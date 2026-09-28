// Test entry points for the phase functions.
//
// THE PHASE FUNCTIONS THEMSELVES ARE IN PhaseLib.slang, and that split is forced
// rather than tidy -- see the note in that file. A kernel that wants to scatter light
// must be able to take `samplePhaseDir` WITHOUT taking `rngTrial` along with it.
//
// This file is the harness, and the generated Phase.cu it produces is what
// slang.phase compiles. Nothing in the shipping renderer should include it.

#include "PhaseLib.slang"

// ---------------------------------------------------------------------------
// Entry points, so the above survives dead-stripping and the tests can reach it
// ---------------------------------------------------------------------------

// Evaluates the phase function at a set of cosines.
// THE ENTRY POINTS TAKE THE DIAMETER, NOT THE DERIVED PARAMETERS.
//
// Two reasons, and the second is the one that forced it. First, it puts
// phaseFromDropletDiameter under test rather than leaving the caller to reproduce
// four exponential fits. Second, Slang dead-strips anything an entry point cannot
// reach -- a function nobody calls simply is not in the generated CUDA, so a host
// that wanted to call it would not find it.
[shader("compute")]
[numthreads(64, 1, 1)]
void phaseEval(uint3 tid : SV_DispatchThreadID,
               uniform float dropletDiameter,
               uniform int useIce,
               uniform RWStructuredBuffer<float> output,
               uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    PhaseInput params = phaseFromDropletDiameter(dropletDiameter, useIce);

    // MIDPOINTS OF A UNIFORM PARTITION OF cos(theta) IN [-1, 1], generated here
    // rather than uploaded: the integral this feeds needs millions of samples to
    // resolve a forward lobe, and a buffer of them is bandwidth spent to send a
    // number the GPU can compute from its own index.
    float mu = -1.0f + (float(i) + 0.5f) * (2.0f / float(count));
    output[i] = phaseAt(params, mu);
}

// The RNG, exposed so slang.transport can pin Transport.slang's copy against this
// one. Slang 2026.18.3 has no `[export]`, so the generator is stated in both files;
// a test is the only thing that can stop them drifting, and if they drift every
// determinism guarantee in the project goes with them.
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

// Draws directions from samplePhaseDir and reports the cosine and the weight, so a
// test can histogram one against the phase function and bound the other.
[shader("compute")]
[numthreads(64, 1, 1)]
void phaseSample(uint3 tid : SV_DispatchThreadID,
                 uniform float dropletDiameter,
                 uniform int useIce,
                 uniform RWStructuredBuffer<float> outCos,
                 uniform RWStructuredBuffer<float> outWeight,
                 uniform uint seed,
                 uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    PhaseInput params = phaseFromDropletDiameter(dropletDiameter, useIce);

    // A DISTINCT STREAM PER SAMPLE, derived from the index -- not a shared counter.
    Rng rng = makeRng(seed + uint(i) * 2654435761u);

    // Fixed incoming direction: the sampler builds its own frame around it, and the
    // distribution of the scattering angle does not depend on which frame that is.
    float3 wo = float3(0.0f, 0.0f, 1.0f);

    float weight;
    float3 dir = samplePhaseDir(params, rng, wo, weight);

    outCos[i]    = clamp(dot(dir, wo), -1.0f, 1.0f);
    outWeight[i] = weight;
}
