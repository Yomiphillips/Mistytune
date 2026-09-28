// The production render: one camera ray, all the way home.
//
// ===========================================================================
// THIS IS THE FUNCTION THAT PUTS A CLOUD IN AFTER EFFECTS, and it is deliberately
// almost empty. Everything it needs was built and proved separately -- the RNG, the
// phase functions, the null-collision tracker, the majorant grid, the ice generator,
// the bounce loop, the atmosphere. Six test suites stand behind the six pieces. What
// was missing was the line that joins them, and this is that line.
//
// IT DOES NOT OWN THE PIXEL. The camera ray, the jitter, the accumulator, the
// exposure, the tonemap and the channel order all stay in src/kernel/Shading.h,
// which is ONE function compiled for both backends and is the reason a golden image
// taken on the CPU is a meaningful check on the GPU. Moving any of that in here
// would fork it, because this file is compiled twice -- once per target.
//
// So the seam is narrow on purpose: Shading.h hands over a ray and a seed and gets
// back linear radiance. Nothing about buffers, bit depths or windows crosses it.
// ===========================================================================
//
// WHY THERE IS NO `RenderInput` STRUCT WRAPPING THE TWO ARGUMENTS. Every struct that
// crosses this boundary has to be marshalled member by member on the host side --
// `Medium` alone is 96 bytes on one backend and 112 on the other, so a memcpy
// compiles, runs, and renders a wrong picture that looks like a missed ray. A
// wrapper would add a third struct to marshal and buy nothing.

#include "BounceLib.slang"

// Linear radiance for one camera ray.
//
// `seed` IS THE WHOLE DETERMINISM CONTRACT AND IT IS ALREADY MIXED. Shading.h
// derives it from (frame pixel, sample index, field seed) with a full avalanche hash
// -- never a clock, a thread id, or a counter shared between launches. So this takes
// it as the RNG state directly rather than re-hashing it: a second hash here would
// not make it more random and would make the two sides disagree about what the seed
// means, which is exactly the kind of thing that survives every test until someone
// renders the same frame twice on different worker counts.
public float3 renderSample(Scene s, PhaseInput ph,
                           StructuredBuffer<float> bounds,
                           StructuredBuffer<float2> drift,
                           float3 ro, float3 rd, uint seed)
{
    Rng rng = makeRng(seed);

    TraceResult r = trace(s, ph, bounds, drift, rng, ro, rd);

    // THE STEP AND BOUNCE COUNTS ARE DROPPED HERE AND THAT IS NOT AN OVERSIGHT.
    // `TraceResult` carries them because slang.transport and slang.bounce are built
    // on them -- a majorant sweep is meaningless without the step count, and the
    // furnace test's entire diagnostic rests on `capped`. The renderer has nowhere
    // to put them and no pass that shows them, so it takes the radiance and leaves
    // the instrumentation to the suites that were written for it.
    return r.pathRadiance;
}
