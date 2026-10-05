#pragma once

// Scene integration (build 30): a depth pass of the footage interleaves the clouds with its
// geometry, pixel by pixel.
//
// ===========================================================================
// THE SPEC, WHICH IS SHORT: "Depth is not a look-driver, it is an integration tool...
// Composite interleaves cloud with geometry per-pixel. Displace Volume pushes the density
// field away from anything in the depth pass, so cloud parts around a building rather than
// intersecting it." PLAN.md lists the three as holdout, composite and displace-volume. This
// file is the first two; displace-volume is the next build.
//
// THE WHOLE IDEA IN FOUR LINES.
//
//   1. A depth pass -- an AI depth map of the plate, or a 3D app's Z pass -- says how far
//      away each pixel's geometry is. Converted here, on the host, to METRES ALONG THE VIEW
//      AXIS, with the open sky (the far end of the range, or no alpha) marked as no
//      geometry at all.
//   2. The camera ray of every sample that lands on geometry STOPS THERE. Cloud nearer than
//      the building is rendered in front of it; cloud behind it is not rendered at all.
//   3. What the ray met on the way is written premultiplied, with ALPHA = 1 - T, where T is
//      the clouds' own transmittance to the geometry. The air in front of the geometry is
//      already in the footage -- the plate has its own haze -- so its clear-air airlight is
//      taken back off, scaled by T. That makes a building with no cloud in front of it
//      exactly transparent, and a cloud in front of it exactly as hazy as the same cloud
//      against the sky beside it.
//   4. HOLDOUT leaves that for AE to lay over the footage underneath. COMPOSITE does the
//      over itself, onto the layer the effect is applied to.
//
// WHY THE AIRLIGHT IS SUBTRACTED, IN ONE LINE OF ALGEBRA. Along a ray from the eye: air
// a1 with transmittance t1, then cloud with radiance C and transmittance T, then air a2,
// then the geometry G. The truth is a1 + t1 (C + T (a2 + t2 G)). The plate already is
// P = a1 + t1 (a2 + t2 G). The render, with G black, is R = a1 + t1 (C + T a2), and the
// clear-air airlight of the whole stretch is H = a1 + t1 a2. Then
//
//     R - T H + T P  =  a1 + t1 C + T t1 a2 - T a1 - T t1 a2 + T a1 + T t1 a2 + T t1 t2 G
//                    =  the truth.
//
// So the premultiplied colour is R - T H and the alpha 1 - T, and AE's own "over" of that
// on the plate is right. Each sample's R and T are unbiased and H is deterministic, so the
// pixel's mean is too.
// ===========================================================================

#include "Image.h"

#include <cstdint>
#include <vector>

namespace plugin::cloud {

// HOW THE DEPTH PASS'S BRIGHTNESS BECOMES A DISTANCE. AI depth tools (Depth Anything, MiDaS)
// write a RELATIVE INVERSE depth -- a disparity -- brighter nearer, so equal steps of
// brightness are equal steps of 1/distance. A 3D app's Z or mist pass is linear, and which
// end is bright depends on the app.
enum class DepthEncoding : int {
    DisparityNearBright = 0,   // AI depth: 1/distance runs linearly from Farthest to Nearest
    LinearNearBright    = 1,   // distance runs linearly, white = Nearest
    LinearFarBright     = 2    // distance runs linearly, white = Farthest (a Z / mist pass)
};

// WHAT THE CLOUDS DO WITH THE GEOMETRY.
enum class SceneMode : int {
    Off       = 0,
    Holdout   = 1,   // the geometry is transparent: lay the effect over the footage
    Composite = 2    // the effect lays itself over the layer it is applied to
};

struct SceneDepthParams {
    SceneMode     mode     = SceneMode::Composite;
    DepthEncoding encoding = DepthEncoding::DisparityNearBright;

    // METRES ALONG THE VIEW AXIS, which is what a depth pass measures: a wall square to the
    // lens is one depth across the frame. The kernel turns it into a distance along each ray.
    float nearestM  = 10.0f;
    float farthestM = 2000.0f;

    // THE OPEN SKY: depth values in the farthest this fraction of the range are no geometry.
    // An AI depth map's sky is near black but rarely exactly black, and a cloud should not be
    // held out by a sky.
    float skyCutoff = 0.02f;
};

// THE DEPTH PASS, RESOLVED: per texel, the geometry's planar distance in metres (0 for none)
// and its coverage, 0..1 -- the layer's alpha, so a soft key edge is a soft holdout edge.
// Two floats per texel, row-major, top row first, as the layer's pixels are.
struct SceneDepthMap {
    int width  = 0;
    int height = 0;
    std::vector<float> texels;   // { metres, coverage } per texel

    uint64_t hash = 0;           // of the texels: keys the device upload and the render
    int geometryTexels = 0;      // texels with any geometry, for the log

    bool empty() const { return width <= 0 || height <= 0 || geometryTexels <= 0; }
};

// A texel larger than this on a side is subsampled to it. The map is sampled per pixel, so a
// layer at the frame's size is kept whole; this only stops an 8K plate costing 8K uploads.
constexpr int kSceneDepthMaxSide = 4096;

// The planar distance in metres for one depth value v in 0..1, or 0 when v is open sky.
float sceneDepthMetres(float v, const SceneDepthParams& p);

// The depth pass's value at one pixel, 0..1: Rec. 709 luma of the STRAIGHT colour, as the
// relief reads it, and its alpha as the coverage.
void sceneDepthTexel(const Texel& t, float& value, float& coverage);

// Builds the map from a layer's pixels. False when nothing in it is geometry -- an all-sky
// pass is no scene, never a failed frame.
bool buildSceneDepthMap(const ConstImageView& view, const SceneDepthParams& p,
                        SceneDepthMap& out);

// ===========================================================================
// COMPOSITE: the effect's premultiplied, already transformed output laid over the plate in
// place -- AE's own normal blend, out = src + plate x (1 - src alpha), in the same encoded
// space AE would blend in. `argb` is the frame's float buffer (ARGB, `pitchPx` pixels a
// row); the plate's pixel for output (x, y) is (x + dx, y + dy), and outside it the plate is
// transparent. Values are left unclamped for a float frame; the 8 and 16 bpc conversion
// clamps after.
// ===========================================================================
void compositeOverPlate(float* argb, int width, int height, int pitchPx,
                        const ConstImageView& plate, int dx, int dy);

} // namespace plugin::cloud
