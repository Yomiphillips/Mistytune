#pragma once

// THE STYLIZED LOOK'S LIGHT AND MARCH PASSES (build 32), as each backend runs them. Internal to
// src/kernel: the host calls renderStylizedCudaToHost / renderStylizedCpu in KernelApi.h, which
// bake and then call these.
//
// IN FILES OF THEIR OWN -- StylizedCpu.cpp and StylizedCuda.cu -- so the look's shading, which is
// what gets tuned, rebuilds two small files and not the generated renderer.

#include "RenderRequest.h"
#include "StylizedFrame.h"

#include <algorithm>
#include <thread>
#include <vector>

namespace plugin::kernel {

// ---------------------------------------------------------------------------
// The CPU
// ---------------------------------------------------------------------------

// [0, n) IN CONTIGUOUS RUNS ACROSS A POOL, 0 threads choosing the machine's width. Every item
// writes only its own output, so any split gives the same bytes.
template <class Fn>
void styleParallelFor(long long n, int threads, const Fn& fn) {
    if (threads <= 0) {
        const unsigned int hw = std::thread::hardware_concurrency();
        threads = hw == 0 ? 1 : static_cast<int>(hw);
    }
    if (n < threads) threads = static_cast<int>(n > 0 ? n : 1);
    if (threads <= 1) {
        for (long long i = 0; i < n; ++i) fn(i);
        return;
    }
    std::vector<std::thread> workers;
    workers.reserve(static_cast<size_t>(threads));
    const long long run = (n + threads - 1) / threads;
    for (int w = 0; w < threads; ++w) {
        const long long i0 = w * run;
        const long long i1 = std::min(i0 + run, n);
        if (i0 >= i1) break;
        workers.emplace_back([&fn, i0, i1] { for (long long i = i0; i < i1; ++i) fn(i); });
    }
    for (std::thread& t : workers) t.join();
}

// From `raw` (every level's density fractions): `packed` (four floats per voxel: density, tau
// sun, tau up, tau down) and `occ` (one flag per block). Threaded; 0 chooses.
void styleLightCpu(const StylizedFrame& f, const float* raw, float* packed, unsigned char* occ,
                   int threads);

// Every pixel of req.dest, transformed and in its channel order. `sky`, `air` and `ci` are the
// tables the bakes made (StylizedFrame.h says their layouts).
void styleMarchCpu(const RenderRequest& req, const StylizedFrame& f, const float* packed,
                   const unsigned char* occ, const float* sky, const float* air, const float* ci,
                   int threads);

// ---------------------------------------------------------------------------
// The GPU
// ---------------------------------------------------------------------------

// From the device's `rawHalf` (every level's density fractions as half floats), the light and
// the march, into DEVICE memory `req.dest`. `sky`, `air` and `ci` are device tables. False with
// lastCudaError() set if a call failed. TIMINGS, when `ms` is not null: light, march, in ms.
bool styleLightAndMarchCuda(const RenderRequest& req, const StylizedFrame& f,
                            const unsigned short* rawHalf, const float* sky, const float* air,
                            const float* ci, float* ms);

// The CUDA error helper Mistytune.cu owns, for the passes in StylizedCuda.cu.
void styleCudaError(const char* what, int code);

} // namespace plugin::kernel
