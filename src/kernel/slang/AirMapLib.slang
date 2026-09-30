// The clouds' shadows in the air, from a map -- the LIBRARY half.
//
// ===========================================================================
// WHY A MAP. Build 17 put the clouds' shadows into the airlight with ONE shadow ray per
// camera ray, cast from one point of the segment drawn in proportion to its airlight.
// Unbiased in luminance, and measured: +29% on the default frame, and at 1 spp denoised
// the sky's RMSE went from 3.43 to 8.56. Under a cumulus field that one ray is either lit
// or shadowed, and OIDN cannot average a coin toss it sees once.
//
// THE SHADOWS DO NOT DEPEND ON THE CAMERA RAY. They depend on the cloud and the sun, and
// every camera ray of the frame asks the same question of the same clouds. So the
// question is answered once per frame, into a table, and every step of every camera
// ray's air reads it. That is noise-free, and a table read is far cheaper than a walk
// through a cumulus.
// ===========================================================================
//
// THE TABLE IS A DEEP SHADOW MAP, ONE PER LAYER.
//
// Texels lie on the layer's BOTTOM plane, on a grid laid out along the sun's azimuth.
// Each texel is a column: the sun ray that crosses the plane there, climbing through the
// slab. Its slices are equal steps of altitude from the bottom to the top of the slab,
// and slice k holds the transmittance to the sun from where that ray is at slice k's
// altitude, through this layer alone.
//
// A POINT ANYWHERE IS ANSWERED BY ITS OWN SUN RAY. Slide the point along the sun
// direction to the bottom plane: that is its column. Its altitude picks the slice.
//
//   below the slab   the whole column, slice 0: the clear air between adds nothing,
//                    so this is exact up to the table's resolution
//   in the slab      between two slices, interpolated
//   above it         1: a ray climbing towards the sun never enters the slab again
//
// ONE MAP PER LAYER, NOT ONE FOR THE SCENE. Transmittance through two media is the
// product of their transmittances, so two maps multiply exactly. Kept apart, each gets
// a box that fits it: a lone hero's map is a few kilometres across and fine, while the
// cirrus's covers the whole Render Distance, where soft shadows can afford coarse texels.
//
// A MAP WITH AN EMPTY BUFFER ANSWERS 1, and that is what an absent layer is.
//
// FIELD NAMES CARRY `sm`, unique across the kernel, for the reason Environment.envMode
// gives in BounceLib.slang.

#ifndef MISTYTUNE_AIRMAP_LIB_SLANG
#define MISTYTUNE_AIRMAP_LIB_SLANG

#include "TransportLib.slang"
#include "SkyLib.slang"

public struct LayerShadowMap
{
    // smDimU x smDimV x smSlices, slice-major: [(k * smDimV + iv) * smDimU + iu].
    // EMPTY IS NO MAP. The build writes it through a RWStructuredBuffer of its own.
    StructuredBuffer<float> smTexels;

    float3 smSun;       // towards the sun, normalised; .y > 0, or the host builds no map
    float2 smCentre;    // world xz of the grid's origin
    float2 smAxisU;     // unit, horizontal: the sun's azimuth. V is it turned 90 degrees
    float2 smLo;        // (u, v) of the grid's low corner, metres from smCentre
    float2 smTexel;     // one texel's size in u and in v, metres
    int    smDimU;      // at least 2 each, which the bilinear read relies on
    int    smDimV;
    int    smSlices;    // at least 2
    float  smBottom;    // the layer's slab, metres: the plane the texels lie on
    float  smTop;
    float  smStep;      // the build's step along the sun ray, metres
};

// Optical depth past which a column is simply black. exp(-12) is six millionths, and
// marching on through a tower to refine it would only cost time.
public static const float kAirMapOpaque = 12.0f;

// Steps per slice of one column, whatever smStep says. The host sizes smStep so the whole
// column stays near 1024 steps; this is the bound a GPU loop wants to see.
public static const int kAirMapSliceCap = 1024;

float2 airMapAxisV(LayerShadowMap m)
{
    return float2(-m.smAxisU.y, m.smAxisU.x);
}

