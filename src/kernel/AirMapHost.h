#pragma once

// Planning and keying the clouds' shadow maps, ON THE HOST, for both backends.
//
// INCLUDED AFTER THE GENERATED SOURCE AND SlangBridge.h, by Mistytune.cu and CpuRender.cpp,
// because it fills the backend's own Scene. The two differ in vector types and in how
// they run the columns: a kernel launch on one, a thread pool on the other. Everything
// else is here, once.
//
// ===========================================================================
// THE PLAN IS READ OFF THE KERNEL'S OWN Medium, NOT RE-DERIVED FROM THE PARAMETERS.
//
// The cumulus slab's top is the tallest tower plus the biggest billow, the hero's box is
// its reach plus a margin, and both are worked out in fillSlangScene. A second copy of
// that arithmetic here would be free to disagree with it, and the symptom would be a
// shadow cut off at a line nobody can find in the parameters. So the host fills a Scene
// exactly as a sample does, and the map covers what that Scene's densityAt can return.
//
// THE CACHE KEY IS THE BYTES A COLUMN READS: both media, the drift table and the plan.
// Nothing else reaches layerMapColumn, so a key that matches is a map that matches. It is
// compared whole rather than hashed, so it cannot collide. The Scene is zeroed before it
// is filled, so its padding is too.
// ===========================================================================

#include <cstring>
#include <vector>

namespace plugin::kernel {

template <class MediumT>
AirMapLayerExtent airMapExtentOf(const MediumT& m, bool present) {
    AirMapLayerExtent e;
    e.present    = present && m.slabTop_0 > m.slabBottom_0;
    e.bottom     = m.slabBottom_0;
    e.top        = m.slabTop_0;
    e.clipOn     = m.clipOn_0 != 0;
    e.clipLoX    = m.clipLo_0.x;
    e.clipLoZ    = m.clipLo_0.y;
    e.clipHiX    = m.clipHi_0.x;
    e.clipHiZ    = m.clipHi_0.y;
    e.fadeX      = m.fadeAt_0.x;
    e.fadeZ      = m.fadeAt_0.y;
    e.fadeRadius = m.fadeRadius_0;
    return e;
}

inline void airMapKeyAppend(std::vector<unsigned char>& key, const void* p, size_t n) {
    const unsigned char* b = static_cast<const unsigned char*>(p);
    key.insert(key.end(), b, b + n);
}

// Fills `scene` as the kernel would, WITHOUT maps, and returns the plan for it. `key`
// receives everything the columns will read.
//
// `req` MUST ALREADY BE DERIVED (deriveRenderInputs): the cumulus slab and the drift table
// come from there.
template <class V, class SceneT, class PhaseT>
AirMapPlan planAirMapsFor(const RenderRequest& req, SceneT& scene,
                          std::vector<unsigned char>& key) {
    RenderRequest bare = req;
    bare.airMaps      = AirMapPlan{};
    bare.airMapBuffer = nullptr;

    PhaseT phase;
    std::memset(static_cast<void*>(&scene), 0, sizeof scene);
    std::memset(static_cast<void*>(&phase), 0, sizeof phase);
    fillSlangScene<V>(bare, scene, phase);

    AirMapLayerExtent layers[2];
    layers[0] = airMapExtentOf(scene.medium_0, true);
    layers[1] = airMapExtentOf(scene.medium2_0, scene.layer2On_0 != 0);

    // WHENEVER THE SKY IS THE ENVIRONMENT, not only when the air's shadows are on: the
    // maps also put the clouds' shadows on the ground (build 19), and Cloud Shadows In Air
    // switching off the air's shadows must not switch off the ground's.
    const bool wanted = req.airShadowMap && scene.environment_0.envMode_0 == 1;
    const AirMapPlan plan = planAirMaps(layers, scene.sunDir_0.x, scene.sunDir_0.y,
                                        scene.sunDir_0.z, req.airMapResolution, wanted);

    // THE PLAN BY MEMBER, not as one block: AirMapPlan has padding after `on`, and bytes
    // nobody wrote would make every call a miss. AirMapGeometry has none (80 bytes).
    key.clear();
    airMapKeyAppend(key, &plan.on, sizeof plan.on);
    airMapKeyAppend(key, &plan.layer[0], sizeof plan.layer[0]);
    airMapKeyAppend(key, &plan.layer[1], sizeof plan.layer[1]);
    airMapKeyAppend(key, &scene.medium_0, sizeof scene.medium_0);
    airMapKeyAppend(key, &scene.medium2_0, sizeof scene.medium2_0);
    airMapKeyAppend(key, req.drift.xz, sizeof req.drift.xz);
    return plan;
}

} // namespace plugin::kernel
