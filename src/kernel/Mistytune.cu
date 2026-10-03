// The CUDA render path.
//
// A LAUNCH AND NOTHING ELSE. The per-pixel maths is renderPixel() in Shading.h,
// which the CPU reference calls too, so there is no arithmetic in this file that
// could drift from the arithmetic in that one.
//
// ---------------------------------------------------------------------------
// WHY THERE IS A .cu HERE AT ALL WHEN PLAN.md SAYS SLANG.
//
// PLAN.md's "One kernel source" is about the RENDERER: transport, phase
// functions, atmosphere and the six generators, written once in Slang and
// compiled to PTX for CUDA and to Metal for macOS. Hand-maintaining two path
// tracers is the design spec's own named risk, and that decision stands.
//
// This file is the LAUNCH SHIM, which Slang does not replace: something still has
// to own the grid dimensions, the stream, and the error check. It stays small for
// that reason. When the Slang kernel arrives in Phase 2 the body of the launch
// below changes to a PTX module call and the file keeps its shape.
//
// The Slang bet is also not yet proved. PLAN.md says the decision point comes
// before any generator is written, not after six -- so this .cu is the thing that
// makes Phase 1's exit criterion reachable without prejudging Phase 2.
// ---------------------------------------------------------------------------

#include "KernelApi.h"
#include "Shading.h"

#include <cuda_runtime.h>

#include <cstdio>
#include <cstring>

// ---------------------------------------------------------------------------
// The renderer itself, as generated CUDA source
// ---------------------------------------------------------------------------
//
// INCLUDED AS SOURCE, NOT LINKED, and that is what lets this file call into it.
//
// slangc emits every function below an entry point `static` to the translation unit,
// so `renderSample_0` has internal linkage and is unreachable from anywhere else. A
// separate object file would expose only `renderRays`, the compute entry point --
// which is a whole kernel launch, not a function a pixel can call.
//
// Including it here also means nvcc sees the transport and renderPixel together and
// can inline across the seam, which is the difference between a call per sample and
// no call at all.
//
// COMMITTED, AND SLANG IS NEEDED ONLY TO REGENERATE IT. See cmake/Slang.cmake for
// why a shader compiler is not a build dependency of this project, and
// slang.regenerates for the test that stops the committed file drifting.
#include "slang/generated/Render.cu"

// RenderRequest -> the generated structs, member by member. AFTER the generated
// source, because it names those structs; after Shading.h, because it uses Vec3.
#include "SlangBridge.h"

#include "AirMapHost.h"

#include <vector>

namespace plugin::kernel {

namespace {

// The backend's vector constructors, handed to the shared marshalling in SlangBridge.h.
// This is the entire difference between the two backends. HOST AND DEVICE, because the
// host fills a Scene of its own to plan the shadow maps -- see AirMapHost.h.
struct CudaVectors {
    static __host__ __device__ float2 v2(float x, float y) { return make_float2(x, y); }
    static __host__ __device__ float3 v3(float x, float y, float z) {
        return make_float3(x, y, z);
    }
    static __host__ __device__ int3 i3(int x, int y, int z) { return make_int3(x, y, z); }
    static __host__ __device__ int2 i2(int x, int y) { return make_int2(x, y); }
    static __host__ __device__ float4 v4(float x, float y, float z, float w) {
        return make_float4(x, y, z, w);
    }
};

// ONE ERROR SLOT, AND IT IS THREAD-LOCAL.
//
// Under multi-frame rendering several frames are in flight in this process at
// once, so a single shared error string would be overwritten by whichever worker
// happened to fail second -- and the diagnostic would then name the wrong frame.
// thread_local costs nothing here and makes the message trustworthy.
thread_local char g_lastError[256] = { 0 };

void setError(const char* what, cudaError_t code) {
    std::snprintf(g_lastError, sizeof(g_lastError), "%s: %s",
                  what, cudaGetErrorString(code));
}

// 16x16 = 256 threads, matching the AE GPU sample's own choice.
//
// NOT TUNED, and it should not be until Phase 2 measures samples/second on real
// cards -- PLAN.md defers the minimum-GPU question for the same reason. A block
// shape tuned against a placeholder kernel tells you about the placeholder.
constexpr int kBlockX = 16;
constexpr int kBlockY = 16;

int divideRoundUp(int a, int b) { return (a + b - 1) / b; }

// ---------------------------------------------------------------------------
// The device buffer renderCudaToHost renders into, kept between calls.
// ---------------------------------------------------------------------------
//
// IT USED TO BE A cudaMalloc AND A cudaFree PER BAND, and that was the right first
// version: correct, obviously leak-free, and invisible next to a placeholder kernel
// at 0.02 s a frame. It stops being invisible the moment the real transport lands --
// a driver-side allocation is a synchronising call, so it does not merely cost its
// own microseconds, it drains the pipeline every band.
//
// GROW-ONLY, NEVER SHRUNK. A comp renders the same size thousands of times in a row,
// so after the first frame every call is a capacity check and a pointer. Shrinking
// would hand the frees back to exactly the workload that just proved it needs the
// bytes, and 33 MB for a 1920x1080 band is not worth defending on a card that has
// gigabytes.
//
// THREAD_LOCAL, FOR THE SAME REASON THE ERROR SLOT ABOVE IS.
//
// Multi-frame rendering puts several frames in this process at once. One shared
// buffer would need a lock around every launch, which would serialise the workers
// against each other on a resource that is not actually scarce -- and an unlocked
// shared buffer would be two frames writing the same device memory, which is a
// corrupted frame rather than an error. A buffer per rendering thread costs VRAM
// proportional to the workers AE chose, which is the same thing their host-side
// buffers already cost.
struct DeviceScratch {
    void*  mem      = nullptr;
    size_t capacity = 0;

