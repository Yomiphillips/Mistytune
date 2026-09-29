#pragma once

// WHEN A RENDER MAY REUSE WHAT THE LAST ONE BUILT.
//
// Pure policy -- no GPU memory, no AE, no clock -- so every rule below is unit
// tested. src/ae/ owns the actual buffers and asks this what to do with them.
//
// ---------------------------------------------------------------------------
// WHAT THIS REPLACES, AND WHY IT IS NOT AutoSolveGate.
//
// The Gravitune scaffolding this repo grew from had an AutoSolveGate with four
// rules -- never solve on first sight, not while a clean project changes, wait
// for the change to settle, one solve per change. Every one of those existed
// because a re-solve WROTE TO THE PROJECT: keyframes and expressions, one undo
// step, and a write the user did not ask for is the thing to avoid above all.
//
// MISTYTUNE WRITES NOTHING. It is a plain effect; a rebuild costs a slow frame
// and not an undo step. So the settle timer, the dirty-project rule and the
// first-sight rule have nothing to protect here and are gone.
//
// WHAT SURVIVES IS THE MECHANISM PLAN.md ACTUALLY NAMED: answer "would rebuilding
// give something different?" with a hash instead of a rebuild, and keep the
// sizeof tripwire that breaks the build when a new parameter goes unhashed. That
// is Fingerprint.h, and this is the cache it exists to serve.
// ---------------------------------------------------------------------------
//
// THE THREE-WAY DECISION IS THE WHOLE POINT. A two-way valid/invalid cache would
// throw the field away on every camera nudge, which is the exact failure PLAN.md
// calls the difference between a plugin people use and one they abandon.

#include "CloudParams.h"

#include <cstdint>

namespace plugin::sim {

// What identifies a render, in two independent halves.
//
// The split mirrors FieldParams / ViewParams exactly, and for the same reason:
// the field is expensive and the view is not, so they must be able to change
// independently.
struct RenderKey {
    // Fingerprint of FieldParams. Changing this invalidates the medium itself.
    uint64_t field = 0;

    // Hash of everything that decides WHICH RAYS ARE TRACED -- the camera, the
    // output size and origin, the bounce depth. Changing this invalidates the
    // accumulated samples, because the samples already taken are samples of a
    // different integral.
    //
    // RENAMED FROM `view`, AND THE RENAME IS THE POINT: `view` used to mean
    // "everything that is not the field", which lumped the camera in with the
    // exposure slider. Those two cost wildly different amounts to change.
    uint64_t sampling = 0;

    // Hash of everything applied to the FINISHED accumulation -- exposure, the
    // tonemap, the output encoding. Changing this needs no new samples at all.
    // See resolveHash().
    uint64_t resolve = 0;
};

enum class Decision {
    // Nothing changed. Launch another batch of samples into the buffer that is
    // already there, and the image gets quieter. This is the case that makes a
    // 2-second-per-frame renderer feel interactive, so it is the case worth
    // being sure about.
    Accumulate,

    // ===================================================================
    // ONLY THE OUTPUT TRANSFORM CHANGED. The accumulated radiance is still
    // exactly right; re-run the resolve pass over it and trace NOTHING.
    //
    // THIS CASE DID NOT EXIST UNTIL THE OUTPUT TRANSFORM LEFT THE PER-PIXEL PATH.
    // While exposure was applied inside renderPixel, the accumulator held exposed
    // values and there was no way to re-expose them without re-tracing -- so
    // exposure had to live in the sampling key, and dragging the exposure slider
    // threw away every sample.
    //
    // WHAT IT IS WORTH: measured at 1920x1080, a resolve is the ~10 ms transform
    // pass against 2.97 s to re-trace 64 samples. Three hundred to one, on the
    // control an artist drags most.
    // ===================================================================
    ResolveOnly,

    // The camera moved, or the comp was resized, or the bounce depth changed. The
    // field still describes the same sky, so KEEP IT and clear the accumulator.
    RestartSamples,

