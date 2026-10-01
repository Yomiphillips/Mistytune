// The host's half of the convection generator: the condensation level, the wind, the
// clock, and the droplets' phase parameters.
//
// ===========================================================================
// THE CONDENSATION LEVEL IS THE ONE TO WATCH, because it is the flat base -- the thing
// the spec's craft checklist says makes a cumulus read as photographed -- and because it
// is the Physics tab's hand on this cloud. If it is wrong, the cloud sits at a plausible
// height for the wrong reason, and nothing in a render says so.
//
// So these check it against the textbook in three independent ways: a dew point against
// a tabulated value, the 125-metres-per-kelvin rule on Earth, and its scaling with
// gravity, which is the coupling that makes an alien sky follow from its constants.
//
// WHAT IS NOT HERE: whether the kernel's density honours the base, the lid and its own
// bound. That is a claim about Slang code, checked where the kernel runs -- see
// slang.convection.
// ===========================================================================

#include "TestFramework.h"

#include "ConvectionField.h"

#include <cmath>

using namespace plugin::cloud;

namespace {

FieldParams convectiveField() {
    FieldParams f;
    f.convection.enabled = true;
    return f;
}

} // namespace

// Magnus, checked against a value anyone can look up: 20 C at 50% has a dew point of
// 9.3 C. A wrong coefficient or a Kelvin/Celsius slip moves this by degrees.
PL_TEST(ADewPointMatchesTheTable) {
    const Real td = dewPoint(Real(293.15), Real(0.5)) - Real(273.15);
    PL_CHECK_NEAR(td, 9.26, 0.1);
}

// Saturated air is at its own dew point.
PL_TEST(SaturatedAirIsAtItsDewPoint) {
    PL_CHECK_NEAR(dewPoint(Real(288.15), Real(1.0)), 288.15, 1e-3);
}

// THE RULE OF THUMB EVERY FORECASTER USES: about 125 m of base per kelvin of dew-point
// depression. The defaults -- 15 C at 70% -- put the base near 680 m, which is where a
// fair-weather cumulus base actually sits on a mild humid day.
PL_TEST(EarthsBaseIsAHundredAndTwentyFiveMetresPerKelvin) {
    PhysicsParams p;
    const Real depression = p.surfaceTemp - dewPoint(p.surfaceTemp, p.surfaceHumidity);
    const Real level = condensationLevel(p);

    PL_CHECK_NEAR(level / depression, 125.5, 1.0);
    PL_CHECK(level > Real(600) && level < Real(760));
}

PL_TEST(SaturatedAirHasItsBaseOnTheGround) {
    PhysicsParams p;
    p.surfaceHumidity = Real(1);
    PL_CHECK_NEAR(condensationLevel(p), 0.0, 0.5);
}

// Monotone, and never negative, across the whole valid range of the slider.
PL_TEST(DrierAirLiftsTheBase) {
    PhysicsParams p;
    Real previous = Real(-1);
    for (int i = 100; i >= 0; --i) {
        p.surfaceHumidity = Real(i) / Real(100);
        const Real level = condensationLevel(p);
        PL_CHECK(std::isfinite(level));
        PL_CHECK(level >= Real(0));
        PL_CHECK(level >= previous);
        previous = level;
    }
}

// BOTH LAPSE RATES ARE HYDROSTATIC, so the base scales as 1/g. A third of the gravity,
// three times the height: the tall-cloud world the Low Gravity preset is for.
PL_TEST(TheBaseScalesInverselyWithGravity) {
    PhysicsParams earth;
    PhysicsParams light = earth;
    light.gravity = earth.gravity / Real(3);

    PL_CHECK_NEAR(condensationLevel(light) / condensationLevel(earth), 3.0, 1e-3);
}

PL_TEST(AZeroGravityIsFlooredRatherThanDivided) {
    PhysicsParams p;
    p.gravity = Real(0);
    PL_CHECK(std::isfinite(condensationLevel(p)));
}

