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
#include "Denoiser.h"
#include "Fingerprint.h"
#include "LocalLights.h"
#include "OrbitCamera.h"
#include "Pareidolia.h"
#include "SunPlacement.h"
#include "Upscale.h"

#include <algorithm>
#include <chrono>
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
        "  --linear         write LINEAR radiance instead of display-referred sRGB.\n"
        "                   The default encodes, because AE with Working Space None\n"
        "                   applies no transform of its own and proto/index.html --\n"
        "                   which passed the Phase 0 look verdict -- encodes too.\n"
        "                   Use this for a colour-managed project or an HDR bake.\n"
        "  --agx            enable the AgX tonemap (default off)\n"
        "  --pitch <deg>    camera pitch, + is up (default 0, looking at the horizon;\n"
        "                   the effect's own default camera is +12)\n"
        "  --seed <n>       field seed (default 0x5eed1ce5)\n"
        "  --cpu            force the CPU path even when CUDA is available. The GPU\n"
        "                   is used by default when a device is present.\n"
        "  --require-gpu    fail instead of falling back if the GPU cannot render\n"
        "  --window <x> <y> <w> <h>  render only this sub-rect of the frame, as\n"
        "                   After Effects does for a Region of Interest. -w/-h stay\n"
        "                   the FRAME; the buffer becomes w x h at origin x,y.\n"
        "  --compare-at <x> <y>  compare the render against the region of <ref>\n"
        "                   at x,y instead of against the whole file.\n"
        "  --majorant <v>   pin the density majorant instead of deriving it from the\n"
        "                   field (0 = derive, the default). Null-collision tracking\n"
        "                   is unbiased for ANY value at or above the true peak, so\n"
        "                   a loose one must converge to the same image -- which is\n"
        "                   what makes this the check on a tightened bound rather\n"
        "                   than a profiling knob. BELOW the peak it renders a\n"
        "                   thinner cloud and says nothing.\n"
        "  --sample-chunk <n>   accumulate the frame in chunks of n samples\n"
        "                   (0 = all in one). Changes the image only by the\n"
        "                   rounding of a regrouped sum.\n"
        "  --gpu-band-rows <n>  render the GPU frame in bands of n rows (0 = one\n"
        "                   launch). Must not change the image.\n"
        "  --threads <n>    CPU worker threads (0 = choose). Must not change the image.\n"
        "  --heading <deg>  the compass direction the camera faces, clockwise from +Z\n"
        "                   like --sun-az (default 180, the identity camera). Set it\n"
        "                   to the sun's azimuth for a backlit view.\n"
        "  --fov <deg>      vertical field of view (default 39.6, 50 mm full frame)\n"
        "  --cam-x <m>      where the eye stands: metres east (+X) of the origin\n"
        "  --cam-z <m>      ...and metres along +Z, which the identity camera faces away from\n"
        "  --altitude <m>   the eye's height (default 2)\n"
        "\n"
        "  The orbit rig -- the effect's default camera. Any of these turns it on, and it\n"
        "  then replaces --pitch, --heading, --fov and --cam-x/z; --altitude is the eye:\n"
        "  --orbit <deg>    round the hero, + walks right (default 0)\n"
        "  --distance <m>   from the hero's axis along the ground (default 4000)\n"
        "  --look-at <f>    where on the cloud to aim, 0 base .. 1 top (default 0.5)\n"
        "  --tilt <deg>  --pan <deg>  --roll <deg>   offsets from that aim\n"
        "  --focal <mm>     focal length on 36 mm film (default 24)\n"
        "  --bounces <n>    scattering events per path (default 32)\n"
        "  --shadow-handoff <texels>  build 25: a shadow ray walks this many shadow-map\n"
        "                   texels of clear air, then reads the rest from the map\n"
        "                   (default 0, the exact ray; Draft uses 2)\n"
        "  --pixel-stride <n>  build 26: one path per n x n block, denoised at that size\n"
        "                   and scaled up (default 1; Draft uses 2)\n"
        "  --draft          Render Quality Draft: 1 spp, hand-off 2, stride 2, and a full\n"
        "                   denoise (on, amount 1, as the effect does)\n"
        "  --megakernel     the GPU's single kernel, each pixel's paths start to finish,\n"
        "                   instead of build 25's launch per bounce. Same bits; A/B only.\n"
        "\n"
        "  The cumulus layer (cellular convection). OFF unless one of these is given,\n"
        "  so every golden scene above is a lone cirrus:\n"
        "  --cumulus        turn the convection layer on at its defaults\n"
        "  --no-ice         turn the cirrus layer off\n"
        "  --polarity <p>   0 = open cells (scattered cumulus) .. 1 = closed (a deck)\n"
        "  --coverage <c>   0..1, how much of the sky the moisture fills\n"
        "  --instability <i> 0..1, humilis -> congestus\n"
        "  --cell-size <m>  the convective cells' spacing (default 1800)\n"
        "  --inversion <m>  the lid (default 2400)\n"
        "  --conv-density <s>  peak extinction per metre (default 0.03)\n"
        "  --billow <m>     billow displacement (default 160)\n"
        "  --billow-scale <m>  the largest billow (default 320)\n"
        "  --billow-octaves <n>  billow octaves, 1..4 (default 3)\n"
        "  --humidity <rh>  surface humidity 0..1, which sets the base (default 0.7)\n"
        "  --hero <1|2>     a hero cloud with the field, or alone\n"
        "  --hero-x <m>  --hero-z <m>  --hero-width <m>  --hero-height <0..1>  --hero-var <v>\n"
        "  --hero-connection <0..1>  build 22: turrets, a flanking line into the wind,\n"
        "                   and the field sinking under them (default 0, the lone tower)\n"
        "  --hero-drift     the hero rides the steering wind with the field\n"
        "  --mamma <0..1>   build 23: pouches hanging from the layer's underside (default 0)\n"
        "  --pouch-size <m> one pouch's width (default 450)\n"
        "  --pileus <0..1>  build 24: a smooth cap over the hero's crown (default 0)\n"
        "  --pileus-gap <m> the crown's highest billows to the cap's middle (default 150)\n"
        "  --velum <0..1>   a wide thin veil the hero rises through (default 0)\n"
        "  --velum-height <0..1>  of the hero's height (default 0.6)\n"
        "\n"
        "  The Organization group, for the cumulus layer (turns it on) and, with an\n"
        "  --ice- prefix, the cirrus layer's generating cells. Bearings clockwise from +Z:\n"
        "  --org <mode>     cellular | rolls | waves | chaotic (or 0..3)\n"
        "  --aspect <a>     cells a times longer along their rows (default 1)\n"
        "  --rows-along <deg>  the rows' bearing (default 90, the lattice unturned)\n"
        "  --coherence <c>  0..1, how straight the rows are\n"
        "  --wave-length <m>  crest to crest (default 3000)\n"
        "  --wave-amp <a>   0..1, 1 clears the troughs\n"
        "  --crests-along <deg>  the crests' bearing (default 0)\n"
        "  --gap <g>        0..1, clear seams between closed cells (cumulus only)\n"
        "  --lacunarity <l> 0..1, a deck with round holes (cumulus only)\n"
        "  --conv-grid <0|1>  the cumulus layer's procedural majorant grid (default 0).\n"
        "                   Cost only: any majorant above the density is unbiased.\n"
        "  --nee-scale <k>  the camera ray's sun: 0 = one next event at the first real\n"
        "                   collision (delta tracking); k >= 1 = a continuous estimate\n"
        "                   over tentative collisions drawn at k x the majorant\n"
        "                   (default 1). Unbiased either way, so it changes noise,\n"
        "                   flicker and cost -- never the converged image.\n"
        "  --aerial <0|1>   the air between the eye and the first cloud: its airlight\n"
        "                   and its transmittance (default 1). 0 is every render\n"
        "                   before build 17.\n"
        "  --no-air-shadows the clouds' shadows in that air (crepuscular rays) off;\n"
        "                   the effect's Cloud Shadows In Air checkbox.\n"
        "  --air-shadow-rays  those shadows from one shadow ray per camera ray, as\n"
        "                   build 17 drew them, instead of the per-frame shadow map.\n"
        "  --air-map-res <n>  the shadow map's texel budget: n x n for the cumulus,\n"
        "                   a quarter of that for the cirrus (default 512).\n"
        "  --sun-placement <backlit|side|front|manual>  the sun relative to the camera,\n"
        "                   as the effect's Sun Placement (default manual: --sun-az).\n"
        "  --resolve-check  render, then regenerate the image from the accumulated\n"
        "                   radiance with ZERO new samples, and require the result to\n"
        "                   be byte-identical. That is what FieldCache's ResolveOnly\n"
        "                   decision promises an exposure change can do. Runs on\n"
        "                   both engines; with --gpu-band-rows it is also the only\n"
        "                   check on the accumulator's per-band offset.\n"
        "\n"
        "  Pareidolia (build 21): the hero's silhouette from a picture.\n"
        "  --shape <file|smiley|letter-f>  a binary PGM (P5), PPM (P6) or PAM (P7) --\n"
        "                   PAM carries alpha, the others are opaque -- or a built-in\n"
        "                   test matte. Turns the cumulus layer and the hero on.\n"
        "  --shape-channel <alpha|luma|inv-alpha|inv-luma>  which number is the matte\n"
        "                   (default alpha; the built-ins draw in alpha)\n"
        "  --shape-threshold <0..1>  the matte level that is the edge (default 0.5)\n"
        "  --shape-decay <0..1>      0 the shape, 1 the ordinary hero (default 0)\n"
        "  --shape-depth <x>         rim radius over half the smaller side (default 0.6)\n"
        "  --shape-billows <0..1>    the shape's billows over the hero's (default 0.2)\n"
        "  --shape-facing <camera|deg>  turn to the camera, or face a fixed orbit bearing\n"
        "                   (default camera)\n"
        "  --shape-dump <path>   also write the distance map as a PGM, to look at\n"
        "  --relief <file|dome>  a depth map (build 27) that carves the shape's face towards\n"
        "                   the eye, read like --shape; dome is a built-in round bulge\n"
        "  --relief-from <luma|inv-luma>  brighter is nearer, or darker (default luma)\n"
        "  --relief-depth <x>    the nearest part's lift over the smaller side (default 0.25)\n"
        "  --relief-softness <0..1>  the depth map's blur (default 0.35)\n"
        "  --relief-detail <0..1>  build 28: how much of the large form is taken away (default 0.5)\n"
        "  --relief-dump <path>  also write the built relief as a PGM, to look at\n"
        "\n"
        "  Local lights (build 29): AE's comp lights and a light layer, beside the sun.\n"
        "  --light <spec>   a light in WORLD metres, repeatable:\n"
        "                     point:x,y,z[,intensity[,radius]]\n"
        "                     spot:x,y,z,dx,dy,dz[,intensity[,radius[,cone[,feather]]]]\n"
        "                     parallel:dx,dy,dz[,intensity]  (the way its light travels)\n"
        "                   intensity is AE's over 100: 1 lights the cloud inside the\n"
        "                   radius as the sun at intensity 1 does (default radius 500 m)\n"
        "  --comp-light <spec>  the same in COMP PIXELS, through AE's default camera for a\n"
        "                   comp the frame's size, mapped as the effect maps a comp light\n"
        "                   under the orbit rig; radius in pixels (default 500, AE's)\n"
        "  --light-color <r,g,b>  linear, for the lights given after it (default 1,1,1)\n"
        "  --light-smooth <m>     AE's Smooth falloff past the radius, for the lights after it\n"
        "  --ambient <k>    AE's ambient light at intensity k (1 is 100%)\n"
        "  --sun-intensity <k>  the effect's Sun Intensity (default 1); 0 is a night sky\n"
        "  --light-layer <file|bolt>  a picture that glows, read like --shape, or a built-in\n"
        "                   lightning bolt. It covers the frame, laid on the cloud it shows.\n"
        "  --light-layer-strength <k>  (default 1)\n"
        "  --light-layer-depth <m>     behind (+) or in front of (-) the cloud's face (default 0)\n"
        "  --light-layer-flat          the sheet as one plane through the hero, as before (A/B)\n"
        "  --light-layer-dump <path>   also write the layer as a PPM, to look at\n"
        "\n"
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

