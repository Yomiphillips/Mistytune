#pragma once

// THE STYLIZED LOOK'S LIGHT AND MARCH (build 32), written once for both backends.
//
// Everything here reads the grids through a SAMPLER the backend supplies -- CUDA's hardware
// textures in StylizedCuda.cu, plain trilinear over host memory in StylizedCpu.cpp -- so the
// arithmetic exists once and only the reads differ. A sampler `S` provides:
//
//   float  density(int level, float x, float y, float z)   the density, trilinear
//   Style4 voxel(int level, float x, float y, float z)     (density, tau sun, tau up, tau down)
//
// THE DENSITY IN EVERY GRID IS A FRACTION OF THE LAYER'S PEAK (StylizedFrame::ref), not per
// metre: 0 to about 1 whatever the Density control says, which is what a half float holds well.
//   float  noise(float x, float y, float z)                the fuzz tile, wrapping
//   bool   occupied(long long block)                       may anything in the block be cloud?
//
// Coordinates are VOXEL coordinates, (p - lo) / cell: voxel i's centre sits at i + 0.5, which is
// where CUDA's unnormalised texture coordinates put a texel's centre too.
//
// INCLUDED ONLY BY THE TWO FILES THAT RUN IT, so tuning the look rebuilds them and not the
// generated renderer.

#include "StylizedFrame.h"

