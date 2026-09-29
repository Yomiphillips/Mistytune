// Phase functions and their sampling, ported from proto/index.html.
//
// ===========================================================================
// WHY THIS IS THE FIRST PIECE OF THE TRANSPORT TO LAND.
//
// It is the part of a volumetric renderer with the most checkable physics and the
// least dependency on anything else: a phase function integrates to one over the
// sphere, and an importance sampler's pdf must be the density of what it actually
// samples. Both are testable without a medium, without a camera, and without a
// reference implementation to diff against -- which matters here, because the
// reference is a GLSL shader in a browser and there is nothing to compare bitwise.
//
// THE SKY PORT COULD BE PROVED BY TRANSCRIPTION; THIS ONE CANNOT. Shading.h gave a
// bit-exact target. Here the check has to be the physics itself, which is a better
// test anyway: it catches errors the original would have shared.
// ===========================================================================

// ---------------------------------------------------------------------------
// WHY THIS IS A `Lib` FILE AND Phase.slang IS NOT
// ---------------------------------------------------------------------------
//
// An #include in Slang drags in the including file's ENTRY POINTS as well as its
// functions, and Phase.slang and Transport.slang both declared an `rngTrial` kernel.
// A bounce loop that wants both the phase functions and the transport would get two
// definitions of it in one translation unit and fail to compile.
//
// So: `XLib.slang` holds functions and nothing else; `X.slang` is the harness that
// includes it and adds the entry points its own test needs. That is also the shape
// PLAN.md's "one kernel source" requires -- the production kernel includes several of
// these Libs and declares exactly one entry point.

#ifndef MISTYTUNE_PHASE_LIB_SLANG
#define MISTYTUNE_PHASE_LIB_SLANG
static const float kPi = 3.14159265358979323846f;

// ---------------------------------------------------------------------------
// Random numbers
// ---------------------------------------------------------------------------
//
// THE PCG GENERATOR USED TO BE STATED HERE, duplicated into Transport.slang because
// Slang 2026.18.3 has no `[export]`. The bounce loop needs both files in one
// translation unit, where two copies is a redefinition error rather than mere
// duplication -- so the definition moved out. See Rng.slang.
//
// THE INCLUDE SITS EXACTLY WHERE THE DEFINITION DID, which is not fussiness: slangc
// emits symbols in declaration order, so moving this above `kPi` would reorder the
// generated CUDA and turn a provably inert refactor into a diff nobody can read.
#include "Rng.slang"

// ---------------------------------------------------------------------------
// The phase functions
// ---------------------------------------------------------------------------

public struct PhaseInput
{
    float hgG;          // Henyey-Greenstein g for the liquid's broad lobe
    float draineG;      // the Draine lobe's g
    float draineAlpha;  // the Draine lobe's alpha
    float draineW;      // how much of the mixture is the Draine lobe
    int   useIce;       // nonzero selects the ice placeholder

    // THE DIFFRACTION LOBE A TRUNCATED PHASE FUNCTION LEFT OUT, for single scattering
    // only -- see phaseCamera below. Zero weight means none, which is every phase
    // function except a delta-scaled droplet one.
    float lobeG;
    float lobeWeight;
};

// THE FOUR PARAMETERS COME FROM THE DROPLET DIAMETER, which is the whole point of
// the Jendersie-d'Eon fit: droplet size becomes a physical control with a visible
// consequence, instead of four sliders nobody can reason about.
//
// The fits are valid for roughly 5 to 50 microns -- fog and cloud droplets. Outside
// that they are extrapolation, so the diameter is clamped rather than trusted: at
// d below 1.67 the hgG fit divides by a negative and the lobe inverts, which renders
// a cloud lit from the wrong side.
// ===========================================================================
// THE ONE CLAMP, AND WHY IT IS HERE RATHER THAN INSIDE THE SAMPLER.
//
// A BUG INHERITED FROM proto/index.html, found by slang.phase and measured before
// it was fixed. The prototype clamps g to +-0.95 inside sampleHG but evaluates the
// pdf at the UNCLAMPED g. For every droplet diameter the fit is valid for, hgG runs
// 0.971 (at 5 microns) to 0.998 (at 50) -- so the clamp always bites, the sampler
// always draws from a broader lobe than the pdf claims, and the two describe
// different distributions.
//
// MEASURED COST: the mean sample weight, which must equal the phase integral of 1,
// came out at 1.019 at 5 microns rising to 1.123 at 50 -- exactly tracking hgG's
// approach to 1. Every scattering event multiplied throughput by ~2-12% too much,
// compounding over a thirty-bounce budget: about 1.9x too much light after ten
// bounces at 50 microns. It renders as a cloud that is too bright and too flat,
// which reads as a lighting choice rather than as a bug.
//
// The fix is one bound applied where the parameters are DERIVED, so the sampler and
// the pdf cannot be given different numbers. sampleHG clamps to the same constant,
// which makes it a no-op for anything from here and still guards a hand-set value.
//
// 0.999 RATHER THAN 0.95: HG sampling is exact for any |g| < 1, and 0.95 threw away
// most of the forward peak the Jendersie-d'Eon fit exists to describe. At 0.999 the
// worst case is a phase value near 1.6e5 per steradian, which is large and finite.
// ===========================================================================
public static const float kMaxG = 0.999f;

