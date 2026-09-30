// How a generator's cells are arranged: the kernel's half of the Organization group.
//
// ===========================================================================
// THE SPEC'S VARIETIES ARE ALMOST ALL ABOUT LAYOUT -- rows, waves, gaps between cells and
// holes through them -- so one set of numbers serves every generator, and each layer has
// its own. src/engine/Organization.h resolves the controls into this struct; the modes
// (Cellular, Rolls, Waves, Chaotic) are settings of it and do not exist down here.
//
// EVERYTHING HERE WORKS ON A GENERATOR'S LATTICE COORDINATES, and that is why the bounds
// survive it. Both generators prove their bounds in LATTICE UNITS: the 3x3 neighbourhood
// being the whole field, the reaches, the ice's overlap count. Rotating the lattice and
// stretching it along its rows changes where the lattice sits in the world, not one of
// those statements about the lattice. So:
//
//   the PATTERN FRAME   rotates the world so the rows run along ogAxis and divides by
//                       the cell's spacing, times ogStretch along the rows. A box in the
//                       world is a parallelogram there; its bounding box is what a bound
//                       searches, which is sound and at worst looser.
//   the ROW JITTER      shrinks the lattice's jitter ACROSS the rows by ogCoherence. Every
//                       layout it allows was already one the full jitter allowed, so any
//                       bound that held over all of those holds over these.
//   the WAVE            multiplies by a factor in [1 - amplitude, 1]. Never above one, so
//                       it can only lower a density a bound was already above.
//   the WARP            moves the point the lattice is read at, by at most ogWarp times
//                       gradientNoise's bound per axis. A bound's box grows by the same.
//
// ZERO IS NONE: ogOn 0 skips all of it, and a zeroed struct -- which is how every test
// builds its inputs -- is the field as it was before build 20, bit for bit.
//
// FIELD NAMES CARRY `og`, unique across the kernel, for the reason Environment.envMode
// gives in BounceLib.slang.
// ===========================================================================

#ifndef MISTYTUNE_ORGANIZATION_LIB_SLANG
#define MISTYTUNE_ORGANIZATION_LIB_SLANG

public struct Organization
{
    int    ogOn;
    float2 ogAxis;       // unit, world xz: the direction the rows run
    float  ogStretch;    // >= 1: a cell's length along the rows over its width
    float  ogCoherence;  // 0..1: the jitter across the rows is (1 - this) of full
    float2 ogWaveK;      // CYCLES per metre, across the wave's crests
    float  ogWaveAmp;    // 0..1
    float  ogWarp;       // lattice units: Chaotic's
};

// The warp's own scale, in lattice units: one noise feature every this many cells, so it
// bends rows and bunches cells without tearing a single one apart. See kChaoticWarp in
// src/engine/Organization.h for the amplitude, and why it and this were raised.
public static const float kOrgWarpScale = 2.5f;

// The warp read twice at unrelated places, one number per axis.
float2 orgWarpOffset(Organization o, float2 g)
{
    float2 s = g / kOrgWarpScale;
    return o.ogWarp * float2(gradientNoise(float3(s.x, 0.37f, s.y)),
                             gradientNoise(float3(s.x + 17.1f, 5.83f, s.y - 9.4f)));
}

// A point of the generator's pattern frame (metres, drift already taken off) in lattice
// units.
//
// ogOn 0 IS EXACTLY THE DIVISION EVERY GENERATOR DID BEFORE BUILD 20. On, the division
// is kept rather than a reciprocal multiplied, so an Alignment of 90 degrees and nothing
// else lands on the old lattice to float precision.
public float2 orgPattern(Organization o, float2 q, float spacing)
{
    if (o.ogOn == 0) return q / spacing;

    float2 across = float2(-o.ogAxis.y, o.ogAxis.x);
    float2 r = float2(dot(q, o.ogAxis), dot(q, across));
    float2 g = r / float2(spacing * o.ogStretch, spacing);
    if (o.ogWarp > 0.0f) g = g + orgWarpOffset(o, g);
    return g;
}

