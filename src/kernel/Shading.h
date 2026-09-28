#pragma once

// THE PIXEL MATHS, written ONCE and compiled for both the GPU and the CPU.
//
// Everything here is marked MT_DEVICE, which expands to `__host__ __device__`
// under nvcc and to `inline` everywhere else. That is the whole trick: one
// definition, two compilers, and a CPU reference that is provably the same
// arithmetic rather than a second implementation that drifts.
//
// ---------------------------------------------------------------------------
// WHAT IS IN HERE TODAY, STATED PLAINLY SO NOBODY MISTAKES IT FOR THE RENDERER.
//
// This is PHASE 1. It is a parameter-driven analytic sky: a Rayleigh-ish zenith
// gradient, a sun disc of the right angular size, and a horizon. It exists to
// prove the plumbing -- that a parameter typed in After Effects reaches a GPU
// kernel, comes back as float pixels, survives 8/16/32 bpc and reduced
// resolution, and matches between the host and the CLI.
//
// THERE IS NO TRANSPORT HERE YET. No null-collision tracking, no multiple
// scattering, no Jendersie-d'Eon phase function, no precomputed atmosphere, no
// ice generator. Those arrive in Phase 2, ported from proto/ once the Phase 0
// look verdict is in, and they arrive as Slang compiled to both PTX and Metal
// rather than as more of this header.
//
// The reason to write the placeholder against the REAL parameter structs is that
// the plumbing is the part Phase 1 is meant to prove, and plumbing proved with
// fake parameters is not proved.
// ---------------------------------------------------------------------------

#include "RenderRequest.h"

#if defined(__CUDACC__)
    #define MT_DEVICE __host__ __device__ inline
#else
    #define MT_DEVICE inline
    #include <cmath>
#endif

