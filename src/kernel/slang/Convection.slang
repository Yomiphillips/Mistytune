// Test entry points for the cellular convection generator.
//
// THE GENERATOR ITSELF IS IN ConvectionLib.slang, and the transport includes that. These
// kernels exist for slang.convection alone, which is why they live in a harness the
// renderer never includes -- the same split every other Lib file makes.

#include "ConvectionLib.slang"

// The density at arbitrary points.
[shader("compute")]
[numthreads(64, 1, 1)]
void convDensityAt(uint3 tid : SV_DispatchThreadID,
                   uniform ConvectionInput c,
                   uniform StructuredBuffer<float3> points,
                   uniform RWStructuredBuffer<float> outDensity,
                   uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    outDensity[i] = convectionDensity(c, points[i]);
}

// The bound over arbitrary boxes, given as pairs of corners.
[shader("compute")]
[numthreads(64, 1, 1)]
void convBoundOver(uint3 tid : SV_DispatchThreadID,
                   uniform ConvectionInput c,
                   uniform StructuredBuffer<float3> boxLo,
                   uniform StructuredBuffer<float3> boxHi,
                   uniform RWStructuredBuffer<float> outBound,
                   uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    outBound[i] = convectionBound(c, boxLo[i], boxHi[i]);
}

// The updraft at pattern-frame points, WITHOUT the footprint warp -- the polarity test
// asks about the cells themselves, and the warp would move the answer off the centres
// the test reads back below.
[shader("compute")]
[numthreads(64, 1, 1)]
void convUpdraftAt(uint3 tid : SV_DispatchThreadID,
                   uniform ConvectionInput c,
                   uniform StructuredBuffer<float2> points,
                   uniform RWStructuredBuffer<float> outUpdraft,
                   uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    outUpdraft[i] = convUpdraft(c, points[i]);
}

// Where a slot's cell centre is, in slot units, and how vigorous it is now.
[shader("compute")]
[numthreads(64, 1, 1)]
void convCells(uint3 tid : SV_DispatchThreadID,
               uniform ConvectionInput c,
               uniform StructuredBuffer<int2> slots,
               uniform RWStructuredBuffer<float3> outCell,
               uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    float2 ctr = convCellCentre(c, slots[i]);
    outCell[i] = float3(ctr.x, ctr.y, convVigour(c, slots[i]));
}

// The billow at arbitrary points, so the test can report the mean it produces.
[shader("compute")]
[numthreads(64, 1, 1)]
void convBillowAt(uint3 tid : SV_DispatchThreadID,
                  uniform ConvectionInput c,
                  uniform StructuredBuffer<float3> points,
                  uniform RWStructuredBuffer<float> outBillow,
                  uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;
    outBillow[i] = convBillow(c, points[i], c.cvBillowScale);
}

// THE UPDRAFT OVER A 5x5 WINDOW, for the claim that 3x3 is exact rather than an
// approximation. convUpdraft's own header argues it from the jitter and the reach; this
// checks it on the kernel's own numbers. The extra ring must contribute nothing: a
// kernel of zero never displaces the two largest, so the two agree to the bit.
//
// A COPY OF convUpdraft'S COMBINATION, deliberately: if the library's changes and this
// one does not, the two disagree and the test says so. THE ORGANIZATION STEP IS SHARED
// rather than copied (convOrganize): what this checks is the neighbourhood, and the gaps,
// holes and wave act on the two largest kernels after it, whichever window found them.
[shader("compute")]
[numthreads(64, 1, 1)]
void convUpdraftWide(uint3 tid : SV_DispatchThreadID,
                     uniform ConvectionInput c,
                     uniform StructuredBuffer<float2> points,
                     uniform RWStructuredBuffer<float> outUpdraft,
                     uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    float2 g  = orgPattern(c.cvOrg, points[i], c.cvSpacing);
    int2   gi = int2(floor(g));

    float oTop = 0.0f, oNext = 0.0f;
    float kTop = 0.0f, kNext = 0.0f;
    float  keep  = 1.0f;
    float2 gKeep = float2(0.0f, 0.0f);
    for (int dj = -2; dj <= 2; ++dj)
    {
        for (int di = -2; di <= 2; ++di)
        {
            int2 slot = gi + int2(di, dj);

            float vig = convVigour(c, slot);
            if (vig <= 0.0f) continue;

            float2 d  = g - convCellCentre(c, slot);
            float  d2 = dot(d, d);
            float  ko = vig * convBump(d2, kConvReachOpen);
            float  kk = vig * convBump(d2, kConvReachClosed);

            if (c.cvLacunarity > 0.0f) convHole(c, d, d2, vig, keep, gKeep);

            if (ko > oTop) { oNext = oTop; oTop = ko; }
            else if (ko > oNext) { oNext = ko; }

            if (kk > kTop) { kNext = kTop; kTop = kk; }
            else if (kk > kNext) { kNext = kk; }
        }
    }

    float openField   = min(oNext / kConvOpenNorm, 1.0f);
    float closedField = kTop - kNext;
    float w = lerp(openField, closedField, c.cvPolarity);
    if (c.cvOrg.ogOn != 0)
    {
        float2 unused;
        float2 none = float2(0.0f, 0.0f);
        w = convOrganize(c, points[i], kTop, kNext, none, none, keep, gKeep, w, none, unused);
    }
    outUpdraft[i] = w;
}
