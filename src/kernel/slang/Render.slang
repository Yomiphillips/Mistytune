// The CUDA arm of the production render.
//
// ===========================================================================
// WHY THIS FILE HOLDS AN ENTRY POINT AT ALL, given that Mistytune.cu calls
// `renderSample` directly out of the generated source.
//
// TWO REASONS, AND THE FIRST ONE IS LOAD-BEARING.
//
// 1. DEAD-CODE ELIMINATION. slangc emits only what is reachable from an entry point.
//    A .slang file with no `[shader]` in it generates an empty translation unit, and
//    the failure is not a link error -- it is a generated file that compiles
//    perfectly and contains none of the renderer.
//
// 2. It is the shape the golden suite will want when it compares this backend
//    against the C++ one ray for ray, the way slang.cpuParity already does for
//    transmittance. `RenderCpu.slang` is its twin, and the two entry points differ
//    only in their names.
//
// WHY THE TWIN NEEDS A DIFFERENT NAME. slangc marks entry points
// SLANG_PRELUDE_EXPORT, which expands through `extern "C"`. Both generated files are
// linked into plugin_kernel -- the CUDA one through Mistytune.cu, the C++ one
// through CpuRender.cpp -- so identical entry-point names are one symbol and the
// binary will not link. Wrapping one in a namespace does not help; `extern "C"`
// ignores namespaces, which is the point of it. CpuParity.slang hit this first and
// its header records the whole argument.
// ===========================================================================

#include "RenderLib.slang"

[shader("compute")]
[numthreads(64, 1, 1)]
void renderRays(uint3 tid : SV_DispatchThreadID,
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

// THE CLOUDS' SHADOW MAP, one texel's column per thread. Mistytune.cu calls
// layerMapColumn from a kernel of its own, as it calls renderSample; this entry point is
// what makes slangc emit it. See AirMapLib.slang.
[shader("compute")]
[numthreads(64, 1, 1)]
void buildAirMap(uint3 tid : SV_DispatchThreadID,
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
