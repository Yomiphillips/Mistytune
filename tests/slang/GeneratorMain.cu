// The ice generator: does its optical-depth parameter mean optical depth?
//
// ===========================================================================
// THE CLAIM BEING TESTED IS THE PROTOTYPE'S OWN, AND IT IS WORTH TESTING BECAUSE IT
// IS THE ONE THAT MAKES THE PARAMETER CHECKABLE AGAINST THE LITERATURE.
//
// iceDensity divides by the streak length so that "a vertical path through the
// thickest part of a streak integrates to roughly the value on the slider". Cirrus
// has a MEASURED optical depth of about 0.1 to 0.7, so a parameter that agrees with
// the literature can be checked against it, while one that happens to look right at
// 0.45 because of a hidden factor cannot.
//
// THE SHEAR SWEEP WAS NOT PLANNED; THE FIRST RUN FORCED IT.
//
// The normalisation divides by the streak LENGTH, which is a VERTICAL extent -- and a
// vertical path only stays inside one streak while the streak is roughly vertical. A
// fallstreak is not. At 8 m/s of wind against a 1 m/s fall speed a parcel drifts 12 km
// sideways over 1.5 km of fall, so a vertical column crosses many streaks and spends
// most of its length in the clear lanes between them.
//
// So the claim is a LOW-SHEAR claim. This measures where it holds and how it decays,
// rather than asserting it everywhere and failing for something that is not a bug.
//
// THE SECOND THING MEASURED IS THE MAJORANT. slang.transport proved the tracker is
// unbiased for any majorant above the true maximum density and biased below it.
// Nobody had the true maximum. This reports it.
// ===========================================================================

#include <cstdio>
#include <cmath>
#include <vector>
#include <algorithm>
#include <limits>

#include <cuda_runtime.h>

// The host majorant, checked here against the kernel own field. src/engine/ is
// host-only C++ with no GPU header in it, which is exactly why it can be linked
// into a test that also holds a kernel.
#include "IceField.h"

#include "Generator.cu"

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

// A constant wind, so the drift is linear in fall time. The prototype uploads a
// prefix integral of wind over fall speed; this is that integral for the simplest
// wind there is.
std::vector<float2> buildDrift(float windSpeed, float fallSpeed, float streakLength) {
    std::vector<float2> disp(33);
    for (int i = 0; i <= 32; ++i) {
        const float depth = streakLength * static_cast<float>(i) / 32.0f;
        const float t = depth / fallSpeed;
        disp[i] = make_float2(windSpeed * t, 0.0f);
    }
    return disp;
}

} // namespace

