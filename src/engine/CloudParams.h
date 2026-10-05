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

    // WHETHER THE CAMERA SEES THE SUN'S DISC (build 31). Off hides the disc and nothing else:
    // the sun still lights every cloud, and the sky's glow round it stays, because only a
    // camera ray that reaches the sky without scattering was ever shown the disc -- see
    // pathEnvironment in BounceLib.slang. The light on the cloud comes by next events.
    bool showSunDisc = true;
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

// ---------------------------------------------------------------------------
// Organization: how a generator's cells are arranged
// ---------------------------------------------------------------------------

// THE SPEC'S ORGANIZATION GROUP, ONE STRUCT FOR ANY GENERATOR. The WMO's varieties are
// almost all about how the cells are laid out -- in rows, in waves, with gaps between
// them or holes through them -- so this is the same set of numbers for the cumulus layer
// and the ice layer, and each layer has its own. src/engine/Organization.h resolves it
// into what the kernel reads, and OrganizationLib.slang is the kernel's half.
//
// THE DEFAULTS ARE NO ORGANIZATION AT ALL: a Cellular layer with round cells, no rows,
// no wave, no gaps and no holes, which is every render before build 20 bit for bit.
enum class OrganizationMode : int32_t {
    Cellular = 0,   // cells, laid out by Aspect Ratio, Alignment and Coherence
    Rolls    = 1,   // cloud streets: cells four times longer along the rows
    Waves    = 2,   // the wave arranges the cells: rows along its crests
    Chaotic  = 3    // no order: the lattice warped, rows ignored
};

struct OrganizationParams {
    int32_t mode = 0;               // OrganizationMode

    // ROWS. A cell is Aspect Ratio times longer along the rows than across them; the
    // rows run along Alignment, a bearing like the wind's; Coherence straightens them,
    // from the lattice's full jitter at 0 to ruled lines at 1. Cloud streets run along
    // the wind, so a Rolls sky usually wants Alignment near Wind From.
    //
    // ALIGNMENT DEFAULTS TO 90, rows east-west along +X, because that is where the lattice
    // before build 20 had them: at 90 the pattern frame is the world's and nothing moves.
    Real aspectRatio = 1.0f;        // >= 1
    Real alignment   = 90.0f;       // degrees, the bearing the rows run along
    Real coherence   = 0.0f;        // 0..1

    // THE WAVE FIELD: bands of thicker and thinner cloud whose crests run along Wave
    // Angle. Amplitude 1 clears the troughs completely. Undulatus.
    Real waveLength    = 3000.0f;   // m, crest to crest
    Real waveAmplitude = 0.0f;      // 0..1
    Real waveAngle     = 0.0f;      // degrees, the bearing the crests run along

    // CUMULUS ONLY. Gap Fraction opens clear seams between the cells (perlucidus);
    // Lacunarity opens round holes through their middles (lacunosus). The ice layer's
    // cells are separate heads already, and ignores both.
    Real gapFraction = 0.0f;        // 0..1
    Real lacunarity  = 0.0f;        // 0..1
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

    // How the generating cells are arranged. Gap Fraction and Lacunarity are ignored.
    OrganizationParams organization;
};

// ---------------------------------------------------------------------------
// Pareidolia: a picture as the hero's silhouette
// ---------------------------------------------------------------------------

// WHAT THE PICTURE BECOMES, NOT THE PICTURE. The pixels come from another layer and are
// not parameters -- the effect reads them at render time and folds their hash into the
// render key (see ShapeMap::hash). These are the numbers that say how to read them and
// what to build from them. src/engine/Pareidolia.h has the whole story.
//
// THE DEFAULTS DO NOTHING ON THEIR OWN: with no picture there is no shape, and the hero is
// the tower it always was, bit for bit.
struct PareidoliaParams {
    // Which number in each pixel is the matte. ShapeChannel in Pareidolia.h: 0 alpha,
    // 1 luminance, 2 inverted alpha, 3 inverted luminance.
    int32_t channel = 0;

    // The matte level that is the silhouette's edge, 0..1.
    Real threshold = 0.5f;

