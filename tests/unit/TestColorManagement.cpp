// Whether the renderer encodes its own output, decided from the project rather than
// assumed of it.
//
// ===========================================================================
// WHAT THIS FILE IS GUARDING, AND IT IS NOT THE ARITHMETIC.
//
// encodesSrgbForHost() is four branches over three bools and a float. Nothing in it is
// hard. What is hard is that EVERY ONE OF ITS ANSWERS RENDERS A PLAUSIBLE PICTURE:
// getting it wrong is one sRGB encode, which reads as a grading choice or a mood, and
// the project has already shipped that exact bug once -- 32 and 16 bpc rendered the
// same comp differently for an entire phase and neither looked wrong on its own.
//
// SO THE TESTS THAT MATTER ARE THE ONES ABOUT THE DEFAULTS, not the ones about the
// rules. A default-constructed HostColorSettings must decide `true`, because that is
// the constant this decision replaced and the one configuration confirmed in the host.
// Any future edit that makes a failed read decide `false` would silently darken every
// render on every machine where the AEGP calls do not answer -- which is a class of
// machine nobody here can enumerate.
//
// AND THE HOLE IS TESTED AS A HOLE. "Linearize Working Color Space" has no API, so a
// linearised sRGB project is served wrongly and knowably. There is a test below that
// asserts the wrong answer on purpose, so that the day someone finds a way to read that
// checkbox, a test fails and points at the reason it existed.
// ===========================================================================

#include "TestFramework.h"

#include "ColorManagement.h"

using namespace plugin;
using namespace plugin::cloud;

namespace {

// The three project configurations that have names, so the tests read as claims about
// projects rather than about struct fields.

// AE's default: Adobe colour managed, Working Color Space None. Nothing describes a
// working space, so no profile comes back.
HostColorSettings unmanagedProject() {
    HostColorSettings s;
    s.queried = true;
    s.ocioManaged = false;
    s.haveWorkingGamma = false;
    return s;
}

// Adobe colour managed with a real working space, linearisation off.
HostColorSettings encodedWorkingSpace(float gamma) {
    HostColorSettings s;
    s.queried = true;
    s.ocioManaged = false;
    s.haveWorkingGamma = true;
    s.workingGamma = gamma;
    return s;
}

// A scene-linear working space, reported as such.
HostColorSettings linearWorkingSpace() {
    return encodedWorkingSpace(1.0f);
}

HostColorSettings ocioProject() {
    HostColorSettings s;
    s.queried = true;
    s.ocioManaged = true;
    return s;
}

} // namespace

// ---------------------------------------------------------------------------
// The defaults, which are the part that must not move
// ---------------------------------------------------------------------------

// THE ONE THAT MATTERS MOST. A HostColorSettings nobody filled in is what every failure
// path in readHostColorSettings() returns -- no SP suite, no AEGP plugin id, no colour
// settings suite, a host that is not After Effects at all. All of them must render what
// this effect rendered before it asked anything.
PL_TEST(AnUnaskedHostGetsTheBehaviourThatShipped) {
    const HostColorSettings nothing;
    PL_CHECK_EQ(nothing.queried, false);
    PL_CHECK_EQ(encodesSrgbForHost(nothing), true);
}

// A HALF-ANSWER IS NOT AN ANSWER. The suite was acquired, so `queried` is true, but
// neither of the two facts came back. Reaching further into the struct than the flags
// allow is how a zeroed float turns into a claim about a working space.
PL_TEST(AQueriedHostThatAnsweredNothingStillEncodes) {
    HostColorSettings partial;
    partial.queried = true;
    PL_CHECK_EQ(encodesSrgbForHost(partial), true);
}

// THE FLOAT ALONE MUST NOT DECIDE ANYTHING. A_FpShort comes back zero from a call that
// half-failed, and zero is below the linear ceiling -- so if haveWorkingGamma were ever
// dropped from the condition, a failed gamma query would read as "linear" and flip the
// default project. This is the test that notices.
PL_TEST(AZeroGammaIsNotLinearItIsNoAnswer) {
    PL_CHECK_EQ(isLinearWorkingGamma(0.0f), false);
    PL_CHECK_EQ(isLinearWorkingGamma(-1.0f), false);

    HostColorSettings zeroed;
    zeroed.queried = true;
    zeroed.haveWorkingGamma = false;
    zeroed.workingGamma = 0.0f;
    PL_CHECK_EQ(encodesSrgbForHost(zeroed), true);
}

