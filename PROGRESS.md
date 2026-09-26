# Progress

Tracked against `PLAN.md`. Newest first.

---

## 2026-09-26 — Phase 0 prototype built; Phase 1 re-scaffold done

### Where the project actually stands

| Phase | State |
| --- | --- |
| **0 — prototype and look verdict** | Prototype **built and running**. The verdict itself is **not given** — it needs a human eye against reference photographs on real hardware. |
| **1 — re-scaffold, GPU pixel in AE** | Scaffolding **done**. Effect builds, registers, renders. **Not yet installed into After Effects or verified in-host.** CUDA path **unbuilt** — no toolkit on this machine. |
| 2 and later | Not started. |

**The single next action is the Phase 0 verdict.** Open `proto/index.html`, press
*Backlit* then *Cirrus uncinus*, and compare against photographs. Everything after
that is engineering; this is the only step that can still say the premise is
wrong.

---

### Phase 0 — `proto/`

A single self-contained WebGL2 page, no build step and no dependencies. It
contains every item `PLAN.md` lists for Phase 0:

- null-collision (delta / ratio) tracking through the density field
- many-bounce brute-force multiple scattering
- the Jendersie–d'Eon (2023) Draine-based Mie approximation for liquid
- a precomputed Bruneton-style transmittance table, skylight, aerial perspective,
  and cloud shadows cast into the medium
- the ice / fallstreak generator — generating cells, habit-dependent fall speed,
  a six-knot shear profile, sublimation, and detail **advected** along the flow
  and re-seeded at the cells
- blue-noise-offset progressive accumulation (void-and-cluster, generated at load)
- linear float, real EV, AgX with the proper inset/outset matrices

Verified headless in Chrome: shaders compile, the page runs, accumulation
converges, the UI is wired, and a fibrous streak structure is visible.

**What could not be verified here.** The only GPU available to this session is
SwiftShader, Chrome's software rasteriser, at roughly 10–16 seconds per sample at
205×155. That is enough to prove the thing runs and to find arithmetic bugs; it is
nowhere near enough to judge a look. `proto/README.md` documents six bugs found
and fixed during that process, including two that would have been reproduced
verbatim in the C++ port.

### Phase 1 — re-scaffold

**Identity.** `cmake/PluginConfig.cmake` rewritten: target, match name, category
and bundle id all `Mistytune`; env prefix `MISTYTUNE`; log `mistytune.log`. The
match name is permanent from the first build anyone else installs — it is
reviewed once more before the v0.5 hand-out and never again.

**Removed.** Jolt and its CMake module; the PiPL chain (`AEPiPL.cmake`,
`PiPLStep.cmake.in`, the `.r.in`); the whole AEGP; the three carrier effects; the
rigid and soft-body solver and its fourteen test files.

**Kept, per the plan.** `docs/HOST-NOTES.md`, the version-from-`Build.h` scheme,
`EffectFlags.cmake` (now feeding only the `static_assert`), `AESDK.cmake`,
`AEPlugin.plist.in`, the build scripts, the `src/engine` / `src/ae` split, the
test framework, and `Contour.{h,cpp}` — which survives on merit as the front half
of pareidolia.

**New.**

```
src/engine/CloudParams.h     the parameter model, and the only definition of it
src/engine/Geometry.{h,cpp}  Vec2/Polygon/area, what Contour needed out of Hull.h
src/engine/Fingerprint.*     retargeted to FieldParams, sizeof tripwire kept
src/engine/FieldCache.*      the three-way cache decision
src/kernel/RenderRequest.h   what the renderer is told
src/kernel/Shading.h         per-pixel maths, compiled for BOTH GPU and CPU
src/kernel/KernelApi.h       the only thing the host calls
src/kernel/Mistytune.cu      the CUDA launch shim
src/kernel/CudaStub.cpp      what resolves instead when there is no toolkit
src/kernel/CpuRender.cpp     the CPU loop around the same Shading.h
src/ae/Params.h              the parameter table: enum, setup, checkout from ONE list
src/ae/Mistytune.cpp         registration, GPU device setup, pre-render, both paths
src/cli/Main.cpp             mistytunec, the headless renderer
cmake/Cuda.cmake             optional CUDA discovery, determinism flags
```

**Build state.** `plugin_engine`, `plugin_kernel`, `plugin_tests`, `mistytunec`
and `Mistytune.aex` all compile clean under MSVC 14.29 with `/W4 /permissive-`.
40 unit tests pass. `mistytunec` renders and is byte-identical across two runs
with the same arguments.

---

### Decisions taken that deviate from PLAN.md