// ---------------------------------------------------------------------------
// What the kernel is handed
// ---------------------------------------------------------------------------

PL_TEST(ALayerThatIsOffIsAbsent) {
    FieldParams f;
    f.convection.enabled = false;
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK(!d.present);
}

PL_TEST(TheDefaultsMakeCumulus) {
    ConvectionDerived d;
    deriveConvection(convectiveField(), d);
    PL_CHECK(d.present);
    PL_CHECK(d.depth > Real(100));
}

// ===========================================================================
// DRY AIR UNDER A LID HAS NO CUMULUS. At 20% humidity the air must rise about 2.5 km to
// saturate, and the default lid is at 2.4 km -- so a parcel stops before it makes cloud.
// Nobody wrote that rule; it is the arithmetic. This pins that it stays so.
// ===========================================================================
PL_TEST(DryAirUnderALidHasNoCumulus) {
    FieldParams f = convectiveField();
    f.physics.surfaceHumidity = Real(0.2);
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK(!d.present);
}

// The lid is a lid, at every instability the slider can be driven to by an expression.
PL_TEST(TowersNeverRiseThroughTheInversion) {
    FieldParams f = convectiveField();
    for (int i = -10; i <= 20; ++i) {
        f.convection.instability = Real(i) / Real(10);
        ConvectionDerived d;
        deriveConvection(f, d);
        PL_CHECK(d.present);
        PL_CHECK(d.base + d.depth <= f.convection.inversionHeight + Real(1e-3));
        PL_CHECK(d.shape > Real(0) && d.shape < Real(1));
    }
}

PL_TEST(MoreInstabilityMeansTallerSteeperTowers) {
    FieldParams calm = convectiveField();
    FieldParams wild = calm;
    calm.convection.instability = Real(0.1);
    wild.convection.instability = Real(0.9);

    ConvectionDerived a, b;
    deriveConvection(calm, a);
    deriveConvection(wild, b);

    PL_CHECK(b.depth > a.depth);
    PL_CHECK(b.shape < a.shape);
}

// A BEARING IS WHERE THE WIND COMES FROM. A westerly (270) blows towards +X; reading it
// as "towards" would send every cloud the wrong way and look like a sign error in the
// drift rather than the convention it is. Same convention as the shear profile.
PL_TEST(TheCellsDriftDownwind) {
    FieldParams f = convectiveField();
    f.convection.windSpeed   = Real(10);
    f.convection.windBearing = Real(270);
    f.timeSeconds = Real(60);

    ConvectionDerived d;
    deriveConvection(f, d);

    PL_CHECK_NEAR(d.driftX, 600.0, 1e-2);
    PL_CHECK_NEAR(d.driftZ, 0.0, 1e-2);
}

PL_TEST(TheClockCountsLifetimes) {
    FieldParams f = convectiveField();
    f.convection.lifetime = Real(1200);
    f.timeSeconds = Real(600);

    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.age, 0.5, 1e-6);
    PL_CHECK(d.rise > Real(0));

    // A zero lifetime is a divisor, and is floored rather than allowed to divide.
    f.convection.lifetime = Real(0);
    deriveConvection(f, d);
    PL_CHECK(std::isfinite(d.age));
}

// ---------------------------------------------------------------------------
// The droplets
// ---------------------------------------------------------------------------

// The fit is valid for 5 to 50 microns and is clamped there, exactly as the kernel's
// copy is. Outside it the hgG term divides by a negative and the lobe inverts.
PL_TEST(TheDropletFitIsClampedToItsValidRange) {
    const DropletPhase tiny = dropletPhase(Real(1));
    const DropletPhase low  = dropletPhase(Real(5));
    PL_CHECK_EQ(tiny.hgG == low.hgG, 1);
    PL_CHECK_EQ(tiny.draineW == low.draineW, 1);

    const DropletPhase huge = dropletPhase(Real(500));
    const DropletPhase high = dropletPhase(Real(50));
    PL_CHECK_EQ(huge.hgG == high.hgG, 1);
    PL_CHECK_EQ(huge.draineAlpha == high.draineAlpha, 1);
}

