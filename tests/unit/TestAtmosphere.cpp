// The transmittance table.
//
// ===========================================================================
// A LOOKUP TABLE IS THE EASIEST THING IN A RENDERER TO GET WRONG QUIETLY.
//
// Every failure mode here produces a SMOOTH, PLAUSIBLE, WRONG sky:
//
//   * the altitude warp inverted with a square instead of a square root -- the sky
//     is simply a bit too clear, everywhere, by an amount that reads as a turbidity
//     choice;
//   * the mu axis flipped -- the horizon gets the zenith's transmittance, which
//     looks like a hazy day rather than like an index error;
//   * texel centres in the build but edges in the sample -- a half-texel shift,
//     worst exactly where the gradient is steepest, which is the sunset;
//   * the ground-shadow case storing the partial path instead of zero -- light
//     leaks through the planet, which looks like ambient.
//
// NONE of those is visible in a render, and all of them are trivially visible
// against a closed form. That is the whole argument for the table living in
// src/engine/ rather than in the kernel: these checks take microseconds and need no
// GPU, no host and no picture.
//
// THE TESTS ARE PHYSICS, NOT REGRESSION. Nothing here compares against a stored
// number that this code produced. Each one states something that has to be true of
// an atmosphere and would still have to be true if the implementation were replaced.
// ===========================================================================

#include "TestFramework.h"

#include "Atmosphere.h"

// The KERNEL's copies of the sampler and of the march the table replaces. plugin_tests
// links plugin_kernel, and on the host Shading.h pulls in no CUDA header -- the same
// arrangement TestCamera.cpp and TestOutputConvert.cpp already use.
#include "Shading.h"

#include <chrono>
#include <cmath>
#include <cstdio>
#include <vector>

using namespace plugin;
using namespace plugin::cloud;

namespace {

TransmittanceParams earth() {
    TransmittanceParams p;
    p.turbidity    = 2.2f;
    p.planetRadius = 6371000.0f;
    p.scaleHeight  = 8500.0f;
    return p;
}

// The built table, once per test that wants one.
std::vector<Real> buildFor(const TransmittanceParams& p) {
    std::vector<Real> lut(static_cast<size_t>(kTransmittanceFloats), -1.0f);
    buildTransmittanceLut(p, lut.data(), kTransmittanceFloats);
    return lut;
}

struct Rgb { Real r, g, b; };

Rgb sampleAt(const std::vector<Real>& lut, const TransmittanceParams& p,
             Real altitude, Real mu) {
    Rgb c{};
    sampleTransmittance(lut.data(), p, altitude, mu, c.r, c.g, c.b);
    return c;
}

const Real kTopAltitude = 8500.0f * 8.0f;   // scaleHeight * kAtmosphereEFoldings

} // namespace

// ---------------------------------------------------------------------------
// The build refuses rather than half-filling
// ---------------------------------------------------------------------------

// A SHORT BUFFER IS NOT PARTIALLY FILLED, because a partially filled table renders a
// sky that is right at the top and black at the bottom -- which reads as a horizon
// bug rather than as a buffer size.
PL_TEST(ABufferTooSmallIsLeftAloneRatherThanOverrun) {
    std::vector<Real> tooSmall(16, -1.0f);
    buildTransmittanceLut(earth(), tooSmall.data(), 16);
    for (Real v : tooSmall) PL_CHECK_EQ(v == -1.0f, 1);

    // And a null buffer is simply ignored rather than dereferenced.
    buildTransmittanceLut(earth(), nullptr, kTransmittanceFloats);
}

PL_TEST(EveryTexelIsWrittenAndIsAValidTransmittance) {
    const std::vector<Real> lut = buildFor(earth());

    int written = 0;
    for (Real v : lut) {
        // -1 was the fill; anything still holding it was never written.
        PL_CHECK(v >= 0.0f);
        PL_CHECK(v <= 1.0f);
        PL_CHECK(!std::isnan(static_cast<double>(v)));
        ++written;
    }
    PL_CHECK_EQ(written, kTransmittanceFloats);
}

// ---------------------------------------------------------------------------
// The closed forms an atmosphere has to satisfy
// ---------------------------------------------------------------------------

