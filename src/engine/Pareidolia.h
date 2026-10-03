#pragma once

// Pareidolia: a picture the user brings becomes the hero cloud's silhouette.
//
// ===========================================================================
// THE WHOLE IDEA IN FOUR LINES.
//
//   1. Another layer's ALPHA or LUMINANCE is the matte. Its pixels above Threshold are
//      the silhouette, cropped to their bounding box.
//   2. The host turns the silhouette into a SIGNED DISTANCE MAP: at every texel, how far
//      it is to the silhouette's edge, positive inside. Two passes of an exact Euclidean
//      distance transform (Felzenszwalb and Huttenlocher), about a millisecond.
//   3. The kernel stands the map up as a vertical plane through the hero's centre, its
//      bottom on the condensation level, fitted inside the hero's width and height and
//      turned to face the camera. It INFLATES it: every point of the silhouette gets a
//      thickness from how deep inside it is, with rims rounded to a radius -- so a disc
//      becomes a lens, a stroke becomes a tube, and a wide region a thick cushion.
//   4. The billows ride that surface exactly as they ride the tower: read at the nearest
//      surface point, so they are relief on it rather than flecks in the air around it.
//
// WHY A DISTANCE MAP AND NOT A HEIGHT FIELD. A thickness over the plane is the obvious
// representation, and near the rim its slope runs to infinity, which a height-field
// distance cannot survive: a point beside the rim reads as ten times nearer the surface
// than a point just past it, and the billows show that as a seam round the silhouette.
// The rounded-rim shape is instead the set of points whose (in-plane depth D, distance
// from the plane m) lies in a fixed 2D profile -- a disc of radius R at D = R, and the
// strip m < R beyond it. The 3D distance to that shape is the 2D distance to the profile,
// in closed form, inside and outside alike. One number per texel is the whole shape.
//
// WHAT IS NOT HERE YET, AND IS PLAN.md'S: the MEASURED legibility readout from a
// shape-context matcher, and Decay in units of it. Decay is input strength for now.
// ===========================================================================
//
// ===========================================================================
// RELIEF (build 27): A DEPTH MAP CARVES THE FACE TOWARDS THE EYE.
//
// The silhouette alone makes every shape a cushion of one thickness, and a figure in a
// real cloud reads from the forms INSIDE its outline -- a brow, a cheek, a hollow the sun
// cannot reach. So a second picture, a depth map (brighter is nearer), pushes the cushion's
// front face out towards the eye by up to Relief Depth. The back stays flat: this is a
// carving in cloud, seen from the front, as the shape itself is.
//
//   1. The depth map is read at the silhouette's texels, in the same place in its frame as
//      the matte -- so a depth pass of the same picture lines up whatever its resolution.
//   2. Its range INSIDE the silhouette is stretched to 0..1: depth tools put a subject
//      anywhere in their range, and Relief Depth should mean the nearest part.
//   3. The outside is filled from the nearest inside texels. Filled, so the blurs that
//      follow do not sink the rim towards the background, and the slope across the edge is
//      the subject's, not a cliff.
//   4. RELIEF DETAIL (build 28) flattens the large form and keeps the features, as a relief
//      sculptor does: it takes away that much of the map blurred at kReliefFormSigma, and
//      stretches what is left to 0..1 again. A three-quarter head's turn otherwise spends
//      the whole range, and the nose, the lips and the brow are bumps on a slope.
//   5. The whole is blurred by Relief Softness.
//   6. The kernel lifts the front face by height x relief, faded in from the silhouette's
//      edge over a quarter of the rims' radius, so the outline is not a sheer wall but a
//      nose ON the outline keeps its height. Billows ride the lifted face as they ride the
//      cushion, so a brow becomes one big lobe made of small ones.
//
// THE BOUND: the relief's largest step between neighbouring texels is measured here, and
// the kernel bounds the face over a box from the relief at its centre plus that slope --
// the same argument as the distance's own, which is what keeps the majorant sound.
//
// THE MEDIUM IS UNCHANGED. Relief moves where the water is, never what it is.
// ===========================================================================
//
// NO AE HEADERS AND NO GPU HEADERS, like the rest of src/engine/. Pixels in, a map out.

#include "CloudParams.h"
#include "ConvectionField.h"
#include "Image.h"

#include <cstdint>
#include <vector>

namespace plugin::cloud {

// WHICH NUMBER IN EACH PIXEL IS THE MATTE. Luminance is Rec. 709 luma of the pixel as it
// arrives. AE's buffers are premultiplied, so that is the layer composited over black,
// which is what a luma matte means.
enum class ShapeChannel : int32_t {
    Alpha             = 0,
    Luminance         = 1,
    InvertedAlpha     = 2,
    InvertedLuminance = 3
};

// ---------------------------------------------------------------------------
// The map
// ---------------------------------------------------------------------------

// THE SILHOUETTE'S LONGER SIDE IS THIS MANY TEXELS, whatever the source's resolution, so a
// proxy render at Third and a full-resolution one build the same shape, only coarser.
// 13 m a texel on the default 3 km hero: finer than any billow can leave legible.
constexpr int kShapeMapInner = 224;

// Clear texels round the silhouette on every side. Beyond them the kernel extends the
// distance linearly, which is continuous and never says a point is nearer the shape than
// it is -- so the margin only has to be wide enough for the gradient there to be honest.
constexpr int kShapeMapMargin = 16;

// Four floats a texel, and the layout is the kernel's (ConvectionLib.slang):
//
//   [0] signed distance to the silhouette's edge, in TEXELS, positive inside
//   [1] its slope along u (texels per texel, so per metre per metre)
//   [2] its slope along y
//   [3] the relief, 0..1 (build 27); zero everywhere when there is none
//
// ROW 0 IS THE BOTTOM. The source's rows run downwards; the map's run up, as height does.
// The slopes are central differences, so that bilinear interpolation of them is
// continuous: the billows read their surface point along this gradient, and a gradient
// that jumped at every texel edge would draw the texel grid on the cloud.
struct ShapeMap {
    int32_t width  = 0;
    int32_t height = 0;