public PhaseInput phaseFromDropletDiameter(float diameterMicrons, int useIce)
{
    float d = clamp(diameterMicrons, 5.0f, 50.0f);

    PhaseInput p;
    p.hgG         = clamp(exp(-0.0990567f / (d - 1.67154f)), -kMaxG, kMaxG);
    p.draineG     = clamp(exp(-(2.20679f / (d + 3.91029f)) - 0.428934f), -kMaxG, kMaxG);
    p.draineAlpha = exp(3.62489f - 8.29288f / (d + 5.52825f));
    p.draineW     = exp(-(0.599085f / (d - 0.641583f)) - 0.665888f);
    p.useIce      = useIce;
    p.lobeG       = 0.0f;
    p.lobeWeight  = 0.0f;
    return p;
}

public float hg(float cosT, float g)
{
    float d = 1.0f + g * g - 2.0f * g * cosT;
    return (1.0f - g * g) / (4.0f * kPi * d * sqrt(max(d, 1e-6f)));
}

// Draine, the second lobe of the Jendersie-d'Eon fit.
//
// The trailing divisor is what keeps the lobe normalised: (1 + a cos^2) integrates
// to (1 + a(1 + 2g^2)/3) against the HG weight, so dividing by it puts the integral
// back at one. Dropping it is the obvious "simplification" and it silently adds
// energy at every bounce.
public float draine(float cosT, float g, float a)
{
    float d = 1.0f + g * g - 2.0f * g * cosT;
    return (1.0f - g * g) / (4.0f * kPi * d * sqrt(max(d, 1e-6f)))
         * (1.0f + a * cosT * cosT) / (1.0f + a * (1.0f + 2.0f * g * g) / 3.0f);
}

// Jendersie-d'Eon (2023): the approximate Mie function for fog and cloud.
//
// Henyey-Greenstein has one lobe and no structure. Real droplets produce a very
// strong narrow forward peak, a backscatter rise, and the angular features that
// become a fogbow and a glory -- which is why HG clouds read as smoke.
public float phaseLiquid(PhaseInput p, float cosT)
{
    return (1.0f - p.draineW) * hg(cosT, p.hgG)
         + p.draineW * draine(cosT, p.draineG, p.draineAlpha);
}

// THESE TWO MUST MATCH samplePhaseDir's constants, or the pdf stops describing what
// was sampled. The prototype says the same thing in the same words, and keeping them
// adjacent here is the only reason it is safe.
public static const float kIceForwardW = 0.72f;
public static const float kIceForwardG = 0.85f;

// ICE, EXPLICITLY A PLACEHOLDER for the habit-indexed library of Phase 4.
//
// Ice is not spheres: plates, columns, bullets and dendrites each refract through
// their own prism angles, and the 22 and 46 degree haloes, the sundogs and the
// pillars all follow from that geometry. What is kept here is the forward lobe (ice
// is optically thin and near single-scatter, so backlit streaks glow) and a faint
// 22 degree ring so the SHAPE of a halo can be judged.
//
// IT IS NOT NORMALISED, AND THAT IS NOT AN OVERSIGHT -- the halo is added on top of
// a normalised mixture, so it injects energy. See the note in the parity test, which
// measures how much rather than assuming it is small.
public float phaseIce(float cosT)
{
    float forward = hg(cosT, kIceForwardG);
    float diffuse = 1.0f / (4.0f * kPi);
    // 22 degrees is 0.3840 radians. The width is arbitrary; the ANGLE is not.
    float t = (acos(clamp(cosT, -1.0f, 1.0f)) - 0.3840f) / 0.035f;
    float halo = exp(-t * t) * 0.35f;
    return lerp(diffuse, forward, 0.72f) + halo;
}

