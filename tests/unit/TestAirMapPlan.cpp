// Where the clouds' shadow maps lie: the planner in src/kernel/AirMapPlan.h.
//
// THE PROPERTY THAT MATTERS IS COVERAGE. A lookup off the grid answers 1, lit, so a grid
// that misses part of a layer's shadow draws that part of the air lit with nothing to say
// so. Every check below throws cloud points at the planner and follows each one's sun ray
// down to the grid, with the kernel's own arithmetic, in double.

#include "TestFramework.h"

#include "AirMapPlan.h"

#include <cmath>

using namespace plugin::kernel;

namespace {

const double kDeg = 3.14159265358979323846 / 180.0;

struct Sun {
    float x, y, z;
};

Sun sunAt(double elevationDeg, double azimuthDeg) {
    const double el = elevationDeg * kDeg, az = azimuthDeg * kDeg;
    Sun s;
    s.x = static_cast<float>(std::sin(az) * std::cos(el));
    s.y = static_cast<float>(std::sin(el));
    s.z = static_cast<float>(std::cos(az) * std::cos(el));
    return s;
}

// Where p's sun ray crosses the grid, in texels: layerMapTransmittance's own steps.
void texelOf(const AirMapGeometry& g, double px, double py, double pz, double& fu, double& fv) {
    const double k  = (g.bottom - py) / g.sunY;
    const double qx = px + g.sunX * k - g.centreX;
    const double qz = pz + g.sunZ * k - g.centreZ;
    const double u  = qx * g.axisUX + qz * g.axisUZ;
    const double v  = qx * -g.axisUZ + qz * g.axisUX;
    fu = (u - g.loU) / g.texelU;
    fv = (v - g.loV) / g.texelV;
}

// A deterministic stream for the sweeps.
struct Lcg {
    unsigned long long s = 0x2545f4914f6cdd1dull;
    double next() {
        s = s * 6364136223846793005ull + 1442695040888963407ull;
        return static_cast<double>(s >> 11) * (1.0 / 9007199254740992.0);
    }
};

// Every point the medium can occupy lands on the grid.
void expectCovers(const AirMapLayerExtent& e, const AirMapGeometry& g, int points) {
    Lcg rng;
    int off = 0;
    for (int i = 0; i < points; ++i) {
        double x, z;
        if (e.clipOn) {
            x = e.clipLoX + rng.next() * (e.clipHiX - e.clipLoX);
            z = e.clipLoZ + rng.next() * (e.clipHiZ - e.clipLoZ);
        } else {
            // inside the Render Distance circle
            const double r = e.fadeRadius * std::sqrt(rng.next());
            const double a = rng.next() * 2.0 * 3.14159265358979323846;
            x = e.fadeX + r * std::cos(a);
            z = e.fadeZ + r * std::sin(a);
        }
        const double y = e.bottom + rng.next() * (e.top - e.bottom);
        double fu, fv;
        texelOf(g, x, y, z, fu, fv);
        // A HAIR OF SLACK for float rounding in the planner, which the kernel matches by
        // reading the edge texels with a clamp.
        const double slack = 1e-3;
        if (fu < -slack || fv < -slack || fu > g.dimU + slack || fv > g.dimV + slack) ++off;
    }
    PL_CHECK_EQ(off, 0);
}

AirMapLayerExtent field(float bottom, float top, float radius) {
    AirMapLayerExtent e;
    e.present    = true;
    e.bottom     = bottom;
    e.top        = top;
    e.fadeX      = 1234.0f;
    e.fadeZ      = -567.0f;
    e.fadeRadius = radius;
    return e;
}

AirMapLayerExtent hero(float bottom, float top) {
    AirMapLayerExtent e = field(bottom, top, 40000.0f);
    e.clipOn  = true;
    e.clipLoX = 3000.0f;  e.clipHiX = 7200.0f;
    e.clipLoZ = -1500.0f; e.clipHiZ = 2700.0f;
    return e;
}

} // namespace

PL_TEST(EveryCumulusPointsShadowLandsOnTheGrid) {
    for (double el : { 1.5, 5.0, 12.0, 30.0, 60.0, 89.0 }) {
        for (double az : { 0.0, 45.0, 135.0, 200.0, 290.0 }) {
            const Sun s = sunAt(el, az);
            const AirMapLayerExtent e = field(700.0f, 3100.0f, 40000.0f);
            const AirMapGeometry g = planLayerAirMap(e, s.x, s.y, s.z, 512, 16);
            PL_CHECK(g.present == 1);
            expectCovers(e, g, 4000);
        }
    }
}

PL_TEST(EveryHeroPointsShadowLandsOnItsSmallGrid) {
    for (double el : { 3.0, 20.0, 70.0 }) {
        for (double az : { 10.0, 160.0, 250.0 }) {
            const Sun s = sunAt(el, az);
            const AirMapLayerExtent e = hero(800.0f, 4200.0f);
            const AirMapGeometry g = planLayerAirMap(e, s.x, s.y, s.z, 512, 16);
            PL_CHECK(g.present == 1);
            expectCovers(e, g, 4000);
            // THE POINT OF THE BOX: a hero's grid is far finer than the field's.
            PL_CHECK(g.texelU < 40.0f);
        }
    }
}

