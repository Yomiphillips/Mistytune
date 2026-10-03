// Local lights (build 29): the host's half.
//
// EVERY PLACEMENT IS CHECKED BY PROJECTING IT, not by comparing numbers to numbers. A comp
// light is mapped into the world and then pushed back through the renderer's camera the
// way primaryRayDirection builds rays, and it must land on the pixel AE's own camera puts
// it on. A light in the wrong place renders a plausible cloud lit from somewhere else,
// which is exactly the kind of wrong this project has found late before.

#include "TestFramework.h"

#include "CameraConvert.h"
#include "LocalLights.h"
#include "OrbitCamera.h"
#include "OutputConvert.h"

#include <algorithm>
#include <cmath>
#include <vector>

using namespace plugin;
using namespace plugin::cloud;

namespace {

constexpr double kPi = 3.14159265358979323846;

FieldParams heroScene() {
    FieldParams f;
    f.convection.enabled  = true;
    f.convection.heroMode = 1;
    return f;
}

ViewParams orbitRig() {
    ViewParams v;
    v.widthPx  = 1920;
    v.heightPx = 1080;
    orbitView(heroScene(), OrbitControls{}, v);
    return v;
}

// AN AE CAMERA, as A_Matrix4 lays it out: rows its axes, row 3 its position. Yaw about AE's
// +Y (down), then pitch about the camera's own X -- a right-handed, orthonormal basis.
void aeCamera(double yawDeg, double pitchDeg, double x, double y, double z, double m[16]) {
    const double a = yawDeg * kPi / 180.0;
    const double p = pitchDeg * kPi / 180.0;
    const double ax[3] = { std::cos(a), 0.0, -std::sin(a) };
    const double y0[3] = { 0.0, 1.0, 0.0 };
    const double z0[3] = { std::sin(a), 0.0, std::cos(a) };
    double ay[3], az[3];
    for (int k = 0; k < 3; ++k) {
        ay[k] =  std::cos(p) * y0[k] + std::sin(p) * z0[k];
        az[k] = -std::sin(p) * y0[k] + std::cos(p) * z0[k];
    }
    const double out[16] = { ax[0], ax[1], ax[2], 0.0,
                             ay[0], ay[1], ay[2], 0.0,
                             az[0], az[1], az[2], 0.0,
                             x,     y,     z,     1.0 };
    for (int k = 0; k < 16; ++k) m[k] = out[k];
}

// WHERE AE'S CAMERA PUTS A COMP POINT, in comp pixels across a w x h frame.
void aeProject(const double cam[16], double zoom, double w, double h, const double p[3],
               double& sx, double& sy) {
    const double rel[3] = { p[0] - cam[12], p[1] - cam[13], p[2] - cam[14] };
    double c[3];
    for (int r = 0; r < 3; ++r)
        c[r] = rel[0] * cam[r * 4 + 0] + rel[1] * cam[r * 4 + 1] + rel[2] * cam[r * 4 + 2];
    sx = 0.5 * w + c[0] * zoom / c[2];
    sy = 0.5 * h + c[1] * zoom / c[2];
}

// WHERE THE RENDERER'S CAMERA PUTS A WORLD POINT, in frame pixels: primaryRayDirection run
// backwards. False behind the eye.
bool ourProject(const ViewParams& v, const float p[3], double& px, double& py) {
    const double rel[3] = { p[0] - static_cast<double>(v.observerX),
                            p[1] - static_cast<double>(v.observerAltitude),
                            p[2] - static_cast<double>(v.observerZ) };
    const Real* m = v.cameraToWorld;
    double c[3];
    for (int col = 0; col < 3; ++col)
        c[col] = rel[0] * m[0 * 4 + col] + rel[1] * m[1 * 4 + col] + rel[2] * m[2 * 4 + col];
    if (!(c[2] < 0.0)) return false;
    const double t      = std::tan(static_cast<double>(v.verticalFovDegrees) * kPi / 360.0);
    const double aspect = static_cast<double>(v.widthPx) / v.heightPx;
    const double ndcX = c[0] / (-c[2] * t * aspect);
    const double ndcY = -c[1] / (-c[2] * t);
    px = (ndcX + 1.0) * 0.5 * v.widthPx;
    py = (ndcY + 1.0) * 0.5 * v.heightPx;
    return true;
}

double luminance(double r, double g, double b) { return 0.2126 * r + 0.7152 * g + 0.0722 * b; }

// A float ARGB picture, as AE hands a 32 bpc layer over.
struct Picture {
    int w = 0, h = 0;
    std::vector<float> argb;
    Picture(int width, int height) : w(width), h(height), argb(static_cast<size_t>(width) * height * 4, 0.0f) {}
    void set(int x, int y, float r, float g, float b) {
        float* p = &argb[(static_cast<size_t>(y) * w + x) * 4];
        p[0] = 1.0f; p[1] = r; p[2] = g; p[3] = b;
    }
    ConstImageView view() const {
        ConstImageView v;
        v.data     = argb.data();
        v.width    = w;
        v.height   = h;
        v.rowBytes = static_cast<std::ptrdiff_t>(w) * 4 * sizeof(float);
        v.format   = PixelFormat::ARGB32F;
        return v;
    }
};

const float* record(const LightSet& s, int i) {
    return &s.packed[static_cast<size_t>(kLightHeaderFloats) + static_cast<size_t>(i) * kLightRecordFloats];
}

} // namespace