    // A parameter that decides what is in the sky changed. Rebuild the field,
    // then start accumulating into a cleared buffer.
    RebuildField
};

// The hash of everything that restarts accumulation without rebuilding the field.
//
// SAMPLE COUNT IS DELIBERATELY ABSENT. Raising samplesPerPixel asks for a more
// converged version of the same image, so it must CONTINUE the accumulation --
// hashing it would clear the buffer every time the user dragged the quality
// slider, which is the opposite of what they asked for. samplesPerLaunch is
// absent for the same reason: it only decides how the work is chopped up to stay
// under the Windows driver timeout, and chopping it differently cannot change
// the answer.
//
// maxBounces IS present, and it is the one that needs the explanation: it
// changes the image, so the samples already taken are not samples of the image
// now being asked for, and averaging the two would give a picture of neither.
// The field is untouched though, so this is a RestartSamples and not a rebuild.
//
// EXPOSURE, TONEMAP AND ENCODING ARE DELIBERATELY ABSENT -- they are resolveHash's.
uint64_t samplingHash(const cloud::ViewParams& v, const cloud::QualityParams& q);

// The hash of everything applied to the finished accumulation.
//
// ===========================================================================
// THESE THREE USED TO BE IN THE SAMPLING HASH, WITH A REASON THAT WAS RIGHT AT THE
// TIME AND IS NOW THE REASON THEY ARE HERE INSTEAD.
//
// The old comment argued that exposure must be hashed with the samples because the
// accumulation buffer is linear radiance and OIDN is trained on roughly perceptual
// magnitudes -- so the exposure has to be in the numbers before the denoiser sees
// them, or denoise strength silently tracks the exposure slider.
//
// THAT ARGUMENT IS STILL TRUE AND IT CONSTRAINS THE ORDER INSIDE THE RESOLVE PASS,
// NOT WHETHER EXPOSURE IS A SAMPLING INPUT. The resolve is
//
//     mean -> exposure -> DENOISE -> tonemap -> encode
//
// and every stage of it is cheap next to tracing. So the denoiser still sees exposed
// values, and an exposure change still costs one denoise -- about 30 ms on CUDA --
// rather than a re-render of 2.97 s.
//
// WHAT MADE THE SPLIT POSSIBLE was lifting applyOutputTransform out of renderPixel.
// While it ran per sample, the destination held exposed values from the first sample
// onward and there was nothing linear left to re-expose.
// ===========================================================================
uint64_t resolveHash(const cloud::ViewParams& v);

class FieldCache {
public:
    // What to do about this render. Does not change any state -- call adopt()
    // once the work has actually been done, so a render that fails part way is
    // retried rather than remembered as complete.
    Decision decide(const RenderKey& k) const;

    // This key's field is now built and its accumulator is live. Resets the
    // sample count to zero.
    //
    // FOR RebuildField AND RestartSamples ONLY. A ResolveOnly render must not come
    // through here -- it would throw away the samples it exists to preserve.
    void adopt(const RenderKey& k);

    // The resolve pass has been re-run for this key. KEEPS THE SAMPLE COUNT, which
    // is the entire difference from adopt().
    //
    // IGNORED IF THE FIELD OR SAMPLING HALVES DISAGREE, for the same reason
    // addSamples checks: a resolve that finished after the camera moved is a
    // resolve of the previous picture, and recording it would leave the cache
    // claiming the new view is resolved when the buffer holds the old one.
    void adoptResolve(const RenderKey& k);

    // Another batch of `count` samples landed in the accumulator for the key
    // that is currently adopted. Ignored if the key does not match, which is
    // what stops a launch that finished after a parameter change from crediting
    // its samples to the new sky.
    void addSamples(const RenderKey& k, int32_t count);

    int32_t samples() const { return m_samples; }

    // True once the accumulator holds at least the requested number of samples,
    // so the caller can stop launching and leave the frame alone.
    bool converged(int32_t wanted) const { return m_valid && m_samples >= wanted; }

    // Forget everything. For PF_Cmd_GPU_DEVICE_SETDOWN, where the buffers this
    // was describing have gone away underneath us.
    void clear();

private:
    bool     m_valid   = false;
    RenderKey m_key;
    int32_t  m_samples = 0;
};

} // namespace plugin::sim
