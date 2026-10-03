#include "LocalLights.h"

#include "ConvectionField.h"
#include "OrbitCamera.h"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace plugin::cloud {

namespace {

constexpr double kPi = 3.14159265358979323846;

// Rec. 709 luminance: how the pick weights and the sheet's table see a colour. Any
// positive weighting is unbiased; this one spends samples where the eye looks.
double luminance(double r, double g, double b) {
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double dot3(const double a[3], const double b[3]) {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

// A camera-space vector into the world, through the row-major camera-to-world's 3x3.
void rotateToWorld(const ViewParams& view, const double v[3], double out[3]) {
    const Real* m = view.cameraToWorld;
    for (int r = 0; r < 3; ++r) {
        out[r] = static_cast<double>(m[r * 4 + 0]) * v[0] +
                 static_cast<double>(m[r * 4 + 1]) * v[1] +
                 static_cast<double>(m[r * 4 + 2]) * v[2];
    }
}

// THE AE CAMERA'S AXES, unit length. A camera carries no scale, but a matrix read off a
// host is normalised rather than trusted: a scaled axis would scale every light.
void cameraAxes(const double cam[16], double axis[3][3]) {
    for (int r = 0; r < 3; ++r) {
        double len = 0.0;
        for (int c = 0; c < 3; ++c) len += cam[r * 4 + c] * cam[r * 4 + c];
        len = len > 0.0 ? std::sqrt(len) : 1.0;
        for (int c = 0; c < 3; ++c) axis[r][c] = cam[r * 4 + c] / len;
    }
}

// A comp-space vector in the renderer's camera space, scaled: AE's camera axes first,
// then the flip of Y and Z, then the frame's two scales.
void compToCameraSpace(const CompLightFrame& f, const double v[3], double out[3]) {
    double axis[3][3];
    cameraAxes(f.camera, axis);
    out[0] =  dot3(v, axis[0]) * f.across;
    out[1] = -dot3(v, axis[1]) * f.across;
    out[2] = -dot3(v, axis[2]) * f.along;
}

void fnv(uint64_t& h, const void* p, size_t n) {
    const unsigned char* b = static_cast<const unsigned char*>(p);
    for (size_t i = 0; i < n; ++i) {
        h ^= b[i];
        h *= 1099511628211ull;
    }
}

float finiteOrZero(double v) {
    return std::isfinite(v) ? static_cast<float>(v) : 0.0f;
}

} // namespace

// ---------------------------------------------------------------------------
// Colour
// ---------------------------------------------------------------------------

float decodeSrgb(float encoded) {
    if (!(encoded > 0.0f))     return 0.0f;
    if (encoded <= 0.04045f)   return encoded / 12.92f;
    return std::pow((encoded + 0.055f) / 1.055f, 2.4f);
}

void spotCosines(float coneAngleDeg, float feather, float& cosOuter, float& cosInner) {
    const double angle = std::clamp(static_cast<double>(coneAngleDeg), 0.0, 180.0);
    const double soft  = std::clamp(static_cast<double>(feather), 0.0, 1.0);
    const double half  = 0.5 * angle * kPi / 180.0;
    cosOuter = static_cast<float>(std::cos(half));
    cosInner = static_cast<float>(std::cos(half * (1.0 - soft)));
}

// ---------------------------------------------------------------------------
// The light layer
// ---------------------------------------------------------------------------

bool buildLightSheet(const ConstImageView& image, bool srgb, int maxSide, LightSheet& out) {
    out = LightSheet{};
    if (!image.valid() || maxSide < 1) return false;

    const int w = image.width;
    const int h = image.height;
    const int longer = std::max(w, h);

    // THE TEXEL GRID KEEPS THE LAYER'S ASPECT, so a texel is square in the frame when the
    // layer is the frame's shape. Each pixel lands in the texel under its own left edge:
    // texel = x * tw / w, which gives every texel the same span to within a pixel.
    int tw = w, th = h;
    if (longer > maxSide) {
        tw = std::max(1, static_cast<int>(std::lround(static_cast<double>(w) * maxSide / longer)));
        th = std::max(1, static_cast<int>(std::lround(static_cast<double>(h) * maxSide / longer)));
    }

    std::vector<double> sum(static_cast<size_t>(tw) * th * 3, 0.0);
    std::vector<int>    count(static_cast<size_t>(tw) * th, 0);

    for (int y = 0; y < h; ++y) {
        const int ty = static_cast<int>(static_cast<long long>(y) * th / h);
        for (int x = 0; x < w; ++x) {
            const int tx = static_cast<int>(static_cast<long long>(x) * tw / w);
            const Texel p = readPixel(image, x, y);
            float c[3] = { static_cast<float>(p.r), static_cast<float>(p.g),
                           static_cast<float>(p.b) };
            for (float& v : c) {
                if (!std::isfinite(v) || v < 0.0f) v = 0.0f;
                if (srgb) v = decodeSrgb(v);
            }
            const size_t t = static_cast<size_t>(ty) * tw + tx;
            sum[t * 3 + 0] += c[0];
            sum[t * 3 + 1] += c[1];
            sum[t * 3 + 2] += c[2];
            ++count[t];
        }
    }

    out.width  = tw;
    out.height = th;
    out.rgb.assign(static_cast<size_t>(tw) * th * 3, 0.0f);
    double lum = 0.0;
    for (size_t t = 0; t < count.size(); ++t) {
        if (count[t] == 0) continue;
        const double inv = 1.0 / count[t];
        for (int c = 0; c < 3; ++c) out.rgb[t * 3 + c] = static_cast<float>(sum[t * 3 + c] * inv);
        lum += luminance(out.rgb[t * 3 + 0], out.rgb[t * 3 + 1], out.rgb[t * 3 + 2]);
    }
    out.luminanceSum = lum;

    // NOTHING GLOWS: a bolt between strikes, or a layer left black. No sheet, rather than
    // a sheet the kernel would pick and find dark.
    if (!(lum > 1e-9)) {
        out = LightSheet{};
        return false;
    }
    return true;
}

SheetPlacement placeLightSheet(const ViewParams& view, float depth, int width, int height) {
    SheetPlacement s;
    if (width <= 0 || height <= 0 || view.widthPx <= 0 || view.heightPx <= 0) return s;

    // THE FRAME AT THAT DEPTH, as primaryRayDirection draws it: half-height tan(fov/2)
    // times the depth, and the width by the frame's aspect.
    const double d      = depth > 1.0f ? static_cast<double>(depth) : 1.0;
    const double t      = std::tan(static_cast<double>(view.verticalFovDegrees) * kPi / 360.0);
    const double halfH  = t * d;
    const double halfW  = halfH * static_cast<double>(view.widthPx) / view.heightPx;

    const double corner[3] = { -halfW, halfH, -d };
    const double stepU[3]  = { 2.0 * halfW / width, 0.0, 0.0 };
    const double stepV[3]  = { 0.0, -2.0 * halfH / height, 0.0 };

    double c[3], u[3], v[3];
    rotateToWorld(view, corner, c);
    rotateToWorld(view, stepU, u);
    rotateToWorld(view, stepV, v);

    s.origin[0] = static_cast<float>(view.observerX + c[0]);
    s.origin[1] = static_cast<float>(view.observerAltitude + c[1]);
    s.origin[2] = static_cast<float>(view.observerZ + c[2]);
    for (int k = 0; k < 3; ++k) {
        s.axisU[k] = static_cast<float>(u[k]);
        s.axisV[k] = static_cast<float>(v[k]);
    }
    s.eye[0] = static_cast<float>(view.observerX);
    s.eye[1] = static_cast<float>(view.observerAltitude);
    s.eye[2] = static_cast<float>(view.observerZ);
    s.planeDepth = static_cast<float>(d);
    return s;
}

// ---------------------------------------------------------------------------
// The sheet, laid on the cloud
// ---------------------------------------------------------------------------

namespace {

bool texelLit(const LightSheet& s, size_t t) {
    return luminance(s.rgb[t * 3 + 0], s.rgb[t * 3 + 1], s.rgb[t * 3 + 2]) > 0.0;
}

// Where texel x's centre falls between the probe's points along one axis: the two points
// it reads and the second one's weight. Point i is the centre of its cell of the frame, as
// surfaceProbePixel puts it, and past the outer points a texel takes the outer one.
void probeSpan(int x, int texels, int points, int& i0, int& i1, double& f) {
    const double g = (x + 0.5) * points / texels - 0.5;
    const double c = std::clamp(g, 0.0, static_cast<double>(points - 1));
    i0 = std::min(static_cast<int>(std::floor(c)), points - 1);
    i1 = std::min(i0 + 1, points - 1);
    f  = c - i0;
}

} // namespace

void surfaceProbeGrid(const LightSheet& sheet, int& gridWidth, int& gridHeight) {
    gridWidth  = std::max(1, (sheet.width + 1) / 2);
    gridHeight = std::max(1, (sheet.height + 1) / 2);
}

void surfaceProbePixel(int i, int j, int gridWidth, int gridHeight, int frameWidth,
                       int frameHeight, float& fx, float& fy) {
    fx = static_cast<float>((i + 0.5) * frameWidth / std::max(gridWidth, 1));
    fy = static_cast<float>((j + 0.5) * frameHeight / std::max(gridHeight, 1));
}

std::vector<unsigned char> surfaceProbeMask(const LightSheet& sheet, int gw, int gh) {
    std::vector<unsigned char> need(gw > 0 && gh > 0 ? static_cast<size_t>(gw) * gh : 0, 0);
    const int w = sheet.width, h = sheet.height;
    if (need.empty() || w <= 0 || h <= 0 ||
        sheet.rgb.size() != static_cast<size_t>(w) * h * 3) return need;

    for (int y = 0; y < h; ++y) {
        int j0, j1;
        double fy;
        probeSpan(y, h, gh, j0, j1, fy);
        for (int x = 0; x < w; ++x) {
            if (!texelLit(sheet, static_cast<size_t>(y) * w + x)) continue;
            int i0, i1;
            double fx;
            probeSpan(x, w, gw, i0, i1, fx);
            need[static_cast<size_t>(j0) * gw + i0] = 1;
            need[static_cast<size_t>(j0) * gw + i1] = 1;
            need[static_cast<size_t>(j1) * gw + i0] = 1;
            need[static_cast<size_t>(j1) * gw + i1] = 1;
        }
    }
    return need;
}

void conformLightSheet(const LightSheet& sheet, const SurfaceProbe& probe,
                       float fallbackDepth, float extraDepth, SheetPlacement& place) {
    place.scale.clear();
    const int w = sheet.width, h = sheet.height;
    const size_t n = static_cast<size_t>(std::max(w, 0)) * std::max(h, 0);
    if (n == 0 || sheet.rgb.size() != n * 3 || !(place.planeDepth > 0.0f)) return;

    const double fallback = std::isfinite(fallbackDepth) ? fallbackDepth : place.planeDepth;
    const double extra    = std::isfinite(extraDepth) ? extraDepth : 0.0;

    const int    gw = probe.width, gh = probe.height;
    const size_t gn = gw > 0 && gh > 0 ? static_cast<size_t>(gw) * gh : 0;
    const bool probed = gn > 0 && probe.depth.size() == gn && probe.hit.size() == gn;

    // ===================================================================
    // EACH GRID POINT'S DEPTH: its own face, mixed by its hit with the nearest face the probe
    // saw anywhere else -- inverse fourth power of the distance in grid points, weighted by
    // each face's hit, which is the nearest one with its neighbours softened in. A probe that
    // saw nothing anywhere is the fallback everywhere.
    //
    // ONLY THE POINTS A LIT TEXEL READS, which are the only ones the probe took. Quadratic in
    // them, and at most 64 x 36 of them: milliseconds.
    // ===================================================================
    std::vector<double> node(gn, fallback);
    if (probed) {
        const std::vector<unsigned char> need = surfaceProbeMask(sheet, gw, gh);
        std::vector<size_t> seen;
        for (size_t k = 0; k < gn; ++k) {
            if (need[k] && probe.hit[k] > 1e-4f && std::isfinite(probe.depth[k]))
                seen.push_back(k);
        }
        if (!seen.empty()) {
            for (size_t k = 0; k < gn; ++k) {
                if (!need[k]) continue;
                const bool   own = probe.hit[k] > 1e-4f && std::isfinite(probe.depth[k]);
                const double hk  = own ? std::min(1.0, static_cast<double>(probe.hit[k])) : 0.0;
                double fill = own ? probe.depth[k] : fallback;
                if (hk < 0.999) {
                    const int ki = static_cast<int>(k % gw), kj = static_cast<int>(k / gw);
                    double sw = 0.0, sd = 0.0;
                    for (size_t j : seen) {
                        if (j == k) continue;
                        const double dx = static_cast<int>(j % gw) - ki;
                        const double dy = static_cast<int>(j / gw) - kj;
                        const double d2 = dx * dx + dy * dy;
                        const double wt = std::min(1.0, static_cast<double>(probe.hit[j])) / (d2 * d2);
                        sw += wt;
                        sd += wt * probe.depth[j];
                    }
                    if (sw > 0.0) fill = sd / sw;
                }
                node[k] = own ? hk * probe.depth[k] + (1.0 - hk) * fill : fill;
            }
        }
    }

    // EVERY LIT TEXEL, bilinear between the four points under it, then Light Layer Depth.
    place.scale.assign(n, 1.0f);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const size_t t = static_cast<size_t>(y) * w + x;
            if (!texelLit(sheet, t)) continue;
            double depth = fallback;
            if (probed) {
                int i0, i1, j0, j1;
                double fx, fy;
                probeSpan(x, w, gw, i0, i1, fx);
                probeSpan(y, h, gh, j0, j1, fy);
                const double top = node[static_cast<size_t>(j0) * gw + i0] * (1.0 - fx) +
                                   node[static_cast<size_t>(j0) * gw + i1] * fx;
                const double bot = node[static_cast<size_t>(j1) * gw + i0] * (1.0 - fx) +
                                   node[static_cast<size_t>(j1) * gw + i1] * fx;
                depth = top * (1.0 - fy) + bot * fy;
            }
            depth = std::max(depth + extra, 10.0);
            place.scale[t] = static_cast<float>(depth / place.planeDepth);
        }
    }
}

