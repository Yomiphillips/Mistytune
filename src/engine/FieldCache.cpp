#include "FieldCache.h"

#include "Fingerprint.h"

namespace plugin::sim {

using namespace plugin::cloud;

uint64_t viewHash(const ViewParams& v, const QualityParams& q) {
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

    // EXPOSURE AND TONEMAP ARE IN HERE RATHER THAN APPLIED AFTERWARDS, which is
    // worth a word because it looks like a missed optimisation.
    //
    // They could be a post-pass over the accumulated buffer, and then changing
    // them would not even restart accumulation. They are not, because the
    // accumulation buffer is linear radiance and the denoiser runs on it: OIDN is
    // trained on roughly perceptual magnitudes, so the exposure the user chose
    // has to be in the numbers before the denoiser sees them, or the denoising
    // strength silently tracks the exposure slider.
    fp.add(v.exposureEV);
    fp.add(v.agxTonemap);

    // See the header for why maxBounces is here and samplesPerPixel is not.
    fp.add(q.maxBounces);
    fp.add(q.densityMajorant);
    fp.add(q.denoise);

    return fp.value();
}

Decision FieldCache::decide(const RenderKey& k) const {
    // NOTHING CACHED IS A REBUILD, not an error. First render after the effect is
    // applied, after a GPU device setdown, or on a fresh MFR worker -- all
    // ordinary, and all correctly answered by building the thing.
    if (!m_valid)              return Decision::RebuildField;
    if (m_key.field != k.field) return Decision::RebuildField;
    if (m_key.view  != k.view)  return Decision::RestartSamples;
    return Decision::Accumulate;
}

void FieldCache::adopt(const RenderKey& k) {
    m_key     = k;
    m_valid   = true;
    m_samples = 0;
}

void FieldCache::addSamples(const RenderKey& k, int32_t count) {
    // THE KEY CHECK IS THE POINT OF THIS FUNCTION, not a guard clause on it.
    //
    // A launch is in flight while the user is still dragging a slider, so a batch
    // can finish AFTER the parameters it was launched for stopped being current.
    // Crediting those samples to the new key would average two different skies
    // together and the frame would never look right at any sample count. Dropping
    // them costs one batch of work and keeps the estimator honest.
    if (!m_valid || m_key.field != k.field || m_key.view != k.view) return;
    if (count <= 0) return;
    m_samples += count;
}

void FieldCache::clear() {
    m_valid   = false;
    m_key     = RenderKey{};
    m_samples = 0;
}

} // namespace plugin::sim
