// The CPU arm of "one kernel source", and the test that it really is one.
//
// ===========================================================================
// WHY THIS FILE EXISTS AT ALL, RATHER THAN COMPILING Transport.slang TO BOTH TARGETS.
//
// It would be tidier to take one .slang and emit both CUDA and C++ from it. That does
// not link: slangc marks entry points `SLANG_PRELUDE_EXPORT`, which is `extern "C"`, so
// the CUDA `transmittanceTrial` and the C++ `transmittanceTrial` are the same symbol and
// a binary containing both will not build. Wrapping one in a namespace does not help --
// `extern "C"` ignores namespaces, which is the whole point of it.
//
// So the CPU side gets its own entry points, named `cpu*`, over THE SAME LIBRARY. That
// is not a weaker test than compiling one file twice; it is the same test. The entry
// point is a handful of lines of marshalling, and what parity is being claimed about is
// `transmittance`, `sampleFreeFlight`, `randFloat` and the phase functions -- every one
// of which is the identical source text, included here and in Transport.slang alike.
// ===========================================================================
//
// WHAT THE PARITY IS FOR. PLAN.md asks for one kernel source and `renderPixel` is one
// function serving both engines. A golden image rendered on the CPU is only a
// meaningful check on the GPU while the two compute the same maths -- so the moment the
// transport reaches the production path, "the CUDA backend and the C++ backend agree"
// stops being a nice property and becomes the thing the entire test strategy rests on.
//
// IT IS NOT EXPECTED TO BE BITWISE, and the test does not ask for that. slang.mathParity
// established that Slang's CUDA output calls the same libm-equivalent functions as
// hand-written CUDA; it established nothing about the host compiler's libm agreeing with
// the device's to the last bit, and it will not for the transcendentals. What must hold
// is that they agree far more closely than tests/golden/'s own tolerance, which is what
// makes a CPU reference usable at all.

#include "TransportLib.slang"

// The generator, value for value. If the two backends disagree here the cause is the
// hash or the noise, not the transport, and that is worth separating.
[shader("compute")]
[numthreads(64, 1, 1)]
void cpuRngTrial(uint3 tid : SV_DispatchThreadID,
                 uniform RWStructuredBuffer<float> output,
                 uniform uint seed,
                 uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    Rng rng = makeRng(seed + uint(i));
    output[i] = randFloat(rng);
}

// NO PHASE ARM HERE, AND THE REASON IS THE SAME LINKAGE PROBLEM ONE LEVEL UP. Each CPU
// entry point is compared against a CUDA one, and the CUDA ones must all come from a
// single translation unit -- Transport.cu, which has `rngTrial` and `transmittanceTrial`.
// Phase.cu also declares an `rngTrial`, so the two generated files cannot be included
// together, and a phase comparison would need its own paired file.
//
// Little is lost: `cpuTransmittanceTrial` on the ice medium already runs the
// transcendental-heavy path -- exp, the fbm, the gradient noise and the PCG hashes --
// which is where the two backends' libm would diverge if they were going to.

// Ratio-tracked transmittance, which exercises the whole estimator: the RNG, the slab
// geometry, the density, the grid lookup and the loop.
[shader("compute")]
[numthreads(64, 1, 1)]
void cpuTransmittanceTrial(uint3 tid : SV_DispatchThreadID,
                           uniform Medium medium,
                           uniform MajorantGrid grid,
                           uniform StructuredBuffer<float> bounds,
                           uniform StructuredBuffer<float2> drift,
                           uniform float3 origin,
                           uniform float3 direction,
                           uniform RWStructuredBuffer<float> output,
                           uniform uint seed,
                           uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    Rng rng = makeRngForIndex(seed, i);

    int steps = 0;
    output[i] = transmittance(medium, grid, bounds, drift, rng, origin, direction, steps);
}
