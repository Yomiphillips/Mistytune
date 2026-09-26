#include "Contour.h"

#include <algorithm>
#include <cmath>
#include <map>

namespace plugin::sim {

namespace {

// Alpha alone. Same helper and same reasoning as Trace.cpp's: this runs over
// every pixel of a rendered layer, so unpacking the colour channels as well
// would be three multiplies and a table lookup each, thrown away.
//
// OUT OF BOUNDS IS TRANSPARENT, and that is load-bearing rather than defensive.
// It is what lets the cell grid run one step past every edge of the image: a
// shape that touches the border then still has outside on the far side of it,
// so its contour closes along the border instead of running off the end.
Scalar alphaAt(const ConstImageView& img, int x, int y) {
    if (x < 0 || y < 0 || x >= img.width || y >= img.height) return 0;
    switch (img.format) {
        case PixelFormat::ARGB8:
            return kChan8.v[img.rowPtr<uint8_t>(y)[static_cast<std::ptrdiff_t>(x) * 4]];
        case PixelFormat::ARGB16:
            return img.rowPtr<uint16_t>(y)[static_cast<std::ptrdiff_t>(x) * 4] * kInvChan16;
        case PixelFormat::ARGB32F:
            return img.rowPtr<float>(y)[static_cast<std::ptrdiff_t>(x) * 4];
    }
    return 0;
}

// WHICH GRID EDGE A CROSSING SITS ON, as one integer.
//
// This is the key to the whole tracer. A crossing is identified by the EDGE it
// lies on rather than by its coordinates, so two cells that share an edge
// necessarily agree on it -- exactly, with no float comparison and no epsilon.
// Identify crossings by position instead and a rounding difference between the
// two cells silently splits one loop into two open chains.
//
// kind 0 is the horizontal edge from corner (x, y) to (x + 1, y); kind 1 is the
// vertical edge from (x, y) to (x, y + 1). The +2 bias keeps the packed value
// positive for the x = -1 and y = -1 cells.
int64_t edgeKey(int kind, int x, int y) {
    return (static_cast<int64_t>(y + 2) << 34) |
           (static_cast<int64_t>(x + 2) << 4)  |
            static_cast<int64_t>(kind);
}

// Where along a grid edge the alpha crosses the threshold, as a fraction.
//
// Guarded because two equal alphas cannot produce a crossing at all -- the
// caller only asks when the two corners are on opposite sides, but a denormal
// difference would still divide badly.
float crossingT(Scalar a, Scalar b, Scalar threshold) {
    const Scalar d = b - a;
    if (d > -1e-12 && d < 1e-12) return 0.5f;
    const Scalar t = (threshold - a) / d;
    return static_cast<float>(t < 0 ? 0 : (t > 1 ? 1 : t));
}

// The crossings of one image, and which pairs of them a cell joins.
struct Crossings {
    std::vector<Vec2>                       points;
    std::vector<std::pair<uint32_t, uint32_t>> segments;
    std::map<int64_t, uint32_t>             byEdge;
};

// Finds or creates the crossing on one grid edge. `ax, ay` and `bx, by` are the
// edge's two corners in pixel coordinates.
uint32_t crossingOn(Crossings& c, const ConstImageView& img, Scalar threshold,
                    int kind, int ex, int ey,
                    int ax, int ay, int bx, int by) {
    const int64_t key = edgeKey(kind, ex, ey);
    auto it = c.byEdge.find(key);
    if (it != c.byEdge.end()) return it->second;

    const Scalar a = alphaAt(img, ax, ay);
    const Scalar b = alphaAt(img, bx, by);
    const float  t = crossingT(a, b, threshold);

    // PIXEL CENTRES, like Trace.h's silhouette: corner (x, y) of the cell grid
    // IS the centre of pixel (x, y). So a contour sits up to half a pixel inside
    // the true silhouette, which is the safe direction -- a body's outline can
    // be slightly small but never slightly large.
    const Vec2 p{ static_cast<float>(ax) + (static_cast<float>(bx - ax)) * t,
                  static_cast<float>(ay) + (static_cast<float>(by - ay)) * t };

    const uint32_t index = static_cast<uint32_t>(c.points.size());
    c.points.push_back(p);
    c.byEdge.emplace(key, index);
    return index;
}

// ---------------------------------------------------------------------------

// Douglas-Peucker over an OPEN run of points, keeping the ends.
void douglasPeucker(const Polygon& p, size_t first, size_t last,
                    float tolerance, std::vector<bool>& keep) {
    if (last <= first + 1) return;

    const Vec2& a = p[first];
    const Vec2& b = p[last];
    const float dx = b.x - a.x, dy = b.y - a.y;
    const float len2 = dx * dx + dy * dy;

    size_t worst = first;
    float  worstDist = -1.0f;
    for (size_t i = first + 1; i < last; ++i) {
        float d;
        if (len2 < 1e-12f) {
            const float ex = p[i].x - a.x, ey = p[i].y - a.y;
            d = std::sqrt(ex * ex + ey * ey);
        } else {
            // Perpendicular distance to the segment's LINE, which is what
            // Douglas-Peucker measures -- the points between two kept ones are
            // by construction between them along the run.
            d = std::fabs((p[i].x - a.x) * dy - (p[i].y - a.y) * dx) / std::sqrt(len2);
        }
        if (d > worstDist) { worstDist = d; worst = i; }
    }

    if (worstDist <= tolerance) return;
    keep[worst] = true;
    douglasPeucker(p, first, worst, tolerance, keep);
    douglasPeucker(p, worst, last, tolerance, keep);
}

} // namespace

Polygon simplifyContour(const Polygon& ring, float tolerancePx) {
    if (ring.size() < 4 || tolerancePx <= 0.0f) return ring;

    // THE TWO FURTHEST-APART POINTS ANCHOR IT, not vertex 0 and the midpoint.
    //
    // A closed ring has no natural ends for Douglas-Peucker to keep, and the
    // tracer's vertex 0 is simply wherever the scan happened to find the first
    // crossing. Splitting at an arbitrary vertex would make the simplification
    // depend on that, so the same shape traced from a slightly different render
    // would simplify differently. The diameter is a property of the shape.
    size_t a = 0, b = 0;
    float  best = -1.0f;
    for (size_t i = 0; i < ring.size(); ++i) {
        const float dx = ring[i].x - ring[0].x, dy = ring[i].y - ring[0].y;
        const float d = dx * dx + dy * dy;
        if (d > best) { best = d; a = i; }
    }
    best = -1.0f;
    for (size_t i = 0; i < ring.size(); ++i) {
        const float dx = ring[i].x - ring[a].x, dy = ring[i].y - ring[a].y;
        const float d = dx * dx + dy * dy;
        if (d > best) { best = d; b = i; }
    }
    if (a == b) return ring;
    if (a > b) std::swap(a, b);

    std::vector<bool> keep(ring.size(), false);
    keep[a] = true;
    keep[b] = true;

    // The ring as two open runs between the anchors: a..b the short way round
    // the indices, and b..a through the wrap.
    douglasPeucker(ring, a, b, tolerancePx, keep);

    Polygon tail;
    std::vector<size_t> tailIndex;
    for (size_t i = b; ; ++i) {
        const size_t k = i % ring.size();
        tail.push_back(ring[k]);
        tailIndex.push_back(k);
        if (k == a) break;
    }
    std::vector<bool> tailKeep(tail.size(), false);
    tailKeep.front() = tailKeep.back() = true;
    douglasPeucker(tail, 0, tail.size() - 1, tolerancePx, tailKeep);
    for (size_t i = 0; i < tail.size(); ++i) {
        if (tailKeep[i]) keep[tailIndex[i]] = true;
    }

    Polygon out;
    for (size_t i = 0; i < ring.size(); ++i) {
        if (keep[i]) out.push_back(ring[i]);
    }
    return out.size() >= 3 ? out : ring;
}

std::vector<Polygon> traceAlphaContours(const ConstImageView& img,
                                        Scalar threshold,
                                        float  tolerancePx,
                                        size_t maxPoints,
                                        float  minAreaPx2) {
    std::vector<Polygon> rings;
    if (!img.valid()) return rings;

    Crossings c;

    // ONE STEP PAST EVERY EDGE, so a shape touching the border still has a cell
    // with outside on the far side of it and its contour closes. See alphaAt.
    for (int y = -1; y < img.height; ++y) {
        for (int x = -1; x < img.width; ++x) {
            // Corners of cell (x, y), as marching-squares bits.
            const bool c00 = alphaAt(img, x,     y    ) >= threshold;
            const bool c10 = alphaAt(img, x + 1, y    ) >= threshold;
            const bool c11 = alphaAt(img, x + 1, y + 1) >= threshold;
            const bool c01 = alphaAt(img, x,     y + 1) >= threshold;

            const int code = (c00 ? 1 : 0) | (c10 ? 2 : 0) | (c11 ? 4 : 0) | (c01 ? 8 : 0);
            if (code == 0 || code == 15) continue;

            // The four edges a crossing can sit on, fetched only when needed.
            const auto top    = [&] { return crossingOn(c, img, threshold, 0, x,     y,     x, y,         x + 1, y    ); };
            const auto bottom = [&] { return crossingOn(c, img, threshold, 0, x,     y + 1, x, y + 1,     x + 1, y + 1); };
            const auto left   = [&] { return crossingOn(c, img, threshold, 1, x,     y,     x, y,         x,     y + 1); };
            const auto right  = [&] { return crossingOn(c, img, threshold, 1, x + 1, y,     x + 1, y,     x + 1, y + 1); };

            // The standard 16 cases. 5 and 10 are the ambiguous diagonals -- the
            // two opposite corners could be one neck or two separate lobes, and
            // the image cannot say which. EITHER pairing gives closed loops, so
            // what matters is only that the choice is CONSISTENT; both are
            // resolved here as two separate corners.
            switch (code) {
                case 1: case 14: c.segments.emplace_back(left(),   top());    break;
                case 2: case 13: c.segments.emplace_back(top(),    right());  break;
                case 3: case 12: c.segments.emplace_back(left(),   right());  break;
                case 4: case 11: c.segments.emplace_back(right(),  bottom()); break;
                case 6: case 9:  c.segments.emplace_back(top(),    bottom()); break;
                case 7: case 8:  c.segments.emplace_back(left(),   bottom()); break;
                case 5:
                    c.segments.emplace_back(left(), top());
                    c.segments.emplace_back(right(), bottom());
                    break;
                case 10:
                    c.segments.emplace_back(top(), right());
                    c.segments.emplace_back(left(), bottom());
                    break;
                default: break;
            }
        }
    }
    if (c.points.empty()) return rings;

    // EVERY CROSSING JOINS EXACTLY TWO SEGMENTS, because the grid edge it sits on
    // is shared by exactly two cells and each contributes one endpoint there. So
    // walking is unambiguous: from each point, go to whichever neighbour is not
    // the one just come from.
    std::vector<uint32_t> link0(c.points.size(), UINT32_MAX);
    std::vector<uint32_t> link1(c.points.size(), UINT32_MAX);
    const auto join = [&](uint32_t a, uint32_t b) {
        if (link0[a] == UINT32_MAX) link0[a] = b; else if (link1[a] == UINT32_MAX) link1[a] = b;
    };
    for (const std::pair<uint32_t, uint32_t>& s : c.segments) {
        join(s.first, s.second);
        join(s.second, s.first);
    }

    std::vector<bool> seen(c.points.size(), false);
    for (uint32_t start = 0; start < c.points.size(); ++start) {
        if (seen[start] || link0[start] == UINT32_MAX) continue;

        Polygon ring;
        uint32_t prev = UINT32_MAX;
        uint32_t here = start;
        while (here != UINT32_MAX && !seen[here]) {
            seen[here] = true;
            ring.push_back(c.points[here]);

            const uint32_t a = link0[here], b = link1[here];
            const uint32_t next = (a != prev && a != UINT32_MAX) ? a : b;
            prev = here;
            here = next;
        }

        if (ring.size() < 3) continue;
        if (std::fabs(doubleSignedArea(ring)) < minAreaPx2 * 2.0f) continue;

        Polygon simplified = simplifyContour(ring, tolerancePx);

        // OVER BUDGET IS SIMPLIFIED HARDER, never truncated: dropping the tail
        // of a ring does not make it smaller, it makes it a different shape with
        // a straight line across the missing part.
        float tol = tolerancePx;
        for (int attempt = 0; simplified.size() > maxPoints && attempt < 20; ++attempt) {
            tol *= 1.6f;
            simplified = simplifyContour(ring, tol);
        }
        if (simplified.size() < 3) continue;
        rings.push_back(std::move(simplified));
    }

    // LARGEST FIRST. The largest ring is the silhouette and the rest are holes in
    // it, so a caller that wants the shape and not the gaps takes rings[0] and
    // stops reading.
    std::sort(rings.begin(), rings.end(), [](const Polygon& a, const Polygon& b) {
        return std::fabs(doubleSignedArea(a)) > std::fabs(doubleSignedArea(b));
    });
    return rings;
}

} // namespace plugin::sim
