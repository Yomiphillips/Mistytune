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
//      alone. They push along the surface's NORMAL, measured as a distance to the
//      nearest surface rather than straight down to the top -- which is what puts
//      cauliflower on a tall tower's walls instead of only on its crown.
//
// And optionally a HERO: one cloud placed where the user says, with or without the field
// around it. It is built the same way from an analytic tower, so it has the same base,
// the same billows and the same bound. It is what a framing -- and, later, pareidolia --
// is built on.
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

    // The hero cloud. cvHeroTop <= 0 means there is none. cvHeroAlone 1 leaves the
    // cell field out. ZERO MEANS THE OLD BEHAVIOUR for both, so a zero-initialised
    // input -- which is how every test builds one -- is the field and no hero.
    int    cvHeroAlone;
    float2 cvHeroAt;       // m, world x and z of the hero's centre. It does not drift
    float  cvHeroRadius;   // m, its footprint on the base
    float  cvHeroTop;      // m above the base
    float3 cvHeroSeed;     // an offset into billow space: which cauliflower it wears

    // THE HERO'S BILLOWS SCALE WITH IT: amount and lobe size both, by this factor over
    // the field's. A cloud twice a cell's width is built from thermals about twice as
    // big, and with the field's lobes a 4 km hero read as a beehive of small ones.
    float  cvHeroBillow;

    // HOW THE CELLS ARE ARRANGED (build 20): the Organization group, which the hero
    // ignores. Zero is none, for this and for both widths, so a zeroed input is still
    // the field as it was. The widths are the deck's own: see convOrganize.
    Organization cvOrg;
    float  cvGapWidth;     // seams clear where a cell's centre-ness is under this
    float  cvLacunarity;   // 0..1: towards a sheet with round holes

    // PAREIDOLIA (build 21): the hero's silhouette from a picture, as a signed distance
    // map the host built (src/engine/Pareidolia.h). cvShapeOn 0 IS NONE, and then nothing
    // reads the rest -- so a zeroed input is still the hero it always was.
    int    cvShapeOn;
    StructuredBuffer<float> cvShapeMap;   // x * y * 4, row 0 at the bottom: see convShapeTexel
    int2   cvShapeDim;
    float2 cvShapeOffset;    // texel-edge coordinates of the plane's u = 0, y = 0
    float  cvShapeTexel;     // m per texel
    float2 cvShapeAxisU;     // unit, world xz: the plane's u. Its normal is this turned 90
    float  cvShapeRound;     // m: the rims' radius, and half the thickest depth
    float  cvShapeHalfWidth; // m: the silhouette's half width once fitted
    float  cvShapeDecay;     // 0 the shape .. 1 the hero's tower
    float  cvShapeBillow;    // the shape's billows over the hero's, 0..1

    // RELIEF (build 27): the map's fourth float is a depth map, 0..1, and the face towards
    // the eye (+n) stands proud of the cushion by up to cvReliefHeight. 0 IS NONE, and the
    // shape is build 21's to the bit.
    float  cvReliefHeight;   // m
    float  cvReliefSlope;    // m per m across the plane, at most: the bound's
    float  cvReliefFade;     // m inside the silhouette's edge over which the lift comes in

    // HERO CONNECTION (build 22): the towers that tie the hero into the field, and how
    // hard the field's updraft sinks under them. ZERO IS NONE for both, so a zeroed input
    // is still the lone hero. Each turret is (world x, world z, radius, top above the
    // base); the host keeps every one no taller than the hero and no wider, which is what
    // keeps convCeiling the hero's and the billows no bigger than its own.
    float  cvMoat;           // 0..1: how far the field's updraft sinks under the group
    float  cvGroupReach;     // m from cvHeroAt: every turret's reach and every moat ring
    int    cvTurretCount;    // 0..kConvMaxTurrets
    float4 cvTurret0;
    float4 cvTurret1;
    float4 cvTurret2;
    float4 cvTurret3;
    float4 cvTurret4;

    // MAMMA (build 23): pouches hanging from the underside. cvMammaDepth 0 IS NONE, and the
    // base is the flat condensation level it was -- so a zeroed input still has no pouches.
    float  cvMammaDepth;     // m: the deepest a pouch hangs below the base
    float  cvPouchSize;      // m: one pouch's width, the lattice pitch

    // PILEUS AND VELUM (build 24): the hero's cap and veil. A thickness of 0 IS NONE, so a
    // zeroed input has neither.
    float  cvPileusThick;    // m, the cap at its thickest
    float  cvPileusGap;      // m, from the smooth crown to the cap's middle (billows in)
    float  cvVelumThick;     // m, the veil at its thickest
    float  cvVelumHeight;    // m above the base, the veil's middle
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
public static const float kBillowSideFraction = 0.6f;

// ===========================================================================
// THE BILLOWS NEAR THE BASE ARE CAPPED AT A FRACTION OF THE HEIGHT, AND WITHOUT IT THE
// FLAT BASE GROWS A SHEET.
//
// Away from every tower the nearest "surface" the distance below can find is the base
// plane itself, `above` metres down. A billow lifting further than that would turn the
// air just above the base into cloud everywhere -- a ragged mist across the whole
// layer. Holding the lift under kLiftPerHeight x above keeps every point that far from
// a wall clear, whatever the billow says. It is non-decreasing in height, which the
// bound relies on.
// ===========================================================================
public static const float kLiftPerHeight = 0.7f;

// ===========================================================================
// THE STEEPEST THE UPDRAFT CAN BE, PER SLOT WIDTH -- the Lipschitz constant the bound
// divides by.
//
// A kernel vig (1 - d^2/R^2)^2 has slope 4 vig t d / R^2, largest at d = R/sqrt(3):
// 8 / (3 sqrt(3) R). The open field is one short kernel (R = 0.75) over kConvOpenNorm:
// 2.053 / 0.31 = 6.62. The closed field is a difference of two long ones (R = 1.05):
// at most 2 x 1.466 = 2.93. A blend of the two is no steeper than the steeper. Vigour
// is at most one. So 6.62 bounds every gradient convUpdraftGrad returns; 7 is the
// constant, with the margin on the safe side.
// ===========================================================================
public static const float kConvGradMax = 7.0f;

// THERE IS NO FOOTPRINT WARP, AND THERE WAS ONE. It was there to stop the footprints
// being ovals, which a sum of round kernels makes. The two-largest-kernels fields do not:
// their level sets are the cells' own polygonal boundaries. And the warp cost two noise
// evaluations per density evaluation plus a wider box for every bound -- at 0.18 of a
// cell it widened boxes past a cell's width and the bound proved 1.9% of them empty.

// Salts for the lattice hashes. Distinct from the ice generator's, so the two layers'
// cells are unrelated even where their lattices happen to align.
static const uint kConvSaltCentre = 0x68e31da4u;
static const uint kConvSaltLife   = 0xb5297a4du;
static const uint kConvSaltPouch  = 0x2c1b3c6du;
static const uint kConvSaltSag    = 0x7f4a7c15u;

// ---------------------------------------------------------------------------
// One cell
// ---------------------------------------------------------------------------

// THE JITTER ACROSS THE ROWS SHRINKS WITH COHERENCE, and every layout that allows was
// one the full jitter allowed already, so the 3x3 argument above only gets more room.
public float2 convCellCentre(ConvectionInput c, int2 slot)
{
    float2 j = hash22(slot, kConvSaltCentre) - 0.5f;
    return float2(slot) + 0.5f + j * orgJitter(c.cvOrg, kConvJitter);
}

// ...and the same centre with no organization, for the unorganized updraft's own loop.
float2 convCellCentrePlain(int2 slot)
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
// THE UPDRAFT AND ITS GRADIENT, per metre. The gradient is what turns "how far below
// the top" into "how far from the wall": see convSurfaceDistance. It is exact wherever
// the kernels' order does not change, which is almost everywhere; where it does, the
// field has a crease and either side's slope is an honest answer.
//
// THREE SPECIALISATIONS, CHOSEN ONCE PER CALL: ORG 0 is the field before build 20, with
// none of the Organization group's code in it; ORG 1 is organized without Lacunarity; ORG
// 2 carries Lacunarity's holes through the lattice loop as well. MEASURED: with one body
// serving all, the default scenes were 4% slower with the group switched OFF, and the
// organized path at its identity cost 15% -- state carried through the lattice loop costs
// registers in the hottest function there is, whether or not a branch is taken.
public float convUpdraftGrad(ConvectionInput c, float2 q, out float2 grad)
{
    if (c.cvOrg.ogOn == 0)       return convUpdraftGradT<0>(c, q, grad);
    if (c.cvLacunarity <= 0.0f)  return convUpdraftGradT<1>(c, q, grad);
    return convUpdraftGradT<2>(c, q, grad);
}

float convUpdraftGradT<let ORG : int>(ConvectionInput c, float2 q, out float2 grad)
{
    float2 g  = ORG != 0 ? orgPattern(c.cvOrg, q, c.cvSpacing) : q / c.cvSpacing;
    int2   gi = int2(floor(g));

    float oTop = 0.0f, oNext = 0.0f;   // the short kernels' two largest: the rims
    float kTop = 0.0f, kNext = 0.0f;   // the long kernels' two largest: the centres
    float2 goTop = float2(0.0f, 0.0f), goNext = float2(0.0f, 0.0f);
    float2 gkTop = float2(0.0f, 0.0f), gkNext = float2(0.0f, 0.0f);

    float ro2 = kConvReachOpen * kConvReachOpen;
    float rk2 = kConvReachClosed * kConvReachClosed;

    // LACUNARITY'S HOLES, one round one per cell: the least of the cells' factors here.
    float  keep  = 1.0f;
    float2 gKeep = float2(0.0f, 0.0f);

    for (int j = -1; j <= 1; ++j)
    {
        for (int i = -1; i <= 1; ++i)
        {
            int2 slot = gi + int2(i, j);

            float vig = convVigour(c, slot);
            if (vig <= 0.0f) continue;

            float2 d  = g - (ORG != 0 ? convCellCentre(c, slot) : convCellCentrePlain(slot));
            float  d2 = dot(d, d);
            float  ko = vig * convBump(d2, kConvReachOpen);
            float  kk = vig * convBump(d2, kConvReachClosed);

            if (ORG == 2) convHole(c, d, d2, vig, keep, gKeep);

            // d/dg of vig (1 - d2/R2)^2 is -4 vig (1 - d2/R2) d / R2.
            float2 gko = d2 < ro2 ? d * (-4.0f * vig * (1.0f - d2 / ro2) / ro2) : float2(0.0f, 0.0f);
            float2 gkk = d2 < rk2 ? d * (-4.0f * vig * (1.0f - d2 / rk2) / rk2) : float2(0.0f, 0.0f);

            if (ko > oTop) { oNext = oTop; goNext = goTop; oTop = ko; goTop = gko; }
            else if (ko > oNext) { oNext = ko; goNext = gko; }

            if (kk > kTop) { kNext = kTop; gkNext = gkTop; kTop = kk; gkTop = gkk; }
            else if (kk > kNext) { kNext = kk; gkNext = gkk; }
        }
    }

    float openRaw     = oNext / kConvOpenNorm;
    float openField   = min(openRaw, 1.0f);
    float closedField = kTop - kNext;

    float2 gOpen   = openRaw < 1.0f ? goNext / kConvOpenNorm : float2(0.0f, 0.0f);
    float2 gClosed = gkTop - gkNext;

    if (ORG != 0)
    {
        return convOrganize(c, q, kTop, kNext, gkTop, gkNext, keep, gKeep,
                            lerp(openField, closedField, c.cvPolarity),
                            lerp(gOpen, gClosed, c.cvPolarity), grad);
    }

    // Per slot width, to per metre.
    grad = lerp(gOpen, gClosed, c.cvPolarity) / c.cvSpacing;
    return lerp(openField, closedField, c.cvPolarity);
}

