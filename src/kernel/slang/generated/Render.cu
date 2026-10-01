// GENERATED FROM Render.slang BY slangc -- DO NOT EDIT.
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

static __device__ float3  max_0(float3  x_3, float3  y_1)
{
    float3  result_0;
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_max((_slang_vector_get_element(x_3, i_0)), (_slang_vector_get_element(y_1, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ int StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    uint2  _S7 = make_uint2(_elementCount_0, _stride_0);
    return int(_S7.x);
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

static __device__ float dot_1(float2  x_4, float2  y_2)
{
    return x_4.x * y_2.x + x_4.y * y_2.y;
}

static __device__ float3  floor_0(float3  x_5)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_floor((_slang_vector_get_element(x_5, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
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

static __device__ float lerp_0(float x_6, float y_3, float s_0)
{
    return x_6 + (y_3 - x_6) * s_0;
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_0(p_0);
    int3  _S12 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S13 = u_0.x;
    float _S14 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_0(hash33_0(_S12), f_0), dot_0(hash33_0(_S12 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S13), lerp_0(dot_0(hash33_0(_S12 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S12 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S13), _S14), lerp_0(lerp_0(dot_0(hash33_0(_S12 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S12 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S13), lerp_0(dot_0(hash33_0(_S12 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S12 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S13), _S14), u_0.z);
}

static __device__ float2  orgWarpOffset_0(Organization_0 * o_0, float2  g_0)
{
    float2  s_1 = g_0 / make_float2 (2.5f);
    float _S15 = s_1.x;
    float _S16 = s_1.y;
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

static __device__ float2  floor_1(float2  x_7)
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
        *_slang_vector_get_element_ptr(&result_2, i_2) = (F32_floor((_slang_vector_get_element(x_7, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
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
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_0(0.34999999403953552f, 1.0f, h_2.y);
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

static __device__ float clamp_0(float x_8, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_8), (minBound_0)))), (maxBound_0)));
}

static __device__ float saturate_0(float x_9)
{
    return clamp_0(x_9, 0.0f, 1.0f);
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

static __device__ float2  lerp_1(float2  x_10, float2  y_4, float2  s_2)
{
    return x_10 + (y_4 - x_10) * s_2;
}

static __device__ float2  orgGradToWorld_0(Organization_0 * o_3, float2  gp_0, float spacing_1)
{
    if((o_3->ogOn_0) == int(0))
    {
        return gp_0 / make_float2 (spacing_1);
    }
    float2  s_3 = gp_0 / make_float2 (spacing_1 * o_3->ogStretch_0, spacing_1);
    return o_3->ogAxis_0 * make_float2 (s_3.x) + make_float2 (- o_3->ogAxis_0.y, o_3->ogAxis_0.x) * make_float2 (s_3.y);
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
    float s_4 = 2.0f * (F32_frac((dot_1(q_1, o_4->ogWaveK_0)))) - 1.0f;
    float tri_0 = 1.0f - (F32_abs((s_4)));
    float crest_0 = tri_0 * tri_0 * (3.0f - 2.0f * tri_0);
    float dCrest_0 = 6.0f * tri_0 * (1.0f - tri_0);
    float dTri_0;
    if(s_4 > 0.0f)
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
        float fill_0 = lerp_0(w_0, 0.40000000596046448f, _S32);
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
        float s_5 = lerp_0(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S36);
        float _S40 = _S34 * s_5;
        _S33 = _S33 * make_float2 (s_5) + gcn_0 * make_float2 (_S34 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S36));
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
        int i_3 = int(-1);
        for(;;)
        {
            if(i_3 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_2 = _S45 + make_int2 (i_3, j_1);
            float _S47 = convVigour_0(c_6, slot_2);
            if(_S47 <= 0.0f)
            {
                i_3 = i_3 + int(1);
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
            i_3 = i_3 + int(1);
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
    float _S54 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_0(_S53, closedField_0, c_6->cvPolarity_0), lerp_1(goTop_0, gClosed_0, make_float2 (c_6->cvPolarity_0)), grad_2);
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
            int2  slot_3 = _S57 + make_int2 (i_4, j_3);
            float _S58 = convVigour_0(c_7, slot_3);
            if(_S58 <= 0.0f)
            {
                i_4 = i_4 + int(1);
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
            i_4 = i_4 + int(1);
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
    float _S65 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_0(_S64, closedField_1, c_7->cvPolarity_0), lerp_1(goTop_3, gClosed_1, make_float2 (c_7->cvPolarity_0)), grad_3);
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
            int2  slot_5 = _S70 + make_int2 (i_5, j_5);
            float _S72 = convVigour_0(c_8, slot_5);
            if(_S72 <= 0.0f)
            {
                i_5 = i_5 + int(1);
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
            i_5 = i_5 + int(1);
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
    *grad_4 = lerp_1(goTop_6, gClosed_2, make_float2 (c_8->cvPolarity_0)) / make_float2 (_S67);
    return lerp_0(_S77, closedField_2, _S78);
}

static __device__ bool any_0(bool2  x_11)
{
    bool result_3 = false;
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
        if(result_3)
        {
            result_3 = true;
        }
        else
        {
            result_3 = (bool((_slang_vector_get_element(x_11, i_6))));
        }
        i_6 = i_6 + int(1);
    }
    return result_3;
}

static __device__ int clamp_1(int x_12, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_12), (minBound_1)))), (maxBound_1)));
}

static __device__ float3  lerp_2(float3  x_13, float3  y_5, float3  s_6)
{
    return x_13 + (y_5 - x_13) * s_6;
}

static __device__ int2  min_0(int2  x_14, int2  y_6)
{
    int2  result_4;
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
        *_slang_vector_get_element_ptr(&result_4, i_7) = (I32_min((_slang_vector_get_element(x_14, i_7)), (_slang_vector_get_element(y_6, i_7))));
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static __device__ float2  max_1(float2  x_15, float2  y_7)
{
    float2  result_5;
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
        *_slang_vector_get_element_ptr(&result_5, i_8) = (F32_max((_slang_vector_get_element(x_15, i_8)), (_slang_vector_get_element(y_7, i_8))));
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static __device__ float2  min_1(float2  x_16, float2  y_8)
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
        *_slang_vector_get_element_ptr(&result_6, i_9) = (F32_min((_slang_vector_get_element(x_16, i_9)), (_slang_vector_get_element(y_8, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static __device__ float2  clamp_2(float2  x_17, float2  minBound_2, float2  maxBound_2)
{
    return min_1(max_1(x_17, minBound_2), maxBound_2);
}

static __device__ float length_1(float2  x_18)
{
    return (F32_sqrt((dot_1(x_18, x_18))));
}

static __device__ float2  abs_0(float2  x_19)
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
        *_slang_vector_get_element_ptr(&result_7, i_10) = (F32_abs((_slang_vector_get_element(x_19, i_10))));
        i_10 = i_10 + int(1);
    }
    return result_7;
}

static __device__ bool all_0(bool2  x_20)
{
    bool result_8 = true;
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
        if(result_8)
        {
            result_8 = (bool((_slang_vector_get_element(x_20, i_11))));
        }
        else
        {
            result_8 = false;
        }
        i_11 = i_11 + int(1);
    }
    return result_8;
}

static __device__ float smoothstep_0(float min_2, float max_2, float x_21)
{
    float _S79 = saturate_0((x_21 - min_2) / (max_2 - min_2));
    return _S79 * _S79 * (3.0f - (_S79 + _S79));
}

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S80 = __ldg(&(ptr_0->x));
    float _S81 = __ldg(&(ptr_0->y));
    float _S82 = __ldg(&(ptr_0->z));
    return make_float3 (_S80, _S81, _S82);
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

static __device__ Rng_0 splitRng_0(Rng_0 * r_2, uint salt_1)
{
    uint s_7 = ((r_2->state_0) ^ (salt_1 * 2654435761U)) * 747796405U + 2891336453U;
    uint s_8 = ((s_7 >> ((s_7 >> 28U) + 4U)) ^ s_7) * 277803737U;
    return makeRng_0((s_8 >> 22U) ^ s_8);
}

static __device__ bool clipAxis_0(float o_5, float d_4, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_4))) < 9.99999971718068537e-10f)
    {
        bool _S83;
        if(o_5 >= lo_0)
        {
            _S83 = o_5 <= hi_0;
        }
        else
        {
            _S83 = false;
        }
        return _S83;
    }
    float ta_0 = (lo_0 - o_5) / d_4;
    float tb_0 = (hi_0 - o_5) / d_4;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S84 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S84;
    return _S84 > (*t0_0);
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
    float _S85 = rd_0.y;
    bool _S86;
    if((F32_abs((_S85))) < 9.99999997475242708e-07f)
    {
        float _S87 = ro_0.y;
        if(_S87 < (m_0->slabBottom_0))
        {
            _S86 = true;
        }
        else
        {
            _S86 = _S87 > (m_0->slabTop_0);
        }
        if(_S86)
        {
            return false;
        }
    }
    else
    {
        float _S88 = ro_0.y;
        float ta_1 = (m_0->slabBottom_0 - _S88) / _S85;
        float tb_1 = (m_0->slabTop_0 - _S88) / _S85;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S89 = (m_0->clipOn_0) != int(0);
    float2  lo_1;
    if(_S89)
    {
        lo_1 = m_0->clipLo_0;
    }
    else
    {
        lo_1 = make_float2 (-1.0e+09f, -1.0e+09f);
    }
    float2  hi_1;
    if(_S89)
    {
        hi_1 = m_0->clipHi_0;
    }
    else
    {
        hi_1 = make_float2 (1.0e+09f, 1.0e+09f);
    }
    float _S90 = m_0->fadeRadius_0;
    if((m_0->fadeRadius_0) > 0.0f)
    {
        float2  _S91 = min_1(hi_1, m_0->fadeAt_0 + make_float2 (_S90));
        lo_1 = max_1(lo_1, m_0->fadeAt_0 - make_float2 (_S90));
        hi_1 = _S91;
    }
    bool _S92 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S92)
    {
        return false;
    }
    bool _S93 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S93)
    {
        return false;
    }
    float _S94 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S94;
    if(_S94 > (*t0_1))
    {
        _S86 = (*t1_1) > 0.0f;
    }
    else
    {
        _S86 = false;
    }
    return _S86;
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
        int3  _S95 = make_int3 (int(0), int(0), int(0));
        (&d_5)->cell_0 = _S95;
        (&d_5)->stepDir_0 = _S95;
        float3  _S96 = make_float3 (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_5)->tMax_0 = _S96;
        (&d_5)->tDelta_0 = _S96;
        return d_5;
    }
    float3  p_1 = ro_1 + rd_1 * make_float3 (t_3);
    float3  _S97 = floor_0((p_1 - g_3->origin_0) / g_3->cellExtent_0);
    int3  _S98 = make_int3 ((int)_S97.x, (int)_S97.y, (int)_S97.z);
    (&d_5)->cell_0 = _S98;
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
        int _S99 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            *_slang_vector_get_element_ptr(&(&d_5)->stepDir_0, a_0) = int(0);
            *_slang_vector_get_element_ptr(&(&d_5)->tMax_0, a_0) = 1.00000001504746622e+30f;
            *_slang_vector_get_element_ptr(&(&d_5)->tDelta_0, a_0) = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S100 = _slang_vector_get_element(rd_1, _S99) > 0.0f;
            int _S101;
            if(_S100)
            {
                _S101 = int(1);
            }
            else
            {
                _S101 = int(-1);
            }
            *_slang_vector_get_element_ptr(&(&d_5)->stepDir_0, a_0) = _S101;
            float _S102 = *_slang_vector_get_element_ptr(&g_3->origin_0, a_0);
            float _S103 = float(*_slang_vector_get_element_ptr(&(&d_5)->cell_0, a_0));
            float _S104;
            if(_S100)
            {
                _S104 = 1.0f;
            }
            else
            {
                _S104 = 0.0f;
            }
            *_slang_vector_get_element_ptr(&(&d_5)->tMax_0, a_0) = t_3 + (_S102 + (_S103 + _S104) * *_slang_vector_get_element_ptr(&g_3->cellExtent_0, a_0) - _slang_vector_get_element(p_1, a_0)) / _slang_vector_get_element(rd_1, _S99);
            *_slang_vector_get_element_ptr(&(&d_5)->tDelta_0, a_0) = (F32_abs((*_slang_vector_get_element_ptr(&g_3->cellExtent_0, a_0) / _slang_vector_get_element(rd_1, _S99))));
        }
        a_0 = a_0 + int(1);
    }
    return d_5;
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

static __device__ float convDomeHeight_0(float top_0, float radius_0, float shape_0, float r_3)
{
    bool _S112;
    if(top_0 <= 0.0f)
    {
        _S112 = true;
    }
    else
    {
        _S112 = r_3 >= radius_0;
    }
    if(_S112)
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
    float _S113 = c_12->cvHeroRadius_0;
    float _S114 = c_12->cvPileusThick_0;
    bool _S115;
    float best_0;
    if((c_12->cvPileusThick_0) > 0.0f)
    {
        float rp_0 = 0.60000002384185791f * _S113;
        float _S116 = c_12->cvPileusGap_0;
        float _S117 = convHeroHeight_0(c_12, rp_0 * 0.60000002384185791f);
        float _S118 = 0.5f * _S114;
        float bottom_0 = _S116 + _S117 - _S118;
        float top_1 = _S116 + c_12->cvHeroTop_0 + _S118;
        if(gap2_0 < (rp_0 * rp_0))
        {
            _S115 = high_0 >= bottom_0;
        }
        else
        {
            _S115 = false;
        }
        if(_S115)
        {
            _S115 = low_0 <= top_1;
        }
        else
        {
            _S115 = false;
        }
        if(_S115)
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
    float _S119 = c_12->cvVelumThick_0;
    if((c_12->cvVelumThick_0) > 0.0f)
    {
        float ext_0 = 1.89999997615814209f * _S113;
        float bottom_1 = c_12->cvVelumHeight_0 - 0.5f * _S119;
        float top_2 = c_12->cvVelumHeight_0 + _S119;
        if(gap2_0 < (ext_0 * ext_0))
        {
            _S115 = high_0 >= bottom_1;
        }
        else
        {
            _S115 = false;
        }
        if(_S115)
        {
            _S115 = low_0 <= top_2;
        }
        else
        {
            _S115 = false;
        }
        if(_S115)
        {
            best_0 = (F32_max((best_0), (0.2199999988079071f)));
        }
    }
    return c_12->cvSigma_0 * best_0 * 1.00001001358032227f;
}

static __device__ float convLift_0(ConvectionInput_0 * c_13, float above_0, float k_1)
{
    return (F32_min((c_13->cvBillow_0 * k_1 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_0(0.60000002384185791f, 1.0f, saturate_0(above_0 / (F32_max((c_13->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_0), (0.0f))))));
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
    Organization_0 _S120 = flat_0;
    float2  _S121 = orgPattern_0(&_S120, q0_0, spacing_2);
    Organization_0 _S122 = flat_0;
    float2  _S123 = orgPattern_0(&_S122, q1_0, spacing_2);
    float2  _S124 = make_float2 (q0_0.x, q1_0.y);
    Organization_0 _S125 = flat_0;
    float2  _S126 = orgPattern_0(&_S125, _S124, spacing_2);
    float2  _S127 = make_float2 (q1_0.x, q0_0.y);
    Organization_0 _S128 = flat_0;
    float2  _S129 = orgPattern_0(&_S128, _S127, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S121.x)))), ((F32_abs((_S121.y))))))), ((F32_max(((F32_abs((_S123.x)))), ((F32_abs((_S123.y)))))))));
    *a_1 = min_1(min_1(_S121, _S126), min_1(_S129, _S123)) - make_float2 (grow_0);
    *b_0 = max_1(max_1(_S121, _S126), max_1(_S129, _S123)) + make_float2 (grow_0);
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_14, int2  slot_6, float2  a_2, float2  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S130 = convVigour_0(c_14, slot_6);
    if(_S130 <= 0.0f)
    {
        return;
    }
    float2  _S131 = convCellCentre_0(c_14, slot_6);
    float2  _S132 = a_2 - _S131;
    float2  nearGap_1 = max_1(max_1(_S132, _S131 - b_1), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_1, nearGap_1);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_1(abs_0(_S132), abs_0(b_1 - _S131));
    float oHi_0 = _S130 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S130 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S130 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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
    float2  _S133 = floor_1((a_3 + b_2) * make_float2 (0.5f));
    int2  _S134 = make_int2 ((int)_S133.x, (int)_S133.y);
    float2  _S135 = make_float2 ((float)_S134.x, (float)_S134.y);
    float2  highEdge_0 = _S135 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S136;
    if(all_0(a_3 >= (_S135 - make_float2 (0.00009999999747379f))))
    {
        _S136 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S136 = false;
    }
    int j_7;
    int i_12;
    if(_S136)
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
            i_12 = int(-1);
            for(;;)
            {
                if(i_12 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, _S134 + make_int2 (i_12, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_12 = i_12 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        float2  _S137 = floor_1(a_3);
        int2  _S138 = make_int2 ((int)_S137.x, (int)_S137.y);
        int2  _S139 = make_int2 (int(1), int(1));
        int2  i0_0 = _S138 - _S139;
        float2  _S140 = floor_1(b_2);
        int2  _S141 = make_int2 ((int)_S140.x, (int)_S140.y);
        int2  _S142 = _S141 + _S139;
        int _S143 = i0_0.y;
        j_7 = _S143;
        for(;;)
        {
            if(j_7 <= (_S142.y))
            {
                _S136 = j_7 <= (_S143 + int(32));
            }
            else
            {
                _S136 = false;
            }
            if(_S136)
            {
            }
            else
            {
                break;
            }
            int _S144 = i0_0.x;
            i_12 = _S144;
            for(;;)
            {
                bool _S145;
                if(i_12 <= (_S142.x))
                {
                    _S145 = i_12 <= (_S144 + int(32));
                }
                else
                {
                    _S145 = false;
                }
                if(_S145)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, make_int2 (i_12, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_12 = i_12 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_0((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_15->cvPolarity_0);
    float _S146 = c_15->cvLacunarity_0;
    float field_2;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_0(field_1, 0.40000000596046448f, _S146);
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
    bool _S147;
    if(cover_1 <= 0.0f)
    {
        _S147 = true;
    }
    else
    {
        _S147 = (c_17->cvDepth_0) <= 0.0f;
    }
    if(_S147)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_17->cvDepth_0), (1.0f / (F32_max((c_17->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_18)
{
    float _S148 = c_18->cvSpacing_0;
    float cap_1 = 7.0f / c_18->cvSpacing_0;
    if(((&c_18->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_1;
    }
    float _S149 = c_18->cvLacunarity_0;
    float cap_2;
    if((c_18->cvLacunarity_0) > 0.0f)
    {
        cap_2 = cap_1 + 1.5f / (0.15000000596046448f * _S149 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S148);
    }
    else
    {
        cap_2 = cap_1;
    }
    float _S150 = c_18->cvGapWidth_0;
    if((c_18->cvGapWidth_0) > 0.0f)
    {
        cap_2 = cap_2 + 14.25f * c_18->cvPolarity_0 / (0.5f * _S150 * _S148);
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
            float4  _S151 = convTurret_0(c_20, k_3);
            t_4 = _S151;
        }
        float4  _S152 = t_4;
        float2  _S153 = float2 {_S152.x, _S152.y};
        float2  gap_0 = max_1(max_1(lo_3 - _S153, _S153 - hi_3), make_float2 (0.0f, 0.0f));
        float _S154 = t_4.z;
        float outer_0 = 1.29999995231628418f * _S154;
        float band_1 = outer_0 - 0.75f * _S154;
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
    bool _S155;
    if(vMin_0 <= 0.0f)
    {
        _S155 = true;
    }
    else
    {
        _S155 = hMin_0 <= 0.0f;
    }
    if(_S155)
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
    return length_1(make_float2 (c_22->cvShapeHalfWidth_0 + lift_0, c_22->cvShapeRound_0 + lift_0));
}

static __device__ float convHeroReachAll_0(ConvectionInput_0 * c_23)
{
    float _S156 = convHeroReach_0(c_23);
    float _S157;
    if((c_23->cvShapeOn_0) != int(0))
    {
        float _S158 = convShapeReach_0(c_23);
        _S157 = (F32_max((_S156), (_S158)));
    }
    else
    {
        _S157 = _S156;
    }
    return _S157;
}

static __device__ float convDomeRadiusAt_0(float top_3, float radius_1, float shape_1, float above_2)
{
    bool _S159;
    if(top_3 <= 0.0f)
    {
        _S159 = true;
    }
    else
    {
        _S159 = above_2 >= top_3;
    }
    if(_S159)
    {
        return -1.0f;
    }
    return radius_1 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / top_3), (1.0f / (F32_max((shape_1), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_24, float above_3)
{
    return convDomeRadiusAt_0(c_24->cvHeroTop_0, c_24->cvHeroRadius_0, c_24->cvShape_0, above_3);
}

static __device__ float3  convShapeTexel_0(ConvectionInput_0 * c_25, int i_13, int j_8)
{
    int k_4 = (j_8 * c_25->cvShapeDim_0.x + i_13) * int(4);
    StructuredBuffer<float> _S160 = c_25->cvShapeMap_0;
    float _S161 = __ldg((&(c_25->cvShapeMap_0)[k_4]));
    float _S162 = __ldg((&(_S160)[k_4 + int(1)]));
    float _S163 = __ldg((&(_S160)[k_4 + int(2)]));
    return make_float3 (_S161, _S162, _S163);
}

static __device__ float convShapeDistance_0(ConvectionInput_0 * c_26, float u_3, float y_9, float2  * slopeUY_0)
{
    float _S164 = c_26->cvShapeTexel_0;
    float2  st_0 = make_float2 (u_3, y_9) / make_float2 (c_26->cvShapeTexel_0) + c_26->cvShapeOffset_0 - make_float2 (0.5f);
    int2  _S165 = make_int2 (int(1), int(1));
    int2  last_0 = c_26->cvShapeDim_0 - _S165;
    float2  _S166 = make_float2 ((float)last_0.x, (float)last_0.y);
    float2  q_6 = clamp_2(st_0, make_float2 (0.0f, 0.0f), _S166);
    float past_0 = length_1(st_0 - q_6);
    float2  f0_0 = floor_1(q_6);
    int2  _S167 = make_int2 ((int)f0_0.x, (int)f0_0.y);
    int2  i0_1 = min_0(_S167, last_0);
    int2  i1_0 = min_0(i0_1 + _S165, last_0);
    float2  fr_0 = q_6 - f0_0;
    int _S168 = i0_1.x;
    int _S169 = i0_1.y;
    float3  _S170 = convShapeTexel_0(c_26, _S168, _S169);
    int _S171 = i1_0.x;
    float3  _S172 = convShapeTexel_0(c_26, _S171, _S169);
    int _S173 = i1_0.y;
    float3  _S174 = convShapeTexel_0(c_26, _S168, _S173);
    float3  _S175 = convShapeTexel_0(c_26, _S171, _S173);
    float3  _S176 = make_float3 (fr_0.x);
    float3  blend_0 = lerp_2(lerp_2(_S170, _S172, _S176), lerp_2(_S174, _S175, _S176), make_float3 (fr_0.y));
    *slopeUY_0 = float2 {blend_0.y, blend_0.z};
    return (blend_0.x - past_0) * _S164;
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
    float2  _S177;
    if(len_0 > 9.99999997475242708e-07f)
    {
        _S177 = w_2 * make_float2 (- gap_1 / len_0);
    }
    else
    {
        _S177 = make_float2 (0.0f, rimR_0);
    }
    *stepDM_0 = _S177;
    return gap_1;
}

static __device__ float convShapeBound_0(ConvectionInput_0 * c_27, float3  lo_4, float3  hi_4, float low_1, float high_1)
{
    float2  ea_0 = float2 {lo_4.x, lo_4.z} - c_27->cvHeroAt_0;
    float2  eb_0 = float2 {hi_4.x, hi_4.z} - c_27->cvHeroAt_0;
    float _S178 = c_27->cvShapeAxisU_0.y;
    float _S179 = - _S178;
    float _S180 = c_27->cvShapeAxisU_0.x;
    float _S181 = ea_0.x;
    float _S182 = _S181 * _S180;
    float _S183 = eb_0.x;
    float _S184 = _S183 * _S180;
    float _S185 = ea_0.y;
    float _S186 = _S185 * _S178;
    float _S187 = eb_0.y;
    float _S188 = _S187 * _S178;
    float uLo_0 = (F32_min((_S182), (_S184))) + (F32_min((_S186), (_S188)));
    float uHi_0 = (F32_max((_S182), (_S184))) + (F32_max((_S186), (_S188)));
    float _S189 = _S181 * _S179;
    float _S190 = _S183 * _S179;
    float _S191 = _S185 * _S180;
    float _S192 = _S187 * _S180;
    float nLo_0 = (F32_min((_S189), (_S190))) + (F32_min((_S191), (_S192)));
    float nHi_0 = (F32_max((_S189), (_S190))) + (F32_max((_S191), (_S192)));
    bool _S193;
    if(nLo_0 <= 0.0f)
    {
        _S193 = nHi_0 >= 0.0f;
    }
    else
    {
        _S193 = false;
    }
    float mMin_0;
    if(_S193)
    {
        mMin_0 = 0.0f;
    }
    else
    {
        mMin_0 = (F32_min(((F32_abs((nLo_0)))), ((F32_abs((nHi_0))))));
    }
    float2  halfSpan_0 = make_float2 (0.5f * (uHi_0 - uLo_0), 0.5f * (high_1 - low_1));
    float2  slopeUnused_0;
    float _S194 = convShapeDistance_0(c_27, 0.5f * (uLo_0 + uHi_0), 0.5f * (low_1 + high_1), &slopeUnused_0);
    float2  stepUnused_0;
    return - convShapeProfile_0(_S194 + 2.5f * length_1(halfSpan_0), mMin_0, c_27->cvShapeRound_0, &stepUnused_0);
}

static __device__ float convTurretReach_0(ConvectionInput_0 * c_28, float4  t_5)
{
    return t_5.z + 1.5f * c_28->cvBillow_0 * c_28->cvHeroBillow_0 + 24.0f;
}

static __device__ float convTurretBillow_0(ConvectionInput_0 * c_29, float radius_2)
{
    return lerp_0((F32_min((1.0f), (c_29->cvHeroBillow_0))), c_29->cvHeroBillow_0, saturate_0(radius_2 / (F32_max((c_29->cvHeroRadius_0), (1.0f)))));
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
                float _S225 = lerp_0(_S224, edge_0, c_31->cvShapeDecay_0);
                float _S226 = convLift_0(c_31, _S206, _S221 * lerp_0(c_31->cvShapeBillow_0, 1.0f, c_31->cvShapeDecay_0));
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
    float x_22 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_14 = clamp_1(int((F32_floor((x_22)))), int(0), int(31));
    float2  _S230 = __ldg((&(disp_0)[i_14]));
    float2  _S231 = __ldg((&(disp_0)[i_14 + int(1)]));
    return lerp_1(_S230, _S231, make_float2 (x_22 - float(i_14)));
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
        int i_15 = _S248;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S249;
            if(i_15 <= (_S245.x))
            {
                _S249 = i_15 <= (_S248 + int(32));
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
            int2  o_7 = make_int2 (i_15, j_9);
            if((hash22_0(o_7, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_15 = i_15 + int(1);
                continue;
            }
            float2  _S250 = make_float2 ((float)o_7.x, (float)o_7.y);
            float2  c_32 = _S250 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S239;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(max_1(max_1(a_4 - c_32, c_32 - b_3), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_15 = i_15 + int(1);
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

static __device__ bool segmentStep_0(Medium_0 * m_4, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > drift_0, float scale_0, float tEnd_0, Dda_0 * dda_0, float * rate_0, float * t_7, Rng_0 * rng_0, float * uKeep_0, float * uLive_0, int * budget_0, int * steps_0)
{
    *uKeep_0 = 0.0f;
    *uLive_0 = 0.0f;
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
        float _S271 = *t_7 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / *rate_0;
        *t_7 = _S271;
        if(_S271 >= _S267)
        {
            if(_S267 >= tEnd_0)
            {
                return false;
            }
            *t_7 = _S267;
            ddaAdvance_0(dda_0);
            float _S272 = gridBound_0(m_4, g_9, bounds_1, drift_0, dda_0->cell_0, m_4->majorant_0);
            *rate_0 = _S272 * scale_0;
            continue;
        }
        return true;
    }
    return false;
}

static __device__ MajorantGrid_0 gridFor_0(Medium_0 * m_5, MajorantGrid_0 * g_10, float3  p_2)
{
    MajorantGrid_0 chosen_0 = *g_10;
    bool _S273;
    if((g_10->enabled_0) == int(2))
    {
        _S273 = (p_2.y) >= (m_5->slabBottom_0);
    }
    else
    {
        _S273 = false;
    }
    if(_S273)
    {
        _S273 = (p_2.y) <= (m_5->slabTop_0);
    }
    else
    {
        _S273 = false;
    }
    if(_S273)
    {
        (&chosen_0)->enabled_0 = int(0);
    }
    return chosen_0;
}

static __device__ float orgWaveFactor_0(Organization_0 * o_8, float2  q_7)
{
    float2  unused_0;
    float _S274 = orgWave_0(o_8, q_7, &unused_0);
    return _S274;
}

static __device__ float cellField_0(GeneratorInput_0 * g_11, float2  q_8)
{
    float2  _S275 = q_8 - g_11->cellDrift_0;
    float2  _S276 = orgPattern_0(&g_11->gnOrg_0, _S275, g_11->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(_S276);
    int2  _S277 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    float2  _S278 = orgJitter_0(&g_11->gnOrg_0, 0.80000001192092896f);
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
        int i_16 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_16 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_9 = _S277 + make_int2 (i_16, j_10);
            if((hash22_0(o_9, 2654435769U).x) > (g_11->cellDensity_0))
            {
                i_16 = i_16 + int(1);
                continue;
            }
            float2  _S279 = make_float2 ((float)o_9.x, (float)o_9.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(_S276 - (_S279 + make_float2 (0.5f) + (hash22_0(o_9, 0U) - make_float2 (0.5f)) * _S278)) * 2.20000004768371582f);
            i_16 = i_16 + int(1);
        }
        j_10 = j_10 + int(1);
        acc_2 = acc_3;
    }
    float _S280 = acc_2 * g_11->cellStrength_0;
    float _S281 = orgWaveFactor_0(&g_11->gnOrg_0, _S275);
    return _S280 * _S281;
}

static __device__ float fbm_0(float3  p_3, int octaves_1)
{
    int i_17 = int(0);
    float amp_0 = 0.5f;
    float3  _S282 = p_3;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_17 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_17 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S282);
        float norm_1 = norm_0 + amp_0;
        float3  _S283 = _S282 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_17 = i_17 + int(1);
        amp_0 = amp_1;
        _S282 = _S283;
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
    bool _S284;
    if(depth_1 < 0.0f)
    {
        _S284 = true;
    }
    else
    {
        _S284 = depth_1 > (g_12->streakLength_0);
    }
    if(_S284)
    {
        return 0.0f;
    }
    float2  _S285 = float2 {p_4.x, p_4.z};
    float2  _S286 = driftAt_0(g_12, disp_5, depth_1);
    float2  source_0 = _S285 - _S286;
    float _S287 = cellField_0(g_12, source_0);
    if(_S287 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S287 * (F32_exp((- g_12->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_12->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_12->streakLength_0, g_12->streakLength_0, depth_1)) * (F32_max((1.0f + g_12->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_12->detailScale_0)).x, (source_0 / make_float2 (g_12->detailScale_0)).y, depth_1 / (F32_max((g_12->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_12->timeSeconds_0 * 0.00999999977648258f), g_12->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_12->opticalDepth_0 / (F32_max((g_12->streakLength_0), (1.0f)));
}

static __device__ float convPouches_0(ConvectionInput_0 * c_34, float2  q_9)
{
    float2  g_13 = q_9 / make_float2 (c_34->cvPouchSize_0);
    float2  _S288 = floor_1(g_13);
    int2  _S289 = make_int2 ((int)_S288.x, (int)_S288.y);
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
        int i_18 = int(-1);
        for(;;)
        {
            if(i_18 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_7 = _S289 + make_int2 (i_18, j_11);
            float2  _S290 = make_float2 ((float)slot_7.x, (float)slot_7.y);
            float2  d_8 = g_13 - (_S290 + make_float2 (0.5f) + (hash22_0(slot_7, 739982445U) - make_float2 (0.5f)) * make_float2 (0.60000002384185791f));
            float t2_0 = dot_1(d_8, d_8) / 0.46240001916885376f;
            if(t2_0 >= 1.0f)
            {
                i_18 = i_18 + int(1);
                continue;
            }
            float2  h_3 = hash22_0(slot_7, 2135587861U);
            deepest_1 = (F32_max((deepest_1), (lerp_0(0.30000001192092896f, 1.0f, convLife_0((F32_frac((2.0f * c_34->cvAge_0 + h_3.x))))) * lerp_0(0.60000002384185791f, 1.0f, h_3.y) * (F32_sqrt((1.0f - t2_0))))));
            i_18 = i_18 + int(1);
        }
        int j_12 = j_11 + int(1);
        deepest_0 = deepest_1;
        j_11 = j_12;
    }
    return deepest_0;
}

static __device__ void convMoatRing_0(float2  xz_0, float2  at_0, float radius_3, float * s_9, float2  * gs_0, float * slope_1)
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
    if(f_1 < (*s_9))
    {
        *s_9 = f_1;
        float2  _S291;
        if(r_6 > 0.00100000004749745f)
        {
            _S291 = d_9 * make_float2 (6.0f * t_8 * (1.0f - t_8) / (band_2 * r_6));
        }
        else
        {
            _S291 = make_float2 (0.0f, 0.0f);
        }
        *gs_0 = _S291;
    }
    return;
}

static __device__ float convMoat_0(ConvectionInput_0 * c_35, float2  xz_1, float2  * grad_5, float * slopeAdd_0)
{
    float s_10 = 1.0f;
    float2  gs_1 = make_float2 (0.0f, 0.0f);
    float slope_2 = 0.0f;
    convMoatRing_0(xz_1, c_35->cvHeroAt_0, c_35->cvHeroRadius_0, &s_10, &gs_1, &slope_2);
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
        float4  _S292 = convTurret_0(c_35, k_7);
        convMoatRing_0(xz_1, float2 {_S292.x, _S292.y}, _S292.z, &s_10, &gs_1, &slope_2);
        k_7 = k_7 + int(1);
    }
    float _S293 = c_35->cvMoat_0;
    *grad_5 = gs_1 * make_float2 (c_35->cvMoat_0);
    *slopeAdd_0 = slope_2 * _S293;
    return 1.0f - _S293 * (1.0f - s_10);
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_36, float2  q_10, float2  * grad_6)
{
    if(((&c_36->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S294 = convUpdraftGradT_2(c_36, q_10, grad_6);
        return _S294;
    }
    if((c_36->cvLacunarity_0) <= 0.0f)
    {
        float _S295 = convUpdraftGradT_1(c_36, q_10, grad_6);
        return _S295;
    }
    float _S296 = convUpdraftGradT_0(c_36, q_10, grad_6);
    return _S296;
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
    float _S297;
    if(v_2 >= 0.0f)
    {
        _S297 = d_10;
    }
    else
    {
        _S297 = - d_10;
    }
    return _S297;
}

static __device__ float convFieldBaseInside_0(ConvectionInput_0 * c_37, float w_3, float2  slope_4, float cap_3)
{
    float _S298 = convTowerHeight_0(c_37, w_3);
    float v_3 = _S298 - 1.0f;
    float _S299 = convNeededUpdraft_0(c_37, 1.0f);
    return convSurfaceDistance_0(v_3, w_3 - _S299, (F32_min((length_1(slope_4)), (cap_3))));
}

static __device__ float convDomeSurface_0(float top_4, float radius_4, float shape_2, float2  rel_0, float r_7, float py_0, float above_4, float3  * x_23)
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
        float _S300 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S300;
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
    *x_23 = make_float3 (at_1.x, py_0 + shiftUp_0, at_1.y);
    return d_11;
}

static __device__ float convTowerSurface_0(ConvectionInput_0 * c_38, float2  rel_1, float r_8, float py_1, float above_5, float3  * x_24)
{
    float _S301 = convDomeSurface_0(c_38->cvHeroTop_0, c_38->cvHeroRadius_0, c_38->cvShape_0, rel_1, r_8, py_1, above_5, x_24);
    return _S301;
}

static __device__ float convShapeSurface_0(ConvectionInput_0 * c_39, float2  plane_0, float py_2, float above_6, float3  * x_25)
{
    float _S302 = plane_0.x;
    float2  slopeUY_1;
    float _S303 = convShapeDistance_0(c_39, _S302, above_6, &slopeUY_1);
    float _S304 = plane_0.y;
    float2  stepDM_1;
    float gap_2 = convShapeProfile_0(_S303, (F32_abs((_S304))), c_39->cvShapeRound_0, &stepDM_1);
    float side_0;
    if(_S304 >= 0.0f)
    {
        side_0 = 1.0f;
    }
    else
    {
        side_0 = -1.0f;
    }
    *x_25 = make_float3 (_S302 + stepDM_1.x * slopeUY_1.x, py_2 + stepDM_1.x * slopeUY_1.y, _S304 + side_0 * stepDM_1.y);
    return - gap_2;
}

static __device__ bool convHeroSmooth_0(ConvectionInput_0 * c_40, float3  p_5, float above_7, float * d_13, float3  * x_26, float * amount_0, float * lobe_0)
{
    *d_13 = -1.00000001504746622e+30f;
    *x_26 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S305 = c_40->cvHeroBillow_0;
    *amount_0 = c_40->cvHeroBillow_0;
    *lobe_0 = _S305;
    float2  rel_2 = float2 {p_5.x, p_5.z} - c_40->cvHeroAt_0;
    float r_9 = length_1(rel_2);
    float _S306 = convHeroReachAll_0(c_40);
    if(r_9 >= _S306)
    {
        return false;
    }
    if((c_40->cvShapeOn_0) == int(0))
    {
        float _S307 = convTowerSurface_0(c_40, rel_2, r_9, p_5.y, above_7, x_26);
        *d_13 = _S307;
    }
    else
    {
        float2  plane_1 = make_float2 (dot_1(rel_2, c_40->cvShapeAxisU_0), dot_1(rel_2, make_float2 (- c_40->cvShapeAxisU_0.y, c_40->cvShapeAxisU_0.x)));
        float _S308 = c_40->cvShapeDecay_0;
        if((c_40->cvShapeDecay_0) >= 1.0f)
        {
            float _S309 = convTowerSurface_0(c_40, plane_1, r_9, p_5.y, above_7, x_26);
            *d_13 = _S309;
        }
        else
        {
            float _S310 = p_5.y;
            float3  xs_0;
            float _S311 = convShapeSurface_0(c_40, plane_1, _S310, above_7, &xs_0);
            if(_S308 > 0.0f)
            {
                float3  xt_0;
                float _S312 = convTowerSurface_0(c_40, plane_1, r_9, _S310, above_7, &xt_0);
                *d_13 = lerp_0(_S311, _S312, _S308);
                *x_26 = lerp_2(xs_0, xt_0, make_float3 (_S308));
            }
            else
            {
                *d_13 = _S311;
                *x_26 = xs_0;
            }
            float _S313 = c_40->cvShapeBillow_0;
            *amount_0 = _S305 * lerp_0(c_40->cvShapeBillow_0, 1.0f, _S308);
            *lobe_0 = _S305 * lerp_0((F32_max((_S313), (0.30000001192092896f))), 1.0f, _S308);
        }
    }
    return true;
}

static __device__ bool convTurretSmooth_0(ConvectionInput_0 * c_41, float4  t_9, float3  p_6, float above_8, float * d_14, float3  * x_27, float * k_8)
{
    *d_14 = -1.00000001504746622e+30f;
    *x_27 = make_float3 (0.0f, 0.0f, 0.0f);
    *k_8 = 1.0f;
    float2  rel_3 = float2 {p_6.x, p_6.z} - float2 {t_9.x, t_9.y};
    float r2_2 = dot_1(rel_3, rel_3);
    float _S314 = convTurretReach_0(c_41, t_9);
    if(r2_2 >= (_S314 * _S314))
    {
        return false;
    }
    float _S315 = t_9.w;
    if(above_8 >= (_S315 + c_41->cvBillow_0 * c_41->cvHeroBillow_0))
    {
        return false;
    }
    float r_10 = (F32_sqrt((r2_2)));
    float _S316 = t_9.z;
    float _S317 = convTurretBillow_0(c_41, _S316);
    *k_8 = _S317;
    float3  own_0;
    float _S318 = convDomeSurface_0(_S315, _S316, c_41->cvShape_0, rel_3, r_10, p_6.y, above_8, &own_0);
    *d_14 = _S318;
    float3  w_4 = own_0 + make_float3 (t_9.x - c_41->cvHeroAt_0.x, 0.0f, t_9.y - c_41->cvHeroAt_0.y);
    float3  w_5;
    if((c_41->cvShapeOn_0) != int(0))
    {
        float2  _S319 = float2 {w_4.x, w_4.z};
        w_5 = make_float3 (dot_1(_S319, c_41->cvShapeAxisU_0), w_4.y, dot_1(_S319, make_float2 (- c_41->cvShapeAxisU_0.y, c_41->cvShapeAxisU_0.x)));
    }
    else
    {
        w_5 = w_4;
    }
    *x_27 = w_5;
    return true;
}

static __device__ float convGroupBaseInside_0(ConvectionInput_0 * c_42, float2  xz_2, bool nearGroup_0)
{
    float best_1;
    if((c_42->cvHeroTop_0) > 0.0f)
    {
        float3  p_7 = make_float3 (xz_2.x, c_42->cvBase_0 + 1.0f, xz_2.y);
        float d_15;
        float amount_1;
        float lobe_1;
        float3  x_28;
        bool _S320 = convHeroSmooth_0(c_42, p_7, 1.0f, &d_15, &x_28, &amount_1, &lobe_1);
        if(_S320)
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
            bool _S321;
            if(!nearGroup_0)
            {
                _S321 = true;
            }
            else
            {
                _S321 = k_9 >= (c_42->cvTurretCount_0);
            }
            if(_S321)
            {
                break;
            }
            float4  _S322 = convTurret_0(c_42, k_9);
            float kt_0;
            bool _S323 = convTurretSmooth_0(c_42, _S322, p_7, 1.0f, &d_15, &x_28, &kt_0);
            if(_S323)
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

static __device__ float convBaseInside_0(ConvectionInput_0 * c_43, float2  xz_3, bool nearGroup_1)
{
    float best_2;
    if((c_43->cvHeroAlone_0) == int(0))
    {
        float capMoat_0 = 0.0f;
        float2  gMoat_0 = make_float2 (0.0f, 0.0f);
        bool moated_0;
        if((c_43->cvMoat_0) > 0.0f)
        {
            moated_0 = nearGroup_1;
        }
        else
        {
            moated_0 = false;
        }
        float m_6;
        if(moated_0)
        {
            float _S324 = convMoat_0(c_43, xz_3, &gMoat_0, &capMoat_0);
            m_6 = _S324;
        }
        else
        {
            m_6 = 1.0f;
        }
        if(m_6 > 0.0f)
        {
            float2  slope_5;
            float _S325 = convUpdraftGrad_0(c_43, xz_3 - c_43->cvDrift_0, &slope_5);
            float _S326 = convSlopeCap_0(c_43);
            float cap_4;
            if(moated_0)
            {
                slope_5 = slope_5 * make_float2 (m_6) + gMoat_0 * make_float2 (_S325);
                float cap_5 = _S326 + capMoat_0;
                best_2 = _S325 * m_6;
                cap_4 = cap_5;
            }
            else
            {
                best_2 = _S325;
                cap_4 = _S326;
            }
            float _S327 = convFieldBaseInside_0(c_43, best_2, slope_5, cap_4);
            best_2 = _S327;
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
    float _S328 = convGroupBaseInside_0(c_43, xz_3, nearGroup_1);
    return (F32_max((best_2), (_S328)));
}

static __device__ float convMammaSagOf_0(ConvectionInput_0 * c_44, float pouch_0, float inside_2)
{
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_44->cvMammaDepth_0 * pouch_0 * smoothstep_0(0.0f, 0.60000002384185791f * c_44->cvPouchSize_0, inside_2);
}

static __device__ float convMammaSag_0(ConvectionInput_0 * c_45, float2  xz_4, bool nearGroup_2, float below_0)
{
    float _S329 = convPouches_0(c_45, xz_4 - c_45->cvDrift_0);
    if((c_45->cvMammaDepth_0 * _S329) <= below_0)
    {
        return 0.0f;
    }
    float _S330 = convBaseInside_0(c_45, xz_4, nearGroup_2);
    float _S331 = convMammaSagOf_0(c_45, _S329, _S330);
    return _S331;
}

static __device__ float3  convTwist_0(float3  x_29)
{
    float _S332 = x_29.x;
    float _S333 = x_29.y;
    float _S334 = x_29.z;
    return make_float3 (0.0f * _S332 + 0.80000001192092896f * _S333 + 0.60000002384185791f * _S334, -0.80000001192092896f * _S332 + 0.36000001430511475f * _S333 - 0.47999998927116394f * _S334, -0.60000002384185791f * _S332 - 0.47999998927116394f * _S333 + 0.63999998569488525f * _S334);
}

static __device__ float convPuffs_0(float3  x_30)
{
    float3  fl_0 = floor_0(x_30);
    int3  _S335 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_2 = x_30 - fl_0;
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
    int3  _S336 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S336 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S337 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_16 = _S337 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S335 + off_0) - f_2;
                float _S338 = (F32_min((nearest_1), (dot_0(d_16, d_16))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S338;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_46, float3  p_8, float scale_1)
{
    float3  _S339 = make_float3 (p_8.x, p_8.y - c_46->cvRise_0, p_8.z) / make_float3 (scale_1);
    int i_19 = int(0);
    float3  x_31 = _S339;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_19 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_19 >= (c_46->cvOctaves_0))
        {
            break;
        }
        float3  x_32 = convTwist_0(x_31);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_32);
        float norm_3 = norm_2 + amp_2;
        float3  x_33 = x_32 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_19 = i_19 + int(1);
        x_31 = x_33;
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

static __device__ float convInside_0(ConvectionInput_0 * c_47, float d_17, float lift_2, float3  x_34, float scale_2)
{
    float _S340 = d_17 + lift_2;
    if(_S340 <= 0.0f)
    {
        return _S340;
    }
    if((d_17 - lift_2) >= 12.0f)
    {
        return 12.0f;
    }
    float _S341 = convBillow_0(c_47, x_34, scale_2);
    return d_17 + lift_2 * _S341;
}

static __device__ float convCapGrain_0(ConvectionInput_0 * c_48, float2  rel_4, float scale_3)
{
    return saturate_0(0.80000001192092896f + 0.13330000638961792f * gradientNoise_0(make_float3 (rel_4.x / scale_3 + c_48->cvHeroSeed_0.x * 0.00100000004749745f, 0.37000000476837158f, rel_4.y / scale_3 + c_48->cvHeroSeed_0.z * 0.00100000004749745f)));
}

static __device__ float convCapDensity_0(ConvectionInput_0 * c_49, float3  p_9, float above_9)
{
    float2  rel_5 = float2 {p_9.x, p_9.z} - c_49->cvHeroAt_0;
    float r2_3 = dot_1(rel_5, rel_5);
    float _S342 = c_49->cvHeroRadius_0;
    float _S343 = c_49->cvPileusThick_0;
    float best_3;
    if((c_49->cvPileusThick_0) > 0.0f)
    {
        float rp_1 = 0.60000002384185791f * _S342;
        float _S344 = rp_1 * rp_1;
        if(r2_3 < _S344)
        {
            float lens_0 = 1.0f - r2_3 / _S344;
            float _S345 = c_49->cvPileusGap_0;
            float _S346 = convHeroHeight_0(c_49, (F32_sqrt((r2_3))) * 0.60000002384185791f);
            float most_0 = 0.5f * _S343 * lens_0;
            float _S347 = (F32_abs((above_9 - (_S345 + _S346))));
            if(_S347 < most_0)
            {
                float _S348 = convCapGrain_0(c_49, rel_5, 900.0f);
                float s_11 = most_0 * _S348 - _S347;
                if(s_11 > 0.0f)
                {
                    best_3 = (F32_max((0.0f), (0.44999998807907104f * smoothstep_0(0.0f, 15.0f, s_11))));
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
    float _S349 = c_49->cvVelumThick_0;
    if((c_49->cvVelumThick_0) > 0.0f)
    {
        float ext_1 = 1.89999997615814209f * _S342;
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
            float edge_1 = _S342 + (ext_1 - _S342) * saturate_0(0.875f + 0.08330000191926956f * gradientNoise_0(make_float3 (1.70000004768371582f * dir_0.x + c_49->cvHeroSeed_0.x * 0.00100000004749745f, 2.29999995231628418f, 1.70000004768371582f * dir_0.y + c_49->cvHeroSeed_0.z * 0.00100000004749745f)));
            float _S350 = 0.5f * _S349;
            float most_1 = _S350 * (1.0f - smoothstep_0(_S342 + 0.40000000596046448f * (edge_1 - _S342), edge_1, r_11));
            float _S351 = (F32_abs((above_9 - (c_49->cvVelumHeight_0 + _S350 * (1.0f - smoothstep_0(_S342, 2.0f * _S342, r_11))))));
            if(_S351 < most_1)
            {
                float _S352 = convCapGrain_0(c_49, rel_5, 2500.0f);
                float s_12 = most_1 * _S352 - _S351;
                if(s_12 > 0.0f)
                {
                    best_3 = (F32_max((best_3), (0.2199999988079071f * smoothstep_0(0.0f, 15.0f, s_12))));
                }
            }
        }
    }
    return c_49->cvSigma_0 * best_3;
}

static __device__ void convGroupFold_0(float d_18, float3  x_35, float lift_3, float lobe_2, float * gMax_0, float * gSum_0, float3  * gX_0, float * gLift_0, float * gLobe_0)
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
    *gX_0 = *gX_0 + make_float3 (wt_0) * x_35;
    *gLift_0 = *gLift_0 + wt_0 * lift_3;
    *gLobe_0 = *gLobe_0 + wt_0 * lobe_2;
    return;
}

static __device__ float convGroupInside_0(ConvectionInput_0 * c_50, float3  p_10, float above_10, bool nearGroup_3)
{
    bool _S353;
    float gMax_1 = -1.00000001504746622e+30f;
    float gSum_1 = 0.0f;
    float gLift_1 = 0.0f;
    float gLobe_1 = 0.0f;
    float3  gX_1 = make_float3 (0.0f, 0.0f, 0.0f);
    float d_19;
    float amount_2;
    float lobe_3;
    float3  x_36;
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
            _S353 = true;
        }
        else
        {
            _S353 = k_10 >= (c_50->cvTurretCount_0);
        }
        if(_S353)
        {
            break;
        }
        float4  _S354 = convTurret_0(c_50, k_10);
        float kt_1;
        bool _S355 = convTurretSmooth_0(c_50, _S354, p_10, above_10, &d_19, &x_36, &kt_1);
        if(_S355)
        {
            float _S356 = convLift_0(c_50, above_10, kt_1);
            convGroupFold_0(d_19, x_36, _S356, kt_1, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
            anyTurret_0 = true;
        }
        k_10 = k_10 + int(1);
    }
    bool _S357 = convHeroSmooth_0(c_50, p_10, above_10, &d_19, &x_36, &amount_2, &lobe_3);
    float heroLift_0;
    if(_S357)
    {
        float _S358 = convLift_0(c_50, above_10, amount_2);
        heroLift_0 = _S358;
    }
    else
    {
        heroLift_0 = 0.0f;
    }
    if(!_S357)
    {
        _S353 = !anyTurret_0;
    }
    else
    {
        _S353 = false;
    }
    if(_S353)
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
        at_2 = x_36;
        lobeAt_0 = lobe_3;
    }
    else
    {
        if(_S357)
        {
            convGroupFold_0(d_19, x_36, heroLift_0, lobe_3, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
        }
        float3  _S359 = gX_1 / make_float3 (gSum_1);
        float _S360 = gLobe_1 / gSum_1;
        lift_4 = gLift_1 / gSum_1;
        at_2 = _S359;
        lobeAt_0 = _S360;
    }
    float _S361 = convInside_0(c_50, gMax_1, lift_4, at_2 + c_50->cvHeroSeed_0, c_50->cvBillowScale_0 * lobeAt_0);
    return _S361;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_51, float3  p_11, float above_11)
{
    float d_20;
    float amount_3;
    float lobe_4;
    float3  x_37;
    bool _S362 = convHeroSmooth_0(c_51, p_11, above_11, &d_20, &x_37, &amount_3, &lobe_4);
    if(!_S362)
    {
        return -1.00000001504746622e+30f;
    }
    float _S363 = convLift_0(c_51, above_11, amount_3);
    float _S364 = convInside_0(c_51, d_20, _S363, x_37 + c_51->cvHeroSeed_0, c_51->cvBillowScale_0 * lobe_4);
    return _S364;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_52, float3  p_12)
{
    float _S365 = p_12.y;
    float above_12 = _S365 - c_52->cvBase_0;
    float _S366 = c_52->cvMammaDepth_0;
    bool rampBand_0;
    if(above_12 < (- c_52->cvMammaDepth_0))
    {
        rampBand_0 = true;
    }
    else
    {
        float _S367 = convCeiling_0(c_52);
        rampBand_0 = above_12 > _S367;
    }
    if(rampBand_0)
    {
        return 0.0f;
    }
    float2  _S368 = float2 {p_12.x, p_12.z};
    float2  fromHero_0 = _S368 - c_52->cvHeroAt_0;
    bool nearGroup_4 = (dot_1(fromHero_0, fromHero_0)) < (c_52->cvGroupReach_0 * c_52->cvGroupReach_0);
    bool _S369 = _S366 > 0.0f;
    if(_S369)
    {
        rampBand_0 = above_12 < 0.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    if(rampBand_0)
    {
        float _S370 = convMammaSag_0(c_52, _S368, nearGroup_4, - above_12);
        float hang_0 = _S370 + above_12;
        if(hang_0 <= 0.0f)
        {
            return 0.0f;
        }
        return c_52->cvSigma_0 * (F32_sqrt((saturate_0(hang_0 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, hang_0);
    }
    float _S371 = convLift_0(c_52, above_12, 1.0f - 0.60000002384185791f * c_52->cvLacunarity_0);
    if(_S369)
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
    if((c_52->cvHeroAlone_0) == int(0))
    {
        float capMoat_1 = 0.0f;
        float2  _S372 = make_float2 (0.0f, 0.0f);
        float2  gMoat_1 = _S372;
        if((c_52->cvMoat_0) > 0.0f)
        {
            moated_1 = nearGroup_4;
        }
        else
        {
            moated_1 = false;
        }
        if(moated_1)
        {
            float _S373 = convMoat_0(c_52, _S368, &gMoat_1, &capMoat_1);
            capDensity_0 = _S373;
        }
        else
        {
            capDensity_0 = 1.0f;
        }
        if(capDensity_0 > 0.0f)
        {
            float2  q_11 = _S368 - c_52->cvDrift_0;
            float2  slope_6;
            float _S374 = convUpdraftGrad_0(c_52, q_11, &slope_6);
            float _S375 = convSlopeCap_0(c_52);
            float cap_6;
            if(moated_1)
            {
                slope_6 = slope_6 * make_float2 (capDensity_0) + gMoat_1 * make_float2 (_S374);
                float cap_7 = _S375 + capMoat_1;
                sag_0 = _S374 * capDensity_0;
                cap_6 = cap_7;
            }
            else
            {
                sag_0 = _S374;
                cap_6 = _S375;
            }
            if(rampBand_0)
            {
                float _S376 = convFieldBaseInside_0(c_52, sag_0, slope_6, cap_6);
                baseField_0 = _S376;
            }
            else
            {
                baseField_0 = -1.00000001504746622e+30f;
            }
            float _S377 = convTowerHeight_0(c_52, sag_0);
            float v_5 = _S377 - above_12;
            float _S378 = convNeededUpdraft_0(c_52, above_12);
            float delta_1 = sag_0 - _S378;
            float d_21 = convSurfaceDistance_0(v_5, delta_1, (F32_min((length_1(slope_6)), (cap_6))));
            if((d_21 + _S371) > 0.0f)
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
                    shiftAcross_0 = _S372;
                }
                float _S379 = convInside_0(c_52, d_21, _S371, make_float3 (q_11.x + shiftAcross_0.x, _S365 + inside_3, q_11.y + shiftAcross_0.y), c_52->cvBillowScale_0);
                inside_3 = _S379;
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
    bool _S380 = (c_52->cvHeroTop_0) > 0.0f;
    if(_S380)
    {
        if((c_52->cvPileusThick_0) > 0.0f)
        {
            moated_1 = true;
        }
        else
        {
            moated_1 = (c_52->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        float _S381 = convCapDensity_0(c_52, p_12, above_12);
        capDensity_0 = _S381;
    }
    else
    {
        capDensity_0 = 0.0f;
    }
    if(_S380)
    {
        moated_1 = inside_3 < 12.0f;
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        if((c_52->cvTurretCount_0) > int(0))
        {
            float _S382 = convGroupInside_0(c_52, p_12, above_12, nearGroup_4);
            inside_3 = (F32_max((inside_3), (_S382)));
        }
        else
        {
            float _S383 = convHeroInside_0(c_52, p_12, above_12);
            inside_3 = (F32_max((inside_3), (_S383)));
        }
    }
    if(inside_3 <= 0.0f)
    {
        return capDensity_0;
    }
    if(rampBand_0)
    {
        float _S384 = convPouches_0(c_52, _S368 - c_52->cvDrift_0);
        if(_S384 > 0.0f)
        {
            float _S385 = convGroupBaseInside_0(c_52, _S368, nearGroup_4);
            float _S386 = convMammaSagOf_0(c_52, _S384, (F32_max((baseField_0), (_S385))));
            sag_0 = _S386;
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
    return (F32_max((c_52->cvSigma_0 * (F32_sqrt((saturate_0((above_12 + sag_0) / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_3)), (capDensity_0)));
}

static __device__ float densityAt_0(Medium_0 * m_7, StructuredBuffer<float2 > disp_6, float3  p_13)
{
    float _S387 = p_13.y;
    bool _S388;
    if(_S387 < (m_7->slabBottom_0))
    {
        _S388 = true;
    }
    else
    {
        _S388 = _S387 > (m_7->slabTop_0);
    }
    if(_S388)
    {
        return 0.0f;
    }
    if((m_7->clipOn_0) != int(0))
    {
        float2  _S389 = float2 {p_13.x, p_13.z};
        if(any_0(_S389 < (m_7->clipLo_0)))
        {
            _S388 = true;
        }
        else
        {
            _S388 = any_0(_S389 > (m_7->clipHi_0));
        }
    }
    else
    {
        _S388 = false;
    }
    if(_S388)
    {
        return 0.0f;
    }
    float _S390 = m_7->fadeRadius_0;
    float fade_0;
    if((m_7->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S390 - length_1(float2 {p_13.x, p_13.z} - m_7->fadeAt_0)) / (F32_max((m_7->fadeWidth_0), (1.0f))));
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
    int _S391 = m_7->mode_0;
    if((m_7->mode_0) == int(0))
    {
        return m_7->density_0 * fade_0;
    }
    if(_S391 == int(2))
    {
        float _S392 = iceDensity_0(&m_7->gen_0, disp_6, p_13);
        return _S392 * fade_0;
    }
    if(_S391 == int(3))
    {
        float _S393 = convectionDensity_0(&m_7->conv_0, p_13);
        return _S393 * fade_0;
    }
    float3  d_22 = (p_13 - m_7->coreCentre_0) / make_float3 ((F32_max((m_7->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_7->density_0 + m_7->coreDensity_0 * (F32_exp((- dot_0(d_22, d_22))))) * fade_0;
}

static __device__ float transmittance_0(Medium_0 * m_8, MajorantGrid_0 * g_14, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > disp_7, Rng_0 * rng_1, float3  p_14, float3  dir_1, int * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S394 = slabRange_0(m_8, p_14, dir_1, &t0_2, &t1_2);
    if(!_S394)
    {
        return 1.0f;
    }
    float _S395 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S395;
    Dda_0 _S396 = ddaInit_0(g_14, p_14, dir_1, _S395);
    Dda_0 dda_1 = _S396;
    float _S397 = m_8->majorant_0;
    float _S398 = gridBound_0(m_8, g_14, bounds_2, disp_7, (&dda_1)->cell_0, m_8->majorant_0);
    float localMaj_0 = _S398;
    int i_20 = int(0);
    float t_10 = _S395;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_20 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_1 = *steps_1 + int(1);
        Dda_0 _S399 = dda_1;
        float _S400 = ddaExit_0(&_S399);
        float _S401 = (F32_min((_S400), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S401 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S402 = gridBound_0(m_8, g_14, bounds_2, disp_7, (&dda_1)->cell_0, _S397);
            localMaj_0 = _S402;
            t_10 = _S401;
            i_20 = i_20 + int(1);
            continue;
        }
        float _S403 = randFloat_0(rng_1);
        float t_11 = t_10 - (F32_log(((F32_max((1.0f - _S403), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_11 >= _S401)
        {
            if(_S401 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S404 = gridBound_0(m_8, g_14, bounds_2, disp_7, (&dda_1)->cell_0, _S397);
            localMaj_0 = _S404;
            t_10 = _S401;
            i_20 = i_20 + int(1);
            continue;
        }
        float _S405 = densityAt_0(m_8, disp_7, p_14 + dir_1 * make_float3 (t_11));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S405 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S406 = randFloat_0(rng_1);
            if(_S406 > 0.5f)
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
        i_20 = i_20 + int(1);
    }
    return tr_0;
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
};

static __device__ float sceneTransmittance_0(Scene_0 * s_13, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > drift_1, Rng_0 * rng_2, float3  p_15, float3  dir_2, int * steps_2)
{
    float _S407 = transmittance_0(&s_13->medium_0, &s_13->grid_0, bounds_3, drift_1, rng_2, p_15, dir_2, steps_2);
    bool _S408;
    if((s_13->layer2On_0) != int(0))
    {
        _S408 = _S407 > 0.0f;
    }
    else
    {
        _S408 = false;
    }
    float tr_3;
    if(_S408)
    {
        MajorantGrid_0 _S409 = gridFor_0(&s_13->medium2_0, &s_13->grid2_0, p_15);
        MajorantGrid_0 _S410 = _S409;
        float _S411 = transmittance_0(&s_13->medium2_0, &_S410, bounds_3, drift_1, rng_2, p_15, dir_2, steps_2);
        tr_3 = _S407 * _S411;
    }
    else
    {
        tr_3 = _S407;
    }
    return tr_3;
}

static __device__ float hg_0(float cosT_0, float g_15)
{
    float _S412 = g_15 * g_15;
    float d_23 = 1.0f + _S412 - 2.0f * g_15 * cosT_0;
    return (1.0f - _S412) / (12.56637096405029297f * d_23 * (F32_sqrt(((F32_max((d_23), (9.99999997475242708e-07f)))))));
}

static __device__ float phaseIce_0(float cosT_1)
{
    float t_12 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_0(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_12 * t_12))) * 0.34999999403953552f;
}

static __device__ float draine_0(float cosT_2, float g_16, float a_5)
{
    float _S413 = g_16 * g_16;
    float _S414 = 2.0f * g_16;
    float d_24 = 1.0f + _S413 - _S414 * cosT_2;
    return (1.0f - _S413) / (12.56637096405029297f * d_24 * (F32_sqrt(((F32_max((d_24), (9.99999997475242708e-07f))))))) * (1.0f + a_5 * cosT_2 * cosT_2) / (1.0f + a_5 * (1.0f + _S414 * g_16) / 3.0f);
}

static __device__ float phaseLiquid_0(PhaseInput_0 * p_16, float cosT_3)
{
    return (1.0f - p_16->draineW_0) * hg_0(cosT_3, p_16->hgG_0) + p_16->draineW_0 * draine_0(cosT_3, p_16->draineG_0, p_16->draineAlpha_0);
}

static __device__ float phaseAt_0(PhaseInput_0 * p_17, float cosT_4)
{
    float _S415;
    if((p_17->useIce_0) != int(0))
    {
        _S415 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S416 = phaseLiquid_0(p_17, cosT_4);
        _S415 = _S416;
    }
    return _S415;
}

static __device__ float phaseCamera_0(PhaseInput_0 * p_18, float cosT_5)
{
    float _S417 = phaseAt_0(p_18, cosT_5);
    float _S418 = p_18->lobeWeight_0;
    float v_6;
    if((p_18->lobeWeight_0) > 0.0f)
    {
        v_6 = _S417 + _S418 * hg_0(cosT_5, p_18->lobeG_0);
    }
    else
    {
        v_6 = _S417;
    }
    return v_6;
}

static __device__ float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_25 = altitude_0 - shellHeight_0;
    return d_25 * (d_25 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_4, float c_53)
{
    float disc_0 = b_4 * b_4 - c_53;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_4 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_5, float c_54)
{
    float disc_1 = b_5 * b_5 - c_54;
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

static __device__ float altitudeFromQ_0(float q_12, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_12;
    float _S419;
    if(rr_0 > 0.0f)
    {
        _S419 = rr_0;
    }
    else
    {
        _S419 = 0.0f;
    }
    return q_12 / (planetRadius_2 + (F32_sqrt((_S419))));
}

static __device__ float3  airTransmittance_0(SkyInput_0 * p_19, float originAltitude_0, float3  rayDir_0, float dist_1)
{
    float _S420 = p_19->planetRadius_0;
    float planetRadius_3;
    if((p_19->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S420;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S421 = p_19->scaleHeight_0;
    float scaleHeight_1;
    if((p_19->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S421;
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
    bool _S422;
    if(tTop_0 <= 0.0f)
    {
        _S422 = true;
    }
    else
    {
        _S422 = !(dist_1 > 0.0f);
    }
    if(_S422)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float tGround_0 = shellEnter_0(b_6, cGround_0);
    float tMax_1;
    if(tGround_0 > 0.0f)
    {
        tMax_1 = tGround_0;
    }
    else
    {
        tMax_1 = tTop_0;
    }
    if(dist_1 < tMax_1)
    {
        tMax_1 = dist_1;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaMExt_0 = mieCoefficient_0(p_19->turbidity_0) * 1.11000001430511475f;
    float tPrev_0 = 0.0f;
    int i_21 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_21 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S423 = i_21 + int(1);
        float tNext_0 = tMax_1 * float(_S423 * _S423) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_21 = _S423;
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
        float _S424 = - hc_0;
        float depthM_1 = depthM_0 + (F32_exp((_S424 / 1200.0f))) * dt_0;
        depthR_0 = depthR_0 + (F32_exp((_S424 / scaleHeight_1))) * dt_0;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_21 = _S423;
    }
    float _S425 = betaMExt_0 * depthM_0;
    return make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S425)))), (F32_exp((- (betaR_0.y * depthR_0 + _S425)))), (F32_exp((- (betaR_0.z * depthR_0 + _S425)))));
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_20)
{
    return 20.0f * p_20->sunIntensity_0;
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

static __device__ float3  sunDirection_0(SkyInput_0 * p_21)
{
    float az_0 = toRadians_0(p_21->sunAzimuth_0);
    float el_0 = toRadians_0(p_21->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static __device__ float lutMuFor_0(float3  geocentric_0, float3  sun_0)
{
    float len_1 = length_0(geocentric_0);
    float _S426;
    if(len_1 > 1.0f)
    {
        _S426 = dot_0(geocentric_0, sun_0) / len_1;
    }
    else
    {
        _S426 = dot_0(geocentric_0, sun_0);
    }
    return _S426;
}

static __device__ float clampf_0(float v_8, float lo_11, float hi_10)
{
    float _S427;
    if(v_8 < lo_11)
    {
        _S427 = lo_11;
    }
    else
    {
        if(v_8 > hi_10)
        {
            _S427 = hi_10;
        }
        else
        {
            _S427 = v_8;
        }
    }
    return _S427;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_22, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S428 = p_22->transmittanceLut_0;
    if(uint(StructuredBuffer_getCount_0(p_22->transmittanceLut_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S429 = p_22->scaleHeight_0;
    float scaleHeight_2;
    if((p_22->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S429;
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
    float _S430 = fx_1 - float(x0_1);
    float _S431 = fy_1 - float(y0_1);
    int _S432 = y0_1 * int(256);
    int _S433 = (_S432 + x0_1) * int(3);
    int _S434 = (_S432 + x1_1) * int(3);
    int _S435 = y1_1 * int(256);
    int _S436 = (_S435 + x0_1) * int(3);
    int _S437 = (_S435 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_55 = int(0);
    for(;;)
    {
        if(c_55 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S438 = __ldg((&(_S428)[_S433 + c_55]));
        float _S439 = 1.0f - _S430;
        float _S440 = _S438 * _S439;
        float _S441 = __ldg((&(_S428)[_S434 + c_55]));
        float a_6 = _S440 + _S441 * _S430;
        float _S442 = __ldg((&(_S428)[_S436 + c_55]));
        float _S443 = _S442 * _S439;
        float _S444 = __ldg((&(_S428)[_S437 + c_55]));
        float r_12 = a_6 * (1.0f - _S431) + (_S443 + _S444 * _S430) * _S431;
        if(c_55 == int(0))
        {
            *&((&out_0)->x) = r_12;
        }
        else
        {
            if(c_55 == int(1))
            {
                *&((&out_0)->y) = r_12;
            }
            else
            {
                *&((&out_0)->z) = r_12;
            }
        }
        c_55 = c_55 + int(1);
    }
    return out_0;
}

static __device__ float3  sunTransmittanceAt_0(SkyInput_0 * p_23, float3  worldPos_0)
{
    float3  _S445 = sunDirection_0(p_23);
    float _S446 = p_23->planetRadius_0;
    float planetRadius_4;
    if((p_23->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S446;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S447 = worldPos_0.y;
    float altitude_2;
    if(_S447 > 0.0f)
    {
        altitude_2 = _S447;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    float3  _S448 = sampleTransmittanceLut_0(p_23, altitude_2, lutMuFor_0(make_float3 (worldPos_0.x, planetRadius_4 + _S447, worldPos_0.z), _S445));
    return _S448;
}

static __device__ float3  sunIrradianceAt_0(Scene_0 * s_14, float3  p_24)
{
    if(((&s_14->environment_0)->envMode_0) == int(1))
    {
        float _S449 = sunIrradianceTop_0(&(&s_14->environment_0)->sky_0);
        float3  _S450 = sunTransmittanceAt_0(&(&s_14->environment_0)->sky_0, p_24);
        return make_float3 (_S449) * _S450;
    }
    return s_14->sunIrradiance_0;
}

static __device__ float3  cameraSegmentSun_0(Scene_0 * s_15, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > drift_2, Rng_0 * rng_3, Rng_0 * rng2_0, float3  ro_2, float3  rd_2, int * steps_3)
{
    float ph0_0;
    float kept_0;
    float keptT_0;
    float3  keptAt_0;
    int keptLayer_0;
    Rng_0 _S451 = *rng2_0;
    float3  none_0 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S452 = (F32_max((s_15->neeTentativeScale_0), (1.0f)));
    float tA_0;
    float endA_0;
    bool _S453 = slabRange_0(&s_15->medium_0, ro_2, rd_2, &tA_0, &endA_0);
    float _S454 = (F32_max((tA_0), (0.0f)));
    tA_0 = _S454;
    Dda_0 _S455 = ddaInit_0(&s_15->grid_0, ro_2, rd_2, _S454);
    Dda_0 ddaA_0 = _S455;
    float _S456 = gridBound_0(&s_15->medium_0, &s_15->grid_0, bounds_4, drift_2, (&ddaA_0)->cell_0, (&s_15->medium_0)->majorant_0);
    float rateA_0 = _S456 * _S452;
    int budgetA_0 = int(4096);
    float keepA_0 = 0.0f;
    float rouletteA_0 = 0.0f;
    bool haveA_0;
    if(_S453)
    {
        bool _S457 = segmentStep_0(&s_15->medium_0, &s_15->grid_0, bounds_4, drift_2, _S452, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
        haveA_0 = _S457;
    }
    else
    {
        haveA_0 = _S453;
    }
    float tB_0 = 0.0f;
    float endB_0 = 0.0f;
    bool haveB_0;
    if((s_15->layer2On_0) != int(0))
    {
        bool _S458 = slabRange_0(&s_15->medium2_0, ro_2, rd_2, &tB_0, &endB_0);
        haveB_0 = _S458;
    }
    else
    {
        haveB_0 = false;
    }
    float _S459 = (F32_max((tB_0), (0.0f)));
    tB_0 = _S459;
    MajorantGrid_0 _S460 = gridFor_0(&s_15->medium2_0, &s_15->grid2_0, ro_2);
    MajorantGrid_0 _S461 = _S460;
    Dda_0 _S462 = ddaInit_0(&_S461, ro_2, rd_2, _S459);
    Dda_0 ddaB_0 = _S462;
    MajorantGrid_0 _S463 = _S460;
    float _S464 = gridBound_0(&s_15->medium2_0, &_S463, bounds_4, drift_2, (&ddaB_0)->cell_0, (&s_15->medium2_0)->majorant_0);
    float rateB_0 = _S464 * _S452;
    int budgetB_0 = int(4096);
    float keepB_0 = 0.0f;
    float rouletteB_0 = 0.0f;
    if(haveB_0)
    {
        MajorantGrid_0 _S465 = _S460;
        bool _S466 = segmentStep_0(&s_15->medium2_0, &_S465, bounds_4, drift_2, _S452, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S451, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
        haveB_0 = _S466;
    }
    float kept_1 = 0.0f;
    float3  keptAt_1 = none_0;
    int keptLayer_1 = int(0);
    float keptT_1 = 0.0f;
    float tr_4 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        bool _S467;
        if(haveA_0)
        {
            _S467 = true;
        }
        else
        {
            _S467 = haveB_0;
        }
        if(_S467)
        {
        }
        else
        {
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
        float3  p_25 = ro_2 + rd_2 * make_float3 (ph0_0);
        float sigma_0;
        if(takeA_0)
        {
            float _S468 = densityAt_0(&s_15->medium_0, drift_2, p_25);
            sigma_0 = _S468;
        }
        else
        {
            float _S469 = densityAt_0(&s_15->medium2_0, drift_2, p_25);
            sigma_0 = _S469;
        }
        if(sigma_0 > 0.0f)
        {
            float w_6 = sigma_0 / rate_1;
            float b_7 = tr_4 * w_6;
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
                    keptAt_0 = p_25;
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
            float tr_5 = tr_4 * (F32_max((0.0f), (1.0f - w_6)));
            float tr_6;
            if(tr_5 < 0.00999999977648258f)
            {
                if(uLive_1 > 0.5f)
                {
                    total_0 = total_1;
                    break;
                }
                tr_6 = tr_5 * 2.0f;
            }
            else
            {
                tr_6 = tr_5;
            }
            tr_4 = tr_6;
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
            bool _S470 = segmentStep_0(&s_15->medium_0, &s_15->grid_0, bounds_4, drift_2, _S452, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
            haveA_0 = _S470;
        }
        else
        {
            MajorantGrid_0 _S471 = _S460;
            bool _S472 = segmentStep_0(&s_15->medium2_0, &_S471, bounds_4, drift_2, _S452, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S451, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
            haveB_0 = _S472;
        }
        kept_1 = kept_0;
        keptAt_1 = keptAt_0;
        keptLayer_1 = keptLayer_0;
        keptT_1 = keptT_0;
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
        return none_0;
    }
    float3  _S473 = s_15->sunDir_0;
    float _S474 = sceneTransmittance_0(s_15, bounds_4, drift_2, rng_3, keptAt_0 + s_15->sunDir_0 * make_float3 (s_15->shadowOffset_0), s_15->sunDir_0, steps_3);
    float3  _S475 = s_15->albedo_0;
    float3  matterAlbedo_0;
    if(keptLayer_0 == int(0))
    {
        float _S476 = phaseCamera_0(ph_0, dot_0(rd_2, _S473));
        matterAlbedo_0 = _S475;
        ph0_0 = _S476;
    }
    else
    {
        float _S477 = phaseCamera_0(&s_15->phase2_0, dot_0(rd_2, _S473));
        matterAlbedo_0 = s_15->albedo2_0;
        ph0_0 = _S477;
    }
    float3  _S478 = make_float3 (1.0f, 1.0f, 1.0f);
    if(((&s_15->environment_0)->envMode_0) == int(1))
    {
        haveA_0 = (s_15->aerialMode_0) != int(0);
    }
    else
    {
        haveA_0 = false;
    }
    float3  air_0;
    if(haveA_0)
    {
        float3  _S479 = airTransmittance_0(&(&s_15->environment_0)->sky_0, ro_2.y, rd_2, keptT_0);
        air_0 = _S479;
    }
    else
    {
        air_0 = _S478;
    }
    float3  _S480 = make_float3 (total_0) * matterAlbedo_0 * make_float3 (ph0_0) * make_float3 (_S474);
    float3  _S481 = sunIrradianceAt_0(s_15, keptAt_0);
    return _S480 * _S481 * air_0;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_9, MajorantGrid_0 * g_17, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > disp_8, Rng_0 * rng_4, float3  ro_3, float3  rd_3, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_4)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S482 = slabRange_0(m_9, ro_3, rd_3, &t0_3, &t1_3);
    if(!_S482)
    {
        return false;
    }
    float _S483 = (F32_min((t1_3), (tLimit_0)));
    t1_3 = _S483;
    if(!(_S483 > t0_3))
    {
        return false;
    }
    float _S484 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S485 = ddaInit_0(g_17, ro_3, rd_3, _S484);
    Dda_0 dda_2 = _S485;
    float _S486 = m_9->majorant_0;
    float _S487 = gridBound_0(m_9, g_17, bounds_5, disp_8, (&dda_2)->cell_0, m_9->majorant_0);
    float localMaj_1 = _S487;
    int i_22 = int(0);
    float t_13 = _S484;
    for(;;)
    {
        if(i_22 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_4 = *steps_4 + int(1);
        Dda_0 _S488 = dda_2;
        float _S489 = ddaExit_0(&_S488);
        float _S490 = (F32_min((_S489), (t1_3)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S490 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S491 = gridBound_0(m_9, g_17, bounds_5, disp_8, (&dda_2)->cell_0, _S486);
            localMaj_1 = _S491;
            t_13 = _S490;
            i_22 = i_22 + int(1);
            continue;
        }
        float _S492 = randFloat_0(rng_4);
        float t_14 = t_13 - (F32_log(((F32_max((1.0f - _S492), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_14 >= _S490)
        {
            if(_S490 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S493 = gridBound_0(m_9, g_17, bounds_5, disp_8, (&dda_2)->cell_0, _S486);
            localMaj_1 = _S493;
            t_13 = _S490;
            i_22 = i_22 + int(1);
            continue;
        }
        float3  p_26 = ro_3 + rd_3 * make_float3 (t_14);
        float _S494 = randFloat_0(rng_4);
        float _S495 = densityAt_0(m_9, disp_8, p_26);
        if(_S494 < (_S495 / localMaj_1))
        {
            *scatterPoint_0 = p_26;
            *distance_0 = t_14;
            return true;
        }
        t_13 = t_14;
        i_22 = i_22 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_10, MajorantGrid_0 * g_18, StructuredBuffer<float> bounds_6, StructuredBuffer<float2 > disp_9, Rng_0 * rng_5, float3  ro_4, float3  rd_4, float3  * scatterPoint_1, float * distance_1, int * steps_5)
{
    bool _S496 = sampleFreeFlightUpTo_0(m_10, g_18, bounds_6, disp_9, rng_5, ro_4, rd_4, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_5);
    return _S496;
}

static __device__ bool sceneFreeFlight_0(Scene_0 * s_16, StructuredBuffer<float> bounds_7, StructuredBuffer<float2 > drift_3, Rng_0 * rng_6, float3  ro_5, float3  rd_5, float3  * scatterAt_0, int * layer_0, int * steps_6)
{
    *layer_0 = int(0);
    float dist_2;
    if((s_16->layer2On_0) == int(0))
    {
        bool _S497 = sampleFreeFlight_0(&s_16->medium_0, &s_16->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, scatterAt_0, &dist_2, steps_6);
        return _S497;
    }
    float a0_0;
    float a1_0;
    bool _S498 = slabRange_0(&s_16->medium_0, ro_5, rd_5, &a0_0, &a1_0);
    float b0_0;
    float b1_0;
    bool _S499 = slabRange_0(&s_16->medium2_0, ro_5, rd_5, &b0_0, &b1_0);
    bool secondFirst_0;
    if(_S499)
    {
        if(!_S498)
        {
            secondFirst_0 = true;
        }
        else
        {
            secondFirst_0 = (F32_max((b0_0), (0.0f))) < (F32_max((a0_0), (0.0f)));
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
    MajorantGrid_0 _S500 = gridFor_0(&s_16->medium2_0, &s_16->grid2_0, ro_5);
    float _S501;
    if(secondFirst_0)
    {
        MajorantGrid_0 _S502 = _S500;
        bool _S503 = sampleFreeFlight_0(&s_16->medium2_0, &_S502, bounds_7, drift_3, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S503)
        {
            _S501 = dNear_1;
        }
        else
        {
            _S501 = 1.00000001504746622e+30f;
        }
        bool _S504 = sampleFreeFlightUpTo_0(&s_16->medium_0, &s_16->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, _S501, &pFar_0, &dFar_0, steps_6);
        if(_S504)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(0);
            return true;
        }
        if(_S503)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(1);
            return true;
        }
    }
    else
    {
        bool _S505 = sampleFreeFlight_0(&s_16->medium_0, &s_16->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S505)
        {
            _S501 = dNear_1;
        }
        else
        {
            _S501 = 1.00000001504746622e+30f;
        }
        MajorantGrid_0 _S506 = _S500;
        bool _S507 = sampleFreeFlightUpTo_0(&s_16->medium2_0, &_S506, bounds_7, drift_3, rng_6, ro_5, rd_5, _S501, &pFar_0, &dFar_0, steps_6);
        if(_S507)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(1);
            return true;
        }
        if(_S505)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(0);
            return true;
        }
    }
    *scatterAt_0 = make_float3 (0.0f, 0.0f, 0.0f);
    return false;
}

static __device__ float2  airMapAxisV_0(LayerShadowMap_0 * m_11)
{
    return make_float2 (- m_11->smAxisU_0.y, m_11->smAxisU_0.x);
}

static __device__ float airMapTexel_0(LayerShadowMap_0 * m_12, int iu_0, int iv_0, int k_11)
{
    float _S508 = __ldg((&(m_12->smTexels_0)[(k_11 * m_12->smDimV_0 + iv_0) * m_12->smDimU_0 + iu_0]));
    return _S508;
}

static __device__ float layerMapTransmittance_0(LayerShadowMap_0 * m_13, float3  p_27)
{
    int _S509 = m_13->smDimU_0;
    int _S510 = m_13->smDimV_0;
    int _S511 = m_13->smSlices_0;
    uint want_0 = uint(m_13->smDimU_0 * m_13->smDimV_0 * m_13->smSlices_0);
    bool _S512;
    if(want_0 == 0U)
    {
        _S512 = true;
    }
    else
    {
        _S512 = uint(StructuredBuffer_getCount_0(m_13->smTexels_0)) < want_0;
    }
    if(_S512)
    {
        return 1.0f;
    }
    float _S513 = p_27.y;
    float _S514 = m_13->smTop_0;
    if(_S513 >= (m_13->smTop_0))
    {
        return 1.0f;
    }
    float3  _S515 = m_13->smSun_0;
    float _S516 = m_13->smBottom_0;
    float2  q_13 = float2 {p_27.x, p_27.z} + float2 {_S515.x, _S515.z} * make_float2 ((m_13->smBottom_0 - _S513) / m_13->smSun_0.y) - m_13->smCentre_0;
    float2  _S517 = m_13->smLo_0;
    float2  _S518 = m_13->smTexel_0;
    float fu_0 = (dot_1(q_13, m_13->smAxisU_0) - m_13->smLo_0.x) / m_13->smTexel_0.x - 0.5f;
    float2  _S519 = airMapAxisV_0(m_13);
    float fv_0 = (dot_1(q_13, _S519) - _S517.y) / _S518.y - 0.5f;
    if(fu_0 >= -0.5f)
    {
        _S512 = fv_0 >= -0.5f;
    }
    else
    {
        _S512 = false;
    }
    if(_S512)
    {
        _S512 = fu_0 <= (float(_S509) - 0.5f);
    }
    else
    {
        _S512 = false;
    }
    if(_S512)
    {
        _S512 = fv_0 <= (float(_S510) - 0.5f);
    }
    else
    {
        _S512 = false;
    }
    if(!_S512)
    {
        return 1.0f;
    }
    int _S520 = _S509 - int(1);
    float fu_1 = clampf_0(fu_0, 0.0f, float(_S520));
    int _S521 = _S510 - int(1);
    float fv_1 = clampf_0(fv_0, 0.0f, float(_S521));
    int u0_0 = int(fu_1);
    int v0_0 = int(fv_1);
    int _S522 = (I32_min((u0_0 + int(1)), (_S520)));
    int _S523 = (I32_min((v0_0 + int(1)), (_S521)));
    float tu_0 = fu_1 - float(u0_0);
    float tv_0 = fv_1 - float(v0_0);
    int _S524 = _S511 - int(1);
    float fk_0 = clampf_0((_S513 - _S516) / (F32_max((_S514 - _S516), (1.0f))), 0.0f, 1.0f) * float(_S524);
    int _S525 = (I32_min((int(fk_0)), (_S524)));
    int _S526 = (I32_min((_S525 + int(1)), (_S524)));
    float tk_0 = fk_0 - float(_S525);
    float _S527 = airMapTexel_0(m_13, u0_0, v0_0, _S525);
    float _S528 = 1.0f - tu_0;
    float _S529 = _S527 * _S528;
    float _S530 = airMapTexel_0(m_13, _S522, v0_0, _S525);
    float a0_1 = _S529 + _S530 * tu_0;
    float _S531 = airMapTexel_0(m_13, u0_0, _S523, _S525);
    float _S532 = _S531 * _S528;
    float _S533 = airMapTexel_0(m_13, _S522, _S523, _S525);
    float b0_1 = _S532 + _S533 * tu_0;
    float _S534 = airMapTexel_0(m_13, u0_0, v0_0, _S526);
    float _S535 = _S534 * _S528;
    float _S536 = airMapTexel_0(m_13, _S522, v0_0, _S526);
    float a1_1 = _S535 + _S536 * tu_0;
    float _S537 = airMapTexel_0(m_13, u0_0, _S523, _S526);
    float _S538 = _S537 * _S528;
    float _S539 = airMapTexel_0(m_13, _S522, _S523, _S526);
    float _S540 = 1.0f - tv_0;
    return (a0_1 * _S540 + b0_1 * tv_0) * (1.0f - tk_0) + (a1_1 * _S540 + (_S538 + _S539 * tu_0) * tv_0) * tk_0;
}

static __device__ float groundShadow_0(LayerShadowMap_0 * mapA_0, LayerShadowMap_0 * mapB_0, float3  origin_1, float3  dir_3)
{
    float _S541 = dir_3.y;
    bool _S542;
    if(!(_S541 < 0.0f))
    {
        _S542 = true;
    }
    else
    {
        _S542 = !((origin_1.y) > 0.0f);
    }
    if(_S542)
    {
        return 1.0f;
    }
    float3  ground_0 = origin_1 + dir_3 * make_float3 (origin_1.y / - _S541);
    *&((&ground_0)->y) = 0.0f;
    float _S543 = layerMapTransmittance_0(mapA_0, ground_0);
    float _S544 = layerMapTransmittance_0(mapB_0, ground_0);
    return _S543 * _S544;
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_28, float originAltitude_1, float3  rayDir_1, bool includeSunDisc_0, float groundLit_0)
{
    float hc_1;
    float3  _S545 = sunDirection_0(p_28);
    float _S546 = p_28->planetRadius_0;
    float planetRadius_5;
    if((p_28->planetRadius_0) > 1000.0f)
    {
        planetRadius_5 = _S546;
    }
    else
    {
        planetRadius_5 = 1000.0f;
    }
    float _S547 = p_28->scaleHeight_0;
    float scaleHeight_3;
    if((p_28->scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = _S547;
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
    float _S548 = planetRadius_5 + observerAltitude_1;
    float _S549 = rayDir_1.y;
    float b_8 = _S548 * _S549;
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
    float betaM_0 = mieCoefficient_0(p_28->turbidity_0);
    float betaMExt_1 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_1, _S545), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_19 = clampf_0(p_28->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S550 = g_19 * g_19;
    float hgDenom_0 = 1.0f + _S550 - 2.0f * g_19 * cosTheta_0;
    float _S551 = 1.0f - _S550;
    float _S552 = 12.56637096405029297f * hgDenom_0;
    float tPrev_1;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_1 = hgDenom_0;
    }
    else
    {
        tPrev_1 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S551 / (_S552 * (F32_sqrt((tPrev_1))));
    float3  _S553 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_1 = 0.0f;
    float3  sumR_0 = _S553;
    float3  sumM_0 = _S553;
    int i_23 = int(0);
    float depthR_1 = 0.0f;
    float depthM_2 = 0.0f;
    for(;;)
    {
        if(i_23 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S554 = i_23 + int(1);
        float tNext_1 = observerAltitude_1 * float(_S554 * _S554) * 0.00173611112404615f;
        float dt_1 = tNext_1 - tPrev_1;
        float tMid_1 = (tPrev_1 + tNext_1) * 0.5f;
        if(dt_1 <= 0.0f)
        {
            tPrev_1 = tNext_1;
            i_23 = _S554;
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
        float _S555 = - hc_1;
        float dR_0 = (F32_exp((_S555 / scaleHeight_3))) * dt_1;
        float dM_0 = (F32_exp((_S555 / 1200.0f))) * dt_1;
        float midR_0 = depthR_1 + 0.5f * dR_0;
        float midM_0 = depthM_2 + 0.5f * dM_0;
        float depthR_2 = depthR_1 + dR_0;
        float depthM_3 = depthM_2 + dM_0;
        float3  _S556 = sampleTransmittanceLut_0(p_28, hc_1, lutMuFor_0(make_float3 (rayDir_1.x * tMid_1, _S548 + _S549 * tMid_1, rayDir_1.z * tMid_1), _S545));
        float _S557 = betaMExt_1 * midM_0;
        float3  transmittance_1 = make_float3 ((F32_exp((- (betaR_1.x * midR_0 + _S557)))), (F32_exp((- (betaR_1.y * midR_0 + _S557)))), (F32_exp((- (betaR_1.z * midR_0 + _S557))))) * _S556;
        float3  _S558 = sumM_0 + transmittance_1 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_1 * make_float3 (dR_0);
        sumM_0 = _S558;
        depthR_1 = depthR_2;
        depthM_2 = depthM_3;
        tPrev_1 = tNext_1;
        i_23 = _S554;
    }
    float _S559 = sunIrradianceTop_0(p_28);
    float3  radiance_0 = (sumR_0 * betaR_1 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S559);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_1.x * tGround_1, _S548 + _S549 * tGround_1, rayDir_1.z * tGround_1);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S545), 0.0f, 1.0f);
        float3  _S560 = sampleTransmittanceLut_0(p_28, 0.0f, lutMuFor_0(groundPoint_0, _S545));
        float _S561 = betaMExt_1 * depthM_2;
        float3  viewT_0 = make_float3 ((F32_exp((- (betaR_1.x * depthR_1 + _S561)))), (F32_exp((- (betaR_1.y * depthR_1 + _S561)))), (F32_exp((- (betaR_1.z * depthR_1 + _S561)))));
        radiance_1 = radiance_0 + viewT_0 * _S560 * make_float3 (p_28->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S559 * groundLit_0) + viewT_0 * p_28->groundSkyLight_0;
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S562;
    if(!hitsGround_0)
    {
        _S562 = includeSunDisc_0;
    }
    else
    {
        _S562 = false;
    }
    if(_S562)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_28->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S563 = betaMExt_1 * depthM_2;
            float3  viewT_1 = make_float3 ((F32_exp((- (betaR_1.x * depthR_1 + _S563)))), (F32_exp((- (betaR_1.y * depthR_1 + _S563)))), (F32_exp((- (betaR_1.z * depthR_1 + _S563)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_1 = solidAngle_0;
            }
            else
            {
                hc_1 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_1 * make_float3 (_S559 / hc_1);
        }
    }
    return radiance_1;
}

static __device__ float3  environmentRadiance_0(Environment_0 * e_0, float3  origin_2, float3  dir_4, bool includeSunDisc_1, float groundLit_1)
{
    if((e_0->envMode_0) == int(1))
    {
        float3  _S564 = skyRadiance_0(&e_0->sky_0, origin_2.y, dir_4, includeSunDisc_1, groundLit_1);
        return _S564;
    }
    return e_0->uniformRadiance_0;
}

static __device__ bool layerMapRange_0(LayerShadowMap_0 * m_14, float3  ro_6, float3  rd_6, float * t0_4, float * t1_4)
{
    *t0_4 = 0.0f;
    *t1_4 = 1.00000001504746622e+30f;
    int _S565 = m_14->smDimU_0;
    int _S566 = m_14->smDimV_0;
    uint want_1 = uint(m_14->smDimU_0 * m_14->smDimV_0 * m_14->smSlices_0);
    bool _S567;
    if(want_1 == 0U)
    {
        _S567 = true;
    }
    else
    {
        _S567 = uint(StructuredBuffer_getCount_0(m_14->smTexels_0)) < want_1;
    }
    if(_S567)
    {
        return false;
    }
    float _S568 = rd_6.y;
    if((F32_abs((_S568))) < 9.99999971718068537e-10f)
    {
        if((ro_6.y) >= (m_14->smTop_0))
        {
            return false;
        }
    }
    else
    {
        float tt_0 = (m_14->smTop_0 - ro_6.y) / _S568;
        if(_S568 > 0.0f)
        {
            *t1_4 = (F32_min((*t1_4), (tt_0)));
        }
        else
        {
            *t0_4 = (F32_max((*t0_4), (tt_0)));
        }
    }
    float3  _S569 = m_14->smSun_0;
    float2  _S570 = float2 {_S569.x, _S569.z};
    float _S571 = m_14->smSun_0.y;
    float2  q0_3 = float2 {ro_6.x, ro_6.z} + _S570 * make_float2 ((m_14->smBottom_0 - ro_6.y) / _S571) - m_14->smCentre_0;
    float2  dq_0 = float2 {rd_6.x, rd_6.z} - _S570 * make_float2 (_S568 / _S571);
    float2  _S572 = airMapAxisV_0(m_14);
    float _S573 = m_14->smLo_0.x;
    float _S574 = m_14->smLo_0.y;
    float vHi_0 = _S574 + float(_S566) * m_14->smTexel_0.y;
    bool _S575 = clipAxis_0(dot_1(q0_3, m_14->smAxisU_0), dot_1(dq_0, m_14->smAxisU_0), _S573, _S573 + float(_S565) * m_14->smTexel_0.x, t0_4, t1_4);
    if(!_S575)
    {
        return false;
    }
    bool _S576 = clipAxis_0(dot_1(q0_3, _S572), dot_1(dq_0, _S572), _S574, vHi_0, t0_4, t1_4);
    if(!_S576)
    {
        return false;
    }
    return (*t1_4) > (*t0_4);
}

static __device__ float3  airShadowLoss_0(SkyInput_0 * p_29, LayerShadowMap_0 * mapA_1, LayerShadowMap_0 * mapB_1, float3  ro_7, float3  rd_7, float dist_3, float jitter_1)
{
    float3  none_1 = make_float3 (0.0f, 0.0f, 0.0f);
    float r0_0;
    float r1_0;
    bool _S577 = layerMapRange_0(mapA_1, ro_7, rd_7, &r0_0, &r1_0);
    float tA_1;
    float tB_1;
    if(_S577)
    {
        float _S578 = (F32_max((-1.00000001504746622e+30f), (r1_0)));
        tA_1 = (F32_min((1.00000001504746622e+30f), (r0_0)));
        tB_1 = _S578;
    }
    else
    {
        tA_1 = 1.00000001504746622e+30f;
        tB_1 = -1.00000001504746622e+30f;
    }
    bool _S579 = layerMapRange_0(mapB_1, ro_7, rd_7, &r0_0, &r1_0);
    if(_S579)
    {
        float _S580 = (F32_min((tA_1), (r0_0)));
        tB_1 = (F32_max((tB_1), (r1_0)));
        tA_1 = _S580;
    }
    if(!(tB_1 > tA_1))
    {
        return none_1;
    }
    float3  _S581 = sunDirection_0(p_29);
    float _S582 = p_29->planetRadius_0;
    float planetRadius_6;
    if((p_29->planetRadius_0) > 1000.0f)
    {
        planetRadius_6 = _S582;
    }
    else
    {
        planetRadius_6 = 1000.0f;
    }
    float _S583 = p_29->scaleHeight_0;
    float scaleHeight_4;
    if((p_29->scaleHeight_0) > 1.0f)
    {
        scaleHeight_4 = _S583;
    }
    else
    {
        scaleHeight_4 = 1.0f;
    }
    float atmosphereHeight_2 = scaleHeight_4 * 8.0f;
    float _S584 = ro_7.y;
    float observerAltitude_2;
    if(_S584 > 0.0f)
    {
        observerAltitude_2 = _S584;
    }
    else
    {
        observerAltitude_2 = 0.0f;
    }
    float _S585 = planetRadius_6 + observerAltitude_2;
    float _S586 = rd_7.y;
    float b_9 = _S585 * _S586;
    float cGround_2 = shellC_0(observerAltitude_2, planetRadius_6, 0.0f);
    float tTop_2 = shellExit_0(b_9, shellC_0(observerAltitude_2, planetRadius_6, atmosphereHeight_2));
    bool _S587;
    if(tTop_2 <= 0.0f)
    {
        _S587 = true;
    }
    else
    {
        _S587 = !(dist_3 > 0.0f);
    }
    if(_S587)
    {
        return none_1;
    }
    float tGround_2 = shellEnter_0(b_9, cGround_2);
    float tMax_2;
    if(tGround_2 > 0.0f)
    {
        tMax_2 = tGround_2;
    }
    else
    {
        tMax_2 = tTop_2;
    }
    if(dist_3 < tMax_2)
    {
        tMax_2 = dist_3;
    }
    float _S588 = (F32_max((tA_1), (0.0f)));
    float _S589 = (F32_min((tB_1), (tMax_2)));
    if(!(_S589 > _S588))
    {
        return none_1;
    }
    float3  betaR_2 = rayleighCoefficients_0();
    float betaM_1 = mieCoefficient_0(p_29->turbidity_0);
    float _S590 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rd_7, _S581), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_20 = clampf_0(p_29->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S591 = g_20 * g_20;
    float hgDenom_1 = 1.0f + _S591 - 2.0f * g_20 * cosTheta_1;
    float _S592 = 1.0f - _S591;
    float _S593 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        tA_1 = hgDenom_1;
    }
    else
    {
        tA_1 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S592 / (_S593 * (F32_sqrt((tA_1))));
    float depthR_3;
    float depthM_4;
    float hc_2;
    int i_24;
    if(_S588 > 0.0f)
    {
        float _S594 = _S588 / 8.0f;
        i_24 = int(0);
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
        for(;;)
        {
            if(i_24 < int(8))
            {
            }
            else
            {
                break;
            }
            float tm_0 = (float(i_24) + 0.5f) * _S594;
            float h_7 = altitudeFromQ_0(cGround_2 + 2.0f * tm_0 * b_9 + tm_0 * tm_0, planetRadius_6);
            if(h_7 < 0.0f)
            {
                hc_2 = 0.0f;
            }
            else
            {
                hc_2 = h_7;
            }
            float _S595 = - hc_2;
            float depthR_4 = depthR_3 + (F32_exp((_S595 / scaleHeight_4))) * _S594;
            float depthM_5 = depthM_4 + (F32_exp((_S595 / 1200.0f))) * _S594;
            i_24 = i_24 + int(1);
            depthR_3 = depthR_4;
            depthM_4 = depthM_5;
        }
    }
    else
    {
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
    }
    float _S596 = clampf_0(jitter_1, 0.0f, 1.0f);
    float _S597 = _S589 - _S588;
    float3  lossR_0 = none_1;
    float3  lossM_0 = none_1;
    i_24 = int(0);
    for(;;)
    {
        if(i_24 < int(48))
        {
        }
        else
        {
            break;
        }
        float s0_0 = _S588 + _S597 * float(i_24 * i_24) * 0.00043402778101154f;
        int _S598 = i_24 + int(1);
        float dt_2 = _S588 + _S597 * float(_S598 * _S598) * 0.00043402778101154f - s0_0;
        float ts_0 = s0_0 + _S596 * dt_2;
        float h_8 = altitudeFromQ_0(cGround_2 + 2.0f * ts_0 * b_9 + ts_0 * ts_0, planetRadius_6);
        if(h_8 < 0.0f)
        {
            hc_2 = 0.0f;
        }
        else
        {
            hc_2 = h_8;
        }
        float _S599 = - hc_2;
        float rhoR_0 = (F32_exp((_S599 / scaleHeight_4)));
        float rhoM_0 = (F32_exp((_S599 / 1200.0f)));
        float _S600 = ts_0 - s0_0;
        float atR_0 = depthR_3 + rhoR_0 * _S600;
        float atM_0 = depthM_4 + rhoM_0 * _S600;
        float depthR_5 = depthR_3 + rhoR_0 * dt_2;
        float depthM_6 = depthM_4 + rhoM_0 * dt_2;
        float3  pw_0 = ro_7 + rd_7 * make_float3 (ts_0);
        float _S601 = layerMapTransmittance_0(mapA_1, pw_0);
        float _S602 = layerMapTransmittance_0(mapB_1, pw_0);
        float v_9 = _S601 * _S602;
        if(v_9 >= 1.0f)
        {
            i_24 = _S598;
            depthR_3 = depthR_5;
            depthM_4 = depthM_6;
            continue;
        }
        float3  _S603 = sampleTransmittanceLut_0(p_29, hc_2, lutMuFor_0(make_float3 (rd_7.x * ts_0, _S585 + _S586 * ts_0, rd_7.z * ts_0), _S581));
        float _S604 = _S590 * atM_0;
        float3  w_7 = make_float3 ((F32_exp((- (betaR_2.x * atR_0 + _S604)))), (F32_exp((- (betaR_2.y * atR_0 + _S604)))), (F32_exp((- (betaR_2.z * atR_0 + _S604))))) * _S603 * make_float3 ((1.0f - v_9) * dt_2);
        float3  _S605 = lossM_0 + w_7 * make_float3 (rhoM_0);
        lossR_0 = lossR_0 + w_7 * make_float3 (rhoR_0);
        lossM_0 = _S605;
        i_24 = _S598;
        depthR_3 = depthR_5;
        depthM_4 = depthM_6;
    }
    float3  _S606 = lossR_0 * betaR_2 * make_float3 (phaseR_1) + lossM_0 * make_float3 (betaM_1 * phaseM_1);
    float _S607 = sunIrradianceTop_0(p_29);
    return _S606 * make_float3 (_S607);
}

struct AirSegment_0
{
    float3  airIn_0;
    float3  airT_0;
    float shadowAt_0;
};

static __device__ AirSegment_0 airSegment_0(SkyInput_0 * p_30, float originAltitude_2, float3  rayDir_2, float dist_4, float u1_0, float u2_0)
{
    AirSegment_0 seg_0;
    float3  _S608 = make_float3 (0.0f, 0.0f, 0.0f);
    (&seg_0)->airIn_0 = _S608;
    (&seg_0)->airT_0 = make_float3 (1.0f, 1.0f, 1.0f);
    (&seg_0)->shadowAt_0 = -1.0f;
    float3  _S609 = sunDirection_0(p_30);
    float _S610 = p_30->planetRadius_0;
    float planetRadius_7;
    if((p_30->planetRadius_0) > 1000.0f)
    {
        planetRadius_7 = _S610;
    }
    else
    {
        planetRadius_7 = 1000.0f;
    }
    float _S611 = p_30->scaleHeight_0;
    float scaleHeight_5;
    if((p_30->scaleHeight_0) > 1.0f)
    {
        scaleHeight_5 = _S611;
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
    float _S612 = planetRadius_7 + observerAltitude_3;
    float _S613 = rayDir_2.y;
    float b_10 = _S612 * _S613;
    float cGround_3 = shellC_0(observerAltitude_3, planetRadius_7, 0.0f);
    float tTop_3 = shellExit_0(b_10, shellC_0(observerAltitude_3, planetRadius_7, atmosphereHeight_3));
    bool _S614;
    if(tTop_3 <= 0.0f)
    {
        _S614 = true;
    }
    else
    {
        _S614 = !(dist_4 > 0.0f);
    }
    if(_S614)
    {
        return seg_0;
    }
    float tGround_3 = shellEnter_0(b_10, cGround_3);
    float tMax_3;
    if(tGround_3 > 0.0f)
    {
        tMax_3 = tGround_3;
    }
    else
    {
        tMax_3 = tTop_3;
    }
    if(dist_4 < tMax_3)
    {
        tMax_3 = dist_4;
    }
    float3  betaR_3 = rayleighCoefficients_0();
    float betaM_2 = mieCoefficient_0(p_30->turbidity_0);
    float betaMExt_2 = betaM_2 * 1.11000001430511475f;
    float cosTheta_2 = clampf_0(dot_0(rayDir_2, _S609), -1.0f, 1.0f);
    float phaseR_2 = 0.05968309938907623f * (1.0f + cosTheta_2 * cosTheta_2);
    float g_21 = clampf_0(p_30->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S615 = g_21 * g_21;
    float hgDenom_2 = 1.0f + _S615 - 2.0f * g_21 * cosTheta_2;
    float _S616 = 1.0f - _S615;
    float _S617 = 12.56637096405029297f * hgDenom_2;
    if(hgDenom_2 > 9.99999997475242708e-07f)
    {
        observerAltitude_3 = hgDenom_2;
    }
    else
    {
        observerAltitude_3 = 9.99999997475242708e-07f;
    }
    float phaseM_2 = _S616 / (_S617 * (F32_sqrt((observerAltitude_3))));
    float tPrev_2 = 0.0f;
    float3  sumR_1 = _S608;
    float3  sumM_1 = _S608;
    float u_4 = u1_0;
    float pickedFrom_0 = -1.0f;
    float pickedSpan_0 = 0.0f;
    int i_25 = int(0);
    float depthR_6 = 0.0f;
    float depthM_7 = 0.0f;
    float lumTotal_0 = 0.0f;
    for(;;)
    {
        if(i_25 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S618 = i_25 + int(1);
        float tNext_2 = tMax_3 * float(_S618 * _S618) * 0.00173611112404615f;
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
            i_25 = _S618;
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
        float _S619 = - hc_3;
        float dR_1 = (F32_exp((_S619 / scaleHeight_5))) * dt_3;
        float dM_1 = (F32_exp((_S619 / 1200.0f))) * dt_3;
        float midR_1 = depthR_6 + 0.5f * dR_1;
        float midM_1 = depthM_7 + 0.5f * dM_1;
        float depthR_7 = depthR_6 + dR_1;
        float depthM_8 = depthM_7 + dM_1;
        float3  _S620 = sampleTransmittanceLut_0(p_30, hc_3, lutMuFor_0(make_float3 (rayDir_2.x * tMid_2, _S612 + _S613 * tMid_2, rayDir_2.z * tMid_2), _S609));
        float _S621 = betaMExt_2 * midM_1;
        float3  transmittance_2 = make_float3 ((F32_exp((- (betaR_3.x * midR_1 + _S621)))), (F32_exp((- (betaR_3.y * midR_1 + _S621)))), (F32_exp((- (betaR_3.z * midR_1 + _S621))))) * _S620;
        float3  _S622 = sumR_1 + transmittance_2 * make_float3 (dR_1);
        float3  _S623 = sumM_1 + transmittance_2 * make_float3 (dM_1);
        float3  c_56 = transmittance_2 * (betaR_3 * make_float3 (phaseR_2 * dR_1) + make_float3 (betaM_2 * (phaseM_2 * dM_1)));
        float lum_0 = c_56.x + c_56.y + c_56.z;
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
        sumR_1 = _S622;
        sumM_1 = _S623;
        depthR_6 = depthR_7;
        depthM_7 = depthM_8;
        lumTotal_0 = lumTotal_1;
        tPrev_2 = tNext_2;
        u_4 = u_5;
        pickedFrom_0 = pickedFrom_1;
        pickedSpan_0 = pickedSpan_1;
        i_25 = _S618;
    }
    float _S624 = sunIrradianceTop_0(p_30);
    (&seg_0)->airIn_0 = (sumR_1 * betaR_3 * make_float3 (phaseR_2) + sumM_1 * make_float3 (betaM_2 * phaseM_2)) * make_float3 (_S624);
    float _S625 = betaMExt_2 * depthM_7;
    (&seg_0)->airT_0 = make_float3 ((F32_exp((- (betaR_3.x * depthR_6 + _S625)))), (F32_exp((- (betaR_3.y * depthR_6 + _S625)))), (F32_exp((- (betaR_3.z * depthR_6 + _S625)))));
    if(pickedFrom_0 >= 0.0f)
    {
        (&seg_0)->shadowAt_0 = pickedFrom_0 + clampf_0(u2_0, 0.0f, 1.0f) * pickedSpan_0;
    }
    return seg_0;
}

static __device__ float airShadow_0(Scene_0 * s_17, StructuredBuffer<float> bounds_8, StructuredBuffer<float2 > drift_4, Rng_0 * rng_7, AirSegment_0 * seg_1, float3  ro_8, float3  rd_8, int * steps_7)
{
    bool _S626;
    if((s_17->aerialMode_0) < int(2))
    {
        _S626 = true;
    }
    else
    {
        _S626 = (seg_1->shadowAt_0) < 0.0f;
    }
    if(_S626)
    {
        return 1.0f;
    }
    float _S627 = sceneTransmittance_0(s_17, bounds_8, drift_4, rng_7, ro_8 + rd_8 * make_float3 (seg_1->shadowAt_0), s_17->sunDir_0, steps_7);
    return _S627;
}

static __device__ float3  sampleHG_0(Rng_0 * rng_8, float3  wo_0, float g_22, float * cosT_6)
{
    float _S628 = clamp_0(g_22, -0.99900001287460327f, 0.99900001287460327f);
    float u1_1 = randFloat_0(rng_8);
    float u2_1 = randFloat_0(rng_8);
    if((F32_abs((_S628))) < 0.00100000004749745f)
    {
        *cosT_6 = 1.0f - 2.0f * u1_1;
    }
    else
    {
        float _S629 = _S628 * _S628;
        float _S630 = 2.0f * _S628;
        float s_18 = (1.0f - _S629) / (1.0f - _S628 + _S630 * u1_1);
        *cosT_6 = (1.0f + _S629 - s_18 * s_18) / _S630;
    }
    float _S631 = clamp_0(*cosT_6, -1.0f, 1.0f);
    *cosT_6 = _S631;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S631 * _S631))))));
    float phi_0 = 6.28318548202514648f * u2_1;
    float3  w_8 = normalize_0(wo_0);
    float3  a_7;
    if((F32_abs((w_8.y))) < 0.94999998807907104f)
    {
        a_7 = make_float3 (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_7 = make_float3 (1.0f, 0.0f, 0.0f);
    }
    float3  u_6 = normalize_0(cross_0(a_7, w_8));
    return normalize_0(make_float3 (sinT_0 * (F32_cos((phi_0)))) * u_6 + make_float3 (sinT_0 * (F32_sin((phi_0)))) * cross_0(w_8, u_6) + make_float3 (*cosT_6) * w_8);
}

static __device__ float3  sampleDraine_0(Rng_0 * rng_9, float3  wo_1, float g_23, float a_8, float * cosT_7)
{
    float3  dir_5 = sampleHG_0(rng_9, wo_1, g_23, cosT_7);
    if(!(a_8 > 0.0f))
    {
        return dir_5;
    }
    float3  dir_6 = dir_5;
    int i_26 = int(0);
    for(;;)
    {
        if(i_26 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S632 = randFloat_0(rng_9);
        if((_S632 * (1.0f + a_8)) <= (1.0f + a_8 * *cosT_7 * *cosT_7))
        {
            break;
        }
        float3  _S633 = sampleHG_0(rng_9, wo_1, g_23, cosT_7);
        int i_27 = i_26 + int(1);
        dir_6 = _S633;
        i_26 = i_27;
    }
    return dir_6;
}

static __device__ float3  samplePhaseDir_0(PhaseInput_0 * p_31, Rng_0 * rng_10, float3  wo_2, float * weight_0)
{
    float cosT_8;
    float3  dir_7;
    float _S634;
    if((p_31->useIce_0) != int(0))
    {
        float _S635 = randFloat_0(rng_10);
        if(_S635 < 0.72000002861022949f)
        {
            float3  _S636 = sampleHG_0(rng_10, wo_2, 0.85000002384185791f, &cosT_8);
            dir_7 = _S636;
        }
        else
        {
            float3  _S637 = sampleHG_0(rng_10, wo_2, 0.0f, &cosT_8);
            dir_7 = _S637;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_8, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S634 = phaseIce_0(cosT_8) / pdf_0;
        }
        else
        {
            _S634 = 0.0f;
        }
        *weight_0 = _S634;
    }
    else
    {
        float _S638 = randFloat_0(rng_10);
        if(_S638 < (p_31->draineW_0))
        {
            float3  _S639 = sampleDraine_0(rng_10, wo_2, p_31->draineG_0, p_31->draineAlpha_0, &cosT_8);
            dir_7 = _S639;
        }
        else
        {
            float3  _S640 = sampleHG_0(rng_10, wo_2, p_31->hgG_0, &cosT_8);
            dir_7 = _S640;
        }
        float _S641 = phaseLiquid_0(p_31, cosT_8);
        if(_S641 > 9.99999971718068537e-10f)
        {
            _S634 = 1.0f;
        }
        else
        {
            _S634 = 0.0f;
        }
        *weight_0 = _S634;
    }
    return dir_7;
}

struct TraceResult_0
{
    float3  pathRadiance_0;
    int scatterEvents_0;
    int capped_0;
    int trackingSteps_0;
};

static __device__ TraceResult_0 trace_0(Scene_0 * s_19, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_9, StructuredBuffer<float2 > drift_5, Rng_0 * rng_11, float3  ro_9, float3  rd_9)
{
    TraceResult_0 r_13;
    float3  _S642 = make_float3 (0.0f, 0.0f, 0.0f);
    (&r_13)->pathRadiance_0 = _S642;
    (&r_13)->scatterEvents_0 = int(0);
    (&r_13)->capped_0 = int(0);
    (&r_13)->trackingSteps_0 = int(0);
    float3  throughput_0 = make_float3 (1.0f, 1.0f, 1.0f);
    int _S643 = (I32_min((s_19->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_19->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S643 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    if(sunAlongCamera_0)
    {
        Rng_0 _S644 = *rng_11;
        Rng_0 _S645 = splitRng_0(&_S644, 1510U);
        Rng_0 segmentRng_0 = _S645;
        Rng_0 _S646 = *rng_11;
        Rng_0 _S647 = splitRng_0(&_S646, 1511U);
        Rng_0 _S648 = _S647;
        float3  _S649 = cameraSegmentSun_0(s_19, ph_1, bounds_9, drift_5, &segmentRng_0, &_S648, ro_9, rd_9, &(&r_13)->trackingSteps_0);
        (&r_13)->pathRadiance_0 = (&r_13)->pathRadiance_0 + _S649;
    }
    bool _S650;
    if(((&s_19->environment_0)->envMode_0) == int(1))
    {
        _S650 = (s_19->aerialMode_0) != int(0);
    }
    else
    {
        _S650 = false;
    }
    Rng_0 _S651 = *rng_11;
    Rng_0 _S652 = splitRng_0(&_S651, 2590U);
    Rng_0 airRng_0 = _S652;
    float3  env_0 = ro_9;
    float3  _S653 = rd_9;
    int bounce_0 = int(0);
    float3  throughput_1 = throughput_0;
    for(;;)
    {
        if(bounce_0 < int(256))
        {
        }
        else
        {
            break;
        }
        if(bounce_0 >= _S643)
        {
            (&r_13)->capped_0 = int(1);
            break;
        }
        float3  p_32;
        int layer_1;
        bool _S654 = sceneFreeFlight_0(s_19, bounds_9, drift_5, rng_11, env_0, _S653, &p_32, &layer_1, &(&r_13)->trackingSteps_0);
        if(!_S654)
        {
            bool _S655 = (s_19->airMapOn_0) != int(0);
            float groundLit_2;
            if(_S655)
            {
                float _S656 = groundShadow_0(&s_19->airMapIce_0, &s_19->airMapCu_0, env_0, _S653);
                groundLit_2 = _S656;
            }
            else
            {
                groundLit_2 = 1.0f;
            }
            bool _S657 = bounce_0 == int(0);
            float3  _S658 = environmentRadiance_0(&s_19->environment_0, env_0, _S653, _S657, groundLit_2);
            if(_S657)
            {
                sunAlongCamera_0 = _S650;
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                sunAlongCamera_0 = (s_19->aerialMode_0) >= int(2);
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                float u1_2 = randFloat_0(&airRng_0);
                float u2_2 = randFloat_0(&airRng_0);
                if(_S655)
                {
                    float3  _S659 = airShadowLoss_0(&(&s_19->environment_0)->sky_0, &s_19->airMapIce_0, &s_19->airMapCu_0, env_0, _S653, 1.00000001504746622e+30f, u2_2);
                    env_0 = max_0(_S658 - _S659, _S642);
                }
                else
                {
                    AirSegment_0 _S660 = airSegment_0(&(&s_19->environment_0)->sky_0, env_0.y, _S653, 1.00000001504746622e+30f, u1_2, u2_2);
                    AirSegment_0 _S661 = _S660;
                    float _S662 = airShadow_0(s_19, bounds_9, drift_5, &airRng_0, &_S661, env_0, _S653, &(&r_13)->trackingSteps_0);
                    env_0 = _S658 - _S660.airIn_0 * make_float3 (1.0f - _S662);
                }
            }
            else
            {
                env_0 = _S658;
            }
            (&r_13)->pathRadiance_0 = (&r_13)->pathRadiance_0 + throughput_1 * env_0;
            break;
        }
        (&r_13)->scatterEvents_0 = (&r_13)->scatterEvents_0 + int(1);
        bool _S663 = bounce_0 == int(0);
        bool _S664;
        if(_S663)
        {
            _S664 = _S650;
        }
        else
        {
            _S664 = false;
        }
        bool _S665;
        float3  throughput_2;
        if(_S664)
        {
            float u1_3 = randFloat_0(&airRng_0);
            float u2_3 = randFloat_0(&airRng_0);
            float dist_5 = length_0(p_32 - env_0);
            AirSegment_0 _S666 = airSegment_0(&(&s_19->environment_0)->sky_0, env_0.y, _S653, dist_5, u1_3, u2_3);
            if((s_19->aerialMode_0) >= int(2))
            {
                _S665 = (s_19->airMapOn_0) != int(0);
            }
            else
            {
                _S665 = false;
            }
            if(_S665)
            {
                float3  _S667 = airShadowLoss_0(&(&s_19->environment_0)->sky_0, &s_19->airMapIce_0, &s_19->airMapCu_0, env_0, _S653, dist_5, u2_3);
                throughput_2 = max_0(_S666.airIn_0 - _S667, _S642);
            }
            else
            {
                AirSegment_0 _S668 = _S666;
                float _S669 = airShadow_0(s_19, bounds_9, drift_5, &airRng_0, &_S668, env_0, _S653, &(&r_13)->trackingSteps_0);
                throughput_2 = _S666.airIn_0 * make_float3 (_S669);
            }
            (&r_13)->pathRadiance_0 = (&r_13)->pathRadiance_0 + throughput_1 * throughput_2;
            throughput_2 = throughput_1 * _S666.airT_0;
        }
        else
        {
            throughput_2 = throughput_1;
        }
        float3  _S670 = s_19->albedo_0;
        float3  matterAlbedo_1;
        PhaseInput_0 matterPhase_0;
        if(layer_1 != int(0))
        {
            matterPhase_0 = s_19->phase2_0;
            matterAlbedo_1 = s_19->albedo2_0;
        }
        else
        {
            matterPhase_0 = *ph_1;
            matterAlbedo_1 = _S670;
        }
        if(_S663)
        {
            _S665 = sunAlongCamera_0;
        }
        else
        {
            _S665 = false;
        }
        if(!_S665)
        {
            float3  _S671 = s_19->sunDir_0;
            float _S672 = sceneTransmittance_0(s_19, bounds_9, drift_5, rng_11, p_32 + s_19->sunDir_0 * make_float3 (s_19->shadowOffset_0), s_19->sunDir_0, &(&r_13)->trackingSteps_0);
            if(_S672 > 0.0f)
            {
                float _S673 = dot_0(_S653, _S671);
                PhaseInput_0 _S674 = matterPhase_0;
                float _S675 = phaseAt_0(&_S674, _S673);
                float3  _S676 = throughput_2 * matterAlbedo_1 * make_float3 (_S675) * make_float3 (_S672);
                float3  _S677 = sunIrradianceAt_0(s_19, p_32);
                (&r_13)->pathRadiance_0 = (&r_13)->pathRadiance_0 + _S676 * _S677;
            }
        }
        PhaseInput_0 _S678 = matterPhase_0;
        float w_9;
        float3  _S679 = samplePhaseDir_0(&_S678, rng_11, _S653, &w_9);
        float3  throughput_3 = throughput_2 * (matterAlbedo_1 * make_float3 (w_9));
        float3  _S680 = p_32;
        if(bounce_0 >= (s_19->rrStartBounce_0))
        {
            float p2_0 = clamp_0((F32_max((throughput_3.x), ((F32_max((throughput_3.y), (throughput_3.z)))))), 0.05000000074505806f, 1.0f);
            float _S681 = randFloat_0(rng_11);
            if(_S681 > p2_0)
            {
                break;
            }
            throughput_1 = throughput_3 / make_float3 (p2_0);
        }
        else
        {
            throughput_1 = throughput_3;
        }
        int bounce_1 = bounce_0 + int(1);
        env_0 = _S680;
        _S653 = _S679;
        bounce_0 = bounce_1;
    }
    return r_13;
}

static __device__ float3  renderSample_0(Scene_0 * s_20, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_10, StructuredBuffer<float2 > drift_6, float3  ro_10, float3  rd_10, uint seed_1)
{
    Rng_0 rng_12 = makeRng_0(seed_1);
    TraceResult_0 _S682 = trace_0(s_20, ph_2, bounds_10, drift_6, &rng_12, ro_10, rd_10);
    return _S682.pathRadiance_0;
}

extern "C" __global__ void renderRays(Scene_0 scene_0, PhaseInput_0 phase_0, StructuredBuffer<float> bounds_11, StructuredBuffer<float2 > drift_7, StructuredBuffer<float3 > origins_0, StructuredBuffer<float3 > directions_0, RWStructuredBuffer<float3 > outRadiance_0, uint seed_2, int count_0)
{
    int i_28 = int((blockIdx * blockDim + threadIdx).x);
    if(i_28 >= count_0)
    {
        return;
    }
    float3  * _S683 = (&(outRadiance_0)[i_28]);
    float3  _S684 = slang_ldg_0((&(origins_0)[i_28]));
    float3  _S685 = slang_ldg_0((&(directions_0)[i_28]));
    uint _S686 = seed_2 + uint(i_28);
    Scene_0 _S687 = scene_0;
    PhaseInput_0 _S688 = phase_0;
    float3  _S689 = renderSample_0(&_S687, &_S688, bounds_11, drift_7, _S684, _S685, _S686);
    *_S683 = _S689;
    return;
}

static __device__ void layerMapColumn_0(Medium_0 * med_0, StructuredBuffer<float2 > drift_8, LayerShadowMap_0 * m_15, int texel_0, RWStructuredBuffer<float> outTexels_0)
{
    int _S690 = m_15->smDimU_0;
    int stride_0 = m_15->smDimU_0 * m_15->smDimV_0;
    bool _S691;
    if(texel_0 < int(0))
    {
        _S691 = true;
    }
    else
    {
        _S691 = texel_0 >= stride_0;
    }
    if(_S691)
    {
        return;
    }
    int iu_1 = texel_0 % _S690;
    int iv_1 = texel_0 / _S690;
    float2  _S692 = m_15->smLo_0;
    float2  _S693 = m_15->smTexel_0;
    float2  _S694 = m_15->smCentre_0 + m_15->smAxisU_0 * make_float2 (m_15->smLo_0.x + (float(iu_1) + 0.5f) * m_15->smTexel_0.x);
    float2  _S695 = airMapAxisV_0(m_15);
    float2  q_14 = _S694 + _S695 * make_float2 (_S692.y + (float(iv_1) + 0.5f) * _S693.y);
    float3  base_0 = make_float3 (q_14.x, m_15->smBottom_0, q_14.y);
    float3  _S696 = m_15->smSun_0;
    int _S697 = m_15->smSlices_0;
    int _S698 = m_15->smSlices_0 - int(1);
    float _S699 = (m_15->smTop_0 - m_15->smBottom_0) / (float(_S698) * m_15->smSun_0.y);
    float _S700 = (F32_max((m_15->smStep_0), (1.0f)));
    float t0_5;
    float t1_5;
    bool _S701 = slabRange_0(med_0, base_0, m_15->smSun_0, &t0_5, &t1_5);
    *(&(outTexels_0)[_S698 * stride_0 + texel_0]) = 1.0f;
    int k_12 = _S697 - int(2);
    float tau_0 = 0.0f;
    for(;;)
    {
        if(k_12 >= int(0))
        {
        }
        else
        {
            break;
        }
        if(_S701)
        {
            _S691 = tau_0 < 12.0f;
        }
        else
        {
            _S691 = false;
        }
        float tau_1;
        if(_S691)
        {
            float _S702 = (F32_max((float(k_12) * _S699), (t0_5)));
            float _S703 = (F32_min((float(k_12 + int(1)) * _S699), (t1_5)));
            if(_S703 > _S702)
            {
                float _S704 = _S703 - _S702;
                int n_0 = clamp_1(int((F32_ceil((_S704 / _S700)))), int(1), int(1024));
                float _S705 = _S704 / float(n_0);
                int j_13 = int(0);
                tau_1 = tau_0;
                for(;;)
                {
                    if(j_13 < n_0)
                    {
                    }
                    else
                    {
                        break;
                    }
                    float _S706 = densityAt_0(med_0, drift_8, base_0 + _S696 * make_float3 (_S702 + (float(j_13) + 0.5f) * _S705));
                    float tau_2 = tau_1 + _S706 * _S705;
                    j_13 = j_13 + int(1);
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
        float * _S707 = (&(outTexels_0)[k_12 * stride_0 + texel_0]);
        float _S708;
        if(tau_1 < 12.0f)
        {
            _S708 = (F32_exp((- tau_1)));
        }
        else
        {
            _S708 = 0.0f;
        }
        *_S707 = _S708;
        k_12 = k_12 - int(1);
        tau_0 = tau_1;
    }
    return;
}

extern "C" __global__ void buildAirMap(Medium_0 medium_1, StructuredBuffer<float2 > drift_9, LayerShadowMap_0 map_0, RWStructuredBuffer<float> outTexels_1, int count_1)
{
    int i_29 = int((blockIdx * blockDim + threadIdx).x);
    if(i_29 >= count_1)
    {
        return;
    }
    Medium_0 _S709 = medium_1;
    LayerShadowMap_0 _S710 = map_0;
    layerMapColumn_0(&_S709, drift_9, &_S710, i_29, outTexels_1);
    return;
}