// AT THE TOP OF THE ATMOSPHERE, LOOKING UP, THERE IS NOTHING LEFT TO GO THROUGH.
// This is the one exact answer the table has, and it pins the altitude axis at its
// far end: a warp that does not reach the top would land short and never return 1.
PL_TEST(FromTheTopLookingUpNothingIsAbsorbed) {
    const TransmittanceParams p = earth();
    const std::vector<Real> lut = buildFor(p);

    const Rgb c = sampleAt(lut, p, kTopAltitude, 1.0f);
    PL_CHECK_NEAR(c.r, 1.0, 1e-3);
    PL_CHECK_NEAR(c.g, 1.0, 1e-3);
    PL_CHECK_NEAR(c.b, 1.0, 1e-3);
}

// THE SUNSET, AS AN INEQUALITY. Rayleigh scattering goes as roughly lambda^-4, so a
// long slant path removes blue far faster than red. If the channels were ever
// written in the wrong order this is what fails -- and in a render it would merely
// look like a colour grade.
PL_TEST(ALongSlantPathRemovesBlueFastestWhichIsTheSunset) {
    const TransmittanceParams p = earth();
    const std::vector<Real> lut = buildFor(p);

    // Just above the horizon from the ground: the longest path in the table.
    const Rgb low = sampleAt(lut, p, 0.0f, 0.02f);

    PL_CHECK(low.r > low.g);
    PL_CHECK(low.g > low.b);

    // And it is a large effect, not a rounding one -- red survives many times better.
    PL_CHECK(low.r > low.b * 3.0f);

    // Straight up from the same point, the ordering is the same but the whole thing
    // is close to transparent.
    const Rgb up = sampleAt(lut, p, 0.0f, 1.0f);
    PL_CHECK(up.r > up.g);
    PL_CHECK(up.g > up.b);
    PL_CHECK(up.b > 0.5f);
}

// MORE AIR IN THE WAY MEANS LESS LIGHT THROUGH IT, in both axes. Monotonicity is
// what the mu axis being flipped would break, and it would break it completely
// rather than subtly -- which is exactly why it is worth one cheap test.
PL_TEST(TransmittanceFallsAsThePathLengthens) {
    const TransmittanceParams p = earth();
    const std::vector<Real> lut = buildFor(p);

    // Along mu at fixed altitude: straight up is the shortest path through the air.
    Real previous = 2.0f;
    for (int i = 0; i <= 40; ++i) {
        const Real mu = 1.0f - static_cast<Real>(i) * 0.02f;   // 1.0 down to 0.2
        const Rgb c = sampleAt(lut, p, 0.0f, mu);
        PL_CHECK(c.g <= previous + 1e-6f);
        previous = c.g;
    }

    // Along altitude at fixed mu: higher up there is less air above you.
    previous = -1.0f;
    for (int i = 0; i <= 40; ++i) {
        const Real h = kTopAltitude * static_cast<Real>(i) / 40.0f;
        const Rgb c = sampleAt(lut, p, h, 0.3f);
        PL_CHECK(c.g >= previous - 1e-6f);
        previous = c.g;
    }
}

