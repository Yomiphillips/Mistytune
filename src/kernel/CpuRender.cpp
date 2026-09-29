// The CPU render path.
//
// NOT A SECOND RENDERER. It calls renderPixel() out of Shading.h, the same
// function the CUDA kernel calls, so this file is a loop and a thread pool and
// nothing else. That is what makes a golden image taken here a meaningful check on
// the GPU: a divergence is a divergence in the compiler or the flags, never in
// somebody's second attempt at the maths.
//
// WHAT IT IS FOR, in order of how much it matters:
//
//   1. The correctness reference for tests/golden/.
//   2. The path AE takes at 8 and 16 bpc, and whenever the GPU is unavailable.
//   3. Somewhere to run under a debugger, which a kernel is not.
//
// WHAT IT IS NOT is a shipping renderer. A real path trace at comp resolution on a
// CPU is minutes per frame.

#include "KernelApi.h"
#include "Shading.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <thread>
#include <vector>

// ---------------------------------------------------------------------------
// The renderer itself, as generated C++ source
// ---------------------------------------------------------------------------
//
// THE SAME .slang THE CUDA PATH COMPILES, through `-target cpp`. RenderLib.slang is
// one file; Render.slang and RenderCpu.slang are two entry points over it, and they
// differ only in their names because slangc marks entry points `extern "C"` and both
// generated objects end up in this one library. See Render.slang's header.
//
// INSIDE A NAMESPACE, so the generated helpers -- `clamp_0`, `dot_1`, `Vector` --
// cannot collide with anything in this file or in Shading.h. The entry point itself
// escapes the namespace because `extern "C"` ignores namespaces, which is exactly
// why it needed its own name in the first place.
//
// <cmath> AND <cstdint> ARE INCLUDED ABOVE, AT GLOBAL SCOPE, DELIBERATELY. The
// prelude includes them, and a standard header first seen from inside a namespace
// puts the entire C library in that namespace. Pulling them in first makes the
// prelude's own includes no-ops.
namespace mistytune_cpu_backend {
#include "slang/generated/RenderCpu.cpp"
}

// RenderRequest -> the generated structs, member by member. The SAME template the
// CUDA path uses; only the vector constructors below differ.
#include "SlangBridge.h"

