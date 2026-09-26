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
void renderCpu(const RenderRequest& req);

// The last CUDA error, cleared by reading it. Empty when there was none.
const char* lastCudaError();

} // namespace plugin::kernel