// --------------------------------------------------------------------------
// The comp, through the camera
// --------------------------------------------------------------------------

// UNDER THE COMP CAMERA A LIGHT GOES THROUGH THE CAMERA'S OWN MAPPING: the comp centre on
// the comp plane is the world origin and Travel is the scale, exactly as the camera's
// position goes through observerFromCompPosition. A rotated, moved camera, so a transpose
// or a missing flip cannot hide behind an identity.
PL_TEST(CompCameraLightsShareTheCamerasWorld) {
    const double w = 1920.0, h = 1080.0, k = 1.7, base = 1500.0;
    double cam[16];
    aeCamera(31.0, -12.0, 700.0, 300.0, -2400.0, cam);

    ViewParams view;
    view.widthPx  = 1920;
    view.heightPx = 1080;
    cameraToWorldFromAE(cam, view.cameraToWorld);
    const ObserverPosition o = observerFromAE(cam, w, h, static_cast<Real>(k), static_cast<Real>(base));
    view.observerX = o.x;
    view.observerAltitude = o.altitude;
    view.observerZ = o.z;

    const CompLightFrame f = compLightFrame(cam, 2666.7, h, true, k, view, LightAnchor{});

    const double points[][3] = { { 960.0, 540.0, 0.0 }, { 300.0, -200.0, 1500.0 },
                                 { 2500.0, 900.0, -800.0 }, { 700.0, 300.0, -2400.0 } };
    for (const auto& p : points) {
        float got[3];
        compPointToWorld(f, view, p, got);
        PL_CHECK_NEAR(got[0], (p[0] - 0.5 * w) * k, 2e-3);
        PL_CHECK_NEAR(got[1], base + (0.5 * h - p[1]) * k, 2e-3);
        PL_CHECK_NEAR(got[2], -p[2] * k, 2e-3);
    }
}

// UNDER THE ORBIT RIG A LIGHT STAYS ON ITS PIXEL: wherever it is in the comp, on the plane
// or off it, it lands where AE's viewer shows it -- through a 24 mm rig against AE's 50 mm
// default camera, which is the case that needs the lenses' ratio.
PL_TEST(OrbitLightsLandOnTheirPixel) {
    const ViewParams view = orbitRig();
    const LightAnchor anchor = lightAnchor(heroScene(), view);

    double cam[16], zoom = 0.0;
    defaultCompCamera(1920.0, 1080.0, cam, zoom);
    const CompLightFrame f = compLightFrame(cam, zoom, 1080.0, false, 1.0, view, anchor);

    const double points[][3] = { { 960.0, 540.0, 0.0 }, { 200.0, 100.0, 0.0 },
                                 { 1700.0, 900.0, 600.0 }, { 400.0, 800.0, -900.0 },
                                 { 1000.0, -300.0, 2500.0 } };
    for (const auto& p : points) {
        double sx = 0.0, sy = 0.0, px = 0.0, py = 0.0;
        aeProject(cam, zoom, 1920.0, 1080.0, p, sx, sy);
        float world[3];
        compPointToWorld(f, view, p, world);
        PL_CHECK(ourProject(view, world, px, py));
        PL_CHECK_NEAR(px, sx, 0.05);
        PL_CHECK_NEAR(py, sy, 0.05);
    }

    // AND AE'S PITCHED, PANNED CAMERA, same rule: what moves the AE view moves the light.
    double turned[16];
    aeCamera(-20.0, 15.0, 1200.0, 400.0, -2000.0, turned);
    const CompLightFrame g = compLightFrame(turned, zoom, 1080.0, false, 1.0, view, anchor);
    const double q[3] = { 1100.0, 500.0, 300.0 };
    double sx = 0.0, sy = 0.0, px = 0.0, py = 0.0;
    aeProject(turned, zoom, 1920.0, 1080.0, q, sx, sy);
    float world[3];
    compPointToWorld(g, view, q, world);
    PL_CHECK(ourProject(view, world, px, py));
    PL_CHECK_NEAR(px, sx, 0.05);
    PL_CHECK_NEAR(py, sy, 0.05);
}

