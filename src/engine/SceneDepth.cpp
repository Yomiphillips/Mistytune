#include "SceneDepth.h"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace plugin::cloud {
namespace {

struct Fnv {
    uint64_t h = 1469598103934665603ull;
    void bytes(const void* p, size_t n) {
        const unsigned char* b = static_cast<const unsigned char*>(p);
        for (size_t i = 0; i < n; ++i) { h ^= b[i]; h *= 1099511628211ull; }
    }
};

float clamp01(float v) {
    if (!(v > 0.0f)) return 0.0f;   // also NaN
    return v > 1.0f ? 1.0f : v;
}

} // namespace

float sceneDepthMetres(float v, const SceneDepthParams& p) {
    v = clamp01(v);
    const float nearM = std::max(p.nearestM, 0.01f);
    const float farM  = std::max(p.farthestM, nearM);
    const float cut   = std::min(std::max(p.skyCutoff, 0.0f), 0.99f);

    // THE OPEN SKY FIRST: the far end of the range, whichever end that is. A cutoff of 0 is
    // no sky at all -- the far end is then geometry at Farthest.
    const bool farBright = p.encoding == DepthEncoding::LinearFarBright;
    if (cut > 0.0f && (farBright ? v >= 1.0f - cut : v <= cut)) return 0.0f;

    // s: 0 at Farthest, 1 at Nearest, over the range the sky leaves.
    const float span = 1.0f - cut;
    float s = farBright ? 1.0f - v / span : (v - cut) / span;
    s = clamp01(s);

    switch (p.encoding) {
    case DepthEncoding::DisparityNearBright: {
        const float inv = (1.0f / farM) + ((1.0f / nearM) - (1.0f / farM)) * s;
        return 1.0f / inv;
    }
    case DepthEncoding::LinearNearBright:
    case DepthEncoding::LinearFarBright:
    default:
        return farM + (nearM - farM) * s;
    }
}

void sceneDepthTexel(const Texel& t, float& value, float& coverage) {
    coverage = clamp01(static_cast<float>(t.a));
    double v = 0.0;
    if (t.a > 1e-6) v = (0.2126 * t.r + 0.7152 * t.g + 0.0722 * t.b) / t.a;
    value = clamp01(static_cast<float>(v));
}

bool buildSceneDepthMap(const ConstImageView& view, const SceneDepthParams& p,
                        SceneDepthMap& out) {
    out = SceneDepthMap{};
    if (!view.valid()) return false;

    // SUBSAMPLED, NEVER FILTERED, past the cap: an average of a building and the sky behind
    // it is a depth that is neither.
    const int longSide = std::max(view.width, view.height);
    const double step = longSide > kSceneDepthMaxSide
                      ? static_cast<double>(longSide) / kSceneDepthMaxSide : 1.0;
    const int w = std::max(1, static_cast<int>(std::floor(view.width / step)));
    const int h = std::max(1, static_cast<int>(std::floor(view.height / step)));

    out.width  = w;
    out.height = h;
    out.texels.assign(static_cast<size_t>(w) * static_cast<size_t>(h) * 2, 0.0f);

    int geometry = 0;
    for (int j = 0; j < h; ++j) {
        const int sy = std::min(static_cast<int>((j + 0.5) * step), view.height - 1);
        for (int i = 0; i < w; ++i) {
            const int sx = std::min(static_cast<int>((i + 0.5) * step), view.width - 1);
            float value = 0.0f, coverage = 0.0f;
            sceneDepthTexel(readPixel(view, sx, sy), value, coverage);
            const float metres = coverage > 0.0f ? sceneDepthMetres(value, p) : 0.0f;
            float* t = &out.texels[(static_cast<size_t>(j) * w + i) * 2];
            t[0] = metres;
            t[1] = metres > 0.0f ? coverage : 0.0f;
            if (t[1] > 0.0f) ++geometry;
        }
    }
    out.geometryTexels = geometry;

    // WORD BY WORD over the texels: a 1080p pass is 16 MB, which byte-wise FNV takes about
    // 15 ms to walk -- per frame, since AE hands the pass over afresh every frame.
    Fnv fnv;
    fnv.bytes(&out.width, sizeof out.width);
    fnv.bytes(&out.height, sizeof out.height);
    for (const float f : out.texels) {
        uint32_t w32;
        std::memcpy(&w32, &f, sizeof w32);
        fnv.h ^= w32;
        fnv.h *= 1099511628211ull;
    }
    out.hash = fnv.h;
    return geometry > 0;
}

void compositeOverPlate(float* argb, int width, int height, int pitchPx,
                        const ConstImageView& plate, int dx, int dy) {
    if (!argb || width <= 0 || height <= 0 || !plate.valid()) return;
    for (int y = 0; y < height; ++y) {
        float* row = argb + static_cast<size_t>(y) * pitchPx * 4;
        for (int x = 0; x < width; ++x) {
            float* p = row + static_cast<size_t>(x) * 4;
            const float keep = 1.0f - p[0];
            if (!(keep > 0.0f)) continue;   // opaque: the plate cannot show
            const Texel t = readPixel(plate, x + dx, y + dy);   // transparent outside it
            p[0] += static_cast<float>(t.a) * keep;
            p[1] += static_cast<float>(t.r) * keep;
            p[2] += static_cast<float>(t.g) * keep;
            p[3] += static_cast<float>(t.b) * keep;
        }
    }
}

} // namespace plugin::cloud