public float phaseAt(PhaseInput p, float cosT)
{
    return p.useIce != 0 ? phaseIce(cosT) : phaseLiquid(p, cosT);
}

// ===========================================================================
// THE PHASE FUNCTION FOR THE CAMERA RAY'S SINGLE SCATTERING, WHICH GETS THE DIFFRACTION
// PEAK BACK.
//
// Cloud droplets put about half their scattering into a diffraction lobe a degree
// wide -- Jendersie-d'Eon's HG term at g = 0.995 for 20 micron droplets, peaking near
// 4e4 per steradian. In multiple scattering that lobe is a firefly generator: a path
// deep in a cumulus has a nearly random direction, and the rare one within a degree of
// the sun returns a next-event estimate ten thousand times the mean. PROGRESS.md shows
// the render: 64 spp of salt and pepper, gone when the lobe is removed.
//
// So the transport uses the delta-Eddington truncation (Joseph, Wiscombe and Weinman
// 1976): that fraction of the scattering is treated as NOT scattering at all -- the
// extinction drops by it and the lobe is replaced by a broad one with the same
// asymmetry. Multiple scattering depends on the asymmetry and the reduced optical
// depth, both preserved, so the diffuse light of a cloud is unchanged. What is lost is
// the lobe's own angular shape: the glow within a few degrees of the sun behind a thin
// edge -- the silver lining.
//
// THE CAMERA RAY CAN HAVE IT BACK FOR FREE. Along one camera ray the angle to the sun
// is fixed, so the lobe's value is a constant across the whole estimate rather than a
// random spike -- no variance at all. This adds the truncated lobe back, at the weight
// the truncation took out of the extinction, and only here. Everywhere else it would
// be the firefly again.
// ===========================================================================
public float phaseCamera(PhaseInput p, float cosT)
{
    float v = phaseAt(p, cosT);
    if (p.lobeWeight > 0.0f) v += p.lobeWeight * hg(cosT, p.lobeG);
    return v;
}

// ---------------------------------------------------------------------------
// Sampling
// ---------------------------------------------------------------------------

// One Henyey-Greenstein lobe, sampled analytically. g = 0 degenerates to uniform.
public float3 sampleHG(inout Rng rng, float3 wo, float g, out float cosT)
{
    // THE SAME BOUND THE PARAMETERS WERE CLAMPED TO -- see kMaxG. If this and the
    // pdf's g can ever differ, the sampler and the pdf describe different
    // distributions and every bounce carries the error. That is the bug slang.phase
    // caught in the prototype.
    g = clamp(g, -kMaxG, kMaxG);
    float u1 = randFloat(rng);
    float u2 = randFloat(rng);

    if (abs(g) < 1e-3f)
    {
        cosT = 1.0f - 2.0f * u1;
    }
    else
    {
        float s = (1.0f - g * g) / (1.0f - g + 2.0f * g * u1);
        cosT = (1.0f + g * g - s * s) / (2.0f * g);
    }
    cosT = clamp(cosT, -1.0f, 1.0f);

    float sinT = sqrt(max(0.0f, 1.0f - cosT * cosT));
    float phi  = 2.0f * kPi * u2;

    float3 w = normalize(wo);
    float3 a = abs(w.y) < 0.95f ? float3(0.0f, 1.0f, 0.0f) : float3(1.0f, 0.0f, 0.0f);
    float3 u = normalize(cross(a, w));
    float3 v = cross(w, u);

    return normalize(sinT * cos(phi) * u + sinT * sin(phi) * v + cosT * w);
}