// ===========================================================================
// THE ORGANIZATION GROUP'S LAST STEP: gaps, holes and the wave, on an updraft `w` whose
// gradient in lattice units is `gp`. Returns the organized updraft and its gradient per
// metre. kTop, kNext and their gradients are the long kernels' two largest at the point.
//
// A CELL'S CENTRE-NESS is 1 - kNext / kTop: near one at a cell's centre, where its own
// kernel is alone, and zero on the seam between two cells, where the two largest are
// equal. It does not care how vigorous the cell is, which is what makes a threshold on
// it the same shape of gap or hole in every cell.
//
//   LACUNARITY     turns the layer into a THIN SHEET WITH ROUND HOLES, one per cell.
//                  It blends the updraft towards kConvSheetLevel everywhere, which fills
//                  the seams, and multiplies by each cell's hole: a disc of radius
//                  kConvHoleRadius x lacunarity x vigour^(1/4) round its centre, soft over
//                  its outer (1 - kConvHoleEdge). Lacunosus. THREE VERSIONS WERE MEASURED
//                  OR SEEN WRONG FIRST: holes punched in the deck alone left 0.8% of it,
//                  because a closed deck's cloud is at its centres; a blend towards a
//                  holed sheet of kTop opened no hole below about 0.8 on the slider; and
//                  with kTop as the sheet, which carries each cell's vigour through its
//                  life, the render was shards and pits rather than a sheet.
//                  THE RADIUS SHRINKS TO NOTHING WITH ITS CELL'S VIGOUR, so a hole closes
//                  as its cell dies and opens from nothing, rather than popping. As the
//                  fourth root, not the square root: SEEN at the square root, most holes
//                  were smaller than the billows and closed, and a frame with dozens of
//                  cells showed half a dozen holes.
//   GAP FRACTION   clears the seams: a factor of 0 up to kConvGapStart of cvGapWidth,
//                  rising to 1 at cvGapWidth. Distinct cells with sky between them --
//                  perlucidus. THE CLEAR BAND IS THE POINT: the closed updraft is already
//                  kTop x centre-ness, so a ramp starting from zero only squared what was
//                  there, and MEASURED, the widest such gap took a closed deck from 72%
//                  cloud to 64%. SCALED BY POLARITY, because open cells' cloud IS the
//                  seams: a gap there would erase the rims, so on open cells it does
//                  nothing and it comes in with the deck.
//
// THE BOUND STILL HOLDS, and only the sheet needed anything for it. The holes, the gap and
// the wave are factors of at most one; the sheet is a constant, so the blend is at most
// the same blend of the updraft's bound and it (convUpdraftBound). The slope is a
// different matter; see convSlopeCap.
// ===========================================================================

// THE SHEET IS THIN: its towers stand at about a third of the room under the lid. At the
// deck's full height, 830 m in the test scene, its holes seen from above were deep pits
// with sunlit walls. Lacunosus is a thin layer.
public static const float kConvSheetLevel = 0.4f;

// ...AND WEARS SMALLER BILLOWS: at full lacunarity, (1 - this) of the field's. A billow as
// big as a tower's on a sheet a third as thick filled every hole narrower than itself.
public static const float kConvSheetBillowCut = 0.6f;

// A full-vigour cell's hole at full lacunarity, in lattice units: nearly touching its
// neighbours', which is a net. Each is fully open inside kConvHoleEdge of its radius.
public static const float kConvHoleRadius = 0.5f;
public static const float kConvHoleEdge   = 0.7f;

public static const float kConvGapStart  = 0.5f;

// Per lattice unit: w |grad centre-ness| is at most kConvCentreSlope, since centre-ness
// moves at most (|grad kNext| + |grad kTop|) / kTop <= 2 x 1.466 / kTop and w is at most
// kTop / kConvOpenNorm, each short kernel being under its cell's long one.
public static const float kConvCentreSlope = 9.5f;

// One cell's hole at offset d (lattice units) from its centre, folded into the least
// factor so far and its gradient.
void convHole(ConvectionInput c, float2 d, float d2, float vig,
              inout float keep, inout float2 gKeep)
{
    float r = kConvHoleRadius * c.cvLacunarity * sqrt(sqrt(vig));
    if (!(d2 < r * r)) return;

    float dist  = sqrt(d2);
    float inner = kConvHoleEdge * r;
    float band  = r - inner;
    float t     = saturate((dist - inner) / band);
    float k     = t * t * (3.0f - 2.0f * t);
    if (k < keep)
    {
        keep  = k;
        gKeep = dist > 1e-6f ? d * (6.0f * t * (1.0f - t) / (band * dist)) : float2(0.0f, 0.0f);
    }
}

float convOrganize(ConvectionInput c, float2 q, float kTop, float kNext, float2 gkTop,
                   float2 gkNext, float keep, float2 gKeep, float w, float2 gp,
                   out float2 grad)
{
    if (c.cvLacunarity > 0.0f)
    {
        // Fill the seams towards the sheet, then open the holes in what that leaves.
        float  fill  = lerp(w, kConvSheetLevel, c.cvLacunarity);
        float2 gFill = gp * (1.0f - c.cvLacunarity);
        gp = gFill * keep + gKeep * fill;
        w  = fill * keep;
    }

    if (c.cvPolarity > 0.0f && c.cvGapWidth > 0.0f)
    {
        float  cn  = 0.0f;
        float2 gcn = float2(0.0f, 0.0f);
        if (kTop > 0.0f)
        {
            cn  = 1.0f - kNext / kTop;
            gcn = (gkTop * kNext - gkNext * kTop) / (kTop * kTop);
        }

        float ramp = (1.0f - kConvGapStart) * c.cvGapWidth;
        float t  = saturate((cn - kConvGapStart * c.cvGapWidth) / ramp);
        float f  = t * t * (3.0f - 2.0f * t);
        float df = 6.0f * t * (1.0f - t) / ramp;

        // Polarity's share: open cells keep all their cloud.
        float s  = lerp(1.0f, f, c.cvPolarity);
        float ds = df * c.cvPolarity;
        gp = gp * s + gcn * (w * ds);
        w  = w * s;
    }

    grad = orgGradToWorld(c.cvOrg, gp, c.cvSpacing);

    float2 gm;
    float  m = orgWave(c.cvOrg, q, gm);
    grad = grad * m + gm * w;
    return w * m;
}

// ===========================================================================
// THE STEEPEST SLOPE THE DENSITY WILL USE, per metre, and the one the bound divides by.
//
// WITHOUT ORGANIZATION it is kConvGradMax per slot, the proved bound on the updraft's
// gradient, and the density's clamp to it never bites.
//
// WITH IT, the sheet, gaps and wave steepen the updraft, and Chaotic's warp bends it by
// a Jacobian the gradient leaves out. So the density CLAMPS the slope it uses to this,
// and the bound divides by the same number. That makes the bound sound by construction,
// whatever the true slope: the density's distance to a wall is |v delta| /
// sqrt(v^2 G^2 + delta^2), which only grows as G is lowered, and the bound's floor is
// that expression at G = this cap. The terms added are the true slope's own bounds, so
// the clamp stays a no-op everywhere but the warp:
//
//   holes    1.5 over the edge band of the smallest hole the cap covers, a cell at
//            kConvHoleVigourFloor of full vigour. Smaller holes, of dying cells, are
//            steeper than this and are clamped to it, which is what the clamp is for.
//   gaps     1.5 over the gap's ramp of centre-ness, times kConvCentreSlope, times polarity
//   wave     3 x amplitude x |k|, see orgWave
//
// A stretch only lengthens the cells, so each per-slot slope over the spacing still
// covers its term.
// ===========================================================================
public static const float kConvHoleVigourFloor = 0.1f;

public float convSlopeCap(ConvectionInput c)
{
    float cap = kConvGradMax / c.cvSpacing;
    if (c.cvOrg.ogOn == 0) return cap;

    if (c.cvLacunarity > 0.0f)
        cap += 1.5f / ((1.0f - kConvHoleEdge) * kConvHoleRadius * c.cvLacunarity
                       * sqrt(sqrt(kConvHoleVigourFloor)) * c.cvSpacing);
    if (c.cvGapWidth > 0.0f)
        cap += kConvCentreSlope * 1.5f * c.cvPolarity
             / ((1.0f - kConvGapStart) * c.cvGapWidth * c.cvSpacing);
    cap += 3.0f * c.cvOrg.ogWaveAmp * length(c.cvOrg.ogWaveK);
    return cap;
}

