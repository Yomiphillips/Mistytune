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

// ---------------------------------------------------------------------------
// The derived half of the request
// ---------------------------------------------------------------------------

// Fill the request's derived fields from its parameters.
//
// EVERY RENDER ENTRY POINT BELOW CALLS THIS ON ITS OWN COPY, so no caller can forget
// it and there is no sentinel value meaning "nobody derived this yet". The
// alternative -- documenting that callers must call it first -- has three callers
// today (the effect, the CLI, the golden tests) and would have more, and the failure
// mode is a majorant of zero, which renders an empty sky rather than an error.
//
// IT IS CHEAP AND IT IS NOT PER-PIXEL. Thirty-three sine and cosine pairs, once per
// launch, against a path trace. Measuring it would cost more than it does.
//
// HOST ONLY. It calls into src/engine/, which is host code, which is exactly why the
// results have to travel to the kernel as data -- see the note in RenderRequest.h.
inline void deriveRenderInputs(RenderRequest& req) {
    cloud::buildDriftTable(req.field.ice, req.drift);

    // A PINNED MAJORANT WINS, and it is allowed to be wrong. QualityParams calls it
    // "0 = derive from the field", so a positive value is the user overriding the
    // structural bound -- which is a legitimate thing to want when profiling, and an
    // illegitimate thing to ship. Too low is not an error the renderer can detect:
    // the estimator simply stops being one. See IceField.h.
    req.densityMajorant = req.quality.densityMajorant > cloud::Real(0)
                        ? req.quality.densityMajorant
                        : cloud::iceMajorant(req.field.ice);

    req.fallSpeed = cloud::iceFallSpeed(req.field.ice);

    cloud::cellDriftAt(req.field.ice, req.field.timeSeconds,
                       req.cellDriftX, req.cellDriftZ);
}

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

// Renders on the GPU into HOST memory: reserves a device buffer, launches into it,
// copies the result back. req.dest.data is ordinary host memory.
//
// THE DEVICE BUFFER IS NOT FREED WHEN THIS RETURNS. It is grow-only, thread-local
// scratch that lives until the calling thread ends, because a comp renders the same
// size thousands of times in a row and a driver-side allocation is a synchronising
// call. See DeviceScratch in Mistytune.cu. The caller owns nothing and frees nothing.
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

// ---------------------------------------------------------------------------
// How many samples one launch may take
// ---------------------------------------------------------------------------

