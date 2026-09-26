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

void renderCpu(const RenderRequest& req) {
    if (!req.dest.data || req.dest.widthPx <= 0 || req.dest.heightPx <= 0) return;

    const int height = req.dest.heightPx;

    // ROWS ACROSS THREADS, and the thread count is bounded on purpose.
    //
    // UNDER MULTI-FRAME RENDERING AE IS ALREADY RUNNING SEVERAL FRAMES AT ONCE in
    // this process. Spawning hardware_concurrency() threads per frame on top of
    // that oversubscribes the machine badly enough to be slower than single
    // threaded, and it is the kind of slowdown that looks like the renderer being
    // heavy rather than like the renderer fighting itself.
    //
    // Four is a compromise that helps a single still frame without swamping an
    // MFR export. The real answer is AE's own threading suite, which is Phase 2
    // work alongside the abort and progress callbacks.
    unsigned int want = std::thread::hardware_concurrency();
    if (want == 0) want = 1;
    const int threads = static_cast<int>(std::min(want, 4u));

    const auto renderRows = [&req](int y0, int y1) {
        for (int y = y0; y < y1; ++y) {
            for (int x = 0; x < req.dest.widthPx; ++x) {
                renderPixel(req, x, y);
            }
        }
    };

    if (threads <= 1) {
        renderRows(0, height);
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
        const int y0 = t * band;
        const int y1 = std::min(y0 + band, height);
        if (y0 >= y1) break;
        pool.emplace_back(renderRows, y0, y1);
    }
    for (std::thread& th : pool) th.join();
}

} // namespace plugin::kernel
