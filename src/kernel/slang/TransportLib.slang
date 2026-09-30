// Null-collision transport: free-flight sampling and ratio-tracked transmittance.
//
// ===========================================================================
// THE HEART OF THE RENDERER, AND THE PART WITH THE SHARPEST TEST.
//
// Delta tracking answers "where does this ray next scatter?" and ratio tracking
// answers "how much light survives along it?" -- in a medium whose density has no
// closed-form integral. Both work by adding fictitious "null" matter until the total
// is a constant MAJORANT, for which the free-flight distance does have a closed form,
// and then rejecting the fictitious collisions.
//
// WHAT MAKES IT TESTABLE WITHOUT A REFERENCE. The method's whole promise is that the
// majorant is a free parameter: any upper bound on the density gives the SAME answer,
// only at a different cost. So three identities fall out, and none of them needs a
// second implementation to check against:
//
//   1. In a constant-density slab, transmittance must equal exp(-sigma * d) exactly.
//   2. The free-flight distance must be exponentially distributed with rate sigma.
//   3. NEITHER ANSWER MAY DEPEND ON THE MAJORANT.
//
// The third is the one that catches real bugs. Almost every way of getting null
// collisions wrong -- multiplying by the wrong ratio, forgetting that a rejected
// collision still advances t, terminating on the wrong side of a comparison -- leaves
// the estimator biased in a way that MOVES WITH THE MAJORANT while still looking like
// a plausible cloud at any single setting.
// ===========================================================================
//
// ---------------------------------------------------------------------------
// WHY THIS IS A `Lib` FILE AND Transport.slang IS NOT
// ---------------------------------------------------------------------------
//
// Slang 2026.18.3 has no `[export]`, so code is shared by #include and every
// generated .cu carries its own copy. That is tolerable. What is NOT tolerable is
// that an #include also drags in the including file's ENTRY POINTS: Phase.slang and
// Transport.slang both declared an `rngTrial` kernel, so a file including both got
// two definitions of it in one translation unit and would not compile.
//
// So the rule, from here on: `XLib.slang` holds functions and nothing else, and
// `X.slang` is a thin harness that includes it and adds the entry points its test
// needs. A file that wants to USE the transport includes TransportLib.slang and gets
// no test kernels with it.
//
// That is also the shape PLAN.md's "one kernel source" requires -- the production
// kernel will include several of these Libs and declare exactly one entry point, and
// it must not inherit five test kernels on the way.

#ifndef MISTYTUNE_TRANSPORT_LIB_SLANG
#define MISTYTUNE_TRANSPORT_LIB_SLANG

// ---------------------------------------------------------------------------
// Random numbers -- the same PCG stream Phase.slang uses
// ---------------------------------------------------------------------------
//
// IT USED TO BE STATED HERE, duplicated from Phase.slang on purpose, because Slang
// 2026.18.3 has no `[export]` and a shared definition has to be pulled in by
// #include regardless. Two copies pinned by a test was cheaper than pretending a
// module system exists.
//
// THE BOUNCE LOOP ENDED THAT, by needing both this file and Phase.slang in one
// translation unit -- where two copies is not duplication but a redefinition error.
// See Rng.slang.
//
// IF THE GENERATORS EVER DISAGREE, EVERY DETERMINISM GUARANTEE IN THE PROJECT IS
// GONE, so slang.transport still pins Transport.slang's `rngTrial` against
// Phase.slang's. The check now catches a different failure and is still worth its
// runtime: a generated artifact that kept a stale local copy instead of the include.
#include "Rng.slang"

// ===========================================================================
// THE TRANSPORT KNOWS ABOUT THE ICE GENERATOR, AND THAT IS A CHOICE RATHER THAN AN
// ACCIDENT. THE ALTERNATIVE IS NAMED HERE SO IT CAN BE TAKEN LATER.
//
// Layering says a transport should not know what kind of cloud it is marching through:
// it wants a density function, not a generator. The clean way to express that in Slang
// is a generic over an interface, specialised at compile time -- which this language
// does support, and which would cost nothing at runtime.
//
// It is not done, for two reasons. PLAN.md's whole premise is ONE KERNEL SOURCE
// compiled per target, so every density this renderer will ever evaluate ends up in the
// same translation unit regardless -- the include is not hiding a dependency that
// generics would remove, it is stating one that already exists. And `mode` is already
// the seam: a second generator lands as `mode 3` beside this one, with no signature
// anywhere else changing.
//
// THE POINT AT WHICH THIS BECOMES WRONG is a second CONSUMER of the transport that
// wants a different density set -- an OFX host, or a bake tool. That is when the
// generic earns its complexity, and it is a mechanical change when it comes.
// ===========================================================================
#include "GeneratorLib.slang"