    // FREED WHEN THE THREAD ENDS, and errors here are deliberately ignored.
    //
    // At process teardown the CUDA runtime may already have torn down the context,
    // and cudaFree then reports cudaErrorCudartUnloading. There is nothing to do
    // about it and nobody left to tell: the driver reclaims the allocation with the
    // context regardless. Reporting it would only put a false failure in the log
    // after the last frame anyone cared about.
    ~DeviceScratch() {
        if (mem) cudaFree(mem);
    }

    void* reserve(size_t bytes) {
        if (mem && bytes <= capacity) return mem;

        // Released BEFORE the new request rather than after, so a grow needs the new
        // size free and not the sum of both -- which is the difference between
        // resizing and failing on a card that is nearly full.
        if (mem) {
            cudaFree(mem);
            mem      = nullptr;
            capacity = 0;
        }

        void* p = nullptr;
        const cudaError_t err = cudaMalloc(&p, bytes);
        if (err != cudaSuccess) {
            setError("cudaMalloc", err);
            return nullptr;
        }
        mem      = p;
        capacity = bytes;
        return mem;
    }
};

// TWO BUFFERS, NOT ONE, AND THEY HAVE DIFFERENT LIFETIMES IN THE SAME FRAME.
//
// g_dest is overwritten by every launch and copied straight back to the host. g_accum
// is linear radiance that has to SURVIVE between the launches of one band -- it is
// what makes a sample split possible at all, and reusing one buffer for both would
// destroy the partial sums the next launch is supposed to add to.
//
// Both are grow-only, so within a band the geometry never changes and reserve() keeps
// handing back the same pointer. That is load-bearing: a reallocation mid-band would
// silently discard the samples already accumulated.
thread_local DeviceScratch g_dest;
thread_local DeviceScratch g_accum;

// The drift table, uploaded once per launch.
//
// A THIRD BUFFER FOR 264 BYTES, WHICH LOOKS LIKE OVERKILL AND IS NOT. The table has
// to be memory the kernel can dereference as an array of float2, and there are only
// three ways to give it that:
//
//   * pass it inside RenderRequest and take its address in the kernel -- which
//     materialises a per-thread copy of all 264 bytes in local memory, on every
//     thread of every launch;
//   * a __constant__ array -- which is per-module state, so two frames in flight
//     under multi-frame rendering would overwrite each other's shear profile;
//   * a device buffer, which is this.
//
// The upload is 264 bytes against a path trace, and the allocation happens once per
// thread because DeviceScratch is grow-only.
thread_local DeviceScratch g_drift;

// The transmittance table, uploaded once per launch.
//
// ===========================================================================
// A FOURTH BUFFER, AND THIS ONE IS 196 KB RATHER THAN 264 BYTES -- SO THE "PASS IT
// INSIDE RenderRequest" OPTION IS NOT MERELY WASTEFUL HERE, IT IS ILLEGAL.
//
// The kernel argument block is capped at 4 KB. A 196 KB member would fail the LAUNCH
// as an invalid configuration, on every frame, rather than degrading.
//
// UPLOADED PER LAUNCH RATHER THAN WHEN IT CHANGES, which is a deliberate trade. At
// about 6 GB/s that is roughly 30 microseconds against a launch sized to ~190 ms of
// work -- under two ten-thousandths. Tracking dirtiness would mean a second copy of
// the cache key on this side of the wall and a way to invalidate it when the
// thread-local host cache rebuilds, which is more state than the copy costs.
//
// THE HOST SIDE REBUILDS RARELY, WHICH IS WHERE THE REAL SAVING IS. This uploads
// whatever cachedTransmittanceLut() last built; that function is the one keyed on the
// parameters, and it is the million exp() calls that would actually hurt.
thread_local DeviceScratch g_transmittance;

// ===========================================================================
// THE CLOUDS' SHADOW MAPS, BUILT ON THE DEVICE AND KEPT THERE.
//
// Unlike the two tables above, these are never uploaded: a kernel builds them where the
// render reads them. KEPT BETWEEN CALLS, keyed on everything a column reads (see
// AirMapHost.h), so the bands and sample chunks of one frame build them once. The key
// remembers the pointer too: DeviceScratch frees and reallocates when it grows, and the
// map in the old allocation went with it.
// ===========================================================================
thread_local DeviceScratch              g_airMap;
thread_local std::vector<unsigned char> g_airMapKey;
thread_local void*                      g_airMapBuiltAt = nullptr;

// THE STAGED RENDER'S PATHS AND ITS TWO LISTS OF THE LIVING (build 25), grow-only like the
// rest. See renderStaged below.
thread_local DeviceScratch g_paths;
thread_local DeviceScratch g_pathLists;

// THE PAREIDOLIA MAP, uploaded when its hash moves rather than per launch: a frame is
// dozens of launches and the map is up to a megabyte. The hash is the map's own
// (ShapeMap::hash), and the pointer is remembered for the reason the shadow maps' is.
thread_local DeviceScratch g_shape;
thread_local uint64_t      g_shapeHash     = 0;
thread_local void*         g_shapeUploaded = nullptr;

// THE LOCAL LIGHTS (build 29), uploaded when their hash moves, as the map above is. A frame
// with a flickering bolt moves it every frame, and that is one copy of a few hundred KB.
thread_local DeviceScratch g_lights;
thread_local uint64_t      g_lightsHash     = 0;
thread_local void*         g_lightsUploaded = nullptr;

} // namespace

// ---------------------------------------------------------------------------
// The seam Shading.h declares
// ---------------------------------------------------------------------------

// ONE RAY THROUGH THE SLANG KERNEL. Four lines, and three of them are marshalling.
//
// `__host__ __device__` through MT_DEVICE, because renderPixel is compiled for both
// and this has to follow it. The host arm is never called on this path -- CpuRender
// has its own definition over the C++ backend -- but nvcc still needs it to exist
// for the host compilation of Shading.h.
MT_RENDER Vec3 mistytuneTrace(const RenderRequest& req, Vec3 ro, Vec3 rd,
                              unsigned int seed) {
    Scene_0      scene{};
    PhaseInput_0 phase{};
    fillSlangScene<CudaVectors>(req, scene, phase);

    // THE MAJORANT GRID IS OFF, so gridBound() returns the medium's own majorant
    // without ever indexing this -- see SlangBridge.h for the measurement behind
    // that. It is still given a valid empty descriptor rather than left as stack
    // rubbish, because "never read" is a property of today's code.
    StructuredBuffer<float> bounds;
    bounds.data  = nullptr;
    bounds.count = 0;

    StructuredBuffer<float2> drift;
    drift.data  = static_cast<float2*>(const_cast<void*>(req.driftBuffer));
    drift.count = static_cast<size_t>(cloud::kDriftKnots);

    const float3 radiance = renderSample_0(&scene, &phase, bounds, drift,
                                           make_float3(ro.x, ro.y, ro.z),
                                           make_float3(rd.x, rd.y, rd.z),
                                           seed);

    return vec3(radiance.x, radiance.y, radiance.z);
}

// The kernel. ONE PIXEL PER THREAD, with the bounds check that every AE GPU
// kernel needs: the grid is rounded up to whole blocks, so the last block runs
// threads that are off the end of the buffer.
__global__ void mistytuneKernel(RenderRequest req) {
    const int px = blockIdx.x * blockDim.x + threadIdx.x;
    const int py = blockIdx.y * blockDim.y + threadIdx.y;
    renderPixel(req, px, py);
}

// ---------------------------------------------------------------------------
// The staged render (build 25)
// ---------------------------------------------------------------------------
//
// ===========================================================================
// ONE LAUNCH FOR THE CAMERA RAYS, THEN ONE PER BOUNCE OVER THE PATHS STILL ALIVE.
//
// MEASURED (PROGRESS.md, build 25): in the single kernel a tracking step cost about 8 ns
// on the camera ray and 26 ns in a later bounce. By the third bounce a warp's paths are
// scattered through the cloud and a third of them have ended, and the warp runs at its
// longest path's pace -- with 250 registers a thread, at a quarter of the threads an SM
// can hold. Here each launch does one kind of work, and a bounce launch runs only the paths
// that are still going, gathered into a list by the launch before.
//
// THE SAME BITS AS THE SINGLE KERNEL. Each path is pathBegin and then pathBounce until it
// ends, which is what trace() is; the finish sums a pixel's samples in sample order and
// writes them exactly as renderPixel does. Which thread runs which path, and in what order
// the living are listed, changes nothing a path computes.
// ===========================================================================

// THE PATHS OF A LAUNCH, at most this many at once: 1080p at one sample in one go, 151 MB of
// path state. A launch with more is taken in bands of whole rows.
constexpr long long kMaxStagedPaths = 1ll << 21;
constexpr int       kStagedBlock    = 128;

// The scene and the two tables, marshalled per thread as mistytuneTrace does.
struct StagedScene {
    Scene_0                  scene;
    PhaseInput_0             phase;
    StructuredBuffer<float>  bounds;
    StructuredBuffer<float2> drift;
};

__device__ inline void fillStagedScene(const RenderRequest& req, StagedScene& st) {
    st.scene = Scene_0{};
    st.phase = PhaseInput_0{};
    fillSlangScene<CudaVectors>(req, st.scene, st.phase);
    st.bounds.data  = nullptr;   // the grid is off: see mistytuneTrace
    st.bounds.count = 0;
    st.drift.data   = static_cast<float2*>(const_cast<void*>(req.driftBuffer));
    st.drift.count  = static_cast<size_t>(cloud::kDriftKnots);
}

// A slot in a list of the living, one atomic per group of threads that ask together.
//
// INTRINSICS, NOT cooperative_groups: CUDA 13's header pulls in CCCL, which refuses MSVC's
// traditional preprocessor. The kernels that call this are one-dimensional with blocks a
// multiple of 32, so a thread's lane is its index's low five bits.
__device__ inline int appendLiving(int* counter) {
    const unsigned mask   = __activemask();
    const int      lane   = static_cast<int>(threadIdx.x & 31u);
    const int      leader = __ffs(static_cast<int>(mask)) - 1;
    int base = 0;
    if (lane == leader) base = atomicAdd(counter, __popc(mask));
    base = __shfl_sync(mask, base, leader);
    return base + __popc(mask & ((1u << lane) - 1u));
}

// Every sample of rows [rowStart, rowStart + rows): its camera ray and first bounce. Path i
// is sample s of pixel px of row rowStart + r at i = (r * width + px) * sampleCount + s, so
// a pixel's samples lie together, in order.
__global__ void stagedBeginKernel(RenderRequest req, int rowStart, int rows,
                                  PathState_0* paths, int* living, int* livingCount) {
    const long long i  = static_cast<long long>(blockIdx.x) * blockDim.x + threadIdx.x;
    const int       S  = req.sampleCount;
    const long long perRow = static_cast<long long>(req.dest.widthPx) * S;
    if (i >= perRow * rows) return;

    const int r   = static_cast<int>(i / perRow);
    const int rem = static_cast<int>(i % perRow);
    const int px  = rem / S;
    const int s   = rem % S;
    const int py  = rowStart + r;

    Vec3         dir;
    unsigned int h;
    pixelSampleRay(req, px, py, s, dir, h);
    const Vec3 origin = primaryRayOrigin(req.view);

    StagedScene sc;
    fillStagedScene(req, sc);
    const PathState_0 st = beginSample_0(&sc.scene, &sc.phase, sc.bounds, sc.drift,
                                         make_float3(origin.x, origin.y, origin.z),
                                         make_float3(dir.x, dir.y, dir.z), h);
    paths[i] = st;
    if (st.psAlive_0 != 0) living[appendLiving(livingCount)] = static_cast<int>(i);
}

// One bounce of every path in `in`; the ones still alive after it go to `out`.
__global__ void stagedBounceKernel(RenderRequest req, PathState_0* paths, const int* in,
                                   int count, int* out, int* outCount) {
    const int k = blockIdx.x * blockDim.x + threadIdx.x;
    if (k >= count) return;
    const int i = in[k];

    StagedScene sc;
    fillStagedScene(req, sc);
    PathState_0 st = paths[i];
    pathBounce_0(&sc.scene, &sc.phase, sc.bounds, sc.drift, &st);
    paths[i] = st;
    if (st.psAlive_0 != 0) out[appendLiving(outCount)] = i;
}

// Each pixel of the rows: its samples summed in sample order, then renderPixel's finish.
__global__ void stagedFinishKernel(RenderRequest req, int rowStart, int rows,
                                   const PathState_0* paths) {
    const int px = blockIdx.x * blockDim.x + threadIdx.x;
    const int r  = blockIdx.y * blockDim.y + threadIdx.y;
    if (px >= req.dest.widthPx || r >= rows) return;

    const int       S    = req.sampleCount;
    const long long base = (static_cast<long long>(r) * req.dest.widthPx + px) * S;

    Vec3 sum = vec3(0.0f, 0.0f, 0.0f);
    for (int s = 0; s < S; ++s) {
        const float3 c = paths[base + s].psRadiance_0;
        sum = sum + vec3(c.x, c.y, c.z);
    }
    finishPixel(req, px, rowStart + r, sum);
}

// The output transform over a finished frame. Same shape, same bounds check, and
// the same arithmetic as the CPU pass because both call transformPixel().
__global__ void mistytuneTransformKernel(RenderRequest req) {
    const int px = blockIdx.x * blockDim.x + threadIdx.x;
    const int py = blockIdx.y * blockDim.y + threadIdx.y;
    transformPixel(req, px, py);
}

// One texel's column of a shadow map per thread. See layerMapColumn in AirMapLib.slang.
__global__ void airMapKernel(Medium_0 medium, StructuredBuffer<float2> drift,
                             LayerShadowMap_0 map, RWStructuredBuffer<float> out, int count) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= count) return;
    layerMapColumn_0(&medium, drift, &map, i, out);
}

