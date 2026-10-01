#pragma once

// The effect's own camera: one that circles a cloud and keeps looking at it.
//
// ===========================================================================
// WHY THERE IS A SECOND CAMERA WHEN AE ALREADY HAS ONE.
//
// Reported from the host on build 15: "the camera movements still feel very
// unintuitive ... I'm lost. I should be able to dolly around a specific point or
// cloud, move towards it or against it." Framing the comp camera has three causes,
// and none of them is a bug in CameraConvert.h:
//
//   1. AE's camera moves in comp PIXELS and the sky is kilometres, so walking up to a
//      3 km cloud is thousands of pixels of dolly at a scale (Camera Travel) that the
//      user has to choose first.
//   2. AE's point of interest, and so its Orbit tool, pivots on the comp centre, which
//      is a spot on the GROUND. The cloud is 1 to 3 km above it. Orbiting swings the
//      camera round the dirt under the cloud, and a default camera looks level, so the
//      cloud is above the frame.
//   3. AE's viewer draws nothing where the cloud is. There is nothing to aim at but
//      a slow render.
//
// This rig answers all three in the units the sky is built in. It stands a given
// DISTANCE from the hero's axis, at a given ORBIT angle round it and a given eye
// height, and it LOOKS AT a point on the cloud. The cloud stays in frame whatever the
// sliders do, which is what "lost" asks for. Tilt, Pan and Roll are offsets from that
// aim, so a composition off the centre is still anchored to the cloud.
// ===========================================================================

#include "CloudParams.h"
#include "ConvectionField.h"

#include <cmath>

namespace plugin::cloud {

// What the panel says. Angles in degrees, lengths in metres.
struct OrbitControls {
    // 0 STANDS WHERE A DEFAULT CAMERA DOES: on the +Z side of the target, looking
    // down -Z. Positive walks to the camera's RIGHT round the target.
    Real orbitDegrees = 0.0f;

    // Horizontally, from the target's vertical axis. ZERO IS DIRECTLY UNDERNEATH and is
    // allowed: the pitch below comes from atan2, so it looks straight up rather than
    // dividing by zero.
    Real distance = 4000.0f;

    // The eye's height above the ground. Floored at one metre, as the comp camera's is.
    Real eyeAltitude = 2.0f;

    // WHERE ON THE CLOUD IT LOOKS, AS A FRACTION OF ITS HEIGHT: 0 the base, 1 the top.
    // A fraction rather than metres so raising the Inversion keeps the aim on the
    // cloud instead of leaving it looking at where the cloud used to be.
    Real lookAt = 0.5f;

    // Offsets from the aim. Tilt + looks up, Pan + looks right, Roll + dips the
    // camera's right side, which is AE's sign for a camera's Z Rotation.
    Real tiltDegrees = 0.0f;
    Real panDegrees  = 0.0f;
    Real rollDegrees = 0.0f;

