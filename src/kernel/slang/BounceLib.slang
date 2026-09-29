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

    // THE SUN ALONG THE CAMERA RAY, AS A SUM RATHER THAN A COIN TOSS. Zero is plain
    // delta tracking: one next event, at the first real collision, if there is one.
    // Above zero, cameraSegmentSun() replaces that single estimate with a continuous
    // one over tentative collisions along the camera segment, drawn at this multiple
    // of the majorant -- 1 at the least, whatever is asked, because below it the
    // estimate is biased. Same expectation, and slang.bounce holds it to the same
    // closed form. See cameraSegmentSun for why, and PROGRESS.md for what it buys.
    float neeTentativeScale;
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

// The sun's irradiance arriving at a point in the medium, before the cloud's own
// shadow. ONE HOME FOR THE NUMBER, shared by both next-event estimators below.
//
// MODE 0 IS UNTOUCHED AND MUST STAY SO. slang.bounce's furnace and its analytic
// next-event reference both run in a uniform environment where `sunIrradiance` is
// the whole answer by construction; multiplying an atmospheric term into that case
// would change what those tests measure.
//
// MODE 1 IGNORES `s.sunIrradiance` ENTIRELY AND TAKES THE NUMBER FROM THE SKY, so
// the sun's brightness has exactly one home. A host that computed it separately
// would be free to disagree with the sky behind the cloud, and the symptom of that is
// a layer that sits at the wrong exposure for a reason no parameter explains.
//
// THE SUN IS ATTENUATED BY THE AIR BETWEEN THE CRYSTAL AND SPACE, not only by the
// cloud. Leaving that out lights a backlit cirrus with a white sun while the sky
// behind it goes orange.
float3 sunIrradianceAt(Scene s, float3 p)
{
    if (s.environment.envMode == 1)
    {
        return sunIrradianceTop(s.environment.sky) * sunTransmittanceAt(s.environment.sky, p);
    }
    return s.sunIrradiance;
}

