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

static __device__ float dot_1(float2  x_2, float2  y_1)
{
    return x_2.x * y_1.x + x_2.y * y_1.y;
}

static __device__ float3  floor_0(float3  x_3)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_floor((_slang_vector_get_element(x_3, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
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

static __device__ float lerp_0(float x_4, float y_2, float s_0)
{
    return x_4 + (y_2 - x_4) * s_0;
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_0(p_0);
    int3  _S6 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S7 = u_0.x;
    float _S8 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_0(hash33_0(_S6), f_0), dot_0(hash33_0(_S6 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S7), lerp_0(dot_0(hash33_0(_S6 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S6 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S7), _S8), lerp_0(lerp_0(dot_0(hash33_0(_S6 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S6 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S7), lerp_0(dot_0(hash33_0(_S6 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S6 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S7), _S8), u_0.z);
}

static __device__ float2  orgWarpOffset_0(Organization_0 * o_0, float2  g_0)
{
    float2  s_1 = g_0 / make_float2 (2.5f);
    float _S9 = s_1.x;
    float _S10 = s_1.y;
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

static __device__ float2  floor_1(float2  x_5)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_floor((_slang_vector_get_element(x_5, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
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
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_0(0.34999999403953552f, 1.0f, h_2.y);
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

static __device__ float clamp_0(float x_6, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_6), (minBound_0)))), (maxBound_0)));
}

static __device__ float saturate_0(float x_7)
{
    return clamp_0(x_7, 0.0f, 1.0f);
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

static __device__ float2  lerp_1(float2  x_8, float2  y_3, float2  s_2)
{
    return x_8 + (y_3 - x_8) * s_2;
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
        float fill_0 = lerp_0(w_0, 0.40000000596046448f, _S26);
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
        float s_5 = lerp_0(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S30);
        float _S34 = _S28 * s_5;
        _S27 = _S27 * make_float2 (s_5) + gcn_0 * make_float2 (_S28 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S30));
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
        int i_2 = int(-1);
        for(;;)
        {
            if(i_2 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_2 = _S39 + make_int2 (i_2, j_1);
            float _S41 = convVigour_0(c_6, slot_2);
            if(_S41 <= 0.0f)
            {
                i_2 = i_2 + int(1);
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
            i_2 = i_2 + int(1);
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
    float _S48 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_0(_S47, closedField_0, c_6->cvPolarity_0), lerp_1(goTop_0, gClosed_0, make_float2 (c_6->cvPolarity_0)), grad_2);
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
            int2  slot_3 = _S51 + make_int2 (i_3, j_3);
            float _S52 = convVigour_0(c_7, slot_3);
            if(_S52 <= 0.0f)
            {
                i_3 = i_3 + int(1);
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
            i_3 = i_3 + int(1);
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
    float _S59 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_0(_S58, closedField_1, c_7->cvPolarity_0), lerp_1(goTop_3, gClosed_1, make_float2 (c_7->cvPolarity_0)), grad_3);
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
            int2  slot_5 = _S64 + make_int2 (i_4, j_5);
            float _S66 = convVigour_0(c_8, slot_5);
            if(_S66 <= 0.0f)
            {
                i_4 = i_4 + int(1);
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
            i_4 = i_4 + int(1);
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
    *grad_4 = lerp_1(goTop_6, gClosed_2, make_float2 (c_8->cvPolarity_0)) / make_float2 (_S61);
    return lerp_0(_S71, closedField_2, _S72);
}

static __device__ float smoothstep_0(float min_0, float max_0, float x_9)
{
    float _S73 = saturate_0((x_9 - min_0) / (max_0 - min_0));
    return _S73 * _S73 * (3.0f - (_S73 + _S73));
}

static __device__ float length_1(float2  x_10)
{
    return (F32_sqrt((dot_1(x_10, x_10))));
}

static __device__ bool any_0(bool2  x_11)
{
    bool result_2 = false;
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
        if(result_2)
        {
            result_2 = true;
        }
        else
        {
            result_2 = (bool((_slang_vector_get_element(x_11, i_5))));
        }
        i_5 = i_5 + int(1);
    }
    return result_2;
}

static __device__ int clamp_1(int x_12, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_12), (minBound_1)))), (maxBound_1)));
}

static __device__ float2  min_1(float2  x_13, float2  y_4)
{
    float2  result_3;
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
        *_slang_vector_get_element_ptr(&result_3, i_6) = (F32_min((_slang_vector_get_element(x_13, i_6)), (_slang_vector_get_element(y_4, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_3;
}

static __device__ float2  max_1(float2  x_14, float2  y_5)
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
        *_slang_vector_get_element_ptr(&result_4, i_7) = (F32_max((_slang_vector_get_element(x_14, i_7)), (_slang_vector_get_element(y_5, i_7))));
        i_7 = i_7 + int(1);
    }
    return result_4;
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
        lo_1 = max_1(lo_1, m_1->fadeAt_0 - make_float2 (_S84));
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
    float x_15 = clamp_0(depth_0 / g_3->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_8 = clamp_1(int((F32_floor((x_15)))), int(0), int(31));
    float2  _S89 = __ldg((&(disp_0)[i_8]));
    float2  _S90 = __ldg((&(disp_0)[i_8 + int(1)]));
    return lerp_1(_S89, _S90, make_float2 (x_15 - float(i_8)));
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
        int i_9 = int(-1);
        float acc_1 = acc_0;
        for(;;)
        {
            if(i_9 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_7 = _S94 + make_int2 (i_9, j_7);
            if((hash22_0(o_7, 2654435769U).x) > (g_4->cellDensity_0))
            {
                i_9 = i_9 + int(1);
                continue;
            }
            float2  _S96 = make_float2 ((float)o_7.x, (float)o_7.y);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(_S93 - (_S96 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S95)) * 2.20000004768371582f);
            i_9 = i_9 + int(1);
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
    int i_10 = int(0);
    float amp_0 = 0.5f;
    float3  _S99 = p_1;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_10 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_10 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S99);
        float norm_1 = norm_0 + amp_0;
        float3  _S100 = _S99 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_10 = i_10 + int(1);
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

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_11, float2  q_8, float2  * grad_5)
{
    if(((&c_11->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S107 = convUpdraftGradT_2(c_11, q_8, grad_5);
        return _S107;
    }
    if((c_11->cvLacunarity_0) <= 0.0f)
    {
        float _S108 = convUpdraftGradT_1(c_11, q_8, grad_5);
        return _S108;
    }
    float _S109 = convUpdraftGradT_0(c_11, q_8, grad_5);
    return _S109;
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
    bool _S110;
    if(cover_1 <= 0.0f)
    {
        _S110 = true;
    }
    else
    {
        _S110 = (c_13->cvDepth_0) <= 0.0f;
    }
    if(_S110)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_13->cvDepth_0), (1.0f / (F32_max((c_13->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_14)
{
    float _S111 = c_14->cvSpacing_0;
    float cap_0 = 7.0f / c_14->cvSpacing_0;
    if(((&c_14->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_0;
    }
    float _S112 = c_14->cvLacunarity_0;
    float cap_1;
    if((c_14->cvLacunarity_0) > 0.0f)
    {
        cap_1 = cap_0 + 1.5f / (0.15000000596046448f * _S112 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S111);
    }
    else
    {
        cap_1 = cap_0;
    }
    float _S113 = c_14->cvGapWidth_0;
    if((c_14->cvGapWidth_0) > 0.0f)
    {
        cap_1 = cap_1 + 14.25f * c_14->cvPolarity_0 / (0.5f * _S113 * _S111);
    }
    return cap_1 + 3.0f * (&c_14->cvOrg_0)->ogWaveAmp_0 * length_1((&c_14->cvOrg_0)->ogWaveK_0);
}

static __device__ float convSurfaceDistance_0(float v_2, float delta_0, float slope_0)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_0 * slope_0 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_5 = num_0 / den_0;
    float _S114;
    if(v_2 >= 0.0f)
    {
        _S114 = d_5;
    }
    else
    {
        _S114 = - d_5;
    }
    return _S114;
}

static __device__ float3  convTwist_0(float3  x_16)
{
    float _S115 = x_16.x;
    float _S116 = x_16.y;
    float _S117 = x_16.z;
    return make_float3 (0.0f * _S115 + 0.80000001192092896f * _S116 + 0.60000002384185791f * _S117, -0.80000001192092896f * _S115 + 0.36000001430511475f * _S116 - 0.47999998927116394f * _S117, -0.60000002384185791f * _S115 - 0.47999998927116394f * _S116 + 0.63999998569488525f * _S117);
}

static __device__ float convPuffs_0(float3  x_17)
{
    float3  fl_0 = floor_0(x_17);
    int3  _S118 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_1 = x_17 - fl_0;
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
    int3  _S119 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S119 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S120 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_6 = _S120 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S118 + off_0) - f_1;
                float _S121 = (F32_min((nearest_1), (dot_0(d_6, d_6))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S121;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_15, float3  p_3, float scale_0)
{
    float3  _S122 = make_float3 (p_3.x, p_3.y - c_15->cvRise_0, p_3.z) / make_float3 (scale_0);
    int i_11 = int(0);
    float3  x_18 = _S122;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_11 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_11 >= (c_15->cvOctaves_0))
        {
            break;
        }
        float3  x_19 = convTwist_0(x_18);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_19);
        float norm_3 = norm_2 + amp_2;
        float3  x_20 = x_19 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_11 = i_11 + int(1);
        x_18 = x_20;
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

static __device__ float convInside_0(ConvectionInput_0 * c_16, float d_7, float lift_0, float3  x_21, float scale_1)
{
    float _S123 = d_7 + lift_0;
    if(_S123 <= 0.0f)
    {
        return _S123;
    }
    if((d_7 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S124 = convBillow_0(c_16, x_21, scale_1);
    return d_7 + lift_0 * _S124;
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_17)
{
    return c_17->cvHeroRadius_0 + 1.5f * c_17->cvBillow_0 * c_17->cvHeroBillow_0 + 24.0f;
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_18, float r_1)
{
    float _S125 = c_18->cvHeroTop_0;
    bool _S126;
    if((c_18->cvHeroTop_0) <= 0.0f)
    {
        _S126 = true;
    }
    else
    {
        _S126 = r_1 >= (c_18->cvHeroRadius_0);
    }
    if(_S126)
    {
        return 0.0f;
    }
    return _S125 * (F32_pow((1.0f - r_1 * r_1 / (c_18->cvHeroRadius_0 * c_18->cvHeroRadius_0)), (c_18->cvShape_0)));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_19, float above_2)
{
    float _S127 = c_19->cvHeroTop_0;
    bool _S128;
    if((c_19->cvHeroTop_0) <= 0.0f)
    {
        _S128 = true;
    }
    else
    {
        _S128 = above_2 >= _S127;
    }
    if(_S128)
    {
        return -1.0f;
    }
    return c_19->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S127), (1.0f / (F32_max((c_19->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_20, float3  p_4, float above_3)
{
    float2  rel_0 = float2 {p_4.x, p_4.z} - c_20->cvHeroAt_0;
    float r_2 = length_1(rel_0);
    float _S129 = convHeroReach_0(c_20);
    if(r_2 >= _S129)
    {
        return -1.00000001504746622e+30f;
    }
    float _S130 = convHeroHeight_0(c_20, r_2);
    float v_3 = _S130 - above_3;
    float _S131 = convHeroRadiusAt_0(c_20, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_8;
    if(_S131 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_8 = v_3;
    }
    else
    {
        float h_3 = _S131 - r_2;
        float d_9 = convSurfaceDistance_0(v_3, h_3, 1.0f);
        if((F32_abs((v_3))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_9 * (d_9 / v_3);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_3))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_9 * (d_9 / h_3);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S132 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S132;
        d_8 = d_9;
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
    float3  x_22 = make_float3 (at_0.x, p_4.y + shiftUp_0, at_0.y) + c_20->cvHeroSeed_0;
    float _S133 = c_20->cvHeroBillow_0;
    float _S134 = convLift_0(c_20, above_3, c_20->cvHeroBillow_0);
    float _S135 = convInside_0(c_20, d_8, _S134, x_22, c_20->cvBillowScale_0 * _S133);
    return _S135;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_21, float3  p_5)
{
    float _S136 = p_5.y;
    float above_4 = _S136 - c_21->cvBase_0;
    bool _S137;
    if(above_4 < 0.0f)
    {
        _S137 = true;
    }
    else
    {
        float _S138 = convCeiling_0(c_21);
        _S137 = above_4 > _S138;
    }
    if(_S137)
    {
        return 0.0f;
    }
    float _S139 = convLift_0(c_21, above_4, 1.0f - 0.60000002384185791f * c_21->cvLacunarity_0);
    float inside_0;
    if((c_21->cvHeroAlone_0) == int(0))
    {
        float2  q_9 = float2 {p_5.x, p_5.z} - c_21->cvDrift_0;
        float2  slope_1;
        float _S140 = convUpdraftGrad_0(c_21, q_9, &slope_1);
        float _S141 = convTowerHeight_0(c_21, _S140);
        float v_4 = _S141 - above_4;
        float _S142 = convNeededUpdraft_0(c_21, above_4);
        float delta_1 = _S140 - _S142;
        float _S143 = length_1(slope_1);
        float _S144 = convSlopeCap_0(c_21);
        float d_10 = convSurfaceDistance_0(v_4, delta_1, (F32_min((_S143), (_S144))));
        if((d_10 + _S139) > 0.0f)
        {
            if((F32_abs((v_4))) > 9.99999997475242708e-07f)
            {
                inside_0 = d_10 * (d_10 / v_4);
            }
            else
            {
                inside_0 = 0.0f;
            }
            float2  shiftAcross_0;
            if((F32_abs((delta_1))) > 9.999999960041972e-13f)
            {
                shiftAcross_0 = slope_1 * make_float2 (- d_10 * (d_10 / delta_1));
            }
            else
            {
                shiftAcross_0 = make_float2 (0.0f, 0.0f);
            }
            float _S145 = convInside_0(c_21, d_10, _S139, make_float3 (q_9.x + shiftAcross_0.x, _S136 + inside_0, q_9.y + shiftAcross_0.y), c_21->cvBillowScale_0);
            inside_0 = _S145;
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
        _S137 = inside_0 < 12.0f;
    }
    else
    {
        _S137 = false;
    }
    if(_S137)
    {
        float _S146 = convHeroInside_0(c_21, p_5, above_4);
        inside_0 = (F32_max((inside_0), (_S146)));
    }
    if(inside_0 <= 0.0f)
    {
        return 0.0f;
    }
    return c_21->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_0);
}

static __device__ float densityAt_0(Medium_0 * m_2, StructuredBuffer<float2 > disp_2, float3  p_6)
{
    float _S147 = p_6.y;
    bool _S148;
    if(_S147 < (m_2->slabBottom_0))
    {
        _S148 = true;
    }
    else
    {
        _S148 = _S147 > (m_2->slabTop_0);
    }
    if(_S148)
    {
        return 0.0f;
    }
    if((m_2->clipOn_0) != int(0))
    {
        float2  _S149 = float2 {p_6.x, p_6.z};
        if(any_0(_S149 < (m_2->clipLo_0)))
        {
            _S148 = true;
        }
        else
        {
            _S148 = any_0(_S149 > (m_2->clipHi_0));
        }
    }
    else
    {
        _S148 = false;
    }
    if(_S148)
    {
        return 0.0f;
    }
    float _S150 = m_2->fadeRadius_0;
    float fade_0;
    if((m_2->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S150 - length_1(float2 {p_6.x, p_6.z} - m_2->fadeAt_0)) / (F32_max((m_2->fadeWidth_0), (1.0f))));
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
    int _S151 = m_2->mode_0;
    if((m_2->mode_0) == int(0))
    {
        return m_2->density_0 * fade_0;
    }
    if(_S151 == int(2))
    {
        float _S152 = iceDensity_0(&m_2->gen_0, disp_2, p_6);
        return _S152 * fade_0;
    }
    if(_S151 == int(3))
    {
        float _S153 = convectionDensity_0(&m_2->conv_0, p_6);
        return _S153 * fade_0;
    }
    float3  d_11 = (p_6 - m_2->coreCentre_0) / make_float3 ((F32_max((m_2->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_2->density_0 + m_2->coreDensity_0 * (F32_exp((- dot_0(d_11, d_11))))) * fade_0;
}

static __device__ void layerMapColumn_0(Medium_0 * med_0, StructuredBuffer<float2 > drift_0, LayerShadowMap_0 * m_3, int texel_0, RWStructuredBuffer<float> outTexels_0)
{
    int _S154 = m_3->smDimU_0;
    int stride_0 = m_3->smDimU_0 * m_3->smDimV_0;
    bool _S155;
    if(texel_0 < int(0))
    {
        _S155 = true;
    }
    else
    {
        _S155 = texel_0 >= stride_0;
    }
    if(_S155)
    {
        return;
    }
    int iu_0 = texel_0 % _S154;
    int iv_0 = texel_0 / _S154;
    float2  _S156 = m_3->smLo_0;
    float2  _S157 = m_3->smTexel_0;
    float2  _S158 = m_3->smCentre_0 + m_3->smAxisU_0 * make_float2 (m_3->smLo_0.x + (float(iu_0) + 0.5f) * m_3->smTexel_0.x);
    float2  _S159 = airMapAxisV_0(m_3);
    float2  q_10 = _S158 + _S159 * make_float2 (_S156.y + (float(iv_0) + 0.5f) * _S157.y);
    float3  base_0 = make_float3 (q_10.x, m_3->smBottom_0, q_10.y);
    float3  _S160 = m_3->smSun_0;
    int _S161 = m_3->smSlices_0;
    int _S162 = m_3->smSlices_0 - int(1);
    float _S163 = (m_3->smTop_0 - m_3->smBottom_0) / (float(_S162) * m_3->smSun_0.y);
    float _S164 = (F32_max((m_3->smStep_0), (1.0f)));
    float t0_2;
    float t1_2;
    bool _S165 = slabRange_0(med_0, base_0, m_3->smSun_0, &t0_2, &t1_2);
    *(&(outTexels_0)[_S162 * stride_0 + texel_0]) = 1.0f;
    int k_2 = _S161 - int(2);
    float tau_0 = 0.0f;
    for(;;)
    {
        if(k_2 >= int(0))
        {
        }
        else
        {
            break;
        }
        if(_S165)
        {
            _S155 = tau_0 < 12.0f;
        }
        else
        {
            _S155 = false;
        }
        float tau_1;
        if(_S155)
        {
            float _S166 = (F32_max((float(k_2) * _S163), (t0_2)));
            float _S167 = (F32_min((float(k_2 + int(1)) * _S163), (t1_2)));
            if(_S167 > _S166)
            {
                float _S168 = _S167 - _S166;
                int n_0 = clamp_1(int((F32_ceil((_S168 / _S164)))), int(1), int(1024));
                float _S169 = _S168 / float(n_0);
                int j_8 = int(0);
                tau_1 = tau_0;
                for(;;)
                {
                    if(j_8 < n_0)
                    {
                    }
                    else
                    {
                        break;
                    }
                    float _S170 = densityAt_0(med_0, drift_0, base_0 + _S160 * make_float3 (_S166 + (float(j_8) + 0.5f) * _S169));
                    float tau_2 = tau_1 + _S170 * _S169;
                    j_8 = j_8 + int(1);
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
        float * _S171 = (&(outTexels_0)[k_2 * stride_0 + texel_0]);
        float _S172;
        if(tau_1 < 12.0f)
        {
            _S172 = (F32_exp((- tau_1)));
        }
        else
        {
            _S172 = 0.0f;
        }
        *_S171 = _S172;
        k_2 = k_2 - int(1);
        tau_0 = tau_1;
    }
    return;
}

extern "C" __global__ void airMapBuild(Medium_0 medium_0, StructuredBuffer<float2 > drift_1, LayerShadowMap_0 map_0, RWStructuredBuffer<float> outTexels_1, int count_0)
{
    int i_12 = int((blockIdx * blockDim + threadIdx).x);
    if(i_12 >= count_0)
    {
        return;
    }
    Medium_0 _S173 = medium_0;
    LayerShadowMap_0 _S174 = map_0;
    layerMapColumn_0(&_S173, drift_1, &_S174, i_12, outTexels_1);
    return;
}

static __device__ float clampf_0(float v_5, float lo_2, float hi_2)
{
    float _S175;
    if(v_5 < lo_2)
    {
        _S175 = lo_2;
    }
    else
    {
        if(v_5 > hi_2)
        {
            _S175 = hi_2;
        }
        else
        {
            _S175 = v_5;
        }
    }
    return _S175;
}

static __device__ float airMapTexel_0(LayerShadowMap_0 * m_4, int iu_1, int iv_1, int k_3)
{
    float _S176 = __ldg((&(m_4->smTexels_0)[(k_3 * m_4->smDimV_0 + iv_1) * m_4->smDimU_0 + iu_1]));
    return _S176;
}

static __device__ float layerMapTransmittance_0(LayerShadowMap_0 * m_5, float3  p_7)
{
    int _S177 = m_5->smDimU_0;
    int _S178 = m_5->smDimV_0;
    int _S179 = m_5->smSlices_0;
    uint want_0 = uint(m_5->smDimU_0 * m_5->smDimV_0 * m_5->smSlices_0);
    bool _S180;
    if(want_0 == 0U)
    {
        _S180 = true;
    }
    else
    {
        _S180 = uint(StructuredBuffer_getCount_0(m_5->smTexels_0)) < want_0;
    }
    if(_S180)
    {
        return 1.0f;
    }
    float _S181 = p_7.y;
    float _S182 = m_5->smTop_0;
    if(_S181 >= (m_5->smTop_0))
    {
        return 1.0f;
    }
    float3  _S183 = m_5->smSun_0;
    float _S184 = m_5->smBottom_0;
    float2  q_11 = float2 {p_7.x, p_7.z} + float2 {_S183.x, _S183.z} * make_float2 ((m_5->smBottom_0 - _S181) / m_5->smSun_0.y) - m_5->smCentre_0;
    float2  _S185 = m_5->smLo_0;
    float2  _S186 = m_5->smTexel_0;
    float fu_0 = (dot_1(q_11, m_5->smAxisU_0) - m_5->smLo_0.x) / m_5->smTexel_0.x - 0.5f;
    float2  _S187 = airMapAxisV_0(m_5);
    float fv_0 = (dot_1(q_11, _S187) - _S185.y) / _S186.y - 0.5f;
    if(fu_0 >= -0.5f)
    {
        _S180 = fv_0 >= -0.5f;
    }
    else
    {
        _S180 = false;
    }
    if(_S180)
    {
        _S180 = fu_0 <= (float(_S177) - 0.5f);
    }
    else
    {
        _S180 = false;
    }
    if(_S180)
    {
        _S180 = fv_0 <= (float(_S178) - 0.5f);
    }
    else
    {
        _S180 = false;
    }
    if(!_S180)
    {
        return 1.0f;
    }
    int _S188 = _S177 - int(1);
    float fu_1 = clampf_0(fu_0, 0.0f, float(_S188));
    int _S189 = _S178 - int(1);
    float fv_1 = clampf_0(fv_0, 0.0f, float(_S189));
    int u0_0 = int(fu_1);
    int v0_0 = int(fv_1);
    int _S190 = (I32_min((u0_0 + int(1)), (_S188)));
    int _S191 = (I32_min((v0_0 + int(1)), (_S189)));
    float tu_0 = fu_1 - float(u0_0);
    float tv_0 = fv_1 - float(v0_0);
    int _S192 = _S179 - int(1);
    float fk_0 = clampf_0((_S181 - _S184) / (F32_max((_S182 - _S184), (1.0f))), 0.0f, 1.0f) * float(_S192);
    int _S193 = (I32_min((int(fk_0)), (_S192)));
    int _S194 = (I32_min((_S193 + int(1)), (_S192)));
    float tk_0 = fk_0 - float(_S193);
    float _S195 = airMapTexel_0(m_5, u0_0, v0_0, _S193);
    float _S196 = 1.0f - tu_0;
    float _S197 = _S195 * _S196;
    float _S198 = airMapTexel_0(m_5, _S190, v0_0, _S193);
    float a0_0 = _S197 + _S198 * tu_0;
    float _S199 = airMapTexel_0(m_5, u0_0, _S191, _S193);
    float _S200 = _S199 * _S196;
    float _S201 = airMapTexel_0(m_5, _S190, _S191, _S193);
    float b0_0 = _S200 + _S201 * tu_0;
    float _S202 = airMapTexel_0(m_5, u0_0, v0_0, _S194);
    float _S203 = _S202 * _S196;
    float _S204 = airMapTexel_0(m_5, _S190, v0_0, _S194);
    float a1_0 = _S203 + _S204 * tu_0;
    float _S205 = airMapTexel_0(m_5, u0_0, _S191, _S194);
    float _S206 = _S205 * _S196;
    float _S207 = airMapTexel_0(m_5, _S190, _S191, _S194);
    float _S208 = 1.0f - tv_0;
    return (a0_0 * _S208 + b0_0 * tv_0) * (1.0f - tk_0) + (a1_0 * _S208 + (_S206 + _S207 * tu_0) * tv_0) * tk_0;
}

extern "C" __global__ void airMapLookup(LayerShadowMap_0 map_1, StructuredBuffer<float3 > points_0, RWStructuredBuffer<float> outT_0, int count_1)
{
    int i_13 = int((blockIdx * blockDim + threadIdx).x);
    if(i_13 >= count_1)
    {
        return;
    }
    float * _S209 = (&(outT_0)[i_13]);
    float3  _S210 = slang_ldg_0((&(points_0)[i_13]));
    LayerShadowMap_0 _S211 = map_1;
    float _S212 = layerMapTransmittance_0(&_S211, _S210);
    *_S209 = _S212;
    return;
}

static __device__ bool layerMapRange_0(LayerShadowMap_0 * m_6, float3  ro_1, float3  rd_1, float * t0_3, float * t1_3)
{
    *t0_3 = 0.0f;
    *t1_3 = 1.00000001504746622e+30f;
    int _S213 = m_6->smDimU_0;
    int _S214 = m_6->smDimV_0;
    uint want_1 = uint(m_6->smDimU_0 * m_6->smDimV_0 * m_6->smSlices_0);
    bool _S215;
    if(want_1 == 0U)
    {
        _S215 = true;
    }
    else
    {
        _S215 = uint(StructuredBuffer_getCount_0(m_6->smTexels_0)) < want_1;
    }
    if(_S215)
    {
        return false;
    }
    float _S216 = rd_1.y;
    if((F32_abs((_S216))) < 9.99999971718068537e-10f)
    {
        if((ro_1.y) >= (m_6->smTop_0))
        {
            return false;
        }
    }
    else
    {
        float tt_0 = (m_6->smTop_0 - ro_1.y) / _S216;
        if(_S216 > 0.0f)
        {
            *t1_3 = (F32_min((*t1_3), (tt_0)));
        }
        else
        {
            *t0_3 = (F32_max((*t0_3), (tt_0)));
        }
    }
    float3  _S217 = m_6->smSun_0;
    float2  _S218 = float2 {_S217.x, _S217.z};
    float _S219 = m_6->smSun_0.y;
    float2  q0_0 = float2 {ro_1.x, ro_1.z} + _S218 * make_float2 ((m_6->smBottom_0 - ro_1.y) / _S219) - m_6->smCentre_0;
    float2  dq_0 = float2 {rd_1.x, rd_1.z} - _S218 * make_float2 (_S216 / _S219);
    float2  _S220 = airMapAxisV_0(m_6);
    float _S221 = m_6->smLo_0.x;
    float _S222 = m_6->smLo_0.y;
    float vHi_0 = _S222 + float(_S214) * m_6->smTexel_0.y;
    bool _S223 = clipAxis_0(dot_1(q0_0, m_6->smAxisU_0), dot_1(dq_0, m_6->smAxisU_0), _S221, _S221 + float(_S213) * m_6->smTexel_0.x, t0_3, t1_3);
    if(!_S223)
    {
        return false;
    }
    bool _S224 = clipAxis_0(dot_1(q0_0, _S220), dot_1(dq_0, _S220), _S222, vHi_0, t0_3, t1_3);
    if(!_S224)
    {
        return false;
    }
    return (*t1_3) > (*t0_3);
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

static __device__ float3  sunDirection_0(SkyInput_0 * p_8)
{
    float az_0 = toRadians_0(p_8->sunAzimuth_0);
    float el_0 = toRadians_0(p_8->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static __device__ float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_12 = altitude_0 - shellHeight_0;
    return d_12 * (d_12 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_0, float c_22)
{
    float disc_0 = b_0 * b_0 - c_22;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_0 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_1, float c_23)
{
    float disc_1 = b_1 * b_1 - c_23;
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

static __device__ float altitudeFromQ_0(float q_12, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_12;
    float _S225;
    if(rr_0 > 0.0f)
    {
        _S225 = rr_0;
    }
    else
    {
        _S225 = 0.0f;
    }
    return q_12 / (planetRadius_2 + (F32_sqrt((_S225))));
}

static __device__ float lutMuFor_0(float3  geocentric_0, float3  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S226;
    if(len_0 > 1.0f)
    {
        _S226 = dot_0(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S226 = dot_0(geocentric_0, sun_0);
    }
    return _S226;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_9, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S227 = p_9->transmittanceLut_0;
    if(uint(StructuredBuffer_getCount_0(p_9->transmittanceLut_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S228 = p_9->scaleHeight_0;
    float scaleHeight_1;
    if((p_9->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S228;
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
    float _S229 = fx_1 - float(x0_1);
    float _S230 = fy_1 - float(y0_1);
    int _S231 = y0_1 * int(256);
    int _S232 = (_S231 + x0_1) * int(3);
    int _S233 = (_S231 + x1_1) * int(3);
    int _S234 = y1_1 * int(256);
    int _S235 = (_S234 + x0_1) * int(3);
    int _S236 = (_S234 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_24 = int(0);
    for(;;)
    {
        if(c_24 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S237 = __ldg((&(_S227)[_S232 + c_24]));
        float _S238 = 1.0f - _S229;
        float _S239 = _S237 * _S238;
        float _S240 = __ldg((&(_S227)[_S233 + c_24]));
        float a_0 = _S239 + _S240 * _S229;
        float _S241 = __ldg((&(_S227)[_S235 + c_24]));
        float _S242 = _S241 * _S238;
        float _S243 = __ldg((&(_S227)[_S236 + c_24]));
        float r_3 = a_0 * (1.0f - _S230) + (_S242 + _S243 * _S229) * _S230;
        if(c_24 == int(0))
        {
            *&((&out_0)->x) = r_3;
        }
        else
        {
            if(c_24 == int(1))
            {
                *&((&out_0)->y) = r_3;
            }
            else
            {
                *&((&out_0)->z) = r_3;
            }
        }
        c_24 = c_24 + int(1);
    }
    return out_0;
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_10)
{
    return 20.0f * p_10->sunIntensity_0;
}

static __device__ float3  airShadowLoss_0(SkyInput_0 * p_11, LayerShadowMap_0 * mapA_0, LayerShadowMap_0 * mapB_0, float3  ro_2, float3  rd_2, float dist_1, float jitter_1)
{
    float3  none_0 = make_float3 (0.0f, 0.0f, 0.0f);
    float r0_0;
    float r1_0;
    bool _S244 = layerMapRange_0(mapA_0, ro_2, rd_2, &r0_0, &r1_0);
    float tA_0;
    float tB_0;
    if(_S244)
    {
        float _S245 = (F32_max((-1.00000001504746622e+30f), (r1_0)));
        tA_0 = (F32_min((1.00000001504746622e+30f), (r0_0)));
        tB_0 = _S245;
    }
    else
    {
        tA_0 = 1.00000001504746622e+30f;
        tB_0 = -1.00000001504746622e+30f;
    }
    bool _S246 = layerMapRange_0(mapB_0, ro_2, rd_2, &r0_0, &r1_0);
    if(_S246)
    {
        float _S247 = (F32_min((tA_0), (r0_0)));
        tB_0 = (F32_max((tB_0), (r1_0)));
        tA_0 = _S247;
    }
    if(!(tB_0 > tA_0))
    {
        return none_0;
    }
    float3  _S248 = sunDirection_0(p_11);
    float _S249 = p_11->planetRadius_0;
    float planetRadius_3;
    if((p_11->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S249;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S250 = p_11->scaleHeight_0;
    float scaleHeight_2;
    if((p_11->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S250;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float atmosphereHeight_0 = scaleHeight_2 * 8.0f;
    float _S251 = ro_2.y;
    float observerAltitude_0;
    if(_S251 > 0.0f)
    {
        observerAltitude_0 = _S251;
    }
    else
    {
        observerAltitude_0 = 0.0f;
    }
    float _S252 = planetRadius_3 + observerAltitude_0;
    float _S253 = rd_2.y;
    float b_2 = _S252 * _S253;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(b_2, shellC_0(observerAltitude_0, planetRadius_3, atmosphereHeight_0));
    bool _S254;
    if(tTop_0 <= 0.0f)
    {
        _S254 = true;
    }
    else
    {
        _S254 = !(dist_1 > 0.0f);
    }
    if(_S254)
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
    float _S255 = (F32_max((tA_0), (0.0f)));
    float _S256 = (F32_min((tB_0), (tMax_0)));
    if(!(_S256 > _S255))
    {
        return none_0;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_11->turbidity_0);
    float _S257 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rd_2, _S248), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_6 = clampf_0(p_11->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S258 = g_6 * g_6;
    float hgDenom_0 = 1.0f + _S258 - 2.0f * g_6 * cosTheta_0;
    float _S259 = 1.0f - _S258;
    float _S260 = 12.56637096405029297f * hgDenom_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tA_0 = hgDenom_0;
    }
    else
    {
        tA_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S259 / (_S260 * (F32_sqrt((tA_0))));
    float depthR_0;
    float depthM_0;
    float hc_0;
    int i_14;
    if(_S255 > 0.0f)
    {
        float _S261 = _S255 / 8.0f;
        i_14 = int(0);
        depthR_0 = 0.0f;
        depthM_0 = 0.0f;
        for(;;)
        {
            if(i_14 < int(8))
            {
            }
            else
            {
                break;
            }
            float tm_0 = (float(i_14) + 0.5f) * _S261;
            float h_4 = altitudeFromQ_0(cGround_0 + 2.0f * tm_0 * b_2 + tm_0 * tm_0, planetRadius_3);
            if(h_4 < 0.0f)
            {
                hc_0 = 0.0f;
            }
            else
            {
                hc_0 = h_4;
            }
            float _S262 = - hc_0;
            float depthR_1 = depthR_0 + (F32_exp((_S262 / scaleHeight_2))) * _S261;
            float depthM_1 = depthM_0 + (F32_exp((_S262 / 1200.0f))) * _S261;
            i_14 = i_14 + int(1);
            depthR_0 = depthR_1;
            depthM_0 = depthM_1;
        }
    }
    else
    {
        depthR_0 = 0.0f;
        depthM_0 = 0.0f;
    }
    float _S263 = clampf_0(jitter_1, 0.0f, 1.0f);
    float _S264 = _S256 - _S255;
    float3  lossR_0 = none_0;
    float3  lossM_0 = none_0;
    i_14 = int(0);
    for(;;)
    {
        if(i_14 < int(48))
        {
        }
        else
        {
            break;
        }
        float s0_0 = _S255 + _S264 * float(i_14 * i_14) * 0.00043402778101154f;
        int _S265 = i_14 + int(1);
        float dt_0 = _S255 + _S264 * float(_S265 * _S265) * 0.00043402778101154f - s0_0;
        float ts_0 = s0_0 + _S263 * dt_0;
        float h_5 = altitudeFromQ_0(cGround_0 + 2.0f * ts_0 * b_2 + ts_0 * ts_0, planetRadius_3);
        if(h_5 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_5;
        }
        float _S266 = - hc_0;
        float rhoR_0 = (F32_exp((_S266 / scaleHeight_2)));
        float rhoM_0 = (F32_exp((_S266 / 1200.0f)));
        float _S267 = ts_0 - s0_0;
        float atR_0 = depthR_0 + rhoR_0 * _S267;
        float atM_0 = depthM_0 + rhoM_0 * _S267;
        float depthR_2 = depthR_0 + rhoR_0 * dt_0;
        float depthM_2 = depthM_0 + rhoM_0 * dt_0;
        float3  pw_0 = ro_2 + rd_2 * make_float3 (ts_0);
        float _S268 = layerMapTransmittance_0(mapA_0, pw_0);
        float _S269 = layerMapTransmittance_0(mapB_0, pw_0);
        float v_7 = _S268 * _S269;
        if(v_7 >= 1.0f)
        {
            i_14 = _S265;
            depthR_0 = depthR_2;
            depthM_0 = depthM_2;
            continue;
        }
        float3  _S270 = sampleTransmittanceLut_0(p_11, hc_0, lutMuFor_0(make_float3 (rd_2.x * ts_0, _S252 + _S253 * ts_0, rd_2.z * ts_0), _S248));
        float _S271 = _S257 * atM_0;
        float3  w_2 = make_float3 ((F32_exp((- (betaR_0.x * atR_0 + _S271)))), (F32_exp((- (betaR_0.y * atR_0 + _S271)))), (F32_exp((- (betaR_0.z * atR_0 + _S271))))) * _S270 * make_float3 ((1.0f - v_7) * dt_0);
        float3  _S272 = lossM_0 + w_2 * make_float3 (rhoM_0);
        lossR_0 = lossR_0 + w_2 * make_float3 (rhoR_0);
        lossM_0 = _S272;
        i_14 = _S265;
        depthR_0 = depthR_2;
        depthM_0 = depthM_2;
    }
    float3  _S273 = lossR_0 * betaR_0 * make_float3 (phaseR_0) + lossM_0 * make_float3 (betaM_0 * phaseM_0);
    float _S274 = sunIrradianceTop_0(p_11);
    return _S273 * make_float3 (_S274);
}

extern "C" __global__ void airMapLoss(SkyInput_0 sky_0, LayerShadowMap_0 mapA_1, LayerShadowMap_0 mapB_1, float3  origin_0, float3  direction_0, float dist_2, RWStructuredBuffer<float3 > outLoss_0, int count_2)
{
    int i_15 = int((blockIdx * blockDim + threadIdx).x);
    if(i_15 >= count_2)
    {
        return;
    }
    float jitter_2 = (float(i_15) + 0.5f) / float(count_2);
    float3  * _S275 = (&(outLoss_0)[i_15]);
    SkyInput_0 _S276 = sky_0;
    LayerShadowMap_0 _S277 = mapA_1;
    LayerShadowMap_0 _S278 = mapB_1;
    float3  _S279 = airShadowLoss_0(&_S276, &_S277, &_S278, origin_0, direction_0, dist_2, jitter_2);
    *_S275 = _S279;
    return;
}

extern "C" __global__ void airMapLossRef(SkyInput_0 p_12, LayerShadowMap_0 mapA_2, LayerShadowMap_0 mapB_2, float3  ro_3, float3  rd_3, float dist_3, int steps_0, int everywhere_0, RWStructuredBuffer<float3 > outLoss_1)
{
    SkyInput_0 _S280 = p_12;
    float3  _S281 = sunDirection_0(&_S280);
    float planetRadius_4;
    if((p_12.planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = p_12.planetRadius_0;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float scaleHeight_3;
    if((p_12.scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = p_12.scaleHeight_0;
    }
    else
    {
        scaleHeight_3 = 1.0f;
    }
    float atmosphereHeight_1 = scaleHeight_3 * 8.0f;
    float _S282 = ro_3.y;
    float observerAltitude_1;
    if(_S282 > 0.0f)
    {
        observerAltitude_1 = _S282;
    }
    else
    {
        observerAltitude_1 = 0.0f;
    }
    float _S283 = planetRadius_4 + observerAltitude_1;
    float _S284 = rd_3.y;
    float b_3 = _S283 * _S284;
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
    float betaM_1 = mieCoefficient_0(p_12.turbidity_0);
    float _S285 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rd_3, _S281), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_7 = clampf_0(p_12.mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S286 = g_7 * g_7;
    float hgDenom_1 = 1.0f + _S286 - 2.0f * g_7 * cosTheta_1;
    float _S287 = 1.0f - _S286;
    float _S288 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        observerAltitude_1 = hgDenom_1;
    }
    else
    {
        observerAltitude_1 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S287 / (_S288 * (F32_sqrt((observerAltitude_1))));
    float _S289 = tMax_1 / float(steps_0);
    float3  _S290 = make_float3 (0.0f, 0.0f, 0.0f);
    float3  accR_0 = _S290;
    float3  accM_0 = _S290;
    int i_16 = int(0);
    float depthR_3 = 0.0f;
    float depthM_3 = 0.0f;
    for(;;)
    {
        if(i_16 < steps_0)
        {
        }
        else
        {
            break;
        }
        float tm_1 = (float(i_16) + 0.5f) * _S289;
        float h_6 = altitudeFromQ_0(cGround_1 + 2.0f * tm_1 * b_3 + tm_1 * tm_1, planetRadius_4);
        float hc_1;
        if(h_6 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_6;
        }
        float _S291 = - hc_1;
        float rR_0 = (F32_exp((_S291 / scaleHeight_3)));
        float rM_0 = (F32_exp((_S291 / 1200.0f)));
        float atR_1 = depthR_3 + 0.5f * rR_0 * _S289;
        float atM_1 = depthM_3 + 0.5f * rM_0 * _S289;
        float depthR_4 = depthR_3 + rR_0 * _S289;
        float depthM_4 = depthM_3 + rM_0 * _S289;
        float3  pw_1 = ro_3 + rd_3 * make_float3 (tm_1);
        LayerShadowMap_0 _S292 = mapA_2;
        float _S293 = layerMapTransmittance_0(&_S292, pw_1);
        LayerShadowMap_0 _S294 = mapB_2;
        float _S295 = layerMapTransmittance_0(&_S294, pw_1);
        float _S296 = _S293 * _S295;
        float v_8;
        if(everywhere_0 != int(0))
        {
            v_8 = 0.0f;
        }
        else
        {
            v_8 = _S296;
        }
        if(v_8 >= 1.0f)
        {
            i_16 = i_16 + int(1);
            depthR_3 = depthR_4;
            depthM_3 = depthM_4;
            continue;
        }
        float _S297 = lutMuFor_0(make_float3 (rd_3.x * tm_1, _S283 + _S284 * tm_1, rd_3.z * tm_1), _S281);
        SkyInput_0 _S298 = p_12;
        float3  _S299 = sampleTransmittanceLut_0(&_S298, hc_1, _S297);
        float _S300 = _S285 * atM_1;
        float3  w_3 = make_float3 ((F32_exp((- (betaR_1.x * atR_1 + _S300)))), (F32_exp((- (betaR_1.y * atR_1 + _S300)))), (F32_exp((- (betaR_1.z * atR_1 + _S300))))) * _S299 * make_float3 ((1.0f - v_8) * _S289);
        float3  _S301 = accM_0 + w_3 * make_float3 (rM_0);
        accR_0 = accR_0 + w_3 * make_float3 (rR_0);
        accM_0 = _S301;
        i_16 = i_16 + int(1);
        depthR_3 = depthR_4;
        depthM_3 = depthM_4;
    }
    float3  * _S302 = (&(outLoss_1)[int(0)]);
    float3  _S303 = accR_0 * betaR_1 * make_float3 (phaseR_1) + accM_0 * make_float3 (betaM_1 * phaseM_1);
    SkyInput_0 _S304 = p_12;
    float _S305 = sunIrradianceTop_0(&_S304);
    *_S302 = _S303 * make_float3 (_S305);
    return;
}

static __device__ float groundShadow_0(LayerShadowMap_0 * mapA_3, LayerShadowMap_0 * mapB_3, float3  origin_1, float3  dir_0)
{
    float _S306 = dir_0.y;
    bool _S307;
    if(!(_S306 < 0.0f))
    {
        _S307 = true;
    }
    else
    {
        _S307 = !((origin_1.y) > 0.0f);
    }
    if(_S307)
    {
        return 1.0f;
    }
    float3  ground_0 = origin_1 + dir_0 * make_float3 (origin_1.y / - _S306);
    *&((&ground_0)->y) = 0.0f;
    float _S308 = layerMapTransmittance_0(mapA_3, ground_0);
    float _S309 = layerMapTransmittance_0(mapB_3, ground_0);
    return _S308 * _S309;
}

extern "C" __global__ void airMapGround(LayerShadowMap_0 mapA_4, LayerShadowMap_0 mapB_4, float3  origin_2, StructuredBuffer<float3 > directions_0, RWStructuredBuffer<float> outLit_0, int count_3)
{
    int i_17 = int((blockIdx * blockDim + threadIdx).x);
    if(i_17 >= count_3)
    {
        return;
    }
    float * _S310 = (&(outLit_0)[i_17]);
    float3  _S311 = slang_ldg_0((&(directions_0)[i_17]));
    LayerShadowMap_0 _S312 = mapA_4;
    LayerShadowMap_0 _S313 = mapB_4;
    float _S314 = groundShadow_0(&_S312, &_S313, origin_2, _S311);
    *_S310 = _S314;
    return;
}