namespace plugin::kernel {

// THE SKYLIGHT'S MEDIUM: between the cloud's own density (aoStyle 0) and the cut (1). The cut is
// nearly opaque a few metres in, which would leave every side of a puff in the dark.
MT_DEVICE float styleSigmaAo(const StylizedFrame& f, float n) {
    if (!(n > 0.0f)) return 0.0f;
    return styleMix(f.ref * n, styleSigma(f, n), f.aoStyle);
}

// A CUBIC B-SPLINE FROM EIGHT FILTERED TAPS (Sigg and Hadwiger, GPU Gems 2 ch. 20), along one
// axis: the two taps' positions and the first one's weight, c a voxel coordinate (centres at
// i + 0.5). C2-smooth, so the cut's surface has no facets at the cells.
MT_DEVICE void styleCubicAxis(float c, float& h0, float& h1, float& g0) {
    const float x  = c - 0.5f;
    const float i  = floorf(x);
    const float t  = x - i;
    const float t2 = t * t, t3 = t2 * t;
    const float w0 = (1.0f / 6.0f) * (-t3 + 3.0f * t2 - 3.0f * t + 1.0f);
    const float w1 = (1.0f / 6.0f) * (3.0f * t3 - 6.0f * t2 + 4.0f);
    const float w2 = (1.0f / 6.0f) * (-3.0f * t3 + 3.0f * t2 + 3.0f * t + 1.0f);
    const float w3 = (1.0f / 6.0f) * t3;
    g0 = w0 + w1;
    h0 = i - 1.0f + w1 / g0 + 0.5f;
    h1 = i + 1.0f + w3 / (w2 + w3) + 0.5f;
}

MT_DEVICE Style4 styleLerp4(Style4 a, Style4 b, float t) {
    Style4 r;
    r.x = a.x + (b.x - a.x) * t; r.y = a.y + (b.y - a.y) * t;
    r.z = a.z + (b.z - a.z) * t; r.w = a.w + (b.w - a.w) * t;
    return r;
}

template <class S>
MT_DEVICE Style4 styleVoxelCubic(const S& smp, int L, float x, float y, float z) {
    float x0, x1, gx, y0, y1, gy, z0, z1, gz;
    styleCubicAxis(x, x0, x1, gx);
    styleCubicAxis(y, y0, y1, gy);
    styleCubicAxis(z, z0, z1, gz);
    // g is the FIRST tap's weight, so each lerp runs from the second tap towards the first.
    const Style4 a = styleLerp4(smp.voxel(L, x1, y0, z0), smp.voxel(L, x0, y0, z0), gx);
    const Style4 b = styleLerp4(smp.voxel(L, x1, y1, z0), smp.voxel(L, x0, y1, z0), gx);
    const Style4 c = styleLerp4(smp.voxel(L, x1, y0, z1), smp.voxel(L, x0, y0, z1), gx);
    const Style4 d = styleLerp4(smp.voxel(L, x1, y1, z1), smp.voxel(L, x0, y1, z1), gx);
    return styleLerp4(styleLerp4(d, c, gy), styleLerp4(b, a, gy), gz);
}

MT_DEVICE void styleVoxelCoords(const StyleLevel& L, Vec3 p, float& x, float& y, float& z) {
    x = (p.x - L.loX) * L.invCell;
    y = (p.y - L.loY) * L.invCell;
    z = (p.z - L.loZ) * L.invCell;
}

// ---------------------------------------------------------------------------
// The shape pass
// ---------------------------------------------------------------------------

// THE BASE'S DOME: the weight the density is given at height y.
MT_DEVICE float styleBaseWeight(const StylizedFrame& f, float y) {
    if (!(f.baseRound > 0.0f)) return 1.0f;
    return styleSmooth(f.baseY, f.baseY + f.baseRound, y);
}

// HOW WIDE THE ROUNDING IS ON LEVEL L, in voxels: a Gaussian's sigma, and its taps each side.
MT_DEVICE void styleBlurWidth(const StylizedFrame& f, const StyleLevel& L, float& sigma, int& radius) {
    sigma = f.blurMetres > 0.0f ? f.blurMetres * L.invCell : 0.0f;
    if (sigma < 0.3f) { sigma = 0.0f; radius = 0; return; }
    if (sigma > 3.0f) sigma = 3.0f;
    radius = static_cast<int>(ceilf(2.0f * sigma));
}

// ONE VOXEL OF ONE BLUR PASS along `axis` (0 x, 1 y, 2 z) of level L, voxel index v counted from
// the level's start.
//
// THE BASE'S DOME IS NOT BAKED IN. It is a gentle ramp in height, and a grid read through the
// texture unit's nine-bit weights turns a gentle ramp under a sharp cut into contour lines across
// the underside -- seen at 1080p. It is laid on analytically wherever the density is read:
// styleBaseWeight at the point's own height.
template <class Raw>
MT_DEVICE float styleBlurVoxel(const StylizedFrame& f, const StyleLevel& L, const Raw& raw,
                               long long v, int axis) {
    const int x = static_cast<int>(v % L.nx);
    const int y = static_cast<int>((v / L.nx) % L.ny);
    const int z = static_cast<int>(v / (static_cast<long long>(L.nx) * L.ny));
    float sigma;
    int radius;
    styleBlurWidth(f, L, sigma, radius);
    const int n = axis == 0 ? L.nx : (axis == 1 ? L.ny : L.nz);
    const int at = axis == 0 ? x : (axis == 1 ? y : z);
    const long long stride = axis == 0 ? 1 : (axis == 1 ? L.nx : static_cast<long long>(L.nx) * L.ny);
    float sum = 0.0f, wsum = 0.0f;
    for (int k = -radius; k <= radius; ++k) {
        int j = at + k;
        j = j < 0 ? 0 : (j >= n ? n - 1 : j);
        const float w = radius > 0 ? expf(-0.5f * k * k / (sigma * sigma)) : 1.0f;
        const long long q = v + static_cast<long long>(j - at) * stride;
        sum += w * raw(q);
        wsum += w;
    }
    return sum / wsum;
}

// ---------------------------------------------------------------------------
// The light
// ---------------------------------------------------------------------------

// THE OPTICAL DEPTH FROM p TO THE SUN through the look's cut of the cloud (without the fuzz,
// which is detail too fine to shadow). The walk reads the finest level wherever it is, its steps
// grow as it goes, and it stops where no level holds it: past the grids the air is clear.
template <class S>
MT_DEVICE float styleSunDepth(const StylizedFrame& f, const S& smp, Vec3 p) {
    const Vec3 sun = vec3(f.sunX, f.sunY, f.sunZ);
    const int L0 = styleFinest(f, p);
    if (L0 < 0) return 0.0f;
    float t = 0.5f * f.level[L0].cell;
    float tau = 0.0f;
    for (int i = 0; i < kStyleSunSteps; ++i) {
        const Vec3 q = p + sun * t;
        const int L = styleFinest(f, q);
        if (L < 0) break;
        const StyleLevel& lv = f.level[L];
        float x, y, z;
        styleVoxelCoords(lv, q, x, y, z);
        const float dt = lv.cell * (1.0f + kStyleSunGrowth * static_cast<float>(i));
        tau += styleSigma(f, smp.density(L, x, y, z) * styleBaseWeight(f, q.y)) * dt;
        t += dt;
        if (tau > 40.0f) break;
    }
    return tau;
}

// ONE COLUMN of level L, (ix, iz): the optical depth above and below every voxel in it, through
// that column's own voxels, each counting half of itself. THROUGH ACCESSORS, so the CPU's floats
// and the GPU's half floats run the same sums: raw(v) is voxel v's density and out(v, c, value)
// stores component c (2 up, 3 down) of its packed voxel, v counted from the level's own start.
template <class Raw, class Out>
MT_DEVICE void styleColumn(const StylizedFrame& f, const StyleLevel& L, const Raw& raw,
                           const Out& out, int ix, int iz) {
    float acc = 0.0f;
    for (int iy = L.ny - 1; iy >= 0; --iy) {
        const long long v = (static_cast<long long>(iz) * L.ny + iy) * L.nx + ix;
        const float s = styleSigmaAo(f, raw(v) * styleBaseWeight(f, L.loY + (iy + 0.5f) * L.cell)) * L.cell;
        out(v, 2, acc + 0.5f * s);
        acc += s;
    }
    acc = 0.0f;
    for (int iy = 0; iy < L.ny; ++iy) {
        const long long v = (static_cast<long long>(iz) * L.ny + iy) * L.nx + ix;
        const float s = styleSigmaAo(f, raw(v) * styleBaseWeight(f, L.loY + (iy + 0.5f) * L.cell)) * L.cell;
        out(v, 3, acc + 0.5f * s);
        acc += s;
    }
}

// ONE BLOCK's flag: can anything in it, or in the voxel round it that trilinear reads, be cloud?
// The cut only grows with the density and the fuzz only erodes it, so the block's largest
// density decides exactly. raw(v) as styleColumn takes it.
template <class Raw>
MT_DEVICE unsigned char styleBlockFlag(const StylizedFrame& f, const StyleLevel& L, const Raw& raw,
                                       int bx, int by, int bz) {
    const int x0 = bx * kStyleBlock - 1, y0 = by * kStyleBlock - 1, z0 = bz * kStyleBlock - 1;
    float most = 0.0f;
    for (int z = z0; z <= z0 + kStyleBlock + 1; ++z) {
        if (z < 0 || z >= L.nz) continue;
        for (int y = y0; y <= y0 + kStyleBlock + 1; ++y) {
            if (y < 0 || y >= L.ny) continue;
            const long long row = (static_cast<long long>(z) * L.ny + y) * L.nx;
            for (int x = x0; x <= x0 + kStyleBlock + 1; ++x) {
                if (x < 0 || x >= L.nx) continue;
                const float d = raw(row + x);
                most = d > most ? d : most;
            }
        }
    }
    return styleSigma(f, most) * L.cell > 1e-5f ? 1 : 0;
}

// ---------------------------------------------------------------------------
// The march
// ---------------------------------------------------------------------------

// The nearest level box the ray enters at or after t, or 1e30.
MT_DEVICE float styleNextEntry(const StylizedFrame& f, Vec3 ro, Vec3 rd, float t) {
    float best = 1e30f;
    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        float a, b;
        if (!styleBoxRange(L.loX, L.loY, L.loZ, L.hiX, L.hiY, L.hiZ, ro, rd, a, b)) continue;
        if (b <= t) continue;
        const float e = a > t ? a : t;
        best = e < best ? e : best;
    }
    return best;
}

