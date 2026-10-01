// The cellular convection generator: its bound, its base, its polarity.
//
// ===========================================================================
// THE BOUND IS THE ONE THAT MATTERS, AND IT IS THE ONE A RENDER CANNOT CHECK.
//
// convectionBound() is what the procedural majorant grid hands delta tracking. A bound
// below the density does not render slowly or noisily -- it renders a cloud that is
// quietly WRONG: the acceptance probability sigma/majorant passes one, the tracker
// scatters at the first tentative collision it tests, and the cloud comes out denser
// and harder-edged where the bound is short. That looks like a modelling choice.
//
// The bound is built as a chain of inequalities (ConvectionLib.slang says which), so
// this is not how it is PROVED -- sampling a fractal can only ever find a floor. It is
// how a slip in the chain is CAUGHT: every box, thousands of points inside it, and not
// one of them may exceed the box's bound. Half the boxes are thrown at random; half are
// centred on points already known to be cloud, which is where the thresholds are and
// where a bound that is right in clear air would be wrong.
//
// THE REST are the generator's physical claims, each of which a picture would show only
// as "looks a bit off":
//
//   * the base is FLAT: nothing below the condensation level, and cloud right down to it
//   * the lid holds: nothing above the tallest tower plus its biggest billow
//   * POLARITY does what it says: closed cells rise at the centres, open at the rims
//   * more moisture means more cloud, monotonically
//   * the 3x3 neighbourhood is the whole field -- a 5x5 one agrees to the bit
//   * the billows are centred: they bulge about as much as they bite
// ===========================================================================

#include <cstdio>
#include <cmath>
#include <string>
#include <utility>
#include <vector>
#include <algorithm>

#include <cuda_runtime.h>

#include "Convection.cu"

namespace {

// A small deterministic generator for the host's own sampling. The kernel's streams are
// not involved -- this only decides where to look.
struct HostRng {
    unsigned long long s;
    explicit HostRng(unsigned long long seed) : s(seed * 6364136223846793005ull + 1442695040888963407ull) {}
    double next() {
        s = s * 6364136223846793005ull + 1442695040888963407ull;
        return static_cast<double>((s >> 11) & ((1ull << 53) - 1)) / static_cast<double>(1ull << 53);
    }
    float range(float a, float b) { return a + static_cast<float>(next()) * (b - a); }
};

template <class T>
struct Device {
    T* p = nullptr;
    size_t n = 0;
    explicit Device(size_t count) : n(count) { cudaMalloc(&p, sizeof(T) * (count ? count : 1)); }
    ~Device() { cudaFree(p); }
    void put(const std::vector<T>& v) { cudaMemcpy(p, v.data(), sizeof(T) * v.size(), cudaMemcpyHostToDevice); }
    std::vector<T> get() const {
        std::vector<T> v(n);
        cudaMemcpy(v.data(), p, sizeof(T) * n, cudaMemcpyDeviceToHost);
        return v;
    }
    StructuredBuffer<T> ro() const { StructuredBuffer<T> b; b.data = p; b.count = n; return b; }
    RWStructuredBuffer<T> rw() const { RWStructuredBuffer<T> b; b.data = p; b.count = n; return b; }
};

int blocks(size_t n) { return static_cast<int>((n + 63) / 64); }

std::vector<float> densities(const ConvectionInput_0& c, const std::vector<float3>& pts) {
    Device<float3> in(pts.size());
    Device<float>  out(pts.size());
    in.put(pts);
    convDensityAt<<<blocks(pts.size()), 64>>>(c, in.ro(), out.rw(), static_cast<int>(pts.size()));
    return out.get();
}

std::vector<float> bounds(const ConvectionInput_0& c, const std::vector<float3>& lo,
                          const std::vector<float3>& hi) {
    Device<float3> dLo(lo.size()), dHi(hi.size());
    Device<float>  out(lo.size());
    dLo.put(lo);
    dHi.put(hi);
    convBoundOver<<<blocks(lo.size()), 64>>>(c, dLo.ro(), dHi.ro(), out.rw(), static_cast<int>(lo.size()));
    return out.get();
}

std::vector<float> updrafts(const ConvectionInput_0& c, const std::vector<float2>& pts, bool wide) {
    Device<float2> in(pts.size());
    Device<float>  out(pts.size());
    in.put(pts);
    if (wide) convUpdraftWide<<<blocks(pts.size()), 64>>>(c, in.ro(), out.rw(), static_cast<int>(pts.size()));
    else      convUpdraftAt<<<blocks(pts.size()), 64>>>(c, in.ro(), out.rw(), static_cast<int>(pts.size()));
    return out.get();
}

// A cumulus field shaped like the shipping defaults: the base at the condensation level
// of 15 C at 70%, towers two thirds of the room under a 2.4 km lid, and the transport's
// truncated extinction.
ConvectionInput_0 defaults(float polarity) {
    ConvectionInput_0 c{};
    c.cvBase_0        = 680.0f;
    c.cvDepth_0       = 1100.0f;
    c.cvSpacing_0     = 1800.0f;
    c.cvPolarity_0    = polarity;
    c.cvCoverage_0    = 0.55f;
    c.cvShape_0       = 0.6f;
    c.cvSigma_0       = 0.015f;
    c.cvBillow_0      = 350.0f;
    c.cvBillowScale_0 = 450.0f;
    c.cvOctaves_0     = 3;
    c.cvDrift_0       = make_float2(123.0f, -45.0f);
    c.cvAge_0         = 0.37f;
    c.cvRise_0        = 50.0f;
    return c;
}

// THE ORGANIZATION GROUP, SET IN THE KERNEL'S OWN TERMS (build 20), so this test does not
// lean on the engine's resolve -- TestOrganization checks that half. Bearings are the
// winds' convention: clockwise from +Z.
void organize(ConvectionInput_0& c, float rowsAlongDeg, float stretch, float coherence) {
    const float b = rowsAlongDeg * 0.01745329252f;
    c.cvOrg_0.ogOn_0        = 1;
    c.cvOrg_0.ogAxis_0      = make_float2(std::sin(b), std::cos(b));
    c.cvOrg_0.ogStretch_0   = stretch;
    c.cvOrg_0.ogCoherence_0 = coherence;
}

void addWave(ConvectionInput_0& c, float crestsAlongDeg, float length, float amplitude) {
    const float b = crestsAlongDeg * 0.01745329252f;
    c.cvOrg_0.ogWaveK_0   = make_float2(std::cos(b) / length, -std::sin(b) / length);
    c.cvOrg_0.ogWaveAmp_0 = amplitude;
}

// A cell centre (lattice units) back to the world, for an organization without a warp.
float2 centreToWorld(const ConvectionInput_0& c, float2 g) {
    const float2 axis = c.cvOrg_0.ogAxis_0;
    const float along  = g.x * c.cvSpacing_0 * c.cvOrg_0.ogStretch_0;
    const float across = g.y * c.cvSpacing_0;
    return make_float2(axis.x * along - axis.y * across, axis.y * along + axis.x * across);
}

// The organized fields the bound and the window are checked on, beside the plain ones.
std::vector<std::pair<const char*, ConvectionInput_0>> organizedCases() {
    std::vector<std::pair<const char*, ConvectionInput_0>> out;
    {
        ConvectionInput_0 c = defaults(0.3f);
        organize(c, 30.0f, 4.0f, 0.9f);
        out.push_back({ "rolls at 30 deg", c });
    }
    {
        ConvectionInput_0 c = defaults(0.7f);
        organize(c, 70.0f, 2.0f, 0.4f);
        addWave(c, 70.0f, 2500.0f, 0.8f);
        out.push_back({ "waves, amplitude 0.8", c });
    }
    {
        ConvectionInput_0 c = defaults(0.5f);
        organize(c, 115.0f, 1.5f, 0.0f);
        c.cvOrg_0.ogWarp_0 = 1.2f;
        out.push_back({ "chaotic warp", c });
    }
    {
        ConvectionInput_0 c = defaults(1.0f);
        c.cvCoverage_0 = 0.9f;
        organize(c, 90.0f, 1.0f, 0.0f);
        c.cvGapWidth_0   = 0.28f;
        c.cvLacunarity_0 = 0.6f;
        out.push_back({ "gaps and holes, closed", c });
    }
    {
        ConvectionInput_0 c = defaults(0.8f);
        c.cvSpacing_0  = 400.0f;
        c.cvCoverage_0 = 1.0f;
        organize(c, 200.0f, 3.0f, 0.6f);
        addWave(c, 20.0f, 900.0f, 1.0f);
        c.cvOrg_0.ogWarp_0 = 1.2f;
        c.cvGapWidth_0   = 0.9f;
        c.cvLacunarity_0 = 1.0f;
        out.push_back({ "everything, small cells", c });
    }
    return out;
}

// ---------------------------------------------------------------------------
// PAREIDOLIA'S MAP, ANALYTIC (build 21)
// ---------------------------------------------------------------------------
//
// NOT THE ENGINE'S BUILDER: this test links no host code, and it does not need it. The
// kernel takes any map whose neighbouring texels differ by at most one -- the property its
// slope bound is built on -- and an exact signed distance function sampled on the grid has
// it. So the silhouette is a disc with an eye punched out of it and a bar sticking out of
// its side, in texel units, as max and min of exact distances, with the slopes by central
// differences as the host writes them.
constexpr int   kShapeW = 180, kShapeH = 200;
constexpr float kShapeTexel = 10.0f;     // m
constexpr float kShapeOffsetU = 90.0f, kShapeOffsetY = 16.0f;

// Texel-edge coordinates (texel i's centre is i + 0.5): the signed distance, + inside.
float shapeSdf(float x, float y) {
    const float disc = 80.0f - std::hypot(x - 90.0f, y - 100.0f);
    const float qx = std::fabs(x - 135.0f) - 35.0f, qy = std::fabs(y - 50.0f) - 10.0f;
    const float bar = -(std::hypot(std::max(qx, 0.0f), std::max(qy, 0.0f)) + std::min(std::max(qx, qy), 0.0f));
    const float eye = std::hypot(x - 65.0f, y - 125.0f) - 12.0f;
    return std::min(std::max(disc, bar), eye);
}

std::vector<float> shapeTexels() {
    std::vector<float> d(static_cast<size_t>(kShapeW) * kShapeH);
    for (int j = 0; j < kShapeH; ++j)
        for (int i = 0; i < kShapeW; ++i) d[static_cast<size_t>(j) * kShapeW + i] = shapeSdf(i + 0.5f, j + 0.5f);
    auto at = [&](int i, int j) { return d[static_cast<size_t>(j) * kShapeW + i]; };
    std::vector<float> t(d.size() * 4, 0.0f);
    for (int j = 0; j < kShapeH; ++j) {
        for (int i = 0; i < kShapeW; ++i) {
            const int il = i > 0 ? i - 1 : i, ir = i < kShapeW - 1 ? i + 1 : i;
            const int jd = j > 0 ? j - 1 : j, ju = j < kShapeH - 1 ? j + 1 : j;
            float* o = t.data() + (static_cast<size_t>(j) * kShapeW + i) * 4;
            o[0] = at(i, j);
            o[1] = (at(ir, j) - at(il, j)) / static_cast<float>(ir - il);
            o[2] = (at(i, ju) - at(i, jd)) / static_cast<float>(ju - jd);
        }
    }
    return t;
}

// The hero wears the map: facing `bearingDeg` on the orbit dial, as the host resolves it.
void addShape(ConvectionInput_0& c, const Device<float>& map, float bearingDeg, float decay,
              float billow) {
    const float b = bearingDeg * 0.01745329252f;
    c.cvShapeOn_0        = 1;
    c.cvShapeMap_0       = map.ro();
    c.cvShapeDim_0       = make_int2(kShapeW, kShapeH);
    c.cvShapeOffset_0    = make_float2(kShapeOffsetU, kShapeOffsetY);
    c.cvShapeTexel_0     = kShapeTexel;
    c.cvShapeAxisU_0     = make_float2(std::cos(b), -std::sin(b));
    c.cvShapeRound_0     = 400.0f;
    c.cvShapeHalfWidth_0 = 800.0f;
    c.cvShapeDecay_0     = decay;
    c.cvShapeBillow_0    = billow;
}

// A hero with room for the map: 1640 m tall at most, 800 m either side of its axis.
ConvectionInput_0 shapeHero(float polarity, bool alone) {
    ConvectionInput_0 c = defaults(polarity);
    c.cvHeroAt_0     = make_float2(-300.0f, 700.0f);
    c.cvHeroRadius_0 = 900.0f;
    c.cvHeroTop_0    = 1700.0f;
    c.cvHeroSeed_0   = make_float3(1731.0f, 613.0f, 2477.0f);
    c.cvHeroBillow_0 = 1.6f;
    c.cvHeroAlone_0  = alone ? 1 : 0;
    return c;
}

// ---------------------------------------------------------------------------
// HERO CONNECTION'S GROUP, IN THE KERNEL'S OWN TERMS (build 22)
// ---------------------------------------------------------------------------
//
// The host's layout at Connection 1 with the wind from 250 degrees, written out rather
// than linked -- TestConvection checks the host's half. Shoulders can be left out, as the
// host leaves them out under a pareidolia shape.
void addGroup(ConvectionInput_0& c, float moat, bool shoulders) {
    const float b  = 250.0f * 0.01745329252f;
    const float ux = std::sin(b), uz = std::cos(b);
    const float vx = uz, vz = -ux;
    struct Spec { float along, across, radius, top; bool shoulder; };
    const Spec specs[] = {
        { -0.30f,  0.80f, 0.45f, 0.80f, true  },
        {  0.35f, -0.78f, 0.40f, 0.68f, true  },
        {  1.25f,  0.12f, 0.55f, 0.72f, false },
        {  2.05f, -0.10f, 0.42f, 0.52f, false },
        {  2.70f,  0.10f, 0.32f, 0.36f, false },
    };
    float4* slots[] = { &c.cvTurret0_0, &c.cvTurret1_0, &c.cvTurret2_0, &c.cvTurret3_0, &c.cvTurret4_0 };
    const float R = c.cvHeroRadius_0;
    int n = 0;
    for (const Spec& s : specs) {
        if (s.shoulder && !shoulders) continue;
        *slots[n++] = make_float4(c.cvHeroAt_0.x + R * (s.along * ux + s.across * vx),
                                  c.cvHeroAt_0.y + R * (s.along * uz + s.across * vz),
                                  R * s.radius, c.cvHeroTop_0 * s.top);
    }
    c.cvTurretCount_0 = n;
    c.cvMoat_0        = moat;

    // THE GROUP'S CIRCLE, as SlangBridge.h sizes it -- without it the density looks for no
    // group at all, and every check below would pass on the lone hero.
    const float lift = 1.5f * c.cvBillow_0 * c.cvHeroBillow_0 + 24.0f;
    float reach = 1.3f * R;
    for (int k = 0; k < n; ++k) {
        const float4 t = *slots[k];
        const float out = std::max(t.z + lift, 1.3f * t.z);
        reach = std::max(reach, std::hypot(t.x - c.cvHeroAt_0.x, t.y - c.cvHeroAt_0.y) + out);
    }
    c.cvGroupReach_0 = reach * 1.01f + 10.0f;
}

float4 turretOf(const ConvectionInput_0& c, int k) {
    const float4 all[] = { c.cvTurret0_0, c.cvTurret1_0, c.cvTurret2_0, c.cvTurret3_0, c.cvTurret4_0 };
    return all[k];
}

} // namespace

