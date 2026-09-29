#pragma once

// THE PARAMETER MODEL, and the only definition of it.
//
// Host-free by design, like everything in src/engine/. The AE effect fills these
// structs from checked-out parameters; src/cli/ fills them from a scene file;
// proto/ mirrors them as shader uniforms under the same names. One definition is
// what makes a golden image comparable between the CLI and the host, and what
// makes the Phase 0 -> Phase 2 port a transcription rather than a redesign.
//
// ---------------------------------------------------------------------------
// THE SPLIT IS LOAD-BEARING, and it is not about tidiness.
//
// FieldParams is everything that decides WHAT IS IN THE SKY. ViewParams is
// everything that decides WHERE IT IS SEEN FROM. The field cache is keyed on a
// hash of the first and ignores the second, which is what makes a camera move
// cheap: PLAN.md is blunt that camera-only changes triggering a field rebuild is
// the difference between a plugin people use and one they abandon.
//
// So: a value goes in FieldParams if changing it changes the medium, and in
// ViewParams if it only changes the ray that looks at the medium. When in doubt
// it goes in FieldParams -- a redundant rebuild is a slow frame, while a missed
// rebuild is a wrong image the user cannot explain.
// ---------------------------------------------------------------------------
//
// UNITS ARE SI AND METRIC THROUGHOUT -- metres, seconds, kelvin, degrees for
// angles. Not comp pixels: the whole point of a physical model is that the
// numbers mean something, and cloud base at 1200 m is a fact about the sky while
// cloud base at 340 px is a fact about a comp.

#include "Types.h"

#include <cstdint>

namespace plugin::cloud {

// Everything is float rather than Scalar (double). These structs cross to the
// GPU verbatim as a kernel argument block, and the kernel is float -- so
// declaring them double here would mean a conversion pass whose only effect is
// to hide which precision the render actually ran at.
using Real = float;

// ---------------------------------------------------------------------------
// Physics
// ---------------------------------------------------------------------------

// HOW FAR FROM EARTH THE USER MAY GO.
//
// The Physics tab is the proof that the model is a model rather than a noise
// stack, so it has to be real. It is also the fastest way to make a realism
// buyer distrust the plugin, which is why Earth is the default and the alien
// skies live in a clearly labelled demo group -- PLAN.md settles this.
enum class PhysicsClamp : int32_t {
    Earth     = 0,   // constants pinned; the sliders are readouts
    EarthLike = 1,   // +/- a plausible fraction of each Earth value
    Unbound   = 2    // anything the maths survives. Here be alien skies
};

// The planet and its air.
//
// GRAVITY AND SCALE HEIGHT ARE NOT INDEPENDENT in reality -- scale height is
// RT/(Mg) -- but they are separate parameters here on purpose: a user who halves
// gravity to see taller convection should not silently also get a different
// atmospheric thickness they did not ask for. Under the Earth clamp both are
// pinned to the real values, so the coupling only matters where the user has
// explicitly said they want it not to.
struct PhysicsParams {
    PhysicsClamp clamp = PhysicsClamp::Earth;

    Real gravity          = 9.80665f;   // m/s^2
    Real scaleHeight      = 8500.0f;    // m -- density e-folding height
    Real surfacePressure  = 101325.0f;  // Pa
    Real surfaceTemp      = 288.15f;    // K
    Real lapseRate        = 0.0065f;    // K/m, environmental
    Real planetRadius     = 6371000.0f; // m -- sets horizon curvature

    // Relative humidity at the surface, 0..1. Drives condensation level, which
    // is where a flat-based cloud's base goes -- and the flat base is one of the
    // things that reads as "photographed" rather than "generated".
    Real surfaceHumidity  = 0.7f;
};

// ---------------------------------------------------------------------------
// Atmosphere and light
// ---------------------------------------------------------------------------

// The precomputed-atmosphere inputs: Rayleigh and Mie coefficients, the sun, and
// the ground under it.
//
// SUN ANGULAR RADIUS IS A PARAMETER AND NOT A CONSTANT because it is what makes
// a shadow edge soft, and the softness of a cloud's shadow edge is a large part
// of how big the cloud reads as being. 0.266 deg is the Sun from Earth.
struct AtmosphereParams {
    Real sunAzimuth       = 135.0f;   // degrees, clockwise from +Z
    Real sunElevation     = 12.0f;    // degrees above the horizon
    Real sunAngularRadius = 0.266f;   // degrees
    Real sunIntensity     = 1.0f;     // multiplier on the physical irradiance

