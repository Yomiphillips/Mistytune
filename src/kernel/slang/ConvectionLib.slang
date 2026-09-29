// The cellular convection generator: cumulus, stratocumulus, and everything between.
//
// The whole idea in four lines:
//
//   1. The boundary layer is tiled by CONVECTIVE CELLS -- a jittered lattice, each cell
//      with its own vigour and its own point in a birth-to-death cycle.
//   2. Air rises either at the cells' RIMS (open cells) or in their CENTRES (closed
//      cells), and CELL POLARITY blends the two. That is the updraft field.
//   3. Where the updraft beats a threshold set by the moisture, a column of cloud stands
//      on the CONDENSATION LEVEL -- flat, because every parcel starts from the same
//      surface air -- and rises as far as its updraft carries it, under the inversion.
//   4. Billows displace the top and sides, riding the updraft upward; the base is left
//      alone.
//
// Nothing here is a density-to-opacity ramp. Every factor is a physical statement
// about where saturated air is, and the light is the transport's business.

#ifndef MISTYTUNE_CONVECTION_LIB_SLANG
#define MISTYTUNE_CONVECTION_LIB_SLANG

// hash22 and gradientNoise. The include is guarded, so a file that includes both this
// and TransportLib gets one copy.
#include "GeneratorLib.slang"

// ===========================================================================
// EVERY FIELD NAME STARTS `cv`, AND THAT IS THE FIELD-NAME HAZARD, NOT STYLE.
//
// slangc suffixes identifiers by an index assigned across the whole translation unit,
// so a `cellSize` here would push GeneratorInput's to `cellSize_1` and every host
// binding to it would read another struct's memory -- or, with luck, fail to compile.
// slang.fieldNames checks that every host-visible field is `_0`. A prefix makes that
// true by construction. Local variables below avoid every field name in the kernel for
// the same reason: a local that shadows a field bumps its suffix too.
// ===========================================================================
public struct ConvectionInput
{
    float  cvBase;         // m, the condensation level: the flat base
    float  cvDepth;        // m, the tallest a tower may grow above the base
    float  cvSpacing;      // m, the lattice pitch -- the size of one convective cell
    float  cvPolarity;     // 0 = open (rising rims) .. 1 = closed (rising centres)
    float  cvCoverage;     // 0..1, the moisture: how much updraft makes cloud
    float  cvShape;        // exponent on the tower profile; lower is steeper-sided
    float  cvSigma;        // per metre, the peak extinction
    float  cvBillow;       // m, how far billows displace the top and sides
    float  cvBillowScale;  // m, the largest billow
    int    cvOctaves;
    float2 cvDrift;        // m, how far the pattern has travelled on the wind
    float  cvAge;          // lifetimes elapsed: the clock every cell's cycle reads
    float  cvRise;         // m, how far the billows have climbed
};

// ---------------------------------------------------------------------------
// THE LATTICE'S GEOMETRY, AND WHY 3x3 IS EXACT HERE WHEN IT IS NOT FOR WORLEY NOISE.
//
// A cell's centre sits within its slot, jittered by at most +-kConvJitter/2, so it is
// never closer than inset = (1 - kConvJitter)/2 = 0.15 slot widths to the slot's edge.
// Each cell reaches at most kConvReachClosed slot widths and NO FURTHER -- its kernels
// are compactly supported. A slot two steps away along an axis therefore holds a centre
// at least 1 + inset = 1.15 away, beyond reach. So the 3x3 neighbourhood is not an
// approximation of the field, it IS the field -- which is what a sound box bound needs,
// because Worley's nearest-point search with a 3x3 window can switch point sets across
// a slot boundary and is not even continuous there. slang.convection checks it against
// a 5x5 window, to the bit.
//
//
// TWO REACHES, ONE PER POLARITY, AND BOTH ARE MEASUREMENTS. The closed field needs
// kernels long enough to tile the plane, or a deck has holes at the vertices. The open
// field needs kernels short enough not to reach into a neighbour's middle: at one slot
// and a half, the rim field at a cell's centre came out half its value on the rim, and
// open cells had no holes to speak of.
// ---------------------------------------------------------------------------
public static const float kConvJitter      = 0.7f;
public static const float kConvReachOpen   = 0.75f;  // slot widths
public static const float kConvReachClosed = 1.05f;  // slot widths; must stay <= 1 + inset