// THE COMP PLANE IS THE ANCHOR'S DEPTH: the comp's centre on it lands on the view axis, as
// deep as the hero.
PL_TEST(OrbitCompPlaneIsTheHerosDepth) {
    const ViewParams view = orbitRig();
    const LightAnchor anchor = lightAnchor(heroScene(), view);
    PL_CHECK(anchor.depth > 1000.0f);

    double cam[16], zoom = 0.0;
    defaultCompCamera(1920.0, 1080.0, cam, zoom);
    const CompLightFrame f = compLightFrame(cam, zoom, 1080.0, false, 1.0, view, anchor);

    const double centre[3] = { 960.0, 540.0, 0.0 };
    float w[3];
    compPointToWorld(f, view, centre, w);
    const double fwd[3] = { -view.cameraToWorld[2], -view.cameraToWorld[6], -view.cameraToWorld[10] };
    const double rel[3] = { w[0] - view.observerX, w[1] - view.observerAltitude, w[2] - view.observerZ };
    const double along = rel[0] * fwd[0] + rel[1] * fwd[1] + rel[2] * fwd[2];
    const double len = std::sqrt(rel[0] * rel[0] + rel[1] * rel[1] + rel[2] * rel[2]);
    PL_CHECK_NEAR(along, anchor.depth, 0.05);
    PL_CHECK_NEAR(len, anchor.depth, 0.05);
}

// A DIRECTION FOLLOWS THE CAMERA: AE's +Z out of a default camera is the rig's view axis,
// and AE's +Y (down) is the rig's down.
PL_TEST(DirectionsFollowTheCamera) {
    const ViewParams view = orbitRig();
    const LightAnchor anchor = lightAnchor(heroScene(), view);
    double cam[16], zoom = 0.0;
    defaultCompCamera(1920.0, 1080.0, cam, zoom);
    const CompLightFrame f = compLightFrame(cam, zoom, 1080.0, false, 1.0, view, anchor);

    const double into[3] = { 0.0, 0.0, 1.0 };
    float d[3];
    compDirectionToWorld(f, view, into, d);
    PL_CHECK_NEAR(d[0], -view.cameraToWorld[2], 1e-5);
    PL_CHECK_NEAR(d[1], -view.cameraToWorld[6], 1e-5);
    PL_CHECK_NEAR(d[2], -view.cameraToWorld[10], 1e-5);

    const double down[3] = { 0.0, 1.0, 0.0 };
    compDirectionToWorld(f, view, down, d);
    PL_CHECK_NEAR(d[0], -view.cameraToWorld[1], 1e-5);
    PL_CHECK_NEAR(d[1], -view.cameraToWorld[5], 1e-5);
    PL_CHECK_NEAR(d[2], -view.cameraToWorld[9], 1e-5);
}

// --------------------------------------------------------------------------
// The light layer
// --------------------------------------------------------------------------

