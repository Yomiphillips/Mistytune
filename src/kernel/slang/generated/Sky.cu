// GENERATED FROM Sky.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

static __device__ int StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    uint2  _S1 = make_uint2(_elementCount_0, _stride_0);
    return int(_S1.x);
}

static __device__ float dot_0(float3  x_0, float3  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y + x_0.z * y_0.z;
}

static __device__ float length_0(float3  x_1)
{
    return (F32_sqrt((dot_0(x_1, x_1))));
}

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S2 = __ldg(&(ptr_0->x));
    float _S3 = __ldg(&(ptr_0->y));
    float _S4 = __ldg(&(ptr_0->z));
    return make_float3 (_S2, _S3, _S4);
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
    StructuredBuffer<float> transmittanceLut_0;
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
    float _S5;
    if(v_1 < lo_0)
    {
        _S5 = lo_0;
    }
    else
    {
        if(v_1 > hi_0)
        {
            _S5 = hi_0;
        }
        else
        {
            _S5 = v_1;
        }
    }
    return _S5;
}

static __device__ float altitudeFromQ_0(float q_0, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_0;
    float _S6;
    if(rr_0 > 0.0f)
    {
        _S6 = rr_0;
    }
    else
    {
        _S6 = 0.0f;
    }
    return q_0 / (planetRadius_2 + (F32_sqrt((_S6))));
}

