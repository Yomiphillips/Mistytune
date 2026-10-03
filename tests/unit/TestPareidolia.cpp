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

// ===========================================================================
// RELIEF (build 27): a depth map on the map's fourth float.
// ===========================================================================

namespace {

// An opaque grey depth map: nearness from a function of the pixel centre's FRACTION of the
// frame, so the same function at two sizes is the same picture.
Picture depthMap(int w, int h, const std::function<double(double, double)>& nearness,
                 float alpha = 1.0f) {
    return Picture(w, h, [&](int x, int y, float* p) {
        const float v = static_cast<float>(nearness((x + 0.5) / w, (y + 0.5) / h));
        p[0] = alpha; p[1] = v * alpha; p[2] = v * alpha; p[3] = v * alpha;   // premultiplied
    });
}

Picture discMatte() {
    return alphaShape(200, 200, [](double x, double y) {
        return (x - 100) * (x - 100) + (y - 100) * (y - 100) < 80 * 80;
    });
}

// The steepest step between neighbouring texels of the relief.
float steepestOf(const ShapeMap& m) {
    float worst = 0.0f;
    for (int j = 0; j < m.height; ++j) {
        for (int i = 0; i < m.width; ++i) {
            if (i + 1 < m.width) worst = std::max(worst, std::fabs(mapAt(m, i + 1, j, 3) - mapAt(m, i, j, 3)));
            if (j + 1 < m.height) worst = std::max(worst, std::fabs(mapAt(m, i, j + 1, 3) - mapAt(m, i, j, 3)));
        }
    }
    return worst;
}

} // namespace

// NO RELIEF IS BUILD 21 TO THE BIT: no source, an invalid one, and one flat grey all leave
// the fourth float zero, hasRelief false, and the hash the shape's alone.
PL_TEST(NoReliefIsTheShapeAsItWas) {
    const Picture matte = discMatte();
    ShapeMap plain;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, plain));

    ReliefSource invalid;   // a default view is not valid
    const Picture flat = depthMap(200, 200, [](double, double) { return 0.5; });
    ReliefSource grey;
    grey.view = flat.view();

    const ReliefSource* sources[] = { nullptr, &invalid, &grey };
    for (const ReliefSource* r : sources) {
        ShapeMap m;
        PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, m, r));
        PL_CHECK(!m.hasRelief);
        PL_CHECK(m.hash == plain.hash);
        PL_CHECK(m.texels == plain.texels);
    }
    PL_CHECK(resolveShape(&plain, PareidoliaParams{}, heroOf(1500.0f, 1700.0f)).reliefHeight == 0.0f);
}

// THE RELIEF IS THE DEPTH MAP, STRETCHED: a left-to-right ramp from 0.3 to 0.7 comes out 0 at
// the silhouette's left and 1 at its right, rising across it; inverted, the other way.
PL_TEST(TheReliefIsTheDepthMapStretched) {
    const Picture matte = discMatte();
    const Picture ramp = depthMap(200, 200, [](double fx, double) { return 0.3 + 0.4 * fx; });

    ReliefSource r;
    r.view = ramp.view();
    r.softness = 0.0f;
    r.detail = 0.0f;
    ShapeMap m;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, m, &r));
    PL_CHECK(m.hasRelief);

    float lo = 1.0f, hi = 0.0f;
    for (int j = 0; j < m.height; ++j) {
        for (int i = 0; i < m.width; ++i) {
            if (mapAt(m, i, j) <= 0.0f) continue;
            lo = std::min(lo, mapAt(m, i, j, 3));
            hi = std::max(hi, mapAt(m, i, j, 3));
        }
    }
    PL_CHECK_NEAR(lo, 0.0, 1e-4);
    PL_CHECK_NEAR(hi, 1.0, 1e-4);

    const int mj = static_cast<int>(0.5f * (m.boxLoY + m.boxHiY));
    const int il = static_cast<int>(m.boxLoU + 0.2f * (m.boxHiU - m.boxLoU));
    const int ir = static_cast<int>(m.boxLoU + 0.8f * (m.boxHiU - m.boxLoU));
    PL_CHECK(mapAt(m, il, mj, 3) < 0.3f);
    PL_CHECK(mapAt(m, ir, mj, 3) > 0.7f);

    r.inverted = true;
    ShapeMap inv;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, inv, &r));
    PL_CHECK(mapAt(inv, il, mj, 3) > 0.7f);
    PL_CHECK_NEAR(mapAt(inv, il, mj, 3), 1.0 - mapAt(m, il, mj, 3), 1e-4);
    PL_CHECK(inv.hash != m.hash);
}