    // 0 THE SHAPE HOLDS, 1 THE CLOUD HAS FORGOTTEN IT and is the ordinary hero tower.
    // Keyframed, it is the shape melting back into a cumulus.
    Real decay = 0.0f;

    // How deep the shape is front to back: the radius its rims are rounded to, as a
    // fraction of half its smaller side. 1 makes the thickest part as deep as the shape
    // is tall (or wide); lower is a flatter cushion.
    Real depth = 0.6f;

    // The shape's cauliflower over the hero's own, 0..1, amount and lobe size together.
    // THE LEGIBILITY KNOB: the hero's billows are sized for a whole tower and swallow an
    // eye or a finger, so the shape wears less of them.
    Real billows = 0.2f;

    // 0 TURNS TO THE CAMERA, 1 faces a fixed bearing.
    int32_t facing = 0;

    // Degrees, in the orbit rig's convention: the shape faces an eye standing at this
    // Orbit angle round the hero. UNDER TURN TO CAMERA THE EFFECT OVERWRITES IT with the
    // camera's own bearing before the fingerprint is taken, as the sun placement does
    // with the sun, so a camera move that turns the shape is a field change.
    Real bearing = 0.0f;

    // RELIEF (build 27): a second picture, a DEPTH MAP, pushes the side of the shape that
    // faces the eye out towards it -- brighter is nearer -- so the inside of the silhouette
    // has forms the sun can model, not one even cushion. NO RELIEF SOURCE IS NO RELIEF, and
    // the shape is build 21's, bit for bit. Pareidolia.h has the whole story.
    //
    // 0 reads the depth map's luminance as nearness, 1 its inverse (a Z pass: dark is near).
    int32_t reliefChannel = 0;

    // How far the nearest part of the relief stands proud of the cushion's face, as a
    // fraction of the shape's smaller side. The depth map's own range inside the
    // silhouette is stretched to fill it.
    Real reliefDepth = 0.25f;

    // 0..1: how far the depth map is blurred before it is built, up to kReliefBlurMax
    // texels. Soft relief reads as cloud lobes; hard relief reads as a plaster cast.
    Real reliefSoftness = 0.35f;

    // 0..1 (build 28): how much of the depth map's LARGE FORM is taken away before it is
    // stretched to Relief Depth, so the features -- a nose, lips, a brow -- spend the range
    // rather than the head's own turn. 0 is the depth map as it is.
    Real reliefDetail = 0.5f;
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

    // -----------------------------------------------------------------
    // THE HERO: one cloud, placed.
    //
    // A field is a statistical thing: you get whichever cloud the lattice happens to
    // put in front of the camera. A shot is usually about ONE cloud, and pareidolia
    // shapes exactly one, so this puts a tower where the user says. It stands on the
    // same base under the same lid with the same billows as the field, and it holds
    // still while the field drifts.
    //
    // POSITION IS IN WORLD METRES from the origin -- the point AE's default camera
    // looks at (see observerFromAE in CameraConvert.h). So a hero at 0, 0 is in front
    // of a default camera, and moving the camera moves you past it.
    //
    // HEIGHT IS A FRACTION OF THE ROOM UNDER THE LID, not metres, for the same reason
    // the field's towers are: the inversion caps convection. Raise Inversion Height for
    // a taller hero.
    // -----------------------------------------------------------------
    int32_t heroMode    = 0;        // 0 off, 1 with the field, 2 alone
    Real heroX          = 0.0f;     // m, +X right of a default camera
    Real heroZ          = 0.0f;     // m, +Z TOWARDS a default camera, which stands on +Z
    Real heroWidth      = 3000.0f;  // m, the footprint's diameter at the base
    Real heroHeight     = 1.0f;     // 0..1 of the base-to-inversion depth
    Real heroVariation  = 0.0f;     // picks which cauliflower it wears

    // HOW MUCH THE HERO BELONGS TO THE FIELD (build 22), 0..1. 0 is the lone tower as
    // it always was, bit for bit. Rising, turrets grow on its shoulders, a flanking line
    // of smaller towers steps down from it into the wind, and the field's updraft sinks
    // under the whole group, so no field cell grows through it. See heroGroup() in
    // ConvectionField.h.
    Real heroConnection = 0.0f;