// THE FINEST LEVEL WHOSE BOX HOLDS THE RAY AT t, judged by the ray's range through each box, or
// -1. styleFinest judges the point instead, and far out ro + rd * t rounds a hair outside a box
// whose range holds t -- most of all on a ray grazing a box's floor near the horizon. The march
// then asked for the next entry, was handed t back, and t + 1e-3 is t past 8 km in floats: the
// ray stood still until its iterations ran out, and the far field's bases came out speckled with
// the sky behind them.
MT_DEVICE int styleLevelAlong(const StylizedFrame& f, Vec3 ro, Vec3 rd, float t) {
    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        float a, b;
        if (styleBoxRange(L.loX, L.loY, L.loZ, L.hiX, L.hiY, L.hiZ, ro, rd, a, b) && a <= t && t <= b) {
            return k;
        }
    }
    return -1;
}

// HOW MUCH OF THE FUZZ A RAY SEES at distance t, with `pixelAngle` one pixel's angle in radians:
// all of it while a pixel is narrower than an eighth of Fuzz Size, none once it is a quarter.
// Noise finer than a pixel only speckles -- seen on the far field at 1080p.
MT_DEVICE float styleFuzzWeight(const StylizedFrame& f, float pixelAngle, float t) {
    if (!(f.fuzzScale > 0.0f)) return 0.0f;
    const float size = static_cast<float>(kStyleNoisePeriod) / f.fuzzScale;   // Fuzz Size, metres
    return styleClamp(2.0f - pixelAngle * t * 8.0f / size, 0.0f, 1.0f);
}