    // Aerosol load. Rayleigh is fixed by the air itself; Mie is what haze,
    // dust and humidity add, and it is the knob that turns a hard blue sky into
    // a milky one.
    Real turbidity        = 2.2f;     // Linke, 1 = pristine
    Real mieAnisotropy    = 0.76f;    // Henyey-Greenstein g for the aerosol

    Real groundAlbedo     = 0.1f;     // 0.1 land, 0.06 ocean, 0.8 snow

    // Whether cloud shadows are cast into the atmospheric medium itself, which
    // is what produces crepuscular rays and what makes a cloud deck sit IN the
    // air rather than in front of it.
    bool cloudShadowsInMedium = true;
};

// ---------------------------------------------------------------------------
// The ice / fallstreak generator -- the first one, per PLAN.md
// ---------------------------------------------------------------------------

// Crystal habit. NOT cosmetic: habit sets fall speed, and fall speed against the
// shear profile IS the streak shape. It also selects the phase function, which
// is what produces 22 deg and 46 deg halos, sundogs and pillars -- the thing a
// spherical-droplet model cannot reach at all.
enum class IceHabit : int32_t {
    Plate      = 0,   // slow, horizontally oriented: pillars and 22 deg
    Column     = 1,   // faster, randomly oriented
    Bullet     = 2,   // rosettes; broad forward lobe
    Dendrite   = 3,   // slowest, most diffuse
    Aggregate  = 4    // mixed habit, no preferred orientation
};

// One height-indexed shear sample. The curve is THE hero control of the ice
// generator -- it is the streak shape, not a modifier on it.
//
// PHASE 2 SHIPS A FIXED SET OF THESE AS SLIDERS, smoothly interpolated, because
// the AE SDK ships no curve control and no sample of one. The real curve editor
// is an arbitrary-data parameter with custom UI, sized honestly as its own
// Phase 4 task. The data shape does not change when the editor arrives, so
// nothing downstream has to.
constexpr int kShearKnots = 6;

struct ShearProfile {
    // Wind speed at each knot, m/s, knot 0 at the generating level and knot
    // kShearKnots-1 at the bottom of the fall streak.
    Real speed[kShearKnots]   = { 34.0f, 30.0f, 25.0f, 19.0f, 13.0f, 8.0f };
    // Wind direction at each knot, degrees. A TURNING wind is what makes a
    // fallstreak hook rather than trail, which is the difference between
    // cirrus fibratus and cirrus uncinus.
    Real bearing[kShearKnots] = { 270.0f, 268.0f, 264.0f, 258.0f, 250.0f, 240.0f };
};

struct IceParams {
    bool enabled = true;

    // WHERE THE CRYSTALS ARE MADE. Generating cells are discrete: crystals are
    // born in them and then fall, which is why detail is ADVECTED along the flow
    // and re-seeded at the cells rather than sampled from a noise field. Noise
    // sampled per-point gives streaks that shimmer instead of flowing, and that
    // is the single most common tell of a procedural cloud.
    Real cellAltitude   = 9000.0f;  // m, the generating level
    Real cellDensity    = 0.35f;    // cells per km^2, 0..1 normalised
    Real cellSize       = 900.0f;   // m, horizontal extent of one cell
    Real cellStrength   = 1.0f;     // crystals produced per cell

    IceHabit habit      = IceHabit::Column;
    // Fall speed multiplier ON TOP of the habit's own. The habit sets the
    // physical speed; this is the artist's override, and it stays in real units
    // so the number still means something.
    Real fallSpeedScale = 1.0f;

