#include "ConvectionField.h"

#include <algorithm>
#include <cmath>

namespace plugin::cloud {

namespace {

constexpr Real kDegToRad = Real(0.01745329252);

// Magnus coefficients over water, Alduchov and Eskridge (1996). `kMagnusC` is in
// degrees Celsius, which is why dewPoint() converts on the way in and out.
constexpr Real kMagnusB = Real(17.625);
constexpr Real kMagnusC = Real(243.04);

constexpr Real kZeroCelsius = Real(273.15);

// Specific heat of dry air at constant pressure, J/(kg K). g/cp is the dry adiabatic
// lapse rate: 9.77 K/km on Earth.
constexpr Real kCpDryAir = Real(1004.0);

// The dew point's own lapse rate, PER UNIT GRAVITY. It is about 1.8 K/km on Earth, and
// like the dry adiabat it is a hydrostatic quantity, so it scales with g. Stored per
// unit g so that condensationLevel() can scale both rates by the same gravity -- which
// is what keeps the famous 125 m per kelvin exact on Earth and honest elsewhere.
constexpr Real kDewLapsePerGravity = Real(1.8e-3) / Real(9.80665);

// kMaxG in PhaseLib.slang. See the note there: 0.999 bounds the HG lobe so the sampler
// and the pdf cannot be handed different numbers.
constexpr Real kMaxG = Real(0.999);

Real clampReal(Real v, Real lo, Real hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

} // namespace

Real dewPoint(Real tempK, Real relHumidity) {
    const Real rh = clampReal(relHumidity, Real(0.01), Real(1));
    const Real tc = tempK - kZeroCelsius;

    const Real gamma = std::log(rh) + kMagnusB * tc / (kMagnusC + tc);
    return kMagnusC * gamma / (kMagnusB - gamma) + kZeroCelsius;
}

Real condensationLevel(const PhysicsParams& physics) {
    // THE FLOOR MATCHES THE PARAMETER'S VALID MINIMUM. A zero gravity has no adiabat --
    // a lifted parcel never cools -- and the division below would say the base is at
    // infinity, which is right in spirit and a NaN in practice.
    const Real g = physics.gravity > Real(0.01) ? physics.gravity : Real(0.01);

    const Real depression = physics.surfaceTemp - dewPoint(physics.surfaceTemp,
                                                           physics.surfaceHumidity);

    const Real metresPerKelvin = Real(1) / (g * (Real(1) / kCpDryAir - kDewLapsePerGravity));

    // SATURATED AIR AT THE SURFACE IS FOG, and its condensation level is the ground.
    // Never negative: a humidity above one is clamped, but a rounding error in the dew
    // point should not put a cloud base underground.
    const Real level = depression * metresPerKelvin;
    return level > Real(0) ? level : Real(0);
}

DropletPhase dropletPhase(Real diameterMicrons) {
    // TRANSCRIBED FROM phaseFromDropletDiameter, term for term and in the same order,
    // so the two round the same way. slang.bounce compares them.
    const Real d = clampReal(diameterMicrons, Real(5), Real(50));

    DropletPhase p;
    p.hgG         = clampReal(std::exp(Real(-0.0990567) / (d - Real(1.67154))), -kMaxG, kMaxG);
    p.draineG     = clampReal(std::exp(-(Real(2.20679) / (d + Real(3.91029))) - Real(0.428934)),
                              -kMaxG, kMaxG);
    p.draineAlpha = std::exp(Real(3.62489) - Real(8.29288) / (d + Real(5.52825)));
    p.draineW     = std::exp(-(Real(0.599085) / (d - Real(0.641583))) - Real(0.665888));
    return p;
}

TruncatedPhase truncateDiffraction(const DropletPhase& fit) {
    const Real g = fit.hgG;
    const Real w = fit.draineW;

    // f = g^2 is delta-Eddington's choice for an HG lobe, and it is the one that keeps
    // the lobe's first moment: f + (1 - f) g/(1 + g) = g.
    const Real f       = g * g;
    const Real removed = (Real(1) - w) * f;     // of ALL the scattering, not of the lobe
    const Real scale   = Real(1) - removed;

    TruncatedPhase t;
    t.extinctionScale = scale;

    // The broadened lobe, and the Draine lobe renormalised against what is left.
    t.transport.hgG         = g / (Real(1) + g);
    t.transport.draineG     = fit.draineG;
    t.transport.draineAlpha = fit.draineAlpha;
    t.transport.draineW     = w / scale;

    // What single scattering adds back: the removed fraction, per unit of the
    // truncated extinction, in the lobe's true shape.
    t.lobeG      = g;
    t.lobeWeight = removed / scale;
    return t;
}

void convectionWind(const ConvectionParams& c, Real& outX, Real& outZ) {
    // Where it comes FROM, so the velocity points the other way -- the same convention
    // shearWindAt() documents, and the same sign.
    const Real b = c.windBearing * kDegToRad;
    outX = -c.windSpeed * std::sin(b);
    outZ = -c.windSpeed * std::cos(b);
}

Real towerFraction(Real instability) {
    return Real(0.35) + Real(0.65) * clampReal(instability, Real(0), Real(1));
}

Real billowRiseSpeed(Real instability) {
    // ONE TO THREE METRES A SECOND, which is a fair-weather thermal's updraft. The
    // billows are not the air -- they are the pattern the air is carrying -- so this
    // is the speed at which a lobe on the top climbs, not a transport velocity.
    return Real(1) + Real(2) * clampReal(instability, Real(0), Real(1));
}

void heroPositionNow(const FieldParams& field, Real& outX, Real& outZ) {
    const ConvectionParams& c = field.convection;
    outX = c.heroX;
    outZ = c.heroZ;
    if (!c.heroDrift) return;

    // THE FIELD'S OWN DRIFT, the same product deriveConvection forms, so the hero and the
    // cell pattern cannot part company by a rounding.
    Real wx = Real(0), wz = Real(0);
    convectionWind(c, wx, wz);
    outX = c.heroX + wx * field.timeSeconds;
    outZ = c.heroZ + wz * field.timeSeconds;
}

namespace {

// ===========================================================================
// THE GROUP'S LAYOUT, in the hero's own units. `along` and `across` are in hero radii
// from its centre: along the way the wind comes FROM, and 90 degrees clockwise of it
// seen from above. Radius and height are fractions of the hero's. `start` is where on
// the Connection slider each tower begins to grow, and it grows over kTurretGrowth.
//
// THE SHOULDERS sit inside the hero's footprint, off-centre, and stand taller than the
// hero's own wall there: at 0.84 of its radius the dome is half its height, and a
// shoulder of 0.8 pokes a third of the hero's height above it. Two of them, on either
// side of the line, turn one round dome into a tower of turrets with a ragged
// footprint -- which is the first thing the top-down render showed was missing.
//
// THE FLANKING LINE runs into the wind, each tower overlapping the last at its base and
// shorter: 72%, 52% and 36% of the hero, the last about a field tower's height, so the
// line ends where the field begins. Each is nudged off the line, alternately, so it is
// not a row of beads. The first overlaps the hero's footprint by a third of its own
// radius, which is where the two bases merge.
//
// ONE LAYOUT, NOT A RANDOM ONE. Hero Variation picks the cauliflower, and the user
// turns Wind From to swing the line round; a layout that jumped with either would be
// a control that moved everything.
// ===========================================================================
struct TurretSpec {
    Real along, across, radius, top, start;
    bool shoulder;
};

constexpr TurretSpec kTurretSpecs[kMaxHeroTurrets] = {
    { Real(-0.30), Real( 0.80), Real(0.45), Real(0.80), Real(0.00), true  },
    { Real( 0.35), Real(-0.78), Real(0.40), Real(0.68), Real(0.15), true  },
    { Real( 1.25), Real( 0.12), Real(0.55), Real(0.72), Real(0.05), false },
    { Real( 2.05), Real(-0.10), Real(0.42), Real(0.52), Real(0.30), false },
    { Real( 2.70), Real( 0.10), Real(0.32), Real(0.36), Real(0.55), false },
};

constexpr Real kTurretGrowth = Real(0.45);

// A tower grows from 60% of its footprint, low, to all of it, full height: cumulus
// spreads before it climbs, and a footprint grown from nothing would be a needle.
constexpr Real kTurretSeedWidth = Real(0.6);

// THE MOAT REACHES FULL STRENGTH HALFWAY UP THE SLIDER, ahead of the towers, so a field
// cell is gone from under the group before the group is big enough to be pierced by it.
constexpr Real kMoatRate = Real(2);

// Drops the towers under a metre tall and closes the gaps, keeping the order.
void compactTurrets(ConvectionDerived& out) {
    int32_t n = 0;
    for (int32_t k = 0; k < out.turretCount; ++k) {
        if (out.turret[k].top > Real(1) && out.turret[k].radius > Real(1)) {
            out.turret[n++] = out.turret[k];
        }
    }
    for (int32_t k = n; k < kMaxHeroTurrets; ++k) out.turret[k] = HeroTurret{};
    out.turretCount = n;
}

} // namespace

void heroGroup(Real connection, Real windFromDegrees, ConvectionDerived& out) {
    out.turretCount = 0;
    out.moat = Real(0);
    for (HeroTurret& t : out.turret) t = HeroTurret{};

    const Real k = clampReal(connection == connection ? connection : Real(0), Real(0), Real(1));
    if (!(k > Real(0)) || !(out.heroTop > Real(1))) return;

    // Towards where the wind comes from, and 90 degrees clockwise of that. A bearing
    // keyframed round many turns is reduced before the trig.
    double b = static_cast<double>(windFromDegrees);
    if (!(b == b) || std::fabs(b) > 1e9) b = 0.0;
    b = std::fmod(b, 360.0) * static_cast<double>(kDegToRad);
    const Real ux = static_cast<Real>(std::sin(b));
    const Real uz = static_cast<Real>(std::cos(b));
    const Real vx = uz;
    const Real vz = -ux;

    const Real R = out.heroRadius;
    for (const TurretSpec& s : kTurretSpecs) {
        const Real grow = clampReal((k - s.start) / kTurretGrowth, Real(0), Real(1));
        HeroTurret& t = out.turret[out.turretCount++];
        t.x        = out.heroX + R * (s.along * ux + s.across * vx);
        t.z        = out.heroZ + R * (s.along * uz + s.across * vz);
        t.radius   = R * s.radius * (kTurretSeedWidth + (Real(1) - kTurretSeedWidth) * grow);
        t.top      = out.heroTop * s.top * grow;
        t.shoulder = s.shoulder;
    }
    compactTurrets(out);
    out.moat = clampReal(k * kMoatRate, Real(0), Real(1));
}

void fitTurretsToShape(const ShapeGeometry& g, Real windFromDegrees, ConvectionDerived& cd) {
    if (!g.on || cd.turretCount <= 0) return;
    const Real keep = clampReal(g.decay == g.decay ? g.decay : Real(0), Real(0), Real(1));
    const Real hold = Real(1) - keep;

    // Into the wind, as heroGroup laid the line...
    double b = static_cast<double>(windFromDegrees);
    if (!(b == b) || std::fabs(b) > 1e9) b = 0.0;
    b = std::fmod(b, 360.0) * static_cast<double>(kDegToRad);
    const double ux = std::sin(b), uz = std::cos(b);

    // ...and along the plane, on the side nearer the wind. A plane square to the wind
    // takes its own +u.
    double ax = static_cast<double>(g.axisUX), az = static_cast<double>(g.axisUZ);
    if (ax * ux + az * uz < 0.0) { ax = -ax; az = -az; }

    // THE TURN FROM ONE TO THE OTHER, made as far as the shape still holds -- so Decay swings
    // the line round continuously rather than jumping it at the end.
    const double turn = std::atan2(ux * az - uz * ax, ux * ax + uz * az) * static_cast<double>(hold);
    const double cs = std::cos(turn), sn = std::sin(turn);

    // PAST THE PICTURE'S EDGE: the first tower's footprint starts 0.7 of the hero's radius
    // out, and a picture as wide as Hero Width reaches all of it.
    const double push = static_cast<double>(hold) *
                        std::max(0.0, 0.5 * static_cast<double>(g.widthMetres) -
                                      0.7 * static_cast<double>(cd.heroRadius));

    for (int32_t k = 0; k < cd.turretCount; ++k) {
        HeroTurret& t = cd.turret[k];
        if (t.shoulder) {
            t.top *= keep;
            continue;
        }
        const double dx = static_cast<double>(t.x - cd.heroX);
        const double dz = static_cast<double>(t.z - cd.heroZ);
        t.x = cd.heroX + static_cast<Real>(dx * cs - dz * sn + push * ax);
        t.z = cd.heroZ + static_cast<Real>(dx * sn + dz * cs + push * az);
    }
    compactTurrets(cd);
}

Real mammaDepth(Real amount, Real pouchSize) {
    const Real a = clampReal(amount == amount ? amount : Real(0), Real(0), Real(1));
    const Real size = pouchSize == pouchSize && pouchSize > kMinPouchSize ? pouchSize : kMinPouchSize;
    return a > Real(0) ? a * kMammaSag * size : Real(0);
}

void deriveConvection(const FieldParams& field, ConvectionDerived& out) {
    const ConvectionParams& c = field.convection;

    out = ConvectionDerived{};

    // Always filled, so a caller that reads them for an absent layer gets numbers that
    // mean something rather than zeros that would divide.
    out.phase = truncateDiffraction(dropletPhase(c.dropletDiameter));
    out.sigma = (c.density > Real(0) ? c.density : Real(0)) * out.phase.extinctionScale;
    out.organization = resolveOrganization(c.organization, true);

    if (!c.enabled) return;

    out.base = condensationLevel(field.physics);

    // ===================================================================
    // DRY AIR UNDER A LID HAS NO CUMULUS, and that falls out of this line rather than
    // being a rule anyone wrote. When the condensation level is at or above the
    // inversion, a parcel stops rising before it saturates -- so the sky is clear. The
    // user sees Surface Humidity switch the clouds off below a threshold, which is the
    // real behaviour of a boundary layer on a dry afternoon.
    // ===================================================================
    const Real room = c.inversionHeight - out.base;
    if (!(room > Real(1)) || !(out.sigma > Real(0))) return;

    out.depth = room * towerFraction(c.instability);
    out.shape = Real(0.9) - Real(0.45) * clampReal(c.instability, Real(0), Real(1));

    Real wx = Real(0), wz = Real(0);
    convectionWind(c, wx, wz);
    out.driftX = wx * field.timeSeconds;
    out.driftZ = wz * field.timeSeconds;

    // A LIFETIME BELOW A SECOND IS FLOORED, not rejected. It is a divisor, and at zero
    // every cell would be at every phase at once.
    const Real life = c.lifetime > Real(1) ? c.lifetime : Real(1);
    out.age  = field.timeSeconds / life;
    out.rise = billowRiseSpeed(c.instability) * field.timeSeconds;

    // THE HERO. Its height is a fraction of the WHOLE room under the lid, where the
    // field's towers are capped at towerFraction of it: a hero is the one cloud in the
    // shot that did get all the way up. A width under a metre is floored rather than
    // allowed to become a divisor of zero.
    if (c.heroMode == 1 || c.heroMode == 2) {
        const Real frac = clampReal(c.heroHeight, Real(0), Real(1));
        const Real width = c.heroWidth > Real(2) ? c.heroWidth : Real(2);
        out.heroTop    = room * frac;
        out.heroRadius = width * Real(0.5);
        heroPositionNow(field, out.heroX, out.heroZ);
        out.heroAlone  = c.heroMode == 2;

        const Real cell = c.cellSize > Real(1) ? c.cellSize : Real(1);
        out.heroBillow = clampReal(width / cell, Real(0.75), Real(3));

        // Far enough per unit that a unit of variation is a different cauliflower, and
        // along three unrelated directions so no two values share a lobe pattern.
        out.heroSeedX = c.heroVariation * Real(1731.0);
        out.heroSeedY = c.heroVariation * Real(613.0);
        out.heroSeedZ = c.heroVariation * Real(2477.0);
        if (!(out.heroTop > Real(1))) out.heroTop = Real(0);

        if (out.heroTop > Real(0)) heroGroup(c.heroConnection, c.windBearing, out);

        // THE CAP AND THE VEIL. THE GAP IS FROM THE CROWN'S HIGHEST BILLOWS, which reach the
        // billow amount times the hero's factor over the smooth crown: SEEN, a gap measured
        // from the smooth crown put the cap inside the cauliflower and only its rim showed.
        // It may be negative -- a cap the turrets push into -- but the cap's middle stays
        // above the base. A veil stands somewhere on the tower, never under the base or over
        // the crown.
        if (out.heroTop > Real(0)) {
            const auto amount = [](Real v) { return clampReal(v == v ? v : Real(0), Real(0), Real(1)); };
            const Real billows = (c.billowAmount > Real(0) ? c.billowAmount : Real(0)) * out.heroBillow;
            out.pileusThick = amount(c.pileus) * kPileusMaxThick;
            out.pileusGap   = billows + clampReal(c.pileusGap == c.pileusGap ? c.pileusGap : Real(0),
                                                  -(out.heroTop + billows), Real(10000));
            out.velumThick  = amount(c.velum) * kVelumMaxThick;
            out.velumHeight = amount(c.velumHeight) * out.heroTop;
        }
    }

    // MAMMA, under whatever the layer has overhead. Absent cloud, absent pouches: the
    // kernel hangs them only where the base above them is inside the cloud.
    out.pouchSize  = c.pouchSize == c.pouchSize && c.pouchSize > kMinPouchSize ? c.pouchSize
                                                                               : kMinPouchSize;
    out.mammaDepth = mammaDepth(c.mamma, c.pouchSize);

    // A HERO ALONE MAKES THE FIELD'S OWN DEPTH IRRELEVANT, but it is kept: the billows'
    // top-to-side ramp and the tower exponent still read it.
    out.present = out.heroAlone ? out.heroTop > Real(1)
                                : (out.depth > Real(1) || out.heroTop > Real(1));
}

} // namespace plugin::cloud
