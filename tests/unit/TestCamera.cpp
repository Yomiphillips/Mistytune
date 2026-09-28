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

#include "CameraConvert.h"
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

// --------------------------------------------------------------------------
// After Effects' camera, converted
// --------------------------------------------------------------------------
//
// THESE CASES ARE WORKED OUT BY HAND, not recorded from a run. A conversion test
// blessed from its own output agrees with whatever the code did on the day, which for
// a camera means it agrees with a plausible picture pointing the wrong way.

namespace {

// AE's A_Matrix4 in memory order: mat[row][col], row-vector convention, so the
// camera's world-space axes are the ROWS.
void aeMatrix(double out[16],
              double xx, double xy, double xz,
              double yx, double yy, double yz,
              double zx, double zy, double zz,
              double px = 0.0, double py = 0.0, double pz = 0.0) {
    const double m[16] = {
        xx, xy, xz, 0.0,
        yx, yy, yz, 0.0,
        zx, zy, zz, 0.0,
        px, py, pz, 1.0
    };
    for (int i = 0; i < 16; ++i) out[i] = m[i];
}

// Where a camera-space direction ends up in world space, under our column-vector
// row-major convention -- the same three lines primaryRayDirection uses.
Vec3 throughMatrix(const Real m[16], Vec3 v) {
    return vec3(
        static_cast<float>(m[0] * v.x + m[1] * v.y + m[2]  * v.z),
        static_cast<float>(m[4] * v.x + m[5] * v.y + m[6]  * v.z),
        static_cast<float>(m[8] * v.x + m[9] * v.y + m[10] * v.z));
}

const Vec3 kForward = vec3(0.0f, 0.0f, -1.0f);   // our camera looks down -Z
const Vec3 kUp      = vec3(0.0f, 1.0f,  0.0f);
const Vec3 kRight   = vec3(1.0f, 0.0f,  0.0f);

} // namespace

// AE'S DEFAULT CAMERA LOOKS ALONG +Z AND ITS UP IS -Y, because AE's Y points down.
// In our conventions that is looking along -Z with up at +Y -- the identity. If the
// handedness flip were applied on only one side, this case still passes, which is why
// it is the first test and not the only one.
PL_TEST(AnAEIdentityCameraIsOurIdentity) {
    double ae[16];
    aeMatrix(ae, 1, 0, 0,
                 0, 1, 0,
                 0, 0, 1);

    Real m[16];
    cameraToWorldFromAE(ae, m);

    checkSameRay(throughMatrix(m, kForward), kForward);
    checkSameRay(throughMatrix(m, kUp),      kUp);
    checkSameRay(throughMatrix(m, kRight),   kRight);
}

// A CAMERA PITCHED UP MUST PITCH UP, which is the case the whole feature exists for
// and the one a sign error inverts.
//
// In AE, pitching the camera up means its forward axis tilts toward -Y (AE's up).
// Worked by hand at 30 degrees: forward becomes (0, -sin30, cos30) = (0, -0.5, 0.866)
// and up becomes (0, -cos30, -sin30). Converted, our forward must be
// (0, +sin30, -cos30) -- above the horizon, still looking down -Z.
PL_TEST(AnAECameraPitchedUpPitchesUp) {
    const double c = 0.86602540378;   // cos 30
    const double s = 0.5;             // sin 30

    double ae[16];
    aeMatrix(ae, 1,  0,  0,           // X axis unchanged by a pitch
                 0,  c,  s,           // Y axis (AE's down) tilts
                 0, -s,  c);          // Z axis (forward) tilts toward -Y

    Real m[16];
    cameraToWorldFromAE(ae, m);

    const Vec3 fwd = throughMatrix(m, kForward);

    // ABOVE THE HORIZON. This single assertion is the one that would have caught the
    // 20-degrees-below-the-horizon default that made the effect render black.
    PL_CHECK(fwd.y > 0.0f);

    checkSameRay(fwd, vec3(0.0f, static_cast<float>(s), static_cast<float>(-c)));
}

// A PAN MUST NOT ROLL, which is what the row-vector/column-vector transpose decides.
// Getting it backwards leaves the forward axis of a yaw looking right, so this checks
// the axis that moves AND the axis that must not.
PL_TEST(AnAECameraYawedStaysLevel) {
    const double c = 0.0, s = 1.0;    // 90 degrees

    double ae[16];
    aeMatrix(ae,  c, 0, -s,
                  0, 1,  0,
                  s, 0,  c);

    Real m[16];
    cameraToWorldFromAE(ae, m);

    // Yawed 90 degrees: forward swings onto the X axis, and up stays up.
    const Vec3 fwd = throughMatrix(m, kForward);
    PL_CHECK_NEAR(fwd.y, 0.0, 1e-5);
    checkSameRay(throughMatrix(m, kUp), kUp);
}

