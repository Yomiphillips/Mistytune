// THE STYLIZED LOOK ON THE CPU (build 32): the light and the march over host memory.
//
// THE SAME ARITHMETIC AS THE GPU'S, from StylizedShading.h; only the reads differ. CUDA's
// textures interpolate with nine-bit weights and these with floats, so the two agree closely
// rather than to the bit -- which is all a renderer with no samples to average needs.

#include "StylizedPasses.h"
#include "StylizedPlan.h"
#include "StylizedShading.h"

#include <cmath>
#include <vector>

namespace plugin::kernel {

namespace {

// TRILINEAR OVER A LEVEL, voxel i's centre at i + 0.5, clamped at the edges as CUDA's
// cudaAddressModeClamp is.
struct Corners {
    long long i[8];
    float     w[8];
};

inline void corners(const StyleLevel& L, float x, float y, float z, Corners& c) {
    x -= 0.5f; y -= 0.5f; z -= 0.5f;
    const float fx0 = std::floor(x), fy0 = std::floor(y), fz0 = std::floor(z);
    const float fx = x - fx0, fy = y - fy0, fz = z - fz0;
    const int x0 = static_cast<int>(fx0), y0 = static_cast<int>(fy0), z0 = static_cast<int>(fz0);
    const auto cx = [&](int v) { return v < 0 ? 0 : (v >= L.nx ? L.nx - 1 : v); };
    const auto cy = [&](int v) { return v < 0 ? 0 : (v >= L.ny ? L.ny - 1 : v); };
    const auto cz = [&](int v) { return v < 0 ? 0 : (v >= L.nz ? L.nz - 1 : v); };
    for (int k = 0; k < 8; ++k) {
        const int xi = cx(x0 + (k & 1)), yi = cy(y0 + ((k >> 1) & 1)), zi = cz(z0 + ((k >> 2) & 1));
        c.i[k] = L.voxelOffset + (static_cast<long long>(zi) * L.ny + yi) * L.nx + xi;
        c.w[k] = ((k & 1) ? fx : 1 - fx) * (((k >> 1) & 1) ? fy : 1 - fy) * (((k >> 2) & 1) ? fz : 1 - fz);
    }
}

// The accessors styleColumn and styleBlockFlag read and write through.
struct FloatRaw {
    const float* p;
    float operator()(long long v) const { return p[v]; }
};
struct FloatOut {
    float* p;
    void operator()(long long v, int c, float value) const { p[v * 4 + c] = value; }
};

struct CpuSampler {
    const StylizedFrame* f      = nullptr;
    const float*         raw    = nullptr;
    const float*         packed = nullptr;
    const unsigned char* occ    = nullptr;
    const float*         noiseTile = nullptr;

    float density(int L, float x, float y, float z) const {
        Corners c;
        corners(f->level[L], x, y, z, c);
        float s = 0.0f;
        for (int k = 0; k < 8; ++k) s += raw[c.i[k]] * c.w[k];
        return s;
    }

    Style4 voxel(int L, float x, float y, float z) const {
        Corners c;
        corners(f->level[L], x, y, z, c);
        Style4 s = { 0.0f, 0.0f, 0.0f, 0.0f };
        for (int k = 0; k < 8; ++k) {
            const float* v = packed + c.i[k] * 4;
            s.x += v[0] * c.w[k]; s.y += v[1] * c.w[k]; s.z += v[2] * c.w[k]; s.w += v[3] * c.w[k];
        }
        return s;
    }

    float noise(float x, float y, float z) const {
        const int N = kStyleNoiseSide;
        x -= 0.5f; y -= 0.5f; z -= 0.5f;
        const float fx0 = std::floor(x), fy0 = std::floor(y), fz0 = std::floor(z);
        const float fx = x - fx0, fy = y - fy0, fz = z - fz0;
        const int x0 = static_cast<int>(fx0), y0 = static_cast<int>(fy0), z0 = static_cast<int>(fz0);
        float s = 0.0f;
        for (int k = 0; k < 8; ++k) {
            const int xi = ((x0 + (k & 1)) % N + N) % N;
            const int yi = ((y0 + ((k >> 1) & 1)) % N + N) % N;
            const int zi = ((z0 + ((k >> 2) & 1)) % N + N) % N;
            const float w = ((k & 1) ? fx : 1 - fx) * (((k >> 1) & 1) ? fy : 1 - fy) * (((k >> 2) & 1) ? fz : 1 - fz);
            s += noiseTile[(static_cast<long long>(zi) * N + yi) * N + xi] * w;
        }
        return s;
    }