// The second generator, behind `mode 3` -- the seam the note above left for it. Cumulus
// is where the majorant grid finally pays, which is why this file also grows a
// procedural bound below.
#include "ConvectionLib.slang"

// ---------------------------------------------------------------------------
// The medium
// ---------------------------------------------------------------------------
//
// A SEAM, NOT A FINISHED INTERFACE. Today the only density this knows how to
// evaluate is a constant, which is exactly what the tests need and is not a cloud.
// The ice generator (cellField / driftAt / iceDensity) lands behind `mode` next, and
// the tests written against the constant keep working -- because the identities above
// are properties of the METHOD, not of the density.
public struct Medium
{
    float slabTop;      // metres, the top of the deck
    float slabBottom;   // metres
    float majorant;     // a GLOBAL upper bound on density anywhere in the slab
    float density;      // the constant background

    // mode 1 only: a sharp Gaussian core on top of the background.
    float3 coreCentre;
    float  coreRadius;  // metres, the 1/e-ish scale
    float  coreDensity; // peak density ABOVE the background

    // mode 2 only: the ice / fallstreak generator. The drift table travels beside it as
    // a buffer, because it is a 33-knot prefix integral the CPU builds once per
    // parameter change rather than something the kernel can recompute per sample.
    GeneratorInput gen;

    // mode 3 only: cellular convection. No table travels beside it -- every input is
    // a scalar, and the cells are a hash of the lattice.
    ConvectionInput conv;

    int   mode;         // 0 = constant, 1 = background + core, 2 = ice, 3 = convection

    // ===================================================================
    // WHERE THE MEDIUM IS, ACROSS: a box in x and z, and a fade around the observer.
    //
    // THE BOX is what makes a lone hero cloud cheap. Without it a ray still walks the
    // whole infinite slab at the majorant's rate, paying null collisions through
    // kilometres of air that the density then says are empty. With it, a ray that
    // misses the hero's box never enters the medium at all. clipOn 0 is unbounded.
    //
    // THE FADE is Render Distance. Density falls from full at fadeRadius - fadeWidth to
    // nothing at fadeRadius, measured across from fadeAt (the observer), and the box is
    // clipped to that radius too. A grazing ray through a cumulus layer otherwise
    // crosses tens of kilometres of cloud, which is most of what a horizon view costs.
    // It is a factor of at most one, so every majorant stays a majorant. fadeRadius <= 0
    // is off.
    //
    // THE DENSITY IS ZERO OUTSIDE BOTH, in densityAt, so the range below is an exact
    // statement about where the medium is rather than an optimisation that hopes.
    // ===================================================================
    int    clipOn;      // 0 = no box across: zero-initialised means unbounded
    float2 clipLo;
    float2 clipHi;
    float2 fadeAt;
    float  fadeRadius;
    float  fadeWidth;
};

