// Tests for the field fingerprint.
//
// THE COVERAGE TEST IS THE IMPORTANT ONE HERE, not the "same input hashes the
// same" one. A hash that misses a parameter still passes every sanity check you
// can write about it -- it is stable, it is cheap, it distinguishes the things it
// does look at. It just silently ignores one slider, and the symptom reaches the
// user as "I moved this and nothing happened".
//
// So the shape of this file is: one mutator per hashable parameter, and a loop
// asserting that every single one of them moves the hash. Adding a parameter
// without adding it to the list here leaves a gap that Fingerprint.cpp's sizeof
// assert will catch at compile time -- but only if someone also updates the size,
// which is exactly the moment to come back and add the line below.

#include "TestFramework.h"

#include "Fingerprint.h"

#include <functional>
#include <string>
#include <vector>

using namespace plugin;
using namespace plugin::cloud;
using namespace plugin::sim;

namespace {

uint64_t hashOf(const FieldParams& f) {
    Fingerprint fp;
    fp.add(f);
    return fp.value();
}

// One named edit to a FieldParams. The name is in the failure message, so a gap
// says which parameter is unhashed rather than just that one is.
struct Mutation {
    const char* name;
    std::function<void(FieldParams&)> apply;
};

// EVERY HASHABLE PARAMETER, one line each. Keep this in the same order as the
// structs in CloudParams.h so a missing line is visible by reading down.
std::vector<Mutation> allMutations() {
    return {
        // PhysicsParams
        { "physics.clamp",            [](FieldParams& f) { f.physics.clamp = PhysicsClamp::Unbound; } },
        { "physics.gravity",          [](FieldParams& f) { f.physics.gravity += 1.0f; } },
        { "physics.scaleHeight",      [](FieldParams& f) { f.physics.scaleHeight += 100.0f; } },
        { "physics.surfacePressure",  [](FieldParams& f) { f.physics.surfacePressure += 100.0f; } },
        { "physics.surfaceTemp",      [](FieldParams& f) { f.physics.surfaceTemp += 1.0f; } },
        { "physics.lapseRate",        [](FieldParams& f) { f.physics.lapseRate += 0.001f; } },
        { "physics.planetRadius",     [](FieldParams& f) { f.physics.planetRadius += 1000.0f; } },
        { "physics.surfaceHumidity",  [](FieldParams& f) { f.physics.surfaceHumidity += 0.05f; } },

        // AtmosphereParams
        { "atmosphere.sunAzimuth",       [](FieldParams& f) { f.atmosphere.sunAzimuth += 1.0f; } },
        { "atmosphere.sunElevation",     [](FieldParams& f) { f.atmosphere.sunElevation += 1.0f; } },
        { "atmosphere.sunAngularRadius", [](FieldParams& f) { f.atmosphere.sunAngularRadius += 0.01f; } },
        { "atmosphere.sunIntensity",     [](FieldParams& f) { f.atmosphere.sunIntensity += 0.1f; } },
        { "atmosphere.turbidity",        [](FieldParams& f) { f.atmosphere.turbidity += 0.1f; } },
        { "atmosphere.mieAnisotropy",    [](FieldParams& f) { f.atmosphere.mieAnisotropy += 0.01f; } },
        { "atmosphere.groundAlbedo",     [](FieldParams& f) { f.atmosphere.groundAlbedo += 0.05f; } },
        { "atmosphere.cloudShadowsInMedium",
                                         [](FieldParams& f) { f.atmosphere.cloudShadowsInMedium = false; } },
        { "atmosphere.showSunDisc",      [](FieldParams& f) { f.atmosphere.showSunDisc = false; } },

        // IceParams
        { "ice.enabled",         [](FieldParams& f) { f.ice.enabled = false; } },
        { "ice.cellAltitude",    [](FieldParams& f) { f.ice.cellAltitude += 100.0f; } },
        { "ice.cellDensity",     [](FieldParams& f) { f.ice.cellDensity += 0.05f; } },
        { "ice.cellSize",        [](FieldParams& f) { f.ice.cellSize += 50.0f; } },
        { "ice.cellStrength",    [](FieldParams& f) { f.ice.cellStrength += 0.1f; } },
        { "ice.habit",           [](FieldParams& f) { f.ice.habit = IceHabit::Dendrite; } },
        { "ice.fallSpeedScale",  [](FieldParams& f) { f.ice.fallSpeedScale += 0.1f; } },
        { "ice.sublimationRate", [](FieldParams& f) { f.ice.sublimationRate += 0.05f; } },
        { "ice.streakLength",    [](FieldParams& f) { f.ice.streakLength += 100.0f; } },
        { "ice.opticalDepth",    [](FieldParams& f) { f.ice.opticalDepth += 0.05f; } },
        { "ice.detailAmount",    [](FieldParams& f) { f.ice.detailAmount += 0.05f; } },
        { "ice.detailScale",     [](FieldParams& f) { f.ice.detailScale += 10.0f; } },
        { "ice.detailOctaves",   [](FieldParams& f) { f.ice.detailOctaves += 1; } },

        // ConvectionParams
        { "convection.enabled",         [](FieldParams& f) { f.convection.enabled = !f.convection.enabled; } },
        { "convection.cellSize",        [](FieldParams& f) { f.convection.cellSize += 100.0f; } },
        { "convection.polarity",        [](FieldParams& f) { f.convection.polarity += 0.1f; } },
        { "convection.coverage",        [](FieldParams& f) { f.convection.coverage += 0.05f; } },
        { "convection.instability",     [](FieldParams& f) { f.convection.instability += 0.05f; } },
        { "convection.inversionHeight", [](FieldParams& f) { f.convection.inversionHeight += 100.0f; } },
        { "convection.density",         [](FieldParams& f) { f.convection.density += 0.005f; } },
        { "convection.billowAmount",    [](FieldParams& f) { f.convection.billowAmount += 10.0f; } },
        { "convection.billowScale",     [](FieldParams& f) { f.convection.billowScale += 10.0f; } },
        { "convection.billowOctaves",   [](FieldParams& f) { f.convection.billowOctaves += 1; } },
        { "convection.windSpeed",       [](FieldParams& f) { f.convection.windSpeed += 1.0f; } },
        { "convection.windBearing",     [](FieldParams& f) { f.convection.windBearing += 5.0f; } },
        { "convection.lifetime",        [](FieldParams& f) { f.convection.lifetime += 60.0f; } },
        { "convection.dropletDiameter", [](FieldParams& f) { f.convection.dropletDiameter += 2.0f; } },

        // The hero (build 15), which this list missed until build 20.
        { "convection.heroMode",      [](FieldParams& f) { f.convection.heroMode += 1; } },
        { "convection.heroX",         [](FieldParams& f) { f.convection.heroX += 100.0f; } },
        { "convection.heroZ",         [](FieldParams& f) { f.convection.heroZ += 100.0f; } },
        { "convection.heroWidth",     [](FieldParams& f) { f.convection.heroWidth += 100.0f; } },
        { "convection.heroHeight",    [](FieldParams& f) { f.convection.heroHeight -= 0.1f; } },
        { "convection.heroVariation", [](FieldParams& f) { f.convection.heroVariation += 0.5f; } },

        // OrganizationParams, both layers' (build 20)
        { "convection.organization.mode",          [](FieldParams& f) { f.convection.organization.mode = 1; } },
        { "convection.organization.aspectRatio",   [](FieldParams& f) { f.convection.organization.aspectRatio += 0.5f; } },
        { "convection.organization.alignment",     [](FieldParams& f) { f.convection.organization.alignment += 5.0f; } },
        { "convection.organization.coherence",     [](FieldParams& f) { f.convection.organization.coherence += 0.1f; } },
        { "convection.organization.waveLength",    [](FieldParams& f) { f.convection.organization.waveLength += 100.0f; } },
        { "convection.organization.waveAmplitude", [](FieldParams& f) { f.convection.organization.waveAmplitude += 0.1f; } },
        { "convection.organization.waveAngle",     [](FieldParams& f) { f.convection.organization.waveAngle += 5.0f; } },
        { "convection.organization.gapFraction",   [](FieldParams& f) { f.convection.organization.gapFraction += 0.1f; } },
        { "convection.organization.lacunarity",    [](FieldParams& f) { f.convection.organization.lacunarity += 0.1f; } },
        { "ice.organization.mode",          [](FieldParams& f) { f.ice.organization.mode = 1; } },
        { "ice.organization.aspectRatio",   [](FieldParams& f) { f.ice.organization.aspectRatio += 0.5f; } },
        { "ice.organization.alignment",     [](FieldParams& f) { f.ice.organization.alignment += 5.0f; } },
        { "ice.organization.coherence",     [](FieldParams& f) { f.ice.organization.coherence += 0.1f; } },
        { "ice.organization.waveLength",    [](FieldParams& f) { f.ice.organization.waveLength += 100.0f; } },
        { "ice.organization.waveAmplitude", [](FieldParams& f) { f.ice.organization.waveAmplitude += 0.1f; } },
        { "ice.organization.waveAngle",     [](FieldParams& f) { f.ice.organization.waveAngle += 5.0f; } },
        { "ice.organization.gapFraction",   [](FieldParams& f) { f.ice.organization.gapFraction += 0.1f; } },
        { "ice.organization.lacunarity",    [](FieldParams& f) { f.ice.organization.lacunarity += 0.1f; } },

        // PareidoliaParams (build 21). The picture itself is not a parameter; its hash is
        // folded into the render key by the effect, and TestPareidolia checks it moves.
        { "convection.pareidolia.channel",   [](FieldParams& f) { f.convection.pareidolia.channel = 1; } },
        { "convection.pareidolia.threshold", [](FieldParams& f) { f.convection.pareidolia.threshold += 0.1f; } },
        { "convection.pareidolia.decay",     [](FieldParams& f) { f.convection.pareidolia.decay += 0.1f; } },
        { "convection.pareidolia.depth",     [](FieldParams& f) { f.convection.pareidolia.depth += 0.1f; } },
        { "convection.pareidolia.billows",   [](FieldParams& f) { f.convection.pareidolia.billows += 0.1f; } },
        { "convection.pareidolia.facing",    [](FieldParams& f) { f.convection.pareidolia.facing = 1; } },
        { "convection.pareidolia.bearing",   [](FieldParams& f) { f.convection.pareidolia.bearing += 5.0f; } },
        // Relief (build 27). The depth map is a picture too, and in the map's hash.
        { "convection.pareidolia.reliefChannel",  [](FieldParams& f) { f.convection.pareidolia.reliefChannel = 1; } },
        { "convection.pareidolia.reliefDepth",    [](FieldParams& f) { f.convection.pareidolia.reliefDepth += 0.1f; } },
        { "convection.pareidolia.reliefSoftness", [](FieldParams& f) { f.convection.pareidolia.reliefSoftness += 0.1f; } },
        { "convection.pareidolia.reliefDetail",   [](FieldParams& f) { f.convection.pareidolia.reliefDetail += 0.1f; } },

        // FieldParams itself
        { "timeSeconds", [](FieldParams& f) { f.timeSeconds += 1.0f; } },
        { "seed",        [](FieldParams& f) { f.seed += 1u; } },
    };
}

} // namespace

