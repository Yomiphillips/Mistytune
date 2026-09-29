#pragma once

// What After Effects will do to this buffer between here and the screen, and
// therefore what encoding the renderer has to write into it.
//
// ===========================================================================
// THIS FILE EXISTS BECAUSE `encodeSrgb` WAS A CONSTANT, AND A CONSTANT IS AN ASSUMPTION
// ABOUT SOMEBODY ELSE'S PROJECT.
//
// The entry that introduced ViewParams::encodeSrgb measured AE 2026 with Working Color
// Space None and found that the host applies NO transform at any bit depth -- so a
// generator has to encode its own output, and `true` was hardcoded with the reasoning
// written beside it. That is right for AE's default project and wrong for every
// colour-managed one, where AE applies the display transform itself and our encode
// would be the second of two.
//
// The decision is HERE, in src/engine/, and not in the effect, for the same reason
// CameraConvert.h is: it is arithmetic over a handful of host-reported facts, every
// branch of it is wrong in a way that still renders a plausible picture, and it must be
// exercisable without launching After Effects. src/ae/AEBridge.h does the asking and
// fills in HostColorSettings; this file does the deciding.
//
// ===========================================================================
// AEGP_DoesViewHaveColorSpaceXform IS THE WRONG API, AND IT IS THE ONE THE PREVIOUS
// ENTRY NAMED.
//
// It answers "does this VIEW apply a colour transform", and the view is the comp
// viewer panel. That is not the question. A render-queue export and a background
// render have no view at all, and the encoding the buffer needs cannot depend on
// whether a window happens to be open -- if it did, the preview and the exported file
// would disagree, which is a worse bug than the one being fixed and a harder one to
// see.
//
// What decides the encoding is the PROJECT's colour management, so the project is what
// gets asked: AEGP_IsOCIOColorManagementUsed, and the working space's own profile.
// ===========================================================================

namespace plugin::cloud {

// ---------------------------------------------------------------------------
// What the host was asked, and what it answered
// ---------------------------------------------------------------------------

// RAW HOST FACTS, NOT A CONCLUSION. Every field is something AE reported or failed to
// report; nothing here is derived. The derivation is encodesSrgbForHost() below, which
// is the part worth testing.
//
// DEFAULT-CONSTRUCTED MEANS "THE HOST WAS NOT ASKED, OR DID NOT ANSWER", and
// encodesSrgbForHost() maps that to exactly the behaviour this project shipped before
// any of it existed. A failed read therefore cannot change a render -- which is what
// makes it safe to put this call on the pre-render path at all.
struct HostColorSettings {
    // Did the read get far enough to mean anything? False when the suite could not be
    // acquired, when there is no AEGP plugin id, or when the host is not AE.
    bool queried = false;

    // AEGP_IsOCIOColorManagementUsed. In OCIO mode AE owns the display transform.
    bool ocioManaged = false;