namespace plugin::kernel {

// ---------------------------------------------------------------------------
// The seam Shading.h declares
// ---------------------------------------------------------------------------
//
// THE TWIN OF THE ONE IN Mistytune.cu, and the resemblance is the point: if these two
// ever stop agreeing, slang.cpuParity is what says so, and tests/golden/ is what
// stops a CPU reference certifying a GPU render it no longer matches.
MT_RENDER Vec3 mistytuneTrace(const RenderRequest& req, Vec3 ro, Vec3 rd,
                              unsigned int seed) {
    namespace be = mistytune_cpu_backend;

    struct CpuVectors {
        static be::Vector<float, 2> v2(float x, float y) {
            be::Vector<float, 2> v; v.x = x; v.y = y; return v;
        }
        static be::Vector<float, 3> v3(float x, float y, float z) {
            be::Vector<float, 3> v; v.x = x; v.y = y; v.z = z; return v;
        }
        static be::Vector<int32_t, 3> i3(int x, int y, int z) {
            be::Vector<int32_t, 3> v; v.x = x; v.y = y; v.z = z; return v;
        }
    };

    be::Scene_0      scene{};
    be::PhaseInput_0 phase{};
    fillSlangScene<CpuVectors>(req, scene, phase);

    be::StructuredBuffer<float> bounds;
    bounds.data  = nullptr;
    bounds.count = 0;

    be::StructuredBuffer<be::Vector<float, 2>> drift;
    drift.data = reinterpret_cast<be::Vector<float, 2>*>(
                     const_cast<void*>(req.driftBuffer));
    drift.count = static_cast<size_t>(cloud::kDriftKnots);

    const be::Vector<float, 3> radiance =
        be::renderSample_0(&scene, &phase, bounds, drift,
                           CpuVectors::v3(ro.x, ro.y, ro.z),
                           CpuVectors::v3(rd.x, rd.y, rd.z),
                           seed);

    return vec3(radiance.x, radiance.y, radiance.z);
}

namespace {

// The accumulator, owned by the thread that calls renderCpu.
//
// NOT thread_local INSIDE THE WORKERS, which is the trap here. renderCpu fans a band
// out across a pool, and every worker writes into the SAME accumulator -- safely,
// because they own disjoint rows. A per-worker buffer would give each of them its own
// partial sums to throw away, and the image would be whichever worker wrote last.
//
// FULL FRAME, NOT BAND-SIZED, unlike the GPU's. renderPixel indexes the accumulator
// with the same py it uses for the destination, and on this path the destination is
// the whole frame rather than a band window -- so the two have to be the same shape
// or the rows land on top of each other.
//
// Grow-only, for the reason the device buffer is: a comp renders one size over and
// over. It is released when the calling thread ends.
thread_local std::vector<float> g_accum;

float* reserveAccumulator(size_t floats) {
    if (g_accum.size() < floats) g_accum.resize(floats);
    return g_accum.data();
}

} // namespace

void renderCpu(const RenderRequest& req, int threads, int rowBegin, int rowEnd) {
    if (!req.dest.data || req.dest.widthPx <= 0 || req.dest.heightPx <= 0) return;

    // THE ROW WINDOW, CLAMPED HERE rather than trusted. rowEnd <= 0 means "to the
    // bottom", which keeps the CLI and the golden tests calling this unchanged.
    if (rowBegin < 0) rowBegin = 0;
    if (rowEnd <= 0 || rowEnd > req.dest.heightPx) rowEnd = req.dest.heightPx;
    if (rowBegin >= rowEnd) return;

    const int height = rowEnd - rowBegin;

    // ROWS ACROSS THREADS, AT THE MACHINE'S FULL WIDTH.
    //
    // THIS WAS CAPPED AT FOUR, and the cap was justified by a claim that turned out
    // to be false when someone finally measured it. The claim was that because AE
    // runs several frames at once under multi-frame rendering, a full-width pool per
    // frame would oversubscribe the machine "badly enough to be slower than single
    // threaded".
    //
    // MEASURED on an 8-core/16-thread i7-10700K, 960x540 at 8 samples, comparing a
    // 4-thread pool against a 16-thread pool with N renders running concurrently:
    //
    //     concurrent frames    4 threads each    16 threads each
    //     1  (interactive)         6.55 s            2.04 s
    //     4  (MFR)                 8.13 s            7.99 s
    //     8  (MFR)                16.82 s           15.99 s
    //
    // Oversubscription costs NOTHING -- the OS scheduler absorbs it, and the wide
    // pool is marginally faster even at eight concurrent frames. The cap bought no
    // throughput under the case it was written for and cost 3.2x on the case that
    // actually hurts, which is a user waiting on one interactive frame.
    //
    // IT IS STILL NOT THE RIGHT ANSWER. AE's own threading suite is, because it
    // knows the host's budget rather than guessing it from the hardware, and it
    // lands with the rest of the Phase 2 host work. What changed here is only that
    // the guess is no longer contradicted by its own measurement.
    if (threads <= 0) {
        unsigned int want = std::thread::hardware_concurrency();
        if (want == 0) want = 1;
        threads = static_cast<int>(want);
    }
    if (threads > height) threads = height > 0 ? height : 1;

    // THE ACCUMULATOR IS ATTACHED ONLY WHEN THE REQUEST IS ACTUALLY SPLIT, exactly as
    // on the CUDA path, and for the same two reasons: an unsplit render has nothing to
    // carry, and renderPixel's no-accumulator branch is bit-for-bit what this function
    // produced before accumulation existed. The golden references were taken that way.
    //
    // A LOCAL COPY OF THE REQUEST, because the accumulator pointer belongs to this
    // call and the caller's struct is const. The workers capture this one.
    RenderRequest work = req;

    // The derived half of the request, exactly as renderCuda does it and for the
    // same reason: no caller can forget, because no caller is asked.
    //
    // THE DRIFT BUFFER IS THE TABLE ITSELF HERE. There is no device to cross, so the
    // kernel reads `work.drift.xz` in place -- which is why that array is interleaved
    // and eight-byte aligned rather than two tidy parallel ones. See IceField.h.
    deriveRenderInputs(work);
    work.driftBuffer = work.drift.xz;

    const bool split = req.samplesAlreadyDone > 0 || req.sampleCount < req.quality.samplesPerPixel;
    if (split) {
        const int pitchPx = req.dest.pitchPx > 0 ? req.dest.pitchPx : req.dest.widthPx;
        const size_t floats = static_cast<size_t>(pitchPx) * 4u
                            * static_cast<size_t>(req.dest.heightPx);
        work.accumulator        = reserveAccumulator(floats);
        work.accumulatorPitchPx = pitchPx;
    } else {
        work.accumulator        = nullptr;
        work.accumulatorPitchPx = 0;
    }

    const auto renderRows = [&work](int y0, int y1) {
        for (int y = y0; y < y1; ++y) {
            for (int x = 0; x < work.dest.widthPx; ++x) {
                renderPixel(work, x, y);
            }
        }
    };

    if (threads <= 1) {
        renderRows(rowBegin, rowEnd);
        return;
    }

    std::vector<std::thread> pool;
    pool.reserve(static_cast<size_t>(threads));

    // CONTIGUOUS BANDS, NOT INTERLEAVED ROWS. Each thread writes a run of whole
    // rows, so two threads never touch the same cache line -- and more to the
    // point, the accumulator writes stay deterministic regardless of how the bands
    // are scheduled, because no two threads ever write the same pixel.
    const int band = (height + threads - 1) / threads;
    for (int t = 0; t < threads; ++t) {
        const int y0 = rowBegin + t * band;
        const int y1 = std::min(y0 + band, rowEnd);
        if (y0 >= y1) break;
        pool.emplace_back(renderRows, y0, y1);
    }
    for (std::thread& th : pool) th.join();
}

// ---------------------------------------------------------------------------
// The output transform over a finished frame
// ---------------------------------------------------------------------------

// ===========================================================================
// THREADED, AND THAT DECISION WAS MADE BY A MEASUREMENT THAT CONTRADICTED THE GUESS.
//
// This was written single-threaded with a comment calling the cost "about 20 ms, not
// worth a pool". MEASURED with mistytunec at 1920x1080: it is 91-97 ms.
//
// The guess was out by nearly five times, and the number it was out by is the one that
// decides the question. A Draft GPU frame is 0.28 s on an RTX 2070 SUPER, so a
// 93 ms serial tail is THIRTY-THREE PER CENT of it -- three times what the denoiser
// costs on CUDA, for a pass that is exposure and a transfer curve.
//
// WHERE IT GOES: 1920x1080x3 is 6.2 million powf calls, at roughly 15 ns each. Nothing
// is wrong; there are simply that many of them.
//
// WITH THE POOL IT IS 10.3 ms on an 8-core/16-thread i7-10700K -- a 9x win, and 3.7%
// of that Draft frame instead of 33%. Measured the same way, five runs each.
//
// THREADING CANNOT CHANGE THE PICTURE, which is why this needs no new tripwire. Every
// pixel reads and writes only itself, so any partition of the rows produces identical
// floats in any order -- unlike the per-sample sum, where regrouping is exactly what
// samplesPerLaunch() exists to control. The contiguous-band split below is the same
// one renderCpu uses, and for the same cache reason.
//
// NO deriveRenderInputs() HERE, unlike every render entry point. This pass reads
// req.view and req.dest and nothing else -- no majorant, no drift table, no field at
// all -- so there is nothing to derive and calling it would only suggest there was.
// ===========================================================================
void transformCpu(const RenderRequest& req, int threads, int rowBegin, int rowEnd) {
    if (!req.dest.data || req.dest.widthPx <= 0 || req.dest.heightPx <= 0) return;

    if (rowBegin < 0) rowBegin = 0;
    if (rowEnd <= 0 || rowEnd > req.dest.heightPx) rowEnd = req.dest.heightPx;
    if (rowBegin >= rowEnd) return;

    const int height = rowEnd - rowBegin;

    if (threads <= 0) {
        unsigned int want = std::thread::hardware_concurrency();
        if (want == 0) want = 1;
        threads = static_cast<int>(want);
    }
    if (threads > height) threads = height > 0 ? height : 1;

    const auto transformRows = [&req](int y0, int y1) {
        for (int y = y0; y < y1; ++y) {
            for (int x = 0; x < req.dest.widthPx; ++x) {
                transformPixel(req, x, y);
            }
        }
    };

    if (threads <= 1) {
        transformRows(rowBegin, rowEnd);
        return;
    }

    std::vector<std::thread> pool;
    pool.reserve(static_cast<size_t>(threads));

    const int band = (height + threads - 1) / threads;
    for (int t = 0; t < threads; ++t) {
        const int y0 = rowBegin + t * band;
        const int y1 = std::min(y0 + band, rowEnd);
        if (y0 >= y1) break;
        pool.emplace_back(transformRows, y0, y1);
    }
    for (std::thread& th : pool) th.join();
}

} // namespace plugin::kernel
