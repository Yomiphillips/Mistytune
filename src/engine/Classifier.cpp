#include "Classifier.h"

#include "ConvectionField.h"

#include <cmath>
#include <cstdio>

namespace plugin::cloud {

namespace {

// ---------------------------------------------------------------------------
// The thresholds, each one a statement about a cloud rather than about a slider
// ---------------------------------------------------------------------------

// HEIGHT OVER WIDTH. The atlas's humilis is "flattened", mediocris of "moderate vertical
// extent" and congestus "markedly sprouting"; a tower's aspect is what those words
// measure. Checked against the scenes this project already renders: the default field
// is 0.61 and the default hero 0.57 (mediocris), and the reference tower the host
// reported on build 14 -- Inversion 7000, Instability 0.9, a 4 km hero at 0.7 -- is 1.1.
constexpr Real kHumilisBelow  = 0.35f;
constexpr Real kCongestusFrom = 0.9f;

// A TOWER THIS TALL IS CONGESTUS WHATEVER ITS WIDTH, and one this short cannot be. The
// aspect alone would call a 10 km-wide mound of 5 km humilis.
constexpr Real kCongestusAlwaysFrom = 4000.0f;   // m
constexpr Real kHumilisOnlyBelow    = 1500.0f;   // m

// CLOSED CELLS MAKE A DECK. Polarity is the spec's hero parameter for exactly this line.
constexpr Real kStratocumulusFrom = 0.5f;

// A closed deck this covered has merged its cells: no sky between them.
constexpr Real kOpacusFrom = 0.75f;

// Coverage below this is a clear sky, not a very sparse field.
constexpr Real kNoCoverage = 0.01f;

// ICE THICK ENOUGH TO GREY AGAINST THE SUN. Optical depth 1.5 transmits about a fifth.
constexpr Real kSpissatusFrom = 1.5f;

// FALL STREAKS THAT BARELY LEAVE THEIR HEADS are tufts rather than filaments.
constexpr Real kFloccusBelow = 600.0f;   // m

// THE HOOK. A streak curves when the wind changes with height -- in direction or in
// speed -- because crystals falling out of a generating head are carried differently at
// each level. The defaults turn 30 degrees and shear 26 m/s, which is why they are
// uncinus; a profile with neither is fibratus.
constexpr Real kUncinusTurn  = 15.0f;   // degrees, top knot to bottom knot
constexpr Real kUncinusShear = 10.0f;   // m/s, top knot to bottom knot

const char* cumulusSpecies(Real height, Real width) {
    const Real w = width > Real(1) ? width : Real(1);
    const Real aspect = height / w;
    if (aspect >= kCongestusFrom || height >= kCongestusAlwaysFrom) return "congestus";
    if (aspect < kHumilisBelow && height < kHumilisOnlyBelow)      return "humilis";
    return "mediocris";
}

Real clamp01(Real v) { return v < Real(0) ? Real(0) : (v > Real(1) ? Real(1) : v); }

// The smallest angle between two bearings, so 350 and 10 are 20 degrees apart and a dial
// keyframed twice round still measures the turn it shows.
Real bearingDifference(Real a, Real b) {
    double d = std::fmod(std::fabs(static_cast<double>(a) - static_cast<double>(b)), 360.0);
    if (d > 180.0) d = 360.0 - d;
    return static_cast<Real>(d);
}

LayerClass classifyLow(const FieldParams& field, bool& tooDry) {
    const ConvectionParams& c = field.convection;
    tooDry = false;
    if (!c.enabled) return {};

    // DRY AIR UNDER A LID is the one reason an enabled layer shows nothing that the user
    // cannot see from the panel, so it is named. deriveConvection's own test.
    const Real room = c.inversionHeight - condensationLevel(field.physics);
    if (!(room > Real(1))) {
        tooDry = true;
        return {};
    }
    if (!(c.density > Real(0))) return {};

    ConvectionDerived cd;
    deriveConvection(field, cd);
    if (!cd.present) return {};

    // THE HERO NAMES THE SHOT. It is a single tower whatever the polarity, because the
    // hero is the one cloud that got all the way up.
    if (cd.heroTop > Real(1)) {
        return { CloudGenus::Cumulus, cumulusSpecies(cd.heroTop, c.heroWidth) };
    }

    if (clamp01(c.coverage) < kNoCoverage) return {};

    const Real cell = c.cellSize > Real(1) ? c.cellSize : Real(1);
    if (clamp01(c.polarity) >= kStratocumulusFrom) {
        if (cd.depth / cell >= kCongestusFrom)       return { CloudGenus::Stratocumulus, "castellanus" };
        if (clamp01(c.coverage) >= kOpacusFrom)      return { CloudGenus::Stratocumulus, "opacus" };
        return { CloudGenus::Stratocumulus, "perlucidus" };
    }
    return { CloudGenus::Cumulus, cumulusSpecies(cd.depth, cell) };
}

LayerClass classifyHigh(const FieldParams& field) {
    const IceParams& ice = field.ice;
    if (!ice.enabled || !(ice.opticalDepth > Real(0)) ||
        !(ice.cellDensity > Real(0)) || !(ice.cellStrength > Real(0))) {
        return {};
    }

    if (ice.opticalDepth >= kSpissatusFrom) return { CloudGenus::Cirrus, "spissatus" };
    if (ice.streakLength < kFloccusBelow)    return { CloudGenus::Cirrus, "floccus" };

    const Real turn  = bearingDifference(ice.shear.bearing[0], ice.shear.bearing[kShearKnots - 1]);
    const Real shear = std::fabs(ice.shear.speed[0] - ice.shear.speed[kShearKnots - 1]);
    if (turn >= kUncinusTurn || shear >= kUncinusShear) return { CloudGenus::Cirrus, "uncinus" };
    return { CloudGenus::Cirrus, "fibratus" };
}

const char* genusName(CloudGenus g) {
    switch (g) {
        case CloudGenus::Cumulus:       return "Cumulus";
        case CloudGenus::Stratocumulus: return "Stratocumulus";
        case CloudGenus::Cirrus:        return "Cirrus";
        case CloudGenus::None:          break;
    }
    return "";
}

// The atlas's own abbreviations, for when two layers have to share 31 characters.
const char* genusAbbrev(CloudGenus g) {
    switch (g) {
        case CloudGenus::Cumulus:       return "Cu";
        case CloudGenus::Stratocumulus: return "Sc";
        case CloudGenus::Cirrus:        return "Ci";
        case CloudGenus::None:          break;
    }
    return "";
}

} // namespace

SkyClass classifySky(const FieldParams& field) {
    SkyClass sky;
    sky.low  = classifyLow(field, sky.tooDryForCumulus);
    sky.high = classifyHigh(field);
    return sky;
}

void describeSky(const SkyClass& sky, char* out, int capacity) {
    if (!out || capacity <= 0) return;

    // NEVER MORE THAN AE CAN SHOW, whatever the caller's buffer.
    const int limit = capacity - 1 < kReadoutMaxChars ? capacity - 1 : kReadoutMaxChars;
    char text[64];

    const bool low  = sky.low.genus  != CloudGenus::None;
    const bool high = sky.high.genus != CloudGenus::None;

    if (low && high) {
        std::snprintf(text, sizeof(text), "%s %s, %s %s",
                      genusAbbrev(sky.low.genus), sky.low.species,
                      genusAbbrev(sky.high.genus), sky.high.species);
    } else if (low) {
        std::snprintf(text, sizeof(text), "%s %s", genusName(sky.low.genus), sky.low.species);
    } else if (high && sky.tooDryForCumulus) {
        std::snprintf(text, sizeof(text), "%s %s (too dry for Cu)",
                      genusAbbrev(sky.high.genus), sky.high.species);
    } else if (high) {
        std::snprintf(text, sizeof(text), "%s %s", genusName(sky.high.genus), sky.high.species);
    } else if (sky.tooDryForCumulus) {
        std::snprintf(text, sizeof(text), "No cloud: too dry for Cu");
    } else {
        std::snprintf(text, sizeof(text), "Clear sky");
    }

    int n = 0;
    for (; n < limit && text[n] != '\0'; ++n) out[n] = text[n];
    out[n] = '\0';
}

} // namespace plugin::cloud