// THE SHEET KEEPS THE LAYER'S POWER: the texels' means times the pixels each covers is the
// pixels' sum, so reducing a bolt to 128 texels neither brightens nor dims what it lights.
PL_TEST(SheetKeepsTheLayersPower) {
    Picture pic(1920, 1080);
    double sum = 0.0;
    for (int i = 0; i < 400; ++i) {
        const int x = 300 + i * 3, y = 100 + (i * 7) % 800;
        pic.set(x, y, 2.0f, 1.5f, 3.0f);
        sum += luminance(2.0, 1.5, 3.0);
    }
    LightSheet s;
    PL_CHECK(buildLightSheet(pic.view(), false, kLightSheetMaxSide, s));
    PL_CHECK_EQ(s.width, 128);
    PL_CHECK_EQ(s.height, 72);
    const double pixelsPerTexel = (1920.0 * 1080.0) / (128.0 * 72.0);
    PL_CHECK_NEAR(s.luminanceSum * pixelsPerTexel / sum, 1.0, 1e-6);

    // A BLACK LAYER IS NO SHEET.
    Picture black(640, 360);
    PL_CHECK(!buildLightSheet(black.view(), false, kLightSheetMaxSide, s));
    PL_CHECK_EQ(s.width, 0);
}

// THE CURVE COMES OFF: an 8 bpc mid grey glows at the linear value it stands for.
PL_TEST(SheetDecodesTheTransferCurve) {
    Picture pic(4, 4);
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 4; ++x) pic.set(x, y, 0.5f, 0.5f, 0.5f);
    LightSheet s;
    PL_CHECK(buildLightSheet(pic.view(), true, kLightSheetMaxSide, s));
    PL_CHECK_NEAR(s.rgb[0], 0.21404, 1e-4);

    for (float x : { 0.0f, 0.001f, 0.04f, 0.2f, 0.5f, 0.9f, 1.0f, 4.0f })
        PL_CHECK_NEAR(decodeSrgb(encodeSrgb(x)), x, 1e-5 + 1e-5 * x);
}

// THE SHEET COVERS THE FRAME: each texel's centre is pushed back through the camera and
// lands on the middle of the pixels it was made from.
PL_TEST(SheetCoversTheFrame) {
    const ViewParams view = orbitRig();
    const int w = 128, h = 72;
    const SheetPlacement s = placeLightSheet(view, 3000.0f, w, h);
    const int probes[][2] = { { 0, 0 }, { 127, 71 }, { 64, 36 }, { 10, 60 } };
    for (const auto& t : probes) {
        float c[3];
        for (int k = 0; k < 3; ++k)
            c[k] = s.origin[k] + s.axisU[k] * (t[0] + 0.5f) + s.axisV[k] * (t[1] + 0.5f);
        double px = 0.0, py = 0.0;
        PL_CHECK(ourProject(view, c, px, py));
        PL_CHECK_NEAR(px, (t[0] + 0.5) * 1920.0 / w, 0.05);
        PL_CHECK_NEAR(py, (t[1] + 0.5) * 1080.0 / h, 0.05);
    }
}

// --------------------------------------------------------------------------
// The packed buffer
// --------------------------------------------------------------------------