namespace {

// THE STAGED RENDER'S HOST LOOP. The request is derived and its tables are on the device.
//
// 1 rendered, 0 failed (the error is set), -1 THE PATHS DID NOT FIT: their 151 MB is per
// rendering thread, and several frames in flight on a full card can be refused it. The
// caller then runs the single kernel, which needs none of it and gives the same bits.
int renderStaged(const RenderRequest& work) {
    const int       W = work.dest.widthPx;
    const int       H = work.dest.heightPx;
    const int       S = work.sampleCount > 0 ? work.sampleCount : 0;
    const long long perRow = static_cast<long long>(W) * S;

    int rowsPerBand = H;
    if (perRow > 0 && perRow * H > kMaxStagedPaths)
        rowsPerBand = static_cast<int>(kMaxStagedPaths / perRow) > 0
                    ? static_cast<int>(kMaxStagedPaths / perRow) : 1;
    const long long maxPaths = perRow * rowsPerBand;

    PathState_0* paths = nullptr;
    int*         lists = nullptr;
    if (maxPaths > 0) {
        paths = static_cast<PathState_0*>(
            g_paths.reserve(sizeof(PathState_0) * static_cast<size_t>(maxPaths)));
        // Two lists of path indices, then their two counts.
        if (paths) {
            lists = static_cast<int*>(
                g_pathLists.reserve(sizeof(int) * (2u * static_cast<size_t>(maxPaths) + 2u)));
        }
        if (!paths || !lists) {
            // NOT AN ERROR FOR THE FRAME: clear the failed allocation's status, or the
            // single kernel's launch check would find it and report it as its own.
            cudaGetLastError();
            return -1;
        }
    }
    int* listA  = lists;
    int* listB  = lists ? lists + maxPaths : nullptr;
    int* counts = lists ? lists + 2 * maxPaths : nullptr;

    for (int row0 = 0; row0 < H; row0 += rowsPerBand) {
        const int       rows = rowsPerBand < H - row0 ? rowsPerBand : H - row0;
        const long long n    = perRow * rows;

        if (n > 0) {
            int* in  = listA;
            int* out = listB;
            int* inCount  = counts;
            int* outCount = counts + 1;

            cudaMemsetAsync(inCount, 0, sizeof(int));
            stagedBeginKernel<<<static_cast<unsigned>((n + kStagedBlock - 1) / kStagedBlock),
                                kStagedBlock>>>(work, row0, rows, paths, in, inCount);

            int living = 0;
            cudaError_t err = cudaMemcpy(&living, inCount, sizeof(int), cudaMemcpyDeviceToHost);
            if (err != cudaSuccess) { setError("staged render: first bounce", err); return 0; }

            // pathBounce ends every path at the bounce budget, which is at most the Slang
            // kBounceCeiling of 256; the cap here only bounds the loop for the reader.
            for (int bounce = 1; bounce < 4096 && living > 0; ++bounce) {
                cudaMemsetAsync(outCount, 0, sizeof(int));
                stagedBounceKernel<<<static_cast<unsigned>(divideRoundUp(living, kStagedBlock)),
                                     kStagedBlock>>>(work, paths, in, living, out, outCount);
                err = cudaMemcpy(&living, outCount, sizeof(int), cudaMemcpyDeviceToHost);
                if (err != cudaSuccess) { setError("staged render: bounce", err); return 0; }

                int* t = in; in = out; out = t;
                t = inCount; inCount = outCount; outCount = t;
            }
        }

        const dim3 block(kBlockX, kBlockY, 1);
        const dim3 grid(static_cast<unsigned>(divideRoundUp(W, kBlockX)),
                        static_cast<unsigned>(divideRoundUp(rows, kBlockY)), 1);
        stagedFinishKernel<<<grid, block>>>(work, row0, rows, paths);

        const cudaError_t launchErr = cudaPeekAtLastError();
        if (launchErr != cudaSuccess) {
            setError("staged render launch", cudaGetLastError());
            return 0;
        }
    }
    return 1;
}

// Plans the maps for `work`, builds them when the key has moved, and points the request at
// them. `driftDev` is the drift table already uploaded for this launch.
//
// NO SYNCHRONISE HERE. The build and the render go on the same stream, so the render
// cannot start before the map is written; renderCuda's own synchronise catches a failure
// in either.
bool prepareAirMapsCuda(RenderRequest& work, void* driftDev) {
    Scene_0 scene;
    std::vector<unsigned char> key;
    const AirMapPlan plan = planAirMapsFor<CudaVectors, Scene_0, PhaseInput_0>(work, scene, key);

    work.airMaps      = plan;
    work.airMapBuffer = nullptr;
    if (!plan.on || plan.totalFloats <= 0) return true;

    void* dev = g_airMap.reserve(sizeof(float) * static_cast<size_t>(plan.totalFloats));
    if (!dev) return false;   // reserve() has already set the error

    if (dev != g_airMapBuiltAt || key != g_airMapKey) {
        g_airMapKey.clear();
        g_airMapBuiltAt = nullptr;

        StructuredBuffer<float2> drift;
        drift.data  = static_cast<float2*>(driftDev);
        drift.count = static_cast<size_t>(cloud::kDriftKnots);

        for (int layer = 0; layer < 2; ++layer) {
            const AirMapGeometry& g = plan.layer[layer];
            if (!g.present) continue;

            LayerShadowMap_0 map;
            std::memset(static_cast<void*>(&map), 0, sizeof map);
            fillAirMap<CudaVectors>(g, dev, map);

            RWStructuredBuffer<float> out;
            out.data  = static_cast<float*>(dev) + g.offset;
            out.count = static_cast<size_t>(airMapFloats(g));

            const int texels = g.dimU * g.dimV;
            airMapKernel<<<static_cast<unsigned>(divideRoundUp(texels, 256)), 256>>>(
                layer == 0 ? scene.medium_0 : scene.medium2_0, drift, map, out, texels);

            const cudaError_t err = cudaPeekAtLastError();
            if (err != cudaSuccess) {
                setError("shadow map launch", cudaGetLastError());
                return false;
            }
        }
        g_airMapKey     = key;
        g_airMapBuiltAt = dev;
    }
    work.airMapBuffer = dev;
    return true;
}

} // namespace