    ShearProfile shear;

    // How fast a crystal shrinks as it falls into drier air below. This is what
    // gives a fallstreak an END -- without it every streak reaches the ground
    // and the sky looks combed.
    Real sublimationRate = 0.55f;    // fraction of mass lost per km fallen
    Real streakLength    = 2600.0f;  // m, the fall distance before it is gone

    // Optical depth scale for the whole layer. Ice is optically thin and near
    // single-scatter, which is exactly why it is the cheapest generator to
    // render and the right one to prove the approach on.
    Real opticalDepth    = 0.45f;

    // Advected detail: how much fine structure rides along the flow, and how
    // fine. Amplitude 0 gives smooth ribbons; 1 gives the fibrous look the
    // species name refers to.
    Real detailAmount    = 0.7f;
    Real detailScale     = 140.0f;   // m, smallest feature
    int32_t detailOctaves = 4;
};

// ---------------------------------------------------------------------------
// Cellular convection -- the workhorse, and the second generator
// ---------------------------------------------------------------------------

// Rayleigh-Benard circulation in a moist boundary layer: air rises in some parts of
// each convective cell and sinks in others, and cloud forms where it rises past the
// condensation level.
//
// CELL POLARITY IS THE ONE PARAMETER THAT MATTERS MOST, per the spec. OPEN cells rise
// at the rims and sink in the centres: cloud walls around clear holes, which at low
// moisture break into scattered fair-weather cumulus at the vertices where the rims
// meet. CLOSED cells rise in the centres and sink at the rims: one cloud per cell,
// which at high moisture is a stratocumulus deck with clear seams between the cells.
// One slider, two completely different skies.
//
// THE BASE IS NOT A PARAMETER. It is the lifting condensation level, computed from
// PhysicsParams' surface temperature and humidity -- see condensationLevel() in
// ConvectionField.h. That is what makes the flat, dark base the spec's craft checklist
// asks for a consequence of the air rather than a slider, and it is why the Physics
// tab changes this cloud: dry air lifts the base, and air dry enough to lift it past
// the inversion has no cumulus at all.
//
// WIND IS A BEARING, LIKE THE SHEAR PROFILE: the direction it comes FROM, clockwise
// from +Z. One steering wind for the whole layer, because a boundary-layer cloud is
// shallow enough that its shear is the ice generator's business rather than this one's.
struct ConvectionParams {
    // OFF IN THE ENGINE'S DEFAULTS, so every existing golden image and every test
    // written against a lone cirrus keeps meaning what it meant. The effect turns it on
    // as the spec's default preset -- two layers, cumulus under thin cirrus.
    bool enabled = false;

    Real cellSize        = 1800.0f;  // m, the spacing of the convective cells
    Real polarity        = 0.0f;     // 0 = open (rising rims) .. 1 = closed (centres)
    Real coverage        = 0.45f;    // 0..1, how much of the sky the moisture can fill
    Real instability     = 0.45f;    // 0..1, humilis -> mediocris -> congestus
    Real inversionHeight = 2400.0f;  // m, the lid: nothing rises through it

    // Peak extinction inside the cloud, per metre. REAL CUMULUS IS DENSER THAN THIS --
    // 0.05 to 0.3 per metre -- and every doubling roughly quadruples the scattering
    // events a path needs to leave. The default is chosen so a mid-sized cumulus is
    // optically thick (optical depth 20 to 40 across) without costing seconds a frame.
    Real density         = 0.03f;

    // Billows: how far, in metres, the cauliflower displaces the top and sides, and
    // the size of the largest lobe. The base is not displaced -- it is the flat
    // condensation level, and a ragged base reads as fractus rather than cumulus.
    Real billowAmount    = 350.0f;   // m
    Real billowScale     = 450.0f;   // m
    int32_t billowOctaves = 3;

    Real windSpeed       = 6.0f;     // m/s
    Real windBearing     = 250.0f;   // degrees, where it comes FROM

