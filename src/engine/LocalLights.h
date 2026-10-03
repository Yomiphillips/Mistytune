#pragma once

// LOCAL LIGHTS (build 29): After Effects' comp lights and a light layer, as lights the
// renderer's bounce loop estimates beside the sun.
//
// ===========================================================================
// WHAT THIS IS FOR. Reported as a want from the host: "making the clouds work with AE
// light or layers (in case I want to use saber lighting for thunder)". Lightning inside a
// cloud is a light INSIDE THE MEDIUM, and a path tracer is the right tool for it: the
// cloud around the bolt glows by multiple scattering, and the cloud between the bolt and
// the eye shades it, with nothing faked. So these lights go through the same next-event
// estimation the sun does -- a shadow ray through the cloud to the light, the phase
// function, the albedo -- and nothing about the medium changes. THE CLOUDS STAY WATER:
// a light adds illumination, it never adds absorption.
//
// TWO SOURCES, ONE KERNEL PATH.
//
//   COMP LIGHTS  AE's point, spot, parallel and ambient lights, read at pre-render and
//                mapped into the world through the camera (see CompLightFrame).
//   LIGHT LAYER  another layer's pixels -- a Saber bolt on a solid -- as a glowing SHEET
//                laid on the cloud where the camera sees it: each texel a small light
//                that shines every way, as a bolt does. Its brightness comes from the
//                pixels, so a flicker in the layer is a flicker in the cloud.
//
// THE HOST DOES EVERYTHING THAT IS NOT PER SAMPLE: the camera mapping, the colour
// decode, the sheet's reduction and its sampling table, and how often each light is
// picked. The kernel reads one packed float buffer -- see LightLib.slang, which mirrors
// the layout below and must change with it.
//
// AND NOTHING HERE TOUCHES THE AE SDK, so tests/unit/ checks every mapping by hand.
// ===========================================================================

#include "CloudParams.h"
#include "Image.h"

#include <cstdint>
#include <vector>

