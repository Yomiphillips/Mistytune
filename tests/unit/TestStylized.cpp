// The Stylized look (build 32): the same cloud baked to grids once a frame and drawn by one
// deterministic march per pixel. See src/kernel/StylizedFrame.h.
//
// THE CLAIMS THAT MATTER:
//
//   * THE GRIDS HOLD WHAT THE FRAME CAN SEE. A hero alone is one grid fitted to its box, every
//     voxel spent on it; a camera looking away from the layer gets no grid at all; a level barely
//     bigger than the one inside it is merged into it. Cells are cubic and the budget holds.
//   * THE CUT ONLY EVER GROWS WITH THE DENSITY, and the fuzz only erodes it -- which is what
//     makes skipping a block on its largest density exact rather than hopeful.
//   * THE CUBIC READ IS A TRUE B-SPLINE: it gives back a constant and a ramp exactly, so it
//     smooths the cells' facets without moving the cloud.
//   * A RAY NEVER STANDS STILL: tens of kilometres out, where a point rounds a hair outside the
//     box its ray is in, the march still moves on into the cloud.
//   * A FRAME IS THE SAME BITS TWICE, and nothing but its own pixels decide it.
//   * THE CLOUDS ALONE ARE THE SKY'S FRAME LESS ITS BACKGROUND: transparent colour plus
//     (1 - alpha) x the sky gives back the frame drawn over the sky.
//   * THE GPU DRAWS WHAT THE CPU DRAWS, to within the texture unit's nine-bit weights.

#include "TestFramework.h"

#include "KernelApi.h"
#include "OrbitCamera.h"
#include "StylizedPlan.h"
#include "StylizedShading.h"

#include <cmath>
#include <vector>

using namespace plugin;
using namespace plugin::kernel;

namespace {

// A camera at the origin, 2 m up, pitched `pitchDeg` above the horizon, looking along -Z.
cloud::ViewParams pitchedView(float pitchDeg, int w, int h) {
    cloud::ViewParams v;
    v.widthPx = w;
    v.heightPx = h;
    v.verticalFovDegrees = 45.0f;
    const float a = pitchDeg * 0.01745329252f;
    const float c = std::cos(a), s = std::sin(a);
    const float m[16] = { 1, 0, 0, 0,
                          0, c, -s, 0,
                          0, s, c, 0,
                          0, 0, 0, 1 };
    for (int k = 0; k < 16; ++k) v.cameraToWorld[k] = m[k];
    return v;
}

AirMapLayerExtent slab(float bottom, float top) {
    AirMapLayerExtent e;
    e.present = true;
    e.bottom = bottom;
    e.top = top;
    e.fadeRadius = 40000.0f;
    return e;
}

// The default hero alone, 4 km off along the orbit, rendered stylized on the chosen engine
// into linear ARGB (no encode, no exposure: the numbers are radiance and alpha).
struct Shot {
    bool transparent = false;
    bool cumulus = true;
    bool ice = false;
    bool gpu = false;
    int  w = 96, h = 54;
};

std::vector<float> renderStylized(const Shot& s) {
    kernel::RenderRequest req;
    req.look = cloud::Look::Stylized;
    req.field.ice.enabled = s.ice;
    req.field.convection.enabled = s.cumulus;
    req.field.convection.heroMode = 2;
    req.view.widthPx = s.w;
    req.view.heightPx = s.h;
    req.view.encodeSrgb = false;
    req.view.transparentSky = s.transparent;
    // THE CAMERA FROM THE CLOUDY FIELD WHATEVER THE SHOT: the orbit rig aims at the cloud's
    // height, so a shot without the cumulus would otherwise look from somewhere else.
    cloud::FieldParams aim = req.field;
    aim.convection.enabled = true;
    cloud::OrbitControls orbit;
    orbit.distance = 4000.0f;
    cloud::orbitView(aim, orbit, req.view);

    std::vector<float> px(static_cast<size_t>(s.w) * s.h * 4, 0.0f);
    req.dest.data = px.data();
    req.dest.widthPx = s.w;
    req.dest.heightPx = s.h;
    req.dest.pitchPx = s.w;
    req.dest.order = kernel::ChannelOrder::ARGB;
    if (s.gpu) {
        if (!kernel::renderStylizedCudaToHost(req)) px.clear();
    } else {
        kernel::renderStylizedCpu(req, 0);
    }
    return px;
}

} // namespace

