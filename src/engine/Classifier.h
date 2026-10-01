#pragma once

// What the user has made, named the way a cloud atlas would name it.
//
// ===========================================================================
// RULE-BASED OVER THE PARAMETERS, AS PLAN.md DECIDES: predictable, debuggable and
// testable without a GPU. It never looks at a rendered pixel. It reads the same numbers
// the generators read -- the condensation level, the room under the lid, the shear
// profile -- so it names the sky the parameters describe, including a sky the camera
// happens not to be pointed at.
//
// THE NAMES ARE THE WMO INTERNATIONAL CLOUD ATLAS'S GENERA, SPECIES AND VARIETIES, reduced
// to the ones these two generators can make:
//
//   cumulus         humilis      wider than tall; flattened
//                   mediocris    moderate vertical extent
//                   congestus    markedly sprouting, of great vertical extent
//                     radiatus     in parallel rows: Rolls, straight enough
//   stratocumulus   stratiformis a closed deck
//                   castellanus  closed cells that tower
//                     opacus       cells merged, no sky between
//                     perlucidus   distinct gaps between the elements
//                     undulatus    in waves
//                     radiatus     in parallel rows
//                     lacunosus    a sheet with round holes
//     + mamma       pouches hanging from the underside, after any variety (build 23).
//     + pileus      a smooth cap over the hero's crown (build 24)
//     + velum       a wide thin veil the hero rises through (build 24)
//                   THE ATLAS LISTS IT UNDER Sc AND Cb, NOT Cu: on a cumulus here it is the
//                   hero standing in for the cumulonimbus this generator cannot make yet,
//                   and the readout names what the user sees rather than refusing to.
//   cirrus          fibratus     filaments without hooks or tufts
//                   uncinus      filaments ending in hooks: a turning or shearing wind
//                   spissatus    dense enough to grey against the sun
//                   floccus      tufts whose fall streaks barely leave them
//                     radiatus     in parallel bands
//
// UNTIL BUILD 20 opacus AND perlucidus WERE CALLED SPECIES. The atlas has them as
// varieties of a species, stratiformis, and a readout meant to teach the atlas should
// not teach that wrong. The varieties come from the Organization group (build 20).
//
// THE READOUT IS AN AFTER EFFECTS PARAMETER NAME, WHICH HOLDS 31 CHARACTERS. That limit
// is PF_MAX_EFFECT_PARAM_NAME_LEN and is the one hard contract here: a longer string is
// cut off in the panel, and TestClassifier sweeps the parameter space against it. When
// the full names do not fit, the atlas's own abbreviations stand in, varieties first:
// "Sc stratiformis op un".
// ===========================================================================

#include "CloudParams.h"

namespace plugin::cloud {

enum class CloudGenus : int32_t {
    None          = 0,
    Cumulus       = 1,
    Stratocumulus = 2,
    Cirrus        = 3
};

struct LayerClass {
    CloudGenus  genus   = CloudGenus::None;
    const char* species = "";   // a string literal, never owned

    // Up to two varieties, "" for none: the deck's opacity first, then its pattern.
    const char* variety[2] = { "", "" };

    // SUPPLEMENTARY FEATURES AND ACCESSORY CLOUDS, "" for none: mamma (build 23), then
    // pileus and velum (build 24). The atlas writes them after the varieties, features
    // before accessory clouds -- "Cumulus congestus mamma pileus" -- and none is a variety:
    // each hangs off the cloud, or sits on it.
    const char* feature[3] = { "", "", "" };
};

struct SkyClass {
    // The boundary layer's cloud: the hero when there is one, since a shot with a hero
    // is about the hero, else the field.
    LayerClass low;
    LayerClass high;

    // The cumulus layer is switched on but the air cannot make it: the condensation level
    // is at or above the inversion. Named, because a user who switched cumulus on and
    // sees none deserves to be told why.
    bool tooDryForCumulus = false;
};

// AE's parameter-name capacity, not counting the terminator. Mirrors the SDK's
// PF_MAX_EFFECT_PARAM_NAME_LEN, which this host-free library cannot include.
constexpr int kReadoutMaxChars = 31;

SkyClass classifySky(const FieldParams& field);

// The readout text, at most kReadoutMaxChars characters plus the terminator. `capacity`
// is the size of `out`; a smaller buffer is honoured rather than overrun.
void describeSky(const SkyClass& sky, char* out, int capacity);

} // namespace plugin::cloud