// The same bound the kernel's sampler clamps to, so the pdf and the sampler are never
// handed different numbers. See kMaxG in PhaseLib.slang.
PL_TEST(TheForwardLobeStaysBelowOne) {
    for (int d = 5; d <= 50; ++d) {
        const DropletPhase p = dropletPhase(Real(d));
        PL_CHECK(p.hgG > Real(0.9) && p.hgG <= Real(0.999));
        PL_CHECK(p.draineW > Real(0) && p.draineW < Real(1));
    }
}

// Bigger droplets scatter more sharply forward. That is the whole physical content of
// the diameter control, so it is worth one line.
PL_TEST(BiggerDropletsAreMoreForward) {
    PL_CHECK(dropletPhase(Real(40)).hgG > dropletPhase(Real(8)).hgG);
}

// ---------------------------------------------------------------------------
// The hero
// ---------------------------------------------------------------------------

// OFF BY DEFAULT: the effect's default sky is the field, and a zeroed request has no
// hero in it.
PL_TEST(ThereIsNoHeroByDefault) {
    ConvectionDerived d;
    deriveConvection(convectiveField(), d);
    PL_CHECK_NEAR(d.heroTop, 0.0, 0.0);
    PL_CHECK(!d.heroAlone);
}

// HEIGHT IS A FRACTION OF THE WHOLE ROOM UNDER THE LID, and one reaches the lid -- where
// the field's own towers stop at towerFraction of it. It never passes the inversion.
PL_TEST(AFullHeightHeroReachesTheLidAndNoFurther) {
    FieldParams f = convectiveField();
    f.convection.heroMode   = 1;
    f.convection.heroHeight = Real(1);
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.base + d.heroTop, f.convection.inversionHeight, 1e-2);
    PL_CHECK(d.heroTop >= d.depth);

    f.convection.heroHeight = Real(7);   // an expression past the slider
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.base + d.heroTop, f.convection.inversionHeight, 1e-2);
}

// ALONE IS STILL PRESENT when the field alone would not be -- a hero on a day too calm
// for the field's towers is still a cloud -- and it is absent when the air is too dry
// for any cloud at all, since the hero stands on the same condensation level.
PL_TEST(AHeroAloneFollowsTheAirNotTheField) {
    FieldParams f = convectiveField();
    f.convection.heroMode = 2;
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK(d.present);
    PL_CHECK(d.heroAlone);

    f.physics.surfaceHumidity = Real(0.2);
    deriveConvection(f, d);
    PL_CHECK(!d.present);
}

// THE HERO'S BILLOWS SCALE WITH ITS WIDTH over a cell's, inside the clamp.
PL_TEST(ABiggerHeroGetsBiggerBillows) {
    FieldParams f = convectiveField();
    f.convection.heroMode  = 1;
    f.convection.cellSize  = Real(2000);
    f.convection.heroWidth = Real(4000);
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.heroBillow, 2.0, 1e-5);

    f.convection.heroWidth = Real(100000);
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.heroBillow, 3.0, 1e-5);

    f.convection.heroWidth = Real(10);
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.heroBillow, 0.75, 1e-5);
}

// POSITION AND VARIATION PASS THROUGH; a mode outside 0..2 from a bad request is off.
PL_TEST(TheHeroIsWhereItIsPut) {
    FieldParams f = convectiveField();
    f.convection.heroMode = 1;
    f.convection.heroX = Real(-1500);
    f.convection.heroZ = Real(3200);
    f.convection.heroVariation = Real(2);
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.heroX, -1500.0, 1e-3);
    PL_CHECK_NEAR(d.heroZ, 3200.0, 1e-3);
    PL_CHECK(d.heroSeedX != Real(0));

    f.convection.heroMode = 9;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.heroTop, 0.0, 0.0);
}

