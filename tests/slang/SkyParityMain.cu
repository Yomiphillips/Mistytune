// The Slang port of the sky, against the hand-written one, BIT FOR BIT.
//
// ===========================================================================
// THIS IS THE TEST THE WHOLE SLANG PORT RESTS ON.
//
// slang.mathParity already proves the PRIMITIVES agree -- exp, sqrt, cos, sin, tan,
// rsqrt, exp2, identical over 44,001 inputs. Given that, the only remaining way for
// src/kernel/slang/Sky.slang to disagree with Shading.h's skyRadiance() is a HUMAN
// TRANSCRIPTION ERROR: a reassociated expression, a dropped clamp, a constant typed
// with one digit wrong.
//
// BOTH SIDES RUN ON THE SAME GPU, in the same build, under the same nvcc flags. That
// is deliberate and it is what makes the comparison sharp: nothing here can be blamed
// on CPU-versus-GPU, on a compiler difference, or on fp-contraction settings. A
// difference is a difference in what somebody typed.
//
// BITWISE, NOT WITHIN TOLERANCE. tests/golden/ compares rendered images at 2/255, and
// a transcription error small enough to hide there is exactly the kind that surfaces
// later as "the sky is subtly wrong at sunset". The two functions are either the same
// arithmetic or they are not.
// ===========================================================================

#include <cstdio>
#include <cmath>
#include <cstring>
#include <vector>

#include <cuda_runtime.h>

// The hand-written reference -- the maths that produced every golden image so far.
#include "Shading.h"

// The Slang port, generated and committed.
#include "Sky.cu"

using plugin::kernel::Vec3;
using plugin::kernel::vec3;

// The reference, wrapped in a kernel so it runs on the same device as the other.
__global__ void handWrittenSky(plugin::cloud::FieldParams field,
                               float originAltitude,
                               const float* lut,
                               const float3* dirs, float3* out, int count) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= count) return;

    const Vec3 d = vec3(dirs[i].x, dirs[i].y, dirs[i].z);
    const Vec3 r = plugin::kernel::skyRadiance(field, originAltitude, d, lut);
    out[i] = make_float3(r.x, r.y, r.z);
}

