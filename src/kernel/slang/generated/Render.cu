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

static __device__ float length_1(float2  x_13)
{
    return (F32_sqrt((dot_1(x_13, x_13))));
}

static __device__ float2  abs_0(float2  x_14)
{
    float2  result_4;
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
        *_slang_vector_get_element_ptr(&result_4, i_7) = (F32_abs((_slang_vector_get_element(x_14, i_7))));
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static __device__ bool all_0(bool2  x_15)
{
    bool result_5 = true;
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
            result_5 = (bool((_slang_vector_get_element(x_15, i_8))));
        }
        else
        {
            result_5 = false;
        }
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static __device__ float smoothstep_0(float min_0, float max_1, float x_16)
{
    float _S79 = saturate_0((x_16 - min_0) / (max_1 - min_0));
    return _S79 * _S79 * (3.0f - (_S79 + _S79));
}

static __device__ float2  min_1(float2  x_17, float2  y_5)
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
        *_slang_vector_get_element_ptr(&result_6, i_9) = (F32_min((_slang_vector_get_element(x_17, i_9)), (_slang_vector_get_element(y_5, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static __device__ float2  max_2(float2  x_18, float2  y_6)
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
        *_slang_vector_get_element_ptr(&result_7, i_10) = (F32_max((_slang_vector_get_element(x_18, i_10)), (_slang_vector_get_element(y_6, i_10))));
        i_10 = i_10 + int(1);
    }
    return result_7;
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
    uint s_6 = ((r_2->state_0) ^ (salt_1 * 2654435761U)) * 747796405U + 2891336453U;
    uint s_7 = ((s_6 >> ((s_6 >> 28U) + 4U)) ^ s_6) * 277803737U;
    return makeRng_0((s_7 >> 22U) ^ s_7);
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
        lo_1 = max_2(lo_1, m_0->fadeAt_0 - make_float2 (_S90));
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

static __device__ float convCeiling_0(ConvectionInput_0 * c_9)
{
    float _S105 = c_9->cvBillow_0;
    float field_0 = c_9->cvDepth_0 + c_9->cvBillow_0;
    float _S106 = c_9->cvHeroTop_0;
    float hero_0;
    if((c_9->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S106 + _S105 * c_9->cvHeroBillow_0;
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
    Organization_0 _S107 = flat_0;
    float2  _S108 = orgPattern_0(&_S107, q0_0, spacing_2);
    Organization_0 _S109 = flat_0;
    float2  _S110 = orgPattern_0(&_S109, q1_0, spacing_2);
    float2  _S111 = make_float2 (q0_0.x, q1_0.y);
    Organization_0 _S112 = flat_0;
    float2  _S113 = orgPattern_0(&_S112, _S111, spacing_2);
    float2  _S114 = make_float2 (q1_0.x, q0_0.y);
    Organization_0 _S115 = flat_0;
    float2  _S116 = orgPattern_0(&_S115, _S114, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S108.x)))), ((F32_abs((_S108.y))))))), ((F32_max(((F32_abs((_S110.x)))), ((F32_abs((_S110.y)))))))));
    *a_1 = min_1(min_1(_S108, _S113), min_1(_S116, _S110)) - make_float2 (grow_0);
    *b_0 = max_2(max_2(_S108, _S113), max_2(_S116, _S110)) + make_float2 (grow_0);
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_11, int2  slot_6, float2  a_2, float2  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S117 = convVigour_0(c_11, slot_6);
    if(_S117 <= 0.0f)
    {
        return;
    }
    float2  _S118 = convCellCentre_0(c_11, slot_6);
    float2  _S119 = a_2 - _S118;
    float2  nearGap_0 = max_2(max_2(_S119, _S118 - b_1), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_2(abs_0(_S119), abs_0(b_1 - _S118));
    float oHi_0 = _S117 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S117 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S117 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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

static __device__ float convUpdraftBound_0(ConvectionInput_0 * c_12, float2  q0_1, float2  q1_1)
{
    float2  a_3;
    float2  b_2;
    orgPatternBox_0(&c_12->cvOrg_0, q0_1, q1_1, c_12->cvSpacing_0, &a_3, &b_2);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    float2  _S120 = floor_1((a_3 + b_2) * make_float2 (0.5f));
    int2  _S121 = make_int2 ((int)_S120.x, (int)_S120.y);
    float2  _S122 = make_float2 ((float)_S121.x, (float)_S121.y);
    float2  highEdge_0 = _S122 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S123;
    if(all_0(a_3 >= (_S122 - make_float2 (0.00009999999747379f))))
    {
        _S123 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S123 = false;
    }
    int j_7;
    int i_11;
    if(_S123)
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
                convSlotBound_0(c_12, _S121 + make_int2 (i_11, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        float2  _S124 = floor_1(a_3);
        int2  _S125 = make_int2 ((int)_S124.x, (int)_S124.y);
        int2  _S126 = make_int2 (int(1), int(1));
        int2  i0_0 = _S125 - _S126;
        float2  _S127 = floor_1(b_2);
        int2  _S128 = make_int2 ((int)_S127.x, (int)_S127.y);
        int2  _S129 = _S128 + _S126;
        int _S130 = i0_0.y;
        j_7 = _S130;
        for(;;)
        {
            if(j_7 <= (_S129.y))
            {
                _S123 = j_7 <= (_S130 + int(32));
            }
            else
            {
                _S123 = false;
            }
            if(_S123)
            {
            }
            else
            {
                break;
            }
            int _S131 = i0_0.x;
            i_11 = _S131;
            for(;;)
            {
                bool _S132;
                if(i_11 <= (_S129.x))
                {
                    _S132 = i_11 <= (_S131 + int(32));
                }
                else
                {
                    _S132 = false;
                }
                if(_S132)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_12, make_int2 (i_11, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_0((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_12->cvPolarity_0);
    float _S133 = c_12->cvLacunarity_0;
    float field_2;
    if((c_12->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_0(field_1, 0.40000000596046448f, _S133);
    }
    else
    {
        field_2 = field_1;
    }
    return field_2 + 0.00000999999974738f;
}

static __device__ float convTowerHeight_0(ConvectionInput_0 * c_13, float w_1)
{
    float cover_0 = clamp_0(c_13->cvCoverage_0, 0.0f, 1.0f);
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
    return c_13->cvDepth_0 * (F32_pow((u_2), (c_13->cvShape_0)));
}

static __device__ float convNeededUpdraft_0(ConvectionInput_0 * c_14, float above_1)
{
    float cover_1 = clamp_0(c_14->cvCoverage_0, 0.0f, 1.0f);
    bool _S134;
    if(cover_1 <= 0.0f)
    {
        _S134 = true;
    }
    else
    {
        _S134 = (c_14->cvDepth_0) <= 0.0f;
    }
    if(_S134)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_14->cvDepth_0), (1.0f / (F32_max((c_14->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_15)
{
    float _S135 = c_15->cvSpacing_0;
    float cap_0 = 7.0f / c_15->cvSpacing_0;
    if(((&c_15->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_0;
    }
    float _S136 = c_15->cvLacunarity_0;
    float cap_1;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        cap_1 = cap_0 + 1.5f / (0.15000000596046448f * _S136 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S135);
    }
    else
    {
        cap_1 = cap_0;
    }
    float _S137 = c_15->cvGapWidth_0;
    if((c_15->cvGapWidth_0) > 0.0f)
    {
        cap_1 = cap_1 + 14.25f * c_15->cvPolarity_0 / (0.5f * _S137 * _S135);
    }
    return cap_1 + 3.0f * (&c_15->cvOrg_0)->ogWaveAmp_0 * length_1((&c_15->cvOrg_0)->ogWaveK_0);
}

static __device__ float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S138;
    if(vMin_0 <= 0.0f)
    {
        _S138 = true;
    }
    else
    {
        _S138 = hMin_0 <= 0.0f;
    }
    if(_S138)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_16)
{
    return c_16->cvHeroRadius_0 + 1.5f * c_16->cvBillow_0 * c_16->cvHeroBillow_0 + 24.0f;
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_17, float r_3)
{
    float _S139 = c_17->cvHeroTop_0;
    bool _S140;
    if((c_17->cvHeroTop_0) <= 0.0f)
    {
        _S140 = true;
    }
    else
    {
        _S140 = r_3 >= (c_17->cvHeroRadius_0);
    }
    if(_S140)
    {
        return 0.0f;
    }
    return _S139 * (F32_pow((1.0f - r_3 * r_3 / (c_17->cvHeroRadius_0 * c_17->cvHeroRadius_0)), (c_17->cvShape_0)));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_18, float above_2)
{
    float _S141 = c_18->cvHeroTop_0;
    bool _S142;
    if((c_18->cvHeroTop_0) <= 0.0f)
    {
        _S142 = true;
    }
    else
    {
        _S142 = above_2 >= _S141;
    }
    if(_S142)
    {
        return -1.0f;
    }
    return c_18->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S141), (1.0f / (F32_max((c_18->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_19, float3  lo_2, float3  hi_2)
{
    float low_0 = lo_2.y - c_19->cvBase_0;
    float high_0 = hi_2.y - c_19->cvBase_0;
    float _S143 = convCeiling_0(c_19);
    bool _S144;
    if(high_0 < 0.0f)
    {
        _S144 = true;
    }
    else
    {
        _S144 = low_0 > _S143;
    }
    if(_S144)
    {
        return 0.0f;
    }
    float _S145 = (F32_max((low_0), (0.0f)));
    float _S146 = (F32_min((high_0), (_S143)));
    float _S147 = convLift_0(c_19, _S146, 1.0f);
    float inside_0;
    if((c_19->cvHeroAlone_0) == int(0))
    {
        float _S148 = convUpdraftBound_0(c_19, float2 {lo_2.x, lo_2.z} - c_19->cvDrift_0, float2 {hi_2.x, hi_2.z} - c_19->cvDrift_0);
        float _S149 = convTowerHeight_0(c_19, _S148);
        float _S150 = convNeededUpdraft_0(c_19, _S145);
        if(_S148 < _S150)
        {
            float _S151 = convSlopeCap_0(c_19);
            inside_0 = _S147 - convDistanceFloor_0(_S145 - _S149, (_S150 - _S148) / _S151);
        }
        else
        {
            inside_0 = (F32_max((_S149 - _S145), (0.0f))) + _S147;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    if((c_19->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_1(max_2(max_2(float2 {lo_2.x, lo_2.z} - c_19->cvHeroAt_0, c_19->cvHeroAt_0 - float2 {hi_2.x, hi_2.z}), make_float2 (0.0f, 0.0f)));
        float _S152 = convHeroReach_0(c_19);
        if(rMin_0 < _S152)
        {
            float _S153 = convHeroHeight_0(c_19, rMin_0);
            float _S154 = convHeroRadiusAt_0(c_19, _S145);
            float _S155 = convLift_0(c_19, _S146, c_19->cvHeroBillow_0);
            bool _S156 = _S154 < 0.0f;
            if(_S156)
            {
                _S144 = true;
            }
            else
            {
                _S144 = rMin_0 >= _S154;
            }
            float heroIn_0;
            if(_S144)
            {
                if(_S156)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S154;
                }
                heroIn_0 = _S155 - convDistanceFloor_0(_S145 - _S153, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S153 - _S145), (0.0f))) + _S155;
            }
            inside_0 = (F32_max((inside_0), (heroIn_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return 0.0f;
    }
    return c_19->cvSigma_0 * (F32_sqrt((saturate_0(_S146 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1) * 1.00001001358032227f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_19 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_12 = clamp_1(int((F32_floor((x_19)))), int(0), int(31));
    float2  _S157 = __ldg((&(disp_0)[i_12]));
    float2  _S158 = __ldg((&(disp_0)[i_12 + int(1)]));
    return lerp_1(_S157, _S158, make_float2 (x_19 - float(i_12)));
}

static __device__ void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<float2 > disp_1, float d0_0, float d1_0, float2  * lo_3, float2  * hi_3)
{
    float2  _S159 = driftAt_0(g_5, disp_1, d0_0);
    *lo_3 = _S159;
    *hi_3 = _S159;
    float2  _S160 = driftAt_0(g_5, disp_1, d1_0);
    *lo_3 = min_1(*lo_3, _S160);
    *hi_3 = max_2(*hi_3, _S160);
    int _S161 = clamp_1(int((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_2 = clamp_1(int((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_2 <= _S161)
        {
        }
        else
        {
            break;
        }
        float2  _S162 = *lo_3;
        float2  _S163 = __ldg((&(disp_1)[k_2]));
        *lo_3 = min_1(_S162, _S163);
        float2  _S164 = *hi_3;
        float2  _S165 = __ldg((&(disp_1)[k_2]));
        *hi_3 = max_2(_S164, _S165);
        k_2 = k_2 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_6, float2  q0_2, float2  q1_2)
{
    float2  a_4;
    float2  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    float2  _S166 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    float2  _S167 = floor_1(a_4);
    int2  _S168 = make_int2 ((int)_S167.x, (int)_S167.y);
    int2  _S169 = make_int2 (int(1), int(1));
    int2  i0_1 = _S168 - _S169;
    float2  _S170 = floor_1(b_3);
    int2  _S171 = make_int2 ((int)_S170.x, (int)_S170.y);
    int2  _S172 = _S171 + _S169;
    int _S173 = i0_1.y;
    int j_8 = _S173;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S174;
        if(j_8 <= (_S172.y))
        {
            _S174 = j_8 <= (_S173 + int(32));
        }
        else
        {
            _S174 = false;
        }
        if(_S174)
        {
        }
        else
        {
            break;
        }
        int _S175 = i0_1.x;
        int i_13 = _S175;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S176;
            if(i_13 <= (_S172.x))
            {
                _S176 = i_13 <= (_S175 + int(32));
            }
            else
            {
                _S176 = false;
            }
            if(_S176)
            {
            }
            else
            {
                break;
            }
            int2  o_7 = make_int2 (i_13, j_8);
            if((hash22_0(o_7, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_13 = i_13 + int(1);
                continue;
            }
            float2  _S177 = make_float2 ((float)o_7.x, (float)o_7.y);
            float2  c_20 = _S177 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S166;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(max_2(max_2(a_4 - c_20, c_20 - b_3), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_13 = i_13 + int(1);
        }
        j_8 = j_8 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_6->cellStrength_0;
}

static __device__ float iceDensityBound_0(GeneratorInput_0 * g_7, StructuredBuffer<float2 > disp_2, float3  lo_4, float3  hi_4)
{
    float d0_1 = g_7->cellAltitude_0 - hi_4.y;
    float d1_1 = g_7->cellAltitude_0 - lo_4.y;
    bool _S178;
    if(d1_1 < 0.0f)
    {
        _S178 = true;
    }
    else
    {
        _S178 = d0_1 > (g_7->streakLength_0);
    }
    if(_S178)
    {
        return 0.0f;
    }
    float _S179 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S180 = cellFieldBound_0(g_7, make_float2 (lo_4.x, lo_4.z) - driftHi_0, make_float2 (hi_4.x, hi_4.z) - driftLo_0);
    return (F32_max((_S180 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S179), (1.0f)));
}

static __device__ float mediumBound_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_3, float3  lo_5, float3  hi_5)
{
    int _S181 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S182 = convectionBound_0(&m_1->conv_0, lo_5, hi_5);
        return _S182;
    }
    if(_S181 == int(2))
    {
        float _S183 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_5, hi_5);
        return _S183;
    }
    return m_1->majorant_0;
}

static __device__ float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_0, StructuredBuffer<float2 > disp_4, int3  c_21, float fallback_0)
{
    int _S184 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S184 == int(2))
    {
        float3  _S185 = make_float3 ((float)c_21.x, (float)c_21.y, (float)c_21.z);
        float3  lo_6 = g_8->origin_0 + _S185 * g_8->cellExtent_0;
        float _S186 = mediumBound_0(m_2, disp_4, lo_6, lo_6 + g_8->cellExtent_0);
        return _S186;
    }
    int _S187 = c_21.x;
    bool _S188;
    if(_S187 < int(0))
    {
        _S188 = true;
    }
    else
    {
        _S188 = (c_21.y) < int(0);
    }
    if(_S188)
    {
        _S188 = true;
    }
    else
    {
        _S188 = (c_21.z) < int(0);
    }
    if(_S188)
    {
        _S188 = true;
    }
    else
    {
        _S188 = _S187 >= (g_8->dims_0.x);
    }
    if(_S188)
    {
        _S188 = true;
    }
    else
    {
        _S188 = (c_21.y) >= (g_8->dims_0.y);
    }
    if(_S188)
    {
        _S188 = true;
    }
    else
    {
        _S188 = (c_21.z) >= (g_8->dims_0.z);
    }
    if(_S188)
    {
        return fallback_0;
    }
    float _S189 = __ldg((&(bounds_0)[(c_21.z * g_8->dims_0.y + c_21.y) * g_8->dims_0.x + _S187]));
    return _S189;
}

static __device__ float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S190;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S190 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S190 = false;
    }
    if(_S190)
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

static __device__ float randFloat_0(Rng_0 * r_4)
{
    uint _S191 = r_4->state_0 * 747796405U + 2891336453U;
    r_4->state_0 = _S191;
    uint word_0 = ((_S191 >> ((_S191 >> 28U) + 4U)) ^ _S191) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ bool segmentStep_0(Medium_0 * m_3, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > drift_0, float scale_0, float tEnd_0, Dda_0 * dda_0, float * rate_0, float * t_4, Rng_0 * rng_0, float * uKeep_0, float * uLive_0, int * budget_0, int * steps_0)
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
        Dda_0 _S192 = *dda_0;
        float _S193 = ddaExit_0(&_S192);
        float _S194 = (F32_min((_S193), (tEnd_0)));
        if(!((*rate_0) > 0.0f))
        {
            if(_S194 >= tEnd_0)
            {
                return false;
            }
            *t_4 = _S194;
            ddaAdvance_0(dda_0);
            float _S195 = gridBound_0(m_3, g_9, bounds_1, drift_0, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S195 * scale_0;
            continue;
        }
        float uStep_0 = randFloat_0(rng_0);
        float _S196 = randFloat_0(rng_0);
        *uKeep_0 = _S196;
        float _S197 = randFloat_0(rng_0);
        *uLive_0 = _S197;
        float _S198 = *t_4 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / *rate_0;
        *t_4 = _S198;
        if(_S198 >= _S194)
        {
            if(_S194 >= tEnd_0)
            {
                return false;
            }
            *t_4 = _S194;
            ddaAdvance_0(dda_0);
            float _S199 = gridBound_0(m_3, g_9, bounds_1, drift_0, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S199 * scale_0;
            continue;
        }
        return true;
    }
    return false;
}

static __device__ MajorantGrid_0 gridFor_0(Medium_0 * m_4, MajorantGrid_0 * g_10, float3  p_2)
{
    MajorantGrid_0 chosen_0 = *g_10;
    bool _S200;
    if((g_10->enabled_0) == int(2))
    {
        _S200 = (p_2.y) >= (m_4->slabBottom_0);
    }
    else
    {
        _S200 = false;
    }
    if(_S200)
    {
        _S200 = (p_2.y) <= (m_4->slabTop_0);
    }
    else
    {
        _S200 = false;
    }
    if(_S200)
    {
        (&chosen_0)->enabled_0 = int(0);
    }
    return chosen_0;
}

static __device__ float orgWaveFactor_0(Organization_0 * o_8, float2  q_6)
{
    float2  unused_0;
    float _S201 = orgWave_0(o_8, q_6, &unused_0);
    return _S201;
}

static __device__ float cellField_0(GeneratorInput_0 * g_11, float2  q_7)
{
    float2  _S202 = q_7 - g_11->cellDrift_0;
    float2  _S203 = orgPattern_0(&g_11->gnOrg_0, _S202, g_11->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(_S203);
    int2  _S204 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    float2  _S205 = orgJitter_0(&g_11->gnOrg_0, 0.80000001192092896f);
    int j_9 = int(-1);
    float acc_2 = 0.0f;
    for(;;)
    {
        if(j_9 <= int(1))
        {
        }
        else
        {
            break;
        }
        int i_14 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_14 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_9 = _S204 + make_int2 (i_14, j_9);
            if((hash22_0(o_9, 2654435769U).x) > (g_11->cellDensity_0))
            {
                i_14 = i_14 + int(1);
                continue;
            }
            float2  _S206 = make_float2 ((float)o_9.x, (float)o_9.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(_S203 - (_S206 + make_float2 (0.5f) + (hash22_0(o_9, 0U) - make_float2 (0.5f)) * _S205)) * 2.20000004768371582f);
            i_14 = i_14 + int(1);
        }
        j_9 = j_9 + int(1);
        acc_2 = acc_3;
    }
    float _S207 = acc_2 * g_11->cellStrength_0;
    float _S208 = orgWaveFactor_0(&g_11->gnOrg_0, _S202);
    return _S207 * _S208;
}

static __device__ float fbm_0(float3  p_3, int octaves_1)
{
    int i_15 = int(0);
    float amp_0 = 0.5f;
    float3  _S209 = p_3;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_15 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_15 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S209);
        float norm_1 = norm_0 + amp_0;
        float3  _S210 = _S209 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_15 = i_15 + int(1);
        amp_0 = amp_1;
        _S209 = _S210;
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
    bool _S211;
    if(depth_1 < 0.0f)
    {
        _S211 = true;
    }
    else
    {
        _S211 = depth_1 > (g_12->streakLength_0);
    }
    if(_S211)
    {
        return 0.0f;
    }
    float2  _S212 = float2 {p_4.x, p_4.z};
    float2  _S213 = driftAt_0(g_12, disp_5, depth_1);
    float2  source_0 = _S212 - _S213;
    float _S214 = cellField_0(g_12, source_0);
    if(_S214 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S214 * (F32_exp((- g_12->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_12->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_12->streakLength_0, g_12->streakLength_0, depth_1)) * (F32_max((1.0f + g_12->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_12->detailScale_0)).x, (source_0 / make_float2 (g_12->detailScale_0)).y, depth_1 / (F32_max((g_12->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_12->timeSeconds_0 * 0.00999999977648258f), g_12->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_12->opticalDepth_0 / (F32_max((g_12->streakLength_0), (1.0f)));
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_22, float2  q_8, float2  * grad_5)
{
    if(((&c_22->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S215 = convUpdraftGradT_2(c_22, q_8, grad_5);
        return _S215;
    }
    if((c_22->cvLacunarity_0) <= 0.0f)
    {
        float _S216 = convUpdraftGradT_1(c_22, q_8, grad_5);
        return _S216;
    }
    float _S217 = convUpdraftGradT_0(c_22, q_8, grad_5);
    return _S217;
}

static __device__ float convSurfaceDistance_0(float v_2, float delta_0, float slope_0)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_0 * slope_0 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_8 = num_0 / den_0;
    float _S218;
    if(v_2 >= 0.0f)
    {
        _S218 = d_8;
    }
    else
    {
        _S218 = - d_8;
    }
    return _S218;
}

static __device__ float3  convTwist_0(float3  x_20)
{
    float _S219 = x_20.x;
    float _S220 = x_20.y;
    float _S221 = x_20.z;
    return make_float3 (0.0f * _S219 + 0.80000001192092896f * _S220 + 0.60000002384185791f * _S221, -0.80000001192092896f * _S219 + 0.36000001430511475f * _S220 - 0.47999998927116394f * _S221, -0.60000002384185791f * _S219 - 0.47999998927116394f * _S220 + 0.63999998569488525f * _S221);
}

static __device__ float convPuffs_0(float3  x_21)
{
    float3  fl_0 = floor_0(x_21);
    int3  _S222 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_1 = x_21 - fl_0;
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
    int3  _S223 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S223 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S224 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_9 = _S224 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S222 + off_0) - f_1;
                float _S225 = (F32_min((nearest_1), (dot_0(d_9, d_9))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S225;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_23, float3  p_5, float scale_1)
{
    float3  _S226 = make_float3 (p_5.x, p_5.y - c_23->cvRise_0, p_5.z) / make_float3 (scale_1);
    int i_16 = int(0);
    float3  x_22 = _S226;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_16 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_16 >= (c_23->cvOctaves_0))
        {
            break;
        }
        float3  x_23 = convTwist_0(x_22);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_23);
        float norm_3 = norm_2 + amp_2;
        float3  x_24 = x_23 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_16 = i_16 + int(1);
        x_22 = x_24;
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

static __device__ float convInside_0(ConvectionInput_0 * c_24, float d_10, float lift_0, float3  x_25, float scale_2)
{
    float _S227 = d_10 + lift_0;
    if(_S227 <= 0.0f)
    {
        return _S227;
    }
    if((d_10 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S228 = convBillow_0(c_24, x_25, scale_2);
    return d_10 + lift_0 * _S228;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_25, float3  p_6, float above_3)
{
    float2  rel_0 = float2 {p_6.x, p_6.z} - c_25->cvHeroAt_0;
    float r_5 = length_1(rel_0);
    float _S229 = convHeroReach_0(c_25);
    if(r_5 >= _S229)
    {
        return -1.00000001504746622e+30f;
    }
    float _S230 = convHeroHeight_0(c_25, r_5);
    float v_3 = _S230 - above_3;
    float _S231 = convHeroRadiusAt_0(c_25, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_11;
    if(_S231 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_11 = v_3;
    }
    else
    {
        float h_3 = _S231 - r_5;
        float d_12 = convSurfaceDistance_0(v_3, h_3, 1.0f);
        if((F32_abs((v_3))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_12 * (d_12 / v_3);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_3))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_12 * (d_12 / h_3);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S232 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S232;
        d_11 = d_12;
    }
    float2  radial_0;
    if(r_5 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / make_float2 (r_5);
    }
    else
    {
        radial_0 = make_float2 (0.0f, 0.0f);
    }
    float2  at_0 = rel_0 + radial_0 * make_float2 (shiftOut_0);
    float3  x_26 = make_float3 (at_0.x, p_6.y + shiftUp_0, at_0.y) + c_25->cvHeroSeed_0;
    float _S233 = c_25->cvHeroBillow_0;
    float _S234 = convLift_0(c_25, above_3, c_25->cvHeroBillow_0);
    float _S235 = convInside_0(c_25, d_11, _S234, x_26, c_25->cvBillowScale_0 * _S233);
    return _S235;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_26, float3  p_7)
{
    float _S236 = p_7.y;
    float above_4 = _S236 - c_26->cvBase_0;
    bool _S237;
    if(above_4 < 0.0f)
    {
        _S237 = true;
    }
    else
    {
        float _S238 = convCeiling_0(c_26);
        _S237 = above_4 > _S238;
    }
    if(_S237)
    {
        return 0.0f;
    }
    float _S239 = convLift_0(c_26, above_4, 1.0f - 0.60000002384185791f * c_26->cvLacunarity_0);
    float inside_2;
    if((c_26->cvHeroAlone_0) == int(0))
    {
        float2  q_9 = float2 {p_7.x, p_7.z} - c_26->cvDrift_0;
        float2  slope_1;
        float _S240 = convUpdraftGrad_0(c_26, q_9, &slope_1);
        float _S241 = convTowerHeight_0(c_26, _S240);
        float v_4 = _S241 - above_4;
        float _S242 = convNeededUpdraft_0(c_26, above_4);
        float delta_1 = _S240 - _S242;
        float _S243 = length_1(slope_1);
        float _S244 = convSlopeCap_0(c_26);
        float d_13 = convSurfaceDistance_0(v_4, delta_1, (F32_min((_S243), (_S244))));
        if((d_13 + _S239) > 0.0f)
        {
            if((F32_abs((v_4))) > 9.99999997475242708e-07f)
            {
                inside_2 = d_13 * (d_13 / v_4);
            }
            else
            {
                inside_2 = 0.0f;
            }
            float2  shiftAcross_0;
            if((F32_abs((delta_1))) > 9.999999960041972e-13f)
            {
                shiftAcross_0 = slope_1 * make_float2 (- d_13 * (d_13 / delta_1));
            }
            else
            {
                shiftAcross_0 = make_float2 (0.0f, 0.0f);
            }
            float _S245 = convInside_0(c_26, d_13, _S239, make_float3 (q_9.x + shiftAcross_0.x, _S236 + inside_2, q_9.y + shiftAcross_0.y), c_26->cvBillowScale_0);
            inside_2 = _S245;
        }
        else
        {
            inside_2 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        inside_2 = -1.00000001504746622e+30f;
    }
    if((c_26->cvHeroTop_0) > 0.0f)
    {
        _S237 = inside_2 < 12.0f;
    }
    else
    {
        _S237 = false;
    }
    if(_S237)
    {
        float _S246 = convHeroInside_0(c_26, p_7, above_4);
        inside_2 = (F32_max((inside_2), (_S246)));
    }
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_26->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2);
}

static __device__ float densityAt_0(Medium_0 * m_5, StructuredBuffer<float2 > disp_6, float3  p_8)
{
    float _S247 = p_8.y;
    bool _S248;
    if(_S247 < (m_5->slabBottom_0))
    {
        _S248 = true;
    }
    else
    {
        _S248 = _S247 > (m_5->slabTop_0);
    }
    if(_S248)
    {
        return 0.0f;
    }
    if((m_5->clipOn_0) != int(0))
    {
        float2  _S249 = float2 {p_8.x, p_8.z};
        if(any_0(_S249 < (m_5->clipLo_0)))
        {
            _S248 = true;
        }
        else
        {
            _S248 = any_0(_S249 > (m_5->clipHi_0));
        }
    }
    else
    {
        _S248 = false;
    }
    if(_S248)
    {
        return 0.0f;
    }
    float _S250 = m_5->fadeRadius_0;
    float fade_0;
    if((m_5->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S250 - length_1(float2 {p_8.x, p_8.z} - m_5->fadeAt_0)) / (F32_max((m_5->fadeWidth_0), (1.0f))));
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
    int _S251 = m_5->mode_0;
    if((m_5->mode_0) == int(0))
    {
        return m_5->density_0 * fade_0;
    }
    if(_S251 == int(2))
    {
        float _S252 = iceDensity_0(&m_5->gen_0, disp_6, p_8);
        return _S252 * fade_0;
    }
    if(_S251 == int(3))
    {
        float _S253 = convectionDensity_0(&m_5->conv_0, p_8);
        return _S253 * fade_0;
    }
    float3  d_14 = (p_8 - m_5->coreCentre_0) / make_float3 ((F32_max((m_5->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_5->density_0 + m_5->coreDensity_0 * (F32_exp((- dot_0(d_14, d_14))))) * fade_0;
}

static __device__ float transmittance_0(Medium_0 * m_6, MajorantGrid_0 * g_13, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > disp_7, Rng_0 * rng_1, float3  p_9, float3  dir_0, int * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S254 = slabRange_0(m_6, p_9, dir_0, &t0_2, &t1_2);
    if(!_S254)
    {
        return 1.0f;
    }
    float _S255 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S255;
    Dda_0 _S256 = ddaInit_0(g_13, p_9, dir_0, _S255);
    Dda_0 dda_1 = _S256;
    float _S257 = m_6->majorant_0;
    float _S258 = gridBound_0(m_6, g_13, bounds_2, disp_7, (&dda_1)->cell_0, m_6->majorant_0);
    float localMaj_0 = _S258;
    int i_17 = int(0);
    float t_5 = _S255;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_17 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_1 = *steps_1 + int(1);
        Dda_0 _S259 = dda_1;
        float _S260 = ddaExit_0(&_S259);
        float _S261 = (F32_min((_S260), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S261 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S262 = gridBound_0(m_6, g_13, bounds_2, disp_7, (&dda_1)->cell_0, _S257);
            localMaj_0 = _S262;
            t_5 = _S261;
            i_17 = i_17 + int(1);
            continue;
        }
        float _S263 = randFloat_0(rng_1);
        float t_6 = t_5 - (F32_log(((F32_max((1.0f - _S263), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_6 >= _S261)
        {
            if(_S261 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S264 = gridBound_0(m_6, g_13, bounds_2, disp_7, (&dda_1)->cell_0, _S257);
            localMaj_0 = _S264;
            t_5 = _S261;
            i_17 = i_17 + int(1);
            continue;
        }
        float _S265 = densityAt_0(m_6, disp_7, p_9 + dir_0 * make_float3 (t_6));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S265 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S266 = randFloat_0(rng_1);
            if(_S266 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_5 = t_6;
        tr_0 = tr_2;
        i_17 = i_17 + int(1);
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

static __device__ float sceneTransmittance_0(Scene_0 * s_8, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > drift_1, Rng_0 * rng_2, float3  p_10, float3  dir_1, int * steps_2)
{
    float _S267 = transmittance_0(&s_8->medium_0, &s_8->grid_0, bounds_3, drift_1, rng_2, p_10, dir_1, steps_2);
    bool _S268;
    if((s_8->layer2On_0) != int(0))
    {
        _S268 = _S267 > 0.0f;
    }
    else
    {
        _S268 = false;
    }
    float tr_3;
    if(_S268)
    {
        MajorantGrid_0 _S269 = gridFor_0(&s_8->medium2_0, &s_8->grid2_0, p_10);
        MajorantGrid_0 _S270 = _S269;
        float _S271 = transmittance_0(&s_8->medium2_0, &_S270, bounds_3, drift_1, rng_2, p_10, dir_1, steps_2);
        tr_3 = _S267 * _S271;
    }
    else
    {
        tr_3 = _S267;
    }
    return tr_3;
}

static __device__ float hg_0(float cosT_0, float g_14)
{
    float _S272 = g_14 * g_14;
    float d_15 = 1.0f + _S272 - 2.0f * g_14 * cosT_0;
    return (1.0f - _S272) / (12.56637096405029297f * d_15 * (F32_sqrt(((F32_max((d_15), (9.99999997475242708e-07f)))))));
}

static __device__ float phaseIce_0(float cosT_1)
{
    float t_7 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_0(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_7 * t_7))) * 0.34999999403953552f;
}

static __device__ float draine_0(float cosT_2, float g_15, float a_5)
{
    float _S273 = g_15 * g_15;
    float _S274 = 2.0f * g_15;
    float d_16 = 1.0f + _S273 - _S274 * cosT_2;
    return (1.0f - _S273) / (12.56637096405029297f * d_16 * (F32_sqrt(((F32_max((d_16), (9.99999997475242708e-07f))))))) * (1.0f + a_5 * cosT_2 * cosT_2) / (1.0f + a_5 * (1.0f + _S274 * g_15) / 3.0f);
}

static __device__ float phaseLiquid_0(PhaseInput_0 * p_11, float cosT_3)
{
    return (1.0f - p_11->draineW_0) * hg_0(cosT_3, p_11->hgG_0) + p_11->draineW_0 * draine_0(cosT_3, p_11->draineG_0, p_11->draineAlpha_0);
}

static __device__ float phaseAt_0(PhaseInput_0 * p_12, float cosT_4)
{
    float _S275;
    if((p_12->useIce_0) != int(0))
    {
        _S275 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S276 = phaseLiquid_0(p_12, cosT_4);
        _S275 = _S276;
    }
    return _S275;
}

static __device__ float phaseCamera_0(PhaseInput_0 * p_13, float cosT_5)
{
    float _S277 = phaseAt_0(p_13, cosT_5);
    float _S278 = p_13->lobeWeight_0;
    float v_5;
    if((p_13->lobeWeight_0) > 0.0f)
    {
        v_5 = _S277 + _S278 * hg_0(cosT_5, p_13->lobeG_0);
    }
    else
    {
        v_5 = _S277;
    }
    return v_5;
}

static __device__ float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_17 = altitude_0 - shellHeight_0;
    return d_17 * (d_17 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_4, float c_27)
{
    float disc_0 = b_4 * b_4 - c_27;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_4 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_5, float c_28)
{
    float disc_1 = b_5 * b_5 - c_28;
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

static __device__ float altitudeFromQ_0(float q_10, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_10;
    float _S279;
    if(rr_0 > 0.0f)
    {
        _S279 = rr_0;
    }
    else
    {
        _S279 = 0.0f;
    }
    return q_10 / (planetRadius_2 + (F32_sqrt((_S279))));
}

static __device__ float3  airTransmittance_0(SkyInput_0 * p_14, float originAltitude_0, float3  rayDir_0, float dist_1)
{
    float _S280 = p_14->planetRadius_0;
    float planetRadius_3;
    if((p_14->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S280;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S281 = p_14->scaleHeight_0;
    float scaleHeight_1;
    if((p_14->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S281;
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
    bool _S282;
    if(tTop_0 <= 0.0f)
    {
        _S282 = true;
    }
    else
    {
        _S282 = !(dist_1 > 0.0f);
    }
    if(_S282)
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
    float betaMExt_0 = mieCoefficient_0(p_14->turbidity_0) * 1.11000001430511475f;
    float tPrev_0 = 0.0f;
    int i_18 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_18 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S283 = i_18 + int(1);
        float tNext_0 = tMax_1 * float(_S283 * _S283) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_18 = _S283;
            continue;
        }
        float h_4 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_6 + tMid_0 * tMid_0, planetRadius_3);
        float hc_0;
        if(h_4 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_4;
        }
        float _S284 = - hc_0;
        float depthM_1 = depthM_0 + (F32_exp((_S284 / 1200.0f))) * dt_0;
        depthR_0 = depthR_0 + (F32_exp((_S284 / scaleHeight_1))) * dt_0;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_18 = _S283;
    }
    float _S285 = betaMExt_0 * depthM_0;
    return make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S285)))), (F32_exp((- (betaR_0.y * depthR_0 + _S285)))), (F32_exp((- (betaR_0.z * depthR_0 + _S285)))));
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_15)
{
    return 20.0f * p_15->sunIntensity_0;
}

static __device__ float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static __device__ float3  normalizeExact_0(float3  v_6)
{
    float len2_0 = dot_0(v_6, v_6);
    if(len2_0 <= 0.0f)
    {
        return make_float3 (0.0f, 1.0f, 0.0f);
    }
    return v_6 * make_float3 (1.0f / (F32_sqrt((len2_0))));
}

static __device__ float3  sunDirection_0(SkyInput_0 * p_16)
{
    float az_0 = toRadians_0(p_16->sunAzimuth_0);
    float el_0 = toRadians_0(p_16->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static __device__ float lutMuFor_0(float3  geocentric_0, float3  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S286;
    if(len_0 > 1.0f)
    {
        _S286 = dot_0(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S286 = dot_0(geocentric_0, sun_0);
    }
    return _S286;
}

static __device__ float clampf_0(float v_7, float lo_7, float hi_6)
{
    float _S287;
    if(v_7 < lo_7)
    {
        _S287 = lo_7;
    }
    else
    {
        if(v_7 > hi_6)
        {
            _S287 = hi_6;
        }
        else
        {
            _S287 = v_7;
        }
    }
    return _S287;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_17, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S288 = p_17->transmittanceLut_0;
    if(uint(StructuredBuffer_getCount_0(p_17->transmittanceLut_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S289 = p_17->scaleHeight_0;
    float scaleHeight_2;
    if((p_17->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S289;
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
    float _S290 = fx_1 - float(x0_1);
    float _S291 = fy_1 - float(y0_1);
    int _S292 = y0_1 * int(256);
    int _S293 = (_S292 + x0_1) * int(3);
    int _S294 = (_S292 + x1_1) * int(3);
    int _S295 = y1_1 * int(256);
    int _S296 = (_S295 + x0_1) * int(3);
    int _S297 = (_S295 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_29 = int(0);
    for(;;)
    {
        if(c_29 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S298 = __ldg((&(_S288)[_S293 + c_29]));
        float _S299 = 1.0f - _S290;
        float _S300 = _S298 * _S299;
        float _S301 = __ldg((&(_S288)[_S294 + c_29]));
        float a_6 = _S300 + _S301 * _S290;
        float _S302 = __ldg((&(_S288)[_S296 + c_29]));
        float _S303 = _S302 * _S299;
        float _S304 = __ldg((&(_S288)[_S297 + c_29]));
        float r_6 = a_6 * (1.0f - _S291) + (_S303 + _S304 * _S290) * _S291;
        if(c_29 == int(0))
        {
            *&((&out_0)->x) = r_6;
        }
        else
        {
            if(c_29 == int(1))
            {
                *&((&out_0)->y) = r_6;
            }
            else
            {
                *&((&out_0)->z) = r_6;
            }
        }
        c_29 = c_29 + int(1);
    }
    return out_0;
}

static __device__ float3  sunTransmittanceAt_0(SkyInput_0 * p_18, float3  worldPos_0)
{
    float3  _S305 = sunDirection_0(p_18);
    float _S306 = p_18->planetRadius_0;
    float planetRadius_4;
    if((p_18->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S306;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S307 = worldPos_0.y;
    float altitude_2;
    if(_S307 > 0.0f)
    {
        altitude_2 = _S307;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    float3  _S308 = sampleTransmittanceLut_0(p_18, altitude_2, lutMuFor_0(make_float3 (worldPos_0.x, planetRadius_4 + _S307, worldPos_0.z), _S305));
    return _S308;
}

static __device__ float3  sunIrradianceAt_0(Scene_0 * s_9, float3  p_19)
{
    if(((&s_9->environment_0)->envMode_0) == int(1))
    {
        float _S309 = sunIrradianceTop_0(&(&s_9->environment_0)->sky_0);
        float3  _S310 = sunTransmittanceAt_0(&(&s_9->environment_0)->sky_0, p_19);
        return make_float3 (_S309) * _S310;
    }
    return s_9->sunIrradiance_0;
}

static __device__ float3  cameraSegmentSun_0(Scene_0 * s_10, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > drift_2, Rng_0 * rng_3, Rng_0 * rng2_0, float3  ro_2, float3  rd_2, int * steps_3)
{
    float ph0_0;
    float kept_0;
    float keptT_0;
    float3  keptAt_0;
    int keptLayer_0;
    Rng_0 _S311 = *rng2_0;
    float3  none_0 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S312 = (F32_max((s_10->neeTentativeScale_0), (1.0f)));
    float tA_0;
    float endA_0;
    bool _S313 = slabRange_0(&s_10->medium_0, ro_2, rd_2, &tA_0, &endA_0);
    float _S314 = (F32_max((tA_0), (0.0f)));
    tA_0 = _S314;
    Dda_0 _S315 = ddaInit_0(&s_10->grid_0, ro_2, rd_2, _S314);
    Dda_0 ddaA_0 = _S315;
    float _S316 = gridBound_0(&s_10->medium_0, &s_10->grid_0, bounds_4, drift_2, (&ddaA_0)->cell_0, (&s_10->medium_0)->majorant_0);
    float rateA_0 = _S316 * _S312;
    int budgetA_0 = int(4096);
    float keepA_0 = 0.0f;
    float rouletteA_0 = 0.0f;
    bool haveA_0;
    if(_S313)
    {
        bool _S317 = segmentStep_0(&s_10->medium_0, &s_10->grid_0, bounds_4, drift_2, _S312, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
        haveA_0 = _S317;
    }
    else
    {
        haveA_0 = _S313;
    }
    float tB_0 = 0.0f;
    float endB_0 = 0.0f;
    bool haveB_0;
    if((s_10->layer2On_0) != int(0))
    {
        bool _S318 = slabRange_0(&s_10->medium2_0, ro_2, rd_2, &tB_0, &endB_0);
        haveB_0 = _S318;
    }
    else
    {
        haveB_0 = false;
    }
    float _S319 = (F32_max((tB_0), (0.0f)));
    tB_0 = _S319;
    MajorantGrid_0 _S320 = gridFor_0(&s_10->medium2_0, &s_10->grid2_0, ro_2);
    MajorantGrid_0 _S321 = _S320;
    Dda_0 _S322 = ddaInit_0(&_S321, ro_2, rd_2, _S319);
    Dda_0 ddaB_0 = _S322;
    MajorantGrid_0 _S323 = _S320;
    float _S324 = gridBound_0(&s_10->medium2_0, &_S323, bounds_4, drift_2, (&ddaB_0)->cell_0, (&s_10->medium2_0)->majorant_0);
    float rateB_0 = _S324 * _S312;
    int budgetB_0 = int(4096);
    float keepB_0 = 0.0f;
    float rouletteB_0 = 0.0f;
    if(haveB_0)
    {
        MajorantGrid_0 _S325 = _S320;
        bool _S326 = segmentStep_0(&s_10->medium2_0, &_S325, bounds_4, drift_2, _S312, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S311, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
        haveB_0 = _S326;
    }
    float kept_1 = 0.0f;
    float3  keptAt_1 = none_0;
    int keptLayer_1 = int(0);
    float keptT_1 = 0.0f;
    float tr_4 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        bool _S327;
        if(haveA_0)
        {
            _S327 = true;
        }
        else
        {
            _S327 = haveB_0;
        }
        if(_S327)
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
        float3  p_20 = ro_2 + rd_2 * make_float3 (ph0_0);
        float sigma_0;
        if(takeA_0)
        {
            float _S328 = densityAt_0(&s_10->medium_0, drift_2, p_20);
            sigma_0 = _S328;
        }
        else
        {
            float _S329 = densityAt_0(&s_10->medium2_0, drift_2, p_20);
            sigma_0 = _S329;
        }
        if(sigma_0 > 0.0f)
        {
            float w_2 = sigma_0 / rate_1;
            float b_7 = tr_4 * w_2;
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
                    keptAt_0 = p_20;
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
            float tr_5 = tr_4 * (F32_max((0.0f), (1.0f - w_2)));
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
            bool _S330 = segmentStep_0(&s_10->medium_0, &s_10->grid_0, bounds_4, drift_2, _S312, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
            haveA_0 = _S330;
        }
        else
        {
            MajorantGrid_0 _S331 = _S320;
            bool _S332 = segmentStep_0(&s_10->medium2_0, &_S331, bounds_4, drift_2, _S312, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S311, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
            haveB_0 = _S332;
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
    float3  _S333 = s_10->sunDir_0;
    float _S334 = sceneTransmittance_0(s_10, bounds_4, drift_2, rng_3, keptAt_0 + s_10->sunDir_0 * make_float3 (s_10->shadowOffset_0), s_10->sunDir_0, steps_3);
    float3  _S335 = s_10->albedo_0;
    float3  matterAlbedo_0;
    if(keptLayer_0 == int(0))
    {
        float _S336 = phaseCamera_0(ph_0, dot_0(rd_2, _S333));
        matterAlbedo_0 = _S335;
        ph0_0 = _S336;
    }
    else
    {
        float _S337 = phaseCamera_0(&s_10->phase2_0, dot_0(rd_2, _S333));
        matterAlbedo_0 = s_10->albedo2_0;
        ph0_0 = _S337;
    }
    float3  _S338 = make_float3 (1.0f, 1.0f, 1.0f);
    if(((&s_10->environment_0)->envMode_0) == int(1))
    {
        haveA_0 = (s_10->aerialMode_0) != int(0);
    }
    else
    {
        haveA_0 = false;
    }
    float3  air_0;
    if(haveA_0)
    {
        float3  _S339 = airTransmittance_0(&(&s_10->environment_0)->sky_0, ro_2.y, rd_2, keptT_0);
        air_0 = _S339;
    }
    else
    {
        air_0 = _S338;
    }
    float3  _S340 = make_float3 (total_0) * matterAlbedo_0 * make_float3 (ph0_0) * make_float3 (_S334);
    float3  _S341 = sunIrradianceAt_0(s_10, keptAt_0);
    return _S340 * _S341 * air_0;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_7, MajorantGrid_0 * g_16, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > disp_8, Rng_0 * rng_4, float3  ro_3, float3  rd_3, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_4)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S342 = slabRange_0(m_7, ro_3, rd_3, &t0_3, &t1_3);
    if(!_S342)
    {
        return false;
    }
    float _S343 = (F32_min((t1_3), (tLimit_0)));
    t1_3 = _S343;
    if(!(_S343 > t0_3))
    {
        return false;
    }
    float _S344 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S345 = ddaInit_0(g_16, ro_3, rd_3, _S344);
    Dda_0 dda_2 = _S345;
    float _S346 = m_7->majorant_0;
    float _S347 = gridBound_0(m_7, g_16, bounds_5, disp_8, (&dda_2)->cell_0, m_7->majorant_0);
    float localMaj_1 = _S347;
    int i_19 = int(0);
    float t_8 = _S344;
    for(;;)
    {
        if(i_19 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_4 = *steps_4 + int(1);
        Dda_0 _S348 = dda_2;
        float _S349 = ddaExit_0(&_S348);
        float _S350 = (F32_min((_S349), (t1_3)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S350 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S351 = gridBound_0(m_7, g_16, bounds_5, disp_8, (&dda_2)->cell_0, _S346);
            localMaj_1 = _S351;
            t_8 = _S350;
            i_19 = i_19 + int(1);
            continue;
        }
        float _S352 = randFloat_0(rng_4);
        float t_9 = t_8 - (F32_log(((F32_max((1.0f - _S352), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_9 >= _S350)
        {
            if(_S350 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S353 = gridBound_0(m_7, g_16, bounds_5, disp_8, (&dda_2)->cell_0, _S346);
            localMaj_1 = _S353;
            t_8 = _S350;
            i_19 = i_19 + int(1);
            continue;
        }
        float3  p_21 = ro_3 + rd_3 * make_float3 (t_9);
        float _S354 = randFloat_0(rng_4);
        float _S355 = densityAt_0(m_7, disp_8, p_21);
        if(_S354 < (_S355 / localMaj_1))
        {
            *scatterPoint_0 = p_21;
            *distance_0 = t_9;
            return true;
        }
        t_8 = t_9;
        i_19 = i_19 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_8, MajorantGrid_0 * g_17, StructuredBuffer<float> bounds_6, StructuredBuffer<float2 > disp_9, Rng_0 * rng_5, float3  ro_4, float3  rd_4, float3  * scatterPoint_1, float * distance_1, int * steps_5)
{
    bool _S356 = sampleFreeFlightUpTo_0(m_8, g_17, bounds_6, disp_9, rng_5, ro_4, rd_4, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_5);
    return _S356;
}

static __device__ bool sceneFreeFlight_0(Scene_0 * s_11, StructuredBuffer<float> bounds_7, StructuredBuffer<float2 > drift_3, Rng_0 * rng_6, float3  ro_5, float3  rd_5, float3  * scatterAt_0, int * layer_0, int * steps_6)
{
    *layer_0 = int(0);
    float dist_2;
    if((s_11->layer2On_0) == int(0))
    {
        bool _S357 = sampleFreeFlight_0(&s_11->medium_0, &s_11->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, scatterAt_0, &dist_2, steps_6);
        return _S357;
    }
    float a0_0;
    float a1_0;
    bool _S358 = slabRange_0(&s_11->medium_0, ro_5, rd_5, &a0_0, &a1_0);
    float b0_0;
    float b1_0;
    bool _S359 = slabRange_0(&s_11->medium2_0, ro_5, rd_5, &b0_0, &b1_0);
    bool secondFirst_0;
    if(_S359)
    {
        if(!_S358)
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
    MajorantGrid_0 _S360 = gridFor_0(&s_11->medium2_0, &s_11->grid2_0, ro_5);
    float _S361;
    if(secondFirst_0)
    {
        MajorantGrid_0 _S362 = _S360;
        bool _S363 = sampleFreeFlight_0(&s_11->medium2_0, &_S362, bounds_7, drift_3, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S363)
        {
            _S361 = dNear_1;
        }
        else
        {
            _S361 = 1.00000001504746622e+30f;
        }
        bool _S364 = sampleFreeFlightUpTo_0(&s_11->medium_0, &s_11->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, _S361, &pFar_0, &dFar_0, steps_6);
        if(_S364)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(0);
            return true;
        }
        if(_S363)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(1);
            return true;
        }
    }
    else
    {
        bool _S365 = sampleFreeFlight_0(&s_11->medium_0, &s_11->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S365)
        {
            _S361 = dNear_1;
        }
        else
        {
            _S361 = 1.00000001504746622e+30f;
        }
        MajorantGrid_0 _S366 = _S360;
        bool _S367 = sampleFreeFlightUpTo_0(&s_11->medium2_0, &_S366, bounds_7, drift_3, rng_6, ro_5, rd_5, _S361, &pFar_0, &dFar_0, steps_6);
        if(_S367)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(1);
            return true;
        }
        if(_S365)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(0);
            return true;
        }
    }
    *scatterAt_0 = make_float3 (0.0f, 0.0f, 0.0f);
    return false;
}

static __device__ float2  airMapAxisV_0(LayerShadowMap_0 * m_9)
{
    return make_float2 (- m_9->smAxisU_0.y, m_9->smAxisU_0.x);
}

static __device__ float airMapTexel_0(LayerShadowMap_0 * m_10, int iu_0, int iv_0, int k_3)
{
    float _S368 = __ldg((&(m_10->smTexels_0)[(k_3 * m_10->smDimV_0 + iv_0) * m_10->smDimU_0 + iu_0]));
    return _S368;
}

static __device__ float layerMapTransmittance_0(LayerShadowMap_0 * m_11, float3  p_22)
{
    int _S369 = m_11->smDimU_0;
    int _S370 = m_11->smDimV_0;
    int _S371 = m_11->smSlices_0;
    uint want_0 = uint(m_11->smDimU_0 * m_11->smDimV_0 * m_11->smSlices_0);
    bool _S372;
    if(want_0 == 0U)
    {
        _S372 = true;
    }
    else
    {
        _S372 = uint(StructuredBuffer_getCount_0(m_11->smTexels_0)) < want_0;
    }
    if(_S372)
    {
        return 1.0f;
    }
    float _S373 = p_22.y;
    float _S374 = m_11->smTop_0;
    if(_S373 >= (m_11->smTop_0))
    {
        return 1.0f;
    }
    float3  _S375 = m_11->smSun_0;
    float _S376 = m_11->smBottom_0;
    float2  q_11 = float2 {p_22.x, p_22.z} + float2 {_S375.x, _S375.z} * make_float2 ((m_11->smBottom_0 - _S373) / m_11->smSun_0.y) - m_11->smCentre_0;
    float2  _S377 = m_11->smLo_0;
    float2  _S378 = m_11->smTexel_0;
    float fu_0 = (dot_1(q_11, m_11->smAxisU_0) - m_11->smLo_0.x) / m_11->smTexel_0.x - 0.5f;
    float2  _S379 = airMapAxisV_0(m_11);
    float fv_0 = (dot_1(q_11, _S379) - _S377.y) / _S378.y - 0.5f;
    if(fu_0 >= -0.5f)
    {
        _S372 = fv_0 >= -0.5f;
    }
    else
    {
        _S372 = false;
    }
    if(_S372)
    {
        _S372 = fu_0 <= (float(_S369) - 0.5f);
    }
    else
    {
        _S372 = false;
    }
    if(_S372)
    {
        _S372 = fv_0 <= (float(_S370) - 0.5f);
    }
    else
    {
        _S372 = false;
    }
    if(!_S372)
    {
        return 1.0f;
    }
    int _S380 = _S369 - int(1);
    float fu_1 = clampf_0(fu_0, 0.0f, float(_S380));
    int _S381 = _S370 - int(1);
    float fv_1 = clampf_0(fv_0, 0.0f, float(_S381));
    int u0_0 = int(fu_1);
    int v0_0 = int(fv_1);
    int _S382 = (I32_min((u0_0 + int(1)), (_S380)));
    int _S383 = (I32_min((v0_0 + int(1)), (_S381)));
    float tu_0 = fu_1 - float(u0_0);
    float tv_0 = fv_1 - float(v0_0);
    int _S384 = _S371 - int(1);
    float fk_0 = clampf_0((_S373 - _S376) / (F32_max((_S374 - _S376), (1.0f))), 0.0f, 1.0f) * float(_S384);
    int _S385 = (I32_min((int(fk_0)), (_S384)));
    int _S386 = (I32_min((_S385 + int(1)), (_S384)));
    float tk_0 = fk_0 - float(_S385);
    float _S387 = airMapTexel_0(m_11, u0_0, v0_0, _S385);
    float _S388 = 1.0f - tu_0;
    float _S389 = _S387 * _S388;
    float _S390 = airMapTexel_0(m_11, _S382, v0_0, _S385);
    float a0_1 = _S389 + _S390 * tu_0;
    float _S391 = airMapTexel_0(m_11, u0_0, _S383, _S385);
    float _S392 = _S391 * _S388;
    float _S393 = airMapTexel_0(m_11, _S382, _S383, _S385);
    float b0_1 = _S392 + _S393 * tu_0;
    float _S394 = airMapTexel_0(m_11, u0_0, v0_0, _S386);
    float _S395 = _S394 * _S388;
    float _S396 = airMapTexel_0(m_11, _S382, v0_0, _S386);
    float a1_1 = _S395 + _S396 * tu_0;
    float _S397 = airMapTexel_0(m_11, u0_0, _S383, _S386);
    float _S398 = _S397 * _S388;
    float _S399 = airMapTexel_0(m_11, _S382, _S383, _S386);
    float _S400 = 1.0f - tv_0;
    return (a0_1 * _S400 + b0_1 * tv_0) * (1.0f - tk_0) + (a1_1 * _S400 + (_S398 + _S399 * tu_0) * tv_0) * tk_0;
}

static __device__ float groundShadow_0(LayerShadowMap_0 * mapA_0, LayerShadowMap_0 * mapB_0, float3  origin_1, float3  dir_2)
{
    float _S401 = dir_2.y;
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
    float3  ground_0 = origin_1 + dir_2 * make_float3 (origin_1.y / - _S401);
    *&((&ground_0)->y) = 0.0f;
    float _S403 = layerMapTransmittance_0(mapA_0, ground_0);
    float _S404 = layerMapTransmittance_0(mapB_0, ground_0);
    return _S403 * _S404;
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_23, float originAltitude_1, float3  rayDir_1, bool includeSunDisc_0, float groundLit_0)
{
    float hc_1;
    float3  _S405 = sunDirection_0(p_23);
    float _S406 = p_23->planetRadius_0;
    float planetRadius_5;
    if((p_23->planetRadius_0) > 1000.0f)
    {
        planetRadius_5 = _S406;
    }
    else
    {
        planetRadius_5 = 1000.0f;
    }
    float _S407 = p_23->scaleHeight_0;
    float scaleHeight_3;
    if((p_23->scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = _S407;
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
    float _S408 = planetRadius_5 + observerAltitude_1;
    float _S409 = rayDir_1.y;
    float b_8 = _S408 * _S409;
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
    float betaM_0 = mieCoefficient_0(p_23->turbidity_0);
    float betaMExt_1 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_1, _S405), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_18 = clampf_0(p_23->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S410 = g_18 * g_18;
    float hgDenom_0 = 1.0f + _S410 - 2.0f * g_18 * cosTheta_0;
    float _S411 = 1.0f - _S410;
    float _S412 = 12.56637096405029297f * hgDenom_0;
    float tPrev_1;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_1 = hgDenom_0;
    }
    else
    {
        tPrev_1 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S411 / (_S412 * (F32_sqrt((tPrev_1))));
    float3  _S413 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_1 = 0.0f;
    float3  sumR_0 = _S413;
    float3  sumM_0 = _S413;
    int i_20 = int(0);
    float depthR_1 = 0.0f;
    float depthM_2 = 0.0f;
    for(;;)
    {
        if(i_20 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S414 = i_20 + int(1);
        float tNext_1 = observerAltitude_1 * float(_S414 * _S414) * 0.00173611112404615f;
        float dt_1 = tNext_1 - tPrev_1;
        float tMid_1 = (tPrev_1 + tNext_1) * 0.5f;
        if(dt_1 <= 0.0f)
        {
            tPrev_1 = tNext_1;
            i_20 = _S414;
            continue;
        }
        float h_5 = altitudeFromQ_0(cGround_1 + 2.0f * tMid_1 * b_8 + tMid_1 * tMid_1, planetRadius_5);
        if(h_5 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_5;
        }
        float _S415 = - hc_1;
        float dR_0 = (F32_exp((_S415 / scaleHeight_3))) * dt_1;
        float dM_0 = (F32_exp((_S415 / 1200.0f))) * dt_1;
        float midR_0 = depthR_1 + 0.5f * dR_0;
        float midM_0 = depthM_2 + 0.5f * dM_0;
        float depthR_2 = depthR_1 + dR_0;
        float depthM_3 = depthM_2 + dM_0;
        float3  _S416 = sampleTransmittanceLut_0(p_23, hc_1, lutMuFor_0(make_float3 (rayDir_1.x * tMid_1, _S408 + _S409 * tMid_1, rayDir_1.z * tMid_1), _S405));
        float _S417 = betaMExt_1 * midM_0;
        float3  transmittance_1 = make_float3 ((F32_exp((- (betaR_1.x * midR_0 + _S417)))), (F32_exp((- (betaR_1.y * midR_0 + _S417)))), (F32_exp((- (betaR_1.z * midR_0 + _S417))))) * _S416;
        float3  _S418 = sumM_0 + transmittance_1 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_1 * make_float3 (dR_0);
        sumM_0 = _S418;
        depthR_1 = depthR_2;
        depthM_2 = depthM_3;
        tPrev_1 = tNext_1;
        i_20 = _S414;
    }
    float _S419 = sunIrradianceTop_0(p_23);
    float3  radiance_0 = (sumR_0 * betaR_1 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S419);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_1.x * tGround_1, _S408 + _S409 * tGround_1, rayDir_1.z * tGround_1);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S405), 0.0f, 1.0f);
        float3  _S420 = sampleTransmittanceLut_0(p_23, 0.0f, lutMuFor_0(groundPoint_0, _S405));
        float _S421 = betaMExt_1 * depthM_2;
        float3  viewT_0 = make_float3 ((F32_exp((- (betaR_1.x * depthR_1 + _S421)))), (F32_exp((- (betaR_1.y * depthR_1 + _S421)))), (F32_exp((- (betaR_1.z * depthR_1 + _S421)))));
        radiance_1 = radiance_0 + viewT_0 * _S420 * make_float3 (p_23->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S419 * groundLit_0) + viewT_0 * p_23->groundSkyLight_0;
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S422;
    if(!hitsGround_0)
    {
        _S422 = includeSunDisc_0;
    }
    else
    {
        _S422 = false;
    }
    if(_S422)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_23->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S423 = betaMExt_1 * depthM_2;
            float3  viewT_1 = make_float3 ((F32_exp((- (betaR_1.x * depthR_1 + _S423)))), (F32_exp((- (betaR_1.y * depthR_1 + _S423)))), (F32_exp((- (betaR_1.z * depthR_1 + _S423)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_1 = solidAngle_0;
            }
            else
            {
                hc_1 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_1 * make_float3 (_S419 / hc_1);
        }
    }
    return radiance_1;
}

static __device__ float3  environmentRadiance_0(Environment_0 * e_0, float3  origin_2, float3  dir_3, bool includeSunDisc_1, float groundLit_1)
{
    if((e_0->envMode_0) == int(1))
    {
        float3  _S424 = skyRadiance_0(&e_0->sky_0, origin_2.y, dir_3, includeSunDisc_1, groundLit_1);
        return _S424;
    }
    return e_0->uniformRadiance_0;
}

static __device__ bool layerMapRange_0(LayerShadowMap_0 * m_12, float3  ro_6, float3  rd_6, float * t0_4, float * t1_4)
{
    *t0_4 = 0.0f;
    *t1_4 = 1.00000001504746622e+30f;
    int _S425 = m_12->smDimU_0;
    int _S426 = m_12->smDimV_0;
    uint want_1 = uint(m_12->smDimU_0 * m_12->smDimV_0 * m_12->smSlices_0);
    bool _S427;
    if(want_1 == 0U)
    {
        _S427 = true;
    }
    else
    {
        _S427 = uint(StructuredBuffer_getCount_0(m_12->smTexels_0)) < want_1;
    }
    if(_S427)
    {
        return false;
    }
    float _S428 = rd_6.y;
    if((F32_abs((_S428))) < 9.99999971718068537e-10f)
    {
        if((ro_6.y) >= (m_12->smTop_0))
        {
            return false;
        }
    }
    else
    {
        float tt_0 = (m_12->smTop_0 - ro_6.y) / _S428;
        if(_S428 > 0.0f)
        {
            *t1_4 = (F32_min((*t1_4), (tt_0)));
        }
        else
        {
            *t0_4 = (F32_max((*t0_4), (tt_0)));
        }
    }
    float3  _S429 = m_12->smSun_0;
    float2  _S430 = float2 {_S429.x, _S429.z};
    float _S431 = m_12->smSun_0.y;
    float2  q0_3 = float2 {ro_6.x, ro_6.z} + _S430 * make_float2 ((m_12->smBottom_0 - ro_6.y) / _S431) - m_12->smCentre_0;
    float2  dq_0 = float2 {rd_6.x, rd_6.z} - _S430 * make_float2 (_S428 / _S431);
    float2  _S432 = airMapAxisV_0(m_12);
    float _S433 = m_12->smLo_0.x;
    float _S434 = m_12->smLo_0.y;
    float vHi_0 = _S434 + float(_S426) * m_12->smTexel_0.y;
    bool _S435 = clipAxis_0(dot_1(q0_3, m_12->smAxisU_0), dot_1(dq_0, m_12->smAxisU_0), _S433, _S433 + float(_S425) * m_12->smTexel_0.x, t0_4, t1_4);
    if(!_S435)
    {
        return false;
    }
    bool _S436 = clipAxis_0(dot_1(q0_3, _S432), dot_1(dq_0, _S432), _S434, vHi_0, t0_4, t1_4);
    if(!_S436)
    {
        return false;
    }
    return (*t1_4) > (*t0_4);
}

static __device__ float3  airShadowLoss_0(SkyInput_0 * p_24, LayerShadowMap_0 * mapA_1, LayerShadowMap_0 * mapB_1, float3  ro_7, float3  rd_7, float dist_3, float jitter_1)
{
    float3  none_1 = make_float3 (0.0f, 0.0f, 0.0f);
    float r0_0;
    float r1_0;
    bool _S437 = layerMapRange_0(mapA_1, ro_7, rd_7, &r0_0, &r1_0);
    float tA_1;
    float tB_1;
    if(_S437)
    {
        float _S438 = (F32_max((-1.00000001504746622e+30f), (r1_0)));
        tA_1 = (F32_min((1.00000001504746622e+30f), (r0_0)));
        tB_1 = _S438;
    }
    else
    {
        tA_1 = 1.00000001504746622e+30f;
        tB_1 = -1.00000001504746622e+30f;
    }
    bool _S439 = layerMapRange_0(mapB_1, ro_7, rd_7, &r0_0, &r1_0);
    if(_S439)
    {
        float _S440 = (F32_min((tA_1), (r0_0)));
        tB_1 = (F32_max((tB_1), (r1_0)));
        tA_1 = _S440;
    }
    if(!(tB_1 > tA_1))
    {
        return none_1;
    }
    float3  _S441 = sunDirection_0(p_24);
    float _S442 = p_24->planetRadius_0;
    float planetRadius_6;
    if((p_24->planetRadius_0) > 1000.0f)
    {
        planetRadius_6 = _S442;
    }
    else
    {
        planetRadius_6 = 1000.0f;
    }
    float _S443 = p_24->scaleHeight_0;
    float scaleHeight_4;
    if((p_24->scaleHeight_0) > 1.0f)
    {
        scaleHeight_4 = _S443;
    }
    else
    {
        scaleHeight_4 = 1.0f;
    }
    float atmosphereHeight_2 = scaleHeight_4 * 8.0f;
    float _S444 = ro_7.y;
    float observerAltitude_2;
    if(_S444 > 0.0f)
    {
        observerAltitude_2 = _S444;
    }
    else
    {
        observerAltitude_2 = 0.0f;
    }
    float _S445 = planetRadius_6 + observerAltitude_2;
    float _S446 = rd_7.y;
    float b_9 = _S445 * _S446;
    float cGround_2 = shellC_0(observerAltitude_2, planetRadius_6, 0.0f);
    float tTop_2 = shellExit_0(b_9, shellC_0(observerAltitude_2, planetRadius_6, atmosphereHeight_2));
    bool _S447;
    if(tTop_2 <= 0.0f)
    {
        _S447 = true;
    }
    else
    {
        _S447 = !(dist_3 > 0.0f);
    }
    if(_S447)
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
    float _S448 = (F32_max((tA_1), (0.0f)));
    float _S449 = (F32_min((tB_1), (tMax_2)));
    if(!(_S449 > _S448))
    {
        return none_1;
    }
    float3  betaR_2 = rayleighCoefficients_0();
    float betaM_1 = mieCoefficient_0(p_24->turbidity_0);
    float _S450 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rd_7, _S441), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_19 = clampf_0(p_24->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S451 = g_19 * g_19;
    float hgDenom_1 = 1.0f + _S451 - 2.0f * g_19 * cosTheta_1;
    float _S452 = 1.0f - _S451;
    float _S453 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        tA_1 = hgDenom_1;
    }
    else
    {
        tA_1 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S452 / (_S453 * (F32_sqrt((tA_1))));
    float depthR_3;
    float depthM_4;
    float hc_2;
    int i_21;
    if(_S448 > 0.0f)
    {
        float _S454 = _S448 / 8.0f;
        i_21 = int(0);
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
        for(;;)
        {
            if(i_21 < int(8))
            {
            }
            else
            {
                break;
            }
            float tm_0 = (float(i_21) + 0.5f) * _S454;
            float h_6 = altitudeFromQ_0(cGround_2 + 2.0f * tm_0 * b_9 + tm_0 * tm_0, planetRadius_6);
            if(h_6 < 0.0f)
            {
                hc_2 = 0.0f;
            }
            else
            {
                hc_2 = h_6;
            }
            float _S455 = - hc_2;
            float depthR_4 = depthR_3 + (F32_exp((_S455 / scaleHeight_4))) * _S454;
            float depthM_5 = depthM_4 + (F32_exp((_S455 / 1200.0f))) * _S454;
            i_21 = i_21 + int(1);
            depthR_3 = depthR_4;
            depthM_4 = depthM_5;
        }
    }
    else
    {
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
    }
    float _S456 = clampf_0(jitter_1, 0.0f, 1.0f);
    float _S457 = _S449 - _S448;
    float3  lossR_0 = none_1;
    float3  lossM_0 = none_1;
    i_21 = int(0);
    for(;;)
    {
        if(i_21 < int(48))
        {
        }
        else
        {
            break;
        }
        float s0_0 = _S448 + _S457 * float(i_21 * i_21) * 0.00043402778101154f;
        int _S458 = i_21 + int(1);
        float dt_2 = _S448 + _S457 * float(_S458 * _S458) * 0.00043402778101154f - s0_0;
        float ts_0 = s0_0 + _S456 * dt_2;
        float h_7 = altitudeFromQ_0(cGround_2 + 2.0f * ts_0 * b_9 + ts_0 * ts_0, planetRadius_6);
        if(h_7 < 0.0f)
        {
            hc_2 = 0.0f;
        }
        else
        {
            hc_2 = h_7;
        }
        float _S459 = - hc_2;
        float rhoR_0 = (F32_exp((_S459 / scaleHeight_4)));
        float rhoM_0 = (F32_exp((_S459 / 1200.0f)));
        float _S460 = ts_0 - s0_0;
        float atR_0 = depthR_3 + rhoR_0 * _S460;
        float atM_0 = depthM_4 + rhoM_0 * _S460;
        float depthR_5 = depthR_3 + rhoR_0 * dt_2;
        float depthM_6 = depthM_4 + rhoM_0 * dt_2;
        float3  pw_0 = ro_7 + rd_7 * make_float3 (ts_0);
        float _S461 = layerMapTransmittance_0(mapA_1, pw_0);
        float _S462 = layerMapTransmittance_0(mapB_1, pw_0);
        float v_8 = _S461 * _S462;
        if(v_8 >= 1.0f)
        {
            i_21 = _S458;
            depthR_3 = depthR_5;
            depthM_4 = depthM_6;
            continue;
        }
        float3  _S463 = sampleTransmittanceLut_0(p_24, hc_2, lutMuFor_0(make_float3 (rd_7.x * ts_0, _S445 + _S446 * ts_0, rd_7.z * ts_0), _S441));
        float _S464 = _S450 * atM_0;
        float3  w_3 = make_float3 ((F32_exp((- (betaR_2.x * atR_0 + _S464)))), (F32_exp((- (betaR_2.y * atR_0 + _S464)))), (F32_exp((- (betaR_2.z * atR_0 + _S464))))) * _S463 * make_float3 ((1.0f - v_8) * dt_2);
        float3  _S465 = lossM_0 + w_3 * make_float3 (rhoM_0);
        lossR_0 = lossR_0 + w_3 * make_float3 (rhoR_0);
        lossM_0 = _S465;
        i_21 = _S458;
        depthR_3 = depthR_5;
        depthM_4 = depthM_6;
    }
    float3  _S466 = lossR_0 * betaR_2 * make_float3 (phaseR_1) + lossM_0 * make_float3 (betaM_1 * phaseM_1);
    float _S467 = sunIrradianceTop_0(p_24);
    return _S466 * make_float3 (_S467);
}

struct AirSegment_0
{
    float3  airIn_0;
    float3  airT_0;
    float shadowAt_0;
};

static __device__ AirSegment_0 airSegment_0(SkyInput_0 * p_25, float originAltitude_2, float3  rayDir_2, float dist_4, float u1_0, float u2_0)
{
    AirSegment_0 seg_0;
    float3  _S468 = make_float3 (0.0f, 0.0f, 0.0f);
    (&seg_0)->airIn_0 = _S468;
    (&seg_0)->airT_0 = make_float3 (1.0f, 1.0f, 1.0f);
    (&seg_0)->shadowAt_0 = -1.0f;
    float3  _S469 = sunDirection_0(p_25);
    float _S470 = p_25->planetRadius_0;
    float planetRadius_7;
    if((p_25->planetRadius_0) > 1000.0f)
    {
        planetRadius_7 = _S470;
    }
    else
    {
        planetRadius_7 = 1000.0f;
    }
    float _S471 = p_25->scaleHeight_0;
    float scaleHeight_5;
    if((p_25->scaleHeight_0) > 1.0f)
    {
        scaleHeight_5 = _S471;
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
    float _S472 = planetRadius_7 + observerAltitude_3;
    float _S473 = rayDir_2.y;
    float b_10 = _S472 * _S473;
    float cGround_3 = shellC_0(observerAltitude_3, planetRadius_7, 0.0f);
    float tTop_3 = shellExit_0(b_10, shellC_0(observerAltitude_3, planetRadius_7, atmosphereHeight_3));
    bool _S474;
    if(tTop_3 <= 0.0f)
    {
        _S474 = true;
    }
    else
    {
        _S474 = !(dist_4 > 0.0f);
    }
    if(_S474)
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
    float betaM_2 = mieCoefficient_0(p_25->turbidity_0);
    float betaMExt_2 = betaM_2 * 1.11000001430511475f;
    float cosTheta_2 = clampf_0(dot_0(rayDir_2, _S469), -1.0f, 1.0f);
    float phaseR_2 = 0.05968309938907623f * (1.0f + cosTheta_2 * cosTheta_2);
    float g_20 = clampf_0(p_25->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S475 = g_20 * g_20;
    float hgDenom_2 = 1.0f + _S475 - 2.0f * g_20 * cosTheta_2;
    float _S476 = 1.0f - _S475;
    float _S477 = 12.56637096405029297f * hgDenom_2;
    if(hgDenom_2 > 9.99999997475242708e-07f)
    {
        observerAltitude_3 = hgDenom_2;
    }
    else
    {
        observerAltitude_3 = 9.99999997475242708e-07f;
    }
    float phaseM_2 = _S476 / (_S477 * (F32_sqrt((observerAltitude_3))));
    float tPrev_2 = 0.0f;
    float3  sumR_1 = _S468;
    float3  sumM_1 = _S468;
    float u_3 = u1_0;
    float pickedFrom_0 = -1.0f;
    float pickedSpan_0 = 0.0f;
    int i_22 = int(0);
    float depthR_6 = 0.0f;
    float depthM_7 = 0.0f;
    float lumTotal_0 = 0.0f;
    for(;;)
    {
        if(i_22 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S478 = i_22 + int(1);
        float tNext_2 = tMax_3 * float(_S478 * _S478) * 0.00173611112404615f;
        float dt_3 = tNext_2 - tPrev_2;
        float tMid_2 = (tPrev_2 + tNext_2) * 0.5f;
        float u_4;
        float pickedFrom_1;
        float pickedSpan_1;
        if(dt_3 <= 0.0f)
        {
            u_4 = u_3;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            tPrev_2 = tNext_2;
            u_3 = u_4;
            pickedFrom_0 = pickedFrom_1;
            pickedSpan_0 = pickedSpan_1;
            i_22 = _S478;
            continue;
        }
        float h_8 = altitudeFromQ_0(cGround_3 + 2.0f * tMid_2 * b_10 + tMid_2 * tMid_2, planetRadius_7);
        float hc_3;
        if(h_8 < 0.0f)
        {
            hc_3 = 0.0f;
        }
        else
        {
            hc_3 = h_8;
        }
        float _S479 = - hc_3;
        float dR_1 = (F32_exp((_S479 / scaleHeight_5))) * dt_3;
        float dM_1 = (F32_exp((_S479 / 1200.0f))) * dt_3;
        float midR_1 = depthR_6 + 0.5f * dR_1;
        float midM_1 = depthM_7 + 0.5f * dM_1;
        float depthR_7 = depthR_6 + dR_1;
        float depthM_8 = depthM_7 + dM_1;
        float3  _S480 = sampleTransmittanceLut_0(p_25, hc_3, lutMuFor_0(make_float3 (rayDir_2.x * tMid_2, _S472 + _S473 * tMid_2, rayDir_2.z * tMid_2), _S469));
        float _S481 = betaMExt_2 * midM_1;
        float3  transmittance_2 = make_float3 ((F32_exp((- (betaR_3.x * midR_1 + _S481)))), (F32_exp((- (betaR_3.y * midR_1 + _S481)))), (F32_exp((- (betaR_3.z * midR_1 + _S481))))) * _S480;
        float3  _S482 = sumR_1 + transmittance_2 * make_float3 (dR_1);
        float3  _S483 = sumM_1 + transmittance_2 * make_float3 (dM_1);
        float3  c_30 = transmittance_2 * (betaR_3 * make_float3 (phaseR_2 * dR_1) + make_float3 (betaM_2 * (phaseM_2 * dM_1)));
        float lum_0 = c_30.x + c_30.y + c_30.z;
        float lumTotal_1;
        if(lum_0 > 0.0f)
        {
            float lumTotal_2 = lumTotal_0 + lum_0;
            float keep_3 = lum_0 / lumTotal_2;
            if(u_3 < keep_3)
            {
                u_4 = u_3 / keep_3;
                pickedFrom_1 = tPrev_2;
                pickedSpan_1 = dt_3;
            }
            else
            {
                u_4 = (u_3 - keep_3) / (1.0f - keep_3);
                pickedFrom_1 = pickedFrom_0;
                pickedSpan_1 = pickedSpan_0;
            }
            lumTotal_1 = lumTotal_2;
        }
        else
        {
            u_4 = u_3;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            lumTotal_1 = lumTotal_0;
        }
        sumR_1 = _S482;
        sumM_1 = _S483;
        depthR_6 = depthR_7;
        depthM_7 = depthM_8;
        lumTotal_0 = lumTotal_1;
        tPrev_2 = tNext_2;
        u_3 = u_4;
        pickedFrom_0 = pickedFrom_1;
        pickedSpan_0 = pickedSpan_1;
        i_22 = _S478;
    }
    float _S484 = sunIrradianceTop_0(p_25);
    (&seg_0)->airIn_0 = (sumR_1 * betaR_3 * make_float3 (phaseR_2) + sumM_1 * make_float3 (betaM_2 * phaseM_2)) * make_float3 (_S484);
    float _S485 = betaMExt_2 * depthM_7;
    (&seg_0)->airT_0 = make_float3 ((F32_exp((- (betaR_3.x * depthR_6 + _S485)))), (F32_exp((- (betaR_3.y * depthR_6 + _S485)))), (F32_exp((- (betaR_3.z * depthR_6 + _S485)))));
    if(pickedFrom_0 >= 0.0f)
    {
        (&seg_0)->shadowAt_0 = pickedFrom_0 + clampf_0(u2_0, 0.0f, 1.0f) * pickedSpan_0;
    }
    return seg_0;
}

static __device__ float airShadow_0(Scene_0 * s_12, StructuredBuffer<float> bounds_8, StructuredBuffer<float2 > drift_4, Rng_0 * rng_7, AirSegment_0 * seg_1, float3  ro_8, float3  rd_8, int * steps_7)
{
    bool _S486;
    if((s_12->aerialMode_0) < int(2))
    {
        _S486 = true;
    }
    else
    {
        _S486 = (seg_1->shadowAt_0) < 0.0f;
    }
    if(_S486)
    {
        return 1.0f;
    }
    float _S487 = sceneTransmittance_0(s_12, bounds_8, drift_4, rng_7, ro_8 + rd_8 * make_float3 (seg_1->shadowAt_0), s_12->sunDir_0, steps_7);
    return _S487;
}

static __device__ float3  sampleHG_0(Rng_0 * rng_8, float3  wo_0, float g_21, float * cosT_6)
{
    float _S488 = clamp_0(g_21, -0.99900001287460327f, 0.99900001287460327f);
    float u1_1 = randFloat_0(rng_8);
    float u2_1 = randFloat_0(rng_8);
    if((F32_abs((_S488))) < 0.00100000004749745f)
    {
        *cosT_6 = 1.0f - 2.0f * u1_1;
    }
    else
    {
        float _S489 = _S488 * _S488;
        float _S490 = 2.0f * _S488;
        float s_13 = (1.0f - _S489) / (1.0f - _S488 + _S490 * u1_1);
        *cosT_6 = (1.0f + _S489 - s_13 * s_13) / _S490;
    }
    float _S491 = clamp_0(*cosT_6, -1.0f, 1.0f);
    *cosT_6 = _S491;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S491 * _S491))))));
    float phi_0 = 6.28318548202514648f * u2_1;
    float3  w_4 = normalize_0(wo_0);
    float3  a_7;
    if((F32_abs((w_4.y))) < 0.94999998807907104f)
    {
        a_7 = make_float3 (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_7 = make_float3 (1.0f, 0.0f, 0.0f);
    }
    float3  u_5 = normalize_0(cross_0(a_7, w_4));
    return normalize_0(make_float3 (sinT_0 * (F32_cos((phi_0)))) * u_5 + make_float3 (sinT_0 * (F32_sin((phi_0)))) * cross_0(w_4, u_5) + make_float3 (*cosT_6) * w_4);
}

static __device__ float3  sampleDraine_0(Rng_0 * rng_9, float3  wo_1, float g_22, float a_8, float * cosT_7)
{
    float3  dir_4 = sampleHG_0(rng_9, wo_1, g_22, cosT_7);
    if(!(a_8 > 0.0f))
    {
        return dir_4;
    }
    float3  dir_5 = dir_4;
    int i_23 = int(0);
    for(;;)
    {
        if(i_23 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S492 = randFloat_0(rng_9);
        if((_S492 * (1.0f + a_8)) <= (1.0f + a_8 * *cosT_7 * *cosT_7))
        {
            break;
        }
        float3  _S493 = sampleHG_0(rng_9, wo_1, g_22, cosT_7);
        int i_24 = i_23 + int(1);
        dir_5 = _S493;
        i_23 = i_24;
    }
    return dir_5;
}

static __device__ float3  samplePhaseDir_0(PhaseInput_0 * p_26, Rng_0 * rng_10, float3  wo_2, float * weight_0)
{
    float cosT_8;
    float3  dir_6;
    float _S494;
    if((p_26->useIce_0) != int(0))
    {
        float _S495 = randFloat_0(rng_10);
        if(_S495 < 0.72000002861022949f)
        {
            float3  _S496 = sampleHG_0(rng_10, wo_2, 0.85000002384185791f, &cosT_8);
            dir_6 = _S496;
        }
        else
        {
            float3  _S497 = sampleHG_0(rng_10, wo_2, 0.0f, &cosT_8);
            dir_6 = _S497;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_8, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S494 = phaseIce_0(cosT_8) / pdf_0;
        }
        else
        {
            _S494 = 0.0f;
        }
        *weight_0 = _S494;
    }
    else
    {
        float _S498 = randFloat_0(rng_10);
        if(_S498 < (p_26->draineW_0))
        {
            float3  _S499 = sampleDraine_0(rng_10, wo_2, p_26->draineG_0, p_26->draineAlpha_0, &cosT_8);
            dir_6 = _S499;
        }
        else
        {
            float3  _S500 = sampleHG_0(rng_10, wo_2, p_26->hgG_0, &cosT_8);
            dir_6 = _S500;
        }
        float _S501 = phaseLiquid_0(p_26, cosT_8);
        if(_S501 > 9.99999971718068537e-10f)
        {
            _S494 = 1.0f;
        }
        else
        {
            _S494 = 0.0f;
        }
        *weight_0 = _S494;
    }
    return dir_6;
}

struct TraceResult_0
{
    float3  pathRadiance_0;
    int scatterEvents_0;
    int capped_0;
    int trackingSteps_0;
};

static __device__ TraceResult_0 trace_0(Scene_0 * s_14, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_9, StructuredBuffer<float2 > drift_5, Rng_0 * rng_11, float3  ro_9, float3  rd_9)
{
    TraceResult_0 r_7;
    float3  _S502 = make_float3 (0.0f, 0.0f, 0.0f);
    (&r_7)->pathRadiance_0 = _S502;
    (&r_7)->scatterEvents_0 = int(0);
    (&r_7)->capped_0 = int(0);
    (&r_7)->trackingSteps_0 = int(0);
    float3  throughput_0 = make_float3 (1.0f, 1.0f, 1.0f);
    int _S503 = (I32_min((s_14->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_14->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S503 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    if(sunAlongCamera_0)
    {
        Rng_0 _S504 = *rng_11;
        Rng_0 _S505 = splitRng_0(&_S504, 1510U);
        Rng_0 segmentRng_0 = _S505;
        Rng_0 _S506 = *rng_11;
        Rng_0 _S507 = splitRng_0(&_S506, 1511U);
        Rng_0 _S508 = _S507;
        float3  _S509 = cameraSegmentSun_0(s_14, ph_1, bounds_9, drift_5, &segmentRng_0, &_S508, ro_9, rd_9, &(&r_7)->trackingSteps_0);
        (&r_7)->pathRadiance_0 = (&r_7)->pathRadiance_0 + _S509;
    }
    bool _S510;
    if(((&s_14->environment_0)->envMode_0) == int(1))
    {
        _S510 = (s_14->aerialMode_0) != int(0);
    }
    else
    {
        _S510 = false;
    }
    Rng_0 _S511 = *rng_11;
    Rng_0 _S512 = splitRng_0(&_S511, 2590U);
    Rng_0 airRng_0 = _S512;
    float3  env_0 = ro_9;
    float3  _S513 = rd_9;
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
        if(bounce_0 >= _S503)
        {
            (&r_7)->capped_0 = int(1);
            break;
        }
        float3  p_27;
        int layer_1;
        bool _S514 = sceneFreeFlight_0(s_14, bounds_9, drift_5, rng_11, env_0, _S513, &p_27, &layer_1, &(&r_7)->trackingSteps_0);
        if(!_S514)
        {
            bool _S515 = (s_14->airMapOn_0) != int(0);
            float groundLit_2;
            if(_S515)
            {
                float _S516 = groundShadow_0(&s_14->airMapIce_0, &s_14->airMapCu_0, env_0, _S513);
                groundLit_2 = _S516;
            }
            else
            {
                groundLit_2 = 1.0f;
            }
            bool _S517 = bounce_0 == int(0);
            float3  _S518 = environmentRadiance_0(&s_14->environment_0, env_0, _S513, _S517, groundLit_2);
            if(_S517)
            {
                sunAlongCamera_0 = _S510;
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                sunAlongCamera_0 = (s_14->aerialMode_0) >= int(2);
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                float u1_2 = randFloat_0(&airRng_0);
                float u2_2 = randFloat_0(&airRng_0);
                if(_S515)
                {
                    float3  _S519 = airShadowLoss_0(&(&s_14->environment_0)->sky_0, &s_14->airMapIce_0, &s_14->airMapCu_0, env_0, _S513, 1.00000001504746622e+30f, u2_2);
                    env_0 = max_0(_S518 - _S519, _S502);
                }
                else
                {
                    AirSegment_0 _S520 = airSegment_0(&(&s_14->environment_0)->sky_0, env_0.y, _S513, 1.00000001504746622e+30f, u1_2, u2_2);
                    AirSegment_0 _S521 = _S520;
                    float _S522 = airShadow_0(s_14, bounds_9, drift_5, &airRng_0, &_S521, env_0, _S513, &(&r_7)->trackingSteps_0);
                    env_0 = _S518 - _S520.airIn_0 * make_float3 (1.0f - _S522);
                }
            }
            else
            {
                env_0 = _S518;
            }
            (&r_7)->pathRadiance_0 = (&r_7)->pathRadiance_0 + throughput_1 * env_0;
            break;
        }
        (&r_7)->scatterEvents_0 = (&r_7)->scatterEvents_0 + int(1);
        bool _S523 = bounce_0 == int(0);
        bool _S524;
        if(_S523)
        {
            _S524 = _S510;
        }
        else
        {
            _S524 = false;
        }
        bool _S525;
        float3  throughput_2;
        if(_S524)
        {
            float u1_3 = randFloat_0(&airRng_0);
            float u2_3 = randFloat_0(&airRng_0);
            float dist_5 = length_0(p_27 - env_0);
            AirSegment_0 _S526 = airSegment_0(&(&s_14->environment_0)->sky_0, env_0.y, _S513, dist_5, u1_3, u2_3);
            if((s_14->aerialMode_0) >= int(2))
            {
                _S525 = (s_14->airMapOn_0) != int(0);
            }
            else
            {
                _S525 = false;
            }
            if(_S525)
            {
                float3  _S527 = airShadowLoss_0(&(&s_14->environment_0)->sky_0, &s_14->airMapIce_0, &s_14->airMapCu_0, env_0, _S513, dist_5, u2_3);
                throughput_2 = max_0(_S526.airIn_0 - _S527, _S502);
            }
            else
            {
                AirSegment_0 _S528 = _S526;
                float _S529 = airShadow_0(s_14, bounds_9, drift_5, &airRng_0, &_S528, env_0, _S513, &(&r_7)->trackingSteps_0);
                throughput_2 = _S526.airIn_0 * make_float3 (_S529);
            }
            (&r_7)->pathRadiance_0 = (&r_7)->pathRadiance_0 + throughput_1 * throughput_2;
            throughput_2 = throughput_1 * _S526.airT_0;
        }
        else
        {
            throughput_2 = throughput_1;
        }
        float3  _S530 = s_14->albedo_0;
        float3  matterAlbedo_1;
        PhaseInput_0 matterPhase_0;
        if(layer_1 != int(0))
        {
            matterPhase_0 = s_14->phase2_0;
            matterAlbedo_1 = s_14->albedo2_0;
        }
        else
        {
            matterPhase_0 = *ph_1;
            matterAlbedo_1 = _S530;
        }
        if(_S523)
        {
            _S525 = sunAlongCamera_0;
        }
        else
        {
            _S525 = false;
        }
        if(!_S525)
        {
            float3  _S531 = s_14->sunDir_0;
            float _S532 = sceneTransmittance_0(s_14, bounds_9, drift_5, rng_11, p_27 + s_14->sunDir_0 * make_float3 (s_14->shadowOffset_0), s_14->sunDir_0, &(&r_7)->trackingSteps_0);
            if(_S532 > 0.0f)
            {
                float _S533 = dot_0(_S513, _S531);
                PhaseInput_0 _S534 = matterPhase_0;
                float _S535 = phaseAt_0(&_S534, _S533);
                float3  _S536 = throughput_2 * matterAlbedo_1 * make_float3 (_S535) * make_float3 (_S532);
                float3  _S537 = sunIrradianceAt_0(s_14, p_27);
                (&r_7)->pathRadiance_0 = (&r_7)->pathRadiance_0 + _S536 * _S537;
            }
        }
        PhaseInput_0 _S538 = matterPhase_0;
        float w_5;
        float3  _S539 = samplePhaseDir_0(&_S538, rng_11, _S513, &w_5);
        float3  throughput_3 = throughput_2 * (matterAlbedo_1 * make_float3 (w_5));
        float3  _S540 = p_27;
        if(bounce_0 >= (s_14->rrStartBounce_0))
        {
            float p2_0 = clamp_0((F32_max((throughput_3.x), ((F32_max((throughput_3.y), (throughput_3.z)))))), 0.05000000074505806f, 1.0f);
            float _S541 = randFloat_0(rng_11);
            if(_S541 > p2_0)
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
        env_0 = _S540;
        _S513 = _S539;
        bounce_0 = bounce_1;
    }
    return r_7;
}

static __device__ float3  renderSample_0(Scene_0 * s_15, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_10, StructuredBuffer<float2 > drift_6, float3  ro_10, float3  rd_10, uint seed_1)
{
    Rng_0 rng_12 = makeRng_0(seed_1);
    TraceResult_0 _S542 = trace_0(s_15, ph_2, bounds_10, drift_6, &rng_12, ro_10, rd_10);
    return _S542.pathRadiance_0;
}

extern "C" __global__ void renderRays(Scene_0 scene_0, PhaseInput_0 phase_0, StructuredBuffer<float> bounds_11, StructuredBuffer<float2 > drift_7, StructuredBuffer<float3 > origins_0, StructuredBuffer<float3 > directions_0, RWStructuredBuffer<float3 > outRadiance_0, uint seed_2, int count_0)
{
    int i_25 = int((blockIdx * blockDim + threadIdx).x);
    if(i_25 >= count_0)
    {
        return;
    }
    float3  * _S543 = (&(outRadiance_0)[i_25]);
    float3  _S544 = slang_ldg_0((&(origins_0)[i_25]));
    float3  _S545 = slang_ldg_0((&(directions_0)[i_25]));
    uint _S546 = seed_2 + uint(i_25);
    Scene_0 _S547 = scene_0;
    PhaseInput_0 _S548 = phase_0;
    float3  _S549 = renderSample_0(&_S547, &_S548, bounds_11, drift_7, _S544, _S545, _S546);
    *_S543 = _S549;
    return;
}

static __device__ void layerMapColumn_0(Medium_0 * med_0, StructuredBuffer<float2 > drift_8, LayerShadowMap_0 * m_13, int texel_0, RWStructuredBuffer<float> outTexels_0)
{
    int _S550 = m_13->smDimU_0;
    int stride_0 = m_13->smDimU_0 * m_13->smDimV_0;
    bool _S551;
    if(texel_0 < int(0))
    {
        _S551 = true;
    }
    else
    {
        _S551 = texel_0 >= stride_0;
    }
    if(_S551)
    {
        return;
    }
    int iu_1 = texel_0 % _S550;
    int iv_1 = texel_0 / _S550;
    float2  _S552 = m_13->smLo_0;
    float2  _S553 = m_13->smTexel_0;
    float2  _S554 = m_13->smCentre_0 + m_13->smAxisU_0 * make_float2 (m_13->smLo_0.x + (float(iu_1) + 0.5f) * m_13->smTexel_0.x);
    float2  _S555 = airMapAxisV_0(m_13);
    float2  q_12 = _S554 + _S555 * make_float2 (_S552.y + (float(iv_1) + 0.5f) * _S553.y);
    float3  base_0 = make_float3 (q_12.x, m_13->smBottom_0, q_12.y);
    float3  _S556 = m_13->smSun_0;
    int _S557 = m_13->smSlices_0;
    int _S558 = m_13->smSlices_0 - int(1);
    float _S559 = (m_13->smTop_0 - m_13->smBottom_0) / (float(_S558) * m_13->smSun_0.y);
    float _S560 = (F32_max((m_13->smStep_0), (1.0f)));
    float t0_5;
    float t1_5;
    bool _S561 = slabRange_0(med_0, base_0, m_13->smSun_0, &t0_5, &t1_5);
    *(&(outTexels_0)[_S558 * stride_0 + texel_0]) = 1.0f;
    int k_4 = _S557 - int(2);
    float tau_0 = 0.0f;
    for(;;)
    {
        if(k_4 >= int(0))
        {
        }
        else
        {
            break;
        }
        if(_S561)
        {
            _S551 = tau_0 < 12.0f;
        }
        else
        {
            _S551 = false;
        }
        float tau_1;
        if(_S551)
        {
            float _S562 = (F32_max((float(k_4) * _S559), (t0_5)));
            float _S563 = (F32_min((float(k_4 + int(1)) * _S559), (t1_5)));
            if(_S563 > _S562)
            {
                float _S564 = _S563 - _S562;
                int n_0 = clamp_1(int((F32_ceil((_S564 / _S560)))), int(1), int(1024));
                float _S565 = _S564 / float(n_0);
                int j_10 = int(0);
                tau_1 = tau_0;
                for(;;)
                {
                    if(j_10 < n_0)
                    {
                    }
                    else
                    {
                        break;
                    }
                    float _S566 = densityAt_0(med_0, drift_8, base_0 + _S556 * make_float3 (_S562 + (float(j_10) + 0.5f) * _S565));
                    float tau_2 = tau_1 + _S566 * _S565;
                    j_10 = j_10 + int(1);
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
        float * _S567 = (&(outTexels_0)[k_4 * stride_0 + texel_0]);
        float _S568;
        if(tau_1 < 12.0f)
        {
            _S568 = (F32_exp((- tau_1)));
        }
        else
        {
            _S568 = 0.0f;
        }
        *_S567 = _S568;
        k_4 = k_4 - int(1);
        tau_0 = tau_1;
    }
    return;
}

extern "C" __global__ void buildAirMap(Medium_0 medium_1, StructuredBuffer<float2 > drift_9, LayerShadowMap_0 map_0, RWStructuredBuffer<float> outTexels_1, int count_1)
{
    int i_26 = int((blockIdx * blockDim + threadIdx).x);
    if(i_26 >= count_1)
    {
        return;
    }
    Medium_0 _S569 = medium_1;
    LayerShadowMap_0 _S570 = map_0;
    layerMapColumn_0(&_S569, drift_9, &_S570, i_26, outTexels_1);
    return;
}

