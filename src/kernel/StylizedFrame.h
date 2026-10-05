#pragma once

// THE STYLIZED LOOK'S FRAME (build 32): what one frame's bakes made, and how to read them.
//
// ===========================================================================
// THE SHAPE OF THE RENDERER, IN ONE PLACE.
//
// Physical traces random walks through a density it evaluates at every step: a few hundred
// procedural evaluations per sample, and noise until there are many samples. Stylized pays
// for the density ONCE A FRAME, at the points of a few grids, and then never again:
//
//   1. THE PLAN (StylizedPlan.h): up to kStyleLevels grids over the cumulus the camera can
//      see -- the finest round the hero, coarser ones out to Render Distance.
//   2. THE BAKES, per backend because they call the generated Slang: the density at every
//      voxel, the sky in every direction, the air in front of every pixel at every depth, and
//      the cirrus along every few pixels' rays.
//   3. THE LIGHT (StylizedShading.h): every voxel's optical depth towards the sun, and up and
//      down through its own column, from the density grids.
//   4. THE MARCH (StylizedShading.h): one ray per pixel, read from the grids. Deterministic,
//      so there is nothing to average and nothing to denoise.
//
// THE PHYSICAL MEDIUM IS ONLY READ. Stylized draws the same cloud, shaped and lit its own way.
// ===========================================================================
//
// EVERYTHING HERE IS A PLAIN AGGREGATE OF SCALARS, passed by value to a kernel as RenderRequest
// is. The buffers travel beside it as pointers, host or device, which this header never owns.

#include "Shading.h"

namespace plugin::kernel {

// ---------------------------------------------------------------------------
// Sizes
// ---------------------------------------------------------------------------

// THE GRIDS: the finest round the hero, then the field near the eye, then the field out to
// Render Distance. A point is read from the finest grid that holds it.
constexpr int kStyleLevels = 3;

// EMPTY SPACE IS SKIPPED A BLOCK AT A TIME: one flag per kStyleBlock^3 voxels says whether
// anything in it (or in the voxel round it, which trilinear reads) can be cloud.
constexpr int kStyleBlock = 8;

// THE FUZZ'S TILE, voxels a side, and how many of them one Fuzz Size spans. The noise's largest
// lattice cell is kStyleNoisePeriod voxels, so the tile repeats every side / period Fuzz Sizes.
constexpr int kStyleNoiseSide   = 128;
constexpr int kStyleNoisePeriod = 16;

// THE SKY TABLE: azimuth across, elevation down, with rows crowded at the horizon where the sky
// changes fastest (the row is the square root of the elevation's fraction).
constexpr int kStyleSkyW = 256;
constexpr int kStyleSkyH = 128;

// THE AIR IN FRONT OF EVERY PIXEL: a grid over the buffer's rect, and depths spaced evenly in
// log from kStyleAirNear to the far end of the cloud.
constexpr int   kStyleAirW    = 32;
constexpr int   kStyleAirH    = 32;
constexpr int   kStyleAirD    = 32;
constexpr float kStyleAirNear = 50.0f;

// THE CIRRUS IS MARCHED ONCE PER kStyleCirrusStride x kStyleCirrusStride PIXELS, at this many
// steps through its slab, and read between them. It is soft, and it is the costly density.
constexpr int kStyleCirrusStride = 4;
constexpr int kStyleCirrusSteps  = 12;

// THE LIGHT'S WALK TOWARDS THE SUN: steps, and how much longer each is than the last, in cells.
constexpr int   kStyleSunSteps  = 48;
constexpr float kStyleSunGrowth = 0.12f;

// THE CAMERA'S WALK: at most this many iterations, empty blocks included.
constexpr int kStyleMarchIterations = 1024;

// A ray this opaque is finished.
constexpr float kStyleOpaque = 0.004f;

// ---------------------------------------------------------------------------
// The frame
// ---------------------------------------------------------------------------

struct Style4 { float x, y, z, w; };

// One grid. CUBIC VOXELS: one `cell` on every axis, so a step is the same length whichever way
// the ray runs and the light's walk reads it alike in every direction.
struct StyleLevel {
    int   present = 0;
    int   nx = 0, ny = 0, nz = 0;       // voxels
    int   bx = 0, by = 0, bz = 0;       // occupancy blocks, ceil(n / kStyleBlock)
    float loX = 0.0f, loY = 0.0f, loZ = 0.0f;   // the box, metres; voxel i's centre is lo + (i + 0.5) cell
    float hiX = 0.0f, hiY = 0.0f, hiZ = 0.0f;
    float cell    = 1.0f;               // metres
    float invCell = 1.0f;
    long long voxelOffset = 0;          // into the buffers every level shares
    long long blockOffset = 0;
};

inline long long styleVoxels(const StyleLevel& L) {
    return L.present ? static_cast<long long>(L.nx) * L.ny * L.nz : 0;
}
inline long long styleBlocks(const StyleLevel& L) {
    return L.present ? static_cast<long long>(L.bx) * L.by * L.bz : 0;
}

struct StylizedFrame {
    StyleLevel level[kStyleLevels];
    long long  voxels = 0;
    long long  blocks = 0;
    int        anyCloud = 0;            // any level present

