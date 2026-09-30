// The ice / fallstreak generator, ported from proto/index.html.
//
// The whole idea in three lines:
//
//   1. Crystals are BORN in discrete generating cells at one altitude.
//   2. They FALL at a speed their habit decides, while the wind carries them
//      sideways at a speed and bearing that change with height.
//   3. They SUBLIME away as they fall into drier air, which gives a streak an end.
//
// So the density at a point is not "noise evaluated here". It is: work out how far a
// parcel now at this height must have drifted since release, look back along that
// drift to find which cell released it, and ask how much of it is left. Detail is
// carried in the PARCEL'S OWN FRAME, which is why the fibres flow along the streak
// instead of shimmering through it. That inversion is the entire difference between
// this and a noise stack.

// ===========================================================================
// THE HASHES ARE INTEGER, AND THE PROTOTYPE'S WERE NOT. THIS IS A CORRECTNESS
// CHANGE, NOT A STYLE ONE.
//
// proto/index.html uses fract(sin(p) * 43758.5453123), the classic GLSL sin-hash.
// It is fine in a browser, on one GPU, for a look verdict. It cannot survive this
// project's requirements, and the reason is measurable rather than theoretical.
//
// MEASURED: perturbing the hash input by ONE ULP.
//
//     grid coord      hash(x)     hash(x + 1ulp)    difference
//           17.3     0.325256          0.326319      0.001064
//          128.0     0.561327          0.098675      0.462652
//         1024.0     0.809906          0.084025      0.725881
//        65536.0     0.777520          0.086796      0.690725
//
// At a grid coordinate of 1024 a single last-bit change moves the hash from 0.81 to
// 0.08. The function is chaotic in its lowest input bit, which is exactly what a
// hash should be -- and exactly what makes it unusable here.
//
// PLAN.md's premise is ONE SOURCE compiled to CUDA and to Metal. sin() of a large
// argument is where vendors differ, because it is argument reduction rather than the
// core polynomial, and they will differ by an ULP somewhere. Amplified by 43758 and
// wrapped by fract, an ULP becomes a completely different number -- so the cells land
// in different places and THE SAME COMP RENDERS A DIFFERENT CLOUD ON MAC AND WINDOWS.
// tests/golden/'s own header names cross-platform float divergence as the thing that
// tier exists to catch; this would defeat it at the first hurdle.
//
// THE FIX IS FREE, because every hash input here is an INTEGER LATTICE COORDINATE --
// floor(g) in cellField, floor(p) in gradientNoise. Integer hashes are exactly
// reproducible on every platform by construction, cost about the same, and are of
// better statistical quality than a sin-hash. PCG2D/PCG3D (Jarzynski & Olano 2020).
//
// The realisation of the noise changes, so the cloud is not pixel-identical to the
// prototype's. The STRUCTURE -- discrete cells, jittered slots, the spacing that
// leaves clear lanes -- is preserved exactly, and that structure is what Phase 0's
// verdict was about.
// ===========================================================================

// ---------------------------------------------------------------------------
// WHY THIS IS A `Lib` FILE AND Generator.slang IS NOT
// ---------------------------------------------------------------------------
//
// The transport needs `iceDensity` and `iceDensityBound`, and an #include in Slang
// drags in the including file's ENTRY POINTS as well as its functions. Without the
// split, TransportLib would inherit densityColumn, densityPlane, cellMax, cellBound and
// hashTrial -- five test kernels in the shipping renderer, and a name collision waiting
// for the next file that does the same.
//
// Same rule as PhaseLib and TransportLib: `XLib.slang` holds functions and nothing else,
// `X.slang` is the harness that adds the entry points its own test needs.
//
// UNLIKE THOSE TWO, THIS SPLIT IS NOT BYTE-INERT. The structural-bound functions sat
// BELOW densityColumn and densityPlane in the original file, and slangc emits in
// declaration order -- so gathering the library together reorders the generated CUDA.
// The set of emitted functions is unchanged and that is what slang.generator checks;
// the diff is a permutation, not a change.

#ifndef MISTYTUNE_GENERATOR_LIB_SLANG
#define MISTYTUNE_GENERATOR_LIB_SLANG