    // THE HERO RIDES THE STEERING WIND WITH THE FIELD when this is set, from Hero
    // Position at time zero. Off, it is pinned there while the field drifts past it,
    // which is how every build before 22 drew it. The orbit rig follows it either way.
    bool heroDrift      = false;

    // -----------------------------------------------------------------
    // MAMMA (build 23): pouches hanging from the layer's underside.
    //
    // Cloudy air sinking into drier air below, cooled by its own evaporation, sags out of
    // the base in round lobes. They hang wherever the layer has cloud overhead -- under a
    // stratocumulus deck, under the hero and its group -- smooth, without cauliflower,
    // with sharp creases between them, and they grow and fade over minutes.
    //
    // 0 IS NONE, and then the base is the flat condensation level it always was, bit for
    // bit. The amount sets how far they hang, up to most of a pouch's width.
    // -----------------------------------------------------------------
    Real mamma     = 0.0f;     // 0..1
    Real pouchSize = 450.0f;   // m, across one pouch

    // -----------------------------------------------------------------
    // PILEUS AND VELUM (build 24): the hero's cap and veil.
    //
    // A tower rising fast lifts a moist, stable layer above it to saturation: PILEUS is
    // the smooth, thin lens that then sits just over its crown, and VELUM the wide thin
    // veil it pushes up through on the way. Accessory clouds the atlas lists for towering
    // cumulus, and smooth where the tower is cauliflower -- which is the contrast that
    // makes them read. They belong to the hero and drift with it.
    //
    // 0 IS NONE for both amounts, and the hero is what it was.
    // -----------------------------------------------------------------
    Real pileus       = 0.0f;     // 0..1: how thick the cap is
    Real pileusGap    = 150.0f;   // m, from the crown's highest billows to the cap's middle
    Real velum        = 0.0f;     // 0..1: how thick the veil is
    Real velumHeight  = 0.6f;     // 0..1 of the hero's height

    // How the convective cells are arranged. The hero is one placed cloud and ignores it.
    OrganizationParams organization;

    // The hero's shape, when a picture gives it one (build 21). See Pareidolia.h.
    PareidoliaParams pareidolia;
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

    // WHERE ON THE GROUND THE OBSERVER STANDS, in metres from the world origin. Zero
    // is the old fixed observer, which is what the CLI and the golden images use.
    //
    // THE EFFECT SETS THESE FROM THE COMP CAMERA'S POSITION, scaled by Camera Travel --
    // see observerFromAE in CameraConvert.h. Before that, only the camera's rotation
    // reached the renderer, so a dolly towards a cloud moved nothing: the eye stayed
    // two metres above one spot and every framing was "look around from here".
    Real observerX = 0.0f;
    Real observerZ = 0.0f;

    // HOW FAR ACROSS FROM THE OBSERVER CLOUD IS DRAWN, in metres; 0 is unlimited.
    //
    // A VIEW SETTING, NOT A FIELD ONE: it is measured from wherever the eye stands, so
    // moving the camera moves it, and the cached field does not care. The cloud fades
    // out over the last kRenderDistanceFade of it rather than stopping at a wall. See
    // Medium's fade in TransportLib.slang, which is where it takes effect.
    Real renderDistance = 0.0f;

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

    // ---------------------------------------------------------------------
    // BACKGROUND: TRANSPARENT (build 31) -- the clouds alone, for compositing over other
    // layers. Every camera ray that no depth pass stops is stopped by geometry AT INFINITY,
    // past the last of the air, and build 30's holdout does the rest: the clouds come out
    // premultiplied with alpha 1 - T, the air in front of them kept and the sky behind them
    // gone. The sun and the sky still light the clouds; they are only not drawn.
    //
    // A SAMPLING INPUT, so it is in samplingHash: it changes what every camera ray returns.
    // ---------------------------------------------------------------------
    bool transparentSky = false;
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