// --------------------------------------------------------------------------
// The basics
// --------------------------------------------------------------------------

PL_TEST(SameFieldHashesTheSame) {
    const FieldParams a;
    const FieldParams b;
    PL_CHECK_EQ(hashOf(a), hashOf(b));
}

PL_TEST(HashingIsOrderIndependentAcrossRuns) {
    // Two separate Fingerprint objects fed the same field must agree, or the
    // hash is carrying state from somewhere it should not be.
    FieldParams f;
    f.ice.cellAltitude = 7300.0f;

    Fingerprint one, two;
    one.add(f);
    two.add(f);
    PL_CHECK_EQ(one.value(), two.value());
}

// --------------------------------------------------------------------------
// Coverage: the test this file exists for
// --------------------------------------------------------------------------

PL_TEST(EveryFieldParameterChangesTheHash) {
    const FieldParams base;
    const uint64_t baseHash = hashOf(base);

    for (const Mutation& m : allMutations()) {
        FieldParams edited = base;
        m.apply(edited);

        const uint64_t editedHash = hashOf(edited);
        if (editedHash == baseHash) {
            // Spelled out rather than PL_CHECK'd so the message names the
            // parameter. "A parameter is unhashed" is not actionable; "ice.habit
            // is unhashed" is a one-line fix.
            ::pltest::reportFailure(__FILE__, __LINE__,
                std::string("unhashed parameter: ") + m.name +
                " -- editing it leaves the cached field in place");
        }
    }
}

