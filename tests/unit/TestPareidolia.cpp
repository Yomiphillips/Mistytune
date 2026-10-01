// Pareidolia's host half (src/engine/Pareidolia.h): a picture in, a signed distance map
// out, and the fit that places it on the hero.
//
// THE KERNEL'S HALF IS slang.convection, which stands a map up in the density and checks
// the box bound against it. These check the steps before: that the map IS a distance --
// exact, not a chamfer -- with the right sign and the right way up, that each channel reads
// the number it names, that the fit keeps the picture's aspect inside the hero, and that
// nothing about a default render changes when there is no picture.

#include "TestFramework.h"

#include "KernelApi.h"
#include "Pareidolia.h"

#include <cmath>
#include <cstdio>
#include <functional>
#include <limits>
#include <vector>

using namespace plugin;
using namespace plugin::cloud;

namespace {

// A premultiplied ARGB float picture, drawn by a coverage function of the pixel centre.
struct Picture {
    int w = 0, h = 0;
    std::vector<float> argb;

    Picture(int width, int height, const std::function<void(int, int, float*)>& paint)
        : w(width), h(height), argb(static_cast<size_t>(width) * height * 4, 0.0f) {
        for (int y = 0; y < h; ++y)
            for (int x = 0; x < w; ++x) paint(x, y, argb.data() + (static_cast<size_t>(y) * w + x) * 4);
    }

    ConstImageView view() const {
        ConstImageView v;
        v.data = argb.data();
        v.width = w;
        v.height = h;
        v.rowBytes = static_cast<std::ptrdiff_t>(w) * 4 * sizeof(float);
        v.format = PixelFormat::ARGB32F;
        return v;
    }
};

// An opaque-white shape drawn in alpha on a transparent frame.
Picture alphaShape(int w, int h, const std::function<bool(double, double)>& inside) {
    return Picture(w, h, [&](int x, int y, float* p) {
        const float a = inside(x + 0.5, y + 0.5) ? 1.0f : 0.0f;
        p[0] = a; p[1] = a; p[2] = a; p[3] = a;
    });
}

float mapAt(const ShapeMap& m, int i, int j, int k = 0) {
    return m.texels[(static_cast<size_t>(j) * m.width + i) * 4 + k];
}

ConvectionDerived heroOf(float radius, float top) {
    ConvectionDerived cd;
    cd.present    = true;
    cd.heroRadius = radius;
    cd.heroTop    = top;
    cd.heroBillow = 1.0f;
    return cd;
}

} // namespace

// A DISC'S MAP IS ITS DISTANCE, to within the texel: the deepest point is the radius, the
// sign flips at the edge, and the slope points inwards at one per texel.
PL_TEST(ADiscMapsToItsDistance) {
    // FINE ENOUGH THAT THE SOURCE'S OWN PIXELS DO NOT SHOW: a 480-pixel disc is about two
    // source pixels a texel. A 120-pixel one came out 1.8 texels short at the centre, which
    // is its own staircase edge, half a pixel on the diagonal, and not the transform.
    const double r = 240.0;
    const Picture pic = alphaShape(600, 600, [&](double x, double y) {
        return (x - 300) * (x - 300) + (y - 300) * (y - 300) < r * r;
    });

    ShapeMap m;
    PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m));

    // The silhouette's longer side is kShapeMapInner texels, so the radius is half that.
    const double radiusTexels = 0.5 * kShapeMapInner;
    float deepest = -1e9f;
    for (int j = 0; j < m.height; ++j)
        for (int i = 0; i < m.width; ++i) deepest = std::max(deepest, mapAt(m, i, j));
    // Less the half diagonal: the disc's centre lands on a texel corner, so the deepest
    // texel's centre is sqrt(0.5) from it.
    PL_CHECK_NEAR(deepest, radiusTexels - std::sqrt(0.5), 1.0);

    // Everywhere, the distance to the centre says what the map should be.
    const double ci = 0.5 * (m.boxLoU + m.boxHiU), cj = 0.5 * (m.boxLoY + m.boxHiY);
    double worst = 0.0;
    for (int j = 0; j < m.height; ++j) {
        for (int i = 0; i < m.width; ++i) {
            const double want = radiusTexels - std::hypot(i + 0.5 - ci, j + 0.5 - cj);
            worst = std::max(worst, std::fabs(mapAt(m, i, j) - want));
        }
    }
    PL_CHECK_NEAR(worst, 0.0, 1.0);

    // The corners are outside; the slope right of centre points back left, at one.
    PL_CHECK(mapAt(m, 0, 0) < 0.0f);
    PL_CHECK(mapAt(m, m.width - 1, m.height - 1) < 0.0f);
    const int ri = static_cast<int>(ci + 0.5 * radiusTexels);
    const int rj = static_cast<int>(cj);
    PL_CHECK_NEAR(mapAt(m, ri, rj, 1), -1.0, 0.1);
    PL_CHECK_NEAR(mapAt(m, ri, rj, 2), 0.0, 0.1);
}

