// The Phase 1 sky: the test harness over SkyLib.slang.
//
// THE MATHS MOVED TO SkyLib.slang AND DID NOT CHANGE. This file is the entry point
// and nothing else, for the same reason Generator.slang, Phase.slang and
// Transport.slang are: the renderer includes the LIBRARY, and without the split it
// would inherit this kernel as well.
//
// slang.skyParity still compares the generated CUDA bitwise against Shading.h's
// hand-written skyRadiance, so the split is checked rather than assumed -- a
// permutation that changed a single expression would fail it.

#include "SkyLib.slang"

// The entry point exists so the maths above survives dead-stripping and so the
// parity test can reach it. The production kernel keeps its own launch shim -- see
// Mistytune.cu, which owns the grid, the bands, the abort and the accumulator.
//
// PASSES includeSunDisc = true, because the hand-written skyRadiance it is compared
// against has no such parameter and always draws the disc. The renderer passes false
// at every bounce after the first; see SkyLib.slang on why that is not optional.
[shader("compute")]
[numthreads(64, 1, 1)]
void skyMain(uint3 tid : SV_DispatchThreadID,
             uniform SkyInput params,
             uniform StructuredBuffer<float3> directions,
             uniform RWStructuredBuffer<float3> output,
             uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    output[i] = skyRadiance(params, directions[i], true);
}
