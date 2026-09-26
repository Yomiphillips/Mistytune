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

RenderKey keyOf(uint64_t field, uint64_t view) {
    RenderKey k;
    k.field = field;
    k.view  = view;
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
    PL_CHECK_EQ(viewHash(v, low), viewHash(v, high));
}

PL_TEST(ResizingTheLaunchBatchDoesNotRestartAccumulation) {
    // samplesPerLaunch only decides how the work is chopped up to stay under the
    // driver timeout. Chopping it differently cannot change the answer.
    const ViewParams v;
    QualityParams a, b;
    a.samplesPerLaunch = 4;
    b.samplesPerLaunch = 16;
    PL_CHECK_EQ(viewHash(v, a), viewHash(v, b));
}

PL_TEST(ChangingBounceDepthRestartsAccumulation) {
    // This one changes the image, so the samples already taken are samples of a
    // different image. The field is untouched, which is why it is a restart and
    // not a rebuild.
    const ViewParams v;
    QualityParams shallow, deep;
    shallow.maxBounces = 8;
    deep.maxBounces    = 32;
    PL_CHECK(viewHash(v, shallow) != viewHash(v, deep));
}

PL_TEST(APureCameraRotationRestartsAccumulation) {
    // Hashing only the translation would miss this, and a pure orbit is the most
    // common camera move there is.
    const QualityParams q;
    ViewParams a;
    ViewParams b = a;
    b.cameraToWorld[0] = 0.0f;
    b.cameraToWorld[2] = 1.0f;
    PL_CHECK(viewHash(a, q) != viewHash(b, q));
}

PL_TEST(ExposureIsPartOfTheViewHash) {
    // It could have been a post-pass over the accumulated buffer, in which case
    // it would restart nothing. It is not, because the denoiser runs on those
    // numbers and OIDN expects roughly perceptual magnitudes -- so the exposure
    // has to be baked in before it sees them.
    const QualityParams q;
    ViewParams a;
    ViewParams b = a;
    b.exposureEV = 1.5f;
    PL_CHECK(viewHash(a, q) != viewHash(b, q));
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
    PL_CHECK(viewHash(defaulted, q) != viewHash(real, q));
}

PL_TEST(ResizingTheOutputRestartsAccumulation) {
    const QualityParams q;
    ViewParams full;
    ViewParams half = full;
    half.widthPx  = 960;
    half.heightPx = 540;
    PL_CHECK(viewHash(full, q) != viewHash(half, q));
}