// ===========================================================================
// A RAY THAT MEETS THE PLANET DELIVERS NOTHING -- AND THE PROBE HAS TO BE NEAR
// TANGENT, WHICH THE FIRST VERSION OF THIS TEST GOT WRONG.
//
// That version sampled STRAIGHT DOWN from the ground and asserted zero. It passed --
// and it passed with the ground-shadow branch DELETED, which is how the mistake was
// found. Measured by injecting exactly that fault.
//
// The reason is that without the branch a downward ray is integrated straight through
// the planet, where the altitude clamps to zero and the density therefore sits at its
// sea-level maximum for thousands of kilometres. The optical depth is astronomical and
// exp(-tau) underflows to zero anyway. The test asserted a true thing for a reason
// that had nothing to do with what it was checking.
//
// THE BRANCH ONLY MATTERS NEAR TANGENT, and that is precisely where it matters most:
// a ray grazing just below the horizon cuts a SHORT chord through the planet.
// Computed for this table at sea level, mu = -0.03 passes about 2.9 km under the
// surface, a 382 km subsurface chord, and leaks **10.9% in red** without the branch.
// Just below the horizon is where the sun is at sunset, so the leak lands on the one
// part of the sky the whole table exists to get right.
//
// AT SEA LEVEL THE HORIZON IS ESSENTIALLY mu = 0 (-0.0011 for the bottom row), so
// mu = -0.03 is about four texels below it -- far enough that every bilinear tap is
// blocked and the answer is exactly zero, close enough that the unbranched answer is
// nowhere near underflowing.
// ===========================================================================
PL_TEST(ARayGrazingIntoThePlanetIsFullyBlocked) {
    const TransmittanceParams p = earth();
    const std::vector<Real> lut = buildFor(p);

    // NEAR TANGENT, NOT STRAIGHT DOWN. See above -- straight down cannot fail.
    const Rgb grazeIn = sampleAt(lut, p, 0.0f, -0.03f);
    PL_CHECK_EQ(grazeIn.r == 0.0f, 1);
    PL_CHECK_EQ(grazeIn.g == 0.0f, 1);
    PL_CHECK_EQ(grazeIn.b == 0.0f, 1);

    // Straight down is zero too, and is kept only so the obvious case is covered --
    // it is NOT the case that discriminates.
    const Rgb down = sampleAt(lut, p, 0.0f, -1.0f);
    PL_CHECK_EQ(down.g == 0.0f, 1);

    // FROM HIGH UP, A SHALLOW DOWNWARD RAY STILL ESCAPES, and that is the half a
    // sign test would get backwards: mu < 0 does not mean "blocked". At the top of
    // this atmosphere the horizon sits at mu = -0.144, so a ray tilted 0.10 below
    // level still grazes out to space and must NOT be zero.
    const Rgb grazeOut = sampleAt(lut, p, kTopAltitude, -0.10f);
    PL_CHECK(grazeOut.g > 0.0f);

    // ...AND THE TWO SIDES OF THE HORIZON MUST DISAGREE at the same altitude, which
    // is what stops this passing if everything downward were zero.
    const Rgb below = sampleAt(lut, p, kTopAltitude, -0.20f);
    PL_CHECK_EQ(below.g == 0.0f, 1);
}

// ---------------------------------------------------------------------------
// The axes, which is where an index bug lives
// ---------------------------------------------------------------------------

// THE WARP AND ITS INVERSE HAVE TO BE EACH OTHER. The build distributes altitude by
// v*v and the sampler inverts with a square root; if either changed alone the table
// would still be smooth and still be wrong everywhere.
//
// Checked by landing exactly on texel centres: if the round trip is right, sampling
// at the altitude a texel was built for returns that texel unmixed with its
// neighbours.
PL_TEST(TheAltitudeWarpRoundTrips) {
    const TransmittanceParams p = earth();
    const std::vector<Real> lut = buildFor(p);

    const double topAltitude = double(p.scaleHeight) * 8.0;

    // ONE ASSERTION AFTER THE SWEEP, NOT ONE INSIDE IT -- and it is pltest::Sweep
    // doing it rather than four locals, because this was the THIRD hand-rolled copy
    // of the same counting and the third time the lesson had to be relearned by
    // injecting a fault and watching the output scroll. See TestFramework.h.
    PL_SWEEP(sweep, "sampled texels");

    for (int yi = 0; yi < kTransmittanceAltitudeSize; ++yi) {
        const double v = (double(yi) + 0.5) / double(kTransmittanceAltitudeSize);
        const double r = topAltitude * v * v;   // the altitude this row was built at

        // Texel 128's centre on the mu axis, so the x interpolation is also exact.
        const double u  = (128.0 + 0.5) / double(kTransmittanceMuSize);
        const double mu = u * 2.0 - 1.0;

        const Rgb got = sampleAt(lut, p, static_cast<Real>(r), static_cast<Real>(mu));

        const int idx = (yi * kTransmittanceMuSize + 128) * kTransmittanceChannels;
        const Real want[3] = { lut[idx + 0], lut[idx + 1], lut[idx + 2] };
        const Real have[3] = { got.r, got.g, got.b };

        for (int c = 0; c < 3; ++c) sweep.check(have[c], want[c], 1e-5, yi);
    }

    sweep.finish(kTransmittanceAltitudeSize * 3);
}

