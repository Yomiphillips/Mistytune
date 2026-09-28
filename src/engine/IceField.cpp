#include "IceField.h"

#include <cmath>
#include <limits>

namespace plugin::cloud {

namespace {

// Degrees to radians, spelled out rather than taken from a header, because this
// file is compiled by MSVC, clang and gcc and only one of them offers M_PI without
// a define first.
constexpr Real kDegToRad = Real(0.01745329252);

Real safeDiv(Real numerator, Real denominator, Real floorValue) {
    const Real d = denominator > floorValue ? denominator : floorValue;
    return numerator / d;
}

Real clamp01(Real t) {
    return t < Real(0) ? Real(0) : (t > Real(1) ? Real(1) : t);
}

// smoothstep AS HLSL AND SLANG COMPUTE IT, INCLUDING THE REVERSED-EDGE CASE, because
// cellField() depends on that case and nothing in the C++ standard library has it.
//
// Slang does not special-case edge0 > edge1: it evaluates saturate((x - edge0) /
// (edge1 - edge0)) and then the cubic. So `smoothstep(1.0, 0.05, d)` -- the blob in
// cellField() -- is ONE at the centre and falls to zero a cell away, which is the
// opposite orientation to the head and tail smoothsteps in the same function. Writing
// the formula out once is what keeps this file's arithmetic the kernel's arithmetic
// instead of a paraphrase of it.
Real smoothstepAs(Real edge0, Real edge1, Real x) {
    const Real span = edge1 - edge0;

    // A ZERO SPAN IS A STEP, and it is the limit of the cubic rather than a special
    // case invented here: as the edges close, the ramp between them vanishes.
    if (span == Real(0)) return x < edge0 ? Real(0) : Real(1);

    const Real t = clamp01((x - edge0) / span);
    return t * t * (Real(3) - Real(2) * t);
}

// One generating cell's contribution at distance `d`, measured IN CELL-SIZES -- the
// units cellField() converts to before it calls smoothstep, not grid units.
Real blobAt(Real d) { return smoothstepAs(kBlobFar, kBlobNear, d); }


} // namespace

Real habitFallSpeed(IceHabit habit) {
    // THESE ARE proto/index.html's HABIT_FALL, VALUE FOR VALUE, AND THAT IS THE
    // POINT RATHER THAN A COINCIDENCE.
    //
    // The prototype is what passed the Phase 0 look verdict, so it is the reference
    // this port is checked against -- and fall speed is not a free parameter here.
    // It divides the shear integral, so it sets how far a streak trails: at 1.0 m/s
    // a crystal takes 43 minutes to fall 2.6 km and the wind carries it tens of
    // kilometres. Halving it doubles that, which is the difference between a
    // fallstreak and a featureless sheet.
    //
    // A first version of this file guessed at these numbers and got Column wrong by
    // 40%. The render was a horizontally banded smear, which reads as a bug in the
    // transport rather than as one in a table.
    switch (habit) {
        case IceHabit::Plate:     return Real(0.35);
        case IceHabit::Column:    return Real(1.0);
        case IceHabit::Bullet:    return Real(1.4);
        case IceHabit::Dendrite:  return Real(0.28);
        case IceHabit::Aggregate: return Real(0.9);
    }
    // NOT A DEFAULT LABEL INSIDE THE SWITCH, deliberately. With every enumerator
    // listed and no default, adding a habit is a compiler warning here rather than a
    // crystal that silently falls at whatever Column does -- which would show up as
    // a streak shape that is wrong in a way nobody would think to look for.
    return Real(0.60);
}

Real iceFallSpeed(const IceParams& ice) {
    const Real v = habitFallSpeed(ice.habit) * ice.fallSpeedScale;

    // A FLOOR, NOT A CLAMP TO ZERO. The fall speed is a divisor: it sets the time a
    // parcel has been falling, and the drift is wind times that time. At zero the
    // parcel never falls, has been in the wind forever, and every streak stretches
    // to infinity -- which renders as a uniform grey slab rather than as an obvious
    // divide-by-zero.
    return v > Real(0.01) ? v : Real(0.01);
}

void shearWindAt(const IceParams& ice, Real depthMetres, Real& outX, Real& outZ) {
    const Real streak = ice.streakLength > Real(1) ? ice.streakLength : Real(1);

    Real t = depthMetres / streak;
    if (t < Real(0)) t = Real(0);
    if (t > Real(1)) t = Real(1);

    // Knot 0 is the generating level, knot kShearKnots-1 the bottom of the streak.
    const Real fIndex = t * Real(kShearKnots - 1);

    int i = static_cast<int>(fIndex);
    if (i < 0) i = 0;
    if (i > kShearKnots - 2) i = kShearKnots - 2;
    const Real f = fIndex - static_cast<Real>(i);

    // ---------------------------------------------------------------------
    // INTERPOLATE THE VECTOR, NOT THE BEARING. Two knots at 350 and 10 degrees are
    // twenty degrees apart, and averaging the NUMBERS gives 180 -- a wind blowing
    // backwards, from one interpolation step, in the middle of an otherwise
    // reasonable profile. Resolving each knot to a vector first and interpolating
    // those takes the short way round by construction and needs no unwrapping.
    //
    // It also does the right thing to the speed at the same time: a profile whose
    // direction reverses passes through a genuine lull, which is what the atmosphere
    // does, rather than holding its speed while it snaps around.
    // ---------------------------------------------------------------------
    const Real b0 = ice.shear.bearing[i]     * kDegToRad;
    const Real b1 = ice.shear.bearing[i + 1] * kDegToRad;

    // A bearing is where the wind comes FROM, so the velocity points the other way.
    const Real x0 = -ice.shear.speed[i]     * std::sin(b0);
    const Real z0 = -ice.shear.speed[i]     * std::cos(b0);
    const Real x1 = -ice.shear.speed[i + 1] * std::sin(b1);
    const Real z1 = -ice.shear.speed[i + 1] * std::cos(b1);

    outX = x0 + (x1 - x0) * f;
    outZ = z0 + (z1 - z0) * f;
}

void buildDriftTable(const IceParams& ice, DriftTable& out) {
    const Real streak = ice.streakLength > Real(1) ? ice.streakLength : Real(1);
    const Real v      = iceFallSpeed(ice);

    const Real step = streak / static_cast<Real>(kDriftKnots - 1);

    // =====================================================================
    // THE WIND IS TAKEN RELATIVE TO THE GENERATING LEVEL, AND THIS IS PHYSICS
    // RATHER THAN A CONVENIENCE. Removing these two lines is the single most
    // convincing way to make the generator look broken.
    //
    // The generating cell is not nailed to the ground. It is carried by the wind at
    // ITS OWN altitude -- 34 m/s in the default profile -- and a crystal falling out
    // of it is carried by the wind at whatever level it has reached. What draws the
    // streak is the DIFFERENCE between those two, which is what shear means.
    //
    // Integrating the absolute wind puts the streak tens of kilometres downwind of a
    // cell that has travelled just as far: 88 km of drift for 2.6 km of fall, at the
    // defaults. Every streak then overlaps every other one, and the sky renders as a
    // featureless horizontally banded sheet -- which looks like a bug in the
    // transport, or in the noise, or in the camera. It is none of those. It is the
    // frame of reference.
    //
    // MEASURED, because this port made exactly that mistake and the render is in
    // PROGRESS.md: the first image out of the Slang renderer was uniform horizontal
    // banding across the whole frame with no cellular structure at all.
    //
    // WITH THE SUBTRACTION THERE IS AN OBVIOUS CHECK: a profile with no shear at all
    // gives a vertical curtain hanging straight below its cell, because every
    // relative wind is zero. proto/index.html reaches the same conclusion in the
    // same words, and it is the version whose look was accepted.
    //
    // The bulk motion is not lost -- it is cellDriftAt(), which moves the cells
    // themselves. That is the correct home for it: the whole sky travels, and the
    // streaks hang off it.
    // =====================================================================
    Real w0x = Real(0), w0z = Real(0);
    shearWindAt(ice, Real(0), w0x, w0z);

    out.xz[0] = Real(0);
    out.xz[1] = Real(0);

    Real accX = Real(0);
    Real accZ = Real(0);

    for (int k = 1; k < kDriftKnots; ++k) {
        // The midpoint of the interval [k-1, k], which integrates the piecewise
        // linear profile exactly. See the header on why the left-hand rule is not
        // merely less accurate but biased.
        const Real depthMid = step * (static_cast<Real>(k) - Real(0.5));

        Real wx = Real(0), wz = Real(0);
        shearWindAt(ice, depthMid, wx, wz);

        // Time spent crossing this interval: the depth it spans, over the fall speed.
        const Real dt = step / v;

        accX += (wx - w0x) * dt;
        accZ += (wz - w0z) * dt;

        out.xz[2 * k]     = accX;
        out.xz[2 * k + 1] = accZ;
    }
}

void cellDriftAt(const IceParams& ice, Real timeSeconds, Real& outX, Real& outZ) {
    Real wx = Real(0), wz = Real(0);
    shearWindAt(ice, Real(0), wx, wz);
    outX = wx * timeSeconds;
    outZ = wz * timeSeconds;
}

// ---------------------------------------------------------------------------
// THE GUARD ON THE THEOREM, AND IT IS A COMPILE ERROR RATHER THAN A FALLBACK.
//
// Four reachable slots per point rather than nine holds only while the two off-slots on
// an axis cannot BOTH be in reach of it, and that is exactly
//
//     2 * (kBlobFar / kCellSpacing)  <=  1 + 2 * inset,   inset = (1 - kCellJitter)/2
//
// which is the inequality the header derives. Widen the jitter or narrow the spacing
// past it and cellOverlapBound()'s whole argument stops applying.
//
// A RUNTIME FALLBACK TO THE TRIVIAL NINE WOULD BE THE SAFE-LOOKING CHOICE AND THE WORSE
// ONE. It keeps rendering -- correctly, 2.76x slower -- with nothing anywhere saying
// why, which is the failure this project spends its comments on avoiding. Breaking the
// build names the file to re-read instead. Same argument as EffectFlags.cmake's
// static_assert on out_flags, and the same reason it is worth a line.
// ---------------------------------------------------------------------------
static_assert(Real(2) * (kBlobFar / kCellSpacing) <= Real(1) + (Real(1) - kCellJitter),
              "cellOverlapBound()'s four-slot derivation no longer holds for these "
              "constants: two off-slots on one axis can now both be in reach of the "
              "same point, so a blob-overlap bound has to go back to nine. See the "
              "derivation over cellOverlapBound() in IceField.h.");

Real cellOverlapBound(int steps) {
    // Every slot in the neighbourhood cellField() sums over, each blob at its ceiling
    // of one. Sound, free, and the number this function replaced.
    const Real trivial = Real((2 * kCellRadius + 1) * (2 * kCellRadius + 1));

    if (steps < 1) return trivial;

    // See the static_assert above: `separation` is 2*inset, and the four-slot count is
    // guaranteed at compile time rather than checked here.
    const Real inset      = (Real(1) - kCellJitter) / Real(2);
    const Real separation = Real(2) * inset;

    // THE SCAN. `a` is the distance, along one axis, from the point to the nearest
    // position its OWN slot's cell may occupy. The partner slot on that axis is then at
    // `separation - a` at the closest -- which is the worst case, since the blob only
    // decreases -- and the pair {a, separation - a} is unordered, so sweeping a over
    // [0, separation/2] enumerates every configuration exactly once.
    const Real span = separation * Real(0.5);

    Real best = Real(0);
    for (int ia = 0; ia <= steps; ++ia) {
        const Real a  = span * Real(ia) / Real(steps);
        const Real a2 = separation - a;

        for (int ic = 0; ic <= steps; ++ic) {
            const Real c  = span * Real(ic) / Real(steps);
            const Real c2 = separation - c;

            // Slot (i,j) of the four sits at per-axis distances (a or a2, c or c2), and
            // its distance is the hypotenuse -- the point's distance to an axis-aligned
            // box being exactly the per-axis distances combined that way.
            const Real sum =
                blobAt(std::sqrt(a  * a  + c  * c ) * kCellSpacing) +
                blobAt(std::sqrt(a2 * a2 + c  * c ) * kCellSpacing) +
                blobAt(std::sqrt(a  * a  + c2 * c2) * kCellSpacing) +
                blobAt(std::sqrt(a2 * a2 + c2 * c2) * kCellSpacing);

            if (sum > best) best = sum;
        }
    }

    // ---------------------------------------------------------------------
    // THE LIPSCHITZ SLACK IS WHAT MAKES THE SCAN A BOUND RATHER THAN A SAMPLE, and it
    // is the difference between this and the sampled majorant this file refuses to use.
    //
    // |d/dt of t*t*(3-2t)| peaks at 1.5; t moves 1/(kBlobFar - kBlobNear) per cell-size
    // of distance; distance moves at most kCellSpacing per grid unit of `a`, and at
    // most 1 per unit of either leg of the hypotenuse. So each of the four terms has a
    // slope of at most 1.5*kCellSpacing/(far - near) in `a`, and the sum four times
    // that. The true maximum is within half a step of a scanned point on each axis, so
    // adding that slope over half a step, once per axis, cannot under-report it.
    //
    // It is 0.0054 at 256 steps against an answer of 3.26 -- present for the argument's
    // sake rather than for its size, and RefiningTheCellScanDoesNotRaiseTheBound is
    // what shows the argument is not merely decorative.
    // ---------------------------------------------------------------------
    const Real slope = Real(4) * Real(1.5) * kCellSpacing / (kBlobFar - kBlobNear);
    const Real half  = span / Real(steps) * Real(0.5);

    const Real certified = best + Real(2) * slope * half;
    return certified < trivial ? certified : trivial;
}

Real depthFactorBound(const IceParams& ice, int parts) {
    const Real length = ice.streakLength;

    // NO SLAB MEANS NO DEPTH RANGE TO SEARCH. iceDensity() returns zero for every depth
    // outside [0, streakLength], so a non-positive length has no interior at all, and
    // one is the bound every factor already carries.
    if (!(length > Real(0)) || parts < 1) return Real(1);

    const Real headEdge = kHeadFraction * length;
    const Real tailEdge = kTailFraction * length;

    Real best = Real(0);

    for (int i = 0; i < parts; ++i) {
        const Real d0 = length * Real(i)     / Real(parts);
        const Real d1 = length * Real(i + 1) / Real(parts);

        // THE MAXIMUM OF THE TWO ENDS, WITHOUT ASSUMING WHICH END IT IS. Every factor
        // here is monotone in depth, so its extreme over the interval is at an end --
        // but WHICH end flips with the sign of the sublimation rate, and AE lets an
        // expression drive that negative. Taking both costs one comparison and removes
        // the assumption entirely.
        const Real s0 = std::exp(-ice.sublimationRate * d0 / Real(1000));
        const Real s1 = std::exp(-ice.sublimationRate * d1 / Real(1000));
        const Real subl = s0 > s1 ? s0 : s1;

        const Real h0 = smoothstepAs(Real(0), headEdge, d0);
        const Real h1 = smoothstepAs(Real(0), headEdge, d1);
        const Real head = h0 > h1 ? h0 : h1;

        const Real t0 = Real(1) - smoothstepAs(tailEdge, length, d0);
        const Real t1 = Real(1) - smoothstepAs(tailEdge, length, d1);
        const Real tail = t0 > t1 ? t0 : t1;

        // A PRODUCT OF PER-FACTOR INTERVAL MAXIMA, which bounds the product's maximum
        // over the interval because every factor here is non-negative. The maximum over
        // the intervals then bounds it over the whole slab.
        const Real product = subl * head * tail;
        if (product > best) best = product;
    }

    // AN OVERFLOWING SUBLIMATION TERM HAS NO REPRESENTABLE BOUND, and pretending
    // otherwise would be the one failure this whole file exists to avoid. A rate of
    // -1000 makes exp(+2600) infinite, so the field really is unbounded in float and
    // the honest answer is the largest one there is: it renders as empty sky, because
    // sigma/majorant is then zero everywhere, rather than as NaN pixels. The parameter
    // is nonsense at that point and no majorant rescues it.
    if (!std::isfinite(best)) return std::numeric_limits<Real>::max();

    return best;
}

Real iceMajorant(const IceParams& ice) {
    // COMPUTED ONCE, EVER. cellOverlapBound() reads the generator's geometry constants
    // and no parameter at all, so the scan runs on first use and never again.
    //
    // FUNCTION-LOCAL STATIC INITIALISATION IS THREAD-SAFE in C++11 and later, and that
    // is not incidental here: PF_OutFlag2_SUPPORTS_THREADED_RENDERING means several AE
    // frames are inside this call at once.
    static const Real cellOverlap = cellOverlapBound();

    const Real strength = ice.cellStrength > Real(0) ? ice.cellStrength : Real(0);
    const Real cellMax  = cellOverlap * strength;

    // detail = 1 + detailAmount * fbm * 1.8, and |fbm| <= kFbmBound.
    const Real amount    = ice.detailAmount > Real(0) ? ice.detailAmount : Real(0);
    const Real detailMax = Real(1) + Real(1.8) * amount * kFbmBound;

    // sublimation, head and tail TOGETHER rather than each bounded by one and
    // multiplied out. See depthFactorBound() for why that is worth a scan, and why
    // leaving them out was not merely loose but unsound at a negative rate.
    const Real depthMax = depthFactorBound(ice);

    const Real optical = ice.opticalDepth > Real(0) ? ice.opticalDepth : Real(0);

    const Real bound = cellMax * detailMax * depthMax
                     * safeDiv(optical, ice.streakLength, Real(1));

    // NEVER ZERO. A majorant of zero makes every free-flight distance infinite, so the
    // tracker leaves the slab on its first step and the medium vanishes -- which reads
    // as "the cloud is not there" rather than as a degenerate parameter. A tiny
    // positive floor keeps the estimator well-formed at settings that produce no
    // cloud, and costs nothing because there is nothing to hit.
    return bound > Real(1e-12) ? bound : Real(1e-12);
}

} // namespace plugin::cloud
