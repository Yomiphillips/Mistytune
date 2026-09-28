// The bounce loop: the test harness over BounceLib.slang.
//
// THE PATH TRACER MOVED TO BounceLib.slang AND DID NOT CHANGE. This file is the
// three test kernels and nothing else, for the same reason Generator.slang and
// Transport.slang are: RenderLib.slang includes the LIBRARY, and without the split
// the production kernel would inherit `traceTrial`, `phaseValueTrial` and
// `phaseParamsTrial` -- three compute entry points in the shipping binary, reachable
// from nothing.
//
// Read BounceLib.slang's header first. It is where the furnace test is argued for,
// and the argument is the reason to trust anything below.

#include "BounceLib.slang"


// ---------------------------------------------------------------------------
// Entry points for the tests
// ---------------------------------------------------------------------------

[shader("compute")]
[numthreads(64, 1, 1)]
void traceTrial(uint3 tid : SV_DispatchThreadID,
                uniform Scene scene,
                uniform PhaseInput phase,
                uniform StructuredBuffer<float> bounds,
                uniform StructuredBuffer<float2> drift,
                uniform float3 origin,
                uniform float3 direction,
                uniform RWStructuredBuffer<float3> outRadiance,
                uniform RWStructuredBuffer<int> outScatterEvents,
                uniform RWStructuredBuffer<int> outCapped,
                uniform RWStructuredBuffer<int> outSteps,
                uniform uint seed,
                uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    Rng rng = makeRngForIndex(seed, i);

    TraceResult r = trace(scene, phase, bounds, drift, rng, origin, direction);

    outRadiance[i]      = r.pathRadiance;
    outScatterEvents[i] = r.scatterEvents;
    outCapped[i]        = r.capped;
    outSteps[i]         = r.trackingSteps;
}

// The phase function at host-chosen cosines.
//
// THE ANALYTIC NEXT-EVENT REFERENCE NEEDS phase(mu), AND THIS IS HOW IT GETS IT
// WITHOUT A SECOND IMPLEMENTATION. Writing the Jendersie-d'Eon fit again in C++ to
// check the Slang one against would be a reference implementation of exactly the kind
// this project does not have and should not invent -- two transcriptions of the same
// paper agreeing proves they were transcribed by the same person.
//
// It is legitimate to use the phase function as an INPUT to the transport identity
// because slang.phase has already established, independently, that it integrates to 1
// and that its sampler matches its own pdf.
[shader("compute")]
[numthreads(64, 1, 1)]
void phaseValueTrial(uint3 tid : SV_DispatchThreadID,
                     uniform PhaseInput phase,
                     uniform StructuredBuffer<float> inCos,
                     uniform RWStructuredBuffer<float> outPhase,
                     uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    outPhase[i] = phaseAt(phase, inCos[i]);
}

// The Jendersie-d'Eon fits, so the host can build a `PhaseInput` for a real droplet
// diameter WITHOUT reimplementing four exponentials in C++.
//
// `traceTrial` takes the derived parameters rather than a diameter, which is the
// opposite of Phase.slang's entry points and is deliberate: the furnace's sharpest
// configuration is ISOTROPIC scattering, and `phaseFromDropletDiameter` cannot produce
// it -- the fit is only valid from 5 to 50 microns and clamps to that, where hgG runs
// 0.971 to 0.998. A test that could only ask for a forward-peaked lobe would never
// exercise the case where the sample weight is exactly 1 and the furnace identity
// becomes exact rather than statistical.
//
// So the host constructs the phase input, and reads the real fits from here when it
// wants a real droplet. Nothing is transcribed twice.
[shader("compute")]
[numthreads(1, 1, 1)]
void phaseParamsTrial(uniform float diameterMicrons,
                      uniform RWStructuredBuffer<float4> outParams)
{
    PhaseInput p = phaseFromDropletDiameter(diameterMicrons, 0);
    outParams[0] = float4(p.hgG, p.draineG, p.draineAlpha, p.draineW);
}
