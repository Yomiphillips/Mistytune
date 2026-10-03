// GENERATED FROM Convection.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

static __device__ float2  abs_0(float2  x_0)
{
    float2  result_0;
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_abs((_slang_vector_get_element(x_0, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ bool all_0(bool2  x_1)
{
    bool result_1 = true;
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
        if(result_1)
        {
            result_1 = (bool((_slang_vector_get_element(x_1, i_1))));
        }
        else
        {
            result_1 = false;
        }
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ float2  min_0(float2  x_2, float2  y_0)
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
        *_slang_vector_get_element_ptr(&result_2, i_2) = (F32_min((_slang_vector_get_element(x_2, i_2)), (_slang_vector_get_element(y_0, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ float2  max_0(float2  x_3, float2  y_1)
{
    float2  result_3;
    int i_3 = int(0);
    for(;;)
    {
        if(i_3 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_3, i_3) = (F32_max((_slang_vector_get_element(x_3, i_3)), (_slang_vector_get_element(y_1, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ float3  lerp_0(float3  x_4, float3  y_2, float3  s_0)
{
    return x_4 + (y_2 - x_4) * s_0;
}

static __device__ float clamp_0(float x_5, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_5), (minBound_0)))), (maxBound_0)));
}

static __device__ float saturate_0(float x_6)
{
    return clamp_0(x_6, 0.0f, 1.0f);
}

static __device__ float smoothstep_0(float min_1, float max_1, float x_7)
{
    float _S1 = saturate_0((x_7 - min_1) / (max_1 - min_1));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static __device__ float4  lerp_1(float4  x_8, float4  y_3, float4  s_1)
{
    return x_8 + (y_3 - x_8) * s_1;
}

static __device__ int2  min_2(int2  x_9, int2  y_4)
{
    int2  result_4;
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
        *_slang_vector_get_element_ptr(&result_4, i_4) = (I32_min((_slang_vector_get_element(x_9, i_4)), (_slang_vector_get_element(y_4, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static __device__ float2  clamp_1(float2  x_10, float2  minBound_1, float2  maxBound_1)
{
    return min_0(max_0(x_10, minBound_1), maxBound_1);
}

static __device__ float dot_0(float2  x_11, float2  y_5)
{
    return x_11.x * y_5.x + x_11.y * y_5.y;
}

static __device__ float length_0(float2  x_12)
{
    return (F32_sqrt((dot_0(x_12, x_12))));
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

static __device__ float3  floor_0(float3  x_13)
{
    float3  result_5;
    int i_5 = int(0);
    for(;;)
    {
        if(i_5 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_5, i_5) = (F32_floor((_slang_vector_get_element(x_13, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
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

static __device__ float dot_1(float3  x_14, float3  y_6)
{
    return x_14.x * y_6.x + x_14.y * y_6.y + x_14.z * y_6.z;
}

static __device__ float lerp_2(float x_15, float y_7, float s_2)
{
    return x_15 + (y_7 - x_15) * s_2;
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_0(p_0);
    int3  _S6 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S7 = u_0.x;
    float _S8 = u_0.y;
    return lerp_2(lerp_2(lerp_2(dot_1(hash33_0(_S6), f_0), dot_1(hash33_0(_S6 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S7), lerp_2(dot_1(hash33_0(_S6 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S6 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S7), _S8), lerp_2(lerp_2(dot_1(hash33_0(_S6 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S6 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S7), lerp_2(dot_1(hash33_0(_S6 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S6 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S7), _S8), u_0.z);
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
    float2  g_1 = make_float2 (dot_0(q_0, o_1->ogAxis_0), dot_0(q_0, make_float2 (- o_1->ogAxis_0.y, o_1->ogAxis_0.x))) / make_float2 (spacing_0 * o_1->ogStretch_0, spacing_0);
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

static __device__ float2  floor_1(float2  x_16)
{
    float2  result_6;
    int i_6 = int(0);
    for(;;)
    {
        if(i_6 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_6, i_6) = (F32_floor((_slang_vector_get_element(x_16, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_6;
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

static __device__ float2  lerp_3(float2  x_17, float2  y_8, float2  s_4)
{
    return x_17 + (y_8 - x_17) * s_4;
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
    float s_6 = 2.0f * (F32_frac((dot_0(q_1, o_4->ogWaveK_0)))) - 1.0f;
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
            int2  slot_2 = _S39 + make_int2 (i_7, j_1);
            float _S41 = convVigour_0(c_6, slot_2);
            if(_S41 <= 0.0f)
            {
                i_7 = i_7 + int(1);
                continue;
            }
            float2  _S42 = convCellCentre_0(c_6, slot_2);
            float2  d_1 = _S37 - _S42;
            float d2_2 = dot_0(d_1, d_1);
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
            i_7 = i_7 + int(1);
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
        int i_8 = int(-1);
        for(;;)
        {
            if(i_8 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_3 = _S51 + make_int2 (i_8, j_3);
            float _S52 = convVigour_0(c_7, slot_3);
            if(_S52 <= 0.0f)
            {
                i_8 = i_8 + int(1);
                continue;
            }
            float2  _S53 = convCellCentre_0(c_7, slot_3);
            float2  d_2 = _S49 - _S53;
            float d2_3 = dot_0(d_2, d_2);
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
            i_8 = i_8 + int(1);
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
        int i_9 = int(-1);
        for(;;)
        {
            if(i_9 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_5 = _S64 + make_int2 (i_9, j_5);
            float _S66 = convVigour_0(c_8, slot_5);
            if(_S66 <= 0.0f)
            {
                i_9 = i_9 + int(1);
                continue;
            }
            float2  d_3 = _S62 - convCellCentrePlain_0(slot_5);
            float d2_4 = dot_0(d_3, d_3);
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
            i_9 = i_9 + int(1);
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

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S73 = __ldg(&(ptr_0->x));
    float _S74 = __ldg(&(ptr_0->y));
    float _S75 = __ldg(&(ptr_0->z));
    return make_float3 (_S73, _S74, _S75);
}

static __device__ float convCapCeiling_0(ConvectionInput_0 * c_9)
{
    float _S76 = c_9->cvHeroTop_0;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        return 0.0f;
    }
    float _S77 = c_9->cvPileusThick_0;
    float cap_0;
    if((c_9->cvPileusThick_0) > 0.0f)
    {
        cap_0 = _S76 + c_9->cvPileusGap_0 + _S77;
    }
    else
    {
        cap_0 = 0.0f;
    }
    float _S78 = c_9->cvVelumThick_0;
    float veil_0;
    if((c_9->cvVelumThick_0) > 0.0f)
    {
        veil_0 = c_9->cvVelumHeight_0 + 1.5f * _S78;
    }
    else
    {
        veil_0 = 0.0f;
    }
    return (F32_max((cap_0), (veil_0)));
}

static __device__ float convCeiling_0(ConvectionInput_0 * c_10)
{
    float _S79 = c_10->cvBillow_0;
    float field_0 = c_10->cvDepth_0 + c_10->cvBillow_0;
    float _S80 = c_10->cvHeroTop_0;
    float hero_0;
    if((c_10->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S80 + _S79 * c_10->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    float _S81 = (F32_max((field_0), (hero_0)));
    float _S82 = convCapCeiling_0(c_10);
    return (F32_max((_S81), (_S82)));
}

static __device__ float convPouches_0(ConvectionInput_0 * c_11, float2  q_6)
{
    float2  g_3 = q_6 / make_float2 (c_11->cvPouchSize_0);
    float2  _S83 = floor_1(g_3);
    int2  _S84 = make_int2 ((int)_S83.x, (int)_S83.y);
    float deepest_0 = 0.0f;
    int j_7 = int(-1);
    for(;;)
    {
        if(j_7 <= int(1))
        {
        }
        else
        {
            break;
        }
        float deepest_1 = deepest_0;
        int i_10 = int(-1);
        for(;;)
        {
            if(i_10 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_6 = _S84 + make_int2 (i_10, j_7);
            float2  _S85 = make_float2 ((float)slot_6.x, (float)slot_6.y);
            float2  d_4 = g_3 - (_S85 + make_float2 (0.5f) + (hash22_0(slot_6, 739982445U) - make_float2 (0.5f)) * make_float2 (0.60000002384185791f));
            float t2_0 = dot_0(d_4, d_4) / 0.46240001916885376f;
            if(t2_0 >= 1.0f)
            {
                i_10 = i_10 + int(1);
                continue;
            }
            float2  h_3 = hash22_0(slot_6, 2135587861U);
            deepest_1 = (F32_max((deepest_1), (lerp_2(0.30000001192092896f, 1.0f, convLife_0((F32_frac((2.0f * c_11->cvAge_0 + h_3.x))))) * lerp_2(0.60000002384185791f, 1.0f, h_3.y) * (F32_sqrt((1.0f - t2_0))))));
            i_10 = i_10 + int(1);
        }
        int j_8 = j_7 + int(1);
        deepest_0 = deepest_1;
        j_7 = j_8;
    }
    return deepest_0;
}

static __device__ void convMoatRing_0(float2  xz_0, float2  at_0, float radius_0, float * s_8, float2  * gs_0, float * slope_0)
{
    float2  d_5 = xz_0 - at_0;
    float r2_1 = dot_0(d_5, d_5);
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
        float2  _S86;
        if(r_1 > 0.00100000004749745f)
        {
            _S86 = d_5 * make_float2 (6.0f * t_3 * (1.0f - t_3) / (band_1 * r_1));
        }
        else
        {
            _S86 = make_float2 (0.0f, 0.0f);
        }
        *gs_0 = _S86;
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
        float4  _S87 = convTurret_0(c_13, k_2);
        convMoatRing_0(xz_1, float2 {_S87.x, _S87.y}, _S87.z, &s_9, &gs_1, &slope_1);
        k_2 = k_2 + int(1);
    }
    float _S88 = c_13->cvMoat_0;
    *grad_5 = gs_1 * make_float2 (c_13->cvMoat_0);
    *slopeAdd_0 = slope_1 * _S88;
    return 1.0f - _S88 * (1.0f - s_9);
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_14, float2  q_7, float2  * grad_6)
{
    if(((&c_14->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S89 = convUpdraftGradT_2(c_14, q_7, grad_6);
        return _S89;
    }
    if((c_14->cvLacunarity_0) <= 0.0f)
    {
        float _S90 = convUpdraftGradT_1(c_14, q_7, grad_6);
        return _S90;
    }
    float _S91 = convUpdraftGradT_0(c_14, q_7, grad_6);
    return _S91;
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_15)
{
    float _S92 = c_15->cvSpacing_0;
    float cap_1 = 7.0f / c_15->cvSpacing_0;
    if(((&c_15->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_1;
    }
    float _S93 = c_15->cvLacunarity_0;
    float cap_2;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        cap_2 = cap_1 + 1.5f / (0.15000000596046448f * _S93 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S92);
    }
    else
    {
        cap_2 = cap_1;
    }
    float _S94 = c_15->cvGapWidth_0;
    if((c_15->cvGapWidth_0) > 0.0f)
    {
        cap_2 = cap_2 + 14.25f * c_15->cvPolarity_0 / (0.5f * _S94 * _S92);
    }
    return cap_2 + 3.0f * (&c_15->cvOrg_0)->ogWaveAmp_0 * length_0((&c_15->cvOrg_0)->ogWaveK_0);
}

static __device__ float convTowerHeight_0(ConvectionInput_0 * c_16, float w_1)
{
    float cover_0 = clamp_0(c_16->cvCoverage_0, 0.0f, 1.0f);
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
    float cover_1 = clamp_0(c_17->cvCoverage_0, 0.0f, 1.0f);
    bool _S95;
    if(cover_1 <= 0.0f)
    {
        _S95 = true;
    }
    else
    {
        _S95 = (c_17->cvDepth_0) <= 0.0f;
    }
    if(_S95)
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
    float d_6 = num_0 / den_0;
    float _S96;
    if(v_2 >= 0.0f)
    {
        _S96 = d_6;
    }
    else
    {
        _S96 = - d_6;
    }
    return _S96;
}

static __device__ float convFieldBaseInside_0(ConvectionInput_0 * c_18, float w_2, float2  slope_3, float cap_3)
{
    float _S97 = convTowerHeight_0(c_18, w_2);
    float v_3 = _S97 - 1.0f;
    float _S98 = convNeededUpdraft_0(c_18, 1.0f);
    return convSurfaceDistance_0(v_3, w_2 - _S98, (F32_min((length_0(slope_3)), (cap_3))));
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_19)
{
    return c_19->cvHeroRadius_0 + 1.5f * c_19->cvBillow_0 * c_19->cvHeroBillow_0 + 24.0f;
}

static __device__ float convShapeReach_0(ConvectionInput_0 * c_20)
{
    float lift_0 = 1.5f * c_20->cvBillow_0 * c_20->cvHeroBillow_0 + 24.0f;
    return length_0(make_float2 (c_20->cvShapeHalfWidth_0 + lift_0, c_20->cvShapeRound_0 + c_20->cvReliefHeight_0 + lift_0));
}

static __device__ float convHeroReachAll_0(ConvectionInput_0 * c_21)
{
    float _S99 = convHeroReach_0(c_21);
    float _S100;
    if((c_21->cvShapeOn_0) != int(0))
    {
        float _S101 = convShapeReach_0(c_21);
        _S100 = (F32_max((_S99), (_S101)));
    }
    else
    {
        _S100 = _S99;
    }
    return _S100;
}

static __device__ float convDomeHeight_0(float top_0, float radius_1, float shape_0, float r_2)
{
    bool _S102;
    if(top_0 <= 0.0f)
    {
        _S102 = true;
    }
    else
    {
        _S102 = r_2 >= radius_1;
    }
    if(_S102)
    {
        return 0.0f;
    }
    return top_0 * (F32_pow((1.0f - r_2 * r_2 / (radius_1 * radius_1)), (shape_0)));
}

static __device__ float convDomeRadiusAt_0(float top_1, float radius_2, float shape_1, float above_1)
{
    bool _S103;
    if(top_1 <= 0.0f)
    {
        _S103 = true;
    }
    else
    {
        _S103 = above_1 >= top_1;
    }
    if(_S103)
    {
        return -1.0f;
    }
    return radius_2 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_1), (0.0f))) / top_1), (1.0f / (F32_max((shape_1), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convDomeSurface_0(float top_2, float radius_3, float shape_2, float2  rel_0, float r_3, float py_0, float above_2, float3  * x_18)
{
    float v_4 = convDomeHeight_0(top_2, radius_3, shape_2, r_3) - above_2;
    float ra_0 = convDomeRadiusAt_0(top_2, radius_3, shape_2, above_2);
    float shiftOut_0;
    float shiftUp_0;
    float d_7;
    if(ra_0 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_4;
        d_7 = v_4;
    }
    else
    {
        float h_4 = ra_0 - r_3;
        float d_8 = convSurfaceDistance_0(v_4, h_4, 1.0f);
        if((F32_abs((v_4))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_8 * (d_8 / v_4);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_4))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_8 * (d_8 / h_4);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S104 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S104;
        d_7 = d_8;
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
    *x_18 = make_float3 (at_1.x, py_0 + shiftUp_0, at_1.y);
    return d_7;
}

static __device__ float convTowerSurface_0(ConvectionInput_0 * c_22, float2  rel_1, float r_4, float py_1, float above_3, float3  * x_19)
{
    float _S105 = convDomeSurface_0(c_22->cvHeroTop_0, c_22->cvHeroRadius_0, c_22->cvShape_0, rel_1, r_4, py_1, above_3, x_19);
    return _S105;
}

static __device__ float4  convShapeTexel_0(ConvectionInput_0 * c_23, int i_11, int j_9)
{
    int k_3 = (j_9 * c_23->cvShapeDim_0.x + i_11) * int(4);
    StructuredBuffer<float> _S106 = c_23->cvShapeMap_0;
    float _S107 = __ldg((&(c_23->cvShapeMap_0)[k_3]));
    float _S108 = __ldg((&(_S106)[k_3 + int(1)]));
    float _S109 = __ldg((&(_S106)[k_3 + int(2)]));
    float _S110 = __ldg((&(_S106)[k_3 + int(3)]));
    return make_float4 (_S107, _S108, _S109, _S110);
}

static __device__ float convShapeDistance_0(ConvectionInput_0 * c_24, float u_3, float y_9, float2  * slopeUY_0, float * relief_0)
{
    float _S111 = c_24->cvShapeTexel_0;
    float2  st_0 = make_float2 (u_3, y_9) / make_float2 (c_24->cvShapeTexel_0) + c_24->cvShapeOffset_0 - make_float2 (0.5f);
    int2  _S112 = make_int2 (int(1), int(1));
    int2  last_0 = c_24->cvShapeDim_0 - _S112;
    float2  _S113 = make_float2 ((float)last_0.x, (float)last_0.y);
    float2  q_8 = clamp_1(st_0, make_float2 (0.0f, 0.0f), _S113);
    float past_0 = length_0(st_0 - q_8);
    float2  f0_0 = floor_1(q_8);
    int2  _S114 = make_int2 ((int)f0_0.x, (int)f0_0.y);
    int2  i0_0 = min_2(_S114, last_0);
    int2  i1_0 = min_2(i0_0 + _S112, last_0);
    float2  fr_0 = q_8 - f0_0;
    int _S115 = i0_0.x;
    int _S116 = i0_0.y;
    float4  _S117 = convShapeTexel_0(c_24, _S115, _S116);
    int _S118 = i1_0.x;
    float4  _S119 = convShapeTexel_0(c_24, _S118, _S116);
    int _S120 = i1_0.y;
    float4  _S121 = convShapeTexel_0(c_24, _S115, _S120);
    float4  _S122 = convShapeTexel_0(c_24, _S118, _S120);
    float4  _S123 = make_float4 (fr_0.x);
    float4  blend_0 = lerp_1(lerp_1(_S117, _S119, _S123), lerp_1(_S121, _S122, _S123), make_float4 (fr_0.y));
    *slopeUY_0 = float2 {blend_0.y, blend_0.z};
    *relief_0 = blend_0.w;
    return (blend_0.x - past_0) * _S111;
}

static __device__ float convReliefLift_0(ConvectionInput_0 * c_25, float dIn_0, float relief_1)
{
    return c_25->cvReliefHeight_0 * relief_1 * smoothstep_0(0.0f, (F32_max((c_25->cvReliefFade_0), (1.0f))), dIn_0);
}

static __device__ float convShapeProfile_0(float dIn_1, float m_0, float rimR_0, float2  * stepDM_0)
{
    if(dIn_1 >= rimR_0)
    {
        *stepDM_0 = make_float2 (0.0f, rimR_0 - m_0);
        return m_0 - rimR_0;
    }
    float2  w_3 = make_float2 (dIn_1 - rimR_0, m_0);
    float len_0 = length_0(w_3);
    float gap_0 = len_0 - rimR_0;
    float2  _S124;
    if(len_0 > 9.99999997475242708e-07f)
    {
        _S124 = w_3 * make_float2 (- gap_0 / len_0);
    }
    else
    {
        _S124 = make_float2 (0.0f, rimR_0);
    }
    *stepDM_0 = _S124;
    return gap_0;
}

static __device__ float convShapeSurface_0(ConvectionInput_0 * c_26, float2  plane_0, float py_2, float above_4, float3  * x_20)
{
    float _S125 = plane_0.x;
    float2  slopeUY_1;
    float relief_2;
    float _S126 = convShapeDistance_0(c_26, _S125, above_4, &slopeUY_1, &relief_2);
    float _S127 = plane_0.y;
    float _S128 = (F32_abs((_S127)));
    bool _S129;
    if((c_26->cvReliefHeight_0) > 0.0f)
    {
        _S129 = _S127 > 0.0f;
    }
    else
    {
        _S129 = false;
    }
    float m_1;
    if(_S129)
    {
        float _S130 = convReliefLift_0(c_26, _S126, relief_2);
        m_1 = (F32_max((_S127 - _S130), (0.0f)));
    }
    else
    {
        m_1 = _S128;
    }
    float2  stepDM_1;
    float gap_1 = convShapeProfile_0(_S126, m_1, c_26->cvShapeRound_0, &stepDM_1);
    float side_0;
    if(_S127 >= 0.0f)
    {
        side_0 = 1.0f;
    }
    else
    {
        side_0 = -1.0f;
    }
    *x_20 = make_float3 (_S125 + stepDM_1.x * slopeUY_1.x, py_2 + stepDM_1.x * slopeUY_1.y, _S127 + side_0 * stepDM_1.y);
    return - gap_1;
}

static __device__ bool convHeroSmooth_0(ConvectionInput_0 * c_27, float3  p_1, float above_5, float * d_9, float3  * x_21, float * amount_0, float * lobe_0)
{
    *d_9 = -1.00000001504746622e+30f;
    *x_21 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S131 = c_27->cvHeroBillow_0;
    *amount_0 = c_27->cvHeroBillow_0;
    *lobe_0 = _S131;
    float2  rel_2 = float2 {p_1.x, p_1.z} - c_27->cvHeroAt_0;
    float r_5 = length_0(rel_2);
    float _S132 = convHeroReachAll_0(c_27);
    if(r_5 >= _S132)
    {
        return false;
    }
    if((c_27->cvShapeOn_0) == int(0))
    {
        float _S133 = convTowerSurface_0(c_27, rel_2, r_5, p_1.y, above_5, x_21);
        *d_9 = _S133;
    }
    else
    {
        float2  plane_1 = make_float2 (dot_0(rel_2, c_27->cvShapeAxisU_0), dot_0(rel_2, make_float2 (- c_27->cvShapeAxisU_0.y, c_27->cvShapeAxisU_0.x)));
        float _S134 = c_27->cvShapeDecay_0;
        if((c_27->cvShapeDecay_0) >= 1.0f)
        {
            float _S135 = convTowerSurface_0(c_27, plane_1, r_5, p_1.y, above_5, x_21);
            *d_9 = _S135;
        }
        else
        {
            float _S136 = p_1.y;
            float3  xs_0;
            float _S137 = convShapeSurface_0(c_27, plane_1, _S136, above_5, &xs_0);
            if(_S134 > 0.0f)
            {
                float3  xt_0;
                float _S138 = convTowerSurface_0(c_27, plane_1, r_5, _S136, above_5, &xt_0);
                *d_9 = lerp_2(_S137, _S138, _S134);
                *x_21 = lerp_0(xs_0, xt_0, make_float3 (_S134));
            }
            else
            {
                *d_9 = _S137;
                *x_21 = xs_0;
            }
            float _S139 = c_27->cvShapeBillow_0;
            *amount_0 = _S131 * lerp_2(c_27->cvShapeBillow_0, 1.0f, _S134);
            *lobe_0 = _S131 * lerp_2((F32_max((_S139), (0.30000001192092896f))), 1.0f, _S134);
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

static __device__ bool convTurretSmooth_0(ConvectionInput_0 * c_30, float4  t_5, float3  p_2, float above_6, float * d_10, float3  * x_22, float * k_4)
{
    *d_10 = -1.00000001504746622e+30f;
    *x_22 = make_float3 (0.0f, 0.0f, 0.0f);
    *k_4 = 1.0f;
    float2  rel_3 = float2 {p_2.x, p_2.z} - float2 {t_5.x, t_5.y};
    float r2_2 = dot_0(rel_3, rel_3);
    float _S140 = convTurretReach_0(c_30, t_5);
    if(r2_2 >= (_S140 * _S140))
    {
        return false;
    }
    float _S141 = t_5.w;
    if(above_6 >= (_S141 + c_30->cvBillow_0 * c_30->cvHeroBillow_0))
    {
        return false;
    }
    float r_6 = (F32_sqrt((r2_2)));
    float _S142 = t_5.z;
    float _S143 = convTurretBillow_0(c_30, _S142);
    *k_4 = _S143;
    float3  own_0;
    float _S144 = convDomeSurface_0(_S141, _S142, c_30->cvShape_0, rel_3, r_6, p_2.y, above_6, &own_0);
    *d_10 = _S144;
    float3  w_4 = own_0 + make_float3 (t_5.x - c_30->cvHeroAt_0.x, 0.0f, t_5.y - c_30->cvHeroAt_0.y);
    float3  w_5;
    if((c_30->cvShapeOn_0) != int(0))
    {
        float2  _S145 = float2 {w_4.x, w_4.z};
        w_5 = make_float3 (dot_0(_S145, c_30->cvShapeAxisU_0), w_4.y, dot_0(_S145, make_float2 (- c_30->cvShapeAxisU_0.y, c_30->cvShapeAxisU_0.x)));
    }
    else
    {
        w_5 = w_4;
    }
    *x_22 = w_5;
    return true;
}

static __device__ float convGroupBaseInside_0(ConvectionInput_0 * c_31, float2  xz_2, bool nearGroup_0)
{
    float best_0;
    if((c_31->cvHeroTop_0) > 0.0f)
    {
        float3  p_3 = make_float3 (xz_2.x, c_31->cvBase_0 + 1.0f, xz_2.y);
        float d_11;
        float amount_1;
        float lobe_1;
        float3  x_23;
        bool _S146 = convHeroSmooth_0(c_31, p_3, 1.0f, &d_11, &x_23, &amount_1, &lobe_1);
        if(_S146)
        {
            best_0 = (F32_max((-1.00000001504746622e+30f), (d_11)));
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
            bool _S147;
            if(!nearGroup_0)
            {
                _S147 = true;
            }
            else
            {
                _S147 = k_5 >= (c_31->cvTurretCount_0);
            }
            if(_S147)
            {
                break;
            }
            float4  _S148 = convTurret_0(c_31, k_5);
            float kt_0;
            bool _S149 = convTurretSmooth_0(c_31, _S148, p_3, 1.0f, &d_11, &x_23, &kt_0);
            if(_S149)
            {
                best_0 = (F32_max((best_0), (d_11)));
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
        float m_2;
        if(moated_0)
        {
            float _S150 = convMoat_0(c_32, xz_3, &gMoat_0, &capMoat_0);
            m_2 = _S150;
        }
        else
        {
            m_2 = 1.0f;
        }
        if(m_2 > 0.0f)
        {
            float2  slope_4;
            float _S151 = convUpdraftGrad_0(c_32, xz_3 - c_32->cvDrift_0, &slope_4);
            float _S152 = convSlopeCap_0(c_32);
            float cap_4;
            if(moated_0)
            {
                slope_4 = slope_4 * make_float2 (m_2) + gMoat_0 * make_float2 (_S151);
                float cap_5 = _S152 + capMoat_0;
                best_1 = _S151 * m_2;
                cap_4 = cap_5;
            }
            else
            {
                best_1 = _S151;
                cap_4 = _S152;
            }
            float _S153 = convFieldBaseInside_0(c_32, best_1, slope_4, cap_4);
            best_1 = _S153;
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
    float _S154 = convGroupBaseInside_0(c_32, xz_3, nearGroup_1);
    return (F32_max((best_1), (_S154)));
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
    float _S155 = convPouches_0(c_34, xz_4 - c_34->cvDrift_0);
    if((c_34->cvMammaDepth_0 * _S155) <= below_0)
    {
        return 0.0f;
    }
    float _S156 = convBaseInside_0(c_34, xz_4, nearGroup_2);
    float _S157 = convMammaSagOf_0(c_34, _S155, _S156);
    return _S157;
}

static __device__ float convLift_0(ConvectionInput_0 * c_35, float above_7, float k_6)
{
    return (F32_min((c_35->cvBillow_0 * k_6 * smoothstep_0(0.0f, 150.0f, above_7) * lerp_2(0.60000002384185791f, 1.0f, saturate_0(above_7 / (F32_max((c_35->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_7), (0.0f))))));
}

static __device__ float3  convTwist_0(float3  x_24)
{
    float _S158 = x_24.x;
    float _S159 = x_24.y;
    float _S160 = x_24.z;
    return make_float3 (0.0f * _S158 + 0.80000001192092896f * _S159 + 0.60000002384185791f * _S160, -0.80000001192092896f * _S158 + 0.36000001430511475f * _S159 - 0.47999998927116394f * _S160, -0.60000002384185791f * _S158 - 0.47999998927116394f * _S159 + 0.63999998569488525f * _S160);
}

static __device__ float convPuffs_0(float3  x_25)
{
    float3  fl_0 = floor_0(x_25);
    int3  _S161 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_2 = x_25 - fl_0;
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
    int3  _S162 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S162 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S163 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_12 = _S163 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S161 + off_0) - f_2;
                float _S164 = (F32_min((nearest_1), (dot_1(d_12, d_12))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S164;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_36, float3  p_4, float scale_0)
{
    float3  _S165 = make_float3 (p_4.x, p_4.y - c_36->cvRise_0, p_4.z) / make_float3 (scale_0);
    int i_12 = int(0);
    float3  x_26 = _S165;
    float amp_0 = 0.60000002384185791f;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_12 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_12 >= (c_36->cvOctaves_0))
        {
            break;
        }
        float3  x_27 = convTwist_0(x_26);
        float sum_1 = sum_0 + amp_0 * convPuffs_0(x_27);
        float norm_1 = norm_0 + amp_0;
        float3  x_28 = x_27 * make_float3 (2.17000007629394531f);
        float amp_1 = amp_0 * 0.55000001192092896f;
        i_12 = i_12 + int(1);
        x_26 = x_28;
        amp_0 = amp_1;
        sum_0 = sum_1;
        norm_0 = norm_1;
    }
    float raw_0;
    if(norm_0 > 0.0f)
    {
        raw_0 = sum_0 / norm_0;
    }
    else
    {
        raw_0 = 0.0f;
    }
    return clamp_0(raw_0 * 2.20000004768371582f - 1.15999996662139893f, -1.0f, 1.0f);
}

static __device__ float convInside_0(ConvectionInput_0 * c_37, float d_13, float lift_1, float3  x_29, float scale_1)
{
    float _S166 = d_13 + lift_1;
    if(_S166 <= 0.0f)
    {
        return _S166;
    }
    if((d_13 - lift_1) >= 12.0f)
    {
        return 12.0f;
    }
    float _S167 = convBillow_0(c_37, x_29, scale_1);
    return d_13 + lift_1 * _S167;
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_38, float r_7)
{
    return convDomeHeight_0(c_38->cvHeroTop_0, c_38->cvHeroRadius_0, c_38->cvShape_0, r_7);
}

static __device__ float convCapGrain_0(ConvectionInput_0 * c_39, float2  rel_4, float scale_2)
{
    return saturate_0(0.80000001192092896f + 0.13330000638961792f * gradientNoise_0(make_float3 (rel_4.x / scale_2 + c_39->cvHeroSeed_0.x * 0.00100000004749745f, 0.37000000476837158f, rel_4.y / scale_2 + c_39->cvHeroSeed_0.z * 0.00100000004749745f)));
}

static __device__ float convCapDensity_0(ConvectionInput_0 * c_40, float3  p_5, float above_8)
{
    float2  rel_5 = float2 {p_5.x, p_5.z} - c_40->cvHeroAt_0;
    float r2_3 = dot_0(rel_5, rel_5);
    float _S168 = c_40->cvHeroRadius_0;
    float _S169 = c_40->cvPileusThick_0;
    float best_2;
    if((c_40->cvPileusThick_0) > 0.0f)
    {
        float rp_0 = 0.60000002384185791f * _S168;
        float _S170 = rp_0 * rp_0;
        if(r2_3 < _S170)
        {
            float lens_0 = 1.0f - r2_3 / _S170;
            float _S171 = c_40->cvPileusGap_0;
            float _S172 = convHeroHeight_0(c_40, (F32_sqrt((r2_3))) * 0.60000002384185791f);
            float most_0 = 0.5f * _S169 * lens_0;
            float _S173 = (F32_abs((above_8 - (_S171 + _S172))));
            if(_S173 < most_0)
            {
                float _S174 = convCapGrain_0(c_40, rel_5, 900.0f);
                float s_10 = most_0 * _S174 - _S173;
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
    float _S175 = c_40->cvVelumThick_0;
    if((c_40->cvVelumThick_0) > 0.0f)
    {
        float ext_0 = 1.89999997615814209f * _S168;
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
            float edge_0 = _S168 + (ext_0 - _S168) * saturate_0(0.875f + 0.08330000191926956f * gradientNoise_0(make_float3 (1.70000004768371582f * dir_0.x + c_40->cvHeroSeed_0.x * 0.00100000004749745f, 2.29999995231628418f, 1.70000004768371582f * dir_0.y + c_40->cvHeroSeed_0.z * 0.00100000004749745f)));
            float _S176 = 0.5f * _S175;
            float most_1 = _S176 * (1.0f - smoothstep_0(_S168 + 0.40000000596046448f * (edge_0 - _S168), edge_0, r_8));
            float _S177 = (F32_abs((above_8 - (c_40->cvVelumHeight_0 + _S176 * (1.0f - smoothstep_0(_S168, 2.0f * _S168, r_8))))));
            if(_S177 < most_1)
            {
                float _S178 = convCapGrain_0(c_40, rel_5, 2500.0f);
                float s_11 = most_1 * _S178 - _S177;
                if(s_11 > 0.0f)
                {
                    best_2 = (F32_max((best_2), (0.2199999988079071f * smoothstep_0(0.0f, 15.0f, s_11))));
                }
            }
        }
    }
    return c_40->cvSigma_0 * best_2;
}

static __device__ void convGroupFold_0(float d_14, float3  x_30, float lift_2, float lobe_2, float * gMax_0, float * gSum_0, float3  * gX_0, float * gLift_0, float * gLobe_0)
{
    if(d_14 > (*gMax_0))
    {
        float scale_3 = (F32_exp(((*gMax_0 - d_14) / 50.0f)));
        *gSum_0 = *gSum_0 * scale_3;
        *gX_0 = *gX_0 * make_float3 (scale_3);
        *gLift_0 = *gLift_0 * scale_3;
        *gLobe_0 = *gLobe_0 * scale_3;
        *gMax_0 = d_14;
    }
    float wt_0 = (F32_exp(((d_14 - *gMax_0) / 50.0f)));
    *gSum_0 = *gSum_0 + wt_0;
    *gX_0 = *gX_0 + make_float3 (wt_0) * x_30;
    *gLift_0 = *gLift_0 + wt_0 * lift_2;
    *gLobe_0 = *gLobe_0 + wt_0 * lobe_2;
    return;
}

static __device__ float convGroupInside_0(ConvectionInput_0 * c_41, float3  p_6, float above_9, bool nearGroup_3)
{
    bool _S179;
    float gMax_1 = -1.00000001504746622e+30f;
    float gSum_1 = 0.0f;
    float gLift_1 = 0.0f;
    float gLobe_1 = 0.0f;
    float3  gX_1 = make_float3 (0.0f, 0.0f, 0.0f);
    float d_15;
    float amount_2;
    float lobe_3;
    float3  x_31;
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
            _S179 = true;
        }
        else
        {
            _S179 = k_7 >= (c_41->cvTurretCount_0);
        }
        if(_S179)
        {
            break;
        }
        float4  _S180 = convTurret_0(c_41, k_7);
        float kt_1;
        bool _S181 = convTurretSmooth_0(c_41, _S180, p_6, above_9, &d_15, &x_31, &kt_1);
        if(_S181)
        {
            float _S182 = convLift_0(c_41, above_9, kt_1);
            convGroupFold_0(d_15, x_31, _S182, kt_1, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
            anyTurret_0 = true;
        }
        k_7 = k_7 + int(1);
    }
    bool _S183 = convHeroSmooth_0(c_41, p_6, above_9, &d_15, &x_31, &amount_2, &lobe_3);
    float heroLift_0;
    if(_S183)
    {
        float _S184 = convLift_0(c_41, above_9, amount_2);
        heroLift_0 = _S184;
    }
    else
    {
        heroLift_0 = 0.0f;
    }
    if(!_S183)
    {
        _S179 = !anyTurret_0;
    }
    else
    {
        _S179 = false;
    }
    if(_S179)
    {
        return -1.00000001504746622e+30f;
    }
    float lift_3;
    float lobeAt_0;
    float3  at_2;
    if(!anyTurret_0)
    {
        gMax_1 = d_15;
        lift_3 = heroLift_0;
        at_2 = x_31;
        lobeAt_0 = lobe_3;
    }
    else
    {
        if(_S183)
        {
            convGroupFold_0(d_15, x_31, heroLift_0, lobe_3, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
        }
        float3  _S185 = gX_1 / make_float3 (gSum_1);
        float _S186 = gLobe_1 / gSum_1;
        lift_3 = gLift_1 / gSum_1;
        at_2 = _S185;
        lobeAt_0 = _S186;
    }
    float _S187 = convInside_0(c_41, gMax_1, lift_3, at_2 + c_41->cvHeroSeed_0, c_41->cvBillowScale_0 * lobeAt_0);
    return _S187;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_42, float3  p_7, float above_10)
{
    float d_16;
    float amount_3;
    float lobe_4;
    float3  x_32;
    bool _S188 = convHeroSmooth_0(c_42, p_7, above_10, &d_16, &x_32, &amount_3, &lobe_4);
    if(!_S188)
    {
        return -1.00000001504746622e+30f;
    }
    float _S189 = convLift_0(c_42, above_10, amount_3);
    float _S190 = convInside_0(c_42, d_16, _S189, x_32 + c_42->cvHeroSeed_0, c_42->cvBillowScale_0 * lobe_4);
    return _S190;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_43, float3  p_8)
{
    float _S191 = p_8.y;
    float above_11 = _S191 - c_43->cvBase_0;
    float _S192 = c_43->cvMammaDepth_0;
    bool rampBand_0;
    if(above_11 < (- c_43->cvMammaDepth_0))
    {
        rampBand_0 = true;
    }
    else
    {
        float _S193 = convCeiling_0(c_43);
        rampBand_0 = above_11 > _S193;
    }
    if(rampBand_0)
    {
        return 0.0f;
    }
    float2  _S194 = float2 {p_8.x, p_8.z};
    float2  fromHero_0 = _S194 - c_43->cvHeroAt_0;
    bool nearGroup_4 = (dot_0(fromHero_0, fromHero_0)) < (c_43->cvGroupReach_0 * c_43->cvGroupReach_0);
    bool _S195 = _S192 > 0.0f;
    if(_S195)
    {
        rampBand_0 = above_11 < 0.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    if(rampBand_0)
    {
        float _S196 = convMammaSag_0(c_43, _S194, nearGroup_4, - above_11);
        float hang_0 = _S196 + above_11;
        if(hang_0 <= 0.0f)
        {
            return 0.0f;
        }
        return c_43->cvSigma_0 * (F32_sqrt((saturate_0(hang_0 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, hang_0);
    }
    float _S197 = convLift_0(c_43, above_11, 1.0f - 0.60000002384185791f * c_43->cvLacunarity_0);
    if(_S195)
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
        float2  _S198 = make_float2 (0.0f, 0.0f);
        float2  gMoat_1 = _S198;
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
            float _S199 = convMoat_0(c_43, _S194, &gMoat_1, &capMoat_1);
            capDensity_0 = _S199;
        }
        else
        {
            capDensity_0 = 1.0f;
        }
        if(capDensity_0 > 0.0f)
        {
            float2  q_9 = _S194 - c_43->cvDrift_0;
            float2  slope_5;
            float _S200 = convUpdraftGrad_0(c_43, q_9, &slope_5);
            float _S201 = convSlopeCap_0(c_43);
            float cap_6;
            if(moated_1)
            {
                slope_5 = slope_5 * make_float2 (capDensity_0) + gMoat_1 * make_float2 (_S200);
                float cap_7 = _S201 + capMoat_1;
                sag_0 = _S200 * capDensity_0;
                cap_6 = cap_7;
            }
            else
            {
                sag_0 = _S200;
                cap_6 = _S201;
            }
            if(rampBand_0)
            {
                float _S202 = convFieldBaseInside_0(c_43, sag_0, slope_5, cap_6);
                baseField_0 = _S202;
            }
            else
            {
                baseField_0 = -1.00000001504746622e+30f;
            }
            float _S203 = convTowerHeight_0(c_43, sag_0);
            float v_5 = _S203 - above_11;
            float _S204 = convNeededUpdraft_0(c_43, above_11);
            float delta_1 = sag_0 - _S204;
            float d_17 = convSurfaceDistance_0(v_5, delta_1, (F32_min((length_0(slope_5)), (cap_6))));
            if((d_17 + _S197) > 0.0f)
            {
                if((F32_abs((v_5))) > 9.99999997475242708e-07f)
                {
                    inside_1 = d_17 * (d_17 / v_5);
                }
                else
                {
                    inside_1 = 0.0f;
                }
                float2  shiftAcross_0;
                if((F32_abs((delta_1))) > 9.999999960041972e-13f)
                {
                    shiftAcross_0 = slope_5 * make_float2 (- d_17 * (d_17 / delta_1));
                }
                else
                {
                    shiftAcross_0 = _S198;
                }
                float _S205 = convInside_0(c_43, d_17, _S197, make_float3 (q_9.x + shiftAcross_0.x, _S191 + inside_1, q_9.y + shiftAcross_0.y), c_43->cvBillowScale_0);
                inside_1 = _S205;
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
    bool _S206 = (c_43->cvHeroTop_0) > 0.0f;
    if(_S206)
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
        float _S207 = convCapDensity_0(c_43, p_8, above_11);
        capDensity_0 = _S207;
    }
    else
    {
        capDensity_0 = 0.0f;
    }
    if(_S206)
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
            float _S208 = convGroupInside_0(c_43, p_8, above_11, nearGroup_4);
            inside_1 = (F32_max((inside_1), (_S208)));
        }
        else
        {
            float _S209 = convHeroInside_0(c_43, p_8, above_11);
            inside_1 = (F32_max((inside_1), (_S209)));
        }
    }
    if(inside_1 <= 0.0f)
    {
        return capDensity_0;
    }
    if(rampBand_0)
    {
        float _S210 = convPouches_0(c_43, _S194 - c_43->cvDrift_0);
        if(_S210 > 0.0f)
        {
            float _S211 = convGroupBaseInside_0(c_43, _S194, nearGroup_4);
            float _S212 = convMammaSagOf_0(c_43, _S210, (F32_max((baseField_0), (_S211))));
            sag_0 = _S212;
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

extern "C" __global__ void convDensityAt(ConvectionInput_0 c_44, StructuredBuffer<float3 > points_0, RWStructuredBuffer<float> outDensity_0, int count_0)
{
    int i_13 = int((blockIdx * blockDim + threadIdx).x);
    if(i_13 >= count_0)
    {
        return;
    }
    float * _S213 = (&(outDensity_0)[i_13]);
    float3  _S214 = slang_ldg_0((&(points_0)[i_13]));
    ConvectionInput_0 _S215 = c_44;
    float _S216 = convectionDensity_0(&_S215, _S214);
    *_S213 = _S216;
    return;
}

static __device__ float convCapBound_0(ConvectionInput_0 * c_45, float3  lo_0, float3  hi_0, float low_0, float high_0)
{
    float2  nearGap_0 = max_0(max_0(float2 {lo_0.x, lo_0.z} - c_45->cvHeroAt_0, c_45->cvHeroAt_0 - float2 {hi_0.x, hi_0.z}), make_float2 (0.0f, 0.0f));
    float gap2_0 = dot_0(nearGap_0, nearGap_0);
    float _S217 = c_45->cvHeroRadius_0;
    float _S218 = c_45->cvPileusThick_0;
    bool _S219;
    float best_3;
    if((c_45->cvPileusThick_0) > 0.0f)
    {
        float rp_1 = 0.60000002384185791f * _S217;
        float _S220 = c_45->cvPileusGap_0;
        float _S221 = convHeroHeight_0(c_45, rp_1 * 0.60000002384185791f);
        float _S222 = 0.5f * _S218;
        float bottom_0 = _S220 + _S221 - _S222;
        float top_3 = _S220 + c_45->cvHeroTop_0 + _S222;
        if(gap2_0 < (rp_1 * rp_1))
        {
            _S219 = high_0 >= bottom_0;
        }
        else
        {
            _S219 = false;
        }
        if(_S219)
        {
            _S219 = low_0 <= top_3;
        }
        else
        {
            _S219 = false;
        }
        if(_S219)
        {
            best_3 = (F32_max((0.0f), (0.44999998807907104f)));
        }
        else
        {
            best_3 = 0.0f;
        }
    }
    else
    {
        best_3 = 0.0f;
    }
    float _S223 = c_45->cvVelumThick_0;
    if((c_45->cvVelumThick_0) > 0.0f)
    {
        float ext_1 = 1.89999997615814209f * _S217;
        float bottom_1 = c_45->cvVelumHeight_0 - 0.5f * _S223;
        float top_4 = c_45->cvVelumHeight_0 + _S223;
        if(gap2_0 < (ext_1 * ext_1))
        {
            _S219 = high_0 >= bottom_1;
        }
        else
        {
            _S219 = false;
        }
        if(_S219)
        {
            _S219 = low_0 <= top_4;
        }
        else
        {
            _S219 = false;
        }
        if(_S219)
        {
            best_3 = (F32_max((best_3), (0.2199999988079071f)));
        }
    }
    return c_45->cvSigma_0 * best_3 * 1.00001001358032227f;
}

static __device__ void orgPatternBox_0(Organization_0 * o_5, float2  q0_0, float2  q1_0, float spacing_2, float2  * a_0, float2  * b_0)
{
    if((o_5->ogOn_0) == int(0))
    {
        *a_0 = q0_0 / make_float2 (spacing_2);
        *b_0 = q1_0 / make_float2 (spacing_2);
        return;
    }
    Organization_0 flat_0 = *o_5;
    (&flat_0)->ogWarp_0 = 0.0f;
    Organization_0 _S224 = flat_0;
    float2  _S225 = orgPattern_0(&_S224, q0_0, spacing_2);
    Organization_0 _S226 = flat_0;
    float2  _S227 = orgPattern_0(&_S226, q1_0, spacing_2);
    float2  _S228 = make_float2 (q0_0.x, q1_0.y);
    Organization_0 _S229 = flat_0;
    float2  _S230 = orgPattern_0(&_S229, _S228, spacing_2);
    float2  _S231 = make_float2 (q1_0.x, q0_0.y);
    Organization_0 _S232 = flat_0;
    float2  _S233 = orgPattern_0(&_S232, _S231, spacing_2);
    float grow_0 = o_5->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S225.x)))), ((F32_abs((_S225.y))))))), ((F32_max(((F32_abs((_S227.x)))), ((F32_abs((_S227.y)))))))));
    *a_0 = min_0(min_0(_S225, _S230), min_0(_S233, _S227)) - make_float2 (grow_0);
    *b_0 = max_0(max_0(_S225, _S230), max_0(_S233, _S227)) + make_float2 (grow_0);
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_46, int2  slot_7, float2  a_1, float2  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S234 = convVigour_0(c_46, slot_7);
    if(_S234 <= 0.0f)
    {
        return;
    }
    float2  _S235 = convCellCentre_0(c_46, slot_7);
    float2  _S236 = a_1 - _S235;
    float2  nearGap_1 = max_0(max_0(_S236, _S235 - b_1), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_0(nearGap_1, nearGap_1);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_0(abs_0(_S236), abs_0(b_1 - _S235));
    float oHi_0 = _S234 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S234 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S234 * convBump_0(dot_0(farGap_0, farGap_0), 1.04999995231628418f);
    if(oHi_0 > (*openTop_0))
    {
        *openNext_0 = *openTop_0;
        *openTop_0 = oHi_0;
    }
    else
    {
        if(oHi_0 > (*openNext_0))
        {
            *openNext_0 = oHi_0;
        }
    }
    *hiTop_0 = (F32_max((*hiTop_0), (kHi_0)));
    if(kLo_0 > (*loTop_0))
    {
        *loNext_0 = *loTop_0;
        *loTop_0 = kLo_0;
    }
    else
    {
        if(kLo_0 > (*loNext_0))
        {
            *loNext_0 = kLo_0;
        }
    }
    return;
}

static __device__ float convUpdraftBound_0(ConvectionInput_0 * c_47, float2  q0_1, float2  q1_1)
{
    float2  a_2;
    float2  b_2;
    orgPatternBox_0(&c_47->cvOrg_0, q0_1, q1_1, c_47->cvSpacing_0, &a_2, &b_2);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    float2  _S237 = floor_1((a_2 + b_2) * make_float2 (0.5f));
    int2  _S238 = make_int2 ((int)_S237.x, (int)_S237.y);
    float2  _S239 = make_float2 ((float)_S238.x, (float)_S238.y);
    float2  highEdge_0 = _S239 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S240;
    if(all_0(a_2 >= (_S239 - make_float2 (0.00009999999747379f))))
    {
        _S240 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S240 = false;
    }
    int j_10;
    int i_14;
    if(_S240)
    {
        j_10 = int(-1);
        for(;;)
        {
            if(j_10 <= int(1))
            {
            }
            else
            {
                break;
            }
            i_14 = int(-1);
            for(;;)
            {
                if(i_14 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_47, _S238 + make_int2 (i_14, j_10), a_2, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_14 = i_14 + int(1);
            }
            j_10 = j_10 + int(1);
        }
    }
    else
    {
        float2  _S241 = floor_1(a_2);
        int2  _S242 = make_int2 ((int)_S241.x, (int)_S241.y);
        int2  _S243 = make_int2 (int(1), int(1));
        int2  i0_1 = _S242 - _S243;
        float2  _S244 = floor_1(b_2);
        int2  _S245 = make_int2 ((int)_S244.x, (int)_S244.y);
        int2  _S246 = _S245 + _S243;
        int _S247 = i0_1.y;
        j_10 = _S247;
        for(;;)
        {
            if(j_10 <= (_S246.y))
            {
                _S240 = j_10 <= (_S247 + int(32));
            }
            else
            {
                _S240 = false;
            }
            if(_S240)
            {
            }
            else
            {
                break;
            }
            int _S248 = i0_1.x;
            i_14 = _S248;
            for(;;)
            {
                bool _S249;
                if(i_14 <= (_S246.x))
                {
                    _S249 = i_14 <= (_S248 + int(32));
                }
                else
                {
                    _S249 = false;
                }
                if(_S249)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_47, make_int2 (i_14, j_10), a_2, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_14 = i_14 + int(1);
            }
            j_10 = j_10 + int(1);
        }
    }
    float field_1 = lerp_2((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_47->cvPolarity_0);
    float _S250 = c_47->cvLacunarity_0;
    float field_2;
    if((c_47->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_2(field_1, 0.40000000596046448f, _S250);
    }
    else
    {
        field_2 = field_1;
    }
    return field_2 + 0.00000999999974738f;
}

static __device__ float convMoatSlopeOver_0(ConvectionInput_0 * c_48, float2  lo_1, float2  hi_1)
{
    float slope_6 = 0.0f;
    int k_8 = int(-1);
    for(;;)
    {
        if(k_8 < int(5))
        {
        }
        else
        {
            break;
        }
        if(k_8 >= (c_48->cvTurretCount_0))
        {
            break;
        }
        float4  t_6;
        if(k_8 < int(0))
        {
            t_6 = make_float4 (c_48->cvHeroAt_0.x, c_48->cvHeroAt_0.y, c_48->cvHeroRadius_0, c_48->cvHeroTop_0);
        }
        else
        {
            float4  _S251 = convTurret_0(c_48, k_8);
            t_6 = _S251;
        }
        float4  _S252 = t_6;
        float2  _S253 = float2 {_S252.x, _S252.y};
        float2  gap_2 = max_0(max_0(lo_1 - _S253, _S253 - hi_1), make_float2 (0.0f, 0.0f));
        float _S254 = t_6.z;
        float outer_1 = 1.29999995231628418f * _S254;
        float band_2 = outer_1 - 0.75f * _S254;
        if((dot_0(gap_2, gap_2)) < (outer_1 * outer_1))
        {
            slope_6 = (F32_max((slope_6), (1.5f / band_2)));
        }
        k_8 = k_8 + int(1);
    }
    return slope_6 * c_48->cvMoat_0;
}

static __device__ float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S255;
    if(vMin_0 <= 0.0f)
    {
        _S255 = true;
    }
    else
    {
        _S255 = hMin_0 <= 0.0f;
    }
    if(_S255)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_49, float above_12)
{
    return convDomeRadiusAt_0(c_49->cvHeroTop_0, c_49->cvHeroRadius_0, c_49->cvShape_0, above_12);
}

static __device__ float convShapeBound_0(ConvectionInput_0 * c_50, float3  lo_2, float3  hi_2, float low_1, float high_1)
{
    float2  ea_0 = float2 {lo_2.x, lo_2.z} - c_50->cvHeroAt_0;
    float2  eb_0 = float2 {hi_2.x, hi_2.z} - c_50->cvHeroAt_0;
    float _S256 = c_50->cvShapeAxisU_0.y;
    float _S257 = - _S256;
    float _S258 = c_50->cvShapeAxisU_0.x;
    float _S259 = ea_0.x;
    float _S260 = _S259 * _S258;
    float _S261 = eb_0.x;
    float _S262 = _S261 * _S258;
    float _S263 = ea_0.y;
    float _S264 = _S263 * _S256;
    float _S265 = eb_0.y;
    float _S266 = _S265 * _S256;
    float uLo_0 = (F32_min((_S260), (_S262))) + (F32_min((_S264), (_S266)));
    float uHi_0 = (F32_max((_S260), (_S262))) + (F32_max((_S264), (_S266)));
    float _S267 = _S259 * _S257;
    float _S268 = _S261 * _S257;
    float _S269 = _S263 * _S258;
    float _S270 = _S265 * _S258;
    float nLo_0 = (F32_min((_S267), (_S268))) + (F32_min((_S269), (_S270)));
    float nHi_0 = (F32_max((_S267), (_S268))) + (F32_max((_S269), (_S270)));
    bool _S271;
    if(nLo_0 <= 0.0f)
    {
        _S271 = nHi_0 >= 0.0f;
    }
    else
    {
        _S271 = false;
    }
    float mMin_0;
    if(_S271)
    {
        mMin_0 = 0.0f;
    }
    else
    {
        mMin_0 = (F32_min(((F32_abs((nLo_0)))), ((F32_abs((nHi_0))))));
    }
    float2  halfSpan_0 = make_float2 (0.5f * (uHi_0 - uLo_0), 0.5f * (high_1 - low_1));
    float2  slopeUnused_0;
    float relief_3;
    float _S272 = convShapeDistance_0(c_50, 0.5f * (uLo_0 + uHi_0), 0.5f * (low_1 + high_1), &slopeUnused_0, &relief_3);
    float _S273 = length_0(halfSpan_0);
    float dMax_0 = _S272 + 2.5f * _S273;
    float _S274 = c_50->cvReliefHeight_0;
    if((c_50->cvReliefHeight_0) > 0.0f)
    {
        _S271 = nLo_0 > 0.0f;
    }
    else
    {
        _S271 = false;
    }
    if(_S271)
    {
        mMin_0 = (F32_max((nLo_0 - (F32_min((_S274), (_S274 * relief_3 + c_50->cvReliefSlope_0 * _S273)))), (0.0f)));
    }
    float2  stepUnused_0;
    return - convShapeProfile_0(dMax_0, mMin_0, c_50->cvShapeRound_0, &stepUnused_0);
}

static __device__ bool convTurretBound_0(ConvectionInput_0 * c_51, float4  t_7, float3  lo_3, float3  hi_3, float low_2, float high_2, float * dPart_0, float * lift_4)
{
    *dPart_0 = -1.00000001504746622e+30f;
    *lift_4 = 0.0f;
    float2  _S275 = float2 {t_7.x, t_7.y};
    float2  nearGap_2 = max_0(max_0(float2 {lo_3.x, lo_3.z} - _S275, _S275 - float2 {hi_3.x, hi_3.z}), make_float2 (0.0f, 0.0f));
    float gap2_1 = dot_0(nearGap_2, nearGap_2);
    float _S276 = convTurretReach_0(c_51, t_7);
    if(gap2_1 >= (_S276 * _S276))
    {
        return false;
    }
    float rMin_0 = (F32_sqrt((gap2_1)));
    float _S277 = t_7.w;
    float _S278 = t_7.z;
    float tower_0 = convDomeHeight_0(_S277, _S278, c_51->cvShape_0, rMin_0);
    float ra_1 = convDomeRadiusAt_0(_S277, _S278, c_51->cvShape_0, low_2);
    float _S279 = convTurretBillow_0(c_51, _S278);
    float _S280 = convLift_0(c_51, high_2, _S279);
    *lift_4 = _S280;
    bool _S281 = ra_1 < 0.0f;
    bool _S282;
    if(_S281)
    {
        _S282 = true;
    }
    else
    {
        _S282 = rMin_0 >= ra_1;
    }
    if(_S282)
    {
        float hMin_1;
        if(_S281)
        {
            hMin_1 = 1.00000001504746622e+30f;
        }
        else
        {
            hMin_1 = rMin_0 - ra_1;
        }
        *dPart_0 = - convDistanceFloor_0(low_2 - tower_0, hMin_1);
    }
    else
    {
        *dPart_0 = (F32_max((tower_0 - low_2), (0.0f)));
    }
    return true;
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_52, float3  lo_4, float3  hi_4)
{
    float low_3 = lo_4.y - c_52->cvBase_0;
    float high_3 = hi_4.y - c_52->cvBase_0;
    float _S283 = convCeiling_0(c_52);
    float _S284 = c_52->cvMammaDepth_0;
    bool pouches_0;
    if(high_3 < (- c_52->cvMammaDepth_0))
    {
        pouches_0 = true;
    }
    else
    {
        pouches_0 = low_3 > _S283;
    }
    if(pouches_0)
    {
        return 0.0f;
    }
    if(_S284 > 0.0f)
    {
        pouches_0 = low_3 < 40.0f;
    }
    else
    {
        pouches_0 = false;
    }
    float _S285 = (F32_max((low_3), (0.0f)));
    float _S286 = (F32_min(((F32_max((high_3), (0.0f)))), (_S283)));
    bool _S287 = (c_52->cvHeroTop_0) > 0.0f;
    bool _S288;
    if(_S287)
    {
        if((c_52->cvPileusThick_0) > 0.0f)
        {
            _S288 = true;
        }
        else
        {
            _S288 = (c_52->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        _S288 = false;
    }
    float capBound_0;
    if(_S288)
    {
        float _S289 = convCapBound_0(c_52, lo_4, hi_4, _S285, _S286);
        capBound_0 = _S289;
    }
    else
    {
        capBound_0 = 0.0f;
    }
    float _S290 = convLift_0(c_52, _S286, 1.0f);
    float inside_2;
    if((c_52->cvHeroAlone_0) == int(0))
    {
        float2  _S291 = float2 {lo_4.x, lo_4.z};
        float2  _S292 = float2 {hi_4.x, hi_4.z};
        float _S293 = convUpdraftBound_0(c_52, _S291 - c_52->cvDrift_0, _S292 - c_52->cvDrift_0);
        float _S294 = convTowerHeight_0(c_52, _S293);
        float _S295 = convNeededUpdraft_0(c_52, _S285);
        if(_S293 < _S295)
        {
            float _S296 = convSlopeCap_0(c_52);
            if((c_52->cvMoat_0) > 0.0f)
            {
                float _S297 = convMoatSlopeOver_0(c_52, _S291, _S292);
                inside_2 = _S296 + _S297;
            }
            else
            {
                inside_2 = _S296;
            }
            inside_2 = _S290 - convDistanceFloor_0(_S285 - _S294, (_S295 - _S293) / inside_2);
        }
        else
        {
            inside_2 = (F32_max((_S294 - _S285), (0.0f))) + _S290;
        }
    }
    else
    {
        inside_2 = -1.00000001504746622e+30f;
    }
    float edge_1;
    if(_S287)
    {
        float rMin_1 = length_0(max_0(max_0(float2 {lo_4.x, lo_4.z} - c_52->cvHeroAt_0, c_52->cvHeroAt_0 - float2 {hi_4.x, hi_4.z}), make_float2 (0.0f, 0.0f)));
        float _S298 = convHeroReachAll_0(c_52);
        float groupD_0;
        float groupLift_0;
        if(rMin_1 < _S298)
        {
            float _S299 = convHeroHeight_0(c_52, rMin_1);
            float _S300 = convHeroRadiusAt_0(c_52, _S285);
            float _S301 = c_52->cvHeroBillow_0;
            float _S302 = convLift_0(c_52, _S286, c_52->cvHeroBillow_0);
            bool _S303 = _S300 < 0.0f;
            if(_S303)
            {
                _S288 = true;
            }
            else
            {
                _S288 = rMin_1 >= _S300;
            }
            if(_S288)
            {
                if(_S303)
                {
                    edge_1 = 1.00000001504746622e+30f;
                }
                else
                {
                    edge_1 = rMin_1 - _S300;
                }
                edge_1 = - convDistanceFloor_0(_S285 - _S299, edge_1);
            }
            else
            {
                edge_1 = (F32_max((_S299 - _S285), (0.0f)));
            }
            if((c_52->cvShapeOn_0) != int(0))
            {
                _S288 = (c_52->cvShapeDecay_0) < 1.0f;
            }
            else
            {
                _S288 = false;
            }
            if(_S288)
            {
                float _S304 = convShapeBound_0(c_52, lo_4, hi_4, _S285, _S286);
                float _S305 = lerp_2(_S304, edge_1, c_52->cvShapeDecay_0);
                float _S306 = convLift_0(c_52, _S286, _S301 * lerp_2(c_52->cvShapeBillow_0, 1.0f, c_52->cvShapeDecay_0));
                groupD_0 = _S305;
                groupLift_0 = _S306;
            }
            else
            {
                groupD_0 = edge_1;
                groupLift_0 = _S302;
            }
        }
        else
        {
            groupD_0 = -1.00000001504746622e+30f;
            groupLift_0 = 0.0f;
        }
        int k_9 = int(0);
        for(;;)
        {
            if(k_9 < int(5))
            {
            }
            else
            {
                break;
            }
            if(k_9 >= (c_52->cvTurretCount_0))
            {
                break;
            }
            float4  _S307 = convTurret_0(c_52, k_9);
            float turretD_0;
            float turretLift_0;
            bool _S308 = convTurretBound_0(c_52, _S307, lo_4, hi_4, _S285, _S286, &turretD_0, &turretLift_0);
            if(_S308)
            {
                float _S309 = (F32_max((groupLift_0), (turretLift_0)));
                groupD_0 = (F32_max((groupD_0), (turretD_0)));
                groupLift_0 = _S309;
            }
            k_9 = k_9 + int(1);
        }
        if(groupD_0 > -1.00000001504746622e+29f)
        {
            inside_2 = (F32_max((inside_2), (groupD_0 + groupLift_0)));
        }
    }
    float inside_3 = inside_2 + 0.00100000004749745f;
    if(inside_3 <= 0.0f)
    {
        return capBound_0;
    }
    if(pouches_0)
    {
        edge_1 = 1.0f;
    }
    else
    {
        edge_1 = smoothstep_0(0.0f, 12.0f, inside_3);
    }
    if(pouches_0)
    {
        inside_2 = _S286 + _S284;
    }
    else
    {
        inside_2 = _S286;
    }
    return (F32_max((c_52->cvSigma_0 * (F32_sqrt((saturate_0(inside_2 / 40.0f)))) * edge_1 * 1.00001001358032227f), (capBound_0)));
}

extern "C" __global__ void convBoundOver(ConvectionInput_0 c_53, StructuredBuffer<float3 > boxLo_0, StructuredBuffer<float3 > boxHi_0, RWStructuredBuffer<float> outBound_0, int count_1)
{
    int i_15 = int((blockIdx * blockDim + threadIdx).x);
    if(i_15 >= count_1)
    {
        return;
    }
    float * _S310 = (&(outBound_0)[i_15]);
    float3  _S311 = slang_ldg_0((&(boxLo_0)[i_15]));
    float3  _S312 = slang_ldg_0((&(boxHi_0)[i_15]));
    ConvectionInput_0 _S313 = c_53;
    float _S314 = convectionBound_0(&_S313, _S311, _S312);
    *_S310 = _S314;
    return;
}

static __device__ float convUpdraft_0(ConvectionInput_0 * c_54, float2  q_10)
{
    float2  unused_0;
    float _S315 = convUpdraftGrad_0(c_54, q_10, &unused_0);
    return _S315;
}

extern "C" __global__ void convUpdraftAt(ConvectionInput_0 c_55, StructuredBuffer<float2 > points_1, RWStructuredBuffer<float> outUpdraft_0, int count_2)
{
    int i_16 = int((blockIdx * blockDim + threadIdx).x);
    if(i_16 >= count_2)
    {
        return;
    }
    float * _S316 = (&(outUpdraft_0)[i_16]);
    float2  _S317 = __ldg((&(points_1)[i_16]));
    ConvectionInput_0 _S318 = c_55;
    float _S319 = convUpdraft_0(&_S318, _S317);
    *_S316 = _S319;
    return;
}

extern "C" __global__ void convCells(ConvectionInput_0 c_56, StructuredBuffer<int2 > slots_0, RWStructuredBuffer<float3 > outCell_0, int count_3)
{
    int i_17 = int((blockIdx * blockDim + threadIdx).x);
    if(i_17 >= count_3)
    {
        return;
    }
    int2  _S320 = __ldg((&(slots_0)[i_17]));
    ConvectionInput_0 _S321 = c_56;
    float2  _S322 = convCellCentre_0(&_S321, _S320);
    float3  * _S323 = (&(outCell_0)[i_17]);
    float _S324 = _S322.x;
    float _S325 = _S322.y;
    int2  _S326 = __ldg((&(slots_0)[i_17]));
    ConvectionInput_0 _S327 = c_56;
    float _S328 = convVigour_0(&_S327, _S326);
    *_S323 = make_float3 (_S324, _S325, _S328);
    return;
}

extern "C" __global__ void convBillowAt(ConvectionInput_0 c_57, StructuredBuffer<float3 > points_2, RWStructuredBuffer<float> outBillow_0, int count_4)
{
    int i_18 = int((blockIdx * blockDim + threadIdx).x);
    if(i_18 >= count_4)
    {
        return;
    }
    float * _S329 = (&(outBillow_0)[i_18]);
    float3  _S330 = slang_ldg_0((&(points_2)[i_18]));
    ConvectionInput_0 _S331 = c_57;
    float _S332 = convBillow_0(&_S331, _S330, c_57.cvBillowScale_0);
    *_S329 = _S332;
    return;
}

extern "C" __global__ void convUpdraftWide(ConvectionInput_0 c_58, StructuredBuffer<float2 > points_3, RWStructuredBuffer<float> outUpdraft_1, int count_5)
{
    float oTop_9;
    int i_19 = int((blockIdx * blockDim + threadIdx).x);
    if(i_19 >= count_5)
    {
        return;
    }
    float2  _S333 = __ldg((&(points_3)[i_19]));
    Organization_0 _S334 = c_58.cvOrg_0;
    float2  _S335 = orgPattern_0(&_S334, _S333, c_58.cvSpacing_0);
    float2  _S336 = floor_1(_S335);
    int2  _S337 = make_int2 ((int)_S336.x, (int)_S336.y);
    float keep_3 = 1.0f;
    float2  _S338 = make_float2 (0.0f, 0.0f);
    float2  gKeep_4 = _S338;
    float oTop_10 = 0.0f;
    float oNext_9 = 0.0f;
    float kTop_10 = 0.0f;
    float kNext_10 = 0.0f;
    int dj_0 = int(-2);
    for(;;)
    {
        if(dj_0 <= int(2))
        {
        }
        else
        {
            break;
        }
        oTop_9 = oTop_10;
        float oNext_10 = oNext_9;
        float kTop_11 = kTop_10;
        float kNext_11 = kNext_10;
        int di_0 = int(-2);
        for(;;)
        {
            if(di_0 <= int(2))
            {
            }
            else
            {
                break;
            }
            int2  slot_8 = _S337 + make_int2 (di_0, dj_0);
            ConvectionInput_0 _S339 = c_58;
            float _S340 = convVigour_0(&_S339, slot_8);
            if(_S340 <= 0.0f)
            {
                di_0 = di_0 + int(1);
                continue;
            }
            ConvectionInput_0 _S341 = c_58;
            float2  _S342 = convCellCentre_0(&_S341, slot_8);
            float2  d_18 = _S335 - _S342;
            float d2_5 = dot_0(d_18, d_18);
            float ko_3 = _S340 * convBump_0(d2_5, 0.75f);
            float kk_3 = _S340 * convBump_0(d2_5, 1.04999995231628418f);
            if((c_58.cvLacunarity_0) > 0.0f)
            {
                ConvectionInput_0 _S343 = c_58;
                convHole_0(&_S343, d_18, d2_5, _S340, &keep_3, &gKeep_4);
            }
            float oTop_11;
            float oNext_11;
            if(ko_3 > oTop_9)
            {
                oTop_11 = ko_3;
                oNext_11 = oTop_9;
            }
            else
            {
                if(ko_3 > oNext_10)
                {
                    oTop_11 = ko_3;
                }
                else
                {
                    oTop_11 = oNext_10;
                }
                float _S344 = oTop_11;
                oTop_11 = oTop_9;
                oNext_11 = _S344;
            }
            float kTop_12;
            float kNext_12;
            if(kk_3 > kTop_11)
            {
                kTop_12 = kk_3;
                kNext_12 = kTop_11;
            }
            else
            {
                if(kk_3 > kNext_11)
                {
                    kTop_12 = kk_3;
                }
                else
                {
                    kTop_12 = kNext_11;
                }
                float _S345 = kTop_12;
                kTop_12 = kTop_11;
                kNext_12 = _S345;
            }
            oTop_9 = oTop_11;
            oNext_10 = oNext_11;
            kTop_11 = kTop_12;
            kNext_11 = kNext_12;
            di_0 = di_0 + int(1);
        }
        int dj_1 = dj_0 + int(1);
        oTop_10 = oTop_9;
        oNext_9 = oNext_10;
        kTop_10 = kTop_11;
        kNext_10 = kNext_11;
        dj_0 = dj_1;
    }
    float w_6 = lerp_2((F32_min((oNext_9 / 0.31000000238418579f), (1.0f))), kTop_10 - kNext_10, c_58.cvPolarity_0);
    if((c_58.cvOrg_0.ogOn_0) != int(0))
    {
        float2  _S346 = __ldg((&(points_3)[i_19]));
        ConvectionInput_0 _S347 = c_58;
        float2  unused_1;
        float _S348 = convOrganize_0(&_S347, _S346, kTop_10, kNext_10, _S338, _S338, keep_3, gKeep_4, w_6, _S338, &unused_1);
        oTop_9 = _S348;
    }
    else
    {
        oTop_9 = w_6;
    }
    *(&(outUpdraft_1)[i_19]) = oTop_9;
    return;
}

