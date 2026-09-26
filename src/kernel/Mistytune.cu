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

namespace plugin::kernel {

namespace {

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

} // namespace

// The kernel. ONE PIXEL PER THREAD, with the bounds check that every AE GPU
// kernel needs: the grid is rounded up to whole blocks, so the last block runs
// threads that are off the end of the buffer.
__global__ void mistytuneKernel(RenderRequest req) {
    const int px = blockIdx.x * blockDim.x + threadIdx.x;
    const int py = blockIdx.y * blockDim.y + threadIdx.y;
    renderPixel(req, px, py);
}

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
    mistytuneKernel<<<grid, block>>>(req);

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

    void* devMem = nullptr;
    cudaError_t err = cudaMalloc(&devMem, bytes);
    if (err != cudaSuccess) {
        setError("cudaMalloc", err);
        return false;
    }

    RenderRequest devReq = req;
    devReq.dest.data     = devMem;
    devReq.dest.pitchPx  = pitchPx;
    devReq.dest.heightPx = bandRows;

    // THE WINDOW MOVES, THE CAMERA DOES NOT. The band buffer's row 0 is frame row
    // (originY + rowBegin), and primaryRayDirection adds originY before dividing by
    // the frame height -- so every ray keeps its true position in the picture while
    // the kernel indexes a buffer that starts at zero. Without this each band would
    // render the TOP of the frame into a different part of the output.
    devReq.view.originY = req.view.originY + rowBegin;

    // THE ACCUMULATOR IS NOT CARRIED ACROSS. It would have to live in device memory
    // and persist between calls, which is the progressive-accumulation design and
    // not this function's job. Callers that want accumulation own the device buffer
    // themselves and use renderCuda().
    devReq.accumulator        = nullptr;
    devReq.accumulatorPitchPx = 0;

    const bool launched = renderCuda(devReq);
    if (!launched) {
        // renderCuda has already filled in the error; do not overwrite it with a
        // less specific one from the cleanup path.
        cudaFree(devMem);
        return false;
    }

    // Back into the band's own slice of the host buffer, at the host pitch.
    char* hostBand = static_cast<char*>(req.dest.data)
                   + static_cast<size_t>(rowBegin) * rowBytes;

    err = cudaMemcpy(hostBand, devMem, bytes, cudaMemcpyDeviceToHost);
    cudaFree(devMem);

    if (err != cudaSuccess) {
        setError("cudaMemcpy device->host", err);
        return false;
    }
    return true;
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
