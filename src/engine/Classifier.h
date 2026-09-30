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
// THE NAMES ARE THE WMO INTERNATIONAL CLOUD ATLAS'S GENERA AND SPECIES, reduced to the
// ones these two generators can make:
//
//   cumulus         humilis    wider than tall; flattened
//                   mediocris  moderate vertical extent
//                   congestus  markedly sprouting, of great vertical extent
//   stratocumulus   opacus     a closed deck, cells merged
//                   perlucidus a deck with distinct gaps
//                   castellanus closed cells that tower
//   cirrus          fibratus   filaments without hooks or tufts
//                   uncinus    filaments ending in hooks: a turning or shearing wind
//                   spissatus  dense enough to grey against the sun
//                   floccus    tufts whose fall streaks barely leave them
//
// THE READOUT IS AN AFTER EFFECTS PARAMETER NAME, WHICH HOLDS 31 CHARACTERS. That limit
// is PF_MAX_EFFECT_PARAM_NAME_LEN and is the one hard contract here: a longer string is
// cut off in the panel, and TestClassifier sweeps the parameter space against it.
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
