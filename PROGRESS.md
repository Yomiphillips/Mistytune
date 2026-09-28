# Progress

Tracked against `PLAN.md`. Newest first.

---

## 2026-09-28 — The 3D camera is real; the field cache is NOT worth wiring yet

### `fillCameraFromComp()` is no longer a stub

It calls `AEGP_GetEffectCameraMatrix` and takes the comp camera's orientation and
field of view. A zero plane size means no camera, which is the ordinary case for a
generator on a solid and takes the default; `cameraFromComp` records which, and the
log now names it rather than leaving it to be inferred from the picture.

**THE CONVERSION LIVES IN `src/engine/CameraConvert.h`, NOT IN `src/ae/`.** It is a
transpose and a handedness flip — AE is +Y down, +Z into the screen, row-vector; this
renderer is +Y up, -Z forward, column-vector — and it produces a camera, which is the
thing in this renderer whose errors look least like errors. A camera pointing the
wrong way renders a plausible, well-formed, entirely incorrect picture. Every bug this
project shipped lived in host glue that tier 1 could not reach, so the AE types stop
at the caller and the arithmetic is sixteen doubles in, sixteen floats out.

Six unit tests, **worked out by hand rather than blessed from a run** — a conversion
test recorded from its own output agrees with whatever the code did that day, which
for a camera means agreeing with a wrong picture. They cover: AE's identity camera is
our identity; a camera pitched up pitches UP (the assertion that would have caught the
20-degrees-below-the-horizon default that rendered black); a yaw does not roll (the
transpose); position does not reach the rays; the FOV comes from the plane HEIGHT, not
the width; and no camera reports zero rather than a default.

**Verified in the host, both halves, by independent evidence.**

- *Orientation*: a fresh AE camera is level, and the rendered horizon sits at the
  vertical centre of the frame. A handedness error would have put it anywhere else.
- *Field of view*: the effect logged **12.5 degrees vertical**, which looked wrong --
  AE's default 50mm camera on a 1920x1080 comp is about 22.9 degrees vertical, and a
  wrong FOV renders a completely convincing picture. It was not wrong. The camera in
  the comp was a **92.59mm** lens showing **Angle of View 22.00 degrees**, and AE
  measures that **horizontally** (Measure Film Size: Horizontally). At 16:9 that is
  2*atan(tan(11 deg) * 1080/1920) = **12.48 degrees vertical**.

So the conversion agrees with AE's own UI, through a unit AE does not print. The raw
`distanceToPlane` and plane size are logged beside the derived angle now, because that
question took a screenshot of the camera panel to answer and should take one log line
next time.

**Aside, measured:** one sample at 1920x1080 costs 0.09-0.18 s with this camera against
0.02 s with the default one. A level camera at a narrow FOV points every ray near the
horizon, where the slant paths are longest and the ray-march takes the most steps. Same
kernel, more work per pixel -- worth knowing before anyone reads a future timing as a
regression.

**Translation is deliberately dropped.** AE's world is comp pixels with an arbitrary
origin; this renderer's is metres with the observer at `observerAltitude`. There is no
conversion without a scene-scale parameter, which does not exist and should not be
invented here. It costs nothing while the sky is at infinity, and starts costing
something in Phase 3 when clouds sit at a finite altitude and the camera flies past
them.

### The field cache was NOT wired in, and that is the finding

PLAN.md's Phase 2 asks for "the field cache keyed on the fingerprint", and the last
entry carried "nothing is cached between renders" forward as debt. Having gone to wire
it up: **it should not be wired up yet, for three reasons, and the third is the one
that would have bitten.**

**1. There is no field to cache.** `FieldCache` exists to avoid rebuilding an
expensive volumetric medium. The Phase 1 sky is an analytic integral in `skyRadiance`
with no build step at all, so the cache would wrap a rebuild that costs nothing. It
becomes real the same week the medium does.

**2. "Exposure should cost nothing" contradicts a deliberate decision already made
here, with a better reason than the debt note had.** `FieldCache.cpp` puts
`exposureEV` and `agxTonemap` in the view hash on purpose: OIDN is trained on roughly
perceptual magnitudes, so the exposure the user chose has to be in the numbers before
the denoiser sees them, or denoising strength silently tracks the exposure slider.

The resolution is neither of the two positions on record: store **raw** radiance and
make exposure, denoise and tonemap a RESOLVE pass over it. Then an exposure change
costs one denoise rather than a re-render, and the denoiser still sees exposed values.
That splits `viewHash` into a sampling key and a resolve key — and it should be
designed the week OIDN lands, not guessed at now, because OIDN's actual cost is the
only number that says whether the resolve pass is worth having.

**3. MULTI-FRAME RENDERING IS ON**, and a cross-render accumulator is shared mutable
state between concurrently rendering frames. `PF_OutFlag2_SUPPORTS_THREADED_RENDERING`
is set; docs/HOST-NOTES.md is blunt that anything shared then needs a lock or needs not
to be shared. A single accumulator keyed on one `RenderKey` would thrash between the
frames AE has in flight, so it wants a keyed cache with an eviction policy and a lock.

That is a real piece of work whose payoff today is saving a re-render **of a frame that
takes 20 ms**. It is worth building when a frame takes two seconds, which is the same
week as reasons 1 and 2.

**Carried forward, with the reasoning rather than as a bare line:** the cache lands
with the real transport, and its design question is the sampling/resolve key split.

---

## 2026-09-28 — Phase 2: the GPU stops allocating, and a frame stops being one launch

Three things in the launch path, plus a fourth defect found the moment a Region of
Interest was finally drawn in the host.

