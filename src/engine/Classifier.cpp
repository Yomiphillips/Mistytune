#include "Classifier.h"

#include "ConvectionField.h"
#include "Organization.h"

#include <cmath>
#include <cstdio>
#include <cstring>

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

// THE ORGANIZATION GROUP'S VARIETIES (build 20), each where the look reads as the word.
// A wave a quarter deep is visible bands; lacunarity 0.4 has opened holes in most cells
// (slang.convection measures the share); a gap of 0.2 on the slider opens seams wide
// enough to see sky through. Radiatus is kRadiatusCoherence in Organization.h.
constexpr Real kUndulatusFrom  = 0.25f;
constexpr Real kLacunosusFrom  = 0.4f;
constexpr Real kPerlucidusGap  = 0.2f;

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

// ROWS THE EYE READS AS PARALLEL BANDS: Rolls, straightened. Radiatus, in any genus that
// has it. The rows' convergence towards the horizon is the camera's, and needs no rule.
bool inRows(const OrganizationParams& p, const OrganizationResolved& o) {
    return o.on && p.mode == static_cast<int32_t>(OrganizationMode::Rolls) &&
           o.coherence >= kRadiatusCoherence;
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

    // THE HERO NAMES THE SHOT. It is a single tower whatever the polarity or the
    // organization, because the hero is the one cloud that got all the way up.
    if (cd.heroTop > Real(1)) {
        return { CloudGenus::Cumulus, cumulusSpecies(cd.heroTop, c.heroWidth) };
    }

    if (clamp01(c.coverage) < kNoCoverage) return {};

    const OrganizationResolved& org = cd.organization;
    const Real cell = c.cellSize > Real(1) ? c.cellSize : Real(1);

    // A SHEET WITH HOLES IS A DECK whatever the polarity: lacunarity fills the seams of
    // open cells too (convOrganize), and the atlas files lacunosus under the layer genera.
    const bool lacunose = org.lacunarity >= kLacunosusFrom;

    if (clamp01(c.polarity) >= kStratocumulusFrom || lacunose) {
        if (cd.depth / cell >= kCongestusFrom) return { CloudGenus::Stratocumulus, "castellanus" };

        LayerClass sc{ CloudGenus::Stratocumulus, "stratiformis" };
        if (lacunose) {
            sc.variety[0] = "lacunosus";
            return sc;
        }
        const bool gaps = clamp01(c.organization.gapFraction) >= kPerlucidusGap;
        sc.variety[0] = gaps || clamp01(c.coverage) < kOpacusFrom ? "perlucidus" : "opacus";
        if (inRows(c.organization, org))                 sc.variety[1] = "radiatus";
        else if (org.waveAmplitude >= kUndulatusFrom)    sc.variety[1] = "undulatus";
        return sc;
    }

    // Cumulus's only variety is radiatus: cloud streets.
    LayerClass cu{ CloudGenus::Cumulus, cumulusSpecies(cd.depth, cell) };
    if (inRows(c.organization, org)) cu.variety[0] = "radiatus";
    return cu;
}

