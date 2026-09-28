// The Phase 1 sky, in Slang -- the LIBRARY half.
//
// Split out of Sky.slang so that the renderer can include the atmosphere without
// also inheriting its test entry point. Sky.slang is now that entry point and
// nothing else; every line of maths below is where it has always been.
//
// ===========================================================================
// A TRANSCRIPTION OF Shading.h's skyRadiance(), NOT A REWRITE OF IT.
//
// PROGRESS.md records the measurement this rests on: Slang's CUDA output calls the
// same math functions the hand-written kernel does, bit for bit, over 44,001 inputs.
// So the ONLY way this file can disagree with Shading.h is if a human mistyped it --
// which is exactly why it is a line-for-line transcription rather than a tidier
// second version of the same physics.
//
// THE EXPRESSION STRUCTURE IS PRESERVED EVEN WHERE IT LOOKS REDUNDANT. Floating-point
// addition is not associative, so `a * (b + c)` and `a * b + a * c` are different
// numbers. Every reassociation is a chance to be off by a bit, and slang.skyParity
// compares against the hand-written kernel BITWISE -- so a "cleaner" rewrite of any
// line here is a test failure, not an improvement.
//
// WHY THE COMMENTS ARE NOT COPIED ACROSS. Shading.h explains WHY this maths is shaped
// the way it is -- the ray-sphere algebra, the quadratic step spacing, the
// double-attenuation bug that made the first attempt render green. That reasoning has
// one home and duplicating it would let the two copies drift. What is kept here is
// only what a reader needs to check the transcription itself.
// ===========================================================================

// Everything skyRadiance needs out of FieldParams, flattened.
//
// FLAT AND EXPLICIT RATHER THAN MIRRORING FieldParams. Reproducing a nested C++
// struct's layout in another language means matching its padding, and a silent
// mismatch there corrupts every parameter at once while still rendering a picture.
// This is a declared ABI with one job, populated by the caller field by field.
public struct SkyInput
{
    float planetRadius;
    float scaleHeight;
    float turbidity;
    float mieAnisotropy;
    float sunAzimuth;        // degrees
    float sunElevation;      // degrees
    float sunIntensity;
    float sunAngularRadius;  // degrees
    float groundAlbedo;
};

static const float kMieScaleHeight      = 1200.0f;
static const float kAtmosphereEFoldings = 8.0f;
static const float kObserverAltitude    = 2.0f;

float clampf(float v, float lo, float hi)
{
    return v < lo ? lo : (v > hi ? hi : v);
}

float toRadians(float degrees) { return degrees * 0.01745329252f; }

// Shading.h's normalize, including its zero case and its refusal to use rsqrt.
float3 normalizeExact(float3 v)
{
    float len2 = dot(v, v);
    if (len2 <= 0.0f) return float3(0.0f, 1.0f, 0.0f);
    float inv = 1.0f / sqrt(len2);
    return v * inv;
}

float3 sunDirection(SkyInput p)
{
    float az    = toRadians(p.sunAzimuth);
    float el    = toRadians(p.sunElevation);
    float cosEl = cos(el);
    return normalizeExact(float3(sin(az) * cosEl, sin(el), cos(az) * cosEl));
}

float3 rayleighCoefficients() { return float3(5.802e-6f, 13.558e-6f, 33.1e-6f); }

float mieCoefficient(float turbidity)
{
    const float reference = 2.2f;
    return 3.996e-6f * (turbidity / reference);
}

float shellC(float altitude, float planetRadius, float shellHeight)
{
    float d = altitude - shellHeight;
    return d * (d + 2.0f * planetRadius + 2.0f * shellHeight);
}

float shellExit(float b, float c)
{
    float disc = b * b - c;
    if (disc < 0.0f) return -1.0f;
    return -b + sqrt(disc);
}

float shellEnter(float b, float c)
{
    float disc = b * b - c;
    if (disc < 0.0f) return -1.0f;
    return -b - sqrt(disc);
}

float altitudeFromQ(float q, float planetRadius)
{
    float R  = planetRadius;
    float rr = R * R + q;
    return q / (R + sqrt(rr > 0.0f ? rr : 0.0f));
}

void sunOpticalDepth(float altitude, float bSun,
                     float planetRadius, float atmosphereHeight,
                     float rayleighScaleHeight,
                     out float outRayleigh, out float outMie)
{
    outRayleigh = 0.0f;
    outMie      = 0.0f;

    float cGround = shellC(altitude, planetRadius, 0.0f);
    float cTop    = shellC(altitude, planetRadius, atmosphereHeight);

    float tTop = shellExit(bSun, cTop);
    if (tTop <= 0.0f) return;

    // The shadow test: a sample with the planet between it and the sun receives
    // nothing, said as a huge optical depth rather than a downstream branch.
    float tGround = shellEnter(bSun, cGround);
    if (tGround > 0.0f)
    {
        outRayleigh = 1e9f;
        outMie      = 1e9f;
        return;
    }

    const int steps = 8;
    float invSteps2 = 1.0f / float(steps * steps);
    float sPrev = 0.0f;

    for (int i = 0; i < steps; ++i)
    {
        float sNext = tTop * float((i + 1) * (i + 1)) * invSteps2;
        float ds    = sNext - sPrev;
        float sMid  = (sPrev + sNext) * 0.5f;
        sPrev = sNext;
        if (ds <= 0.0f) continue;

        float q  = cGround + 2.0f * sMid * bSun + sMid * sMid;
        float h  = altitudeFromQ(q, planetRadius);
        float hc = h < 0.0f ? 0.0f : h;

        outRayleigh += exp(-hc / rayleighScaleHeight) * ds;
        outMie      += exp(-hc / kMieScaleHeight) * ds;
    }
}