bool cudaAvailable() {
    // CACHED, because this is asked on the render path and cudaGetDeviceCount
    // initialises the driver on first call. Static local initialisation is
    // thread-safe in C++11 and later, which matters under MFR.
    static const bool available = [] {
        int count = 0;
        const cudaError_t err = cudaGetDeviceCount(&count);
        if (err != cudaSuccess) {
            // THE TWO CASES WORTH TELLING APART. "No toolkit" cannot reach here at
            // all -- this file would not have compiled -- so a failure here is a
            // driver or device problem: the driver is older than the runtime this
            // was built against, or the device is in a state that refuses work.
            // Both mean "take the CPU path" to the caller and mean different fixes
            // to whoever reads the log.
            setError("cudaGetDeviceCount", err);
            return false;
        }
        return count > 0;
    }();
    return available;
}

const char* deviceDescription() {
    static char description[256] = { 0 };
    static const bool filled = [] {
        int device = 0;
        if (cudaGetDevice(&device) != cudaSuccess) {
            std::snprintf(description, sizeof(description), "no CUDA device");
            return true;
        }
        cudaDeviceProp prop;
        if (cudaGetDeviceProperties(&prop, device) != cudaSuccess) {
            std::snprintf(description, sizeof(description), "CUDA device %d (properties unavailable)", device);
            return true;
        }
        // COMPUTE CAPABILITY AND MEMORY, not just the marketing name. The name
        // alone does not say whether the cubin in this binary covers the card, and
        // "which architectures did we actually ship" is the first question when a
        // user reports a black frame.
        std::snprintf(description, sizeof(description),
                      "%s (sm_%d%d, %zu MB, %d SMs)",
                      prop.name, prop.major, prop.minor,
                      prop.totalGlobalMem / (1024u * 1024u),
                      prop.multiProcessorCount);
        return true;
    }();
    (void)filled;
    return description;
}

