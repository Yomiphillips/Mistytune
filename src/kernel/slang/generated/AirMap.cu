// GENERATED FROM AirMap.slang BY slangc -- DO NOT EDIT.
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

static __device__ float length_0(float3  x_1)
{
    return (F32_sqrt((dot_0(x_1, x_1))));
}

static __device__ int StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    uint2  _S1 = make_uint2(_elementCount_0, _stride_0);
    return int(_S1.x);
}

static __device__ float3  lerp_0(float3  x_2, float3  y_1, float3  s_0)
{
    return x_2 + (y_1 - x_2) * s_0;
}

static __device__ float4  lerp_1(float4  x_3, float4  y_2, float4  s_1)
{
    return x_3 + (y_2 - x_3) * s_1;
}

static __device__ int2  min_0(int2  x_4, int2  y_3)
{
    int2  result_0;
    int i_0 = int(0);
    for(;;)
    {
        if(i_0 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_0, i_0) = (I32_min((_slang_vector_get_element(x_4, i_0)), (_slang_vector_get_element(y_3, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ float2  max_0(float2  x_5, float2  y_4)
{
    float2  result_1;
    int i_1 = int(0);
    for(;;)
    {
        if(i_1 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_max((_slang_vector_get_element(x_5, i_1)), (_slang_vector_get_element(y_4, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ float2  min_1(float2  x_6, float2  y_5)
{
    float2  result_2;
    int i_2 = int(0);
    for(;;)
    {
        if(i_2 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_2, i_2) = (F32_min((_slang_vector_get_element(x_6, i_2)), (_slang_vector_get_element(y_5, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ float2  clamp_0(float2  x_7, float2  minBound_0, float2  maxBound_0)
{
    return min_1(max_0(x_7, minBound_0), maxBound_0);
}

struct Organization_0
{
    int ogOn_0;
    float2  ogAxis_0;
    float ogStretch_0;
    float ogCoherence_0;
    float2  ogWaveK_0;
    float ogWaveAmp_0;
    float ogWarp_0;
};

struct ConvectionInput_0
{
    float cvBase_0;
    float cvDepth_0;
    float cvSpacing_0;
    float cvPolarity_0;
    float cvCoverage_0;
    float cvShape_0;
    float cvSigma_0;
    float cvBillow_0;
    float cvBillowScale_0;
    int cvOctaves_0;
    float2  cvDrift_0;
    float cvAge_0;
    float cvRise_0;
    int cvHeroAlone_0;
    float2  cvHeroAt_0;
    float cvHeroRadius_0;
    float cvHeroTop_0;
    float3  cvHeroSeed_0;
    float cvHeroBillow_0;
    Organization_0 cvOrg_0;
    float cvGapWidth_0;
    float cvLacunarity_0;
    int cvShapeOn_0;
    StructuredBuffer<float> cvShapeMap_0;
    int2  cvShapeDim_0;
    float2  cvShapeOffset_0;
    float cvShapeTexel_0;
    float2  cvShapeAxisU_0;
    float cvShapeRound_0;
    float cvShapeHalfWidth_0;
    float cvShapeDecay_0;
    float cvShapeBillow_0;
    float cvReliefHeight_0;
    float cvReliefSlope_0;
    float cvReliefFade_0;
    float cvMoat_0;
    float cvGroupReach_0;
    int cvTurretCount_0;
    float4  cvTurret0_0;
    float4  cvTurret1_0;
    float4  cvTurret2_0;
    float4  cvTurret3_0;
    float4  cvTurret4_0;
    float cvMammaDepth_0;
    float cvPouchSize_0;
    float cvPileusThick_0;
    float cvPileusGap_0;
    float cvVelumThick_0;
    float cvVelumHeight_0;
};

static __device__ float dot_1(float2  x_8, float2  y_6)
{
    return x_8.x * y_6.x + x_8.y * y_6.y;
}

static __device__ float3  floor_0(float3  x_9)
{
    float3  result_3;
    int i_3 = int(0);
    for(;;)
    {
        if(i_3 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_3, i_3) = (F32_floor((_slang_vector_get_element(x_9, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ uint3  pcg3d_0(uint3  v_0)
{
    uint3  _S2 = v_0 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S3 = _S2;
    *&((&_S3)->x) = *&((&_S3)->x) + _S2.y * _S2.z;
    *&((&_S3)->y) = *&((&_S3)->y) + _S3.z * _S3.x;
    *&((&_S3)->z) = *&((&_S3)->z) + _S3.x * _S3.y;
    uint3  _S4 = _S3 ^ (_S3 >> make_uint3 (16U));
    _S3 = _S4;
    *&((&_S3)->x) = *&((&_S3)->x) + _S4.y * _S4.z;
    *&((&_S3)->y) = *&((&_S3)->y) + _S3.z * _S3.x;
    *&((&_S3)->z) = *&((&_S3)->z) + _S3.x * _S3.y;
    return _S3;
}

static __device__ float3  hash33_0(int3  c_0)
{
    uint3  h_0 = pcg3d_0(make_uint3 (uint(c_0.x), uint(c_0.y), uint(c_0.z)));
    float3  _S5 = make_float3 ((float)h_0.x, (float)h_0.y, (float)h_0.z);
    return _S5 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float lerp_2(float x_10, float y_7, float s_2)
{
    return x_10 + (y_7 - x_10) * s_2;
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_0(p_0);
    int3  _S6 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S7 = u_0.x;
    float _S8 = u_0.y;
    return lerp_2(lerp_2(lerp_2(dot_0(hash33_0(_S6), f_0), dot_0(hash33_0(_S6 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S7), lerp_2(dot_0(hash33_0(_S6 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S6 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S7), _S8), lerp_2(lerp_2(dot_0(hash33_0(_S6 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S6 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S7), lerp_2(dot_0(hash33_0(_S6 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S6 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S7), _S8), u_0.z);
}

static __device__ float2  orgWarpOffset_0(Organization_0 * o_0, float2  g_0)
{
    float2  s_3 = g_0 / make_float2 (2.5f);
    float _S9 = s_3.x;
    float _S10 = s_3.y;
    return make_float2 (o_0->ogWarp_0) * make_float2 (gradientNoise_0(make_float3 (_S9, 0.37000000476837158f, _S10)), gradientNoise_0(make_float3 (_S9 + 17.10000038146972656f, 5.82999992370605469f, _S10 - 9.39999961853027344f)));
}

static __device__ float2  orgPattern_0(Organization_0 * o_1, float2  q_0, float spacing_0)
{
    if((o_1->ogOn_0) == int(0))
    {
        return q_0 / make_float2 (spacing_0);
    }
    float2  g_1 = make_float2 (dot_1(q_0, o_1->ogAxis_0), dot_1(q_0, make_float2 (- o_1->ogAxis_0.y, o_1->ogAxis_0.x))) / make_float2 (spacing_0 * o_1->ogStretch_0, spacing_0);
    float2  g_2;
    if((o_1->ogWarp_0) > 0.0f)
    {
        float2  _S11 = orgWarpOffset_0(o_1, g_1);
        g_2 = g_1 + _S11;
    }
    else
    {
        g_2 = g_1;
    }
    return g_2;
}

static __device__ float2  floor_1(float2  x_11)
{
    float2  result_4;
    int i_4 = int(0);
    for(;;)
    {
        if(i_4 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_4, i_4) = (F32_floor((_slang_vector_get_element(x_11, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static __device__ uint2  pcg2d_0(uint2  v_1)
{
    uint2  _S12 = v_1 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S13 = _S12;
    *&((&_S13)->x) = *&((&_S13)->x) + _S12.y * 1664525U;
    *&((&_S13)->y) = *&((&_S13)->y) + _S13.x * 1664525U;
    uint2  _S14 = _S13 ^ (_S13 >> make_uint2 (16U));
    _S13 = _S14;
    *&((&_S13)->x) = *&((&_S13)->x) + _S14.y * 1664525U;
    *&((&_S13)->y) = *&((&_S13)->y) + _S13.x * 1664525U;
    uint2  _S15 = _S13 ^ (_S13 >> make_uint2 (16U));
    _S13 = _S15;
    return _S15;
}

static __device__ float2  hash22_0(int2  c_1, uint salt_0)
{
    uint2  h_1 = pcg2d_0(make_uint2 (uint(c_1.x), uint(c_1.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S16 = make_float2 ((float)h_1.x, (float)h_1.y);
    return _S16 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float convLife_0(float u_1)
{
    float _S17 = 1.0f - u_1;
    return 6.75f * u_1 * _S17 * _S17;
}

static __device__ float convVigour_0(ConvectionInput_0 * c_2, int2  slot_0)
{
    float2  h_2 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_2(0.34999999403953552f, 1.0f, h_2.y);
}

static __device__ float2  orgJitter_0(Organization_0 * o_2, float jitter_0)
{
    float _S18;
    if((o_2->ogOn_0) != int(0))
    {
        _S18 = jitter_0 * (1.0f - o_2->ogCoherence_0);
    }
    else
    {
        _S18 = jitter_0;
    }
    return make_float2 (jitter_0, _S18);
}

static __device__ float2  convCellCentre_0(ConvectionInput_0 * c_3, int2  slot_1)
{
    float2  j_0 = hash22_0(slot_1, 1759714724U) - make_float2 (0.5f);
    float2  _S19 = make_float2 ((float)slot_1.x, (float)slot_1.y);
    float2  _S20 = _S19 + make_float2 (0.5f);
    float2  _S21 = orgJitter_0(&c_3->cvOrg_0, 0.69999998807907104f);
    return _S20 + j_0 * _S21;
}

static __device__ float convBump_0(float d2_0, float reach_0)
{
    float r2_0 = reach_0 * reach_0;
    if(d2_0 >= r2_0)
    {
        return 0.0f;
    }
    float t_0 = 1.0f - d2_0 / r2_0;
    return t_0 * t_0;
}

static __device__ float clamp_1(float x_12, float minBound_1, float maxBound_1)
{
    return (F32_min(((F32_max((x_12), (minBound_1)))), (maxBound_1)));
}

static __device__ float saturate_0(float x_13)
{
    return clamp_1(x_13, 0.0f, 1.0f);
}

static __device__ void convHole_0(ConvectionInput_0 * c_4, float2  d_0, float d2_1, float vig_0, float * keep_0, float2  * gKeep_0)
{
    float r_0 = 0.5f * c_4->cvLacunarity_0 * (F32_sqrt(((F32_sqrt((vig_0))))));
    if(!(d2_1 < (r_0 * r_0)))
    {
        return;
    }
    float dist_0 = (F32_sqrt((d2_1)));
    float inner_0 = 0.69999998807907104f * r_0;
    float band_0 = r_0 - inner_0;
    float t_1 = saturate_0((dist_0 - inner_0) / band_0);
    float k_0 = t_1 * t_1 * (3.0f - 2.0f * t_1);
    if(k_0 < (*keep_0))
    {
        *keep_0 = k_0;
        float2  _S22;
        if(dist_0 > 9.99999997475242708e-07f)
        {
            _S22 = d_0 * make_float2 (6.0f * t_1 * (1.0f - t_1) / (band_0 * dist_0));
        }
        else
        {
            _S22 = make_float2 (0.0f, 0.0f);
        }
        *gKeep_0 = _S22;
    }
    return;
}

static __device__ float2  lerp_3(float2  x_14, float2  y_8, float2  s_4)
{
    return x_14 + (y_8 - x_14) * s_4;
}

static __device__ float2  orgGradToWorld_0(Organization_0 * o_3, float2  gp_0, float spacing_1)
{
    if((o_3->ogOn_0) == int(0))
    {
        return gp_0 / make_float2 (spacing_1);
    }
    float2  s_5 = gp_0 / make_float2 (spacing_1 * o_3->ogStretch_0, spacing_1);
    return o_3->ogAxis_0 * make_float2 (s_5.x) + make_float2 (- o_3->ogAxis_0.y, o_3->ogAxis_0.x) * make_float2 (s_5.y);
}

static __device__ float orgWave_0(Organization_0 * o_4, float2  q_1, float2  * grad_0)
{
    *grad_0 = make_float2 (0.0f, 0.0f);
    bool _S23;
    if((o_4->ogOn_0) == int(0))
    {
        _S23 = true;
    }
    else
    {
        _S23 = (o_4->ogWaveAmp_0) <= 0.0f;
    }
    if(_S23)
    {
        return 1.0f;
    }
    float2  _S24 = o_4->ogWaveK_0;
    float s_6 = 2.0f * (F32_frac((dot_1(q_1, o_4->ogWaveK_0)))) - 1.0f;
    float tri_0 = 1.0f - (F32_abs((s_6)));
    float crest_0 = tri_0 * tri_0 * (3.0f - 2.0f * tri_0);
    float dCrest_0 = 6.0f * tri_0 * (1.0f - tri_0);
    float dTri_0;
    if(s_6 > 0.0f)
    {
        dTri_0 = -2.0f;
    }
    else
    {
        dTri_0 = 2.0f;
    }
    float _S25 = o_4->ogWaveAmp_0;
    *grad_0 = _S24 * make_float2 (o_4->ogWaveAmp_0 * dCrest_0 * dTri_0);
    return 1.0f - _S25 * (1.0f - crest_0);
}

static __device__ float convOrganize_0(ConvectionInput_0 * c_5, float2  q_2, float kTop_0, float kNext_0, float2  gkTop_0, float2  gkNext_0, float keep_1, float2  gKeep_1, float w_0, float2  gp_1, float2  * grad_1)
{
    float _S26 = c_5->cvLacunarity_0;
    float2  _S27;
    float _S28;
    if((c_5->cvLacunarity_0) > 0.0f)
    {
        float fill_0 = lerp_2(w_0, 0.40000000596046448f, _S26);
        float _S29 = fill_0 * keep_1;
        _S27 = gp_1 * make_float2 (1.0f - _S26) * make_float2 (keep_1) + gKeep_1 * make_float2 (fill_0);
        _S28 = _S29;
    }
    else
    {
        _S27 = gp_1;
        _S28 = w_0;
    }
    float _S30 = c_5->cvPolarity_0;
    bool _S31;
    if((c_5->cvPolarity_0) > 0.0f)
    {
        _S31 = (c_5->cvGapWidth_0) > 0.0f;
    }
    else
    {
        _S31 = false;
    }
    if(_S31)
    {
        float2  _S32 = make_float2 (0.0f, 0.0f);
        float2  gcn_0;
        float cn_0;
        if(kTop_0 > 0.0f)
        {
            float2  _S33 = (gkTop_0 * make_float2 (kNext_0) - gkNext_0 * make_float2 (kTop_0)) / make_float2 (kTop_0 * kTop_0);
            cn_0 = 1.0f - kNext_0 / kTop_0;
            gcn_0 = _S33;
        }
        else
        {
            cn_0 = 0.0f;
            gcn_0 = _S32;
        }
        float ramp_0 = 0.5f * c_5->cvGapWidth_0;
        float t_2 = saturate_0((cn_0 - ramp_0) / ramp_0);
        float s_7 = lerp_2(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S30);
        float _S34 = _S28 * s_7;
        _S27 = _S27 * make_float2 (s_7) + gcn_0 * make_float2 (_S28 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S30));
        _S28 = _S34;
    }
    float2  _S35 = orgGradToWorld_0(&c_5->cvOrg_0, _S27, c_5->cvSpacing_0);
    *grad_1 = _S35;
    float2  gm_0;
    float _S36 = orgWave_0(&c_5->cvOrg_0, q_2, &gm_0);
    *grad_1 = _S35 * make_float2 (_S36) + gm_0 * make_float2 (_S28);
    return _S28 * _S36;
}

static __device__ float convUpdraftGradT_0(ConvectionInput_0 * c_6, float2  q_3, float2  * grad_2)
{
    float2  goTop_0;
    float2  _S37 = orgPattern_0(&c_6->cvOrg_0, q_3, c_6->cvSpacing_0);
    float2  _S38 = floor_1(_S37);
    int2  _S39 = make_int2 ((int)_S38.x, (int)_S38.y);
    float2  _S40 = make_float2 (0.0f, 0.0f);
    float keep_2 = 1.0f;
    float2  gKeep_2 = _S40;
    float oTop_0 = 0.0f;
    float2  goTop_1 = _S40;
    float oNext_0 = 0.0f;
    float kTop_1 = 0.0f;
    float2  gkTop_1 = _S40;
    float kNext_1 = 0.0f;
    float2  goNext_0 = _S40;
    float2  gkNext_1 = _S40;
    int j_1 = int(-1);
    for(;;)
    {
        if(j_1 <= int(1))
        {
        }
        else
        {
            break;
        }
        float oTop_1 = oTop_0;
        goTop_0 = goTop_1;
        float oNext_1 = oNext_0;
        float kTop_2 = kTop_1;
        float2  gkTop_2 = gkTop_1;
        float kNext_2 = kNext_1;
        float2  goNext_1 = goNext_0;
        float2  gkNext_2 = gkNext_1;
        int i_5 = int(-1);
        for(;;)
        {
            if(i_5 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_2 = _S39 + make_int2 (i_5, j_1);
            float _S41 = convVigour_0(c_6, slot_2);
            if(_S41 <= 0.0f)
            {
                i_5 = i_5 + int(1);
                continue;
            }
            float2  _S42 = convCellCentre_0(c_6, slot_2);
            float2  d_1 = _S37 - _S42;
            float d2_2 = dot_1(d_1, d_1);
            float ko_0 = _S41 * convBump_0(d2_2, 0.75f);
            float kk_0 = _S41 * convBump_0(d2_2, 1.04999995231628418f);
            convHole_0(c_6, d_1, d2_2, _S41, &keep_2, &gKeep_2);
            float2  gko_0;
            if(d2_2 < 0.5625f)
            {
                gko_0 = d_1 * make_float2 (-4.0f * _S41 * (1.0f - d2_2 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S40;
            }
            float2  gkk_0;
            if(d2_2 < 1.10249984264373779f)
            {
                gkk_0 = d_1 * make_float2 (-4.0f * _S41 * (1.0f - d2_2 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S40;
            }
            float oTop_2;
            float oNext_2;
            float2  goTop_2;
            float2  goNext_2;
            if(ko_0 > oTop_1)
            {
                oTop_2 = ko_0;
                goTop_2 = gko_0;
                oNext_2 = oTop_1;
                goNext_2 = goTop_0;
            }
            else
            {
                if(ko_0 > oNext_1)
                {
                    oTop_2 = ko_0;
                    goTop_2 = gko_0;
                }
                else
                {
                    oTop_2 = oNext_1;
                    goTop_2 = goNext_1;
                }
                float _S43 = oTop_2;
                float2  _S44 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S43;
                goNext_2 = _S44;
            }
            float kTop_3;
            float kNext_3;
            float2  gkTop_3;
            float2  gkNext_3;
            if(kk_0 > kTop_2)
            {
                kTop_3 = kk_0;
                gkTop_3 = gkk_0;
                kNext_3 = kTop_2;
                gkNext_3 = gkTop_2;
            }
            else
            {
                if(kk_0 > kNext_2)
                {
                    kTop_3 = kk_0;
                    gkTop_3 = gkk_0;
                }
                else
                {
                    kTop_3 = kNext_2;
                    gkTop_3 = gkNext_2;
                }
                float _S45 = kTop_3;
                float2  _S46 = gkTop_3;
                kTop_3 = kTop_2;
                gkTop_3 = gkTop_2;
                kNext_3 = _S45;
                gkNext_3 = _S46;
            }
            oTop_1 = oTop_2;
            goTop_0 = goTop_2;
            oNext_1 = oNext_2;
            kTop_2 = kTop_3;
            gkTop_2 = gkTop_3;
            kNext_2 = kNext_3;
            goNext_1 = goNext_2;
            gkNext_2 = gkNext_3;
            i_5 = i_5 + int(1);
        }
        int j_2 = j_1 + int(1);
        oTop_0 = oTop_1;
        goTop_1 = goTop_0;
        oNext_0 = oNext_1;
        kTop_1 = kTop_2;
        gkTop_1 = gkTop_2;
        kNext_1 = kNext_2;
        goNext_0 = goNext_1;
        gkNext_1 = gkNext_2;
        j_1 = j_2;
    }
    float openRaw_0 = oNext_0 / 0.31000000238418579f;
    float _S47 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_1 - kNext_1;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_0 = _S40;
    }
    float2  gClosed_0 = gkTop_1 - gkNext_1;
    float _S48 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_2(_S47, closedField_0, c_6->cvPolarity_0), lerp_3(goTop_0, gClosed_0, make_float2 (c_6->cvPolarity_0)), grad_2);
    return _S48;
}

static __device__ float convUpdraftGradT_1(ConvectionInput_0 * c_7, float2  q_4, float2  * grad_3)
{
    float2  goTop_3;
    float2  _S49 = orgPattern_0(&c_7->cvOrg_0, q_4, c_7->cvSpacing_0);
    float2  _S50 = floor_1(_S49);
    int2  _S51 = make_int2 ((int)_S50.x, (int)_S50.y);
    float2  gKeep_3 = make_float2 (0.0f, 0.0f);
    float oTop_3 = 0.0f;
    float2  goTop_4 = gKeep_3;
    float oNext_3 = 0.0f;
    float kTop_4 = 0.0f;
    float2  gkTop_4 = gKeep_3;
    float kNext_4 = 0.0f;
    float2  goNext_3 = gKeep_3;
    float2  gkNext_4 = gKeep_3;
    int j_3 = int(-1);
    for(;;)
    {
        if(j_3 <= int(1))
        {
        }
        else
        {
            break;
        }
        float oTop_4 = oTop_3;
        goTop_3 = goTop_4;
        float oNext_4 = oNext_3;
        float kTop_5 = kTop_4;
        float2  gkTop_5 = gkTop_4;
        float kNext_5 = kNext_4;
        float2  goNext_4 = goNext_3;
        float2  gkNext_5 = gkNext_4;
        int i_6 = int(-1);
        for(;;)
        {
            if(i_6 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_3 = _S51 + make_int2 (i_6, j_3);
            float _S52 = convVigour_0(c_7, slot_3);
            if(_S52 <= 0.0f)
            {
                i_6 = i_6 + int(1);
                continue;
            }
            float2  _S53 = convCellCentre_0(c_7, slot_3);
            float2  d_2 = _S49 - _S53;
            float d2_3 = dot_1(d_2, d_2);
            float ko_1 = _S52 * convBump_0(d2_3, 0.75f);
            float kk_1 = _S52 * convBump_0(d2_3, 1.04999995231628418f);
            float2  gko_1;
            if(d2_3 < 0.5625f)
            {
                gko_1 = d_2 * make_float2 (-4.0f * _S52 * (1.0f - d2_3 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_1 = gKeep_3;
            }
            float2  gkk_1;
            if(d2_3 < 1.10249984264373779f)
            {
                gkk_1 = d_2 * make_float2 (-4.0f * _S52 * (1.0f - d2_3 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_1 = gKeep_3;
            }
            float oTop_5;
            float oNext_5;
            float2  goTop_5;
            float2  goNext_5;
            if(ko_1 > oTop_4)
            {
                oTop_5 = ko_1;
                goTop_5 = gko_1;
                oNext_5 = oTop_4;
                goNext_5 = goTop_3;
            }
            else
            {
                if(ko_1 > oNext_4)
                {
                    oTop_5 = ko_1;
                    goTop_5 = gko_1;
                }
                else
                {
                    oTop_5 = oNext_4;
                    goTop_5 = goNext_4;
                }
                float _S54 = oTop_5;
                float2  _S55 = goTop_5;
                oTop_5 = oTop_4;
                goTop_5 = goTop_3;
                oNext_5 = _S54;
                goNext_5 = _S55;
            }
            float kTop_6;
            float kNext_6;
            float2  gkTop_6;
            float2  gkNext_6;
            if(kk_1 > kTop_5)
            {
                kTop_6 = kk_1;
                gkTop_6 = gkk_1;
                kNext_6 = kTop_5;
                gkNext_6 = gkTop_5;
            }
            else
            {
                if(kk_1 > kNext_5)
                {
                    kTop_6 = kk_1;
                    gkTop_6 = gkk_1;
                }
                else
                {
                    kTop_6 = kNext_5;
                    gkTop_6 = gkNext_5;
                }
                float _S56 = kTop_6;
                float2  _S57 = gkTop_6;
                kTop_6 = kTop_5;
                gkTop_6 = gkTop_5;
                kNext_6 = _S56;
                gkNext_6 = _S57;
            }
            oTop_4 = oTop_5;
            goTop_3 = goTop_5;
            oNext_4 = oNext_5;
            kTop_5 = kTop_6;
            gkTop_5 = gkTop_6;
            kNext_5 = kNext_6;
            goNext_4 = goNext_5;
            gkNext_5 = gkNext_6;
            i_6 = i_6 + int(1);
        }
        int j_4 = j_3 + int(1);
        oTop_3 = oTop_4;
        goTop_4 = goTop_3;
        oNext_3 = oNext_4;
        kTop_4 = kTop_5;
        gkTop_4 = gkTop_5;
        kNext_4 = kNext_5;
        goNext_3 = goNext_4;
        gkNext_4 = gkNext_5;
        j_3 = j_4;
    }
    float openRaw_1 = oNext_3 / 0.31000000238418579f;
    float _S58 = (F32_min((openRaw_1), (1.0f)));
    float closedField_1 = kTop_4 - kNext_4;
    if(openRaw_1 < 1.0f)
    {
        goTop_3 = goNext_3 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_3 = gKeep_3;
    }
    float2  gClosed_1 = gkTop_4 - gkNext_4;
    float _S59 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_2(_S58, closedField_1, c_7->cvPolarity_0), lerp_3(goTop_3, gClosed_1, make_float2 (c_7->cvPolarity_0)), grad_3);
    return _S59;
}

static __device__ float2  convCellCentrePlain_0(int2  slot_4)
{
    float2  _S60 = make_float2 ((float)slot_4.x, (float)slot_4.y);
    return _S60 + make_float2 (0.5f) + (hash22_0(slot_4, 1759714724U) - make_float2 (0.5f)) * make_float2 (0.69999998807907104f);
}

static __device__ float convUpdraftGradT_2(ConvectionInput_0 * c_8, float2  q_5, float2  * grad_4)
{
    float2  goTop_6;
    float _S61 = c_8->cvSpacing_0;
    float2  _S62 = q_5 / make_float2 (c_8->cvSpacing_0);
    float2  _S63 = floor_1(_S62);
    int2  _S64 = make_int2 ((int)_S63.x, (int)_S63.y);
    float2  _S65 = make_float2 (0.0f, 0.0f);
    float oTop_6 = 0.0f;
    float2  goTop_7 = _S65;
    float oNext_6 = 0.0f;
    float kTop_7 = 0.0f;
    float2  gkTop_7 = _S65;
    float kNext_7 = 0.0f;
    float2  goNext_6 = _S65;
    float2  gkNext_7 = _S65;
    int j_5 = int(-1);
    for(;;)
    {
        if(j_5 <= int(1))
        {
        }
        else
        {
            break;
        }
        float oTop_7 = oTop_6;
        goTop_6 = goTop_7;
        float oNext_7 = oNext_6;
        float kTop_8 = kTop_7;
        float2  gkTop_8 = gkTop_7;
        float kNext_8 = kNext_7;
        float2  goNext_7 = goNext_6;
        float2  gkNext_8 = gkNext_7;
        int i_7 = int(-1);
        for(;;)
        {
            if(i_7 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_5 = _S64 + make_int2 (i_7, j_5);
            float _S66 = convVigour_0(c_8, slot_5);
            if(_S66 <= 0.0f)
            {
                i_7 = i_7 + int(1);
                continue;
            }
            float2  d_3 = _S62 - convCellCentrePlain_0(slot_5);
            float d2_4 = dot_1(d_3, d_3);
            float ko_2 = _S66 * convBump_0(d2_4, 0.75f);
            float kk_2 = _S66 * convBump_0(d2_4, 1.04999995231628418f);
            float2  gko_2;
            if(d2_4 < 0.5625f)
            {
                gko_2 = d_3 * make_float2 (-4.0f * _S66 * (1.0f - d2_4 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_2 = _S65;
            }
            float2  gkk_2;
            if(d2_4 < 1.10249984264373779f)
            {
                gkk_2 = d_3 * make_float2 (-4.0f * _S66 * (1.0f - d2_4 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_2 = _S65;
            }
            float oTop_8;
            float oNext_8;
            float2  goTop_8;
            float2  goNext_8;
            if(ko_2 > oTop_7)
            {
                oTop_8 = ko_2;
                goTop_8 = gko_2;
                oNext_8 = oTop_7;
                goNext_8 = goTop_6;
            }
            else
            {
                if(ko_2 > oNext_7)
                {
                    oTop_8 = ko_2;
                    goTop_8 = gko_2;
                }
                else
                {
                    oTop_8 = oNext_7;
                    goTop_8 = goNext_7;
                }
                float _S67 = oTop_8;
                float2  _S68 = goTop_8;
                oTop_8 = oTop_7;
                goTop_8 = goTop_6;
                oNext_8 = _S67;
                goNext_8 = _S68;
            }
            float kTop_9;
            float kNext_9;
            float2  gkTop_9;
            float2  gkNext_9;
            if(kk_2 > kTop_8)
            {
                kTop_9 = kk_2;
                gkTop_9 = gkk_2;
                kNext_9 = kTop_8;
                gkNext_9 = gkTop_8;
            }
            else
            {
                if(kk_2 > kNext_8)
                {
                    kTop_9 = kk_2;
                    gkTop_9 = gkk_2;
                }
                else
                {
                    kTop_9 = kNext_8;
                    gkTop_9 = gkNext_8;
                }
                float _S69 = kTop_9;
                float2  _S70 = gkTop_9;
                kTop_9 = kTop_8;
                gkTop_9 = gkTop_8;
                kNext_9 = _S69;
                gkNext_9 = _S70;
            }
            oTop_7 = oTop_8;
            goTop_6 = goTop_8;
            oNext_7 = oNext_8;
            kTop_8 = kTop_9;
            gkTop_8 = gkTop_9;
            kNext_8 = kNext_9;
            goNext_7 = goNext_8;
            gkNext_8 = gkNext_9;
            i_7 = i_7 + int(1);
        }
        int j_6 = j_5 + int(1);
        oTop_6 = oTop_7;
        goTop_7 = goTop_6;
        oNext_6 = oNext_7;
        kTop_7 = kTop_8;
        gkTop_7 = gkTop_8;
        kNext_7 = kNext_8;
        goNext_6 = goNext_7;
        gkNext_7 = gkNext_8;
        j_5 = j_6;
    }
    float openRaw_2 = oNext_6 / 0.31000000238418579f;
    float _S71 = (F32_min((openRaw_2), (1.0f)));
    float closedField_2 = kTop_7 - kNext_7;
    if(openRaw_2 < 1.0f)
    {
        goTop_6 = goNext_6 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_6 = _S65;
    }
    float2  gClosed_2 = gkTop_7 - gkNext_7;
    float _S72 = c_8->cvPolarity_0;
    *grad_4 = lerp_3(goTop_6, gClosed_2, make_float2 (c_8->cvPolarity_0)) / make_float2 (_S61);
    return lerp_2(_S71, closedField_2, _S72);
}

static __device__ float smoothstep_0(float min_2, float max_1, float x_15)
{
    float _S73 = saturate_0((x_15 - min_2) / (max_1 - min_2));
    return _S73 * _S73 * (3.0f - (_S73 + _S73));
}

static __device__ float length_1(float2  x_16)
{
    return (F32_sqrt((dot_1(x_16, x_16))));
}

static __device__ bool any_0(bool2  x_17)
{
    bool result_5 = false;
    int i_8 = int(0);
    for(;;)
    {
        if(i_8 < int(2))
        {
        }
        else
        {
            break;
        }
        if(result_5)
        {
            result_5 = true;
        }
        else
        {
            result_5 = (bool((_slang_vector_get_element(x_17, i_8))));
        }
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static __device__ int clamp_2(int x_18, int minBound_2, int maxBound_2)
{
    return (I32_min(((I32_max((x_18), (minBound_2)))), (maxBound_2)));
}

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S74 = __ldg(&(ptr_0->x));
    float _S75 = __ldg(&(ptr_0->y));
    float _S76 = __ldg(&(ptr_0->z));
    return make_float3 (_S74, _S75, _S76);
}

struct LayerShadowMap_0
{
    StructuredBuffer<float> smTexels_0;
    float3  smSun_0;
    float2  smCentre_0;
    float2  smAxisU_0;
    float2  smLo_0;
    float2  smTexel_0;
    int smDimU_0;
    int smDimV_0;
    int smSlices_0;
    float smBottom_0;
    float smTop_0;
    float smStep_0;
};

static __device__ float2  airMapAxisV_0(LayerShadowMap_0 * m_0)
{
    return make_float2 (- m_0->smAxisU_0.y, m_0->smAxisU_0.x);
}

static __device__ bool clipAxis_0(float o_5, float d_4, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_4))) < 9.99999971718068537e-10f)
    {
        bool _S77;
        if(o_5 >= lo_0)
        {
            _S77 = o_5 <= hi_0;
        }
        else
        {
            _S77 = false;
        }
        return _S77;
    }
    float ta_0 = (lo_0 - o_5) / d_4;
    float tb_0 = (hi_0 - o_5) / d_4;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S78 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S78;
    return _S78 > (*t0_0);
}

struct GeneratorInput_0
{
    float cellAltitude_0;
    float streakLength_0;
    float cellSize_0;
    float cellDensity_0;
    float cellStrength_0;
    float2  cellDrift_0;
    float sublimation_0;
    float fallSpeed_0;
    float detailScale_0;
    float detailAmount_0;
    float opticalDepth_0;
    float timeSeconds_0;
    int octaves_0;
    Organization_0 gnOrg_0;
};

struct Medium_0
{
    float slabTop_0;
    float slabBottom_0;
    float majorant_0;
    float density_0;
    float3  coreCentre_0;
    float coreRadius_0;
    float coreDensity_0;
    GeneratorInput_0 gen_0;
    ConvectionInput_0 conv_0;
    int mode_0;
    int clipOn_0;
    float2  clipLo_0;
    float2  clipHi_0;
    float2  fadeAt_0;
    float fadeRadius_0;
    float fadeWidth_0;
};

static __device__ bool slabRange_0(Medium_0 * m_1, float3  ro_0, float3  rd_0, float * t0_1, float * t1_1)
{
    *t0_1 = 0.0f;
    *t1_1 = 1.0e+09f;
    float _S79 = rd_0.y;
    bool _S80;
    if((F32_abs((_S79))) < 9.99999997475242708e-07f)
    {
        float _S81 = ro_0.y;
        if(_S81 < (m_1->slabBottom_0))
        {
            _S80 = true;
        }
        else
        {
            _S80 = _S81 > (m_1->slabTop_0);
        }
        if(_S80)
        {
            return false;
        }
    }
    else
    {
        float _S82 = ro_0.y;
        float ta_1 = (m_1->slabBottom_0 - _S82) / _S79;
        float tb_1 = (m_1->slabTop_0 - _S82) / _S79;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S83 = (m_1->clipOn_0) != int(0);
    float2  lo_1;
    if(_S83)
    {
        lo_1 = m_1->clipLo_0;
    }
    else
    {
        lo_1 = make_float2 (-1.0e+09f, -1.0e+09f);
    }
    float2  hi_1;
    if(_S83)
    {
        hi_1 = m_1->clipHi_0;
    }
    else
    {
        hi_1 = make_float2 (1.0e+09f, 1.0e+09f);
    }
    float _S84 = m_1->fadeRadius_0;
    if((m_1->fadeRadius_0) > 0.0f)
    {
        float2  _S85 = min_1(hi_1, m_1->fadeAt_0 + make_float2 (_S84));
        lo_1 = max_0(lo_1, m_1->fadeAt_0 - make_float2 (_S84));
        hi_1 = _S85;
    }
    bool _S86 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S86)
    {
        return false;
    }
    bool _S87 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S87)
    {
        return false;
    }
    float _S88 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S88;
    if(_S88 > (*t0_1))
    {
        _S80 = (*t1_1) > 0.0f;
    }
    else
    {
        _S80 = false;
    }
    return _S80;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_3, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_19 = clamp_1(depth_0 / g_3->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_9 = clamp_2(int((F32_floor((x_19)))), int(0), int(31));
    float2  _S89 = __ldg((&(disp_0)[i_9]));
    float2  _S90 = __ldg((&(disp_0)[i_9 + int(1)]));
    return lerp_3(_S89, _S90, make_float2 (x_19 - float(i_9)));
}

static __device__ float orgWaveFactor_0(Organization_0 * o_6, float2  q_6)
{
    float2  unused_0;
    float _S91 = orgWave_0(o_6, q_6, &unused_0);
    return _S91;
}

static __device__ float cellField_0(GeneratorInput_0 * g_4, float2  q_7)
{
    float2  _S92 = q_7 - g_4->cellDrift_0;
    float2  _S93 = orgPattern_0(&g_4->gnOrg_0, _S92, g_4->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(_S93);
    int2  _S94 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    float2  _S95 = orgJitter_0(&g_4->gnOrg_0, 0.80000001192092896f);
    int j_7 = int(-1);
    float acc_0 = 0.0f;
    for(;;)
    {
        if(j_7 <= int(1))
        {
        }
        else
        {
            break;
        }
        int i_10 = int(-1);
        float acc_1 = acc_0;
        for(;;)
        {
            if(i_10 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_7 = _S94 + make_int2 (i_10, j_7);
            if((hash22_0(o_7, 2654435769U).x) > (g_4->cellDensity_0))
            {
                i_10 = i_10 + int(1);
                continue;
            }
            float2  _S96 = make_float2 ((float)o_7.x, (float)o_7.y);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(_S93 - (_S96 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S95)) * 2.20000004768371582f);
            i_10 = i_10 + int(1);
        }
        j_7 = j_7 + int(1);
        acc_0 = acc_1;
    }
    float _S97 = acc_0 * g_4->cellStrength_0;
    float _S98 = orgWaveFactor_0(&g_4->gnOrg_0, _S92);
    return _S97 * _S98;
}

static __device__ float fbm_0(float3  p_1, int octaves_1)
{
    int i_11 = int(0);
    float amp_0 = 0.5f;
    float3  _S99 = p_1;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_11 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_11 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S99);
        float norm_1 = norm_0 + amp_0;
        float3  _S100 = _S99 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_11 = i_11 + int(1);
        amp_0 = amp_1;
        _S99 = _S100;
        sum_0 = sum_1;
        norm_0 = norm_1;
    }
    if(norm_0 > 0.0f)
    {
        amp_0 = sum_0 / norm_0;
    }
    else
    {
        amp_0 = 0.0f;
    }
    return amp_0;
}

static __device__ float iceDensity_0(GeneratorInput_0 * g_5, StructuredBuffer<float2 > disp_1, float3  p_2)
{
    float depth_1 = g_5->cellAltitude_0 - p_2.y;
    bool _S101;
    if(depth_1 < 0.0f)
    {
        _S101 = true;
    }
    else
    {
        _S101 = depth_1 > (g_5->streakLength_0);
    }
    if(_S101)
    {
        return 0.0f;
    }
    float2  _S102 = float2 {p_2.x, p_2.z};
    float2  _S103 = driftAt_0(g_5, disp_1, depth_1);
    float2  source_0 = _S102 - _S103;
    float _S104 = cellField_0(g_5, source_0);
    if(_S104 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S104 * (F32_exp((- g_5->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_5->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_5->streakLength_0, g_5->streakLength_0, depth_1)) * (F32_max((1.0f + g_5->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_5->detailScale_0)).x, (source_0 / make_float2 (g_5->detailScale_0)).y, depth_1 / (F32_max((g_5->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_5->timeSeconds_0 * 0.00999999977648258f), g_5->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_5->opticalDepth_0 / (F32_max((g_5->streakLength_0), (1.0f)));
}

static __device__ float convCapCeiling_0(ConvectionInput_0 * c_9)
{
    float _S105 = c_9->cvHeroTop_0;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        return 0.0f;
    }
    float _S106 = c_9->cvPileusThick_0;
    float cap_0;
    if((c_9->cvPileusThick_0) > 0.0f)
    {
        cap_0 = _S105 + c_9->cvPileusGap_0 + _S106;
    }
    else
    {
        cap_0 = 0.0f;
    }
    float _S107 = c_9->cvVelumThick_0;
    float veil_0;
    if((c_9->cvVelumThick_0) > 0.0f)
    {
        veil_0 = c_9->cvVelumHeight_0 + 1.5f * _S107;
    }
    else
    {
        veil_0 = 0.0f;
    }
    return (F32_max((cap_0), (veil_0)));
}

static __device__ float convCeiling_0(ConvectionInput_0 * c_10)
{
    float _S108 = c_10->cvBillow_0;
    float field_0 = c_10->cvDepth_0 + c_10->cvBillow_0;
    float _S109 = c_10->cvHeroTop_0;
    float hero_0;
    if((c_10->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S109 + _S108 * c_10->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    float _S110 = (F32_max((field_0), (hero_0)));
    float _S111 = convCapCeiling_0(c_10);
    return (F32_max((_S110), (_S111)));
}

static __device__ float convPouches_0(ConvectionInput_0 * c_11, float2  q_8)
{
    float2  g_6 = q_8 / make_float2 (c_11->cvPouchSize_0);
    float2  _S112 = floor_1(g_6);
    int2  _S113 = make_int2 ((int)_S112.x, (int)_S112.y);
    float deepest_0 = 0.0f;
    int j_8 = int(-1);
    for(;;)
    {
        if(j_8 <= int(1))
        {
        }
        else
        {
            break;
        }
        float deepest_1 = deepest_0;
        int i_12 = int(-1);
        for(;;)
        {
            if(i_12 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_6 = _S113 + make_int2 (i_12, j_8);
            float2  _S114 = make_float2 ((float)slot_6.x, (float)slot_6.y);
            float2  d_5 = g_6 - (_S114 + make_float2 (0.5f) + (hash22_0(slot_6, 739982445U) - make_float2 (0.5f)) * make_float2 (0.60000002384185791f));
            float t2_0 = dot_1(d_5, d_5) / 0.46240001916885376f;
            if(t2_0 >= 1.0f)
            {
                i_12 = i_12 + int(1);
                continue;
            }
            float2  h_3 = hash22_0(slot_6, 2135587861U);
            deepest_1 = (F32_max((deepest_1), (lerp_2(0.30000001192092896f, 1.0f, convLife_0((F32_frac((2.0f * c_11->cvAge_0 + h_3.x))))) * lerp_2(0.60000002384185791f, 1.0f, h_3.y) * (F32_sqrt((1.0f - t2_0))))));
            i_12 = i_12 + int(1);
        }
        int j_9 = j_8 + int(1);
        deepest_0 = deepest_1;
        j_8 = j_9;
    }
    return deepest_0;
}

static __device__ void convMoatRing_0(float2  xz_0, float2  at_0, float radius_0, float * s_8, float2  * gs_0, float * slope_0)
{
    float2  d_6 = xz_0 - at_0;
    float r2_1 = dot_1(d_6, d_6);
    float outer_0 = 1.29999995231628418f * radius_0;
    if(!(r2_1 < (outer_0 * outer_0)))
    {
        return;
    }
    float band_1 = outer_0 - 0.75f * radius_0;
    float inner_1 = outer_0 - band_1;
    *slope_0 = (F32_max((*slope_0), (1.5f / band_1)));
    float r_1 = (F32_sqrt((r2_1)));
    float t_3 = saturate_0((r_1 - inner_1) / band_1);
    float f_1 = t_3 * t_3 * (3.0f - 2.0f * t_3);
    if(f_1 < (*s_8))
    {
        *s_8 = f_1;
        float2  _S115;
        if(r_1 > 0.00100000004749745f)
        {
            _S115 = d_6 * make_float2 (6.0f * t_3 * (1.0f - t_3) / (band_1 * r_1));
        }
        else
        {
            _S115 = make_float2 (0.0f, 0.0f);
        }
        *gs_0 = _S115;
    }
    return;
}

static __device__ float4  convTurret_0(ConvectionInput_0 * c_12, int k_1)
{
    if(k_1 == int(0))
    {
        return c_12->cvTurret0_0;
    }
    if(k_1 == int(1))
    {
        return c_12->cvTurret1_0;
    }
    if(k_1 == int(2))
    {
        return c_12->cvTurret2_0;
    }
    if(k_1 == int(3))
    {
        return c_12->cvTurret3_0;
    }
    return c_12->cvTurret4_0;
}

static __device__ float convMoat_0(ConvectionInput_0 * c_13, float2  xz_1, float2  * grad_5, float * slopeAdd_0)
{
    float s_9 = 1.0f;
    float2  gs_1 = make_float2 (0.0f, 0.0f);
    float slope_1 = 0.0f;
    convMoatRing_0(xz_1, c_13->cvHeroAt_0, c_13->cvHeroRadius_0, &s_9, &gs_1, &slope_1);
    int k_2 = int(0);
    for(;;)
    {
        if(k_2 < int(5))
        {
        }
        else
        {
            break;
        }
        if(k_2 >= (c_13->cvTurretCount_0))
        {
            break;
        }
        float4  _S116 = convTurret_0(c_13, k_2);
        convMoatRing_0(xz_1, float2 {_S116.x, _S116.y}, _S116.z, &s_9, &gs_1, &slope_1);
        k_2 = k_2 + int(1);
    }
    float _S117 = c_13->cvMoat_0;
    *grad_5 = gs_1 * make_float2 (c_13->cvMoat_0);
    *slopeAdd_0 = slope_1 * _S117;
    return 1.0f - _S117 * (1.0f - s_9);
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_14, float2  q_9, float2  * grad_6)
{
    if(((&c_14->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S118 = convUpdraftGradT_2(c_14, q_9, grad_6);
        return _S118;
    }
    if((c_14->cvLacunarity_0) <= 0.0f)
    {
        float _S119 = convUpdraftGradT_1(c_14, q_9, grad_6);
        return _S119;
    }
    float _S120 = convUpdraftGradT_0(c_14, q_9, grad_6);
    return _S120;
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_15)
{
    float _S121 = c_15->cvSpacing_0;
    float cap_1 = 7.0f / c_15->cvSpacing_0;
    if(((&c_15->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_1;
    }
    float _S122 = c_15->cvLacunarity_0;
    float cap_2;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        cap_2 = cap_1 + 1.5f / (0.15000000596046448f * _S122 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S121);
    }
    else
    {
        cap_2 = cap_1;
    }
    float _S123 = c_15->cvGapWidth_0;
    if((c_15->cvGapWidth_0) > 0.0f)
    {
        cap_2 = cap_2 + 14.25f * c_15->cvPolarity_0 / (0.5f * _S123 * _S121);
    }
    return cap_2 + 3.0f * (&c_15->cvOrg_0)->ogWaveAmp_0 * length_1((&c_15->cvOrg_0)->ogWaveK_0);
}

static __device__ float convTowerHeight_0(ConvectionInput_0 * c_16, float w_1)
{
    float cover_0 = clamp_1(c_16->cvCoverage_0, 0.0f, 1.0f);
    if(cover_0 <= 0.0f)
    {
        return 0.0f;
    }
    float span_0 = (F32_sqrt((cover_0)));
    float u_2 = saturate_0((w_1 - (1.0f - span_0)) / span_0);
    if(u_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_16->cvDepth_0 * (F32_pow((u_2), (c_16->cvShape_0)));
}

static __device__ float convNeededUpdraft_0(ConvectionInput_0 * c_17, float above_0)
{
    float cover_1 = clamp_1(c_17->cvCoverage_0, 0.0f, 1.0f);
    bool _S124;
    if(cover_1 <= 0.0f)
    {
        _S124 = true;
    }
    else
    {
        _S124 = (c_17->cvDepth_0) <= 0.0f;
    }
    if(_S124)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_0), (0.0f))) / c_17->cvDepth_0), (1.0f / (F32_max((c_17->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSurfaceDistance_0(float v_2, float delta_0, float slope_2)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_2 * slope_2 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_7 = num_0 / den_0;
    float _S125;
    if(v_2 >= 0.0f)
    {
        _S125 = d_7;
    }
    else
    {
        _S125 = - d_7;
    }
    return _S125;
}

static __device__ float convFieldBaseInside_0(ConvectionInput_0 * c_18, float w_2, float2  slope_3, float cap_3)
{
    float _S126 = convTowerHeight_0(c_18, w_2);
    float v_3 = _S126 - 1.0f;
    float _S127 = convNeededUpdraft_0(c_18, 1.0f);
    return convSurfaceDistance_0(v_3, w_2 - _S127, (F32_min((length_1(slope_3)), (cap_3))));
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_19)
{
    return c_19->cvHeroRadius_0 + 1.5f * c_19->cvBillow_0 * c_19->cvHeroBillow_0 + 24.0f;
}

static __device__ float convShapeReach_0(ConvectionInput_0 * c_20)
{
    float lift_0 = 1.5f * c_20->cvBillow_0 * c_20->cvHeroBillow_0 + 24.0f;
    return length_1(make_float2 (c_20->cvShapeHalfWidth_0 + lift_0, c_20->cvShapeRound_0 + c_20->cvReliefHeight_0 + lift_0));
}

static __device__ float convHeroReachAll_0(ConvectionInput_0 * c_21)
{
    float _S128 = convHeroReach_0(c_21);
    float _S129;
    if((c_21->cvShapeOn_0) != int(0))
    {
        float _S130 = convShapeReach_0(c_21);
        _S129 = (F32_max((_S128), (_S130)));
    }
    else
    {
        _S129 = _S128;
    }
    return _S129;
}

static __device__ float convDomeHeight_0(float top_0, float radius_1, float shape_0, float r_2)
{
    bool _S131;
    if(top_0 <= 0.0f)
    {
        _S131 = true;
    }
    else
    {
        _S131 = r_2 >= radius_1;
    }
    if(_S131)
    {
        return 0.0f;
    }
    return top_0 * (F32_pow((1.0f - r_2 * r_2 / (radius_1 * radius_1)), (shape_0)));
}

static __device__ float convDomeRadiusAt_0(float top_1, float radius_2, float shape_1, float above_1)
{
    bool _S132;
    if(top_1 <= 0.0f)
    {
        _S132 = true;
    }
    else
    {
        _S132 = above_1 >= top_1;
    }
    if(_S132)
    {
        return -1.0f;
    }
    return radius_2 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_1), (0.0f))) / top_1), (1.0f / (F32_max((shape_1), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convDomeSurface_0(float top_2, float radius_3, float shape_2, float2  rel_0, float r_3, float py_0, float above_2, float3  * x_20)
{
    float v_4 = convDomeHeight_0(top_2, radius_3, shape_2, r_3) - above_2;
    float ra_0 = convDomeRadiusAt_0(top_2, radius_3, shape_2, above_2);
    float shiftOut_0;
    float shiftUp_0;
    float d_8;
    if(ra_0 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_4;
        d_8 = v_4;
    }
    else
    {
        float h_4 = ra_0 - r_3;
        float d_9 = convSurfaceDistance_0(v_4, h_4, 1.0f);
        if((F32_abs((v_4))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_9 * (d_9 / v_4);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_4))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_9 * (d_9 / h_4);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S133 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S133;
        d_8 = d_9;
    }
    float2  radial_0;
    if(r_3 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / make_float2 (r_3);
    }
    else
    {
        radial_0 = make_float2 (0.0f, 0.0f);
    }
    float2  at_1 = rel_0 + radial_0 * make_float2 (shiftOut_0);
    *x_20 = make_float3 (at_1.x, py_0 + shiftUp_0, at_1.y);
    return d_8;
}

static __device__ float convTowerSurface_0(ConvectionInput_0 * c_22, float2  rel_1, float r_4, float py_1, float above_3, float3  * x_21)
{
    float _S134 = convDomeSurface_0(c_22->cvHeroTop_0, c_22->cvHeroRadius_0, c_22->cvShape_0, rel_1, r_4, py_1, above_3, x_21);
    return _S134;
}

static __device__ float4  convShapeTexel_0(ConvectionInput_0 * c_23, int i_13, int j_10)
{
    int k_3 = (j_10 * c_23->cvShapeDim_0.x + i_13) * int(4);
    StructuredBuffer<float> _S135 = c_23->cvShapeMap_0;
    float _S136 = __ldg((&(c_23->cvShapeMap_0)[k_3]));
    float _S137 = __ldg((&(_S135)[k_3 + int(1)]));
    float _S138 = __ldg((&(_S135)[k_3 + int(2)]));
    float _S139 = __ldg((&(_S135)[k_3 + int(3)]));
    return make_float4 (_S136, _S137, _S138, _S139);
}

static __device__ float convShapeDistance_0(ConvectionInput_0 * c_24, float u_3, float y_9, float2  * slopeUY_0, float * relief_0)
{
    float _S140 = c_24->cvShapeTexel_0;
    float2  st_0 = make_float2 (u_3, y_9) / make_float2 (c_24->cvShapeTexel_0) + c_24->cvShapeOffset_0 - make_float2 (0.5f);
    int2  _S141 = make_int2 (int(1), int(1));
    int2  last_0 = c_24->cvShapeDim_0 - _S141;
    float2  _S142 = make_float2 ((float)last_0.x, (float)last_0.y);
    float2  q_10 = clamp_0(st_0, make_float2 (0.0f, 0.0f), _S142);
    float past_0 = length_1(st_0 - q_10);
    float2  f0_0 = floor_1(q_10);
    int2  _S143 = make_int2 ((int)f0_0.x, (int)f0_0.y);
    int2  i0_0 = min_0(_S143, last_0);
    int2  i1_0 = min_0(i0_0 + _S141, last_0);
    float2  fr_0 = q_10 - f0_0;
    int _S144 = i0_0.x;
    int _S145 = i0_0.y;
    float4  _S146 = convShapeTexel_0(c_24, _S144, _S145);
    int _S147 = i1_0.x;
    float4  _S148 = convShapeTexel_0(c_24, _S147, _S145);
    int _S149 = i1_0.y;
    float4  _S150 = convShapeTexel_0(c_24, _S144, _S149);
    float4  _S151 = convShapeTexel_0(c_24, _S147, _S149);
    float4  _S152 = make_float4 (fr_0.x);
    float4  blend_0 = lerp_1(lerp_1(_S146, _S148, _S152), lerp_1(_S150, _S151, _S152), make_float4 (fr_0.y));
    *slopeUY_0 = float2 {blend_0.y, blend_0.z};
    *relief_0 = blend_0.w;
    return (blend_0.x - past_0) * _S140;
}

static __device__ float convReliefLift_0(ConvectionInput_0 * c_25, float dIn_0, float relief_1)
{
    return c_25->cvReliefHeight_0 * relief_1 * smoothstep_0(0.0f, (F32_max((c_25->cvReliefFade_0), (1.0f))), dIn_0);
}

static __device__ float convShapeProfile_0(float dIn_1, float m_2, float rimR_0, float2  * stepDM_0)
{
    if(dIn_1 >= rimR_0)
    {
        *stepDM_0 = make_float2 (0.0f, rimR_0 - m_2);
        return m_2 - rimR_0;
    }
    float2  w_3 = make_float2 (dIn_1 - rimR_0, m_2);
    float len_0 = length_1(w_3);
    float gap_0 = len_0 - rimR_0;
    float2  _S153;
    if(len_0 > 9.99999997475242708e-07f)
    {
        _S153 = w_3 * make_float2 (- gap_0 / len_0);
    }
    else
    {
        _S153 = make_float2 (0.0f, rimR_0);
    }
    *stepDM_0 = _S153;
    return gap_0;
}

static __device__ float convShapeSurface_0(ConvectionInput_0 * c_26, float2  plane_0, float py_2, float above_4, float3  * x_22)
{
    float _S154 = plane_0.x;
    float2  slopeUY_1;
    float relief_2;
    float _S155 = convShapeDistance_0(c_26, _S154, above_4, &slopeUY_1, &relief_2);
    float _S156 = plane_0.y;
    float _S157 = (F32_abs((_S156)));
    bool _S158;
    if((c_26->cvReliefHeight_0) > 0.0f)
    {
        _S158 = _S156 > 0.0f;
    }
    else
    {
        _S158 = false;
    }
    float m_3;
    if(_S158)
    {
        float _S159 = convReliefLift_0(c_26, _S155, relief_2);
        m_3 = (F32_max((_S156 - _S159), (0.0f)));
    }
    else
    {
        m_3 = _S157;
    }
    float2  stepDM_1;
    float gap_1 = convShapeProfile_0(_S155, m_3, c_26->cvShapeRound_0, &stepDM_1);
    float side_0;
    if(_S156 >= 0.0f)
    {
        side_0 = 1.0f;
    }
    else
    {
        side_0 = -1.0f;
    }
    *x_22 = make_float3 (_S154 + stepDM_1.x * slopeUY_1.x, py_2 + stepDM_1.x * slopeUY_1.y, _S156 + side_0 * stepDM_1.y);
    return - gap_1;
}

static __device__ bool convHeroSmooth_0(ConvectionInput_0 * c_27, float3  p_3, float above_5, float * d_10, float3  * x_23, float * amount_0, float * lobe_0)
{
    *d_10 = -1.00000001504746622e+30f;
    *x_23 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S160 = c_27->cvHeroBillow_0;
    *amount_0 = c_27->cvHeroBillow_0;
    *lobe_0 = _S160;
    float2  rel_2 = float2 {p_3.x, p_3.z} - c_27->cvHeroAt_0;
    float r_5 = length_1(rel_2);
    float _S161 = convHeroReachAll_0(c_27);
    if(r_5 >= _S161)
    {
        return false;
    }
    if((c_27->cvShapeOn_0) == int(0))
    {
        float _S162 = convTowerSurface_0(c_27, rel_2, r_5, p_3.y, above_5, x_23);
        *d_10 = _S162;
    }
    else
    {
        float2  plane_1 = make_float2 (dot_1(rel_2, c_27->cvShapeAxisU_0), dot_1(rel_2, make_float2 (- c_27->cvShapeAxisU_0.y, c_27->cvShapeAxisU_0.x)));
        float _S163 = c_27->cvShapeDecay_0;
        if((c_27->cvShapeDecay_0) >= 1.0f)
        {
            float _S164 = convTowerSurface_0(c_27, plane_1, r_5, p_3.y, above_5, x_23);
            *d_10 = _S164;
        }
        else
        {
            float _S165 = p_3.y;
            float3  xs_0;
            float _S166 = convShapeSurface_0(c_27, plane_1, _S165, above_5, &xs_0);
            if(_S163 > 0.0f)
            {
                float3  xt_0;
                float _S167 = convTowerSurface_0(c_27, plane_1, r_5, _S165, above_5, &xt_0);
                *d_10 = lerp_2(_S166, _S167, _S163);
                *x_23 = lerp_0(xs_0, xt_0, make_float3 (_S163));
            }
            else
            {
                *d_10 = _S166;
                *x_23 = xs_0;
            }
            float _S168 = c_27->cvShapeBillow_0;
            *amount_0 = _S160 * lerp_2(c_27->cvShapeBillow_0, 1.0f, _S163);
            *lobe_0 = _S160 * lerp_2((F32_max((_S168), (0.30000001192092896f))), 1.0f, _S163);
        }
    }
    return true;
}

static __device__ float convTurretReach_0(ConvectionInput_0 * c_28, float4  t_4)
{
    return t_4.z + 1.5f * c_28->cvBillow_0 * c_28->cvHeroBillow_0 + 24.0f;
}

static __device__ float convTurretBillow_0(ConvectionInput_0 * c_29, float radius_4)
{
    return lerp_2((F32_min((1.0f), (c_29->cvHeroBillow_0))), c_29->cvHeroBillow_0, saturate_0(radius_4 / (F32_max((c_29->cvHeroRadius_0), (1.0f)))));
}

static __device__ bool convTurretSmooth_0(ConvectionInput_0 * c_30, float4  t_5, float3  p_4, float above_6, float * d_11, float3  * x_24, float * k_4)
{
    *d_11 = -1.00000001504746622e+30f;
    *x_24 = make_float3 (0.0f, 0.0f, 0.0f);
    *k_4 = 1.0f;
    float2  rel_3 = float2 {p_4.x, p_4.z} - float2 {t_5.x, t_5.y};
    float r2_2 = dot_1(rel_3, rel_3);
    float _S169 = convTurretReach_0(c_30, t_5);
    if(r2_2 >= (_S169 * _S169))
    {
        return false;
    }
    float _S170 = t_5.w;
    if(above_6 >= (_S170 + c_30->cvBillow_0 * c_30->cvHeroBillow_0))
    {
        return false;
    }
    float r_6 = (F32_sqrt((r2_2)));
    float _S171 = t_5.z;
    float _S172 = convTurretBillow_0(c_30, _S171);
    *k_4 = _S172;
    float3  own_0;
    float _S173 = convDomeSurface_0(_S170, _S171, c_30->cvShape_0, rel_3, r_6, p_4.y, above_6, &own_0);
    *d_11 = _S173;
    float3  w_4 = own_0 + make_float3 (t_5.x - c_30->cvHeroAt_0.x, 0.0f, t_5.y - c_30->cvHeroAt_0.y);
    float3  w_5;
    if((c_30->cvShapeOn_0) != int(0))
    {
        float2  _S174 = float2 {w_4.x, w_4.z};
        w_5 = make_float3 (dot_1(_S174, c_30->cvShapeAxisU_0), w_4.y, dot_1(_S174, make_float2 (- c_30->cvShapeAxisU_0.y, c_30->cvShapeAxisU_0.x)));
    }
    else
    {
        w_5 = w_4;
    }
    *x_24 = w_5;
    return true;
}

static __device__ float convGroupBaseInside_0(ConvectionInput_0 * c_31, float2  xz_2, bool nearGroup_0)
{
    float best_0;
    if((c_31->cvHeroTop_0) > 0.0f)
    {
        float3  p_5 = make_float3 (xz_2.x, c_31->cvBase_0 + 1.0f, xz_2.y);
        float d_12;
        float amount_1;
        float lobe_1;
        float3  x_25;
        bool _S175 = convHeroSmooth_0(c_31, p_5, 1.0f, &d_12, &x_25, &amount_1, &lobe_1);
        if(_S175)
        {
            best_0 = (F32_max((-1.00000001504746622e+30f), (d_12)));
        }
        else
        {
            best_0 = -1.00000001504746622e+30f;
        }
        int k_5 = int(0);
        for(;;)
        {
            if(k_5 < int(5))
            {
            }
            else
            {
                break;
            }
            bool _S176;
            if(!nearGroup_0)
            {
                _S176 = true;
            }
            else
            {
                _S176 = k_5 >= (c_31->cvTurretCount_0);
            }
            if(_S176)
            {
                break;
            }
            float4  _S177 = convTurret_0(c_31, k_5);
            float kt_0;
            bool _S178 = convTurretSmooth_0(c_31, _S177, p_5, 1.0f, &d_12, &x_25, &kt_0);
            if(_S178)
            {
                best_0 = (F32_max((best_0), (d_12)));
            }
            k_5 = k_5 + int(1);
        }
    }
    else
    {
        best_0 = -1.00000001504746622e+30f;
    }
    return best_0;
}

static __device__ float convBaseInside_0(ConvectionInput_0 * c_32, float2  xz_3, bool nearGroup_1)
{
    float best_1;
    if((c_32->cvHeroAlone_0) == int(0))
    {
        float capMoat_0 = 0.0f;
        float2  gMoat_0 = make_float2 (0.0f, 0.0f);
        bool moated_0;
        if((c_32->cvMoat_0) > 0.0f)
        {
            moated_0 = nearGroup_1;
        }
        else
        {
            moated_0 = false;
        }
        float m_4;
        if(moated_0)
        {
            float _S179 = convMoat_0(c_32, xz_3, &gMoat_0, &capMoat_0);
            m_4 = _S179;
        }
        else
        {
            m_4 = 1.0f;
        }
        if(m_4 > 0.0f)
        {
            float2  slope_4;
            float _S180 = convUpdraftGrad_0(c_32, xz_3 - c_32->cvDrift_0, &slope_4);
            float _S181 = convSlopeCap_0(c_32);
            float cap_4;
            if(moated_0)
            {
                slope_4 = slope_4 * make_float2 (m_4) + gMoat_0 * make_float2 (_S180);
                float cap_5 = _S181 + capMoat_0;
                best_1 = _S180 * m_4;
                cap_4 = cap_5;
            }
            else
            {
                best_1 = _S180;
                cap_4 = _S181;
            }
            float _S182 = convFieldBaseInside_0(c_32, best_1, slope_4, cap_4);
            best_1 = _S182;
        }
        else
        {
            best_1 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        best_1 = -1.00000001504746622e+30f;
    }
    float _S183 = convGroupBaseInside_0(c_32, xz_3, nearGroup_1);
    return (F32_max((best_1), (_S183)));
}

static __device__ float convMammaSagOf_0(ConvectionInput_0 * c_33, float pouch_0, float inside_0)
{
    if(inside_0 <= 0.0f)
    {
        return 0.0f;
    }
    return c_33->cvMammaDepth_0 * pouch_0 * smoothstep_0(0.0f, 0.60000002384185791f * c_33->cvPouchSize_0, inside_0);
}

static __device__ float convMammaSag_0(ConvectionInput_0 * c_34, float2  xz_4, bool nearGroup_2, float below_0)
{
    float _S184 = convPouches_0(c_34, xz_4 - c_34->cvDrift_0);
    if((c_34->cvMammaDepth_0 * _S184) <= below_0)
    {
        return 0.0f;
    }
    float _S185 = convBaseInside_0(c_34, xz_4, nearGroup_2);
    float _S186 = convMammaSagOf_0(c_34, _S184, _S185);
    return _S186;
}

static __device__ float convLift_0(ConvectionInput_0 * c_35, float above_7, float k_6)
{
    return (F32_min((c_35->cvBillow_0 * k_6 * smoothstep_0(0.0f, 150.0f, above_7) * lerp_2(0.60000002384185791f, 1.0f, saturate_0(above_7 / (F32_max((c_35->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_7), (0.0f))))));
}

static __device__ float3  convTwist_0(float3  x_26)
{
    float _S187 = x_26.x;
    float _S188 = x_26.y;
    float _S189 = x_26.z;
    return make_float3 (0.0f * _S187 + 0.80000001192092896f * _S188 + 0.60000002384185791f * _S189, -0.80000001192092896f * _S187 + 0.36000001430511475f * _S188 - 0.47999998927116394f * _S189, -0.60000002384185791f * _S187 - 0.47999998927116394f * _S188 + 0.63999998569488525f * _S189);
}

static __device__ float convPuffs_0(float3  x_27)
{
    float3  fl_0 = floor_0(x_27);
    int3  _S190 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_2 = x_27 - fl_0;
    int dz_0;
    if((f_2.x) < 0.5f)
    {
        dz_0 = int(-1);
    }
    else
    {
        dz_0 = int(0);
    }
    int dy_0;
    if((f_2.y) < 0.5f)
    {
        dy_0 = int(-1);
    }
    else
    {
        dy_0 = int(0);
    }
    int dx_0;
    if((f_2.z) < 0.5f)
    {
        dx_0 = int(-1);
    }
    else
    {
        dx_0 = int(0);
    }
    int3  _S191 = make_int3 (dz_0, dy_0, dx_0);
    float nearest_0 = 1.0e+09f;
    dz_0 = int(0);
    for(;;)
    {
        if(dz_0 <= int(1))
        {
        }
        else
        {
            break;
        }
        dy_0 = int(0);
        for(;;)
        {
            if(dy_0 <= int(1))
            {
            }
            else
            {
                break;
            }
            float nearest_1 = nearest_0;
            dx_0 = int(0);
            for(;;)
            {
                if(dx_0 <= int(1))
                {
                }
                else
                {
                    break;
                }
                int3  off_0 = _S191 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S192 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_13 = _S192 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S190 + off_0) - f_2;
                float _S193 = (F32_min((nearest_1), (dot_0(d_13, d_13))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S193;
                dx_0 = dx_1;
            }
            int dy_1 = dy_0 + int(1);
            nearest_0 = nearest_1;
            dy_0 = dy_1;
        }
        dz_0 = dz_0 + int(1);
    }
    return saturate_0(1.0f - nearest_0 / 0.5625f);
}

static __device__ float convBillow_0(ConvectionInput_0 * c_36, float3  p_6, float scale_0)
{
    float3  _S194 = make_float3 (p_6.x, p_6.y - c_36->cvRise_0, p_6.z) / make_float3 (scale_0);
    int i_14 = int(0);
    float3  x_28 = _S194;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_14 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_14 >= (c_36->cvOctaves_0))
        {
            break;
        }
        float3  x_29 = convTwist_0(x_28);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_29);
        float norm_3 = norm_2 + amp_2;
        float3  x_30 = x_29 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_14 = i_14 + int(1);
        x_28 = x_30;
        amp_2 = amp_3;
        sum_2 = sum_3;
        norm_2 = norm_3;
    }
    float raw_0;
    if(norm_2 > 0.0f)
    {
        raw_0 = sum_2 / norm_2;
    }
    else
    {
        raw_0 = 0.0f;
    }
    return clamp_1(raw_0 * 2.20000004768371582f - 1.15999996662139893f, -1.0f, 1.0f);
}

static __device__ float convInside_0(ConvectionInput_0 * c_37, float d_14, float lift_1, float3  x_31, float scale_1)
{
    float _S195 = d_14 + lift_1;
    if(_S195 <= 0.0f)
    {
        return _S195;
    }
    if((d_14 - lift_1) >= 12.0f)
    {
        return 12.0f;
    }
    float _S196 = convBillow_0(c_37, x_31, scale_1);
    return d_14 + lift_1 * _S196;
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_38, float r_7)
{
    return convDomeHeight_0(c_38->cvHeroTop_0, c_38->cvHeroRadius_0, c_38->cvShape_0, r_7);
}

static __device__ float convCapGrain_0(ConvectionInput_0 * c_39, float2  rel_4, float scale_2)
{
    return saturate_0(0.80000001192092896f + 0.13330000638961792f * gradientNoise_0(make_float3 (rel_4.x / scale_2 + c_39->cvHeroSeed_0.x * 0.00100000004749745f, 0.37000000476837158f, rel_4.y / scale_2 + c_39->cvHeroSeed_0.z * 0.00100000004749745f)));
}

static __device__ float convCapDensity_0(ConvectionInput_0 * c_40, float3  p_7, float above_8)
{
    float2  rel_5 = float2 {p_7.x, p_7.z} - c_40->cvHeroAt_0;
    float r2_3 = dot_1(rel_5, rel_5);
    float _S197 = c_40->cvHeroRadius_0;
    float _S198 = c_40->cvPileusThick_0;
    float best_2;
    if((c_40->cvPileusThick_0) > 0.0f)
    {
        float rp_0 = 0.60000002384185791f * _S197;
        float _S199 = rp_0 * rp_0;
        if(r2_3 < _S199)
        {
            float lens_0 = 1.0f - r2_3 / _S199;
            float _S200 = c_40->cvPileusGap_0;
            float _S201 = convHeroHeight_0(c_40, (F32_sqrt((r2_3))) * 0.60000002384185791f);
            float most_0 = 0.5f * _S198 * lens_0;
            float _S202 = (F32_abs((above_8 - (_S200 + _S201))));
            if(_S202 < most_0)
            {
                float _S203 = convCapGrain_0(c_40, rel_5, 900.0f);
                float s_10 = most_0 * _S203 - _S202;
                if(s_10 > 0.0f)
                {
                    best_2 = (F32_max((0.0f), (0.44999998807907104f * smoothstep_0(0.0f, 15.0f, s_10))));
                }
                else
                {
                    best_2 = 0.0f;
                }
            }
            else
            {
                best_2 = 0.0f;
            }
        }
        else
        {
            best_2 = 0.0f;
        }
    }
    else
    {
        best_2 = 0.0f;
    }
    float _S204 = c_40->cvVelumThick_0;
    if((c_40->cvVelumThick_0) > 0.0f)
    {
        float ext_0 = 1.89999997615814209f * _S197;
        if(r2_3 < (ext_0 * ext_0))
        {
            float r_8 = (F32_sqrt((r2_3)));
            float2  dir_0;
            if(r_8 > 0.00100000004749745f)
            {
                dir_0 = rel_5 / make_float2 (r_8);
            }
            else
            {
                dir_0 = make_float2 (1.0f, 0.0f);
            }
            float edge_0 = _S197 + (ext_0 - _S197) * saturate_0(0.875f + 0.08330000191926956f * gradientNoise_0(make_float3 (1.70000004768371582f * dir_0.x + c_40->cvHeroSeed_0.x * 0.00100000004749745f, 2.29999995231628418f, 1.70000004768371582f * dir_0.y + c_40->cvHeroSeed_0.z * 0.00100000004749745f)));
            float _S205 = 0.5f * _S204;
            float most_1 = _S205 * (1.0f - smoothstep_0(_S197 + 0.40000000596046448f * (edge_0 - _S197), edge_0, r_8));
            float _S206 = (F32_abs((above_8 - (c_40->cvVelumHeight_0 + _S205 * (1.0f - smoothstep_0(_S197, 2.0f * _S197, r_8))))));
            if(_S206 < most_1)
            {
                float _S207 = convCapGrain_0(c_40, rel_5, 2500.0f);
                float s_11 = most_1 * _S207 - _S206;
                if(s_11 > 0.0f)
                {
                    best_2 = (F32_max((best_2), (0.2199999988079071f * smoothstep_0(0.0f, 15.0f, s_11))));
                }
            }
        }
    }
    return c_40->cvSigma_0 * best_2;
}

static __device__ void convGroupFold_0(float d_15, float3  x_32, float lift_2, float lobe_2, float * gMax_0, float * gSum_0, float3  * gX_0, float * gLift_0, float * gLobe_0)
{
    if(d_15 > (*gMax_0))
    {
        float scale_3 = (F32_exp(((*gMax_0 - d_15) / 50.0f)));
        *gSum_0 = *gSum_0 * scale_3;
        *gX_0 = *gX_0 * make_float3 (scale_3);
        *gLift_0 = *gLift_0 * scale_3;
        *gLobe_0 = *gLobe_0 * scale_3;
        *gMax_0 = d_15;
    }
    float wt_0 = (F32_exp(((d_15 - *gMax_0) / 50.0f)));
    *gSum_0 = *gSum_0 + wt_0;
    *gX_0 = *gX_0 + make_float3 (wt_0) * x_32;
    *gLift_0 = *gLift_0 + wt_0 * lift_2;
    *gLobe_0 = *gLobe_0 + wt_0 * lobe_2;
    return;
}

static __device__ float convGroupInside_0(ConvectionInput_0 * c_41, float3  p_8, float above_9, bool nearGroup_3)
{
    bool _S208;
    float gMax_1 = -1.00000001504746622e+30f;
    float gSum_1 = 0.0f;
    float gLift_1 = 0.0f;
    float gLobe_1 = 0.0f;
    float3  gX_1 = make_float3 (0.0f, 0.0f, 0.0f);
    float d_16;
    float amount_2;
    float lobe_3;
    float3  x_33;
    bool anyTurret_0 = false;
    int k_7 = int(0);
    for(;;)
    {
        if(k_7 < int(5))
        {
        }
        else
        {
            break;
        }
        if(!nearGroup_3)
        {
            _S208 = true;
        }
        else
        {
            _S208 = k_7 >= (c_41->cvTurretCount_0);
        }
        if(_S208)
        {
            break;
        }
        float4  _S209 = convTurret_0(c_41, k_7);
        float kt_1;
        bool _S210 = convTurretSmooth_0(c_41, _S209, p_8, above_9, &d_16, &x_33, &kt_1);
        if(_S210)
        {
            float _S211 = convLift_0(c_41, above_9, kt_1);
            convGroupFold_0(d_16, x_33, _S211, kt_1, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
            anyTurret_0 = true;
        }
        k_7 = k_7 + int(1);
    }
    bool _S212 = convHeroSmooth_0(c_41, p_8, above_9, &d_16, &x_33, &amount_2, &lobe_3);
    float heroLift_0;
    if(_S212)
    {
        float _S213 = convLift_0(c_41, above_9, amount_2);
        heroLift_0 = _S213;
    }
    else
    {
        heroLift_0 = 0.0f;
    }
    if(!_S212)
    {
        _S208 = !anyTurret_0;
    }
    else
    {
        _S208 = false;
    }
    if(_S208)
    {
        return -1.00000001504746622e+30f;
    }
    float lift_3;
    float lobeAt_0;
    float3  at_2;
    if(!anyTurret_0)
    {
        gMax_1 = d_16;
        lift_3 = heroLift_0;
        at_2 = x_33;
        lobeAt_0 = lobe_3;
    }
    else
    {
        if(_S212)
        {
            convGroupFold_0(d_16, x_33, heroLift_0, lobe_3, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
        }
        float3  _S214 = gX_1 / make_float3 (gSum_1);
        float _S215 = gLobe_1 / gSum_1;
        lift_3 = gLift_1 / gSum_1;
        at_2 = _S214;
        lobeAt_0 = _S215;
    }
    float _S216 = convInside_0(c_41, gMax_1, lift_3, at_2 + c_41->cvHeroSeed_0, c_41->cvBillowScale_0 * lobeAt_0);
    return _S216;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_42, float3  p_9, float above_10)
{
    float d_17;
    float amount_3;
    float lobe_4;
    float3  x_34;
    bool _S217 = convHeroSmooth_0(c_42, p_9, above_10, &d_17, &x_34, &amount_3, &lobe_4);
    if(!_S217)
    {
        return -1.00000001504746622e+30f;
    }
    float _S218 = convLift_0(c_42, above_10, amount_3);
    float _S219 = convInside_0(c_42, d_17, _S218, x_34 + c_42->cvHeroSeed_0, c_42->cvBillowScale_0 * lobe_4);
    return _S219;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_43, float3  p_10)
{
    float _S220 = p_10.y;
    float above_11 = _S220 - c_43->cvBase_0;
    float _S221 = c_43->cvMammaDepth_0;
    bool rampBand_0;
    if(above_11 < (- c_43->cvMammaDepth_0))
    {
        rampBand_0 = true;
    }
    else
    {
        float _S222 = convCeiling_0(c_43);
        rampBand_0 = above_11 > _S222;
    }
    if(rampBand_0)
    {
        return 0.0f;
    }
    float2  _S223 = float2 {p_10.x, p_10.z};
    float2  fromHero_0 = _S223 - c_43->cvHeroAt_0;
    bool nearGroup_4 = (dot_1(fromHero_0, fromHero_0)) < (c_43->cvGroupReach_0 * c_43->cvGroupReach_0);
    bool _S224 = _S221 > 0.0f;
    if(_S224)
    {
        rampBand_0 = above_11 < 0.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    if(rampBand_0)
    {
        float _S225 = convMammaSag_0(c_43, _S223, nearGroup_4, - above_11);
        float hang_0 = _S225 + above_11;
        if(hang_0 <= 0.0f)
        {
            return 0.0f;
        }
        return c_43->cvSigma_0 * (F32_sqrt((saturate_0(hang_0 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, hang_0);
    }
    float _S226 = convLift_0(c_43, above_11, 1.0f - 0.60000002384185791f * c_43->cvLacunarity_0);
    if(_S224)
    {
        rampBand_0 = above_11 < 40.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    bool moated_1;
    float capDensity_0;
    float sag_0;
    float baseField_0;
    float inside_1;
    if((c_43->cvHeroAlone_0) == int(0))
    {
        float capMoat_1 = 0.0f;
        float2  _S227 = make_float2 (0.0f, 0.0f);
        float2  gMoat_1 = _S227;
        if((c_43->cvMoat_0) > 0.0f)
        {
            moated_1 = nearGroup_4;
        }
        else
        {
            moated_1 = false;
        }
        if(moated_1)
        {
            float _S228 = convMoat_0(c_43, _S223, &gMoat_1, &capMoat_1);
            capDensity_0 = _S228;
        }
        else
        {
            capDensity_0 = 1.0f;
        }
        if(capDensity_0 > 0.0f)
        {
            float2  q_11 = _S223 - c_43->cvDrift_0;
            float2  slope_5;
            float _S229 = convUpdraftGrad_0(c_43, q_11, &slope_5);
            float _S230 = convSlopeCap_0(c_43);
            float cap_6;
            if(moated_1)
            {
                slope_5 = slope_5 * make_float2 (capDensity_0) + gMoat_1 * make_float2 (_S229);
                float cap_7 = _S230 + capMoat_1;
                sag_0 = _S229 * capDensity_0;
                cap_6 = cap_7;
            }
            else
            {
                sag_0 = _S229;
                cap_6 = _S230;
            }
            if(rampBand_0)
            {
                float _S231 = convFieldBaseInside_0(c_43, sag_0, slope_5, cap_6);
                baseField_0 = _S231;
            }
            else
            {
                baseField_0 = -1.00000001504746622e+30f;
            }
            float _S232 = convTowerHeight_0(c_43, sag_0);
            float v_5 = _S232 - above_11;
            float _S233 = convNeededUpdraft_0(c_43, above_11);
            float delta_1 = sag_0 - _S233;
            float d_18 = convSurfaceDistance_0(v_5, delta_1, (F32_min((length_1(slope_5)), (cap_6))));
            if((d_18 + _S226) > 0.0f)
            {
                if((F32_abs((v_5))) > 9.99999997475242708e-07f)
                {
                    inside_1 = d_18 * (d_18 / v_5);
                }
                else
                {
                    inside_1 = 0.0f;
                }
                float2  shiftAcross_0;
                if((F32_abs((delta_1))) > 9.999999960041972e-13f)
                {
                    shiftAcross_0 = slope_5 * make_float2 (- d_18 * (d_18 / delta_1));
                }
                else
                {
                    shiftAcross_0 = _S227;
                }
                float _S234 = convInside_0(c_43, d_18, _S226, make_float3 (q_11.x + shiftAcross_0.x, _S220 + inside_1, q_11.y + shiftAcross_0.y), c_43->cvBillowScale_0);
                inside_1 = _S234;
            }
            else
            {
                inside_1 = -1.00000001504746622e+30f;
            }
        }
        else
        {
            inside_1 = -1.00000001504746622e+30f;
            baseField_0 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        inside_1 = -1.00000001504746622e+30f;
        baseField_0 = -1.00000001504746622e+30f;
    }
    bool _S235 = (c_43->cvHeroTop_0) > 0.0f;
    if(_S235)
    {
        if((c_43->cvPileusThick_0) > 0.0f)
        {
            moated_1 = true;
        }
        else
        {
            moated_1 = (c_43->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        float _S236 = convCapDensity_0(c_43, p_10, above_11);
        capDensity_0 = _S236;
    }
    else
    {
        capDensity_0 = 0.0f;
    }
    if(_S235)
    {
        moated_1 = inside_1 < 12.0f;
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        if((c_43->cvTurretCount_0) > int(0))
        {
            float _S237 = convGroupInside_0(c_43, p_10, above_11, nearGroup_4);
            inside_1 = (F32_max((inside_1), (_S237)));
        }
        else
        {
            float _S238 = convHeroInside_0(c_43, p_10, above_11);
            inside_1 = (F32_max((inside_1), (_S238)));
        }
    }
    if(inside_1 <= 0.0f)
    {
        return capDensity_0;
    }
    if(rampBand_0)
    {
        float _S239 = convPouches_0(c_43, _S223 - c_43->cvDrift_0);
        if(_S239 > 0.0f)
        {
            float _S240 = convGroupBaseInside_0(c_43, _S223, nearGroup_4);
            float _S241 = convMammaSagOf_0(c_43, _S239, (F32_max((baseField_0), (_S240))));
            sag_0 = _S241;
        }
        else
        {
            sag_0 = 0.0f;
        }
    }
    else
    {
        sag_0 = 0.0f;
    }
    return (F32_max((c_43->cvSigma_0 * (F32_sqrt((saturate_0((above_11 + sag_0) / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1)), (capDensity_0)));
}

static __device__ float densityAt_0(Medium_0 * m_5, StructuredBuffer<float2 > disp_2, float3  p_11)
{
    float _S242 = p_11.y;
    bool _S243;
    if(_S242 < (m_5->slabBottom_0))
    {
        _S243 = true;
    }
    else
    {
        _S243 = _S242 > (m_5->slabTop_0);
    }
    if(_S243)
    {
        return 0.0f;
    }
    if((m_5->clipOn_0) != int(0))
    {
        float2  _S244 = float2 {p_11.x, p_11.z};
        if(any_0(_S244 < (m_5->clipLo_0)))
        {
            _S243 = true;
        }
        else
        {
            _S243 = any_0(_S244 > (m_5->clipHi_0));
        }
    }
    else
    {
        _S243 = false;
    }
    if(_S243)
    {
        return 0.0f;
    }
    float _S245 = m_5->fadeRadius_0;
    float fade_0;
    if((m_5->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S245 - length_1(float2 {p_11.x, p_11.z} - m_5->fadeAt_0)) / (F32_max((m_5->fadeWidth_0), (1.0f))));
        if(fade_1 <= 0.0f)
        {
            return 0.0f;
        }
        fade_0 = fade_1;
    }
    else
    {
        fade_0 = 1.0f;
    }
    int _S246 = m_5->mode_0;
    if((m_5->mode_0) == int(0))
    {
        return m_5->density_0 * fade_0;
    }
    if(_S246 == int(2))
    {
        float _S247 = iceDensity_0(&m_5->gen_0, disp_2, p_11);
        return _S247 * fade_0;
    }
    if(_S246 == int(3))
    {
        float _S248 = convectionDensity_0(&m_5->conv_0, p_11);
        return _S248 * fade_0;
    }
    float3  d_19 = (p_11 - m_5->coreCentre_0) / make_float3 ((F32_max((m_5->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_5->density_0 + m_5->coreDensity_0 * (F32_exp((- dot_0(d_19, d_19))))) * fade_0;
}

static __device__ void layerMapColumn_0(Medium_0 * med_0, StructuredBuffer<float2 > drift_0, LayerShadowMap_0 * m_6, int texel_0, RWStructuredBuffer<float> outTexels_0)
{
    int _S249 = m_6->smDimU_0;
    int stride_0 = m_6->smDimU_0 * m_6->smDimV_0;
    bool _S250;
    if(texel_0 < int(0))
    {
        _S250 = true;
    }
    else
    {
        _S250 = texel_0 >= stride_0;
    }
    if(_S250)
    {
        return;
    }
    int iu_0 = texel_0 % _S249;
    int iv_0 = texel_0 / _S249;
    float2  _S251 = m_6->smLo_0;
    float2  _S252 = m_6->smTexel_0;
    float2  _S253 = m_6->smCentre_0 + m_6->smAxisU_0 * make_float2 (m_6->smLo_0.x + (float(iu_0) + 0.5f) * m_6->smTexel_0.x);
    float2  _S254 = airMapAxisV_0(m_6);
    float2  q_12 = _S253 + _S254 * make_float2 (_S251.y + (float(iv_0) + 0.5f) * _S252.y);
    float3  base_0 = make_float3 (q_12.x, m_6->smBottom_0, q_12.y);
    float3  _S255 = m_6->smSun_0;
    int _S256 = m_6->smSlices_0;
    int _S257 = m_6->smSlices_0 - int(1);
    float _S258 = (m_6->smTop_0 - m_6->smBottom_0) / (float(_S257) * m_6->smSun_0.y);
    float _S259 = (F32_max((m_6->smStep_0), (1.0f)));
    float t0_2;
    float t1_2;
    bool _S260 = slabRange_0(med_0, base_0, m_6->smSun_0, &t0_2, &t1_2);
    *(&(outTexels_0)[_S257 * stride_0 + texel_0]) = 1.0f;
    int k_8 = _S256 - int(2);
    float tau_0 = 0.0f;
    for(;;)
    {
        if(k_8 >= int(0))
        {
        }
        else
        {
            break;
        }
        if(_S260)
        {
            _S250 = tau_0 < 12.0f;
        }
        else
        {
            _S250 = false;
        }
        float tau_1;
        if(_S250)
        {
            float _S261 = (F32_max((float(k_8) * _S258), (t0_2)));
            float _S262 = (F32_min((float(k_8 + int(1)) * _S258), (t1_2)));
            if(_S262 > _S261)
            {
                float _S263 = _S262 - _S261;
                int n_0 = clamp_2(int((F32_ceil((_S263 / _S259)))), int(1), int(1024));
                float _S264 = _S263 / float(n_0);
                int j_11 = int(0);
                tau_1 = tau_0;
                for(;;)
                {
                    if(j_11 < n_0)
                    {
                    }
                    else
                    {
                        break;
                    }
                    float _S265 = densityAt_0(med_0, drift_0, base_0 + _S255 * make_float3 (_S261 + (float(j_11) + 0.5f) * _S264));
                    float tau_2 = tau_1 + _S265 * _S264;
                    j_11 = j_11 + int(1);
                    tau_1 = tau_2;
                }
            }
            else
            {
                tau_1 = tau_0;
            }
        }
        else
        {
            tau_1 = tau_0;
        }
        float * _S266 = (&(outTexels_0)[k_8 * stride_0 + texel_0]);
        float _S267;
        if(tau_1 < 12.0f)
        {
            _S267 = (F32_exp((- tau_1)));
        }
        else
        {
            _S267 = 0.0f;
        }
        *_S266 = _S267;
        k_8 = k_8 - int(1);
        tau_0 = tau_1;
    }
    return;
}

extern "C" __global__ void airMapBuild(Medium_0 medium_0, StructuredBuffer<float2 > drift_1, LayerShadowMap_0 map_0, RWStructuredBuffer<float> outTexels_1, int count_0)
{
    int i_15 = int((blockIdx * blockDim + threadIdx).x);
    if(i_15 >= count_0)
    {
        return;
    }
    Medium_0 _S268 = medium_0;
    LayerShadowMap_0 _S269 = map_0;
    layerMapColumn_0(&_S268, drift_1, &_S269, i_15, outTexels_1);
    return;
}

static __device__ float clampf_0(float v_6, float lo_2, float hi_2)
{
    float _S270;
    if(v_6 < lo_2)
    {
        _S270 = lo_2;
    }
    else
    {
        if(v_6 > hi_2)
        {
            _S270 = hi_2;
        }
        else
        {
            _S270 = v_6;
        }
    }
    return _S270;
}

static __device__ float airMapTexel_0(LayerShadowMap_0 * m_7, int iu_1, int iv_1, int k_9)
{
    float _S271 = __ldg((&(m_7->smTexels_0)[(k_9 * m_7->smDimV_0 + iv_1) * m_7->smDimU_0 + iu_1]));
    return _S271;
}

static __device__ float layerMapTransmittance_0(LayerShadowMap_0 * m_8, float3  p_12)
{
    int _S272 = m_8->smDimU_0;
    int _S273 = m_8->smDimV_0;
    int _S274 = m_8->smSlices_0;
    uint want_0 = uint(m_8->smDimU_0 * m_8->smDimV_0 * m_8->smSlices_0);
    bool _S275;
    if(want_0 == 0U)
    {
        _S275 = true;
    }
    else
    {
        _S275 = uint(StructuredBuffer_getCount_0(m_8->smTexels_0)) < want_0;
    }
    if(_S275)
    {
        return 1.0f;
    }
    float _S276 = p_12.y;
    float _S277 = m_8->smTop_0;
    if(_S276 >= (m_8->smTop_0))
    {
        return 1.0f;
    }
    float3  _S278 = m_8->smSun_0;
    float _S279 = m_8->smBottom_0;
    float2  q_13 = float2 {p_12.x, p_12.z} + float2 {_S278.x, _S278.z} * make_float2 ((m_8->smBottom_0 - _S276) / m_8->smSun_0.y) - m_8->smCentre_0;
    float2  _S280 = m_8->smLo_0;
    float2  _S281 = m_8->smTexel_0;
    float fu_0 = (dot_1(q_13, m_8->smAxisU_0) - m_8->smLo_0.x) / m_8->smTexel_0.x - 0.5f;
    float2  _S282 = airMapAxisV_0(m_8);
    float fv_0 = (dot_1(q_13, _S282) - _S280.y) / _S281.y - 0.5f;
    if(fu_0 >= -0.5f)
    {
        _S275 = fv_0 >= -0.5f;
    }
    else
    {
        _S275 = false;
    }
    if(_S275)
    {
        _S275 = fu_0 <= (float(_S272) - 0.5f);
    }
    else
    {
        _S275 = false;
    }
    if(_S275)
    {
        _S275 = fv_0 <= (float(_S273) - 0.5f);
    }
    else
    {
        _S275 = false;
    }
    if(!_S275)
    {
        return 1.0f;
    }
    int _S283 = _S272 - int(1);
    float fu_1 = clampf_0(fu_0, 0.0f, float(_S283));
    int _S284 = _S273 - int(1);
    float fv_1 = clampf_0(fv_0, 0.0f, float(_S284));
    int u0_0 = int(fu_1);
    int v0_0 = int(fv_1);
    int _S285 = (I32_min((u0_0 + int(1)), (_S283)));
    int _S286 = (I32_min((v0_0 + int(1)), (_S284)));
    float tu_0 = fu_1 - float(u0_0);
    float tv_0 = fv_1 - float(v0_0);
    int _S287 = _S274 - int(1);
    float fk_0 = clampf_0((_S276 - _S279) / (F32_max((_S277 - _S279), (1.0f))), 0.0f, 1.0f) * float(_S287);
    int _S288 = (I32_min((int(fk_0)), (_S287)));
    int _S289 = (I32_min((_S288 + int(1)), (_S287)));
    float tk_0 = fk_0 - float(_S288);
    float _S290 = airMapTexel_0(m_8, u0_0, v0_0, _S288);
    float _S291 = 1.0f - tu_0;
    float _S292 = _S290 * _S291;
    float _S293 = airMapTexel_0(m_8, _S285, v0_0, _S288);
    float a0_0 = _S292 + _S293 * tu_0;
    float _S294 = airMapTexel_0(m_8, u0_0, _S286, _S288);
    float _S295 = _S294 * _S291;
    float _S296 = airMapTexel_0(m_8, _S285, _S286, _S288);
    float b0_0 = _S295 + _S296 * tu_0;
    float _S297 = airMapTexel_0(m_8, u0_0, v0_0, _S289);
    float _S298 = _S297 * _S291;
    float _S299 = airMapTexel_0(m_8, _S285, v0_0, _S289);
    float a1_0 = _S298 + _S299 * tu_0;
    float _S300 = airMapTexel_0(m_8, u0_0, _S286, _S289);
    float _S301 = _S300 * _S291;
    float _S302 = airMapTexel_0(m_8, _S285, _S286, _S289);
    float _S303 = 1.0f - tv_0;
    return (a0_0 * _S303 + b0_0 * tv_0) * (1.0f - tk_0) + (a1_0 * _S303 + (_S301 + _S302 * tu_0) * tv_0) * tk_0;
}

extern "C" __global__ void airMapLookup(LayerShadowMap_0 map_1, StructuredBuffer<float3 > points_0, RWStructuredBuffer<float> outT_0, int count_1)
{
    int i_16 = int((blockIdx * blockDim + threadIdx).x);
    if(i_16 >= count_1)
    {
        return;
    }
    float * _S304 = (&(outT_0)[i_16]);
    float3  _S305 = slang_ldg_0((&(points_0)[i_16]));
    LayerShadowMap_0 _S306 = map_1;
    float _S307 = layerMapTransmittance_0(&_S306, _S305);
    *_S304 = _S307;
    return;
}

static __device__ bool layerMapRange_0(LayerShadowMap_0 * m_9, float3  ro_1, float3  rd_1, float * t0_3, float * t1_3)
{
    *t0_3 = 0.0f;
    *t1_3 = 1.00000001504746622e+30f;
    int _S308 = m_9->smDimU_0;
    int _S309 = m_9->smDimV_0;
    uint want_1 = uint(m_9->smDimU_0 * m_9->smDimV_0 * m_9->smSlices_0);
    bool _S310;
    if(want_1 == 0U)
    {
        _S310 = true;
    }
    else
    {
        _S310 = uint(StructuredBuffer_getCount_0(m_9->smTexels_0)) < want_1;
    }
    if(_S310)
    {
        return false;
    }
    float _S311 = rd_1.y;
    if((F32_abs((_S311))) < 9.99999971718068537e-10f)
    {
        if((ro_1.y) >= (m_9->smTop_0))
        {
            return false;
        }
    }
    else
    {
        float tt_0 = (m_9->smTop_0 - ro_1.y) / _S311;
        if(_S311 > 0.0f)
        {
            *t1_3 = (F32_min((*t1_3), (tt_0)));
        }
        else
        {
            *t0_3 = (F32_max((*t0_3), (tt_0)));
        }
    }
    float3  _S312 = m_9->smSun_0;
    float2  _S313 = float2 {_S312.x, _S312.z};
    float _S314 = m_9->smSun_0.y;
    float2  q0_0 = float2 {ro_1.x, ro_1.z} + _S313 * make_float2 ((m_9->smBottom_0 - ro_1.y) / _S314) - m_9->smCentre_0;
    float2  dq_0 = float2 {rd_1.x, rd_1.z} - _S313 * make_float2 (_S311 / _S314);
    float2  _S315 = airMapAxisV_0(m_9);
    float _S316 = m_9->smLo_0.x;
    float _S317 = m_9->smLo_0.y;
    float vHi_0 = _S317 + float(_S309) * m_9->smTexel_0.y;
    bool _S318 = clipAxis_0(dot_1(q0_0, m_9->smAxisU_0), dot_1(dq_0, m_9->smAxisU_0), _S316, _S316 + float(_S308) * m_9->smTexel_0.x, t0_3, t1_3);
    if(!_S318)
    {
        return false;
    }
    bool _S319 = clipAxis_0(dot_1(q0_0, _S315), dot_1(dq_0, _S315), _S317, vHi_0, t0_3, t1_3);
    if(!_S319)
    {
        return false;
    }
    return (*t1_3) > (*t0_3);
}

static __device__ float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static __device__ float3  normalizeExact_0(float3  v_7)
{
    float len2_0 = dot_0(v_7, v_7);
    if(len2_0 <= 0.0f)
    {
        return make_float3 (0.0f, 1.0f, 0.0f);
    }
    return v_7 * make_float3 (1.0f / (F32_sqrt((len2_0))));
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
    float3  groundSkyLight_0;
    StructuredBuffer<float> transmittanceLut_0;
};

static __device__ float3  sunDirection_0(SkyInput_0 * p_13)
{
    float az_0 = toRadians_0(p_13->sunAzimuth_0);
    float el_0 = toRadians_0(p_13->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static __device__ float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_20 = altitude_0 - shellHeight_0;
    return d_20 * (d_20 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_0, float c_44)
{
    float disc_0 = b_0 * b_0 - c_44;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_0 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_1, float c_45)
{
    float disc_1 = b_1 * b_1 - c_45;
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

static __device__ float altitudeFromQ_0(float q_14, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_14;
    float _S320;
    if(rr_0 > 0.0f)
    {
        _S320 = rr_0;
    }
    else
    {
        _S320 = 0.0f;
    }
    return q_14 / (planetRadius_2 + (F32_sqrt((_S320))));
}

static __device__ float lutMuFor_0(float3  geocentric_0, float3  sun_0)
{
    float len_1 = length_0(geocentric_0);
    float _S321;
    if(len_1 > 1.0f)
    {
        _S321 = dot_0(geocentric_0, sun_0) / len_1;
    }
    else
    {
        _S321 = dot_0(geocentric_0, sun_0);
    }
    return _S321;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_14, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S322 = p_14->transmittanceLut_0;
    if(uint(StructuredBuffer_getCount_0(p_14->transmittanceLut_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S323 = p_14->scaleHeight_0;
    float scaleHeight_1;
    if((p_14->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S323;
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
    float _S324 = fx_1 - float(x0_1);
    float _S325 = fy_1 - float(y0_1);
    int _S326 = y0_1 * int(256);
    int _S327 = (_S326 + x0_1) * int(3);
    int _S328 = (_S326 + x1_1) * int(3);
    int _S329 = y1_1 * int(256);
    int _S330 = (_S329 + x0_1) * int(3);
    int _S331 = (_S329 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_46 = int(0);
    for(;;)
    {
        if(c_46 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S332 = __ldg((&(_S322)[_S327 + c_46]));
        float _S333 = 1.0f - _S324;
        float _S334 = _S332 * _S333;
        float _S335 = __ldg((&(_S322)[_S328 + c_46]));
        float a_0 = _S334 + _S335 * _S324;
        float _S336 = __ldg((&(_S322)[_S330 + c_46]));
        float _S337 = _S336 * _S333;
        float _S338 = __ldg((&(_S322)[_S331 + c_46]));
        float r_9 = a_0 * (1.0f - _S325) + (_S337 + _S338 * _S324) * _S325;
        if(c_46 == int(0))
        {
            *&((&out_0)->x) = r_9;
        }
        else
        {
            if(c_46 == int(1))
            {
                *&((&out_0)->y) = r_9;
            }
            else
            {
                *&((&out_0)->z) = r_9;
            }
        }
        c_46 = c_46 + int(1);
    }
    return out_0;
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_15)
{
    return 20.0f * p_15->sunIntensity_0;
}

static __device__ float3  airShadowLoss_0(SkyInput_0 * p_16, LayerShadowMap_0 * mapA_0, LayerShadowMap_0 * mapB_0, float3  ro_2, float3  rd_2, float dist_1, float jitter_1)
{
    float3  none_0 = make_float3 (0.0f, 0.0f, 0.0f);
    float r0_0;
    float r1_0;
    bool _S339 = layerMapRange_0(mapA_0, ro_2, rd_2, &r0_0, &r1_0);
    float tA_0;
    float tB_0;
    if(_S339)
    {
        float _S340 = (F32_max((-1.00000001504746622e+30f), (r1_0)));
        tA_0 = (F32_min((1.00000001504746622e+30f), (r0_0)));
        tB_0 = _S340;
    }
    else
    {
        tA_0 = 1.00000001504746622e+30f;
        tB_0 = -1.00000001504746622e+30f;
    }
    bool _S341 = layerMapRange_0(mapB_0, ro_2, rd_2, &r0_0, &r1_0);
    if(_S341)
    {
        float _S342 = (F32_min((tA_0), (r0_0)));
        tB_0 = (F32_max((tB_0), (r1_0)));
        tA_0 = _S342;
    }
    if(!(tB_0 > tA_0))
    {
        return none_0;
    }
    float3  _S343 = sunDirection_0(p_16);
    float _S344 = p_16->planetRadius_0;
    float planetRadius_3;
    if((p_16->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S344;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S345 = p_16->scaleHeight_0;
    float scaleHeight_2;
    if((p_16->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S345;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float atmosphereHeight_0 = scaleHeight_2 * 8.0f;
    float _S346 = ro_2.y;
    float observerAltitude_0;
    if(_S346 > 0.0f)
    {
        observerAltitude_0 = _S346;
    }
    else
    {
        observerAltitude_0 = 0.0f;
    }
    float _S347 = planetRadius_3 + observerAltitude_0;
    float _S348 = rd_2.y;
    float b_2 = _S347 * _S348;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(b_2, shellC_0(observerAltitude_0, planetRadius_3, atmosphereHeight_0));
    bool _S349;
    if(tTop_0 <= 0.0f)
    {
        _S349 = true;
    }
    else
    {
        _S349 = !(dist_1 > 0.0f);
    }
    if(_S349)
    {
        return none_0;
    }
    float tGround_0 = shellEnter_0(b_2, cGround_0);
    float tMax_0;
    if(tGround_0 > 0.0f)
    {
        tMax_0 = tGround_0;
    }
    else
    {
        tMax_0 = tTop_0;
    }
    if(dist_1 < tMax_0)
    {
        tMax_0 = dist_1;
    }
    float _S350 = (F32_max((tA_0), (0.0f)));
    float _S351 = (F32_min((tB_0), (tMax_0)));
    if(!(_S351 > _S350))
    {
        return none_0;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_16->turbidity_0);
    float _S352 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rd_2, _S343), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_7 = clampf_0(p_16->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S353 = g_7 * g_7;
    float hgDenom_0 = 1.0f + _S353 - 2.0f * g_7 * cosTheta_0;
    float _S354 = 1.0f - _S353;
    float _S355 = 12.56637096405029297f * hgDenom_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tA_0 = hgDenom_0;
    }
    else
    {
        tA_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S354 / (_S355 * (F32_sqrt((tA_0))));
    float depthR_0;
    float depthM_0;
    float hc_0;
    int i_17;
    if(_S350 > 0.0f)
    {
        float _S356 = _S350 / 8.0f;
        i_17 = int(0);
        depthR_0 = 0.0f;
        depthM_0 = 0.0f;
        for(;;)
        {
            if(i_17 < int(8))
            {
            }
            else
            {
                break;
            }
            float tm_0 = (float(i_17) + 0.5f) * _S356;
            float h_5 = altitudeFromQ_0(cGround_0 + 2.0f * tm_0 * b_2 + tm_0 * tm_0, planetRadius_3);
            if(h_5 < 0.0f)
            {
                hc_0 = 0.0f;
            }
            else
            {
                hc_0 = h_5;
            }
            float _S357 = - hc_0;
            float depthR_1 = depthR_0 + (F32_exp((_S357 / scaleHeight_2))) * _S356;
            float depthM_1 = depthM_0 + (F32_exp((_S357 / 1200.0f))) * _S356;
            i_17 = i_17 + int(1);
            depthR_0 = depthR_1;
            depthM_0 = depthM_1;
        }
    }
    else
    {
        depthR_0 = 0.0f;
        depthM_0 = 0.0f;
    }
    float _S358 = clampf_0(jitter_1, 0.0f, 1.0f);
    float _S359 = _S351 - _S350;
    float3  lossR_0 = none_0;
    float3  lossM_0 = none_0;
    i_17 = int(0);
    for(;;)
    {
        if(i_17 < int(48))
        {
        }
        else
        {
            break;
        }
        float s0_0 = _S350 + _S359 * float(i_17 * i_17) * 0.00043402778101154f;
        int _S360 = i_17 + int(1);
        float dt_0 = _S350 + _S359 * float(_S360 * _S360) * 0.00043402778101154f - s0_0;
        float ts_0 = s0_0 + _S358 * dt_0;
        float h_6 = altitudeFromQ_0(cGround_0 + 2.0f * ts_0 * b_2 + ts_0 * ts_0, planetRadius_3);
        if(h_6 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_6;
        }
        float _S361 = - hc_0;
        float rhoR_0 = (F32_exp((_S361 / scaleHeight_2)));
        float rhoM_0 = (F32_exp((_S361 / 1200.0f)));
        float _S362 = ts_0 - s0_0;
        float atR_0 = depthR_0 + rhoR_0 * _S362;
        float atM_0 = depthM_0 + rhoM_0 * _S362;
        float depthR_2 = depthR_0 + rhoR_0 * dt_0;
        float depthM_2 = depthM_0 + rhoM_0 * dt_0;
        float3  pw_0 = ro_2 + rd_2 * make_float3 (ts_0);
        float _S363 = layerMapTransmittance_0(mapA_0, pw_0);
        float _S364 = layerMapTransmittance_0(mapB_0, pw_0);
        float v_8 = _S363 * _S364;
        if(v_8 >= 1.0f)
        {
            i_17 = _S360;
            depthR_0 = depthR_2;
            depthM_0 = depthM_2;
            continue;
        }
        float3  _S365 = sampleTransmittanceLut_0(p_16, hc_0, lutMuFor_0(make_float3 (rd_2.x * ts_0, _S347 + _S348 * ts_0, rd_2.z * ts_0), _S343));
        float _S366 = _S352 * atM_0;
        float3  w_6 = make_float3 ((F32_exp((- (betaR_0.x * atR_0 + _S366)))), (F32_exp((- (betaR_0.y * atR_0 + _S366)))), (F32_exp((- (betaR_0.z * atR_0 + _S366))))) * _S365 * make_float3 ((1.0f - v_8) * dt_0);
        float3  _S367 = lossM_0 + w_6 * make_float3 (rhoM_0);
        lossR_0 = lossR_0 + w_6 * make_float3 (rhoR_0);
        lossM_0 = _S367;
        i_17 = _S360;
        depthR_0 = depthR_2;
        depthM_0 = depthM_2;
    }
    float3  _S368 = lossR_0 * betaR_0 * make_float3 (phaseR_0) + lossM_0 * make_float3 (betaM_0 * phaseM_0);
    float _S369 = sunIrradianceTop_0(p_16);
    return _S368 * make_float3 (_S369);
}

extern "C" __global__ void airMapLoss(SkyInput_0 sky_0, LayerShadowMap_0 mapA_1, LayerShadowMap_0 mapB_1, float3  origin_0, float3  direction_0, float dist_2, RWStructuredBuffer<float3 > outLoss_0, int count_2)
{
    int i_18 = int((blockIdx * blockDim + threadIdx).x);
    if(i_18 >= count_2)
    {
        return;
    }
    float jitter_2 = (float(i_18) + 0.5f) / float(count_2);
    float3  * _S370 = (&(outLoss_0)[i_18]);
    SkyInput_0 _S371 = sky_0;
    LayerShadowMap_0 _S372 = mapA_1;
    LayerShadowMap_0 _S373 = mapB_1;
    float3  _S374 = airShadowLoss_0(&_S371, &_S372, &_S373, origin_0, direction_0, dist_2, jitter_2);
    *_S370 = _S374;
    return;
}

extern "C" __global__ void airMapLossRef(SkyInput_0 p_17, LayerShadowMap_0 mapA_2, LayerShadowMap_0 mapB_2, float3  ro_3, float3  rd_3, float dist_3, int steps_0, int everywhere_0, RWStructuredBuffer<float3 > outLoss_1)
{
    SkyInput_0 _S375 = p_17;
    float3  _S376 = sunDirection_0(&_S375);
    float planetRadius_4;
    if((p_17.planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = p_17.planetRadius_0;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float scaleHeight_3;
    if((p_17.scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = p_17.scaleHeight_0;
    }
    else
    {
        scaleHeight_3 = 1.0f;
    }
    float atmosphereHeight_1 = scaleHeight_3 * 8.0f;
    float _S377 = ro_3.y;
    float observerAltitude_1;
    if(_S377 > 0.0f)
    {
        observerAltitude_1 = _S377;
    }
    else
    {
        observerAltitude_1 = 0.0f;
    }
    float _S378 = planetRadius_4 + observerAltitude_1;
    float _S379 = rd_3.y;
    float b_3 = _S378 * _S379;
    float cGround_1 = shellC_0(observerAltitude_1, planetRadius_4, 0.0f);
    float tTop_1 = shellExit_0(b_3, shellC_0(observerAltitude_1, planetRadius_4, atmosphereHeight_1));
    float tGround_1 = shellEnter_0(b_3, cGround_1);
    float tMax_1;
    if(tGround_1 > 0.0f)
    {
        tMax_1 = tGround_1;
    }
    else
    {
        tMax_1 = tTop_1;
    }
    if(dist_3 < tMax_1)
    {
        tMax_1 = dist_3;
    }
    float3  betaR_1 = rayleighCoefficients_0();
    float betaM_1 = mieCoefficient_0(p_17.turbidity_0);
    float _S380 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rd_3, _S376), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_8 = clampf_0(p_17.mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S381 = g_8 * g_8;
    float hgDenom_1 = 1.0f + _S381 - 2.0f * g_8 * cosTheta_1;
    float _S382 = 1.0f - _S381;
    float _S383 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        observerAltitude_1 = hgDenom_1;
    }
    else
    {
        observerAltitude_1 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S382 / (_S383 * (F32_sqrt((observerAltitude_1))));
    float _S384 = tMax_1 / float(steps_0);
    float3  _S385 = make_float3 (0.0f, 0.0f, 0.0f);
    float3  accR_0 = _S385;
    float3  accM_0 = _S385;
    int i_19 = int(0);
    float depthR_3 = 0.0f;
    float depthM_3 = 0.0f;
    for(;;)
    {
        if(i_19 < steps_0)
        {
        }
        else
        {
            break;
        }
        float tm_1 = (float(i_19) + 0.5f) * _S384;
        float h_7 = altitudeFromQ_0(cGround_1 + 2.0f * tm_1 * b_3 + tm_1 * tm_1, planetRadius_4);
        float hc_1;
        if(h_7 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_7;
        }
        float _S386 = - hc_1;
        float rR_0 = (F32_exp((_S386 / scaleHeight_3)));
        float rM_0 = (F32_exp((_S386 / 1200.0f)));
        float atR_1 = depthR_3 + 0.5f * rR_0 * _S384;
        float atM_1 = depthM_3 + 0.5f * rM_0 * _S384;
        float depthR_4 = depthR_3 + rR_0 * _S384;
        float depthM_4 = depthM_3 + rM_0 * _S384;
        float3  pw_1 = ro_3 + rd_3 * make_float3 (tm_1);
        LayerShadowMap_0 _S387 = mapA_2;
        float _S388 = layerMapTransmittance_0(&_S387, pw_1);
        LayerShadowMap_0 _S389 = mapB_2;
        float _S390 = layerMapTransmittance_0(&_S389, pw_1);
        float _S391 = _S388 * _S390;
        float v_9;
        if(everywhere_0 != int(0))
        {
            v_9 = 0.0f;
        }
        else
        {
            v_9 = _S391;
        }
        if(v_9 >= 1.0f)
        {
            i_19 = i_19 + int(1);
            depthR_3 = depthR_4;
            depthM_3 = depthM_4;
            continue;
        }
        float _S392 = lutMuFor_0(make_float3 (rd_3.x * tm_1, _S378 + _S379 * tm_1, rd_3.z * tm_1), _S376);
        SkyInput_0 _S393 = p_17;
        float3  _S394 = sampleTransmittanceLut_0(&_S393, hc_1, _S392);
        float _S395 = _S380 * atM_1;
        float3  w_7 = make_float3 ((F32_exp((- (betaR_1.x * atR_1 + _S395)))), (F32_exp((- (betaR_1.y * atR_1 + _S395)))), (F32_exp((- (betaR_1.z * atR_1 + _S395))))) * _S394 * make_float3 ((1.0f - v_9) * _S384);
        float3  _S396 = accM_0 + w_7 * make_float3 (rM_0);
        accR_0 = accR_0 + w_7 * make_float3 (rR_0);
        accM_0 = _S396;
        i_19 = i_19 + int(1);
        depthR_3 = depthR_4;
        depthM_3 = depthM_4;
    }
    float3  * _S397 = (&(outLoss_1)[int(0)]);
    float3  _S398 = accR_0 * betaR_1 * make_float3 (phaseR_1) + accM_0 * make_float3 (betaM_1 * phaseM_1);
    SkyInput_0 _S399 = p_17;
    float _S400 = sunIrradianceTop_0(&_S399);
    *_S397 = _S398 * make_float3 (_S400);
    return;
}

static __device__ float groundShadow_0(LayerShadowMap_0 * mapA_3, LayerShadowMap_0 * mapB_3, float3  origin_1, float3  dir_1)
{
    float _S401 = dir_1.y;
    bool _S402;
    if(!(_S401 < 0.0f))
    {
        _S402 = true;
    }
    else
    {
        _S402 = !((origin_1.y) > 0.0f);
    }
    if(_S402)
    {
        return 1.0f;
    }
    float3  ground_0 = origin_1 + dir_1 * make_float3 (origin_1.y / - _S401);
    *&((&ground_0)->y) = 0.0f;
    float _S403 = layerMapTransmittance_0(mapA_3, ground_0);
    float _S404 = layerMapTransmittance_0(mapB_3, ground_0);
    return _S403 * _S404;
}

extern "C" __global__ void airMapGround(LayerShadowMap_0 mapA_4, LayerShadowMap_0 mapB_4, float3  origin_2, StructuredBuffer<float3 > directions_0, RWStructuredBuffer<float> outLit_0, int count_3)
{
    int i_20 = int((blockIdx * blockDim + threadIdx).x);
    if(i_20 >= count_3)
    {
        return;
    }
    float * _S405 = (&(outLit_0)[i_20]);
    float3  _S406 = slang_ldg_0((&(directions_0)[i_20]));
    LayerShadowMap_0 _S407 = mapA_4;
    LayerShadowMap_0 _S408 = mapB_4;
    float _S409 = groundShadow_0(&_S407, &_S408, origin_2, _S406);
    *_S405 = _S409;
    return;
}