// ---------------------------------------------------------------------------
// Hero Connection (build 22)
// ---------------------------------------------------------------------------
//
// THE LAYOUT IS THE HOST'S, so its promises are checked here: nothing at 0, every tower
// under and inside the hero (which is what keeps the kernel's ceiling and slab the hero's),
// the flanking line into the wind and stepping down, and a group that moves with a
// drifting hero. Whether the kernel's density and bound honour it is slang.convection's.

namespace {

FieldParams connectedField(Real connection) {
    FieldParams f = convectiveField();
    f.convection.heroMode       = 1;
    f.convection.heroX          = Real(700);
    f.convection.heroZ          = Real(-400);
    f.convection.heroConnection = connection;
    return f;
}

// Along the way the wind comes from, from the hero's centre.
double upwindOf(const ConvectionDerived& d, const HeroTurret& t, Real windFrom) {
    const double b = static_cast<double>(windFrom) * 0.017453292519943295;
    return (t.x - d.heroX) * std::sin(b) + (t.z - d.heroZ) * std::cos(b);
}

} // namespace

// CONNECTION 0 IS THE LONE HERO, exactly: no tower and no moat. So is a NaN.
PL_TEST(ConnectionZeroIsTheLoneHero) {
    ConvectionDerived d;
    deriveConvection(connectedField(Real(0)), d);
    PL_CHECK(d.heroTop > Real(1));
    PL_CHECK(d.turretCount == 0);
    PL_CHECK_NEAR(d.moat, 0.0, 0.0);

    deriveConvection(connectedField(std::nanf("")), d);
    PL_CHECK(d.turretCount == 0);
    PL_CHECK_NEAR(d.moat, 0.0, 0.0);
}

// NO HERO, NO GROUP, whatever the slider says: the moat is round the hero's footprint.
PL_TEST(NoHeroMeansNoGroup) {
    FieldParams f = connectedField(Real(1));
    f.convection.heroMode = 0;
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK(d.turretCount == 0);
    PL_CHECK_NEAR(d.moat, 0.0, 0.0);
}

// EVERY TOWER UNDER AND INSIDE THE HERO. A turret taller than the hero, or wider, would
// reach past the ceiling the kernel cuts the density at.
PL_TEST(EveryTurretIsSmallerThanTheHero) {
    for (Real k : { Real(0.05), Real(0.3), Real(0.6), Real(1), Real(5) }) {
        for (Real width : { Real(300), Real(3000), Real(12000) }) {
            FieldParams f = connectedField(k);
            f.convection.heroWidth = width;
            ConvectionDerived d;
            deriveConvection(f, d);
            PL_CHECK(d.turretCount >= 1 && d.turretCount <= kMaxHeroTurrets);
            for (int i = 0; i < d.turretCount; ++i) {
                PL_CHECK(d.turret[i].top > Real(1));
                PL_CHECK(d.turret[i].top <= d.heroTop);
                PL_CHECK(d.turret[i].radius > Real(0));
                PL_CHECK(d.turret[i].radius <= d.heroRadius);
            }
        }
    }
}

// THE GROUP GROWS WITH THE SLIDER, never shrinks: every tower's height is non-decreasing,
// and the moat is full by halfway.
PL_TEST(TheGroupGrowsWithTheSlider) {
    double lastTotal = -1.0;
    int lastCount = 0;
    for (int s = 0; s <= 20; ++s) {
        ConvectionDerived d;
        deriveConvection(connectedField(Real(s) / Real(20)), d);
        double total = 0.0;
        for (int i = 0; i < d.turretCount; ++i) total += d.turret[i].top;
        PL_CHECK(total >= lastTotal);
        PL_CHECK(d.turretCount >= lastCount);
        lastTotal = total;
        lastCount = d.turretCount;
        if (s >= 10) PL_CHECK_NEAR(d.moat, 1.0, 1e-6);
    }
    PL_CHECK(lastCount == kMaxHeroTurrets);
}

