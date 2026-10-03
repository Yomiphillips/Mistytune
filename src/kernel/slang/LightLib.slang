// Local lights (build 29): one light drawn per scattering event, and the irradiance it
// sends to a point before any cloud is in the way.
//
// ===========================================================================
// THE GEOMETRY ONLY. The shadow ray and the phase function are BounceLib's, beside the
// sun's, so a light and the sun go through one next-event estimator and differ only in
// where the light comes from. This file knows nothing of the scene or the medium, which
// is what lets slang.bounce hold it against a quadrature of the same integral.
//
// THE BUFFER IS src/engine/LocalLights.h's, AND EVERY OFFSET BELOW IS ONE OF ITS NUMBERS.
// The two change together or the kernel reads one light's colour as another's position.
//
// WHAT EACH KIND SENDS, as irradiance on a surface facing it, before the cloud:
//
//   point     I / max(d^2, R^2): AE's Inverse Square Clamped, full strength inside R
//   spot      the same, times the cone: 1 inside the inner angle, 0 outside the outer,
//             a smoothstep between -- AE's Cone Feather
//   parallel  E, from one direction, from infinitely far: a second sun
//   sheet     one texel drawn down the sheet's tree, a point drawn inside it, and that
//             texel as a small glowing patch that shines every way: L A / max(d^2, A). A
//             bolt is a line of light, not a lamp shade, so it lights its back as its front.
//             The texel stands off the sheet's plane by its depth scale s -- laid on the
//             cloud the camera sees -- so its point and its area A s^2 are where it stands.
//
// AE's Smooth falloff multiplies a point or a spot by a smoothstep from 1 at R to 0 at
// R + its Falloff Distance.
//
// DIVIDED BY THE PROBABILITY OF THE DRAW -- the light's pick, and for the sheet the
// texel's -- so the sum over draws is the sum over lights. That is the whole of what
// makes picking one light per event unbiased, and slang.bounce checks it.
// ===========================================================================

#ifndef MISTYTUNE_LIGHT_LIB_SLANG
#define MISTYTUNE_LIGHT_LIB_SLANG

#include "Rng.slang"

public static const int kLightHeaderFloats = 8;
public static const int kLightRecordFloats = 20;
public static const int kMaxLocalLights    = 16;

public static const int kLightPoint    = 0;
public static const int kLightSpot     = 1;
public static const int kLightParallel = 2;
public static const int kLightSheet    = 3;

// ===========================================================================
// THE SHEET'S TEXEL IS DRAWN DOWN A QUADTREE, BY HOW BRIGHTLY EACH CELL LIGHTS THE POINT.
//
// MEASURED, AND WHY. Drawn by luminance alone, a bolt rendered as a field of fireflies even
// at 512 spp (build/tmp/b29/r1/m2.png). A bolt is hundreds of lit texels, and a point in
// the cloud near the channel is lit almost entirely by the few beside it -- which a draw by
// luminance picks one time in a hundred, at a hundred times the mean. A window of texels
// round the point's projection (r2/m3.png) helped only within a few texels of the sheet's
// plane, and the cloud is hundreds of metres deep either side of it.
//
// SO EACH LEVEL OF THE TREE PICKS ONE OF FOUR CHILDREN in proportion to its light over its
// squared distance from the point -- the light it would send there, before the cloud. A
// point beside the bolt walks down to the texels beside it; a point far off sees the cells
// as near enough equally distant and picks by light. The texel's probability is the product
// of the choices on its way down, exact, so the estimate is unbiased whatever the
// importance says; the importance is only the noise. This is the light tree that renderers
// use for many lights, on a grid, where the tree is free.
//
// A CELL IS ITS POWER, ITS POWER'S CENTROID IN THE WORLD, AND A RADIUS THAT HOLDS IT. Since
// the sheet is laid on the cloud its texels are not on one plane and not one size, so a cell
// is what it is where its texels stand. Its distance is to the centroid, floored at that
// radius, so a cell the point is inside is not taken for an infinitely bright one.
// ===========================================================================
public static const int kSheetTreeMaxLevels = 12;   // 4096 texels a side: far past the sheet's
public static const int kSheetTexelFloats   = 4;    // radiance rgb, depth scale
public static const int kSheetCellFloats    = 5;    // power, centroid xyz, radius squared

// FIELD NAMES CARRY `ls`, unique across the kernel, for the reason Environment.envMode gives.
public struct LightSample
{
    float3 lsDir;         // unit, from the point towards the light
    float  lsDist;        // to the light, metres; 1e30 for a parallel light
    float3 lsIrradiance;  // at the point, before the cloud, over the draw's probability
};

float3 lightTriple(StructuredBuffer<float> b, int i)
{
    return float3(b[i], b[i + 1], b[i + 2]);
}

