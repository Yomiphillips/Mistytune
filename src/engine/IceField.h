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
// would be wrong in exactly the way that does not show up until someone else scene.
// So the bound is STRUCTURAL -- iceDensity is a product of factors, and each factor
// is bounded on its own:
//
//     cellField   <= 9 * cellStrength  (nine slots in the 3x3 neighbourhood, each
//                                       blob a smoothstep with a ceiling of 1)
//     sublimation <= 1                 (exp of a negative, maximal at depth 0)
//     head        <= 1                 (a smoothstep)
//     tail        <= 1                 (a smoothstep)
//     detail      <= 1 + 1.8 * amount * kFbmBound
//
// The product of the maxima bounds the maximum of the product. It is looser than the
// truth because the factors do not all peak at the same point -- notably, `head` is
// zero exactly where `sublimation` and `tail` are largest -- but every step of it is
// an inequality that holds by construction rather than by measurement.
//
// MEASURED CONSEQUENCE, 2026-09-28: on thin cirrus the tracker runs about 2.4 steps
// against a cap of 1024, so several times loose is several times cheap rather than
// anywhere near a hazard. It is the convective generators of Phase 3 that will need
// the majorant GRID, which already exists and is proved correct.
// ---------------------------------------------------------------------------
Real iceMajorant(const IceParams& ice);

} // namespace plugin::cloud
