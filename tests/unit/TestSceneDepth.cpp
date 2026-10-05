// Scene integration (build 30): a depth pass of the footage stops the camera ray at its
// geometry -- holdout and composite. See src/engine/SceneDepth.h.
//
// THE CLAIMS THAT MATTER, and none of them can be seen by looking:
//
//   * THE ALGEBRA. The holdout's premultiplied colour laid over what lies behind the
//     geometry must give back the render without it. Checked end to end through the CPU
//     kernel, with the geometry pushed past the atmosphere and a clear sky behind it: the
//     clouds' transmittance, the airlight taken back off and the alpha all have to be right
//     for the sum to close.
//   * GEOMETRY IN FRONT OF EVERYTHING IS EXACTLY TRANSPARENT AND EXACTLY BLACK -- a building
//     with nothing in front of it must leave the footage untouched, not lay a haze on it.
//   * A HALF-COVERED TEXEL IS HALF GEOMETRY, so a soft key edge is a soft holdout edge.
//   * The depth pass reads as its encoding says, with the open sky cut off at its far end.
//   * Composite is AE's own normal blend.

#include "TestFramework.h"

#include "KernelApi.h"
#include "SceneDepth.h"

#include <cmath>
#include <vector>

using namespace plugin;
using namespace plugin::cloud;

namespace {

// A ShapeImage-like float ARGB picture for buildSceneDepthMap.
struct Picture {
    int w = 0, h = 0;
    std::vector<float> argb;
    Picture(int w_, int h_) : w(w_), h(h_), argb(static_cast<size_t>(w_) * h_ * 4, 0.0f) {}
    void set(int x, int y, float a, float v) {
        float* p = &argb[(static_cast<size_t>(y) * w + x) * 4];
        p[0] = a; p[1] = p[2] = p[3] = v * a;   // premultiplied, as AE's buffers are
    }
    ConstImageView view() const {
        ConstImageView v;
        v.data = argb.data();
        v.width = w;
        v.height = h;
        v.rowBytes = static_cast<std::ptrdiff_t>(w) * 4 * sizeof(float);
        v.format = PixelFormat::ARGB32F;
        return v;
    }
};

// A uniform depth map: every texel at `metres`, with `coverage`.
SceneDepthMap uniformMap(int w, int h, float metres, float coverage) {
    SceneDepthMap m;
    m.width = w;
    m.height = h;
    m.texels.resize(static_cast<size_t>(w) * h * 2);
    for (size_t q = 0; q < static_cast<size_t>(w) * h; ++q) {
        m.texels[q * 2 + 0] = metres;
        m.texels[q * 2 + 1] = coverage;
    }
    m.geometryTexels = w * h;
    m.hash = 0x5eedull + static_cast<uint64_t>(metres) + static_cast<uint64_t>(coverage * 1000.0f);
    return m;
}

constexpr int kW = 24, kH = 12;

// The test frame: the default sky, looking 40 degrees up through the cirrus, rendered on the
// CPU into a linear ARGB buffer -- no transform, so the numbers are radiance and alpha.
// THE CLOUDS ALONE (build 31): Background and Show Sun, and a sun the test can aim the
// camera at. An elevation below -90 leaves the default sun.
struct Look {
    bool  transparent = false;
    bool  showSun     = true;
    float sunAz       = 0.0f;
    float sunEl       = -100.0f;
    float sunRadius   = 0.0f;     // degrees; 0 leaves the default
};

std::vector<float> render(bool ice, const SceneDepthMap* scene, int spp,
                          bool airShadows = true, const Look& look = Look()) {
    kernel::RenderRequest req;
    req.field.ice.enabled = ice;
    req.field.atmosphere.cloudShadowsInMedium = airShadows;
    req.field.atmosphere.showSunDisc = look.showSun;
    if (look.sunEl > -90.0f) {
        req.field.atmosphere.sunAzimuth   = look.sunAz;
        req.field.atmosphere.sunElevation = look.sunEl;
    }
    if (look.sunRadius > 0.0f) req.field.atmosphere.sunAngularRadius = look.sunRadius;
    req.view.transparentSky = look.transparent;
    req.view.widthPx  = kW;
    req.view.heightPx = kH;
    const float c = std::cos(0.698132f), s = std::sin(0.698132f);
    const float m[16] = { 1, 0, 0, 0,
                          0, c, -s, 0,
                          0, s, c, 0,
                          0, 0, 0, 1 };
    for (int k = 0; k < 16; ++k) req.view.cameraToWorld[k] = m[k];
    req.quality.samplesPerPixel = spp;
    req.sceneDepth = scene;

    std::vector<float> px(static_cast<size_t>(kW) * kH * 4, 0.0f);
    req.dest.data     = px.data();
    req.dest.widthPx  = kW;
    req.dest.heightPx = kH;
    req.dest.pitchPx  = kW;
    req.dest.order    = kernel::ChannelOrder::ARGB;
    req.firstSample   = 0;
    req.sampleCount   = spp;
    kernel::renderCpu(req, 0);
    return px;
}

} // namespace