// ===========================================================================
// THE AIR IN FRONT OF A CLOUD, checked against the sky beside it and against physics.
//
// airSegment has no hand-written twin, so these are identities rather than a diff:
//
//   1. run past the top of the air, its airlight IS skyRadiance's, bit for bit, on a ray
//      that misses the ground -- and never more than the sky on one that hits it
//   2. airTransmittance agrees with its airT
//   3. a short level path at the ground has the closed-form transmittance
//   4. along one ray, the airlight only grows and the transmittance only falls
//   5. the air in front of a point plus what it lets through of the sky behind the point
//      is the sky from the eye -- which is the statement aerial perspective makes
//   6. the shadow point is drawn in proportion to the airlight: a shadow over the first
//      d0 metres removes the airlight of the first d0 metres, in expectation
// ===========================================================================
namespace {

struct AirRun {
    std::vector<float3> airIn, airT, trans, sky;
    std::vector<float>  shadowAt;
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

bool runAir(const SkyInput_0& in, float alt, const std::vector<float3>& dirs,
            const std::vector<float>& dists, const std::vector<float2>& us, AirRun& out) {
    const size_t n = dirs.size();
    float3* dDirs  = upload(dirs);
    float*  dDists = upload(dists);
    float2* dUs    = upload(us);
    float3* dIn    = deviceArray<float3>(n);
    float3* dT     = deviceArray<float3>(n);
    float3* dTr    = deviceArray<float3>(n);
    float*  dAt    = deviceArray<float>(n);
    float3* dSky   = deviceArray<float3>(n);
    if (!dDirs || !dDists || !dUs || !dIn || !dT || !dTr || !dAt || !dSky) return false;

    const int count = static_cast<int>(n);
    airMain<<<(count + 63) / 64, 64>>>(in, alt, readView(dDirs, n), readView(dDists, n),
                                       readView(dUs, n), writeView(dIn, n), writeView(dT, n),
                                       writeView(dTr, n), writeView(dAt, n),
                                       writeView(dSky, n), count);
    const bool ok = cudaDeviceSynchronize() == cudaSuccess;

    out.airIn.resize(n); out.airT.resize(n); out.trans.resize(n);
    out.sky.resize(n);   out.shadowAt.resize(n);
    cudaMemcpy(out.airIn.data(),    dIn,  n * sizeof(float3), cudaMemcpyDeviceToHost);
    cudaMemcpy(out.airT.data(),     dT,   n * sizeof(float3), cudaMemcpyDeviceToHost);
    cudaMemcpy(out.trans.data(),    dTr,  n * sizeof(float3), cudaMemcpyDeviceToHost);
    cudaMemcpy(out.shadowAt.data(), dAt,  n * sizeof(float),  cudaMemcpyDeviceToHost);
    cudaMemcpy(out.sky.data(),      dSky, n * sizeof(float3), cudaMemcpyDeviceToHost);

    cudaFree(dDirs); cudaFree(dDists); cudaFree(dUs); cudaFree(dIn); cudaFree(dT);
    cudaFree(dTr);   cudaFree(dAt);    cudaFree(dSky);
    return ok;
}

float3 dirAt(float elevationDeg, float azimuthDeg) {
    const float el = elevationDeg * 0.01745329252f;
    const float az = azimuthDeg * 0.01745329252f;
    return make_float3(std::sin(az) * std::cos(el), std::sin(el), std::cos(az) * std::cos(el));
}

float channel(const float3& v, int c) { return c == 0 ? v.x : (c == 1 ? v.y : v.z); }
float lum(const float3& v) { return v.x + v.y + v.z; }

bool sameBits(float a, float b) {
    unsigned ua = 0, ub = 0;
    std::memcpy(&ua, &a, sizeof(ua));
    std::memcpy(&ub, &b, sizeof(ub));
    return ua == ub;
}

// ===========================================================================
// THE AIRLIGHT, INTEGRATED ON THE HOST IN DOUBLE, as a reference for the kernel's march.
//
// THE SAME PHYSICS AND THE SAME SUN TABLE, with two knobs: the number of quadratic steps,
// and whether a step's in-scatter is dimmed by the view depth at its END -- which is what
// skyRadiance does -- or at its MIDDLE. 4096 steps at the middle is converged; 24 at the
// end reproduces the kernel's quadrature, so the two together say how much of any
// disagreement is the quadrature and how much is the code.
// ===========================================================================
struct AirRef {
    double in[3];
    double t[3];
};

AirRef referenceAir(const std::vector<float>& lut, const plugin::cloud::TransmittanceParams& tp,
                    const SkyInput_0& in, double alt, const float3& dir, double dist,
                    int steps, bool midpoint) {
    AirRef out{};
    for (int c = 0; c < 3; ++c) { out.in[c] = 0.0; out.t[c] = 1.0; }

    const double kDeg = 0.017453292519943295;
    const double sAz = static_cast<double>(in.sunAzimuth_0) * kDeg;
    const double sEl = static_cast<double>(in.sunElevation_0) * kDeg;
    const double sun[3] = { std::sin(sAz) * std::cos(sEl), std::sin(sEl), std::cos(sAz) * std::cos(sEl) };
    const double d[3]   = { dir.x, dir.y, dir.z };

    const double R  = in.planetRadius_0;
    const double H  = in.scaleHeight_0;
    const double top = H * 8.0;
    const double h0 = alt > 0.0 ? alt : 0.0;

    // The ray against the ground and the top of the air, as the kernel's shell algebra.
    const double b = (R + h0) * d[1];
    const double cG = (h0) * (h0 + 2.0 * R);
    const double cT = (h0 - top) * (h0 - top + 2.0 * R + 2.0 * top);
    const double discT = b * b - cT;
    if (discT < 0.0) return out;
    const double tTop = -b + std::sqrt(discT);
    if (tTop <= 0.0) return out;
    const double discG = b * b - cG;
    const double tG = discG >= 0.0 ? -b - std::sqrt(discG) : -1.0;
    double tMax = tG > 0.0 ? tG : tTop;
    if (dist < tMax) tMax = dist;

    const double betaR[3] = { 5.802e-6, 13.558e-6, 33.1e-6 };
    const double betaM    = 3.996e-6 * (static_cast<double>(in.turbidity_0) / 2.2);
    const double betaMExt = betaM * 1.11;

    double cosT = d[0] * sun[0] + d[1] * sun[1] + d[2] * sun[2];
    cosT = cosT < -1.0 ? -1.0 : (cosT > 1.0 ? 1.0 : cosT);
    const double phaseR = 0.0596831 * (1.0 + cosT * cosT);
    double g = in.mieAnisotropy_0;
    g = g < -0.95 ? -0.95 : (g > 0.95 ? 0.95 : g);
    const double hg = 1.0 + g * g - 2.0 * g * cosT;
    const double phaseM = (1.0 - g * g) / (12.566370614 * hg * std::sqrt(hg));

    double depthR = 0.0, depthM = 0.0, tPrev = 0.0;
    double sum[3] = { 0.0, 0.0, 0.0 };
    for (int i = 0; i < steps; ++i) {
        const double tNext = tMax * static_cast<double>((i + 1) * (i + 1)) /
                             static_cast<double>(steps * steps);
        const double dt = tNext - tPrev;
        const double tMid = 0.5 * (tPrev + tNext);
        tPrev = tNext;

        const double p[3] = { d[0] * tMid, R + h0 + d[1] * tMid, d[2] * tMid };
        const double r = std::sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2]);
        const double h = r - R > 0.0 ? r - R : 0.0;

