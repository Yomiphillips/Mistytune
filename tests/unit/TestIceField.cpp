// The host's half of the ice generator: the shear integral and the majorant.
//
// ===========================================================================
// WHY THIS FILE EXISTS, AND IT IS NOT "FOR COVERAGE".
//
// Both things it tests fail SILENTLY AND CONVINCINGLY.
//
// The shear integral fails by rendering a sky. Not a black frame, not a crash -- a
// perfectly plausible overcast sheet that looks like a bug in the transport, or the
// noise, or the camera, and sends the reader anywhere but here. That is exactly what
// happened when this renderer first ran: the integral was in the wrong frame of
// reference, the streaks were drawn 88 km from their own cells, and the picture was
// uniform horizontal banding. It was found by LOOKING AT IT, which is not a method.
//
// The majorant fails by rendering a thinner cloud. A bound below the true maximum
// makes the null-collision estimator stop being an estimator -- the collision
// probability exceeds one and the comparison accepts unconditionally -- and the
// result is a picture that is quietly wrong in a way no test that renders and looks
// can distinguish from a parameter change.
//
// NEITHER NEEDS A GPU AND NEITHER NEEDS A RENDER, which is the whole argument for
// src/engine/ existing. These run in microseconds on every build.
//
// WHAT IS NOT HERE: whether the majorant actually bounds the kernel's density. That
// is a claim about iceDensity(), which lives in Slang, so it is checked where the
// kernel can be run -- see slang.generator, which samples the field's peak and
// asserts this file's bound is above it. The two tiers are complementary: this one
// says the arithmetic is what it claims, that one says the claim is true.
// ===========================================================================

#include "TestFramework.h"

#include "IceField.h"

#include <cmath>

using namespace plugin::cloud;

namespace {

// A profile with no shear at all: same speed, same bearing, at every level.
IceParams noShear() {
    IceParams ice;
    for (int k = 0; k < kShearKnots; ++k) {
        ice.shear.speed[k]   = Real(30);
        ice.shear.bearing[k] = Real(270);
    }
    return ice;
}

Real hypot2(Real x, Real z) { return std::sqrt(x * x + z * z); }

} // namespace

// ---------------------------------------------------------------------------
// The frame of reference
// ---------------------------------------------------------------------------

// THE OBVIOUS CHECK, AND THE ONE THAT WOULD HAVE CAUGHT THE BUG.
//
// A wind that is the same at every level has no shear in it. The generating cell and
// every crystal below it are carried at identical speed, so nothing is drawn out:
// the streak hangs straight down as a vertical curtain and the drift is zero at
// every knot.
//
// Integrating the ABSOLUTE wind instead gives 30 m/s times the fall time at the
// bottom knot -- which at the default 2.6 km and 1 m/s is 78 kilometres, and renders
// as a featureless sheet.
PL_TEST(ZeroShearGivesZeroDrift) {
    const IceParams ice = noShear();

    DriftTable table;
    buildDriftTable(ice, table);

    for (int k = 0; k < kDriftKnots; ++k) {
        PL_CHECK_NEAR(table.x(k), 0.0, 1e-3);
        PL_CHECK_NEAR(table.z(k), 0.0, 1e-3);
    }
}

// The first knot is the generating level itself, where nothing has fallen yet.
PL_TEST(DriftStartsAtTheCell) {
    IceParams ice;
    DriftTable table;
    buildDriftTable(ice, table);

    PL_CHECK_EQ(table.x(0) == Real(0), 1);
    PL_CHECK_EQ(table.z(0) == Real(0), 1);
}

// With real shear the streak trails, and it trails further the deeper it goes.
//
// MONOTONIC BECAUSE THE DEFAULT PROFILE ONLY EVER SLOWS DOWN. The relative wind
// therefore points the same way at every level, so the displacement accumulates
// rather than doubling back. A profile whose wind reversed would not have this
// property and this is not asserted of one.
PL_TEST(DriftGrowsWithDepth) {
    const IceParams ice;      // the defaults: 34 m/s at the top, 8 at the bottom

    DriftTable table;
    buildDriftTable(ice, table);

    Real previous = Real(0);
    for (int k = 1; k < kDriftKnots; ++k) {
        const Real d = hypot2(table.x(k), table.z(k));
        PL_CHECK(d > previous);
        previous = d;
    }

    PL_CHECK(previous > Real(1000));   // kilometres, not metres. Cirrus trails a long way
}

// ---------------------------------------------------------------------------
// Fall speed IS the streak length
// ---------------------------------------------------------------------------