// The Organization group, which both generators share. It reads gradientNoise and
// kFbmBound from further down this file; Slang resolves a module's names in any order.
#include "OrganizationLib.slang"

public struct GeneratorInput
{
    float cellAltitude;   // m, the release level
    float streakLength;   // m, how far a streak falls before the slab ends
    float cellSize;       // m
    float cellDensity;    // 0..1, the fraction of grid slots holding a cell
    float cellStrength;
    float2 cellDrift;     // m, bulk translation of the generating level
    float sublimation;    // per km
    float fallSpeed;      // m/s
    float detailScale;    // m
    float detailAmount;
    float opticalDepth;   // what a vertical path through a thick streak integrates to
    float timeSeconds;
    int   octaves;

    // How the generating cells are arranged (build 20). Zero is no organization.
    Organization gnOrg;
};

// THE GRID IS WIDER THAN THE CELLS, and that spacing is the whole reason this reads
// as generating cells rather than as a slab. A cell whose blob radius equals the grid
// spacing overlaps all its neighbours, so above about a third occupancy the field is
// continuous everywhere -- no gaps, no distinct heads, and an optical depth several
// times what the slider says because the overlaps sum.
//
// The clear lanes between streak families are as much of the look as the streaks are:
// a photograph of uncinus is mostly empty sky.
public static const float kCellSpacing = 2.2f;

// ---------------------------------------------------------------------------
// THE JITTER WIDTH AND THE BLOB'S TWO EDGES, NAMED BECAUSE A THEOREM DEPENDS ON THEM.
//
// src/engine/IceField.h derives cellOverlapBound() from these three numbers and
// kCellSpacing: at most four of the nine neighbouring slots can reach any point, and
// those four cannot all reach their ceiling. It gets 3.26 where the trivial count gets
// 9, and that is a 2.76x cut in tracking steps.
//
// IT HAS TO MIRROR THEM, because host C++ cannot include a .slang file. They were bare
// literals here, which made the mirror a copy of a number nobody had named -- and a
// mirrored constant that drifts does not fail to compile, it lowers a majorant below
// the field and renders a cloud that is quietly too thin.
//
// SO slang.generator READS THESE BACK AND COMPARES THEM AGAINST THE HOST'S, EXACTLY.
// Naming them is what makes that possible. MEASURED while writing that check: moving
// the host's kCellSpacing to 2.6 -- an 18% error, far larger than a typo -- leaves the
// bound at 2.96, which still covers everything a dense sweep of the field actually
// finds, so sampling alone does not catch it. See cellGeometry below.
// ---------------------------------------------------------------------------
public static const float kCellJitter = 0.8f;
public static const float kBlobFar    = 1.0f;   // smoothstep's far edge -- zero here
public static const float kBlobNear   = 0.05f;  // ...and its near edge -- one here


// ---------------------------------------------------------------------------
// Integer hashes
// ---------------------------------------------------------------------------

uint2 pcg2d(uint2 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v >> 16u);
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v >> 16u);
    return v;
}

uint3 pcg3d(uint3 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v = v ^ (v >> 16u);
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    return v;
}

// 0..1 from an integer lattice coordinate. `salt` separates independent hashes of
// the same coordinate -- see the note at its call site, which is load-bearing.
public float2 hash22(int2 c, uint salt)
{
    uint2 h = pcg2d(uint2(uint(c.x), uint(c.y)) ^ uint2(salt, salt * 2654435761u));
    return float2(h) * (1.0f / 4294967296.0f);
}

// -1..1 gradient vector from an integer lattice coordinate.
public float3 hash33(int3 c)
{
    uint3 h = pcg3d(uint3(uint(c.x), uint(c.y), uint(c.z)));
    return float3(h) * (2.0f / 4294967296.0f) - 1.0f;
}

// ---------------------------------------------------------------------------
// Noise, for the advected detail only
// ---------------------------------------------------------------------------

