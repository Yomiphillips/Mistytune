// The clouds' shadow maps: the TEST entry points. See AirMapLib.slang for what is tested.
//
// THREE KERNELS AND ONE INDEPENDENT REFERENCE:
//
//   airMapBuild      the production column, one texel per thread
//   airMapLookup     the production lookup at arbitrary points
//   airMapLoss       the production airShadowLoss, one jitter per thread
//   airMapLossRef    the same integral by a DIFFERENT method: tens of thousands of fixed
//                    midpoints, uniform in distance, with the optical depth carried by
//                    the midpoint rule. It shares the map lookup and the sky's
//                    coefficients and nothing else, so a wrong step, a wrong weight or a
//                    wrong colour in airShadowLoss cannot also be in it. With
//                    `everywhere` it ignores the maps and returns the ray's whole airlight,
//                    which is the scale a loss's error is judged against.

#include "AirMapLib.slang"

[shader("compute")]
[numthreads(64, 1, 1)]
void airMapBuild(uint3 tid : SV_DispatchThreadID,
                 uniform Medium medium,
                 uniform StructuredBuffer<float2> drift,
                 uniform LayerShadowMap map,
                 uniform RWStructuredBuffer<float> outTexels,
                 uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    layerMapColumn(medium, drift, map, i, outTexels);
}

[shader("compute")]
[numthreads(64, 1, 1)]
void airMapLookup(uint3 tid : SV_DispatchThreadID,
                  uniform LayerShadowMap map,
                  uniform StructuredBuffer<float3> points,
                  uniform RWStructuredBuffer<float> outT,
                  uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    outT[i] = layerMapTransmittance(map, points[i]);
}

[shader("compute")]
[numthreads(64, 1, 1)]
void airMapLoss(uint3 tid : SV_DispatchThreadID,
                uniform SkyInput sky,
                uniform LayerShadowMap mapA,
                uniform LayerShadowMap mapB,
                uniform float3 origin,
                uniform float3 direction,
                uniform float dist,
                uniform RWStructuredBuffer<float3> outLoss,
                uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    float jitter = (float(i) + 0.5f) / float(count);
    outLoss[i] = airShadowLoss(sky, mapA, mapB, origin, direction, dist, jitter);
}

[shader("compute")]
[numthreads(1, 1, 1)]
void airMapLossRef(uniform SkyInput p,
                   uniform LayerShadowMap mapA,
                   uniform LayerShadowMap mapB,
                   uniform float3 ro,
                   uniform float3 rd,
                   uniform float dist,
                   uniform int steps,
                   uniform int everywhere,
                   uniform RWStructuredBuffer<float3> outLoss)
{
    float3 sun = sunDirection(p);

    float planetRadius = p.planetRadius > 1000.0f ? p.planetRadius : 1000.0f;
    float scaleHeight  = p.scaleHeight > 1.0f ? p.scaleHeight : 1.0f;
    float atmosphereHeight = scaleHeight * kAtmosphereEFoldings;
    float observerAltitude = ro.y > 0.0f ? ro.y : 0.0f;

    float b       = (planetRadius + observerAltitude) * rd.y;
    float cGround = shellC(observerAltitude, planetRadius, 0.0f);
    float cTop    = shellC(observerAltitude, planetRadius, atmosphereHeight);
    float tTop    = shellExit(b, cTop);
    float tGround = shellEnter(b, cGround);
    float tMax    = tGround > 0.0f ? tGround : tTop;
    if (dist < tMax) tMax = dist;

    float3 betaR    = rayleighCoefficients();
    float  betaM    = mieCoefficient(p.turbidity);
    float  betaMExt = betaM * 1.11f;
    float  cosTheta = clampf(dot(rd, sun), -1.0f, 1.0f);
    float  phaseR   = 0.0596831f * (1.0f + cosTheta * cosTheta);
    float  g        = clampf(p.mieAnisotropy, -0.95f, 0.95f);
    float  hgDenom  = 1.0f + g * g - 2.0f * g * cosTheta;
    float  phaseM   = (1.0f - g * g) /
                      (12.566370614f * hgDenom * sqrt(hgDenom > 1e-6f ? hgDenom : 1e-6f));

    float  h0 = tMax / float(steps);
    float  depthR = 0.0f, depthM = 0.0f;
    float3 accR = float3(0.0f, 0.0f, 0.0f);
    float3 accM = float3(0.0f, 0.0f, 0.0f);

    for (int i = 0; i < steps; ++i)
    {
        float tm = (float(i) + 0.5f) * h0;
        float q  = cGround + 2.0f * tm * b + tm * tm;
        float h  = altitudeFromQ(q, planetRadius);
        float hc = h < 0.0f ? 0.0f : h;
        float rR = exp(-hc / scaleHeight);
        float rM = exp(-hc / kMieScaleHeight);

        float atR = depthR + 0.5f * rR * h0;
        float atM = depthM + 0.5f * rM * h0;
        depthR += rR * h0;
        depthM += rM * h0;

        float3 pw = ro + rd * tm;
        float  v  = layerMapTransmittance(mapA, pw) * layerMapTransmittance(mapB, pw);
        if (everywhere != 0) v = 0.0f;   // the whole airlight: the scale a loss is judged on
        if (v >= 1.0f) continue;

        float3 pt   = float3(rd.x * tm, planetRadius + observerAltitude + rd.y * tm, rd.z * tm);
        float3 sunT = sampleTransmittanceLut(p, hc, lutMuFor(pt, sun));
        float3 viewT = float3(exp(-(betaR.x * atR + betaMExt * atM)),
                              exp(-(betaR.y * atR + betaMExt * atM)),
                              exp(-(betaR.z * atR + betaMExt * atM)));
        float3 w = viewT * sunT * ((1.0f - v) * h0);
        accR = accR + w * rR;
        accM = accM + w * rM;
    }

    outLoss[0] = (accR * betaR * phaseR + accM * (betaM * phaseM)) * sunIrradianceTop(p);
}

[shader("compute")]
[numthreads(64, 1, 1)]
void airMapGround(uint3 tid : SV_DispatchThreadID,
                  uniform LayerShadowMap mapA,
                  uniform LayerShadowMap mapB,
                  uniform float3 origin,
                  uniform StructuredBuffer<float3> directions,
                  uniform RWStructuredBuffer<float> outLit,
                  uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    outLit[i] = groundShadow(mapA, mapB, origin, directions[i]);
}
