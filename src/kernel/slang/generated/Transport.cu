// GENERATED FROM Transport.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

static __device__ float3  lerp_0(float3  x_0, float3  y_0, float3  s_0)
{
    return x_0 + (y_0 - x_0) * s_0;
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

static __device__ float dot_0(float2  x_1, float2  y_1)
{
    return x_1.x * y_1.x + x_1.y * y_1.y;
}

static __device__ float3  floor_0(float3  x_2)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_floor((_slang_vector_get_element(x_2, i_0))));
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

static __device__ float dot_1(float3  x_3, float3  y_2)
{
    return x_3.x * y_2.x + x_3.y * y_2.y + x_3.z * y_2.z;
}

static __device__ float lerp_1(float x_4, float y_3, float s_1)
{
    return x_4 + (y_3 - x_4) * s_1;
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_0(p_0);
    int3  _S5 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S6 = u_0.x;
    float _S7 = u_0.y;
    return lerp_1(lerp_1(lerp_1(dot_1(hash33_0(_S5), f_0), dot_1(hash33_0(_S5 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S6), lerp_1(dot_1(hash33_0(_S5 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S5 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S6), _S7), lerp_1(lerp_1(dot_1(hash33_0(_S5 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S5 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S6), lerp_1(dot_1(hash33_0(_S5 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S5 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S6), _S7), u_0.z);
}

static __device__ float2  orgWarpOffset_0(Organization_0 * o_0, float2  g_0)
{
    float2  s_2 = g_0 / make_float2 (2.5f);
    float _S8 = s_2.x;
    float _S9 = s_2.y;
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
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_2.y);
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

static __device__ float2  lerp_2(float2  x_8, float2  y_4, float2  s_3)
{
    return x_8 + (y_4 - x_8) * s_3;
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
    float s_5 = 2.0f * (F32_frac((dot_0(q_1, o_4->ogWaveK_0)))) - 1.0f;
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
        float fill_0 = lerp_1(w_0, 0.40000000596046448f, _S25);
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
        float s_6 = lerp_1(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S29);
        float _S33 = _S27 * s_6;
        _S26 = _S26 * make_float2 (s_6) + gcn_0 * make_float2 (_S27 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S29));
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
    float _S47 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_1(_S46, closedField_0, c_6->cvPolarity_0), lerp_2(goTop_0, gClosed_0, make_float2 (c_6->cvPolarity_0)), grad_2);
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
    float _S58 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_1(_S57, closedField_1, c_7->cvPolarity_0), lerp_2(goTop_3, gClosed_1, make_float2 (c_7->cvPolarity_0)), grad_3);
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
    *grad_4 = lerp_2(goTop_6, gClosed_2, make_float2 (c_8->cvPolarity_0)) / make_float2 (_S60);
    return lerp_1(_S70, closedField_2, _S71);
}

static __device__ bool any_0(bool2  x_9)
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
            result_2 = (bool((_slang_vector_get_element(x_9, i_5))));
        }
        i_5 = i_5 + int(1);
    }
    return result_2;
}

static __device__ int clamp_1(int x_10, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_10), (minBound_1)))), (maxBound_1)));
}

static __device__ float4  lerp_3(float4  x_11, float4  y_5, float4  s_7)
{
    return x_11 + (y_5 - x_11) * s_7;
}

