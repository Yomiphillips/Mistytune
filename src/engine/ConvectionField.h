#pragma once

// The host's half of the convection generator: the numbers the kernel cannot work out
// for itself, derived once per parameter change.
//
// SAME ARRANGEMENT AS IceField.h, FOR THE SAME REASON. Each of these is a function of
// the parameters only -- no pixel, no ray, no position -- so computing it on the GPU
// would be the same answer recomputed a few billion times a frame. And because it is
// plain arithmetic over CloudParams, tests/unit/ can check it without a card.

#include "CloudParams.h"
#include "Organization.h"

namespace plugin::cloud {

// ---------------------------------------------------------------------------
// The base: where rising air first saturates
// ---------------------------------------------------------------------------

// The dew point, in kelvin, of air at `tempK` and relative humidity `relHumidity`
// (0..1). The Magnus form with Alduchov and Eskridge's (1996) coefficients, good to
// about 0.1 K over the range weather lives in.
//
// A HUMIDITY OF ZERO HAS NO DEW POINT -- the logarithm runs away -- so it is floored
// at 1%. Air that dry has a condensation level far above any lid a user can set, which
// is the physically right answer: no cumulus.
Real dewPoint(Real tempK, Real relHumidity);

// The lifting condensation level, in metres above the surface: the height at which a
// parcel lifted from the ground cools to its own dew point and cloud begins.
//
// ---------------------------------------------------------------------------
// THIS IS THE FLAT BASE, and it is a consequence of the air rather than a parameter.
//
// A rising parcel cools at the dry adiabatic rate, g/cp, while its dew point falls
// much more slowly. The two meet at
//
//     LCL = (T - Td) / (g/cp - dewpoint lapse)
//
// which on Earth is the familiar 125 m per kelvin of dew-point depression. Every parcel
// in the boundary layer starts from the same surface air, so every one of them
// saturates at the same height -- which is WHY a cumulus field has one flat base across
// the whole sky, and why a floating soft base reads as fake.
//
// GRAVITY IS IN IT, deliberately. Both lapse rates scale with g, so the Physics tab's
// gravity moves the base: at a third of Earth's gravity the same air saturates three
// times higher. That is the kind of consequence the spec means by "realism is internal
// consistency" -- the alien sky follows from the constant rather than being painted.
// ---------------------------------------------------------------------------
Real condensationLevel(const PhysicsParams& physics);

// ---------------------------------------------------------------------------
// The droplets' phase function
// ---------------------------------------------------------------------------

// The Jendersie-d'Eon (2023) fit's four parameters for a droplet diameter in microns.
//
// A MIRROR OF PhaseLib.slang's phaseFromDropletDiameter, including the clamps, because
// the marshalling into the kernel runs on the device and cannot call into src/engine/,
// and the kernel cannot be asked per ray for something that depends only on a slider.
// slang.bounce compares the two across the whole diameter range, so a drift on either
// side fails a test rather than rendering a subtly different forward peak.
struct DropletPhase {
    Real hgG         = 0;
    Real draineG     = 0;
    Real draineAlpha = 0;
    Real draineW     = 0;
};

DropletPhase dropletPhase(Real diameterMicrons);

// ===========================================================================
// THE DIFFRACTION LOBE, TRUNCATED -- WHICH IS WHAT MAKES A CUMULUS RENDERABLE AT ALL.
//
// At 20 microns the fit's HG term has g = 0.995 and carries half the scattering: a
// diffraction lobe a degree wide that peaks near 4e4 per steradian. Multiple scattering
// through it is a firefly generator -- a path's direction deep inside a cloud is nearly
// random, and the rare one within a degree of the sun brings back a next-event estimate
// ten thousand times the mean. MEASURED: 64 spp of a cumulus was salt and pepper, and
// swapping in a broad phase function cleared it.
//
// DELTA-EDDINGTON (Joseph, Wiscombe and Weinman 1976), applied to that lobe alone. A
// fraction f = g^2 of it is taken to be a spike straight forward -- light that is, to
// every purpose of multiple scattering, not scattered -- and removed from the
// extinction. The rest of the lobe becomes HG at g' = g / (1 + g), which keeps the
// lobe's asymmetry exactly: f + (1 - f) g' = g. Diffuse transport depends on the
// asymmetry and the reduced optical depth sigma (1 - g), and both are preserved, so
// the light INSIDE a cloud is unchanged. It is the standard move in atmospheric
// radiative transfer for exactly this reason.
//
// WHAT IS LOST is the lobe's angular shape: the glow within a few degrees of the sun
// behind a thin edge. `lobeG` and `lobeWeight` carry it to the one estimator that can
// have it back without the variance -- the camera ray's single scattering, where the
// angle to the sun is fixed along the ray. See phaseCamera in PhaseLib.slang.
//
// IT ALSO HALVES THE WORK: the transport's extinction drops by about half at 20
// microns, and a path through a thick cloud takes roughly half the scattering events.
// ===========================================================================
struct TruncatedPhase {
    DropletPhase transport;          // what every scattering event samples and evaluates
    Real extinctionScale = 1;        // the transport's extinction, over the true one
    Real lobeG           = 0;        // the lobe that was removed...
    Real lobeWeight      = 0;        // ...and its weight against the TRUNCATED mixture
};

TruncatedPhase truncateDiffraction(const DropletPhase& fit);

// ---------------------------------------------------------------------------
// Everything the kernel is handed
// ---------------------------------------------------------------------------

struct ConvectionDerived {
    // FALSE WHEN THERE CAN BE NO CLOUD: the generator is off, or the condensation level
    // is at or above the inversion. The second is not an error -- it is dry air under a
    // lid, and a clear sky is the right render of it.
    bool present = false;