// OUT OF RANGE CLAMPS AND DOES NOT WRAP. A wrap on the mu axis fetches the opposite
// hemisphere -- so a ray pointing just past straight up would get the answer for
// straight down, which is zero, and the zenith would have a black speck in it.
PL_TEST(SamplingOutsideTheTableClampsRatherThanWrapping) {
    const TransmittanceParams p = earth();
    const std::vector<Real> lut = buildFor(p);

    const Rgb up     = sampleAt(lut, p, 0.0f, 1.0f);
    const Rgb wayUp  = sampleAt(lut, p, 0.0f, 4.0f);
    PL_CHECK_NEAR(wayUp.g, up.g, 1e-6);

    const Rgb top    = sampleAt(lut, p, kTopAltitude, 0.5f);
    const Rgb wayTop = sampleAt(lut, p, kTopAltitude * 10.0f, 0.5f);
    PL_CHECK_NEAR(wayTop.g, top.g, 1e-6);

    // Below the ground clamps to the ground rather than reading backwards.
    const Rgb ground  = sampleAt(lut, p, 0.0f, 0.5f);
    const Rgb below   = sampleAt(lut, p, -5000.0f, 0.5f);
    PL_CHECK_NEAR(below.g, ground.g, 1e-6);

    // A null table is refused rather than dereferenced.
    Real r = 9.0f, g = 9.0f, b = 9.0f;
    sampleTransmittance(nullptr, p, 0.0f, 0.5f, r, g, b);
    PL_CHECK_EQ(r == 0.0f && g == 0.0f && b == 0.0f, 1);
}

// ---------------------------------------------------------------------------
// The parameters it depends on, and the ones it does not
// ---------------------------------------------------------------------------

// THE CACHE KEY IS THIS EQUALITY, so what it does and does not notice IS the caching
// policy. A key that noticed the sun would rebuild a 196 KB table every time the
// artist dragged the sun slider, which is the one thing they do continuously.
PL_TEST(TheKeyNoticesTheAtmosphereAndIgnoresTheSun) {
    PhysicsParams    physics;
    AtmosphereParams atmosphere;

    const TransmittanceParams base = transmittanceParamsFrom(physics, atmosphere);

    // Moving the sun must NOT change the key.
    atmosphere.sunAzimuth   += 90.0f;
    atmosphere.sunElevation += 30.0f;
    atmosphere.sunIntensity *= 2.0f;
    atmosphere.groundAlbedo  = 0.8f;
    PL_CHECK_EQ(transmittanceParamsFrom(physics, atmosphere) == base, 1);

    // Turbidity must.
    atmosphere.turbidity += 1.0f;
    PL_CHECK_EQ(transmittanceParamsFrom(physics, atmosphere) != base, 1);

    // So must the two physics numbers the geometry is built from.
    AtmosphereParams clean;
    physics.planetRadius *= 0.5f;
    PL_CHECK_EQ(transmittanceParamsFrom(physics, clean) != base, 1);

    PhysicsParams physics2;
    physics2.scaleHeight *= 2.0f;
    PL_CHECK_EQ(transmittanceParamsFrom(physics2, clean) != base, 1);
}

// TURBIDITY HAS TO REACH THE TABLE, and in the right direction: more aerosol is less
// light through. A build that ignored it would still pass every test above.
PL_TEST(MoreTurbidityMeansLessTransmittance) {
    TransmittanceParams clear = earth();
    clear.turbidity = 1.0f;
    TransmittanceParams hazy = earth();
    hazy.turbidity = 8.0f;

    const std::vector<Real> clearLut = buildFor(clear);
    const std::vector<Real> hazyLut  = buildFor(hazy);

    const Rgb c = sampleAt(clearLut, clear, 0.0f, 0.2f);
    const Rgb h = sampleAt(hazyLut,  hazy,  0.0f, 0.2f);

    PL_CHECK(h.r < c.r);
    PL_CHECK(h.g < c.g);
    PL_CHECK(h.b < c.b);

    // MIE IS MUCH GREYER THAN RAYLEIGH, so haze costs red proportionally far more
    // than it costs blue -- which is why a hazy sky goes milky rather than bluer.
    PL_CHECK((h.r / c.r) < (h.b / c.b));
}