// WHY ROW BANDS ARE NOT ENOUGH, WHICH IS NOT OBVIOUS AND COST A READING TO FIND.
//
// The host already splits a frame into bands of rows and sizes them from a
// pixel-sample budget, so a band is roughly constant work however many samples the
// user asked for. That bounds the launch -- right up until the band hits its FLOOR.
//
// The floor exists for its own good reasons (below it, most threads in every 16-row
// CUDA block idle, and the CPU pool runs out of rows to divide). Once the band is at
// the floor, the only thing left that scales with the sample count is the launch
// itself. At 1920 wide with a 16-row floor and the 2M pixel-sample budget below, the
// crossover is about 68 samples per pixel -- and the Samples parameter's range goes
// to 65536, which is nearly a thousand times past it. At the top of that range one
// launch would be minutes of GPU work against a display-driver timeout of about two
// seconds, and the failure is a driver reset that takes the whole CUDA context --
// and After Effects with it.
//
// THE CROSSOVER MOVED FROM 1041 TO 68 when the real transport replaced the Phase 1
// sky, because it is the budget divided by the floor band and the budget is a
// measurement. Nothing about this function changed; what it is protecting did.
//
// So above the crossover the SAMPLES have to be split as well, with the accumulator
// carrying the partial sums between launches.
//
// IT IS A PURE FUNCTION OF THE REQUEST, AND THAT IS THE WHOLE DESIGN CONSTRAINT.
//
// Splitting the samples REGROUPS the per-pixel sum, and floating-point addition is
// not associative -- so anything that changes the split changes the image. The row
// split is safe because rows never interact; this one is not. tests/golden/ asserts
// byte-identical output across band sizes and across thread counts, and a user under
// multi-frame rendering gets whatever worker count AE felt like.
//
// Therefore: pass the FLOOR band's pixel count here, never the band actually being
// rendered, and never a thread count or a measured time. Two renders of the same
// request then agree whatever the host does around them.
//
// Returns at least 1, and never more than samplesPerPixel -- so a request below the
// crossover is one launch and is bit-for-bit what it was before this existed.
// How much work one GPU launch may contain, in pixel-samples.
//
// ===========================================================================
// THIS NUMBER IS A MEASUREMENT AND IT MOVED BY 18x WHEN THE RENDERER ARRIVED.
//
// It exists to keep every launch clear of the Windows display-driver timeout, which
// is about two seconds and which kills the whole CUDA CONTEXT rather than the
// launch -- taking After Effects with it. So the budget is chosen as "roughly a
// quarter of a second of GPU work", and what a pixel-sample costs is the only input.
//
//   Phase 1, the analytic sky      ~5 ns each   -> 32M pixel-samples was 0.16 s
//   Phase 2, the real transport   ~93 ns each   -> 32M pixel-samples is 3.0 s
//
// MEASURED on an RTX 2070 SUPER, 2026-09-28: 1920x1080 at 64 samples per pixel is
// 12.37 s, which is 132.7M pixel-samples at 93 ns. The old budget therefore sat
// FIFTY PER CENT PAST THE TIMEOUT rather than a comfortable distance inside it, and
// it did so silently -- the constant did not change, the thing it was measuring did.
//
// 2M pixel-samples is 0.19 s on that card: a tenfold margin here, and still under
// the timeout on a card four times slower. The cost of a smaller budget is more
// launches, at roughly 50 microseconds of overhead each against 190 ms of work.
//
// IT IS A CONSTANT RATHER THAN A MEASURED TIME ON PURPOSE. Splitting the samples
// regroups a floating-point sum, so anything that changes the split changes the
// image -- and tests/golden/ asserts byte-identical output across band sizes and
// worker counts. A budget derived from a timing would make the picture depend on how
// busy the machine was.
//
// WHEN THE MAJORANT IS TIGHTENED, MEASURE AGAIN. The 93 ns is 18x the Phase 1 figure
// and the majorant is currently 18x looser than the field it bounds -- see
// slang.generator, which prints the slack. Those two numbers are not a coincidence,
// and closing the second one moves this budget back up.
// ===========================================================================
constexpr long long kGpuPixelSampleBudget = 2 * 1024 * 1024;

inline int samplesPerLaunch(long long pixelSampleBudget,
                            long long pixelsInFloorBand,
                            int samplesPerPixel) {
    if (samplesPerPixel <= 1) return 1;
    if (pixelsInFloorBand <= 0 || pixelSampleBudget <= 0) return samplesPerPixel;

    const long long fit = pixelSampleBudget / pixelsInFloorBand;
    if (fit <= 1) return 1;
    if (fit >= samplesPerPixel) return samplesPerPixel;
    return static_cast<int>(fit);
}

// Device memory to accumulate into, for a caller that owns its own destination.
//
// FOR THE ONE CASE renderCudaToHost() CANNOT SERVE: a host that hands out GPU
// buffers. After Effects' PF_Cmd_SMART_RENDER_GPU gives the effect a device pointer
// to write into, so the destination is not ours -- but a sample split still needs an
// accumulator, and src/ae/ has no CUDA headers to allocate one with. This hands back
// a bare pointer and keeps the allocation on this side of the wall.
//
// THE CALLER OWNS NOTHING AND FREES NOTHING. It is the same grow-only thread-local
// scratch the rest of this file uses, released when the thread ends, and the pointer
// is stable for as long as the geometry is -- which is what lets the launches of one
// frame accumulate into it.
//
// Sized in the same units as Surface: pitch in pixels of four floats, times rows.
// Returns null if the allocation failed or this build has no CUDA.
float* reserveDeviceAccumulator(int pitchPx, int heightPx);

// The last CUDA error, cleared by reading it. Empty when there was none.
const char* lastCudaError();

} // namespace plugin::kernel
