# Changelog

Keep one entry per build number, and bump `PLUGIN_BUILD` in `src/ae/Build.h`
every time you install into After Effects. The build number is what tells AE its
cached registration is stale, and it is what identifies which binary AE is
actually holding when something behaves unexpectedly.

Note against each entry whether it needs a full install or can be hot-swapped:
parameter list, `out_flags`, effect name and version changes all need a full
install with AE closed.

## Unreleased

- **build 1 — Phase 0 prototype, Phase 1 scaffolding.** Needs a full install:
  this is the first build, so AE has no cached registration for the
  `Mistytune` match name yet.

  - `proto/` — the Phase 0 look prototype. Null-collision tracking, many-bounce
    multiple scattering, Jendersie–d'Eon, a precomputed transmittance table, the
    ice / fallstreak generator, blue-noise accumulation, AgX. Standalone; no
    build step. **The Phase 0 look verdict has not been given yet.**
  - One self-registering effect, no PiPL, no AEGP. GPU device setup/setdown,
    smart pre-render, and both the GPU and CPU render paths.
  - The parameter table is generated from one declarative list, with reserved
    spare slots per group so a later control can be added without reordering.
  - `mistytunec`, the headless renderer, so the kernel can be golden-imaged and
    profiled outside After Effects.
  - The renderer itself is a **placeholder**: an analytic single-scattering sky,
    no volumetric transport. See `PROGRESS.md`.
