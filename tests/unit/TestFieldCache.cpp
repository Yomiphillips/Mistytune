// Tests for the field cache's three-way decision.
//
// THE TEST THAT MATTERS IS CameraMoveKeepsTheField. PLAN.md calls that row the
// difference between a plugin people use and one they abandon: a 2-second field
// rebuild on every frame of a camera move makes the exploration loop -- which the
// design spec calls the product -- impossible. Everything else in this file is
// there to stop that one from being passed by accident.

#include "TestFramework.h"

#include "FieldCache.h"

using namespace plugin;
using namespace plugin::cloud;
using namespace plugin::sim;

namespace {

// `sampling` is the old `view`; `resolve` defaults to a single shared value so the
// existing decision tests keep meaning what they meant -- they are about the field
// and the camera, and a resolve difference would add a second reason to restart and
// stop them testing one thing.
RenderKey keyOf(uint64_t field, uint64_t sampling, uint64_t resolve = 7777) {
    RenderKey k;
    k.field    = field;
    k.sampling = sampling;
    k.resolve  = resolve;
    return k;
}

} // namespace

// --------------------------------------------------------------------------
// The three-way decision
// --------------------------------------------------------------------------

PL_TEST(AnEmptyCacheRebuilds) {
    // First render after the effect is applied, and after a GPU device setdown,
    // and on a fresh MFR worker. All ordinary; all correctly answered by building
    // the thing rather than by reporting an error.
    const FieldCache cache;
    PL_CHECK(cache.decide(keyOf(1, 1)) == Decision::RebuildField);
}

PL_TEST(TheSameKeyTwiceAccumulates) {
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    PL_CHECK(cache.decide(keyOf(7, 3)) == Decision::Accumulate);
}

PL_TEST(CameraMoveKeepsTheField) {
    // THE ROW THIS CLASS EXISTS FOR. Same field, different view: the medium is
    // still the same sky, so it must survive and only the accumulator is cleared.
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    PL_CHECK(cache.decide(keyOf(7, 4)) == Decision::RestartSamples);
}

PL_TEST(AFieldEditRebuilds) {
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    PL_CHECK(cache.decide(keyOf(8, 3)) == Decision::RebuildField);
}

PL_TEST(AFieldEditRebuildsEvenWhenTheViewAlsoChanged) {
    // Both halves different is still a rebuild and not a restart -- the rebuild
    // subsumes it. Worth pinning because a decide() written as two independent
    // ifs in the wrong order returns RestartSamples here and then renders the old
    // sky from the new camera.
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    PL_CHECK(cache.decide(keyOf(8, 4)) == Decision::RebuildField);
}

PL_TEST(DecideDoesNotChangeState) {
    // A render that fails part way must be retried, not remembered as done. So
    // asking the question cannot be what answers it.
    FieldCache cache;
    PL_CHECK(cache.decide(keyOf(1, 1)) == Decision::RebuildField);
    PL_CHECK(cache.decide(keyOf(1, 1)) == Decision::RebuildField);
}

// --------------------------------------------------------------------------
// Sample accounting
// --------------------------------------------------------------------------

PL_TEST(AdoptResetsTheSampleCount) {
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    cache.addSamples(keyOf(7, 3), 16);
    PL_CHECK_EQ(cache.samples(), 16);

    cache.adopt(keyOf(7, 4));
    PL_CHECK_EQ(cache.samples(), 0);
}

PL_TEST(SamplesAccumulateAcrossLaunches) {
    // One launch per batch is a Windows TDR mitigation before it is a quality
    // feature -- the driver's timeout is about two seconds and a full-quality
    // frame sits right on it -- so many small batches adding up correctly is the
    // normal path, not an edge case.
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    for (int i = 0; i < 8; ++i) cache.addSamples(keyOf(7, 3), 4);
    PL_CHECK_EQ(cache.samples(), 32);
}

PL_TEST(SamplesFromAStaleLaunchAreDropped) {
    // A batch launched before the user let go of a slider finishes after the
    // parameters it was launched for stopped being current. Crediting it would
    // average two different skies together, and the frame would then never look
    // right at any sample count.
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    cache.addSamples(keyOf(7, 3), 4);

    cache.adopt(keyOf(9, 3));                 // the sky changed
    cache.addSamples(keyOf(7, 3), 4);         // the old launch lands late
    PL_CHECK_EQ(cache.samples(), 0);
}

