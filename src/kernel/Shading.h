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

    // DEVICE ONLY, AND THE DISTINCTION IS FORCED BY slangc RATHER THAN CHOSEN.
    //
    // The generated CUDA marks every function `static __device__` -- there is no
    // host arm of it at all -- so anything that calls into the kernel cannot itself
    // be `__host__ __device__`. nvcc rejects that outright rather than letting the
    // host arm dangle, which is the correct failure and is how this was found.
    //
    // Only the two functions that reach the transport carry it. Everything else in
    // this header stays callable from the host, because tests/slang/SkyParityMain.cu
    // and tests/unit/TestCamera.cpp call the camera and the sky directly and that is
    // how those suites work without a GPU.
    //
    // NOTHING CALLS renderPixel FROM THE HOST IN A .cu. Mistytune.cu reaches it only
    // through mistytuneKernel, which is `__global__`; the CPU reference is compiled
    // by the host compiler, where this expands to plain `inline` and the whole
    // question does not arise.
    #define MT_RENDER __device__ inline
#else
    #define MT_DEVICE inline
    #define MT_RENDER inline
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
//
// `stride` IS DRAFT'S PIXEL STRIDE (build 26): buffer pixel (px, py) is then the stride x
// stride block of the frame starting at origin + stride * (px, py), and the jitter spans the
// block. ONE TAKES THE ORIGINAL EXPRESSION, rounding included, so every render that does not
// ask for a stride is bit-for-bit what it was. See QualityParams::pixelStride.
MT_DEVICE Vec3 primaryRayDirection(const cloud::ViewParams& view,
                                   int px, int py,
                                   float jitterX, float jitterY, int stride = 1) {
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
    const float sf = static_cast<float>(stride);
    const float fx = stride > 1
        ? static_cast<float>(view.originX) + (static_cast<float>(px) + 0.5f + jitterX) * sf
        : static_cast<float>(px + view.originX) + 0.5f + jitterX;
    const float fy = stride > 1
        ? static_cast<float>(view.originY) + (static_cast<float>(py) + 0.5f + jitterY) * sf
        : static_cast<float>(py + view.originY) + 0.5f + jitterY;

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
// ===========================================================================
// NO LONGER ON THE RENDER PATH, AND KEPT ON PURPOSE AS THE REFERENCE THE TABLE IS
// CHECKED AGAINST.
//
// The sky march below reads src/engine/Atmosphere.cpp's precomputed table instead.
// This is the integral that table is a precomputation OF, so the two are a genuine
// cross-check -- LutAgreesWithTheMarchItReplaces in tests/unit/ compares them, and
// that comparison is only meaningful while this remains an independent second
// derivation rather than a call into the same code.
//
// The eight-step quadrature and its quadratic spacing are unchanged, so the
// comparison is also a statement about how much the table's 64 uniform steps in
// double improved on it.
// ===========================================================================
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

// ---------------------------------------------------------------------------
// The transmittance table, read
// ---------------------------------------------------------------------------

// A LINE-FOR-LINE MIRROR of sampleTransmittanceLut() in src/kernel/slang/SkyLib.slang,
// which is the production copy, and of sampleTransmittance() in
// src/engine/Atmosphere.cpp, which is the host reference the table's tests use.
//
// THREE COPIES IS TWO MORE THAN ANYONE WANTS, and each one is pinned: slang.skyParity
// compares this against the generated Slang bitwise, and LutAgreesWithTheHostSampler
// compares it against the engine's. The alternative -- one definition -- is not
// available, because one has to compile for CUDA, one has to be reachable from
// src/engine/ which holds no kernel headers, and one is written in another language.
//
// THE SHAPE COMES FROM THE ENGINE rather than being redeclared, so at least the
// strides cannot drift.
MT_DEVICE Vec3 sampleTransmittanceLut(const float* lut, float scaleHeight,
                                      float altitude, float mu) {
    // AN ABSENT TABLE RETURNS ONE -- unattenuated -- rather than zero. See
    // SkyLib.slang: an over-bright sky still shows the geometry, while a black one
    // reads as a dead renderer and sends the reader to the transport.
    if (lut == nullptr) return vec3(1.0f, 1.0f, 1.0f);

    const float sh  = scaleHeight > 1.0f ? scaleHeight : 1.0f;
    const float top = sh * kAtmosphereEFoldings;

    const float h = clampf(altitude, 0.0f, top);
    const float v = sqrtf(h / top);

    const float m = clampf(mu, -1.0f, 1.0f);
    const float u = (m + 1.0f) * 0.5f;

    float fx = u * static_cast<float>(cloud::kTransmittanceMuSize) - 0.5f;
    float fy = v * static_cast<float>(cloud::kTransmittanceAltitudeSize) - 0.5f;
    if (fx < 0.0f) fx = 0.0f;
    if (fy < 0.0f) fy = 0.0f;

    int x0 = static_cast<int>(fx);
    int y0 = static_cast<int>(fy);
    if (x0 > cloud::kTransmittanceMuSize - 1)       x0 = cloud::kTransmittanceMuSize - 1;
    if (y0 > cloud::kTransmittanceAltitudeSize - 1) y0 = cloud::kTransmittanceAltitudeSize - 1;

    int x1 = x0 + 1;
    int y1 = y0 + 1;
    if (x1 > cloud::kTransmittanceMuSize - 1)       x1 = cloud::kTransmittanceMuSize - 1;
    if (y1 > cloud::kTransmittanceAltitudeSize - 1) y1 = cloud::kTransmittanceAltitudeSize - 1;

    const float tx = fx - static_cast<float>(x0);
    const float ty = fy - static_cast<float>(y0);

    const int i00 = (y0 * cloud::kTransmittanceMuSize + x0) * cloud::kTransmittanceChannels;
    const int i10 = (y0 * cloud::kTransmittanceMuSize + x1) * cloud::kTransmittanceChannels;
    const int i01 = (y1 * cloud::kTransmittanceMuSize + x0) * cloud::kTransmittanceChannels;
    const int i11 = (y1 * cloud::kTransmittanceMuSize + x1) * cloud::kTransmittanceChannels;

    float out[3] = { 0.0f, 0.0f, 0.0f };
    for (int c = 0; c < cloud::kTransmittanceChannels; ++c) {
        const float a = lut[i00 + c] * (1.0f - tx) + lut[i10 + c] * tx;
        const float b = lut[i01 + c] * (1.0f - tx) + lut[i11 + c] * tx;
        out[c] = a * (1.0f - ty) + b * ty;
    }
    return vec3(out[0], out[1], out[2]);
}

// The lookup's mu: the cosine of the sun's zenith angle at a geocentric point.
//
// LOCAL UP IS THE NORMALISED GEOCENTRIC POSITION, not world +Y. The two agree at the
// observer and diverge towards the horizon, which is exactly where getting this wrong
// renders a plausible sky overhead and a wrong one where it matters.
MT_DEVICE float lutMuFor(Vec3 geocentric, Vec3 sun) {
    const float len = sqrtf(dot(geocentric, geocentric));
    return len > 1.0f ? dot(geocentric, sun) / len : dot(geocentric, sun);
}

// Radiance along one ray, in the same linear units throughout.
//
// TAKES THE TABLE, because the sun-transmittance inner march is now a lookup. A null
// table is legal and means "no atmospheric extinction towards the sun".
//
// ===========================================================================
// TAKES THE ORIGIN'S ALTITUDE, AND IT USED TO BE THE CONSTANT 2.0.
//
// That was correct for exactly as long as this function had one caller: a camera ray
// from an observer standing on the ground. The bounce loop then started calling it
// for ESCAPED PATHS -- a path that scattered inside a cirrus at 9 km and left the
// medium asks the sky what is in its direction -- and a constant answered every one
// of them with the sky as seen from two metres.
//
// THE ERROR IS NOT SMALL AND IT IS NOT NOISE. It integrates nine kilometres of air
// that is not between the crystal and space, so the skylight illuminating the cloud
// came back too bright and too blue, systematically, at every bounce. proto/index.html
// -- the reference that passed the Phase 0 look verdict -- passes `ro` and always
// did; this is the transcription catching up with it.
//
// ONLY THE ALTITUDE, NOT THE POSITION, and that is sound rather than a shortcut: the
// atmosphere is spherically symmetric, so the march depends on where the origin is
// only through its height and the ray's angle to the local vertical. The existing
// local-frame assumption -- the origin sits on the +Y axis -- is what makes `b` one
// multiply instead of a dot product, and it is unchanged.
// ===========================================================================
MT_DEVICE Vec3 skyRadiance(const cloud::FieldParams& field, float originAltitude,
                           Vec3 rayDir, const float* transmittanceLut) {
    const cloud::AtmosphereParams& atm = field.atmosphere;
    const Vec3 sun = sunDirection(atm);

    const float planetRadius = field.physics.planetRadius > 1000.0f
                             ? field.physics.planetRadius : 1000.0f;
    const float scaleHeight  = field.physics.scaleHeight > 1.0f
                             ? field.physics.scaleHeight : 1.0f;
    const float atmosphereHeight = scaleHeight * kAtmosphereEFoldings;

    // THE ORIGIN SITS ON THE PLANET, not at the centre. A flat-earth model cannot
    // produce a horizon at all, and the horizon is where most of the interesting
    // light is.
    //
    // THE ALTITUDE IS CARRIED AS A NUMBER, not recovered from the position. Every
    // intersection below is computed from it, which is what keeps the horizon clean
    // -- see the ray-sphere note above.
    //
    // FLOORED AT THE GROUND. An escaped path's origin is a point in the medium and
    // nothing stops a caller handing over a negative height -- a slab configured
    // below sea level, or an expression driving the generating level under zero.
    // A negative altitude puts the origin inside the planet, where shellEnter()
    // returns a root behind the ray and the march runs backwards through the air.
    // Clamping is what the density profile already does with `hc` below.
    const float observerAltitude = originAltitude > 0.0f ? originAltitude : 0.0f;

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

        // THE SAMPLE IS DIMMED BY THE AIR UP TO THE STEP'S MIDDLE: every step before
        // it, plus HALF of its own. Leaving this step out brightens the horizon;
        // counting ALL of it, as this line did until build 17 while its comment said
        // half, darkened it -- measured against 4096 steps in double
        // (slang.skyParity, check 5): the whole ray was 16.5% dark at 1 degree of
        // elevation, 9.4% at 5 and 3.1% at 20. At the midpoint it is under 1% at all
        // three, with the same 24 steps.
        const float midR = depthR + 0.5f * dR;
        const float midM = depthM + 0.5f * dM;
        depthR += dR;
        depthM += dM;

        // THE INNER MARCH IS A TABLE LOOKUP NOW -- eight steps of quadrature, run at
        // every one of the twenty-four steps of this loop, for a quantity that does
        // not depend on the view direction at all.
        //
        // FACTORED RATHER THAN SUMMED, AND IT IS THE SAME NUMBER. The old line
        // exponentiated (view + sun) together; exp(-(a+b)) is exp(-a)*exp(-b), so
        // splitting them is what lets the sun half come from the table while the view
        // half stays an accumulation along this ray.
        const Vec3 sunT = sampleTransmittanceLut(transmittanceLut, scaleHeight,
                                                 hc, lutMuFor(p, sun));

        const Vec3 viewT = vec3(expf(-(betaR.x * midR + betaMExt * midM)),
                                expf(-(betaR.y * midR + betaMExt * midM)),
                                expf(-(betaR.z * midR + betaMExt * midM)));

        const Vec3 transmittance = viewT * sunT;

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

        // ALTITUDE ZERO, because this point is on the ground by construction.
        const Vec3 sunT = sampleTransmittanceLut(transmittanceLut, scaleHeight,
                                                 0.0f, lutMuFor(groundPoint, sun));

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
// The ground's skylight
// ---------------------------------------------------------------------------
//
// albedo / pi times the irradiance the sky dome puts on flat ground at altitude 0:
// SkyInput.groundSkyLight in SkyLib.slang, which says why the ground needs it. The
// kernel's skyRadiance adds it where a ray lands on the ground; THIS FILE'S DOES NOT,
// because this one is the reference slang.skyParity compares against with it at zero.
//
// HOST ONLY, AND DELIBERATELY NOT MT_DEVICE. It is muSteps x azimuthSteps sky marches,
// once per change of the sky (deriveRenderInputs caches it), and nothing on the device
// should ever call it.
//
// MIDPOINTS IN mu, EACH WEIGHTED BY ITS mu. The weights of N midpoints sum to exactly one
// half, which is the integral of mu dmu, so a uniform sky of radiance L gives exactly
// albedo L: the white furnace's answer.
//
// NOT EQUAL STEPS OF mu^2, which would make every point carry the same weight. That
// substitution was tried first and converged to only about 1%, at a high sun as much as
// a low one: it puts a square root into the radiance at the horizon, where the sky
// brightens fastest. Measured against a grid sixteen times as fine in TestAtmosphere.
//
// THE DISC IS LEFT OUT: it is the ground's sunlit term already, and a grid point that
// landed in a disc of 7e-5 sr would count it many times over. So the sky is asked with a
// sun of zero radius, whose disc no direction can land in (cosTheta is clamped to 1).
//
// ONE ANSWER FOR ALL THE GROUND IN VIEW. The sky over a patch 40 km off sees the sun
// 0.36 degrees lower, which only matters for a sun on the horizon, and there the sky's
// share of the ground's light is dim anyway.
inline void groundSkyLightFor(const cloud::FieldParams& field, const float* transmittanceLut,
                              int muSteps, int azimuthSteps, float out[3]) {
    cloud::FieldParams sky = field;
    sky.atmosphere.sunAngularRadius = 0.0f;

    double r = 0.0, g = 0.0, b = 0.0;
    for (int i = 0; i < muSteps; ++i) {
        const double mu   = (i + 0.5) / muSteps;
        const double sinT = std::sqrt(1.0 - mu * mu);
        for (int j = 0; j < azimuthSteps; ++j) {
            const double phi = 6.283185307179586 * (j + 0.5) / azimuthSteps;
            const Vec3 d = vec3(static_cast<float>(sinT * std::sin(phi)),
                                static_cast<float>(mu),
                                static_cast<float>(sinT * std::cos(phi)));
            const Vec3 L = skyRadiance(sky, 0.0f, d, transmittanceLut);
            r += L.x * mu;
            g += L.y * mu;
            b += L.z * mu;
        }
    }

    // albedo / pi, times 2 pi / azimuthSteps for the azimuth, times 1 / muSteps for mu.
    const double w = 2.0 * static_cast<double>(field.atmosphere.groundAlbedo)
                   / (static_cast<double>(muSteps) * azimuthSteps);
    out[0] = static_cast<float>(r * w);
    out[1] = static_cast<float>(g * w);
    out[2] = static_cast<float>(b * w);
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

// The sRGB opto-electronic transfer function (IEC 61966-2-1).
//
// ===========================================================================
// THE ONE COPY, AND IT IS IN THE KERNEL BECAUSE THAT IS WHERE THE OUTPUT TRANSFORM IS.
//
// It used to live in src/ae/AEBridge.h and then in src/engine/OutputConvert.h, applied
// only on the 8 and 16 bpc paths -- which is what made a comp render differently at
// different bit depths. It belongs with the exposure and the tonemap, because it is the
// third stage of the same transform, and those are here.
//
// THE LINEAR SEGMENT NEAR ZERO IS NOT OPTIONAL. A pure 1/2.4 power curve has infinite
// slope at the origin, which turns a path tracer's noise in the darkest values into
// visible speckle -- and the darkest values are exactly where its noise lives.
//
// NOT CLAMPED ABOVE ONE, which is where this deliberately differs from
// proto/index.html. The prototype clamps to 0..1 before encoding because a WebGL canvas
// has nowhere to put more; a 32 bpc AE buffer does, and the sun is what is in it. The
// curve extends above 1 continuously -- 4.0 encodes to 1.83 -- so the headroom survives,
// compressed, and the integer quantiser clamps at its own end where it must.
// ===========================================================================
MT_DEVICE float encodeSrgbChannel(float linear) {
    if (linear <= 0.0f)       return 0.0f;
    if (linear <= 0.0031308f) return linear * 12.92f;
    return 1.055f * powf(linear, 1.0f / 2.4f) - 0.055f;
}

MT_DEVICE Vec3 encodeSrgbVec(Vec3 c) {
    return vec3(encodeSrgbChannel(c.x), encodeSrgbChannel(c.y), encodeSrgbChannel(c.z));
}

MT_DEVICE Vec3 applyOutputTransform(Vec3 radiance, const cloud::ViewParams& view) {
    // REAL EV, applied as a power of two, because that is what the unit means.
    const float gain = exp2f(view.exposureEV);
    Vec3 c = radiance * gain;

    if (!view.agxTonemap) {
        // NO TONEMAP: values above 1.0 are the sun and they stay above 1.0, because
        // that is what "no tonemap" has to mean if the switch is worth anything. The
        // transfer curve below is not a tonemap -- it is what makes a monitor show a
        // linear value correctly, and skipping it renders near-black with a sun in it.
        return view.encodeSrgb ? encodeSrgbVec(c) : c;
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

    // AgX LANDS IN DISPLAY-REFERRED sRGB PRIMARIES, AND THE TRANSFER CURVE IS STILL
    // OURS TO APPLY. proto/index.html says so in the same words at its own output, and
    // it is the easy one to get wrong: AgX looks like a complete output transform and
    // is only two thirds of one.
    const Vec3 tonemapped = vec3(ch[0], ch[1], ch[2]);
    return view.encodeSrgb ? encodeSrgbVec(tonemapped) : tonemapped;
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
// The seam to the Slang kernel
// ---------------------------------------------------------------------------

// Linear radiance for one ray, traced through the medium and the atmosphere.
//
// ===========================================================================
// DECLARED HERE AND DEFINED BY WHICHEVER BACKEND INCLUDES THIS HEADER. That
// indirection is one line and it is what keeps renderPixel ONE FUNCTION.
//
// The transport is written once, in Slang, and compiled to CUDA and to C++. Those
// two compilations emit DIFFERENT SYMBOLS -- different struct layouts, different
// vector types, and both `static` to their own translation unit -- so this header,
// which is included by both, cannot name either of them. What it can do is call a
// function of its own and let the including file supply it:
//
//     Mistytune.cu   includes the generated Render.cu,    then defines this
//     CpuRender.cpp  includes the generated RenderCpu.cpp, then defines this
//
// Both definitions are four lines of marshalling over src/kernel/SlangBridge.h,
// which is itself written once. Nothing about the renderer exists twice.
//
// A TU THAT NEVER CALLS renderPixel NEEDS NO DEFINITION, which is why
// tests/unit/TestCamera.cpp and tests/slang/SkyParityMain.cu still include this
// header and link: an inline function that is not called is not odr-used.
// ===========================================================================
//
// `tGeo` STOPS THE CAMERA RAY AT THE SCENE'S GEOMETRY (build 30), or is kNoSceneGeometry;
// `see` comes back as how much of that geometry shows through, 0 when there is none. See
// pathBegin in BounceLib.slang.
MT_RENDER Vec3 mistytuneTrace(const RenderRequest& req, Vec3 ro, Vec3 rd,
                              unsigned int seed, float tGeo, float& see);

// NO GEOMETRY ON A CAMERA RAY: BounceLib.slang's kNoGeometry, which the kernel compares
// every distance on the ray against. The same number on both sides of the seam.
constexpr float kNoSceneGeometry = 1e30f;

// THE OPEN SKY AS GEOMETRY AT INFINITY (build 31), for Background: Transparent. Past the top of
// the air and past every cloud -- airSegment stops at the atmosphere and slabRange at 120 km --
// so the ray gathers everything it would have and is then stopped short of the sky itself.
// Below kNoSceneGeometry, because the kernel tells the two apart by comparing with it.
constexpr float kSkyGeometry = 1e29f;

// Where a camera ray starts, in world space.
//
// +Y IS ALTITUDE IN METRES and the ground plane is y = 0, which is the convention
// the atmosphere, the slab and the generator all share. A camera 2 m up at the
// origin is at (0, 2, 0).
//
// ===========================================================================
// THE MATRIX TRANSLATION IS STILL NOT READ HERE, AND THAT IS STILL THE RULE.
//
// The first version of this function took elements 3, 7 and 11 of cameraToWorld
// when `cameraFromComp` was set. Those are comp PIXELS in AE's world and zeros after
// CameraConvert, and they put the camera at altitude zero -- a bug no render could
// show. The camera now DOES travel, and the position arrives the one way the old
// note asked for: converted to metres once, by observerFromAE in CameraConvert.h
// with the Camera Travel scale, and carried in ViewParams' observer fields. The
// matrix stays a pure rotation, so nothing here can consume a pixel as a metre.
// ===========================================================================
MT_DEVICE Vec3 primaryRayOrigin(const cloud::ViewParams& view) {
    return vec3(view.observerX, view.observerAltitude, view.observerZ);
}

// ---------------------------------------------------------------------------
// One pixel, start to finish
// ---------------------------------------------------------------------------

// Draft's pixel stride, clamped: below one is one, and past eight a block is no longer a
// preview of anything. See QualityParams::pixelStride.
MT_DEVICE int pixelStrideOf(const RenderRequest& req) {
    const int s = req.quality.pixelStride;
    return s < 1 ? 1 : (s > 8 ? 8 : s);
}

// ===========================================================================
// THE SCENE'S GEOMETRY UNDER ONE SAMPLE (build 30): the distance ALONG THE RAY to the building
// in the footage's depth pass at the sample's own jittered spot in the frame, or
// kNoSceneGeometry.
//
// THE DEPTH PASS IS MATCHED TO THE FRAME BY FRACTION, so a pass at another resolution, or the
// frame at AE's half resolution, lines up. NEAREST TEXEL, not bilinear: a mean of a building's
// depth and the open sky's is a depth that is neither, and the jitter already spreads each
// pixel's samples over its area, which is what antialiases the edge.
//
// A HALF-COVERED TEXEL -- a soft key edge -- is geometry for that fraction of the samples, by a
// number of its own drawn from the sample's hash, so the path's stream is untouched.
//
// THE PASS IS PLANAR, as a depth pass is: a wall square to the lens is one depth across the
// frame. Along a ray off the axis the same wall is farther, by 1 / cos.
// ===========================================================================
MT_DEVICE float sceneGeometryAlong(const RenderRequest& req, float fx, float fy, Vec3 dir,
                                   unsigned int h) {
    const float* map = static_cast<const float*>(req.sceneBuffer);
    if (map == nullptr || req.sceneWidth <= 0 || req.sceneHeight <= 0) return kNoSceneGeometry;
    const float w  = static_cast<float>(req.view.widthPx);
    const float hh = static_cast<float>(req.view.heightPx);
    if (w <= 0.0f || hh <= 0.0f) return kNoSceneGeometry;

    int tx = static_cast<int>(fx / w * static_cast<float>(req.sceneWidth));
    int ty = static_cast<int>(fy / hh * static_cast<float>(req.sceneHeight));
    tx = tx < 0 ? 0 : (tx >= req.sceneWidth ? req.sceneWidth - 1 : tx);
    ty = ty < 0 ? 0 : (ty >= req.sceneHeight ? req.sceneHeight - 1 : ty);

    const float* t = map + (static_cast<long long>(ty) * req.sceneWidth + tx) * 2;
    const float metres   = t[0];
    const float coverage = t[1];
    if (!(metres > 0.0f) || !(coverage > 0.0f)) return kNoSceneGeometry;
    if (coverage < 1.0f && unitFloat(h * 0x2c1b3c6du + 0x297a2d39u) >= coverage)
        return kNoSceneGeometry;

    const float* m = req.view.cameraToWorld;
    const float along = -(dir.x * m[2] + dir.y * m[6] + dir.z * m[10]);
    if (!(along > 1e-4f)) return kNoSceneGeometry;
    return metres / along;
}

// One sample's camera ray: its direction and its seed. The origin is the same for every
// sample of every pixel -- primaryRayOrigin -- so the callers lift it out of their loops.
//
// AND, SINCE BUILD 30, WHERE THE SCENE'S GEOMETRY STOPS IT: see sceneGeometryAlong.
//
// A FUNCTION OF ITS OWN SINCE BUILD 25, when the staged GPU render began tracing a launch's
// samples one stage at a time instead of one pixel at a time. renderPixel calls it exactly
// as it ran inline, so the CPU reference and both GPU paths trace the same rays.
MT_DEVICE void pixelSampleRay(const RenderRequest& req, int px, int py, int s,
                              Vec3& dir, unsigned int& seed, float& tGeo) {
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
    //
    // AT A PIXEL STRIDE THE SEED IS THE BLOCK'S FIRST FRAME PIXEL, so each block keeps its own
    // stream however the frame is divided.
    const int stride = pixelStrideOf(req);
    const int frameX = px * stride + req.view.originX;
    const int frameY = py * stride + req.view.originY;

    const int sampleIndex = req.firstSample + s;
    const unsigned int h = hashPixelSample(frameX, frameY, sampleIndex, req.field.seed);

    // Two decorrelated dimensions from one hash. Blue-noise offsets stable
    // across frames are a Phase 2 upgrade -- they are the first mitigation to
    // reach for against denoiser flicker, and they need a texture this
    // placeholder has no way to carry.
    const float jx = unitFloat(h) - 0.5f;
    const float jy = unitFloat(h * 0x9e3779b9u + 0x632be59bu) - 0.5f;

    dir  = primaryRayDirection(req.view, px, py, jx, jy, stride);
    seed = h;

    // THE SAME JITTERED SPOT primaryRayDirection aimed at, in frame pixels -- which spreads a
    // pixel's samples over its area and so antialiases the geometry's edge.
    //
    // AT A PIXEL STRIDE, THE BLOCK'S CENTRE INSTEAD. Draft has one sample per block, so a
    // jittered spot made every block on an edge building or sky at random: MEASURED, a
    // ragged line of notches along every tower. The centre makes the edge a clean staircase
    // one block wide, which the scale-up then softens.
    tGeo = kNoSceneGeometry;
    if (req.sceneBuffer != nullptr) {
        const float sf = static_cast<float>(stride);
        const float fx = stride > 1
            ? static_cast<float>(req.view.originX) + (static_cast<float>(px) + 0.5f) * sf
            : static_cast<float>(px + req.view.originX) + 0.5f + jx;
        const float fy = stride > 1
            ? static_cast<float>(req.view.originY) + (static_cast<float>(py) + 0.5f) * sf
            : static_cast<float>(py + req.view.originY) + 0.5f + jy;
        tGeo = sceneGeometryAlong(req, fx, fy, dir, h);
    }

    // BACKGROUND: TRANSPARENT (build 31): what the depth pass leaves open is stopped at
    // infinity, so the holdout takes the sky away and keeps the clouds. A depth pass's own
    // geometry still stops the ray where it stands.
    if (req.view.transparentSky && !(tGeo < kNoSceneGeometry)) tGeo = kSkyGeometry;
}

// The pixel's finish: this launch's samples, summed in sample order by the caller, into the
// accumulator, and the linear mean into the destination. Shared with the staged GPU render
// for the reason pixelSampleRay is.
//
// `seeSum` IS THE SAMPLES' SUMMED SCENE VISIBILITY (build 30), kept in the accumulator's fourth
// float beside the radiance -- which was always there and always zero, so a frame without a
// depth pass stores and writes exactly what it did. The pixel's alpha is one minus its mean.
MT_DEVICE void finishPixel(const RenderRequest& req, int px, int py, Vec3 sum, float seeSum) {
    // PROGRESSIVE ACCUMULATION, weighted by the counts rather than by a running
    // lerp factor. A lerp with 1/n loses precision as n grows; a running sum
    // divided once does not, and the sum is what the denoiser wants anyway.
    Vec3 mean;
    float meanSee = 0.0f;
    if (req.accumulator != nullptr) {
        const int idx = py * req.accumulatorPitchPx * 4 + px * 4;
        float* acc = req.accumulator + idx;

        if (req.samplesAlreadyDone <= 0) {
            acc[0] = sum.x; acc[1] = sum.y; acc[2] = sum.z; acc[3] = seeSum;
        } else {
            acc[0] += sum.x; acc[1] += sum.y; acc[2] += sum.z; acc[3] += seeSum;
        }

        const int total = req.samplesAlreadyDone + req.sampleCount;
        const float inv = total > 0 ? 1.0f / static_cast<float>(total) : 0.0f;
        mean = vec3(acc[0] * inv, acc[1] * inv, acc[2] * inv);
        meanSee = acc[3] * inv;
    } else {
        const float inv = req.sampleCount > 0 ? 1.0f / static_cast<float>(req.sampleCount) : 0.0f;
        mean = sum * inv;
        meanSee = seeSum * inv;
    }

    // THE ALPHA: opaque where the sky is, transparent where the geometry shows. Exactly 1
    // without a depth pass, because every sample's see is exactly 0.
    float alpha = 1.0f - meanSee;
    alpha = alpha < 0.0f ? 0.0f : (alpha > 1.0f ? 1.0f : alpha);

    // NEVER BELOW ZERO WITH A DEPTH PASS. A geometry pixel's colour is the air in front of it
    // less the clear air the footage already has, and a cloud's shadow lying in that air makes
    // it slightly negative -- light taken OFF the footage, which an "over" cannot express. Only
    // the mean is clamped; the accumulator keeps the unbiased sum. THE SAME WITH A TRANSPARENT
    // BACKGROUND (build 31), whose open sky is geometry at infinity.
    if (req.sceneBuffer != nullptr || req.view.transparentSky) {
        mean.x = mean.x > 0.0f ? mean.x : 0.0f;
        mean.y = mean.y > 0.0f ? mean.y : 0.0f;
        mean.z = mean.z > 0.0f ? mean.z : 0.0f;
    }

    // ===================================================================
    // THE LINEAR MEAN GOES IN THE DESTINATION. THE OUTPUT TRANSFORM DOES NOT HAPPEN
    // HERE ANY MORE, AND THAT IS THE WHOLE POINT OF THE SPLIT.
    //
    // This used to be `applyOutputTransform(mean, req.view)`, which meant the
    // destination held exposed, possibly tonemapped, possibly sRGB-encoded values from
    // the moment the first sample landed. THE DENOISER WANTS LINEAR. OIDN's HDR filter
    // is built for scene-referred radiance, and handing it an AgX-tonemapped buffer is
    // wrong in a way that gets worse the more the tonemap is doing.
    //
    // The correct order is
    //
    //     kernel writes LINEAR mean -> denoise -> output transform -> quantise
    //
    // and the last three are per-FRAME, not per-sample: re-exposing on every chunk of
    // a split render was redundant work as well as the wrong buffer contents.
    // transformPixel() below is the third stage, run once by the caller when the frame
    // is complete. See KernelApi.h's transformCpu / transformCuda.
    // ===================================================================
    float* row = static_cast<float*>(req.dest.data) + py * req.dest.pitchPx * 4;
    float* pix = row + px * 4;

    // THE CHANNEL ORDER, ASKED AND NOT ASSUMED. See ChannelOrder in
    // RenderRequest.h for why this is a parameter.
    //
    // ALPHA IS 1 WHERE THE SKY IS, because a sky is opaque, and at alpha 1 premultiplied and
    // straight are the same numbers. WHERE A DEPTH PASS'S GEOMETRY SHOWS THROUGH (build 30) the
    // colour is ALREADY PREMULTIPLIED: it is what the ray gathered in front of the geometry,
    // which is light added over the footage, and that is what premultiplied colour is. So is
    // every pixel of a TRANSPARENT BACKGROUND (build 31): the clouds, over nothing.
    if (req.dest.order == ChannelOrder::BGRA) {
        pix[0] = mean.z; pix[1] = mean.y; pix[2] = mean.x; pix[3] = alpha;
    } else {
        pix[0] = alpha; pix[1] = mean.x; pix[2] = mean.y; pix[3] = mean.z;
    }
}


// The whole per-pixel job, shared verbatim between the CUDA kernel and the CPU
// reference. Neither has a copy of any of this.
//
// WRITES LINEAR RADIANCE INTO THE ACCUMULATOR AND THE TRANSFORMED RESULT INTO THE
// DESTINATION. Two buffers because the denoiser needs the linear one and the host
// needs the display one, and because the accumulator has to survive between
// launches while the destination is handed back to AE every time.
MT_RENDER void renderPixel(const RenderRequest& req, int px, int py) {
    if (px < 0 || py < 0 || px >= req.dest.widthPx || py >= req.dest.heightPx) return;

    Vec3  sum    = vec3(0.0f, 0.0f, 0.0f);
    float seeSum = 0.0f;

    // Loop-invariant, so it is lifted out by hand rather than left to the optimiser
    // to notice across a call boundary.
    const Vec3 origin = primaryRayOrigin(req.view);

    for (int s = 0; s < req.sampleCount; ++s) {
        Vec3         dir;
        unsigned int h;
        float        tGeo;
        pixelSampleRay(req, px, py, s, dir, h, tGeo);

        // THE ONE LINE. It used to be `skyRadiance(req.field, dir)` -- an analytic
        // sky and nothing in front of it, which is what Phase 1 was for. Everything
        // around it is unchanged: the frame-pixel seeding, the accumulator, the
        // output transform and the channel order are all still here, and all still
        // shared between the two backends.
        float see = 0.0f;
        sum = sum + mistytuneTrace(req, origin, dir, h, tGeo, see);
        seeSum += see;
    }

    finishPixel(req, px, py, sum, seeSum);
}

// ---------------------------------------------------------------------------
// The output transform, as a pass over a finished frame
// ---------------------------------------------------------------------------

// Exposure, tonemap and transfer curve, applied in place to one pixel of a
// destination that already holds linear radiance.
//
// ===========================================================================
// SHARED BETWEEN THE BACKENDS FOR THE SAME REASON renderPixel IS. CpuRender.cpp and
// Mistytune.cu each wrap this in their own loop and neither has a copy of the
// arithmetic, so a golden image taken on the CPU still certifies the GPU.
//
// IT READS WHAT IT WRITES, which makes it safe to run exactly once and wrong to run
// twice. Running it twice squares the gain and applies the transfer curve to an
// already-encoded value; the result is washed out rather than broken, which is the
// bad kind of wrong. The caller runs it once per frame, after the last band and the
// last sample chunk.
//
// ALPHA IS NOT TOUCHED. It is coverage, not light -- the same rule the quantiser in
// src/engine/OutputConvert.h follows, and for the same reason.
//
// THE CHANNEL ORDER IS READ BACK THE WAY renderPixel WROTE IT rather than assumed to
// be irrelevant. Today applyOutputTransform happens to be per-channel, so BGRA and
// ARGB would give the same answer either way; AgX with the inset and outset matrices
// proto/index.html uses is NOT per-channel, and this is the function those matrices
// land in. Unpacking properly now costs two lines and stops that port from silently
// swapping red and blue.
// ===========================================================================
MT_DEVICE void transformPixel(const RenderRequest& req, int px, int py) {
    if (px < 0 || py < 0 || px >= req.dest.widthPx || py >= req.dest.heightPx) return;
    if (req.dest.data == nullptr) return;

    float* row = static_cast<float*>(req.dest.data) + py * req.dest.pitchPx * 4;
    float* pix = row + px * 4;

    const bool bgra = (req.dest.order == ChannelOrder::BGRA);

    const Vec3 linear = bgra ? vec3(pix[2], pix[1], pix[0])
                             : vec3(pix[1], pix[2], pix[3]);
    const float alpha = bgra ? pix[3] : pix[0];

    // A PARTLY TRANSPARENT PIXEL (build 30, a depth pass's geometry showing through) IS
    // PREMULTIPLIED, and the transform is not linear: the colour is divided by alpha,
    // transformed, and multiplied back, as OutputConvert.h says a generator with genuine
    // coverage must. At alpha 1 -- every pixel without a depth pass -- this is the line it
    // always was.
    Vec3 out;
    if (alpha >= 1.0f) {
        out = applyOutputTransform(linear, req.view);
    } else if (alpha > 1e-6f) {
        out = applyOutputTransform(linear * (1.0f / alpha), req.view) * alpha;
    } else {
        out = vec3(0.0f, 0.0f, 0.0f);
    }

    if (bgra) {
        pix[0] = out.z; pix[1] = out.y; pix[2] = out.x;
    } else {
        pix[1] = out.x; pix[2] = out.y; pix[3] = out.z;
    }
}

} // namespace plugin::kernel