// TRANSLATION IS DROPPED, not silently folded into the rotation. A camera parked a
// thousand pixels away must give the same rays as one at the origin -- the sky is at
// infinity and primaryRayDirection applies the upper 3x3 alone.
PL_TEST(CameraPositionDoesNotReachTheRays) {
    double atOrigin[16], moved[16];
    aeMatrix(atOrigin, 1, 0, 0,  0, 1, 0,  0, 0, 1);
    aeMatrix(moved,    1, 0, 0,  0, 1, 0,  0, 0, 1,  960.0, -540.0, -2666.0);

    Real a[16], b[16];
    cameraToWorldFromAE(atOrigin, a);
    cameraToWorldFromAE(moved,    b);

    checkSameRay(throughMatrix(a, kForward), throughMatrix(b, kForward));
}

// --------------------------------------------------------------------------
// The field of view AE's camera implies
// --------------------------------------------------------------------------

// AE gives a distance to the comp plane and that plane's size. Half the HEIGHT over
// the distance is the tangent of half the VERTICAL field of view.
PL_TEST(FovComesFromThePlaneHeight) {
    // The 50mm-on-full-frame default this project uses elsewhere: 39.6 degrees
    // vertical. A 1080-tall plane at that field of view sits 1499.4 px away.
    PL_CHECK_NEAR(verticalFovFromPlane(1499.4, 1080.0), 39.6, 0.05);

    // Twice as far is roughly half the angle, and exactly a smaller one.
    PL_CHECK(verticalFovFromPlane(2998.8, 1080.0) < verticalFovFromPlane(1499.4, 1080.0));

    // THE WIDTH MUST NOT BE WHAT IS PASSED. A 1920-wide plane at the same distance
    // implies a much wider angle, and using it would widen the lens by the aspect
    // ratio -- which looks like a wrong camera, not like a wrong argument.
    PL_CHECK(verticalFovFromPlane(1499.4, 1920.0) > 60.0);
}

// NO CAMERA REPORTS ZERO RATHER THAN A DEFAULT. docs/HOST-NOTES.md: a comp without a
// camera returns a zero plane size, and the caller has to be able to tell that from a
// camera that genuinely is 90 degrees wide.
PL_TEST(NoCameraGivesZeroFov) {
    PL_CHECK_NEAR(verticalFovFromPlane(1499.4, 0.0), 0.0, 1e-9);
    PL_CHECK_NEAR(verticalFovFromPlane(0.0, 1080.0), 0.0, 1e-9);
    PL_CHECK_NEAR(verticalFovFromPlane(-1.0, 1080.0), 0.0, 1e-9);
}

// ---------------------------------------------------------------------------
// Where the ray STARTS, which is a different question from where it points
// ---------------------------------------------------------------------------

// THE OBSERVER IS AT observerAltitude, WHATEVER THE COMP CAMERA SAYS.
//
// CameraConvert drops the translation on purpose -- AE's world is comp pixels with an
// arbitrary origin and this one is metres, and there is no conversion without a
// scene-scale parameter that does not exist yet. So elements 3, 7 and 11 are
// guaranteed zero, and a primaryRayOrigin that trusted them put the camera at
// ALTITUDE ZERO in After Effects instead of at the observer's two metres.
//
// THAT SHIPPED, AND NO RENDER COULD HAVE SHOWN IT: two metres against a cloud base of
// six kilometres moves nothing a person can see. It is exactly the class of error
// this file exists for -- the one that renders a completely plausible picture.
PL_TEST(TheRayStartsAtTheObserverNotAtTheMatrix) {
    cloud::ViewParams view;
    view.observerAltitude = 2.0f;

    const Vec3 def = primaryRayOrigin(view);
    PL_CHECK_NEAR(def.x, 0.0, 1e-6);
    PL_CHECK_NEAR(def.y, 2.0, 1e-6);
    PL_CHECK_NEAR(def.z, 0.0, 1e-6);

    // A comp camera parked a long way from the origin, converted exactly as
    // src/ae/AEBridge.h converts it. The origin must not move.
    double moved[16];
    aeMatrix(moved, 1, 0, 0,  0, 1, 0,  0, 0, 1,  960.0, -540.0, -2666.0);

    cloud::ViewParams fromComp;
    fromComp.observerAltitude = 2.0f;
    fromComp.cameraFromComp   = true;
    cameraToWorldFromAE(moved, fromComp.cameraToWorld);

    const Vec3 got = primaryRayOrigin(fromComp);
    PL_CHECK_NEAR(got.x, 0.0, 1e-6);
    PL_CHECK_NEAR(got.y, 2.0, 1e-6);
    PL_CHECK_NEAR(got.z, 0.0, 1e-6);
}

// And the altitude is the one the parameter carries, not a constant.
PL_TEST(ObserverAltitudeReachesTheRayOrigin) {
    cloud::ViewParams high;
    high.observerAltitude = 3500.0f;
    PL_CHECK_NEAR(primaryRayOrigin(high).y, 3500.0, 1e-3);
}
