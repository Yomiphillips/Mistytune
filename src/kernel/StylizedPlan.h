#pragma once

// WHERE THE STYLIZED LOOK'S GRIDS LIE (build 32), and the look's constants. Host only, and pure:
// every rule here is unit tested without a card. See StylizedFrame.h for the renderer's shape.
//
// ===========================================================================
// THE GRIDS FOLLOW THE CAMERA, NOT THE WORLD.
//
// A grid over the whole layer out to Render Distance is 80 km across; at any budget a frame can
// afford, its voxels would be a hundred metres and the hero a blob. So each grid holds only what
// the frame can SEE -- the camera's frustum, a little wider, cut by the cumulus slab, the hero's
// box and the fade -- and is stretched towards the sun, so a cloud just out of frame still casts
// its shadow into it.
//
//   level 0  the hero's box, when there is a hero in view; else the field within kStyleNearReach
//   level 1  the field within kStyleMidReach
//   level 2  the field out to Render Distance
//
// A LEVEL BARELY BIGGER THAN THE ONE INSIDE IT ADDS NOTHING but a seam, so the finer of the two
// is dropped and its budget given to the coarser: a hero alone is one grid of every voxel.
// ===========================================================================

#include "AirMapPlan.h"
#include "RenderRequest.h"
#include "StylizedFrame.h"

#include <cmath>
#include <vector>