// THE FLANKING LINE RUNS INTO THE WIND and steps down away from the hero; the shoulders
// stand on the hero's own footprint. Checked at three winds, one keyframed round ten turns.
PL_TEST(TheFlankingLineStepsDownIntoTheWind) {
    for (Real wind : { Real(250), Real(90), Real(3600 + 10) }) {
        FieldParams f = connectedField(Real(1));
        f.convection.windBearing = wind;
        ConvectionDerived d;
        deriveConvection(f, d);
        PL_CHECK(d.turretCount == kMaxHeroTurrets);

        double lastAlong = 0.0, lastTop = static_cast<double>(d.heroTop);
        int line = 0;
        for (int i = 0; i < d.turretCount; ++i) {
            const HeroTurret& t = d.turret[i];
            const double along = upwindOf(d, t, wind);
            if (t.shoulder) {
                const double r = std::hypot(t.x - d.heroX, t.z - d.heroZ);
                PL_CHECK(r < d.heroRadius);
                continue;
            }
            ++line;
            PL_CHECK(along > lastAlong);   // farther into the wind...
            PL_CHECK(t.top < lastTop);     // ...and lower
            lastAlong = along;
            lastTop = t.top;
        }
        PL_CHECK(line == 3);
        // THE FIRST TOWER OVERLAPS THE HERO'S FOOTPRINT, which is where the bases merge.
        const HeroTurret& first = d.turret[2];
        PL_CHECK(std::hypot(first.x - d.heroX, first.z - d.heroZ) - first.radius < d.heroRadius);
    }

    // A WIND FROM THE EAST PUTS THE LINE EAST OF THE HERO: the sign, pinned.
    FieldParams f = connectedField(Real(1));
    f.convection.windBearing = Real(90);
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK(d.turret[4].x > d.heroX + d.heroRadius);
}

// A PICTURE TAKES THE SHOULDERS' PLACE: gone while the shape holds, back as it decays, and
// untouched with no shape.
namespace {
ShapeGeometry pictureFacing(double bearingDeg, Real decay, Real widthMetres) {
    ShapeGeometry g;
    g.on = true;
    const double b = bearingDeg * 0.017453292519943295;
    g.axisUX = static_cast<Real>(std::cos(b));
    g.axisUZ = static_cast<Real>(-std::sin(b));
    g.decay = decay;
    g.widthMetres = widthMetres;
    return g;
}
} // namespace

PL_TEST(APictureTakesTheShouldersPlace) {
    ConvectionDerived full;
    deriveConvection(connectedField(Real(1)), full);

    ConvectionDerived d = full;
    fitTurretsToShape(pictureFacing(0.0, Real(0), Real(2400)), Real(250), d);
    PL_CHECK(d.turretCount == 3);
    for (int i = 0; i < d.turretCount; ++i) PL_CHECK(!d.turret[i].shoulder);

    d = full;
    fitTurretsToShape(pictureFacing(0.0, Real(1), Real(2400)), Real(250), d);
    PL_CHECK(d.turretCount == kMaxHeroTurrets);
    for (int i = 0; i < d.turretCount; ++i) {
        PL_CHECK_NEAR(d.turret[i].top, full.turret[i].top, 0.0);
        PL_CHECK_NEAR(d.turret[i].x, full.turret[i].x, 1e-2);   // decay 1: the line is home
        PL_CHECK_NEAR(d.turret[i].z, full.turret[i].z, 1e-2);
    }

    d = full;
    fitTurretsToShape(pictureFacing(0.0, Real(0.25), Real(2400)), Real(250), d);
    PL_CHECK_NEAR(d.turret[0].top, full.turret[0].top * 0.25, 1e-3);

    d = full;
    ShapeGeometry off = pictureFacing(0.0, Real(0), Real(2400));
    off.on = false;
    fitTurretsToShape(off, Real(250), d);
    PL_CHECK(d.turretCount == kMaxHeroTurrets);
    PL_CHECK_NEAR(d.turret[4].x, full.turret[4].x, 0.0);
}