// THE CUT CLOUD AT p, read from level k: its extinction, and the voxel's packed light in `v`.
//
// `fuzz` SCALES THE FUZZ, 1 near and 0 where a pixel is wider than its fibres: see
// styleFuzzWeight.
template <class S>
MT_DEVICE float styleSigmaAt(const StylizedFrame& f, const S& smp, int k, Vec3 p, Style4& v,
                             float fuzz) {
    const StyleLevel& L = f.level[k];
    float x, y, z;
    styleVoxelCoords(L, p, x, y, z);
    v = f.cubic ? styleVoxelCubic(smp, k, x, y, z) : smp.voxel(k, x, y, z);
    float n = v.x * styleBaseWeight(f, p.y);
    if (f.fuzzAmp > 0.0f && fuzz > 0.0f && n > 0.0f) {
        const bool hero = k == f.fuzzHeroLevel;
        const float ox = hero ? f.fuzzHeroX : f.fuzzFieldX;
        const float oy = hero ? f.fuzzHeroY : f.fuzzFieldY;
        const float oz = hero ? f.fuzzHeroZ : f.fuzzFieldZ;
        const float noise = smp.noise((p.x + ox) * f.fuzzScale, (p.y + oy) * f.fuzzScale,
                                      (p.z + oz) * f.fuzzScale);
        n = styleErode(f, n, noise * fuzz);
    }
    return styleSigma(f, n);
}

