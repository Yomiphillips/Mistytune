// One kernel source, two backends, and the check that they agree.
//
// ===========================================================================
// THIS IS THE PROPERTY THE WHOLE TEST STRATEGY RESTS ON, AND NOTHING CHECKED IT.
//
// PLAN.md asks for the transport written once and compiled to every target.
// `renderPixel` is a single function serving both the CPU and the GPU, and CpuRender.cpp
// is emphatic that it is "not a second renderer". That arrangement is what makes a
// golden image rendered on the CPU a meaningful check on the GPU -- but only while the
// two are actually computing the same maths.
//
// So: the same Slang library, compiled through `-target cuda` and through `-target cpp`,
// run over the same inputs, compared.
//
// WHY THE ENTRY POINTS HAVE DIFFERENT NAMES ON EACH SIDE. slangc marks them
// `SLANG_PRELUDE_EXPORT`, which is `extern "C"` -- so the CUDA `transmittanceTrial` and a
// C++ `transmittanceTrial` are one symbol and a binary holding both will not link.
// Namespacing does not help, because `extern "C"` ignores namespaces. The CPU side
// therefore declares `cpu*` entry points over THE SAME library, which is the same test:
// what parity is claimed about is `transmittance`, `densityAt`, `iceDensity` and
// `randFloat`, and every one of those is identical source text on both sides.
//
// BITWISE IS NOT THE CLAIM AND IS NOT EXPECTED. slang.mathParity established that
// Slang's CUDA output calls the same functions as hand-written CUDA. It established
// nothing about the HOST compiler's libm matching the device's, and for exp and the trig
// functions it will not. What has to hold is that they agree far inside tests/golden/'s
// own tolerance, because that is what makes a CPU reference usable at all.
// ===========================================================================

#include <cstdio>
#include <cmath>
#include <cstring>
#include <vector>
#include <algorithm>

#include <cuda_runtime.h>

// The CUDA side. Transport.cu carries `rngTrial` and `transmittanceTrial`.
#include "Transport.cu"

// The C++ side, compiled from the same library through -target cpp. Included as source
// into its own translation unit exactly as the CUDA one is.
namespace cpuside {
#include "CpuParity.cpp"
}

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

struct Diff {
    double worstAbs = 0.0;
    double worstRel = 0.0;
    int    differing = 0;
};

Diff compare(const std::vector<float>& a, const std::vector<float>& b) {
    Diff d;
    for (size_t i = 0; i < a.size(); ++i) {
        const double da = a[i], db = b[i];
        const double abs = std::fabs(da - db);
        if (abs != 0.0) ++d.differing;
        d.worstAbs = std::max(d.worstAbs, abs);
        const double scale = std::max(std::fabs(da), std::fabs(db));
        if (scale > 1e-12) d.worstRel = std::max(d.worstRel, abs / scale);
    }
    return d;
}

} // namespace