// NEIGHBOURING TEXELS DIFFER BY AT MOST ONE, which is the property the kernel's slope bound
// (kShapeLipschitz) is built on. An exact distance transform has it; a chamfer does not
// quite, and a sign convention that put the zero on the texel centres would break it at
// the edge.
PL_TEST(NeighboursDifferByAtMostOne) {
    const Picture pic = alphaShape(300, 180, [](double x, double y) {
        const bool blob = (x - 90) * (x - 90) + (y - 90) * (y - 90) < 70 * 70;
        const bool bar  = x > 150 && x < 290 && y > 40 && y < 70;
        const bool hole = (x - 70) * (x - 70) + (y - 80) * (y - 80) < 15 * 15;
        return (blob || bar) && !hole;
    });
    ShapeMap m;
    PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m));

    double worst = 0.0;
    for (int j = 0; j < m.height; ++j) {
        for (int i = 0; i < m.width; ++i) {
            if (i + 1 < m.width) worst = std::max(worst, double(std::fabs(mapAt(m, i + 1, j) - mapAt(m, i, j))));
            if (j + 1 < m.height) worst = std::max(worst, double(std::fabs(mapAt(m, i, j + 1) - mapAt(m, i, j))));
        }
    }
    PL_CHECK(worst <= 1.0 + 1e-4);
}

// EACH CHANNEL READS THE NUMBER IT NAMES: an opaque frame with a white square on black.
PL_TEST(EachChannelReadsItsNumber) {
    const Picture pic(100, 80, [](int x, int y, float* p) {
        const float v = (x >= 30 && x < 70 && y >= 20 && y < 60) ? 1.0f : 0.0f;
        p[0] = 1.0f; p[1] = v; p[2] = v; p[3] = v;
    });

    ShapeMap alpha, luma, invLuma, invAlpha;

    // Alpha: the whole opaque frame is the shape.
    PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, alpha));
    PL_CHECK_NEAR((alpha.boxHiU - alpha.boxLoU) / (alpha.boxHiY - alpha.boxLoY), 100.0 / 80.0, 0.02);

    // Luminance: the square.
    PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::Luminance, 0.5f, luma));
    PL_CHECK_NEAR((luma.boxHiU - luma.boxLoU) / (luma.boxHiY - luma.boxLoY), 1.0, 0.02);

    // Inverted luminance: the frame round the square, so its box is the frame's and its
    // middle is a hole.
    PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::InvertedLuminance, 0.5f, invLuma));
    const int mi = static_cast<int>(0.5f * (invLuma.boxLoU + invLuma.boxHiU));
    const int mj = static_cast<int>(0.5f * (invLuma.boxLoY + invLuma.boxHiY));
    PL_CHECK(mapAt(invLuma, mi, mj) < 0.0f);

    // Inverted alpha of an opaque frame is nothing at all.
    PL_CHECK(!buildShapeMap(pic.view(), ShapeChannel::InvertedAlpha, 0.5f, invAlpha));
    PL_CHECK(invAlpha.empty());
}