PL_TEST(ConvergenceNeedsTheRequestedCount) {
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    cache.addSamples(keyOf(7, 3), 32);
    PL_CHECK(!cache.converged(64));
    cache.addSamples(keyOf(7, 3), 32);
    PL_CHECK(cache.converged(64));
}

PL_TEST(AClearedCacheIsNotConverged) {
    FieldCache cache;
    cache.adopt(keyOf(7, 3));
    cache.addSamples(keyOf(7, 3), 1000);
    cache.clear();
    PL_CHECK(!cache.converged(1));
    PL_CHECK(cache.decide(keyOf(7, 3)) == Decision::RebuildField);
}

// --------------------------------------------------------------------------
// viewHash: what restarts accumulation and what does not
// --------------------------------------------------------------------------

PL_TEST(RaisingSampleCountDoesNotRestartAccumulation) {
    // The user asked for a more converged version of the same image. Clearing the
    // buffer would throw away exactly the work they asked to add to.
    const ViewParams v;
    QualityParams low, high;
    low.samplesPerPixel  = 64;
    high.samplesPerPixel = 512;
    PL_CHECK_EQ(samplingHash(v, low), samplingHash(v, high));
}

PL_TEST(ResizingTheLaunchBatchDoesNotRestartAccumulation) {
    // samplesPerLaunch only decides how the work is chopped up to stay under the
    // driver timeout. Chopping it differently cannot change the answer.
    const ViewParams v;
    QualityParams a, b;
    a.samplesPerLaunch = 4;
    b.samplesPerLaunch = 16;
    PL_CHECK_EQ(samplingHash(v, a), samplingHash(v, b));
}

PL_TEST(ChangingBounceDepthRestartsAccumulation) {
    // This one changes the image, so the samples already taken are samples of a
    // different image. The field is untouched, which is why it is a restart and
    // not a rebuild.
    const ViewParams v;
    QualityParams shallow, deep;
    shallow.maxBounces = 8;
    deep.maxBounces    = 32;
    PL_CHECK(samplingHash(v, shallow) != samplingHash(v, deep));
}

PL_TEST(APureCameraRotationRestartsAccumulation) {
    // Hashing only the translation would miss this, and a pure orbit is the most
    // common camera move there is.
    const QualityParams q;
    ViewParams a;
    ViewParams b = a;
    b.cameraToWorld[0] = 0.0f;
    b.cameraToWorld[2] = 1.0f;
    PL_CHECK(samplingHash(a, q) != samplingHash(b, q));
}

// ===========================================================================
// EXPOSURE IS NOT A SAMPLING INPUT, AND THIS TEST USED TO ASSERT THAT IT WAS.
//
// The old version was called ExposureIsPartOfTheViewHash and argued that exposure
// could not be a post-pass because the denoiser runs on those numbers and OIDN
// expects roughly perceptual magnitudes.
//
// THAT ARGUMENT WAS RIGHT AND IS NOW SATISFIED SOMEWHERE ELSE. It constrains the
// ORDER inside the resolve pass -- mean, exposure, denoise, tonemap, encode -- not
// whether exposure decides which rays get traced. Nothing about exposure changes the
// radiance that comes back along a ray.
//
// WHAT CHANGED TO MAKE THE SPLIT POSSIBLE was lifting applyOutputTransform out of
// renderPixel. While it ran per sample, the accumulator held exposed values and there
// was nothing linear left to re-expose, so exposure genuinely did have to restart the
// samples. It no longer does.
// ===========================================================================
PL_TEST(ExposureDoesNotRestartTheSamples) {
    const QualityParams q;
    ViewParams a;
    ViewParams b = a;
    b.exposureEV = 1.5f;

    // Same rays, so the accumulated samples are still exactly right.
    PL_CHECK_EQ(samplingHash(a, q), samplingHash(b, q));

    // ...but a different picture comes out of them.
    PL_CHECK(resolveHash(a, q) != resolveHash(b, q));
}

