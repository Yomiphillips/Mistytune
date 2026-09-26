#pragma once

// The ONLY place After Effects types meet engine and kernel types.
//
// Everything in src/engine/ and src/kernel/ is host-agnostic by design. This header
// is the translation layer: a PF_EffectWorld becomes a kernel Surface, AE's
// parameter and resolution quirks get normalised here rather than leaking downward.
//
// KEEP THAT RULE. It is what lets the interesting code be unit-tested without
// launching After Effects, and what stops host weirdness from spreading into the
// renderer -- where it would also have to be reproduced by src/cli/ for a golden
// image to mean anything.

#include "AEConfig.h"
#include "entry.h"
#include "AE_Effect.h"
#include "AE_EffectCB.h"
#include "AE_EffectSuites.h"
#include "AE_GeneralPlug.h"
#include "AE_Macros.h"
#include "AEGP_SuiteHandler.h"
#include "AEFX_SuiteHandlerTemplate.h"
#include "Param_Utils.h"
// UnionLRect and friends, for the smart-render rect arithmetic. DECLARED here but
// DEFINED in Smart_Utils.cpp, which cmake/AESDK.cmake compiles in -- the header
// alone links to nothing.
#include "Smart_Utils.h"

#include "CloudParams.h"
#include "RenderRequest.h"

#include <cmath>
#include <cstddef>