// ---------------------------------------------------------------------------
// Determinism
// ---------------------------------------------------------------------------

// THE TABLE IS BUILT ONCE ON THE HOST AND UPLOADED TO THE DEVICE, so this is what
// makes the CPU and CUDA paths read bit-identical values -- a stronger guarantee than
// the inner sun march it replaces, where each backend evaluated its own exp().
// tests/golden/ can only assert that downstream; this asserts it at the source.
PL_TEST(TheTableIsBitIdenticalAcrossBuilds) {
    const std::vector<Real> a = buildFor(earth());
    const std::vector<Real> b = buildFor(earth());

    int differing = 0;
    for (size_t i = 0; i < a.size(); ++i) {
        if (a[i] != b[i]) ++differing;
    }
    PL_CHECK_EQ(differing, 0);
}

// ---------------------------------------------------------------------------
// The three copies of the sampler, and the march the table replaces
// ---------------------------------------------------------------------------

// ===========================================================================
// THE SAMPLER EXISTS THREE TIMES AND EACH COPY IS PINNED TO ANOTHER.
//
//   src/engine/Atmosphere.cpp   host, double -- the reference these tests use
//   src/kernel/Shading.h        device-compilable, float -- the C++/CUDA reference
//   src/kernel/slang/SkyLib.slang  device, float -- what actually renders
//
// The last two are compared BITWISE by slang.skyParity. This test pins the first to
// the second, which closes the chain.
//
// ONE DEFINITION IS NOT AVAILABLE, which is why this is a test rather than a refactor:
// one copy has to compile for CUDA, one has to be reachable from src/engine/ which
// holds no kernel headers, and one is written in another language.
//
// THE TOLERANCE IS 1e-6 AND BOTH ANSWERS ARE FLOAT. The engine computes the
// interpolation in double and the kernel in float, so they are allowed to differ in
// the last bits and nowhere else.
// ===========================================================================
PL_TEST(LutAgreesWithTheHostSampler) {
    const TransmittanceParams p = earth();
    const std::vector<Real> lut = buildFor(p);

    PL_SWEEP(sweep, "sampler channels");

    for (int hi = 0; hi <= 20; ++hi) {
        const Real h = kTopAltitude * static_cast<Real>(hi) / 20.0f;
        for (int mi = 0; mi <= 40; ++mi) {
            const Real mu = -1.0f + static_cast<Real>(mi) * 0.05f;

            const Rgb host = sampleAt(lut, p, h, mu);
            const plugin::kernel::Vec3 kern =
                plugin::kernel::sampleTransmittanceLut(lut.data(), p.scaleHeight, h, mu);

            sweep.check(host.r, kern.x, 1e-6, mu);
            sweep.check(host.g, kern.y, 1e-6, mu);
            sweep.check(host.b, kern.z, 1e-6, mu);
        }
    }

    sweep.finish(21 * 41 * 3);
}

