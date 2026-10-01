// The classifier readout: what the parameters describe, named by the cloud atlas.
//
// THE CONTRACT IS THE LENGTH. The readout is an After Effects parameter NAME, which
// holds 31 characters, and a longer one is cut off in the panel mid-word. So the sweep
// below throws the whole parameter space at describeSky and holds every answer to it.
//
// THE REST PIN EACH RULE TO A SCENE this project already renders or has been sent: the
// effect's default sky, and the towering cumulus from the build 14 host report.

#include "TestFramework.h"

#include "Classifier.h"

#include <cstring>

using namespace plugin;
using namespace plugin::cloud;

namespace {

std::string describe(const FieldParams& f) {
    char text[64];
    describeSky(classifySky(f), text, static_cast<int>(sizeof(text)));
    return text;
}

// The effect's defaults, which are not the engine's: cumulus on at Coverage 0.6, with the
// hero standing in the field, under the default cirrus.
FieldParams effectDefaults() {
    FieldParams f;
    f.convection.enabled  = true;
    f.convection.coverage = 0.6f;
    f.convection.heroMode = 1;
    return f;
}

FieldParams iceOnly() {
    FieldParams f;
    f.convection.enabled = false;
    return f;
}

FieldParams cumulusOnly() {
    FieldParams f = effectDefaults();
    f.ice.enabled = false;
    f.convection.heroMode = 0;
    return f;
}

void checkName(const FieldParams& f, const char* want) {
    const std::string got = describe(f);
    if (got != want) {
        char buf[160];
        std::snprintf(buf, sizeof(buf), "classified \"%s\", wanted \"%s\"", got.c_str(), want);
        ::pltest::reportFailure(__FILE__, __LINE__, buf);
    }
}

} // namespace

// --------------------------------------------------------------------------
// The scenes that exist
// --------------------------------------------------------------------------

// THE FIRST THING A NEW INSTANCE SHOWS. Aspect 0.57 for the default hero and a turning,
// shearing wind over the cirrus.
PL_TEST(TheEffectsDefaultSkyIsMediocrisUnderUncinus) {
    checkName(effectDefaults(), "Cu mediocris, Ci uncinus");
}

// THE SHOT THE HOST ASKED FOR ON BUILD 14: Inversion 7000, Instability 0.9, a 4 km hero
// alone at Height 0.7 -- a tower 4.4 km tall.
PL_TEST(TheReferenceTowerIsCongestus) {
    FieldParams f = effectDefaults();
    f.ice.enabled = false;
    f.convection.inversionHeight = 7000.0f;
    f.convection.instability     = 0.9f;
    f.convection.heroMode        = 2;
    f.convection.heroWidth       = 4000.0f;
    f.convection.heroHeight      = 0.7f;
    checkName(f, "Cumulus congestus");
}

// --------------------------------------------------------------------------
// Cumulus and stratocumulus
// --------------------------------------------------------------------------

PL_TEST(ALowWideFieldIsHumilis) {
    FieldParams f = cumulusOnly();
    f.convection.instability     = 0.0f;
    f.convection.inversionHeight = 1500.0f;
    checkName(f, "Cumulus humilis");
}

PL_TEST(TheDefaultFieldIsMediocris) {
    checkName(cumulusOnly(), "Cumulus mediocris");
}

// A VERY TALL TOWER IS CONGESTUS HOWEVER WIDE, which the aspect alone would miss.
PL_TEST(AFiveKilometreMoundIsStillCongestus) {
    FieldParams f = cumulusOnly();
    f.convection.heroMode        = 2;
    f.convection.inversionHeight = 6000.0f;
    f.convection.heroHeight      = 1.0f;
    f.convection.heroWidth       = 10000.0f;
    checkName(f, "Cumulus congestus");
}

