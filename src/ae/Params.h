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
    /* ---------------- Ice and fallstreaks ---------------- */                         \
    /* THE FIRST GENERATOR, AND UNTIL NOW NOT ONE OF ITS PARAMETERS REACHED THE PANEL.  \
     * The kernel has marched a real cirrus field since 2026-09-28 -- IceParams is      \
     * plumbed through SlangBridge.h and hashed into the fingerprint -- but             \
     * FieldParams::ice was never assigned from a control, so every render anyone has   \
     * ever seen used the struct's defaults. One sky, unreachable. This group is that   \
     * gap and nothing else.                                                            \
     *                                                                                  \
     * IT GOES HERE, BETWEEN SKY AND PHYSICS, RATHER THAN APPENDED. Group order is      \
     * screen order, so appending would have put the clouds below Quality and Output.   \
     * Inserting rewires saved projects, which is FREE TODAY AND NEVER AGAIN: nothing   \
     * has shipped, and PLAN.md fixes the layout at the v0.5 hand-out.                  \
     *                                                                                  \
     * NO ENABLE CHECKBOX, and that is deliberate. IceParams::enabled is hashed but no  \
     * backend reads it -- the `enabled` flags in TransportLib.slang belong to the      \
     * MAJORANT GRID, not to the generator. A control that silently does nothing is     \
     * worse than no control, so its slot is a reserved spare below and the checkbox    \
     * arrives with the code that honours it. */                                        \
    TOPIC   (IceGroup,          500, "Ice and Fallstreaks")                             \
    /* WHERE THE CRYSTALS ARE MADE. Cirrus generates between about 6 and 12 km; the     \
     * valid range reaches 100 km because the Unbound physics clamp and the v2          \
     * noctilucent generator both live above the slider. */                             \
    FLOAT   (IceCellAltitude,   501, "Generating Level",                                \
             0.0, 100000.0,   3000.0, 14000.0,   9000.0,  0)                            \
    FLOAT   (IceCellDensity,    502, "Cell Density",                                    \
             0.0, 1.0,        0.0, 1.0,          0.35,    3)                            \
    /* A DIVISOR in cellField(), which is why the valid minimum is 1 m and not 0: AE    \
     * clamps an expression to the VALID range, so that bound is the guard. */          \
    FLOAT   (IceCellSize,       503, "Cell Size",                                       \
             1.0, 100000.0,   100.0, 5000.0,     900.0,   0)                            \
    FLOAT   (IceCellStrength,   504, "Cell Strength",                                   \
             0.0, 1000.0,     0.0, 4.0,          1.0,     3)                            \
    /* NOT COSMETIC. Habit sets fall speed, and fall speed against the shear profile IS \
     * the streak shape -- habitFallSpeed() spans 0.28 to 1.4 m/s across these five,    \
     * which is the difference between a fallstreak and a featureless sheet. Default 2  \
     * is 1-based for Column. */                                                        \
    POPUP   (IceHabit,          505, "Crystal Habit", 5, 2,                             \
             "Plate|Column|Bullet Rosette|Dendrite|Aggregate")                          \
    FLOAT   (IceFallSpeedScale, 506, "Fall Speed",                                      \
             0.0, 1000.0,     0.0, 4.0,          1.0,     3)                            \
    FLOAT   (IceStreakLength,   507, "Streak Length",                                   \
             0.0, 100000.0,   0.0, 10000.0,      2600.0,  0)                            \
    /* THE VALID RANGE GOES NEGATIVE ON PURPOSE. A negative rate is deposition -- the   \
     * crystal grows as it falls -- and depthFactorBound() already takes the maximum at \
     * both ends of each interval precisely because the sign can flip. The bound stays  \
     * sound there, so the range has no reason to forbid it. */                         \
    FLOAT   (IceSublimation,    508, "Sublimation",                                     \
             -10.0, 100.0,    0.0, 2.0,          0.55,    3)                            \
    FLOAT   (IceOpticalDepth,   509, "Optical Depth",                                   \
             0.0, 1000.0,     0.0, 3.0,          0.45,    3)                            \
    FLOAT   (IceDetailAmount,   510, "Detail",                                          \
             0.0, 1.0,        0.0, 1.0,          0.7,     3)                            \
    FLOAT   (IceDetailScale,    511, "Detail Scale",                                    \
             1.0, 100000.0,   20.0, 1000.0,      140.0,   0)                            \
    /* SIX IS WHAT THE MATHS ALLOWS, not a comfortable limit. fbm() in                  \
     * GeneratorLib.slang loops to a hard 6 and breaks early, so a seventh octave is a  \
     * control that moves nothing. The valid range stops where the loop does. */        \
    FLOAT   (IceDetailOctaves,  512, "Detail Octaves",                                  \
             1.0, 6.0,        1.0, 6.0,          4.0,     0)                            \
    /* THE SHEAR PROFILE: SIX KNOTS, TOP TO BOTTOM, AND IT IS THE HERO CONTROL.         \
     * Knot 1 is the generating level and knot 6 the bottom of the fall streak. The     \
     * streak shape is the integral of wind over fall speed, so these twelve sliders    \
     * ARE the shape rather than a modifier on it.                                      \
     *                                                                                  \
     * TWELVE SLIDERS IS THE PHASE 2 SHAPE PLAN.md ASKS FOR, not a compromise reached   \
     * here: the SDK ships no curve control and no sample of one, so the real editor is \
     * an arbitrary-data parameter with custom UI, sized as its own Phase 4 task. The   \
     * DATA shape does not change when it arrives, so nothing downstream moves.         \
     *                                                                                  \
     * BEARINGS ARE ANGLE DIALS because a bearing is a compass reading and wraps. They  \
     * are where the wind comes FROM, which is why shearWindAt() negates. A TURNING     \
     * wind is what makes a fallstreak hook rather than trail -- cirrus uncinus rather  \
     * than fibratus -- so the defaults back off 30 degrees down the profile. */        \
    FLOAT   (IceShearSpeed0,    513, "Wind Speed 1 (Top)",                              \
             0.0, 1000.0,     0.0, 80.0,         34.0,    1)                            \
    FLOAT   (IceShearSpeed1,    514, "Wind Speed 2",                                    \
             0.0, 1000.0,     0.0, 80.0,         30.0,    1)                            \
    FLOAT   (IceShearSpeed2,    515, "Wind Speed 3",                                    \
             0.0, 1000.0,     0.0, 80.0,         25.0,    1)                            \
    FLOAT   (IceShearSpeed3,    516, "Wind Speed 4",                                    \
             0.0, 1000.0,     0.0, 80.0,         19.0,    1)                            \
    FLOAT   (IceShearSpeed4,    517, "Wind Speed 5",                                    \
             0.0, 1000.0,     0.0, 80.0,         13.0,    1)                            \
    FLOAT   (IceShearSpeed5,    518, "Wind Speed 6 (Bottom)",                           \
             0.0, 1000.0,     0.0, 80.0,         8.0,     1)                            \
    ANGLE   (IceShearBearing0,  519, "Wind From 1 (Top)",    270.0)                     \
    ANGLE   (IceShearBearing1,  520, "Wind From 2",          268.0)                     \
    ANGLE   (IceShearBearing2,  521, "Wind From 3",          264.0)                     \
    ANGLE   (IceShearBearing3,  522, "Wind From 4",          258.0)                     \
    ANGLE   (IceShearBearing4,  523, "Wind From 5",          250.0)                     \
    ANGLE   (IceShearBearing5,  524, "Wind From 6 (Bottom)", 240.0)                     \
    /* IceSpare1 IS EARMARKED FOR THE ENABLE CHECKBOX, per the note on the group. */    \
    SPARE   (IceSpare1,         525)                                                    \
    SPARE   (IceSpare2,         526)                                                    \
    SPARE   (IceSpare3,         527)                                                    \
    SPARE   (IceSpare4,         528)                                                    \
    ENDTOPIC(IceGroupEnd,       529)                                                    \
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
    /* DEFAULT 1, NOT 64. The Phase 1 sky is analytic and a sample only jitters the     \
     * ray inside the pixel, so 64 of them cost 64x the render time and change nothing  \
     * outside the horizon row -- measured at most 2/255 everywhere else. On the CPU    \
     * path, the only one that exists until CUDA is built, 64 made a full-HD frame take \
     * 3m43s and After Effects cancelled it before it ever finished. The VALID RANGE is \
     * left wide open for the Phase 2 transport that will need it; see CloudParams.h. */\
    FLOAT   (Samples,           301, "Samples",                                           \
             1.0, 65536.0,  1.0, 512.0,      1.0,    0)                                   \
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