// ---------------------------------------------------------------------------
// The plan
// ---------------------------------------------------------------------------

PL_TEST(StylizedHeroAloneIsOneGridOfEveryVoxel) {
    const cloud::ViewParams view = pitchedView(20.0f, 640, 360);
    AirMapLayerExtent e = slab(800.0f, 2600.0f);
    e.clipOn = true;
    e.clipLoX = -2000.0f; e.clipHiX = 2000.0f;
    e.clipLoZ = -6000.0f; e.clipHiZ = -2000.0f;
    StylizedFrame f;
    planStyleLevels(view, e, 0.0f, -4000.0f, 2000.0f, 0.3f, 0.5f, -0.8f, 1.0f, f);

    int present = 0;
    for (int k = 0; k < kStyleLevels; ++k) present += f.level[k].present;
    PL_CHECK_EQ(present, 1);
    PL_CHECK(f.anyCloud == 1);

    long long budget = 0;
    for (int k = 0; k < kStyleLevels; ++k) budget += kStyleBudget[k];
    PL_CHECK(f.voxels <= budget + budget / 5);
    PL_CHECK(f.voxels >= budget / 2);

    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        // CUBIC CELLS, the box grown to whole ones, and inside the layer's own box (with the
        // growth of one cell at most).
        PL_CHECK_NEAR(L.hiX - L.loX, L.nx * L.cell, 1e-2 * L.cell);
        PL_CHECK_NEAR(L.hiY - L.loY, L.ny * L.cell, 1e-2 * L.cell);
        PL_CHECK_NEAR(L.hiZ - L.loZ, L.nz * L.cell, 1e-2 * L.cell);
        PL_CHECK(L.loX >= -2000.0f - L.cell && L.hiX <= 2000.0f + L.cell);
        PL_CHECK(L.loY >= 800.0f - L.cell && L.hiY <= 2600.0f + L.cell);
        PL_CHECK_EQ(L.bx, (L.nx + kStyleBlock - 1) / kStyleBlock);
    }
}

PL_TEST(StylizedLookingAwayFromTheLayerBakesNothing) {
    // Pitched 40 degrees DOWN from 2 m: every ray meets the ground long before a slab at 800 m.
    const cloud::ViewParams view = pitchedView(-40.0f, 640, 360);
    StylizedFrame f;
    planStyleLevels(view, slab(800.0f, 2600.0f), 0.0f, 0.0f, 0.0f, 0.3f, 0.5f, -0.8f, 1.0f, f);
    PL_CHECK(f.anyCloud == 0);
    PL_CHECK_EQ(f.voxels, 0ll);
}

PL_TEST(StylizedFieldIsCoarserFartherOut) {
    const cloud::ViewParams view = pitchedView(10.0f, 640, 360);
    StylizedFrame f;
    planStyleLevels(view, slab(800.0f, 2600.0f), 0.0f, 0.0f, 0.0f, 0.3f, 0.5f, -0.8f, 1.0f, f);
    PL_CHECK(f.anyCloud == 1);
    float last = 0.0f;
    long long offset = 0;
    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        PL_CHECK(L.cell >= last);          // each level out is no finer than the one inside it
        PL_CHECK_EQ(L.voxelOffset, offset);
        offset += styleVoxels(L);
        last = L.cell;
    }
    PL_CHECK_EQ(f.voxels, offset);
}

PL_TEST(StylizedLayerBoundsTakeTheClipAndTheFade) {
    AirMapLayerExtent e = slab(1000.0f, 2000.0f);
    e.fadeX = 100.0f; e.fadeZ = -50.0f; e.fadeRadius = 5000.0f;
    StyleBox b = styleLayerBounds(e);
    PL_CHECK(b.ok);
    PL_CHECK_NEAR(b.lo[0], -4900.0, 1e-3);
    PL_CHECK_NEAR(b.hi[2], 4950.0, 1e-3);
    e.clipOn = true;
    e.clipLoX = 0.0f; e.clipHiX = 10.0f; e.clipLoZ = 0.0f; e.clipHiZ = 20.0f;
    b = styleLayerBounds(e);
    PL_CHECK(b.ok);
    PL_CHECK_NEAR(b.lo[0], 0.0, 1e-6);
    PL_CHECK_NEAR(b.hi[2], 20.0, 1e-6);
    e.present = false;
    PL_CHECK(!styleLayerBounds(e).ok);
}

