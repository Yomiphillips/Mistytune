// The C++ arm of the production render.
//
// IDENTICAL TO Render.slang BUT FOR THE ENTRY POINT NAME, and the duplication is
// forced rather than chosen -- see that file's header on `extern "C"` and why a
// namespace does not rescue it.
//
// WHAT IS NOT DUPLICATED IS THE RENDERER. Both files include RenderLib.slang, which
// includes BounceLib, TransportLib, GeneratorLib, PhaseLib and SkyLib. Every line of
// transport, every generator and the whole atmosphere is the same source text on
// both sides; what differs is forty lines of marshalling in two entry points that
// the production path does not even call.
//
// THAT IS THE PROPERTY PLAN.md CALLS "ONE KERNEL SOURCE", and slang.cpuParity is
// what keeps it honest: the same library through both targets, over the same inputs,
// compared.

#include "RenderLib.slang"

[shader("compute")]
[numthreads(64, 1, 1)]
void cpuRenderRays(uint3 tid : SV_DispatchThreadID,
                   uniform Scene scene,
                   uniform PhaseInput phase,
                   uniform StructuredBuffer<float> bounds,
                   uniform StructuredBuffer<float2> drift,
                   uniform StructuredBuffer<float3> origins,
                   uniform StructuredBuffer<float3> directions,
                   uniform RWStructuredBuffer<float3> outRadiance,
                   uniform uint seed,
                   uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    outRadiance[i] = renderSample(scene, phase, bounds, drift,
                                  origins[i], directions[i], seed + uint(i));
}

// The twin of Render.slang's buildAirMap, named apart for the same `extern "C"` reason.
[shader("compute")]
[numthreads(64, 1, 1)]
void cpuBuildAirMap(uint3 tid : SV_DispatchThreadID,
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