    // THE SILHOUETTE'S BOUNDING BOX IN THE MAP, in texel-edge coordinates: texel i spans
    // [i, i + 1]. The fit into the hero works from this, not from the map's own size.
    float boxLoU = 0, boxLoY = 0;
    float boxHiU = 0, boxHiY = 0;

    std::vector<float> texels;   // width x height x 4, row-major from the bottom

    // RELIEF (build 27): whether [3] holds one, and its largest step between neighbouring
    // texels, along either axis -- what the kernel's bound turns into metres per metre.
    bool  hasRelief   = false;
    float reliefSlope = 0;

    // A hash of everything the kernel reads from here. THE PICTURE IS NOT A PARAMETER,
    // so the fingerprint cannot see it; the effect folds this into the render key once
    // it has read the pixels, and the device caches its upload and the shadow maps
    // their build on it.
    uint64_t hash = 0;

    bool empty() const { return width <= 0 || height <= 0 || texels.empty(); }
};

// THE RELIEF'S BLUR AT SOFTNESS 1, as a Gaussian's sigma in texels: 7% of the
// silhouette's longer side, about 90 m on the default 3 km hero -- the size of the shape's
// own billow lobes, which is where relief reads as cloud rather than as sculpture.
constexpr float kReliefBlurMax = 16.0f;

// THE LARGE FORM RELIEF DETAIL TAKES AWAY, as a Gaussian's sigma in texels: 12% of the
// silhouette's longer side. Bigger than a nose or a brow on a face that fills it, smaller
// than the head's own turn.
constexpr float kReliefFormSigma = 0.12f * kShapeMapInner;

// The lift fades in from the silhouette's edge over this much of the rims' radius (or of
// the relief's height, if that is less). See convReliefLift for why it is short.
constexpr float kReliefFadeOfRim = 0.25f;

// The depth map, how to read it, and how soft to make it.
struct ReliefSource {
    ConstImageView view;
    bool inverted = false;   // a Z pass: darker is nearer
    Real softness = 0.35f;   // 0..1, of kReliefBlurMax
    Real detail   = 0.5f;    // 0 the depth map as it is .. 1 its large form taken away
};

// Builds the map from `source`. RETURNS FALSE, AND LEAVES `out` EMPTY, when nothing in the
// picture reaches the threshold -- a blank layer is no shape, and the hero stays a tower.
//
// PIXELS OUTSIDE THE SOURCE'S FRAME ARE OFF IN EVERY MODE, the inverted ones included, so
// a shape always ends at the edge of its picture: an inverted matte of a small dark mark
// on white paper is the mark, not the mark plus an infinite sheet of paper.
//
// `relief` IS OPTIONAL: null, or a view that is not valid, is no relief, and the map is
// build 21's to the bit, hash included. A depth map with no range inside the silhouette --
// one flat grey -- is no relief either.
bool buildShapeMap(const ConstImageView& source, ShapeChannel channel, Real threshold,
                   ShapeMap& out, const ReliefSource* relief = nullptr);

// ---------------------------------------------------------------------------
// The fit: the map, placed and sized in the world
// ---------------------------------------------------------------------------

// ShapeGeometry, what the fit produces, is in ConvectionField.h beside the rest of what
// the kernel is handed, so RenderRequest.h can hold one without this header's vector.

// THE FIT IS "CONTAIN": the silhouette keeps its aspect and fills the Hero Width by the
// hero's height (Hero Height of the room under the lid), centred on the hero, its bottom
// on the base. So Hero Width and Hero Height stay the controls for how big the cloud is.
//
// OFF when there is no map or no hero. CLAMPED against NaN and out-of-range expressions,
// so whatever the sliders say, the kernel gets numbers its bounds hold for.
ShapeGeometry resolveShape(const ShapeMap* map, const PareidoliaParams& p,
                           const ConvectionDerived& cd);

// THE BEARING THAT FACES THE EYE, in the orbit rig's convention: the camera stands at
// hero + d (sin b, cos b). From the eye's position when it is a metre or more from the
// hero's axis, else from where the camera looks, so a camera straight underneath still
// gets a sensible answer.
Real shapeBearingToCamera(const ViewParams& view, Real heroX, Real heroZ);

// The shape's facing, resolved: the camera's bearing under Turn to Camera, the slider's
// otherwise. The effect and the CLI call this after the camera is known and before the
// fingerprint, as they do the sun placement.
inline void placeShape(PareidoliaParams& p, const ViewParams& view, Real heroX, Real heroZ) {
    if (p.facing == 0) p.bearing = shapeBearingToCamera(view, heroX, heroZ);
}

} // namespace plugin::cloud