// A smoothstep that takes equal edges as a hard step -- a spot with no feather. Written
// out rather than the intrinsic, so both backends run the same arithmetic.
float lightEdge(float lo, float hi, float x)
{
    if (!(hi > lo)) return x >= lo ? 1.0f : 0.0f;
    float t = clamp((x - lo) / (hi - lo), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

// Where level k's cells start in the tree, in cells: (4^k - 1) / 3.
int sheetLevelStart(int k)
{
    return ((1 << (2 * k)) - 1) / 3;
}

// One light for the point p. The first draw picks the light; a sheet then draws one number
// per level of its tree and two for the point inside the texel. Irradiance zero is a light
// that sends nothing here: outside a spot's cone, past a Smooth falloff, or a pick of
// probability zero.
public LightSample sampleLocalLight(StructuredBuffer<float> b, int count, float3 p,
                                    inout Rng rng)
{
    LightSample ls;
    ls.lsDir        = float3(0.0f, 1.0f, 0.0f);
    ls.lsDist       = 0.0f;
    ls.lsIrradiance = float3(0.0f, 0.0f, 0.0f);

    int n = min(count, kMaxLocalLights);
    if (n <= 0) return ls;

    // THE PICK: the first light whose CDF passes the draw. The last one's is exactly 1.
    float uPick = randFloat(rng);
    int   k = n - 1;
    for (int i = 0; i < kMaxLocalLights; ++i)
    {
        if (i >= n) break;
        if (uPick < b[kLightHeaderFloats + i * kLightRecordFloats + 1])
        {
            k = i;
            break;
        }
    }

    int   r    = kLightHeaderFloats + k * kLightRecordFloats;
    int   kind = int(b[r]);
    float pick = b[r + 2];
    if (!(pick > 0.0f)) return ls;

    float3 rgb = lightTriple(b, r + 9);

    if (kind == kLightParallel)
    {
        ls.lsDir        = lightTriple(b, r + 6);
        ls.lsDist       = 1e30f;
        ls.lsIrradiance = rgb / pick;
        return ls;
    }

    float  floorSq = b[r + 12];
    float3 q;
    if (kind == kLightSheet)
    {
        int    w      = int(b[r + 13]);
        int    h      = int(b[r + 14]);
        int    texels = int(b[r + 15]);
        int    tree   = int(b[r + 19]);
        int    levels = int(b[tree]);
        float3 origin = lightTriple(b, r + 3);
        float3 axisU  = lightTriple(b, r + 6);
        float3 eye    = lightTriple(b, r + 9);
        float3 axisV  = lightTriple(b, r + 16);
        if (w <= 0 || h <= 0 || levels < 0 || levels > kSheetTreeMaxLevels) return ls;

        int   cx  = 0;
        int   cy  = 0;
        float pdf = 1.0f;
        for (int lv = 0; lv < kSheetTreeMaxLevels; ++lv)
        {
            if (lv >= levels) break;
            int   child = lv + 1;
            int   across = 1 << child;
            int   start  = tree + 1 + kSheetCellFloats * sheetLevelStart(child);

            float imp0 = 0.0f, imp1 = 0.0f, imp2 = 0.0f, imp3 = 0.0f;
            for (int c = 0; c < 4; ++c)
            {
                int   x     = 2 * cx + (c & 1);
                int   y     = 2 * cy + (c >> 1);
                int   at    = start + kSheetCellFloats * (y * across + x);
                float power = b[at];
                float imp   = 0.0f;
                if (power > 0.0f)
                {
                    float3 d = lightTriple(b, at + 1) - p;
                    imp = power / max(dot(d, d), b[at + 4]);
                }
                if (c == 0) imp0 = imp;
                else if (c == 1) imp1 = imp;
                else if (c == 2) imp2 = imp;
                else imp3 = imp;
            }
            float total = imp0 + imp1 + imp2 + imp3;
            if (!(total > 0.0f)) return ls;

            // THE CHILD, by its share of the importance -- and a share of zero can never be
            // drawn, so a dark cell is never entered.
            float u = randFloat(rng) * total;
            int   pickC = 3;
            float pickImp = imp3;
            if (u < imp0)                      { pickC = 0; pickImp = imp0; }
            else if (u < imp0 + imp1)          { pickC = 1; pickImp = imp1; }
            else if (u < imp0 + imp1 + imp2)   { pickC = 2; pickImp = imp2; }
            if (!(pickImp > 0.0f))
            {
                // Rounding at the top of the range: the last child with any importance.
                if (imp3 > 0.0f)      { pickC = 3; pickImp = imp3; }
                else if (imp2 > 0.0f) { pickC = 2; pickImp = imp2; }
                else if (imp1 > 0.0f) { pickC = 1; pickImp = imp1; }
                else                  { pickC = 0; pickImp = imp0; }
            }
            pdf *= pickImp / total;
            cx = 2 * cx + (pickC & 1);
            cy = 2 * cy + (pickC >> 1);
        }
        if (cx >= w || cy >= h || !(pdf > 0.0f)) return ls;

        // THE POINT ON THE PLANE, then out along the eye's ray to where the texel stands. A
        // uniform point of the plane's patch is a uniform point of the pushed one, which is
        // the same patch s times the size.
        int   tx = texels + kSheetTexelFloats * (cy * w + cx);
        float s  = b[tx + 3];
        float u2 = randFloat(rng);
        float u3 = randFloat(rng);
        float3 onPlane = origin + axisU * (float(cx) + u2) + axisV * (float(cy) + u3);
        q = eye + (onPlane - eye) * s;

        // RADIANCE TIMES THE TEXEL'S AREA WHERE IT STANDS, over the texel's probability: its
        // intensity. And that area is the inverse square's floor below.
        floorSq *= s * s;
        rgb = lightTriple(b, tx) * (floorSq / pdf);
    }
    else
    {
        q = lightTriple(b, r + 3);
    }

    float3 d     = q - p;
    float  dSq   = dot(d, d);
    float  dist  = sqrt(dSq);
    ls.lsDir     = dist > 0.0f ? d / dist : float3(0.0f, 1.0f, 0.0f);
    ls.lsDist    = dist;

    float3 e = rgb / max(dSq, floorSq);

    if (kind == kLightSpot)
    {
        // THE ANGLE OFF THE AXIS, seen from the light: -lsDir is the way its light leaves.
        e *= lightEdge(b[r + 13], b[r + 14], dot(-ls.lsDir, lightTriple(b, r + 6)));
    }
    if (kind != kLightSheet && b[r + 16] > 0.0f)
    {
        e *= 1.0f - lightEdge(b[r + 15], b[r + 16], dist);
    }

    ls.lsIrradiance = e / pick;
    return ls;
}

#endif // MISTYTUNE_LIGHT_LIB_SLANG