// A cell's vigour is its size variety times where it is in its life. The floor on the
// variety is what keeps the smallest cells from vanishing entirely: a field of equals
// reads as a pattern, and one hero among subordinates reads as a sky.
public static const float kConvMinVigour = 0.35f;

// The rim field's scale: the open kernel halfway between two equal neighbours a slot
// apart, (1 - 0.25/0.75^2)^2 = 0.31. Dividing by it puts a vigorous rim at one, beside
// the centre field, which is one at a vigorous cell's centre by construction.
// slang.convection prints the field's upper percentiles, which is where to look if this
// is retuned.
public static const float kConvOpenNorm = 0.31f;

// THE VERTICAL PROFILE, in metres.
//
//   kConvBaseRamp  extinction rises as the square root of height above the base over
//                  this: droplets grow as the parcel climbs, fast at first. It is what
//                  makes the base read as a surface rather than a mist.
//   kConvBaseFade  billows fade in over this above the base, so the base stays flat.
//   kConvEdgeSoft  how soft the cloud's boundary is once billows have shaped it.
public static const float kConvBaseRamp = 40.0f;
public static const float kConvBaseFade = 150.0f;
public static const float kConvEdgeSoft = 12.0f;

// BILLOWS ARE PUFFS: a sphere on every feature point of a jittered 3D lattice, one
// lattice per octave. The union of overlapping spheres is round lobes meeting in sharp
// creases -- which is the cauliflower, and which turbulence (|noise|) is not: its lobes
// are ridges, and a first version built from it rendered smooth jellybeans with a
// faint texture on them. The gain and bias re-centre the octave-averaged bump so that
// the billows bulge about as much as they bite.
//
// EIGHT CELLS, NOT TWENTY-SEVEN, AND THE PAIR OF NUMBERS BELOW IS WHAT MAKES THAT EXACT.
// A point in the upper half of its cell along an axis is at least 0.5 + (1 - J)/2 from
// any feature point in the cell BELOW -- 0.75 at J = 0.5 -- and a puff reaches
// kPuffRadius = 0.75. So only the eight cells on the point's own side of each axis can
// reach it, and searching them is the whole field rather than an approximation of it.
// The 27-cell search cost 81 hashes a density evaluation at three octaves, about
// two-thirds of the whole evaluation.
public static const float kPuffJitter = 0.5f;    // feature points within +-0.25 of centre
public static const float kPuffRadius = 0.75f;   // lattice units; must stay <= 0.5 + (1-J)/2
public static const float kBillowGain = 2.2f;
public static const float kBillowBias = 1.16f;  // measured: 0.9 inflated by +0.20

// How much of the full billow a tower's SIDES get, against its top. Rising thermals
// break through the top; the flanks are smoother. The displacement ramps from this at
// the base to one at the top of the tallest tower.
public static const float kBillowSideFraction = 0.35f;

// THERE IS NO FOOTPRINT WARP, AND THERE WAS ONE. It was there to stop the footprints
// being ovals, which a sum of round kernels makes. The two-largest-kernels fields do not:
// their level sets are the cells' own polygonal boundaries. And the warp cost two noise
// evaluations per density evaluation plus a wider box for every bound -- at 0.18 of a
// cell it widened boxes past a cell's width and the bound proved 1.9% of them empty.

// Salts for the lattice hashes. Distinct from the ice generator's, so the two layers'
// cells are unrelated even where their lattices happen to align.
static const uint kConvSaltCentre = 0x68e31da4u;
static const uint kConvSaltLife   = 0xb5297a4du;

// ---------------------------------------------------------------------------
// One cell
// ---------------------------------------------------------------------------

public float2 convCellCentre(int2 slot)
{
    float2 j = hash22(slot, kConvSaltCentre) - 0.5f;
    return float2(slot) + 0.5f + j * kConvJitter;
}

// Birth to gone over one lifetime, peaking a third of the way through: cumulus grows
// quickly and decays slowly. 27/4 u (1-u)^2 is one at u = 1/3, zero at both ends, and
// flat at the end -- so a cell dies smoothly and the next is born from nothing, which is
// continuous across the wrap. A POLYNOMIAL RATHER THAN A SINE: see GeneratorLib's note
// on transcendentals as a cross-platform hazard. frac() of a small number is exact.
public float convLife(float u)
{
    return 6.75f * u * (1.0f - u) * (1.0f - u);
}

