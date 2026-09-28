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
#include <thread>
#include <vector>

namespace plugin::kernel {

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

} // namespace plugin::kernel
