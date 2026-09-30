// GENERATED FROM Transport.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

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

static __device__ float dot_0(float2  x_0, float2  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y;
}

static __device__ float3  floor_0(float3  x_1)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_floor((_slang_vector_get_element(x_1, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
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

static __device__ float dot_1(float3  x_2, float3  y_1)
{
    return x_2.x * y_1.x + x_2.y * y_1.y + x_2.z * y_1.z;
}

static __device__ float lerp_0(float x_3, float y_2, float s_0)
{
    return x_3 + (y_2 - x_3) * s_0;
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

static __device__ float2  floor_1(float2  x_4)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_floor((_slang_vector_get_element(x_4, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
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

static __device__ float clamp_0(float x_5, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_5), (minBound_0)))), (maxBound_0)));
}

static __device__ float saturate_0(float x_6)
{
    return clamp_0(x_6, 0.0f, 1.0f);
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

static __device__ float2  lerp_1(float2  x_7, float2  y_3, float2  s_2)
{
    return x_7 + (y_3 - x_7) * s_2;
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
            int2  slot_2 = _S38 + make_int2 (i_2, j_1);
            float _S40 = convVigour_0(c_6, slot_2);
            if(_S40 <= 0.0f)
            {
                i_2 = i_2 + int(1);
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
            int2  slot_3 = _S50 + make_int2 (i_3, j_3);
            float _S51 = convVigour_0(c_7, slot_3);
            if(_S51 <= 0.0f)
            {
                i_3 = i_3 + int(1);
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
            int2  slot_5 = _S63 + make_int2 (i_4, j_5);
            float _S65 = convVigour_0(c_8, slot_5);
            if(_S65 <= 0.0f)
            {
                i_4 = i_4 + int(1);
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

static __device__ bool any_0(bool2  x_8)
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
            result_2 = (bool((_slang_vector_get_element(x_8, i_5))));
        }
        i_5 = i_5 + int(1);
    }
    return result_2;
}

static __device__ int clamp_1(int x_9, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_9), (minBound_1)))), (maxBound_1)));
}

static __device__ float length_0(float2  x_10)
{
    return (F32_sqrt((dot_0(x_10, x_10))));
}

static __device__ float2  abs_0(float2  x_11)
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
        *_slang_vector_get_element_ptr(&result_3, i_6) = (F32_abs((_slang_vector_get_element(x_11, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_3;
}

static __device__ bool all_0(bool2  x_12)
{
    bool result_4 = true;
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
            result_4 = (bool((_slang_vector_get_element(x_12, i_7))));
        }
        else
        {
            result_4 = false;
        }
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static __device__ float smoothstep_0(float min_0, float max_0, float x_13)
{
    float _S72 = saturate_0((x_13 - min_0) / (max_0 - min_0));
    return _S72 * _S72 * (3.0f - (_S72 + _S72));
}

static __device__ float2  min_1(float2  x_14, float2  y_4)
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
        *_slang_vector_get_element_ptr(&result_5, i_8) = (F32_min((_slang_vector_get_element(x_14, i_8)), (_slang_vector_get_element(y_4, i_8))));
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static __device__ float2  max_1(float2  x_15, float2  y_5)
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
        *_slang_vector_get_element_ptr(&result_6, i_9) = (F32_max((_slang_vector_get_element(x_15, i_9)), (_slang_vector_get_element(y_5, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
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

static __device__ bool clipAxis_0(float o_5, float d_4, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_4))) < 9.99999971718068537e-10f)
    {
        bool _S73;
        if(o_5 >= lo_0)
        {
            _S73 = o_5 <= hi_0;
        }
        else
        {
            _S73 = false;
        }
        return _S73;
    }
    float ta_0 = (lo_0 - o_5) / d_4;
    float tb_0 = (hi_0 - o_5) / d_4;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S74 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S74;
    return _S74 > (*t0_0);
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
    float _S75 = rd_0.y;
    bool _S76;
    if((F32_abs((_S75))) < 9.99999997475242708e-07f)
    {
        float _S77 = ro_0.y;
        if(_S77 < (m_0->slabBottom_0))
        {
            _S76 = true;
        }
        else
        {
            _S76 = _S77 > (m_0->slabTop_0);
        }
        if(_S76)
        {
            return false;
        }
    }
    else
    {
        float _S78 = ro_0.y;
        float ta_1 = (m_0->slabBottom_0 - _S78) / _S75;
        float tb_1 = (m_0->slabTop_0 - _S78) / _S75;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S79 = (m_0->clipOn_0) != int(0);
    float2  lo_1;
    if(_S79)
    {
        lo_1 = m_0->clipLo_0;
    }
    else
    {
        lo_1 = make_float2 (-1.0e+09f, -1.0e+09f);
    }
    float2  hi_1;
    if(_S79)
    {
        hi_1 = m_0->clipHi_0;
    }
    else
    {
        hi_1 = make_float2 (1.0e+09f, 1.0e+09f);
    }
    float _S80 = m_0->fadeRadius_0;
    if((m_0->fadeRadius_0) > 0.0f)
    {
        float2  _S81 = min_1(hi_1, m_0->fadeAt_0 + make_float2 (_S80));
        lo_1 = max_1(lo_1, m_0->fadeAt_0 - make_float2 (_S80));
        hi_1 = _S81;
    }
    bool _S82 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S82)
    {
        return false;
    }
    bool _S83 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S83)
    {
        return false;
    }
    float _S84 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S84;
    if(_S84 > (*t0_1))
    {
        _S76 = (*t1_1) > 0.0f;
    }
    else
    {
        _S76 = false;
    }
    return _S76;
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
        int3  _S85 = make_int3 (int(0), int(0), int(0));
        (&d_5)->cell_0 = _S85;
        (&d_5)->stepDir_0 = _S85;
        float3  _S86 = make_float3 (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_5)->tMax_0 = _S86;
        (&d_5)->tDelta_0 = _S86;
        return d_5;
    }
    float3  p_1 = ro_1 + rd_1 * make_float3 (t_3);
    float3  _S87 = floor_0((p_1 - g_3->origin_0) / g_3->cellExtent_0);
    int3  _S88 = make_int3 ((int)_S87.x, (int)_S87.y, (int)_S87.z);
    (&d_5)->cell_0 = _S88;
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
        int _S89 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            *_slang_vector_get_element_ptr(&(&d_5)->stepDir_0, a_0) = int(0);
            *_slang_vector_get_element_ptr(&(&d_5)->tMax_0, a_0) = 1.00000001504746622e+30f;
            *_slang_vector_get_element_ptr(&(&d_5)->tDelta_0, a_0) = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S90 = _slang_vector_get_element(rd_1, _S89) > 0.0f;
            int _S91;
            if(_S90)
            {
                _S91 = int(1);
            }
            else
            {
                _S91 = int(-1);
            }
            *_slang_vector_get_element_ptr(&(&d_5)->stepDir_0, a_0) = _S91;
            float _S92 = *_slang_vector_get_element_ptr(&g_3->origin_0, a_0);
            float _S93 = float(*_slang_vector_get_element_ptr(&(&d_5)->cell_0, a_0));
            float _S94;
            if(_S90)
            {
                _S94 = 1.0f;
            }
            else
            {
                _S94 = 0.0f;
            }
            *_slang_vector_get_element_ptr(&(&d_5)->tMax_0, a_0) = t_3 + (_S92 + (_S93 + _S94) * *_slang_vector_get_element_ptr(&g_3->cellExtent_0, a_0) - _slang_vector_get_element(p_1, a_0)) / _slang_vector_get_element(rd_1, _S89);
            *_slang_vector_get_element_ptr(&(&d_5)->tDelta_0, a_0) = (F32_abs((*_slang_vector_get_element_ptr(&g_3->cellExtent_0, a_0) / _slang_vector_get_element(rd_1, _S89))));
        }
        a_0 = a_0 + int(1);
    }
    return d_5;
}

