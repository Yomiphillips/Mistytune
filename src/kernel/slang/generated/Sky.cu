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
        float midR_0 = depthR_0 + 0.5f * dR_0;
        float midM_0 = depthM_0 + 0.5f * dM_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        float3  _S36 = sampleTransmittanceLut_0(p_3, hc_0, lutMuFor_0(make_float3 (rayDir_0.x * tMid_0, _S28 + _S29 * tMid_0, rayDir_0.z * tMid_0), _S25));
        float _S37 = betaMExt_0 * midM_0;
        float3  transmittance_0 = make_float3 ((F32_exp((- (betaR_0.x * midR_0 + _S37)))), (F32_exp((- (betaR_0.y * midR_0 + _S37)))), (F32_exp((- (betaR_0.z * midR_0 + _S37))))) * _S36;
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

struct AirSegment_0
{
    float3  airIn_0;
    float3  airT_0;
    float shadowAt_0;
};

static __device__ AirSegment_0 airSegment_0(SkyInput_0 * p_4, float originAltitude_2, float3  rayDir_1, float dist_0, float u1_0, float u2_0)
{
    AirSegment_0 seg_0;
    float3  _S48 = make_float3 (0.0f, 0.0f, 0.0f);
    (&seg_0)->airIn_0 = _S48;
    (&seg_0)->airT_0 = make_float3 (1.0f, 1.0f, 1.0f);
    (&seg_0)->shadowAt_0 = -1.0f;
    float3  _S49 = sunDirection_0(p_4);
    float _S50 = p_4->planetRadius_0;
    float planetRadius_4;
    if((p_4->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S50;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S51 = p_4->scaleHeight_0;
    float scaleHeight_3;
    if((p_4->scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = _S51;
    }
    else
    {
        scaleHeight_3 = 1.0f;
    }
    float atmosphereHeight_1 = scaleHeight_3 * 8.0f;
    float observerAltitude_1;
    if(originAltitude_2 > 0.0f)
    {
        observerAltitude_1 = originAltitude_2;
    }
    else
    {
        observerAltitude_1 = 0.0f;
    }
    float _S52 = planetRadius_4 + observerAltitude_1;
    float _S53 = rayDir_1.y;
    float b_3 = _S52 * _S53;
    float cGround_1 = shellC_0(observerAltitude_1, planetRadius_4, 0.0f);
    float tTop_1 = shellExit_0(b_3, shellC_0(observerAltitude_1, planetRadius_4, atmosphereHeight_1));
    bool _S54;
    if(tTop_1 <= 0.0f)
    {
        _S54 = true;
    }
    else
    {
        _S54 = !(dist_0 > 0.0f);
    }
    if(_S54)
    {
        return seg_0;
    }
    float tGround_1 = shellEnter_0(b_3, cGround_1);
    float tMax_0;
    if(tGround_1 > 0.0f)
    {
        tMax_0 = tGround_1;
    }
    else
    {
        tMax_0 = tTop_1;
    }
    if(dist_0 < tMax_0)
    {
        tMax_0 = dist_0;
    }
    float3  betaR_1 = rayleighCoefficients_0();
    float betaM_1 = mieCoefficient_0(p_4->turbidity_0);
    float betaMExt_1 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rayDir_1, _S49), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_1 = clampf_0(p_4->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S55 = g_1 * g_1;
    float hgDenom_1 = 1.0f + _S55 - 2.0f * g_1 * cosTheta_1;
    float _S56 = 1.0f - _S55;
    float _S57 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        observerAltitude_1 = hgDenom_1;
    }
    else
    {
        observerAltitude_1 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S56 / (_S57 * (F32_sqrt((observerAltitude_1))));
    float tPrev_1 = 0.0f;
    float3  sumR_1 = _S48;
    float3  sumM_1 = _S48;
    float u_0 = u1_0;
    float pickedFrom_0 = -1.0f;
    float pickedSpan_0 = 0.0f;
    int i_2 = int(0);
    float depthR_2 = 0.0f;
    float depthM_2 = 0.0f;
    float lumTotal_0 = 0.0f;
    for(;;)
    {
        if(i_2 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S58 = i_2 + int(1);
        float tNext_1 = tMax_0 * float(_S58 * _S58) * 0.00173611112404615f;
        float dt_1 = tNext_1 - tPrev_1;
        float tMid_1 = (tPrev_1 + tNext_1) * 0.5f;
        float u_1;
        float pickedFrom_1;
        float pickedSpan_1;
        if(dt_1 <= 0.0f)
        {
            u_1 = u_0;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            tPrev_1 = tNext_1;
            u_0 = u_1;
            pickedFrom_0 = pickedFrom_1;
            pickedSpan_0 = pickedSpan_1;
            i_2 = _S58;
            continue;
        }
        float h_1 = altitudeFromQ_0(cGround_1 + 2.0f * tMid_1 * b_3 + tMid_1 * tMid_1, planetRadius_4);
        float hc_1;
        if(h_1 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_1;
        }
        float _S59 = - hc_1;
        float dR_1 = (F32_exp((_S59 / scaleHeight_3))) * dt_1;
        float dM_1 = (F32_exp((_S59 / 1200.0f))) * dt_1;
        float midR_1 = depthR_2 + 0.5f * dR_1;
        float midM_1 = depthM_2 + 0.5f * dM_1;
        float depthR_3 = depthR_2 + dR_1;
        float depthM_3 = depthM_2 + dM_1;
        float3  _S60 = sampleTransmittanceLut_0(p_4, hc_1, lutMuFor_0(make_float3 (rayDir_1.x * tMid_1, _S52 + _S53 * tMid_1, rayDir_1.z * tMid_1), _S49));
        float _S61 = betaMExt_1 * midM_1;
        float3  transmittance_1 = make_float3 ((F32_exp((- (betaR_1.x * midR_1 + _S61)))), (F32_exp((- (betaR_1.y * midR_1 + _S61)))), (F32_exp((- (betaR_1.z * midR_1 + _S61))))) * _S60;
        float3  _S62 = sumR_1 + transmittance_1 * make_float3 (dR_1);
        float3  _S63 = sumM_1 + transmittance_1 * make_float3 (dM_1);
        float3  c_3 = transmittance_1 * (betaR_1 * make_float3 (phaseR_1 * dR_1) + make_float3 (betaM_1 * (phaseM_1 * dM_1)));
        float lum_0 = c_3.x + c_3.y + c_3.z;
        float lumTotal_1;
        if(lum_0 > 0.0f)
        {
            float lumTotal_2 = lumTotal_0 + lum_0;
            float keep_0 = lum_0 / lumTotal_2;
            if(u_0 < keep_0)
            {
                u_1 = u_0 / keep_0;
                pickedFrom_1 = tPrev_1;
                pickedSpan_1 = dt_1;
            }
            else
            {
                u_1 = (u_0 - keep_0) / (1.0f - keep_0);
                pickedFrom_1 = pickedFrom_0;
                pickedSpan_1 = pickedSpan_0;
            }
            lumTotal_1 = lumTotal_2;
        }
        else
        {
            u_1 = u_0;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            lumTotal_1 = lumTotal_0;
        }
        sumR_1 = _S62;
        sumM_1 = _S63;
        depthR_2 = depthR_3;
        depthM_2 = depthM_3;
        lumTotal_0 = lumTotal_1;
        tPrev_1 = tNext_1;
        u_0 = u_1;
        pickedFrom_0 = pickedFrom_1;
        pickedSpan_0 = pickedSpan_1;
        i_2 = _S58;
    }
    float _S64 = sunIrradianceTop_0(p_4);
    (&seg_0)->airIn_0 = (sumR_1 * betaR_1 * make_float3 (phaseR_1) + sumM_1 * make_float3 (betaM_1 * phaseM_1)) * make_float3 (_S64);
    float _S65 = betaMExt_1 * depthM_2;
    (&seg_0)->airT_0 = make_float3 ((F32_exp((- (betaR_1.x * depthR_2 + _S65)))), (F32_exp((- (betaR_1.y * depthR_2 + _S65)))), (F32_exp((- (betaR_1.z * depthR_2 + _S65)))));
    if(pickedFrom_0 >= 0.0f)
    {
        (&seg_0)->shadowAt_0 = pickedFrom_0 + clampf_0(u2_0, 0.0f, 1.0f) * pickedSpan_0;
    }
    return seg_0;
}

static __device__ float3  airTransmittance_0(SkyInput_0 * p_5, float originAltitude_3, float3  rayDir_2, float dist_1)
{
    float _S66 = p_5->planetRadius_0;
    float planetRadius_5;
    if((p_5->planetRadius_0) > 1000.0f)
    {
        planetRadius_5 = _S66;
    }
    else
    {
        planetRadius_5 = 1000.0f;
    }
    float _S67 = p_5->scaleHeight_0;
    float scaleHeight_4;
    if((p_5->scaleHeight_0) > 1.0f)
    {
        scaleHeight_4 = _S67;
    }
    else
    {
        scaleHeight_4 = 1.0f;
    }
    float atmosphereHeight_2 = scaleHeight_4 * 8.0f;
    float observerAltitude_2;
    if(originAltitude_3 > 0.0f)
    {
        observerAltitude_2 = originAltitude_3;
    }
    else
    {
        observerAltitude_2 = 0.0f;
    }
    float b_4 = (planetRadius_5 + observerAltitude_2) * rayDir_2.y;
    float cGround_2 = shellC_0(observerAltitude_2, planetRadius_5, 0.0f);
    float tTop_2 = shellExit_0(b_4, shellC_0(observerAltitude_2, planetRadius_5, atmosphereHeight_2));
    bool _S68;
    if(tTop_2 <= 0.0f)
    {
        _S68 = true;
    }
    else
    {
        _S68 = !(dist_1 > 0.0f);
    }
    if(_S68)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float tGround_2 = shellEnter_0(b_4, cGround_2);
    float tMax_1;
    if(tGround_2 > 0.0f)
    {
        tMax_1 = tGround_2;
    }
    else
    {
        tMax_1 = tTop_2;
    }
    if(dist_1 < tMax_1)
    {
        tMax_1 = dist_1;
    }
    float3  betaR_2 = rayleighCoefficients_0();
    float betaMExt_2 = mieCoefficient_0(p_5->turbidity_0) * 1.11000001430511475f;
    float tPrev_2 = 0.0f;
    int i_3 = int(0);
    float depthR_4 = 0.0f;
    float depthM_4 = 0.0f;
    for(;;)
    {
        if(i_3 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S69 = i_3 + int(1);
        float tNext_2 = tMax_1 * float(_S69 * _S69) * 0.00173611112404615f;
        float dt_2 = tNext_2 - tPrev_2;
        float tMid_2 = (tPrev_2 + tNext_2) * 0.5f;
        if(dt_2 <= 0.0f)
        {
            tPrev_2 = tNext_2;
            i_3 = _S69;
            continue;
        }
        float h_2 = altitudeFromQ_0(cGround_2 + 2.0f * tMid_2 * b_4 + tMid_2 * tMid_2, planetRadius_5);
        float hc_2;
        if(h_2 < 0.0f)
        {
            hc_2 = 0.0f;
        }
        else
        {
            hc_2 = h_2;
        }
        float _S70 = - hc_2;
        float depthM_5 = depthM_4 + (F32_exp((_S70 / 1200.0f))) * dt_2;
        depthR_4 = depthR_4 + (F32_exp((_S70 / scaleHeight_4))) * dt_2;
        depthM_4 = depthM_5;
        tPrev_2 = tNext_2;
        i_3 = _S69;
    }
    float _S71 = betaMExt_2 * depthM_4;
    return make_float3 ((F32_exp((- (betaR_2.x * depthR_4 + _S71)))), (F32_exp((- (betaR_2.y * depthR_4 + _S71)))), (F32_exp((- (betaR_2.z * depthR_4 + _S71)))));
}

extern "C" __global__ void airMain(SkyInput_0 params_1, float originAltitude_4, StructuredBuffer<float3 > directions_1, StructuredBuffer<float> distances_0, StructuredBuffer<float2 > uniforms_0, RWStructuredBuffer<float3 > airIn_1, RWStructuredBuffer<float3 > airT_1, RWStructuredBuffer<float3 > trans_0, RWStructuredBuffer<float> shadowAt_1, RWStructuredBuffer<float3 > sky_0, int count_1)
{
    int i_4 = int((blockIdx * blockDim + threadIdx).x);
    if(i_4 >= count_1)
    {
        return;
    }
    float3  _S72 = slang_ldg_0((&(directions_1)[i_4]));
    float _S73 = __ldg((&(distances_0)[i_4]));
    float2  _S74 = __ldg((&(uniforms_0)[i_4]));
    float _S75 = _S74.x;
    float2  _S76 = __ldg((&(uniforms_0)[i_4]));
    float _S77 = _S76.y;
    SkyInput_0 _S78 = params_1;
    AirSegment_0 _S79 = airSegment_0(&_S78, originAltitude_4, _S72, _S73, _S75, _S77);
    *(&(airIn_1)[i_4]) = _S79.airIn_0;
    *(&(airT_1)[i_4]) = _S79.airT_0;
    *(&(shadowAt_1)[i_4]) = _S79.shadowAt_0;
    float3  * _S80 = (&(trans_0)[i_4]);
    float _S81 = __ldg((&(distances_0)[i_4]));
    SkyInput_0 _S82 = params_1;
    float3  _S83 = airTransmittance_0(&_S82, originAltitude_4, _S72, _S81);
    *_S80 = _S83;
    float3  * _S84 = (&(sky_0)[i_4]);
    SkyInput_0 _S85 = params_1;
    float3  _S86 = skyRadiance_0(&_S85, originAltitude_4, _S72, false);
    *_S84 = _S86;
    return;
}