bool renderCuda(const RenderRequest& req) {
    if (!cudaAvailable()) return false;
    if (!req.dest.data || req.dest.widthPx <= 0 || req.dest.heightPx <= 0) return false;

    // ---------------------------------------------------------------------
    // The derived half of the request, and the one buffer it needs on the device
    // ---------------------------------------------------------------------
    //
    // DONE HERE RATHER THAN ASKED OF THE CALLER. Three call sites today -- the
    // effect, the CLI and the golden tests -- and the failure mode of a caller that
    // forgets is a majorant of zero, which renders a clear sky rather than an error.
    //
    // A LOCAL COPY, because the caller's struct is const and this fills in five
    // fields and a pointer. renderCudaToHost calls straight through to here, so the
    // derivation happens exactly once per launch either way.
    RenderRequest work = req;
    deriveRenderInputs(work);

    void* driftDev = g_drift.reserve(sizeof(work.drift.xz));
    if (!driftDev) return false;   // reserve() has already set the error

    const cudaError_t driftErr = cudaMemcpy(driftDev, work.drift.xz,
                                            sizeof(work.drift.xz),
                                            cudaMemcpyHostToDevice);
    if (driftErr != cudaSuccess) {
        setError("drift table upload", driftErr);
        return false;
    }
    work.driftBuffer = driftDev;

    // THE TRANSMITTANCE TABLE: HOST POINTER IN, DEVICE POINTER OUT.
    //
    // deriveRenderInputs left the thread-local cache's host pointer in the request.
    // Read it before overwriting -- that is the only copy of where the table is.
    //
    // A NULL TABLE IS NOT A REASON TO FAIL THE LAUNCH, and that is a judgement rather
    // than laziness: the sky reads it, the cloud transport does not, so a missing
    // table costs the atmosphere and not the frame. The kernel's sampler treats a
    // zero count as "no table" and falls back rather than indexing null.
    const void* lutHost = work.transmittanceBuffer;
    if (lutHost) {
        const size_t lutBytes = sizeof(cloud::Real) * static_cast<size_t>(cloud::kTransmittanceFloats);
        void* lutDev = g_transmittance.reserve(lutBytes);
        if (!lutDev) return false;   // reserve() has already set the error

        const cudaError_t lutErr = cudaMemcpy(lutDev, lutHost, lutBytes, cudaMemcpyHostToDevice);
        if (lutErr != cudaSuccess) {
            setError("transmittance table upload", lutErr);
            return false;
        }
        work.transmittanceBuffer = lutDev;
    }

    // THE PAREIDOLIA MAP: HOST POINTER IN, DEVICE POINTER OUT, like the table above -- and
    // BEFORE THE SHADOW MAPS, whose columns read the hero through it.
    if (work.shape.on && work.shapeBuffer) {
        const size_t shapeBytes = sizeof(float) * static_cast<size_t>(work.shape.width) *
                                  static_cast<size_t>(work.shape.height) * 4u;
        void* shapeDev = g_shape.reserve(shapeBytes);
        if (!shapeDev) return false;   // reserve() has already set the error

        if (shapeDev != g_shapeUploaded || work.shapeHash != g_shapeHash) {
            g_shapeUploaded = nullptr;
            const cudaError_t shapeErr = cudaMemcpy(shapeDev, work.shapeBuffer, shapeBytes,
                                                    cudaMemcpyHostToDevice);
            if (shapeErr != cudaSuccess) {
                setError("pareidolia map upload", shapeErr);
                return false;
            }
            g_shapeUploaded = shapeDev;
            g_shapeHash     = work.shapeHash;
        }
        work.shapeBuffer = shapeDev;
    }

    // THE LOCAL LIGHTS: HOST POINTER IN, DEVICE POINTER OUT, like the map above.
    if (work.lightBuffer && work.lightCount > 0 && work.lightFloats > 0) {
        const size_t lightBytes = sizeof(float) * static_cast<size_t>(work.lightFloats);
        void* lightDev = g_lights.reserve(lightBytes);
        if (!lightDev) return false;   // reserve() has already set the error

        if (lightDev != g_lightsUploaded || work.lightHash != g_lightsHash) {
            g_lightsUploaded = nullptr;
            const cudaError_t lightErr = cudaMemcpy(lightDev, work.lightBuffer, lightBytes,
                                                    cudaMemcpyHostToDevice);
            if (lightErr != cudaSuccess) {
                setError("local lights upload", lightErr);
                return false;
            }
            g_lightsUploaded = lightDev;
            g_lightsHash     = work.lightHash;
        }
        work.lightBuffer = lightDev;
    }

    // THE CLOUDS' SHADOW MAPS, built on this device at most once per change. See
    // AirMapLib.slang for what they are and AirMapHost.h for the key.
    if (!prepareAirMapsCuda(work, driftDev)) return false;

    const dim3 block(kBlockX, kBlockY, 1);
    const dim3 grid(static_cast<unsigned>(divideRoundUp(req.dest.widthPx,  kBlockX)),
                    static_cast<unsigned>(divideRoundUp(req.dest.heightPx, kBlockY)),
                    1);

    // THE REQUEST GOES BY VALUE, as a kernel argument.
    //
    // It is a plain aggregate of scalars and two pointers, a few hundred bytes,
    // which is inside the 4 KB constant-bank limit for kernel parameters -- so it
    // needs no device allocation, no copy, and no lifetime to manage. That is much
    // of the reason RenderRequest is built the way it is.
    const int staged = work.stagedGpu ? renderStaged(work) : -1;
    if (staged == 0) return false;
    if (staged < 0) {
        mistytuneKernel<<<grid, block>>>(work);   // the derived copy, not the caller's
    }

    // PEEK, NOT GET: cudaGetLastError CLEARS the error, and the caller is about to
    // ask for it. This checks that the launch was accepted -- an invalid
    // configuration, or a struct too big for the parameter space.
    const cudaError_t launchErr = cudaPeekAtLastError();
    if (launchErr != cudaSuccess) {
        setError("kernel launch", cudaGetLastError());
        return false;
    }

    // ---------------------------------------------------------------------
    // SYNCHRONISE, AND KNOW WHY.
    //
    // AE hands us a GPU world and takes it back when SMART_RENDER_GPU returns, so
    // the write has to have landed by then. The AE GPU sample synchronises for the
    // same reason.
    //
    // THIS IS ALSO WHERE THE WINDOWS TDR SHOWS UP. The display driver's timeout is
    // about two seconds, and a full-quality frame in ONE launch sits exactly on it
    // -- the failure is a driver reset, not a slow render. Which is why the
    // renderer is chunked at the sample level (req.firstSample / sampleCount) and
    // the host loops: one launch per batch, each well under the timeout, with the
    // accumulator persisting between them.
    //
    // A cudaErrorLaunchTimeout here is therefore not a bug in the kernel. It means
    // the batch size is too large for this card, and the host's response is to
    // reduce it rather than to fail the frame.
    // ---------------------------------------------------------------------
    const cudaError_t syncErr = cudaDeviceSynchronize();
    if (syncErr != cudaSuccess) {
        setError("kernel execution", syncErr);
        return false;
    }

    return true;
}

