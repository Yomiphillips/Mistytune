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
//
// MINOR 4 -- THE ICE GROUP. Thirty parameters were inserted between Sun and Sky and
// Physics, which is a PARAMETER LIST change and therefore a minor bump by the rule
// above. This is not bookkeeping: PARAMS_SETUP is re-run only after a version
// change, so shipping these controls at minor 3 would install a binary that renders
// exactly as build 7 did and shows not one of the new sliders. That failure looks
// like the controls were never written.
//
// INSERTED RATHER THAN APPENDED, which the same bump is what makes safe. AE stores
// values by POSITION, so every parameter after index 13 has moved; a project saved
// by build 7 would read its Physics values out of the shear profile. Nothing has
// shipped and nothing has been handed to anyone, so there is no such project -- and
// PLAN.md fixes the layout at the v0.5 hand-out, after which this is never free
// again.
//
// BUILD 8 -- the ice generator's parameters reach the panel for the first time. The
// kernel has marched this field since build 6; until now `field.ice` was never
// assigned from a control, so every render used the struct's defaults.
//
// BUILD 9 -- the sky is asked from where the path actually is. skyRadiance() took the
// origin altitude as the constant 2.0, which was right while a camera ray was its only
// caller and wrong from the moment the bounce loop began asking it for ESCAPED paths:
// every one of them got the sky as seen from two metres. It moves pixels, the three
// goldens were re-blessed on the evidence, and PROGRESS.md carries the numbers.
//
// STILL MINOR 4: no parameter was added and no flag changed. Observer Altitude is a
// ViewParams field with no control, so nothing in the panel moved -- see PROGRESS.md,
// which records that it is now honoured and still unreachable.
// BUILD 10 -- the Denoise checkbox does something. It had been checked out, mapped to
// QualityParams::denoise and hashed into the fingerprint since Phase 1 with nothing
// reading it; Open Image Denoise is now loaded at runtime and runs over the finished
// frame. The DLLs install beside the .aex, and a plugin without them renders
// undenoised and says so rather than failing to load.
//
// STILL MINOR 4: no parameter was added and no flag changed. The checkbox was already
// there -- that was the problem.
// MINOR 5, BUILD 11 -- Denoise Amount. Reported from the host as "too smooth", and the
// report is right: measured at 4 spp against a 512-spp render of the same frame, a full
// denoise leaves 33% of the fine structure the converged image has. The control is a
// blend, defaulting to 0.8 because that is where the detail matches.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST CHANGED -- a reserved SPARE became a real
// control. The ID did not move and no index shifted, so no saved project is rewired;
// but PARAMS_SETUP only re-runs after a version change, so without this the slider
// would not appear at all.
// BUILD 12 -- the accumulator cache is live. A change to a resolve input only --
// Exposure, AgX, the Denoise switch, Denoise Amount -- rebuilds the frame from what is
// already accumulated instead of tracing it again: about 10 ms against 3.9 s at
// 1920x1080 and 64 spp. The GPU accumulator is frame-sized so a frame survives the
// render that made it; the cache is thread_local, one per engine, and credits only a
// frame finished start to end on one engine. Every other path traces, as before.
//
// STILL MINOR 5: no parameter or flag changed. Denoise and Denoise Amount moved from
// the sampling hash to the resolve hash, which AE never sees.
// BUILD 13 -- the sun along the camera ray is estimated continuously. Delta tracking
// brought the sun back only for the few rays that happened to scatter, which is what
// made a low-spp cirrus a field of bright dots and what the denoiser shimmered on.
// Measured at 1 spp denoised: flicker down 42%, RMSE down 42%, 78% of the true fine
// detail kept against 53%, for 2.2x the time per sample -- better than the old
// estimator at 3 spp on every measure. It moves every noisy pixel, and the three
// goldens were re-blessed after both estimators were shown to converge on the same
// images. PROGRESS.md carries the numbers.
//
// STILL MINOR 5: no parameter or flag changed.
#define PLUGIN_MAJOR 0
#define PLUGIN_MINOR 5
#define PLUGIN_BUILD 13
