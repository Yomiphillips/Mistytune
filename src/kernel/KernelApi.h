#pragma once

// THE ONLY THING THE HOST CALLS.
//
// Two implementations behind one declaration: the CUDA launch in Mistytune.cu and
// the CPU reference in CpuRender.cpp. Callers pick by asking cudaAvailable()
// rather than by #ifdef, so src/ae/ and src/cli/ hold no CUDA conditionals at all
// and the CPU path is exercised on a machine that has a GPU.
//
// NO AE HEADERS AND NO CUDA HEADERS IN THIS FILE. A caller that had to include
// cuda_runtime.h to ask whether CUDA existed would defeat the point.

#include "RenderRequest.h"

namespace plugin::kernel {

// Was this binary built with a CUDA toolkit, and is a usable device present?
//
// TWO QUESTIONS IN ONE ANSWER, deliberately. A build with CUDA compiled in still
// has to cope with a machine whose driver is older than the runtime, or whose GPU
// was claimed by something else -- and from the caller's point of view both mean
// the same thing: take the CPU path. The diagnostic log records WHICH, because
// "no toolkit" and "driver too old" need different fixes.
bool cudaAvailable();

// A human-readable name for the device the renderer would use, for the diagnostic
// log. Never null; returns a string saying so when there is no device.
//
// PLAN.md's Phase 1 exit criterion asks for exactly this line: "the diagnostic log
// names the GPU device AE handed us." A render path that silently fell back to the
// CPU and was merely slow is the failure this catches.
const char* deviceDescription();

// Renders `req.sampleCount` samples into the request's accumulator and writes the
// result to its destination surface.
//
// BOTH POINTERS MUST ALREADY BE DEVICE MEMORY for the CUDA path and host memory
// for the CPU path. This function does not copy: AE hands out GPU worlds through
// PF_GPUDeviceSuite1::GetGPUWorldData and expects a kernel to write into them
// directly, and adding a staging copy would double the bandwidth of every frame
// for nothing.
//
// Returns false if the launch could not be made at all. A launch that was made and
// then failed reports through cudaError, which the caller reads separately -- the
// two need different handling, because the first is "take the CPU path" and the
// second is "something is wrong with this machine".
bool renderCuda(const RenderRequest& req);

// The same arithmetic on the CPU, over host memory.
//
// NOT A SECOND IMPLEMENTATION. Both paths call renderPixel() from Shading.h, so
// this is a different loop around identical maths -- which is what lets a golden
// image taken on the CPU be a meaningful check on the GPU. It is a correctness
// reference and a fallback; at comp resolution a real path trace on a CPU is
// minutes per frame, and it is not a shipping renderer.
//
// THREADS IS AN ARGUMENT AND NOT PART OF RenderRequest, and that placement is the
// point rather than a detail.
//
// How the work is divided is an execution decision; what the image contains is a
// scene decision. Putting the thread count in QualityParams would make it a
// parameter -- keyframable, landing in the field or view hash, and reasonably
// read by the next person as something that changes the picture.
//
// It must not change the picture, and tests/golden/ asserts exactly that: the
// same scene rendered at one thread and at eight must come out byte-identical.
// That is the tripwire for multi-frame rendering, where After Effects picks the
// worker count and we do not get a say.
//
// 0 means "choose one", which is what the effect passes.
//
// ROWS [rowBegin, rowEnd) ONLY, so the caller can break one frame into pieces small
// enough to check the host's abort between them. rowEnd <= 0 means "to the bottom",
// which is what the CLI and the golden tests pass.
//
// IT CANNOT CHANGE THE PICTURE, and that is why the split is by ROW rather than by
// anything cleverer: a pixel's value depends only on its own samples, so rows never
// interact and any partition of them accumulates the identical floats in the
// identical order. A partition that regrouped the per-sample SUM would not have that
// property -- floating-point addition is not associative -- which is why the sample
// count per call is the caller's business and the row range is not.
void renderCpu(const RenderRequest& req, int threads = 0,
               int rowBegin = 0, int rowEnd = 0);

// Renders on the GPU into HOST memory: allocates a device buffer, launches into
// it, copies the result back, frees. req.dest.data is ordinary host memory.
//
// WHY THIS EXISTS ALONGSIDE renderCuda(), WHICH LOOKS LIKE IT DOES THE SAME JOB.
//
// renderCuda() is for a host that hands out GPU buffers -- After Effects through
// PF_GPUDeviceSuite1, where adding a staging copy would double the bandwidth of
// every frame for nothing. THIS one is for every other case, and there are two
// that matter:
//
//   1. THE CLI, which has no host to get device memory from. Without this there is
//      no way to run the kernel outside After Effects, and therefore no way to
//      compare the GPU against the CPU reference -- which is the half of
//      tests/golden/ that has never been writable.
//
//   2. AFTER EFFECTS WHEN IT DECLINES TO GPU-RENDER. Measured on AE 2026 with a
//      32 bpc float project, Mercury GPU Acceleration set to CUDA, and a device AE
//      itself handed the effect at GPU_DEVICE_SETUP: pre-render still reports
//      what_gpu=NONE, so PF_Cmd_SMART_RENDER_GPU is never called. Dropping
//      I_USE_3D_CAMERA did not change it; adding PIX_INDEPENDENT did not change it.
//      The card is idle for reasons that are not the effect's to fix.
//
//      This is the way out, and it is what most GPU-using AE plugins do anyway:
//      own the device memory, launch from inside the ordinary CPU smart render,
//      copy back. One device-to-host copy per frame, which is nothing against a
//      path trace.
//
// THE PITCH IS HONOURED, so a padded host buffer (an AE world) copies back as one
// linear block with its padding intact rather than needing a row loop.
//
// ROWS [rowBegin, rowEnd) ONLY, exactly as renderCpu takes them, so a caller can
// break a frame into pieces small enough to check the host's abort between them.
// rowEnd <= 0 means "to the bottom".
//
// ON THE GPU THE BAND IS ALSO THE TDR MITIGATION. The Windows display driver's
// timeout is about two seconds and it kills the whole context, not just the launch
// -- so a frame at a high sample count has to be several launches whatever else is
// true. Measured on an RTX 2070 SUPER: 1920x1080 at 64 samples is 0.67 s in one
// launch, so the timeout is roughly 200 samples away at that resolution, and the
// parameter's valid range goes to 65536.
//
// THE BAND IS A WINDOW, NOT A CROP, and that distinction is the whole reason this
// works: the device buffer holds only the band's rows, while view.originY is moved
// down by rowBegin so every ray still knows which row of the FULL FRAME it is. Get
// that wrong and each band renders the top of the picture.
bool renderCudaToHost(const RenderRequest& req, int rowBegin = 0, int rowEnd = 0);

// The last CUDA error, cleared by reading it. Empty when there was none.
const char* lastCudaError();

} // namespace plugin::kernel
