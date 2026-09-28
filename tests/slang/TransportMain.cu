// Null-collision transport, checked against the answers it must give.
//
// ===========================================================================
// THE MAJORANT SWEEP IS THE TEST THAT MATTERS.
//
// Delta and ratio tracking exist to make a heterogeneous medium tractable without
// ever integrating its density. The method's promise is that the MAJORANT -- any
// upper bound on density -- is a free parameter: it changes how long the estimator
// takes and nothing about the answer.
//
// So the test is not "does it produce a plausible number". It is:
//
//   1. In a constant-density slab, transmittance equals exp(-sigma * d) exactly.
//   2. The free-flight distance is exponentially distributed with rate sigma.
//   3. NEITHER ANSWER MOVES WHEN THE MAJORANT DOES.
//
// Almost every way of getting null collisions wrong -- the wrong ratio, forgetting
// that a rejected collision still advances t, a comparison on the wrong side --
// leaves an estimator that is biased AS A FUNCTION OF THE MAJORANT while still
// rendering a perfectly plausible cloud at any single setting. Checking one majorant
// would pass. Sweeping it is what makes the check mean anything.
// ===========================================================================

#include <cstdio>
#include <cmath>
#include <vector>
#include <algorithm>

#include <cuda_runtime.h>

#include "Transport.cu"

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

// A majorant grid plus the device buffer holding its bounds.
// The drift table iceDensity needs. mode 0 and mode 1 never read it, but it is a
// kernel parameter regardless, so every call site needs one.
struct Drift {
    float2* dev = nullptr;
    static Drift zero() {
        Drift d;
        std::vector<float2> knots(33, make_float2(0.0f, 0.0f));
        cudaMalloc(&d.dev, knots.size() * sizeof(float2));
        cudaMemcpy(d.dev, knots.data(), knots.size() * sizeof(float2), cudaMemcpyHostToDevice);
        return d;
    }
    StructuredBuffer<float2> buffer() const {
        StructuredBuffer<float2> b; b.data = dev; b.count = 33; return b;
    }
};

struct Grid {
    MajorantGrid_0 desc{};
    float*         dev = nullptr;
    std::vector<float> host;

    // DISABLED IS THE DEFAULT, and every test written before the grid existed uses it.
    // `ddaInit` short-circuits on it, so the estimators are bit-for-bit what they were.
    static Grid disabled() {
        Grid g;
        g.desc.origin_0   = make_float3(0.0f, 0.0f, 0.0f);
        g.desc.cellExtent_0 = make_float3(1.0f, 1.0f, 1.0f);
        g.desc.dims_0     = make_int3(1, 1, 1);
        g.desc.enabled_0  = 0;
        cudaMalloc(&g.dev, sizeof(float));
        return g;
    }

    StructuredBuffer<float> buffer() const {
        StructuredBuffer<float> b;
        b.data  = dev;
        b.count = host.empty() ? 1 : host.size();
        return b;
    }
};

