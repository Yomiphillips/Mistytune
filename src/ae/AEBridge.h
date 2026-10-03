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
#include "LocalLights.h"
#include "ColorManagement.h"
#include "OutputConvert.h"
#include "RenderRequest.h"

#include <cmath>
#include <cstddef>
#include <vector>

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
// ANOTHER LAYER'S PIXELS, READ-ONLY, AT WHATEVER DEPTH THEY ARRIVE (build 21): pareidolia's
// source. Unlike toImageView below, EVERY CPU FORMAT IS A REAL ANSWER HERE, and an
// unrecognised one is a refusal rather than a guess -- this reads memory AE owns, and a
// wrong stride reads past it.
inline bool toSourceView(PF_EffectWorld* world, PF_PixelFormat format, ConstImageView& v) {
    if (!world || !world->data || world->width <= 0 || world->height <= 0) return false;
    switch (format) {
        case PF_PixelFormat_ARGB128: v.format = PixelFormat::ARGB32F; break;
        case PF_PixelFormat_ARGB64:  v.format = PixelFormat::ARGB16;  break;
        case PF_PixelFormat_ARGB32:  v.format = PixelFormat::ARGB8;   break;
        default:                     return false;
    }
    v.data     = world->data;
    v.width    = world->width;
    v.height   = world->height;
    v.rowBytes = world->rowbytes;
    return true;
}

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
// The project's colour management
// ---------------------------------------------------------------------------

// One suite, typed, or nullptr.
//
// THE CAST IS THE REASON THIS EXISTS. SPBasicSuite::AcquireSuite writes through a
// `const void**`, and `reinterpret_cast<const void**>(&someSuitePtr)` is ill-formed --
// it adds const at the second level, which MSVC rejects outright. Going through a
// `const void*` local is the conversion that is actually legal, and doing it once here
// keeps four call sites from each getting it slightly differently.
//
// AEFX_SuiteScoper IS NOT USED FOR THESE. It throws when a suite is missing, and every
// suite below is one this effect must be able to do without -- an older host, or a
// call made where AE will not answer. A throw crossing the AE boundary is never
// allowed, so the absence has to be a nullptr rather than an exception.
template <typename Suite>
inline Suite* acquireSuite(SPBasicSuite* basic, const char* name, int version) {
    if (!basic) return nullptr;
    const void* raw = nullptr;
    if (basic->AcquireSuite(name, version, &raw) || !raw) return nullptr;
    return static_cast<Suite*>(const_cast<void*>(raw));
}

// A colour profile's human-readable name, into `out`, for the diagnostic log only.
//
// ===========================================================================
// WHY A NAME IS WORTH TWENTY LINES OF UTF-16 AND MEMORY-HANDLE HANDLING.
//
// The gamma alone is ambiguous in exactly the case that still matters. Under Working
// Space None the open question is whether AEGP_GetNewWorkingSpaceColorProfile fails --
// in which case rule 4 encodes and is right -- or succeeds with some profile, in which
// case its gamma decides and could be wrong. `profileErr=0 gamma=1.000` and
// `profileErr=0 gamma=2.200` need completely different responses, and neither says
// which SPACE answered.
//
// The description does: "None", "sRGB IEC61966-2.1", "ACEScg" and "Rec.709" are all
// distinguishable at a glance. ONE host session with this line settles every remaining
// branch; without it, the None case would likely need a second.
//
// DIAGNOSTIC ONLY, AND NEVER PARSED. The string is localised, host-specific and free to
// change between AE versions, so a decision keyed off it would be a decision keyed off
// a display string. encodesSrgbForHost() never sees it.
//
// LOSSY ASCII ON PURPOSE. A_UTF16Char down to one byte per character mangles anything
// non-Latin, which is the correct trade for a log line: DiagLog is printf-based, and
// carrying a UTF-8 conversion into it to render a profile name would be a real
// dependency for a debugging aid.
// ===========================================================================
inline void colorProfileDescription(SPBasicSuite* basic, AEGP_PluginID pluginId,
                                    AEGP_ColorSettingsSuite4* colour,
                                    AEGP_ColorProfileP profile,
                                    char* out, size_t outSize) {
    if (!out || outSize == 0) return;
    out[0] = '\0';
    if (!basic || !colour || !profile) return;

    AEGP_MemorySuite1* memory = acquireSuite<AEGP_MemorySuite1>(
        basic, kAEGPMemorySuite, kAEGPMemorySuiteVersion1);
    if (!memory) return;

    AEGP_MemHandle handle = nullptr;
    const A_Err err = colour->AEGP_GetNewColorProfileDescription(pluginId, profile, &handle);
    if (!err && handle) {
        void* locked = nullptr;
        if (!memory->AEGP_LockMemHandle(handle, &locked) && locked) {
            const A_UTF16Char* utf16 = static_cast<const A_UTF16Char*>(locked);
            size_t n = 0;
            while (n + 1 < outSize && utf16[n] != 0) {
                const A_UTF16Char c = utf16[n];
                out[n] = (c >= 32 && c < 127) ? static_cast<char>(c) : '?';
                ++n;
            }
            out[n] = '\0';
            memory->AEGP_UnlockMemHandle(handle);
        }
        // FREED WHETHER OR NOT THE LOCK WORKED. "GetNew" means the caller owns it, and
        // this runs once per frame -- a leak here is a leak per frame.
        memory->AEGP_FreeMemHandle(handle);
    }

    basic->ReleaseSuite(kAEGPMemorySuite, kAEGPMemorySuiteVersion1);
}

