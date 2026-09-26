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

    const auto renderRows = [&req](int y0, int y1) {
        for (int y = y0; y < y1; ++y) {
            for (int x = 0; x < req.dest.widthPx; ++x) {
                renderPixel(req, x, y);
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
