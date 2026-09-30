// The sun-camera presets: where the sun stands relative to the lens.
//
// EVERY CHECK IS MADE ON THE SUN THE RENDERER WILL USE, not on the azimuth number: the
// preset's azimuth goes through sunDirection(), the kernel's own, and is compared with
// the camera's forward and right vectors read out of the same matrix the rays are built
// from. A sign error anywhere between the preset and the pixel fails here.

#include "TestFramework.h"

#include "OrbitCamera.h"
#include "Shading.h"
#include "SunPlacement.h"

#include <cmath>

using namespace plugin;
using namespace plugin::cloud;
using namespace plugin::kernel;

namespace {

const double kDeg = 3.14159265358979323846 / 180.0;

// A scene with a hero, so the rig has a cloud to aim at.
FieldParams heroScene() {
    FieldParams f;
    f.convection.enabled  = true;
    f.convection.heroMode = 1;
    return f;
}

ViewParams rig(const OrbitControls& c) {
    ViewParams v;
    v.widthPx  = 1920;
    v.heightPx = 1080;
    orbitView(heroScene(), c, v);
    return v;
}

struct Flat {
    double x = 0.0, z = 0.0;
};

Flat flat(double x, double z) {
    const double n = std::sqrt(x * x + z * z);
    Flat f;
    f.x = x / n;
    f.z = z / n;
    return f;
}

double dotFlat(Flat a, Flat b) { return a.x * b.x + a.z * b.z; }

// The camera's heading and its right, on the ground, from the matrix the rays use.
Flat forwardOf(const ViewParams& v) { return flat(-v.cameraToWorld[2], -v.cameraToWorld[10]); }
Flat rightOf(const ViewParams& v)   { return flat(v.cameraToWorld[0], v.cameraToWorld[8]); }

// The sun the kernel will light with, on the ground.
Flat sunOf(SunPlacement p, const ViewParams& v) {
    AtmosphereParams atm;
    atm.sunElevation = 12.0f;
    atm.sunAzimuth   = placedSunAzimuth(p, atm.sunAzimuth, v);
    const Vec3 s = sunDirection(atm);
    return flat(s.x, s.z);
}

} // namespace

// --------------------------------------------------------------------------
// The three presets, all the way round
// --------------------------------------------------------------------------

// BACKLIT IS AHEAD AND TO THE RIGHT, by kBacklitDegrees, wherever the camera stands and
// however it is panned. This is the row that says Orbit no longer changes the lighting.
PL_TEST(BacklitStandsAheadAndToTheRightFromEveryOrbit) {
    PL_SWEEP(sweep, "orbit x pan");
    const float orbits[] = { 0.0f, 37.0f, 90.0f, 200.0f, -150.0f, 719.0f };
    const float pans[]   = { 0.0f, 25.0f, -40.0f };
    for (float o : orbits) {
        for (float pan : pans) {
            OrbitControls c;
            c.orbitDegrees = o;
            c.panDegrees   = pan;
            const ViewParams v = rig(c);
            const Flat s = sunOf(SunPlacement::Backlit, v);
            sweep.check(dotFlat(s, forwardOf(v)), std::cos(kBacklitDegrees * kDeg), 1e-4, o);
            sweep.check(dotFlat(s, rightOf(v)),   std::sin(kBacklitDegrees * kDeg), 1e-4, o);
        }
    }
    sweep.finish(36);
}

PL_TEST(SideLitIsSquareToTheRight) {
    PL_SWEEP(sweep, "orbit");
    const float orbits[] = { 0.0f, 45.0f, 180.0f, -95.0f };
    for (float o : orbits) {
        OrbitControls c;
        c.orbitDegrees = o;
        const ViewParams v = rig(c);
        const Flat s = sunOf(SunPlacement::SideLit, v);
        sweep.check(dotFlat(s, rightOf(v)), 1.0, 1e-4, o);
    }
    sweep.finish(4);
}

PL_TEST(FrontLitIsBehindTheCamera) {
    PL_SWEEP(sweep, "orbit");
    const float orbits[] = { 0.0f, 45.0f, 180.0f, -95.0f };
    for (float o : orbits) {
        OrbitControls c;
        c.orbitDegrees = o;
        const ViewParams v = rig(c);
        const Flat s = sunOf(SunPlacement::FrontLit, v);
        sweep.check(dotFlat(s, forwardOf(v)), -1.0, 1e-4, o);
    }
    sweep.finish(4);
}

