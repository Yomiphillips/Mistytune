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
#include "AirMapLib.slang"

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
//
// `groundLit` is the clouds' shadow on the ground the ray lands on, 1 where there is none
// or no map to say. Mode 0 has no ground and ignores it. See groundShadow in AirMapLib.
public float3 environmentRadiance(Environment e, float3 origin, float3 dir,
                                  bool includeSunDisc, float groundLit)
{
    if (e.envMode == 1)
    {
        return skyRadiance(e.sky, origin.y, dir, includeSunDisc, groundLit);
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

    // THE AIR BETWEEN THE EYE AND THE FIRST CLOUD, at envMode 1 only. 0 leaves it out,
    // as every render before build 17 did. 1 is aerial perspective: the airlight in front
    // of the first collision, and its transmittance on everything behind it. 2 also puts
    // the clouds' shadows in that air: from the shadow maps when airMapOn says so, else
    // with one shadow ray per camera ray. That is the Cloud Shadows In Air checkbox, and
    // crepuscular rays are what it draws. See airSegment in SkyLib.slang, airShadowLoss in
    // AirMapLib.slang and airShadow below.
    //
    // ZERO IN A ZEROED STRUCT, so every test scene built before this field existed keeps
    // measuring exactly what it measured.
    int aerialMode;

    // ===================================================================
    // THE SECOND LAYER, AND IT IS A SECOND MEDIUM RATHER THAN A SECOND TERM IN THE
    // FIRST ONE'S DENSITY.
    //
    // A cumulus layer and a cirrus deck sit kilometres apart and differ in density by
    // a factor of a hundred. Summed into one medium, the pair would be tracked through
    // one slab at one majorant -- so every ray through the cirrus would pay null
    // collisions at cumulus density, and every ray through the gap would pay them
    // through empty air. Kept apart, each layer is tracked through its own slab at its
    // own majorant, and the SCENE functions below combine them exactly:
    //
    //   shadow       the product of the layers' transmittances -- which is where a
    //                cirrus greying the cumulus under it comes from, rendered rather
    //                than faked, as the spec's layer section demands
    //   free flight  the nearer of the layers' collisions -- exact, because the
    //                survival probabilities of independent media multiply
    //   scattering   in the layer that collided, with THAT layer's phase function
    //                and albedo: ice crystals and water droplets are different stuff
    //
    // ZERO LEAVES IT OUT ENTIRELY, and every scene function then does exactly the
    // arithmetic it did before the layer existed -- which is what keeps a lone cirrus
    // byte-identical to the goldens blessed before this field was added.
    // ===================================================================
    int          layer2On;
    Medium       medium2;
    MajorantGrid grid2;
    float3       albedo2;
    PhaseInput   phase2;

    // THE CLOUDS' SHADOW MAPS, ONE PER LAYER. Nonzero puts the clouds' shadows on the
    // ground the sky's rays land on, always, and in the air at aerialMode 2, where they
    // replace build 17's one shadow ray per camera ray; see AirMapLib.slang. The host
    // builds a map for EVERY layer present or leaves this zero, because an empty map
    // answers 1, which is right only for a layer that is absent.
    //
    // ZERO IN A ZEROED STRUCT, so every scene a test builds by hand keeps the shadow ray.
    int            airMapOn;
    LayerShadowMap airMapIce;   // medium's
    LayerShadowMap airMapCu;    // medium2's

    // DRAFT'S SHADOW HAND-OFF (build 25), in texels of each layer's map: a shadow ray walks
    // exactly until it has crossed this many texels of clear air, then reads the rest from
    // the map. Zero is the exact ray, which is what a zeroed struct and every final render
    // get. Only with the maps (airMapOn). See transmittanceHandoff in AirMapLib.slang.
    float          shadowHandoff;
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
// The scene's layers, combined
// ---------------------------------------------------------------------------

// ===========================================================================
// THE SECOND LAYER'S GRID, FOR A WALK STARTING AT p: THE PROCEDURAL ONE ONLY FOR A WALK
// THAT STARTS OUTSIDE THE LAYER.
//
// A procedural grid pays a bound evaluation for every box it enters, and it earns that
// back only by crossing boxes the bound proves empty in one step. A camera ray does
// exactly that -- it crosses kilometres of clear air between clouds. A walk that starts
// INSIDE the layer is a shadow ray or the next leg of a path already in a cloud: it is
// short, it starts in a box that is not empty, and paying a bound to learn so is pure
// cost.
//
// MEASURED, 640x360 at 32 spp, before this split, grid everywhere against grid nowhere:
//
//     empty layer         0.48 s   vs  0.90 s   -- the grid's case
//     sparse field        6.74 s   vs  2.91 s
//     dense field         9.22 s   vs  3.60 s
//
// Either is unbiased -- ANY majorant at or above the density is -- so this is a cost
// decision with no effect on the converged image.
// ===========================================================================
MajorantGrid gridFor(Medium m, MajorantGrid g, float3 p)
{
    MajorantGrid chosen = g;
    if (g.enabled == 2 && p.y >= m.slabBottom && p.y <= m.slabTop) chosen.enabled = 0;
    return chosen;
}

// How much light survives from p along dir, through every layer.
//
// A PRODUCT OF INDEPENDENT ESTIMATES IS AN ESTIMATE OF THE PRODUCT, and the product is
// the answer: transmittance through a sum of media is exp(-A - B) = exp(-A) exp(-B).
// Skipping the second layer when the first has already gone black costs nothing in
// expectation, and it is where most shadow rays in a thick cumulus end.
//
// EVERY CALLER ASKS TOWARDS THE SUN, which is what lets Draft's hand-off read the shadow
// maps: a map's column is a sun ray. Below the first layer's slab its whole share is one
// read of its map -- a cumulus point under a cirrus deck -- and the second layer's ray
// walks until it has crossed shadowHandoff texels of clear air. See transmittanceHandoff.
float sceneTransmittance(Scene s, StructuredBuffer<float> bounds, StructuredBuffer<float2> drift,
                         inout Rng rng, float3 p, float3 dir, inout int steps)
{
    bool handoff = s.shadowHandoff > 0.0f && s.airMapOn != 0;

    float tr;
    if (handoff && p.y < s.medium.slabBottom)
        tr = layerMapTransmittance(s.airMapIce, p);
    else
        tr = transmittance(s.medium, s.grid, bounds, drift, rng, p, dir, steps);

    if (s.layer2On != 0 && tr > 0.0f)
    {
        MajorantGrid g2 = gridFor(s.medium2, s.grid2, p);
        if (handoff)
        {
            float texel = max(s.airMapCu.smTexel.x, s.airMapCu.smTexel.y);
            tr *= transmittanceHandoff(s.medium2, g2, bounds, drift, s.airMapCu,
                                       s.shadowHandoff * texel, rng, p, dir, steps);
        }
        else
        {
            tr *= transmittance(s.medium2, g2, bounds, drift, rng, p, dir, steps);
        }
    }
    return tr;
}

// Where the path next scatters, in whichever layer it scatters in.
//
// ===========================================================================
// EXACT, NOT A HEURISTIC. The two layers are independent media, so the probability of
// crossing distance t without a collision in either is the product of the two -- which
// is the survival function of the MINIMUM of two independent free-flight distances.
// So: track one layer, then track the other only as far as the first one's collision.
// Whichever collides first is where the path scatters, and it scatters as that layer's
// matter.
//
// THE NEARER SLAB IS TRACKED FIRST, and that is cost, not correctness. Any order gives
// the same distribution; tracking the far cirrus first would walk all of it for a path
// that the near cumulus was about to stop.
// ===========================================================================
bool sceneFreeFlight(Scene s, StructuredBuffer<float> bounds, StructuredBuffer<float2> drift,
                     inout Rng rng, float3 ro, float3 rd,
                     out float3 scatterAt, out int layer, inout int steps)
{
    layer = 0;
    float dist;

    if (s.layer2On == 0)
    {
        return sampleFreeFlight(s.medium, s.grid, bounds, drift, rng, ro, rd,
                                scatterAt, dist, steps);
    }

    float a0, a1, b0, b1;
    bool reachA = slabRange(s.medium,  ro, rd, a0, a1);
    bool reachB = slabRange(s.medium2, ro, rd, b0, b1);
    bool secondFirst = reachB && (!reachA || max(b0, 0.0f) < max(a0, 0.0f));

    float3 pNear, pFar;
    float  dNear, dFar;

    MajorantGrid gridSecond = gridFor(s.medium2, s.grid2, ro);

    if (secondFirst)
    {
        bool hitNear = sampleFreeFlight(s.medium2, gridSecond, bounds, drift, rng, ro, rd,
                                        pNear, dNear, steps);
        bool hitFar  = sampleFreeFlightUpTo(s.medium, s.grid, bounds, drift, rng, ro, rd,
                                            hitNear ? dNear : 1e30f, pFar, dFar, steps);
        if (hitFar)  { scatterAt = pFar;  layer = 0; return true; }
        if (hitNear) { scatterAt = pNear; layer = 1; return true; }
    }
    else
    {
        bool hitNear = sampleFreeFlight(s.medium, s.grid, bounds, drift, rng, ro, rd,
                                        pNear, dNear, steps);
        bool hitFar  = sampleFreeFlightUpTo(s.medium2, gridSecond, bounds, drift, rng, ro, rd,
                                            hitNear ? dNear : 1e30f, pFar, dFar, steps);
        if (hitFar)  { scatterAt = pFar;  layer = 1; return true; }
        if (hitNear) { scatterAt = pNear; layer = 0; return true; }
    }

    scatterAt = float3(0.0f, 0.0f, 0.0f);
    return false;
}

// One layer's walk along the camera segment, advanced to its next tentative collision.
//
// FOUR DRAWS PER STEP, EVERY STEP -- the point, the reservoir's keep test, the roulette,
// and since build 25 the coin that says whether the point is the ray's first REAL
// collision -- and on the layer's own stream, so a moving cumulus cannot shift the
// cirrus's points or the other way round. An empty cell of a procedural grid is crossed
// without a draw, as the trackers cross one.
//
// Returns false when the segment is used up. `budget` is kTrackCap shared across the
// calls for one layer, so the walk has the bound the GPU needs.
bool segmentStep(Medium m, MajorantGrid g, StructuredBuffer<float> bounds,
                 StructuredBuffer<float2> drift, float scale, float tEnd,
                 inout Dda dda, inout float rate, inout float t, inout Rng rng,
                 out float uKeep, out float uLive, out float uHit,
                 inout int budget, inout int steps)
{
    uKeep = 0.0f;
    uLive = 0.0f;
    uHit  = 0.0f;

    while (budget > 0)
    {
        --budget;
        ++steps;

        float cellExit = min(ddaExit(dda), tEnd);

        if (!(rate > 0.0f))
        {
            if (cellExit >= tEnd) return false;
            t = cellExit;
            ddaAdvance(dda);
            rate = gridBound(m, g, bounds, drift, dda.cell, m.majorant) * scale;
            continue;
        }

        float uStep = randFloat(rng);
        uKeep = randFloat(rng);
        uLive = randFloat(rng);
        uHit  = randFloat(rng);

        t -= log(max(1.0f - uStep, 1e-7f)) / rate;

        if (t >= cellExit)
        {
            if (cellExit >= tEnd) return false;
            t = cellExit;
            ddaAdvance(dda);
            rate = gridBound(m, g, bounds, drift, dda.cell, m.majorant) * scale;
            continue;
        }
        return true;
    }
    return false;
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
//
// ===========================================================================
// THE SAME WALK FINDS THE PATH'S FIRST COLLISION (build 25), so the camera ray is walked
// once rather than twice.
//
// These tentative points are a Poisson process at a rate at or above the density -- which
// is all delta tracking asks of its own. Accepting each as REAL with probability
// sigma / rate, the first accepted point is distributed exactly as delta tracking's first
// collision, in either layer: the merged walk is a process at the summed rate, and each of
// its points belongs to a layer in proportion to that layer's rate. So trace() takes the
// collision from here (`hit` = 1) or the ray's escape (`hit` = 0), and tracks nothing.
//
// MEASURED (PROGRESS.md, build 25): the camera ray's free flight was 58 of 278 tracking
// steps per pixel-sample in the default frame and 60 of 158 in a cumulus field -- the
// same stretch of air the sum had just walked.
//
// WHEN THE ROULETTE ENDS THE WALK FIRST, `hit` = 2 and trace() tracks on from `tResume`,
// the last point walked. The roulette looks only at points already walked, so the process
// beyond them is fresh, and the exponential is memoryless. That is a ray past optical
// depth 4.6 with no collision accepted: one in a hundred.
//
// THE PATH'S OWN STREAM IS UNTOUCHED BY THIS. The coin is the walk's fourth draw, every
// step, so as the cloud drifts the first collision moves with the density under fixed
// points, as the sum's estimate does.
// ===========================================================================
float3 cameraSegmentSun(Scene s, PhaseInput ph, StructuredBuffer<float> bounds,
                        StructuredBuffer<float2> drift,
                        inout Rng rng, Rng rng2, float3 ro, float3 rd, inout int steps,
                        out int hit, out float3 hitAt, out int hitLayer, out float tResume)
{
    hit      = 0;
    hitAt    = float3(0.0f, 0.0f, 0.0f);
    hitLayer = 0;
    tResume  = 0.0f;

    const float3 none = float3(0.0f, 0.0f, 0.0f);

    // NEVER BELOW THE MAJORANT. Under it, sigma/rate can exceed 1, the clamp on
    // (1 - w) below turns a negative ratio into zero, and the estimate goes dark with
    // nothing to say so. A scale of 0.5 was measured before this clamp existed; it
    // looked plausible, which is the problem.
    float scale = max(s.neeTentativeScale, 1.0f);

    // ===================================================================
    // ONE WALK PER LAYER, MERGED IN ORDER OF DISTANCE.
    //
    // Each layer's tentative collisions are a Poisson process at that layer's own rate,
    // and the two together are a Poisson process at the summed rate -- the superposition
    // of independent processes. Taking their points in order of t and giving each the
    // weight (sigma of ITS layer / rate of ITS layer) times the ratio-tracked
    // transmittance of every point before it, from EITHER layer, is the same Mecke
    // argument as one layer, and the weights telescope in the same way. So nothing about
    // the estimator changes; it simply sees both media.
    //
    // RATES ARE THE LAYER'S OWN GRID. For the first layer that is the global majorant --
    // its grid is off, and SlangBridge.h records that it is not worth turning on for
    // cirrus -- so a lone cirrus walks exactly the points it always walked. The cumulus
    // layer's grid is procedural, and its walk crosses clear air in one step per cell.
    // ===================================================================
    float tA, endA;
    bool  haveA = slabRange(s.medium, ro, rd, tA, endA);
    tA = max(tA, 0.0f);
    Dda   ddaA    = ddaInit(s.grid, ro, rd, tA);
    float rateA   = gridBound(s.medium, s.grid, bounds, drift, ddaA.cell, s.medium.majorant) * scale;
    int   budgetA = kTrackCap;
    float keepA   = 0.0f, rouletteA = 0.0f, coinA = 0.0f;
    if (haveA)
    {
        haveA = segmentStep(s.medium, s.grid, bounds, drift, scale, endA,
                            ddaA, rateA, tA, rng, keepA, rouletteA, coinA, budgetA, steps);
    }

    // INITIALISED, because the && below skips slabRange when there is no second layer
    // and the two would otherwise be read uninitialised by the lines after it.
    float tB = 0.0f, endB = 0.0f;
    bool  haveB = s.layer2On != 0 && slabRange(s.medium2, ro, rd, tB, endB);
    tB = max(tB, 0.0f);
    MajorantGrid gridB = gridFor(s.medium2, s.grid2, ro);
    Dda   ddaB    = ddaInit(gridB, ro, rd, tB);
    float rateB   = gridBound(s.medium2, gridB, bounds, drift, ddaB.cell, s.medium2.majorant) * scale;
    int   budgetB = kTrackCap;
    float keepB   = 0.0f, rouletteB = 0.0f, coinB = 0.0f;
    if (haveB)
    {
        haveB = segmentStep(s.medium2, gridB, bounds, drift, scale, endB,
                            ddaB, rateB, tB, rng2, keepB, rouletteB, coinB, budgetB, steps);
    }

    float  tr        = 1.0f;
    float  total     = 0.0f;                       // B, the sum of the weights so far
    float  kept      = 0.0f;                       // b_J
    float3 keptAt    = float3(0.0f, 0.0f, 0.0f);   // x_J
    float  keptT     = 0.0f;                       // and its distance, for the air
    int    keptLayer = 0;
    bool   rouletted = false;                      // the walk ended on the roulette

    // BOUNDED BY THE TWO BUDGETS: every pass consumes at least one step of one walk,
    // and each walk stops at kTrackCap. Hitting a cap truncates the sum, which is
    // biased dark, so it must stay unreachable -- which is what the cumulus layer's
    // procedural grid is for.
    while (haveA || haveB)
    {
        bool takeA = haveA && (!haveB || tA <= tB);

        float t     = takeA ? tA : tB;
        float rate  = takeA ? rateA : rateB;
        float uKeep = takeA ? keepA : keepB;
        float uLive = takeA ? rouletteA : rouletteB;
        float uHit  = takeA ? coinA : coinB;

        float3 p     = ro + rd * t;
        tResume      = t;
        float  sigma = takeA ? densityAt(s.medium, drift, p) : densityAt(s.medium2, drift, p);

        // POINTS IN EMPTY AIR COST NOTHING: a zero weight draws nothing further and
        // leaves T alone.
        if (sigma > 0.0f)
        {
            float w = sigma / rate;

            // THE PATH'S FIRST COLLISION: real with probability sigma / rate, as delta
            // tracking accepts one. Only the first acceptance is the path's.
            if (hit == 0 && uHit < w)
            {
                hit      = 1;
                hitAt    = p;
                hitLayer = takeA ? 0 : 1;
            }

            // T_k is the product over the points BEFORE this one, so it is used first
            // and updated after. The other order drops this point's own extinction into
            // its own weight and is biased dark by exactly that.
            float b = tr * w;
            if (b > 0.0f)
            {
                // THE RESERVOIR: after k candidates, each has been kept with
                // probability b_i / B_k, which is what makes B * f(x_J) unbiased for
                // the sum.
                total += b;
                if (uKeep * total < b)
                {
                    kept      = b;
                    keptAt    = p;
                    keptT     = t;
                    keptLayer = takeA ? 0 : 1;
                }
            }

            tr *= max(0.0f, 1.0f - w);

            // Russian roulette once the remaining light is negligible, as
            // transmittance() does. Unbiased: the survivors are doubled, which the
            // reservoir sees as doubled weights from here on.
            if (tr < 0.01f)
            {
                if (uLive > 0.5f) { rouletted = true; break; }
                tr *= 2.0f;
            }
        }

        // FOUR DRAWS PER STEP, EVERY STEP, on the taken layer's own stream -- see
        // segmentStep. Step k's point, keep test and roulette then come from the same
        // numbers on every frame, so as the cloud drifts the points stay where they were
        // and only the density under them changes, which is what keeps this estimate's
        // noise still in screen space.
        if (takeA)
        {
            haveA = segmentStep(s.medium, s.grid, bounds, drift, scale, endA,
                                ddaA, rateA, tA, rng, keepA, rouletteA, coinA, budgetA, steps);
        }
        else
        {
            haveB = segmentStep(s.medium2, gridB, bounds, drift, scale, endB,
                                ddaB, rateB, tB, rng2, keepB, rouletteB, coinB, budgetB, steps);
        }
    }

    // NO COLLISION ACCEPTED, AND THE WALK DID NOT REACH THE END OF THE MEDIUM: the roulette
    // stopped it, or a budget ran out. trace() tracks on from the last point walked.
    if (hit == 0 && (rouletted || budgetA <= 0 || budgetB <= 0)) hit = 2;

    if (!(total > 0.0f) || !(kept > 0.0f)) return none;

    // THROUGH EVERY LAYER, so a cumulus point under a cirrus deck is shadowed by it.
    float shadow = sceneTransmittance(s, bounds, drift, rng,
                                      keptAt + s.sunDir * s.shadowOffset, s.sunDir, steps);

    // The scattering angle is fixed along a straight segment, so the phase depends only
    // on WHICH matter the kept point is. dot(rd, sunDir) for the same reason as in
    // trace(), which reads like a sign error and is not.
    float3 matterAlbedo = s.albedo;
    float  ph0;
    //
    // phaseCamera, NOT phaseAt: this is single scattering along a fixed angle, which is
    // the one place the diffraction lobe a droplet phase function was truncated of can
    // come back without its variance. See phaseCamera in PhaseLib.slang.
    if (keptLayer == 0)
    {
        ph0 = phaseCamera(ph, dot(rd, s.sunDir));
    }
    else
    {
        matterAlbedo = s.albedo2;
        ph0 = phaseCamera(s.phase2, dot(rd, s.sunDir));
    }

    // THE AIR BETWEEN THE EYE AND THE KEPT POINT dims what it sends back. Each point of
    // the sum carries its own distance, so the factor rides with f(x_J) and the reservoir
    // stays unbiased for the sum -- see trace(), which does the same for the path.
    float3 air = float3(1.0f, 1.0f, 1.0f);
    if (s.environment.envMode == 1 && s.aerialMode != 0)
    {
        air = airTransmittance(s.environment.sky, ro.y, rd, keptT);
    }

    // b_J * (B / b_J) = B: the kept point's own weight cancels, which is why `kept` is
    // only checked and never multiplied.
    return total * matterAlbedo * ph0 * shadow * sunIrradianceAt(s, keptAt) * air;
}

// ---------------------------------------------------------------------------
// The clouds' shadows in the air
// ---------------------------------------------------------------------------
//
// ===========================================================================
// THE FALLBACK SINCE BUILD 18. The shadow maps in AirMapLib.slang replace this whenever
// the host builds them; it remains for a sun below one degree, for scenes a test builds
// by hand, and behind the CLI's --air-shadow-rays.
//
// ONE SHADOW RAY FOR THE WHOLE CAMERA SEGMENT, from the point airSegment drew in
// proportion to the airlight. Crepuscular rays are the air in a cloud's shadow going
// dark; the airlight is the integral of sunlit air along the ray, and this puts the
// clouds' transmittance to the sun under that integral.
//
// airIn x V(x) IS UNBIASED IN LUMINANCE, because x was drawn with probability in
// proportion to each step's luminance: E[V(x)] x L is the shadowed luminance exactly. It
// is NOT exact in colour. A shadowed stretch is given the whole segment's average colour
// rather than its own, and the airlight reddens with distance, so a shadow near the eye
// takes out slightly too much red. That is chosen over the exact estimator, airIn - (1 -
// V(x)) x c_i L / l_i, because the exact one goes NEGATIVE in a channel whenever a
// fully shadowed point is drawn from a step whose colour differs from the average, and a
// negative pixel at one sample per pixel is a coloured speck the denoiser cannot remove.
// This form is never negative and has zero variance on a ray no shadow crosses, which is
// most of them.
// ===========================================================================
float airShadow(Scene s, StructuredBuffer<float> bounds, StructuredBuffer<float2> drift,
                inout Rng rng, AirSegment seg, float3 ro, float3 rd, inout int steps)
{
    if (s.aerialMode < 2 || seg.shadowAt < 0.0f) return 1.0f;
    return sceneTransmittance(s, bounds, drift, rng, ro + rd * seg.shadowAt, s.sunDir, steps);
}

// ---------------------------------------------------------------------------
// The path
// ---------------------------------------------------------------------------
//
// Transcribed from proto/index.html's `trace()`, with the atmosphere behind the
// Environment seam and the shadow-ray offset removed.
// ---------------------------------------------------------------------------
// One path, in pieces (build 25)
// ---------------------------------------------------------------------------
//
// ===========================================================================
// THE PATH LOOP, CUT AT ITS BOUNCES, SO THE GPU CAN RUN ONE BOUNCE PER LAUNCH.
//
// MEASURED (PROGRESS.md, build 25): a tracking step along the camera ray cost about 8 ns
// and one in a later bounce about 26 ns. The camera rays of a warp walk side by side;
// by the third bounce its 32 paths are scattered through the cloud, a third of them have
// ended, and the warp runs at the pace of its longest. Mistytune.cu therefore runs
// pathBegin for every sample in one launch, then pathBounce over the paths still alive,
// one launch per bounce, gathering the survivors each time.
//
// trace() IS pathBegin AND pathBounce IN A LOOP, so the CPU reference, the test suites
// and the GPU run the same arithmetic in the same order -- the goldens and slang.cpuParity
// hold the staged GPU path to the bit, as they held the loop it replaced.
//
// FIELD NAMES CARRY `ps`, unique across the kernel, for the reason Environment.envMode
// gives above.
// ===========================================================================
public struct PathState
{
    float3 psRadiance;     // what the path has gathered so far
    float3 psThroughput;
    float3 psOrigin;       // where the next free flight leaves from
    float3 psDir;          // and its direction
    Rng    psRng;          // the path's own stream
    int    psBounce;       // the bounce pathBounce runs next
    int    psAlive;        // nonzero while the path goes on
    int    psEvents;       // real collisions so far
    int    psCapped;       // nonzero: still alive when the budget ran out
    int    psSteps;        // tracking iterations, every walk included
};

// What a path that leaves the medium carries home. `first` is bounce 0, where the camera
// ray meets the sky; see environmentRadiance.
float3 pathEnvironment(Scene s, float3 ro, float3 rd, bool first)
{
    // The path left the medium. Whatever the environment is in that direction
    // is what it carries home -- which makes skylight a transport result
    // rather than an ambient constant.
    //
    // `ro` IS WHERE IT IS LEAVING FROM: the camera at bounce 0, and the last
    // scattering point after that. The sky is asked from there rather than
    // from the ground, which is what makes the skylight on a high cirrus the
    // sky that crystal can actually see.
    //
    // THE GROUND IT LANDS ON IS IN THE CLOUDS' SHADOW where the maps say so, which
    // is the ground in view AND the light the ground throws back up at the cloud
    // bases. Without it the ground under a thick deck was lit as if the sky were
    // clear, and brightened the deck's own underside.
    float groundLit = s.airMapOn != 0
                    ? groundShadow(s.airMapIce, s.airMapCu, ro, rd) : 1.0f;
    return environmentRadiance(s.environment, ro, rd, first, groundLit);
}

// What happens at a real collision at p in `layer`, after the free flight found it: the
// next event towards the sun when `nee`, the scatter, and the roulette. False when the
// roulette ends the path. psBounce is the bounce this collision belongs to.
bool pathScatter(Scene s, PhaseInput ph, StructuredBuffer<float> bounds,
                 StructuredBuffer<float2> drift, inout PathState st, float3 p, int layer,
                 bool nee)
{
    // WHAT THE PATH HIT: ice or water. The phase function and the albedo are the
    // matter's, not the scene's -- a crystal and a droplet scatter differently.
    PhaseInput matterPhase = ph;
    float3     matterAlbedo = s.albedo;
    if (layer != 0)
    {
        matterPhase  = s.phase2;
        matterAlbedo = s.albedo2;
    }

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
    if (nee)
    {
        float  shadow = sceneTransmittance(s, bounds, drift, st.psRng,
                                           p + s.sunDir * s.shadowOffset, s.sunDir,
                                           st.psSteps);
        if (shadow > 0.0f)
        {
            // `rd` is still the INCOMING direction. The scattering angle is between the
            // light's direction of travel (-sunDir) and the camera's (-rd), so its
            // cosine is dot(rd, sunDir) -- which reads like a sign error and is not.
            float ph0 = phaseAt(matterPhase, dot(st.psDir, s.sunDir));

            // `shadow` is the cloud's own transmittance along the shadow ray;
            // sunIrradianceAt is the air's, and says why both are needed.
            st.psRadiance += st.psThroughput * matterAlbedo * ph0 * shadow * sunIrradianceAt(s, p);
        }
    }

    // Scatter, and carry on. THIS LOOP IS THE MULTIPLE SCATTERING -- no
    // approximation and no ambient fudge, just the path continuing until it leaves
    // or runs out of budget.
    float  w;
    float3 newDir = samplePhaseDir(matterPhase, st.psRng, st.psDir, w);
    st.psThroughput *= matterAlbedo * w;

    st.psOrigin = p;
    st.psDir    = newDir;

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
    //
    // A SURVIVAL CAP FOR DRAFT WAS TRIED HERE AND LOST (build 26): unbiased in linear light,
    // but OIDN treats its heavily weighted survivors as outliers, so the denoised preview
    // came out 13 levels dark on a close hero. PROGRESS.md has the numbers.
    // ===================================================================
    if (st.psBounce >= s.rrStartBounce)
    {
        float p2 = clamp(max(st.psThroughput.x, max(st.psThroughput.y, st.psThroughput.z)),
                         0.05f, 1.0f);
        if (randFloat(st.psRng) > p2) return false;
        st.psThroughput /= p2;
    }
    return true;
}

// The camera ray and the path's whole first bounce: the camera segment's sun, the first
// collision, the air in front of it, and the scatter. The path leaves with psBounce 1, or
// ended.
public PathState pathBegin(Scene s, PhaseInput ph, StructuredBuffer<float> bounds,
                           StructuredBuffer<float2> drift, Rng rng, float3 ro, float3 rd)
{
    PathState st;
    st.psRadiance   = float3(0.0f, 0.0f, 0.0f);
    st.psThroughput = float3(1.0f, 1.0f, 1.0f);
    st.psOrigin     = ro;
    st.psDir        = rd;
    st.psRng        = rng;
    st.psBounce     = 0;
    st.psAlive      = 0;
    st.psEvents     = 0;
    st.psCapped     = 0;
    st.psSteps      = 0;

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
    //
    // AND THE SAME WALK DECIDES WHERE THE PATH FIRST SCATTERS (build 25), so bounce 0 below
    // does not walk the camera ray a second time. See cameraSegmentSun.
    bool   sunAlongCamera = s.neeTentativeScale > 0.0f && budget > 0;
    int    cameraHit      = 0;
    float3 cameraHitAt    = float3(0.0f, 0.0f, 0.0f);
    int    cameraHitLayer = 0;
    float  cameraResume   = 0.0f;
    if (sunAlongCamera)
    {
        Rng segmentRng  = splitRng(rng, 0x5e6u);
        Rng segmentRng2 = splitRng(rng, 0x5e7u);   // the second layer's walk
        st.psRadiance += st.psThroughput * cameraSegmentSun(s, ph, bounds, drift, segmentRng,
                                                            segmentRng2, ro, rd, st.psSteps,
                                                            cameraHit, cameraHitAt,
                                                            cameraHitLayer, cameraResume);
    }

    // THE AIR IN FRONT OF THE FIRST EVENT, on its own stream for the reason the segment's
    // sun has one: its shadow ray's draw count depends on the medium.
    bool airOn  = s.environment.envMode == 1 && s.aerialMode != 0;
    Rng  airRng = splitRng(rng, 0xa1eu);

    if (budget <= 0)
    {
        // OUT OF BUDGET, AND THE ENERGY STILL IN `throughput` IS SIMPLY LOST.
        // That is a real bias, it is reported rather than hidden, and the furnace
        // test measures it: the shortfall below L must equal exactly this
        // fraction of paths. When it exceeds that, the loop is leaking somewhere
        // else and the cap is not the explanation.
        st.psCapped = 1;
        return st;
    }

    float3 p;
    int    layer;
    bool   collided;
    if (sunAlongCamera && cameraHit != 2)
    {
        // FROM THE CAMERA SEGMENT'S OWN WALK: its first accepted point, or none.
        collided = cameraHit == 1;
        p        = cameraHitAt;
        layer    = cameraHitLayer;
    }
    else if (sunAlongCamera)
    {
        // THE ROULETTE ENDED THAT WALK FIRST: track on from where it stopped. `ro` stays
        // the eye, because the escape below asks the environment from there.
        collided = sceneFreeFlight(s, bounds, drift, st.psRng, ro + rd * cameraResume, rd,
                                   p, layer, st.psSteps);
    }
    else
    {
        collided = sceneFreeFlight(s, bounds, drift, st.psRng, ro, rd, p, layer, st.psSteps);
    }

    if (!collided)
    {
        float3 env = pathEnvironment(s, ro, rd, true);

        // A CAMERA RAY THAT ESCAPES already has its airlight, in the sky; only the
        // clouds' shadow in it is missing. The segment runs to the top of the air,
        // so its airIn is exactly the airlight inside `env`, and the shadowed part
        // comes off. Never negative: the ground and the disc are what is left.
        //
        // FROM THE MAPS WHEN THERE ARE MAPS, and then the sky's own march is not needed:
        // the loss is taken straight off it, clamped because the two quadratures can
        // disagree by a fraction of a percent where the whole ray is in shadow.
        if (airOn && s.aerialMode >= 2)
        {
            float u1 = randFloat(airRng);
            float u2 = randFloat(airRng);
            if (s.airMapOn != 0)
            {
                env = max(env - airShadowLoss(s.environment.sky, s.airMapIce, s.airMapCu,
                                              ro, rd, 1e30f, u2),
                          float3(0.0f, 0.0f, 0.0f));
            }
            else
            {
                AirSegment seg = airSegment(s.environment.sky, ro.y, rd, 1e30f, u1, u2);
                float v = airShadow(s, bounds, drift, airRng, seg, ro, rd, st.psSteps);
                env = env - seg.airIn * (1.0f - v);
            }
        }

        st.psRadiance += st.psThroughput * env;
        return st;
    }

    ++st.psEvents;

    // THE FIRST EVENT IS BEHIND THE AIR IN FRONT OF IT. Its airlight is added once,
    // and its transmittance goes into the throughput BEFORE the next event below, so
    // the sun at this point and everything the path gathers after it are dimmed by
    // the same air. See airSegment in SkyLib.slang for why this is exact.
    if (airOn)
    {
        float u1 = randFloat(airRng);
        float u2 = randFloat(airRng);
        float dist = length(p - ro);
        AirSegment seg = airSegment(s.environment.sky, ro.y, rd, dist, u1, u2);
        float3 airIn;
        if (s.aerialMode >= 2 && s.airMapOn != 0)
        {
            airIn = max(seg.airIn - airShadowLoss(s.environment.sky, s.airMapIce,
                                                  s.airMapCu, ro, rd, dist, u2),
                        float3(0.0f, 0.0f, 0.0f));
        }
        else
        {
            airIn = seg.airIn * airShadow(s, bounds, drift, airRng, seg, ro, rd,
                                          st.psSteps);
        }
        st.psRadiance += st.psThroughput * airIn;
        st.psThroughput *= seg.airT;
    }

    // SKIPPED AT THE FIRST EVENT WHEN cameraSegmentSun HAS ALREADY COUNTED IT -- see the
    // next event in pathScatter.
    if (pathScatter(s, ph, bounds, drift, st, p, layer, !sunAlongCamera))
    {
        st.psBounce = 1;
        st.psAlive  = 1;
    }
    return st;
}

// One bounce after the first: the free flight from psOrigin, then the escape or the
// collision. Does nothing to a path that has ended.
public void pathBounce(Scene s, PhaseInput ph, StructuredBuffer<float> bounds,
                       StructuredBuffer<float2> drift, inout PathState st)
{
    if (st.psAlive == 0) return;

    if (st.psBounce >= min(s.maxBounces, kBounceCeiling))
    {
        st.psCapped = 1;
        st.psAlive  = 0;
        return;
    }

    float3 p;
    int    layer;
    if (!sceneFreeFlight(s, bounds, drift, st.psRng, st.psOrigin, st.psDir, p, layer,
                         st.psSteps))
    {
        st.psRadiance += st.psThroughput * pathEnvironment(s, st.psOrigin, st.psDir, false);
        st.psAlive = 0;
        return;
    }

    ++st.psEvents;

    if (pathScatter(s, ph, bounds, drift, st, p, layer, true))
        ++st.psBounce;
    else
        st.psAlive = 0;
}

public TraceResult trace(Scene s, PhaseInput ph, StructuredBuffer<float> bounds,
                         StructuredBuffer<float2> drift,
                         inout Rng rng, float3 ro, float3 rd)
{
    // THE WHOLE PATH, as the GPU runs it in pieces: see PathState. kBounceCeiling bounds the
    // loop for the compiler; pathBounce ends the path at the budget long before.
    PathState st = pathBegin(s, ph, bounds, drift, rng, ro, rd);
    for (int i = 1; i < kBounceCeiling && st.psAlive != 0; ++i)
        pathBounce(s, ph, bounds, drift, st);

    // A path still alive here met the ceiling itself, which the budget is clamped to.
    if (st.psAlive != 0) st.psCapped = 1;

    rng = st.psRng;

    TraceResult r;
    r.pathRadiance  = st.psRadiance;
    r.scatterEvents = st.psEvents;
    r.capped        = st.psCapped;
    r.trackingSteps = st.psSteps;
    return r;
}