int main() {
    int deviceCount = 0;
    if (cudaGetDeviceCount(&deviceCount) != cudaSuccess || deviceCount == 0) {
        std::printf("no CUDA device -- skipping (this test needs a GPU)\n");
        return 0;
    }

    int failures = 0;

    // -----------------------------------------------------------------------
    // 1. The bound is above the density, everywhere anyone has looked
    // -----------------------------------------------------------------------
    std::printf("1. The box bound against the density inside each box\n\n");
    std::printf("  %-26s %7s %9s %11s %12s\n", "field", "boxes", "zero", "violations", "worst ratio");

    struct Case { const char* name; ConvectionInput_0 c; };
    std::vector<Case> cases;
    cases.push_back({ "open (polarity 0)",   defaults(0.0f) });
    cases.push_back({ "closed (polarity 1)", defaults(1.0f) });
    cases.push_back({ "halfway (0.5)",       defaults(0.5f) });
    {
        ConvectionInput_0 c = defaults(0.3f);
        c.cvCoverage_0 = 1.0f;   // the whole sky: thresholds everywhere
        c.cvShape_0    = 0.45f;
        c.cvOctaves_0  = 4;
        cases.push_back({ "full coverage, 4 octaves", c });
    }
    {
        ConvectionInput_0 c = defaults(0.8f);
        c.cvSpacing_0 = 250.0f;  // cells smaller than the billows
        c.cvBillow_0  = 0.0f;
        cases.push_back({ "small cells, no billow", c });
    }
    // THE HERO: its own closed-form tower and its own scaled billows, beside the field and
    // alone. Placed near the origin, so the random boxes meet it as well as the seeds do.
    {
        ConvectionInput_0 c = defaults(0.0f);
        c.cvHeroAt_0     = make_float2(500.0f, -800.0f);
        c.cvHeroRadius_0 = 2000.0f;
        c.cvHeroTop_0    = 1500.0f;
        c.cvHeroSeed_0   = make_float3(1731.0f, 613.0f, 2477.0f);
        c.cvHeroBillow_0 = 2.0f;
        cases.push_back({ "hero with the field", c });
        c.cvHeroAlone_0  = 1;
        cases.push_back({ "hero alone", c });
    }
    // THE ORGANIZATION GROUP (build 20): its factors are all at most one and its slope is
    // clamped to what the bound divides by, and this is where a slip in either shows.
    for (const auto& oc : organizedCases()) cases.push_back({ oc.first, oc.second });

    // PAREIDOLIA (build 21): the map stood up on the hero at three facings, blended into the
    // tower, at full billows, and forgotten. THE MAP'S BUFFER OUTLIVES EVERY CASE.
    const std::vector<float> shapeHost = shapeTexels();
    Device<float> shapeMap(shapeHost.size());
    shapeMap.put(shapeHost);
    {
        ConvectionInput_0 c = shapeHero(0.0f, false);
        addShape(c, shapeMap, 0.0f, 0.0f, 0.2f);
        cases.push_back({ "shape, facing 0", c });

        c = shapeHero(0.0f, true);
        addShape(c, shapeMap, 37.0f, 0.4f, 0.2f);
        cases.push_back({ "shape alone, 37 deg, decay .4", c });

        c = shapeHero(0.5f, true);
        addShape(c, shapeMap, 200.0f, 0.0f, 1.0f);
        cases.push_back({ "shape alone, 200 deg, billow 1", c });

        c = shapeHero(0.0f, true);
        addShape(c, shapeMap, 123.0f, 1.0f, 0.2f);
        cases.push_back({ "shape alone, decay 1", c });
    }

    // HERO CONNECTION (build 22): the group's domes, and the moat's slope term in the
    // field's clamp. The organized case is where the moat's term and the organization's
    // add up.
    {
        ConvectionInput_0 c = defaults(0.0f);
        c.cvHeroAt_0     = make_float2(500.0f, -800.0f);
        c.cvHeroRadius_0 = 1500.0f;
        c.cvHeroTop_0    = 1500.0f;
        c.cvHeroSeed_0   = make_float3(1731.0f, 613.0f, 2477.0f);
        c.cvHeroBillow_0 = 1.67f;
        addGroup(c, 1.0f, true);
        cases.push_back({ "group with the field", c });
        c.cvHeroAlone_0 = 1;
        cases.push_back({ "group alone", c });

        ConvectionInput_0 o = defaults(0.6f);
        o.cvCoverage_0 = 0.9f;
        organize(o, 30.0f, 3.0f, 0.7f);
        addWave(o, 60.0f, 2200.0f, 0.7f);
        o.cvGapWidth_0   = 0.4f;
        o.cvHeroAt_0     = make_float2(-1200.0f, 300.0f);
        o.cvHeroRadius_0 = 700.0f;       // smaller than a cell: the narrowest moat bands
        o.cvHeroTop_0    = 1400.0f;
        o.cvHeroBillow_0 = 0.78f;        // under one: the turrets' billow is the hero's
        addGroup(o, 0.5f, true);
        cases.push_back({ "group, half moat, organized", o });

        ConvectionInput_0 s = shapeHero(0.0f, false);
        addShape(s, shapeMap, 37.0f, 0.3f, 0.2f);
        addGroup(s, 1.0f, false);
        cases.push_back({ "shape with the flanking line", s });
    }

    // MAMMA (build 23): pouches under a closed deck, under the hero, and under the group.
    // The boxes and the seeds below reach down to the deepest pouch.
    {
        ConvectionInput_0 c = defaults(1.0f);
        c.cvCoverage_0   = 0.9f;
        c.cvMammaDepth_0 = 360.0f;
        c.cvPouchSize_0  = 450.0f;
        cases.push_back({ "closed deck, mamma", c });

        ConvectionInput_0 h = defaults(0.0f);
        h.cvHeroAt_0     = make_float2(500.0f, -800.0f);
        h.cvHeroRadius_0 = 1500.0f;
        h.cvHeroTop_0    = 1500.0f;
        h.cvHeroSeed_0   = make_float3(1731.0f, 613.0f, 2477.0f);
        h.cvHeroBillow_0 = 1.67f;
        h.cvMammaDepth_0 = 200.0f;
        h.cvPouchSize_0  = 300.0f;
        h.cvHeroAlone_0  = 1;
        cases.push_back({ "hero alone, mamma", h });
        addGroup(h, 1.0f, true);
        h.cvHeroAlone_0  = 0;
        cases.push_back({ "group, mamma", h });
    }

    // PILEUS AND VELUM (build 24): the cap and the veil with the field, and alone with a
    // gap that lets the billows push into the cap.
    {
        ConvectionInput_0 c = defaults(0.0f);
        c.cvHeroAt_0     = make_float2(500.0f, -800.0f);
        c.cvHeroRadius_0 = 1500.0f;
        c.cvHeroTop_0    = 1500.0f;
        c.cvHeroSeed_0   = make_float3(1731.0f, 613.0f, 2477.0f);
        c.cvHeroBillow_0 = 1.67f;
        c.cvPileusThick_0 = 260.0f;
        c.cvPileusGap_0   = 300.0f;
        c.cvVelumThick_0  = 200.0f;
        c.cvVelumHeight_0 = 900.0f;
        cases.push_back({ "cap and veil, the field", c });
        c.cvHeroAlone_0  = 1;
        c.cvPileusGap_0  = 60.0f;
        cases.push_back({ "cap and veil alone, gap 60", c });
    }

    const float extents[] = { 15.0f, 60.0f, 250.0f, 900.0f, 2500.0f };
    const int   perBox    = 192;

    for (const Case& k : cases) {
        const ConvectionInput_0& c = k.c;
        HostRng rng(0xc0ffee);

        // The layer's ceiling, as convCeiling has it: the field's or the hero's, billows in,
        // or the cap's and the veil's (build 24) -- else the boxes never reach the cap's top.
        const bool  hero    = c.cvHeroTop_0 > 0.0f;
        const float capTop  = hero && c.cvPileusThick_0 > 0.0f
                            ? c.cvHeroTop_0 + c.cvPileusGap_0 + c.cvPileusThick_0 : 0.0f;
        const float veilTop = hero && c.cvVelumThick_0 > 0.0f
                            ? c.cvVelumHeight_0 + 1.5f * c.cvVelumThick_0 : 0.0f;
        const float top = c.cvBase_0 + std::max(std::max(c.cvDepth_0 + c.cvBillow_0,
                                                         hero ? c.cvHeroTop_0 + c.cvBillow_0 * c.cvHeroBillow_0 : 0.0f),
                                                std::max(capTop, veilTop));

        // SEEDS: points already known to be cloud, which the second half of the boxes
        // centre on. Found by sampling the slab and keeping the ones with density.
        // A HERO ALONE IS ONE CLOUD IN A 40 KM SQUARE, about 1% of it, so its seeds are
        // looked for around it instead -- otherwise the half of the boxes meant to sit on
        // cloud would mostly sit on nothing.
        const bool   alone = c.cvHeroAlone_0 != 0 && c.cvHeroTop_0 > 0.0f;
        const float  span  = alone ? c.cvHeroRadius_0 * (c.cvTurretCount_0 > 0 ? 4.5f : 2.0f) : 20000.0f;
        const float2 mid   = alone ? c.cvHeroAt_0 : make_float2(0.0f, 0.0f);
        std::vector<float3> probe(200000);
        for (float3& p : probe) {
            p = make_float3(mid.x + rng.range(-span, span),
                            rng.range(c.cvBase_0 - c.cvMammaDepth_0, top),
                            mid.y + rng.range(-span, span));
        }
        const std::vector<float> probeD = densities(c, probe);
        std::vector<float3> cloud;
        for (size_t i = 0; i < probe.size(); ++i) if (probeD[i] > 0.0f) cloud.push_back(probe[i]);

        std::vector<float3> lo, hi, pts;
        const int nBoxes = 3000;
        for (int b = 0; b < nBoxes; ++b) {
            const float ex = extents[b % 5];
            const float ey = (b / 5) % 3 == 0 ? ex : ((b / 5) % 3 == 1 ? ex * 0.25f : top - c.cvBase_0);

            float3 centre;
            if (b % 2 == 1 && !cloud.empty()) {
                centre = cloud[static_cast<size_t>(rng.next() * cloud.size()) % cloud.size()];
            } else {
                centre = make_float3(rng.range(-20000.0f, 20000.0f),
                                     rng.range(c.cvBase_0 - 200.0f - c.cvMammaDepth_0, top + 200.0f),
                                     rng.range(-20000.0f, 20000.0f));
            }
            const float3 l = make_float3(centre.x - ex * rng.range(0.0f, 1.0f),
                                         centre.y - ey * rng.range(0.0f, 1.0f),
                                         centre.z - ex * rng.range(0.0f, 1.0f));
            const float3 h = make_float3(l.x + ex, l.y + ey, l.z + ex);
            lo.push_back(l);
            hi.push_back(h);

            // The corners, the centre, and the rest at random inside.
            for (int q = 0; q < perBox; ++q) {
                float3 p;
                if (q < 8) {
                    p = make_float3((q & 1) ? h.x : l.x, (q & 2) ? h.y : l.y, (q & 4) ? h.z : l.z);
                } else if (q == 8) {
                    p = make_float3((l.x + h.x) * 0.5f, (l.y + h.y) * 0.5f, (l.z + h.z) * 0.5f);
                } else {
                    p = make_float3(rng.range(l.x, h.x), rng.range(l.y, h.y), rng.range(l.z, h.z));
                }
                pts.push_back(p);
            }
        }

        const std::vector<float> bnd = bounds(c, lo, hi);
        const std::vector<float> den = densities(c, pts);

        int zeroBoxes = 0, violations = 0;
        double worst = 0.0;
        for (int b = 0; b < nBoxes; ++b) {
            if (bnd[b] <= 0.0f) ++zeroBoxes;
            for (int q = 0; q < perBox; ++q) {
                const float d = den[static_cast<size_t>(b) * perBox + q];
                if (d > bnd[b]) ++violations;
                if (d > 0.0f) {
                    const double r = bnd[b] > 0.0f ? d / static_cast<double>(bnd[b]) : 1e30;
                    worst = std::max(worst, r);
                }
            }
        }

        std::printf("  %-26s %7d %8.1f%% %11d %12.4f\n", k.name, nBoxes,
                    100.0 * zeroBoxes / nBoxes, violations, worst);

        if (violations > 0) {
            std::printf("    FAIL: %d samples exceed their box's bound -- the procedural\n", violations);
            std::printf("          majorant is BELOW the field, and delta tracking is biased\n");
            ++failures;
        }
        if (cloud.size() < 1000) {
            std::printf("    FAIL: only %zu cloud points found -- the boxes centred on cloud\n", cloud.size());
            std::printf("          test nothing, and the field is suspiciously empty\n");
            ++failures;
        }
    }

    // THE BOUND MUST ALSO BE USEFUL, or the grid is pure cost. Most random boxes in a
    // fair-weather field are clear air, and a bound that never says zero skips none of it.
    {
        const ConvectionInput_0 c = defaults(0.0f);
        HostRng rng(7);
        std::vector<float3> lo, hi;
        for (int b = 0; b < 4000; ++b) {
            const float3 l = make_float3(rng.range(-20000.0f, 20000.0f),
                                         rng.range(c.cvBase_0, c.cvBase_0 + c.cvDepth_0),
                                         rng.range(-20000.0f, 20000.0f));
            lo.push_back(l);
            hi.push_back(make_float3(l.x + 450.0f, l.y + 360.0f, l.z + 450.0f));
        }
        const std::vector<float> bnd = bounds(c, lo, hi);
        int zero = 0;
        for (float v : bnd) if (v <= 0.0f) ++zero;

        // AGAINST THE FRACTION THAT IS ACTUALLY EMPTY, which is the ceiling a bound can
        // reach: sample each box and count the ones where no sample found cloud.
        std::vector<float3> inside;
        const int per = 64;
        for (size_t b = 0; b < lo.size(); ++b)
            for (int q = 0; q < per; ++q)
                inside.push_back(make_float3(rng.range(lo[b].x, hi[b].x), rng.range(lo[b].y, hi[b].y),
                                             rng.range(lo[b].z, hi[b].z)));
        const std::vector<float> den = densities(c, inside);
        int empty = 0;
        for (size_t b = 0; b < lo.size(); ++b) {
            bool any = false;
            for (int q = 0; q < per; ++q) any = any || den[b * per + q] > 0.0f;
            if (!any) ++empty;
        }
        std::printf("\n  shipping-sized boxes (450 x 360 x 450 m): proved empty %.1f%%, "
                    "found empty by sampling %.1f%%\n",
                    100.0 * zero / bnd.size(), 100.0 * empty / bnd.size());
        // ===================================================================
        // REPORTED, NO LONGER A GATE -- AND THAT IS A REGRESSION OF THE OPTIONAL GRID, NOT
        // A TEST MADE TO PASS.
        //
        // Until build 15 the billows only moved the surface vertically, so a box over
        // every top was provably clear. Now they reach sideways off the walls, and proving
        // a box clear needs the updraft's slope; the only slope that bounds soundly is the
        // steepest a kernel can be (kConvGradMax), which is loose, so small boxes are not
        // proved empty. The bound stays SOUND -- section 1 above, zero violations -- it has
        // stopped being useful.
        //
        // THE GRID WAS ALREADY OFF, because it was measured a loss in every cloudy scene
        // (PROGRESS.md, 2026-09-29), and `--conv-grid 1` is an A/B switch only. Nothing
        // that ships consults this bound. If the grid is ever revived, this is the line
        // to make a gate again, with a per-box slope bound behind it.
        // ===================================================================
        if (zero == 0) {
            std::printf("    note: the bound never says zero at this box size -- the optional\n"
                        "          grid would skip nothing (it is off; see the comment above)\n");
        }
    }

    // -----------------------------------------------------------------------
    // 2. The base is flat, and the lid holds
    // -----------------------------------------------------------------------
    std::printf("\n2. The base and the lid\n\n");
    {
        const ConvectionInput_0 c = defaults(0.0f);
        const int side = 300;
        std::vector<float3> below, justAbove, higher, overLid;
        for (int j = 0; j < side; ++j) {
            for (int i = 0; i < side; ++i) {
                const float x = -15000.0f + 30000.0f * (i + 0.5f) / side;
                const float z = -15000.0f + 30000.0f * (j + 0.5f) / side;
                below.push_back(make_float3(x, c.cvBase_0 - 0.5f, z));
                justAbove.push_back(make_float3(x, c.cvBase_0 + 0.5f, z));
                higher.push_back(make_float3(x, c.cvBase_0 + 60.0f, z));
                overLid.push_back(make_float3(x, c.cvBase_0 + c.cvDepth_0 + c.cvBillow_0 + 1.0f, z));
            }
        }
        const std::vector<float> dBelow = densities(c, below);
        const std::vector<float> dJust  = densities(c, justAbove);
        const std::vector<float> dHigh  = densities(c, higher);
        const std::vector<float> dOver  = densities(c, overLid);

        int belowCount = 0, overCount = 0, cloudy = 0, reachesBase = 0;
        for (size_t i = 0; i < dBelow.size(); ++i) {
            if (dBelow[i] > 0.0f) ++belowCount;
            if (dOver[i]  > 0.0f) ++overCount;
            if (dHigh[i]  > 0.0f) {
                ++cloudy;
                if (dJust[i] > 0.0f) ++reachesBase;
            }
        }
        const double flat = cloudy ? static_cast<double>(reachesBase) / cloudy : 0.0;
        std::printf("  columns with cloud 60 m up: %d; of those, cloud 0.5 m up: %.1f%%\n",
                    cloudy, 100.0 * flat);
        std::printf("  columns with cloud below the base: %d; above the lid: %d\n",
                    belowCount, overCount);

        if (belowCount > 0 || overCount > 0) {
            std::printf("    FAIL: cloud outside [base, top]\n");
            ++failures;
        }
        // THE BASE IS THE CONDENSATION LEVEL, so a column that is cloud a little way up
        // is cloud all the way down to it. Not quite all: a billow biting into a thin
        // column near its footprint's edge can open it from below.
        if (cloudy < 1000 || flat < 0.9) {
            std::printf("    FAIL: the base is not flat -- cloud stops short of the\n");
            std::printf("          condensation level in %.1f%% of cloudy columns\n",
                        100.0 * (1.0 - flat));
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 3. Polarity: closed cells rise at the centres, open cells at the rims
    // -----------------------------------------------------------------------
    std::printf("\n3. Polarity\n\n");
    {
        // The cells in a patch, read back from the kernel: centre and vigour.
        const int n = 40;
        std::vector<int2> slots;
        for (int j = 0; j < n; ++j) for (int i = 0; i < n; ++i) slots.push_back(make_int2(i - 20, j - 20));

        const ConvectionInput_0 base = defaults(0.0f);
        Device<int2>   dSlots(slots.size());
        Device<float3> dCells(slots.size());
        dSlots.put(slots);
        convCells<<<blocks(slots.size()), 64>>>(base, dSlots.ro(), dCells.rw(), static_cast<int>(slots.size()));
        const std::vector<float3> cells = dCells.get();

        // Centres of vigorous cells, and midpoints between vigorous neighbours along x.
        //
        // WELL-SEPARATED PAIRS ONLY. Two jittered neighbours can sit 0.3 slots apart,
        // and then each one's centre IS near the rim between them -- the geometry, not
        // the field, puts rising air there. The claim is about a cell's middle against
        // its edge, so the pairs are ones where those are different places.
        std::vector<float2> centres, midpoints;
        for (int j = 0; j < n; ++j) {
            for (int i = 0; i + 1 < n; ++i) {
                const float3 a = cells[j * n + i];
                const float3 b = cells[j * n + i + 1];
                if (a.z < 0.3f || b.z < 0.3f) continue;
                const float sep = std::sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
                if (sep < 0.9f) continue;
                centres.push_back(make_float2(a.x * base.cvSpacing_0, a.y * base.cvSpacing_0));
                midpoints.push_back(make_float2((a.x + b.x) * 0.5f * base.cvSpacing_0,
                                                (a.y + b.y) * 0.5f * base.cvSpacing_0));
            }
        }

        auto mean = [](const std::vector<float>& v) {
            double s = 0.0; for (float x : v) s += x; return v.empty() ? 0.0 : s / v.size();
        };

        const double openC   = mean(updrafts(defaults(0.0f), centres, false));
        const double openM   = mean(updrafts(defaults(0.0f), midpoints, false));
        const double closedC = mean(updrafts(defaults(1.0f), centres, false));
        const double closedM = mean(updrafts(defaults(1.0f), midpoints, false));

        std::printf("  %zu vigorous neighbour pairs\n", centres.size());
        std::printf("  %-10s %12s %12s\n", "", "at centres", "on the rims");
        std::printf("  %-10s %12.3f %12.3f\n", "open",   openC,   openM);
        std::printf("  %-10s %12.3f %12.3f\n", "closed", closedC, closedM);

        // THE OPEN FIELD'S UPPER PERCENTILES, which is where kConvOpenNorm comes from: a
        // vigorous rim should sit near one, not far past it (clamped flat) and not far
        // below it (so the whole field is weak against the moisture threshold).
        {
            HostRng r3(3);
            std::vector<float2> anywhere(200000);
            for (float2& p : anywhere) p = make_float2(r3.range(-40000.0f, 40000.0f), r3.range(-40000.0f, 40000.0f));
            std::vector<float> v = updrafts(defaults(0.0f), anywhere, false);
            std::sort(v.begin(), v.end());
            int clamped = 0; for (float x : v) if (x >= 1.0f) ++clamped;
            std::printf("  open field: p50 %.3f, p90 %.3f, p99 %.3f, at the clamp %.2f%%\n",
                        v[v.size() / 2], v[v.size() * 9 / 10], v[v.size() * 99 / 100],
                        100.0 * clamped / v.size());
        }

        if (centres.size() < 50) {
            std::printf("    FAIL: too few vigorous pairs to say anything\n");
            ++failures;
        }
        if (!(openM > 2.0 * openC)) {
            std::printf("    FAIL: open cells do not rise at the rims\n");
            ++failures;
        }
        if (!(closedC > 2.0 * closedM)) {
            std::printf("    FAIL: closed cells do not rise at the centres\n");
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 4. The 3x3 neighbourhood is the whole field
    // -----------------------------------------------------------------------
    std::printf("\n4. The 3x3 window against a 5x5 one\n\n");
    {
        HostRng rng(99);
        std::vector<float2> pts(100000);
        for (float2& p : pts) p = make_float2(rng.range(-50000.0f, 50000.0f), rng.range(-50000.0f, 50000.0f));

        // The plain field at three polarities, then every organized case: the lattice is
        // rotated, stretched, straightened and warped there, and the window must still be
        // all of it.
        std::vector<std::pair<std::string, ConvectionInput_0>> windowCases;
        for (float pol : { 0.0f, 0.5f, 1.0f }) {
            char name[32];
            std::snprintf(name, sizeof name, "polarity %.1f", pol);
            windowCases.push_back({ name, defaults(pol) });
        }
        for (const auto& oc : organizedCases()) windowCases.push_back({ oc.first, oc.second });

        for (const auto& wc : windowCases) {
            const ConvectionInput_0& c = wc.second;
            const std::vector<float> a = updrafts(c, pts, false);
            const std::vector<float> b = updrafts(c, pts, true);
            int differ = 0;
            for (size_t i = 0; i < a.size(); ++i) if (a[i] != b[i]) ++differ;
            std::printf("  %-26s %d of %zu points differ\n", wc.first.c_str(), differ, a.size());
            if (differ > 0) {
                std::printf("    FAIL: a cell two slots away reaches the point -- the 3x3\n");
                std::printf("          window is not the whole field, and the bound's slot\n");
                std::printf("          range is not all the cells that can reach a box\n");
                ++failures;
            }
        }
    }

    // -----------------------------------------------------------------------
    // 5. More moisture, more cloud
    // -----------------------------------------------------------------------
    std::printf("\n5. Coverage against cloud fraction, 100 m above the base\n\n");
    {
        HostRng rng(5);
        std::vector<float3> pts(200000);
        double previous = -1.0;
        for (float cover : { 0.2f, 0.4f, 0.6f, 0.8f, 1.0f }) {
            ConvectionInput_0 c = defaults(0.0f);
            c.cvCoverage_0 = cover;
            HostRng r2(5);
            for (float3& p : pts) p = make_float3(r2.range(-30000.0f, 30000.0f), c.cvBase_0 + 100.0f,
                                                  r2.range(-30000.0f, 30000.0f));
            const std::vector<float> d = densities(c, pts);
            int cloudy = 0;
            for (float v : d) if (v > 0.0f) ++cloudy;
            const double frac = static_cast<double>(cloudy) / d.size();
            std::printf("  coverage %.1f: %5.1f%% of the sky\n", cover, 100.0 * frac);
            if (!(frac > previous)) {
                std::printf("    FAIL: more moisture did not make more cloud\n");
                ++failures;
            }
            previous = frac;
        }
    }

    // -----------------------------------------------------------------------
    // 6. The billows are centred
    // -----------------------------------------------------------------------
    std::printf("\n6. The billow's distribution\n\n");
    {
        const ConvectionInput_0 c = defaults(0.0f);
        HostRng rng(11);
        std::vector<float3> pts(400000);
        for (float3& p : pts) p = make_float3(rng.range(-5000.0f, 5000.0f), rng.range(0.0f, 3000.0f),
                                              rng.range(-5000.0f, 5000.0f));
        Device<float3> in(pts.size());
        Device<float>  out(pts.size());
        in.put(pts);
        convBillowAt<<<blocks(pts.size()), 64>>>(c, in.ro(), out.rw(), static_cast<int>(pts.size()));
        const std::vector<float> v = out.get();

        double s = 0.0, s2 = 0.0; int atTop = 0, atBottom = 0;
        for (float x : v) { s += x; s2 += x * x; if (x >= 1.0f) ++atTop; if (x <= -1.0f) ++atBottom; }
        const double m  = s / v.size();
        const double sd = std::sqrt(std::max(0.0, s2 / v.size() - m * m));
        std::printf("  mean %+.3f, std %.3f, clamped at +1: %.1f%%, at -1: %.1f%%\n",
                    m, sd, 100.0 * atTop / v.size(), 100.0 * atBottom / v.size());
        if (std::fabs(m) > 0.25) {
            std::printf("    FAIL: the billows are off-centre -- they %s the cloud on average\n",
                        m > 0 ? "inflate" : "shrink");
            ++failures;
        }
    }

    // -----------------------------------------------------------------------
    // 7. The Organization group does what each control says (build 20)
    // -----------------------------------------------------------------------
    std::printf("\n7. Organization\n\n");
    {
        auto check = [&](bool ok, const char* what) {
            if (!ok) { std::printf("    FAIL: %s\n", what); ++failures; }
        };

        HostRng rng(2020);
        std::vector<float2> flat(100000);
        for (float2& p : flat) p = make_float2(rng.range(-30000.0f, 30000.0f), rng.range(-30000.0f, 30000.0f));

        // (a) SWITCHED ON AT THE IDENTITY IS THE OLD FIELD, BIT FOR BIT: rows along +X,
        // no stretch, no coherence, no wave. The updraft AND the density, since the
        // density also reads the slope cap, which must then be the old constant.
        {
            ConvectionInput_0 off = defaults(0.4f);
            ConvectionInput_0 on  = off;
            on.cvOrg_0.ogOn_0      = 1;
            on.cvOrg_0.ogAxis_0    = make_float2(1.0f, 0.0f);
            on.cvOrg_0.ogStretch_0 = 1.0f;
            const std::vector<float> a = updrafts(off, flat, false);
            const std::vector<float> b = updrafts(on, flat, false);
            std::vector<float3> pts;
            for (size_t i = 0; i < 50000; ++i)
                pts.push_back(make_float3(flat[i].x, off.cvBase_0 + rng.range(0.0f, 1400.0f), flat[i].y));
            const std::vector<float> da = densities(off, pts);
            const std::vector<float> db = densities(on, pts);
            int differ = 0, differD = 0;
            for (size_t i = 0; i < a.size(); ++i) if (a[i] != b[i]) ++differ;
            for (size_t i = 0; i < da.size(); ++i) if (da[i] != db[i]) ++differD;
            std::printf("  identity on vs off: %d updrafts and %d densities differ\n", differ, differD);
            check(differ == 0 && differD == 0, "organization at the identity moved the field");
        }

        // (b) ROLLS ARE LONGER ALONG THE ROWS: the updraft one cell away along the rows is
        // far more like the updraft here than one cell away across them.
        {
            ConvectionInput_0 c = defaults(0.3f);
            organize(c, 30.0f, 4.0f, 1.0f);
            const float2 along  = c.cvOrg_0.ogAxis_0;
            const float2 across = make_float2(-along.y, along.x);
            const float  lag    = c.cvSpacing_0;
            std::vector<float2> here, alongPts, acrossPts;
            for (size_t i = 0; i < 40000; ++i) {
                here.push_back(flat[i]);
                alongPts.push_back(make_float2(flat[i].x + along.x * lag, flat[i].y + along.y * lag));
                acrossPts.push_back(make_float2(flat[i].x + across.x * lag, flat[i].y + across.y * lag));
            }
            const std::vector<float> w0 = updrafts(c, here, false);
            const std::vector<float> w1 = updrafts(c, alongPts, false);
            const std::vector<float> w2 = updrafts(c, acrossPts, false);
            auto corr = [](const std::vector<float>& x, const std::vector<float>& y) {
                double mx = 0, my = 0;
                for (size_t i = 0; i < x.size(); ++i) { mx += x[i]; my += y[i]; }
                mx /= x.size(); my /= y.size();
                double sxy = 0, sxx = 0, syy = 0;
                for (size_t i = 0; i < x.size(); ++i) {
                    sxy += (x[i] - mx) * (y[i] - my);
                    sxx += (x[i] - mx) * (x[i] - mx);
                    syy += (y[i] - my) * (y[i] - my);
                }
                return sxy / std::sqrt(sxx * syy + 1e-30);
            };
            const double ca = corr(w0, w1), cx = corr(w0, w2);
            std::printf("  rolls: correlation one cell along the rows %.3f, across %.3f\n", ca, cx);
            check(ca > cx + 0.3, "rolls are not longer along their rows than across them");
        }

        // (c) COHERENCE 1 RULES THE ROWS: every centre sits exactly mid-slot across them.
        {
            ConvectionInput_0 c = defaults(0.3f);
            organize(c, 30.0f, 1.0f, 1.0f);
            std::vector<int2> slots;
            for (int j = -20; j < 20; ++j) for (int i = -20; i < 20; ++i) slots.push_back(make_int2(i, j));
            Device<int2>   in(slots.size());
            Device<float3> out(slots.size());
            in.put(slots);
            convCells<<<blocks(slots.size()), 64>>>(c, in.ro(), out.rw(), static_cast<int>(slots.size()));
            const std::vector<float3> cells = out.get();
            int offRow = 0, movedAlong = 0;
            for (size_t i = 0; i < cells.size(); ++i) {
                if (cells[i].y != static_cast<float>(slots[i].y) + 0.5f) ++offRow;
                if (cells[i].x != static_cast<float>(slots[i].x) + 0.5f) ++movedAlong;
            }
            std::printf("  coherence 1: %d of %zu centres off their row (must be 0), %d jittered along it\n",
                        offRow, cells.size(), movedAlong);
            check(offRow == 0 && movedAlong > static_cast<int>(cells.size()) / 2,
                  "coherence 1 left centres off their rows, or stopped the jitter along them");
        }

        // (d) AMPLITUDE 1 CLEARS THE TROUGHS: on a trough line the updraft is nothing.
        {
            ConvectionInput_0 c = defaults(0.6f);
            organize(c, 90.0f, 1.0f, 0.0f);
            addWave(c, 40.0f, 3000.0f, 1.0f);
            // Trough n is where q . k = n; a point slides along it in the crests' direction.
            const float2 k  = c.cvOrg_0.ogWaveK_0;
            const float  kk = k.x * k.x + k.y * k.y;
            const float  kl = std::sqrt(kk);
            const float2 crest = make_float2(-k.y / kl, k.x / kl);
            std::vector<float2> trough;
            for (int n = -8; n <= 8; ++n)
                for (int t = 0; t < 400; ++t) {
                    const float s = rng.range(-20000.0f, 20000.0f);
                    trough.push_back(make_float2(k.x / kk * n + crest.x * s, k.y / kk * n + crest.y * s));
                }
            const std::vector<float> w = updrafts(c, trough, false);
            float worst = 0.0f;
            for (float v : w) worst = std::max(worst, v);
            std::printf("  wave amplitude 1: largest updraft on %zu trough points %.2e\n", w.size(), worst);
            check(worst < 1e-4f, "a trough of a full-amplitude wave still has updraft");
        }

        // (e) GAP FRACTION THINS A DECK, MONOTONICALLY, AND LEAVES OPEN CELLS ALONE.
        {
            std::vector<float3> pts;
            for (size_t i = 0; i < 60000; ++i) pts.push_back(make_float3(flat[i].x, 680.0f + 100.0f, flat[i].y));
            double previous = 2.0;
            bool monotone = true;
            for (float gap : { 0.0f, 0.2f, 0.45f, 0.7f, 0.9f }) {
                ConvectionInput_0 c = defaults(1.0f);
                c.cvCoverage_0 = 0.9f;
                organize(c, 90.0f, 1.0f, 0.0f);
                c.cvGapWidth_0 = gap;
                const std::vector<float> d = densities(c, pts);
                int cloudy = 0;
                for (float v : d) if (v > 0.0f) ++cloudy;
                const double frac = static_cast<double>(cloudy) / d.size();
                std::printf("  closed deck, gap width %.2f: %5.1f%% cloud\n", gap, 100.0 * frac);
                monotone = monotone && frac < previous;
                previous = frac;
            }
            check(monotone, "a wider gap did not make less cloud");

            ConvectionInput_0 open = defaults(0.0f);
            organize(open, 90.0f, 1.0f, 0.0f);
            ConvectionInput_0 openGap = open;
            openGap.cvGapWidth_0 = 0.5f;
            const std::vector<float> a = updrafts(open, flat, false);
            const std::vector<float> b = updrafts(openGap, flat, false);
            int differ = 0;
            for (size_t i = 0; i < a.size(); ++i) if (a[i] != b[i]) ++differ;
            std::printf("  open cells with gaps: %d of %zu updrafts moved (must be 0)\n", differ, a.size());
            check(differ == 0, "gaps changed open cells");
        }

        // (f) LACUNARITY: A THIN SHEET WITH A ROUND HOLE AT EVERY CELL. From a quarter of
        // the slider up, every vigorous centre is a hole, and the holes widen from there
        // (less cloud near the centres); the sheet fills the seams and keeps them filled
        // (more cloud on them than without it); and at full lacunarity the layer is mostly
        // cloud with holes in it, not a few shards.
        //
        // NEAR-CENTRE CLOUD FIRST RISES, and that is the model: at a quarter the sheet has
        // already filled what the deck left clear, while the holes are still small. MEASURED
        // when written: 81% near the centres with no lacunarity, 86% at 0.25, 20% at 1.
        //
        // THREE VERSIONS FAILED BEFORE THIS ONE, which is why each claim is here: holes in
        // the deck alone left 0.8% of it; a blend towards a holed sheet opened no hole
        // below about 0.8 on the slider; and a sheet of the largest kernel rendered as
        // shards and pits, because that kernel carries each cell's vigour.
        {
            ConvectionInput_0 c = defaults(1.0f);
            c.cvCoverage_0 = 0.9f;
            organize(c, 60.0f, 1.0f, 0.0f);
            std::vector<int2> slots;
            for (int j = -15; j < 15; ++j) for (int i = -15; i < 15; ++i) slots.push_back(make_int2(i, j));
            Device<int2>   in(slots.size());
            Device<float3> out(slots.size());
            in.put(slots);
            convCells<<<blocks(slots.size()), 64>>>(c, in.ro(), out.rw(), static_cast<int>(slots.size()));
            const std::vector<float3> cells = out.get();

            std::vector<float2> allCentres, vigorous;
            for (const float3& cell : cells) {
                if (cell.z <= 0.0f) continue;
                const float2 w = centreToWorld(c, make_float2(cell.x, cell.y));
                allCentres.push_back(w);
                if (cell.z > 0.2f) vigorous.push_back(w);
            }

            // Points at 100 m, each with its distance to the nearest centre in cells.
            std::vector<float3> pts;
            std::vector<float>  nearest;
            HostRng pr(77);
            for (int n = 0; n < 60000; ++n) {
                const float x = pr.range(-20000.0f, 20000.0f), z = pr.range(-20000.0f, 20000.0f);
                float best = 1e30f;
                for (const float2& ce : allCentres) {
                    const float dx = x - ce.x, dz = z - ce.y;
                    best = std::min(best, dx * dx + dz * dz);
                }
                pts.push_back(make_float3(x, 680.0f + 100.0f, z));
                nearest.push_back(std::sqrt(best) / c.cvSpacing_0);
            }

            bool holedEverywhere = true, widening = true, filling = true;
            double prevNear = 2.0, prevSeam = -1.0, fullFrac = 0.0, seamAtZero = 0.0;
            for (float lac : { 0.0f, 0.25f, 0.5f, 1.0f }) {
                ConvectionInput_0 holed = c;
                holed.cvLacunarity_0 = lac;
                const std::vector<float> w = updrafts(holed, vigorous, false);
                int centresWithUpdraft = 0;
                for (float v : w) if (v > 0.0f) ++centresWithUpdraft;

                const std::vector<float> d = densities(holed, pts);
                int nearN = 0, nearCloud = 0, seamN = 0, seamCloud = 0, cloudy = 0;
                for (size_t k = 0; k < d.size(); ++k) {
                    const bool cloud = d[k] > 0.0f;
                    cloudy += cloud ? 1 : 0;
                    if (nearest[k] < 0.15f) { ++nearN; nearCloud += cloud ? 1 : 0; }
                    if (nearest[k] > 0.6f)  { ++seamN; seamCloud += cloud ? 1 : 0; }
                }
                const double nearFrac = nearN ? static_cast<double>(nearCloud) / nearN : 0.0;
                const double seamFrac = seamN ? static_cast<double>(seamCloud) / seamN : 0.0;
                const double frac     = static_cast<double>(cloudy) / d.size();
                std::printf("  lacunarity %.2f: updraft at %4d of %zu centres; cloud %5.1f%%, "
                            "near centres %5.1f%%, on seams %5.1f%%\n", lac, centresWithUpdraft,
                            vigorous.size(), 100.0 * frac, 100.0 * nearFrac, 100.0 * seamFrac);

                if (lac >= 0.25f && centresWithUpdraft > 0) holedEverywhere = false;
                if (lac > 0.25f) widening = widening && nearFrac < prevNear;
                if (lac > 0.0f)  filling  = filling && seamFrac >= prevSeam && seamFrac > seamAtZero + 0.2;
                if (lac == 0.0f) seamAtZero = seamFrac;
                prevNear = nearFrac;
                prevSeam = seamFrac;
                fullFrac = frac;
            }
            check(holedEverywhere, "a vigorous centre kept its updraft with lacunarity on");
            check(widening, "the holes did not widen as lacunarity rose");
            check(filling, "the sheet did not fill the seams as lacunarity rose");
            check(fullFrac > 0.3 && fullFrac < 0.95, "full lacunarity is not a sheet with holes");
        }
    }

    // -----------------------------------------------------------------------
    // 8. Pareidolia: the picture is the cloud, and forgetting it is the tower (build 21)
    // -----------------------------------------------------------------------
    std::printf("\n8. Pareidolia\n\n");
    {
        auto check = [&](bool ok, const char* what) {
            if (!ok) { std::printf("    FAIL: %s\n", what); ++failures; }
        };
        HostRng rng(2121);

        // (a) DECAY 1 FACING 0 IS THE HERO WITHOUT A SHAPE, BIT FOR BIT. At bearing 0 the
        // plane's frame is the world's exactly (x * 1 + z * 0), and decay 1 takes the
        // tower's own path, so nothing may differ -- the density or the bound.
        {
            ConvectionInput_0 plain = shapeHero(0.0f, true);
            ConvectionInput_0 gone  = plain;
            addShape(gone, shapeMap, 0.0f, 1.0f, 0.2f);

            std::vector<float3> pts(100000);
            for (float3& q : pts) {
                q = make_float3(-300.0f + rng.range(-1500.0f, 1500.0f),
                                plain.cvBase_0 + rng.range(-50.0f, 2400.0f),
                                700.0f + rng.range(-1500.0f, 1500.0f));
            }
            const std::vector<float> a = densities(plain, pts);
            const std::vector<float> b = densities(gone, pts);
            int differ = 0, cloudy = 0;
            for (size_t i = 0; i < a.size(); ++i) {
                if (a[i] != b[i]) ++differ;
                if (a[i] > 0.0f) ++cloudy;
            }
            std::printf("  decay 1 against no shape: %d of %zu densities differ (%d cloud)\n",
                        differ, a.size(), cloudy);
            check(differ == 0, "decay 1 is not the ordinary hero");
            check(cloudy > 1000, "too little of the hero was sampled to mean anything");
        }

        // (b) WITH NO BILLOWS, THE PLANE'S CROSS-SECTION IS THE SILHOUETTE: on the plane the
        // profile's distance is D itself, so cloud stands exactly where the map is inside.
        // Checked away from the edge by more than the soft edge and a texel's rounding --
        // and at every facing, so the axis and its sign are the ones the host resolves.
        for (float bearing : { 0.0f, 90.0f, 211.0f }) {
            ConvectionInput_0 c = shapeHero(0.0f, true);
            c.cvBillow_0 = 0.0f;
            addShape(c, shapeMap, bearing, 0.0f, 0.0f);
            const float b = bearing * 0.01745329252f;
            const float ux = std::cos(b), uz = -std::sin(b);

            std::vector<float3> pts;
            std::vector<float>  sdf;
            for (int k = 0; k < 60000; ++k) {
                const float u = rng.range(-900.0f, 900.0f);
                const float y = rng.range(60.0f, 1700.0f);
                const float x = u / kShapeTexel + kShapeOffsetU;
                const float z = y / kShapeTexel + kShapeOffsetY;
                const float d = shapeSdf(x, z) * kShapeTexel;
                if (std::fabs(d) < 30.0f) continue;          // the soft edge, and a texel
                pts.push_back(make_float3(c.cvHeroAt_0.x + u * ux, c.cvBase_0 + y, c.cvHeroAt_0.y + u * uz));
                sdf.push_back(d);
            }
            const std::vector<float> den = densities(c, pts);
            int wrong = 0, inside = 0;
            for (size_t i = 0; i < pts.size(); ++i) {
                if ((den[i] > 0.0f) != (sdf[i] > 0.0f)) ++wrong;
                if (sdf[i] > 0.0f) ++inside;
            }
            std::printf("  facing %5.1f: %d of %zu plane points disagree with the silhouette (%d inside)\n",
                        bearing, wrong, pts.size(), inside);
            check(wrong == 0, "the plane's cross-section is not the silhouette");
            check(inside > 5000, "too little of the silhouette was sampled");
        }

        // (c) THE RIMS ARE ROUND: along the normal through the disc's deepest point, the
        // cloud reaches out to R and no further (no billows), and through a point D inside
        // the edge, to sqrt(D (2R - D)).
        {
            ConvectionInput_0 c = shapeHero(0.0f, true);
            c.cvBillow_0 = 0.0f;
            addShape(c, shapeMap, 0.0f, 0.0f, 0.0f);
            const float R = c.cvShapeRound_0;
            // THE EXPECTATION FROM THE SAME DISTANCE FUNCTION, not from the disc alone: the
            // eye sits 23 texels from the disc's centre, and a first version of this check
            // expected R there and failed on the eye's own rim. One probe where D is past R
            // (the cushion's flat face), one 200 m inside the disc's left edge.
            struct Probe { float u; float y; float expect; };
            auto profileAt = [&](float u, float y) {
                const float d = shapeSdf(u / kShapeTexel + kShapeOffsetU, y / kShapeTexel + kShapeOffsetY) * kShapeTexel;
                return d >= R ? R : std::sqrt(d * (2.0f * R - d));
            };
            const Probe probes[] = { { 200.0f, 740.0f, profileAt(200.0f, 740.0f) },
                                     { -600.0f, 840.0f, profileAt(-600.0f, 840.0f) } };
            for (const Probe& pr : probes) {
                std::vector<float3> pts;
                for (int k = 0; k < 400; ++k) {
                    const float n = k * 2.5f;   // 0 .. 1000 m along the normal (+Z at bearing 0)
                    pts.push_back(make_float3(c.cvHeroAt_0.x + pr.u, c.cvBase_0 + pr.y, c.cvHeroAt_0.y + n));
                }
                const std::vector<float> den = densities(c, pts);
                float reach = 0.0f;
                for (int k = 0; k < 400; ++k) if (den[k] > 0.0f) reach = k * 2.5f;
                std::printf("  through u = %6.0f m the cloud reaches %6.1f m from the plane (profile %6.1f)\n",
                            pr.u, reach, pr.expect);
                check(std::fabs(reach - pr.expect) < 8.0f, "the rim is not the profile");
            }
        }
    }

    // -----------------------------------------------------------------------
    // 9. Hero Connection: the field yields to the group, and the group is local (build 22)
    // -----------------------------------------------------------------------
    std::printf("\n9. Hero Connection\n\n");
    {
        auto check = [&](bool ok, const char* what) {
            if (!ok) { std::printf("    FAIL: %s\n", what); ++failures; }
        };
        HostRng rng(2222);

        // (a) THE MOAT CLEARS THE FIELD UNDER THE HERO. A hero only 150 m tall, so the
        // field's towers would stand above it: well inside the moat's inner radius -- by more
        // than any billow reaches -- there must be no cloud above the hero's own ceiling,
        // where without the moat there is. THE HERO IS PUT ON A FIELD CLOUD, found by
        // sampling, so there is something to clear: the first place tried was clear air.
        {
            ConvectionInput_0 c = defaults(0.3f);
            c.cvCoverage_0   = 0.9f;
            c.cvHeroRadius_0 = 2500.0f;
            c.cvHeroTop_0    = 150.0f;
            c.cvHeroBillow_0 = 1.0f;

            std::vector<float3> probe(20000);
            for (float3& q : probe)
                q = make_float3(rng.range(-8000.0f, 8000.0f), c.cvBase_0 + rng.range(550.0f, 800.0f),
                                rng.range(-8000.0f, 8000.0f));
            const std::vector<float> probeD = densities(c, probe);   // no hero yet: cvHeroTop set, at 0,0
            float2 at = make_float2(0.0f, 0.0f);
            for (size_t i = 0; i < probe.size(); ++i)
                if (probeD[i] > 0.0f && std::hypot(probe[i].x, probe[i].z) > 3000.0f) {
                    at = make_float2(probe[i].x, probe[i].z);
                    break;
                }
            c.cvHeroAt_0 = at;

            const float inner = 0.75f * c.cvHeroRadius_0 - 600.0f;   // past every billow
            std::vector<float3> pts(100000);
            for (float3& q : pts) {
                const float a = rng.range(0.0f, 6.2831853f), r = inner * std::sqrt(rng.range(0.0f, 1.0f));
                q = make_float3(at.x + r * std::cos(a), c.cvBase_0 + rng.range(520.0f, 1400.0f),
                                at.y + r * std::sin(a));
            }
            const std::vector<float> open = densities(c, pts);
            ConvectionInput_0 m = c;
            m.cvMoat_0       = 1.0f;
            m.cvGroupReach_0 = 1.3f * m.cvHeroRadius_0 * 1.01f + 10.0f;
            const std::vector<float> moat = densities(m, pts);
            int before = 0, after = 0;
            for (size_t i = 0; i < pts.size(); ++i) {
                if (open[i] > 0.0f) ++before;
                if (moat[i] > 0.0f) ++after;
            }
            std::printf("  over a low hero's middle: field cloud at %d points without the moat, %d with it\n",
                        before, after);
            check(before > 500, "the field has no cloud over the hero to clear -- the test proves nothing");
            check(after == 0, "the moat left field cloud over the hero's middle");
        }

        // (b) EVERY TURRET IS CLOUD: on its axis at 40% of its height, alone with the hero.
        {
            ConvectionInput_0 c = defaults(0.0f);
            c.cvHeroAt_0     = make_float2(500.0f, -800.0f);
            c.cvHeroRadius_0 = 1500.0f;
            c.cvHeroTop_0    = 1500.0f;
            c.cvHeroSeed_0   = make_float3(1731.0f, 613.0f, 2477.0f);
            c.cvHeroBillow_0 = 1.67f;
            c.cvHeroAlone_0  = 1;
            addGroup(c, 1.0f, true);
            std::vector<float3> pts;
            for (int k = 0; k < c.cvTurretCount_0; ++k) {
                const float4 t = turretOf(c, k);
                pts.push_back(make_float3(t.x, c.cvBase_0 + 0.4f * t.w, t.y));
            }
            const std::vector<float> den = densities(c, pts);
            int solid = 0;
            for (float d : den) if (d > 0.0f) ++solid;
            std::printf("  turrets that are cloud on their own axis: %d of %d\n", solid, c.cvTurretCount_0);
            check(solid == c.cvTurretCount_0, "a turret is not there");
        }

        // (c) THE GROUP IS LOCAL: past every tower's moat and reach, the field is the field
        // it was, bit for bit.
        {
            ConvectionInput_0 plain = defaults(0.0f);
            plain.cvHeroAt_0     = make_float2(500.0f, -800.0f);
            plain.cvHeroRadius_0 = 1500.0f;
            plain.cvHeroTop_0    = 1500.0f;
            plain.cvHeroSeed_0   = make_float3(1731.0f, 613.0f, 2477.0f);
            plain.cvHeroBillow_0 = 1.67f;
            ConvectionInput_0 group = plain;
            addGroup(group, 1.0f, true);

            std::vector<float3> pts;
            while (pts.size() < 100000) {
                const float3 q = make_float3(rng.range(-12000.0f, 12000.0f),
                                             rng.range(plain.cvBase_0, plain.cvBase_0 + 2000.0f),
                                             rng.range(-12000.0f, 12000.0f));
                bool clear = true;
                for (int k = -1; k < group.cvTurretCount_0 && clear; ++k) {
                    const float4 t = k < 0 ? make_float4(plain.cvHeroAt_0.x, plain.cvHeroAt_0.y,
                                                         plain.cvHeroRadius_0, plain.cvHeroTop_0)
                                           : turretOf(group, k);
                    const float reach = std::max(1.3f * t.z, t.z + 1.5f * 350.0f * 1.67f + 24.0f) + 10.0f;
                    clear = std::hypot(q.x - t.x, q.z - t.y) > reach;
                }
                if (clear) pts.push_back(q);
            }
            const std::vector<float> a = densities(plain, pts);
            const std::vector<float> b = densities(group, pts);
            int differ = 0, cloudy = 0;
            for (size_t i = 0; i < a.size(); ++i) {
                if (a[i] != b[i]) ++differ;
                if (a[i] > 0.0f) ++cloudy;
            }
            std::printf("  away from the group: %d of %zu densities differ (%d cloud)\n",
                        differ, a.size(), cloudy);
            check(differ == 0, "the group changed the field away from it");
            check(cloudy > 1000, "too little field was sampled to mean anything");
        }
    }

    // -----------------------------------------------------------------------
    // 10. Mamma: pouches hang where there is cloud overhead, and nowhere else (build 23)
    // -----------------------------------------------------------------------
    std::printf("\n10. Mamma\n\n");
    {
        auto check = [&](bool ok, const char* what) {
            if (!ok) { std::printf("    FAIL: %s\n", what); ++failures; }
        };
        HostRng rng(2323);
        ConvectionInput_0 flat = defaults(1.0f);
        flat.cvCoverage_0 = 0.9f;
        flat.cvPouchSize_0 = 450.0f;
        ConvectionInput_0 sag = flat;
        sag.cvMammaDepth_0 = 360.0f;

        // (a) ABOVE THE BASE RAMP, THE CLOUD IS THE CLOUD IT WAS, bit for bit: the pouches
        // touch only the bottom forty metres and what hangs below.
        {
            std::vector<float3> pts(100000);
            for (float3& q : pts)
                q = make_float3(rng.range(-10000.0f, 10000.0f), flat.cvBase_0 + rng.range(40.0f, 1500.0f),
                                rng.range(-10000.0f, 10000.0f));
            const std::vector<float> a = densities(flat, pts);
            const std::vector<float> b = densities(sag, pts);
            int differ = 0, cloudy = 0;
            for (size_t i = 0; i < a.size(); ++i) {
                if (a[i] != b[i]) ++differ;
                if (a[i] > 0.0f) ++cloudy;
            }
            std::printf("  above the ramp: %d of %zu densities differ (%d cloud)\n", differ, a.size(), cloudy);
            check(differ == 0, "mamma changed the cloud above the base ramp");
            check(cloudy > 10000, "too little deck was sampled to mean anything");
        }

        // (b) NOTHING HANGS WHERE THERE IS NO CLOUD OVERHEAD: a column with no cloud in its
        // first sixty metres has no pouch under it. (c) AND THEY DO HANG, most of the way.
        {
            const int columns = 20000, up = 12, down = 24;
            std::vector<float3> pts;
            for (int k = 0; k < columns; ++k) {
                const float x = rng.range(-10000.0f, 10000.0f), z = rng.range(-10000.0f, 10000.0f);
                for (int j = 0; j < up; ++j)   pts.push_back(make_float3(x, flat.cvBase_0 + 1.0f + 5.0f * j, z));
                for (int j = 0; j < down; ++j) pts.push_back(make_float3(x, flat.cvBase_0 - 0.5f - 15.0f * j, z));
            }
            const std::vector<float> overhead = densities(flat, pts);
            const std::vector<float> hanging  = densities(sag, pts);
            int stray = 0, withPouch = 0;
            float deepest = 0.0f;
            for (int k = 0; k < columns; ++k) {
                const size_t at = static_cast<size_t>(k) * (up + down);
                bool cloud = false;
                for (int j = 0; j < up; ++j) cloud = cloud || overhead[at + j] > 0.0f;
                bool pouch = false;
                for (int j = 0; j < down; ++j) {
                    const float d = hanging[at + up + j];
                    if (d > 1e-6f * sag.cvSigma_0) {
                        pouch = true;
                        deepest = std::max(deepest, 0.5f + 15.0f * j);
                        if (!cloud) ++stray;
                    }
                }
                if (pouch) ++withPouch;
            }
            std::printf("  columns with a pouch: %d of %d, the deepest found %.0f m (at most %.0f); "
                        "under no cloud: %d\n", withPouch, columns, deepest, sag.cvMammaDepth_0, stray);
            check(stray == 0, "a pouch hangs where there is no cloud overhead");
            check(withPouch > columns / 10, "almost no pouches hang under a 90% deck");
            check(deepest > 0.5f * sag.cvMammaDepth_0, "no pouch hangs even half its depth");
            check(deepest <= sag.cvMammaDepth_0, "a pouch hangs past the deepest it may");
        }
    }

    // -----------------------------------------------------------------------
    // 11. Pileus and velum: where the cap and the veil stand (build 24)
    // -----------------------------------------------------------------------
    std::printf("\n11. Pileus and velum\n\n");
    {
        auto check = [&](bool ok, const char* what) {
            if (!ok) { std::printf("    FAIL: %s\n", what); ++failures; }
        };
        ConvectionInput_0 c = defaults(0.0f);
        c.cvHeroAt_0     = make_float2(500.0f, -800.0f);
        c.cvHeroRadius_0 = 1500.0f;
        c.cvHeroTop_0    = 1500.0f;
        c.cvHeroBillow_0 = 1.67f;
        c.cvHeroAlone_0  = 1;
        c.cvBillow_0     = 0.0f;     // smooth, so the gap between crown and cap is exact
        ConvectionInput_0 capped = c;
        capped.cvPileusThick_0 = 260.0f;
        capped.cvPileusGap_0   = 400.0f;
        capped.cvVelumThick_0  = 200.0f;
        capped.cvVelumHeight_0 = 900.0f;

        // On the hero's axis, up through crown, gap and cap; and out along the veil, whose
        // middle rises by its hump near the tower: half its thickness at the wall, nothing at
        // two radii, on a smoothstep.
        const float x = c.cvHeroAt_0.x, z = c.cvHeroAt_0.y, b = c.cvBase_0;
        const float R = c.cvHeroRadius_0;
        const float ht = (1.15f * R - R) / R;
        const float veilHump = 0.5f * capped.cvVelumThick_0 * (1.0f - ht * ht * (3.0f - 2.0f * ht));
        std::vector<float3> pts = {
            make_float3(x, b + 1500.0f - 30.0f, z),       // 0 the crown, just under its top
            make_float3(x, b + 1500.0f + 200.0f, z),      // 1 between crown and cap
            make_float3(x, b + 1500.0f + 400.0f, z),      // 2 the cap's middle
            make_float3(x, b + 1500.0f + 600.0f, z),      // 3 over the cap
            make_float3(x + 1.15f * R, b + 900.0f + veilHump, z),   // 4 the veil, off the tower
            make_float3(x + 1.15f * R, b + 1300.0f, z),             // 5 over the veil
            make_float3(x + 1.95f * R, b + 900.0f, z),              // 6 past its farthest edge
        };
        const std::vector<float> plain = densities(c, pts);
        const std::vector<float> with  = densities(capped, pts);
        std::printf("  crown %.4f/%.4f, gap %.4f, cap %.4f, over the cap %.4f\n",
                    plain[0], with[0], with[1], with[2], with[3]);
        std::printf("  veil %.4f, over it %.4f, past its edge %.4f\n", with[4], with[5], with[6]);
        check(with[0] == plain[0], "the cap changed the crown under it");
        check(with[1] == 0.0f, "there is cloud between the crown and the cap");
        check(with[2] > 0.0f && with[2] < c.cvSigma_0 * 0.5f, "the cap is missing, or as dense as the tower");
        check(with[3] == 0.0f, "there is cloud over the cap");
        check(with[4] > 0.0f && with[4] < c.cvSigma_0 * 0.5f, "the veil is missing, or as dense as the tower");
        check(with[5] == 0.0f && with[6] == 0.0f, "the veil reaches where it should not");
    }

    const cudaError_t err = cudaDeviceSynchronize();
    if (err != cudaSuccess) {
        std::printf("\nCUDA error: %s\n", cudaGetErrorString(err));
        ++failures;
    }

    std::printf("\n%s (%d failure%s)\n", failures ? "FAILED" : "PASSED", failures, failures == 1 ? "" : "s");
    return failures ? 1 : 0;
}