// THE CUMULUS ALONG ONE RAY, from the eye to tMax: what it sends back (before the air in front
// of it), what it lets through, and the distance its light comes from on average.
template <class S>
MT_DEVICE void styleMarch(const StylizedFrame& f, const S& smp, Vec3 ro, Vec3 rd, float tMax,
                          float pixelAngle, Vec3& C, float& T, float& tMean) {
    C = vec3(0.0f, 0.0f, 0.0f);
    T = 1.0f;
    tMean = 0.0f;
    if (!f.anyCloud) return;

    float t0 = 1e30f, t1 = -1.0f;
    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        float a, b;
        if (!styleBoxRange(L.loX, L.loY, L.loZ, L.hiX, L.hiY, L.hiZ, ro, rd, a, b)) continue;
        t0 = a < t0 ? a : t0;
        t1 = b > t1 ? b : t1;
    }
    if (t0 < 0.0f) t0 = 0.0f;
    if (t1 > tMax) t1 = tMax;
    if (!(t1 > t0)) return;

    // THE PHASE PER OCTAVE depends only on the ray, so it is worked out once.
    const Vec3  sun  = vec3(f.sunX, f.sunY, f.sunZ);
    const float cosT = dot(rd, sun);
    float ph[4];
    {
        float g = 1.0f;
        for (int i = 0; i < 4; ++i) {
            ph[i] = f.wForward * styleHg(f.gForward * g, cosT) +
                    (1.0f - f.wForward) * styleHg(f.gBack * g, cosT);
            g *= f.msC;
        }
    }
    const int octaves = f.msOctaves < 1 ? 1 : (f.msOctaves > 4 ? 4 : f.msOctaves);

    float wSum = 0.0f, tSum = 0.0f;
    float t = t0;
    float tEmpty = t0;        // the last point known to be clear of cloud
    bool  inside = false;     // the last sample was cloud
    for (int it = 0; it < kStyleMarchIterations && t < t1; ++it) {
        const Vec3 p = ro + rd * t;
        int k = styleFinest(f, p);
        if (k < 0) k = styleLevelAlong(f, ro, rd, t);
        if (k < 0) {
            // In no box's range, so the next entry lies strictly ahead and the ray moves on.
            const float e = styleNextEntry(f, ro, rd, t);
            if (!(e < t1)) break;
            t = e + 1e-3f;
            tEmpty = t;
            inside = false;
            continue;
        }
        const StyleLevel& L = f.level[k];
        const float dt = f.stepScale * L.cell;

        float x, y, z;
        styleVoxelCoords(L, p, x, y, z);

        // EMPTY BLOCKS ARE CROSSED IN ONE STEP.
        int bx = static_cast<int>(x) / kStyleBlock, by = static_cast<int>(y) / kStyleBlock,
            bz = static_cast<int>(z) / kStyleBlock;
        bx = bx < 0 ? 0 : (bx >= L.bx ? L.bx - 1 : bx);
        by = by < 0 ? 0 : (by >= L.by ? L.by - 1 : by);
        bz = bz < 0 ? 0 : (bz >= L.bz ? L.bz - 1 : bz);
        if (!smp.occupied(L.blockOffset + (static_cast<long long>(bz) * L.by + by) * L.bx + bx)) {
            const float side = kStyleBlock * L.cell;
            const float lx = L.loX + bx * side, ly = L.loY + by * side, lz = L.loZ + bz * side;
            float a, b;
            if (styleBoxRange(lx, ly, lz, lx + side, ly + side, lz + side, ro, rd, a, b) && b > t) {
                t = b + 1e-3f * L.cell;
            } else {
                t += dt;
            }
            tEmpty = t;
            inside = false;
            continue;
        }

        Style4 v;
        float sigma = styleSigmaAt(f, smp, k, p, v, styleFuzzWeight(f, pixelAngle, t));

        // THE SURFACE, FOUND BY BISECTION between the last clear point and this one, so every ray
        // enters the cloud where the cloud is and not where its step happened to land. Without
        // it, neighbouring rays enter a step apart and a far cloud's surface comes out speckled.
        if (sigma > 0.0f && !inside) {
            float lo = tEmpty, hi = t;
            for (int b = 0; b < 5; ++b) {
                const float mid = 0.5f * (lo + hi);
                const Vec3  q   = ro + rd * mid;
                const int   kq  = styleFinest(f, q);
                Style4 vq;
                if (kq >= 0 && styleSigmaAt(f, smp, kq, q, vq, styleFuzzWeight(f, pixelAngle, mid)) > 0.0f) {
                    hi = mid;
                } else {
                    lo = mid;
                }
            }
            if (hi < t) {
                t = hi;
                const Vec3 q = ro + rd * t;
                const int kq = styleFinest(f, q);
                if (kq >= 0) sigma = styleSigmaAt(f, smp, kq, q, v, styleFuzzWeight(f, pixelAngle, t));
            }
        }
        inside = sigma > 0.0f;
        if (!inside) tEmpty = t;
        if (sigma > 0.0f) {
            float sunL = 0.0f, a = 1.0f, b = 1.0f;
            for (int i = 0; i < octaves; ++i) {
                sunL += a * ph[i] * expf(-b * v.y * f.lightScale);
                a *= f.msA;
                b *= f.msB;
            }
            // THE SKYLIGHT: from above through the cloud over the point, and round the dome's
            // sides through the shallower of its two columns; and the ground's from below.
            const float side = expf(-f.aoK * (v.z < v.w ? v.z : v.w));
            const float up = styleMix(expf(-f.aoK * v.z), side, f.sideSky);
            const float down = expf(-f.aoK * v.w) * f.groundBounce;
            const float sg = sunL * f.sunGain, kg = f.skyGain;
            const Vec3 src = vec3(
                (f.sunR * sg + (f.skyR * up + f.gndR * down) * f.tintR * kg) * f.gain,
                (f.sunG * sg + (f.skyG * up + f.gndG * down) * f.tintG * kg) * f.gain,
                (f.sunB * sg + (f.skyB * up + f.gndB * down) * f.tintB * kg) * f.gain);
            const float alpha = 1.0f - expf(-sigma * dt);
            const float w = T * alpha;
            C = C + src * w;
            wSum += w;
            tSum += w * t;
            T *= 1.0f - alpha;
            if (T < kStyleOpaque) break;
        }
        t += dt;
    }
    tMean = wSum > 0.0f ? tSum / wSum : 0.0f;
}