static __device__ float lutMuFor_0(float3  geocentric_0, float3  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S7;
    if(len_0 > 1.0f)
    {
        _S7 = dot_0(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S7 = dot_0(geocentric_0, sun_0);
    }
    return _S7;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_1, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S8 = p_1->transmittanceLut_0;
    if(uint(StructuredBuffer_getCount_0(p_1->transmittanceLut_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S9 = p_1->scaleHeight_0;
    float scaleHeight_1;
    if((p_1->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S9;
    }
    else
    {
        scaleHeight_1 = 1.0f;
    }
    float topAltitude_0 = scaleHeight_1 * 8.0f;
    float fx_0 = (clampf_0(mu_0, -1.0f, 1.0f) + 1.0f) * 0.5f * 256.0f - 0.5f;
    float fy_0 = (F32_sqrt((clampf_0(altitude_1, 0.0f, topAltitude_0) / topAltitude_0))) * 64.0f - 0.5f;
    float fx_1;
    if(fx_0 < 0.0f)
    {
        fx_1 = 0.0f;
    }
    else
    {
        fx_1 = fx_0;
    }
    float fy_1;
    if(fy_0 < 0.0f)
    {
        fy_1 = 0.0f;
    }
    else
    {
        fy_1 = fy_0;
    }
    int x0_0 = int(fx_1);
    int y0_0 = int(fy_1);
    int x0_1;
    if(x0_0 > int(255))
    {
        x0_1 = int(255);
    }
    else
    {
        x0_1 = x0_0;
    }
    int y0_1;
    if(y0_0 > int(63))
    {
        y0_1 = int(63);
    }
    else
    {
        y0_1 = y0_0;
    }
    int x1_0 = x0_1 + int(1);
    int y1_0 = y0_1 + int(1);
    int x1_1;
    if(x1_0 > int(255))
    {
        x1_1 = int(255);
    }
    else
    {
        x1_1 = x1_0;
    }
    int y1_1;
    if(y1_0 > int(63))
    {
        y1_1 = int(63);
    }
    else
    {
        y1_1 = y1_0;
    }
    float _S10 = fx_1 - float(x0_1);
    float _S11 = fy_1 - float(y0_1);
    int _S12 = y0_1 * int(256);
    int _S13 = (_S12 + x0_1) * int(3);
    int _S14 = (_S12 + x1_1) * int(3);
    int _S15 = y1_1 * int(256);
    int _S16 = (_S15 + x0_1) * int(3);
    int _S17 = (_S15 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_2 = int(0);
    for(;;)
    {
        if(c_2 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S18 = __ldg((&(_S8)[_S13 + c_2]));
        float _S19 = 1.0f - _S10;
        float _S20 = _S18 * _S19;
        float _S21 = __ldg((&(_S8)[_S14 + c_2]));
        float a_0 = _S20 + _S21 * _S10;
        float _S22 = __ldg((&(_S8)[_S16 + c_2]));
        float _S23 = _S22 * _S19;
        float _S24 = __ldg((&(_S8)[_S17 + c_2]));
        float r_0 = a_0 * (1.0f - _S11) + (_S23 + _S24 * _S10) * _S11;
        if(c_2 == int(0))
        {
            *&((&out_0)->x) = r_0;
        }
        else
        {
            if(c_2 == int(1))
            {
                *&((&out_0)->y) = r_0;
            }
            else
            {
                *&((&out_0)->z) = r_0;
            }
        }
        c_2 = c_2 + int(1);
    }
    return out_0;
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_2)
{
    return 20.0f * p_2->sunIntensity_0;
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_3, float originAltitude_0, float3  rayDir_0, bool includeSunDisc_0)
{
    float hc_0;
    float3  _S25 = sunDirection_0(p_3);
    float _S26 = p_3->planetRadius_0;
    float planetRadius_3;
    if((p_3->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S26;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S27 = p_3->scaleHeight_0;
    float scaleHeight_2;
    if((p_3->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S27;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float atmosphereHeight_0 = scaleHeight_2 * 8.0f;
    float observerAltitude_0;
    if(originAltitude_0 > 0.0f)
    {
        observerAltitude_0 = originAltitude_0;
    }
    else
    {
        observerAltitude_0 = 0.0f;
    }
    float _S28 = planetRadius_3 + observerAltitude_0;
    float _S29 = rayDir_0.y;
    float b_2 = _S28 * _S29;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(b_2, shellC_0(observerAltitude_0, planetRadius_3, atmosphereHeight_0));
    if(tTop_0 <= 0.0f)
    {
        return make_float3 (0.0f, 0.0f, 0.0f);
    }
    float tGround_0 = shellEnter_0(b_2, cGround_0);
    bool hitsGround_0 = tGround_0 > 0.0f;
    if(hitsGround_0)
    {
        observerAltitude_0 = tGround_0;
    }
    else
    {
        observerAltitude_0 = tTop_0;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_3->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_0, _S25), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_0 = clampf_0(p_3->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S30 = g_0 * g_0;
    float hgDenom_0 = 1.0f + _S30 - 2.0f * g_0 * cosTheta_0;
    float _S31 = 1.0f - _S30;
    float _S32 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S31 / (_S32 * (F32_sqrt((tPrev_0))));
    float3  _S33 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    float3  sumR_0 = _S33;
    float3  sumM_0 = _S33;
    int i_0 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_0 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S34 = i_0 + int(1);
        float tNext_0 = observerAltitude_0 * float(_S34 * _S34) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_0 = _S34;
            continue;
        }
        float h_0 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_2 + tMid_0 * tMid_0, planetRadius_3);
        if(h_0 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_0;
        }
        float _S35 = - hc_0;
        float dR_0 = (F32_exp((_S35 / scaleHeight_2))) * dt_0;
        float dM_0 = (F32_exp((_S35 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        float3  _S36 = sampleTransmittanceLut_0(p_3, hc_0, lutMuFor_0(make_float3 (rayDir_0.x * tMid_0, _S28 + _S29 * tMid_0, rayDir_0.z * tMid_0), _S25));
        float _S37 = betaMExt_0 * depthM_1;
        float3  transmittance_0 = make_float3 ((F32_exp((- (betaR_0.x * depthR_1 + _S37)))), (F32_exp((- (betaR_0.y * depthR_1 + _S37)))), (F32_exp((- (betaR_0.z * depthR_1 + _S37))))) * _S36;
        float3  _S38 = sumM_0 + transmittance_0 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_0 * make_float3 (dR_0);
        sumM_0 = _S38;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_0 = _S34;
    }
    float _S39 = sunIrradianceTop_0(p_3);
    float3  radiance_0 = (sumR_0 * betaR_0 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S39);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_0.x * tGround_0, _S28 + _S29 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S25), 0.0f, 1.0f);
        float3  _S40 = sampleTransmittanceLut_0(p_3, 0.0f, lutMuFor_0(groundPoint_0, _S25));
        float _S41 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S41)))), (F32_exp((- (betaR_0.y * depthR_0 + _S41)))), (F32_exp((- (betaR_0.z * depthR_0 + _S41))))) * _S40 * make_float3 (p_3->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S39);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S42;
    if(!hitsGround_0)
    {
        _S42 = includeSunDisc_0;
    }
    else
    {
        _S42 = false;
    }
    if(_S42)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_3->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S43 = betaMExt_0 * depthM_0;
            float3  viewT_0 = make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S43)))), (F32_exp((- (betaR_0.y * depthR_0 + _S43)))), (F32_exp((- (betaR_0.z * depthR_0 + _S43)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_0 = solidAngle_0;
            }
            else
            {
                hc_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * make_float3 (_S39 / hc_0);
        }
    }
    return radiance_1;
}

extern "C" __global__ void skyMain(SkyInput_0 params_0, float originAltitude_1, StructuredBuffer<float3 > directions_0, RWStructuredBuffer<float3 > output_0, int count_0)
{
    int i_1 = int((blockIdx * blockDim + threadIdx).x);
    if(i_1 >= count_0)
    {
        return;
    }
    float3  * _S44 = (&(output_0)[i_1]);
    float3  _S45 = slang_ldg_0((&(directions_0)[i_1]));
    SkyInput_0 _S46 = params_0;
    float3  _S47 = skyRadiance_0(&_S46, originAltitude_1, _S45, true);
    *_S44 = _S47;
    return;
}