// A BLANK PICTURE IS NO SHAPE, and nothing downstream turns on.
PL_TEST(NothingAboveTheThresholdIsNoShape) {
    const Picture pic = alphaShape(64, 64, [](double, double) { return false; });
    ShapeMap m;
    PL_CHECK(!buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m));
    PL_CHECK(m.empty());
    PL_CHECK(!resolveShape(&m, PareidoliaParams{}, heroOf(1500.0f, 1700.0f)).on);
    PL_CHECK(!resolveShape(nullptr, PareidoliaParams{}, heroOf(1500.0f, 1700.0f)).on);

    // A half-transparent mark is a shape under a threshold below it and none above it.
    const Picture half = Picture(8, 8, [](int x, int, float* p) {
        const float a = x < 4 ? 0.6f : 0.0f;
        p[0] = a; p[1] = a; p[2] = a; p[3] = a;
    });
    PL_CHECK(buildShapeMap(half.view(), ShapeChannel::Alpha, 0.5f, m));
    PL_CHECK(!buildShapeMap(half.view(), ShapeChannel::Alpha, 0.7f, m));
}

// THE MAP IS THE SILHOUETTE'S BOX AT kShapeMapInner TEXELS ALONG ITS LONGER SIDE, with the
// margin clear all round -- whatever the picture's resolution, and wherever in its frame
// the silhouette sits.
PL_TEST(TheBoxFillsTheInnerTexels) {
    for (int size : { 40, 300, 1500 }) {
        const Picture pic = alphaShape(size * 2, size, [&](double x, double y) {
            return x > size * 1.2 && x < size * 1.6 && y > size * 0.1 && y < size * 0.9;
        });
        ShapeMap m;
        PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m));
        const float bw = m.boxHiU - m.boxLoU, bh = m.boxHiY - m.boxLoY;
        PL_CHECK_NEAR(std::max(bw, bh), kShapeMapInner, 2.0);
        PL_CHECK_NEAR(bw / bh, 0.4 / 0.8, 0.03);
        PL_CHECK(m.boxLoU >= kShapeMapMargin - 1 && m.boxLoY >= kShapeMapMargin - 1);
        PL_CHECK(m.boxHiU <= m.width - kShapeMapMargin + 1 && m.boxHiY <= m.height - kShapeMapMargin + 1);
        for (int i = 0; i < m.width; ++i) PL_CHECK(mapAt(m, i, 0) < 0.0f);
    }
}

// ROW ZERO IS THE BOTTOM AND u RUNS RIGHT: an F keeps its arms on the right and its top at
// the top. A mirrored or upside-down map would still be a fine distance field, so this is
// the only thing that says it is the picture.
PL_TEST(AnFStaysTheRightWayRound) {
    const Picture pic = alphaShape(100, 100, [](double x, double y) {
        const bool stem = x >= 20 && x <= 40 && y >= 10 && y <= 90;
        const bool top  = x >= 20 && x <= 80 && y >= 10 && y <= 25;
        return stem || top;
    });
    ShapeMap m;
    PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m));

    auto sample = [&](double fu, double fy) {   // fractions of the box, y UP
        const int i = static_cast<int>(m.boxLoU + fu * (m.boxHiU - m.boxLoU));
        const int j = static_cast<int>(m.boxLoY + fy * (m.boxHiY - m.boxLoY));
        return mapAt(m, i, j);
    };
    PL_CHECK(sample(0.9, 0.92) > 0.0f);   // the arm: right, at the top
    PL_CHECK(sample(0.9, 0.10) < 0.0f);   // nothing right at the bottom
    PL_CHECK(sample(0.1, 0.10) > 0.0f);   // the stem's foot: left, at the bottom
}

