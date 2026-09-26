# proto — the Phase 0 look prototype

Open `index.html` in a browser. No server, no build step, no dependencies.

It needs WebGL2 and `EXT_color_buffer_float`, which every desktop browser from
about 2018 onward has. Drag to aim, scroll to change the focal length.

## What this is for

It answers the only question that can still tell us the premise is wrong, and it
answers it before any C++ is written. From `PLAN.md`:

> **Exit criterion, stated before we start so it cannot move:** side by side with
> reference photographs of *cirrus fibratus* and *uncinus*, backlit, the
> prototype reads as photographed, and the hook is visibly the shear curve rather
> than a sculpted shape.

That verdict is a human judgement against real photographs, on real hardware. It
is not something the test suite can return.

**How to run it:** open the page, press **Backlit**, then **Cirrus uncinus**, put
a photograph of uncinus next to it, and look. Then drag the six shear speed
sliders and the turning control, and watch whether the hook follows them. If the
answer is yes to both, Phase 0 is done and Phase 1 starts. If it is no, it is
fixed here, where an iteration costs seconds — nothing downstream is cheaper to
change than this shader.

## What is in it

Everything `PLAN.md` lists for Phase 0, and nothing beyond it:

| Piece | Where |
| --- | --- |
| Null-collision (delta / ratio) tracking | `trace()`, `cloudTransmittance()` |
| Many-bounce brute-force multiple scattering | the bounce loop in `trace()` |
| Jendersie–d'Eon (2023) Draine-based Mie | `phaseLiquid()`, `samplePhaseDir()` |
| Bruneton-style precomputed atmosphere | the `fs_transmittance` pass, `skyRadiance()` |
| Cloud shadows cast into the medium | `uCloudShadowsInAir`, inside `skyRadiance()` |
| The ice / fallstreak generator | `iceDensity()`, `cellField()`, `driftAt()` |
| Blue-noise-offset progressive accumulation | `voidAndCluster()`, `blueNoiseOffset()` |
| Linear float, real EV, AgX | the `fs_display` pass |

Aerial perspective is not a separate pass and does not need to be: an escaped
path's sky march starts at the camera, so the air between the viewer and the
cloud is integrated by the same code that produces the sky. Self-aerial-
perspective falls out of it.

The skylight on the cloud is likewise not an ambient term — a path that leaves
the medium picks up whatever the sky is in that direction, which is the same
thing arrived at by transport.

## The generator, in three lines

1. Crystals are **born in discrete generating cells** at one altitude.
2. They **fall** at a speed their habit sets, while the wind carries them
   sideways at a speed and bearing that change with height.
3. They **sublime** as they fall into drier air, which is what gives a streak an
   end.

So the density at a point is not noise evaluated there. It is: work out how far a
parcel now at this height must have drifted since release, look back along that
drift to find the cell that released it, and ask how much of it is left. **Detail
is carried in the parcel's own frame**, which is why the fibres flow along the
streak instead of shimmering through it. That inversion is the whole difference
between this and a noise stack.

## URL overrides

Any control can be set from the query string, which makes a capture repeatable:

```
index.html?burst=64&scale=0.4&sunEl=4&od=0.6&ev=1.2
```

Useful for putting the same frame beside a photograph twice, and for the golden
comparison if this page is ever wired into the harness.

## What it is not

- **Not the shipping renderer.** The transport here is a WebGL fragment shader;
  the plugin's is Slang compiled to PTX and Metal. This is the look reference the
  port is checked against, and it is kept after Phase 0 for exactly that.
- **Not a full ice phase function.** `phaseIce()` is a forward lobe, an isotropic
  floor and a single 22° bump, and it is labelled as a placeholder in the source.
  Real haloes, sundogs and pillars need a library indexed by habit and
  orientation, which is Phase 4. The Jendersie–d'Eon model beside it *is* the
  real thing for liquid, and is kept live so the two can be compared.
- **Not multiple-scattering-corrected in the atmosphere.** The sky is single
  scattering with a precomputed transmittance table. Twilight therefore comes out
  darker and less saturated than it should. Bruneton's second table fixes it, in
  Phase 2.

## Things found while building it

Written down because each one cost real time and each would have cost it again in
the C++ port.

**The sun must not be counted twice.** Every scattering event estimates the sun
directly by next-event estimation. If an escaped path *also* picks up the sun
disc, the sun is double-counted — and not merely twice as bright: the disc
subtends 6.8e-5 sr, so a path that happens to scatter into it returns ~3e5 while
its neighbours return 1. The image fills with fireflies that never average out.
Only a ray that never scattered may see the disc.

**A phase function must be sampled by its own mixture, lobe for lobe.** Sampling
one Henyey-Greenstein lobe at an average `g` and reweighting by `phase/pdf` is
unbiased and does not work: the proxy is always less forward-peaked than the real
forward lobe, so the weight exceeds 1 in the forward direction, and the
throughput is multiplied by it at every bounce. With albedo 0.999 and thirty
bounces, a few paths per frame come home carrying hundreds. It reads as a firefly
problem and it is not one — clamping and more samples both fail to fix it.

**Cells must be spaced wider than they are large.** A blob whose radius equals the
grid spacing overlaps all its neighbours, so above about a third occupancy the
field is continuous everywhere: no gaps, no distinct heads, and an optical depth
several times what the slider says. The clear lanes between streak families are
as much of the look as the streaks.

**The drift is shear, not wind.** A generating cell is carried by the wind at its
own altitude. What draws a streak is the *difference* between that and the wind
below it. Integrating absolute wind puts the streak 34 m/s downwind of a cell
that moved just as far — 88 km of drift for 2.6 km of fall at the default
profile, so every streak overlaps every other and the sky is a featureless sheet.
The generator looks broken; the frame of reference is.

**Fallstreaks are genuinely tens of kilometres long.** A crystal falling at a
metre a second through 20 m/s of shear takes most of an hour to fall two
kilometres. That is why the default lens is 75° — a normal lens sees a piece of
one streak and reads as an even haze, and photographs of cirrus are taken wide
because the sweeping strokes across the whole frame *are* the subject.