// ---------------------------------------------------------------------------
// The anchor
// ---------------------------------------------------------------------------

LightAnchor lightAnchor(const FieldParams& field, const ViewParams& view) {
    Real lo = 0, hi = 0;
    orbitAimSpan(field, lo, hi);
    Real hx = 0, hz = 0;
    heroPositionNow(field, hx, hz);

    LightAnchor a;
    a.point[0] = static_cast<float>(hx);
    a.point[1] = static_cast<float>(0.5 * (static_cast<double>(lo) + static_cast<double>(hi)));
    a.point[2] = static_cast<float>(hz);

    // THE VIEW AXIS IS THE CAMERA'S -Z, the matrix's third column negated.
    const Real* m = view.cameraToWorld;
    const double fwd[3] = { -static_cast<double>(m[2]), -static_cast<double>(m[6]),
                            -static_cast<double>(m[10]) };
    const double rel[3] = { a.point[0] - static_cast<double>(view.observerX),
                            a.point[1] - static_cast<double>(view.observerAltitude),
                            a.point[2] - static_cast<double>(view.observerZ) };
    const double depth = dot3(rel, fwd);
    a.depth = depth > 100.0 ? static_cast<float>(depth) : 100.0f;
    a.reach = static_cast<float>(std::max(static_cast<double>(field.convection.heroWidth),
                                          static_cast<double>(hi) - static_cast<double>(lo)));
    return a;
}