    bool occupied(long long b) const { return occ[b] != 0; }
};

} // namespace

void styleLightCpu(const StylizedFrame& f, const float* rawIn, float* packed, unsigned char* occ,
                   int threads) {
    // THE SHAPE PASS: the rounding, one axis at a time. The base's dome is laid on wherever the
    // density is read, not here; see styleBlurVoxel.
    static thread_local std::vector<float> shapedA, shapedB;
    const float* raw = rawIn;
    bool shape = false;
    for (int k = 0; k < kStyleLevels; ++k) {
        if (!f.level[k].present) continue;
        float sigma;
        int radius;
        styleBlurWidth(f, f.level[k], sigma, radius);
        shape = shape || radius > 0;
    }
    if (shape && f.voxels > 0) {
        shapedA.resize(static_cast<size_t>(f.voxels));
        shapedB.resize(static_cast<size_t>(f.voxels));
        for (int k = 0; k < kStyleLevels; ++k) {
            const StyleLevel& L = f.level[k];
            if (!L.present) continue;
            const long long n = styleVoxels(L);
            const FloatRaw in{ rawIn + L.voxelOffset }, ina{ shapedA.data() + L.voxelOffset },
                           inb{ shapedB.data() + L.voxelOffset };
            float* a = shapedA.data() + L.voxelOffset;
            float* b = shapedB.data() + L.voxelOffset;
            styleParallelFor(n, threads, [&](long long v) { a[v] = styleBlurVoxel(f, L, in, v, 0); });
            styleParallelFor(n, threads, [&](long long v) { b[v] = styleBlurVoxel(f, L, ina, v, 1); });
            styleParallelFor(n, threads, [&](long long v) { a[v] = styleBlurVoxel(f, L, inb, v, 2); });
        }
        raw = shapedA.data();
    }

    CpuSampler smp;
    smp.f = &f;
    smp.raw = raw;

    // THE SUN, voxel by voxel.
    styleParallelFor(f.voxels, threads, [&](long long i) {
        int L;
        Vec3 p;
        if (!styleVoxelCentre(f, i, L, p)) return;
        packed[i * 4 + 0] = raw[i];
        packed[i * 4 + 1] = styleSunDepth(f, smp, p);
    });

    // UP AND DOWN, column by column.
    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        const long long cols = static_cast<long long>(L.nx) * L.nz;
        const FloatRaw   in{ raw + L.voxelOffset };
        const FloatOut   out{ packed + L.voxelOffset * 4 };
        styleParallelFor(cols, threads, [&](long long c) {
            styleColumn(f, L, in, out, static_cast<int>(c % L.nx), static_cast<int>(c / L.nx));
        });
        const long long blocks = static_cast<long long>(L.bx) * L.by * L.bz;
        styleParallelFor(blocks, threads, [&](long long b) {
            const int bx = static_cast<int>(b % L.bx);
            const int by = static_cast<int>((b / L.bx) % L.by);
            const int bz = static_cast<int>(b / (static_cast<long long>(L.bx) * L.by));
            occ[L.blockOffset + b] = styleBlockFlag(f, L, in, bx, by, bz);
        });
    }
}

void styleMarchCpu(const RenderRequest& req, const StylizedFrame& f, const float* packed,
                   const unsigned char* occ, const float* sky, const float* air, const float* ci,
                   int threads) {
    CpuSampler smp;
    smp.f = &f;
    smp.packed = packed;
    smp.occ = occ;
    smp.noiseTile = styleNoiseTile().data();

    const int W = req.dest.widthPx;
    styleParallelFor(static_cast<long long>(req.dest.heightPx), threads, [&](long long y) {
        for (int x = 0; x < W; ++x) {
            stylePixel(req, f, smp, sky, air, ci, x, static_cast<int>(y));
        }
    });
}

} // namespace plugin::kernel
