#pragma once

// Where the clouds' shadow maps lie, and how finely: the HOST's half of AirMapLib.slang.
//
// PLAIN C++ AND NO KERNEL TYPES, so tests/unit can hold the geometry to account without a
// GPU or a generated struct. RenderRequest carries the plan to the kernel by value, which
// is why every member is a scalar and there is no container here.
//
// ===========================================================================
// ONE MAP PER LAYER, LAID OUT ALONG THE SUN.
//
// A map's texels lie on its layer's bottom plane. A cloud point at altitude h throws its
// shadow onto that plane (h - bottom) / tan(elevation) away from the sun, so the texels a
// layer needs are its own footprint across, STRETCHED AWAY FROM THE SUN by the slab's
// depth over the tangent of the sun's elevation. With the grid's U axis on the sun's
// azimuth that stretch is one-sided along U, and the box is tight whatever the azimuth. An
// axis-aligned box would be up to twice as large for a sun on the diagonal.
//
// THE FOOTPRINT IS THE ONE THE DENSITY HAS: the Render Distance circle round the eye, cut
// by the hero's box when the hero is alone. Both are read from the kernel's own Medium by
// airMapExtentOf in AirMapHost.h, so the map and densityAt cannot disagree about where
// cloud can be.
//
// SQUARE TEXELS FROM A BUDGET, not a fixed side. A low sun stretches the box several
// times longer than it is wide, and a fixed 512 along the long side would leave the short
// one a few hundred texels at most. A budget of resolution^2 texels shared by both sides
// keeps the texel the same size across and along.
// ===========================================================================

#include <cmath>
#include <cstddef>

