// The bounce loop, checked by a furnace and by a closed form.
//
// ===========================================================================
// THE FURNACE TEST: A CONSERVATIVE MEDIUM INSIDE A UNIFORM SOURCE MUST RETURN THE
// SOURCE, EXACTLY.
//
// Set the single-scatter albedo to 1 -- scattering redirects light and removes none --
// and surround the medium with a uniform radiance L. Then every point, in every
// direction, sees exactly L. Nothing about the phase function, the density, the path
// length or the majorant can change that: a photon that is never absorbed and never
// created arrives with the energy it set out with.
//
// That is the only identity the bounce loop has, and it is the one that matters,
// because the way a bounce loop fails is by losing a few percent per event. A 3% leak
// is invisible in a single-scatter check and is a factor of two after twenty-five
// bounces.
//
// THE SHARP FORM OF IT, WHICH IS WHAT THIS TEST ACTUALLY ASSERTS.
//
// With an ISOTROPIC phase function the importance sampler's weight is exactly 1.0f --
// the pdf and the phase are the same expression, so the division is x/x. With albedo
// also exactly 1, the throughput of every path stays exactly 1.0f, Russian roulette's
// survival probability is exactly 1 and never fires, and each path returns either L
// (it escaped) or 0 (the bounce budget ran out).
//
// So the identity is not statistical. It is PER PATH:
//
//     shortfall below L  ==  the fraction of paths that hit the bounce cap
//
// Any leak anywhere in the loop breaks it immediately, which is why the tolerance on
// it is 1e-6 rather than a Monte Carlo band. The second furnace, with a real droplet
// phase, gives up that exactness to gain coverage of the Draine lobe and the mixture
// sampler -- there the identity holds only in expectation and is checked as such.
//
// WHAT THE FURNACE CANNOT SEE. In a furnace every escape returns L, so a path that
// escapes TOO EARLY -- exactly what a loose majorant with a too-small iteration cap
// produces, and the bug slang.transport found -- returns the right answer for the
// wrong reason. The furnace is structurally blind to it.
//
// That is why the majorant sweep here is on the NEXT-EVENT test instead, where a
// premature escape is a scattering event that never happened and the answer moves.
// The two tiers are complementary and neither subsumes the other.
// ===========================================================================

#include <cstdio>
#include <cmath>
#include <vector>
#include <algorithm>

#include <cuda_runtime.h>

#include "Bounce.cu"

// The local lights' buffer, packed as the effect packs it (build 29).
#include "LocalLights.h"

namespace {

double kahanSum(const std::vector<float>& v) {
    double sum = 0.0, c = 0.0;
    for (float f : v) {
        const double y = static_cast<double>(f) - c;
        const double t = sum + y;
        c = (t - sum) - y;
        sum = t;
    }
    return sum;
}

// What one sweep of the bounce loop returns.
struct Run {
    double meanRadiance;     // channel x
    double stdevRadiance;    // per path, channel x -- what a variance technique moves
    double cappedFraction;
    double meanEvents;
    double maxChannelSpread; // the largest |x-y| or |x-z| seen, for a swizzle bug
};

// Device scratch, allocated once: these sweeps run the kernel dozens of times and a
// cudaMalloc per call was 0.55 ms of pure driver time when Mistytune.cu was measured.
struct Scratch {
    float3* radiance = nullptr;
    int*    events   = nullptr;
    int*    capped   = nullptr;
    int*    steps    = nullptr;
    float*  bounds   = nullptr;   // a one-element stand-in; the grid here is disabled
    float2* drift    = nullptr;   // 33 zero knots; mode 0 never reads them
    int     count    = 0;

