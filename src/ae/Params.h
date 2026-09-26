#pragma once

// THE PARAMETER TABLE, WRITTEN ONCE.
//
// The enum, PF_Cmd_PARAMS_SETUP and the checkout are all generated from the single
// list in MISTYTUNE_PARAM_TABLE below. Nothing in this file counts indices by
// hand, and nothing outside it may.
//
// ===========================================================================
// WHY IT IS A MACRO TABLE AND NOT THREE LISTS THAT AGREE.
//
// AFTER EFFECTS PARAMETER INDICES ARE POSITIONS, AND AE STORES VALUES BY POSITION.
// A saved project holds "parameter 7 = 0.42", not "Turbidity = 0.42". So:
//
//   * Reordering or deleting a shipped parameter silently rewires every saved
//     project. Not an error, not a warning -- the user's Turbidity turns up in
//     Ground Albedo.
//   * The UI order IS the index order, so inserting a control into an early group
//     later would put it on screen after every later group.
//   * Parameter IDs are a SEPARATE namespace from indices and must never be
//     reused, because AE matches old projects through them.
//
// Three hand-maintained lists -- an enum, a setup function and a checkout function
// -- drift, and every one of those drifts is silent. One list cannot.
// ===========================================================================
//
// APPENDING IS THE ONLY SAFE CHANGE, which is why every group ends with hidden
// SPARE slots. A spare is a real parameter occupying a real index, invisible in
// the UI, reserved so that a later layer-local control can be turned on IN PLACE
// rather than appended after every other group. Turning a spare into a control is
// free; inserting a row is not.
//
// RANGES GO IN AS WIDE AS THE MATHS ALLOWS, from the start. PF_UpdateParamUI
// cannot change a valid range -- only AE re-running PARAMS_SETUP after a version
// change can -- and a valid range that is too narrow does not merely clamp: it
// SILENTLY FLATTENS expression-driven and keyframed values, which presents to the
// user as a broken expression rather than as a clamped parameter. The slider range
// is the comfortable range; the valid range is the possible one.

#include "AEConfig.h"
#include "entry.h"
#include "AE_Effect.h"
#include "AE_EffectCB.h"
#include "AE_EffectSuites.h"
#include "AE_Macros.h"
#include "Param_Utils.h"

#include "CloudParams.h"

#include <cmath>

