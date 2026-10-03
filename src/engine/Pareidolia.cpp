#include "Pareidolia.h"

#include <algorithm>
#include <cmath>
#include <limits>

namespace plugin::cloud {

namespace {

constexpr double kPiD = 3.14159265358979323846;

// Far enough that no real squared distance reaches it, near enough that sums of two stay
// finite. The transform below adds a squared index to it, which is lost in the rounding:
// that is the standard trade, and every comparison it takes part in comes out right.
constexpr double kFar = 1e20;

// The matte value of one pixel, 0..1. NaN and out-of-range HDR come out as numbers in
// range, so a 32 bpc layer with a hot pixel is a matte and not a hole in one.
float matteOf(const Texel& t, ShapeChannel channel) {
    double v = 0.0;
    switch (channel) {
        case ShapeChannel::Alpha:             v = t.a; break;
        case ShapeChannel::Luminance:         v = 0.2126 * t.r + 0.7152 * t.g + 0.0722 * t.b; break;
        case ShapeChannel::InvertedAlpha:     v = 1.0 - t.a; break;
        case ShapeChannel::InvertedLuminance: v = 1.0 - (0.2126 * t.r + 0.7152 * t.g + 0.0722 * t.b); break;
    }
    if (!(v > 0.0)) return 0.0f;   // also NaN
    if (v > 1.0) return 1.0f;
    return static_cast<float>(v);
}

// ===========================================================================
// THE EXACT SQUARED EUCLIDEAN DISTANCE TRANSFORM, one dimension at a time (Felzenszwalb
// and Huttenlocher 2012). The squared distance to the nearest feature is separable: run
// along every column, then along every row of the result, and each pass is the lower
// envelope of parabolas rooted at the samples -- linear time, and exact, not the chamfer
// approximation whose octagons would show as facets on a round cloud.
// ===========================================================================
void distance1d(const double* f, int n, double* d, int* v, double* z) {
    int k = 0;
    v[0] = 0;
    z[0] = -std::numeric_limits<double>::infinity();
    z[1] = std::numeric_limits<double>::infinity();
    for (int q = 1; q < n; ++q) {
        double s = ((f[q] + double(q) * q) - (f[v[k]] + double(v[k]) * v[k])) /
                   (2.0 * q - 2.0 * v[k]);
        while (s <= z[k]) {
            --k;
            s = ((f[q] + double(q) * q) - (f[v[k]] + double(v[k]) * v[k])) /
                (2.0 * q - 2.0 * v[k]);
        }
        ++k;
        v[k] = q;
        z[k] = s;
        z[k + 1] = std::numeric_limits<double>::infinity();
    }
    k = 0;
    for (int q = 0; q < n; ++q) {
        while (z[k + 1] < q) ++k;
        const double dq = double(q) - v[k];
        d[q] = dq * dq + f[v[k]];
    }
}

// Squared distance, in texels, from every texel to the nearest one where `feature` is set.
void squaredDistance(const std::vector<uint8_t>& feature, int w, int h, std::vector<double>& out) {
    out.assign(static_cast<size_t>(w) * h, 0.0);
    const int n = std::max(w, h);
    std::vector<double> f(n), d(n), z(n + 1);
    std::vector<int> v(n);

    for (int x = 0; x < w; ++x) {
        for (int y = 0; y < h; ++y) f[y] = feature[static_cast<size_t>(y) * w + x] ? 0.0 : kFar;
        distance1d(f.data(), h, d.data(), v.data(), z.data());
        for (int y = 0; y < h; ++y) out[static_cast<size_t>(y) * w + x] = d[y];
    }
    for (int y = 0; y < h; ++y) {
        double* row = out.data() + static_cast<size_t>(y) * w;
        for (int x = 0; x < w; ++x) f[x] = row[x];
        distance1d(f.data(), w, d.data(), v.data(), z.data());
        for (int x = 0; x < w; ++x) row[x] = d[x];
    }
}

// FNV-1a, the same arithmetic as sim::Fingerprint, without dragging that header in.
struct Fnv {
    uint64_t h = 14695981039346656037ull;
    void bytes(const void* p, size_t n) {
        const auto* b = static_cast<const unsigned char*>(p);
        for (size_t i = 0; i < n; ++i) { h ^= b[i]; h *= 1099511628211ull; }
    }
};

Real clampFinite(Real v, Real lo, Real hi, Real fallback) {
    if (!(v == v)) return fallback;          // NaN
    return v < lo ? lo : (v > hi ? hi : v);
}

// ===========================================================================
// Relief (build 27)
// ===========================================================================

// THE DEPTH MAP'S NEARNESS AT ONE PIXEL, 0..1: Rec. 709 luma of the STRAIGHT colour. AE's
// buffers are premultiplied, and a depth pass with a soft alpha edge is its depth there,
// not further away for being half transparent. Nothing where there is no alpha.
float nearnessOf(const Texel& t, bool inverted) {
    double v = 0.0;
    if (t.a > 1e-6) v = (0.2126 * t.r + 0.7152 * t.g + 0.0722 * t.b) / t.a;
    if (!(v > 0.0)) v = 0.0;   // also NaN
    if (v > 1.0) v = 1.0;
    return static_cast<float>(inverted ? 1.0 - v : v);
}

// Bilinear nearness at a continuous position, pixel centres at +0.5, clamped to the frame.
double nearnessAt(const ConstImageView& img, bool inverted, double x, double y) {
    const double fx = std::min(std::max(x - 0.5, 0.0), double(img.width - 1));
    const double fy = std::min(std::max(y - 0.5, 0.0), double(img.height - 1));
    const int ix = std::min(static_cast<int>(fx), img.width - 1);
    const int iy = std::min(static_cast<int>(fy), img.height - 1);
    const int jx = std::min(ix + 1, img.width - 1);
    const int jy = std::min(iy + 1, img.height - 1);
    const double tx = fx - ix, ty = fy - iy;
    const double a = nearnessOf(readPixel(img, ix, iy), inverted);
    const double b = nearnessOf(readPixel(img, jx, iy), inverted);
    const double c = nearnessOf(readPixel(img, ix, jy), inverted);
    const double d = nearnessOf(readPixel(img, jx, jy), inverted);
    return (a * (1.0 - tx) + b * tx) * (1.0 - ty) + (c * (1.0 - tx) + d * tx) * ty;
}

// THE OUTSIDE, FILLED FROM THE INSIDE, one ring at a time: each texel next to the filled
// region takes the mean of its filled neighbours. So the blur that follows sees the
// subject's own values across the edge rather than a background, and the slope across the
// silhouette's edge is the subject's -- which is also what keeps the bound tight there.
void fillOutward(std::vector<float>& v, std::vector<uint8_t> filled, int w, int h) {
    std::vector<size_t> ring, next;
    auto touches = [&](int i, int j) {
        return (i > 0 && filled[static_cast<size_t>(j) * w + i - 1]) ||
               (i < w - 1 && filled[static_cast<size_t>(j) * w + i + 1]) ||
               (j > 0 && filled[static_cast<size_t>(j - 1) * w + i]) ||
               (j < h - 1 && filled[static_cast<size_t>(j + 1) * w + i]);
    };
    for (int j = 0; j < h; ++j)
        for (int i = 0; i < w; ++i)
            if (!filled[static_cast<size_t>(j) * w + i] && touches(i, j))
                ring.push_back(static_cast<size_t>(j) * w + i);

    std::vector<uint8_t> queued(filled.size(), 0);
    while (!ring.empty()) {
        // Every value in a ring from the rings before it, so the order inside one is moot.
        std::vector<float> got(ring.size());
        for (size_t k = 0; k < ring.size(); ++k) {
            const int i = static_cast<int>(ring[k] % w), j = static_cast<int>(ring[k] / w);
            double sum = 0.0;
            int n = 0;
            if (i > 0     && filled[ring[k] - 1]) { sum += v[ring[k] - 1]; ++n; }
            if (i < w - 1 && filled[ring[k] + 1]) { sum += v[ring[k] + 1]; ++n; }
            if (j > 0     && filled[ring[k] - w]) { sum += v[ring[k] - w]; ++n; }
            if (j < h - 1 && filled[ring[k] + w]) { sum += v[ring[k] + w]; ++n; }
            got[k] = n > 0 ? static_cast<float>(sum / n) : 0.0f;
        }
        for (size_t k = 0; k < ring.size(); ++k) { v[ring[k]] = got[k]; filled[ring[k]] = 1; }
        next.clear();
        for (size_t q : ring) {
            const int i = static_cast<int>(q % w), j = static_cast<int>(q / w);
            const size_t around[4] = { i > 0 ? q - 1 : q, i < w - 1 ? q + 1 : q,
                                       j > 0 ? q - w : q, j < h - 1 ? q + w : q };
            for (size_t a : around) {
                if (!filled[a] && !queued[a]) { queued[a] = 1; next.push_back(a); }
            }
        }
        ring.swap(next);
    }
}

// A separable Gaussian, clamped at the map's edges. Sigma under a third of a texel is none.
void blurGaussian(std::vector<float>& v, int w, int h, double sigma) {
    if (!(sigma >= 0.33)) return;
    const int radius = static_cast<int>(std::ceil(3.0 * sigma));
    std::vector<double> k(static_cast<size_t>(2 * radius + 1));
    double norm = 0.0;
    for (int t = -radius; t <= radius; ++t) {
        k[static_cast<size_t>(t + radius)] = std::exp(-0.5 * (t * t) / (sigma * sigma));
        norm += k[static_cast<size_t>(t + radius)];
    }
    for (double& x : k) x /= norm;

    std::vector<float> tmp(v.size());
    for (int j = 0; j < h; ++j) {
        for (int i = 0; i < w; ++i) {
            double s = 0.0;
            for (int t = -radius; t <= radius; ++t) {
                const int x = std::min(std::max(i + t, 0), w - 1);
                s += k[static_cast<size_t>(t + radius)] * v[static_cast<size_t>(j) * w + x];
            }
            tmp[static_cast<size_t>(j) * w + i] = static_cast<float>(s);
        }
    }
    for (int j = 0; j < h; ++j) {
        for (int i = 0; i < w; ++i) {
            double s = 0.0;
            for (int t = -radius; t <= radius; ++t) {
                const int y = std::min(std::max(j + t, 0), h - 1);
                s += k[static_cast<size_t>(t + radius)] * tmp[static_cast<size_t>(y) * w + i];
            }
            v[static_cast<size_t>(j) * w + i] = static_cast<float>(s);
        }
    }
}

} // namespace

bool buildShapeMap(const ConstImageView& source, ShapeChannel channel, Real threshold,
                   ShapeMap& out, const ReliefSource* relief) {
    out = ShapeMap{};
    if (!source.valid()) return false;

    const int sw = source.width;
    const int sh = source.height;
    const float thr = static_cast<float>(clampFinite(threshold, Real(1e-4), Real(1), Real(0.5)));

    // ---------------------------------------------------------------------
    // The matte, once, and the silhouette's bounding box in source pixels.
    // ---------------------------------------------------------------------
    std::vector<float> matte(static_cast<size_t>(sw) * sh);
    int x0 = sw, y0 = sh, x1 = -1, y1 = -1;
    for (int y = 0; y < sh; ++y) {
        float* row = matte.data() + static_cast<size_t>(y) * sw;
        for (int x = 0; x < sw; ++x) {
            const float m = matteOf(readPixel(source, x, y), channel);
            row[x] = m;
            if (m >= thr) {
                x0 = std::min(x0, x); x1 = std::max(x1, x);
                y0 = std::min(y0, y); y1 = std::max(y1, y);
            }
        }
    }
    if (x1 < x0 || y1 < y0) return false;

    // Pixel edges: the box is [x0, x1] x [y0, y1] in whole pixels.
    const double bw = double(x1 + 1 - x0);
    const double bh = double(y1 + 1 - y0);
    const double texelPx = std::max(bw, bh) / double(kShapeMapInner);

    const int w = static_cast<int>(std::ceil(bw / texelPx - 1e-6)) + 2 * kShapeMapMargin;
    const int h = static_cast<int>(std::ceil(bh / texelPx - 1e-6)) + 2 * kShapeMapMargin;

    // The matte at a continuous source position, pixel centres at +0.5. OFF OUTSIDE THE
    // FRAME in every mode; inside it, clamped to the edge, so the frame's border is not a
    // soft edge of its own.
    auto sample = [&](double x, double y) -> double {
        if (x < 0.0 || y < 0.0 || x > double(sw) || y > double(sh)) return 0.0;
        const double fx = std::min(std::max(x - 0.5, 0.0), double(sw - 1));
        const double fy = std::min(std::max(y - 0.5, 0.0), double(sh - 1));
        const int ix = std::min(static_cast<int>(fx), sw - 1);
        const int iy = std::min(static_cast<int>(fy), sh - 1);
        const int jx = std::min(ix + 1, sw - 1);
        const int jy = std::min(iy + 1, sh - 1);
        const double tx = fx - ix, ty = fy - iy;
        const double a = matte[static_cast<size_t>(iy) * sw + ix];
        const double b = matte[static_cast<size_t>(iy) * sw + jx];
        const double c = matte[static_cast<size_t>(jy) * sw + ix];
        const double d = matte[static_cast<size_t>(jy) * sw + jx];
        return (a * (1.0 - tx) + b * tx) * (1.0 - ty) + (c * (1.0 - tx) + d * tx) * ty;
    };

    // ---------------------------------------------------------------------
    // The silhouette on the map's grid. A texel is inside when the matte's average over it
    // reaches the threshold: k x k samples, k growing with how many source pixels a texel
    // covers, so a 4K source is filtered rather than aliased and a 64-pixel icon is
    // interpolated rather than blocky.
    // ---------------------------------------------------------------------
    const int k = std::min(std::max(static_cast<int>(std::ceil(texelPx)), 1), 4);
    std::vector<uint8_t> inside(static_cast<size_t>(w) * h, 0);
    int bi0 = w, bj0 = h, bi1 = -1, bj1 = -1;
    for (int j = 0; j < h; ++j) {
        for (int i = 0; i < w; ++i) {
            double sum = 0.0;
            for (int b = 0; b < k; ++b) {
                // ROW 0 IS THE BOTTOM: the source's y runs down from the box's bottom edge.
                const double ys = double(y1 + 1) - (j + (b + 0.5) / k - kShapeMapMargin) * texelPx;
                for (int a = 0; a < k; ++a) {
                    const double xs = double(x0) + (i + (a + 0.5) / k - kShapeMapMargin) * texelPx;
                    sum += sample(xs, ys);
                }
            }
            if (sum / double(k * k) >= thr) {
                inside[static_cast<size_t>(j) * w + i] = 1;
                bi0 = std::min(bi0, i); bi1 = std::max(bi1, i);
                bj0 = std::min(bj0, j); bj1 = std::max(bj1, j);
            }
        }
    }
    // A silhouette of hairlines can vanish in the averaging. No texel, no shape.
    if (bi1 < bi0 || bj1 < bj0) return false;

    // ---------------------------------------------------------------------
    // Signed distance, in texels, to the edge between inside and outside texels -- which
    // sits half a texel from the centres either side of it.
    // ---------------------------------------------------------------------
    std::vector<uint8_t> outside(inside.size());
    for (size_t q = 0; q < inside.size(); ++q) outside[q] = inside[q] ? 0 : 1;

    std::vector<double> toOutside, toInside;
    squaredDistance(outside, w, h, toOutside);
    squaredDistance(inside, w, h, toInside);

    std::vector<float> dist(inside.size());
    for (size_t q = 0; q < inside.size(); ++q) {
        dist[q] = inside[q] ? static_cast<float>(std::sqrt(toOutside[q]) - 0.5)
                            : static_cast<float>(-(std::sqrt(toInside[q]) - 0.5));
    }

    out.width  = w;
    out.height = h;
    out.boxLoU = static_cast<float>(bi0);
    out.boxLoY = static_cast<float>(bj0);
    out.boxHiU = static_cast<float>(bi1 + 1);
    out.boxHiY = static_cast<float>(bj1 + 1);
    out.texels.assign(static_cast<size_t>(w) * h * 4, 0.0f);

    auto at = [&](int i, int j) { return dist[static_cast<size_t>(j) * w + i]; };
    for (int j = 0; j < h; ++j) {
        for (int i = 0; i < w; ++i) {
            const int il = i > 0 ? i - 1 : i, ir = i < w - 1 ? i + 1 : i;
            const int jd = j > 0 ? j - 1 : j, ju = j < h - 1 ? j + 1 : j;
            float* t = out.texels.data() + (static_cast<size_t>(j) * w + i) * 4;
            t[0] = at(i, j);
            t[1] = (at(ir, j) - at(il, j)) / static_cast<float>(ir - il);
            t[2] = (at(i, ju) - at(i, jd)) / static_cast<float>(ju - jd);
            t[3] = 0.0f;
        }
    }

    // ---------------------------------------------------------------------
    // RELIEF (build 27): the depth map at the silhouette's texels, in the same place in its
    // frame as the matte's samples -- the frames are matched by their FRACTION, so a depth
    // pass rendered at another size still lines up. See Pareidolia.h for the four steps.
    // ---------------------------------------------------------------------
    if (relief && relief->view.valid()) {
        const ConstImageView& rv = relief->view;
        const double sx = double(rv.width) / double(sw);
        const double sy = double(rv.height) / double(sh);
        const int kr = std::min(std::max(static_cast<int>(std::ceil(texelPx * std::max(sx, sy))), 1), 4);

        std::vector<float> nearness(inside.size(), 0.0f);
        float lo = 1.0f, hi = 0.0f;
        for (int j = 0; j < h; ++j) {
            for (int i = 0; i < w; ++i) {
                const size_t q = static_cast<size_t>(j) * w + i;
                if (!inside[q]) continue;
                double sum = 0.0;
                for (int b = 0; b < kr; ++b) {
                    const double ys = double(y1 + 1) - (j + (b + 0.5) / kr - kShapeMapMargin) * texelPx;
                    for (int a = 0; a < kr; ++a) {
                        const double xs = double(x0) + (i + (a + 0.5) / kr - kShapeMapMargin) * texelPx;
                        sum += nearnessAt(rv, relief->inverted, xs * sx, ys * sy);
                    }
                }
                nearness[q] = static_cast<float>(sum / double(kr * kr));
                lo = std::min(lo, nearness[q]);
                hi = std::max(hi, nearness[q]);
            }
        }

        // ONE FLAT GREY IS NO RELIEF: there is nothing to stretch.
        if (hi - lo > 1e-4f) {
            const float span = hi - lo;
            for (size_t q = 0; q < nearness.size(); ++q)
                nearness[q] = inside[q] ? (nearness[q] - lo) / span : 0.0f;
            fillOutward(nearness, inside, w, h);

            // RELIEF DETAIL (build 28): take away that much of the large form and stretch
            // what is left inside the silhouette to 0..1 again. The fill above is what lets
            // the form be blurred without the background sinking the rim.
            const Real detail = clampFinite(relief->detail, Real(0), Real(1), Real(0.5));
            if (detail > Real(0)) {
                std::vector<float> form = nearness;
                blurGaussian(form, w, h, double(kReliefFormSigma));
                float dlo = 1e30f, dhi = -1e30f;
                for (size_t q = 0; q < nearness.size(); ++q) {
                    nearness[q] -= static_cast<float>(detail) * form[q];
                    if (inside[q]) { dlo = std::min(dlo, nearness[q]); dhi = std::max(dhi, nearness[q]); }
                }
                const float dspan = dhi - dlo > 1e-6f ? dhi - dlo : 1.0f;
                for (float& v : nearness) v = (v - dlo) / dspan;
            }

            const Real soft = clampFinite(relief->softness, Real(0), Real(1), Real(0.35));
            blurGaussian(nearness, w, h, double(soft) * kReliefBlurMax);

            float steepest = 0.0f;
            for (int j = 0; j < h; ++j) {
                for (int i = 0; i < w; ++i) {
                    const size_t q = static_cast<size_t>(j) * w + i;
                    nearness[q] = std::min(std::max(nearness[q], 0.0f), 1.0f);
                }
            }
            for (int j = 0; j < h; ++j) {
                for (int i = 0; i < w; ++i) {
                    const size_t q = static_cast<size_t>(j) * w + i;
                    if (i + 1 < w) steepest = std::max(steepest, std::fabs(nearness[q + 1] - nearness[q]));
                    if (j + 1 < h) steepest = std::max(steepest, std::fabs(nearness[q + w] - nearness[q]));
                    out.texels[q * 4 + 3] = nearness[q];
                }
            }
            out.hasRelief   = true;
            out.reliefSlope = steepest;
        }
    }

    // THE DISTANCES ARE A FUNCTION OF THE MASK, so the mask and the box are the hash -- and
    // the relief, when there is one. Without it the hash is build 21's, to the bit.
    Fnv fnv;
    fnv.bytes(&out.width, sizeof out.width);
    fnv.bytes(&out.height, sizeof out.height);
    fnv.bytes(&out.boxLoU, sizeof(float) * 4);
    fnv.bytes(inside.data(), inside.size());
    if (out.hasRelief) {
        for (size_t q = 0; q < inside.size(); ++q) fnv.bytes(&out.texels[q * 4 + 3], sizeof(float));
        fnv.bytes(&out.reliefSlope, sizeof out.reliefSlope);
    }
    out.hash = fnv.h;
    return true;
}

ShapeGeometry resolveShape(const ShapeMap* map, const PareidoliaParams& p,
                           const ConvectionDerived& cd) {
    ShapeGeometry g;
    if (!map || map->empty() || !cd.present) return g;
    if (!(cd.heroTop > Real(1)) || !(cd.heroRadius > Real(0))) return g;

    const Real boxW = map->boxHiU - map->boxLoU;
    const Real boxH = map->boxHiY - map->boxLoY;
    if (!(boxW > Real(0)) || !(boxH > Real(0))) return g;

    // CONTAIN: the whole silhouette inside Hero Width by the hero's height.
    const Real fitW = Real(2) * cd.heroRadius;
    const Real fitH = cd.heroTop;
    const Real metres = std::min(fitW / boxW, fitH / boxH);

    g.on           = true;
    g.width        = map->width;
    g.height       = map->height;
    g.offsetU      = Real(0.5) * (map->boxLoU + map->boxHiU);
    g.offsetY      = map->boxLoY;
    g.texelMetres  = metres;
    g.widthMetres  = boxW * metres;
    g.heightMetres = boxH * metres;

    const Real depth = clampFinite(p.depth, Real(0.02), Real(2), Real(0.6));
    g.round  = std::max(Real(1), depth * Real(0.5) * std::min(g.widthMetres, g.heightMetres));

    // RELIEF (build 27): Relief Depth of the smaller side, and the slope the kernel's bound
    // takes. The map's step is per texel along one axis; bilinear interpolation can step
    // that along both at once, so sqrt(2) of it per texel, and a texel is `metres`. The
    // 0.1% is rounding's share, so the bound is never a rounding short of the density.
    if (map->hasRelief) {
        const Real rd = clampFinite(p.reliefDepth, Real(0), Real(2), Real(0.25));
        const Real height = rd * std::min(g.widthMetres, g.heightMetres);
        if (height >= Real(1)) {
            g.reliefHeight = height;
            g.reliefSlope  = height * Real(1.41421356) * map->reliefSlope / metres * Real(1.001);
            // THE FADE FROM THE EDGE: a quarter of the rims or of the relief, whichever is
            // less -- enough that the outline is not a sheer wall, short enough that a nose
            // on the outline keeps its height. See convReliefLift.
            g.reliefFade = std::max(Real(1), kReliefFadeOfRim * std::min(g.round, height));
        }
    }
    const Real front = g.round + g.reliefHeight;
    g.extent = std::sqrt(Real(0.25) * g.widthMetres * g.widthMetres + front * front);

    // A DIAL KEYFRAMED ROUND ACCUMULATES REVOLUTIONS, so the angle is reduced before the
    // trig rather than trusted to it at 3600 degrees.
    double bearing = static_cast<double>(p.bearing);
    if (!(bearing == bearing) || std::fabs(bearing) > 1e9) bearing = 0.0;
    bearing = std::fmod(bearing, 360.0) * (kPiD / 180.0);
    g.axisUX = static_cast<Real>(std::cos(bearing));
    g.axisUZ = static_cast<Real>(-std::sin(bearing));

    // DECAY IS EASED, SQUARED, ON ITS WAY TO THE KERNEL, which blends linearly in what it is
    // handed. SEEN LINEAR: a smiley's eyes and mouth were gone by 0.33 on the slider -- an eye
    // is a hole a hundred-odd metres deep in a tower half a kilometre deep, so a third of the
    // tower filled it, and the billows had already grown past the eye by then. Squared, a
    // third of the slider is a ninth of the blend, and the features melt across the range
    // rather than in its first fifth. 0 and 1 are untouched, so decay 1 is still the tower.
    const Real decay = clampFinite(p.decay, Real(0), Real(1), Real(0));
    g.decay  = decay * decay;
    g.billow = clampFinite(p.billows, Real(0), Real(1), Real(0));
    return g;
}

Real shapeBearingToCamera(const ViewParams& view, Real heroX, Real heroZ) {
    const double dx = static_cast<double>(view.observerX) - heroX;
    const double dz = static_cast<double>(view.observerZ) - heroZ;
    if (dx * dx + dz * dz >= 1.0) {
        return static_cast<Real>(std::atan2(dx, dz) * (180.0 / kPiD));
    }
    // Straight underneath: back along where the camera looks. The matrix is row-major
    // camera-to-world, and the camera looks down its own -Z, so the column (m[2], m[10])
    // is the horizontal direction back towards the eye.
    const double nx = view.cameraToWorld[2];
    const double nz = view.cameraToWorld[10];
    if (nx * nx + nz * nz < 1e-12) return Real(0);
    return static_cast<Real>(std::atan2(nx, nz) * (180.0 / kPiD));
}

} // namespace plugin::cloud