// THE LAYOUT LightLib.slang READS, and the picks it divides by.
PL_TEST(PackedLightsAreWhatTheKernelReads) {
    LocalLight point;
    point.kind = LightKind::Point;
    point.position[0] = 100.0f; point.position[1] = 2000.0f; point.position[2] = -50.0f;
    point.color[0] = 1.0f; point.color[1] = 0.5f; point.color[2] = 0.25f;
    point.intensity = 2.0f;
    point.radius = 300.0f;

    LocalLight spot = point;
    spot.kind = LightKind::Spot;
    spot.direction[0] = 0.0f; spot.direction[1] = -2.0f; spot.direction[2] = 0.0f;
    spot.coneAngleDeg = 90.0f;
    spot.coneFeather  = 0.5f;
    spot.smoothFalloff = 200.0f;

    LocalLight sun;
    sun.kind = LightKind::Parallel;
    sun.direction[0] = 0.0f; sun.direction[1] = -1.0f; sun.direction[2] = 0.0f;
    sun.intensity = 0.5f;

    Picture pic(16, 9);
    pic.set(3, 4, 1.0f, 1.0f, 1.0f);
    pic.set(12, 2, 0.0f, 2.0f, 0.0f);
    LightSheet sheet;
    PL_CHECK(buildLightSheet(pic.view(), false, kLightSheetMaxSide, sheet));
    const ViewParams view = orbitRig();
    const SheetPlacement place = placeLightSheet(view, 4000.0f, sheet.width, sheet.height);

    LightAnchor anchor;
    anchor.point[1] = 2000.0f;
    const float ambient[3] = { 0.1f, 0.2f, 0.3f };
    LightSet set;
    packLightSet({ point, spot, sun }, ambient, &sheet, &place, 1.0f, anchor, set);

    PL_CHECK_EQ(set.count, 4);
    PL_CHECK_EQ(static_cast<int>(set.packed[0]), 4);
    PL_CHECK_NEAR(set.packed[3], 0.3, 1e-7);

    // The sheet first, then the order given.
    PL_CHECK_EQ(static_cast<int>(record(set, 0)[0]), static_cast<int>(LightKind::Sheet));
    PL_CHECK_EQ(static_cast<int>(record(set, 1)[0]), static_cast<int>(LightKind::Point));
    PL_CHECK_EQ(static_cast<int>(record(set, 3)[0]), static_cast<int>(LightKind::Parallel));

    // THE PICKS: a CDF ending at exactly 1, probabilities that sum to 1, and none below a
    // tenth of the largest's share.
    double sum = 0.0, maxP = 0.0, minP = 1.0;
    for (int i = 0; i < set.count; ++i) {
        const double p = record(set, i)[2];
        sum += p;
        maxP = std::max(maxP, p);
        minP = std::min(minP, p);
        if (i > 0) PL_CHECK(record(set, i)[1] >= record(set, i - 1)[1]);
    }
    PL_CHECK(record(set, set.count - 1)[1] == 1.0f);
    PL_CHECK_NEAR(sum, 1.0, 1e-6);
    PL_CHECK(minP >= 0.1 * maxP / (1.0 + 1e-6) - 1e-7);

    // A POINT LIGHT IS THE SUN, TIMES ITS INTENSITY, INSIDE ITS RADIUS: I / R^2.
    const float* p = record(set, 1);
    PL_CHECK_NEAR(p[9] / p[12], 2.0 * 1.0 * kLightSunIrradiance, 1e-3);
    PL_CHECK_NEAR(p[10] / p[12], 2.0 * 0.5 * kLightSunIrradiance, 1e-3);

    // THE SPOT'S AXIS IS UNIT AND ITS CONE AE'S: 45 degrees out, 22.5 in at half feather.
    const float* s = record(set, 2);
    PL_CHECK_NEAR(s[7], -1.0, 1e-6);
    PL_CHECK_NEAR(s[13], std::cos(45.0 * kPi / 180.0), 1e-6);
    PL_CHECK_NEAR(s[14], std::cos(22.5 * kPi / 180.0), 1e-6);
    PL_CHECK_NEAR(s[15], 300.0, 1e-3);
    PL_CHECK_NEAR(s[16], 500.0, 1e-3);

    // A PARALLEL LIGHT POINTS TOWARDS ITSELF, like sunDir.
    const float* par = record(set, 3);
    PL_CHECK_NEAR(par[7], 1.0, 1e-6);
    PL_CHECK_NEAR(par[9], 0.5 * kLightSunIrradiance, 1e-4);

    // THE SHEET'S TEXELS AND ITS TREE, WHERE ITS RECORD SAYS. 16 x 9 texels is a 16 x 16
    // tree four levels below its root, and the record carries the eye.
    const float* sh = record(set, 0);
    const int n = static_cast<int>(sh[13]) * static_cast<int>(sh[14]);
    const size_t off  = static_cast<size_t>(sh[15]);
    const size_t tree = static_cast<size_t>(sh[19]);
    PL_CHECK_EQ(off, static_cast<size_t>(kLightHeaderFloats + 4 * kLightRecordFloats));
    PL_CHECK_EQ(tree, off + static_cast<size_t>(n) * kSheetTexelFloats);
    PL_CHECK_EQ(static_cast<int>(set.packed[tree]), 4);
    const size_t cells = 1 + 4 + 16 + 64 + 256;
    PL_CHECK_EQ(set.packed.size(), tree + 1 + cells * kSheetCellFloats);
    for (int k = 0; k < 3; ++k) PL_CHECK_NEAR(sh[9 + k], place.eye[k], 1e-3);

    // THE ROOT HOLDS ALL THE LIGHT, and its centroid is the light's, in the world: the white
    // texel at (3.5, 4.5) with luminance 100, the green at (12.5, 2.5) with 143.04, each
    // times a texel's area -- on the plane, unconformed, so the same area.
    const int green = 2 * 16 + 12;
    const double area = static_cast<double>(sh[12]);
    const double lw = 1.0 * kLightLayerRadiance, lg = 2.0 * 0.7152 * kLightLayerRadiance;
    const double cu = (3.5 * lw + 12.5 * lg) / (lw + lg), cv = (4.5 * lw + 2.5 * lg) / (lw + lg);
    PL_CHECK_NEAR(set.packed[tree + 1] / ((lw + lg) * area), 1.0, 1e-5);
    for (int k = 0; k < 3; ++k) {
        const double want = place.origin[k] + place.axisU[k] * cu + place.axisV[k] * cv;
        PL_CHECK_NEAR(set.packed[tree + 2 + k], want, 0.05);
    }
    // ...and the green texel's leaf is the green texel, a texel across.
    const size_t leaf = tree + 1 + (85 + 2 * 16 + 12) * kSheetCellFloats;
    PL_CHECK_NEAR(set.packed[leaf] / (lg * area), 1.0, 1e-5);
    PL_CHECK_NEAR(set.packed[leaf + 1], place.origin[0] + place.axisU[0] * 12.5 + place.axisV[0] * 2.5,
                  0.05);
    PL_CHECK_NEAR(set.packed[leaf + 4] / area, 1.0, 1e-4);
    PL_CHECK_NEAR(set.packed[off + green * kSheetTexelFloats + 1], 2.0 * kLightLayerRadiance, 1e-3);
    PL_CHECK_NEAR(set.packed[off + green * kSheetTexelFloats + 3], 1.0, 1e-7);

    // THE HASH MOVES WITH A LIGHT.
    LightSet brighter;
    point.intensity = 2.5f;
    packLightSet({ point, spot, sun }, ambient, &sheet, &place, 1.0f, anchor, brighter);
    PL_CHECK(brighter.hash != set.hash);
}