// ---------------------------------------------------------------------------
// The comp, through the camera
// ---------------------------------------------------------------------------

void defaultCompCamera(double compWidth, double compHeight, double outMatrix[16],
                       double& outPlaneDistance) {
    const double zoom = compWidth * (50.0 / 36.0);
    const double m[16] = {
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        compWidth * 0.5, compHeight * 0.5, -zoom, 1.0
    };
    std::memcpy(outMatrix, m, sizeof m);
    outPlaneDistance = zoom;
}

CompLightFrame compLightFrame(const double aeCamera[16], double planeDistance,
                              double planeHeight, bool compCamera, double travel,
                              const ViewParams& view, const LightAnchor& anchor) {
    CompLightFrame f;
    std::memcpy(f.camera, aeCamera, sizeof f.camera);

    if (compCamera) {
        // THE CAMERA'S OWN SCALE, so a light and the camera move through one world. Travel
        // 0 keeps the camera still; the lights still need a size, and a pixel is a metre.
        const double k = travel > 0.0 ? travel : 1.0;
        f.across = k;
        f.along  = k;
        return f;
    }

    // THE COMP PLANE AT THE ANCHOR'S DEPTH, and the frame stretched by the lenses' ratio.
    const double zoom  = planeDistance > 1.0 ? planeDistance : 1.0;
    const double tanAE = planeHeight > 0.0 ? 0.5 * planeHeight / zoom : 0.5 * 1080.0 / zoom;
    const double tanUs = std::tan(static_cast<double>(view.verticalFovDegrees) * kPi / 360.0);
    f.along  = static_cast<double>(anchor.depth) / zoom;
    f.across = tanAE > 0.0 && tanUs > 0.0 ? f.along * tanUs / tanAE : f.along;
    return f;
}

