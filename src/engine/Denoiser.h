#pragma once

// Intel Open Image Denoise, loaded at RUNTIME and optional at every step.
//
// ===========================================================================
// THE WHOLE POINT OF THIS FILE IS THAT IT CAN FAIL AND THE EFFECT STILL LOADS.
//
// PLAN.md requires the integration to be a runtime-optional load INDEPENDENTLY of the
// decision to bundle the DLLs, and bundling makes that path rarer rather than
// unnecessary: a user who prunes the install folder, or an antivirus that quarantines
// one DLL of the set, is exactly the case it exists for.
//
// So nothing here is linked. There is no `#include <OpenImageDenoise/oidn.h>`, no
// OpenImageDenoise.lib on any link line, and no import table entry -- because a
// load-time import of a missing DLL is a plugin After Effects refuses to load AT ALL,
// with an error that names the effect and not the missing file. That failure looks
// like "Mistytune is broken", and the user cannot tell it from one.
//
// The entire API this needs is ten functions, declared here as pointers and resolved
// with GetProcAddress. That is a DECLARED ABI with one job -- the same arrangement
// SkyInput is under in src/kernel/slang/SkyLib.slang, and for the same reason: a
// header we do not control cannot be a build dependency of a thing that must build
// without it.
// ===========================================================================
//
// WHY IT IS IN src/engine/ RATHER THAN src/kernel/. It touches no GPU header and no
// AE header, it is a pure function of a buffer, and the case that matters most -- no
// library present, render undenoised, say so -- is testable in microseconds with
// neither a host nor a card. That is what src/engine/ is for. src/cli/ and src/ae/
// both call it, and neither has a second copy of the decision.

#include <cstdint>

namespace plugin::cloud {

// ---------------------------------------------------------------------------
// What it is given
// ---------------------------------------------------------------------------

// How the four floats of a pixel are ordered.
//
// MIRRORS src/kernel/RenderRequest.h's ChannelOrder WITHOUT DEPENDING ON IT. src/engine
// does not reach into src/kernel -- the dependency runs the other way -- so the caller
// translates. Two enumerators and a one-line conversion at the call site is the price
// of the layering, and it is cheaper than the layering violation.
enum class DenoiseOrder : int32_t {
    ArgbFloat4 = 0,   // pix[0]=A, [1]=R, [2]=G, [3]=B
    BgraFloat4 = 1    // pix[0]=B, [1]=G, [2]=R, [3]=A
};

// A frame of linear, EXPOSED radiance, four floats per pixel.
//
// EXPOSED AND NOT RAW, AND THE DIFFERENCE IS THE ONE THING A CALLER CAN GET WRONG
// SILENTLY. src/engine/FieldCache.h fixes the resolve order as
//
//     mean -> exposure -> DENOISE -> tonemap -> encode
//
// because OIDN's RT filter is trained on roughly perceptual magnitudes. Exposure is a
// linear scale, so the buffer is still linear scene-referred radiance when it arrives
// here -- which is what the filter wants. A TONEMAPPED or sRGB-ENCODED buffer is not,
// and handing one over is wrong in a way that gets worse the more the tonemap does.
struct DenoiseImage {
    float*       data     = nullptr;
    int32_t      widthPx  = 0;
    int32_t      heightPx = 0;
    int32_t      pitchPx  = 0;   // pixels (of four floats) per row, >= widthPx
    DenoiseOrder order    = DenoiseOrder::ArgbFloat4;

    // HOW MUCH OF THE RESULT TO KEEP, 0..1, blended against what was there.
    //
    // NOT A COMFORT KNOB. Measured at 4 spp against a 512-spp render of the same
    // frame, a full denoise leaves 33% of the fine structure the converged image has;
    // 0.8 reproduces it. QualityParams::denoiseAmount carries the table.
    //
    // 0 IS AN EARLY RETURN rather than a filtered image thrown away, so turning the
    // slider to zero costs nothing at all.
    float amount = 1.0f;
};

// ---------------------------------------------------------------------------
// Using it
// ---------------------------------------------------------------------------

// Is a denoiser usable in this process?
//
// LOADS THE LIBRARY ON FIRST CALL and caches the answer, including the negative one --
// a machine without OIDN must not pay a failed LoadLibrary per frame.
bool denoiserAvailable();

// One line for the diagnostic log, naming the library and the device or saying why
// there is none. Never null.
//
// PLAN.md's Phase 1 exit criterion asks for exactly this shape of line about the GPU,
// and the argument carries over: a render that silently fell back to no denoise and
// was merely noisy is the failure this catches.
const char* denoiserDescription();

// Denoise `img` in place.
//
// RETURNS FALSE AND LEAVES THE IMAGE UNTOUCHED when there is no denoiser, when the
// geometry is unusable, or when the filter reported an error. That is not an error
// path the caller has to handle -- it is the undenoised render, which is a correct
// picture with more noise in it. A caller that treats it as a failure and aborts the
// frame has turned a missing DLL back into a broken effect.
bool denoiseFrame(const DenoiseImage& img);

// Release the per-thread device, filter and buffers.
//
// FOR PF_Cmd_GPU_DEVICE_SETDOWN AND FOR TESTS. An OIDN CUDA device holds a context and
// a few hundred MB; leaving one per render thread alive after AE has taken the GPU
// away is how the next render fails for a reason that points nowhere near here.
void denoiserShutdown();

} // namespace plugin::cloud