public float gradientNoise(float3 p)
{
    float3 fi = floor(p);
    int3   i  = int3(fi);
    float3 f  = p - fi;
    float3 u  = f * f * (3.0f - 2.0f * f);

    return lerp(lerp(lerp(dot(hash33(i + int3(0,0,0)), f - float3(0,0,0)),
                          dot(hash33(i + int3(1,0,0)), f - float3(1,0,0)), u.x),
                     lerp(dot(hash33(i + int3(0,1,0)), f - float3(0,1,0)),
                          dot(hash33(i + int3(1,1,0)), f - float3(1,1,0)), u.x), u.y),
                lerp(lerp(dot(hash33(i + int3(0,0,1)), f - float3(0,0,1)),
                          dot(hash33(i + int3(1,0,1)), f - float3(1,0,1)), u.x),
                     lerp(dot(hash33(i + int3(0,1,1)), f - float3(0,1,1)),
                          dot(hash33(i + int3(1,1,1)), f - float3(1,1,1)), u.x), u.y), u.z);
}

public float fbm(float3 p, int octaves)
{
    float sum = 0.0f, amp = 0.5f, norm = 0.0f;
    for (int i = 0; i < 6; ++i)
    {
        if (i >= octaves) break;
        sum  += amp * gradientNoise(p);
        norm += amp;
        p    *= 2.02f;
        amp  *= 0.5f;
    }
    return norm > 0.0f ? sum / norm : 0.0f;
}

// ---------------------------------------------------------------------------
// The generating cells
// ---------------------------------------------------------------------------

public float cellField(GeneratorInput g, float2 q)
{
    float spacing = g.cellSize * kCellSpacing;
    float2 gq = orgPattern(g.gnOrg, q - g.cellDrift, spacing);
    float2 gf = floor(gq);
    int2   gi = int2(gf);
    float2 jitterWidth = orgJitter(g.gnOrg, kCellJitter);

    float acc = 0.0f;

    for (int j = -1; j <= 1; ++j)
    {
        for (int i = -1; i <= 1; ++i)
        {
            int2 o = gi + int2(i, j);

            // A SEPARATE HASH FROM THE ONE THAT JITTERS THE POSITION. Reusing one
            // would correlate "is there a cell here" with "where is it", and the
            // cells would drift towards one corner of every occupied slot in a
            // visibly regular way. The prototype separates them by adding 17.3 to
            // the coordinate; an integer hash separates them with a salt, which
            // cannot collide with a real coordinate the way an offset can.
            if (hash22(o, 0x9e3779b9u).x > g.cellDensity) continue;

            float2 jitter = hash22(o, 0u) - 0.5f;
            float2 c = float2(o) + 0.5f + jitter * jitterWidth;

            // Measured in cell-sizes rather than grid units, so cellSize means the
            // cell and not the spacing.
            float d = length(gq - c) * kCellSpacing;
            acc += smoothstep(kBlobFar, kBlobNear, d);
        }
    }

    // THE WAVE, at most one, so cellOverlapBound's majorant still holds. Exactly one when
    // there is no organization.
    return acc * g.cellStrength * orgWaveFactor(g.gnOrg, q - g.cellDrift);
}

// ---------------------------------------------------------------------------
// Density
// ---------------------------------------------------------------------------

// Horizontal drift accumulated between release and a given depth below the
// generating level, as a 33-knot lookup -- the CPU precomputes it as a prefix
// integral of wind over fall speed, so this is a lookup and not an integral.
public float2 driftAt(GeneratorInput g, StructuredBuffer<float2> disp, float depth)
{
    float x = clamp(depth / g.streakLength, 0.0f, 1.0f) * 32.0f;
    int i = clamp(int(floor(x)), 0, 31);
    return lerp(disp[i], disp[i + 1], x - float(i));
}

