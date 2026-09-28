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

/// The bound tracks the factors it is built from, which is what makes it a bound on
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

    // ---------------------------------------------------------------------
    // A LONGER STREAK IS NO LONGER EXACTLY HALF, AND THE REASON IS THE POINT.
    //
    // Spreading the same optical depth over twice the metres halves the density per
    // metre -- that is what makes `opticalDepth` mean optical depth, and it used to be
    // the whole of this relation.
    //
    // depthFactorBound() now moves with the length as well. The head opens over
    // kHeadFraction of the streak, so doubling the streak doubles the depth at which
    // it finishes opening -- and by then sublimation has eaten more of the crystal. So
    // the depth factor FALLS, and the majorant falls by more than half.
    //
    // Asserted through depthFactorBound() rather than against a blessed number,
    // because the relation is the claim and the number is a consequence of it.
    // ---------------------------------------------------------------------
    IceParams longer = base;
    longer.streakLength = base.streakLength * Real(2);

    const Real depthRatio = depthFactorBound(longer) / depthFactorBound(base);
    PL_CHECK(depthRatio < Real(1));
    PL_CHECK_NEAR(iceMajorant(longer), b * 0.5 * depthRatio, b * 1e-4);
}

// ---------------------------------------------------------------------------
// The cell-overlap bound: four blobs, not nine
// ---------------------------------------------------------------------------

// NINE IS SOUND AND 2.76x TOO BIG, and the cost is paid in tracking steps -- every one
// of which is a four-octave fbm. The header derives four; this checks the arithmetic
// landed between the two numbers that bracket it.
//
// THE LOWER BRACKET IS NOT COSMETIC. A single blob at its own centre is exactly one, so
// a bound below one would be below the field, and that is the failure that renders a
// thinner cloud rather than an error.
PL_TEST(TheCellOverlapBoundIsFourBlobsNotNine) {
    const Real bound = cellOverlapBound();

    PL_CHECK(bound >= Real(1));
    PL_CHECK(bound < Real(9));

    // Four blobs is the ceiling of the count argument, so the bound cannot exceed it
    // however the distances fall out.
    PL_CHECK(bound <= Real(4));

    // And it is not so tight that it has stopped being the four-slot bound: two blobs
    // can reach 1.83 between them, so anything at or below that would mean the second
    // axis had been lost somewhere.
    PL_CHECK(bound > Real(2));
}

// THE WORST CASE, COMPUTED HERE INSTEAD OF THERE.
//
// A point on a slot corner has four cells able to sit at (0.1, 0.1) from it in grid
// units -- the closest the jitter inset allows from each of the four slots that share
// the corner. That configuration is what the scan is looking for, so building it
// independently and checking the bound covers it is the one test that would catch a
// scan that searched the wrong square.
//
// THE SMOOTHSTEP IS REPLICATED RATHER THAN CALLED, deliberately: a helper shared with
// the implementation would agree with it by construction and prove nothing.
PL_TEST(TheCellOverlapBoundCoversTheWorstCornerItself) {
    const Real inset = (Real(1) - kCellJitter) / Real(2);

    // Distance in CELL-SIZES from the corner to each of the four nearest cells.
    const Real d = std::sqrt(inset * inset + inset * inset) * kCellSpacing;

    // smoothstep(kBlobFar, kBlobNear, d), written out.
    const Real t     = (d - kBlobFar) / (kBlobNear - kBlobFar);
    const Real clamp = t < Real(0) ? Real(0) : (t > Real(1) ? Real(1) : t);
    const Real blob  = clamp * clamp * (Real(3) - Real(2) * clamp);

    const Real corner = Real(4) * blob;

    PL_CHECK(corner > Real(3));                 // it really is the dense configuration
    PL_CHECK(cellOverlapBound() >= corner);     // ...and the bound covers it

    // The scan should land ON it rather than merely above it -- the Lipschitz slack is
    // 0.0054 at the shipping resolution, so anything looser than a percent would mean
    // the search had missed the maximum it is supposed to find.
    PL_CHECK_NEAR(cellOverlapBound(), corner, corner * 0.01);
}

// WHAT SEPARATES A CERTIFIED SCAN FROM A SAMPLE: refining it may only LOWER the answer.
//
// The scan plus its Lipschitz slack is an upper bound on the true maximum, so a finer
// scan -- which is a better estimate of that same maximum -- cannot exceed the coarser
// one's certified value. If it did, the slack would be wrong, and a slack that is wrong
// is a majorant below the field.
PL_TEST(RefiningTheCellScanDoesNotRaiseTheBound) {
    const Real shipping = cellOverlapBound();

    PL_CHECK(cellOverlapBound(1024) <= shipping);
    PL_CHECK(cellOverlapBound(4096) <= shipping);

    // And a far coarser scan is still a bound, because the slack grows as the scan
    // thins. THIS IS THE DIRECTION THAT MATTERS: a coarse scan must over-report, never
    // under-report.
    PL_CHECK(cellOverlapBound(8) >= cellOverlapBound(4096));
}

// A DEGENERATE RESOLUTION FALLS BACK TO SOUND RATHER THAN TO CLEVER. Zero steps is not
// a scan, so there is nothing to certify and the trivial nine-slot bound is the answer.
PL_TEST(AnEmptyCellScanFallsBackToTheTrivialBound) {
    PL_CHECK_EQ(cellOverlapBound(0) == Real(9), 1);
    PL_CHECK_EQ(cellOverlapBound(-1) == Real(9), 1);
}