// The AEGP plugin id, registered once.
//
// AN EFFECT HAS NO PLUGIN ID OF ITS OWN, and two of the three colour-settings calls
// want one. AEGP_RegisterWithAEGP mints one for any plugin that asks, and it is meant
// to be asked ONCE -- so the work sits in the initialiser of a function-local static,
// whose initialisation C++11 guarantees is thread-safe and runs exactly once.
//
// THAT GUARANTEE IS THE REASON IT IS WRITTEN THIS WAY rather than as a plain
// "if (!done)" flag: PF_OutFlag2_SUPPORTS_THREADED_RENDERING means several frames are
// in flight at once, and a plain flag would let two of them race into the registration.
//
// RETURNS 0 AND KEEPS RETURNING 0 IF THE REGISTRATION FAILS, which readHostColorSettings
// treats as "the host cannot be asked" rather than retrying on every frame.
inline AEGP_PluginID aegpPluginId(SPBasicSuite* basic) {
    static const AEGP_PluginID cached = [&]() -> AEGP_PluginID {
        AEGP_UtilitySuite6* utility = acquireSuite<AEGP_UtilitySuite6>(
            basic, kAEGPUtilitySuite, kAEGPUtilitySuiteVersion6);
        if (!utility) return 0;

        AEGP_PluginID id = 0;
        const A_Err err = utility->AEGP_RegisterWithAEGP(nullptr, PLUGIN_NAME, &id);
        basic->ReleaseSuite(kAEGPUtilitySuite, kAEGPUtilitySuiteVersion6);
        return err ? 0 : id;
    }();

    return cached;
}

