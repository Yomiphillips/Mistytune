// THE STYLIZED LOOK ON THE GPU (build 32): the light and the march.
//
// THE GRIDS ARE HARDWARE TEXTURES. Every step of the march reads one half-float RGBA texel --
// density, the sun's optical depth, the sky's above and the ground's below -- trilinearly
// filtered by the texture unit, and the light's walk towards the sun reads a one-channel density
// texture the same way. That is the whole reason a stylized frame is tens of milliseconds: the
// march costs a filtered fetch per step where the path trace costs a procedural density.
//
// Mistytune.cu bakes the density (it owns the generated renderer that evaluates it) and calls
// styleLightAndMarchCuda with it. This file includes none of the generated code, so tuning the
// look rebuilds this file alone.

#include "StylizedPasses.h"
#include "StylizedPlan.h"
#include "StylizedShading.h"

#include <cuda_fp16.h>
#include <cuda_runtime.h>

namespace plugin::kernel {

namespace {

// Grow-only device memory owned by the calling thread, as Mistytune.cu's DeviceScratch.
struct StyleScratch {
    void*  mem = nullptr;
    size_t capacity = 0;
    ~StyleScratch() { if (mem) cudaFree(mem); }
    void* reserve(size_t bytes) {
        if (mem && bytes <= capacity) return mem;
        if (mem) { cudaFree(mem); mem = nullptr; capacity = 0; }
        void* p = nullptr;
        const cudaError_t err = cudaMalloc(&p, bytes > 0 ? bytes : 1);
        if (err != cudaSuccess) { styleCudaError("stylized cudaMalloc", static_cast<int>(err)); return nullptr; }
        mem = p;
        capacity = bytes;
        return mem;
    }
};

// A 3D ARRAY AND ITS TEXTURE, kept while its size and format hold. A comp renders one size
// thousands of times, and a level's dimensions move only when the camera's view of the cloud does.
struct StyleTexture {
    cudaArray_t         arr = nullptr;
    cudaTextureObject_t tex = 0;
    int nx = 0, ny = 0, nz = 0, channels = 0;

    ~StyleTexture() { release(); }
    void release() {
        if (tex) cudaDestroyTextureObject(tex);
        if (arr) cudaFreeArray(arr);
        tex = 0;
        arr = nullptr;
        nx = ny = nz = channels = 0;
    }

    // Half floats, 1 or 4 channels. NORMALISED AND WRAPPING for the fuzz's tile; voxel
    // coordinates and clamped at the edges for a level.
    bool ensure(int x, int y, int z, int ch, bool tile) {
        if (arr && x == nx && y == ny && z == nz && ch == channels) return true;
        release();
        const cudaChannelFormatDesc desc = ch == 4 ? cudaCreateChannelDescHalf4() : cudaCreateChannelDescHalf();
        cudaError_t err = cudaMalloc3DArray(&arr, &desc, make_cudaExtent(x, y, z));
        if (err != cudaSuccess) { arr = nullptr; styleCudaError("stylized 3D array", static_cast<int>(err)); return false; }

        cudaResourceDesc res = {};
        res.resType = cudaResourceTypeArray;
        res.res.array.array = arr;
        cudaTextureDesc td = {};
        const cudaTextureAddressMode mode = tile ? cudaAddressModeWrap : cudaAddressModeClamp;
        td.addressMode[0] = mode;
        td.addressMode[1] = mode;
        td.addressMode[2] = mode;
        td.filterMode = cudaFilterModeLinear;
        td.readMode = cudaReadModeElementType;
        td.normalizedCoords = tile ? 1 : 0;
        err = cudaCreateTextureObject(&tex, &res, &td, nullptr);
        if (err != cudaSuccess) { tex = 0; release(); styleCudaError("stylized texture", static_cast<int>(err)); return false; }
        nx = x; ny = y; nz = z; channels = ch;
        return true;
    }

    // From linear device memory, `bytesPerVoxel` a voxel, rows of nx.
    bool fill(const void* src, int bytesPerVoxel) {
        cudaMemcpy3DParms p = {};
        p.srcPtr = make_cudaPitchedPtr(const_cast<void*>(src), static_cast<size_t>(nx) * bytesPerVoxel, nx, ny);
        p.dstArray = arr;
        p.extent = make_cudaExtent(nx, ny, nz);
        p.kind = cudaMemcpyDeviceToDevice;
        const cudaError_t err = cudaMemcpy3D(&p);
        if (err != cudaSuccess) { styleCudaError("stylized texture fill", static_cast<int>(err)); return false; }
        return true;
    }
};

thread_local StyleTexture g_densTex[kStyleLevels];
thread_local StyleTexture g_voxTex[kStyleLevels];
thread_local StyleTexture g_noiseTex;
thread_local bool         g_noiseFilled = false;
thread_local StyleScratch g_packed;   // four half floats per voxel
thread_local StyleScratch g_shapeA;   // the shape pass's two halves
thread_local StyleScratch g_shapeB;
thread_local StyleScratch g_occ;      // a byte per block

__device__ inline float halfAt(const unsigned short* p, long long i) {
    return __half2float(__ushort_as_half(p[i]));
}
__device__ inline unsigned short toHalf(float v) {
    return __half_as_ushort(__float2half_rn(v));
}

struct HalfRaw {
    const unsigned short* p;
    __device__ float operator()(long long v) const { return halfAt(p, v); }
};
struct HalfOut {
    unsigned short* p;
    __device__ void operator()(long long v, int c, float value) const { p[v * 4 + c] = toHalf(value); }
};

struct CudaSampler {
    cudaTextureObject_t  dens[kStyleLevels];
    cudaTextureObject_t  vox[kStyleLevels];
    cudaTextureObject_t  noiseTex;
    const unsigned char* occ;

