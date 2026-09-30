#include "ConvectionField.h"

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
        out.heroX      = c.heroX;
        out.heroZ      = c.heroZ;
        out.heroAlone  = c.heroMode == 2;

        const Real cell = c.cellSize > Real(1) ? c.cellSize : Real(1);
        out.heroBillow = clampReal(width / cell, Real(0.75), Real(3));

        // Far enough per unit that a unit of variation is a different cauliflower, and
        // along three unrelated directions so no two values share a lobe pattern.
        out.heroSeedX = c.heroVariation * Real(1731.0);
        out.heroSeedY = c.heroVariation * Real(613.0);
        out.heroSeedZ = c.heroVariation * Real(2477.0);
        if (!(out.heroTop > Real(1))) out.heroTop = Real(0);
    }

    // A HERO ALONE MAKES THE FIELD'S OWN DEPTH IRRELEVANT, but it is kept: the billows'
    // top-to-side ramp and the tower exponent still read it.
    out.present = out.heroAlone ? out.heroTop > Real(1)
                                : (out.depth > Real(1) || out.heroTop > Real(1));
}

} // namespace plugin::cloud
