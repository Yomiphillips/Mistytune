#pragma once

// THE VERSION. This header is the single source of it -- the effect reports it to
// After Effects, CMake reads it for project(VERSION) and so for the macOS
// Info.plist, and the packaging scripts name the ZIP from it.
//
// A SECOND HAND-EDITED COPY IS HOW A BUNDLE CLAIMS A VERSION IT DOES NOT CONTAIN,
// so there isn't one.
//
// AFTER EFFECTS CACHES AN EFFECT'S REGISTRATION AGAINST THE BINARY -- version,
// out_flags, out_flags2, the parameter list, the effect name, the match name and
// the category are all read once and remembered. Change any of them without a new
// version and AE either ignores the change or refuses to load with a mismatch
// error whose text names the wrong field:
//
//     effect "Mistytune" has version mismatch.
//     Code version is 1.0 and PiPL version is 1.0. (8001e)
//
// Both halves print 1.0 because the dialog shows only major.minor and the
// difference is in the build field.
//
// KEEP THIS HEADER FREE OF ANYTHING BUT THESE MACROS. CMake parses it with a
// regex before any compiler runs.

// ---------------------------------------------------------------------------
// WHEN TO BUMP WHAT.
//
// PLUGIN_BUILD -- every time you install a build into After Effects. It is what
//   tells AE its cached registration is stale, and it is what identifies which
//   binary AE is actually holding in the "build N loaded" diagnostic line.
//
// PLUGIN_MINOR -- whenever out_flags, out_flags2 or THE PARAMETER LIST change.
//   The flags because AE reports "global outflags2 mismatch" otherwise. The
//   parameter list because PARAMS_SETUP is only re-run after a version change,
//   and a parameter's VALID RANGE can be changed by nothing else -- not even
//   PF_UpdateParamUI. A range left too narrow silently flattens expression-driven
//   and keyframed values, which presents as a broken expression.
//
// PLUGIN_MAJOR -- the milestones in PLAN.md: 0.x is pre-hand-out, 1.0 is the
//   content-complete release.
// ---------------------------------------------------------------------------

// 0.1 -- Phase 1. The scaffolding is Mistytune's, the parameter model is real,
// and the renderer is a placeholder analytic sky proving the plumbing. Nothing
// has been handed to anyone, so the parameter layout is still free to change.
// MINOR STAYS AT 3: out_flags, out_flags2 and the parameter list are untouched. The
// output conversion moved into src/engine/OutputConvert.h and toImageView's fallback
// narrowed, both of which are internal to the render path.
//
// BUILD 7 -- the atmosphere's inner sun march became a precomputed transmittance
// table. It is the only change since build 6 that moves a pixel: 1.47x faster, and
// more accurate at low sun, where the 8-step quadrature it replaces was worst. The
// diagnostic log also names the working-space colour profile now.
//
// STILL MINOR 3: no parameter was added, no flag changed. The table reaches the
// kernel as a pointer in RenderRequest, which AE never sees.
#define PLUGIN_MAJOR 0
#define PLUGIN_MINOR 3
#define PLUGIN_BUILD 7
