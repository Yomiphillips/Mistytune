// Test entry points for the ice / fallstreak generator.
//
// THE GENERATOR ITSELF IS IN GeneratorLib.slang. The transport includes that to evaluate
// the field and to bound it, and must not inherit these kernels along with it -- see the
// note in that file.

#include "GeneratorLib.slang"

// ---------------------------------------------------------------------------
// Entry points for the tests
// ---------------------------------------------------------------------------

// Density along a vertical line, so a test can integrate it and check that the
// optical-depth parameter means what it claims.
[shader("compute")]
[numthreads(64, 1, 1)]
void densityColumn(uint3 tid : SV_DispatchThreadID,
                   uniform GeneratorInput g,
                   uniform StructuredBuffer<float2> disp,
                   uniform float2 columnXZ,
                   uniform RWStructuredBuffer<float> output,
                   uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    // Top to bottom of the streak, midpoints of a uniform partition.
    float depth = (float(i) + 0.5f) * (g.streakLength / float(count));
    float3 p = float3(columnXZ.x, g.cellAltitude - depth, columnXZ.y);

    output[i] = iceDensity(g, disp, p);
}

// Density over a horizontal plane, for the occupancy and majorant checks.
[shader("compute")]
[numthreads(8, 8, 1)]
void densityPlane(uint3 tid : SV_DispatchThreadID,
                  uniform GeneratorInput g,
                  uniform StructuredBuffer<float2> disp,
                  uniform float depth,
                  uniform float extent,
                  uniform RWStructuredBuffer<float> output,
                  uniform int side)
{
    int x = int(tid.x), y = int(tid.y);
    if (x >= side || y >= side) return;

    float u = (float(x) + 0.5f) / float(side) * extent - extent * 0.5f;
    float v = (float(y) + 0.5f) / float(side) * extent - extent * 0.5f;

    output[y * side + x] = iceDensity(g, disp, float3(u, g.cellAltitude - depth, v));
}

[shader("compute")]
[numthreads(64, 1, 1)]
void cellBound(uint3 tid : SV_DispatchThreadID,
               uniform GeneratorInput g,
               uniform StructuredBuffer<float2> disp,
               uniform float3 gridOrigin,
               uniform float3 cellSize,
               uniform int3 dims,
               uniform RWStructuredBuffer<float> outBound,
               uniform int cellCount)
{
    int i = int(tid.x);
    if (i >= cellCount) return;

    int cx = i % dims.x;
    int cy = (i / dims.x) % dims.y;
    int cz = i / (dims.x * dims.y);

    float3 lo = gridOrigin + float3(float(cx), float(cy), float(cz)) * cellSize;
    outBound[i] = iceDensityBound(g, disp, lo, lo + cellSize);
}

// The maximum density inside each cell of a grid, found by sampling.
//
// ===========================================================================
// THIS IS THE MEASUREMENT THE MAJORANT GRID NEEDS BEFORE IT CAN TOUCH THIS GENERATOR.
//
// slang.transport builds its grid bounds in CLOSED FORM, because its medium is a
// Gaussian core whose maximum over a box is exactly computable. That is what makes
// every result there falsifiable: a bound below the true density biases delta tracking
// silently, so a bound that is merely probably right makes the whole grid unfalsifiable.
//
// `iceDensity` has no closed-form maximum over a box. It is a product of a cell field,
// three smoothsteps and an fbm, evaluated through a drift lookup -- so its bounds have
// to be SAMPLED, and a sampled maximum can always miss a peak between its samples.
//
// The question is therefore not "does sampling miss" -- it does -- but BY HOW MUCH, so
// that a safety factor can be chosen against a number instead of against a feeling.
// This entry point exists to answer it: run it coarse, run it fine, and the ratio is
// the miss.
// ===========================================================================
[shader("compute")]
[numthreads(64, 1, 1)]
void cellMax(uint3 tid : SV_DispatchThreadID,
             uniform GeneratorInput g,
             uniform StructuredBuffer<float2> disp,
             uniform float3 gridOrigin,
             uniform float3 cellSize,
             uniform int3 dims,
             uniform int samplesPerAxis,
             uniform RWStructuredBuffer<float> outMax,
             uniform int cellCount)
{
    int i = int(tid.x);
    if (i >= cellCount) return;

    int cx = i % dims.x;
    int cy = (i / dims.x) % dims.y;
    int cz = i / (dims.x * dims.y);

    float3 lo = gridOrigin + float3(float(cx), float(cy), float(cz)) * cellSize;

    // MIDPOINTS, NOT CORNERS. Sampling the corners of a cell is the obvious choice and
    // is worse: neighbouring cells share corners, so the samples cluster on the cell
    // lattice and systematically miss the interior, which is exactly where a smooth
    // blob's peak sits.
    float m = 0.0f;
    for (int a = 0; a < samplesPerAxis; ++a)
    for (int b = 0; b < samplesPerAxis; ++b)
    for (int c = 0; c < samplesPerAxis; ++c)
    {
        float3 f = (float3(float(a), float(b), float(c)) + 0.5f) / float(samplesPerAxis);
        m = max(m, iceDensity(g, disp, lo + f * cellSize));
    }

    outMax[i] = m;
}

// The hash, so a test can measure its sensitivity to a one-ULP input change -- the
// property the sin-hash failed and the reason this file uses integers.
[shader("compute")]
[numthreads(64, 1, 1)]
void hashTrial(uint3 tid : SV_DispatchThreadID,
               uniform RWStructuredBuffer<float> output,
               uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    output[i] = hash22(int2(i, i * 7 + 3), 0u).x;
}
