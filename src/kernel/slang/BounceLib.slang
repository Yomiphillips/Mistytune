// The bounce loop: multiple scattering with next-event estimation -- the LIBRARY half.
//
// Split out of Bounce.slang so the renderer can include the path tracer without also
// inheriting its three test kernels. Bounce.slang is now those kernels and nothing
// else; the furnace test below still measures exactly what it always did.
//
// ===========================================================================
// THIS IS WHERE THE PIECES BECOME A RENDERER, AND ITS TEST IS A FURNACE.
//
// Everything so far was checkable on its own. A phase function integrates to one. A
// transmittance estimator matches exp(-sigma d). A free-flight distance is
// exponentially distributed. Each was provable without the others.
//
// The bounce loop has no such local identity: it is the thing that COMPOSES them, and
// the way it fails is by losing or inventing energy a little at a time, over a path
// that may have thirty events. A 3% error per bounce is invisible in a single-scatter
// check and is a factor of two after twenty-five.
//
// THE FURNACE TEST IS THE IDENTITY THAT COMPOSITION HAS.
//
// Put a CONSERVATIVE medium -- single-scatter albedo exactly 1, so scattering moves
// light without removing any -- inside a closed environment of uniform radiance L.
// Then every point, in every direction, must see exactly L. It cannot matter what the
// phase function is, how dense the medium is, how many times a path scatters, or what
// the majorant is: a photon that is never absorbed and never created must arrive with
// the energy it set out with.
//
// So the renderer must return L. Not approximately as a matter of taste -- the
// estimator is unbiased, so the MEAN over many paths converges on L, and any
// systematic shortfall is energy the loop is losing.
//
//   * a phase sampler whose weight does not average to 1 -> drifts with bounce count
//   * Russian roulette that forgets to divide by the survival probability -> dark
//   * a throughput updated in the wrong order relative to the estimate -> off by one
//     bounce's worth of albedo
//   * a path terminated without accounting for what it would have collected -> dark
//
// WHAT THE FURNACE CANNOT SEE, WHICH IS WHY slang.transport STILL EXISTS. In a
// furnace every escape returns L, so a path that escapes TOO EARLY -- the exact
// failure a loose majorant and a too-small iteration cap produce -- returns precisely
// the right answer for the wrong reason. The furnace is structurally blind to it.
// That is why the majorant sweep here lives on the next-event test, where a premature
// escape means a scattering event that never happened and the answer moves.
//
// The two tiers are complementary, not redundant, and neither subsumes the other.
// ===========================================================================

#include "TransportLib.slang"
#include "PhaseLib.slang"
#include "SkyLib.slang"

// ---------------------------------------------------------------------------
// The environment
// ---------------------------------------------------------------------------
//
// A SEAM, LIKE `Medium` BESIDE IT. Mode 0 is a uniform radiance from every direction,
// which is what the furnace test needs and is not a sky. The Bruneton atmosphere --
// Sky.slang's `skyRadiance`, plus the aerial perspective and the sun's own
// transmittance -- lands behind `mode` when the atmosphere is merged into this
// translation unit.
public struct Environment
{
    float3   uniformRadiance;   // mode 0: the incident radiance, from every direction
    SkyInput sky;        // mode 1: the atmosphere

    // NAMED envMode AND NOT mode, AND THAT IS A REAL HAZARD RATHER THAN A STYLE NOTE.
    //
    // slangc disambiguates identifiers with an index assigned across the ENTIRE
    // translation unit: the first `mode` it emits becomes `mode_0`, the second
    // `mode_1`. `Medium` already has a `mode`, so this one used to generate as
    // `mode_1` -- and which struct got which suffix depended on nothing more than
    // the order slangc happened to emit them in.
    //
    // A COMPILE ERROR IS THE LUCKY CASE. Two int fields swapping suffixes still
    // compiles and reads the wrong memory, silently, in generated code nobody reads.
    // PROGRESS.md records this happening for real: an unrelated #include renamed a
    // field in a struct nobody had touched. Host-visible field names are kept unique
    // across the whole kernel so the collision cannot arise.
    int      envMode;    // 0 = uniform, 1 = the Bruneton-style sky
};