public float convVigour(ConvectionInput c, int2 slot)
{
    float2 h = hash22(slot, kConvSaltLife);
    float u = frac(c.cvAge + h.x);
    return convLife(u) * lerp(kConvMinVigour, 1.0f, h.y);
}

// A cell's kernel at a squared distance in slot units: (1 - d^2/R^2)^2. Smooth,
// compactly supported, monotone decreasing, and it needs no square root.
public float convBump(float d2, float reach)
{
    float r2 = reach * reach;
    if (d2 >= r2) return 0.0f;
    float t = 1.0f - d2 / r2;
    return t * t;
}

// ---------------------------------------------------------------------------
// The updraft
// ---------------------------------------------------------------------------
//
// ===========================================================================
// OPEN AND CLOSED ARE COMPLEMENTS, BUILT FROM THE SAME TWO NUMBERS: THE LARGEST KERNEL AT
// THE POINT, AND THE SECOND LARGEST.
//
// CLOSED: air rises in the centre. The field is how much the strongest cell dominates
// the next: first - second. One at a lone cell's centre, zero on the boundary between
// two equals -- and between unequal neighbours the boundary moves towards the weaker,
// so a vigorous cell grows at its neighbours' expense. That is a power diagram, and it
// is what convection does.
//
// OPEN: air rises at the rims. The field is the SECOND largest kernel -- how strongly a
// point belongs to a cell other than its own. Near nothing at a centre, where the cell's
// own kernel is alone; as large as the first on a boundary, where two cells meet. So as
// moisture rises, open cells cloud first along the most vigorous rims -- scattered
// cumulus -- and last as a full network around clear holes.
//
// A PAIRWISE PRODUCT WAS TRIED FIRST AND MEASURED WRONG. sum K_i K_j multiplies a
// neighbour's small kernel by the cell's OWN kernel at its peak, so any neighbour within
// reach made a centre look like a rim: 0.30 at centres against 0.41 on rims, and open
// cells had no holes. The second-largest kernel is symmetric in the two cells, which
// is what "on the boundary" means.
// ===========================================================================
public float convUpdraft(ConvectionInput c, float2 q)
{
    float2 g  = q / c.cvSpacing;
    int2   gi = int2(floor(g));

    float oTop = 0.0f, oNext = 0.0f;   // the short kernels' two largest: the rims
    float kTop = 0.0f, kNext = 0.0f;   // the long kernels' two largest: the centres

    for (int j = -1; j <= 1; ++j)
    {
        for (int i = -1; i <= 1; ++i)
        {
            int2 slot = gi + int2(i, j);

            float vig = convVigour(c, slot);
            if (vig <= 0.0f) continue;

            float2 d  = g - convCellCentre(slot);
            float  d2 = dot(d, d);
            float  ko = vig * convBump(d2, kConvReachOpen);
            float  kk = vig * convBump(d2, kConvReachClosed);

            if (ko > oTop) { oNext = oTop; oTop = ko; }
            else if (ko > oNext) { oNext = ko; }

            if (kk > kTop) { kNext = kTop; kTop = kk; }
            else if (kk > kNext) { kNext = kk; }
        }
    }

    float openField   = min(oNext / kConvOpenNorm, 1.0f);
    float closedField = kTop - kNext;
    return lerp(openField, closedField, c.cvPolarity);
}

// How tall the cloud column stands over a point with updraft w. Zero below the
// moisture threshold; the full depth at the strongest updraft. The exponent is below
// one, so the sides rise steeply from the edge of the footprint and the top rounds off,
// which is a tower rather than a tent.
//
// THE THRESHOLD IS 1 - sqrt(coverage), NOT 1 - coverage. The updraft is mostly small
// -- its median is under 0.05 in an open field -- so a linear threshold left the bottom
// half of the slider nearly empty: MEASURED, coverage 0.4 made 2.5% of the sky cloud.
// The square root spends more of the slider where the updraft actually lives.
public float convTowerHeight(ConvectionInput c, float w)
{
    float cover = clamp(c.cvCoverage, 0.0f, 1.0f);
    if (cover <= 0.0f) return 0.0f;

    float span = sqrt(cover);
    float u = saturate((w - (1.0f - span)) / span);
    if (u <= 0.0f) return 0.0f;
    return c.cvDepth * pow(u, c.cvShape);
}