PL_TEST(TheTonemapAndTheEncodingAreResolveOnlyToo) {
    ViewParams base;
    const QualityParams q;

    ViewParams tonemapped = base;
    tonemapped.agxTonemap = !base.agxTonemap;
    PL_CHECK(resolveHash(base, q) != resolveHash(tonemapped, q));

    ViewParams unencoded = base;
    unencoded.encodeSrgb = !base.encodeSrgb;
    PL_CHECK(resolveHash(base, q) != resolveHash(unencoded, q));

    PL_CHECK_EQ(samplingHash(base, q), samplingHash(tonemapped, q));
    PL_CHECK_EQ(samplingHash(base, q), samplingHash(unencoded, q));
}

// THE CAMERA MUST NOT LEAK INTO THE RESOLVE HASH. If it did, a camera move would
// report ResolveOnly -- re-exposing a buffer full of the old camera's pixels, which
// is a picture of neither view and would read as a caching bug months later.
PL_TEST(TheResolveHashIgnoresEverythingThatDecidesARay) {
    ViewParams base;

    ViewParams moved = base;
    moved.cameraToWorld[3] += 100.0f;
    moved.verticalFovDegrees += 5.0f;
    moved.widthPx = 640;
    moved.heightPx = 360;
    moved.originX = 17;
    moved.cameraFromComp = !base.cameraFromComp;

    const QualityParams q;
    PL_CHECK_EQ(resolveHash(base, q), resolveHash(moved, q));
}

// ===========================================================================
// THE DENOISER IS A RESOLVE INPUT, AND IT WAS A SAMPLING ONE UNTIL 2026-09-29.
//
// The integration that landed filters the finished colour ALONE -- no auxiliary albedo
// or normal buffers, which would be written while tracing -- so neither the switch nor
// the amount changes a single sample. With them in the sampling hash, every drag of the
// Denoise Amount slider threw the frame away and traced it again, which at a final-
// quality sample count is seconds per nudge on the one control a user tunes by eye.
//
// BOTH HALVES ARE ASSERTED. That the sampling hash IGNORES them is the performance
// claim; that the resolve hash SEES them is the correctness one -- a resolve input left
// out of every hash is a slider that moves with nothing re-rendering at all.
//
// IF AUXILIARY BUFFERS ARE EVER ADDED, THIS TEST IS SUPPOSED TO FAIL. Those are written
// during tracing, and a denoise that wants them is a sampling input again.
// ===========================================================================
PL_TEST(TheDenoiserIsAResolveInputNotASamplingOne) {
    const ViewParams v;

    QualityParams base;
    base.denoise = true;
    base.denoiseAmount = 0.8f;

    QualityParams off = base;
    off.denoise = false;

    QualityParams amount = base;
    amount.denoiseAmount = 0.5f;

    PL_CHECK_EQ(samplingHash(v, base), samplingHash(v, off));
    PL_CHECK_EQ(samplingHash(v, base), samplingHash(v, amount));

    PL_CHECK(resolveHash(v, base) != resolveHash(v, off));
    PL_CHECK(resolveHash(v, base) != resolveHash(v, amount));
}

// --------------------------------------------------------------------------
// ResolveOnly, the decision the split exists to produce
// --------------------------------------------------------------------------

PL_TEST(AnExposureChangeResolvesRatherThanRestarting) {
    FieldCache cache;
    cache.adopt(keyOf(1, 2, 100));
    cache.addSamples(keyOf(1, 2, 100), 32);

    const Decision d = cache.decide(keyOf(1, 2, 200));
    PL_CHECK_EQ(d == Decision::ResolveOnly, 1);
}

// THE SAMPLES SURVIVE IT, which is the entire point. adopt() would zero them.
PL_TEST(AResolveKeepsTheSamplesItWasCollected) {
    FieldCache cache;
    cache.adopt(keyOf(1, 2, 100));
    cache.addSamples(keyOf(1, 2, 100), 32);

    cache.adoptResolve(keyOf(1, 2, 200));
    PL_CHECK_EQ(cache.samples(), 32);

    // And the cache now agrees it is up to date at the new exposure.
    PL_CHECK_EQ(cache.decide(keyOf(1, 2, 200)) == Decision::Accumulate, 1);
}

// SAMPLES STILL LAND WHEN ONLY THE EXPOSURE MOVED UNDER THEM. A batch launched
// before the slider moved holds exactly the right radiance for the new exposure --
// that is what makes it a resolve. Dropping it would undo the split.
PL_TEST(SamplesInFlightSurviveAnExposureChange) {
    FieldCache cache;
    cache.adopt(keyOf(1, 2, 100));
    cache.addSamples(keyOf(1, 2, 999), 16);
    PL_CHECK_EQ(cache.samples(), 16);
}