namespace plugin::cloud {

// ---------------------------------------------------------------------------
// Calibration
// ---------------------------------------------------------------------------

// THE SUN'S IRRADIANCE AT SUN INTENSITY 1, which every comp light is calibrated against:
// an AE light at 100% lights the cloud inside its falloff radius as brightly as the sun
// at Sun Intensity 1 does. sunIrradianceTop in SkyLib.slang is 20 x Sun Intensity; this
// is that 20, and the two must move together.
constexpr float kLightSunIrradiance = 20.0f;

// THE LIGHT LAYER'S RADIANCE FOR A PIXEL VALUE OF 1 at Light Layer Strength 1. A bolt is
// a thin line of pixels and a cloud a few hundred metres from it sees it as a sliver, so
// the radiance has to be far above the pixel's own value to light anything. Set from a
// render (PROGRESS.md, build 29): a Saber-like bolt at the hero lights the cloud within
// a few hundred metres of it about as brightly as the sun lights a cloud top.
constexpr float kLightLayerRadiance = 100.0f;

// AE'S AMBIENT LIGHT AS A UNIFORM DOME: at 100% its radiance from every direction gives a
// flat surface the sun's irradiance, so it is the sun's irradiance over pi.
constexpr float kAmbientRadiancePerIntensity = kLightSunIrradiance / 3.14159265358979f;

// ---------------------------------------------------------------------------
// The packed layout. LightLib.slang MIRRORS EVERY NUMBER HERE.
// ---------------------------------------------------------------------------
//
// header   kLightHeaderFloats: [0] count, [1..3] ambient radiance, the rest zero
// records  kLightRecordFloats each, in pick order:
//
//   [0]      kind (LightKind)
//   [1]      the pick CDF: the probability of picking this light or one before it
//   [2]      the probability of picking this light
//   [3..5]   point/spot: position. sheet: the corner of texel (0, 0)
//   [6..8]   spot: the axis it shines along. parallel: TOWARDS the light, like sunDir.
//            sheet: one texel's step across, in metres (axis U)
//   [9..11]  point/spot: radiant intensity. parallel: irradiance. sheet: the eye, which
//            every texel is pushed away from by its depth scale
//   [12]     point/spot: radius squared, the inverse square's floor. sheet: a texel's
//            area on the plane
//   [13]     spot: cos of the outer half-angle. sheet: width in texels
//   [14]     spot: cos of the inner half-angle. sheet: height in texels
//   [15]     point/spot: where Smooth falloff starts, m. sheet: offset of its texels
//   [16]     point/spot: where Smooth falloff ends, m; 0 is none. sheet: axis V .x
//   [17..18] sheet: axis V .y, .z
//   [19]     sheet: offset of its tree
//
// sheet texels, at the offset in [15]: kSheetTexelFloats per texel, rows top down as the
// frame's are -- linear radiance, and the texel's DEPTH SCALE s. A texel stands where its
// patch of the plane does, pushed along the eye's rays to s times the plane's depth: it
// covers the same pixels at any depth, and its area is s^2 times the plane's. Its tree, at
// the offset in [19]: the number of levels below the root, then every level from the root
// down, level k a square of 2^k x 2^k cells row by row, each cell kSheetCellFloats -- its
// power (luminance times area), its power's centroid in the world, and the square of a
// radius round that centroid that holds the whole cell. The kernel draws a texel down it;
// see LightLib.slang for why.
constexpr int kLightHeaderFloats = 8;
constexpr int kLightRecordFloats = 20;
constexpr int kSheetTexelFloats  = 4;
constexpr int kSheetCellFloats   = 5;

// A GPU loop wants a bound it can see, and a comp with more lights than this is not a
// cloud scene. The sheet counts as one. Lights past it are dropped and the log says so.
constexpr int kMaxLocalLights = 16;

// The sheet's longer side, in texels. A texel is tens of metres at a hero's distance,
// which is finer than a cloud can show the light's shape at: multiple scattering blurs
// it over the photon's mean free path, hundreds of metres.
constexpr int kLightSheetMaxSide = 128;

enum class LightKind : int {
    Point    = 0,
    Spot     = 1,
    Parallel = 2,
    Sheet    = 3
};

// One light, in the renderer's world: metres, +Y up, linear RGB.
struct LocalLight {
    LightKind kind = LightKind::Point;
    float position[3]  = { 0.0f, 0.0f, 0.0f };
    // SPOT: the way it shines, from the light outward. PARALLEL: the way its light
    // TRAVELS, which is AE's -- the packer turns it round into sunDir's convention.
    float direction[3] = { 0.0f, -1.0f, 0.0f };
    float color[3]     = { 1.0f, 1.0f, 1.0f };   // linear
    // AE's Intensity over 100, times the effect's Comp Light Strength. 1 is the sun.
    float intensity    = 1.0f;
    // FULL STRENGTH INSIDE IT, INVERSE SQUARE BEYOND -- AE's Inverse Square Clamped,
    // which is also what a glowing ball of this radius does to the space outside it.
    float radius       = 1.0f;
    float coneAngleDeg = 90.0f;   // spot: the whole cone, as AE's Cone Angle
    float coneFeather  = 0.5f;    // spot: 0..1, AE's Cone Feather over 100
    float smoothFalloff = 0.0f;   // metres past the radius to zero (AE's Smooth); 0 none
};

// ---------------------------------------------------------------------------
// The light layer
// ---------------------------------------------------------------------------

// THE LAYER, REDUCED: linear radiance per texel at pixel value 1 = 1, rows top down, as
// it covers the frame. A box filter, so the sum -- the light's power -- survives it.
struct LightSheet {
    int width  = 0;
    int height = 0;
    std::vector<float> rgb;   // 3 per texel
    double luminanceSum = 0.0;
};

// Reduces the layer to at most `maxSide` texels on its longer side. PREMULTIPLIED COLOUR
// IS THE EMISSION, as AE's buffers carry it: a bolt over black and a bolt on a
// transparent layer both glow by their colour. `decodeSrgb` undoes the transfer curve
// the effect would put on its own output (ViewParams::encodeSrgb), so a pixel's value
// and the radiance it stands for are related the same way in both directions.
//
// False, and an empty sheet, when nothing in the layer glows.
bool buildLightSheet(const ConstImageView& image, bool decodeSrgb, int maxSide,
                     LightSheet& out);

// WHERE THE SHEET STANDS: the plane square to the camera's view axis at `depth` metres,
// covering exactly the frame -- so a pixel of the layer glows where that pixel of the
// render looks. Texel (0, 0) is the frame's top left.
//
// AND EACH TEXEL OFF THE PLANE, by `scale`: pushed along the eye's rays to `scale` times
// the plane's depth, where it still covers the same pixels. conformLightSheet sets it;
// empty is every texel on the plane.
struct SheetPlacement {
    float origin[3] = { 0.0f, 0.0f, 0.0f };   // texel (0, 0)'s outer corner
    float axisU[3]  = { 0.0f, 0.0f, 0.0f };   // one texel to the right, in metres
    float axisV[3]  = { 0.0f, 0.0f, 0.0f };   // one texel down
    float eye[3]    = { 0.0f, 0.0f, 0.0f };   // the camera, which the scales push away from
    float planeDepth = 0.0f;                  // the plane's, along the view axis
    std::vector<float> scale;                 // per texel, rows top down; empty is all 1
};

SheetPlacement placeLightSheet(const ViewParams& view, float depth, int width, int height);

// ---------------------------------------------------------------------------
// The sheet, laid on the cloud
// ---------------------------------------------------------------------------
//
// ===========================================================================
// A FLAT SHEET THROUGH THE HERO'S MIDDLE IS BURIED. MEASURED (build 29): in a thick hero
// that plane is hundreds of metres of cloud behind the face the camera sees. A bolt there
// reaches the eye only after 8 to 32 bounces, and the frame is fireflies at 512 spp
// (build/tmp/b29/r5/m6.png) -- on the user's 6 km hero, next to nothing (r6/m7.png). That
// is diffusion from a buried source, not the sampler: three samplers gave the same frame.
//
// SO THE SHEET IS LAID ON THE CLOUD AS THE CAMERA SEES IT. Each texel stands where, on
// average, the camera's own light first scatters along that texel's rays -- the face the
// render shows there -- and then Light Layer Depth behind it. A bolt drawn over the cloud
// lights the face it is drawn on, and the glow round it is that cloud's own.
//
// WHERE THE CAMERA SEES NO CLOUD, the texel takes the nearest face the probe did see, so a
// bolt leaving a cloud's edge stays beside it. Under a layer with no cloud behind it at
// all, every texel is at the anchor's depth, the flat sheet as it was.
//
// THE PROBE IS THE KERNEL'S (probeSurfaceCpu in KernelApi.h): a deterministic march
// through the density the render sees, so a cloud that moves smoothly moves its sheet
// smoothly. It is taken on a grid of half the sheet's resolution, only at the points a lit
// texel reads, and the texels are bilinear between them. The grid and its mask are here.
// ===========================================================================
struct SurfaceProbe {
    int width  = 0;
    int height = 0;
    // IN: the deepest a face may be, along the view axis: the anchor's depth plus its reach.
    // The march stops there. 0 is no limit.
    float farDepth = 0.0f;
    // Per grid point, rows top down: the depth along the view axis of the mean first
    // scatter, and the probability of scattering at all. A depth means nothing at hit 0.
    std::vector<float> depth;
    std::vector<float> hit;
};

// The probe's grid for a sheet: half its texels each way, rounded up.
void surfaceProbeGrid(const LightSheet& sheet, int& gridWidth, int& gridHeight);

// Grid point (i, j) in frame pixels: the centre of its cell of the frame.
void surfaceProbePixel(int i, int j, int gridWidth, int gridHeight, int frameWidth,
                       int frameHeight, float& fx, float& fy);

// The grid points a lit texel's bilinear footprint reads, which are the only ones worth
// probing. Rows top down; 1 is wanted.
std::vector<unsigned char> surfaceProbeMask(const LightSheet& sheet, int gridWidth,
                                            int gridHeight);

// LAYS THE SHEET ON THE PROBED CLOUD: every lit texel's scale, from the probe's depth under
// it plus `extraDepth`, floored at 10 m. A grid point the camera half sees through is its
// own face and the nearest other face, mixed by its hit. A probe that saw no cloud leaves
// every lit texel at `fallbackDepth` plus `extraDepth`. `place` must come from
// placeLightSheet for this sheet.
void conformLightSheet(const LightSheet& sheet, const SurfaceProbe& probe,
                       float fallbackDepth, float extraDepth, SheetPlacement& place);

// ---------------------------------------------------------------------------
// Where the lights are anchored
// ---------------------------------------------------------------------------

// THE POINT THE LIGHTS ARE PLACED RELATIVE TO: the hero's centre, or the middle of the
// layers when there is no hero -- orbitAimSpan's span, at the hero's position now -- and
// its depth along the camera's view axis, floored at 100 m so a camera turned away still
// has its sheet in front of it.
//
// AND HOW FAR BEHIND IT THE CLOUD IT ANCHORS GOES: the hero's width or its span from base
// to crown, whichever is larger. A face the camera sees past depth + reach is another
// cloud's -- the field behind the hero, the horizon -- and the light layer is not laid on it.
struct LightAnchor {
    float point[3] = { 0.0f, 0.0f, 0.0f };
    float depth    = 100.0f;
    float reach    = 0.0f;
};

LightAnchor lightAnchor(const FieldParams& field, const ViewParams& view);

// ---------------------------------------------------------------------------
// AE's comp, through the camera
// ---------------------------------------------------------------------------
//
// ===========================================================================
// A LIGHT GOES WHERE IT APPEARS IN AE'S VIEWER. Its position is taken relative to the
// comp's camera -- or the default one AE uses when the comp has none -- and put at the
// same place relative to the renderer's camera:
//
//   COMP CAMERA   the scale is Comp Camera Travel, the same metres per pixel the camera
//                 itself moves by, so this is exactly the mapping the camera's own
//                 position goes through (observerFromCompPosition): the comp centre on
//                 the comp plane is the world origin. Checked in TestLights.
//
//   ORBIT RIG     the comp plane is put at the anchor's depth, and across the frame the
//                 scale is stretched by the ratio of the two lenses, so a light on the
//                 comp plane lands on the same pixel of the render that it sits on in
//                 AE's viewer. The rig's lens is rarely the comp camera's, and without
//                 that ratio a light aligned with a bolt in the comp would miss it.
//
// AE's axes are +X right, +Y down, +Z into the screen; the renderer's camera space is +X
// right, +Y up, looking down -Z. See CameraConvert.h for the same two flips on the camera.
// ===========================================================================
struct CompLightFrame {
    // The AE camera's camera-to-world in A_Matrix4 memory order: rows 0..2 its axes,
    // row 3 its position, in comp pixels.
    double camera[16] = { 1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1 };
    double across = 1.0;   // metres per comp pixel, across the frame
    double along  = 1.0;   // metres per comp pixel, along the view axis
};

// The frame for one render. `aeCamera` is AEGP_GetEffectCameraMatrix's matrix and
// `planeDistance`/`planeHeight` its zoom and plane, in comp pixels -- or
// defaultCompCamera()'s. `compCamera` is the effect's Camera popup.
CompLightFrame compLightFrame(const double aeCamera[16], double planeDistance,
                              double planeHeight, bool compCamera, double travel,
                              const ViewParams& view, const LightAnchor& anchor);

// AE's default camera for a comp with none: 50 mm on 36 mm film across the comp, at the
// comp's centre, looking along +Z. As defaultObserver in CameraConvert.h.
void defaultCompCamera(double compWidth, double compHeight, double outMatrix[16],
                       double& outPlaneDistance);

// A point and a direction in comp space, into the world. A direction is a vector, so it
// takes the frame's scales too -- an anisotropic frame turns it -- and comes back unit.
void compPointToWorld(const CompLightFrame& f, const ViewParams& view,
                      const double p[3], float out[3]);
void compDirectionToWorld(const CompLightFrame& f, const ViewParams& view,
                          const double d[3], float out[3]);

// ---------------------------------------------------------------------------
// The set the kernel reads
// ---------------------------------------------------------------------------

struct LightSet {
    std::vector<float> packed;
    int   count = 0;                             // records, the sheet included
    float ambient[3] = { 0.0f, 0.0f, 0.0f };     // a uniform dome's radiance, linear
    uint64_t hash = 0;                           // of everything above