### THE THIRD TIME THIS PROJECT HAS SHIPPED THE SAME SHAPE OF BUG

A Region of Interest was drawn over part of the frame, and the effect rendered a flat
pale-blue rectangle. The log:

    PRE_RENDER: frame=1920x1080 request=[633,387 907x751] downsample=1/1,1/1
      result_rect=[633,387 907x693]
    SMART_RENDER_HOST: output=907x693 rowbytes=7296
      frame=1920x1080 origin=0,0

AE asked for a rect at **(633,387)**, returned a buffer of exactly that size, and
`in_data->output_origin_x/y` reported **ZERO**. So the renderer drew the top-left
907x693 of the sky into a buffer AE composited at (633,387) — and the top-left corner
of a sky is empty, so it came back as a flat rectangle that reads as a broken effect.

**It is the same bug three times, each time with a different field to blame:**

| | the wrong number | what it looked like |
| --- | --- | --- |
| the requested rect stored as the frame | request 2304x1296 vs frame 1920x1080 | FOV widened, image off centre |
| the layer size stored at full resolution | 1920 against a 640-wide buffer | flat blue at Third resolution |
| output_origin read instead of the result rect | 0,0 against a rect at 633,387 | flat pale blue inside the ROI |

Every one is the same mistake: **the buffer is a WINDOW into the frame, and the number
that says where the window sits came from the wrong place.** Every one was found by a
render in the host, and none by any test.

**The fix.** Pre-render now records its own `result_rect` into `PreRenderData` and both
render paths take the origin from there, through one `applyRenderOrigin()` rather than
two copies of a subtle line. The result rect is the rect the effect TOLD AE it would
fill, and the buffer handed back has matched it exactly on every frame measured.

**The size is now checked rather than assumed**, and the log prints `output_origin`
beside the value actually used — so if the two ever disagree in the other direction,
or AE hands back a buffer that is not the promised rect, it announces itself instead
of quietly rendering the wrong patch.

**Verified in the host.** `origin=933,433 (output_origin=0,0)` on the ROI frame, and
the correct patch of sky inside the box.

### The test that was missing, and the fourth bug it found immediately

`mistytunec` gained `--window <x> <y> <w> <h>` (render a sub-rect; `-w/-h` stay the
frame) and `--compare-at <x> <y>` (compare against that region of a reference).
`determinism.window` renders a window and checks it against the same patch of a
whole-frame render, on both engines, with a control that the same window compared at
the WRONG place must fail.

**It failed on the first run, at max 190 of 255.**

`renderPixel()` seeded the sampler from `px, py` -- the BUFFER pixel -- while building
the ray from `px + originX` -- the FRAME pixel. So the same frame pixel got different
sub-pixel jitter depending on how the frame happened to be divided. A Region of
Interest disagreed with the picture underneath it, and a banded render disagreed with
a whole-frame one.

**`determinism.gpuBands` had been asserting almost exactly that property, and passing.**
Its scene was the suite's shared 96x54 sky at sun elevation 20 -- smooth enough that a
different jitter moves no pixel by a whole level. The bug was live underneath a green
test. Its scene is now 256x144 with the sun disc in frame, where sub-pixel differences
become whole levels, and with the fix reverted **both** tests now fail. Before the
scene change, only the new one did.

    A TEST CAN ONLY CATCH WHAT ITS SCENE CAN SHOW.

That is the third lesson of the day and the most expensive one, because a green test
asserting the right property is harder to doubt than no test at all.

**The mean was 0.51** while the maximum was 190 -- the whole case for comparing maxima,
made again by an unrelated bug. 13 ctest suites now.

### The rest, none of it yet seen by After Effects

### The device buffer persists

`renderCudaToHost()` allocated and freed per band. It now reserves grow-only
thread-local scratch (`DeviceScratch` in `Mistytune.cu`) and hands back the same
pointer for the life of the thread.

Measured, 1920x1080 at one sample through `mistytunec --require-gpu`:

| | before | after |
| --- | --- | --- |
| 135 bands of 8 rows | 302 ms | **227 ms** |
| one band, whole frame | 186 ms | 177 ms |

About **0.55 ms per band** of driver-side allocation removed. The one-band row barely
moves, which is the check that the number means what it says: one launch allocates
once either way. Both totals include roughly 150 ms of process start and CUDA context
init, so the render-only share of that 75 ms is much larger than it looks.

**thread_local, not global.** Multi-frame rendering puts several frames in this
process at once; one shared buffer needs a lock on every launch, and an unlocked one
is two frames writing the same device memory.

### A frame is now many launches, and the reason was not obvious

**Row banding alone cannot bound a launch, and it looked as though it could.** The
host sizes bands from a pixel-sample budget, so a band is roughly constant work -- but
only until it hits its FLOOR, which exists because a band under 16 rows idles most of
the threads in every CUDA block. Past the floor the only thing still scaling is the
sample count. At 1920 wide the crossover is about **1041 samples per pixel**, and the
Samples parameter goes to **65536** -- 63x past it, which is roughly ten seconds of
GPU work against a display-driver timeout of about two. That failure is a driver reset
that takes the whole CUDA context, and After Effects with it.

So above the crossover the samples are split too, with the accumulator carrying the
partial sums. `samplesPerLaunch()` in `KernelApi.h` decides where.

