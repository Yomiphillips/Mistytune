// What KernelApi.h resolves to when there is no CUDA toolkit.
//
// COMPILED INSTEAD OF Mistytune.cu, never alongside it.
//
// WHY A STUB RATHER THAN #ifdef AT EVERY CALL SITE. The callers -- src/ae/ and
// src/cli/ -- ask cudaAvailable() and take the CPU path when it says no. That is
// the same code they run on a machine that HAS CUDA but whose driver is too old,
// so the fallback path is exercised constantly instead of being the branch nobody
// compiles. A #ifdef at each call site would give two different programs, and the
// one without a GPU would be the one nobody ever ran.
//
// It also keeps the GPU-less build honest: the plugin loads, renders, and says in
// the log exactly why it is slow.

#include "KernelApi.h"

namespace plugin::kernel {

bool cudaAvailable() { return false; }

const char* deviceDescription() {
    // PHRASED FOR WHOEVER READS THE LOG. "No device" would be ambiguous between a
    // machine with no GPU and a binary with no GPU support, and those need
    // different fixes -- one is buy a card, the other is rebuild.
    return "built without CUDA support (CPU reference path)";
}

bool renderCuda(const RenderRequest&) { return false; }

bool renderCudaToHost(const RenderRequest&, int, int) { return false; }

// NO STUB FOR transformCpu, BECAUSE IT HAS NO GPU IN IT. CpuRender.cpp defines it in
// both builds -- this file replaces the CUDA half of the API and nothing else.
bool transformCuda(const RenderRequest&) { return false; }

float* reserveDeviceAccumulator(int, int) { return nullptr; }

const char* lastCudaError() { return ""; }

bool renderStylizedCudaToHost(const RenderRequest&, StylizedTimings*) { return false; }

} // namespace plugin::kernel