// ---------------------------------------------------------------------------
// Pareidolia's pictures
// ---------------------------------------------------------------------------

// A picture as the effect would hand it over: premultiplied ARGB float, 0..1.
struct ShapeImage {
    int width = 0;
    int height = 0;
    std::vector<float> argb;

    ConstImageView view() const {
        ConstImageView v;
        v.data     = argb.data();
        v.width    = width;
        v.height   = height;
        v.rowBytes = static_cast<std::ptrdiff_t>(width) * 4 * sizeof(float);
        v.format   = PixelFormat::ARGB32F;
        return v;
    }
};

// ONE NETPBM TOKEN, skipping whitespace and comments.
bool readToken(FILE* f, char* out, int cap) {
    int c = std::fgetc(f);
    for (;;) {
        while (c == ' ' || c == '\t' || c == '\r' || c == '\n') c = std::fgetc(f);
        if (c != '#') break;
        while (c != '\n' && c != EOF) c = std::fgetc(f);
    }
    int n = 0;
    while (c != EOF && c != ' ' && c != '\t' && c != '\r' && c != '\n' && n < cap - 1) {
        out[n++] = static_cast<char>(c);
        c = std::fgetc(f);
    }
    out[n] = 0;
    return n > 0;
}

// Binary PGM, PPM and PAM, 8 or 16 bits. PAM's RGB_ALPHA and GRAYSCALE_ALPHA carry alpha,
// which is STRAIGHT in the file and premultiplied here, as AE's buffers are.
bool loadShapeImage(const char* path, ShapeImage& img) {
    FILE* f = std::fopen(path, "rb");
    if (!f) return false;
    char tok[64];
    if (!readToken(f, tok, sizeof tok)) { std::fclose(f); return false; }

    int w = 0, h = 0, maxval = 0, depth = 0;
    if (argIs(tok, "P5") || argIs(tok, "P6")) {
        depth = argIs(tok, "P5") ? 1 : 3;
        char a[32], b[32], c[32];
        if (!readToken(f, a, 32) || !readToken(f, b, 32) || !readToken(f, c, 32)) { std::fclose(f); return false; }
        w = std::atoi(a); h = std::atoi(b); maxval = std::atoi(c);
    } else if (argIs(tok, "P7")) {
        for (;;) {
            if (!readToken(f, tok, sizeof tok)) { std::fclose(f); return false; }
            if (argIs(tok, "ENDHDR")) break;
            char v[64];
            if (!readToken(f, v, sizeof v)) { std::fclose(f); return false; }
            if (argIs(tok, "WIDTH"))  w = std::atoi(v);
            if (argIs(tok, "HEIGHT")) h = std::atoi(v);
            if (argIs(tok, "DEPTH"))  depth = std::atoi(v);
            if (argIs(tok, "MAXVAL")) maxval = std::atoi(v);
        }
    } else {
        std::fclose(f);
        return false;
    }
    if (w <= 0 || h <= 0 || maxval <= 0 || maxval > 65535 || depth < 1 || depth > 4) {
        std::fclose(f);
        return false;
    }

    const int bytes = maxval > 255 ? 2 : 1;
    std::vector<unsigned char> raw(static_cast<size_t>(w) * h * depth * bytes);
    const size_t got = std::fread(raw.data(), 1, raw.size(), f);
    std::fclose(f);
    if (got != raw.size()) return false;

    img.width = w;
    img.height = h;
    img.argb.assign(static_cast<size_t>(w) * h * 4, 0.0f);
    for (size_t p = 0; p < static_cast<size_t>(w) * h; ++p) {
        float ch[4] = { 0, 0, 0, 1 };
        for (int k = 0; k < depth; ++k) {
            const size_t at = (p * depth + k) * bytes;
            const int v = bytes == 2 ? (raw[at] << 8) | raw[at + 1] : raw[at];
            ch[k] = static_cast<float>(v) / static_cast<float>(maxval);
        }
        float r, g, b, a;
        if (depth == 1)      { r = g = b = ch[0]; a = 1.0f; }
        else if (depth == 2) { r = g = b = ch[0]; a = ch[1]; }
        else                 { r = ch[0]; g = ch[1]; b = ch[2]; a = depth == 4 ? ch[3] : 1.0f; }
        img.argb[p * 4 + 0] = a;
        img.argb[p * 4 + 1] = r * a;
        img.argb[p * 4 + 2] = g * a;
        img.argb[p * 4 + 3] = b * a;
    }
    return true;
}

// THE BUILT-IN RELIEF (build 27): DOME, a round bulge over the whole frame, brightest in the
// middle and black at the corners -- opaque grey, so it is read as luminance. On a smiley
// it lifts the face's middle and leaves the eyes and mouth as they were cut.
bool builtinRelief(const char* name, ShapeImage& img) {
    if (!argIs(name, "dome")) return false;
    const int n = 512;
    img.width = n;
    img.height = n;
    img.argb.assign(static_cast<size_t>(n) * n * 4, 0.0f);
    for (int y = 0; y < n; ++y) {
        for (int x = 0; x < n; ++x) {
            const double cx = (x + 0.5) / n - 0.5, cy = (y + 0.5) / n - 0.5;
            const double r2 = (cx * cx + cy * cy) / 0.5;
            const float v = static_cast<float>(r2 < 1.0 ? std::sqrt(1.0 - r2) : 0.0);
            float* p = img.argb.data() + (static_cast<size_t>(y) * n + x) * 4;
            p[0] = 1.0f; p[1] = v; p[2] = v; p[3] = v;
        }
    }
    return true;
}