**IT IS A PURE FUNCTION OF THE REQUEST, AND THAT IS THE DESIGN CONSTRAINT.** Splitting
samples regroups a floating-point sum and addition is not associative, so anything
that changes the split changes the image. `determinism.gpuBands` and
`determinism.threadCount` demand byte-identical output across band sizes and worker
counts, and under MFR the worker count is AE's to choose. The chunk size therefore
takes the FLOOR band's pixel count, never the band being rendered, and never a thread
count or a measured time.

**Below the crossover it is one chunk and changes nothing, bit for bit.** The golden
references were blessed from the unsplit path and still match at max 0.

`renderPixel()` already implemented the accumulation; what was missing was a host loop
to use it. Both engines now have one, and both attach an accumulator only when the
request is actually split.

### Abort is now checked per chunk, not per band

At a high sample count a band is many launches. Checking only between bands would
leave AE unresponsive for exactly as long as the split exists to avoid.

### `PF_Cmd_SMART_RENDER_GPU` no longer carries the hazard

It is still dead code -- AE reports `what_gpu=NONE` and never calls it -- but it no
longer contains the one-launch-for-all-samples bug, because the day AE does start
calling it is not the day to discover that. No row banding there (AE hands the buffer
over whole), so it splits on samples alone, against the whole frame rather than a
floor band. `reserveDeviceAccumulator()` was added to `KernelApi.h` so `src/ae/` can
get device memory without a CUDA header.

Everything in that function is reasoned rather than measured, **including whether
PF_ABORT and PF_PROGRESS are legal from inside it.**

### The test, and what it is worth

`determinism.sampleChunks` -- 64 samples in one launch against 64 samples in 64
launches, on both engines, compared at tolerance 2. 12 ctest suites now, 44 unit tests.

**It carries its own control, and without it the test is worthless:** a 1-sample render
must FAIL the same comparison. It does, at max 206.

**Verified to go red.** Breaking the accumulator the realistic way -- re-initialising
every launch instead of honouring `samplesAlreadyDone` -- fails this test while **every
golden scene stays green**, which is exactly why the tier could not already catch it.

Measured aside: at 8-bit PPM output every split tested compares max 0 against the
unsplit render, on both engines. That is a stronger result than the design is entitled
to claim -- the output quantisation hides sub-1/255 float differences -- so the test
asserts tolerance rather than equality.

### What needs After Effects next

- **A high sample count in the host.** Everything above the crossover is untested in
  AE: whether the progress bar moves, whether cancel is responsive, and whether the
  driver timeout is genuinely avoided at 2048+ samples.
- **A Region of Interest**, still the only way to drive a non-zero `output_origin`.

---

## 2026-09-28 — Phase 1 exit criterion MET

The two paths the last entry listed as never exercised were driven in AE 2026. One
passed untouched. The other rendered a flat blue frame, and the defect was a comment.

### 16 bpc passes, and it was right the first time

    SMART_RENDER_HOST: format=909206881 output=1920x1080 rowbytes=15360 samples=1

`909206881` is `'ae16'`, and 15360 rowbytes on a 1920-wide buffer is 8 bytes per
pixel — `PF_PixelFormat_ARGB64`, as expected. The frame came back at correct
brightness, so the `0..32768` scaling at `Mistytune.cpp` is confirmed in a host. That
is the classic way to get a 16 bpc render half as bright, and it is now checked rather
than reasoned about.

All three depths are therefore verified in the running host: 8 via `'argb'`, 16 via
`'ae16'`, 32 via `'ae32'`.

### Reduced resolution failed, and the cause was a sentence

Third resolution rendered flat blue — no horizon, no gradient. The log named it:

    PRE_RENDER: frame=1920x1080 request=[-64,-36 768x432] downsample=1/3,1/3
      result_rect=[0,0 640x360]
    SMART_RENDER_HOST: output=640x360 rowbytes=5120
      frame=1920x1080 origin=0,0

**`frame` and `output` were in different units.** `primaryRayDirection` divides the
destination pixel by `view.widthPx`, so `px` ran 0..639 over a denominator of 1920 and
the render covered the top-left third of the picture. On a sky whose top third is
empty that is a uniform blue rectangle, which reads as a dead renderer rather than as
a framing error — the same disguise the black frame wore in the previous entry.

**The wrong number came from a comment asserting the opposite of the truth.**
`Mistytune.cpp` carried, directly above the assignment:

> `in_data->width/height` are the layer's size at the current downsample

They are not. They are full resolution and do not shrink: the 1/3 render reported
`in_data->width == 1920` while AE's own `result_rect` was 640x360. Everything else at
render time — the output world, the request rect, `output_origin_x/y` — is in
downsampled pixels, so that one full-resolution number described a different picture
than everything it sat beside.

**The fix.** `downsampledExtent()` in `AEBridge.h` scales the layer into the buffer's
units, and pre-render stores that. At Third the frame is 640x360 against a 640x360
buffer, and the whole picture renders. Verified in AE at Third and Quarter.

**The field of view is still not scaled by the downsample**, which the old comment got
right and is worth keeping right: only the RATIO of buffer to frame reaches the ray
maths, so scaling both together holds the camera still. That is what makes a proxy
render a smaller picture of the same view instead of a zoom.

### What the new tests do and do not cover

`tests/unit/TestCamera.cpp` — four cases: framing invariant across Full/Half/Third/
Quarter, the frame as the real denominator, the ROI origin, and the CUDA band offset.
44 unit tests now, all green, plus the 11 ctest suites.

**It would not have caught this bug, and its header says so.** The bad number lived in
AE glue that tier 1 cannot reach; `primaryRayDirection` was correct before the fix and
is correct after it. What the file guards is the opposite mistake — "fixing" the field
of view by multiplying it with the downsample factor — and it records the contract the
glue has to satisfy in a place a compiler checks.