    // THE DENSITY'S SCALE: the cumulus layer's peak extinction, per metre. A voxel's density
    // over this is the fraction the look's cut is made at.
    float ref = 0.03f;

    // THE CUT (StylizedParams::puffiness): sigma = mix(ref * n, ref * solid * smoothstep(edge -
    // edgeSoft, edge + edgeSoft, n), puff), n the density's fraction after the fuzz.
    float puff = 0.0f, edge = 0.1f, edgeSoft = 0.1f, solid = 3.0f;

    // THE FUZZ: n is eroded by fuzzAmp x the noise, the noise read at (p + offset) x fuzzScale,
    // in tile voxels. The finest level rides with the hero, the rest with the field.
    float fuzzAmp = 0.0f, fuzzScale = 1.0f;
    float fuzzHeroX = 0.0f, fuzzHeroY = 0.0f, fuzzHeroZ = 0.0f;
    float fuzzFieldX = 0.0f, fuzzFieldY = 0.0f, fuzzFieldZ = 0.0f;
    int   fuzzHeroLevel = -1;           // the level that rides with the hero, or -1

    // THE SUN, and what it delivers at the cumulus and at the cirrus: irradiance on a face square
    // to it, after the air above.
    float sunX = 0.0f, sunY = 1.0f, sunZ = 0.0f;
    float sunR = 0.0f, sunG = 0.0f, sunB = 0.0f;
    float sunCiR = 0.0f, sunCiG = 0.0f, sunCiB = 0.0f;

    // THE SKYLIGHT, as the mean radiance of the sky above and of the ground below.
    float skyR = 0.0f, skyG = 0.0f, skyB = 0.0f;
    float gndR = 0.0f, gndG = 0.0f, gndB = 0.0f;

    // THE LIGHT'S SHAPE (StylizedParams::softness, silverLining). Octave i of the sunlight is
    // msA^i of the energy, through msB^i of the optical depth, with the lobes' g x msC^i.
    float msA = 0.5f, msB = 0.5f, msC = 0.5f;
    int   msOctaves = 4;
    float gForward = 0.6f, gBack = -0.2f, wForward = 0.7f;
    float aoK = 0.5f;                   // how fast the skylight fades with optical depth
    float tintR = 1.0f, tintG = 1.0f, tintB = 1.0f;
    float gain = 1.0f;                  // StylizedParams::brightness, times the calibration

    // THE CIRRUS, as a veil: on, its strength on the optical depth, its lobe.
    int   cirrusOn = 0;
    float cirrusGain = 1.0f, cirrusG = 0.5f;
    int   cirrusW = 0, cirrusH = 0;     // map texels

    // THE CAMERA'S WALK, in cells.
    float stepScale = 0.8f;

    // HOW THE GRIDS ARE READ: 1 is a cubic B-spline (eight filtered taps), which has no facets
    // at the cells; 0 is plain trilinear, which shows the cells as terraces once the cut is sharp.
    int   cubic = 1;

    // THE LIGHT'S OWN SCALES. The sun's optical depth is the cut cloud's times lightScale -- under
    // 1 the light soaks in further than the cut alone would let it. The skylight fades with the
    // optical depth of a medium between the cloud's own density (aoStyle 0) and the cut (1).
    float lightScale = 1.0f;
    float aoStyle    = 0.0f;
    float sunGain    = 1.0f;
    float skyGain    = 1.0f;