// ---------------------------------------------------------------------------
// The cut, the fuzz and the reads
// ---------------------------------------------------------------------------

PL_TEST(StylizedCutGrowsWithDensityAndFuzzOnlyErodes) {
    PL_SWEEP(sweep, "puffiness x softness");
    for (float puff : { 0.0f, 0.3f, 0.65f, 1.0f }) {
        StylizedFrame f;
        cloud::StylizedParams p;
        p.puffiness = puff;
        styleLookConstants(p, 0.03f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, false, f);
        float last = 0.0f;
        for (int i = 0; i <= 200; ++i) {
            const float n = i / 100.0f;
            const float s = styleSigma(f, n);
            PL_CHECK(s >= last - 1e-7f);
            last = s;
            for (float noise : { 0.0f, 0.5f, 1.0f }) {
                PL_CHECK(styleErode(f, n, noise) <= n + 1e-6f);
            }
        }
        PL_CHECK_EQ(styleSigma(f, 0.0f), 0.0f);
    }
    // PUFFINESS 0 IS THE CLOUD'S OWN DENSITY.
    StylizedFrame f;
    cloud::StylizedParams p;
    p.puffiness = 0.0f;
    styleLookConstants(p, 0.03f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, false, f);
    PL_CHECK_NEAR(styleSigma(f, 0.5f), 0.015, 1e-7);
}

namespace {
// A 1D "texture" of n texels read linearly, as the texture unit reads one, centres at i + 0.5.
struct Line {
    std::vector<float> v;
    float at(float c) const {
        const float x = c - 0.5f;
        int i = static_cast<int>(std::floor(x));
        const float t = x - i;
        const auto get = [&](int k) { return v[k < 0 ? 0 : (k >= static_cast<int>(v.size()) ? v.size() - 1 : k)]; };
        return get(i) * (1 - t) + get(i + 1) * t;
    }
    float cubic(float c) const {
        float h0, h1, g0;
        styleCubicAxis(c, h0, h1, g0);
        return at(h0) * g0 + at(h1) * (1.0f - g0);
    }
};
} // namespace

PL_TEST(StylizedCubicReadGivesBackConstantsAndRamps) {
    Line constant{ std::vector<float>(16, 0.37f) };
    Line ramp;
    for (int i = 0; i < 16; ++i) ramp.v.push_back(2.0f * i - 3.0f);
    for (float c = 3.0f; c <= 12.0f; c += 0.137f) {
        PL_CHECK_NEAR(constant.cubic(c), 0.37, 1e-5);
        // texel i holds 2i - 3 at coordinate i + 0.5
        PL_CHECK_NEAR(ramp.cubic(c), 2.0 * (c - 0.5) - 3.0, 1e-3);
    }
}

namespace {
// Solid cloud wherever a level is, read without textures.
struct SolidSampler {
    float density(int, float, float, float) const { return 1.0f; }
    Style4 voxel(int, float, float, float) const { return Style4{ 1.0f, 0.0f, 0.0f, 0.0f }; }
    float noise(float, float, float) const { return 0.0f; }
    bool occupied(long long) const { return true; }
};
} // namespace

PL_TEST(StylizedFarRaysNeverStandStill) {
    // ONE SOLID LEVEL whose floor is 1 km up, met by rays from the ground 20-50 km out: the far
    // field's bases seen near the horizon. Where ro + rd * t rounded under the floor, the march
    // was handed its own t back as the next entry and stood still until its iterations ran out:
    // those rays saw no cloud at all.
    StylizedFrame f;
    cloud::StylizedParams p;
    styleLookConstants(p, 0.03f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, false, f);
    f.cubic = 0;
    f.baseRound = 0.0f;
    StyleLevel& L = f.level[0];
    L.present = 1;
    L.cell = 200.0f;
    L.invCell = 1.0f / L.cell;
    L.nx = 500; L.ny = 10; L.nz = 500;
    L.bx = 63; L.by = 2; L.bz = 63;
    L.loX = -50000.0f; L.loY = 1000.0f; L.loZ = -50000.0f;
    L.hiX = 50000.0f;  L.hiY = 3000.0f; L.hiZ = 50000.0f;
    f.anyCloud = 1;
    f.voxels = styleVoxels(L);
    f.blocks = styleBlocks(L);

    const SolidSampler smp;
    const Vec3 ro = vec3(0.0f, 2.0f, 0.0f);
    int clear = 0;
    for (int i = 0; i < 4000; ++i) {
        const float rise = 0.02f + 0.03f * i / 4000.0f;
        const float side = 0.3f * std::sin(0.37f * i);
        const Vec3 rd = normalize(vec3(side, rise, -1.0f));
        Vec3 C;
        float T, tMean;
        styleMarch(f, smp, ro, rd, kNoSceneGeometry, 1e-3f, C, T, tMean);
        if (T > 0.5f) ++clear;
    }
    PL_CHECK_EQ(clear, 0);
}

