// Tests for the ordered alpha contour tracer.
//
// This is the front half of pareidolia: a matte comes in and an ordered ring
// comes out, and everything after it -- curvature extrema, the medial axis, the
// shape-context match -- is defined along that ordering. It has to produce RINGS
// and not a point set, because "where does this boundary turn sharply" has no
// meaning for points whose neighbours are arbitrary.
//
// Synthetic bitmaps throughout, built here in ARGB8, so none of this needs After
// Effects, a GPU or a render.

#include "TestFramework.h"

#include "Contour.h"

#include <algorithm>
#include <cmath>
#include <vector>

using namespace plugin;
using namespace plugin::sim;

namespace {

// A writable ARGB8 bitmap with a ConstImageView over it.
struct Bitmap {
    int width = 0;
    int height = 0;
    std::vector<uint8_t> pixels;   // ARGB, alpha first

    Bitmap(int w, int h) : width(w), height(h),
                           pixels(static_cast<size_t>(w) * h * 4, 0) {}

    void setAlpha(int x, int y, uint8_t a) {
        if (x < 0 || y < 0 || x >= width || y >= height) return;
        pixels[(static_cast<size_t>(y) * width + x) * 4] = a;
    }

    // A filled axis-aligned rectangle, inclusive of both corners.
    void fillRect(int x0, int y0, int x1, int y1, uint8_t a = 255) {
        for (int y = y0; y <= y1; ++y) {
            for (int x = x0; x <= x1; ++x) setAlpha(x, y, a);
        }
    }

    void fillDisc(float cx, float cy, float r, uint8_t a = 255) {
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                const float dx = static_cast<float>(x) - cx;
                const float dy = static_cast<float>(y) - cy;
                if (dx * dx + dy * dy <= r * r) setAlpha(x, y, a);
            }
        }
    }

    ConstImageView view() const {
        ConstImageView v;
        v.data     = pixels.data();
        v.width    = width;
        v.height   = height;
        v.rowBytes = static_cast<std::ptrdiff_t>(width) * 4;
        v.format   = PixelFormat::ARGB8;
        return v;
    }
};

float ringArea(const Polygon& p) { return std::fabs(doubleSignedArea(p)) * 0.5f; }

// Every consecutive pair of a traced ring must be NEIGHBOURS. A ring whose
// points were emitted in the wrong order has roughly the same points and jumps
// across the shape between them, which this catches and an area check does not.
bool isWellOrdered(const Polygon& ring, float maxStep) {
    for (size_t i = 0; i < ring.size(); ++i) {
        const Vec2& a = ring[i];
        const Vec2& b = ring[(i + 1) % ring.size()];
        const float dx = b.x - a.x, dy = b.y - a.y;
        if (std::sqrt(dx * dx + dy * dy) > maxStep) return false;
    }
    return true;
}

} // namespace

// --------------------------------------------------------------------------
// The basics
// --------------------------------------------------------------------------

PL_TEST(ATransparentImageHasNoContour) {
    const Bitmap b(32, 32);
    PL_CHECK(traceAlphaContours(b.view()).empty());
}

PL_TEST(AnInvalidViewHasNoContour) {
    PL_CHECK(traceAlphaContours(ConstImageView{}).empty());
}

PL_TEST(ASquareTracesToOneRing) {
    Bitmap b(64, 64);
    b.fillRect(16, 16, 47, 47);

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 1);
    PL_CHECK(rings[0].size() >= 4);

    // Points land on pixel CENTRES, so the ring runs 16..47 -- a 31 x 31 square
    // of area 961, not 32 x 32. Slightly INSIDE the silhouette is the safe
    // direction for a body: it can be a shade small, never a shade large.
    PL_CHECK_NEAR(ringArea(rings[0]), 961.0, 40.0);
    PL_CHECK(isWellOrdered(rings[0], 40.0f));
}