// ---------------------------------------------------------------------------
// The depth pass, read
// ---------------------------------------------------------------------------

PL_TEST(DisparityRunsFromFarthestToNearestIn1OverDistance) {
    SceneDepthParams p;
    p.encoding = DepthEncoding::DisparityNearBright;
    p.nearestM = 10.0f;
    p.farthestM = 1000.0f;
    p.skyCutoff = 0.0f;
    PL_CHECK_NEAR(sceneDepthMetres(1.0f, p), 10.0, 1e-3);
    PL_CHECK_NEAR(sceneDepthMetres(0.0f, p), 1000.0, 1e-2);
    // Halfway in brightness is halfway in 1/distance: 1 / ((0.1 + 0.001) / 2).
    PL_CHECK_NEAR(sceneDepthMetres(0.5f, p), 1.0 / 0.0505, 1e-2);
}

PL_TEST(LinearEncodingsRunEitherWay) {
    SceneDepthParams p;
    p.nearestM = 100.0f;
    p.farthestM = 300.0f;
    p.skyCutoff = 0.0f;
    p.encoding = DepthEncoding::LinearNearBright;
    PL_CHECK_NEAR(sceneDepthMetres(1.0f, p), 100.0, 1e-3);
    PL_CHECK_NEAR(sceneDepthMetres(0.25f, p), 250.0, 1e-3);
    p.encoding = DepthEncoding::LinearFarBright;
    PL_CHECK_NEAR(sceneDepthMetres(0.0f, p), 100.0, 1e-3);
    PL_CHECK_NEAR(sceneDepthMetres(0.25f, p), 150.0, 1e-3);
}

PL_TEST(TheFarEndIsOpenSky) {
    SceneDepthParams p;
    p.skyCutoff = 0.05f;
    p.encoding = DepthEncoding::DisparityNearBright;
    PL_CHECK(sceneDepthMetres(0.0f, p) == 0.0f);
    PL_CHECK(sceneDepthMetres(0.05f, p) == 0.0f);
    PL_CHECK(sceneDepthMetres(0.06f, p) > 0.0f);
    // Just past the cutoff is Farthest, not a jump to the middle of the range. Linear here:
    // a disparity is steep at its far end -- 0.0001 past the cutoff is already 2% nearer.
    p.encoding = DepthEncoding::LinearNearBright;
    PL_CHECK_NEAR(sceneDepthMetres(0.0501f, p), p.farthestM, p.farthestM * 0.01);
    p.encoding = DepthEncoding::LinearFarBright;
    PL_CHECK(sceneDepthMetres(1.0f, p) == 0.0f);
    PL_CHECK(sceneDepthMetres(0.9f, p) > 0.0f);
    PL_CHECK_NEAR(sceneDepthMetres(0.0f, p), p.nearestM, 1e-3);
}

PL_TEST(TheMapKeepsAlphaAsCoverageAndReadsTheStraightColour) {
    SceneDepthParams p;
    p.encoding = DepthEncoding::LinearNearBright;
    p.nearestM = 10.0f;
    p.farthestM = 110.0f;
    p.skyCutoff = 0.02f;
    Picture pic(3, 1);
    pic.set(0, 0, 1.0f, 0.0f);    // open sky
    pic.set(1, 0, 0.5f, 0.51f);   // a soft edge: half there, at the straight value 0.51
    pic.set(2, 0, 0.0f, 0.0f);    // no alpha: nothing
    SceneDepthMap m;
    PL_CHECK(buildSceneDepthMap(pic.view(), p, m));
    PL_CHECK_EQ(m.geometryTexels, 1);
    PL_CHECK(m.texels[0] == 0.0f && m.texels[1] == 0.0f);
    PL_CHECK_NEAR(m.texels[3], 0.5, 1e-6);
    PL_CHECK_NEAR(m.texels[2], sceneDepthMetres(0.51f, p), 1e-3);   // not darker for the alpha
    PL_CHECK(m.texels[4] == 0.0f && m.texels[5] == 0.0f);
}