// --------------------------------------------------------------------------
// The sheet, laid on the cloud
// --------------------------------------------------------------------------

namespace {

// Where texel (x, y) of a placement stands, its scale applied.
void texelAt(const SheetPlacement& p, int x, int y, float s, float out[3]) {
    for (int k = 0; k < 3; ++k) {
        const double c = p.origin[k] + p.axisU[k] * (x + 0.5) + p.axisV[k] * (y + 0.5);
        out[k] = static_cast<float>(p.eye[k] + (c - p.eye[k]) * s);
    }
}

double viewDepth(const ViewParams& v, const float q[3]) {
    const Real* m = v.cameraToWorld;
    return -((q[0] - v.observerX) * m[2] + (q[1] - v.observerAltitude) * m[6] +
             (q[2] - v.observerZ) * m[10]);
}

// A 16 x 9 layer with three lit pixels, one of them in a corner.
Picture threeLit() {
    Picture pic(16, 9);
    pic.set(3, 4, 1.0f, 1.0f, 1.0f);
    pic.set(12, 2, 0.0f, 2.0f, 0.0f);
    pic.set(0, 0, 0.5f, 0.5f, 0.5f);
    return pic;
}

} // namespace

// THE PROBE'S GRID IS HALF THE SHEET'S, AND ONLY WHAT A LIT TEXEL READS IS ASKED FOR: the
// four points round each lit texel's centre, and nothing else.
PL_TEST(SurfaceProbeAsksOnlyWhereTheLayerGlows) {
    const Picture pic = threeLit();
    LightSheet sheet;
    PL_CHECK(buildLightSheet(pic.view(), false, kLightSheetMaxSide, sheet));
    int gw = 0, gh = 0;
    surfaceProbeGrid(sheet, gw, gh);
    PL_CHECK_EQ(gw, 8);
    PL_CHECK_EQ(gh, 5);

    const std::vector<unsigned char> need = surfaceProbeMask(sheet, gw, gh);
    PL_CHECK_EQ(static_cast<int>(need.size()), gw * gh);
    // (3, 4): x at grid 1.25 reads points 1 and 2; y at grid 2.0 reads rows 2 and 3.
    PL_CHECK(need[2 * gw + 1] && need[2 * gw + 2] && need[3 * gw + 1] && need[3 * gw + 2]);
    // (0, 0) clamps into the corner point.
    PL_CHECK(need[0]);
    int marked = 0;
    for (unsigned char c : need) marked += c ? 1 : 0;
    PL_CHECK(marked <= 12);
    PL_CHECK(!need[4 * gw + 7]);

    // GRID POINTS ARE THE CENTRES OF THEIR CELLS OF THE FRAME.
    float fx = 0.0f, fy = 0.0f;
    surfaceProbePixel(0, 0, gw, gh, 1920, 1080, fx, fy);
    PL_CHECK_NEAR(fx, 120.0, 1e-3);
    PL_CHECK_NEAR(fy, 108.0, 1e-3);
}

