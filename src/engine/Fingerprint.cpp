#include "Fingerprint.h"

namespace plugin::sim {

using namespace plugin::cloud;

// ---------------------------------------------------------------------------
// THE TRIPWIRES.
//
// If one of these fires, a member was added to the struct: hash it in the
// matching add() below, add a line for it to TestFingerprint.cpp, and only then
// update the size here. UPDATING THE SIZE ALONE GIVES THE FIELD CACHE A BLIND
// SPOT -- the new parameter changes the sky and the cache never notices, so the
// user edits it and nothing happens.
//
// Sizes are what MSVC and clang both produce for these structs at default
// alignment on 64-bit. They are plain aggregates of 4-byte members with no
// pointers, so the two agree; if a future member breaks that, the assert is the
// right place to find out.
// ---------------------------------------------------------------------------
static_assert(sizeof(PhysicsParams) == 32,
              "PhysicsParams changed -- hash the new member in Fingerprint::add(PhysicsParams)");
static_assert(sizeof(AtmosphereParams) == 32,
              "AtmosphereParams changed -- hash the new member in Fingerprint::add(AtmosphereParams)");
static_assert(sizeof(ShearProfile) == 48,
              "ShearProfile changed -- hash the new member in Fingerprint::add(ShearProfile)");
static_assert(sizeof(IceParams) == 100,
              "IceParams changed -- hash the new member in Fingerprint::add(IceParams)");
static_assert(sizeof(ConvectionParams) == 80,
              "ConvectionParams changed -- hash the new member in Fingerprint::add(ConvectionParams)");
static_assert(sizeof(FieldParams) == 252,
              "FieldParams changed -- hash the new member in Fingerprint::add(FieldParams)");

// THE ONE PAIR THAT MUST NOT BE HASHED, asserted so that a future refactor
// cannot quietly fold camera state into the field. If someone moves a member
// from ViewParams into FieldParams the assert above fires and this one is the
// comment that explains why that might have been deliberate.
// ===========================================================================
// THIS ASSERT HAS A BLIND SPOT, AND IT IS WORTH NAMING BECAUSE THE PROJECT LEANS ON IT.
//
// MEASURED 2026-09-28: adding `bool encodeSrgb` to ViewParams, beside the existing
// `bool agxTonemap`, did NOT change sizeof -- the new member landed in padding the
// struct already carried, and the build stayed green. The field WAS hashed, in
// FieldCache.cpp, but nothing here would have said so if it had not been.
//
// So a sizeof tripwire catches a field that changes the layout and misses one that fits
// a hole. It is necessary and it is not sufficient, and the sufficient version needs
// reflection this language does not have. The mitigation is to treat "I added a member
// and the build stayed green" as meaning nothing, rather than as clearance.
// ===========================================================================
static_assert(sizeof(ViewParams) == 112,
              "ViewParams changed -- check nothing camera-side leaked into the "
              "field hash; see the note in Fingerprint.h");

void Fingerprint::bytes(const void* p, size_t n) {
    const auto* b = static_cast<const unsigned char*>(p);
    for (size_t i = 0; i < n; ++i) {
        m_hash ^= b[i];
        m_hash *= 1099511628211ull;
    }
}

void Fingerprint::add(const PhysicsParams& p) {
    add(static_cast<int32_t>(p.clamp));
    add(p.gravity);
    add(p.scaleHeight);
    add(p.surfacePressure);
    add(p.surfaceTemp);
    add(p.lapseRate);
    add(p.planetRadius);
    add(p.surfaceHumidity);
}

void Fingerprint::add(const AtmosphereParams& a) {
    add(a.sunAzimuth);
    add(a.sunElevation);
    add(a.sunAngularRadius);
    add(a.sunIntensity);
    add(a.turbidity);
    add(a.mieAnisotropy);
    add(a.groundAlbedo);
    add(a.cloudShadowsInMedium);
}

void Fingerprint::add(const ShearProfile& s) {
    // EVERY KNOT, and in order. The curve IS the streak shape, so two profiles
    // holding the same numbers in a different order describe different skies.
    for (int i = 0; i < kShearKnots; ++i) {
        add(s.speed[i]);
        add(s.bearing[i]);
    }
}

void Fingerprint::add(const IceParams& i) {
    add(i.enabled);
    add(i.cellAltitude);
    add(i.cellDensity);
    add(i.cellSize);
    add(i.cellStrength);
    add(static_cast<int32_t>(i.habit));
    add(i.fallSpeedScale);
    add(i.shear);
    add(i.sublimationRate);
    add(i.streakLength);
    add(i.opticalDepth);
    add(i.detailAmount);
    add(i.detailScale);
    add(i.detailOctaves);
}

void Fingerprint::add(const ConvectionParams& c) {
    add(c.enabled);
    add(c.cellSize);
    add(c.polarity);
    add(c.coverage);
    add(c.instability);
    add(c.inversionHeight);
    add(c.density);
    add(c.billowAmount);
    add(c.billowScale);
    add(c.billowOctaves);
    add(c.windSpeed);
    add(c.windBearing);
    add(c.lifetime);
    add(c.dropletDiameter);
    add(c.heroMode);
    add(c.heroX);
    add(c.heroZ);
    add(c.heroWidth);
    add(c.heroHeight);
    add(c.heroVariation);
}

void Fingerprint::add(const FieldParams& f) {
    add(f.physics);
    add(f.atmosphere);
    add(f.ice);
    add(f.convection);

    // TIME IS PART OF THE FIELD, not of the view. The generating cells advect,
    // so a new frame genuinely is a new medium -- which is also why a still
    // frame re-rendered at the same time hits the cache and an animation does
    // not, and that is the correct behaviour rather than a cache miss to fix.
    add(f.timeSeconds);

    add(static_cast<int64_t>(f.seed));
}

} // namespace plugin::sim
