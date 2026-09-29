# Mistytune — build plan

A volumetric cloud and sky renderer for After Effects: an offline path tracer,
not a noise generator. The design spec is
[Cloud — Plugin Design Spec](https://claude.ai/code/artifact/43d5e335-0c43-4144-8ebb-4a3fea1c0630);
this file is how we get there from what is in this repo today.

The spec's own conclusion is the thing to keep in view while reading: **the
physics is not the hard part.** The cost is AE's render model, two GPU backends,
and keeping a 2-second-per-frame renderer interactive enough that anyone
explores it. So this plan front-loads a look-verdict prototype, then spends its
middle on host plumbing, and treats the six generators as the part we already
know how to write.

## Decisions taken here

The spec left these open. They are settled now, and the reasoning is short
enough to keep beside the answer.

| Question | Decision | Why |
| --- | --- | --- |
| Product name | **Mistytune** | Settled. It is the binary name, the match name and the bundle id — see *Identity, once* below |
| Host scope | AE only for v1; keep `src/engine/` host-free so OFX stays possible | Camera integration differs per host and is the part that would fork; nothing else would |
| Headless / standalone | Yes, and **early** — as the test harness, not as a feature | A GPU path tracer that can only run inside AE cannot be golden-imaged, profiled or bisected. The EXR bake feature falls out of it for free |
| VDB export | Internal field is our own GPU brick grid; export converts to OpenVDB at v2 | NanoVDB is a read-side format built host-side, so it is the wrong shape for a field assembled on the GPU every frame and the right shape only for export |
| Classifier | Rule-based over parameter space, in `src/engine/`, unit-tested | Predictable, debuggable, and testable without a GPU. A trained model has no budget and no ground truth yet |
| Terrain input | A driver slot with Top-Down projection, channel = Luminance or Depth | No new input type, no new code path, and it composes with the other three slots |
| Physics tab on install | Earth clamp by default; alien presets in a clearly-labelled *Physics demo* group | The alien skies are the proof the tab is real. They should not be the first thing a realism buyer sees |
| GPU backends | CUDA first (Windows), **one kernel source** cross-compiled; Metal from the same source at Phase 5 | Hand-maintaining two path tracers is the spec's own named risk. See *One kernel source* |
| Minimum GPU | **Measured 2026-09-29: 44.7 M pixel-samples/s on an RTX 2070 SUPER, linear in pixel-samples.** The floor is set by having a CUDA *denoise*, not by the path tracer — see *Still open* below | It is a measurement, not an opinion, and it sets whether Draft mode is genuinely interactive |

Still open, and each needs an answer before the phase that consumes it:

- **OIDN install bulk — MEASURED 2026-09-28, and the question it was asking turns out
  not to be the question.** OIDN 2.5.1, the x64 Windows package: 54 MB zipped, 79 MB
  extracted. The weights are **not a separable file** — there is no `.tza`, no blob, no
  weights directory. They are linked into `OpenImageDenoise_core.dll`, which is
  **48.3 MB** on its own and is required whatever device is used.

  So "bundle the weights or fetch them on first run" has no bundle-the-code-only
  option: the minimum that works is

  | | |
  | --- | --- |
  | `OpenImageDenoise_core.dll` | 48.3 MB — core and weights, unavoidable |
  | `OpenImageDenoise_device_cuda.dll` | 3.1 MB |
  | `OpenImageDenoise_device_cpu.dll` + tbb | 1.3 MB |
  | `OpenImageDenoise.dll` | 0.2 MB — the API shim |
  | **total** | **52.9 MB, verified to load and denoise** |

  Droppable and verified droppable: the HIP device (13.8 MB), the SYCL device and its
  runtime (9.5 MB of `sycl9.dll` and `ur_*`), and the bundled tools. A 52.9 MB set with
  HIP and SYCL removed still enumerates every RT filter and denoises on both CPU and
  CUDA — checked, not assumed.

  **Against a 1 MB plugin that is a 53x multiplier**, so the decision is now a real
  product decision rather than a measurement: ship ~53 MB beside a 1 MB effect, or fetch
  on first run and carry the offline-install and corporate-proxy cases. Building OIDN
  from source with only the RT filter and only the CPU and CUDA devices is the third
  option and the only one that could shrink `core.dll` itself; it costs an ISPC and TBB
  toolchain in the build.

  **DECIDED 2026-09-29: BUNDLE THE 52.9 MB SET.** 53 MB is unremarkable for a VFX plugin,
  and the deciding argument is that the denoiser is **on by default** — so every failure
  mode of fetching (offline install, corporate proxy, a first-run stall, a cache
  directory that is not writable) lands on nearly every user rather than on a minority
  who opted in. Building from source would shrink it and costs an ISPC and TBB toolchain
  that every contributor would then need, which is a poor trade for a one-time download.

  The CPU device stays in the bundle despite the measurement below making it nearly
  useless for Draft — it is 1.3 MB, and it is what a machine with no CUDA falls back to
  for a final render, where 774 ms a frame is irrelevant.

  **THE INTEGRATION MUST BE A RUNTIME-OPTIONAL LOAD ANYWAY**, and that does not change
  with the decision: a missing or mismatched DLL has to degrade to "no denoise" rather
  than to an effect that will not load. Bundling makes that path rarer, not unnecessary
  — a user who prunes the install folder, or an antivirus that quarantines one DLL, is
  exactly the case it exists for.

  Follows the `tools/slang/` pattern: a `cmake/FetchOidn.cmake`, a gitignored directory,
  and the repo carrying the version and the fetch instructions rather than 53 MB of
  binaries. A binary in git is a binary in git forever.

- **Whether Draft mode can be interactive at all — ANSWERED 2026-09-29, and the answer
  is yes on this card and probably yes on a quarter of it.**

  The renderer's cost is **linear in pixel-samples and nothing else**, measured across
  three resolutions and seven sample counts and fitted:

  | | ns per pixel-sample |
  | --- | --- |
  | 1920x1080 | 20.7 |
  | 960x540 | 21.1 |
  | 480x270 | 25.2 |

  **44.7 M pixel-samples/second** on an RTX 2070 SUPER. The 480x270 figure is worse
  because 129,600 pixels is about three waves on a 40-SM card — small frames do not fill
  it, which matters because that is exactly what a Draft preview is.

  A Draft frame, kernel only:

  | | 1 spp | 4 spp |
  | --- | --- | --- |
  | 1920x1080 | 46 ms | 185 ms |
  | 960x540 | 12 ms | 46 ms |

  Add the output transform (**10 ms** at 1080p, threaded) and OIDN's RT HDR filter with
  albedo and normal (**30 ms on CUDA, 774 ms on the CPU**). So 1080p at 1 spp is about
  **86 ms — 12 fps — and 4 spp is 225 ms**, which is scrubbable. Half resolution at
  4 spp is 86 ms again.

  **Minimum GPU follows from the slope.** A card a quarter of this one's throughput
  renders 1080p Draft at 1 spp in 184 ms; with the denoiser that is ~225 ms, still
  usable, and half resolution brings it back under 100 ms. The floor is therefore set
  by *having a CUDA denoise at all* rather than by the path tracer: on a machine that
  falls back to OIDN's CPU device the denoiser is **17x the 1 spp render** and Draft
  becomes denoiser-bound. That is the number that decides whether the CPU device is
  offered at all, or whether no-GPU means no-denoise.

  Superseded figures: this entry previously recorded 0.28 s at 1 sample. Intervening
  work — the majorant tightening, then the transmittance table — moved it; see
  PROGRESS.md for the A/B of each.

  **BUILD 13 MADE A SAMPLE 2.2x DEARER AND WORTH MORE THAN THREE OF THE OLD ONES.**
  The continuous camera-ray estimator (see *Denoiser flicker* below), measured back to
  back on one binary by the same fit, at the CLI's default scene:

  | | ns per pixel-sample | 1080p, 1 spp | 1080p, 4 spp | 960x540, 1 spp |
  | --- | --- | --- | --- | --- |
  | delta tracking (before) | 12.7 | 26 ms | 105 ms | 7 ms |
  | continuous (build 13) | 27.6 | 57 ms | 229 ms | 15 ms |

  With the transform and a CUDA denoise that is about **97 ms at 1080p, 1 spp** —
  still interactive — and it is better on every measure than the old estimator's
  3 spp. **The old estimator's 12.7 ns is itself below the 20.7 recorded above**, by
  the same method with the same intercept. That gap is not explained, and the ratio is
  the number to carry until it is.


## Where we are starting from

This repo is a working copy of **Gravitune**, a Jolt-physics AEGP that poses and
bakes rigid and soft bodies in After Effects. None of its simulation is relevant
to clouds. Its *scaffolding* is worth a great deal, and it is the reason to start
here rather than from the bare template.

**Keep, unchanged or nearly so:**

| Asset | What it buys us |
| --- | --- |
| `docs/HOST-NOTES.md` | Twenty-odd AE behaviours that each cost real debugging time. Read it before Phase 1, not during |
| `CMakeLists.txt` version-from-`Build.h` scheme | One source for the version. AE caches registration against it, so a second hand-edited copy is how a binary claims a version it does not contain |
| `cmake/EffectFlags.cmake` | Makes an `out_flags` mismatch a compile error on our machine instead of a load failure on someone else's |
| `cmake/AESDK.cmake`, `AEPiPL.cmake`, `AEPlugin.plist.in` | SDK discovery, resource compilation, macOS bundle classification and ad-hoc signing |
| `build.ps1`, `build.sh`, `package-mac.sh` | Configure/build/test/install/package, with AE located rather than assumed |
| `src/engine` / `src/ae` split, enforced by CMake | The engine builds and tests with no Adobe SDK present. Keep this absolutely |
| `tests/unit/TestFramework.h`, `TestMain.cpp` | A working test loop measured in milliseconds |
| `src/ae/AEBridge.h`, `DiagLog.h`, `EffectCommon.h`, `Params.h` | Param checkout, pixel-format probing, diagnostics gated on an env var |

**Two pieces of Gravitune's engine survive on merit, not sentiment:**

- `src/engine/Contour.{h,cpp}` — marching-squares ordered contours out of an
  alpha channel. That is exactly the front half of pareidolia: matte → ring →
  curvature extrema → medial axis. Reuse as-is.
- `src/engine/Fingerprint.{h,cpp}` and `AutoSolveGate.{h,cpp}` — "would solving
  now give a different answer?", answered by a hash instead of a solve, with a
  `sizeof` tripwire that breaks the build when a new field goes unhashed. That is
  precisely the mechanism the spec's last AE-plumbing row demands: camera-only
  changes must not rebuild the field. Retarget the hashed structs, keep the
  tripwire.

**Delete in Phase 1:** `cmake/Jolt.cmake` and the Jolt dependency; the AEGP
(`AegpMain.cpp`, `Discovery.cpp`, `Bake.cpp`, `PoseWriter.cpp`, `SoftWriter.cpp`,
`Posing.cpp`, `SolveDriver.cpp`, `StreamOps.cpp`, `AlphaTrace.cpp`, `Outline.cpp`,
and the three carrier effects); the rigid/soft solver (`World`, `Body`, `Hull`,
`Trace`, `Decompose`, `SoftMesh`, `SoftContact`, `PoseCache`, `Scene`, `Force`,
`KeyReduce`, `LookupExpr`, `ExprNumber`, `WorldNullGate`) and their tests.

**The PiPL goes too.** Gravitune needed it because an AEGP has no
self-registration path. Mistytune is a plain effect, and effects self-register on
AE 2023+ through `PluginDataEntryFunction2` / `PF_REGISTER_EFFECT_EXT2`. Dropping
the PiPL removes a whole class of version-mismatch failure. `EffectFlags.cmake`
stays, now feeding only the `static_assert` in the generated identity header.

### Identity, once

`cmake/PluginConfig.cmake` is the only file that names the plugin. Rewrite it in
Phase 1: target `Mistytune`, match name `Mistytune`, category `Mistytune`, bundle
id `com.mistytune.mistytune`, env prefix `MISTYTUNE`, log `mistytune.log`.

**The match name is permanent from the first build anyone else installs.** AE
stores it in every project file that uses the effect and finds the effect by it at
load time; changing it after ship drops the effect from every saved comp and takes
the user's sky settings with it. It is free to change now and never again, so it
is fixed in Phase 1 and reviewed once more before the v0.5 hand-out.

## Target shape

```
proto/            standalone GLSL raymarcher — Phase 0, kept after as the look reference
src/kernel/       the renderer: ONE cross-compiled kernel source
                  (transport, phase functions, atmosphere, generators)
src/engine/       host-free C++: parameter model, classifier, curve eval, feature
                  extraction, field-cache fingerprint, preset tables.
                  No AE headers, no GPU headers. Unit-tested.
src/ae/           the SmartFX GPU effect: params, checkout, GPU device setup,
                  render dispatch, camera, caching
src/cli/          mistytunec — headless renderer: golden images, profiling, EXR bakes
tests/unit/       engine tests (fast, no SDK, no GPU)
tests/golden/     fixed-scene renders through src/cli, compared with tolerance
```

The `src/engine` / `src/ae` rule Gravitune enforces extends to a second rule:
**`src/kernel` never includes an AE header either.** The effect hands the kernel a
plain struct of physics constants and a camera; the CLI hands it the same struct.
That is what makes golden images possible.

### One kernel source

Write the transport, phase functions, atmosphere and generators once, in
[Slang](https://shader-slang.org), and compile that source to PTX for CUDA and to
Metal for macOS. Slang is a superset of HLSL with modules and generics, and it
targets CUDA, Metal, SPIR-V, HLSL and GLSL from one input.

The alternative — AE's own sample convention of parallel `.cu` and `.metal` files
kept in sync by hand, as `sdk/.../Examples/Effect/SDK_Invert_ProcAmp` does — is
tolerable for a fifty-line invert and untenable for a path tracer with six
generators. (That sample's `.chlsl` is the Premiere DirectX path; out of scope.)
Read its `.cpp` anyway: it is the reference for `PF_Cmd_GPU_DEVICE_SETUP`,
`PF_GPUDeviceSuite1` and dispatching into a device AE owns, which is the part we
do need to copy.

If Slang proves a bad bet in Phase 2, the fallback is the same single source
behind a macro shim — and that decision point comes before any generator is
written, not after six.

## Phases

Effort figures are the spec's own, kept so we notice when reality disagrees.

### Phase 0 — Prototype, and a verdict on the look (1–2 weeks)

No C++, no AE, no UI. A standalone GLSL raymarcher in `proto/`, tunable in a
browser, containing the parts that decide whether the approach works at all:

- null-collision (delta/ratio) tracking through a density field
- many-bounce brute-force multiple scattering
- the Jendersie–d'Eon (2023) Draine-based Mie approximation for liquid
- a precomputed Bruneton-style atmosphere: sun transmittance, skylight ambient,
  aerial perspective, with cloud shadows cast into the medium
- the **ice / fallstreak generator**: generating cells, habit-dependent fall
  speed, a shear profile curve, sublimation — with detail **advected** along the
  flow and re-seeded at the cells, never sampled from noise
- blue-noise-offset progressive accumulation
- AgX, linear float, real EV exposure

**Ice first, per the spec.** Optically thin, near single-scatter, cheapest to
render, smallest parameter set, and the look no existing tool reaches.

**Exit criterion, stated before we start so it cannot move:** side by side with
reference photographs of *cirrus fibratus* and *uncinus*, backlit, the prototype
reads as photographed, and the hook is visibly the shear curve rather than a
sculpted shape. If it is not there, we fix it here, where an iteration costs
seconds. Nothing downstream is cheaper to change than this shader.

### Phase 1 — Re-scaffold, and a GPU pixel in AE (1 week)

Strip Gravitune per the lists above; rewrite `PluginConfig.cmake`; drop Jolt and
the PiPL. Then stand up the smallest real GPU effect: one `Mistytune` effect,
`PF_Cmd_SMART_RENDER` plus `PF_Cmd_SMART_RENDER_GPU`,
`PF_OutFlag2_SUPPORTS_GPU_RENDER_F32`, `PF_Cmd_GPU_DEVICE_SETUP`/`SETDOWN`, and a
CUDA kernel that fills the output with a parameter-driven colour.

Exit: installs into AE; renders correctly at 8, 16 and 32 bpc (16-bit channels run
0..32768, not 65535) and at reduced resolution; `EffectFlags.cmake`'s
`static_assert` passes; `build.ps1 -Test` green; the diagnostic log names the GPU
device AE handed us.

### Phase 2 — The renderer, one layer, in the host (3–4 weeks)

Port the Phase 0 shader into `src/kernel/` as Slang, and build `src/cli/` in the
same week so the kernel is runnable and golden-imaged outside AE from the start.
Then the host side: progressive accumulation across chunked launches, Intel Open
Image Denoise on the accumulated buffer, the 3D camera via
`AEGP_GetEffectCameraMatrix`, and the field cache keyed on the fingerprint.

Exit: a single ice layer renders in AE, matches the CLI's golden image, survives a
camera move without rebuilding the field, and Draft mode's measured
samples/second is written down — which is what finally answers the minimum-GPU and
interactivity questions.

### Phase 3 — v0.5: convection, organization, two layers (1–2 months)

Cellular convection with **cell polarity** as its hero parameter (open cells →
scattered fair-weather cumulus; closed → a solid stratocumulus deck). The
Organization group — waves, rolls, alignment coherence, lacunarity, gap fraction —
applying to any generator. Two layers with **inter-layer shadowing rendered, not
faked**, in one shared atmospheric medium. The classifier readout. The flat
condensation-level base, self-aerial-perspective, and the three sun-camera presets
with **backlit** as default.

Exit: the two-layer default preset (Cu + thin Ci, backlit) is something we would
show someone.

### Phase 4 — v1.0 content (2–3 months)

The remaining four generators. Phase including Mixed, with the liquid-to-ice
transition inside deep convection, which is what produces anvils. The ice
phase-function library indexed by habit and orientation — the thing that produces
22° and 46° halos, sundogs and pillars, and that a spherical-droplet model cannot.
The four driver slots and their low-resolution control texture. Scene integration
(holdout, composite, displace-volume). Pareidolia. The six v1 supplementary
features, **mamma first** as the spec's highest value-per-effort item. The physics
tab with its Earth / Earth-like / Unbound clamp. The ten presets. AgX and the
separate output passes, tonemap defaulting off.

### Phase 5 — Metal, packaging, hardening (3–4 weeks)

Compile the same kernel source to Metal; universal bundle; `eFKT`/`FXTC`
classification and inside-out ad-hoc signing (`package-mac.sh` already does this);
rewrite `INSTALL.md` and `README.md`; determinism and MFR soak tests.

### Out of v1 scope

Fluctus with a genuine shear-instability solve, arcus, asperitas, the supercell
kit, nacreous and noctilucent with their sun-below-horizon illumination mode, the
variations grid, terrain-driven orographic placement, VDB export.

The **variations grid** deserves a note: it is the spec's exploration loop, and
exploration is the product. It is v2 only because nine thumbnails per re-roll
needs Draft-mode numbers we will not have until Phase 2. If those numbers are
good, it moves forward.

## The plumbing that actually costs

Each of these has bitten this codebase's predecessor or is named in the spec as a
project-killer. Listed with the mitigation and, where there is one, the tripwire
that makes the failure loud.

**Windows TDR will kill a long kernel.** The display driver's default timeout is
about two seconds; a 2-second-per-frame path trace in a single launch sits exactly
on it, and the failure is a driver reset, not a slow render. Progressive
accumulation is therefore not only a quality feature: **one launch per sample
batch**, sized so no single launch approaches the timeout, with the accumulation
buffer persisting between them.

**Abort and progress between chunks.** Check AE's abort and report progress
between accumulation launches, or the host looks frozen for the whole frame and
the user kills it.

**MFR safety is a promise about the render path.**
`PF_OutFlag2_SUPPORTS_THREADED_RENDERING` tells AE it may call render from any
thread, and several frames will be in flight in one process. So: no shared mutable
solver state, a field cache that is read-mostly with explicit locking, and nothing
on the render path that touches host streams. Gravitune's `EffectFlags.cmake`
records at length how this flag got blamed for a bug it did not cause — read it
before diagnosing anything here.

**Determinism across passes and workers.** Motion blur renders one frame several
times and MFR renders frames on different workers, so seeds come from
`(frame, sample index, pixel)` and nothing else — never a clock, a thread id, or a
counter shared between launches. The tripwire is in `tests/golden/`: the same
inputs rendered twice, and rendered again with a different worker count, must
compare identical.

**Denoiser flicker is a real risk.** OIDN is not temporal, and per-frame denoising
of a stochastic image is how animation gets shimmer. Mitigations in the order to
try them: per-pixel blue-noise offsets stable across frames, albedo and normal
auxiliary buffers, prefiltering, and raising spp before reaching for anything
temporal. Judge it on a moving 48-frame render, never on a still.

**Blue-noise offsets were tried on 2026-09-29 and do nothing for this renderer.** They
were built through the shipping kernel and swept from 0 to 16 draws, and the error
stayed white. Under delta tracking, whether a camera ray scatters depends jointly on
ten or more draws, beyond what per-dimension dithering can shape. The noise comes from
the estimator's yes-or-no, not from the sampler. Aux buffers only help if their
coverage feature comes from a continuous estimate too. See PROGRESS.md.

**The continuous camera-ray estimator shipped in build 13, and it is the mitigation
that worked.** It estimates how likely the camera ray is to scatter by ratio tracking
instead of a coin toss, and asks for the sun from one point resampled along the ray
(`cameraSegmentSun` in BounceLib.slang). Measured at 1 spp denoised: flicker down 42%,
RMSE down 42%, 78% of the true fine detail kept against 53%. It costs 2.2x per sample
and beats the old estimator at 3 spp on every measure. Unbiased, and slang.bounce
holds it to the same closed form. **Still to be judged on a moving 48-frame render in
the host**, which no metric here replaces.

**Camera-only changes must not re-solve.** The cache is keyed on a fingerprint of
every non-camera input, with Gravitune's `sizeof` tripwire kept so that adding a
parameter without hashing it breaks the build. The spec is blunt that this row is
the difference between a plugin people use and one they abandon.

**Floating-point contraction stays off.** `-ffp-contract=off` is already in
`CMakeLists.txt` and it is not a micro-optimisation knob: clang fuses `a*b + c*d`
into an FMA and MSVC does not, so removing it changes render output and breaks
cross-platform golden images.

## Parameters and UI

Sixty-plus parameters across four layers is the spec's own worry, and AE makes it
worse in a specific way: **parameter indices are positions, AE stores values by
position, and the UI order is the index order.** Appending is the only safe
change; inserting a control into layer 1 later would otherwise put it on screen
after layer 4.

So generate the whole parameter table from one declarative list in a single header
— enum, `PARAMS_SETUP` and checkout all from the same rows. Lay out per-layer
blocks contiguously and **reserve a few hidden spare slots at the end of each
block**, because that is the only way to add a layer-local control later without
either reordering or landing it in the wrong place. Parameter IDs are a separate
namespace and are never reused.

Two readouts are static text, which AE has no control for. Use the documented
pairing: the parameter's *name* carries the text, rewritten through
`PF_UpdateParamUI`, with `PF_PUI_STD_CONTROL_ONLY` and `PF_ParamFlag_SUPERVISE`,
which are mandatory together. Those two are

- the **classifier readout** naming what the user has made, and
- the **measured pareidolia legibility** number from the shape-context matcher,
  which is what lets Decay be specified in real units and lets the user keyframe
  perceived legibility rather than input strength.

`PF_UpdateParamUI` cannot change a valid range — only AE re-running `PARAMS_SETUP`
after a version change can — so ranges go in as wide as the maths allows from the
start. A range that is too narrow silently flattens expression-driven and keyframed
values, which presents as a broken expression rather than as a clamped parameter.

**The shear profile curve editor is unreferenced work.** It is the hero control of
the ice generator and it *is* the streak shape, so a slider will not do; the SDK
ships no curve control and no sample of one (`Paramarama` is the parameter-type
reference to read first). Plan: ship Phase 2 with a small fixed set of
height-indexed sliders, smoothly interpolated, and build the real editor as an
arbitrary-data parameter with custom UI during Phase 4 — sized honestly as its own
task, not as a widget.

## Testing

Three tiers, and the point of the split is that the first two need neither AE nor
a GPU.

1. **`tests/unit/`** — the engine: classifier rules, curve evaluation, contour and
   curvature-extrema extraction, medial axis, fingerprint coverage, preset tables,
   parameter-range maths. Milliseconds, no SDK, run on every build.
2. **`tests/golden/`** — fixed scenes rendered through `src/cli/`, compared with
   tolerance. Catches kernel regressions, cross-platform float divergence and
   non-determinism, including the same-inputs-twice and differing-worker-count
   comparisons.
3. **In-host checks**, scripted but judged by eye: all three bit depths, both
   resolutions, a camera move that must not re-solve, an MFR soak, and a 48-frame
   animation watched for denoiser shimmer.

Diagnostics stay behind `MISTYTUNE_DIAG=1`, set before AE launches. Logs interleave
under MFR, so diagnose on a single still frame.

## First week

1. Read `docs/HOST-NOTES.md` end to end. It is the cheapest hour in the project.
2. Start `proto/`: null-collision tracking, the Jendersie–d'Eon phase function, the
   Bruneton atmosphere, progressive accumulation, AgX. No generator yet.
3. Add the ice generator to the prototype, with advected detail and a shear curve,
   and get the Phase 0 verdict against reference photographs before writing any
   C++.
4. In parallel, since it blocks nothing: rewrite `cmake/PluginConfig.cmake` for
   Mistytune, and delete Jolt, the AEGP and the rigid/soft solver, so Phase 1
   starts from a clean tree.

The Phase 0 verdict is the gate. Everything after it is engineering; it is the only
step that can still tell us the premise is wrong.