    void reserve(int n) {
        if (bounds == nullptr) cudaMalloc(&bounds, sizeof(float));
        if (drift == nullptr) {
            std::vector<float2> knots(33, make_float2(0.0f, 0.0f));
            cudaMalloc(&drift, knots.size() * sizeof(float2));
            cudaMemcpy(drift, knots.data(), knots.size() * sizeof(float2),
                       cudaMemcpyHostToDevice);
        }
        if (n <= count) return;
        cudaFree(radiance); cudaFree(events); cudaFree(capped); cudaFree(steps);
        cudaMalloc(&radiance, static_cast<size_t>(n) * sizeof(float3));
        cudaMalloc(&events,   static_cast<size_t>(n) * sizeof(int));
        cudaMalloc(&capped,   static_cast<size_t>(n) * sizeof(int));
        cudaMalloc(&steps,    static_cast<size_t>(n) * sizeof(int));
        count = n;
    }
};

Run runTrace(Scratch& s, Scene_0 scene, PhaseInput_0 phase,
             float3 origin, float3 direction, unsigned seed, int n) {
    s.reserve(n);

    RWStructuredBuffer<float3> bRad;   bRad.data = s.radiance; bRad.count = static_cast<size_t>(n);
    RWStructuredBuffer<int>    bEvt;   bEvt.data = s.events;   bEvt.count = static_cast<size_t>(n);
    RWStructuredBuffer<int>    bCap;   bCap.data = s.capped;   bCap.count = static_cast<size_t>(n);
    RWStructuredBuffer<int>    bStp;   bStp.data = s.steps;    bStp.count = static_cast<size_t>(n);

    // THE MAJORANT GRID IS DISABLED THROUGHOUT THIS SUITE, so `bounds` is never read.
    // The bounce loop's identities are properties of the estimator, not of how the
    // majorant is looked up, and every number in this file was blessed before the grid
    // existed -- keeping it off is what makes those numbers still mean the same thing.
    // slang.transport is where the grid is exercised.
    StructuredBuffer<float>  bBnd;     bBnd.data = s.bounds;   bBnd.count = 1;
    StructuredBuffer<float2> bDrf;     bDrf.data = s.drift;    bDrf.count = 33;

    traceTrial<<<(n + 63) / 64, 64>>>(scene, phase, bBnd, bDrf, origin, direction,
                                      bRad, bEvt, bCap, bStp, seed, n);

    std::vector<float3> rad(n);
    std::vector<int>    evt(n);
    std::vector<int>    cap(n);
    cudaMemcpy(rad.data(), s.radiance, rad.size() * sizeof(float3), cudaMemcpyDeviceToHost);
    cudaMemcpy(evt.data(), s.events,   evt.size() * sizeof(int),    cudaMemcpyDeviceToHost);
    cudaMemcpy(cap.data(), s.capped,   cap.size() * sizeof(int),    cudaMemcpyDeviceToHost);

    std::vector<float> x(n);
    double spread = 0.0;
    long long cappedCount = 0, eventSum = 0;
    for (int i = 0; i < n; ++i) {
        x[i] = rad[i].x;
        spread = std::max(spread, static_cast<double>(std::fabs(rad[i].x - rad[i].y)));
        spread = std::max(spread, static_cast<double>(std::fabs(rad[i].x - rad[i].z)));
        cappedCount += cap[i];
        eventSum    += evt[i];
    }

    Run r;
    r.meanRadiance     = kahanSum(x) / n;

    double sq = 0.0;
    for (int i = 0; i < n; ++i) {
        const double d = static_cast<double>(x[i]) - r.meanRadiance;
        sq += d * d;
    }
    r.stdevRadiance    = n > 1 ? std::sqrt(sq / (n - 1)) : 0.0;
    r.cappedFraction   = static_cast<double>(cappedCount) / n;
    r.meanEvents       = static_cast<double>(eventSum) / n;
    r.maxChannelSpread = spread;
    return r;
}

// Reads the Jendersie-d'Eon fits off the GPU rather than restating them here.
PhaseInput_0 dropletPhase(float diameterMicrons) {
    float4* d = nullptr;
    cudaMalloc(&d, sizeof(float4));
    RWStructuredBuffer<float4> b; b.data = d; b.count = 1;

    phaseParamsTrial<<<1, 1>>>(diameterMicrons, b);

    float4 h = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    cudaMemcpy(&h, d, sizeof(float4), cudaMemcpyDeviceToHost);
    cudaFree(d);

    PhaseInput_0 p{};   // value-initialised: no truncated lobe
    p.hgG_0         = h.x;
    p.draineG_0     = h.y;
    p.draineAlpha_0 = h.z;
    p.draineW_0     = h.w;
    p.useIce_0      = 0;
    return p;
}

// The phase function at one cosine, from the GPU, for the analytic reference.
double phaseValue(PhaseInput_0 p, double mu) {
    const float muf = static_cast<float>(mu);
    float* dIn  = nullptr;
    float* dOut = nullptr;
    cudaMalloc(&dIn,  sizeof(float));
    cudaMalloc(&dOut, sizeof(float));
    cudaMemcpy(dIn, &muf, sizeof(float), cudaMemcpyHostToDevice);

    StructuredBuffer<float>   bIn;  bIn.data  = dIn;  bIn.count  = 1;
    RWStructuredBuffer<float> bOut; bOut.data = dOut; bOut.count = 1;

    phaseValueTrial<<<1, 64>>>(p, bIn, bOut, 1);

    float h = 0.0f;
    cudaMemcpy(&h, dOut, sizeof(float), cudaMemcpyDeviceToHost);
    cudaFree(dIn);
    cudaFree(dOut);
    return static_cast<double>(h);
}

// ---------------------------------------------------------------------------
// THE CLOSED FORM FOR SINGLE-SCATTER NEXT-EVENT ESTIMATION
// ---------------------------------------------------------------------------
//
// A constant slab of thickness H and extinction sigma. The sun is straight up and is a
// delta light of irradiance E. A view ray starts at the slab's BOTTOM face with
// direction mu = cos(angle from vertical), so it exits the top at distance H/mu.
//
// The probability of the first real collision falling in [t, t+dt] is
// exp(-sigma t) sigma dt, and the shadow ray from that point runs straight up through
// H - t*mu of medium. Single-scatter radiance is therefore
//
//   L = albedo * phase(mu) * E * sigma * integral over t of
//         exp(-sigma t) * exp(-sigma (H - t mu)) dt,   t from 0 to H/mu
//
//     = albedo * phase(mu) * E * exp(-tau) * (1 - exp(-tau (1-mu)/mu)) / (1-mu)
//
// with tau = sigma H. The estimator needs no weight of its own: delta tracking samples
// exactly that collision density, so averaging the next-event contribution over trials
// converges on this number.
//
// WHY THIS IS THE TEST THAT CARRIES THE MAJORANT SWEEP. Every factor above is a
// different part of the code -- the free-flight distribution, the ratio-tracked shadow,
// the phase evaluation, the albedo -- and the majorant appears in NONE of them. A
// premature escape shows up here as a collision that never happened, and the answer
// falls. The furnace cannot see that, because there an early escape still returns L.
double neeAnalytic(double albedo, double phase, double E,
                   double sigma, double H, double mu) {
    const double tau = sigma * H;
    const double k   = (1.0 - mu) / mu;
    // The (1-mu) denominator is removable, and at mu near 1 the cancellation is where
    // the precision goes. Expanded rather than evaluated as written when it is tight.
    double geom;
    if (1.0 - mu < 1e-6) {
        geom = tau;                       // the limit of (1 - exp(-tau k))/(1-mu)
    } else {
        geom = (1.0 - std::exp(-tau * k)) / (1.0 - mu);
    }
    return albedo * phase * E * std::exp(-tau) * geom;
}


// ---------------------------------------------------------------------------
// LOCAL LIGHTS (build 29): the same single-scatter integral, by quadrature
// ---------------------------------------------------------------------------
//
// THE KERNEL DRAWS ONE LIGHT PER EVENT, AND FOR A SHEET ONE TEXEL AND ONE POINT IN IT, and
// divides by the probability of each draw. The reference below draws nothing: it sums every
// light, integrates every texel's area, and marches the camera ray -- so a wrong pick
// probability, a texel weighted twice, a shadow ray that walks past its light or one that
// stops short, and a phase cosine of the wrong sign all show up as a difference. The phase
// is a forward-peaked Henyey-Greenstein for exactly that last reason: an isotropic phase
// cannot tell a cosine from its negative.
//
// IT READS THE SAME PACKED BUFFER THE KERNEL DOES, made by src/engine/LocalLights.h, and
// TestLights.cpp checks the packer's numbers against AE's meaning. This checks the kernel's
// reading of them.
struct SlabRef {
    double bottom, top, sigma;
};

double len3(const double v[3]) { return std::sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]); }

// Optical depth along the straight segment a -> b: sigma times its length inside the slab.
double slabDepth(const SlabRef& s, const double a[3], const double b[3]) {
    const double d[3] = { b[0] - a[0], b[1] - a[1], b[2] - a[2] };
    const double len = len3(d);
    if (!(len > 0.0)) return 0.0;
    if (std::fabs(d[1]) < 1e-12) return (a[1] >= s.bottom && a[1] <= s.top) ? s.sigma * len : 0.0;
    double s0 = (s.bottom - a[1]) / d[1];
    double s1 = (s.top - a[1]) / d[1];
    if (s0 > s1) std::swap(s0, s1);
    const double lo = std::max(0.0, s0), hi = std::min(1.0, s1);
    return hi > lo ? s.sigma * len * (hi - lo) : 0.0;
}

// ...and from a point inside the slab out along a unit direction, for good.
double slabDepthOut(const SlabRef& s, const double x[3], const double d[3]) {
    if (d[1] > 1e-12)  return s.sigma * (s.top - x[1]) / d[1];
    if (d[1] < -1e-12) return s.sigma * (x[1] - s.bottom) / -d[1];
    return 1e30;
}

double lightEdgeHost(double lo, double hi, double x) {
    if (!(hi > lo)) return x >= lo ? 1.0 : 0.0;
    const double t = std::min(1.0, std::max(0.0, (x - lo) / (hi - lo)));
    return t * t * (3.0 - 2.0 * t);
}

// The phase function off the GPU, tabulated over the cosine and read back linearly.
struct PhaseTable {
    std::vector<double> v;
    double at(double mu) const {
        const double x = (std::min(1.0, std::max(-1.0, mu)) + 1.0) * 0.5 * (v.size() - 1);
        const size_t i = std::min(static_cast<size_t>(x), v.size() - 2);
        const double f = x - static_cast<double>(i);
        return v[i] * (1.0 - f) + v[i + 1] * f;
    }
};

PhaseTable phaseTable(PhaseInput_0 p, int n) {
    std::vector<float> mus(n);
    for (int i = 0; i < n; ++i) mus[i] = static_cast<float>(-1.0 + 2.0 * i / (n - 1));
    float* dIn = nullptr;
    float* dOut = nullptr;
    cudaMalloc(&dIn, n * sizeof(float));
    cudaMalloc(&dOut, n * sizeof(float));
    cudaMemcpy(dIn, mus.data(), n * sizeof(float), cudaMemcpyHostToDevice);
    StructuredBuffer<float>   bIn;  bIn.data  = dIn;  bIn.count  = static_cast<size_t>(n);
    RWStructuredBuffer<float> bOut; bOut.data = dOut; bOut.count = static_cast<size_t>(n);
    phaseValueTrial<<<(n + 63) / 64, 64>>>(p, bIn, bOut, n);
    std::vector<float> h(n);
    cudaMemcpy(h.data(), dOut, n * sizeof(float), cudaMemcpyDeviceToHost);
    cudaFree(dIn);
    cudaFree(dOut);
    PhaseTable t;
    t.v.assign(h.begin(), h.end());
    return t;
}