namespace plugin {
namespace ae {

// ---------------------------------------------------------------------------
// THE TABLE
// ---------------------------------------------------------------------------
//
// Every row is:  KIND(name, id, ...)
//
//   TOPIC   (name, id, label)                       a collapsible group header
//   ENDTOPIC(name, id)                              ...and its end. IT IS A REAL
//                                                   PARAMETER SLOT -- AE spends an
//                                                   index on it, so it needs a
//                                                   name in the enum like anything
//                                                   else.
//   FLOAT   (name, id, label, validMin, validMax,
//            sliderMin, sliderMax, dflt, precision) a float slider
//   ANGLE   (name, id, label, dflt)                 degrees, stored as 16.16 fixed
//   POPUP   (name, id, label, count, dflt1, items)  1-BASED default; items are
//                                                   "A|B|C"
//   CHECK   (name, id, label, dflt)                 a checkbox
//   TEXT    (name, id, label)                       a static-text readout; see
//                                                   addStaticText below
//   SPARE   (name, id)                              reserved, hidden, unused
//
// IDs ARE PERMANENT AND ARE NEVER REUSED. They are written out explicitly rather
// than derived from the row's position, precisely so that deleting a row cannot
// hand its number to its neighbour. Blocks of 100 per group, so a group can grow
// to 100 controls before anyone has to think about it.
//
// THE ORDER OF THE GROUPS IS THE ORDER ON SCREEN. Sun and Sky first because it is
// what a user reaches for; Physics second because it is the proof the model is
// real; Quality and Output last because they are settings rather than creative
// controls.

#define MISTYTUNE_PARAM_TABLE(TOPIC, ENDTOPIC, FLOAT, ANGLE, POPUP, CHECK, TEXT, SPARE) \
    /* ---------------- Sun and Sky ---------------- */                                 \
    TOPIC   (SkyGroup,          100, "Sun and Sky")                                     \
    ANGLE   (SunAzimuth,        101, "Sun Azimuth", 135.0)                              \
    /* Elevation goes BELOW the horizon in the valid range, though the slider stops     \
     * at -10: the nacreous and noctilucent generators are lit by a sun below the       \
     * horizon, and that is v2 work whose range must already be keyframable. */         \
    FLOAT   (SunElevation,      102, "Sun Elevation",                                   \
             -90.0, 90.0,   -10.0, 90.0,    12.0,    2)                                 \
    /* 0.266 deg is the Sun from Earth. A PARAMETER, not a constant: it is what makes    \
     * a shadow edge soft, and the softness of a cloud's shadow edge is much of how     \
     * large the cloud reads as being. The valid range reaches 30 deg for a red giant.*/\
    FLOAT   (SunAngularRadius,  103, "Sun Size",                                        \
             0.001, 30.0,   0.05, 2.0,      0.266,   3)                                 \
    FLOAT   (SunIntensity,      104, "Sun Intensity",                                   \
             0.0, 10000.0,  0.0, 4.0,       1.0,     3)                                 \
    /* Linke turbidity. 1 is pristine; 64 is a dust storm. */                           \
    FLOAT   (Turbidity,         105, "Turbidity",                                       \
             1.0, 64.0,     1.0, 10.0,      2.2,     2)                                 \
    FLOAT   (MieAnisotropy,     106, "Aerosol Forward Bias",                            \
             -0.95, 0.95,   0.0, 0.95,      0.76,    3)                                 \
    FLOAT   (GroundAlbedo,      107, "Ground Albedo",                                   \
             0.0, 1.0,      0.0, 1.0,       0.1,     3)                                 \
    CHECK   (CloudShadowsInMedium, 108, "Cloud Shadows In Air", true)                    \
    SPARE   (SkySpare1,         109)                                                     \
    SPARE   (SkySpare2,         110)                                                     \
    SPARE   (SkySpare3,         111)                                                     \
    SPARE   (SkySpare4,         112)                                                     \
    ENDTOPIC(SkyGroupEnd,       113)                                                     \
                                                                                        \
    /* ---------------- Physics ---------------- */                                      \
    /* EARTH BY DEFAULT, and the alien presets live in a clearly labelled demo group     \
     * rather than at the top of the panel. The alien skies are the proof the tab is     \
     * real; they should not be the first thing a realism buyer sees. */                 \
    TOPIC   (PhysicsGroup,      200, "Physics")                                          \
    POPUP   (PhysicsClamp,      201, "Realism", 3, 1, "Earth|Earth-like|Unbound")         \
    FLOAT   (Gravity,           202, "Gravity",                                          \
             0.01, 1000.0,  0.5, 30.0,      9.80665, 4)                                  \
    FLOAT   (ScaleHeight,       203, "Scale Height",                                     \
             100.0, 200000.0, 1000.0, 20000.0, 8500.0, 1)                                \
    FLOAT   (SurfaceHumidity,   204, "Surface Humidity",                                 \
             0.0, 1.0,      0.0, 1.0,       0.7,     3)                                   \
    SPARE   (PhysicsSpare1,     205)                                                      \
    SPARE   (PhysicsSpare2,     206)                                                      \
    SPARE   (PhysicsSpare3,     207)                                                      \
    SPARE   (PhysicsSpare4,     208)                                                      \
    ENDTOPIC(PhysicsGroupEnd,   209)                                                      \
                                                                                         \
    /* ---------------- Quality ---------------- */                                       \
    TOPIC   (QualityGroup,      300, "Quality")                                           \
    FLOAT   (Samples,           301, "Samples",                                           \
             1.0, 65536.0,  1.0, 512.0,     64.0,    0)                                   \
    FLOAT   (MaxBounces,        302, "Max Bounces",                                        \
             1.0, 1024.0,   1.0, 64.0,      32.0,    0)                                   \
    CHECK   (Denoise,           303, "Denoise", true)                                      \
    SPARE   (QualitySpare1,     304)                                                       \
    SPARE   (QualitySpare2,     305)                                                       \
    SPARE   (QualitySpare3,     306)                                                       \
    ENDTOPIC(QualityGroupEnd,   307)                                                       \
                                                                                          \
    /* ---------------- Output ---------------- */                                         \
    TOPIC   (OutputGroup,       400, "Output")                                             \
    /* REAL EV. The render is linear float and the tonemap is off by default, so this      \
     * is the only thing between the physical radiance and the pixel. */                   \
    FLOAT   (ExposureEV,        401, "Exposure",                                           \
             -30.0, 30.0,   -6.0, 6.0,      0.0,     2)                                    \
    /* OFF BY DEFAULT and it must stay that way: an effect that tonemapped unasked         \
     * would be fighting whatever the user's own grade is doing downstream. */             \
    CHECK   (AgxTonemap,        402, "AgX Tonemap", false)                                 \
    /* The classifier readout: what the user has actually made. Static text, which AE      \
     * has no control for -- see addStaticText below. */                                    \
    TEXT    (Classification,    403, "--")                                                 \
    SPARE   (OutputSpare1,      404)                                                       \
    SPARE   (OutputSpare2,      405)                                                       \
    ENDTOPIC(OutputGroupEnd,    406)

// ---------------------------------------------------------------------------
// The enum, generated
// ---------------------------------------------------------------------------

// Each kind contributes exactly one index, INCLUDING ENDTOPIC and SPARE. Getting
// that wrong is the whole class of bug this file exists to prevent.
#define MT_ENUM_TOPIC(name, id, label)                          kMistytune##name,
#define MT_ENUM_ENDTOPIC(name, id)                              kMistytune##name,
#define MT_ENUM_FLOAT(name, id, label, vn, vx, sn, sx, d, p)    kMistytune##name,
#define MT_ENUM_ANGLE(name, id, label, d)                       kMistytune##name,
#define MT_ENUM_POPUP(name, id, label, n, d, items)             kMistytune##name,
#define MT_ENUM_CHECK(name, id, label, d)                       kMistytune##name,
#define MT_ENUM_TEXT(name, id, label)                           kMistytune##name,
#define MT_ENUM_SPARE(name, id)                                 kMistytune##name,

enum ParamIndex {
    // INDEX 0 IS THE INPUT LAYER, ALWAYS, and PARAMS_SETUP does not add it -- AE
    // provides it. Leaving it out of the enum would put every generated index one
    // too low, which is the single most common way to get this wrong.
    kMistytuneInput = 0,