// THE FLANKING LINE NEVER STANDS BETWEEN THE LENS AND THE PICTURE: while the shape holds it
// lies along the plane -- the camera's right, under Turn to Camera -- on the side nearer the
// wind, and every tower of it is out past the picture's edge. From every facing.
PL_TEST(TheFlankingLineFramesThePicture) {
    ConvectionDerived full;
    deriveConvection(connectedField(Real(1)), full);
    const Real windFrom = Real(250);
    const double wb = 250.0 * 0.017453292519943295;

    for (double facing : { 0.0, 45.0, 110.0, 200.0, 290.0 }) {
        const ShapeGeometry g = pictureFacing(facing, Real(0), Real(2400));
        ConvectionDerived d = full;
        fitTurretsToShape(g, windFrom, d);
        double side = static_cast<double>(g.axisUX) * std::sin(wb) + static_cast<double>(g.axisUZ) * std::cos(wb);
        side = side < 0.0 ? -1.0 : 1.0;
        for (int i = 0; i < d.turretCount; ++i) {
            const double dx = d.turret[i].x - d.heroX, dz = d.turret[i].z - d.heroZ;
            const double u = (dx * g.axisUX + dz * g.axisUZ) * side;   // along the plane, windward
            const double n = -dx * g.axisUZ + dz * g.axisUX;           // towards the lens
            PL_CHECK(u - d.turret[i].radius >= 0.5 * g.widthMetres - 1.0);
            PL_CHECK(std::fabs(n) < 0.15 * d.heroRadius);
        }
    }
}

// A DRIFTING HERO KEEPS ITS PLACE IN THE FIELD: hero minus the cells' drift is constant
// in time, and the group moves with it. Pinned, it is where the sliders say at any time.
PL_TEST(ADriftingHeroRidesWithTheField) {
    FieldParams f = connectedField(Real(1));
    f.convection.heroDrift = true;
    f.convection.windSpeed = Real(8);

    ConvectionDerived at0, at90;
    f.timeSeconds = Real(0);
    deriveConvection(f, at0);
    f.timeSeconds = Real(90);
    deriveConvection(f, at90);

    PL_CHECK_NEAR(at0.heroX, 700.0, 1e-3);
    PL_CHECK_NEAR(at0.heroZ, -400.0, 1e-3);
    PL_CHECK_NEAR(at90.heroX - at90.driftX, at0.heroX - at0.driftX, 1e-2);
    PL_CHECK_NEAR(at90.heroZ - at90.driftZ, at0.heroZ - at0.driftZ, 1e-2);
    PL_CHECK(std::hypot(at90.heroX - at0.heroX, at90.heroZ - at0.heroZ) > 700.0);
    for (int i = 0; i < at0.turretCount; ++i) {
        PL_CHECK_NEAR(at90.turret[i].x - at90.heroX, at0.turret[i].x - at0.heroX, 1e-2);
        PL_CHECK_NEAR(at90.turret[i].z - at90.heroZ, at0.turret[i].z - at0.heroZ, 1e-2);
    }

    Real x = 0, z = 0;
    heroPositionNow(f, x, z);
    PL_CHECK_NEAR(x, at90.heroX, 0.0);
    PL_CHECK_NEAR(z, at90.heroZ, 0.0);

    f.convection.heroDrift = false;
    deriveConvection(f, at90);
    PL_CHECK_NEAR(at90.heroX, 700.0, 0.0);
    PL_CHECK_NEAR(at90.heroZ, -400.0, 0.0);
}

// ---------------------------------------------------------------------------
// Mamma (build 23)
// ---------------------------------------------------------------------------

