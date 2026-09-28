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

// cellField over a horizontal plane, for the host's cell-overlap bound.
//
// ===========================================================================
// THE ONE PLACE IN THIS GENERATOR WHERE DENSE SAMPLING IS A REAL CHECK RATHER THAN A
// GUESS, AND THE FBM IS THE WHOLE DIFFERENCE.
//
// `iceDensity` cannot be bounded by sampling, and the note above cellMax says why: the
// detail term is fractal, so a grid that missed the peak by a metre is wrong in exactly
// the way that surfaces in somebody else's scene.
//
// `cellField` HAS NO FBM IN IT. It is a sum of at most nine smoothsteps of a distance
// -- smooth, Lipschitz, and with its scale set by the cell spacing -- so a grid finer
// than that scale genuinely finds its maximum rather than hoping at it.
//
// WHICH IS WHAT MAKES THIS A TRIPWIRE ON A THEOREM. src/engine/IceField.h mirrors
// kCellSpacing, kCellJitter and the two blob edges from this file, and DERIVES a bound
// of 3.26 from them -- four reachable slots rather than nine, and four blobs that
// cannot all reach their ceiling. Nothing in either language makes those two copies of
// the constants agree. This does: run the KERNEL's cellField with every slot occupied,
// densely, and the host's bound must be above everything it finds. A constant that
// drifts on one side is then caught by the very field it is supposed to bound, which is
// a better tripwire than comparing the two numbers.
// ===========================================================================
[shader("compute")]
[numthreads(8, 8, 1)]
void cellFieldPlane(uint3 tid : SV_DispatchThreadID,
                    uniform GeneratorInput g,
                    uniform float2 origin,
                    uniform float span,
                    uniform RWStructuredBuffer<float> output,
                    uniform int side)
{
    int x = int(tid.x), y = int(tid.y);
    if (x >= side || y >= side) return;

    float u = origin.x + (float(x) + 0.5f) / float(side) * span;
    float v = origin.y + (float(y) + 0.5f) / float(side) * span;

    output[y * side + x] = cellField(g, float2(u, v));
}

// The four constants cellOverlapBound()'s derivation stands on, read back FROM THE
// KERNEL, plus the blob evaluated at a distance the host chooses.
//
// ===========================================================================
// THE OTHER HALF OF THE CELL-OVERLAP TRIPWIRE, AND IT EXISTS BECAUSE THE SAMPLED HALF
// WAS MEASURED AND FOUND TOO WEAK.
//
// cellFieldPlane below sweeps the real field and checks the host's bound covers it.
// That catches a wrong DERIVATION. It does not catch a small drift in a mirrored
// constant: moving the host's kCellSpacing from 2.2 to 2.6 lowers its bound from 3.26 to
// 2.96, which still covers the 1.77 a 49-patch sweep actually finds, so the sweep passes
// and the majorant is wrong. The reason is the same one that makes the peak-density
// sweep a floor rather than a truth -- the worst jitter configuration is rare, so a
// sweep of hundreds of neighbourhoods does not contain it.
//
// So this reports the constants themselves, exactly, and the blob's own value at the
// distance the derivation's worst case sits at. The two checks divide the work and
// neither subsumes the other:
//
//   the sweep   catches a wrong derivation, which exact constants would pass
//   this        catches a drifted copy, which the sweep passes until it is enormous
// ===========================================================================
[shader("compute")]
[numthreads(8, 1, 1)]
void cellGeometry(uint3 tid : SV_DispatchThreadID,
                  uniform RWStructuredBuffer<float> output,
                  uniform int count)
{
    if (int(tid.x) != 0 || count < 6) return;

    output[0] = kCellSpacing;
    output[1] = kCellJitter;
    output[2] = kBlobFar;
    output[3] = kBlobNear;

    // ===================================================================
    // THE WORST CASE, DERIVED AND EVALUATED HERE RATHER THAN PASSED IN, AND THAT IS THE
    // WHOLE POINT OF THIS ENTRY POINT.
    //
    // The first version took the distance as a uniform and the host computed it from its
    // OWN mirrored constants. That check could not fail: drift the host's kCellSpacing
    // and it asks about a different distance, gets a consistent answer back, and agrees
    // with itself. Verified -- the 2.2-to-2.6 drift passed it.
    //
    // So the kernel derives the configuration from ITS constants: a point on a slot
    // corner, with all four cells that share the corner jittered as close to it as the
    // inset allows. Now the host has nothing to contribute but its answer, and the two
    // can actually disagree.
    // ===================================================================
    float inset  = (1.0f - kCellJitter) * 0.5f;
    float corner = sqrt(2.0f * inset * inset) * kCellSpacing;

    output[4] = 4.0f * smoothstep(kBlobFar, kBlobNear, corner);
    output[5] = corner;
}