// ===========================================================================
// MODE 1 EXISTS TO MAKE A GLOBAL MAJORANT LOOK AS BAD AS IT REALLY IS.
//
// A constant slab is the one medium for which a global majorant is already tight, so
// every test written against it is blind to the cost of the alternative. The failure
// PROGRESS.md records -- 3.4x too much light at a 100x majorant -- needed the majorant
// to be forced loose by hand, because mode 0 could not do it on its own.
//
// A background plus one sharp core is the ordinary case, not a pathological one: a
// global majorant has to cover the single densest point in the field, so ONE hard core
// makes the ratio loose EVERYWHERE ELSE. That is a cumulus, and it is what the
// majorant grid exists for.
//
// The Gaussian is chosen because its maximum over an axis-aligned box has a closed
// form -- the nearest point of the box to the centre -- so the test can build grid
// bounds that are PROVABLY valid rather than sampled and hoped about. A bound that is
// merely probably right would make every grid result unfalsifiable.
// ===========================================================================
public float densityAt(Medium m, StructuredBuffer<float2> disp, float3 p)
{
    // A point outside the slab has no medium in it, which the slab range already
    // guarantees -- but a density function that relies on its caller to bound it is one
    // inlining away from being wrong.
    if (p.y < m.slabBottom || p.y > m.slabTop) return 0.0f;
    if (m.clipOn != 0 && (any(p.xz < m.clipLo) || any(p.xz > m.clipHi))) return 0.0f;

    float fade = 1.0f;
    if (m.fadeRadius > 0.0f)
    {
        float r = length(p.xz - m.fadeAt);
        fade = saturate((m.fadeRadius - r) / max(m.fadeWidth, 1.0f));
        if (fade <= 0.0f) return 0.0f;
    }

    if (m.mode == 0) return m.density * fade;

    if (m.mode == 2) return iceDensity(m.gen, disp, p) * fade;
    if (m.mode == 3) return convectionDensity(m.conv, p) * fade;

    float3 d  = (p - m.coreCentre) / max(m.coreRadius, 1e-6f);
    float  r2 = dot(d, d);
    return (m.density + m.coreDensity * exp(-r2)) * fade;
}

// One axis of a box, narrowing [t0, t1]. False when the ray misses it.
bool clipAxis(float o, float d, float lo, float hi, inout float t0, inout float t1)
{
    if (abs(d) < 1e-9f) return o >= lo && o <= hi;
    float ta = (lo - o) / d;
    float tb = (hi - o) / d;
    t0 = max(t0, min(ta, tb));
    t1 = min(t1, max(ta, tb));
    return t1 > t0;
}

// Where the ray is inside the slab. Returns false when it never is.
public bool slabRange(Medium m, float3 ro, float3 rd, out float t0, out float t1)
{
    t0 = 0.0f;
    t1 = 1e9f;

    if (abs(rd.y) < 1e-6f)
    {
        // Parallel to the deck: either always inside it or never.
        if (ro.y < m.slabBottom || ro.y > m.slabTop) return false;
    }
    else
    {
        float ta = (m.slabBottom - ro.y) / rd.y;
        float tb = (m.slabTop - ro.y) / rd.y;
        t0 = max(t0, min(ta, tb));
        t1 = min(t1, max(ta, tb));
    }

    // THE BOX ACROSS, per axis the same way as the slab above. The fade's radius is
    // folded into it as a square, which contains the circle the density fades inside.
    float2 lo = m.clipOn != 0 ? m.clipLo : float2(-1e9f, -1e9f);
    float2 hi = m.clipOn != 0 ? m.clipHi : float2(1e9f, 1e9f);
    if (m.fadeRadius > 0.0f)
    {
        lo = max(lo, m.fadeAt - m.fadeRadius);
        hi = min(hi, m.fadeAt + m.fadeRadius);
    }
    if (!clipAxis(ro.x, rd.x, lo.x, hi.x, t0, t1)) return false;
    if (!clipAxis(ro.z, rd.z, lo.y, hi.y, t0, t1)) return false;

    // A HORIZONTAL BOUND AS WELL, or a ray parallel to the deck marches forever
    // through empty grid cells and the frame rate collapses with nothing on screen.
    t1 = min(t1, 120000.0f);
    return t1 > t0 && t1 > 0.0f;
}

// ---------------------------------------------------------------------------
// The majorant grid
// ---------------------------------------------------------------------------
//
// ===========================================================================
// A CORRECTNESS REQUIREMENT WEARING AN OPTIMISATION'S CLOTHES.
//
// Null-collision tracking is unbiased for ANY majorant above the true density, and the
// cost is the ratio between them: the expected number of steps through a path of length
// L is majorant * L, and all but a handful of those are null collisions. A global
// majorant has to cover the single densest point in the whole field, so one sharp core
// makes that ratio loose along every ray that never goes near it.
//
// PROGRESS.md records what that cost: at 100x the true sigma the iteration cap was
// reached before the slab was, and the estimators returned PARTIAL answers -- 3.4x too
// much light through the ratio tracker, and 0.28% of rays escaping that should have
// scattered. Raising the cap to 1024 converted a silent bias into a visible slowdown,
// which is the right way round and is still a holding action.
//
// THE GRID REMOVES THE REASON THE CAP IS EVER APPROACHED, rather than raising it again.
// Per-cell bounds keep the local ratio near 1 everywhere, so the step count tracks the
// density actually present instead of the worst density anywhere.
//
// THE ONE THING THAT MUST BE TRUE: every stored value is an upper bound on the density
// anywhere in its cell. A bound that is too low does not merely cost accuracy -- delta
// tracking's acceptance probability sigma/majorant exceeds 1 and the estimator is
// silently biased. `slang.transport` builds bounds analytically for exactly this reason
// and carries a deliberately violated grid as a control.
// ===========================================================================