public float iceDensity(GeneratorInput g, StructuredBuffer<float2> disp, float3 p)
{
    float depth = g.cellAltitude - p.y;
    if (depth < 0.0f || depth > g.streakLength) return 0.0f;

    // BACK ALONG THE DRIFT to where this parcel was released.
    float2 source = p.xz - driftAt(g, disp, depth);

    float cell = cellField(g, source);
    if (cell <= 0.001f) return 0.0f;

    // SUBLIMATION gives the streak an end. Without it every streak reaches the bottom
    // of the slab and the sky looks combed rather than alive.
    float subl = exp(-g.sublimation * depth / 1000.0f);

    // A soft head at the generating level: crystals take a moment to grow, so the very
    // top of a streak is thinner than just below it.
    float head = smoothstep(0.0f, 0.08f * g.streakLength, depth);

    // ...and a soft tail, so the streak fades rather than being cut off by the slab.
    float tail = 1.0f - smoothstep(0.75f * g.streakLength, g.streakLength, depth);

    // THE ADVECTED DETAIL, sampled in the SOURCE frame -- the parcel's own coordinates
    // at release -- plus its age. Sample it at p instead and the fibres sit still in
    // world space while the cloud moves through them, which is the single most
    // recognisable tell of a procedural cloud.
    float age = depth / max(g.fallSpeed, 0.01f);
    float det = fbm(float3(source / g.detailScale, age * 0.02f + g.timeSeconds * 0.01f),
                    g.octaves);
    float detail = 1.0f + g.detailAmount * det * 1.8f;

    float shape = cell * subl * head * tail * max(detail, 0.0f);

    // NORMALISED BY THE STREAK LENGTH, so that "optical depth" MEANS optical depth: a
    // vertical path through the thickest part of a streak integrates to roughly the
    // value on the slider.
    //
    // Worth doing rather than leaving a tuned constant in front of it. Cirrus has a
    // measured optical depth of about 0.1 to 0.7, and a parameter that agrees with the
    // literature is checkable against it; one that happens to look right at 0.45
    // because of a hidden factor is not.
    return max(shape, 0.0f) * g.opticalDepth / max(g.streakLength, 1.0f);
}

// ---------------------------------------------------------------------------
// A STRUCTURAL MAJORANT BOUND
// ---------------------------------------------------------------------------
//
// ===========================================================================
// SAMPLING CANNOT BOUND THIS FIELD, AND THAT IS MEASURED RATHER THAN ASSUMED.
//
// `cellMax` below samples a cell and takes the maximum. slang.generator runs it coarse
// against a fine reference and the answer is stark: at every practical resolution the
// coarse pass finds NOTHING in cells the reference says are occupied, and even an 8^3
// pass underestimates 99% of them. Cirrus is thin filaments in mostly clear air, so a
// sparse sample of a cell usually lands in the clear.
//
// A SAMPLED BOUND OF ZERO IS THE WORST FAILURE AVAILABLE. TransportLib treats a zero
// bound as proof that there is nothing to collide with and crosses the cell in one step
// without drawing a random number -- so a cell with cloud in it would be skipped
// outright, and the cloud would simply not be there.
//
// So the bound is built from the generator's STRUCTURE instead. `iceDensity` is a
// product of factors, and each one can be bounded over a box on its own:
//
//   depth      -- from the box's y range, and everything below keys off it
//   subl       -- exp(-k*depth), decreasing, so its max is at the SHALLOWEST depth
//   head       -- smoothstep rising with depth, max at the DEEPEST
//   tail       -- smoothstep falling with depth, max at the SHALLOWEST
//   detail     -- 1 + amount*1.8*fbm, and |fbm| has a hard analytic bound
//   cellField  -- a sum of localised blobs; each is maximised at the point of the box
//                 nearest its centre, and summing those maxima bounds the sum
//
// The product of the maxima is an upper bound on the maximum of the product. It is
// LOOSER than the truth -- the factors do not all peak at the same point -- but it is
// sound by construction, which sampling is not at any resolution. Looseness costs
// steps; unsoundness costs correctness, and only one of those is recoverable.
// ===========================================================================

// |fbm| <= |gradientNoise| <= sqrt(3) * sqrt(3)/2 for gradients in [-1,1]^3, and fbm
// divides by the sum of its amplitudes. 1.5 is that bound; it is not tuned, and it is
// the reason `detail` can be bounded without sampling it.
public static const float kFbmBound = 1.5f;