    __device__ float density(int L, float x, float y, float z) const {
        return tex3D<float>(dens[L], x, y, z);
    }
    __device__ Style4 voxel(int L, float x, float y, float z) const {
        const float4 v = tex3D<float4>(vox[L], x, y, z);
        Style4 s;
        s.x = v.x; s.y = v.y; s.z = v.z; s.w = v.w;
        return s;
    }
    __device__ float noise(float x, float y, float z) const {
        const float inv = 1.0f / static_cast<float>(kStyleNoiseSide);
        return tex3D<float>(noiseTex, x * inv, y * inv, z * inv);
    }
    __device__ bool occupied(long long b) const { return occ[b] != 0; }
};

__global__ void styleBlurKernel(StylizedFrame f, int level, int axis,
                                const unsigned short* in, unsigned short* out) {
    const StyleLevel& L = f.level[level];
    const long long v = static_cast<long long>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (v >= static_cast<long long>(L.nx) * L.ny * L.nz) return;
    const HalfRaw src{ in + L.voxelOffset };
    out[L.voxelOffset + v] = toHalf(styleBlurVoxel(f, L, src, v, axis));
}

__global__ void styleBlocksKernel(StylizedFrame f, const unsigned short* raw, unsigned char* occ) {
    const long long b = static_cast<long long>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (b >= f.blocks) return;
    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        const long long n = static_cast<long long>(L.bx) * L.by * L.bz;
        if (b < L.blockOffset || b >= L.blockOffset + n) continue;
        const long long j = b - L.blockOffset;
        const HalfRaw in{ raw + L.voxelOffset };
        occ[b] = styleBlockFlag(f, L, in, static_cast<int>(j % L.bx), static_cast<int>((j / L.bx) % L.by),
                                static_cast<int>(j / (static_cast<long long>(L.bx) * L.by)));
        return;
    }
}

__global__ void styleColumnsKernel(StylizedFrame f, int level, const unsigned short* raw,
                                   unsigned short* packed) {
    const StyleLevel& L = f.level[level];
    const long long c = static_cast<long long>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (c >= static_cast<long long>(L.nx) * L.nz) return;
    const HalfRaw in{ raw + L.voxelOffset };
    const HalfOut out{ packed + L.voxelOffset * 4 };
    styleColumn(f, L, in, out, static_cast<int>(c % L.nx), static_cast<int>(c / L.nx));
}

__global__ void styleSunKernel(StylizedFrame f, CudaSampler smp, const unsigned short* raw,
                               unsigned short* packed) {
    const long long i = static_cast<long long>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (i >= f.voxels) return;
    int L;
    Vec3 p;
    if (!styleVoxelCentre(f, i, L, p)) return;
    packed[i * 4 + 0] = raw[i];
    packed[i * 4 + 1] = toHalf(styleSunDepth(f, smp, p));
}

__global__ void styleMarchKernel(RenderRequest req, StylizedFrame f, CudaSampler smp,
                                 const float* sky, const float* air, const float* ci) {
    const int px = blockIdx.x * blockDim.x + threadIdx.x;
    const int py = blockIdx.y * blockDim.y + threadIdx.y;
    stylePixel(req, f, smp, sky, air, ci, px, py);
}

unsigned int gridFor(long long n, int block) {
    return static_cast<unsigned int>((n + block - 1) / block);
}

bool launched(const char* what) {
    const cudaError_t err = cudaPeekAtLastError();
    if (err != cudaSuccess) { styleCudaError(what, static_cast<int>(cudaGetLastError())); return false; }
    return true;
}

} // namespace