PL_TEST(EveryShearKnotChangesTheHash) {
    // SEPARATE FROM THE LOOP ABOVE because the shear profile is an array, and an
    // array is the one shape where "hash the struct" can look right and be wrong:
    // a loop that stopped one knot short would pass every test above.
    //
    // The curve IS the streak shape -- it is the hero control of the ice
    // generator -- so a knot that does not reach the hash is a control the user
    // can drag with no effect at all.
    const FieldParams base;
    const uint64_t baseHash = hashOf(base);

    for (int k = 0; k < kShearKnots; ++k) {
        FieldParams speedEdit = base;
        speedEdit.ice.shear.speed[k] += 1.0f;
        if (hashOf(speedEdit) == baseHash) {
            ::pltest::reportFailure(__FILE__, __LINE__,
                "unhashed shear speed knot " + std::to_string(k));
        }

        FieldParams bearingEdit = base;
        bearingEdit.ice.shear.bearing[k] += 1.0f;
        if (hashOf(bearingEdit) == baseHash) {
            ::pltest::reportFailure(__FILE__, __LINE__,
                "unhashed shear bearing knot " + std::to_string(k));
        }
    }
}

PL_TEST(SwappingTwoShearKnotsChangesTheHash) {
    // A hash that summed the knots instead of feeding them in order would give
    // the same answer for a curve read backwards -- and a shear profile read
    // backwards is a fallstreak hooking the wrong way.
    FieldParams a;
    FieldParams b = a;
    std::swap(b.ice.shear.speed[0], b.ice.shear.speed[kShearKnots - 1]);
    PL_CHECK(hashOf(a) != hashOf(b));
}

// --------------------------------------------------------------------------
// The quantized helper
// --------------------------------------------------------------------------

PL_TEST(QuantizedLengthAbsorbsSubMillimetreNoise) {
    // An AE parameter typed as 9000 m comes back through the host's fixed-point
    // conversion as 8999.9995 often enough to matter. Bitwise that is an edit on
    // every poll and the field rebuilds for ever.
    Fingerprint exact, noisy;
    exact.addQuantized(9000.0f);
    noisy.addQuantized(9000.0004f);
    PL_CHECK_EQ(exact.value(), noisy.value());
}

PL_TEST(QuantizedLengthStillSeesARealEdit) {
    // ...and the slack must not be so generous that a real change hides in it.
    // One millimetre is the grain; two are distinguishable.
    Fingerprint a, b;
    a.addQuantized(9000.0f);
    b.addQuantized(9000.002f);
    PL_CHECK(a.value() != b.value());
}
