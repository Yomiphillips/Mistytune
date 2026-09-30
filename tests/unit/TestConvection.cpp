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