int main() {
    int deviceCount = 0;
    if (cudaGetDeviceCount(&deviceCount) != cudaSuccess || deviceCount == 0) {
        std::printf("no CUDA device -- skipping (this test needs a GPU)\n");
        return 0;
    }

    int failures = 0;

    GeneratorInput_0 g;
    g.cellAltitude_0 = 8000.0f;
    g.streakLength_0 = 1500.0f;
    g.cellSize_0     = 400.0f;
    g.cellDensity_0  = 0.35f;
    g.cellStrength_0 = 1.0f;
    g.cellDrift_0    = make_float2(0.0f, 0.0f);
    g.sublimation_0  = 0.6f;
    g.fallSpeed_0    = 1.0f;
    g.detailScale_0  = 300.0f;
    g.detailAmount_0 = 0.4f;
    g.opticalDepth_0 = 0.45f;   // mid-range for cirrus
    g.timeSeconds_0  = 0.0f;
    g.octaves_0      = 4;

    float2* dDrift = nullptr;
    cudaMalloc(&dDrift, 33 * sizeof(float2));

    StructuredBuffer<float2> sDrift;
    sDrift.data  = dDrift;
    sDrift.count = 33;

    const int   samplesPerColumn = 2048;
    const int   columnsPerSide   = 24;
    const float extent           = 4000.0f;
    const int   totalColumns     = columnsPerSide * columnsPerSide;

    float* dCol = nullptr;
    cudaMalloc(&dCol, samplesPerColumn * sizeof(float));

    RWStructuredBuffer<float> sCol;
    sCol.data  = dCol;
    sCol.count = static_cast<size_t>(samplesPerColumn);

    std::vector<float> column(samplesPerColumn);

    auto sweepColumns = [&](GeneratorInput_0 gg, float wind,
                            double& maxTau, double& meanTau, int& occupied) {
        const std::vector<float2> d = buildDrift(wind, gg.fallSpeed_0, gg.streakLength_0);
        cudaMemcpy(dDrift, d.data(), d.size() * sizeof(float2), cudaMemcpyHostToDevice);

        const float dz = gg.streakLength_0 / samplesPerColumn;
        maxTau = 0.0;
        meanTau = 0.0;
        occupied = 0;

        for (int iy = 0; iy < columnsPerSide; ++iy) {
            for (int ix = 0; ix < columnsPerSide; ++ix) {
                const float u = (static_cast<float>(ix) + 0.5f) / columnsPerSide * extent - extent * 0.5f;
                const float v = (static_cast<float>(iy) + 0.5f) / columnsPerSide * extent - extent * 0.5f;

                densityColumn<<<(samplesPerColumn + 63) / 64, 64>>>(
                    gg, sDrift, make_float2(u, v), sCol, samplesPerColumn);
                cudaMemcpy(column.data(), dCol, column.size() * sizeof(float),
                           cudaMemcpyDeviceToHost);

                const double tau = kahanSum(column) * dz;
                meanTau += tau;
                if (tau > maxTau) maxTau = tau;
                if (tau > 0.01) ++occupied;
            }
        }
        meanTau /= totalColumns;
    };

    // -----------------------------------------------------------------------
    // 1. Optical depth down many columns, swept across wind shear
    // -----------------------------------------------------------------------
    std::printf("Optical depth of a vertical path, %d columns over %.0f m\n",
                totalColumns, static_cast<double>(extent));
    std::printf("  parameter %.4f, fall speed %.1f m/s\n\n",
                static_cast<double>(g.opticalDepth_0),
                static_cast<double>(g.fallSpeed_0));
    std::printf("  %8s %8s %12s %12s %10s\n",
                "wind", "shear", "thickest", "mean", "occupied");

    double tauNoShear = 0.0;
    const float winds[] = { 0.0f, 0.5f, 1.0f, 2.0f, 4.0f, 8.0f };
    for (float w : winds) {
        double maxTau = 0.0, meanTau = 0.0;
        int occ = 0;
        sweepColumns(g, w, maxTau, meanTau, occ);
        if (w == 0.0f) tauNoShear = maxTau;

        std::printf("  %8.1f %8.1f %12.4f %12.4f %9.0f%%\n",
                    static_cast<double>(w),
                    static_cast<double>(w / g.fallSpeed_0),
                    maxTau, meanTau, 100.0 * occ / totalColumns);
    }

    std::printf("\n  At zero shear a streak is vertical, which is where the\n");
    std::printf("  normalisation's claim applies.\n");

    // ASSERTED ONLY WHERE THE CLAIM IS MADE. A factor of two, because "roughly" is
    // the claim and the thickest column found depends on where the sampling grid
    // lands relative to a cell centre. It still catches a normalisation out by 10x,
    // or by the streak length.
    if (tauNoShear < 0.5 * g.opticalDepth_0 || tauNoShear > 2.0 * g.opticalDepth_0) {
        std::printf("    FAIL: at zero shear the thickest path is %.3f against a\n",
                    tauNoShear);
        std::printf("          parameter of %.3f -- the slider does not mean optical depth\n",
                    static_cast<double>(g.opticalDepth_0));
        ++failures;
    }

    // -----------------------------------------------------------------------
    // 2. Independence from streak length
    // -----------------------------------------------------------------------
    //
    // The normalisation exists so the slider keeps its meaning when the streak length
    // changes, instead of the cloud thickening every time the streaks get longer.
    // That is a separate claim from the magnitude, and a separate way to be wrong.
    {
        GeneratorInput_0 g2 = g;
        g2.streakLength_0 = 3000.0f;

        double maxTau2 = 0.0, meanTau2 = 0.0;
        int occ2 = 0;
        sweepColumns(g2, 0.0f, maxTau2, meanTau2, occ2);

        std::printf("\nStreak length doubled, no shear (1500 m -> 3000 m)\n");
        std::printf("  thickest column  %.4f  (was %.4f)\n", maxTau2, tauNoShear);

        // Not equality: sublimation is per kilometre, so a longer streak really does
        // sublime more of itself away. What must NOT happen is proportionality to
        // the length, which is what dropping the normalisation would give.
        if (maxTau2 > 1.5 * tauNoShear) {
            std::printf("    FAIL: the cloud thickened by %.2fx when the streaks got\n",
                        maxTau2 / tauNoShear);
            std::printf("          longer -- the streak-length normalisation is gone\n");
            ++failures;
        }
    }

    cudaFree(dCol);

    // -----------------------------------------------------------------------
    // 2b. IS THE DOMAIN MEAN CONSERVED UNDER DISPLACEMENT?
    // -----------------------------------------------------------------------
    //
    // THIS EXISTS TO SETTLE A NUMBER BEFORE A DESIGN DECISION IS TAKEN ON IT.
    //
    // The shear sweep above shows the thickest column falling about 7x while occupancy
    // rises from 23% to 61% -- the same ice spread over more columns. That suggests the
    // DOMAIN MEAN should be conserved, and in the 4000 m sweep it was not: it fell about
    // 1.9x. PROGRESS.md records that residual as unexplained, and a parameter
    // calibration built on the domain mean would quietly absorb it, bug or not.
    //
    // WHY IT SHOULD BE CONSERVED. Wind enters iceDensity only through
    // `source = p.xz - driftAt(depth)`: a pure horizontal DISPLACEMENT of where the cell
    // field is sampled. Sublimation, head, tail and the streak-length normalisation all
    // key off vertical depth, which the wind does not change. Displacing a statistically
    // homogeneous field cannot change its mean, so any decay is a measurement artefact
    // or a bug.
    //
    // WHY THE 4000 m SWEEP COULD NOT SEE THAT. The cell grid spacing is
    // cellSize * kCellSpacing = 880 m, so a 4000 m window holds about 4.5 cells per axis
    // -- roughly 20 cells, of which about a third are occupied. A mean over ~7 cells is
    // dominated by which ones happen to be in frame. Worse, the drift reaches 12 km at
    // 8 m/s, so each wind speed samples a DIFFERENT patch of the field, and the
    // comparison is between small independent samples rather than between the same
    // region displaced.
    //
    // So this measures over 40 km -- about 45 cells per axis, ~2000 cells -- using
    // densityPlane, which integrates a whole plane per launch instead of a column.
    {
        const float wideExtent = 40000.0f;
        const int   side       = 512;
        const int   depths     = 64;

        float* dPlane = nullptr;
        cudaMalloc(&dPlane, static_cast<size_t>(side) * side * sizeof(float));

        RWStructuredBuffer<float> sPlane;
        sPlane.data  = dPlane;
        sPlane.count = static_cast<size_t>(side) * side;

        std::vector<float> plane(static_cast<size_t>(side) * side);

        auto domainMeanTau = [&](float wind) {
            const std::vector<float2> d = buildDrift(wind, g.fallSpeed_0, g.streakLength_0);
            cudaMemcpy(dDrift, d.data(), d.size() * sizeof(float2), cudaMemcpyHostToDevice);

            const float dz = g.streakLength_0 / depths;
            double tau = 0.0;

            for (int k = 0; k < depths; ++k) {
                const float depth = g.streakLength_0 * (static_cast<float>(k) + 0.5f) / depths;

                dim3 block(8, 8);
                dim3 grid((side + 7) / 8, (side + 7) / 8);
                densityPlane<<<grid, block>>>(g, sDrift, depth, wideExtent, sPlane, side);
                cudaMemcpy(plane.data(), dPlane, plane.size() * sizeof(float),
                           cudaMemcpyDeviceToHost);

                tau += (kahanSum(plane) / plane.size()) * dz;
            }
            return tau;
        };

        std::printf("\nDomain-mean vertical optical depth over %.0f km, swept across wind\n",
                    static_cast<double>(wideExtent) / 1000.0);
        std::printf("  a pure horizontal displacement cannot change this\n\n");
        std::printf("  %8s %16s %10s\n", "wind", "mean tau", "vs wind 0");

        const double base = domainMeanTau(0.0f);
        double worst = 1.0;

        const float winds2[] = { 0.0f, 1.0f, 4.0f, 8.0f };
        for (float w : winds2) {
            const double m = (w == 0.0f) ? base : domainMeanTau(w);
            const double ratio = m / base;
            std::printf("  %8.1f %16.6f %9.3fx\n", static_cast<double>(w), m, ratio);
            worst = std::max(worst, std::max(ratio, 1.0 / ratio));
        }

        cudaFree(dPlane);

        // 10%: displacement of a homogeneous field is exact, so the only slack needed is
        // the finite window and the 512x512 x 64 quadrature. The 1.9x this is testing
        // would fail it by a mile.
        if (worst > 1.10) {
            std::printf("    FAIL: the domain mean moved by %.2fx under a pure horizontal\n"
                        "          displacement. Wind reaches iceDensity ONLY through\n"
                        "          `source = p.xz - driftAt(depth)`, so this is a bug in the\n"
                        "          generator, not a property of shear -- and calibrating the\n"
                        "          optical-depth parameter on the domain mean would hide it.\n",
                        worst);
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 2c. HOW BADLY CAN A SAMPLED MAJORANT BOUND MISS?
    // -----------------------------------------------------------------------
    //
    // The majorant grid in slang.transport builds its bounds in closed form, which is
    // what makes every result there falsifiable -- a bound below the true density biases
    // delta tracking silently, and a bound that is only probably right makes the grid
    // unfalsifiable. `iceDensity` has no closed-form maximum over a box, so its bounds
    // must be SAMPLED, and a sampled maximum can always miss a peak between samples.
    //
    // THIS MEASURES THE MISS SO A SAFETY FACTOR CAN BE A NUMBER RATHER THAN A FEELING.
    // Coarse sampling against a much finer reference, per cell, reporting the worst
    // ratio over all cells -- the worst case is what a majorant has to survive, not the
    // average.
    //
    // WHAT THIS CANNOT DO, STATED PLAINLY: the fine sample is itself a sample. It
    // bounds the miss RELATIVE TO A FINER SAMPLE, not relative to the true supremum,
    // which for a field with fbm detail is not available at any resolution. So the
    // factor this justifies is a floor on what is needed, never a proof of sufficiency,
    // and the safety margin should sit well above it.
    {
        const int3  dims  = make_int3(8, 8, 8);
        const int   cells = dims.x * dims.y * dims.z;
        const int   refSamples = 24;    // the reference, 13824 points per cell

        const float3 gridLo = make_float3(-2000.0f,
                                          g.cellAltitude_0 - g.streakLength_0,
                                          -2000.0f);
        const float3 cellSize = make_float3(4000.0f / dims.x,
                                            g.streakLength_0 / dims.y,
                                            4000.0f / dims.z);

        const std::vector<float2> drift = buildDrift(2.0f, g.fallSpeed_0, g.streakLength_0);
        cudaMemcpy(dDrift, drift.data(), drift.size() * sizeof(float2), cudaMemcpyHostToDevice);

        float* dMax = nullptr;
        cudaMalloc(&dMax, static_cast<size_t>(cells) * sizeof(float));
        RWStructuredBuffer<float> sMax;
        sMax.data  = dMax;
        sMax.count = static_cast<size_t>(cells);

        auto cellMaxima = [&](int n) {
            cellMax<<<(cells + 63) / 64, 64>>>(g, sDrift, gridLo, cellSize, dims,
                                               n, sMax, cells);
            std::vector<float> out(cells);
            cudaMemcpy(out.data(), dMax, out.size() * sizeof(float), cudaMemcpyDeviceToHost);
            return out;
        };

        const std::vector<float> reference = cellMaxima(refSamples);

        // Only cells with something in them can be missed in a way that matters: an
        // empty cell's bound is 0 and stays 0.
        int occupiedCells = 0;
        double refPeak = 0.0;
        for (float v : reference) {
            if (v > 0.0f) ++occupiedCells;
            refPeak = std::max(refPeak, static_cast<double>(v));
        }

        std::printf("\nSampled majorant bounds: how far under the reference do they land?\n");
        std::printf("  %dx%dx%d cells, reference %d^3 samples each, %d cells occupied\n\n",
                    dims.x, dims.y, dims.z, refSamples, occupiedCells);
        std::printf("  %10s %14s %14s %12s\n",
                    "samples", "worst miss", "mean miss", "cells under");

        double worstOverall = 1.0;
        const int coarseSweep[] = { 2, 3, 4, 6, 8 };
        for (int n : coarseSweep) {
            const std::vector<float> coarse = cellMaxima(n);

            double worst = 1.0, sum = 0.0;
            int under = 0, counted = 0;
            for (int i = 0; i < cells; ++i) {
                if (reference[i] <= 0.0f) continue;
                // A coarse pass that found nothing at all in an occupied cell is the
                // worst case there is, and a ratio cannot express it.
                const double ratio = (coarse[i] > 0.0f)
                    ? static_cast<double>(reference[i]) / coarse[i]
                    : std::numeric_limits<double>::infinity();
                worst = std::max(worst, ratio);
                if (std::isfinite(ratio)) { sum += ratio; ++counted; }
                if (coarse[i] < reference[i]) ++under;
            }
            worstOverall = std::max(worstOverall, worst);

            std::printf("  %10d %14.3f %14.3f %11d%%\n",
                        n, worst, counted ? sum / counted : 0.0,
                        occupiedCells ? 100 * under / occupiedCells : 0);
        }

        std::printf("\n  peak density in the reference: %.6g per metre\n", refPeak);

        // THE VERDICT ON SAMPLING, ASSERTED SO IT CANNOT QUIETLY STOP BEING TRUE.
        //
        // An infinite worst-case miss means a coarse pass found NOTHING in a cell the
        // reference says is occupied. TransportLib treats a zero bound as proof that
        // there is nothing to collide with and skips the cell without drawing a random
        // number, so such a bound does not make the cloud thin -- it deletes it.
        //
        // This is recorded as a measurement rather than a failure because the code under
        // test is fine: it is the CONSTRUCTION that is unsound, and the structural bound
        // below is the answer. If this ever stops being infinite the field has changed
        // character and the decision is worth revisiting, which is why it is checked.
        if (worstOverall < 1e30) {
            std::printf("    NOTE: sampling no longer misses a whole cell. The reason this\n"
                        "          generator uses a structural bound was that it did --\n"
                        "          revisit that decision.\n");
        } else {
            std::printf("  sampling misses whole cells at every resolution, so a sampled\n");
            std::printf("  bound is not merely loose -- it can be ZERO where there is cloud,\n");
            std::printf("  which deletes the cell rather than thinning it.\n");
        }

        // -------------------------------------------------------------------
        // The structural bound must DOMINATE the sampled maximum, in every cell
        // -------------------------------------------------------------------
        //
        // This is the check that makes the majorant grid usable on this generator. The
        // bound is built from the factors of iceDensity rather than from samples of it,
        // so it is sound by construction -- and this asserts the inequality against the
        // real field rather than trusting the derivation.
        //
        // IT IS AN INEQUALITY, NOT A COMPARISON OF TWO IMPLEMENTATIONS. The bound is a
        // different computation from the density, so this is not two transcriptions
        // agreeing with each other; it is a claim about the density being checked
        // against the density.
        {
            float* dBound = nullptr;
            cudaMalloc(&dBound, static_cast<size_t>(cells) * sizeof(float));
            RWStructuredBuffer<float> sBound;
            sBound.data  = dBound;
            sBound.count = static_cast<size_t>(cells);

            cellBound<<<(cells + 63) / 64, 64>>>(g, sDrift, gridLo, cellSize, dims,
                                                 sBound, cells);
            std::vector<float> bound(cells);
            cudaMemcpy(bound.data(), dBound, bound.size() * sizeof(float),
                       cudaMemcpyDeviceToHost);
            cudaFree(dBound);

            int violations = 0;
            double worstViolation = 0.0;
            double sumSlack = 0.0, worstSlack = 0.0;
            int counted = 0, emptyButBounded = 0;

            for (int i = 0; i < cells; ++i) {
                if (bound[i] < reference[i]) {
                    ++violations;
                    worstViolation = std::max(worstViolation,
                        static_cast<double>(reference[i]) / std::max(bound[i], 1e-30f));
                }
                if (reference[i] > 0.0f) {
                    const double slack = static_cast<double>(bound[i]) / reference[i];
                    sumSlack += slack;
                    worstSlack = std::max(worstSlack, slack);
                    ++counted;
                } else if (bound[i] > 0.0f) {
                    ++emptyButBounded;
                }
            }

            std::printf("\nStructural bound vs the sampled maximum, all %d cells\n", cells);
            std::printf("  cells where the bound is BELOW the field : %d\n", violations);
            std::printf("  slack where there is cloud   mean %.2fx   worst %.2fx\n",
                        counted ? sumSlack / counted : 0.0, worstSlack);
            std::printf("  cells the sample found empty but the bound covers : %d\n",
                        emptyButBounded);

            if (violations > 0) {
                std::printf("    FAIL: the structural bound is not a bound -- %d cells, worst\n"
                            "          by %.2fx. Delta tracking's acceptance ratio exceeds 1\n"
                            "          wherever that happens and the estimator is silently\n"
                            "          biased, which is the whole failure this construction\n"
                            "          exists to rule out.\n", violations, worstViolation);
                ++failures;
            }

            // Slack is the cost, and it is reported rather than bounded tightly: the
            // factors do not all peak at the same point, so a product of maxima is
            // necessarily loose. slang.transport shows what looseness costs in steps.
            if (counted == 0) {
                std::printf("    FAIL: no occupied cells, so this proved nothing\n");
                ++failures;
            }
        }

        cudaFree(dMax);
    }

    // -----------------------------------------------------------------------
    // 3. The peak density, which is what a majorant must cover
    // -----------------------------------------------------------------------
    {
        const std::vector<float2> d = buildDrift(0.0f, g.fallSpeed_0, g.streakLength_0);
        cudaMemcpy(dDrift, d.data(), d.size() * sizeof(float2), cudaMemcpyHostToDevice);

        const int side = 512;
        float* dPlane = nullptr;
        cudaMalloc(&dPlane, static_cast<size_t>(side) * side * sizeof(float));

        RWStructuredBuffer<float> sPlane;
        sPlane.data  = dPlane;
        sPlane.count = static_cast<size_t>(side) * side;

        std::vector<float> plane(static_cast<size_t>(side) * side);
        double globalMax = 0.0, bestDepth = 0.0;

        for (int k = 0; k < 16; ++k) {
            const float depth = g.streakLength_0 * (static_cast<float>(k) + 0.5f) / 16.0f;

            dim3 block(8, 8);
            dim3 grid((side + 7) / 8, (side + 7) / 8);
            densityPlane<<<grid, block>>>(g, sDrift, depth, extent, sPlane, side);
            cudaMemcpy(plane.data(), dPlane, plane.size() * sizeof(float),
                       cudaMemcpyDeviceToHost);

            const double hi = *std::max_element(plane.begin(), plane.end());
            if (hi > globalMax) { globalMax = hi; bestDepth = depth; }

            // NEGATIVE DENSITY IS NOT A ROUNDING QUESTION. The detail term is
            // 1 + amount * fbm * 1.8, which goes negative for amount above about
            // 0.55 -- and a negative sigma makes the tracker's acceptance
            // probability negative, which silently never scatters.
            const double lo = *std::min_element(plane.begin(), plane.end());
            if (lo < 0.0) {
                std::printf("    FAIL: negative density %.6g at depth %.0f m\n",
                            lo, static_cast<double>(depth));
                ++failures;
            }
        }
        cudaFree(dPlane);

        std::printf("\nPeak density over 16 depths x %dx%d samples\n", side, side);
        std::printf("  maximum %.6g per metre, at depth %.0f m\n", globalMax, bestDepth);
        std::printf("  a majorant must be at least this, and slang.transport shows\n");
        std::printf("  what it costs for one to be much more\n");

        if (!(globalMax > 0.0)) {
            std::printf("    FAIL: the field is empty everywhere\n");
            ++failures;
        }

        // -------------------------------------------------------------------
        // ...AND THE HOST MAJORANT IS WHAT ACTUALLY HAS TO COVER IT
        // -------------------------------------------------------------------
        //
        // THE CHECK THAT JOINS THE TWO TIERS, and neither one alone can make it.
        //
        // src/engine/IceField.h derives the majorant the shipping renderer uses,
        // structurally -- a product of per-factor maxima, argued rather than
        // sampled -- and tests/unit/ checks that the arithmetic is what it claims
        // to be. What tests/unit/ cannot check is whether the CLAIM IS TRUE,
        // because the claim is about iceDensity(), which is Slang and needs a GPU.
        //
        // This is where the two meet: the host bound against the kernel own
        // sampled peak, for the same parameters.
        //
        // WHICH DIRECTION MATTERS. Below the peak is not a slow render, it is a
        // WRONG one -- the acceptance probability in the tracker exceeds one, the
        // comparison accepts unconditionally, and the ray scatters at the first
        // collision it tests rather than at the one it should have. The picture is
        // quietly too thin and nothing says so. Above the peak merely costs steps,
        // and slang.transport measures what that costs.
        //
        // THE SAMPLED PEAK IS A FLOOR, NOT THE TRUTH. Sixteen depths by 512x512
        // will miss the real maximum between samples, so this can only catch a
        // bound that is badly wrong -- which is the useful case. It cannot certify
        // one that is marginally wrong, and the structural argument is what covers
        // that. Neither is redundant.
        plugin::cloud::IceParams ice;
        ice.cellStrength = g.cellStrength_0;
        ice.detailAmount = g.detailAmount_0;
        ice.opticalDepth = g.opticalDepth_0;
        ice.streakLength = g.streakLength_0;

        // THE RATE MATTERS NOW AND IT DID NOT BEFORE, which is a trap this line exists
        // to close. The old bound omitted sublimation entirely, so leaving IceParams at
        // its default 0.55 while the kernel ran at 0.6 was harmless. depthFactorBound()
        // reads it, and a host bound computed at a WEAKER rate than the field's is a
        // bound computed for a different field -- which is unsound in the one direction
        // that does not announce itself.
        ice.sublimationRate = g.sublimation_0;

        const double hostBound = static_cast<double>(plugin::cloud::iceMajorant(ice));

        std::printf("\n  host structural majorant %.6g per metre\n", hostBound);
        std::printf("  slack over the sampled peak: %.2fx\n",
                    globalMax > 0.0 ? hostBound / globalMax : 0.0);

        if (hostBound < globalMax) {
            std::printf("    FAIL: src/engine/IceField.h majorant is BELOW the field it\n"
                        "          is supposed to bound -- %.6g against a sampled peak of\n"
                        "          %.6g. Null-collision tracking is not merely slow with\n"
                        "          this, it is WRONG, and the render looks like a thinner\n"
                        "          cloud rather than like an error.\n",
                        hostBound, globalMax);
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 4. The cell-overlap bound, against the kernel's own cellField
    // -----------------------------------------------------------------------
    //
    // ===========================================================================
    // THE TRIPWIRE ON A THEOREM THAT LIVES IN A DIFFERENT LANGUAGE FROM WHAT IT IS
    // ABOUT.
    //
    // src/engine/IceField.h derives cellOverlapBound() from four constants it MIRRORS
    // from GeneratorLib.slang -- the grid pitch, the jitter width, and the two blob
    // edges. Nothing makes the two copies agree, and the failure of a drifted copy is a
    // majorant below the field: a cloud that renders quietly too thin.
    //
    // A NAME-AND-VALUE COMPARISON WOULD BE THE OBVIOUS TEST AND THE WEAKER ONE. It
    // checks that the copies match, which is not the claim. The claim is that the bound
    // holds -- so this runs the KERNEL's cellField and checks the host's number is above
    // everything it produces. A mirrored constant that drifts fails this; so does a
    // wrong derivation, which a value comparison would pass.
    //
    // cellDensity IS FORCED TO ONE, and that is what makes the test the worst case
    // rather than a typical one. The bound assumes every slot in the neighbourhood holds
    // a cell, because the occupancy is a hash the host cannot evaluate. At the default
    // 0.35 most slots are empty and the sampled peak would land far below the bound for
    // a reason that has nothing to do with whether the bound is correct.
    //
    // AND SAMPLING IS LEGITIMATE HERE, uniquely in this file: cellField has no fbm in
    // it. See the note over cellFieldPlane in Generator.slang.
    // ===========================================================================
    {
        GeneratorInput_0 cg = g;
        cg.cellDensity_0  = 1.0f;   // every slot occupied -- the case the bound assumes
        cg.cellStrength_0 = 1.0f;   // so the sampled maximum IS the overlap factor
        cg.cellDrift_0    = make_float2(0.0f, 0.0f);

        const int   side = 1024;
        const float spacing = cg.cellSize_0 * 2.2f;   // kCellSpacing, one grid pitch

        // FOUR PITCHES ACROSS, OFFSET OFF THE LATTICE. The field is periodic in nothing
        // -- the jitter comes from a hash of the slot -- so a few pitches sample many
        // different slot neighbourhoods. The offset is so the sample grid does not land
        // on the slot lattice, where the corners that matter are.
        const float span = spacing * 4.0f;

        float* dPlane = nullptr;
        cudaMalloc(&dPlane, static_cast<size_t>(side) * side * sizeof(float));

        RWStructuredBuffer<float> sPlane;
        sPlane.data  = dPlane;
        sPlane.count = static_cast<size_t>(side) * side;

        std::vector<float> plane(static_cast<size_t>(side) * side);

        double sampledMax = 0.0;

        // MANY PATCHES OF THE PLANE, so the answer is not one neighbourhood's luck --
        // and so the note below about how rare the worst jitter is has a number under it.
        // 7 x 7 patches of 4 pitches each is 784 slot neighbourhoods at 1024x1024 apiece.
        int patches = 0;
        for (int py = -3; py <= 3; ++py)
        for (int px = -3; px <= 3; ++px) {
            ++patches;
            const float2 origin = make_float2(static_cast<float>(px) * span + 0.137f * spacing,
                                              static_cast<float>(py) * span + 0.291f * spacing);

            dim3 block(8, 8);
            dim3 grid((side + 7) / 8, (side + 7) / 8);
            cellFieldPlane<<<grid, block>>>(cg, origin, span, sPlane, side);
            cudaMemcpy(plane.data(), dPlane, plane.size() * sizeof(float),
                       cudaMemcpyDeviceToHost);

            sampledMax = std::max(sampledMax,
                                  static_cast<double>(*std::max_element(plane.begin(),
                                                                        plane.end())));
        }
        cudaFree(dPlane);

        const double hostOverlap = static_cast<double>(plugin::cloud::cellOverlapBound());

        std::printf("\ncellField with every slot occupied, %d patches x %dx%d\n",
                    patches, side, side);
        std::printf("  kernel sampled maximum      %.4f\n", sampledMax);
        std::printf("  host cellOverlapBound()     %.4f\n", hostOverlap);
        std::printf("  the trivial nine-slot bound 9.0000\n");
        std::printf("  slack %.3fx, against 9/%.4f = %.2fx before the derivation\n",
                    sampledMax > 0.0 ? hostOverlap / sampledMax : 0.0,
                    sampledMax, sampledMax > 0.0 ? 9.0 / sampledMax : 0.0);

        if (!(sampledMax > 0.0)) {
            std::printf("    FAIL: cellField is zero everywhere, so this proved nothing\n");
            ++failures;
        }

        // ---------------------------------------------------------------------
        // WHY THE SAMPLED MAXIMUM SITS WELL BELOW THE BOUND, AND WHY THAT IS NOT SLACK
        // TO BE REMOVED.
        //
        // MEASURED: 1.69 against a bound of 3.26, over 784 slot neighbourhoods.
        //
        // The bound is over every jitter the hash could produce. Reaching 3.26 needs all
        // four cells around one slot corner to have jittered TOWARDS it, and the jitter
        // is `hash22(o, 0u) - 0.5` -- fixed per slot, not free. Four independent draws
        // all landing in the same eighth of their square is about one neighbourhood in a
        // few thousand, so a sweep of a few hundred does not see it.
        //
        // IT IS STILL REACHED. There is no seed, and the sky is millions of slots wide,
        // so a configuration that is rare per neighbourhood is certain somewhere in the
        // frame -- and null-collision tracking is biased, not merely slow, at the one
        // place the majorant is under the field. So the bound covers the rare case by
        // construction and the sampled maximum is a FLOOR on the truth, exactly as the
        // peak-density sweep above is.
        //
        // WHICH SETS WHAT THIS CAN ASSERT. Soundness, in the direction that matters. And
        // that the four-slot derivation is still doing its job -- four blobs at a ceiling
        // of one each is 4, so a bound at or above 4 means the derivation has collapsed
        // back to the trivial nine and the 2.76x is gone. Both are guaranteed. "Close to
        // the sampled maximum" is not, and asserting it would be asserting that the rare
        // configuration never happens.
        // ---------------------------------------------------------------------
        if (hostOverlap < sampledMax) {
            std::printf("    FAIL: cellOverlapBound() is BELOW the kernel's own cellField\n"
                        "          -- %.4f against a sampled maximum of %.4f. Either a\n"
                        "          constant mirrored in src/engine/IceField.h has drifted\n"
                        "          from GeneratorLib.slang, or the four-slot derivation in\n"
                        "          that header is wrong. Both make the majorant too low,\n"
                        "          and a majorant that is too low renders a thinner cloud\n"
                        "          rather than an error.\n",
                        hostOverlap, sampledMax);
            ++failures;
        }

        // ---------------------------------------------------------------------
        // ...AND THE CONSTANTS THEMSELVES, EXACTLY, BECAUSE THE SWEEP ABOVE CANNOT CATCH
        // A SMALL DRIFT.
        //
        // MEASURED WHILE WRITING THIS CHECK: moving the host's kCellSpacing from 2.2 to
        // 2.6 -- an 18% error, far larger than a typo -- lowers cellOverlapBound() to
        // 2.96, which is STILL above the 1.77 the sweep finds. So the sweep passed and
        // the majorant was wrong. That is not a flaw in the sweep: it is the same
        // floor-not-truth limit the peak-density sweep has, because the worst jitter
        // configuration is rare and hundreds of neighbourhoods do not contain it.
        //
        // WHAT THE FOUR CONSTANTS ARE FOR. src/engine/IceField.h cannot include a .slang
        // file, so it mirrors kCellSpacing, kCellJitter and the two blob edges and
        // derives its bound from them. This reads the kernel's own copies back.
        // ---------------------------------------------------------------------
        {
            const int probeCount = 8;
            float* dProbe = nullptr;
            cudaMalloc(&dProbe, probeCount * sizeof(float));
            cudaMemset(dProbe, 0, probeCount * sizeof(float));

            RWStructuredBuffer<float> sProbe;
            sProbe.data  = dProbe;
            sProbe.count = static_cast<size_t>(probeCount);

            cellGeometry<<<1, 8>>>(sProbe, probeCount);

            std::vector<float> probe(probeCount);
            cudaMemcpy(probe.data(), dProbe, probe.size() * sizeof(float),
                       cudaMemcpyDeviceToHost);
            cudaFree(dProbe);

            struct Mirror { const char* name; double kernel; double host; };
            const Mirror mirrors[] = {
                { "kCellSpacing", probe[0], static_cast<double>(plugin::cloud::kCellSpacing) },
                { "kCellJitter",  probe[1], static_cast<double>(plugin::cloud::kCellJitter)  },
                { "kBlobFar",     probe[2], static_cast<double>(plugin::cloud::kBlobFar)     },
                { "kBlobNear",    probe[3], static_cast<double>(plugin::cloud::kBlobNear)    },
            };

            std::printf("\nthe four mirrored constants, kernel against host\n");
            for (const Mirror& m : mirrors) {
                const bool same = m.kernel == m.host;
                std::printf("  %-14s kernel %-10.6g host %-10.6g %s\n",
                            m.name, m.kernel, m.host, same ? "" : "  <-- DRIFTED");
                if (!same) {
                    std::printf("    FAIL: GeneratorLib.slang and src/engine/IceField.h\n"
                                "          disagree about %s. IceField.h derives its\n"
                                "          cell-overlap bound from this number, so the\n"
                                "          bound is now a theorem about a field that is not\n"
                                "          the one being rendered -- which means a majorant\n"
                                "          below the density, and a cloud that renders\n"
                                "          quietly too thin.\n", m.name);
                    ++failures;
                }
            }

            // AND THE DERIVED WORST CASE, DERIVED AND EVALUATED ENTIRELY IN THE KERNEL.
            //
            // Four blobs at the corner distance is the configuration the host's scan is
            // searching for. THE HOST CONTRIBUTES NOTHING TO IT BUT ITS ANSWER -- see the
            // note over cellGeometry for why a first version that passed the distance IN
            // could not fail, and was measured not failing -- so the host's number must
            // sit at that value: above it by no more than the Lipschitz slack its scan
            // adds, and never below it.
            const double kernelCorner   = static_cast<double>(probe[4]);
            const double cornerDistance = static_cast<double>(probe[5]);

            std::printf("  four blobs at the kernel's own corner distance %.5f cell-sizes\n",
                        cornerDistance);
            std::printf("    kernel arithmetic %.4f   host cellOverlapBound() %.4f\n",
                        kernelCorner, hostOverlap);

            if (hostOverlap < kernelCorner) {
                std::printf("    FAIL: cellOverlapBound() is %.4f, BELOW the %.4f the\n"
                            "          kernel's own blob gives for the configuration the\n"
                            "          bound is supposed to cover. The scan is missing its\n"
                            "          own worst case.\n", hostOverlap, kernelCorner);
                ++failures;
            }

            // 1% covers the 0.0054 of Lipschitz slack with room to spare, and is tight
            // enough that a fallback to the trivial nine cannot hide inside it.
            if (hostOverlap > kernelCorner * 1.01) {
                std::printf("    FAIL: cellOverlapBound() is %.4f against a worst case of\n"
                            "          %.4f, which is more slack than the scan's own\n"
                            "          Lipschitz margin allows. Either the scan searched\n"
                            "          the wrong square or it fell back to the trivial\n"
                            "          nine-slot bound.\n", hostOverlap, kernelCorner);
                ++failures;
            }
        }
    }




    cudaFree(dDrift);

    std::printf("\n%s\n", failures == 0
        ? "the generator is bounded, and its optical depth means optical depth"
        : "GENERATOR CHECKS FAILED");
    return failures == 0 ? 0 : 1;
}
