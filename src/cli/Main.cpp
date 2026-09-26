// mistytunec -- the headless renderer.
//
// ===========================================================================
// THIS IS THE TEST HARNESS FIRST AND A FEATURE SECOND.
//
// PLAN.md is explicit that it gets built in the same week as the kernel, and the
// reason is not convenience: A GPU PATH TRACER THAT CAN ONLY RUN INSIDE AFTER
// EFFECTS CANNOT BE GOLDEN-IMAGED, PROFILED OR BISECTED. Every regression would be
// diagnosed by launching a host, applying an effect and looking at it.
//
// So this exists to make three things possible:
//
//   1. tests/golden/ -- fixed scenes rendered here and compared with tolerance.
//      Including the two comparisons that catch non-determinism: the same inputs
//      rendered twice, and rendered again with a different worker count.
//   2. Profiling, under a profiler that does not have a host in the way.
//   3. Bisecting a kernel change without a 40-second AE launch in the loop.
//
// The EXR bake feature PLAN.md mentions falls out of it for free, later.
// ===========================================================================
//
// NO AE HEADERS. It links plugin_kernel and plugin_engine and nothing else, which is
// the whole point: it hands the kernel the same RenderRequest the effect does, so a
// difference between the two is a difference in that struct and nowhere else.

#include "KernelApi.h"
#include "FieldCache.h"
#include "Fingerprint.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

using namespace plugin;

namespace {

void printUsage() {
    std::printf(
        "mistytunec -- Mistytune headless renderer\n"
        "\n"
        "Usage:\n"
        "  mistytunec [options] -o <out.ppm>\n"
        "\n"
        "Options:\n"
        "  -o <path>        output file (.ppm, 8-bit; EXR comes with the bake feature)\n"
        "  -w <px>          width  (default 640)\n"
        "  -h <px>          height (default 360)\n"
        "  -s <n>           samples per pixel (default 16)\n"
        "  --sun-el <deg>   sun elevation (default 12)\n"
        "  --sun-az <deg>   sun azimuth (default 135)\n"
        "  --turbidity <t>  Linke turbidity (default 2.2)\n"
        "  --ev <stops>     exposure (default 0)\n"
        "  --agx            enable the AgX tonemap (default off)\n"
        "  --seed <n>       field seed (default 0x5eed1ce5)\n"
        "  --cpu            force the CPU path even when CUDA is available\n"
        "  --device         print what the renderer would use, and exit\n"
        "  --fingerprint    print the field and view hashes, and exit\n"
        "\n"
        "Determinism: the same arguments must produce a byte-identical file, on\n"
        "either path. That is what tests/golden/ checks.\n");
}

// PPM RATHER THAN EXR, FOR NOW, AND IT IS A DELIBERATE STOPGAP.
//
// The renderer's output is linear HDR and PPM is neither, so this throws away
// exactly what the format exists to carry -- which is why the bake feature needs
// OpenEXR and will get it. What PPM buys today is a dependency-free file that any
// viewer opens and that `cmp` compares byte for byte, which is all a golden-image
// harness needs to start catching regressions.
//
// LINEAR IS WRITTEN AS LINEAR, with no sRGB transfer applied. The file will look
// dark in a viewer that assumes sRGB. That is correct and is the lesser evil: a
// transfer curve applied here would be a second, invisible tonemap sitting between
// the renderer and the comparison, and a golden image has to be of the renderer.
bool writePpm(const char* path, const std::vector<float>& argb, int width, int height) {
    FILE* f = std::fopen(path, "wb");
    if (!f) return false;

    std::fprintf(f, "P6\n%d %d\n255\n", width, height);

    std::vector<unsigned char> row(static_cast<size_t>(width) * 3);
    for (int y = 0; y < height; ++y) {
        const float* src = argb.data() + static_cast<size_t>(y) * width * 4;
        for (int x = 0; x < width; ++x) {
            for (int c = 0; c < 3; ++c) {
                // ARGB in memory, so colour starts at offset 1.
                float v = src[x * 4 + 1 + c];
                v = v < 0.0f ? 0.0f : (v > 1.0f ? 1.0f : v);
                row[static_cast<size_t>(x) * 3 + c] =
                    static_cast<unsigned char>(v * 255.0f + 0.5f);
            }
        }
        std::fwrite(row.data(), 1, row.size(), f);
    }

    std::fclose(f);
    return true;
}

bool argIs(const char* a, const char* want) { return std::strcmp(a, want) == 0; }

} // namespace