// CLOSED CELLS ARE A DECK. Polarity is the spec's hero parameter for this line. Its
// species is stratiformis and opacus / perlucidus are VARIETIES, as the atlas has them;
// until build 20 they were named as species. "Stratocumulus stratiformis opacus" is 33
// characters, so the genus is abbreviated.
PL_TEST(ClosedCellsAreStratocumulus) {
    FieldParams f = cumulusOnly();
    f.convection.polarity = 1.0f;
    f.convection.coverage = 0.9f;
    checkName(f, "Sc stratiformis opacus");

    f.convection.coverage = 0.5f;
    checkName(f, "Sc stratiformis perlucidus");

    f.convection.instability     = 1.0f;
    f.convection.inversionHeight = 5000.0f;
    checkName(f, "Stratocumulus castellanus");
}

// THE ORGANIZATION GROUP'S VARIETIES (build 20), each from the control the spec names.
PL_TEST(OrganizationNamesTheVarieties) {
    FieldParams deck = cumulusOnly();
    deck.convection.polarity = 1.0f;
    deck.convection.coverage = 0.9f;

    // undulatus: a wave a quarter deep, or the Waves mode, which is at least that. In
    // full it is 32 characters, one over, so the varieties go to the atlas's short forms.
    FieldParams f = deck;
    f.convection.organization.waveAmplitude = 0.4f;
    checkName(f, "Sc stratiformis op un");
    f.convection.organization.waveAmplitude = 0.0f;
    f.convection.organization.mode = static_cast<int32_t>(OrganizationMode::Waves);
    checkName(f, "Sc stratiformis op un");

    // radiatus: Rolls, straight enough. Loose rolls are not yet bands.
    f = deck;
    f.convection.organization.mode      = static_cast<int32_t>(OrganizationMode::Rolls);
    f.convection.organization.coherence = 0.8f;
    checkName(f, "Sc stratiformis opacus radiatus");
    f.convection.organization.coherence = 0.2f;
    checkName(f, "Sc stratiformis opacus");

    // perlucidus from gaps, even on a deck covered enough to be opacus without them.
    f = deck;
    f.convection.organization.gapFraction = 0.5f;
    checkName(f, "Sc stratiformis perlucidus");

    // lacunosus: a sheet with holes, which is a deck whatever the polarity.
    f = deck;
    f.convection.organization.lacunarity = 0.7f;
    checkName(f, "Sc stratiformis lacunosus");
    f.convection.polarity = 0.0f;
    checkName(f, "Sc stratiformis lacunosus");

    // Cumulus in rows is radiatus, and its only variety: a wave is not a Cu variety.
    FieldParams cu = cumulusOnly();
    cu.convection.organization.mode      = static_cast<int32_t>(OrganizationMode::Rolls);
    cu.convection.organization.coherence = 0.8f;
    cu.convection.organization.waveAmplitude = 0.5f;
    checkName(cu, "Cumulus mediocris radiatus");

    // Cirrus in bands.
    FieldParams ci = iceOnly();
    ci.ice.organization.mode      = static_cast<int32_t>(OrganizationMode::Rolls);
    ci.ice.organization.coherence = 0.9f;
    checkName(ci, "Cirrus uncinus radiatus");

    // THE LONG ONES FALL BACK TO THE ATLAS'S ABBREVIATIONS, the low layer's first:
    // "Sc stratiformis op un, Ci uncinus" is 33 characters.
    FieldParams both = deck;
    both.ice.enabled = true;
    both.convection.organization.waveAmplitude = 0.4f;
    checkName(both, "Sc str op un, Ci uncinus");
}

// THE HERO NAMES THE SHOT whatever the field's polarity: it is one tower.
PL_TEST(AHeroInADeckIsStillACumulus) {
    FieldParams f = effectDefaults();
    f.ice.enabled = false;
    f.convection.polarity = 1.0f;
    checkName(f, "Cumulus mediocris");
}

// --------------------------------------------------------------------------
// Cirrus
// --------------------------------------------------------------------------

PL_TEST(AWindThatNeitherTurnsNorShearsIsFibratus) {
    FieldParams f = iceOnly();
    for (int k = 0; k < kShearKnots; ++k) {
        f.ice.shear.bearing[k] = 270.0f;
        f.ice.shear.speed[k]   = 20.0f;
    }
    checkName(f, "Cirrus fibratus");
}

