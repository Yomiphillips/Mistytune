// GENERATED FROM Bounce.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

static __device__ float3  cross_0(float3  left_0, float3  right_0)
{
    float _S1 = left_0.y;
    float _S2 = right_0.z;
    float _S3 = left_0.z;
    float _S4 = right_0.y;
    float _S5 = right_0.x;
    float _S6 = left_0.x;
    return make_float3 (_S1 * _S2 - _S3 * _S4, _S3 * _S5 - _S6 * _S2, _S6 * _S4 - _S1 * _S5);
}

static __device__ float dot_0(float3  x_0, float3  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y + x_0.z * y_0.z;
}

static __device__ float length_0(float3  x_1)
{
    return (F32_sqrt((dot_0(x_1, x_1))));
}

static __device__ float3  normalize_0(float3  x_2)
{
    return x_2 / make_float3 (length_0(x_2));
}

static __device__ bool any_0(bool3  x_3)
{
    bool result_0 = false;
    int i_0 = int(0);
    for(;;)
    {
        if(i_0 < int(3))
        {
        }
        else
        {
            break;
        }
        if(result_0)
        {
            result_0 = true;
        }
        else
        {
            result_0 = (bool((_slang_vector_get_element(x_3, i_0))));
        }
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ float3  max_0(float3  x_4, float3  y_1)
{
    float3  result_1;
    int i_1 = int(0);
    for(;;)
    {
        if(i_1 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_max((_slang_vector_get_element(x_4, i_1)), (_slang_vector_get_element(y_1, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ int StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    uint2  _S7 = make_uint2(_elementCount_0, _stride_0);
    return int(_S7.x);
}

static __device__ float3  lerp_0(float3  x_5, float3  y_2, float3  s_0)
{
    return x_5 + (y_2 - x_5) * s_0;
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

static __device__ float dot_1(float2  x_6, float2  y_3)
{
    return x_6.x * y_3.x + x_6.y * y_3.y;
}

static __device__ float3  floor_0(float3  x_7)
{
    float3  result_2;
    int i_2 = int(0);
    for(;;)
    {
        if(i_2 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_2, i_2) = (F32_floor((_slang_vector_get_element(x_7, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ uint3  pcg3d_0(uint3  v_0)
{
    uint3  _S8 = v_0 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S9 = _S8;
    *&((&_S9)->x) = *&((&_S9)->x) + _S8.y * _S8.z;
    *&((&_S9)->y) = *&((&_S9)->y) + _S9.z * _S9.x;
    *&((&_S9)->z) = *&((&_S9)->z) + _S9.x * _S9.y;
    uint3  _S10 = _S9 ^ (_S9 >> make_uint3 (16U));
    _S9 = _S10;
    *&((&_S9)->x) = *&((&_S9)->x) + _S10.y * _S10.z;
    *&((&_S9)->y) = *&((&_S9)->y) + _S9.z * _S9.x;
    *&((&_S9)->z) = *&((&_S9)->z) + _S9.x * _S9.y;
    return _S9;
}

static __device__ float3  hash33_0(int3  c_0)
{
    uint3  h_0 = pcg3d_0(make_uint3 (uint(c_0.x), uint(c_0.y), uint(c_0.z)));
    float3  _S11 = make_float3 ((float)h_0.x, (float)h_0.y, (float)h_0.z);
    return _S11 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float lerp_1(float x_8, float y_4, float s_1)
{
    return x_8 + (y_4 - x_8) * s_1;
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_0(p_0);
    int3  _S12 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S13 = u_0.x;
    float _S14 = u_0.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S12), f_0), dot_0(hash33_0(_S12 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S13), lerp_1(dot_0(hash33_0(_S12 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S12 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S13), _S14), lerp_1(lerp_1(dot_0(hash33_0(_S12 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S12 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S13), lerp_1(dot_0(hash33_0(_S12 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S12 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S13), _S14), u_0.z);
}

static __device__ float2  orgWarpOffset_0(Organization_0 * o_0, float2  g_0)
{
    float2  s_2 = g_0 / make_float2 (2.5f);
    float _S15 = s_2.x;
    float _S16 = s_2.y;
    return make_float2 (o_0->ogWarp_0) * make_float2 (gradientNoise_0(make_float3 (_S15, 0.37000000476837158f, _S16)), gradientNoise_0(make_float3 (_S15 + 17.10000038146972656f, 5.82999992370605469f, _S16 - 9.39999961853027344f)));
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
        float2  _S17 = orgWarpOffset_0(o_1, g_1);
        g_2 = g_1 + _S17;
    }
    else
    {
        g_2 = g_1;
    }
    return g_2;
}

static __device__ float2  floor_1(float2  x_9)
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
        *_slang_vector_get_element_ptr(&result_3, i_3) = (F32_floor((_slang_vector_get_element(x_9, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ uint2  pcg2d_0(uint2  v_1)
{
    uint2  _S18 = v_1 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S19 = _S18;
    *&((&_S19)->x) = *&((&_S19)->x) + _S18.y * 1664525U;
    *&((&_S19)->y) = *&((&_S19)->y) + _S19.x * 1664525U;
    uint2  _S20 = _S19 ^ (_S19 >> make_uint2 (16U));
    _S19 = _S20;
    *&((&_S19)->x) = *&((&_S19)->x) + _S20.y * 1664525U;
    *&((&_S19)->y) = *&((&_S19)->y) + _S19.x * 1664525U;
    uint2  _S21 = _S19 ^ (_S19 >> make_uint2 (16U));
    _S19 = _S21;
    return _S21;
}

static __device__ float2  hash22_0(int2  c_1, uint salt_0)
{
    uint2  h_1 = pcg2d_0(make_uint2 (uint(c_1.x), uint(c_1.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S22 = make_float2 ((float)h_1.x, (float)h_1.y);
    return _S22 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float convLife_0(float u_1)
{
    float _S23 = 1.0f - u_1;
    return 6.75f * u_1 * _S23 * _S23;
}

static __device__ float convVigour_0(ConvectionInput_0 * c_2, int2  slot_0)
{
    float2  h_2 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_2.y);
}

static __device__ float2  orgJitter_0(Organization_0 * o_2, float jitter_0)
{
    float _S24;
    if((o_2->ogOn_0) != int(0))
    {
        _S24 = jitter_0 * (1.0f - o_2->ogCoherence_0);
    }
    else
    {
        _S24 = jitter_0;
    }
    return make_float2 (jitter_0, _S24);
}

static __device__ float2  convCellCentre_0(ConvectionInput_0 * c_3, int2  slot_1)
{
    float2  j_0 = hash22_0(slot_1, 1759714724U) - make_float2 (0.5f);
    float2  _S25 = make_float2 ((float)slot_1.x, (float)slot_1.y);
    float2  _S26 = _S25 + make_float2 (0.5f);
    float2  _S27 = orgJitter_0(&c_3->cvOrg_0, 0.69999998807907104f);
    return _S26 + j_0 * _S27;
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

static __device__ float clamp_0(float x_10, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_10), (minBound_0)))), (maxBound_0)));
}

static __device__ float saturate_0(float x_11)
{
    return clamp_0(x_11, 0.0f, 1.0f);
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
        float2  _S28;
        if(dist_0 > 9.99999997475242708e-07f)
        {
            _S28 = d_0 * make_float2 (6.0f * t_1 * (1.0f - t_1) / (band_0 * dist_0));
        }
        else
        {
            _S28 = make_float2 (0.0f, 0.0f);
        }
        *gKeep_0 = _S28;
    }
    return;
}

static __device__ float2  lerp_2(float2  x_12, float2  y_5, float2  s_3)
{
    return x_12 + (y_5 - x_12) * s_3;
}

static __device__ float2  orgGradToWorld_0(Organization_0 * o_3, float2  gp_0, float spacing_1)
{
    if((o_3->ogOn_0) == int(0))
    {
        return gp_0 / make_float2 (spacing_1);
    }
    float2  s_4 = gp_0 / make_float2 (spacing_1 * o_3->ogStretch_0, spacing_1);
    return o_3->ogAxis_0 * make_float2 (s_4.x) + make_float2 (- o_3->ogAxis_0.y, o_3->ogAxis_0.x) * make_float2 (s_4.y);
}

static __device__ float orgWave_0(Organization_0 * o_4, float2  q_1, float2  * grad_0)
{
    *grad_0 = make_float2 (0.0f, 0.0f);
    bool _S29;
    if((o_4->ogOn_0) == int(0))
    {
        _S29 = true;
    }
    else
    {
        _S29 = (o_4->ogWaveAmp_0) <= 0.0f;
    }
    if(_S29)
    {
        return 1.0f;
    }
    float2  _S30 = o_4->ogWaveK_0;
    float s_5 = 2.0f * (F32_frac((dot_1(q_1, o_4->ogWaveK_0)))) - 1.0f;
    float tri_0 = 1.0f - (F32_abs((s_5)));
    float crest_0 = tri_0 * tri_0 * (3.0f - 2.0f * tri_0);
    float dCrest_0 = 6.0f * tri_0 * (1.0f - tri_0);
    float dTri_0;
    if(s_5 > 0.0f)
    {
        dTri_0 = -2.0f;
    }
    else
    {
        dTri_0 = 2.0f;
    }
    float _S31 = o_4->ogWaveAmp_0;
    *grad_0 = _S30 * make_float2 (o_4->ogWaveAmp_0 * dCrest_0 * dTri_0);
    return 1.0f - _S31 * (1.0f - crest_0);
}

static __device__ float convOrganize_0(ConvectionInput_0 * c_5, float2  q_2, float kTop_0, float kNext_0, float2  gkTop_0, float2  gkNext_0, float keep_1, float2  gKeep_1, float w_0, float2  gp_1, float2  * grad_1)
{
    float _S32 = c_5->cvLacunarity_0;
    float2  _S33;
    float _S34;
    if((c_5->cvLacunarity_0) > 0.0f)
    {
        float fill_0 = lerp_1(w_0, 0.40000000596046448f, _S32);
        float _S35 = fill_0 * keep_1;
        _S33 = gp_1 * make_float2 (1.0f - _S32) * make_float2 (keep_1) + gKeep_1 * make_float2 (fill_0);
        _S34 = _S35;
    }
    else
    {
        _S33 = gp_1;
        _S34 = w_0;
    }
    float _S36 = c_5->cvPolarity_0;
    bool _S37;
    if((c_5->cvPolarity_0) > 0.0f)
    {
        _S37 = (c_5->cvGapWidth_0) > 0.0f;
    }
    else
    {
        _S37 = false;
    }
    if(_S37)
    {
        float2  _S38 = make_float2 (0.0f, 0.0f);
        float2  gcn_0;
        float cn_0;
        if(kTop_0 > 0.0f)
        {
            float2  _S39 = (gkTop_0 * make_float2 (kNext_0) - gkNext_0 * make_float2 (kTop_0)) / make_float2 (kTop_0 * kTop_0);
            cn_0 = 1.0f - kNext_0 / kTop_0;
            gcn_0 = _S39;
        }
        else
        {
            cn_0 = 0.0f;
            gcn_0 = _S38;
        }
        float ramp_0 = 0.5f * c_5->cvGapWidth_0;
        float t_2 = saturate_0((cn_0 - ramp_0) / ramp_0);
        float s_6 = lerp_1(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S36);
        float _S40 = _S34 * s_6;
        _S33 = _S33 * make_float2 (s_6) + gcn_0 * make_float2 (_S34 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S36));
        _S34 = _S40;
    }
    float2  _S41 = orgGradToWorld_0(&c_5->cvOrg_0, _S33, c_5->cvSpacing_0);
    *grad_1 = _S41;
    float2  gm_0;
    float _S42 = orgWave_0(&c_5->cvOrg_0, q_2, &gm_0);
    *grad_1 = _S41 * make_float2 (_S42) + gm_0 * make_float2 (_S34);
    return _S34 * _S42;
}

static __device__ float convUpdraftGradT_0(ConvectionInput_0 * c_6, float2  q_3, float2  * grad_2)
{
    float2  goTop_0;
    float2  _S43 = orgPattern_0(&c_6->cvOrg_0, q_3, c_6->cvSpacing_0);
    float2  _S44 = floor_1(_S43);
    int2  _S45 = make_int2 ((int)_S44.x, (int)_S44.y);
    float2  _S46 = make_float2 (0.0f, 0.0f);
    float keep_2 = 1.0f;
    float2  gKeep_2 = _S46;
    float oTop_0 = 0.0f;
    float2  goTop_1 = _S46;
    float oNext_0 = 0.0f;
    float kTop_1 = 0.0f;
    float2  gkTop_1 = _S46;
    float kNext_1 = 0.0f;
    float2  goNext_0 = _S46;
    float2  gkNext_1 = _S46;
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
        int i_4 = int(-1);
        for(;;)
        {
            if(i_4 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_2 = _S45 + make_int2 (i_4, j_1);
            float _S47 = convVigour_0(c_6, slot_2);
            if(_S47 <= 0.0f)
            {
                i_4 = i_4 + int(1);
                continue;
            }
            float2  _S48 = convCellCentre_0(c_6, slot_2);
            float2  d_1 = _S43 - _S48;
            float d2_2 = dot_1(d_1, d_1);
            float ko_0 = _S47 * convBump_0(d2_2, 0.75f);
            float kk_0 = _S47 * convBump_0(d2_2, 1.04999995231628418f);
            convHole_0(c_6, d_1, d2_2, _S47, &keep_2, &gKeep_2);
            float2  gko_0;
            if(d2_2 < 0.5625f)
            {
                gko_0 = d_1 * make_float2 (-4.0f * _S47 * (1.0f - d2_2 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S46;
            }
            float2  gkk_0;
            if(d2_2 < 1.10249984264373779f)
            {
                gkk_0 = d_1 * make_float2 (-4.0f * _S47 * (1.0f - d2_2 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S46;
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
                float _S49 = oTop_2;
                float2  _S50 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S49;
                goNext_2 = _S50;
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
                float _S51 = kTop_3;
                float2  _S52 = gkTop_3;
                kTop_3 = kTop_2;
                gkTop_3 = gkTop_2;
                kNext_3 = _S51;
                gkNext_3 = _S52;
            }
            oTop_1 = oTop_2;
            goTop_0 = goTop_2;
            oNext_1 = oNext_2;
            kTop_2 = kTop_3;
            gkTop_2 = gkTop_3;
            kNext_2 = kNext_3;
            goNext_1 = goNext_2;
            gkNext_2 = gkNext_3;
            i_4 = i_4 + int(1);
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
    float _S53 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_1 - kNext_1;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_0 = _S46;
    }
    float2  gClosed_0 = gkTop_1 - gkNext_1;
    float _S54 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_1(_S53, closedField_0, c_6->cvPolarity_0), lerp_2(goTop_0, gClosed_0, make_float2 (c_6->cvPolarity_0)), grad_2);
    return _S54;
}

static __device__ float convUpdraftGradT_1(ConvectionInput_0 * c_7, float2  q_4, float2  * grad_3)
{
    float2  goTop_3;
    float2  _S55 = orgPattern_0(&c_7->cvOrg_0, q_4, c_7->cvSpacing_0);
    float2  _S56 = floor_1(_S55);
    int2  _S57 = make_int2 ((int)_S56.x, (int)_S56.y);
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
            int2  slot_3 = _S57 + make_int2 (i_5, j_3);
            float _S58 = convVigour_0(c_7, slot_3);
            if(_S58 <= 0.0f)
            {
                i_5 = i_5 + int(1);
                continue;
            }
            float2  _S59 = convCellCentre_0(c_7, slot_3);
            float2  d_2 = _S55 - _S59;
            float d2_3 = dot_1(d_2, d_2);
            float ko_1 = _S58 * convBump_0(d2_3, 0.75f);
            float kk_1 = _S58 * convBump_0(d2_3, 1.04999995231628418f);
            float2  gko_1;
            if(d2_3 < 0.5625f)
            {
                gko_1 = d_2 * make_float2 (-4.0f * _S58 * (1.0f - d2_3 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_1 = gKeep_3;
            }
            float2  gkk_1;
            if(d2_3 < 1.10249984264373779f)
            {
                gkk_1 = d_2 * make_float2 (-4.0f * _S58 * (1.0f - d2_3 / 1.10249984264373779f) / 1.10249984264373779f);
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
                float _S60 = oTop_5;
                float2  _S61 = goTop_5;
                oTop_5 = oTop_4;
                goTop_5 = goTop_3;
                oNext_5 = _S60;
                goNext_5 = _S61;
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
                float _S62 = kTop_6;
                float2  _S63 = gkTop_6;
                kTop_6 = kTop_5;
                gkTop_6 = gkTop_5;
                kNext_6 = _S62;
                gkNext_6 = _S63;
            }
            oTop_4 = oTop_5;
            goTop_3 = goTop_5;
            oNext_4 = oNext_5;
            kTop_5 = kTop_6;
            gkTop_5 = gkTop_6;
            kNext_5 = kNext_6;
            goNext_4 = goNext_5;
            gkNext_5 = gkNext_6;
            i_5 = i_5 + int(1);
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
    float _S64 = (F32_min((openRaw_1), (1.0f)));
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
    float _S65 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_1(_S64, closedField_1, c_7->cvPolarity_0), lerp_2(goTop_3, gClosed_1, make_float2 (c_7->cvPolarity_0)), grad_3);
    return _S65;
}

static __device__ float2  convCellCentrePlain_0(int2  slot_4)
{
    float2  _S66 = make_float2 ((float)slot_4.x, (float)slot_4.y);
    return _S66 + make_float2 (0.5f) + (hash22_0(slot_4, 1759714724U) - make_float2 (0.5f)) * make_float2 (0.69999998807907104f);
}

static __device__ float convUpdraftGradT_2(ConvectionInput_0 * c_8, float2  q_5, float2  * grad_4)
{
    float2  goTop_6;
    float _S67 = c_8->cvSpacing_0;
    float2  _S68 = q_5 / make_float2 (c_8->cvSpacing_0);
    float2  _S69 = floor_1(_S68);
    int2  _S70 = make_int2 ((int)_S69.x, (int)_S69.y);
    float2  _S71 = make_float2 (0.0f, 0.0f);
    float oTop_6 = 0.0f;
    float2  goTop_7 = _S71;
    float oNext_6 = 0.0f;
    float kTop_7 = 0.0f;
    float2  gkTop_7 = _S71;
    float kNext_7 = 0.0f;
    float2  goNext_6 = _S71;
    float2  gkNext_7 = _S71;
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
            int2  slot_5 = _S70 + make_int2 (i_6, j_5);
            float _S72 = convVigour_0(c_8, slot_5);
            if(_S72 <= 0.0f)
            {
                i_6 = i_6 + int(1);
                continue;
            }
            float2  d_3 = _S68 - convCellCentrePlain_0(slot_5);
            float d2_4 = dot_1(d_3, d_3);
            float ko_2 = _S72 * convBump_0(d2_4, 0.75f);
            float kk_2 = _S72 * convBump_0(d2_4, 1.04999995231628418f);
            float2  gko_2;
            if(d2_4 < 0.5625f)
            {
                gko_2 = d_3 * make_float2 (-4.0f * _S72 * (1.0f - d2_4 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_2 = _S71;
            }
            float2  gkk_2;
            if(d2_4 < 1.10249984264373779f)
            {
                gkk_2 = d_3 * make_float2 (-4.0f * _S72 * (1.0f - d2_4 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_2 = _S71;
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
                float _S73 = oTop_8;
                float2  _S74 = goTop_8;
                oTop_8 = oTop_7;
                goTop_8 = goTop_6;
                oNext_8 = _S73;
                goNext_8 = _S74;
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
                float _S75 = kTop_9;
                float2  _S76 = gkTop_9;
                kTop_9 = kTop_8;
                gkTop_9 = gkTop_8;
                kNext_9 = _S75;
                gkNext_9 = _S76;
            }
            oTop_7 = oTop_8;
            goTop_6 = goTop_8;
            oNext_7 = oNext_8;
            kTop_8 = kTop_9;
            gkTop_8 = gkTop_9;
            kNext_8 = kNext_9;
            goNext_7 = goNext_8;
            gkNext_8 = gkNext_9;
            i_6 = i_6 + int(1);
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
    float _S77 = (F32_min((openRaw_2), (1.0f)));
    float closedField_2 = kTop_7 - kNext_7;
    if(openRaw_2 < 1.0f)
    {
        goTop_6 = goNext_6 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_6 = _S71;
    }
    float2  gClosed_2 = gkTop_7 - gkNext_7;
    float _S78 = c_8->cvPolarity_0;
    *grad_4 = lerp_2(goTop_6, gClosed_2, make_float2 (c_8->cvPolarity_0)) / make_float2 (_S67);
    return lerp_1(_S77, closedField_2, _S78);
}

static __device__ bool any_1(bool2  x_13)
{
    bool result_4 = false;
    int i_7 = int(0);
    for(;;)
    {
        if(i_7 < int(2))
        {
        }
        else
        {
            break;
        }
        if(result_4)
        {
            result_4 = true;
        }
        else
        {
            result_4 = (bool((_slang_vector_get_element(x_13, i_7))));
        }
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static __device__ int clamp_1(int x_14, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_14), (minBound_1)))), (maxBound_1)));
}

static __device__ float4  lerp_3(float4  x_15, float4  y_6, float4  s_7)
{
    return x_15 + (y_6 - x_15) * s_7;
}

static __device__ int2  min_0(int2  x_16, int2  y_7)
{
    int2  result_5;
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
        *_slang_vector_get_element_ptr(&result_5, i_8) = (I32_min((_slang_vector_get_element(x_16, i_8)), (_slang_vector_get_element(y_7, i_8))));
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static __device__ float2  max_1(float2  x_17, float2  y_8)
{
    float2  result_6;
    int i_9 = int(0);
    for(;;)
    {
        if(i_9 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_6, i_9) = (F32_max((_slang_vector_get_element(x_17, i_9)), (_slang_vector_get_element(y_8, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static __device__ float2  min_1(float2  x_18, float2  y_9)
{
    float2  result_7;
    int i_10 = int(0);
    for(;;)
    {
        if(i_10 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_7, i_10) = (F32_min((_slang_vector_get_element(x_18, i_10)), (_slang_vector_get_element(y_9, i_10))));
        i_10 = i_10 + int(1);
    }
    return result_7;
}

static __device__ float2  clamp_2(float2  x_19, float2  minBound_2, float2  maxBound_2)
{
    return min_1(max_1(x_19, minBound_2), maxBound_2);
}

static __device__ float length_1(float2  x_20)
{
    return (F32_sqrt((dot_1(x_20, x_20))));
}

static __device__ float2  abs_0(float2  x_21)
{
    float2  result_8;
    int i_11 = int(0);
    for(;;)
    {
        if(i_11 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_8, i_11) = (F32_abs((_slang_vector_get_element(x_21, i_11))));
        i_11 = i_11 + int(1);
    }
    return result_8;
}

static __device__ bool all_0(bool2  x_22)
{
    bool result_9 = true;
    int i_12 = int(0);
    for(;;)
    {
        if(i_12 < int(2))
        {
        }
        else
        {
            break;
        }
        if(result_9)
        {
            result_9 = (bool((_slang_vector_get_element(x_22, i_12))));
        }
        else
        {
            result_9 = false;
        }
        i_12 = i_12 + int(1);
    }
    return result_9;
}

static __device__ float smoothstep_0(float min_2, float max_2, float x_23)
{
    float _S79 = saturate_0((x_23 - min_2) / (max_2 - min_2));
    return _S79 * _S79 * (3.0f - (_S79 + _S79));
}

struct Rng_0
{
    uint state_0;
};

static __device__ Rng_0 makeRng_0(uint seed_0)
{
    Rng_0 r_1;
    (&r_1)->state_0 = seed_0;
    return r_1;
}

static __device__ Rng_0 makeRngForIndex_0(uint seed_1, int index_0)
{
    uint s_8 = uint(index_0) * 747796405U + 2891336453U;
    uint s_9 = ((s_8 >> ((s_8 >> 28U) + 4U)) ^ s_8) * 277803737U;
    return makeRng_0(((s_9 >> 22U) ^ s_9) ^ seed_1);
}

static __device__ Rng_0 splitRng_0(Rng_0 * r_2, uint salt_1)
{
    uint s_10 = ((r_2->state_0) ^ (salt_1 * 2654435761U)) * 747796405U + 2891336453U;
    uint s_11 = ((s_10 >> ((s_10 >> 28U) + 4U)) ^ s_10) * 277803737U;
    return makeRng_0((s_11 >> 22U) ^ s_11);
}

static __device__ bool clipAxis_0(float o_5, float d_4, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_4))) < 9.99999971718068537e-10f)
    {
        bool _S80;
        if(o_5 >= lo_0)
        {
            _S80 = o_5 <= hi_0;
        }
        else
        {
            _S80 = false;
        }
        return _S80;
    }
    float ta_0 = (lo_0 - o_5) / d_4;
    float tb_0 = (hi_0 - o_5) / d_4;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S81 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S81;
    return _S81 > (*t0_0);
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

static __device__ bool slabRange_0(Medium_0 * m_0, float3  ro_0, float3  rd_0, float * t0_1, float * t1_1)
{
    *t0_1 = 0.0f;
    *t1_1 = 1.0e+09f;
    float _S82 = rd_0.y;
    bool _S83;
    if((F32_abs((_S82))) < 9.99999997475242708e-07f)
    {
        float _S84 = ro_0.y;
        if(_S84 < (m_0->slabBottom_0))
        {
            _S83 = true;
        }
        else
        {
            _S83 = _S84 > (m_0->slabTop_0);
        }
        if(_S83)
        {
            return false;
        }
    }
    else
    {
        float _S85 = ro_0.y;
        float ta_1 = (m_0->slabBottom_0 - _S85) / _S82;
        float tb_1 = (m_0->slabTop_0 - _S85) / _S82;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S86 = (m_0->clipOn_0) != int(0);
    float2  lo_1;
    if(_S86)
    {
        lo_1 = m_0->clipLo_0;
    }
    else
    {
        lo_1 = make_float2 (-1.0e+09f, -1.0e+09f);
    }
    float2  hi_1;
    if(_S86)
    {
        hi_1 = m_0->clipHi_0;
    }
    else
    {
        hi_1 = make_float2 (1.0e+09f, 1.0e+09f);
    }
    float _S87 = m_0->fadeRadius_0;
    if((m_0->fadeRadius_0) > 0.0f)
    {
        float2  _S88 = min_1(hi_1, m_0->fadeAt_0 + make_float2 (_S87));
        lo_1 = max_1(lo_1, m_0->fadeAt_0 - make_float2 (_S87));
        hi_1 = _S88;
    }
    bool _S89 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S89)
    {
        return false;
    }
    bool _S90 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S90)
    {
        return false;
    }
    float _S91 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S91;
    if(_S91 > (*t0_1))
    {
        _S83 = (*t1_1) > 0.0f;
    }
    else
    {
        _S83 = false;
    }
    return _S83;
}

struct Dda_0
{
    int3  cell_0;
    int3  stepDir_0;
    float3  tMax_0;
    float3  tDelta_0;
};

struct MajorantGrid_0
{
    float3  origin_0;
    float3  cellExtent_0;
    int3  dims_0;
    int enabled_0;
};

static __device__ Dda_0 ddaInit_0(MajorantGrid_0 * g_3, float3  ro_1, float3  rd_1, float t_3)
{
    Dda_0 d_5;
    if((g_3->enabled_0) == int(0))
    {
        int3  _S92 = make_int3 (int(0), int(0), int(0));
        (&d_5)->cell_0 = _S92;
        (&d_5)->stepDir_0 = _S92;
        float3  _S93 = make_float3 (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_5)->tMax_0 = _S93;
        (&d_5)->tDelta_0 = _S93;
        return d_5;
    }
    float3  p_1 = ro_1 + rd_1 * make_float3 (t_3);
    float3  _S94 = floor_0((p_1 - g_3->origin_0) / g_3->cellExtent_0);
    int3  _S95 = make_int3 ((int)_S94.x, (int)_S94.y, (int)_S94.z);
    (&d_5)->cell_0 = _S95;
    int a_0 = int(0);
    for(;;)
    {
        if(a_0 < int(3))
        {
        }
        else
        {
            break;
        }
        int _S96 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            *_slang_vector_get_element_ptr(&(&d_5)->stepDir_0, a_0) = int(0);
            *_slang_vector_get_element_ptr(&(&d_5)->tMax_0, a_0) = 1.00000001504746622e+30f;
            *_slang_vector_get_element_ptr(&(&d_5)->tDelta_0, a_0) = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S97 = _slang_vector_get_element(rd_1, _S96) > 0.0f;
            int _S98;
            if(_S97)
            {
                _S98 = int(1);
            }
            else
            {
                _S98 = int(-1);
            }
            *_slang_vector_get_element_ptr(&(&d_5)->stepDir_0, a_0) = _S98;
            float _S99 = *_slang_vector_get_element_ptr(&g_3->origin_0, a_0);
            float _S100 = float(*_slang_vector_get_element_ptr(&(&d_5)->cell_0, a_0));
            float _S101;
            if(_S97)
            {
                _S101 = 1.0f;
            }
            else
            {
                _S101 = 0.0f;
            }
            *_slang_vector_get_element_ptr(&(&d_5)->tMax_0, a_0) = t_3 + (_S99 + (_S100 + _S101) * *_slang_vector_get_element_ptr(&g_3->cellExtent_0, a_0) - _slang_vector_get_element(p_1, a_0)) / _slang_vector_get_element(rd_1, _S96);
            *_slang_vector_get_element_ptr(&(&d_5)->tDelta_0, a_0) = (F32_abs((*_slang_vector_get_element_ptr(&g_3->cellExtent_0, a_0) / _slang_vector_get_element(rd_1, _S96))));
        }
        a_0 = a_0 + int(1);
    }
    return d_5;
}

static __device__ float convCapCeiling_0(ConvectionInput_0 * c_9)
{
    float _S102 = c_9->cvHeroTop_0;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        return 0.0f;
    }
    float _S103 = c_9->cvPileusThick_0;
    float cap_0;
    if((c_9->cvPileusThick_0) > 0.0f)
    {
        cap_0 = _S102 + c_9->cvPileusGap_0 + _S103;
    }
    else
    {
        cap_0 = 0.0f;
    }
    float _S104 = c_9->cvVelumThick_0;
    float veil_0;
    if((c_9->cvVelumThick_0) > 0.0f)
    {
        veil_0 = c_9->cvVelumHeight_0 + 1.5f * _S104;
    }
    else
    {
        veil_0 = 0.0f;
    }
    return (F32_max((cap_0), (veil_0)));
}

static __device__ float convCeiling_0(ConvectionInput_0 * c_10)
{
    float _S105 = c_10->cvBillow_0;
    float field_0 = c_10->cvDepth_0 + c_10->cvBillow_0;
    float _S106 = c_10->cvHeroTop_0;
    float hero_0;
    if((c_10->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S106 + _S105 * c_10->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    float _S107 = (F32_max((field_0), (hero_0)));
    float _S108 = convCapCeiling_0(c_10);
    return (F32_max((_S107), (_S108)));
}

static __device__ float convDomeHeight_0(float top_0, float radius_0, float shape_0, float r_3)
{
    bool _S109;
    if(top_0 <= 0.0f)
    {
        _S109 = true;
    }
    else
    {
        _S109 = r_3 >= radius_0;
    }
    if(_S109)
    {
        return 0.0f;
    }
    return top_0 * (F32_pow((1.0f - r_3 * r_3 / (radius_0 * radius_0)), (shape_0)));
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_11, float r_4)
{
    return convDomeHeight_0(c_11->cvHeroTop_0, c_11->cvHeroRadius_0, c_11->cvShape_0, r_4);
}

static __device__ float convCapBound_0(ConvectionInput_0 * c_12, float3  lo_2, float3  hi_2, float low_0, float high_0)
{
    float2  nearGap_0 = max_1(max_1(float2 {lo_2.x, lo_2.z} - c_12->cvHeroAt_0, c_12->cvHeroAt_0 - float2 {hi_2.x, hi_2.z}), make_float2 (0.0f, 0.0f));
    float gap2_0 = dot_1(nearGap_0, nearGap_0);
    float _S110 = c_12->cvHeroRadius_0;
    float _S111 = c_12->cvPileusThick_0;
    bool _S112;
    float best_0;
    if((c_12->cvPileusThick_0) > 0.0f)
    {
        float rp_0 = 0.60000002384185791f * _S110;
        float _S113 = c_12->cvPileusGap_0;
        float _S114 = convHeroHeight_0(c_12, rp_0 * 0.60000002384185791f);
        float _S115 = 0.5f * _S111;
        float bottom_0 = _S113 + _S114 - _S115;
        float top_1 = _S113 + c_12->cvHeroTop_0 + _S115;
        if(gap2_0 < (rp_0 * rp_0))
        {
            _S112 = high_0 >= bottom_0;
        }
        else
        {
            _S112 = false;
        }
        if(_S112)
        {
            _S112 = low_0 <= top_1;
        }
        else
        {
            _S112 = false;
        }
        if(_S112)
        {
            best_0 = (F32_max((0.0f), (0.44999998807907104f)));
        }
        else
        {
            best_0 = 0.0f;
        }
    }
    else
    {
        best_0 = 0.0f;
    }
    float _S116 = c_12->cvVelumThick_0;
    if((c_12->cvVelumThick_0) > 0.0f)
    {
        float ext_0 = 1.89999997615814209f * _S110;
        float bottom_1 = c_12->cvVelumHeight_0 - 0.5f * _S116;
        float top_2 = c_12->cvVelumHeight_0 + _S116;
        if(gap2_0 < (ext_0 * ext_0))
        {
            _S112 = high_0 >= bottom_1;
        }
        else
        {
            _S112 = false;
        }
        if(_S112)
        {
            _S112 = low_0 <= top_2;
        }
        else
        {
            _S112 = false;
        }
        if(_S112)
        {
            best_0 = (F32_max((best_0), (0.2199999988079071f)));
        }
    }
    return c_12->cvSigma_0 * best_0 * 1.00001001358032227f;
}

static __device__ float convLift_0(ConvectionInput_0 * c_13, float above_0, float k_1)
{
    return (F32_min((c_13->cvBillow_0 * k_1 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_1(0.60000002384185791f, 1.0f, saturate_0(above_0 / (F32_max((c_13->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_0), (0.0f))))));
}

static __device__ void orgPatternBox_0(Organization_0 * o_6, float2  q0_0, float2  q1_0, float spacing_2, float2  * a_1, float2  * b_0)
{
    if((o_6->ogOn_0) == int(0))
    {
        *a_1 = q0_0 / make_float2 (spacing_2);
        *b_0 = q1_0 / make_float2 (spacing_2);
        return;
    }
    Organization_0 flat_0 = *o_6;
    (&flat_0)->ogWarp_0 = 0.0f;
    Organization_0 _S117 = flat_0;
    float2  _S118 = orgPattern_0(&_S117, q0_0, spacing_2);
    Organization_0 _S119 = flat_0;
    float2  _S120 = orgPattern_0(&_S119, q1_0, spacing_2);
    float2  _S121 = make_float2 (q0_0.x, q1_0.y);
    Organization_0 _S122 = flat_0;
    float2  _S123 = orgPattern_0(&_S122, _S121, spacing_2);
    float2  _S124 = make_float2 (q1_0.x, q0_0.y);
    Organization_0 _S125 = flat_0;
    float2  _S126 = orgPattern_0(&_S125, _S124, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S118.x)))), ((F32_abs((_S118.y))))))), ((F32_max(((F32_abs((_S120.x)))), ((F32_abs((_S120.y)))))))));
    *a_1 = min_1(min_1(_S118, _S123), min_1(_S126, _S120)) - make_float2 (grow_0);
    *b_0 = max_1(max_1(_S118, _S123), max_1(_S126, _S120)) + make_float2 (grow_0);
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_14, int2  slot_6, float2  a_2, float2  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S127 = convVigour_0(c_14, slot_6);
    if(_S127 <= 0.0f)
    {
        return;
    }
    float2  _S128 = convCellCentre_0(c_14, slot_6);
    float2  _S129 = a_2 - _S128;
    float2  nearGap_1 = max_1(max_1(_S129, _S128 - b_1), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_1, nearGap_1);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_1(abs_0(_S129), abs_0(b_1 - _S128));
    float oHi_0 = _S127 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S127 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S127 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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

static __device__ float convUpdraftBound_0(ConvectionInput_0 * c_15, float2  q0_1, float2  q1_1)
{
    float2  a_3;
    float2  b_2;
    orgPatternBox_0(&c_15->cvOrg_0, q0_1, q1_1, c_15->cvSpacing_0, &a_3, &b_2);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    float2  _S130 = floor_1((a_3 + b_2) * make_float2 (0.5f));
    int2  _S131 = make_int2 ((int)_S130.x, (int)_S130.y);
    float2  _S132 = make_float2 ((float)_S131.x, (float)_S131.y);
    float2  highEdge_0 = _S132 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S133;
    if(all_0(a_3 >= (_S132 - make_float2 (0.00009999999747379f))))
    {
        _S133 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S133 = false;
    }
    int j_7;
    int i_13;
    if(_S133)
    {
        j_7 = int(-1);
        for(;;)
        {
            if(j_7 <= int(1))
            {
            }
            else
            {
                break;
            }
            i_13 = int(-1);
            for(;;)
            {
                if(i_13 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, _S131 + make_int2 (i_13, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_13 = i_13 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        float2  _S134 = floor_1(a_3);
        int2  _S135 = make_int2 ((int)_S134.x, (int)_S134.y);
        int2  _S136 = make_int2 (int(1), int(1));
        int2  i0_0 = _S135 - _S136;
        float2  _S137 = floor_1(b_2);
        int2  _S138 = make_int2 ((int)_S137.x, (int)_S137.y);
        int2  _S139 = _S138 + _S136;
        int _S140 = i0_0.y;
        j_7 = _S140;
        for(;;)
        {
            if(j_7 <= (_S139.y))
            {
                _S133 = j_7 <= (_S140 + int(32));
            }
            else
            {
                _S133 = false;
            }
            if(_S133)
            {
            }
            else
            {
                break;
            }
            int _S141 = i0_0.x;
            i_13 = _S141;
            for(;;)
            {
                bool _S142;
                if(i_13 <= (_S139.x))
                {
                    _S142 = i_13 <= (_S141 + int(32));
                }
                else
                {
                    _S142 = false;
                }
                if(_S142)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, make_int2 (i_13, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_13 = i_13 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_1((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_15->cvPolarity_0);
    float _S143 = c_15->cvLacunarity_0;
    float field_2;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_1(field_1, 0.40000000596046448f, _S143);
    }
    else
    {
        field_2 = field_1;
    }
    return field_2 + 0.00000999999974738f;
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

static __device__ float convNeededUpdraft_0(ConvectionInput_0 * c_17, float above_1)
{
    float cover_1 = clamp_0(c_17->cvCoverage_0, 0.0f, 1.0f);
    bool _S144;
    if(cover_1 <= 0.0f)
    {
        _S144 = true;
    }
    else
    {
        _S144 = (c_17->cvDepth_0) <= 0.0f;
    }
    if(_S144)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_17->cvDepth_0), (1.0f / (F32_max((c_17->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_18)
{
    float _S145 = c_18->cvSpacing_0;
    float cap_1 = 7.0f / c_18->cvSpacing_0;
    if(((&c_18->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_1;
    }
    float _S146 = c_18->cvLacunarity_0;
    float cap_2;
    if((c_18->cvLacunarity_0) > 0.0f)
    {
        cap_2 = cap_1 + 1.5f / (0.15000000596046448f * _S146 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S145);
    }
    else
    {
        cap_2 = cap_1;
    }
    float _S147 = c_18->cvGapWidth_0;
    if((c_18->cvGapWidth_0) > 0.0f)
    {
        cap_2 = cap_2 + 14.25f * c_18->cvPolarity_0 / (0.5f * _S147 * _S145);
    }
    return cap_2 + 3.0f * (&c_18->cvOrg_0)->ogWaveAmp_0 * length_1((&c_18->cvOrg_0)->ogWaveK_0);
}

static __device__ float4  convTurret_0(ConvectionInput_0 * c_19, int k_2)
{
    if(k_2 == int(0))
    {
        return c_19->cvTurret0_0;
    }
    if(k_2 == int(1))
    {
        return c_19->cvTurret1_0;
    }
    if(k_2 == int(2))
    {
        return c_19->cvTurret2_0;
    }
    if(k_2 == int(3))
    {
        return c_19->cvTurret3_0;
    }
    return c_19->cvTurret4_0;
}

static __device__ float convMoatSlopeOver_0(ConvectionInput_0 * c_20, float2  lo_3, float2  hi_3)
{
    float slope_0 = 0.0f;
    int k_3 = int(-1);
    for(;;)
    {
        if(k_3 < int(5))
        {
        }
        else
        {
            break;
        }
        if(k_3 >= (c_20->cvTurretCount_0))
        {
            break;
        }
        float4  t_4;
        if(k_3 < int(0))
        {
            t_4 = make_float4 (c_20->cvHeroAt_0.x, c_20->cvHeroAt_0.y, c_20->cvHeroRadius_0, c_20->cvHeroTop_0);
        }
        else
        {
            float4  _S148 = convTurret_0(c_20, k_3);
            t_4 = _S148;
        }
        float4  _S149 = t_4;
        float2  _S150 = float2 {_S149.x, _S149.y};
        float2  gap_0 = max_1(max_1(lo_3 - _S150, _S150 - hi_3), make_float2 (0.0f, 0.0f));
        float _S151 = t_4.z;
        float outer_0 = 1.29999995231628418f * _S151;
        float band_1 = outer_0 - 0.75f * _S151;
        if((dot_1(gap_0, gap_0)) < (outer_0 * outer_0))
        {
            slope_0 = (F32_max((slope_0), (1.5f / band_1)));
        }
        k_3 = k_3 + int(1);
    }
    return slope_0 * c_20->cvMoat_0;
}

static __device__ float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S152;
    if(vMin_0 <= 0.0f)
    {
        _S152 = true;
    }
    else
    {
        _S152 = hMin_0 <= 0.0f;
    }
    if(_S152)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_21)
{
    return c_21->cvHeroRadius_0 + 1.5f * c_21->cvBillow_0 * c_21->cvHeroBillow_0 + 24.0f;
}

static __device__ float convShapeReach_0(ConvectionInput_0 * c_22)
{
    float lift_0 = 1.5f * c_22->cvBillow_0 * c_22->cvHeroBillow_0 + 24.0f;
    return length_1(make_float2 (c_22->cvShapeHalfWidth_0 + lift_0, c_22->cvShapeRound_0 + c_22->cvReliefHeight_0 + lift_0));
}

static __device__ float convHeroReachAll_0(ConvectionInput_0 * c_23)
{
    float _S153 = convHeroReach_0(c_23);
    float _S154;
    if((c_23->cvShapeOn_0) != int(0))
    {
        float _S155 = convShapeReach_0(c_23);
        _S154 = (F32_max((_S153), (_S155)));
    }
    else
    {
        _S154 = _S153;
    }
    return _S154;
}

static __device__ float convDomeRadiusAt_0(float top_3, float radius_1, float shape_1, float above_2)
{
    bool _S156;
    if(top_3 <= 0.0f)
    {
        _S156 = true;
    }
    else
    {
        _S156 = above_2 >= top_3;
    }
    if(_S156)
    {
        return -1.0f;
    }
    return radius_1 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / top_3), (1.0f / (F32_max((shape_1), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_24, float above_3)
{
    return convDomeRadiusAt_0(c_24->cvHeroTop_0, c_24->cvHeroRadius_0, c_24->cvShape_0, above_3);
}

static __device__ float4  convShapeTexel_0(ConvectionInput_0 * c_25, int i_14, int j_8)
{
    int k_4 = (j_8 * c_25->cvShapeDim_0.x + i_14) * int(4);
    StructuredBuffer<float> _S157 = c_25->cvShapeMap_0;
    float _S158 = __ldg((&(c_25->cvShapeMap_0)[k_4]));
    float _S159 = __ldg((&(_S157)[k_4 + int(1)]));
    float _S160 = __ldg((&(_S157)[k_4 + int(2)]));
    float _S161 = __ldg((&(_S157)[k_4 + int(3)]));
    return make_float4 (_S158, _S159, _S160, _S161);
}

static __device__ float convShapeDistance_0(ConvectionInput_0 * c_26, float u_3, float y_10, float2  * slopeUY_0, float * relief_0)
{
    float _S162 = c_26->cvShapeTexel_0;
    float2  st_0 = make_float2 (u_3, y_10) / make_float2 (c_26->cvShapeTexel_0) + c_26->cvShapeOffset_0 - make_float2 (0.5f);
    int2  _S163 = make_int2 (int(1), int(1));
    int2  last_0 = c_26->cvShapeDim_0 - _S163;
    float2  _S164 = make_float2 ((float)last_0.x, (float)last_0.y);
    float2  q_6 = clamp_2(st_0, make_float2 (0.0f, 0.0f), _S164);
    float past_0 = length_1(st_0 - q_6);
    float2  f0_0 = floor_1(q_6);
    int2  _S165 = make_int2 ((int)f0_0.x, (int)f0_0.y);
    int2  i0_1 = min_0(_S165, last_0);
    int2  i1_0 = min_0(i0_1 + _S163, last_0);
    float2  fr_0 = q_6 - f0_0;
    int _S166 = i0_1.x;
    int _S167 = i0_1.y;
    float4  _S168 = convShapeTexel_0(c_26, _S166, _S167);
    int _S169 = i1_0.x;
    float4  _S170 = convShapeTexel_0(c_26, _S169, _S167);
    int _S171 = i1_0.y;
    float4  _S172 = convShapeTexel_0(c_26, _S166, _S171);
    float4  _S173 = convShapeTexel_0(c_26, _S169, _S171);
    float4  _S174 = make_float4 (fr_0.x);
    float4  blend_0 = lerp_3(lerp_3(_S168, _S170, _S174), lerp_3(_S172, _S173, _S174), make_float4 (fr_0.y));
    *slopeUY_0 = float2 {blend_0.y, blend_0.z};
    *relief_0 = blend_0.w;
    return (blend_0.x - past_0) * _S162;
}

static __device__ float convShapeProfile_0(float dIn_0, float m_1, float rimR_0, float2  * stepDM_0)
{
    if(dIn_0 >= rimR_0)
    {
        *stepDM_0 = make_float2 (0.0f, rimR_0 - m_1);
        return m_1 - rimR_0;
    }
    float2  w_2 = make_float2 (dIn_0 - rimR_0, m_1);
    float len_0 = length_1(w_2);
    float gap_1 = len_0 - rimR_0;
    float2  _S175;
    if(len_0 > 9.99999997475242708e-07f)
    {
        _S175 = w_2 * make_float2 (- gap_1 / len_0);
    }
    else
    {
        _S175 = make_float2 (0.0f, rimR_0);
    }
    *stepDM_0 = _S175;
    return gap_1;
}

static __device__ float convShapeBound_0(ConvectionInput_0 * c_27, float3  lo_4, float3  hi_4, float low_1, float high_1)
{
    float2  ea_0 = float2 {lo_4.x, lo_4.z} - c_27->cvHeroAt_0;
    float2  eb_0 = float2 {hi_4.x, hi_4.z} - c_27->cvHeroAt_0;
    float _S176 = c_27->cvShapeAxisU_0.y;
    float _S177 = - _S176;
    float _S178 = c_27->cvShapeAxisU_0.x;
    float _S179 = ea_0.x;
    float _S180 = _S179 * _S178;
    float _S181 = eb_0.x;
    float _S182 = _S181 * _S178;
    float _S183 = ea_0.y;
    float _S184 = _S183 * _S176;
    float _S185 = eb_0.y;
    float _S186 = _S185 * _S176;
    float uLo_0 = (F32_min((_S180), (_S182))) + (F32_min((_S184), (_S186)));
    float uHi_0 = (F32_max((_S180), (_S182))) + (F32_max((_S184), (_S186)));
    float _S187 = _S179 * _S177;
    float _S188 = _S181 * _S177;
    float _S189 = _S183 * _S178;
    float _S190 = _S185 * _S178;
    float nLo_0 = (F32_min((_S187), (_S188))) + (F32_min((_S189), (_S190)));
    float nHi_0 = (F32_max((_S187), (_S188))) + (F32_max((_S189), (_S190)));
    bool _S191;
    if(nLo_0 <= 0.0f)
    {
        _S191 = nHi_0 >= 0.0f;
    }
    else
    {
        _S191 = false;
    }
    float mMin_0;
    if(_S191)
    {
        mMin_0 = 0.0f;
    }
    else
    {
        mMin_0 = (F32_min(((F32_abs((nLo_0)))), ((F32_abs((nHi_0))))));
    }
    float2  halfSpan_0 = make_float2 (0.5f * (uHi_0 - uLo_0), 0.5f * (high_1 - low_1));
    float2  slopeUnused_0;
    float relief_1;
    float _S192 = convShapeDistance_0(c_27, 0.5f * (uLo_0 + uHi_0), 0.5f * (low_1 + high_1), &slopeUnused_0, &relief_1);
    float _S193 = length_1(halfSpan_0);
    float dMax_0 = _S192 + 2.5f * _S193;
    float _S194 = c_27->cvReliefHeight_0;
    if((c_27->cvReliefHeight_0) > 0.0f)
    {
        _S191 = nLo_0 > 0.0f;
    }
    else
    {
        _S191 = false;
    }
    if(_S191)
    {
        mMin_0 = (F32_max((nLo_0 - (F32_min((_S194), (_S194 * relief_1 + c_27->cvReliefSlope_0 * _S193)))), (0.0f)));
    }
    float2  stepUnused_0;
    return - convShapeProfile_0(dMax_0, mMin_0, c_27->cvShapeRound_0, &stepUnused_0);
}

static __device__ float convTurretReach_0(ConvectionInput_0 * c_28, float4  t_5)
{
    return t_5.z + 1.5f * c_28->cvBillow_0 * c_28->cvHeroBillow_0 + 24.0f;
}

static __device__ float convTurretBillow_0(ConvectionInput_0 * c_29, float radius_2)
{
    return lerp_1((F32_min((1.0f), (c_29->cvHeroBillow_0))), c_29->cvHeroBillow_0, saturate_0(radius_2 / (F32_max((c_29->cvHeroRadius_0), (1.0f)))));
}

static __device__ bool convTurretBound_0(ConvectionInput_0 * c_30, float4  t_6, float3  lo_5, float3  hi_5, float low_2, float high_2, float * dPart_0, float * lift_1)
{
    *dPart_0 = -1.00000001504746622e+30f;
    *lift_1 = 0.0f;
    float2  _S195 = float2 {t_6.x, t_6.y};
    float2  nearGap_2 = max_1(max_1(float2 {lo_5.x, lo_5.z} - _S195, _S195 - float2 {hi_5.x, hi_5.z}), make_float2 (0.0f, 0.0f));
    float gap2_1 = dot_1(nearGap_2, nearGap_2);
    float _S196 = convTurretReach_0(c_30, t_6);
    if(gap2_1 >= (_S196 * _S196))
    {
        return false;
    }
    float rMin_0 = (F32_sqrt((gap2_1)));
    float _S197 = t_6.w;
    float _S198 = t_6.z;
    float tower_0 = convDomeHeight_0(_S197, _S198, c_30->cvShape_0, rMin_0);
    float ra_0 = convDomeRadiusAt_0(_S197, _S198, c_30->cvShape_0, low_2);
    float _S199 = convTurretBillow_0(c_30, _S198);
    float _S200 = convLift_0(c_30, high_2, _S199);
    *lift_1 = _S200;
    bool _S201 = ra_0 < 0.0f;
    bool _S202;
    if(_S201)
    {
        _S202 = true;
    }
    else
    {
        _S202 = rMin_0 >= ra_0;
    }
    if(_S202)
    {
        float hMin_1;
        if(_S201)
        {
            hMin_1 = 1.00000001504746622e+30f;
        }
        else
        {
            hMin_1 = rMin_0 - ra_0;
        }
        *dPart_0 = - convDistanceFloor_0(low_2 - tower_0, hMin_1);
    }
    else
    {
        *dPart_0 = (F32_max((tower_0 - low_2), (0.0f)));
    }
    return true;
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_31, float3  lo_6, float3  hi_6)
{
    float low_3 = lo_6.y - c_31->cvBase_0;
    float high_3 = hi_6.y - c_31->cvBase_0;
    float _S203 = convCeiling_0(c_31);
    float _S204 = c_31->cvMammaDepth_0;
    bool pouches_0;
    if(high_3 < (- c_31->cvMammaDepth_0))
    {
        pouches_0 = true;
    }
    else
    {
        pouches_0 = low_3 > _S203;
    }
    if(pouches_0)
    {
        return 0.0f;
    }
    if(_S204 > 0.0f)
    {
        pouches_0 = low_3 < 40.0f;
    }
    else
    {
        pouches_0 = false;
    }
    float _S205 = (F32_max((low_3), (0.0f)));
    float _S206 = (F32_min(((F32_max((high_3), (0.0f)))), (_S203)));
    bool _S207 = (c_31->cvHeroTop_0) > 0.0f;
    bool _S208;
    if(_S207)
    {
        if((c_31->cvPileusThick_0) > 0.0f)
        {
            _S208 = true;
        }
        else
        {
            _S208 = (c_31->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        _S208 = false;
    }
    float capBound_0;
    if(_S208)
    {
        float _S209 = convCapBound_0(c_31, lo_6, hi_6, _S205, _S206);
        capBound_0 = _S209;
    }
    else
    {
        capBound_0 = 0.0f;
    }
    float _S210 = convLift_0(c_31, _S206, 1.0f);
    float inside_0;
    if((c_31->cvHeroAlone_0) == int(0))
    {
        float2  _S211 = float2 {lo_6.x, lo_6.z};
        float2  _S212 = float2 {hi_6.x, hi_6.z};
        float _S213 = convUpdraftBound_0(c_31, _S211 - c_31->cvDrift_0, _S212 - c_31->cvDrift_0);
        float _S214 = convTowerHeight_0(c_31, _S213);
        float _S215 = convNeededUpdraft_0(c_31, _S205);
        if(_S213 < _S215)
        {
            float _S216 = convSlopeCap_0(c_31);
            if((c_31->cvMoat_0) > 0.0f)
            {
                float _S217 = convMoatSlopeOver_0(c_31, _S211, _S212);
                inside_0 = _S216 + _S217;
            }
            else
            {
                inside_0 = _S216;
            }
            inside_0 = _S210 - convDistanceFloor_0(_S205 - _S214, (_S215 - _S213) / inside_0);
        }
        else
        {
            inside_0 = (F32_max((_S214 - _S205), (0.0f))) + _S210;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    float edge_0;
    if(_S207)
    {
        float rMin_1 = length_1(max_1(max_1(float2 {lo_6.x, lo_6.z} - c_31->cvHeroAt_0, c_31->cvHeroAt_0 - float2 {hi_6.x, hi_6.z}), make_float2 (0.0f, 0.0f)));
        float _S218 = convHeroReachAll_0(c_31);
        float groupD_0;
        float groupLift_0;
        if(rMin_1 < _S218)
        {
            float _S219 = convHeroHeight_0(c_31, rMin_1);
            float _S220 = convHeroRadiusAt_0(c_31, _S205);
            float _S221 = c_31->cvHeroBillow_0;
            float _S222 = convLift_0(c_31, _S206, c_31->cvHeroBillow_0);
            bool _S223 = _S220 < 0.0f;
            if(_S223)
            {
                _S208 = true;
            }
            else
            {
                _S208 = rMin_1 >= _S220;
            }
            if(_S208)
            {
                if(_S223)
                {
                    edge_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    edge_0 = rMin_1 - _S220;
                }
                edge_0 = - convDistanceFloor_0(_S205 - _S219, edge_0);
            }
            else
            {
                edge_0 = (F32_max((_S219 - _S205), (0.0f)));
            }
            if((c_31->cvShapeOn_0) != int(0))
            {
                _S208 = (c_31->cvShapeDecay_0) < 1.0f;
            }
            else
            {
                _S208 = false;
            }
            if(_S208)
            {
                float _S224 = convShapeBound_0(c_31, lo_6, hi_6, _S205, _S206);
                float _S225 = lerp_1(_S224, edge_0, c_31->cvShapeDecay_0);
                float _S226 = convLift_0(c_31, _S206, _S221 * lerp_1(c_31->cvShapeBillow_0, 1.0f, c_31->cvShapeDecay_0));
                groupD_0 = _S225;
                groupLift_0 = _S226;
            }
            else
            {
                groupD_0 = edge_0;
                groupLift_0 = _S222;
            }
        }
        else
        {
            groupD_0 = -1.00000001504746622e+30f;
            groupLift_0 = 0.0f;
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
            if(k_5 >= (c_31->cvTurretCount_0))
            {
                break;
            }
            float4  _S227 = convTurret_0(c_31, k_5);
            float turretD_0;
            float turretLift_0;
            bool _S228 = convTurretBound_0(c_31, _S227, lo_6, hi_6, _S205, _S206, &turretD_0, &turretLift_0);
            if(_S228)
            {
                float _S229 = (F32_max((groupLift_0), (turretLift_0)));
                groupD_0 = (F32_max((groupD_0), (turretD_0)));
                groupLift_0 = _S229;
            }
            k_5 = k_5 + int(1);
        }
        if(groupD_0 > -1.00000001504746622e+29f)
        {
            inside_0 = (F32_max((inside_0), (groupD_0 + groupLift_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return capBound_0;
    }
    if(pouches_0)
    {
        edge_0 = 1.0f;
    }
    else
    {
        edge_0 = smoothstep_0(0.0f, 12.0f, inside_1);
    }
    if(pouches_0)
    {
        inside_0 = _S206 + _S204;
    }
    else
    {
        inside_0 = _S206;
    }
    return (F32_max((c_31->cvSigma_0 * (F32_sqrt((saturate_0(inside_0 / 40.0f)))) * edge_0 * 1.00001001358032227f), (capBound_0)));
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_24 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_15 = clamp_1(int((F32_floor((x_24)))), int(0), int(31));
    float2  _S230 = __ldg((&(disp_0)[i_15]));
    float2  _S231 = __ldg((&(disp_0)[i_15 + int(1)]));
    return lerp_2(_S230, _S231, make_float2 (x_24 - float(i_15)));
}

static __device__ void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<float2 > disp_1, float d0_0, float d1_0, float2  * lo_7, float2  * hi_7)
{
    float2  _S232 = driftAt_0(g_5, disp_1, d0_0);
    *lo_7 = _S232;
    *hi_7 = _S232;
    float2  _S233 = driftAt_0(g_5, disp_1, d1_0);
    *lo_7 = min_1(*lo_7, _S233);
    *hi_7 = max_1(*hi_7, _S233);
    int _S234 = clamp_1(int((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_6 = clamp_1(int((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_6 <= _S234)
        {
        }
        else
        {
            break;
        }
        float2  _S235 = *lo_7;
        float2  _S236 = __ldg((&(disp_1)[k_6]));
        *lo_7 = min_1(_S235, _S236);
        float2  _S237 = *hi_7;
        float2  _S238 = __ldg((&(disp_1)[k_6]));
        *hi_7 = max_1(_S237, _S238);
        k_6 = k_6 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_6, float2  q0_2, float2  q1_2)
{
    float2  a_4;
    float2  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    float2  _S239 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    float2  _S240 = floor_1(a_4);
    int2  _S241 = make_int2 ((int)_S240.x, (int)_S240.y);
    int2  _S242 = make_int2 (int(1), int(1));
    int2  i0_2 = _S241 - _S242;
    float2  _S243 = floor_1(b_3);
    int2  _S244 = make_int2 ((int)_S243.x, (int)_S243.y);
    int2  _S245 = _S244 + _S242;
    int _S246 = i0_2.y;
    int j_9 = _S246;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S247;
        if(j_9 <= (_S245.y))
        {
            _S247 = j_9 <= (_S246 + int(32));
        }
        else
        {
            _S247 = false;
        }
        if(_S247)
        {
        }
        else
        {
            break;
        }
        int _S248 = i0_2.x;
        int i_16 = _S248;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S249;
            if(i_16 <= (_S245.x))
            {
                _S249 = i_16 <= (_S248 + int(32));
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
            int2  o_7 = make_int2 (i_16, j_9);
            if((hash22_0(o_7, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_16 = i_16 + int(1);
                continue;
            }
            float2  _S250 = make_float2 ((float)o_7.x, (float)o_7.y);
            float2  c_32 = _S250 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S239;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(max_1(max_1(a_4 - c_32, c_32 - b_3), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_16 = i_16 + int(1);
        }
        j_9 = j_9 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_6->cellStrength_0;
}

static __device__ float iceDensityBound_0(GeneratorInput_0 * g_7, StructuredBuffer<float2 > disp_2, float3  lo_8, float3  hi_8)
{
    float d0_1 = g_7->cellAltitude_0 - hi_8.y;
    float d1_1 = g_7->cellAltitude_0 - lo_8.y;
    bool _S251;
    if(d1_1 < 0.0f)
    {
        _S251 = true;
    }
    else
    {
        _S251 = d0_1 > (g_7->streakLength_0);
    }
    if(_S251)
    {
        return 0.0f;
    }
    float _S252 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S253 = cellFieldBound_0(g_7, make_float2 (lo_8.x, lo_8.z) - driftHi_0, make_float2 (hi_8.x, hi_8.z) - driftLo_0);
    return (F32_max((_S253 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S252), (1.0f)));
}

static __device__ float mediumBound_0(Medium_0 * m_2, StructuredBuffer<float2 > disp_3, float3  lo_9, float3  hi_9)
{
    int _S254 = m_2->mode_0;
    if((m_2->mode_0) == int(3))
    {
        float _S255 = convectionBound_0(&m_2->conv_0, lo_9, hi_9);
        return _S255;
    }
    if(_S254 == int(2))
    {
        float _S256 = iceDensityBound_0(&m_2->gen_0, disp_3, lo_9, hi_9);
        return _S256;
    }
    return m_2->majorant_0;
}

static __device__ float gridBound_0(Medium_0 * m_3, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_0, StructuredBuffer<float2 > disp_4, int3  c_33, float fallback_0)
{
    int _S257 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S257 == int(2))
    {
        float3  _S258 = make_float3 ((float)c_33.x, (float)c_33.y, (float)c_33.z);
        float3  lo_10 = g_8->origin_0 + _S258 * g_8->cellExtent_0;
        float _S259 = mediumBound_0(m_3, disp_4, lo_10, lo_10 + g_8->cellExtent_0);
        return _S259;
    }
    int _S260 = c_33.x;
    bool _S261;
    if(_S260 < int(0))
    {
        _S261 = true;
    }
    else
    {
        _S261 = (c_33.y) < int(0);
    }
    if(_S261)
    {
        _S261 = true;
    }
    else
    {
        _S261 = (c_33.z) < int(0);
    }
    if(_S261)
    {
        _S261 = true;
    }
    else
    {
        _S261 = _S260 >= (g_8->dims_0.x);
    }
    if(_S261)
    {
        _S261 = true;
    }
    else
    {
        _S261 = (c_33.y) >= (g_8->dims_0.y);
    }
    if(_S261)
    {
        _S261 = true;
    }
    else
    {
        _S261 = (c_33.z) >= (g_8->dims_0.z);
    }
    if(_S261)
    {
        return fallback_0;
    }
    float _S262 = __ldg((&(bounds_0)[(c_33.z * g_8->dims_0.y + c_33.y) * g_8->dims_0.x + _S260]));
    return _S262;
}

static __device__ float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S263;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S263 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S263 = false;
    }
    if(_S263)
    {
        *&((&d_7->cell_0)->x) = *&((&d_7->cell_0)->x) + d_7->stepDir_0.x;
        *&((&d_7->tMax_0)->x) = *&((&d_7->tMax_0)->x) + d_7->tDelta_0.x;
    }
    else
    {
        if((d_7->tMax_0.y) <= (d_7->tMax_0.z))
        {
            *&((&d_7->cell_0)->y) = *&((&d_7->cell_0)->y) + d_7->stepDir_0.y;
            *&((&d_7->tMax_0)->y) = *&((&d_7->tMax_0)->y) + d_7->tDelta_0.y;
        }
        else
        {
            *&((&d_7->cell_0)->z) = *&((&d_7->cell_0)->z) + d_7->stepDir_0.z;
            *&((&d_7->tMax_0)->z) = *&((&d_7->tMax_0)->z) + d_7->tDelta_0.z;
        }
    }
    return;
}

static __device__ float randFloat_0(Rng_0 * r_5)
{
    uint _S264 = r_5->state_0 * 747796405U + 2891336453U;
    r_5->state_0 = _S264;
    uint word_0 = ((_S264 >> ((_S264 >> 28U) + 4U)) ^ _S264) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ bool segmentStep_0(Medium_0 * m_4, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > drift_0, float scale_0, float tEnd_0, Dda_0 * dda_0, float * rate_0, float * t_7, Rng_0 * rng_0, float * uKeep_0, float * uLive_0, float * uHit_0, int * budget_0, int * steps_0)
{
    *uKeep_0 = 0.0f;
    *uLive_0 = 0.0f;
    *uHit_0 = 0.0f;
    for(;;)
    {
        if((*budget_0) > int(0))
        {
        }
        else
        {
            break;
        }
        *budget_0 = *budget_0 - int(1);
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S265 = *dda_0;
        float _S266 = ddaExit_0(&_S265);
        float _S267 = (F32_min((_S266), (tEnd_0)));
        if(!((*rate_0) > 0.0f))
        {
            if(_S267 >= tEnd_0)
            {
                return false;
            }
            *t_7 = _S267;
            ddaAdvance_0(dda_0);
            float _S268 = gridBound_0(m_4, g_9, bounds_1, drift_0, dda_0->cell_0, m_4->majorant_0);
            *rate_0 = _S268 * scale_0;
            continue;
        }
        float uStep_0 = randFloat_0(rng_0);
        float _S269 = randFloat_0(rng_0);
        *uKeep_0 = _S269;
        float _S270 = randFloat_0(rng_0);
        *uLive_0 = _S270;
        float _S271 = randFloat_0(rng_0);
        *uHit_0 = _S271;
        float _S272 = *t_7 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / *rate_0;
        *t_7 = _S272;
        if(_S272 >= _S267)
        {
            if(_S267 >= tEnd_0)
            {
                return false;
            }
            *t_7 = _S267;
            ddaAdvance_0(dda_0);
            float _S273 = gridBound_0(m_4, g_9, bounds_1, drift_0, dda_0->cell_0, m_4->majorant_0);
            *rate_0 = _S273 * scale_0;
            continue;
        }
        return true;
    }
    return false;
}

static __device__ MajorantGrid_0 gridFor_0(Medium_0 * m_5, MajorantGrid_0 * g_10, float3  p_2)
{
    MajorantGrid_0 chosen_0 = *g_10;
    bool _S274;
    if((g_10->enabled_0) == int(2))
    {
        _S274 = (p_2.y) >= (m_5->slabBottom_0);
    }
    else
    {
        _S274 = false;
    }
    if(_S274)
    {
        _S274 = (p_2.y) <= (m_5->slabTop_0);
    }
    else
    {
        _S274 = false;
    }
    if(_S274)
    {
        (&chosen_0)->enabled_0 = int(0);
    }
    return chosen_0;
}

static __device__ float orgWaveFactor_0(Organization_0 * o_8, float2  q_7)
{
    float2  unused_0;
    float _S275 = orgWave_0(o_8, q_7, &unused_0);
    return _S275;
}

static __device__ float cellField_0(GeneratorInput_0 * g_11, float2  q_8)
{
    float2  _S276 = q_8 - g_11->cellDrift_0;
    float2  _S277 = orgPattern_0(&g_11->gnOrg_0, _S276, g_11->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(_S277);
    int2  _S278 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    float2  _S279 = orgJitter_0(&g_11->gnOrg_0, 0.80000001192092896f);
    int j_10 = int(-1);
    float acc_2 = 0.0f;
    for(;;)
    {
        if(j_10 <= int(1))
        {
        }
        else
        {
            break;
        }
        int i_17 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_17 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_9 = _S278 + make_int2 (i_17, j_10);
            if((hash22_0(o_9, 2654435769U).x) > (g_11->cellDensity_0))
            {
                i_17 = i_17 + int(1);
                continue;
            }
            float2  _S280 = make_float2 ((float)o_9.x, (float)o_9.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(_S277 - (_S280 + make_float2 (0.5f) + (hash22_0(o_9, 0U) - make_float2 (0.5f)) * _S279)) * 2.20000004768371582f);
            i_17 = i_17 + int(1);
        }
        j_10 = j_10 + int(1);
        acc_2 = acc_3;
    }
    float _S281 = acc_2 * g_11->cellStrength_0;
    float _S282 = orgWaveFactor_0(&g_11->gnOrg_0, _S276);
    return _S281 * _S282;
}

static __device__ float fbm_0(float3  p_3, int octaves_1)
{
    int i_18 = int(0);
    float amp_0 = 0.5f;
    float3  _S283 = p_3;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_18 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_18 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S283);
        float norm_1 = norm_0 + amp_0;
        float3  _S284 = _S283 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_18 = i_18 + int(1);
        amp_0 = amp_1;
        _S283 = _S284;
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

static __device__ float iceDensity_0(GeneratorInput_0 * g_12, StructuredBuffer<float2 > disp_5, float3  p_4)
{
    float depth_1 = g_12->cellAltitude_0 - p_4.y;
    bool _S285;
    if(depth_1 < 0.0f)
    {
        _S285 = true;
    }
    else
    {
        _S285 = depth_1 > (g_12->streakLength_0);
    }
    if(_S285)
    {
        return 0.0f;
    }
    float2  _S286 = float2 {p_4.x, p_4.z};
    float2  _S287 = driftAt_0(g_12, disp_5, depth_1);
    float2  source_0 = _S286 - _S287;
    float _S288 = cellField_0(g_12, source_0);
    if(_S288 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S288 * (F32_exp((- g_12->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_12->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_12->streakLength_0, g_12->streakLength_0, depth_1)) * (F32_max((1.0f + g_12->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_12->detailScale_0)).x, (source_0 / make_float2 (g_12->detailScale_0)).y, depth_1 / (F32_max((g_12->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_12->timeSeconds_0 * 0.00999999977648258f), g_12->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_12->opticalDepth_0 / (F32_max((g_12->streakLength_0), (1.0f)));
}

static __device__ float convPouches_0(ConvectionInput_0 * c_34, float2  q_9)
{
    float2  g_13 = q_9 / make_float2 (c_34->cvPouchSize_0);
    float2  _S289 = floor_1(g_13);
    int2  _S290 = make_int2 ((int)_S289.x, (int)_S289.y);
    float deepest_0 = 0.0f;
    int j_11 = int(-1);
    for(;;)
    {
        if(j_11 <= int(1))
        {
        }
        else
        {
            break;
        }
        float deepest_1 = deepest_0;
        int i_19 = int(-1);
        for(;;)
        {
            if(i_19 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_7 = _S290 + make_int2 (i_19, j_11);
            float2  _S291 = make_float2 ((float)slot_7.x, (float)slot_7.y);
            float2  d_8 = g_13 - (_S291 + make_float2 (0.5f) + (hash22_0(slot_7, 739982445U) - make_float2 (0.5f)) * make_float2 (0.60000002384185791f));
            float t2_0 = dot_1(d_8, d_8) / 0.46240001916885376f;
            if(t2_0 >= 1.0f)
            {
                i_19 = i_19 + int(1);
                continue;
            }
            float2  h_3 = hash22_0(slot_7, 2135587861U);
            deepest_1 = (F32_max((deepest_1), (lerp_1(0.30000001192092896f, 1.0f, convLife_0((F32_frac((2.0f * c_34->cvAge_0 + h_3.x))))) * lerp_1(0.60000002384185791f, 1.0f, h_3.y) * (F32_sqrt((1.0f - t2_0))))));
            i_19 = i_19 + int(1);
        }
        int j_12 = j_11 + int(1);
        deepest_0 = deepest_1;
        j_11 = j_12;
    }
    return deepest_0;
}

static __device__ void convMoatRing_0(float2  xz_0, float2  at_0, float radius_3, float * s_12, float2  * gs_0, float * slope_1)
{
    float2  d_9 = xz_0 - at_0;
    float r2_1 = dot_1(d_9, d_9);
    float outer_1 = 1.29999995231628418f * radius_3;
    if(!(r2_1 < (outer_1 * outer_1)))
    {
        return;
    }
    float band_2 = outer_1 - 0.75f * radius_3;
    float inner_1 = outer_1 - band_2;
    *slope_1 = (F32_max((*slope_1), (1.5f / band_2)));
    float r_6 = (F32_sqrt((r2_1)));
    float t_8 = saturate_0((r_6 - inner_1) / band_2);
    float f_1 = t_8 * t_8 * (3.0f - 2.0f * t_8);
    if(f_1 < (*s_12))
    {
        *s_12 = f_1;
        float2  _S292;
        if(r_6 > 0.00100000004749745f)
        {
            _S292 = d_9 * make_float2 (6.0f * t_8 * (1.0f - t_8) / (band_2 * r_6));
        }
        else
        {
            _S292 = make_float2 (0.0f, 0.0f);
        }
        *gs_0 = _S292;
    }
    return;
}

static __device__ float convMoat_0(ConvectionInput_0 * c_35, float2  xz_1, float2  * grad_5, float * slopeAdd_0)
{
    float s_13 = 1.0f;
    float2  gs_1 = make_float2 (0.0f, 0.0f);
    float slope_2 = 0.0f;
    convMoatRing_0(xz_1, c_35->cvHeroAt_0, c_35->cvHeroRadius_0, &s_13, &gs_1, &slope_2);
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
        if(k_7 >= (c_35->cvTurretCount_0))
        {
            break;
        }
        float4  _S293 = convTurret_0(c_35, k_7);
        convMoatRing_0(xz_1, float2 {_S293.x, _S293.y}, _S293.z, &s_13, &gs_1, &slope_2);
        k_7 = k_7 + int(1);
    }
    float _S294 = c_35->cvMoat_0;
    *grad_5 = gs_1 * make_float2 (c_35->cvMoat_0);
    *slopeAdd_0 = slope_2 * _S294;
    return 1.0f - _S294 * (1.0f - s_13);
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_36, float2  q_10, float2  * grad_6)
{
    if(((&c_36->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S295 = convUpdraftGradT_2(c_36, q_10, grad_6);
        return _S295;
    }
    if((c_36->cvLacunarity_0) <= 0.0f)
    {
        float _S296 = convUpdraftGradT_1(c_36, q_10, grad_6);
        return _S296;
    }
    float _S297 = convUpdraftGradT_0(c_36, q_10, grad_6);
    return _S297;
}

static __device__ float convSurfaceDistance_0(float v_2, float delta_0, float slope_3)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_3 * slope_3 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_10 = num_0 / den_0;
    float _S298;
    if(v_2 >= 0.0f)
    {
        _S298 = d_10;
    }
    else
    {
        _S298 = - d_10;
    }
    return _S298;
}

static __device__ float convFieldBaseInside_0(ConvectionInput_0 * c_37, float w_3, float2  slope_4, float cap_3)
{
    float _S299 = convTowerHeight_0(c_37, w_3);
    float v_3 = _S299 - 1.0f;
    float _S300 = convNeededUpdraft_0(c_37, 1.0f);
    return convSurfaceDistance_0(v_3, w_3 - _S300, (F32_min((length_1(slope_4)), (cap_3))));
}

static __device__ float convDomeSurface_0(float top_4, float radius_4, float shape_2, float2  rel_0, float r_7, float py_0, float above_4, float3  * x_25)
{
    float v_4 = convDomeHeight_0(top_4, radius_4, shape_2, r_7) - above_4;
    float ra_1 = convDomeRadiusAt_0(top_4, radius_4, shape_2, above_4);
    float shiftOut_0;
    float shiftUp_0;
    float d_11;
    if(ra_1 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_4;
        d_11 = v_4;
    }
    else
    {
        float h_4 = ra_1 - r_7;
        float d_12 = convSurfaceDistance_0(v_4, h_4, 1.0f);
        if((F32_abs((v_4))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_12 * (d_12 / v_4);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_4))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_12 * (d_12 / h_4);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S301 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S301;
        d_11 = d_12;
    }
    float2  radial_0;
    if(r_7 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / make_float2 (r_7);
    }
    else
    {
        radial_0 = make_float2 (0.0f, 0.0f);
    }
    float2  at_1 = rel_0 + radial_0 * make_float2 (shiftOut_0);
    *x_25 = make_float3 (at_1.x, py_0 + shiftUp_0, at_1.y);
    return d_11;
}

static __device__ float convTowerSurface_0(ConvectionInput_0 * c_38, float2  rel_1, float r_8, float py_1, float above_5, float3  * x_26)
{
    float _S302 = convDomeSurface_0(c_38->cvHeroTop_0, c_38->cvHeroRadius_0, c_38->cvShape_0, rel_1, r_8, py_1, above_5, x_26);
    return _S302;
}

static __device__ float convReliefLift_0(ConvectionInput_0 * c_39, float dIn_1, float relief_2)
{
    return c_39->cvReliefHeight_0 * relief_2 * smoothstep_0(0.0f, (F32_max((c_39->cvReliefFade_0), (1.0f))), dIn_1);
}

static __device__ float convShapeSurface_0(ConvectionInput_0 * c_40, float2  plane_0, float py_2, float above_6, float3  * x_27)
{
    float _S303 = plane_0.x;
    float2  slopeUY_1;
    float relief_3;
    float _S304 = convShapeDistance_0(c_40, _S303, above_6, &slopeUY_1, &relief_3);
    float _S305 = plane_0.y;
    float _S306 = (F32_abs((_S305)));
    bool _S307;
    if((c_40->cvReliefHeight_0) > 0.0f)
    {
        _S307 = _S305 > 0.0f;
    }
    else
    {
        _S307 = false;
    }
    float m_6;
    if(_S307)
    {
        float _S308 = convReliefLift_0(c_40, _S304, relief_3);
        m_6 = (F32_max((_S305 - _S308), (0.0f)));
    }
    else
    {
        m_6 = _S306;
    }
    float2  stepDM_1;
    float gap_2 = convShapeProfile_0(_S304, m_6, c_40->cvShapeRound_0, &stepDM_1);
    float side_0;
    if(_S305 >= 0.0f)
    {
        side_0 = 1.0f;
    }
    else
    {
        side_0 = -1.0f;
    }
    *x_27 = make_float3 (_S303 + stepDM_1.x * slopeUY_1.x, py_2 + stepDM_1.x * slopeUY_1.y, _S305 + side_0 * stepDM_1.y);
    return - gap_2;
}

static __device__ bool convHeroSmooth_0(ConvectionInput_0 * c_41, float3  p_5, float above_7, float * d_13, float3  * x_28, float * amount_0, float * lobe_0)
{
    *d_13 = -1.00000001504746622e+30f;
    *x_28 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S309 = c_41->cvHeroBillow_0;
    *amount_0 = c_41->cvHeroBillow_0;
    *lobe_0 = _S309;
    float2  rel_2 = float2 {p_5.x, p_5.z} - c_41->cvHeroAt_0;
    float r_9 = length_1(rel_2);
    float _S310 = convHeroReachAll_0(c_41);
    if(r_9 >= _S310)
    {
        return false;
    }
    if((c_41->cvShapeOn_0) == int(0))
    {
        float _S311 = convTowerSurface_0(c_41, rel_2, r_9, p_5.y, above_7, x_28);
        *d_13 = _S311;
    }
    else
    {
        float2  plane_1 = make_float2 (dot_1(rel_2, c_41->cvShapeAxisU_0), dot_1(rel_2, make_float2 (- c_41->cvShapeAxisU_0.y, c_41->cvShapeAxisU_0.x)));
        float _S312 = c_41->cvShapeDecay_0;
        if((c_41->cvShapeDecay_0) >= 1.0f)
        {
            float _S313 = convTowerSurface_0(c_41, plane_1, r_9, p_5.y, above_7, x_28);
            *d_13 = _S313;
        }
        else
        {
            float _S314 = p_5.y;
            float3  xs_0;
            float _S315 = convShapeSurface_0(c_41, plane_1, _S314, above_7, &xs_0);
            if(_S312 > 0.0f)
            {
                float3  xt_0;
                float _S316 = convTowerSurface_0(c_41, plane_1, r_9, _S314, above_7, &xt_0);
                *d_13 = lerp_1(_S315, _S316, _S312);
                *x_28 = lerp_0(xs_0, xt_0, make_float3 (_S312));
            }
            else
            {
                *d_13 = _S315;
                *x_28 = xs_0;
            }
            float _S317 = c_41->cvShapeBillow_0;
            *amount_0 = _S309 * lerp_1(c_41->cvShapeBillow_0, 1.0f, _S312);
            *lobe_0 = _S309 * lerp_1((F32_max((_S317), (0.30000001192092896f))), 1.0f, _S312);
        }
    }
    return true;
}

static __device__ bool convTurretSmooth_0(ConvectionInput_0 * c_42, float4  t_9, float3  p_6, float above_8, float * d_14, float3  * x_29, float * k_8)
{
    *d_14 = -1.00000001504746622e+30f;
    *x_29 = make_float3 (0.0f, 0.0f, 0.0f);
    *k_8 = 1.0f;
    float2  rel_3 = float2 {p_6.x, p_6.z} - float2 {t_9.x, t_9.y};
    float r2_2 = dot_1(rel_3, rel_3);
    float _S318 = convTurretReach_0(c_42, t_9);
    if(r2_2 >= (_S318 * _S318))
    {
        return false;
    }
    float _S319 = t_9.w;
    if(above_8 >= (_S319 + c_42->cvBillow_0 * c_42->cvHeroBillow_0))
    {
        return false;
    }
    float r_10 = (F32_sqrt((r2_2)));
    float _S320 = t_9.z;
    float _S321 = convTurretBillow_0(c_42, _S320);
    *k_8 = _S321;
    float3  own_0;
    float _S322 = convDomeSurface_0(_S319, _S320, c_42->cvShape_0, rel_3, r_10, p_6.y, above_8, &own_0);
    *d_14 = _S322;
    float3  w_4 = own_0 + make_float3 (t_9.x - c_42->cvHeroAt_0.x, 0.0f, t_9.y - c_42->cvHeroAt_0.y);
    float3  w_5;
    if((c_42->cvShapeOn_0) != int(0))
    {
        float2  _S323 = float2 {w_4.x, w_4.z};
        w_5 = make_float3 (dot_1(_S323, c_42->cvShapeAxisU_0), w_4.y, dot_1(_S323, make_float2 (- c_42->cvShapeAxisU_0.y, c_42->cvShapeAxisU_0.x)));
    }
    else
    {
        w_5 = w_4;
    }
    *x_29 = w_5;
    return true;
}

static __device__ float convGroupBaseInside_0(ConvectionInput_0 * c_43, float2  xz_2, bool nearGroup_0)
{
    float best_1;
    if((c_43->cvHeroTop_0) > 0.0f)
    {
        float3  p_7 = make_float3 (xz_2.x, c_43->cvBase_0 + 1.0f, xz_2.y);
        float d_15;
        float amount_1;
        float lobe_1;
        float3  x_30;
        bool _S324 = convHeroSmooth_0(c_43, p_7, 1.0f, &d_15, &x_30, &amount_1, &lobe_1);
        if(_S324)
        {
            best_1 = (F32_max((-1.00000001504746622e+30f), (d_15)));
        }
        else
        {
            best_1 = -1.00000001504746622e+30f;
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
            bool _S325;
            if(!nearGroup_0)
            {
                _S325 = true;
            }
            else
            {
                _S325 = k_9 >= (c_43->cvTurretCount_0);
            }
            if(_S325)
            {
                break;
            }
            float4  _S326 = convTurret_0(c_43, k_9);
            float kt_0;
            bool _S327 = convTurretSmooth_0(c_43, _S326, p_7, 1.0f, &d_15, &x_30, &kt_0);
            if(_S327)
            {
                best_1 = (F32_max((best_1), (d_15)));
            }
            k_9 = k_9 + int(1);
        }
    }
    else
    {
        best_1 = -1.00000001504746622e+30f;
    }
    return best_1;
}

static __device__ float convBaseInside_0(ConvectionInput_0 * c_44, float2  xz_3, bool nearGroup_1)
{
    float best_2;
    if((c_44->cvHeroAlone_0) == int(0))
    {
        float capMoat_0 = 0.0f;
        float2  gMoat_0 = make_float2 (0.0f, 0.0f);
        bool moated_0;
        if((c_44->cvMoat_0) > 0.0f)
        {
            moated_0 = nearGroup_1;
        }
        else
        {
            moated_0 = false;
        }
        float m_7;
        if(moated_0)
        {
            float _S328 = convMoat_0(c_44, xz_3, &gMoat_0, &capMoat_0);
            m_7 = _S328;
        }
        else
        {
            m_7 = 1.0f;
        }
        if(m_7 > 0.0f)
        {
            float2  slope_5;
            float _S329 = convUpdraftGrad_0(c_44, xz_3 - c_44->cvDrift_0, &slope_5);
            float _S330 = convSlopeCap_0(c_44);
            float cap_4;
            if(moated_0)
            {
                slope_5 = slope_5 * make_float2 (m_7) + gMoat_0 * make_float2 (_S329);
                float cap_5 = _S330 + capMoat_0;
                best_2 = _S329 * m_7;
                cap_4 = cap_5;
            }
            else
            {
                best_2 = _S329;
                cap_4 = _S330;
            }
            float _S331 = convFieldBaseInside_0(c_44, best_2, slope_5, cap_4);
            best_2 = _S331;
        }
        else
        {
            best_2 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        best_2 = -1.00000001504746622e+30f;
    }
    float _S332 = convGroupBaseInside_0(c_44, xz_3, nearGroup_1);
    return (F32_max((best_2), (_S332)));
}

static __device__ float convMammaSagOf_0(ConvectionInput_0 * c_45, float pouch_0, float inside_2)
{
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_45->cvMammaDepth_0 * pouch_0 * smoothstep_0(0.0f, 0.60000002384185791f * c_45->cvPouchSize_0, inside_2);
}

static __device__ float convMammaSag_0(ConvectionInput_0 * c_46, float2  xz_4, bool nearGroup_2, float below_0)
{
    float _S333 = convPouches_0(c_46, xz_4 - c_46->cvDrift_0);
    if((c_46->cvMammaDepth_0 * _S333) <= below_0)
    {
        return 0.0f;
    }
    float _S334 = convBaseInside_0(c_46, xz_4, nearGroup_2);
    float _S335 = convMammaSagOf_0(c_46, _S333, _S334);
    return _S335;
}

static __device__ float3  convTwist_0(float3  x_31)
{
    float _S336 = x_31.x;
    float _S337 = x_31.y;
    float _S338 = x_31.z;
    return make_float3 (0.0f * _S336 + 0.80000001192092896f * _S337 + 0.60000002384185791f * _S338, -0.80000001192092896f * _S336 + 0.36000001430511475f * _S337 - 0.47999998927116394f * _S338, -0.60000002384185791f * _S336 - 0.47999998927116394f * _S337 + 0.63999998569488525f * _S338);
}

static __device__ float convPuffs_0(float3  x_32)
{
    float3  fl_0 = floor_0(x_32);
    int3  _S339 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_2 = x_32 - fl_0;
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
    int3  _S340 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S340 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S341 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_16 = _S341 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S339 + off_0) - f_2;
                float _S342 = (F32_min((nearest_1), (dot_0(d_16, d_16))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S342;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_47, float3  p_8, float scale_1)
{
    float3  _S343 = make_float3 (p_8.x, p_8.y - c_47->cvRise_0, p_8.z) / make_float3 (scale_1);
    int i_20 = int(0);
    float3  x_33 = _S343;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_20 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_20 >= (c_47->cvOctaves_0))
        {
            break;
        }
        float3  x_34 = convTwist_0(x_33);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_34);
        float norm_3 = norm_2 + amp_2;
        float3  x_35 = x_34 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_20 = i_20 + int(1);
        x_33 = x_35;
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
    return clamp_0(raw_0 * 2.20000004768371582f - 1.15999996662139893f, -1.0f, 1.0f);
}

static __device__ float convInside_0(ConvectionInput_0 * c_48, float d_17, float lift_2, float3  x_36, float scale_2)
{
    float _S344 = d_17 + lift_2;
    if(_S344 <= 0.0f)
    {
        return _S344;
    }
    if((d_17 - lift_2) >= 12.0f)
    {
        return 12.0f;
    }
    float _S345 = convBillow_0(c_48, x_36, scale_2);
    return d_17 + lift_2 * _S345;
}

static __device__ float convCapGrain_0(ConvectionInput_0 * c_49, float2  rel_4, float scale_3)
{
    return saturate_0(0.80000001192092896f + 0.13330000638961792f * gradientNoise_0(make_float3 (rel_4.x / scale_3 + c_49->cvHeroSeed_0.x * 0.00100000004749745f, 0.37000000476837158f, rel_4.y / scale_3 + c_49->cvHeroSeed_0.z * 0.00100000004749745f)));
}

static __device__ float convCapDensity_0(ConvectionInput_0 * c_50, float3  p_9, float above_9)
{
    float2  rel_5 = float2 {p_9.x, p_9.z} - c_50->cvHeroAt_0;
    float r2_3 = dot_1(rel_5, rel_5);
    float _S346 = c_50->cvHeroRadius_0;
    float _S347 = c_50->cvPileusThick_0;
    float best_3;
    if((c_50->cvPileusThick_0) > 0.0f)
    {
        float rp_1 = 0.60000002384185791f * _S346;
        float _S348 = rp_1 * rp_1;
        if(r2_3 < _S348)
        {
            float lens_0 = 1.0f - r2_3 / _S348;
            float _S349 = c_50->cvPileusGap_0;
            float _S350 = convHeroHeight_0(c_50, (F32_sqrt((r2_3))) * 0.60000002384185791f);
            float most_0 = 0.5f * _S347 * lens_0;
            float _S351 = (F32_abs((above_9 - (_S349 + _S350))));
            if(_S351 < most_0)
            {
                float _S352 = convCapGrain_0(c_50, rel_5, 900.0f);
                float s_14 = most_0 * _S352 - _S351;
                if(s_14 > 0.0f)
                {
                    best_3 = (F32_max((0.0f), (0.44999998807907104f * smoothstep_0(0.0f, 15.0f, s_14))));
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
    float _S353 = c_50->cvVelumThick_0;
    if((c_50->cvVelumThick_0) > 0.0f)
    {
        float ext_1 = 1.89999997615814209f * _S346;
        if(r2_3 < (ext_1 * ext_1))
        {
            float r_11 = (F32_sqrt((r2_3)));
            float2  dir_0;
            if(r_11 > 0.00100000004749745f)
            {
                dir_0 = rel_5 / make_float2 (r_11);
            }
            else
            {
                dir_0 = make_float2 (1.0f, 0.0f);
            }
            float edge_1 = _S346 + (ext_1 - _S346) * saturate_0(0.875f + 0.08330000191926956f * gradientNoise_0(make_float3 (1.70000004768371582f * dir_0.x + c_50->cvHeroSeed_0.x * 0.00100000004749745f, 2.29999995231628418f, 1.70000004768371582f * dir_0.y + c_50->cvHeroSeed_0.z * 0.00100000004749745f)));
            float _S354 = 0.5f * _S353;
            float most_1 = _S354 * (1.0f - smoothstep_0(_S346 + 0.40000000596046448f * (edge_1 - _S346), edge_1, r_11));
            float _S355 = (F32_abs((above_9 - (c_50->cvVelumHeight_0 + _S354 * (1.0f - smoothstep_0(_S346, 2.0f * _S346, r_11))))));
            if(_S355 < most_1)
            {
                float _S356 = convCapGrain_0(c_50, rel_5, 2500.0f);
                float s_15 = most_1 * _S356 - _S355;
                if(s_15 > 0.0f)
                {
                    best_3 = (F32_max((best_3), (0.2199999988079071f * smoothstep_0(0.0f, 15.0f, s_15))));
                }
            }
        }
    }
    return c_50->cvSigma_0 * best_3;
}

static __device__ void convGroupFold_0(float d_18, float3  x_37, float lift_3, float lobe_2, float * gMax_0, float * gSum_0, float3  * gX_0, float * gLift_0, float * gLobe_0)
{
    if(d_18 > (*gMax_0))
    {
        float scale_4 = (F32_exp(((*gMax_0 - d_18) / 50.0f)));
        *gSum_0 = *gSum_0 * scale_4;
        *gX_0 = *gX_0 * make_float3 (scale_4);
        *gLift_0 = *gLift_0 * scale_4;
        *gLobe_0 = *gLobe_0 * scale_4;
        *gMax_0 = d_18;
    }
    float wt_0 = (F32_exp(((d_18 - *gMax_0) / 50.0f)));
    *gSum_0 = *gSum_0 + wt_0;
    *gX_0 = *gX_0 + make_float3 (wt_0) * x_37;
    *gLift_0 = *gLift_0 + wt_0 * lift_3;
    *gLobe_0 = *gLobe_0 + wt_0 * lobe_2;
    return;
}

static __device__ float convGroupInside_0(ConvectionInput_0 * c_51, float3  p_10, float above_10, bool nearGroup_3)
{
    bool _S357;
    float gMax_1 = -1.00000001504746622e+30f;
    float gSum_1 = 0.0f;
    float gLift_1 = 0.0f;
    float gLobe_1 = 0.0f;
    float3  gX_1 = make_float3 (0.0f, 0.0f, 0.0f);
    float d_19;
    float amount_2;
    float lobe_3;
    float3  x_38;
    bool anyTurret_0 = false;
    int k_10 = int(0);
    for(;;)
    {
        if(k_10 < int(5))
        {
        }
        else
        {
            break;
        }
        if(!nearGroup_3)
        {
            _S357 = true;
        }
        else
        {
            _S357 = k_10 >= (c_51->cvTurretCount_0);
        }
        if(_S357)
        {
            break;
        }
        float4  _S358 = convTurret_0(c_51, k_10);
        float kt_1;
        bool _S359 = convTurretSmooth_0(c_51, _S358, p_10, above_10, &d_19, &x_38, &kt_1);
        if(_S359)
        {
            float _S360 = convLift_0(c_51, above_10, kt_1);
            convGroupFold_0(d_19, x_38, _S360, kt_1, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
            anyTurret_0 = true;
        }
        k_10 = k_10 + int(1);
    }
    bool _S361 = convHeroSmooth_0(c_51, p_10, above_10, &d_19, &x_38, &amount_2, &lobe_3);
    float heroLift_0;
    if(_S361)
    {
        float _S362 = convLift_0(c_51, above_10, amount_2);
        heroLift_0 = _S362;
    }
    else
    {
        heroLift_0 = 0.0f;
    }
    if(!_S361)
    {
        _S357 = !anyTurret_0;
    }
    else
    {
        _S357 = false;
    }
    if(_S357)
    {
        return -1.00000001504746622e+30f;
    }
    float lift_4;
    float lobeAt_0;
    float3  at_2;
    if(!anyTurret_0)
    {
        gMax_1 = d_19;
        lift_4 = heroLift_0;
        at_2 = x_38;
        lobeAt_0 = lobe_3;
    }
    else
    {
        if(_S361)
        {
            convGroupFold_0(d_19, x_38, heroLift_0, lobe_3, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
        }
        float3  _S363 = gX_1 / make_float3 (gSum_1);
        float _S364 = gLobe_1 / gSum_1;
        lift_4 = gLift_1 / gSum_1;
        at_2 = _S363;
        lobeAt_0 = _S364;
    }
    float _S365 = convInside_0(c_51, gMax_1, lift_4, at_2 + c_51->cvHeroSeed_0, c_51->cvBillowScale_0 * lobeAt_0);
    return _S365;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_52, float3  p_11, float above_11)
{
    float d_20;
    float amount_3;
    float lobe_4;
    float3  x_39;
    bool _S366 = convHeroSmooth_0(c_52, p_11, above_11, &d_20, &x_39, &amount_3, &lobe_4);
    if(!_S366)
    {
        return -1.00000001504746622e+30f;
    }
    float _S367 = convLift_0(c_52, above_11, amount_3);
    float _S368 = convInside_0(c_52, d_20, _S367, x_39 + c_52->cvHeroSeed_0, c_52->cvBillowScale_0 * lobe_4);
    return _S368;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_53, float3  p_12)
{
    float _S369 = p_12.y;
    float above_12 = _S369 - c_53->cvBase_0;
    float _S370 = c_53->cvMammaDepth_0;
    bool rampBand_0;
    if(above_12 < (- c_53->cvMammaDepth_0))
    {
        rampBand_0 = true;
    }
    else
    {
        float _S371 = convCeiling_0(c_53);
        rampBand_0 = above_12 > _S371;
    }
    if(rampBand_0)
    {
        return 0.0f;
    }
    float2  _S372 = float2 {p_12.x, p_12.z};
    float2  fromHero_0 = _S372 - c_53->cvHeroAt_0;
    bool nearGroup_4 = (dot_1(fromHero_0, fromHero_0)) < (c_53->cvGroupReach_0 * c_53->cvGroupReach_0);
    bool _S373 = _S370 > 0.0f;
    if(_S373)
    {
        rampBand_0 = above_12 < 0.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    if(rampBand_0)
    {
        float _S374 = convMammaSag_0(c_53, _S372, nearGroup_4, - above_12);
        float hang_0 = _S374 + above_12;
        if(hang_0 <= 0.0f)
        {
            return 0.0f;
        }
        return c_53->cvSigma_0 * (F32_sqrt((saturate_0(hang_0 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, hang_0);
    }
    float _S375 = convLift_0(c_53, above_12, 1.0f - 0.60000002384185791f * c_53->cvLacunarity_0);
    if(_S373)
    {
        rampBand_0 = above_12 < 40.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    bool moated_1;
    float capDensity_0;
    float sag_0;
    float baseField_0;
    float inside_3;
    if((c_53->cvHeroAlone_0) == int(0))
    {
        float capMoat_1 = 0.0f;
        float2  _S376 = make_float2 (0.0f, 0.0f);
        float2  gMoat_1 = _S376;
        if((c_53->cvMoat_0) > 0.0f)
        {
            moated_1 = nearGroup_4;
        }
        else
        {
            moated_1 = false;
        }
        if(moated_1)
        {
            float _S377 = convMoat_0(c_53, _S372, &gMoat_1, &capMoat_1);
            capDensity_0 = _S377;
        }
        else
        {
            capDensity_0 = 1.0f;
        }
        if(capDensity_0 > 0.0f)
        {
            float2  q_11 = _S372 - c_53->cvDrift_0;
            float2  slope_6;
            float _S378 = convUpdraftGrad_0(c_53, q_11, &slope_6);
            float _S379 = convSlopeCap_0(c_53);
            float cap_6;
            if(moated_1)
            {
                slope_6 = slope_6 * make_float2 (capDensity_0) + gMoat_1 * make_float2 (_S378);
                float cap_7 = _S379 + capMoat_1;
                sag_0 = _S378 * capDensity_0;
                cap_6 = cap_7;
            }
            else
            {
                sag_0 = _S378;
                cap_6 = _S379;
            }
            if(rampBand_0)
            {
                float _S380 = convFieldBaseInside_0(c_53, sag_0, slope_6, cap_6);
                baseField_0 = _S380;
            }
            else
            {
                baseField_0 = -1.00000001504746622e+30f;
            }
            float _S381 = convTowerHeight_0(c_53, sag_0);
            float v_5 = _S381 - above_12;
            float _S382 = convNeededUpdraft_0(c_53, above_12);
            float delta_1 = sag_0 - _S382;
            float d_21 = convSurfaceDistance_0(v_5, delta_1, (F32_min((length_1(slope_6)), (cap_6))));
            if((d_21 + _S375) > 0.0f)
            {
                if((F32_abs((v_5))) > 9.99999997475242708e-07f)
                {
                    inside_3 = d_21 * (d_21 / v_5);
                }
                else
                {
                    inside_3 = 0.0f;
                }
                float2  shiftAcross_0;
                if((F32_abs((delta_1))) > 9.999999960041972e-13f)
                {
                    shiftAcross_0 = slope_6 * make_float2 (- d_21 * (d_21 / delta_1));
                }
                else
                {
                    shiftAcross_0 = _S376;
                }
                float _S383 = convInside_0(c_53, d_21, _S375, make_float3 (q_11.x + shiftAcross_0.x, _S369 + inside_3, q_11.y + shiftAcross_0.y), c_53->cvBillowScale_0);
                inside_3 = _S383;
            }
            else
            {
                inside_3 = -1.00000001504746622e+30f;
            }
        }
        else
        {
            inside_3 = -1.00000001504746622e+30f;
            baseField_0 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        inside_3 = -1.00000001504746622e+30f;
        baseField_0 = -1.00000001504746622e+30f;
    }
    bool _S384 = (c_53->cvHeroTop_0) > 0.0f;
    if(_S384)
    {
        if((c_53->cvPileusThick_0) > 0.0f)
        {
            moated_1 = true;
        }
        else
        {
            moated_1 = (c_53->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        float _S385 = convCapDensity_0(c_53, p_12, above_12);
        capDensity_0 = _S385;
    }
    else
    {
        capDensity_0 = 0.0f;
    }
    if(_S384)
    {
        moated_1 = inside_3 < 12.0f;
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        if((c_53->cvTurretCount_0) > int(0))
        {
            float _S386 = convGroupInside_0(c_53, p_12, above_12, nearGroup_4);
            inside_3 = (F32_max((inside_3), (_S386)));
        }
        else
        {
            float _S387 = convHeroInside_0(c_53, p_12, above_12);
            inside_3 = (F32_max((inside_3), (_S387)));
        }
    }
    if(inside_3 <= 0.0f)
    {
        return capDensity_0;
    }
    if(rampBand_0)
    {
        float _S388 = convPouches_0(c_53, _S372 - c_53->cvDrift_0);
        if(_S388 > 0.0f)
        {
            float _S389 = convGroupBaseInside_0(c_53, _S372, nearGroup_4);
            float _S390 = convMammaSagOf_0(c_53, _S388, (F32_max((baseField_0), (_S389))));
            sag_0 = _S390;
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
    return (F32_max((c_53->cvSigma_0 * (F32_sqrt((saturate_0((above_12 + sag_0) / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_3)), (capDensity_0)));
}

static __device__ float densityAt_0(Medium_0 * m_8, StructuredBuffer<float2 > disp_6, float3  p_13)
{
    float _S391 = p_13.y;
    bool _S392;
    if(_S391 < (m_8->slabBottom_0))
    {
        _S392 = true;
    }
    else
    {
        _S392 = _S391 > (m_8->slabTop_0);
    }
    if(_S392)
    {
        return 0.0f;
    }
    if((m_8->clipOn_0) != int(0))
    {
        float2  _S393 = float2 {p_13.x, p_13.z};
        if(any_1(_S393 < (m_8->clipLo_0)))
        {
            _S392 = true;
        }
        else
        {
            _S392 = any_1(_S393 > (m_8->clipHi_0));
        }
    }
    else
    {
        _S392 = false;
    }
    if(_S392)
    {
        return 0.0f;
    }
    float _S394 = m_8->fadeRadius_0;
    float fade_0;
    if((m_8->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S394 - length_1(float2 {p_13.x, p_13.z} - m_8->fadeAt_0)) / (F32_max((m_8->fadeWidth_0), (1.0f))));
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
    int _S395 = m_8->mode_0;
    if((m_8->mode_0) == int(0))
    {
        return m_8->density_0 * fade_0;
    }
    if(_S395 == int(2))
    {
        float _S396 = iceDensity_0(&m_8->gen_0, disp_6, p_13);
        return _S396 * fade_0;
    }
    if(_S395 == int(3))
    {
        float _S397 = convectionDensity_0(&m_8->conv_0, p_13);
        return _S397 * fade_0;
    }
    float3  d_22 = (p_13 - m_8->coreCentre_0) / make_float3 ((F32_max((m_8->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_8->density_0 + m_8->coreDensity_0 * (F32_exp((- dot_0(d_22, d_22))))) * fade_0;
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

static __device__ float2  airMapAxisV_0(LayerShadowMap_0 * m_9)
{
    return make_float2 (- m_9->smAxisU_0.y, m_9->smAxisU_0.x);
}

static __device__ float clampf_0(float v_6, float lo_11, float hi_10)
{
    float _S398;
    if(v_6 < lo_11)
    {
        _S398 = lo_11;
    }
    else
    {
        if(v_6 > hi_10)
        {
            _S398 = hi_10;
        }
        else
        {
            _S398 = v_6;
        }
    }
    return _S398;
}

static __device__ float airMapTexel_0(LayerShadowMap_0 * m_10, int iu_0, int iv_0, int k_11)
{
    float _S399 = __ldg((&(m_10->smTexels_0)[(k_11 * m_10->smDimV_0 + iv_0) * m_10->smDimU_0 + iu_0]));
    return _S399;
}

static __device__ float layerMapTransmittance_0(LayerShadowMap_0 * m_11, float3  p_14)
{
    int _S400 = m_11->smDimU_0;
    int _S401 = m_11->smDimV_0;
    int _S402 = m_11->smSlices_0;
    uint want_0 = uint(m_11->smDimU_0 * m_11->smDimV_0 * m_11->smSlices_0);
    bool _S403;
    if(want_0 == 0U)
    {
        _S403 = true;
    }
    else
    {
        _S403 = uint(StructuredBuffer_getCount_0(m_11->smTexels_0)) < want_0;
    }
    if(_S403)
    {
        return 1.0f;
    }
    float _S404 = p_14.y;
    float _S405 = m_11->smTop_0;
    if(_S404 >= (m_11->smTop_0))
    {
        return 1.0f;
    }
    float3  _S406 = m_11->smSun_0;
    float _S407 = m_11->smBottom_0;
    float2  q_12 = float2 {p_14.x, p_14.z} + float2 {_S406.x, _S406.z} * make_float2 ((m_11->smBottom_0 - _S404) / m_11->smSun_0.y) - m_11->smCentre_0;
    float2  _S408 = m_11->smLo_0;
    float2  _S409 = m_11->smTexel_0;
    float fu_0 = (dot_1(q_12, m_11->smAxisU_0) - m_11->smLo_0.x) / m_11->smTexel_0.x - 0.5f;
    float2  _S410 = airMapAxisV_0(m_11);
    float fv_0 = (dot_1(q_12, _S410) - _S408.y) / _S409.y - 0.5f;
    if(fu_0 >= -0.5f)
    {
        _S403 = fv_0 >= -0.5f;
    }
    else
    {
        _S403 = false;
    }
    if(_S403)
    {
        _S403 = fu_0 <= (float(_S400) - 0.5f);
    }
    else
    {
        _S403 = false;
    }
    if(_S403)
    {
        _S403 = fv_0 <= (float(_S401) - 0.5f);
    }
    else
    {
        _S403 = false;
    }
    if(!_S403)
    {
        return 1.0f;
    }
    int _S411 = _S400 - int(1);
    float fu_1 = clampf_0(fu_0, 0.0f, float(_S411));
    int _S412 = _S401 - int(1);
    float fv_1 = clampf_0(fv_0, 0.0f, float(_S412));
    int u0_0 = int(fu_1);
    int v0_0 = int(fv_1);
    int _S413 = (I32_min((u0_0 + int(1)), (_S411)));
    int _S414 = (I32_min((v0_0 + int(1)), (_S412)));
    float tu_0 = fu_1 - float(u0_0);
    float tv_0 = fv_1 - float(v0_0);
    int _S415 = _S402 - int(1);
    float fk_0 = clampf_0((_S404 - _S407) / (F32_max((_S405 - _S407), (1.0f))), 0.0f, 1.0f) * float(_S415);
    int _S416 = (I32_min((int(fk_0)), (_S415)));
    int _S417 = (I32_min((_S416 + int(1)), (_S415)));
    float tk_0 = fk_0 - float(_S416);
    float _S418 = airMapTexel_0(m_11, u0_0, v0_0, _S416);
    float _S419 = 1.0f - tu_0;
    float _S420 = _S418 * _S419;
    float _S421 = airMapTexel_0(m_11, _S413, v0_0, _S416);
    float a0_0 = _S420 + _S421 * tu_0;
    float _S422 = airMapTexel_0(m_11, u0_0, _S414, _S416);
    float _S423 = _S422 * _S419;
    float _S424 = airMapTexel_0(m_11, _S413, _S414, _S416);
    float b0_0 = _S423 + _S424 * tu_0;
    float _S425 = airMapTexel_0(m_11, u0_0, v0_0, _S417);
    float _S426 = _S425 * _S419;
    float _S427 = airMapTexel_0(m_11, _S413, v0_0, _S417);
    float a1_0 = _S426 + _S427 * tu_0;
    float _S428 = airMapTexel_0(m_11, u0_0, _S414, _S417);
    float _S429 = _S428 * _S419;
    float _S430 = airMapTexel_0(m_11, _S413, _S414, _S417);
    float _S431 = 1.0f - tv_0;
    return (a0_0 * _S431 + b0_0 * tv_0) * (1.0f - tk_0) + (a1_0 * _S431 + (_S429 + _S430 * tu_0) * tv_0) * tk_0;
}

static __device__ float transmittanceUpTo_0(Medium_0 * m_12, MajorantGrid_0 * g_14, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > disp_7, Rng_0 * rng_1, float3  p_15, float3  dir_1, float tMax_1, int * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S432 = slabRange_0(m_12, p_15, dir_1, &t0_2, &t1_2);
    if(!_S432)
    {
        return 1.0f;
    }
    float _S433 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S433;
    t1_2 = (F32_min((t1_2), (tMax_1)));
    Dda_0 _S434 = ddaInit_0(g_14, p_15, dir_1, _S433);
    Dda_0 dda_1 = _S434;
    float _S435 = m_12->majorant_0;
    float _S436 = gridBound_0(m_12, g_14, bounds_2, disp_7, (&dda_1)->cell_0, m_12->majorant_0);
    float localMaj_0 = _S436;
    int i_21 = int(0);
    float t_10 = _S433;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_21 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_1 = *steps_1 + int(1);
        Dda_0 _S437 = dda_1;
        float _S438 = ddaExit_0(&_S437);
        float _S439 = (F32_min((_S438), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S439 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S440 = gridBound_0(m_12, g_14, bounds_2, disp_7, (&dda_1)->cell_0, _S435);
            localMaj_0 = _S440;
            t_10 = _S439;
            i_21 = i_21 + int(1);
            continue;
        }
        float _S441 = randFloat_0(rng_1);
        float t_11 = t_10 - (F32_log(((F32_max((1.0f - _S441), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_11 >= _S439)
        {
            if(_S439 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S442 = gridBound_0(m_12, g_14, bounds_2, disp_7, (&dda_1)->cell_0, _S435);
            localMaj_0 = _S442;
            t_10 = _S439;
            i_21 = i_21 + int(1);
            continue;
        }
        float _S443 = densityAt_0(m_12, disp_7, p_15 + dir_1 * make_float3 (t_11));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S443 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S444 = randFloat_0(rng_1);
            if(_S444 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_10 = t_11;
        tr_0 = tr_2;
        i_21 = i_21 + int(1);
    }
    return tr_0;
}

static __device__ float transmittance_0(Medium_0 * m_13, MajorantGrid_0 * g_15, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > disp_8, Rng_0 * rng_2, float3  p_16, float3  dir_2, int * steps_2)
{
    float _S445 = transmittanceUpTo_0(m_13, g_15, bounds_3, disp_8, rng_2, p_16, dir_2, 1.00000001504746622e+30f, steps_2);
    return _S445;
}

static __device__ float transmittanceHandoff_0(Medium_0 * m_14, MajorantGrid_0 * g_16, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > disp_9, LayerShadowMap_0 * map_0, float handoff_0, Rng_0 * rng_3, float3  p_17, float3  dir_3, int * steps_3)
{
    float t0_3;
    float t1_3;
    bool _S446 = slabRange_0(m_14, p_17, dir_3, &t0_3, &t1_3);
    if(!_S446)
    {
        return 1.0f;
    }
    float _S447 = (F32_max((t0_3), (0.0f)));
    t0_3 = _S447;
    float _S448 = map_0->smBottom_0;
    float _S449 = (map_0->smTop_0 - map_0->smBottom_0) / float((I32_max((map_0->smSlices_0 - int(1)), (int(1)))));
    Dda_0 _S450 = ddaInit_0(g_16, p_17, dir_3, _S447);
    Dda_0 dda_2 = _S450;
    float _S451 = m_14->majorant_0;
    float _S452 = gridBound_0(m_14, g_16, bounds_4, disp_9, (&dda_2)->cell_0, m_14->majorant_0);
    float tEnd_1 = t1_3;
    float localMaj_1 = _S452;
    bool toPlane_0 = false;
    float clearFrom_0 = _S447;
    int i_22 = int(0);
    float t_12 = _S447;
    float tr_3 = 1.0f;
    for(;;)
    {
        if(i_22 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_3 = *steps_3 + int(1);
        Dda_0 _S453 = dda_2;
        float _S454 = ddaExit_0(&_S453);
        float _S455 = (F32_min((_S454), (tEnd_1)));
        float tEnd_2;
        bool toPlane_1;
        if(localMaj_1 <= 0.0f)
        {
            if(_S455 >= tEnd_1)
            {
                break;
            }
            ddaAdvance_0(&dda_2);
            float _S456 = gridBound_0(m_14, g_16, bounds_4, disp_9, (&dda_2)->cell_0, _S451);
            tEnd_2 = tEnd_1;
            localMaj_1 = _S456;
            toPlane_1 = toPlane_0;
            t_12 = _S455;
            int i_23 = i_22 + int(1);
            tEnd_1 = tEnd_2;
            toPlane_0 = toPlane_1;
            i_22 = i_23;
            continue;
        }
        float _S457 = randFloat_0(rng_3);
        float t_13 = t_12 - (F32_log(((F32_max((1.0f - _S457), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_13 >= _S455)
        {
            if(_S455 >= tEnd_1)
            {
                break;
            }
            ddaAdvance_0(&dda_2);
            float _S458 = gridBound_0(m_14, g_16, bounds_4, disp_9, (&dda_2)->cell_0, _S451);
            tEnd_2 = tEnd_1;
            localMaj_1 = _S458;
            toPlane_1 = toPlane_0;
            t_12 = _S455;
            int i_23 = i_22 + int(1);
            tEnd_1 = tEnd_2;
            toPlane_0 = toPlane_1;
            i_22 = i_23;
            continue;
        }
        float3  x_40 = p_17 + dir_3 * make_float3 (t_13);
        float _S459 = densityAt_0(m_14, disp_9, x_40);
        float clearFrom_1;
        float tr_4;
        if(_S459 > 0.0f)
        {
            float tr_5 = tr_3 * (F32_max((0.0f), (1.0f - _S459 / localMaj_1)));
            float _S460 = t1_3;
            if(tr_5 < 0.00999999977648258f)
            {
                float _S461 = randFloat_0(rng_3);
                if(_S461 > 0.5f)
                {
                    return 0.0f;
                }
                tEnd_2 = tr_5 * 2.0f;
            }
            else
            {
                tEnd_2 = tr_5;
            }
            float _S462 = tEnd_2;
            tEnd_2 = _S460;
            toPlane_1 = false;
            clearFrom_1 = t_13;
            tr_4 = _S462;
        }
        else
        {
            bool _S463;
            if(!toPlane_0)
            {
                _S463 = (t_13 - clearFrom_0) >= handoff_0;
            }
            else
            {
                _S463 = false;
            }
            if(_S463)
            {
                float _S464 = x_40.y;
                float tPlane_0 = t_13 + (F32_max((_S448 + (F32_ceil(((_S464 - _S448) / _S449))) * _S449 - _S464), (0.0f))) / (F32_max((dir_3.y), (9.99999997475242708e-07f)));
                if(tPlane_0 < t1_3)
                {
                    tEnd_2 = tPlane_0;
                    toPlane_1 = true;
                }
                else
                {
                    tEnd_2 = tEnd_1;
                    toPlane_1 = toPlane_0;
                }
            }
            else
            {
                tEnd_2 = tEnd_1;
                toPlane_1 = toPlane_0;
            }
            clearFrom_1 = clearFrom_0;
            tr_4 = tr_3;
        }
        clearFrom_0 = clearFrom_1;
        t_12 = t_13;
        tr_3 = tr_4;
        int i_23 = i_22 + int(1);
        tEnd_1 = tEnd_2;
        toPlane_0 = toPlane_1;
        i_22 = i_23;
    }
    if(toPlane_0)
    {
        float _S465 = layerMapTransmittance_0(map_0, p_17 + dir_3 * make_float3 (tEnd_1));
        return tr_3 * _S465;
    }
    return tr_3;
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

struct Environment_0
{
    float3  uniformRadiance_0;
    SkyInput_0 sky_0;
    int envMode_0;
};

struct PhaseInput_0
{
    float hgG_0;
    float draineG_0;
    float draineAlpha_0;
    float draineW_0;
    int useIce_0;
    float lobeG_0;
    float lobeWeight_0;
};

struct Scene_0
{
    Medium_0 medium_0;
    MajorantGrid_0 grid_0;
    Environment_0 environment_0;
    float3  albedo_0;
    float3  sunIrradiance_0;
    float3  sunDir_0;
    float shadowOffset_0;
    int maxBounces_0;
    int rrStartBounce_0;
    float neeTentativeScale_0;
    int aerialMode_0;
    int layer2On_0;
    Medium_0 medium2_0;
    MajorantGrid_0 grid2_0;
    float3  albedo2_0;
    PhaseInput_0 phase2_0;
    int airMapOn_0;
    LayerShadowMap_0 airMapIce_0;
    LayerShadowMap_0 airMapCu_0;
    float shadowHandoff_0;
    int ltCount_0;
    StructuredBuffer<float> ltBuffer_0;
    float3  ltAmbient_0;
};

static __device__ float sceneTransmittance_0(Scene_0 * s_16, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > drift_1, Rng_0 * rng_4, float3  p_18, float3  dir_4, int * steps_4)
{
    float _S466 = s_16->shadowHandoff_0;
    bool handoff_1;
    if((s_16->shadowHandoff_0) > 0.0f)
    {
        handoff_1 = (s_16->airMapOn_0) != int(0);
    }
    else
    {
        handoff_1 = false;
    }
    bool _S467;
    if(handoff_1)
    {
        _S467 = (p_18.y) < ((&s_16->medium_0)->slabBottom_0);
    }
    else
    {
        _S467 = false;
    }
    float tr_6;
    if(_S467)
    {
        float _S468 = layerMapTransmittance_0(&s_16->airMapIce_0, p_18);
        tr_6 = _S468;
    }
    else
    {
        float _S469 = transmittance_0(&s_16->medium_0, &s_16->grid_0, bounds_5, drift_1, rng_4, p_18, dir_4, steps_4);
        tr_6 = _S469;
    }
    if((s_16->layer2On_0) != int(0))
    {
        _S467 = tr_6 > 0.0f;
    }
    else
    {
        _S467 = false;
    }
    if(_S467)
    {
        MajorantGrid_0 _S470 = gridFor_0(&s_16->medium2_0, &s_16->grid2_0, p_18);
        if(handoff_1)
        {
            float _S471 = _S466 * (F32_max(((&s_16->airMapCu_0)->smTexel_0.x), ((&s_16->airMapCu_0)->smTexel_0.y)));
            MajorantGrid_0 _S472 = _S470;
            float _S473 = transmittanceHandoff_0(&s_16->medium2_0, &_S472, bounds_5, drift_1, &s_16->airMapCu_0, _S471, rng_4, p_18, dir_4, steps_4);
            tr_6 = tr_6 * _S473;
        }
        else
        {
            MajorantGrid_0 _S474 = _S470;
            float _S475 = transmittance_0(&s_16->medium2_0, &_S474, bounds_5, drift_1, rng_4, p_18, dir_4, steps_4);
            tr_6 = tr_6 * _S475;
        }
    }
    return tr_6;
}

static __device__ float hg_0(float cosT_0, float g_17)
{
    float _S476 = g_17 * g_17;
    float d_23 = 1.0f + _S476 - 2.0f * g_17 * cosT_0;
    return (1.0f - _S476) / (12.56637096405029297f * d_23 * (F32_sqrt(((F32_max((d_23), (9.99999997475242708e-07f)))))));
}

static __device__ float phaseIce_0(float cosT_1)
{
    float t_14 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_1(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_14 * t_14))) * 0.34999999403953552f;
}

static __device__ float draine_0(float cosT_2, float g_18, float a_5)
{
    float _S477 = g_18 * g_18;
    float _S478 = 2.0f * g_18;
    float d_24 = 1.0f + _S477 - _S478 * cosT_2;
    return (1.0f - _S477) / (12.56637096405029297f * d_24 * (F32_sqrt(((F32_max((d_24), (9.99999997475242708e-07f))))))) * (1.0f + a_5 * cosT_2 * cosT_2) / (1.0f + a_5 * (1.0f + _S478 * g_18) / 3.0f);
}

static __device__ float phaseLiquid_0(PhaseInput_0 * p_19, float cosT_3)
{
    return (1.0f - p_19->draineW_0) * hg_0(cosT_3, p_19->hgG_0) + p_19->draineW_0 * draine_0(cosT_3, p_19->draineG_0, p_19->draineAlpha_0);
}

static __device__ float phaseAt_0(PhaseInput_0 * p_20, float cosT_4)
{
    float _S479;
    if((p_20->useIce_0) != int(0))
    {
        _S479 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S480 = phaseLiquid_0(p_20, cosT_4);
        _S479 = _S480;
    }
    return _S479;
}

static __device__ float phaseCamera_0(PhaseInput_0 * p_21, float cosT_5)
{
    float _S481 = phaseAt_0(p_21, cosT_5);
    float _S482 = p_21->lobeWeight_0;
    float v_7;
    if((p_21->lobeWeight_0) > 0.0f)
    {
        v_7 = _S481 + _S482 * hg_0(cosT_5, p_21->lobeG_0);
    }
    else
    {
        v_7 = _S481;
    }
    return v_7;
}

static __device__ float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_25 = altitude_0 - shellHeight_0;
    return d_25 * (d_25 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_4, float c_54)
{
    float disc_0 = b_4 * b_4 - c_54;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_4 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_5, float c_55)
{
    float disc_1 = b_5 * b_5 - c_55;
    if(disc_1 < 0.0f)
    {
        return -1.0f;
    }
    return - b_5 - (F32_sqrt((disc_1)));
}

static __device__ float3  rayleighCoefficients_0()
{
    return make_float3 (5.80200003241770901e-06f, 0.00001355800031888f, 0.00003310000101919f);
}

static __device__ float mieCoefficient_0(float turbidity_1)
{
    return 3.99600003220257349e-06f * (turbidity_1 / 2.20000004768371582f);
}

static __device__ float altitudeFromQ_0(float q_13, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_13;
    float _S483;
    if(rr_0 > 0.0f)
    {
        _S483 = rr_0;
    }
    else
    {
        _S483 = 0.0f;
    }
    return q_13 / (planetRadius_2 + (F32_sqrt((_S483))));
}

static __device__ float3  airTransmittance_0(SkyInput_0 * p_22, float originAltitude_0, float3  rayDir_0, float dist_1)
{
    float _S484 = p_22->planetRadius_0;
    float planetRadius_3;
    if((p_22->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S484;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S485 = p_22->scaleHeight_0;
    float scaleHeight_1;
    if((p_22->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S485;
    }
    else
    {
        scaleHeight_1 = 1.0f;
    }
    float atmosphereHeight_0 = scaleHeight_1 * 8.0f;
    float observerAltitude_0;
    if(originAltitude_0 > 0.0f)
    {
        observerAltitude_0 = originAltitude_0;
    }
    else
    {
        observerAltitude_0 = 0.0f;
    }
    float b_6 = (planetRadius_3 + observerAltitude_0) * rayDir_0.y;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(b_6, shellC_0(observerAltitude_0, planetRadius_3, atmosphereHeight_0));
    bool _S486;
    if(tTop_0 <= 0.0f)
    {
        _S486 = true;
    }
    else
    {
        _S486 = !(dist_1 > 0.0f);
    }
    if(_S486)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float tGround_0 = shellEnter_0(b_6, cGround_0);
    float tMax_2;
    if(tGround_0 > 0.0f)
    {
        tMax_2 = tGround_0;
    }
    else
    {
        tMax_2 = tTop_0;
    }
    if(dist_1 < tMax_2)
    {
        tMax_2 = dist_1;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaMExt_0 = mieCoefficient_0(p_22->turbidity_0) * 1.11000001430511475f;
    float tPrev_0 = 0.0f;
    int i_24 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_24 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S487 = i_24 + int(1);
        float tNext_0 = tMax_2 * float(_S487 * _S487) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_24 = _S487;
            continue;
        }
        float h_5 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_6 + tMid_0 * tMid_0, planetRadius_3);
        float hc_0;
        if(h_5 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_5;
        }
        float _S488 = - hc_0;
        float depthM_1 = depthM_0 + (F32_exp((_S488 / 1200.0f))) * dt_0;
        depthR_0 = depthR_0 + (F32_exp((_S488 / scaleHeight_1))) * dt_0;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_24 = _S487;
    }
    float _S489 = betaMExt_0 * depthM_0;
    return make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S489)))), (F32_exp((- (betaR_0.y * depthR_0 + _S489)))), (F32_exp((- (betaR_0.z * depthR_0 + _S489)))));
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_23)
{
    return 20.0f * p_23->sunIntensity_0;
}

static __device__ float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static __device__ float3  normalizeExact_0(float3  v_8)
{
    float len2_0 = dot_0(v_8, v_8);
    if(len2_0 <= 0.0f)
    {
        return make_float3 (0.0f, 1.0f, 0.0f);
    }
    return v_8 * make_float3 (1.0f / (F32_sqrt((len2_0))));
}

static __device__ float3  sunDirection_0(SkyInput_0 * p_24)
{
    float az_0 = toRadians_0(p_24->sunAzimuth_0);
    float el_0 = toRadians_0(p_24->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static __device__ float lutMuFor_0(float3  geocentric_0, float3  sun_0)
{
    float len_1 = length_0(geocentric_0);
    float _S490;
    if(len_1 > 1.0f)
    {
        _S490 = dot_0(geocentric_0, sun_0) / len_1;
    }
    else
    {
        _S490 = dot_0(geocentric_0, sun_0);
    }
    return _S490;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_25, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S491 = p_25->transmittanceLut_0;
    if(uint(StructuredBuffer_getCount_0(p_25->transmittanceLut_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S492 = p_25->scaleHeight_0;
    float scaleHeight_2;
    if((p_25->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S492;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float topAltitude_0 = scaleHeight_2 * 8.0f;
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
    float _S493 = fx_1 - float(x0_1);
    float _S494 = fy_1 - float(y0_1);
    int _S495 = y0_1 * int(256);
    int _S496 = (_S495 + x0_1) * int(3);
    int _S497 = (_S495 + x1_1) * int(3);
    int _S498 = y1_1 * int(256);
    int _S499 = (_S498 + x0_1) * int(3);
    int _S500 = (_S498 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_56 = int(0);
    for(;;)
    {
        if(c_56 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S501 = __ldg((&(_S491)[_S496 + c_56]));
        float _S502 = 1.0f - _S493;
        float _S503 = _S501 * _S502;
        float _S504 = __ldg((&(_S491)[_S497 + c_56]));
        float a_6 = _S503 + _S504 * _S493;
        float _S505 = __ldg((&(_S491)[_S499 + c_56]));
        float _S506 = _S505 * _S502;
        float _S507 = __ldg((&(_S491)[_S500 + c_56]));
        float r_12 = a_6 * (1.0f - _S494) + (_S506 + _S507 * _S493) * _S494;
        if(c_56 == int(0))
        {
            *&((&out_0)->x) = r_12;
        }
        else
        {
            if(c_56 == int(1))
            {
                *&((&out_0)->y) = r_12;
            }
            else
            {
                *&((&out_0)->z) = r_12;
            }
        }
        c_56 = c_56 + int(1);
    }
    return out_0;
}

static __device__ float3  sunTransmittanceAt_0(SkyInput_0 * p_26, float3  worldPos_0)
{
    float3  _S508 = sunDirection_0(p_26);
    float _S509 = p_26->planetRadius_0;
    float planetRadius_4;
    if((p_26->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S509;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S510 = worldPos_0.y;
    float altitude_2;
    if(_S510 > 0.0f)
    {
        altitude_2 = _S510;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    float3  _S511 = sampleTransmittanceLut_0(p_26, altitude_2, lutMuFor_0(make_float3 (worldPos_0.x, planetRadius_4 + _S510, worldPos_0.z), _S508));
    return _S511;
}

static __device__ float3  sunIrradianceAt_0(Scene_0 * s_17, float3  p_27)
{
    if(((&s_17->environment_0)->envMode_0) == int(1))
    {
        float _S512 = sunIrradianceTop_0(&(&s_17->environment_0)->sky_0);
        float3  _S513 = sunTransmittanceAt_0(&(&s_17->environment_0)->sky_0, p_27);
        return make_float3 (_S512) * _S513;
    }
    return s_17->sunIrradiance_0;
}

static __device__ float3  cameraSegmentSun_0(Scene_0 * s_18, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_6, StructuredBuffer<float2 > drift_2, Rng_0 * rng_5, Rng_0 * rng2_0, float3  ro_2, float3  rd_2, int * steps_5, int * hit_0, float3  * hitAt_0, int * hitLayer_0, float * tResume_0)
{
    bool rouletted_0;
    float ph0_0;
    float kept_0;
    float keptT_0;
    float3  keptAt_0;
    int keptLayer_0;
    Rng_0 _S514 = *rng2_0;
    *hit_0 = int(0);
    float3  _S515 = make_float3 (0.0f, 0.0f, 0.0f);
    *hitAt_0 = _S515;
    *hitLayer_0 = int(0);
    *tResume_0 = 0.0f;
    float _S516 = (F32_max((s_18->neeTentativeScale_0), (1.0f)));
    float tA_0;
    float endA_0;
    bool _S517 = slabRange_0(&s_18->medium_0, ro_2, rd_2, &tA_0, &endA_0);
    float _S518 = (F32_max((tA_0), (0.0f)));
    tA_0 = _S518;
    Dda_0 _S519 = ddaInit_0(&s_18->grid_0, ro_2, rd_2, _S518);
    Dda_0 ddaA_0 = _S519;
    float _S520 = gridBound_0(&s_18->medium_0, &s_18->grid_0, bounds_6, drift_2, (&ddaA_0)->cell_0, (&s_18->medium_0)->majorant_0);
    float rateA_0 = _S520 * _S516;
    int budgetA_0 = int(4096);
    float keepA_0 = 0.0f;
    float rouletteA_0 = 0.0f;
    float coinA_0 = 0.0f;
    bool haveA_0;
    if(_S517)
    {
        bool _S521 = segmentStep_0(&s_18->medium_0, &s_18->grid_0, bounds_6, drift_2, _S516, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_5, &keepA_0, &rouletteA_0, &coinA_0, &budgetA_0, steps_5);
        haveA_0 = _S521;
    }
    else
    {
        haveA_0 = _S517;
    }
    float tB_0 = 0.0f;
    float endB_0 = 0.0f;
    bool haveB_0;
    if((s_18->layer2On_0) != int(0))
    {
        bool _S522 = slabRange_0(&s_18->medium2_0, ro_2, rd_2, &tB_0, &endB_0);
        haveB_0 = _S522;
    }
    else
    {
        haveB_0 = false;
    }
    float _S523 = (F32_max((tB_0), (0.0f)));
    tB_0 = _S523;
    MajorantGrid_0 _S524 = gridFor_0(&s_18->medium2_0, &s_18->grid2_0, ro_2);
    MajorantGrid_0 _S525 = _S524;
    Dda_0 _S526 = ddaInit_0(&_S525, ro_2, rd_2, _S523);
    Dda_0 ddaB_0 = _S526;
    MajorantGrid_0 _S527 = _S524;
    float _S528 = gridBound_0(&s_18->medium2_0, &_S527, bounds_6, drift_2, (&ddaB_0)->cell_0, (&s_18->medium2_0)->majorant_0);
    float rateB_0 = _S528 * _S516;
    int budgetB_0 = int(4096);
    float keepB_0 = 0.0f;
    float rouletteB_0 = 0.0f;
    float coinB_0 = 0.0f;
    if(haveB_0)
    {
        MajorantGrid_0 _S529 = _S524;
        bool _S530 = segmentStep_0(&s_18->medium2_0, &_S529, bounds_6, drift_2, _S516, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S514, &keepB_0, &rouletteB_0, &coinB_0, &budgetB_0, steps_5);
        haveB_0 = _S530;
    }
    float kept_1 = 0.0f;
    float3  keptAt_1 = _S515;
    int keptLayer_1 = int(0);
    float keptT_1 = 0.0f;
    float tr_7 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        if(haveA_0)
        {
            rouletted_0 = true;
        }
        else
        {
            rouletted_0 = haveB_0;
        }
        if(rouletted_0)
        {
        }
        else
        {
            rouletted_0 = false;
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            keptLayer_0 = keptLayer_1;
            keptT_0 = keptT_1;
            break;
        }
        bool takeA_0;
        if(haveA_0)
        {
            if(!haveB_0)
            {
                takeA_0 = true;
            }
            else
            {
                takeA_0 = tA_0 <= tB_0;
            }
        }
        else
        {
            takeA_0 = false;
        }
        if(takeA_0)
        {
            ph0_0 = tA_0;
        }
        else
        {
            ph0_0 = tB_0;
        }
        float rate_1;
        if(takeA_0)
        {
            rate_1 = rateA_0;
        }
        else
        {
            rate_1 = rateB_0;
        }
        float uKeep_1;
        if(takeA_0)
        {
            uKeep_1 = keepA_0;
        }
        else
        {
            uKeep_1 = keepB_0;
        }
        float uLive_1;
        if(takeA_0)
        {
            uLive_1 = rouletteA_0;
        }
        else
        {
            uLive_1 = rouletteB_0;
        }
        float uHit_1;
        if(takeA_0)
        {
            uHit_1 = coinA_0;
        }
        else
        {
            uHit_1 = coinB_0;
        }
        float3  p_28 = ro_2 + rd_2 * make_float3 (ph0_0);
        *tResume_0 = ph0_0;
        float sigma_0;
        if(takeA_0)
        {
            float _S531 = densityAt_0(&s_18->medium_0, drift_2, p_28);
            sigma_0 = _S531;
        }
        else
        {
            float _S532 = densityAt_0(&s_18->medium2_0, drift_2, p_28);
            sigma_0 = _S532;
        }
        if(sigma_0 > 0.0f)
        {
            float w_6 = sigma_0 / rate_1;
            bool _S533;
            if((*hit_0) == int(0))
            {
                _S533 = uHit_1 < w_6;
            }
            else
            {
                _S533 = false;
            }
            if(_S533)
            {
                *hit_0 = int(1);
                *hitAt_0 = p_28;
                if(takeA_0)
                {
                    keptLayer_0 = int(0);
                }
                else
                {
                    keptLayer_0 = int(1);
                }
                *hitLayer_0 = keptLayer_0;
            }
            float b_7 = tr_7 * w_6;
            float total_1;
            if(b_7 > 0.0f)
            {
                float total_2 = total_0 + b_7;
                if((uKeep_1 * total_2) < b_7)
                {
                    if(takeA_0)
                    {
                        keptLayer_0 = int(0);
                    }
                    else
                    {
                        keptLayer_0 = int(1);
                    }
                    kept_0 = b_7;
                    keptAt_0 = p_28;
                    keptT_0 = ph0_0;
                }
                else
                {
                    kept_0 = kept_1;
                    keptAt_0 = keptAt_1;
                    keptLayer_0 = keptLayer_1;
                    keptT_0 = keptT_1;
                }
                total_1 = total_2;
            }
            else
            {
                kept_0 = kept_1;
                keptAt_0 = keptAt_1;
                keptLayer_0 = keptLayer_1;
                keptT_0 = keptT_1;
                total_1 = total_0;
            }
            float tr_8 = tr_7 * (F32_max((0.0f), (1.0f - w_6)));
            float tr_9;
            if(tr_8 < 0.00999999977648258f)
            {
                if(uLive_1 > 0.5f)
                {
                    rouletted_0 = true;
                    total_0 = total_1;
                    break;
                }
                tr_9 = tr_8 * 2.0f;
            }
            else
            {
                tr_9 = tr_8;
            }
            tr_7 = tr_9;
            total_0 = total_1;
        }
        else
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            keptLayer_0 = keptLayer_1;
            keptT_0 = keptT_1;
        }
        if(takeA_0)
        {
            bool _S534 = segmentStep_0(&s_18->medium_0, &s_18->grid_0, bounds_6, drift_2, _S516, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_5, &keepA_0, &rouletteA_0, &coinA_0, &budgetA_0, steps_5);
            haveA_0 = _S534;
        }
        else
        {
            MajorantGrid_0 _S535 = _S524;
            bool _S536 = segmentStep_0(&s_18->medium2_0, &_S535, bounds_6, drift_2, _S516, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S514, &keepB_0, &rouletteB_0, &coinB_0, &budgetB_0, steps_5);
            haveB_0 = _S536;
        }
        kept_1 = kept_0;
        keptAt_1 = keptAt_0;
        keptLayer_1 = keptLayer_0;
        keptT_1 = keptT_0;
    }
    if((*hit_0) == int(0))
    {
        if(rouletted_0)
        {
            haveA_0 = true;
        }
        else
        {
            haveA_0 = budgetA_0 <= int(0);
        }
        if(haveA_0)
        {
            haveA_0 = true;
        }
        else
        {
            haveA_0 = budgetB_0 <= int(0);
        }
    }
    else
    {
        haveA_0 = false;
    }
    if(haveA_0)
    {
        *hit_0 = int(2);
    }
    if(!(total_0 > 0.0f))
    {
        haveA_0 = true;
    }
    else
    {
        haveA_0 = !(kept_0 > 0.0f);
    }
    if(haveA_0)
    {
        return _S515;
    }
    float3  _S537 = s_18->sunDir_0;
    float _S538 = sceneTransmittance_0(s_18, bounds_6, drift_2, rng_5, keptAt_0 + s_18->sunDir_0 * make_float3 (s_18->shadowOffset_0), s_18->sunDir_0, steps_5);
    float3  _S539 = s_18->albedo_0;
    float3  matterAlbedo_0;
    if(keptLayer_0 == int(0))
    {
        float _S540 = phaseCamera_0(ph_0, dot_0(rd_2, _S537));
        matterAlbedo_0 = _S539;
        ph0_0 = _S540;
    }
    else
    {
        float _S541 = phaseCamera_0(&s_18->phase2_0, dot_0(rd_2, _S537));
        matterAlbedo_0 = s_18->albedo2_0;
        ph0_0 = _S541;
    }
    float3  _S542 = make_float3 (1.0f, 1.0f, 1.0f);
    if(((&s_18->environment_0)->envMode_0) == int(1))
    {
        haveA_0 = (s_18->aerialMode_0) != int(0);
    }
    else
    {
        haveA_0 = false;
    }
    float3  air_0;
    if(haveA_0)
    {
        float3  _S543 = airTransmittance_0(&(&s_18->environment_0)->sky_0, ro_2.y, rd_2, keptT_0);
        air_0 = _S543;
    }
    else
    {
        air_0 = _S542;
    }
    float3  _S544 = make_float3 (total_0) * matterAlbedo_0 * make_float3 (ph0_0) * make_float3 (_S538);
    float3  _S545 = sunIrradianceAt_0(s_18, keptAt_0);
    return _S544 * _S545 * air_0;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_15, MajorantGrid_0 * g_19, StructuredBuffer<float> bounds_7, StructuredBuffer<float2 > disp_10, Rng_0 * rng_6, float3  ro_3, float3  rd_3, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_6)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_4;
    float t1_4;
    bool _S546 = slabRange_0(m_15, ro_3, rd_3, &t0_4, &t1_4);
    if(!_S546)
    {
        return false;
    }
    float _S547 = (F32_min((t1_4), (tLimit_0)));
    t1_4 = _S547;
    if(!(_S547 > t0_4))
    {
        return false;
    }
    float _S548 = (F32_max((t0_4), (0.0f)));
    Dda_0 _S549 = ddaInit_0(g_19, ro_3, rd_3, _S548);
    Dda_0 dda_3 = _S549;
    float _S550 = m_15->majorant_0;
    float _S551 = gridBound_0(m_15, g_19, bounds_7, disp_10, (&dda_3)->cell_0, m_15->majorant_0);
    float localMaj_2 = _S551;
    int i_25 = int(0);
    float t_15 = _S548;
    for(;;)
    {
        if(i_25 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_6 = *steps_6 + int(1);
        Dda_0 _S552 = dda_3;
        float _S553 = ddaExit_0(&_S552);
        float _S554 = (F32_min((_S553), (t1_4)));
        if(localMaj_2 <= 0.0f)
        {
            if(_S554 >= t1_4)
            {
                return false;
            }
            ddaAdvance_0(&dda_3);
            float _S555 = gridBound_0(m_15, g_19, bounds_7, disp_10, (&dda_3)->cell_0, _S550);
            localMaj_2 = _S555;
            t_15 = _S554;
            i_25 = i_25 + int(1);
            continue;
        }
        float _S556 = randFloat_0(rng_6);
        float t_16 = t_15 - (F32_log(((F32_max((1.0f - _S556), (1.00000001168609742e-07f)))))) / localMaj_2;
        if(t_16 >= _S554)
        {
            if(_S554 >= t1_4)
            {
                return false;
            }
            ddaAdvance_0(&dda_3);
            float _S557 = gridBound_0(m_15, g_19, bounds_7, disp_10, (&dda_3)->cell_0, _S550);
            localMaj_2 = _S557;
            t_15 = _S554;
            i_25 = i_25 + int(1);
            continue;
        }
        float3  p_29 = ro_3 + rd_3 * make_float3 (t_16);
        float _S558 = randFloat_0(rng_6);
        float _S559 = densityAt_0(m_15, disp_10, p_29);
        if(_S558 < (_S559 / localMaj_2))
        {
            *scatterPoint_0 = p_29;
            *distance_0 = t_16;
            return true;
        }
        t_15 = t_16;
        i_25 = i_25 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_16, MajorantGrid_0 * g_20, StructuredBuffer<float> bounds_8, StructuredBuffer<float2 > disp_11, Rng_0 * rng_7, float3  ro_4, float3  rd_4, float3  * scatterPoint_1, float * distance_1, int * steps_7)
{
    bool _S560 = sampleFreeFlightUpTo_0(m_16, g_20, bounds_8, disp_11, rng_7, ro_4, rd_4, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_7);
    return _S560;
}

static __device__ bool sceneFreeFlight_0(Scene_0 * s_19, StructuredBuffer<float> bounds_9, StructuredBuffer<float2 > drift_3, Rng_0 * rng_8, float3  ro_5, float3  rd_5, float3  * scatterAt_0, int * layer_0, int * steps_8)
{
    *layer_0 = int(0);
    float dist_2;
    if((s_19->layer2On_0) == int(0))
    {
        bool _S561 = sampleFreeFlight_0(&s_19->medium_0, &s_19->grid_0, bounds_9, drift_3, rng_8, ro_5, rd_5, scatterAt_0, &dist_2, steps_8);
        return _S561;
    }
    float a0_1;
    float a1_1;
    bool _S562 = slabRange_0(&s_19->medium_0, ro_5, rd_5, &a0_1, &a1_1);
    float b0_1;
    float b1_0;
    bool _S563 = slabRange_0(&s_19->medium2_0, ro_5, rd_5, &b0_1, &b1_0);
    bool secondFirst_0;
    if(_S563)
    {
        if(!_S562)
        {
            secondFirst_0 = true;
        }
        else
        {
            secondFirst_0 = (F32_max((b0_1), (0.0f))) < (F32_max((a0_1), (0.0f)));
        }
    }
    else
    {
        secondFirst_0 = false;
    }
    float3  pNear_0;
    float3  pFar_0;
    float dNear_1;
    float dFar_0;
    MajorantGrid_0 _S564 = gridFor_0(&s_19->medium2_0, &s_19->grid2_0, ro_5);
    float _S565;
    if(secondFirst_0)
    {
        MajorantGrid_0 _S566 = _S564;
        bool _S567 = sampleFreeFlight_0(&s_19->medium2_0, &_S566, bounds_9, drift_3, rng_8, ro_5, rd_5, &pNear_0, &dNear_1, steps_8);
        if(_S567)
        {
            _S565 = dNear_1;
        }
        else
        {
            _S565 = 1.00000001504746622e+30f;
        }
        bool _S568 = sampleFreeFlightUpTo_0(&s_19->medium_0, &s_19->grid_0, bounds_9, drift_3, rng_8, ro_5, rd_5, _S565, &pFar_0, &dFar_0, steps_8);
        if(_S568)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(0);
            return true;
        }
        if(_S567)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(1);
            return true;
        }
    }
    else
    {
        bool _S569 = sampleFreeFlight_0(&s_19->medium_0, &s_19->grid_0, bounds_9, drift_3, rng_8, ro_5, rd_5, &pNear_0, &dNear_1, steps_8);
        if(_S569)
        {
            _S565 = dNear_1;
        }
        else
        {
            _S565 = 1.00000001504746622e+30f;
        }
        MajorantGrid_0 _S570 = _S564;
        bool _S571 = sampleFreeFlightUpTo_0(&s_19->medium2_0, &_S570, bounds_9, drift_3, rng_8, ro_5, rd_5, _S565, &pFar_0, &dFar_0, steps_8);
        if(_S571)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(1);
            return true;
        }
        if(_S569)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(0);
            return true;
        }
    }
    *scatterAt_0 = make_float3 (0.0f, 0.0f, 0.0f);
    return false;
}

static __device__ float groundShadow_0(LayerShadowMap_0 * mapA_0, LayerShadowMap_0 * mapB_0, float3  origin_1, float3  dir_5)
{
    float _S572 = dir_5.y;
    bool _S573;
    if(!(_S572 < 0.0f))
    {
        _S573 = true;
    }
    else
    {
        _S573 = !((origin_1.y) > 0.0f);
    }
    if(_S573)
    {
        return 1.0f;
    }
    float3  ground_0 = origin_1 + dir_5 * make_float3 (origin_1.y / - _S572);
    *&((&ground_0)->y) = 0.0f;
    float _S574 = layerMapTransmittance_0(mapA_0, ground_0);
    float _S575 = layerMapTransmittance_0(mapB_0, ground_0);
    return _S574 * _S575;
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_30, float originAltitude_1, float3  rayDir_1, bool includeSunDisc_0, float groundLit_0)
{
    float hc_1;
    float3  _S576 = sunDirection_0(p_30);
    float _S577 = p_30->planetRadius_0;
    float planetRadius_5;
    if((p_30->planetRadius_0) > 1000.0f)
    {
        planetRadius_5 = _S577;
    }
    else
    {
        planetRadius_5 = 1000.0f;
    }
    float _S578 = p_30->scaleHeight_0;
    float scaleHeight_3;
    if((p_30->scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = _S578;
    }
    else
    {
        scaleHeight_3 = 1.0f;
    }
    float atmosphereHeight_1 = scaleHeight_3 * 8.0f;
    float observerAltitude_1;
    if(originAltitude_1 > 0.0f)
    {
        observerAltitude_1 = originAltitude_1;
    }
    else
    {
        observerAltitude_1 = 0.0f;
    }
    float _S579 = planetRadius_5 + observerAltitude_1;
    float _S580 = rayDir_1.y;
    float b_8 = _S579 * _S580;
    float cGround_1 = shellC_0(observerAltitude_1, planetRadius_5, 0.0f);
    float tTop_1 = shellExit_0(b_8, shellC_0(observerAltitude_1, planetRadius_5, atmosphereHeight_1));
    if(tTop_1 <= 0.0f)
    {
        return make_float3 (0.0f, 0.0f, 0.0f);
    }
    float tGround_1 = shellEnter_0(b_8, cGround_1);
    bool hitsGround_0 = tGround_1 > 0.0f;
    if(hitsGround_0)
    {
        observerAltitude_1 = tGround_1;
    }
    else
    {
        observerAltitude_1 = tTop_1;
    }
    float3  betaR_1 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_30->turbidity_0);
    float betaMExt_1 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_1, _S576), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_21 = clampf_0(p_30->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S581 = g_21 * g_21;
    float hgDenom_0 = 1.0f + _S581 - 2.0f * g_21 * cosTheta_0;
    float _S582 = 1.0f - _S581;
    float _S583 = 12.56637096405029297f * hgDenom_0;
    float tPrev_1;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_1 = hgDenom_0;
    }
    else
    {
        tPrev_1 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S582 / (_S583 * (F32_sqrt((tPrev_1))));
    float3  _S584 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_1 = 0.0f;
    float3  sumR_0 = _S584;
    float3  sumM_0 = _S584;
    int i_26 = int(0);
    float depthR_1 = 0.0f;
    float depthM_2 = 0.0f;
    for(;;)
    {
        if(i_26 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S585 = i_26 + int(1);
        float tNext_1 = observerAltitude_1 * float(_S585 * _S585) * 0.00173611112404615f;
        float dt_1 = tNext_1 - tPrev_1;
        float tMid_1 = (tPrev_1 + tNext_1) * 0.5f;
        if(dt_1 <= 0.0f)
        {
            tPrev_1 = tNext_1;
            i_26 = _S585;
            continue;
        }
        float h_6 = altitudeFromQ_0(cGround_1 + 2.0f * tMid_1 * b_8 + tMid_1 * tMid_1, planetRadius_5);
        if(h_6 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_6;
        }
        float _S586 = - hc_1;
        float dR_0 = (F32_exp((_S586 / scaleHeight_3))) * dt_1;
        float dM_0 = (F32_exp((_S586 / 1200.0f))) * dt_1;
        float midR_0 = depthR_1 + 0.5f * dR_0;
        float midM_0 = depthM_2 + 0.5f * dM_0;
        float depthR_2 = depthR_1 + dR_0;
        float depthM_3 = depthM_2 + dM_0;
        float3  _S587 = sampleTransmittanceLut_0(p_30, hc_1, lutMuFor_0(make_float3 (rayDir_1.x * tMid_1, _S579 + _S580 * tMid_1, rayDir_1.z * tMid_1), _S576));
        float _S588 = betaMExt_1 * midM_0;
        float3  transmittance_1 = make_float3 ((F32_exp((- (betaR_1.x * midR_0 + _S588)))), (F32_exp((- (betaR_1.y * midR_0 + _S588)))), (F32_exp((- (betaR_1.z * midR_0 + _S588))))) * _S587;
        float3  _S589 = sumM_0 + transmittance_1 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_1 * make_float3 (dR_0);
        sumM_0 = _S589;
        depthR_1 = depthR_2;
        depthM_2 = depthM_3;
        tPrev_1 = tNext_1;
        i_26 = _S585;
    }
    float _S590 = sunIrradianceTop_0(p_30);
    float3  radiance_0 = (sumR_0 * betaR_1 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S590);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_1.x * tGround_1, _S579 + _S580 * tGround_1, rayDir_1.z * tGround_1);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S576), 0.0f, 1.0f);
        float3  _S591 = sampleTransmittanceLut_0(p_30, 0.0f, lutMuFor_0(groundPoint_0, _S576));
        float _S592 = betaMExt_1 * depthM_2;
        float3  viewT_0 = make_float3 ((F32_exp((- (betaR_1.x * depthR_1 + _S592)))), (F32_exp((- (betaR_1.y * depthR_1 + _S592)))), (F32_exp((- (betaR_1.z * depthR_1 + _S592)))));
        radiance_1 = radiance_0 + viewT_0 * _S591 * make_float3 (p_30->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S590 * groundLit_0) + viewT_0 * p_30->groundSkyLight_0;
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S593;
    if(!hitsGround_0)
    {
        _S593 = includeSunDisc_0;
    }
    else
    {
        _S593 = false;
    }
    if(_S593)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_30->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S594 = betaMExt_1 * depthM_2;
            float3  viewT_1 = make_float3 ((F32_exp((- (betaR_1.x * depthR_1 + _S594)))), (F32_exp((- (betaR_1.y * depthR_1 + _S594)))), (F32_exp((- (betaR_1.z * depthR_1 + _S594)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_1 = solidAngle_0;
            }
            else
            {
                hc_1 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_1 * make_float3 (_S590 / hc_1);
        }
    }
    return radiance_1;
}

static __device__ float3  environmentRadiance_0(Environment_0 * e_0, float3  origin_2, float3  dir_6, bool includeSunDisc_1, float groundLit_1)
{
    if((e_0->envMode_0) == int(1))
    {
        float3  _S595 = skyRadiance_0(&e_0->sky_0, origin_2.y, dir_6, includeSunDisc_1, groundLit_1);
        return _S595;
    }
    return e_0->uniformRadiance_0;
}

static __device__ float3  pathEnvironment_0(Scene_0 * s_20, float3  ro_6, float3  rd_6, bool first_0)
{
    float groundLit_2;
    if((s_20->airMapOn_0) != int(0))
    {
        float _S596 = groundShadow_0(&s_20->airMapIce_0, &s_20->airMapCu_0, ro_6, rd_6);
        groundLit_2 = _S596;
    }
    else
    {
        groundLit_2 = 1.0f;
    }
    float3  _S597 = environmentRadiance_0(&s_20->environment_0, ro_6, rd_6, first_0, groundLit_2);
    float3  env_0;
    if(!first_0)
    {
        env_0 = _S597 + s_20->ltAmbient_0;
    }
    else
    {
        env_0 = _S597;
    }
    return env_0;
}

static __device__ bool layerMapRange_0(LayerShadowMap_0 * m_17, float3  ro_7, float3  rd_7, float * t0_5, float * t1_5)
{
    *t0_5 = 0.0f;
    *t1_5 = 1.00000001504746622e+30f;
    int _S598 = m_17->smDimU_0;
    int _S599 = m_17->smDimV_0;
    uint want_1 = uint(m_17->smDimU_0 * m_17->smDimV_0 * m_17->smSlices_0);
    bool _S600;
    if(want_1 == 0U)
    {
        _S600 = true;
    }
    else
    {
        _S600 = uint(StructuredBuffer_getCount_0(m_17->smTexels_0)) < want_1;
    }
    if(_S600)
    {
        return false;
    }
    float _S601 = rd_7.y;
    if((F32_abs((_S601))) < 9.99999971718068537e-10f)
    {
        if((ro_7.y) >= (m_17->smTop_0))
        {
            return false;
        }
    }
    else
    {
        float tt_0 = (m_17->smTop_0 - ro_7.y) / _S601;
        if(_S601 > 0.0f)
        {
            *t1_5 = (F32_min((*t1_5), (tt_0)));
        }
        else
        {
            *t0_5 = (F32_max((*t0_5), (tt_0)));
        }
    }
    float3  _S602 = m_17->smSun_0;
    float2  _S603 = float2 {_S602.x, _S602.z};
    float _S604 = m_17->smSun_0.y;
    float2  q0_3 = float2 {ro_7.x, ro_7.z} + _S603 * make_float2 ((m_17->smBottom_0 - ro_7.y) / _S604) - m_17->smCentre_0;
    float2  dq_0 = float2 {rd_7.x, rd_7.z} - _S603 * make_float2 (_S601 / _S604);
    float2  _S605 = airMapAxisV_0(m_17);
    float _S606 = m_17->smLo_0.x;
    float _S607 = m_17->smLo_0.y;
    float vHi_0 = _S607 + float(_S599) * m_17->smTexel_0.y;
    bool _S608 = clipAxis_0(dot_1(q0_3, m_17->smAxisU_0), dot_1(dq_0, m_17->smAxisU_0), _S606, _S606 + float(_S598) * m_17->smTexel_0.x, t0_5, t1_5);
    if(!_S608)
    {
        return false;
    }
    bool _S609 = clipAxis_0(dot_1(q0_3, _S605), dot_1(dq_0, _S605), _S607, vHi_0, t0_5, t1_5);
    if(!_S609)
    {
        return false;
    }
    return (*t1_5) > (*t0_5);
}

static __device__ float3  airShadowLoss_0(SkyInput_0 * p_31, LayerShadowMap_0 * mapA_1, LayerShadowMap_0 * mapB_1, float3  ro_8, float3  rd_8, float dist_3, float jitter_1)
{
    float3  none_0 = make_float3 (0.0f, 0.0f, 0.0f);
    float r0_0;
    float r1_0;
    bool _S610 = layerMapRange_0(mapA_1, ro_8, rd_8, &r0_0, &r1_0);
    float tA_1;
    float tB_1;
    if(_S610)
    {
        float _S611 = (F32_max((-1.00000001504746622e+30f), (r1_0)));
        tA_1 = (F32_min((1.00000001504746622e+30f), (r0_0)));
        tB_1 = _S611;
    }
    else
    {
        tA_1 = 1.00000001504746622e+30f;
        tB_1 = -1.00000001504746622e+30f;
    }
    bool _S612 = layerMapRange_0(mapB_1, ro_8, rd_8, &r0_0, &r1_0);
    if(_S612)
    {
        float _S613 = (F32_min((tA_1), (r0_0)));
        tB_1 = (F32_max((tB_1), (r1_0)));
        tA_1 = _S613;
    }
    if(!(tB_1 > tA_1))
    {
        return none_0;
    }
    float3  _S614 = sunDirection_0(p_31);
    float _S615 = p_31->planetRadius_0;
    float planetRadius_6;
    if((p_31->planetRadius_0) > 1000.0f)
    {
        planetRadius_6 = _S615;
    }
    else
    {
        planetRadius_6 = 1000.0f;
    }
    float _S616 = p_31->scaleHeight_0;
    float scaleHeight_4;
    if((p_31->scaleHeight_0) > 1.0f)
    {
        scaleHeight_4 = _S616;
    }
    else
    {
        scaleHeight_4 = 1.0f;
    }
    float atmosphereHeight_2 = scaleHeight_4 * 8.0f;
    float _S617 = ro_8.y;
    float observerAltitude_2;
    if(_S617 > 0.0f)
    {
        observerAltitude_2 = _S617;
    }
    else
    {
        observerAltitude_2 = 0.0f;
    }
    float _S618 = planetRadius_6 + observerAltitude_2;
    float _S619 = rd_8.y;
    float b_9 = _S618 * _S619;
    float cGround_2 = shellC_0(observerAltitude_2, planetRadius_6, 0.0f);
    float tTop_2 = shellExit_0(b_9, shellC_0(observerAltitude_2, planetRadius_6, atmosphereHeight_2));
    bool _S620;
    if(tTop_2 <= 0.0f)
    {
        _S620 = true;
    }
    else
    {
        _S620 = !(dist_3 > 0.0f);
    }
    if(_S620)
    {
        return none_0;
    }
    float tGround_2 = shellEnter_0(b_9, cGround_2);
    float tMax_3;
    if(tGround_2 > 0.0f)
    {
        tMax_3 = tGround_2;
    }
    else
    {
        tMax_3 = tTop_2;
    }
    if(dist_3 < tMax_3)
    {
        tMax_3 = dist_3;
    }
    float _S621 = (F32_max((tA_1), (0.0f)));
    float _S622 = (F32_min((tB_1), (tMax_3)));
    if(!(_S622 > _S621))
    {
        return none_0;
    }
    float3  betaR_2 = rayleighCoefficients_0();
    float betaM_1 = mieCoefficient_0(p_31->turbidity_0);
    float _S623 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rd_8, _S614), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_22 = clampf_0(p_31->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S624 = g_22 * g_22;
    float hgDenom_1 = 1.0f + _S624 - 2.0f * g_22 * cosTheta_1;
    float _S625 = 1.0f - _S624;
    float _S626 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        tA_1 = hgDenom_1;
    }
    else
    {
        tA_1 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S625 / (_S626 * (F32_sqrt((tA_1))));
    float depthR_3;
    float depthM_4;
    float hc_2;
    int i_27;
    if(_S621 > 0.0f)
    {
        float _S627 = _S621 / 8.0f;
        i_27 = int(0);
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
        for(;;)
        {
            if(i_27 < int(8))
            {
            }
            else
            {
                break;
            }
            float tm_0 = (float(i_27) + 0.5f) * _S627;
            float h_7 = altitudeFromQ_0(cGround_2 + 2.0f * tm_0 * b_9 + tm_0 * tm_0, planetRadius_6);
            if(h_7 < 0.0f)
            {
                hc_2 = 0.0f;
            }
            else
            {
                hc_2 = h_7;
            }
            float _S628 = - hc_2;
            float depthR_4 = depthR_3 + (F32_exp((_S628 / scaleHeight_4))) * _S627;
            float depthM_5 = depthM_4 + (F32_exp((_S628 / 1200.0f))) * _S627;
            i_27 = i_27 + int(1);
            depthR_3 = depthR_4;
            depthM_4 = depthM_5;
        }
    }
    else
    {
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
    }
    float _S629 = clampf_0(jitter_1, 0.0f, 1.0f);
    float _S630 = _S622 - _S621;
    float3  lossR_0 = none_0;
    float3  lossM_0 = none_0;
    i_27 = int(0);
    for(;;)
    {
        if(i_27 < int(48))
        {
        }
        else
        {
            break;
        }
        float s0_0 = _S621 + _S630 * float(i_27 * i_27) * 0.00043402778101154f;
        int _S631 = i_27 + int(1);
        float dt_2 = _S621 + _S630 * float(_S631 * _S631) * 0.00043402778101154f - s0_0;
        float ts_0 = s0_0 + _S629 * dt_2;
        float h_8 = altitudeFromQ_0(cGround_2 + 2.0f * ts_0 * b_9 + ts_0 * ts_0, planetRadius_6);
        if(h_8 < 0.0f)
        {
            hc_2 = 0.0f;
        }
        else
        {
            hc_2 = h_8;
        }
        float _S632 = - hc_2;
        float rhoR_0 = (F32_exp((_S632 / scaleHeight_4)));
        float rhoM_0 = (F32_exp((_S632 / 1200.0f)));
        float _S633 = ts_0 - s0_0;
        float atR_0 = depthR_3 + rhoR_0 * _S633;
        float atM_0 = depthM_4 + rhoM_0 * _S633;
        float depthR_5 = depthR_3 + rhoR_0 * dt_2;
        float depthM_6 = depthM_4 + rhoM_0 * dt_2;
        float3  pw_0 = ro_8 + rd_8 * make_float3 (ts_0);
        float _S634 = layerMapTransmittance_0(mapA_1, pw_0);
        float _S635 = layerMapTransmittance_0(mapB_1, pw_0);
        float v_9 = _S634 * _S635;
        if(v_9 >= 1.0f)
        {
            i_27 = _S631;
            depthR_3 = depthR_5;
            depthM_4 = depthM_6;
            continue;
        }
        float3  _S636 = sampleTransmittanceLut_0(p_31, hc_2, lutMuFor_0(make_float3 (rd_8.x * ts_0, _S618 + _S619 * ts_0, rd_8.z * ts_0), _S614));
        float _S637 = _S623 * atM_0;
        float3  w_7 = make_float3 ((F32_exp((- (betaR_2.x * atR_0 + _S637)))), (F32_exp((- (betaR_2.y * atR_0 + _S637)))), (F32_exp((- (betaR_2.z * atR_0 + _S637))))) * _S636 * make_float3 ((1.0f - v_9) * dt_2);
        float3  _S638 = lossM_0 + w_7 * make_float3 (rhoM_0);
        lossR_0 = lossR_0 + w_7 * make_float3 (rhoR_0);
        lossM_0 = _S638;
        i_27 = _S631;
        depthR_3 = depthR_5;
        depthM_4 = depthM_6;
    }
    float3  _S639 = lossR_0 * betaR_2 * make_float3 (phaseR_1) + lossM_0 * make_float3 (betaM_1 * phaseM_1);
    float _S640 = sunIrradianceTop_0(p_31);
    return _S639 * make_float3 (_S640);
}

struct AirSegment_0
{
    float3  airIn_0;
    float3  airT_0;
    float shadowAt_0;
};

static __device__ AirSegment_0 airSegment_0(SkyInput_0 * p_32, float originAltitude_2, float3  rayDir_2, float dist_4, float u1_0, float u2_0)
{
    AirSegment_0 seg_0;
    float3  _S641 = make_float3 (0.0f, 0.0f, 0.0f);
    (&seg_0)->airIn_0 = _S641;
    (&seg_0)->airT_0 = make_float3 (1.0f, 1.0f, 1.0f);
    (&seg_0)->shadowAt_0 = -1.0f;
    float3  _S642 = sunDirection_0(p_32);
    float _S643 = p_32->planetRadius_0;
    float planetRadius_7;
    if((p_32->planetRadius_0) > 1000.0f)
    {
        planetRadius_7 = _S643;
    }
    else
    {
        planetRadius_7 = 1000.0f;
    }
    float _S644 = p_32->scaleHeight_0;
    float scaleHeight_5;
    if((p_32->scaleHeight_0) > 1.0f)
    {
        scaleHeight_5 = _S644;
    }
    else
    {
        scaleHeight_5 = 1.0f;
    }
    float atmosphereHeight_3 = scaleHeight_5 * 8.0f;
    float observerAltitude_3;
    if(originAltitude_2 > 0.0f)
    {
        observerAltitude_3 = originAltitude_2;
    }
    else
    {
        observerAltitude_3 = 0.0f;
    }
    float _S645 = planetRadius_7 + observerAltitude_3;
    float _S646 = rayDir_2.y;
    float b_10 = _S645 * _S646;
    float cGround_3 = shellC_0(observerAltitude_3, planetRadius_7, 0.0f);
    float tTop_3 = shellExit_0(b_10, shellC_0(observerAltitude_3, planetRadius_7, atmosphereHeight_3));
    bool _S647;
    if(tTop_3 <= 0.0f)
    {
        _S647 = true;
    }
    else
    {
        _S647 = !(dist_4 > 0.0f);
    }
    if(_S647)
    {
        return seg_0;
    }
    float tGround_3 = shellEnter_0(b_10, cGround_3);
    float tMax_4;
    if(tGround_3 > 0.0f)
    {
        tMax_4 = tGround_3;
    }
    else
    {
        tMax_4 = tTop_3;
    }
    if(dist_4 < tMax_4)
    {
        tMax_4 = dist_4;
    }
    float3  betaR_3 = rayleighCoefficients_0();
    float betaM_2 = mieCoefficient_0(p_32->turbidity_0);
    float betaMExt_2 = betaM_2 * 1.11000001430511475f;
    float cosTheta_2 = clampf_0(dot_0(rayDir_2, _S642), -1.0f, 1.0f);
    float phaseR_2 = 0.05968309938907623f * (1.0f + cosTheta_2 * cosTheta_2);
    float g_23 = clampf_0(p_32->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S648 = g_23 * g_23;
    float hgDenom_2 = 1.0f + _S648 - 2.0f * g_23 * cosTheta_2;
    float _S649 = 1.0f - _S648;
    float _S650 = 12.56637096405029297f * hgDenom_2;
    if(hgDenom_2 > 9.99999997475242708e-07f)
    {
        observerAltitude_3 = hgDenom_2;
    }
    else
    {
        observerAltitude_3 = 9.99999997475242708e-07f;
    }
    float phaseM_2 = _S649 / (_S650 * (F32_sqrt((observerAltitude_3))));
    float tPrev_2 = 0.0f;
    float3  sumR_1 = _S641;
    float3  sumM_1 = _S641;
    float u_4 = u1_0;
    float pickedFrom_0 = -1.0f;
    float pickedSpan_0 = 0.0f;
    int i_28 = int(0);
    float depthR_6 = 0.0f;
    float depthM_7 = 0.0f;
    float lumTotal_0 = 0.0f;
    for(;;)
    {
        if(i_28 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S651 = i_28 + int(1);
        float tNext_2 = tMax_4 * float(_S651 * _S651) * 0.00173611112404615f;
        float dt_3 = tNext_2 - tPrev_2;
        float tMid_2 = (tPrev_2 + tNext_2) * 0.5f;
        float u_5;
        float pickedFrom_1;
        float pickedSpan_1;
        if(dt_3 <= 0.0f)
        {
            u_5 = u_4;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            tPrev_2 = tNext_2;
            u_4 = u_5;
            pickedFrom_0 = pickedFrom_1;
            pickedSpan_0 = pickedSpan_1;
            i_28 = _S651;
            continue;
        }
        float h_9 = altitudeFromQ_0(cGround_3 + 2.0f * tMid_2 * b_10 + tMid_2 * tMid_2, planetRadius_7);
        float hc_3;
        if(h_9 < 0.0f)
        {
            hc_3 = 0.0f;
        }
        else
        {
            hc_3 = h_9;
        }
        float _S652 = - hc_3;
        float dR_1 = (F32_exp((_S652 / scaleHeight_5))) * dt_3;
        float dM_1 = (F32_exp((_S652 / 1200.0f))) * dt_3;
        float midR_1 = depthR_6 + 0.5f * dR_1;
        float midM_1 = depthM_7 + 0.5f * dM_1;
        float depthR_7 = depthR_6 + dR_1;
        float depthM_8 = depthM_7 + dM_1;
        float3  _S653 = sampleTransmittanceLut_0(p_32, hc_3, lutMuFor_0(make_float3 (rayDir_2.x * tMid_2, _S645 + _S646 * tMid_2, rayDir_2.z * tMid_2), _S642));
        float _S654 = betaMExt_2 * midM_1;
        float3  transmittance_2 = make_float3 ((F32_exp((- (betaR_3.x * midR_1 + _S654)))), (F32_exp((- (betaR_3.y * midR_1 + _S654)))), (F32_exp((- (betaR_3.z * midR_1 + _S654))))) * _S653;
        float3  _S655 = sumR_1 + transmittance_2 * make_float3 (dR_1);
        float3  _S656 = sumM_1 + transmittance_2 * make_float3 (dM_1);
        float3  c_57 = transmittance_2 * (betaR_3 * make_float3 (phaseR_2 * dR_1) + make_float3 (betaM_2 * (phaseM_2 * dM_1)));
        float lum_0 = c_57.x + c_57.y + c_57.z;
        float lumTotal_1;
        if(lum_0 > 0.0f)
        {
            float lumTotal_2 = lumTotal_0 + lum_0;
            float keep_3 = lum_0 / lumTotal_2;
            if(u_4 < keep_3)
            {
                u_5 = u_4 / keep_3;
                pickedFrom_1 = tPrev_2;
                pickedSpan_1 = dt_3;
            }
            else
            {
                u_5 = (u_4 - keep_3) / (1.0f - keep_3);
                pickedFrom_1 = pickedFrom_0;
                pickedSpan_1 = pickedSpan_0;
            }
            lumTotal_1 = lumTotal_2;
        }
        else
        {
            u_5 = u_4;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            lumTotal_1 = lumTotal_0;
        }
        sumR_1 = _S655;
        sumM_1 = _S656;
        depthR_6 = depthR_7;
        depthM_7 = depthM_8;
        lumTotal_0 = lumTotal_1;
        tPrev_2 = tNext_2;
        u_4 = u_5;
        pickedFrom_0 = pickedFrom_1;
        pickedSpan_0 = pickedSpan_1;
        i_28 = _S651;
    }
    float _S657 = sunIrradianceTop_0(p_32);
    (&seg_0)->airIn_0 = (sumR_1 * betaR_3 * make_float3 (phaseR_2) + sumM_1 * make_float3 (betaM_2 * phaseM_2)) * make_float3 (_S657);
    float _S658 = betaMExt_2 * depthM_7;
    (&seg_0)->airT_0 = make_float3 ((F32_exp((- (betaR_3.x * depthR_6 + _S658)))), (F32_exp((- (betaR_3.y * depthR_6 + _S658)))), (F32_exp((- (betaR_3.z * depthR_6 + _S658)))));
    if(pickedFrom_0 >= 0.0f)
    {
        (&seg_0)->shadowAt_0 = pickedFrom_0 + clampf_0(u2_0, 0.0f, 1.0f) * pickedSpan_0;
    }
    return seg_0;
}

static __device__ float airShadow_0(Scene_0 * s_21, StructuredBuffer<float> bounds_10, StructuredBuffer<float2 > drift_4, Rng_0 * rng_9, AirSegment_0 * seg_1, float3  ro_9, float3  rd_9, int * steps_9)
{
    bool _S659;
    if((s_21->aerialMode_0) < int(2))
    {
        _S659 = true;
    }
    else
    {
        _S659 = (seg_1->shadowAt_0) < 0.0f;
    }
    if(_S659)
    {
        return 1.0f;
    }
    float _S660 = sceneTransmittance_0(s_21, bounds_10, drift_4, rng_9, ro_9 + rd_9 * make_float3 (seg_1->shadowAt_0), s_21->sunDir_0, steps_9);
    return _S660;
}

static __device__ float3  lightTriple_0(StructuredBuffer<float> b_11, int i_29)
{
    float _S661 = __ldg((&(b_11)[i_29]));
    float _S662 = __ldg((&(b_11)[i_29 + int(1)]));
    float _S663 = __ldg((&(b_11)[i_29 + int(2)]));
    return make_float3 (_S661, _S662, _S663);
}

static __device__ int sheetLevelStart_0(int k_12)
{
    return ((int(1) << (int(2) * k_12)) - int(1)) / int(3);
}

static __device__ float lightEdge_0(float lo_12, float hi_11, float x_41)
{
    if(!(hi_11 > lo_12))
    {
        float _S664;
        if(x_41 >= lo_12)
        {
            _S664 = 1.0f;
        }
        else
        {
            _S664 = 0.0f;
        }
        return _S664;
    }
    float t_17 = clamp_0((x_41 - lo_12) / (hi_11 - lo_12), 0.0f, 1.0f);
    return t_17 * t_17 * (3.0f - 2.0f * t_17);
}

struct LightSample_0
{
    float3  lsDir_0;
    float lsDist_0;
    float3  lsIrradiance_0;
};

static __device__ LightSample_0 sampleLocalLight_0(StructuredBuffer<float> b_12, int count_0, float3  p_33, Rng_0 * rng_10)
{
    int k_13;
    float imp_0;
    float imp1_0;
    LightSample_0 ls_0;
    float3  _S665 = make_float3 (0.0f, 1.0f, 0.0f);
    (&ls_0)->lsDir_0 = _S665;
    (&ls_0)->lsDist_0 = 0.0f;
    (&ls_0)->lsIrradiance_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int _S666 = (I32_min((count_0), (int(16))));
    if(_S666 <= int(0))
    {
        return ls_0;
    }
    float _S667 = randFloat_0(rng_10);
    int _S668 = _S666 - int(1);
    int i_30 = int(0);
    for(;;)
    {
        if(i_30 < int(16))
        {
        }
        else
        {
            k_13 = _S668;
            break;
        }
        if(i_30 >= _S666)
        {
            k_13 = _S668;
            break;
        }
        float _S669 = __ldg((&(b_12)[int(8) + i_30 * int(20) + int(1)]));
        if(_S667 < _S669)
        {
            k_13 = i_30;
            break;
        }
        i_30 = i_30 + int(1);
    }
    int r_13 = int(8) + k_13 * int(20);
    float _S670 = __ldg((&(b_12)[r_13]));
    int kind_0 = int(_S670);
    float _S671 = __ldg((&(b_12)[r_13 + int(2)]));
    if(!(_S671 > 0.0f))
    {
        return ls_0;
    }
    int _S672 = r_13 + int(9);
    float3  rgb_0 = lightTriple_0(b_12, _S672);
    if(kind_0 == int(2))
    {
        (&ls_0)->lsDir_0 = lightTriple_0(b_12, r_13 + int(6));
        (&ls_0)->lsDist_0 = 1.00000001504746622e+30f;
        (&ls_0)->lsIrradiance_0 = rgb_0 / make_float3 (_S671);
        return ls_0;
    }
    float _S673 = __ldg((&(b_12)[r_13 + int(12)]));
    bool _S674;
    float floorSq_0;
    float3  q_14;
    float3  rgb_1;
    if(kind_0 == int(3))
    {
        float _S675 = __ldg((&(b_12)[r_13 + int(13)]));
        int w_8 = int(_S675);
        float _S676 = __ldg((&(b_12)[r_13 + int(14)]));
        int h_10 = int(_S676);
        float _S677 = __ldg((&(b_12)[r_13 + int(15)]));
        int texels_0 = int(_S677);
        float _S678 = __ldg((&(b_12)[r_13 + int(19)]));
        int tree_0 = int(_S678);
        float _S679 = __ldg((&(b_12)[tree_0]));
        int levels_0 = int(_S679);
        float3  origin_3 = lightTriple_0(b_12, r_13 + int(3));
        float3  axisU_0 = lightTriple_0(b_12, r_13 + int(6));
        float3  eye_0 = lightTriple_0(b_12, _S672);
        float3  axisV_0 = lightTriple_0(b_12, r_13 + int(16));
        if(w_8 <= int(0))
        {
            _S674 = true;
        }
        else
        {
            _S674 = h_10 <= int(0);
        }
        if(_S674)
        {
            _S674 = true;
        }
        else
        {
            _S674 = levels_0 < int(0);
        }
        if(_S674)
        {
            _S674 = true;
        }
        else
        {
            _S674 = levels_0 > int(12);
        }
        if(_S674)
        {
            return ls_0;
        }
        int cx_0 = int(0);
        int cy_0 = int(0);
        int lv_0 = int(0);
        floorSq_0 = 1.0f;
        for(;;)
        {
            if(lv_0 < int(12))
            {
            }
            else
            {
                break;
            }
            if(lv_0 >= levels_0)
            {
                break;
            }
            int child_0 = lv_0 + int(1);
            int _S680 = int(1) << child_0;
            int _S681 = tree_0 + int(1) + int(5) * sheetLevelStart_0(child_0);
            float imp0_0 = 0.0f;
            float imp1_1 = 0.0f;
            float imp2_0 = 0.0f;
            float imp3_0 = 0.0f;
            int c_58 = int(0);
            for(;;)
            {
                if(c_58 < int(4))
                {
                }
                else
                {
                    break;
                }
                int at_3 = _S681 + int(5) * ((int(2) * cy_0 + (c_58 >> int(1))) * _S680 + (int(2) * cx_0 + (c_58 & int(1))));
                float _S682 = __ldg((&(b_12)[at_3]));
                if(_S682 > 0.0f)
                {
                    float3  d_26 = lightTriple_0(b_12, at_3 + int(1)) - p_33;
                    float _S683 = dot_0(d_26, d_26);
                    float _S684 = __ldg((&(b_12)[at_3 + int(4)]));
                    imp_0 = _S682 / (F32_max((_S683), (_S684)));
                }
                else
                {
                    imp_0 = 0.0f;
                }
                if(c_58 == int(0))
                {
                    imp0_0 = imp_0;
                }
                else
                {
                    float imp2_1;
                    float imp3_1;
                    if(c_58 == int(1))
                    {
                        imp1_0 = imp_0;
                        imp2_1 = imp2_0;
                        imp3_1 = imp3_0;
                    }
                    else
                    {
                        if(c_58 == int(2))
                        {
                            imp1_0 = imp_0;
                            imp2_1 = imp3_0;
                        }
                        else
                        {
                            imp1_0 = imp2_0;
                            imp2_1 = imp_0;
                        }
                        float _S685 = imp1_0;
                        float _S686 = imp2_1;
                        imp1_0 = imp1_1;
                        imp2_1 = _S685;
                        imp3_1 = _S686;
                    }
                    imp1_1 = imp1_0;
                    imp2_0 = imp2_1;
                    imp3_0 = imp3_1;
                }
                c_58 = c_58 + int(1);
            }
            float _S687 = imp0_0 + imp1_1;
            float _S688 = _S687 + imp2_0;
            float total_3 = _S688 + imp3_0;
            if(!(total_3 > 0.0f))
            {
                return ls_0;
            }
            float _S689 = randFloat_0(rng_10);
            float u_6 = _S689 * total_3;
            int pickC_0;
            if(u_6 < imp0_0)
            {
                imp_0 = imp0_0;
                pickC_0 = int(0);
            }
            else
            {
                if(u_6 < _S687)
                {
                    imp_0 = imp1_1;
                    pickC_0 = int(1);
                }
                else
                {
                    if(u_6 < _S688)
                    {
                        imp_0 = imp2_0;
                        pickC_0 = int(2);
                    }
                    else
                    {
                        imp_0 = imp3_0;
                        pickC_0 = int(3);
                    }
                }
            }
            int pickC_1;
            if(!(imp_0 > 0.0f))
            {
                if(imp3_0 > 0.0f)
                {
                    imp1_0 = imp3_0;
                    pickC_1 = int(3);
                }
                else
                {
                    if(imp2_0 > 0.0f)
                    {
                        imp1_0 = imp2_0;
                        pickC_1 = int(2);
                    }
                    else
                    {
                        if(imp1_1 > 0.0f)
                        {
                            imp1_0 = imp1_1;
                            pickC_1 = int(1);
                        }
                        else
                        {
                            imp1_0 = imp0_0;
                            pickC_1 = int(0);
                        }
                    }
                }
            }
            else
            {
                imp1_0 = imp_0;
                pickC_1 = pickC_0;
            }
            float pdf_0 = floorSq_0 * (imp1_0 / total_3);
            int _S690 = int(2) * cx_0 + (pickC_1 & int(1));
            int _S691 = int(2) * cy_0 + (pickC_1 >> int(1));
            cx_0 = _S690;
            cy_0 = _S691;
            lv_0 = child_0;
            floorSq_0 = pdf_0;
        }
        if(cx_0 >= w_8)
        {
            _S674 = true;
        }
        else
        {
            _S674 = cy_0 >= h_10;
        }
        if(_S674)
        {
            _S674 = true;
        }
        else
        {
            _S674 = !(floorSq_0 > 0.0f);
        }
        if(_S674)
        {
            return ls_0;
        }
        int tx_0 = texels_0 + int(4) * (cy_0 * w_8 + cx_0);
        float _S692 = __ldg((&(b_12)[tx_0 + int(3)]));
        float u2_1 = randFloat_0(rng_10);
        float u3_0 = randFloat_0(rng_10);
        float floorSq_1 = _S673 * (_S692 * _S692);
        float3  _S693 = lightTriple_0(b_12, tx_0) * make_float3 (floorSq_1 / floorSq_0);
        q_14 = eye_0 + (origin_3 + axisU_0 * make_float3 (float(cx_0) + u2_1) + axisV_0 * make_float3 (float(cy_0) + u3_0) - eye_0) * make_float3 (_S692);
        rgb_1 = _S693;
        floorSq_0 = floorSq_1;
    }
    else
    {
        q_14 = lightTriple_0(b_12, r_13 + int(3));
        rgb_1 = rgb_0;
        floorSq_0 = _S673;
    }
    float3  d_27 = q_14 - p_33;
    float dSq_0 = dot_0(d_27, d_27);
    float dist_5 = (F32_sqrt((dSq_0)));
    if(dist_5 > 0.0f)
    {
        q_14 = d_27 / make_float3 (dist_5);
    }
    else
    {
        q_14 = _S665;
    }
    (&ls_0)->lsDir_0 = q_14;
    (&ls_0)->lsDist_0 = dist_5;
    float3  e_1 = rgb_1 / make_float3 ((F32_max((dSq_0), (floorSq_0))));
    float3  e_2;
    if(kind_0 == int(1))
    {
        float _S694 = __ldg((&(b_12)[r_13 + int(13)]));
        float _S695 = __ldg((&(b_12)[r_13 + int(14)]));
        e_2 = e_1 * make_float3 (lightEdge_0(_S694, _S695, dot_0(- (&ls_0)->lsDir_0, lightTriple_0(b_12, r_13 + int(6)))));
    }
    else
    {
        e_2 = e_1;
    }
    if(kind_0 != int(3))
    {
        float _S696 = __ldg((&(b_12)[r_13 + int(16)]));
        _S674 = _S696 > 0.0f;
    }
    else
    {
        _S674 = false;
    }
    if(_S674)
    {
        float _S697 = __ldg((&(b_12)[r_13 + int(15)]));
        float _S698 = __ldg((&(b_12)[r_13 + int(16)]));
        e_2 = e_2 * make_float3 (1.0f - lightEdge_0(_S697, _S698, dist_5));
    }
    (&ls_0)->lsIrradiance_0 = e_2 / make_float3 (_S671);
    return ls_0;
}

static __device__ float sceneTransmittanceUpTo_0(Scene_0 * s_22, StructuredBuffer<float> bounds_11, StructuredBuffer<float2 > drift_5, Rng_0 * rng_11, float3  p_34, float3  dir_7, float tMax_5, int * steps_10)
{
    float _S699 = transmittanceUpTo_0(&s_22->medium_0, &s_22->grid_0, bounds_11, drift_5, rng_11, p_34, dir_7, tMax_5, steps_10);
    bool _S700;
    if((s_22->layer2On_0) != int(0))
    {
        _S700 = _S699 > 0.0f;
    }
    else
    {
        _S700 = false;
    }
    float tr_10;
    if(_S700)
    {
        MajorantGrid_0 _S701 = gridFor_0(&s_22->medium2_0, &s_22->grid2_0, p_34);
        MajorantGrid_0 _S702 = _S701;
        float _S703 = transmittanceUpTo_0(&s_22->medium2_0, &_S702, bounds_11, drift_5, rng_11, p_34, dir_7, tMax_5, steps_10);
        tr_10 = _S699 * _S703;
    }
    else
    {
        tr_10 = _S699;
    }
    return tr_10;
}

static __device__ float3  sampleHG_0(Rng_0 * rng_12, float3  wo_0, float g_24, float * cosT_6)
{
    float _S704 = clamp_0(g_24, -0.99900001287460327f, 0.99900001287460327f);
    float u1_1 = randFloat_0(rng_12);
    float u2_2 = randFloat_0(rng_12);
    if((F32_abs((_S704))) < 0.00100000004749745f)
    {
        *cosT_6 = 1.0f - 2.0f * u1_1;
    }
    else
    {
        float _S705 = _S704 * _S704;
        float _S706 = 2.0f * _S704;
        float s_23 = (1.0f - _S705) / (1.0f - _S704 + _S706 * u1_1);
        *cosT_6 = (1.0f + _S705 - s_23 * s_23) / _S706;
    }
    float _S707 = clamp_0(*cosT_6, -1.0f, 1.0f);
    *cosT_6 = _S707;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S707 * _S707))))));
    float phi_0 = 6.28318548202514648f * u2_2;
    float3  w_9 = normalize_0(wo_0);
    float3  a_7;
    if((F32_abs((w_9.y))) < 0.94999998807907104f)
    {
        a_7 = make_float3 (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_7 = make_float3 (1.0f, 0.0f, 0.0f);
    }
    float3  u_7 = normalize_0(cross_0(a_7, w_9));
    return normalize_0(make_float3 (sinT_0 * (F32_cos((phi_0)))) * u_7 + make_float3 (sinT_0 * (F32_sin((phi_0)))) * cross_0(w_9, u_7) + make_float3 (*cosT_6) * w_9);
}

static __device__ float3  sampleDraine_0(Rng_0 * rng_13, float3  wo_1, float g_25, float a_8, float * cosT_7)
{
    float3  dir_8 = sampleHG_0(rng_13, wo_1, g_25, cosT_7);
    if(!(a_8 > 0.0f))
    {
        return dir_8;
    }
    float3  dir_9 = dir_8;
    int i_31 = int(0);
    for(;;)
    {
        if(i_31 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S708 = randFloat_0(rng_13);
        if((_S708 * (1.0f + a_8)) <= (1.0f + a_8 * *cosT_7 * *cosT_7))
        {
            break;
        }
        float3  _S709 = sampleHG_0(rng_13, wo_1, g_25, cosT_7);
        int i_32 = i_31 + int(1);
        dir_9 = _S709;
        i_31 = i_32;
    }
    return dir_9;
}

static __device__ float3  samplePhaseDir_0(PhaseInput_0 * p_35, Rng_0 * rng_14, float3  wo_2, float * weight_0)
{
    float cosT_8;
    float3  dir_10;
    float _S710;
    if((p_35->useIce_0) != int(0))
    {
        float _S711 = randFloat_0(rng_14);
        if(_S711 < 0.72000002861022949f)
        {
            float3  _S712 = sampleHG_0(rng_14, wo_2, 0.85000002384185791f, &cosT_8);
            dir_10 = _S712;
        }
        else
        {
            float3  _S713 = sampleHG_0(rng_14, wo_2, 0.0f, &cosT_8);
            dir_10 = _S713;
        }
        float pdf_1 = 0.72000002861022949f * hg_0(cosT_8, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_1 > 9.99999971718068537e-10f)
        {
            _S710 = phaseIce_0(cosT_8) / pdf_1;
        }
        else
        {
            _S710 = 0.0f;
        }
        *weight_0 = _S710;
    }
    else
    {
        float _S714 = randFloat_0(rng_14);
        if(_S714 < (p_35->draineW_0))
        {
            float3  _S715 = sampleDraine_0(rng_14, wo_2, p_35->draineG_0, p_35->draineAlpha_0, &cosT_8);
            dir_10 = _S715;
        }
        else
        {
            float3  _S716 = sampleHG_0(rng_14, wo_2, p_35->hgG_0, &cosT_8);
            dir_10 = _S716;
        }
        float _S717 = phaseLiquid_0(p_35, cosT_8);
        if(_S717 > 9.99999971718068537e-10f)
        {
            _S710 = 1.0f;
        }
        else
        {
            _S710 = 0.0f;
        }
        *weight_0 = _S710;
    }
    return dir_10;
}

struct PathState_0
{
    float3  psRadiance_0;
    float3  psThroughput_0;
    float3  psOrigin_0;
    float3  psDir_0;
    Rng_0 psRng_0;
    int psBounce_0;
    int psAlive_0;
    int psEvents_0;
    int psCapped_0;
    int psSteps_0;
};

static __device__ bool pathScatter_0(Scene_0 * s_24, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_12, StructuredBuffer<float2 > drift_6, PathState_0 * st_1, float3  p_36, int layer_1, bool nee_0)
{
    float3  _S718 = s_24->albedo_0;
    PhaseInput_0 matterPhase_0;
    float3  matterAlbedo_1;
    if(layer_1 != int(0))
    {
        matterPhase_0 = s_24->phase2_0;
        matterAlbedo_1 = s_24->albedo2_0;
    }
    else
    {
        matterPhase_0 = *ph_1;
        matterAlbedo_1 = _S718;
    }
    if(nee_0)
    {
        float3  _S719 = s_24->sunDir_0;
        float _S720 = sceneTransmittance_0(s_24, bounds_12, drift_6, &st_1->psRng_0, p_36 + s_24->sunDir_0 * make_float3 (s_24->shadowOffset_0), s_24->sunDir_0, &st_1->psSteps_0);
        if(_S720 > 0.0f)
        {
            float _S721 = dot_0(st_1->psDir_0, _S719);
            PhaseInput_0 _S722 = matterPhase_0;
            float _S723 = phaseAt_0(&_S722, _S721);
            float3  _S724 = st_1->psThroughput_0 * matterAlbedo_1 * make_float3 (_S723) * make_float3 (_S720);
            float3  _S725 = sunIrradianceAt_0(s_24, p_36);
            st_1->psRadiance_0 = st_1->psRadiance_0 + _S724 * _S725;
        }
    }
    int _S726 = s_24->ltCount_0;
    if((s_24->ltCount_0) > int(0))
    {
        Rng_0 _S727 = st_1->psRng_0;
        Rng_0 _S728 = splitRng_0(&_S727, 281U);
        Rng_0 lr_0 = _S728;
        LightSample_0 ls_1 = sampleLocalLight_0(s_24->ltBuffer_0, _S726, p_36, &lr_0);
        if(any_0((ls_1.lsIrradiance_0) > make_float3 (0.0f, 0.0f, 0.0f)))
        {
            float _S729 = sceneTransmittanceUpTo_0(s_24, bounds_12, drift_6, &lr_0, p_36, ls_1.lsDir_0, ls_1.lsDist_0, &st_1->psSteps_0);
            if(_S729 > 0.0f)
            {
                float _S730 = dot_0(st_1->psDir_0, ls_1.lsDir_0);
                PhaseInput_0 _S731 = matterPhase_0;
                float _S732 = phaseAt_0(&_S731, _S730);
                st_1->psRadiance_0 = st_1->psRadiance_0 + st_1->psThroughput_0 * matterAlbedo_1 * make_float3 (_S732) * make_float3 (_S729) * ls_1.lsIrradiance_0;
            }
        }
    }
    PhaseInput_0 _S733 = matterPhase_0;
    float w_10;
    float3  _S734 = samplePhaseDir_0(&_S733, &st_1->psRng_0, st_1->psDir_0, &w_10);
    st_1->psThroughput_0 = st_1->psThroughput_0 * (matterAlbedo_1 * make_float3 (w_10));
    st_1->psOrigin_0 = p_36;
    st_1->psDir_0 = _S734;
    if((st_1->psBounce_0) >= (s_24->rrStartBounce_0))
    {
        float p2_0 = clamp_0((F32_max((st_1->psThroughput_0.x), ((F32_max((st_1->psThroughput_0.y), (st_1->psThroughput_0.z)))))), 0.05000000074505806f, 1.0f);
        float _S735 = randFloat_0(&st_1->psRng_0);
        if(_S735 > p2_0)
        {
            return false;
        }
        st_1->psThroughput_0 = st_1->psThroughput_0 / make_float3 (p2_0);
    }
    return true;
}

static __device__ PathState_0 pathBegin_0(Scene_0 * s_25, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_13, StructuredBuffer<float2 > drift_7, Rng_0 * rng_15, float3  ro_10, float3  rd_10)
{
    PathState_0 st_2;
    float3  _S736 = make_float3 (0.0f, 0.0f, 0.0f);
    (&st_2)->psRadiance_0 = _S736;
    (&st_2)->psThroughput_0 = make_float3 (1.0f, 1.0f, 1.0f);
    (&st_2)->psOrigin_0 = ro_10;
    (&st_2)->psDir_0 = rd_10;
    (&st_2)->psRng_0 = *rng_15;
    (&st_2)->psBounce_0 = int(0);
    (&st_2)->psAlive_0 = int(0);
    (&st_2)->psEvents_0 = int(0);
    (&st_2)->psCapped_0 = int(0);
    (&st_2)->psSteps_0 = int(0);
    int _S737 = (I32_min((s_25->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_25->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S737 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    int cameraHit_0 = int(0);
    float3  cameraHitAt_0 = _S736;
    int cameraHitLayer_0 = int(0);
    float cameraResume_0 = 0.0f;
    if(sunAlongCamera_0)
    {
        Rng_0 _S738 = splitRng_0(rng_15, 1510U);
        Rng_0 segmentRng_0 = _S738;
        Rng_0 _S739 = splitRng_0(rng_15, 1511U);
        Rng_0 _S740 = _S739;
        float3  _S741 = cameraSegmentSun_0(s_25, ph_2, bounds_13, drift_7, &segmentRng_0, &_S740, ro_10, rd_10, &(&st_2)->psSteps_0, &cameraHit_0, &cameraHitAt_0, &cameraHitLayer_0, &cameraResume_0);
        (&st_2)->psRadiance_0 = (&st_2)->psRadiance_0 + (&st_2)->psThroughput_0 * _S741;
    }
    bool airOn_0;
    if(((&s_25->environment_0)->envMode_0) == int(1))
    {
        airOn_0 = (s_25->aerialMode_0) != int(0);
    }
    else
    {
        airOn_0 = false;
    }
    Rng_0 _S742 = splitRng_0(rng_15, 2590U);
    Rng_0 airRng_0 = _S742;
    if(_S737 <= int(0))
    {
        (&st_2)->psCapped_0 = int(1);
        return st_2;
    }
    float3  p_37;
    int layer_2;
    bool collided_0;
    if(sunAlongCamera_0)
    {
        collided_0 = cameraHit_0 != int(2);
    }
    else
    {
        collided_0 = false;
    }
    if(collided_0)
    {
        bool _S743 = cameraHit_0 == int(1);
        p_37 = cameraHitAt_0;
        layer_2 = cameraHitLayer_0;
        collided_0 = _S743;
    }
    else
    {
        if(sunAlongCamera_0)
        {
            bool _S744 = sceneFreeFlight_0(s_25, bounds_13, drift_7, &(&st_2)->psRng_0, ro_10 + rd_10 * make_float3 (cameraResume_0), rd_10, &p_37, &layer_2, &(&st_2)->psSteps_0);
            collided_0 = _S744;
        }
        else
        {
            bool _S745 = sceneFreeFlight_0(s_25, bounds_13, drift_7, &(&st_2)->psRng_0, ro_10, rd_10, &p_37, &layer_2, &(&st_2)->psSteps_0);
            collided_0 = _S745;
        }
    }
    float3  env_1;
    if(!collided_0)
    {
        float3  _S746 = pathEnvironment_0(s_25, ro_10, rd_10, true);
        if(airOn_0)
        {
            sunAlongCamera_0 = (s_25->aerialMode_0) >= int(2);
        }
        else
        {
            sunAlongCamera_0 = false;
        }
        if(sunAlongCamera_0)
        {
            float u1_2 = randFloat_0(&airRng_0);
            float u2_3 = randFloat_0(&airRng_0);
            if((s_25->airMapOn_0) != int(0))
            {
                float3  _S747 = airShadowLoss_0(&(&s_25->environment_0)->sky_0, &s_25->airMapIce_0, &s_25->airMapCu_0, ro_10, rd_10, 1.00000001504746622e+30f, u2_3);
                env_1 = max_0(_S746 - _S747, _S736);
            }
            else
            {
                AirSegment_0 _S748 = airSegment_0(&(&s_25->environment_0)->sky_0, ro_10.y, rd_10, 1.00000001504746622e+30f, u1_2, u2_3);
                AirSegment_0 _S749 = _S748;
                float _S750 = airShadow_0(s_25, bounds_13, drift_7, &airRng_0, &_S749, ro_10, rd_10, &(&st_2)->psSteps_0);
                env_1 = _S746 - _S748.airIn_0 * make_float3 (1.0f - _S750);
            }
        }
        else
        {
            env_1 = _S746;
        }
        (&st_2)->psRadiance_0 = (&st_2)->psRadiance_0 + (&st_2)->psThroughput_0 * env_1;
        return st_2;
    }
    (&st_2)->psEvents_0 = (&st_2)->psEvents_0 + int(1);
    if(airOn_0)
    {
        float u1_3 = randFloat_0(&airRng_0);
        float u2_4 = randFloat_0(&airRng_0);
        float dist_6 = length_0(p_37 - ro_10);
        AirSegment_0 _S751 = airSegment_0(&(&s_25->environment_0)->sky_0, ro_10.y, rd_10, dist_6, u1_3, u2_4);
        if((s_25->aerialMode_0) >= int(2))
        {
            airOn_0 = (s_25->airMapOn_0) != int(0);
        }
        else
        {
            airOn_0 = false;
        }
        if(airOn_0)
        {
            float3  _S752 = airShadowLoss_0(&(&s_25->environment_0)->sky_0, &s_25->airMapIce_0, &s_25->airMapCu_0, ro_10, rd_10, dist_6, u2_4);
            env_1 = max_0(_S751.airIn_0 - _S752, _S736);
        }
        else
        {
            AirSegment_0 _S753 = _S751;
            float _S754 = airShadow_0(s_25, bounds_13, drift_7, &airRng_0, &_S753, ro_10, rd_10, &(&st_2)->psSteps_0);
            env_1 = _S751.airIn_0 * make_float3 (_S754);
        }
        (&st_2)->psRadiance_0 = (&st_2)->psRadiance_0 + (&st_2)->psThroughput_0 * env_1;
        (&st_2)->psThroughput_0 = (&st_2)->psThroughput_0 * _S751.airT_0;
    }
    bool _S755 = pathScatter_0(s_25, ph_2, bounds_13, drift_7, &st_2, p_37, layer_2, !sunAlongCamera_0);
    if(_S755)
    {
        (&st_2)->psBounce_0 = int(1);
        (&st_2)->psAlive_0 = int(1);
    }
    return st_2;
}

static __device__ void pathBounce_0(Scene_0 * s_26, PhaseInput_0 * ph_3, StructuredBuffer<float> bounds_14, StructuredBuffer<float2 > drift_8, PathState_0 * st_3)
{
    if((st_3->psAlive_0) == int(0))
    {
        return;
    }
    if((st_3->psBounce_0) >= (I32_min((s_26->maxBounces_0), (int(256)))))
    {
        st_3->psCapped_0 = int(1);
        st_3->psAlive_0 = int(0);
        return;
    }
    float3  p_38;
    int layer_3;
    bool _S756 = sceneFreeFlight_0(s_26, bounds_14, drift_8, &st_3->psRng_0, st_3->psOrigin_0, st_3->psDir_0, &p_38, &layer_3, &st_3->psSteps_0);
    if(!_S756)
    {
        float3  _S757 = st_3->psThroughput_0;
        float3  _S758 = pathEnvironment_0(s_26, st_3->psOrigin_0, st_3->psDir_0, false);
        st_3->psRadiance_0 = st_3->psRadiance_0 + _S757 * _S758;
        st_3->psAlive_0 = int(0);
        return;
    }
    st_3->psEvents_0 = st_3->psEvents_0 + int(1);
    bool _S759 = pathScatter_0(s_26, ph_3, bounds_14, drift_8, st_3, p_38, layer_3, true);
    if(_S759)
    {
        st_3->psBounce_0 = st_3->psBounce_0 + int(1);
    }
    else
    {
        st_3->psAlive_0 = int(0);
    }
    return;
}

struct TraceResult_0
{
    float3  pathRadiance_0;
    int scatterEvents_0;
    int capped_0;
    int trackingSteps_0;
};

static __device__ TraceResult_0 trace_0(Scene_0 * s_27, PhaseInput_0 * ph_4, StructuredBuffer<float> bounds_15, StructuredBuffer<float2 > drift_9, Rng_0 * rng_16, float3  ro_11, float3  rd_11)
{
    Rng_0 _S760 = *rng_16;
    PathState_0 _S761 = pathBegin_0(s_27, ph_4, bounds_15, drift_9, &_S760, ro_11, rd_11);
    PathState_0 st_4 = _S761;
    int i_33 = int(1);
    for(;;)
    {
        bool _S762;
        if(i_33 < int(256))
        {
            _S762 = ((&st_4)->psAlive_0) != int(0);
        }
        else
        {
            _S762 = false;
        }
        if(_S762)
        {
        }
        else
        {
            break;
        }
        pathBounce_0(s_27, ph_4, bounds_15, drift_9, &st_4);
        i_33 = i_33 + int(1);
    }
    if(((&st_4)->psAlive_0) != int(0))
    {
        (&st_4)->psCapped_0 = int(1);
    }
    *rng_16 = (&st_4)->psRng_0;
    TraceResult_0 r_14;
    (&r_14)->pathRadiance_0 = (&st_4)->psRadiance_0;
    (&r_14)->scatterEvents_0 = (&st_4)->psEvents_0;
    (&r_14)->capped_0 = (&st_4)->psCapped_0;
    (&r_14)->trackingSteps_0 = (&st_4)->psSteps_0;
    return r_14;
}

extern "C" __global__ void traceTrial(Scene_0 scene_0, PhaseInput_0 phase_0, StructuredBuffer<float> bounds_16, StructuredBuffer<float2 > drift_10, float3  origin_4, float3  direction_0, RWStructuredBuffer<float3 > outRadiance_0, RWStructuredBuffer<int> outScatterEvents_0, RWStructuredBuffer<int> outCapped_0, RWStructuredBuffer<int> outSteps_0, uint seed_2, int count_1)
{
    int i_34 = int((blockIdx * blockDim + threadIdx).x);
    if(i_34 >= count_1)
    {
        return;
    }
    Rng_0 rng_17 = makeRngForIndex_0(seed_2, i_34);
    Scene_0 _S763 = scene_0;
    PhaseInput_0 _S764 = phase_0;
    TraceResult_0 _S765 = trace_0(&_S763, &_S764, bounds_16, drift_10, &rng_17, origin_4, direction_0);
    *(&(outRadiance_0)[i_34]) = _S765.pathRadiance_0;
    *(&(outScatterEvents_0)[i_34]) = _S765.scatterEvents_0;
    *(&(outCapped_0)[i_34]) = _S765.capped_0;
    *(&(outSteps_0)[i_34]) = _S765.trackingSteps_0;
    return;
}

extern "C" __global__ void phaseValueTrial(PhaseInput_0 phase_1, StructuredBuffer<float> inCos_0, RWStructuredBuffer<float> outPhase_0, int count_2)
{
    int i_35 = int((blockIdx * blockDim + threadIdx).x);
    if(i_35 >= count_2)
    {
        return;
    }
    float * _S766 = (&(outPhase_0)[i_35]);
    float _S767 = __ldg((&(inCos_0)[i_35]));
    PhaseInput_0 _S768 = phase_1;
    float _S769 = phaseAt_0(&_S768, _S767);
    *_S766 = _S769;
    return;
}

static __device__ PhaseInput_0 phaseFromDropletDiameter_0(float diameterMicrons_0, int useIce_1)
{
    float d_28 = clamp_0(diameterMicrons_0, 5.0f, 50.0f);
    PhaseInput_0 p_39;
    (&p_39)->hgG_0 = clamp_0((F32_exp((-0.09905669838190079f / (d_28 - 1.6715400218963623f)))), -0.99900001287460327f, 0.99900001287460327f);
    (&p_39)->draineG_0 = clamp_0((F32_exp((- (2.20678997039794922f / (d_28 + 3.91029000282287598f)) - 0.4289340078830719f))), -0.99900001287460327f, 0.99900001287460327f);
    (&p_39)->draineAlpha_0 = (F32_exp((3.62489008903503418f - 8.29288005828857422f / (d_28 + 5.52825021743774414f))));
    (&p_39)->draineW_0 = (F32_exp((- (0.59908497333526611f / (d_28 - 0.64158302545547485f)) - 0.66588801145553589f)));
    (&p_39)->useIce_0 = useIce_1;
    (&p_39)->lobeG_0 = 0.0f;
    (&p_39)->lobeWeight_0 = 0.0f;
    return p_39;
}

extern "C" __global__ void phaseParamsTrial(float diameterMicrons_1, RWStructuredBuffer<float4 > outParams_0)
{
    PhaseInput_0 p_40 = phaseFromDropletDiameter_0(diameterMicrons_1, int(0));
    *(&(outParams_0)[int(0)]) = make_float4 (p_40.hgG_0, p_40.draineG_0, p_40.draineAlpha_0, p_40.draineW_0);
    return;
}