The lesson is the same one the previous entry ends on, one level up: **a comment
asserting a host's behaviour is a claim, and an unverified claim next to an assignment
is more dangerous than no comment, because it stops the next reader from checking.**
Both defects in this file's history were found by a render, not by a reading.

### Phase 1, against PLAN.md's exit criterion

| | |
| --- | --- |
| installs into AE | yes |
| renders correctly at 8 / 16 / 32 bpc | yes, all three observed in host |
| renders correctly at reduced resolution | yes, Third and Quarter |
| `EffectFlags.cmake` static_assert passes | yes |
| `build.ps1 -Test` green | yes — 44 unit, 11 ctest |
| the log names the GPU device AE handed us | **with an asterisk** |

**The asterisk.** AE hands us no device: `what_gpu=NONE` on every frame observed, so
`PF_Cmd_SMART_RENDER_GPU` is never called. The log names the device *we* opened, and
the frame is rendered on it through `renderCudaToHost()` inside the ordinary CPU
command. The criterion's intent — a GPU pixel in the host, provably on the GPU — is
met at 20 ms a frame against 1.16 s on the CPU. Its letter is not, and no amount of
work in this effect can meet the letter until AE is persuaded to offer a device.

**Phase 1 is closed. Phase 2 is next.**

### Carried into Phase 2, unchanged from the last entry

- **`PF_Cmd_SMART_RENDER_GPU` is dead code** and its one-launch-for-all-samples hazard
  is still unfixed AND still unreachable. It needs the chunked loop before AE is ever
  persuaded to call it.
- **`renderCudaToHost()` allocates and frees per band.** At 20 ms a frame the
  `cudaMalloc` and the 33 MB copy back are a measurable fraction of the total. A
  persistent device buffer is the obvious next win and is the same allocation
  progressive accumulation needs.
- **Nothing is cached between renders.** Exposure and AgX Tonemap are pure post
  transforms and currently cost a full re-render.
- **`fillCameraFromComp()` is still a stub** returning a fixed matrix.
- **The `--` classifier readout still draws a 0..1 slider** instead of a text-only row.
- **A non-zero `output_origin` has still never been driven in the host.** Every render
  to date logs `origin=0,0`, including the one where AE expanded the request to
  [-192,-108 2304x1296] and still asked for the full frame. The path is covered by
  unit tests and by the CUDA band split; it is not covered by a host.
- ~~`src/engine/AutoSolveGate.{h,cpp}` and its test are out of the build but on disk.~~
  **Already deleted**, in a commit before this entry. The bullet was carried forward
  from the previous entry without checking, which is the same mistake as the comment
  in the section above — a stale claim repeated because it was written down once. The
  only surviving mention is the deliberate one in `FieldCache.h`, explaining what the
  cache replaced and why, and that one should stay.

---

## 2026-09-26 — Phase 1 exit criterion FAILED on first contact with After Effects

The effect was installed into AE 2026 (26.2.1) and asked to render for the first
time. It rendered a black frame.

**Five defects. Four were in code this file recorded as done, and three carried
comments asserting the behaviour was deliberate.** That is the finding worth
keeping: the previous entry's "unverified" list was not a list of things that were
probably fine.

### What was actually wrong

**1. The default camera pointed 20 degrees BELOW the horizon.** `R_x(theta)`
applied to the camera's forward `(0,0,-1)` gives world `y = sin(theta)`, so a
negative angle pitches DOWN. `fillCameraFromComp()` used `-20` while its own
comment said "pitched up 20 degrees". At a 39.6 degree vertical field of view the
frame ran from -39.8 to -0.2 degrees elevation: **every pixel was ground**, with
the horizon just off the top edge.

Fixed to `+12`. Not `+20`: at half a field of view of 19.8 degrees, a 20 degree
pitch puts the horizon exactly on the bottom edge, so the comment's own stated
goal — "keep the horizon in frame so that both halves are visible at once" —
fails by two tenths of a degree. 12 puts it about 80% down the frame.

**2. The 8 and 16 bpc paths wrote linear radiance into a display-referred
buffer.** AE's integer worlds hold values in the project working space, which is
display-encoded; only the 32 bpc float world is linear. The conversion loop
multiplied linear radiance by 255 and stored it with no transfer curve, so
everything below mid-grey collapsed towards black and only values above 1.0 — the
sun — survived.

Measured on one 1920x1080 render, written versus sRGB-encoded: ground **18/255
against 74**, top of the sky **106 against 169**, whole-frame mean **86.6 against
137.3**. Combined with defect 1 the result was a frame that was entirely ground at
18/255 — black to the eye, with a faint warm smear near the top edge. That is
exactly what was reported.

Fixed with the sRGB OETF in `encodeSrgb()`, colour channels only: alpha is
coverage and never takes a transfer curve. **sRGB is a stopgap.** The honest
version reads the project's actual working space, which can be Rec.709, Rec.2020
or linear. sRGB is the default and therefore right more often than linear is.

**3. The camera's frame size was the REQUESTED rect, not the buffer.**
`preRender` stored `output_request.rect` into `view.widthPx/heightPx`. Measured on
a plain 1920x1080 comp, AE requests `[-192,-108 2304x1296]` and hands back an
output world of `1920x1080` — so every ray was divided by a denominator 20% too
large. The field of view silently widened and the image slid off centre. The
request origin was ignored entirely.

