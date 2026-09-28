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

    // TRANSLATION DELIBERATELY DROPPED, AND THIS IS A DESIGN DECISION RATHER THAN AN
    // OMISSION.
    //
    // The renderer's world is metres with the observer at ViewParams::observerAltitude;
    // AE's is comp PIXELS with an arbitrary origin. There is no conversion between
    // them without a scene-scale parameter, which does not exist and should not be
    // invented here.
    //
    // It costs nothing today: the sky is at infinity, so only orientation reaches the
    // image, and primaryRayDirection applies the upper 3x3 alone for that reason. It
    // will start costing something the moment clouds sit at a finite altitude and the
    // camera is expected to fly past them -- which is Phase 3, and wants a real
    // pixels-per-metre parameter rather than a guess made here.
    out[3] = out[7] = out[11] = static_cast<Real>(0);
    out[12] = out[13] = out[14] = static_cast<Real>(0);
    out[15] = static_cast<Real>(1);
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
