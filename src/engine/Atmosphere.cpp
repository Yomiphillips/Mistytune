#include "Atmosphere.h"

#include <cmath>

namespace plugin::cloud {

namespace {

// ===========================================================================
// THE INTEGRATION RUNS IN DOUBLE AND THE TABLE STORES FLOAT, WHICH LOOKS LIKE IT
// CONTRADICTS THE RULE NEXT DOOR AND DOES NOT.
//
// CloudParams.h declares `Real = float` because those structs cross to the GPU as a
// kernel argument block, and OutputConvert.h refuses to widen for the opposite
// reason -- it quantises a float buffer the kernel wrote, so widening would move
// which integer a value lands on.
//
// Neither argument reaches here. This is a PRECOMPUTE: nothing downstream compares
// its output against a float-built reference, because it replaces the march it is
// derived from rather than reproducing it. What it does have to be is the same on
// every machine, and it is -- the table is built ONCE ON THE HOST and the CUDA path
// uploads those same floats, so the CPU and the GPU read bit-identical values. That
// is a stronger guarantee than the old inner march had, where each backend evaluated
// its own exp().
//
// The accumulation is where the width earns itself: a slant path near the horizon is
// hundreds of kilometres of 64 summed steps, and the summands span several orders of
// magnitude because density is exponential in altitude.
// ===========================================================================

// Matching src/kernel/Shading.h. NOT included from there -- src/engine/ holds no
// kernel headers, by the rule that makes this testable without a GPU. The parity is
// asserted by test rather than by sharing a header, which is the same arrangement
// SkyLib.slang and Shading.h are already in.
constexpr double kMieScaleHeight      = 1200.0;
constexpr double kAtmosphereEFoldings = 8.0;

// Rayleigh scattering coefficients at sea level, per metre, for R/G/B.
constexpr double kBetaR[3] = { 5.802e-6, 13.558e-6, 33.1e-6 };

// Mie, referenced to Linke turbidity 2.2.
double mieCoefficient(double turbidity) {
    return 3.996e-6 * (turbidity / 2.2);
}

// MIE EXTINCTION IS 1.11x MIE SCATTERING, because aerosol single-scatter albedo is
// about 0.9 and extinction is scattering divided by it. The same 1.11 appears in
// Shading.h, SkyLib.slang and proto/index.html; this is the fourth copy and the
// comment is here because it is the only one of the four that is a build rather than
// a march.
constexpr double kMieAlbedoInverse = 1.11;

// Distance from radius `r` along a ray of direction cosine `mu` to the top of the
// atmosphere at radius `rTop`.
//
// WRITTEN FROM RADIUS AND mu, NOT FROM A POSITION, so the planet-sized cancellation
// never happens: r is about 6.37e6 and the answer near the zenith is about 6.8e4, and
// subtracting two positions to get there loses most of the significant digits.
double distanceToTop(double r, double mu, double rTop) {
    const double disc = r * r * (mu * mu - 1.0) + rTop * rTop;
    const double root = disc > 0.0 ? std::sqrt(disc) : 0.0;
    const double t = -r * mu + root;
    return t > 0.0 ? t : 0.0;
}

// Does a ray from radius `r` with direction cosine `mu` hit the ground first?
//
// ONLY POSSIBLE LOOKING DOWNWARD, and then only if the ray's closest approach is
// inside the planet. Both halves are needed: mu < 0 alone would shadow a ray that
// dips and comes back out, which is most of the sky just below the horizon.
bool hitsGround(double r, double mu, double rGround) {
    if (mu >= 0.0) return false;
    const double disc = r * r * (mu * mu - 1.0) + rGround * rGround;
    return disc >= 0.0;
}

} // namespace

TransmittanceParams transmittanceParamsFrom(const PhysicsParams& physics,
                                            const AtmosphereParams& atmosphere) {
    TransmittanceParams p;
    p.turbidity    = atmosphere.turbidity;
    p.planetRadius = physics.planetRadius;
    p.scaleHeight  = physics.scaleHeight;
    return p;
}

void buildTransmittanceLut(const TransmittanceParams& params, Real* out, int floatCount) {
    if (!out || floatCount < kTransmittanceFloats) return;

    // CLAMPED THE SAME WAY Shading.h CLAMPS THEM, so an alien-physics preset that
    // drives either to zero gets the same floor in the table as in the march rather
    // than a division by nothing.
    const double planetRadius = params.planetRadius > 1000.0f ? double(params.planetRadius) : 1000.0;
    const double scaleHeight  = params.scaleHeight  > 1.0f    ? double(params.scaleHeight)  : 1.0;

    const double rGround = planetRadius;
    const double rTop    = planetRadius + scaleHeight * kAtmosphereEFoldings;

    const double betaMExt = mieCoefficient(double(params.turbidity)) * kMieAlbedoInverse;

    // 64 STEPS, MATCHING proto/index.html. It is the reference this is checked
    // against, and the table is built once per parameter change rather than once per
    // frame -- so the step count is bounded by accuracy, not by budget.
    constexpr int kSteps = 64;

    for (int yi = 0; yi < kTransmittanceAltitudeSize; ++yi) {
        // TEXEL CENTRES, NOT EDGES. The proto reads this table through a GL_LINEAR
        // sampler, whose texel centres sit at (i + 0.5) / size; building at (i / size)
        // and sampling at the centres would shift the whole table by half a texel,
        // which shows as a systematic brightness error near the horizon where the
        // gradient is steepest.
        const double v = (double(yi) + 0.5) / double(kTransmittanceAltitudeSize);

        // SQUARED, so the texels land where the function moves -- see Atmosphere.h.
        const double r = rGround + (rTop - rGround) * v * v;

        for (int xi = 0; xi < kTransmittanceMuSize; ++xi) {
            const double u  = (double(xi) + 0.5) / double(kTransmittanceMuSize);
            const double mu = u * 2.0 - 1.0;

            double depthR = 0.0;
            double depthM = 0.0;

            // A RAY THAT MEETS THE GROUND REACHES SPACE THROUGH NOTHING. Storing zero
            // rather than the transmittance of the partial path is what makes the
            // lookup a complete answer: the caller asks "how much sunlight gets here"
            // and a point in the planet's shadow gets none. Shading.h says the same
            // thing as an optical depth of 1e9; zero here is that, evaluated.
            if (!hitsGround(r, mu, rGround)) {
                const double tMax = distanceToTop(r, mu, rTop);
                const double dt   = tMax / double(kSteps);

                for (int i = 0; i < kSteps; ++i) {
                    const double t = (double(i) + 0.5) * dt;

                    // LAW OF COSINES FOR THE SAMPLE'S RADIUS. r, t and mu are all
                    // known exactly; forming a 3D position and taking its length
                    // instead would cancel six significant digits against the planet
                    // radius for every sample near the ground.
                    const double ri = std::sqrt(r * r + t * t + 2.0 * r * t * mu);
                    const double h  = ri - rGround > 0.0 ? ri - rGround : 0.0;

                    depthR += std::exp(-h / scaleHeight) * dt;
                    depthM += std::exp(-h / kMieScaleHeight) * dt;
                }
            } else {
                // Optical depth large enough that exp(-tau) is exactly 0.0f in float.
                depthR = 1e30;
                depthM = 1e30;
            }

            const int base = (yi * kTransmittanceMuSize + xi) * kTransmittanceChannels;
            for (int c = 0; c < 3; ++c) {
                const double tau = kBetaR[c] * depthR + betaMExt * depthM;
                out[base + c] = static_cast<Real>(std::exp(-tau));
            }
        }
    }
}

void sampleTransmittance(const Real* lut, const TransmittanceParams& params,
                         Real altitude, Real mu,
                         Real& outR, Real& outG, Real& outB) {
    outR = outG = outB = 0.0f;
    if (!lut) return;

    const double scaleHeight = params.scaleHeight > 1.0f ? double(params.scaleHeight) : 1.0;
    const double topAltitude = scaleHeight * kAtmosphereEFoldings;

    // THE INVERSE OF THE BUILD'S WARP, and getting it wrong is invisible: a sqrt
    // mismatched against a square still produces a smooth, plausible, wrong sky.
    // TheAltitudeWarpRoundTrips is the test that holds these two together.
    double h = double(altitude);
    if (h < 0.0) h = 0.0;
    if (h > topAltitude) h = topAltitude;
    const double v = std::sqrt(h / topAltitude);

    double m = double(mu);
    if (m < -1.0) m = -1.0;
    if (m > 1.0) m = 1.0;
    const double u = (m + 1.0) * 0.5;

    // TEXEL CENTRES AGAIN, matching the build: a coordinate of u maps to texel
    // u * size - 0.5, clamped at both ends so the edge texels extend rather than
    // wrapping into the opposite hemisphere.
    double fx = u * double(kTransmittanceMuSize) - 0.5;
    double fy = v * double(kTransmittanceAltitudeSize) - 0.5;
    if (fx < 0.0) fx = 0.0;
    if (fy < 0.0) fy = 0.0;

    int x0 = int(fx);
    int y0 = int(fy);
    if (x0 > kTransmittanceMuSize - 1)       x0 = kTransmittanceMuSize - 1;
    if (y0 > kTransmittanceAltitudeSize - 1) y0 = kTransmittanceAltitudeSize - 1;

    int x1 = x0 + 1, y1 = y0 + 1;
    if (x1 > kTransmittanceMuSize - 1)       x1 = kTransmittanceMuSize - 1;
    if (y1 > kTransmittanceAltitudeSize - 1) y1 = kTransmittanceAltitudeSize - 1;

    const double tx = fx - double(x0);
    const double ty = fy - double(y0);

    const int i00 = (y0 * kTransmittanceMuSize + x0) * kTransmittanceChannels;
    const int i10 = (y0 * kTransmittanceMuSize + x1) * kTransmittanceChannels;
    const int i01 = (y1 * kTransmittanceMuSize + x0) * kTransmittanceChannels;
    const int i11 = (y1 * kTransmittanceMuSize + x1) * kTransmittanceChannels;

    Real* outs[3] = { &outR, &outG, &outB };
    for (int c = 0; c < 3; ++c) {
        const double a = double(lut[i00 + c]) * (1.0 - tx) + double(lut[i10 + c]) * tx;
        const double b = double(lut[i01 + c]) * (1.0 - tx) + double(lut[i11 + c]) * tx;
        *outs[c] = static_cast<Real>(a * (1.0 - ty) + b * ty);
    }
}

} // namespace plugin::cloud
