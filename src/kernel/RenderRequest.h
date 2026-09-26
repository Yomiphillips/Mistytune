#pragma once

// EVERYTHING THE RENDERER IS TOLD, in one plain struct.
//
// NO AE HEADERS, NO CUDA HEADERS, NO STL. This header is included by the effect,
// by the CLI, by the .cu translation unit and by the CPU reference, so it has to
// compile under every one of nvcc, MSVC and clang with nothing on the include
// path. That constraint is what makes golden images possible at all: the effect
// hands the kernel this struct and src/cli/ hands it the same struct, so a
// mismatch between the two is a difference in the struct and nowhere else.
//
// It is the reason src/kernel/ is a separate directory from src/ae/ rather than a
// file inside it.

#include "../engine/CloudParams.h"

namespace plugin::kernel {

// WHERE A PIXEL'S FOUR FLOATS SIT IN MEMORY, and it is not the same on both
// paths -- which is a bug waiting to happen, so it is a parameter rather than an
// assumption.
//
//   AE's CPU worlds are ARGB: PF_PixelFloat is { alpha, red, green, blue }.
//   AE's GPU worlds are BGRA: PF_PixelFormat_GPU_BGRA128 is
//                             { blue, green, red, alpha }.
//
// Getting it wrong does not crash and does not look obviously broken -- it looks
// like the sky has the wrong colour balance, which reads as a bug in the
// atmosphere model rather than as a channel swap. Ask, do not assume.
enum class ChannelOrder : int {
    ARGB = 0,   // AE CPU worlds, 8/16/32 bpc
    BGRA = 1    // AE GPU worlds, PF_PixelFormat_GPU_BGRA128
};

// The destination surface.
//
// PITCH IN PIXELS, NOT BYTES, matching what the GPU sample passes its kernels
// (rowbytes / bytes_per_pixel). A row stride is never assumed to equal the width:
// AE pads rows, and at reduced resolution the buffer is a different shape again.
struct Surface {
    void* data      = nullptr;
    int   widthPx   = 0;
    int   heightPx  = 0;
    int   pitchPx   = 0;          // elements of 4 floats per row
    ChannelOrder order = ChannelOrder::ARGB;
};

// One render, fully specified.
//
// THE SPLIT MIRRORS FieldParams / ViewParams FOR THE SAME REASON THEY EXIST: the
// field is expensive and the view is not. See src/engine/FieldCache.h.
struct RenderRequest {
    cloud::FieldParams   field;
    cloud::ViewParams    view;
    cloud::QualityParams quality;

    // WHICH SAMPLES THIS LAUNCH IS RESPONSIBLE FOR, as a half-open range into the
    // frame's total sample budget.
    //
    // THIS IS THE TDR MITIGATION, and it is why the renderer is chunked at all.
    // The Windows display driver's timeout is about two seconds; a full-quality
    // frame sits exactly on it, and the failure is a driver reset rather than a
    // slow render. So a frame is many launches, each responsible for a slice of
    // the samples, with the accumulation buffer persisting between them.
    //
    // IT IS ALSO WHERE DETERMINISM COMES FROM. The seed for a sample is derived
    // from (frame, sampleIndex, pixel) and the field's own seed -- never a clock,
    // a thread id, or a counter shared between launches. Motion blur renders one
    // frame several times and MFR renders frames on different workers, so
    // anything else gives a different image on the second pass.
    int firstSample = 0;
    int sampleCount = 1;

    // Linear radiance, four floats per pixel, persisting across the launches of
    // one frame. Null on the CPU reference path, which accumulates in the
    // destination surface directly because it has nowhere else to put it.
    float* accumulator     = nullptr;
    int    accumulatorPitchPx = 0;

    // Total samples already in the accumulator BEFORE this launch. The kernel
    // needs it to weight its own contribution, and taking it as a parameter rather
    // than storing it per-pixel keeps the accumulator a plain radiance sum.
    int samplesAlreadyDone = 0;

    Surface dest;
};

} // namespace plugin::kernel