// ---------------------------------------------------------------------------
// One pixel
// ---------------------------------------------------------------------------

// THE PIXEL'S LINEAR COLOUR, PREMULTIPLIED, AND ITS ALPHA. `tGeo` is where a depth pass's
// geometry stops the ray, or kNoSceneGeometry; `hold` says the background is not drawn (a depth
// pass's geometry, or Background Transparent). (u, v) is the pixel's fraction of the buffer's
// maps.
template <class S>
MT_DEVICE void styleShade(const StylizedFrame& f, const S& smp, const float* sky, const float* air,
                          const float* ci, Vec3 ro, Vec3 rd, float tGeo, bool hold,
                          float u, float v, float pixelAngle, Vec3& rgb, float& alpha) {
    const Vec3 sun = vec3(f.sunX, f.sunY, f.sunZ);
    const float cosT = dot(rd, sun);

    // THE CUMULUS.
    Vec3 C;
    float T, tc;
    styleMarch(f, smp, ro, rd, tGeo, pixelAngle, C, T, tc);
    Vec3 cloud = vec3(0.0f, 0.0f, 0.0f);
    if (T < 1.0f) {
        Vec3 in, tr;
        styleAir(f, air, u, v, tc, in, tr);
        cloud = in * (1.0f - T) + tr * C;
    }

    // THE CIRRUS, a veil.
    float tauC, tCi;
    styleCirrus(f, ci, u, v, tauC, tCi);
    float aC = 0.0f;
    Vec3 veil = vec3(0.0f, 0.0f, 0.0f);
    if (tauC > 0.0f && tCi < tGeo) {
        aC = 1.0f - expf(-tauC * f.cirrusGain);
        const float ph = 0.75f * styleHg(f.cirrusG, cosT) + 0.25f * styleHg(-0.15f, cosT);
        const Vec3 s = vec3(f.sunCiR * ph * 2.0f + f.skyR * 0.9f,
                            f.sunCiG * ph * 2.0f + f.skyG * 0.9f,
                            f.sunCiB * ph * 2.0f + f.skyB * 0.9f) * f.gain;
        Vec3 in, tr;
        styleAir(f, air, u, v, tCi, in, tr);
        veil = in * aC + tr * s * aC;
    }

    // THE BACKGROUND.
    Vec3 bg = vec3(0.0f, 0.0f, 0.0f);
    if (!hold && f.skyOn) {
        bg = styleSky(sky, rd);
        if (f.discOn && cosT > f.discCos) bg = bg + vec3(f.discR, f.discG, f.discB);
    }

    // NEARER FIRST. A camera under the cumulus sees it in front of the cirrus.
    if (T >= 1.0f || tCi > tc || aC <= 0.0f) {
        rgb = cloud + (veil + bg * (1.0f - aC)) * T;
    } else {
        rgb = veil + (cloud + bg * T) * (1.0f - aC);
    }
    alpha = hold ? 1.0f - T * (1.0f - aC) : 1.0f;
}

