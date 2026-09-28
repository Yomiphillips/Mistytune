// The random number generator, stated once.
//
// ===========================================================================
// THIS FILE EXISTS BECAUSE THE BOUNCE LOOP NEEDS BOTH Phase.slang AND
// Transport.slang, AND THEY EACH CARRIED THEIR OWN COPY OF THE GENERATOR.
//
// That duplication was deliberate and recorded as "the lesser evil": Slang 2026.18.3
// has no `[export]`, so a shared module has to be pulled in by #include and each
// generated .cu carries its own copy of everything anyway. Two copies pinned by a
// test was cheaper than a module system that does not exist.
//
// It stops being the lesser evil the moment one file includes both, because then the
// two copies are in the SAME translation unit and `Rng` is defined twice. The
// extraction is forced rather than chosen -- which is the good case, since the
// alternative was a third copy.
//
// WHAT THE EXTRACTION MUST NOT DO IS CHANGE THE NUMBERS. The generator below is
// character-for-character what both files contained, so regenerating Phase.cu and
// Transport.cu after this change must produce BYTE-IDENTICAL output. That was
// checked, not assumed: `git diff` on the generated directory was empty.
//
// `slang.transport` still pins Transport.slang's `rngTrial` against Phase.slang's,
// and it is still worth running. It now checks something slightly different and
// still useful: that both generated artifacts really did pick up this file, rather
// than one of them retaining a stale local copy.
// ===========================================================================
//
// THE STATE IS PASSED, NOT GLOBAL, AND THAT IS A DELIBERATE DEPARTURE FROM THE
// PROTOTYPE. proto/index.html carries a mutable `uint rngState` at file scope and
// rand() advances it. That is fine for one fragment shader in a browser and is
// exactly what PLAN.md forbids here: seeds come from (frame, sample index, pixel)
// and nothing else -- never a counter shared between launches -- because motion blur
// renders one frame several times and MFR renders frames on different workers.
//
// An `inout` parameter makes the dependency visible in every signature that has one,
// so a future caller cannot accidentally share a stream between two pixels.

#ifndef MISTYTUNE_RNG_SLANG
#define MISTYTUNE_RNG_SLANG

public struct Rng
{
    uint state;
};

public Rng makeRng(uint seed)
{
    Rng r;
    r.state = seed;
    return r;
}

// PCG, matching the prototype's hash exactly.
public float randFloat(inout Rng r)
{
    r.state = r.state * 747796405u + 2891336453u;
    uint word = ((r.state >> ((r.state >> 28u) + 4u)) ^ r.state) * 277803737u;
    return float((word >> 22u) ^ word) * (1.0f / 4294967296.0f);
}

// A DECORRELATED SEED FROM A THREAD INDEX, which every test entry point in this
// project needs and two of them had already open-coded.
//
// Seeding a PCG state with `seed + i * k` and drawing immediately leaves the first
// draw correlated across threads -- consecutive states produce consecutive-looking
// first outputs, which biases anything that branches on that first draw. Since the
// first draw is exactly what a delta-tracking loop branches on, that correlation
// reaches the answer.
public Rng makeRngForIndex(uint seed, int index)
{
    uint s = uint(index) * 747796405u + 2891336453u;
    s = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return makeRng((s >> 22u) ^ s ^ seed);
}

#endif // MISTYTUNE_RNG_SLANG