// The largest cellField can be anywhere in a source-space box.
//
// Each blob is `smoothstep(1, 0.05, d)`, which DECREASES with distance -- so a blob is
// largest at the point of the box nearest its centre, and that distance is the
// per-axis distance outside the box, which is zero when the centre is inside it.
public float cellFieldBound(GeneratorInput g, float2 q0, float2 q1)
{
    float spacing = g.cellSize * kCellSpacing;
    float2 a, b;
    orgPatternBox(g.gnOrg, q0 - g.cellDrift, q1 - g.cellDrift, spacing, a, b);
    float2 jitterWidth = orgJitter(g.gnOrg, kCellJitter);

    int2 i0 = int2(floor(a)) - int2(1, 1);
    int2 i1 = int2(floor(b)) + int2(1, 1);

    float acc = 0.0f;

    // A CAP, because the box widens with the drift spread across the cell's depth range
    // and an unbounded double loop here is a hang rather than a slow frame. 32x32 slots
    // is far beyond anything a sane grid cell produces; overflowing it is a sign the
    // grid cell is too tall, not that the cap is wrong.
    for (int j = i0.y; j <= i1.y && j <= i0.y + 32; ++j)
    for (int i = i0.x; i <= i1.x && i <= i0.x + 32; ++i)
    {
        int2 o = int2(i, j);
        if (hash22(o, 0x9e3779b9u).x > g.cellDensity) continue;

        float2 jitter = hash22(o, 0u) - 0.5f;
        float2 c = float2(o) + 0.5f + jitter * jitterWidth;

        // Per-axis distance from the box to the centre; zero on an axis where the
        // centre lies inside the box's span.
        float2 d = max(max(a - c, c - b), float2(0.0f, 0.0f));
        float dist = length(d) * kCellSpacing;

        acc += smoothstep(kBlobFar, kBlobNear, dist);
    }

    return acc * g.cellStrength;
}

// The drift over a depth range, as a box. `driftAt` interpolates a 33-knot table, so
// the extremes over a range are found by scanning the knots it spans plus the two
// interpolated ends -- no assumption that the drift is monotonic in depth, because a
// veering wind means it is not.
public void driftRange(GeneratorInput g, StructuredBuffer<float2> disp,
                       float d0, float d1, out float2 lo, out float2 hi)
{
    lo = driftAt(g, disp, d0);
    hi = lo;

    float2 e = driftAt(g, disp, d1);
    lo = min(lo, e);
    hi = max(hi, e);

    int k0 = clamp(int(floor(clamp(d0 / g.streakLength, 0.0f, 1.0f) * 32.0f)), 0, 32);
    int k1 = clamp(int(ceil (clamp(d1 / g.streakLength, 0.0f, 1.0f) * 32.0f)), 0, 32);

    for (int k = k0; k <= k1; ++k)
    {
        lo = min(lo, disp[k]);
        hi = max(hi, disp[k]);
    }
}

// An upper bound on iceDensity anywhere in the box [lo, hi].
public float iceDensityBound(GeneratorInput g, StructuredBuffer<float2> disp,
                             float3 lo, float3 hi)
{
    float d0 = g.cellAltitude - hi.y;   // shallowest depth in the box
    float d1 = g.cellAltitude - lo.y;   // deepest

    if (d1 < 0.0f || d0 > g.streakLength) return 0.0f;
    d0 = clamp(d0, 0.0f, g.streakLength);
    d1 = clamp(d1, 0.0f, g.streakLength);

    float subl = exp(-g.sublimation * d0 / 1000.0f);
    float head = smoothstep(0.0f, 0.08f * g.streakLength, d1);
    float tail = 1.0f - smoothstep(0.75f * g.streakLength, g.streakLength, d0);

    float detail = 1.0f + g.detailAmount * kFbmBound * 1.8f;

    float2 driftLo, driftHi;
    driftRange(g, disp, d0, d1, driftLo, driftHi);

    // source = p.xz - drift, so the source box is the position box minus the drift box.
    float2 s0 = float2(lo.x, lo.z) - driftHi;
    float2 s1 = float2(hi.x, hi.z) - driftLo;

    float cell = cellFieldBound(g, s0, s1);

    return max(cell * subl * head * tail * max(detail, 0.0f), 0.0f)
         * g.opticalDepth / max(g.streakLength, 1.0f);
}


#endif // MISTYTUNE_GENERATOR_LIB_SLANG