// ===========================================================================
// THE FIELD NAMES HERE ARE DELIBERATELY UNIQUE ACROSS THE WHOLE KERNEL, AND THAT IS
// NOT STYLE. IT IS A DEFENCE AGAINST HOW slangc NAMES THINGS.
//
// slangc disambiguates identifiers by appending an index assigned across the ENTIRE
// translation unit: the first `cellSize` it emits becomes `cellSize_0`, the second
// `cellSize_1`. Host code binds to those exact names.
//
// So when TransportLib started including GeneratorLib -- whose `GeneratorInput` has a
// `cellSize` -- this struct's `cellSize_0` silently became `cellSize_1`, and every host
// call site stopped compiling. Nothing about this struct changed. An unrelated include
// renamed a field in it.
//
// A COMPILE ERROR IS THE GOOD CASE and it is not guaranteed: two fields of the SAME
// TYPE swapping suffixes would still compile and would read the wrong memory. The
// defence is to keep host-visible field names unique across the kernel, which costs a
// word here and removes the failure entirely.
// ===========================================================================
public struct MajorantGrid
{
    float3 origin;      // world position of the min corner of cell (0,0,0)
    float3 cellExtent;  // NOT `cellSize` -- GeneratorInput already has one. See above
    int3   dims;
    int    enabled;     // 0 = ignore the grid and use Medium.majorant everywhere;
                        // 1 = the stored bounds; 2 = computed per cell (see gridBound)
};

// A sound upper bound on the medium's density anywhere in the box [lo, hi], from the
// generator's own structure. Only the generators that can say something better than
// their global majorant do; everything else answers with it.
public float mediumBound(Medium m, StructuredBuffer<float2> disp, float3 lo, float3 hi)
{
    if (m.mode == 3) return convectionBound(m.conv, lo, hi);
    if (m.mode == 2) return iceDensityBound(m.gen, disp, lo, hi);
    return m.majorant;
}

// The bound for one cell. OUTSIDE THE GRID FALLS BACK TO THE GLOBAL MAJORANT, which
// keeps the estimator correct when the grid does not span the whole medium -- the grid
// is an accelerator, never the definition of where the medium is.
//
// ===========================================================================
// `enabled = 2` IS A GRID WITH NO STORAGE: THE BOUND IS COMPUTED FOR THE CELL THE WALK
// HAS JUST ENTERED, FROM THE GENERATOR'S STRUCTURE.
//
// A stored grid needs a finite extent, and a cumulus layer has none -- it runs to the
// horizon in every direction, and a grazing ray crosses tens of kilometres of it. So the
// lattice is unbounded and each cell's bound is mediumBound over its box. That is sound
// for exactly the reason a stored analytic bound is, and it costs one bound evaluation
// per cell crossed rather than per null collision -- which is why the walks below
// evaluate this when they ENTER a cell and hold it, rather than at every step.
// ===========================================================================
public float gridBound(Medium m, MajorantGrid g, StructuredBuffer<float> bounds,
                       StructuredBuffer<float2> disp, int3 c, float fallback)
{
    if (g.enabled == 0) return fallback;
    if (g.enabled == 2)
    {
        float3 lo = g.origin + float3(c) * g.cellExtent;
        return mediumBound(m, disp, lo, lo + g.cellExtent);
    }
    if (c.x < 0 || c.y < 0 || c.z < 0 ||
        c.x >= g.dims.x || c.y >= g.dims.y || c.z >= g.dims.z) return fallback;
    return bounds[(c.z * g.dims.y + c.y) * g.dims.x + c.x];
}

// Amanatides-Woo, the standard voxel walk: per axis, how far to the next boundary and
// how far between boundaries thereafter.
public struct Dda
{
    int3   cell;
    int3   stepDir;
    float3 tMax;      // t at which the ray crosses the next boundary on each axis
    float3 tDelta;    // t between successive boundaries on each axis
};

