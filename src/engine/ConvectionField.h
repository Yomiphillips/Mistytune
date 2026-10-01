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
// Hero Connection: the towers that tie the hero into the field (build 22)
// ---------------------------------------------------------------------------
//
// ===========================================================================
// WHY THE HERO LOOKED LIKE IT DID NOT BELONG, SEEN FROM ABOVE AND NOT GUESSED.
//
// Rendered top-down, the field's clouds have ragged footprints, since each is a cell's
// rim or centre. The hero was a perfect disc. Nothing in the frame was between its
// 3 km and the field's few hundred metres, and a field cell grew out through its wall.
// So a cloud of another kind had been set down on the field, and the eye reads it that way.
//
// A TOWERING CUMULUS IS A GROUP OF TURRETS, not one dome. Its shoulders are thermals of
// their own, and on the side the wind comes from a FLANKING LINE of smaller towers steps
// down from it into the field, newer ones each farther out. So Connection grows exactly
// that out of the hero's own closed form: more towers of the same family, each a dome
// with the hero's exponent, cauliflower read in the hero's billow frame, lobes sized
// between the field's and the hero's. Their union with the hero is a hard one, as
// thermals meet: in creases.
//
// A SMOOTH JOIN WAS PLANNED AND IS NOT HERE. A smooth union adds cloud wherever two
// surfaces are both near, and the base plane is "near" every tower's formula at every
// point just above it, so it grows a pancake of cloud under the whole group. The
// overlapping footprints already merge the bases, the way a real group's do.
//
// AND THE FIELD YIELDS: its updraft is multiplied down under each tower (the MOAT), so
// no cell grows through the group. The factor is at most one, so the field's bound
// holds untouched; its slope term goes into the kernel's clamp (convMoat).
// ===========================================================================
constexpr int kMaxHeroTurrets = 5;

struct HeroTurret {
    Real x      = 0;   // m, world: the centre on the base
    Real z      = 0;
    Real radius = 0;   // m, the footprint at the base
    Real top    = 0;   // m above the base, never above the hero's
    bool shoulder = false;   // on the hero's own flank, where a pareidolia shape stands
};

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

    // HERO CONNECTION (build 22): the towers that join the hero to the field, and how
    // hard the field's updraft sinks under them. None and zero for Connection 0, which
    // is the hero as it was. See heroGroup() below.
    int32_t    turretCount = 0;
    HeroTurret turret[kMaxHeroTurrets];
    Real       moat = 0;   // 0..1

    // MAMMA (build 23): the deepest a pouch can hang below the base, in metres -- zero is
    // none, and the base is flat -- and one pouch's width. See mammaDepth() below.
    Real mammaDepth = 0;
    Real pouchSize  = 450;

    // PILEUS AND VELUM (build 24), resolved: each one's thickness in metres -- zero is none
    // -- and where it stands, in metres above the base. Zero without a hero.
    Real pileusThick  = 0;
    Real pileusGap    = 0;   // from the hero's smooth crown to the cap's middle, billows in
    Real velumThick   = 0;
    Real velumHeight  = 0;   // the veil's middle, above the base

    TruncatedPhase phase;

    // How the cells are arranged, resolved (build 20). Off for the defaults.
    OrganizationResolved organization;
};

// ---------------------------------------------------------------------------
// Pareidolia's placement: see Pareidolia.h, which fills it
// ---------------------------------------------------------------------------

// Everything the kernel needs to place the map, as plain numbers: this travels to the
// device inside the render request, and the map's texels go separately.
struct ShapeGeometry {
    bool on = false;

    int32_t width  = 0;   // the map's texels
    int32_t height = 0;

    // Texel-edge coordinates of the plane point u = 0, y = 0: the middle of the
    // silhouette's bottom edge, which stands on the condensation level under the hero's
    // centre.
    Real offsetU = 0;
    Real offsetY = 0;

    Real texelMetres = 1;   // one texel's side

    // THE PLANE'S u AXIS, world (x, z), unit: the camera's right when the shape faces it.
    // The normal is it turned 90 degrees towards the camera: (-axisUZ, axisUX).
    Real axisUX = 1;
    Real axisUZ = 0;

    Real round  = 0;   // m: the rims' radius, and half the thickest part's depth
    Real extent = 0;   // m: from the hero's axis to the shape's farthest corner, no billows
    Real decay  = 0;   // 0..1
    Real billow = 1;   // the shape's billows over the hero's, 0..1

    // The silhouette's size once fitted, for the log and the tests.
    Real widthMetres  = 0;
    Real heightMetres = 0;
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

// WHERE THE HERO STANDS AT THE FIELD'S TIME: Hero Position, plus the steering wind's
// drift when Hero Drifts is set. Everything that aims at the hero reads this rather than
// the sliders -- the orbit rig, the shape's facing, the kernel -- so a drifting hero stays
// framed and faces the lens.
void heroPositionNow(const FieldParams& field, Real& outX, Real& outZ);

// The hero's group at `connection` (0..1), around a hero of radius `radius` and height
// `top` at (x, z), with the flanking line pointing towards `windFromDegrees`. Fills
// out.turret and out.turretCount; the hero's own fields must already be set. Towers
// under a metre tall are left out, so Connection 0 is no towers at all.
void heroGroup(Real connection, Real windFromDegrees, ConvectionDerived& out);

// A PAREIDOLIA SHAPE STANDS WHERE THE SHOULDERS WOULD: a turret on the hero's flank is a
// bump in front of, or beside, the picture. So they shrink away as the shape holds and
// return as Decay melts it back into the tower.
//
// AND THE FLANKING LINE TURNS INTO THE PICTURE'S PLANE. Left pointing into the wind, it
// stands between the lens and the face from every orbit that puts the camera upwind. So
// while the shape holds, the line lies along the plane, on whichever side is nearer the
// wind, pushed out past the picture's edge; it frames the face rather than covering it,
// and as Decay melts the shape it swings back into the wind. `g` is the shape as the
// kernel will have it -- its eased decay, its axis, its width -- and a shape that is off
// leaves the group alone.
void fitTurretsToShape(const ShapeGeometry& g, Real windFromDegrees, ConvectionDerived& cd);

// ===========================================================================
// MAMMA'S DEPTH: how far the deepest pouch hangs below the base, in metres.
//
// AT MOST kMammaSag OF A POUCH'S WIDTH. Mamma photographed under anvils hang about as
// far as they are wide at the most, and usually half that; much past it a pouch stops
// reading as a sagging lobe and starts reading as a stalactite. The amount scales it
// linearly, so keyframing Mamma lowers them smoothly from a flat base.
//
// The kernel lowers the layer's slab by this and bounds the pouches by it, so it is the
// definition of the deepest one rather than an estimate.
// ===========================================================================
constexpr Real kMammaSag = Real(0.8);

// A pouch narrower than this is floored: it is a divisor, and a few metres would be grain.
constexpr Real kMinPouchSize = Real(20);

Real mammaDepth(Real amount, Real pouchSize);

// ===========================================================================
// PILEUS AND VELUM'S THICKNESS AT FULL AMOUNT. A pileus is a thin lens -- a few hundred
// metres at its thickest, where the tower below it is kilometres -- and a velum thinner
// still, but kilometres wide. Much thicker and neither reads as an accessory cloud: it
// reads as a second layer.
// ===========================================================================
constexpr Real kPileusMaxThick = Real(260);
constexpr Real kVelumMaxThick  = Real(200);

void deriveConvection(const FieldParams& field, ConvectionDerived& out);

} // namespace plugin::cloud