    // AEGP_GetColorProfileApproximateGamma over the comp's working-space profile.
    // haveWorkingGamma is false when no profile came back -- which is itself a signal,
    // because a project with no working space has nothing to describe.
    bool  haveWorkingGamma = false;
    float workingGamma = 0.0f;
};

// ---------------------------------------------------------------------------
// The decision
// ---------------------------------------------------------------------------

// Above this, the working space carries a display transfer curve; below it, it is
// linear and AE will apply the curve itself.
//
// 1.25 IS NOT A TUNING PARAMETER, IT IS THE MIDDLE OF A GAP. The only two answers that
// occur in practice are 1.0 (a linear/scene-referred working space) and something in
// 2.2..2.4 (sRGB, Rec.709, Adobe RGB, Rec.2020). There is nothing between them, so any
// threshold in that gap gives the same answers and the choice cannot matter. Placed
// near the bottom of the gap deliberately: a profile that reports 1.1 for something
// nominally linear should still read as linear.
inline constexpr float kLinearGammaCeiling = 1.25f;

// Is this reported gamma a linear working space?
//
// THE > 0 IS LOAD-BEARING AND NOT A TIDINESS. A_FpShort comes back as zero when the
// call half-fails, and zero is less than the ceiling -- so without this test an
// unanswered query would read as "linear", which is the one wrong answer that flips
// the default project's render.
inline bool isLinearWorkingGamma(float gamma) {
    return gamma > 0.0f && gamma < kLinearGammaCeiling;
}

// Must the renderer apply the sRGB transfer curve itself?
//
// ===========================================================================
// THE RULES, IN ORDER, AND WHAT EACH ONE IS WORTH.
//
//   1. THE READ FAILED -> ENCODE. Exactly what this project did before this file
//      existed, so a host that cannot answer renders what it rendered yesterday. This
//      is the branch that makes the whole read safe to attempt.
//
//   2. OCIO COLOUR MANAGEMENT IS ON -> DO NOT ENCODE. OCIO mode exists precisely so
//      that AE applies a configured view transform on the way to the display.
//      Encoding here would be the second of two transforms and the result is the
//      washed-out look of a double encode.
//
//      THE ORDER OF RULE 2 BEFORE RULE 3 IS LOAD-BEARING, AND THAT IS A MEASUREMENT
//      RATHER THAN A TIDINESS. Measured in AE 2026 on an OCIO-managed project:
//
//          colour raw: ocioErr=0 ocio=1 profileErr=0 haveGamma=1 gamma=2.400
//
//      The working-space profile reports gamma 2.4, NOT 1.0. This comment used to
//      assert that an OCIO working space is the config's scene_linear role, which
//      would have meant a gamma near 1 -- so either that claim is wrong, or
//      AEGP_GetNewWorkingSpaceColorProfile does not describe the OCIO working space
//      and is falling back to something generic (Rec.709's transfer curve is 2.4,
//      which is suspicious). This log cannot tell those two apart.
//
//      WHAT IT DOES SETTLE IS THAT THE GAMMA MUST NOT BE BELIEVED IN OCIO MODE. Rule
//      3 would read 2.4 as "encoded" and give the opposite answer; rule 2 fires first
//      and never asks. The ordering was originally chosen for a reason that may be
//      wrong, and it is right for a reason that is measured.
//
//   3. THE WORKING SPACE IS LINEAR -> DO NOT ENCODE. Same argument without OCIO: if
//      AE is working in linear it is because it intends to apply the display transform
//      downstream.
//
//      STILL UNMEASURED. No non-OCIO managed project has been through this, so no
//      gamma near 1.0 has ever been observed -- the only real reading so far is the
//      2.4 above, which rule 2 discarded.
//
//   4. ANYTHING ELSE -> ENCODE. Covers both Working Space None, where AE applies
//      nothing and the buffer goes to the screen as-is, and a non-linear working space
//      such as sRGB, where the buffer is expected to already carry that space's curve.
//      The two want the same thing from us for different reasons.
//
// ===========================================================================
// WHAT THIS CANNOT SEE, AND IT IS A REAL HOLE RATHER THAN A CAVEAT.
//
// "Linearize Working Color Space" is a project checkbox with NO API. The SDK exposes no
// way to read it -- searched, AE 25.6 headers, nothing. So a project set to working
// space sRGB with linearisation ON is linear in fact and will report sRGB's gamma here,
// and rule 4 will encode when rule 3 was wanted.
//
// That case renders too light, by one sRGB encode. It is not detectable from inside
// this function, it is not detectable from inside the effect, and the honest statement
// is that it is unserved rather than handled. It was equally unserved before this file
// existed -- every colour-managed project was -- so this is a narrowing of the hole and
// not a new one.
// ===========================================================================
inline bool encodesSrgbForHost(const HostColorSettings& settings) {
    if (!settings.queried) return true;
    if (settings.ocioManaged) return false;
    if (settings.haveWorkingGamma && isLinearWorkingGamma(settings.workingGamma)) {
        return false;
    }
    return true;
}

} // namespace plugin::cloud