        const double dR = std::exp(-h / H) * dt;
        const double dM = std::exp(-h / 1200.0) * dt;

        const double atR = midpoint ? depthR + 0.5 * dR : depthR + dR;
        const double atM = midpoint ? depthM + 0.5 * dM : depthM + dM;
        depthR += dR;
        depthM += dM;

        const double mu = (p[0] * sun[0] + p[1] * sun[1] + p[2] * sun[2]) / r;
        float sR = 0.0f, sG = 0.0f, sB = 0.0f;
        plugin::cloud::sampleTransmittance(lut.data(), tp, static_cast<float>(h),
                                           static_cast<float>(mu), sR, sG, sB);
        const double sunT[3] = { sR, sG, sB };

        for (int c = 0; c < 3; ++c) {
            const double viewT = std::exp(-(betaR[c] * atR + betaMExt * atM));
            sum[c] += viewT * sunT[c] * (betaR[c] * phaseR * dR + betaM * phaseM * dM);
        }
    }

    const double irradiance = 20.0 * static_cast<double>(in.sunIntensity_0);
    for (int c = 0; c < 3; ++c) {
        out.in[c] = sum[c] * irradiance;
        out.t[c]  = std::exp(-(betaR[c] * depthR + betaMExt * depthM));
    }
    return out;
}

double worstRel(const float3& got, const AirRef& ref) {
    double w = 0.0;
    for (int c = 0; c < 3; ++c) {
        const double rel = std::fabs(static_cast<double>(channel(got, c)) - ref.in[c]) / ref.in[c];
        if (rel > w) w = rel;
    }
    return w;
}

double worstRel(const AirRef& got, const AirRef& ref) {
    double w = 0.0;
    for (int c = 0; c < 3; ++c) {
        const double rel = std::fabs(got.in[c] - ref.in[c]) / ref.in[c];
        if (rel > w) w = rel;
    }
    return w;
}

// A small PCG so the draws are the same on every run.
struct Pcg {
    unsigned s;
    float next() {
        s = s * 747796405u + 2891336453u;
        unsigned w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
        return static_cast<float>((w >> 22u) ^ w) * (1.0f / 4294967296.0f);
    }
};