// ===========================================================================
// NO deriveRenderInputs, NO DRIFT UPLOAD, NO ACCUMULATOR. This pass reads req.view
// and req.dest and nothing else, so the whole setup renderCuda does above is dead
// weight here -- and copying it would put a second drift upload on the frame for a
// kernel that never looks at the table.
//
// IT IS THE ONLY PLACE THE TRANSFORM RUNS ON THE DEVICE. Everything else finishes in
// host memory and uses transformCpu, including renderCudaToHost's output; this exists
// for the AE GPU path, whose destination is a pointer PF_GPUDeviceSuite1 handed us.
// ===========================================================================
bool transformCuda(const RenderRequest& req) {
    if (!cudaAvailable()) return false;
    if (!req.dest.data || req.dest.widthPx <= 0 || req.dest.heightPx <= 0) return false;

    const dim3 block(kBlockX, kBlockY, 1);
    const dim3 grid(static_cast<unsigned>(divideRoundUp(req.dest.widthPx,  kBlockX)),
                    static_cast<unsigned>(divideRoundUp(req.dest.heightPx, kBlockY)),
                    1);

    mistytuneTransformKernel<<<grid, block>>>(req);

    const cudaError_t launchErr = cudaPeekAtLastError();
    if (launchErr != cudaSuccess) {
        setError("transform kernel launch", cudaGetLastError());
        return false;
    }

    // SYNCHRONISED FOR THE SAME REASON THE RENDER IS: AE takes its GPU world back
    // when SMART_RENDER_GPU returns, so the write has to have landed. There is no TDR
    // question here -- the pass is one cheap operation per pixel, not a path trace.
    const cudaError_t syncErr = cudaDeviceSynchronize();
    if (syncErr != cudaSuccess) {
        setError("transform kernel execution", syncErr);
        return false;
    }

    return true;
}