The frame is now `in_data->width/height`, and the buffer's offset within it comes
from `in_data->output_origin_x/y`, read at RENDER time because that is when AE
fills it in. `ViewParams` gained `originX/originY` and the kernel adds them before
dividing. `sizeof(ViewParams)` 92 -> 100; the tripwire assert and `viewHash` moved
with it.

**4. The CPU render was one blocking call with no abort check and no progress
report.** A 1920x1080 frame at the then-default 64 samples took **3m43s**. AE had
nothing to draw and no way to cancel, so the host sat frozen and never painted a
frame — which presents as "the effect renders nothing", not as "the effect is
slow".

Now rendered in bands of rows with `PF_ABORT` and `PF_PROGRESS` between them.
**Split by ROW and not by SAMPLE on purpose**: every pixel still gets its whole
sample budget inside one `renderCpu` call, so the per-sample sum is grouped
exactly as before and the golden images stay byte-identical. Chunking by sample
would regroup that sum, and floating-point addition is not associative.

**5. `PF_RenderOutputFlag_GPU_RENDER_POSSIBLE` was claimed by a build with no GPU
path.** With CUDA stubbed out, AE would hand a 32-bpc-float project to
`SMART_RENDER_GPU`, which has nothing to render with and can only return an error.
The code assumed AE then falls back to the CPU. **That assumption is still
untested** — it was removed rather than verified, because not making the claim
costs a stubbed build nothing.

### Two "deliberate" decisions that were never measured

**The four-thread cap in `CpuRender.cpp`** was justified by the claim that a
full-width pool under multi-frame rendering would be "slower than single
threaded". Measured on an 8-core/16-thread i7-10700K, 960x540 at 8 samples, with N
renders running concurrently:

| concurrent frames | 4 threads each | 16 threads each |
| --- | --- | --- |
| 1 (interactive) | 6.55 s | **2.04 s** |
| 4 (MFR) | 8.13 s | **7.99 s** |
| 8 (MFR) | 16.82 s | **15.99 s** |

Oversubscription costs nothing — the scheduler absorbs it, and the wide pool is
marginally faster even at eight concurrent frames. The cap bought no throughput
under the case it was written for, and cost **3.2x** on the case that hurts. It is
gone. AE's own threading suite is still the right answer, because it knows the
host's budget instead of guessing it from the hardware.

**The 64-sample default** was a value for the FINISHED renderer, inherited by a
placeholder with no stochastic transport. A sample buys one thing today: a
jittered ray inside the pixel. `skyRadiance()` is a deterministic function of a
direction, so there is no noise for a second sample to converge.

Measured at 960x540 against a 64-sample reference: away from the horizon line,
**one sample differs by at most 2/255**, whole-frame mean difference 0.12/255. The
horizon row differs by up to 224 — and raising the count does not fix it, because
that speckle is the 24-step quadratic march at grazing angles, not sampling noise.
So 64 cost 64x the render time to improve a single row that stayed wrong anyway.

The default is now **1**, changed in `CloudParams.h` and the parameter table
together. The valid range is untouched. **This goes back up with the Phase 2
transport** — it is not a claim that path tracing is cheap, it is a statement that
this renderer does not path trace yet.

### The net effect

| | before | after |
| --- | --- | --- |
| 1920x1080, default settings | 3m 43s | **1.08 s** |
| 960x540 | — | 0.27 s |
| 480x270 | — | 0.08 s |

### Instrumentation, which is why any of this was findable

The render path had **no logging at all**. The log proved the plugin LOADED and
said nothing about whether AE ever asked it for a pixel, so "renders nothing" and
"still rendering" were indistinguishable from outside.

It now logs the pre-render request and frame size, the result rect (saying so
loudly when it is empty, since that makes AE skip `SMART_RENDER` entirely), which
path AE chose, the pixel format, the buffer origin, and the elapsed time per
frame. `PF_Cmd_RENDER` is named rather than swallowed by `default`.

`mistytunec` gained `--pitch`. It could not previously reproduce the effect's own
camera, so **every golden image was taken through an identity camera looking at
the horizon, and the framing the host actually uses had never been rendered
once**. Defect 1 was invisible from the test suite by construction.

### Verified now, and what is still NOT

Verified in the running host, both on the CPU smart render path:

- **8 bpc**, full resolution, 1:1 downsample. Format arrives as the `'argb'`
  fourcc, `rowbytes` 7680 on a 1920-wide buffer — 4 bytes per pixel.
- **32 bpc float**, full resolution, 1:1 downsample. Format `'ae32'`
  (`PF_PixelFormat_ARGB128`), `rowbytes` 30720 — 16 bytes per pixel. Rendered in
  1.16 s against 1.19 s for the same frame at 8 bpc, which is the expected shape:
  the float path writes straight into AE's buffer with no staging copy and no
  transfer curve, because that world is linear.

Note what those two together establish: the transfer curve is applied on exactly
the paths that want it and not on the one that does not. That was the defect that
made the effect look black, and it is now checked in both directions rather than
in one.

Still unverified, and the Phase 1 exit criterion is NOT met until they are:

- **16 bpc has never been exercised.** The 0..32768 scaling — not 0..65535, which
  is the classic way to get 16 bpc half as bright — is still code nobody has run
  inside a host.
- **Reduced resolution has never been exercised.** Every observed render was
  `downsample=1/1,1/1`, so `view.originX/originY` have only ever been 0,0 and the
  frame-versus-window split is untested against a real window.
- ~~The GPU kernel has never run INSIDE AFTER EFFECTS.~~ **It does now**, through
  `renderCudaToHost()` inside the ordinary CPU smart render: 20 ms for 1920x1080 at
  32 bpc against 1.16 s on the CPU. `PF_Cmd_SMART_RENDER_GPU` is still never
  called — AE reports `what_gpu=NONE` — so that command remains dead code.