// MANUAL IS THE SLIDER, EXACTLY, and ignores the camera: the world-fixed sun of every
// build before 17.
PL_TEST(ManualIsTheSunAzimuthSliderUntouched) {
    OrbitControls c;
    c.orbitDegrees = 73.0f;
    const ViewParams v = rig(c);
    PL_CHECK_NEAR(placedSunAzimuth(SunPlacement::Manual, 135.0f, v), 135.0, 0.0);
    PL_CHECK_NEAR(placedSunAzimuth(SunPlacement::Manual, -990.0f, v), -990.0, 0.0);
}

// THE DEFAULT SCENE, AS A NUMBER, so a change to the preset or to the rig's heading
// shows up as a changed default rather than as a differently lit first render.
PL_TEST(TheDefaultCameraIsBacklitFromAzimuth160) {
    const ViewParams v = rig(OrbitControls{});
    // MODULO A TURN: the heading comes out of atan2, whose sign at 180 follows the sign
    // of a zero, so -200 and 160 are both correct answers for the same sun.
    PL_CHECK_NEAR(std::remainder(placedSunAzimuth(SunPlacement::Backlit, 135.0f, v) - 160.0,
                                 360.0), 0.0, 1e-3);
}

// --------------------------------------------------------------------------
// The poles, and roll
// --------------------------------------------------------------------------

// DIRECTLY UNDER THE HERO the forward has no horizontal part at all. The heading must be
// the same there as a metre away and as at the default distance, or tilting up through
// the zenith would swing the sun across the sky between two frames.
PL_TEST(LookingStraightUpKeepsTheHeading) {
    PL_SWEEP(sweep, "orbit x distance");
    const float orbits[]    = { 0.0f, 60.0f, -135.0f };
    const float distances[] = { 0.0f, 1.0f, 100.0f, 4000.0f };
    for (float o : orbits) {
        const double expected = static_cast<double>(o) + 180.0;
        for (float d : distances) {
            OrbitControls c;
            c.orbitDegrees = o;
            c.distance     = d;
            const double got = viewAzimuthDegrees(rig(c));
            sweep.check(std::remainder(got - expected, 360.0), 0.0, 1e-3, d);
        }
    }
    sweep.finish(12);
}

// PAST THE ZENITH, a tilt that carries the camera over onto its back still faces the
// way it did, since the top of the frame still points back along the orbit.
PL_TEST(TiltingPastTheZenithKeepsTheHeading) {
    OrbitControls c;
    c.distance    = 0.0f;
    c.tiltDegrees = 10.0f;
    const double got = viewAzimuthDegrees(rig(c));
    PL_CHECK_NEAR(std::remainder(got - 180.0, 360.0), 0.0, 1e-3);
}

// ROLL ON A LEVEL CAMERA MOVES NOTHING. The first version switched the up vector in by
// the sign of the pitch, which added its sideways part to every level camera once it was
// rolled -- 30 degrees of Roll swung the sun by about 27.
PL_TEST(RollOnALevelCameraDoesNotTurnTheSun) {
    // THE EYE AT THE AIM'S OWN HEIGHT, so the pitch is exactly zero and the only thing
    // moving the up vector off vertical is the roll.
    Real lo = 0, hi = 0;
    orbitAimSpan(heroScene(), lo, hi);
    OrbitControls c;
    c.eyeAltitude = lo;
    c.lookAt      = 0.0f;
    c.rollDegrees = 30.0f;
    const ViewParams v = rig(c);
    PL_CHECK_NEAR(std::remainder(viewAzimuthDegrees(v) - 180.0, 360.0), 0.0, 1e-3);
}

// A MATRIX WITH NO HEADING AT ALL faces the identity camera's way rather than
// atan2(0, 0), which is 0 and would silently turn every preset round.
PL_TEST(ADegenerateMatrixFacesTheIdentityHeading) {
    ViewParams v;
    for (float& e : v.cameraToWorld) e = 0.0f;
    PL_CHECK_NEAR(viewAzimuthDegrees(v), 180.0, 0.0);
}