bool renderCudaToHost(const RenderRequest& req, int rowBegin, int rowEnd) {
    if (!cudaAvailable()) return false;
    if (!req.dest.data || req.dest.widthPx <= 0 || req.dest.heightPx <= 0) return false;

    if (rowBegin < 0) rowBegin = 0;
    if (rowEnd <= 0 || rowEnd > req.dest.heightPx) rowEnd = req.dest.heightPx;
    if (rowBegin >= rowEnd) return true;   // nothing asked for is not a failure

    const int bandRows = rowEnd - rowBegin;

    // THE DEVICE BUFFER IS THE SAME SHAPE AS THE HOST ONE, PADDING INCLUDED.
    //
    // Allocating width*4 floats per row instead would be smaller and would force a
    // row-by-row copy to put it back into a padded destination. Matching the pitch
    // makes the copy one linear block, and -- more to the point -- means the kernel
    // sees the IDENTICAL Surface layout on both paths, so a pitch bug cannot hide
    // on one of them.
    const int pitchPx = req.dest.pitchPx > 0 ? req.dest.pitchPx : req.dest.widthPx;
    const size_t rowBytes = static_cast<size_t>(pitchPx) * 4u * sizeof(float);
    const size_t bytes    = rowBytes * static_cast<size_t>(bandRows);

    // THE BUFFER OUTLIVES THE CALL -- see DeviceScratch above. Nothing here frees it,
    // and that is not a leak: it is owned by this thread and released when the thread
    // ends. The failure path below therefore does NOT free either, because a later
    // band on this thread will want the same bytes.
    void* devMem = g_dest.reserve(bytes);
    if (!devMem) return false;   // reserve() has already set the error

    RenderRequest devReq = req;
    devReq.dest.data     = devMem;
    devReq.dest.pitchPx  = pitchPx;
    devReq.dest.heightPx = bandRows;

    // THE WINDOW MOVES, THE CAMERA DOES NOT. The band buffer's row 0 is frame row
    // (originY + rowBegin), and primaryRayDirection adds originY before dividing by
    // the frame height -- so every ray keeps its true position in the picture while
    // the kernel indexes a buffer that starts at zero. Without this each band would
    // render the TOP of the frame into a different part of the output.
    //
    // AT DRAFT'S PIXEL STRIDE A BUFFER ROW IS `stride` FRAME ROWS, so the band moves that much
    // further down the frame. One is the line as it always was.
    devReq.view.originY = req.view.originY + rowBegin * pixelStrideOf(req);

    // THE ACCUMULATOR IS CARRIED ACROSS THE LAUNCHES OF ONE BAND, and this function
    // owns it so that no caller has to hold device memory to get a sample split.
    //
    // ASKED FOR ONLY WHEN THE REQUEST IS ACTUALLY SPLIT. A single-launch band has
    // nothing to carry, and renderPixel's no-accumulator branch divides its own sum
    // once -- which is bit-for-bit what this path did before accumulation existed.
    // Allocating a second 33 MB buffer to hold one launch's partial sums would cost
    // bandwidth and VRAM to reproduce a number we already have.
    //
    // THE HOST DECIDES WHERE THE BOUNDARIES ARE, through firstSample / sampleCount /
    // samplesAlreadyDone in the request -- see samplesPerLaunch() in KernelApi.h for
    // why that decision may not depend on the band, the thread count, or a clock.
    // renderPixel treats samplesAlreadyDone <= 0 as "initialise", so a band's first
    // launch overwrites whatever the previous band left behind and there is no reset
    // to forget.
    // ===================================================================
    // THE ACCUMULATOR IS FRAME-SIZED AND THE BAND GETS A SLICE OF IT, which is the
    // change that lets a frame be carried across RENDERS and not merely across the
    // launches of one band.
    //
    // IT USED TO BE BAND-SIZED -- rowBytes * bandRows -- so each band overwrote the
    // last and there was nothing left to carry. A FieldCache that promised
    // "accumulate onto what is already there" would have been describing a buffer
    // that no longer held it.
    //
    // THE WHOLE FIX IS A POINTER OFFSET, AND THAT IS DELIBERATE. renderPixel indexes
    // the accumulator with the BAND-LOCAL py it already uses; handing it a base that
    // starts at the band's first row maps that onto the frame without a single new
    // index expression in the kernel. Teaching renderPixel a frame-relative row
    // instead would be the band-as-window arithmetic this project has got wrong three
    // times -- the reduced-resolution render that drew the top-left third, the Region
    // of Interest that drew the top-left corner, and the band offset in this very
    // function. Each of those rendered a plausible picture.
    //
    // SO THE KERNEL IS UNCHANGED AND determinism.gpuBands IS THE CHECK: the same
    // frame rendered in one band and in many must stay byte-identical.
    // ===================================================================
    const size_t frameBytes = rowBytes * static_cast<size_t>(req.dest.heightPx);

    const bool split = req.samplesAlreadyDone > 0 || req.sampleCount < req.quality.samplesPerPixel;
    if (split) {
        void* accMem = g_accum.reserve(frameBytes);
        if (!accMem) return false;
        devReq.accumulator        = static_cast<float*>(accMem)
                                  + static_cast<size_t>(rowBegin) * pitchPx * 4u;
        devReq.accumulatorPitchPx = pitchPx;
    } else {
        devReq.accumulator        = nullptr;
        devReq.accumulatorPitchPx = 0;
    }

    // renderCuda has already filled in the error; do not overwrite it with a less
    // specific one, and do not free the scratch -- the next band wants it.
    if (!renderCuda(devReq)) return false;

    // Back into the band's own slice of the host buffer, at the host pitch.
    char* hostBand = static_cast<char*>(req.dest.data)
                   + static_cast<size_t>(rowBegin) * rowBytes;

    // ONLY THE BAND'S BYTES, NOT THE BUFFER'S CAPACITY. The scratch is grow-only, so
    // after a large frame it is routinely bigger than the band being copied -- and
    // copying `capacity` would run off the end of the host buffer.
    const cudaError_t err = cudaMemcpy(hostBand, devMem, bytes, cudaMemcpyDeviceToHost);

    if (err != cudaSuccess) {
        setError("cudaMemcpy device->host", err);
        return false;
    }
    return true;
}

float* reserveDeviceAccumulator(int pitchPx, int heightPx) {
    if (!cudaAvailable()) return nullptr;
    if (pitchPx <= 0 || heightPx <= 0) return nullptr;

    // SHARES g_accum WITH renderCudaToHost, WHICH IS SAFE ONLY BECAUSE THE TWO ARE
    // NEVER IN FLIGHT TOGETHER: a frame is rendered by one command or the other, and
    // within a thread the calls do not interleave. If a future path ever used both,
    // this needs its own scratch -- the failure would be one frame's partial sums
    // landing in the other's accumulator.
    const size_t bytes = static_cast<size_t>(pitchPx) * 4u * sizeof(float)
                       * static_cast<size_t>(heightPx);
    return static_cast<float*>(g_accum.reserve(bytes));
}

const char* lastCudaError() {
    // CLEARED BY READING, so a stale message from three frames ago cannot be
    // reported as the cause of a fresh failure.
    static thread_local char out[256];
    std::memcpy(out, g_lastError, sizeof(out));
    g_lastError[0] = '\0';
    return out;
}

} // namespace plugin::kernel