// ---------------------------------------------------------------------------
// `includeSunDisc` IS INERT TODAY AND IS HERE ANYWAY. READ THIS BEFORE REMOVING IT.
// ---------------------------------------------------------------------------
//
// The sun reaches a scattering event by next-event estimation, and it reaches the
// camera through whatever the environment says is in that direction. The moment the
// environment contains a SUN DISC, those are two paths to the same photon and the sun
// is counted twice -- and not merely twice as bright, which would be noticed.
//
// The disc subtends about 6.8e-5 steradians. A path that happens to scatter into it
// comes home carrying something like 3e5 while its neighbours carry 1, so the image
// fills with single white pixels that no amount of averaging removes. That reads as a
// firefly problem and sends the reader looking at the phase function, which is where
// the prototype's comments record the same trap.
//
// A camera ray that reached the sky WITHOUT ever scattering had no next-event
// estimate, so for that one the disc is the correct and only answer. Hence the
// parameter, and hence `bounce == 0` at the call site.
//
// Mode 0 has no disc to include, so the argument does nothing there -- which is what
// the furnace test needs and is why the flag was wired up before it had a sun to
// suppress. Mode 1 is the sky, and there it is doing the job above.
// TAKES THE POSITION THE PATH IS LEAVING FROM, not only the direction it leaves in.
//
// MODE 0 IGNORES IT, and must: a uniform environment is the same radiance from
// everywhere, which is the whole premise of the furnace test.
//
// MODE 1 NEEDS IT. The sky a path sees depends on how much air is between it and
// space, and a path that scattered inside a cirrus at 9 km has nine kilometres less
// of it than the camera does. Passing only a direction meant every escaped path was
// answered with the sky as seen from the ground -- see Shading.h's skyRadiance, which
// carries the argument. proto/index.html passes `ro` here and always did.
//
// ONLY `.y` REACHES THE SKY, because the atmosphere is spherically symmetric and the
// march is built around altitude. The full position is taken rather than a float so
// the call site cannot quietly pass the wrong component.
public float3 environmentRadiance(Environment e, float3 origin, float3 dir,
                                  bool includeSunDisc)
{
    if (e.envMode == 1)
    {
        return skyRadiance(e.sky, origin.y, dir, includeSunDisc);
    }

    return e.uniformRadiance;
}

// ---------------------------------------------------------------------------
// The scene
// ---------------------------------------------------------------------------

public struct Scene
{
    Medium       medium;
    MajorantGrid grid;      // `enabled = 0` falls back to Medium.majorant everywhere
    Environment  environment;

    float3 albedo;          // single-scatter albedo, per channel. 1 = conservative
    float3 sunIrradiance;   // on a surface facing the sun. A DELTA light: no disc
    float3 sunDir;          // normalised, pointing towards the sun

    // ===================================================================
    // THIS MUST BE ZERO, AND IT IS A PARAMETER SO THAT THE TEST CAN PROVE IT.
    //
    // The prototype offsets the shadow ray's origin by one metre along the sun
    // direction -- `cloudTransmittance(scatterPoint + uSunDir * 1.0, uSunDir)` -- which
    // is the reflex every surface ray tracer teaches, because a ray leaving a triangle
    // will otherwise hit the triangle it left.
    //
    // THERE IS NO SURFACE HERE. A null-collision medium has nothing to
    // self-intersect: the shadow ray starts at a point in a volume and the estimator
    // integrates from zero. The offset buys nothing at all, and it SKIPS ONE METRE OF
    // MEDIUM, so every shadow comes back too bright by exp(sigma * offset).
    //
    // That is a systematic brightening, not noise, and its size is the density: about
    // 0.25% in the thin cirrus this file is tested against, and about 5% at the
    // sigma of a cumulus. It applies at every scattering event of every path.
    //
    // slang.bounce sweeps it and reports the bias rather than asserting it away.
    // ===================================================================
    float shadowOffset;     // metres. Zero. See above

    int maxBounces;         // scattering events allowed before the path is abandoned
    int rrStartBounce;      // Russian roulette begins at this event. 4 in the prototype
};

// A STRUCTURAL CEILING, SEPARATE FROM THE PARAMETER. A GPU loop wants a bound the
// compiler can see, and an unbounded one reached through a bad parameter is a driver
// timeout rather than a slow frame -- which PLAN.md names as a project-killer.
//
// The budget is clamped to it so that `bounce >= budget` is ALWAYS what ends the loop.
// Letting the `for` condition terminate instead would exit without setting `capped`,
// and the furnace test's whole diagnostic rests on `capped` being the truth.
public static const int kBounceCeiling = 256;

public struct TraceResult
{
    float3 pathRadiance;
    int    scatterEvents;   // real collisions, not counting null ones
    int    capped;          // nonzero: the path was still alive when the budget ran out
    int    trackingSteps;           // tracking iterations, summed over free flight and shadows
};