// Every light's phase-weighted irradiance at x, through the slab: what one next event
// estimates, summed rather than drawn. Channel x of the packed colours.
double lightsAt(const std::vector<float>& b, const SlabRef& slab, const double x[3],
                const double camDir[3], const PhaseTable& ph) {
    const int count = static_cast<int>(b[0]);
    double total = 0.0;
    for (int k = 0; k < count; ++k) {
        const int r = plugin::cloud::kLightHeaderFloats + k * plugin::cloud::kLightRecordFloats;
        const int kind = static_cast<int>(b[r]);

        if (kind == 2) {
            const double toL[3] = { b[r + 6], b[r + 7], b[r + 8] };
            const double mu = camDir[0] * toL[0] + camDir[1] * toL[1] + camDir[2] * toL[2];
            total += ph.at(mu) * b[r + 9] * std::exp(-slabDepthOut(slab, x, toL));
            continue;
        }

        if (kind == 3) {
            const int w = static_cast<int>(b[r + 13]), h = static_cast<int>(b[r + 14]);
            const int off = static_cast<int>(b[r + 15]);
            const int n = w * h;
            const int tf = plugin::cloud::kSheetTexelFloats;
            const double eye[3] = { b[r + 9], b[r + 10], b[r + 11] };
            const int sub = 16;
            for (int t = 0; t < n; ++t) {
                const double L = b[off + tf * t];
                if (!(L > 0.0)) continue;
                // WHERE THE TEXEL STANDS: its patch of the plane pushed along the eye's rays by
                // its scale, and s^2 times the area.
                const double s = b[off + tf * t + 3];
                const double area = b[r + 12] * s * s;
                const int iu = t % w, iv = t / w;
                for (int j = 0; j < sub; ++j) {
                    for (int i = 0; i < sub; ++i) {
                        const double fu = iu + (i + 0.5) / sub, fv = iv + (j + 0.5) / sub;
                        double q[3], d[3];
                        for (int c = 0; c < 3; ++c) {
                            const double onPlane = b[r + 3 + c] + b[r + 6 + c] * fu + b[r + 16 + c] * fv;
                            q[c] = eye[c] + (onPlane - eye[c]) * s;
                            d[c] = q[c] - x[c];
                        }
                        const double dist = len3(d);
                        const double d2 = dist * dist;
                        const double mu = (camDir[0] * d[0] + camDir[1] * d[1] + camDir[2] * d[2]) / dist;
                        // the integral of L / max(d^2, A) over the texel, one sub-patch of it
                        const double e = L * (area / (sub * sub)) / std::max(d2, area);
                        total += ph.at(mu) * e * std::exp(-slabDepth(slab, x, q));
                    }
                }
            }
            continue;
        }

        const double q[3] = { b[r + 3], b[r + 4], b[r + 5] };
        const double d[3] = { q[0] - x[0], q[1] - x[1], q[2] - x[2] };
        const double dist = len3(d);
        double e = b[r + 9] / std::max(dist * dist, static_cast<double>(b[r + 12]));
        if (kind == 1) {
            const double c = -(d[0] * b[r + 6] + d[1] * b[r + 7] + d[2] * b[r + 8]) / dist;
            e *= lightEdgeHost(b[r + 13], b[r + 14], c);
        }
        if (b[r + 16] > 0.0f) e *= 1.0 - lightEdgeHost(b[r + 15], b[r + 16], dist);
        const double mu = (camDir[0] * d[0] + camDir[1] * d[1] + camDir[2] * d[2]) / dist;
        total += ph.at(mu) * e * std::exp(-slabDepth(slab, x, q));
    }
    return total;
}

// Single scatter along the camera ray from `o` until it leaves the slab's top: the first
// collision's density times the albedo times what the lights send there.
double lightsReference(const std::vector<float>& b, const SlabRef& slab, double albedo,
                       const double o[3], const double dir[3], const PhaseTable& ph) {
    const double tExit = (slab.top - o[1]) / dir[1];
    const int steps = 1500;
    const double dt = tExit / steps;
    double sum = 0.0;
    for (int i = 0; i < steps; ++i) {
        const double t = (i + 0.5) * dt;
        const double x[3] = { o[0] + dir[0] * t, o[1] + dir[1] * t, o[2] + dir[2] * t };
        sum += slab.sigma * std::exp(-slab.sigma * t) * lightsAt(b, slab, x, dir, ph) * dt;
    }
    return albedo * sum;
}

} // namespace