    // ON A 36 MM FILM MEASURED HORIZONTALLY, which is AE's camera default -- so a
    // 50 mm here frames what a 50 mm comp camera does on the same comp.
    Real focalLengthMm = 24.0f;
};

// ---------------------------------------------------------------------------
// The vertical span that `lookAt` is a fraction of
// ---------------------------------------------------------------------------
//
// THE HERO'S, ELSE THE CUMULUS FIELD'S, ELSE THE CIRRUS'S. Each is the cloud the rig
// is most likely pointed at when it exists. The last is the ground up to the ice's
// generating level, so Look At 0.5 in a cirrus-only sky still aims into the sky; with
// no cloud at all it is the ground up to 3 km, so the aim is never the horizon.
//
// THE HERO'S BILLOWS ARE NOT COUNTED, so the top is the analytic tower's crown. They
// reach past it by a few hundred metres, which Look At 1 leaves just in frame.
inline void orbitAimSpan(const FieldParams& field, Real& lo, Real& hi) {
    ConvectionDerived cd;
    deriveConvection(field, cd);

    if (cd.present && cd.heroTop > Real(0)) {
        lo = cd.base;
        hi = cd.base + cd.heroTop;
        return;
    }
    if (cd.present && cd.depth > Real(0)) {
        lo = cd.base;
        hi = cd.base + cd.depth;
        return;
    }
    lo = Real(0);
    hi = field.ice.enabled && field.ice.cellAltitude > Real(0) ? field.ice.cellAltitude
                                                               : Real(3000);
}

// The vertical field of view a focal length gives on AE's default film: 36 mm across,
// so the horizontal half-angle's tangent is 18 / f and the vertical one's is that over
// the frame's aspect. ZERO FOR A LENS OR FRAME THAT CANNOT BE ONE, so the caller keeps
// its default rather than rendering a degenerate camera.
inline Real verticalFovFromFocalLength(Real focalLengthMm, int32_t widthPx, int32_t heightPx) {
    if (!(focalLengthMm > Real(0)) || widthPx <= 0 || heightPx <= 0) return Real(0);

    const double tanHalfH = 18.0 / static_cast<double>(focalLengthMm);
    const double tanHalfV = tanHalfH * static_cast<double>(heightPx) / static_cast<double>(widthPx);
    return static_cast<Real>(2.0 * std::atan(tanHalfV) * (180.0 / 3.14159265358979323846));
}

// ---------------------------------------------------------------------------
// The rig
// ---------------------------------------------------------------------------
//
// THE TARGET IS THE HERO'S POSITION WHETHER OR NOT THE HERO IS DRAWN, so with the hero
// off the rig circles the same point of the field and switching it on puts a cloud
// exactly where the camera was already looking.
//
// BUILT FROM ANGLES, NOT FROM A LOOK-AT CROSS PRODUCT. A look-at basis crosses the
// forward with world up, which is zero when the camera looks straight up -- and
// standing under a cloud looking up is precisely the shot this exists for. As
// yaw-pitch-roll it has no such pole: R = Ry(yaw) Rx(pitch) Rz(-roll), the same
// Ry Rx order the CLI's --heading/--pitch build, so the two cannot disagree on a sign.
//
// Writes the matrix, the observer and the field of view. `view.widthPx/heightPx` must
// already hold the frame, since the field of view depends on its aspect.
inline void orbitView(const FieldParams& field, const OrbitControls& c, ViewParams& view) {
    constexpr double kDeg = 3.14159265358979323846 / 180.0;

    Real lo = 0, hi = 0;
    orbitAimSpan(field, lo, hi);
    const double aimAltitude = static_cast<double>(lo) +
                               static_cast<double>(c.lookAt) * static_cast<double>(hi - lo);

    const double dist  = c.distance > Real(0) ? static_cast<double>(c.distance) : 0.0;
    const double orbit = static_cast<double>(c.orbitDegrees) * kDeg;
    const double eye   = c.eyeAltitude >= Real(1) ? static_cast<double>(c.eyeAltitude) : 1.0;

    // WHERE THE HERO IS NOW, drift included, so a hero riding the wind stays framed.
    Real heroX = 0, heroZ = 0;
    heroPositionNow(field, heroX, heroZ);
    view.observerX        = static_cast<Real>(static_cast<double>(heroX) + dist * std::sin(orbit));
    view.observerZ        = static_cast<Real>(static_cast<double>(heroZ) + dist * std::cos(orbit));
    view.observerAltitude = static_cast<Real>(eye);

    // YAW = ORBIT because Ry(yaw) sends the camera's forward (0,0,-1) to
    // (-sin yaw, 0, -cos yaw), which is exactly the way back from (sin, cos) to the
    // target. Pan is subtracted because a positive yaw turns LEFT.
    const double yaw   = orbit - static_cast<double>(c.panDegrees) * kDeg;
    const double pitch = std::atan2(aimAltitude - eye, dist) +
                         static_cast<double>(c.tiltDegrees) * kDeg;
    const double roll  = -static_cast<double>(c.rollDegrees) * kDeg;

    const double cy = std::cos(yaw),   sy = std::sin(yaw);
    const double cp = std::cos(pitch), sp = std::sin(pitch);
    const double cr = std::cos(roll),  sr = std::sin(roll);

    // Ry Rx, as the CLI writes it out, then times Rz on the right.
    const double a[3][3] = {
        { cy,  sy * sp, sy * cp },
        { 0.0, cp,      -sp     },
        { -sy, cy * sp, cy * cp }
    };
    const double z[3][3] = {
        { cr,  -sr, 0.0 },
        { sr,  cr,  0.0 },
        { 0.0, 0.0, 1.0 }
    };
    for (int row = 0; row < 3; ++row) {
        for (int col = 0; col < 3; ++col) {
            double v = 0.0;
            for (int k = 0; k < 3; ++k) v += a[row][k] * z[k][col];
            view.cameraToWorld[row * 4 + col] = static_cast<Real>(v);
        }
    }
    view.cameraToWorld[3] = view.cameraToWorld[7] = view.cameraToWorld[11] = Real(0);
    view.cameraToWorld[12] = view.cameraToWorld[13] = view.cameraToWorld[14] = Real(0);
    view.cameraToWorld[15] = Real(1);

    const Real fov = verticalFovFromFocalLength(c.focalLengthMm, view.widthPx, view.heightPx);
    if (fov > Real(0)) view.verticalFovDegrees = fov;

    view.cameraFromComp = false;
}

} // namespace plugin::cloud