static __device__ int2  min_0(int2  x_12, int2  y_6)
{
    int2  result_3;
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
        *_slang_vector_get_element_ptr(&result_3, i_6) = (I32_min((_slang_vector_get_element(x_12, i_6)), (_slang_vector_get_element(y_6, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_3;
}

static __device__ float2  max_0(float2  x_13, float2  y_7)
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
        *_slang_vector_get_element_ptr(&result_4, i_7) = (F32_max((_slang_vector_get_element(x_13, i_7)), (_slang_vector_get_element(y_7, i_7))));
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static __device__ float2  min_1(float2  x_14, float2  y_8)
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
        *_slang_vector_get_element_ptr(&result_5, i_8) = (F32_min((_slang_vector_get_element(x_14, i_8)), (_slang_vector_get_element(y_8, i_8))));
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static __device__ float2  clamp_2(float2  x_15, float2  minBound_2, float2  maxBound_2)
{
    return min_1(max_0(x_15, minBound_2), maxBound_2);
}

static __device__ float length_0(float2  x_16)
{
    return (F32_sqrt((dot_0(x_16, x_16))));
}

static __device__ float2  abs_0(float2  x_17)
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
        *_slang_vector_get_element_ptr(&result_6, i_9) = (F32_abs((_slang_vector_get_element(x_17, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static __device__ bool all_0(bool2  x_18)
{
    bool result_7 = true;
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
        if(result_7)
        {
            result_7 = (bool((_slang_vector_get_element(x_18, i_10))));
        }
        else
        {
            result_7 = false;
        }
        i_10 = i_10 + int(1);
    }
    return result_7;
}

static __device__ float smoothstep_0(float min_2, float max_1, float x_19)
{
    float _S72 = saturate_0((x_19 - min_2) / (max_1 - min_2));
    return _S72 * _S72 * (3.0f - (_S72 + _S72));
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
        lo_1 = max_0(lo_1, m_0->fadeAt_0 - make_float2 (_S80));
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

static __device__ float convCapCeiling_0(ConvectionInput_0 * c_9)
{
    float _S95 = c_9->cvHeroTop_0;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        return 0.0f;
    }
    float _S96 = c_9->cvPileusThick_0;
    float cap_0;
    if((c_9->cvPileusThick_0) > 0.0f)
    {
        cap_0 = _S95 + c_9->cvPileusGap_0 + _S96;
    }
    else
    {
        cap_0 = 0.0f;
    }
    float _S97 = c_9->cvVelumThick_0;
    float veil_0;
    if((c_9->cvVelumThick_0) > 0.0f)
    {
        veil_0 = c_9->cvVelumHeight_0 + 1.5f * _S97;
    }
    else
    {
        veil_0 = 0.0f;
    }
    return (F32_max((cap_0), (veil_0)));
}

static __device__ float convCeiling_0(ConvectionInput_0 * c_10)
{
    float _S98 = c_10->cvBillow_0;
    float field_0 = c_10->cvDepth_0 + c_10->cvBillow_0;
    float _S99 = c_10->cvHeroTop_0;
    float hero_0;
    if((c_10->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S99 + _S98 * c_10->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    float _S100 = (F32_max((field_0), (hero_0)));
    float _S101 = convCapCeiling_0(c_10);
    return (F32_max((_S100), (_S101)));
}

static __device__ float convDomeHeight_0(float top_0, float radius_0, float shape_0, float r_2)
{
    bool _S102;
    if(top_0 <= 0.0f)
    {
        _S102 = true;
    }
    else
    {
        _S102 = r_2 >= radius_0;
    }
    if(_S102)
    {
        return 0.0f;
    }
    return top_0 * (F32_pow((1.0f - r_2 * r_2 / (radius_0 * radius_0)), (shape_0)));
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_11, float r_3)
{
    return convDomeHeight_0(c_11->cvHeroTop_0, c_11->cvHeroRadius_0, c_11->cvShape_0, r_3);
}

static __device__ float convCapBound_0(ConvectionInput_0 * c_12, float3  lo_2, float3  hi_2, float low_0, float high_0)
{
    float2  nearGap_0 = max_0(max_0(float2 {lo_2.x, lo_2.z} - c_12->cvHeroAt_0, c_12->cvHeroAt_0 - float2 {hi_2.x, hi_2.z}), make_float2 (0.0f, 0.0f));
    float gap2_0 = dot_0(nearGap_0, nearGap_0);
    float _S103 = c_12->cvHeroRadius_0;
    float _S104 = c_12->cvPileusThick_0;
    bool _S105;
    float best_0;
    if((c_12->cvPileusThick_0) > 0.0f)
    {
        float rp_0 = 0.60000002384185791f * _S103;
        float _S106 = c_12->cvPileusGap_0;
        float _S107 = convHeroHeight_0(c_12, rp_0 * 0.60000002384185791f);
        float _S108 = 0.5f * _S104;
        float bottom_0 = _S106 + _S107 - _S108;
        float top_1 = _S106 + c_12->cvHeroTop_0 + _S108;
        if(gap2_0 < (rp_0 * rp_0))
        {
            _S105 = high_0 >= bottom_0;
        }
        else
        {
            _S105 = false;
        }
        if(_S105)
        {
            _S105 = low_0 <= top_1;
        }
        else
        {
            _S105 = false;
        }
        if(_S105)
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
    float _S109 = c_12->cvVelumThick_0;
    if((c_12->cvVelumThick_0) > 0.0f)
    {
        float ext_0 = 1.89999997615814209f * _S103;
        float bottom_1 = c_12->cvVelumHeight_0 - 0.5f * _S109;
        float top_2 = c_12->cvVelumHeight_0 + _S109;
        if(gap2_0 < (ext_0 * ext_0))
        {
            _S105 = high_0 >= bottom_1;
        }
        else
        {
            _S105 = false;
        }
        if(_S105)
        {
            _S105 = low_0 <= top_2;
        }
        else
        {
            _S105 = false;
        }
        if(_S105)
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
    Organization_0 _S110 = flat_0;
    float2  _S111 = orgPattern_0(&_S110, q0_0, spacing_2);
    Organization_0 _S112 = flat_0;
    float2  _S113 = orgPattern_0(&_S112, q1_0, spacing_2);
    float2  _S114 = make_float2 (q0_0.x, q1_0.y);
    Organization_0 _S115 = flat_0;
    float2  _S116 = orgPattern_0(&_S115, _S114, spacing_2);
    float2  _S117 = make_float2 (q1_0.x, q0_0.y);
    Organization_0 _S118 = flat_0;
    float2  _S119 = orgPattern_0(&_S118, _S117, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S111.x)))), ((F32_abs((_S111.y))))))), ((F32_max(((F32_abs((_S113.x)))), ((F32_abs((_S113.y)))))))));
    *a_1 = min_1(min_1(_S111, _S116), min_1(_S119, _S113)) - make_float2 (grow_0);
    *b_0 = max_0(max_0(_S111, _S116), max_0(_S119, _S113)) + make_float2 (grow_0);
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_14, int2  slot_6, float2  a_2, float2  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S120 = convVigour_0(c_14, slot_6);
    if(_S120 <= 0.0f)
    {
        return;
    }
    float2  _S121 = convCellCentre_0(c_14, slot_6);
    float2  _S122 = a_2 - _S121;
    float2  nearGap_1 = max_0(max_0(_S122, _S121 - b_1), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_0(nearGap_1, nearGap_1);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_0(abs_0(_S122), abs_0(b_1 - _S121));
    float oHi_0 = _S120 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S120 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S120 * convBump_0(dot_0(farGap_0, farGap_0), 1.04999995231628418f);
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
    float2  _S123 = floor_1((a_3 + b_2) * make_float2 (0.5f));
    int2  _S124 = make_int2 ((int)_S123.x, (int)_S123.y);
    float2  _S125 = make_float2 ((float)_S124.x, (float)_S124.y);
    float2  highEdge_0 = _S125 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S126;
    if(all_0(a_3 >= (_S125 - make_float2 (0.00009999999747379f))))
    {
        _S126 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S126 = false;
    }
    int j_7;
    int i_11;
    if(_S126)
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
                convSlotBound_0(c_15, _S124 + make_int2 (i_11, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        float2  _S127 = floor_1(a_3);
        int2  _S128 = make_int2 ((int)_S127.x, (int)_S127.y);
        int2  _S129 = make_int2 (int(1), int(1));
        int2  i0_0 = _S128 - _S129;
        float2  _S130 = floor_1(b_2);
        int2  _S131 = make_int2 ((int)_S130.x, (int)_S130.y);
        int2  _S132 = _S131 + _S129;
        int _S133 = i0_0.y;
        j_7 = _S133;
        for(;;)
        {
            if(j_7 <= (_S132.y))
            {
                _S126 = j_7 <= (_S133 + int(32));
            }
            else
            {
                _S126 = false;
            }
            if(_S126)
            {
            }
            else
            {
                break;
            }
            int _S134 = i0_0.x;
            i_11 = _S134;
            for(;;)
            {
                bool _S135;
                if(i_11 <= (_S132.x))
                {
                    _S135 = i_11 <= (_S134 + int(32));
                }
                else
                {
                    _S135 = false;
                }
                if(_S135)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, make_int2 (i_11, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_1((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_15->cvPolarity_0);
    float _S136 = c_15->cvLacunarity_0;
    float field_2;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_1(field_1, 0.40000000596046448f, _S136);
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
    bool _S137;
    if(cover_1 <= 0.0f)
    {
        _S137 = true;
    }
    else
    {
        _S137 = (c_17->cvDepth_0) <= 0.0f;
    }
    if(_S137)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_17->cvDepth_0), (1.0f / (F32_max((c_17->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSlopeCap_0(ConvectionInput_0 * c_18)
{
    float _S138 = c_18->cvSpacing_0;
    float cap_1 = 7.0f / c_18->cvSpacing_0;
    if(((&c_18->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_1;
    }
    float _S139 = c_18->cvLacunarity_0;
    float cap_2;
    if((c_18->cvLacunarity_0) > 0.0f)
    {
        cap_2 = cap_1 + 1.5f / (0.15000000596046448f * _S139 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S138);
    }
    else
    {
        cap_2 = cap_1;
    }
    float _S140 = c_18->cvGapWidth_0;
    if((c_18->cvGapWidth_0) > 0.0f)
    {
        cap_2 = cap_2 + 14.25f * c_18->cvPolarity_0 / (0.5f * _S140 * _S138);
    }
    return cap_2 + 3.0f * (&c_18->cvOrg_0)->ogWaveAmp_0 * length_0((&c_18->cvOrg_0)->ogWaveK_0);
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
            float4  _S141 = convTurret_0(c_20, k_3);
            t_4 = _S141;
        }
        float4  _S142 = t_4;
        float2  _S143 = float2 {_S142.x, _S142.y};
        float2  gap_0 = max_0(max_0(lo_3 - _S143, _S143 - hi_3), make_float2 (0.0f, 0.0f));
        float _S144 = t_4.z;
        float outer_0 = 1.29999995231628418f * _S144;
        float band_1 = outer_0 - 0.75f * _S144;
        if((dot_0(gap_0, gap_0)) < (outer_0 * outer_0))
        {
            slope_0 = (F32_max((slope_0), (1.5f / band_1)));
        }
        k_3 = k_3 + int(1);
    }
    return slope_0 * c_20->cvMoat_0;
}

static __device__ float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S145;
    if(vMin_0 <= 0.0f)
    {
        _S145 = true;
    }
    else
    {
        _S145 = hMin_0 <= 0.0f;
    }
    if(_S145)
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
    return length_0(make_float2 (c_22->cvShapeHalfWidth_0 + lift_0, c_22->cvShapeRound_0 + c_22->cvReliefHeight_0 + lift_0));
}

static __device__ float convHeroReachAll_0(ConvectionInput_0 * c_23)
{
    float _S146 = convHeroReach_0(c_23);
    float _S147;
    if((c_23->cvShapeOn_0) != int(0))
    {
        float _S148 = convShapeReach_0(c_23);
        _S147 = (F32_max((_S146), (_S148)));
    }
    else
    {
        _S147 = _S146;
    }
    return _S147;
}

static __device__ float convDomeRadiusAt_0(float top_3, float radius_1, float shape_1, float above_2)
{
    bool _S149;
    if(top_3 <= 0.0f)
    {
        _S149 = true;
    }
    else
    {
        _S149 = above_2 >= top_3;
    }
    if(_S149)
    {
        return -1.0f;
    }
    return radius_1 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / top_3), (1.0f / (F32_max((shape_1), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_24, float above_3)
{
    return convDomeRadiusAt_0(c_24->cvHeroTop_0, c_24->cvHeroRadius_0, c_24->cvShape_0, above_3);
}

static __device__ float4  convShapeTexel_0(ConvectionInput_0 * c_25, int i_12, int j_8)
{
    int k_4 = (j_8 * c_25->cvShapeDim_0.x + i_12) * int(4);
    StructuredBuffer<float> _S150 = c_25->cvShapeMap_0;
    float _S151 = __ldg((&(c_25->cvShapeMap_0)[k_4]));
    float _S152 = __ldg((&(_S150)[k_4 + int(1)]));
    float _S153 = __ldg((&(_S150)[k_4 + int(2)]));
    float _S154 = __ldg((&(_S150)[k_4 + int(3)]));
    return make_float4 (_S151, _S152, _S153, _S154);
}

static __device__ float convShapeDistance_0(ConvectionInput_0 * c_26, float u_3, float y_9, float2  * slopeUY_0, float * relief_0)
{
    float _S155 = c_26->cvShapeTexel_0;
    float2  st_0 = make_float2 (u_3, y_9) / make_float2 (c_26->cvShapeTexel_0) + c_26->cvShapeOffset_0 - make_float2 (0.5f);
    int2  _S156 = make_int2 (int(1), int(1));
    int2  last_0 = c_26->cvShapeDim_0 - _S156;
    float2  _S157 = make_float2 ((float)last_0.x, (float)last_0.y);
    float2  q_6 = clamp_2(st_0, make_float2 (0.0f, 0.0f), _S157);
    float past_0 = length_0(st_0 - q_6);
    float2  f0_0 = floor_1(q_6);
    int2  _S158 = make_int2 ((int)f0_0.x, (int)f0_0.y);
    int2  i0_1 = min_0(_S158, last_0);
    int2  i1_0 = min_0(i0_1 + _S156, last_0);
    float2  fr_0 = q_6 - f0_0;
    int _S159 = i0_1.x;
    int _S160 = i0_1.y;
    float4  _S161 = convShapeTexel_0(c_26, _S159, _S160);
    int _S162 = i1_0.x;
    float4  _S163 = convShapeTexel_0(c_26, _S162, _S160);
    int _S164 = i1_0.y;
    float4  _S165 = convShapeTexel_0(c_26, _S159, _S164);
    float4  _S166 = convShapeTexel_0(c_26, _S162, _S164);
    float4  _S167 = make_float4 (fr_0.x);
    float4  blend_0 = lerp_3(lerp_3(_S161, _S163, _S167), lerp_3(_S165, _S166, _S167), make_float4 (fr_0.y));
    *slopeUY_0 = float2 {blend_0.y, blend_0.z};
    *relief_0 = blend_0.w;
    return (blend_0.x - past_0) * _S155;
}

static __device__ float convShapeProfile_0(float dIn_0, float m_1, float rimR_0, float2  * stepDM_0)
{
    if(dIn_0 >= rimR_0)
    {
        *stepDM_0 = make_float2 (0.0f, rimR_0 - m_1);
        return m_1 - rimR_0;
    }
    float2  w_2 = make_float2 (dIn_0 - rimR_0, m_1);
    float len_0 = length_0(w_2);
    float gap_1 = len_0 - rimR_0;
    float2  _S168;
    if(len_0 > 9.99999997475242708e-07f)
    {
        _S168 = w_2 * make_float2 (- gap_1 / len_0);
    }
    else
    {
        _S168 = make_float2 (0.0f, rimR_0);
    }
    *stepDM_0 = _S168;
    return gap_1;
}

static __device__ float convShapeBound_0(ConvectionInput_0 * c_27, float3  lo_4, float3  hi_4, float low_1, float high_1)
{
    float2  ea_0 = float2 {lo_4.x, lo_4.z} - c_27->cvHeroAt_0;
    float2  eb_0 = float2 {hi_4.x, hi_4.z} - c_27->cvHeroAt_0;
    float _S169 = c_27->cvShapeAxisU_0.y;
    float _S170 = - _S169;
    float _S171 = c_27->cvShapeAxisU_0.x;
    float _S172 = ea_0.x;
    float _S173 = _S172 * _S171;
    float _S174 = eb_0.x;
    float _S175 = _S174 * _S171;
    float _S176 = ea_0.y;
    float _S177 = _S176 * _S169;
    float _S178 = eb_0.y;
    float _S179 = _S178 * _S169;
    float uLo_0 = (F32_min((_S173), (_S175))) + (F32_min((_S177), (_S179)));
    float uHi_0 = (F32_max((_S173), (_S175))) + (F32_max((_S177), (_S179)));
    float _S180 = _S172 * _S170;
    float _S181 = _S174 * _S170;
    float _S182 = _S176 * _S171;
    float _S183 = _S178 * _S171;
    float nLo_0 = (F32_min((_S180), (_S181))) + (F32_min((_S182), (_S183)));
    float nHi_0 = (F32_max((_S180), (_S181))) + (F32_max((_S182), (_S183)));
    bool _S184;
    if(nLo_0 <= 0.0f)
    {
        _S184 = nHi_0 >= 0.0f;
    }
    else
    {
        _S184 = false;
    }
    float mMin_0;
    if(_S184)
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
    float _S185 = convShapeDistance_0(c_27, 0.5f * (uLo_0 + uHi_0), 0.5f * (low_1 + high_1), &slopeUnused_0, &relief_1);
    float _S186 = length_0(halfSpan_0);
    float dMax_0 = _S185 + 2.5f * _S186;
    float _S187 = c_27->cvReliefHeight_0;
    if((c_27->cvReliefHeight_0) > 0.0f)
    {
        _S184 = nLo_0 > 0.0f;
    }
    else
    {
        _S184 = false;
    }
    if(_S184)
    {
        mMin_0 = (F32_max((nLo_0 - (F32_min((_S187), (_S187 * relief_1 + c_27->cvReliefSlope_0 * _S186)))), (0.0f)));
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
    float2  _S188 = float2 {t_6.x, t_6.y};
    float2  nearGap_2 = max_0(max_0(float2 {lo_5.x, lo_5.z} - _S188, _S188 - float2 {hi_5.x, hi_5.z}), make_float2 (0.0f, 0.0f));
    float gap2_1 = dot_0(nearGap_2, nearGap_2);
    float _S189 = convTurretReach_0(c_30, t_6);
    if(gap2_1 >= (_S189 * _S189))
    {
        return false;
    }
    float rMin_0 = (F32_sqrt((gap2_1)));
    float _S190 = t_6.w;
    float _S191 = t_6.z;
    float tower_0 = convDomeHeight_0(_S190, _S191, c_30->cvShape_0, rMin_0);
    float ra_0 = convDomeRadiusAt_0(_S190, _S191, c_30->cvShape_0, low_2);
    float _S192 = convTurretBillow_0(c_30, _S191);
    float _S193 = convLift_0(c_30, high_2, _S192);
    *lift_1 = _S193;
    bool _S194 = ra_0 < 0.0f;
    bool _S195;
    if(_S194)
    {
        _S195 = true;
    }
    else
    {
        _S195 = rMin_0 >= ra_0;
    }
    if(_S195)
    {
        float hMin_1;
        if(_S194)
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
    float _S196 = convCeiling_0(c_31);
    float _S197 = c_31->cvMammaDepth_0;
    bool pouches_0;
    if(high_3 < (- c_31->cvMammaDepth_0))
    {
        pouches_0 = true;
    }
    else
    {
        pouches_0 = low_3 > _S196;
    }
    if(pouches_0)
    {
        return 0.0f;
    }
    if(_S197 > 0.0f)
    {
        pouches_0 = low_3 < 40.0f;
    }
    else
    {
        pouches_0 = false;
    }
    float _S198 = (F32_max((low_3), (0.0f)));
    float _S199 = (F32_min(((F32_max((high_3), (0.0f)))), (_S196)));
    bool _S200 = (c_31->cvHeroTop_0) > 0.0f;
    bool _S201;
    if(_S200)
    {
        if((c_31->cvPileusThick_0) > 0.0f)
        {
            _S201 = true;
        }
        else
        {
            _S201 = (c_31->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        _S201 = false;
    }
    float capBound_0;
    if(_S201)
    {
        float _S202 = convCapBound_0(c_31, lo_6, hi_6, _S198, _S199);
        capBound_0 = _S202;
    }
    else
    {
        capBound_0 = 0.0f;
    }
    float _S203 = convLift_0(c_31, _S199, 1.0f);
    float inside_0;
    if((c_31->cvHeroAlone_0) == int(0))
    {
        float2  _S204 = float2 {lo_6.x, lo_6.z};
        float2  _S205 = float2 {hi_6.x, hi_6.z};
        float _S206 = convUpdraftBound_0(c_31, _S204 - c_31->cvDrift_0, _S205 - c_31->cvDrift_0);
        float _S207 = convTowerHeight_0(c_31, _S206);
        float _S208 = convNeededUpdraft_0(c_31, _S198);
        if(_S206 < _S208)
        {
            float _S209 = convSlopeCap_0(c_31);
            if((c_31->cvMoat_0) > 0.0f)
            {
                float _S210 = convMoatSlopeOver_0(c_31, _S204, _S205);
                inside_0 = _S209 + _S210;
            }
            else
            {
                inside_0 = _S209;
            }
            inside_0 = _S203 - convDistanceFloor_0(_S198 - _S207, (_S208 - _S206) / inside_0);
        }
        else
        {
            inside_0 = (F32_max((_S207 - _S198), (0.0f))) + _S203;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    float edge_0;
    if(_S200)
    {
        float rMin_1 = length_0(max_0(max_0(float2 {lo_6.x, lo_6.z} - c_31->cvHeroAt_0, c_31->cvHeroAt_0 - float2 {hi_6.x, hi_6.z}), make_float2 (0.0f, 0.0f)));
        float _S211 = convHeroReachAll_0(c_31);
        float groupD_0;
        float groupLift_0;
        if(rMin_1 < _S211)
        {
            float _S212 = convHeroHeight_0(c_31, rMin_1);
            float _S213 = convHeroRadiusAt_0(c_31, _S198);
            float _S214 = c_31->cvHeroBillow_0;
            float _S215 = convLift_0(c_31, _S199, c_31->cvHeroBillow_0);
            bool _S216 = _S213 < 0.0f;
            if(_S216)
            {
                _S201 = true;
            }
            else
            {
                _S201 = rMin_1 >= _S213;
            }
            if(_S201)
            {
                if(_S216)
                {
                    edge_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    edge_0 = rMin_1 - _S213;
                }
                edge_0 = - convDistanceFloor_0(_S198 - _S212, edge_0);
            }
            else
            {
                edge_0 = (F32_max((_S212 - _S198), (0.0f)));
            }
            if((c_31->cvShapeOn_0) != int(0))
            {
                _S201 = (c_31->cvShapeDecay_0) < 1.0f;
            }
            else
            {
                _S201 = false;
            }
            if(_S201)
            {
                float _S217 = convShapeBound_0(c_31, lo_6, hi_6, _S198, _S199);
                float _S218 = lerp_1(_S217, edge_0, c_31->cvShapeDecay_0);
                float _S219 = convLift_0(c_31, _S199, _S214 * lerp_1(c_31->cvShapeBillow_0, 1.0f, c_31->cvShapeDecay_0));
                groupD_0 = _S218;
                groupLift_0 = _S219;
            }
            else
            {
                groupD_0 = edge_0;
                groupLift_0 = _S215;
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
            float4  _S220 = convTurret_0(c_31, k_5);
            float turretD_0;
            float turretLift_0;
            bool _S221 = convTurretBound_0(c_31, _S220, lo_6, hi_6, _S198, _S199, &turretD_0, &turretLift_0);
            if(_S221)
            {
                float _S222 = (F32_max((groupLift_0), (turretLift_0)));
                groupD_0 = (F32_max((groupD_0), (turretD_0)));
                groupLift_0 = _S222;
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
        inside_0 = _S199 + _S197;
    }
    else
    {
        inside_0 = _S199;
    }
    return (F32_max((c_31->cvSigma_0 * (F32_sqrt((saturate_0(inside_0 / 40.0f)))) * edge_0 * 1.00001001358032227f), (capBound_0)));
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_20 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_13 = clamp_1(int((F32_floor((x_20)))), int(0), int(31));
    float2  _S223 = __ldg((&(disp_0)[i_13]));
    float2  _S224 = __ldg((&(disp_0)[i_13 + int(1)]));
    return lerp_2(_S223, _S224, make_float2 (x_20 - float(i_13)));
}

static __device__ void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<float2 > disp_1, float d0_0, float d1_0, float2  * lo_7, float2  * hi_7)
{
    float2  _S225 = driftAt_0(g_5, disp_1, d0_0);
    *lo_7 = _S225;
    *hi_7 = _S225;
    float2  _S226 = driftAt_0(g_5, disp_1, d1_0);
    *lo_7 = min_1(*lo_7, _S226);
    *hi_7 = max_0(*hi_7, _S226);
    int _S227 = clamp_1(int((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_6 = clamp_1(int((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_6 <= _S227)
        {
        }
        else
        {
            break;
        }
        float2  _S228 = *lo_7;
        float2  _S229 = __ldg((&(disp_1)[k_6]));
        *lo_7 = min_1(_S228, _S229);
        float2  _S230 = *hi_7;
        float2  _S231 = __ldg((&(disp_1)[k_6]));
        *hi_7 = max_0(_S230, _S231);
        k_6 = k_6 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_6, float2  q0_2, float2  q1_2)
{
    float2  a_4;
    float2  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    float2  _S232 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    float2  _S233 = floor_1(a_4);
    int2  _S234 = make_int2 ((int)_S233.x, (int)_S233.y);
    int2  _S235 = make_int2 (int(1), int(1));
    int2  i0_2 = _S234 - _S235;
    float2  _S236 = floor_1(b_3);
    int2  _S237 = make_int2 ((int)_S236.x, (int)_S236.y);
    int2  _S238 = _S237 + _S235;
    int _S239 = i0_2.y;
    int j_9 = _S239;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S240;
        if(j_9 <= (_S238.y))
        {
            _S240 = j_9 <= (_S239 + int(32));
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
        int _S241 = i0_2.x;
        int i_14 = _S241;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S242;
            if(i_14 <= (_S238.x))
            {
                _S242 = i_14 <= (_S241 + int(32));
            }
            else
            {
                _S242 = false;
            }
            if(_S242)
            {
            }
            else
            {
                break;
            }
            int2  o_7 = make_int2 (i_14, j_9);
            if((hash22_0(o_7, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_14 = i_14 + int(1);
                continue;
            }
            float2  _S243 = make_float2 ((float)o_7.x, (float)o_7.y);
            float2  c_32 = _S243 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S232;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_0(max_0(a_4 - c_32, c_32 - b_3), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_14 = i_14 + int(1);
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
    bool _S244;
    if(d1_1 < 0.0f)
    {
        _S244 = true;
    }
    else
    {
        _S244 = d0_1 > (g_7->streakLength_0);
    }
    if(_S244)
    {
        return 0.0f;
    }
    float _S245 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S246 = cellFieldBound_0(g_7, make_float2 (lo_8.x, lo_8.z) - driftHi_0, make_float2 (hi_8.x, hi_8.z) - driftLo_0);
    return (F32_max((_S246 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S245), (1.0f)));
}

static __device__ float mediumBound_0(Medium_0 * m_2, StructuredBuffer<float2 > disp_3, float3  lo_9, float3  hi_9)
{
    int _S247 = m_2->mode_0;
    if((m_2->mode_0) == int(3))
    {
        float _S248 = convectionBound_0(&m_2->conv_0, lo_9, hi_9);
        return _S248;
    }
    if(_S247 == int(2))
    {
        float _S249 = iceDensityBound_0(&m_2->gen_0, disp_3, lo_9, hi_9);
        return _S249;
    }
    return m_2->majorant_0;
}

static __device__ float gridBound_0(Medium_0 * m_3, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_0, StructuredBuffer<float2 > disp_4, int3  c_33, float fallback_0)
{
    int _S250 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S250 == int(2))
    {
        float3  _S251 = make_float3 ((float)c_33.x, (float)c_33.y, (float)c_33.z);
        float3  lo_10 = g_8->origin_0 + _S251 * g_8->cellExtent_0;
        float _S252 = mediumBound_0(m_3, disp_4, lo_10, lo_10 + g_8->cellExtent_0);
        return _S252;
    }
    int _S253 = c_33.x;
    bool _S254;
    if(_S253 < int(0))
    {
        _S254 = true;
    }
    else
    {
        _S254 = (c_33.y) < int(0);
    }
    if(_S254)
    {
        _S254 = true;
    }
    else
    {
        _S254 = (c_33.z) < int(0);
    }
    if(_S254)
    {
        _S254 = true;
    }
    else
    {
        _S254 = _S253 >= (g_8->dims_0.x);
    }
    if(_S254)
    {
        _S254 = true;
    }
    else
    {
        _S254 = (c_33.y) >= (g_8->dims_0.y);
    }
    if(_S254)
    {
        _S254 = true;
    }
    else
    {
        _S254 = (c_33.z) >= (g_8->dims_0.z);
    }
    if(_S254)
    {
        return fallback_0;
    }
    float _S255 = __ldg((&(bounds_0)[(c_33.z * g_8->dims_0.y + c_33.y) * g_8->dims_0.x + _S253]));
    return _S255;
}

static __device__ float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S256;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S256 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S256 = false;
    }
    if(_S256)
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
    uint _S257 = r_4->state_0 * 747796405U + 2891336453U;
    r_4->state_0 = _S257;
    uint word_0 = ((_S257 >> ((_S257 >> 28U) + 4U)) ^ _S257) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float orgWaveFactor_0(Organization_0 * o_8, float2  q_7)
{
    float2  unused_0;
    float _S258 = orgWave_0(o_8, q_7, &unused_0);
    return _S258;
}

static __device__ float cellField_0(GeneratorInput_0 * g_9, float2  q_8)
{
    float2  _S259 = q_8 - g_9->cellDrift_0;
    float2  _S260 = orgPattern_0(&g_9->gnOrg_0, _S259, g_9->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(_S260);
    int2  _S261 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    float2  _S262 = orgJitter_0(&g_9->gnOrg_0, 0.80000001192092896f);
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
        int i_15 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_15 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_9 = _S261 + make_int2 (i_15, j_10);
            if((hash22_0(o_9, 2654435769U).x) > (g_9->cellDensity_0))
            {
                i_15 = i_15 + int(1);
                continue;
            }
            float2  _S263 = make_float2 ((float)o_9.x, (float)o_9.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(_S260 - (_S263 + make_float2 (0.5f) + (hash22_0(o_9, 0U) - make_float2 (0.5f)) * _S262)) * 2.20000004768371582f);
            i_15 = i_15 + int(1);
        }
        j_10 = j_10 + int(1);
        acc_2 = acc_3;
    }
    float _S264 = acc_2 * g_9->cellStrength_0;
    float _S265 = orgWaveFactor_0(&g_9->gnOrg_0, _S259);
    return _S264 * _S265;
}

static __device__ float fbm_0(float3  p_2, int octaves_1)
{
    int i_16 = int(0);
    float amp_0 = 0.5f;
    float3  _S266 = p_2;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_16 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_16 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S266);
        float norm_1 = norm_0 + amp_0;
        float3  _S267 = _S266 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_16 = i_16 + int(1);
        amp_0 = amp_1;
        _S266 = _S267;
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
    bool _S268;
    if(depth_1 < 0.0f)
    {
        _S268 = true;
    }
    else
    {
        _S268 = depth_1 > (g_10->streakLength_0);
    }
    if(_S268)
    {
        return 0.0f;
    }
    float2  _S269 = float2 {p_3.x, p_3.z};
    float2  _S270 = driftAt_0(g_10, disp_5, depth_1);
    float2  source_0 = _S269 - _S270;
    float _S271 = cellField_0(g_10, source_0);
    if(_S271 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S271 * (F32_exp((- g_10->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_10->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_10->streakLength_0, g_10->streakLength_0, depth_1)) * (F32_max((1.0f + g_10->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_10->detailScale_0)).x, (source_0 / make_float2 (g_10->detailScale_0)).y, depth_1 / (F32_max((g_10->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_10->timeSeconds_0 * 0.00999999977648258f), g_10->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_10->opticalDepth_0 / (F32_max((g_10->streakLength_0), (1.0f)));
}

static __device__ float convPouches_0(ConvectionInput_0 * c_34, float2  q_9)
{
    float2  g_11 = q_9 / make_float2 (c_34->cvPouchSize_0);
    float2  _S272 = floor_1(g_11);
    int2  _S273 = make_int2 ((int)_S272.x, (int)_S272.y);
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
        int i_17 = int(-1);
        for(;;)
        {
            if(i_17 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_7 = _S273 + make_int2 (i_17, j_11);
            float2  _S274 = make_float2 ((float)slot_7.x, (float)slot_7.y);
            float2  d_8 = g_11 - (_S274 + make_float2 (0.5f) + (hash22_0(slot_7, 739982445U) - make_float2 (0.5f)) * make_float2 (0.60000002384185791f));
            float t2_0 = dot_0(d_8, d_8) / 0.46240001916885376f;
            if(t2_0 >= 1.0f)
            {
                i_17 = i_17 + int(1);
                continue;
            }
            float2  h_3 = hash22_0(slot_7, 2135587861U);
            deepest_1 = (F32_max((deepest_1), (lerp_1(0.30000001192092896f, 1.0f, convLife_0((F32_frac((2.0f * c_34->cvAge_0 + h_3.x))))) * lerp_1(0.60000002384185791f, 1.0f, h_3.y) * (F32_sqrt((1.0f - t2_0))))));
            i_17 = i_17 + int(1);
        }
        int j_12 = j_11 + int(1);
        deepest_0 = deepest_1;
        j_11 = j_12;
    }
    return deepest_0;
}

static __device__ void convMoatRing_0(float2  xz_0, float2  at_0, float radius_3, float * s_8, float2  * gs_0, float * slope_1)
{
    float2  d_9 = xz_0 - at_0;
    float r2_1 = dot_0(d_9, d_9);
    float outer_1 = 1.29999995231628418f * radius_3;
    if(!(r2_1 < (outer_1 * outer_1)))
    {
        return;
    }
    float band_2 = outer_1 - 0.75f * radius_3;
    float inner_1 = outer_1 - band_2;
    *slope_1 = (F32_max((*slope_1), (1.5f / band_2)));
    float r_5 = (F32_sqrt((r2_1)));
    float t_7 = saturate_0((r_5 - inner_1) / band_2);
    float f_1 = t_7 * t_7 * (3.0f - 2.0f * t_7);
    if(f_1 < (*s_8))
    {
        *s_8 = f_1;
        float2  _S275;
        if(r_5 > 0.00100000004749745f)
        {
            _S275 = d_9 * make_float2 (6.0f * t_7 * (1.0f - t_7) / (band_2 * r_5));
        }
        else
        {
            _S275 = make_float2 (0.0f, 0.0f);
        }
        *gs_0 = _S275;
    }
    return;
}

static __device__ float convMoat_0(ConvectionInput_0 * c_35, float2  xz_1, float2  * grad_5, float * slopeAdd_0)
{
    float s_9 = 1.0f;
    float2  gs_1 = make_float2 (0.0f, 0.0f);
    float slope_2 = 0.0f;
    convMoatRing_0(xz_1, c_35->cvHeroAt_0, c_35->cvHeroRadius_0, &s_9, &gs_1, &slope_2);
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
        float4  _S276 = convTurret_0(c_35, k_7);
        convMoatRing_0(xz_1, float2 {_S276.x, _S276.y}, _S276.z, &s_9, &gs_1, &slope_2);
        k_7 = k_7 + int(1);
    }
    float _S277 = c_35->cvMoat_0;
    *grad_5 = gs_1 * make_float2 (c_35->cvMoat_0);
    *slopeAdd_0 = slope_2 * _S277;
    return 1.0f - _S277 * (1.0f - s_9);
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_36, float2  q_10, float2  * grad_6)
{
    if(((&c_36->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S278 = convUpdraftGradT_2(c_36, q_10, grad_6);
        return _S278;
    }
    if((c_36->cvLacunarity_0) <= 0.0f)
    {
        float _S279 = convUpdraftGradT_1(c_36, q_10, grad_6);
        return _S279;
    }
    float _S280 = convUpdraftGradT_0(c_36, q_10, grad_6);
    return _S280;
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
    float _S281;
    if(v_2 >= 0.0f)
    {
        _S281 = d_10;
    }
    else
    {
        _S281 = - d_10;
    }
    return _S281;
}

static __device__ float convFieldBaseInside_0(ConvectionInput_0 * c_37, float w_3, float2  slope_4, float cap_3)
{
    float _S282 = convTowerHeight_0(c_37, w_3);
    float v_3 = _S282 - 1.0f;
    float _S283 = convNeededUpdraft_0(c_37, 1.0f);
    return convSurfaceDistance_0(v_3, w_3 - _S283, (F32_min((length_0(slope_4)), (cap_3))));
}

static __device__ float convDomeSurface_0(float top_4, float radius_4, float shape_2, float2  rel_0, float r_6, float py_0, float above_4, float3  * x_21)
{
    float v_4 = convDomeHeight_0(top_4, radius_4, shape_2, r_6) - above_4;
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
        float h_4 = ra_1 - r_6;
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
        float _S284 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S284;
        d_11 = d_12;
    }
    float2  radial_0;
    if(r_6 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / make_float2 (r_6);
    }
    else
    {
        radial_0 = make_float2 (0.0f, 0.0f);
    }
    float2  at_1 = rel_0 + radial_0 * make_float2 (shiftOut_0);
    *x_21 = make_float3 (at_1.x, py_0 + shiftUp_0, at_1.y);
    return d_11;
}

static __device__ float convTowerSurface_0(ConvectionInput_0 * c_38, float2  rel_1, float r_7, float py_1, float above_5, float3  * x_22)
{
    float _S285 = convDomeSurface_0(c_38->cvHeroTop_0, c_38->cvHeroRadius_0, c_38->cvShape_0, rel_1, r_7, py_1, above_5, x_22);
    return _S285;
}

static __device__ float convReliefLift_0(ConvectionInput_0 * c_39, float dIn_1, float relief_2)
{
    return c_39->cvReliefHeight_0 * relief_2 * smoothstep_0(0.0f, (F32_max((c_39->cvReliefFade_0), (1.0f))), dIn_1);
}

static __device__ float convShapeSurface_0(ConvectionInput_0 * c_40, float2  plane_0, float py_2, float above_6, float3  * x_23)
{
    float _S286 = plane_0.x;
    float2  slopeUY_1;
    float relief_3;
    float _S287 = convShapeDistance_0(c_40, _S286, above_6, &slopeUY_1, &relief_3);
    float _S288 = plane_0.y;
    float _S289 = (F32_abs((_S288)));
    bool _S290;
    if((c_40->cvReliefHeight_0) > 0.0f)
    {
        _S290 = _S288 > 0.0f;
    }
    else
    {
        _S290 = false;
    }
    float m_4;
    if(_S290)
    {
        float _S291 = convReliefLift_0(c_40, _S287, relief_3);
        m_4 = (F32_max((_S288 - _S291), (0.0f)));
    }
    else
    {
        m_4 = _S289;
    }
    float2  stepDM_1;
    float gap_2 = convShapeProfile_0(_S287, m_4, c_40->cvShapeRound_0, &stepDM_1);
    float side_0;
    if(_S288 >= 0.0f)
    {
        side_0 = 1.0f;
    }
    else
    {
        side_0 = -1.0f;
    }
    *x_23 = make_float3 (_S286 + stepDM_1.x * slopeUY_1.x, py_2 + stepDM_1.x * slopeUY_1.y, _S288 + side_0 * stepDM_1.y);
    return - gap_2;
}

static __device__ bool convHeroSmooth_0(ConvectionInput_0 * c_41, float3  p_4, float above_7, float * d_13, float3  * x_24, float * amount_0, float * lobe_0)
{
    *d_13 = -1.00000001504746622e+30f;
    *x_24 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S292 = c_41->cvHeroBillow_0;
    *amount_0 = c_41->cvHeroBillow_0;
    *lobe_0 = _S292;
    float2  rel_2 = float2 {p_4.x, p_4.z} - c_41->cvHeroAt_0;
    float r_8 = length_0(rel_2);
    float _S293 = convHeroReachAll_0(c_41);
    if(r_8 >= _S293)
    {
        return false;
    }
    if((c_41->cvShapeOn_0) == int(0))
    {
        float _S294 = convTowerSurface_0(c_41, rel_2, r_8, p_4.y, above_7, x_24);
        *d_13 = _S294;
    }
    else
    {
        float2  plane_1 = make_float2 (dot_0(rel_2, c_41->cvShapeAxisU_0), dot_0(rel_2, make_float2 (- c_41->cvShapeAxisU_0.y, c_41->cvShapeAxisU_0.x)));
        float _S295 = c_41->cvShapeDecay_0;
        if((c_41->cvShapeDecay_0) >= 1.0f)
        {
            float _S296 = convTowerSurface_0(c_41, plane_1, r_8, p_4.y, above_7, x_24);
            *d_13 = _S296;
        }
        else
        {
            float _S297 = p_4.y;
            float3  xs_0;
            float _S298 = convShapeSurface_0(c_41, plane_1, _S297, above_7, &xs_0);
            if(_S295 > 0.0f)
            {
                float3  xt_0;
                float _S299 = convTowerSurface_0(c_41, plane_1, r_8, _S297, above_7, &xt_0);
                *d_13 = lerp_1(_S298, _S299, _S295);
                *x_24 = lerp_0(xs_0, xt_0, make_float3 (_S295));
            }
            else
            {
                *d_13 = _S298;
                *x_24 = xs_0;
            }
            float _S300 = c_41->cvShapeBillow_0;
            *amount_0 = _S292 * lerp_1(c_41->cvShapeBillow_0, 1.0f, _S295);
            *lobe_0 = _S292 * lerp_1((F32_max((_S300), (0.30000001192092896f))), 1.0f, _S295);
        }
    }
    return true;
}

static __device__ bool convTurretSmooth_0(ConvectionInput_0 * c_42, float4  t_8, float3  p_5, float above_8, float * d_14, float3  * x_25, float * k_8)
{
    *d_14 = -1.00000001504746622e+30f;
    *x_25 = make_float3 (0.0f, 0.0f, 0.0f);
    *k_8 = 1.0f;
    float2  rel_3 = float2 {p_5.x, p_5.z} - float2 {t_8.x, t_8.y};
    float r2_2 = dot_0(rel_3, rel_3);
    float _S301 = convTurretReach_0(c_42, t_8);
    if(r2_2 >= (_S301 * _S301))
    {
        return false;
    }
    float _S302 = t_8.w;
    if(above_8 >= (_S302 + c_42->cvBillow_0 * c_42->cvHeroBillow_0))
    {
        return false;
    }
    float r_9 = (F32_sqrt((r2_2)));
    float _S303 = t_8.z;
    float _S304 = convTurretBillow_0(c_42, _S303);
    *k_8 = _S304;
    float3  own_0;
    float _S305 = convDomeSurface_0(_S302, _S303, c_42->cvShape_0, rel_3, r_9, p_5.y, above_8, &own_0);
    *d_14 = _S305;
    float3  w_4 = own_0 + make_float3 (t_8.x - c_42->cvHeroAt_0.x, 0.0f, t_8.y - c_42->cvHeroAt_0.y);
    float3  w_5;
    if((c_42->cvShapeOn_0) != int(0))
    {
        float2  _S306 = float2 {w_4.x, w_4.z};
        w_5 = make_float3 (dot_0(_S306, c_42->cvShapeAxisU_0), w_4.y, dot_0(_S306, make_float2 (- c_42->cvShapeAxisU_0.y, c_42->cvShapeAxisU_0.x)));
    }
    else
    {
        w_5 = w_4;
    }
    *x_25 = w_5;
    return true;
}

static __device__ float convGroupBaseInside_0(ConvectionInput_0 * c_43, float2  xz_2, bool nearGroup_0)
{
    float best_1;
    if((c_43->cvHeroTop_0) > 0.0f)
    {
        float3  p_6 = make_float3 (xz_2.x, c_43->cvBase_0 + 1.0f, xz_2.y);
        float d_15;
        float amount_1;
        float lobe_1;
        float3  x_26;
        bool _S307 = convHeroSmooth_0(c_43, p_6, 1.0f, &d_15, &x_26, &amount_1, &lobe_1);
        if(_S307)
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
            bool _S308;
            if(!nearGroup_0)
            {
                _S308 = true;
            }
            else
            {
                _S308 = k_9 >= (c_43->cvTurretCount_0);
            }
            if(_S308)
            {
                break;
            }
            float4  _S309 = convTurret_0(c_43, k_9);
            float kt_0;
            bool _S310 = convTurretSmooth_0(c_43, _S309, p_6, 1.0f, &d_15, &x_26, &kt_0);
            if(_S310)
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
        float m_5;
        if(moated_0)
        {
            float _S311 = convMoat_0(c_44, xz_3, &gMoat_0, &capMoat_0);
            m_5 = _S311;
        }
        else
        {
            m_5 = 1.0f;
        }
        if(m_5 > 0.0f)
        {
            float2  slope_5;
            float _S312 = convUpdraftGrad_0(c_44, xz_3 - c_44->cvDrift_0, &slope_5);
            float _S313 = convSlopeCap_0(c_44);
            float cap_4;
            if(moated_0)
            {
                slope_5 = slope_5 * make_float2 (m_5) + gMoat_0 * make_float2 (_S312);
                float cap_5 = _S313 + capMoat_0;
                best_2 = _S312 * m_5;
                cap_4 = cap_5;
            }
            else
            {
                best_2 = _S312;
                cap_4 = _S313;
            }
            float _S314 = convFieldBaseInside_0(c_44, best_2, slope_5, cap_4);
            best_2 = _S314;
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
    float _S315 = convGroupBaseInside_0(c_44, xz_3, nearGroup_1);
    return (F32_max((best_2), (_S315)));
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
    float _S316 = convPouches_0(c_46, xz_4 - c_46->cvDrift_0);
    if((c_46->cvMammaDepth_0 * _S316) <= below_0)
    {
        return 0.0f;
    }
    float _S317 = convBaseInside_0(c_46, xz_4, nearGroup_2);
    float _S318 = convMammaSagOf_0(c_46, _S316, _S317);
    return _S318;
}

static __device__ float3  convTwist_0(float3  x_27)
{
    float _S319 = x_27.x;
    float _S320 = x_27.y;
    float _S321 = x_27.z;
    return make_float3 (0.0f * _S319 + 0.80000001192092896f * _S320 + 0.60000002384185791f * _S321, -0.80000001192092896f * _S319 + 0.36000001430511475f * _S320 - 0.47999998927116394f * _S321, -0.60000002384185791f * _S319 - 0.47999998927116394f * _S320 + 0.63999998569488525f * _S321);
}

static __device__ float convPuffs_0(float3  x_28)
{
    float3  fl_0 = floor_0(x_28);
    int3  _S322 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_2 = x_28 - fl_0;
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
    int3  _S323 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S323 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S324 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_16 = _S324 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S322 + off_0) - f_2;
                float _S325 = (F32_min((nearest_1), (dot_1(d_16, d_16))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S325;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_47, float3  p_7, float scale_0)
{
    float3  _S326 = make_float3 (p_7.x, p_7.y - c_47->cvRise_0, p_7.z) / make_float3 (scale_0);
    int i_18 = int(0);
    float3  x_29 = _S326;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_18 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_18 >= (c_47->cvOctaves_0))
        {
            break;
        }
        float3  x_30 = convTwist_0(x_29);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_30);
        float norm_3 = norm_2 + amp_2;
        float3  x_31 = x_30 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_18 = i_18 + int(1);
        x_29 = x_31;
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

static __device__ float convInside_0(ConvectionInput_0 * c_48, float d_17, float lift_2, float3  x_32, float scale_1)
{
    float _S327 = d_17 + lift_2;
    if(_S327 <= 0.0f)
    {
        return _S327;
    }
    if((d_17 - lift_2) >= 12.0f)
    {
        return 12.0f;
    }
    float _S328 = convBillow_0(c_48, x_32, scale_1);
    return d_17 + lift_2 * _S328;
}

static __device__ float convCapGrain_0(ConvectionInput_0 * c_49, float2  rel_4, float scale_2)
{
    return saturate_0(0.80000001192092896f + 0.13330000638961792f * gradientNoise_0(make_float3 (rel_4.x / scale_2 + c_49->cvHeroSeed_0.x * 0.00100000004749745f, 0.37000000476837158f, rel_4.y / scale_2 + c_49->cvHeroSeed_0.z * 0.00100000004749745f)));
}

static __device__ float convCapDensity_0(ConvectionInput_0 * c_50, float3  p_8, float above_9)
{
    float2  rel_5 = float2 {p_8.x, p_8.z} - c_50->cvHeroAt_0;
    float r2_3 = dot_0(rel_5, rel_5);
    float _S329 = c_50->cvHeroRadius_0;
    float _S330 = c_50->cvPileusThick_0;
    float best_3;
    if((c_50->cvPileusThick_0) > 0.0f)
    {
        float rp_1 = 0.60000002384185791f * _S329;
        float _S331 = rp_1 * rp_1;
        if(r2_3 < _S331)
        {
            float lens_0 = 1.0f - r2_3 / _S331;
            float _S332 = c_50->cvPileusGap_0;
            float _S333 = convHeroHeight_0(c_50, (F32_sqrt((r2_3))) * 0.60000002384185791f);
            float most_0 = 0.5f * _S330 * lens_0;
            float _S334 = (F32_abs((above_9 - (_S332 + _S333))));
            if(_S334 < most_0)
            {
                float _S335 = convCapGrain_0(c_50, rel_5, 900.0f);
                float s_10 = most_0 * _S335 - _S334;
                if(s_10 > 0.0f)
                {
                    best_3 = (F32_max((0.0f), (0.44999998807907104f * smoothstep_0(0.0f, 15.0f, s_10))));
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
    float _S336 = c_50->cvVelumThick_0;
    if((c_50->cvVelumThick_0) > 0.0f)
    {
        float ext_1 = 1.89999997615814209f * _S329;
        if(r2_3 < (ext_1 * ext_1))
        {
            float r_10 = (F32_sqrt((r2_3)));
            float2  dir_0;
            if(r_10 > 0.00100000004749745f)
            {
                dir_0 = rel_5 / make_float2 (r_10);
            }
            else
            {
                dir_0 = make_float2 (1.0f, 0.0f);
            }
            float edge_1 = _S329 + (ext_1 - _S329) * saturate_0(0.875f + 0.08330000191926956f * gradientNoise_0(make_float3 (1.70000004768371582f * dir_0.x + c_50->cvHeroSeed_0.x * 0.00100000004749745f, 2.29999995231628418f, 1.70000004768371582f * dir_0.y + c_50->cvHeroSeed_0.z * 0.00100000004749745f)));
            float _S337 = 0.5f * _S336;
            float most_1 = _S337 * (1.0f - smoothstep_0(_S329 + 0.40000000596046448f * (edge_1 - _S329), edge_1, r_10));
            float _S338 = (F32_abs((above_9 - (c_50->cvVelumHeight_0 + _S337 * (1.0f - smoothstep_0(_S329, 2.0f * _S329, r_10))))));
            if(_S338 < most_1)
            {
                float _S339 = convCapGrain_0(c_50, rel_5, 2500.0f);
                float s_11 = most_1 * _S339 - _S338;
                if(s_11 > 0.0f)
                {
                    best_3 = (F32_max((best_3), (0.2199999988079071f * smoothstep_0(0.0f, 15.0f, s_11))));
                }
            }
        }
    }
    return c_50->cvSigma_0 * best_3;
}

static __device__ void convGroupFold_0(float d_18, float3  x_33, float lift_3, float lobe_2, float * gMax_0, float * gSum_0, float3  * gX_0, float * gLift_0, float * gLobe_0)
{
    if(d_18 > (*gMax_0))
    {
        float scale_3 = (F32_exp(((*gMax_0 - d_18) / 50.0f)));
        *gSum_0 = *gSum_0 * scale_3;
        *gX_0 = *gX_0 * make_float3 (scale_3);
        *gLift_0 = *gLift_0 * scale_3;
        *gLobe_0 = *gLobe_0 * scale_3;
        *gMax_0 = d_18;
    }
    float wt_0 = (F32_exp(((d_18 - *gMax_0) / 50.0f)));
    *gSum_0 = *gSum_0 + wt_0;
    *gX_0 = *gX_0 + make_float3 (wt_0) * x_33;
    *gLift_0 = *gLift_0 + wt_0 * lift_3;
    *gLobe_0 = *gLobe_0 + wt_0 * lobe_2;
    return;
}

static __device__ float convGroupInside_0(ConvectionInput_0 * c_51, float3  p_9, float above_10, bool nearGroup_3)
{
    bool _S340;
    float gMax_1 = -1.00000001504746622e+30f;
    float gSum_1 = 0.0f;
    float gLift_1 = 0.0f;
    float gLobe_1 = 0.0f;
    float3  gX_1 = make_float3 (0.0f, 0.0f, 0.0f);
    float d_19;
    float amount_2;
    float lobe_3;
    float3  x_34;
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
            _S340 = true;
        }
        else
        {
            _S340 = k_10 >= (c_51->cvTurretCount_0);
        }
        if(_S340)
        {
            break;
        }
        float4  _S341 = convTurret_0(c_51, k_10);
        float kt_1;
        bool _S342 = convTurretSmooth_0(c_51, _S341, p_9, above_10, &d_19, &x_34, &kt_1);
        if(_S342)
        {
            float _S343 = convLift_0(c_51, above_10, kt_1);
            convGroupFold_0(d_19, x_34, _S343, kt_1, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
            anyTurret_0 = true;
        }
        k_10 = k_10 + int(1);
    }
    bool _S344 = convHeroSmooth_0(c_51, p_9, above_10, &d_19, &x_34, &amount_2, &lobe_3);
    float heroLift_0;
    if(_S344)
    {
        float _S345 = convLift_0(c_51, above_10, amount_2);
        heroLift_0 = _S345;
    }
    else
    {
        heroLift_0 = 0.0f;
    }
    if(!_S344)
    {
        _S340 = !anyTurret_0;
    }
    else
    {
        _S340 = false;
    }
    if(_S340)
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
        at_2 = x_34;
        lobeAt_0 = lobe_3;
    }
    else
    {
        if(_S344)
        {
            convGroupFold_0(d_19, x_34, heroLift_0, lobe_3, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
        }
        float3  _S346 = gX_1 / make_float3 (gSum_1);
        float _S347 = gLobe_1 / gSum_1;
        lift_4 = gLift_1 / gSum_1;
        at_2 = _S346;
        lobeAt_0 = _S347;
    }
    float _S348 = convInside_0(c_51, gMax_1, lift_4, at_2 + c_51->cvHeroSeed_0, c_51->cvBillowScale_0 * lobeAt_0);
    return _S348;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_52, float3  p_10, float above_11)
{
    float d_20;
    float amount_3;
    float lobe_4;
    float3  x_35;
    bool _S349 = convHeroSmooth_0(c_52, p_10, above_11, &d_20, &x_35, &amount_3, &lobe_4);
    if(!_S349)
    {
        return -1.00000001504746622e+30f;
    }
    float _S350 = convLift_0(c_52, above_11, amount_3);
    float _S351 = convInside_0(c_52, d_20, _S350, x_35 + c_52->cvHeroSeed_0, c_52->cvBillowScale_0 * lobe_4);
    return _S351;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_53, float3  p_11)
{
    float _S352 = p_11.y;
    float above_12 = _S352 - c_53->cvBase_0;
    float _S353 = c_53->cvMammaDepth_0;
    bool rampBand_0;
    if(above_12 < (- c_53->cvMammaDepth_0))
    {
        rampBand_0 = true;
    }
    else
    {
        float _S354 = convCeiling_0(c_53);
        rampBand_0 = above_12 > _S354;
    }
    if(rampBand_0)
    {
        return 0.0f;
    }
    float2  _S355 = float2 {p_11.x, p_11.z};
    float2  fromHero_0 = _S355 - c_53->cvHeroAt_0;
    bool nearGroup_4 = (dot_0(fromHero_0, fromHero_0)) < (c_53->cvGroupReach_0 * c_53->cvGroupReach_0);
    bool _S356 = _S353 > 0.0f;
    if(_S356)
    {
        rampBand_0 = above_12 < 0.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    if(rampBand_0)
    {
        float _S357 = convMammaSag_0(c_53, _S355, nearGroup_4, - above_12);
        float hang_0 = _S357 + above_12;
        if(hang_0 <= 0.0f)
        {
            return 0.0f;
        }
        return c_53->cvSigma_0 * (F32_sqrt((saturate_0(hang_0 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, hang_0);
    }
    float _S358 = convLift_0(c_53, above_12, 1.0f - 0.60000002384185791f * c_53->cvLacunarity_0);
    if(_S356)
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
        float2  _S359 = make_float2 (0.0f, 0.0f);
        float2  gMoat_1 = _S359;
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
            float _S360 = convMoat_0(c_53, _S355, &gMoat_1, &capMoat_1);
            capDensity_0 = _S360;
        }
        else
        {
            capDensity_0 = 1.0f;
        }
        if(capDensity_0 > 0.0f)
        {
            float2  q_11 = _S355 - c_53->cvDrift_0;
            float2  slope_6;
            float _S361 = convUpdraftGrad_0(c_53, q_11, &slope_6);
            float _S362 = convSlopeCap_0(c_53);
            float cap_6;
            if(moated_1)
            {
                slope_6 = slope_6 * make_float2 (capDensity_0) + gMoat_1 * make_float2 (_S361);
                float cap_7 = _S362 + capMoat_1;
                sag_0 = _S361 * capDensity_0;
                cap_6 = cap_7;
            }
            else
            {
                sag_0 = _S361;
                cap_6 = _S362;
            }
            if(rampBand_0)
            {
                float _S363 = convFieldBaseInside_0(c_53, sag_0, slope_6, cap_6);
                baseField_0 = _S363;
            }
            else
            {
                baseField_0 = -1.00000001504746622e+30f;
            }
            float _S364 = convTowerHeight_0(c_53, sag_0);
            float v_5 = _S364 - above_12;
            float _S365 = convNeededUpdraft_0(c_53, above_12);
            float delta_1 = sag_0 - _S365;
            float d_21 = convSurfaceDistance_0(v_5, delta_1, (F32_min((length_0(slope_6)), (cap_6))));
            if((d_21 + _S358) > 0.0f)
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
                    shiftAcross_0 = _S359;
                }
                float _S366 = convInside_0(c_53, d_21, _S358, make_float3 (q_11.x + shiftAcross_0.x, _S352 + inside_3, q_11.y + shiftAcross_0.y), c_53->cvBillowScale_0);
                inside_3 = _S366;
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
    bool _S367 = (c_53->cvHeroTop_0) > 0.0f;
    if(_S367)
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
        float _S368 = convCapDensity_0(c_53, p_11, above_12);
        capDensity_0 = _S368;
    }
    else
    {
        capDensity_0 = 0.0f;
    }
    if(_S367)
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
            float _S369 = convGroupInside_0(c_53, p_11, above_12, nearGroup_4);
            inside_3 = (F32_max((inside_3), (_S369)));
        }
        else
        {
            float _S370 = convHeroInside_0(c_53, p_11, above_12);
            inside_3 = (F32_max((inside_3), (_S370)));
        }
    }
    if(inside_3 <= 0.0f)
    {
        return capDensity_0;
    }
    if(rampBand_0)
    {
        float _S371 = convPouches_0(c_53, _S355 - c_53->cvDrift_0);
        if(_S371 > 0.0f)
        {
            float _S372 = convGroupBaseInside_0(c_53, _S355, nearGroup_4);
            float _S373 = convMammaSagOf_0(c_53, _S371, (F32_max((baseField_0), (_S372))));
            sag_0 = _S373;
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

static __device__ float densityAt_0(Medium_0 * m_6, StructuredBuffer<float2 > disp_6, float3  p_12)
{
    float _S374 = p_12.y;
    bool _S375;
    if(_S374 < (m_6->slabBottom_0))
    {
        _S375 = true;
    }
    else
    {
        _S375 = _S374 > (m_6->slabTop_0);
    }
    if(_S375)
    {
        return 0.0f;
    }
    if((m_6->clipOn_0) != int(0))
    {
        float2  _S376 = float2 {p_12.x, p_12.z};
        if(any_0(_S376 < (m_6->clipLo_0)))
        {
            _S375 = true;
        }
        else
        {
            _S375 = any_0(_S376 > (m_6->clipHi_0));
        }
    }
    else
    {
        _S375 = false;
    }
    if(_S375)
    {
        return 0.0f;
    }
    float _S377 = m_6->fadeRadius_0;
    float fade_0;
    if((m_6->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S377 - length_0(float2 {p_12.x, p_12.z} - m_6->fadeAt_0)) / (F32_max((m_6->fadeWidth_0), (1.0f))));
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
    int _S378 = m_6->mode_0;
    if((m_6->mode_0) == int(0))
    {
        return m_6->density_0 * fade_0;
    }
    if(_S378 == int(2))
    {
        float _S379 = iceDensity_0(&m_6->gen_0, disp_6, p_12);
        return _S379 * fade_0;
    }
    if(_S378 == int(3))
    {
        float _S380 = convectionDensity_0(&m_6->conv_0, p_12);
        return _S380 * fade_0;
    }
    float3  d_22 = (p_12 - m_6->coreCentre_0) / make_float3 ((F32_max((m_6->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_6->density_0 + m_6->coreDensity_0 * (F32_exp((- dot_1(d_22, d_22))))) * fade_0;
}

static __device__ float transmittanceUpTo_0(Medium_0 * m_7, MajorantGrid_0 * g_12, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_7, Rng_0 * rng_0, float3  p_13, float3  dir_1, float tMax_1, int * steps_0)
{
    float t0_2;
    float t1_2;
    bool _S381 = slabRange_0(m_7, p_13, dir_1, &t0_2, &t1_2);
    if(!_S381)
    {
        return 1.0f;
    }
    float _S382 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S382;
    t1_2 = (F32_min((t1_2), (tMax_1)));
    Dda_0 _S383 = ddaInit_0(g_12, p_13, dir_1, _S382);
    Dda_0 dda_0 = _S383;
    float _S384 = m_7->majorant_0;
    float _S385 = gridBound_0(m_7, g_12, bounds_1, disp_7, (&dda_0)->cell_0, m_7->majorant_0);
    float localMaj_0 = _S385;
    int i_19 = int(0);
    float t_9 = _S382;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_19 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S386 = dda_0;
        float _S387 = ddaExit_0(&_S386);
        float _S388 = (F32_min((_S387), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S388 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S389 = gridBound_0(m_7, g_12, bounds_1, disp_7, (&dda_0)->cell_0, _S384);
            localMaj_0 = _S389;
            t_9 = _S388;
            i_19 = i_19 + int(1);
            continue;
        }
        float _S390 = randFloat_0(rng_0);
        float t_10 = t_9 - (F32_log(((F32_max((1.0f - _S390), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_10 >= _S388)
        {
            if(_S388 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S391 = gridBound_0(m_7, g_12, bounds_1, disp_7, (&dda_0)->cell_0, _S384);
            localMaj_0 = _S391;
            t_9 = _S388;
            i_19 = i_19 + int(1);
            continue;
        }
        float _S392 = densityAt_0(m_7, disp_7, p_13 + dir_1 * make_float3 (t_10));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S392 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S393 = randFloat_0(rng_0);
            if(_S393 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_9 = t_10;
        tr_0 = tr_2;
        i_19 = i_19 + int(1);
    }
    return tr_0;
}

static __device__ float transmittance_0(Medium_0 * m_8, MajorantGrid_0 * g_13, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > disp_8, Rng_0 * rng_1, float3  p_14, float3  dir_2, int * steps_1)
{
    float _S394 = transmittanceUpTo_0(m_8, g_13, bounds_2, disp_8, rng_1, p_14, dir_2, 1.00000001504746622e+30f, steps_1);
    return _S394;
}

extern "C" __global__ void transmittanceTrial(Medium_0 medium_0, MajorantGrid_0 grid_0, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > drift_0, float3  origin_1, float3  direction_0, RWStructuredBuffer<float> output_0, RWStructuredBuffer<int> outSteps_0, uint seed_1, int count_0)
{
    int i_20 = int((blockIdx * blockDim + threadIdx).x);
    if(i_20 >= count_0)
    {
        return;
    }
    uint s_12 = uint(i_20) * 747796405U + 2891336453U;
    uint s_13 = ((s_12 >> ((s_12 >> 28U) + 4U)) ^ s_12) * 277803737U;
    Rng_0 rng_2 = makeRng_0(((s_13 >> 22U) ^ s_13) ^ seed_1);
    int steps_2 = int(0);
    float * _S395 = (&(output_0)[i_20]);
    Medium_0 _S396 = medium_0;
    MajorantGrid_0 _S397 = grid_0;
    float _S398 = transmittance_0(&_S396, &_S397, bounds_3, drift_0, &rng_2, origin_1, direction_0, &steps_2);
    *_S395 = _S398;
    *(&(outSteps_0)[i_20]) = steps_2;
    return;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_9, MajorantGrid_0 * g_14, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > disp_9, Rng_0 * rng_3, float3  ro_2, float3  rd_2, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_3)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S399 = slabRange_0(m_9, ro_2, rd_2, &t0_3, &t1_3);
    if(!_S399)
    {
        return false;
    }
    float _S400 = (F32_min((t1_3), (tLimit_0)));
    t1_3 = _S400;
    if(!(_S400 > t0_3))
    {
        return false;
    }
    float _S401 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S402 = ddaInit_0(g_14, ro_2, rd_2, _S401);
    Dda_0 dda_1 = _S402;
    float _S403 = m_9->majorant_0;
    float _S404 = gridBound_0(m_9, g_14, bounds_4, disp_9, (&dda_1)->cell_0, m_9->majorant_0);
    float localMaj_1 = _S404;
    int i_21 = int(0);
    float t_11 = _S401;
    for(;;)
    {
        if(i_21 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_3 = *steps_3 + int(1);
        Dda_0 _S405 = dda_1;
        float _S406 = ddaExit_0(&_S405);
        float _S407 = (F32_min((_S406), (t1_3)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S407 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S408 = gridBound_0(m_9, g_14, bounds_4, disp_9, (&dda_1)->cell_0, _S403);
            localMaj_1 = _S408;
            t_11 = _S407;
            i_21 = i_21 + int(1);
            continue;
        }
        float _S409 = randFloat_0(rng_3);
        float t_12 = t_11 - (F32_log(((F32_max((1.0f - _S409), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_12 >= _S407)
        {
            if(_S407 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S410 = gridBound_0(m_9, g_14, bounds_4, disp_9, (&dda_1)->cell_0, _S403);
            localMaj_1 = _S410;
            t_11 = _S407;
            i_21 = i_21 + int(1);
            continue;
        }
        float3  p_15 = ro_2 + rd_2 * make_float3 (t_12);
        float _S411 = randFloat_0(rng_3);
        float _S412 = densityAt_0(m_9, disp_9, p_15);
        if(_S411 < (_S412 / localMaj_1))
        {
            *scatterPoint_0 = p_15;
            *distance_0 = t_12;
            return true;
        }
        t_11 = t_12;
        i_21 = i_21 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_10, MajorantGrid_0 * g_15, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > disp_10, Rng_0 * rng_4, float3  ro_3, float3  rd_3, float3  * scatterPoint_1, float * distance_1, int * steps_4)
{
    bool _S413 = sampleFreeFlightUpTo_0(m_10, g_15, bounds_5, disp_10, rng_4, ro_3, rd_3, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_4);
    return _S413;
}

extern "C" __global__ void freeFlightTrial(Medium_0 medium_1, MajorantGrid_0 grid_1, StructuredBuffer<float> bounds_6, StructuredBuffer<float2 > drift_1, float3  origin_2, float3  direction_1, RWStructuredBuffer<float> outDistance_0, RWStructuredBuffer<int> outSteps_1, uint seed_2, int count_1)
{
    int i_22 = int((blockIdx * blockDim + threadIdx).x);
    if(i_22 >= count_1)
    {
        return;
    }
    uint s_14 = uint(i_22) * 747796405U + 2891336453U;
    uint s_15 = ((s_14 >> ((s_14 >> 28U) + 4U)) ^ s_14) * 277803737U;
    Rng_0 rng_5 = makeRng_0(((s_15 >> 22U) ^ s_15) ^ seed_2);
    int steps_5 = int(0);
    float * _S414 = (&(outDistance_0)[i_22]);
    Medium_0 _S415 = medium_1;
    MajorantGrid_0 _S416 = grid_1;
    float3  hit_0;
    float dist_1;
    bool _S417 = sampleFreeFlight_0(&_S415, &_S416, bounds_6, drift_1, &rng_5, origin_2, direction_1, &hit_0, &dist_1, &steps_5);
    float _S418;
    if(_S417)
    {
        _S418 = dist_1;
    }
    else
    {
        _S418 = -1.0f;
    }
    *_S414 = _S418;
    *(&(outSteps_1)[i_22]) = steps_5;
    return;
}

static __device__ float2  firstScatterMoments_0(Medium_0 * m_11, MajorantGrid_0 * g_16, StructuredBuffer<float> bounds_7, StructuredBuffer<float2 > disp_11, float3  ro_4, float3  rd_4, float tMax_2)
{
    float t0_4;
    float t1_4;
    bool _S419 = slabRange_0(m_11, ro_4, rd_4, &t0_4, &t1_4);
    if(!_S419)
    {
        return make_float2 (0.0f, 0.0f);
    }
    float _S420 = (F32_min((t1_4), (tMax_2)));
    t1_4 = _S420;
    float _S421 = (F32_max((t0_4), (0.0f)));
    if(!(_S420 > _S421))
    {
        return make_float2 (0.0f, 0.0f);
    }
    Dda_0 _S422 = ddaInit_0(g_16, ro_4, rd_4, _S421);
    Dda_0 dda_2 = _S422;
    float _S423 = m_11->majorant_0;
    float _S424 = gridBound_0(m_11, g_16, bounds_7, disp_11, (&dda_2)->cell_0, m_11->majorant_0);
    float localMaj_2 = _S424;
    int i_23 = int(0);
    float t_13 = _S421;
    float tr_3 = 1.0f;
    float sumP_0 = 0.0f;
    float sumT_0 = 0.0f;
    for(;;)
    {
        if(i_23 < int(4096))
        {
        }
        else
        {
            break;
        }
        Dda_0 _S425 = dda_2;
        float _S426 = ddaExit_0(&_S425);
        float _S427 = (F32_min((_S426), (t1_4)));
        bool _S428;
        if(localMaj_2 > 0.0f)
        {
            _S428 = _S427 > t_13;
        }
        else
        {
            _S428 = false;
        }
        float tr_4;
        float sumP_1;
        float sumT_1;
        if(_S428)
        {
            float _S429 = (F32_min((0.25f / localMaj_2), (_S427 - t_13)));
            float tm_0 = t_13 + 0.5f * _S429;
            float _S430 = densityAt_0(m_11, disp_11, ro_4 + rd_4 * make_float3 (tm_0));
            float a_5 = 1.0f - (F32_exp((- _S430 * _S429)));
            float _S431 = tr_3 * a_5;
            float sumP_2 = sumP_0 + _S431;
            float sumT_2 = sumT_0 + _S431 * tm_0;
            float tr_5 = tr_3 * (1.0f - a_5);
            if(tr_5 < 0.00499999988824129f)
            {
                sumT_0 = sumT_2;
                sumP_0 = sumP_2;
                break;
            }
            float t_14 = t_13 + _S429;
            if(t_14 < _S427)
            {
                t_13 = t_14;
                tr_3 = tr_5;
                sumP_0 = sumP_2;
                sumT_0 = sumT_2;
                i_23 = i_23 + int(1);
                continue;
            }
            tr_4 = tr_5;
            sumP_1 = sumP_2;
            sumT_1 = sumT_2;
        }
        else
        {
            tr_4 = tr_3;
            sumP_1 = sumP_0;
            sumT_1 = sumT_0;
        }
        if(_S427 >= t1_4)
        {
            sumT_0 = sumT_1;
            sumP_0 = sumP_1;
            break;
        }
        ddaAdvance_0(&dda_2);
        float _S432 = gridBound_0(m_11, g_16, bounds_7, disp_11, (&dda_2)->cell_0, _S423);
        localMaj_2 = _S432;
        t_13 = _S427;
        tr_3 = tr_4;
        sumP_0 = sumP_1;
        sumT_0 = sumT_1;
        i_23 = i_23 + int(1);
    }
    return make_float2 (sumT_0, sumP_0);
}

extern "C" __global__ void firstScatterTrial(Medium_0 medium_2, MajorantGrid_0 grid_2, StructuredBuffer<float> bounds_8, StructuredBuffer<float2 > drift_2, float3  origin_3, float3  direction_2, float tMax_3, RWStructuredBuffer<float2 > output_1, int count_2)
{
    int i_24 = int((blockIdx * blockDim + threadIdx).x);
    if(i_24 >= count_2)
    {
        return;
    }
    float2  * _S433 = (&(output_1)[i_24]);
    Medium_0 _S434 = medium_2;
    MajorantGrid_0 _S435 = grid_2;
    float2  _S436 = firstScatterMoments_0(&_S434, &_S435, bounds_8, drift_2, origin_3, direction_2, tMax_3);
    *_S433 = _S436;
    return;
}

extern "C" __global__ void rngTrial(RWStructuredBuffer<float> output_2, uint seed_3, int count_3)
{
    int i_25 = int((blockIdx * blockDim + threadIdx).x);
    if(i_25 >= count_3)
    {
        return;
    }
    Rng_0 rng_6 = makeRng_0(seed_3 + uint(i_25));
    float * _S437 = (&(output_2)[i_25]);
    float _S438 = randFloat_0(&rng_6);
    *_S437 = _S438;
    return;
}

extern "C" __global__ void buildIceGrid(Medium_0 medium_3, StructuredBuffer<float2 > drift_3, MajorantGrid_0 grid_3, RWStructuredBuffer<float> outBounds_0, int cellCount_0)
{
    int i_26 = int((blockIdx * blockDim + threadIdx).x);
    if(i_26 >= cellCount_0)
    {
        return;
    }
    int _S439 = grid_3.dims_0.x;
    int cx_0 = i_26 % _S439;
    int _S440 = i_26 / _S439;
    int _S441 = grid_3.dims_0.y;
    int cy_0 = _S440 % _S441;
    int cz_0 = i_26 / (_S439 * _S441);
    float3  lo_11 = grid_3.origin_0 + make_float3 (float(cx_0), float(cy_0), float(cz_0)) * grid_3.cellExtent_0;
    float * _S442 = (&(outBounds_0)[i_26]);
    float3  _S443 = lo_11 + grid_3.cellExtent_0;
    GeneratorInput_0 _S444 = medium_3.gen_0;
    float _S445 = iceDensityBound_0(&_S444, drift_3, lo_11, _S443);
    *_S442 = _S445;
    return;
}

