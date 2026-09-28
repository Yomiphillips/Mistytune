// Test entry points for the null-collision transport.
//
// THE TRANSPORT ITSELF IS IN TransportLib.slang, and that split is not organisational
// tidiness -- see the note in that file. An #include drags in the including file's
// entry points too, so a kernel that wants the transport must be able to take the
// functions WITHOUT taking `transmittanceTrial` and `rngTrial` along with them.
//
// This file is therefore the harness, and the generated Transport.cu it produces is
// what slang.transport compiles. Nothing in the shipping renderer should ever include
// it.

#include "TransportLib.slang"

// ---------------------------------------------------------------------------
// Entry points for the tests
// ---------------------------------------------------------------------------

[shader("compute")]
[numthreads(64, 1, 1)]
void transmittanceTrial(uint3 tid : SV_DispatchThreadID,
                        uniform Medium medium,
                        uniform MajorantGrid grid,
                        uniform StructuredBuffer<float> bounds,
                        uniform StructuredBuffer<float2> drift,
                        uniform float3 origin,
                        uniform float3 direction,
                        uniform RWStructuredBuffer<float> output,
                        uniform RWStructuredBuffer<int> outSteps,
                        uniform uint seed,
                        uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    // HASHED, NOT AN ARITHMETIC PROGRESSION. Seeding a PCG state with seed + i*k and
    // drawing immediately leaves the first draw correlated across threads, which
    // biases anything that branches on it.
    uint s = uint(i) * 747796405u + 2891336453u;
    s = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    Rng rng = makeRng((s >> 22u) ^ s ^ seed);

    // THE STEP COUNT IS REPORTED BECAUSE IT IS THE WHOLE CASE FOR THE GRID. The answer
    // is supposed to be identical with and without it; the cost is the only thing that
    // may differ, so a test that did not measure cost could not tell the grid was doing
    // anything at all.
    int steps = 0;
    output[i]   = transmittance(medium, grid, bounds, drift, rng, origin, direction, steps);
    outSteps[i] = steps;
}

[shader("compute")]
[numthreads(64, 1, 1)]
void freeFlightTrial(uint3 tid : SV_DispatchThreadID,
                     uniform Medium medium,
                     uniform MajorantGrid grid,
                     uniform StructuredBuffer<float> bounds,
                     uniform StructuredBuffer<float2> drift,
                     uniform float3 origin,
                     uniform float3 direction,
                     uniform RWStructuredBuffer<float> outDistance,
                     uniform RWStructuredBuffer<int> outSteps,
                     uniform uint seed,
                     uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    uint s = uint(i) * 747796405u + 2891336453u;
    s = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    Rng rng = makeRng((s >> 22u) ^ s ^ seed);

    float3 hit;
    float  dist;
    int    steps = 0;
    // A NEGATIVE DISTANCE MEANS "ESCAPED", which the histogram treats as a sample in
    // the tail rather than discarding -- throwing escapes away would renormalise the
    // distribution and hide a rate that is wrong in exactly one direction.
    outDistance[i] = sampleFreeFlight(medium, grid, bounds, drift, rng, origin, direction,
                                      hit, dist, steps) ? dist : -1.0f;
    outSteps[i]    = steps;
}

// The RNG, exposed so slang.transport can pin it against Phase.slang's.
//
// BOTH FILES NOW GET IT FROM Rng.slang, so this no longer compares two hand-kept
// copies. It compares two GENERATED ARTIFACTS, which is a weaker claim about the
// source and the same claim about what ships: if one .cu was regenerated and the
// other was not, or one kept a stale local definition, these disagree.
[shader("compute")]
[numthreads(64, 1, 1)]
void rngTrial(uint3 tid : SV_DispatchThreadID,
              uniform RWStructuredBuffer<float> output,
              uniform uint seed,
              uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    Rng rng = makeRng(seed + uint(i));
    output[i] = randFloat(rng);
}

// Fills a majorant grid from the ice generator's structural bound.
//
// NOT TEST SCAFFOLDING, though a test is its first caller. A renderer using a majorant
// grid has to build it from somewhere, and for a procedural field that means a kernel
// like this one running whenever the generator parameters change -- which is exactly
// what the field cache in src/engine/ exists to decide. It lives here for now and moves
// to the production kernel with the rest of the transport.
//
// THE BOUND IS STRUCTURAL, NOT SAMPLED, and slang.generator measures why: sampling this
// field misses whole cells at every resolution tried, and a majorant of zero does not
// thin a cell, it deletes it.
[shader("compute")]
[numthreads(64, 1, 1)]
void buildIceGrid(uint3 tid : SV_DispatchThreadID,
                  uniform Medium medium,
                  uniform StructuredBuffer<float2> drift,
                  uniform MajorantGrid grid,
                  uniform RWStructuredBuffer<float> outBounds,
                  uniform int cellCount)
{
    int i = int(tid.x);
    if (i >= cellCount) return;

    int cx = i % grid.dims.x;
    int cy = (i / grid.dims.x) % grid.dims.y;
    int cz = i / (grid.dims.x * grid.dims.y);

    float3 lo = grid.origin + float3(float(cx), float(cy), float(cz)) * grid.cellExtent;
    outBounds[i] = iceDensityBound(medium.gen, drift, lo, lo + grid.cellExtent);
}
