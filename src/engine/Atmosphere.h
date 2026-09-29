#pragma once

// The transmittance table: how much light survives from a point in the atmosphere,
// in a given direction, out to space.
//
// ===========================================================================
// THIS IS THE WHOLE REASON A PRECOMPUTED ATMOSPHERE IS AFFORDABLE, and it is the
// difference between the Phase 1 sky in Shading.h and the one proto/index.html passed
// the Phase 0 look verdict with.
//
// Without it, every atmosphere sample on a view ray has to march TOWARDS THE SUN to
// find out how much sunlight reached it -- an inner loop multiplying against the outer
// one. Shading.h's sunOpticalDepth() is exactly that inner loop, 8 steps deep, run at
// every step of the view march. The cost is quadratic in a quantity that is not even
// view-dependent.
//
// THE TABLE IS NOT VIEW-DEPENDENT AND NOT SUN-DEPENDENT. Sun DIRECTION enters as a
// lookup coordinate (mu, the cosine of the zenith angle), not as an input to the
// build -- so moving the sun, which is the thing an artist does constantly, does not
// invalidate it. What invalidates it is turbidity, planet radius and scale height:
// the Physics tab, which is the thing an artist sets once.
//
// ===========================================================================
// WHY IT IS IN src/engine/ AND BUILT ON THE HOST.
//
// It is a pure function of three numbers, it costs roughly a million exp() calls, and
// it must be CACHED rather than rebuilt -- deriveRenderInputs() runs once per launch
// and a frame is many launches. Host code that is expensive, cacheable and testable
// without a GPU is precisely what src/engine/ is for; the drift table next door is the
// same shape of thing, one size up.
//
// THE KERNEL RECEIVES IT AS DATA, exactly as it receives the drift table -- a bare
// pointer in RenderRequest, host memory on the CPU path and a device upload on the
// CUDA one. Nothing in src/kernel/ knows this file exists.
// ===========================================================================

#include "CloudParams.h"

namespace plugin::cloud {

// ---------------------------------------------------------------------------
// The table's shape
// ---------------------------------------------------------------------------

// 256 x 64, matching proto/index.html, which is the reference this port is checked
// against rather than a size chosen here.
//
// THE AXES ARE NOT SYMMETRICAL IN IMPORTANCE, which is why they are not the same
// length. mu -- the direction cosine -- is where the table changes fastest: near the
// horizon a degree of elevation changes the slant path through the air by a large
// factor, and banding there shows as a visible step in the sunset gradient. Altitude
// is the gentler axis and gets a quarter of the resolution.
constexpr int kTransmittanceMuSize       = 256;   // x: cosine of the zenith angle
constexpr int kTransmittanceAltitudeSize = 64;    // y: altitude, warped -- see below

// Three floats per texel: the table is wavelength-dependent and that is the point of
// it. Rayleigh scattering goes as roughly lambda^-4, so blue is removed from a long
// slant path an order of magnitude faster than red -- which IS the sunset.
constexpr int kTransmittanceChannels = 3;

constexpr int kTransmittanceFloats =
    kTransmittanceMuSize * kTransmittanceAltitudeSize * kTransmittanceChannels;

// ---------------------------------------------------------------------------
// What the table depends on
// ---------------------------------------------------------------------------

// THE ONLY THREE INPUTS, SEPARATED FROM THE PARAMETER STRUCTS THEY LIVE IN.
//
// turbidity comes from AtmosphereParams; planetRadius and scaleHeight come from
// PhysicsParams. Taking the two structs would say this depends on the sun, the ground
// albedo and the lapse rate, and it does not -- which matters because the cache key
// is built from exactly this and nothing else. A key over more than the dependency
// rebuilds a 196 KB table every time the artist drags the sun.
struct TransmittanceParams {
    Real turbidity    = 2.2f;
    Real planetRadius = 6371000.0f;
    Real scaleHeight  = 8500.0f;

    // Equality, so the cache can ask "did anything I depend on move?" without a hash.
    // THREE FLOATS COMPARED EXACTLY IS RIGHT HERE and would be wrong for a fingerprint:
    // these come straight from parameter values, not from arithmetic, so a bit-for-bit
    // comparison is asking exactly the question the cache means.
    bool operator==(const TransmittanceParams& o) const {
        return turbidity == o.turbidity
            && planetRadius == o.planetRadius
            && scaleHeight == o.scaleHeight;
    }
    bool operator!=(const TransmittanceParams& o) const { return !(*this == o); }
};

TransmittanceParams transmittanceParamsFrom(const PhysicsParams& physics,
                                            const AtmosphereParams& atmosphere);

// ---------------------------------------------------------------------------
// Building it
// ---------------------------------------------------------------------------

// Fills `out` with kTransmittanceFloats floats: RGB transmittance to space.
//
// LAID OUT ROW-MAJOR IN mu, so one altitude row is contiguous -- which is the axis a
// bilinear sample interpolates along most often and the one the kernel walks.
//
// THE ALTITUDE AXIS IS WARPED BY A SQUARE, and that is not a micro-optimisation. Air
// density falls off exponentially, so nearly all of the atmosphere's mass is in its
// lowest few kilometres; a linear altitude axis spends half the table on the
// near-vacuum above 30 km, where the transmittance is 1 everywhere and needs no
// resolution at all. v*v puts the texels where the function changes.
//
// SAFE WITH A NULL OR SHORT BUFFER -- it simply does nothing, because the caller that
// gets this wrong is the one that then renders with an uninitialised table, and a
// black sky is easier to chase than a subtly wrong one.
void buildTransmittanceLut(const TransmittanceParams& params, Real* out, int floatCount);

// ---------------------------------------------------------------------------
// Reading it
// ---------------------------------------------------------------------------

// Bilinear sample: transmittance from `altitude` metres, in the direction whose
// cosine-of-zenith-angle is `mu`, out to space.
//
// THE SAME FUNCTION THE KERNEL WILL USE, living here so that tests/unit/ can check the
// table against the closed forms it has to satisfy without a GPU or a render. When the
// kernel gains its own copy for the device, this is what it is checked against -- the
// arrangement Shading.h and SkyLib.slang already use, and slang.skyParity is the
// pattern for comparing them.
//
// CLAMPED AT BOTH EDGES, not wrapped. mu = -1 is straight down and mu = +1 is straight
// up; there is nothing past either, and a wrap would fetch the opposite hemisphere.
void sampleTransmittance(const Real* lut, const TransmittanceParams& params,
                         Real altitude, Real mu,
                         Real& outR, Real& outG, Real& outB);

} // namespace plugin::cloud