// ---------------------------------------------------------------------------
// The depth factors
// ---------------------------------------------------------------------------

// THREE FACTORS EACH BOUNDED BY ONE, WHOSE PRODUCT IS NOWHERE NEAR ONE.
//
// `head` rises from zero at the generating level and `sublimation` falls from one
// there, so they are never both large. Bounding each separately is what the old
// majorant did, and the slack is what this measures.
PL_TEST(TheDepthFactorsCannotAllBeOne) {
    const IceParams ice;
    const Real f = depthFactorBound(ice);

    PL_CHECK(f > Real(0));
    PL_CHECK(f < Real(1));

    // On the defaults the head finishes opening at 8% of 2600 m, by which point
    // sublimation at 0.55 per km has taken about 11%. So the peak is near 0.89 -- close
    // enough to one that it is worth stating the bound is real and not a rounding.
    PL_CHECK(f > Real(0.8));
    PL_CHECK(f < Real(0.95));
}

// The same certified-refinement property as the cell scan, and for the same reason: a
// partition of monotone factors over-reports, so refining it may only lower the answer.
PL_TEST(RefiningTheDepthScanDoesNotRaiseIt) {
    const IceParams ice;

    PL_CHECK(depthFactorBound(ice, 4096) <= depthFactorBound(ice));
    PL_CHECK(depthFactorBound(ice, 4) >= depthFactorBound(ice, 4096));
}

// A STRONGER SUBLIMATION RATE LOWERS THE BOUND, because the head has to finish opening
// before the product can be large, and by then more of the crystal is gone.
PL_TEST(SublimationLowersTheDepthFactor) {
    IceParams dry;
    dry.sublimationRate = Real(3);

    IceParams wet;
    wet.sublimationRate = Real(0.1);

    PL_CHECK(depthFactorBound(dry) < depthFactorBound(wet));
    PL_CHECK(depthFactorBound(wet) < Real(1));
}

// ===========================================================================
// THE HOLE THIS CLOSED, AND IT WAS OPEN.
//
// The old bound omitted sublimation entirely, on the argument that exp of a negative is
// at most one. That argument holds only while the RATE is positive -- and AE lets an
// expression drive any slider past its range, which the tests above already rely on
// being true for the other parameters.
//
// At a negative rate exp(-rate * depth / 1000) GROWS with depth: 4.2x at the default
// streak length and a rate of -1. So the majorant was not merely loose there, it was
// BELOW the field it was supposed to bound, and the render would have been quietly thin
// with nothing saying so.
//
// The fix is to evaluate the factor rather than assert it, and this is what pins it.
// ===========================================================================
PL_TEST(ANegativeSublimationRateStillBounds) {
    IceParams ice;
    ice.sublimationRate = Real(-1);

    const Real f = depthFactorBound(ice);

    // It must now exceed one, which the old "each factor is at most one" never allowed.
    PL_CHECK(f > Real(1));

    // AND IT MUST COVER THE DEEPEST POINT THE PRODUCT IS STILL ALIVE AT, computed here
    // independently. The tail closes at the bottom of the streak, so take the depth
    // where it is still fully open -- kTailFraction of the way down -- where the head
    // has long since opened and sublimation has been growing all the way.
    const Real depth = kTailFraction * ice.streakLength;
    const Real truth = std::exp(-ice.sublimationRate * depth / Real(1000));

    PL_CHECK(f >= truth);

    // ...and the majorant built on it stays finite and positive, because a bound that
    // is right and infinite is no more usable than one that is wrong.
    PL_CHECK(iceMajorant(ice) > Real(0));
    PL_CHECK(std::isfinite(iceMajorant(ice)));
}

// ---------------------------------------------------------------------------
// What the two bounds bought
// ---------------------------------------------------------------------------

// THE WHOLE POINT OF THE CHANGE, ASSERTED RATHER THAN RECORDED IN A COMMENT.
//
// The old majorant was nine blobs times the detail bound times the optical depth over
// the streak length, with the three depth factors bounded by one each. Both survivors
// of that formula are still here, so the old number can be rebuilt exactly and the
// ratio checked.
//
// EXPECTED COST IN STEPS IS majorant * PATH LENGTH, so this ratio is the ratio of
// density evaluations, and a density evaluation is a four-octave fbm. It is not a
// cosmetic tightening.
PL_TEST(TheTightenedMajorantIsWellBelowTheOldOne) {
    const IceParams ice;

    const Real detailMax = Real(1) + Real(1.8) * ice.detailAmount * kFbmBound;
    const Real oldBound  = Real(9) * ice.cellStrength * detailMax
                         * ice.opticalDepth / ice.streakLength;

    const Real now = iceMajorant(ice);

    PL_CHECK(now < oldBound);

    // 2.76x from the cell count and about 1.12x from the depth factors. Bracketed
    // rather than pinned to a digit, because the exact value follows from constants
    // this test does not own -- but a cut far outside this range means one of the two
    // bounds stopped contributing.
    const Real gain = oldBound / now;
    PL_CHECK(gain > Real(2.5));
    PL_CHECK(gain < Real(3.5));
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