// A TEXEL LAID ON THE CLOUD STAYS ON ITS PIXEL, at the depth the probe found plus Light Layer
// Depth -- and where the camera sees no cloud it takes the nearest face that was seen, or with
// none seen at all, the fallback.
PL_TEST(SheetIsLaidOnTheFaceTheCameraSees) {
    const ViewParams view = orbitRig();
    const Picture pic = threeLit();
    LightSheet sheet;
    PL_CHECK(buildLightSheet(pic.view(), false, kLightSheetMaxSide, sheet));

    SheetPlacement place = placeLightSheet(view, 4000.0f, sheet.width, sheet.height);
    PL_CHECK_NEAR(place.planeDepth, 4000.0, 1e-3);
    PL_CHECK_NEAR(place.eye[1], view.observerAltitude, 1e-3);

    // THE PROBE LOOKS NO FURTHER THAN THE HERO GOES: at least its width behind its middle.
    PL_CHECK(lightAnchor(heroScene(), view).reach >= heroScene().convection.heroWidth);

    SurfaceProbe probe;
    surfaceProbeGrid(sheet, probe.width, probe.height);
    const size_t gn = static_cast<size_t>(probe.width) * probe.height;
    const std::vector<unsigned char> need = surfaceProbeMask(sheet, probe.width, probe.height);

    // EVERY POINT SEES A FACE AT 3000 m: every lit texel at 3200, on its own pixel.
    probe.depth.assign(gn, 0.0f);
    probe.hit.assign(gn, 0.0f);
    for (size_t k = 0; k < gn; ++k) {
        if (!need[k]) continue;
        probe.depth[k] = 3000.0f;
        probe.hit[k] = 1.0f;
    }
    conformLightSheet(sheet, probe, 5000.0f, 200.0f, place);
    PL_CHECK_EQ(place.scale.size(), static_cast<size_t>(sheet.width) * sheet.height);
    const int lit[][2] = { { 3, 4 }, { 12, 2 }, { 0, 0 } };
    for (const auto& t : lit) {
        const float s = place.scale[static_cast<size_t>(t[1]) * sheet.width + t[0]];
        PL_CHECK_NEAR(s, 3200.0 / 4000.0, 1e-5);
        float q[3];
        texelAt(place, t[0], t[1], s, q);
        double px = 0.0, py = 0.0;
        PL_CHECK(ourProject(view, q, px, py));
        PL_CHECK_NEAR(px, (t[0] + 0.5) * 1920.0 / sheet.width, 0.05);
        PL_CHECK_NEAR(py, (t[1] + 0.5) * 1080.0 / sheet.height, 0.05);
        PL_CHECK_NEAR(viewDepth(view, q), 3200.0, 0.5);
    }
    // AN UNLIT TEXEL IS LEFT ON THE PLANE: nothing reads it.
    PL_CHECK_NEAR(place.scale[1 * sheet.width + 8], 1.0, 1e-7);

    // ONE POINT HALF SEES A FACE AT 2000 m, THE REST SEE NOTHING: the nearest face seen is
    // everyone's, so a bolt leaving the cloud's edge stays beside it.
    for (size_t k = 0; k < gn; ++k) {
        probe.depth[k] = 0.0f;
        probe.hit[k] = 0.0f;
    }
    probe.depth[2 * probe.width + 1] = 2000.0f;
    probe.hit[2 * probe.width + 1] = 0.5f;
    conformLightSheet(sheet, probe, 5000.0f, 0.0f, place);
    for (const auto& t : lit) {
        PL_CHECK_NEAR(place.scale[static_cast<size_t>(t[1]) * sheet.width + t[0]], 0.5, 1e-5);
    }

    // NOTHING SEEN ANYWHERE: the fallback, and Light Layer Depth from it.
    probe.hit[2 * probe.width + 1] = 0.0f;
    conformLightSheet(sheet, probe, 5000.0f, -300.0f, place);
    PL_CHECK_NEAR(place.scale[4 * sheet.width + 3], 4700.0 / 4000.0, 1e-5);

    // AND A FACE IN FRONT OF THE EYE IS FLOORED: never nearer than 10 m.
    for (size_t k = 0; k < gn; ++k) {
        probe.depth[k] = 5.0f;
        probe.hit[k] = need[k] ? 1.0f : 0.0f;
    }
    conformLightSheet(sheet, probe, 5000.0f, -100.0f, place);
    PL_CHECK_NEAR(place.scale[4 * sheet.width + 3], 10.0 / 4000.0, 1e-6);
}