PL_TEST(SpeedShearAloneIsUncinus) {
    FieldParams f = iceOnly();
    for (int k = 0; k < kShearKnots; ++k) f.ice.shear.bearing[k] = 270.0f;
    checkName(f, "Cirrus uncinus");
}

// A TURN THROUGH NORTH IS A 20-DEGREE TURN, not a 340-degree one, and a dial keyframed
// twice round measures the turn it shows.
PL_TEST(ATurnThroughNorthIsMeasuredTheShortWay) {
    FieldParams f = iceOnly();
    for (int k = 0; k < kShearKnots; ++k) f.ice.shear.speed[k] = 20.0f;
    f.ice.shear.bearing[0] = 350.0f;
    f.ice.shear.bearing[kShearKnots - 1] = 370.0f + 720.0f;   // 10, twice round
    checkName(f, "Cirrus uncinus");

    f.ice.shear.bearing[kShearKnots - 1] = 355.0f - 720.0f;   // 5 degrees
    checkName(f, "Cirrus fibratus");
}

PL_TEST(DenseIceIsSpissatus) {
    FieldParams f = iceOnly();
    f.ice.opticalDepth = 2.0f;
    checkName(f, "Cirrus spissatus");
}

PL_TEST(StreaksThatBarelyFallAreFloccus) {
    FieldParams f = iceOnly();
    f.ice.streakLength = 300.0f;
    checkName(f, "Cirrus floccus");
}

// --------------------------------------------------------------------------
// Nothing, and why
// --------------------------------------------------------------------------

// DRY AIR UNDER THE LID. Surface Humidity 0.2 puts the condensation level near 2.9 km,
// above the default 2.4 km inversion. Named, because the layer is switched on.
PL_TEST(DryAirSaysWhyThereIsNoCumulus) {
    FieldParams f = effectDefaults();
    f.physics.surfaceHumidity = 0.2f;
    checkName(f, "Ci uncinus (too dry for Cu)");

    f.ice.enabled = false;
    checkName(f, "No cloud: too dry for Cu");
}

PL_TEST(NothingSwitchedOnIsAClearSky) {
    FieldParams f = iceOnly();
    f.ice.enabled = false;
    checkName(f, "Clear sky");

    // A layer that is on but cannot show anything is not a cloud either.
    FieldParams g = iceOnly();
    g.ice.opticalDepth = 0.0f;
    checkName(g, "Clear sky");
}

// --------------------------------------------------------------------------
// The contract
// --------------------------------------------------------------------------

// EVERY ANSWER FITS IN AN AE PARAMETER NAME. A deterministic walk over every switch and
// across each continuous parameter's whole valid range, since the longest names come
// from combinations -- two layers, the longest species, the dry-air suffix.
PL_TEST(EveryReadoutFitsInAnAfterEffectsParameterName) {
    PL_SWEEP(sweep, "skies");
    unsigned int h = 12345u;
    auto next = [&h]() {
        h = h * 747796405u + 2891336453u;
        const unsigned int w = ((h >> ((h >> 28u) + 4u)) ^ h) * 277803737u;
        return static_cast<float>((w >> 22u) ^ w) * (1.0f / 4294967296.0f);
    };

    for (int i = 0; i < 20000; ++i) {
        FieldParams f;
        f.convection.enabled         = next() < 0.8f;
        f.convection.heroMode        = static_cast<int32_t>(next() * 3.0f);
        f.convection.polarity        = next();
        f.convection.coverage        = next();
        f.convection.instability     = next();
        f.convection.inversionHeight = next() * 12000.0f;
        f.convection.cellSize        = 100.0f + next() * 20000.0f;
        f.convection.heroWidth       = 2.0f + next() * 10000.0f;
        f.convection.heroHeight      = next();
        f.physics.surfaceHumidity    = next();
        f.ice.enabled                = next() < 0.8f;
        f.ice.opticalDepth           = next() * 3.0f;
        f.ice.streakLength           = next() * 5000.0f;
        for (int k = 0; k < kShearKnots; ++k) {
            f.ice.shear.speed[k]   = next() * 80.0f;
            f.ice.shear.bearing[k] = next() * 720.0f - 360.0f;
        }
        // The varieties (build 20), which make the longest names of all.
        f.convection.organization.mode          = static_cast<int32_t>(next() * 4.0f);
        f.convection.organization.coherence     = next();
        f.convection.organization.waveAmplitude = next();
        f.convection.organization.gapFraction   = next();
        f.convection.organization.lacunarity    = next();
        f.ice.organization.mode                 = static_cast<int32_t>(next() * 4.0f);
        f.ice.organization.coherence            = next();
        // Mamma (build 23), a word after all of them.
        f.convection.mamma = next() < 0.5f ? 0.0f : next();
        // The hero's cap and veil (build 24): with mamma, the longest names there are.
        f.convection.pileus = next() < 0.5f ? 0.0f : next();
        f.convection.velum  = next() < 0.5f ? 0.0f : next();

        const std::string text = describe(f);
        sweep.require(!text.empty() && text.size() <= static_cast<size_t>(kReadoutMaxChars), i);
    }
    sweep.finish(20000);
}

