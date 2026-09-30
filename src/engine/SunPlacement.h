#pragma once

// Where the sun is, said relative to the camera rather than to the world.
//
// ===========================================================================
// THE THREE SUN-CAMERA PRESETS PLAN.md's PHASE 3 ASKS FOR, WITH BACKLIT AS DEFAULT.
//
// A photographer says "backlit", not "azimuth 160". Lighting is a relation between the
// sun and the lens: the same cloud reads as a dark mass with a silver rim from one side
// and as a flat white shape from the other. With the orbit rig, walking round the hero
// used to walk the camera round a FIXED sun, so every orbit changed the lighting as well
// as the angle. Under a preset the sun turns with the camera, and Orbit changes only
// which side of the cloud is seen.
//
// ELEVATION IS NOT A PRESET'S BUSINESS. It stays the Sun Elevation slider in every mode:
// how high the sun is sets the time of day and the colour, which is a separate decision
// from where it stands relative to the lens.
//
// MANUAL is the Sun Azimuth slider, unchanged -- the world-fixed sun of every build
// before 17, and the right choice for a sun that must not move when the camera does.
// ===========================================================================

#include "CloudParams.h"

#include <cmath>

namespace plugin::cloud {

enum class SunPlacement : int32_t {
    Backlit  = 0,
    SideLit  = 1,
    FrontLit = 2,
    Manual   = 3
};

// DEGREES THE SUN STANDS TO THE RIGHT OF STRAIGHT AHEAD, per preset.
//
// BACKLIT IS 20, NOT 0. Dead ahead hides the sun exactly behind the hero, which the orbit
// rig puts in the middle of the frame, and the cloud reads as a flat dark disc. Twenty
// degrees is the default hero's flank from the default Distance (1.5 km of half-width at
// 4 km is 20.6 degrees), so the sun sits at the cloud's right edge and the silver lining
// runs down that side.
constexpr Real kBacklitDegrees  = 20.0f;
constexpr Real kSideLitDegrees  = 90.0f;
constexpr Real kFrontLitDegrees = 180.0f;

// The azimuth the camera faces, in the sun's convention: degrees clockwise from +Z,
// towards (sin az, cos az) on the ground.
//
// ===========================================================================
// FROM THE FORWARD AND THE UP VECTOR TOGETHER, so that looking straight up still has a
// heading. Directly under the hero is a shot the orbit rig exists for (Distance 0), and
// there the forward has no horizontal part at all.
//
// Tilted up, the top of the frame points back the way the camera was facing, so MINUS
// the horizontal up agrees with the horizontal forward; tilted down, PLUS it does. The up
// vector is weighted by the forward's own vertical part, which does both at once: it is
// the whole heading at either pole and nothing on a level camera.
//
// WEIGHTED, NOT SWITCHED BY THE SIGN OF THE PITCH. A switch adds the whole up vector to
// a level camera, whose up has a sideways part as soon as it is rolled -- 30 degrees of
// Roll would swing the sun about 27 degrees. TestSunPlacement pins that.
// ===========================================================================
inline Real viewAzimuthDegrees(const ViewParams& view) {
    const Real* m = view.cameraToWorld;

    // Camera-to-world, row-major: column 1 is the camera's up, column 2 its +Z, and the
    // camera looks down its -Z.
    const double fx = -static_cast<double>(m[2]);
    const double fy = -static_cast<double>(m[6]);
    const double fz = -static_cast<double>(m[10]);
    const double ux =  static_cast<double>(m[1]);
    const double uz =  static_cast<double>(m[9]);

    const double hx = fx - fy * ux;
    const double hz = fz - fy * uz;

    // A DEGENERATE MATRIX FACES AZIMUTH 180, the identity camera's heading, rather than
    // producing atan2(0, 0) -- which is 0 and would silently flip every preset.
    if (hx * hx + hz * hz < 1e-12) return Real(180);

    return static_cast<Real>(std::atan2(hx, hz) * (180.0 / 3.14159265358979323846));
}

// The sun azimuth a preset gives. `manualAzimuth` is the Sun Azimuth slider, returned
// untouched under Manual.
//
// NOT WRAPPED TO 0..360: sunDirection() goes through sin and cos, and AtmosphereParams'
// own azimuth accumulates revolutions from an AE dial for the same reason.
inline Real placedSunAzimuth(SunPlacement placement, Real manualAzimuth,
                             const ViewParams& view) {
    Real right = Real(0);
    switch (placement) {
        case SunPlacement::Backlit:  right = kBacklitDegrees;  break;
        case SunPlacement::SideLit:  right = kSideLitDegrees;  break;
        case SunPlacement::FrontLit: right = kFrontLitDegrees; break;
        case SunPlacement::Manual:   return manualAzimuth;
    }

    // Right of the camera is its heading minus 90, because azimuth runs clockwise seen
    // from above and +X is to a default camera's right while it faces azimuth 180.
    return viewAzimuthDegrees(view) - right;
}

} // namespace plugin::cloud