// The sun irradiance at the top of the atmosphere, on a surface facing it.
//
// ONE CONSTANT, ONE HOME. It used to be a literal inside skyRadiance; the bounce
// loop needs the same number for its next-event estimate, and two copies of a
// brightness constant is how the cloud and the sky behind it end up on different
// exposures for a reason nobody can find.
public float sunIrradianceTop(SkyInput p)
{
    return 20.0f * p.sunIntensity;
}

// includeSunDisc IS NOT A CONVENIENCE FLAG. It is what stops the sun being counted
// twice once this is the RENDERER's environment rather than a standalone sky.
//
// Every scattering event in the bounce loop already estimates the sun directly by
// next-event estimation. If an escaped path ALSO picked up the disc, the sun arrives
// by two routes -- and not merely twice as bright, which would be noticed. The disc
// subtends about 6.8e-5 steradians, so a path that happens to scatter into it comes
// home carrying something like 3e5 while its neighbours carry 1, and the image fills
// with single white pixels that no amount of averaging removes. That reads as a
// firefly problem and sends the reader to the phase function, which is where the
// prototype records the same trap.
//
// A camera ray that reached the sky WITHOUT ever scattering had no next-event
// estimate, so for that one the disc is the correct and only answer.
public float3 skyRadiance(SkyInput p, float3 rayDir, bool includeSunDisc)
{
    float3 sun = sunDirection(p);

    float planetRadius = p.planetRadius > 1000.0f ? p.planetRadius : 1000.0f;
    float scaleHeight  = p.scaleHeight > 1.0f ? p.scaleHeight : 1.0f;
    float atmosphereHeight = scaleHeight * kAtmosphereEFoldings;

    float b = (planetRadius + kObserverAltitude) * rayDir.y;

    float cGround = shellC(kObserverAltitude, planetRadius, 0.0f);
    float cTop    = shellC(kObserverAltitude, planetRadius, atmosphereHeight);

    float tTop = shellExit(b, cTop);
    if (tTop <= 0.0f) return float3(0.0f, 0.0f, 0.0f);

    float tGround   = shellEnter(b, cGround);
    bool  hitsGround = tGround > 0.0f;
    float tMax      = hitsGround ? tGround : tTop;

    float3 betaR    = rayleighCoefficients();
    float  betaM    = mieCoefficient(p.turbidity);
    float  betaMExt = betaM * 1.11f;

    float cosTheta = clampf(dot(rayDir, sun), -1.0f, 1.0f);

    float phaseR = 0.0596831f * (1.0f + cosTheta * cosTheta);

    float g       = clampf(p.mieAnisotropy, -0.95f, 0.95f);
    float hgDenom = 1.0f + g * g - 2.0f * g * cosTheta;
    float phaseM  = (1.0f - g * g) /
                    (12.566370614f * hgDenom * sqrt(hgDenom > 1e-6f ? hgDenom : 1e-6f));

    const int steps = 24;
    float invSteps2 = 1.0f / float(steps * steps);

    float3 sumR = float3(0.0f, 0.0f, 0.0f);
    float3 sumM = float3(0.0f, 0.0f, 0.0f);
    float  depthR = 0.0f;
    float  depthM = 0.0f;

    float tPrev = 0.0f;

    for (int i = 0; i < steps; ++i)
    {
        float tNext = tMax * float((i + 1) * (i + 1)) * invSteps2;
        float dt    = tNext - tPrev;
        float tMid  = (tPrev + tNext) * 0.5f;
        tPrev = tNext;

        if (dt <= 0.0f) continue;

        float q  = cGround + 2.0f * tMid * b + tMid * tMid;
        float h  = altitudeFromQ(q, planetRadius);
        float hc = h < 0.0f ? 0.0f : h;

        float3 pt = float3(rayDir.x * tMid,
                           planetRadius + kObserverAltitude + rayDir.y * tMid,
                           rayDir.z * tMid);
        float bSun = dot(pt, sun);

        float dR = exp(-hc / scaleHeight) * dt;
        float dM = exp(-hc / kMieScaleHeight) * dt;

        depthR += dR;
        depthM += dM;

        float sunR, sunM;
        sunOpticalDepth(hc, bSun, planetRadius, atmosphereHeight, scaleHeight, sunR, sunM);

        float tauX = betaR.x * (depthR + sunR) + betaMExt * (depthM + sunM);
        float tauY = betaR.y * (depthR + sunR) + betaMExt * (depthM + sunM);
        float tauZ = betaR.z * (depthR + sunR) + betaMExt * (depthM + sunM);

        float3 transmittance = float3(exp(-tauX), exp(-tauY), exp(-tauZ));

        sumR = sumR + transmittance * dR;
        sumM = sumM + transmittance * dM;
    }

    float irradiance = sunIrradianceTop(p);

    float3 radiance = (sumR * betaR * phaseR + sumM * (betaM * phaseM)) * irradiance;

    if (hitsGround)
    {
        float3 groundPoint = float3(rayDir.x * tGround,
                                    planetRadius + kObserverAltitude + rayDir.y * tGround,
                                    rayDir.z * tGround);
        float3 groundNormal = normalizeExact(groundPoint);
        float  nDotL = clampf(dot(groundNormal, sun), 0.0f, 1.0f);

        float sunR, sunM;
        sunOpticalDepth(0.0f, dot(groundPoint, sun), planetRadius, atmosphereHeight,
                        scaleHeight, sunR, sunM);

        float3 sunT = float3(exp(-(betaR.x * sunR + betaMExt * sunM)),
                             exp(-(betaR.y * sunR + betaMExt * sunM)),
                             exp(-(betaR.z * sunR + betaMExt * sunM)));

        float3 viewT = float3(exp(-(betaR.x * depthR + betaMExt * depthM)),
                              exp(-(betaR.y * depthR + betaMExt * depthM)),
                              exp(-(betaR.z * depthR + betaMExt * depthM)));

        float lambert = p.groundAlbedo * nDotL * 0.3183098862f;
        radiance = radiance + viewT * sunT * (lambert * irradiance);
    }

    if (!hitsGround && includeSunDisc)
    {
        float cosRadius = cos(toRadians(p.sunAngularRadius));
        if (cosTheta > cosRadius)
        {
            float3 viewT = float3(exp(-(betaR.x * depthR + betaMExt * depthM)),
                                  exp(-(betaR.y * depthR + betaMExt * depthM)),
                                  exp(-(betaR.z * depthR + betaMExt * depthM)));

            float solidAngle = 6.283185307f * (1.0f - cosRadius);
            float safeSolid  = solidAngle > 1e-9f ? solidAngle : 1e-9f;

            radiance = radiance + viewT * (irradiance / safeSolid);
        }
    }

    return radiance;
}