public Dda ddaInit(MajorantGrid g, float3 ro, float3 rd, float t)
{
    Dda d;

    // ===================================================================
    // A DISABLED GRID MUST NOT TRAVERSE, AND GETTING THIS WRONG DID NOT LOOK LIKE A
    // TRAVERSAL BUG.
    //
    // With `enabled = 0` the bound lookup already falls back to Medium.majorant, so it
    // is tempting to let the walk run and simply ignore what it finds. It cannot: the
    // walk still chops the ray at cell boundaries, and every boundary costs an
    // iteration of a loop whose cap is a fixed 1024. Against the 1x1x1 metre dummy
    // grid a caller passes when it does not want one, that caps the path at about a
    // kilometre of travel.
    //
    // MEASURED, because slang.bounce noticed before this comment existed: the furnace's
    // mean scattering events fell from 4.21 to 2.79 and every capped fraction moved,
    // while the furnace IDENTITY still held exactly. So the estimator stayed
    // self-consistent and merely answered a different question -- which is the hardest
    // kind of change to spot, and would have been invisible without a suite whose
    // numbers were blessed before the grid existed.
    //
    // One cell spanning everything, so min(ddaExit, t1) is always t1 and the loops are
    // bit-for-bit what they were before the grid.
    // ===================================================================
    if (g.enabled == 0)
    {
        d.cell    = int3(0, 0, 0);
        d.stepDir = int3(0, 0, 0);
        d.tMax    = float3(1e30f, 1e30f, 1e30f);
        d.tDelta  = float3(1e30f, 1e30f, 1e30f);
        return d;
    }

    float3 p     = ro + rd * t;
    float3 local = (p - g.origin) / g.cellExtent;
    d.cell = int3(floor(local));

    for (int a = 0; a < 3; ++a)
    {
        // A COMPONENT EXACTLY PARALLEL TO THE AXIS NEVER CROSSES IT. Left as an
        // infinite tMax rather than special-cased later, so the min() below simply
        // never picks it.
        if (abs(rd[a]) < 1e-12f)
        {
            d.stepDir[a] = 0;
            d.tMax[a]    = 1e30f;
            d.tDelta[a]  = 1e30f;
        }
        else
        {
            d.stepDir[a] = rd[a] > 0.0f ? 1 : -1;
            float next   = g.origin[a] + (float(d.cell[a]) + (rd[a] > 0.0f ? 1.0f : 0.0f))
                                       * g.cellExtent[a];
            d.tMax[a]    = t + (next - p[a]) / rd[a];
            d.tDelta[a]  = abs(g.cellExtent[a] / rd[a]);
        }
    }
    return d;
}

// Where the ray leaves the cell it is currently in.
public float ddaExit(Dda d)
{
    return min(d.tMax.x, min(d.tMax.y, d.tMax.z));
}

public void ddaAdvance(inout Dda d)
{
    if (d.tMax.x <= d.tMax.y && d.tMax.x <= d.tMax.z)
    {
        d.cell.x += d.stepDir.x;
        d.tMax.x += d.tDelta.x;
    }
    else if (d.tMax.y <= d.tMax.z)
    {
        d.cell.y += d.stepDir.y;
        d.tMax.y += d.tDelta.y;
    }
    else
    {
        d.cell.z += d.stepDir.z;
        d.tMax.z += d.tDelta.z;
    }
}

// A SINGLE CAP FOR BOTH ESTIMATORS, raised from the prototype's 128/256 and kept high
// even with the grid in place. The grid is what stops it being approached; the cap is
// what stops a bad grid from hanging the display driver. See PROGRESS.md.
//
// 4096 SINCE THE CUMULUS LAYER, whose procedural grid spends an iteration on every box a
// ray crosses, collision or not. A ray grazing the layer near the horizon crosses about
// six hundred of them. Nothing that stayed under 1024 changes: the cap is a bound the
// GPU can see, and a walk that never reaches it runs exactly the same iterations.
public static const int kTrackCap = 4096;