PL_TEST(StylizedTablesMapBackToThemselves) {
    for (float u = 0.02f; u < 1.0f; u += 0.07f) {
        for (float v = 0.03f; v < 1.0f; v += 0.05f) {
            float u2, v2;
            styleSkyUv(styleSkyDir(u, v), u2, v2);
            PL_CHECK_NEAR(u2, u, 1e-4);
            PL_CHECK_NEAR(v2, v, 1e-4);
        }
    }
    StylizedFrame f;
    f.airFar = 80000.0f;
    for (int k = 0; k < kStyleAirD; ++k) {
        PL_CHECK_NEAR(styleAirSlice(f, styleAirDepth(f, static_cast<float>(k))), k, 1e-3);
    }
}

// ---------------------------------------------------------------------------
// Frames
// ---------------------------------------------------------------------------

PL_TEST(StylizedFrameIsTheSameBitsTwice) {
    Shot s;
    const std::vector<float> a = renderStylized(s);
    const std::vector<float> b = renderStylized(s);
    PL_CHECK(a == b);
    // AND SOMETHING IS IN IT: the hero, opaque somewhere, the sky everywhere else.
    float most = 0.0f;
    for (size_t i = 0; i < a.size(); i += 4) most = std::fmax(most, a[i + 1]);
    PL_CHECK(most > 0.0f);
}

PL_TEST(StylizedTransparentIsTheSkyFrameLessItsBackground) {
    Shot sky;
    Shot alone;
    alone.transparent = true;
    Shot empty;
    empty.cumulus = false;
    const std::vector<float> a = renderStylized(sky);
    const std::vector<float> t = renderStylized(alone);
    const std::vector<float> bg = renderStylized(empty);
    double worst = 0.0;
    int clouded = 0;
    for (size_t i = 0; i < a.size(); i += 4) {
        const float alpha = t[i];
        if (alpha > 0.01f) ++clouded;
        for (int c = 1; c < 4; ++c) {
            const double back = t[i + c] + (1.0 - alpha) * bg[i + c];
            worst = std::fmax(worst, std::fabs(back - a[i + c]) / std::fmax(1e-3, a[i + c]));
        }
    }
    PL_CHECK(clouded > 0);
    PL_CHECK(worst < 1e-4);

    // NO CLOUD, NOTHING: a transparent frame of an empty sky is exactly zero.
    empty.transparent = true;
    const std::vector<float> z = renderStylized(empty);
    for (float v : z) PL_CHECK_EQ(v, 0.0f);
}

PL_TEST(StylizedGpuDrawsWhatTheCpuDraws) {
    if (!kernel::cudaAvailable()) return;   // nothing to compare on a machine without a card
    Shot s;
    const std::vector<float> cpu = renderStylized(s);
    s.gpu = true;
    const std::vector<float> gpu = renderStylized(s);
    PL_CHECK_EQ(gpu.size(), cpu.size());
    if (gpu.size() != cpu.size()) return;
    double sum = 0.0, scale = 0.0;
    for (size_t i = 0; i < cpu.size(); ++i) {
        sum += std::fabs(gpu[i] - cpu[i]);
        scale += std::fabs(cpu[i]);
    }
    // THE MEAN DIFFERENCE, AS A FRACTION OF THE MEAN: the texture unit's weights are nine bits.
    PL_CHECK(sum / std::fmax(scale, 1e-9) < 0.01);
}