- ~~The effect does not use `renderCudaToHost()` yet.~~ **Done.**
  `smartRenderCpu` is now `smartRenderHost` and uses the GPU when a device is
  present, in bands of rows, falling back to the CPU for the rest of the frame if a
  band fails. Still unrun inside AE at the time of writing.
- **Whether AE falls back to the CPU after a GPU render error.** Assumed, never
  measured. See defect 5.
- **The `--` classifier readout draws a 0..1 slider** in the effect panel instead
  of being a text-only row. Observed, not yet investigated.

### CUDA — the kernel compiles, runs, and matches the CPU reference

Toolkit **13.4**, and it accepts the VS2019 host compiler: `host_config.h` gates on
`_MSC_VER < 1920 || _MSC_VER >= 1960` and MSVC 14.29 is 1929. The earlier worry
about needing VS2022 was wrong.

Four blockers stood between "toolkit installed" and "kernel compiles", none of
which named itself:

**1. No CUDA MSBuild integration.** CMake's Visual Studio generator compiles `.cu`
through MSBuild, and the toolkit installs that integration only into full Visual
Studio. Build Tools 2019's `BuildCustomizations` folder had no CUDA files, so
`check_language(CUDA)` returned NOTFOUND and the build silently selected
`CudaStub.cpp`. Fixed by copying the five files from the toolkit's own
`extras/visual_studio_integration/MSBuildExtensions/` — NVIDIA's documented fix,
needs admin.

**2. `CUDA_PATH_V13_4` missing from the environment.** `CUDA 13.4.props` derives
`CudaToolkitDir` from that VERSIONED variable, not from `CUDA_PATH`. The installer
sets it machine-wide, so a fresh shell is fine — but **any shell already open
across the install inherits a stale environment**, and an editor's integrated
terminal carries that staleness for as long as the editor stays open.

**Configure and build read the environment at different moments, and that is what
makes it nasty.** A tree configured in a good shell caches "CUDA found"; building
that same tree from a stale shell then fails inside a `.targets` file with
`The CUDA Toolkit directory '' does not exist`, followed by `LNK1181` on
`cudart_static.lib` because the empty directory also emptied the library search
path. Neither message mentions the environment, and the tree looks correctly
configured — because it was. Hit for real, in exactly that shape.

Fixed permanently in `cmake/Cuda.cmake`, in two halves, because the two failures
have different timing:

- Before `check_language(CUDA)`, CMake now DISCOVERS the toolkit (from `CUDA_PATH`
  if set, else the newest `v*` under the standard install directory, sorted
  `COMPARE NATURAL` so `v9.0` cannot outrank `v13.4`) and exports the versioned
  variable itself with `set(ENV{...})`, which reaches every process CMake spawns.
- After `find_package(CUDAToolkit)`, `CudaToolkitDir` is pinned into every
  generated project via `CMAKE_VS_GLOBALS`, so the BUILD step never consults the
  environment again.

Same rule as `cmake/AESDK.cmake` finding After Effects through the registry:
locate it once, write it down, do not ask the environment twice. **Verified**: a
clean build with `CUDA_PATH` unset, `CUDA_PATH_V13_4` unset and every CUDA entry
stripped from `PATH` configures, compiles the kernel and exits 0.

**3. `compute_61` no longer exists.** CUDA 13 removed Maxwell, Pascal and Volta;
`nvcc --list-gpu-arch` starts at `compute_75`. The architecture list began at 61,
which is now `nvcc fatal : Unsupported gpu architecture 'compute_61'`. **The
minimum GPU is Turing for as long as the build uses a 13.x toolkit** — a
constraint discovered, not the Phase 2 measurement, which can only raise this
floor. See the note in `cmake/Cuda.cmake`.

**4. MSVC host flags were reaching nvcc directly.** `add_compile_options()` applies
to EVERY enabled language, so once CUDA was one of them the top-level
`/permissive- /W4 /utf-8` landed on nvcc's own command line. nvcc does not
recognise a bare MSVC switch and treats it as another INPUT FILE:

    nvcc fatal : A single input file is required for a non-link phase
                 when an outputfile is specified

which names neither the flag nor the language and reads like a broken source file.
The flags are now scoped with `$<COMPILE_LANGUAGE:...>` and routed through
`-Xcompiler` for CUDA. **This was latent from the day CUDA support was written**
and could not have been found without a toolkit present.

### The kernel is correct

`mistytunec` now has a GPU path — `renderCudaToHost()` allocates a device buffer
with the SAME pitch as the host one, launches, copies back one linear block, frees.
The matched pitch is deliberate: the kernel sees an identical `Surface` layout on
both paths, so a pitch bug cannot hide on one of them.

That is what finally makes the cross-path comparison writable — **the half of this
tier that has been a plan since it was created**, because the kernel could not run
outside a host. Result, against the CPU-blessed references, at the normal tolerance
of 2:

| scene | GPU vs CPU reference |
| --- | --- |
| midday | max **0** |
| sunset | max **0** |
| horizon | max **0** |

Byte-identical, not merely within tolerance. The `--fmad=false --prec-div=true
--prec-sqrt=true` flags in `cmake/Cuda.cmake` were written to make exactly this
true and they do. (A larger 960x540 scene shows max 1/255 at a single pixel, which
is the transcendental-library difference the tolerance exists for.)

`tests/golden/` now runs 10 tests instead of 7: three CPU comparisons, three GPU
comparisons, three determinism tripwires, plus the unit suite.

