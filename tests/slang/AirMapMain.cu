// slang.airMap -- the clouds' shadow maps, against answers they did not compute.
//
// ===========================================================================
// WHAT THE MAP HAS TO GET RIGHT, AND WHAT EACH CHECK HOLDS IT TO.
//
// The map replaces a shadow ray with a table read, so it is only as good as two things:
// the TABLE (does a lookup give the transmittance to the sun from that point?) and the
// INTEGRAL over it (does airShadowLoss add up the shadowed airlight correctly?). They
// fail differently, so they are checked apart.
//
//   1. the lookup against a CLOSED FORM. The medium is one Gaussian core, whose line
//      integral is an erf, so the true transmittance from any point is exact in double.
//      Points below the slab are exact up to the bilinear read; points inside it also
//      carry the slice interpolation. They are reported apart.
//   2. airShadowLoss's mean over its jitter against airMapLossRef, the same integral by
//      a different method: fixed midpoints, uniform, tens of thousands of them. A wrong
//      step weight, a wrong optical depth or a wrong colour shows here.
//   3. a ray whose air no shadow reaches loses EXACTLY nothing, so the sky it sees is
//      the sky bit for bit.
//   4. with no maps at all the loss is exactly zero.
//   5. the build is deterministic: built twice, the bytes agree.
//   6. the shadow on the GROUND (build 19): a ray down answers the closed form where it
//      lands, and a ray up answers exactly 1.
//
// THE PLAN COMES FROM planAirMaps, the production planner, fed the medium's own extent.
// So these checks also cover the grid's placement: a grid that missed part of the
// shadow would fail check 1 with a lookup of 1 where the answer is dark.
// ===========================================================================

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <vector>

#include <cuda_runtime.h>

#include "Shading.h"

#include "AirMap.cu"

#include "SlangBridge.h"

#include "AirMapHost.h"