// THE DEPTH IS THE STRAIGHT COLOUR: a half-transparent depth pass reads the same nearness
// as an opaque one, not half of it.
PL_TEST(AHalfTransparentDepthPassReadsItsDepth) {
    const Picture matte = discMatte();
    auto bump = [](double fx, double fy) {
        return 0.2 + 0.6 * std::exp(-((fx - 0.5) * (fx - 0.5) + (fy - 0.4) * (fy - 0.4)) / 0.02);
    };
    const Picture opaque = depthMap(200, 200, bump, 1.0f);
    const Picture half   = depthMap(200, 200, bump, 0.5f);

    ReliefSource a, b;
    a.view = opaque.view();
    b.view = half.view();
    ShapeMap ma, mb;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, ma, &a));
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, mb, &b));
    double worst = 0.0;
    for (size_t q = 3; q < ma.texels.size(); q += 4)
        worst = std::max(worst, double(std::fabs(ma.texels[q] - mb.texels[q])));
    PL_CHECK_NEAR(worst, 0.0, 1e-4);
}

// A DEPTH PASS AT ANOTHER SIZE LINES UP: the frames are matched by fraction, so the same
// depth at half the resolution builds nearly the same relief.
PL_TEST(ADepthPassAtAnotherSizeLinesUp) {
    const Picture matte = discMatte();
    auto bumps = [](double fx, double fy) {
        const double a = std::exp(-((fx - 0.35) * (fx - 0.35) + (fy - 0.4) * (fy - 0.4)) / 0.01);
        const double b = std::exp(-((fx - 0.65) * (fx - 0.65) + (fy - 0.6) * (fy - 0.6)) / 0.02);
        return 0.1 + 0.5 * a + 0.4 * b;
    };
    const Picture full = depthMap(400, 400, bumps);
    const Picture small = depthMap(200, 200, bumps);
    ReliefSource a, b;
    a.view = full.view();
    b.view = small.view();
    ShapeMap ma, mb;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, ma, &a));
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, mb, &b));
    double worst = 0.0;
    for (size_t q = 3; q < ma.texels.size(); q += 4)
        worst = std::max(worst, double(std::fabs(ma.texels[q] - mb.texels[q])));
    PL_CHECK(worst < 0.03);
}

// THE SLOPE THE KERNEL'S BOUND TAKES IS THE STEEPEST STEP THERE IS, and Softness lowers it:
// a hard step in the depth map is a cliff at softness 0 and a slope at 1.
PL_TEST(TheReliefSlopeIsTheSteepestStep) {
    const Picture matte = discMatte();
    const Picture step = depthMap(200, 200, [](double fx, double) { return fx < 0.5 ? 0.2 : 0.8; });

    ReliefSource r;
    r.view = step.view();
    r.softness = 0.0f;
    r.detail = 0.0f;
    ShapeMap hard;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, hard, &r));
    PL_CHECK_NEAR(hard.reliefSlope, steepestOf(hard), 1e-6);
    PL_CHECK(hard.reliefSlope > 0.5f);

    r.softness = 1.0f;
    ShapeMap soft;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, soft, &r));
    PL_CHECK_NEAR(soft.reliefSlope, steepestOf(soft), 1e-6);
    // A unit step through a Gaussian of sigma 16 is at most 1 / (sigma sqrt(2 pi)) a texel.
    PL_CHECK(soft.reliefSlope < 1.0f / (kReliefBlurMax * 2.5f) + 1e-3f);
    PL_CHECK(soft.hash != hard.hash);
}

// THE OUTSIDE IS FILLED FROM THE INSIDE, so the rim keeps the subject's depth rather than
// sinking towards the background: a depth map that is near at the disc's rim and far in
// its middle (and black, far, outside it) leaves the rim near after the blur.
PL_TEST(TheOutsideIsFilledFromTheInside) {
    const Picture matte = discMatte();
    const Picture ring = depthMap(200, 200, [](double fx, double fy) {
        const double r = std::hypot(fx - 0.5, fy - 0.5);
        return r > 0.4 ? 0.0 : 0.2 + 0.6 * (r / 0.4);
    });
    ReliefSource rs;
    rs.view = ring.view();
    rs.softness = 1.0f;
    rs.detail = 0.0f;
    ShapeMap m;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, m, &rs));

    // Just inside the rim, and a few texels outside it, on the middle row.
    const int mj = static_cast<int>(0.5f * (m.boxLoY + m.boxHiY));
    int edge = -1;
    for (int i = 0; i < m.width; ++i) if (mapAt(m, i, mj) > 0.0f) { edge = i; break; }
    PL_CHECK(edge > 0);
    PL_CHECK(mapAt(m, edge + 1, mj, 3) > 0.75f);
    PL_CHECK(mapAt(m, edge - 4, mj, 3) > 0.75f);
}

