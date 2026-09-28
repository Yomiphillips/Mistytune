// The phase functions and their importance sampler, checked against physics.
//
// ===========================================================================
// THERE IS NOTHING TO DIFF AGAINST, SO THE TEST HAS TO BE THE PHYSICS.
//
// slang.skyParity could be bitwise, because Shading.h gave a target. The transport
// has no C++ twin -- its reference is a GLSL shader in a browser -- so a transcription
// error here cannot be caught by comparison. It has to be caught by the identities a
// correct phase function obeys, which is a stronger test anyway: it would also catch
// an error the prototype itself contains.
//
// TWO IDENTITIES, AND THE SECOND IS THE ONE THAT EARNS ITS KEEP.
//
//   1. A phase function integrates to 1 over the sphere. Quadrature, no sampling.
//
//   2. THE MEAN RETURNED WEIGHT IS THAT SAME INTEGRAL. samplePhaseDir returns
//      phase/pdf, and the expectation of phase/pdf over the pdf is exactly
//      integral(phase) -- so if the sampler draws from a distribution that is NOT
//      its stated pdf, this mean drifts off 1 while the quadrature above stays
//      perfect. It is the only check here that tests the SAMPLER rather than the
//      function, and a mismatched sampler and pdf is the single most common way to
//      get a volumetric renderer subtly, unfixably wrong.
//
// A biased sampler does not look broken. It looks like a cloud with the wrong
// silver lining, and no amount of extra samples converges it to the right answer.
// ===========================================================================

#include <cstdio>
#include <cmath>
#include <vector>

#include <cuda_runtime.h>

#include "Phase.cu"

namespace {

// Kahan, because this sums millions of terms spanning several orders of magnitude --
// a forward lobe is worth 15 per steradian against a background of 0.08, and a naive
// float sum loses the tail that carries most of the solid angle.
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

struct Result {
    double integral;
    double meanWeight;
    double maxWeight;
};

Result measure(float dropletDiameter, int useIce, unsigned seed, int quadN, int sampleN) {
    Result r{};

    // ---- 1. The integral, by quadrature over cos(theta) ----
    //
    // integral over the sphere = 2*pi * integral over mu in [-1,1], and the midpoint
    // rule on a uniform partition of mu is what the kernel generates.
    float* dEval = nullptr;
    cudaMalloc(&dEval, static_cast<size_t>(quadN) * sizeof(float));

    RWStructuredBuffer<float> sEval;
    sEval.data  = dEval;
    sEval.count = static_cast<size_t>(quadN);

    phaseEval<<<(quadN + 63) / 64, 64>>>(dropletDiameter, useIce, sEval, quadN);

    std::vector<float> eval(quadN);
    cudaMemcpy(eval.data(), dEval, eval.size() * sizeof(float), cudaMemcpyDeviceToHost);
    cudaFree(dEval);

    r.integral = kahanSum(eval) * (2.0 / quadN) * 2.0 * 3.14159265358979323846;

    // ---- 2. The sampler, by the mean of its own weight ----
    float *dCos = nullptr, *dW = nullptr;
    cudaMalloc(&dCos, static_cast<size_t>(sampleN) * sizeof(float));
    cudaMalloc(&dW,   static_cast<size_t>(sampleN) * sizeof(float));

    RWStructuredBuffer<float> sCos;
    sCos.data  = dCos;
    sCos.count = static_cast<size_t>(sampleN);

    RWStructuredBuffer<float> sW;
    sW.data  = dW;
    sW.count = static_cast<size_t>(sampleN);

    phaseSample<<<(sampleN + 63) / 64, 64>>>(dropletDiameter, useIce, sCos, sW, seed, sampleN);

    std::vector<float> weights(sampleN);
    cudaMemcpy(weights.data(), dW, weights.size() * sizeof(float), cudaMemcpyDeviceToHost);
    cudaFree(dCos);
    cudaFree(dW);

    r.meanWeight = kahanSum(weights) / sampleN;
    r.maxWeight  = 0.0;
    for (float w : weights) {
        if (static_cast<double>(w) > r.maxWeight) r.maxWeight = w;
    }

    return r;
}

} // namespace