// A CRYSTAL THAT FALLS HALF AS FAST SPENDS TWICE AS LONG IN THE WIND, so it trails
// twice as far. That is the whole relationship between habit and shape, and it is
// why habit is not cosmetic.
//
// EXACT TO A SCALE FACTOR, not approximately: the integral is linear in 1/v and
// nothing else in it depends on the speed, so doubling the divisor halves every knot
// of the table. A drift that changed shape as well as size would mean the fall speed
// had leaked into the profile lookup.
PL_TEST(HalvingFallSpeedDoublesDrift) {
    IceParams fast;
    fast.habit = IceHabit::Column;
    fast.fallSpeedScale = Real(1);

    IceParams slow = fast;
    slow.fallSpeedScale = Real(0.5);

    DriftTable a, b;
    buildDriftTable(fast, a);
    buildDriftTable(slow, b);

    for (int k = 1; k < kDriftKnots; ++k) {
        PL_CHECK_NEAR(b.x(k), a.x(k) * 2.0, std::fabs(a.x(k)) * 1e-4 + 1e-3);
        PL_CHECK_NEAR(b.z(k), a.z(k) * 2.0, std::fabs(a.z(k)) * 1e-4 + 1e-3);
    }
}

// A zero or negative multiplier must not divide by zero.
//
// THE FLOOR IS NOT COSMETIC. At a fall speed of zero the parcel never falls, has
// been in the wind forever, and every knot of the table is infinite -- which
// propagates into the generator as a NaN and renders as an empty sky, not as an
// error anybody can trace back to a slider at its minimum.
PL_TEST(FallSpeedIsFloored) {
    IceParams ice;
    ice.fallSpeedScale = Real(0);
    PL_CHECK(iceFallSpeed(ice) > Real(0));

    ice.fallSpeedScale = Real(-4);
    PL_CHECK(iceFallSpeed(ice) > Real(0));

    DriftTable table;
    buildDriftTable(ice, table);
    for (int k = 0; k < kDriftKnots; ++k) {
        PL_CHECK(std::isfinite(table.x(k)));
        PL_CHECK(std::isfinite(table.z(k)));
    }
}

// Habit changes the speed, and the five are distinct.
//
// A SWITCH THAT FELL THROUGH TO ONE VALUE would make habit a no-op, which is
// invisible in a render unless you already know what each habit should look like.
PL_TEST(HabitsHaveDistinctFallSpeeds) {
    const IceHabit all[] = { IceHabit::Plate, IceHabit::Column, IceHabit::Bullet,
                             IceHabit::Dendrite, IceHabit::Aggregate };

    for (int i = 0; i < 5; ++i) {
        PL_CHECK(habitFallSpeed(all[i]) > Real(0));
        for (int j = i + 1; j < 5; ++j) {
            PL_CHECK(habitFallSpeed(all[i]) != habitFallSpeed(all[j]));
        }
    }

    // Dendrites are the slowest thing in the sky that is not a droplet; bullet
    // rosettes are the fastest of these. Pinned because the ordering is what makes
    // the parameter mean something to a user who knows what the words refer to.
    PL_CHECK(habitFallSpeed(IceHabit::Dendrite) < habitFallSpeed(IceHabit::Plate));
    PL_CHECK(habitFallSpeed(IceHabit::Plate)    < habitFallSpeed(IceHabit::Column));
    PL_CHECK(habitFallSpeed(IceHabit::Column)   < habitFallSpeed(IceHabit::Bullet));
}

// ---------------------------------------------------------------------------
// The bearing convention
// ---------------------------------------------------------------------------

// A 270 BEARING IS A WESTERLY AND A WESTERLY BLOWS EAST.
//
// Bearings are meteorological: the direction the wind comes FROM, clockwise from
// north, and north is +Z. Reading it as the direction it blows TOWARDS reverses
// every streak in the sky, which looks like a sign error somewhere in the integral
// and is not one.
PL_TEST(BearingIsWhereTheWindComesFrom) {
    IceParams ice = noShear();

    Real x = Real(0), z = Real(0);

    // From the west, blowing east: +X.
    for (int k = 0; k < kShearKnots; ++k) ice.shear.bearing[k] = Real(270);
    shearWindAt(ice, Real(0), x, z);
    PL_CHECK(x > Real(20));
    PL_CHECK_NEAR(z, 0.0, 1e-3);

    // From the north, blowing south: -Z.
    for (int k = 0; k < kShearKnots; ++k) ice.shear.bearing[k] = Real(0);
    shearWindAt(ice, Real(0), x, z);
    PL_CHECK(z < Real(-20));
    PL_CHECK_NEAR(x, 0.0, 1e-3);
}