// ---------------------------------------------------------------------------
// Transmittance, by ratio tracking
// ---------------------------------------------------------------------------
//
// UNBIASED, AND IT DOES NOT TERMINATE THE PATH -- which is what next-event estimation
// needs: a partial shadow has to return a fraction, not a yes or a no.
//
// Each step multiplies by (1 - sigma/majorant), the probability that the collision
// just stepped to was fictitious. The product telescopes to the true transmittance in
// expectation, whatever the majorant is.
public float transmittance(Medium m, MajorantGrid g, StructuredBuffer<float> bounds,
                           StructuredBuffer<float2> disp,
                           inout Rng rng, float3 p, float3 dir, inout int steps)
{
    float t0, t1;
    if (!slabRange(m, p, dir, t0, t1)) return 1.0f;
    t0 = max(t0, 0.0f);

    float tr = 1.0f;
    float t  = t0;

    Dda dda = ddaInit(g, p, dir, t0);

    // ===================================================================
    // THE ITERATION CAP IS A CORRECTNESS LIMIT, NOT A SAFETY NET, and the
    // prototype's 128 was too low by a factor of eight.
    //
    // The expected number of steps is majorant * (t1 - t0) -- every one of them a
    // null collision when the majorant is loose. Hitting the cap `break`s and
    // returns the PARTIAL product, which is biased HIGH: the attenuation that had
    // not been accumulated yet is simply missing.
    //
    // MEASURED by slang.transport, through a 1000 m slab at optical depth 2.5,
    // where the analytic answer is 0.082085:
    //
    //     majorant      measured
    //       1x sigma    0.082292
    //      20x sigma    0.082124
    //     100x sigma    0.276252   <- 3.4x too much light
    //
    // 100x sigma needs about 250 steps and got 128. The failure is silent: a
    // too-bright cloud reads as a lighting choice, and it only appears when the
    // majorant is loose relative to the density actually encountered -- which is
    // exactly what happens when a field has one sharp peak and a global majorant
    // has to cover it.
    //
    // 1024 covers roughly 400x sigma at this thickness. THE REAL FIX IS LOCAL
    // MAJORANTS -- a coarse grid of per-cell bounds instead of one global number --
    // which is the standard performance fix for the same reason it is the
    // correctness fix: it keeps the ratio near 1 everywhere. That is Phase 2 work
    // and is recorded in PROGRESS.md.
    //
    // Raising the cap converts a silent bias into a visible slowdown, which is the
    // right way round.
    // ===================================================================
    // THE CELL'S BOUND IS TAKEN ON ENTRY AND HELD, not asked again at every step. For a
    // stored grid that is a lookup either way; for a procedural one (enabled = 2) it is
    // a bound evaluation, and paying it per null collision rather than per cell would
    // hand back much of what the grid saves.
    float localMaj = gridBound(m, g, bounds, disp, dda.cell, m.majorant);

    for (int i = 0; i < kTrackCap; ++i)
    {
        ++steps;

        float cellExit  = min(ddaExit(dda), t1);

        // AN EMPTY CELL IS CROSSED IN ONE STEP AND COSTS NO RANDOM NUMBER. This is
        // where most of the saving is: a bound of zero means there is provably nothing
        // to collide with, so the only correct thing to do is leave. It is also the
        // step that is catastrophically wrong if the bound is not a true bound, which
        // is why the grid is built analytically and the violated-bound control exists.
        if (localMaj <= 0.0f)
        {
            if (cellExit >= t1) break;
            t = cellExit;
            ddaAdvance(dda);
            localMaj = gridBound(m, g, bounds, disp, dda.cell, m.majorant);
            continue;
        }

        t -= log(max(1.0f - randFloat(rng), 1e-7f)) / localMaj;

        // THE EXPONENTIAL IS MEMORYLESS, which is the entire reason a per-cell majorant
        // is legitimate. Overshooting the cell is not a rejected sample to be redrawn:
        // the walk simply resumes at the boundary under the next cell's rate, and the
        // distribution of the whole path is unchanged.
        if (t >= cellExit)
        {
            if (cellExit >= t1) break;
            t = cellExit;
            ddaAdvance(dda);
            localMaj = gridBound(m, g, bounds, disp, dda.cell, m.majorant);
            continue;
        }

        float sigma = densityAt(m, disp, p + dir * t);
        tr *= max(0.0f, 1.0f - sigma / localMaj);

        // Russian roulette, so a long clear path does not cost the whole cap for an
        // answer that is already 1. UNBIASED: the survivors are doubled, so the
        // expectation is unchanged -- which the mean-over-trials test relies on.
        if (tr < 0.01f)
        {
            if (randFloat(rng) > 0.5f) return 0.0f;
            tr *= 2.0f;
        }
    }

    return tr;
}