namespace plugin::kernel {

// Below this the map is not built and the renderer falls back to one shadow ray per
// camera ray. At one degree the stretch is already 57 times the slab's depth; lower than
// that the texels spread too thin to draw a shaft, and the sun's own light is nearly gone.
constexpr float kAirMapMinSunSine = 0.0174524f;   // sin(1 degree)

// How far across a layer with no Render Distance can reach. slabRange caps a ray at 120 km
// along it; clouds past 60 km of the eye cast shadows no camera ray can reach through the
// haze in front of them.
constexpr float kAirMapUnboundedReach = 60000.0f;

// The longest the sun's stretch is allowed to make a box. Past it, shadows land off the
// grid and the air there is treated as lit.
constexpr float kAirMapMaxStretch = 200000.0f;

// Slices per column. The cumulus is deep and lumpy and gets sixteen. Cirrus is thin and
// soft and gets eight.
constexpr int kAirMapSlicesCirrus  = 8;
constexpr int kAirMapSlicesCumulus = 16;

// The build's step along a column, as a fraction of a texel, floored and capped, then
// stretched so that no column needs more than kAirMapColumnSteps.
constexpr float kAirMapStepPerTexel = 0.5f;
constexpr float kAirMapMinStep      = 25.0f;
constexpr float kAirMapMaxStep      = 200.0f;
constexpr float kAirMapColumnSteps  = 1024.0f;

// No side longer than this, however the budget falls.
constexpr int kAirMapMaxSide = 4096;

// One layer's map, as the kernel's LayerShadowMap reads it.
struct AirMapGeometry {
    int   present = 0;
    float sunX = 0.0f, sunY = 1.0f, sunZ = 0.0f;
    float centreX = 0.0f, centreZ = 0.0f;
    float axisUX = 1.0f, axisUZ = 0.0f;
    float loU = 0.0f, loV = 0.0f;
    float texelU = 1.0f, texelV = 1.0f;
    int   dimU = 0, dimV = 0, slices = 0;
    float bottom = 0.0f, top = 0.0f;
    float step = 1.0f;
    long long offset = 0;   // floats from the start of the buffer both layers share
};

// NO PADDING, because AirMapHost.h keys a cache on these bytes and bytes nobody wrote
// would make every lookup a miss.
static_assert(sizeof(AirMapGeometry) == 80, "AirMapGeometry has grown padding; see AirMapHost.h");

inline long long airMapFloats(const AirMapGeometry& g) {
    return g.present ? static_cast<long long>(g.dimU) * g.dimV * g.slices : 0;
}

// Both layers' maps. `on` zero means the renderer takes the shadow ray instead.
struct AirMapPlan {
    int on = 0;
    AirMapGeometry layer[2];   // 0 = the first layer (cirrus), 1 = the second (cumulus)
    long long totalFloats = 0;
};

// What a layer's medium says about where it can be.
struct AirMapLayerExtent {
    bool  present = false;
    float bottom = 0.0f, top = 0.0f;
    bool  clipOn = false;
    float clipLoX = 0.0f, clipLoZ = 0.0f, clipHiX = 0.0f, clipHiZ = 0.0f;
    float fadeX = 0.0f, fadeZ = 0.0f, fadeRadius = 0.0f;
};

// One layer's map, or none. `budgetSide` squared is its texel budget.
inline AirMapGeometry planLayerAirMap(const AirMapLayerExtent& e,
                                      float sunX, float sunY, float sunZ,
                                      int budgetSide, int slices) {
    AirMapGeometry g;
    if (!e.present || !(e.top > e.bottom) || !(sunY >= kAirMapMinSunSine)) return g;
    if (budgetSide < 2 || slices < 2) return g;

    // THE FOOTPRINT ACROSS, as a box in x and z. The fade is a circle, and slabRange folds
    // it into its box as the square round it, which is what is done here as well.
    const float reach = e.fadeRadius > 0.0f ? e.fadeRadius : kAirMapUnboundedReach;
    float loX = e.fadeX - reach, hiX = e.fadeX + reach;
    float loZ = e.fadeZ - reach, hiZ = e.fadeZ + reach;
    const bool circle = !e.clipOn;
    if (e.clipOn) {
        loX = std::fmax(loX, e.clipLoX); hiX = std::fmin(hiX, e.clipHiX);
        loZ = std::fmax(loZ, e.clipLoZ); hiZ = std::fmin(hiZ, e.clipHiZ);
    }
    if (!(hiX > loX) || !(hiZ > loZ)) return g;

    // U ALONG THE SUN'S AZIMUTH. Straight overhead there is none, and any axis will do:
    // the stretch is then zero.
    const float across = std::sqrt(sunX * sunX + sunZ * sunZ);
    float ax = 1.0f, az = 0.0f;
    if (across > 1e-6f) { ax = sunX / across; az = sunZ / across; }
    const float vx = -az, vz = ax;   // U turned 90 degrees, as airMapAxisV has it

    const float cx = 0.5f * (loX + hiX);
    const float cz = 0.5f * (loZ + hiZ);

    // THE BOX IN (u, v). A circle is the same in every frame; a box's corners are
    // projected.
    float uLo, uHi, vLo, vHi;
    if (circle) {
        uLo = -reach; uHi = reach; vLo = -reach; vHi = reach;
    } else {
        const float xs[2] = { loX - cx, hiX - cx };
        const float zs[2] = { loZ - cz, hiZ - cz };
        uLo = vLo = 1e30f;
        uHi = vHi = -1e30f;
        for (float x : xs) {
            for (float z : zs) {
                const float u = x * ax + z * az;
                const float v = x * vx + z * vz;
                uLo = std::fmin(uLo, u); uHi = std::fmax(uHi, u);
                vLo = std::fmin(vLo, v); vHi = std::fmax(vHi, v);
            }
        }
    }

    // THE SUN'S STRETCH: the slab's top throws its shadow this far towards -U.
    const float stretch = std::fmin((e.top - e.bottom) * across / sunY, kAirMapMaxStretch);
    uLo -= stretch;

    const float uSpan = uHi - uLo;
    const float vSpan = vHi - vLo;
    const float texel = std::sqrt(uSpan * vSpan) / static_cast<float>(budgetSide);
    if (!(texel > 0.0f)) return g;

    const auto side = [texel](float span) {
        const float n = std::ceil(span / texel);
        return n < 2.0f ? 2 : (n > static_cast<float>(kAirMapMaxSide)
                               ? kAirMapMaxSide : static_cast<int>(n));
    };

    g.present = 1;
    g.sunX = sunX; g.sunY = sunY; g.sunZ = sunZ;
    g.centreX = cx; g.centreZ = cz;
    g.axisUX = ax;  g.axisUZ = az;
    g.loU = uLo;    g.loV = vLo;
    g.dimU = side(uSpan);
    g.dimV = side(vSpan);
    g.texelU = uSpan / static_cast<float>(g.dimU);
    g.texelV = vSpan / static_cast<float>(g.dimV);
    g.slices = slices;
    g.bottom = e.bottom;
    g.top    = e.top;

    // THE COLUMN'S STEP: half a texel, within limits, and never so fine that the sun's
    // whole climb through the slab takes more than kAirMapColumnSteps.
    const float base = std::fmin(std::fmax(std::fmin(g.texelU, g.texelV) * kAirMapStepPerTexel,
                                           kAirMapMinStep), kAirMapMaxStep);
    const float climb = (e.top - e.bottom) / sunY;
    g.step = std::fmax(base, climb / kAirMapColumnSteps);
    return g;
}

// Both maps. `wanted` is false when the air's shadows are off or the CLI asked for the
// shadow ray. The cumulus gets `resolution`; the cirrus, whose shadows are thin and soft,
// half of it.
inline AirMapPlan planAirMaps(const AirMapLayerExtent layers[2],
                              float sunX, float sunY, float sunZ,
                              int resolution, bool wanted) {
    AirMapPlan plan;
    if (!wanted || !(sunY >= kAirMapMinSunSine) || resolution < 2) return plan;

    plan.on = 1;
    plan.layer[0] = planLayerAirMap(layers[0], sunX, sunY, sunZ,
                                    resolution / 2 < 2 ? 2 : resolution / 2,
                                    kAirMapSlicesCirrus);
    plan.layer[1] = planLayerAirMap(layers[1], sunX, sunY, sunZ, resolution,
                                    kAirMapSlicesCumulus);

    plan.layer[0].offset = 0;
    plan.layer[1].offset = airMapFloats(plan.layer[0]);
    plan.totalFloats     = airMapFloats(plan.layer[0]) + airMapFloats(plan.layer[1]);
    return plan;
}

} // namespace plugin::kernel