PL_TEST(AnAllSkyPassIsNoScene) {
    SceneDepthParams p;
    Picture pic(4, 4);
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 4; ++x) pic.set(x, y, 1.0f, 0.01f);
    SceneDepthMap m;
    PL_CHECK(!buildSceneDepthMap(pic.view(), p, m));
    PL_CHECK(m.empty());
}

PL_TEST(TheHashFollowsTheDepths) {
    SceneDepthParams p;
    Picture a(4, 4), b(4, 4);
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 4; ++x) { a.set(x, y, 1.0f, 0.5f); b.set(x, y, 1.0f, 0.5f); }
    b.set(2, 2, 1.0f, 0.6f);
    SceneDepthMap ma, mb, ma2;
    buildSceneDepthMap(a.view(), p, ma);
    buildSceneDepthMap(b.view(), p, mb);
    buildSceneDepthMap(a.view(), p, ma2);
    PL_CHECK(ma.hash != mb.hash);
    PL_CHECK_EQ(ma.hash, ma2.hash);
    // ...and so do the reading's settings, which the map bakes in.
    SceneDepthParams q = p;
    q.farthestM = p.farthestM * 2.0f;
    SceneDepthMap mq;
    buildSceneDepthMap(a.view(), q, mq);
    PL_CHECK(ma.hash != mq.hash);
}

// ---------------------------------------------------------------------------
// Composite
// ---------------------------------------------------------------------------

PL_TEST(CompositeIsAEsNormalBlend) {
    // Three pixels: opaque, half, clear. The plate is a flat 0.2 grey at alpha 1, offset so
    // the third output pixel falls off it.
    std::vector<float> out = { 1.0f, 0.9f, 0.8f, 0.7f,
                               0.5f, 0.3f, 0.3f, 0.3f,
                               0.0f, 0.0f, 0.0f, 0.0f };
    Picture plate(3, 1);
    for (int x = 0; x < 3; ++x) plate.set(x, 0, 1.0f, 0.2f);
    compositeOverPlate(out.data(), 3, 1, 3, plate.view(), 1, 0);
    PL_CHECK(out[0] == 1.0f && out[1] == 0.9f);                // opaque: untouched
    PL_CHECK_NEAR(out[4], 1.0, 1e-6);                         // 0.5 + 1 x 0.5
    PL_CHECK_NEAR(out[5], 0.3 + 0.2 * 0.5, 1e-6);
    PL_CHECK(out[8] == 0.0f && out[9] == 0.0f);                // off the plate: transparent
}

// ---------------------------------------------------------------------------
// Through the kernel
// ---------------------------------------------------------------------------

PL_TEST(NoDepthPassIsOpaque) {
    const std::vector<float> n = render(true, nullptr, 4);
    for (int q = 0; q < kW * kH; ++q) PL_CHECK(n[q * 4] == 1.0f);
}

PL_TEST(GeometryInFrontOfEverythingIsExactlyTransparentAndBlack) {
    // One metre from the lens: no cloud and no measurable air in front of it. Whatever the
    // footage is, it must come through untouched.
    const SceneDepthMap near = uniformMap(8, 4, 1.0f, 1.0f);
    const std::vector<float> g = render(true, &near, 8);
    for (int q = 0; q < kW * kH; ++q) {
        PL_CHECK(g[q * 4 + 0] == 0.0f);
        PL_CHECK(g[q * 4 + 1] == 0.0f && g[q * 4 + 2] == 0.0f && g[q * 4 + 3] == 0.0f);
    }
}