float airMapTexel(LayerShadowMap m, int iu, int iv, int k)
{
    return m.smTexels[(k * m.smDimV + iv) * m.smDimU + iu];
}

// ---------------------------------------------------------------------------
// Reading it
// ---------------------------------------------------------------------------

// The transmittance to the sun through this layer, from world point p.
//
// TRILINEAR: bilinear across the plane, linear between slices. Eight reads.
//
// OUTSIDE THE GRID IS 1, EXACTLY. The host sizes the grid to cover every column that can
// meet this layer's medium, so a column off the grid is one that meets none.
public float layerMapTransmittance(LayerShadowMap m, float3 p)
{
    uint want = uint(m.smDimU * m.smDimV * m.smSlices);
    if (want == 0u || m.smTexels.getCount() < want) return 1.0f;
    if (p.y >= m.smTop) return 1.0f;

    float3 sun = m.smSun;
    float2 q   = p.xz + sun.xz * ((m.smBottom - p.y) / sun.y) - m.smCentre;

    float fu = (dot(q, m.smAxisU)     - m.smLo.x) / m.smTexel.x - 0.5f;
    float fv = (dot(q, airMapAxisV(m)) - m.smLo.y) / m.smTexel.y - 0.5f;

    // WRITTEN SO THAT A NaN FALLS OUT AS "OFF THE GRID", which answers 1.
    if (!(fu >= -0.5f && fv >= -0.5f &&
          fu <= float(m.smDimU) - 0.5f && fv <= float(m.smDimV) - 0.5f)) return 1.0f;

    fu = clampf(fu, 0.0f, float(m.smDimU - 1));
    fv = clampf(fv, 0.0f, float(m.smDimV - 1));
    int u0 = int(fu);
    int v0 = int(fv);
    int u1 = min(u0 + 1, m.smDimU - 1);
    int v1 = min(v0 + 1, m.smDimV - 1);
    float tu = fu - float(u0);
    float tv = fv - float(v0);

    float fk = clampf((p.y - m.smBottom) / max(m.smTop - m.smBottom, 1.0f), 0.0f, 1.0f)
             * float(m.smSlices - 1);
    int   k0 = min(int(fk), m.smSlices - 1);
    int   k1 = min(k0 + 1, m.smSlices - 1);
    float tk = fk - float(k0);

    float a0 = airMapTexel(m, u0, v0, k0) * (1.0f - tu) + airMapTexel(m, u1, v0, k0) * tu;
    float b0 = airMapTexel(m, u0, v1, k0) * (1.0f - tu) + airMapTexel(m, u1, v1, k0) * tu;
    float a1 = airMapTexel(m, u0, v0, k1) * (1.0f - tu) + airMapTexel(m, u1, v0, k1) * tu;
    float b1 = airMapTexel(m, u0, v1, k1) * (1.0f - tu) + airMapTexel(m, u1, v1, k1) * tu;

    float lower = a0 * (1.0f - tv) + b0 * tv;
    float upper = a1 * (1.0f - tv) + b1 * tv;
    return lower * (1.0f - tk) + upper * tk;
}

// Where along a ray this map can shadow anything: below the slab's top, and over the
// grid. False when nowhere.
//
// THE RAY'S TRACK ACROSS THE GRID IS A STRAIGHT LINE, because sliding a point along the
// sun to the plane is affine in the point. So the grid is two slabs in t, clipped the way
// slabRange clips a box.
bool layerMapRange(LayerShadowMap m, float3 ro, float3 rd, out float t0, out float t1)
{
    t0 = 0.0f;
    t1 = 1e30f;

    uint want = uint(m.smDimU * m.smDimV * m.smSlices);
    if (want == 0u || m.smTexels.getCount() < want) return false;

    if (abs(rd.y) < 1e-9f)
    {
        if (ro.y >= m.smTop) return false;
    }
    else
    {
        float tt = (m.smTop - ro.y) / rd.y;
        if (rd.y > 0.0f) t1 = min(t1, tt);
        else             t0 = max(t0, tt);
    }

    float3 sun = m.smSun;
    float2 q0  = ro.xz + sun.xz * ((m.smBottom - ro.y) / sun.y) - m.smCentre;
    float2 dq  = rd.xz - sun.xz * (rd.y / sun.y);
    float2 av  = airMapAxisV(m);

    float uHi = m.smLo.x + float(m.smDimU) * m.smTexel.x;
    float vHi = m.smLo.y + float(m.smDimV) * m.smTexel.y;
    if (!clipAxis(dot(q0, m.smAxisU), dot(dq, m.smAxisU), m.smLo.x, uHi, t0, t1)) return false;
    if (!clipAxis(dot(q0, av),        dot(dq, av),        m.smLo.y, vHi, t0, t1)) return false;
    return t1 > t0;
}

