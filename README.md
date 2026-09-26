# Mistytune

A volumetric cloud and sky renderer for After Effects. **An offline path tracer,
not a noise generator.**

The difference is the whole point. A noise-based cloud is a shape that has been
sculpted to look like weather; Mistytune is a physical medium — generating cells,
fall speed, wind shear, sublimation — rendered with real light transport, so the
sky it produces is the consequence of conditions rather than of a texture. That
is what lets a fallstreak hook because the wind turns, rather than because
somebody drew a hook.

> **Status: early. Nothing here is usable yet.**
> The Phase 0 look prototype is built and the Phase 1 scaffolding stands, but the
> renderer is a placeholder and the plugin has never been loaded into After
> Effects. See [PROGRESS.md](PROGRESS.md) for exactly what works and what does
> not, and [PLAN.md](PLAN.md) for where it is going.

## Layout

```
proto/        the Phase 0 look prototype -- open index.html, no build needed
src/kernel/   the renderer: ONE cross-compiled kernel source
src/engine/   host-free C++: parameter model, cache policy, feature extraction
src/ae/       the SmartFX GPU effect
src/cli/      mistytunec -- headless renderer: golden images, profiling, bakes
tests/unit/   engine tests -- fast, no SDK, no GPU
docs/         HOST-NOTES.md, which is the cheapest hour in the project
```

Two rules hold the layout together, and both are enforced by CMake rather than by
good intentions:

- **`src/engine/` includes no After Effects header and no GPU header.** It is the
  part worth testing and the part that survives a host port.
- **`src/kernel/` includes no After Effects header either.** The effect hands the
  kernel a plain struct of physics constants and a camera; `src/cli/` hands it the
  same struct. That is what makes golden images possible at all.

## Building

The After Effects SDK is Adobe's, is licensed, and is not in this repository.
Download it from [developer.adobe.com/after-effects](https://developer.adobe.com/after-effects/)
and either set `AE_SDK_ROOT`, pass `-DAE_SDK_ROOT=<path>`, or unpack it into
`./sdk/` (which is gitignored).

```powershell
.\build.ps1              # configure and build
.\build.ps1 -Test        # ...and run the unit tests
.\build.ps1 -Install     # ...and copy the .aex into AE's plug-ins folder
```

## Tests

Three tiers, and the point of the split is that the first two need neither After
Effects nor a GPU.

```
ctest -C Release --output-on-failure      # both automated tiers, ~2 seconds
```

1. **`tests/unit/`** — the engine: the parameter model, the field fingerprint's
   coverage, the cache policy, contour extraction. Milliseconds.
2. **`tests/golden/`** — fixed scenes rendered through `mistytunec` and compared
   with tolerance, plus the determinism tripwires: the same inputs twice, and the
   same inputs at one thread versus eight, must be **byte**-identical. A third
   test asserts that two different seeds *differ*, which is what stops
   "deterministic" from being satisfied by "always the same wrong answer".
3. **In-host checks** — scripted but judged by eye: all three bit depths, both
   resolutions, a camera move that must not re-solve, an MFR soak, and a
   48-frame animation watched for denoiser shimmer.

If a golden test fails, **look at the image before blessing it**. When the change
was intended:

```
cmake --build build --config Release --target golden-bless
```

That target is deliberately separate and never automatic — a suite that
regenerated its own references on failure would agree with every change ever
made, including the wrong ones.

```bash
./build.sh --test        # macOS; v1 is Windows-only, so this is untested ground
```

**Neither the SDK nor CUDA is required to build the interesting parts.** Without
the SDK the plugin target is skipped and the engine, the kernel and the tests
still build. Without the CUDA Toolkit the GPU path is replaced by a stub and the
CPU reference is used. Both are deliberate: a renderer that can only be built on
a fully equipped machine cannot be bisected on any other one.

## Running it headless

```
mistytunec -w 1920 -h 1080 -s 256 --sun-el 4 --agx -o sunset.ppm
mistytunec --device          # what the renderer would use, and whether CUDA is live
mistytunec --fingerprint     # the field and view hashes, for diagnosing the cache
```

The same arguments must produce a byte-identical file every time, on either path.
That is not a nicety — motion blur renders one frame several times and
multi-frame rendering renders frames on different workers, so a renderer that is
not reproducible is a renderer that flickers.

## Diagnostics

Set `MISTYTUNE_DIAG=1` **before** launching After Effects, then read
`%TEMP%\mistytune.log` (or `$TMPDIR/mistytune.log` on macOS). The log names the
GPU device AE handed us, which is the difference between "the GPU path is working"
and "the GPU path silently fell back and is merely slow".

Logs interleave under multi-frame rendering. Diagnose on a single still frame; if
the output looks shuffled, that is why.

## Licence

See [LICENSE](LICENSE).