    // One cell's life, birth to gone, in seconds. Fair-weather cumulus lives about
    // fifteen to thirty minutes. Each cell is at its own point in the cycle, which is
    // what stops a timelapse from pulsing in step.
    Real lifetime        = 1200.0f;

    // Droplet diameter in microns. It selects the Jendersie-d'Eon phase function's
    // four parameters, so it is what sets the forward peak, the fogbow and the glory.
    // The fit is valid from 5 to 50 microns and is clamped to that range.
    Real dropletDiameter = 20.0f;
};

// ---------------------------------------------------------------------------
// What is in the sky
// ---------------------------------------------------------------------------

// EVERYTHING HERE IS HASHED INTO THE FIELD FINGERPRINT. Adding a member without
// hashing it is a change the cache cannot see: the user edits it, the field is
// not rebuilt, and the old sky stays on screen. Fingerprint.cpp static_asserts
// this struct's size as the tripwire for exactly that -- adding a field breaks
// the build until someone hashes it.
struct FieldParams {
    PhysicsParams   physics;
    AtmosphereParams atmosphere;
    IceParams       ice;
    ConvectionParams convection;

    // The frame being rendered, in seconds. IN THE FIELD, not the view: the
    // cells advect, so a new time is genuinely a new medium.
    Real timeSeconds = 0.0f;

    // The one seed the whole render derives from. Per PLAN.md, randomness comes
    // from (frame, sample index, pixel) and this -- never a clock, a thread id,
    // or a counter shared between launches, because motion blur renders one
    // frame several times and MFR renders frames on different workers.
    uint32_t seed = 0x5eed1ce5u;
};

// ---------------------------------------------------------------------------
// Where it is seen from
// ---------------------------------------------------------------------------

// NOTHING HERE IS HASHED INTO THE FIELD FINGERPRINT. That is the whole point:
// change any of it and the cached field is still valid, so the renderer restarts
// accumulation without rebuilding the medium.
struct ViewParams {
    // Camera-to-world, row-major. AEGP_GetEffectCameraMatrix returns
    // camera-to-world and it must be INVERTED for a view matrix -- see
    // docs/HOST-NOTES.md, which also records that a comp with no camera returns
    // a zero plane size and needs a default rather than a failure.
    Real cameraToWorld[16] = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    };

    // True when the matrix above came from a real comp camera. Kept because
    // "no camera, defaulting" is correct and "the call failed" is a guess, and
    // the diagnostic log should be able to tell them apart.
    bool cameraFromComp = false;

    Real verticalFovDegrees = 39.6f;   // 50 mm on full frame
    Real observerAltitude   = 2.0f;    // m above the ground plane

    // THE FULL FRAME, WHICH IS NOT NECESSARILY THE BUFFER BEING WRITTEN.
    //
    // These two are the camera's denominator -- the size of the whole picture the
    // lens sees. The destination Surface can be a WINDOW into that picture: After
    // Effects routinely asks for a rect larger or smaller than the layer and hands
    // back a buffer of a third size again (measured: a 1920x1080 layer requested as
    // 2304x1296 with the output world still 1920x1080).
    //
    // CONFLATING THE TWO IS A FRAMING BUG, NOT A CROP. Using the request size here
    // while writing a smaller buffer scales every ray by the ratio, so the effective
    // field of view changes and the image slides off centre -- which reads as a
    // broken camera rather than as a units mistake.
    //
    // IN THE DESTINATION BUFFER'S OWN UNITS, WHICH UNDER AE MEANS DOWNSAMPLED PIXELS.
    // "Full frame" is about extent, not about resolution: at Third the whole picture
    // the lens sees is 640x360 and these hold 640x360. A full-resolution number here
    // beside a downsampled buffer is the same framing bug wearing different clothes,
    // and it is the one that shipped -- every reduced-resolution render drew the
    // top-left third of the picture until 2026-09-28. The camera is unharmed by the
    // scaling because only the RATIO of buffer to frame reaches the ray maths.
    int32_t widthPx  = 1920;
    int32_t heightPx = 1080;

