#pragma once

// The 2D primitives the contour tracer needs, and nothing else.
//
// WHY THIS FILE EXISTS. Contour.{h,cpp} came across from Gravitune's rigid-body
// engine, where Vec2, Polygon and doubleSignedArea lived in Hull.h beside the
// convex-hull and collision-outline code. None of that survives here -- there is
// no solver to build colliders for -- but the tracer does: matte -> ring ->
// curvature extrema -> medial axis is the front half of pareidolia, and this is
// the ring half.
//
// So the three things the tracer actually used were lifted out to sit on their
// own rather than dragging a hull builder along behind them.
//
// NO AE HEADERS AND NO GPU HEADERS, like the rest of src/engine/.

#include "Types.h"

#include <cstddef>
#include <vector>

namespace plugin::sim {

struct Vec2 {
    float x = 0.0f;
    float y = 0.0f;
};

using Polygon = std::vector<Vec2>;

// Twice the signed area. NEGATIVE for a clockwise ring in AE coordinates
// (+Y down), which is what a shape drawn clockwise on screen gives.
//
// Doubled because that is what the shoelace sum produces naturally and every
// caller only compares it or tests its sign -- halving it would throw away a bit
// of precision to no purpose.
float doubleSignedArea(const Polygon& p);

// Where a matte stops being background.
//
// HALF, not "anything non-zero". An anti-aliased edge ramps across two or three
// pixels; the half-way point is the one that lands on the shape the artist drew
// rather than on the outer fringe of its own feathering.
constexpr Scalar kDefaultAlphaThreshold = 0.5;

} // namespace plugin::sim