// ---------------------------------------------------------------------------
// What the sun looks like FROM INSIDE THE MEDIUM
// ---------------------------------------------------------------------------

// Atmospheric transmittance from a world point to the sun, per channel.
//
// ===========================================================================
// THIS IS WHAT MAKES A BACKLIT CIRRUS GO ORANGE AT THE RIGHT MOMENT, and it is why
// the cloud cannot simply be lit by a white sun and composited over a coloured sky.
//
// A crystal at 9 km with the sun two degrees above the horizon is lit by light that
// has come through a very long slant path of atmosphere -- so the light reaching it
// is already reddened, and by a different amount than the light reaching the ground
// or the light reaching a crystal at 6 km below it. Multiply a white sun by a
// reddened sky afterwards and the cloud is the wrong colour in a way that reads as
// a grading problem rather than a missing term.
//
// THE PROTOTYPE READS THIS OUT OF A PRECOMPUTED TABLE (Bruneton), and that table is
// still the Phase 2 upgrade -- it replaces the eight-step quadrature below with two
// texture fetches. What is here is the SAME integral the sky already runs per
// sample, called at a point instead of along a ray, so the two agree by construction
// and the table can be checked against it when it arrives.
// ===========================================================================
//
// THE POINT IS GEOCENTRIC, NOT LOCAL. World +Y is altitude and the planet centre
// sits at -planetRadius, so the vector from the centre to a world point is
// (x, planetRadius + y, z). Handing sunOpticalDepth a local position instead puts
// every scattering event at the centre of the planet, where it is always night.
public float3 sunTransmittanceAt(SkyInput p, float3 worldPos)
{
    float3 sun = sunDirection(p);

    float planetRadius = p.planetRadius > 1000.0f ? p.planetRadius : 1000.0f;
    float scaleHeight  = p.scaleHeight > 1.0f ? p.scaleHeight : 1.0f;
    float atmosphereHeight = scaleHeight * kAtmosphereEFoldings;

    float altitude = worldPos.y > 0.0f ? worldPos.y : 0.0f;

    float3 geocentric = float3(worldPos.x, planetRadius + worldPos.y, worldPos.z);
    float  bSun = dot(geocentric, sun);

    float sunR, sunM;
    sunOpticalDepth(altitude, bSun, planetRadius, atmosphereHeight, scaleHeight,
                    sunR, sunM);

    float3 betaR    = rayleighCoefficients();
    float  betaMExt = mieCoefficient(p.turbidity) * 1.11f;

    // The same per-channel extinction the sky integral uses, spelled out rather than
    // vectorised, because Sky.slang's transcription rule is that the expression
    // structure is preserved and the parity test compares bitwise.
    return float3(exp(-(betaR.x * sunR + betaMExt * sunM)),
                  exp(-(betaR.y * sunR + betaMExt * sunM)),
                  exp(-(betaR.z * sunR + betaMExt * sunM)));
}