// THE FIT IS CONTAIN: the silhouette keeps its aspect inside Hero Width by the hero's
// height, its middle over the hero's centre and its bottom on the base.
PL_TEST(TheFitContainsTheSilhouette) {
    const ConvectionDerived cd = heroOf(1500.0f, 1700.0f);
    auto fitOf = [&](int w, int h) {
        const Picture pic = alphaShape(w, h, [](double, double) { return true; });
        ShapeMap m;
        buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m);
        return resolveShape(&m, PareidoliaParams{}, cd);
    };

    const ShapeGeometry square = fitOf(100, 100);
    PL_CHECK(square.on);
    PL_CHECK_NEAR(square.widthMetres, 1700.0, 1.0);
    PL_CHECK_NEAR(square.heightMetres, 1700.0, 1.0);

    const ShapeGeometry tall = fitOf(50, 100);
    PL_CHECK_NEAR(tall.heightMetres, 1700.0, 1.0);
    PL_CHECK_NEAR(tall.widthMetres, 850.0, 10.0);

    const ShapeGeometry wide = fitOf(200, 100);
    PL_CHECK_NEAR(wide.widthMetres, 3000.0, 1.0);
    PL_CHECK_NEAR(wide.heightMetres, 1500.0, 10.0);

    // The rims: depth x half the smaller side, and the extent reaches the far corner.
    PareidoliaParams p;
    p.depth = 1.0f;
    const Picture pic = alphaShape(100, 100, [](double, double) { return true; });
    ShapeMap m;
    buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m);
    const ShapeGeometry g = resolveShape(&m, p, cd);
    PL_CHECK_NEAR(g.round, 850.0, 1.0);
    PL_CHECK_NEAR(g.extent, std::hypot(850.0, 850.0), 1.0);

    // Its bottom middle is the plane's origin: offsetY is the box's bottom edge.
    PL_CHECK_NEAR(g.offsetY, m.boxLoY, 1e-6);
    PL_CHECK_NEAR(g.offsetU, 0.5 * (m.boxLoU + m.boxHiU), 1e-6);

    // No hero, no shape.
    ConvectionDerived none = cd;
    none.heroTop = 0.0f;
    PL_CHECK(!resolveShape(&m, p, none).on);
}

// TURN TO CAMERA FACES THE EYE, in the orbit rig's convention: an eye at hero + d (sin b,
// cos b) is bearing b. The plane's u axis is then the camera's right.
PL_TEST(TheShapeTurnsToTheCamera) {
    ViewParams v;
    v.observerX = 0.0f; v.observerZ = 4000.0f;
    PL_CHECK_NEAR(shapeBearingToCamera(v, 0.0f, 0.0f), 0.0, 1e-4);
    v.observerX = 4000.0f; v.observerZ = 0.0f;
    PL_CHECK_NEAR(shapeBearingToCamera(v, 0.0f, 0.0f), 90.0, 1e-4);
    v.observerX = 500.0f; v.observerZ = -3000.0f;
    PL_CHECK_NEAR(shapeBearingToCamera(v, 500.0f, 1000.0f), 180.0, 1e-4);

    // Straight underneath: back along the view. The identity camera looks down -Z.
    ViewParams under;
    under.observerX = 10.0f; under.observerZ = 10.0f;
    PL_CHECK_NEAR(shapeBearingToCamera(under, 10.0f, 10.0f), 0.0, 1e-4);

    // placeShape honours Fixed.
    PareidoliaParams p;
    p.facing = 1;
    p.bearing = 33.0f;
    placeShape(p, v, 0.0f, 0.0f);
    PL_CHECK_NEAR(p.bearing, 33.0, 1e-6);
    p.facing = 0;
    placeShape(p, v, 500.0f, 1000.0f);
    PL_CHECK_NEAR(p.bearing, 180.0, 1e-4);
}

// THE AXIS FOLLOWS THE BEARING: u = (cos b, -sin b), so at bearing 0 it is +X, the default
// camera's right, and the normal (-u.z, u.x) points at the eye.
PL_TEST(TheBearingSetsTheAxis) {
    const ConvectionDerived cd = heroOf(1500.0f, 1700.0f);
    const Picture pic = alphaShape(50, 50, [](double, double) { return true; });
    ShapeMap m;
    buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m);

    PareidoliaParams p;
    p.bearing = 0.0f;
    ShapeGeometry g = resolveShape(&m, p, cd);
    PL_CHECK_NEAR(g.axisUX, 1.0, 1e-6);
    PL_CHECK_NEAR(g.axisUZ, 0.0, 1e-6);

    p.bearing = 90.0f;
    g = resolveShape(&m, p, cd);
    PL_CHECK_NEAR(g.axisUX, 0.0, 1e-6);
    PL_CHECK_NEAR(g.axisUZ, -1.0, 1e-6);
    PL_CHECK_NEAR(-g.axisUZ, 1.0, 1e-6);   // the normal's x: towards an eye on +X

    // A dial keyframed round ten times lands where one turn would.
    p.bearing = 90.0f + 3600.0f;
    const ShapeGeometry again = resolveShape(&m, p, cd);
    PL_CHECK_NEAR(again.axisUX, g.axisUX, 1e-5);
    PL_CHECK_NEAR(again.axisUZ, g.axisUZ, 1e-5);
}