    MISTYTUNE_PARAM_TABLE(MT_ENUM_TOPIC, MT_ENUM_ENDTOPIC, MT_ENUM_FLOAT,
                          MT_ENUM_ANGLE, MT_ENUM_POPUP, MT_ENUM_CHECK,
                          MT_ENUM_TEXT, MT_ENUM_SPARE)

    kMistytuneNumParams
};

#undef MT_ENUM_TOPIC
#undef MT_ENUM_ENDTOPIC
#undef MT_ENUM_FLOAT
#undef MT_ENUM_ANGLE
#undef MT_ENUM_POPUP
#undef MT_ENUM_CHECK
#undef MT_ENUM_TEXT
#undef MT_ENUM_SPARE

// The permanent IDs, in their own namespace. Generated from the same rows so an ID
// cannot be typed twice or skipped.
#define MT_ID_TOPIC(name, id, label)                          kMistytuneId##name = (id),
#define MT_ID_ENDTOPIC(name, id)                              kMistytuneId##name = (id),
#define MT_ID_FLOAT(name, id, label, vn, vx, sn, sx, d, p)    kMistytuneId##name = (id),
#define MT_ID_ANGLE(name, id, label, d)                       kMistytuneId##name = (id),
#define MT_ID_POPUP(name, id, label, n, d, items)             kMistytuneId##name = (id),
#define MT_ID_CHECK(name, id, label, d)                       kMistytuneId##name = (id),
#define MT_ID_TEXT(name, id, label)                           kMistytuneId##name = (id),
#define MT_ID_SPARE(name, id)                                 kMistytuneId##name = (id),

enum ParamId {
    MISTYTUNE_PARAM_TABLE(MT_ID_TOPIC, MT_ID_ENDTOPIC, MT_ID_FLOAT,
                          MT_ID_ANGLE, MT_ID_POPUP, MT_ID_CHECK,
                          MT_ID_TEXT, MT_ID_SPARE)
    kMistytuneIdLast
};

#undef MT_ID_TOPIC
#undef MT_ID_ENDTOPIC
#undef MT_ID_FLOAT
#undef MT_ID_ANGLE
#undef MT_ID_POPUP
#undef MT_ID_CHECK
#undef MT_ID_TEXT
#undef MT_ID_SPARE

// ---------------------------------------------------------------------------
// Static text, which the parameter API has no control for
// ---------------------------------------------------------------------------

// A READOUT, NOT AN INPUT. The parameter's NAME carries the message and
// PF_UpdateParamUI rewrites it; the control itself is suppressed.
//
// PF_PUI_STD_CONTROL_ONLY REQUIRES PF_ParamFlag_SUPERVISE. That pairing is
// mandated by the SDK, not a choice -- without SUPERVISE the UI flag does nothing
// and the slider appears.
//
// PF_ParamFlag_CANNOT_TIME_VARY as well, because a readout with a stopwatch beside
// it invites the user to keyframe something that is an output.
//
// TWO OF THESE ARE PLANNED. This one names what the user has made; the other, in
// Phase 4, is the MEASURED pareidolia legibility from the shape-context matcher --
// which is what lets Decay be specified in real units and lets the user keyframe
// perceived legibility rather than input strength.
inline PF_Err addStaticText(PF_InData* in_data, const char* label, A_long id) {
    PF_ParamDef def;
    AEFX_CLR_STRUCT(def);

    def.param_type = PF_Param_FLOAT_SLIDER;
    def.flags      = PF_ParamFlag_SUPERVISE | PF_ParamFlag_CANNOT_TIME_VARY;
    def.ui_flags   = PF_PUI_STD_CONTROL_ONLY;
    PF_STRNNCPY(def.PF_DEF_NAME, label, sizeof(def.PF_DEF_NAME));

    def.u.fs_d.valid_min  = 0.0;
    def.u.fs_d.valid_max  = 1.0;
    def.u.fs_d.slider_min = 0.0;
    def.u.fs_d.slider_max = 1.0;
    def.u.fs_d.value      = 0.0;
    def.u.fs_d.dephault   = 0.0;
    def.uu.id             = id;

    return PF_ADD_PARAM(in_data, -1, &def);
}

// ---------------------------------------------------------------------------
// PARAMS_SETUP, generated
// ---------------------------------------------------------------------------

#define MT_SETUP_TOPIC(name, id, label) \
    PF_ADD_TOPICX(label, PF_ParamFlag_START_COLLAPSED, id);

#define MT_SETUP_ENDTOPIC(name, id) \
    PF_END_TOPIC(id);

#define MT_SETUP_FLOAT(name, id, label, vmin, vmax, smin, smax, dflt, prec) \
    PF_ADD_FLOAT_SLIDERX(label, vmin, vmax, smin, smax, dflt, prec,         \
                         PF_ValueDisplayFlag_NONE, 0, id);

#define MT_SETUP_ANGLE(name, id, label, dflt) \
    do { AEFX_CLR_STRUCT(def); PF_ADD_ANGLE(label, dflt, id); } while (0);

#define MT_SETUP_POPUP(name, id, label, count, dflt, items) \
    PF_ADD_POPUPX(label, count, dflt, items, 0, id);

#define MT_SETUP_CHECK(name, id, label, dflt) \
    PF_ADD_CHECKBOXX(label, dflt, 0, id);

#define MT_SETUP_TEXT(name, id, label)                                   \
    do {                                                                 \
        const PF_Err textErr = addStaticText(in_data, label, id);         \
        if (textErr) return textErr;                                     \
    } while (0);

// A SPARE IS A REAL PARAMETER. PF_PUI_INVISIBLE keeps it off the panel while it
// holds its index, which is the entire point: a later control turns this on in
// place instead of landing after every group that came after it.
//
// PF_ParamFlag_CANNOT_TIME_VARY so that nothing can be keyframed into a slot whose
// meaning has not been decided yet -- otherwise a project could arrive with data
// in a parameter that later means something different.
// NOTE THE PARAMETER NAME: `pid`, NOT `id`.
//
// A macro parameter is substituted everywhere its spelling appears, INCLUDING IN A
// MEMBER ACCESS. Naming it `id` turns `def.uu.id = (id)` into `def.uu.109 = (109)`,
// and the compiler then reports a syntax error whose text mentions neither the macro
// nor the member. The SDK's own PF_ADD_* macros get away with `ID` because C++ is
// case-sensitive; anything written here has to avoid the collision deliberately.
#define MT_SETUP_SPARE(name, pid)                                             \
    do {                                                                      \
        AEFX_CLR_STRUCT(def);                                                 \
        def.param_type = PF_Param_FLOAT_SLIDER;                               \
        def.flags      = PF_ParamFlag_CANNOT_TIME_VARY;                       \
        def.ui_flags   = PF_PUI_INVISIBLE;                                    \
        PF_STRNNCPY(def.PF_DEF_NAME, "(reserved)", sizeof(def.PF_DEF_NAME));   \
        def.u.fs_d.valid_min  = 0.0;                                          \
        def.u.fs_d.valid_max  = 1.0;                                          \
        def.u.fs_d.slider_min = 0.0;                                          \
        def.u.fs_d.slider_max = 1.0;                                          \
        def.u.fs_d.value = def.u.fs_d.dephault = 0.0;                         \
        def.uu.id = (pid);                                                    \
        const PF_Err spareErr = PF_ADD_PARAM(in_data, -1, &def);               \
        if (spareErr) return spareErr;                                        \
    } while (0);

inline PF_Err paramsSetup(PF_InData* in_data, PF_OutData* out_data) {
    PF_ParamDef def;
    AEFX_CLR_STRUCT(def);

    MISTYTUNE_PARAM_TABLE(MT_SETUP_TOPIC, MT_SETUP_ENDTOPIC, MT_SETUP_FLOAT,
                          MT_SETUP_ANGLE, MT_SETUP_POPUP, MT_SETUP_CHECK,
                          MT_SETUP_TEXT, MT_SETUP_SPARE)

    // AE COMPARES THIS AGAINST THE NUMBER OF PARAMETERS ACTUALLY ADDED, and the
    // count comes from the same table that added them -- so it cannot be one out.
    out_data->num_params = kMistytuneNumParams;
    return PF_Err_NONE;
}

#undef MT_SETUP_TOPIC
#undef MT_SETUP_ENDTOPIC
#undef MT_SETUP_FLOAT
#undef MT_SETUP_ANGLE
#undef MT_SETUP_POPUP
#undef MT_SETUP_CHECK
#undef MT_SETUP_TEXT
#undef MT_SETUP_SPARE

// ---------------------------------------------------------------------------
// Checkout, generated
// ---------------------------------------------------------------------------

// Every parameter's value as a double, indexed by ParamIndex.
//
// ONE ARRAY RATHER THAN A STRUCT OF NAMED FIELDS, because the dangerous part of
// reading parameters is the INDEX arithmetic and that is what generating this
// removes. The mapping from a value to the struct member it means stays
// hand-written below, where it is a statement about physics rather than about
// positions.
struct ParamValues {
    double v[kMistytuneNumParams] = { 0.0 };
};

// SMART RENDER DOES NOT GET THE PARAMS ARRAY. It has to check each one out, which
// is why this exists as a function rather than as a field access.
//
// CHECKED IN AGAIN ON EVERY PATH, including the failure paths: a parameter checked
// out and not checked back in leaks a host reference, and AE reports that as an
// unrelated failure much later.
#define MT_READ_TOPIC(name, id, label)                          /* no value */
#define MT_READ_ENDTOPIC(name, id)                              /* no value */
#define MT_READ_SPARE(name, id)                                 /* not read */
#define MT_READ_TEXT(name, id, label)                           /* a readout */

#define MT_READ_FLOAT(name, id, label, vn, vx, sn, sx, d, p)                   \
    if (!err) {                                                                \
        AEFX_CLR_STRUCT(def);                                                  \
        err = PF_CHECKOUT_PARAM(in_data, kMistytune##name, in_data->current_time,\
                                in_data->time_step, in_data->time_scale, &def); \
        if (!err) {                                                            \
            out.v[kMistytune##name] = def.u.fs_d.value;                        \
            PF_CHECKIN_PARAM(in_data, &def);                                   \
        }                                                                      \
    }

// ANGLES ARE PF_Fixed: DEGREES IN 16.16 FIXED POINT. Divided here, once, rather
// than wherever the value is used.
#define MT_READ_ANGLE(name, id, label, d)                                      \
    if (!err) {                                                                \
        AEFX_CLR_STRUCT(def);                                                  \
        err = PF_CHECKOUT_PARAM(in_data, kMistytune##name, in_data->current_time,\
                                in_data->time_step, in_data->time_scale, &def); \
        if (!err) {                                                            \
            out.v[kMistytune##name] = def.u.ad.value / 65536.0;                \
            PF_CHECKIN_PARAM(in_data, &def);                                   \
        }                                                                      \
    }

// POPUPS ARE 1-BASED IN AE and 0-based in every enum we own. Converted here, once.
#define MT_READ_POPUP(name, id, label, n, d, items)                            \
    if (!err) {                                                                \
        AEFX_CLR_STRUCT(def);                                                  \
        err = PF_CHECKOUT_PARAM(in_data, kMistytune##name, in_data->current_time,\
                                in_data->time_step, in_data->time_scale, &def); \
        if (!err) {                                                            \
            out.v[kMistytune##name] = static_cast<double>(def.u.pd.value - 1); \
            PF_CHECKIN_PARAM(in_data, &def);                                   \
        }                                                                      \
    }

#define MT_READ_CHECK(name, id, label, d)                                      \
    if (!err) {                                                                \
        AEFX_CLR_STRUCT(def);                                                  \
        err = PF_CHECKOUT_PARAM(in_data, kMistytune##name, in_data->current_time,\
                                in_data->time_step, in_data->time_scale, &def); \
        if (!err) {                                                            \
            out.v[kMistytune##name] = def.u.bd.value ? 1.0 : 0.0;              \
            PF_CHECKIN_PARAM(in_data, &def);                                   \
        }                                                                      \
    }

inline PF_Err readParams(PF_InData* in_data, ParamValues& out) {
    PF_Err err = PF_Err_NONE;
    PF_ParamDef def;

    MISTYTUNE_PARAM_TABLE(MT_READ_TOPIC, MT_READ_ENDTOPIC, MT_READ_FLOAT,
                          MT_READ_ANGLE, MT_READ_POPUP, MT_READ_CHECK,
                          MT_READ_TEXT, MT_READ_SPARE)

    return err;
}

#undef MT_READ_TOPIC
#undef MT_READ_ENDTOPIC
#undef MT_READ_FLOAT
#undef MT_READ_ANGLE
#undef MT_READ_POPUP
#undef MT_READ_CHECK
#undef MT_READ_TEXT
#undef MT_READ_SPARE

// ---------------------------------------------------------------------------
// Values -> the engine's structs
// ---------------------------------------------------------------------------
//
// HAND-WRITTEN ON PURPOSE, and it is the one part of this file that should be.
// Each line says what a control MEANS, which is a claim about physics that a macro
// cannot make and that a reader needs to be able to check.

inline cloud::PhysicsParams toPhysics(const ParamValues& p) {
    cloud::PhysicsParams out;

    const int clamp = static_cast<int>(std::lround(p.v[kMistytunePhysicsClamp]));
    out.clamp = static_cast<cloud::PhysicsClamp>(clamp < 0 ? 0 : (clamp > 2 ? 2 : clamp));

    out.gravity         = static_cast<float>(p.v[kMistytuneGravity]);
    out.scaleHeight     = static_cast<float>(p.v[kMistytuneScaleHeight]);
    out.surfaceHumidity = static_cast<float>(p.v[kMistytuneSurfaceHumidity]);

    // THE EARTH CLAMP IS APPLIED HERE, not in the UI, and that is deliberate.
    //
    // Disabling the sliders would be friendlier and would also be a lie: an
    // expression or a keyframe can drive a disabled parameter, so the UI is not
    // where a physical constraint can be enforced. Pinning the value on the way
    // through is the only place it actually holds.
    //
    // The sliders are left enabled under the clamp so that they read as the real
    // constants -- which is the point of the tab.
    if (out.clamp == cloud::PhysicsClamp::Earth) {
        const cloud::PhysicsParams earth;   // the defaults ARE Earth
        out.gravity     = earth.gravity;
        out.scaleHeight = earth.scaleHeight;
    }

    // Left at their Earth values until Phase 4 gives them controls. The spare slots
    // in the Physics group are reserved for exactly these.
    return out;
}

inline cloud::AtmosphereParams toAtmosphere(const ParamValues& p) {
    cloud::AtmosphereParams out;
    out.sunAzimuth       = static_cast<float>(p.v[kMistytuneSunAzimuth]);
    out.sunElevation     = static_cast<float>(p.v[kMistytuneSunElevation]);
    out.sunAngularRadius = static_cast<float>(p.v[kMistytuneSunAngularRadius]);
    out.sunIntensity     = static_cast<float>(p.v[kMistytuneSunIntensity]);
    out.turbidity        = static_cast<float>(p.v[kMistytuneTurbidity]);
    out.mieAnisotropy    = static_cast<float>(p.v[kMistytuneMieAnisotropy]);
    out.groundAlbedo     = static_cast<float>(p.v[kMistytuneGroundAlbedo]);
    out.cloudShadowsInMedium = p.v[kMistytuneCloudShadowsInMedium] > 0.5;
    return out;
}

inline cloud::QualityParams toQuality(const ParamValues& p) {
    cloud::QualityParams out;
    out.samplesPerPixel = static_cast<int32_t>(std::lround(p.v[kMistytuneSamples]));
    out.maxBounces      = static_cast<int32_t>(std::lround(p.v[kMistytuneMaxBounces]));
    out.denoise         = p.v[kMistytuneDenoise] > 0.5;

    // AT LEAST ONE OF EACH, whatever the parameter says. The valid range starts at
    // 1, but an expression can still deliver 0 on the frame where it divides by
    // something -- and zero samples is a black frame the user cannot explain.
    if (out.samplesPerPixel < 1) out.samplesPerPixel = 1;
    if (out.maxBounces < 1)      out.maxBounces = 1;
    return out;
}

} // namespace ae
} // namespace plugin
