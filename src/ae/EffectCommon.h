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

// PF_OutFlag_PIX_INDEPENDENT IS NOT SET, AS OF BUILD 21 -- and it was, from the build that
// read the SDK's wording properly until pareidolia.
//
// The SDK's wording: "Set this flag if the output at a given pixel is not dependent
// on the values of THE PIXELS AROUND IT." It is a claim about the pixels the effect
// READS. Until build 21 Mistytune read none, so it was true. PAREIDOLIA READS A WHOLE
// LAYER and every output pixel depends on all of it, so it is false now. Dropped outright
// rather than withdrawn per frame through PF_Cmd_QUERY_DYNAMIC_FLAGS: it bought nothing
// measurable when it was set (cmake/EffectFlags.cmake has the history), so the dynamic
// mechanism would be machinery for no gain.
constexpr PF_OutFlags kOutFlags =
    // Build 24: THE PICTURE CHANGES WITH TIME, NOT ONLY WITH THE PARAMETERS -- the cumulus
    // cells' drift, life and billows, the ice's drift. Without this AE takes an effect on
    // a solid with nothing keyframed to be one frame, and plays that frame back. The SDK:
    // "If the effect produces changing frames when applied to a still image and all
    // parameters are constant, that's a sure sign that this bit should be set."
    PF_OutFlag_NON_PARAM_VARY |
    PF_OutFlag_DEEP_COLOR_AWARE |
    // Build 17: PF_Cmd_UPDATE_PARAMS_UI, so the classifier readout is named when the
    // Effect Controls open and when a project loads -- not only once a supervised
    // control has been touched. See updateReadout in Mistytune.cpp.
    PF_OutFlag_SEND_UPDATE_PARAMS_UI;

constexpr PF_OutFlags2 kOutFlags2 =
    // Required before AEGP_GetEffectCameraMatrix returns anything, and what makes
    // AE re-render when the comp camera moves. Set in Phase 1 before the camera is
    // used, because out_flags2 is cached against the binary and adding it later
    // costs a version bump and a stale-cache hunt. See cmake/EffectFlags.cmake --
    // which also records that removing it does NOT persuade AE to GPU-render.
    PF_OutFlag2_I_USE_3D_CAMERA |
    // Build 29: the comp's lights light the clouds, read at pre-render (never on the
    // render path). The SDK requires it of an effect that reads light layers, and it is
    // what makes AE re-render when a light moves or flickers.
    PF_OutFlag2_I_USE_3D_LIGHTS |
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
