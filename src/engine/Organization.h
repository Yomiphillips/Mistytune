#pragma once

// The Organization group, resolved into what the kernel reads.
//
// SAME ARRANGEMENT AS ConvectionField.h: plain arithmetic over the parameters, once per
// change, so the kernel never takes a sine of a slider per sample, and tests/unit/ can
// check it without a card. OrganizationLib.slang is the kernel's half.
//
// ===========================================================================
// ONE MODEL FOR EVERY MODE. The kernel knows nothing of Cellular or Rolls. It knows a
// PATTERN FRAME -- the lattice rotated so its rows run along a bearing and stretched
// along them -- a row jitter, a wave, a warp, and for the cumulus deck two ways of
// clearing cloud out of a cell. Each mode is a setting of those:
//
//   Cellular   the controls as they stand
//   Rolls      cells kRollStretch times longer again: cloud streets
//   Waves      the rows turned to run along the wave's crests, cells kWavesStretch
//              longer, and the wave at least kWavesMinAmplitude: cloudlets in bands
//   Chaotic    the lattice warped by a smooth noise and the rows' coherence dropped
//
// So a mode is a starting point rather than a switch that disables sliders, and the
// same four numbers reach the kernel whichever one is picked.
// ===========================================================================

#include "CloudParams.h"

namespace plugin::cloud {

// The mode's settings, named because the classifier and the tests read them too.
constexpr Real kRollStretch       = Real(4);
constexpr Real kWavesStretch      = Real(2);
constexpr Real kWavesMinAmplitude = Real(0.6);
// MEASURED TOO WEAK AT 0.45 over a noise feature 1.7 cells wide: a typical cell moved
// about 240 m of 1800, and the field read as Cellular. At 1.2 over 2.5 the local scale
// swings by about half either way, which bends rows and mixes cell sizes.
constexpr Real kChaoticWarp       = Real(1.2);    // slot widths

// GAP FRACTION IS A THRESHOLD ON A CELL'S CENTRE-NESS, 1 at a lone centre and 0 on the
// seam between two cells (see convOrganize in ConvectionLib.slang): the seams clear out to
// half the width and thin to it. The width is kGapWidthMax x sqrt(Gap Fraction).
//
// THE SQUARE ROOT BECAUSE WHAT SHOWS STARTS LATE. A closed cell's visible top, from above,
// is where centre-ness passes about 0.4; below that are low shoulders nobody sees. SEEN on
// a linear map to 0.9: 0.3 and 0.6 on the slider looked like no gap at all.
constexpr Real kGapWidthMax = Real(1.0);

// THE BEARING AT WHICH THE PATTERN FRAME IS THE WORLD'S: rows along +X. The lattice before
// build 20 had its rows there, so this is the default and the one alignment that leaves
// the field exactly as it was.
constexpr Real kAlignmentIdentity = Real(90);

struct OrganizationResolved {
    // FALSE FOR THE DEFAULTS, and then the kernel takes the path it took before build 20
    // and reads nothing else here. Anything else switches it on, including an Alignment
    // off 90 degrees alone, which turns the lattice.
    bool on = false;

    Real axisX = 1, axisZ = 0;     // unit, world: the direction the rows run
    Real stretch = 1;              // >= 1: a cell's length along the rows over across
    Real coherence = 0;            // 0..1: the jitter across the rows is (1 - this) of full

    Real waveKX = 0, waveKZ = 0;   // CYCLES per metre, across the crests
    Real waveAmplitude = 0;        // 0..1

    Real warp = 0;                 // slot widths: Chaotic's

    // The cumulus deck's only, each 0 for none. A seam clears where a cell's centre-ness
    // is under gapWidth; lacunarity turns the layer towards a sheet with round holes, and
    // is also how wide they are. The kernel holds the hole's shape (convOrganize).
    Real gapWidth   = 0;
    Real lacunarity = 0;
};

// `deck` is true for the cumulus layer, whose cells can have gaps and holes, and false for
// the ice layer, whose generating cells are separate heads and which ignores both.
//
// CLAMPED HERE: AE lets an expression drive a slider anywhere, and a NaN from one must
// come out as a number the kernel's bounds can hold.
OrganizationResolved resolveOrganization(const OrganizationParams& p, bool deck);

// ROWS STRAIGHT ENOUGH TO READ AS STREETS, which the classifier calls radiatus in Rolls
// mode. A threshold on a look, not on physics.
constexpr Real kRadiatusCoherence = Real(0.5);

} // namespace plugin::cloud