inline cloud::IceParams toIce(const ParamValues& p) {
    cloud::IceParams out;

    out.cellAltitude = static_cast<float>(p.v[kMistytuneIceCellAltitude]);
    out.cellDensity  = static_cast<float>(p.v[kMistytuneIceCellDensity]);
    out.cellSize     = static_cast<float>(p.v[kMistytuneIceCellSize]);
    out.cellStrength = static_cast<float>(p.v[kMistytuneIceCellStrength]);

    // CLAMPED TO THE ENUMERATORS THAT EXIST, like PhysicsClamp above. The popup
    // cannot produce anything else, but a cast of an out-of-range integer to a
    // scoped enum is undefined behaviour rather than a wrong crystal -- and
    // habitFallSpeed()'s switch has no default label, so it would fall through to a
    // speed nobody chose.
    const int habit = static_cast<int>(std::lround(p.v[kMistytuneIceHabit]));
    out.habit = static_cast<cloud::IceHabit>(habit < 0 ? 0 : (habit > 4 ? 4 : habit));

    out.fallSpeedScale  = static_cast<float>(p.v[kMistytuneIceFallSpeedScale]);
    out.streakLength    = static_cast<float>(p.v[kMistytuneIceStreakLength]);
    out.sublimationRate = static_cast<float>(p.v[kMistytuneIceSublimation]);
    out.opticalDepth    = static_cast<float>(p.v[kMistytuneIceOpticalDepth]);
    out.detailAmount    = static_cast<float>(p.v[kMistytuneIceDetailAmount]);
    out.detailScale     = static_cast<float>(p.v[kMistytuneIceDetailScale]);

    // THE VALID RANGE ALREADY STOPS AT 6 and AE clamps an expression to it, so this
    // is the second line of defence rather than the first. It is here because the
    // cost is a comparison and the failure it guards is silent: fbm() breaks out of
    // its loop early, so a seventh octave would render identically to six and read
    // as a control the plugin ignores.
    int octaves = static_cast<int>(std::lround(p.v[kMistytuneIceDetailOctaves]));
    if (octaves < 0) octaves = 0;
    if (octaves > 6) octaves = 6;
    out.detailOctaves = static_cast<int32_t>(octaves);

    // ---------------------------------------------------------------------
    // THE SHEAR KNOTS, WRITTEN OUT RATHER THAN INDEXED.
    //
    // `kMistytuneIceShearSpeed0 + k` would work today, because the table puts the
    // six rows next to each other and the enum follows the table. It is exactly the
    // index arithmetic this file exists to remove, and it would keep compiling after
    // someone inserted a row into the middle of the block.
    //
    // THE static_assert IS THE TRIPWIRE. Raise kShearKnots and this stops compiling
    // until the sliders to match it exist -- which is the same bargain Fingerprint.h
    // strikes with sizeof, and for the same reason: a profile whose last knots were
    // never filled renders as a streak that straightens out near the bottom, and
    // nothing about that picture says which file is wrong.
    // ---------------------------------------------------------------------
    static_assert(cloud::kShearKnots == 6,
                  "kShearKnots changed; add or remove the matching shear sliders in "
                  "MISTYTUNE_PARAM_TABLE and the rows below. APPEND ONLY -- see the "
                  "header of this file on why an inserted row rewires saved projects.");

    const double speed[cloud::kShearKnots] = {
        p.v[kMistytuneIceShearSpeed0], p.v[kMistytuneIceShearSpeed1],
        p.v[kMistytuneIceShearSpeed2], p.v[kMistytuneIceShearSpeed3],
        p.v[kMistytuneIceShearSpeed4], p.v[kMistytuneIceShearSpeed5]
    };
    const double bearing[cloud::kShearKnots] = {
        p.v[kMistytuneIceShearBearing0], p.v[kMistytuneIceShearBearing1],
        p.v[kMistytuneIceShearBearing2], p.v[kMistytuneIceShearBearing3],
        p.v[kMistytuneIceShearBearing4], p.v[kMistytuneIceShearBearing5]
    };

    for (int k = 0; k < cloud::kShearKnots; ++k) {
        out.shear.speed[k] = static_cast<float>(speed[k]);

        // NOT WRAPPED TO 0..360, DELIBERATELY. An AE angle dial accumulates
        // revolutions, so a bearing keyframed twice round arrives here as 990 rather
        // than 270 -- and shearWindAt() resolves each knot to a vector through sin
        // and cos before it interpolates, which is periodic. Wrapping here would
        // change nothing about the render and would break the one case the dial is
        // good at: keyframing a wind that turns through north without snapping back.
        out.shear.bearing[k] = static_cast<float>(bearing[k]);
    }

    // `enabled` is left at its default. No backend reads it -- see the note on the
    // Ice group in the table -- so there is no control to read it from.
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