// NANS AND OUT-OF-RANGE EXPRESSIONS COME OUT AS NUMBERS the kernel's bounds hold for.
PL_TEST(ExpressionsCannotBreakTheShape) {
    const ConvectionDerived cd = heroOf(1500.0f, 1700.0f);
    const Picture pic = alphaShape(50, 70, [](double x, double y) { return x + y < 90; });
    ShapeMap m;
    PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::Alpha, std::numeric_limits<float>::quiet_NaN(), m));

    const float nan = std::numeric_limits<float>::quiet_NaN();
    for (float bad : { nan, -5.0f, 7.0f, 1e30f, -1e30f }) {
        PareidoliaParams p;
        p.decay = bad; p.depth = bad; p.billows = bad; p.bearing = bad;
        const ShapeGeometry g = resolveShape(&m, p, cd);
        PL_CHECK(g.on);
        PL_CHECK(g.decay >= 0.0f && g.decay <= 1.0f);
        PL_CHECK(g.billow >= 0.0f && g.billow <= 1.0f);
        PL_CHECK(g.round >= 1.0f && std::isfinite(g.round));
        PL_CHECK(std::isfinite(g.axisUX) && std::isfinite(g.axisUZ));
        PL_CHECK_NEAR(g.axisUX * g.axisUX + g.axisUZ * g.axisUZ, 1.0, 1e-5);
    }
}

// THE HASH FOLLOWS THE PICTURE, which nothing else does: it is not a parameter.
PL_TEST(TheHashFollowsThePicture) {
    auto disc = [](double r) {
        return alphaShape(100, 100, [r](double x, double y) {
            return (x - 50) * (x - 50) + (y - 50) * (y - 50) < r * r;
        });
    };
    ShapeMap a, b, c;
    buildShapeMap(disc(30).view(), ShapeChannel::Alpha, 0.5f, a);
    buildShapeMap(disc(30).view(), ShapeChannel::Alpha, 0.5f, b);
    PL_CHECK(a.hash == b.hash);

    // A dent the size of a few texels is a different shape.
    const Picture dented = alphaShape(100, 100, [](double x, double y) {
        const bool in = (x - 50) * (x - 50) + (y - 50) * (y - 50) < 30.0 * 30.0;
        const bool dent = (x - 50) * (x - 50) + (y - 20) * (y - 20) < 6.0 * 6.0;
        return in && !dent;
    });
    buildShapeMap(dented.view(), ShapeChannel::Alpha, 0.5f, c);
    PL_CHECK(a.hash != c.hash);
}

// WITH NO PICTURE, A RENDER IS WHAT IT WAS: deriveRenderInputs leaves the shape off and
// points the kernel at nothing. With one, it points at the caller's texels and hash.
PL_TEST(NoPictureIsTheHeroAsItWas) {
    kernel::RenderRequest req;
    req.field.convection.enabled  = true;
    req.field.convection.heroMode = 1;
    kernel::deriveRenderInputs(req);
    PL_CHECK(!req.shape.on);
    PL_CHECK(req.shapeBuffer == nullptr);
    PL_CHECK(req.shapeHash == 0u);

    const Picture pic = alphaShape(64, 64, [](double x, double y) {
        return (x - 32) * (x - 32) + (y - 32) * (y - 32) < 20 * 20;
    });
    ShapeMap m;
    PL_CHECK(buildShapeMap(pic.view(), ShapeChannel::Alpha, 0.5f, m));
    req.shapeMap = &m;
    kernel::deriveRenderInputs(req);
    PL_CHECK(req.shape.on == req.convection.present);
    if (req.shape.on) {
        PL_CHECK(req.shapeBuffer == m.texels.data());
        PL_CHECK(req.shapeHash == m.hash);
        PL_CHECK(req.shape.heightMetres <= req.convection.heroTop + 1e-3f);
        PL_CHECK(req.shape.widthMetres <= 2.0f * req.convection.heroRadius + 1e-3f);
    }

    // The hero off is the shape off, picture or not.
    req.field.convection.heroMode = 0;
    kernel::deriveRenderInputs(req);
    PL_CHECK(!req.shape.on);
    PL_CHECK(req.shapeBuffer == nullptr);
}