static __device__ float convCeiling_0(ConvectionInput_0 * c_9)
{
    float _S95 = c_9->cvBillow_0;
    float field_0 = c_9->cvDepth_0 + c_9->cvBillow_0;
    float _S96 = c_9->cvHeroTop_0;
    float hero_0;
    if((c_9->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S96 + _S95 * c_9->cvHeroBillow_0;
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
    Organization_0 _S97 = flat_0;
    float2  _S98 = orgPattern_0(&_S97, q0_0, spacing_2);
    Organization_0 _S99 = flat_0;
    float2  _S100 = orgPattern_0(&_S99, q1_0, spacing_2);
    float2  _S101 = make_float2 (q0_0.x, q1_0.y);
    Organization_0 _S102 = flat_0;
    float2  _S103 = orgPattern_0(&_S102, _S101, spacing_2);
    float2  _S104 = make_float2 (q1_0.x, q0_0.y);
    Organization_0 _S105 = flat_0;
    float2  _S106 = orgPattern_0(&_S105, _S104, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S98.x)))), ((F32_abs((_S98.y))))))), ((F32_max(((F32_abs((_S100.x)))), ((F32_abs((_S100.y)))))))));
    *a_1 = min_1(min_1(_S98, _S103), min_1(_S106, _S100)) - make_float2 (grow_0);
    *b_0 = max_1(max_1(_S98, _S103), max_1(_S106, _S100)) + make_float2 (grow_0);
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_11, int2  slot_6, float2  a_2, float2  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S107 = convVigour_0(c_11, slot_6);
    if(_S107 <= 0.0f)
    {
        return;
    }
    float2  _S108 = convCellCentre_0(c_11, slot_6);
    float2  _S109 = a_2 - _S108;
    float2  nearGap_0 = max_1(max_1(_S109, _S108 - b_1), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_0(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_1(abs_0(_S109), abs_0(b_1 - _S108));
    float oHi_0 = _S107 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S107 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S107 * convBump_0(dot_0(farGap_0, farGap_0), 1.04999995231628418f);
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
    float2  _S110 = floor_1((a_3 + b_2) * make_float2 (0.5f));
    int2  _S111 = make_int2 ((int)_S110.x, (int)_S110.y);
    float2  _S112 = make_float2 ((float)_S111.x, (float)_S111.y);
    float2  highEdge_0 = _S112 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S113;
    if(all_0(a_3 >= (_S112 - make_float2 (0.00009999999747379f))))
    {
        _S113 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S113 = false;
    }
    int j_7;
    int i_10;
    if(_S113)
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
            i_10 = int(-1);
            for(;;)
            {
                if(i_10 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_12, _S111 + make_int2 (i_10, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_10 = i_10 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        float2  _S114 = floor_1(a_3);
        int2  _S115 = make_int2 ((int)_S114.x, (int)_S114.y);
        int2  _S116 = make_int2 (int(1), int(1));
        int2  i0_0 = _S115 - _S116;
        float2  _S117 = floor_1(b_2);
        int2  _S118 = make_int2 ((int)_S117.x, (int)_S117.y);
        int2  _S119 = _S118 + _S116;
        int _S120 = i0_0.y;
        j_7 = _S120;
        for(;;)
        {
            if(j_7 <= (_S119.y))
            {
                _S113 = j_7 <= (_S120 + int(32));
            }
            else
            {
                _S113 = false;
            }
            if(_S113)
            {
            }
            else
            {
                break;
            }
            int _S121 = i0_0.x;
            i_10 = _S121;
            for(;;)
            {
                bool _S122;
                if(i_10 <= (_S119.x))
                {
                    _S122 = i_10 <= (_S121 + int(32));
                }
                else
                {
                    _S122 = false;
                }
                if(_S122)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_12, make_int2 (i_10, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_10 = i_10 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_0((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_12->cvPolarity_0);
    float _S123 = c_12->cvLacunarity_0;
    float field_2;
    if((c_12->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_0(field_1, 0.40000000596046448f, _S123);
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
    bool _S124;
    if(cover_1 <= 0.0f)
    {
        _S124 = true;
    }
    else
    {
        _S124 = (c_14->cvDepth_0) <= 0.0f;
    }
    if(_S124)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_14->cvDepth_0), (1.0f / (F32_max((c_14->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_15)
{
    float _S125 = c_15->cvSpacing_0;
    float cap_0 = 7.0f / c_15->cvSpacing_0;
    if(((&c_15->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_0;
    }
    float _S126 = c_15->cvLacunarity_0;
    float cap_1;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        cap_1 = cap_0 + 1.5f / (0.15000000596046448f * _S126 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S125);
    }
    else
    {
        cap_1 = cap_0;
    }
    float _S127 = c_15->cvGapWidth_0;
    if((c_15->cvGapWidth_0) > 0.0f)
    {
        cap_1 = cap_1 + 14.25f * c_15->cvPolarity_0 / (0.5f * _S127 * _S125);
    }
    return cap_1 + 3.0f * (&c_15->cvOrg_0)->ogWaveAmp_0 * length_0((&c_15->cvOrg_0)->ogWaveK_0);
}

static __device__ float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S128;
    if(vMin_0 <= 0.0f)
    {
        _S128 = true;
    }
    else
    {
        _S128 = hMin_0 <= 0.0f;
    }
    if(_S128)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_16)
{
    return c_16->cvHeroRadius_0 + 1.5f * c_16->cvBillow_0 * c_16->cvHeroBillow_0 + 24.0f;
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_17, float r_2)
{
    float _S129 = c_17->cvHeroTop_0;
    bool _S130;
    if((c_17->cvHeroTop_0) <= 0.0f)
    {
        _S130 = true;
    }
    else
    {
        _S130 = r_2 >= (c_17->cvHeroRadius_0);
    }
    if(_S130)
    {
        return 0.0f;
    }
    return _S129 * (F32_pow((1.0f - r_2 * r_2 / (c_17->cvHeroRadius_0 * c_17->cvHeroRadius_0)), (c_17->cvShape_0)));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_18, float above_2)
{
    float _S131 = c_18->cvHeroTop_0;
    bool _S132;
    if((c_18->cvHeroTop_0) <= 0.0f)
    {
        _S132 = true;
    }
    else
    {
        _S132 = above_2 >= _S131;
    }
    if(_S132)
    {
        return -1.0f;
    }
    return c_18->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S131), (1.0f / (F32_max((c_18->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_19, float3  lo_2, float3  hi_2)
{
    float low_0 = lo_2.y - c_19->cvBase_0;
    float high_0 = hi_2.y - c_19->cvBase_0;
    float _S133 = convCeiling_0(c_19);
    bool _S134;
    if(high_0 < 0.0f)
    {
        _S134 = true;
    }
    else
    {
        _S134 = low_0 > _S133;
    }
    if(_S134)
    {
        return 0.0f;
    }
    float _S135 = (F32_max((low_0), (0.0f)));
    float _S136 = (F32_min((high_0), (_S133)));
    float _S137 = convLift_0(c_19, _S136, 1.0f);
    float inside_0;
    if((c_19->cvHeroAlone_0) == int(0))
    {
        float _S138 = convUpdraftBound_0(c_19, float2 {lo_2.x, lo_2.z} - c_19->cvDrift_0, float2 {hi_2.x, hi_2.z} - c_19->cvDrift_0);
        float _S139 = convTowerHeight_0(c_19, _S138);
        float _S140 = convNeededUpdraft_0(c_19, _S135);
        if(_S138 < _S140)
        {
            float _S141 = convSlopeCap_0(c_19);
            inside_0 = _S137 - convDistanceFloor_0(_S135 - _S139, (_S140 - _S138) / _S141);
        }
        else
        {
            inside_0 = (F32_max((_S139 - _S135), (0.0f))) + _S137;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    if((c_19->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_0(max_1(max_1(float2 {lo_2.x, lo_2.z} - c_19->cvHeroAt_0, c_19->cvHeroAt_0 - float2 {hi_2.x, hi_2.z}), make_float2 (0.0f, 0.0f)));
        float _S142 = convHeroReach_0(c_19);
        if(rMin_0 < _S142)
        {
            float _S143 = convHeroHeight_0(c_19, rMin_0);
            float _S144 = convHeroRadiusAt_0(c_19, _S135);
            float _S145 = convLift_0(c_19, _S136, c_19->cvHeroBillow_0);
            bool _S146 = _S144 < 0.0f;
            if(_S146)
            {
                _S134 = true;
            }
            else
            {
                _S134 = rMin_0 >= _S144;
            }
            float heroIn_0;
            if(_S134)
            {
                if(_S146)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S144;
                }
                heroIn_0 = _S145 - convDistanceFloor_0(_S135 - _S143, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S143 - _S135), (0.0f))) + _S145;
            }
            inside_0 = (F32_max((inside_0), (heroIn_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return 0.0f;
    }
    return c_19->cvSigma_0 * (F32_sqrt((saturate_0(_S136 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1) * 1.00001001358032227f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_16 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_11 = clamp_1(int((F32_floor((x_16)))), int(0), int(31));
    float2  _S147 = __ldg((&(disp_0)[i_11]));
    float2  _S148 = __ldg((&(disp_0)[i_11 + int(1)]));
    return lerp_1(_S147, _S148, make_float2 (x_16 - float(i_11)));
}

static __device__ void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<float2 > disp_1, float d0_0, float d1_0, float2  * lo_3, float2  * hi_3)
{
    float2  _S149 = driftAt_0(g_5, disp_1, d0_0);
    *lo_3 = _S149;
    *hi_3 = _S149;
    float2  _S150 = driftAt_0(g_5, disp_1, d1_0);
    *lo_3 = min_1(*lo_3, _S150);
    *hi_3 = max_1(*hi_3, _S150);
    int _S151 = clamp_1(int((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_2 = clamp_1(int((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_2 <= _S151)
        {
        }
        else
        {
            break;
        }
        float2  _S152 = *lo_3;
        float2  _S153 = __ldg((&(disp_1)[k_2]));
        *lo_3 = min_1(_S152, _S153);
        float2  _S154 = *hi_3;
        float2  _S155 = __ldg((&(disp_1)[k_2]));
        *hi_3 = max_1(_S154, _S155);
        k_2 = k_2 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_6, float2  q0_2, float2  q1_2)
{
    float2  a_4;
    float2  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    float2  _S156 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    float2  _S157 = floor_1(a_4);
    int2  _S158 = make_int2 ((int)_S157.x, (int)_S157.y);
    int2  _S159 = make_int2 (int(1), int(1));
    int2  i0_1 = _S158 - _S159;
    float2  _S160 = floor_1(b_3);
    int2  _S161 = make_int2 ((int)_S160.x, (int)_S160.y);
    int2  _S162 = _S161 + _S159;
    int _S163 = i0_1.y;
    int j_8 = _S163;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S164;
        if(j_8 <= (_S162.y))
        {
            _S164 = j_8 <= (_S163 + int(32));
        }
        else
        {
            _S164 = false;
        }
        if(_S164)
        {
        }
        else
        {
            break;
        }
        int _S165 = i0_1.x;
        int i_12 = _S165;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S166;
            if(i_12 <= (_S162.x))
            {
                _S166 = i_12 <= (_S165 + int(32));
            }
            else
            {
                _S166 = false;
            }
            if(_S166)
            {
            }
            else
            {
                break;
            }
            int2  o_7 = make_int2 (i_12, j_8);
            if((hash22_0(o_7, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_12 = i_12 + int(1);
                continue;
            }
            float2  _S167 = make_float2 ((float)o_7.x, (float)o_7.y);
            float2  c_20 = _S167 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S156;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_1(max_1(a_4 - c_20, c_20 - b_3), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_12 = i_12 + int(1);
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
    bool _S168;
    if(d1_1 < 0.0f)
    {
        _S168 = true;
    }
    else
    {
        _S168 = d0_1 > (g_7->streakLength_0);
    }
    if(_S168)
    {
        return 0.0f;
    }
    float _S169 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S170 = cellFieldBound_0(g_7, make_float2 (lo_4.x, lo_4.z) - driftHi_0, make_float2 (hi_4.x, hi_4.z) - driftLo_0);
    return (F32_max((_S170 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S169), (1.0f)));
}

static __device__ float mediumBound_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_3, float3  lo_5, float3  hi_5)
{
    int _S171 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S172 = convectionBound_0(&m_1->conv_0, lo_5, hi_5);
        return _S172;
    }
    if(_S171 == int(2))
    {
        float _S173 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_5, hi_5);
        return _S173;
    }
    return m_1->majorant_0;
}

static __device__ float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_0, StructuredBuffer<float2 > disp_4, int3  c_21, float fallback_0)
{
    int _S174 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S174 == int(2))
    {
        float3  _S175 = make_float3 ((float)c_21.x, (float)c_21.y, (float)c_21.z);
        float3  lo_6 = g_8->origin_0 + _S175 * g_8->cellExtent_0;
        float _S176 = mediumBound_0(m_2, disp_4, lo_6, lo_6 + g_8->cellExtent_0);
        return _S176;
    }
    int _S177 = c_21.x;
    bool _S178;
    if(_S177 < int(0))
    {
        _S178 = true;
    }
    else
    {
        _S178 = (c_21.y) < int(0);
    }
    if(_S178)
    {
        _S178 = true;
    }
    else
    {
        _S178 = (c_21.z) < int(0);
    }
    if(_S178)
    {
        _S178 = true;
    }
    else
    {
        _S178 = _S177 >= (g_8->dims_0.x);
    }
    if(_S178)
    {
        _S178 = true;
    }
    else
    {
        _S178 = (c_21.y) >= (g_8->dims_0.y);
    }
    if(_S178)
    {
        _S178 = true;
    }
    else
    {
        _S178 = (c_21.z) >= (g_8->dims_0.z);
    }
    if(_S178)
    {
        return fallback_0;
    }
    float _S179 = __ldg((&(bounds_0)[(c_21.z * g_8->dims_0.y + c_21.y) * g_8->dims_0.x + _S177]));
    return _S179;
}

static __device__ float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S180;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S180 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S180 = false;
    }
    if(_S180)
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

static __device__ float randFloat_0(Rng_0 * r_3)
{
    uint _S181 = r_3->state_0 * 747796405U + 2891336453U;
    r_3->state_0 = _S181;
    uint word_0 = ((_S181 >> ((_S181 >> 28U) + 4U)) ^ _S181) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float orgWaveFactor_0(Organization_0 * o_8, float2  q_6)
{
    float2  unused_0;
    float _S182 = orgWave_0(o_8, q_6, &unused_0);
    return _S182;
}

static __device__ float cellField_0(GeneratorInput_0 * g_9, float2  q_7)
{
    float2  _S183 = q_7 - g_9->cellDrift_0;
    float2  _S184 = orgPattern_0(&g_9->gnOrg_0, _S183, g_9->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(_S184);
    int2  _S185 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    float2  _S186 = orgJitter_0(&g_9->gnOrg_0, 0.80000001192092896f);
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
        int i_13 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_13 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_9 = _S185 + make_int2 (i_13, j_9);
            if((hash22_0(o_9, 2654435769U).x) > (g_9->cellDensity_0))
            {
                i_13 = i_13 + int(1);
                continue;
            }
            float2  _S187 = make_float2 ((float)o_9.x, (float)o_9.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(_S184 - (_S187 + make_float2 (0.5f) + (hash22_0(o_9, 0U) - make_float2 (0.5f)) * _S186)) * 2.20000004768371582f);
            i_13 = i_13 + int(1);
        }
        j_9 = j_9 + int(1);
        acc_2 = acc_3;
    }
    float _S188 = acc_2 * g_9->cellStrength_0;
    float _S189 = orgWaveFactor_0(&g_9->gnOrg_0, _S183);
    return _S188 * _S189;
}

static __device__ float fbm_0(float3  p_2, int octaves_1)
{
    int i_14 = int(0);
    float amp_0 = 0.5f;
    float3  _S190 = p_2;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_14 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_14 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S190);
        float norm_1 = norm_0 + amp_0;
        float3  _S191 = _S190 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_14 = i_14 + int(1);
        amp_0 = amp_1;
        _S190 = _S191;
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

static __device__ float iceDensity_0(GeneratorInput_0 * g_10, StructuredBuffer<float2 > disp_5, float3  p_3)
{
    float depth_1 = g_10->cellAltitude_0 - p_3.y;
    bool _S192;
    if(depth_1 < 0.0f)
    {
        _S192 = true;
    }
    else
    {
        _S192 = depth_1 > (g_10->streakLength_0);
    }
    if(_S192)
    {
        return 0.0f;
    }
    float2  _S193 = float2 {p_3.x, p_3.z};
    float2  _S194 = driftAt_0(g_10, disp_5, depth_1);
    float2  source_0 = _S193 - _S194;
    float _S195 = cellField_0(g_10, source_0);
    if(_S195 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S195 * (F32_exp((- g_10->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_10->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_10->streakLength_0, g_10->streakLength_0, depth_1)) * (F32_max((1.0f + g_10->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_10->detailScale_0)).x, (source_0 / make_float2 (g_10->detailScale_0)).y, depth_1 / (F32_max((g_10->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_10->timeSeconds_0 * 0.00999999977648258f), g_10->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_10->opticalDepth_0 / (F32_max((g_10->streakLength_0), (1.0f)));
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_22, float2  q_8, float2  * grad_5)
{
    if(((&c_22->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S196 = convUpdraftGradT_2(c_22, q_8, grad_5);
        return _S196;
    }
    if((c_22->cvLacunarity_0) <= 0.0f)
    {
        float _S197 = convUpdraftGradT_1(c_22, q_8, grad_5);
        return _S197;
    }
    float _S198 = convUpdraftGradT_0(c_22, q_8, grad_5);
    return _S198;
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
    float _S199;
    if(v_2 >= 0.0f)
    {
        _S199 = d_8;
    }
    else
    {
        _S199 = - d_8;
    }
    return _S199;
}

static __device__ float3  convTwist_0(float3  x_17)
{
    float _S200 = x_17.x;
    float _S201 = x_17.y;
    float _S202 = x_17.z;
    return make_float3 (0.0f * _S200 + 0.80000001192092896f * _S201 + 0.60000002384185791f * _S202, -0.80000001192092896f * _S200 + 0.36000001430511475f * _S201 - 0.47999998927116394f * _S202, -0.60000002384185791f * _S200 - 0.47999998927116394f * _S201 + 0.63999998569488525f * _S202);
}

static __device__ float convPuffs_0(float3  x_18)
{
    float3  fl_0 = floor_0(x_18);
    int3  _S203 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_1 = x_18 - fl_0;
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
    int3  _S204 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S204 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S205 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_9 = _S205 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S203 + off_0) - f_1;
                float _S206 = (F32_min((nearest_1), (dot_1(d_9, d_9))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S206;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_23, float3  p_4, float scale_0)
{
    float3  _S207 = make_float3 (p_4.x, p_4.y - c_23->cvRise_0, p_4.z) / make_float3 (scale_0);
    int i_15 = int(0);
    float3  x_19 = _S207;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_15 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_15 >= (c_23->cvOctaves_0))
        {
            break;
        }
        float3  x_20 = convTwist_0(x_19);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_20);
        float norm_3 = norm_2 + amp_2;
        float3  x_21 = x_20 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_15 = i_15 + int(1);
        x_19 = x_21;
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

static __device__ float convInside_0(ConvectionInput_0 * c_24, float d_10, float lift_0, float3  x_22, float scale_1)
{
    float _S208 = d_10 + lift_0;
    if(_S208 <= 0.0f)
    {
        return _S208;
    }
    if((d_10 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S209 = convBillow_0(c_24, x_22, scale_1);
    return d_10 + lift_0 * _S209;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_25, float3  p_5, float above_3)
{
    float2  rel_0 = float2 {p_5.x, p_5.z} - c_25->cvHeroAt_0;
    float r_4 = length_0(rel_0);
    float _S210 = convHeroReach_0(c_25);
    if(r_4 >= _S210)
    {
        return -1.00000001504746622e+30f;
    }
    float _S211 = convHeroHeight_0(c_25, r_4);
    float v_3 = _S211 - above_3;
    float _S212 = convHeroRadiusAt_0(c_25, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_11;
    if(_S212 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_11 = v_3;
    }
    else
    {
        float h_3 = _S212 - r_4;
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
        float _S213 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S213;
        d_11 = d_12;
    }
    float2  radial_0;
    if(r_4 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / make_float2 (r_4);
    }
    else
    {
        radial_0 = make_float2 (0.0f, 0.0f);
    }
    float2  at_0 = rel_0 + radial_0 * make_float2 (shiftOut_0);
    float3  x_23 = make_float3 (at_0.x, p_5.y + shiftUp_0, at_0.y) + c_25->cvHeroSeed_0;
    float _S214 = c_25->cvHeroBillow_0;
    float _S215 = convLift_0(c_25, above_3, c_25->cvHeroBillow_0);
    float _S216 = convInside_0(c_25, d_11, _S215, x_23, c_25->cvBillowScale_0 * _S214);
    return _S216;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_26, float3  p_6)
{
    float _S217 = p_6.y;
    float above_4 = _S217 - c_26->cvBase_0;
    bool _S218;
    if(above_4 < 0.0f)
    {
        _S218 = true;
    }
    else
    {
        float _S219 = convCeiling_0(c_26);
        _S218 = above_4 > _S219;
    }
    if(_S218)
    {
        return 0.0f;
    }
    float _S220 = convLift_0(c_26, above_4, 1.0f - 0.60000002384185791f * c_26->cvLacunarity_0);
    float inside_2;
    if((c_26->cvHeroAlone_0) == int(0))
    {
        float2  q_9 = float2 {p_6.x, p_6.z} - c_26->cvDrift_0;
        float2  slope_1;
        float _S221 = convUpdraftGrad_0(c_26, q_9, &slope_1);
        float _S222 = convTowerHeight_0(c_26, _S221);
        float v_4 = _S222 - above_4;
        float _S223 = convNeededUpdraft_0(c_26, above_4);
        float delta_1 = _S221 - _S223;
        float _S224 = length_0(slope_1);
        float _S225 = convSlopeCap_0(c_26);
        float d_13 = convSurfaceDistance_0(v_4, delta_1, (F32_min((_S224), (_S225))));
        if((d_13 + _S220) > 0.0f)
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
            float _S226 = convInside_0(c_26, d_13, _S220, make_float3 (q_9.x + shiftAcross_0.x, _S217 + inside_2, q_9.y + shiftAcross_0.y), c_26->cvBillowScale_0);
            inside_2 = _S226;
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
        _S218 = inside_2 < 12.0f;
    }
    else
    {
        _S218 = false;
    }
    if(_S218)
    {
        float _S227 = convHeroInside_0(c_26, p_6, above_4);
        inside_2 = (F32_max((inside_2), (_S227)));
    }
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_26->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2);
}

static __device__ float densityAt_0(Medium_0 * m_3, StructuredBuffer<float2 > disp_6, float3  p_7)
{
    float _S228 = p_7.y;
    bool _S229;
    if(_S228 < (m_3->slabBottom_0))
    {
        _S229 = true;
    }
    else
    {
        _S229 = _S228 > (m_3->slabTop_0);
    }
    if(_S229)
    {
        return 0.0f;
    }
    if((m_3->clipOn_0) != int(0))
    {
        float2  _S230 = float2 {p_7.x, p_7.z};
        if(any_0(_S230 < (m_3->clipLo_0)))
        {
            _S229 = true;
        }
        else
        {
            _S229 = any_0(_S230 > (m_3->clipHi_0));
        }
    }
    else
    {
        _S229 = false;
    }
    if(_S229)
    {
        return 0.0f;
    }
    float _S231 = m_3->fadeRadius_0;
    float fade_0;
    if((m_3->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S231 - length_0(float2 {p_7.x, p_7.z} - m_3->fadeAt_0)) / (F32_max((m_3->fadeWidth_0), (1.0f))));
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
    int _S232 = m_3->mode_0;
    if((m_3->mode_0) == int(0))
    {
        return m_3->density_0 * fade_0;
    }
    if(_S232 == int(2))
    {
        float _S233 = iceDensity_0(&m_3->gen_0, disp_6, p_7);
        return _S233 * fade_0;
    }
    if(_S232 == int(3))
    {
        float _S234 = convectionDensity_0(&m_3->conv_0, p_7);
        return _S234 * fade_0;
    }
    float3  d_14 = (p_7 - m_3->coreCentre_0) / make_float3 ((F32_max((m_3->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_3->density_0 + m_3->coreDensity_0 * (F32_exp((- dot_1(d_14, d_14))))) * fade_0;
}

static __device__ float transmittance_0(Medium_0 * m_4, MajorantGrid_0 * g_11, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_7, Rng_0 * rng_0, float3  p_8, float3  dir_0, int * steps_0)
{
    float t0_2;
    float t1_2;
    bool _S235 = slabRange_0(m_4, p_8, dir_0, &t0_2, &t1_2);
    if(!_S235)
    {
        return 1.0f;
    }
    float _S236 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S236;
    Dda_0 _S237 = ddaInit_0(g_11, p_8, dir_0, _S236);
    Dda_0 dda_0 = _S237;
    float _S238 = m_4->majorant_0;
    float _S239 = gridBound_0(m_4, g_11, bounds_1, disp_7, (&dda_0)->cell_0, m_4->majorant_0);
    float localMaj_0 = _S239;
    int i_16 = int(0);
    float t_4 = _S236;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_16 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S240 = dda_0;
        float _S241 = ddaExit_0(&_S240);
        float _S242 = (F32_min((_S241), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S242 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S243 = gridBound_0(m_4, g_11, bounds_1, disp_7, (&dda_0)->cell_0, _S238);
            localMaj_0 = _S243;
            t_4 = _S242;
            i_16 = i_16 + int(1);
            continue;
        }
        float _S244 = randFloat_0(rng_0);
        float t_5 = t_4 - (F32_log(((F32_max((1.0f - _S244), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_5 >= _S242)
        {
            if(_S242 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S245 = gridBound_0(m_4, g_11, bounds_1, disp_7, (&dda_0)->cell_0, _S238);
            localMaj_0 = _S245;
            t_4 = _S242;
            i_16 = i_16 + int(1);
            continue;
        }
        float _S246 = densityAt_0(m_4, disp_7, p_8 + dir_0 * make_float3 (t_5));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S246 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S247 = randFloat_0(rng_0);
            if(_S247 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_4 = t_5;
        tr_0 = tr_2;
        i_16 = i_16 + int(1);
    }
    return tr_0;
}

extern "C" __global__ void transmittanceTrial(Medium_0 medium_0, MajorantGrid_0 grid_0, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > drift_0, float3  origin_1, float3  direction_0, RWStructuredBuffer<float> output_0, RWStructuredBuffer<int> outSteps_0, uint seed_1, int count_0)
{
    int i_17 = int((blockIdx * blockDim + threadIdx).x);
    if(i_17 >= count_0)
    {
        return;
    }
    uint s_6 = uint(i_17) * 747796405U + 2891336453U;
    uint s_7 = ((s_6 >> ((s_6 >> 28U) + 4U)) ^ s_6) * 277803737U;
    Rng_0 rng_1 = makeRng_0(((s_7 >> 22U) ^ s_7) ^ seed_1);
    int steps_1 = int(0);
    float * _S248 = (&(output_0)[i_17]);
    Medium_0 _S249 = medium_0;
    MajorantGrid_0 _S250 = grid_0;
    float _S251 = transmittance_0(&_S249, &_S250, bounds_2, drift_0, &rng_1, origin_1, direction_0, &steps_1);
    *_S248 = _S251;
    *(&(outSteps_0)[i_17]) = steps_1;
    return;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_5, MajorantGrid_0 * g_12, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > disp_8, Rng_0 * rng_2, float3  ro_2, float3  rd_2, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_2)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S252 = slabRange_0(m_5, ro_2, rd_2, &t0_3, &t1_3);
    if(!_S252)
    {
        return false;
    }
    float _S253 = (F32_min((t1_3), (tLimit_0)));
    t1_3 = _S253;
    if(!(_S253 > t0_3))
    {
        return false;
    }
    float _S254 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S255 = ddaInit_0(g_12, ro_2, rd_2, _S254);
    Dda_0 dda_1 = _S255;
    float _S256 = m_5->majorant_0;
    float _S257 = gridBound_0(m_5, g_12, bounds_3, disp_8, (&dda_1)->cell_0, m_5->majorant_0);
    float localMaj_1 = _S257;
    int i_18 = int(0);
    float t_6 = _S254;
    for(;;)
    {
        if(i_18 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_2 = *steps_2 + int(1);
        Dda_0 _S258 = dda_1;
        float _S259 = ddaExit_0(&_S258);
        float _S260 = (F32_min((_S259), (t1_3)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S260 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S261 = gridBound_0(m_5, g_12, bounds_3, disp_8, (&dda_1)->cell_0, _S256);
            localMaj_1 = _S261;
            t_6 = _S260;
            i_18 = i_18 + int(1);
            continue;
        }
        float _S262 = randFloat_0(rng_2);
        float t_7 = t_6 - (F32_log(((F32_max((1.0f - _S262), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_7 >= _S260)
        {
            if(_S260 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S263 = gridBound_0(m_5, g_12, bounds_3, disp_8, (&dda_1)->cell_0, _S256);
            localMaj_1 = _S263;
            t_6 = _S260;
            i_18 = i_18 + int(1);
            continue;
        }
        float3  p_9 = ro_2 + rd_2 * make_float3 (t_7);
        float _S264 = randFloat_0(rng_2);
        float _S265 = densityAt_0(m_5, disp_8, p_9);
        if(_S264 < (_S265 / localMaj_1))
        {
            *scatterPoint_0 = p_9;
            *distance_0 = t_7;
            return true;
        }
        t_6 = t_7;
        i_18 = i_18 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_6, MajorantGrid_0 * g_13, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > disp_9, Rng_0 * rng_3, float3  ro_3, float3  rd_3, float3  * scatterPoint_1, float * distance_1, int * steps_3)
{
    bool _S266 = sampleFreeFlightUpTo_0(m_6, g_13, bounds_4, disp_9, rng_3, ro_3, rd_3, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_3);
    return _S266;
}

extern "C" __global__ void freeFlightTrial(Medium_0 medium_1, MajorantGrid_0 grid_1, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > drift_1, float3  origin_2, float3  direction_1, RWStructuredBuffer<float> outDistance_0, RWStructuredBuffer<int> outSteps_1, uint seed_2, int count_1)
{
    int i_19 = int((blockIdx * blockDim + threadIdx).x);
    if(i_19 >= count_1)
    {
        return;
    }
    uint s_8 = uint(i_19) * 747796405U + 2891336453U;
    uint s_9 = ((s_8 >> ((s_8 >> 28U) + 4U)) ^ s_8) * 277803737U;
    Rng_0 rng_4 = makeRng_0(((s_9 >> 22U) ^ s_9) ^ seed_2);
    int steps_4 = int(0);
    float * _S267 = (&(outDistance_0)[i_19]);
    Medium_0 _S268 = medium_1;
    MajorantGrid_0 _S269 = grid_1;
    float3  hit_0;
    float dist_1;
    bool _S270 = sampleFreeFlight_0(&_S268, &_S269, bounds_5, drift_1, &rng_4, origin_2, direction_1, &hit_0, &dist_1, &steps_4);
    float _S271;
    if(_S270)
    {
        _S271 = dist_1;
    }
    else
    {
        _S271 = -1.0f;
    }
    *_S267 = _S271;
    *(&(outSteps_1)[i_19]) = steps_4;
    return;
}

extern "C" __global__ void rngTrial(RWStructuredBuffer<float> output_1, uint seed_3, int count_2)
{
    int i_20 = int((blockIdx * blockDim + threadIdx).x);
    if(i_20 >= count_2)
    {
        return;
    }
    Rng_0 rng_5 = makeRng_0(seed_3 + uint(i_20));
    float * _S272 = (&(output_1)[i_20]);
    float _S273 = randFloat_0(&rng_5);
    *_S272 = _S273;
    return;
}

extern "C" __global__ void buildIceGrid(Medium_0 medium_2, StructuredBuffer<float2 > drift_2, MajorantGrid_0 grid_2, RWStructuredBuffer<float> outBounds_0, int cellCount_0)
{
    int i_21 = int((blockIdx * blockDim + threadIdx).x);
    if(i_21 >= cellCount_0)
    {
        return;
    }
    int _S274 = grid_2.dims_0.x;
    int cx_0 = i_21 % _S274;
    int _S275 = i_21 / _S274;
    int _S276 = grid_2.dims_0.y;
    int cy_0 = _S275 % _S276;
    int cz_0 = i_21 / (_S274 * _S276);
    float3  lo_7 = grid_2.origin_0 + make_float3 (float(cx_0), float(cy_0), float(cz_0)) * grid_2.cellExtent_0;
    float * _S277 = (&(outBounds_0)[i_21]);
    float3  _S278 = lo_7 + grid_2.cellExtent_0;
    GeneratorInput_0 _S279 = medium_2.gen_0;
    float _S280 = iceDensityBound_0(&_S279, drift_2, lo_7, _S278);
    *_S277 = _S280;
    return;
}