// ---------------------------------------------------------------------------
// Building it
// ---------------------------------------------------------------------------

// One texel's column: every slice's transmittance, written to `outTexels`.
//
// A DETERMINISTIC MARCH, NOT RATIO TRACKING. A stochastic column would be a noise
// pattern frozen into the frame, and it would crawl as the cloud drifted. Midpoints at
// smStep integrate the optical depth; the map's own resolution is the coarser limit.
//
// FROM THE TOP DOWN, because slice k's answer is the optical depth from slice k UP, and
// walking down adds each slice's own stretch to the one above it. It also lets a column
// stop at the first tower it is buried in: everything below is black.
//
// ONLY WHERE THE MEDIUM CAN BE: the layer's own slabRange, which clips to its box and to
// the Render Distance fade. Outside that the density is zero by definition.
public void layerMapColumn(Medium med, StructuredBuffer<float2> drift, LayerShadowMap m,
                           int texel, RWStructuredBuffer<float> outTexels)
{
    int stride = m.smDimU * m.smDimV;
    if (texel < 0 || texel >= stride) return;

    int iu = texel % m.smDimU;
    int iv = texel / m.smDimU;

    float2 q = m.smCentre
             + m.smAxisU       * (m.smLo.x + (float(iu) + 0.5f) * m.smTexel.x)
             + airMapAxisV(m)  * (m.smLo.y + (float(iv) + 0.5f) * m.smTexel.y);
    float3 base = float3(q.x, m.smBottom, q.y);
    float3 sun  = m.smSun;

    // Slices are equal steps of altitude, so equal steps along the ray.
    float sliceRun = (m.smTop - m.smBottom) / (float(m.smSlices - 1) * sun.y);
    float step     = max(m.smStep, 1.0f);

    float t0, t1;
    bool  reach = slabRange(med, base, sun, t0, t1);

    float tau = 0.0f;
    outTexels[(m.smSlices - 1) * stride + texel] = 1.0f;

    for (int k = m.smSlices - 2; k >= 0; --k)
    {
        if (reach && tau < kAirMapOpaque)
        {
            float lo = max(float(k) * sliceRun, t0);
            float hi = min(float(k + 1) * sliceRun, t1);
            if (hi > lo)
            {
                int   n = clamp(int(ceil((hi - lo) / step)), 1, kAirMapSliceCap);
                float h = (hi - lo) / float(n);
                for (int j = 0; j < n; ++j)
                {
                    tau += densityAt(med, drift, base + sun * (lo + (float(j) + 0.5f) * h)) * h;
                }
            }
        }
        outTexels[k * stride + texel] = tau < kAirMapOpaque ? exp(-tau) : 0.0f;
    }
}

// ---------------------------------------------------------------------------
// The shadow on the ground
// ---------------------------------------------------------------------------

// The clouds' shadow where a ray from `origin` along `dir` lands on the ground: 1 for a
// ray that does not go down, or lands where no shadow falls.
//
// THE FLAT GROUND, y = 0, because the clouds are in the transport's flat world and so is
// their shadow. The sky finds its ground on the sphere, which lies further out along a
// low ray; that far out the grid has long ended and the answer is 1 either way.
public float groundShadow(LayerShadowMap mapA, LayerShadowMap mapB, float3 origin, float3 dir)
{
    if (!(dir.y < 0.0f) || !(origin.y > 0.0f)) return 1.0f;
    float3 ground = origin + dir * (origin.y / -dir.y);
    ground.y = 0.0f;
    return layerMapTransmittance(mapA, ground) * layerMapTransmittance(mapB, ground);
}