// A gradient in lattice units back to per metre in the world.
//
// THE WARP'S OWN SLOPE IS LEFT OUT. A generator uses this gradient only to estimate how
// far a point is from a wall, and the one that bounds that estimate clamps the slope it
// uses to a cap it can prove its bound with (convSlopeCap). An estimate a little off in
// Chaotic mode moves a billow; a bound resting on a slope nobody computed would not.
public float2 orgGradToWorld(Organization o, float2 gp, float spacing)
{
    if (o.ogOn == 0) return gp / spacing;

    float2 across = float2(-o.ogAxis.y, o.ogAxis.x);
    float2 s = gp / float2(spacing * o.ogStretch, spacing);
    return o.ogAxis * s.x + across * s.y;
}

// The lattice-unit box every point of the world box [q0, q1] maps into: the four
// corners' bounding box, grown by the warp's reach and by a sliver for the rounding the
// density's own transform does along a different expression.
public void orgPatternBox(Organization o, float2 q0, float2 q1, float spacing,
                          out float2 a, out float2 b)
{
    if (o.ogOn == 0)
    {
        a = q0 / spacing;
        b = q1 / spacing;
        return;
    }

    Organization flat = o;
    flat.ogWarp = 0.0f;
    float2 c00 = orgPattern(flat, q0, spacing);
    float2 c11 = orgPattern(flat, q1, spacing);
    float2 c01 = orgPattern(flat, float2(q0.x, q1.y), spacing);
    float2 c10 = orgPattern(flat, float2(q1.x, q0.y), spacing);

    float grow = o.ogWarp * kFbmBound + 1e-4f
               + 1e-6f * max(max(abs(c00.x), abs(c00.y)), max(abs(c11.x), abs(c11.y)));
    a = min(min(c00, c01), min(c10, c11)) - grow;
    b = max(max(c00, c01), max(c10, c11)) + grow;
}

// The lattice's jitter per axis: full along the rows, (1 - coherence) of it across.
public float2 orgJitter(Organization o, float jitter)
{
    return float2(jitter, o.ogOn != 0 ? jitter * (1.0f - o.ogCoherence) : jitter);
}

// ---------------------------------------------------------------------------
// The wave
// ---------------------------------------------------------------------------
//
// A FACTOR IN [1 - amplitude, 1], one at the crests, at pattern-frame point q (metres).
//
// A POLYNOMIAL, NOT A COSINE: the crest-to-crest profile is smoothstep of a triangle
// wave, flat at crest and trough like a sine and within 0.02 of one. frac() of a small
// number is exact on every backend, where a cosine of a phase in the hundreds is the
// cross-platform hazard GeneratorLib's note on transcendentals describes.
//
// THE SLOPE IS AT MOST 3 x amplitude x |k| per metre: smoothstep's steepest is 1.5 of its
// input's, and the triangle's is 2 per cycle.
public float orgWave(Organization o, float2 q, out float2 grad)
{
    grad = float2(0.0f, 0.0f);
    if (o.ogOn == 0 || o.ogWaveAmp <= 0.0f) return 1.0f;

    float u   = frac(dot(q, o.ogWaveK));
    float s   = 2.0f * u - 1.0f;
    float tri = 1.0f - abs(s);                  // 1 at the crest, u = 1/2
    float crest = tri * tri * (3.0f - 2.0f * tri);

    float dCrest = 6.0f * tri * (1.0f - tri);   // d crest / d tri
    float dTri   = s > 0.0f ? -2.0f : 2.0f;     // d tri / d u
    grad = o.ogWaveK * (o.ogWaveAmp * dCrest * dTri);
    return 1.0f - o.ogWaveAmp * (1.0f - crest);
}

public float orgWaveFactor(Organization o, float2 q)
{
    float2 unused;
    return orgWave(o, q, unused);
}

#endif // MISTYTUNE_ORGANIZATION_LIB_SLANG