// The corners of a rectangle must survive simplification, or a soft body built
// from a square PNG starts life as a rounded blob.
PL_TEST(ASquaresCornersSurviveTracing) {
    Bitmap b(64, 64);
    b.fillRect(16, 16, 47, 47);

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 1);

    const auto hasCorner = [&](float x, float y) {
        return std::any_of(rings[0].begin(), rings[0].end(), [&](const Vec2& p) {
            return std::fabs(p.x - x) < 1.01f && std::fabs(p.y - y) < 1.01f;
        });
    };
    PL_CHECK(hasCorner(16.0f, 16.0f));
    PL_CHECK(hasCorner(47.0f, 16.0f));
    PL_CHECK(hasCorner(47.0f, 47.0f));
    PL_CHECK(hasCorner(16.0f, 47.0f));

    // And a square is four corners plus whatever the tracer could not remove --
    // not the 124 crossings the pixel grid produced.
    PL_CHECK(rings[0].size() < 16);
}

PL_TEST(ADiscTracesToARoundRing) {
    Bitmap b(80, 80);
    b.fillDisc(40.0f, 40.0f, 30.0f);

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 1);
    PL_CHECK_NEAR(ringArea(rings[0]), 3.14159 * 30.0 * 30.0, 300.0);

    // The step bound comes from the simplifier, not from a guess. A chord whose
    // sagitta is the tolerance `t` on a circle of radius `r` is 2*sqrt(2*r*t)
    // long, which at r = 30 and t = 0.75 is about 13.4 px -- so the ring is
    // ALLOWED to take 13 px strides along a gentle arc, and only a jump across
    // the shape means the order is wrong.
    PL_CHECK(isWellOrdered(rings[0], 16.0f));
}

// --------------------------------------------------------------------------
// Topology: the thing a hull tracer never had to get right
// --------------------------------------------------------------------------

// A DONUT. The hole is a second ring, and marching squares finds it with no
// special case at all -- which is the reason for choosing it over a
// boundary-following tracer.
PL_TEST(ADonutTracesToTwoRingsLargestFirst) {
    Bitmap b(80, 80);
    b.fillDisc(40.0f, 40.0f, 32.0f);
    b.fillDisc(40.0f, 40.0f, 14.0f, 0);   // punch the hole back out

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 2);

    // LARGEST FIRST, which is the order a host needs: the outline becomes the
    // Add mask and the hole a Subtract one.
    PL_CHECK(ringArea(rings[0]) > ringArea(rings[1]));
    PL_CHECK_NEAR(ringArea(rings[0]), 3.14159 * 32.0 * 32.0, 350.0);
    PL_CHECK_NEAR(ringArea(rings[1]), 3.14159 * 14.0 * 14.0, 200.0);
}

PL_TEST(TwoSeparateBlobsTraceToTwoRings) {
    Bitmap b(96, 48);
    b.fillRect(6, 12, 29, 35);
    b.fillRect(60, 12, 89, 35);

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 2);
    // The bigger rectangle is first.
    PL_CHECK(ringArea(rings[0]) > ringArea(rings[1]));
}

// A CONCAVE shape has to come back concave. This is precisely what the hull
// tracer could not do, and the whole reason this file exists.
PL_TEST(AConcaveShapeStaysConcave) {
    // A C: a block with a deep bite out of its right side.
    Bitmap b(64, 64);
    b.fillRect(10, 10, 53, 53);
    b.fillRect(28, 22, 53, 41, 0);

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 1);

    // The block is 44 x 44 = 1936 at pixel centres (43 x 43 = 1849); the bite is
    // 26 x 20 = 520. A hull would come back at the full block area, so the test
    // is that it does NOT.
    const float area = ringArea(rings[0]);
    PL_CHECK(area < 1600.0f);
    PL_CHECK(area > 1000.0f);
    PL_CHECK(isWellOrdered(rings[0], 50.0f));
}

// A shape running off the edge of the render must still close, along the border.
// Without the cell grid stepping one past the image, its contour would be an
// open chain and the ring would be dropped.
PL_TEST(AShapeTouchingTheBorderStillCloses) {
    Bitmap b(48, 48);
    b.fillRect(0, 0, 23, 47);        // flush against three edges

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 1);
    PL_CHECK(isWellOrdered(rings[0], 50.0f));
    PL_CHECK_NEAR(ringArea(rings[0]), 23.0 * 47.0, 120.0);
}

PL_TEST(ASpeckIsNotABody) {
    Bitmap b(64, 64);
    b.fillRect(20, 20, 43, 43);
    b.setAlpha(3, 3, 255);           // one stray anti-aliased pixel

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 1);     // the speck has no area worth meshing
}