// A SMALLER BUFFER IS HONOURED rather than overrun, and still terminated.
PL_TEST(ASmallBufferIsNeverOverrun) {
    char tiny[8];
    std::memset(tiny, 'x', sizeof(tiny));
    describeSky(classifySky(effectDefaults()), tiny, static_cast<int>(sizeof(tiny)));
    PL_CHECK(std::strlen(tiny) == sizeof(tiny) - 1);
}

// MAMMA ARE NAMED AFTER THE VARIETIES, as the atlas writes them, and only when they hang.
// The deck is the effect's default sky with closed cells: the longest name it makes.
PL_TEST(MammaAreNamedAfterTheVarieties) {
    FieldParams f = effectDefaults();
    f.convection.heroMode = 0;
    f.convection.polarity = 1.0f;
    f.convection.coverage = 0.9f;
    f.convection.organization.mode          = 2;     // waves: undulatus
    f.convection.organization.waveAmplitude = 0.8f;

    const std::string flat = describe(f);
    PL_CHECK(flat.find("mam") == std::string::npos);

    f.convection.mamma = 0.6f;
    const std::string sagging = describe(f);
    PL_CHECK(sagging.find("mam") != std::string::npos);
    PL_CHECK(sagging.find("mam") > sagging.find(" un"));
    PL_CHECK(sagging.size() <= static_cast<size_t>(kReadoutMaxChars));

    // ON THE HERO TOO, and on a layer the air cannot make, not at all.
    f.convection.heroMode = 1;
    PL_CHECK(describe(f).find("mam") != std::string::npos);
    f.physics.surfaceHumidity = 0.05f;
    PL_CHECK(describe(f).find("mam") == std::string::npos);
}

// PILEUS AND VELUM ARE THE HERO'S: named with it, after mamma as the atlas orders features
// and accessory clouds, and not on a field without one.
PL_TEST(TheCapAndVeilAreNamedWithTheHero) {
    FieldParams f = effectDefaults();
    f.convection.mamma  = 0.5f;
    f.convection.pileus = 0.7f;
    f.convection.velum  = 0.4f;
    const std::string all = describe(f);
    PL_CHECK(all.find("pil") != std::string::npos);
    PL_CHECK(all.find("vel") != std::string::npos);
    PL_CHECK(all.find("mam") < all.find("pil"));
    PL_CHECK(all.find("pil") < all.find("vel"));
    PL_CHECK(all.size() <= static_cast<size_t>(kReadoutMaxChars));

    f.convection.heroMode = 0;
    const std::string field = describe(f);
    PL_CHECK(field.find("pil") == std::string::npos);
    PL_CHECK(field.find("vel") == std::string::npos);
    PL_CHECK(field.find("mam") != std::string::npos);
}
