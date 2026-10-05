# Progress

Tracked against `PLAN.md`. Newest first.

---

## 2026-10-03 — THE CLOUDS ALONE: BACKGROUND TRANSPARENT, AND SHOW SUN. Build 31, still minor 15. Two new controls. **Background** (under Render Quality): Sky, or Transparent (Clouds Only), which gives the clouds premultiplied over nothing, with alpha from their own transmittance, for use over other layers. **Show Sun** (Sun and Sky): off hides the sun's disc from the camera and leaves every cloud lit exactly as before. With both at their defaults a frame is byte-identical to build 30 (cirrus, hero, Draft, field, city depth pass). Transparent laid over the clear sky gives back the sky render to 0.001%. Transparent costs about the same as Sky, and less when the cloud is small in frame. Displace Volume moves to build 32. INSTALLED (2026-10-03), NOT YET SEEN IN THE HOST.

### What was asked

"Is there a way for me to have a hero cloud alone without the sky etc, so I can use with other layers?" Build 30's Holdout already could, with a black solid as the depth pass, Open Sky Cutoff 0 and Farthest 100 km (tested in the CLI first). Then: "Yeah lets have a proper. Need so the renders can even be faster too. Prolly fine to have the option to switch off or on the sun. But still have it affect the cloud. Just not show."

### What was built

- **Background** (POPUP, ID 309, "Sky|Transparent (Clouds Only)", default Sky): inserted directly under Render Quality, because it is a mode a session switches. `ViewParams::transparentSky`, hashed in `samplingHash`. ViewParams' sizeof did not move (the bool fits in padding), so a test pins the hash.
  - **The kernel:** `pixelSampleRay` gives every camera ray that no depth pass stops `tGeo = kSkyGeometry` (1e29), geometry at infinity: past the top of the air (airSegment stops there) and past every cloud (slabRange stops at 120 km), below `kNoGeometry` (1e30). Build 30's holdout does the rest: colour R − T·H, alpha 1 − T. Here H is the whole clear-air airlight along the ray, so the result is (1 − T)·(air in front) + (the cloud as seen through that air): the clouds with the haze in front of them, the sky behind them gone. The sun and sky still light the clouds; bounced paths never see the geometry.
  - **A depth pass still wins:** its own geometry stops the ray where it stands. Transparent + Composite with a depth pass lays the clouds over the footage everywhere, the footage's own sky included.
  - **The early-out:** a transparent ray whose camera walk met no cloud at all (`psSee >= 1`) returns before the airlight's march (`Scene.clearSky`). All it could add is the air less the same air clear: zero, or below zero where a cloud's shadow lies in that air, which the mean's clamp removes anyway.
  - **The clamp** in `finishPixel` now applies to transparent frames as to depth-pass frames.
- **Show Sun** (CHECK, ID 115, default on): inserted after Sun Intensity. `AtmosphereParams::showSunDisc`, hashed in the field fingerprint. `Scene.hideSunDisc`: `pathEnvironment` passes `first && hideSunDisc == 0` as `includeSunDisc`, so only the camera's unscattered view of the disc changes. The sky's glow round the sun stays; that is the sky.
- **The denoise for the clouds alone** (`denoiseCpu`, Denoiser.{h,cpp}):
  - **Guided:** a transparent frame takes build 30's alpha guide.
  - **The crop:** `alphaCrop` finds the box round every pixel with alpha > 0, adds a 32-pixel margin and rounds the size up to 128-pixel steps (the filter is rebuilt when the size changes, which is the expensive call). `denoiseCpu` filters only that window of the buffer. Outside it the guided filter's answer was exactly zero anyway. A frame with no alpha at all is not filtered.
  - **Pinholes:** build 30 put every pixel whose raw alpha was exactly 0 back to exactly 0. For a depth pass's building that is right. For the clouds alone at one sample it left the soft edge PEPPERED WITH HOLES (156 at 640x360, 1 spp; the same count through build 30's own holdout). `DenoiseImage::exactZeros` (true with a depth pass, false for the clouds alone) lets the denoised alpha decide instead; only what it leaves below half an 8-bit level is zeroed. build/tmp/b31 has the before and after.
  - **The GPU offer:** withdrawn under Transparent, as a depth pass withdraws it, so the alpha's denoise and crop always run. The host path still traces on CUDA.
- **AE log:** `background sky|transparent (clouds only), sun disc shown|hidden`, and `transparent background -- not offering GPU_RENDER_POSSIBLE.`
- **CLI:** `--transparent` and `--hide-sun`, in the scene options' own chain.

### Measured

- **Defaults are build 30's to the bit:** five scenes (cirrus 8 spp, hero 8 spp, hero Draft, field 4 spp, city depth pass holdout 4 spp) compared byte for byte against build 30's CLI.
- **Transparent against build 30's black-solid trick** (640x360, 32 spp): alpha identical to 0.0000 mean; colour mean |d| 0.02 levels, max 18 (the skipped shadow-in-the-air term, per sample instead of after the mean).
- **Speed, 1080p, CLI median of 5** (each includes about 0.23 s of process and CUDA start-up AE does not pay):

| Scene | Sky | Transparent | Build 30 trick |
|---|---|---|---|
| Hero at 4 km, 1 spp + denoise | 0.78 s | 0.78 s | 0.87 s |
| Hero at 4 km, 4 spp + denoise | 1.69 s | 1.67 s | |
| Hero at 9 km, 4 spp + denoise | 0.81 s | 0.74 s | |
| Hero at 4 km, Draft | 0.51 s | 0.52 s | |

  The sky was never the cost: a full 1080p frame of nothing but sky traces in 0.03 s per sample, against 0.29 s for the hero. What Transparent saves (the sky's airlight, the denoise outside the cloud) about pays for what it adds (the alpha's own filter). It is faster in proportion to how little of the frame the cloud fills.

### Tests

- **TestSceneDepth** (+5): a transparent clear sky is exactly zero, colour and alpha. The transparent clouds over the clear sky give back the render (0.001%, worst pixel 0.13%). A depth pass's geometry is untouched by the switch. Hiding the sun leaves a frame with the disc out of view bit-identical, clouds included. With the sun dead ahead, hiding it takes the brightest pixel from 1358 to 0.68 and moves only the 4 pixels under the disc.
- **TestDenoiser** (+6): the crop (none for no alpha; margin and whole steps; slides inside at the edge; whole frame when larger; a window into the same buffer), and pinholes fill for the clouds alone (mean alpha 0.98) but stay exactly zero with a depth pass, with the clear sky exactly zero either way.
- **TestFieldCache** (+1): Transparent restarts the accumulation. **TestFingerprint:** `showSunDisc` is in the coverage list.

### What to look at in AE

- **Background → Transparent (Clouds Only)** on a solid above other layers: the hero alone, over whatever is underneath. Hero Cloud Alone, and Ice Layer off, for the hero by itself.
- **Draft** with Transparent: the edge should be soft, not peppered.
- **Show Sun off** with the sun in frame (Sun Placement Backlit and a low Sun Elevation): the disc goes, the cloud's lit edge stays.
- **Log:** `background transparent (clouds only), sun disc hidden`.

---

## 2026-10-03 — SCENE INTEGRATION: A DEPTH PASS STOPS THE CAMERA RAY AT THE FOOTAGE'S GEOMETRY. HOLDOUT AND COMPOSITE. Build 30, still minor 15. A new Scene Integration topic. A Depth Pass layer, either an AI depth map of the footage or a 3D app's Z pass, says how far away each pixel's building is. Every camera ray that lands on one stops there. Cloud nearer than the building is drawn in front of it, and cloud behind it is not drawn. The geometry comes out transparent, with alpha taken from the clouds' own transmittance in front of it. Composite lays the result over the layer the effect is applied to; Holdout leaves that to AE. With no depth pass a frame is byte-identical to build 29 (GPU, CPU, Draft, light layer). The holdout's algebra closes to 0.001% through the kernel. Best is 3 to 9% faster with a depth pass; Draft is about 0.1 s slower at 1080p. Displace Volume is next. INSTALLED (2026-10-03), NOT YET SEEN IN THE HOST.

### What was asked

"Continue with scene integration until you need me to test something in AE." PLAN.md's Phase 4 lists scene integration as holdout, composite and displace-volume. The design spec's section (recovered from an earlier session's transcript, since no session here can read the Claude Docs spec):

> Depth is not a look-driver, it is an integration tool, so it gets its own section. **Composite** interleaves cloud with geometry per-pixel. **Displace Volume** pushes the density field away from anything in the depth pass, so cloud parts around a building rather than intersecting it.

This build is holdout and composite. Displace Volume is build 31.

### What was built

- **The Scene Integration topic** (params 900–913, after Lights):
  - **Depth Integration:** Off, Holdout (Transparent), or Composite Over This Layer (the default). Nothing happens until a Depth Pass is picked.
  - **Depth Pass:** a layer.
  - **Depth Pass Is:** Brighter Is Nearer (AI Depth), Brighter Is Nearer (Linear), or Brighter Is Farther (Linear).
  - **Nearest (m)** (default 10) and **Farthest (m)** (default 2000): planar distances along the lens axis.
  - **Open Sky Cutoff (%)** (default 2).
  - Six spares, two of them held for Displace Volume.
- **The depth pass** (src/engine/SceneDepth.{h,cpp}): resolved on the host to metres along the view axis and a coverage per texel.
  - **Reading:** Rec. 709 luma of the straight colour, as the relief reads it. The alpha is the coverage, so a soft key edge is a soft holdout edge.
  - **AI depth:** a disparity, so equal steps of brightness are equal steps of 1/distance.
  - **Open sky:** the far end of the range beyond the cutoff, or no alpha, is no geometry.
  - **Size:** kept at the layer's size up to 4096 on a side, subsampled past that and never filtered (a mean of a building and the sky is neither). Matched to the frame by fraction, so a pass at another resolution lines up.
- **The kernel** (BounceLib `pathBegin`, `cameraSegmentSun`; Shading.h `sceneGeometryAlong`):
  - **The stop:** each sample reads the pass at its own jittered spot (Draft: at the block's centre) and turns the planar depth into a distance along its ray. The camera walk and the free flights stop there. Only the camera ray sees the geometry: bounced paths do not hit it, and it casts no shadow.
  - **What comes back:** the premultiplied colour R − T·H and the alpha 1 − T. R is what the ray gathers in front of the geometry, with the geometry black. T is the clouds' ratio-tracked transmittance to it. H is the clear air's airlight over the same stretch, which the footage already has.
  - **Why the subtraction:** SceneDepth.h has the algebra. AE's own "over" of that pixel on the footage is the truth: a building with nothing in front of it is exactly transparent, and a cloud in front of it is exactly as hazy as the same cloud beside it against the sky.
  - **Determinism:** the walk's end is the only change, and `kNoGeometry` (1e30) moves no comparison and draws no number. That is why a frame without a pass is build 29's to the bit.
  - **The alpha's home:** the accumulator's fourth float, always present and always zero until now, so the resolve path and the cache carry it.
  - **The transform:** it divides a partly transparent pixel by its alpha, transforms it, and multiplies back. At alpha 1 the line is unchanged.
- **The denoiser, with a depth pass** (`DenoiseImage::alphaGuide`):
  - **The guide:** the alpha is denoised by an LDR filter of its own, then goes to the colour's filter as its albedo guide.
  - **Exact zeros:** where the alpha is exactly 0, both colour and alpha are put back to exactly 0.
  - **Why:** without a guide, sky colour smeared into the transparent tower blocks came back multiplied by 1/alpha as a light-blue dotted outline at Draft. Without the alpha's own pass, a stray opaque block along a cloud's thin edge was a dark speck. build/tmp/b30/r1/m5.png and m7.png show before and after.
- **Composite** (`compositeOverPlate`): after the transform, in the space AE would blend in, out = clouds + footage × (1 − alpha). The input's buffer offset comes from its own checkout rect.
- **AE:**
  - **Checkout:** the pass is checked out at pre-render like the light layer, and not at all when Depth Integration is Off.
  - **GPU:** the pass withdraws the GPU offer, as a shape or a light layer does. The host path still renders on CUDA.
  - **Key:** the map's hash goes into the render key; Holdout or Composite does not, because they trace the same samples.
  - **Log:** the line is `depth pass: WxH -> WxH map, N texels of geometry, near to far m, encoding, mode`.
- **CLI:**
  - **Options:** `--depth <file|city>` (`city` is a built-in skyline in three ranks), `--depth-encoding ai|near|far`, `--depth-near`, `--depth-far`, `--sky-cutoff <pct>`, `--scene holdout|composite`, `--plate <file|city>` and `--alpha-out <pgm>`.
  - **Parser:** the options parse in a chain of their own, because the main `else if` chain hit MSVC's limit of 128 nested blocks.

### Tests

- **TestSceneDepth** (11 tests):
  - **Encodings:** disparity is linear in 1/distance; both linear encodings run the right way.
  - **The map:** the open sky is cut at the far end, the map reads the straight colour and keeps alpha as coverage, an all-sky pass is no scene, and the hash follows the depths and the settings.
  - **Composite:** it is AE's normal blend.
  - **Through the CPU kernel:**
    - No pass is opaque.
    - Geometry 1 m away is exactly transparent and exactly black.
    - A half-covered texel is half geometry (alpha 0.5 ± 0.03).
    - **The algebra:** with the geometry past the top of the atmosphere, the holdout laid in linear light over a clear-sky render gives back the render without a pass. The frame mean is within 0.001% and the worst pixel within 0.13% (air shadows off; see Known limits).
- **Without a pass:** byte-identical to build 29 on six scenes, GPU and CPU: default, field, hero, hero on CPU, Draft, and the bolt light layer (build/tmp/b30/ident.sh).
- **With a pass:**
  - `--resolve-check` passes on the GPU (chunked and banded) and on the CPU (chunked).
  - A window of the composite is the whole frame's region to the bit.
  - GPU against CPU is at most 1 level on one pixel, the same as build 29 shows without a pass.
- **ctest:** 28/28 on the main build (four architectures); the unit suite on the dev build too (TestSceneDepth's 11 tests run inside the `unit` entry).

### Measured

The hero at 4 km with the built-in skyline linear from 1500 to 8000 m: towers at 2.8 km in front of it, 4.8 km through its base, and 6.5 km behind it. Montages are in build/tmp/b30/r1:

- **m1:** no pass, holdout colour, holdout alpha, and composite over the city plate. The cloud passes in front of the far towers and behind the near ones.
- **m2, m5, m7:** Draft edges, before and after the guide and the alpha's own pass.

- **Cost** at 1920×1080 on the RTX 2070 SUPER, CLI wall time:

| | no pass | composite |
|---|---|---|
| Best 4 spp | 3.48 / 3.53 s | 3.39 / 3.22 s (−3 to −9%: rays on geometry stop early) |
| Draft | 0.63 / 0.66 s | 0.73 / 0.73 s (+0.1 s: the alpha's own denoise, the guided filter, and the map) |

### Known limits

- **The clouds' shadow in the air in front of a building is lost.** It is light taken off the footage, and an "over" cannot express that, so the colour is clamped at zero. Under the default cirrus it is about 5% of a clear-sky pixel over the whole air column, and much less over a building's few hundred metres.
- **Only the camera ray sees the geometry.** A building does not shadow the cloud, and light does not bounce off it.
- **The pass is read in its own frame with transforms off.** A comp-sized layer lines up; a scaled or moved one does not.
- **Draft edges are a staircase one block wide,** softened by the scale-up and faintly outlined against the sky. The cumulus base meeting a tower shows the block grid. Best antialiases the edge over its samples.
- **A cloud that intersects a building is cut flat on its face.** That is what Displace Volume is for.

### What needs the host

- Everything. The first check is an AI depth map of real footage (Depth Anything V2 or similar) with Composite on the footage layer itself, and its Nearest and Farthest.
- Holdout on a solid above the footage.
- The input buffer's offset under a Region of Interest. The log prints `composite over this layer (WxH, offset x,y)`.
- A depth pass of moving footage, which re-uploads 16 MB a frame at 1080p.

---

## 2026-10-02 — LOCAL LIGHTS: AE'S COMP LIGHTS AND A LIGHT LAYER (SABER FOR THUNDER) LIGHT THE CLOUD FROM INSIDE IT. Build 29, still minor 15. A new Lights topic. Use Comp Lights (default on) reads the comp's point, spot, parallel and ambient lights and places each where AE's viewer shows it. Light Layer takes another layer's pixels, such as a Saber bolt on black, as a glowing sheet laid on the face of the cloud the camera sees. Every light goes through the sun's own next-event estimator: a shadow ray through the cloud, the phase function, the albedo. The clouds stay water: a light adds light and the medium is untouched. With no lights a frame is byte-identical to build 28 (GPU and CPU). A light layer costs 35 to 46% at Best and 21 to 37% at Draft (1080p). On the user's 6 km hero, the flat sheet of the first draft left the cloud black; the laid sheet lights the cloud round the bolt. INSTALLED (2026-10-02, 18:00), 28/28 tests, NOT YET SEEN IN THE HOST.

### What was asked

"Can we work on making the clouds work with Ae light or layers (incase I want to use saber lighting for thunder)?"

### What was built

- **The Lights topic** (params 800–809, after Camera):
  - Use Comp Lights (default on) and Comp Light Strength (×, default 1).
  - Light Layer, Light Layer Strength (×, default 1) and Light Layer Depth (m, default 0).
  - Three spares.
  - `PF_OutFlag2_I_USE_3D_LIGHTS` is set, so AE re-renders when a light moves.
- **Comp lights** (AEBridge.h `readCompLights`, src/engine/LocalLights.{h,cpp}): read at pre-render at the comp's time, honouring in/out points and the video switch.
  - **Kinds:** point, spot (cone and feather), parallel (a second sun) and ambient (a uniform dome every scattered path sees on its way out).
  - **Strength:** at 100% a light lights the cloud inside its radius as brightly as the sun does at Sun Intensity 1. It falls off as the inverse square past the radius (AE's Inverse Square Clamped), whatever its Falloff says. Smooth adds AE's smoothstep to zero.
  - **Placement:** the light goes where the viewer shows it. Under the Comp Camera, the scale is Comp Camera Travel, the camera's own mapping. Under the orbit rig, the comp plane goes to the hero's depth and the frame is stretched by the two lenses' ratio, so a light on the comp plane lands on the same pixel of the render. TestLights checks both by projecting.
- **The light layer:**
  - **Reduction:** the layer is box-filtered to at most 128 texels on its long side, which keeps its power. It is sRGB-decoded when the effect encodes sRGB. Premultiplied colour is the emission, so a bolt over black and a bolt on a transparent layer glow alike.
  - **Emission:** each texel is a small patch that shines every way.
  - **Picking:** the kernel draws a texel down a quadtree by power over squared distance, so a point beside the bolt finds the texels beside it.
  - **Key:** the light set's hash goes into the render key, so a flickering bolt re-renders.
  - **GPU path:** a light layer withdraws the GPU offer, as a shape does. The host path still renders on CUDA (AE has never taken the GPU offer).
- **The sheet laid on the cloud** (`conformLightSheet`):
  - **Why:** the first draft stood the sheet on one plane through the hero's middle. In a thick hero that plane is hundreds of metres behind the face. Its glow arrived only after 8 to 32 bounces, so the frame was fireflies at 512 spp (build/tmp/b29/r5/m6.png) or, on the user's hero, next to nothing (r6/m7.png). Three samplers gave the same frame: this was diffusion from a buried source.
  - **The probe:** each texel now stands where, on average, the camera's own light first scatters along its rays, plus Light Layer Depth behind that. The probe is a deterministic march of the density the render sees: `firstScatterMoments` in TransportLib, a quarter of the cell's majorant free path per step, stopping with 0.5% left. A free flight's mean from fixed random numbers would jump as the cloud moved, so the sheet would flicker.
  - **The grid:** half the sheet's resolution, probed only at the points a lit texel reads, threaded on the CPU, with texels bilinear between them.
  - **Where nothing is seen:** a point that sees no cloud takes the nearest seen face, so a bolt leaving the cloud's edge stays beside it. With no cloud behind the layer at all, the sheet sits at the hero's middle.
  - **The far limit:** faces deeper than the hero's middle plus its width or height (whichever is larger) belong to another cloud and are not probed. Without this, part of a bolt was laid on a cloud 87 km away, and its texels, 400 times the area, lit the landscape.
- **Kernel:** one light is drawn per scattering event on its own RNG stream, so the path's stream is untouched. Lights are picked in proportion to how brightly each lights the hero, floored at a tenth of the brightest's share. The shadow ray stops at the light (`transmittanceUpTo`) and never takes Draft's shadow-map hand-off, because the maps are columns towards the sun.
- **CLI:** `--light`, `--comp-light`, `--light-color`, `--light-smooth`, `--ambient`, `--sun-intensity`, `--light-layer <file|bolt>` (`bolt` is a built-in procedural bolt), `--light-layer-strength`, `--light-layer-depth`, `--light-layer-flat` (the old plane, for A/B) and `--light-layer-dump`.

### Tests

- **TestLights** (12 tests): comp lights under both cameras land on their pixel, by projection. The sheet keeps the layer's power and decodes sRGB. The probe asks only where the layer glows. A laid texel stays on its pixel at the probed depth plus Light Layer Depth, takes the nearest face where none is seen, and is floored at 10 m. The packed layout is checked field by field, and the tree's root radius holds every pushed texel.
- **slang.bounce, section 7:** one light drawn per event against every light summed by host quadrature. Point +0.06/−0.02%, spot −0.17%, parallel +0.04%, six-texel sheet +0.05%, crossed bolt −0.04%, **bolt laid on a face +0.17%**, all five −0.10% and +0.001% through the segment walk. The ambient dome is 1.0 standard error out.
- **slang.transport, FIRST SCATTER:** the march against closed forms through a constant slab (mean 1312.7 m against 1310.6 at 1× majorant, the step midpoint's expected +2 m; 1310.6 at 20×), stopped by tMax (1201.3 against 1199.2), a slab thick enough to stop early (1049.1 against 1050.0) and the sharp core through the stored grid (1412.0 against a 5 cm quadrature's 1411.9).
- **No lights:** byte-identical to build 28 on four scenes, GPU and CPU (build/tmp/b29/ab2).
- **ctest:** 28/28 on the dev build.

### Measured

Two night heroes (Sun Intensity 0) with the built-in bolt. A is the default hero at 4 km. B is the user's settings: Hero Width 6000, Inversion 7000, Density 0.1, at 9 km. Montages are in build/tmp/b29/r9 (m10: flat against laid; m11: Light Layer Depth 0/50/150/400).

- **Flat against laid:** on B the flat sheet leaves the cloud black, and the laid one lights it round the bolt. On A the glow follows the bolt's channel down the face where the flat sheet gave a diffuse patch.
- **Brightness:** with the layer laid, 17% (A) and 10% (B) of the lit cloud clips at 8 bits, and the median lit pixel is 126 (A) or 89 (B). In daylight 20% and 15% of the frame clips. So a bolt at strength 1 lights the cloud near it about as the sun lights a cloud top, as `kLightLayerRadiance` (100) intends. Light Layer Strength turns it down.
- **Light Layer Depth:** 0 is the crispest glow. Deeper is softer and wider, and on B at 150 m the cloud in front starts to shade it.
- **The probe:** 338 of 64×36 points, 19 ms on A and 26 ms on B.
- **Cost** at 1920×1080 on the RTX 2070 SUPER, CLI wall time, best of three:

| | no layer | flat sheet | laid sheet |
|---|---|---|---|
| A, Best 4 spp | 3.29 s | 4.46 s | 4.48 s (+36%) |
| A, Draft | 0.63 s | 0.78 s | 0.76 s (+21%) |
| B, Best 4 spp | 8.78 s | 11.78 s | 12.81 s (+46%) |
| B, Draft | 0.96 s | 1.24 s | 1.31 s (+37%) |

### Known limits

- **Noise in a night lit only by the bolt:** at 64 spp undenoised it is still sparkles round the glow. Denoise is what makes 16 spp usable.
- **The cost is one more shadow ray per scattering event,** whichever light is drawn, and it scales with how many events a path has. The probe itself is negligible.
- **The sheet follows the camera's view:** move the camera and it is re-laid on the face now seen. A bolt "inside" the cloud is Light Layer Depth, not a position.
- **The layer is read in its own frame with transforms off:** a comp-sized layer lines up, but a scaled or moved one does not.
- **Falloff:** AE's falloff enum is read 0-based and its raw values are logged. That is unchecked against a real comp.

### What needs the host

Everything: a real Saber layer (its brightness and its glow's spread at Light Layer Strength 1), comp lights under the Comp Camera and under the rig, the light-moved re-render, and a flickering bolt over a render with the Draft switch.

## 2026-10-02 — RELIEF THAT KEEPS THE FEATURES: A SHORT EDGE FADE, AND RELIEF DETAIL. Build 28, still minor 15. Build 27's edge fade threw away most of a depth map, and with it the nose of a three-quarter face. It now keeps 91% of the map where build 27 kept 38%. Relief Detail (new, default 0.5) takes the depth map's large form away so the features spend Relief Depth. With the user's depth map, the forms are now in the cloud: the eye socket, the nose ridge and the lip line. They read as a sculpted fragment, not yet as a face. INSTALLED (2026-10-02, 13:51), 28/28 tests, NOT YET SEEN IN THE HOST.

### What was reported

The user fed build 27 a photo and its AI depth map: a tight three-quarter crop of a face (one eye, nose, lips), 4030x6000. Their first result was a box with a hole, because the photo was the Shape Source with Shape From Luminance at 0.5: 74% of it, background included, is brighter than 0.5. With a Threshold effect on the photo, the result was a blob with holes. A thresholded photo is still light and dark patches, and its dark parts are cut out. Both were reproduced in the CLI (build/tmp/b27/u1-montage.png). The setup that should work uses the depth map for both sources. Asked about our own renders, the user said: **"I don't see the eye brows. Just something sculpted like a head. don't see nose or any face feature."**

### Why: build 27's fade

The lift faded in from the silhouette's edge over the relief's whole height. On the user's map that was 1.1 km, on a 2.2 km wide face. Measured on the built maps with an exact distance transform (build/tmp/b27/user/lift-compare.png), the fade kept 38% of the depth map. What was left was a ridge down the middle, from distance-to-edge and not from the picture, and that ridge was the "sculpted head". The nose of a three-quarter face sits on the outline, where the fade was zero. A fade of 150 m kept 91%.

The kernel now fades over `kReliefFadeOfRim` (0.25) times the rims' radius or the relief's height, whichever is less: 165 m on the user's face. The cost is that a depth map cut off by its frame or by a hard mask stands as a near-sheer wall at the cut. From below, its underside shows (u4-nob-d50-left). A feathered mask on the depth layer, used for both sources, tapers it, because the masked depth falls towards the mask's edge.

### Relief Detail

A three-quarter head's own turn spends most of the depth range, so the features are small bumps on a slope. `buildShapeMap` now subtracts Detail times the map blurred at `kReliefFormSigma` (12% of the longer side, after the fill so the rim does not sink), and stretches the rest to 0..1 again. 0 is build 27's map. Param 655, inserted after Relief Depth; `PareidoliaParams` 40 → 44.

### Tests

- **TestPareidolia, ReliefDetailKeepsTheFeatures:** a slope with a bump on it. As it is, the far end of the slope is nearest; at Detail 1, the bump is, by more than 0.3. The fit test checks the fade, and the older tests pin Detail 0, the behaviour they were written for.
- **slang.convection (d):** two probes near the edge were added, one on the rounded rim (D 200 m) and one inside the fade (D 40 m). They give front 615.0 / 190.0 m against 616.1 / 191.1 expected, and back 346.2 / 173.8 against the profile's 346.4 / 174.4.
- **Bound sweep:** still 0 violations.
- **ctest:** 28/28 on the dev build.

### What the user's map gives now, honestly

These renders are in build/tmp/b27/u3, u4 and u5 montages. They use the user's settings (Hero Width 6000, Inversion 4160, Density 0.1, Billow Scale 300) with the hero alone and the camera at 4.2 km.

- **Billows off:** the eye socket, the nose ridge and the line of the lips are there, like a plaster cast of a face fragment.
- **Shape Billows 0.1:** they are scrambled. The lobes are the size of the features.
- **Shape Billows 0.03:** they survive as soft wrinkles.
- **Overall:** none of these reads as a face the way the frontal test card did (brow, two eye sockets, nose, from above). The crop has no head outline and only one eye. The outline is the strongest cue, and build 21's silhouettes (a face, a word, a dog) read from it alone.

**Guidance given to the user:**
- Use a whole head, ideally in profile, inside the frame against a plain background, and its depth map, for both sources.
- Draw a feathered mask on the depth layer and set the Shape Source dropdown to Effects & Masks; Source ignores masks and effects.
- Shape Billows 0 to 0.05.
- Light from above and in front.

### Known limits

- **Shape Billows is still the legibility knob.** Features smaller than the shape's billow lobes do not survive them. `kShapeLobeFloor` keeps the lobes at 0.3 of the hero's even at low Shape Billows, so the amount goes down but the size does not.
- **Viewing angle:** the plane stands vertical. A camera on the ground looking up sees the relief from below, foreshortened. Tilting the plane towards the lens is still open (see build 21).

## 2026-10-02 — PAREIDOLIA RELIEF: A DEPTH MAP CARVES THE SHAPE'S FACE TOWARDS THE EYE. Build 27, still minor 15. A second layer, Relief Source, pushes the camera-facing side of the shape forward: brighter is nearer. A figure can now read from forms inside its outline that the sun models, not from the outline alone. On a face test card lit from above, the brow, the eye sockets and the nose read in the cloud; with the silhouette alone the same card is an oval of lobes. The clouds stay water: relief changes where the cloud is, never what it is made of. With no Relief Source a frame is byte-identical to build 26. Relief costs 0.6% on the default hero and 5% on a large dense face. INSTALLED (2026-10-02, 10:46), 28/28 tests, NOT YET SEEN IN THE HOST.

### What was asked

The user showed a sunset photo of a huge cloud mass whose figure reads from its inner forms: a brow, bulges catching the low sun, and a dark hollow in the middle. They said build 21's pareidolia could not do it, and doubted that "luminance as a depth map" would. They were right about the mechanism. The silhouette is cut at Threshold, and everything inside it becomes one cushion of even thickness, so only the outline carries the figure. An Absorption control (soot, for the photo's brown smoke-like shadows) was offered and declined: **"it's fine to build the relief if we keep our clouds as water (Very important)"**. Nothing in this build touches the medium.

### What was built

- **Params.h**: Relief Source (LAYER, 651), Relief From (Luminance | Inverted Luminance, 652), Relief Depth (653, default 0.25) and Relief Softness (654, default 0.35). They were inserted in the Pareidolia group before its spares. `PareidoliaParams` gained `reliefChannel`, `reliefDepth` and `reliefSoftness`, all hashed (sizes 28 → 40, 176 → 188, 384 → 396).
- **Pareidolia.cpp, `buildShapeMap(..., const ReliefSource*)`**:
  - The depth map is read at the silhouette's texels, matched to the matte by fraction of the frame, so a depth pass at another resolution lines up. It is read as Rec. 709 luma of the straight colour, so a half-transparent edge reads as its depth.
  - Its range inside the silhouette is stretched to 0..1, because depth tools put a subject anywhere in their range.
  - The outside is filled outward from the inside (each ring takes the mean of its filled neighbours), then blurred by a Gaussian of up to `kReliefBlurMax` = 16 texels at Softness 1. Without the fill, the blur would sink the rim towards the background, and the slope at the edge would be a cliff that loosened the bound everywhere.
  - The result goes in the map's fourth float, which was unused. The steepest step between neighbouring texels is stored as `reliefSlope`.
  - The hash takes the relief only when there is one, so a map without relief hashes as build 21's. One flat grey is no relief.
- **`resolveShape`**: the relief height is Relief Depth × the shape's smaller side. The slope is height × √2 × step ÷ texel × 1.001: bilinear interpolation can step along both axes at once, and the 0.1% covers rounding. `extent` now reaches past the lifted face.
- **ConvectionLib.slang**:
  - `cvReliefHeight` and `cvReliefSlope`. The shape texel is read as a `float4`, and `convShapeDistance` returns the relief beside the distance.
  - `convReliefLift`: height × relief × smoothstep(0, height, D). The lift fades in from the silhouette's edge over the relief's own height, so the rim stays round and the relief rises off it at no more than about 56°.
  - In `convShapeSurface`, in front of the plane only, the distance from the plane counts from the lifted face: m = max(n − lift, 0). The whole rounded profile moves out towards the eye, and the slab behind the lifted face is solid. It is continuous at the plane, and the back is the old cushion. This is not build 21's rejected thickness height field: the profile's distance stays exact at the rim, where the lift is zero. On a steep relief the distance overstates the true one by up to √(1 + slope²), which only makes the billows there a little shallower.
  - `convShapeBound`: a box wholly in front is nearer the face by at most min(height, height × relief(centre) + slope × half diagonal). This is the same argument as the distance's own Lipschitz bound, and the fade only lowers the lift. `convShapeReach` and SlangBridge.h's hero box add the height.
- **Mistytune.cpp**: the two-step whole-layer checkout became `checkoutWholeLayer()`, used for both layers. The relief layer is checked out (7003/7004) only when a shape was, read in the same breath as the shape's source, and checked back in on every path. The log says `pareidolia: ... map in N s, with relief`, `relief flat -- none`, or why the depth map was unreadable.
- **CLI**: `--relief <file|dome>`, `--relief-from luma|inv-luma`, `--relief-depth`, `--relief-softness` and `--relief-dump`. The shape line prints the relief's height and slope.
- **Version**: build 27, MINOR STILL 15. AE's packed version gives the minor four bits. `PF_VERSION` masked minor 16 to 0, and the only symptom was EffectCommon.h's mismatch assert. CMakeLists.txt now refuses a minor past 15 or a build past 511 at configure time, in plain words. The build number is what tells AE its registration is stale, so it carries parameter changes from here.

### Tests

- **TestPareidolia, 7 new tests**:
  - No relief, an invalid view and one flat grey all give build 21's texels and hash.
  - A 0.3..0.7 ramp is stretched to 0..1 the right way round, and the inverse under Inverted.
  - A half-transparent depth pass reads its depth.
  - A pass at half the resolution builds the same relief to 0.03.
  - `reliefSlope` is the steepest step, and Softness 1 brings a hard step under 1/(16 × 2.5) a texel.
  - The rim keeps the subject's depth after the blur.
  - The fit, the slope, the extent and NaN or out-of-range Relief Depth are covered.
- **TestFingerprint**: the three new members.
- **slang.convection**:
  - The bound sweep gained three relief cases: a gentle ripple with the field (200 m), alone at 37° with decay 0.4 (500 m), and a sharp ripple (steps of 0.25 a texel) alone at full billows (900 m). All had 0 violations and a worst ratio of 1.0000.
  - Section 8 gained (d): with no billows, through three points deep in the face, the cloud reaches R + height × relief in front (550.0 / 528.8 / 570.0 m against 550.2 / 529.7 / 570.5) and R behind (398.8 against 400, the 1.25 m probe step).
  - It also gained (e): relief height 0 over a map whose fourth float is a ripple gives the same densities and bounds, bit for bit, as the map without one (0 of 102,000 differ).
- **ctest**: 28/28 on the dev build and on the installed main build (267 unit tests).

### Measured

- **Unchanged without relief:** 320x180 at 16 spp against build 26's installed CLI, byte-identical with the smiley, with the face silhouette and with no shape.
- **CPU against GPU with relief** (face card, facing 57°, 128x72 at 4 spp): max channel difference 0.
- **Cost**, 1280x720 at 32 spp, three interleaved pairs: the default backlit hero with the face card took 54.4 s against 54.8 s with relief (+0.6%, noise). The large dense face (Inversion 7000, Hero Width 6000, Density 0.1) took 17.9 s against 18.9 s (+5.4%: the relief adds cloud).
- **Map build**: a 512x640 matte with a depth map takes 21 ms, against 9 ms without.

### What it takes to read: scale and density, and that is physics

The first look renders at the defaults showed nothing inside the face. There was no bug: the side views showed the profile, brow, nose and chin standing proud exactly as built. The reason is that at Density 0.03 /m the mean free path is about 33 m, and with the droplets' forward-peaked phase function (g ≈ 0.85) light diffuses about 220 m before it forgets its direction. Any form smaller than a few hundred metres is lit as if it were not there. The test face was 1.2 km wide, so its nose and eye sockets were under that scale.

At Hero Width 6000, Inversion 7000 and Density 0.1, the forms read. Light from above (sun at 50°) puts the brow's shadow into the eye sockets. Pure side light reads the big forms (the dome's ridge, the nose) but not the sockets. Shape Billows 0.1 reads better than 0.2 at this scale, because the hero's billows grow with it. The look renders are in build/tmp/b27/ (`relief-before-after.png`, `p1..p6-montage.png`), with the scripts that make them and the face cards (`make_face*.py`).

So the guidance for a figure like the reference: a big hero (several km), Density near 0.1, Relief Depth 0.4 to 0.6, a sun that rakes across the forms, and Shape Billows down to about 0.1. That is the photo's own situation: a mass many kilometres across.

### Known limits

- One-sided: a carving seen from the front. Turn to Camera keeps it there. Orbited far round under Fixed Bearing, it is a relief seen from the side.
- No overhangs beyond what the billows give: the depth is a height over the plane.
- Animated depth maps are normalized per frame, so a depth map whose range changes over time will pump. Per-frame AI depth usually is normalized anyway.
- Depth and silhouette are matched by fraction of their frames, so a depth layer of a different aspect is stretched to fit.
- Not verified in the host: the second layer checkout, and an animated relief source.

## 2026-10-02 — RENDER QUALITY: THE EFFECT'S OWN DRAFT/BEST SWITCH, AND A DRAFT THAT IS AS BRIGHT AS BEST. Build 26, minor 15. Draft traces one path per 2x2 block at one sample, with build 25's shadow hand-off and a full denoise, and leaves Max Bounces alone. Against Best at the same size, at 1 spp on the RTX 2070 SUPER: 3.4 to 3.9x less trace time at 480x270, 4.2 to 6.3x at 1920x1080. Its cloud is within 2 levels of a 64-spp reference. Through build 25, Draft capped Max Bounces at 16, and that left a close hero 27 levels dark. INSTALLED (2026-10-02, 09:12), 28/28 tests, NOT YET SEEN IN THE HOST.

### What was reported, and what the log says

Reported from the host, after build 25's advice to preview with the layer's Draft switch: "Just
setting Draft in AE does not help in any way. Ideally the plugin should have its own draft/best
option."

- **The layer switch never reached the effect.** `%TEMP%\mistytune.log` holds builds 15 to 24,
  close to 7,000 traced frames. It never recorded "layer quality Draft", the line pre-render wrote
  whenever `in_data->quality == PF_Quality_LO`. Whether the user never set it or AE never passed
  it, it did nothing either way. Build 26 logs `layer=LO|HI` on every frame, so the next session
  that touches the switch will say which.
- **Even working, it would have bought little.** The last session in the log ran at quarter
  resolution with Samples already 1. That leaves Draft only the 16-bounce cap and, since build 25,
  the hand-off.

### What Draft could be made of, measured

CLI, scenes as in build 25 (A the default backlit hero, close a side-lit close-up, B a cumulus
field). The CLI's fixed cost is 0.27 s: a 16x9 render takes that, `--help` takes 4 ms, and
switching off the shadow maps saves 10 ms of it. So the 0.27 s is CUDA start-up, which AE pays
once per session. Times below are net of it, with interleaved medians of three.

**Bounces are expensive, but cutting them darkens the hero.** At 32 spp, 640x360, no denoise,
display levels against 32 bounces:

| bounces | 16 | 8 | 4 | 2 |
| --- | --- | --- | --- | --- |
| A, mean | -6.4 | -15.7 | -27.3 | -39.7 |
| close, mean | -21.6 | -47.2 | -73.4 | -94.0 |
| B, mean | -0.6 | -2.4 | -5.8 | -9.6 |
| close, time (32: 39.6 s) | 27.4 s | 16.4 s | 8.5 s | 4.3 s |

Build 16's "1% darker" for the 16 cap was measured on a cumulus field, which matches B. The hero
is far thicker, so much of its light arrives after the 16th bounce.

**Billow octaves cost almost nothing.** `--billow-octaves` (new, CLI only) at 3, 2 and 1: 0.2% and
2 to 3% less time. The billow is only evaluated in the surface shell.

**Half resolution is the big constant factor.** At 240x136 instead of 480x270, trace time falls
2.3x for Best and 2.7x for build 25's Draft.

**A roulette in place of the cap was tried and lost.** The idea: from the fourth bounce, a path
survives each scattering with probability at most p, and the survivors carry 1/p more. That is
unbiased in linear light, whereas the cap is not. The existing roulette takes p from the
throughput, and in a cloud of albedo near one that is always 1, so it never ends a path. The
denoised preview test below found it dark anyway: OIDN treats the rare, heavily weighted survivors
as outliers. Removed. The kernel keeps a comment saying why.

### The preview, denoised: what the user would actually see

480x270, 1 spp, denoised, four seeds averaged, against a 64-spp denoised render at the same size.
"Cloud" is the reference's brightest 40% of pixels. Levels, then RMSE per frame:

| | A cloud | close cloud | B cloud | RMSE A / close / B |
| --- | --- | --- | --- | --- |
| Best (Denoise Amount 0.8) | -3.7 | -7.8 | -1.7 | 14.5 / 17.3 / 10.6 |
| Best, bounces capped at 16 (build 25's Draft) | -6.9 | -30.3 | -2.2 | 20.8 / 37.1 / 11.5 |
| Best, roulette 0.85 | -5.9 | -16.2 | -2.2 | 18.2 / 25.2 / 11.7 |
| Half res + hand-off, amount 0.8 | -2.9 | -5.6 | -0.6 | 18.0 / 18.1 / 14.1 |
| **Draft: half res + hand-off, amount 1** | **-1.8** | **-2.0** | **0.0** | **15.6 / 12.3 / 13.6** |
| Best, amount 1 | -1.5 | -1.9 | -0.7 | 11.0 / 9.9 / 9.0 |

At amount 0.8, half resolution was the right brightness but covered a close hero in white 2x2
speckles. Amount 0.8 blends a fifth of the raw frame back in, and at half resolution each raw
firefly is a block. A full denoise removes them (montages in `build/tmp/b26/preview*.png`). So
Draft always denoises in full, whatever Denoise and Denoise Amount say.

### Draft against Best, trace time

1 spp, no denoise (a Draft denoise runs on a quarter of the pixels, so it is cheaper still):

| | A | close | B |
| --- | --- | --- | --- |
| 1920x1080 | 5.69 -> 1.04 s (5.5x) | 9.66 -> 1.54 s (6.3x) | 1.29 -> 0.31 s (4.2x) |
| 960x540 | 1.48 -> 0.31 s (4.8x) | 2.46 -> 0.45 s (5.5x) | 0.42 -> 0.12 s (3.4x) |
| 480x270 | 0.49 -> 0.14 s (3.5x) | 0.73 -> 0.19 s (3.9x) | 0.19 -> 0.055 s (3.4x) |

For comparison, build 25's Draft at 480x270 was 0.24 / 0.32 / 0.085 s. At Full 1080p, Draft is
still about a second, so it is not real time there. At quarter resolution it is a tenth to a fifth
of a second.

### What was built

- **Render Quality**, a Draft | Best popup directly under the classifier readout and outside every
  group, because a look session touches it most. ID 308, default Best, so a render queue gets what
  the sliders say unless asked. It was inserted, hence the minor bump. `draftRequested()` in
  Params.h treats anything an expression delivers other than Draft as Best. The layer switch no
  longer does anything.
- **`QualityParams::pixelStride`** (in `samplingHash`). `primaryRayDirection` takes a stride: buffer
  pixel (px, py) is the stride x stride block at origin + stride * (px, py), traced from the
  block's centre with the jitter spread over the block. The frame is not halved, so framing and
  field of view are exact at odd sizes; halving `widthPx` would round. The seed is the block's
  first frame pixel. The CUDA band offset moves `rowBegin * stride`. STRIDE ONE TAKES THE OLD
  EXPRESSION, ROUNDING INCLUDED: 32-spp renders of A and close came out byte-identical to
  build 25's, from both the dev build and the installed one, and the goldens pass unchanged.
- **`src/engine/Upscale.h`**: `strideExtent` and `upscaleFromStride`, bilinear between block
  centres, clamped at the edges, honouring both pitches. It works in linear light, after the
  denoise and before the output transform. `smartRenderHost` traces into a buffer the stride's
  size, runs the bands, chunks and denoise on it, scales it up into AE's world or the staging
  buffer, and transforms there. `smartRenderGpu` keeps every pixel, because nothing scales a
  smaller buffer into AE's device memory. Measured in AE 2026, that command is never called.
- **`draftQuality`**: one sample (never raised), hand-off 2, stride 2, denoise on at amount 1. Max
  Bounces untouched.
- **CLI**: `--pixel-stride`, `--billow-octaves`, and `--draft` meaning the above.
- **Tests**: `TestUpscale.cpp` (new, five: extents, stride one copies, a flat field stays exactly
  flat, a ramp lands on the block centres, padded rows honoured and untouched). `TestCamera.cpp`
  gains two: a strided pixel looks through its block centre, odd frame, origin and band offset
  included; stride one equals the unstrided ray bit for bit. `TestFieldCache.cpp`: Draft's recipe,
  including a full denoise with the switch off, and the stride in the sampling hash.

### Known limits

- Draft is softer than Best: half resolution, fully denoised. That is the trade, and it is the
  only one. Brightness, shadows (to a texel) and bounces are Best's.
- The 2x2 blocks align to the buffer AE hands over, not to the frame. Two different request rects
  of one frame put them differently. This affects Draft only.
- Not real time at Full 1080p (A about 1 s). The remaining large costs are build 25's: the camera
  ray's sun walk through clear air, and multiple scattering inside the hero.

---

## 2026-10-02 — FASTER: THE CAMERA RAY WALKED ONCE, THE GPU ONE BOUNCE PER LAUNCH, AND DRAFT'S SHADOWS FROM THE MAP. Build 25, minor 14. Against build 24 at 1 spp on the RTX 2070 SUPER: Best takes 26 to 34% less time at 1080p, with the same picture up to its noise; the layer's Draft switch is 2.5 to 3x faster at 1080p and about 2x at Third. INSTALLED (2026-10-02, 00:48), NOT YET SEEN IN THE HOST.

### Where a frame's time went

Asked for from the host: "work on optimising to make preview faster and reduce render time to
feel real time". Measured before anything was changed, CLI, Best quality, 1 spp, no denoise:

| | 1920x1080 | 640x360 |
| --- | --- | --- |
| A, the default backlit hero | 8.1 s | 1.1 s |
| B, a cumulus field, no hero | 2.3 s | 0.5 s |

A PROBE (throwaway, `build/tmp/b25/probe*.py`): a negative `--nee-scale` made the kernel return its
tracking steps per pixel as colour. Steps per pixel-sample at 640x360:

| | total | camera ray: sun walk + first flight | later free flights | shadow rays | scatter events |
| --- | --- | --- | --- | --- | --- |
| A | 278 | 85 + 58 | 27 | 107 | 4.8 |
| wide | 237 | 87 + 61 | 17 | 72 | 2.4 |
| close | 374 | 42 + 11 | 40 | 280 | 12.3 |
| B | 158 | 73 + 60 | 8 | 16 | 1.0 |

- **A step is not a step.** `--bounces` from 1 to 32 against the probe's counts: a step along the
  camera ray costs about 8 ns of frame time, a step in a later bounce about 26 ns. The camera rays
  of a warp walk side by side; by the third bounce its 32 paths are scattered through the cloud
  and a third of them have ended. Lanes doing useful work, from the probe image in 16x2 warps:
  41% in A, 53% in B. The kernel used 250 registers a thread, so an SM held a quarter of the
  threads it can.
- **Shadow rays were the largest category**, about 22 steps each, most of them null collisions in
  the clear air between the cloud a point is in and the slab's top. Reading the shadow map for
  the whole ray instead (a throwaway, wrong in the near field) took A from 8.1 to 4.4 s: the
  most any shadow change could buy.

Measured and rejected:

- **The scene in device memory, built once per launch**, instead of per ray on each thread's
  stack (3.5 KB of stack frame): 10% SLOWER in global memory and no faster in constant memory.
  The stack was not the bottleneck. Reverted.
- **Empty-space skipping.** The cumulus layer's procedural majorant grid ADDS steps in every scene
  (A 278 to 292, B 158 to 181): a box's bound must allow every billow that could reach into it,
  hundreds of metres from any tower, so almost no box is provably empty. A stored grid of the same
  bounds would skip nothing either.
- **Block shapes** were timed while After Effects was rendering on the same GPU and told nothing.

### The camera ray, walked once

`cameraSegmentSun` walks the whole camera ray to estimate the sun along it, and then `trace()`
walked the same stretch again, by delta tracking, to find the first collision. The walk's own
tentative points are a Poisson process at a rate at or above the density, which is all delta
tracking needs: each is now accepted as real with probability sigma / rate on a fourth draw per
step, and the first accepted point is the path's first collision, in either layer. When the
walk's roulette ends it first -- optical depth past 4.6 with nothing accepted, one ray in a
hundred -- `trace()` tracks on from where it stopped.

- **Steps**: A 278 to 218, wide 237 to 175, close 374 to 361, B 158 to 98.
- **Time**: only 5 to 15% at 1080p. The steps it removed were the cheap, coherent ones.
- **The same picture up to its noise.** Build 24 and build 25 at 64 spp, 160x90, against build
  24 at 256: every mean difference within one standard error (A, close, B, and the three golden
  scenes), and the spread between them no larger than noise predicts (ratio 0.70 to 0.95).
- **slang.bounce** passes unchanged: the closed forms, the majorant sweep, the thin-slab variance
  gain (7.28x), the furnace at scale 4 (0.999996), and the full path against delta tracking (0.29
  standard errors apart).
- **The goldens were re-blessed**, from the CPU path: the noise moved (mean 1 level, max 124 on
  single pixels at 24 spp). The old references are in `build/tmp/b25/golden-old/`.

### The GPU, one bounce per launch

`trace()` is now `pathBegin` -- the camera ray and the whole first bounce -- and `pathBounce` in a
loop (`BounceLib.slang`, `PathState`). The CPU reference and every test suite run that loop. The
GPU runs it in stages (`renderStaged` in `Mistytune.cu`): one launch begins every sample of the
request, then one launch per bounce runs only the paths still alive, gathered into a list by the
launch before, and a last launch sums each pixel's samples in sample order and writes them as
`renderPixel` does. Each launch does one kind of work, and the bounce kernel uses 164 registers.

- **The same bits.** Byte-identical to the single kernel (`--megakernel`, kept for A/B) at 1 and 4
  spp and in Draft, and the restructured `trace()` byte-identical to the one before it at 128 spp.
  New test: **determinism.gpuStaged**, a hero in a cumulus field with bands and sample chunks.
- **Time, against the single kernel in the same binary**, 1080p 1 spp: A 0.75x, B 0.73x, close
  0.75x, wide 0.76x, o90 0.68x.
- **Memory**: 151 MB of path state per rendering thread for 1080p at one sample, the GPU band
  budget. A frame that cannot get it -- several in flight on a full card -- runs the single
  kernel instead, with the same result.
- **The Windows display timeout** sees one bounce per launch rather than a whole band.

### Draft: the shadow ray hands off to the map

The layer's Draft switch now also sets `QualityParams::shadowHandoff` to 2 (texels of the shadow
map; 0, Best's, is the exact ray). It is a sampling input and in `samplingHash`. A shadow ray walks
exactly, by ratio tracking, until it has crossed two texels of clear air since the last cloud it
met; then it walks on, still exactly, to the next slice plane above, and takes the rest of its way
to the sun from the cumulus layer's shadow map, read on that plane. Below the cirrus slab, the
cirrus's share is one read of its map. See `transmittanceHandoff` in `AirMapLib.slang`.

- **Why the plane.** The first version read the map where the gap ran out, between two slices, and
  the slice below holds the column's transmittance through the cloud the ray had just left:
  sunlit faces came out up to 20 levels darker (9-pixel blur of a 128 spp render) and the backlit
  rim brighter. Read on the plane, the mean difference against the exact ray is +0.04 to +0.20
  levels in four views, and the blurred 1st and 99th percentiles (about ±5 to 9) are what the
  noise of two 128 spp renders gives. Left: a faint brightening on A's backlit right rim and a
  slightly warmer patch on o90's overhead base, up to about 20 levels in the blur. Side by side
  the frames cannot be told apart.
- **Cost**: the cumulus map keeps its 16 slices. More would shorten the walk to the plane, but the
  same map draws the air's and the ground's shadows in Best, which would then change.
- **Time**, 640x360, 128 spp, against build 25's exact ray in the single kernel: A 125 to 50 s,
  close 203 to 90 s, wide 106 to 31 s, o90 143 to 42 s (staged kernel and hand-off together).

### Against build 24, end to end

CLI, 1 spp, interleaved runs, best of three. Chrome was drawing on the GPU, so the absolute times
drift between sets; the ratios held.

| | Best, 1080p | Draft, 1080p | Draft, 640x360 |
| --- | --- | --- | --- |
| A | 0.72x | 0.39x (9.4 to 3.7 s) | 0.53x (1.27 to 0.67 s) |
| close | 0.74x | 0.33x (15.2 to 5.0 s) | 0.43x |
| o90 | 0.66x | 0.33x (9.3 to 3.1 s) | 0.48x |
| B | 0.66x | | |

The 640x360 times include about 0.3 s of process start and CUDA initialisation that the effect
does not pay per frame.

### What it did not do

Real time at 1080p is not here: a Draft frame of the default hero is still over three seconds at
full resolution on this card. What is left is the work itself -- a dense cloud scatters a path a
dozen times, and each event needs a shadow ray -- and the 1080p Best frame is about 4 µs per
pixel-sample. The next levers, in the order the measurements rank them: the camera ray's sun walk
through clear air (85 steps in A, coherent but long), a finer shadow map round the hero so the
hand-off could start sooner, and the density function's own cost inside the hero group.

### Tests

All 28 ctest suites pass (27 and determinism.gpuStaged). The goldens moved once, for the single
walk, and were re-blessed from the CPU.

### What needs the host

- **Preview with the layer's Draft switch** (the layer's Quality switch): 1 spp, 16 bounces, and
  the shadow hand-off. Best is unchanged apart from its noise.
- Does Draft at Half or Third feel interactive now, and does its look match Best's closely enough
  to judge a frame by?
- Builds 22 to 24's items still apply.

---

## 2026-10-01 — PILEUS AND VELUM, AND THE CLOUDS FINALLY MOVE IN PLAYBACK. Build 24, minor 14. The hero gets a smooth cap over its crown and a wide thin veil it rises through, both thinner than the tower. At 0 the frame is byte-identical to build 21. And the effect now tells AE its picture changes with time: since Phase 1, AE played back one frame of an effect with nothing keyframed. BUILT AND TESTED, NOT INSTALLED: After Effects was open.

**Installed afterwards, and REPORTED from the host on 2026-10-01:** "the playback was not the issue". The cumulus looked still because the default orbit rig follows the drifting hero, so the frame moves with the wind; with the hero not followed, the drift shows. The flag stays, because the SDK says an effect whose picture changes with time must set it, and this build cannot show whether it was also needed. Offered and declined ("I think it's fine"): a camera that stays put while the hero drifts, and a Time Scale.

### Why nothing drifted (found from a user report)

The user asked why the cumulus did not move with the wind while the ice did when its wind changed.
Three things, one a bug:

- **`PF_OutFlag_NON_PARAM_VARY` was never set.** The SDK: "If the effect produces changing
  frames when applied to a still image and all parameters are constant, that's a sure sign
  that this bit should be set." Mistytune sits on a solid, so with nothing keyframed AE
  rendered one frame and reused it. Set in `EffectCommon.h` and `cmake/EffectFlags.cmake`.
  NOT YET SEEN IN THE HOST.
- **The default camera rides with the hero.** Orbit the Hero follows the hero's drifted
  position, and the field drifts at the same velocity, so the frame does not change. Comp
  Camera, or Hero Drifts With Wind off, shows the drift.
- **Real time is slow.** 6 m/s is 60 m in ten seconds against a 3 km hero 4 km away, and a
  cell lives 1200 s. Moving clouds on video are timelapses. Offered, not built: a Time Scale
  control, so a timelapse needs no precomp and time remap.

The ice looked different because its wind is the shear profile: changing it reshapes the fall
streaks at any time, and no camera follows the ice.

### How the cap and veil work

A **Pileus and Velum** topic after Mamma: **Pileus** (0..1), **Pileus Gap** (m, default 150),
**Velum** (0..1), **Velum Height** (0..1 of the hero, default 0.6), plus two spare rows. Both
are the hero's, so Hero Cloud Off hides them (`ConvectionLib.slang`, `convCapDensity`).

- **Pileus** is a lens 0.6 hero radii across, up to 260 m thick, at 0.45 of the layer's
  extinction. Its middle follows the hero's dome at 0.6x the radius, so it drapes. **The gap is
  from the crown's highest billows**: measured from the smooth crown, the cap sat inside the
  cauliflower and only its rim showed. A negative gap lets the turrets push into it.
- **Velum** is a veil up to 200 m thick at 0.22 of the extinction. It is humped up near the
  tower and reaches past the wall by between 75% and all of 0.9 radii, by bearing. **Seen at 3
  radii**, the default camera stood under it, an overcast sheet blazing in the backlight. **At
  2.2** its near edge crossed the frame as a ruled diagonal.
- Both thicknesses wander by up to 40% on a kilometre-scale noise. They carry no billows.
- **The bound** takes each factor where the box can reach it (`convCapBound`). The slab top
  and the Alone box grow to cover them.
- **The classifier** writes them after mamma: "... pileus velum", or "pil vel" when long.

### Measured

- **Pileus and Velum 0 against build 21:** scene A, **byte-identical**.
- **Frame times**, CLI, 640x360, 32 spp, denoised, Hero Connection 0.6, Pileus 0.8, Velum 0.6,
  one run each: A 67.9 s, wide 37.2 s, close 105.3 s. Not compared against the same frames
  without them, so the features' own cost is NOT MEASURED.
- **Looked at**: `build/tmp/b22/caps3.png`, against the previous version in each row. In
  `wide` the cap reads as a smooth lens over the crown, and the veil as a shelf off the
  tower's side with a wandering edge. In the backlit default `A`, a bright diagonal at the
  top left is in both versions; whether it is the veil or the ice layer was not checked.

### Tests

- **slang.convection**: two new bound-sweep cases, the cap and veil with the field and
  alone with a 60 m gap, **0 violations**. The sweep's probe height now includes the cap's and
  the veil's tops; before, it stopped short of the cap. New section 11: the crown is
  unchanged, the gap is clear, and the cap and veil are there at 0.45 and 0.22 of the tower's
  density. There is nothing above the cap, and nothing above or beyond the veil.
- **TestClassifier**, **TestConvection**, **TestFingerprint**: the new features and fields.
- **All 27 ctest suites pass. The goldens did not move.**

### What needs the host

- **Close AE and run `.\build.ps1 -Install`.** Then apply the effect fresh, since a topic was
  inserted after Mamma.
- **Playback with nothing keyframed**: the field should drift and the cells evolve. With Comp
  Camera, the hero should move across the frame.
- **Pileus** 0 to 1 at the default orbit, and **Pileus Gap** from -300 to 600.
- **Velum** at the default backlit orbit: is its edge still visible as a line?
- Builds 22 and 23's items still apply.

---

## 2026-10-01 — MAMMA: POUCHES HANGING FROM THE UNDERSIDE. Build 23, minor 13. The first of the six supplementary features, and the one PLAN.md puts first. Smooth pouches on their own lattice hang wherever the cumulus layer has cloud overhead: under a deck, and under the hero and its group. They are creased between, and each sags and lifts over half a cell's life. At Mamma 0 the frame is byte-identical to build 21. On the way, the Slang rewrite step that failed the first build after nearly every kernel change was fixed. INSTALLED, NOT YET SEEN IN THE HOST.

### How it works

A new **Mamma** topic in the Cumulus layer, after Organization, has two controls: **Mamma**
(0..1, default 0) and **Pouch Size** (m, default 450), plus two spare rows.

**The sag** under a point is three things multiplied (`ConvectionLib.slang`, `convMammaSag`):

- **The pouch there.** A jittered lattice of hanging hemispheres in the drifting pattern's
  frame, radius 0.68 of the pitch, so they overlap and the underside is mostly lobes with
  sharp creases between them. They are smooth, with no cauliflower, which is what makes mamma
  read as mamma. Each one's depth runs through the cell life curve at twice the cells' rate,
  between a third and all of its size. So in a timelapse they sag and lift without ever quite
  leaving.
- **The envelope**, how far inside the cloud the base above is. This is the smooth surfaces'
  distance a metre over the condensation level: the field's with its moat, the hero's, the
  group's turrets. No pouch hangs where there is no cloud overhead, and they shallow to nothing
  over 0.6 of a pouch towards the edge of what there is.
- **The depth**, Mamma times 0.8 of Pouch Size (`mammaDepth()` in `ConvectionField.h`). Mamma
  photographed under anvils hang about as far as they are wide at most. Much past that a
  pouch reads as a stalactite.

Below the base a point is inside a pouch when it is less than the sag down, and the density
ramps up from the pouch's surface as it does from the base. **Above the base, the 40 m base
ramp starts at the pouch's bottom** rather than at the base. Otherwise every pouch would hang
from a band of thinning cloud.

**The slab** reaches down by the deepest pouch. **The bound** treats a box below the base as
one at it. Every inside below is at least the inside at height zero, and a pouch's own density
is at most the ramp from its deepest bottom.

**The classifier** writes the atlas's supplementary feature after any varieties: "Sc
stratiformis opacus mamma", or "Sc str op un mam" when it is long. The atlas lists mamma under
Sc and Cb, not Cu. On the hero it names what the user sees; the hero stands in for the
cumulonimbus this generator cannot make yet.

### Measured

**Mamma 0 against build 21:** scene A, **byte-identical**.

**Frame times**, CLI, 640x360, denoised, 64 spp, one run each. `wide` is a closed deck with
its base at 1.5 km, a 75 degree lens looking up 30 degrees, and the sun at 4 degrees across
the view. `herow` is the hero from 3 km under the same sun.

| | Mamma 0 | Mamma 1, 450 m pouches | Mamma 1, 20 m pouches |
| --- | --- | --- | --- |
| wide | 29.1 s | 49.3 s | 33.1 s |
| herow | 80.1 s | 104.5 s | |

- **The first version cost the deck view 85%.** Two cuts give the same pixels:
  - Below the base, a pouch that could not reach the point even under the deepest cloud
    skips the base's lattice. That measured within noise on its own.
  - In the band above the base, the base test now reuses the lattice the density has
    already run for the column, which depends on xz alone. With a second lattice, pouches
    only 16 m deep cost 22%; now they cost 14%.
- **What is left is the deeper medium.** Every ray now tracks through the band down to the
  deepest pouch, with the pouches' nine hashes at each step there, and the pouches' own
  scattering. That is the price of the feature, paid only when it is on.

**Looked at** (`build/tmp/b23/`):

- `mamma1.png`: framings too steep or too flat show almost nothing. Looking 55 degrees up at
  a base 680 m overhead, a 40 degree lens sees about one pouch.
- `mamma2.png`: a grazing sun from the side shows the underside as uniform murk.
- `mamma4.png`: wider and higher, the hero's underside hangs in clear pouches, and a deck's
  cells sag in lobes.

### Tests

- **TestConvection**, 2 new tests:
  - No mamma is a flat base, a NaN or a negative amount included.
  - The depth is 0.8 of the pouch's width at full amount, linear below that and clamped
    above it, the width floored at 20 m, and nothing on an absent layer.
- **TestClassifier**:
  - Mamma are named after the varieties.
  - They are named on the hero too, and not on a layer the air cannot make.
  - The 20000-sky length sweep now includes them.
- **TestFingerprint**: covers both new fields, through the size tripwire.
- **slang.convection**:
  - Three new bound-sweep cases with **0 violations**: a closed deck with mamma, the hero
    alone with them, and the group with them. Its boxes and seeds now reach the deepest pouch.
  - New section 10: above the base ramp, 0 of 100000 densities differ from no mamma.
  - Under a 90% deck, 14688 of 20000 columns have a pouch, and none under a column with no
    cloud in its first sixty metres.
  - The deepest pouch found is 346 m, against an allowed 360.
- **249 unit tests and 27 ctest suites pass. The goldens did not move.**

### The build fix

`cmake/SlangRewriteInclude.cmake` wrote each generated file with `file(WRITE)`. Two test
projects generate Transport.cu, and MSBuild builds them in parallel, so one could be compiling
the file while the other rewrote it. The write then failed with "Permission denied", leaving
the absolute-prelude file behind (a quirk on record since build 18). On 2026-10-01 that
happened on the first build after nearly every kernel change, five builds running. The script
now writes a staging file and copies it with `copy_if_different`, which never rewrites an
identical file. It touches the output so the rule does not rerun forever, and it retries for
up to ten seconds against a lock. Since then every build has passed first time, and a no-op
rebuild takes 3 s with nothing regenerated.

### Known limits

- **They need the right light and framing.** A wide lens, a base well overhead, and a low sun.
  At the default orbit's backlight they are a scalloped bottom edge.
- **Cumulus only.** The atlas's mamma are mostly under anvils and altostratus. There is no
  anvil until Phase 4's mixed phase, and the cirrus layer has no mamma.
- **The pouches do not know about the hero's turrets' shapes** beyond their footprints. A pouch
  under a turret hangs from the turret's base like any other.

### What needs the host

- **Apply the effect fresh.** A topic was inserted after Organization.
- **Mamma** keyframed 0 to 1 under the hero at a low sun with a wide focal length.
- **Pouch Size** from 150 to 1500.
- **A timelapse**, to see them sag and lift.
- **The cost** at the user's own framing.
- Build 22's items still apply.

---

## 2026-10-01 — HERO CONNECTION: THE HERO STOPS LOOKING SET DOWN ON THE FIELD. Build 22, minor 12. Turrets grow on its shoulders, and a flanking line of smaller towers steps down from it into the wind. The field's updraft sinks under the group, and the hero drifts with the wind. One slider, Hero Connection; at 0 the frame is byte-identical to build 21. It costs 23% on the default backlit frame and 45% on a close frame the group fills. INSTALLED, NOT YET SEEN IN THE HOST: the user is away from AE and asked for Phase 4 to go on meanwhile.

### What was wrong, looked at rather than guessed

Build 21 was reported good, and the next question was whether the hero could feel "connected
to other clouds so it does not feel disassociated". The renders in `build/tmp/b22/before.png`
and `before2.png` show why it did not. From above, the field's clouds have ragged footprints,
because each is a cell's rim or centre. The hero was a perfect disc. Nothing in the frame sat
between its 3 km and the field's few hundred metres. A field cell grew out through its wall.

### How it works

**Turrets.** A towering cumulus is a group of turrets, not one dome. Connection grows more
domes of the hero's own family: the closed-form tower with the hero's exponent and flat base.
They are laid out by `heroGroup()` in `src/engine/ConvectionField.cpp`, in hero radii:

- **Two shoulders** stand inside the hero's footprint, off-centre, and higher than its wall
  there. They turn the dome into a tower of turrets with a ragged footprint.
- **A flanking line of three** steps down into the wind, at 72%, 52% and 36% of the hero's
  height, each overlapping the last at its base. The last is about a field tower's height, so
  the line ends where the field begins. Wind From swings it round.

Each grows in over its own stretch of the slider, from 60% of its footprint and no height, to
full. The layout is fixed, not random: Variation picks the cauliflower, and a layout that
jumped with it would be a control that moved everything.

**The moat.** The field's updraft is multiplied by a factor round each tower, the hero
included: zero inside 0.75 of its radius, rising to one at 1.3. A field cell centred under the
group is gone. One at its edge shrinks to a small cloud against the wall, which is where the
field merges with the group. The factor is at most one, so the field's bound holds untouched.
Its slope goes into the kernel's slope clamp only inside a ring, so the rest of the sky's bound
is exactly what it was. The moat is full by Connection 0.5, ahead of the towers.

**One cauliflower for the group.** Every tower's smooth surface is taken. The billow is then
read once, at a read point, lift and lobe blended by a softmax over 50 m towards the nearest
surface. On a crease both read points are near the point, so the blend barely moves. The
result is continuous, with no seam, and a tower-level crease becomes one more crease in a
single cauliflower. The turrets read the hero's billow frame and seed, so Variation changes
them with the hero, and their lobes are sized between the field's and the hero's.

**Drift.** `heroPositionNow()` puts the hero at Hero Position plus the steering wind's drift
when Hero Drifts With Wind is on. The kernel, the orbit rig and the shape's facing all read
it, so a drifting hero stays framed and still faces the lens.

**With a pareidolia shape.** The shoulders shrink away while the shape holds and return as
Decay melts it. The flanking line turns into the picture's plane, on the side nearer the wind,
pushed out past the picture's edge. Left pointing into the wind, it would have stood between
the lens and the face from every orbit that puts the camera upwind. It swings back into the
wind as Decay runs. `build/tmp/b22/look2.png` shows the smiley framed by the line, and at
orbit 0 the moat clears a field cloud that used to grow into the face's right side.

### What changed from the agreed outline, and why

- **No smooth join.** A smooth union adds cloud wherever two surfaces are both near. The base
  plane counts as "near" for every tower's formula at every point just above it, so it would
  grow a pancake of cloud under the whole group. The overlapping footprints already merge the
  bases, and turrets meet in creases, as thermals do.
- **The feeders are towers of the hero's family, not a vigour boost on the field's cells.** A
  boosted lattice gives whichever cells happen to fall there, at whatever point in their life:
  sometimes a line, sometimes a gap or an open-cell wall. Towers placed by the host are always
  a line, and they step down because they are told to.
- **One control plus a checkbox.** Hero Connection, and Hero Drifts With Wind.

### Defaults

| Control | Default | Why |
| --- | --- | --- |
| Hero Connection | 0.6 | Two shoulders, two-thirds of the line and the full moat. It costs the same as 1 (32.3 s against 32.4 s on scene A), and the third tower of the line stays small. |
| Hero Drifts With Wind | on | The field sliding past a pinned hero was one of the three reasons it looked set down. |

The engine's defaults are 0 and off, so every golden image and test means what it meant.

### Measured

**Connection 0 against build 21:** scene A, byte for byte, **identical**. Checked three
times, after each kernel change.

**Frame times.** CLI, 640x360, 32 spp, denoised, minimum of 3. The GPU ran warm late in the
session: Connection 0 crept from 25.4 s to 26.3 s on the same binary.

| | Connection 0 | 0.6 | 1 |
| --- | --- | --- | --- |
| A, the default backlit orbit at 4 km | 26.29 s | 32.31 s | 32.43 s |
| Looking away from the hero | 14.05 s | | 15.04 s |
| Close, 2.5 km, the group filling the frame | 33.9 s | 49.2 s | 49.2 s |
| A at Connection 0.02, towers a few metres tall | 26.18 s | 29.10 s at 0.02 | |

**Where the cost is,** from a throwaway benchmark (`build/tmp/b22/bench/`) that times the
density over 4M points round the group:

| | ns per density | cloud |
| --- | --- | --- |
| Connection 0 | 0.99 | 6.2% |
| Moat only | 1.03 | 6.1% |
| Turrets only | 1.66 | 7.9% |
| Connection 1 | 1.95 | 7.6% |

- **The first version cost 2.46 ns**, and 20% of the frame even looking away from the group.
  The rings and reaches ran for every density in the sky. One circle round the group, tested
  once, skips both exactly outside it. The away view went from +20% to +3% and later +7%,
  since part of that view's near field lies inside the circle.
- **Each turret had its own billow.** With the turrets' billows removed for the experiment,
  the turrets cost 1.20 ns instead of 1.80, so the billows were two-thirds of their cost. The
  one-cauliflower blend above replaced them with one billow per point: 2.28 ns down to 1.91.
- **Returning the hero's own path where no turret is near made it 30% slower** (1.95 to 2.58
  ns). A warp whose points split between the two returns ran both billows. It was replaced by
  one call site fed the hero's own numbers, and the kernel says why.
- **Under the group's middle, the field's lattice is no longer run.** Where the moat's factor
  is exactly zero, the field provably adds nothing, so skipping it gives the identical result.
- **A dome's two pows are skipped** at points over a turret's top by more than any billow
  lifts. That measured within noise on scene A.
- **What is left is mostly cloud.** The close frame is the group's underside wall to wall,
  and every extra scattering event costs. The rest is the group's fixed overhead: 0.02 already
  costs 11%. 0 costs nothing.

**Looked at:** `build/tmp/b22/look1.png` (from above, the default orbit, the flank) and
`look2.png` (close, the smiley from upwind and from orbit 0), each at Connection 0, 0.6 and 1.
From the flank the line reads as distinct towers stepping down on one flat base. From above
the group is no longer a disc.

### Tests

- **TestConvection**, 8 new tests:
  - Connection 0, and a NaN, is the lone hero.
  - No hero means no group.
  - Every turret is under and inside the hero, at five connections and three widths.
  - The group grows with the slider, never shrinks, and the moat is full by halfway.
  - The flanking line steps down into the wind, at three winds, one keyframed round ten
    turns, and a wind from the east puts it east.
  - A picture takes the shoulders' place.
  - The flanking line frames the picture: along the plane, windward and past its edge, from
    five facings.
  - A drifting hero keeps its place in the field.
- **TestCamera**: the orbit follows a drifting hero.
- **TestFingerprint**: covers both new fields, through the struct-size tripwire.
- **slang.convection**:
  - Four new bound-sweep cases, with **0 violations**: the group with the field, the group
    alone, a half moat on organized cells with a hero smaller than a cell, and a shape with the
    flanking line.
  - New section 9: over a low hero's middle the moat clears 7021 of 7021 field-cloud points.
  - All five turrets are cloud on their own axes.
  - Away from the group, 0 of 100000 densities differ from the lone hero's.
  - That last check would have caught a group circle drawn too small.
- **246 unit tests and 27 ctest suites pass. The goldens did not move.**

### Known limits

- **The cost**, above. The fixed overhead is the price of the group's code running near the
  hero at all.
- **The layout is fixed.** Variation does not move it; Wind From swings it round. A flanking
  line seen end-on, with the camera directly upwind or downwind, reads as one wide mass.
- **The group ignores Organization.** A hero in cloud streets does not sit on a street.
- **Mid-size neighbours come only from the line.** The field's own clouds are no bigger near
  the hero than anywhere else.

### What needs the host

- **Apply the effect fresh.** Two rows were inserted after Hero Variation, so every control
  after them shifts in a project saved by an earlier build.
- **Hero Connection** from 0 to 1 at the default orbit: the flank on the left, the shoulders,
  and the field clearing round the hero. Then Wind From swung round to bring the line into a
  framing.
- **Hero Drifts With Wind**: scrub an animation. The hero and the field move together and the
  orbit rig follows. Unticked, the field slides past as before.
- **With a Shape Source**: the line beside the picture, never in front of it, from any orbit.
- **The cost** at the user's own framing.
- Builds 20 and 21's items still apply.

---

## 2026-09-30 — Build 21 reported good in the host. REPORTED, not measured, like builds 7 and 13.

The report was "It looks really good". No log and no frame times came back, so this entry
weighs less than the ones with numbers in them.

| | status |
| --- | --- |
| A picture from another layer reads as a cloud in AE | **Settled.** A person is the right judge of that |
| The two-step checkout of the source layer works in the host | Consistent with the report, since a shape appeared. Not logged |
| Editing or animating the source re-renders the cloud | Not reported either way |
| Decay's squared easing melts evenly | Not reported either way |
| Build 20's Organization group | Not reported separately. The report covers the build as seen |

---

## 2026-09-30 — PAREIDOLIA: ANOTHER LAYER'S ALPHA OR LUMINANCE BECOMES THE HERO. Build 21, minor 11. The first Phase 4 item. The effect takes a layer as its Shape Source, turns the chosen channel into a signed distance map on the host, and stands it up on the hero. It faces the camera, is inflated with rounded rims and wears scaled-down billows. Decay melts it back into the ordinary tower. A face, a word and a dog silhouette all read in the render. The shape costs nothing measurable, and a 1080p source becomes a map in 18 ms.

### Where build 20 stands

Build 20 is installed and has not been reported on. Build 21 carries it, so build 20's "What
needs the host" list below still applies.

### How it works

**The picture.** A new **Pareidolia** group at the end of the Cumulus layer has these controls:
Shape Source (a layer), Shape From (Alpha, Luminance, Inverted Alpha, Inverted Luminance),
Threshold, Decay, Depth, Shape Billows, Facing (Turn to Camera or Fixed Bearing) and Facing
Bearing. The layer arrives in its own space, with masks and effects applied and transforms not.
Pixels at or above Threshold are the silhouette, cropped to their bounding box. Pixels outside
the source's frame are off in every mode, so an inverted matte of a mark on white paper gives
the mark, not the mark plus an endless sheet of paper.

**The map** (`src/engine/Pareidolia.{h,cpp}`). The silhouette's longer side is always 224
texels, with 16 clear texels round it, so a proxy at Third builds the same shape, only coarser.
Each texel is inside when the matte averages to the threshold over it, using up to 4x4
bilinear samples. Two passes of an exact Euclidean distance transform (Felzenszwalb and
Huttenlocher) give the signed distance to the edge. Central differences give its slope, so the
interpolated gradient is continuous. Each texel is four floats: distance, two slopes, zero.
Row 0 is the bottom.

**The fit.** The silhouette keeps its aspect and fits inside Hero Width by the hero's height
(contain). Its bottom stands on the condensation level, so a face's chin is cut flat like any
cumulus base. Hero Width and Hero Height stay the controls for size.

**The shape in the kernel** (`ConvectionLib.slang`). A vertical plane through the hero's centre
carries the map. A point is cloud when (its depth D inside the silhouette, its distance m from
the plane) lies in a rounded-rim profile: a disc of radius R centred R inside the edge, and past
it the strip m < R. So a disc becomes a sphere, a stroke a tube, and a wide region a cushion 2R
deep. **The 3D distance is the 2D distance to that profile, in closed form**, inside and out.
Billows are read at the nearest surface point, as on the tower.

**The first design was rejected on paper.** It stored a thickness height field over the plane.
Near the rim that field's slope runs to infinity, and the height-field distance then reads a
point beside the rim as ten times nearer the surface than a point just past it. The billows
would have shown that as a seam round every silhouette.

**Facing.** Under Turn to Camera the plane turns to the eye's bearing before the fingerprint is
taken, as the sun placement does. A camera move that turns the shape is therefore a field
change, which the cache sees. Fixed Bearing uses the Orbit dial's convention, so 0 faces the
default camera. With a shape, the whole hero's billows are read in the plane's frame. Decay
blends the two surfaces' read points, and a blend across two frames would slide the
cauliflower round the axis.

**Decay** blends the shape's distance and read point with the tower's, and the billow amount
from the shape's to the hero's. **It is squared on the host.** With a linear blend, the
smiley's eyes and mouth were gone by 0.33. An eye is a hole about 130 m deep in a tower about
500 m deep, so a fifth of the tower fills it. Squared, the features are still there at 0.2,
faint at 0.4, and gone from 0.6. Decay 1 takes the tower's own path in the kernel, exactly.

### What the defaults are, and why

| Control | Default | Why |
| --- | --- | --- |
| Shape Billows | 0.2 | Swept at 0, 0.1, 0.2 and 0.35 (`build/tmp/b21/sweep1.png`). At the hero's own 0.35 the eyes closed over; at 0 it is a plastic balloon; at 0.2 the face reads and it is still cloud. |
| Depth | 0.6 | Rims of 0.3 x the smaller side: a 1.7 km face is about 1 km deep. Face-on, 1.0 narrowed the eyes and 0.35 read as well as 0.6. 0.35 was not looked at edge-on; 0.6 was kept as the deeper, more cloud-like of the two that read. |
| Threshold | 0.5 | The matte's middle. |
| Facing | Turn to Camera | The shape exists to be read from the lens. |

### Measured

**Timings.** CLI, 640x360, 32 spp, best of 3, the scenes build 20 used:

| | build 20 | build 21 |
| --- | --- | --- |
| A, default backlit hero | 24.95 s | 24.71 s |
| A with the smiley | | 23.36 s |
| A with "HI" from a 1080p luminance source | | 23.70 s |
| B, cumulus field | 9.57 s | 9.35 s |

The shape is a little cheaper than the tower because it holds less cloud. The hero code was
refactored into `convTowerSurface`, and with no shape the timings did not move.

**The map.** A 1920x1080 source becomes a 256x218 map in **18.3 ms** on the CPU. The effect
pays this on every frame of an animated source.

**CPU against GPU**, with a shape at facing 0 and at 57 degrees, 128x72 at 4 spp: **max
difference 0**, byte for byte.

**Looked at** (`build/tmp/b21/`): `sweep1.png` for billows and depth, `looks1.png` for the dog
from inverted luminance on white paper and "HI" from luminance text, `decay2.png` for the melt,
`orbit2.png` for edge-on at orbit 90 with Fixed, face-on with Turn to Camera, and the
three-quarter view at 45, and `backlit.png`. **Front and side light read best.** Backlit, the
default, the shape glows, because a 1 km cushion lets the forward-scattered sun through where
build 20's 3 km tower was dark. The face and the dog still read.

### Tests

- **TestPareidolia**, 11 new tests:
  - A disc's map is its distance within a texel everywhere.
  - Neighbouring texels differ by at most one, which the kernel's slope bound relies on.
  - Each channel reads the number it names.
  - A blank picture is no shape.
  - The box fills 224 texels at any source resolution.
  - An F stays the right way round, which is the only test that would catch a mirror.
  - The fit is contain.
  - The shape turns to the camera.
  - The bearing sets the axis, even when keyframed round ten turns.
  - NaNs come out as numbers.
  - The hash follows the picture, and with no picture the hero is what it was.
- **TestFingerprint**: every PareidoliaParams field moves the hash.
- **slang.convection**: four shape cases join the bound sweep (facing 0; 37 degrees with decay
  0.4; 200 degrees with full billows; decay 1). There were **0 violations** in 3000 boxes each.
  New section 8:
  - Decay 1 at facing 0 against no shape: 0 of 100000 densities differ.
  - With no billows, the plane's cross-section is the silhouette: 0 of about 53000 points
    disagree, at facings 0, 90 and 211.
  - The rim reaches 397.5 m against a profile of 400, and 345 against 346.4.
  - The first version of that last check expected R at the disc's centre and failed. The eye
    sits 23 texels from the centre, so D there is 234 m, and the kernel's 362.5 m was right: the
    profile gives 364. The check now takes its expectation from the same distance function.
- **237 unit tests and 27 ctest suites pass. The goldens did not move.**

### Host plumbing, and what changed about the effect

- **A LAYER kind in the parameter table.** Its setup is `PF_ADD_LAYER` with no default.
  Checkout and the params-array read skip it, because the pixels come from pre-render.
- **Two checkouts of the source at pre-render.** A probe with AE's own request reads back
  `max_result_rect`, the layer's whole extent. A second checkout asks for exactly that, capped
  at 8192 px a side. Only the second's pixels are read. **The source is not unioned into the
  result rect**, because it shapes the cloud, not where our pixels lie.
- **The map's hash is folded into the render key** at smart render. The picture is not a
  parameter, so without the hash, editing the source layer would have let the accumulator cache
  resolve the old shape. The device caches its upload on the same hash, and the shadow maps
  add it to their key.
- **A source withdraws the GPU offer.** `PF_Cmd_SMART_RENDER_GPU` would hand the source over as
  a GPU world the builder cannot read. AE has never taken that offer on this effect, and the
  host path still renders on the card.
- **`PF_OutFlag_PIX_INDEPENDENT` is gone.** It stopped being true when the effect started
  reading another layer. It never changed anything that was measured, so it was dropped
  outright rather than withdrawn per frame through dynamic flags.
- **Any failure reading the source is no shape, not a failed frame.** The log says which:
  `pareidolia:` lines under `MISTYTUNE_DIAG=1`.

### Known limits

- **The legibility readout is not built.** PLAN.md's measured legibility from a shape-context
  matcher, and Decay in its units, are still to come. Decay is input strength, eased.
- **Close and looking up, the shape foreshortens.** The plane is vertical, so from under a 1.7
  km face at 1.5 km, the frame is mostly its lower half. Tilting the plane to the lens would
  lift its base off the condensation level. Not done; worth asking.
- **Luminance is of the values as they arrive.** In a linear 32 bpc project a mid-grey is 0.18,
  so Threshold means something different there than at 8 bpc.
- **The field ignores the shape.** Field clouds near the hero overlap it with the field on, as
  they overlap the tower. Alone is clean.
- **Hero Cloud Off hides the shape** even with a source picked. The shape is the hero.

### What needs the host

- **Apply the effect fresh.** The Pareidolia group was inserted in the Cumulus layer before its
  spares, so every control after it (Physics, Quality, Output) shifts in a project saved by an
  earlier build. The minor bump is what makes the group appear.
- **Pareidolia:** put a text layer, a shape layer or footage in the comp. Hide it with its eye,
  or leave it visible under the effect's layer. Then pick it as Shape Source. White text on
  transparent works with Alpha. A black mark on white works with Inverted Luminance.
  - Does the shape appear on the hero, the right way round?
  - Does editing the text update the cloud? That is the hash in the render key.
  - Does an animated source animate the cloud?
  - Try Decay keyframed from 0 to 1, Shape Billows, Depth, Facing Fixed with Orbit, and Sun
    Placement Front Lit.
- **Build 20's items**, below, because they are still unreported.
- **In the log**, with `MISTYTUNE_DIAG=1`, the lines to look for:
  - `pareidolia: source [x,y wxh]` at pre-render.
  - `pareidolia: WxH source -> map in N s` at render.
  - `pareidolia source present -- not offering GPU_RENDER_POSSIBLE`.

---

## 2026-09-30 — THE ORGANIZATION GROUP: ROWS, WAVES, GAPS AND HOLES. Build 20, minor 10. The spec's last Phase 3 group. Each layer gets its own Mode (Cellular, Rolls, Waves, Chaotic), Aspect Ratio, Rows Along, Row Coherence and a wave field. The cumulus deck also gets Gap Fraction and Lacunarity. The classifier names what they make: undulatus, radiatus, perlucidus, lacunosus. At the defaults the kernel runs the code it ran before, bit for bit, and nothing about the default frame's time changed. Phase 3 is done.

### Where builds 18 and 19 stand

Build 18 is installed and not reported on. Build 19 was built while AE was open, so it was
staged and never installed. Build 20 contains it, so **this is the first time build 19's
ground shadows and ground skylight reach the host.** Its "What needs the host" list below
still applies.

### One model for every mode

The kernel knows nothing of Cellular or Rolls. `OrganizationLib.slang` has a **pattern
frame**: the lattice rotated so its rows run along a bearing, and stretched along them. It
also has a row jitter, a wave and a warp. `src/engine/Organization.h` turns each mode into a
setting of those:

| Mode | Setting |
| --- | --- |
| Cellular | the controls as they are |
| Rolls | cells 4x longer again along the rows: cloud streets |
| Waves | rows turned along the wave's crests, cells 2x longer, amplitude at least 0.6 |
| Chaotic | the lattice warped by smooth noise (1.2 slot widths over 2.5 cells), rows' coherence dropped |

So a mode is a starting point, and every slider stays live in every mode.

**Why the bounds survive.** Both generators prove their bounds in lattice units: the 3x3
neighbourhood, the reaches, the ice's overlap count. Rotating and stretching the lattice
moves it in the world, and it changes none of those statements. A world box becomes a
parallelogram in the pattern frame, and the bound searches its bounding box, which is sound
and at worst looser. Coherence shrinks the jitter across the rows, so every layout it
allows was already allowed. The wave is a factor in [1 - amplitude, 1]. The warp moves the
read point by at most 1.2 x `kFbmBound` per axis, and the box grows by the same.

**The defaults are off.** Rows Along defaults to 90, rows along +X, which is where the
lattice always had them. With nothing else set, `OrganizationResolved.on` is false and the
kernel takes the pre-build-20 path. A Rows Along keyframed round to 450 still counts as off.

**Specialised, because it was measured.** `convUpdraftGrad` is the hottest function in the
cumulus layer. With one body serving everything, the default scenes were 4% slower with
the group off, and the organized path at its identity cost 15%. The extra state in the
lattice loop costs registers whether or not a branch is taken. It is now three
specialisations chosen once per call: off, organized, and organized with Lacunarity's
holes.

### Gaps and holes (the cumulus deck only)

**Centre-ness** is `1 - kNext / kTop`, from the two largest cell kernels at a point. It is
near 1 at a cell's centre and 0 on the seam between two cells. It ignores how vigorous
the cell is, so a threshold on it gives every cell the same shape of gap or hole.

- **Gap Fraction (perlucidus)** clears the seams to a band of 0 up to half the gap width,
  then ramps to 1. The width is the square root of the slider, because a closed cell's
  visible top starts late, around centre-ness 0.4, and on a linear map 0.3 and 0.6 looked
  like no gap at all. It is scaled by polarity: an open cell's cloud *is* its seam, so on
  open cells gaps do nothing.
- **Lacunarity (lacunosus)** turns the layer into a thin sheet, a third of the depth to the
  lid, with one round hole per cell. Hole radius is 0.5 cells x lacunarity x vigour^¼, so a
  hole shrinks away as its cell dies instead of popping. Billows on the sheet are cut to 40%
  so they don't fill the holes. Three versions were wrong first. Holes punched in the deck
  alone left 0.8% of the cloud, because a closed deck's cloud is at its centres. A blend
  towards a holed sheet made no hole below about 0.8 on the slider. A sheet that carried
  each cell's vigour rendered as shards and pits.

**The bound needed nothing new for either.** Holes, gaps and the wave are factors of at
most one. The sheet is a constant, so the blend stays under the same blend of the bound.
**The slope did need something.** The density clamps the slope it uses to
`convSlopeCap`, and the bound divides by the same cap. That makes the bound sound whatever
the true slope. The added terms are the holes', the gaps' and the wave's own maximum
slopes, so the clamp only bites under the warp.

### The classifier

| Variety | When |
| --- | --- |
| undulatus | wave amplitude ≥ 0.25 (Waves mode is at least 0.6); Sc only |
| radiatus | Rolls with coherence ≥ 0.5; Cu, Sc and Ci |
| perlucidus | Gap Fraction ≥ 0.2, or coverage below opacus |
| lacunosus | Lacunarity ≥ 0.4, which makes the layer a deck at any polarity |

**Opacus and perlucidus were called species until now.** The atlas has them as varieties
of stratiformis, so the readout now says "Sc stratiformis opacus". When a name doesn't fit
the panel, the atlas's abbreviations stand in, the low layer's varieties first:
"Sc str op un, Ci uncinus".

### Measured

**Timings**, CLI, 640x360, 32 spp, best of 3. Scene A is the default backlit hero with Cu
and Ci. Scene B is a cumulus field, sun at 6°, looking along it.

| | time | against its base |
| --- | --- | --- |
| A, default | 24.95 s | build 19: 25.9 s |
| B, default | 9.57 s | |
| B, Rolls, coherence 0.8 | 7.56 s | -21% |
| B, Waves | 7.75 s | -19% |
| B, Chaotic | 12.44 s | +30% |
| B, closed cells | 8.32 s | |
| B, closed, Gap 0.6 | 10.07 s | +21% over closed |
| B, Lacunarity 0.8 | 14.79 s | +55% |

Rolls and Waves are faster because the same coverage lays down fewer, longer cells. Chaotic
is slower because its warp reaches 1.8 cells, which pushes every majorant bound off the
fixed 3x3 path onto the general loop. Gaps and holes raise the slope cap, which shortens
the steps near walls. A lacunose sheet is also simply more cloud.

**slang.convection check 7**, new:

| | |
| --- | --- |
| switched on at the identity, against off | 0 of 100000 updrafts and 0 of 50000 densities differ |
| Rolls: correlation one cell along the rows / across | 0.521 / 0.044 |
| coherence 1 | 0 of 1600 centres off their row |
| wave amplitude 1, 6800 trough points | largest updraft 0 |
| closed deck, gap width 0 / 0.45 / 0.9 | 72.2% / 66.7% / 46.3% cloud |
| open cells with gaps | 0 of 100000 updrafts moved |
| lacunarity 0 / 0.25 / 0.5 / 1 | near-centre cloud 81% / 74% / 33% / 4%; seams 52% / 100% / 100% / 100% |

The box-bound and 3x3-window checks (1 and 4) now also run five organized fields (rolls at
30°, waves, the chaotic warp, gaps and holes, and everything at small cells): 0 violations
in 3000 boxes each, and 0 of 100000 points differ between the 3x3 and 5x5 windows.
**slang.generator**: the ice's structural bound holds in all 512 cells of an organized
field (rows at 35°, stretch 4, a wave, the warp), and its sampled peak of 1.67 stays under
`cellOverlapBound()`'s 3.26.

**Goldens: unchanged.** The organization is off in all three, and the CPU and GPU still
match them.

**Looked at**, from 5 km looking down on a closed deck (`build/tmp/b20/final/`): Rolls
are clean parallel streets with clear lanes, Waves are bands of stretched cells, Chaotic
bends the rows and mixes cell sizes, Gap 0.6 opens the seams, and Lacunarity 0.8 is a
white sheet with round holes that shows ground and shadow through them. The cirrus
looking up: Rows Along 0 gives bands along +Z, and 90 gives bands across it.

### Tests

- **TestOrganization**, 6 new: the defaults are off (and so is 450°); 90° is the world
  frame; each mode is the setting its name says; the wave varies across its crests; NaNs
  and out-of-range expressions come out as numbers the bounds hold for; and the ice ignores
  gaps and holes.
- **TestClassifier**: `OrganizationNamesTheVarieties` covers each variety and the
  abbreviation fallback. The random sweep now drives the organization too, against the
  panel's length limit.
- **TestFingerprint**: every OrganizationParams field on both layers moves the hash. So do
  the hero's six fields, which this list had missed since build 15. They were hashed all
  along; only the test was missing them.
- **225 unit tests, 27 ctest suites, all pass.**

### Known limits

- **Chaotic costs 30%** on the default field, for the reason above. A tighter warp bound, or
  a warp that moves whole cells instead of the point read, would fix it.
- **Gap Fraction does nothing on open cells**, by design. Their cloud is the seam.
- **The hero ignores the organization.** It is one placed cloud.
- **Cirrus has no undulatus.** The atlas gives it none. Cirrocumulus, which has one, isn't a
  generator here.
- **Ice organization reads faintly at the default optical depth of 0.45.** It works, but
  on a thin deck.

### Phase 3's exit test

PLAN.md's exit test is that the two-layer default (cumulus plus thin cirrus, backlit) is
showable. It has been the default since build 17: the hero With the Field under the Ci deck,
Sun Placement Backlit. Scene A above is that frame. **Phase 3 is done pending the host's
look, and pareidolia (Phase 4) can start.**

### What needs the host

- **Two new groups**, "Ice Organization" and "Cumulus Organization", each at the end of its
  layer. The minor bump is what makes them appear.
- **Cumulus:** set Polarity to 1 (closed cells), raise the camera and look down. Try Rolls
  with Row Coherence 0.8, then Gap Fraction 0.6, then Lacunarity 0.8. The readout should
  name radiatus, perlucidus and lacunosus in turn.
- **Build 19's items**, below, because this is the first build that carries them.
- **Apply the effect fresh.** AE stores values by position, and the Ice Organization rows
  were inserted mid-list, so a project saved by an earlier build reads shifted values for
  every control after the Ice group: Cumulus, Physics, Camera. Nothing has shipped, which
  is what makes the insert free (docs/HOST-NOTES.md).

---

## 2026-09-30 — THE CLOUDS' SHADOWS FALL ON THE GROUND, AND THE GROUND SEES THE SKY. Build 19, minor 9. Build 18's shadow maps are read where a ray lands on the ground. Shadowed ground then came out black, which exposed a Phase 1 shortcut: the ground had only ever been lit by the sun. It now also gets the sky dome's light, one colour per frame, integrated on the host in 3 ms.

### Where build 18 stands

Installed, not yet reported on. The host asked to "finish everything" and be told when
pareidolia can start, so this build and the Organization group follow without a stop.

### Build 18's first "Next" item was measured and dropped

It proposed summing the air along the camera ray to remove the extra noise on the clouds.
Measured in linear light at `--ev -4` (scene B, 320x180, 4 spp), the absolute noise was
20.1 with the map, 19.3 with no air shadows and 21.9 with aerial perspective off. There is
no excess to remove. What build 18 saw was a darker image, through sRGB and 8-bit
clamping.

### Shadows on the ground

`groundShadow` in AirMapLib.slang: where a ray that escapes the clouds heads down, it
lands on the flat ground at y = 0, and that point's transmittance to the sun is read from
both layers' maps. The ground lies below every slab, so the read is slice 0, the whole
column, the case slang.airMap already held to 0.0001 mean error. `skyRadiance` gained a
`groundLit` argument that scales the ground's sunlit term and nothing else.

**This covers the ground in view and the light the ground throws back up at the cloud
bases.** Both are the same escaped ray.

**The maps are now built whenever the sky is the environment**, not only when Cloud
Shadows In Air is on. Turning the air's shadows off keeps the ground's.

### The ground had no skylight

The first render of the default backlit hero had a black foreground. The camera stands in
the hero's shadow, and the ground's radiance in the sky model was
`albedo / pi * sunT * irradiance * cos`: the sun and nothing else. Nothing had shown it
before, because nothing shadowed the ground. Only the sunset golden gave a hint: its
ground was a dark orange-brown.

**The fix is one colour per frame.** The sky over flat ground is the same everywhere, so
its irradiance there depends only on the sky's parameters. `groundSkyLightFor` in
Shading.h integrates Shading.h's own `skyRadiance` over the upper hemisphere at altitude 0.
It uses 32 x 64 midpoints, each weighted by its mu, with the disc left out because the
disc is the sunlit term already. The result, times albedo / pi, rides in
`SkyInput.groundSkyLight` and is added where a ray lands on the ground. It is not dimmed
by the clouds' shadow. `deriveGroundSkyLight` (GroundSkyLight.cpp) caches it per thread,
keyed on the eight sky parameters. Unlike the transmittance table, the sun is in the key,
so dragging the sun costs one integral per change.

**Measured:**

| | |
| --- | --- |
| 32 x 64 against 128 x 256 | under 0.1% to a 45° sun, 0.49% at 85° (aureole near zenith) |
| equal steps of mu², tried first | 1.2 to 1.4% at every sun: a √ kink at the horizon |
| time for one integral | 2.9 to 3.0 ms |
| sky / sun on the ground at 45°, turbidity 2.2 | 0.038 R, 0.077 G, 0.169 B |

The last row is single scattering only. Real clear-sky diffuse is somewhat higher, so
this is an underestimate, and a blue one, as it should be.

**Shading.h's own `skyRadiance` does not add it.** That function is the reference
slang.skyParity compares against, with the new term at zero. `0` adds nothing and a
`groundLit` of 1 multiplies exactly, so the check stays bitwise.

### Measured

**Goldens, in two steps.** The mean change per band against the build 18 references, in
8-bit levels:

| | upper half | lower half (ground) |
| --- | --- | --- |
| midday, shadows only | -0.01 | -0.87 to -1.00 (the cirrus deck's shadow) |
| horizon, shadows only | 0.00 | -0.09 near the horizon, 0 close up |
| sunset, shadows only | 0 | 0 |
| midday, + skylight | +0.03 | +6.6 |
| horizon, + skylight | +0.03 | +12.8 |
| sunset, + skylight | +0.01 | +32.5 |

Every changed channel went the expected way: darker for shadows, brighter for skylight.
Sunset doesn't move with shadows, because a 2° sun puts the cirrus's shadow about 250 km
away, past the 40 km Render Distance. Horizon's shadow is likewise only on the far ground.
The small rise in the sky half is the cirrus lit from below by the brighter ground.
Sunset's ground went from near black to a dim neutral grey-brown, which is ground lit
mostly by the dome. The goldens were re-blessed after both steps, and the CPU and GPU
match them.

**Cost: nothing measurable.** A high view over the cumulus field (below) took 8.3 s with
ground shadows against 8.2 s without. The default backlit hero at 640x360 with 32 spp
denoised took 25.9 s, against 26.2 s before the skylight.

**Looked at:** `--cumulus --altitude 6000 --pitch -35 --sun-el 40 --sun-az 200`. Every
cloud has its shadow on the ground, offset away from the sun, with soft edges. Through
6 km of air they read blue, as in aerial photos.

### Tests

- **slang.airMap check 6**: rays from above the core land on the ground. The error against
  the closed form is 0.0003 to 0.0008 mean and 0.0046 at worst, and rays going up answer
  exactly 1. The first version aimed rays 45° either side, which put only 112 of 4000
  landings in a 300 m core's shadow at a high sun. It now aims within 1 km of the
  shadow, which puts 1466 to 2719 in shadow.
- **slang.skyParity** is still bitwise against Shading.h (its SkyInput is now zeroed
  first). It gained a ground-skylight check: with the term set, no upward ray changes a
  bit, all 7160 downward rays gain between 0 and the term, and straight down from 2 m
  gains 0.99992 of it.
- **TestAtmosphere**, 2 new tests: the grid converges, and the result behaves like
  skylight. A black ground gets none, a sun at -30° gives exactly 0, it is bluer than it
  is red, and against the direct beam at 45° it is between 0.02 and 0.5 in every channel.
- **218 unit tests, 27 ctest suites, all pass.**

### Known limits

- **The clouds don't block the skylight.** Ground under a cloud still sees the whole dome
  as clear sky, and it doesn't see the cloud's own light. Under a thick deck the shadowed
  ground is too bright and too blue.
- **One value for all the ground in view.** A patch 40 km off sees the sun 0.36° lower.
- **Single-scattering sky**, so the skylight is on the low side.

### What needs the host

- **The default backlit hero changed visibly.** The foreground ground is in the hero's
  shadow now: a dim blue-grey where it was sunlit brown.
- **Look down on a cumulus field** (raise the camera, pitch down): the shadows should sit
  under their clouds. Turn Cloud Shadows In Air off, and the ground's shadows should stay.
- **A low sun**: the ground is lit by the dome and is no longer near black.
- **Saved build 18 projects open unchanged**, because no parameter moved.

---

## 2026-09-30 — THE CLOUDS' SHADOWS IN THE AIR COME FROM A MAP. Build 18, minor 9. Build 17's shadow ray per camera ray cost 20 to 43% of the frame and speckled the sky. A deep shadow map per layer, built once per frame, makes those shadows free. They are also exact in colour now, and the sky's noise at 1 spp denoised is halved. On the way, nvcc accepted a host function call from device code, which returned 0 and switched the map off on the GPU only.

### Where build 17 stands

The host committed build 17 and asked to move on. That is recorded as ACCEPTED, NOT
MEASURED: there was no report on backlit-by-default, the haze or the readout. The next
item was the one build 17 queued: the shadow map.

### What it is

`src/kernel/slang/AirMapLib.slang`. One map per layer, because the transmittance through
two media is the product of the two:

- **Texels** lie on the layer's bottom plane, on a grid laid out along the sun's azimuth.
- **Each texel is a column**: the sun ray that crosses the plane there, climbing through the
  slab. There are 16 slices for the cumulus and 8 for the cirrus, at equal steps of
  altitude. Slice k holds the transmittance to the sun from where that ray is at slice k's
  altitude.
- **A lookup** slides the point along the sun to the plane to find its column, and its
  altitude picks the slice. Below the slab it reads slice 0, which is exact but for the
  bilinear read. Inside the slab it interpolates between slices. Above the slab it is 1.
- **The build** is a deterministic midpoint march from the top of each column down. It stops
  at optical depth 12, below which the column is black. One thread per column on the GPU,
  a thread pool on the CPU, both through the same generated Slang.
- **`airShadowLoss`** takes the shadowed airlight off the sky (for a ray that escapes) or
  off `airSegment`'s airIn (for one that hits a cloud). It uses 48 jittered quadratic
  steps over the stretch of the ray where a shadow can fall, and it has the same integrand
  as the sky. Where nothing is shadowed the loss is exactly zero, so the sky is untouched
  bit for bit.
- **Build 17's shadow ray** is kept behind `--air-shadow-rays` (RenderRequest::airShadowMap)
  and is also the fallback below a 1° sun, where the grid would be stretched 57 times the
  slab's depth.

**The grid covers exactly what the density can reach.** The host fills a Scene as a sample
does and reads each layer's slab, hero box and Render Distance off the kernel's own Medium
(`AirMapHost.h`). The box is that footprint stretched away from the sun by depth /
tan(elevation). The texels are square, from a budget of 512² for the cumulus and 256² for
the cirrus. A lone hero's map is a few kilometres across, with texels of tens of metres
(TestAirMapPlan holds a hero's under 40 m). The field's cumulus map in scene B below has
169 m texels.

**Built once per frame, not per launch.** The cache is thread-local and keyed on the bytes a
column reads: both media, the drift table and the plan. It is compared whole, so a key
cannot collide. The bands and sample chunks of a frame, and an exposure change, all hit
it. On the GPU the key also records the allocation, because DeviceScratch reallocates when
it grows.

### The GPU bug: a host function in device code, accepted by nvcc

The first GPU renders with the map were BYTE-IDENTICAL to renders with no air shadows at
all. On the CPU the map worked. On the GPU it had been built correctly, with slice means
matching the CPU's to four places. A device printf showed every map's buffer count as 0,
so every lookup answered 1.

`fillAirMap` in SlangBridge.h runs on the device and computed the count with
`airMapFloats()`, a plain host inline in AirMapPlan.h. nvcc compiled a host function
called from `__host__ __device__` code without an error, and on the device it came back 0.
The product is now written out, and the comment says why.

### Measured

Two scenes, 640x360 on the RTX 2070 SUPER. A is the backlit hero: `--orbit 0 --hero 1
--sun-placement backlit --render-distance 40000 --turbidity 5`. B is a low sun into a cumulus
field: `--cumulus --sun-el 6 --sun-az 180 --heading 180 --pitch 4 --turbidity 5
--render-distance 40000`.

| | shadow ray (b17) | map (b18) | no air shadows |
| --- | --- | --- | --- |
| A, 32 spp | 29.9 s | 25.9 s | 25.0 s |
| A, 128 spp | 123.0 s | 99.7 s | 98.6 s |
| B, 32 spp | 14.2 s | 10.2 s | 9.9 s |
| B, 128 spp | 57.1 s | 41.2 s | 40.0 s |

**The map build** is 0 to about 20 ms a frame on the GPU (the difference between 32x18
renders, min of 3, over four scenes). On the CPU reference it is 0.7 to 3.3 s. That is
nothing beside a CPU path trace, and the whole ctest run still takes 46 s.

**Noise**, RMSE against each estimator's own 128-spp reference. Sky pixels are those a
cloud-free render matches within 4 levels, above the horizon. Cloud pixels are those it
misses by 12 or more:

| 1 spp denoised | sky A | sky B | clouds A | clouds B |
| --- | --- | --- | --- | --- |
| shadow ray (b17) | 8.11 | 12.24 | 21.4 | 17.5 |
| map (b18) | **4.95** | **6.09** | 21.0 | 16.3 |
| no air shadows | 3.94 | 3.73 | 16.0 | 10.4 |

Raw at 1 spp, the whole of B: 67.4 with the ray, 37.3 with the map, 23.0 with no shadows.

**The map's own estimator adds no noise the frame can show.** Pinning its jitter at 0.5 left
both the sky and the clouds unchanged to the second decimal. Four map reads per step, with
golden-ratio offsets, also changed nothing and cost up to 5%, so they were reverted.

**What remains above "no air shadows" is delta tracking's escape-or-collide coin toss.** The
air in front of a backlit cloud is now correctly dark, so a sample that collides and one
that escapes differ by more than they did. The excess sits on the clouds, not the sky (a
difference image shows it). It is the variance cameraSegmentSun removed for the sun, and
the same cure would work for the air. See "Next".

### Colour: exact now, where build 17 averaged

At 128 spp the two estimators agree in luminance to within one level in every third of
both frames. In the sky band the map is redder by 4.3 and bluer by 4.5 to 6.6. Build 17's
estimator was unbiased in luminance only: it gave a shadowed stretch the whole segment's
average colour. The map colours each step with its own. The direction fits shadows lying
in the far, reddened air towards a low sun, where build 17 took out too little red.

### Tests

- **slang.airMap** (new, 8 s) checks three suns, including a 5° sun on a diagonal azimuth:
  1. **Lookups against the closed form** of a Gaussian core (an erf), 40,000 points. Below
     the slab: mean |ΔT| 0.0001, 99th percentile ≤ 0.003. Inside the slab: mean ≤ 0.0015,
     99th ≤ 0.018.
  2. **The loss against an independent march** of 20,000 fixed midpoints: worst 0.018% of
     the loss, over 360 rays.
  3. **Rays that never meet the grid lose exactly nothing.**
  4. **No maps, no loss.**
  5. **The build is deterministic.**
- **TestAirMapPlan** (9 new unit tests): every cloud point's shadow lands on the grid, for
  30 suns over the field and 9 over a hero. The box is the footprint plus the stretch, the
  texels are square within budget, and the column's step budget holds. Also the 1° cutoff,
  the shared buffer's offsets and absent layers.
- **With `--air-shadow-rays`, all three goldens reproduce build 17's references byte for
  byte on the CPU.** Nothing else in the renderer moved. The goldens were then re-blessed
  from the map after inspection. The band means moved by at most 2.3 levels (sunset's blue),
  and the CPU and GPU renders agree.
- **216 unit tests, 27 ctest suites, all pass.**

### Known limits

- **Inside the slab at a low sun** the slices are far apart along the ray: 1.4 km at 5°.
  Air between towers can then get a smeared shadow, and the worst point in slang.airMap
  is off by 0.58. Air below the base, which is most of what a ground camera sees, is
  unaffected.
- **Below a 1° sun** the renderer falls back to build 17's shadow ray.
- **Memory:** 19 MB of VRAM per render thread for the two maps, and the same in host
  memory on the CPU path.

### Next

1. *(Measured and dropped in build 19: the noise was not what this says. See that
   entry.)* **The air along the camera ray as a sum, not a coin toss.** This is the cloud-pixel noise
   above. It uses cameraSegmentSun's own ratio-tracked transmittance, applied to the
   shadowed airlight, so the air stops depending on where the path happens to collide.
2. **Cloud shadows on the ground.** The map makes this one lookup where the sky's ray hits
   the ground, and it would also darken the ground light that reaches cloud bases.
3. **The Organization group**, which is the rest of Phase 3.

### What needs the host

- **Does Cloud Shadows In Air now look right and cost nothing?** Try a backlit hero, and a
  low sun into the field for crepuscular rays.
- **Draft at 1 sample**: the sky should be cleaner than build 17. The clouds are about the
  same.
- **Saved build 17 projects open unchanged**, because no parameter moved.

---

## 2026-09-30 — THE AIR IN FRONT OF THE CLOUD, THE SUN THAT FOLLOWS THE LENS, AND A NAME FOR THE SKY. Build 17, minor 9. The first three of Phase 3's remaining items. On the way, the sky's own march turned out to have been 16.5% dark at the horizon since Phase 1, and the Cloud Shadows In Air checkbox turned out never to have been read.

### Where build 16 stands

The host committed build 16 and asked to move on. That is recorded as ACCEPTED, NOT
MEASURED: there was no report on the orbit rig itself. The next item was chosen by the
host: finish Phase 3.

### Aerial perspective on the clouds

Missing since build 9. A camera ray that escaped got the whole sky's airlight from
skyRadiance. One that scattered in a cloud at t₁ got the cloud's light undimmed and no
air in front of it, so a cumulus 30 km out was as crisp and white as one at 3 km.

**Exact under delta tracking.** With t₁ drawn from the cloud's own free flight
(infinity for an escape), the eye sees the airlight over [0, t₁] plus T_air(t₁) times
whatever the path gathers from t₁ on. The expectation over t₁ is the two-medium
integral, because P(t₁ > s) is the cloud's transmittance to s. The escape case already
was skyRadiance. So `airSegment` in SkyLib.slang is the same march stopped at t₁: its
airlight is added once, and its transmittance goes into the throughput before the first
event's own next event. `airTransmittance` dims the camera segment's sun estimate at
the point it kept, which keeps the reservoir unbiased.

**Cost: none measurable.** Default scene, 640x360, 32 spp: 28.6 s against 28.8 s.

### The sky's march was dark, and a new check found it

slang.skyParity gained six checks on the new march, including one against a host
integration in double with 4096 steps. The kernel's airlight matched, to the digit, a
host model of its own quadrature (24 steps, each step dimmed by ALL of its own optical
depth). It did not match the converged answer, and neither did skyRadiance:

| elevation | 3 km | 20 km | 60 km | whole ray (the sky) |
| --- | --- | --- | --- | --- |
| 1° | 0.31% | 1.82% | 4.29% | **16.51%** |
| 5° | 0.30% | 1.56% | 3.26% | **9.39%** |
| 20° | 0.27% | 1.11% | 1.79% | 3.05% |

Taking each step's transmittance at its MIDDLE (the step before it plus half its own)
brings the whole ray to 0.68%, 0.74% and 0.93% with the same 24 steps. Shading.h's
comment on that line had always said "includes this step's own half" while the code
added all of it. Fixed in Shading.h, skyRadiance and airSegment together, so
slang.skyParity is still bitwise over 260,082 channels. **The low sky is brighter and
bluer than it was**, most at the horizon. That is the correction, and it is a change to a
look the host approved.

The first cut of the checks also failed "front plus behind equals the whole" by 6% and
found the airlight falling between 150 km and the top of the air. Both were this bias in
the long ray, not errors in the new code. The reference table is what told them apart.

### Cloud Shadows In Air: hashed since Phase 1, read by nothing

The fourth control in this project wired everywhere except where it would do anything.
It now puts the clouds' shadows into the airlight along the camera segment. One point is
drawn along the segment in proportion to its airlight's luminance, and one shadow ray is
cast from it. The estimate is airIn x V. It is unbiased in luminance and gives a
shadowed stretch the segment's average colour. The exact estimator goes negative in a
channel whenever a fully shadowed point is drawn, and one sample per pixel cannot
survive that (see airShadow in BounceLib.slang). Check 6 draws 65,536 points and matches
the airlight's own distribution to 0.27%.

**It is what makes aerial perspective right for a backlit cloud.** Without it, the hazy
air in front of a cloud with the sun behind it glows as if the cloud did not shade it,
and the hero washes out to a pale mass (sun 22° behind the hero, turbidity 5). With it,
that air is in the cloud's shadow, and the hero reads dark with a silver lining. So it
stays ON by default, and the checkbox's comment says what off costs.

**Its price, measured:** +29% on the default frame (28.6 s to 37.0 s). At 1 spp,
denoised, the sky's RMSE against a 128-spp reference goes from 3.43 to 8.56. The hero
body is unchanged at 16. The single shadow ray per pixel is either lit or shadowed under
a cumulus field, and OIDN cannot average a coin toss it sees once.

**Tried and reverted: stratifying the shadow point across the frame.** Interleaved
gradient noise across pixels, with a golden-ratio step per sample. The sky LOOKED
smoother, but it measured 8.99 against white noise's 8.56, and the whole frame and the
hero were identical. OIDN is trained on white noise and seems to keep a structured
pattern rather than average it. It took a signature change through four files and was
backed out.

**THE REAL FIX IS A SHADOW MAP.** Each frame, the cloud layers' transmittance to the sun
goes into a 2D grid over the ground, once. Every airlight step then looks it up. That is
noise-free, costs a texture fetch per step, and could put the clouds' shadows on the
ground too. At the measured 1.14 µs per shadow ray, a 256² map is about 75 ms a frame,
against the 2.4 s this estimator adds to a 1080p frame at 1 spp. It is the next piece of
Phase 3 work, not part of this build.

### Sun Placement: the three sun-camera presets, backlit by default

A popup at the top of Sun and Sky offers Backlit, Side Lit, Front Lit and Manual.
Under a preset the sun's azimuth is set from the camera's heading. Orbit now changes
which side of the cloud is seen, not its lighting. Backlit is 20° to the right of
straight ahead, which is the default hero's flank from the default Distance, so the
silver lining runs down that side instead of hiding behind the middle of the cloud.
Elevation stays the Sun Elevation slider. Manual is the old world-fixed sun, and
Sun Azimuth is relabelled "(Manual)".

The heading is the camera's horizontal forward, plus its up vector weighted by the
forward's vertical part. Directly under the hero looking up (Distance 0), the forward has
no heading, and this still gives the orbit's. **The first version switched the up vector
in by the sign of the pitch**, which a test showed would swing the sun about 27° when a
level camera was rolled 30°. TestSunPlacement checks every preset through the kernel's
own sunDirection against the forward and right of the matrix the rays use. It covers six
orbits and three pans, the pole, tilting past the zenith, and roll.

### The classifier readout

`src/engine/Classifier.{h,cpp}`, rule-based over the parameters as PLAN.md decided. It
names the sky with the cloud atlas's genera and species:

- **Cumulus:** humilis, mediocris or congestus, by a tower's height over its width, with
  absolute limits so a 5 km mound is congestus.
- **Stratocumulus** once polarity passes 0.5: opacus, perlucidus or castellanus.
- **Cirrus:** fibratus, or uncinus when the wind turns 15° or shears 10 m/s between the
  top and bottom knots, plus spissatus and floccus.
- **Nothing:** "too dry for Cu" when the condensation level is above the inversion.

The default sky reads "Cu mediocris, Ci uncinus". The build 14 reference tower reads
"Cumulus congestus".

The readout moved to the top of the panel, outside every group. It sat at the end of the
collapsed Output group. It is renamed with PF_UpdateParamUI, as the SDK's Supervisor
sample renames a parameter. That happens on PF_Cmd_USER_CHANGED_PARAM from the thirty
controls it reads (now PF_ParamFlag_SUPERVISE), and on PF_Cmd_UPDATE_PARAMS_UI (a new
out_flag) for opening the panel and loading a project.

**AE's parameter name holds 31 characters**, and that is the contract.
EveryReadoutFitsInAnAfterEffectsParameterName throws 20,000 skies at it.

### Tests and goldens

- **207 unit tests**, 25 of them new. All 26 ctest suites pass.
- **slang.skyParity** gained its six air checks.
- **The three goldens were re-blessed** after rendering each one three ways: the sky fix
  alone, plus aerial perspective, plus shadows in the air.
  - The sky fix brightened the sky bands (blue +2.6 to +5.1 of 255) and left the ground
    band unchanged.
  - Aerial perspective took blue out of the backlit sunset cirrus (−11 in the top band),
    which is what a distant cloud under a 2° sun does.
  - Shadows in the air took a few levels off the sky under the cirrus.
  - The blessed CPU references match the inspected GPU renders to 1 level.

### Machine note

**C: is full: 0 GB free.** nvcc writes to TEMP, so one build failed with "No space left
on device" and then a ptxas "Memory allocation failure". The builds here now point TEMP
at `build/tmp` on D:. Nothing on C: was touched.

### What needs the host

- **Backlit by default.** Is the new first frame the right one?
- **The haze.** Distant clouds should now dissolve into the horizon, and the low sky is
  brighter and bluer than build 16.
- **Draft at 1 sample is noisier in the sky** (see above). How much does it bother you
  before the shadow map exists?
- **The readout** at the top of the panel. Does it rename as Instability and Polarity
  move?
- **Saved build 16 projects will be scrambled**: two rows were inserted above everything.
  Re-apply the effect.

---

## 2026-09-30 — THE CAMERA ORBITS THE CLOUD. Build 16, minor 8.

### What the host reported

"The camera movements still feel very unintuitive ... I'm lost. I should be able to
dolly around a specific point or cloud, move towards it or against it."

Three causes, none of them a bug in CameraConvert.h:

1. **AE's camera moves in comp pixels and the sky is in kilometres.** At the default
   Camera Travel of 1 m/px, reaching a 3 km cloud means thousands of pixels of dolly.
2. **AE's point of interest pivots on a spot on the ground.** The world origin is the
   comp centre on the comp plane, at eye height. The cloud is 0.7 to 2.4 km above that
   spot, so the Orbit tool swings the camera round the ground under the cloud. A
   default camera looks level, so the cloud sits above the frame.
3. **AE's viewer draws nothing where the cloud is.** The only feedback is a slow render.

### Orbit the Hero

The Camera group now opens with a **Camera** popup. **Orbit the Hero** is the new
default, and **Comp Camera** is build 15's behaviour, unchanged. The rig is in
`src/engine/OrbitCamera.h`:

| Control | Meaning |
|---|---|
| Orbit | round the hero; 0 stands where a default camera does, + walks right |
| Distance | metres from the hero's axis along the ground; 0 is underneath, looking up |
| Eye Height | the old Camera Altitude, relabelled (same ID and index) |
| Look At Height | where on the cloud it aims: 0 base, 1 top; follows the Inversion |
| Tilt / Pan / Roll | offsets from that aim |
| Focal Length (mm) | on 36 mm film measured across, so 50 is AE's 50 |
| Comp Camera Travel | relabelled; used only by Comp Camera |

The target is Hero Position X/Z whether or not the hero is drawn. Look At is a
fraction of the hero's height, or of the field's towers when the hero is off, or of
the ground up to the cirrus generating level when there is no cumulus. The basis is
built from yaw, pitch and roll rather than a look-at cross product, so directly under
the cloud it looks straight up instead of degenerating. **Hero Cloud now defaults to
With the Field** so a new instance has something to orbit.

**The defaults, chosen from CLI renders** (480x270): Distance 4000 m and 24 mm frame the
default hero whole, with the horizon near the bottom edge. At 2500 m it fills the
frame. At Distance 3200 with the reference tower (Inversion 7000, Instability 0.9,
Width 4000, Height 0.7), it is the close, looking-up shot from the build 14 report,
and Orbit 90 shows its other side. **Under half the Hero Width the eye is beneath the
base**, and the frame is the base's grey underside. That is physically right, and it
is recorded because it looks like a failure.

**Also fixed:** `heroZ`'s comment said +Z is away from a default camera. It is
towards it: the camera stands on +Z looking down -Z.

### Tests

Six new cases in TestCamera.cpp: from 84 combinations of orbit, distance and Look At
(including directly underneath), the centre ray passes through the aim point. They
also pin orbit direction, tilt, pan and roll signs (none of which move the eye), that
the basis is orthonormal looking straight up, the eye floor, 50 mm matching AE's
22.9°, and the Look At span for the hero, the field and cirrus only. The CLI has the
rig as `--orbit --distance --look-at --tilt --pan --roll --focal`.

### What needs the host

- **Does Orbit / Distance feel like walking round a cloud and towards it?** That is
  the report this build answers.
- **The Comp Camera popup** still behaves as build 15 did.
- **Saved build 15 projects will have scrambled Camera and later values**: eight rows
  were inserted. Re-apply the effect.

---

## 2026-09-30 — THE CAMERA TRAVELS, ONE CLOUD CAN BE PLACED, AND THE WALLS GET CAULIFLOWER. Build 15, minor 7. The shape costs 1.8x on the default field, measured, and five cheaper-looking ways out were each measured and each failed.

### What the host reported

Build 14 looked good, but a close, looking-up shot of one towering cumulus (a phone
photo was the reference) could not be framed. Only the horizon view, or the same view
pitched up. The user was worried about this for pareidolia. Cumulus was only
interactive at Third resolution and Samples 1. They also said "we don't have to render
everything sometimes".

Two causes, both confirmed before any code was written:

1. **Only the comp camera's rotation reached the renderer.** CameraConvert.h dropped
   the translation on purpose, for want of a scale, so the eye stood 2 m above one spot.
   Moving a camera with a point of interest turned it; dollying it moved nothing.
2. **Tall towers were smooth pillars.** A test render with the camera placed as well as
   it could be (7 km inversion, sun behind, 18° up) showed tapered tombstones. The billow
   displaced a HEIGHT FIELD, so it roughened crowns and could not move a steep wall.

### Camera Travel

A Camera group after Sun and Sky: **Camera Travel** (metres per comp pixel, default 1;
0 is the old turn-only behaviour) and **Camera Altitude** (default 2 m).
`observerFromAE` in CameraConvert.h converts the position. The world origin is the comp
centre on the comp plane, which is where a new AE camera looks, so a default camera
stands zoom x travel metres behind it (2.7 km for 50 mm on a 1920 comp). The altitude
is floored at 1 m. With no comp camera, the eye stands where a default camera would, so
adding one turns the view without moving it. The matrix stays a pure rotation and the
position travels in ViewParams' new observer fields, in metres.

**MEASURED FROM THE HOST LOG, not assumed:** the image plane AE reports stayed 1920x1080
at Full, Half, Third and Quarter (911 frames at 1/4 and 1/3 in mistytune.log). The
camera is therefore in full comp pixels at every preview resolution, and a resolution
change cannot move the eye.

**NOT YET MEASURED:** whether the translation row is in comp space (the assumption) or
layer space. The log now prints `camera pos: comp (x, y, z) px -> observer (...) m`. A
new default camera on a 1920x1080 comp should read comp (960, 540, -2666.7) and
observer (0, 2, 2666.7) at 1 m/px.

### The hero cloud

Five rows in the Cumulus group: **Hero Cloud** (Off / With the Field / Alone),
**Position X/Z** (world metres; 0, 0 is in front of a default camera), **Width**,
**Height** (a fraction of the room under the Inversion, and the hero may use all of it
where the field's towers stop at towerFraction), and **Variation** (continuous, so
keyframing it morphs the lobes). The hero is an analytic tower on the same condensation
level with the same billows, and it holds still while the field drifts.

**Alone is a box.** Medium gained a horizontal box (`clipOn`, zero meaning unbounded, so
a zeroed test struct keeps the old behaviour). A ray that misses the hero never enters
the layer: 480x270 at 32 spp renders in 1.6 to 2.7 s against 24.6 s for a field of
towers.

### Cauliflower on the walls, in three attempts

The density now measures the distance to the surface, not the height below the top.
There are two intercepts, `v` down to the crown and `h` across to the wall, where `h` is
the updraft's shortfall over its gradient (exact, in closed form, for the hero). They
combine as the distance to the plane through both. The gradient rides the lattice
loop's hashes.

1. **Billow sampled at the point: loose flecks.** It varies along the normal as fast as
   across it, so pockets of it float free of the wall. Now sampled at the NEAREST SURFACE
   POINT (`p + d²(ŷ/v − g/δ)`), which makes it a relief on the surface.
2. **Lobe height over lobe size set too high in the test: pine branches.** At 700 m of
   billow on 500 m lobes, each lobe is taller than it is wide. At the defaults it is not.
3. **Horizontal banding like a beehive.** The puff lattice's feature points are jittered
   only a quarter cell (the eight-cell search needs that), and on a wall its rows show.
   Each octave now turns the lattice by a fixed orthonormal rotation.

The hero's billows scale with its width over a cell's (clamped 0.75 to 3). With the
field's lobes, a 4 km hero read as a beehive of small ones.

Also: the lift is capped at 0.7 x the height above the base. Away from every tower the
nearest "surface" is the base plane itself, and without the cap the billows would grow
a ragged sheet across the whole layer.

### What it costs, and five things that did not fix it

Density per evaluation on 4M points spread through the default layer (a tracking walk's
sampling), RTX 2070 SUPER, runs made one at a time:

| | ns per point |
| --- | --- |
| build 14, vertical distance | 0.35 to 0.42 |
| distance with the gradient, no billow | 0.39 to 0.42 |
| **distance with the gradient, billow in the shell (shipped)** | **0.64 to 0.68** |
| Lipschitz pre-test, gradient only in the shell | 1.16 to 1.20 |

The whole frame (default field, 640x360, 32 spp, backlit horizon): **17.3 to 17.9 s
against 9.5 to 9.7 s, 1.8x.** The frame ratio is above the density ratio, which says
the lumpier cloud also scatters more.

Measured and rejected:

- **A cheap Lipschitz pre-test** before the gradient: 1.7x WORSE. The only sound slope
  bound is loose, so most points fail it and pay the lattice twice.
- **`[noinline]` on the shell, the billow or the density:** no fewer registers. A CUDA
  kernel's count covers everything it calls. The main kernel is at 226 to 232 registers
  against 162. An experiment showed the growth is a threshold effect of total inlined
  size: either library's changes alone passed 220, and both reverted gave 166.
- **Occupancy:** with 16x16 blocks, 162 and 232 registers both fit one block per SM, so
  occupancy never changed. `__launch_bounds__(256, 2)` gave 17.1 to 17.5 s, within
  noise. Reverted.
- **Stopping the octaves once the answer is known** (exact, and verified by an identical
  cloud fraction): no gain. A warp runs the billow if any of its points needs it.
- **Narrower wall billows** (side fraction 0.35 against 0.6): 17.8 s against 17.9.

### The offsets

**Render Distance** (Camera group, default 40 km, 0 unlimited): the medium fades over
the last quarter of the radius around the eye, and the ray range is clipped to it. It is
a factor at most one, so every majorant still holds. Same frame: **17.3 s unlimited,
14.2 s at 40 km, 8.2 s at 20 km.** At 40 km little changes beyond the far clutter at the
horizon; at 20 km the low cirrus fades visibly.

**The layer's Draft switch** (`in_data->quality == PF_Quality_LO`) caps samples at 1 and
bounces at 16, so the Samples slider keeps the final render's value. Bounces were
measured first and are not where the time is: 32 to 16 is 1% darker for about 10% less
time, and 8 is 3% darker for 28% less.

### Tests

26 of 26 pass. New: the camera's axes, signs, zero travel and ground floor; the observer
and render distance in the sampling hash; Draft's caps; the hero's height, lid, alone,
billow scale and placement; hero with the field and hero alone in slang.convection's
bound sweep (0 violations in 6,000 boxes). The flat base holds at 97.4% (gate 90%).

**A REGRESSION, RECORDED RATHER THAN HIDDEN:** the box bound is still sound, but it now
proves 0.0% of shipping-sized boxes empty against 82.2% found empty by sampling. Proving
a box clear needs the slope, and the sound slope bound is loose. That gate is now a
printed note, with the reason in the test. The optional grid it served was already
off, measured a loss in build 14, and nothing that ships consults it.

### What needs the host

- **The `camera pos` log line** with a new default camera, against the numbers above.
  That settles comp space against layer space.
- **A dolly towards the point of interest** walks towards a hero at 0, 0.
- **The reference shot, verified in the CLI with AE's 50 mm lens:** Inversion 7000,
  Instability 0.9, Hero Cloud Alone, Width 4000, Height 0.7, Camera Travel 5, camera
  tilted about 15° up, Sun Elevation 45 with Sun Azimuth 0 (behind a default camera),
  Exposure -1.
- **Draft on the layer** should make slider drags feel like Samples 1 did.
- **The field's new walls:** is the lumpier default field still the look that was
  reported good?

---

## 2026-09-29 — THE SECOND GENERATOR AND THE SECOND LAYER. Cumulus from cellular convection, with cell polarity, a flat base at the condensation level, and a cirrus deck that shadows it because it is in the same medium. Two firefly sources found and removed on the way, and a majorant grid that was proved correct and then measured to be a loss.

### What was built

**`ConvectionLib.slang`: the density.** A jittered lattice of convective cells, each with
its own vigour and its own point in a birth-to-death cycle (`27/4 u (1-u)^2`, a polynomial
because a sine is a cross-platform hazard). Two updraft fields from the same kernels:
**closed** is the largest kernel minus the second (air rising in the centres, a power
diagram); **open** is the second-largest kernel (air rising where two cells meet).
Polarity blends them. Where the updraft beats a moisture threshold a column stands on
the base and rises under the inversion; billows displace its top and sides.

**The base is not a parameter.** It is the lifting condensation level from surface
temperature and humidity (`condensationLevel()`: 125 m per kelvin of dew-point
depression on Earth, scaling as 1/g). Air too dry to saturate under the lid has no
cumulus, and nobody wrote that rule.

**Two layers, exactly.** `Scene` gains a second medium. Shadows multiply the layers'
transmittances; free flight takes the nearer of the two layers' collisions (the
minimum of independent exponential races, which is exact); a scattering event uses its
own layer's phase function and albedo. The camera-segment sun merges the two layers'
tentative-collision walks in distance order: the same Mecke argument, and the weights
still telescope. **With one layer every scene function does exactly the old
arithmetic: all three goldens stay byte-identical on CPU and GPU.**

### Two firefly sources, each measured

1. **The droplets' diffraction lobe.** At 20 µm, Jendersie-d'Eon's HG term has g = 0.995
   and carries half the scattering, peaking near 4e4 sr⁻¹. A multiply-scattered path
   whose direction happens to lie within a degree of the sun returns a spike.
   **Delta-Eddington truncation** (`truncateDiffraction()`): f = g² of that lobe is
   treated as unscattered, the extinction drops by it, and the rest becomes HG at
   g/(1+g), which preserves the asymmetry exactly. The camera ray's single scattering adds
   the true lobe back (`phaseCamera`), at zero variance because the angle is fixed along
   the ray, so the silver lining survives.
2. **Draine sampled from an HG envelope.** Alpha is 27 at 20 µm, so the old weight
   (1 + a cos²)/norm ran 0.06 to 1.7 and compounded over thirty bounces. Now sampled
   **exactly by rejection** (1.7 tries on average); every weight is exactly one.

A broad-phase control made the diagnosis: swapping the ice placeholder in cleared the
first render. What noise remains is ordinary multiple-scattering variance: about 1.6
relative std per sample, measured, and the same order with the broad phase. That is
the denoiser's job.

### Measured in slang.convection

| check | result |
| --- | --- |
| bound against density, 15,000 boxes, 5 fields | **0 violations** |
| cloud 60 m up that reaches 0.5 m above the base | 100% (the base is flat) |
| cloud below the base or above the lid | 0 |
| open cells, updraft at centres / rims | 0.086 / 0.252 |
| closed cells, updraft at centres / rims | 0.450 / 0.093 |
| 3x3 window against 5x5, 300k points | identical to the bit |
| billow mean | +0.005 (re-centred from +0.20) |

Coverage 0.2 / 0.6 / 1.0 gives 3.4% / 12.7% / 45% of the sky at open polarity; the rest
is the holes open cells have.

### The majorant grid: correct, and a loss

A procedural grid (`MajorantGrid.enabled = 2`) bounds each box from the generator's
structure on the fly, since the layer is infinite. It is sound, and grid on/off agree to
noise. But it is **slower in every scene that has clouds** (640x360, 32 spp):

| | grid | none |
| --- | --- | --- |
| empty layer | 0.42 s | 1.10 s |
| sparse field | 5.86 s | 3.56 s |
| dense field | 6.62 s | 4.48 s |
| looking up | 1.90 s | 1.42 s |

A ray near clouds meets one within a kilometre or two, and each box crossed costs about
what its null collisions would have. Lattice-aligned boxes, taller boxes, and the grid
for camera rays only were each measured; none changed the verdict. **Off by default**;
`--conv-grid 1` for A/B. `kTrackCap` went to 4096 so a grazing ray through the layer
cannot truncate.

### Cost

Cumulus is expensive: about 0.6 µs per pixel-sample in a cloudy view against 0.028 for
cirrus, so 1080p at 1 spp is roughly 1.3 s. It needs 32 bounces: 16 captures 89% of the
light, 32 captures 98.5%. Divergence is part of it (sky pixels idle while cloud paths
take hundreds of steps), with 128 registers per thread and a 728-byte stack frame.

### State

Build 14, minor 6: a Cumulus group inserted between Ice and Physics (on by default,
matching the spec's two-layer default preset), and the ice group's reserved spare is
now its on/off switch. 26 ctest suites, including the new slang.convection.

### What needs the host

- **The look.** Default AE scene: cumulus under cirrus. Is it cumulus?
- **Cell Polarity** from 0 to 1: scattered cumulus to a stratocumulus deck.
- **Surface Humidity** in Physics moves the base; below about 0.25 the cumulus goes.
- **Whether Draft is still usable** at ~1.3 s a 1080p sample.

---

## 2026-09-29 — Build 13 reported good in the host. REPORTED, not measured, like build 7.

The report was that the build looks good. No log and no frame times came back, so this
entry weighs less than the ones with numbers in them.

| | status |
| --- | --- |
| The picture reads right with the new estimator | **Settled.** A person is the right judge of that |
| A moving 48-frame render is calm enough | Consistent with "looks good". It was not reported as watched in motion |
| Draft still feels interactive at 2.2x per sample | Not reported either way |
| Denoise Amount 0.8 against 0.9 | **Left at 0.8.** Nothing in the report asked for a change |

---

## 2026-09-29 — THE SUN ALONG THE CAMERA RAY IS ESTIMATED, NOT GAMBLED ON. At 1 spp denoised: flicker down 42%, RMSE down 42%, fine detail from 53% of the truth to 78%, for 2.2x the time per sample. The dots were the estimator's coin toss, as the entry below predicted. Getting there took a 6x-too-slow first version, a flicker regression from sharing one random stream, and a field name that moved.

### What it is

`cameraSegmentSun` in `BounceLib.slang`. Delta tracking brings the sun back to a
camera ray only if the ray has a real collision, a yes-or-no with probability `1 - T`.
In thin cirrus that is small, so a 4 spp frame is sky with bright dots.

The replacement walks tentative collisions along the whole camera segment at the
majorant rate and forms, by ratio tracking, a **continuous** estimate `B` of how likely
the ray is to scatter. It then asks for the sun from one point `J` resampled along the
ray. The estimate is `B · albedo · phase · sun(x_J) · shadow(x_J)`. The first real
collision's own next event is skipped, since this replaces it. Everything after that
(the continued path, later events, escapes) is unchanged.

**Why it is unbiased.** A next event at every tentative point, weighted by `σ/μ` and
the ratio-tracked transmittance of the points before it, has expectation
`∫ σ T f dt` by the Mecke formula. That is exactly what delta tracking's single next
event estimates. The weights `b_k = T_k σ_k/μ` telescope (`b_k = T_k − T_{k+1}`), so
their sum `B` is the ratio-tracked `1 − T`. Resampling one point with probability
`b_J/B` by a streaming reservoir keeps the expectation.

### Three things that went wrong on the way, each measured

**1. One shadow ray per point was 6x the frame time (15x at scale 4).** Cirrus is ice
almost everywhere inside its slab, so nearly every tentative point paid for a shadow
ray. The telescoping above is what made one shadow ray enough: 2.2x.

**2. It made the flicker WORSE until the random streams were split.** The walk skips
empty air, so its draw count depends on the medium. On the path's own stream, every
later draw shifted whenever the cloud moved, and noise that had been still in screen
space began to crawl. The walk now draws from `splitRng(rng, salt)`, three draws per
step whether it uses them or not, so step k's point sits in the same place every
frame and the rest of the path draws exactly what it drew before.

**3. `SkyInput.transmittance` became `transmittance_1`.** It shared its name with the
function `transmittance()`, and it had been `_0` only because of emission order. The
new code moved the function ahead, and the host binding stopped compiling. Renamed to
`transmittanceLut`, the fix SlangCheckFieldNames.cmake prescribes, and the third
instance of this hazard in the project.

**Also: a scale below 1 is refused.** Under the majorant, `σ/rate` can exceed 1 and the
`max(0, 1 − w)` clamp biases the estimate dark. A scale-0.5 row was measured before the
clamp existed and looked plausible, which is the problem.

### Proved

In `slang.bounce`, held to everything the original estimator is held to:

- the single-scatter closed form at three angles and two rates, all within 0.37%;
- the majorant sweep (1x to 20x) without moving;
- a real droplet phase (+0.08%);
- the furnace identity, exact to 0;
- a full lit, absorbing, multiple-scattering path agreeing with delta tracking to
  0.19 standard errors.

**The variance control is in the regime the estimator is for:** optical depth 0.1 under
a 50x majorant. There the per-path spread is **7.3x lower (53x in variance)**, and the
test fails below 3x. In the thick test slab (τ 2.5) the ratio is about 1. Nearly every
ray scatters there, so the coin toss was never the noise; that ratio is printed and
not asserted, with the reason beside it.

**The goldens were re-blessed on evidence.** Rendered at 8192 spp by both estimators,
the three scenes agree to a signed mean of −0.002, +0.003 and −0.0006 levels. 8x8
blocks agree within half a level, and the worst single pixels differ in both
directions. That is noise, not bias. All 25 ctest suites then pass, including the CUDA
goldens against the CPU references and every determinism check.

### Measured in the image

The shimmer scene (`-w 240 -h 135 --pitch 12`, 8 frames 0.5 s apart). **Flicker is now
measured against a per-frame 4096-spp truth**, as the mean change of the ERROR between
frames. The old frame-to-frame metric counted the cloud's real motion (0.117 in the
truth) as shimmer, and would have scored an image that finally shows a moving cloud as
flickering more than one showing static dots.

| 1 spp, denoised 1.0 | flicker | RMSE | fine detail vs truth |
| --- | --- | --- | --- |
| delta tracking | 0.474 | 8.25 | 53% |
| delta tracking, 3 spp (more time) | 0.435 | 5.81 | 62% |
| **continuous, scale 1** | **0.276** | **4.78** | **78%** |

| 4 spp, denoised 1.0 | flicker | RMSE | fine detail vs truth |
| --- | --- | --- | --- |
| delta tracking | 0.432 | 5.32 | 66% |
| delta tracking, 8 spp (≈ same time) | 0.381 | 4.40 | 71% |
| **continuous, scale 1** | **0.267** | **3.40** | **84%** |
| continuous, scale 4 | 0.261 | 3.20 | 83% |

Raw 4 spp RMSE falls from 17.5 to 8.0; delta tracking at 16 spp reaches only 11.9.
**Scale 1 ships**: scale 2 buys about 5% for 15% more time, and scale 4 about 6% for
40% more.

### Cost

Back to back, same binary, least-squares over 1–32 spp at the CLI default scene:
**27.6 ns per pixel-sample against 12.7**, so 1080p at 1 spp is 57 ms of kernel
against 26. PLAN.md carries the table. **The old estimator's 12.7 ns is itself below
the 20.7 recorded when throughput was first measured**, by the same method with the
same 0.2 s intercept. That gap is unexplained; the ratio does not depend on it.

A cheaper version is possible and deliberately not built yet. At scale 1 the delta
free flight and this walk draw from the same process and could share their points,
which would save most of one walk's density evaluations. It re-couples two streams
that item 2 above separated, so it wants its own flicker measurement.

### Denoise Amount's default is now off by the criterion that chose it

0.8 was fitted to "fine detail closest to the truth" when a full denoise kept only a
third of it. With this estimator a full denoise keeps 78–84%, and the same criterion
lands near **0.9**:

| scale 1, denoised | 0.8 | 0.9 | 1.0 |
| --- | --- | --- | --- |
| 1 spp detail / flicker | 121% / 0.268 | **97%** / 0.271 | 78% / 0.276 |
| 4 spp detail / flicker | 107% / 0.255 | **95%** / 0.261 | 84% / 0.267 |

**Not changed.** It is a judgement about pictures, it needs PARAMS_SETUP to re-run, and
the host is where to make it.

### State

Build 13, minor 5 (no parameter or flag changed). 146 unit tests, 25 ctest suites.
`--nee-scale 0` keeps the old estimator reachable from the CLI for A/B.

### What needs the host

- **A moving 48-frame render, watched for shimmer.** PLAN.md's standing rule. The
  numbers above say it should be markedly calmer; only a moving render says whether it
  is calm enough.
- **Whether Draft still feels interactive** at 2.2x the per-sample cost, about 97 ms
  at 1080p 1 spp with the denoise.
- **Denoise Amount 0.8 against 0.9** on the new picture.

---

## 2026-09-29 — BLUE-NOISE OFFSETS DO NOTHING FOR THIS RENDERER, MEASURED AND REVERTED. PLAN.md's first flicker mitigation was built through the shipping path, swept from 0 to 16 blue-noise draws, and left every metric within noise; a sanity render proves the wiring was right and names why it cannot work under delta tracking.

### Why this was next

The previous shimmer entry ranked blue-noise offsets first: PLAN.md lists them first,
and the sampler's frame stability is what already makes the raw image the temporally
stable one. So that was the thing to try.

### First, the harness could not see the denoiser

`mistytunec --denoise` quietly did nothing. `denoiseCpu` returns false and leaves the
image alone when OIDN is not beside the binary, which is correct for the effect, and
the CLI never said so. **The first "denoised" sweep of this session was byte-identical
to the raw one.** It was caught only because four rows agreed to the last digit. The
CLI now prints `denoise: <denoiserDescription()>` whenever a denoise was asked for,
either `OpenImageDenoise loaded from ...` or the paths it tried. Run from a build
tree, set `MISTYTUNE_OIDN_DIR=<repo>\tools\oidn\bin`.

### The baseline, re-measured and with its command line this time

The previous entry's figures (0.227 raw / 0.453 denoised) did not record their camera.
Re-measured:

    mistytunec -w 240 -h 135 -s 4 --pitch 12 --time <0, 0.5 .. 3.5> [--denoise-amount a]

| | raw shimmer | denoised (1.0) shimmer |
| --- | --- | --- |
| `--pitch 0` (CLI default) | 0.113 | 0.185 |
| `--pitch 12` (effect default) | **0.198** | **0.371** |

Pitch 12 reproduces the recorded ratio (the denoiser roughly doubles the shimmer), so
everything below uses it. The truth is 2048 spp.

### What the noise actually is

A 4 spp frame of this cirrus is **sparse bright dots on a clean sky**. Most camera rays
pass through the thin medium without a real collision; a few scatter and bring back the
forward-peaked sun. The pixel's value is dominated by that yes-or-no decision.

### What was built

The textbook version (Georgiev & Fajardo 2016), end to end through the shipping kernel
on both backends:

- A 64x64 void-and-cluster tile per sampled dimension, generated offline into a header.
  Checked properly blue: below a quarter of Nyquist, each channel's power is under 0.2%
  of its high-band power. Thresholded at 25%, the pattern a one-in-four event makes, it
  is still blue. Cross-channel correlation is under 0.04.
- Each pixel's samples walk away from its blue-noise offsets along Roberts' R2 (jitter)
  and R16 (transport), in 32-bit fixed point, keyed to the frame pixel and the sample
  index. No time input, so a pixel draws the same numbers every frame.
- An optional prefix on `Rng.slang`, so the first N `randFloat` calls of a path return
  the given values before PCG takes over.
- An A/B knob. **`--blue-dims -1` reproduced all three goldens byte-identically on the
  CPU and on CUDA**, so the comparison below is the same binary with one variable changed.

### Measured: nothing

8 frames, 4 spp. "Blueness" is error power in the band 0.125–0.375 of Nyquist over the
band 0.625–1.0 (white is about 1, blue well below 1). The band below 0.125 is skipped
because it holds the display-space bias of a noisy mean, which is not noise.

| blue-noise draws | raw shimmer | raw blueness | raw RMSE | denoised shimmer | denoised RMSE |
| --- | --- | --- | --- | --- | --- |
| white (before) | 0.198 | 1.38 | 17.49 | 0.371 | 5.30 |
| 0 (jitter only) | 0.178 | 1.43 | 17.29 | 0.334 | 5.32 |
| 4 | 0.191 | 1.36 | 17.35 | 0.378 | 5.46 |
| 8 | 0.187 | 1.27 | 17.37 | 0.374 | 5.44 |
| 16 | 0.189 | 1.37 | 17.29 | 0.368 | 5.41 |

**The error stays white at every prefix length.** The shimmer moves by less than its own
spread across seeds. To check the one row that looked promising, jitter-only was run
over four field seeds and 16 frames at denoise 1.0:

| seed | white | jitter only | 16 draws |
| --- | --- | --- | --- |
| 0x5eed1ce5 | 0.355 | 0.338 | 0.371 |
| 0x1234567 | 0.359 | 0.348 | 0.383 |
| 0xbadc0de | 0.363 | 0.356 | 0.342 |
| 0x7777 | 0.341 | 0.337 | 0.370 |

Jitter-only is consistently better by about 3%. Sixteen draws are worse on three seeds
of four. Neither comes near the gap between denoised (~0.35) and raw (~0.19).

### The sanity render that says it was wired right, and why it cannot work

A negative result from new code is only worth recording if the code was right. So every
pixel was given THE SAME offsets:

- **16 identical draws:** the upper sky turns into solid blobs, whole regions scattering
  together. The first 16 draws do carry the scatter decision, except on grazing paths
  near the horizon, which still need more.
- **2 identical draws:** still independent-looking dots. The first tentative collision
  alone decides very little.

That is the explanation. With the majorant grid off (SlangBridge.h records ~4.8
tracking steps per camera ray at the shipping majorant, two draws each), **whether a
ray scatters is a joint function of ten or more draws**: an OR over several tentative
collisions, each accepted against the density at a distance set by the draws before it.
Per-dimension blue noise only makes the *additive* part of the error blue. The part that
depends on the draws jointly stays white, and for a thin, sparse medium under delta
tracking that part is nearly all of it. This is the known limit of blue-noise dithering
in high dimensions, and this transport sits squarely inside it.

### Reverted, deliberately

A 3% shimmer gain from jitter-only does not pay for re-blessing every golden and
carrying a tile, a generator and a sampler switch. The kernel is back to the white-noise
sampler, and the generated Slang is byte-identical to before (`slang.regenerates`
passes). What stays is the CLI's denoiser line.

### What this changes about the plan

**The dots are the problem, and they come from the estimator rather than the sampler.**
PLAN.md's remaining mitigations should be judged against that:

- **Aux buffers are weaker here than they look.** The cloud's single-scatter albedo is a
  constant, so an albedo feature is really a coverage map. Rendered by the same
  collide-or-not decision, it would be exactly as dotty as the colour. It only helps if
  it comes from a continuous estimate, such as a ratio-tracked `1 - T` along the camera
  ray, which ratio tracking already provides without a Bernoulli.
- **A continuous primary-ray estimator is the candidate worth measuring next.** Score
  the sun's next event at *every* tentative collision on the camera segment, weighted
  by `sigma/majorant` times the ratio-tracked transmittance up to it. By Campbell's
  theorem that is unbiased for the single-scatter integral, and it replaces the
  yes-or-no that makes the dots with a sum that varies smoothly. Its cost is one shadow
  ray per tentative collision, about five per camera ray here. It is a transport change,
  so it answers to the furnace test and slang.bounce, and it is a hypothesis until
  measured.
- **Raising spp** stays the fallback it always was.

### State

146 unit tests, 25 ctest suites, goldens untouched. Build and minor unchanged; the only
product-side change is a line of CLI output.

---

## 2026-09-29 — THE ACCUMULATOR CACHE IS LIVE: a resolve-only change costs about 10 ms instead of 3.9 s. The last Phase 2 exit criterion, reached by way of a test that first proved it could not fail, and a hash that had the denoiser in the wrong key.

### Why now, when three entries ago it was declined

The 2026-09-28 entry declined to wire the cache for three reasons. All three have since
been answered: there is a real medium now (reason 1); the sampling/resolve key split
landed (reason 2); and the previous entry moved the cache thread_local, which removes the
MFR sharing problem without a lock (reason 3). A frame costs seconds rather than the 20 ms
that made it not worth doing. **It is the last Phase 2 exit criterion.**

What still blocked it was the GPU accumulator's SIZE.

### The GPU accumulator is frame-sized — a pointer offset, not new arithmetic

It was `rowBytes * bandRows`, so each band overwrote the last and nothing survived the
render that made it. It is now `rowBytes * heightPx`, and each band is handed the slice
starting at its first row. **The kernel is unchanged**: `renderPixel` indexes with the
band-local row it already used, and the base pointer does the mapping. Teaching the kernel
a frame-relative row instead would have been the band-as-window arithmetic this project
has shipped wrong three times.

### A test was written, and then shown to be unable to fail

`determinism.gpuBandChunks` renders in bands *and* sample chunks and compares against the
whole frame. It passed. **So the offset was deleted, and it still passed.**

The reason is worth keeping: each band's first chunk RE-INITIALISES the accumulator, so
bands sharing one region still produce the right mean as long as they run in sequence. The
offset only matters when a frame must survive **a second pass** — which is the cache, and
which nothing yet did.

The discriminating test is `--resolve-check` on the GPU, which used to refuse outright
("needs the CPU accumulator"). It now walks the bands a second time with zero new samples,
so band 1 resolves from its own slice or from band 0's. **With the offset deleted, exactly
one test of 25 goes red: `resolve.reproducesTheRenderOnGpuInBands`.** `gpuBandChunks` stays,
with a comment saying what it does and does not cover.

### Denoise was in the sampling key, so the slider re-traced every nudge

`denoise` and `denoiseAmount` were hashed into `samplingHash`, on the reasoning that OIDN
would need auxiliary albedo/normal buffers written while tracing. The integration that
landed uses none — it filters the finished colour, after accumulation. **So every drag of
Denoise Amount threw the frame away and traced it again**, on the one control a user tunes
by eye. Both now live in `resolveHash`, which takes `QualityParams` as well as
`ViewParams`. A test asserts both halves, and says it is supposed to fail if aux buffers
are ever added.

### The rules that keep it failing safe

`sim::AccumulatorCache`, in `src/engine/FieldCache.h`, one per engine, thread_local in the
effect beside the accumulators.

- **Only split renders are cached.** An unsplit render takes the no-accumulator branch and
  leaves the buffer holding another frame. Draft at one chunk never resolves — cheap to
  trace anyway.
- **Invalidate before writing, credit after completing.** A full render invalidates BOTH
  engines' caches before it touches an accumulator. Only a frame finished start to end on
  one engine, not aborted, is credited. A GPU failure mid-frame invalidates both, and a
  resolve that fails over traces the rest in full rather than resolving from the CPU's
  buffer, which holds something else.
- **Exact sample count, both directions.** Resolving 128 samples for a frame asked at 64
  looks harmless and is not: frame noise would depend on the worker's history, and MFR
  would return neighbouring frames at different noise levels.
- **Geometry, because pitch is in no hash.** AE's rowbytes can differ between two renders
  of one frame with every hash matching; a resolve at the old stride shears the picture.
- **`SMART_RENDER_GPU` and device setdown invalidate the GPU cache** — the first writes the
  same device accumulator without crediting, the second takes the device away.

Each `canResolve` condition has its own unit test, because each guards a picture that
renders plausibly and is wrong, and none of them is visible on a still in the host.

### Measured

1920x1080, 64 spp, GPU, four paired runs:

| | min | spread |
| --- | --- | --- |
| trace only | 3.877 s | 0.058 s |
| trace + resolve | 3.883 s | |

Every resolve run is 6–12 ms slower than its paired trace — a consistent signal well under
the 58 ms noise. **About 10 ms, against 3.9 s: roughly 400x** on Exposure, AgX, Denoise and
Denoise Amount. Add ~30 ms of CUDA denoise when that is on.

### State

146 unit tests, 25 ctest suites. Build 12, minor 5.

### What needs the host, and it is specific

- **Whether it hits.** A resolve needs the SAME worker thread to re-render the SAME frame.
  Parked on a frame dragging a slider, that is likely; whether AE actually routes it so is
  unmeasured. The diagnostic line now says `resolved` or `traced` — a `traced` right after
  a slider drag, on a split render, is a miss worth reporting.
- **Nothing here shortens a first render or a camera move.** Those change the sampling key
  and trace, exactly as before. The cache makes the *second* look at a frame cheap.
- **Raising Samples still restarts.** `Accumulate` — continue from 64 to 128 rather than
  start again — is answered by the cache and deliberately not acted on: it needs the chunk
  loop to start mid-frame across a possible engine fallback, and that is its own change.
- **GPU memory per worker went up.** The device accumulator is frame-sized now — 33 MB
  at 1080p — where it was band-sized, and there is one per render thread. Together with
  the per-thread OIDN device recorded two entries ago, that is the thing to watch under a
  multi-frame render.

---

## 2026-09-29 — "TOO SMOOTH" AND "IT SHIMMERS" ARE THE SAME BUG, AND THE FIX IS ONE SLIDER. Both complaints come back from the host; both are measured; and they turn out to move TOGETHER rather than trade against each other, which is the opposite of what was assumed before measuring.

### The two reports

From the host, build 10: the denoised cirrus reads **too smooth**, and it **shimmers**
on a moving render. The second was predicted — PLAN.md says denoiser flicker is judged
on a moving render and never on a still, and the last entry listed it as the open
question. The first was not.

### The CLI could not render a sequence at all

`field.timeSeconds` had no command-line flag, so `mistytunec` rendered every frame at
t=0. **The one thing PLAN.md says flicker must be judged on was the one thing the
harness could not produce.** `--time <sec>` now exists, and everything below is measured
through it.

### Measurement 1: the denoiser DOUBLES the shimmer

Eight frames, 240x135 at 4 spp, half a second apart, mean absolute frame-to-frame
difference per channel:

| | frame-to-frame | temporal Laplacian |
| --- | --- | --- |
| raw | 0.227 | 0.452 |
| denoised | **0.453** | 0.730 |

**The denoised sequence changes twice as much per frame as the raw one.** OIDN is not
temporal: it reconstructs each frame independently, so a small input difference can
produce a large output difference in a smooth region. The raw noise, by contrast, is
nearly FIXED-PATTERN — `hashPixelSample` takes (pixel, sample index, field seed) and no
frame input, so a given pixel draws the same numbers every frame — and a static pattern
barely moves frame to frame.

So the denoiser is not merely failing to fix the shimmer. It is the source of it.

### Measurement 2: the denoiser removes two thirds of the REAL detail

The suspicion that "too smooth" just means "4 spp has no detail to keep" is testable:
render the same frame at 512 spp and ask how much fine structure the truth has. Mean
neighbouring-pixel difference:

| | | |
| --- | --- | --- |
| 512 spp (truth) | 2.364 | 100% |
| 4 spp, raw | 9.887 | 418% — four times too much; that is the noise |
| 4 spp, amount 0.5 | 4.984 | 211% |
| 4 spp, amount 0.8 | 2.655 | **112%** |
| 4 spp, amount 1.0 | 0.769 | **33%** |

**A full denoise leaves a third of the fine structure a converged render actually has.**
The report was right, and it is not a preference — the filter overshoots on this
content.

**RMSE DISAGREES, AND THAT IS WHY THIS IS A SLIDER AND NOT A CONSTANT.** Against the
same 512-spp reference, RMSE is minimised at amount **0.95** (9.669, against 9.751 at
1.0 and 25.985 raw). RMSE rewards blur: a smooth wrong image beats a noisy right one.
The two criteria genuinely point at different numbers, so the choice belongs to whoever
is looking at the picture. The default follows the structure measurement, because that
is the one that corresponds to what was complained about.

### The two complaints are the same dial, and they do not trade

This was the finding worth the whole exercise. The assumption going in — written down
before measuring — was that blending raw noise back would restore detail at the cost of
MORE shimmer, because noise is what shimmers. **It is the other way round.** The raw
noise is nearly static, so keeping some of it is temporally cheap, while the denoised
image is the unstable one:

| amount | shimmer | fine structure |
| --- | --- | --- |
| 0.00 | 0.227 | 418% of truth |
| 0.50 | 0.338 | 211% |
| 0.80 | 0.395 | 112% |
| 1.00 | 0.453 | 33% |

Detail and stability move together. There is no trade to warn anyone about: turning the
amount down helps both complaints at once, and the only thing it costs is noise.

### What was built

**`QualityParams::denoiseAmount`, default 0.8**, hashed beside the switch it scales.
OIDN's RT filter has no strength of its own, so it is a lerp between the raw render and
the filtered one — **in linear, before the output transform**, which is the only place
it can be correct. Blending after the transfer curve would mix two differently encoded
images.

**THE BLEND NEEDS NO SECOND BUFFER.** At the unpack the destination still holds the
original radiance — the pack read from it and the filter worked in its own buffer — so
the raw value is already under the write.

**A RESERVED SPARE BECAME THE CONTROL.** `QualitySpare1` was id 304 and is now Denoise
Amount at id 304. No index moved, no saved project is rewired, and it sits beside the
switch it scales rather than after the Output group. **That is the entire reason the
spares exist**, and this is the first time one has been spent.

Minor 4 -> 5, build 11: `PARAMS_SETUP` only re-runs after a version change, so without
the bump the slider would not appear at all.

### Proved

Three new tests on top of the ten from the last entry. The endpoints are what a test can
pin — whether 0.8 is the right default is a judgement about pictures, but **0 being the
identity and 0.5 landing exactly at the midpoint of raw and fully denoised is
arithmetic**, and it is the arithmetic that would break silently. Amount 0 also returns
false and skips the filter entirely rather than running it and discarding the result.

**THE DEFAULT WAS RE-MEASURED THROUGH THE SHIPPING PATH BEFORE IT WAS FIXED.** The first
sweep lerped 8-bit output and predicted 100% of truth at 0.8; the real blend, in linear,
gives 112%. Close enough to keep 0.8, and a reminder that a simulation of the pipeline
is not the pipeline.

138 unit tests, 23 ctest suites, goldens untouched -- the CLI still defaults to no
denoise, so tier 2 remains independent of whether `tools/oidn/` exists.

### Still open

- **THE SHIMMER IS REDUCED, NOT SOLVED.** At 0.8 it is 0.395 against 0.453 -- about 13%
  better, and still worse than raw. The real fixes are PLAN.md's remaining mitigations,
  and the measurements above reorder them: **blue-noise offsets** are now clearly the
  next one, because the sampler's frame-stability is exactly what makes the raw image
  the temporally stable one, and blue noise would make that stability perceptually
  cheaper. Aux buffers come after.
- **AUXILIARY ALBEDO AND NORMAL BUFFERS** would let the filter keep detail without
  giving noise back, which is the only way to beat the trade rather than move along it.
  Kernel work: the renderer would have to emit them, and what "albedo" and "normal" mean
  for a volume needs deciding.
- **WHETHER 0.8 IS RIGHT AT OTHER SAMPLE COUNTS IS UNMEASURED.** It was fitted at 4 spp.
  At 32 spp the raw image is far less noisy and the same amount will keep more real
  detail and more real noise; the right default may well be sample-count dependent,
  which would make it a curve rather than a constant.

---

## 2026-09-29 — THE DENOISE CHECKBOX DOES SOMETHING. Third instance in three sessions of a control wired everywhere except the one place that makes it real; plus a measurement that settled two comments arguing with each other, and made the fix simpler rather than harder.

### What was wrong, and it is getting familiar

`QualityParams::denoise` was checked out, mapped in `toQuality()`, hashed into the
fingerprint and defaulted **on** — and nothing read it. There was no OIDN code in the
repository and no `cmake/FetchOidn.cmake`. `Mistytune.cpp` said "OIDN goes in
immediately above this line when it lands."

That is the ice parameters, the sky origin, and now this: **three controls in three
sessions that were plumbed, hashed, tested and shipped without the one line that makes
them real.** The shared cause is worth naming — each was finished right up to the seam
where a *different* subsystem had to accept it, and nothing in three test tiers looks
at a seam.

This one was the most visible of the three. At 1 spp Draft a path-traced cirrus is
noise; the denoiser is what makes the preview usable at all.

### What was built

**`cmake/FetchOidn.cmake`** on the `tools/slang/` pattern: version and SHA256 pinned,
gitignored destination, the repo carrying the instructions rather than 53 MB of
binaries. It prunes the devices we do not ship — HIP, SYCL and its runtime, the three
tools — and reports the remaining size. **52 MiB, which is exactly the figure recorded
on 2026-09-28 as "verified to load and denoise."** The keep set was confirmed by
arithmetic against that measurement before a line of it was written.

**`src/engine/Denoiser.{h,cpp}`** — loaded with `LoadLibraryEx`/`GetProcAddress`, ten
functions declared as a local ABI. **Nothing is linked.** There is no
`OpenImageDenoise.lib` on any link line and no import-table entry, because a load-time
import of a missing DLL is a plugin After Effects refuses to load AT ALL, with an error
naming the effect and not the file — a failure indistinguishable from "Mistytune is
broken". `LOAD_WITH_ALTERED_SEARCH_PATH` is load-bearing: the shim depends on
`OpenImageDenoise_core.dll`, and without it the loader looks beside `AfterFX.exe`.

**The buffer path, not the shared-pointer path.** `oidnSetSharedFilterImage` needs
memory the *device* can read, and our destination is host memory — on a CUDA device a
plain host pointer is not device-accessible. `oidnNewBuffer`/`write`/`read` works for
every device type, so there is one code path rather than one per device. The pack it
requires also solves channel order for free: OIDN's FLOAT3 reads three CONSECUTIVE
floats, ARGB happens to store R,G,B that way and **BGRA stores them reversed**, which no
stride expresses. AE hands out BGRA worlds, so that is the host path.

**`kernel::denoiseCpu()`** beside `transformCpu()`, honouring the checkbox in one place
so a fourth call site cannot be written without it.

### The measurement that made it simpler

Two comments in this repository disagreed. `FieldCache.h` fixed the resolve as
`mean -> exposure -> DENOISE -> tonemap -> encode`, arguing OIDN is trained on
perceptual magnitudes so "denoise strength silently tracks the exposure slider"
otherwise. `Shading.h`, `KernelApi.h` and `Mistytune.cpp` all said the shorter
`render (LINEAR) -> denoise -> output transform`.

The difference was a whole extra full-frame pass — exposure lifted out of the transform,
about 5 ms a frame at 1080p.

**MEASURED: the same image denoised three stops apart agrees to 0.42% once the gain is
divided out.** OIDN 2.x normalises its own input. The premise was false for this
version, the transform stays one pass, and the three shorter comments were right. The
test is kept, because it is the thing that will say so if a future OIDN stops
auto-exposing.

What has NOT changed is the constraint that actually matters: **scale invariance is not
curve invariance.** A tonemapped or encoded buffer is still wrong to hand over, and AgX
is not a gain.

### Proved

**Ten unit tests, and the ones that matter most run with no OIDN installed** — the
refusal paths. A missing DLL, a pruned install folder, an antivirus quarantine: all of
them land there, and it is the path no developer machine exercises by accident, so it is
the one that rots. Bundling makes it rarer, not unnecessary.

The strongest of the rest is an **equivalence**: the same colours laid out ARGB and BGRA
must come back bit-identical. A channel-order bug would still smooth the image — it
would denoise using the colour statistics of a differently-coloured picture, look almost
right, and say nothing about channel order.

**End to end through the CLI, 320x180 at 2 spp:** neighbour-difference energy falls from
4.190 to 0.418 levels — **90%**.

**A measured property of the filter, recorded rather than tolerated.** RT does not
reproduce a flat field exactly at image CORNERS: on flat 0.25/0.50/0.75, 35 of 960
pixels off by >0.02 at 40x24 (worst 0.135), and 15 of 15360 at 160x96 (worst 0.095). A
fixed band rather than a fraction — the count barely moved while the area grew sixteen
times — so it vanishes on a real frame. A wiring error would have scaled with the image
instead. The test asserts the interior and leaves the border to those numbers.

### The CLI does NOT denoise by default, and that is deliberate

`mistytunec` renders the golden references and every determinism tripwire. Denoising
there would have broken two things:

- **Tier 2 would depend on whether `tools/oidn/` exists.** A machine that had fetched
  OIDN and one that had not would bless different references. The whole arrangement is
  built so a machine with neither Slang nor OIDN builds and tests identically.
- **`determinism.window` could never pass.** It renders a sub-rect and requires it to
  equal that region of the whole frame. A denoiser is SPATIAL — the same pixel denoised
  with a window's neighbours and with the frame's is legitimately different. It would
  have failed for a correct reason, which is the worst kind of failing test.

So `--denoise` is opt-in there and on by default in the effect. 23 ctest suites and 135
unit tests green, goldens untouched.

### State, and what is NOT done

Build 10, minor unchanged at 4. `build.ps1 -Install` and `-Package` copy the DLLs beside
the `.aex` — which is where `Denoiser.cpp` looks, since it resolves its own module's
directory and not the EXE's.

- **NO HOST HAS SEEN THIS.** Whether it denoises correctly in After Effects, what it
  costs there, and **whether it flickers** are all untested. OIDN is not temporal, and
  per-frame denoising of a stochastic image is how animation gets shimmer. PLAN.md is
  explicit that this is judged on a moving 48-frame render and never on a still. No unit
  test substitutes for that.
- **ALBEDO AND NORMAL AUXILIARY BUFFERS ARE NOT WIRED.** They are PLAN.md's second
  flicker mitigation after stable blue-noise offsets, and they are kernel work: the
  renderer would have to emit them. Deliberately left until there is a flicker
  measurement to justify the cost.
- **THE `PF_Cmd_SMART_RENDER_GPU` PATH DOES NOT DENOISE.** Its destination is a device
  pointer AE owns, and the host denoiser cannot reach it without a round trip. AE does
  not currently take that path — PROGRESS records it refusing the GPU command — so it
  is a gap rather than a live bug.
- **ONE OIDN DEVICE PER RENDER THREAD.** The session is `thread_local`, matching the
  accumulator and the transmittance table, because an OIDN filter is not safe to execute
  from two threads and a lock would serialise the denoise across every MFR worker. A
  CUDA device is not small, so eight workers means eight contexts. **That is the first
  thing to watch under a multi-frame render** and it is recorded here rather than
  discovered.

---

## 2026-09-29 — THE SKY WAS ASKED FROM THE WRONG PLACE. Every escaped path got the sky as seen from two metres, including one leaving a crystal at nine kilometres; the fix is one argument, and the sunset golden moved the OPPOSITE way from the other two, which is the measurement that says it is right.

### What was wrong

`skyRadiance()` took the origin's altitude as a literal `2.0`. That was correct for
exactly as long as the function had one caller — a camera ray from an observer standing
on the ground. The bounce loop then began calling it through `environmentRadiance()`
for **escaped paths**, and `environmentRadiance` took a direction and no position. So a
path that scattered inside a cirrus at 9 km and left the medium was told what the sky
looks like **from two metres above the sea**.

**THE ERROR IS SYSTEMATIC, NOT NOISE.** It integrates nine kilometres of air that is not
between the crystal and space, at every bounce of every path. Skylight is the whole
illumination of a cloud that is not direct sun, so it is not a corner case.

**proto/index.html HAS ALWAYS PASSED `ro`** — `skyRadiance(ro, rd, 1e9, neverScattered)`,
with `ro` updated to the scatter point each bounce. The prototype is what passed the
Phase 0 look verdict and is the reference this port is checked against. This is the
transcription catching up with it, not a new idea.

**NOTHING RECORDED IT AS A DECISION.** No comment argued for the constant and no
PROGRESS entry mentions it. It is a Phase 1 value that silently changed meaning when
Phase 2 gave the function a second caller — the same shape as the ice parameters two
entries ago: not a thing that broke, a thing that was never connected.

### The fix, and what it does not do

`skyRadiance(SkyInput, float originAltitude, float3 rayDir, bool)` on both sides, and
`environmentRadiance(Environment, float3 origin, float3 dir, bool)` passing `origin.y`.
The bounce loop hands it `ro`: the camera at bounce 0, the last scattering point after.

**ONLY THE ALTITUDE REACHES THE MARCH, and that is sound rather than a shortcut.** The
atmosphere is spherically symmetric, so the integral depends on the origin only through
its height and the ray's angle to the local vertical. The local-frame assumption that
makes `b` one multiply instead of a dot product is untouched.

**FLOORED AT THE GROUND.** An escaped path's origin is a point in the medium and nothing
stops a slab configured below sea level. A negative altitude puts the origin inside the
planet, where `shellEnter()` returns a root behind the ray and the march runs backwards.

**`ViewParams::observerAltitude` IS NOW HONOURED TOO**, incidentally: the camera ray's
`ro.y` is that field, where the sky previously pinned 2.0 regardless. It has no control
in the panel and no CLI flag, so it is still always 2.0 in practice — the parameter was
simply being ignored as well as the escape point.

### Proved, not assumed

**`slang.skyParity` NOW SWEEPS ALTITUDE and still passes bitwise.** The test dispatched
at one altitude, which after this change would have compared the two files only where
they agreed by construction and stayed green through a transcription error in the new
argument on either side. It runs at −500, 0, 2, 6400, 9000 and 30000 m — the ground, the
observer, the streak bottom, the generating level, the stratosphere, and a negative that
must clamp. 14,449 directions at each: 0 differing channels of 260,082.

**THE CONTROL IS IN THE DATA.** A path that never scatters calls the function with the
camera's 2.0, which is the old constant, so those pixels must be bit-identical. Measured:
the sunset scene's rows 31–71 — the part of the frame with no cloud in it — differ by
exactly zero. Where the cloud is not, nothing moved.

### The goldens moved, and the DIRECTION is the finding

| scene | max | mean | signed mean | darker | brighter | identical |
| --- | --- | --- | --- | --- | --- | --- |
| midday | 14 | 0.78 | −0.51 | 36.8% | 5.5% | 57.7% |
| sunset | 32 | 0.28 | **+0.26** | 0.6% | **6.1%** | 93.2% |
| horizon | 48 | 1.48 | −0.62 | 75.9% | 11.0% | 13.1% |

Midday and horizon go **darker**: less air above a crystal at 9 km than above the ground,
so less in-scattered skylight reaches it. Predicted before measuring, and confirmed.

**SUNSET GOES BRIGHTER, AND THAT IS WHY THIS IS RIGHT RATHER THAN WHY IT IS WRONG.** At
a sun elevation of 2° the geometric horizon seen from 9 km is depressed about 3°, so the
sun sits roughly 5° above the crystal's own horizon while the ground is nearly in shadow.
The sky a high crystal sees at sunset is genuinely brighter than the sky from below it.
That is the alpenglow case, and it is the reason a high cirrus still burns after the
ground has gone flat — which is the default preset PLAN.md asks for, backlit.

A constant could not have produced a sign that depends on sun elevation. Two scenes
moving down and one moving up, each for a reason stated before the number was read, is a
stronger check than three moving the same way would have been.

Magnitudes are dominated by ±1/255 and tail off quickly (midday: 7381 channels at 1,
1731 at 2, 201 at 6), which is the signature of a modest change to what illuminates a
semi-transparent layer rather than a change to the background behind it.

**BLESSED**, on those four grounds: the port is bitwise-identical to the reference across
six altitudes, the change is provably nil where no path scatters and measured nil there,
the direction is correct in all three scenes including the one that disagrees with the
other two, and it moves toward proto/index.html rather than away from it.

### A build hazard found on the way, worth the line

The first build after the edit failed partway and left
`src/kernel/slang/generated/RenderCpu.cpp` holding slangc's raw output: an **absolute
path** to the prelude on this machine, and no banner. It compiles here and nowhere else.
`slang.regenerates` caught it — which is exactly the hole that test was written for —
but the mechanism is worth naming: `add_custom_command` runs slangc and the prelude
rewrite as two COMMANDs, and a build interrupted between them commits the un-rewritten
file. Deleting the generated file and rebuilding restores it.

### State

**23 of 23 ctest suites and 123 unit tests green**, goldens re-blessed and the GPU
comparisons passing against the CPU-blessed references. Build 9, minor unchanged at 4.

### Still not done, and unchanged by this

- **MULTIPLE SCATTERING IN THE AIR IS STILL MISSING** and is the remaining half of "the
  rest of the Bruneton atmosphere". Shading.h has said so since Phase 1: a hazy or
  high-turbidity sky comes out too dark because the light that would have bounced a
  second time is absent, and twilight is worst affected. Neither proto/ nor this kernel
  has ever had it — the prototype's sky march is the same 12-step single-scattering
  integral. That is the second LUT, and it is new work rather than a transcription.
- **AERIAL PERSPECTIVE ON THE CLOUD** — the air between the viewer and the cloud
  attenuating what the cloud sends back, and adding its own airlight in front of it — is
  also still absent. The prototype's claim that it "is already in the result" holds only
  for the sky behind the cloud, not for the cloud itself: `maxDist` exists in its
  signature and every call site passes `1e9`.
- OIDN, the field cache, and Working Space None, all unchanged from the last entry.

---

## 2026-09-29 — THE ICE GENERATOR HAS HAD NO CONTROLS. It was plumbed, hashed, tested and shipped in seven builds without one of its parameters reaching the panel, and nothing in the repo could have said so.

### The finding

`FieldParams::ice` was never assigned in the effect. `preRender` filled `physics`,
`atmosphere` and `quality` and stopped; `field.ice` kept `IceParams`'s defaults. So
every render made in After Effects since build 6 — when the Slang transport first
reached the pixel — was **the same cirrus**: 9000 m, Column habit, density 0.35, that
one shear profile. Correct, and unreachable.

**NOTHING WAS FAILING.** The kernel marches `field.ice` properly, `SlangBridge.h`
carries all of it, `Fingerprint.cpp` hashes all of it, and `deriveRenderInputs()`
builds the drift table from all of it. 123 unit tests and 23 ctest suites pass on it
and always did — `src/cli/` sets its scene directly and never goes through
`src/ae/Params.h`, so no test tier this project has could see the gap. It is visible
only from the panel, and only if you know what should have been in it.

**THE THREE TIERS HAVE A FOURTH EDGE AND IT IS UNTESTED.** Unit tests cover the
engine, goldens cover the kernel, and in-host checks cover the render path. The
mapping from a control to a struct member is in none of them: `Params.h` needs the
Adobe SDK, so it is outside tier 1 by construction, and tiers 2 and 3 both enter
below it. Every parameter this project adds from here passes through code no test
executes.

### What was built

Thirty parameters — twelve scalars, a habit popup, six shear speeds, six shear
bearings, four spares, the group and its end — plus `toIce()`.

**INSERTED BETWEEN SKY AND PHYSICS, NOT APPENDED.** Group order is screen order, so
appending would have put the clouds below Quality and Output. Inserting moves every
index after 13, which rewires saved projects — **free today and never again**, since
nothing has shipped and PLAN.md fixes the layout at the v0.5 hand-out.

**THE SHEAR PROFILE IS TWELVE SLIDERS, WHICH IS PLAN.md's PHASE 2 SHAPE** and not a
compromise reached here: the SDK ships no curve control and no sample of one, so the
editor is an arbitrary-data parameter with custom UI in Phase 4. `ShearProfile` does
not change when it arrives. A `static_assert` on `kShearKnots == 6` in `toIce()` is
the tripwire — raise the constant and the build stops until the sliders exist, the
same bargain `Fingerprint.h` strikes with `sizeof`.

**NO ENABLE CHECKBOX.** `IceParams::enabled` is hashed but no backend reads it: the
`enabled` flags in `TransportLib.slang` belong to the **majorant grid**, not to the
generator. A control that silently does nothing is worse than no control, so the slot
is `IceSpare1` and the checkbox arrives with the code that honours it.

**MINOR 3 → 4, BUILD 7 → 8, AND THE BUMP IS THE FEATURE.** `PARAMS_SETUP` is re-run
only after a version change, so these controls installed at minor 3 would have given
a binary that renders exactly as build 7 and shows not one new slider — a failure
indistinguishable from never having written them.

Valid ranges are as wide as the maths allows, per the rule in `Params.h`, and every
divisor downstream is already guarded: `streakLength` and fall speed are floored in
`IceField.cpp`, `iceMajorant()` clamps the negatives, and `cellSize`'s valid minimum
of 1 m is the guard for the one that is not. Sublimation's valid range **goes
negative on purpose** — that is deposition, and `depthFactorBound()` already takes
the maximum at both ends of each interval precisely because the sign can flip.

### State, and what is NOT verified

123 unit tests and 23 ctest suites green, goldens included — unchanged, as they must
be: the CLI does not read `Params.h`.

**NO HOST HAS SEEN THIS.** Whether AE accepts thirty inserted parameters, whether the
group lands between Sky and Physics on screen, whether the angle dials read back as
bearings, and whether a shear slider visibly changes the streak are all untested and
cannot be tested here. That is the next thing to do and it needs After Effects.

---

## 2026-09-29 — THE FIELD CACHE IS IN THE WRONG PLACE, AND A LOCK IS NOT THE FIX. Found while going to wire it; the planned mitigation would have made a real race deterministic without making it correct.

`SequenceData` has carried a `FieldCache` since Phase 1, with a comment saying it "will
need the lock in Phase 2, when it starts describing a real GPU allocation". Going to
wire it up: **the lock is the wrong answer, and the reason is worth more than the lock
would have been.**

### A CACHE MUST LIVE WHERE THE MEMORY IT DESCRIBES LIVES

Sequence data is **shared** across every render thread AE has in flight for a layer.
The accumulators the cache would describe are **not**: both are `thread_local` --
`g_accum` in `CpuRender.cpp`, and the `DeviceScratch` of the same name in
`Mistytune.cu`.

So a shared cache over per-thread buffers is wrong *with* a mutex:

> Thread A adopts a key and records 32 samples. Thread B asks, is told **Accumulate**,
> and accumulates into **its own empty accumulator** while the cache still claims 32
> samples are in it.

The frame comes out darker or noisier than its neighbours, only under multi-frame
rendering, for no visible reason. A mutex makes that race deterministic. It does not
make it correct.

### WHERE IT BELONGS, AND THE LOCK DISAPPEARS

Beside the accumulator: `thread_local`, in the kernel library. Then nothing is shared
and no lock is needed.

**IT FAILS SAFE BY CONSTRUCTION**, which is the property that matters for something
that cannot be tested outside the host. A thread that has not rendered this key sees an
empty cache and renders from scratch -- which is exactly today's behaviour. The worst
case of a cache miss is a slow frame, never a wrong one. That is a much better place to
be than "correct as long as the lock is held in all four paths".

### WHAT ACTUALLY BLOCKS IT IS THE ACCUMULATOR'S SIZE, NOT ITS LIFETIME

The CPU accumulator is already full-frame and would carry a frame across renders
unchanged. **The CUDA one is BAND-sized** -- `rowBytes * bandRows` in
`renderCudaToHost` -- so each band overwrites the last and there is nothing to carry.

Making it frame-sized means indexing it by the band's offset into the frame. That is
precisely the band-as-window arithmetic this project has got wrong **three times**: the
reduced-resolution render that drew the top-left third of the sky, the Region of
Interest that drew the top-left corner, and the band offset in `renderCudaToHost`
itself. Each one rendered a plausible picture and read as a broken effect rather than as
a units mistake.

**SO IT SHOULD BE WRITTEN WHERE A HOST CAN BE WATCHED**, not blind. The policy
(`FieldCache`, 123 unit tests) and the mechanism (`resolve.reproducesTheRender`) are
both done and tested; what is left is the one part whose failure mode is a picture that
looks fine until you compare it with its neighbours.

The member stays in `SequenceData` for now because nothing reads it. Moving it before
the accumulator question is settled would relocate the problem rather than fix it.

### State

123 unit tests, 23 ctest suites, all green. The only change here is the comment that
said a lock was the plan, which is now the paragraph above.

---

## 2026-09-29 — THE VIEW HASH SPLITS IN TWO, and an exposure change stops costing a re-render. The mechanism turns out to need NO new kernel code, which is the finding; and a comment that was right when written is now the reason for doing the opposite.

PLAN.md's Phase 2 exit has four clauses. Two were done, one was closed by the
measurement in the entry below, and this is the third: *"survives a camera move without
rebuilding the field"*.

### THE OLD COMMENT WAS RIGHT, AND IT IS NOW THE ARGUMENT FOR THE OTHER SIDE

`FieldCache.cpp` carried, at length, the reason exposure had to be hashed with the
samples:

> They could be a post-pass over the accumulated buffer, and then changing them would
> not even restart accumulation. They are not, because the accumulation buffer is
> linear radiance and the denoiser runs on it: OIDN is trained on roughly perceptual
> magnitudes, so the exposure the user chose has to be in the numbers before the
> denoiser sees them.

**THAT ARGUMENT IS STILL TRUE. IT CONSTRAINS THE ORDER INSIDE THE RESOLVE PASS, NOT
WHETHER EXPOSURE IS A SAMPLING INPUT.** The resolve is

    mean -> exposure -> DENOISE -> tonemap -> encode

and every stage of it is cheap next to tracing. The denoiser still sees exposed values;
an exposure change still costs one denoise — about 30 ms on CUDA — rather than 2.97 s of
re-tracing.

What actually kept exposure in the sampling hash was that `applyOutputTransform` ran
**inside** `renderPixel`, so the accumulator held exposed values and there was nothing
linear left to re-expose. Lifting it out removed that, and the entry of 2026-09-28
predicted exactly this: *"store raw radiance and make exposure, denoise and tonemap a
RESOLVE pass over it... That splits `viewHash` into a sampling key and a resolve key."*

### THE SPLIT

`RenderKey.view` becomes `sampling` and `resolve`. The rename is the point: `view` meant
"everything that is not the field", which lumped the camera in with the exposure slider,
and those two cost wildly different amounts to change.

| | contains | changing it costs |
| --- | --- | --- |
| `field` | FieldParams | rebuild the medium |
| `sampling` | camera, size, origin, bounce depth, majorant, denoise | every sample so far |
| `resolve` | exposure, tonemap, encoding | **one resolve pass** |

`Decision` gains `ResolveOnly`, and `adoptResolve()` sits beside `adopt()` — identical
except that it **keeps the sample count**, which is the whole difference.

**THE ORDER INSIDE `decide()` IS LOAD-BEARING AND IS ASSERTED RATHER THAN LEFT TO THE
READING.** A render whose camera *and* exposure both moved must restart, not resolve;
reversing those two tests would re-expose a buffer full of the old camera's pixels,
which is a picture of neither view. `ACameraMoveBeatsAnExposureChange` pins it.

`addSamples` deliberately does **not** check the resolve half: a batch launched before
the slider moved holds exactly the right radiance for the new exposure. Requiring them
to match would throw those samples away and undo the split.

### THE MECHANISM NEEDS NO NEW KERNEL CODE, AND THAT IS THE PART WORTH RECORDING

The obvious next step was a `resolveCpu` / `resolveCuda` pair beside `renderCpu`. It is
not needed. **`renderPixel` with `sampleCount == 0` already IS a resolve**: it adds
nothing to the accumulator, divides it by `samplesAlreadyDone`, and writes the mean. The
transform pass then finishes it.

So the whole ResolveOnly path is two calls the renderer already has, and there is no
second copy of the accumulation arithmetic to keep in step with the first.

**CHECKED RATHER THAN ASSERTED.** `--resolve-check` renders, then regenerates from the
accumulator with zero new samples and demands byte-identical output:

    resolve-check: ok -- 36864 floats identical,
    re-resolved from 24 accumulated samples without tracing

Verified to go red by resolving against `totalSamples - 1`: 27,648 of 36,864 floats
differ. Now `resolve.reproducesTheRender` in ctest.

**BYTE-IDENTICAL IS THE RIGHT BAR, NOT A TOLERANCE.** Both paths divide the same
accumulator by the same integer and run the same transform. A loose bar would admit the
worst failure a cache has — the cached picture differing from the one the same
parameters would render — which appears only after an edit and reads as a rendering bug
rather than a caching one.

The test passes `--sample-chunk` deliberately: without a split, `renderPixel` takes its
no-accumulator branch and there is nothing to resolve *from*, so the test would pass
while exercising none of what it names.

### State

123 unit tests (was 115), 23 ctest suites (was 22), all green.

### WHAT IS STILL NOT WIRED, AND IT IS THE PART THAT NEEDS A HOST

The policy and the mechanism both exist and are tested. **Nothing calls them yet.**

The entry of 2026-09-28 declined to wire the cache for three reasons. Reason 2 — the
sampling/resolve split — is what this entry is. Reason 1 stands in a reduced form: there
is still no *field* to rebuild, because the ice generator is procedural, so what the
cache now saves is the accumulated samples rather than a medium. At 2.97 s for 64 spp
that is worth having, where at the 20 ms frame of the original entry it was not.

**REASON 3 IS UNCHANGED AND IS THE BLOCKER.** A cross-render accumulator is shared
mutable state between frames After Effects has in flight;
`PF_OutFlag2_SUPPORTS_THREADED_RENDERING` is set, and `docs/HOST-NOTES.md` is blunt that
anything shared then needs a lock or needs not to be shared. A single accumulator keyed
on one `RenderKey` would thrash between concurrent frames, so it wants a keyed cache with
an eviction policy and a lock — and none of that can be verified outside the host.

### Next

- **Wire it**, which is where MFR has to be reasoned about properly and then watched in
  AE under a multi-frame render.
- **OIDN**, now decided: bundle the 52.9 MB set. Needs the package fetched to develop
  against; `cmake/FetchOidn.cmake` follows the `tools/slang/` pattern.
- **The rest of the Bruneton atmosphere**, which ends in a look.
- **Working Space None**, one log line.

---

## 2026-09-29 — Build 7 reported fine in the host. Recorded as REPORTED rather than MEASURED, and the difference matters for exactly one line of it.

Build 7 installed into AE 2026 and checked against the three things it changed: the sky
at low sun, the frame time, and the Working Space None colour branch. The report back
was that everything is fine.

**NO LOG WAS CAPTURED HERE, SO THIS ENTRY CARRIES LESS WEIGHT THAN THE ONES ABOVE IT.**
Every other claim in this file has a number behind it. This one has a person saying it
looked right, which is the correct evidence for "does the sky look wrong" and weaker
evidence for the other two.

### What that does and does not settle

| | status |
| --- | --- |
| The sky at low sun looks unchanged | **Settled.** This is a judgement and a person is the right instrument for it |
| The frame got faster | Consistent with the 1.47x A/B, but the host number was not read back |
| **Working Space None gives `encodeSrgb=1`** | **REPORTED, NOT MEASURED** |

The third is the one that matters. Rules 3 and 4 of `encodesSrgbForHost` have still
never been seen firing in a log. The stated assertion was that a Working Space None
project must report `encodeSrgb=1`, and a `0` there would mean
`AEGP_GetNewWorkingSpaceColorProfile` returns a *linear* profile for "None" — which
would darken every default project by one sRGB encode.

"Fine" is consistent with `encodeSrgb=1`, and it is also consistent with the branch not
having been exercised at all. **The log line is still worth capturing the next time
anyone is in the host**, and the diagnostic now prints the profile name beside the
gamma, so one line answers it outright:

    colour raw: ocioErr=0 ocio=0 profileErr=? haveGamma=? gamma=? profile="?"

Left open deliberately rather than written up as closed, because a caveat that gets
quietly upgraded to a fact is how this project has already lost two premises.

---

## 2026-09-29 — 44.7 MILLION PIXEL-SAMPLES A SECOND, which closes three of PLAN.md's open questions at once. Plus the sweep helper that three separate entries said was the real fix and none of them built.

### THE COST IS LINEAR IN PIXEL-SAMPLES AND NOTHING ELSE

Seven sample counts across three resolutions, best of three runs each, least-squares
fitted so the process-start and file-write overhead falls out as the intercept rather
than contaminating the slope:

| resolution | pixels | ns per pixel-sample | fixed overhead |
| --- | --- | --- | --- |
| 1920x1080 | 2,073,600 | **20.7** | 0.202 s |
| 960x540 | 518,400 | **21.1** | 0.164 s |
| 480x270 | 129,600 | **25.2** | 0.160 s |

**44.7 M pixel-samples/second** on an RTX 2070 SUPER.

**THE INTERCEPT IS THE CLI, NOT THE RENDERER.** A 16x16 frame at one sample takes
0.151 s, which is process start, CUDA context creation and the PPM write with almost no
kernel under it. In After Effects the context is already up, which is why the user's own
host log reports 0.11 s for a 1080p 1-sample frame where the CLI reports 0.256 s. The
slope is the number that transfers; the intercept is this program.

**480x270 IS WORSE PER SAMPLE, AND THAT IS THE INTERESTING ONE.** 129,600 pixels is
about three waves on a 40-SM card, so a small frame does not fill it. That matters
precisely because a small frame is what a Draft preview *is* — the per-sample cost gets
worse exactly where interactivity is wanted.

### WHICH ANSWERS "CAN DRAFT BE INTERACTIVE AT ALL", OPEN SINCE PHASE 0

Kernel only:

| | 1 spp | 4 spp | 16 spp | 64 spp |
| --- | --- | --- | --- | --- |
| 1920x1080 | 46 ms | 185 ms | 741 ms | 2.97 s |
| 960x540 | 12 ms | 46 ms | 185 ms | 741 ms |
| 480x270 | 3 ms | 12 ms | 46 ms | 185 ms |

Add the output transform (10 ms at 1080p, threaded — see the entry below) and OIDN's RT
HDR filter with albedo and normal (30 ms on CUDA, 774 ms on the CPU, measured
2026-09-28). A 1080p Draft frame is then **86 ms, about 12 fps**, and 4 spp is 225 ms,
which is scrubbable.

**AND IT SETS THE MINIMUM GPU, WHICH PLAN.md HAS DEFERRED SINCE THE START.** A card at a
quarter of this throughput renders 1080p 1 spp in 184 ms; with a CUDA denoise that is
~225 ms, and half resolution brings it back under 100 ms. **So the path tracer is not
what sets the floor — the denoiser is.** On a machine falling back to OIDN's CPU device
the denoise is 774 ms against a 46 ms render: **17x**, and Draft becomes entirely
denoiser-bound. Whether the CPU device is offered at all is now a decision with a ratio
behind it.

### THE TDR BUDGET WAS RE-MEASURED AS THE FILE ASKED, AND THE ANSWER IS TO LEAVE IT

`KernelApi.h` says, in capitals, *"WHEN THE MAJORANT IS TIGHTENED, MEASURE AGAIN."*
Done. `kGpuPixelSampleBudget` is 2,097,152 pixel-samples, chosen as ~0.19 s of work at
93 ns per pixel-sample. At 22 ns it is now **47 ms per launch** — four times more
conservative than designed.

**IT STAYS, AND THE ARITHMETIC IS WHY.** The cost of an over-small budget is launch
count: 1080p at 64 spp is 63 launches at roughly 50 us of overhead each, which is
**3.2 ms against 2.97 s of work — one part in nine hundred.** The benefit is margin: 47 ms
against a ~2 s display-driver timeout is 42x here and still 10x on a card four times
slower, which is exactly the safety property the constant exists for.

Raising it would buy three milliseconds and spend most of the TDR margin. Recorded so
the next person to read that instruction finds it already carried out.

### THE SWEEP HELPER, WHICH THREE ENTRIES CALLED FOR AND NONE BUILT

The previous entry said: *"Writing the lesson down has now failed three times to prevent
it. What would is a sweep helper in `TestFramework.h`."* Built.

`pltest::Sweep` collects, remembers the first disagreement, and reports one line. The
count that made the case for it:

| test | lines reported on a single injected fault |
| --- | --- |
| `TheQuantiserIsExactlyClampScaleAndRound` | ~16,000 |
| `TheCurveMatchesTheOneOnTheRenderPath` | 2,007 |
| `TheAltitudeWarpRoundTrips` | 64 |

Two of the three are converted; the output is identical in quality and the boilerplate
is gone:

    2007 of 2015 curve probes disagree.
    first: at 0.00313089998 -- got 0.0399987996, wanted 0.0404511765

**THE THIRD IS DELIBERATELY NOT CONVERTED.** `TheQuantiserIsExactlyClampScaleAndRound`
reports which *bit depth* and which *channel* disagreed and prints both sides as the
integers they actually are. The generic helper carries one double and one location.
Converting it would trade real diagnostic detail for uniformity, and that test's whole
value is saying which of eight quantiser paths failed. The helper is for the next sweep,
not for rewriting that one.

**BOTH HALVES VERIFIED.** The mismatch path by re-injecting `1.055f` as `1.05f`; the
`atLeast` guard by temporarily demanding 999,999 comparisons, which reports

    sweep over curve probes compared 2015, expected at least 999999
    -- an empty sweep passes while checking nothing

That guard is the one that matters long-term: a sweep whose range silently became empty
passes while checking nothing, and every loop-driven test in this suite has that failure
mode.

### State

115 unit tests, 22 ctest suites, all green. PLAN.md updated: the minimum-GPU row and the
Draft-interactivity question are now answered rather than deferred, with the superseded
0.28 s figure marked as such rather than quietly overwritten.

### Next

- **OIDN**, still the one thing blocked on a product decision rather than on code —
  and the measurement above sharpens it: the CPU device is 17x the render at Draft, so
  "bundle the CUDA device only" is now a defensible fourth option.
- **The rest of the Bruneton atmosphere** — skylight ambient and aerial perspective from
  `proto/index.html`. The transmittance half is done and the plumbing they need exists.
  This one changes the look, so it ends in a blessing decision.
- **The field cache.** The entry of 2026-09-28 declined to wire it for three reasons;
  reason 2 — "exposure should cost nothing" needing a sampling/resolve key split — was
  answered by lifting the output transform out of the per-pixel path. Reasons 1 and 3
  stand, and reason 3 (MFR-shared mutable state) is the one that cannot be verified
  outside the host.
- **Working Space None**, one log line.

---

## 2026-09-29 — THE INNER SUN MARCH IS GONE: the table is wired in and the frame is 1.47x faster. Two independent measurements agree on WHERE the picture changed, which is what turned blessing a golden from a judgement into a decision with a number behind it.

`sunOpticalDepth()` ran **inside** the view march — eight steps of quadrature at every
one of twenty-four steps, 192 `exp()` pairs per sky ray, for a quantity that does not
depend on the view direction at all. It also ran at every scattering event in the bounce
loop, which is the hotter of the two.

Both are now one lookup into the table built in the previous entry.

### 1.47x, MEASURED BY A/B ON THE SAME BINARY

The march was put *back* into `SkyLib.slang`, rebuilt, timed, and removed again — so
this is one change measured against itself rather than against a number from a different
day.

| scene | with the march | with the table | |
| --- | --- | --- | --- |
| GPU, 1920x1080, 8 spp, sun elevation 2 | 1.022 s | **0.697 s** | **1.47x** |
| CPU, 640x360, 4 spp, sun elevation 2 | 2.458 s | **2.145 s** | 1.15x |

Best of three each, wall clock including process start and the PPM write — so the
render-only figure is better than this and this is the honest one.

The CPU gains less because the ratio there is dominated by fixed overhead at that size,
not because the kernel behaves differently; both backends run the identical lookup.

### THE STRUCT CARRIES THE TABLE, WHICH AVOIDED THREADING A PARAMETER THROUGH THE WHOLE CALL CHAIN

`skyRadiance` is reached from inside the bounce loop, through `environmentRadiance`, so
passing the table as an argument meant adding one to every function on that path — in a
file whose whole discipline is that its expression structure is preserved so a bitwise
parity test stays meaningful.

**A `StructuredBuffer` IS LEGAL AS A STRUCT MEMBER on the `cuda` and `cpp` targets.**
Checked with `slangc` on a throwaway file *before* the design was committed to, not
assumed — it generates as the prelude's `{ T* data; size_t count; }`, exactly the shape
the host already fills for the drift table. So it went inside `SkyInput` and nothing
else changed shape.

**IT IS A POINTER IN `RenderRequest` AND THAT IS NOT STYLE.** The request crosses to the
device as a kernel argument block, which CUDA caps at **4 KB**. The table is 196 KB.
By value it would not render wrongly — it would fail the *launch*, as an invalid
configuration, on every frame.

### WHERE THE PICTURE CHANGED, PREDICTED AND CONFIRMED BY TWO MEASUREMENTS

`slang.skyParity` **passes**, which is the first thing to check: `SkyLib.slang` and
`Shading.h` were both rewritten and still agree bitwise, so the transcription is
faithful and any change in the render is the table, not a typo.

Then the goldens:

| scene | sun elevation | result |
| --- | --- | --- |
| midday | 45 deg | **unchanged** |
| horizon | 12 deg | **unchanged** |
| sunset | 2 deg | max 3, mean 0.40 |

And independently, `LutAgreesWithTheMarchItReplaces` — the table against the 8-step
quadrature it replaces, which is kept in `Shading.h` for exactly this — reports its
**worst disagreement of 0.0350 at the top of the atmosphere looking 0.1 below level**:
a grazing path through the whole depth of the air.

**THOSE TWO ARE THE SAME FINDING ARRIVED AT FROM DIFFERENT DIRECTIONS.** The only golden
that moved is the one whose light arrives along exactly that grazing path. A pixel test
and a physics test agreeing on *where* the difference lives is what makes it a
measurement rather than a coincidence.

### WHICH MADE BLESSING A DECISION WITH A NUMBER BEHIND IT

`tests/golden/CMakeLists.txt` is blunt that blessing is a judgement — *"a suite that
regenerated its own references whenever they failed would agree with every change ever
made, including the wrong ones."* The case here:

1. the port is bitwise-faithful (`slang.skyParity`);
2. two of three scenes did not move at all;
3. the third moved by 3 of 255 at one pixel, mean 0.40;
4. the table is the **more accurate** of the two — 64 uniform steps in double against
   8 quadratic steps in float — so where they differ it is the new number that is right.

**ONLY `sunset` WAS BLESSED, NOT ALL THREE.** `golden-bless` re-renders every reference,
which would have silently absorbed any sub-tolerance drift in `midday` and `horizon`.
Their reference files are byte-identical before and after — checked by hash, not
assumed — so those two remain pinned to references blessed before any of this.

### THE SAMPLER NOW EXISTS THREE TIMES, AND EACH COPY IS PINNED TO ANOTHER

| copy | why it cannot be merged |
| --- | --- |
| `src/engine/Atmosphere.cpp` (host, double) | `src/engine/` holds no kernel headers |
| `src/kernel/Shading.h` (float) | must compile for CUDA |
| `src/kernel/slang/SkyLib.slang` | another language |

`slang.skyParity` compares the last two bitwise; `LutAgreesWithTheHostSampler` compares
the first two to 1e-6. The chain is closed. Three copies of anything is two too many,
and the alternative here is not one copy — it is three copies with nothing comparing
them.

### THE PARITY HARNESS BUILDS ONE TABLE AND HANDS IT TO BOTH SIDES

`SkyParityMain.cu` already typed its parameters once and fed both engines, for the
stated reason that separately-filled structs could pass while the port read a different
sky. The table is under the same rule and it matters *more*: two sides each building
their own table would compare two samplers over two tables, and agree while the
atmosphere differed.

### State

115 unit tests (was 113), 22 ctest suites, all green. `sunset` re-blessed; `midday` and
`horizon` untouched. Build clean under `/W4 /permissive-`.

### THIS IS THE THING TO LOOK AT IN AFTER EFFECTS

Everything since the last host log is now in the binary, and the sky is the part with a
picture attached:

- the atmosphere is **1.47x faster** and more accurate at low sun;
- the output transform moved out of the per-pixel path;
- the colour decision reads the project.

**What to check:** a low sun. The golden says the difference is 3 of 255 at 128x72, so
this is confirmation rather than investigation — but low-elevation sun is where the
change lives, and it is the one configuration no golden covers at comp resolution.

The diagnostic log also now names the working-space profile:

    colour raw: ... gamma=2.400 profile="..."

which is what settles the **Working Space None** branch that is still unmeasured — the
one case where the colour decision could regress. Set the project to Adobe colour
managed, Working Space None, and read that one line.

### Next

- **OIDN**, which is now only a product decision: ~53 MB bundled, fetch on first run, or
  built from source with the RT filter alone. The hook point is a marked comment in
  `smartRenderHost`, immediately above the transform call.
- **The rest of the Bruneton atmosphere.** The table is the expensive half; skylight
  ambient and aerial perspective from `proto/index.html` are the remaining Phase 2 sky
  work, and the plumbing they need now exists.
- **A sweep helper in `TestFramework.h`**, per the three-times-repeated lesson.

---

## 2026-09-29 — THE HOST ANSWERED, AND IT CLOSED PHASE 1'S LAST EXIT CRITERION. 8 bpc ran for the first time, the AEGP colour calls are legal from pre-render, and the OCIO working space reports gamma 2.4 — which refutes the reason the rule that reads it was ordered the way it is, while confirming the ordering.

Four frames in AE 2026, `MISTYTUNE_DIAG=1`, three bit depths, one OCIO-managed project.
Everything below is read off that log rather than argued.

### `'argb'` FINALLY APPEARED, AND WITH IT THE LAST OF PLAN.md's PHASE 1 EXIT

That criterion — *"renders correctly at 8, 16 and 32 bpc"* — has been open since the
effect first loaded, and 8 bpc had **never once run**. All three are now on the record,
each confirmed twice: by the format code and independently by `rowbytes / width`.

| logged | FOURCC | format | bytes/px | rowbytes/width |
| --- | --- | --- | --- | --- |
| 1650946657 | `argb` | `PF_PixelFormat_ARGB32` | 4 | 7680/1920 = 4 |
| 909206881 | `ae16` | `PF_PixelFormat_ARGB64` | 8 | 3840/480 = 8 |
| 842229089 | `ae32` | `PF_PixelFormat_ARGB128` | 16 | 30720/1920 = 16 |

Only the 8-bit one is named by its channels; 16 and 32 are `ae16` and `ae32`. The table
is now in `docs/HOST-NOTES.md`, because a format code prints as a nine-digit integer and
nothing about 1650946657 says "8 bpc".

**AND ALL THREE RENDERED THE SAME DECISION** — `encodeSrgb=0` on every one of them.
That is `EveryBitDepthStoresTheSameBrightness` holding in the host rather than in a test:
the bug that started this whole thread was two depths disagreeing, and they no longer
can, because the decision is made once in pre-render from the project.

### THE AEGP COLOUR CALLS ARE LEGAL FROM PRE-RENDER

    colour raw: ocioErr=0 ocio=1 profileErr=0 haveGamma=1 gamma=2.400

Both error codes zero, on every frame. The whole chain ran on the thread AE calls
pre-render on: `AEGP_RegisterWithAEGP`, `AEGP_GetEffectLayer`,
`AEGP_GetLayerParentComp`, `AEGP_GetNewWorkingSpaceColorProfile` and
`AEGP_GetColorProfileApproximateGamma`.

Only `AEGP_GetEffectCameraMatrix` is documented for a render thread; the other five are
documented for neither. **Writing it fail-safe was still right** — a wrong-thread call
returns `A_Err_WRONG_THREAD` (5) rather than throwing, so the cost of being wrong was a
logged 5 and yesterday's render. That is what made it cheap to simply try, and the
fallback stays for the hosts and versions this log does not cover.

### gamma = 2.400 IN OCIO MODE, WHICH REFUTES THE REASON AND CONFIRMS THE ORDER

`ColorManagement.h` asserted that an OCIO working space "is the config's `scene_linear`
role". **If that were true the gamma would be near 1.0. It is 2.4.**

The log cannot say which of two things is happening:

- the OCIO working space is not scene-linear, or
- `AEGP_GetNewWorkingSpaceColorProfile` does not describe the OCIO working space at all
  and is falling back to something generic — Rec.709's transfer curve is 2.4, which is
  suspicious rather than conclusive.

**WHAT IT DOES SETTLE IS THAT THE GAMMA MUST NOT BE BELIEVED IN OCIO MODE.** Rule 3
would read 2.4 as "encoded" and return the opposite answer. Rule 2 fires first and never
asks, so the effect is right — and it is right for a reason that is now measured rather
than for the reason it was written down with.

**THE ORDERING WAS LOAD-BEARING AND NOBODY KNEW IT.** It was chosen as "the soundest of
the three"; it turns out to be the only thing standing between this project and a
double-encoded render. Corrected in the file, because a comment that explains a
behaviour by an assertion the log contradicts is exactly the failure this project has
now recorded three times.

### THE OUTPUT TRANSFORM COSTS 9 ms IN THE HOST, WHICH IS WHAT THE CLI SAID

    output transform 0.009 s (encodeSrgb=0, ev=0.00, agx=0)

Against 10.3 ms measured through `mistytunec` at the same resolution. The threading
decision — taken because the serial version was 91-97 ms and the guess behind writing it
serial was 20 — transfers to the host unchanged. At 1920x1080 the render is 0.11 s, so
the pass is 8% of the frame; serial it would have been 46%.

### WHAT THE LOG CONFIRMS IN PASSING

- **`what_gpu=NONE` on all four frames**, again, with a device AE itself handed the
  effect at `GPU_DEVICE_SETUP` and reported compatible. `SMART_RENDER_GPU` is still
  never called, so `transformCuda` remains compiled and unexecuted.
- **The GPU renders anyway**, through `renderCudaToHost` inside the ordinary CPU smart
  render: 1920x1080 at one sample in 0.11 s.
- **Reduced resolution is right.** `downsample=1/4` gives `frame=480x270` — the frame
  scaled *with* the buffer, which is the bug that once drew the top-left third of the
  sky and read as a dead renderer.
- **The camera is right.** `distanceToPlane=2666.7 plane=1920x1080` → 22.9 deg, which is
  exactly the default AE camera this was predicted against.

### STILL NOT MEASURED, AND IT IS THE ONE THAT COULD BITE

**No non-OCIO project has been through this.** Rules 3 and 4 have never fired in a host.
In particular the regression flagged when this landed is still open: if
`AEGP_GetNewWorkingSpaceColorProfile` returns a *linear* profile under **Working Space
None**, rule 3 fires and the default project flips to not encoding. One log line
settles it, and it needs the project set to Adobe colour managed with Working Space None.

The reading `gamma=2.400` is mildly reassuring for rule 4 — the only real gamma anyone
has seen sits firmly in the "encoded" bucket — and says nothing about the None case,
where the question is whether a profile comes back at all.

### State

113 unit tests, 22 ctest suites, all green. Build 7 confirmed in AE 2026 at 8, 16 and
32 bpc and at quarter resolution.

### Next

- **One log line from a Working Space None project**, per above.
- **The Sky port**, steps 2 and 3 of the previous entry. Needs no host; needs a person to
  look at the resulting sky once.
- **The OIDN decision**, which is a product question and not an engineering one.
- **A sweep helper in `TestFramework.h`.**

---

## 2026-09-29 — THE TRANSMITTANCE TABLE, which is the thing that makes a precomputed atmosphere affordable. Built and tested against closed forms rather than against stored numbers; and a test that passed for the wrong reason was found by injecting the fault it was written to catch.

`Sky.slang` is still the Phase 1 analytic atmosphere, and the reason it is slow is
structural rather than incidental: `sunOpticalDepth()` marches **towards the sun** at
every step of the view march, so the cost is quadratic in a quantity that is not even
view-dependent.

`proto/index.html` -- which passed the Phase 0 look verdict, and which PLAN.md names as
the reference the port is checked against -- does not do that. It precomputes a 256x64
transmittance table once and looks the answer up.

**THE TABLE IS NOT VIEW-DEPENDENT AND NOT SUN-DEPENDENT.** Sun *direction* enters as a
lookup coordinate, not as an input to the build, so dragging the sun -- the thing an
artist does continuously -- does not invalidate it. What invalidates it is turbidity,
planet radius and scale height: the Physics tab, which is set once.

### WHAT LANDED, AND WHAT DELIBERATELY DID NOT

`src/engine/Atmosphere.{h,cpp}` and 11 tests. **Nothing uses it yet**, and that is the
stopping point rather than an oversight -- see below.

It is host code for the same reason `IceField` and the drift table are: it is a pure
function of three numbers, it costs about a million `exp()` calls, and it must be
**cached** rather than rebuilt, because `deriveRenderInputs()` runs once per launch and
a frame is many launches.

**THE INTEGRATION RUNS IN DOUBLE AND THE TABLE STORES FLOAT**, which looks like it
contradicts `CloudParams.h`'s "Real is float because these structs cross to the GPU" and
does not. Neither that rule nor `OutputConvert.h`'s refusal to widen reaches a
precompute: nothing downstream compares this against a float-built reference, because it
*replaces* the march it derives from rather than reproducing it. What it does have to be
is identical everywhere -- and it is more so than what it replaces: **the table is built
once on the host and the CUDA path uploads those same floats**, so both backends read
bit-identical values, where the old inner march had each backend evaluating its own
`exp()`.

### THE TESTS ARE PHYSICS, NOT REGRESSION, AND THAT IS THE POINT

Not one of the 11 compares against a number this code produced. Each states something
that has to be true of an atmosphere and would still have to be true of a replacement:

- at the top of the atmosphere looking up, transmittance is 1;
- a long slant path removes blue fastest, by more than 3x -- **that inequality is the
  sunset**, and a channel-order mistake would otherwise read as a colour grade;
- transmittance falls monotonically as the path lengthens, in both axes;
- more turbidity means less light, and it costs red proportionally more than blue,
  which is why haze goes milky rather than bluer;
- the build's `v*v` altitude warp and the sampler's `sqrt` invert each other;
- sampling out of range clamps rather than wrapping.

**A LOOKUP TABLE IS THE EASIEST THING IN A RENDERER TO GET WRONG QUIETLY.** Every one of
those failures produces a smooth, plausible, wrong sky -- a warp mismatch just looks
like a clearer day. None is visible in a render; all are trivial against a closed form.

### A TEST THAT PASSED FOR THE WRONG REASON, FOUND BY INJECTING ITS OWN FAULT

`ARayIntoThePlanetIsFullyBlocked` sampled **straight down** from the ground and asserted
zero. It passed. **It also passed with the ground-shadow branch deleted** -- which is
how the mistake was found, because the red checks were run rather than assumed.

Without the branch a downward ray integrates straight through the planet, where altitude
clamps to zero and density therefore sits at its sea-level maximum for thousands of
kilometres. `exp(-tau)` underflows to zero anyway. The assertion was true for a reason
that had nothing to do with what it was checking.

**THE BRANCH ONLY MATTERS NEAR TANGENT, WHICH IS WHERE IT MATTERS MOST.** A ray grazing
just below the horizon cuts a *short* chord through the planet. Computed for this table:

| probe (sea level) | subsurface chord | red leak without the branch |
| --- | --- | --- |
| mu = -0.03 | 382 km | **10.9%** |
| mu = -1.00 (straight down) | 12 742 km | 0 -- underflows either way |

Just below the horizon is where the sun is at sunset. The test is now
`ARayGrazingIntoThePlanetIsFullyBlocked`, probes four texels below the horizon so every
bilinear tap is blocked, and **is verified to go red** on the same injected fault.

### THREE FAULTS INJECTED, AND THE THIRD FLOODED AGAIN

| fault | caught by |
| --- | --- |
| altitude warp not inverted (`h/top` instead of `sqrt`) | `TheAltitudeWarpRoundTrips`, **and nothing else** |
| mu axis flipped | five tests |
| ground-shadow branch deleted | `ARayGrazingIntoThePlanetIsFullyBlocked`, after it was fixed |

The first is the interesting one: monotonicity did **not** catch it, because a wrong
warp is still monotonic. The round-trip test is the only thing that can see it, which is
the argument for writing it.

And `TheAltitudeWarpRoundTrips` reported **64 times** on its first red run. That is the
third time this project has written assertions inside a sweep and had to learn the same
lesson -- it is recorded twice already, in `TheQuantiserIsExactlyClampScaleAndRound` and
in yesterday's curve-parity test. Reworked to one assertion after the loop:

    188 of 192 sampled texels missed the row they were built for.
    first: row 1 -- got 0.142527625, wanted 0.144934282

**Writing the lesson down has now failed three times to prevent it.** What would is a
sweep helper in `TestFramework.h` that collects and reports once, so the right shape is
the easy one to reach for.

### State

113 unit tests (was 102), 22 ctest suites, all green. Goldens unmoved -- nothing calls
this code yet, so no render changed.

### WHERE THIS STOPS, AND WHY IT IS A DECISION RATHER THAN A PAUSE

The remaining work is plumbing and then a look:

- **Wiring**: `RenderRequest` gains a table pointer beside `driftBuffer`;
  `deriveRenderInputs()` builds it lazily into a `thread_local` keyed on
  `TransmittanceParams`, so no caller can forget and no launch rebuilds it; `renderCuda`
  uploads it exactly as it already uploads the drift table -- 196 KB at ~30 us against a
  190 ms launch, so per-launch upload is simpler than tracking dirtiness and costs
  nothing measurable.
- **Use**: `SkyLib.slang`'s `sunOpticalDepth()` call becomes a table lookup, the
  generated CUDA and C++ are regenerated (`tools/slang/bin/slangc.exe` is present), and
  a parity test compares the table path against the march it replaces.

**THE GOLDENS WILL MOVE, AND BLESSING THEM IS A JUDGEMENT.** `tests/golden/CMakeLists.txt`
is explicit that blessing is a decision and not a refresh: *"a test that regenerated its
own references whenever they failed would agree with every change ever made, including
the wrong ones."* The port is not meant to be numerically equivalent -- the proto's
atmosphere is a different and better one -- so "the goldens changed" cannot be
auto-resolved here.

Stopping with a tested component that nothing calls leaves the tree green. Stopping
halfway through the wiring would not.

### Next

- **The Sky port, steps 2 and 3 above.** Needs no host and no dependency; needs a person
  to look at the resulting sky once.
- **The OIDN decision**, which is a product question and not an engineering one: ~53 MB
  bundled, fetch on first run, or build from source with only the RT filter. The package
  is not on this machine.
- **Read the four colour-management log lines in the host.**
- **Look at 8 bpc once** -- `'argb'` has still never appeared in a log.
- **A sweep helper in `TestFramework.h`**, per the third repeat above.

---

## 2026-09-29 — THE OUTPUT TRANSFORM IS OUT OF THE PER-PIXEL PATH, which is what OIDN was blocked on. The restructure that was called too risky to land blind is now the one with the loudest failure mode, and the guess about what it would cost was wrong by five times in the direction that mattered.

`applyOutputTransform` -- real EV, optional AgX, and since yesterday the sRGB transfer
curve -- was called **inside `renderPixel`**, so the destination held exposed and
possibly tonemapped values from the first sample onward. OIDN's HDR filter wants linear.
The order has to be

    kernel writes LINEAR mean  ->  denoise  ->  output transform  ->  quantise

and the last three are per-**frame**, not per-sample.

### THE REASON THIS WAS DEFERRED NO LONGER EXISTS, AND YESTERDAY'S ENTRY IS WHY

The previous attempt stopped here deliberately, and the reason was specific:
`applyOutputTransform` **was the identity at default settings** -- exposure 0, AgX off --
so a forgotten transform pass would have been invisible in After Effects on every
default render and would have first appeared, months later, as "the Exposure slider does
nothing" in a different file.

`encodeSrgb` defaulting to true removed that. The transform is never the identity now.
**Measured, by deleting the call and running the goldens:**

| scene | max | mean |
| --- | --- | --- |
| midday (ev 0) | 74 | 49.7 |
| sunset (ev 1.5) | 165 | 56.9 |
| horizon (ev 0) | 74 | 59.8 |

All six golden tests fail, including the three at default exposure, at a mean error of
**a fifth of the whole range**. A forgotten pass is now a near-black render with a sun in
it. The change that could not be landed blind is now the one that cannot be got wrong
quietly.

### PROVED TO BE A CHANGE OF ARRANGEMENT AND NOT OF ANSWER

All 22 ctest suites pass against references blessed **before** the restructure, with no
re-blessing. That includes `golden.sunset` at `--ev 1.5`, where the transform is doing
real work, and all three `golden.gpu.*`.

It is exact rather than close, and it should be: the destination is float32 either way,
so `mean` written and read back is the same float the old code passed straight to
`applyOutputTransform`. The one real difference is that a split render used to transform
the running mean on **every chunk** and throw away all but the last -- redundant work as
well as the wrong buffer contents.

### THE COST WAS GUESSED AT 20 ms AND IS 93. THAT IS WHAT DECIDED THE DESIGN.

The pass was written single-threaded, with a comment explaining that a pool was not
worth it against a frame measured in seconds. **Measured with mistytunec at 1920x1080:
91-97 ms over five runs.**

Nearly five times the guess, and the number is what decides the question rather than
colouring it. A Draft GPU frame is 0.28 s on an RTX 2070 SUPER, so a 93 ms serial tail
is **33% of it** -- three times what the denoiser costs on CUDA, for exposure and a
transfer curve. It is 6.2 million `powf` calls; nothing is wrong, there are simply that
many.

Threaded, on an 8-core/16-thread i7-10700K: **10.3 ms, a 9x win**, and 3.7% of that frame
instead of 33%.

**THREADING IT NEEDS NO NEW TRIPWIRE, AND THE REASON IS WORTH KEEPING STRAIGHT.** Every
pixel here reads and writes only itself, so any partition of the rows produces identical
floats in any order. That is exactly what is NOT true of the per-sample sum, where
regrouping changes the image and `samplesPerLaunch()` exists to control it. The two
splits look alike and are not.

### ...AND `--threads` NOW REACHES THE PASS, SO AN EXISTING TEST COVERS IT FOR FREE

The CLI hands its `--threads` value to `transformCpu` as well as to `renderCpu`, which
widens `determinism.threadCount` from "the render is thread-count invariant" to "the
whole pipeline is". That is the claim the effect actually relies on under multi-frame
rendering, where AE picks the worker count and the effect does not get a say.

### WHICH TRANSFORM TO CALL IS DECIDED BY WHERE THE PIXELS ARE, NOT BY WHAT RENDERED THEM

This is the part that is easy to get backwards. `renderCudaToHost()` copies each band
into **host** memory, so a GPU-rendered frame on that path -- which is every frame the
effect renders today, and every frame the CLI renders -- is finished with `transformCpu`.

`transformCuda` exists for exactly one caller: `smartRenderGpu`, whose destination is a
device pointer from `PF_GPUDeviceSuite1` that never comes back to the host.

A side effect worth noting: the transform is now on the CPU for both golden paths, so it
has stopped being a source of CPU-versus-GPU divergence.

### State

102 unit tests, 22 ctest suites, all green, goldens unmoved and unblessed. Build clean
under `/W4 /permissive-` with no new warnings outside the Slang prelude.

### What this did NOT do

- **`transformCuda` has never executed.** It compiles under nvcc and is dead code for
  the same reason `renderCuda` is: AE reports `what_gpu=NONE` and never calls
  `PF_Cmd_SMART_RENDER_GPU`. There is no CLI path with a device destination to exercise
  it from, because `renderCudaToHost` copies back inside itself.
- **No denoiser.** The hook point is a marked comment in `smartRenderHost`, immediately
  above the transform call. OIDN is **not** blocked on code any more -- it is blocked on
  a product decision PLAN.md already states: ship ~53 MB beside a 1 MB effect, fetch on
  first run, or build OIDN from source with only the RT filter and the CPU and CUDA
  devices. The package is not on this machine.

### Next

- **The OIDN decision**, which is not an engineering question. The runtime-optional load
  is the part that does not depend on it and could be built first, but writing an FFI
  binding with no headers on disk and no way to run one call of it would be guessing.
- **`Sky.slang` is still the Phase 1 analytic atmosphere.** The Bruneton precompute needs
  no host and no dependency, and is the remaining Phase 2 kernel item.
- **Read the four colour-management log lines in the host** (previous entry).
- **Look at 8 bpc once** -- `'argb'` has still never appeared in a log.

---

## 2026-09-29 — THE ENCODING IS ASKED OF THE PROJECT INSTEAD OF ASSUMED OF IT. The API the last entry named turns out to be the wrong one, the checkbox that decides the hardest case has no API at all, and the hole is pinned by a test that asserts the wrong answer on purpose.

`ViewParams::encodeSrgb` was a hardcoded `true` with a page of reasoning beside it. The
reasoning was sound and the measurement behind it was real -- **it was a measurement of
one project**, AE's default, and the constant it justified is wrong for every
colour-managed one.

### THE API THE LAST ENTRY NAMED IS THE WRONG ONE, AND IT IS WORTH SAYING WHY

The previous entry's Next list said to use `AEGP_IsOCIOColorManagementUsed` **and
`AEGP_DoesViewHaveColorSpaceXform`**. The second one asks about an `AEGP_ItemViewP` --
the comp **viewer panel**.

**A render-queue export has no viewer.** So an encoding keyed off that call would make
the preview and the exported file disagree, which is a worse bug than the one being
fixed and a much harder one to see: both renders look plausible, and they are only
wrong next to each other. That is the same shape as the bug the last entry found, one
level up.

What decides the encoding is the **project**, so the project is what gets asked.

### WHAT IS ACTUALLY READABLE, AND IT IS TWO FACTS AND NOT THREE

| | |
| --- | --- |
| `AEGP_IsOCIOColorManagementUsed` | is the project on OCIO |
| `AEGP_GetNewWorkingSpaceColorProfile` -> `AEGP_GetColorProfileApproximateGamma` | the working space's transfer curve, via the comp |
| **"Linearize Working Color Space"** | **no API. Searched the AE 25.6 headers; there is none** |

Colour Settings Suite **4**, not 6: suite 4 froze in AE 22.6 and already carries all
three calls, and asking for the oldest suite that answers keeps the effect loadable on
hosts older than the SDK it was built against.

An effect has no `AEGP_PluginID` of its own and two of the three calls want one, so
`AEGP_RegisterWithAEGP` mints one in the initialiser of a function-local static --
thread-safe by the standard, which matters because
`PF_OutFlag2_SUPPORTS_THREADED_RENDERING` means several frames are registering at once.

### THE RULES, AND THE ONLY ONE THAT IS SOUND RATHER THAN REASONED

1. **The read failed -> encode.** Exactly what shipped, so a host that cannot answer
   renders what it rendered yesterday.
2. **OCIO is on -> do not encode.** The soundest of the four. OCIO mode exists so that
   AE applies a configured view transform, and its working space is the config's
   `scene_linear` role. Ours would be the second of two.
3. **The working space reports a linear gamma -> do not encode.**
4. **Anything else -> encode.** Covers Working Space None, where AE applies nothing, and
   a non-linear working space such as sRGB, where the buffer is expected to already
   carry that space's curve. The two want the same thing from us for different reasons.

The threshold between 3 and 4 is 1.25, and **its exact value cannot matter**: the only
answers that occur are 1.0 and something from 1.8 up, so anything in that gap gives
identical answers. `TheLinearCeilingSitsBetweenTheOnlyTwoAnswersThatOccur` pins that the
gap is empty rather than that 1.25 is special.

### EVERY FAILURE PATH LANDS ON THE OLD CONSTANT, AND THAT IS THE WHOLE SAFETY ARGUMENT

There is no branch that can render worse than what shipped. No SP suite, no plugin id,
no colour suite, a layer mid-teardown, a host that is not After Effects -- all of them
return a default-constructed `HostColorSettings`, and `encodesSrgbForHost()` maps that
to `true`. That is what makes it defensible to put three new AEGP calls on the
pre-render path at all.

`AnUnaskedHostGetsTheBehaviourThatShipped` is the test that matters most in the file,
and it is not about colour: it is about never letting a future edit decide `false` on a
machine where the calls do not answer. Nobody here can enumerate those machines.

### THE HOLE, ASSERTED AS A HOLE

A project set to working space sRGB with **Linearize ON** holds linear pixels and wants
`encodeSrgb` false. All this decision can see is sRGB's gamma, so it says true, and such
a project renders one sRGB encode too light.

`ALinearisedWorkingSpaceIsUnservedAndKnowablySo` **asserts that wrong answer on
purpose.** If someone finds the API, or AE starts reporting gamma 1.0 for a linearised
space, that test fails -- and its failure is the notification that the hole closed.
A silent improvement that nobody writes down is how a caveat outlives the thing it
described.

It was equally unserved before, so this narrows the hole rather than opening one.

### VERIFIED TO GO RED, TWICE, AND THE SECOND ONE REPRODUCED A LESSON THIS FILE ALREADY RECORDS

Two faults injected into a green tree:

| fault | caught by |
| --- | --- |
| `if (!settings.queried) return true` -> `false` | `AnUnaskedHostGetsTheBehaviourThatShipped` |
| `1.055f` -> `1.05f` in the engine's sRGB curve | `TheCurveMatchesTheOneOnTheRenderPath` |

The second one reported **2007 times**, because the sweep asserted per value. The entry
of 2026-09-28 records that exact mistake -- "an injected 65535 made it report sixteen
thousand times and buried every other failure in the run" -- and the lesson had been
written down and then not applied to the next sweep written. Reworked to one assertion
after the loop; re-injected, and it now reports once:

    2007 of 2015 probes disagree between the two copies.
    first: input 0.00313089998 -- engine 0.0399987996, kernel 0.0404511765

### THE TWO COPIES OF THE sRGB CURVE ARE NOW COMPARED, WHICH IS WHAT MAKES TWO DEFENSIBLE

`encodeSrgbChannel()` is in `src/kernel/Shading.h` because it has to compile for CUDA.
`encodeSrgb()` is in `src/engine/OutputConvert.h` and has not been on the render path
since the encode moved. Two copies of a formula is normally a defect; the test above
turns the second one into an **independent reference**, so a mistyped constant in either
is a failure rather than a consistent answer. Merging them would make the comparison
tautological, which is why the duplication is staying.

### AND THE FILE STILL ASSERTED THE REFUTED PREMISE, IN TWO PLACES

`OutputConvert.h`'s header block still said, at length, *"AE'S INTEGER WORLDS ARE
DISPLAY-REFERRED. ITS FLOAT WORLD IS LINEAR"* -- the exact claim the last entry
disproved by rendering one comp at two bit depths. Its body had been fixed; its
documentation had not, so the file simultaneously explained the bug and asserted its
cause. `CloudParams.h` still pointed at `AEGP_DoesViewHaveColorSpaceXform` as the way to
close this. Both corrected.

The last entry has a section titled "A COMMENT THAT HAD BEEN FALSE FOR AN ENTIRE ENTRY".
This is the same thing, found in the file that entry was about.

### NONE OF THIS HAS BEEN IN AFTER EFFECTS, AND THAT IS THE HONEST STATE

The decision is unit-tested and the reader compiles clean under `/W4 /permissive-`.
**Not one of the three AEGP calls has ever executed.** What that leaves open:

- **Does `AEGP_GetNewWorkingSpaceColorProfile` succeed under Working Space None?** Rule 4
  assumes it fails or returns nothing. If it instead returns a *linear* profile, rule 3
  fires and the default project -- the one configuration confirmed in the host -- flips.
  That is the one regression this change can cause, and it is one log line to check.
- **Are these calls legal on a render thread?** `AEGP_GetEffectCameraMatrix` is
  documented safe and is already called from this same pre-render; `AEGP_GetEffectLayer`
  and the colour suite are not documented either way. The SDK returns
  `A_Err_WRONG_THREAD` (5) rather than throwing, so the failure mode is a logged 5 and
  yesterday's render. If a 5 appears, the read moves to sequence setup and gets cached.
- **What AE reports for each configuration.** Unknowable from here.

The raw answers are logged before anything is concluded from them, for the same reason
the camera logs `distanceToPlane` and the plane size:

    colour raw: ocioErr=%d ocio=%d profileErr=%d haveGamma=%d gamma=%.3f
    colour: encodeSrgb=%d (<which rule fired>)

**The measurement that settles it is one session**, with `MISTYTUNE_DIAG=1`: set the
project to each of Working Space None, sRGB with Linearize off, sRGB with Linearize on,
and an OCIO config, and read those two lines back for each.

### State

102 unit tests (was 91), 22 ctest suites, all green. Build clean under `/W4
/permissive-`. Goldens unmoved -- `src/cli/` has no host to ask and keeps the `true`
default, so every golden renders exactly as it did.

### Next

- **Read the four log lines in the host.** Blocks nothing and settles the whole entry.
  The Working-Space-None line is the one that could show a regression.
- **Look at 8 bpc once**, which has still never run -- `'argb'` has not appeared in any
  log. Carried from the last entry, still confirmation rather than investigation.
- **The output-transform lift, then OIDN.**
- **`Sky.slang` is still the Phase 1 analytic atmosphere.**
- If the host read turns out unreliable, the escape hatch is an env override beside
  `MISTYTUNE_DIAG` -- deliberately not built today, because an override nobody has
  needed is a second code path to keep true.

---

## 2026-09-28 — THE OUTPUT ENCODING WAS KEYED OFF THE BIT DEPTH, WHICH IS WHY 32 AND 16 BPC RENDERED THE SAME COMP DIFFERENTLY. It belongs to the project, and now it is in one place that every path goes through.

Found by rendering one frame at two bit depths in After Effects and comparing the
screenshots. Neither looked wrong on its own, which is the whole problem.

### THE MEASUREMENT

    16 bpc  ==  sRGB(32 bpc)

to **half a code value** on the flat ground patches, across six sampled regions. The sky
patches deviate up to 6.6 only because the two screenshots are slightly different crops.

The difference was exactly one sRGB encode, and it was **ours**, not the host's.

### WHICH REFUTED THE PREMISE THE CODE WAS BUILT ON

`AEBridge.h` asserted, at length: *"AE's integer worlds are display-referred. Its float
world is linear."* Everything followed from that -- encode at 8 and 16 bpc, write linear at
32.

**If it were true the two screenshots would be IDENTICAL.** AE would encode our linear float
for display and leave our already-encoded integers alone. They were not identical; they
differed by exactly the encode we applied to one and not the other. So AE applied the same
transform to both, and the project settings say which:

    Color Engine          Adobe color managed
    Working Color Space   None
    Linearize working color space   unchecked

**Working Space None means AE applies NO transform, at any depth.** It is the identity in
both directions. The premise holds only in a colour-managed project, and it was written as
though it held always.

### AN EFFECT THAT FILTERS PIXELS NEVER MEETS THIS. ONE THAT MAKES LIGHT HAS TO CHOOSE.

Whatever encoding arrives at a blur, leaves it. A generator starts from radiance and nothing
in the destination buffer says what encoding is expected -- so it has to decide, and the
decision is a property of the PROJECT, not of how many bits the buffer has. Bit depth and
colour space are orthogonal in After Effects. Keying one off the other is what produced two
renders of one comp.

### THE REFERENCE THAT SETTLES WHICH ONE WAS RIGHT

`proto/index.html`, line 1042, in the branch with the tonemap off:

    // LINEAR, and only the sRGB transfer applied so a monitor shows it.

and again after AgX, with *"AgX already lands in display-referred sRGB primaries; the
transfer curve is still ours to apply."* The prototype is what passed the Phase 0 look
verdict and what PLAN.md names as the reference the port is checked against. **It encodes.**

So of the three output paths, one was right and two were wrong in the same direction:

| path | before | after |
| --- | --- | --- |
| `proto/` -- the Phase 0 verdict | sRGB | -- |
| AE 8 / 16 bpc | sRGB | sRGB |
| AE 32 bpc | **linear** | sRGB |
| CLI to PPM, and all three goldens | **linear** | sRGB |

### THE FIX IS THAT THE ENCODE JOINS THE TRANSFORM IT IS THE THIRD STAGE OF

Exposure, tonemap and transfer curve are one transform, and `applyOutputTransform` in
`Shading.h` already held the first two. The curve is there now, behind
`ViewParams::encodeSrgb`, and **every render path goes through that one function** -- CPU,
CUDA, CLI, all three bit depths. `OutputConvert.h` lost its encode and is a clamp, a scale
and a round.

**IT DID NOT NEED THE OUTPUT-PASS RESTRUCTURE** the denoiser is blocked on. The encode goes
where the exposure already is; when that whole stage is eventually lifted out of the
per-pixel path, the three move together, which is the right grouping anyway.

**AND IT REMOVES THE REASON THAT RESTRUCTURE WAS RISKY.** The entry below stopped short of
it because `applyOutputTransform` was the identity at default settings, so a forgotten pass
would be invisible on a default render. With the curve in it, it is the identity at NO
settings -- forgetting it renders the visibly-under-encoded picture this entry is about. The
silent failure mode is gone.

### VERIFIED AS EXACTLY THE ENCODE AND NOTHING ELSE

The goldens were still on disk, unblessed, so the change could be checked against them
before replacing them:

| scene | max residual vs sRGB(old) |
| --- | --- |
| midday | 0.98 codes |
| horizon | 1.60 codes |
| sunset | 6.00 codes |

Sunset looked like a discrepancy and is not. **The worst residual sits at a pixel the OLD
render had clipped to 0/255**, where one linear code spans 12.71 sRGB codes -- so predicting
from an already-quantised linear image is meaningless at the floor. Measured, not argued.

**WHICH IS A SECOND FINDING: THE OLD LINEAR GOLDENS WERE CRUSHING THE SHADOWS.** A linear
8-bit PPM has almost no resolution in the darks, which is precisely what a display encoding
exists to fix. The new references are a better regression reference and not merely a
differently-encoded one.

`--linear` was added to the CLI so the old behaviour stays reachable -- for a colour-managed
project, and for the HDR bake when EXR lands. Checked: the default output is sRGB of the
`--linear` output to 0.98 codes.

### THE sizeof TRIPWIRE HAS A BLIND SPOT, MEASURED HERE

`Fingerprint.cpp` carries `static_assert(sizeof(ViewParams) == 100)` so that adding a member
without hashing it breaks the build. **Adding `bool encodeSrgb` beside the existing
`bool agxTonemap` did not change sizeof** -- it landed in padding the struct already had --
and the build stayed green.

The field *was* hashed, in `FieldCache.cpp`. Nothing here would have said so if it had not
been. A sizeof tripwire catches a member that changes the layout and misses one that fits a
hole; it is necessary and not sufficient, and the sufficient version needs reflection this
language does not have. Recorded in the file, because "I added a member and the build stayed
green" has to stop reading as clearance.

### CONFIRMED IN THE HOST: THE TWO DEPTHS AGREE

Build 6 installed and checked in After Effects on the same comp: **32 bpc and 16 bpc now
render the same picture**, and it is the lighter one -- the display-referred look that
matches `proto/index.html`, not the darker under-encoded render 32 bpc used to give.

So the fix is verified where it was found. The bug was a real one, the direction was the
one this entry predicted, and the depths are pinned to stay together by
`EveryBitDepthStoresTheSameBrightness`.

**THIS ALSO CLOSES PLAN.md's PHASE 1 EXIT CRITERION** as far as anything short of 8 bpc can:
the criterion asks the effect to render correctly at 8, 16 and 32 bpc, and two of the three
are now confirmed in the host against each other and against the Phase 0 reference.

### State

91 unit tests, 22 ctest suites, all green. Goldens re-blessed, display-referred. Build 6,
installed and confirmed in AE 2026.

### Next

- **Look at 8 bpc once**, which has still never run -- `'argb'` has not appeared in any log.
  The three depths are pinned to agree by `EveryBitDepthStoresTheSameBrightness` and two of
  them are now confirmed in the host, so this is confirmation rather than investigation.
- **Read the project's colour settings** instead of assuming Working Space None.
  `AEGP_IsOCIOColorManagementUsed` and `AEGP_DoesViewHaveColorSpaceXform` are in the SDK, and
  `Mistytune.cpp` marks the line where the answer belongs. A colour-managed project wants
  `encodeSrgb` false and today gets true, which is the one configuration this change does not
  serve -- it was equally unserved before, differently.
- **The output-transform lift, then OIDN.** No longer blocked on a silent failure mode.
- **`Sky.slang` is still the Phase 1 analytic atmosphere.**

---

## 2026-09-28 — THE MAJORANT WIN IS CONFIRMED IN THE HOST: 1.86 s to 1.10 s on the same frame. And reading the log to check that found a buffer overrun in code written an hour earlier.

An AE 2026 run of build 4, at 32 bpc, one, twelve and twenty-four samples.

### 1.69x, MEASURED IN AFTER EFFECTS, AGAINST THE SAME LINE OF AN OLDER LOG

The majorant entry below reported a 1.70x speedup measured through the CLI, and noted
honestly that its old-majorant column did not reproduce an earlier CLI table and that the
ratio rather than the seconds was the claim. **The host log settles it, because it is the
same instrument on both sides:**

    earlier entry   SMART_RENDER_HOST: rendered 1920x1080 on the GPU in 1.86 s (91 rows per band)
    this run        SMART_RENDER_HOST: rendered 1920x1080 on the GPU in 1.10 s (91 rows per band)

Same resolution, same sample count of twelve, same band size. **1.69x**, against 1.70x
measured through the CLI at 64 samples. Two different harnesses, one number.

### ...AND THE BAND BUDGET HOLDS ACROSS SAMPLE COUNTS, WHICH HAD ONLY EVER BEEN SEEN AT ONE

| samples | time | rows per band | bands | per band |
| --- | --- | --- | --- | --- |
| 1 | 0.21 s | 1080 | 1 | 0.21 s |
| 12 | 1.10 s | 91 | 12 | 0.092 s |
| 24 | 2.37 s | 45 | 24 | 0.099 s |

`kGpuPixelSampleBudget` is holding a launch near a tenth of a second at both split sample
counts -- an order of magnitude inside the two-second display-driver timeout -- and it is
adapting the row count rather than the time, which is what it was sized to do. The earlier
log only ever showed one sample count, so the constant's behaviour ACROSS them is new.

**A first look in After Effects is now 0.21 s a frame at 1920x1080**, against the third of
a second the entry below predicted from the CLI.

### The camera is right at a second zoom, which is better evidence than one

    camera raw: err=0 distanceToPlane=2666.7 plane=1920x1080
    camera: from the comp, vertical fov 22.9 deg

2*atan(540/2666.7) is 22.91 degrees, and 2666.7 is AE's default comp-camera zoom for a
1920-wide comp. The earlier log checked out at 3555.3 and 17.3 degrees. Two distinct zooms
both converting correctly says more about `CameraConvert.h` than either alone.

### WHAT THE RUN DID NOT EXERCISE, AND IT IS THE THING IT WAS RUN FOR

Every frame reports `bitdepth=32`, and `format=842229089` -- which is the fourcc `'ae32'`,
`PF_PixelFormat_ARGB128`, confirmed against `rowbytes=30720` over 1920 pixels giving exactly
sixteen bytes each.

**At 32 bpc `direct` is true and the function returns before the conversion**, so
`convertStagingFrame` -- the code the entry below is about -- did not run once. 8 and 16 bpc
remain unexercised in the host. The project bit depth has to be changed for that, and
nothing about the render path reveals it.

### READING THE LOG TO CHECK THAT FOUND A BUFFER OVERRUN

Decoding `format=842229089` meant looking at what value actually reaches
`toImageView`'s switch -- and noticing the switch had no case for it.

Its first version, written an hour earlier in the same session:

    default: v.format = PixelFormat::ARGB32F;

**ARGB32F WRITES SIXTEEN BYTES PER PIXEL. AN 8 BPC PIXEL IS FOUR.** The function is only
reached on the non-direct path, so every format arriving there is narrow, and defaulting
wide is a four-times overrun of every row of a world After Effects allocated and still owns.
It would not present as a wrong picture. It would present as AE crashing somewhere else,
later, with this plugin nowhere in the stack.

**THE LOOP IT REPLACED WAS SAFE HERE AND THE REFACTOR MADE IT UNSAFE.** The old code was
`sixteen ? 16-bit : 8-bit`, so anything unrecognised under-wrote -- a wrong picture inside a
buffer we were given, which is diagnosable. The refactor was proved bit-identical for the two
formats that occur, and the sweep that proved it could not see this, because the fault is in
the case where neither occurs.

The fallback is `ARGB8` now, and the call site logs a warning naming the format rather than
quietly producing a wrong picture. It cannot be unit-tested -- `toImageView` needs AE headers
by construction, which is exactly why it is four lines and why the arithmetic it feeds is not
in that file.

**THE GENERAL LESSON IS ABOUT THE PROOF, NOT THE BUG.** "Bit-identical over 16,440
conversions" is a true statement about the inputs that occur and says nothing about the
inputs that do not. An exhaustive-looking sweep is still a sweep of a domain somebody chose.

### 16 BPC RAN FOR REAL, AND IT BROUGHT THREE THINGS THAT HAD NEVER BEEN EXERCISED

A second run, with the project depth changed part way through, so both formats appear in one
log and the comparison is against the same comp.

    bitdepth=32   format=842229089   'ae32'   rowbytes 7680 / 480 px = 16 bytes
    bitdepth=16   format=909206881   'ae16'   rowbytes 3840 / 480 px =  8 bytes

`'ae16'` is `PF_PixelFormat_ARGB64`, which `toImageView` maps to `PixelFormat::ARGB16`, and
eight bytes a pixel is four `uint16` channels. **So `convertStagingFrame` executed in the
host for the first time** -- at 32 bpc `direct` returns before it, which is why the run
before this one exercised none of it.

**A PADDED DESTINATION, WHICH IS THE ONE THING A UNIT TEST CANNOT ARRANGE HONESTLY.**

    113 px wide, rowbytes 960, and 113 * 8 = 904 -- fifty-six bytes of padding a row

`TheFrameWalkHonoursTheDestinationStride` pins exactly this with a deliberately padded
buffer, and here it is arriving from the host unprompted. A stride derived from the width
would have written each row 56 bytes early and the frame would have sheared diagonally.

**AND THE FRAMING SURVIVED A 1/17 DOWNSAMPLE**, which is a far harsher case than the 1/4
the earlier run used, because it does not divide:

    1920 / 17 = 112.94  ->  113        1080 / 17 = 63.53  ->  64

AE asked for a 135x76 rect at 1/17 and the result rect, the origin and the frame all agree.
`TheFrameIsTheDenominator` and `ReducedResolutionKeepsTheFraming` are about this and had only
ever been checked against divisors.

**THE CONVERSION IS FREE AT THESE SIZES.** 480x270 at 24 samples is 0.16 s at 32 bpc and
0.16 s at 16 bpc -- the staging buffer and the quantising pass do not register against the
transport.

### THE ABORT PATH FIRED FOR THE FIRST TIME, AND IT RETURNS IN THE RIGHT PLACE

    aborted at row 64 of 64, sample 24 of 24, after 0.09 s

PLAN.md asks for abort and progress between accumulation launches, and until now that code
had never been seen running. **It returns from inside the band loop, before the `direct`
check and before the conversion**, so an aborted 16 bpc frame leaves AE's world untouched
rather than handing back a half-converted one for the host to cache. Checked against the
code rather than inferred from the picture, because a partially-written frame is the kind of
thing AE would cache and then show later out of context.

It aborted on the last row of the last sample, which is AE cancelling a frame that had
essentially finished -- ordinary, and not a sign the check is in the wrong place.

### WHAT 16 BPC STILL HAS NOT ESTABLISHED

**Whether the picture is the right BRIGHTNESS**, which is the one thing the trap is about
and the one thing a log cannot carry. Using 65535 instead of 32768 produces a correctly
sized, correctly strided, correctly padded, non-crashing render that is half as bright. Every
line above would read exactly the same.

What has been narrowed is how much is left to doubt: the format maps correctly, the SDK
header for `'ae16'` says "range 0...32768" in its own comment, and
`SixteenBitWhiteIs32768NotWhatEveryOtherHostUses` pins the arithmetic. What is unobserved is
the composition of those two facts in the host.

**The sharp test is toggling the project depth between 32 and 16 on one frame** rather than
judging 16 bpc on its own. A 2x error is unmissable as a jump and easy to miss as a still.

**8 bpc has still never run.** `'argb'` has not appeared in any log.

### State

89 unit tests, 22 ctest suites, all green. Plugin loads as v0.3 build 4; GPU device setup
reports the RTX 2070 SUPER as sm_75 with 40 SMs and AE agrees it is compatible.
`what_gpu=NONE` on every frame, so `PF_Cmd_SMART_RENDER_GPU` is still dead code and the card
is reached through `renderCudaToHost` inside the CPU smart render.

### Next, and the first one needs the host

- **16 bpc BRIGHTNESS, and 8 bpc at all.** 16 bpc now renders in the host with the right
  format, stride and padding; what is unobserved is whether it is the right brightness, which
  is the only symptom the 0..32768 trap has. Toggle the project depth 32 to 16 on one frame --
  a 2x error is unmissable as a jump and invisible as a still. 8 bpc has never run.
- **The output-transform lift, then OIDN.** Unchanged, and still blocked on the reason in the
  entry below: `applyOutputTransform` is the identity at default settings, so a forgotten
  transform pass is invisible in AE on a default render.
- **`Sky.slang` is still the Phase 1 analytic atmosphere.** The remaining Phase 2 kernel item,
  and the only one that needs neither the host nor a dependency.

---

## 2026-09-28 — THE BIT DEPTHS ARE TESTED RATHER THAN LOOKED AT. The output conversion moved into src/engine/ and is proved bit-identical to the loop it replaced; OIDN is measured and the install-bulk question turns out not to be the question; and the denoiser stops at an architectural blocker whose failure mode is invisible at default settings.

Second half of the same day. The majorant entry below is the first.

### PLAN.md's OLDEST OPEN EXIT CRITERION WAS OPEN BECAUSE IT WAS UNTESTABLE WHERE IT SAT

Phase 1's exit asks that the effect render **correctly at 8, 16 and 32 bpc (16-bit
channels run 0..32768, not 65535)**. That has been on the "never exercised" list since the
effect first loaded, and the reason it stayed there is that the conversion lived inside
`smartRenderHost`, sixty lines into the one function in this project that cannot run
without After Effects.

**LOOKING CANNOT SETTLE ANY OF THE THREE THINGS IN IT**, which is why "run it in AE and
check" was never going to close this row:

| trap | why looking fails |
| --- | --- |
| 0..32768 versus 0..65535 | a factor of two in brightness, in the one bit depth nobody checks first. Reads as a grading choice |
| a missing sRGB curve | renders near-black with a sun in it, which sends the reader to the transport |
| encoding ALPHA with the colour | **invisible in every frame this renderer can currently produce**, because the sky is opaque and 1 encodes to 1 |

So it is `src/engine/OutputConvert.h` now — the curve, the full-scale constants and the
quantiser — and `tests/unit/TestOutputConvert.cpp` exercises all three formats, the alpha
rule, the clamp directions and the destination stride in microseconds with no SDK and no
host. `src/ae/Mistytune.cpp` lost sixty lines and gained one call; `AEBridge.h` kept only
`toImageView`, which is the whole of the AE-specific part.

**THERE WERE TWO COPIES OF THE 0..32768 RULE AND ONE OF THEM WAS NOT UNDER TEST.**
`src/engine/Image.h` has had a correct `writePixel` with `kMaxChan16` since the Gravitune
scaffolding, used by `Contour` and tested through it. The smart-render loop never called
it — it carried its own scale, its own clamp and its own rounding. `fullScale()` reads
Image.h's constants now, and `FullScaleMatchesTheImageFormatConstants` is what says there
is one copy.

### THE REFACTOR IS PROVED BIT-IDENTICAL, BECAUSE ITS CALLER CANNOT BE RUN

Moving code out of the AE smart render has no safety net: the usual one is "run the tests
before and after", and there were no tests. The change would otherwise rest on having read
the old loop carefully and believing the reading.

The old quantiser was

    static_cast<A_u_short>(av > maxVal ? maxVal : av + 0.5f)

and the new one is a plain `av + 0.5f`. **The branch was unreachable** — `a` is clamped
into 0..1 above it and `maxVal` is the scale, so `av` never exceeds it. That is exactly the
kind of claim that is easy to make and easy to be wrong about.

So `TheConversionIsBitIdenticalToTheLoopItReplaced` transcribes the old expression verbatim
and sweeps it against the shipping function: 4097 steps across 0..1 plus the awkward values
— the ends, the HDR values that must clamp, the negatives that must not wrap — at both
integer depths, in two channel arrangements so an ARGB/RGBA slip cannot hide behind four
equal numbers. **16,440 conversions, 65,760 channels, zero disagreements.**

Verified to go red: an injected 65535 reports `first: 16 bpc channel 1 of input 0 -- now
65535, was 32768`.

### ONE ASSERTION AFTER THE SWEEP, NOT ONE INSIDE IT, AND THAT IS A LESSON FROM WATCHING IT

The first version asserted per comparison. The injected 65535 made it print **sixteen
thousand FAIL lines**, which buried the two tests that actually named the bug and truncated
the run's own output. A sweep should say what disagreed once, with enough of the first
mismatch to act on. Fourteen failures instead of sixteen thousand, and the one line above
is the whole diagnosis.

### AND ONE TEST FAILED BECAUSE THE TEST WAS WRONG, TWICE OVER

`TheCurveIsLinearNearZeroAndContinuousAtTheJoin` failed on first run at 1e-9 and 1e-6, and
`encodeSrgb` was right both times.

- **It is deliberately `float`, not `Scalar`.** The rest of `src/engine/` computes in
  double; this quantises a float buffer the kernel wrote, and widening it would change
  which integer a value near a rounding boundary lands on — moving every 8 and 16 bpc pixel
  AE has ever been handed, silently, for nothing. So it has to be tested at float
  tolerances, and 12.92f times 0.001f carries about 2e-9.
- **THE SRGB CURVE IS GENUINELY DISCONTINUOUS AT ITS BREAKPOINT, BY SPECIFICATION.** IEC
  61966-2-1 publishes 12.92 and 0.0031308, both rounded; the pair that actually joins is
  12.9232102 and 0.00313066844. Measured across the published breakpoint:

      below   0.0404499360
      above   0.0404511778
      jump    1.24e-06, which is 0.0003 of an 8-bit code

  Asserting the jump is zero would be asserting the standard is something it is not. The
  check is for a jump orders larger than that, which is what a wrong breakpoint or slope
  gives — and it gained a second assertion, because continuity alone does not pin the
  breakpoint: a curve linear all the way to 0.1 is continuous with itself and visibly wrong
  in the darks.

### A COMMENT THAT HAD BEEN FALSE FOR AN ENTIRE ENTRY

`fillCameraFromComp` in `AEBridge.h` was headed **"PHASE 1 STUB. The real implementation
lands in Phase 2"**. It calls `AEGP_GetEffectCameraMatrix` at line 232 and the host log in
the entry below reports `vertical fov 17.3 deg`, which checks out against a 1080 plane at
3555. The comment is the same stale claim that entry had to correct in itself, left in the
file that the correction was about.

Rewritten to say what is actually absent, which is the POSITION — `CameraConvert` zeroes the
translation on purpose because AE's world is comp pixels against an arbitrary origin. That
distinction is easy to read a "stub" label as covering.

### OIDN, MEASURED — AND THE OPEN QUESTION WAS ASKING THE WRONG THING

PLAN.md deferred this as "the weights are the question. Measure the shipped size in Phase 2
before committing to bundling them rather than fetching on first run."

**There is no separable weights file.** No `.tza`, no blob, no weights directory. They are
linked into `OpenImageDenoise_core.dll`, which is **48.3 MB** and is required whatever
device is used. So there is no bundle-the-code-only option to choose.

    minimum working set, verified to load and denoise      52.9 MB
      OpenImageDenoise_core.dll                            48.3    core + weights
      OpenImageDenoise_device_cuda.dll                       3.1
      OpenImageDenoise_device_cpu.dll + tbb                  1.3
      OpenImageDenoise.dll                                   0.2
    dropped, and verified droppable
      OpenImageDenoise_device_hip.dll                       13.8
      SYCL device + sycl9.dll + ur_*                         9.5
      bundled tools and docs                                 4.4

Checked rather than assumed: with HIP and SYCL absent the set still enumerates every RT
filter and denoises on both devices. **Against a 0.98 MB plugin that is a 53x multiplier**,
so what is left is a product decision, not a measurement — ship it, fetch it, or build from
source with only the RT filter and only the CPU and CUDA devices, which is the one route
that could shrink `core.dll` itself and costs an ISPC and TBB toolchain in the build.

### ...AND THE DENOISE COST DECIDES SOMETHING ELSE PLAN.md HAD OPEN

RT HDR with albedo and normal, 1920x1080, RTX 2070 SUPER:

| device | per frame |
| --- | --- |
| CUDA | **30.1 ms** |
| CPU | **773.8 ms** |

The render is 0.28 s at 1 sample since the majorant was tightened. So on a card the
denoiser is 11% of a Draft frame and can run every frame; **on the CPU device it is 2.8x
the entire render** and Draft would be denoiser-bound. That is the number that decides
whether the CPU device is offered at all, or whether no-GPU means no-denoise.

### WHERE THE DENOISER STOPPED, AND IT IS A BLOCKER RATHER THAN A BUDGET

`applyOutputTransform` — real EV and optional AgX — is called **inside `renderPixel`**, so
`req.dest` holds exposed, possibly tonemapped values and not linear radiance. OIDN's HDR
filter wants linear. Denoising what is in that buffer today is wrong the moment AgX is on,
and the correct order is

    kernel writes LINEAR mean  ->  denoise  ->  output transform  ->  quantise

which means lifting the transform out of the per-pixel path into a pass the caller runs once
per frame, after every band and every sample chunk. `renderPixel` stays one function, which
is what keeps a CPU golden image a check on the GPU.

**THE REASON THIS IS NOT BEING LANDED BLIND IS THE DEFAULTS.** `exposureEV` is 0 and
`agxTonemap` is false, so `applyOutputTransform` **is the identity at default settings**. A
forgotten transform pass would be invisible in After Effects on every default render, and
would first appear as "the Exposure slider does nothing" — which reads as a parameter-wiring
bug, in a different file, months later.

`tests/golden/` would catch it on the CLI paths, because the `sunset` scene renders at
`--ev 1.5` and both the CPU and GPU comparisons run it. **The AE path has no equivalent and
is the path that gains the new call site.** So the one change whose failure mode is silent
is the one change with no test, in the one place that needs the host — which is where this
stops.

### State

89 unit tests (16 new over the output conversion), 22 ctest suites, all green. No new
warnings outside the Slang prelude. The OIDN package is measured but **not wired into the
build**: no CMake change, no new dependency, nothing to install to build this tree.

### Still not done

- **8, 16 and 32 bpc in the host.** The arithmetic is now tested; what is untested is
  whether AE hands us the formats it says it will and whether the picture is right. That is
  a much smaller thing to check than it was this morning.
- **The output-transform lift, and then OIDN.** Blocked on the above, per the section above.
- **`PF_Cmd_SMART_RENDER_GPU` is still dead code.** AE reports `what_gpu=NONE`.
- **No progressive display.** A frame reaches its full sample count before AE sees anything.
- **The camera POSITION is unmapped.** Phase 3, and the comment now says so correctly.
- **The single-scatter albedo is a constant**, not a parameter — adding a field to
  `FieldParams` trips the fingerprint tripwire. Phase 3.
- **`Sky.slang` is still the Phase 1 analytic atmosphere.** The Bruneton precompute is the
  remaining Phase 2 kernel item and needs no host and no dependency.

---

## 2026-09-28 — THE MAJORANT IS 2.95x TIGHTER AND THE FRAME IS 1.7x FASTER. Nine blobs was a count, not a bound; the tightening is proved to be a change of realisation and not of answer; and the tripwire written to protect it was measured too weak and had to be rebuilt.

The previous entry called this "the next performance task and it is worth real time". It
was, and it also closed a soundness hole nobody had noticed.

    host structural majorant   0.005616  ->  0.00190258  per metre
    slack over the sampled peak   18.32x  ->  6.21x
    1920x1080 at 64 spp            ~9.7s  ->  5.7s

### Nine was the number of slots, not a bound on the sum

`cellField` sums a 3x3 neighbourhood of blobs, so nine blobs each with a ceiling of one
bounds it. That is sound, free, and wrong about the geometry: **a point cannot be inside
nine of these blobs, because the blobs are narrower than the grid they sit on.**

The count is four, and it is a theorem rather than an observation. In grid units, with a
point at fraction u along one axis of its slot:

| | |
| --- | --- |
| a blob vanishes at `kBlobFar / kCellSpacing` | = 0.4545 grid units. Its reach |
| a cell is its slot centre plus `+-kCellJitter/2` | so never nearer than `inset` = 0.1 to the slot edge |
| the slot one step UP the axis | holds every cell at least `(1 + inset) - u` away |
| the slot one step DOWN | at least `u + inset` away |

**Those two sum to 1 + 2\*inset = 1.2 whatever u is**, and both are in reach only if they
sum to under 0.909. So at most one of them is ever in reach: two offsets per axis, two
axes, four slots. That alone is 2.25x.

The remaining 1.23x is that four blobs cannot all be at their ceiling either, and the same
inequality gives it — on each axis the two reachable distances sum to at least 2\*inset, so
the worst case is a two-parameter family over a 0.1 x 0.1 square. **cellOverlapBound() is
3.2649 against nine.**

**WHICH IS A SEARCH, AND THIS FILE REFUSES TO BOUND BY SAMPLING, SO THE DISTINCTION HAD TO
BE MADE EXPLICIT.** What is searched is four smoothsteps of a distance — Lipschitz, with a
slope the function computes — not the fractal detail term. A scan of a Lipschitz function
*plus its Lipschitz slack* is an upper bound by construction; a scan of an fbm is a guess.
The slack is 0.0054 at 256 steps, and `RefiningTheCellScanDoesNotRaiseTheBound` is what
stops that being decorative.

### ...AND THE THREE DEPTH FACTORS WERE BOUNDED BY ONE EACH, WHICH WAS TRUE AND UNSOUND

`head` is a smoothstep RISING from zero at the generating level, so it is zero exactly
where `sublimation` and `tail` are largest. Bounding each by one bounds the product by one,
and the product never comes near it: **0.93 at the test parameters, 0.89 on the defaults.**

Each factor is monotone in depth, so partitioning `[0, streakLength]` and taking
`max(subl at ends) * max(head at ends) * max(tail at ends)` per interval is exact rather
than sampled — no assumption about which end, none that the partition found the peak, and
refining it can only lower the answer.

**THE HOLE THAT WAS ALREADY OPEN.** "sublimation <= 1, being exp of a negative" holds only
while the rate is positive. AE lets an expression drive any slider past its range — which
every other parameter in this file is already tested against — and at a negative rate
`exp(-rate * depth / 1000)` GROWS: 4.2x at the default streak length and a rate of -1. The
old bound omitted the factor entirely, so there it was not loose, **it was below the field
it was supposed to bound.** Evaluating the factor instead of asserting it is the fix, and
`ANegativeSublimationRateStillBounds` pins it. Verified to go red against the old
assumption.

### THE CHANGE IS A CHANGE OF REALISATION, NOT OF ANSWER, AND THAT IS MEASURED

A tighter majorant consumes random numbers differently, so every golden image moved. That
is expected and says nothing about correctness — **a majorant below the field also moves
them, and renders a quietly thinner cloud.** The two have to be told apart before the
references are re-blessed, and an absolute mean difference cannot do it: a systematic
thinning and a pile of noise both raise it.

So `--majorant` went into the CLI — `QualityParams` already documented the override as
"overridable for tests" and nothing had exposed it — and midday was rendered at 4096 spp
three ways, compared on the **signed** mean:

    new vs old bound      signed mean  -0.0004   abs mean 0.4444   brighter 11.6% / darker 12.2%
    new vs loose (0.045)  signed mean  +0.3384   abs mean 0.6948
    old vs loose (0.045)  signed mean  +0.3389   abs mean 0.6901

**The signed mean is a thousandth of the absolute mean and the sign split is even.** That
is Monte Carlo noise and nothing else: the tightened bound converges to the same image.

**THE LOOSE CONTROL SAYS SOMETHING ON ITS OWN, AND IT IS NOT ABOUT THIS CHANGE.** Both tight
majorants differ from 0.045 by the *same* +0.34 signed shift, so the loose one is the biased
member of the three. 0.045 per metre against a slab `slabRange` caps at 120 km is about 5400
expected steps into a `kTrackCap` of 1024, and TransportLib's own note says hitting the cap
returns a partial product **biased high — too much light**. Measured at +0.34, which is a
brighter render, in the predicted direction. The tightening moves away from that cliff, not
towards it.

Golden references re-blessed from the CPU path afterwards; all three GPU comparisons return
to max 0 against them.

### What it costs now, at 1920x1080 on an RTX 2070 SUPER

Same binary, same session, interleaved, `--majorant` pinned to the old bound against the
new derived one — because that is the only comparison in which nothing else can have moved.

| samples | old majorant | new derived | |
| --- | --- | --- | --- |
| 1 | 0.40 s | 0.28 s | 1.43x |
| 8 | 1.30 s | 0.84 s | 1.54x |
| 32 | 4.60 s | 2.85 s | 1.61x |
| 64 | 9.3–10.1 s | 5.64–5.72 s | 1.70x |

**THE OLD COLUMN DOES NOT REPRODUCE THE TABLE IN THE ENTRY BELOW**, which recorded 12.37 s
at 64 spp for what should be the same work. It was not re-measured at the time and the
difference is not explained — clocks, thermals or a different measurement boundary. The
ratio is the claim here, not the absolute seconds, which is why it was taken head to head
in one sitting.

**1.7x rather than 2.95x, and the gap is not a disappointment.** Expected steps are
`majorant * path length + 1` — the `+ 1` is a floor no majorant removes — and the sky, the
phase function and the camera do not scale with it at all.

### THE TRIPWIRE FOR THIS WAS WRITTEN, THEN MEASURED, AND IT DID NOT WORK

`src/engine/IceField.h` cannot include a `.slang` file, so it MIRRORS four constants —
`kCellSpacing`, `kCellJitter` and the blob's two edges — and derives a theorem from them.
A mirrored constant that drifts does not fail to compile. It lowers a majorant.

The first defence was the honest-looking one: run the KERNEL's `cellField` with
`cellDensity = 1`, densely, and require the host's bound to be above everything it finds.
`cellField` has no fbm in it, so unlike `iceDensity` it really can be sampled.

**IT PASSED A DELIBERATE 18% DRIFT.** Moving the host's `kCellSpacing` to 2.6 drops the
bound to 2.9636, and a 49-patch sweep of 784 slot neighbourhoods finds only **1.7714** —
so 2.96 still covered it and the majorant was wrong with every test green.

That is not a flaw in the sweep. It is the same floor-not-truth limit the peak-density sweep
has: reaching 3.26 needs all four cells around one slot corner to have jittered towards it,
the jitter is `hash22(o, 0u)` and therefore fixed per slot, and a few hundred neighbourhoods
do not contain that configuration. **It is still reached** — there is no seed and the sky is
millions of slots wide — which is exactly why the bound must cover the rare case and why the
sampled maximum is a floor.

So the constants are named in `GeneratorLib.slang` now, and a `cellGeometry` entry point
reads them back with the four-blob worst case **derived and evaluated in the kernel**:

    kCellSpacing   kernel 2.2    host 2.2
    kCellJitter    kernel 0.8    host 0.8
    kBlobFar       kernel 1      host 1
    kBlobNear      kernel 0.05   host 0.05
    four blobs at the kernel's own corner distance 0.31113 cell-sizes
      kernel arithmetic 3.2595   host cellOverlapBound() 3.2649

**THE FIRST VERSION OF THAT CHECK COULD NOT FAIL EITHER, AND WAS MEASURED NOT FAILING.** It
took the corner distance as a uniform and the host computed it from its OWN mirrored
constants — so a drifted host asks about a different distance, gets a consistent answer, and
agrees with itself. The 2.2-to-2.6 drift passed it. The kernel derives the configuration from
its own constants now, and the host contributes nothing but its answer.

The 0.0054 between 3.2595 and 3.2649 is the Lipschitz slack, exactly. The scan lands on its
own worst case.

**The two checks divide the work and neither subsumes the other**, which is the same argument
this file already makes about tiers: the sweep catches a wrong derivation, which exact
constants would pass; the constants catch a drifted copy, which the sweep passes until it is
enormous.

Both verified to go red on the injected drift, which named `kCellSpacing` and reported the
consequence separately.

### What is left, and why most of it is not tightenable by this argument

`slang.transport`'s cirrus section derives its own global majorant as the largest cell bound
over a 16^3 grid — **0.000944957 per metre, the tightest global bound the structural
construction can give at that resolution.** Against it:

    old host bound  5.94x
    new host bound  2.01x

So two thirds of what was left is gone and the remaining 2x is a different problem:

- **`kFbmBound` is 1.5 and that is TIGHT**, not lazy. `hash33` returns gradients in the whole
  cube `[-1,1]^3`, and `sqrt(3) * sqrt(3)/2` is attained at a lattice cell's centre. Lowering
  it means normalising the gradients, which changes the field — and therefore the look that
  passed Phase 0's verdict.
- **The occupancy is a hash.** At `cellDensity` 0.35 most slots are empty and a bound that
  does not evaluate the hash must assume none of them is. Knowing WHICH is what a majorant
  GRID is for, and SlangBridge.h's measurement still says the grid loses 7x on thin cirrus
  and wins 25x on a hard core. That is the Phase 3 convective case, not this one — and the
  tightening makes the grid-off decision *stronger*, because the global majorant it is being
  compared against is now twice as tight rather than six times as loose.

**The guard on the theorem is a `static_assert`, not a fallback.** Four slots holds only while
`2 * (kBlobFar / kCellSpacing) <= 1 + 2 * inset`. A runtime fallback to the trivial nine would
keep rendering, correctly, 2.76x slower, with nothing saying why. Breaking the build names the
file to re-read instead — the same argument as `EffectFlags.cmake`'s assert on `out_flags`.

73 unit tests (9 new over the two bounds), 22 ctest suites, all green.

### Still not done, and unchanged by this

- **8 and 16 bpc are still unexercised.** The AE run was 32 bpc throughout, so 16-bit's
  0..32768 channel range — not 65535, the classic AE trap — has never been through the real
  transport on either engine. **This change was not run in After Effects**; it is in
  `src/engine/`, shared by both paths, and the GPU golden comparisons cover it, but the host
  has not seen it.
- **`PF_Cmd_SMART_RENDER_GPU` is still dead code.** AE reports `what_gpu=NONE`, so the card is
  reached through `renderCudaToHost` inside the ordinary CPU smart render.
- **No denoiser.** OIDN is the Phase 2 item, and its install-bulk question is still deferred.
- **No progressive display.** A frame reaches its full sample count before AE sees anything.
- **The camera POSITION is still unmapped** — `CameraConvert` zeroes the translation on
  purpose, because AE's world is comp pixels against an arbitrary origin. Phase 3.
- **The single-scatter albedo is a constant**, not a parameter, because adding a field to
  `FieldParams` trips the fingerprint tripwire. Phase 3 parameter work.
- **`Sky.slang` is still the Phase 1 analytic atmosphere.** The Bruneton precompute replaces
  eight-step quadrature with two texture fetches and can be checked against what is there now.

---

## 2026-09-28 — THERE IS A CLOUD. The Slang transport reaches the pixel, both backends render it byte-identically, and the first picture was a featureless sheet for a reason worth the entry.

`Render.slang` landed and `renderPixel`'s one line changed. What comes out of the CLI is
cirrus: discrete fallstreaks with real perspective, backlit forward scatter, aerial
perspective into the horizon. The golden references are re-blessed, deliberately, and
the placeholder sky PLAN.md's Phase 2 exists to delete is gone.

### The seam, which is four lines and was the whole design question

`renderPixel` had to stay ONE function -- it is what makes a golden image taken on the
CPU a check on the GPU -- and the generated code cannot be called from it directly,
because the two targets emit different symbols and both emit them `static`.

| | |
| --- | --- |
| `Shading.h` | declares `mistytuneTrace`, calls it, knows nothing about either backend |
| `Mistytune.cu` | `#include`s the generated `Render.cu`, defines `mistytuneTrace` |
| `CpuRender.cpp` | `#include`s the generated `RenderCpu.cpp`, defines the same |
| `SlangBridge.h` | RenderRequest to the kernel's structs, ONE template, both backends |

`Render.slang` and `RenderCpu.slang` are two entry points over one `RenderLib.slang`,
and they exist separately only because slangc marks entry points `extern "C"` and both
objects land in `plugin_kernel`. `SkyLib` and `BounceLib` were split out of their
harnesses the same way `GeneratorLib` and `PhaseLib` already were.

**The marshalling is a template, not two copies.** Slang's suffixing gives every
host-visible field `_0` on both targets, so the two backends differ only in their vector
type -- which is now a three-function policy class handed to `fillSlangScene`. Two copies
of forty lines of field assignment is exactly how one backend picks up a new parameter
and the other does not.

### THE TWO BACKENDS RENDER THE SAME PICTURE, BYTE FOR BYTE

    golden.gpu.midday   max 0 (at 0,0), mean 0.0000
    golden.gpu.sunset   max 0 (at 0,0), mean 0.0000
    golden.gpu.horizon  max 0 (at 0,0), mean 0.0000

Through the ice generator, the ratio tracker, thirty-two bounces and the atmosphere --
not the analytic sky this comparison used to be about. `slang.cpuParity` measured the
two backends agreeing to 1.13e-06 on transmittance and said nothing about a whole
render; this is the whole render, and 8-bit quantisation absorbs the difference
completely.

**It holds because the RNG is bitwise identical and is asserted to be.** A 1e-06
difference in a density value can flip a delta-tracking branch, and a flipped branch is
a different path, not a slightly different one. The paths do not diverge because the
draws do not.

### THE FIRST RENDER WAS A FEATURELESS HORIZONTALLY BANDED SHEET

It looked like a transport bug. It was a frame of reference.

`buildDriftTable` integrated the ABSOLUTE wind. A generating cell is not nailed to the
ground -- it is carried by the wind at its own altitude, 34 m/s in the default profile --
so a streak drawn from the absolute integral is placed **88 km from its own head** for
2.6 km of fall. Every streak then overlaps every other one and the sky is a sheet.

The integral is relative to the generating level, and the bulk motion goes where it
belongs: `cellDriftAt`, which moves the cells themselves. `proto/index.html` reaches the
same conclusion in nearly the same words, which is the point of having kept it.

**The second bug was in the same function and was quieter.** The habit fall speeds were
invented rather than taken from the prototype: Column at 0.60 m/s against the
prototype's 1.0, which is a 67% error in the divisor of the shear integral. Fall speed
against the shear IS the streak shape. `proto/`'s `HABIT_FALL` is now copied value for
value, because the prototype is what passed the Phase 0 look verdict and is therefore
the reference rather than a starting point.

**BOTH WERE FOUND BY LOOKING AT A PICTURE, WHICH IS NOT A METHOD.** So
`tests/unit/TestIceField.cpp` is twelve tests over the shear integral, the fall speeds,
the bearing convention and the majorant, none of which need a GPU or a render.
`ZeroShearGivesZeroDrift` is the one that matters: a wind that is the same at every
level has no shear in it, so the streak hangs straight down and every knot is zero.
Verified to go red -- reintroducing the absolute integral fails it fourteen times.

### The majorant is sound and 18x loose, and that is now measured rather than assumed

`slang.generator` gained the check that joins the two tiers: the HOST's structural
majorant against the KERNEL's own sampled peak, for the same parameters.

    host structural majorant 0.005616   per metre
    sampled peak             0.00030649 per metre
    slack                    18.32x

`tests/unit/` can check that the arithmetic is what it claims; only a GPU can check that
the claim is true. Neither subsumes the other, and the sampled peak is a floor rather
than the truth -- 16 depths by 512x512 will miss the real maximum between samples, so it
catches a badly wrong bound and cannot certify a marginally wrong one.

**The looseness is nearly all the 9x cell bound and the fbm bound**, neither of which is
tightenable without a different argument. Null-collision tracking is unbiased for any
majorant at or above the peak and silently wrong below it, so loose costs steps and
tight-but-wrong costs correctness. **This is the next performance task and it is worth
real time**: 18x the steps is 18x the density evaluations, and a density evaluation is a
four-octave fbm.

### ...WHICH HAD ALREADY INVALIDATED THE TDR BUDGET, SILENTLY

The GPU band budget was 32M pixel-samples, chosen to keep a launch near a quarter second
against a display-driver timeout of about two. It was calibrated at **5 ns** per
pixel-sample, on the analytic sky.

    1920x1080 at 64 spp    12.37 s    =  93 ns per pixel-sample

**So the same constant had gone from 0.16 s a band to 3.0 s -- fifty per cent PAST the
timeout, and a TDR reset kills the CUDA context and takes After Effects with it.** The
constant did not change. The thing it was measuring did.

It is `kernel::kGpuPixelSampleBudget` now, one named constant beside the measurement,
used by both call sites that had a copy of the literal. 2M pixel-samples is 0.19 s on
this card: a tenfold margin, and still inside the timeout on a card four times slower.
The sample-split crossover moves from 1041 samples per pixel to 68.

### A generated field was renamed by an edit to a different file, again

The third occurrence, and the one that finally became a test.

`Environment.radiance` generated as `radiance_0` in `Bounce.cu` and as `radiance_2` in
`Render.cu`, because `SkyLib` joined the translation unit. `TraceResult.radiance` moved
from `_1` to `_3` the same way. Nothing about either struct changed.

A compile error is the lucky case: two fields of the same TYPE swapping suffixes between
two structs still compiles, and each then names the other struct's field.

So `Environment.radiance` is `uniformRadiance`, `Environment.mode` is `envMode`, and
`TraceResult.radiance` / `steps` are `pathRadiance` / `trackingSteps` -- and
**`slang.fieldNames` now fails the build if any host-visible struct field in any
generated source is not `_0`.** That is a property of the output, so it is checked
mechanically instead of remembered. Verified to go red: a corrupted copy reports
`Render.cu: Environment_0.uniformRadiance_2`.

**Its first version passed while testing nothing**, because `;` is CMake's list separator
and a C struct body is nothing but semicolons -- `foreach(... IN LISTS ...)` was splitting
every struct at its first field. The injected-corruption check is the only reason that
was noticed.

### What it costs, at 1920x1080 on an RTX 2070 SUPER

| samples | time |
| --- | --- |
| 1 | 0.47 s |
| 8 | 1.73 s |
| 32 | 6.26 s |
| 64 | 12.37 s |

The default is 1 sample, so a first look in AE is about a third of a second a frame.
PLAN.md's Phase 2 exit asks for this number to be written down because it is what
answers the minimum-GPU and Draft-interactivity questions -- and it is measured against
a majorant 18x looser than it needs to be, so it is a ceiling rather than a verdict.

22 ctest suites.

### IT RENDERS IN AFTER EFFECTS, and the log settled three open questions

Run in AE 2026 at 32 bpc, 12 samples, a comp camera, Quarter and Full resolution.

    PRE_RENDER: frame=480x270 request=[-48,-27 576x324] downsample=1/4,1/4 samples=12
      result_rect=[0,0 480x270]
      camera raw: err=0 distanceToPlane=3555.3 plane=1920x1080
      camera: from the comp, vertical fov 17.3 deg
    SMART_RENDER_HOST: rendered 480x270 on the GPU in 0.01 s (270 rows per band)
    ...
    SMART_RENDER_HOST: rendered 1920x1080 on the GPU in 1.86 s (91 rows per band)

**REDUCED RESOLUTION IS NOW EXERCISED AND IT IS CORRECT.** It has been on the "never
tested" list since the effect first loaded. AE asked for a 576x324 rect at 1/4, handed
back a 480x270 world, and the frame, the origin and the result rect all agree. The
camera is unharmed by the scaling because only the RATIO of buffer to frame reaches the
ray maths, which is what CloudParams.h has always claimed and nothing had checked.

**THE NEW TDR BUDGET IS DOING EXACTLY WHAT IT WAS SIZED TO DO.** 91 rows per band at
1920 wide and 12 samples is 2.1M pixel-samples, and the whole frame is 1.86 s across
twelve bands -- about 0.155 s each, an order of magnitude inside the two-second display
driver timeout. Under the old 32M constant that frame would have been ONE band of three
seconds, which is the reset this change was made to avoid.

**AND THE CAMERA IS REAL, WHICH THIS ENTRY FIRST CLAIMED IT WAS NOT.** 17.3 degrees is
what a 1080 plane at 3555.3 implies, so the conversion, the plane maths and the flags
are all live. See the corrected note below.

### ...AND IT FOUND A BUG NO RENDER COULD HAVE SHOWN

`primaryRayOrigin` is new in this change, and its first version read the camera-to-world
translation whenever `cameraFromComp` was set. That looks obviously right and is
obviously wrong here: `CameraConvert.h` ZEROES elements 3, 7 and 11 deliberately, with a
paragraph explaining that AE's world is comp pixels against an arbitrary origin while
this one is metres, and that the conversion needs a scene-scale parameter which does not
exist yet.

**So in After Effects the camera sat at altitude ZERO rather than at the observer's two
metres.** Against a cloud base of 6.4 km that moves nothing a person can see, in any
scene, at any exposure -- and the AE log does not print a ray origin. It was found by
reading the camera path to check a DIFFERENT claim in this entry.

The origin is `observerAltitude` unconditionally now, and
`TheRayStartsAtTheObserverNotAtTheMatrix` pins it with a comp camera parked at
(960, -540, -2666) converted exactly as `AEBridge.h` converts it. Verified to go red.

**The real cost of the old version was not the two metres.** It was that Phase 3 adds
the translation to `CameraConvert` for a camera that can fly, and this would have
started consuming pixels as metres the moment it did -- silently, in a function nobody
would have thought to re-read.

24 unit tests over the camera and the ice field; 22 ctest suites.

### Still not done, and the next things

- **8 and 16 bpc are still unexercised.** The host run above was 32 bpc throughout, so
  the two integer depths -- and in particular 16-bit's 0..32768 channel range, which is
  not 65535 and is the classic AE trap -- have never been through the real transport on
  either engine.
- **`PF_Cmd_SMART_RENDER_GPU` is still dead code.** AE reports `what_gpu=NONE` on every
  frame of the host run, so the card is reached only through `renderCudaToHost` inside
  the ordinary CPU smart render. That path works and is what most GPU-using AE plugins
  do; the sample-split loop behind the GPU command remains unreachable and therefore
  unverified.
- **The majorant, per above.** The largest single performance win available.
- **No denoiser.** 1024 samples still shows grain, and OIDN is the Phase 2 item that
  answers it. The install-bulk question PLAN.md defers is still deferred.
- **No progressive display.** A frame is rendered to its full sample count before AE sees
  anything.
- **The camera position is still unmapped, and I wrote the opposite here first.** This
  entry originally said "the camera is still the stub", carried forward from an older
  entry without checking. It is false: `fillCameraFromComp()` calls
  `AEGP_GetEffectCameraMatrix`, converts through `CameraConvert.h` and works -- the host
  log says `camera: from the comp, vertical fov 17.3 deg`, which checks out against a
  1080 plane at distance 3555. What is genuinely absent is the POSITION: CameraConvert
  zeroes the translation on purpose, because AE's world is comp pixels with an arbitrary
  origin and this one is metres. Flying the camera wants a real pixels-per-metre
  parameter and is Phase 3.
- **The single-scatter albedo is a constant**, not a parameter, because adding a field to
  `FieldParams` trips the fingerprint tripwire and wants hashing in the same change. That
  belongs with the Phase 3 parameter work.
- **`Sky.slang` is still the Phase 1 analytic atmosphere**, now doing a second job as the
  environment and as the sun's own transmittance at a scattering point. The Bruneton
  precompute replaces eight-step quadrature with two texture fetches and can be checked
  against what is there now.

---

## 2026-09-28 — ONE KERNEL SOURCE IS PROVED TO BE ONE. The CUDA and C++ backends agree to 1e-6, and the two structs are different sizes.

`PLAN.md`'s central bet is the transport written once and compiled to every target, and
`renderPixel` being a single function serving both engines is what makes a golden image
taken on the CPU a meaningful check on the GPU. **Nothing checked that the two backends
actually compute the same thing.** `slang.cpuParity` now does.

### The result

    RNG, 65536 draws
      differing 0 of 65536, worst absolute 0
      identical, as integer arithmetic must be

    Ratio-tracked transmittance through the ice field, 65536 rays
      mean   GPU 0.97926634   CPU 0.97926634   difference 4.52e-09
      per ray: differing 6540 of 65536, worst absolute 1.13e-06

**The RNG is bitwise identical and is asserted to be.** PCG is integer arithmetic and one
float multiply — there is no libm in it and no room for a backend to differ, so this is
the one comparison that demands equality rather than closeness. Every determinism
guarantee in the project rests on it, and it isolates the generator from everything built
on top: if it fails, nothing below it means anything.

**Transmittance agrees to 1.13e-06 in the worst single ray**, against `tests/golden/`'s
own tolerance of 2/255. That is about 250x of margin, which is what makes a CPU reference
worth having rather than merely defensible.

**Bitwise was never the claim for that half and the test does not ask for it.**
`slang.mathParity` established that Slang's CUDA output calls the same functions as
hand-written CUDA; it established nothing about the HOST compiler's libm matching the
device's, and for exp and the trig functions it will not. The bound is per-ray, not on
the mean — two backends whose errors cancelled in the mean while individual rays
disagreed would still ruin a golden image, because a golden image is compared pixel by
pixel.

It also carries a vacuity check: if the ray missed the cloud both sides would return 1.0
and agree perfectly while testing nothing, so the mean transmittance is asserted to be
neither 1 nor 0.

### THE TWO BACKENDS' STRUCTS ARE DIFFERENT SIZES, AND THE FIRST ATTEMPT MEMCPY'd THEM

    Medium_0 is 96 bytes on the CPU backend and 112 on the CUDA one

The CUDA target emits `float3`; the C++ target emits `Vector<float,3>`. They need not
agree on size or alignment and here they do not, by 16 bytes.

The first version of this test `memcpy`'d one into the other. **Every CPU ray came back
1.0 — which reads as "the ray missed the cloud", not as a marshalling bug**, and the
failure printed as a 0.338 disagreement that looked like a maths divergence. The fix is
member-by-member marshalling, and the test now prints the size mismatch when it sees one
so the next reader is told rather than left to find it.

**THIS IS A CONSTRAINT ON THE PRODUCTION PATH, NOT A TEST DETAIL.** The host will hold
one set of parameters and must marshal them into both backends' structs. Member by
member is the only safe way, and `sizeof` is not a shortcut available here.

### Why the CPU entry points have different names

slangc marks entry points `SLANG_PRELUDE_EXPORT`, which expands through `extern "C"`. So
the CUDA `transmittanceTrial` and a C++ `transmittanceTrial` are the same symbol and a
binary holding both will not link — and wrapping one in a namespace does not help,
because `extern "C"` ignores namespaces, which is the point of it.

So `CpuParity.slang` declares `cpu*` entry points over **the same library**. That is not
a weaker test than compiling one file twice: an entry point is a few lines of
marshalling, and what parity is claimed about is `transmittance`, `densityAt`,
`iceDensity` and `randFloat` — identical source text on both sides.

The phase functions have no arm here for the same linkage reason one level down: their
CUDA counterpart lives in `Phase.cu`, which cannot share a translation unit with
`Transport.cu` because both declare an `rngTrial`. Little is lost — transmittance through
the ice medium already runs exp, the fbm, the gradient noise and the PCG hashes, which is
where two libms would diverge if they were going to.

### The arrangement extended, not bypassed

`slang_generate_cpp()` mirrors `slang_generate()`: same `-fp-mode`, generated into the
source tree, committed, and compiled with no toolchain present. The CPU prelude and its
three transitive headers are vendored beside the CUDA one, and
`SlangRewriteInclude.cmake` now rewrites either.

**`slang.regenerates` covers the C++ artifact too**, and that mattered more than it looks:
a stale CPU kernel is worse than a stale GPU one, because `tests/golden/` takes its
references from the CPU. A reference blessed from maths the source no longer contains
would certify every GPU render against the wrong picture. Seven generated sources are now
checked.

### Next: the pixel

Everything the production path needs is now proved. What remains is `Render.slang` — a
camera ray, the bounce loop, the ice medium, the environment — compiled to both targets
and called by the same `renderPixel`. **That is the step that puts a cloud in After
Effects**, and it is the largest single change so far.

**THE SHAPE IT SHOULD TAKE, so the next person does not re-derive it.**

`renderPixel()` in `Shading.h` must stay ONE function. It is included by both
`Mistytune.cu` and `CpuRender.cpp`, and CpuRender's own header is emphatic that it is
"not a second renderer" — that shared function is what makes a golden image taken on the
CPU a check on the GPU. So the generated code cannot be called directly from it: the
CUDA and C++ backends emit different symbols, and both emit them `static` to their
translation unit.

The seam that preserves it is a per-target shim, one line of indirection:

| | |
| --- | --- |
| `Mistytune.cu` | `#include` the generated `Render.cu`, define `mistytuneTrace(...)` calling it |
| `CpuRender.cpp` | `#include` the generated `Render.cpp`, define the same `mistytuneTrace` |
| `Shading.h` | calls `mistytuneTrace` and knows nothing about either backend |

`renderPixel` then changes by one line — `skyRadiance(req.field, dir)` becomes the trace
— and everything around it (the frame-pixel seeding, the accumulator, the output
transform, the channel order) is untouched. All of that is carefully reasoned and none
of it should be reimplemented inside a shader.

**Two things already measured that this step must respect:**

- **Marshal `RenderRequest` into the Slang structs MEMBER BY MEMBER.** `Medium_0` is 96
  bytes on one backend and 112 on the other. A `memcpy` compiles, runs, and renders a
  wrong picture that looks like a missed ray.
- **Keep new host-visible field names unique across the whole kernel**, or slangc's
  suffixes shift under an unrelated include.

**And the golden images get re-blessed, deliberately.** The picture genuinely changes —
this is the placeholder sky that PLAN.md's Phase 2 exists to delete. Re-blessing is an
act to perform on purpose and to record here, not a side effect to absorb quietly. Bless
them only once the CLI render has been looked at and is the intended picture, because a
reference blessed from a wrong render certifies that wrong render forever.

21 ctest suites.

---

## 2026-09-28 — The transport marches real cirrus, and the majorant grid LOSES on it. Plus a naming hazard that renamed a field in a struct nobody touched.

The grid is wired to the ice generator: `GeneratorLib.slang` split out, `Medium` gained
`mode 2`, and `buildIceGrid` fills a grid from the structural bound. The measurement the
last two entries said did not exist now exists, and it does not say what was expected.

### THE GRID COSTS STEPS ON CIRRUS. 16x16x16 cells, 1582 with cloud in them:

| ray | majorant | transmittance | steps | vs global |
| --- | --- | --- | --- | --- |
| vertical | global | 0.978028 | 2.4 | — |
| | 16^3 grid | 0.977887 | 16.2 | **0.1x** |
| slant 20 deg | global | 0.964692 | 3.1 | — |
| | 16^3 grid | 0.964656 | 16.4 | **0.2x** |

Ten times slower, and the reason is arithmetic rather than a bug. A global majorant
costs `majorant * pathLength` steps; here that is 9.4e-4 per metre over 1500 m, **under
one expected collision per ray**. The grid cannot beat that, because it pays a
**traversal step per cell crossed whatever the density is** — 16 cells deep is 16 steps
before a single collision is sampled.

**So the grid pays for DYNAMIC RANGE, not for density.** It wins 25x on mode 1 — a
background with a hard core, which is a cumulus — because there the global majorant sits
far above the typical density. Thin cirrus spread through 1500 m is nearly uniform where
it exists, so the global majorant is already close to tight and there is nothing to
recover.

**AND IT QUALIFIES THE CLAIM THAT THE GRID IS A CORRECTNESS REQUIREMENT.** That claim
came from a majorant forced 100x loose by hand. With a sound structural majorant this
field runs at **2.4 steps against a cap of 1024** — nowhere near it. For this generator
the grid is an optimisation that does not currently pay, not a fix for a live defect. It
stays, because the convective generators of Phase 3 and 4 are exactly the
high-dynamic-range case it was built for, and because it is proved correct either way.

### A FIELD IN A STRUCT NOBODY TOUCHED WAS SILENTLY RENAMED

The sharpest trap in this entry, and it will recur.

slangc disambiguates identifiers with an index assigned across the **entire translation
unit**: the first `cellSize` it emits becomes `cellSize_0`, the second `cellSize_1`. Host
code binds to those exact names.

`TransportLib` started including `GeneratorLib`, whose `GeneratorInput` has a `cellSize`.
`MajorantGrid.cellSize_0` therefore became `cellSize_1`, and every host call site stopped
compiling. **Nothing about `MajorantGrid` changed. An unrelated include renamed a field
in it.**

**A COMPILE ERROR IS THE LUCKY CASE AND IS NOT GUARANTEED.** Two fields of the same type
swapping suffixes would still compile and would read the wrong memory — silently, in
generated code nobody reads. The mitigation is cheap and now applied: **host-visible
field names are kept unique across the whole kernel**, so the collision cannot arise.
`MajorantGrid.cellSize` is now `cellExtent`.

This matters well beyond the tests. `src/ae/` and `src/cli/` will bind to these structs
when the transport reaches the production path, and a rename there is a wrong picture
rather than a build failure.

### The Lib split, and the one honest difference from the other two

`GeneratorLib.slang` holds the generator; `Generator.slang` is the harness. Without it,
`TransportLib` would inherit five test kernels.

**Unlike the RNG and Phase/Transport splits, this one is NOT byte-inert**, because the
structural-bound functions sat below `densityColumn` and `densityPlane` in the original
file and slangc emits in declaration order. Gathering the library together permutes the
output. Checked properly rather than waved through: the generated file emits **exactly
the same 15 functions**, so the diff is a permutation and not a change.

### The layering question, decided

`TransportLib` includes `GeneratorLib`, so the transport knows what an ice cloud is. The
clean alternative — a generic over a density interface, which Slang supports and which
would cost nothing at runtime — is **named in the file rather than taken**, for two
reasons: PLAN.md's premise is one kernel source per target, so every density ends up in
one translation unit regardless, and `mode` is already the seam a second generator lands
behind. The point at which the generic earns its complexity is **a second consumer** of
the transport wanting a different density set — an OFX host, or a bake tool.

### The CPU arm is de-risked, and needs one thing vendored

`-target cpp` was recorded as "viable but not built" and was spiked on a much smaller
file. Re-run against the current transport, buffers and all: it emits cleanly, with entry
points as `name_Thread(ComputeThreadVaryingInput*, void*, void*)`.

It needs `slang-cpp-prelude.h` vendored beside the CUDA one, and
`SlangRewriteInclude.cmake` extended to rewrite either — both mechanical, and the same
pattern already in place.

**That is the critical path to a pixel in After Effects**, because `renderPixel` is one
function serving both engines and forking it is what the whole golden-image strategy
rests on not doing.

### Next, and it is one thing

**`Render.slang` and the production path.** A camera ray, the bounce loop, the ice
medium, the environment — compiled to CUDA for the GPU and to C++ for the CPU, called by
the same `renderPixel`. Then the golden images are re-blessed, deliberately, because the
picture genuinely changes.

20 ctest suites.

---

## 2026-09-28 — Sampled majorant bounds DELETE cirrus. The fix is a structural bound, and it is sound in all 512 cells.

The previous entry ended by naming the blocker for wiring the majorant grid to the ice
generator: `iceDensity` has no closed-form maximum over a box, so its bounds must be
sampled, and that needs "a safety margin chosen against a measurement of how badly
sampling can miss". **The measurement was taken and it does not justify a margin. It
rules the approach out.**

### The measurement, and it is not close

Per-cell maxima over an 8x8x8 grid on the real ice field, coarse sampling against a
24^3 reference, 293 cells occupied:

| samples per axis | worst miss | mean miss | cells underestimated |
| --- | --- | --- | --- |
| 2 | **infinite** | 16.584 | 100% |
| 3 | **infinite** | 8.042 | 100% |
| 4 | **infinite** | 4.074 | 100% |
| 6 | **infinite** | 2.252 | 99% |
| 8 | **infinite** | 1.691 | 99% |

**Infinite means the coarse pass found NOTHING in a cell the reference says is
occupied**, and it happens at every resolution tried. Cirrus is thin filaments in mostly
clear air — the structure the generator exists to produce, and the structure that defeats
point sampling. Even an 8^3 pass, 512 evaluations per cell, underestimates 99% of them.

**A SAMPLED BOUND OF ZERO IS THE WORST FAILURE AVAILABLE HERE, AND IT IS WORSE THAN
"SLIGHTLY THIN".** `TransportLib` treats a zero bound as proof there is nothing to
collide with: the cell is crossed in one step with no random number drawn. That is where
most of the grid's speed comes from, and it means a wrongly-zero cell is not thinned, it
is **deleted**. A safety factor cannot rescue it either — any multiple of zero is zero.

So the honest conclusion is that the previous entry asked for the wrong thing. There is
no margin to choose.

### The structural bound, which is sound by construction rather than by sampling

`iceDensity` is a product, and each factor can be bounded over a box on its own:

| factor | bounded by |
| --- | --- |
| `subl` | `exp(-k*depth)` falls with depth, so its max is at the box's SHALLOWEST depth |
| `head` | a smoothstep rising with depth, max at the DEEPEST |
| `tail` | a smoothstep falling with depth, max at the SHALLOWEST |
| `detail` | `1 + amount*1.8*fbm`, and `|fbm| <= 1.5` analytically for gradients in [-1,1]^3 |
| `cellField` | a sum of localised blobs, each maximised at the point of the box nearest its centre |

The product of the maxima bounds the maximum of the product. **It is looser than the
truth — the factors do not peak at the same point — and that is the right trade:
looseness costs steps, unsoundness costs correctness, and only one of those is
recoverable.**

Two details that are not incidental. The drift over a cell's depth range is taken as a
**box over the knots it spans, not from its endpoints**, because a veering wind means
`driftAt` is not monotonic in depth and endpoint sampling would miss the excursion. And
`cellField`'s blob distance is the **per-axis distance outside the box**, which is zero
on an axis where the centre lies within the box's span — the standard point-to-box
distance, and the reason a cell containing a blob centre gets that blob's full value.

### Measured against the real field, in every cell

    cells where the bound is BELOW the field : 0
    slack where there is cloud   mean 6.29x   worst 509.19x
    cells the sample found empty but the bound covers : 14

**Zero violations across all 512 cells.** And the last row is the point of the whole
entry: **14 cells that sampling called empty are covered by the structural bound** —
precisely the cells a sampled grid would have deleted.

**THIS IS AN INEQUALITY, NOT TWO IMPLEMENTATIONS AGREEING.** The bound is a different
computation from the density, so this is not the failure mode the phase work warned about
(two transcriptions of one paper agreeing because the same person made them). It is a
claim about the density, checked against the density.

**Verified to go red with a realistic mistake:** dropping the `detail` factor from the
bound — forgetting that it can exceed 1 — puts **42 cells** below the field.

### The cost, reported rather than hidden

Mean slack 6.29x, worst 509x. The worst case is a cell whose true content is a sliver
while the bound covers a nearby blob, and slack is exactly what `slang.transport` shows
turning into steps. It is not asserted tightly, because a product of maxima is
necessarily loose and pretending otherwise would make the test fail on an honest bound.

**The number that would decide whether 6.29x is good enough does not exist yet**, because
it needs the transport actually running on this field. That is the next step and it is
now unblocked.

### What is NOT done

**The transport still does not evaluate `iceDensity`.** Wiring it needs `Medium` to gain
a mode that calls the generator, which means `TransportLib` including a `GeneratorLib`
that does not exist yet — the Lib split has not been applied to `Generator.slang` because
nothing needed it until now. That split is mechanical and provably inert, as the other
two were; the layering question it raises (should the transport know about ice at all, or
should the density be a generic parameter) is worth deciding rather than defaulting into.

20 ctest suites.

---

## 2026-09-28 — The majorant grid: the answer holds still, the cost falls 25x, and a "disabled" feature changed the render

`src/kernel/slang/TransportLib.slang` gains per-cell majorants with an Amanatides-Woo
walk, in both estimators. This was carried as a **correctness requirement rather than an
optimisation** from two entries ago, and the reason is worth restating: null-collision
tracking is unbiased for any majorant above the true density, and the cost is the ratio
between them. A global majorant must cover the single densest point in the field, so one
sharp core makes that ratio loose along **every ray that never goes near it** — and the
iteration cap eventually turns looseness into silent bias.

### mode 1 exists because a constant slab cannot show the problem

The transport tests all ran against a constant medium, which is the one field for which a
global majorant is already tight. The 3.4x error that started this had to be produced by
forcing the majorant loose **by hand**, because mode 0 could not do it on its own.

So `Medium` gained a background plus one Gaussian core — a cumulus, not a pathological
case. **The Gaussian is chosen for a testing reason, not a physical one:** its maximum
over an axis-aligned box has a closed form (the point of the box nearest the centre), so
the grid bounds can be built **analytically and provably**, rather than sampled at some
resolution and hoped about. A sampled bound can always miss a peak between samples, and
the resulting bias looks exactly like a slightly thin cloud.

### The answer holds still and the cost collapses

Transmittance through the slab, 2.1M trials, swept across grid resolution:

| grid | transmittance | steps | vs global |
| --- | --- | --- | --- |
| none (global) | 0.778808 | 101.2 | — |
| 4x4x4 | 0.778611 | 3.9 | **25.7x** |
| 8x8x8 | 0.778328 | 7.7 | 13.2x |
| 16x16x16 | 0.778622 | 15.2 | 6.7x |
| 32x32x32 | 0.778831 | 30.3 | 3.3x |

**The grid is a free parameter exactly as the majorant is**, and that is the assertion.
The step count is reported because it is the entire case for the feature: the answer is
supposed to be identical, so a test that measured only the answer could not tell the grid
was doing anything at all.

**Most of the saving is one line.** A cell whose bound is zero is crossed in a single step
and costs no random number — there is provably nothing to collide with. It is also the
step that is catastrophically wrong if the bound is not a true bound, which is why the
construction is analytic and why the control below is permanent.

### THE SWEEP ABOVE IS THE BEST CASE, AND SAYING SO IS THE POINT

Every row there is for a ray that never approaches the core. A ray **through** the core
has to pay for density that is genuinely present:

| grid | clear of core | through core |
| --- | --- | --- |
| 4x4x4 | **25.7x** | 2.1x |
| 8x8x8 | 13.2x | 3.5x |
| 16x16x16 | 6.7x | **3.6x** |
| 32x32x32 | 3.3x | 2.5x |

**The optimum resolution is opposite for the two rays**, and both get worse at the fine
end because a fine grid pays traversal steps it did not pay before. So "finer is better"
is wrong in both directions, the cost curve has an interior optimum, and 16^3 is the
honest compromise rather than the winner of a cherry-picked row. Without the second
column the first one reads as a universal 25x speed-up, which it is not.

### Verified to go red, and the two controls catch different things

**Bounds that are not bounds.** Every stored value scaled to 0.4x — still positive, still
plausible, no longer an upper bound. Transmittance 0.904866 against 0.778808: **16% too
much light**, correctly rejected. This control is permanent, because without it the sweep
proves only that the grid is harmless, which is equally what a grid that silently did
nothing would prove.

**A broken walk.** `ddaAdvance` made a no-op, so the ray never leaves its first cell:

| | clear of core | through core |
| --- | --- | --- |
| bias | +0.16 to +0.21 | **+0.94 to +0.99** |

Through the core, transmittance goes from 0.000019 to 0.99 — the ray stops seeing the
cloud at all — and every step count pins at the 1024 cap. **The through-core arm is by far
the sharper detector**, which is the second reason it exists: a ray that never meets high
density cannot notice a bound that is wrongly low where the density is.

### A "DISABLED" FEATURE CHANGED THE RENDER, AND THE IDENTITY STILL HELD

The worst thing in this entry, and it was caught by a suite whose numbers predate the
feature.

With `enabled = 0` the bound lookup already falls back to the global majorant, so it
seemed safe to let the walk run and ignore what it found. It is not: **the walk still
chops the ray at cell boundaries**, and every boundary costs an iteration of a loop
capped at 1024. Against the 1x1x1 metre dummy grid a caller passes when it does not want
one, that caps a path at about a kilometre of travel.

`slang.bounce` noticed immediately — mean scattering events fell **4.21 to 2.79** and
every capped fraction moved:

| maxBounces | before | with the dummy walk |
| --- | --- | --- |
| 2 | 0.403963 | 0.468257 |
| 8 | 0.805689 | 0.910538 |
| 32 | 0.997921 | 0.999928 |

**And the furnace identity held exactly throughout — `|diff|` = 0 on every row.** The
estimator stayed perfectly self-consistent and simply answered a different question,
which is the hardest kind of change to see. A suite that only checked internal
consistency would have passed it.

`ddaInit` now short-circuits on a disabled grid to a single cell spanning everything, and
every number in `slang.bounce` is restored to the bit. **That is what a regression suite
whose numbers were blessed before a feature existed is for**, and it is the third time
this project has been saved by a test scene that predates the change it caught.

### What is NOT done

**The grid is not wired to the ice generator.** `iceDensity` has no closed-form maximum
over a box, so its bounds must be sampled — and a sampled bound is exactly the
unfalsifiable kind this entry went out of its way to avoid. That needs a safety margin
chosen against a measurement of how badly sampling can miss, which is its own piece of
work and is the natural next one.

**SUPERSEDED BY THE ENTRY ABOVE, AND THE ASK WAS WRONG.** The measurement was taken and
there is no margin to choose: sampling misses *whole cells* at every resolution tried, and
a bound of zero cannot be rescued by any factor. The construction is a structural bound
instead, sound in all 512 cells. Left here rather than rewritten, because "measure it
before choosing the constant" was the right instinct and it is worth seeing that the
measurement rejected the premise rather than sizing it.

20 ctest suites.

---

## 2026-09-28 — The optical-depth parameter: no divisor fixes it, and the anomaly that justified the question was a measurement artefact.

Carried from two entries ago, where the shear sweep was measured and the question was
left open. **The decision is still not taken here** — it changes what a shipped parameter
means. What is settled is the evidence it should be taken on, and one number that turned
out to be an artefact of too small a domain.

One test added (`slang.generator` gained a domain-mean conservation check); the generator
itself is unchanged, and after the measurement there is no longer a reason to change it.

### The structural finding, which narrows the options to two

The generator divides by `streakLength` so that "a vertical path through the thickest
part of a streak integrates to roughly the value on the slider". Measured, it holds at
zero shear and decays about 7x across the useful shear range.

The instinct is to find a better divisor — the streak's own path length instead of its
vertical extent. **That does not work, and seeing why settles the shape of the fix.**

`iceDensity` is evaluated per point and knows only its own parcel. But the quantity
that decays is not a property of a streak at all: it is **how much of a vertical line
lies inside any streak**, which is a property of the whole field — the tilt, the
spacing, and how many streak families a column happens to cross. No per-point divisor
can see that, so no closed-form normalisation can hold it fixed.

Dividing by the parcel path length is in fact the wrong direction. At 8 m/s against a
1 m/s fall speed the parcel travels 12 km sideways over 1.5 km of fall, so the path is
about 12.1 km against a vertical extent of 1.5 km — dividing by it would make the field
**eight times thinner** at high shear, not thicker.

So the options are only: **calibrate numerically against a chosen target**, or **rename
the parameter** so it stops promising something it cannot deliver.

### Which target, and a result that was not in the original table

Three candidate meanings, with the decay across the measured shear range. The
`mean over occupied` column is arithmetic on the published numbers (mean over all
columns, divided by the occupied fraction), not a new measurement:

| wind | thickest | mean (all columns) | occupied | mean over occupied |
| --- | --- | --- | --- | --- |
| 0 | 0.2594 | 0.0240 | 23% | 0.104 |
| 1 | 0.1575 | 0.0207 | 37% | 0.056 |
| 4 | 0.0541 | 0.0125 | 49% | 0.026 |
| 8 | 0.0376 | 0.0129 | 61% | 0.021 |
| **decay** | **6.9x** | **1.9x** | | **4.9x** |

**The domain mean is by far the most shear-stable of the three**, and that was not
visible in the original table because the occupancy column was read as a separate fact
rather than as the explanation. Occupancy rises from 23% to 61% while the thickest
column falls 6.9x: the same ice is being spread over more columns, so the integral over
the domain is nearly preserved.

### THE 1.9x WAS A MEASUREMENT ARTEFACT. Measured, and it is now zero.

The paragraph that stood here called the 1.9x unexplained and refused to guess. It is
now measured, in `slang.generator`, and the answer is that **there was never anything to
explain**: over a 40 km domain the mean is conserved under wind to better than 1%.

| wind | domain mean tau | vs wind 0 |
| --- | --- | --- |
| 0 | 0.018965 | 1.000x |
| 1 | 0.018834 | 0.993x |
| 4 | 0.018941 | 0.999x |
| 8 | 0.018923 | 0.998x |

**Why the original sweep could not see it.** The cell grid spacing is
`cellSize * kCellSpacing` = 880 m, so the 4000 m window held about 4.5 cells per axis —
roughly 20 cells, of which a third are occupied. A mean over ~7 cells is decided by
which ones happen to be in frame. Worse, the drift reaches 12 km at 8 m/s, so each wind
speed was sampling a **different patch of the field**: the comparison was between small
independent samples, not between one region displaced.

This is the same lesson as the green `determinism.gpuBands` from an earlier entry, one
tier up — **a measurement can only show what its domain is big enough to resolve**, and
a number read off too small a window is not a weak result, it is a wrong one.

The theory was right and now has evidence: wind reaches `iceDensity` only through
`source = p.xz - driftAt(depth)`, a pure horizontal displacement, and sublimation, head,
tail and the streak-length normalisation all key off vertical depth, which wind does not
change. Displacing a homogeneous field cannot change its mean. **The generator has no
bug here**, and the `max(detail, 0)` clamp I named as the suspect is exonerated.

**It also invalidates the 4.9x in the table above**, which was arithmetic on those same
noisy means. With the domain mean conserved, the mean over occupied columns must fall
exactly as occupancy rises — 23% to 61%, so **2.65x, not 4.9x**. That figure still rests
on occupancy measured in the narrow window, and occupancy is a far better-behaved
statistic than a mean of maxima, but it wants re-measuring wide before anything is built
on it.

### What the measurement changes: THE GENERATOR IS RIGHT, THE LABEL IS WRONG

With the domain mean proved conserved, the decay in the other two measures stops looking
like a defect and starts looking like the physics. **Shear really does spread cirrus
thinner** — the same ice over more sky — and a renderer whose streaks got no thinner as
the shear slider came up would be the one with the bug.

So this was never a normalisation to repair. The generator conserves what it should
conserve. What is wrong is that a control governing **total ice** is labelled with a
quantity that is read **down a single column**, and those two only coincide at zero
shear.

### The recommendation, not taken

**Calibrate, against the mean over occupied columns.** It is the quantity the
literature's 0.1–0.7 for cirrus actually describes — a property of the cloud, not of a
scene diluted with clear sky — which was the whole reason for having a physical
parameter rather than a tuned constant. At zero shear it already reads **0.104**, sitting
squarely in that band, which is a good sign the units are right.

**Not the domain mean, despite it being the stable one.** It is stable because it is the
total ice, and exposing it at a scale that matches the literature would need a 24x
rescale — at which point the occupied columns reach an optical depth of about 6, which is
not cirrus. Shear-invariance is the wrong thing to optimise for here: the invariant
quantity and the meaningful quantity are different quantities.

**And accept the residual shear dependence**, which under this target is the occupancy
ratio and nothing else. That is physical, it is now bounded rather than mysterious, and
documenting it beats calibrating it away.

**With one hard constraint on how.** The calibration is a global measurement, so it must
be computed **once on the CPU and passed to both engines as a scalar** — never
recomputed per-engine. A factor derived on the GPU for the GPU path and on the CPU for
the CPU path would have to agree bitwise or every golden image diverges, and that is a
determinism promise this project should not take on for a convenience. It also becomes
part of the fingerprint, since it is a function of the generator parameters.

Affordability looks fine: `slang.generator` runs six full sweeps of 576 columns at 2048
samples in 0.51 s, so one sweep is well under 100 ms, and a calibration grid can be far
coarser than a test grid. It reruns only when generator parameters change, which the
field cache already tracks.

**The fallback is renaming**, and it is not a bad outcome — a slider called *Density* or
*Streak Opacity* promises nothing it cannot keep. What it costs is the check against the
literature, which is the thing that makes the parameter falsifiable.

### What has to happen before this is decided

1. ~~**Measure the 1.9x.**~~ **Done** — conserved to better than 1% over 40 km, so there
   is no bug to hide. `slang.generator` now asserts it at 10%, which the 1.9x would have
   failed by a mile.
2. **Re-measure occupancy on the wide domain**, since the 2.65x above still rests on the
   narrow window that produced the artefact in the first place.
3. **Sweep the calibration target** against cell size, density and sublimation, not just
   wind — a factor that is stable in shear and wild in cell size has moved the problem.

None of this needs After Effects. **The decision itself is still open and is not mine to
take**: it changes what a shipped parameter means, and PLAN.md is explicit that parameter
identity is close to permanent once anyone else installs a build.

---

## 2026-09-28 — The bounce loop, proved by a furnace. A third prototype bug, and a build that could not configure without Slang.

`src/kernel/slang/Bounce.slang` — multiple scattering with next-event estimation,
Russian roulette, and the environment behind a seam. The last entry named its test in
advance: a furnace. That is what it got, and the identity came out sharper than
predicted.

### THE FURNACE IS EXACT, NOT STATISTICAL, AND THAT WAS NOT THE PLAN

Put a conservative medium — single-scatter albedo exactly 1, so scattering moves light
and removes none — inside a closed environment of uniform radiance L. Every point in
every direction must see exactly L. Nothing about the phase function, the density, the
path length or the majorant can change it.

The intention was to check that as a mean over many paths. It turns out to be checkable
**per path**, which is far stronger. With an ISOTROPIC phase the sampler's weight is
exactly `1.0f` — the pdf and the phase are the same expression, so the division is
`x/x`. With albedo also exactly 1, throughput stays exactly `1.0f`, roulette's survival
probability is exactly 1 and never fires, and every path returns either L or zero. So

    the shortfall below L  ==  the fraction of paths that hit the bounce cap

is an identity about individual paths, not an average. Measured, 1.05M paths through a
1000 m slab at optical depth 2.5:

| maxBounces | measured | capped fraction | shortfall | \|difference\| |
| --- | --- | --- | --- | --- |
| 1 | 0.287177 | 0.712823 | 0.712823 | **0** |
| 4 | 0.587816 | 0.412184 | 0.412184 | **0** |
| 16 | 0.957218 | 0.042782 | 0.042782 | **0** |
| 32 | 0.997921 | 0.002079 | 0.002079 | **0** |
| 64 | 0.999995 | 0.000005 | 0.000005 | **0** |
| 128 | 1.000000 | 0.000000 | 0.000000 | **0** |

Zero at every budget, which is why the assertion is at 1e-6 rather than a Monte Carlo
band. **Any leak anywhere in the loop breaks it immediately.**

**A measured answer to a parameter default, incidentally.** The mean path has 4.21
scattering events at this optical depth, 16 bounces loses 4.3% of the energy, 32 loses
0.2% and 64 loses 5e-6. The prototype's default of 32 is defensible on numbers now
rather than on taste, and **the budget is a quality setting with a known cost**, not a
safety limit.

### The droplet furnace, where the tolerance was set by measurement rather than caution

The isotropic case cannot reach the Draine lobe or the mixture sampler — it has g = 0,
so the interesting machinery is bypassed. The second furnace uses the real
Jendersie-d'Eon phase and gives up exactness to gain that coverage.

**IT LOOKED LIKE A REAL LEAK AND IT WAS NOISE, WHICH IS WORTH RECORDING BECAUSE THE
FIRST READING WAS WRONG.** At 1.05M paths the shortfall sat at 1e-4 to 6e-4 with zero
capped paths — consistent in size with the 0.9997 mean sample weight the previous entry
reports from `slang.phase`, and therefore easy to believe. At 16.8M paths:

| microns | measured | capped | shortfall |
| --- | --- | --- | --- |
| 5 | 0.999934 | 0 | 6.6e-05 |
| 20 | 0.999999 | 0 | 1.0e-06 |
| 50 | 0.999965 | 0 | 3.5e-05 |

Every residual is within one standard error of zero (about 8.5e-5 at this count).

**That is a result about the sampler and not just a tolerance.** A mean weight of
0.9997 per event, over the 1.7 events these paths average, would show a shortfall of
5.1e-4 — six standard errors above what is measured. So this test **positively excludes
a per-event deficit of that size**, which means `slang.phase`'s 0.9997 was its own Monte
Carlo floor rather than a bias in the sampler. Two tiers measuring one quantity, and
the second is an order of magnitude tighter.

The bound is 5e-4: about 7x the observed residual, tight enough that a real 3e-4
per-event leak fails it, loose enough not to flake.

### Russian roulette is a free parameter, with the control that makes the check mean something

Roulette trades variance for speed and must not move the mean. Absorbing medium (albedo
0.7), 128-bounce budget:

| | measured | mean events |
| --- | --- | --- |
| roulette on | 0.487059 | 2.67 |
| roulette off | 0.487134 | 4.20 |

Difference 7.5e-5. **The event count is the control and without it the test is
worthless** — two runs doing the same thing would agree perfectly and prove nothing. It
is asserted, not just printed.

This cannot be folded into the furnace: at albedo 1 the survival probability is exactly
1 and roulette never fires, which is the same property that makes the furnace exact.

### Next-event estimation against a closed form

Environment black, sun a delta light, budget 1 — so the only thing measured is one
next-event estimate, and a constant slab has an analytic answer for it:

    L = albedo * phase(mu) * E * exp(-tau) * (1 - exp(-tau (1-mu)/mu)) / (1-mu)

derived in the test's own header. Every factor is a different piece of code — the
free-flight distribution, the ratio-tracked shadow, the phase evaluation, the albedo —
and the majorant appears in none of them.

| mu | measured | analytic | error |
| --- | --- | --- | --- |
| 0.90 | 0.01267505 | 0.01267413 | +0.007% |
| 0.70 | 0.01144448 | 0.01145265 | −0.071% |
| 0.50 | 0.00957134 | 0.00959348 | −0.231% |

and with the real droplet phase at 20 microns, −0.071%. The majorant swept 1x to 100x
at mu = 0.7 moves it between −0.071% and +0.181% with no trend.

**`phase(mu)` IS READ OFF THE GPU, NOT REIMPLEMENTED IN C++.** Writing the
Jendersie-d'Eon fit again host-side to check the Slang one against would be a reference
implementation of exactly the kind this project does not have — two transcriptions of
one paper agreeing proves only that the same person made them. `phaseValueTrial` and
`phaseParamsTrial` exist so nothing is transcribed twice.

### THE THIRD BUG INHERITED FROM THE PROTOTYPE, AND IT IS A ONE-LINE REFLEX

`proto/index.html` starts every shadow ray one metre along the sun direction:

    cloudTransmittance(scatterPoint + uSunDir * 1.0, uSunDir)

That is the reflex every surface ray tracer teaches, because a ray leaving a triangle
will otherwise hit the triangle it left. **There is no surface here.** A null-collision
medium has nothing to self-intersect: the shadow ray starts at a point in a volume and
the estimator integrates from zero. The offset buys nothing at all, and it **skips one
metre of medium**, so every shadow returns too much light by about `exp(sigma * offset)`.

Swept, mu = 0.7, and compared against that prediction rather than merely shown to exist:

| offset | measured | vs offset 0 | exp(sigma·d) |
| --- | --- | --- | --- |
| 0 m | 0.01144448 | 1.0000x | 1.0000x |
| 1 m | 0.01147190 | **1.0024x** | 1.0025x |
| 10 m | 0.01173403 | 1.0253x | 1.0253x |
| 50 m | 0.01295020 | 1.1316x | 1.1331x |

**So the prototype's offset is +0.24% of light at every scattering event of every
path**, in this thin cirrus. It is not noise and it does not average away. The number
scales with density: the same one metre in a cumulus at sigma 0.05 would be **+5%**.

The 50 m row falls *short* of the formula, which is the formula's limit and not the
code's: for a scatter point within `offset` of the slab top the shadow origin lands
outside the medium, the formula would demand a transmittance above 1, and the estimator
correctly returns exactly 1. Asserted to 10 m for that reason.

**Three prototype bugs in three days, none of them visible to a look-based verdict** —
a sampler clamp mismatch that brightened clouds, an iteration cap that thinned them,
and now a shadow epsilon that brightens them again. Phase 0 was the right gate for the
question it asked and could not have caught any of these.

### Verified to go red, three ways, and the third one is the architecture

A green test proves nothing until it can fail.

**1. The prototype's g-clamp mismatch, restored.** `sampleHG` clamps to 0.95 while the
derived parameters stay at 0.999 — the exact bug the previous entry found.

| | `slang.phase`, per event | `slang.bounce` furnace, compounded |
| --- | --- | --- |
| 5 microns | weight 1.019 | **+3.4%** over 1.81 events |
| 20 microns | weight 1.089 | **+16.6%** |
| 50 microns | weight 1.123 | **+24.2%** |

The furnace measures the compounded consequence, which is the number that reaches a
render. **The isotropic furnace stayed green throughout**, correctly — at g = 0 the
clamp cannot bite — which is exactly why both configurations exist.

**2. Roulette without the compensating divide.** The mean moved by −2.2% and the event
control still showed 2.61 against 4.20, so the failure is attributable. The isotropic
furnace again stayed green, because roulette never fires there.

**3. THE COMPLEMENTARITY CLAIM ITSELF, WHICH IS THE ONE WORTH THE TROUBLE.**
`Bounce.slang`'s header asserts that the furnace is *structurally blind* to a path that
escapes too early — because in a furnace every escape returns L, so a premature escape
returns the right answer for the wrong reason. That is a claim about what a test cannot
do, and this project's history says an unverified claim is worse than none.

Starving `sampleFreeFlight`'s iteration cap from 1024 to 64 reproduces the previous
entry's bug class. Result:

| | |
| --- | --- |
| furnace, every budget | **`\|diff\|` = 0, measured 1.000000 at 128 bounces** |
| next-event, majorant 20x | −4.9% |
| next-event, majorant 100x | **−73.2%** |
| `slang.transport` | escape fraction wrong by +0.44 |

**The furnace is blind to it, exactly as claimed, and the majorant sweep is not.** That
is why the sweep lives on the next-event test rather than the furnace, and why neither
tier subsumes the other. Measured rather than reasoned.

### The refactor the include model forced, and it is provably inert

Slang 2026.18.3 has no `[export]`, so the previous entry duplicated the PCG generator
into `Phase.slang` and `Transport.slang` and called it "the lesser evil". **The bounce
loop ended that**, by needing both files in one translation unit — where two copies is
not duplication but a redefinition error. So the RNG moved to `Rng.slang`.

**A second collision, and this one is structural rather than incidental.** An `#include`
drags in the including file's ENTRY POINTS too, and both files declared an `rngTrial`
kernel. So the rule from here on:

| | |
| --- | --- |
| `XLib.slang` | functions and nothing else |
| `X.slang` | a harness that includes it and adds the entry points its test needs |

`PhaseLib.slang` and `TransportLib.slang` now hold the libraries; `Phase.slang` and
`Transport.slang` are the harnesses. **That is also the shape PLAN.md's "one kernel
source" requires** — the production kernel will include several Libs and declare exactly
one entry point, and it must not inherit five test kernels on the way.

**VERIFIED INERT BY BYTE COMPARISON, NOT BY READING.** The generated sources are
untracked, so `git diff` cannot answer this. Instead the pre-refactor `.slang` files
were reconstructed with the definitions substituted back in at the exact point the
`#include` now sits, and both were generated:

    Phase     : IDENTICAL to the pre-refactor generation (8363 bytes)
    Transport : IDENTICAL to the pre-refactor generation (6362 bytes)

Declaration order is why the include sits where the definition did rather than at the
top of the file — slangc emits symbols in declaration order, and moving it would have
turned a provably inert refactor into a diff nobody could read.

### THE BUILD COULD NOT CONFIGURE ON A MACHINE WITH CUDA AND NO SLANG

Found by testing the arrangement's own central claim, and it is the most serious thing
in this entry.

`cmake/Slang.cmake` `return()`s early in both the configurations it is written for —
`PLUGIN_ENABLE_SLANG=OFF`, and slangc not found — and **defined `slang_generate` at the
bottom, after both returns.** `tests/slang/CMakeLists.txt` calls it unconditionally:

    CMake Error at tests/slang/CMakeLists.txt:37 (slang_generate):
      Unknown CMake command "slang_generate"

So a fresh clone or a CI runner with CUDA and no Slang **could not configure**, let
alone build from the committed CUDA. That is precisely the scenario the committed
artifacts exist for, and the previous entry recorded it as verified both ways.

**WHY IT SURVIVED BEING "VERIFIED".** `tests/slang/CMakeLists.txt` returns early when
CUDA is absent, so the call is never reached on a machine with neither toolchain. It
needs CUDA *and* no Slang to bite — which is CI and a fresh clone, and is never the
machine doing the work. A check run on the development machine cannot see it.

The fix is the definition moved above the returns; it already no-ops internally on
`PLUGIN_SLANG_FOUND`, so nothing else about the arrangement changes. **Verified
properly this time:** a clean build directory configured with
`-DPLUGIN_ENABLE_SLANG=OFF`, built with no `Slang -> CUDA` step at all, and **19/19
ctest suites green from the committed CUDA**.

### A staleness hole the refactor opened, closed with it

`slang_generate` listed only the top-level `.slang` as a dependency. Once files share
code by `#include`, CMake cannot see through it — so **editing `Rng.slang` would have
left every generated `.cu` exactly as it was**: build succeeds, tests pass, and what
ships is the old maths. The worst failure this file can have, because the committed
artifact is the thing that ships.

The function now takes the included sources as trailing arguments and **refuses rather
than warns** on a path that does not exist, since a typo silently reintroduces the
problem the argument exists to prevent. Verified: editing `PhaseLib.slang` regenerated
both `Phase.cu` and `Bounce.cu`.

`add_custom_command`'s `DEPFILE` would remove the chance of a wrong list entirely, and
is Ninja/Makefile only — this project uses the Visual Studio generator. Recorded in the
function rather than left as a footgun.

### `slang.regenerates` DOES NOT EXIST

Three separate comments — in `cmake/Slang.cmake` twice and in
`cmake/SlangRewriteInclude.cmake` — promise that "the slang.regenerates test fails if
this file and its .slang source have drifted apart", and one of them points at a
`slang_generated_source()` function. **Neither exists anywhere in the repository.**

So the staleness of a committed generated file was guarded by nothing but the build's own
dependency rule, which is exactly what the section above had to repair. The comments are
the same failure this project keeps rediscovering: **a claim written down once and then
trusted.**

### …so it was built, and it catches the hole the section above could only patch

`cmake/SlangCheckRegenerated.cmake`, wired as `slang.regenerates`. It regenerates every
committed `.cu` into a temporary directory, applies the same prelude rewrite, and
compares. **It skips rather than fails without Slang** — the artifact exists and every
other suite compiles it, and failing here would make Slang mandatory, which is the one
thing this arrangement exists to avoid.

**WHAT IT ACTUALLY GUARDS IS THE FIX ABOVE, AND THAT IS THE POINT.** The explicit
`#include` dependency list is hand-written, and the failure mode of a hand-written list
is a forgotten name. So the two work as a pair: the list makes the build regenerate, and
this notices when the list has stopped being right.

**Verified to go red, twice, and the second one is the real scenario.** A stray line
appended to `generated/Phase.cu` is caught and named while the other five stay green.
Then the genuine case — `PhaseLib.slang` dropped from `Phase.slang`'s dependency list and
a real constant changed:

    Slang -> CUDA: .../Bounce.slang        <- regenerated, it lists PhaseLib
    (Phase.slang absent)                   <- did NOT, its list is now wrong
    --- build exit: 0 ---

    Phase: STALE -- Phase.cu does not match Phase.slang

**The build exits 0 and says nothing.** Two generated kernels compiled from one edited
source, now disagreeing about a constant, and only this test notices.

*(A first attempt at that check was confounded and is worth the line: editing the
CMakeLists to remove the dependency also dirties the custom command, so the rule re-runs
and Phase regenerates anyway. The hole only shows when the dependency list was already
wrong at the previous configure — which is exactly how it would happen in real life.)*

20 ctest suites.

### Next

- ~~**The majorant grid**, still a correctness requirement rather than an optimisation,
  and now with a second test that would see it: the next-event sweep above.~~ **Done** —
  see the entry above. The answer holds still across grid resolutions and the cost falls
  up to 25x. Not yet wired to the ice generator, which needs sampled bounds.
- ~~**The optical-depth-versus-shear decision**, still open from two entries ago.~~ The
  evidence is now in and **the decision is still open**: the anomaly that motivated it
  turned out to be a measurement artefact, and the generator has no bug. See the entry
  above for the recommendation.
- **The atmosphere behind the `Environment` seam**, which is what makes
  `includeSunDisc` live and turns the double-counting hazard from a wired-up argument
  into something a test can reach.

---

## 2026-09-28 — The Slang bet, settled by measurement. It is a GO, with one condition.

PLAN.md asks for the transport written once in Slang and compiled to PTX for CUDA and
Metal for macOS, and says plainly that **the decision point comes before any generator
is written, not after six**. Nothing had tested it. Slang was not installed, not
vendored, and had no build wiring.

Spiked against Slang **2026.18.3** (windows-x86_64), downloaded to a scratch directory
rather than the repo, because a bet that fails should leave nothing behind.

### What was measured, in the order it mattered

**1. All three targets emit.** `-target cuda`, `-target ptx`, `-target metal` all
produced output from one source.

**2. The CUDA output is ORDINARY CUDA, which was the real worry.**

    extern "C" __global__ void computeMain(SkyParams_0 params_0,
                                           RWStructuredBuffer<float3> output_0,
                                           int width_0)

Parameters by value as ordinary kernel arguments, CUDA's own `float3`/`make_float3`,
no Slang-specific uniform blob to marshal. `RenderRequest` can be passed the way
`Mistytune.cu` passes it today, and the launch shim, the band split, the abort check
and the accumulator all survive unchanged. The .cu stays what its own header says it
is: a launch shim.

**3. IT COMPILES UNDER THIS PROJECT'S DETERMINISM FLAGS**, exit 0, with
`--fmad=false --prec-div=true --prec-sqrt=true -std=c++17`. That is the reason to take
CUDA SOURCE rather than PTX: nvcc still applies our flags. Emitting PTX would put
contraction and division precision beyond our control, and those flags are exactly what
tests/golden/ exists to protect.

Cost: Slang's prelude uses CUDA 13's deprecated `longlong4`/`ulonglong4`/`double4`, so
the build needs `-diag-suppress 1444` and `/wd4996`. Noise today; a build break the day
anyone adds `/WX`.

**4. THE NUMBERS ARE BIT-IDENTICAL.** Every transcendental the renderer actually calls
-- counted out of Shading.h as expf x16, sqrtf x5, cosf x3, sinf x2, tanf, rsqrtf,
exp2f -- evaluated through Slang and through hand-written CUDA over **44,001 inputs**,
compared as raw bit patterns:

    exp  0 differing    sqrt 0 differing    cos  0 differing    sin 0 differing
    tan  0 differing    rsqrt 0 differing   exp2 0 differing

**That is the result the bet turned on, and it is stronger than "close enough".** A
faithful Slang port of the transport reproduces the CPU reference BY CONSTRUCTION,
because the primitives are literally the same functions. The port did not have to be
written to find that out -- which also means a divergence found later is a transcription
error, not a Slang problem, and that is a much easier thing to debug.

### THE CONDITION, AND IT IS NOT A FORMALITY

`-fp-mode fast` must never be passed. Slang's backend then emits
`SLANG_CUDA_ENABLE_FAST_MATH=1` and the prelude redirects to the approximate `__expf`
family. Measured, same 44,001 inputs:

| | differing | worst absolute difference |
| --- | --- | --- |
| exp | 36,886 | **4.12e11** |
| tan | 43,688 | 2812 |
| cos | 42,465 | 9.9e-06 |
| sin | 42,496 | 9.3e-06 |

sqrt, rsqrt and exp2 stay precise -- they have no fast intrinsic to redirect to -- which
is what makes this dangerous rather than obvious: **the flag breaks some functions and
not others**, so a render with it on looks nearly right and the golden tests would catch
it only where exp happens to dominate.

It is off by default. It needs to be off *on purpose*, which means a build that asserts
it rather than a comment asking for it.

### The verdict

**GO.** The integration friction is low, the determinism story is intact, and the
alternative -- PLAN.md's macro shim -- buys nothing that this does not, while costing
the Metal path in Phase 5.

### The arrangement that was built on the back of it

**THE GENERATED CUDA IS COMMITTED. SLANG IS NEEDED TO REGENERATE IT, NEVER TO BUILD.**

That is the decision, and the obvious alternative -- run slangc as a build step -- is
what most projects do and is wrong here. A shader compiler decides the bits in every
golden image, so making it a build dependency means every machine needs the right
VERSION of it or the golden suite fails for reasons unrelated to the change being
tested. It also means CI, a fresh clone, and anyone fixing a typo in the host code all
need a 147 MB download.

Committing the generated .cu costs a file in review and buys builds that work with no
toolchain, a diff that SHOWS what a shader edit did to the generated code, and a bisect
that compiles at every commit.

| | |
| --- | --- |
| `cmake/FetchSlang.cmake` | standalone fetch, version and SHA256 pinned. NOT part of configure -- a configure that reaches the network fails in CI and on an aeroplane, for a tool most builds do not need. |
| `cmake/Slang.cmake` | optional discovery, mirroring `Cuda.cmake`. Reports the version, because a compiler upgrade is a change to the output bits. |
| `cmake/SlangRewriteInclude.cmake` | makes the output portable enough to commit |
| `src/kernel/slang/prelude/` | the vendored prelude, Apache-2.0 WITH LLVM-exception -- the licence written for exactly this, a support header emitted into someone else's build output |
| `tests/slang/` | the parity test, permanent |
| `tools/slang/` | gitignored; 147 MB of prebuilt binaries is not a thing to put in git |

**TWO THINGS LEAKED THE GENERATING MACHINE INTO THE OUTPUT**, and both had to go or
the committed file differs per developer and the staleness check fails for everyone
except whoever last regenerated it:

- `#line` directives carrying absolute source paths -- killed with
  `-line-directive-mode none`.
- The prelude `#include`, which slangc writes as an absolute path to wherever the
  toolchain lives -- rewritten to a relative one, and the rewrite REFUSES rather than
  passing silently if slangc's output shape ever changes. A generated file that
  compiles only on the machine that made it is the worst kind of build bug, because it
  reproduces for nobody who could fix it.

**`slang.mathParity` is permanent, and verified to go red.** Regenerating with
`-fp-mode fast` fails it with the exact signature its own diagnostic predicts -- exp
and the trig functions moved, sqrt/rsqrt/exp2 did not. It needs CUDA but NOT Slang,
because it compiles the COMMITTED artifact: it guards what ships rather than what
generates it, and so it also catches a regeneration made with the wrong flags and
committed by accident.

14 ctest suites. The whole arrangement was verified both ways -- configured and tested
green with Slang absent, then again with it present and regenerating.

**One CMake trap worth the line it costs.** `set(PLUGIN_SLANGC "")` as tidy
initialisation made the search appear to fail on a machine with slangc sitting exactly
where the hint pointed: `find_program` writes a CACHE entry and a normal variable of
the same name shadows it. Also, `find_program` does not normalise a hint containing
"..".

### The port, done and proved bit-exact

`src/kernel/slang/Sky.slang` is `skyRadiance()` and its helpers -- the ray-sphere
algebra, the quadratic marches, the sun optical depth, the ground and the sun disc --
transcribed from Shading.h.

**A TRANSCRIPTION, NOT A REWRITE, AND THE EXPRESSION STRUCTURE IS PRESERVED EVEN WHERE
IT LOOKS REDUNDANT.** Floating-point addition is not associative, so every tidy-looking
reassociation is a chance to be off by a bit.

`slang.skyParity` runs both versions **on the same GPU, in the same build, under the
same nvcc flags**, over 14,449 directions -- 0.1-degree elevation steps through the
horizon band at eight azimuths, plus a ring of near-misses around the sun's limb. So
nothing it reports can be blamed on CPU-versus-GPU or on a flag.

    14449 directions, 0 differing channels of 43347 -- identical

First run, no debugging. That is what slang.mathParity buys: with the primitives
proved identical, a faithful transcription is bit-exact or it is mistyped, and there
is no third possibility to investigate.

**Verified to go red, with the exact mistake the file warns about.** Changing
`sumR * betaR * phaseR` to `sumR * (betaR * phaseR)` -- a pure reassociation, the kind
of "harmless tidy-up" a future editor makes without thinking -- moves **6,435 of 43,347
channels**. Worst absolute difference **4.77e-07**, at 1.9 degrees elevation: in the
horizon band, where the hard cases were always going to be.

**That 4.77e-07 is the case for comparing bitwise.** It is orders of magnitude below
anything tests/golden/ could see at 2/255. This tier catches what that tier cannot,
which is the only reason to have it.

### What was DELIBERATELY not done: the production kernel still uses Shading.h

The obvious next move is to point the shipping GPU path at the Slang sky. It was not
made, and the reason is structural rather than caution.

`renderPixel()` is ONE function serving both engines -- that is the arrangement that
makes a golden image taken on the CPU a meaningful check on the GPU, and CpuRender.cpp
is emphatic that it is "not a second renderer". Switching only the GPU's sky to Slang
means forking `renderPixel`, which buys nothing for a **placeholder sky that Phase 2
deletes** and costs the property the whole test strategy rests on.

The value of this work was never migrating the placeholder. It is that **the real
transport gets written in Slang**, with the pipeline proved and guarded before a line
of it exists -- which is exactly what PLAN.md means by deciding before any generator is
written. Both paths switch together when the transport lands and the CPU reference
starts consuming the `cpp` target.

`Sky.slang` is not dead code in the meantime: `slang.skyParity` fails the moment it and
Shading.h drift apart, so it stays honest without being shipped.

### The CPU arm, established as viable but not built

Slang's `-target cpp` emits a callable entry point taking `ComputeThreadVaryingInput`
-- two uint3s -- so CpuRender.cpp can call the SAME generated maths per pixel. That is
what closes the loop to genuinely one source for CUDA, C++ and (Phase 5) Metal.

`[export]` is not available in 2026.18.3, so plain-function libraries are out and the
entry point has to be a kernel in every target. That is a shape constraint on the port,
not a blocker.

### The transport starts: phase functions, and a REAL BUG INHERITED FROM THE PROTOTYPE

`src/kernel/slang/Phase.slang` -- Henyey-Greenstein, the Draine lobe, the
Jendersie-d'Eon mixture, the ice placeholder, and the importance sampler for all of
them. Ported from `proto/index.html`.

**THE VERIFICATION HAD TO CHANGE SHAPE, AND THAT TURNED OUT TO BE THE POINT.**

The sky port could be proved bitwise because Shading.h was a target to diff against.
The transport has no C++ twin -- its reference is a GLSL shader in a browser -- so a
transcription error here cannot be caught by comparison. It has to be caught by the
identities a correct phase function obeys:

1. **A phase function integrates to 1 over the sphere.** Quadrature, 4.2M points.
2. **The mean returned sample weight is that same integral.** `samplePhaseDir` returns
   phase/pdf, and the expectation of phase/pdf over the pdf is exactly the integral --
   so a sampler drawing from anything other than its stated pdf shows up here while
   the quadrature stays perfect.

Identity 2 is the one that earns its keep, and it immediately failed.

    microns     integral  mean weight
        5.0     1.000014     1.018845
       12.0     1.000075     1.066672
       50.0     1.000406     1.123231

The phase functions normalised perfectly. The sampler did not agree with its own pdf,
and **the error grew smoothly with droplet diameter** -- which is what named the cause.

**`sampleHG` clamps g to +-0.95; the pdf evaluates `hg()` at the UNCLAMPED g.** For
every droplet diameter the Jendersie-d'Eon fit is valid for, `hgG` runs from 0.971 at
5 microns to 0.998 at 50 -- so the clamp ALWAYS bites, the sampler always draws from a
broader lobe than the pdf claims, and the discrepancy tracks hgG's approach to 1
exactly as measured.

**This bug is in the prototype**, in the same shape, and it survived the Phase 0 look
verdict because it does not look like a bug. Throughput is multiplied by 2-12% too
much at every scattering event, compounding across a thirty-bounce budget -- roughly
1.9x too much light after ten bounces at 50 microns. It renders as a cloud that is too
bright and too flat, which reads as a lighting choice.

**The fix is one bound where the parameters are DERIVED**, so the sampler and the pdf
cannot be handed different numbers; `sampleHG` clamps to the same constant, which makes
it a no-op for anything derived and still guards a hand-set value. Raised to 0.999 from
0.95 while doing it: HG sampling is exact for any |g| < 1, and 0.95 was discarding most
of the forward peak the fit exists to describe.

    after: mean weight 0.9997 at every diameter, against an integral of 1.0000

**Max weight is 1.65-1.84**, bounded, matching the prototype's own predicted "around
1.8" -- so the firefly mechanism its comments describe is not present.

### The ice placeholder, measured rather than assumed

`phaseIce` adds a 22-degree halo on top of an already-normalised mixture, so it does
not conserve energy. Everyone knew that; nobody had the number.

    integral 1.051092  -- the halo invents 5.1% extra light
    mean weight 1.051514, max 2.1551

The mean weight matches the integral to 4e-4, so **the ice sampler is self-consistent
even though the function is not normalised** -- which is the right state for a
placeholder and is now asserted rather than hoped. The test bounds the excess instead
of demanding 1, so it catches a halo that gets dramatically brighter without pretending
Phase 4's work is already done.

16 ctest suites.

### Null-collision transport, and a SECOND bug the identities caught

`src/kernel/slang/Transport.slang` -- delta-tracked free flight and ratio-tracked
transmittance, with the medium behind a seam so the ice generator can land there next.

**THE MAJORANT SWEEP IS THE TEST.** Null-collision tracking's whole promise is that
the majorant -- any upper bound on density -- is a free parameter: it changes how long
the estimator takes and nothing about the answer. So the check is not "is this
number plausible", it is:

1. In a constant-density slab, transmittance equals `exp(-sigma * d)` exactly.
2. The free-flight distance is exponentially distributed with rate sigma.
3. **Neither answer moves when the majorant does.**

Checking one majorant would have passed. Sweeping it is what made the check mean
anything -- and it failed at 100x.

    1000 m slab, optical depth 2.5, analytic exp(-tau) = 0.082085

      majorant     measured (before)
        1x sigma    0.082292
       20x sigma    0.082124
      100x sigma    0.276252      <- 3.4x too much light

**THE ITERATION CAP WAS A CORRECTNESS LIMIT WEARING A SAFETY NET'S CLOTHES.** The
expected number of steps is `majorant * pathLength`, every one a null collision when
the majorant is loose. The prototype's 128 was too low by a factor of eight: hitting
the cap `break`s and returns the PARTIAL product, with the not-yet-accumulated
attenuation simply missing.

The free-flight loop had the same defect in the opposite direction -- 0.28% of rays
escaped that should have scattered, biasing towards a THINNER cloud. **The two do not
cancel.**

Raised to 1024, which covers about 400x sigma at that thickness. After:

      100x sigma    0.082087   against analytic 0.082085

**This is the second bug inherited from the prototype in two days, and both were
invisible to a look-based verdict.** A too-bright cloud reads as a lighting choice; a
too-thin one reads as a density slider set low. Neither would ever have been found by
comparing pictures, which is what Phase 0 was for and is exactly what Phase 0 could
not do.

**Why it only shows with a loose majorant** -- and therefore why it will show in
practice: a global majorant has to cover the single densest point in the field, so one
sharp peak makes the ratio loose EVERYWHERE ELSE. That is the ordinary case for a
cumulus with a hard core, not a pathological one.

**THE REAL FIX IS LOCAL MAJORANTS** -- a coarse grid of per-cell bounds instead of one
global number -- which is the standard performance fix for the same reason it is the
correctness fix: it keeps the ratio near 1 everywhere, so the cap is never approached.
Raising the cap converts a silent bias into a visible slowdown, which is the right way
round, but it is a holding action. **The majorant grid is now a Phase 2 requirement
rather than an optimisation.**

### The RNG is duplicated, and pinned by test

Slang 2026.18.3 has no `[export]`, so a shared module would be pulled in by `#include`
and each generated .cu would carry its own copy regardless. The PCG generator is
therefore stated in both `Phase.slang` and `Transport.slang`. If those ever disagree,
every determinism guarantee in the project goes with them -- so both expose an
`rngTrial` entry point and the test pins one against the other.

17 ctest suites.

### The generator, and a THIRD thing the prototype could not have survived

`src/kernel/slang/Generator.slang` -- `cellField`, `driftAt`, `iceDensity`,
`gradientNoise`, `fbm`.

**THE HASHES ARE NOW INTEGER, AND THAT IS A CORRECTNESS CHANGE.**

The prototype uses `fract(sin(p) * 43758.5453123)`, the classic GLSL sin-hash. Fine in
a browser, on one GPU, for a look verdict. Measured sensitivity to a ONE-ULP change in
its input:

| grid coord | hash(x) | hash(x + 1 ulp) | difference |
| --- | --- | --- | --- |
| 17.3 | 0.325256 | 0.326319 | 0.001064 |
| 128.0 | 0.561327 | 0.098675 | 0.462652 |
| 1024.0 | 0.809906 | 0.084025 | **0.725881** |
| 65536.0 | 0.777520 | 0.086796 | 0.690725 |

At a grid coordinate of 1024 a single last-bit change moves the hash from 0.81 to
0.08. The function is chaotic in its lowest input bit -- which is what a hash should
be, and exactly what makes it unusable here.

**PLAN.md's premise is one source compiled to CUDA AND METAL.** `sin()` of a large
argument is where vendors differ, because it is argument reduction rather than the
core polynomial, and they will differ by an ULP somewhere. Amplified by 43758 and
wrapped by `fract`, that ULP becomes a different number entirely: the cells land in
different places and **the same comp renders a different cloud on Mac and Windows**.
tests/golden/'s own header names cross-platform float divergence as the thing that
tier exists to catch; this would have defeated it at the first hurdle.

**The fix is free**, because every hash input here is an integer lattice coordinate --
`floor(g)` in cellField, `floor(p)` in gradientNoise. PCG2D/PCG3D are exactly
reproducible on every platform by construction, cost about the same, and are of better
statistical quality. The noise realisation changes; the STRUCTURE the Phase 0 verdict
was about -- discrete cells, jittered slots, the spacing that leaves clear lanes --
is preserved exactly.

### The optical-depth parameter is a LOW-SHEAR claim, now measured

The generator divides by streak length so that "a vertical path through the thickest
part of a streak integrates to roughly the value on the slider" -- which is what makes
the parameter checkable against the literature's 0.1 to 0.7 for cirrus.

The first run of the test measured 0.038 against a parameter of 0.45 and looked like a
port bug. It is not. **The normalisation divides by a VERTICAL extent, and a fallstreak
is not vertical.** At 8 m/s of wind against a 1 m/s fall speed a parcel drifts 12 km
sideways over 1.5 km of fall, so a vertical column crosses many streaks and spends most
of its length in the clear lanes between them.

Swept, at parameter 0.45:

    wind    shear     thickest         mean   occupied
     0.0      0.0       0.2594       0.0240        23%
     1.0      1.0       0.1575       0.0207        37%
     4.0      4.0       0.0541       0.0125        49%
     8.0      8.0       0.0376       0.0129        61%

So the claim holds where it is made -- at zero shear, 0.26 against 0.45, within the
"roughly" it promises -- and **decays by about 7x across the useful shear range**. The
test asserts it only at zero shear and reports the decay, rather than failing for
something that is not a bug.

**This matters for the UI, not just the test.** A parameter labelled "optical depth"
that delivers a seventh of its value once the shear slider is up is a parameter that
has quietly stopped meaning anything -- and shear is the hero control of this
generator. Either the normalisation should follow the streak's own path length rather
than its vertical extent, or the parameter should be renamed. **That is a design
decision, recorded here rather than silently patched.**

Also measured, because slang.transport needs it: **peak density 3.06e-4 per metre**,
at 141 m below the generating level. That is the floor a majorant estimator has to
clear, and the transport work shows what it costs to be much above it.

18 ctest suites.

### Next

- **The bounce loop**: multiple scattering with next-event estimation. Its identity is
  a FURNACE TEST -- a conservative medium (albedo 1) inside a uniform source must
  return exactly the source. That catches an energy leak in multiple scattering the
  way the majorant sweep catches one in the tracker.
- **The majorant grid**, now a correctness requirement rather than an optimisation.
- **The optical-depth-versus-shear decision** above.

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

- ~~**A high sample count in the host.** Everything above the crossover is untested in
  AE: whether the progress bar moves, whether cancel is responsive, and whether the
  driver timeout is genuinely avoided at 2048+ samples.~~ **Driven, and it passed** —
  see the correction below.
- ~~**A Region of Interest**, still the only way to drive a non-zero `output_origin`.~~
  **Driven in the same session**, and it found the defect this entry opens with.

**CORRECTED 2026-09-28, from `%TEMP%\mistytune.log` rather than from memory.** Both
bullets were done in the session immediately after this entry was written, and neither
was struck — the same stale-claim pattern this file keeps rediscovering, this time by
leaving a finished item on a to-do list:

| | |
| --- | --- |
| 1920x1080 @ 1045 spp | 9.17 s, 16 rows per band |
| 555x576 @ 2048 spp | 3.48 s, 29 rows per band |
| **1920x1080 @ 2048 spp** | **17.58 s, 16 rows per band, no driver reset** |

17.58 s against a display-driver timeout of about two seconds is the launch split doing
exactly the job it was built for. **Cancel is responsive mid-frame**, not merely
between frames:

    aborted at row 500 of 576, sample 241 of 241, after 0.30 s

**What the log cannot answer, and so remains open:** whether the progress bar visibly
moves during that 17 s. That is an eyeball check and nothing else can make it.

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