    Real base  = 0;   // m, the condensation level
    Real depth = 0;   // m, the tallest a tower may grow above the base

    // Where the cell pattern has travelled by now, in metres. The whole field moves as
    // one thing on the steering wind.
    Real driftX = 0;
    Real driftZ = 0;

    // How many lifetimes have passed. Each cell is at its own phase of the cycle, so
    // this is a clock rather than a state.
    Real age = 0;

    // How far the billows have risen through the cloud by now, in metres. Billows ride
    // the updraft, which is what makes a cumulus boil rather than sit.
    Real rise = 0;

    // Peak extinction per metre AS THE TRANSPORT SEES IT: the parameter, floored at
    // zero, times the truncation's extinctionScale. Every factor of the kernel's
    // density is at most one, so this is also a sound global majorant.
    Real sigma = 0;

    // The exponent on the tower profile: 0.9 at no instability, a rounded mound; 0.45
    // at full instability, steep sides and a narrow top. Below one either way, so the
    // sides rise steeply from the footprint's edge.
    Real shape = 1;

    // The hero, resolved. heroTop is zero when there is none; heroAlone leaves the
    // cell field out. The seed is an offset into billow space, continuous in Hero
    // Variation so that keyframing it morphs the cauliflower rather than cutting.
    bool heroAlone  = false;
    Real heroX      = 0;
    Real heroZ      = 0;
    Real heroRadius = 0;
    Real heroTop    = 0;
    Real heroSeedX  = 0;
    Real heroSeedY  = 0;
    Real heroSeedZ  = 0;

    // The hero's billows over the field's, amount and lobe size alike: its width over
    // a cell's, clamped. A cloud twice a cell across is built from thermals about twice
    // as big; with the field's own lobes a 4 km hero read as a beehive of small ones.
    Real heroBillow = 1;

    TruncatedPhase phase;

    // How the cells are arranged, resolved (build 20). Off for the defaults.
    OrganizationResolved organization;
};

// The steering wind as a velocity, m/s. BEARING IS WHERE IT COMES FROM, as in
// shearWindAt(): a 250 wind comes from west-south-west and blows towards
// east-north-east.
void convectionWind(const ConvectionParams& c, Real& outX, Real& outZ);

// How tall towers may grow, as a fraction of the room under the lid: 35% at no
// instability (humilis, wider than tall) to all of it at full instability (congestus).
Real towerFraction(Real instability);

// The updraft that carries the billows, m/s. Stronger with instability.
Real billowRiseSpeed(Real instability);

void deriveConvection(const FieldParams& field, ConvectionDerived& out);

} // namespace plugin::cloud
