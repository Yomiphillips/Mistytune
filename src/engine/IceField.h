#pragma once

// The host's half of the ice generator: the three things the kernel cannot work
// out for itself.
//
// ---------------------------------------------------------------------------
// WHY ANY OF THIS IS HOST-SIDE AT ALL, given that the generator is a kernel.
//
// Each of these is a function of the PARAMETERS ONLY. None of them varies with the
// pixel, the sample, the ray or the position, so computing them on the GPU would be
// the same answer recomputed a few billion times a frame. They are derived once per
// parameter change and travel to the kernel as data -- the drift table as a buffer,
// the majorant and the fall speed as scalars inside GeneratorInput.
//
// THAT IS ALSO WHY THEY LIVE IN src/engine/ RATHER THAN src/kernel/. They are plain
// arithmetic over CloudParams with no GPU type anywhere in them, so tests/unit/ can
// check the shear integral and the majorant's soundness in milliseconds without a
// card -- and the majorant's soundness is not a property a render can show you.
// ---------------------------------------------------------------------------

#include "CloudParams.h"

namespace plugin::cloud {

// ---------------------------------------------------------------------------
// The drift table
// ---------------------------------------------------------------------------

// THIRTY-THREE, AND THE NUMBER IS NOT FREE. GeneratorLib.slang's driftAt() maps a
// fall depth onto `depth / streakLength * 32` and interpolates between `disp[i]` and
// `disp[i+1]`, so the table must have exactly 32 intervals and 33 entries. A
// different length here does not fail to compile -- it reads off the end of the
// buffer on the last interval, which on a GPU is whatever happened to be next.
constexpr int kDriftKnots = 33;

// Horizontal displacement, in metres, of a parcel that has fallen to each of the 33
// sample depths. Entry 0 is the generating level and is always (0,0); entry 32 is
// the bottom of the streak.
//
// INTERLEAVED, AND ALIGNED TO EIGHT, because the kernel reads this exact memory as
// an array of float2 rather than copying it.
//
// The alternative -- two parallel arrays, which reads better here -- would have to
// be interleaved somewhere, and the only place left is inside the kernel, per
// thread. Thirty-three pairs is 264 bytes of per-thread local memory on a GPU, which
// is not a tidiness question but a spill.
//
// alignas(8) IS THE LOAD-BEARING HALF. CUDA's float2 requires eight-byte alignment
// and an array of floats inside a struct is only guaranteed four. A misaligned
// vector load does not fall back to a slow path; it faults, or worse, it does not.
// The same declaration satisfies the C++ backend's Vector<float,2>.
//
// No vector type appears here, which is what keeps this header free of every
// backend's idea of what a float2 is -- measured, and they do not agree.
struct DriftTable {
    alignas(8) Real xz[2 * kDriftKnots] = {};

