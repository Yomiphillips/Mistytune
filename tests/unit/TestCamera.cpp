// The camera's framing: the contract between the frame, the buffer and the origin.
//
// WHAT THIS FILE IS HONEST ABOUT. It would NOT have caught the bug that caused it to
// be written. On 2026-09-28 every reduced-resolution render in After Effects came back
// flat blue, because src/ae/Mistytune.cpp handed primaryRayDirection a FULL-RESOLUTION
// frame alongside a DOWNSAMPLED buffer, and the maths below -- which was correct then
// and is correct now -- dutifully drew the top-left third of the picture. The defect
// was in the glue, in a number this tier cannot see, and the thing that found it was a
// render inside the host.
//
// WHAT IT IS FOR, THEN. It states the contract that glue has to satisfy, in the one
// place a compiler will check: the frame and the buffer are measured in the SAME
// units, and scaling both together is a proxy render that must not move the camera.
// That is the invariant somebody "fixing" the field of view by multiplying it with the
// downsample factor will break, and this is where they will find out.

#include "TestFramework.h"

#include "Shading.h"

using namespace plugin;
using namespace plugin::cloud;
using namespace plugin::kernel;

namespace {

ViewParams frameOf(int w, int h) {
    ViewParams v;
    v.widthPx  = w;
    v.heightPx = h;
    return v;
}

// A HALF-PIXEL OF SLACK, AND NOT MORE. Two resolutions sample the same picture at
// different pixel centres, so the rays can never be bit-identical -- at 1/3 the centres
// sit up to half a source pixel apart, which is about 0.001 in normalised device
// coordinates and about 0.0007 in the direction. The tolerance is a few times that and
// still ~100x tighter than the framing error it exists to catch: the bug pointed the
// centre ray 0.43 away in X.
const double kSubPixel = 0.005;

void checkSameRay(Vec3 a, Vec3 b) {
    PL_CHECK_NEAR(a.x, b.x, kSubPixel);
    PL_CHECK_NEAR(a.y, b.y, kSubPixel);
    PL_CHECK_NEAR(a.z, b.z, kSubPixel);
}

} // namespace

// --------------------------------------------------------------------------
// Reduced resolution
// --------------------------------------------------------------------------

// THE ROW THAT MATTERS. A proxy render is a smaller buffer of the SAME view, so a
// pixel at a given fraction across the frame must look in the same direction at every
// resolution. Scaling the field of view with the downsample factor -- the plausible
// wrong fix -- zooms the image instead, and fails here.
PL_TEST(ReducedResolutionKeepsTheFraming) {
    const ViewParams full    = frameOf(1920, 1080);
    const ViewParams half    = frameOf(960,  540);
    const ViewParams third   = frameOf(640,  360);
    const ViewParams quarter = frameOf(480,  270);

    // Centre, all four corners, and a point off the diagonal so a transposed or
    // mirrored mapping cannot pass by symmetry.
    const int probes[][2] = { {960, 540}, {0, 0}, {1919, 0}, {0, 1079}, {1919, 1079}, {1440, 270} };

    for (const auto& p : probes) {
        const Vec3 ref = primaryRayDirection(full, p[0], p[1], 0.0f, 0.0f);
        checkSameRay(primaryRayDirection(half,    p[0] / 2, p[1] / 2, 0.0f, 0.0f), ref);
        checkSameRay(primaryRayDirection(third,   p[0] / 3, p[1] / 3, 0.0f, 0.0f), ref);
        checkSameRay(primaryRayDirection(quarter, p[0] / 4, p[1] / 4, 0.0f, 0.0f), ref);
    }
}

// The frame is the denominator and nothing else. Two different frames of the same
// aspect must disagree about a buffer pixel, or the mapping is ignoring one of them --
// which is exactly the state the AE glue was in.
PL_TEST(TheFrameIsTheDenominator) {
    const Vec3 inFull  = primaryRayDirection(frameOf(1920, 1080), 320, 180, 0.0f, 0.0f);
    const Vec3 inThird = primaryRayDirection(frameOf(640,  360),  320, 180, 0.0f, 0.0f);

    // 320,180 is the centre of a 640x360 frame and a sixth of the way into a 1920x1080
    // one. Those cannot be the same ray.
    PL_CHECK(std::fabs(inFull.x - inThird.x) > 0.1);
}

// --------------------------------------------------------------------------
// The buffer as a window
// --------------------------------------------------------------------------

// Region of interest, and the CUDA band split. Both move the buffer within the frame
// by setting the origin, and both are the same arithmetic: buffer pixel + origin is a
// frame pixel.
PL_TEST(OriginWindowsIntoTheFrame) {
    ViewParams window = frameOf(1920, 1080);
    window.originX = 700;
    window.originY = 400;

    const Vec3 fromWindow = primaryRayDirection(window, 0, 0, 0.0f, 0.0f);
    const Vec3 fromFull   = primaryRayDirection(frameOf(1920, 1080), 700, 400, 0.0f, 0.0f);

    checkSameRay(fromWindow, fromFull);
}

// Mistytune.cu splits a frame into bands by adding the first row to originY. The band's
// rows have to land where the unsplit render would have put them, or the frame comes
// back striped.
PL_TEST(BandOffsetMatchesTheUnsplitFrame) {
    const ViewParams whole = frameOf(1920, 1080);

    const int bandRows  = 260;
    const int bandBegin = 520;

    ViewParams band = whole;
    band.originY = bandBegin;

    for (int y = 0; y < bandRows; y += 37) {
        checkSameRay(primaryRayDirection(band,  480, y, 0.0f, 0.0f),
                     primaryRayDirection(whole, 480, bandBegin + y, 0.0f, 0.0f));
    }
}
