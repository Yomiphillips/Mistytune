// GENERATED FROM Sky.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

static __device__ float dot_0(float3  x_0, float3  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y + x_0.z * y_0.z;
}

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S1 = __ldg(&(ptr_0->x));
    float _S2 = __ldg(&(ptr_0->y));
    float _S3 = __ldg(&(ptr_0->z));
    return make_float3 (_S1, _S2, _S3);
}

static __device__ float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static __device__ float3  normalizeExact_0(float3  v_0)
{
    float len2_0 = dot_0(v_0, v_0);
    if(len2_0 <= 0.0f)
    {
        return make_float3 (0.0f, 1.0f, 0.0f);
    }
    return v_0 * make_float3 (1.0f / (F32_sqrt((len2_0))));
}

struct SkyInput_0
{
    float planetRadius_0;
    float scaleHeight_0;
    float turbidity_0;
    float mieAnisotropy_0;
    float sunAzimuth_0;
    float sunElevation_0;
    float sunIntensity_0;
    float sunAngularRadius_0;
    float groundAlbedo_0;
};

static __device__ float3  sunDirection_0(SkyInput_0 * p_0)
{
    float az_0 = toRadians_0(p_0->sunAzimuth_0);
    float el_0 = toRadians_0(p_0->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static __device__ float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_0 = altitude_0 - shellHeight_0;
    return d_0 * (d_0 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_0, float c_0)
{
    float disc_0 = b_0 * b_0 - c_0;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_0 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_1, float c_1)
{
    float disc_1 = b_1 * b_1 - c_1;
    if(disc_1 < 0.0f)
    {
        return -1.0f;
    }
    return - b_1 - (F32_sqrt((disc_1)));
}

static __device__ float3  rayleighCoefficients_0()
{
    return make_float3 (5.80200003241770901e-06f, 0.00001355800031888f, 0.00003310000101919f);
}

static __device__ float mieCoefficient_0(float turbidity_1)
{
    return 3.99600003220257349e-06f * (turbidity_1 / 2.20000004768371582f);
}

static __device__ float clampf_0(float v_1, float lo_0, float hi_0)
{
    float _S4;
    if(v_1 < lo_0)
    {
        _S4 = lo_0;
    }
    else
    {
        if(v_1 > hi_0)
        {
            _S4 = hi_0;
        }
        else
        {
            _S4 = v_1;
        }
    }
    return _S4;
}

static __device__ float altitudeFromQ_0(float q_0, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_0;
    float _S5;
    if(rr_0 > 0.0f)
    {
        _S5 = rr_0;
    }
    else
    {
        _S5 = 0.0f;
    }
    return q_0 / (planetRadius_2 + (F32_sqrt((_S5))));
}

static __device__ void sunOpticalDepth_0(float altitude_1, float bSun_0, float planetRadius_3, float atmosphereHeight_0, float rayleighScaleHeight_0, float * outRayleigh_0, float * outMie_0)
{
    *outRayleigh_0 = 0.0f;
    *outMie_0 = 0.0f;
    float cGround_0 = shellC_0(altitude_1, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(bSun_0, shellC_0(altitude_1, planetRadius_3, atmosphereHeight_0));
    if(tTop_0 <= 0.0f)
    {
        return;
    }
    if((shellEnter_0(bSun_0, cGround_0)) > 0.0f)
    {
        *outRayleigh_0 = 1.0e+09f;
        *outMie_0 = 1.0e+09f;
        return;
    }
    float sPrev_0 = 0.0f;
    int i_0 = int(0);
    for(;;)
    {
        if(i_0 < int(8))
        {
        }
        else
        {
            break;
        }
        int _S6 = i_0 + int(1);
        float sNext_0 = tTop_0 * float(_S6 * _S6) * 0.015625f;
        float ds_0 = sNext_0 - sPrev_0;
        float sMid_0 = (sPrev_0 + sNext_0) * 0.5f;
        if(ds_0 <= 0.0f)
        {
            sPrev_0 = sNext_0;
            i_0 = _S6;
            continue;
        }
        float h_0 = altitudeFromQ_0(cGround_0 + 2.0f * sMid_0 * bSun_0 + sMid_0 * sMid_0, planetRadius_3);
        float hc_0;
        if(h_0 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_0;
        }
        float _S7 = - hc_0;
        *outRayleigh_0 = *outRayleigh_0 + (F32_exp((_S7 / rayleighScaleHeight_0))) * ds_0;
        *outMie_0 = *outMie_0 + (F32_exp((_S7 / 1200.0f))) * ds_0;
        sPrev_0 = sNext_0;
        i_0 = _S6;
    }
    return;
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_1)
{
    return 20.0f * p_1->sunIntensity_0;
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_2, float3  rayDir_0, bool includeSunDisc_0)
{
    float3  _S8 = sunDirection_0(p_2);
    float _S9 = p_2->planetRadius_0;
    float planetRadius_4;
    if((p_2->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S9;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S10 = p_2->scaleHeight_0;
    float scaleHeight_1;
    if((p_2->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S10;
    }
    else
    {
        scaleHeight_1 = 1.0f;
    }
    float atmosphereHeight_1 = scaleHeight_1 * 8.0f;
    float _S11 = planetRadius_4 + 2.0f;
    float _S12 = rayDir_0.y;
    float b_2 = _S11 * _S12;
    float cGround_1 = shellC_0(2.0f, planetRadius_4, 0.0f);
    float tTop_1 = shellExit_0(b_2, shellC_0(2.0f, planetRadius_4, atmosphereHeight_1));
    if(tTop_1 <= 0.0f)
    {
        return make_float3 (0.0f, 0.0f, 0.0f);
    }
    float tGround_0 = shellEnter_0(b_2, cGround_1);
    bool hitsGround_0 = tGround_0 > 0.0f;
    float safeSolid_0;
    if(hitsGround_0)
    {
        safeSolid_0 = tGround_0;
    }
    else
    {
        safeSolid_0 = tTop_1;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_2->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_0, _S8), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_0 = clampf_0(p_2->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S13 = g_0 * g_0;
    float hgDenom_0 = 1.0f + _S13 - 2.0f * g_0 * cosTheta_0;
    float _S14 = 1.0f - _S13;
    float _S15 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S14 / (_S15 * (F32_sqrt((tPrev_0))));
    float3  _S16 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    float3  sumR_0 = _S16;
    float3  sumM_0 = _S16;
    int i_1 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_1 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S17 = i_1 + int(1);
        float tNext_0 = safeSolid_0 * float(_S17 * _S17) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_1 = _S17;
            continue;
        }
        float h_1 = altitudeFromQ_0(cGround_1 + 2.0f * tMid_0 * b_2 + tMid_0 * tMid_0, planetRadius_4);
        float hc_1;
        if(h_1 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_1;
        }
        float _S18 = - hc_1;
        float dR_0 = (F32_exp((_S18 / scaleHeight_1))) * dt_0;
        float dM_0 = (F32_exp((_S18 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        float sunR_0;
        float sunM_0;
        sunOpticalDepth_0(hc_1, dot_0(make_float3 (rayDir_0.x * tMid_0, _S11 + _S12 * tMid_0, rayDir_0.z * tMid_0), _S8), planetRadius_4, atmosphereHeight_1, scaleHeight_1, &sunR_0, &sunM_0);
        float3  transmittance_0 = make_float3 ((F32_exp((- (betaR_0.x * (depthR_1 + sunR_0) + betaMExt_0 * (depthM_1 + sunM_0))))), (F32_exp((- (betaR_0.y * (depthR_1 + sunR_0) + betaMExt_0 * (depthM_1 + sunM_0))))), (F32_exp((- (betaR_0.z * (depthR_1 + sunR_0) + betaMExt_0 * (depthM_1 + sunM_0))))));
        float3  _S19 = sumM_0 + transmittance_0 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_0 * make_float3 (dR_0);
        sumM_0 = _S19;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_1 = _S17;
    }
    float _S20 = sunIrradianceTop_0(p_2);
    float3  radiance_0 = (sumR_0 * betaR_0 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S20);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_0.x * tGround_0, _S11 + _S12 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S8), 0.0f, 1.0f);
        float sunR_1;
        float sunM_1;
        sunOpticalDepth_0(0.0f, dot_0(groundPoint_0, _S8), planetRadius_4, atmosphereHeight_1, scaleHeight_1, &sunR_1, &sunM_1);
        float _S21 = betaR_0.x;
        float _S22 = betaR_0.y;
        float _S23 = betaR_0.z;
        float _S24 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + make_float3 ((F32_exp((- (_S21 * depthR_0 + _S24)))), (F32_exp((- (_S22 * depthR_0 + _S24)))), (F32_exp((- (_S23 * depthR_0 + _S24))))) * make_float3 ((F32_exp((- (_S21 * sunR_1 + betaMExt_0 * sunM_1)))), (F32_exp((- (_S22 * sunR_1 + betaMExt_0 * sunM_1)))), (F32_exp((- (_S23 * sunR_1 + betaMExt_0 * sunM_1))))) * make_float3 (p_2->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S20);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S25;
    if(!hitsGround_0)
    {
        _S25 = includeSunDisc_0;
    }
    else
    {
        _S25 = false;
    }
    if(_S25)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_2->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S26 = betaMExt_0 * depthM_0;
            float3  viewT_0 = make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S26)))), (F32_exp((- (betaR_0.y * depthR_0 + _S26)))), (F32_exp((- (betaR_0.z * depthR_0 + _S26)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                safeSolid_0 = solidAngle_0;
            }
            else
            {
                safeSolid_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * make_float3 (_S20 / safeSolid_0);
        }
    }
    return radiance_1;
}

extern "C" __global__ void skyMain(SkyInput_0 params_0, StructuredBuffer<float3 > directions_0, RWStructuredBuffer<float3 > output_0, int count_0)
{
    int i_2 = int((blockIdx * blockDim + threadIdx).x);
    if(i_2 >= count_0)
    {
        return;
    }
    float3  * _S27 = (&(output_0)[i_2]);
    float3  _S28 = slang_ldg_0((&(directions_0)[i_2]));
    SkyInput_0 _S29 = params_0;
    float3  _S30 = skyRadiance_0(&_S29, _S28, true);
    *_S27 = _S30;
    return;
}