// ---------------------------------------------------------------------------
// The path
// ---------------------------------------------------------------------------
//
// Transcribed from proto/index.html's `trace()`, with the atmosphere behind the
// Environment seam and the shadow-ray offset removed.
public TraceResult trace(Scene s, PhaseInput ph, StructuredBuffer<float> bounds,
                         StructuredBuffer<float2> drift,
                         inout Rng rng, float3 ro, float3 rd)
{
    TraceResult r;
    r.pathRadiance      = float3(0.0f, 0.0f, 0.0f);
    r.scatterEvents = 0;
    r.capped        = 0;
    r.trackingSteps         = 0;

    float3 throughput = float3(1.0f, 1.0f, 1.0f);

    int budget = min(s.maxBounces, kBounceCeiling);

    for (int bounce = 0; bounce < kBounceCeiling; ++bounce)
    {
        if (bounce >= budget)
        {
            // OUT OF BUDGET, AND THE ENERGY STILL IN `throughput` IS SIMPLY LOST.
            // That is a real bias, it is reported rather than hidden, and the furnace
            // test measures it: the shortfall below L must equal exactly this
            // fraction of paths. When it exceeds that, the loop is leaking somewhere
            // else and the cap is not the explanation.
            r.capped = 1;
            break;
        }

        float3 p;
        float  dist;
        if (!sampleFreeFlight(s.medium, s.grid, bounds, drift, rng, ro, rd, p, dist, r.trackingSteps))
        {
            // The path left the medium. Whatever the environment is in that direction
            // is what it carries home -- which makes skylight a transport result
            // rather than an ambient constant.
            //
            // `ro` IS WHERE IT IS LEAVING FROM: the camera at bounce 0, and the last
            // scattering point after that. The sky is asked from there rather than
            // from the ground, which is what makes the skylight on a high cirrus the
            // sky that crystal can actually see.
            r.pathRadiance += throughput * environmentRadiance(s.environment, ro, rd, bounce == 0);
            break;
        }

        ++r.scatterEvents;

        // NEXT-EVENT ESTIMATION towards the sun. Without it a thin cirrus takes
        // thousands of samples to find the sun at all, because the phase function is
        // sharply forward and the sun is half a degree wide.
        //
        // THE SHADOW RAY IS CAST EVEN WHEN THE SUN IS BLACK, deliberately. Skipping it
        // would make the number of random draws depend on the sun's brightness, so two
        // renders differing only in exposure would consume different RNG streams and
        // decorrelate -- and PLAN.md's determinism tripwire is that the same inputs
        // give the same bits. It is a real cost and the right place to pay it is a
        // host-side decision not to trace a black sun at all.
        float  shadow = transmittance(s.medium, s.grid, bounds, drift, rng,
                                      p + s.sunDir * s.shadowOffset, s.sunDir, r.trackingSteps);
        if (shadow > 0.0f)
        {
            // `rd` is still the INCOMING direction. The scattering angle is between the
            // light's direction of travel (-sunDir) and the camera's (-rd), so its
            // cosine is dot(rd, sunDir) -- which reads like a sign error and is not.
            float ph0 = phaseAt(ph, dot(rd, s.sunDir));

            // THE SUN IS ATTENUATED BY THE AIR BETWEEN THE CRYSTAL AND SPACE, not
            // only by the cloud. `shadow` is the cloud's own transmittance along the
            // shadow ray; this is the atmosphere's, and leaving it out lights a
            // backlit cirrus with a white sun while the sky behind it goes orange.
            //
            // MODE 0 IS UNTOUCHED AND MUST STAY SO. slang.bounce's furnace and its
            // analytic next-event reference both run in a uniform environment where
            // `sunIrradiance` is the whole answer by construction; multiplying an
            // atmospheric term into that case would change what those tests measure.
            //
            // MODE 1 IGNORES `s.sunIrradiance` ENTIRELY AND TAKES THE NUMBER FROM THE
            // SKY, so the sun's brightness has exactly one home. A host that computed
            // it separately would be free to disagree with the sky behind the cloud,
            // and the symptom of that is a layer that sits at the wrong exposure for
            // a reason no parameter explains.
            float3 sunE = s.sunIrradiance;
            if (s.environment.envMode == 1)
            {
                sunE = sunIrradianceTop(s.environment.sky)
                     * sunTransmittanceAt(s.environment.sky, p);
            }

            r.pathRadiance += throughput * s.albedo * ph0 * shadow * sunE;
        }

        // Scatter, and carry on. THIS LOOP IS THE MULTIPLE SCATTERING -- no
        // approximation and no ambient fudge, just the path continuing until it leaves
        // or runs out of budget.
        float  w;
        float3 newDir = samplePhaseDir(ph, rng, rd, w);
        throughput *= s.albedo * w;

        ro = p;
        rd = newDir;

        // ===================================================================
        // RUSSIAN ROULETTE, AND THE DIVISION IS THE WHOLE THING.
        //
        // Kill the path with probability 1-p and multiply the survivors by 1/p: the
        // expectation is unchanged, so the estimator stays unbiased while the cheap
        // early bounces are never at risk.
        //
        // Taking p from the throughput's largest channel makes this self-tuning. A
        // conservative medium has throughput 1, so p is 1 and nothing is ever killed
        // -- which is what the furnace test relies on, and why the furnace measures
        // the bounce cap in isolation rather than the cap plus roulette.
        //
        // The floor of 0.05 stops a nearly-black path from being kept alive by a
        // vanishing probability and then multiplied by twenty.
        //
        // slang.bounce checks this the only way it can be checked: roulette is a FREE
        // PARAMETER, so turning it off must not move the answer.
        // ===================================================================
        if (bounce >= s.rrStartBounce)
        {
            float p2 = clamp(max(throughput.x, max(throughput.y, throughput.z)), 0.05f, 1.0f);
            if (randFloat(rng) > p2) break;
            throughput /= p2;
        }
    }

    return r;
}