void compPointToWorld(const CompLightFrame& f, const ViewParams& view,
                      const double p[3], float out[3]) {
    const double rel[3] = { p[0] - f.camera[12], p[1] - f.camera[13], p[2] - f.camera[14] };
    double cam[3], world[3];
    compToCameraSpace(f, rel, cam);
    rotateToWorld(view, cam, world);
    out[0] = finiteOrZero(static_cast<double>(view.observerX) + world[0]);
    out[1] = finiteOrZero(static_cast<double>(view.observerAltitude) + world[1]);
    out[2] = finiteOrZero(static_cast<double>(view.observerZ) + world[2]);
}

void compDirectionToWorld(const CompLightFrame& f, const ViewParams& view,
                          const double d[3], float out[3]) {
    double cam[3], world[3];
    compToCameraSpace(f, d, cam);
    rotateToWorld(view, cam, world);
    const double len = std::sqrt(dot3(world, world));
    if (!(len > 0.0)) {
        out[0] = 0.0f; out[1] = -1.0f; out[2] = 0.0f;
        return;
    }
    for (int k = 0; k < 3; ++k) out[k] = static_cast<float>(world[k] / len);
}

// ---------------------------------------------------------------------------
// Packing
// ---------------------------------------------------------------------------

void packLightSet(const std::vector<LocalLight>& lights, const float ambient[3],
                  const LightSheet* sheet, const SheetPlacement* place,
                  float sheetStrength, const LightAnchor& anchor, LightSet& out) {
    out = LightSet{};
    if (ambient) {
        for (int c = 0; c < 3; ++c) {
            out.ambient[c] = std::isfinite(ambient[c]) && ambient[c] > 0.0f ? ambient[c] : 0.0f;
        }
    }

    struct Record {
        float  v[kLightRecordFloats];
        double weight;
    };
    std::vector<Record> records;
    std::vector<float>  sheetData;

    const double at[3] = { anchor.point[0], anchor.point[1], anchor.point[2] };

    // THE SHEET FIRST, so a comp with too many lights drops a comp light rather than the
    // layer the user picked by name.
    const bool haveSheet = sheet && place && sheet->width > 0 && sheet->height > 0 &&
                           sheetStrength > 0.0f && std::isfinite(sheetStrength) &&
                           sheet->rgb.size() == static_cast<size_t>(sheet->width) * sheet->height * 3;
    if (haveSheet) {
        const int    w = sheet->width;
        const int    h = sheet->height;
        const size_t n = static_cast<size_t>(w) * h;

        const double u[3] = { place->axisU[0], place->axisU[1], place->axisU[2] };
        const double v[3] = { place->axisV[0], place->axisV[1], place->axisV[2] };
        const double eye[3] = { place->eye[0], place->eye[1], place->eye[2] };
        const double area   = std::sqrt(dot3(u, u)) * std::sqrt(dot3(v, v));
        const double diagSq = dot3(u, u) + dot3(v, v);
        const double scale  = static_cast<double>(sheetStrength) * kLightLayerRadiance;
        const bool conformed = place->scale.size() == n;

        // THE TEXELS' RADIANCE AND DEPTH SCALE, then THE TREE the kernel draws them down:
        // level 0 the whole sheet, level `levels` the texels, each level a square of 2^k x 2^k
        // cells, row by row. A cell is its power, its power's centroid in the world and a
        // radius round that which holds every texel in it -- a leaf's is its texel's size where
        // it stands, a parent's the smallest round its centroid that holds its children's.
        // Built bottom up in double, so a parent is its children's sum to the float. See
        // LightLib.slang.
        int levels = 0;
        while ((1 << levels) < std::max(w, h)) ++levels;
        const int side = 1 << levels;
        size_t cells = 0;
        for (int k = 0; k <= levels; ++k) cells += static_cast<size_t>(1) << (2 * k);

        std::vector<double> pw(cells, 0.0), reach(cells, 0.0);
        std::vector<double> cx(cells, 0.0), cy(cells, 0.0), cz(cells, 0.0);
        auto levelStart = [](int k) { return ((static_cast<size_t>(1) << (2 * k)) - 1) / 3; };

        const size_t texelFloats = n * kSheetTexelFloats;
        sheetData.assign(texelFloats + 1 + cells * kSheetCellFloats, 0.0f);
        double total = 0.0, weight = 0.0;
        for (size_t t = 0; t < n; ++t) {
            double s = conformed ? static_cast<double>(place->scale[t]) : 1.0;
            if (!(s > 0.0) || !std::isfinite(s)) s = 1.0;

            const double r = sheet->rgb[t * 3 + 0] * scale;
            const double g = sheet->rgb[t * 3 + 1] * scale;
            const double b = sheet->rgb[t * 3 + 2] * scale;
            sheetData[t * kSheetTexelFloats + 0] = static_cast<float>(r);
            sheetData[t * kSheetTexelFloats + 1] = static_cast<float>(g);
            sheetData[t * kSheetTexelFloats + 2] = static_cast<float>(b);
            sheetData[t * kSheetTexelFloats + 3] = static_cast<float>(s);
            const double l = luminance(r, g, b);
            if (!(l > 0.0)) continue;
            total += l;

            const int    x  = static_cast<int>(t % static_cast<size_t>(w));
            const int    y  = static_cast<int>(t / static_cast<size_t>(w));
            const size_t at0 = levelStart(levels) + static_cast<size_t>(y) * side + x;

            // WHERE THE TEXEL STANDS: its patch of the plane, pushed along the eye's ray.
            double q[3];
            for (int k = 0; k < 3; ++k) {
                const double c = place->origin[k] + u[k] * (x + 0.5) + v[k] * (y + 0.5);
                q[k] = eye[k] + (c - eye[k]) * s;
            }
            const double a = area * s * s;
            pw[at0]    = l * a;
            cx[at0]    = q[0];
            cy[at0]    = q[1];
            cz[at0]    = q[2];
            reach[at0] = s * std::sqrt(std::max(0.25 * diagSq, area));

            // HOW BRIGHTLY THIS TEXEL LIGHTS THE ANCHOR, as the kernel would see it.
            double d2 = 0.0;
            for (int k = 0; k < 3; ++k) d2 += (q[k] - at[k]) * (q[k] - at[k]);
            weight += l * a / std::max(d2, a);
        }

        if (total > 0.0 && area > 0.0) {
            for (int k = levels - 1; k >= 0; --k) {
                const int across = 1 << k;
                for (int y = 0; y < across; ++y) {
                    for (int x = 0; x < across; ++x) {
                        const size_t parent = levelStart(k) + static_cast<size_t>(y) * across + x;
                        size_t child[4];
                        double s = 0.0, sx = 0.0, sy = 0.0, sz = 0.0;
                        for (int c = 0; c < 4; ++c) {
                            child[c] = levelStart(k + 1) +
                                       static_cast<size_t>(2 * y + (c >> 1)) * (2 * across) +
                                       (2 * x + (c & 1));
                            s  += pw[child[c]];
                            sx += pw[child[c]] * cx[child[c]];
                            sy += pw[child[c]] * cy[child[c]];
                            sz += pw[child[c]] * cz[child[c]];
                        }
                        pw[parent] = s;
                        if (!(s > 0.0)) continue;
                        cx[parent] = sx / s;
                        cy[parent] = sy / s;
                        cz[parent] = sz / s;
                        double r = 0.0;
                        for (int c = 0; c < 4; ++c) {
                            if (!(pw[child[c]] > 0.0)) continue;
                            const double d[3] = { cx[child[c]] - cx[parent], cy[child[c]] - cy[parent],
                                                  cz[child[c]] - cz[parent] };
                            r = std::max(r, std::sqrt(dot3(d, d)) + reach[child[c]]);
                        }
                        reach[parent] = r;
                    }
                }
            }
            float* tree = &sheetData[texelFloats];
            tree[0] = static_cast<float>(levels);
            for (size_t c = 0; c < cells; ++c) {
                float* cell = tree + 1 + c * kSheetCellFloats;
                cell[0] = static_cast<float>(pw[c]);
                cell[1] = static_cast<float>(cx[c]);
                cell[2] = static_cast<float>(cy[c]);
                cell[3] = static_cast<float>(cz[c]);
                cell[4] = static_cast<float>(reach[c] * reach[c]);
            }

            Record rec{};
            rec.v[0]  = static_cast<float>(LightKind::Sheet);
            rec.v[3]  = place->origin[0]; rec.v[4] = place->origin[1]; rec.v[5] = place->origin[2];
            rec.v[6]  = place->axisU[0];  rec.v[7] = place->axisU[1];  rec.v[8] = place->axisU[2];
            rec.v[9]  = place->eye[0];    rec.v[10] = place->eye[1];   rec.v[11] = place->eye[2];
            rec.v[12] = static_cast<float>(area);
            rec.v[13] = static_cast<float>(w);
            rec.v[14] = static_cast<float>(h);
            rec.v[15] = 0.0f;   // the texels' offset, set once the records are counted
            rec.v[16] = place->axisV[0]; rec.v[17] = place->axisV[1]; rec.v[18] = place->axisV[2];
            rec.v[19] = static_cast<float>(texelFloats);   // the tree's, relative until then
            rec.weight = weight;
            records.push_back(rec);
        } else {
            sheetData.clear();
        }
    }

    for (const LocalLight& L : lights) {
        if (static_cast<int>(records.size()) >= kMaxLocalLights) break;

        const double k = std::isfinite(L.intensity) && L.intensity > 0.0f ? L.intensity : 0.0;
        double c[3];
        for (int i = 0; i < 3; ++i) {
            c[i] = std::isfinite(L.color[i]) && L.color[i] > 0.0f ? L.color[i] * k : 0.0;
        }
        // A BLACK LIGHT IS NO LIGHT: nothing to pick, nothing to trace.
        if (!(luminance(c[0], c[1], c[2]) > 0.0)) continue;

        Record rec{};
        rec.v[0] = static_cast<float>(L.kind);

        if (L.kind == LightKind::Parallel) {
            double d[3] = { L.direction[0], L.direction[1], L.direction[2] };
            const double len = std::sqrt(dot3(d, d));
            if (!(len > 0.0)) continue;
            // TOWARDS THE LIGHT, which is how sunDir points.
            rec.v[6] = static_cast<float>(-d[0] / len);
            rec.v[7] = static_cast<float>(-d[1] / len);
            rec.v[8] = static_cast<float>(-d[2] / len);
            for (int i = 0; i < 3; ++i)
                rec.v[9 + i] = static_cast<float>(c[i] * kLightSunIrradiance);
            rec.weight = luminance(c[0], c[1], c[2]) * kLightSunIrradiance;
        } else {
            const double radius = std::isfinite(L.radius) && L.radius > 0.01f ? L.radius : 0.01;
            const double r2 = radius * radius;
            for (int i = 0; i < 3; ++i) rec.v[3 + i] = L.position[i];
            for (int i = 0; i < 3; ++i)
                rec.v[9 + i] = static_cast<float>(c[i] * kLightSunIrradiance * r2);
            rec.v[12] = static_cast<float>(r2);

            if (L.kind == LightKind::Spot) {
                double d[3] = { L.direction[0], L.direction[1], L.direction[2] };
                const double len = std::sqrt(dot3(d, d));
                if (!(len > 0.0)) continue;
                for (int i = 0; i < 3; ++i) rec.v[6 + i] = static_cast<float>(d[i] / len);
                float co = 0.0f, ci = 0.0f;
                spotCosines(L.coneAngleDeg, L.coneFeather, co, ci);
                rec.v[13] = co;
                rec.v[14] = ci;
            }
            if (std::isfinite(L.smoothFalloff) && L.smoothFalloff > 0.0f) {
                rec.v[15] = static_cast<float>(radius);
                rec.v[16] = static_cast<float>(radius + L.smoothFalloff);
            }

            double d2 = 0.0;
            for (int i = 0; i < 3; ++i) {
                const double e = static_cast<double>(L.position[i]) - at[i];
                d2 += e * e;
            }
            rec.weight = luminance(c[0], c[1], c[2]) * kLightSunIrradiance * r2 / std::max(d2, r2);
        }
        records.push_back(rec);
    }

    out.count = static_cast<int>(records.size());

    // THE PICK PROBABILITIES: each weight, floored at a tenth of the largest, normalised.
    // All zero is equal shares -- every light dark at the anchor still lights something.
    double maxW = 0.0;
    for (const Record& r : records) maxW = std::max(maxW, std::isfinite(r.weight) ? r.weight : 0.0);
    double sumW = 0.0;
    for (Record& r : records) {
        double w = std::isfinite(r.weight) ? r.weight : 0.0;
        w = maxW > 0.0 ? std::max(w, 0.1 * maxW) : 1.0;
        r.weight = w;
        sumW += w;
    }
    double cdf = 0.0;
    for (size_t i = 0; i < records.size(); ++i) {
        const double p = records[i].weight / sumW;
        cdf += p;
        records[i].v[1] = i + 1 == records.size() ? 1.0f : static_cast<float>(cdf);
        records[i].v[2] = static_cast<float>(p);
    }

    // THE BUFFER: header, records, then the sheet's table.
    const size_t sheetOffset = kLightHeaderFloats + records.size() * kLightRecordFloats;
    out.packed.assign(sheetOffset + sheetData.size(), 0.0f);
    out.packed[0] = static_cast<float>(out.count);
    out.packed[1] = out.ambient[0];
    out.packed[2] = out.ambient[1];
    out.packed[3] = out.ambient[2];
    for (size_t i = 0; i < records.size(); ++i) {
        if (records[i].v[0] == static_cast<float>(LightKind::Sheet)) {
            records[i].v[15] = static_cast<float>(sheetOffset);
            records[i].v[19] = static_cast<float>(sheetOffset) + records[i].v[19];
        }
        std::memcpy(&out.packed[kLightHeaderFloats + i * kLightRecordFloats], records[i].v,
                    sizeof(records[i].v));
    }
    if (!sheetData.empty())
        std::memcpy(&out.packed[sheetOffset], sheetData.data(), sheetData.size() * sizeof(float));

    uint64_t h = 14695981039346656037ull;
    fnv(h, out.packed.data(), out.packed.size() * sizeof(float));
    out.hash = h;
}

} // namespace plugin::cloud