int airChecks(const SkyInput_0& in, const std::vector<float>& lut,
              const plugin::cloud::TransmittanceParams& tp) {
    int failures = 0;
    std::printf("\nthe air in front of a cloud:\n");

    // --- 1 and 2: the whole ray, and airTransmittance against airT -------------------
    {
        std::vector<float3> dirs;
        std::vector<float>  dists;
        std::vector<float2> us;
        const float distLadder[] = { 1e30f, 500.0f, 8000.0f, 60000.0f };
        for (int i = -180; i <= 180; ++i) {
            for (int a = 0; a < 8; ++a) {
                for (float d : distLadder) {
                    dirs.push_back(dirAt(static_cast<float>(i) * 0.5f, static_cast<float>(a) * 45.0f));
                    dists.push_back(d);
                    us.push_back(make_float2(0.5f, 0.5f));
                }
            }
        }

        const float altitudes[] = { 2.0f, 1500.0f, 9000.0f };
        int wholeCompared = 0, wholeDiffer = 0, overSky = 0, transDiffer = 0;
        float transWorst = 0.0f;
        for (float alt : altitudes) {
            AirRun r;
            if (!runAir(in, alt, dirs, dists, us, r)) {
                std::printf("  FAIL: CUDA error in airMain\n");
                return failures + 1;
            }
            for (size_t k = 0; k < dirs.size(); ++k) {
                for (int c = 0; c < 3; ++c) {
                    const float t0 = channel(r.airT[k], c), t1 = channel(r.trans[k], c);
                    const float rel = std::fabs(t0 - t1) / (t0 > 1e-30f ? t0 : 1e-30f);
                    if (rel > 1e-5f) ++transDiffer;
                    if (rel > transWorst) transWorst = rel;
                }
                if (dists[k] < 1e29f) continue;
                for (int c = 0; c < 3; ++c) {
                    const float a = channel(r.airIn[k], c), s = channel(r.sky[k], c);
                    if (dirs[k].y > 0.0f) {
                        ++wholeCompared;
                        if (!sameBits(a, s)) ++wholeDiffer;
                    } else if (a > s * (1.0f + 1e-6f)) {
                        ++overSky;
                    }
                }
            }
        }
        std::printf("  1. past the top of the air, upward rays: %d of %d channels differ from "
                    "skyRadiance's airlight bitwise (must be 0)\n", wholeDiffer, wholeCompared);
        std::printf("     downward rays with airlight above the sky: %d (must be 0)\n", overSky);
        // NOT BITWISE: the two loops do the same arithmetic, but airSegment's dR has more
        // uses, so nvcc is free to contract a multiply-add in one and not the other.
        // Measured at under 3e-6 before this bound was set.
        std::printf("  2. airTransmittance against airT: %d channels beyond 1e-5 relative, "
                    "worst %.3g (must be 0)\n", transDiffer, static_cast<double>(transWorst));
        if (wholeDiffer || overSky || transDiffer) ++failures;
    }

    // --- 3: a closed form -------------------------------------------------------------
    {
        const std::vector<float3> dirs  = { dirAt(0.0f, 30.0f) };
        const std::vector<float>  dists = { 1000.0f };
        const std::vector<float2> us    = { make_float2(0.5f, 0.5f) };
        AirRun r;
        runAir(in, 2.0f, dirs, dists, us, r);

        // Over a kilometre the path rises 8 cm, so the density is the density at 2 m.
        const double betaR[3] = { 5.802e-6, 13.558e-6, 33.1e-6 };
        const double betaM    = 3.996e-6 * (static_cast<double>(in.turbidity_0) / 2.2);
        const double fr = std::exp(-2.0 / static_cast<double>(in.scaleHeight_0));
        const double fm = std::exp(-2.0 / 1200.0);
        double worst = 0.0;
        for (int c = 0; c < 3; ++c) {
            const double expect = std::exp(-(betaR[c] * fr + 1.11 * betaM * fm) * 1000.0);
            const double rel = std::fabs(static_cast<double>(channel(r.airT[0], c)) - expect) / expect;
            if (rel > worst) worst = rel;
        }
        std::printf("  3. 1 km level at 2 m against exp(-beta d): worst relative error %.2e "
                    "(must be under 1e-4)\n", worst);
        if (!(worst < 1e-4)) ++failures;
    }

    // --- 4: monotonic along a ray -------------------------------------------------------
    {
        const float ladder[] = { 0.0f, 100.0f, 1000.0f, 5000.0f, 20000.0f, 50000.0f, 150000.0f, 1e30f };
        std::vector<float3> dirs;
        std::vector<float>  dists;
        std::vector<float2> us;
        for (float d : ladder) {
            dirs.push_back(dirAt(3.0f, 135.0f));
            dists.push_back(d);
            us.push_back(make_float2(0.5f, 0.5f));
        }
        AirRun r;
        runAir(in, 2.0f, dirs, dists, us, r);
        int wrong = 0;
        for (int c = 0; c < 3; ++c) {
            if (channel(r.airIn[0], c) != 0.0f || channel(r.airT[0], c) != 1.0f) ++wrong;
        }
        for (size_t k = 1; k < dirs.size(); ++k) {
            for (int c = 0; c < 3; ++c) {
                const bool fell = channel(r.airIn[k], c) < channel(r.airIn[k - 1], c);
                const bool rose = channel(r.airT[k], c)  > channel(r.airT[k - 1], c);
                if (fell || rose) {
                    ++wrong;
                    std::printf("     %s in channel %d from %g m to %g m: %g -> %g\n",
                                fell ? "airlight fell" : "transmittance rose", c,
                                static_cast<double>(ladder[k - 1]), static_cast<double>(ladder[k]),
                                static_cast<double>(fell ? channel(r.airIn[k - 1], c) : channel(r.airT[k - 1], c)),
                                static_cast<double>(fell ? channel(r.airIn[k], c) : channel(r.airT[k], c)));
                }
            }
        }
        std::printf("  4. along one ray from 0 to past the air: %d steps where the airlight "
                    "fell or the transmittance rose (must be 0)\n", wrong);
        if (wrong) ++failures;
    }

    // --- 5: against a converged reference --------------------------------------------
    {
        std::printf("  5. airlight against 4096 midpoint steps in double, worst channel:\n");
        std::printf("     elev  dist km   kernel   24 end   24 mid\n");
        const float elevations[] = { 1.0f, 5.0f, 20.0f };
        const float dists[]      = { 3000.0f, 20000.0f, 40000.0f, 60000.0f, 1e30f };
        double worstFront = 0.0;
        for (float el : elevations) {
            for (float d : dists) {
                const float3 dir = dirAt(el, 135.0f);
                AirRun k;
                runAir(in, 2.0f, { dir }, { d }, { make_float2(0.5f, 0.5f) }, k);
                const AirRef truth = referenceAir(lut, tp, in, 2.0, dir, d, 4096, true);
                const AirRef end24 = referenceAir(lut, tp, in, 2.0, dir, d, 24, false);
                const AirRef mid24 = referenceAir(lut, tp, in, 2.0, dir, d, 24, true);
                const double ek = worstRel(k.airIn[0], truth);
                std::printf("     %4.0f  %7.0f  %6.2f%%  %6.2f%%  %6.2f%%\n",
                            static_cast<double>(el), d > 1e29f ? -1.0 : static_cast<double>(d) / 1000.0,
                            ek * 100.0, worstRel(end24, truth) * 100.0, worstRel(mid24, truth) * 100.0);
                if (ek > worstFront) worstFront = ek;
            }
        }
        // THE WHOLE RAY IS GATED TOO, since it is the sky itself: "24 end" is the march
        // as it was until build 17, and the column beside it is why it changed.
        std::printf("     worst, the sky included: %.2f%% (must be under 1.5%%)\n", worstFront * 100.0);
        if (!(worstFront < 0.015)) ++failures;
    }

    // --- 6: the shadow point ----------------------------------------------------------
    {
        // A 30 KM SEGMENT, where the march is within a percent of converged (check 5), so
        // the expected fractions below come from marches that agree with each other and
        // any error left is the draw's.
        const int n = 1 << 16;
        const float elevation = 2.0f;
        const float segment = 30000.0f;
        Pcg rng{ 12345u };
        std::vector<float3> dirs(n, dirAt(elevation, 135.0f));
        std::vector<float>  dists(n, segment);
        std::vector<float2> us(n);
        for (int k = 0; k < n; ++k) {
            const float a = rng.next();
            us[k] = make_float2(a, rng.next());
        }
        AirRun r;
        runAir(in, 2.0f, dirs, dists, us, r);

        int outside = 0;
        for (int k = 0; k < n; ++k) {
            if (!(r.shadowAt[k] >= 0.0f) || r.shadowAt[k] > segment) ++outside;
        }

        const float cuts[] = { 3000.0f, 10000.0f, 20000.0f };
        double worst = 0.0;
        for (float d0 : cuts) {
            AirRun part;
            runAir(in, 2.0f, { dirAt(elevation, 135.0f) }, { d0 }, { make_float2(0.5f, 0.5f) }, part);
            int beyond = 0;
            for (int k = 0; k < n; ++k) if (r.shadowAt[k] >= d0) ++beyond;
            const double measured = static_cast<double>(beyond) / n;
            const double expected = 1.0 - static_cast<double>(lum(part.airIn[0])) /
                                          static_cast<double>(lum(r.airIn[0]));
            const double err = std::fabs(measured - expected);
            std::printf("     a shadow over the first %5.0f m: lit fraction %.4f drawn, %.4f "
                        "by the airlight\n", static_cast<double>(d0), measured, expected);
            if (err > worst) worst = err;
        }
        std::printf("  6. the shadow point, %d draws: worst error %.4f (must be under 0.01), "
                    "%d outside the ray (must be 0)\n", n, worst, outside);
        if (!(worst < 0.01) || outside) ++failures;
    }

    return failures;
}

} // namespace

