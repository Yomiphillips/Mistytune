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

    // Hash of everything that changes the IMAGE without changing the MEDIUM --
    // the camera, the exposure, the bounce depth, the output size. Changing this
    // invalidates the accumulated samples and nothing else.
    uint64_t view = 0;
};

enum class Decision {
    // Nothing changed. Launch another batch of samples into the buffer that is
    // already there, and the image gets quieter. This is the case that makes a
    // 2-second-per-frame renderer feel interactive, so it is the case worth
    // being sure about.
    Accumulate,

    // The camera moved, or the exposure changed, or the comp was resized. The
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
uint64_t viewHash(const cloud::ViewParams& v, const cloud::QualityParams& q);

class FieldCache {
public:
    // What to do about this render. Does not change any state -- call adopt()
    // once the work has actually been done, so a render that fails part way is
    // retried rather than remembered as complete.
    Decision decide(const RenderKey& k) const;

    // This key's field is now built and its accumulator is live. Resets the
    // sample count to zero.
    void adopt(const RenderKey& k);

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
