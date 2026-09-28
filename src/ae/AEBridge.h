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

// The camera conversion logs the raw host values it derives from -- see
// fillCameraFromComp, and DiagLog.h on why measuring beats inferring.
#include "DiagLog.h"

#include "CameraConvert.h"
#include "CloudParams.h"
#include "OutputConvert.h"
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

// A full-resolution extent, in the units the destination buffer is measured in.
//
// IN_DATA->WIDTH/HEIGHT ARE FULL RESOLUTION AND DO NOT SHRINK. Measured in AE 2026:
// a 1/3 render of a 1920x1080 layer reported in_data->width == 1920 while the buffer
// AE handed back was 640x360. Everything else at render time -- the output world, the
// request rect, output_origin_x/y -- is in downsampled pixels, so a full-resolution
// number mixed in with them describes a different picture than the rest.
//
// ROUNDED UP, because a layer must not lose its last row or column at reduced
// resolution. On the sizes AE actually uses the division is exact; the rounding only
// decides a sub-pixel case, and losing the edge is the worse of the two.
inline int downsampledExtent(A_long fullRes, const PF_RationalScale& scale) {
    if (scale.den <= 0 || scale.num <= 0) return static_cast<int>(fullRes);
    const A_long num = fullRes * scale.num;
    return static_cast<int>((num + scale.den - 1) / scale.den);
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

// An integer world as an engine ImageView, for the output conversion.
//
// THE CONVERSION ITSELF IS IN src/engine/OutputConvert.h AND THIS IS THE WHOLE OF THE
// AE-SPECIFIC PART OF IT. That split is why the 0..32768 rule, the sRGB curve and the
// "alpha never gets the curve" rule are all unit-tested now rather than being three
// things that could only be checked by rendering in the host and looking.
//
// ONLY THE INTEGER FORMATS REACH THIS. 32 bpc float is what the renderer already works
// in, so the effect writes straight into AE's buffer through toSurface() above and
// builds no staging buffer at all.
inline ImageView toImageView(PF_EffectWorld* world, PF_PixelFormat format) {
    ImageView v;
    v.data     = world->data;
    v.width    = world->width;
    v.height   = world->height;
    v.rowBytes = world->rowbytes;

    // =======================================================================
    // THE FALLBACK IS THE NARROWEST FORMAT, NOT THE WIDEST, AND THAT IS THE WHOLE
    // DIFFERENCE BETWEEN A WRONG PICTURE AND CORRUPTING THE HOST.
    //
    // This function is only ever reached on the NON-DIRECT path, which is 8 or 16 bpc --
    // 32 bpc float returns before it, because the renderer already works in that format
    // and writes into AE's buffer through toSurface(). So an unrecognised format here is
    // something narrow, and guessing wide is not a conservative guess:
    //
    //   ARGB32F writes 16 bytes per pixel. An 8 bpc pixel is 4.
    //
    // That is a four-times overrun of every row of a world AE allocated and still owns,
    // across the whole frame. It would not present as a wrong picture; it would present
    // as After Effects crashing somewhere else entirely, later, in a way no part of this
    // plugin appears in.
    //
    // ARGB8 under-writes instead. Four bytes into an eight-byte pixel is a visibly wrong
    // picture in a buffer we were given, which is recoverable and diagnosable -- and the
    // loop this replaced fell back exactly that way, with `sixteen ? ... : 8-bit`.
    //
    // A FIRST VERSION OF THIS FUNCTION DEFAULTED TO ARGB32F. It was caught by reading an
    // AE log to check a different claim -- the log reported format 842229089, which is
    // the fourcc 'ae32', PF_PixelFormat_ARGB128 -- and noticing that the value reaching
    // the switch was one the switch had no case for and would have mapped to sixteen
    // bytes had it ever arrived here.
    // =======================================================================
    switch (format) {
        case PF_PixelFormat_ARGB64: v.format = PixelFormat::ARGB16; break;
        case PF_PixelFormat_ARGB32: v.format = PixelFormat::ARGB8;  break;
        default:                    v.format = PixelFormat::ARGB8;  break;
    }
    return v;
}


// THE OUTPUT TRANSFER CURVE AND THE QUANTISER HAVE MOVED to
// src/engine/OutputConvert.h, which this file includes. They were here, and they
// were the last part of the render path that could only be checked by rendering in
// After Effects and looking at the result -- three quiet host conventions with no
// test between them. Nothing in either is AE-specific, so nothing kept them here.

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
// NOT A STUB ANY MORE, AND THIS COMMENT SAID IT WAS FOR ONE ENTRY LONGER THAN IT WAS
// TRUE. It calls AEGP_GetEffectCameraMatrix below and converts through
// src/engine/CameraConvert.h; the AE 2026 host log reports `vertical fov 17.3 deg`,
// which checks out against a 1080 plane at distance 3555.
//
// WHAT IS STILL ABSENT IS THE POSITION, which is a different thing and is easy to read
// this as covering. CameraConvert zeroes the translation deliberately: AE's world is
// comp pixels against an arbitrary origin and this one is metres, so flying the camera
// needs a real pixels-per-metre parameter. Phase 3. The ray origin is observerAltitude
// unconditionally, which TheRayStartsAtTheObserverNotAtTheMatrix pins.
inline void fillCameraFromComp(PF_InData* in_data, cloud::ViewParams& view) {
    view.cameraFromComp = false;

    // ---------------------------------------------------------------------
    // THE COMP'S OWN CAMERA, WHEN THERE IS ONE.
    //
    // AEGP_GetEffectCameraMatrix needs PF_OutFlag2_I_USE_3D_CAMERA, which is set in
    // EffectFlags.cmake, and docs/HOST-NOTES.md records that it is safe to call on a
    // render thread. The conversion itself is in src/engine/CameraConvert.h, tested
    // against hand-derived cases -- a camera pointing the wrong way renders a
    // plausible picture, so it is the last thing to verify by eye.
    //
    // A ZERO PLANE SIZE MEANS NO CAMERA, NOT AN ERROR. A comp without one is the
    // ordinary case for a generator dropped on a solid, and it takes the default
    // below. cameraFromComp records which happened, so the log can say "no camera,
    // defaulting" rather than leaving it to be guessed from the picture.
    // ---------------------------------------------------------------------
    if (in_data && in_data->pica_basicP) {
        A_Matrix4 aeMatrix;
        AEFX_CLR_STRUCT(aeMatrix);

        A_FpLong distanceToPlane = 0.0;
        A_short  planeWidth = 0, planeHeight = 0;

        A_Time when;
        when.value = in_data->current_time;
        when.scale = in_data->time_scale;

        AEGP_SuiteHandler suites(in_data->pica_basicP);
        const A_Err aeErr = suites.PFInterfaceSuite1()->AEGP_GetEffectCameraMatrix(
            in_data->effect_ref, &when, &aeMatrix,
            &distanceToPlane, &planeWidth, &planeHeight);

        // THE RAW VALUES, LOGGED BEFORE ANYTHING IS DERIVED FROM THEM.
        //
        // The field of view is computed from these two numbers and nothing else, and a
        // wrong field of view renders a picture that looks entirely reasonable -- so
        // the inputs are on the record rather than only the conclusion. For a default
        // AE camera on a 1920x1080 comp expect distance 2666.7 against a 1080 plane,
        // which is 22.9 degrees vertical; anything far from that is either a real lens
        // choice or a units mistake, and these two numbers are what tells them apart.
        diagLog("  camera raw: err=%d distanceToPlane=%.1f plane=%dx%d",
                static_cast<int>(aeErr), static_cast<double>(distanceToPlane),
                static_cast<int>(planeWidth), static_cast<int>(planeHeight));

        if (!aeErr && planeHeight > 0 && distanceToPlane > 0.0) {
            // A_Matrix4 is mat[row][col] of A_FpLong; CameraConvert takes the same
            // sixteen values in memory order and owns every convention question.
            double flat[16];
            for (int r = 0; r < 4; ++r) {
                for (int c = 0; c < 4; ++c) flat[r * 4 + c] = aeMatrix.mat[r][c];
            }

            cloud::cameraToWorldFromAE(flat, view.cameraToWorld);

            const cloud::Real fov =
                cloud::verticalFovFromPlane(distanceToPlane, planeHeight);
            if (fov > 0) view.verticalFovDegrees = fov;

            view.cameraFromComp = true;
            return;
        }
    }

    // A DEFAULT THAT LOOKS AT THE SKY rather than the identity, which looks along
    // -Z at the horizon and would make the Phase 1 sky a flat band.
    //
    // THE SIGN IS POSITIVE, AND IT WAS NOT. R_x(theta) applied to the camera's
    // forward (0,0,-1) gives world y = sin(theta), so a NEGATIVE angle pitches the
    // camera DOWN. The old value of -20 degrees put the centre ray 20 degrees BELOW
    // the horizon and, at a 39.6 degree vertical field of view, the whole frame ran
    // from -39.8 to -0.2 degrees: every pixel was ground, and the horizon sat just
    // off the top edge. Rendered without a transfer curve that ground came out at
    // 18/255, so the effect appeared to produce a black frame.
    //
    // THE MAGNITUDE IS 12 AND NOT 20 because 20 does not satisfy what this comment
    // has always claimed. With half the field of view at 19.8 degrees, a 20 degree
    // pitch puts the horizon exactly on the bottom edge -- "both halves visible at
    // once" fails by two tenths of a degree, in the direction of an all-sky gradient
    // with no horizon in it. 12 degrees puts the horizon about 80% down the frame,
    // which is what the intent below actually describes.
    //
    // Enough pitch to see the zenith gradient, low enough to keep the horizon in
    // frame so that both halves of the placeholder are visible at once. Column-major
    // would transpose this; it is row-major, as the kernel reads it.
    const float pitch = 12.0f * 0.01745329252f;
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
