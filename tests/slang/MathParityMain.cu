// Slang's math against CUDA's, compared BIT FOR BIT.
//
// ===========================================================================
// THE ONE TEST THAT WOULD NOTICE `-fp-mode fast` ARRIVING IN A BUILD FILE.
//
// Writing the transport in Slang is only safe because Slang's generated CUDA calls
// the same math functions the CPU reference does. Measured 2026-09-28 and recorded
// in PROGRESS.md: identical over 44,001 inputs, every function the renderer uses.
//
// `-fp-mode fast` destroys that -- exp by up to 4.12e11 -- and destroys it UNEVENLY,
// leaving sqrt/rsqrt/exp2 exact. A build with it on renders a picture that is nearly
// right, which the golden suite would catch only where exp dominates a pixel.
//
// BITWISE AND NOT "WITHIN EPSILON", DELIBERATELY. tests/golden/ already compares at
// 2/255, so anything this test waves through gets to hide there. Either the two are
// the same function or the Slang bet has changed and somebody needs to know.
// ===========================================================================
//
// NEEDS NO SLANG. It compiles the COMMITTED generated CUDA, which is what ships --
// so it also catches the case where someone regenerates with the wrong flags and
// commits the result.

#include <cstdio>
#include <cmath>
#include <cstring>
#include <vector>

#include <cuda_runtime.h>

// The committed Slang output. Included as source so both kernels compile under one
// set of flags -- the same --fmad=false --prec-div=true --prec-sqrt=true the rest of
// the project builds with, which is half of why the numbers agree at all.
#include "MathParity.cu"

// What the CPU reference calls, and what the hand-written kernel in Mistytune.cu
// calls. If Slang's output stops matching THIS, the port's premise is gone.
__global__ void handWritten(const float* in, float* out, int count) {
    const int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= count) return;

    const float x = in[i];
    out[i * 7 + 0] = ::expf(x);
    out[i * 7 + 1] = ::sqrtf(::fabsf(x));
    out[i * 7 + 2] = ::cosf(x);
    out[i * 7 + 3] = ::sinf(x);
    out[i * 7 + 4] = ::tanf(x);
    out[i * 7 + 5] = ::rsqrtf(::fabsf(x) + 1.0f);
    out[i * 7 + 6] = ::exp2f(x);
}

int main() {
    int deviceCount = 0;
    if (cudaGetDeviceCount(&deviceCount) != cudaSuccess || deviceCount == 0) {
        // NOT A FAILURE. This mirrors how the rest of the build treats a missing
        // GPU: the CPU reference is the fallback everywhere else, and a machine
        // without a card should still get a green run rather than a red one it
        // cannot act on.
        std::printf("no CUDA device -- skipping (this test needs a GPU)\n");
        return 0;
    }

    // A RANGE THE RENDERER ACTUALLY VISITS, not a uniform sweep. Optical depths run
    // from tiny to tens; altitudes are divided by scale heights of 8000 and 1200;
    // the phase functions take cosines in [-1,1]. The near-zero and far-negative
    // tails are included because that is where an approximate intrinsic diverges
    // first, and where a sky's darkest pixels live.
    std::vector<float> in;
    for (int i = -20000; i <= 20000; ++i) in.push_back(static_cast<float>(i) * 0.002f);
    for (int i = 0; i < 2000; ++i)        in.push_back(static_cast<float>(i) * 1e-7f);
    for (int i = 0; i < 2000; ++i)        in.push_back(-static_cast<float>(i) * 0.05f);

    const int    count     = static_cast<int>(in.size());
    const size_t outFloats = static_cast<size_t>(count) * 7;

    float *dIn = nullptr, *dSlang = nullptr, *dHand = nullptr;
    if (cudaMalloc(&dIn, in.size() * sizeof(float)) != cudaSuccess ||
        cudaMalloc(&dSlang, outFloats * sizeof(float)) != cudaSuccess ||
        cudaMalloc(&dHand, outFloats * sizeof(float)) != cudaSuccess) {
        std::printf("FAIL: could not allocate device memory\n");
        return 1;
    }
    cudaMemcpy(dIn, in.data(), in.size() * sizeof(float), cudaMemcpyHostToDevice);

    const int block = 256;
    const int grid  = (count + block - 1) / block;

    StructuredBuffer<float>   sIn;
    sIn.data  = dIn;
    sIn.count = static_cast<size_t>(count);

    RWStructuredBuffer<float> sOut;
    sOut.data  = dSlang;
    sOut.count = outFloats;

    mathMain<<<grid, block>>>(sIn, sOut, count);
    handWritten<<<grid, block>>>(dIn, dHand, count);

    const cudaError_t err = cudaDeviceSynchronize();
    if (err != cudaSuccess) {
        std::printf("FAIL: CUDA error: %s\n", cudaGetErrorString(err));
        return 1;
    }

    std::vector<float> slangOut(outFloats), handOut(outFloats);
    cudaMemcpy(slangOut.data(), dSlang, outFloats * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(handOut.data(),  dHand,  outFloats * sizeof(float), cudaMemcpyDeviceToHost);

    const char* names[7] = { "exp", "sqrt", "cos", "sin", "tan", "rsqrt", "exp2" };
    int   differing[7] = { 0 };
    float worst[7]     = { 0 };

    for (int i = 0; i < count; ++i) {
        for (int f = 0; f < 7; ++f) {
            const float a = slangOut[static_cast<size_t>(i) * 7 + f];
            const float b = handOut[static_cast<size_t>(i) * 7 + f];

            // Two NaNs are the same answer for this test's purposes: tan near its
            // poles produces them on both sides, and their payloads are not a
            // promise either compiler makes.
            if (std::isnan(a) && std::isnan(b)) continue;

            unsigned ua = 0, ub = 0;
            std::memcpy(&ua, &a, sizeof(ua));
            std::memcpy(&ub, &b, sizeof(ub));
            if (ua != ub) {
                ++differing[f];
                const float d = std::fabs(a - b);
                if (d > worst[f]) worst[f] = d;
            }
        }
    }

    std::printf("%d inputs, Slang vs hand-written CUDA, compared bitwise:\n\n", count);
    int total = 0;
    for (int f = 0; f < 7; ++f) {
        std::printf("  %-6s %8d differing   worst abs diff %g\n",
                    names[f], differing[f], static_cast<double>(worst[f]));
        total += differing[f];
    }

    if (total == 0) {
        std::printf("\nidentical -- a faithful Slang port matches the CPU reference "
                    "by construction\n");
        return 0;
    }

    std::printf(
        "\nSLANG'S MATH IS NO LONGER CUDA'S MATH.\n"
        "  The most likely cause by far is `-fp-mode fast` reaching slangc: it\n"
        "  redirects exp/sin/cos/tan/log/pow to the approximate __*f intrinsics and\n"
        "  leaves sqrt/rsqrt/exp2 alone, which is the signature above if exp and the\n"
        "  trig functions moved and the others did not.\n"
        "  See PLUGIN_SLANG_FP_MODE in cmake/Slang.cmake -- it is not meant to be\n"
        "  configurable, and changing it means re-blessing every golden reference.\n"
        "  A Slang version bump is the other candidate; the version is printed at\n"
        "  configure time for exactly this moment.\n");
    return 1;
}