// ===========================================================================
// DRAINE'S LOBE, SAMPLED EXACTLY, BY REJECTION FROM ITS OWN HG ENVELOPE.
//
// Draine is HG(g) times (1 + a cos^2) over a constant, so HG(g) times (1 + a) is an
// envelope for it. Draw from HG, keep with probability (1 + a cos^2) / (1 + a), and what
// is kept is distributed exactly as Draine: the pdf IS the phase, and the weight is one.
//
// THE SHORTCUT THIS REPLACES WAS UNBIASED AND IT WAS A FIREFLY GENERATOR. The lobe used
// to be drawn from plain HG and reweighted by (1 + a cos^2)/norm, which the comment here
// called "bounded" -- and it is, at 0.06 to 1.7 for 20 micron droplets, where the fit's
// alpha is 27. But a weight that averages one and varies that much COMPOUNDS: after
// thirty bounces through a cumulus the throughput is a product of thirty of them, and
// its variance grows geometrically with depth. MEASURED: a 64 spp cumulus stayed salt
// and pepper after the diffraction lobe was truncated, and this was the rest of it.
//
// It never showed on cirrus, which scatters with the ice phase function and a handful
// of times at most.
//
// THE DRAW COUNT IS RANDOM -- (1 + a) / E[1 + a cos^2] tries on average, 1.7 at 20
// microns -- which costs nothing in determinism: it depends only on the stream. The
// cap is a bound the GPU can see; reaching it takes 64 rejections in a row, which at
// the worst acceptance any droplet gives is below one in a trillion.
// ===========================================================================
public float3 sampleDraine(inout Rng rng, float3 wo, float g, float a, out float cosT)
{
    float3 dir = sampleHG(rng, wo, g, cosT);
    if (!(a > 0.0f)) return dir;

    for (int i = 0; i < 64; ++i)
    {
        if (randFloat(rng) * (1.0f + a) <= 1.0f + a * cosT * cosT) break;
        dir = sampleHG(rng, wo, g, cosT);
    }
    return dir;
}

// ---------------------------------------------------------------------------
// SAMPLING THE MIXTURE BY SAMPLING THE SAME MIXTURE, LOBE FOR LOBE.
//
// The tempting shortcut is to sample ONE HG lobe at some average g and reweight by
// phase/pdf. It is unbiased and it does not work, and the symptom points somewhere
// else entirely -- which is why the prototype's reasoning is kept here rather than
// left behind in a browser.
//
// A single proxy lobe is always less forward-peaked than the real forward lobe, so
// in the forward direction phase/pdf comes out well above 1 -- around 2.7 for the ice
// phase against a g = 0.72 proxy. Throughput is multiplied by that at every bounce,
// so a path that forward-scatters repeatedly GROWS: 2.7, then 7, then 20. With a
// single-scatter albedo of 0.999 and a thirty-bounce budget, a few paths per frame
// come home carrying hundreds and the image fills with white pixels that never
// average away.
//
// That reads as a firefly problem, and the usual answers are clamping (biased) or
// more samples (useless -- the variance is unbounded). It is neither. It is the proxy.
//
// Sampling each lobe with its own probability makes the pdf match the phase term for
// term, so the weight is exactly 1 wherever the phase is a pure mixture of the
// sampled lobes, and bounded where it is not (the ice halo, which is not sampled).
// ---------------------------------------------------------------------------
public float3 samplePhaseDir(PhaseInput p, inout Rng rng, float3 wo, out float weight)
{
    float cosT;
    float3 dir;
    float pdf;

    if (p.useIce != 0)
    {
        if (randFloat(rng) < kIceForwardW) dir = sampleHG(rng, wo, kIceForwardG, cosT);
        else                               dir = sampleHG(rng, wo, 0.0f, cosT);

        pdf = kIceForwardW * hg(cosT, kIceForwardG)
            + (1.0f - kIceForwardW) * (1.0f / (4.0f * kPi));

        weight = pdf > 1e-9f ? phaseIce(cosT) / pdf : 0.0f;
    }
    else
    {
        // EACH LOBE FROM ITS OWN DISTRIBUTION, the Draine lobe by rejection -- see
        // sampleDraine. The pdf of the mixture is then the phase function itself, term
        // for term, and the weight is exactly one wherever the phase is positive.
        if (randFloat(rng) < p.draineW) dir = sampleDraine(rng, wo, p.draineG, p.draineAlpha, cosT);
        else                            dir = sampleHG(rng, wo, p.hgG, cosT);

        pdf = phaseLiquid(p, cosT);
        weight = pdf > 1e-9f ? 1.0f : 0.0f;
    }

    return dir;
}

#endif // MISTYTUNE_PHASE_LIB_SLANG