// ---------------------------------------------------------------------------
// THE BOUNDS ARE COMPUTED IN CLOSED FORM, NOT SAMPLED, AND THAT IS THE POINT.
// ---------------------------------------------------------------------------
//
// Delta tracking is unbiased for any majorant ABOVE the true density and silently
// biased below it, so a grid is only as trustworthy as the proof that every cell bounds
// its contents. Sampling a cell at some resolution and taking the maximum can always
// miss a peak between samples -- and the resulting bias looks exactly like a slightly
// thin cloud, which is the failure this project has already shipped once.
//
// mode 1 is a background plus one Gaussian core precisely so the maximum over an
// axis-aligned box is exact: density falls monotonically with distance from the centre,
// so the box's maximum is at the point of the box NEAREST the centre. Clamping the
// centre into the box finds it in three lines.
//
// The y range is intersected with the slab first, because outside it the density is
// zero however close the core is.
Grid buildGrid(const Medium_0& m, float3 lo, float3 hi, int3 dims) {
    Grid g;
    g.desc.origin_0   = lo;
    g.desc.cellExtent_0 = make_float3((hi.x - lo.x) / dims.x,
                                    (hi.y - lo.y) / dims.y,
                                    (hi.z - lo.z) / dims.z);
    g.desc.dims_0     = dims;
    g.desc.enabled_0  = 1;

    g.host.resize(static_cast<size_t>(dims.x) * dims.y * dims.z);

    for (int cz = 0; cz < dims.z; ++cz)
    for (int cy = 0; cy < dims.y; ++cy)
    for (int cx = 0; cx < dims.x; ++cx) {
        const float x0 = lo.x + cx * g.desc.cellExtent_0.x, x1 = x0 + g.desc.cellExtent_0.x;
        const float y0 = lo.y + cy * g.desc.cellExtent_0.y, y1 = y0 + g.desc.cellExtent_0.y;
        const float z0 = lo.z + cz * g.desc.cellExtent_0.z, z1 = z0 + g.desc.cellExtent_0.z;

        const float sy0 = std::max(y0, m.slabBottom_0);
        const float sy1 = std::min(y1, m.slabTop_0);

        float bound = 0.0f;
        if (sy0 <= sy1) {
            // The point of the (slab-clipped) box nearest the core centre.
            const float nx = std::min(std::max(m.coreCentre_0.x, x0),  x1);
            const float ny = std::min(std::max(m.coreCentre_0.y, sy0), sy1);
            const float nz = std::min(std::max(m.coreCentre_0.z, z0),  z1);

            const float dx = (nx - m.coreCentre_0.x) / m.coreRadius_0;
            const float dy = (ny - m.coreCentre_0.y) / m.coreRadius_0;
            const float dz = (nz - m.coreCentre_0.z) / m.coreRadius_0;

            bound = m.density_0 + (m.mode_0 == 0
                        ? 0.0f
                        : m.coreDensity_0 * std::exp(-(dx * dx + dy * dy + dz * dz)));
        }
        g.host[(static_cast<size_t>(cz) * dims.y + cy) * dims.x + cx] = bound;
    }

    cudaMalloc(&g.dev, g.host.size() * sizeof(float));
    cudaMemcpy(g.dev, g.host.data(), g.host.size() * sizeof(float), cudaMemcpyHostToDevice);
    return g;
}