    // Where the destination buffer's pixel (0,0) sits within that full frame.
    //
    // ZERO FOR A FULL-FRAME RENDER, which is why the CLI and the golden tests never
    // set it. AE sets it through in_data->output_origin_x/y, and ignoring it renders
    // the wrong part of the picture into the right buffer.
    int32_t originX = 0;
    int32_t originY = 0;

    // Real exposure, in stops. The render is linear float and the tonemap is a
    // separate switch defaulting OFF, so this is the only thing between the
    // physical radiance and the pixel.
    Real exposureEV = 0.0f;
    bool agxTonemap = false;

    // ---------------------------------------------------------------------
    // WHETHER THE OUTPUT CARRIES A DISPLAY TRANSFER CURVE, AND IT IS A PROPERTY OF
    // THE PROJECT RATHER THAN OF THE BIT DEPTH.
    //
    // MEASURED 2026-09-28, in AE 2026 with Working Color Space set to None and
    // "Linearize working color space" unchecked -- which is the default: AE applies
    // NO transform to either buffer on the way to the screen. It is the identity, in
    // both directions, at every bit depth. Confirmed by rendering one frame at 32 bpc
    // and again at 16 bpc and comparing the two screenshots: they differed by exactly
    // one sRGB encode, to half a code value on flat areas.
    //
    // WHICH MEANS A GENERATOR HAS TO ENCODE ITS OWN OUTPUT. An effect that filters
    // somebody else's pixels never faces this -- whatever encoding arrives, leaves.
    // One that makes light from nothing has to choose, and nothing in the buffer says
    // which choice was made.
    //
    // THE CODE USED TO KEY THIS OFF THE BIT DEPTH: linear at 32 bpc, sRGB at 8 and 16.
    // That is wrong, and it is wrong in a way that cannot be seen from inside one
    // depth -- the two render the same comp differently, and each looks plausible
    // alone. Bit depth and colour space are orthogonal in After Effects. The encoding
    // follows the PROJECT.
    //
    // DEFAULT TRUE, because Working Space None is AE's default and is what
    // proto/index.html does -- and proto is what passed the Phase 0 look verdict, so
    // it is the reference for what this renderer is supposed to look like.
    //
    // FALSE IS FOR A COLOUR-MANAGED PROJECT, where AE applies the display transform
    // itself; encoding there would double-encode.
    //
    // NO LONGER A CONSTANT AT THE EFFECT. ColorManagement.h decides it from what the
    // project reports -- AEGP_IsOCIOColorManagementUsed and the working space's own
    // approximate gamma. THE DEFAULT HERE IS STILL TRUE AND HAS TO BE: src/cli/ has no
    // host to ask, and a failed read in the effect must land on the behaviour that was
    // confirmed in AE rather than on a guess.
    //
    // NOT AEGP_DoesViewHaveColorSpaceXform, which an earlier note here named. That asks
    // about the comp VIEWER, and a render-queue export has no viewer -- so it would let
    // the preview and the exported file disagree. See ColorManagement.h.
    // ---------------------------------------------------------------------
    bool encodeSrgb = true;
};

// ---------------------------------------------------------------------------
// How hard to render it
// ---------------------------------------------------------------------------

