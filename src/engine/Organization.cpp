#include "Organization.h"

#include <cmath>

namespace plugin::cloud {

namespace {

constexpr double kDegToRad = 0.017453292519943295;

// NaN comes out as `lo`: `!(v >= lo)` is true for it, where `v < lo` is not.
Real clampSafe(Real v, Real lo, Real hi) {
    if (!(v >= lo)) return lo;
    return v > hi ? hi : v;
}

// A bearing as a unit vector in world xz, clockwise from +Z like the winds'. In double,
// so 90 degrees comes out as (1, 0) to float precision and the frame is the world's.
void bearingAxis(Real bearing, Real& x, Real& z) {
    const double b = std::isfinite(bearing) ? static_cast<double>(bearing) * kDegToRad : 0.0;
    x = static_cast<Real>(std::sin(b));
    z = static_cast<Real>(std::cos(b));
}

} // namespace

OrganizationResolved resolveOrganization(const OrganizationParams& p, bool deck) {
    OrganizationResolved o;

    const int  mode      = p.mode < 0 || p.mode > 3 ? 0 : p.mode;
    const Real aspect    = clampSafe(p.aspectRatio, Real(1), Real(100));
    const Real coherence = clampSafe(p.coherence, Real(0), Real(1));
    const Real amplitude = clampSafe(p.waveAmplitude, Real(0), Real(1));
    const Real gap       = deck ? clampSafe(p.gapFraction, Real(0), Real(1)) : Real(0);
    const Real lac       = deck ? clampSafe(p.lacunarity, Real(0), Real(1)) : Real(0);

    // WHETHER THE ALIGNMENT TURNS ANYTHING, compared on the circle so a dial keyframed
    // round to 450 still counts as the identity.
    const double turn = std::isfinite(p.alignment)
                      ? std::remainder(static_cast<double>(p.alignment) - kAlignmentIdentity, 360.0)
                      : 0.0;

    o.on = mode != 0 || aspect > Real(1) || coherence > Real(0) || amplitude > Real(0) ||
           gap > Real(0) || lac > Real(0) || turn != 0.0;
    if (!o.on) return o;

    bearingAxis(p.alignment, o.axisX, o.axisZ);
    o.stretch   = aspect;
    o.coherence = coherence;

    // THE WAVE'S CRESTS RUN ALONG waveAngle, so it varies across them.
    Real crestX, crestZ;
    bearingAxis(p.waveAngle, crestX, crestZ);
    const Real length = std::isfinite(p.waveLength) && p.waveLength > Real(10)
                      ? p.waveLength : Real(10);
    o.waveKX = crestZ / length;
    o.waveKZ = -crestX / length;
    o.waveAmplitude = amplitude;

    switch (static_cast<OrganizationMode>(mode)) {
        case OrganizationMode::Rolls:
            o.stretch = aspect * kRollStretch;
            break;
        case OrganizationMode::Waves:
            o.axisX = crestX;
            o.axisZ = crestZ;
            o.stretch = aspect * kWavesStretch;
            o.waveAmplitude = amplitude > kWavesMinAmplitude ? amplitude : kWavesMinAmplitude;
            break;
        case OrganizationMode::Chaotic:
            o.coherence = Real(0);
            o.warp = kChaoticWarp;
            break;
        case OrganizationMode::Cellular:
            break;
    }

    o.gapWidth   = std::sqrt(gap) * kGapWidthMax;
    o.lacunarity = lac;
    return o;
}

} // namespace plugin::cloud
