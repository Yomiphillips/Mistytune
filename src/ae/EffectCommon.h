#pragma once

// What every command handler shares: the registration numbers, and the two calls
// that report them.
//
// KEPT SEPARATE FROM Mistytune.cpp so that the static_asserts below are compiled
// by anything that includes this, rather than only by the one translation unit
// that happens to define GlobalSetup.

#include "AEConfig.h"
#include "entry.h"
#include "AE_Effect.h"
#include "AE_EffectCB.h"
#include "AE_EffectCBSuites.h"
#include "AE_EffectSuites.h"
// PF_GPUDeviceSuite1, PF_GPUDeviceInfo, PF_GPUDeviceSetupExtra and the
// PF_GPU_Framework_* enum. A SEPARATE HEADER from the rest of the suites, and not
// included by any of them -- so a GPU effect that forgets it gets
// "PF_GPUDeviceSuite1: undeclared identifier" and no hint about which header to add.
#include "AE_EffectGPUSuites.h"
#include "AE_GeneralPlug.h"
#include "AE_Macros.h"
#include "AEGP_SuiteHandler.h"
#include "AEFX_SuiteHandlerTemplate.h"
#include "Param_Utils.h"
#include "Smart_Utils.h"

#include "Build.h"
#include "DiagLog.h"
#include "PluginIdentity.h"

namespace plugin {
namespace ae {

// ---------------------------------------------------------------------------
// THE NUMBERS AE CACHES, PROVED CORRECT AT COMPILE TIME.
//
// After Effects caches an effect's registration against the binary and compares it
// with what PF_Cmd_GLOBAL_SETUP reports at load. cmake/EffectFlags.cmake computes
// the decimals and puts them in the generated identity header; these three
// static_asserts check them against the symbolic constants set below.
//
// A flag typo is therefore a compile error on this machine rather than a "global
// outflags2 mismatch" on someone else's.
// ---------------------------------------------------------------------------

// PF_OutFlag_PIX_INDEPENDENT IS SET, AND THIS FILE USED TO ARGUE IT SHOULD NOT BE.
//
// The SDK's wording: "Set this flag if the output at a given pixel is not dependent
// on the values of THE PIXELS AROUND IT." It is a claim about the INPUT IMAGE.
//
// The old argument here was that "every pixel of a path trace depends on the whole
// field", which conflates the SCENE with the input image. Mistytune is a generator
// and does not read its input at all. See cmake/EffectFlags.cmake for the full
// reasoning, including when Phase 4's pareidolia makes this false again and the
// dynamic-flags mechanism for withdrawing it.
constexpr PF_OutFlags kOutFlags =
    PF_OutFlag_PIX_INDEPENDENT |
    PF_OutFlag_DEEP_COLOR_AWARE;

constexpr PF_OutFlags2 kOutFlags2 =
    // Required before AEGP_GetEffectCameraMatrix returns anything, and what makes
    // AE re-render when the comp camera moves. Set in Phase 1 before the camera is
    // used, because out_flags2 is cached against the binary and adding it later
    // costs a version bump and a stale-cache hunt. See cmake/EffectFlags.cmake --
    // which also records that removing it does NOT persuade AE to GPU-render.
    PF_OutFlag2_I_USE_3D_CAMERA |
    PF_OutFlag2_SUPPORTS_SMART_RENDER |
    // 32 bpc float. LEGAL ONLY ALONGSIDE SUPPORTS_SMART_RENDER, and the format the
    // renderer actually works in: the accumulator holds linear radiance and values
    // above 1.0 are the sun.
    PF_OutFlag2_FLOAT_COLOR_AWARE |
    // Must ALSO set PF_RenderOutputFlag_GPU_RENDER_POSSIBLE at pre-render, or AE
    // silently takes the CPU path.
    PF_OutFlag2_SUPPORTS_GPU_RENDER_F32 |
    // The Multi-Frame Rendering opt-in. HONEST HERE FOR NOW: the Phase 1 render
    // path reads parameters, launches a kernel over a buffer AE owns, and returns.
    // It holds no mutable global state at all.
    //
    // WHAT HAS TO STAY TRUE AS PHASE 2 LANDS: no shared mutable renderer state, a
    // field cache that is read-mostly with explicit locking, nothing on the render
    // path that touches host streams, and seeds derived only from
    // (frame, sample index, pixel). If any of those stops holding, this flag comes
    // back off or the state grows a lock -- the promise is about the render path,
    // not about the effect doing no work.
    PF_OutFlag2_SUPPORTS_THREADED_RENDERING;

static_assert(kOutFlags  == PLUGIN_EFFECT_OUT_FLAGS,
              "out_flags disagree with cmake/EffectFlags.cmake -- fix the CMake copy");
static_assert(kOutFlags2 == PLUGIN_EFFECT_OUT_FLAGS2,
              "out_flags2 disagree with cmake/EffectFlags.cmake -- fix the CMake copy");

// The release stage AE packs into the version field.
//
// PLUGIN_DIST_BUILD is defined ONLY by the PLUGIN_HOT_RELOAD=OFF CMake path, so a
// development binary cannot claim to be a release one. BETA rather than RELEASE
// deliberately: PF_Stage_RELEASE is the point the parameter layout freezes for
// good, and PLAN.md reviews the match name and layout once more before the v0.5
// hand-out.
#ifdef PLUGIN_DIST_BUILD
  #define PLUGIN_STAGE PF_Stage_BETA
#else
  #define PLUGIN_STAGE PF_Stage_DEVELOP
#endif

constexpr A_u_long kEffectVersion =
    PF_VERSION(PLUGIN_MAJOR, PLUGIN_MINOR, 0, PLUGIN_STAGE, PLUGIN_BUILD);

static_assert(kEffectVersion == PLUGIN_EFFECT_VERSION,
              "effect version disagrees with cmake/EffectFlags.cmake -- note the "
              "STAGE is part of the packed number, so flipping build shape changes it");

// ---------------------------------------------------------------------------

inline PF_Err globalSetup(PF_InData* in_data, PF_OutData* out_data) {
    (void)in_data;
    out_data->my_version = kEffectVersion;
    out_data->out_flags  = kOutFlags;
    out_data->out_flags2 = kOutFlags2;

    diagLog("=== %s v%d.%d build %d loaded ===",
            PLUGIN_NAME, PLUGIN_MAJOR, PLUGIN_MINOR, PLUGIN_BUILD);
    return PF_Err_NONE;
}

inline PF_Err about(PF_InData* in_data, PF_OutData* out_data) {
    AEGP_SuiteHandler suites(in_data->pica_basicP);
    suites.ANSICallbacksSuite1()->sprintf(
        out_data->return_msg,
        "%s\rv%d.%d build %d\r\r"
        "Volumetric cloud and sky renderer. An offline path tracer, not a noise "
        "generator.",
        PLUGIN_NAME, PLUGIN_MAJOR, PLUGIN_MINOR, PLUGIN_BUILD);
    return PF_Err_NONE;
}

} // namespace ae
} // namespace plugin