LayerClass classifyHigh(const FieldParams& field) {
    const IceParams& ice = field.ice;
    if (!ice.enabled || !(ice.opticalDepth > Real(0)) ||
        !(ice.cellDensity > Real(0)) || !(ice.cellStrength > Real(0))) {
        return {};
    }

    LayerClass ci{ CloudGenus::Cirrus, "fibratus" };
    if (ice.opticalDepth >= kSpissatusFrom) {
        ci.species = "spissatus";
    } else if (ice.streakLength < kFloccusBelow) {
        ci.species = "floccus";
    } else {
        const Real turn  = bearingDifference(ice.shear.bearing[0], ice.shear.bearing[kShearKnots - 1]);
        const Real shear = std::fabs(ice.shear.speed[0] - ice.shear.speed[kShearKnots - 1]);
        if (turn >= kUncinusTurn || shear >= kUncinusShear) ci.species = "uncinus";
    }

    // Cirrus radiatus: the generating heads in parallel bands.
    if (inRows(ice.organization, resolveOrganization(ice.organization, false))) {
        ci.variety[0] = "radiatus";
    }
    return ci;
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

// THE ATLAS'S ABBREVIATIONS FOR SPECIES AND VARIETIES, for when even the genus
// abbreviations leave the readout too long. A word it does not list is kept whole.
const char* wordAbbrev(const char* word) {
    static const char* const table[][2] = {
        { "humilis", "hum" },      { "mediocris", "med" },   { "congestus", "con" },
        { "stratiformis", "str" }, { "castellanus", "cas" }, { "fibratus", "fib" },
        { "uncinus", "unc" },      { "spissatus", "spi" },   { "floccus", "flo" },
        { "opacus", "op" },        { "perlucidus", "pe" },   { "undulatus", "un" },
        { "radiatus", "ra" },      { "lacunosus", "la" },
    };
    for (const auto& row : table) {
        if (std::strcmp(row[0], word) == 0) return row[1];
    }
    return word;
}

// ONE LAYER'S NAME AT A LEVEL OF SHORTENING: 0 all in full; 1 the genus abbreviated;
// 2 the varieties too; 3 the species too.
void layerText(const LayerClass& l, int level, char* out, size_t cap) {
    const char* genus   = level >= 1 ? genusAbbrev(l.genus) : genusName(l.genus);
    const char* species = level >= 3 ? wordAbbrev(l.species) : l.species;
    std::snprintf(out, cap, "%s %s", genus, species);
    for (const char* v : l.variety) {
        if (!v || !*v) continue;
        const size_t n = std::strlen(out);
        std::snprintf(out + n, cap - n, " %s", level >= 2 ? wordAbbrev(v) : v);
    }
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
    char text[128];

    const bool low  = sky.low.genus  != CloudGenus::None;
    const bool high = sky.high.genus != CloudGenus::None;

    // THE LONGEST FORM THAT FITS: full names where there is room, the atlas's
    // abbreviations where there is not. Two layers always abbreviate their genera, as
    // they did before varieties existed, so the default sky reads the same. The LOW layer
    // is shortened first, since it is the one with varieties to spare: "Sc str op un,
    // Ci uncinus" rather than "Sc str op un, Ci unc".
    const bool shared = (low && high) || (high && sky.tooDryForCumulus);
    static const int kSteps[][2] = { { 0, 0 }, { 1, 1 }, { 2, 1 }, { 3, 1 }, { 3, 2 }, { 3, 3 } };
    for (int step = shared ? 1 : 0; step < 6; ++step) {
        // One layer alone walks its own levels, 0 to 3, with whichever column is its own.
        const int lowLevel  = shared ? kSteps[step][0] : (step < 4 ? step : 3);
        const int highLevel = shared ? kSteps[step][1] : (step < 4 ? step : 3);
        char a[64], b[64];
        if (low)  layerText(sky.low, lowLevel, a, sizeof(a));
        if (high) layerText(sky.high, highLevel, b, sizeof(b));

        if (low && high) {
            std::snprintf(text, sizeof(text), "%s, %s", a, b);
        } else if (low) {
            std::snprintf(text, sizeof(text), "%s", a);
        } else if (high && sky.tooDryForCumulus) {
            std::snprintf(text, sizeof(text), "%s (too dry for Cu)", b);
        } else if (high) {
            std::snprintf(text, sizeof(text), "%s", b);
        } else if (sky.tooDryForCumulus) {
            std::snprintf(text, sizeof(text), "No cloud: too dry for Cu");
        } else {
            std::snprintf(text, sizeof(text), "Clear sky");
        }
        if (static_cast<int>(std::strlen(text)) <= limit) break;
    }

    int n = 0;
    for (; n < limit && text[n] != '\0'; ++n) out[n] = text[n];
    out[n] = '\0';
}

} // namespace plugin::cloud