// One octave of puffs: the largest sphere any feature point puts over x, in [0, 1].
//
// NOT WORLEY NOISE, THOUGH IT LOOKS LIKE IT. The 3x3x3 window can miss a feature point
// that is nearer than every one inside it, so this is not the true nearest-point
// distance -- and it does not need to be. Nothing bounds it by continuity: its only
// consumer clamps the result to [-1, 1] and the density's bound takes the clamp.
public float convPuffs(float3 x)
{
    float3 fl = floor(x);
    int3   xi = int3(fl);
    float3 f  = x - fl;

    // The point's own side of each axis: 0 or -1 for the lower half, 0 or +1 for the
    // upper. See kPuffJitter on why the far side cannot reach.
    int3 lo = int3(f.x < 0.5f ? -1 : 0, f.y < 0.5f ? -1 : 0, f.z < 0.5f ? -1 : 0);

    float nearest = 1e9f;
    for (int dz = 0; dz <= 1; ++dz)
    for (int dy = 0; dy <= 1; ++dy)
    for (int dx = 0; dx <= 1; ++dx)
    {
        int3   off  = lo + int3(dx, dy, dz);
        int3   cell = xi + off;
        float3 site = float3(off) + 0.5f + (0.5f * kPuffJitter) * hash33(cell);
        float3 d = site - f;
        nearest = min(nearest, dot(d, d));
    }
    return saturate(1.0f - nearest / (kPuffRadius * kPuffRadius));
}

// Cauliflower: round lobes separated by sharp creases, in [-1, 1]. Sampled in the
// PATTERN'S frame and lifted by the updraft, so the billows ride with the cloud and
// climb through it rather than sitting still while it drifts past.
public float convBillow(ConvectionInput c, float3 p)
{
    float3 x = float3(p.x, p.y - c.cvRise, p.z) / c.cvBillowScale;

    float sum = 0.0f, amp = 0.6f, norm = 0.0f;
    for (int i = 0; i < 4; ++i)
    {
        if (i >= c.cvOctaves) break;
        sum  += amp * convPuffs(x);
        norm += amp;
        x    *= 2.17f;
        amp  *= 0.55f;
    }
    float raw = norm > 0.0f ? sum / norm : 0.0f;

    // CLAMPED, so the bound below can take the billow at exactly one rather than at an
    // analytic bound on the puffs. It costs the rare extreme lobe a little of its tip.
    return clamp(raw * kBillowGain - kBillowBias, -1.0f, 1.0f);
}

// How far the billows may displace the surface at a height above the base: nothing at
// the base, which stays flat; kBillowSideFraction of the full amount on the flanks,
// rising to all of it at the top of the tallest tower. NON-DECREASING IN HEIGHT, which
// is what lets the bound take it at the top of a box.
public float convLift(ConvectionInput c, float above)
{
    float up = saturate(above / max(c.cvDepth, 1.0f));
    return c.cvBillow * smoothstep(0.0f, kConvBaseFade, above)
         * lerp(kBillowSideFraction, 1.0f, up);
}



// ---------------------------------------------------------------------------
// Density
// ---------------------------------------------------------------------------

public float convectionDensity(ConvectionInput c, float3 p)
{
    float above = p.y - c.cvBase;

    // NOTHING BELOW THE CONDENSATION LEVEL, EXACTLY. That line is the flat base.
    if (above < 0.0f || above > c.cvDepth + c.cvBillow) return 0.0f;

    float2 q = p.xz - c.cvDrift;

    float tower = convTowerHeight(c, convUpdraft(c, q));
    if (tower <= 0.0f) return 0.0f;

    // The cheapest rejection first: even the biggest outward billow cannot reach.
    float lift = convLift(c, above);
    if (tower - above + lift <= 0.0f) return 0.0f;

    // ...and the cheapest acceptance: DEEP ENOUGH THAT NO BILLOW CAN BITE THROUGH TO
    // THE EDGE. The billow is at least -1, so inside >= tower - above - lift, and past
    // kConvEdgeSoft the edge factor is one whatever the billow says. Most scattering in
    // a thick cloud happens exactly here, and the billow is the expensive part.
    float inside;
    if (tower - above - lift >= kConvEdgeSoft)
    {
        inside = kConvEdgeSoft;
    }
    else
    {
        inside = tower - above + lift * convBillow(c, float3(q.x, p.y, q.y));
        if (inside <= 0.0f) return 0.0f;
    }

    float edge    = smoothstep(0.0f, kConvEdgeSoft, inside);
    float profile = sqrt(saturate(above / kConvBaseRamp));
    return c.cvSigma * profile * edge;
}