PL_TEST(TheHoldoutOverWhatIsBehindItIsTheRender) {
    // THE ALGEBRA, END TO END. The geometry stands past the top of the atmosphere, so behind it
    // is exactly the clear sky. Holdout colour F with alpha a, laid over that clear sky S in
    // linear light, must give back N, the render with no depth pass: F + (1 - a) S = N.
    //
    // The two renders share every random number but the airlight taken off, so the residual is
    // the difference between the sky's own march and the airlight's quadrature, not noise.
    //
    // WITHOUT THE CLOUDS' SHADOWS IN THE AIR. With them, the cirrus darkens the clear air in
    // front of the geometry, which is light taken OFF the footage: an "over" cannot say that,
    // and the holdout clamps it to nothing (finishPixel). That is a real limit of the format,
    // measured at about 5% of a clear-sky pixel under this cirrus, and not what this test is
    // about.
    const int spp = 32;
    const SceneDepthMap far = uniformMap(8, 4, 1.0e6f, 1.0f);
    const std::vector<float> n = render(true, nullptr, spp, false);
    const std::vector<float> s = render(false, nullptr, spp, false);
    const std::vector<float> g = render(true, &far, spp, false);

    double sumN = 0.0, sumC = 0.0, worst = 0.0, alphaMin = 1.0, alphaMax = 0.0;
    for (int q = 0; q < kW * kH; ++q) {
        const double a = g[q * 4];
        alphaMin = std::min(alphaMin, a);
        alphaMax = std::max(alphaMax, a);
        for (int c = 1; c < 4; ++c) {
            const double composed = g[q * 4 + c] + (1.0 - a) * s[q * 4 + c];
            sumN += n[q * 4 + c];
            sumC += composed;
            const double rel = std::fabs(composed - n[q * 4 + c]) /
                               std::max(1e-6, static_cast<double>(n[q * 4 + c]));
            worst = std::max(worst, rel);
        }
    }
    std::printf("    holdout over clear sky: frame mean %.6f vs render %.6f (%.3f%%), "
                "worst pixel %.3f%%, alpha %.3f..%.3f\n",
                sumC / (kW * kH * 3), sumN / (kW * kH * 3),
                100.0 * (sumC - sumN) / sumN, 100.0 * worst, alphaMin, alphaMax);
    PL_CHECK_NEAR(sumC / sumN, 1.0, 0.01);
    PL_CHECK(worst < 0.03);
    // The cirrus is in the frame and is not opaque: the alpha says both.
    PL_CHECK(alphaMax > 0.02);
    PL_CHECK(alphaMin < 1.0);
}

PL_TEST(AHalfCoveredTexelIsHalfGeometry) {
    // Clear sky, so a sample that misses the geometry is opaque sky and one that lands on it
    // is fully transparent: the alpha is the fraction that missed.
    const SceneDepthMap half = uniformMap(8, 4, 1.0f, 0.5f);
    const std::vector<float> g = render(false, &half, 64);
    double mean = 0.0;
    for (int q = 0; q < kW * kH; ++q) mean += g[q * 4];
    mean /= kW * kH;
    PL_CHECK_NEAR(mean, 0.5, 0.03);
}

// ---------------------------------------------------------------------------
// The clouds alone (build 31): Background Transparent and Show Sun
// ---------------------------------------------------------------------------

namespace {

Look transparentLook() {
    Look l;
    l.transparent = true;
    return l;
}

} // namespace

PL_TEST(ATransparentClearSkyIsExactlyNothing) {
    // No cloud anywhere: every pixel is the sky, and the sky is what Transparent takes away.
    // Exactly zero, colour and alpha -- not a faint haze over whatever is underneath.
    const std::vector<float> g = render(false, nullptr, 8, true, transparentLook());
    for (int q = 0; q < kW * kH; ++q) {
        PL_CHECK(g[q * 4 + 0] == 0.0f);
        PL_CHECK(g[q * 4 + 1] == 0.0f && g[q * 4 + 2] == 0.0f && g[q * 4 + 3] == 0.0f);
    }
}