// THE BUILT-IN MATTES, drawn in alpha at 512 x 512 with 4 x 4 coverage per pixel, so the
// tests and the look renders need no file. A SMILEY is pareidolia's own test card: a face
// read from two holes and an arc. THE LETTER F is asymmetric both ways, so a mirrored or
// upside-down shape cannot pass for right.
bool builtinShape(const char* name, ShapeImage& img) {
    const bool smiley = argIs(name, "smiley");
    const bool letter = argIs(name, "letter-f");
    if (!smiley && !letter) return false;

    const int n = 512;
    img.width = n;
    img.height = n;
    img.argb.assign(static_cast<size_t>(n) * n * 4, 0.0f);

    auto insideAt = [&](double x, double y) -> bool {   // unit square, y DOWN
        if (letter) {
            const bool stem = x >= 0.25 && x <= 0.42 && y >= 0.08 && y <= 0.92;
            const bool top  = x >= 0.25 && x <= 0.78 && y >= 0.08 && y <= 0.24;
            const bool mid  = x >= 0.25 && x <= 0.64 && y >= 0.44 && y <= 0.58;
            return stem || top || mid;
        }
        const double cx = x - 0.5, cy = y - 0.5;
        if (cx * cx + cy * cy > 0.45 * 0.45) return false;                  // the head
        const double ex = std::fabs(cx) - 0.16, ey = cy + 0.12;
        if (ex * ex + ey * ey < 0.075 * 0.075) return false;                // the eyes
        const double my = cy - 0.02, mr = std::sqrt(cx * cx + my * my);
        if (my > 0.07 && mr > 0.20 && mr < 0.29) return false;              // the mouth
        return true;
    };

    for (int y = 0; y < n; ++y) {
        for (int x = 0; x < n; ++x) {
            int hits = 0;
            for (int j = 0; j < 4; ++j)
                for (int i = 0; i < 4; ++i)
                    hits += insideAt((x + (i + 0.5) / 4.0) / n, (y + (j + 0.5) / 4.0) / n) ? 1 : 0;
            const float a = hits / 16.0f;
            float* p = img.argb.data() + (static_cast<size_t>(y) * n + x) * 4;
            p[0] = a; p[1] = a; p[2] = a; p[3] = a;
        }
    }
    return true;
}

// ---------------------------------------------------------------------------
// Local lights (build 29)
// ---------------------------------------------------------------------------

// A LIGHT AS TYPED: its numbers in world metres or, for --comp-light, comp pixels, and the
// colour and Smooth falloff in force when it was given.
struct LightSpec {
    cloud::LightKind kind = cloud::LightKind::Point;
    double p[3] = { 0.0, 0.0, 0.0 };
    double d[3] = { 0.0, -1.0, 0.0 };
    float  intensity = 1.0f;
    float  radius    = 500.0f;
    float  cone      = 90.0f;
    float  feather   = 0.5f;
    float  color[3]  = { 1.0f, 1.0f, 1.0f };
    float  smooth    = 0.0f;
};

// point:x,y,z[,i[,r]]  spot:x,y,z,dx,dy,dz[,i[,r[,cone[,feather]]]]  parallel:dx,dy,dz[,i]
bool parseLightSpec(const char* text, LightSpec& s) {
    const char* colon = std::strchr(text, ':');
    if (!colon) return false;
    const std::string kind(text, colon);
    double v[10];
    int n = 0;
    const char* at = colon + 1;
    while (*at && n < 10) {
        char* end = nullptr;
        v[n++] = std::strtod(at, &end);
        if (end == at) return false;
        at = *end == ',' ? end + 1 : end;
        if (*end != ',' && *end != 0) return false;
    }
    if (kind == "point" && n >= 3) {
        s.kind = cloud::LightKind::Point;
        for (int k = 0; k < 3; ++k) s.p[k] = v[k];
        if (n > 3) s.intensity = static_cast<float>(v[3]);
        if (n > 4) s.radius    = static_cast<float>(v[4]);
        return true;
    }
    if (kind == "spot" && n >= 6) {
        s.kind = cloud::LightKind::Spot;
        for (int k = 0; k < 3; ++k) { s.p[k] = v[k]; s.d[k] = v[3 + k]; }
        if (n > 6) s.intensity = static_cast<float>(v[6]);
        if (n > 7) s.radius    = static_cast<float>(v[7]);
        if (n > 8) s.cone      = static_cast<float>(v[8]);
        if (n > 9) s.feather   = static_cast<float>(v[9]);
        return true;
    }
    if (kind == "parallel" && n >= 3) {
        s.kind = cloud::LightKind::Parallel;
        for (int k = 0; k < 3; ++k) s.d[k] = v[k];
        if (n > 3) s.intensity = static_cast<float>(v[3]);
        return true;
    }
    return false;
}

// THE BUILT-IN BOLT: a forked lightning channel, white-blue with a glow, over black, the
// size of the frame -- what Saber on a black solid hands the effect. Deterministic: a
// fixed stream of jitter, so the tests and the look renders see one bolt.
bool builtinBolt(const char* name, int w, int h, ShapeImage& img) {
    if (!argIs(name, "bolt")) return false;
    img.width = w;
    img.height = h;
    img.argb.assign(static_cast<size_t>(w) * h * 4, 0.0f);
    for (size_t p = 0; p < static_cast<size_t>(w) * h; ++p) img.argb[p * 4] = 1.0f;

    unsigned state = 0x5eedb017u;
    auto jitter = [&]() {
        state = state * 747796405u + 2891336453u;
        return static_cast<double>((state >> 8) & 0xffffff) / 16777216.0 - 0.5;
    };

    // A CHANNEL: from a to b in `steps` legs, each kink pushed sideways by up to `wander`.
    struct Seg { double x0, y0, x1, y1, core; };
    std::vector<Seg> segs;
    auto channel = [&](double ax, double ay, double bx, double by, int steps, double wander,
                       double core) {
        double px = ax, py = ay;
        for (int i = 1; i <= steps; ++i) {
            const double t = static_cast<double>(i) / steps;
            double x = ax + (bx - ax) * t, y = ay + (by - ay) * t;
            if (i < steps) x += jitter() * wander * w;
            segs.push_back({ px, py, x, y, core });
            px = x; py = y;
        }
    };
    channel(0.55 * w, 0.30 * h, 0.44 * w, 1.00 * h, 48, 0.035, 1.0);
    channel(0.52 * w, 0.52 * h, 0.66 * w, 0.78 * h, 18, 0.03, 0.55);
    channel(0.49 * w, 0.70 * h, 0.36 * w, 0.86 * h, 14, 0.025, 0.4);

    const double sigma = 0.004 * w;      // the glow
    const double coreR = 0.0012 * w;     // the channel
    const double reach = 6.0 * sigma;
    for (const Seg& s : segs) {
        const int x0 = std::max(0, static_cast<int>(std::floor(std::min(s.x0, s.x1) - reach)));
        const int x1 = std::min(w - 1, static_cast<int>(std::ceil(std::max(s.x0, s.x1) + reach)));
        const int y0 = std::max(0, static_cast<int>(std::floor(std::min(s.y0, s.y1) - reach)));
        const int y1 = std::min(h - 1, static_cast<int>(std::ceil(std::max(s.y0, s.y1) + reach)));
        const double dx = s.x1 - s.x0, dy = s.y1 - s.y0;
        const double len2 = dx * dx + dy * dy;
        for (int y = y0; y <= y1; ++y) {
            for (int x = x0; x <= x1; ++x) {
                const double qx = x + 0.5 - s.x0, qy = y + 0.5 - s.y0;
                const double t = len2 > 0.0 ? std::min(1.0, std::max(0.0, (qx * dx + qy * dy) / len2)) : 0.0;
                const double ex = qx - dx * t, ey = qy - dy * t;
                const double d = std::sqrt(ex * ex + ey * ey);
                const double v = s.core * (d < coreR ? 1.0 : 0.0) + 0.45 * s.core * std::exp(-d / sigma);
                float* p = img.argb.data() + (static_cast<size_t>(y) * w + x) * 4;
                const float r = static_cast<float>(std::min(1.0, v * 0.85));
                const float g = static_cast<float>(std::min(1.0, v * 0.90));
                const float b = static_cast<float>(std::min(1.0, v * 1.00));
                p[1] = std::max(p[1], r);
                p[2] = std::max(p[2], g);
                p[3] = std::max(p[3], b);
            }
        }
    }
    return true;
}

bool dumpLightLayer(const char* path, const ShapeImage& img) {
    std::vector<float> argb = img.argb;
    return writePpm(path, argb, img.width, img.height);
}

// The distance map as a picture: mid-grey at the edge, lighter inside, 4 texels a level.
bool dumpShapeMap(const char* path, const cloud::ShapeMap& m) {
    FILE* f = std::fopen(path, "wb");
    if (!f) return false;
    std::fprintf(f, "P5\n%d %d\n255\n", m.width, m.height);
    for (int j = m.height - 1; j >= 0; --j) {       // row 0 of the map is the bottom
        for (int i = 0; i < m.width; ++i) {
            const float d = m.texels[(static_cast<size_t>(j) * m.width + i) * 4];
            float v = 128.0f + d * 4.0f;
            v = v < 0.0f ? 0.0f : (v > 255.0f ? 255.0f : v);
            std::fputc(static_cast<int>(v), f);
        }
    }
    std::fclose(f);
    return true;
}