// The box is the footprint plus the sun's stretch, and no more.
PL_TEST(TheGridIsTheFootprintStretchedAwayFromTheSun) {
    const Sun s = sunAt(10.0, 135.0);
    const AirMapLayerExtent e = field(700.0f, 3100.0f, 40000.0f);
    const AirMapGeometry g = planLayerAirMap(e, s.x, s.y, s.z, 512, 16);
    const double stretch = (3100.0 - 700.0) / std::tan(10.0 * kDeg);
    PL_CHECK_NEAR(g.dimU * g.texelU, 80000.0 + stretch, 1.0);
    PL_CHECK_NEAR(g.dimV * g.texelV, 80000.0, 1.0);
    // U is the sun's azimuth, so the stretch is all on the low side.
    PL_CHECK_NEAR(g.loU, -(40000.0 + stretch), 1.0);
    PL_CHECK_NEAR(g.axisUX, std::sin(135.0 * kDeg), 1e-5);
    PL_CHECK_NEAR(g.axisUZ, std::cos(135.0 * kDeg), 1e-5);
}

PL_TEST(TexelsAreSquareAndTheBudgetHolds) {
    for (double el : { 2.0, 8.0, 45.0 }) {
        const Sun s = sunAt(el, 70.0);
        const AirMapGeometry g = planLayerAirMap(field(700.0f, 3100.0f, 40000.0f),
                                                 s.x, s.y, s.z, 512, 16);
        PL_CHECK_NEAR(g.texelU / g.texelV, 1.0, 0.02);
        // Rounding up each side can add a row and a column to the budget, no more.
        PL_CHECK(static_cast<long long>(g.dimU) * g.dimV <= 513LL * 513LL + 513LL);
        PL_CHECK(g.dimU >= 2 && g.dimV >= 2);
    }
}

// No column takes more than the step budget, however long the sun's climb.
PL_TEST(AColumnNeverTakesMoreThanItsBudgetOfSteps) {
    for (double el : { 1.2, 3.0, 10.0, 60.0 }) {
        const Sun s = sunAt(el, 180.0);
        const AirMapGeometry g = planLayerAirMap(field(700.0f, 3100.0f, 40000.0f),
                                                 s.x, s.y, s.z, 512, 16);
        const double climb = (g.top - g.bottom) / g.sunY;
        PL_CHECK(climb / g.step <= kAirMapColumnSteps + 1.0);
        PL_CHECK(g.step >= kAirMapMinStep);
    }
}

PL_TEST(StraightOverheadThereIsNoStretch) {
    const AirMapGeometry g = planLayerAirMap(field(700.0f, 3100.0f, 10000.0f),
                                             0.0f, 1.0f, 0.0f, 256, 16);
    PL_CHECK(g.present == 1);
    PL_CHECK_NEAR(g.dimU * g.texelU, 20000.0, 1.0);
    PL_CHECK_NEAR(g.dimV * g.texelV, 20000.0, 1.0);
}

PL_TEST(BelowOneDegreeTheRendererKeepsTheShadowRay) {
    AirMapLayerExtent layers[2] = { field(6400.0f, 9000.0f, 40000.0f),
                                    field(700.0f, 3100.0f, 40000.0f) };
    const Sun low = sunAt(0.8, 180.0);
    PL_CHECK(planAirMaps(layers, low.x, low.y, low.z, 512, true).on == 0);
    const Sun ok = sunAt(1.2, 180.0);
    PL_CHECK(planAirMaps(layers, ok.x, ok.y, ok.z, 512, true).on == 1);
    PL_CHECK(planAirMaps(layers, ok.x, ok.y, ok.z, 512, false).on == 0);
}

// Both maps share one buffer: the cumulus's starts where the cirrus's ends.
PL_TEST(TheTwoMapsShareOneBufferEndToEnd) {
    AirMapLayerExtent layers[2] = { field(6400.0f, 9000.0f, 40000.0f),
                                    field(700.0f, 3100.0f, 40000.0f) };
    const Sun s = sunAt(20.0, 100.0);
    const AirMapPlan p = planAirMaps(layers, s.x, s.y, s.z, 512, true);
    PL_CHECK(p.layer[0].present == 1 && p.layer[1].present == 1);
    PL_CHECK_EQ(p.layer[0].offset, 0);
    PL_CHECK_EQ(p.layer[1].offset, airMapFloats(p.layer[0]));
    PL_CHECK_EQ(p.totalFloats, airMapFloats(p.layer[0]) + airMapFloats(p.layer[1]));
    PL_CHECK_EQ(p.layer[0].slices, kAirMapSlicesCirrus);
    PL_CHECK_EQ(p.layer[1].slices, kAirMapSlicesCumulus);
    // The cirrus gets a quarter of the texels.
    PL_CHECK(static_cast<long long>(p.layer[0].dimU) * p.layer[0].dimV * 3 <
             static_cast<long long>(p.layer[1].dimU) * p.layer[1].dimV);
}

// An absent layer, or one with no room across, has no map, which the kernel reads as 1.
PL_TEST(AnAbsentLayerHasNoMap) {
    AirMapLayerExtent layers[2] = { field(6400.0f, 9000.0f, 40000.0f), AirMapLayerExtent{} };
    const Sun s = sunAt(20.0, 100.0);
    const AirMapPlan p = planAirMaps(layers, s.x, s.y, s.z, 512, true);
    PL_CHECK(p.on == 1);
    PL_CHECK(p.layer[1].present == 0);
    PL_CHECK_EQ(airMapFloats(p.layer[1]), 0);

    // Ice switched off is a slab with no depth, far below the ground.
    AirMapLayerExtent off = field(-1.0e6f, -1.0e6f, 40000.0f);
    PL_CHECK(planLayerAirMap(off, s.x, s.y, s.z, 512, 8).present == 0);

    // A hero box that the Render Distance does not reach.
    AirMapLayerExtent far = hero(800.0f, 4200.0f);
    far.fadeRadius = 1000.0f;
    PL_CHECK(planLayerAirMap(far, s.x, s.y, s.z, 512, 16).present == 0);
}
