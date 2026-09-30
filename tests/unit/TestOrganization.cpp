// The Organization group, resolved: the host's half of it (src/engine/Organization.h).
//
// THE KERNEL'S HALF IS slang.convection AND slang.generator, which set the kernel's struct
// directly and check the bounds and the look on it. These check the step between: that a
// control lands in the numbers the kernel reads, that each mode is the setting it says,
// and above all that THE DEFAULTS ARE OFF -- which is what keeps every render before
// build 20 bit for bit.

#include "TestFramework.h"

#include "Organization.h"

#include <cmath>
#include <limits>

using namespace plugin;
using namespace plugin::cloud;

// NOTHING SET IS NOTHING ON, and neither is a Rows Along keyframed round to where it was.
PL_TEST(TheDefaultsAreNoOrganization) {
    OrganizationParams p;
    PL_CHECK(!resolveOrganization(p, true).on);
    PL_CHECK(!resolveOrganization(p, false).on);

    p.alignment = 450.0f;
    PL_CHECK(!resolveOrganization(p, true).on);
    p.alignment = -270.0f;
    PL_CHECK(!resolveOrganization(p, true).on);

    // Anything else turns it on, including the alignment alone: it turns the lattice.
    p.alignment = 91.0f;
    PL_CHECK(resolveOrganization(p, true).on);
}

// AT 90 DEGREES THE ROWS RUN ALONG +X, which is where the lattice always had them.
PL_TEST(NinetyDegreesIsTheWorldFrame) {
    OrganizationParams p;
    p.coherence = 0.5f;   // on, with the alignment at its default
    const OrganizationResolved o = resolveOrganization(p, true);
    PL_CHECK(o.on);
    PL_CHECK_NEAR(o.axisX, 1.0, 1e-7);
    PL_CHECK_NEAR(o.axisZ, 0.0, 1e-7);

    // And bearings go clockwise from +Z, like the winds: 0 is +Z.
    p.alignment = 0.0f;
    const OrganizationResolved n = resolveOrganization(p, true);
    PL_CHECK_NEAR(n.axisX, 0.0, 1e-7);
    PL_CHECK_NEAR(n.axisZ, 1.0, 1e-7);
}

// EACH MODE IS THE SETTING ITS NAME SAYS.
PL_TEST(TheModesAreSettings) {
    OrganizationParams p;
    p.aspectRatio = 1.5f;
    p.coherence   = 0.6f;
    p.waveAngle   = 30.0f;

    p.mode = static_cast<int32_t>(OrganizationMode::Rolls);
    OrganizationResolved o = resolveOrganization(p, true);
    PL_CHECK_NEAR(o.stretch, 1.5 * kRollStretch, 1e-6);
    PL_CHECK_NEAR(o.coherence, 0.6, 1e-6);

    // Waves: the rows turn to run along the crests, and the wave is at least its floor.
    p.mode = static_cast<int32_t>(OrganizationMode::Waves);
    o = resolveOrganization(p, true);
    PL_CHECK_NEAR(o.stretch, 1.5 * kWavesStretch, 1e-6);
    PL_CHECK_NEAR(o.axisX, std::sin(30.0 * 0.017453292519943295), 1e-6);
    PL_CHECK_NEAR(o.axisZ, std::cos(30.0 * 0.017453292519943295), 1e-6);
    PL_CHECK_NEAR(o.waveAmplitude, kWavesMinAmplitude, 1e-6);
    p.waveAmplitude = 0.9f;
    PL_CHECK_NEAR(resolveOrganization(p, true).waveAmplitude, 0.9, 1e-6);

    // Chaotic: warped, and the rows' coherence dropped whatever the slider says.
    p.mode = static_cast<int32_t>(OrganizationMode::Chaotic);
    o = resolveOrganization(p, true);
    PL_CHECK_NEAR(o.warp, kChaoticWarp, 1e-6);
    PL_CHECK_NEAR(o.coherence, 0.0, 0.0);
    PL_CHECK_NEAR(o.stretch, 1.5, 1e-6);
}

// THE WAVE VARIES ACROSS ITS CRESTS: its vector is perpendicular to them, one cycle per
// wavelength.
PL_TEST(TheWaveRunsAcrossItsCrests) {
    OrganizationParams p;
    p.waveAmplitude = 0.5f;
    p.waveLength    = 2500.0f;
    p.waveAngle     = 70.0f;
    const OrganizationResolved o = resolveOrganization(p, true);
    const double b = 70.0 * 0.017453292519943295;
    const double crestX = std::sin(b), crestZ = std::cos(b);
    PL_CHECK_NEAR(o.waveKX * crestX + o.waveKZ * crestZ, 0.0, 1e-9);
    PL_CHECK_NEAR(std::sqrt(o.waveKX * o.waveKX + o.waveKZ * o.waveKZ), 1.0 / 2500.0, 1e-9);
}

// A NaN OR AN OUT-OF-RANGE VALUE FROM AN EXPRESSION COMES OUT AS A NUMBER THE KERNEL'S
// BOUNDS HOLD FOR: a stretch of at least 1, a wavelength of at least 10 m, fractions in
// [0, 1], a mode that exists.
PL_TEST(ExpressionsCannotBreakTheBounds) {
    const float nan = std::numeric_limits<float>::quiet_NaN();
    OrganizationParams p;
    p.mode          = 17;
    p.aspectRatio   = nan;
    p.coherence     = 3.0f;
    p.waveLength    = -5.0f;
    p.waveAmplitude = nan;
    p.alignment     = nan;
    p.gapFraction   = -1.0f;
    p.lacunarity    = 9.0f;
    const OrganizationResolved o = resolveOrganization(p, true);
    PL_CHECK(o.on);
    PL_CHECK(o.stretch >= 1.0f && std::isfinite(o.stretch));
    PL_CHECK_NEAR(o.coherence, 1.0, 0.0);
    PL_CHECK_NEAR(o.waveAmplitude, 0.0, 0.0);
    PL_CHECK_NEAR(std::sqrt(o.waveKX * o.waveKX + o.waveKZ * o.waveKZ), 0.1, 1e-6);
    PL_CHECK(std::isfinite(o.axisX) && std::isfinite(o.axisZ));
    PL_CHECK_NEAR(o.gapWidth, 0.0, 0.0);
    PL_CHECK_NEAR(o.lacunarity, 1.0, 0.0);
    PL_CHECK_NEAR(o.warp, 0.0, 0.0);
}

// THE ICE LAYER HAS NO GAPS OR HOLES: its cells are separate heads already.
PL_TEST(TheIceLayerIgnoresGapsAndHoles) {
    OrganizationParams p;
    p.gapFraction = 0.5f;
    p.lacunarity  = 0.5f;
    const OrganizationResolved ice = resolveOrganization(p, false);
    PL_CHECK(!ice.on);
    PL_CHECK_NEAR(ice.gapWidth, 0.0, 0.0);
    PL_CHECK_NEAR(ice.lacunarity, 0.0, 0.0);

    const OrganizationResolved deck = resolveOrganization(p, true);
    PL_CHECK(deck.on);
    PL_CHECK_NEAR(deck.gapWidth, std::sqrt(0.5) * kGapWidthMax, 1e-6);
    PL_CHECK_NEAR(deck.lacunarity, 0.5, 1e-6);
}