    Real x(int knot) const { return xz[2 * knot]; }
    Real z(int knot) const { return xz[2 * knot + 1]; }
};

// The fall speed a habit gives a crystal, in m/s, before the artist multiplier.
//
// REAL NUMBERS FROM THE LITERATURE, not a tuning curve. Terminal velocities for ice
// crystals in cirrus: plates fall slowly because they present their full area to the
// flow and tend to orient horizontally; columns and bullet rosettes fall faster;
// dendrites are the slowest thing in the sky that is not a cloud droplet. Aggregates
// are the fastest because they are the biggest.
//
// FALL SPEED AGAINST THE SHEAR PROFILE IS THE STREAK SHAPE, which is why this is not
// cosmetic and why it is a table of measurements rather than five sliders. A slow
// crystal spends longer in the wind and trails further for the same shear.
Real habitFallSpeed(IceHabit habit);

// Habit times the artist multiplier, floored so that a zero cannot divide.
Real iceFallSpeed(const IceParams& ice);

// The wind at a fall depth, in m/s, as a horizontal vector.
//
// BEARING IS METEOROLOGICAL -- the direction the wind comes FROM, clockwise from
// north, which the project's +Z axis is. The defaults say 270, and a 270 wind is a
// westerly: it comes from the west and blows towards the east, which is +X. Reading
// it as "the direction it blows towards" reverses every streak in the sky and looks
// like a sign error in the shear integral rather than a convention mismatch.
void shearWindAt(const IceParams& ice, Real depthMetres, Real& outX, Real& outZ);

// The shear profile integrated into the displacement of a falling parcel.
//
// ---------------------------------------------------------------------------
// THIS INTEGRAL IS THE HOOK. It is the whole reason cirrus uncinus looks different
// from cirrus fibratus, and it is the hero control PLAN.md protects.
//
// A parcel released at the generating level falls at a constant speed, so the time
// it has spent falling to depth d is d/v. While it falls the wind carries it
// sideways, and the wind is DIFFERENT AT EVERY HEIGHT -- that is what shear is. So
// its displacement RELATIVE TO ITS OWN CELL is
//
//     disp(d) = integral from 0 to d of  (wind(s) - wind(0)) / v  ds
//
// and the `- wind(0)` is load-bearing. See the .cpp, where it is argued at length
// and where the render it produces when it is missing is described.
//
// A TURNING wind -- the bearing changing with height rather than only the speed --
// is what curls the bottom of a streak away from the top, which is the hook. A
// profile whose bearing is constant gives fibratus; one that turns gives uncinus.
// Nothing else in the generator produces that shape, and no amount of noise will.
//
// MIDPOINT RULE, and it is the right one rather than the lazy one: the profile is
// piecewise linear between knots, and the midpoint rule integrates a linear function
// exactly. A trapezoid would too; a left-hand rule would not, and would bias every
// streak upwind by half an interval.
// ---------------------------------------------------------------------------
void buildDriftTable(const IceParams& ice, DriftTable& out);

// Where the generating level itself has moved to by `timeSeconds`.
//
// THE CELLS TRAVEL, AND THE STREAKS HANG OFF THEM. Advecting the whole field is what
// makes the sky move as one thing rather than as a pattern crawling through a fixed
// window. It is the wind at the TOP of the profile because that is the height the
// cells are at; the shear below is already in the drift table.
void cellDriftAt(const IceParams& ice, Real timeSeconds, Real& outX, Real& outZ);

// ---------------------------------------------------------------------------
// The majorant
// ---------------------------------------------------------------------------

// 1.5, and it must equal GeneratorLib.slang's kFbmBound.
//
// |gradientNoise| <= sqrt(3) * sqrt(3)/2 for gradients in [-1,1]^3, and fbm divides
// by the sum of its amplitudes. It is derived, not tuned, which is why the detail
// term can be bounded without ever sampling it.
constexpr Real kFbmBound = Real(1.5);

// ---------------------------------------------------------------------------
// The generator's geometry, mirrored -- and these must equal GeneratorLib.slang's
// ---------------------------------------------------------------------------
//
/// SAME CONTRACT AS kFbmBound ABOVE, and the same hazard: these are the numbers
// cellField() is built from, and the bound below is a theorem about them. A change on
// one side and not the other does not fail to compile -- it produces a bound that is
// too low, and a majorant that is too low does not render slowly, it renders a cloud
// that is quietly too thin.
//
// SO slang.generator CHECKS THEM TWO WAYS, AND IT TAKES BOTH.
//
//   cellFieldPlane  runs the KERNEL's own cellField densely with every slot occupied and
//                   requires this bound to be above everything it finds. That catches a
//                   wrong DERIVATION, which matching constants would sail through.
//
//   cellGeometry    reads these four constants back out of the kernel and compares them
//                   exactly, and has the kernel derive and evaluate the four-blob worst
//                   case itself. That catches a DRIFTED COPY.
//
// THE SECOND ONE IS THERE BECAUSE THE FIRST WAS MEASURED AND FOUND INSUFFICIENT. Moving
// kCellSpacing here to 2.6 -- an 18% error, far more than a typo -- lowers the bound to
// 2.96, and a 49-patch sweep of 784 slot neighbourhoods finds only 1.77, so the sweep
// passed and the majorant was wrong with every test green.
//
// That is not a flaw in the sweep. Reaching 3.26 needs all four cells around one slot
// corner to have jittered towards it; the jitter is a hash of the slot, so it is fixed
// rather than free, and a few hundred neighbourhoods do not contain that configuration.
// IT IS STILL REACHED, because there is no seed and the sky is millions of slots wide --
// which is precisely why the bound must cover the rare case, and why a sampled maximum
// of this field is a floor and never a truth.
constexpr Real kCellSpacing  = Real(2.2);   // grid pitch, in cell-sizes
constexpr Real kCellJitter   = Real(0.8);   // the `jitter * 0.8` in cellField()
constexpr Real kBlobFar      = Real(1.0);   // smoothstep(1.0, 0.05, d) -- zero here
constexpr Real kBlobNear     = Real(0.05);  // ...and one here
constexpr int  kCellRadius   = 1;           // the 3x3 neighbourhood it sums over
constexpr Real kHeadFraction = Real(0.08);  // head = smoothstep(0, 0.08*L, depth)
constexpr Real kTailFraction = Real(0.75);  // tail = 1 - smoothstep(0.75*L, L, depth)

// How finely the two bounds below partition their search space. Both are CERTIFIED
// rather than sampled -- see each function -- so these set tightness, never soundness.
constexpr int kCellScanSteps  = 256;
constexpr int kDepthScanParts = 256;

// The largest cellField() / cellStrength can be, ANYWHERE.
//
// ---------------------------------------------------------------------------
// NINE WAS THE TRIVIAL ANSWER AND IT WAS 2.76x TOO BIG.
//
// cellField() sums a 3x3 neighbourhood of blobs, so "nine blobs, each with a ceiling
// of one" bounds it. That is sound, it is free, and it is wrong about the geometry: a
// point CANNOT be inside nine of these blobs at once, because the blobs are narrower
// than the grid they sit on.
//
// THE COUNT IS FOUR, AND IT IS A THEOREM RATHER THAN AN OBSERVATION. Work in grid
// units and let a point sit at fraction u along one axis of its slot.
//
//   * A blob vanishes at kBlobFar cell-sizes, which is kBlobFar / kCellSpacing =
//     0.4545 GRID units. That is its reach.
//   * A cell is its slot centre plus a jitter of +-kCellJitter/2, so it is never
//     nearer than inset = (1 - kCellJitter)/2 = 0.1 to the slot boundary.
//   * The slot one step UP the axis therefore holds every cell at least (1 + inset)-u
//     away along it; the slot one step DOWN, at least u + inset. THOSE TWO SUM TO
//     1 + 2*inset = 1.2, whatever u is.
//   * Both are in reach only if both are under 0.4545, so only if they sum to under
//     0.909. And 0.909 < 1.2, so AT MOST ONE OF THEM IS EVER IN REACH.
//
// Two offsets per axis, two axes: four slots, never nine. That alone is 2.25x.
//
// THE REMAINING 1.23x IS THAT FOUR BLOBS CANNOT ALL BE AT THEIR CEILING EITHER, and
// the same inequality gives it. On each axis the two reachable slots' distances sum to
// AT LEAST 2*inset = 0.2 -- exactly 0.2 when the point lies within inset of a slot
// boundary, and more when it does not. So the worst case is a two-parameter family and
// maximising over it is a search of a 0.1 x 0.1 square.
//
// WHICH IS A SEARCH, SO WHY IS IT NOT THE SAMPLING THIS FILE REFUSES TO DO. Because
// what is being searched is four smoothsteps of a distance -- Lipschitz, with a slope
// this function computes -- and NOT the fractal detail term. A scan of a Lipschitz
// function plus its Lipschitz slack is an upper bound on the true maximum, by
// construction. A scan of an fbm is a guess. That distinction is the whole reason
// `detail` is still bounded by kFbmBound and never sampled.
//
// The answer is 3.26 against nine. `steps` is exposed so that a test can show
// refining the scan does not move it past the slack the shipping one allows.
Real cellOverlapBound(int steps = kCellScanSteps);

// The largest sublimation * head * tail can be, together, at any depth.
//
// ---------------------------------------------------------------------------
// THREE FACTORS EACH BOUNDED BY ONE, WHICH IS TRUE AND USELESS, BECAUSE THEY CANNOT
// ALL BE ONE AT THE SAME DEPTH.
//
// `head` is a smoothstep RISING from zero at the generating level -- it is zero
// exactly where `sublimation` and `tail` are largest. So bounding each by one bounds
// the product by one, and the product never comes near one: on the defaults it peaks
// at 0.89, just below the depth at which the head finishes opening.
//
// EACH FACTOR IS MONOTONE IN DEPTH, which is what makes this exact rather than
// sampled. Over any interval a monotone function's maximum is at one end or the other,
// so partitioning [0, streakLength] and taking
//
//     max over intervals of  max(subl at ends) * max(head at ends) * max(tail at ends)
//
// bounds the product's maximum -- with no assumption about WHICH end, and none that
// the partition landed on the peak. Refining it can only lower the answer.
//
// AND IT CLOSES A SOUNDNESS HOLE THAT WAS ALREADY OPEN. "sublimation <= 1, being exp
// of a negative" holds only while the rate is positive. AE lets an expression drive
// any slider past its range, and at a NEGATIVE rate exp(-rate*depth/1000) grows
// without bound -- 4.2x at the default streak length and a rate of -1. The old bound
// omitted the factor entirely, so there it was not merely loose, it was BELOW the
// field. Evaluating the factor rather than asserting it is what fixes that, and
// ANegativeSublimationRateStillBounds is what pins it.
Real depthFactorBound(const IceParams& ice, int parts = kDepthScanParts);

// A SOUND upper bound on iceDensity() anywhere in the slab, per metre.
//
// ---------------------------------------------------------------------------
// SOUND, NOT TIGHT, AND THE ASYMMETRY IS THE WHOLE POINT.
//
// Null-collision tracking is unbiased for ANY majorant at or above the true maximum,
// and simply wrong below it -- a density that exceeds the majorant makes the
// collision probability greater than one, and the estimator silently stops being an
// estimator. So the cost of a loose bound is steps, which is time, and the cost of a
// tight-but-wrong one is a picture that is quietly incorrect. Only one of those is
// recoverable, and only one of them is visible.
//
// SAMPLING THE FIELD TO FIND ITS PEAK IS NOT AN OPTION at any resolution: the field
// is fractal in the detail term, and a sample grid that missed the peak by one metre
// would be wrong in exactly the way that does not show up until someone else's scene.
// So the bound is STRUCTURAL -- iceDensity is a product of factors, and each factor is
// bounded on its own:
//
//     cellField          <= cellOverlapBound() * cellStrength   (3.26, not 9)
//     subl * head * tail <= depthFactorBound(ice)               (0.89, not 1)
//     detail             <= 1 + 1.8 * amount * kFbmBound
//
// The product of the maxima bounds the maximum of the product. It is still looser than
// the truth -- `cell` and `detail` need not peak together, and most slots are empty at
// the default cellDensity while a bound that does not evaluate the hash must assume
// they are not -- but every step of it is an inequality that holds by construction
// rather than by measurement.
//
// MEASURED, 2026-09-28: the old bound ran 18.32x over the kernel's sampled peak. The
// two bounds above take that to 6.2x, a 2.96x cut in the majorant and therefore in the
// expected number of tracking steps -- every one of which is a four-octave fbm.
//
// WHAT IS LEFT IS NOT TIGHTENABLE BY THE SAME ARGUMENT.
//
//   * kFbmBound is 1.5 because hash33 returns gradients in the whole cube [-1,1]^3,
//     and sqrt(3) * sqrt(3)/2 is TIGHT for that distribution -- attained at a lattice
//     cell's centre. Lowering it means normalising the gradients, which changes the
//     field and so the look that passed Phase 0's verdict.
//   * The occupancy is a hash. At cellDensity 0.35 most slots are empty, and a bound
//     that does not evaluate the hash must assume none of them is. Knowing WHICH is
//     what a majorant GRID is for -- and SlangBridge.h records the measurement that
//     says the grid loses 7x on thin cirrus and wins 25x on a hard core, which is the
//     Phase 3 convective case rather than this one.
// ---------------------------------------------------------------------------
Real iceMajorant(const IceParams& ice);

} // namespace plugin::cloud