**Two test meanings changed silently when the CLI learned to prefer the GPU, and
both are now pinned.** `mistytunec` renders on the GPU BY DEFAULT when a device is
present, so `add_golden_scene` and `RunDeterminism.cmake` both pass `--cpu`
explicitly now. Without it, `determinism.threadCount` would have compared two
identical GPU renders — `--threads` is meaningless on that path — and become a test
that cannot fail. The golden references are blessed from `--cpu` for the same
reason: a reference must not depend on whether the machine that blessed it had a
card.

The GPU comparisons pass `--require-gpu`, a new flag that FAILS instead of falling
back. A GPU test that quietly rendered on the CPU would report green while checking
nothing, which is the failure this file already refuses to tolerate for missing
references. Verified to exit 3 when the GPU does not run.

### Speed, measured

1920x1080, i7-10700K at full thread width against an RTX 2070 SUPER:

| samples | CPU | GPU | speedup |
| --- | --- | --- | --- |
| 1 | 1.17 s | 0.19 s | 6x |
| 16 | 17.65 s | 0.30 s | 59x |
| 64 | 66.88 s | 0.67 s | **100x** |

The GPU barely notices the sample count below ~64, which is what an occupancy-bound
kernel looks like when it is not yet saturated. Do not read these as Phase 2
numbers: this is 24 analytic march steps, not null-collision tracking with
multiple scattering.

### AFTER EFFECTS STILL WILL NOT USE IT, AND THAT IS NOT THE EFFECT'S DOING

On this machine — AE 2026, 32 bpc float project, Mercury GPU Acceleration set to
CUDA, a card AE itself hands the effect at `GPU_DEVICE_SETUP`:

    GPU_DEVICE_SETUP: device_index=0 framework=CUDA
      AE says compatible: yes
      renderer will use : NVIDIA GeForce RTX 2070 SUPER (sm_75, 8191 MB, 40 SMs)
    PRE_RENDER: AE offers what_gpu=NONE device_index=-1 bitdepth=32
    SMART_RENDER: AE chose the CPU path.

**AE settles `what_gpu` BEFORE asking the effect what it can do**, so
`PF_RenderOutputFlag_GPU_RENDER_POSSIBLE` never enters into it and
`PF_Cmd_SMART_RENDER_GPU` is never called. Two hypotheses were tested properly,
each with a version bump so AE could not serve a cached registration, and **both
were wrong**:

- **Dropping `PF_OutFlag2_I_USE_3D_CAMERA`** (out_flags2 167777280). No change.
  Recorded in `cmake/EffectFlags.cmake` so nobody re-runs it.
- **Adding `PF_OutFlag_PIX_INDEPENDENT`** (out_flags 33555456). No change — but it
  was kept, because the old reasoning for omitting it was simply wrong. The SDK
  says the flag is about "the pixels around it", i.e. the INPUT IMAGE; the old note
  argued from "every pixel of a path trace depends on the whole field", which is
  the SCENE. Mistytune is a generator and does not read its input at all. The same
  note also attributed `I_SHRINK_BUFFER`'s behaviour to this flag.

The only registration difference left against `SDK_Invert_ProcAmp` — the sample AE
does GPU-render — is `PF_OutFlag2_SUPPORTS_DIRECTX_RENDERING`, which cannot be set
honestly without a DirectX kernel behind it. Worth noting the sample sets it
alongside CUDA support on Windows.

**This no longer blocks anything**, which is the point of `renderCudaToHost()`. It
is the approach most GPU-using AE plugins take — own the device memory, launch from
inside the ordinary CPU smart render, copy back — and it keeps the comp camera,
keeps `I_USE_3D_CAMERA`, and costs one device-to-host copy per frame, which is
nothing against a path trace. **The effect does not use it yet**; wiring
`smartRenderCpu` to try the GPU first is the obvious next step and was not taken in
the same pass that proved the kernel correct.

### The effect uses the GPU now, through the CPU command

`smartRenderCpu` is `smartRenderHost`, and the rename carries the meaning: After
Effects calls `PF_Cmd_SMART_RENDER` and hands out an ordinary CPU world, but what
FILLS that world is a separate question, and on a machine with CUDA the answer is
the card. Both bit-depth paths go through it — 32 bpc writes straight into AE's
buffer, 8 and 16 bpc through the float staging buffer and then the sRGB encode.

**One band loop, two engines.** The loop that already existed for `PF_ABORT` and
`PF_PROGRESS` now drives either `renderCudaToHost()` or `renderCpu()`, with the
band budget chosen per engine because the two are three orders of magnitude apart:
256K pixel-samples on the CPU (~1.7 us each), 32M on the GPU (~5 ns each). Both
land near a quarter second, which is what keeps abort responsive AND keeps every
GPU launch clear of the Windows display-driver timeout.

The row floor differs too: two rows per CPU worker, or the kernel's 16-row block
height on the GPU, because a band shorter than one block wastes most of the threads
in it.

**A failed GPU band falls back for the rest of the frame rather than failing it.**
A driver reset or an out-of-memory partway down should cost a slow frame, not a
black one, and the bands already written stay valid because both engines write
identical pixels. The log names it so the slowness is never a mystery.

**THE BAND IS A WINDOW, NOT A CROP**, and this is the part that was easy to get
wrong. The device buffer holds only the band's rows, while `view.originY` moves
down by the band's first row so every ray still knows its position in the FULL
frame. Get it wrong and every band renders the top of the picture — horizontal
stripes of repeated sky.