// ===========================================================================
// THE TABLE AGAINST THE INTEGRAL IT IS A PRECOMPUTATION OF.
//
// `sunOpticalDepth` in Shading.h is the eight-step quadrature that used to run inside
// the view march. It is no longer on the render path and is kept precisely so this
// comparison can exist -- two independent derivations of the same physical quantity,
// which is the only way to check a lookup table against something other than itself.
//
// THEY ARE NOT EXPECTED TO AGREE EXACTLY, AND WHICH ONE IS RIGHT IS THE POINT. The
// march is 8 steps with quadratic spacing in float; the table is 64 uniform steps in
// double, then bilinearly interpolated. Where they differ, the table is the better
// number -- so this test is not "the port changed nothing", it is "the port changed
// nothing by MORE than the accuracy it was buying".
//
// THE TOLERANCE IS SET BY MEASUREMENT, not by caution. MEASURED worst case: 0.0350,
// at the TOP of the atmosphere looking 0.1 below level -- a grazing path through the
// whole depth of the air, which is precisely where an 8-step quadrature is worst and
// where the table's 64 uniform steps earn themselves. 0.04 leaves 14% headroom: close
// enough that changing either step count trips it, loose enough not to be fragile.
//
// AND IT PREDICTS WHICH GOLDEN MOVED. The only scene in tests/golden/ that changed
// when the table replaced the march is `sunset`, at sun elevation 2 degrees -- the one
// whose light arrives along exactly this grazing path. `midday` and `horizon` did not
// move at all. Two independent measurements agreeing on where the difference lives is
// what turns "the picture changed" into "the picture got more accurate, here.
//
// THE HORIZON BAND IS EXCLUDED DELIBERATELY. Within about a degree of the geometric
// horizon the two disagree by construction rather than by accuracy: the table stores
// exactly zero for a blocked texel and interpolates that zero outwards, while the
// march returns a finite optical depth right up to the tangent. That is a real and
// intended difference -- it is the ground shadow being resolved at texel resolution --
// and folding it in here would measure the table's resolution rather than its accuracy.
// ===========================================================================
PL_TEST(LutAgreesWithTheMarchItReplaces) {
    const TransmittanceParams p = earth();
    const std::vector<Real> lut = buildFor(p);

    const float planetRadius = p.planetRadius;
    const float scaleHeight  = p.scaleHeight;
    const float atmosphereHeight = scaleHeight * 8.0f;

    // The extinction coefficients the march's depths are combined with, matching
    // Shading.h's own.
    const float betaR[3] = { 5.802e-6f, 13.558e-6f, 33.1e-6f };
    const float betaMExt = 3.996e-6f * (p.turbidity / 2.2f) * 1.11f;

    int    compared = 0;
    double worst = 0.0;
    double worstAlt = 0.0, worstMu = 0.0;

    for (int hi = 0; hi <= 16; ++hi) {
        const float h = kTopAltitude * static_cast<float>(hi) / 16.0f;
        const float radius = planetRadius + h;

        // The geometric horizon at this altitude; everything below it is blocked.
        const double horizon = -std::sqrt(1.0 - double(planetRadius) * double(planetRadius)
                                                / (double(radius) * double(radius)));

        for (int mi = 0; mi <= 60; ++mi) {
            const float mu = -1.0f + static_cast<float>(mi) * (2.0f / 60.0f);

            // Skip the band where the difference is resolution, not accuracy.
            if (double(mu) < horizon + 0.02) continue;

            float sunR = 0.0f, sunM = 0.0f;
            plugin::kernel::sunOpticalDepth(h, mu * radius, planetRadius,
                                            atmosphereHeight, scaleHeight, sunR, sunM);

            const plugin::kernel::Vec3 table =
                plugin::kernel::sampleTransmittanceLut(lut.data(), scaleHeight, h, mu);

            const float march[3] = {
                std::exp(-(betaR[0] * sunR + betaMExt * sunM)),
                std::exp(-(betaR[1] * sunR + betaMExt * sunM)),
                std::exp(-(betaR[2] * sunR + betaMExt * sunM))
            };
            const float got[3] = { table.x, table.y, table.z };

            for (int c = 0; c < 3; ++c) {
                const double d = std::fabs(double(got[c]) - double(march[c]));
                if (d > worst) { worst = d; worstAlt = h; worstMu = mu; }
            }
            ++compared;
        }
    }

    std::printf("      table vs 8-step march: worst %.6f at altitude %.0f m, mu %.3f "
                "(%d points)\n",
                worst, worstAlt, worstMu, compared);

    PL_CHECK(compared > 500);
    PL_CHECK(worst < 0.04);
}

// ---------------------------------------------------------------------------
// The ground's skylight (build 19)
// ---------------------------------------------------------------------------

namespace {

cloud::FieldParams skyWith(float elevation, float turbidity) {
    cloud::FieldParams f;
    f.atmosphere.sunElevation = elevation;
    f.atmosphere.sunAzimuth   = 135.0f;
    f.atmosphere.turbidity    = turbidity;
    return f;
}

std::vector<Real> tableFor(const cloud::FieldParams& f) {
    return buildFor(transmittanceParamsFrom(f.physics, f.atmosphere));
}

} // namespace