int main() {
    int deviceCount = 0;
    if (cudaGetDeviceCount(&deviceCount) != cudaSuccess || deviceCount == 0) {
        std::printf("no CUDA device -- skipping (this test needs a GPU)\n");
        return 0;
    }

    int failures = 0;
    Scratch scratch;

    // The same slab slang.transport uses, so the two suites describe one scene.
    const float thickness = 1000.0f;
    const float sigma     = 0.0025f;          // optical depth 2.5 across the slab
    const float slabBottom = 1000.0f;
    const float slabTop    = slabBottom + thickness;

    // ZERO-INITIALISED, not merely assigned field by field. `Environment` gained a
    // `SkyInput` when the renderer landed, and mode 0 never reads it -- so an
    // uninitialised one would travel to the GPU as whatever was on the stack and
    // cost an afternoon the day somebody sets envMode to 1 here.
    Scene_0 base{};
    base.medium_0.slabTop_0    = slabTop;
    base.medium_0.slabBottom_0 = slabBottom;
    base.medium_0.density_0    = sigma;
    base.medium_0.majorant_0   = sigma;
    base.medium_0.coreCentre_0 = make_float3(0.0f, 0.0f, 0.0f);
    base.medium_0.coreRadius_0 = 1.0f;    // unread at mode 0, and never left at zero
    base.medium_0.coreDensity_0 = 0.0f;
    base.medium_0.mode_0       = 0;
    base.grid_0.origin_0   = make_float3(0.0f, 0.0f, 0.0f);
    base.grid_0.cellExtent_0 = make_float3(1.0f, 1.0f, 1.0f);
    base.grid_0.dims_0     = make_int3(1, 1, 1);
    base.grid_0.enabled_0  = 0;           // see runTrace
    base.environment_0.uniformRadiance_0 = make_float3(1.0f, 1.0f, 1.0f);
    base.environment_0.envMode_0     = 0;
    base.albedo_0        = make_float3(1.0f, 1.0f, 1.0f);
    base.sunIrradiance_0 = make_float3(0.0f, 0.0f, 0.0f);
    base.sunDir_0        = make_float3(0.0f, 1.0f, 0.0f);
    base.shadowOffset_0  = 0.0f;
    base.maxBounces_0    = 64;
    base.rrStartBounce_0 = 4;

    // ISOTROPIC. Not reachable through phaseFromDropletDiameter, and the reason this
    // entry point takes derived parameters -- see Bounce.slang. It is what makes the
    // furnace identity exact instead of statistical.
    PhaseInput_0 iso{};
    iso.hgG_0 = 0.0f; iso.draineG_0 = 0.0f;
    iso.draineAlpha_0 = 0.0f; iso.draineW_0 = 0.0f; iso.useIce_0 = 0;

    // Start in the middle of the slab, so the walk can leave through either face.
    const float3 mid = make_float3(0.0f, slabBottom + thickness * 0.5f, 0.0f);
    const float3 up  = make_float3(0.0f, 1.0f, 0.0f);

    const int trials = 1 << 20;   // 1.05M

    // -----------------------------------------------------------------------
    // 1. The furnace, isotropic: the shortfall must BE the bounce cap
    // -----------------------------------------------------------------------
    std::printf("FURNACE -- conservative medium (albedo 1) in a uniform source L = 1\n");
    std::printf("  isotropic phase, so the sample weight is exactly 1 and the identity\n");
    std::printf("  below is per-path rather than statistical.\n\n");
    std::printf("  %10s %12s %12s %12s %12s\n",
                "maxBounces", "measured", "capped", "shortfall", "|diff|");

    const int bounceSweep[] = { 1, 2, 4, 8, 16, 32, 64, 128 };
    for (int mb : bounceSweep) {
        Scene_0 s = base;
        s.maxBounces_0 = mb;

        const Run r = runTrace(scratch, s, iso, mid, up, 0xB0117CEu, trials);
        const double shortfall = 1.0 - r.meanRadiance;
        const double diff      = std::fabs(shortfall - r.cappedFraction);

        std::printf("  %10d %12.6f %12.6f %12.6f %12.2e\n",
                    mb, r.meanRadiance, r.cappedFraction, shortfall, diff);

        // THE IDENTITY. 1e-6 rather than a Monte Carlo band, because every escaped path
        // returns exactly 1.0f and every capped path exactly 0.
        if (diff > 1e-6) {
            std::printf("    FAIL: the loop lost %.3e that the bounce cap does not explain.\n"
                        "          Energy is leaking somewhere other than the budget.\n", diff);
            ++failures;
        }

        // A grey scene must stay grey. Catches a channel swizzle, which would otherwise
        // hide behind a mean taken from one channel.
        if (r.maxChannelSpread != 0.0) {
            std::printf("    FAIL: channels disagree by %.3e in a grey scene\n",
                        r.maxChannelSpread);
            ++failures;
        }
    }

    // The convergence claim, separate from the identity: the cap has to be high enough
    // that the loop is honest, not merely self-consistent.
    {
        Scene_0 s = base;
        s.maxBounces_0 = 64;
        const Run r = runTrace(scratch, s, iso, mid, up, 0x5eed01u, trials);
        std::printf("\n  at 64 bounces: %.6f against L = 1 (mean %.2f scattering events)\n",
                    r.meanRadiance, r.meanEvents);
        if (std::fabs(r.meanRadiance - 1.0) > 0.003) {
            std::printf("    FAIL: 64 bounces is not enough for this slab -- the cap is\n"
                        "          truncating %.3f of the energy\n", 1.0 - r.meanRadiance);
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 2. The furnace with a REAL droplet phase
    // -----------------------------------------------------------------------
    //
    // Gives up the exactness of case 1 to gain what case 1 cannot reach: the Draine
    // lobe, the mixture sampler, and a weight that is only 1 ON AVERAGE. slang.phase
    // establishes that average over single samples. This establishes that it survives
    // composition over a whole path, which is a different claim -- a weight that is
    // unbiased per event but correlated with path length would pass there and fail here.
    // MORE TRIALS THAN THE ISOTROPIC CASE, and the reason is the whole difference
    // between the two. There the answer is exact per path, so one trial would do and a
    // million is for the capped fraction. Here the weight only averages to 1, and the
    // residual being looked for is a few parts in ten thousand -- which is BELOW the
    // Monte Carlo error of a million paths, so a million paths cannot tell a real
    // sampler deficit from noise. 16.8M puts the standard error near 7e-5.
    const int dropletTrials = 1 << 24;

    std::printf("\nFURNACE -- the same scene with the Jendersie-d'Eon droplet phase\n");
    std::printf("  %d trials, so the standard error is well below the residual\n\n",
                dropletTrials);
    std::printf("  %10s %10s %12s %12s %12s %10s\n",
                "microns", "hgG", "measured", "capped", "shortfall", "events");

    const float diameters[] = { 5.0f, 20.0f, 50.0f };
    for (float d : diameters) {
        const PhaseInput_0 ph = dropletPhase(d);

        Scene_0 s = base;
        s.maxBounces_0 = 128;

        const Run r = runTrace(scratch, s, ph, mid, up, 0xFACE01u, dropletTrials);
        const double shortfall = 1.0 - r.meanRadiance;

        std::printf("  %10.1f %10.4f %12.6f %12.6f %12.6f %10.2f\n",
                    static_cast<double>(d), static_cast<double>(ph.hgG_0),
                    r.meanRadiance, r.cappedFraction, shortfall, r.meanEvents);

        // ===================================================================
        // 5e-4, AND THE BOUND WAS SET BY MEASUREMENT RATHER THAN BY CAUTION.
        //
        // At a million trials this residual sat at 1e-4 to 6e-4 and looked like a real
        // sampler deficit -- consistent in size with the 0.9997 mean sample weight
        // slang.phase reports. At 16.8M it collapses to 1e-6 to 7e-5, which is this
        // run's standard error. It was noise.
        //
        // THAT IS A RESULT AND NOT JUST A TOLERANCE. A mean weight of 0.9997 per event
        // over the 1.7 events these paths average would show a shortfall of 5.1e-4 --
        // seven standard errors above what is measured here. So this test positively
        // EXCLUDES a per-event deficit of that size, which means slang.phase's 0.9997
        // was its own Monte Carlo floor rather than a bias in the sampler.
        //
        // The bound is therefore ~7x the observed residual: tight enough that a real
        // 3e-4 per-event leak would fail it, loose enough not to flake.
        // ===================================================================
        if (std::fabs(shortfall - r.cappedFraction) > 5e-4) {
            std::printf("    FAIL: shortfall %.5f against a capped fraction of %.5f --\n"
                        "          the mixture sampler is not energy-conserving over a path\n",
                        shortfall, r.cappedFraction);
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 3. Russian roulette is a free parameter
    // -----------------------------------------------------------------------
    //
    // Roulette trades variance for speed and MUST NOT move the mean. The scene is
    // absorbing (albedo 0.7) so that roulette actually fires -- in the conservative
    // furnace the survival probability is 1 and it never does, which is why this cannot
    // be folded into case 1.
    //
    // THE CONTROL IS THE MEAN EVENT COUNT. Without it the test compares two runs that
    // might be doing the same thing and passes for no reason.
    std::printf("\nRUSSIAN ROULETTE -- absorbing medium (albedo 0.7), 128 bounce budget\n");
    {
        Scene_0 s = base;
        s.albedo_0     = make_float3(0.7f, 0.7f, 0.7f);
        s.maxBounces_0 = 128;

        Scene_0 on  = s; on.rrStartBounce_0  = 4;
        Scene_0 off = s; off.rrStartBounce_0 = 1000000;   // past the ceiling: never fires

        const Run rOn  = runTrace(scratch, on,  iso, mid, up, 0x2211u, trials);
        const Run rOff = runTrace(scratch, off, iso, mid, up, 0x2211u, trials);

        std::printf("  %14s %12s %12s\n", "", "measured", "events");
        std::printf("  %14s %12.6f %12.2f\n", "roulette on",  rOn.meanRadiance,  rOn.meanEvents);
        std::printf("  %14s %12.6f %12.2f\n", "roulette off", rOff.meanRadiance, rOff.meanEvents);
        std::printf("  difference %.6f\n", rOn.meanRadiance - rOff.meanRadiance);

        if (std::fabs(rOn.meanRadiance - rOff.meanRadiance) > 0.003) {
            std::printf("    FAIL: roulette moved the answer by %.5f. It is a variance\n"
                        "          technique and must not reach the mean -- check the 1/p.\n",
                        rOn.meanRadiance - rOff.meanRadiance);
            ++failures;
        }
        if (rOn.meanEvents >= rOff.meanEvents * 0.98) {
            std::printf("    FAIL: roulette did not shorten the paths (%.2f vs %.2f events),\n"
                        "          so the comparison above proved nothing\n",
                        rOn.meanEvents, rOff.meanEvents);
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 4. Next-event estimation against the closed form
    // -----------------------------------------------------------------------
    //
    // Environment black, sun a delta light, budget 1 -- so the only thing measured is
    // one next-event estimate, and it has an analytic answer. See neeAnalytic().
    const double E      = 1.0;
    const double albedo = 0.8;
    const double isoPhase = phaseValue(iso, 0.0);   // 1/(4 pi), read off the GPU

    Scene_0 nee = base;
    nee.environment_0.uniformRadiance_0 = make_float3(0.0f, 0.0f, 0.0f);
    nee.sunIrradiance_0          = make_float3(static_cast<float>(E), static_cast<float>(E),
                                               static_cast<float>(E));
    nee.albedo_0                 = make_float3(static_cast<float>(albedo),
                                               static_cast<float>(albedo),
                                               static_cast<float>(albedo));
    nee.maxBounces_0             = 1;

    const float3 bottom = make_float3(0.0f, slabBottom, 0.0f);

    std::printf("\nNEXT-EVENT ESTIMATION -- single scatter against the closed form\n");
    std::printf("  isotropic phase %.6f, albedo %.2f, tau %.2f\n\n",
                isoPhase, albedo, static_cast<double>(sigma * thickness));
    std::printf("  %8s %14s %14s %10s\n", "mu", "measured", "analytic", "rel err");

    const double muSweep[] = { 0.9, 0.7, 0.5 };
    for (double mu : muSweep) {
        Scene_0 s = nee;
        s.medium_0.majorant_0 = sigma * 2.0f;

        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);

        const Run r = runTrace(scratch, s, iso, bottom, dir, 0x7E57u, trials);
        const double an  = neeAnalytic(albedo, isoPhase, E, sigma, thickness, mu);
        const double rel = (r.meanRadiance - an) / an;

        std::printf("  %8.2f %14.8f %14.8f %+9.3f%%\n", mu, r.meanRadiance, an, rel * 100.0);

        if (std::fabs(rel) > 0.015) {
            std::printf("    FAIL: next-event estimation is off by %.2f%% at mu = %.2f\n",
                        rel * 100.0, mu);
            ++failures;
        }
    }

    // The majorant sweep, on the test that can actually see it.
    std::printf("\n  and the majorant must not reach the answer (mu = 0.7)\n");
    std::printf("  %12s %14s %14s %10s\n", "x sigma", "measured", "analytic", "rel err");
    {
        const double mu = 0.7;
        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);
        const double an  = neeAnalytic(albedo, isoPhase, E, sigma, thickness, mu);

        const float scales[] = { 1.0f, 2.0f, 5.0f, 20.0f, 100.0f };
        for (float k : scales) {
            Scene_0 s = nee;
            s.medium_0.majorant_0 = sigma * k;

            const Run r = runTrace(scratch, s, iso, bottom, dir, 0x7E57u, trials);
            const double rel = (r.meanRadiance - an) / an;

            std::printf("  %12.0f %14.8f %14.8f %+9.3f%%\n",
                        static_cast<double>(k), r.meanRadiance, an, rel * 100.0);

            if (std::fabs(rel) > 0.015) {
                std::printf("    FAIL: the answer moved with the majorant -- %.2f%% at %.0fx.\n"
                            "          That is a premature escape or a truncated shadow, and\n"
                            "          the furnace test is blind to both.\n", rel * 100.0, k);
                ++failures;
            }
        }
    }

    // And once with a real droplet phase, so the forward peak is in the loop too.
    {
        const double mu = 0.7;
        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);

        const PhaseInput_0 ph = dropletPhase(20.0f);
        const double phv = phaseValue(ph, mu);

        Scene_0 s = nee;
        s.medium_0.majorant_0 = sigma * 2.0f;

        const Run r  = runTrace(scratch, s, ph, bottom, dir, 0x7E57u, trials);
        const double an  = neeAnalytic(albedo, phv, E, sigma, thickness, mu);
        const double rel = (r.meanRadiance - an) / an;

        std::printf("\n  droplet phase, 20 microns: phase(%.2f) = %.6f\n", mu, phv);
        std::printf("  measured %.8f against analytic %.8f (%+.3f%%)\n",
                    r.meanRadiance, an, rel * 100.0);

        if (std::fabs(rel) > 0.015) {
            std::printf("    FAIL: next-event estimation is off by %.2f%% with a real phase\n",
                        rel * 100.0);
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 5. The prototype's shadow-ray offset, measured
    // -----------------------------------------------------------------------
    //
    // proto/index.html starts the shadow ray one metre along the sun direction, which is
    // the reflex a surface ray tracer teaches. THERE IS NO SURFACE HERE, so the offset
    // buys nothing and skips one metre of medium -- every shadow comes back brighter by
    // about exp(sigma * offset).
    //
    // Reported rather than asserted away, because the number is the point: 0.25% in this
    // thin cirrus, and the same offset in a cumulus at sigma 0.05 would be 5%.
    // THE BIAS IS COMPARED AGAINST ITS OWN PREDICTION, not merely shown to exist.
    // Skipping `offset` metres of a medium of extinction sigma multiplies every shadow
    // by exp(sigma * offset), so if that formula is the mechanism, the measured ratio
    // must follow it. Reported relative to the offset-0 run rather than to the analytic
    // value, so that the comparison is not carrying this scene's Monte Carlo error.
    std::printf("\nTHE PROTOTYPE'S SHADOW OFFSET, measured (mu = 0.7)\n");
    std::printf("  %10s %14s %12s %12s %12s\n",
                "offset m", "measured", "vs exact", "vs offset 0", "exp(sig*d)");
    {
        const double mu = 0.7;
        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);
        const double an  = neeAnalytic(albedo, isoPhase, E, sigma, thickness, mu);

        double baseline = 0.0;
        const float offsets[] = { 0.0f, 1.0f, 10.0f, 50.0f };
        for (float off : offsets) {
            Scene_0 s = nee;
            s.medium_0.majorant_0 = sigma * 2.0f;
            s.shadowOffset_0      = off;

            const Run r = runTrace(scratch, s, iso, bottom, dir, 0x7E57u, trials);
            if (off == 0.0f) baseline = r.meanRadiance;

            const double rel       = r.meanRadiance / baseline;
            const double predicted = std::exp(static_cast<double>(sigma) * off);

            std::printf("  %10.0f %14.8f %11.4fx %11.4fx %11.4fx\n",
                        static_cast<double>(off), r.meanRadiance,
                        r.meanRadiance / an, rel, predicted);

            // Asserted up to 10 m only, and the 50 m row shows why it stops there.
            //
            // exp(sigma * offset) assumes the shadow path shortens by `offset` at every
            // scatter point. For a point within `offset` of the slab top it cannot: the
            // shadow origin lands OUTSIDE the medium, the formula would demand a
            // transmittance above 1, and the estimator correctly returns exactly 1. So
            // the measured bias falls SHORT of the naive prediction near the top, by
            // more of the slab the larger the offset -- 1.1316x against 1.1331x at 50 m.
            //
            // That is the formula's limit rather than the code's, which is the reason to
            // show the row and not to assert against it.
            if (off > 0.0f && off <= 10.0f && std::fabs(rel - predicted) > 0.005) {
                std::printf("    FAIL: the bias is %.4fx where exp(sigma*offset) predicts\n"
                            "          %.4fx, so the explanation in Bounce.slang is wrong\n",
                            rel, predicted);
                ++failures;
            }
        }
        std::printf("  so the prototype's 1 m offset is +0.24%% of light at EVERY event.\n");
        std::printf("  the shipped value is 0, and Bounce.slang says why\n");
    }

    // -----------------------------------------------------------------------
    // 6. The camera segment's sun as a sum: the same answers, less noise
    // -----------------------------------------------------------------------
    //
    // cameraSegmentSun replaces delta tracking's single next event at the first real
    // collision with a continuous estimate over the tentative collisions, weighted by
    // the ratio-tracked transmittance. It claims to be unbiased for any rate at or
    // above the density, so it is held to EVERYTHING section 4 holds the original to
    // -- the closed form at three angles, the majorant sweep, a real droplet phase --
    // and then to one thing more: that it is actually a variance technique, since an
    // estimator that matched the closed form by doing nothing different would pass
    // all the rest.
    //
    // THE STDEV RATIO BELOW IS PRINTED, NOT ASSERTED, AND IT IS ABOUT 1 ON PURPOSE.
    // This slab is optically THICK (tau 2.5): nearly every ray scatters, so delta
    // tracking's coin toss was never the noise here -- the depth of the scatter point,
    // and so its shadow, is. The resampled estimate draws that depth the same way.
    // The regime the estimator is for is the thin one, and the control is there.
    std::printf("\nTHE CAMERA SEGMENT'S SUN AS A SUM -- the closed form again\n");
    std::printf("  %8s %6s %14s %14s %10s %10s %10s\n",
                "mu", "scale", "measured", "analytic", "rel err", "stdev", "vs delta");
    for (double mu : muSweep) {
        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);
        const double an  = neeAnalytic(albedo, isoPhase, E, sigma, thickness, mu);

        Scene_0 delta = nee;
        delta.medium_0.majorant_0 = sigma * 2.0f;
        const Run rd = runTrace(scratch, delta, iso, bottom, dir, 0x7E57u, trials);

        const float scaleSweep[] = { 1.0f, 4.0f };
        for (float k : scaleSweep) {
            Scene_0 s = delta;
            s.neeTentativeScale_0 = k;

            const Run r = runTrace(scratch, s, iso, bottom, dir, 0x7E57u, trials);
            const double rel = (r.meanRadiance - an) / an;

            std::printf("  %8.2f %6.0f %14.8f %14.8f %+9.3f%% %10.6f %9.2fx\n",
                        mu, static_cast<double>(k), r.meanRadiance, an, rel * 100.0,
                        r.stdevRadiance, rd.stdevRadiance / r.stdevRadiance);

            if (std::fabs(rel) > 0.015) {
                std::printf("    FAIL: the summed estimator is off by %.2f%% at mu = %.2f,\n"
                            "          scale %.0f -- it is not estimating the same integral\n",
                            rel * 100.0, mu, static_cast<double>(k));
                ++failures;
            }
        }
    }

    // THE REGIME IT IS FOR, AND THE CONTROL. Optically thin -- tau 0.1 -- under a
    // majorant fifty times the density, so a ray crosses several tentative points
    // and most of them are null. That is a cirrus: a bound set by the densest streak,
    // and a ray that mostly passes through thin ice. Delta tracking returns the sun
    // for about one ray in seven and nothing for the rest; the continuous estimate
    // returns a little for nearly every ray.
    //
    // 3x IN STDEV, against 7.3x measured when written (53x in variance): loose
    // enough not to flake, tight enough that an estimator which had quietly fallen
    // back to a coin toss would fail it.
    {
        const float thinSigma = 0.0001f;   // tau 0.1 across the slab
        const double mu = 0.7;
        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);
        const double an  = neeAnalytic(albedo, isoPhase, E, thinSigma, thickness, mu);

        Scene_0 delta = nee;
        delta.medium_0.density_0  = thinSigma;
        delta.medium_0.majorant_0 = thinSigma * 50.0f;

        Scene_0 summed = delta;
        summed.neeTentativeScale_0 = 1.0f;

        const Run rd = runTrace(scratch, delta,  iso, bottom, dir, 0x7E58u, trials);
        const Run rs = runTrace(scratch, summed, iso, bottom, dir, 0x7E58u, trials);
        const double relD = (rd.meanRadiance - an) / an;
        const double relS = (rs.meanRadiance - an) / an;
        const double gain = rd.stdevRadiance / rs.stdevRadiance;

        std::printf("\n  thin slab (tau 0.1) under a 50x majorant, mu 0.7, scale 1:\n");
        std::printf("    delta tracking %.8f (%+.3f%%)  stdev %.6f\n",
                    rd.meanRadiance, relD * 100.0, rd.stdevRadiance);
        std::printf("    continuous     %.8f (%+.3f%%)  stdev %.6f  -- %.2fx less\n",
                    rs.meanRadiance, relS * 100.0, rs.stdevRadiance, gain);

        if (std::fabs(relS) > 0.015) {
            std::printf("    FAIL: off the closed form by %.2f%% in the thin slab\n", relS * 100.0);
            ++failures;
        }
        if (gain < 3.0) {
            std::printf("    FAIL: only %.2fx less spread than delta tracking, in the regime\n"
                        "          the estimator exists for\n", gain);
            ++failures;
        }
    }

    // The majorant sweep again. At scale 1 the tentative rate IS the majorant, so a
    // loose one means more, lighter points -- and the answer must not move. Stops at
    // 20x: at 100x a 1000 m slab at mu 0.7 needs ~360 tentative points and that is
    // still inside kTrackCap, but it tests the cap rather than the estimator.
    std::printf("\n  and the majorant must not reach the answer (mu = 0.7, scale 1)\n");
    {
        const double mu = 0.7;
        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);
        const double an  = neeAnalytic(albedo, isoPhase, E, sigma, thickness, mu);

        const float scales[] = { 1.0f, 2.0f, 5.0f, 20.0f };
        for (float k : scales) {
            Scene_0 s = nee;
            s.medium_0.majorant_0 = sigma * k;
            s.neeTentativeScale_0 = 1.0f;

            const Run r = runTrace(scratch, s, iso, bottom, dir, 0x7E57u, trials);
            const double rel = (r.meanRadiance - an) / an;

            std::printf("  %12.0fx %14.8f %14.8f %+9.3f%%\n",
                        static_cast<double>(k), r.meanRadiance, an, rel * 100.0);

            if (std::fabs(rel) > 0.015) {
                std::printf("    FAIL: the summed estimator moved with the majorant --\n"
                            "          %.2f%% at %.0fx\n", rel * 100.0, static_cast<double>(k));
                ++failures;
            }
        }
    }

    // A real droplet phase, so the forward peak is weighted at every point too.
    {
        const double mu = 0.7;
        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);

        const PhaseInput_0 ph = dropletPhase(20.0f);
        const double an = neeAnalytic(albedo, phaseValue(ph, mu), E, sigma, thickness, mu);

        Scene_0 s = nee;
        s.medium_0.majorant_0 = sigma * 2.0f;
        s.neeTentativeScale_0 = 4.0f;

        const Run r = runTrace(scratch, s, ph, bottom, dir, 0x7E57u, trials);
        const double rel = (r.meanRadiance - an) / an;
        std::printf("\n  droplet phase, 20 microns, scale 4: measured %.8f against %.8f (%+.3f%%)\n",
                    r.meanRadiance, an, rel * 100.0);
        if (std::fabs(rel) > 0.015) {
            std::printf("    FAIL: the summed estimator is off by %.2f%% with a real phase\n",
                        rel * 100.0);
            ++failures;
        }
    }

    // THE FURNACE, WITH THE SUM ON. The sun is black here, so the sum adds nothing --
    // but it consumes draws and it switches off the first event's own next event, and
    // the per-path identity must survive both exactly.
    {
        Scene_0 s = base;
        s.maxBounces_0        = 64;
        s.neeTentativeScale_0 = 4.0f;

        const Run r = runTrace(scratch, s, iso, mid, up, 0xB0117CEu, trials);
        const double shortfall = 1.0 - r.meanRadiance;
        const double diff      = std::fabs(shortfall - r.cappedFraction);
        std::printf("\n  furnace, scale 4, 64 bounces: %.6f (capped %.6f, |diff| %.2e)\n",
                    r.meanRadiance, r.cappedFraction, diff);
        if (diff > 1e-6) {
            std::printf("    FAIL: the furnace identity broke with the sum on\n");
            ++failures;
        }
    }

    // THE WHOLE PATH, NOT ONLY THE FIRST EVENT. A lit, absorbing, multiple-scattering
    // scene with a sky: the sum replaces one term of many, and skipping the first
    // event's own next event is only right if nothing else was skipped with it. So the
    // two estimators must agree on the complete answer, within their joint error.
    {
        const double mu = 0.7;
        const double sa = std::sqrt(1.0 - mu * mu);
        const float3 dir = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);

        Scene_0 s = nee;
        s.environment_0.uniformRadiance_0 = make_float3(0.3f, 0.3f, 0.3f);
        s.medium_0.majorant_0 = sigma * 2.0f;
        s.maxBounces_0        = 64;

        const PhaseInput_0 ph = dropletPhase(20.0f);

        Scene_0 on = s;
        on.neeTentativeScale_0 = 4.0f;

        const Run rOff = runTrace(scratch, s,  ph, bottom, dir, 0xA11u, dropletTrials);
        const Run rOn  = runTrace(scratch, on, ph, bottom, dir, 0xA12u, dropletTrials);

        const double se = std::sqrt(rOff.stdevRadiance * rOff.stdevRadiance +
                                    rOn.stdevRadiance  * rOn.stdevRadiance) /
                          std::sqrt(static_cast<double>(dropletTrials));
        const double z  = (rOn.meanRadiance - rOff.meanRadiance) / se;

        std::printf("\n  full path, sky 0.3, 64 bounces, droplet phase:\n");
        std::printf("    delta tracking %.7f (stdev %.5f)\n", rOff.meanRadiance, rOff.stdevRadiance);
        std::printf("    summed, x4     %.7f (stdev %.5f)   %.2f standard errors apart\n",
                    rOn.meanRadiance, rOn.stdevRadiance, z);
        if (std::fabs(z) > 5.0) {
            std::printf("    FAIL: the two estimators disagree on the whole path --\n"
                        "          something besides the first next event was dropped\n");
            ++failures;
        }
    }


    // -----------------------------------------------------------------------
    // 7. LOCAL LIGHTS (build 29): one light per event against every light summed
    // -----------------------------------------------------------------------
    //
    // Two points (one inside the slab, one below it), a spot with a feathered cone and a
    // Smooth falloff, a parallel light, and a six-texel sheet inside the slab. Single
    // scatter, black sky, no sun: what is measured is the lights' next event alone, against
    // lightsReference above. Each light alone as well, so a failure names its kind.
    std::printf("\nLOCAL LIGHTS -- one light drawn per event, against every light summed\n");
    {
        using namespace plugin::cloud;

        PhaseInput_0 hg{};
        hg.hgG_0 = 0.5f;
        hg.useIce_0 = 0;
        const PhaseTable table = phaseTable(hg, 8193);

        const SlabRef slab{ slabBottom, slabTop, sigma };
        const double lightAlbedo = 0.8;
        const double mu = 0.7;
        const double sa = std::sqrt(1.0 - mu * mu);
        const double o[3]   = { 0.0, slabBottom, 0.0 };
        const double dir[3] = { sa, mu, 0.0 };
        const float3 dirF   = make_float3(static_cast<float>(sa), static_cast<float>(mu), 0.0f);

        std::vector<LocalLight> all;
        LocalLight a;
        a.kind = LightKind::Point;
        a.position[0] = 500.0f; a.position[1] = 1550.0f; a.position[2] = 150.0f;
        a.intensity = 0.02f;
        a.radius = 60.0f;
        all.push_back(a);

        LocalLight below = a;
        below.position[0] = -300.0f; below.position[1] = 700.0f; below.position[2] = -100.0f;
        below.intensity = 0.05f;
        below.radius = 40.0f;
        all.push_back(below);

        LocalLight spot;
        spot.kind = LightKind::Spot;
        spot.position[0] = 600.0f; spot.position[1] = 2400.0f; spot.position[2] = 0.0f;
        spot.direction[0] = 0.0f; spot.direction[1] = -1.0f; spot.direction[2] = 0.0f;
        spot.intensity = 0.03f;
        spot.radius = 80.0f;
        spot.coneAngleDeg = 70.0f;
        spot.coneFeather = 0.4f;
        spot.smoothFalloff = 900.0f;
        all.push_back(spot);

        LocalLight par;
        par.kind = LightKind::Parallel;
        par.direction[0] = -0.3f; par.direction[1] = -0.8f; par.direction[2] = -0.2f;
        par.intensity = 0.002f;
        all.push_back(par);

        LightSheet sheet;
        sheet.width = 3;
        sheet.height = 2;
        sheet.rgb = { 0.002f, 0.002f, 0.002f,   0.0f, 0.0f, 0.0f,         0.005f, 0.005f, 0.005f,
                      0.001f, 0.001f, 0.001f,   0.003f, 0.003f, 0.003f,   0.0f, 0.0f, 0.0f };
        SheetPlacement place;
        place.origin[0] = 200.0f; place.origin[1] = 1150.0f; place.origin[2] = -250.0f;
        place.axisU[0] = 150.0f;
        place.axisV[1] = 120.0f; place.axisV[2] = 60.0f;

        LightAnchor anchor;
        anchor.point[0] = 500.0f; anchor.point[1] = 1500.0f;
        const float noAmbient[3] = { 0.0f, 0.0f, 0.0f };

        float* dLights = nullptr;
        auto run = [&](const LightSet& set, float neeScale, unsigned seed, int n,
                       double& measured, double& reference) {
            cudaFree(dLights);
            cudaMalloc(&dLights, set.packed.size() * sizeof(float));
            cudaMemcpy(dLights, set.packed.data(), set.packed.size() * sizeof(float),
                       cudaMemcpyHostToDevice);
            Scene_0 s = nee;
            s.sunIrradiance_0 = make_float3(0.0f, 0.0f, 0.0f);
            s.albedo_0 = make_float3(static_cast<float>(lightAlbedo), static_cast<float>(lightAlbedo),
                                     static_cast<float>(lightAlbedo));
            s.medium_0.majorant_0 = sigma * 2.0f;
            s.neeTentativeScale_0 = neeScale;
            s.ltCount_0 = set.count;
            s.ltBuffer_0.data = dLights;
            s.ltBuffer_0.count = set.packed.size();
            measured  = runTrace(scratch, s, hg, bottom, dirF, seed, n).meanRadiance;
            reference = lightsReference(set.packed, slab, lightAlbedo, o, dir, table);
        };

        const int lightTrials = 1 << 21;
        std::printf("  HG phase g 0.5, albedo %.1f, mu %.1f, %d trials\n\n", lightAlbedo, mu, lightTrials);
        std::printf("  %-22s %14s %14s %10s\n", "light", "measured", "quadrature", "rel err");

        const char* names[] = { "point, in the slab", "point, below it", "spot, feathered",
                                "parallel" };
        for (int i = 0; i < 4; ++i) {
            LightSet one;
            packLightSet({ all[i] }, noAmbient, nullptr, nullptr, 1.0f, anchor, one);
            double m = 0.0, ref = 0.0;
            run(one, 0.0f, 0x11A0u + i, lightTrials, m, ref);
            const double rel = (m - ref) / ref;
            std::printf("  %-22s %14.8f %14.8f %+9.3f%%\n", names[i], m, ref, rel * 100.0);
            if (std::fabs(rel) > 0.02) {
                std::printf("    FAIL: the %s is off by %.2f%%\n", names[i], rel * 100.0);
                ++failures;
            }
        }
        {
            LightSet one;
            packLightSet({}, noAmbient, &sheet, &place, 1.0f, anchor, one);
            double m = 0.0, ref = 0.0;
            run(one, 0.0f, 0x11A9u, lightTrials, m, ref);
            const double rel = (m - ref) / ref;
            std::printf("  %-22s %14.8f %14.8f %+9.3f%%\n", "sheet, six texels", m, ref, rel * 100.0);
            if (std::fabs(rel) > 0.02) {
                std::printf("    FAIL: the sheet is off by %.2f%%\n", rel * 100.0);
                ++failures;
            }
        }

        // A BOLT ACROSS A 16 x 10 SHEET WHOSE PLANE THE CAMERA RAY CROSSES, so the points near
        // it draw from the window round their projection as well as from the whole sheet --
        // and the mixture's probability is what the answer rests on. A diagonal channel, a
        // bright texel near the crossing and a brighter one far from it.
        {
            LightSheet bolt;
            bolt.width = 16;
            bolt.height = 10;
            bolt.rgb.assign(16 * 10 * 3, 0.0f);
            auto lit = [&](int iu, int iv, float v) {
                for (int c = 0; c < 3; ++c) bolt.rgb[(iv * 16 + iu) * 3 + c] = v;
            };
            for (int iu = 2; iu <= 14; ++iu) lit(iu, 1 + (iu - 2) * 7 / 12, 0.003f);
            lit(4, 3, 0.01f);
            lit(15, 0, 0.02f);
            SheetPlacement across;
            across.origin[0] = -100.0f; across.origin[1] = 1050.0f; across.origin[2] = -60.0f;
            across.axisU[0] = 70.0f;
            across.axisV[1] = 60.0f; across.axisV[2] = 20.0f;

            LightSet one;
            packLightSet({}, noAmbient, &bolt, &across, 1.0f, anchor, one);
            double m = 0.0, ref = 0.0;
            run(one, 0.0f, 0x11AAu, lightTrials, m, ref);
            const double rel = (m - ref) / ref;
            std::printf("  %-22s %14.8f %14.8f %+9.3f%%\n", "sheet, a bolt crossed", m, ref, rel * 100.0);
            if (std::fabs(rel) > 0.02) {
                std::printf("    FAIL: the crossed sheet is off by %.2f%% -- the window's\n"
                            "          probability is not what the kernel divides by\n", rel * 100.0);
                ++failures;
            }

            // THE SAME BOLT LAID ON A FACE: every texel pushed along an eye's rays by its own
            // scale, as conformLightSheet lays it on the cloud, so the texels are off one
            // plane, of different sizes, and the tree's cells are where they stand.
            SheetPlacement laid = across;
            laid.eye[0] = -400.0f; laid.eye[1] = 600.0f; laid.eye[2] = -1500.0f;
            laid.scale.assign(16 * 10, 1.0f);
            for (int t = 0; t < 16 * 10; ++t)
                laid.scale[t] = 0.75f + 0.5f * static_cast<float>((t * 37) % 11) / 10.0f;

            LightSet onFace;
            packLightSet({}, noAmbient, &bolt, &laid, 1.0f, anchor, onFace);
            run(onFace, 0.0f, 0x11ABu, lightTrials, m, ref);
            const double relLaid = (m - ref) / ref;
            std::printf("  %-22s %14.8f %14.8f %+9.3f%%\n", "sheet, laid on a face", m, ref,
                        relLaid * 100.0);
            if (std::fabs(relLaid) > 0.02) {
                std::printf("    FAIL: the laid sheet is off by %.2f%% -- its texels are not\n"
                            "          where the kernel draws them, or not the size\n",
                            relLaid * 100.0);
                ++failures;
            }
        }

        // ALL FIVE AT ONCE, which is where the pick probabilities are divided by -- and once
        // more through the camera segment's walk, which is how the renderer finds the first
        // event.
        LightSet set;
        packLightSet(all, noAmbient, &sheet, &place, 1.0f, anchor, set);
        const float scales[] = { 0.0f, 1.0f };
        for (float k : scales) {
            double m = 0.0, ref = 0.0;
            run(set, k, 0x11B0u + static_cast<unsigned>(k), lightTrials, m, ref);
            const double rel = (m - ref) / ref;
            std::printf("  %-22s %14.8f %14.8f %+9.3f%%\n",
                        k > 0.0f ? "all five, segment walk" : "all five", m, ref, rel * 100.0);
            if (std::fabs(rel) > 0.015) {
                std::printf("    FAIL: the lights together are off by %.2f%% -- the picks are\n"
                            "          not what the kernel divides by\n", rel * 100.0);
                ++failures;
            }
        }

        // AE's AMBIENT LIGHT: a uniform dome every scattered path sees on its way out, and
        // the camera does not. In a conservative medium a path that scatters returns exactly
        // the ambient radiance or is capped, so the mean is an identity, as the furnace's is:
        // A x (P(the camera ray scatters) - P(capped)).
        {
            LightSet amb;
            const float A[3] = { 0.25f, 0.25f, 0.25f };
            packLightSet({}, A, nullptr, nullptr, 1.0f, anchor, amb);
            Scene_0 s = base;
            s.environment_0.uniformRadiance_0 = make_float3(0.0f, 0.0f, 0.0f);
            s.maxBounces_0 = 128;
            s.ltCount_0 = amb.count;
            s.ltAmbient_0 = make_float3(amb.ambient[0], amb.ambient[1], amb.ambient[2]);
            const Run r = runTrace(scratch, s, iso, bottom, dirF, 0xA3B1u, trials);
            const double scatter = 1.0 - std::exp(-static_cast<double>(sigma * thickness) / mu);
            const double expect = 0.25 * (scatter - r.cappedFraction);
            const double se = 0.25 * std::sqrt(scatter * (1.0 - scatter) / trials);
            std::printf("  %-22s %14.8f %14.8f   (%.1f standard errors)\n", "ambient dome",
                        r.meanRadiance, expect, (r.meanRadiance - expect) / se);
            if (std::fabs(r.meanRadiance - expect) > 5.0 * se) {
                std::printf("    FAIL: the ambient light is not what a scattered path sees\n");
                ++failures;
            }
        }
        cudaFree(dLights);
    }

    std::printf("\n%s\n", failures == 0
        ? "the bounce loop conserves energy, and roulette and the majorant do not reach the answer"
        : "BOUNCE LOOP CHECKS FAILED");
    return failures == 0 ? 0 : 1;
}