// Interpolating the VECTOR rather than the bearing, which matters at the wrap.
//
// Two knots at 350 and 10 degrees are twenty degrees apart. Averaging the NUMBERS
// gives 180 -- a wind blowing backwards, in the middle of an otherwise unremarkable
// profile, from one interpolation step. Taking each knot to a vector first cannot
// produce that.
PL_TEST(BearingInterpolationTakesTheShortWayRound) {
    IceParams ice = noShear();
    for (int k = 0; k < kShearKnots; ++k) ice.shear.speed[k] = Real(20);
    ice.shear.bearing[0] = Real(350);
    ice.shear.bearing[1] = Real(10);

    Real x0 = Real(0), z0 = Real(0), xm = Real(0), zm = Real(0);
    shearWindAt(ice, Real(0), x0, z0);

    // Halfway between knot 0 and knot 1.
    const Real depthMid = ice.streakLength / Real(2 * (kShearKnots - 1));
    shearWindAt(ice, depthMid, xm, zm);

    // The interpolated wind must stay close to both ends, never swing to the
    // opposite quadrant. A bearing-space average would put z the other way up.
    PL_CHECK(zm * z0 > Real(0));
    PL_CHECK(hypot2(xm, zm) > Real(15));
}

// ---------------------------------------------------------------------------
// The majorant
// ---------------------------------------------------------------------------

// NEVER ZERO, WHATEVER THE PARAMETERS SAY.
//
// A majorant of zero makes every sampled free-flight distance infinite, so the
// tracker leaves the slab on its first step and the medium is simply not there. That
// reads as "the cloud is missing", which is the most expensive thing a renderer can
// say, because there are twenty other reasons a cloud could be missing.
PL_TEST(MajorantIsAlwaysPositive) {
    IceParams ice;
    PL_CHECK(iceMajorant(ice) > Real(0));

    ice.opticalDepth = Real(0);
    ice.cellStrength = Real(0);
    ice.detailAmount = Real(0);
    PL_CHECK(iceMajorant(ice) > Real(0));

    // Negative parameters are not reachable through the UI and are reachable through
    // an expression, which AE lets drive any slider past its range.
    ice.opticalDepth = Real(-1);
    ice.cellStrength = Real(-1);
    ice.detailAmount = Real(-1);
    ice.streakLength = Real(-1);
    PL_CHECK(iceMajorant(ice) > Real(0));
    PL_CHECK(std::isfinite(iceMajorant(ice)));
}

// The bound tracks the factors it is built from, which is what makes it a bound on
// THIS field rather than a constant that happens to be large enough today.
PL_TEST(MajorantTracksItsFactors) {
    const IceParams base;
    const Real b = iceMajorant(base);

    IceParams thicker = base;
    thicker.opticalDepth = base.opticalDepth * Real(2);
    PL_CHECK_NEAR(iceMajorant(thicker), b * 2.0, b * 1e-4);

    IceParams stronger = base;
    stronger.cellStrength = base.cellStrength * Real(2);
    PL_CHECK_NEAR(iceMajorant(stronger), b * 2.0, b * 1e-4);

    // More detail can only ever raise the peak: the detail term is 1 + amount*fbm*1.8
    // and fbm is signed, so a larger amount widens the range in both directions.
    IceParams detailed = base;
    detailed.detailAmount = base.detailAmount * Real(2);
    PL_CHECK(iceMajorant(detailed) > b);

    // A longer streak spreads the same optical depth over more metres, so the density
    // per metre falls. That is what makes `opticalDepth` mean optical depth.
    IceParams longer = base;
    longer.streakLength = base.streakLength * Real(2);
    PL_CHECK_NEAR(iceMajorant(longer), b * 0.5, b * 1e-4);
}

// ---------------------------------------------------------------------------
// The bulk drift
// ---------------------------------------------------------------------------

// THE CELLS TRAVEL AND THE STREAKS HANG OFF THEM. This is the other half of the
// frame-of-reference decision: the relative integral removed the generating level's
// wind, and this is where it goes.
//
// AT t = 0 IT MUST BE EXACTLY ZERO, because the field's fingerprint and every golden
// image are taken there. A bulk offset that was nonzero at zero time would move the
// whole sky for every scene in tests/golden/ and look like a camera change.
PL_TEST(CellDriftIsZeroAtTimeZero) {
    const IceParams ice;
    Real x = Real(1), z = Real(1);
    cellDriftAt(ice, Real(0), x, z);
    PL_CHECK_EQ(x == Real(0), 1);
    PL_CHECK_EQ(z == Real(0), 1);
}

// It is the wind at the TOP of the profile, because that is the height the cells are
// at -- and it is linear in time, because the wind is constant over one frame.
PL_TEST(CellDriftIsTheGeneratingLevelWind) {
    const IceParams ice;

    Real wx = Real(0), wz = Real(0);
    shearWindAt(ice, Real(0), wx, wz);

    Real x = Real(0), z = Real(0);
    cellDriftAt(ice, Real(10), x, z);

    PL_CHECK_NEAR(x, wx * 10.0, std::fabs(wx) * 1e-4 + 1e-3);
    PL_CHECK_NEAR(z, wz * 10.0, std::fabs(wz) * 1e-4 + 1e-3);
}
