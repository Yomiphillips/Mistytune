#include "FieldCache.h"

#include "Fingerprint.h"

namespace plugin::sim {

using namespace plugin::cloud;

uint64_t samplingHash(const ViewParams& v, const QualityParams& q) {
    Fingerprint fp;

    // THE CAMERA MATRIX, ALL SIXTEEN. Hashing only the translation would miss a
    // pure rotation, which is the most common camera move there is.
    for (int i = 0; i < 16; ++i) fp.add(v.cameraToWorld[i]);

    // Whether the matrix came from a real comp camera is part of the view: a comp
    // that gains a camera should re-render even if the default matrix happened to
    // match it. docs/HOST-NOTES.md is clear that "no camera, defaulting" and "the
    // call failed" must stay distinguishable, and this keeps them so.
    fp.add(v.cameraFromComp);

    fp.add(v.verticalFovDegrees);
    fp.add(v.observerAltitude);
    fp.add(v.widthPx);
    fp.add(v.heightPx);

    // THE WINDOW'S ORIGIN IS PART OF THE VIEW. Two renders of the same frame through
    // different windows contain different pixels, so an accumulation cannot be
    // carried from one to the other -- which is exactly what this hash decides.
    fp.add(v.originX);
    fp.add(v.originY);

    // EXPOSURE, TONEMAP AND ENCODING USED TO BE HERE AND ARE NOW IN resolveHash.
    //
    // They are not sampling inputs: none of them changes which ray is traced or what
    // radiance comes back. What kept them here was that applyOutputTransform ran
    // INSIDE renderPixel, so the accumulator held exposed values and there was
    // nothing linear left to re-expose. That is no longer true -- see the header.
    //
    // THE OLD COMMENT'S OIDN ARGUMENT SURVIVES INTACT and now constrains the resolve
    // pass's internal order rather than this hash: mean, then exposure, then denoise,
    // then tonemap and encode. The denoiser still sees exposed values.

    // See the header for why maxBounces is here and samplesPerPixel is not.
    fp.add(q.maxBounces);
    fp.add(q.densityMajorant);

    // DENOISE IS A SAMPLING INPUT AND NOT A RESOLVE ONE, which looks wrong at first
    // glance and is not. Turning the denoiser on does not change the radiance, so it
    // could be a resolve -- but OIDN needs auxiliary albedo and normal buffers that
    // the renderer only fills when it knows they are wanted, and those are written
    // while tracing. Enabling it therefore needs samples that do not exist yet.
    //
    // WHEN THE AUXILIARY BUFFERS ARE ALWAYS WRITTEN, this moves to resolveHash and
    // toggling the denoiser becomes free. That is a decision to take when OIDN lands
    // and the cost of always writing them is measurable, not now.
    fp.add(q.denoise);

    return fp.value();
}

uint64_t resolveHash(const ViewParams& v) {
    Fingerprint fp;

    // ALL THREE STAGES OF applyOutputTransform, and nothing else. If a fourth stage
    // is ever added to that function it belongs here too -- the invariant is that
    // this hash covers exactly the inputs the resolve pass reads.
    fp.add(v.exposureEV);
    fp.add(v.agxTonemap);
    fp.add(v.encodeSrgb);

    return fp.value();
}

Decision FieldCache::decide(const RenderKey& k) const {
    // NOTHING CACHED IS A REBUILD, not an error. First render after the effect is
    // applied, after a GPU device setdown, or on a fresh MFR worker -- all
    // ordinary, and all correctly answered by building the thing.
    if (!m_valid)                     return Decision::RebuildField;
    if (m_key.field    != k.field)    return Decision::RebuildField;
    if (m_key.sampling != k.sampling) return Decision::RestartSamples;

    // ORDERED CHEAPEST-LAST, AND THE ORDER IS LOAD-BEARING. A render whose camera
    // AND exposure both moved must restart the samples, not merely resolve them --
    // so the sampling test has to come first and win. Reversing these two would
    // re-expose a buffer full of the old camera's pixels, which is a picture of
    // neither view and would read as a caching bug months later.
    if (m_key.resolve != k.resolve)   return Decision::ResolveOnly;

    return Decision::Accumulate;
}

void FieldCache::adopt(const RenderKey& k) {
    m_key     = k;
    m_valid   = true;
    m_samples = 0;
}

void FieldCache::adoptResolve(const RenderKey& k) {
    if (!m_valid) return;
    if (m_key.field != k.field || m_key.sampling != k.sampling) return;

    // THE SAMPLE COUNT IS UNTOUCHED, which is the whole reason this is not adopt().
    m_key.resolve = k.resolve;
}

void FieldCache::addSamples(const RenderKey& k, int32_t count) {
    // THE KEY CHECK IS THE POINT OF THIS FUNCTION, not a guard clause on it.
    //
    // A launch is in flight while the user is still dragging a slider, so a batch
    // can finish AFTER the parameters it was launched for stopped being current.
    // Crediting those samples to the new key would average two different skies
    // together and the frame would never look right at any sample count. Dropping
    // them costs one batch of work and keeps the estimator honest.
    // THE RESOLVE HALF IS DELIBERATELY NOT CHECKED. A batch launched before the
    // exposure slider moved contains exactly the right radiance for the new exposure
    // too -- that is what makes it a resolve rather than a restart. Requiring the
    // resolve keys to match would throw those samples away and undo the split.
    if (!m_valid || m_key.field != k.field || m_key.sampling != k.sampling) return;
    if (count <= 0) return;
    m_samples += count;
}

void FieldCache::clear() {
    m_valid   = false;
    m_key     = RenderKey{};
    m_samples = 0;
}

} // namespace plugin::sim