PL_TEST(TheTransparentCloudsOverTheSkyAreTheRender) {
    // THE ALGEBRA AGAIN, through the switch rather than a far depth pass: the clouds alone, F
    // with alpha a, laid over the clear sky S, must give back the render N. Without the air's
    // shadows, for the reason TheHoldoutOverWhatIsBehindItIsTheRender gives.
    const int spp = 32;
    const std::vector<float> n = render(true, nullptr, spp, false);
    const std::vector<float> s = render(false, nullptr, spp, false);
    const std::vector<float> g = render(true, nullptr, spp, false, transparentLook());

    double sumN = 0.0, sumC = 0.0, worst = 0.0, alphaMin = 1.0, alphaMax = 0.0;
    for (int q = 0; q < kW * kH; ++q) {
        const double a = g[q * 4];
        alphaMin = std::min(alphaMin, a);
        alphaMax = std::max(alphaMax, a);
        for (int c = 1; c < 4; ++c) {
            const double composed = g[q * 4 + c] + (1.0 - a) * s[q * 4 + c];
            sumN += n[q * 4 + c];
            sumC += composed;
            const double rel = std::fabs(composed - n[q * 4 + c]) /
                               std::max(1e-6, static_cast<double>(n[q * 4 + c]));
            worst = std::max(worst, rel);
        }
    }
    std::printf("    transparent over clear sky: frame mean %.6f vs render %.6f (%.3f%%), "
                "worst pixel %.3f%%, alpha %.3f..%.3f\n",
                sumC / (kW * kH * 3), sumN / (kW * kH * 3),
                100.0 * (sumC - sumN) / sumN, 100.0 * worst, alphaMin, alphaMax);
    PL_CHECK_NEAR(sumC / sumN, 1.0, 0.01);
    PL_CHECK(worst < 0.03);
    PL_CHECK(alphaMax > 0.02);
    PL_CHECK(alphaMin < 1.0);
}

PL_TEST(ATransparentBackgroundKeepsADepthPassesGeometry) {
    // A building one metre from the lens is still a building: the switch only stops what the
    // depth pass leaves open.
    const SceneDepthMap near = uniformMap(8, 4, 1.0f, 1.0f);
    const std::vector<float> a = render(true, &near, 8, true);
    const std::vector<float> b = render(true, &near, 8, true, transparentLook());
    for (size_t k = 0; k < a.size(); ++k) PL_CHECK(a[k] == b[k]);
}

PL_TEST(HidingTheSunLeavesTheCloudsLitExactlyAsTheyWere) {
    // The default sun is out of frame, 48 degrees right of the lens. Only a camera ray that reaches the sky unscattered
    // was ever shown the disc, so with the disc out of view the two renders must agree to the
    // bit -- cloud, sky and all. That is "still have it affect the cloud".
    Look hidden;
    hidden.showSun = false;
    const std::vector<float> a = render(true, nullptr, 8);
    const std::vector<float> b = render(true, nullptr, 8, true, hidden);
    for (size_t k = 0; k < a.size(); ++k) PL_CHECK(a[k] == b[k]);
}

PL_TEST(HidingTheSunTakesItsDiscOutOfView) {
    // The sun dead ahead: the camera looks 40 degrees up towards -Z, which is azimuth 180.
    // Shown, the samples that land on the disc blaze; hidden, they do not, and no pixel the
    // disc never touched moves at all. TWO DEGREES ACROSS, not the Sun's 0.27: a pixel here is
    // 3.3 degrees, and the real disc would be missed by every sample often enough to fail.
    Look shown;
    shown.sunAz = 180.0f;
    shown.sunEl = 40.0f;
    shown.sunRadius = 1.0f;
    Look hidden = shown;
    hidden.showSun = false;
    const std::vector<float> a = render(false, nullptr, 64, true, shown);
    const std::vector<float> b = render(false, nullptr, 64, true, hidden);

    double maxA = 0.0, maxB = 0.0;
    int moved = 0;
    for (int q = 0; q < kW * kH; ++q) {
        maxA = std::max(maxA, static_cast<double>(a[q * 4 + 2]));
        maxB = std::max(maxB, static_cast<double>(b[q * 4 + 2]));
        bool same = true;
        for (int c = 0; c < 4; ++c) same = same && a[q * 4 + c] == b[q * 4 + c];
        if (!same) ++moved;
    }
    std::printf("    sun dead ahead: brightest pixel %.3f shown, %.3f hidden; %d pixels moved\n",
                maxA, maxB, moved);
    PL_CHECK(maxA > 10.0 * maxB);
    PL_CHECK(moved >= 1 && moved <= 9);
}