namespace {

using plugin::kernel::AirMapGeometry;
using plugin::kernel::AirMapLayerExtent;
using plugin::kernel::AirMapPlan;

struct CudaV {
    static __host__ __device__ float2 v2(float x, float y) { return make_float2(x, y); }
    static __host__ __device__ float3 v3(float x, float y, float z) { return make_float3(x, y, z); }
    static __host__ __device__ int3 i3(int x, int y, int z) { return make_int3(x, y, z); }
    static __host__ __device__ int2 i2(int x, int y) { return make_int2(x, y); }
    static __host__ __device__ float4 v4(float x, float y, float z, float w) { return make_float4(x, y, z, w); }
};

template <typename T>
T* upload(const std::vector<T>& v) {
    T* d = nullptr;
    if (cudaMalloc(&d, v.size() * sizeof(T)) != cudaSuccess) return nullptr;
    cudaMemcpy(d, v.data(), v.size() * sizeof(T), cudaMemcpyHostToDevice);
    return d;
}

template <typename T>
T* deviceArray(size_t n) {
    T* d = nullptr;
    if (cudaMalloc(&d, n * sizeof(T)) != cudaSuccess) return nullptr;
    return d;
}

template <typename T>
StructuredBuffer<T> readView(T* d, size_t n) {
    StructuredBuffer<T> b;
    b.data  = d;
    b.count = n;
    return b;
}

template <typename T>
RWStructuredBuffer<T> writeView(T* d, size_t n) {
    RWStructuredBuffer<T> b;
    b.data  = d;
    b.count = n;
    return b;
}

// THE MEDIUM: one Gaussian core in a slab, and nothing else. Mode 1 with no background.
//
// SIZED SO THE CLOSED FORM NEEDS NO CLIPPING. The core is 300 m across and a kilometre
// from both faces of the slab, so the density at a face is e^-11 of the peak, and the box
// is 13 radii out. The erf over the ray's whole run is then the answer to 1e-5.
constexpr float kBottom = 1000.0f, kTop = 3000.0f;
constexpr float kCoreY = 2000.0f, kCoreR = 300.0f, kCoreSigma = 0.02f;
constexpr float kBox = 4000.0f;

Medium_0 coreMedium() {
    Medium_0 m;
    std::memset(static_cast<void*>(&m), 0, sizeof m);
    m.slabTop_0      = kTop;
    m.slabBottom_0   = kBottom;
    m.majorant_0     = kCoreSigma;
    m.density_0      = 0.0f;
    m.coreCentre_0   = make_float3(0.0f, kCoreY, 0.0f);
    m.coreRadius_0   = kCoreR;
    m.coreDensity_0  = kCoreSigma;
    m.mode_0         = 1;
    m.clipOn_0       = 1;
    m.clipLo_0       = make_float2(-kBox, -kBox);
    m.clipHi_0       = make_float2(kBox, kBox);
    m.fadeRadius_0   = 0.0f;
    return m;
}

// The true transmittance from p towards `sun`, in double: the core's line integral.
double trueTransmittance(double px, double py, double pz, const double sun[3]) {
    if (py >= kTop) return 1.0;
    const double wx = px, wy = py - kCoreY, wz = pz;
    const double wd = wx * sun[0] + wy * sun[1] + wz * sun[2];
    const double b2 = wx * wx + wy * wy + wz * wz - wd * wd;
    const double s0 = -wd;                                   // closest approach
    const double sExit = (kTop - py) / sun[1];
    const double r = kCoreR;
    const double integral = r * std::sqrt(3.14159265358979323846) * 0.5 * std::exp(-b2 / (r * r)) *
                            (std::erf((sExit - s0) / r) - std::erf((0.0 - s0) / r));
    return std::exp(-kCoreSigma * integral);
}

SkyInput_0 skyFor(const plugin::cloud::FieldParams& field, float* dLut, size_t lutCount) {
    SkyInput_0 s;
    std::memset(static_cast<void*>(&s), 0, sizeof s);
    s.transmittanceLut_0.data  = dLut;
    s.transmittanceLut_0.count = lutCount;
    s.planetRadius_0     = field.physics.planetRadius;
    s.scaleHeight_0      = field.physics.scaleHeight;
    s.turbidity_0        = field.atmosphere.turbidity;
    s.mieAnisotropy_0    = field.atmosphere.mieAnisotropy;
    s.sunAzimuth_0       = field.atmosphere.sunAzimuth;
    s.sunElevation_0     = field.atmosphere.sunElevation;
    s.sunIntensity_0     = field.atmosphere.sunIntensity;
    s.sunAngularRadius_0 = field.atmosphere.sunAngularRadius;
    s.groundAlbedo_0     = field.atmosphere.groundAlbedo;
    return s;
}

// A tiny deterministic generator for the test points.
struct Lcg {
    unsigned long long s = 0x9e3779b97f4a7c15ull;
    double next() {
        s = s * 6364136223846793005ull + 1442695040888963407ull;
        return static_cast<double>(s >> 11) * (1.0 / 9007199254740992.0);
    }
};

// One sun: plan, build, and every check. Returns the number of failed checks.
int runSun(float elevation, float azimuth) {
    int failures = 0;
    std::printf("\n== sun elevation %.1f, azimuth %.1f\n", elevation, azimuth);

    plugin::cloud::FieldParams field;
    field.atmosphere.sunElevation = elevation;
    field.atmosphere.sunAzimuth   = azimuth;
    field.atmosphere.turbidity    = 3.0f;

    const plugin::kernel::Vec3 sv = plugin::kernel::sunDirection(field.atmosphere);
    const double sun[3] = { sv.x, sv.y, sv.z };

    const Medium_0 medium = coreMedium();

    AirMapLayerExtent layers[2];
    layers[1] = plugin::kernel::airMapExtentOf(medium, true);
    const AirMapPlan plan = plugin::kernel::planAirMaps(layers, sv.x, sv.y, sv.z, 512, true);
    const AirMapGeometry& g = plan.layer[1];
    if (!plan.on || !g.present || plan.layer[0].present) {
        std::printf("FAIL: the planner gave no map for a present layer\n");
        return 1;
    }
    std::printf("   grid %d x %d x %d, texel %.1f x %.1f m, step %.1f m\n",
                g.dimU, g.dimV, g.slices, g.texelU, g.texelV, g.step);

    const size_t floats = static_cast<size_t>(plugin::kernel::airMapFloats(g));
    float* dTex  = deviceArray<float>(floats);
    float* dTex2 = deviceArray<float>(floats);
    if (!dTex || !dTex2) { std::printf("FAIL: allocation\n"); return 1; }

    LayerShadowMap_0 map;
    std::memset(static_cast<void*>(&map), 0, sizeof map);
    plugin::kernel::fillAirMap<CudaV>(g, dTex, map);

    LayerShadowMap_0 none;
    std::memset(static_cast<void*>(&none), 0, sizeof none);
    plugin::kernel::fillAirMap<CudaV>(AirMapGeometry{}, nullptr, none);

    StructuredBuffer<float2> drift = readView<float2>(nullptr, 0);
    const int texels = g.dimU * g.dimV;
    airMapBuild<<<(texels + 63) / 64, 64>>>(medium, drift, map, writeView(dTex, floats), texels);
    airMapBuild<<<(texels + 63) / 64, 64>>>(medium, drift, map, writeView(dTex2, floats), texels);
    if (cudaDeviceSynchronize() != cudaSuccess) { std::printf("FAIL: build launch\n"); return 1; }

    // --- 5. determinism --------------------------------------------------------------
    {
        std::vector<float> a(floats), b(floats);
        cudaMemcpy(a.data(), dTex,  floats * sizeof(float), cudaMemcpyDeviceToHost);
        cudaMemcpy(b.data(), dTex2, floats * sizeof(float), cudaMemcpyDeviceToHost);
        const bool same = std::memcmp(a.data(), b.data(), floats * sizeof(float)) == 0;
        std::printf("5. built twice: %s\n", same ? "identical" : "DIFFERENT");
        if (!same) ++failures;
    }

    // --- 6. the shadow on the ground --------------------------------------------------
    //
    // Rays from high above the core, down to the flat ground: each must answer the closed
    // form at the spot it lands on, to the below-slab tolerance, because the ground is
    // below the slab. Rays that go up must answer exactly 1.
    {
        const double across = std::sqrt(sun[0] * sun[0] + sun[2] * sun[2]);
        const double back = kCoreY / (sun[1] / across);
        const float3 origin = make_float3(static_cast<float>(-sun[0] / across * back), 4000.0f,
                                          static_cast<float>(-sun[2] / across * back));
        Lcg rng;
        std::vector<float3> dirs;
        for (int i = 0; i < 4000; ++i) {
            // down, landing within 1 km of the shadow's centre either way. The core is 300 m,
            // so a wider spread (45 degrees was tried) left too few landings in its shadow
            // at a high sun for the count below to mean anything.
            const double x = (rng.next() * 0.5 - 0.25), z = (rng.next() * 0.5 - 0.25);
            const double n = std::sqrt(x * x + z * z + 1.0);
            dirs.push_back(make_float3(static_cast<float>(x / n), static_cast<float>(-1.0 / n),
                                       static_cast<float>(z / n)));
        }
        for (int i = 0; i < 200; ++i) dirs.push_back(make_float3(0.1f, 0.3f + 0.003f * i, 0.2f));
        const int n = static_cast<int>(dirs.size());
        float3* dDirs = upload(dirs);
        float*  dLit  = deviceArray<float>(n);
        airMapGround<<<(n + 63) / 64, 64>>>(none, map, origin, readView(dDirs, n),
                                            writeView(dLit, n), n);
        cudaDeviceSynchronize();
        std::vector<float> lit(n);
        cudaMemcpy(lit.data(), dLit, n * sizeof(float), cudaMemcpyDeviceToHost);

        double worst = 0.0, sum = 0.0;
        int shaded = 0, upNotOne = 0;
        for (int i = 0; i < n; ++i) {
            if (dirs[i].y >= 0.0f) {
                if (lit[i] != 1.0f) ++upNotOne;
                continue;
            }
            const double t = origin.y / -static_cast<double>(dirs[i].y);
            const double gx = origin.x + dirs[i].x * t, gz = origin.z + dirs[i].z * t;
            const double want = trueTransmittance(gx, 0.0, gz, sun);
            if (want < 0.9) ++shaded;
            const double e = std::fabs(static_cast<double>(lit[i]) - want);
            worst = std::fmax(worst, e);
            sum += e;
        }
        const double mean = sum / 4000.0;
        const bool ok = upNotOne == 0 && mean <= 0.002 && shaded >= 200;
        std::printf("6. ground: %d of 4000 landings shaded, mean |dT| %.5f (<= 0.002), worst %.4f; "
                    "%d upward rays not exactly 1  %s\n", shaded, mean, worst, upNotOne,
                    ok ? "ok" : "FAIL");
        if (!ok) ++failures;
        cudaFree(dDirs);
        cudaFree(dLit);
    }

    // --- 1. the lookup against the closed form ----------------------------------------
    {
        // Points over the whole shadow: across the core's box, stretched away from the sun
        // as far as its shadow reaches the ground, and from the ground to above the slab.
        const double across = std::sqrt(sun[0] * sun[0] + sun[2] * sun[2]);
        const double reachBack = kTop / (sun[1] / across);
        Lcg rng;
        std::vector<float3> pts;
        for (int i = 0; i < 40000; ++i) {
            const double t = rng.next();
            const double y = rng.next() * 3400.0;
            // along the anti-sun direction by up to reachBack, plus scatter across
            const double back = t * (reachBack + 2000.0) - 1000.0;
            const double side = (rng.next() * 2.0 - 1.0) * 1500.0;
            const double ax = sun[0] / across, az = sun[2] / across;
            pts.push_back(make_float3(static_cast<float>(-ax * back - az * side),
                                      static_cast<float>(y),
                                      static_cast<float>(-az * back + ax * side)));
        }
        const int n = static_cast<int>(pts.size());
        float3* dPts = upload(pts);
        float*  dT   = deviceArray<float>(n);
        airMapLookup<<<(n + 63) / 64, 64>>>(map, readView(dPts, n), writeView(dT, n), n);
        cudaDeviceSynchronize();
        std::vector<float> got(n);
        cudaMemcpy(got.data(), dT, n * sizeof(float), cudaMemcpyDeviceToHost);

        std::vector<double> errBelow, errInside;
        int shadowed = 0;
        for (int i = 0; i < n; ++i) {
            const double want = trueTransmittance(pts[i].x, pts[i].y, pts[i].z, sun);
            if (want < 0.9) ++shadowed;
            const double e = std::fabs(static_cast<double>(got[i]) - want);
            if (pts[i].y < kBottom)   errBelow.push_back(e);
            else if (pts[i].y < kTop) errInside.push_back(e);
            else if (got[i] != 1.0f) {
                std::printf("   above the slab the map said %.6f, not exactly 1\n", got[i]);
                ++failures;
                break;
            }
        }
        const auto report = [&](const char* what, std::vector<double>& e,
                                double meanLimit, double p99Limit) {
            std::sort(e.begin(), e.end());
            double mean = 0.0;
            for (double x : e) mean += x;
            mean /= static_cast<double>(e.size());
            const double p99 = e[static_cast<size_t>(0.99 * static_cast<double>(e.size() - 1))];
            const bool ok = mean <= meanLimit && p99 <= p99Limit;
            std::printf("1. %-13s %6zu points: mean |dT| %.5f (<= %.4f), 99th %.5f (<= %.3f), "
                        "worst %.4f  %s\n", what, e.size(), mean, meanLimit, p99, p99Limit,
                        e.back(), ok ? "ok" : "FAIL");
            if (!ok) ++failures;
        };
        std::printf("   %d of %d points are in the shadow (T < 0.9)\n", shadowed, n);
        if (shadowed < n / 50) {
            std::printf("FAIL: too few points in the shadow to test anything\n");
            ++failures;
        }
        // BELOW THE SLAB the column is exact but for the bilinear read across texels.
        // INSIDE IT the slices are 133 m apart in altitude, and between two of them the
        // sun ray can cross the edge of the core, so the interpolation error is larger.
        report("below slab", errBelow, 0.002, 0.02);
        report("inside slab", errInside, 0.01, 0.12);
        cudaFree(dPts);
        cudaFree(dT);
    }

    // --- 2, 3, 4. the loss against the reference integral --------------------------------
    {
        std::vector<float> lut(static_cast<size_t>(plugin::cloud::kTransmittanceFloats));
        plugin::cloud::buildTransmittanceLut(
            plugin::cloud::transmittanceParamsFrom(field.physics, field.atmosphere),
            lut.data(), plugin::cloud::kTransmittanceFloats);
        float* dLut = upload(lut);
        const SkyInput_0 sky = skyFor(field, dLut, lut.size());

        // The eye stands in the core's shadow on the ground, and looks along a spread of
        // directions: some through the shadow column, some away from it.
        const double across = std::sqrt(sun[0] * sun[0] + sun[2] * sun[2]);
        const double back = kCoreY / (sun[1] / across);
        const float3 eye = make_float3(static_cast<float>(-sun[0] / across * (back + 1500.0)),
                                       2.0f,
                                       static_cast<float>(-sun[2] / across * (back + 1500.0)));

        const int jitters = 4096;
        float3* dLoss = deviceArray<float3>(jitters);
        float3* dRef  = deviceArray<float3>(1);

        // One ray: the jitter's mean, the fine march's answer, the ray's whole airlight, and
        // whether any single jitter lost anything at all.
        struct RayResult {
            double mean[3], want[3], air[3];
            bool   anyLoss;
        };
        const auto runRay = [&](float3 from, float3 rd, float dist) {
            RayResult r;
            airMapLoss<<<(jitters + 63) / 64, 64>>>(sky, none, map, from, rd, dist,
                                                   writeView(dLoss, jitters), jitters);
            std::vector<float3> loss(jitters);
            float3 ref, air;
            airMapLossRef<<<1, 1>>>(sky, none, map, from, rd, dist, 20000, 0, writeView(dRef, 1));
            cudaMemcpy(&ref, dRef, sizeof(float3), cudaMemcpyDeviceToHost);
            airMapLossRef<<<1, 1>>>(sky, none, map, from, rd, dist, 20000, 1, writeView(dRef, 1));
            cudaMemcpy(&air, dRef, sizeof(float3), cudaMemcpyDeviceToHost);
            cudaMemcpy(loss.data(), dLoss, jitters * sizeof(float3), cudaMemcpyDeviceToHost);
            r.mean[0] = r.mean[1] = r.mean[2] = 0.0;
            r.anyLoss = false;
            for (const float3& l : loss) {
                r.mean[0] += l.x; r.mean[1] += l.y; r.mean[2] += l.z;
                if (l.x != 0.0f || l.y != 0.0f || l.z != 0.0f) r.anyLoss = true;
            }
            for (double& m : r.mean) m /= jitters;
            r.want[0] = ref.x; r.want[1] = ref.y; r.want[2] = ref.z;
            r.air[0]  = air.x; r.air[1]  = air.y; r.air[2]  = air.z;
            return r;
        };

        // 2. THE EYE STANDS IN THE CORE'S SHADOW and looks every way. The error is judged
        // against the ray's own airlight as well as the loss itself: the core's Gaussian
        // tail shadows every ray by a millionth, and a relative error on a millionth
        // measures nothing.
        int compared = 0, significant = 0;
        double worstOfLoss = 0.0, worstOfAir = 0.0;
        for (int e = 0; e < 5; ++e) {
            const double elDeg = e == 0 ? 1.0 : e == 1 ? 5.0 : e == 2 ? 15.0 : e == 3 ? 35.0 : 70.0;
            const double el = elDeg * 0.017453292519943295;
            for (int a = 0; a < 12; ++a) {
                const double az = a * 30.0 * 0.017453292519943295;
                const float3 rd = make_float3(static_cast<float>(std::sin(az) * std::cos(el)),
                                              static_cast<float>(std::sin(el)),
                                              static_cast<float>(std::cos(az) * std::cos(el)));
                for (int d = 0; d < 2; ++d) {
                    const float dist = d == 0 ? 1e30f : 2500.0f;
                    const RayResult r = runRay(eye, rd, dist);
                    ++compared;
                    for (int c = 0; c < 3; ++c) {
                        const double err = std::fabs(r.mean[c] - r.want[c]);
                        worstOfAir = std::fmax(worstOfAir, err / r.air[c]);
                        if (r.want[c] > 0.01 * r.air[c]) {
                            ++significant;
                            worstOfLoss = std::fmax(worstOfLoss, err / r.want[c]);
                        }
                        if (err > 0.005 * r.want[c] + 2e-4 * r.air[c]) {
                            std::printf("2. FAIL el %.0f az %d dist %.0f ch %d: mean %.6g ref %.6g "
                                        "air %.6g\n", elDeg, a * 30, dist, c, r.mean[c], r.want[c],
                                        r.air[c]);
                            ++failures;
                        }
                    }
                }
            }
        }
        std::printf("2. %d rays from inside the shadow: the jitter's mean against the fine march,\n"
                    "   worst %.3f%% of the loss (%d channels losing over 1%% of their air), "
                    "worst %.4f%% of the air\n", compared, 100.0 * worstOfLoss, significant,
                    100.0 * worstOfAir);
        if (significant < 30) {
            std::printf("FAIL: only %d channels lost enough air to judge\n", significant);
            ++failures;
        }

        // 3. AN EYE OUTSIDE THE GRID, LOOKING AWAY FROM IT, low enough that its air never
        // reaches the grid: every jitter must lose exactly nothing, and so must the
        // reference. Nothing lost means the sky the ray escapes to is the sky, bit for bit.
        const float3 far = make_float3(static_cast<float>(sun[0] / across * 30000.0), 2.0f,
                                       static_cast<float>(sun[2] / across * 30000.0));
        int zeroRays = 0;
        for (double elDeg : { 0.5, 1.0, 2.0 }) {
            for (double off : { -20.0, 0.0, 20.0 }) {
                const double az = std::atan2(sun[0], sun[2]) + off * 0.017453292519943295;
                const double el = elDeg * 0.017453292519943295;
                const float3 rd = make_float3(static_cast<float>(std::sin(az) * std::cos(el)),
                                              static_cast<float>(std::sin(el)),
                                              static_cast<float>(std::cos(az) * std::cos(el)));
                const RayResult r = runRay(far, rd, 1e30f);
                if (r.want[0] != 0.0 || r.want[1] != 0.0 || r.want[2] != 0.0) continue;
                ++zeroRays;
                if (r.anyLoss) {
                    std::printf("3. FAIL: a ray no shadow reaches lost airlight (el %.1f)\n", elDeg);
                    ++failures;
                }
            }
        }
        std::printf("3. %d rays that never meet the grid lost exactly nothing\n", zeroRays);
        if (zeroRays < 6) {
            std::printf("FAIL: only %d of 9 rays missed the grid\n", zeroRays);
            ++failures;
        }

        // 4. no maps: nothing lost, exactly
        airMapLoss<<<(jitters + 63) / 64, 64>>>(sky, none, none, eye,
                                               make_float3(0.0f, 0.2f, 0.98f), 1e30f,
                                               writeView(dLoss, jitters), jitters);
        cudaDeviceSynchronize();
        std::vector<float3> loss(jitters);
        cudaMemcpy(loss.data(), dLoss, jitters * sizeof(float3), cudaMemcpyDeviceToHost);
        bool allZero = true;
        for (const float3& l : loss) allZero = allZero && l.x == 0.0f && l.y == 0.0f && l.z == 0.0f;
        std::printf("4. no maps: %s\n", allZero ? "nothing lost" : "FAIL, airlight lost");
        if (!allZero) ++failures;

        cudaFree(dLoss);
        cudaFree(dRef);
        cudaFree(dLut);
    }

    cudaFree(dTex);
    cudaFree(dTex2);
    return failures;
}

} // namespace

int main() {
    int count = 0;
    if (cudaGetDeviceCount(&count) != cudaSuccess || count == 0) {
        std::printf("FAIL: no CUDA device\n");
        return 1;
    }

    // A HIGH SUN, A MIDDLING ONE, AND A LOW ONE ON A DIAGONAL AZIMUTH: the low sun
    // stretches the grid eleven times the slab's depth, and the diagonal is where an
    // axis-aligned box would have been twice too big.
    int failures = 0;
    failures += runSun(60.0f, 135.0f);
    failures += runSun(30.0f, 135.0f);
    failures += runSun(5.0f, 225.0f);

    if (failures) {
        std::printf("\n%d CHECK(S) FAILED\n", failures);
        return 1;
    }
    std::printf("\nall checks passed\n");
    return 0;
}
