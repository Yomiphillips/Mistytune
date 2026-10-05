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
// MINOR 6, BUILD 14 -- THE CUMULUS LAYER. Cellular convection with cell polarity, a
// flat base at the condensation level, and cauliflower billows, rendered as a second
// medium beside the cirrus -- so the cirrus shadows it, rendered rather than faked.
// The droplets' diffraction lobe is delta-Eddington truncated and their Draine lobe is
// sampled exactly; each was a firefly source, measured. PROGRESS.md carries it all.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST CHANGED: a Cumulus group was inserted between
// Ice and Physics, and the ice group's reserved spare became its on/off switch.
// MINOR 7, BUILD 15 -- THE CAMERA TRAVELS, AND ONE CLOUD CAN BE PLACED. Reported from
// the host: a close, looking-up shot of one cumulus could not be framed, because only
// the comp camera's rotation reached the renderer. Camera Travel converts its position
// into metres. The Hero Cloud puts a tower where the user says, with the field or alone.
// Billows now push off the walls as well as the crowns, which is what turned tall
// towers from smooth pillars into cauliflower; it costs about 1.8x on the default field,
// measured, and Render Distance (default 40 km) and the layer's Draft switch (1 sample)
// are the offsets. PROGRESS.md carries the numbers.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST CHANGED: a Camera group was inserted after Sun
// and Sky, and six hero rows were inserted into the Cumulus group before its spares.
// MINOR 8, BUILD 16 -- THE CAMERA ORBITS THE CLOUD. Reported from the host: framing with
// the comp camera left the user "lost". It moves in pixels, pivots on the ground under
// the cloud, and AE's viewer shows nothing to aim at. The new default camera, Orbit the
// Hero, circles Hero Position X/Z at a Distance in metres and always looks at the cloud;
// Tilt, Pan and Roll offset that aim. The comp camera is still there, unchanged, behind
// the Camera popup. The hero now defaults to With the Field so there is one to orbit.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST CHANGED: eight rows were inserted into the
// Camera group, and a default changed.
// MINOR 9, BUILD 17 -- THE AIR IN FRONT OF THE CLOUD, THE SUN THAT FOLLOWS THE LENS, AND
// A NAME FOR THE SKY. Aerial perspective on the clouds (missing since build 9) and their
// shadows in that air, which the Cloud Shadows In Air checkbox had promised since Phase
// 1 without anything reading it. The sky's own march is fixed on the way: it dimmed each
// step by all of its own depth rather than half, and was 16.5% dark at the horizon. Sun
// Placement puts the sun relative to the camera, backlit by default. The classifier
// readout names the sky at the top of the panel.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST AND THE FLAGS CHANGED: the readout moved to
// the top, Sun Placement was inserted at the top of Sun and Sky, thirty controls gained
// PF_ParamFlag_SUPERVISE, and out_flags gained PF_OutFlag_SEND_UPDATE_PARAMS_UI.
// BUILD 18 -- THE CLOUDS' SHADOWS IN THE AIR COME FROM A MAP. Build 17 cast one shadow
// ray per camera ray, which cost 20 to 43% of the frame and speckled the sky. A deep
// shadow map per layer is now built once per frame on the GPU (up to about 20 ms) and every
// step of the air reads it. Measured: the air's shadows now cost nothing measurable, and
// the sky's noise at 1 spp denoised is halved. PROGRESS.md carries the numbers.
//
// STILL MINOR 9: no parameter or flag changed.
// BUILD 19 -- THE CLOUDS' SHADOWS FALL ON THE GROUND, AND THE GROUND SEES THE SKY. Build
// 18's maps are read where a ray lands on the ground, and they are built whenever the sky
// is on, so Cloud Shadows In Air off keeps the ground's. Shadowed ground then came out
// black: since Phase 1 the ground had only the sun. It now also has the sky dome's light,
// integrated once per change of the sky (about 3 ms).
//
// STILL MINOR 9: no parameter or flag changed.
// MINOR 10, BUILD 20 -- THE ORGANIZATION GROUP. How each layer's cells are arranged:
// Cellular, Rolls, Waves or Chaotic; Aspect Ratio, Rows Along and Row Coherence; a wave
// field; and for the cumulus deck Gap Fraction (perlucidus) and Lacunarity (lacunosus).
// The classifier names the varieties they make. At the defaults the kernel takes the
// path it took before build 20, and the goldens did not move.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST CHANGED: an Organization topic was inserted
// into the Ice group and one into the Cumulus group, each before its spares.
// MINOR 11, BUILD 21 -- PAREIDOLIA. Another layer's alpha or luminance becomes the hero's
// silhouette: a signed distance map built on the host, stood up facing the camera,
// inflated with rounded rims, and billowed. Decay melts it back into the ordinary hero.
//
// A MINOR BUMP FOR BOTH REASONS: a Pareidolia topic was inserted into the Cumulus group
// before its spares, and out_flags LOST PF_OutFlag_PIX_INDEPENDENT, which stopped being
// true the moment the effect read another layer.
// MINOR 12, BUILD 22 -- HERO CONNECTION. The hero stops looking set down on the field:
// turrets on its shoulders, a flanking line of smaller towers stepping down into the
// wind, the field's updraft sinking under the group, and the hero drifting with the wind.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST CHANGED: Hero Connection and Hero Drifts With
// Wind were inserted after Hero Variation, before the Organization topic.
// MINOR 13, BUILD 23 -- MAMMA. Pouches hanging from the cumulus layer's underside wherever
// it has cloud overhead: smooth hemispheres on a lattice of their own, creased between,
// sagging and lifting over half a cell's life.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST CHANGED: a Mamma topic was inserted after the
// cumulus Organization group, before Pareidolia.
// MINOR 14, BUILD 24 -- PILEUS AND VELUM. The hero's cap and veil: a smooth thin lens over
// its crown and a wide thin veil it rises through, both thinner than the tower.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST AND THE FLAGS CHANGED: a Pileus and Velum topic
// was inserted after Mamma, before Pareidolia, and out_flags gained
// PF_OutFlag_NON_PARAM_VARY. Without it AE played back one frame of an effect with nothing
// keyframed, so nothing drifted.
// BUILD 25 -- FASTER. The camera ray is walked once rather than twice, the GPU traces a
// frame one bounce per launch over the paths still alive, and the layer's Draft switch
// adds a shadow hand-off: a shadow ray walks the cloud near it exactly and reads the rest
// of its way to the sun from the shadow map. Against build 24, at 1 spp on an RTX 2070
// SUPER: Best 26 to 34% less time at 1080p, Draft 2.5 to 3x faster. Best's picture is the
// same up to its noise; Draft's cast shadows soften by about a texel. PROGRESS.md carries
// the numbers.
//
// STILL MINOR 14: no parameter or flag changed.
// MINOR 15, BUILD 26 -- RENDER QUALITY: THE EFFECT'S OWN DRAFT/BEST SWITCH. Reported from
// the host: "Just setting Draft in AE does not help in any way. Ideally the plugin should
// have its own draft/best option." The log never once saw the layer switch at Draft. Draft
// now traces one path per 2x2 block at one sample, with the shadow hand-off and a full
// denoise, and leaves Max Bounces alone so it is as bright as Best. Against Best at the
// same size: 3.4 to 3.9x less trace time at 480x270, 4.2 to 6.3x at 1920x1080.
//
// A MINOR BUMP BECAUSE THE PARAMETER LIST CHANGED: Render Quality was inserted directly
// under the classifier readout, outside every group.
// BUILD 27 -- PAREIDOLIA RELIEF. A second layer, a depth map, pushes the shape's face
// towards the eye: brighter is nearer, stretched to Relief Depth, blurred by Relief
// Softness, faded in from the silhouette's edge. A figure now reads from forms inside its
// outline that the sun can model, not from the outline alone. The back stays flat, and the
// clouds stay water: relief moves where the water is, never what it is. With no Relief
// Source the shape is build 21's to the bit.
//
// THE PARAMETER LIST CHANGED -- Relief Source, Relief From, Relief Depth and Relief
// Softness were inserted in the Pareidolia group, before its spares -- BUT STILL MINOR 15.
// AE's packed version gives the minor FOUR BITS, so 15 is the last one: minor 16 was
// masked to 0 and the build failed on EffectCommon.h's version assert. The build number
// is what tells AE its cached registration is stale (CHANGELOG.md), so it carries every
// change from here; CMakeLists.txt now refuses a minor past 15 in so many words. The next
// minor is the major's business: 1.0 is PLAN.md's v1, not a counter.
// BUILD 28 -- RELIEF THAT KEEPS THE FEATURES. Reported from the host with a three-quarter
// face's depth map: "just something sculpted like a head. don't see nose or any face
// feature". Two causes, both build 27's. The lift faded in from the outline over the relief's
// whole height -- 1.1 km on a 2.2 km face -- which kept 38% of the depth map and lost the
// nose, which sits on the outline; it now fades over a quarter of the rims' radius and keeps
// 91%. And the head's own turn spent the whole depth range: RELIEF DETAIL (new, default 0.5)
// takes that much of the large form away before the map is stretched to Relief Depth.
//
// THE PARAMETER LIST CHANGED: Relief Detail was inserted after Relief Depth. Still minor 15.
// BUILD 29 -- LOCAL LIGHTS. Asked for from the host: "making the clouds work with AE light or
// layers (in case I want to use saber lighting for thunder)". The comp's point, spot, parallel
// and ambient lights now light the clouds, and so does a Light Layer -- Saber on a solid --
// as a glowing sheet at the hero's depth. Both go through the sun's own next-event estimator:
// a shadow ray through the cloud to the light, the phase function, the albedo. The clouds stay
// water: a light adds illumination and never changes the medium. With no lights a frame is
// build 28's to the bit.
//
// THE PARAMETER LIST AND THE FLAGS CHANGED: a Lights topic was inserted after Camera, and
// out_flags2 gained PF_OutFlag2_I_USE_3D_LIGHTS, without which AE would not re-render when a
// light moves. Still minor 15.
// BUILD 30 -- SCENE INTEGRATION: HOLDOUT AND COMPOSITE. The spec's "Composite interleaves
// cloud with geometry per-pixel". A Depth Pass layer -- an AI depth map of the footage, or a
// Z pass -- stops every camera ray at the building it shows: cloud nearer than the building
// is drawn in front of it, cloud behind it is not drawn. The geometry comes out transparent,
// with alpha from the clouds' own transmittance in front of it, and Composite lays the result
// over the layer the effect is applied to. With no depth pass a frame is build 29's to the bit.
//
// THE PARAMETER LIST CHANGED: a Scene Integration topic was inserted after Lights. Still
// minor 15.
// BUILD 31 -- THE CLOUDS ALONE. Asked for from the host: "a hero cloud alone without the sky
// etc, so I can use with other layers", faster, and "the option to switch off or on the sun.
// But still have it affect the cloud. Just not show". BACKGROUND: TRANSPARENT stops every
// camera ray that no depth pass stops at geometry at infinity, and build 30's holdout gives
// the clouds premultiplied with alpha 1 - T; a ray that met no cloud skips its air, and the
// denoise runs only on the box round the alpha. SHOW SUN off hides the disc from the camera
// and nothing else. With both at their defaults a frame is build 30's to the bit.
//
// THE PARAMETER LIST CHANGED: Background was inserted under Render Quality, Show Sun after
// Sun Intensity. Still minor 15.
#define PLUGIN_MAJOR 0
#define PLUGIN_MINOR 15
#define PLUGIN_BUILD 31