public float convUpdraft(ConvectionInput c, float2 q)
{
    float2 unused;
    return convUpdraftGrad(c, q, unused);
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

// The updraft a column needs to reach `above`: convTowerHeight's inverse. Past the
// tallest tower it keeps climbing past one, which no updraft reaches, so a point over
// every top is outside by a positive margin rather than on a surface.
public float convNeededUpdraft(ConvectionInput c, float above)
{
    float cover = clamp(c.cvCoverage, 0.0f, 1.0f);
    if (cover <= 0.0f || c.cvDepth <= 0.0f) return 1e9f;

    float span = sqrt(cover);
    float u = pow(max(above, 0.0f) / c.cvDepth, 1.0f / max(c.cvShape, 1e-3f));
    return (1.0f - span) + span * u;
}

// ===========================================================================
// HOW FAR A POINT IS FROM THE CLOUD'S SURFACE: positive inside, negative outside.
//
// THE OLD MEASURE WAS VERTICAL ONLY -- tower minus height -- and that is why tall towers
// rendered as smooth pillars. A billow adds to this number, and on a steep wall the
// vertical distance to the top is hundreds of metres while the wall is a few metres
// away, so no billow could move it. The crown got cauliflower and the walls got none.
//
// So both distances are taken, `v` down to the top and `h` across to the wall, and
// combined as the distance to the plane through both intercepts:
//
//     d = sign(v) |v h| / sqrt(v^2 + h^2)
//
// On a flat crown h is huge and d is v, as before. On a wall v is huge and d is h. The
// two always share a sign, since a point is under the top exactly where the updraft
// beats what that height needs. |d| is at most min(|v|, |h|), which the bound uses.
//
// FOR THE FIELD, h is the updraft's shortfall over its slope: delta / G. Written without
// the division, so a flat updraft (G = 0) gives d = v rather than a NaN.
// ===========================================================================
public float convSurfaceDistance(float v, float delta, float slope)
{
    float num = abs(v * delta);
    float den = sqrt(v * v * slope * slope + delta * delta);
    if (den <= 1e-20f) return 0.0f;
    float d = num / den;
    return v >= 0.0f ? d : -d;
}

// The same combination as a floor: every point whose |v| >= vMin and |h| >= hMin is at
// least this far from the surface.
public float convDistanceFloor(float vMin, float hMin)
{
    if (vMin <= 0.0f || hMin <= 0.0f) return 0.0f;
    return 1.0f / sqrt(1.0f / (vMin * vMin) + 1.0f / (hMin * hMin));
}

// ---------------------------------------------------------------------------
// The hero
// ---------------------------------------------------------------------------
//
// ONE TOWER, ANALYTIC: height cvHeroTop (1 - (r/R)^2)^shape over a round footprint of
// radius R. The same exponent as the field, so it is as steep-sided as the field's
// towers at the same instability. Because the profile inverts in closed form, h is the
// true horizontal distance to the wall, not an estimate.

// ANY DOME OF THE FAMILY: the hero, and since build 22 the turrets of its group. The
// hero's two functions below are these with its own numbers, the same arithmetic in the
// same order, so the lone hero renders to the bit what it did.
public float convDomeHeight(float top, float radius, float shape, float r)
{
    if (top <= 0.0f || r >= radius) return 0.0f;
    float t = 1.0f - (r * r) / (radius * radius);
    return top * pow(t, shape);
}

// A dome's radius at height `above`, or -1 above its top.
public float convDomeRadiusAt(float top, float radius, float shape, float above)
{
    if (top <= 0.0f || above >= top) return -1.0f;
    float f = pow(max(above, 0.0f) / top, 1.0f / max(shape, 1e-3f));
    return radius * sqrt(max(1.0f - f, 0.0f));
}

public float convHeroHeight(ConvectionInput c, float r)
{
    return convDomeHeight(c.cvHeroTop, c.cvHeroRadius, c.cvShape, r);
}

// The hero's radius at height `above`, or -1 above its top.
public float convHeroRadiusAt(ConvectionInput c, float above)
{
    return convDomeRadiusAt(c.cvHeroTop, c.cvHeroRadius, c.cvShape, above);
}

// The highest anything in the layer reaches above the base, billows included: the
// field's tallest tower plus its billow, or the hero's plus its own. The slab's top.
public float convCeiling(ConvectionInput c)
{
    float field = c.cvDepth + c.cvBillow;
    float hero  = c.cvHeroTop > 0.0f ? c.cvHeroTop + c.cvBillow * c.cvHeroBillow : 0.0f;
    return max(max(field, hero), convCapCeiling(c));
}

// THE CAP AND THE VEIL'S TOPS (build 24), or zero without them: see convCapDensity. The
// veil's hump near the tower is at most half its thickness, so a whole thickness covers it.
public float convCapCeiling(ConvectionInput c)
{
    if (c.cvHeroTop <= 0.0f) return 0.0f;
    float cap  = c.cvPileusThick > 0.0f ? c.cvHeroTop + c.cvPileusGap + c.cvPileusThick : 0.0f;
    float veil = c.cvVelumThick > 0.0f ? c.cvVelumHeight + 1.5f * c.cvVelumThick : 0.0f;
    return max(cap, veil);
}

// How far outside its footprint the hero can put cloud: the side billows' reach, which
// is under 1.5x the lift once the base cap holds (see kLiftPerHeight), plus the soft
// edge. The host sizes the layer's horizontal box from the same number, and the density
// is zero outside that box, so this is the definition rather than an estimate.
public float convHeroReach(ConvectionInput c)
{
    return c.cvHeroRadius + 1.5f * c.cvBillow * c.cvHeroBillow + 2.0f * kConvEdgeSoft;
}

// THE SHAPE'S REACH, the same way. A point is outside the shape by at least how far it is
// past the silhouette's box across the plane, and by at least how far it is past the rims
// along the normal (see convShapeProfile) -- the front's rims lifted by the relief, at
// most cvReliefHeight -- so once both are more than the billows can lift, it is clear. The
// host's box uses the same arithmetic (SlangBridge.h).
public float convShapeReach(ConvectionInput c)
{
    float lift = 1.5f * c.cvBillow * c.cvHeroBillow + 2.0f * kConvEdgeSoft;
    float2 corner = float2(c.cvShapeHalfWidth + lift, c.cvShapeRound + c.cvReliefHeight + lift);
    return length(corner);
}

// The tower's reach or the shape's, whichever is further: Decay blends the two, and a
// blend is never out past both.
public float convHeroReachAll(ConvectionInput c)
{
    float reach = convHeroReach(c);
    return c.cvShapeOn != 0 ? max(reach, convShapeReach(c)) : reach;
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
// ===========================================================================
// EACH OCTAVE'S LATTICE IS TURNED, because a wall shows the lattice's rows.
//
// The puffs' feature points are jittered by only a quarter of a cell -- that is what
// makes the eight-cell search exact -- so the lattice is regular enough to read. Seen
// from above it never did; on a tower's wall, once the billows reached the sides, it
// read as horizontal bands a lattice cell apart, like a beehive. An oblique rotation
// per octave puts the rows at an angle no wall shares, and each octave at a different
// one. It is orthonormal (this is the rotation from Quilez's value-noise fbm), so the
// puffs keep their size and the eight-cell argument is untouched.
// ===========================================================================
float3 convTwist(float3 x)
{
    return float3( 0.00f * x.x + 0.80f * x.y + 0.60f * x.z,
                  -0.80f * x.x + 0.36f * x.y - 0.48f * x.z,
                  -0.60f * x.x - 0.48f * x.y + 0.64f * x.z);
}

// `scale` is the largest lobe, in metres: the field's billow scale, or the hero's.
public float convBillow(ConvectionInput c, float3 p, float scale)
{
    float3 x = float3(p.x, p.y - c.cvRise, p.z) / scale;

    float sum = 0.0f, amp = 0.6f, norm = 0.0f;
    for (int i = 0; i < 4; ++i)
    {
        if (i >= c.cvOctaves) break;
        x     = convTwist(x);
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
// `k` scales the billow amount: one for the field, cvHeroBillow for the hero. It scales
// before the base cap, so the cap holds for both.
public float convLift(ConvectionInput c, float above, float k)
{
    float up = saturate(above / max(c.cvDepth, 1.0f));
    float lift = c.cvBillow * k * smoothstep(0.0f, kConvBaseFade, above)
               * lerp(kBillowSideFraction, 1.0f, up);
    return min(lift, kLiftPerHeight * max(above, 0.0f));
}

// How far inside the cloud a point is once the billows have had their say, given its
// distance `d` from the smooth surface and the most the billows can move it. The billow
// is the expensive part, so it is only evaluated in the shell where it can matter.
// `x` is the point in the billow pattern's own frame.
float convInside(ConvectionInput c, float d, float lift, float3 x, float scale)
{
    if (d + lift <= 0.0f) return d + lift;             // no billow reaches out this far
    if (d - lift >= kConvEdgeSoft) return kConvEdgeSoft;  // nor bites in this far
    return d + lift * convBillow(c, x, scale);
}



// ---------------------------------------------------------------------------
// Density
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pareidolia: the hero as a picture
// ---------------------------------------------------------------------------
//
// ===========================================================================
// THE SHAPE IS A VERTICAL PLANE THROUGH THE HERO'S CENTRE, INFLATED.
//
// The host's map holds, per texel, the signed distance D to the silhouette's edge in the
// plane -- positive inside -- and its slope. The plane's frame is (u, y, n): u across it
// (cvShapeAxisU), y height above the base, n along its normal. A point is in the cloud when
// its (D, m = |n|) lies in the ROUNDED-RIM PROFILE: the disc of radius R centred R inside
// the edge, and past it the strip m < R. So a disc of radius R becomes a sphere, a narrow
// stroke a tube, and a wide region a cushion 2R deep with rounded rims.
//
// THE DISTANCE TO THE SHAPE IS THE 2D DISTANCE TO THE PROFILE, in closed form, with the
// same sign inside and out and no slope that runs away at the rim -- which is what a
// thickness height field does, and the billows would show it as a seam round the
// silhouette.
//
// RELIEF (build 27) IS NOT THAT HEIGHT FIELD. It lifts the front half's distance from the
// plane, so the whole round profile moves out towards the eye by the lift, rim included;
// and the lift fades in from the silhouette's edge, so it is zero where the rim is. The
// distance stays the profile's, continuous everywhere. On a steep relief it overstates
// the true distance by up to sqrt(1 + slope^2), which only makes the billows there a
// little shallower -- the host's blur keeps the slope gentle.
// ===========================================================================

// kShapeLipschitz: how fast D can change per metre, map and extension together. Adjacent
// texels of an exact distance map differ by at most one, so the bilinear slope is at most
// one along each axis, sqrt(2) in all; the linear extension past the map adds at most one
// more by the triangle inequality. The bound takes 2.5.
public static const float kShapeLipschitz = 2.5f;

// The shape's billow lobes never shrink below this fraction of the hero's, however low
// Shape Billows goes: at zero there is no billow to size, and just above it a lobe of a
// few metres would be grain on the surface rather than cauliflower.
public static const float kShapeLobeFloor = 0.3f;

// Texel (i, j) of the map: distance in texels, its slopes along u and y, and the relief.
float4 convShapeTexel(ConvectionInput c, int i, int j)
{
    int k = (j * c.cvShapeDim.x + i) * 4;
    return float4(c.cvShapeMap[k], c.cvShapeMap[k + 1], c.cvShapeMap[k + 2], c.cvShapeMap[k + 3]);
}

// THE SIGNED DISTANCE TO THE SILHOUETTE'S EDGE, in metres, at plane point (u, y), and its
// slope. Bilinear inside the map. Past it, the value at the nearest map point less the
// distance out: continuous, and never nearer the shape than the truth, since D changes by
// at most a metre per metre -- the host's margin keeps the silhouette well inside.
//
// `relief` IS THE DEPTH MAP THERE, 0..1, bilinear too, and past the map the nearest map
// point's: clamping is a projection, so its slope never exceeds the map's own, which is
// what cvReliefSlope bounds. Zero everywhere when there is no relief.
public float convShapeDistance(ConvectionInput c, float u, float y, out float2 slopeUY,
                               out float relief)
{
    float2 st   = float2(u, y) / c.cvShapeTexel + c.cvShapeOffset - 0.5f;
    int2   last = c.cvShapeDim - int2(1, 1);
    float2 q    = clamp(st, float2(0.0f, 0.0f), float2(last));
    float  past = length(st - q);

    float2 f0 = floor(q);
    int2   i0 = min(int2(f0), last);
    int2   i1 = min(i0 + int2(1, 1), last);
    float2 fr = q - f0;

    float4 s00 = convShapeTexel(c, i0.x, i0.y);
    float4 s10 = convShapeTexel(c, i1.x, i0.y);
    float4 s01 = convShapeTexel(c, i0.x, i1.y);
    float4 s11 = convShapeTexel(c, i1.x, i1.y);
    float4 blend = lerp(lerp(s00, s10, fr.x), lerp(s01, s11, fr.x), fr.y);

    slopeUY = blend.yz;
    relief  = blend.w;
    return (blend.x - past) * c.cvShapeTexel;
}

// HOW FAR THE FRONT FACE STANDS PROUD at a point `dIn` metres inside the silhouette where the
// depth map reads `relief`: the relief's height, FADED IN FROM THE EDGE over cvReliefFade,
// a quarter of the rims' radius at most, so the silhouette's edge does not stand as a
// sheer wall. Never more than cvReliefHeight * relief, which is all the bound takes.
//
// SHORT ON PURPOSE, AND THAT IS A MEASUREMENT (build 28). Build 27 faded over the relief's
// whole height, which on a 2.2 km face with Relief Depth 0.5 was 1.1 km -- the face's
// half width. It kept 38% of the depth map and replaced the rest with a ridge down the
// middle: the nose of a three-quarter face, which sits on the outline, was gone. A
// quarter of the rims kept 91%.
public float convReliefLift(ConvectionInput c, float dIn, float relief)
{
    return c.cvReliefHeight * relief * smoothstep(0.0f, max(c.cvReliefFade, 1.0f), dIn);
}

// THE ROUNDED RIM IN ITS OWN TWO DIMENSIONS: a point `dIn` metres inside the silhouette and
// `m` from the plane, against the profile. Returns its distance OUT of the profile --
// negative inside -- and the step (along D, along m) to the profile's nearest point.
//
// MONOTONE, which the bound relies on: never increasing in dIn (deeper in the silhouette is
// never further out of the cloud) and never decreasing in m.
public float convShapeProfile(float dIn, float m, float rimR, out float2 stepDM)
{
    if (dIn >= rimR)
    {
        stepDM = float2(0.0f, rimR - m);   // under the cushion's face: straight to it
        return m - rimR;
    }
    float2 w   = float2(dIn - rimR, m);
    float  len = length(w);
    float  gap = len - rimR;
    stepDM = len > 1e-6f ? w * (-gap / len) : float2(0.0f, rimR);
    return gap;
}

// The shape's distance to its surface, positive inside, and the billow read point at the
// surface's nearest point -- in the PLANE'S frame (u, height, n) about the hero's centre,
// height absolute, as the tower's is in its own. `plane` is the point's (u, n).
float convShapeSurface(ConvectionInput c, float2 plane, float py, float above, out float3 x)
{
    float2 slopeUY;
    float  relief;
    float  dIn = convShapeDistance(c, plane.x, above, slopeUY, relief);

    // RELIEF (build 27): IN FRONT, the distance from the plane counts from the lifted face,
    // so the whole profile -- rim and face -- moves out towards the eye by the lift, and the
    // slab between the plane and it is solid. Continuous at the plane, where both sides
    // read zero. Behind, the cushion as it was.
    float m = abs(plane.y);
    if (c.cvReliefHeight > 0.0f && plane.y > 0.0f)
        m = max(plane.y - convReliefLift(c, dIn, relief), 0.0f);

    float2 stepDM;
    float  gap  = convShapeProfile(dIn, m, c.cvShapeRound, stepDM);
    float  side = plane.y >= 0.0f ? 1.0f : -1.0f;

    // Along the silhouette's own gradient for the in-plane part of the step. The slope is
    // interpolated from central differences, so it is continuous, and it fades to nothing
    // across a stroke's middle, where the two edges' gradients cancel -- which keeps the
    // read point from jumping from one side of a thin stroke to the other.
    x = float3(plane.x + stepDM.x * slopeUY.x,
               py + stepDM.x * slopeUY.y,
               plane.y + side * stepDM.y);
    return -gap;
}

// A dome's distance to its surface, positive inside, and its billow read point relative
// to the dome's centre, in whatever horizontal frame `rel` is given in. The same surface
// point as the field's, from the closed form: up by v to the crown, out along the radius by
// h to the wall.
float convDomeSurface(float top, float radius, float shape, float2 rel, float r, float py,
                      float above, out float3 x)
{
    float v  = convDomeHeight(top, radius, shape, r) - above;
    float ra = convDomeRadiusAt(top, radius, shape, above);
    float d, shiftUp, shiftOut;
    if (ra < 0.0f)
    {
        d = v; shiftUp = v; shiftOut = 0.0f;   // over the top: straight down to it
    }
    else
    {
        float h = ra - r;
        d = convSurfaceDistance(v, h, 1.0f);
        shiftUp  = abs(v) > 1e-6f ? d * (d / v) : 0.0f;
        shiftOut = abs(h) > 1e-6f ? d * (d / h) : 0.0f;
    }
    float2 radial = r > 1e-3f ? rel / r : float2(0.0f, 0.0f);
    float2 at = rel + radial * shiftOut;
    x = float3(at.x, py + shiftUp, at.y);
    return d;
}

// The hero's tower: the dome with its own numbers.
float convTowerSurface(ConvectionInput c, float2 rel, float r, float py, float above,
                       out float3 x)
{
    return convDomeSurface(c.cvHeroTop, c.cvHeroRadius, c.cvShape, rel, r, py, above, x);
}

// ---------------------------------------------------------------------------
// The hero's group (build 22)
// ---------------------------------------------------------------------------
//
// ===========================================================================
// TURRETS: MORE DOMES OF THE HERO'S FAMILY, placed by the host (heroGroup in
// ConvectionField.h) on the hero's shoulders and in a flanking line into the wind. Each
// is the closed-form dome, so it has the hero's exponent, flat base and exact wall
// distance, and its union with the hero is a hard one -- turrets meet in creases, as
// thermals do.
//
// ONE BILLOW FRAME FOR THE WHOLE GROUP: each turret reads the hero's cauliflower, about
// the hero's centre and with its seed, at its own nearest surface point. So Hero
// Variation changes every turret's lobes with the hero's, and a turret's billows are
// those of the same cloud rather than a second one's.
//
// THEIR LOBES ARE SIZED BETWEEN THE FIELD'S AND THE HERO'S by radius, and never past the
// hero's. That is the middle size the frame was missing -- and, with every top at most
// the hero's, it is what keeps the group under convCeiling without a loop in it.
// ===========================================================================
public static const int kConvMaxTurrets = 5;

public float4 convTurret(ConvectionInput c, int k)
{
    if (k == 0) return c.cvTurret0;
    if (k == 1) return c.cvTurret1;
    if (k == 2) return c.cvTurret2;
    if (k == 3) return c.cvTurret3;
    return c.cvTurret4;
}

// A turret's billows over the field's, amount and lobe size together.
public float convTurretBillow(ConvectionInput c, float radius)
{
    float small = min(1.0f, c.cvHeroBillow);
    return lerp(small, c.cvHeroBillow, saturate(radius / max(c.cvHeroRadius, 1.0f)));
}

// How far past its footprint a turret can put cloud: convHeroReach's arithmetic, AT THE
// HERO'S BILLOW FACTOR rather than the turret's own. That is never nearer, and it leaves
// the division out of a test every point near the group pays five times. Density and
// bound compare SQUARES against it, the same squares, so they agree on it to the bit.
public float convTurretReach(ConvectionInput c, float4 t)
{
    return t.z + 1.5f * c.cvBillow * c.cvHeroBillow + 2.0f * kConvEdgeSoft;
}

// A TURRET'S SMOOTH SURFACE: its distance, positive inside, and its billow read point in
// the hero's billow frame -- about the hero's centre, and turned into the picture's plane
// when a shape is on, which is the frame the hero reads its own in. `k` is its billows
// over the field's. False beyond its reach, or over its top by more than any billow
// lifts: d is at most top - above there, so it is outside, and the dome's two pows are
// not paid. Most points near the hero's upper surface are there -- every turret is lower.
bool convTurretSmooth(ConvectionInput c, float4 t, float3 p, float above, out float d,
                      out float3 x, out float k)
{
    d = -1e30f;
    x = float3(0.0f, 0.0f, 0.0f);
    k = 1.0f;

    float2 rel   = p.xz - t.xy;
    float  r2    = dot(rel, rel);
    float  reach = convTurretReach(c, t);
    if (r2 >= reach * reach) return false;
    if (above >= t.w + c.cvBillow * c.cvHeroBillow) return false;

    float  r = sqrt(r2);
    float3 own;
    k = convTurretBillow(c, t.z);
    d = convDomeSurface(t.w, t.z, c.cvShape, rel, r, p.y, above, own);

    float3 w = own + float3(t.x - c.cvHeroAt.x, 0.0f, t.y - c.cvHeroAt.y);
    if (c.cvShapeOn != 0)
    {
        float2 axisN = float2(-c.cvShapeAxisU.y, c.cvShapeAxisU.x);
        w = float3(dot(w.xz, c.cvShapeAxisU), w.y, dot(w.xz, axisN));
    }
    x = w;
    return true;
}

// ===========================================================================
// THE GROUP IS ONE SURFACE WITH ONE CAULIFLOWER (build 22), and that is a measurement.
//
// The first version gave every turret its own billow and took the hard union of the
// billowed towers. Near the group the density then cost 2.5x what it did without it:
// the billow is the whole cost of a density evaluation, and a point in the shells of
// three towers paid three. Taking the billows away from the turrets alone took two
// thirds of that back.
//
// So the towers' SMOOTH surfaces are taken first, which is cheap, and the billow once:
// D is the largest of their distances -- the union of the smooth towers -- and the read
// point, lift and lobe are a softmax of theirs over kGroupBlend, weighted to the nearest
// surface. On a crease both read points are near the point itself, so the blend barely
// moves; away from one it is the other's alone. Continuous everywhere, so no seam, and
// the tower-level crease becomes one more crease in a single cauliflower rather than
// two cauliflowers cutting through each other.
//
// THE BOUND: convInside is at most D + lift, D is at most the largest of the towers'
// distance bounds, and a weighted mean of lifts is at most the largest. So the group's
// bound is the largest distance part plus the largest lift -- see convectionBound.
//
// ONLINE, as a softmax is: the weights are rescaled when a larger distance arrives, so
// one pass over the towers keeps nothing per tower.
// ===========================================================================
public static const float kGroupBlend = 50.0f;   // m

void convGroupFold(float d, float3 x, float lift, float lobe, inout float gMax,
                   inout float gSum, inout float3 gX, inout float gLift, inout float gLobe)
{
    if (d > gMax)
    {
        float scale = exp((gMax - d) / kGroupBlend);
        gSum  *= scale;
        gX    *= scale;
        gLift *= scale;
        gLobe *= scale;
        gMax   = d;
    }
    float wt = exp((d - gMax) / kGroupBlend);
    gSum  += wt;
    gX    += wt * x;
    gLift += wt * lift;
    gLobe += wt * lobe;
}

// ===========================================================================
// THE MOAT: THE FIELD'S UPDRAFT SINKS UNDER THE GROUP.
//
// Round every tower of the group, the hero included, a factor on the field's updraft:
// zero inside kMoatInner of its radius, rising smoothly to one at kMoatOuter. The least of
// them, blended by cvMoat from none to all of it. A field cell centred under a tower is
// gone; one at its edge is shrunk to a small cloud against its wall, which is where the
// field's clouds merge with the group; one farther out is untouched. It is the
// compensating subsidence round a vigorous updraft, and it is what stops a field tower
// growing out through the hero's wall.
//
// THE BOUND IS UNTOUCHED: the factor is at most one and the updraft is not negative, so
// the updraft's bound still bounds it. THE SLOPE IS NOT: the factor's own slope times an
// updraft of at most one adds at most 1.5 / band per metre, only inside a ring. So the
// density clamps to the cap plus that term where it is in a ring, and the bound divides by
// the cap plus the largest term of any ring its box reaches -- the same argument as
// convSlopeCap's, made per ring rather than for the whole sky, so the rest of the field's
// bound is exactly what it was.
// ===========================================================================
public static const float kMoatInner = 0.75f;
public static const float kMoatOuter = 1.3f;

void convMoatRing(float2 xz, float2 at, float radius, inout float s, inout float2 gs,
                  inout float slope)
{
    float2 d  = xz - at;
    float  r2 = dot(d, d);
    float  outer = kMoatOuter * radius;
    if (!(r2 < outer * outer)) return;

    float band  = outer - kMoatInner * radius;
    float inner = outer - band;
    slope = max(slope, 1.5f / band);

    float r = sqrt(r2);
    float t = saturate((r - inner) / band);
    float f = t * t * (3.0f - 2.0f * t);
    if (f < s)
    {
        s  = f;
        gs = r > 1e-3f ? d * (6.0f * t * (1.0f - t) / (band * r)) : float2(0.0f, 0.0f);
    }
}

// The factor on the field's updraft at world point xz, its gradient per metre, and what it
// adds to the slope cap there.
public float convMoat(ConvectionInput c, float2 xz, out float2 grad, out float slopeAdd)
{
    float  s     = 1.0f;
    float2 gs    = float2(0.0f, 0.0f);
    float  slope = 0.0f;
    convMoatRing(xz, c.cvHeroAt, c.cvHeroRadius, s, gs, slope);
    for (int k = 0; k < kConvMaxTurrets; ++k)
    {
        if (k >= c.cvTurretCount) break;
        float4 t = convTurret(c, k);
        convMoatRing(xz, t.xy, t.z, s, gs, slope);
    }
    grad     = gs * c.cvMoat;
    slopeAdd = slope * c.cvMoat;
    return 1.0f - c.cvMoat * (1.0f - s);
}

// The most the moat adds to the slope cap anywhere in the box whose footprint is [lo, hi].
float convMoatSlopeOver(ConvectionInput c, float2 lo, float2 hi)
{
    float slope = 0.0f;
    for (int k = -1; k < kConvMaxTurrets; ++k)
    {
        if (k >= c.cvTurretCount) break;
        float4 t = k < 0 ? float4(c.cvHeroAt.x, c.cvHeroAt.y, c.cvHeroRadius, c.cvHeroTop)
                         : convTurret(c, k);
        // THE BAND AS convMoatRing FORMS IT, to the bit: a cap a rounding below the
        // density's would be a bound a rounding short.
        float2 gap   = max(max(lo - t.xy, t.xy - hi), float2(0.0f, 0.0f));
        float  outer = kMoatOuter * t.z;
        float  band  = outer - kMoatInner * t.z;
        if (dot(gap, gap) < outer * outer)
            slope = max(slope, 1.5f / band);
    }
    return slope * c.cvMoat;
}

// The hero, in its own frame: it stands still while the field drifts, so its billows are
// sampled about its own centre and do not slide across it. -1e30 beyond its reach.
//
// WITH A SHAPE, THE FRAME IS THE PLANE'S, for the tower too: Decay blends the two surfaces
// and their read points, and a blend of points in two frames would slide the cauliflower
// round the axis as it ran. So under Turn to Camera the whole hero turns with the eye,
// cauliflower and all, and a camera move does not make the billows swim across the shape.
//
// SPLIT IN TWO SINCE BUILD 22: the smooth surface here, the billow in convHeroInside, so
// the hero's group can take its towers' smooth surfaces and billow once (convGroupInside).
bool convHeroSmooth(ConvectionInput c, float3 p, float above, out float d, out float3 x,
                    out float amount, out float lobe)
{
    d      = -1e30f;
    x      = float3(0.0f, 0.0f, 0.0f);
    amount = c.cvHeroBillow;
    lobe   = c.cvHeroBillow;

    float2 rel = p.xz - c.cvHeroAt;
    float  r   = length(rel);
    if (r >= convHeroReachAll(c)) return false;

    if (c.cvShapeOn == 0)
    {
        d = convTowerSurface(c, rel, r, p.y, above, x);
    }
    else
    {
        float2 axisN = float2(-c.cvShapeAxisU.y, c.cvShapeAxisU.x);
        float2 plane = float2(dot(rel, c.cvShapeAxisU), dot(rel, axisN));

        if (c.cvShapeDecay >= 1.0f)
        {
            d = convTowerSurface(c, plane, r, p.y, above, x);   // forgotten: the tower, exactly
        }
        else
        {
            float3 xs;
            float  ds = convShapeSurface(c, plane, p.y, above, xs);
            if (c.cvShapeDecay > 0.0f)
            {
                float3 xt;
                float  dt = convTowerSurface(c, plane, r, p.y, above, xt);
                d = lerp(ds, dt, c.cvShapeDecay);
                x = lerp(xs, xt, c.cvShapeDecay);
            }
            else
            {
                d = ds;
                x = xs;
            }
            amount = c.cvHeroBillow * lerp(c.cvShapeBillow, 1.0f, c.cvShapeDecay);
            lobe   = c.cvHeroBillow * lerp(max(c.cvShapeBillow, kShapeLobeFloor), 1.0f,
                                           c.cvShapeDecay);
        }
    }
    return true;
}

// The hero alone: its smooth surface and its billow, exactly as before build 22.
float convHeroInside(ConvectionInput c, float3 p, float above)
{
    float  d, amount, lobe;
    float3 x;
    if (!convHeroSmooth(c, p, above, d, x, amount, lobe)) return -1e30f;
    float heroLift = convLift(c, above, amount);
    return convInside(c, d, heroLift, x + c.cvHeroSeed, c.cvBillowScale * lobe);
}

// The hero with its group: every tower's smooth surface, blended, and one billow. -1e30
// when the point is beyond every tower's reach. `nearGroup` is the density's test of the
// group's circle: outside it no turret can be near, and the loop is not run.
//
// ===========================================================================
// ONE CALL TO THE BILLOW, WHATEVER THE POINT, AND THAT IS ALSO A MEASUREMENT.
//
// Where no turret is near, the point is the hero's alone, and the numbers handed to the
// billow are the hero's own -- no blend arithmetic touches them, so it is the hero's
// surface exactly. A first version RETURNED convHeroInside there instead, to skip the
// blend, and near the group the density got 30% SLOWER: a warp whose points split between
// the two returns ran both billows. The billow is the whole cost, and on a GPU two call
// sites of it are two costs.
// ===========================================================================
float convGroupInside(ConvectionInput c, float3 p, float above, bool nearGroup)
{
    float  gMax = -1e30f, gSum = 0.0f, gLift = 0.0f, gLobe = 0.0f;
    float3 gX   = float3(0.0f, 0.0f, 0.0f);

    float  d, amount, lobe;
    float3 x;
    bool   anyTurret = false;
    for (int k = 0; k < kConvMaxTurrets; ++k)
    {
        if (!nearGroup || k >= c.cvTurretCount) break;
        float kt;
        if (convTurretSmooth(c, convTurret(c, k), p, above, d, x, kt))
        {
            convGroupFold(d, x, convLift(c, above, kt), kt, gMax, gSum, gX, gLift, gLobe);
            anyTurret = true;
        }
    }

    bool  hero     = convHeroSmooth(c, p, above, d, x, amount, lobe);
    float heroLift = hero ? convLift(c, above, amount) : 0.0f;
    if (!hero && !anyTurret) return -1e30f;

    float3 at;
    float  lift, lobeAt;
    if (!anyTurret)
    {
        gMax = d;   at = x;   lift = heroLift;   lobeAt = lobe;
    }
    else
    {
        if (hero) convGroupFold(d, x, heroLift, lobe, gMax, gSum, gX, gLift, gLobe);
        at = gX / gSum;   lift = gLift / gSum;   lobeAt = gLobe / gSum;
    }
    return convInside(c, gMax, lift, at + c.cvHeroSeed, c.cvBillowScale * lobeAt);
}

// ---------------------------------------------------------------------------
// Mamma (build 23)
// ---------------------------------------------------------------------------
//
// ===========================================================================
// POUCHES HANGING FROM THE UNDERSIDE, WHERE THERE IS CLOUD OVERHEAD TO HANG THEM FROM.
//
// Cloudy air sinking into drier air below sags out of the base in round lobes. So the
// underside's sag at a point is three things multiplied:
//
//   the POUCH there   a jittered lattice of hanging hemispheres in the pattern's frame,
//                     one per slot, overlapping so the underside is mostly lobes with
//                     sharp creases between them -- and SMOOTH, with no cauliflower,
//                     which is what makes mamma read as mamma. Each sags and fades over
//                     half a cell's life, so a timelapse shows them come and go.
//   the ENVELOPE      how far inside the cloud the base above is: no pouch hangs where
//                     there is no cloud overhead, and they shallow to nothing towards the
//                     edge of what there is, so none hangs past its cloud's footprint.
//   cvMammaDepth      the deepest they hang, from Mamma and Pouch Size.
//
// Below the base, a point is inside a pouch when it is less than the sag below the base,
// and the density ramps up from the pouch's surface as it does from the base. ABOVE THE
// BASE, the ramp starts at the pouch's bottom rather than at the base -- otherwise every
// pouch would hang from a forty-metre band of thinning cloud.
// ===========================================================================
public static const float kPouchJitter = 0.6f;   // centres within +-0.3 of the slot's middle
public static const float kPouchRadius = 0.68f;  // slot widths; must stay <= 1 + (1 - J)/2

// THE 3x3 IS EXACT, as the cells' is: a slot two away holds a centre at least
// 1 + (1 - kPouchJitter)/2 = 1.2 from this slot's edge, past kPouchRadius.
public float convPouches(ConvectionInput c, float2 q)
{
    float2 g  = q / c.cvPouchSize;
    int2   gi = int2(floor(g));
    float  r2 = kPouchRadius * kPouchRadius;

    float deepest = 0.0f;
    for (int j = -1; j <= 1; ++j)
    for (int i = -1; i <= 1; ++i)
    {
        int2   slot = gi + int2(i, j);
        float2 ctr  = float2(slot) + 0.5f + (hash22(slot, kConvSaltPouch) - 0.5f) * kPouchJitter;
        float2 d    = g - ctr;
        float  t2   = dot(d, d) / r2;
        if (t2 >= 1.0f) continue;

        // HALF A CELL'S LIFE, and never quite gone: a pouch shrinks to a third rather than
        // vanishing, so the underside stays lobed while each one sags and lifts.
        float2 h    = hash22(slot, kConvSaltSag);
        float  life = convLife(frac(2.0f * c.cvAge + h.x));
        float  sag  = lerp(0.3f, 1.0f, life) * lerp(0.6f, 1.0f, h.y);
        deepest = max(deepest, sag * sqrt(1.0f - t2));
    }
    return deepest;
}

// HOW FAR INSIDE THE CLOUD THE BASE IS, over xz: the smooth surfaces' distance a metre over
// the condensation level, with no billow -- the field's with its moat, the hero's, its
// group's. Positive where there is cloud overhead to hang a pouch from.
//
// IN TWO PARTS, because the field's needs the lattice and the density above the base has
// already run it for the same column: the lattice depends on xz alone. So the density hands
// its own updraft to convFieldBaseInside, and only the pouches below the base -- where there
// is no field evaluation to borrow -- run the lattice here.
public static const float kMammaProbe = 1.0f;   // m over the base the inside is read at

float convFieldBaseInside(ConvectionInput c, float w, float2 slope, float cap)
{
    float v     = convTowerHeight(c, w) - kMammaProbe;
    float delta = w - convNeededUpdraft(c, kMammaProbe);
    return convSurfaceDistance(v, delta, min(length(slope), cap));
}

float convGroupBaseInside(ConvectionInput c, float2 xz, bool nearGroup)
{
    float best = -1e30f;
    if (c.cvHeroTop > 0.0f)
    {
        float  above = kMammaProbe;
        float3 p = float3(xz.x, c.cvBase + above, xz.y);
        float  d, amount, lobe;
        float3 x;
        if (convHeroSmooth(c, p, above, d, x, amount, lobe)) best = max(best, d);
        for (int k = 0; k < kConvMaxTurrets; ++k)
        {
            if (!nearGroup || k >= c.cvTurretCount) break;
            float kt;
            if (convTurretSmooth(c, convTurret(c, k), p, above, d, x, kt)) best = max(best, d);
        }
    }
    return best;
}

float convBaseInside(ConvectionInput c, float2 xz, bool nearGroup)
{
    float best = -1e30f;
    if (c.cvHeroAlone == 0)
    {
        float  m       = 1.0f;
        float  capMoat = 0.0f;
        float2 gMoat   = float2(0.0f, 0.0f);
        bool   moated  = c.cvMoat > 0.0f && nearGroup;
        if (moated) m = convMoat(c, xz, gMoat, capMoat);
        if (m > 0.0f)
        {
            float2 slope;
            float  w   = convUpdraftGrad(c, xz - c.cvDrift, slope);
            float  cap = convSlopeCap(c);
            if (moated)
            {
                slope = slope * m + gMoat * w;
                w     = w * m;
                cap  += capMoat;
            }
            best = convFieldBaseInside(c, w, slope, cap);
        }
    }
    return max(best, convGroupBaseInside(c, xz, nearGroup));
}

// THE UNDERSIDE'S SAG over xz, in metres below the base: zero where nothing hangs. The
// pouch is taken first, being nine hashes against the base's whole lattice -- and where
// even a pouch under the deepest cloud could not reach `below` metres down, the lattice is
// not run at all: the caller only needs to know the sag does not reach it.
public float convMammaSag(ConvectionInput c, float2 xz, bool nearGroup, float below)
{
    float pouch = convPouches(c, xz - c.cvDrift);
    if (c.cvMammaDepth * pouch <= below) return 0.0f;
    return convMammaSagOf(c, pouch, convBaseInside(c, xz, nearGroup));
}

// The sag from a pouch and the base's inside, however the inside was found.
float convMammaSagOf(ConvectionInput c, float pouch, float inside)
{
    if (inside <= 0.0f) return 0.0f;
    return c.cvMammaDepth * pouch * smoothstep(0.0f, 0.6f * c.cvPouchSize, inside);
}

// ---------------------------------------------------------------------------
// Pileus and velum (build 24)
// ---------------------------------------------------------------------------
//
// ===========================================================================
// THE HERO'S CAP AND VEIL: SMOOTH, THIN, AND WHERE THE TOWER IS NOT.
//
// PILEUS is a lens over the crown, kPileusRadius of the hero's radius across: its middle
// follows the hero's own dome, flattened by kPileusFlatten and lifted by the gap, and it is
// thickest over the crown and thins to nothing at its rim. So it drapes a little, as a cap
// does, and the cauliflower pushes up into it where the billows reach the gap.
//
// VELUM is a veil at a height on the tower, kVelumExtent of the hero's radius across,
// fading out over its outer half, and humped up near the tower, which is pushing through
// it. The tower and the veil are a union, as everything in this layer is, so where they
// meet the tower is simply cloud.
//
// BOTH ARE THINNER THAN THE TOWER, by a density factor, and that is the look: a silky
// sheet against a cauliflower tower. Their thickness wanders by up to 40% on a
// kilometre-scale noise, so neither is a machined disc, and they carry no billows.
//
// The inside measure is vertical -- half the thickness less the distance from the middle
// -- which is the true distance for a sheet this flat, and only shortens the soft edge on
// the lens's slopes.
// ===========================================================================
public static const float kPileusRadius  = 0.6f;    // hero radii
public static const float kPileusFlatten = 0.6f;    // the cap follows the dome at 0.6x the radius
public static const float kPileusDensity = 0.45f;   // of the layer's extinction
// SEEN AT 3 RADII: from the default orbit, 4 km out, the camera stood under the veil, which
// filled the top of the frame as an overcast sheet blazing in the backlight. SEEN AT 2.2: its
// near edge still crossed the top of that frame, as a ruled diagonal -- a circle's edge in
// perspective. A veil reads as one when it is round the tower, the eye is outside it, and
// its edge is not a circle. So it reaches PAST THE TOWER'S WALL by between 75% and all of
// (kVelumExtent - 1) radii, by bearing, and thins out over the outer 60% of that.
public static const float kVelumExtent   = 1.9f;    // hero radii from the centre, at the farthest
public static const float kVelumDensity  = 0.22f;
public static const float kCapSoft       = 15.0f;   // m

// A thickness factor in [0.6, 1]: |gradientNoise| is at most 1.5.
float convCapGrain(ConvectionInput c, float2 rel, float scale)
{
    float n = gradientNoise(float3(rel.x / scale + c.cvHeroSeed.x * 1e-3f, 0.37f,
                                   rel.y / scale + c.cvHeroSeed.z * 1e-3f));
    return saturate(0.8f + 0.1333f * n);
}

// The cap's and the veil's density, not an inside: they are thinner than the layer, so
// the caller takes the larger of this and the layer's own density.
public float convCapDensity(ConvectionInput c, float3 p, float above)
{
    float2 rel  = p.xz - c.cvHeroAt;
    float  r2   = dot(rel, rel);
    float  R    = c.cvHeroRadius;
    float  best = 0.0f;

    if (c.cvPileusThick > 0.0f)
    {
        float rp = kPileusRadius * R;
        if (r2 < rp * rp)
        {
            float r    = sqrt(r2);
            float lens = 1.0f - r2 / (rp * rp);
            float mid  = c.cvPileusGap + convHeroHeight(c, r * kPileusFlatten);
            float most = 0.5f * c.cvPileusThick * lens;            // before the grain
            if (abs(above - mid) < most)
            {
                float half = most * convCapGrain(c, rel, 900.0f);
                float s    = half - abs(above - mid);
                if (s > 0.0f) best = max(best, kPileusDensity * smoothstep(0.0f, kCapSoft, s));
            }
        }
    }

    if (c.cvVelumThick > 0.0f)
    {
        float ext = kVelumExtent * R;
        if (r2 < ext * ext)
        {
            float r    = sqrt(r2);

            // THE OUTLINE WANDERS WITH BEARING, on a noise read round the unit circle so it is
            // continuous all the way round. |gradientNoise| <= 1.5, so this is in [0.75, 1].
            float2 dir  = r > 1e-3f ? rel / r : float2(1.0f, 0.0f);
            float  wob  = gradientNoise(float3(1.7f * dir.x + c.cvHeroSeed.x * 1e-3f, 2.3f,
                                               1.7f * dir.y + c.cvHeroSeed.z * 1e-3f));
            float  edge = R + (ext - R) * saturate(0.875f + 0.0833f * wob);
            float fade = 1.0f - smoothstep(R + 0.4f * (edge - R), edge, r);
            float hump = 0.5f * c.cvVelumThick * (1.0f - smoothstep(R, 2.0f * R, r));
            float mid  = c.cvVelumHeight + hump;
            float most = 0.5f * c.cvVelumThick * fade;
            if (abs(above - mid) < most)
            {
                float half = most * convCapGrain(c, rel, 2500.0f);
                float s    = half - abs(above - mid);
                if (s > 0.0f) best = max(best, kVelumDensity * smoothstep(0.0f, kCapSoft, s));
            }
        }
    }
    return c.cvSigma * best;
}

// THEIR BOUND OVER A BOX: each one's factor where the box can reach it, from the heights it
// can span. The cap's middle falls with the radius, so over the whole lens it spans its rim's
// height to its crown's; the veil's rises by at most its hump.
float convCapBound(ConvectionInput c, float3 lo, float3 hi, float low, float high)
{
    float2 nearGap = max(max(lo.xz - c.cvHeroAt, c.cvHeroAt - hi.xz), float2(0.0f, 0.0f));
    float  gap2    = dot(nearGap, nearGap);
    float  R       = c.cvHeroRadius;
    float  best    = 0.0f;

    if (c.cvPileusThick > 0.0f)
    {
        float rp     = kPileusRadius * R;
        float bottom = c.cvPileusGap + convHeroHeight(c, rp * kPileusFlatten) - 0.5f * c.cvPileusThick;
        float top    = c.cvPileusGap + c.cvHeroTop + 0.5f * c.cvPileusThick;
        if (gap2 < rp * rp && high >= bottom && low <= top) best = max(best, kPileusDensity);
    }
    if (c.cvVelumThick > 0.0f)
    {
        float ext    = kVelumExtent * R;
        float bottom = c.cvVelumHeight - 0.5f * c.cvVelumThick;
        float top    = c.cvVelumHeight + c.cvVelumThick;
        if (gap2 < ext * ext && high >= bottom && low <= top) best = max(best, kVelumDensity);
    }
    return c.cvSigma * best * 1.00001f;
}

// ===========================================================================
// WHAT THE SIDE BILLOWS COST, MEASURED, AND WHY IT IS THIS SHAPE.
//
// Per density evaluation, on points spread through the layer the way a tracking walk
// spreads them (the default field, RTX 2070 SUPER):
//
//     vertical-only distance, the build-14 shape          0.39 ns
//     distance with the gradient, no billow at all        0.40 ns
//     distance with the gradient, billow in the shell     0.68 ns   <- this
//     a Lipschitz pre-test, gradient only in the shell    1.16 ns
//
// So the gradient is free -- it rides the lattice loop's hashes -- and the billow is the
// whole cost. It runs wherever a lobe could reach, which is now around the walls as well
// as over the crowns, and that shell is the feature. The last row is the tempting
// optimisation, and it is 1.7x WORSE: the global slope bound is loose, so most points
// fail the cheap test and pay the lattice twice. Stopping the octaves early once the
// answer is known was also measured, at no gain: a warp runs the billow if any one of its
// points needs it.
// ===========================================================================
public float convectionDensity(ConvectionInput c, float3 p)
{
    float above = p.y - c.cvBase;

    // NOTHING BELOW THE CONDENSATION LEVEL, EXACTLY -- that line is the flat base -- BUT THE
    // POUCHES, which hang at most cvMammaDepth under it (build 23). Zero depth is the old line.
    if (above < -c.cvMammaDepth || above > convCeiling(c)) return 0.0f;

    // THE HERO'S GROUP IS LOCAL (build 22): one circle round the hero covers every turret's
    // reach and every ring of the moat, and a point outside it skips both, exactly. MEASURED:
    // without it, looking away from the group, the frame took 20% longer at Connection 1 --
    // the rings and reaches, run for every density in the sky.
    float2 fromHero  = p.xz - c.cvHeroAt;
    bool   nearGroup = dot(fromHero, fromHero) < c.cvGroupReach * c.cvGroupReach;

    // MAMMA (build 23): under the base, the pouch alone. MEASURED: the slab reaching down to
    // the deepest pouch put every ray through that band, and with the base's lattice run at
    // every step there the deck's frame took 75% longer. A pouch that cannot reach this deep
    // even under the deepest cloud now skips the lattice -- see convMammaSag.
    if (c.cvMammaDepth > 0.0f && above < 0.0f)
    {
        float hang = convMammaSag(c, p.xz, nearGroup, -above) + above;   // up from its surface
        if (hang <= 0.0f) return 0.0f;
        return c.cvSigma * sqrt(saturate(hang / kConvBaseRamp))
             * smoothstep(0.0f, kConvEdgeSoft, hang);
    }

    // A LACUNOSE SHEET WEARS SMALLER BILLOWS: see kConvSheetBillowCut. The bound keeps the
    // full lift, which is only ever more. Without lacunarity the factor is exactly one.
    float lift   = convLift(c, above, 1.0f - kConvSheetBillowCut * c.cvLacunarity);
    float inside = -1e30f;

    // MAMMA'S BASE TEST, from the field's own lattice when the point is in the base ramp:
    // see convBaseInside. -1e30 is what that function's field part says where the field is
    // not run, so the two agree everywhere.
    bool  rampBand  = c.cvMammaDepth > 0.0f && above < kConvBaseRamp;
    float baseField = -1e30f;

    // THE CELL FIELD. The updraft and its slope give the distance to the surface; the
    // billow is evaluated only in the shell where it can move the answer.
    if (c.cvHeroAlone == 0)
    {
        // THE MOAT (build 22): the updraft sinks under the hero's group. In the world's
        // frame, not the pattern's -- the group stands where the hero does, and the cells
        // drift through it unless the hero drifts with them.
        //
        // TAKEN FIRST, because WHERE IT IS ZERO THE FIELD IS NOTHING and its lattice need not
        // run: an updraft of zero with a slope of zero -- the ring's slope is zero inside its
        // inner radius too -- is a tower of zero, d = -above, and a lift of at most 0.7 above
        // never brings that past zero. So the branch below would leave `inside` at -1e30,
        // which is what skipping it leaves. That is every point in the group's middle, the
        // hero's interior included, where the field's lattice was paid and thrown away.
        float  m       = 1.0f;
        float  capMoat = 0.0f;
        float2 gMoat   = float2(0.0f, 0.0f);
        bool   moated  = c.cvMoat > 0.0f && nearGroup;
        if (moated) m = convMoat(c, p.xz, gMoat, capMoat);

        if (m > 0.0f)
        {
            float2 q = p.xz - c.cvDrift;
            float2 slope;
            float  w   = convUpdraftGrad(c, q, slope);
            float  cap = convSlopeCap(c);
            if (moated)
            {
                slope = slope * m + gMoat * w;
                w     = w * m;
                cap  += capMoat;
            }
            if (rampBand) baseField = convFieldBaseInside(c, w, slope, cap);

            // THE SLOPE CLAMPED TO WHAT THE BOUND DIVIDES BY: see convSlopeCap. Without
            // organization the true slope is always under it, and this is the old line.
            float v     = convTowerHeight(c, w) - above;
            float delta = w - convNeededUpdraft(c, above);
            float d     = convSurfaceDistance(v, delta, min(length(slope), cap));

            if (d + lift > 0.0f)
            {
                // THE BILLOW IS READ AT THE NEAREST SURFACE POINT, NOT AT p. Read at p, it
                // varies along the normal as fast as across it, so pockets of high billow sit
                // out in the air, detached: the first render of side billows was a tower
                // wrapped in loose flecks. Read at the surface, each point along a normal gets
                // the same billow, which makes the displacement a relief ON the surface --
                // round lobes attached to the wall, the cauliflower.
                //
                // The nearest point on the plane through both intercepts is
                // p + d^2 (y/v - g/delta), with g the updraft's gradient. Each term is at
                // most |d| long, and each ratio is taken only where its divisor is not
                // vanishing -- where it is, d is too.
                float  shiftUp = abs(v) > 1e-6f ? d * (d / v) : 0.0f;
                float2 shiftAcross = abs(delta) > 1e-12f ? slope * (-d * (d / delta))
                                                         : float2(0.0f, 0.0f);
                inside = convInside(c, d, lift,
                                    float3(q.x + shiftAcross.x, p.y + shiftUp, q.y + shiftAcross.y),
                                    c.cvBillowScale);
            }
        }
    }

    // THE HERO'S CAP AND VEIL (build 24): thinner than the layer, so the larger density wins.
    float capDensity = 0.0f;
    if (c.cvHeroTop > 0.0f && (c.cvPileusThick > 0.0f || c.cvVelumThick > 0.0f))
        capDensity = convCapDensity(c, p, above);

    // THE HERO, and its group (build 22). Without turrets, the hero's own path, exactly as it
    // was. The branch is the same for every point of a launch, so it costs no divergence.
    if (c.cvHeroTop > 0.0f && inside < kConvEdgeSoft)
    {
        if (c.cvTurretCount > 0)
            inside = max(inside, convGroupInside(c, p, above, nearGroup));
        else
            inside = max(inside, convHeroInside(c, p, above));
    }

    if (inside <= 0.0f) return capDensity;

    // THE BASE RAMP STARTS AT THE POUCH'S BOTTOM where one hangs; with none, at the base.
    // Taken only here, where there is cloud for it to change, and from the field's own
    // lattice above. MEASURED: with a second lattice for it, pouches 16 m deep cost a deck
    // seen from below 22%.
    float sag = 0.0f;
    if (rampBand)
    {
        float pouch = convPouches(c, p.xz - c.cvDrift);
        if (pouch > 0.0f)
            sag = convMammaSagOf(c, pouch, max(baseField, convGroupBaseInside(c, p.xz, nearGroup)));
    }

    float edge    = smoothstep(0.0f, kConvEdgeSoft, inside);
    float profile = sqrt(saturate((above + sag) / kConvBaseRamp));
    return max(c.cvSigma * profile * edge, capDensity);
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

    float2 ctr = convCellCentre(c, slot);

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
//
// THE ORGANIZED UPDRAFT INCLUDED: every factor convOrganize applies is at most one, so
// the unorganized updraft's bound holds for it, over the lattice box the footprint maps
// into -- orgPatternBox's, which is the footprint itself when there is no organization.
public float convUpdraftBound(ConvectionInput c, float2 q0, float2 q1)
{
    float2 a, b;
    orgPatternBox(c.cvOrg, q0, q1, c.cvSpacing, a, b);

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
    float field = lerp(openHi, closedHi, c.cvPolarity);

    // LACUNARITY'S SHEET is the constant kConvSheetLevel, and its holes only lower it, so
    // the blend is at most the same blend of the field's bound and it. Zero lacunarity is
    // the line above exactly: lerp(x, y, 0) is x.
    if (c.cvLacunarity > 0.0f) field = lerp(field, kConvSheetLevel, c.cvLacunarity);
    return field + 1e-5f;
}

// THE SHAPE'S DISTANCE, BOUNDED OVER A BOX: the deepest the box's footprint on the plane
// reaches into the silhouette, against the nearest the box comes to the plane. The profile
// is monotone in both (convShapeProfile), so that pair bounds every point in the box.
//
// THE DEEPEST IS THE FOOTPRINT'S CENTRE PLUS THE SLOPE BOUND TIMES ITS HALF DIAGONAL, not a
// search: a small box is tight and a big one is loose, and loose is only slower.
float convShapeBound(ConvectionInput c, float3 lo, float3 hi, float low, float high)
{
    float2 ea = lo.xz - c.cvHeroAt;
    float2 eb = hi.xz - c.cvHeroAt;
    float2 au = c.cvShapeAxisU;
    float2 an = float2(-au.y, au.x);

    float uLo = min(ea.x * au.x, eb.x * au.x) + min(ea.y * au.y, eb.y * au.y);
    float uHi = max(ea.x * au.x, eb.x * au.x) + max(ea.y * au.y, eb.y * au.y);
    float nLo = min(ea.x * an.x, eb.x * an.x) + min(ea.y * an.y, eb.y * an.y);
    float nHi = max(ea.x * an.x, eb.x * an.x) + max(ea.y * an.y, eb.y * an.y);
    float mMin = (nLo <= 0.0f && nHi >= 0.0f) ? 0.0f : min(abs(nLo), abs(nHi));

    float2 slopeUnused;
    float  relief;
    float2 halfSpan = float2(0.5f * (uHi - uLo), 0.5f * (high - low));
    float  dMax = convShapeDistance(c, 0.5f * (uLo + uHi), 0.5f * (low + high), slopeUnused, relief)
                + kShapeLipschitz * length(halfSpan);

    // RELIEF (build 27): A BOX WHOLLY IN FRONT IS NEARER THE FACE BY THE MOST IT CAN BE LIFTED
    // there -- the relief at the footprint's centre plus its slope bound times the half
    // diagonal, as for D, and never more than the whole height. The fade only lowers it.
    if (c.cvReliefHeight > 0.0f && nLo > 0.0f)
    {
        float hMax = min(c.cvReliefHeight,
                         c.cvReliefHeight * relief + c.cvReliefSlope * length(halfSpan));
        mMin = max(nLo - hMax, 0.0f);
    }

    float2 stepUnused;
    return -convShapeProfile(dMax, mMin, c.cvShapeRound, stepUnused);
}

// ONE TURRET OVER A BOX: the hero's tower's two cases, from the dome's closed form. Every
// factor is monotone in the distance from the turret's centre, so the box's nearest point
// to it bounds them; the lift is taken at the box's top. The distance part and the lift
// come back apart, for the group's bound (convGroupInside). False past its reach.
bool convTurretBound(ConvectionInput c, float4 t, float3 lo, float3 hi, float low, float high,
                     out float dPart, out float lift)
{
    dPart = -1e30f;
    lift  = 0.0f;
    float2 nearGap = max(max(lo.xz - t.xy, t.xy - hi.xz), float2(0.0f, 0.0f));
    float  gap2    = dot(nearGap, nearGap);
    float  reach   = convTurretReach(c, t);
    if (gap2 >= reach * reach) return false;

    float rMin  = sqrt(gap2);
    float tower = convDomeHeight(t.w, t.z, c.cvShape, rMin);
    float ra    = convDomeRadiusAt(t.w, t.z, c.cvShape, low);
    lift = convLift(c, high, convTurretBillow(c, t.z));
    if (ra < 0.0f || rMin >= ra)
    {
        float hMin = ra < 0.0f ? 1e30f : rMin - ra;
        dPart = -convDistanceFloor(low - tower, hMin);
    }
    else
    {
        dPart = max(tower - low, 0.0f);
    }
    return true;
}

public float convectionBound(ConvectionInput c, float3 lo, float3 hi)
{
    float low  = lo.y - c.cvBase;
    float high = hi.y - c.cvBase;
    float ceiling = convCeiling(c);

    if (high < -c.cvMammaDepth || low > ceiling) return 0.0f;

    // MAMMA (build 23): A BOX BELOW THE BASE IS BOUNDED AS ONE AT IT. A pouch hangs only
    // where the base over it is inside the cloud, and every inside below is at least that at
    // height zero; the pouch's own density is at most the ramp from its deepest bottom.
    bool pouches = c.cvMammaDepth > 0.0f && low < kConvBaseRamp;
    low  = max(low, 0.0f);
    high = min(max(high, 0.0f), ceiling);

    // THE CAP AND THE VEIL (build 24), whose density is the larger of theirs and the layer's.
    float capBound = 0.0f;
    if (c.cvHeroTop > 0.0f && (c.cvPileusThick > 0.0f || c.cvVelumThick > 0.0f))
        capBound = convCapBound(c, lo, hi, low, high);

    // THE LIFT AT THE TOP OF THE BOX: it is non-decreasing in height, base cap included.
    float lift   = convLift(c, high, 1.0f);
    float inside = -1e30f;

    // ===================================================================
    // THE FIELD. Two cases, and each is an inequality on the distance the density uses.
    //
    // SOME POINT MAY BE UNDER A TOP (the bounded updraft reaches what the box's lowest
    // point needs): then d <= v <= tallest tower - low, and inside is at most that plus
    // the lift.
    //
    // EVERY POINT IS OUTSIDE: then |v| >= low - tallest, and |delta| >= needed(low) -
    // wHi, and |d| is increasing in both and decreasing in the slope, which is at most
    // kConvGradMax per slot. So every point is at least `floor` from the surface, and
    // the most a billow can do is lift it back by `lift`. This is the case that proves
    // clear air clear -- the old vertical-only bound could say zero for any box over
    // the towers' tops; this one must first be sure no wall is within reach sideways.
    // ===================================================================
    if (c.cvHeroAlone == 0)
    {
        float wHi   = convUpdraftBound(c, lo.xz - c.cvDrift, hi.xz - c.cvDrift);
        float tower = convTowerHeight(c, wHi);
        float need  = convNeededUpdraft(c, low);

        if (wHi < need)
        {
            // The density's own clamp, so this floor holds for the distance it computes --
            // with the moat's term wherever the box reaches a ring of it (build 22).
            float slopeMax = convSlopeCap(c);
            if (c.cvMoat > 0.0f) slopeMax += convMoatSlopeOver(c, lo.xz, hi.xz);
            float floorD = convDistanceFloor(low - tower, (need - wHi) / slopeMax);
            inside = lift - floorD;
        }
        else
        {
            inside = max(tower - low, 0.0f) + lift;
        }
    }

    // THE HERO, the same two cases from its closed form. Every factor is monotone in
    // the distance from its centre, so the box's nearest point to the centre bounds it.
    if (c.cvHeroTop > 0.0f)
    {
        float groupD = -1e30f, groupLift = 0.0f;   // the hero's, then the group's

        float2 nearGap = max(max(lo.xz - c.cvHeroAt, c.cvHeroAt - hi.xz), float2(0.0f, 0.0f));
        float  rMin    = length(nearGap);

        if (rMin < convHeroReachAll(c))
        {
            float tower = convHeroHeight(c, rMin);
            float ra    = convHeroRadiusAt(c, low);

            float heroLift = convLift(c, high, c.cvHeroBillow);
            float towerD;
            if (ra < 0.0f || rMin >= ra)
            {
                // Outside everywhere: over the top, or beyond the wall at every height
                // the box reaches. See the field's case above.
                float hMin = ra < 0.0f ? 1e30f : rMin - ra;
                towerD = -convDistanceFloor(low - tower, hMin);
            }
            else
            {
                towerD = max(tower - low, 0.0f);
            }

            // THE SHAPE: its own bound, blended with the tower's as the density blends the
            // two, then the lift the density uses. The tower's bound above is taken in the
            // world's frame and the density's tower in the plane's, which is the same
            // number: the tower is round.
            if (c.cvShapeOn != 0 && c.cvShapeDecay < 1.0f)
            {
                float shapeD = convShapeBound(c, lo, hi, low, high);
                float amount = c.cvHeroBillow * lerp(c.cvShapeBillow, 1.0f, c.cvShapeDecay);
                groupD    = lerp(shapeD, towerD, c.cvShapeDecay);
                groupLift = convLift(c, high, amount);
            }
            else
            {
                groupD    = towerD;
                groupLift = heroLift;
            }
        }

        // THE HERO'S GROUP (build 22): each turret a dome, bounded as the hero's tower is,
        // and the group's billow at most the largest distance part plus the largest lift --
        // see convGroupInside. Without turrets that is the hero's own bound, as it was.
        for (int k = 0; k < kConvMaxTurrets; ++k)
        {
            if (k >= c.cvTurretCount) break;
            float turretD, turretLift;
            if (convTurretBound(c, convTurret(c, k), lo, hi, low, high, turretD, turretLift))
            {
                groupD    = max(groupD, turretD);
                groupLift = max(groupLift, turretLift);
            }
        }
        if (groupD > -1e29f) inside = max(inside, groupD + groupLift);
    }

    inside += 1e-3f;
    if (inside <= 0.0f) return capBound;

    // A POUCH'S EDGE IS ITS OWN, not the cloud's above it, so it is taken at one; and the
    // ramp from the deepest bottom any pouch can have.
    float edge    = pouches ? 1.0f : smoothstep(0.0f, kConvEdgeSoft, inside);
    float profile = sqrt(saturate((pouches ? high + c.cvMammaDepth : high) / kConvBaseRamp));
    return max(c.cvSigma * profile * edge * 1.00001f, capBound);
}

#endif // MISTYTUNE_CONVECTION_LIB_SLANG