bool styleLightAndMarchCuda(const RenderRequest& req, const StylizedFrame& f,
                            const unsigned short* rawHalf, const float* sky, const float* air,
                            const float* ci, float* ms) {
    cudaEvent_t e0 = nullptr, e1 = nullptr, e2 = nullptr;
    if (ms) { cudaEventCreate(&e0); cudaEventCreate(&e1); cudaEventCreate(&e2); cudaEventRecord(e0); }

    // THE FUZZ'S TILE, once per thread.
    if (!g_noiseFilled) {
        const int N = kStyleNoiseSide;
        if (!g_noiseTex.ensure(N, N, N, 1, true)) return false;
        const std::vector<float>& tile = styleNoiseTile();
        std::vector<__half> h(tile.size());
        for (size_t k = 0; k < tile.size(); ++k) h[k] = __float2half_rn(tile[k]);
        cudaMemcpy3DParms p = {};
        p.srcPtr = make_cudaPitchedPtr(h.data(), static_cast<size_t>(N) * sizeof(__half), N, N);
        p.dstArray = g_noiseTex.arr;
        p.extent = make_cudaExtent(N, N, N);
        p.kind = cudaMemcpyHostToDevice;
        const cudaError_t err = cudaMemcpy3D(&p);
        if (err != cudaSuccess) { styleCudaError("stylized noise upload", static_cast<int>(err)); return false; }
        g_noiseFilled = true;
    }

    CudaSampler smp = {};
    smp.noiseTex = g_noiseTex.tex;

    if (f.anyCloud && f.voxels > 0) {
        // THE SHAPE PASS: the rounding, one axis at a time. The base's dome is laid on wherever
        // the density is read, not here; see styleBlurVoxel. What it leaves stands in for the
        // bake from here on.
        bool shape = false;
        for (int k = 0; k < kStyleLevels; ++k) {
            if (!f.level[k].present) continue;
            float sigma;
            int radius;
            styleBlurWidth(f, f.level[k], sigma, radius);
            shape = shape || radius > 0;
        }
        if (shape) {
            unsigned short* a = static_cast<unsigned short*>(g_shapeA.reserve(static_cast<size_t>(f.voxels) * 2u));
            unsigned short* b = static_cast<unsigned short*>(g_shapeB.reserve(static_cast<size_t>(f.voxels) * 2u));
            if (!a || !b) return false;
            for (int k = 0; k < kStyleLevels; ++k) {
                const StyleLevel& L = f.level[k];
                if (!L.present) continue;
                const unsigned int g = gridFor(styleVoxels(L), 256);
                styleBlurKernel<<<g, 256>>>(f, k, 0, rawHalf, a);
                styleBlurKernel<<<g, 256>>>(f, k, 1, a, b);
                styleBlurKernel<<<g, 256>>>(f, k, 2, b, a);
                if (!launched("stylized shape")) return false;
            }
            rawHalf = a;
        }

        unsigned short* packed = static_cast<unsigned short*>(g_packed.reserve(static_cast<size_t>(f.voxels) * 8u));
        unsigned char*  occ    = static_cast<unsigned char*>(g_occ.reserve(static_cast<size_t>(f.blocks)));
        if (!packed || !occ) return false;

        // THE DENSITY AS A TEXTURE, for the light's walk.
        for (int k = 0; k < kStyleLevels; ++k) {
            const StyleLevel& L = f.level[k];
            if (!L.present) continue;
            if (!g_densTex[k].ensure(L.nx, L.ny, L.nz, 1, false)) return false;
            if (!g_densTex[k].fill(rawHalf + L.voxelOffset, 2)) return false;
            smp.dens[k] = g_densTex[k].tex;
        }

        styleBlocksKernel<<<gridFor(f.blocks, 256), 256>>>(f, rawHalf, occ);
        if (!launched("stylized blocks")) return false;
        for (int k = 0; k < kStyleLevels; ++k) {
            const StyleLevel& L = f.level[k];
            if (!L.present) continue;
            styleColumnsKernel<<<gridFor(static_cast<long long>(L.nx) * L.nz, 128), 128>>>(f, k, rawHalf, packed);
            if (!launched("stylized columns")) return false;
        }
        styleSunKernel<<<gridFor(f.voxels, 128), 128>>>(f, smp, rawHalf, packed);
        if (!launched("stylized sun")) return false;

        // THE PACKED VOXELS AS TEXTURES, for the march.
        for (int k = 0; k < kStyleLevels; ++k) {
            const StyleLevel& L = f.level[k];
            if (!L.present) continue;
            if (!g_voxTex[k].ensure(L.nx, L.ny, L.nz, 4, false)) return false;
            if (!g_voxTex[k].fill(packed + L.voxelOffset * 4, 8)) return false;
            smp.vox[k] = g_voxTex[k].tex;
        }
        smp.occ = occ;
    }
    if (ms) cudaEventRecord(e1);

    const dim3 block(16, 8, 1);
    const dim3 grid(gridFor(req.dest.widthPx, 16), gridFor(req.dest.heightPx, 8), 1);
    styleMarchKernel<<<grid, block>>>(req, f, smp, sky, air, ci);
    if (!launched("stylized march")) return false;

    if (ms) {
        cudaEventRecord(e2);
        cudaEventSynchronize(e2);
        cudaEventElapsedTime(&ms[0], e0, e1);
        cudaEventElapsedTime(&ms[1], e1, e2);
        cudaEventDestroy(e0); cudaEventDestroy(e1); cudaEventDestroy(e2);
    }
    const cudaError_t err = cudaDeviceSynchronize();
    if (err != cudaSuccess) { styleCudaError("stylized execution", static_cast<int>(err)); return false; }
    return true;
}

} // namespace plugin::kernel