int main(int argc, char** argv) {
    kernel::RenderRequest req;

    // THE DEFAULTS ARE THE STRUCTS' OWN, not a second set typed here. CloudParams.h
    // is the one definition of what a parameter means and what it starts at, and a
    // CLI with its own defaults would make a golden image taken here describe a scene
    // the effect never renders.
    req.view.widthPx  = 640;
    req.view.heightPx = 360;
    req.quality.samplesPerPixel = 16;

    const char* outPath = nullptr;
    bool forceCpu       = false;
    bool printDevice    = false;
    bool printHashes    = false;

    for (int i = 1; i < argc; ++i) {
        const char* a = argv[i];
        const bool hasNext = (i + 1) < argc;

        if (argIs(a, "--help") || argIs(a, "-?")) { printUsage(); return 0; }
        else if (argIs(a, "-o") && hasNext)          outPath = argv[++i];
        else if (argIs(a, "-w") && hasNext)          req.view.widthPx  = std::atoi(argv[++i]);
        else if (argIs(a, "-h") && hasNext)          req.view.heightPx = std::atoi(argv[++i]);
        else if (argIs(a, "-s") && hasNext)          req.quality.samplesPerPixel = std::atoi(argv[++i]);
        else if (argIs(a, "--sun-el") && hasNext)    req.field.atmosphere.sunElevation = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--sun-az") && hasNext)    req.field.atmosphere.sunAzimuth   = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--turbidity") && hasNext) req.field.atmosphere.turbidity    = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--ev") && hasNext)        req.view.exposureEV = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--agx"))                  req.view.agxTonemap = true;
        else if (argIs(a, "--seed") && hasNext)      req.field.seed = static_cast<unsigned>(std::strtoul(argv[++i], nullptr, 0));
        else if (argIs(a, "--cpu"))                  forceCpu = true;
        else if (argIs(a, "--device"))               printDevice = true;
        else if (argIs(a, "--fingerprint"))          printHashes = true;
        else {
            std::fprintf(stderr, "unknown or incomplete option: %s\n\n", a);
            printUsage();
            return 2;
        }
    }

    if (printDevice) {
        std::printf("cuda available : %s\n", kernel::cudaAvailable() ? "yes" : "no");
        std::printf("device         : %s\n", kernel::deviceDescription());
        return 0;
    }

    if (req.view.widthPx <= 0 || req.view.heightPx <= 0) {
        std::fprintf(stderr, "width and height must be positive\n");
        return 2;
    }
    if (req.quality.samplesPerPixel < 1) req.quality.samplesPerPixel = 1;

    if (printHashes) {
        // THE SAME TWO HASHES THE EFFECT COMPUTES, from the same code. Printing them
        // is how a cache bug gets diagnosed without a host: render twice with one
        // parameter changed and see which hash moved.
        sim::Fingerprint fp;
        fp.add(req.field);
        std::printf("field : 0x%016llx\n", static_cast<unsigned long long>(fp.value()));
        std::printf("view  : 0x%016llx\n",
                    static_cast<unsigned long long>(sim::viewHash(req.view, req.quality)));
        return 0;
    }

    if (!outPath) {
        std::fprintf(stderr, "no output path given (-o)\n\n");
        printUsage();
        return 2;
    }

    // TIGHTLY PACKED, UNLIKE AE'S WORLDS. AE pads rows and the kernel is told the
    // pitch separately for exactly that reason; here there is no padding, so pitch
    // equals width. Writing it out rather than leaving it zero is what keeps the two
    // callers' assumptions visible side by side.
    std::vector<float> pixels(static_cast<size_t>(req.view.widthPx) *
                              static_cast<size_t>(req.view.heightPx) * 4, 0.0f);

    req.dest.data     = pixels.data();
    req.dest.widthPx  = req.view.widthPx;
    req.dest.heightPx = req.view.heightPx;
    req.dest.pitchPx  = req.view.widthPx;
    req.dest.order    = kernel::ChannelOrder::ARGB;

    req.firstSample        = 0;
    req.sampleCount        = req.quality.samplesPerPixel;
    req.samplesAlreadyDone = 0;
    req.accumulator        = nullptr;

    // ---------------------------------------------------------------------
    // THE PATH CHOICE, AND WHY --cpu EXISTS.
    //
    // The CPU path is the correctness reference, so it has to be reachable ON A
    // MACHINE THAT HAS A GPU. Without a way to ask for it, the only machines that
    // ever ran it would be the ones that could not run the other one -- and a
    // reference nobody compares against is not a reference.
    //
    // A CUDA pointer cannot be written by the CPU loop, so this CLI's GPU path needs
    // device memory and a copy back; that arrives with the bake feature. Today
    // --cpu is the only path here, and saying so is better than pretending.
    // ---------------------------------------------------------------------
    const bool useGpu = !forceCpu && kernel::cudaAvailable();
    if (useGpu) {
        std::printf("note: the GPU path needs device allocation and a copy back, which\n"
                    "      lands with the EXR bake. Rendering on the CPU reference.\n");
    }

    kernel::renderCpu(req);

    if (!writePpm(outPath, pixels, req.view.widthPx, req.view.heightPx)) {
        std::fprintf(stderr, "could not write %s\n", outPath);
        return 1;
    }

    std::printf("wrote %s (%dx%d, %d spp)\n",
                outPath, req.view.widthPx, req.view.heightPx, req.quality.samplesPerPixel);
    return 0;
}