    bool empty() const { return count == 0 && ambient[0] <= 0.0f && ambient[1] <= 0.0f &&
                                ambient[2] <= 0.0f; }
};

// ===========================================================================
// PACKS THE LIGHTS FOR THE KERNEL, and decides how often each is picked.
//
// ONE LIGHT PER SCATTERING EVENT, picked in proportion to how brightly it lights the
// anchor -- the hero -- with every light kept at a tenth of the brightest's share at
// least, so a dim light that matters somewhere else is not starved. Any choice is
// unbiased, because the kernel divides by the probability; this one is the noise.
//
// `sheet` and `place` together, or neither, and `place` conformed or not. `sheetStrength`
// is Light Layer Strength.
// Lights past kMaxLocalLights are dropped: the sheet first in line to stay, then the
// order given.
// ===========================================================================
void packLightSet(const std::vector<LocalLight>& lights, const float ambient[3],
                  const LightSheet* sheet, const SheetPlacement* place,
                  float sheetStrength, const LightAnchor& anchor, LightSet& out);

// THE sRGB CURVE, UNDONE: OutputConvert.h's encodeSrgb, inverted. For colours and pixels
// that arrive the way the effect's output leaves.
float decodeSrgb(float encoded);

// The cone of an AE spot as the kernel reads it: cosines of the outer and inner
// half-angles. Feather 0 is a hard edge, and the two come back equal.
void spotCosines(float coneAngleDeg, float feather, float& cosOuter, float& cosInner);

} // namespace plugin::cloud