// ...BUT A CAMERA MOVE UNDER THEM STILL DROPS THEM.
PL_TEST(SamplesInFlightDoNotSurviveACameraMove) {
    FieldCache cache;
    cache.adopt(keyOf(1, 2, 100));
    cache.addSamples(keyOf(1, 3, 100), 16);
    PL_CHECK_EQ(cache.samples(), 0);
}

// ===========================================================================
// WHEN BOTH MOVED, THE SAMPLING HALF WINS. This is the ordering inside decide(),
// asserted rather than left to the reading: an exposure drag that also nudged the
// camera must re-trace, not re-expose the old camera's pixels.
// ===========================================================================
PL_TEST(ACameraMoveBeatsAnExposureChange) {
    FieldCache cache;
    cache.adopt(keyOf(1, 2, 100));

    PL_CHECK_EQ(cache.decide(keyOf(1, 3, 200)) == Decision::RestartSamples, 1);

    // And a field edit beats both.
    PL_CHECK_EQ(cache.decide(keyOf(9, 3, 200)) == Decision::RebuildField, 1);
}

// A RESOLVE FOR A DIFFERENT SAMPLING KEY IS IGNORED, for the same reason a stale
// batch of samples is: it describes a picture the buffer no longer holds.
PL_TEST(AStaleResolveIsIgnored) {
    FieldCache cache;
    cache.adopt(keyOf(1, 2, 100));
    cache.addSamples(keyOf(1, 2, 100), 8);

    cache.adoptResolve(keyOf(1, 77, 200));   // different camera

    // The cache still describes the render it actually holds.
    PL_CHECK_EQ(cache.samples(), 8);
    PL_CHECK_EQ(cache.decide(keyOf(1, 2, 100)) == Decision::Accumulate, 1);
}

PL_TEST(GainingACompCameraRestartsAccumulation) {
    // A comp with no camera gets a default matrix. If it later gains one that
    // happens to match, the render must still restart -- and docs/HOST-NOTES.md
    // is explicit that "no camera, defaulting" and "the call failed" have to stay
    // distinguishable rather than both collapsing to the same state.
    const QualityParams q;
    ViewParams defaulted;
    ViewParams real = defaulted;
    real.cameraFromComp = true;
    PL_CHECK(samplingHash(defaulted, q) != samplingHash(real, q));
}

PL_TEST(ResizingTheOutputRestartsAccumulation) {
    const QualityParams q;
    ViewParams full;
    ViewParams half = full;
    half.widthPx  = 960;
    half.heightPx = 540;
    PL_CHECK(samplingHash(full, q) != samplingHash(half, q));
}

// ===========================================================================
// AccumulatorCache -- the question the render loop actually asks.
//
// EACH TEST BELOW IS ONE CONDITION OF canResolve(), and each condition guards a picture
// that would render plausibly and be wrong. None of them can be seen from a still in
// After Effects: a resolve from the wrong buffer looks like a rendered frame. So they
// are pinned here, where a failure names the condition rather than the symptom.
// ===========================================================================

namespace {
constexpr int32_t kW = 1920, kH = 1080, kPitch = 1920, kSpp = 64;
}

// NOTHING IS RESOLVED UNTIL A WHOLE FRAME HAS BEEN CREDITED. The first render after the
// effect is applied, a fresh MFR worker, and every render after an invalidate() all
// land here -- and all must trace.
PL_TEST(AnEmptyAccumulatorCacheNeverResolves) {
    AccumulatorCache c;
    PL_CHECK(!c.canResolve(keyOf(1, 2, 3), kSpp, kW, kH, kPitch));
}

// THE CASE THE WHOLE THING EXISTS FOR: an exposure or denoise-amount drag.
PL_TEST(AResolveOnlyChangeResolvesFromACreditedFrame) {
    AccumulatorCache c;
    c.adoptFull(keyOf(1, 2, 3), kSpp, kW, kH, kPitch);

    PL_CHECK(c.canResolve(keyOf(1, 2, 99), kSpp, kW, kH, kPitch));  // resolve key moved
    PL_CHECK(c.canResolve(keyOf(1, 2, 3),  kSpp, kW, kH, kPitch));  // nothing moved
}