// ---------------------------------------------------------------------------
// The airlight the shadows take away
// ---------------------------------------------------------------------------

// Stratified steps along the shadowed stretch of a camera ray. Quadratic, like the sky's
// march, because the shafts nearest the eye are the biggest on screen.
public static const int kAirMapSteps = 48;

// ===========================================================================
// THE AIRLIGHT THAT FALLS IN THE CLOUDS' SHADOW, over [0, dist] of a camera ray.
// The caller takes it off airSegment's airIn, or off the sky for a ray that escapes.
//
// THE SAME INTEGRAND AS airSegment -- the air's own scattering, dimmed on the way to the
// eye and on the way from the sun -- times (1 - V), where V is the two maps' product.
// Where V is 1 everywhere this is exactly zero, so a ray no shadow crosses keeps the sky
// bit for bit.
//
// EXACT IN COLOUR, which build 17's estimator was not. That one gave a shadowed stretch
// the whole segment's average colour, because the exact form went negative in a channel
// whenever it drew a fully shadowed point. Here nothing is drawn: each step carries its
// own colour, and the only random number is the offset.
//
// ONLY OVER THE STRETCH WHERE A SHADOW CAN FALL: below the highest map's top and over its
// grid, which layerMapRange finds. The optical depth up to that stretch is marched
// separately when it does not start at the eye, which is the view from above the clouds.
//
// `jitter` PLACES EVERY STEP'S POINT WITHIN ITS STEP, one number for the whole ray.
// Each step is then an unbiased estimate of its own stretch, so their sum is unbiased
// for the integral, given the map. Fixed midpoints would draw the shafts as bands.
//
// ONE MAP READ PER STEP IS ENOUGH, AND THAT WAS MEASURED. Pinning the jitter at 0.5
// changed the 1 spp denoised RMSE of neither the sky nor the clouds (PROGRESS.md, build
// 18), so this estimator's own noise is below what the frame can show. Four reads per
// step with golden-ratio offsets were tried, cost up to 5%, and changed nothing either.
// What the frame still shows over "no air shadows" is delta tracking's escape-or-collide
// coin toss, against the contrast that shadowed air in front of a cloud really has.
//
// NOT CLAMPED HERE. The loss comes from a finer quadrature than the airIn it is taken
// from, so where a whole segment is in shadow the two can differ by a fraction of a
// percent either way. The caller clamps the difference at zero.
// ===========================================================================
public float3 airShadowLoss(SkyInput p, LayerShadowMap mapA, LayerShadowMap mapB,
                            float3 ro, float3 rd, float dist, float jitter)
{
    const float3 none = float3(0.0f, 0.0f, 0.0f);

    float tA = 1e30f;
    float tB = -1e30f;
    float r0, r1;
    if (layerMapRange(mapA, ro, rd, r0, r1)) { tA = min(tA, r0); tB = max(tB, r1); }
    if (layerMapRange(mapB, ro, rd, r0, r1)) { tA = min(tA, r0); tB = max(tB, r1); }
    if (!(tB > tA)) return none;

    float3 sun = sunDirection(p);

    float planetRadius = p.planetRadius > 1000.0f ? p.planetRadius : 1000.0f;
    float scaleHeight  = p.scaleHeight > 1.0f ? p.scaleHeight : 1.0f;
    float atmosphereHeight = scaleHeight * kAtmosphereEFoldings;

    float observerAltitude = ro.y > 0.0f ? ro.y : 0.0f;

    float b = (planetRadius + observerAltitude) * rd.y;

    float cGround = shellC(observerAltitude, planetRadius, 0.0f);
    float cTop    = shellC(observerAltitude, planetRadius, atmosphereHeight);

    float tTop = shellExit(b, cTop);
    if (tTop <= 0.0f || !(dist > 0.0f)) return none;

    float tGround = shellEnter(b, cGround);
    float tMax    = tGround > 0.0f ? tGround : tTop;
    if (dist < tMax) tMax = dist;

    tA = max(tA, 0.0f);
    tB = min(tB, tMax);
    if (!(tB > tA)) return none;

    float3 betaR    = rayleighCoefficients();
    float  betaM    = mieCoefficient(p.turbidity);
    float  betaMExt = betaM * 1.11f;

    float cosTheta = clampf(dot(rd, sun), -1.0f, 1.0f);
    float phaseR   = 0.0596831f * (1.0f + cosTheta * cosTheta);
    float g        = clampf(p.mieAnisotropy, -0.95f, 0.95f);
    float hgDenom  = 1.0f + g * g - 2.0f * g * cosTheta;
    float phaseM   = (1.0f - g * g) /
                     (12.566370614f * hgDenom * sqrt(hgDenom > 1e-6f ? hgDenom : 1e-6f));

    float depthR = 0.0f;
    float depthM = 0.0f;

    // THE AIR IN FRONT OF THE STRETCH, when the eye is not in it: eight midpoint steps.
    // Only the view from above the clouds gets here, and its optical depth varies slowly.
    if (tA > 0.0f)
    {
        const int front = 8;
        float h0 = tA / float(front);
        for (int i = 0; i < front; ++i)
        {
            float tm = (float(i) + 0.5f) * h0;
            float q  = cGround + 2.0f * tm * b + tm * tm;
            float h  = altitudeFromQ(q, planetRadius);
            float hc = h < 0.0f ? 0.0f : h;
            depthR += exp(-hc / scaleHeight) * h0;
            depthM += exp(-hc / kMieScaleHeight) * h0;
        }
    }

    float u    = clampf(jitter, 0.0f, 1.0f);
    float span = tB - tA;
    float invSteps2 = 1.0f / float(kAirMapSteps * kAirMapSteps);

    float3 lossR = float3(0.0f, 0.0f, 0.0f);
    float3 lossM = float3(0.0f, 0.0f, 0.0f);

    for (int i = 0; i < kAirMapSteps; ++i)
    {
        float s0 = tA + span * float(i * i) * invSteps2;
        float s1 = tA + span * float((i + 1) * (i + 1)) * invSteps2;
        float dt = s1 - s0;
        float ts = s0 + u * dt;

        float q  = cGround + 2.0f * ts * b + ts * ts;
        float h  = altitudeFromQ(q, planetRadius);
        float hc = h < 0.0f ? 0.0f : h;

        float rhoR = exp(-hc / scaleHeight);
        float rhoM = exp(-hc / kMieScaleHeight);

        // The optical depth AT the point, then over the whole step for the next one.
        float atR = depthR + rhoR * (ts - s0);
        float atM = depthM + rhoM * (ts - s0);
        depthR += rhoR * dt;
        depthM += rhoM * dt;

        // THE CLOUDS ARE IN THE FLAT WORLD the transport uses; the air is on the sphere.
        float3 pw = ro + rd * ts;
        float  v  = layerMapTransmittance(mapA, pw) * layerMapTransmittance(mapB, pw);
        if (v >= 1.0f) continue;

        float3 pt = float3(rd.x * ts, planetRadius + observerAltitude + rd.y * ts, rd.z * ts);
        float3 sunT = sampleTransmittanceLut(p, hc, lutMuFor(pt, sun));

        float3 viewT = float3(exp(-(betaR.x * atR + betaMExt * atM)),
                              exp(-(betaR.y * atR + betaMExt * atM)),
                              exp(-(betaR.z * atR + betaMExt * atM)));

        float3 w = viewT * sunT * ((1.0f - v) * dt);
        lossR = lossR + w * rhoR;
        lossM = lossM + w * rhoM;
    }

    return (lossR * betaR * phaseR + lossM * (betaM * phaseM)) * sunIrradianceTop(p);
}

#endif // MISTYTUNE_AIRMAP_LIB_SLANG