`determinism.gpuBands` is the only test that catches it: the same scene rendered in
one launch and in bands of 37 rows (deliberately awkward — not a divisor of the
height, not a multiple of the 16-row block) must be byte-identical. **Verified to go
red as well as green**: with the `originY` offset removed it fails with a message
naming the cause, while all three `golden.gpu.*` scenes still PASS, because a
whole-frame render has exactly one band and cannot see the bug. That is precisely
why the test had to exist separately.

The suite is 11 tests now: unit, three CPU golden, three GPU golden, and four
determinism tripwires.

### The kernel runs inside After Effects

Measured in AE 2026, 1920x1080, 32 bpc float, one sample, RTX 2070 SUPER:

    SMART_RENDER_HOST: format=842229089 output=1920x1080 rowbytes=30720 samples=1
      rendered 1920x1080 on the GPU in 0.13 s (1080 rows per band)   <- first frame
      rendered 1920x1080 on the GPU in 0.02 s (1080 rows per band)
      rendered 1920x1080 on the GPU in 0.02 s (1080 rows per band)

**20 ms a frame, against 1.16 s on the CPU at the identical settings — 58x, in the
host.** The first frame's 0.13 s is CUDA context initialisation and is paid once per
AE session, not per frame.

Note that `SMART_RENDER: AE chose the CPU path` still appears directly above it, and
both lines are true: AE chose its CPU COMMAND, and the effect filled the buffer with
the GPU. That pair of lines is the whole design in two sentences.

**At one sample there is exactly one band.** The 32M pixel-sample budget works out
to 16,666 rows at 1920 wide and clamps to the frame height, so there is no abort
granularity at all on this setting — which does not matter at 20 ms and would matter
a great deal at 512. The bands appear as the sample count rises: 64 samples gives
about 5 bands of 260 rows.

### What this cost, end to end

The same comp at the start of the day rendered in **3 m 43 s** and looked black. The
distance covered is not one fix:

| | |
| --- | --- |
| camera pointed 20 deg below the horizon | every pixel was ground |
| linear radiance into a display-referred buffer | ground at 18/255, read as black |
| camera frame size taken from the requested rect | wrong field of view, off-centre |
| one blocking call, no abort, no progress | AE frozen, frame never painted |
| 4-thread cap justified by an unmeasured claim | 3.2x on the case that hurts |
| 64-sample default on an analytic sky | 64x the time for 2/255 of difference |
| CUDA never compiled | the card idle on a machine that had one |

### Still not done

- **`PF_Cmd_SMART_RENDER_GPU` is dead code here.** AE reports `what_gpu=NONE` and
  never calls it, so `renderCuda()` is reached only through `renderCudaToHost()`.
  The one-launch-for-all-samples hazard in `smartRenderGpu` is therefore still
  unfixed AND still unreachable. It needs the chunked loop before AE is ever
  persuaded to call that command — and nothing here has persuaded it yet.
- **`renderCudaToHost()` allocates and frees per band.** At 20 ms a frame the
  cudaMalloc and the 33 MB copy back over PCIe are now a measurable fraction of the
  total rather than noise. A buffer that persisted between frames is the obvious
  next win and is the same device allocation progressive accumulation needs.
- **Nothing is cached between renders.** Every parameter change re-renders from
  scratch, including Exposure and AgX Tonemap, which are pure post-transforms
  applied after the radiance is computed and should cost nothing at all.
- **16 bpc and reduced resolution are still unexercised**, in both engines. Every
  render observed all day was 8 or 32 bpc at `downsample=1/1,1/1`, so
  `view.originX/originY` have only ever been 0,0 from AE's side — the band path
  exercises the Y offset, but a real reduced-resolution window never has.

---

## 2026-09-26 — Phase 0 prototype built; Phase 1 re-scaffold done

> **SUPERSEDED by the entry above**, which was written later the same day. The
> table below is what this was BELIEVED to be before the effect was run in After
> Effects; four of the things it records as done were not, and its "still
> unverified" list was not a list of things that were probably fine. It is kept
> because the log is chronological and because what someone believed at the time is
> part of the record.

### Where the project actually stands

| Phase | State |
| --- | --- |
| **0 — prototype and look verdict** | **PASSED.** Prototype built, run on real hardware, and judged to read as realistic. The gate is cleared and Phase 2 is unblocked. |
| **1 — re-scaffold, GPU pixel in AE** | Scaffolding done. **Installs and loads in AE 2026 (26.2.1)** — `GLOBAL_SETUP` runs and the registration is accepted. Still unverified: applying the effect, the three bit depths, reduced resolution, and the GPU device line. CUDA path **unbuilt** — no toolkit on this machine. |
| 2 and later | Unblocked, not started. |

### The Phase 0 verdict — given, and passed

Judged on real hardware against the criterion fixed in `PLAN.md` before the work
started. The look was accepted as realistic. **Phase 2 may proceed**: the
prototype's transport is now the reference the Slang port is checked against, and
`proto/` is kept for exactly that.

### Installing

Use **`.\build.ps1 -Install`**. It finds After Effects through the registry,
which is the only thing that reliably knows where it is: this machine has AE at
`F:\Adobe suite\Adobe After Effects 2026`, plus leftover `24.0` and `25.0`
registry keys with blank `InstallPath` and a stale
`C:\Program Files\Adobe\Adobe After Effects 2024` folder containing no
executable. Any hand-rolled search of `<drive>\Adobe` finds the dead one and
installs into it, and the symptom is an effect that never appears with no error
anywhere. The script already skips blank-`InstallPath` keys and ranks versions
numerically; use it rather than copying by hand.

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