// The relief as a picture: black is the cushion's face, white the nearest part.
bool dumpReliefMap(const char* path, const cloud::ShapeMap& m) {
    FILE* f = std::fopen(path, "wb");
    if (!f) return false;
    std::fprintf(f, "P5\n%d %d\n255\n", m.width, m.height);
    for (int j = m.height - 1; j >= 0; --j) {       // row 0 of the map is the bottom
        for (int i = 0; i < m.width; ++i) {
            const float r = m.texels[(static_cast<size_t>(j) * m.width + i) * 4 + 3];
            const float v = r < 0.0f ? 0.0f : (r > 1.0f ? 1.0f : r);
            std::fputc(static_cast<int>(v * 255.0f + 0.5f), f);
        }
    }
    std::fclose(f);
    return true;
}

// An Organization mode by name or by number. Anything else is Cellular, which is what
// resolveOrganization makes of an out-of-range number too.
int32_t parseOrgMode(const char* s) {
    if (argIs(s, "rolls"))   return 1;
    if (argIs(s, "waves"))   return 2;
    if (argIs(s, "chaotic")) return 3;
    return static_cast<int32_t>(std::atoi(s));
}

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
// THE REFERENCE MAY BE LARGER THAN THE RENDER, AND THEN refX/refY SAY WHERE TO LOOK.
//
// That is the whole point of the window tests: render a sub-rect of a frame, then
// check it against THE SAME SUB-RECT of a render of the whole frame. Equal sizes with
// an offset of 0,0 is the ordinary golden comparison and is unchanged.
int comparePpm(const char* refPath, const std::vector<float>& argb,
               int width, int height, int tolerance, int refX = 0, int refY = 0) {
    std::vector<unsigned char> ref;
    int rw = 0, rh = 0;
    if (!readPpm(refPath, ref, rw, rh)) {
        std::fprintf(stderr, "could not read reference %s\n", refPath);
        return 1;
    }
    if (refX < 0 || refY < 0 || refX + width > rw || refY + height > rh) {
        std::fprintf(stderr,
                     "region out of range: reference is %dx%d, render is %dx%d at %d,%d\n",
                     rw, rh, width, height, refX, refY);
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
                const int want =
                    ref[(static_cast<size_t>(y + refY) * rw + (x + refX)) * 3 + c];
                const int d = got > want ? got - want : want - got;
                if (d > maxDiff) { maxDiff = d; worstX = x; worstY = y; }
                sumDiff += d;
            }
        }
    }

    const double mean = sumDiff / (static_cast<double>(width) * height * 3);
    std::printf("compare %s%s: max %d (at %d,%d), mean %.4f, tolerance %d -- %s\n",
                refPath,
                (refX || refY) ? " (region)" : "",
                maxDiff, worstX, worstY, mean, tolerance,
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

    // ===================================================================
    // THE DENOISER IS OFF HERE AND ON IN THE EFFECT, AND THE ASYMMETRY IS THE POINT.
    //
    // QualityParams::denoise defaults to TRUE because that is the right default for a
    // person using the plugin. mistytunec is not that -- PLAN.md calls it the test
    // harness rather than a feature -- and leaving it on by default would break the
    // two things this program exists to provide.
    //
    //   * TIER 2 WOULD DEPEND ON WHETHER tools/oidn/ EXISTS. The golden references are
    //     rendered by this binary. With the denoiser on, a machine that had fetched
    //     OIDN and one that had not would produce different references and disagree
    //     about every golden -- and the whole arrangement is built so a machine with
    //     neither Slang nor OIDN still builds and tests identically.
    //
    //   * A WINDOWED RENDER COULD NEVER MATCH THE FULL FRAME. determinism.window
    //     renders a sub-rect and requires it to equal that region of the whole
    //     picture. A denoiser is SPATIAL: the same pixel denoised with a window's
    //     worth of neighbours and with the whole frame's is legitimately a different
    //     pixel. That test would fail for a correct reason, which is the worst kind of
    //     failing test.
    //
    // So it is opt-in here, and --denoise exists so the path CAN be exercised from the
    // command line -- which is how it gets profiled without After Effects.
    // ===================================================================
    req.quality.denoise = false;

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
    int  sampleChunk     = 0;
    int  windowX = 0, windowY = 0, windowW = 0, windowH = 0;
    int  compareAtX = 0, compareAtY = 0;
    bool printDevice     = false;
    bool printHashes     = false;
    int  threads         = 0;      // 0 = let the renderer choose
    bool resolveCheck    = false;  // --resolve-check, see the end of render()
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

    // 180 IS THE IDENTITY CAMERA, which looks down -Z -- compass azimuth 180 in the
    // convention --sun-az uses. Keeping the default at the identity is what keeps the
    // golden scenes' matrix exactly what it was.
    float headingDegrees = 180.0f;

    // THE ORBIT RIG, off unless one of its flags is given, so every golden scene keeps
    // its camera. The eye height is --altitude's, read after the loop.
    cloud::OrbitControls orbit;
    bool useOrbit = false;

    // MANUAL BY DEFAULT HERE, where the effect defaults to Backlit: --sun-az has always
    // meant a world azimuth to this program, and the goldens are written with it.
    cloud::SunPlacement sunPlacement = cloud::SunPlacement::Manual;

    // PAREIDOLIA: the picture, and where to write its map for a look.
    const char* shapePath = nullptr;
    const char* shapeDump = nullptr;
    const char* reliefPath = nullptr;
    const char* reliefDump = nullptr;

    // LOCAL LIGHTS (build 29): as typed, placed after the camera.
    std::vector<LightSpec> worldLights;
    std::vector<LightSpec> compLights;
    float lightColor[3] = { 1.0f, 1.0f, 1.0f };
    float lightSmooth = 0.0f;
    float ambientIntensity = 0.0f;
    const char* lightLayerPath = nullptr;
    const char* lightLayerDump = nullptr;
    float lightLayerStrength = 1.0f;
    float lightLayerDepth = 0.0f;
    bool  lightLayerFlat = false;

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
        else if (argIs(a, "--sun-intensity") && hasNext) req.field.atmosphere.sunIntensity = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--ev") && hasNext)        req.view.exposureEV = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--agx"))                  req.view.agxTonemap = true;
        else if (argIs(a, "--denoise"))              req.quality.denoise = true;
        else if (argIs(a, "--denoise-amount") && hasNext) { req.quality.denoise = true; req.quality.denoiseAmount = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--linear"))               req.view.encodeSrgb = false;
        else if (argIs(a, "--pitch") && hasNext)     pitchDegrees = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--seed") && hasNext)      req.field.seed = static_cast<unsigned>(std::strtoul(argv[++i], nullptr, 0));
        else if (argIs(a, "--time") && hasNext)      req.field.timeSeconds = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--cpu"))                  forceCpu = true;
        else if (argIs(a, "--require-gpu"))          requireGpu = true;
        else if (argIs(a, "--gpu-band-rows") && hasNext) gpuBandRows = std::atoi(argv[++i]);
        else if (argIs(a, "--majorant") && hasNext)      req.quality.densityMajorant = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--sample-chunk") && hasNext)  sampleChunk = std::atoi(argv[++i]);
        else if (argIs(a, "--nee-scale") && hasNext)     req.neeTentativeScale = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--aerial") && hasNext)        req.aerialPerspective = std::atoi(argv[++i]) != 0;
        else if (argIs(a, "--no-air-shadows"))           req.field.atmosphere.cloudShadowsInMedium = false;
        else if (argIs(a, "--air-shadow-rays"))          req.airShadowMap = false;
        else if (argIs(a, "--air-map-res") && hasNext)   req.airMapResolution = std::atoi(argv[++i]);
        else if (argIs(a, "--sun-placement") && hasNext) {
            const char* v = argv[++i];
            sunPlacement = argIs(v, "backlit") ? cloud::SunPlacement::Backlit
                         : argIs(v, "side")    ? cloud::SunPlacement::SideLit
                         : argIs(v, "front")   ? cloud::SunPlacement::FrontLit
                                               : cloud::SunPlacement::Manual;
        }
        else if (argIs(a, "--heading") && hasNext)       headingDegrees = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--fov") && hasNext)           req.view.verticalFovDegrees = static_cast<float>(std::atof(argv[++i]));
        // WHERE THE EYE STANDS, in metres -- what the effect derives from the comp
        // camera's position and Camera Travel. Zero is the fixed observer the goldens use.
        else if (argIs(a, "--cam-x") && hasNext)         req.view.observerX = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--cam-z") && hasNext)         req.view.observerZ = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--altitude") && hasNext)      req.view.observerAltitude = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--bounces") && hasNext)       req.quality.maxBounces = std::atoi(argv[++i]);
        else if (argIs(a, "--shadow-handoff") && hasNext) req.quality.shadowHandoff = static_cast<cloud::Real>(std::atof(argv[++i]));
        else if (argIs(a, "--draft"))                    req.quality = cloud::draftQuality(req.quality);
        else if (argIs(a, "--pixel-stride") && hasNext)  req.quality.pixelStride = std::atoi(argv[++i]);
        else if (argIs(a, "--megakernel"))               req.stagedGpu = false;
        else if (argIs(a, "--conv-grid") && hasNext)     req.convectionGrid = std::atoi(argv[++i]) != 0;
        // The convection layer. Any of its settings turns it on, since setting one of
        // them on an absent layer would otherwise be a flag that silently does nothing.
        else if (argIs(a, "--cumulus"))                  req.field.convection.enabled = true;
        else if (argIs(a, "--no-ice"))                   req.field.ice.enabled = false;
        else if (argIs(a, "--polarity") && hasNext)      { req.field.convection.enabled = true; req.field.convection.polarity        = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--coverage") && hasNext)      { req.field.convection.enabled = true; req.field.convection.coverage        = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--instability") && hasNext)   { req.field.convection.enabled = true; req.field.convection.instability     = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--cell-size") && hasNext)     { req.field.convection.enabled = true; req.field.convection.cellSize        = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--inversion") && hasNext)     { req.field.convection.enabled = true; req.field.convection.inversionHeight = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--conv-density") && hasNext)  { req.field.convection.enabled = true; req.field.convection.density         = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--billow") && hasNext)        { req.field.convection.enabled = true; req.field.convection.billowAmount    = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--billow-scale") && hasNext)  { req.field.convection.enabled = true; req.field.convection.billowScale     = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--billow-octaves") && hasNext) req.field.convection.billowOctaves = std::atoi(argv[++i]);
        else if (argIs(a, "--humidity") && hasNext)      req.field.physics.surfaceHumidity = static_cast<float>(std::atof(argv[++i]));
        // THE ORGANIZATION GROUP, the cumulus layer's (which it turns on) and the ice's.
        else if (argIs(a, "--org") && hasNext)           { req.field.convection.enabled = true; req.field.convection.organization.mode = parseOrgMode(argv[++i]); }
        else if (argIs(a, "--aspect") && hasNext)        { req.field.convection.enabled = true; req.field.convection.organization.aspectRatio   = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--rows-along") && hasNext)    { req.field.convection.enabled = true; req.field.convection.organization.alignment     = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--coherence") && hasNext)     { req.field.convection.enabled = true; req.field.convection.organization.coherence     = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--wave-length") && hasNext)   { req.field.convection.enabled = true; req.field.convection.organization.waveLength    = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--wave-amp") && hasNext)      { req.field.convection.enabled = true; req.field.convection.organization.waveAmplitude = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--crests-along") && hasNext)  { req.field.convection.enabled = true; req.field.convection.organization.waveAngle     = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--gap") && hasNext)           { req.field.convection.enabled = true; req.field.convection.organization.gapFraction   = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--lacunarity") && hasNext)    { req.field.convection.enabled = true; req.field.convection.organization.lacunarity    = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--ice-org") && hasNext)          req.field.ice.organization.mode          = parseOrgMode(argv[++i]);
        else if (argIs(a, "--ice-aspect") && hasNext)       req.field.ice.organization.aspectRatio   = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--ice-rows-along") && hasNext)   req.field.ice.organization.alignment     = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--ice-coherence") && hasNext)    req.field.ice.organization.coherence     = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--ice-wave-length") && hasNext)  req.field.ice.organization.waveLength    = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--ice-wave-amp") && hasNext)     req.field.ice.organization.waveAmplitude = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--ice-crests-along") && hasNext) req.field.ice.organization.waveAngle     = static_cast<float>(std::atof(argv[++i]));
        // THE HERO. --hero 1 is with the field, 2 is alone; the rest place and size it.
        else if (argIs(a, "--hero") && hasNext)          { req.field.convection.enabled = true; req.field.convection.heroMode = std::atoi(argv[++i]); }
        else if (argIs(a, "--hero-x") && hasNext)        req.field.convection.heroX         = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--hero-z") && hasNext)        req.field.convection.heroZ         = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--hero-width") && hasNext)    req.field.convection.heroWidth     = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--hero-height") && hasNext)   req.field.convection.heroHeight    = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--hero-var") && hasNext)      req.field.convection.heroVariation = static_cast<float>(std::atof(argv[++i]));
        // HERO CONNECTION (build 22): the group round the hero, and whether it rides the wind.
        else if (argIs(a, "--hero-connection") && hasNext) req.field.convection.heroConnection = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--hero-drift"))               req.field.convection.heroDrift = true;
        // MAMMA (build 23): pouches under the layer.
        else if (argIs(a, "--mamma") && hasNext)         { req.field.convection.enabled = true; req.field.convection.mamma = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--pouch-size") && hasNext)    req.field.convection.pouchSize = static_cast<float>(std::atof(argv[++i]));
        // PILEUS AND VELUM (build 24): the hero's cap and veil.
        else if (argIs(a, "--pileus") && hasNext)        req.field.convection.pileus      = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--pileus-gap") && hasNext)    req.field.convection.pileusGap   = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--velum") && hasNext)         req.field.convection.velum       = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--velum-height") && hasNext)  req.field.convection.velumHeight = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--render-distance") && hasNext) req.view.renderDistance = static_cast<float>(std::atof(argv[++i]));
        else if ((argIs(a, "--light") || argIs(a, "--comp-light")) && hasNext) {
            LightSpec s;
            for (int k = 0; k < 3; ++k) s.color[k] = lightColor[k];
            s.smooth = lightSmooth;
            const bool comp = argIs(a, "--comp-light");
            if (!parseLightSpec(argv[++i], s)) {
                std::fprintf(stderr, "could not read %s %s\n", a, argv[i]);
                return 2;
            }
            (comp ? compLights : worldLights).push_back(s);
        }
        else if (argIs(a, "--light-color") && hasNext) {
            if (std::sscanf(argv[++i], "%f,%f,%f", &lightColor[0], &lightColor[1], &lightColor[2]) != 3) {
                std::fprintf(stderr, "--light-color wants r,g,b\n");
                return 2;
            }
        }
        else if (argIs(a, "--light-smooth") && hasNext)          lightSmooth        = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--ambient") && hasNext)               ambientIntensity   = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--light-layer") && hasNext)           lightLayerPath     = argv[++i];
        else if (argIs(a, "--light-layer-dump") && hasNext)      lightLayerDump     = argv[++i];
        else if (argIs(a, "--light-layer-strength") && hasNext)  lightLayerStrength = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--light-layer-depth") && hasNext)     lightLayerDepth    = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--light-layer-flat"))                  lightLayerFlat     = true;
        else if (argIs(a, "--shape") && hasNext)           shapePath = argv[++i];
        else if (argIs(a, "--shape-dump") && hasNext)      shapeDump = argv[++i];
        else if (argIs(a, "--relief") && hasNext)          reliefPath = argv[++i];
        else if (argIs(a, "--relief-dump") && hasNext)     reliefDump = argv[++i];
        else if (argIs(a, "--relief-from") && hasNext)
            req.field.convection.pareidolia.reliefChannel = argIs(argv[++i], "inv-luma") ? 1 : 0;
        else if (argIs(a, "--relief-depth") && hasNext)    req.field.convection.pareidolia.reliefDepth    = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--relief-softness") && hasNext) req.field.convection.pareidolia.reliefSoftness = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--relief-detail") && hasNext)   req.field.convection.pareidolia.reliefDetail   = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--shape-channel") && hasNext) {
            const char* v = argv[++i];
            req.field.convection.pareidolia.channel = argIs(v, "luma") ? 1 : argIs(v, "inv-alpha") ? 2
                                                    : argIs(v, "inv-luma") ? 3 : 0;
        }
        else if (argIs(a, "--shape-threshold") && hasNext) req.field.convection.pareidolia.threshold = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--shape-decay") && hasNext)     req.field.convection.pareidolia.decay     = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--shape-depth") && hasNext)     req.field.convection.pareidolia.depth     = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--shape-billows") && hasNext)   req.field.convection.pareidolia.billows   = static_cast<float>(std::atof(argv[++i]));
        else if (argIs(a, "--shape-facing") && hasNext) {
            const char* v = argv[++i];
            if (argIs(v, "camera")) {
                req.field.convection.pareidolia.facing = 0;
            } else {
                req.field.convection.pareidolia.facing  = 1;
                req.field.convection.pareidolia.bearing = static_cast<float>(std::atof(v));
            }
        }
        else if (argIs(a, "--orbit") && hasNext)         { useOrbit = true; orbit.orbitDegrees  = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--distance") && hasNext)      { useOrbit = true; orbit.distance      = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--look-at") && hasNext)       { useOrbit = true; orbit.lookAt        = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--tilt") && hasNext)          { useOrbit = true; orbit.tiltDegrees   = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--pan") && hasNext)           { useOrbit = true; orbit.panDegrees    = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--roll") && hasNext)          { useOrbit = true; orbit.rollDegrees   = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--focal") && hasNext)         { useOrbit = true; orbit.focalLengthMm = static_cast<float>(std::atof(argv[++i])); }
        else if (argIs(a, "--window") && i + 4 < argc) {
            windowX = std::atoi(argv[++i]);
            windowY = std::atoi(argv[++i]);
            windowW = std::atoi(argv[++i]);
            windowH = std::atoi(argv[++i]);
        }
        else if (argIs(a, "--compare-at") && i + 2 < argc) {
            compareAtX = std::atoi(argv[++i]);
            compareAtY = std::atoi(argv[++i]);
        }
        else if (argIs(a, "--threads") && hasNext)   threads = std::atoi(argv[++i]);
        else if (argIs(a, "--resolve-check"))       resolveCheck = true;
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
        // TWO HASHES, NOT ONE. `sample` is what restarts accumulation; `resolve` is
        // what only re-runs the output transform. Printing them separately is what
        // makes the split checkable from outside -- drag exposure and only the second
        // should move.
        std::printf("sample: 0x%016llx\n",
                    static_cast<unsigned long long>(sim::samplingHash(req.view, req.quality)));
        std::printf("resolv: 0x%016llx\n",
                    static_cast<unsigned long long>(sim::resolveHash(req.view, req.quality)));
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
    // PITCH THEN HEADING: the camera tilts up about its own X axis, then turns about the
    // world's Y. Camera-to-world, row-major, as ViewParams documents -- Ry(theta) * Rx(pitch),
    // where theta = heading - 180 because the identity camera already faces azimuth 180.
    // Left untouched at the defaults, so the golden scenes keep the exact identity.
    // A PICTURE MEANS A HERO TO PUT IT ON, before the orbit rig aims at the hero's height.
    if (shapePath) {
        req.field.convection.enabled = true;
        if (req.field.convection.heroMode == 0) req.field.convection.heroMode = 1;
    }

    if (useOrbit) {
        // THE SAME CALL THE EFFECT MAKES, after the frame size is known, since the
        // field of view depends on its aspect.
        orbit.eyeAltitude = req.view.observerAltitude;
        cloud::orbitView(req.field, orbit, req.view);
        std::printf("orbit: eye (%.1f, %.1f, %.1f) m, vertical fov %.1f deg\n",
                    static_cast<double>(req.view.observerX),
                    static_cast<double>(req.view.observerAltitude),
                    static_cast<double>(req.view.observerZ),
                    static_cast<double>(req.view.verticalFovDegrees));
    } else if (pitchDegrees != 0.0f || headingDegrees != 180.0f) {
        const float rad = pitchDegrees * 0.01745329252f;
        const float cc  = std::cos(rad);
        const float ss  = std::sin(rad);
        const float yaw = (headingDegrees - 180.0f) * 0.01745329252f;
        const float cy  = std::cos(yaw);
        const float sy  = std::sin(yaw);
        const float m[16] = {
            cy,    sy * ss,  sy * cc,  0.0f,
            0.0f,  cc,       -ss,      0.0f,
            -sy,   cy * ss,  cy * cc,  0.0f,
            0.0f,  0.0f,     0.0f,     1.0f
        };
        for (int i = 0; i < 16; ++i) req.view.cameraToWorld[i] = m[i];
    }

    // THE SHAPE'S FACING, AFTER THE CAMERA, as the effect places it -- and the picture's
    // map, which the request points at for the rest of the run.
    ShapeImage shapeImage;
    cloud::ShapeMap shapeMap;
    if (shapePath) {
        if (!builtinShape(shapePath, shapeImage) && !loadShapeImage(shapePath, shapeImage)) {
            std::fprintf(stderr, "could not read --shape %s (binary PGM, PPM or PAM, or a built-in)\n",
                         shapePath);
            return 2;
        }
        const cloud::ShapeChannel channel =
            static_cast<cloud::ShapeChannel>(req.field.convection.pareidolia.channel & 3);
        // THE RELIEF'S DEPTH MAP (build 27), when one is named. It must outlive the build only.
        ShapeImage reliefImage;
        cloud::ReliefSource relief;
        if (reliefPath) {
            if (!builtinRelief(reliefPath, reliefImage) && !loadShapeImage(reliefPath, reliefImage)) {
                std::fprintf(stderr, "could not read --relief %s (binary PGM, PPM or PAM, or dome)\n",
                             reliefPath);
                return 2;
            }
            relief.view     = reliefImage.view();
            relief.inverted = req.field.convection.pareidolia.reliefChannel == 1;
            relief.softness = req.field.convection.pareidolia.reliefSoftness;
            relief.detail   = req.field.convection.pareidolia.reliefDetail;
        }
        // TIMED, because the effect pays this on every frame of an animated source.
        const auto buildStart = std::chrono::steady_clock::now();
        const bool built = cloud::buildShapeMap(shapeImage.view(), channel,
                                                req.field.convection.pareidolia.threshold, shapeMap,
                                                reliefPath ? &relief : nullptr);
        const double buildMs = std::chrono::duration<double, std::milli>(
                                   std::chrono::steady_clock::now() - buildStart).count();
        std::printf("shape: %dx%d source -> map in %.1f ms\n", shapeImage.width, shapeImage.height,
                    buildMs);
        if (!built) {
            std::printf("shape: nothing in %s reaches the threshold -- no shape\n", shapePath);
        } else {
            req.shapeMap = &shapeMap;
            if (shapeDump) dumpShapeMap(shapeDump, shapeMap);
            if (reliefDump) dumpReliefMap(reliefDump, shapeMap);
            if (reliefPath) {
                std::printf("relief: %s, steepest step %.4f a texel\n",
                            shapeMap.hasRelief ? "built" : "FLAT -- none",
                            static_cast<double>(shapeMap.reliefSlope));
            }
        }
        cloud::Real heroX = 0, heroZ = 0;
        cloud::heroPositionNow(req.field, heroX, heroZ);
        cloud::placeShape(req.field.convection.pareidolia, req.view, heroX, heroZ);

        cloud::ConvectionDerived cd;
        cloud::deriveConvection(req.field, cd);
        const cloud::ShapeGeometry g = cloud::resolveShape(req.shapeMap,
                                                           req.field.convection.pareidolia, cd);
        std::printf("shape: %dx%d map, %.0f x %.0f m, rims %.0f m, relief %.0f m (slope %.3f), "
                    "facing %.1f deg%s\n",
                    shapeMap.width, shapeMap.height,
                    static_cast<double>(g.widthMetres), static_cast<double>(g.heightMetres),
                    static_cast<double>(g.round),
                    static_cast<double>(g.reliefHeight), static_cast<double>(g.reliefSlope),
                    static_cast<double>(req.field.convection.pareidolia.bearing),
                    g.on ? "" : " (OFF: no map or no hero)");
    }

    // THE SUN, PLACED AFTER THE CAMERA, as the effect places it.
    req.field.atmosphere.sunAzimuth =
        cloud::placedSunAzimuth(sunPlacement, req.field.atmosphere.sunAzimuth, req.view);
    if (sunPlacement != cloud::SunPlacement::Manual) {
        std::printf("sun: azimuth %.1f deg from the placement\n",
                    static_cast<double>(req.field.atmosphere.sunAzimuth));
    }

    // THE LOCAL LIGHTS (build 29), after the camera, as the effect places them: comp lights
    // through AE's default camera for a comp the frame's size, under the orbit rig's
    // mapping, and the light layer at the hero's depth.
    ShapeImage lightImage;
    cloud::LightSheet lightSheet;
    cloud::SheetPlacement lightPlace;
    cloud::LightSet lightSet;
    if (!worldLights.empty() || !compLights.empty() || ambientIntensity > 0.0f || lightLayerPath) {
        const cloud::LightAnchor anchor = cloud::lightAnchor(req.field, req.view);
        double cam[16];
        double zoom = 0.0;
        cloud::defaultCompCamera(req.view.widthPx, req.view.heightPx, cam, zoom);
        const cloud::CompLightFrame frame = cloud::compLightFrame(
            cam, zoom, req.view.heightPx, false, 1.0, req.view, anchor);

        std::vector<cloud::LocalLight> lights;
        auto add = [&](const LightSpec& s, bool comp) {
            cloud::LocalLight L;
            L.kind = s.kind;
            L.intensity = s.intensity;
            L.coneAngleDeg = s.cone;
            L.coneFeather = s.feather;
            for (int k = 0; k < 3; ++k) L.color[k] = s.color[k];
            if (comp) {
                cloud::compPointToWorld(frame, req.view, s.p, L.position);
                cloud::compDirectionToWorld(frame, req.view, s.d, L.direction);
                L.radius = static_cast<float>(s.radius * frame.along);
                L.smoothFalloff = static_cast<float>(s.smooth * frame.along);
            } else {
                for (int k = 0; k < 3; ++k) {
                    L.position[k] = static_cast<float>(s.p[k]);
                    L.direction[k] = static_cast<float>(s.d[k]);
                }
                L.radius = s.radius;
                L.smoothFalloff = s.smooth;
            }
            std::printf("light: %s at (%.0f, %.0f, %.0f) m, intensity %.2f, radius %.0f m\n",
                        L.kind == cloud::LightKind::Spot ? "spot"
                        : L.kind == cloud::LightKind::Parallel ? "parallel" : "point",
                        static_cast<double>(L.position[0]), static_cast<double>(L.position[1]),
                        static_cast<double>(L.position[2]), static_cast<double>(L.intensity),
                        static_cast<double>(L.radius));
            lights.push_back(L);
        };
        for (const LightSpec& s : worldLights) add(s, false);
        for (const LightSpec& s : compLights) add(s, true);

        bool haveSheet = false;
        if (lightLayerPath) {
            if (!builtinBolt(lightLayerPath, req.view.widthPx, req.view.heightPx, lightImage) &&
                !loadShapeImage(lightLayerPath, lightImage)) {
                std::fprintf(stderr, "could not read --light-layer %s (binary PGM, PPM or PAM, or bolt)\n",
                             lightLayerPath);
                return 2;
            }
            if (lightLayerDump) dumpLightLayer(lightLayerDump, lightImage);
            haveSheet = cloud::buildLightSheet(lightImage.view(), req.view.encodeSrgb,
                                               cloud::kLightSheetMaxSide, lightSheet);
            std::printf("light layer: %dx%d -> %dx%d sheet%s\n",
                        lightImage.width, lightImage.height, lightSheet.width, lightSheet.height,
                        haveSheet ? "" : " -- NOTHING GLOWS, no sheet");
            if (haveSheet && lightLayerFlat) {
                lightPlace = cloud::placeLightSheet(req.view,
                                                    std::max(10.0f, anchor.depth + lightLayerDepth),
                                                    lightSheet.width, lightSheet.height);
                std::printf("light layer: flat, at %.0f m\n",
                            static_cast<double>(lightPlace.planeDepth));
            } else if (haveSheet) {
                // LAID ON THE CLOUD, as the effect lays it: probed from this request's field,
                // the shape included, before it renders.
                lightPlace = cloud::placeLightSheet(req.view, anchor.depth, lightSheet.width,
                                                    lightSheet.height);
                const auto probeStart = std::chrono::steady_clock::now();
                cloud::SurfaceProbe probe;
                cloud::surfaceProbeGrid(lightSheet, probe.width, probe.height);
                probe.farDepth = anchor.depth + anchor.reach;
                const std::vector<unsigned char> need =
                    cloud::surfaceProbeMask(lightSheet, probe.width, probe.height);
                kernel::probeSurfaceCpu(req, need, probe, threads);
                cloud::conformLightSheet(lightSheet, probe, anchor.depth, lightLayerDepth,
                                         lightPlace);
                const double probeMs = std::chrono::duration<double, std::milli>(
                                           std::chrono::steady_clock::now() - probeStart).count();

                // WHERE THE LIT TEXELS STAND, as a range of depths: the face the probe found.
                int asked = 0, seen = 0;
                for (size_t k = 0; k < need.size(); ++k) {
                    if (!need[k]) continue;
                    ++asked;
                    if (probe.hit[k] > 0.5f) ++seen;
                }
                std::vector<float> depths;
                for (size_t t = 0; t < lightPlace.scale.size(); ++t) {
                    const float* c = &lightSheet.rgb[t * 3];
                    if (c[0] + c[1] + c[2] > 0.0f)
                        depths.push_back(lightPlace.scale[t] * lightPlace.planeDepth);
                }
                std::sort(depths.begin(), depths.end());
                const auto at = [&](double f) {
                    return depths.empty() ? 0.0
                         : static_cast<double>(depths[static_cast<size_t>(f * (depths.size() - 1))]);
                };
                std::printf("light layer: laid on the cloud from %d of %dx%d probe points (%d see it)"
                            " in %.1f ms; lit texels %.0f / %.0f / %.0f m deep (min / median / max),"
                            " the plane at %.0f m, none past %.0f m\n",
                            asked, probe.width, probe.height, seen, probeMs, at(0.0), at(0.5),
                            at(1.0), static_cast<double>(lightPlace.planeDepth),
                            static_cast<double>(probe.farDepth));
            }
        }

        const float ambient[3] = { ambientIntensity * cloud::kAmbientRadiancePerIntensity,
                                   ambientIntensity * cloud::kAmbientRadiancePerIntensity,
                                   ambientIntensity * cloud::kAmbientRadiancePerIntensity };
        cloud::packLightSet(lights, ambient, haveSheet ? &lightSheet : nullptr,
                            haveSheet ? &lightPlace : nullptr, lightLayerStrength, anchor, lightSet);
        req.lightSet = &lightSet;
        std::printf("lights: %d packed, anchor %.0f m deep, %zu floats\n", lightSet.count,
                    static_cast<double>(anchor.depth), lightSet.packed.size());
    }

    // THE WINDOW, WHICH IS WHAT AFTER EFFECTS ACTUALLY ASKS FOR MOST OF THE TIME.
    //
    // -w/-h are the FRAME: the whole picture the lens sees. Without --window the
    // buffer is that same frame and the origin is 0,0, which is every render this
    // program did before the option existed.
    //
    // WITH IT, THE BUFFER IS A SUB-RECT AND THE FRAME IS NOT, which is the one shape
    // this project keeps getting wrong. Three separate bugs -- the requested rect
    // stored as the frame, the layer size stored at full resolution, and the origin
    // read from output_origin_x/y -- were all the same mistake, all shipped, and all
    // found by a human looking at After Effects because nothing here could ask for a
    // window. Now it can.
    int destW = req.view.widthPx;
    int destH = req.view.heightPx;

    if (windowW > 0 && windowH > 0) {
        destW = windowW;
        destH = windowH;
        req.view.originX = windowX;
        req.view.originY = windowY;
    }

    // TIGHTLY PACKED, UNLIKE AE'S WORLDS. AE pads rows and the kernel is told the
    // pitch separately for exactly that reason; here there is no padding, so pitch
    // equals width. Writing it out rather than leaving it zero is what keeps the two
    // callers' assumptions visible side by side.
    std::vector<float> pixels(static_cast<size_t>(destW) *
                              static_cast<size_t>(destH) * 4, 0.0f);

    req.dest.data     = pixels.data();
    req.dest.widthPx  = destW;
    req.dest.heightPx = destH;
    req.dest.pitchPx  = destW;
    req.dest.order    = kernel::ChannelOrder::ARGB;

    // DRAFT'S PIXEL STRIDE, AS THE EFFECT RUNS IT: traced into a buffer 1/stride the size,
    // denoised there, then scaled up into `pixels` before the transform. See Upscale.h.
    const int stride = req.quality.pixelStride > 1 ? std::min(req.quality.pixelStride, 8) : 1;
    std::vector<float> traced;
    if (stride > 1) {
        if (resolveCheck) {
            std::fprintf(stderr, "--resolve-check does not take a pixel stride\n");
            return 2;
        }
        const int tw = cloud::strideExtent(destW, stride);
        const int th = cloud::strideExtent(destH, stride);
        traced.assign(static_cast<size_t>(tw) * static_cast<size_t>(th) * 4, 0.0f);
        req.dest.data     = traced.data();
        req.dest.widthPx  = tw;
        req.dest.heightPx = th;
        req.dest.pitchPx  = tw;
    }

    req.firstSample        = 0;
    req.sampleCount        = req.quality.samplesPerPixel;
    req.samplesAlreadyDone = 0;
    req.accumulator        = nullptr;

    // THE SAMPLE SPLIT, WHICH THE EFFECT DERIVES AND THIS PROGRAM TAKES AS AN OPTION.
    //
    // In the effect the chunk size comes from samplesPerLaunch() so that no launch
    // approaches the display-driver timeout. Here it is an argument instead, because
    // the thing worth testing is not the policy but the ARITHMETIC underneath it: that
    // a frame split into N pieces and accumulated agrees with the same frame rendered
    // whole. A test that could only reach the split by asking for 65536 samples would
    // take minutes to say so.
    const int totalSamples = req.quality.samplesPerPixel;
    const int chunk = (sampleChunk > 0 && sampleChunk < totalSamples)
                    ? sampleChunk : totalSamples;

    // CHUNKS ARE ALWAYS INNER, BANDS ALWAYS OUTER, ON BOTH PATHS.
    //
    // The CUDA accumulator is ONE band-sized buffer reused for every band, so a band's
    // launches have to be consecutive. Swapping the loops would have band 2's first
    // chunk overwrite the partial sums band 1 was still adding to -- which shows up as
    // horizontal stripes of differently-converged sky and looks like a sampling bug.

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

    // One band's worth of chunks. Sets the sample window on `req` and launches for
    // each piece; rowEnd <= 0 means the whole frame, exactly as the kernel takes it.
    const auto renderGpuBand = [&](int y, int y1) {
        for (int s0 = 0; s0 < totalSamples; s0 += chunk) {
            req.firstSample        = s0;
            req.sampleCount        = std::min(chunk, totalSamples - s0);
            req.samplesAlreadyDone = s0;
            if (!kernel::renderCudaToHost(req, y, y1)) return false;
        }
        return true;
    };

    if (!forceCpu && kernel::cudaAvailable()) {
        if (gpuBandRows <= 0) {
            renderedOnGpu = renderGpuBand(0, 0);
        } else {
            renderedOnGpu = true;
            // BANDS ARE ROWS OF THE BUFFER, NOT OF THE FRAME. With --window the two
            // differ, and banding the frame would walk off the end of a smaller
            // buffer.
            for (int y = 0; y < req.dest.heightPx; y += gpuBandRows) {
                int y1 = y + gpuBandRows;
                if (y1 > req.dest.heightPx) y1 = req.dest.heightPx;
                if (!renderGpuBand(y, y1)) { renderedOnGpu = false; break; }
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
        for (int s0 = 0; s0 < totalSamples; s0 += chunk) {
            req.firstSample        = s0;
            req.sampleCount        = std::min(chunk, totalSamples - s0);
            req.samplesAlreadyDone = s0;
            kernel::renderCpu(req, threads);
        }
    }

    // ---------------------------------------------------------------------
    // THE FRAME IS COMPLETE, SO THE OUTPUT TRANSFORM RUNS -- ONCE, HERE.
    //
    // `pixels` holds LINEAR radiance until this line: exposure, AgX and the sRGB
    // transfer curve all left renderPixel when the denoiser turned out to need a
    // linear buffer. See KernelApi.h.
    //
    // ALWAYS transformCpu, EVEN AFTER A GPU RENDER, because renderCudaToHost has
    // already copied the result into this program's own host memory. Which engine
    // traced the rays does not decide where the destination lives.
    //
    // AFTER THE FALLBACK, NOT INSIDE EITHER BRANCH. A GPU render that failed partway
    // and finished on the CPU must be transformed once in total, and putting this
    // in both branches is how it would be transformed twice.
    // ---------------------------------------------------------------------
    // --threads IS PASSED HERE TOO, AND THAT MAKES determinism.threadCount COVER THIS
    // PASS FOR FREE. That test renders the same scene at one worker and at eight and
    // demands byte-identical output; feeding the same count to the transform extends
    // it from "the render is thread-count invariant" to "the whole pipeline is",
    // which is the claim the effect actually relies on under multi-frame rendering.
    // BEFORE THE TRANSFORM AND AFTER EVERY SAMPLE -- see KernelApi.h. A no-op unless
    // --denoise was given, and a no-op with a reported reason if OIDN is not installed.
    kernel::denoiseCpu(req);
    if (stride > 1) {
        cloud::upscaleFromStride(traced.data(), req.dest.widthPx, req.dest.heightPx,
                                 req.dest.pitchPx, pixels.data(), destW, destH, destW, stride);
        req.dest.data     = pixels.data();
        req.dest.widthPx  = destW;
        req.dest.heightPx = destH;
        req.dest.pitchPx  = destW;
    }
    kernel::transformCpu(req, threads);

    // ---------------------------------------------------------------------
    // THE RESOLVE PATH, CHECKED RATHER THAN ASSUMED TO EXIST.
    //
    // FieldCache's ResolveOnly decision claims that when only the exposure, tonemap
    // or encoding changed, the picture can be regenerated from the accumulated
    // radiance without tracing a single ray. THAT CLAIM NEEDS NO NEW KERNEL CODE,
    // which is the finding worth pinning: renderPixel with sampleCount == 0 adds
    // nothing to the accumulator, divides it by samplesAlreadyDone and writes the
    // mean -- which is exactly a resolve. The transform pass then finishes it.
    //
    // SO THIS RE-RENDERS WITH ZERO SAMPLES AND DEMANDS THE IDENTICAL IMAGE. If the
    // two ever diverge, the ResolveOnly branch is silently showing a different
    // picture from the one the same parameters would render -- which is the single
    // worst failure a cache can have, because it only appears after an edit and
    // looks like a rendering bug rather than a caching one.
    //
    // BYTE-IDENTICAL IS THE RIGHT BAR, not a tolerance. Both paths divide the same
    // accumulator by the same integer and run the same transform, so anything other
    // than equality means one of those three is not the same.
    if (resolveCheck) {
        std::vector<float> rendered(pixels);

        kernel::RenderRequest resolve = req;
        resolve.firstSample        = totalSamples;
        resolve.sampleCount        = 0;
        resolve.samplesAlreadyDone = totalSamples;

        // ===================================================================
        // THE GPU RESOLVES TOO NOW, AND THAT IS WHAT MAKES THIS TEST ABLE TO FAIL.
        //
        // It used to refuse a GPU render -- "needs the CPU accumulator" -- because the
        // device accumulator was BAND-SIZED: each band overwrote the last, so there was
        // no frame left to resolve from. It is frame-sized now, and each band is handed
        // the slice that starts at its own first row.
        //
        // THE BANDS ARE WALKED AGAIN IN THE SAME ORDER, deliberately. A resolve that
        // asked for the whole frame in one launch would read the accumulator correctly
        // whatever the per-band offset was, and would therefore prove nothing about it.
        // Walking the bands is what makes a wrong offset show up: band 1 would resolve
        // from band 0's samples, and the picture would repeat the top of the frame.
        //
        // That is the fourth appearance of the band-as-window hazard in this project,
        // and the first time a test for it exists before a human found it in the host.
        // ===================================================================
        if (renderedOnGpu) {
            bool ok = true;
            if (gpuBandRows <= 0) {
                ok = kernel::renderCudaToHost(resolve, 0, 0);
            } else {
                for (int y = 0; y < resolve.dest.heightPx && ok; y += gpuBandRows) {
                    int y1 = y + gpuBandRows;
                    if (y1 > resolve.dest.heightPx) y1 = resolve.dest.heightPx;
                    ok = kernel::renderCudaToHost(resolve, y, y1);
                }
            }
            if (!ok) {
                const char* why = kernel::lastCudaError();
                std::fprintf(stderr, "resolve-check: the GPU resolve failed (%s)\n",
                             why && why[0] ? why : "no detail");
                return 3;
            }
        } else {
            kernel::renderCpu(resolve, threads);
        }
        // THE RESOLVE HAS TO DENOISE TOO, or this compares a denoised first render
        // against an undenoised second one and reports a difference that is the test's
        // own doing. It also makes the check mean something stronger: the denoise is
        // part of the resolve, so ResolveOnly's promise covers it.
        kernel::denoiseCpu(resolve);
        kernel::transformCpu(resolve, threads);

        size_t differing = 0;
        size_t firstAt   = 0;
        for (size_t i = 0; i < rendered.size(); ++i) {
            if (rendered[i] != pixels[i]) {
                if (differing == 0) firstAt = i;
                ++differing;
            }
        }

        if (differing != 0) {
            std::printf("resolve-check: FAIL -- %zu of %zu floats differ, "
                        "first at %zu (%.9g vs %.9g)\n",
                        differing, rendered.size(), firstAt,
                        static_cast<double>(rendered[firstAt]),
                        static_cast<double>(pixels[firstAt]));
            return 4;
        }
        std::printf("resolve-check: ok -- %zu floats identical, "
                    "re-resolved from %d accumulated samples without tracing\n",
                    rendered.size(), totalSamples);
        return 0;
    }

    if (comparePath) {
        // WHICH PATH PRODUCED THE PIXELS, PRINTED BESIDE THE VERDICT. A golden
        // comparison that does not say what it compared is a number without a claim.
        std::printf("rendered on the %s path\n",
                    renderedOnGpu ? "GPU (CUDA)" : "CPU reference");
        return comparePpm(comparePath, pixels, destW, destH, tolerance,
                          compareAtX, compareAtY);
    }

    if (!writePpm(outPath, pixels, destW, destH)) {
        std::fprintf(stderr, "could not write %s\n", outPath);
        return 1;
    }

    std::printf("wrote %s (%dx%d, %d spp)\n",
                outPath, destW, destH, req.quality.samplesPerPixel);
    std::printf("  path: %s\n", renderedOnGpu ? "GPU (CUDA)" : "CPU reference");

    // THE DENOISER'S LINE, WHENEVER ONE WAS ASKED FOR. denoiseCpu returns false and
    // leaves the image alone when OIDN is missing -- correct for the effect, and
    // exactly how a measurement run from a build tree without MISTYTUNE_OIDN_DIR set
    // reported "denoised" figures identical to raw ones and said nothing.
    if (req.quality.denoise) {
        std::printf("  denoise: %s\n", cloud::denoiserDescription());
    }
    return 0;
}