// ALSO NOT HASHED. Sample count and bounce depth change how converged the image
// is, not what is in it, so raising them continues an accumulation rather than
// restarting one. Bounce depth is the exception worth naming: it changes the
// image, but it changes the TRANSPORT and not the FIELD, so the cached medium
// still stands.
struct QualityParams {
    // ONE, AND THAT IS A PHASE 1 VALUE WITH A DATE ON IT.
    //
    // A sample here buys ONE thing today: a jittered ray within the pixel. The
    // Phase 1 sky is analytic -- skyRadiance() is a deterministic function of a
    // direction, with no stochastic transport anywhere in it -- so there is no
    // noise for a second sample to converge.
    //
    // MEASURED, at 960x540 against a 64-sample reference: away from the horizon
    // line, ONE sample differs by at most 2/255, and the whole-frame mean
    // difference is 0.12/255. The horizon row itself differs by up to 224 -- and
    // raising the count does not fix it, because that speckle is the 24-step
    // quadratic march at grazing angles and not sampling noise. So 64 cost 64x the
    // render time to improve a single row of pixels that stayed wrong anyway.
    //
    // WHAT MUST HAPPEN WHEN PHASE 2 LANDS. Null-collision tracking and multiple
    // scattering are genuinely stochastic, and at one sample they are pure noise.
    // This number goes back up with the transport that needs it -- it is not a
    // judgement that path tracing is cheap, it is a statement that THIS renderer
    // does not path trace yet.
    int32_t samplesPerPixel = 1;
    int32_t maxBounces      = 32;

    // ONE LAUNCH PER BATCH, sized so no single launch approaches the Windows
    // display-driver timeout -- about two seconds, which is exactly where a
    // 2-second frame sits. Progressive accumulation is therefore a TDR
    // mitigation before it is a quality feature; PLAN.md says so at length.
    int32_t samplesPerLaunch = 4;

    // Null-collision tracking needs an upper bound on density to bound its
    // majorant. Too low and the estimator is biased; too high and it is just
    // slow. Measured from the field when it is built, overridable for tests.
    Real densityMajorant = 0.0f;   // 0 = derive from the field

    bool denoise = true;

    // ===================================================================
    // HOW MUCH OF THE DENOISED IMAGE TO KEEP, 0..1, BLENDED AGAINST THE RAW RENDER.
    //
    // OIDN's RT filter has no strength of its own, so this is a blend -- and it is a
    // real control rather than a comfort knob, because the filter measurably
    // OVERSHOOTS on this content.
    //
    // MEASURED 2026-09-29, 240x135 at 4 spp against a 512-spp render of the same
    // frame, comparing mean neighbouring-pixel difference (how much fine structure
    // the image carries):
    //
    //     512 spp (truth)      2.364    100%
    //       4 spp, raw         9.887    418%  -- four times too much: that is noise
    //       4 spp, amount 0.5  4.984    211%
    //       4 spp, amount 0.8  2.655    112%  -- the converged amount of structure
    //       4 spp, amount 1.0  0.769     33%  -- two thirds of the detail gone
    //
    // Those are the SHIPPING path, blended in linear before the output transform, not
    // a simulation over encoded output -- which predicted 100% at 0.8 rather than 112%
    // and is the reason the real thing was measured before the default was fixed.
    //
    // So a full denoise removes two thirds of the fine structure a converged render
    // actually has. THE DEFAULT IS 0.8 BECAUSE THAT IS WHERE THE IMAGE CARRIES THE
    // SAME DETAIL AS THE TRUTH, not because it looked nicer.
    //
    // RMSE DISAGREES, AND THAT IS WHY THIS IS A SLIDER AND NOT A CONSTANT. Measured
    // against the same reference, RMSE is minimised at amount 0.95 -- because RMSE
    // rewards blur, and a smooth wrong image scores better than a noisy right one.
    // The two criteria genuinely differ, so the choice belongs to whoever is looking
    // at the picture.
    //
    // IT ALSO COSTS NOTHING IN TEMPORAL STABILITY -- it helps. Frame-to-frame change
    // over an eight-frame move measured 0.227 raw against 0.453 fully denoised: the
    // denoiser DOUBLES the shimmer, because OIDN is not temporal and reconstructs each
    // frame independently while the raw noise is nearly fixed-pattern. Lower amounts
    // interpolate between the two. Detail and stability move together here; there is
    // no trade to make between them.
    //
    // BLENDED IN LINEAR, BEFORE THE OUTPUT TRANSFORM, which is where the denoise
    // already happens. Blending after the transfer curve would mix two differently
    // encoded images and darken the midtones.
    // ===================================================================
    Real denoiseAmount = 0.8f;
};

} // namespace plugin::cloud