**`AutoSolveGate` was replaced rather than retargeted.** The plan says to keep it.
Its four rules — never solve on first sight, not while a clean project changes,
wait to settle, one solve per change — all existed because a re-solve *wrote to
the project*: keyframes, expressions, an undo step. Mistytune is a plain effect
and writes nothing; a rebuild costs a slow frame, not an undo step. So the rules
have nothing to protect here.

What the plan actually named as the mechanism worth keeping — answer "would
rebuilding give something different?" with a hash instead of a rebuild, and keep
the `sizeof` tripwire — is `Fingerprint.h`, and `FieldCache` is the cache it
serves. The three-way decision (accumulate / restart samples / rebuild field) is
what makes a camera move cheap, which is the row the plan calls the difference
between a plugin people use and one they abandon.

`src/engine/AutoSolveGate.{h,cpp}` and `tests/unit/TestAutoSolveGate.cpp` are out
of the build but still on disk. **They should be deleted.**

**`PF_OutFlag2_I_USE_3D_CAMERA` is set before the camera is used.** `out_flags2`
is cached by AE against the binary, so adding a flag later costs a version bump
and a stale-cache hunt. Setting it now costs some redundant re-renders during
development. Nothing has shipped, so it is free today and not tomorrow.

**The Phase 1 placeholder sky is more than "a parameter-driven colour."** The
plan asks only for a colour. The first attempt was exactly that — one slab, one
air mass — and it rendered a *green* sky, because multiplying in-scattered blue by
the sun's own horizon-path transmittance attenuates blue twice. Phase 1's exit
criterion is that the render is **correct** at three bit depths and two
resolutions, and a picture that is visibly wrong for a known reason cannot be
used to find one that is wrong for an unknown reason. It is now a real
single-scattering integral, about thirty lines, and it is the honest precursor to
Phase 2's precomputed version rather than something to throw away.

---

### Open, and blocking the phase that consumes it

- **The Phase 0 verdict itself.** Blocks Phase 2.
- **The CUDA path has never been compiled.** No toolkit on this machine, so
  `cmake/Cuda.cmake` selected the stub and `Mistytune.cu` has never been through
  nvcc. It is written against the AE GPU sample's conventions and it is
  *unverified*. Install the CUDA Toolkit and build before trusting a line of it.
- **Nothing has been loaded into After Effects.** The effect compiles and
  registers in code; whether AE accepts the registration, renders at 8/16/32 bpc,
  survives reduced resolution and names its device in the log is all untested.
  That is the rest of the Phase 1 exit criterion.
- **OIDN install bulk** — measure the shipped weights in Phase 2 before deciding
  to bundle rather than fetch.
- **Whether Draft mode can be interactive at all** on the floor GPU — a Phase 2
  measurement, and it decides whether the variations grid moves forward from v2.

### Known gaps in what was built

- `fillCameraFromComp()` in `src/ae/AEBridge.h` is a **stub** returning a fixed
  matrix pitched 20° up. The flag, the parameter and the view hash are all in
  place, so the real implementation is one function body in Phase 2.
- The GPU render path launches **all samples in one launch**. Safe only because
  the placeholder kernel cannot approach the Windows driver timeout; the chunked
  loop, the abort check and the progress report land in Phase 2 with the real
  transport. `RenderRequest` already carries `firstSample`/`sampleCount` and
  `FieldCache` already counts samples across launches.
- `mistytunec` renders on the **CPU only**. The GPU path there needs device
  allocation and a copy back, which arrives with the EXR bake.
- `tests/golden/` **exists and is green**, built against the CPU reference. Three
  fixed scenes at 128×72 (midday, sunset, horizon) compared with a tolerance of
  2/255, plus the three determinism tripwires. It needs no GPU and no AE, so it
  runs everywhere the unit tests do.

  Verified to go red as well as green: a one-degree change in sun elevation
  trips it (max 5), and so does rendering one fewer sample (max 8). That second
  case is why the comparison is on the **maximum** per-channel difference and not
  the mean — its mean was 0.031, which any mean-based threshold would have waved
  through.

  When the real kernel lands, the same scenes gain a GPU-versus-CPU comparison;
  that is the cross-platform-divergence half the tier exists for and it cannot be
  written until there is a second path to compare against.
- Output is **PPM**, not EXR — dependency-free and byte-comparable, but it throws
  away exactly the HDR the renderer exists to produce.

### Repository history

The Gravitune history is **not** Mistytune's history. `main` was recreated as an
orphan branch so the published repo starts at this work rather than at twelve
commits of a Jolt rigid-body plugin.

The old history is not gone — it is on the local branch **`gravitune-history`**
(tip `1636785`), which is deliberately not pushed. Delete that branch and run
`git gc --prune=now` if you ever want the objects gone for good; until then it is
the only copy, because the remote was empty when this was done.
