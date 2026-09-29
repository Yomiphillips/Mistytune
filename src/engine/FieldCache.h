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
// THAT ARGUMENT TURNS OUT TO BE FALSE FOR OIDN 2.x, AND IT WAS MEASURED RATHER THAN
// ARGUED AGAIN. The filter normalises its own input: the same image denoised three
// stops apart agrees to 0.42% once the gain is divided out. Denoise strength does NOT
// track the exposure slider, so exposure does not have to reach the denoiser first.
// See TheHdrFilterIsScaleInvariantSoExposureNeedNotPrecedeIt in
// tests/unit/TestDenoiser.cpp, kept so a future OIDN that stops auto-exposing says so
// there rather than in somebody's render.
//
// SO THE RESOLVE IS THE SIMPLER THING the rest of the codebase already described:
//
//     mean -> DENOISE -> exposure, tonemap, encode
//
// one output-transform pass rather than two, which is worth about 5 ms a frame at
// 1080p. What has NOT changed is the constraint that matters: the denoiser must never
// see a TONEMAPPED or ENCODED buffer. Scale invariance is not curve invariance, and
// AgX is not a gain.
//
// THE SPLIT ITSELF STANDS EITHER WAY. Every stage of the resolve is cheap next to
// tracing, so an exposure change costs one resolve -- the denoise included, about
// 30 ms on CUDA -- rather than a re-render of 2.97 s.
//
// WHAT MADE THE SPLIT POSSIBLE was lifting applyOutputTransform out of renderPixel.
// While it ran per sample, the destination held exposed values from the first sample
// onward and there was nothing linear left to re-expose.
// ===========================================================================
uint64_t resolveHash(const cloud::ViewParams& v, const cloud::QualityParams& q);

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

// ===========================================================================
// A FieldCache PLUS THE GEOMETRY OF THE BUFFER IT DESCRIBES, AND THE ONE QUESTION THE
// RENDER LOOP ACTUALLY ASKS OF IT: may this frame be resolved without tracing?
//
// ONE OF THESE PER ENGINE, PER RENDER THREAD, thread_local in the effect, beside the
// accumulators -- which are thread_local too. A shared cache over per-thread buffers is
// wrong even with a lock: thread A records 32 samples, thread B is told "resolve", and
// resolves from ITS OWN buffer while the cache vouches for A's.
//
// IN src/engine/ RATHER THAN IN THE EFFECT because every condition in canResolve() is
// one whose absence renders a plausible wrong picture, and here they are testable in
// microseconds with no host. See tests/unit/TestFieldCache.cpp.
// ===========================================================================
class AccumulatorCache {
public:
    // Stop vouching for anything. Called BEFORE any render that will write the
    // accumulator, so that a fallback or an abort partway through leaves it empty.
    void invalidate() { m_fc.clear(); m_widthPx = m_heightPx = m_pitchPx = 0; }

    // MAY THIS FRAME BE REBUILT FROM THE ACCUMULATOR WITH ZERO NEW SAMPLES?
    //
    //   * field and sampling hashes match -- FieldCache answers ResolveOnly or
    //     Accumulate only when both do. Otherwise the buffer holds another sky or
    //     another view.
    //
    //   * THE SAMPLE COUNT MATCHES EXACTLY, not "at least". Resolving 128 samples for a
    //     frame asked at 64 gives a cleaner picture -- and a frame whose noise depends
    //     on what this thread rendered before it. Under multi-frame rendering that is
    //     neighbouring frames at different noise levels for no visible reason.
    //     samplesPerPixel is in no hash on purpose, so this is the only place it is
    //     checked.
    //
    //   * THE GEOMETRY MATCHES. The accumulator is indexed by row pitch, pitch is in no
    //     hash, and AE's rowbytes can differ between two renders of one frame. A resolve
    //     at another pitch reads every row at the wrong stride: it renders, it is
    //     garbage.
    bool canResolve(const RenderKey& key, int32_t totalSamples,
                    int32_t widthPx, int32_t heightPx, int32_t pitchPx) const {
        const Decision d = m_fc.decide(key);
        if (d != Decision::ResolveOnly && d != Decision::Accumulate) return false;
        if (m_fc.samples() != totalSamples) return false;
        return m_widthPx == widthPx && m_heightPx == heightPx && m_pitchPx == pitchPx;
    }

    // A WHOLE FRAME, rendered start to end on one engine with nothing aborted, is now
    // in the accumulator. The only thing that credits the cache.
    void adoptFull(const RenderKey& key, int32_t totalSamples,
                   int32_t widthPx, int32_t heightPx, int32_t pitchPx) {
        m_fc.adopt(key);
        m_fc.addSamples(key, totalSamples);
        m_widthPx = widthPx; m_heightPx = heightPx; m_pitchPx = pitchPx;
    }

    // The frame was re-resolved: same samples, new resolve key.
    void adoptResolve(const RenderKey& key) { m_fc.adoptResolve(key); }

    int32_t samples() const { return m_fc.samples(); }

private:
    FieldCache m_fc;
    int32_t    m_widthPx  = 0;
    int32_t    m_heightPx = 0;
    int32_t    m_pitchPx  = 0;
};

} // namespace plugin::sim