// ---------------------------------------------------------------------------
// The whole pixel job, transform included
// ---------------------------------------------------------------------------

// BUFFER PIXEL (px, py) OF req.dest: the ray, the depth pass, the shade, the output transform,
// written in the destination's channel order. The transform runs here, not in a second pass:
// a stylized frame has no samples to accumulate and nothing to denoise, so its linear colour has
// nowhere else to go.
template <class S>
MT_DEVICE void stylePixel(const RenderRequest& req, const StylizedFrame& f, const S& smp,
                          const float* sky, const float* air, const float* ci, int px, int py) {
    if (px < 0 || py < 0 || px >= req.dest.widthPx || py >= req.dest.heightPx) return;

    const int frameX = px + req.view.originX;
    const int frameY = py + req.view.originY;
    const Vec3 dir = primaryRayDirection(req.view, px, py, 0.0f, 0.0f);
    const Vec3 ro  = primaryRayOrigin(req.view);

    float tGeo = kNoSceneGeometry;
    if (req.sceneBuffer != nullptr) {
        const unsigned int h = hashPixelSample(frameX, frameY, 0, req.field.seed);
        tGeo = sceneGeometryAlong(req, static_cast<float>(frameX) + 0.5f,
                                  static_cast<float>(frameY) + 0.5f, dir, h);
    }
    const bool hold = tGeo < kNoSceneGeometry || req.view.transparentSky;

    const float u = styleMapU(f, static_cast<float>(frameX) + 0.5f);
    const float v = styleMapV(f, static_cast<float>(frameY) + 0.5f);

    Vec3 rgb;
    float alpha;
    const float pixelAngle = 2.0f * tanf(radians(req.view.verticalFovDegrees) * 0.5f) /
                             static_cast<float>(req.view.heightPx > 0 ? req.view.heightPx : 1);
    styleShade(f, smp, sky, air, ci, ro, dir, tGeo, hold, u, v, pixelAngle, rgb, alpha);

    alpha = alpha < 0.0f ? 0.0f : (alpha > 1.0f ? 1.0f : alpha);
    Vec3 out;
    if (alpha >= 1.0f) {
        out = applyOutputTransform(rgb, req.view);
    } else if (alpha > 1e-6f) {
        out = applyOutputTransform(rgb * (1.0f / alpha), req.view) * alpha;
    } else {
        out = vec3(0.0f, 0.0f, 0.0f);
    }

    float* pix = static_cast<float*>(req.dest.data) + (static_cast<long long>(py) * req.dest.pitchPx + px) * 4;
    if (req.dest.order == ChannelOrder::BGRA) {
        pix[0] = out.z; pix[1] = out.y; pix[2] = out.x; pix[3] = alpha;
    } else {
        pix[0] = alpha; pix[1] = out.x; pix[2] = out.y; pix[3] = out.z;
    }
}

} // namespace plugin::kernel
