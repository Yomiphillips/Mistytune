// The ground's skylight, cached per render thread.
//
// A FILE OF ITS OWN so KernelApi.h, which the effect and the CLI include, need not pull
// in Shading.h to reach the reference sky. See groundSkyLightFor there for the integral
// and SkyInput.groundSkyLight in SkyLib.slang for why the ground needs it.

#include "KernelApi.h"
#include "Shading.h"

namespace plugin::kernel {

namespace {

// The grid. 32 x 64 is 2048 marches, and within 0.1% of a grid sixteen times as fine up
// to a 45 degree sun, 0.5% near the zenith (TestAtmosphere, GroundSkyLightConverges).
constexpr int kGroundSkyMuSteps      = 32;
constexpr int kGroundSkyAzimuthSteps = 64;

// EVERY FIELD THE REFERENCE SKY READS, bar the disc's radius, which the integral sets to
// zero itself. The table is a function of three of these, so the key covers it too.
struct GroundSkyKey {
    float v[8];
    bool operator==(const GroundSkyKey& o) const {
        for (int i = 0; i < 8; ++i) if (v[i] != o.v[i]) return false;
        return true;
    }
};

GroundSkyKey groundSkyKeyOf(const cloud::FieldParams& f) {
    const cloud::AtmosphereParams& a = f.atmosphere;
    return GroundSkyKey{ { f.physics.planetRadius, f.physics.scaleHeight, a.turbidity,
                           a.mieAnisotropy, a.sunAzimuth, a.sunElevation, a.sunIntensity,
                           a.groundAlbedo } };
}

} // namespace

// THREAD-LOCAL for the reason the transmittance table's cache is (KernelApi.h): several
// frames are in flight at once and a shared cache would want a lock on the render path.
// UNLIKE the table, THE SUN IS IN THE KEY, so dragging it costs one integral per change.
// That is a few milliseconds against a path trace.
void deriveGroundSkyLight(RenderRequest& req) {
    static thread_local GroundSkyKey built{};
    static thread_local float        light[3] = { 0.0f, 0.0f, 0.0f };
    static thread_local bool         haveBuilt = false;

    const GroundSkyKey key = groundSkyKeyOf(req.field);
    if (!haveBuilt || !(built == key)) {
        groundSkyLightFor(req.field, static_cast<const float*>(req.transmittanceBuffer),
                          kGroundSkyMuSteps, kGroundSkyAzimuthSteps, light);
        built = key;
        haveBuilt = true;
    }
    req.groundSkyLight[0] = light[0];
    req.groundSkyLight[1] = light[1];
    req.groundSkyLight[2] = light[2];
}

} // namespace plugin::kernel