int main() {
    int deviceCount = 0;
    if (cudaGetDeviceCount(&deviceCount) != cudaSuccess || deviceCount == 0) {
        std::printf("no CUDA device -- skipping (this test needs a GPU)\n");
        return 0;
    }

    const cudaError_t warm = cudaFree(nullptr);
    if (warm != cudaSuccess) {
        std::printf("FAIL: CUDA unavailable: %s\n", cudaGetErrorString(warm));
        return 1;
    }

    const int quadN   = 1 << 22;   // 4.2M quadrature points
    const int sampleN = 1 << 21;   // 2.1M sampled directions

    int failures = 0;

    // ---------------------------------------------------------------------
    // The liquid phase, across the droplet diameters the fit is valid for
    // ---------------------------------------------------------------------
    //
    // SWEPT RATHER THAN SPOT-CHECKED, because the Draine lobe's weight and alpha
    // both move sharply with diameter -- an error in the normalising divisor shows
    // at one end of the range and not the other.
    std::printf("Liquid (Jendersie-d'Eon), by droplet diameter:\n");
    std::printf("  %8s %12s %12s %12s\n", "microns", "integral", "mean weight", "max weight");

    const float diameters[] = { 5.0f, 8.0f, 12.0f, 20.0f, 35.0f, 50.0f };
    for (float d : diameters) {
        const Result r = measure(d, 0, 0x5eed1ce5u, quadN, sampleN);

        std::printf("  %8.1f %12.6f %12.6f %12.4f\n",
                    static_cast<double>(d), r.integral, r.meanWeight, r.maxWeight);

        // 1e-3 is quadrature error plus Monte Carlo noise at 2M samples, not a
        // tolerance for a wrong normalisation -- dropping the Draine divisor moves
        // this by tens of percent.
        if (std::fabs(r.integral - 1.0) > 1e-3) {
            std::printf("    FAIL: phase does not integrate to 1 over the sphere\n");
            ++failures;
        }
        if (std::fabs(r.meanWeight - 1.0) > 5e-3) {
            std::printf("    FAIL: mean sample weight is not the integral -- the pdf\n"
                        "          does not describe what samplePhaseDir draws\n");
            ++failures;
        }
        // The prototype predicts "around 1.8"; anything unbounded here is the
        // firefly mechanism its own comment describes.
        if (r.maxWeight > 3.0) {
            std::printf("    FAIL: sample weight is unbounded (%g) -- throughput will\n"
                        "          grow across bounces and the image will fill with fireflies\n",
                        r.maxWeight);
            ++failures;
        }
    }

    // ---------------------------------------------------------------------
    // The ice placeholder, MEASURED RATHER THAN ASSUMED
    // ---------------------------------------------------------------------
    //
    // phaseIce adds a 22-degree halo on top of an already-normalised mixture, so it
    // does NOT integrate to 1 and cannot be expected to. That is a known property of
    // the Phase 4 placeholder, and the useful thing is to know HOW MUCH energy it
    // invents -- a number nobody had, because the prototype never measured it.
    //
    // The test asserts a bound rather than equality. If a future edit makes the halo
    // dramatically brighter, this catches it; it does not pretend the placeholder is
    // energy-conserving.
    std::printf("\nIce placeholder (NOT energy-conserving by construction):\n");
    const Result ri = measure(12.0f, 1, 0x5eed1ce5u, quadN, sampleN);
    std::printf("  integral %.6f  (excess energy %+.2f%%)\n",
                ri.integral, (ri.integral - 1.0) * 100.0);
    std::printf("  mean weight %.6f   max weight %.4f\n", ri.meanWeight, ri.maxWeight);

    // The two must still AGREE with each other even though neither is 1: the mean
    // weight is the integral whatever the integral happens to be, and that identity
    // is what tests the sampler. If these diverge, the ice pdf is wrong.
    if (std::fabs(ri.meanWeight - ri.integral) > 5e-3) {
        std::printf("    FAIL: mean weight %.6f does not match the integral %.6f --\n"
                    "          the ice pdf does not describe what is sampled.\n"
                    "          ICE_FORWARD_W / ICE_FORWARD_G in samplePhaseDir must\n"
                    "          match phaseIce's own mix(), which is what the\n"
                    "          prototype's comment warns about.\n",
                    ri.meanWeight, ri.integral);
        ++failures;
    }
    if (ri.integral < 1.0 || ri.integral > 1.6) {
        std::printf("    FAIL: the halo's energy is outside the expected range\n");
        ++failures;
    }

    std::printf("\n%s\n", failures == 0
        ? "phase functions normalise, and every sampler's pdf describes what it draws"
        : "PHASE CHECKS FAILED");
    return failures == 0 ? 0 : 1;
}