int main() {
    int deviceCount = 0;
    if (cudaGetDeviceCount(&deviceCount) != cudaSuccess || deviceCount == 0) {
        std::printf("no CUDA device -- skipping (this test needs a GPU)\n");
        return 0;
    }

    // ONE SET OF VALUES, TYPED ONCE, FED TO BOTH. If the two structs were filled
    // separately the test could pass while the port read a different sky.
    plugin::cloud::FieldParams field;          // the struct's own defaults
    field.atmosphere.sunElevation = 12.0f;
    field.atmosphere.sunAzimuth   = 135.0f;
    field.atmosphere.turbidity    = 2.2f;

    // ===================================================================
    // ONE TABLE, BUILT ONCE, HANDED TO BOTH SIDES -- which is the same rule the
    // parameters above are under and matters more here, not less.
    //
    // The sun-transmittance inner march is a table lookup on both sides now, so if
    // each side built its own table this test would compare two samplers over two
    // tables and would pass while the port read a different atmosphere. Building it
    // once means a divergence can only be in the sampler or the sky integral, which
    // is what this test is for.
    // ===================================================================
    std::vector<float> lut(static_cast<size_t>(plugin::cloud::kTransmittanceFloats));
    plugin::cloud::buildTransmittanceLut(
        plugin::cloud::transmittanceParamsFrom(field.physics, field.atmosphere),
        lut.data(), plugin::cloud::kTransmittanceFloats);

    float* dLut = nullptr;
    if (cudaMalloc(&dLut, lut.size() * sizeof(float)) != cudaSuccess) {
        std::printf("FAIL: could not allocate the transmittance table\n");
        return 1;
    }
    cudaMemcpy(dLut, lut.data(), lut.size() * sizeof(float), cudaMemcpyHostToDevice);

    // ZEROED FIRST, which leaves groundSkyLight at zero: the kernel's one addition to
    // Shading.h's sky, and zero is where the two must agree bit for bit. The ground-light
    // check after the bitwise one sets it.
    SkyInput_0 slangIn;
    std::memset(static_cast<void*>(&slangIn), 0, sizeof slangIn);
    slangIn.transmittanceLut_0.data  = dLut;
    slangIn.transmittanceLut_0.count = lut.size();
    slangIn.planetRadius_0     = field.physics.planetRadius;
    slangIn.scaleHeight_0      = field.physics.scaleHeight;
    slangIn.turbidity_0        = field.atmosphere.turbidity;
    slangIn.mieAnisotropy_0    = field.atmosphere.mieAnisotropy;
    slangIn.sunAzimuth_0       = field.atmosphere.sunAzimuth;
    slangIn.sunElevation_0     = field.atmosphere.sunElevation;
    slangIn.sunIntensity_0     = field.atmosphere.sunIntensity;
    slangIn.sunAngularRadius_0 = field.atmosphere.sunAngularRadius;
    slangIn.groundAlbedo_0     = field.atmosphere.groundAlbedo;

    // DIRECTIONS CHOSEN TO HIT THE HARD CASES, not a uniform sphere.
    //
    // The horizon band is where the ray-sphere algebra earns its keep and where a
    // transcription error hides best; the sun disc is a hard threshold; straight down
    // takes the ground branch; straight up takes the short path. A uniform sweep
    // would spend most of its samples in the easy middle of the sky.
    std::vector<float3> dirs;
    for (int i = -900; i <= 900; ++i) {                     // elevation, 0.1 deg steps
        const float el = static_cast<float>(i) * 0.1f * 0.01745329252f;
        for (int a = 0; a < 8; ++a) {
            const float az = static_cast<float>(a) * 45.0f * 0.01745329252f;
            const float ce = std::cos(el);
            dirs.push_back(make_float3(std::sin(az) * ce, std::sin(el), std::cos(az) * ce));
        }
    }
    // Straight at the sun, and a ring of near-misses around its limb.
    for (int i = -20; i <= 20; ++i) {
        const float el = (12.0f + static_cast<float>(i) * 0.02f) * 0.01745329252f;
        const float az = 135.0f * 0.01745329252f;
        const float ce = std::cos(el);
        dirs.push_back(make_float3(std::sin(az) * ce, std::sin(el), std::cos(az) * ce));
    }

    const int count = static_cast<int>(dirs.size());

    float3 *dDirs = nullptr, *dSlang = nullptr, *dHand = nullptr;
    if (cudaMalloc(&dDirs, count * sizeof(float3)) != cudaSuccess ||
        cudaMalloc(&dSlang, count * sizeof(float3)) != cudaSuccess ||
        cudaMalloc(&dHand,  count * sizeof(float3)) != cudaSuccess) {
        std::printf("FAIL: could not allocate device memory\n");
        return 1;
    }
    cudaMemcpy(dDirs, dirs.data(), count * sizeof(float3), cudaMemcpyHostToDevice);

    const int block = 64;
    const int grid  = (count + block - 1) / block;

    StructuredBuffer<float3> sDirs;
    sDirs.data  = dDirs;
    sDirs.count = static_cast<size_t>(count);

    RWStructuredBuffer<float3> sOut;
    sOut.data  = dSlang;
    sOut.count = static_cast<size_t>(count);

    // ===================================================================
    // SWEPT OVER ORIGIN ALTITUDE, because that argument is the one the renderer
    // actually varies and it used to be a constant on both sides.
    //
    // The bounce loop calls this for every ESCAPED path, from wherever it left the
    // medium -- the camera at bounce 0, a crystal at 9 km after that. A test pinned
    // at 2 m would compare the two files only where they used to agree by
    // construction, and would stay green through a transcription error in the new
    // argument on either side.
    //
    // THE VALUES ARE THE CASES THAT DIFFER IN KIND, not a uniform ladder: the ground
    // itself, the observer, the default generating level and the top of its streak,
    // the stratosphere, and a negative that must clamp to the ground rather than put
    // the origin inside the planet.
    // ===================================================================
    const float altitudes[] = { -500.0f, 0.0f, 2.0f, 6400.0f, 9000.0f, 30000.0f };
    const int   altCount    = static_cast<int>(sizeof(altitudes) / sizeof(altitudes[0]));

    int   differing = 0;
    float worst     = 0.0f;
    int   worstAt   = -1;
    float worstAlt  = 0.0f;

    std::vector<float3> slangOut(count), handOut(count);

    for (int k = 0; k < altCount; ++k) {
        const float alt = altitudes[k];

        skyMain<<<grid, block>>>(slangIn, alt, sDirs, sOut, count);
        handWrittenSky<<<grid, block>>>(field, alt, dLut, dDirs, dHand, count);

        const cudaError_t err = cudaDeviceSynchronize();
        if (err != cudaSuccess) {
            std::printf("FAIL: CUDA error at altitude %g: %s\n",
                        static_cast<double>(alt), cudaGetErrorString(err));
            return 1;
        }

        cudaMemcpy(slangOut.data(), dSlang, count * sizeof(float3), cudaMemcpyDeviceToHost);
        cudaMemcpy(handOut.data(),  dHand,  count * sizeof(float3), cudaMemcpyDeviceToHost);

        for (int i = 0; i < count; ++i) {
            const float a[3] = { slangOut[i].x, slangOut[i].y, slangOut[i].z };
            const float b[3] = { handOut[i].x,  handOut[i].y,  handOut[i].z  };

            for (int c = 0; c < 3; ++c) {
                if (std::isnan(a[c]) && std::isnan(b[c])) continue;

                unsigned ua = 0, ub = 0;
                std::memcpy(&ua, &a[c], sizeof(ua));
                std::memcpy(&ub, &b[c], sizeof(ub));
                if (ua != ub) {
                    ++differing;
                    const float d = std::fabs(a[c] - b[c]);
                    if (d > worst) { worst = d; worstAt = i; worstAlt = alt; }
                }
            }
        }
    }

    std::printf("%d directions at %d origin altitudes, Slang sky vs hand-written sky, "
                "compared bitwise:\n", count, altCount);
    std::printf("  %d differing channels of %d", differing, count * 3 * altCount);
    if (differing) {
        std::printf(", worst absolute difference %g at altitude %g m, "
                    "direction %d (%.4f, %.4f, %.4f)",
                    static_cast<double>(worst), static_cast<double>(worstAlt), worstAt,
                    static_cast<double>(dirs[worstAt].x),
                    static_cast<double>(dirs[worstAt].y),
                    static_cast<double>(dirs[worstAt].z));
    }
    std::printf("\n");

    // ===================================================================
    // THE GROUND'S SKYLIGHT (build 19), the kernel's one term Shading.h lacks. Set, it
    // must leave every ray that cannot reach the ground bit for bit alone, brighten every
    // ray that lands on it by no more than itself, and, looking straight down from 2 m
    // through almost no air, by almost exactly itself.
    // ===================================================================
    int groundFailures = 0;
    {
        const float3 light = make_float3(0.1f, 0.2f, 0.3f);
        SkyInput_0 lit = slangIn;
        lit.groundSkyLight_0 = light;

        std::vector<float3> base(count), with(count);
        skyMain<<<grid, block>>>(slangIn, 2.0f, sDirs, sOut, count);
        cudaDeviceSynchronize();
        cudaMemcpy(base.data(), dSlang, count * sizeof(float3), cudaMemcpyDeviceToHost);
        skyMain<<<grid, block>>>(lit, 2.0f, sDirs, sOut, count);
        cudaDeviceSynchronize();
        cudaMemcpy(with.data(), dSlang, count * sizeof(float3), cudaMemcpyDeviceToHost);

        int upChanged = 0, downWrong = 0, down = 0;
        double straightDown = 1.0;
        for (int i = 0; i < count; ++i) {
            const float gain[3] = { with[i].x - base[i].x, with[i].y - base[i].y,
                                    with[i].z - base[i].z };
            const float lim[3]  = { light.x, light.y, light.z };
            if (dirs[i].y >= 0.0f) {
                if (std::memcmp(&with[i], &base[i], sizeof(float3)) != 0) ++upChanged;
            } else if (dirs[i].y < -0.01f) {
                ++down;
                for (int c = 0; c < 3; ++c) {
                    if (!(gain[c] > 0.0f) || gain[c] > lim[c] * 1.0001f) { ++downWrong; break; }
                }
                if (dirs[i].y < -0.9999f) {
                    for (int c = 0; c < 3; ++c) {
                        straightDown = std::fmin(straightDown, gain[c] / lim[c]);
                    }
                }
            }
        }
        const bool ok = upChanged == 0 && downWrong == 0 && down > 0 && straightDown > 0.999;
        std::printf("ground skylight: %d rays up changed (must be 0), %d of %d rays down "
                    "outside (0, light] (must be 0), straight down gains %.5f of it  %s\n",
                    upChanged, downWrong, down, straightDown, ok ? "ok" : "FAIL");
        if (!ok) groundFailures = 1;
    }

    const int airFailures = groundFailures + airChecks(
        slangIn, lut, plugin::cloud::transmittanceParamsFrom(field.physics, field.atmosphere));
    if (airFailures) {
        std::printf("\nTHE AIR IN FRONT OF A CLOUD FAILED %d CHECK(S). See the numbered lines\n"
                    "above and the list at airChecks in this file.\n", airFailures);
    }

    if (differing == 0) {
        std::printf("\nidentical -- the port is a faithful transcription\n");
        return airFailures ? 1 : 0;
    }

    std::printf(
        "\nTHE SLANG PORT NO LONGER MATCHES Shading.h.\n"
        "  Given slang.mathParity is green, this is a TRANSCRIPTION difference rather\n"
        "  than a toolchain one. The usual causes, in order:\n"
        "    * an expression reassociated -- a*(b+c) is not a*b+a*c in float\n"
        "    * a clamp, a guard, or a `continue` dropped from a loop\n"
        "    * a constant retyped with a digit missing\n"
        "    * one of the two files edited without the other\n"
        "  The worst direction is printed above; feed it to both and diff the steps.\n");
    return 1;
}