// ---------------------------------------------------------------------------
// A SOUND BOUND OVER A BOX
// ---------------------------------------------------------------------------
//
// ===========================================================================
// WHY THIS GENERATOR NEEDS THE MAJORANT GRID AND THE ICE DID NOT.
//
// Cirrus fills its slab thinly and nearly everywhere, so a global majorant is already
// close to the density a ray meets, and a grid only adds traversal steps -- SlangBridge.h
// records it losing 7x. Cumulus is the opposite: dense towers in clear air. A global
// majorant has to cover the densest point of the densest tower, so a ray crossing the
// clear air between clouds pays null collisions at cloud density the whole way -- 30
// per kilometre at the default, and a grazing ray crosses tens of kilometres of layer.
//
// THE BOUND IS COMPUTED PER BOX, ON THE FLY, rather than stored. The layer is infinite
// in both horizontal directions, so there is no finite grid to fill, and every factor
// of the density is monotone in something a box bounds exactly:
//
//   profile  increasing in height        -> take it at the box's top
//   lift     increasing in height        -> take it at the box's top
//   billow   at most one, by its clamp
//   inside   increasing in tower, decreasing in height -> tallest tower, lowest point
//   tower    increasing in the updraft   -> the updraft's bound over the footprint
//   updraft  built from kernels that DECREASE with distance: each cell's kernel over a
//            box lies between its value at the box's nearest and farthest points, and
//            both fields are monotone in the kernels -- see convUpdraftBound.
//
// So every inequality holds by construction, and the only thing sampled is nothing.
// A TOO-LOW BOUND IS NOT A SLOW RENDER, IT IS A WRONG ONE -- delta tracking's
// acceptance probability exceeds one and the cloud comes out quietly too thin.
// slang.convection sweeps the density densely against this bound, as the floor of a
// check that is really this argument.
// ===========================================================================

// One cell's contribution to the updraft's bound over the box [a, b] (slot units): its
// kernels at the box's nearest and farthest points, folded into the running order
// statistics the bound is built from.
void convSlotBound(ConvectionInput c, int2 slot, float2 a, float2 b,
                   inout float openTop, inout float openNext, inout float hiTop,
                   inout float loTop, inout float loNext)
{
    float vig = convVigour(c, slot);
    if (vig <= 0.0f) return;

    float2 ctr = convCellCentre(slot);

    float2 nearGap = max(max(a - ctr, ctr - b), float2(0.0f, 0.0f));
    float  dNear   = dot(nearGap, nearGap);
    if (dNear >= kConvReachClosed * kConvReachClosed) return;   // the longer reach

    float2 farGap = max(abs(a - ctr), abs(b - ctr));
    float  dFar   = dot(farGap, farGap);

    // Each field's own kernels, each bounded between the box's nearest and farthest
    // points -- the rims from the short ones, the centres from the long ones.
    float oHi = vig * convBump(dNear, kConvReachOpen);
    float kHi = vig * convBump(dNear, kConvReachClosed);
    float kLo = vig * convBump(dFar,  kConvReachClosed);

    if (oHi > openTop) { openNext = openTop; openTop = oHi; }
    else if (oHi > openNext) { openNext = oHi; }

    hiTop = max(hiTop, kHi);

    if (kLo > loTop) { loNext = loTop; loTop = kLo; }
    else if (kLo > loNext) { loNext = kLo; }
}