namespace plugin {
namespace ae {

// ---------------------------------------------------------------------------
// Resolution
// ---------------------------------------------------------------------------

// DOWNSAMPLE IS THE THING NEW AE DEVELOPERS GET CAUGHT BY.
//
// At Half resolution AE hands you a buffer half the size and expects you to work in
// it. Anything measured in "comp pixels" has to be scaled, or the effect changes
// shape when the user switches preview quality -- which looks like a bug in the
// maths rather than a units mistake.
//
// FOR A RENDERER THE CONSEQUENCE IS SHARPER THAN USUAL: the field of view must NOT
// be scaled, because a smaller buffer of the same view is exactly what a proxy
// render is. Scale the buffer, keep the camera.
inline float downsampleX(const PF_InData* in_data) {
    return static_cast<float>(in_data->downsample_x.num) / in_data->downsample_x.den;
}

inline float downsampleY(const PF_InData* in_data) {
    return static_cast<float>(in_data->downsample_y.num) / in_data->downsample_y.den;
}

// ---------------------------------------------------------------------------
// Pixel formats
// ---------------------------------------------------------------------------

// How many bytes one pixel takes, from the world itself.
//
// ASKED, NOT ASSUMED. PF_WorldSuite2 is the only thing that knows -- a
// PF_EffectWorld carries a PF_WorldFlag_DEEP bit that distinguishes 8 from 16 bpc
// and says nothing at all about 32-bit float.
//
// Returns 0 when the format cannot be established, which the caller must treat as
// "do not touch these pixels" rather than as a reason to guess a stride.
inline size_t bytesPerPixel(PF_PixelFormat format) {
    switch (format) {
        case PF_PixelFormat_ARGB32:      return 4;    // 8 bpc
        case PF_PixelFormat_ARGB64:      return 8;    // 16 bpc
        case PF_PixelFormat_ARGB128:     return 16;   // 32 bpc float
        case PF_PixelFormat_GPU_BGRA128: return 16;   // GPU float, BGRA order
        default:                         return 0;
    }
}

inline PF_Err pixelFormatOf(PF_InData* in_data, PF_OutData* out_data,
                            PF_EffectWorld* world, PF_PixelFormat& out) {
    out = PF_PixelFormat_INVALID;
    AEFX_SuiteScoper<PF_WorldSuite2> worldSuite(in_data, kPFWorldSuite,
                                                kPFWorldSuiteVersion2, out_data);
    return worldSuite->PF_GetPixelFormat(world, &out);
}

// ---------------------------------------------------------------------------
// Worlds -> kernel surfaces
// ---------------------------------------------------------------------------

// A float world as the kernel's destination surface.
//
// PITCH IN PIXELS, NOT BYTES, matching what the AE GPU sample passes its kernels
// (rowbytes / bytes_per_pixel). A row stride is never assumed to equal the width:
// AE pads rows, and at reduced resolution the buffer is a different shape again.
//
// ONLY VALID FOR THE TWO 128-BIT FORMATS. The 8 and 16 bpc paths convert through a
// float staging buffer, because the renderer's output is HDR and quantising it to
// integers is the last thing that should happen, not the first.
inline kernel::Surface toSurface(PF_EffectWorld* world, PF_PixelFormat format) {
    kernel::Surface s;
    s.data     = world->data;
    s.widthPx  = world->width;
    s.heightPx = world->height;

    const size_t bpp = bytesPerPixel(format);
    s.pitchPx = bpp ? static_cast<int>(world->rowbytes / static_cast<A_long>(bpp)) : 0;

    // THE CHANNEL ORDER, AND IT IS NOT THE SAME ON BOTH PATHS.
    //
    //   PF_PixelFormat_ARGB128     is { alpha, red, green, blue }
    //   PF_PixelFormat_GPU_BGRA128 is { blue, green, red, alpha }
    //
    // Getting it wrong does not crash and does not look obviously broken: the sky
    // comes out with the wrong colour balance, which reads as a bug in the
    // atmosphere model. So the kernel is TOLD rather than left to assume.
    s.order = (format == PF_PixelFormat_GPU_BGRA128)
                ? kernel::ChannelOrder::BGRA
                : kernel::ChannelOrder::ARGB;
    return s;
}

// ---------------------------------------------------------------------------
// The camera
// ---------------------------------------------------------------------------

// Fills the view's camera from the comp's 3D camera, if it has one.
//
// AEGP_GetEffectCameraMatrix RETURNS CAMERA-TO-WORLD. Invert it for a view matrix --
// which is why ViewParams stores camera-to-world and the kernel does the rotation
// directly, so no inversion is needed at all on this path.
//
// It requires PF_OutFlag2_I_USE_3D_CAMERA, which EffectCommon.h sets, and it is
// safe to call on a render thread.
//
// A COMP WITH NO CAMERA RETURNS A ZERO PLANE SIZE. Falling back to a default camera
// is correct; what matters is keeping track of WHICH happened, because "no camera,
// defaulting" is a fact and "the call failed" is a guess. cameraFromComp carries
// that distinction into the view hash, so a comp that later gains a camera
// re-renders even if the default matrix happened to match.
//
// PHASE 1 STUB. The real implementation lands in Phase 2 alongside progressive
// accumulation; it is stubbed rather than omitted so that the flag, the parameter
// and the hash are all already in place and the change is one function body.
inline void fillCameraFromComp(PF_InData* in_data, cloud::ViewParams& view) {
    (void)in_data;
    view.cameraFromComp = false;

    // A DEFAULT THAT LOOKS AT THE SKY rather than the identity, which looks along
    // -Z at the horizon and would make the Phase 1 sky a flat band.
    //
    // Pitched up 20 degrees: enough to see the zenith gradient, low enough to keep
    // the horizon in frame so that both halves of the placeholder are visible at
    // once. Column-major would transpose this; it is row-major, as the kernel reads
    // it.
    const float pitch = -20.0f * 0.01745329252f;
    const float c = std::cos(pitch);
    const float s = std::sin(pitch);

    const float m[16] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, c,    -s,   0.0f,
        0.0f, s,    c,    0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
    };
    for (int i = 0; i < 16; ++i) view.cameraToWorld[i] = m[i];
}

// ---------------------------------------------------------------------------
// Time
// ---------------------------------------------------------------------------

// The current frame as seconds.
//
// DIVIDED, NOT COUNTED. in_data->current_time is in time_scale units, and the
// frame-rate-independent value is what the field wants: an advecting cell has to
// move the same distance per second whatever the comp's frame rate, or changing the
// frame rate changes the sky.
inline float currentTimeSeconds(const PF_InData* in_data) {
    if (in_data->time_scale == 0) return 0.0f;
    return static_cast<float>(in_data->current_time) /
           static_cast<float>(in_data->time_scale);
}

} // namespace ae
} // namespace plugin