// A LAID SHEET PACKS WHERE ITS TEXELS STAND: a leaf's centroid is its pushed texel, its power
// the radiance times the pushed area, and the texel carries its scale for the kernel.
PL_TEST(LaidSheetPacksWhereItsTexelsStand) {
    const ViewParams view = orbitRig();
    const Picture pic = threeLit();
    LightSheet sheet;
    PL_CHECK(buildLightSheet(pic.view(), false, kLightSheetMaxSide, sheet));
    SheetPlacement place = placeLightSheet(view, 4000.0f, sheet.width, sheet.height);
    place.scale.assign(static_cast<size_t>(sheet.width) * sheet.height, 1.0f);
    place.scale[4 * sheet.width + 3] = 0.6f;
    place.scale[2 * sheet.width + 12] = 1.25f;

    LightAnchor anchor;
    const float none[3] = { 0.0f, 0.0f, 0.0f };
    LightSet set;
    packLightSet({}, none, &sheet, &place, 1.0f, anchor, set);
    PL_CHECK_EQ(set.count, 1);

    const float* sh = record(set, 0);
    const size_t off  = static_cast<size_t>(sh[15]);
    const size_t tree = static_cast<size_t>(sh[19]);
    const double area = sh[12];
    const size_t leaves = 1 + 4 + 16 + 64;   // level 4 starts after levels 0..3

    const int white = 4 * 16 + 3;
    PL_CHECK_NEAR(set.packed[off + white * kSheetTexelFloats + 3], 0.6, 1e-7);
    const size_t wl = tree + 1 + (leaves + 4 * 16 + 3) * kSheetCellFloats;
    PL_CHECK_NEAR(set.packed[wl] / (kLightLayerRadiance * area * 0.36), 1.0, 1e-5);
    float q[3];
    texelAt(place, 3, 4, 0.6f, q);
    for (int k = 0; k < 3; ++k) PL_CHECK_NEAR(set.packed[wl + 1 + k], q[k], 0.05);
    PL_CHECK_NEAR(set.packed[wl + 4] / (area * 0.36), 1.0, 1e-4);

    // THE ROOT'S RADIUS HOLDS EVERY LIT TEXEL, wherever it was pushed to.
    const double root[3] = { set.packed[tree + 2], set.packed[tree + 3], set.packed[tree + 4] };
    const double reach = std::sqrt(static_cast<double>(set.packed[tree + 5]));
    const int lit[][2] = { { 3, 4 }, { 12, 2 }, { 0, 0 } };
    for (const auto& t : lit) {
        float c[3];
        texelAt(place, t[0], t[1], place.scale[static_cast<size_t>(t[1]) * sheet.width + t[0]], c);
        const double d = std::sqrt((c[0] - root[0]) * (c[0] - root[0]) + (c[1] - root[1]) * (c[1] - root[1]) +
                                   (c[2] - root[2]) * (c[2] - root[2]));
        PL_CHECK(d <= reach + 1e-2);
    }
}

// NOTHING IN IS NOTHING OUT: no lights, no sheet, no ambient is an empty set, which the
// request turns into no buffer and the kernel into no extra draw.
PL_TEST(NoLightsIsAnEmptySet) {
    LightSet set;
    const float none[3] = { 0.0f, 0.0f, 0.0f };
    LocalLight black;
    black.color[0] = black.color[1] = black.color[2] = 0.0f;
    packLightSet({ black }, none, nullptr, nullptr, 1.0f, LightAnchor{}, set);
    PL_CHECK_EQ(set.count, 0);
    PL_CHECK(set.empty());
}
