#pragma once

// After Effects' camera, converted into the renderer's conventions.
//
// ===========================================================================
// WHY THIS IS IN src/engine/ AND NOT IN src/ae/ WITH THE REST OF THE HOST GLUE.
//
// It is arithmetic with two chances to be silently wrong -- a transpose and a
// handedness flip -- and it produces a camera, which is the thing in this renderer
// whose errors look least like errors. A camera pointing the wrong way renders a
// picture: a plausible, well-formed, completely incorrect picture. That is exactly
// the failure this project has now shipped three times and caught late every time,
// and every one of those lived in host glue that tests/unit/ could not reach.
//
// So the AE types stop at the caller. This header takes sixteen doubles and gives
// back sixteen floats, and tests/unit/TestCamera.cpp checks it against cases whose
// answers are known by hand.
// ===========================================================================

#include "CloudParams.h"

#include <cmath>

namespace plugin::cloud {

// ---------------------------------------------------------------------------
// The two coordinate systems, stated once so the conversion below is checkable
// ---------------------------------------------------------------------------
//
// AFTER EFFECTS:  +X right, +Y DOWN, +Z INTO the screen. A default camera looks
//                 along +Z. Right-handed.
//
// THIS RENDERER:  +X right, +Y UP, +Z OUT of the screen. The camera looks along
//                 -Z, which is what primaryRayDirection builds. Right-handed.
//
// So the two differ by flipping Y and Z: S = diag(1, -1, -1), which is its own
// inverse. A vector converts as v_ours = S * v_ae, and a BASIS converts as
// M_ours = S * M_ae * S -- once for the world side and once for the camera side.
// Doing it on only one side is the mistake that yields a camera mirrored through
// the horizon, which renders a perfectly convincing upside-down sky.
//
// AE'S MATRIX IS ROW-VECTOR, OURS IS COLUMN-VECTOR, which is the transpose on top
// of all that. A_Matrix4 stores mat[row][col] and AE multiplies v * M, so the
// camera's world-space axes are its ROWS. primaryRayDirection multiplies M * v and
// reads m[0],m[1],m[2] as a row, so our axes are COLUMNS.
//
// Both flips are applied in one expression below rather than in two passes,
// because two passes invite exactly one of them to be forgotten.

// `aeRowMajor` is A_Matrix4's sixteen doubles in memory order: mat[0][0], mat[0][1],
// mat[0][2], mat[0][3], mat[1][0], ... `out` is the row-major camera-to-world the
// kernel reads, with the translation left as identity -- see ViewParams.
inline void cameraToWorldFromAE(const double aeRowMajor[16], Real out[16]) {
    // The handedness flip, as a sign per axis. s[0] is X, which does not move.
    const double s[3] = { 1.0, -1.0, -1.0 };

    for (int row = 0; row < 3; ++row) {
        for (int col = 0; col < 3; ++col) {
            // out[row][col] = s[row] * s[col] * ae[col][row]
            //
            // THE INDICES ARE SWAPPED ON PURPOSE -- that is the row-vector to
            // column-vector transpose. Writing ae[row][col] here compiles, runs, and
            // gives a camera that rolls when it should pan.
            out[row * 4 + col] =
                static_cast<Real>(s[row] * s[col] * aeRowMajor[col * 4 + row]);
        }
    }

    // TRANSLATION LEFT OUT OF THE MATRIX, AND IT IS NOT LOST: IT GOES THROUGH
    // observerFromAE BELOW INSTEAD.
    //
    // AE's world is comp PIXELS; this one is METRES. The conversion needs the Camera
    // Travel scale, so the position is carried in ViewParams' observer fields, in
    // metres, and this matrix stays a pure rotation. primaryRayDirection applies the
    // upper 3x3 alone, and primaryRayOrigin reads the observer fields. So there is one
    // place a position is converted, and a pixel is never read as a metre.
    out[3] = out[7] = out[11] = static_cast<Real>(0);
    out[12] = out[13] = out[14] = static_cast<Real>(0);
    out[15] = static_cast<Real>(1);
}

// ---------------------------------------------------------------------------
// Where the camera stands
// ---------------------------------------------------------------------------
//
// ===========================================================================
// THE COMP'S CENTRE, ON THE COMP PLANE, IS THE WORLD ORIGIN -- WHICH IS WHERE AE'S
// DEFAULT CAMERA LOOKS.
//
// A new AE camera stands at (w/2, h/2, -zoom) and its point of interest is (w/2, h/2,
// 0). Anchoring the world there means the default camera stands zoom x travel metres
// BEHIND the origin, looking at it. That is 2.7 km for a 50 mm camera on a 1920-wide
// comp at 1 m per pixel. A hero cloud placed at the origin is therefore in front of any
// camera that still looks where AE put it, and a dolly towards the point of interest
// walks towards the cloud.
//
// MEASURED IN THE HOST (the diagnostic log, 2026-09-29): the plane AE reports stays
// 1920x1080 at Full, Half, Third and Quarter resolution. So the camera is in full comp
// pixels whatever the preview resolution, and a resolution change cannot move the
// observer.
//
// AXES: AE +X right, +Y DOWN, +Z INTO the screen. Ours: +X right, +Y up (altitude),
// +Z OUT of the screen. So x carries over, y flips into altitude, and z flips.
//
// `metresPerPixel` 0 IS THE OLD BEHAVIOUR: the camera turns but does not travel, and
// the observer stands at the origin at `baseAltitude`.
//
// THE ALTITUDE IS FLOORED AT ONE METRE. The atmosphere clamps a negative origin
// altitude to zero anyway, but a camera below the ground plane would start every ray
// inside the planet, and the floor keeps "lowered the camera too far" a plausible
// picture rather than a black one.
// ===========================================================================
struct ObserverPosition {
    Real x        = 0;
    Real altitude = 0;
    Real z        = 0;
};

inline ObserverPosition observerFromCompPosition(double camX, double camY, double camZ,
                                                 double compWidth, double compHeight,
                                                 Real metresPerPixel, Real baseAltitude) {
    const double s = metresPerPixel > 0 ? static_cast<double>(metresPerPixel) : 0.0;

    ObserverPosition o;
    o.x        = static_cast<Real>((camX - compWidth * 0.5) * s);
    o.altitude = static_cast<Real>(static_cast<double>(baseAltitude) + (compHeight * 0.5 - camY) * s);
    o.z        = static_cast<Real>(-camZ * s);

    if (!(o.altitude >= static_cast<Real>(1))) o.altitude = static_cast<Real>(1);
    return o;
}

// The same, from A_Matrix4's sixteen values in memory order. The translation is the
// fourth ROW, since AE multiplies row vectors: mat[3][0..2].
inline ObserverPosition observerFromAE(const double aeRowMajor[16],
                                       double compWidth, double compHeight,
                                       Real metresPerPixel, Real baseAltitude) {
    return observerFromCompPosition(aeRowMajor[12], aeRowMajor[13], aeRowMajor[14],
                                    compWidth, compHeight, metresPerPixel, baseAltitude);
}

// WHERE THE OBSERVER STANDS WHEN THE COMP HAS NO CAMERA: where a new default camera
// would stand, a 50 mm lens on a 36 mm frame, so zoom = width x 50/36. Adding a
// default camera to the comp then turns the view without moving it.
inline ObserverPosition defaultObserver(double compWidth, double compHeight,
                                        Real metresPerPixel, Real baseAltitude) {
    return observerFromCompPosition(compWidth * 0.5, compHeight * 0.5,
                                    -compWidth * (50.0 / 36.0),
                                    compWidth, compHeight, metresPerPixel, baseAltitude);
}

// The vertical field of view AE's camera implies, in degrees.
//
// AE gives the distance from the camera to the comp plane and that plane's size in
// pixels, which is the same thing a focal length is: half the plane's height over the
// distance is the tangent of half the vertical field of view.
//
// VERTICAL, FROM THE HEIGHT, because that is what ViewParams::verticalFovDegrees
// means and what primaryRayDirection divides by -- it derives the horizontal extent
// from the frame's aspect ratio itself. Passing the width here gives a field of view
// too wide by exactly the aspect ratio, which reads as a camera with the wrong lens
// rather than as a units mistake.
//
// RETURNS ZERO WHEN THERE IS NO CAMERA. docs/HOST-NOTES.md records that a comp
// without one reports a zero plane size, and zero is returned rather than a default
// so the caller can tell "no camera, defaulting" from "a camera 90 degrees wide".
inline Real verticalFovFromPlane(double distanceToPlane, double planeHeightPx) {
    if (!(distanceToPlane > 0.0) || !(planeHeightPx > 0.0)) return static_cast<Real>(0);

    const double halfAngle = std::atan((planeHeightPx * 0.5) / distanceToPlane);
    return static_cast<Real>(halfAngle * 2.0 * (180.0 / 3.14159265358979323846));
}

} // namespace plugin::cloud
