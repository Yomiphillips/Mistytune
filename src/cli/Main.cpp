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

#include <cmath>
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
        "  --pitch <deg>    camera pitch, + is up (default 0, looking at the horizon;\n"
        "                   the effect's own default camera is +12)\n"
        "  --seed <n>       field seed (default 0x5eed1ce5)\n"
        "  --cpu            force the CPU path even when CUDA is available. The GPU\n"
        "                   is used by default when a device is present.\n"
        "  --require-gpu    fail instead of falling back if the GPU cannot render\n"
        "  --gpu-band-rows <n>  render the GPU frame in bands of n rows (0 = one\n"
        "                   launch). Must not change the image.\n"
        "  --threads <n>    CPU worker threads (0 = choose). Must not change the image.\n"
        "  --device         print what the renderer would use, and exit\n"
        "  --fingerprint    print the field and view hashes, and exit\n"
        "\n"
        "  --compare <ref>  render, then compare against <ref> instead of writing.\n"
        "                   Exits 0 if within tolerance, 1 if not.\n"
        "  --tolerance <n>  max allowed per-channel difference, 0-255 (default 2)\n"
        "\n"
        "Determinism: the same arguments must produce a byte-identical file, on\n"
        "either path and at any thread count. That is what tests/golden/ checks.\n");
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

// Reads a PPM this program wrote. DELIBERATELY NOT A GENERAL PPM READER -- it
// accepts only the exact header this file emits, because a golden reference that
// silently parsed as a different size would compare against the wrong pixels and
// report a pass.
bool readPpm(const char* path, std::vector<unsigned char>& rgb, int& width, int& height) {
    FILE* f = std::fopen(path, "rb");
    if (!f) return false;

    char magic[3] = { 0 };
    int maxval = 0;
    if (std::fscanf(f, "%2s %d %d %d", magic, &width, &height, &maxval) != 4 ||
        std::strcmp(magic, "P6") != 0 || maxval != 255 || width <= 0 || height <= 0) {
        std::fclose(f);
        return false;
    }
    // Exactly one whitespace character separates the header from the data.
    std::fgetc(f);

    rgb.resize(static_cast<size_t>(width) * height * 3);
    const size_t got = std::fread(rgb.data(), 1, rgb.size(), f);
    std::fclose(f);
    return got == rgb.size();
}