    // THE SKYLIGHT'S PATHS IN: sideSky of it comes round the dome's sides, through the shallower
    // of a point's two columns, rather than straight down through the cloud above -- which is
    // what keeps an underside blue-grey instead of the ground's beige. groundBounce scales the
    // light from the ground below.
    float sideSky      = 0.5f;
    float groundBounce = 0.5f;

    // THE SHAPE PASS, between the bake and the light. ROUNDING blurs the density over this many
    // metres, so thin spikes melt into the puffs beside them. THE BASE is lifted into a dome: the
    // density fades in over baseRound metres above the layer's flat floor at baseY, so the cut
    // meets the floor at the cloud's thin edge first and curves under the thick middle.
    float baseY     = 0.0f;
    float baseRound = 0.0f;
    float blurMetres = 0.0f;

    // SPARES FOR TUNING (--style-tune tune0=...), read by whatever experiment needs them.
    float tune[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };

    // THE BACKGROUND: the sky (1) or nothing (0, Background Transparent).
    int   skyOn = 1;
    int   discOn = 1;                   // Show Sun
    float discCos = 0.99999f;
    float discR = 0.0f, discG = 0.0f, discB = 0.0f;

    // THE MAPS OVER THE BUFFER: frame pixels at the buffer's top left, and how many it spans.
    float mapX0 = 0.0f, mapY0 = 0.0f, mapW = 1.0f, mapH = 1.0f;
    float airFar = 100000.0f;           // the far end of the air table, metres
};

// ---------------------------------------------------------------------------
// Small maths
// ---------------------------------------------------------------------------

MT_DEVICE float styleClamp(float v, float lo, float hi) { return v < lo ? lo : (v > hi ? hi : v); }
MT_DEVICE float styleMix(float a, float b, float t) { return a + (b - a) * t; }

MT_DEVICE float styleSmooth(float e0, float e1, float x) {
    const float t = styleClamp((x - e0) / (e1 - e0 > 1e-6f ? e1 - e0 : 1e-6f), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

// Henyey-Greenstein, per steradian.
MT_DEVICE float styleHg(float g, float cosTheta) {
    const float d = 1.0f + g * g - 2.0f * g * cosTheta;
    return (1.0f - g * g) * 0.0795774715f / (d * sqrtf(d > 1e-6f ? d : 1e-6f));
}

// THE SLAB OF A BOX ALONG A RAY: [t0, t1], false if it misses.
MT_DEVICE bool styleBoxRange(float loX, float loY, float loZ, float hiX, float hiY, float hiZ,
                             Vec3 ro, Vec3 rd, float& t0, float& t1) {
    float a = -1e30f, b = 1e30f;
    const float o[3]  = { ro.x, ro.y, ro.z };
    const float d[3]  = { rd.x, rd.y, rd.z };
    const float lo[3] = { loX, loY, loZ };
    const float hi[3] = { hiX, hiY, hiZ };
    for (int k = 0; k < 3; ++k) {
        if (fabsf(d[k]) < 1e-9f) {
            if (o[k] < lo[k] || o[k] > hi[k]) return false;
            continue;
        }
        const float inv = 1.0f / d[k];
        float n = (lo[k] - o[k]) * inv;
        float f = (hi[k] - o[k]) * inv;
        if (n > f) { const float s = n; n = f; f = s; }
        a = n > a ? n : a;
        b = f < b ? f : b;
    }
    t0 = a;
    t1 = b;
    return b >= a;
}

MT_DEVICE bool styleInside(const StyleLevel& L, Vec3 p) {
    return L.present && p.x >= L.loX && p.x <= L.hiX && p.y >= L.loY && p.y <= L.hiY &&
           p.z >= L.loZ && p.z <= L.hiZ;
}

// THE FINEST LEVEL HOLDING p, or -1.
MT_DEVICE int styleFinest(const StylizedFrame& f, Vec3 p) {
    for (int k = 0; k < kStyleLevels; ++k) {
        if (styleInside(f.level[k], p)) return k;
    }
    return -1;
}

// THE CUT: extinction per metre from the density's fraction n (after the fuzz).
MT_DEVICE float styleSigma(const StylizedFrame& f, float n) {
    if (!(n > 0.0f)) return 0.0f;
    const float phys = f.ref * n;
    const float sty  = f.ref * f.solid * styleSmooth(f.edge - f.edgeSoft, f.edge + f.edgeSoft, n);
    return styleMix(phys, sty, f.puff);
}

// THE FUZZ: erosion by the noise, strongest where the cloud is thinnest. The core is untouched,
// so the fuzz frays edges rather than thinning the whole cloud.
MT_DEVICE float styleErode(const StylizedFrame& f, float n, float noise) {
    if (!(f.fuzzAmp > 0.0f)) return n;
    const float e = f.fuzzAmp * noise;
    // NEVER ABOVE n: the rescale alone would lift a density over the layer's peak, and the empty
    // blocks are skipped on the promise that the fuzz only takes away (TestStylized).
    const float r = (n - e) / (1.0f - e > 0.05f ? 1.0f - e : 0.05f);
    return r < n ? r : n;
}

// ---------------------------------------------------------------------------
// The sky table
// ---------------------------------------------------------------------------

// Texel (i, j) -> direction. Elevation is crowded at the horizon: row j's fraction from the
// middle is the square root of the elevation's.
MT_DEVICE Vec3 styleSkyDir(float u, float v) {
    const float az = (u - 0.5f) * 6.283185307f;
    const float s  = v * 2.0f - 1.0f;                 // -1 bottom .. 1 top
    const float el = (s >= 0.0f ? s * s : -s * s) * 1.570796327f;
    const float c  = cosf(el);
    return vec3(sinf(az) * c, sinf(el), cosf(az) * c);
}

MT_DEVICE void styleSkyUv(Vec3 d, float& u, float& v) {
    const float az = atan2f(d.x, d.z);
    u = az * 0.1591549431f + 0.5f;
    const float el = asinf(styleClamp(d.y, -1.0f, 1.0f)) * 0.6366197724f;   // -1..1
    const float s  = el >= 0.0f ? sqrtf(el) : -sqrtf(-el);
    v = s * 0.5f + 0.5f;
}

// Bilinear, wrapping in azimuth. `sky` is kStyleSkyW x kStyleSkyH float4s, RGB and unused.
MT_DEVICE Vec3 styleSky(const float* sky, Vec3 d) {
    float u, v;
    styleSkyUv(d, u, v);
    const float x = u * kStyleSkyW - 0.5f;
    const float y = styleClamp(v * kStyleSkyH - 0.5f, 0.0f, static_cast<float>(kStyleSkyH - 1));
    const float xf = floorf(x), yf = floorf(y);
    const float fx = x - xf, fy = y - yf;
    int x0 = static_cast<int>(xf), y0 = static_cast<int>(yf);
    int x1 = x0 + 1, y1 = y0 + 1 < kStyleSkyH ? y0 + 1 : kStyleSkyH - 1;
    x0 = (x0 % kStyleSkyW + kStyleSkyW) % kStyleSkyW;
    x1 = (x1 % kStyleSkyW + kStyleSkyW) % kStyleSkyW;
    const float* a = sky + (y0 * kStyleSkyW + x0) * 4;
    const float* b = sky + (y0 * kStyleSkyW + x1) * 4;
    const float* c = sky + (y1 * kStyleSkyW + x0) * 4;
    const float* e = sky + (y1 * kStyleSkyW + x1) * 4;
    const float w00 = (1 - fx) * (1 - fy), w10 = fx * (1 - fy), w01 = (1 - fx) * fy, w11 = fx * fy;
    return vec3(a[0] * w00 + b[0] * w10 + c[0] * w01 + e[0] * w11,
                a[1] * w00 + b[1] * w10 + c[1] * w01 + e[1] * w11,
                a[2] * w00 + b[2] * w10 + c[2] * w01 + e[2] * w11);
}

// ---------------------------------------------------------------------------
// The air table
// ---------------------------------------------------------------------------

// Depth slice k -> metres, and back.
MT_DEVICE float styleAirDepth(const StylizedFrame& f, float k) {
    const float r = logf(f.airFar / kStyleAirNear);
    return kStyleAirNear * expf(r * k / static_cast<float>(kStyleAirD - 1));
}
MT_DEVICE float styleAirSlice(const StylizedFrame& f, float t) {
    const float r = logf(f.airFar / kStyleAirNear);
    const float k = logf((t > kStyleAirNear ? t : kStyleAirNear) / kStyleAirNear) / r;
    return styleClamp(k * static_cast<float>(kStyleAirD - 1), 0.0f, static_cast<float>(kStyleAirD - 1));
}

// THE AIR OVER [0, t] in front of buffer fraction (u, v): what it adds, and what it lets
// through. Trilinear. `air` is kStyleAirW x kStyleAirH x kStyleAirD texels of two float4s:
// airIn then airT. Nearer than the table's first slice is read as that slice, scaled down.
MT_DEVICE void styleAir(const StylizedFrame& f, const float* air, float u, float v, float t,
                        Vec3& in, Vec3& tr) {
    const float x = styleClamp(u * kStyleAirW - 0.5f, 0.0f, static_cast<float>(kStyleAirW - 1));
    const float y = styleClamp(v * kStyleAirH - 0.5f, 0.0f, static_cast<float>(kStyleAirH - 1));
    const float z = styleAirSlice(f, t);
    const int x0 = static_cast<int>(x), y0 = static_cast<int>(y), z0 = static_cast<int>(z);
    const int x1 = x0 + 1 < kStyleAirW ? x0 + 1 : x0;
    const int y1 = y0 + 1 < kStyleAirH ? y0 + 1 : y0;
    const int z1 = z0 + 1 < kStyleAirD ? z0 + 1 : z0;
    const float fx = x - x0, fy = y - y0, fz = z - z0;
    float acc[6] = { 0, 0, 0, 0, 0, 0 };
    for (int c = 0; c < 8; ++c) {
        const int xi = (c & 1) ? x1 : x0, yi = (c & 2) ? y1 : y0, zi = (c & 4) ? z1 : z0;
        const float w = ((c & 1) ? fx : 1 - fx) * ((c & 2) ? fy : 1 - fy) * ((c & 4) ? fz : 1 - fz);
        const float* e = air + ((static_cast<long long>(zi) * kStyleAirH + yi) * kStyleAirW + xi) * 8;
        acc[0] += e[0] * w; acc[1] += e[1] * w; acc[2] += e[2] * w;
        acc[3] += e[4] * w; acc[4] += e[5] * w; acc[5] += e[6] * w;
    }
    // NEARER THAN THE FIRST SLICE, the air is scaled towards none at the eye.
    const float near = t < kStyleAirNear ? (t > 0.0f ? t / kStyleAirNear : 0.0f) : 1.0f;
    in = vec3(acc[0] * near, acc[1] * near, acc[2] * near);
    tr = vec3(1.0f - (1.0f - acc[3]) * near, 1.0f - (1.0f - acc[4]) * near,
              1.0f - (1.0f - acc[5]) * near);
}

// THE FRAME PIXEL AT BUFFER FRACTION (u, v) of a map over the buffer, and back.
MT_DEVICE float styleMapU(const StylizedFrame& f, float frameX) { return (frameX - f.mapX0) / f.mapW; }
MT_DEVICE float styleMapV(const StylizedFrame& f, float frameY) { return (frameY - f.mapY0) / f.mapH; }

// ---------------------------------------------------------------------------
// The cirrus map
// ---------------------------------------------------------------------------

// Bilinear: optical depth along the ray, and the depth-weighted distance. `ci` is
// f.cirrusW x f.cirrusH float2s.
MT_DEVICE void styleCirrus(const StylizedFrame& f, const float* ci, float u, float v,
                           float& tau, float& tMean) {
    tau = 0.0f;
    tMean = 0.0f;
    if (!f.cirrusOn || f.cirrusW <= 0 || f.cirrusH <= 0) return;
    const float x = styleClamp(u * f.cirrusW - 0.5f, 0.0f, static_cast<float>(f.cirrusW - 1));
    const float y = styleClamp(v * f.cirrusH - 0.5f, 0.0f, static_cast<float>(f.cirrusH - 1));
    const int x0 = static_cast<int>(x), y0 = static_cast<int>(y);
    const int x1 = x0 + 1 < f.cirrusW ? x0 + 1 : x0;
    const int y1 = y0 + 1 < f.cirrusH ? y0 + 1 : y0;
    const float fx = x - x0, fy = y - y0;
    const float* a = ci + (y0 * f.cirrusW + x0) * 2;
    const float* b = ci + (y0 * f.cirrusW + x1) * 2;
    const float* c = ci + (y1 * f.cirrusW + x0) * 2;
    const float* e = ci + (y1 * f.cirrusW + x1) * 2;
    const float w00 = (1 - fx) * (1 - fy), w10 = fx * (1 - fy), w01 = (1 - fx) * fy, w11 = fx * fy;
    tau = a[0] * w00 + b[0] * w10 + c[0] * w01 + e[0] * w11;
    // THE DISTANCE WEIGHTED BY DEPTH, so a texel with no cirrus does not drag its neighbour's in.
    const float wt = a[0] * w00 + b[0] * w10 + c[0] * w01 + e[0] * w11;
    tMean = wt > 1e-8f ? (a[0] * a[1] * w00 + b[0] * b[1] * w10 + c[0] * c[1] * w01 + e[0] * e[1] * w11) / wt
                       : 0.0f;
}

// THE RAY FOR FRAME PIXEL (fx, fy), with the frame's origin at the top left: the camera's own.
MT_DEVICE Vec3 styleFrameRay(const cloud::ViewParams& view, float fx, float fy) {
    cloud::ViewParams v = view;
    v.originX = 0;
    v.originY = 0;
    return primaryRayDirection(v, 0, 0, fx - 0.5f, fy - 0.5f);
}

// ---------------------------------------------------------------------------
// The bakes' texels, shared so both backends bake the same points
// ---------------------------------------------------------------------------

// VOXEL i OF ALL LEVELS TOGETHER: its level and its centre. False past the end.
MT_DEVICE bool styleVoxelCentre(const StylizedFrame& f, long long i, int& level, Vec3& p) {
    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        const long long n = static_cast<long long>(L.nx) * L.ny * L.nz;
        if (i < L.voxelOffset || i >= L.voxelOffset + n) continue;
        const long long j = i - L.voxelOffset;
        const int x = static_cast<int>(j % L.nx);
        const int y = static_cast<int>((j / L.nx) % L.ny);
        const int z = static_cast<int>(j / (static_cast<long long>(L.nx) * L.ny));
        level = k;
        p = vec3(L.loX + (x + 0.5f) * L.cell, L.loY + (y + 0.5f) * L.cell, L.loZ + (z + 0.5f) * L.cell);
        return true;
    }
    return false;
}

// AIR TABLE TEXEL (i, j, k): its ray through the buffer, and its depth.
MT_DEVICE void styleAirTexel(const StylizedFrame& f, const cloud::ViewParams& view, int i, int j, int k,
                             Vec3& dir, float& depth) {
    const float fx = f.mapX0 + (static_cast<float>(i) + 0.5f) / kStyleAirW * f.mapW;
    const float fy = f.mapY0 + (static_cast<float>(j) + 0.5f) / kStyleAirH * f.mapH;
    dir   = styleFrameRay(view, fx, fy);
    depth = styleAirDepth(f, static_cast<float>(k));
}

// CIRRUS MAP TEXEL (i, j): its ray, and where that ray is inside the ice slab [bottom, top]
// and within `reach` across from the eye. False if it never is.
MT_DEVICE bool styleCirrusTexel(const StylizedFrame& f, const cloud::ViewParams& view,
                                float bottom, float top, float reach, int i, int j,
                                Vec3& ro, Vec3& rd, float& t0, float& t1) {
    const float fx = f.mapX0 + (static_cast<float>(i) + 0.5f) / f.cirrusW * f.mapW;
    const float fy = f.mapY0 + (static_cast<float>(j) + 0.5f) / f.cirrusH * f.mapH;
    rd = styleFrameRay(view, fx, fy);
    ro = primaryRayOrigin(view);
    if (fabsf(rd.y) < 1e-5f) return false;
    float a = (bottom - ro.y) / rd.y, b = (top - ro.y) / rd.y;
    if (a > b) { const float s = a; a = b; b = s; }
    if (a < 0.0f) a = 0.0f;
    const float across = sqrtf(rd.x * rd.x + rd.z * rd.z);
    if (reach > 0.0f && across > 1e-6f && reach / across < b) b = reach / across;
    t0 = a;
    t1 = b;
    return b > a;
}

} // namespace plugin::kernel
