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
//   [3] unused, zero
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

    // A hash of everything the kernel reads from here. THE PICTURE IS NOT A PARAMETER,
    // so the fingerprint cannot see it; the effect folds this into the render key once
    // it has read the pixels, and the device caches its upload and the shadow maps
    // their build on it.
    uint64_t hash = 0;

    bool empty() const { return width <= 0 || height <= 0 || texels.empty(); }
};

// Builds the map from `source`. RETURNS FALSE, AND LEAVES `out` EMPTY, when nothing in the
// picture reaches the threshold -- a blank layer is no shape, and the hero stays a tower.
//
// PIXELS OUTSIDE THE SOURCE'S FRAME ARE OFF IN EVERY MODE, the inverted ones included, so
// a shape always ends at the edge of its picture: an inverted matte of a small dark mark
// on white paper is the mark, not the mark plus an infinite sheet of paper.
bool buildShapeMap(const ConstImageView& source, ShapeChannel channel, Real threshold,
                   ShapeMap& out);

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