namespace plugin::kernel {

// Small vector type of our own rather than float3/float4.
//
// DELIBERATELY NOT CUDA'S. float3 exists only under nvcc, so using it would put a
// CUDA header on the CPU reference's include path and break the one rule that
// makes this file work.
struct Vec3 {
    float x = 0.0f, y = 0.0f, z = 0.0f;
};

MT_DEVICE Vec3 vec3(float x, float y, float z) { Vec3 v; v.x = x; v.y = y; v.z = z; return v; }

MT_DEVICE Vec3 operator+(Vec3 a, Vec3 b) { return vec3(a.x + b.x, a.y + b.y, a.z + b.z); }
MT_DEVICE Vec3 operator-(Vec3 a, Vec3 b) { return vec3(a.x - b.x, a.y - b.y, a.z - b.z); }
MT_DEVICE Vec3 operator*(Vec3 a, float s) { return vec3(a.x * s, a.y * s, a.z * s); }
MT_DEVICE Vec3 operator*(Vec3 a, Vec3 b) { return vec3(a.x * b.x, a.y * b.y, a.z * b.z); }

MT_DEVICE float dot(Vec3 a, Vec3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }

MT_DEVICE Vec3 normalize(Vec3 v) {
    const float len2 = dot(v, v);
    if (len2 <= 0.0f) return vec3(0.0f, 1.0f, 0.0f);
    // rsqrtf would be faster on the GPU and is NOT used: it is approximate, and
    // an approximate normalize gives the CPU reference and the kernel different
    // ray directions, which is a golden-image mismatch for no measurable gain at
    // one normalize per pixel.
    const float inv = 1.0f / sqrtf(len2);
    return v * inv;
}

MT_DEVICE float clampf(float v, float lo, float hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

MT_DEVICE float radians(float degrees) { return degrees * 0.01745329252f; }

// ---------------------------------------------------------------------------
// Camera
// ---------------------------------------------------------------------------

// A ray for one pixel, in world space.
//
// PIXEL CENTRES, hence the +0.5. Sampling at the integer corner shifts the whole
// image half a pixel, which is invisible on a still and shows up as a half-pixel
// crawl the moment anything moves.
//
// +Y IS UP IN WORLD SPACE AND DOWN IN THE IMAGE. AE's image origin is top-left
// with +Y downward, so the vertical screen coordinate is negated exactly once,
// here, rather than being fixed up at some later stage where it would be negated
// twice by two people who each thought they were first.
MT_DEVICE Vec3 primaryRayDirection(const cloud::ViewParams& view,
                                   int px, int py,
                                   float jitterX, float jitterY) {
    const float w = static_cast<float>(view.widthPx);
    const float h = static_cast<float>(view.heightPx);
    if (w <= 0.0f || h <= 0.0f) return vec3(0.0f, 1.0f, 0.0f);

    // Normalised device coordinates, -1..1, with the aspect ratio on X.
    //
    // THE BUFFER'S ORIGIN IS ADDED BEFORE DIVIDING BY THE FRAME. px and py index the
    // destination buffer, which may be a window into a larger frame -- so the pixel
    // has to be moved into frame coordinates first. Dividing the buffer coordinate by
    // the frame size instead renders the wrong part of the picture at the wrong
    // scale, and looks like a broken field of view rather than a missing offset.
    const float fx = static_cast<float>(px + view.originX) + 0.5f + jitterX;
    const float fy = static_cast<float>(py + view.originY) + 0.5f + jitterY;

    const float ndcX = (fx / w) * 2.0f - 1.0f;
    const float ndcY = (fy / h) * 2.0f - 1.0f;

    const float tanHalfFov = tanf(radians(view.verticalFovDegrees) * 0.5f);
    const float aspect     = w / h;

    // Camera-space ray: +X right, +Y up, looking down -Z.
    const Vec3 camDir = vec3(ndcX * tanHalfFov * aspect,
                             -ndcY * tanHalfFov,
                             -1.0f);

    // Rotate by the camera-to-world matrix's upper 3x3. ROW-MAJOR, and the
    // translation (elements 3, 7, 11) is deliberately not applied: this is a
    // direction, and adding the camera position to a direction is the kind of
    // mistake that looks like a broken FOV.
    const float* m = view.cameraToWorld;
    const Vec3 world = vec3(
        m[0] * camDir.x + m[1] * camDir.y + m[2]  * camDir.z,
        m[4] * camDir.x + m[5] * camDir.y + m[6]  * camDir.z,
        m[8] * camDir.x + m[9] * camDir.y + m[10] * camDir.z);

    return normalize(world);
}

// The sun's direction, from azimuth and elevation.
//
// AZIMUTH IS CLOCKWISE FROM +Z, which is the compass convention rather than the
// maths one, because the parameter is labelled in degrees and a user typing 90
// means east.
MT_DEVICE Vec3 sunDirection(const cloud::AtmosphereParams& atm) {
    const float az = radians(atm.sunAzimuth);
    const float el = radians(atm.sunElevation);
    const float cosEl = cosf(el);
    return normalize(vec3(sinf(az) * cosEl, sinf(el), cosf(az) * cosEl));
}

// ---------------------------------------------------------------------------
// The Phase 1 sky: single scattering, integrated
// ---------------------------------------------------------------------------
//
// WHAT THIS IS AND IS NOT.
//
// It is a genuine single-scattering atmosphere: a spherical planet with an
// exponential Rayleigh and Mie density, the in-scattered sunlight integrated along
// the view ray, and the transmittance to the sun integrated from each sample. That
// is the Nishita-style brute-force model the Bruneton precomputation of Phase 2
// replaces with lookup tables.
//
// IT DOES NOT INCLUDE MULTIPLE SCATTERING, and the consequence is visible rather
// than academic: a hazy or high-turbidity sky comes out darker than it should,
// because the light that would have bounced a second time is simply missing.
// Twilight is affected most. Phase 2's second LUT is what fixes it.
//
// ---------------------------------------------------------------------------
// WHY THIS IS HERE AT ALL, WHEN PHASE 1 ONLY ASKED FOR "A PARAMETER-DRIVEN COLOUR".
//
// The first attempt was cheaper: one slab, one air mass, one sun transmittance
// applied to the whole sky. It plumbed every parameter correctly and it rendered a
// GREEN sky -- because multiplying the in-scattered blue by the sun's own
// horizon-path transmittance attenuates blue twice and leaves green on top.
//
// That mattered more than it looks. Phase 1's exit criterion is that the render is
// CORRECT at three bit depths and two resolutions, and "correct" has to be
// checkable by eye; a picture that is visibly wrong for a known reason cannot be
// used to find one that is wrong for an unknown one. The integral is about thirty
// lines and gives a sky that can be compared against a photograph, so it earns
// its place.
// ---------------------------------------------------------------------------

// Scattering coefficients at sea level, per metre, for 680/550/440 nm.
//
// MEASURED VALUES, NOT A TINT. Rayleigh goes as 1/lambda^4, and these are the
// standard figures used by the Bruneton model -- so the blue of the sky here comes
// out of the numbers rather than out of a colour someone chose.
MT_DEVICE Vec3 rayleighCoefficients() { return vec3(5.802e-6f, 13.558e-6f, 33.1e-6f); }

// Mie scattering at sea level, per metre, at the reference turbidity.
//
// GREY, deliberately: aerosol particles are large compared with visible
// wavelengths, so they scatter all three channels nearly equally. That greyness is
// exactly why haze desaturates a sky instead of tinting it.
MT_DEVICE float mieCoefficient(float turbidity) {
    const float reference = 2.2f;   // the AtmosphereParams default
    return 3.996e-6f * (turbidity / reference);
}

// Density scale heights. RAYLEIGH FROM THE PARAMETER, MIE FIXED.
//
// The air's own scale height is a physical constant of the planet and is exposed on
// the Physics tab. The aerosol's is not the same number and never was -- dust and
// water droplets settle out far lower, around 1200 m on Earth, which is why haze
// sits in a band near the ground instead of filling the sky.
constexpr float kMieScaleHeight = 1200.0f;

// How thick the atmosphere is taken to be, as a multiple of the scale height.
//
// EIGHT e-FOLDINGS leaves about 0.03% of the air above the boundary, which is below
// the noise floor of a single-scattering model. Going higher costs march steps in
// vacuum.
constexpr float kAtmosphereEFoldings = 8.0f;

// ---------------------------------------------------------------------------
// RAY-SPHERE, WRITTEN FOR A PLANET-SIZED SPHERE AND A VIEWER STANDING ON IT.
//
// THIS IS THE ONE PIECE OF ARITHMETIC IN THE FILE THAT CANNOT BE WRITTEN THE
// TEXTBOOK WAY, and the reason is worth the space because the failure is baffling
// otherwise.
//
// The textbook form computes c = dot(o, o) - radius*radius. With an observer two
// metres above a 6 371 km planet those are 4.0589...e13 and 4.0589...e13: the true
// difference is about 2.5e7, and a float carries only 24 bits of mantissa, so each
// term is already uncertain by around 2.4e6. The difference therefore arrives with
// roughly TEN PERCENT ERROR.
//
// Away from the horizon nobody notices, because the discriminant b*b - c is
// dominated by b*b. AT the horizon b*b and c are equal by definition -- that is
// what the horizon IS -- so what is left is entirely error, and whether a grazing
// ray hits the planet or misses it stops being decided by geometry.
//
// TO BE CLEAR ABOUT WHAT THIS DOES AND DOES NOT FIX: the visible speckle along the
// horizon in a low-sample render is ordinary Monte Carlo noise on a one-pixel
// geometric edge, and it converges away with samples. This is a separate, quieter
// defect -- it decides the edge's POSITION wrongly by a fraction of a pixel, which
// no amount of sampling corrects because every sample agrees on the wrong answer.
//
// THE FIX IS ALGEBRAIC, NOT A LARGER TYPE. c is |o|^2 - r^2, which factors into
// (|o| - r)(|o| + r) -- and |o| - r is the ALTITUDE, a number we know exactly
// because we put the observer there. So c is computed from the altitude and never
// by subtracting two enormous squares. Doubles would also work and would cost 32x
// on consumer NVIDIA hardware for a quantity that has a closed form.
// ---------------------------------------------------------------------------

// c = |o|^2 - r^2 for a point at altitude `altitude` above a sphere of radius
// `planetRadius`, measured against a sphere of radius planetRadius + shellHeight.
//
// Both terms stay in the millions rather than the tens of trillions, so every bit
// of the result is significant.
MT_DEVICE float shellC(float altitude, float planetRadius, float shellHeight) {
    const float d = altitude - shellHeight;
    return d * (d + 2.0f * planetRadius + 2.0f * shellHeight);
}

// Where the ray LEAVES the shell, from b = dot(o, dir) and the c above. Negative
// when the shell is not reached.
MT_DEVICE float shellExit(float b, float c) {
    const float disc = b * b - c;
    if (disc < 0.0f) return -1.0f;
    return -b + sqrtf(disc);
}

// Where the ray ENTERS the shell. Negative when it misses or points away.
MT_DEVICE float shellEnter(float b, float c) {
    const float disc = b * b - c;
    if (disc < 0.0f) return -1.0f;
    return -b - sqrtf(disc);
}

// Altitude at a point on the ray, from q = |p|^2 - R^2.
//
// SAME TRICK IN REVERSE. q is carried along the ray as c + 2tb + t^2, all of which
// are moderate numbers, so q stays accurate; dividing by (|p| + R) then gives the
// altitude without ever subtracting R from |p|.
//
// For a low sample R*R + q rounds to R*R in float and this degrades to q / 2R --
// which is the correct first-order answer, so the degradation is graceful rather
// than a cliff.
MT_DEVICE float altitudeFromQ(float q, float planetRadius) {
    const float R = planetRadius;
    const float rr = R * R + q;
    return q / (R + sqrtf(rr > 0.0f ? rr : 0.0f));
}

// Optical depth from `p` towards the sun, out to the top of the atmosphere.
//
// EIGHT STEPS, and the cost of that choice is worth stating: this runs inside the
// view march, so the two loops multiply. Eight is enough that the terminator does
// not band at the exposures a sky is viewed at, and Phase 2 replaces the whole
// thing with a texture fetch -- which is precisely why Bruneton precomputes it.
//
// TAKES THE SAMPLE'S ALTITUDE AND THE DOT PRODUCT RATHER THAN THE POINT, so that
// the caller -- which already knows both accurately -- does not force this function
// to recover them by subtracting planet-sized numbers. See the ray-sphere note.
MT_DEVICE void sunOpticalDepth(float altitude, float bSun,
                               float planetRadius, float atmosphereHeight,
                               float rayleighScaleHeight,
                               float& outRayleigh, float& outMie) {
    outRayleigh = 0.0f;
    outMie = 0.0f;

    const float cGround = shellC(altitude, planetRadius, 0.0f);
    const float cTop    = shellC(altitude, planetRadius, atmosphereHeight);

    const float tTop = shellExit(bSun, cTop);
    if (tTop <= 0.0f) return;

    // THE SHADOW TEST, and it is what makes night happen. A sample with the planet
    // between it and the sun receives nothing; returning a huge optical depth says
    // so without a separate branch downstream. Leave it out and the ground glows
    // from beneath at sunset.
    const float tGround = shellEnter(bSun, cGround);
    if (tGround > 0.0f) {
        outRayleigh = 1e9f;
        outMie = 1e9f;
        return;
    }

    // EIGHT STEPS, quadratically spaced for the same reason as the view march: a
    // sun ray at sunset grazes the atmosphere for hundreds of kilometres and nearly
    // all of the air it passes through is in the first few.
    //
    // This runs INSIDE the view march, so the two loops multiply -- which is exactly
    // why Bruneton precomputes this into a table, and exactly what Phase 2 replaces
    // it with.
    const int steps = 8;
    const float invSteps2 = 1.0f / static_cast<float>(steps * steps);
    float sPrev = 0.0f;

    for (int i = 0; i < steps; ++i) {
        const float sNext = tTop * static_cast<float>((i + 1) * (i + 1)) * invSteps2;
        const float ds    = sNext - sPrev;
        const float sMid  = (sPrev + sNext) * 0.5f;
        sPrev = sNext;
        if (ds <= 0.0f) continue;

        const float q = cGround + 2.0f * sMid * bSun + sMid * sMid;
        const float h = altitudeFromQ(q, planetRadius);
        const float hc = h < 0.0f ? 0.0f : h;

        outRayleigh += expf(-hc / rayleighScaleHeight) * ds;
        outMie      += expf(-hc / kMieScaleHeight) * ds;
    }
}

// Radiance along one ray, in the same linear units throughout.
MT_DEVICE Vec3 skyRadiance(const cloud::FieldParams& field, Vec3 rayDir) {
    const cloud::AtmosphereParams& atm = field.atmosphere;
    const Vec3 sun = sunDirection(atm);

    const float planetRadius = field.physics.planetRadius > 1000.0f
                             ? field.physics.planetRadius : 1000.0f;
    const float scaleHeight  = field.physics.scaleHeight > 1.0f
                             ? field.physics.scaleHeight : 1.0f;
    const float atmosphereHeight = scaleHeight * kAtmosphereEFoldings;

    // THE OBSERVER SITS ON THE PLANET, not at the origin. A flat-earth model cannot
    // produce a horizon at all, and the horizon is where most of the interesting
    // light is.
    //
    // THE ALTITUDE IS CARRIED AS A NUMBER, not recovered from the position. Every
    // intersection below is computed from it, which is what keeps the horizon clean
    // -- see the ray-sphere note above.
    const float observerAltitude = 2.0f;

    // b = dot(origin, dir), and the origin is on the +Y axis, so this is one
    // multiply rather than a dot product over coordinates in the millions.
    const float b = (planetRadius + observerAltitude) * rayDir.y;

    const float cGround = shellC(observerAltitude, planetRadius, 0.0f);
    const float cTop    = shellC(observerAltitude, planetRadius, atmosphereHeight);

    const float tTop = shellExit(b, cTop);
    if (tTop <= 0.0f) return vec3(0.0f, 0.0f, 0.0f);

    // Stop at the ground if the ray reaches it, so a downward ray integrates the
    // air in front of the ground rather than through the planet.
    const float tGround = shellEnter(b, cGround);
    const bool  hitsGround = tGround > 0.0f;
    const float tMax = hitsGround ? tGround : tTop;

    const Vec3  betaR = rayleighCoefficients();
    const float betaM = mieCoefficient(atm.turbidity);
    // Aerosol ABSORBS as well as scatters. The usual figure is about a ninth of the
    // scattering coefficient again; leaving it out makes haze glow.
    const float betaMExt = betaM * 1.11f;

    const float cosTheta = clampf(dot(rayDir, sun), -1.0f, 1.0f);

    // Rayleigh phase: (3/16pi)(1 + cos^2). Exact for molecular scattering.
    const float phaseR = 0.0596831f * (1.0f + cosTheta * cosTheta);

    // Henyey-Greenstein for the aerosol, at the parameterised anisotropy.
    //
    // NOTE THAT THIS IS THE AEROSOL PHASE FUNCTION AND NOT THE CLOUD ONE. HG is
    // adequate for dust and haze and is badly wrong for water droplets, which is why
    // Phase 2 brings in the Jendersie-d'Eon (2023) Draine-based Mie approximation
    // for the liquid -- the one that produces a fogbow and a glory. Using HG for
    // cloud is the single biggest reason procedural clouds look like smoke.
    const float g = clampf(atm.mieAnisotropy, -0.95f, 0.95f);
    const float hgDenom = 1.0f + g * g - 2.0f * g * cosTheta;
    const float phaseM = (1.0f - g * g) /
                         (12.566370614f * hgDenom * sqrtf(hgDenom > 1e-6f ? hgDenom : 1e-6f));

    // ---------------------------------------------------------------------
    // TWENTY-FOUR STEPS, DISTRIBUTED QUADRATICALLY RATHER THAN EVENLY.
    //
    // Even steps are the wrong distribution for an exponential atmosphere. A ray a
    // degree above the horizon travels several hundred kilometres before it leaves
    // the atmosphere, while a ray at the zenith travels sixty -- so an even split
    // gives the grazing ray some 20 km between samples through the exact region
    // where the density is highest and changing fastest. What that costs is
    // accuracy in the horizon band, where the integral is largest and matters most.
    //
    // t ~ i^2 puts the samples where the air is. The first step is short and near
    // the observer, where an exponential atmosphere keeps nearly all of its mass;
    // the last is long and high up, where there is almost nothing left to integrate.
    //
    // Phase 2 removes the question entirely: Bruneton precomputes transmittance into
    // a table and the march stops being an integral over the whole atmosphere. The
    // step count here is a stopgap, not a tuning result.
    // ---------------------------------------------------------------------
    const int steps = 24;
    const float invSteps2 = 1.0f / static_cast<float>(steps * steps);

    Vec3  sumR = vec3(0.0f, 0.0f, 0.0f);
    Vec3  sumM = vec3(0.0f, 0.0f, 0.0f);
    float depthR = 0.0f;
    float depthM = 0.0f;

    float tPrev = 0.0f;

    for (int i = 0; i < steps; ++i) {
        // The segment runs between two quadratically spaced boundaries, and the
        // sample sits at its midpoint. Taking the sample at the boundary instead
        // would bias every segment towards the denser end of itself.
        const float tNext = tMax * static_cast<float>((i + 1) * (i + 1)) * invSteps2;
        const float dt    = tNext - tPrev;
        const float tMid  = (tPrev + tNext) * 0.5f;
        tPrev = tNext;

        if (dt <= 0.0f) continue;

        // q = |p|^2 - R^2, carried along the ray rather than recomputed from the
        // position. All three terms are moderate, so the altitude stays accurate
        // right down to the horizon.
        const float q = cGround + 2.0f * tMid * b + tMid * tMid;
        const float h = altitudeFromQ(q, planetRadius);
        const float hc = h < 0.0f ? 0.0f : h;

        // The sample's position, needed only for its direction to the sun. The
        // planet is centred at the origin, so the point is the observer plus the
        // ray -- and its dot with the sun direction is what sunOpticalDepth wants.
        const Vec3 p = vec3(rayDir.x * tMid,
                            planetRadius + observerAltitude + rayDir.y * tMid,
                            rayDir.z * tMid);
        const float bSun = dot(p, sun);

        const float dR = expf(-hc / scaleHeight) * dt;
        const float dM = expf(-hc / kMieScaleHeight) * dt;

        // ACCUMULATED BEFORE THE SAMPLE IS USED, so the transmittance includes this
        // step's own half. Adding it afterwards biases the whole integral towards
        // the viewer and brightens the horizon by a visible amount.
        depthR += dR;
        depthM += dM;

        float sunR = 0.0f, sunM = 0.0f;
        sunOpticalDepth(hc, bSun, planetRadius, atmosphereHeight, scaleHeight, sunR, sunM);

        // Transmittance from the sun to p, and from p back to the viewer.
        const float tauX = betaR.x * (depthR + sunR) + betaMExt * (depthM + sunM);
        const float tauY = betaR.y * (depthR + sunR) + betaMExt * (depthM + sunM);
        const float tauZ = betaR.z * (depthR + sunR) + betaMExt * (depthM + sunM);

        const Vec3 transmittance = vec3(expf(-tauX), expf(-tauY), expf(-tauZ));

        sumR = sumR + transmittance * dR;
        sumM = sumM + transmittance * dM;
    }

    // THE SOLAR CONSTANT, as a radiance scale. 20 is the figure that puts a clear
    // midday zenith near 1.0 with these coefficients, which is what makes 0 EV a
    // sensible default rather than a number the user must always fix.
    const float irradiance = 20.0f * atm.sunIntensity;

    Vec3 radiance = (sumR * betaR * phaseR + sumM * (betaM * phaseM)) * irradiance;

    // ---------------------------------------------------------------------
    // The ground
    // ---------------------------------------------------------------------
    if (hitsGround) {
        // Lambertian, lit by the sun through the air above it. The sky's own
        // contribution to ground lighting is a multiple-scattering term and is
        // therefore missing here along with the rest of them -- so the ground reads
        // slightly too dark in shadow, consistently with everything else.
        const Vec3 groundPoint = vec3(rayDir.x * tGround,
                                      planetRadius + observerAltitude + rayDir.y * tGround,
                                      rayDir.z * tGround);
        const Vec3 groundNormal = normalize(groundPoint);
        const float nDotL = clampf(dot(groundNormal, sun), 0.0f, 1.0f);

        float sunR = 0.0f, sunM = 0.0f;
        sunOpticalDepth(0.0f, dot(groundPoint, sun), planetRadius, atmosphereHeight,
                        scaleHeight, sunR, sunM);

        const Vec3 sunT = vec3(expf(-(betaR.x * sunR + betaMExt * sunM)),
                               expf(-(betaR.y * sunR + betaMExt * sunM)),
                               expf(-(betaR.z * sunR + betaMExt * sunM)));

        // Transmittance from the viewer to the ground, which is what gives distant
        // ground its aerial perspective.
        const Vec3 viewT = vec3(expf(-(betaR.x * depthR + betaMExt * depthM)),
                                expf(-(betaR.y * depthR + betaMExt * depthM)),
                                expf(-(betaR.z * depthR + betaMExt * depthM)));

        const float lambert = atm.groundAlbedo * nDotL * 0.3183098862f;  // 1/pi
        radiance = radiance + viewT * sunT * (lambert * irradiance);
    }

    // ---------------------------------------------------------------------
    // The sun disc
    // ---------------------------------------------------------------------
    //
    // ONLY WHEN THE RAY LEAVES THE ATMOSPHERE, so the planet occludes it rather than
    // the sun shining through the ground.
    //
    // ITS ANGULAR RADIUS IS A PARAMETER AND NOT A CONSTANT, because it is what makes
    // a shadow edge soft -- and the softness of a cloud's shadow edge is much of how
    // large the cloud reads as being. 0.266 degrees is the Sun from Earth.
    if (!hitsGround) {
        const float cosRadius = cosf(radians(atm.sunAngularRadius));
        if (cosTheta > cosRadius) {
            const Vec3 viewT = vec3(expf(-(betaR.x * depthR + betaMExt * depthM)),
                                    expf(-(betaR.y * depthR + betaMExt * depthM)),
                                    expf(-(betaR.z * depthR + betaMExt * depthM)));

            // The disc's RADIANCE is its irradiance over its solid angle, so a bigger
            // sun is not a brighter one -- it is the same light over more sky. Getting
            // that backwards is why hand-tuned suns blow out when resized.
            const float radiusRad = radians(atm.sunAngularRadius);
            const float solidAngle = 6.283185307f * (1.0f - cosRadius);
            const float safeSolid = solidAngle > 1e-9f ? solidAngle : 1e-9f;
            (void)radiusRad;

            // Limb darkening left out on purpose: at 0.266 degrees the whole disc is
            // about a pixel at any sane comp size, and inventing detail with no
            // observer is how a renderer gets slow for nothing.
            radiance = radiance + viewT * (irradiance / safeSolid);
        }
    }

    return radiance;
}

// ---------------------------------------------------------------------------
// Output transform
// ---------------------------------------------------------------------------

// AgX, approximated. OFF BY DEFAULT and it must stay that way: the render is
// linear float, and an effect that tonemapped unasked would be fighting whatever
// the user's own grade is doing downstream.
//
// The polynomial is the widely used fit of the full AgX transform. It is not the
// real thing and is labelled as such; the real one needs a 3D LUT, which is Phase
// 4 work alongside the separate output passes.
MT_DEVICE float agxChannel(float x) {
    x = clampf(x, 0.0f, 1.0f);
    const float x2 = x * x;
    const float x3 = x2 * x;
    const float x4 = x2 * x2;
    return 15.5f * x4 * x2
         - 40.14f * x4 * x
         + 31.96f * x4
         - 6.868f * x3
         + 0.4298f * x2
         + 0.1191f * x
         - 0.00232f;
}

MT_DEVICE Vec3 applyOutputTransform(Vec3 radiance, const cloud::ViewParams& view) {
    // REAL EV, applied as a power of two, because that is what the unit means.
    const float gain = exp2f(view.exposureEV);
    Vec3 c = radiance * gain;

    if (!view.agxTonemap) {
        // LINEAR FLOAT, UNCLAMPED, and that is the default on purpose. Values
        // above 1.0 are the sun, and clamping them here would throw away the
        // headroom the 32 bpc path exists to carry.
        return c;
    }

    // AgX works in log2 over a fixed dynamic range before the curve.
    const float minEv = -12.47393f;
    const float maxEv = 4.026069f;
    const float span  = maxEv - minEv;

    float ch[3] = { c.x, c.y, c.z };
    for (int i = 0; i < 3; ++i) {
        const float v = ch[i] > 1e-10f ? ch[i] : 1e-10f;
        const float logv = clampf((log2f(v) - minEv) / span, 0.0f, 1.0f);
        ch[i] = agxChannel(logv);
    }
    return vec3(ch[0], ch[1], ch[2]);
}

// ---------------------------------------------------------------------------
// Sampling
// ---------------------------------------------------------------------------

// A HASH, NOT A COUNTER, and this is the determinism rule in one function.
//
// The seed for a sample comes from (pixel, sample index, field seed) and nothing
// else. Never a clock, never a thread id, never a counter shared between launches
// -- because motion blur renders one frame several times and MFR renders frames on
// different workers, so anything stateful gives a different image on the second
// pass and tests/golden/ catches it as non-determinism.
//
// PCG's output permutation, which passes the statistical tests that a plain
// multiply-xorshift does not. Cheap enough to call per sample.
MT_DEVICE unsigned int hashPixelSample(int px, int py, int sampleIndex, unsigned int seed) {
    unsigned int h = seed;
    h ^= static_cast<unsigned int>(px) * 0x9e3779b9u;
    h ^= static_cast<unsigned int>(py) * 0x85ebca6bu;
    h ^= static_cast<unsigned int>(sampleIndex) * 0xc2b2ae35u;
    h ^= h >> 16;
    h *= 0x7feb352du;
    h ^= h >> 15;
    h *= 0x846ca68bu;
    h ^= h >> 16;
    return h;
}

MT_DEVICE float unitFloat(unsigned int h) {
    // 24 bits into [0,1), which is exactly what a float mantissa holds. Using all
    // 32 would round to 1.0 for the top values, and a sample at exactly 1.0 is off
    // the end of every table it indexes.
    return static_cast<float>(h >> 8) * (1.0f / 16777216.0f);
}

// ---------------------------------------------------------------------------
// One pixel, start to finish
// ---------------------------------------------------------------------------

// The whole per-pixel job, shared verbatim between the CUDA kernel and the CPU
// reference. Neither has a copy of any of this.
//
// WRITES LINEAR RADIANCE INTO THE ACCUMULATOR AND THE TRANSFORMED RESULT INTO THE
// DESTINATION. Two buffers because the denoiser needs the linear one and the host
// needs the display one, and because the accumulator has to survive between
// launches while the destination is handed back to AE every time.
MT_DEVICE void renderPixel(const RenderRequest& req, int px, int py) {
    if (px < 0 || py < 0 || px >= req.dest.widthPx || py >= req.dest.heightPx) return;

    Vec3 sum = vec3(0.0f, 0.0f, 0.0f);

    // THE SEED IS KEYED TO THE FRAME PIXEL, NOT THE BUFFER PIXEL, and the difference
    // is the whole determinism claim rather than a detail.
    //
    // px,py index the destination, which is routinely a WINDOW into the frame: a CUDA
    // band, or a Region of Interest. Seeding from those gave the same frame pixel a
    // different jitter depending on how the frame happened to be divided -- so a ROI
    // render disagreed with the full render underneath it, and a banded render
    // disagreed with a whole-frame one.
    //
    // MEASURED before the fix: a 120x70 window of a 256x144 frame differed from the
    // same patch of the whole frame by max 190 of 255, concentrated at the sun disc.
    // The mean was 0.51, which is exactly why tests/golden/ compares maxima.
    //
    // determinism.gpuBands DID NOT CATCH IT. That test renders a smooth 96x54 sky at
    // sun elevation 20, where a different jitter moves no pixel by a whole level, so
    // it compared byte-identical while the property it names was broken. A test can
    // only catch what its scene can show.
    const int frameX = px + req.view.originX;
    const int frameY = py + req.view.originY;

    for (int s = 0; s < req.sampleCount; ++s) {
        const int sampleIndex = req.firstSample + s;
        const unsigned int h = hashPixelSample(frameX, frameY, sampleIndex, req.field.seed);

        // Two decorrelated dimensions from one hash. Blue-noise offsets stable
        // across frames are a Phase 2 upgrade -- they are the first mitigation to
        // reach for against denoiser flicker, and they need a texture this
        // placeholder has no way to carry.
        const float jx = unitFloat(h) - 0.5f;
        const float jy = unitFloat(h * 0x9e3779b9u + 0x632be59bu) - 0.5f;

        const Vec3 dir = primaryRayDirection(req.view, px, py, jx, jy);
        sum = sum + skyRadiance(req.field, dir);
    }

    // PROGRESSIVE ACCUMULATION, weighted by the counts rather than by a running
    // lerp factor. A lerp with 1/n loses precision as n grows; a running sum
    // divided once does not, and the sum is what the denoiser wants anyway.
    Vec3 mean;
    if (req.accumulator != nullptr) {
        const int idx = py * req.accumulatorPitchPx * 4 + px * 4;
        float* acc = req.accumulator + idx;

        if (req.samplesAlreadyDone <= 0) {
            acc[0] = sum.x; acc[1] = sum.y; acc[2] = sum.z; acc[3] = 0.0f;
        } else {
            acc[0] += sum.x; acc[1] += sum.y; acc[2] += sum.z;
        }

        const int total = req.samplesAlreadyDone + req.sampleCount;
        const float inv = total > 0 ? 1.0f / static_cast<float>(total) : 0.0f;
        mean = vec3(acc[0] * inv, acc[1] * inv, acc[2] * inv);
    } else {
        const float inv = req.sampleCount > 0 ? 1.0f / static_cast<float>(req.sampleCount) : 0.0f;
        mean = sum * inv;
    }

    const Vec3 out = applyOutputTransform(mean, req.view);

    float* row = static_cast<float*>(req.dest.data) + py * req.dest.pitchPx * 4;
    float* pix = row + px * 4;

    // THE CHANNEL ORDER, ASKED AND NOT ASSUMED. See ChannelOrder in
    // RenderRequest.h for why this is a parameter.
    //
    // ALPHA IS 1 AND THE COLOUR IS NOT PREMULTIPLIED BY ANYTHING, because a sky is
    // opaque. AE's buffers are premultiplied, and at alpha 1 premultiplied and
    // straight are the same numbers -- so this is correct rather than merely
    // convenient. A generator with genuine transparency would have to multiply.
    if (req.dest.order == ChannelOrder::BGRA) {
        pix[0] = out.z; pix[1] = out.y; pix[2] = out.x; pix[3] = 1.0f;
    } else {
        pix[0] = 1.0f; pix[1] = out.x; pix[2] = out.y; pix[3] = out.z;
    }
}

} // namespace plugin::kernel
