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

static __device__ float2  max_0(float2  x_2, float2  y_0)
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
        *_slang_vector_get_element_ptr(&result_2, i_2) = (F32_max((_slang_vector_get_element(x_2, i_2)), (_slang_vector_get_element(y_0, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ float2  min_0(float2  x_3, float2  y_1)
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
        *_slang_vector_get_element_ptr(&result_3, i_3) = (F32_min((_slang_vector_get_element(x_3, i_3)), (_slang_vector_get_element(y_1, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ float dot_0(float2  x_4, float2  y_2)
{
    return x_4.x * y_2.x + x_4.y * y_2.y;
}

static __device__ float length_0(float2  x_5)
{
    return (F32_sqrt((dot_0(x_5, x_5))));
}

static __device__ float clamp_0(float x_6, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_6), (minBound_0)))), (maxBound_0)));
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
};

static __device__ float3  floor_0(float3  x_7)
{
    float3  result_4;
    int i_4 = int(0);
    for(;;)
    {
        if(i_4 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_4, i_4) = (F32_floor((_slang_vector_get_element(x_7, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static __device__ uint3  pcg3d_0(uint3  v_0)
{
    uint3  _S1 = v_0 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S2 = _S1;
    *&((&_S2)->x) = *&((&_S2)->x) + _S1.y * _S1.z;
    *&((&_S2)->y) = *&((&_S2)->y) + _S2.z * _S2.x;
    *&((&_S2)->z) = *&((&_S2)->z) + _S2.x * _S2.y;
    uint3  _S3 = _S2 ^ (_S2 >> make_uint3 (16U));
    _S2 = _S3;
    *&((&_S2)->x) = *&((&_S2)->x) + _S3.y * _S3.z;
    *&((&_S2)->y) = *&((&_S2)->y) + _S2.z * _S2.x;
    *&((&_S2)->z) = *&((&_S2)->z) + _S2.x * _S2.y;
    return _S2;
}

static __device__ float3  hash33_0(int3  c_0)
{
    uint3  h_0 = pcg3d_0(make_uint3 (uint(c_0.x), uint(c_0.y), uint(c_0.z)));
    float3  _S4 = make_float3 ((float)h_0.x, (float)h_0.y, (float)h_0.z);
    return _S4 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float dot_1(float3  x_8, float3  y_3)
{
    return x_8.x * y_3.x + x_8.y * y_3.y + x_8.z * y_3.z;
}

static __device__ float lerp_0(float x_9, float y_4, float s_0)
{
    return x_9 + (y_4 - x_9) * s_0;
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_0(p_0);
    int3  _S5 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S6 = u_0.x;
    float _S7 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_1(hash33_0(_S5), f_0), dot_1(hash33_0(_S5 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S6), lerp_0(dot_1(hash33_0(_S5 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S5 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S6), _S7), lerp_0(lerp_0(dot_1(hash33_0(_S5 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S5 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S6), lerp_0(dot_1(hash33_0(_S5 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S5 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S6), _S7), u_0.z);
}

static __device__ float2  orgWarpOffset_0(Organization_0 * o_0, float2  g_0)
{
    float2  s_1 = g_0 / make_float2 (2.5f);
    float _S8 = s_1.x;
    float _S9 = s_1.y;
    return make_float2 (o_0->ogWarp_0) * make_float2 (gradientNoise_0(make_float3 (_S8, 0.37000000476837158f, _S9)), gradientNoise_0(make_float3 (_S8 + 17.10000038146972656f, 5.82999992370605469f, _S9 - 9.39999961853027344f)));
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
        float2  _S10 = orgWarpOffset_0(o_1, g_1);
        g_2 = g_1 + _S10;
    }
    else
    {
        g_2 = g_1;
    }
    return g_2;
}

static __device__ float2  floor_1(float2  x_10)
{
    float2  result_5;
    int i_5 = int(0);
    for(;;)
    {
        if(i_5 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_5, i_5) = (F32_floor((_slang_vector_get_element(x_10, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
}

static __device__ uint2  pcg2d_0(uint2  v_1)
{
    uint2  _S11 = v_1 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S12 = _S11;
    *&((&_S12)->x) = *&((&_S12)->x) + _S11.y * 1664525U;
    *&((&_S12)->y) = *&((&_S12)->y) + _S12.x * 1664525U;
    uint2  _S13 = _S12 ^ (_S12 >> make_uint2 (16U));
    _S12 = _S13;
    *&((&_S12)->x) = *&((&_S12)->x) + _S13.y * 1664525U;
    *&((&_S12)->y) = *&((&_S12)->y) + _S12.x * 1664525U;
    uint2  _S14 = _S12 ^ (_S12 >> make_uint2 (16U));
    _S12 = _S14;
    return _S14;
}

static __device__ float2  hash22_0(int2  c_1, uint salt_0)
{
    uint2  h_1 = pcg2d_0(make_uint2 (uint(c_1.x), uint(c_1.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S15 = make_float2 ((float)h_1.x, (float)h_1.y);
    return _S15 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float convLife_0(float u_1)
{
    float _S16 = 1.0f - u_1;
    return 6.75f * u_1 * _S16 * _S16;
}

static __device__ float convVigour_0(ConvectionInput_0 * c_2, int2  slot_0)
{
    float2  h_2 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_0(0.34999999403953552f, 1.0f, h_2.y);
}

static __device__ float2  orgJitter_0(Organization_0 * o_2, float jitter_0)
{
    float _S17;
    if((o_2->ogOn_0) != int(0))
    {
        _S17 = jitter_0 * (1.0f - o_2->ogCoherence_0);
    }
    else
    {
        _S17 = jitter_0;
    }
    return make_float2 (jitter_0, _S17);
}

static __device__ float2  convCellCentre_0(ConvectionInput_0 * c_3, int2  slot_1)
{
    float2  j_0 = hash22_0(slot_1, 1759714724U) - make_float2 (0.5f);
    float2  _S18 = make_float2 ((float)slot_1.x, (float)slot_1.y);
    float2  _S19 = _S18 + make_float2 (0.5f);
    float2  _S20 = orgJitter_0(&c_3->cvOrg_0, 0.69999998807907104f);
    return _S19 + j_0 * _S20;
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
        float2  _S21;
        if(dist_0 > 9.99999997475242708e-07f)
        {
            _S21 = d_0 * make_float2 (6.0f * t_1 * (1.0f - t_1) / (band_0 * dist_0));
        }
        else
        {
            _S21 = make_float2 (0.0f, 0.0f);
        }
        *gKeep_0 = _S21;
    }
    return;
}

static __device__ float2  lerp_1(float2  x_12, float2  y_5, float2  s_2)
{
    return x_12 + (y_5 - x_12) * s_2;
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
    bool _S22;
    if((o_4->ogOn_0) == int(0))
    {
        _S22 = true;
    }
    else
    {
        _S22 = (o_4->ogWaveAmp_0) <= 0.0f;
    }
    if(_S22)
    {
        return 1.0f;
    }
    float2  _S23 = o_4->ogWaveK_0;
    float s_4 = 2.0f * (F32_frac((dot_0(q_1, o_4->ogWaveK_0)))) - 1.0f;
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
    float _S24 = o_4->ogWaveAmp_0;
    *grad_0 = _S23 * make_float2 (o_4->ogWaveAmp_0 * dCrest_0 * dTri_0);
    return 1.0f - _S24 * (1.0f - crest_0);
}

static __device__ float convOrganize_0(ConvectionInput_0 * c_5, float2  q_2, float kTop_0, float kNext_0, float2  gkTop_0, float2  gkNext_0, float keep_1, float2  gKeep_1, float w_0, float2  gp_1, float2  * grad_1)
{
    float _S25 = c_5->cvLacunarity_0;
    float2  _S26;
    float _S27;
    if((c_5->cvLacunarity_0) > 0.0f)
    {
        float fill_0 = lerp_0(w_0, 0.40000000596046448f, _S25);
        float _S28 = fill_0 * keep_1;
        _S26 = gp_1 * make_float2 (1.0f - _S25) * make_float2 (keep_1) + gKeep_1 * make_float2 (fill_0);
        _S27 = _S28;
    }
    else
    {
        _S26 = gp_1;
        _S27 = w_0;
    }
    float _S29 = c_5->cvPolarity_0;
    bool _S30;
    if((c_5->cvPolarity_0) > 0.0f)
    {
        _S30 = (c_5->cvGapWidth_0) > 0.0f;
    }
    else
    {
        _S30 = false;
    }
    if(_S30)
    {
        float2  _S31 = make_float2 (0.0f, 0.0f);
        float2  gcn_0;
        float cn_0;
        if(kTop_0 > 0.0f)
        {
            float2  _S32 = (gkTop_0 * make_float2 (kNext_0) - gkNext_0 * make_float2 (kTop_0)) / make_float2 (kTop_0 * kTop_0);
            cn_0 = 1.0f - kNext_0 / kTop_0;
            gcn_0 = _S32;
        }
        else
        {
            cn_0 = 0.0f;
            gcn_0 = _S31;
        }
        float ramp_0 = 0.5f * c_5->cvGapWidth_0;
        float t_2 = saturate_0((cn_0 - ramp_0) / ramp_0);
        float s_5 = lerp_0(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S29);
        float _S33 = _S27 * s_5;
        _S26 = _S26 * make_float2 (s_5) + gcn_0 * make_float2 (_S27 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S29));
        _S27 = _S33;
    }
    float2  _S34 = orgGradToWorld_0(&c_5->cvOrg_0, _S26, c_5->cvSpacing_0);
    *grad_1 = _S34;
    float2  gm_0;
    float _S35 = orgWave_0(&c_5->cvOrg_0, q_2, &gm_0);
    *grad_1 = _S34 * make_float2 (_S35) + gm_0 * make_float2 (_S27);
    return _S27 * _S35;
}

static __device__ float convUpdraftGradT_0(ConvectionInput_0 * c_6, float2  q_3, float2  * grad_2)
{
    float2  goTop_0;
    float2  _S36 = orgPattern_0(&c_6->cvOrg_0, q_3, c_6->cvSpacing_0);
    float2  _S37 = floor_1(_S36);
    int2  _S38 = make_int2 ((int)_S37.x, (int)_S37.y);
    float2  _S39 = make_float2 (0.0f, 0.0f);
    float keep_2 = 1.0f;
    float2  gKeep_2 = _S39;
    float oTop_0 = 0.0f;
    float2  goTop_1 = _S39;
    float oNext_0 = 0.0f;
    float kTop_1 = 0.0f;
    float2  gkTop_1 = _S39;
    float kNext_1 = 0.0f;
    float2  goNext_0 = _S39;
    float2  gkNext_1 = _S39;
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
            int2  slot_2 = _S38 + make_int2 (i_6, j_1);
            float _S40 = convVigour_0(c_6, slot_2);
            if(_S40 <= 0.0f)
            {
                i_6 = i_6 + int(1);
                continue;
            }
            float2  _S41 = convCellCentre_0(c_6, slot_2);
            float2  d_1 = _S36 - _S41;
            float d2_2 = dot_0(d_1, d_1);
            float ko_0 = _S40 * convBump_0(d2_2, 0.75f);
            float kk_0 = _S40 * convBump_0(d2_2, 1.04999995231628418f);
            convHole_0(c_6, d_1, d2_2, _S40, &keep_2, &gKeep_2);
            float2  gko_0;
            if(d2_2 < 0.5625f)
            {
                gko_0 = d_1 * make_float2 (-4.0f * _S40 * (1.0f - d2_2 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S39;
            }
            float2  gkk_0;
            if(d2_2 < 1.10249984264373779f)
            {
                gkk_0 = d_1 * make_float2 (-4.0f * _S40 * (1.0f - d2_2 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S39;
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
                float _S42 = oTop_2;
                float2  _S43 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S42;
                goNext_2 = _S43;
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
                float _S44 = kTop_3;
                float2  _S45 = gkTop_3;
                kTop_3 = kTop_2;
                gkTop_3 = gkTop_2;
                kNext_3 = _S44;
                gkNext_3 = _S45;
            }
            oTop_1 = oTop_2;
            goTop_0 = goTop_2;
            oNext_1 = oNext_2;
            kTop_2 = kTop_3;
            gkTop_2 = gkTop_3;
            kNext_2 = kNext_3;
            goNext_1 = goNext_2;
            gkNext_2 = gkNext_3;
            i_6 = i_6 + int(1);
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
    float _S46 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_1 - kNext_1;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_0 = _S39;
    }
    float2  gClosed_0 = gkTop_1 - gkNext_1;
    float _S47 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_0(_S46, closedField_0, c_6->cvPolarity_0), lerp_1(goTop_0, gClosed_0, make_float2 (c_6->cvPolarity_0)), grad_2);
    return _S47;
}

static __device__ float convUpdraftGradT_1(ConvectionInput_0 * c_7, float2  q_4, float2  * grad_3)
{
    float2  goTop_3;
    float2  _S48 = orgPattern_0(&c_7->cvOrg_0, q_4, c_7->cvSpacing_0);
    float2  _S49 = floor_1(_S48);
    int2  _S50 = make_int2 ((int)_S49.x, (int)_S49.y);
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
            int2  slot_3 = _S50 + make_int2 (i_7, j_3);
            float _S51 = convVigour_0(c_7, slot_3);
            if(_S51 <= 0.0f)
            {
                i_7 = i_7 + int(1);
                continue;
            }
            float2  _S52 = convCellCentre_0(c_7, slot_3);
            float2  d_2 = _S48 - _S52;
            float d2_3 = dot_0(d_2, d_2);
            float ko_1 = _S51 * convBump_0(d2_3, 0.75f);
            float kk_1 = _S51 * convBump_0(d2_3, 1.04999995231628418f);
            float2  gko_1;
            if(d2_3 < 0.5625f)
            {
                gko_1 = d_2 * make_float2 (-4.0f * _S51 * (1.0f - d2_3 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_1 = gKeep_3;
            }
            float2  gkk_1;
            if(d2_3 < 1.10249984264373779f)
            {
                gkk_1 = d_2 * make_float2 (-4.0f * _S51 * (1.0f - d2_3 / 1.10249984264373779f) / 1.10249984264373779f);
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
                float _S53 = oTop_5;
                float2  _S54 = goTop_5;
                oTop_5 = oTop_4;
                goTop_5 = goTop_3;
                oNext_5 = _S53;
                goNext_5 = _S54;
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
                float _S55 = kTop_6;
                float2  _S56 = gkTop_6;
                kTop_6 = kTop_5;
                gkTop_6 = gkTop_5;
                kNext_6 = _S55;
                gkNext_6 = _S56;
            }
            oTop_4 = oTop_5;
            goTop_3 = goTop_5;
            oNext_4 = oNext_5;
            kTop_5 = kTop_6;
            gkTop_5 = gkTop_6;
            kNext_5 = kNext_6;
            goNext_4 = goNext_5;
            gkNext_5 = gkNext_6;
            i_7 = i_7 + int(1);
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
    float _S57 = (F32_min((openRaw_1), (1.0f)));
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
    float _S58 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_0(_S57, closedField_1, c_7->cvPolarity_0), lerp_1(goTop_3, gClosed_1, make_float2 (c_7->cvPolarity_0)), grad_3);
    return _S58;
}

static __device__ float2  convCellCentrePlain_0(int2  slot_4)
{
    float2  _S59 = make_float2 ((float)slot_4.x, (float)slot_4.y);
    return _S59 + make_float2 (0.5f) + (hash22_0(slot_4, 1759714724U) - make_float2 (0.5f)) * make_float2 (0.69999998807907104f);
}

static __device__ float convUpdraftGradT_2(ConvectionInput_0 * c_8, float2  q_5, float2  * grad_4)
{
    float2  goTop_6;
    float _S60 = c_8->cvSpacing_0;
    float2  _S61 = q_5 / make_float2 (c_8->cvSpacing_0);
    float2  _S62 = floor_1(_S61);
    int2  _S63 = make_int2 ((int)_S62.x, (int)_S62.y);
    float2  _S64 = make_float2 (0.0f, 0.0f);
    float oTop_6 = 0.0f;
    float2  goTop_7 = _S64;
    float oNext_6 = 0.0f;
    float kTop_7 = 0.0f;
    float2  gkTop_7 = _S64;
    float kNext_7 = 0.0f;
    float2  goNext_6 = _S64;
    float2  gkNext_7 = _S64;
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
            int2  slot_5 = _S63 + make_int2 (i_8, j_5);
            float _S65 = convVigour_0(c_8, slot_5);
            if(_S65 <= 0.0f)
            {
                i_8 = i_8 + int(1);
                continue;
            }
            float2  d_3 = _S61 - convCellCentrePlain_0(slot_5);
            float d2_4 = dot_0(d_3, d_3);
            float ko_2 = _S65 * convBump_0(d2_4, 0.75f);
            float kk_2 = _S65 * convBump_0(d2_4, 1.04999995231628418f);
            float2  gko_2;
            if(d2_4 < 0.5625f)
            {
                gko_2 = d_3 * make_float2 (-4.0f * _S65 * (1.0f - d2_4 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_2 = _S64;
            }
            float2  gkk_2;
            if(d2_4 < 1.10249984264373779f)
            {
                gkk_2 = d_3 * make_float2 (-4.0f * _S65 * (1.0f - d2_4 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_2 = _S64;
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
                float _S66 = oTop_8;
                float2  _S67 = goTop_8;
                oTop_8 = oTop_7;
                goTop_8 = goTop_6;
                oNext_8 = _S66;
                goNext_8 = _S67;
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
                float _S68 = kTop_9;
                float2  _S69 = gkTop_9;
                kTop_9 = kTop_8;
                gkTop_9 = gkTop_8;
                kNext_9 = _S68;
                gkNext_9 = _S69;
            }
            oTop_7 = oTop_8;
            goTop_6 = goTop_8;
            oNext_7 = oNext_8;
            kTop_8 = kTop_9;
            gkTop_8 = gkTop_9;
            kNext_8 = kNext_9;
            goNext_7 = goNext_8;
            gkNext_8 = gkNext_9;
            i_8 = i_8 + int(1);
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
    float _S70 = (F32_min((openRaw_2), (1.0f)));
    float closedField_2 = kTop_7 - kNext_7;
    if(openRaw_2 < 1.0f)
    {
        goTop_6 = goNext_6 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_6 = _S64;
    }
    float2  gClosed_2 = gkTop_7 - gkNext_7;
    float _S71 = c_8->cvPolarity_0;
    *grad_4 = lerp_1(goTop_6, gClosed_2, make_float2 (c_8->cvPolarity_0)) / make_float2 (_S60);
    return lerp_0(_S70, closedField_2, _S71);
}

static __device__ float smoothstep_0(float min_1, float max_1, float x_13)
{
    float _S72 = saturate_0((x_13 - min_1) / (max_1 - min_1));
    return _S72 * _S72 * (3.0f - (_S72 + _S72));
}

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S73 = __ldg(&(ptr_0->x));
    float _S74 = __ldg(&(ptr_0->y));
    float _S75 = __ldg(&(ptr_0->z));
    return make_float3 (_S73, _S74, _S75);
}

static __device__ float convCeiling_0(ConvectionInput_0 * c_9)
{
    float _S76 = c_9->cvBillow_0;
    float field_0 = c_9->cvDepth_0 + c_9->cvBillow_0;
    float _S77 = c_9->cvHeroTop_0;
    float hero_0;
    if((c_9->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S77 + _S76 * c_9->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    return (F32_max((field_0), (hero_0)));
}

static __device__ float convLift_0(ConvectionInput_0 * c_10, float above_0, float k_1)
{
    return (F32_min((c_10->cvBillow_0 * k_1 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_0(0.60000002384185791f, 1.0f, saturate_0(above_0 / (F32_max((c_10->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_0), (0.0f))))));
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_11, float2  q_6, float2  * grad_5)
{
    if(((&c_11->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S78 = convUpdraftGradT_2(c_11, q_6, grad_5);
        return _S78;
    }
    if((c_11->cvLacunarity_0) <= 0.0f)
    {
        float _S79 = convUpdraftGradT_1(c_11, q_6, grad_5);
        return _S79;
    }
    float _S80 = convUpdraftGradT_0(c_11, q_6, grad_5);
    return _S80;
}

static __device__ float convTowerHeight_0(ConvectionInput_0 * c_12, float w_1)
{
    float cover_0 = clamp_0(c_12->cvCoverage_0, 0.0f, 1.0f);
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
    return c_12->cvDepth_0 * (F32_pow((u_2), (c_12->cvShape_0)));
}

static __device__ float convNeededUpdraft_0(ConvectionInput_0 * c_13, float above_1)
{
    float cover_1 = clamp_0(c_13->cvCoverage_0, 0.0f, 1.0f);
    bool _S81;
    if(cover_1 <= 0.0f)
    {
        _S81 = true;
    }
    else
    {
        _S81 = (c_13->cvDepth_0) <= 0.0f;
    }
    if(_S81)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_13->cvDepth_0), (1.0f / (F32_max((c_13->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_14)
{
    float _S82 = c_14->cvSpacing_0;
    float cap_0 = 7.0f / c_14->cvSpacing_0;
    if(((&c_14->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_0;
    }
    float _S83 = c_14->cvLacunarity_0;
    float cap_1;
    if((c_14->cvLacunarity_0) > 0.0f)
    {
        cap_1 = cap_0 + 1.5f / (0.15000000596046448f * _S83 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S82);
    }
    else
    {
        cap_1 = cap_0;
    }
    float _S84 = c_14->cvGapWidth_0;
    if((c_14->cvGapWidth_0) > 0.0f)
    {
        cap_1 = cap_1 + 14.25f * c_14->cvPolarity_0 / (0.5f * _S84 * _S82);
    }
    return cap_1 + 3.0f * (&c_14->cvOrg_0)->ogWaveAmp_0 * length_0((&c_14->cvOrg_0)->ogWaveK_0);
}

static __device__ float convSurfaceDistance_0(float v_2, float delta_0, float slope_0)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_0 * slope_0 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_4 = num_0 / den_0;
    float _S85;
    if(v_2 >= 0.0f)
    {
        _S85 = d_4;
    }
    else
    {
        _S85 = - d_4;
    }
    return _S85;
}

static __device__ float3  convTwist_0(float3  x_14)
{
    float _S86 = x_14.x;
    float _S87 = x_14.y;
    float _S88 = x_14.z;
    return make_float3 (0.0f * _S86 + 0.80000001192092896f * _S87 + 0.60000002384185791f * _S88, -0.80000001192092896f * _S86 + 0.36000001430511475f * _S87 - 0.47999998927116394f * _S88, -0.60000002384185791f * _S86 - 0.47999998927116394f * _S87 + 0.63999998569488525f * _S88);
}

static __device__ float convPuffs_0(float3  x_15)
{
    float3  fl_0 = floor_0(x_15);
    int3  _S89 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_1 = x_15 - fl_0;
    int dz_0;
    if((f_1.x) < 0.5f)
    {
        dz_0 = int(-1);
    }
    else
    {
        dz_0 = int(0);
    }
    int dy_0;
    if((f_1.y) < 0.5f)
    {
        dy_0 = int(-1);
    }
    else
    {
        dy_0 = int(0);
    }
    int dx_0;
    if((f_1.z) < 0.5f)
    {
        dx_0 = int(-1);
    }
    else
    {
        dx_0 = int(0);
    }
    int3  _S90 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S90 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S91 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_5 = _S91 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S89 + off_0) - f_1;
                float _S92 = (F32_min((nearest_1), (dot_1(d_5, d_5))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S92;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_15, float3  p_1, float scale_0)
{
    float3  _S93 = make_float3 (p_1.x, p_1.y - c_15->cvRise_0, p_1.z) / make_float3 (scale_0);
    int i_9 = int(0);
    float3  x_16 = _S93;
    float amp_0 = 0.60000002384185791f;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_9 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_9 >= (c_15->cvOctaves_0))
        {
            break;
        }
        float3  x_17 = convTwist_0(x_16);
        float sum_1 = sum_0 + amp_0 * convPuffs_0(x_17);
        float norm_1 = norm_0 + amp_0;
        float3  x_18 = x_17 * make_float3 (2.17000007629394531f);
        float amp_1 = amp_0 * 0.55000001192092896f;
        i_9 = i_9 + int(1);
        x_16 = x_18;
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

static __device__ float convInside_0(ConvectionInput_0 * c_16, float d_6, float lift_0, float3  x_19, float scale_1)
{
    float _S94 = d_6 + lift_0;
    if(_S94 <= 0.0f)
    {
        return _S94;
    }
    if((d_6 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S95 = convBillow_0(c_16, x_19, scale_1);
    return d_6 + lift_0 * _S95;
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_17)
{
    return c_17->cvHeroRadius_0 + 1.5f * c_17->cvBillow_0 * c_17->cvHeroBillow_0 + 24.0f;
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_18, float r_1)
{
    float _S96 = c_18->cvHeroTop_0;
    bool _S97;
    if((c_18->cvHeroTop_0) <= 0.0f)
    {
        _S97 = true;
    }
    else
    {
        _S97 = r_1 >= (c_18->cvHeroRadius_0);
    }
    if(_S97)
    {
        return 0.0f;
    }
    return _S96 * (F32_pow((1.0f - r_1 * r_1 / (c_18->cvHeroRadius_0 * c_18->cvHeroRadius_0)), (c_18->cvShape_0)));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_19, float above_2)
{
    float _S98 = c_19->cvHeroTop_0;
    bool _S99;
    if((c_19->cvHeroTop_0) <= 0.0f)
    {
        _S99 = true;
    }
    else
    {
        _S99 = above_2 >= _S98;
    }
    if(_S99)
    {
        return -1.0f;
    }
    return c_19->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S98), (1.0f / (F32_max((c_19->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_20, float3  p_2, float above_3)
{
    float2  rel_0 = float2 {p_2.x, p_2.z} - c_20->cvHeroAt_0;
    float r_2 = length_0(rel_0);
    float _S100 = convHeroReach_0(c_20);
    if(r_2 >= _S100)
    {
        return -1.00000001504746622e+30f;
    }
    float _S101 = convHeroHeight_0(c_20, r_2);
    float v_3 = _S101 - above_3;
    float _S102 = convHeroRadiusAt_0(c_20, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_7;
    if(_S102 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_7 = v_3;
    }
    else
    {
        float h_3 = _S102 - r_2;
        float d_8 = convSurfaceDistance_0(v_3, h_3, 1.0f);
        if((F32_abs((v_3))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_8 * (d_8 / v_3);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_3))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_8 * (d_8 / h_3);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S103 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S103;
        d_7 = d_8;
    }
    float2  radial_0;
    if(r_2 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / make_float2 (r_2);
    }
    else
    {
        radial_0 = make_float2 (0.0f, 0.0f);
    }
    float2  at_0 = rel_0 + radial_0 * make_float2 (shiftOut_0);
    float3  x_20 = make_float3 (at_0.x, p_2.y + shiftUp_0, at_0.y) + c_20->cvHeroSeed_0;
    float _S104 = c_20->cvHeroBillow_0;
    float _S105 = convLift_0(c_20, above_3, c_20->cvHeroBillow_0);
    float _S106 = convInside_0(c_20, d_7, _S105, x_20, c_20->cvBillowScale_0 * _S104);
    return _S106;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_21, float3  p_3)
{
    float _S107 = p_3.y;
    float above_4 = _S107 - c_21->cvBase_0;
    bool _S108;
    if(above_4 < 0.0f)
    {
        _S108 = true;
    }
    else
    {
        float _S109 = convCeiling_0(c_21);
        _S108 = above_4 > _S109;
    }
    if(_S108)
    {
        return 0.0f;
    }
    float _S110 = convLift_0(c_21, above_4, 1.0f - 0.60000002384185791f * c_21->cvLacunarity_0);
    float inside_0;
    if((c_21->cvHeroAlone_0) == int(0))
    {
        float2  q_7 = float2 {p_3.x, p_3.z} - c_21->cvDrift_0;
        float2  slope_1;
        float _S111 = convUpdraftGrad_0(c_21, q_7, &slope_1);
        float _S112 = convTowerHeight_0(c_21, _S111);
        float v_4 = _S112 - above_4;
        float _S113 = convNeededUpdraft_0(c_21, above_4);
        float delta_1 = _S111 - _S113;
        float _S114 = length_0(slope_1);
        float _S115 = convSlopeCap_0(c_21);
        float d_9 = convSurfaceDistance_0(v_4, delta_1, (F32_min((_S114), (_S115))));
        if((d_9 + _S110) > 0.0f)
        {
            if((F32_abs((v_4))) > 9.99999997475242708e-07f)
            {
                inside_0 = d_9 * (d_9 / v_4);
            }
            else
            {
                inside_0 = 0.0f;
            }
            float2  shiftAcross_0;
            if((F32_abs((delta_1))) > 9.999999960041972e-13f)
            {
                shiftAcross_0 = slope_1 * make_float2 (- d_9 * (d_9 / delta_1));
            }
            else
            {
                shiftAcross_0 = make_float2 (0.0f, 0.0f);
            }
            float _S116 = convInside_0(c_21, d_9, _S110, make_float3 (q_7.x + shiftAcross_0.x, _S107 + inside_0, q_7.y + shiftAcross_0.y), c_21->cvBillowScale_0);
            inside_0 = _S116;
        }
        else
        {
            inside_0 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    if((c_21->cvHeroTop_0) > 0.0f)
    {
        _S108 = inside_0 < 12.0f;
    }
    else
    {
        _S108 = false;
    }
    if(_S108)
    {
        float _S117 = convHeroInside_0(c_21, p_3, above_4);
        inside_0 = (F32_max((inside_0), (_S117)));
    }
    if(inside_0 <= 0.0f)
    {
        return 0.0f;
    }
    return c_21->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_0);
}

extern "C" __global__ void convDensityAt(ConvectionInput_0 c_22, StructuredBuffer<float3 > points_0, RWStructuredBuffer<float> outDensity_0, int count_0)
{
    int i_10 = int((blockIdx * blockDim + threadIdx).x);
    if(i_10 >= count_0)
    {
        return;
    }
    float * _S118 = (&(outDensity_0)[i_10]);
    float3  _S119 = slang_ldg_0((&(points_0)[i_10]));
    ConvectionInput_0 _S120 = c_22;
    float _S121 = convectionDensity_0(&_S120, _S119);
    *_S118 = _S121;
    return;
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
    Organization_0 _S122 = flat_0;
    float2  _S123 = orgPattern_0(&_S122, q0_0, spacing_2);
    Organization_0 _S124 = flat_0;
    float2  _S125 = orgPattern_0(&_S124, q1_0, spacing_2);
    float2  _S126 = make_float2 (q0_0.x, q1_0.y);
    Organization_0 _S127 = flat_0;
    float2  _S128 = orgPattern_0(&_S127, _S126, spacing_2);
    float2  _S129 = make_float2 (q1_0.x, q0_0.y);
    Organization_0 _S130 = flat_0;
    float2  _S131 = orgPattern_0(&_S130, _S129, spacing_2);
    float grow_0 = o_5->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S123.x)))), ((F32_abs((_S123.y))))))), ((F32_max(((F32_abs((_S125.x)))), ((F32_abs((_S125.y)))))))));
    *a_0 = min_0(min_0(_S123, _S128), min_0(_S131, _S125)) - make_float2 (grow_0);
    *b_0 = max_0(max_0(_S123, _S128), max_0(_S131, _S125)) + make_float2 (grow_0);
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_23, int2  slot_6, float2  a_1, float2  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S132 = convVigour_0(c_23, slot_6);
    if(_S132 <= 0.0f)
    {
        return;
    }
    float2  _S133 = convCellCentre_0(c_23, slot_6);
    float2  _S134 = a_1 - _S133;
    float2  nearGap_0 = max_0(max_0(_S134, _S133 - b_1), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_0(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_0(abs_0(_S134), abs_0(b_1 - _S133));
    float oHi_0 = _S132 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S132 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S132 * convBump_0(dot_0(farGap_0, farGap_0), 1.04999995231628418f);
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

static __device__ float convUpdraftBound_0(ConvectionInput_0 * c_24, float2  q0_1, float2  q1_1)
{
    float2  a_2;
    float2  b_2;
    orgPatternBox_0(&c_24->cvOrg_0, q0_1, q1_1, c_24->cvSpacing_0, &a_2, &b_2);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    float2  _S135 = floor_1((a_2 + b_2) * make_float2 (0.5f));
    int2  _S136 = make_int2 ((int)_S135.x, (int)_S135.y);
    float2  _S137 = make_float2 ((float)_S136.x, (float)_S136.y);
    float2  highEdge_0 = _S137 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S138;
    if(all_0(a_2 >= (_S137 - make_float2 (0.00009999999747379f))))
    {
        _S138 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S138 = false;
    }
    int j_7;
    int i_11;
    if(_S138)
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
            i_11 = int(-1);
            for(;;)
            {
                if(i_11 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_24, _S136 + make_int2 (i_11, j_7), a_2, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        float2  _S139 = floor_1(a_2);
        int2  _S140 = make_int2 ((int)_S139.x, (int)_S139.y);
        int2  _S141 = make_int2 (int(1), int(1));
        int2  i0_0 = _S140 - _S141;
        float2  _S142 = floor_1(b_2);
        int2  _S143 = make_int2 ((int)_S142.x, (int)_S142.y);
        int2  _S144 = _S143 + _S141;
        int _S145 = i0_0.y;
        j_7 = _S145;
        for(;;)
        {
            if(j_7 <= (_S144.y))
            {
                _S138 = j_7 <= (_S145 + int(32));
            }
            else
            {
                _S138 = false;
            }
            if(_S138)
            {
            }
            else
            {
                break;
            }
            int _S146 = i0_0.x;
            i_11 = _S146;
            for(;;)
            {
                bool _S147;
                if(i_11 <= (_S144.x))
                {
                    _S147 = i_11 <= (_S146 + int(32));
                }
                else
                {
                    _S147 = false;
                }
                if(_S147)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_24, make_int2 (i_11, j_7), a_2, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_0((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_24->cvPolarity_0);
    float _S148 = c_24->cvLacunarity_0;
    float field_2;
    if((c_24->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_0(field_1, 0.40000000596046448f, _S148);
    }
    else
    {
        field_2 = field_1;
    }
    return field_2 + 0.00000999999974738f;
}

static __device__ float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S149;
    if(vMin_0 <= 0.0f)
    {
        _S149 = true;
    }
    else
    {
        _S149 = hMin_0 <= 0.0f;
    }
    if(_S149)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_25, float3  lo_0, float3  hi_0)
{
    float low_0 = lo_0.y - c_25->cvBase_0;
    float high_0 = hi_0.y - c_25->cvBase_0;
    float _S150 = convCeiling_0(c_25);
    bool _S151;
    if(high_0 < 0.0f)
    {
        _S151 = true;
    }
    else
    {
        _S151 = low_0 > _S150;
    }
    if(_S151)
    {
        return 0.0f;
    }
    float _S152 = (F32_max((low_0), (0.0f)));
    float _S153 = (F32_min((high_0), (_S150)));
    float _S154 = convLift_0(c_25, _S153, 1.0f);
    float inside_1;
    if((c_25->cvHeroAlone_0) == int(0))
    {
        float _S155 = convUpdraftBound_0(c_25, float2 {lo_0.x, lo_0.z} - c_25->cvDrift_0, float2 {hi_0.x, hi_0.z} - c_25->cvDrift_0);
        float _S156 = convTowerHeight_0(c_25, _S155);
        float _S157 = convNeededUpdraft_0(c_25, _S152);
        if(_S155 < _S157)
        {
            float _S158 = convSlopeCap_0(c_25);
            inside_1 = _S154 - convDistanceFloor_0(_S152 - _S156, (_S157 - _S155) / _S158);
        }
        else
        {
            inside_1 = (F32_max((_S156 - _S152), (0.0f))) + _S154;
        }
    }
    else
    {
        inside_1 = -1.00000001504746622e+30f;
    }
    if((c_25->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_0(max_0(max_0(float2 {lo_0.x, lo_0.z} - c_25->cvHeroAt_0, c_25->cvHeroAt_0 - float2 {hi_0.x, hi_0.z}), make_float2 (0.0f, 0.0f)));
        float _S159 = convHeroReach_0(c_25);
        if(rMin_0 < _S159)
        {
            float _S160 = convHeroHeight_0(c_25, rMin_0);
            float _S161 = convHeroRadiusAt_0(c_25, _S152);
            float _S162 = convLift_0(c_25, _S153, c_25->cvHeroBillow_0);
            bool _S163 = _S161 < 0.0f;
            if(_S163)
            {
                _S151 = true;
            }
            else
            {
                _S151 = rMin_0 >= _S161;
            }
            float heroIn_0;
            if(_S151)
            {
                if(_S163)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S161;
                }
                heroIn_0 = _S162 - convDistanceFloor_0(_S152 - _S160, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S160 - _S152), (0.0f))) + _S162;
            }
            inside_1 = (F32_max((inside_1), (heroIn_0)));
        }
    }
    float inside_2 = inside_1 + 0.00100000004749745f;
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_25->cvSigma_0 * (F32_sqrt((saturate_0(_S153 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2) * 1.00001001358032227f;
}

extern "C" __global__ void convBoundOver(ConvectionInput_0 c_26, StructuredBuffer<float3 > boxLo_0, StructuredBuffer<float3 > boxHi_0, RWStructuredBuffer<float> outBound_0, int count_1)
{
    int i_12 = int((blockIdx * blockDim + threadIdx).x);
    if(i_12 >= count_1)
    {
        return;
    }
    float * _S164 = (&(outBound_0)[i_12]);
    float3  _S165 = slang_ldg_0((&(boxLo_0)[i_12]));
    float3  _S166 = slang_ldg_0((&(boxHi_0)[i_12]));
    ConvectionInput_0 _S167 = c_26;
    float _S168 = convectionBound_0(&_S167, _S165, _S166);
    *_S164 = _S168;
    return;
}

static __device__ float convUpdraft_0(ConvectionInput_0 * c_27, float2  q_8)
{
    float2  unused_0;
    float _S169 = convUpdraftGrad_0(c_27, q_8, &unused_0);
    return _S169;
}

extern "C" __global__ void convUpdraftAt(ConvectionInput_0 c_28, StructuredBuffer<float2 > points_1, RWStructuredBuffer<float> outUpdraft_0, int count_2)
{
    int i_13 = int((blockIdx * blockDim + threadIdx).x);
    if(i_13 >= count_2)
    {
        return;
    }
    float * _S170 = (&(outUpdraft_0)[i_13]);
    float2  _S171 = __ldg((&(points_1)[i_13]));
    ConvectionInput_0 _S172 = c_28;
    float _S173 = convUpdraft_0(&_S172, _S171);
    *_S170 = _S173;
    return;
}

extern "C" __global__ void convCells(ConvectionInput_0 c_29, StructuredBuffer<int2 > slots_0, RWStructuredBuffer<float3 > outCell_0, int count_3)
{
    int i_14 = int((blockIdx * blockDim + threadIdx).x);
    if(i_14 >= count_3)
    {
        return;
    }
    int2  _S174 = __ldg((&(slots_0)[i_14]));
    ConvectionInput_0 _S175 = c_29;
    float2  _S176 = convCellCentre_0(&_S175, _S174);
    float3  * _S177 = (&(outCell_0)[i_14]);
    float _S178 = _S176.x;
    float _S179 = _S176.y;
    int2  _S180 = __ldg((&(slots_0)[i_14]));
    ConvectionInput_0 _S181 = c_29;
    float _S182 = convVigour_0(&_S181, _S180);
    *_S177 = make_float3 (_S178, _S179, _S182);
    return;
}

extern "C" __global__ void convBillowAt(ConvectionInput_0 c_30, StructuredBuffer<float3 > points_2, RWStructuredBuffer<float> outBillow_0, int count_4)
{
    int i_15 = int((blockIdx * blockDim + threadIdx).x);
    if(i_15 >= count_4)
    {
        return;
    }
    float * _S183 = (&(outBillow_0)[i_15]);
    float3  _S184 = slang_ldg_0((&(points_2)[i_15]));
    ConvectionInput_0 _S185 = c_30;
    float _S186 = convBillow_0(&_S185, _S184, c_30.cvBillowScale_0);
    *_S183 = _S186;
    return;
}

extern "C" __global__ void convUpdraftWide(ConvectionInput_0 c_31, StructuredBuffer<float2 > points_3, RWStructuredBuffer<float> outUpdraft_1, int count_5)
{
    float oTop_9;
    int i_16 = int((blockIdx * blockDim + threadIdx).x);
    if(i_16 >= count_5)
    {
        return;
    }
    float2  _S187 = __ldg((&(points_3)[i_16]));
    Organization_0 _S188 = c_31.cvOrg_0;
    float2  _S189 = orgPattern_0(&_S188, _S187, c_31.cvSpacing_0);
    float2  _S190 = floor_1(_S189);
    int2  _S191 = make_int2 ((int)_S190.x, (int)_S190.y);
    float keep_3 = 1.0f;
    float2  _S192 = make_float2 (0.0f, 0.0f);
    float2  gKeep_4 = _S192;
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
            int2  slot_7 = _S191 + make_int2 (di_0, dj_0);
            ConvectionInput_0 _S193 = c_31;
            float _S194 = convVigour_0(&_S193, slot_7);
            if(_S194 <= 0.0f)
            {
                di_0 = di_0 + int(1);
                continue;
            }
            ConvectionInput_0 _S195 = c_31;
            float2  _S196 = convCellCentre_0(&_S195, slot_7);
            float2  d_10 = _S189 - _S196;
            float d2_5 = dot_0(d_10, d_10);
            float ko_3 = _S194 * convBump_0(d2_5, 0.75f);
            float kk_3 = _S194 * convBump_0(d2_5, 1.04999995231628418f);
            if((c_31.cvLacunarity_0) > 0.0f)
            {
                ConvectionInput_0 _S197 = c_31;
                convHole_0(&_S197, d_10, d2_5, _S194, &keep_3, &gKeep_4);
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
                float _S198 = oTop_11;
                oTop_11 = oTop_9;
                oNext_11 = _S198;
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
                float _S199 = kTop_12;
                kTop_12 = kTop_11;
                kNext_12 = _S199;
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
    float w_2 = lerp_0((F32_min((oNext_9 / 0.31000000238418579f), (1.0f))), kTop_10 - kNext_10, c_31.cvPolarity_0);
    if((c_31.cvOrg_0.ogOn_0) != int(0))
    {
        float2  _S200 = __ldg((&(points_3)[i_16]));
        ConvectionInput_0 _S201 = c_31;
        float2  unused_1;
        float _S202 = convOrganize_0(&_S201, _S200, kTop_10, kNext_10, _S192, _S192, keep_3, gKeep_4, w_2, _S192, &unused_1);
        oTop_9 = _S202;
    }
    else
    {
        oTop_9 = w_2;
    }
    *(&(outUpdraft_1)[i_16]) = oTop_9;
    return;
}