// MAMMA 0 IS A FLAT BASE, and so is a NaN or an expression below the slider: the kernel
// hangs nothing, and the slab is where it was.
PL_TEST(NoMammaIsAFlatBase) {
    ConvectionDerived d;
    deriveConvection(convectiveField(), d);
    PL_CHECK_NEAR(d.mammaDepth, 0.0, 0.0);
    PL_CHECK_NEAR(mammaDepth(std::nanf(""), Real(450)), 0.0, 0.0);
    PL_CHECK_NEAR(mammaDepth(Real(-2), Real(450)), 0.0, 0.0);
}

// THE DEEPEST POUCH IS kMammaSag OF ITS WIDTH AT FULL AMOUNT, linear below that, clamped
// above it; a pouch narrower than the floor is floored, never a divisor of zero.
PL_TEST(MammaHangAtMostMostOfAPouchWidth) {
    PL_CHECK_NEAR(mammaDepth(Real(1), Real(450)), 0.8 * 450.0, 1e-3);
    PL_CHECK_NEAR(mammaDepth(Real(0.5), Real(450)), 0.4 * 450.0, 1e-3);
    PL_CHECK_NEAR(mammaDepth(Real(7), Real(450)), 0.8 * 450.0, 1e-3);
    PL_CHECK_NEAR(mammaDepth(Real(1), Real(0)), 0.8 * kMinPouchSize, 1e-4);

    FieldParams f = convectiveField();
    f.convection.mamma     = Real(0.5);
    f.convection.pouchSize = Real(600);
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.mammaDepth, 0.4 * 600.0, 1e-3);
    PL_CHECK_NEAR(d.pouchSize, 600.0, 0.0);

    // An absent layer has none to hang.
    f.convection.enabled = false;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.mammaDepth, 0.0, 0.0);
}

// ---------------------------------------------------------------------------
// Pileus and velum (build 24)
// ---------------------------------------------------------------------------

// THE CAP AND THE VEIL ARE THE HERO'S: nothing without one, and nothing at 0.
PL_TEST(NoHeroHasNoCapOrVeil) {
    FieldParams f = convectiveField();
    f.convection.pileus = Real(1);
    f.convection.velum  = Real(1);
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.pileusThick, 0.0, 0.0);
    PL_CHECK_NEAR(d.velumThick, 0.0, 0.0);

    f.convection.heroMode = 1;
    f.convection.pileus   = Real(0);
    f.convection.velum    = std::nanf("");
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.pileusThick, 0.0, 0.0);
    PL_CHECK_NEAR(d.velumThick, 0.0, 0.0);
}

// THICKNESS SCALES WITH THE AMOUNT to its cap; the veil stands at its fraction of the hero;
// a gap may push the cap into the crown, but no lower than the crown's own height.
PL_TEST(TheCapAndVeilStandWhereTheySay) {
    FieldParams f = convectiveField();
    f.convection.heroMode    = 1;
    f.convection.pileus      = Real(0.5);
    f.convection.pileusGap   = Real(250);
    f.convection.velum       = Real(2);
    f.convection.velumHeight = Real(0.4);
    ConvectionDerived d;
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.pileusThick, 0.5 * kPileusMaxThick, 1e-3);
    // FROM THE CROWN'S HIGHEST BILLOWS, which stand billow amount x the hero's factor over it.
    PL_CHECK_NEAR(d.pileusGap, 250.0 + f.convection.billowAmount * d.heroBillow, 1e-2);
    PL_CHECK_NEAR(d.velumThick, kVelumMaxThick, 1e-3);
    PL_CHECK_NEAR(d.velumHeight, 0.4 * d.heroTop, 1e-2);

    f.convection.pileusGap = Real(-1e6);
    deriveConvection(f, d);
    PL_CHECK_NEAR(d.pileusGap, -d.heroTop, 1e-2);
}