// The largest the updraft can be anywhere in the footprint [q0, q1] (pattern frame, m).
public float convUpdraftBound(ConvectionInput c, float2 q0, float2 q1)
{
    float2 a = q0 / c.cvSpacing;
    float2 b = q1 / c.cvSpacing;

    float openTop = 0.0f, openNext = 0.0f;   // the short kernels' two largest UPPER bounds
    float hiTop   = 0.0f;                    // the long kernels' largest upper bound
    float loTop   = 0.0f, loNext = 0.0f;     // ...and their two largest LOWER bounds

    // ===================================================================
    // THE COMMON CASE, A BOX INSIDE ONE SLOT, IS THE DENSITY'S OWN FIXED 3x3 -- AND
    // THAT IS THE WHOLE REASON THE SHIPPING GRID IS ALIGNED TO THE LATTICE.
    //
    // A box within [s, s+1] on each axis is reached only by slots s-1 .. s+1: a slot two
    // away holds a centre at least 1 + inset = 1.15 from the slot's edge, beyond the
    // longer reach, by a margin of a tenth of a slot that the tolerance below does not
    // come near. So the neighbourhood is fixed, and the loop is one the compiler unrolls.
    //
    // MEASURED, before the split: with the general loop's data-dependent bounds, a bound
    // cost several density evaluations, and the grid made every cloudy scene SLOWER than
    // no grid at all -- 6.6 s against 3.6 s on a dense field.
    // ===================================================================
    int2 slot = int2(floor((a + b) * 0.5f));
    float2 lowEdge  = float2(slot) - 1e-4f;
    float2 highEdge = float2(slot) + 1.0f + 1e-4f;

    if (all(a >= lowEdge) && all(b <= highEdge))
    {
        for (int j = -1; j <= 1; ++j)
        for (int i = -1; i <= 1; ++i)
        {
            convSlotBound(c, slot + int2(i, j), a, b, openTop, openNext, hiTop, loTop, loNext);
        }
    }
    else
    {
        // One slot beyond the box on each side: see the note on 3x3 above -- a slot two
        // away cannot reach any point in the box, so these are all the cells that can.
        int2 i0 = int2(floor(a)) - int2(1, 1);
        int2 i1 = int2(floor(b)) + int2(1, 1);

        // A CAP, as cellFieldBound has, so a box far wider than a cell is a slow bound
        // rather than a hang.
        for (int jj = i0.y; jj <= i1.y && jj <= i0.y + 32; ++jj)
        for (int ii = i0.x; ii <= i1.x && ii <= i0.x + 32; ++ii)
        {
            convSlotBound(c, int2(ii, jj), a, b, openTop, openNext, hiTop, loTop, loNext);
        }
    }

    // ORDER STATISTICS ARE MONOTONE IN EVERY ARGUMENT. Every K_i at a point of the box
    // lies between its lower and upper bound, so the k-th largest K lies between the
    // k-th largest lower bound and the k-th largest upper bound.
    //
    // OPEN: the second-largest short kernel is at most the second-largest upper bound.
    float openHi = min(openNext / kConvOpenNorm, 1.0f);

    // CLOSED: the largest is at most the largest upper bound, and the second is at least
    // the second-largest lower bound -- so their difference is at most this.
    float closedHi = max(hiTop - loNext, 0.0f);

    // Both weights are non-negative for a polarity in [0, 1], which the host clamps to.
    // The epsilon is float rounding: the bound and the density compute the kernel along
    // different expressions, and a one-ulp disagreement at the moisture threshold would
    // otherwise be a zero bound over a sliver of cloud.
    return lerp(openHi, closedHi, c.cvPolarity) + 1e-5f;
}

public float convectionBound(ConvectionInput c, float3 lo, float3 hi)
{
    float low  = lo.y - c.cvBase;
    float high = hi.y - c.cvBase;
    float ceiling = c.cvDepth + c.cvBillow;

    if (high < 0.0f || low > ceiling) return 0.0f;
    low  = max(low, 0.0f);
    high = min(high, ceiling);

    float tower = convTowerHeight(c, convUpdraftBound(c, lo.xz - c.cvDrift, hi.xz - c.cvDrift));
    if (tower <= 0.0f) return 0.0f;

    float lift   = convLift(c, high);
    float inside = tower - low + lift + 1e-3f;
    if (inside <= 0.0f) return 0.0f;

    float edge    = smoothstep(0.0f, kConvEdgeSoft, inside);
    float profile = sqrt(saturate(high / kConvBaseRamp));
    return c.cvSigma * profile * edge * 1.00001f;
}

#endif // MISTYTUNE_CONVECTION_LIB_SLANG