// RELIEF DETAIL TAKES THE LARGE FORM AWAY AND KEEPS THE FEATURES (build 28). A depth map
// that is mostly a slope -- a head turned three-quarters -- with a small bump on it: as it
// is, the far end of the slope is the nearest thing; with the form taken away, the bump is.
PL_TEST(ReliefDetailKeepsTheFeatures) {
    const Picture matte = discMatte();
    const Picture turned = depthMap(200, 200, [](double fx, double fy) {
        const double bump = std::exp(-((fx - 0.4) * (fx - 0.4) + (fy - 0.5) * (fy - 0.5)) / (2.0 * 0.05 * 0.05));
        return 0.2 + 0.6 * fx + 0.15 * bump;
    });
    auto reliefAt = [](const ShapeMap& m, double fx, double fy) {   // fractions of the frame
        // The disc spans 20..180 of the 200-pixel frame; the map's box is the disc's.
        const double bu = (fx * 200.0 - 20.0) / 160.0, by = 1.0 - (fy * 200.0 - 20.0) / 160.0;
        const int i = static_cast<int>(m.boxLoU + bu * (m.boxHiU - m.boxLoU));
        const int j = static_cast<int>(m.boxLoY + by * (m.boxHiY - m.boxLoY));
        return mapAt(m, i, j, 3);
    };

    ReliefSource r;
    r.view = turned.view();
    r.softness = 0.0f;
    r.detail = 0.0f;
    ShapeMap asIs;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, asIs, &r));
    PL_CHECK(reliefAt(asIs, 0.85, 0.5) > reliefAt(asIs, 0.4, 0.5));

    r.detail = 1.0f;
    ShapeMap detail;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, detail, &r));
    PL_CHECK(reliefAt(detail, 0.4, 0.5) > reliefAt(detail, 0.85, 0.5) + 0.3f);
    PL_CHECK(detail.hash != asIs.hash);

    // Still stretched to 0..1 inside the silhouette.
    float lo = 1.0f, hi = 0.0f;
    for (int j = 0; j < detail.height; ++j) {
        for (int i = 0; i < detail.width; ++i) {
            if (mapAt(detail, i, j) <= 0.0f) continue;
            lo = std::min(lo, mapAt(detail, i, j, 3));
            hi = std::max(hi, mapAt(detail, i, j, 3));
        }
    }
    PL_CHECK_NEAR(lo, 0.0, 1e-4);
    PL_CHECK_NEAR(hi, 1.0, 1e-4);
}

// THE FIT: Relief Depth of the smaller side, the slope in metres per metre, the extent out
// past the lifted face -- and none of it without a relief, or with NaN for a depth.
PL_TEST(TheReliefIsFittedWithTheShape) {
    const ConvectionDerived cd = heroOf(1500.0f, 1700.0f);
    const Picture matte = alphaShape(100, 200, [](double, double) { return true; });
    const Picture ramp = depthMap(100, 200, [](double, double fy) { return fy; });
    ReliefSource r;
    r.view = ramp.view();
    ShapeMap m;
    PL_CHECK(buildShapeMap(matte.view(), ShapeChannel::Alpha, 0.5f, m, &r));
    PL_CHECK(m.hasRelief);

    PareidoliaParams p;
    p.reliefDepth = 0.5f;
    const ShapeGeometry g = resolveShape(&m, p, cd);
    PL_CHECK(g.on);
    PL_CHECK_NEAR(g.reliefHeight, 0.5 * g.widthMetres, 1.0);
    PL_CHECK_NEAR(g.reliefSlope,
                  g.reliefHeight * std::sqrt(2.0) * m.reliefSlope / g.texelMetres * 1.001,
                  1e-3 * g.reliefSlope + 1e-6);
    PL_CHECK_NEAR(g.extent, std::hypot(0.5 * g.widthMetres, g.round + g.reliefHeight), 1.0);
    // The fade from the edge: a quarter of the rims or of the relief, whichever is less.
    PL_CHECK_NEAR(g.reliefFade, kReliefFadeOfRim * std::min(g.round, g.reliefHeight), 1e-3);

    p.reliefDepth = 0.0f;
    PL_CHECK(resolveShape(&m, p, cd).reliefHeight == 0.0f);
    PL_CHECK(resolveShape(&m, p, cd).reliefSlope == 0.0f);

    for (float bad : { std::numeric_limits<float>::quiet_NaN(), -3.0f, 1e30f }) {
        p.reliefDepth = bad;
        const ShapeGeometry b = resolveShape(&m, p, cd);
        PL_CHECK(std::isfinite(b.reliefHeight) && b.reliefHeight >= 0.0f);
        PL_CHECK(b.reliefHeight <= 2.0f * std::min(b.widthMetres, b.heightMetres) + 1e-3f);
        PL_CHECK(std::isfinite(b.reliefSlope) && b.reliefSlope >= 0.0f);
    }
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
