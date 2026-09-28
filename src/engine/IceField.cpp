#include "IceField.h"

#include <cmath>

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

Real iceMajorant(const IceParams& ice) {
    // Nine slots in the 3x3 neighbourhood cellField() sums over, each contributing a
    // smoothstep that cannot exceed 1, all scaled by cellStrength.
    const Real strength = ice.cellStrength > Real(0) ? ice.cellStrength : Real(0);
    const Real cellMax  = Real(9) * strength;

    // detail = 1 + detailAmount * fbm * 1.8, and |fbm| <= kFbmBound.
    const Real amount    = ice.detailAmount > Real(0) ? ice.detailAmount : Real(0);
    const Real detailMax = Real(1) + Real(1.8) * amount * kFbmBound;

    // sublimation, head and tail are each bounded by 1 and are omitted rather than
    // multiplied in as literal ones -- see the header for why the bound is a product
    // of per-factor maxima and why that is sound without being tight.
    const Real optical = ice.opticalDepth > Real(0) ? ice.opticalDepth : Real(0);

    const Real bound = cellMax * detailMax * safeDiv(optical, ice.streakLength, Real(1));

    // NEVER ZERO. A majorant of zero makes every free-flight distance infinite, so the
    // tracker leaves the slab on its first step and the medium vanishes -- which reads
    // as "the cloud is not there" rather than as a degenerate parameter. A tiny
    // positive floor keeps the estimator well-formed at settings that produce no
    // cloud, and costs nothing because there is nothing to hit.
    return bound > Real(1e-12) ? bound : Real(1e-12);
}

} // namespace plugin::cloud