// ---------------------------------------------------------------------------
// Free flight, by delta tracking
// ---------------------------------------------------------------------------
//
// Steps an exponential distance against the MAJORANT, then accepts the collision as
// real with probability sigma/majorant. The rejected ones are null collisions:
// fictitious matter that makes the medium uniform so the free-flight distance has a
// closed form.
//
// THE POINT IS THAT IT NEEDS NO INTEGRAL OF DENSITY ALONG THE RAY, which is what
// makes a heterogeneous medium tractable at all. A majorant below the true maximum
// biases the result; above it is merely slow.
//
// `tLimit` STOPS THE SEARCH AT A DISTANCE, which is what makes two layers exact rather
// than approximate. A medium that is a SUM of two has a free-flight distance that is the
// MINIMUM of the two layers' own -- the survival probabilities multiply, exp(-A) exp(-B),
// which is the definition of independent exponential races. So the second layer only
// needs searching up to where the first one collided; a collision beyond that never
// happens, because the path scattered first. See sceneFreeFlight in BounceLib.slang.
public bool sampleFreeFlightUpTo(Medium m, MajorantGrid g, StructuredBuffer<float> bounds,
                                 StructuredBuffer<float2> disp,
                                 inout Rng rng, float3 ro, float3 rd, float tLimit,
                                 out float3 scatterPoint, out float distance, inout int steps)
{
    scatterPoint = float3(0.0f, 0.0f, 0.0f);
    distance     = 0.0f;

    float t0, t1;
    if (!slabRange(m, ro, rd, t0, t1)) return false;

    t1 = min(t1, tLimit);
    if (!(t1 > t0)) return false;

    float t = max(t0, 0.0f);

    Dda dda = ddaInit(g, ro, rd, t);

    // THE SAME CAP ARGUMENT AS transmittance(), and the same measurement: at 100x
    // sigma the prototype's 256 let 0.28% of rays escape that should have scattered,
    // because the loop ran out before the slab did. Biased towards a THINNER cloud,
    // and in the opposite direction to the transmittance bias -- so the two do not
    // even cancel.
    float localMaj = gridBound(m, g, bounds, disp, dda.cell, m.majorant);

    for (int i = 0; i < kTrackCap; ++i)
    {
        ++steps;

        float cellExit = min(ddaExit(dda), t1);

        if (localMaj <= 0.0f)
        {
            if (cellExit >= t1) return false;
            t = cellExit;
            ddaAdvance(dda);
            localMaj = gridBound(m, g, bounds, disp, dda.cell, m.majorant);
            continue;
        }

        t -= log(max(1.0f - randFloat(rng), 1e-7f)) / localMaj;

        if (t >= cellExit)
        {
            if (cellExit >= t1) return false;
            t = cellExit;
            ddaAdvance(dda);
            localMaj = gridBound(m, g, bounds, disp, dda.cell, m.majorant);
            continue;
        }

        float3 p = ro + rd * t;

        // A BOUND THAT IS TOO LOW MAKES THIS RATIO EXCEED 1, and the comparison then
        // accepts unconditionally -- the ray scatters at the first collision it tests
        // instead of the one it should have. That is the silent failure the analytic
        // grid construction and the violated-bound control exist to rule out.
        if (randFloat(rng) < densityAt(m, disp, p) / localMaj)
        {
            scatterPoint = p;
            distance     = t;
            return true;
        }
    }

    return false;
}

// The whole slab, which is what one layer on its own needs. The limit is far beyond
// slabRange's own horizontal cap, so min() leaves t1 exactly as it was.
public bool sampleFreeFlight(Medium m, MajorantGrid g, StructuredBuffer<float> bounds,
                             StructuredBuffer<float2> disp,
                             inout Rng rng, float3 ro, float3 rd,
                             out float3 scatterPoint, out float distance, inout int steps)
{
    return sampleFreeFlightUpTo(m, g, bounds, disp, rng, ro, rd, 1e30f,
                                scatterPoint, distance, steps);
}

#endif // MISTYTUNE_TRANSPORT_LIB_SLANG
