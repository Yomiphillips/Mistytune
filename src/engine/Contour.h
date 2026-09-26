#pragma once

// ORDERED boundary contours out of an alpha channel.
//
// THE THING Trace.h DELIBERATELY DOES NOT DO, and it says so: a convex hull only
// ever needed each row's leftmost and rightmost opaque pixel, which is a point
// SET and not a ring at all -- its points zig-zag down one side of the shape and
// back up the other. That is exactly right for a hull and useless for anything
// that cares which point follows which.
//
// PAREIDOLIA CARES ABOUT NOTHING ELSE. Curvature extrema and a medial axis are
// both defined along an ORDERED boundary: "where does this ring turn sharply"
// has no meaning for a point set whose neighbours are arbitrary. So the matcher
// needs a real traced contour, and this is that tracer.
//
// NO AE AND NO GPU HEADERS, like the rest of src/engine/. Pixels in, rings out.
//
// WHAT IT IS FOR HERE. This came across from a rigid-body engine, where a traced
// ring became a soft body's boundary. There is no solver now; the ring is the
// front half of pareidolia -- matte -> ring -> curvature extrema -> medial axis --
// and the tracer is reused unchanged because that first step is identical.
//
// MARCHING SQUARES, NOT NEIGHBOUR-FOLLOWING, and the reason is robustness
// rather than quality. A boundary-following tracer has to decide what is an
// outer contour and what is a hole, has to label connected components to know
// when it is finished, and has a fiddly special case at every one-pixel-wide
// neck. Marching squares has none of that: it emits line segments per 2x2 cell,
// every crossing lies on a grid edge shared by exactly two cells, so every
// crossing joins exactly two segments and the segments therefore link into
// closed loops with no topology decisions at all. Holes and several separate
// blobs fall out of it for free.

#include "Geometry.h"
#include "Image.h"
#include "Types.h"

#include <cstddef>
#include <vector>

namespace plugin::sim {

// HOW MANY POINTS ONE TRACED RING MAY KEEP.
//
// A 256-pixel render of a rounded blob produces something like 800 crossings,
// nearly all of them describing the staircase of the pixel grid rather than the
// shape. The mesher would thin them anyway (it drops anything closer together
// than half its spacing), so this is about not carrying an order of magnitude
// more points than anything downstream can use.
constexpr size_t kMaxContourPoints = 400;

// HOW FAR A SIMPLIFIED RING MAY STRAY from the traced one, in the TRACE's own
// pixels. Just under one pixel: enough to take the staircase off a diagonal
// edge, small enough to keep a corner a corner.
constexpr float kDefaultContourTolerancePx = 0.75f;

// Every closed contour in the image, in the view's own PIXEL COORDINATES: +X
// right, +Y down, origin at the top-left corner of pixel (0, 0).
//
// Crossings are placed by LINEAR INTERPOLATION between the two corner alphas, so
// the contour follows a soft or anti-aliased edge rather than the pixel grid --
// and, because both cells sharing a grid edge compute that crossing from the
// same two values, the two agree exactly and the segments still link.
//
// SORTED LARGEST FIRST, by absolute area. The largest ring is the silhouette and
// every other one is a hole in it, so a caller that wants the shape and not the
// gaps in it can take rings[0] and stop.
//
// Rings smaller than `minAreaPx2` are dropped: a stray anti-aliased pixel in a
// corner is a contour, and it is not a body.
//
// EMPTY IS A NORMAL ANSWER -- a fully transparent frame, or a layer whose
// content has not started yet. The caller falls back, it does not fail.
std::vector<Polygon> traceAlphaContours(const ConstImageView& img,
                                        Scalar threshold  = kDefaultAlphaThreshold,
                                        float  tolerancePx = kDefaultContourTolerancePx,
                                        size_t maxPoints   = kMaxContourPoints,
                                        float  minAreaPx2  = 4.0f);

// Douglas-Peucker on a CLOSED ring. Exposed for its own tests.
//
// The two points furthest apart are kept as the initial pair, rather than an
// arbitrary first vertex, so the result does not depend on where the ring
// happens to start -- which matters because the tracer's starting point is
// wherever the scan found the first crossing.
Polygon simplifyContour(const Polygon& ring, float tolerancePx);

} // namespace plugin::sim