namespace plugin::kernel {

// Voxels per level at Best. Draft takes half.
constexpr long long kStyleBudget[kStyleLevels] = { 4000000, 1500000, 1500000 };

constexpr float kStyleNearReach = 4000.0f;    // m: level 0's reach when there is no hero
constexpr float kStyleMidReach  = 12000.0f;   // m
constexpr float kStyleFarReach  = 60000.0f;   // m: level 2 when Render Distance is unbounded
constexpr float kStyleGuard     = 0.08f;      // the frame widened by this much on every side
constexpr float kStyleMinCell   = 4.0f;       // m
constexpr int   kStyleMaxSide   = 1024;       // voxels
constexpr float kStyleMergeRatio = 2.0f;      // drop a level whose next is under this x its volume

// THE SHADOW'S REACH TOWARDS THE SUN, per level: past this the light walk sees clear air.
constexpr float kStyleSunStretch[kStyleLevels] = { 3000.0f, 5000.0f, 10000.0f };

// THE FUZZ'S CLIMB, m/s: the noise rises through the cloud, a slow boil on the edge.
constexpr float kStyleFuzzRise = 1.0f;

struct StyleBox {
    bool  ok = false;
    float lo[3] = { 0.0f, 0.0f, 0.0f };
    float hi[3] = { 0.0f, 0.0f, 0.0f };
};

inline float styleBoxVolume(const StyleBox& b) {
    if (!b.ok) return 0.0f;
    return (b.hi[0] - b.lo[0]) * (b.hi[1] - b.lo[1]) * (b.hi[2] - b.lo[2]);
}

inline StyleBox styleIntersect(StyleBox a, const StyleBox& b) {
    if (!a.ok || !b.ok) return StyleBox{};
    for (int k = 0; k < 3; ++k) {
        a.lo[k] = std::fmax(a.lo[k], b.lo[k]);
        a.hi[k] = std::fmin(a.hi[k], b.hi[k]);
        if (!(a.hi[k] > a.lo[k])) return StyleBox{};
    }
    return a;
}

// WHERE THE LAYER CAN BE, ACROSS AND UP: its slab, its clip box, the square round its fade.
inline StyleBox styleLayerBounds(const AirMapLayerExtent& e) {
    StyleBox b;
    if (!e.present || !(e.top > e.bottom)) return b;
    b.ok = true;
    b.lo[1] = e.bottom;
    b.hi[1] = e.top;
    const float r = e.fadeRadius > 0.0f ? e.fadeRadius : 1e9f;
    b.lo[0] = e.fadeX - r; b.hi[0] = e.fadeX + r;
    b.lo[2] = e.fadeZ - r; b.hi[2] = e.fadeZ + r;
    if (e.clipOn) {
        b.lo[0] = std::fmax(b.lo[0], e.clipLoX); b.hi[0] = std::fmin(b.hi[0], e.clipHiX);
        b.lo[2] = std::fmax(b.lo[2], e.clipLoZ); b.hi[2] = std::fmin(b.hi[2], e.clipHiZ);
    }
    if (!(b.hi[0] > b.lo[0]) || !(b.hi[2] > b.lo[2])) b.ok = false;
    return b;
}

// IS A WORLD POINT INSIDE THE FRAME, widened by `guard` on every side, and in front of the eye?
inline bool styleInFrustum(const cloud::ViewParams& view, float x, float y, float z, float guard) {
    const float* m = view.cameraToWorld;
    const float dx = x - view.observerX, dy = y - view.observerAltitude, dz = z - view.observerZ;
    // World to camera is the transpose of the rotation.
    const float cx = m[0] * dx + m[4] * dy + m[8] * dz;
    const float cy = m[1] * dx + m[5] * dy + m[9] * dz;
    const float cz = m[2] * dx + m[6] * dy + m[10] * dz;
    if (!(cz < 0.0f)) return false;
    const float th = std::tan(view.verticalFovDegrees * 0.00872664626f);
    const float aspect = view.heightPx > 0 ? static_cast<float>(view.widthPx) / view.heightPx : 1.0f;
    const float k = 1.0f + 2.0f * guard;
    return std::fabs(cx / -cz) <= th * aspect * k && std::fabs(cy / -cz) <= th * k;
}

// THE PART OF `bounds` THE FRAME CAN SEE, within `reach` across from the eye: the box round
// every ray's run through it, the box's own corners in view, and the eye if it stands inside.
inline StyleBox styleVisibleBox(const cloud::ViewParams& view, StyleBox bounds, float reach) {
    StyleBox out;
    const float ex = view.observerX, ey = view.observerAltitude, ez = view.observerZ;
    if (reach > 0.0f) {
        StyleBox r;
        r.ok = true;
        r.lo[0] = ex - reach; r.hi[0] = ex + reach;
        r.lo[1] = -1e9f;      r.hi[1] = 1e9f;
        r.lo[2] = ez - reach; r.hi[2] = ez + reach;
        bounds = styleIntersect(bounds, r);
    }
    if (!bounds.ok || view.widthPx <= 0 || view.heightPx <= 0) return out;

    float lo[3] = { 1e30f, 1e30f, 1e30f }, hi[3] = { -1e30f, -1e30f, -1e30f };
    bool any = false;
    const auto add = [&](float x, float y, float z) {
        lo[0] = std::fmin(lo[0], x); hi[0] = std::fmax(hi[0], x);
        lo[1] = std::fmin(lo[1], y); hi[1] = std::fmax(hi[1], y);
        lo[2] = std::fmin(lo[2], z); hi[2] = std::fmax(hi[2], z);
        any = true;
    };

    const Vec3 eye = vec3(ex, ey, ez);
    const int N = 16;
    const float W = static_cast<float>(view.widthPx), H = static_cast<float>(view.heightPx);
    for (int j = 0; j <= N; ++j) {
        for (int i = 0; i <= N; ++i) {
            const float fx = (-kStyleGuard + (1.0f + 2.0f * kStyleGuard) * i / N) * W;
            const float fy = (-kStyleGuard + (1.0f + 2.0f * kStyleGuard) * j / N) * H;
            const Vec3 d = styleFrameRay(view, fx, fy);
            float t0, t1;
            if (!styleBoxRange(bounds.lo[0], bounds.lo[1], bounds.lo[2],
                               bounds.hi[0], bounds.hi[1], bounds.hi[2], eye, d, t0, t1)) continue;
            if (t1 < 0.0f) continue;
            if (t0 < 0.0f) t0 = 0.0f;
            add(ex + d.x * t0, ey + d.y * t0, ez + d.z * t0);
            add(ex + d.x * t1, ey + d.y * t1, ez + d.z * t1);
        }
    }
    for (int c = 0; c < 8; ++c) {
        const float x = (c & 1) ? bounds.hi[0] : bounds.lo[0];
        const float y = (c & 2) ? bounds.hi[1] : bounds.lo[1];
        const float z = (c & 4) ? bounds.hi[2] : bounds.lo[2];
        if (styleInFrustum(view, x, y, z, kStyleGuard)) add(x, y, z);
    }
    if (!any) return out;

    out.ok = true;
    for (int k = 0; k < 3; ++k) {
        const float pad = 0.01f * (hi[k] - lo[k]) + 1.0f;
        out.lo[k] = lo[k] - pad;
        out.hi[k] = hi[k] + pad;
    }
    return styleIntersect(out, bounds);
}

// THE BOX STRETCHED TOWARDS THE SUN, by as far as the slab's height throws a shadow, capped.
inline StyleBox styleSunward(StyleBox b, const StyleBox& bounds, float sx, float sy, float sz,
                             float cap) {
    if (!b.ok || !(sy > 0.03f)) return b;
    const float across = std::sqrt(sx * sx + sz * sz);
    if (!(across > 1e-4f)) return b;
    const float stretch = std::fmin((bounds.hi[1] - b.lo[1]) * across / sy, cap);
    const float dx = sx / across * stretch, dz = sz / across * stretch;
    if (dx > 0.0f) b.hi[0] += dx; else b.lo[0] += dx;
    if (dz > 0.0f) b.hi[2] += dz; else b.lo[2] += dz;
    return styleIntersect(b, bounds);
}

// A level over `box` at `budget` voxels: cubic cells, the box grown to whole cells.
inline StyleLevel styleLevelFor(const StyleBox& box, long long budget) {
    StyleLevel L;
    const float vol = styleBoxVolume(box);
    if (!(vol > 0.0f) || budget < 8) return L;
    float cell = std::cbrt(vol / static_cast<float>(budget));
    if (cell < kStyleMinCell) cell = kStyleMinCell;
    int n[3];
    for (int k = 0; k < 3; ++k) {
        const float ext = box.hi[k] - box.lo[k];
        // THE LONGEST SIDE MAY NOT PASS kStyleMaxSide: the cell grows instead.
        if (ext / cell > static_cast<float>(kStyleMaxSide)) cell = ext / static_cast<float>(kStyleMaxSide);
    }
    for (int k = 0; k < 3; ++k) {
        const float ext = box.hi[k] - box.lo[k];
        int v = static_cast<int>(std::ceil(ext / cell));
        n[k] = v < 2 ? 2 : (v > kStyleMaxSide ? kStyleMaxSide : v);
    }
    L.present = 1;
    L.nx = n[0]; L.ny = n[1]; L.nz = n[2];
    L.bx = (n[0] + kStyleBlock - 1) / kStyleBlock;
    L.by = (n[1] + kStyleBlock - 1) / kStyleBlock;
    L.bz = (n[2] + kStyleBlock - 1) / kStyleBlock;
    // CENTRED ON THE BOX, grown to whole cells.
    const float c[3] = { 0.5f * (box.lo[0] + box.hi[0]), 0.5f * (box.lo[1] + box.hi[1]),
                         0.5f * (box.lo[2] + box.hi[2]) };
    L.loX = c[0] - 0.5f * n[0] * cell; L.hiX = L.loX + n[0] * cell;
    L.loY = c[1] - 0.5f * n[1] * cell; L.hiY = L.loY + n[1] * cell;
    L.loZ = c[2] - 0.5f * n[2] * cell; L.hiZ = L.loZ + n[2] * cell;
    L.cell = cell;
    L.invCell = 1.0f / cell;
    return L;
}

// THE THREE LEVELS for the cumulus layer `cumulus`, seen through `view`, with the sun towards
// (sx, sy, sz). `heroReach` is heroBoxReach (0: no hero) round (heroX, heroZ).
inline void planStyleLevels(const cloud::ViewParams& view, const AirMapLayerExtent& cumulus,
                            float heroX, float heroZ, float heroReach,
                            float sx, float sy, float sz, float budgetScale,
                            StylizedFrame& f) {
    for (int k = 0; k < kStyleLevels; ++k) f.level[k] = StyleLevel{};
    f.voxels = 0;
    f.blocks = 0;
    f.anyCloud = 0;

    const StyleBox bounds = styleLayerBounds(cumulus);
    if (!bounds.ok) return;

    const float farReach = cumulus.fadeRadius > 0.0f ? cumulus.fadeRadius : kStyleFarReach;

    StyleBox box[kStyleLevels];
    box[2] = styleVisibleBox(view, bounds, farReach);
    box[1] = styleVisibleBox(view, bounds, std::fmin(kStyleMidReach, farReach));

    if (heroReach > 0.0f) {
        StyleBox hero;
        hero.ok = true;
        hero.lo[0] = heroX - heroReach; hero.hi[0] = heroX + heroReach;
        hero.lo[1] = bounds.lo[1];      hero.hi[1] = bounds.hi[1];
        hero.lo[2] = heroZ - heroReach; hero.hi[2] = heroZ + heroReach;
        box[0] = styleIntersect(styleVisibleBox(view, styleIntersect(hero, bounds), 0.0f), hero);
    }
    if (!box[0].ok) box[0] = styleVisibleBox(view, bounds, std::fmin(kStyleNearReach, farReach));

    for (int k = 0; k < kStyleLevels; ++k) {
        box[k] = styleSunward(box[k], bounds, sx, sy, sz, kStyleSunStretch[k]);
    }

    long long budget[kStyleLevels];
    for (int k = 0; k < kStyleLevels; ++k) {
        budget[k] = static_cast<long long>(static_cast<double>(kStyleBudget[k]) * budgetScale);
    }

    // A LEVEL HARDLY SMALLER THAN THE NEXT ONE OUT IS DROPPED, and its voxels go to that one.
    for (int k = 0; k + 1 < kStyleLevels; ++k) {
        if (!box[k].ok) continue;
        int next = -1;
        for (int j = k + 1; j < kStyleLevels; ++j) {
            if (box[j].ok) { next = j; break; }
        }
        if (next < 0) break;
        if (styleBoxVolume(box[next]) < kStyleMergeRatio * styleBoxVolume(box[k])) {
            budget[next] += budget[k];
            box[k] = StyleBox{};
        }
    }

    long long voxels = 0, blocks = 0;
    for (int k = 0; k < kStyleLevels; ++k) {
        if (!box[k].ok) continue;
        StyleLevel L = styleLevelFor(box[k], budget[k]);
        if (!L.present) continue;
        L.voxelOffset = voxels;
        L.blockOffset = blocks;
        voxels += styleVoxels(L);
        blocks += styleBlocks(L);
        f.level[k] = L;
        f.anyCloud = 1;
    }
    f.voxels = voxels;
    f.blocks = blocks;
}

// THE LOOK'S CONSTANTS from its controls. `ref` is the layer's peak extinction; `timeSeconds`
// drives the fuzz's boil, and the two offsets carry it with the hero and with the field.
inline void styleLookConstants(const cloud::StylizedParams& p, float ref, float timeSeconds,
                               float heroDX, float heroDZ, float fieldDX, float fieldDZ,
                               bool draft, StylizedFrame& f) {
    const auto unit = [](float v) { return v < 0.0f ? 0.0f : (v > 1.0f ? 1.0f : v); };
    const float puff = unit(p.puffiness);
    const float soft = unit(p.softness);
    const float silver = unit(p.silverLining);
    const float fuzz = unit(p.fuzz);

    f.ref      = ref > 1e-6f ? ref : 1e-6f;
    f.puff     = puff;
    f.edge     = 0.10f;
    f.edgeSoft = styleMix(0.10f, 0.015f, puff);
    f.solid    = 3.0f;

    f.fuzzAmp   = 0.6f * fuzz;
    const float size = p.fuzzSize > 1.0f ? p.fuzzSize : 1.0f;
    f.fuzzScale = static_cast<float>(kStyleNoisePeriod) / size;
    const float rise = -kStyleFuzzRise * timeSeconds;
    f.fuzzHeroX  = -heroDX;  f.fuzzHeroY  = rise; f.fuzzHeroZ  = -heroDZ;
    f.fuzzFieldX = -fieldDX; f.fuzzFieldY = rise; f.fuzzFieldZ = -fieldDZ;

    f.msA = styleMix(0.35f, 0.75f, soft);
    f.msB = styleMix(0.55f, 0.15f, soft);
    f.msC = 0.5f;
    f.msOctaves = 4;
    f.aoK = styleMix(1.0f, 0.2f, soft);

    f.gForward = styleMix(0.45f, 0.85f, silver);
    f.wForward = styleMix(0.55f, 0.85f, silver);
    f.gBack    = -0.2f;

    f.tintR = p.shadowTint[0] > 0.0f ? p.shadowTint[0] : 0.0f;
    f.tintG = p.shadowTint[1] > 0.0f ? p.shadowTint[1] : 0.0f;
    f.tintB = p.shadowTint[2] > 0.0f ? p.shadowTint[2] : 0.0f;
    f.gain  = p.brightness > 0.0f ? p.brightness : 0.0f;

    f.stepScale = draft ? 1.2f : 0.8f;

    // THE SHAPE PASS, with Puffiness: rounding up to 70 m, the base's dome up to 600 m.
    f.baseRound  = 600.0f * puff;
    f.blurMetres = 70.0f * puff;
    f.cubic      = 1;
    f.lightScale = styleMix(1.0f, 0.2f, soft);
    f.aoStyle    = 0.0f;

    // THE CALIBRATION, MEASURED (PROGRESS.md, build 32): with these, Brightness 100% puts the
    // hero's mean near a converged Physical frame of the same cloud, at a 12 and a 40 degree
    // sun -- with more of it from the sky than Physical's, which is the look's blue.
    f.sunGain      = 0.85f;
    f.skyGain      = 1.5f;
    f.sideSky      = 0.5f;
    f.groundBounce = 0.5f;
}

// ---------------------------------------------------------------------------
// The fuzz's noise tile
// ---------------------------------------------------------------------------

// A TILING GRADIENT NOISE, three octaves, kStyleNoiseSide^3 floats in [0, 1]. Built once per
// process and never changed: it is texture, not field, so it carries no seed of the user's.
inline const std::vector<float>& styleNoiseTile() {
    static const std::vector<float> tile = [] {
        const int N = kStyleNoiseSide;
        std::vector<float> out(static_cast<size_t>(N) * N * N, 0.0f);
        const auto hash = [](unsigned int x, unsigned int y, unsigned int z, unsigned int s) {
            unsigned int h = x * 0x8da6b343u ^ y * 0xd8163841u ^ z * 0xcb1ab31fu ^ s * 0x165667b1u;
            h ^= h >> 13; h *= 0x5bd1e995u; h ^= h >> 15;
            return h;
        };
        const auto grad = [&](int x, int y, int z, int period, unsigned int s, float fx, float fy, float fz) {
            const unsigned int h = hash(static_cast<unsigned int>((x % period + period) % period),
                                        static_cast<unsigned int>((y % period + period) % period),
                                        static_cast<unsigned int>((z % period + period) % period), s);
            // TWELVE EDGE DIRECTIONS, as Perlin's improved noise.
            static const float g[12][3] = { {1,1,0},{-1,1,0},{1,-1,0},{-1,-1,0},{1,0,1},{-1,0,1},
                                            {1,0,-1},{-1,0,-1},{0,1,1},{0,-1,1},{0,1,-1},{0,-1,-1} };
            const float* v = g[h % 12u];
            return v[0] * fx + v[1] * fy + v[2] * fz;
        };
        const auto fade = [](float t) { return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f); };
        const int periods[3] = { N / kStyleNoisePeriod, N / (kStyleNoisePeriod / 2), N / (kStyleNoisePeriod / 4) };
        const float weights[3] = { 0.55f, 0.3f, 0.15f };
        float lo = 1e30f, hi = -1e30f;
        for (int z = 0; z < N; ++z) {
            for (int y = 0; y < N; ++y) {
                for (int x = 0; x < N; ++x) {
                    float sum = 0.0f;
                    for (int o = 0; o < 3; ++o) {
                        const int P = periods[o];               // lattice cells across the tile
                        const float s = static_cast<float>(P) / static_cast<float>(N);
                        const float px = x * s, py = y * s, pz = z * s;
                        const int ix = static_cast<int>(std::floor(px));
                        const int iy = static_cast<int>(std::floor(py));
                        const int iz = static_cast<int>(std::floor(pz));
                        const float fx = px - ix, fy = py - iy, fz = pz - iz;
                        const float u = fade(fx), v = fade(fy), w = fade(fz);
                        float c[8];
                        for (int k = 0; k < 8; ++k) {
                            const int dx = k & 1, dy = (k >> 1) & 1, dz = (k >> 2) & 1;
                            c[k] = grad(ix + dx, iy + dy, iz + dz, P, static_cast<unsigned int>(o),
                                        fx - dx, fy - dy, fz - dz);
                        }
                        const float x0 = c[0] + (c[1] - c[0]) * u, x1 = c[2] + (c[3] - c[2]) * u;
                        const float x2 = c[4] + (c[5] - c[4]) * u, x3 = c[6] + (c[7] - c[6]) * u;
                        const float y0 = x0 + (x1 - x0) * v, y1 = x2 + (x3 - x2) * v;
                        sum += weights[o] * (y0 + (y1 - y0) * w);
                    }
                    out[(static_cast<size_t>(z) * N + y) * N + x] = sum;
                    lo = std::fmin(lo, sum);
                    hi = std::fmax(hi, sum);
                }
            }
        }
        const float span = hi > lo ? hi - lo : 1.0f;
        for (float& v : out) v = (v - lo) / span;
        return out;
    }();
    return tile;
}

} // namespace plugin::kernel