// THE RENDERER'S GRID IS CONVERGED: 32 x 64 against 128 x 256, sixteen times as many
// directions, within 1% in every channel. MEASURED when written: under 0.1% up to a 45
// degree sun, and 0.49% at 85 degrees, where the aureole sits in the few cells round the
// zenith. Equal steps of mu^2 were measured at 1.2 to 1.4% here; see groundSkyLightFor.
PL_TEST(GroundSkyLightConverges) {
    const float elevations[] = { 2.0f, 12.0f, 45.0f, 85.0f };
    const float turbidities[] = { 2.2f, 6.0f };
    double worst = 0.0;
    for (float el : elevations) {
        for (float tb : turbidities) {
            const cloud::FieldParams f = skyWith(el, tb);
            const std::vector<Real> lut = tableFor(f);
            float coarse[3], fine[3];
            const auto t0 = std::chrono::steady_clock::now();
            plugin::kernel::groundSkyLightFor(f, lut.data(), 32, 64, coarse);
            const double ms = std::chrono::duration<double, std::milli>(
                                  std::chrono::steady_clock::now() - t0).count();
            plugin::kernel::groundSkyLightFor(f, lut.data(), 128, 256, fine);
            double here = 0.0;
            for (int c = 0; c < 3; ++c) {
                PL_CHECK(fine[c] > 0.0f);
                here = std::fmax(here, std::fabs(double(coarse[c]) / fine[c] - 1.0));
            }
            std::printf("      sun %4.0f deg, turbidity %.1f: %.4f%% (32 x 64 took %.1f ms)\n",
                        el, tb, here * 100.0, ms);
            worst = std::fmax(worst, here);
        }
    }
    std::printf("      32 x 64 against 128 x 256: worst %.4f%%\n", worst * 100.0);
    PL_CHECK(worst < 0.01);
}

// WHAT HAS TO BE TRUE OF SKYLIGHT, whatever computes it:
//   * it is the ground's albedo times something, so a black ground returns none;
//   * a sun far below the horizon lights no sky in a single-scattering model;
//   * a clear sky's light is blue, so the ground's share of it is too;
//   * against the sun's own light on the same ground it is a minority, and not a
//     vanishing one: clear-sky diffuse is of order a tenth of the direct beam at 45
//     degrees. The bounds are wide on purpose; they catch a lost pi, not a model choice.
PL_TEST(GroundSkyLightIsSkylight) {
    float out[3];

    cloud::FieldParams black = skyWith(45.0f, 2.2f);
    black.atmosphere.groundAlbedo = 0.0f;
    const std::vector<Real> lut45 = tableFor(black);
    plugin::kernel::groundSkyLightFor(black, lut45.data(), 32, 64, out);
    PL_CHECK(out[0] == 0.0f && out[1] == 0.0f && out[2] == 0.0f);

    const cloud::FieldParams night = skyWith(-30.0f, 2.2f);
    const std::vector<Real> lutNight = tableFor(night);
    plugin::kernel::groundSkyLightFor(night, lutNight.data(), 32, 64, out);
    std::printf("      sun at -30 deg: %.3g %.3g %.3g\n", out[0], out[1], out[2]);
    PL_CHECK(out[0] < 1e-6f && out[1] < 1e-6f && out[2] < 1e-6f);

    const cloud::FieldParams day = skyWith(45.0f, 2.2f);
    plugin::kernel::groundSkyLightFor(day, lut45.data(), 32, 64, out);
    PL_CHECK(out[2] > out[0]);

    // The direct beam on the same ground, as skyRadiance's ground term has it, with the
    // albedo / pi that groundSkyLight also carries.
    const float mu = std::sin(45.0f * 0.01745329252f);
    const plugin::kernel::Vec3 sunT =
        plugin::kernel::sampleTransmittanceLut(lut45.data(), day.physics.scaleHeight, 0.0f, mu);
    const float direct = day.atmosphere.groundAlbedo * 0.3183098862f
                       * 20.0f * day.atmosphere.sunIntensity * mu;
    const double ratio[3] = { out[0] / (direct * sunT.x), out[1] / (direct * sunT.y),
                              out[2] / (direct * sunT.z) };
    std::printf("      sky / sun on the ground at 45 deg: %.3f %.3f %.3f\n",
                ratio[0], ratio[1], ratio[2]);
    for (int c = 0; c < 3; ++c) PL_CHECK(ratio[c] > 0.02 && ratio[c] < 0.5);
}
