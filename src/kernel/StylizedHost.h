#pragma once

// THE STYLIZED FRAME, BUILT ON THE HOST (build 32), once per backend's scene type.
//
// Both backends fill the generated Scene from the request (SlangBridge.h) and hand it here: the
// slabs, the sun and the clip boxes come out of it, so the grids lie exactly where the media
// the bakes then evaluate are. HOST ONLY: it calls the planner, which uses the standard library.

#include "StylizedPlan.h"   // first: it brings Shading.h, which SlangBridge.h needs
#include "SlangBridge.h"
#include "AirMapHost.h"

#include <cmath>
#include <cstdlib>
#include <cstring>

namespace plugin::kernel {

// THE CPU'S SHARE OF THE GRIDS' VOXELS. The CPU is the fallback, and its light walk is a few
// hundred milliseconds a million voxels where the card's is a few; a quarter keeps a 1080p frame
// near a second. MEASURED (PROGRESS.md, build 32).
constexpr float kStyleCpuBudget = 0.25f;

// WHAT THE SMALL PROBE BAKE RETURNS, in floats: the sun's irradiance at the cumulus and at the
// cirrus, and the disc's own radiance (the sky looking at the sun, less the sky without it).
constexpr int kStyleProbeFloats = 9;

// The ice slab's extent, for the cirrus map.
template <class SceneT>
AirMapLayerExtent styleIceExtent(const SceneT& scene) {
    return airMapExtentOf(scene.medium_0, true);
}

// THE CLI'S --style-tune, "name=value,name=value": overrides of the look's constants by name,
// for tuning the look without a rebuild. Nothing else sets it; the effect never does.
inline void styleApplyTune(const char* tune, StylizedFrame& f) {
    if (!tune || !tune[0]) return;
    struct Entry { const char* name; float* value; };
    const Entry floats[] = {
        { "edge", &f.edge }, { "edgeSoft", &f.edgeSoft }, { "solid", &f.solid }, { "puff", &f.puff },
        { "fuzzAmp", &f.fuzzAmp }, { "fuzzScale", &f.fuzzScale },
        { "msA", &f.msA }, { "msB", &f.msB }, { "msC", &f.msC },
        { "gForward", &f.gForward }, { "gBack", &f.gBack }, { "wForward", &f.wForward },
        { "aoK", &f.aoK }, { "gain", &f.gain }, { "stepScale", &f.stepScale },
        { "lightScale", &f.lightScale }, { "aoStyle", &f.aoStyle }, { "sunGain", &f.sunGain },
        { "skyGain", &f.skyGain }, { "cirrusGain", &f.cirrusGain },
        { "tintR", &f.tintR }, { "tintG", &f.tintG }, { "tintB", &f.tintB },
        { "baseRound", &f.baseRound }, { "blurMetres", &f.blurMetres },
        { "sideSky", &f.sideSky }, { "groundBounce", &f.groundBounce },
        { "tune0", &f.tune[0] }, { "tune1", &f.tune[1] }, { "tune2", &f.tune[2] }, { "tune3", &f.tune[3] },
        { "tune4", &f.tune[4] }, { "tune5", &f.tune[5] }, { "tune6", &f.tune[6] }, { "tune7", &f.tune[7] },
    };
    const char* p = tune;
    while (*p) {
        char name[32] = { 0 };
        int n = 0;
        while (*p && *p != '=' && *p != ',' && n < 31) name[n++] = *p++;
        if (*p != '=') { while (*p && *p != ',') ++p; if (*p) ++p; continue; }
        ++p;
        const float v = static_cast<float>(std::atof(p));
        while (*p && *p != ',') ++p;
        if (*p) ++p;
        if (std::strcmp(name, "cubic") == 0)     { f.cubic = static_cast<int>(v); continue; }
        if (std::strcmp(name, "octaves") == 0)   { f.msOctaves = static_cast<int>(v); continue; }
        for (const Entry& e : floats) {
            if (std::strcmp(name, e.name) == 0) { *e.value = v; break; }
        }
    }
}

// THE FRAME, EVERYTHING BUT WHAT THE BAKES MEASURE: the grids, the look's constants, the
// background, the maps' rect. `work` is derived (deriveRenderInputs) and `scene` filled from it.
// `budgetScale` scales the grids' voxels: 1 on the card, kStyleCpuBudget on the CPU.
template <class SceneT>
void styleBeginFrame(const RenderRequest& work, const SceneT& scene, StylizedFrame& f,
                     float budgetScale = 1.0f) {
    f = StylizedFrame{};
    const cloud::ConvectionDerived& cd = work.convection;
    const cloud::ConvectionParams&  cv = work.field.convection;
    const bool draft = work.quality.pixelStride > 1;

    const float sx = scene.sunDir_0.x, sy = scene.sunDir_0.y, sz = scene.sunDir_0.z;
    f.sunX = sx; f.sunY = sy; f.sunZ = sz;

    const AirMapLayerExtent cumulus = airMapExtentOf(scene.medium2_0, scene.layer2On_0 != 0);
    const float heroReach = heroBoxReach(work);
    planStyleLevels(work.view, cumulus, cd.heroX, cd.heroZ, heroReach, sx, sy, sz,
                    (draft ? 0.5f : 1.0f) * budgetScale, f);

    styleLookConstants(work.stylized, cd.sigma, work.field.timeSeconds,
                       cd.heroX - cv.heroX, cd.heroZ - cv.heroZ, cd.driftX, cd.driftZ, draft, f);
    f.fuzzHeroLevel = (heroReach > 0.0f && f.level[0].present) ? 0 : -1;
    f.baseY = cd.base;
    // MAMMA HANG BELOW THE FLOOR, and a dome would cut them off from the cloud above them.
    if (cd.mammaDepth > 0.0f) f.baseRound = 0.0f;

    // THE MAPS COVER THE BUFFER, wherever in the frame it lies.
    f.mapX0 = static_cast<float>(work.view.originX);
    f.mapY0 = static_cast<float>(work.view.originY);
    f.mapW  = static_cast<float>(work.dest.widthPx > 0 ? work.dest.widthPx : 1);
    f.mapH  = static_cast<float>(work.dest.heightPx > 0 ? work.dest.heightPx : 1);

    // THE CIRRUS, when the ice layer is there.
    const AirMapLayerExtent ice = styleIceExtent(scene);
    f.cirrusOn = ice.present ? 1 : 0;
    f.cirrusW  = f.cirrusOn ? (work.dest.widthPx + kStyleCirrusStride - 1) / kStyleCirrusStride : 0;
    f.cirrusH  = f.cirrusOn ? (work.dest.heightPx + kStyleCirrusStride - 1) / kStyleCirrusStride : 0;
    f.cirrusGain = 1.0f;
    f.cirrusG    = 0.6f;

    // THE AIR TABLE REACHES THE FARTHEST THING IT MAY BE ASKED ABOUT: the far corner of every
    // grid, and the cirrus's reach.
    const float ex = work.view.observerX, ey = work.view.observerAltitude, ez = work.view.observerZ;
    float far = 1000.0f;
    for (int k = 0; k < kStyleLevels; ++k) {
        const StyleLevel& L = f.level[k];
        if (!L.present) continue;
        for (int c = 0; c < 8; ++c) {
            const float x = (c & 1) ? L.hiX : L.loX, y = (c & 2) ? L.hiY : L.loY, z = (c & 4) ? L.hiZ : L.loZ;
            const float d = std::sqrt((x - ex) * (x - ex) + (y - ey) * (y - ey) + (z - ez) * (z - ez));
            far = d > far ? d : far;
        }
    }
    if (f.cirrusOn) {
        const float reach = ice.fadeRadius > 0.0f ? ice.fadeRadius : kStyleFarReach;
        const float slant = std::sqrt(reach * reach + ice.top * ice.top);
        far = slant > far ? slant : far;
    }
    f.airFar = far < 200000.0f ? far : 200000.0f;

    f.skyOn   = work.view.transparentSky ? 0 : 1;
    f.discOn  = work.field.atmosphere.showSunDisc ? 1 : 0;
    f.discCos = std::cos(work.field.atmosphere.sunAngularRadius * 0.01745329252f);

    styleApplyTune(work.styleTune, f);
}

// THE FRAME'S LIGHT, from what the bakes measured: the sun at each layer and its disc from the
// probe, and the skylight from the sky table -- the cosine-weighted mean radiance of the sky
// above and of the ground below, which is what a cloud's shadowed side sees.
inline void styleFinishFrame(const float* sky, const float* probe, StylizedFrame& f) {
    f.sunR   = probe[0]; f.sunG   = probe[1]; f.sunB   = probe[2];
    f.sunCiR = probe[3]; f.sunCiG = probe[4]; f.sunCiB = probe[5];
    f.discR  = probe[6]; f.discG  = probe[7]; f.discB  = probe[8];

    double up[3] = { 0, 0, 0 }, down[3] = { 0, 0, 0 }, wUp = 0, wDown = 0;
    for (int j = 0; j < kStyleSkyH; ++j) {
        const float s0 = static_cast<float>(j) / kStyleSkyH * 2.0f - 1.0f;
        const float s1 = static_cast<float>(j + 1) / kStyleSkyH * 2.0f - 1.0f;
        const float e0 = (s0 >= 0 ? s0 * s0 : -s0 * s0) * 1.570796327f;
        const float e1 = (s1 >= 0 ? s1 * s1 : -s1 * s1) * 1.570796327f;
        const float band = std::fabs(std::sin(e1) - std::sin(e0));   // solid angle / (2 pi) of the row
        const float mid  = std::sin(0.5f * (e0 + e1));                // cosine to the zenith
        for (int i = 0; i < kStyleSkyW; ++i) {
            const float* t = sky + (j * kStyleSkyW + i) * 4;
            const double w = static_cast<double>(band) * std::fabs(mid);
            if (mid >= 0.0f) {
                for (int c = 0; c < 3; ++c) up[c] += t[c] * w;
                wUp += w;
            } else {
                for (int c = 0; c < 3; ++c) down[c] += t[c] * w;
                wDown += w;
            }
        }
    }
    f.skyR = wUp > 0 ? static_cast<float>(up[0] / wUp) : 0.0f;
    f.skyG = wUp > 0 ? static_cast<float>(up[1] / wUp) : 0.0f;
    f.skyB = wUp > 0 ? static_cast<float>(up[2] / wUp) : 0.0f;
    f.gndR = wDown > 0 ? static_cast<float>(down[0] / wDown) : 0.0f;
    f.gndG = wDown > 0 ? static_cast<float>(down[1] / wDown) : 0.0f;
    f.gndB = wDown > 0 ? static_cast<float>(down[2] / wDown) : 0.0f;
}

// WHERE THE PROBE MEASURES THE SUN: the middle of the cumulus slab and of the ice slab, above
// the eye. Altitude is all the sun's air depends on.
template <class SceneT>
void styleProbePoints(const RenderRequest& work, const SceneT& scene, float cu[3], float ci[3]) {
    cu[0] = work.view.observerX; cu[2] = work.view.observerZ;
    ci[0] = cu[0];               ci[2] = cu[2];
    cu[1] = scene.layer2On_0 ? 0.5f * (scene.medium2_0.slabBottom_0 + scene.medium2_0.slabTop_0) : 1500.0f;
    const float iceMid = 0.5f * (scene.medium_0.slabBottom_0 + scene.medium_0.slabTop_0);
    ci[1] = iceMid > 0.0f ? iceMid : 9000.0f;
}

} // namespace plugin::kernel