// ---------------------------------------------------------------------------
// The rules
// ---------------------------------------------------------------------------

// Working Space None. AE applies no transform at any bit depth -- measured in AE 2026,
// and it is the configuration the host confirmation was done in.
PL_TEST(AnUnmanagedProjectEncodesItsOwnOutput) {
    PL_CHECK_EQ(encodesSrgbForHost(unmanagedProject()), true);
}

// OCIO owns the display transform, so ours would be the second of two.
PL_TEST(AnOcioProjectLeavesTheDisplayTransformToTheHost) {
    PL_CHECK_EQ(encodesSrgbForHost(ocioProject()), false);
}

// OCIO WINS OVER THE GAMMA, and it has to: an OCIO config's working space is
// scene-linear whatever a profile query makes of it, so the flag is the stronger fact.
PL_TEST(OcioDecidesEvenWhenAProfileReportsACurve) {
    HostColorSettings s = ocioProject();
    s.haveWorkingGamma = true;
    s.workingGamma = 2.2f;
    PL_CHECK_EQ(encodesSrgbForHost(s), false);
}

PL_TEST(ALinearWorkingSpaceIsWrittenLinear) {
    PL_CHECK_EQ(encodesSrgbForHost(linearWorkingSpace()), false);
}

// sRGB, Rec.709, Adobe RGB and Rec.2020 all land in 2.2..2.4, and all of them expect a
// buffer that already carries their curve.
PL_TEST(EveryEncodedWorkingSpaceGetsTheCurve) {
    PL_CHECK_EQ(encodesSrgbForHost(encodedWorkingSpace(2.2f)), true);
    PL_CHECK_EQ(encodesSrgbForHost(encodedWorkingSpace(2.4f)), true);
    PL_CHECK_EQ(encodesSrgbForHost(encodedWorkingSpace(1.8f)), true);
}

// THE THRESHOLD SITS IN AN EMPTY GAP, WHICH IS WHY ITS EXACT VALUE CANNOT MATTER.
// Real profiles report 1.0 or something from 1.8 up. If a future edit moved the ceiling
// anywhere inside 1.0..1.8 every answer above would be unchanged; this test pins that
// the gap is genuinely empty of real values rather than that 1.25 is special.
PL_TEST(TheLinearCeilingSitsBetweenTheOnlyTwoAnswersThatOccur) {
    PL_CHECK(kLinearGammaCeiling > 1.0f);
    PL_CHECK(kLinearGammaCeiling < 1.8f);

    PL_CHECK_EQ(isLinearWorkingGamma(1.0f), true);
    PL_CHECK_EQ(isLinearWorkingGamma(1.8f), false);
}

// ---------------------------------------------------------------------------
// The hole, asserted as a hole
// ---------------------------------------------------------------------------

// ===========================================================================
// THIS TEST ASSERTS THE WRONG ANSWER ON PURPOSE.
//
// A project set to working space sRGB with "Linearize Working Color Space" ON holds
// linear pixels and wants encodeSrgb FALSE. There is no API for that checkbox -- the
// AE 25.6 headers expose none -- so all this decision can see is sRGB's gamma, and it
// says TRUE. Such a project renders one sRGB encode too light.
//
// PINNED SO THAT FIXING IT BREAKS SOMETHING. If someone later finds the API, or AE
// starts reporting gamma 1.0 for a linearised space, this test fails -- and its failure
// is the notification that the hole closed, which is the only way a silent improvement
// gets noticed and written down.
// ===========================================================================
PL_TEST(ALinearisedWorkingSpaceIsUnservedAndKnowablySo) {
    // What AE is believed to report for sRGB-with-linearisation: the profile's own
    // gamma, with nothing anywhere saying the linearise box is ticked.
    const HostColorSettings linearisedButReportedAsSrgb = encodedWorkingSpace(2.2f);

    // The right answer is false. This is the answer we give.
    PL_CHECK_EQ(encodesSrgbForHost(linearisedButReportedAsSrgb), true);
}