int main() {
    int deviceCount = 0;
    if (cudaGetDeviceCount(&deviceCount) != cudaSuccess || deviceCount == 0) {
        std::printf("no CUDA device -- skipping (this test needs a GPU)\n");
        return 0;
    }

    int failures = 0;
    const int n = 1 << 16;

    // -----------------------------------------------------------------------
    // 1. The random number generator, which must be EXACT
    // -----------------------------------------------------------------------
    //
    // PCG is integer arithmetic and one float multiply. There is no libm in it and no
    // room for a backend to differ, so this is the one comparison that demands equality
    // rather than closeness -- and it isolates the RNG from everything built on it. If
    // this fails, nothing below it means anything.
    {
        std::vector<float> gpu(n), cpu(n);

        float* d = nullptr;
        cudaMalloc(&d, static_cast<size_t>(n) * sizeof(float));
        RWStructuredBuffer<float> buf;
        buf.data  = d;
        buf.count = static_cast<size_t>(n);
        rngTrial<<<(n + 63) / 64, 64>>>(buf, 12345u, n);
        cudaMemcpy(gpu.data(), d, gpu.size() * sizeof(float), cudaMemcpyDeviceToHost);
        cudaFree(d);

        cpuside::EntryPointParams_0 p{};
        p.output_0.data  = cpu.data();
        p.output_0.count = static_cast<size_t>(n);
        p.seed_0  = 12345u;
        p.count_0 = n;

        cpuside::ComputeVaryingInput vi{};
        vi.startGroupID = { 0, 0, 0 };
        vi.endGroupID   = { static_cast<uint32_t>((n + 63) / 64), 1, 1 };
        cpuside::cpuRngTrial(&vi, &p, nullptr);

        const Diff diff = compare(gpu, cpu);
        std::printf("RNG, %d draws\n", n);
        std::printf("  differing %d of %d, worst absolute %.3g\n",
                    diff.differing, n, diff.worstAbs);

        if (diff.differing != 0) {
            std::printf("    FAIL: the PCG generator is integer arithmetic -- the two\n"
                        "          backends must agree EXACTLY, and every determinism\n"
                        "          guarantee in the project depends on it\n");
            ++failures;
        } else {
            std::printf("  identical, as integer arithmetic must be\n");
        }
    }

    // -----------------------------------------------------------------------
    // 2. Ratio-tracked transmittance through the ice field
    // -----------------------------------------------------------------------
    //
    // The whole estimator: the RNG, the slab geometry, the grid lookup, the loop, and
    // `iceDensity` underneath it -- which is where exp, the fbm, the gradient noise and
    // the PCG hashes live. This is where the two libms get their chance to differ.
    {
        Medium_0 m{};
        m.slabTop_0     = 8000.0f;
        m.slabBottom_0  = 6500.0f;
        m.density_0     = 0.0f;
        m.coreCentre_0  = make_float3(0.0f, 0.0f, 0.0f);
        m.coreRadius_0  = 1.0f;
        m.coreDensity_0 = 0.0f;
        m.mode_0        = 2;

        m.gen_0.cellAltitude_0 = 8000.0f;
        m.gen_0.streakLength_0 = 1500.0f;
        m.gen_0.cellSize_0     = 400.0f;
        m.gen_0.cellDensity_0  = 0.35f;
        m.gen_0.cellStrength_0 = 1.0f;
        m.gen_0.cellDrift_0    = make_float2(0.0f, 0.0f);
        m.gen_0.sublimation_0  = 0.6f;
        m.gen_0.fallSpeed_0    = 1.0f;
        m.gen_0.detailScale_0  = 300.0f;
        m.gen_0.detailAmount_0 = 0.4f;
        m.gen_0.opticalDepth_0 = 0.45f;
        m.gen_0.timeSeconds_0  = 0.0f;
        m.gen_0.octaves_0      = 4;
        m.majorant_0           = 1.0e-3f;

        MajorantGrid_0 grid{};
        grid.origin_0     = make_float3(0.0f, 0.0f, 0.0f);
        grid.cellExtent_0 = make_float3(1.0f, 1.0f, 1.0f);
        grid.dims_0       = make_int3(1, 1, 1);
        grid.enabled_0    = 0;

        std::vector<float2> knots(33);
        for (int i = 0; i <= 32; ++i) {
            const float depth = m.gen_0.streakLength_0 * i / 32.0f;
            knots[i] = make_float2(2.0f * depth / m.gen_0.fallSpeed_0, 0.0f);
        }

        const float3 origin = make_float3(-300.0f, 6490.0f, 120.0f);
        const float3 dir    = make_float3(0.1736f, 0.9848f, 0.0f);

        std::vector<float> gpu(n), cpu(n);

        // GPU
        {
            float*  d  = nullptr;
            float*  db = nullptr;
            float2* dk = nullptr;
            cudaMalloc(&d,  static_cast<size_t>(n) * sizeof(float));
            cudaMalloc(&db, sizeof(float));
            cudaMalloc(&dk, knots.size() * sizeof(float2));
            cudaMemcpy(dk, knots.data(), knots.size() * sizeof(float2), cudaMemcpyHostToDevice);

            RWStructuredBuffer<float> out;  out.data = d;  out.count = static_cast<size_t>(n);
            RWStructuredBuffer<int>   stp;
            int* ds = nullptr;
            cudaMalloc(&ds, static_cast<size_t>(n) * sizeof(int));
            stp.data = ds; stp.count = static_cast<size_t>(n);

            StructuredBuffer<float>  bnd; bnd.data = db; bnd.count = 1;
            StructuredBuffer<float2> drf; drf.data = dk; drf.count = 33;

            transmittanceTrial<<<(n + 63) / 64, 64>>>(m, grid, bnd, drf, origin, dir,
                                                      out, stp, 0x1234u, n);
            cudaMemcpy(gpu.data(), d, gpu.size() * sizeof(float), cudaMemcpyDeviceToHost);
            cudaFree(d); cudaFree(db); cudaFree(dk); cudaFree(ds);
        }

        // CPU
        {
            float hostBound = 0.0f;

            // ===============================================================
            // FIELD BY FIELD, NOT memcpy, AND THE FIRST ATTEMPT GOT THIS WRONG.
            //
            // `Medium_0` on the CUDA side and `cpuside::Medium_0` are two different C++
            // definitions of the same Slang struct, and the backends spell vectors
            // differently: CUDA emits `float3`, the C++ target emits `Vector<float,3>`.
            // They need not agree on size or alignment, and here they do not -- a
            // memcpy between them scrambled the medium and every CPU ray returned 1.0,
            // which reads as "the ray missed the cloud" rather than as a marshalling
            // bug.
            //
            // THIS IS A LESSON FOR THE PRODUCTION PATH, NOT JUST FOR THIS TEST. The host
            // will hold one set of parameters and must marshal them into BOTH backends'
            // structs, and the only safe way to do that is member by member.
            // ===============================================================
            if (sizeof(cpuside::Medium_0) != sizeof(Medium_0)) {
                std::printf("  note: Medium_0 is %zu bytes on the CPU backend and %zu on\n"
                            "        the CUDA one -- marshalling must be field by field\n",
                            sizeof(cpuside::Medium_0), sizeof(Medium_0));
            }

            cpuside::EntryPointParams_1 p{};

            p.medium_0.slabTop_0     = m.slabTop_0;
            p.medium_0.slabBottom_0  = m.slabBottom_0;
            p.medium_0.majorant_0    = m.majorant_0;
            p.medium_0.density_0     = m.density_0;
            p.medium_0.coreCentre_0  = { m.coreCentre_0.x, m.coreCentre_0.y, m.coreCentre_0.z };
            p.medium_0.coreRadius_0  = m.coreRadius_0;
            p.medium_0.coreDensity_0 = m.coreDensity_0;
            p.medium_0.mode_0        = m.mode_0;

            p.medium_0.gen_0.cellAltitude_0 = m.gen_0.cellAltitude_0;
            p.medium_0.gen_0.streakLength_0 = m.gen_0.streakLength_0;
            p.medium_0.gen_0.cellSize_0     = m.gen_0.cellSize_0;
            p.medium_0.gen_0.cellDensity_0  = m.gen_0.cellDensity_0;
            p.medium_0.gen_0.cellStrength_0 = m.gen_0.cellStrength_0;
            p.medium_0.gen_0.cellDrift_0    = { m.gen_0.cellDrift_0.x, m.gen_0.cellDrift_0.y };
            p.medium_0.gen_0.sublimation_0  = m.gen_0.sublimation_0;
            p.medium_0.gen_0.fallSpeed_0    = m.gen_0.fallSpeed_0;
            p.medium_0.gen_0.detailScale_0  = m.gen_0.detailScale_0;
            p.medium_0.gen_0.detailAmount_0 = m.gen_0.detailAmount_0;
            p.medium_0.gen_0.opticalDepth_0 = m.gen_0.opticalDepth_0;
            p.medium_0.gen_0.timeSeconds_0  = m.gen_0.timeSeconds_0;
            p.medium_0.gen_0.octaves_0      = m.gen_0.octaves_0;

            p.grid_0.origin_0     = { grid.origin_0.x, grid.origin_0.y, grid.origin_0.z };
            p.grid_0.cellExtent_0 = { grid.cellExtent_0.x, grid.cellExtent_0.y,
                                      grid.cellExtent_0.z };
            p.grid_0.dims_0       = { grid.dims_0.x, grid.dims_0.y, grid.dims_0.z };
            p.grid_0.enabled_0    = grid.enabled_0;
            p.bounds_0.data  = &hostBound;
            p.bounds_0.count = 1;
            p.drift_0.data   = reinterpret_cast<cpuside::Vector<float, 2>*>(knots.data());
            p.drift_0.count  = knots.size();
            p.origin_1    = { origin.x, origin.y, origin.z };
            p.direction_0 = { dir.x, dir.y, dir.z };
            p.output_1.data  = cpu.data();
            p.output_1.count = static_cast<size_t>(n);
            p.seed_1  = 0x1234u;
            p.count_1 = n;

            cpuside::ComputeVaryingInput vi{};
            vi.startGroupID = { 0, 0, 0 };
            vi.endGroupID   = { static_cast<uint32_t>((n + 63) / 64), 1, 1 };
            cpuside::cpuTransmittanceTrial(&vi, &p, nullptr);
        }

        const Diff diff = compare(gpu, cpu);
        const double meanGpu = kahanSum(gpu) / n;
        const double meanCpu = kahanSum(cpu) / n;

        std::printf("\nRatio-tracked transmittance through the ice field, %d rays\n", n);
        std::printf("  mean   GPU %.8f   CPU %.8f   difference %.3g\n",
                    meanGpu, meanCpu, meanGpu - meanCpu);
        std::printf("  per ray: differing %d of %d, worst absolute %.3g, worst relative %.3g\n",
                    diff.differing, n, diff.worstAbs, diff.worstRel);

        // A RAY-BY-RAY BOUND, NOT JUST A MEAN. Two backends whose errors cancelled in
        // the mean while individual rays disagreed wildly would still ruin a golden
        // image, because a golden image is compared pixel by pixel.
        //
        // 2/255 is what tests/golden/ tolerates on an 8-bit render. This asks for two
        // orders of magnitude better than that, which is the margin that makes a CPU
        // reference worth having rather than merely defensible.
        if (diff.worstAbs > 1.0e-4) {
            std::printf("    FAIL: the CUDA and C++ backends disagree by %.3g on a single\n"
                        "          ray. `renderPixel` is one function serving both engines,\n"
                        "          so a golden image taken on the CPU stops being a check on\n"
                        "          the GPU at all.\n", diff.worstAbs);
            ++failures;
        }

        // THE SANITY CHECK THAT STOPS THIS PASSING FOR THE WRONG REASON: if the ray
        // misses the cloud entirely both sides return 1.0 and agree perfectly while
        // testing nothing.
        if (meanGpu > 0.999 || meanGpu <= 0.0) {
            std::printf("    FAIL: mean transmittance %.6f -- the ray is not actually\n"
                        "          passing through cloud, so this comparison is vacuous\n",
                        meanGpu);
            ++failures;
        }
    }

    std::printf("\n%s\n", failures == 0
        ? "the CUDA and C++ backends agree -- one kernel source really is one"
        : "CPU/GPU PARITY FAILED");
    return failures == 0 ? 0 : 1;
}