// Asks the project what it does to our pixels on the way to the screen.
//
// ===========================================================================
// EVERY FAILURE PATH RETURNS A DEFAULT-CONSTRUCTED HostColorSettings, WHICH
// encodesSrgbForHost() MAPS TO EXACTLY WHAT THIS EFFECT DID BEFORE ANY OF THIS EXISTED.
//
// That is the whole safety argument for putting three new AEGP calls on the pre-render
// path. There is no branch here that can make a render worse than the one that shipped;
// the worst case is that nothing is learned and the constant wins.
//
// COLOUR SETTINGS SUITE 4, NOT 6. Suite 4 froze in AE 22.6 and already carries all
// three calls used here; 6 adds OCIO config paths and LUT interpolation, none of which
// this needs. Asking for the oldest suite that answers the question is what keeps the
// effect loadable on hosts older than the SDK it was built against.
//
// THE RAW ANSWERS ARE LOGGED, NOT JUST THE CONCLUSION, for the same reason the camera
// logs distanceToPlane and the plane size: the conclusion is one bool, every value it
// could take renders a plausible picture, and "Linearize Working Color Space" has no
// API at all -- so the only way anyone settles what AE reports for a given project
// configuration is to set it up in the host and read these lines back.
//
// THESE CALLS ARE LEGAL FROM PRE-RENDER, AND THAT IS NOW MEASURED RATHER THAN HOPED.
// Confirmed in AE 2026 over four frames at three bit depths:
//
//     colour raw: ocioErr=0 ocio=1 profileErr=0 haveGamma=1 gamma=2.400
//
// Both error codes zero means the whole chain ran on the thread AE calls pre-render on:
// AEGP_RegisterWithAEGP, AEGP_GetEffectLayer, AEGP_GetLayerParentComp,
// AEGP_GetNewWorkingSpaceColorProfile and AEGP_GetColorProfileApproximateGamma.
//
// IT WAS STILL RIGHT TO WRITE IT FAIL-SAFE. Only AEGP_GetEffectCameraMatrix is
// documented for a render thread (docs/HOST-NOTES.md); AEGP_GetEffectLayer and the
// colour suite are documented for neither. The SDK returns A_Err_WRONG_THREAD (5)
// rather than throwing, so a bad thread would have cost a logged 5 and yesterday's
// render rather than a crash. No 5 appeared. If one ever does -- another host, another
// AE version, a render-queue worker -- the read moves to sequence setup and gets cached.
// ===========================================================================
inline cloud::HostColorSettings readHostColorSettings(PF_InData* in_data) {
    cloud::HostColorSettings settings;

    if (!in_data || !in_data->pica_basicP) {
        diagLog("  colour: no SP basic suite -- assuming an unmanaged project.");
        return settings;
    }
    SPBasicSuite* basic = in_data->pica_basicP;

    const AEGP_PluginID pluginId = aegpPluginId(basic);
    if (pluginId == 0) {
        diagLog("  colour: AEGP_RegisterWithAEGP failed -- assuming an unmanaged project.");
        return settings;
    }

    AEGP_ColorSettingsSuite4* colour = acquireSuite<AEGP_ColorSettingsSuite4>(
        basic, kAEGPColorSettingsSuite, kAEGPColorSettingsSuiteVersion4);
    if (!colour) {
        diagLog("  colour: ColorSettingsSuite4 unavailable -- assuming an unmanaged project.");
        return settings;
    }

    // GOT THIS FAR MEANS THE HOST CAN BE ASKED. Individual calls below may still fail,
    // and each one leaves its own field untouched rather than discarding the others.
    settings.queried = true;

    // --- Is the project on OCIO? ----------------------------------------
    A_Boolean ocio = FALSE;
    const A_Err ocioErr = colour->AEGP_IsOCIOColorManagementUsed(pluginId, &ocio);
    if (!ocioErr) settings.ocioManaged = (ocio != FALSE);

    // --- What is the working space's transfer curve? ---------------------
    //
    // VIA THE COMP, because that is what AEGP_GetNewWorkingSpaceColorProfile takes.
    // The effect knows its layer and the layer knows its comp, which is two hops and
    // both of them can fail on a layer that is mid-teardown.
    //
    // A COMP WITH NO WORKING SPACE IS EXPECTED TO FAIL HERE, and that failure is
    // informative rather than a problem: "Working Space None" has no profile to
    // describe. haveWorkingGamma stays false and rule 4 encodes, which is right.
    A_Err profileErr = A_Err_NONE;

    // NAMED "(none)" RATHER THAN LEFT EMPTY, so the log distinguishes "no profile
    // came back" from "a profile came back with a blank name".
    char profileName[128] = "(none)";
    do {
        AEGP_PFInterfaceSuite1* pfInterface = acquireSuite<AEGP_PFInterfaceSuite1>(
            basic, kAEGPPFInterfaceSuite, kAEGPPFInterfaceSuiteVersion1);
        if (!pfInterface) {
            profileErr = A_Err_MISSING_SUITE;
            break;
        }

        AEGP_LayerH layer = nullptr;
        profileErr = pfInterface->AEGP_GetEffectLayer(in_data->effect_ref, &layer);
        basic->ReleaseSuite(kAEGPPFInterfaceSuite, kAEGPPFInterfaceSuiteVersion1);
        if (profileErr || !layer) break;

        AEGP_LayerSuite8* layerSuite = acquireSuite<AEGP_LayerSuite8>(
            basic, kAEGPLayerSuite, kAEGPLayerSuiteVersion8);
        if (!layerSuite) {
            profileErr = A_Err_MISSING_SUITE;
            break;
        }

        AEGP_CompH comp = nullptr;
        profileErr = layerSuite->AEGP_GetLayerParentComp(layer, &comp);
        basic->ReleaseSuite(kAEGPLayerSuite, kAEGPLayerSuiteVersion8);
        if (profileErr || !comp) break;

        AEGP_ColorProfileP profile = nullptr;
        profileErr = colour->AEGP_GetNewWorkingSpaceColorProfile(pluginId, comp, &profile);
        if (profileErr || !profile) break;

        // THE NAME OF WHATEVER ANSWERED, read before the profile is disposed. It is for
        // the log and never for a decision -- see colorProfileDescription above on why
        // the gamma alone leaves the Working Space None case ambiguous.
        colorProfileDescription(basic, pluginId, colour, profile,
                                profileName, sizeof(profileName));

        // DISPOSED ON EVERY PATH OUT OF HERE. AEGP_GetNewWorkingSpaceColorProfile is a
        // "GetNew", which in this SDK always means the caller owns it -- and this runs
        // once per frame, so a leak here is a leak per frame rather than a one-off.
        A_FpShort gamma = 0.0f;
        const A_Err gammaErr = colour->AEGP_GetColorProfileApproximateGamma(profile, &gamma);
        colour->AEGP_DisposeColorProfile(profile);

        if (gammaErr) { profileErr = gammaErr; break; }

        settings.haveWorkingGamma = true;
        settings.workingGamma = static_cast<float>(gamma);
    } while (false);

    basic->ReleaseSuite(kAEGPColorSettingsSuite, kAEGPColorSettingsSuiteVersion4);

    // THE RAW ANSWERS, BEFORE ANYTHING IS CONCLUDED FROM THEM. Both error codes are
    // here because "the project is not OCIO" and "the OCIO query failed" are different
    // facts that produce the same bool, and telling them apart by looking at the render
    // is exactly the diagnosis this project keeps getting wrong.
    diagLog("  colour raw: ocioErr=%d ocio=%d profileErr=%d haveGamma=%d gamma=%.3f profile=\"%s\"",
            static_cast<int>(ocioErr),
            static_cast<int>(settings.ocioManaged),
            static_cast<int>(profileErr),
            static_cast<int>(settings.haveWorkingGamma),
            static_cast<double>(settings.workingGamma),
            profileName);

    return settings;
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
inline void fillCameraFromComp(PF_InData* in_data, cloud::ViewParams& view,
                               float metresPerPixel, float baseAltitude) {
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

            // WHERE IT STANDS, in metres. The plane AE reports is the comp, in full
            // pixels at every preview resolution (measured), which is the frame the
            // translation is in. The raw position is logged beside the result so a
            // wrong frame -- a layer-relative translation, say -- shows as numbers
            // rather than as a sky that is merely somewhere else.
            const cloud::ObserverPosition o = cloud::observerFromAE(
                flat, static_cast<double>(planeWidth), static_cast<double>(planeHeight),
                metresPerPixel, baseAltitude);
            view.observerX        = o.x;
            view.observerAltitude = o.altitude;
            view.observerZ        = o.z;
            diagLog("  camera pos: comp (%.1f, %.1f, %.1f) px -> observer (%.1f, %.1f, %.1f) m"
                    " at %.3f m/px",
                    flat[12], flat[13], flat[14],
                    static_cast<double>(o.x), static_cast<double>(o.altitude),
                    static_cast<double>(o.z), static_cast<double>(metresPerPixel));

            view.cameraFromComp = true;
            return;
        }
    }

    // NO CAMERA: stand where a new default camera would, so that adding one turns the
    // view without moving it. The layer's size stands in for the comp's, which it is
    // for a generator on a comp-sized solid.
    {
        const double w = in_data ? static_cast<double>(in_data->width)  : 1920.0;
        const double h = in_data ? static_cast<double>(in_data->height) : 1080.0;
        const cloud::ObserverPosition o =
            cloud::defaultObserver(w, h, metresPerPixel, baseAltitude);
        view.observerX        = o.x;
        view.observerAltitude = o.altitude;
        view.observerZ        = o.z;
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
// The comp's lights (build 29)
// ---------------------------------------------------------------------------

// A suite held for one scope, released on every path out of it.
template <class Suite>
struct ScopedSuite {
    SPBasicSuite* basic;
    const char*   name;
    int           version;
    Suite*        suite;
    ScopedSuite(SPBasicSuite* b, const char* n, int v)
        : basic(b), name(n), version(v), suite(acquireSuite<Suite>(b, n, v)) {}
    ~ScopedSuite() { if (suite) basic->ReleaseSuite(name, version); }
    ScopedSuite(const ScopedSuite&) = delete;
    ScopedSuite& operator=(const ScopedSuite&) = delete;
    Suite* operator->() const { return suite; }
    explicit operator bool() const { return suite != nullptr; }
};

// ===========================================================================
// EVERY LIGHT IN THE EFFECT'S COMP THAT IS ON NOW, in the renderer's world.
//
// WALKED THROUGH THE LAYER SUITE AT PRE-RENDER, where the camera and the colour settings
// are already asked for and the log shows those calls succeed; never on the render path.
// I_USE_3D_LIGHTS (EffectFlags.cmake) is what makes AE re-render when one changes.
//
// ON NOW MEANS: a light layer, its video switch on as solo leaves it (IsLayerVideoReallyOn),
// and the comp's current time inside its in and out points. The comp's time, not the
// effect's: a light is a comp layer, and the effect's layer may start late.
//
// PLACED THROUGH src/engine/LocalLights.h's frame: the comp camera's own mapping under the
// Comp Camera, and onto the orbit rig with the comp plane at the hero's depth otherwise.
// Either way the comp camera is the one AE draws the viewer through, or AE's default when
// the comp has none.
//
// WHAT EACH LIGHT BECOMES:
//   point, spot   a light at its position, Intensity/100 x Comp Light Strength, the sun's
//                 strength inside its Falloff Radius and the inverse square outside it.
//                 Smooth also fades it to nothing over its Falloff Distance. None is the
//                 inverse square too: a light undimmed for kilometres would light the sky.
//   parallel      a second sun, from its position towards its point of interest
//   ambient       a uniform dome every scattered path sees on its way out
//   environment   not read -- an HDRI light is the sky's job here -- and logged
//
// RAW VALUES ARE LOGGED, light by light, because a light in the wrong place renders a
// plausible cloud lit from somewhere else.
//
// FAILS SAFE: any suite or call that fails leaves the lights read so far and says so. The
// sky renders without the rest.
// ===========================================================================
inline int readCompLights(PF_InData* in_data, const cloud::ViewParams& view, bool compCamera,
                          double travel, const cloud::LightAnchor& anchor, float strength,
                          bool decodeColour, std::vector<cloud::LocalLight>& out,
                          float ambient[3]) {
    out.clear();
    ambient[0] = ambient[1] = ambient[2] = 0.0f;
    if (!in_data || !in_data->pica_basicP) return 0;
    SPBasicSuite* basic = in_data->pica_basicP;

    ScopedSuite<AEGP_PFInterfaceSuite1> pf(basic, kAEGPPFInterfaceSuite, kAEGPPFInterfaceSuiteVersion1);
    ScopedSuite<AEGP_LayerSuite8>  layers(basic, kAEGPLayerSuite, kAEGPLayerSuiteVersion8);
    ScopedSuite<AEGP_StreamSuite5> streams(basic, kAEGPStreamSuite, kAEGPStreamSuiteVersion5);
    ScopedSuite<AEGP_LightSuite2>  lightSuite(basic, kAEGPLightSuite, kAEGPLightSuiteVersion2);
    if (!pf || !layers || !streams || !lightSuite) {
        diagLog("  comp lights: a suite is missing (pf %d layer %d stream %d light %d) -- none read",
                pf ? 1 : 0, layers ? 1 : 0, streams ? 1 : 0, lightSuite ? 1 : 0);
        return 0;
    }

    AEGP_LayerH effectLayer = nullptr;
    AEGP_CompH  comp = nullptr;
    A_Err aeErr = pf->AEGP_GetEffectLayer(in_data->effect_ref, &effectLayer);
    if (!aeErr && effectLayer) aeErr = layers->AEGP_GetLayerParentComp(effectLayer, &comp);
    if (aeErr || !comp) {
        diagLog("  comp lights: no comp (err %d) -- none read", static_cast<int>(aeErr));
        return 0;
    }

    A_Time compTime;
    compTime.value = in_data->current_time;
    compTime.scale = in_data->time_scale;
    aeErr = pf->AEGP_ConvertEffectToCompTime(in_data->effect_ref, in_data->current_time,
                                             in_data->time_scale, &compTime);
    if (aeErr) {
        compTime.value = in_data->current_time;
        compTime.scale = in_data->time_scale;
    }
    const double now = compTime.scale ? static_cast<double>(compTime.value) / compTime.scale : 0.0;

    // THE CAMERA AE DRAWS THE VIEWER THROUGH, or its default for a comp with none.
    double camera[16];
    double planeDistance = 0.0, planeHeight = 0.0;
    {
        A_Matrix4 m;
        AEFX_CLR_STRUCT(m);
        A_FpLong dist = 0.0;
        A_short pw = 0, ph = 0;
        A_Time when;
        when.value = in_data->current_time;
        when.scale = in_data->time_scale;
        const A_Err camErr = pf->AEGP_GetEffectCameraMatrix(in_data->effect_ref, &when, &m,
                                                            &dist, &pw, &ph);
        if (!camErr && ph > 0 && dist > 0.0) {
            for (int r = 0; r < 4; ++r)
                for (int c = 0; c < 4; ++c) camera[r * 4 + c] = m.mat[r][c];
            planeDistance = dist;
            planeHeight   = ph;
        } else {
            cloud::defaultCompCamera(static_cast<double>(in_data->width),
                                     static_cast<double>(in_data->height), camera, planeDistance);
            planeHeight = static_cast<double>(in_data->height);
        }
    }
    const cloud::CompLightFrame frame = cloud::compLightFrame(camera, planeDistance, planeHeight,
                                                              compCamera, travel, view, anchor);

    A_long count = 0;
    if (layers->AEGP_GetCompNumLayers(comp, &count)) count = 0;

    int ambientCount = 0, skipped = 0;
    for (A_long i = 0; i < count; ++i) {
        AEGP_LayerH layer = nullptr;
        if (layers->AEGP_GetCompLayerByIndex(comp, i, &layer) || !layer) continue;
        AEGP_ObjectType type = AEGP_ObjectType_NONE;
        if (layers->AEGP_GetLayerObjectType(layer, &type) || type != AEGP_ObjectType_LIGHT) continue;

        A_Boolean on = FALSE;
        if (layers->AEGP_IsLayerVideoReallyOn(layer, &on) || !on) continue;

        A_Time inPoint, duration;
        if (!layers->AEGP_GetLayerInPoint(layer, AEGP_LTimeMode_CompTime, &inPoint) &&
            !layers->AEGP_GetLayerDuration(layer, AEGP_LTimeMode_CompTime, &duration) &&
            inPoint.scale && duration.scale) {
            const double from = static_cast<double>(inPoint.value) / inPoint.scale;
            const double span = static_cast<double>(duration.value) / duration.scale;
            if (now < from || now >= from + span) continue;
        }

        AEGP_LightType lightType = static_cast<AEGP_LightType>(AEGP_LightType_NONE);
        if (lightSuite->AEGP_GetLightType(layer, &lightType)) continue;

        auto oneD = [&](AEGP_LayerStream which, double fallback) {
            AEGP_StreamVal2 v;
            AEFX_CLR_STRUCT(v);
            AEGP_StreamType t = AEGP_StreamType_NO_DATA;
            if (streams->AEGP_GetLayerStreamValue(layer, which, AEGP_LTimeMode_CompTime, &compTime,
                                                  FALSE, &v, &t)) return fallback;
            return static_cast<double>(v.one_d);
        };

        const double intensity = oneD(AEGP_LayerStream_INTENSITY, 100.0);
        float colour[3] = { 1.0f, 1.0f, 1.0f };
        {
            AEGP_StreamVal2 v;
            AEFX_CLR_STRUCT(v);
            AEGP_StreamType t = AEGP_StreamType_NO_DATA;
            if (!streams->AEGP_GetLayerStreamValue(layer, AEGP_LayerStream_COLOR, AEGP_LTimeMode_CompTime,
                                                   &compTime, FALSE, &v, &t)) {
                colour[0] = static_cast<float>(v.color.redF);
                colour[1] = static_cast<float>(v.color.greenF);
                colour[2] = static_cast<float>(v.color.blueF);
            }
            // AE's colours arrive the way the effect's output leaves: undone the same way.
            if (decodeColour)
                for (float& c : colour) c = cloud::decodeSrgb(c);
        }
        const float k = static_cast<float>(intensity / 100.0) * strength;

        if (lightType == AEGP_LightType_AMBIENT) {
            for (int c = 0; c < 3; ++c)
                ambient[c] += (k > 0.0f ? k : 0.0f) * colour[c] * cloud::kAmbientRadiancePerIntensity;
            ++ambientCount;
            diagLog("  comp light %d: ambient, intensity %.1f%% -- a dome of %.3f",
                    static_cast<int>(i + 1), intensity,
                    static_cast<double>(k * cloud::kAmbientRadiancePerIntensity));
            continue;
        }
        if (lightType != AEGP_LightType_POINT && lightType != AEGP_LightType_SPOT &&
            lightType != AEGP_LightType_PARALLEL) {
            ++skipped;
            diagLog("  comp light %d: type %d not read (environment lights are the sky's job)",
                    static_cast<int>(i + 1), static_cast<int>(lightType));
            continue;
        }

        A_Matrix4 xf;
        AEFX_CLR_STRUCT(xf);
        if (layers->AEGP_GetLayerToWorldXform(layer, &compTime, &xf)) {
            ++skipped;
            continue;
        }
        const double pos[3] = { xf.mat[3][0], xf.mat[3][1], xf.mat[3][2] };
        const double axis[3] = { xf.mat[2][0], xf.mat[2][1], xf.mat[2][2] };

        cloud::LocalLight L;
        L.kind = lightType == AEGP_LightType_SPOT     ? cloud::LightKind::Spot
               : lightType == AEGP_LightType_PARALLEL ? cloud::LightKind::Parallel
                                                      : cloud::LightKind::Point;
        cloud::compPointToWorld(frame, view, pos, L.position);
        cloud::compDirectionToWorld(frame, view, axis, L.direction);
        for (int c = 0; c < 3; ++c) L.color[c] = colour[c];
        L.intensity = k;

        // THE FALLOFF: AEGP_LightFalloffType, 0-based -- None, Smooth, Inverse Square
        // Clamped. The raw number is logged, so a host that counts from 1 shows itself.
        const double falloff  = oneD(AEGP_LayerStream_LIGHT_FALLOFF_TYPE, 0.0);
        const double radiusPx = oneD(AEGP_LayerStream_LIGHT_FALLOFF_START, 500.0);
        const double fadePx   = oneD(AEGP_LayerStream_LIGHT_FALLOFF_DISTANCE, 500.0);
        L.radius = static_cast<float>((radiusPx > 1.0 ? radiusPx : 1.0) * frame.along);
        if (std::lround(falloff) == AEGP_LightFalloff_SMOOTH && fadePx > 0.0)
            L.smoothFalloff = static_cast<float>(fadePx * frame.along);

        if (L.kind == cloud::LightKind::Spot) {
            L.coneAngleDeg = static_cast<float>(oneD(AEGP_LayerStream_CONE_ANGLE, 90.0));
            L.coneFeather  = static_cast<float>(oneD(AEGP_LayerStream_CONE_FEATHER, 50.0) / 100.0);
        }

        diagLog("  comp light %d: %s at comp (%.1f, %.1f, %.1f) px -> (%.0f, %.0f, %.0f) m, "
                "intensity %.1f%%, colour (%.3f, %.3f, %.3f), falloff %.0f radius %.0f px = %.0f m%s",
                static_cast<int>(i + 1),
                L.kind == cloud::LightKind::Spot ? "spot"
                : L.kind == cloud::LightKind::Parallel ? "parallel" : "point",
                pos[0], pos[1], pos[2],
                static_cast<double>(L.position[0]), static_cast<double>(L.position[1]),
                static_cast<double>(L.position[2]), intensity,
                static_cast<double>(colour[0]), static_cast<double>(colour[1]),
                static_cast<double>(colour[2]), falloff, radiusPx,
                static_cast<double>(L.radius),
                L.smoothFalloff > 0.0f ? ", smooth" : "");
        out.push_back(L);
    }

    diagLog("  comp lights: %d read, %d ambient, %d not read; %.3f m/px across, %.3f along (%s)",
            static_cast<int>(out.size()), ambientCount, skipped, frame.across, frame.along,
            compCamera ? "comp camera" : "onto the orbit rig");
    return static_cast<int>(out.size());
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