// ---------------------------------------------------------------------------
// The sun along the camera ray, as a sum rather than a coin toss
// ---------------------------------------------------------------------------
//
// ===========================================================================
// WHY THIS EXISTS: A 4 spp CIRRUS IS SPARSE BRIGHT DOTS, AND THE DOTS ARE THE
// ESTIMATOR.
//
// Under delta tracking the sun reaches a camera ray only if that ray has a real
// collision -- a yes-or-no with probability 1 - T, which in thin cirrus is small. So
// most rays bring back the sky and a few bring back the forward-peaked sun, and the
// pixel is whichever happened. PROGRESS.md (2026-09-29) measured that this is what
// the denoiser mistakes for detail, and that blue-noise sampling cannot reach it:
// the yes-or-no depends on ten or more draws at once.
//
// THIS REPLACES THE YES-OR-NO WITH A SUM. Tentative collisions x_k are drawn along
// the whole camera segment as a Poisson process of rate `mu` (a multiple of the
// majorant), and each contributes
//
//     (sigma(x_k) / mu) * T_k * albedo * phase * shadow(x_k) * sun(x_k)
//
// where T_k is the RATIO-TRACKED transmittance over the points before it. By the
// Mecke formula -- the points before x_k are themselves a Poisson process of rate mu,
// independent of x_k -- the expectation of that sum is
//
//     integral of mu * (sigma/mu) * exp(-integral of sigma) * f  dt
//   = integral of sigma(t) T(t) f(t) dt
//
// which is exactly what delta tracking's one next event estimates. Unbiased, for ANY
// rate at or above the density; slang.bounce holds it to the same closed form and the
// same majorant sweep as the estimator it replaces.
//
// WHAT CHANGES IS THE VARIANCE. Every ray that passes through ice now brings back
// some sun in proportion to how much ice it passed, instead of all or nothing. A
// higher rate samples the density more finely -- more points, smaller weights.
//
// ONE SHADOW RAY, NOT ONE PER POINT, AND THAT WAS MEASURED BEFORE IT WAS WRITTEN.
// The literal sum casts a shadow ray from every point that lands in ice, and cirrus
// is ice almost everywhere inside its slab: 6x the frame time at scale 1, 15x at 4.
// But the weights b_k = T_k * sigma_k / mu TELESCOPE -- T_{k+1} = T_k (1 - sigma_k/mu),
// so b_k = T_k - T_{k+1} and their sum B is the ratio-tracked estimate of 1 - T, the
// probability that the ray scatters at all. So the sum is resampled: one point J is
// kept with probability b_J / B by a streaming reservoir, and the estimate is
//
//     B * albedo * phase * sun(x_J) * shadow(x_J)
//
// whose expectation over J is the sum above -- unbiased, with one shadow ray. It
// reads as what it is: HOW LIKELY the ray is to scatter, estimated continuously, times
// the sun seen from WHERE it would scatter. Delta tracking estimates the first factor
// with a coin toss, and that coin toss was the dots.
//
// THE SELECTION WEIGHTS CARRY NO SUN, deliberately, so the number of draws depends
// only on the field and the ray, never on the sun's brightness -- see the note on
// shadow rays in trace(). The sun's slow change along the segment rides in sun(x_J).
//
// ONLY THE CAMERA SEGMENT, AND ONLY THE SUN. The path still scatters where delta
// tracking says it does and carries on from there; its later next events and its
// escapes are untouched. Those are the rare, dim part of a thin cirrus -- the dots
// were the first event.
//
// POINTS IN EMPTY AIR COST NOTHING: a zero weight draws nothing and leaves T alone.
// ===========================================================================
float3 cameraSegmentSun(Scene s, PhaseInput ph, StructuredBuffer<float> bounds,
                        StructuredBuffer<float2> drift,
                        inout Rng rng, float3 ro, float3 rd, inout int steps)
{
    const float3 none = float3(0.0f, 0.0f, 0.0f);

    float t0, t1;
    if (!slabRange(s.medium, ro, rd, t0, t1)) return none;
    t0 = max(t0, 0.0f);

    // THE GLOBAL MAJORANT, EVEN WITH THE GRID ON. Any rate at or above the density is
    // unbiased here, so the grid would only be a cost optimisation -- and SlangBridge.h
    // records that it is not one for cirrus.
    //
    // NEVER BELOW THE MAJORANT. Under it, sigma/rate can exceed 1, the clamp on
    // (1 - w) below turns a negative ratio into zero, and the estimate goes dark with
    // nothing to say so. A scale of 0.5 was measured before this clamp existed; it
    // looked plausible, which is the problem.
    float rate = s.medium.majorant * max(s.neeTentativeScale, 1.0f);
    if (!(rate > 0.0f)) return none;

    // The scattering angle is fixed along a straight segment, so the phase is too.
    // dot(rd, sunDir) for the same reason as in trace(), which reads like a sign
    // error and is not.
    float ph0 = phaseAt(ph, dot(rd, s.sunDir));

    float  tr      = 1.0f;
    float  t       = t0;
    float  total   = 0.0f;                       // B, the sum of the weights so far
    float  kept    = 0.0f;                       // b_J
    float3 keptAt  = float3(0.0f, 0.0f, 0.0f);   // x_J

    // kTrackCap FOR THE SAME REASON AS EVERY OTHER WALK: a bound the GPU can see.
    // Hitting it truncates the sum, which is biased dark, so it must stay unreachable
    // -- at the shipping majorant a camera ray takes about five steps per unit scale.
    for (int i = 0; i < kTrackCap; ++i)
    {
        ++steps;

        // THREE DRAWS PER STEP, EVERY STEP, whether or not they are used. Step k's
        // point, keep test and roulette then come from the same numbers on every
        // frame, so as the cloud drifts the points stay where they were and only the
        // density under them changes -- which is what keeps this estimate's noise
        // still in screen space. Drawing only when needed would shift every later
        // draw whenever one point crossed the edge of a streak.
        float uStep = randFloat(rng);
        float uKeep = randFloat(rng);
        float uLive = randFloat(rng);

        t -= log(max(1.0f - uStep, 1e-7f)) / rate;
        if (t >= t1) break;

        float3 p     = ro + rd * t;
        float  sigma = densityAt(s.medium, drift, p);
        if (sigma <= 0.0f) continue;

        float w = sigma / rate;

        // T_k is the product over the points BEFORE this one, so it is used first and
        // updated after. The other order drops this point's own extinction into its
        // own weight and is biased dark by exactly that.
        float b = tr * w;
        if (b > 0.0f)
        {
            // THE RESERVOIR: after k candidates, each has been kept with probability
            // b_i / B_k, which is what makes B * f(x_J) unbiased for the sum.
            total += b;
            if (uKeep * total < b)
            {
                kept   = b;
                keptAt = p;
            }
        }

        tr *= max(0.0f, 1.0f - w);

        // Russian roulette once the remaining light is negligible, as transmittance()
        // does. Unbiased: the survivors are doubled, which the reservoir sees as
        // doubled weights from here on.
        if (tr < 0.01f)
        {
            if (uLive > 0.5f) break;
            tr *= 2.0f;
        }
    }

    if (!(total > 0.0f) || !(kept > 0.0f)) return none;

    float shadow = transmittance(s.medium, s.grid, bounds, drift, rng,
                                 keptAt + s.sunDir * s.shadowOffset, s.sunDir, steps);

    // b_J * (B / b_J) = B: the kept point's own weight cancels, which is why `kept` is
    // only checked and never multiplied.
    return total * s.albedo * ph0 * shadow * sunIrradianceAt(s, keptAt);
}

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

    // THE CAMERA SEGMENT'S SUN, AS A SUM, when asked for -- and then the first
    // collision's own next event below is skipped, because this replaces it. Taken
    // before the free flight and whether or not the path ever scatters: it is an
    // estimate of the whole segment. Only while the budget allows a first event at
    // all, which is when delta tracking would have made one.
    //
    // ON ITS OWN STREAM, split from the path's without advancing it. Its draw count
    // depends on the medium, and on the path's own stream that would hand every later
    // event fresh numbers whenever the cloud moved -- see splitRng. The path below
    // therefore draws exactly what it drew before this estimator existed, less the
    // first event's shadow ray.
    bool sunAlongCamera = s.neeTentativeScale > 0.0f && budget > 0;
    if (sunAlongCamera)
    {
        Rng segmentRng = splitRng(rng, 0x5e6u);
        r.pathRadiance += throughput * cameraSegmentSun(s, ph, bounds, drift, segmentRng,
                                                        ro, rd, r.trackingSteps);
    }

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
        //
        // SKIPPED AT THE FIRST EVENT WHEN cameraSegmentSun HAS ALREADY COUNTED IT. That
        // is a Scene setting, fixed for the frame, so the draw count still does not
        // depend on the sun.
        if (!(bounce == 0 && sunAlongCamera))
        {
            float  shadow = transmittance(s.medium, s.grid, bounds, drift, rng,
                                          p + s.sunDir * s.shadowOffset, s.sunDir, r.trackingSteps);
            if (shadow > 0.0f)
            {
                // `rd` is still the INCOMING direction. The scattering angle is between the
                // light's direction of travel (-sunDir) and the camera's (-rd), so its
                // cosine is dot(rd, sunDir) -- which reads like a sign error and is not.
                float ph0 = phaseAt(ph, dot(rd, s.sunDir));

                // `shadow` is the cloud's own transmittance along the shadow ray;
                // sunIrradianceAt is the air's, and says why both are needed.
                r.pathRadiance += throughput * s.albedo * ph0 * shadow * sunIrradianceAt(s, p);
            }
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