// ANOTHER SKY OR ANOTHER VIEW: the buffer holds samples of a different integral.
PL_TEST(AFieldOrSamplingChangeNeverResolves) {
    AccumulatorCache c;
    c.adoptFull(keyOf(1, 2, 3), kSpp, kW, kH, kPitch);

    PL_CHECK(!c.canResolve(keyOf(9, 2, 3), kSpp, kW, kH, kPitch));  // new field -- next frame
    PL_CHECK(!c.canResolve(keyOf(1, 9, 3), kSpp, kW, kH, kPitch));  // camera moved
}

// ===========================================================================
// EXACTLY THE SAMPLE COUNT, NOT "AT LEAST", AND BOTH DIRECTIONS ARE ASSERTED.
//
// FEWER is obvious: 32 accumulated samples cannot stand in for 64.
//
// MORE is the one that looks harmless and is not. Resolving 128 samples for a frame
// asked at 64 gives a CLEANER picture -- and a frame whose noise depends on what this
// thread happened to render before it. Under multi-frame rendering, neighbouring frames
// land on different workers with different histories, so the render queue would come
// back with frames at different noise levels for no visible reason.
// ===========================================================================
PL_TEST(TheSampleCountMustMatchExactlyInBothDirections) {
    AccumulatorCache c;
    c.adoptFull(keyOf(1, 2, 3), kSpp, kW, kH, kPitch);

    PL_CHECK(!c.canResolve(keyOf(1, 2, 3), kSpp * 2, kW, kH, kPitch));
    PL_CHECK(!c.canResolve(keyOf(1, 2, 3), kSpp / 2, kW, kH, kPitch));
}

// ===========================================================================
// THE PITCH IS IN NO HASH, SO THIS IS THE ONLY THING THAT CATCHES IT.
//
// The accumulator is indexed row * pitch. AE's rowbytes can differ between two renders
// of the same frame, and width, height and origin are all identical in that case -- so
// every hash matches. A resolve at the new pitch reads each row at the old stride: the
// picture shears diagonally, and it would be read as a camera bug.
// ===========================================================================
PL_TEST(ADifferentPitchNeverResolvesEvenWithEveryHashMatching) {
    AccumulatorCache c;
    c.adoptFull(keyOf(1, 2, 3), kSpp, kW, kH, kPitch);

    PL_CHECK(!c.canResolve(keyOf(1, 2, 3), kSpp, kW, kH, kPitch + 64));
    PL_CHECK(!c.canResolve(keyOf(1, 2, 3), kSpp, kW, kH + 1, kPitch));
    PL_CHECK(!c.canResolve(keyOf(1, 2, 3), kSpp, kW - 1, kH, kPitch));
}

// INVALIDATE IS WHAT A FULL RENDER CALLS BEFORE IT WRITES. A render that then falls
// back to the other engine or is aborted never reaches the credit, so the cache must
// already have stopped vouching -- or the next render resolves from half a frame.
PL_TEST(InvalidateStopsVouchingImmediately) {
    AccumulatorCache c;
    c.adoptFull(keyOf(1, 2, 3), kSpp, kW, kH, kPitch);
    PL_CHECK(c.canResolve(keyOf(1, 2, 3), kSpp, kW, kH, kPitch));

    c.invalidate();
    PL_CHECK(!c.canResolve(keyOf(1, 2, 3), kSpp, kW, kH, kPitch));
    PL_CHECK_EQ(c.samples(), 0);
}

// A RESOLVE KEEPS THE SAMPLES, so a second drag resolves again rather than tracing.
// That is the difference between a slider that stays fast and one that is fast once.
PL_TEST(ASecondResolveStillResolves) {
    AccumulatorCache c;
    c.adoptFull(keyOf(1, 2, 3), kSpp, kW, kH, kPitch);

    PL_CHECK(c.canResolve(keyOf(1, 2, 4), kSpp, kW, kH, kPitch));
    c.adoptResolve(keyOf(1, 2, 4));

    PL_CHECK(c.canResolve(keyOf(1, 2, 5), kSpp, kW, kH, kPitch));
    PL_CHECK_EQ(c.samples(), kSpp);
}