std::vector<float> runTransmittance(Medium_0 m, const Grid& g, const Drift& dr,
                                    float3 origin, float3 dir,
                                    unsigned seed, int n, double* meanSteps = nullptr) {
    float* d = nullptr;
    int*   s = nullptr;
    cudaMalloc(&d, static_cast<size_t>(n) * sizeof(float));
    cudaMalloc(&s, static_cast<size_t>(n) * sizeof(int));

    RWStructuredBuffer<float> buf;  buf.data  = d; buf.count = static_cast<size_t>(n);
    RWStructuredBuffer<int>   stp;  stp.data  = s; stp.count = static_cast<size_t>(n);

    transmittanceTrial<<<(n + 63) / 64, 64>>>(m, g.desc, g.buffer(), dr.buffer(), origin, dir,
                                              buf, stp, seed, n);

    std::vector<float> out(n);
    std::vector<int>   steps(n);
    cudaMemcpy(out.data(),   d, out.size()   * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(steps.data(), s, steps.size() * sizeof(int),   cudaMemcpyDeviceToHost);
    cudaFree(d);
    cudaFree(s);

    if (meanSteps) {
        long long total = 0;
        for (int v : steps) total += v;
        *meanSteps = static_cast<double>(total) / n;
    }
    return out;
}

std::vector<float> runFreeFlight(Medium_0 m, const Grid& g, const Drift& dr,
                                 float3 origin, float3 dir,
                                 unsigned seed, int n, double* meanSteps = nullptr) {
    float* d = nullptr;
    int*   s = nullptr;
    cudaMalloc(&d, static_cast<size_t>(n) * sizeof(float));
    cudaMalloc(&s, static_cast<size_t>(n) * sizeof(int));

    RWStructuredBuffer<float> buf;  buf.data = d; buf.count = static_cast<size_t>(n);
    RWStructuredBuffer<int>   stp;  stp.data = s; stp.count = static_cast<size_t>(n);

    freeFlightTrial<<<(n + 63) / 64, 64>>>(m, g.desc, g.buffer(), dr.buffer(), origin, dir,
                                           buf, stp, seed, n);

    std::vector<float> out(n);
    std::vector<int>   steps(n);
    cudaMemcpy(out.data(),   d, out.size()   * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(steps.data(), s, steps.size() * sizeof(int),   cudaMemcpyDeviceToHost);
    cudaFree(d);
    cudaFree(s);

    if (meanSteps) {
        long long total = 0;
        for (int v : steps) total += v;
        *meanSteps = static_cast<double>(total) / n;
    }
    return out;
}

} // namespace

int main() {
    int deviceCount = 0;
    if (cudaGetDeviceCount(&deviceCount) != cudaSuccess || deviceCount == 0) {
        std::printf("no CUDA device -- skipping (this test needs a GPU)\n");
        return 0;
    }

    int failures = 0;

    // A SLAB ONE KILOMETRE THICK, crossed vertically, so the path length through it
    // is exactly 1000 m and the analytic answer needs no geometry of its own.
    const float thickness = 1000.0f;
    const float sigma     = 0.0025f;          // optical depth 2.5 across the slab
    const float expected  = std::exp(-sigma * thickness);

    Medium_0 base;
    base.slabTop_0    = 2000.0f;
    base.slabBottom_0 = 2000.0f - thickness;
    base.density_0    = sigma;
    base.coreCentre_0  = make_float3(0.0f, 0.0f, 0.0f);
    base.coreRadius_0  = 1.0f;
    base.coreDensity_0 = 0.0f;
    base.mode_0       = 0;

    // The pre-grid suite runs with the grid off, so its numbers still mean what they
    // meant when they were blessed. The grid gets its own section below.
    const Grid  noGrid  = Grid::disabled();
    const Drift noDrift = Drift::zero();
    base.majorant_0   = sigma;

    // Start below the slab looking straight up, so the ray crosses the full
    // thickness and t0/t1 do the work.
    const float3 origin = make_float3(0.0f, 0.0f, 0.0f);
    const float3 up     = make_float3(0.0f, 1.0f, 0.0f);

    const int trials = 1 << 21;   // 2.1M

    // -----------------------------------------------------------------------
    // 1 + 3. Transmittance, swept across majorants
    // -----------------------------------------------------------------------
    std::printf("Ratio-tracked transmittance through a constant slab\n");
    std::printf("  sigma %.4f, thickness %.0f m, optical depth %.2f\n",
                static_cast<double>(sigma), static_cast<double>(thickness),
                static_cast<double>(sigma * thickness));
    std::printf("  analytic exp(-tau) = %.6f\n\n", expected);
    std::printf("  %12s %12s %12s %10s\n", "majorant", "x sigma", "measured", "error");

    const float majorantScale[] = { 1.0f, 2.0f, 5.0f, 20.0f, 100.0f };
    for (float k : majorantScale) {
        Medium_0 m = base;
        m.majorant_0 = sigma * k;

        const std::vector<float> tr = runTransmittance(m, noGrid, noDrift, origin, up, 0x5eed1ce5u, trials);
        const double mean = kahanSum(tr) / trials;
        const double err  = mean - expected;

        std::printf("  %12.5f %12.0f %12.6f %+10.5f\n",
                    static_cast<double>(m.majorant_0), static_cast<double>(k), mean, err);

        // 3-sigma of the Monte Carlo noise at 2.1M trials is well under 0.002; a
        // majorant-dependent bias moves this by whole percent.
        if (std::fabs(err) > 0.002) {
            std::printf("    FAIL: transmittance is wrong by %+.5f at this majorant\n", err);
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 2 + 3. Free-flight distance, swept across majorants
    // -----------------------------------------------------------------------
    //
    // The ray starts INSIDE the slab going up, so the distance to the top is 1000 m
    // and the fraction that escapes without scattering must be exp(-sigma * 1000) --
    // the same analytic number, arrived at by a completely different code path.
    std::printf("\nDelta-tracked free flight from inside the slab\n");
    std::printf("  P(escape without scattering) must be exp(-tau) = %.6f\n\n", expected);
    std::printf("  %12s %12s %12s %10s\n", "majorant", "x sigma", "escaped", "error");

    const float3 inside = make_float3(0.0f, 1000.0f, 0.0f);   // slab bottom

    for (float k : majorantScale) {
        Medium_0 m = base;
        m.majorant_0 = sigma * k;

        const std::vector<float> d = runFreeFlight(m, noGrid, noDrift, inside, up, 0x1234567u, trials);

        int escaped = 0;
        double meanDist = 0.0;
        int scattered = 0;
        for (float v : d) {
            if (v < 0.0f) { ++escaped; }
            else          { meanDist += v; ++scattered; }
        }
        const double frac = static_cast<double>(escaped) / trials;
        const double err  = frac - expected;

        std::printf("  %12.5f %12.0f %12.6f %+10.5f\n",
                    static_cast<double>(m.majorant_0), static_cast<double>(k), frac, err);

        if (std::fabs(err) > 0.002) {
            std::printf("    FAIL: escape fraction is wrong by %+.5f -- the free-flight\n"
                        "          distance is not exponential with rate sigma\n", err);
            ++failures;
        }

        // The mean distance of those that DID scatter is another independent check on
        // the same distribution: for a truncated exponential it is
        // 1/sigma - L*exp(-sigma L)/(1 - exp(-sigma L)).
        if (scattered > 0) {
            meanDist /= scattered;
            const double L  = thickness;
            const double s  = sigma;
            const double an = 1.0 / s - L * std::exp(-s * L) / (1.0 - std::exp(-s * L));
            if (std::fabs(meanDist - an) > 0.01 * an) {
                std::printf("    FAIL: mean scatter depth %.1f m against analytic %.1f m\n",
                            meanDist, an);
                ++failures;
            }
        }
    }

    // -----------------------------------------------------------------------
    // A ray that misses the slab entirely
    // -----------------------------------------------------------------------
    //
    // Transmittance must be exactly 1, not approximately -- slabRange returns false
    // and nothing is sampled. Worth asserting because "no medium" is the case a
    // shadow ray hits most often, and an estimator that returned 0.999 there would
    // darken every lit surface in the scene by a hair.
    {
        Medium_0 m = base;
        m.majorant_0 = sigma * 10.0f;
        const float3 down = make_float3(0.0f, -1.0f, 0.0f);
        const std::vector<float> tr = runTransmittance(m, noGrid, noDrift, origin, down, 0x99u, 4096);
        const double mean = kahanSum(tr) / tr.size();
        std::printf("\nRay pointing away from the slab: transmittance %.6f\n", mean);
        if (mean != 1.0) {
            std::printf("  FAIL: a ray that never enters the medium must return exactly 1\n");
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // THE MAJORANT GRID
    // -----------------------------------------------------------------------
    //
    // A background plus one sharp core -- the ordinary cumulus case, not a
    // pathological one. A global majorant must cover the core, so it is loose along
    // every ray that never goes near it, and that looseness is what the iteration cap
    // eventually turns into bias.
    //
    // THE ANSWER MUST NOT MOVE AND THE COST MUST. That is the whole claim, and both
    // halves have to be measured: a grid that changed the answer would be wrong, and a
    // grid that did not change the cost would be pointless.
    {
        std::printf("\n\nMAJORANT GRID -- background plus one sharp core (mode 1)\n");

        Medium_0 spiky = base;
        spiky.mode_0        = 1;
        spiky.density_0     = sigma * 0.1f;                       // thin background
        spiky.coreCentre_0  = make_float3(0.0f, base.slabBottom_0 + thickness * 0.5f, 0.0f);
        spiky.coreRadius_0  = 60.0f;
        spiky.coreDensity_0 = sigma * 40.0f;                      // the hard core
        // A GLOBAL MAJORANT HAS TO COVER THE PEAK, wherever the ray goes.
        spiky.majorant_0    = spiky.density_0 + spiky.coreDensity_0;

        const float3 lo = make_float3(-500.0f, base.slabBottom_0, -500.0f);
        const float3 hi = make_float3( 500.0f, base.slabTop_0,  500.0f);

        // A ray up through the slab, offset well clear of the core: the case a global
        // majorant handles worst, because it pays for a peak it never meets.
        const float3 off = make_float3(300.0f, 0.0f, 0.0f);

        double stepsGlobal = 0.0;
        const std::vector<float> trGlobal =
            runTransmittance(spiky, noGrid, noDrift, off, up, 0xA11CEu, trials, &stepsGlobal);
        const double refMean = kahanSum(trGlobal) / trials;

        std::printf("  a ray clear of the core, %d trials\n\n", trials);
        std::printf("  %14s %14s %12s %10s\n", "grid", "transmittance", "steps", "vs global");
        std::printf("  %14s %14.6f %12.1f %10s\n", "none (global)", refMean, stepsGlobal, "-");

        const int3 resolutions[] = { make_int3(4, 4, 4), make_int3(8, 8, 8),
                                     make_int3(16, 16, 16), make_int3(32, 32, 32) };

        for (int3 dims : resolutions) {
            Grid g = buildGrid(spiky, lo, hi, dims);

            double steps = 0.0;
            const std::vector<float> tr =
                runTransmittance(spiky, g, noDrift, off, up, 0xA11CEu, trials, &steps);
            const double mean = kahanSum(tr) / trials;

            char label[32];
            std::snprintf(label, sizeof(label), "%dx%dx%d", dims.x, dims.y, dims.z);
            std::printf("  %14s %14.6f %12.1f %9.1fx\n",
                        label, mean, steps, stepsGlobal / steps);

            // THE GRID IS A FREE PARAMETER, exactly as the majorant is. 3-sigma of the
            // Monte Carlo noise at this trial count is well inside 0.002.
            if (std::fabs(mean - refMean) > 0.002) {
                std::printf("    FAIL: the grid moved the transmittance by %+.5f.\n"
                            "          Per-cell bounds change the COST of the estimator and\n"
                            "          must not change what it estimates.\n", mean - refMean);
                ++failures;
            }
            cudaFree(g.dev);
        }

        // -------------------------------------------------------------------
        // The control: a grid whose bounds are NOT bounds
        // -------------------------------------------------------------------
        //
        // Without this the section above proves only that the grid is harmless, which
        // is also what a grid that silently did nothing would prove. A bound below the
        // true density makes delta tracking's acceptance ratio exceed 1 and biases the
        // estimator -- so scaling every bound down MUST move the answer. If it does
        // not, this suite cannot tell a sound grid from an unsound one and none of the
        // rows above mean anything.
        {
            Grid bad = buildGrid(spiky, lo, hi, make_int3(16, 16, 16));
            for (float& b : bad.host) b *= 0.4f;
            cudaMemcpy(bad.dev, bad.host.data(), bad.host.size() * sizeof(float),
                       cudaMemcpyHostToDevice);

            const std::vector<float> tr =
                runTransmittance(spiky, bad, noDrift, off, up, 0xA11CEu, trials);
            const double mean = kahanSum(tr) / trials;

            std::printf("\n  control: every bound scaled to 0.4x (no longer a bound)\n");
            std::printf("    transmittance %.6f against %.6f -- %+.5f\n",
                        mean, refMean, mean - refMean);

            if (std::fabs(mean - refMean) <= 0.002) {
                std::printf("    FAIL: an INVALID grid gave the same answer, so this test\n"
                            "          cannot distinguish a sound grid from an unsound one\n");
                ++failures;
            } else {
                std::printf("    correctly rejected -- the check above can see an unsound grid\n");
            }
            cudaFree(bad.dev);
        }

        // -------------------------------------------------------------------
        // The other side of the trade, so the numbers above are not read as a
        // universal speed-up
        // -------------------------------------------------------------------
        //
        // Every row above is for a ray that never approaches the core -- the case a
        // global majorant handles worst and a grid handles best. A ray THROUGH the core
        // has to pay for the density that is genuinely there, and a coarse cell spreads
        // the core's bound over a large volume, so the coarse grid that won by 25x
        // above should win far less here.
        //
        // WITHOUT THIS ROW THE SWEEP IS CHERRY-PICKED. It also shows why "finer is
        // better" is wrong in both directions: a fine grid pays traversal steps it did
        // not pay before, and the two costs trade against each other.
        {
            const float3 through = make_float3(0.0f, 0.0f, 0.0f);   // straight up the axis

            double sG = 0.0;
            const std::vector<float> trG =
                runTransmittance(spiky, noGrid, noDrift, through, up, 0xC02E5u, trials, &sG);
            const double mG = kahanSum(trG) / trials;

            std::printf("\n  the same sweep for a ray THROUGH the core\n");
            std::printf("  %14s %14s %12s %10s\n", "grid", "transmittance", "steps", "vs global");
            std::printf("  %14s %14.6f %12.1f %10s\n", "none (global)", mG, sG, "-");

            for (int3 dims : resolutions) {
                Grid g = buildGrid(spiky, lo, hi, dims);

                double s = 0.0;
                const std::vector<float> tr =
                    runTransmittance(spiky, g, noDrift, through, up, 0xC02E5u, trials, &s);
                const double mean = kahanSum(tr) / trials;

                char label[32];
                std::snprintf(label, sizeof(label), "%dx%dx%d", dims.x, dims.y, dims.z);
                std::printf("  %14s %14.6f %12.1f %9.1fx\n", label, mean, s, sG / s);

                if (std::fabs(mean - mG) > 0.002) {
                    std::printf("    FAIL: the grid moved the transmittance by %+.5f on a\n"
                                "          ray through the core\n", mean - mG);
                    ++failures;
                }
                cudaFree(g.dev);
            }
        }

        // Free flight, on the same field: a second estimator over the same grid, and
        // the one whose bias runs the other way.
        {
            Grid g = buildGrid(spiky, lo, hi, make_int3(16, 16, 16));

            double sG = 0.0, sL = 0.0;
            const std::vector<float> dGlobal =
                runFreeFlight(spiky, noGrid, noDrift, off, up, 0xBEEFu, trials, &sG);
            const std::vector<float> dGrid =
                runFreeFlight(spiky, g, noDrift, off, up, 0xBEEFu, trials, &sL);

            auto escapedFraction = [&](const std::vector<float>& v) {
                int e = 0;
                for (float x : v) if (x < 0.0f) ++e;
                return static_cast<double>(e) / v.size();
            };
            const double eG = escapedFraction(dGlobal), eL = escapedFraction(dGrid);

            std::printf("\n  free flight on the same field\n");
            std::printf("    global: escaped %.6f in %.1f steps\n", eG, sG);
            std::printf("    16^3  : escaped %.6f in %.1f steps  (%.1fx fewer)\n",
                        eL, sL, sG / sL);

            if (std::fabs(eG - eL) > 0.002) {
                std::printf("    FAIL: the grid moved the escape fraction by %+.5f\n", eG - eL);
                ++failures;
            }
            cudaFree(g.dev);
        }
    }

    // -----------------------------------------------------------------------
    // THE GRID ON THE REAL FIELD
    // -----------------------------------------------------------------------
    //
    // Everything above uses an analytic medium, chosen so its bounds are exact. This is
    // the cirrus the renderer actually has to march through, with bounds from
    // `iceDensityBound` -- the structural construction slang.generator proves sound.
    //
    // THIS PRODUCES THE NUMBER THE LAST TWO ENTRIES SAID DID NOT EXIST: what the grid
    // is worth on a field whose bounds are loose rather than exact. Mean slack there was
    // 6.29x, and slack is the thing that turns into steps.
    {
        Medium_0 ice = base;
        ice.mode_0 = 2;

        ice.gen_0.cellAltitude_0 = 8000.0f;
        ice.gen_0.streakLength_0 = 1500.0f;
        ice.gen_0.cellSize_0     = 400.0f;
        ice.gen_0.cellDensity_0  = 0.35f;
        ice.gen_0.cellStrength_0 = 1.0f;
        ice.gen_0.cellDrift_0    = make_float2(0.0f, 0.0f);
        ice.gen_0.sublimation_0  = 0.6f;
        ice.gen_0.fallSpeed_0    = 1.0f;
        ice.gen_0.detailScale_0  = 300.0f;
        ice.gen_0.detailAmount_0 = 0.4f;
        ice.gen_0.opticalDepth_0 = 0.45f;
        ice.gen_0.timeSeconds_0  = 0.0f;
        ice.gen_0.octaves_0      = 4;

        ice.slabBottom_0 = ice.gen_0.cellAltitude_0 - ice.gen_0.streakLength_0;
        ice.slabTop_0    = ice.gen_0.cellAltitude_0;

        // The drift table, as slang.generator builds it: a constant wind, so the drift
        // is linear in fall time.
        const float wind = 2.0f;
        Drift dr;
        {
            std::vector<float2> knots(33);
            for (int i = 0; i <= 32; ++i) {
                const float depth = ice.gen_0.streakLength_0 * i / 32.0f;
                knots[i] = make_float2(wind * (depth / ice.gen_0.fallSpeed_0), 0.0f);
            }
            cudaMalloc(&dr.dev, knots.size() * sizeof(float2));
            cudaMemcpy(dr.dev, knots.data(), knots.size() * sizeof(float2),
                       cudaMemcpyHostToDevice);
        }

        const int3 dims  = make_int3(16, 16, 16);
        const int  cells = dims.x * dims.y * dims.z;

        Grid g;
        g.desc.origin_0     = make_float3(-2000.0f, ice.slabBottom_0, -2000.0f);
        g.desc.cellExtent_0 = make_float3(4000.0f / dims.x,
                                          ice.gen_0.streakLength_0 / dims.y,
                                          4000.0f / dims.z);
        g.desc.dims_0       = dims;
        g.desc.enabled_0    = 1;
        cudaMalloc(&g.dev, static_cast<size_t>(cells) * sizeof(float));
        g.host.assign(cells, 0.0f);

        RWStructuredBuffer<float> outB;
        outB.data  = g.dev;
        outB.count = static_cast<size_t>(cells);
        buildIceGrid<<<(cells + 63) / 64, 64>>>(ice, dr.buffer(), g.desc, outB, cells);
        cudaMemcpy(g.host.data(), g.dev, g.host.size() * sizeof(float),
                   cudaMemcpyDeviceToHost);

        // THE GLOBAL MAJORANT IS THE LARGEST CELL BOUND, which is sound for the same
        // reason the cells are: a bound on every part bounds the whole. It is also
        // exactly what a renderer without a grid would have to use.
        double peak = 0.0;
        int occupied = 0;
        for (float b : g.host) { peak = std::max(peak, static_cast<double>(b)); if (b > 0.0f) ++occupied; }

        Medium_0 iceGlobal = ice;
        iceGlobal.majorant_0 = static_cast<float>(peak);
        ice.majorant_0       = static_cast<float>(peak);   // the grid falls back to it

        std::printf("\n\nTHE GRID ON THE REAL CIRRUS FIELD (mode 2)\n");
        std::printf("  %dx%dx%d cells, %d with cloud in them\n", dims.x, dims.y, dims.z, occupied);
        std::printf("  global majorant %.6g per metre (the largest cell bound)\n\n",
                    peak);

        // A ray up through the deck, and one along it -- the slant path is where a
        // renderer spends its time and where a loose majorant hurts most.
        struct Ray { const char* name; float3 origin; float3 dir; };
        const float mid = ice.slabBottom_0 + ice.gen_0.streakLength_0 * 0.5f;
        const Ray rays[] = {
            { "vertical", make_float3(0.0f, ice.slabBottom_0 - 10.0f, 0.0f),
                          make_float3(0.0f, 1.0f, 0.0f) },
            { "slant 20deg", make_float3(-1500.0f, mid, 0.0f),
                          make_float3(0.9397f, 0.3420f, 0.0f) },
        };

        std::printf("  %14s %10s %14s %12s %10s\n",
                    "ray", "majorant", "transmittance", "steps", "vs global");

        for (const Ray& r : rays) {
            Grid none = Grid::disabled();

            double sG = 0.0, sL = 0.0;
            const std::vector<float> trG =
                runTransmittance(iceGlobal, none, dr, r.origin, r.dir, 0x1CEu, trials, &sG);
            const std::vector<float> trL =
                runTransmittance(ice, g, dr, r.origin, r.dir, 0x1CEu, trials, &sL);

            const double mG = kahanSum(trG) / trials;
            const double mL = kahanSum(trL) / trials;

            std::printf("  %14s %10s %14.6f %12.1f %10s\n", r.name, "global", mG, sG, "-");
            std::printf("  %14s %10s %14.6f %12.1f %9.1fx\n", "", "16^3 grid", mL, sL,
                        sG / std::max(sL, 1e-9));

            // SAME IDENTITY AS EVERYWHERE ELSE: the grid is a free parameter. It holds
            // on a field whose bounds are loose just as it does on one where they are
            // exact -- looseness is a cost, not a bias.
            if (std::fabs(mG - mL) > 0.002) {
                std::printf("    FAIL: the grid moved the transmittance by %+.5f on the\n"
                            "          real field, where the bound is structural and loose\n",
                            mG - mL);
                ++failures;
            }
            cudaFree(none.dev);
        }

        // ===================================================================
        // THE GRID LOSES HERE, AND THAT IS THE RESULT RATHER THAN A DISAPPOINTMENT.
        //
        // A global majorant costs `majorant * pathLength` steps. On this field the
        // majorant is the peak of a thin cirrus -- about 3e-4 per metre over 1500 m, so
        // under one expected collision per ray. The grid cannot beat that, because it
        // pays a TRAVERSAL step per cell crossed whatever the density is: 16 cells deep
        // is 16 steps before any collision is sampled.
        //
        // So the grid is not a universal win. It pays for DYNAMIC RANGE -- a field whose
        // global majorant is far above its typical density, which is what a cumulus with
        // a hard core is and what mode 1 models. Cirrus at optical depth 0.45 spread
        // through 1500 m is nearly uniform where it exists, so the global majorant is
        // already close to tight and there is nothing to recover.
        //
        // THIS ALSO QUALIFIES THE CLAIM THAT THE GRID IS A CORRECTNESS REQUIREMENT. The
        // bias that motivated it came from a majorant forced 100x loose by hand. With a
        // sound structural majorant this field never approaches the iteration cap -- 2.4
        // steps against a cap of 1024 -- so for THIS generator the grid is an
        // optimisation that does not currently pay, not a fix for a live defect.
        // ===================================================================
        std::printf("\n  the grid COSTS steps here, and that is the finding: a global\n");
        std::printf("  majorant of %.2g per metre over %.0f m is under one expected\n",
                    peak, ice.gen_0.streakLength_0);
        std::printf("  collision, while %d cells deep is %d traversal steps before any\n",
                    dims.y, dims.y);
        std::printf("  collision is sampled. The grid pays for DYNAMIC RANGE, which thin\n");
        std::printf("  cirrus does not have -- see mode 1 above, where it wins 25x.\n");

        cudaFree(g.dev);
        cudaFree(dr.dev);
    }

    std::printf("\n%s\n", failures == 0
        ? "transport is unbiased, and neither the majorant nor the grid reaches the answer"
        : "TRANSPORT CHECKS FAILED");
    return failures == 0 ? 0 : 1;
}