// ---------------------------------------------------------------------------
// COMPARISON IS BY MAXIMUM PER-CHANNEL DIFFERENCE, NOT BY AVERAGE.
//
// An average hides exactly the failures worth catching. A kernel change that
// wrecks one percent of the pixels -- a broken branch, a bad intersection along
// one edge, a single NaN -- moves the mean by almost nothing and moves the
// maximum to 255. A mean-based threshold loose enough to absorb legitimate
// cross-compiler rounding is far too loose to notice that.
//
// The mean is printed anyway, because when the maximum does trip it is the
// number that says whether the whole image moved or one pixel did.
// ---------------------------------------------------------------------------
int comparePpm(const char* refPath, const std::vector<float>& argb,
               int width, int height, int tolerance) {
    std::vector<unsigned char> ref;
    int rw = 0, rh = 0;
    if (!readPpm(refPath, ref, rw, rh)) {
        std::fprintf(stderr, "could not read reference %s\n", refPath);
        return 1;
    }
    if (rw != width || rh != height) {
        std::fprintf(stderr, "size mismatch: reference is %dx%d, render is %dx%d\n",
                     rw, rh, width, height);
        return 1;
    }

    int maxDiff = 0;
    double sumDiff = 0.0;
    int worstX = 0, worstY = 0;

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            for (int c = 0; c < 3; ++c) {
                float v = argb[(static_cast<size_t>(y) * width + x) * 4 + 1 + c];
                v = v < 0.0f ? 0.0f : (v > 1.0f ? 1.0f : v);
                const int got = static_cast<int>(v * 255.0f + 0.5f);
                const int want = ref[(static_cast<size_t>(y) * width + x) * 3 + c];
                const int d = got > want ? got - want : want - got;
                if (d > maxDiff) { maxDiff = d; worstX = x; worstY = y; }
                sumDiff += d;
            }
        }
    }

    const double mean = sumDiff / (static_cast<double>(width) * height * 3);
    std::printf("compare %s: max %d (at %d,%d), mean %.4f, tolerance %d -- %s\n",
                refPath, maxDiff, worstX, worstY, mean, tolerance,
                maxDiff <= tolerance ? "PASS" : "FAIL");

    return maxDiff <= tolerance ? 0 : 1;
}

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

    const char* outPath  = nullptr;
    const char* comparePath = nullptr;
    bool forceCpu        = false;
    // FAILS INSTEAD OF FALLING BACK. The friendly fallback below is right for a
    // person at a terminal and WRONG for a test: a GPU test that silently rendered
    // on the CPU would report green while checking nothing, which is the exact
    // failure tests/golden/CMakeLists.txt refuses to tolerate for missing
    // references. tests/golden/ passes this on every GPU comparison.
    bool requireGpu      = false;
    // 0 = one launch for the whole frame. Any other value renders in bands of
    // that many rows, which is what the EFFECT does -- see smartRenderHost in
    // src/ae/Mistytune.cpp, where the band is both the abort granularity and the
    // mitigation for the Windows display-driver timeout.
    //
    // IT EXISTS SO THE BANDING CAN BE TESTED. A band is a WINDOW into the frame:
    // the device buffer holds only those rows while view.originY moves down to
    // keep every ray's true position. That is easy to get wrong and impossible to
    // see in a whole-frame render, so determinism.gpuBands renders the same scene
    // banded and unbanded and demands the two be byte-identical.
    int  gpuBandRows     = 0;
    bool printDevice     = false;
    bool printHashes     = false;
    int  threads         = 0;      // 0 = let the renderer choose
    int  tolerance       = 2;

    // THE CAMERA, WHICH THIS TOOL COULD NOT SET AND SHOULD HAVE BEEN ABLE TO.
    //
    // The effect's default camera is pitched, and nothing here could reproduce that
    // -- so every headless render and every golden image was taken through an
    // IDENTITY camera looking straight at the horizon, and the framing the host
    // actually uses was never rendered once. An inverted pitch that put every pixel
    // below the horizon was therefore invisible from here.
    //
    // ZERO IS THE DEFAULT AND MEANS IDENTITY, so the golden images are unchanged.
    float pitchDegrees = 0.0f;

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
        else if (argIs(a, "--pitch") && hasNext)     pitchDegrees = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--seed") && hasNext)      req.field.seed = static_cast<unsigned>(std::strtoul(argv[++i], nullptr, 0));
        else if (argIs(a, "--cpu"))                  forceCpu = true;
        else if (argIs(a, "--require-gpu"))          requireGpu = true;
        else if (argIs(a, "--gpu-band-rows") && hasNext) gpuBandRows = std::atoi(argv[++i]);
        else if (argIs(a, "--threads") && hasNext)   threads = std::atoi(argv[++i]);
        else if (argIs(a, "--compare") && hasNext)   comparePath = argv[++i];
        else if (argIs(a, "--tolerance") && hasNext) tolerance = std::atoi(argv[++i]);
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

    if (!outPath && !comparePath) {
        std::fprintf(stderr, "nothing to do: give -o <out.ppm> or --compare <ref.ppm>\n\n");
        printUsage();
        return 2;
    }

    // THE SAME ROW-MAJOR CAMERA-TO-WORLD THE EFFECT BUILDS, and deliberately the
    // same arithmetic rather than a second version of it: R_x(pitch), so a positive
    // angle sends the camera's forward (0,0,-1) to world y = +sin(pitch) and pitches
    // it UP. See fillCameraFromComp in src/ae/AEBridge.h.
    if (pitchDegrees != 0.0f) {
        const float rad = pitchDegrees * 0.01745329252f;
        const float cc  = std::cos(rad);
        const float ss  = std::sin(rad);
        const float m[16] = {
            1.0f, 0.0f, 0.0f, 0.0f,
            0.0f, cc,   -ss,  0.0f,
            0.0f, ss,   cc,   0.0f,
            0.0f, 0.0f, 0.0f, 1.0f
        };
        for (int i = 0; i < 16; ++i) req.view.cameraToWorld[i] = m[i];
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
    // THE GPU PATH HERE OWNS ITS DEVICE MEMORY, unlike the one in the effect: there
    // is no host to hand this program a GPU buffer, so renderCudaToHost() allocates,
    // launches and copies back. That is what makes a GPU-versus-CPU comparison
    // possible at all outside After Effects -- and it is the half of tests/golden/
    // that could not be written while the kernel could only run inside a host.
    //
    // A FAILED GPU RENDER FALLS BACK RATHER THAN EXITING, and says so. The point of
    // this program is to produce a comparable image; refusing to produce one because
    // the fast path broke would take the diagnostic away at the moment it is needed.
    // ---------------------------------------------------------------------
    bool renderedOnGpu = false;

    if (!forceCpu && kernel::cudaAvailable()) {
        if (gpuBandRows <= 0) {
            renderedOnGpu = kernel::renderCudaToHost(req);
        } else {
            renderedOnGpu = true;
            for (int y = 0; y < req.view.heightPx; y += gpuBandRows) {
                int y1 = y + gpuBandRows;
                if (y1 > req.view.heightPx) y1 = req.view.heightPx;
                if (!kernel::renderCudaToHost(req, y, y1)) { renderedOnGpu = false; break; }
            }
        }
        if (!renderedOnGpu) {
            const char* why = kernel::lastCudaError();
            std::fprintf(stderr, "GPU render failed (%s)%s\n",
                         why && why[0] ? why : "no detail",
                         requireGpu ? "" : " -- falling back to the CPU.");
            if (requireGpu) return 3;
        }
    }

    if (requireGpu && !renderedOnGpu) {
        std::fprintf(stderr, "--require-gpu was given but no CUDA device is usable\n");
        return 3;
    }

    if (!renderedOnGpu) {
        kernel::renderCpu(req, threads);
    }

    if (comparePath) {
        // WHICH PATH PRODUCED THE PIXELS, PRINTED BESIDE THE VERDICT. A golden
        // comparison that does not say what it compared is a number without a claim.
        std::printf("rendered on the %s path\n",
                    renderedOnGpu ? "GPU (CUDA)" : "CPU reference");
        return comparePpm(comparePath, pixels, req.view.widthPx, req.view.heightPx, tolerance);
    }

    if (!writePpm(outPath, pixels, req.view.widthPx, req.view.heightPx)) {
        std::fprintf(stderr, "could not write %s\n", outPath);
        return 1;
    }

    std::printf("wrote %s (%dx%d, %d spp)\n",
                outPath, req.view.widthPx, req.view.heightPx, req.quality.samplesPerPixel);
    std::printf("  path: %s\n", renderedOnGpu ? "GPU (CUDA)" : "CPU reference");
    return 0;
}
