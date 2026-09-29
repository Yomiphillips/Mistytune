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

    SkyInput_0 slangIn;
    slangIn.transmittance_0.data  = dLut;
    slangIn.transmittance_0.count = lut.size();
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

    if (differing == 0) {
        std::printf("\nidentical -- the port is a faithful transcription\n");
        return 0;
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