    // ===================================================================
    // DRAFT'S SHADOW HAND-OFF, in texels of the clouds' shadow maps (build 25). A shadow
    // ray walks exactly until it has crossed this many texels of clear air, then reads the
    // rest of its way to the sun from the map. ZERO IS THE EXACT RAY, and the default: only
    // draftQuality() turns it on.
    //
    // A SAMPLING INPUT, so it is in samplingHash: a Draft frame's samples are not samples
    // of the Best frame. See transmittanceHandoff in AirMapLib.slang for the argument and
    // PROGRESS.md (build 25) for what it costs the picture.
    // ===================================================================
    Real shadowHandoff = 0.0f;

    // ===================================================================
    // DRAFT'S PIXEL STRIDE (build 26): one path per stride x stride block of the frame,
    // traced from the block's centre with the jitter spread over the block. The caller
    // renders into a buffer 1/stride the size, denoises it there and scales it up with
    // upscaleFromStride (src/engine/Upscale.h). ONE IS EVERY PIXEL, and the default.
    //
    // THE FRAME DOES NOT CHANGE, so the field of view and the framing are exact at any
    // size, odd ones included -- unlike halving widthPx, which rounds.
    //
    // A SAMPLING INPUT, in samplingHash.
    // ===================================================================
    int32_t pixelStride = 1;
};

// ---------------------------------------------------------------------------
// Draft: what the Render Quality switch buys
// ---------------------------------------------------------------------------
//
// ===========================================================================
// THE EFFECT'S OWN SWITCH SINCE BUILD 26, NOT THE LAYER'S.
//
// Through build 25 the layer's quality switch drove this, read as in_data->quality ==
// PF_Quality_LO. Reported from the host: "Just setting Draft in AE does not help in any
// way." The log agrees: across builds 15 to 24 it never once recorded a Draft frame.
// Whatever the layer switch does in AE 2026, it did not reach this effect, so the Render
// Quality popup at the top of the panel decides now. See Params.h.
//
// WHAT IT BUYS, MEASURED (PROGRESS.md, build 26) on an RTX 2070 SUPER at 1 spp, trace
// time against Best at the same size: 3.4 to 3.9x less at 480x270 (a quarter-resolution
// 1080p preview), 3.5 to 5.5x at 960x540, 4.2 to 6.3x at 1920x1080.
//
//   * ONE SAMPLE. NEVER RAISES ANYTHING: a user already at one sample keeps it.
//   * HALF RESOLUTION, one path per 2x2 block (QualityParams::pixelStride), denoised at
//     that size and scaled up. The largest single saving, and it changes only sharpness.
//   * THE SHADOW HAND-OFF (build 25): two texels of clear air, then the map. Cast shadows
//     soften by about a texel. See QualityParams::shadowHandoff.
//   * A FULL DENOISE, whatever Denoise and Denoise Amount say. Amount 0.8 blends a fifth
//     of the raw frame back in, and at half resolution its fireflies come back as 2x2
//     white speckles all over a close hero -- seen, not just measured. Fully denoised,
//     Draft's cloud is within 2 levels of a 64-spp reference on all three test frames.
//
// MAX BOUNCES IS LEFT ALONE, so Draft is as bright as Best. Through build 25 Draft capped
// it at 16, measured then as 1% darker on a cumulus field. The hero is far thicker: on a
// close side-lit frame, denoised, the cap put the mean 27 levels under a 64-spp reference
// where Best sits 4 under. A roulette that survives at most 0.85 a bounce was tried in its
// place -- unbiased in linear light, but OIDN treats its heavily weighted survivors as
// outliers, and it sat 13 under.
// ===========================================================================
constexpr int32_t kDraftSamples       = 1;
constexpr Real    kDraftShadowHandoff = 2.0f;
constexpr int32_t kDraftPixelStride   = 2;

inline QualityParams draftQuality(QualityParams q) {
    if (q.samplesPerPixel > kDraftSamples)  q.samplesPerPixel = kDraftSamples;
    if (!(q.shadowHandoff > 0.0f))          q.shadowHandoff = kDraftShadowHandoff;
    if (q.pixelStride < kDraftPixelStride)  q.pixelStride = kDraftPixelStride;
    q.denoise       = true;
    q.denoiseAmount = 1.0f;
    return q;
}

} // namespace plugin::cloud