// --------------------------------------------------------------------------
// The threshold and the soft edge
// --------------------------------------------------------------------------

// Half coverage is the edge, so a feathered edge traces where a viewer reads it
// -- not inflated by the whole width of the feather.
PL_TEST(ASoftEdgeTracesAtHalfCoverage) {
    Bitmap b(64, 64);
    b.fillRect(16, 16, 47, 47);
    // A one-pixel ramp all the way round, at a quarter coverage: below the
    // threshold, so it must NOT widen the silhouette.
    for (int x = 15; x <= 48; ++x) { b.setAlpha(x, 15, 64); b.setAlpha(x, 48, 64); }
    for (int y = 15; y <= 48; ++y) { b.setAlpha(15, y, 64); b.setAlpha(48, y, 64); }

    const std::vector<Polygon> rings = traceAlphaContours(b.view());
    PL_CHECK(rings.size() == 1);
    PL_CHECK_NEAR(ringArea(rings[0]), 961.0, 90.0);
}

// --------------------------------------------------------------------------
// Douglas-Peucker
// --------------------------------------------------------------------------

PL_TEST(SimplifyDropsCollinearPoints) {
    // A square with ten redundant points along each edge.
    Polygon ring;
    for (int i = 0; i < 10; ++i) ring.push_back(Vec2{ static_cast<float>(i) * 10.0f, 0.0f });
    for (int i = 0; i < 10; ++i) ring.push_back(Vec2{ 90.0f, static_cast<float>(i) * 10.0f });
    for (int i = 0; i < 10; ++i) ring.push_back(Vec2{ 90.0f - static_cast<float>(i) * 10.0f, 90.0f });
    for (int i = 0; i < 10; ++i) ring.push_back(Vec2{ 0.0f, 90.0f - static_cast<float>(i) * 10.0f });

    const Polygon simple = simplifyContour(ring, 0.5f);
    PL_CHECK(simple.size() == 4);
    PL_CHECK_NEAR(ringArea(simple), ringArea(ring), 1.0);
}

PL_TEST(SimplifyKeepsTheShape) {
    Polygon ring;
    for (int i = 0; i < 120; ++i) {
        const float a = 6.2831853f * static_cast<float>(i) / 120.0f;
        ring.push_back(Vec2{ 100.0f * std::cos(a), 100.0f * std::sin(a) });
    }
    const Polygon simple = simplifyContour(ring, 1.0f);
    PL_CHECK(simple.size() < ring.size());
    PL_CHECK(simple.size() >= 8);
    PL_CHECK_NEAR(ringArea(simple), ringArea(ring), ringArea(ring) * 0.05);
}

// The tracer's starting vertex is wherever the scan found the first crossing, so
// a simplification anchored on vertex 0 would depend on it. Anchoring on the
// ring's DIAMETER makes it a property of the shape instead.
PL_TEST(SimplifyDoesNotDependOnWhereTheRingStarts) {
    Polygon ring;
    for (int i = 0; i < 60; ++i) {
        const float a = 6.2831853f * static_cast<float>(i) / 60.0f;
        const float r = (i % 7 == 0) ? 120.0f : 100.0f;
        ring.push_back(Vec2{ r * std::cos(a), r * std::sin(a) });
    }

    const Polygon fromZero = simplifyContour(ring, 2.0f);

    Polygon rotated(ring.begin() + 23, ring.end());
    rotated.insert(rotated.end(), ring.begin(), ring.begin() + 23);
    const Polygon fromElsewhere = simplifyContour(rotated, 2.0f);

    PL_CHECK(fromZero.size() == fromElsewhere.size());
    PL_CHECK_NEAR(ringArea(fromZero), ringArea(fromElsewhere), 0.5);
}

PL_TEST(SimplifyRefusesToDestroyARing) {
    const Polygon tri{ {0.0f, 0.0f}, {50.0f, 0.0f}, {25.0f, 40.0f} };
    // A tolerance far bigger than the shape must still leave a ring behind.
    const Polygon simple = simplifyContour(tri, 1000.0f);
    PL_CHECK(simple.size() >= 3);
}
