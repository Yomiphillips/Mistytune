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

static __device__ float3  lerp_2(float3  x_10, float3  y_4, float3  s_6)
{
    return x_10 + (y_4 - x_10) * s_6;
}

static __device__ int2  min_0(int2  x_11, int2  y_5)
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
        *_slang_vector_get_element_ptr(&result_3, i_6) = (I32_min((_slang_vector_get_element(x_11, i_6)), (_slang_vector_get_element(y_5, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_3;
}

static __device__ float2  max_0(float2  x_12, float2  y_6)
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
        *_slang_vector_get_element_ptr(&result_4, i_7) = (F32_max((_slang_vector_get_element(x_12, i_7)), (_slang_vector_get_element(y_6, i_7))));
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static __device__ float2  min_1(float2  x_13, float2  y_7)
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
        *_slang_vector_get_element_ptr(&result_5, i_8) = (F32_min((_slang_vector_get_element(x_13, i_8)), (_slang_vector_get_element(y_7, i_8))));
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static __device__ float2  clamp_2(float2  x_14, float2  minBound_2, float2  maxBound_2)
{
    return min_1(max_0(x_14, minBound_2), maxBound_2);
}

static __device__ float length_0(float2  x_15)
{
    return (F32_sqrt((dot_0(x_15, x_15))));
}

static __device__ float2  abs_0(float2  x_16)
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
        *_slang_vector_get_element_ptr(&result_6, i_9) = (F32_abs((_slang_vector_get_element(x_16, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static __device__ bool all_0(bool2  x_17)
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
            result_7 = (bool((_slang_vector_get_element(x_17, i_10))));
        }
        else
        {
            result_7 = false;
        }
        i_10 = i_10 + int(1);
    }
    return result_7;
}

static __device__ float smoothstep_0(float min_2, float max_1, float x_18)
{
    float _S72 = saturate_0((x_18 - min_2) / (max_1 - min_2));
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
    float field_1 = lerp_0((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_15->cvPolarity_0);
    float _S136 = c_15->cvLacunarity_0;
    float field_2;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_0(field_1, 0.40000000596046448f, _S136);
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
    return length_0(make_float2 (c_22->cvShapeHalfWidth_0 + lift_0, c_22->cvShapeRound_0 + lift_0));
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

static __device__ float3  convShapeTexel_0(ConvectionInput_0 * c_25, int i_12, int j_8)
{
    int k_4 = (j_8 * c_25->cvShapeDim_0.x + i_12) * int(4);
    StructuredBuffer<float> _S150 = c_25->cvShapeMap_0;
    float _S151 = __ldg((&(c_25->cvShapeMap_0)[k_4]));
    float _S152 = __ldg((&(_S150)[k_4 + int(1)]));
    float _S153 = __ldg((&(_S150)[k_4 + int(2)]));
    return make_float3 (_S151, _S152, _S153);
}

static __device__ float convShapeDistance_0(ConvectionInput_0 * c_26, float u_3, float y_8, float2  * slopeUY_0)
{
    float _S154 = c_26->cvShapeTexel_0;
    float2  st_0 = make_float2 (u_3, y_8) / make_float2 (c_26->cvShapeTexel_0) + c_26->cvShapeOffset_0 - make_float2 (0.5f);
    int2  _S155 = make_int2 (int(1), int(1));
    int2  last_0 = c_26->cvShapeDim_0 - _S155;
    float2  _S156 = make_float2 ((float)last_0.x, (float)last_0.y);
    float2  q_6 = clamp_2(st_0, make_float2 (0.0f, 0.0f), _S156);
    float past_0 = length_0(st_0 - q_6);
    float2  f0_0 = floor_1(q_6);
    int2  _S157 = make_int2 ((int)f0_0.x, (int)f0_0.y);
    int2  i0_1 = min_0(_S157, last_0);
    int2  i1_0 = min_0(i0_1 + _S155, last_0);
    float2  fr_0 = q_6 - f0_0;
    int _S158 = i0_1.x;
    int _S159 = i0_1.y;
    float3  _S160 = convShapeTexel_0(c_26, _S158, _S159);
    int _S161 = i1_0.x;
    float3  _S162 = convShapeTexel_0(c_26, _S161, _S159);
    int _S163 = i1_0.y;
    float3  _S164 = convShapeTexel_0(c_26, _S158, _S163);
    float3  _S165 = convShapeTexel_0(c_26, _S161, _S163);
    float3  _S166 = make_float3 (fr_0.x);
    float3  blend_0 = lerp_2(lerp_2(_S160, _S162, _S166), lerp_2(_S164, _S165, _S166), make_float3 (fr_0.y));
    *slopeUY_0 = float2 {blend_0.y, blend_0.z};
    return (blend_0.x - past_0) * _S154;
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
    float2  _S167;
    if(len_0 > 9.99999997475242708e-07f)
    {
        _S167 = w_2 * make_float2 (- gap_1 / len_0);
    }
    else
    {
        _S167 = make_float2 (0.0f, rimR_0);
    }
    *stepDM_0 = _S167;
    return gap_1;
}

static __device__ float convShapeBound_0(ConvectionInput_0 * c_27, float3  lo_4, float3  hi_4, float low_1, float high_1)
{
    float2  ea_0 = float2 {lo_4.x, lo_4.z} - c_27->cvHeroAt_0;
    float2  eb_0 = float2 {hi_4.x, hi_4.z} - c_27->cvHeroAt_0;
    float _S168 = c_27->cvShapeAxisU_0.y;
    float _S169 = - _S168;
    float _S170 = c_27->cvShapeAxisU_0.x;
    float _S171 = ea_0.x;
    float _S172 = _S171 * _S170;
    float _S173 = eb_0.x;
    float _S174 = _S173 * _S170;
    float _S175 = ea_0.y;
    float _S176 = _S175 * _S168;
    float _S177 = eb_0.y;
    float _S178 = _S177 * _S168;
    float uLo_0 = (F32_min((_S172), (_S174))) + (F32_min((_S176), (_S178)));
    float uHi_0 = (F32_max((_S172), (_S174))) + (F32_max((_S176), (_S178)));
    float _S179 = _S171 * _S169;
    float _S180 = _S173 * _S169;
    float _S181 = _S175 * _S170;
    float _S182 = _S177 * _S170;
    float nLo_0 = (F32_min((_S179), (_S180))) + (F32_min((_S181), (_S182)));
    float nHi_0 = (F32_max((_S179), (_S180))) + (F32_max((_S181), (_S182)));
    bool _S183;
    if(nLo_0 <= 0.0f)
    {
        _S183 = nHi_0 >= 0.0f;
    }
    else
    {
        _S183 = false;
    }
    float mMin_0;
    if(_S183)
    {
        mMin_0 = 0.0f;
    }
    else
    {
        mMin_0 = (F32_min(((F32_abs((nLo_0)))), ((F32_abs((nHi_0))))));
    }
    float2  halfSpan_0 = make_float2 (0.5f * (uHi_0 - uLo_0), 0.5f * (high_1 - low_1));
    float2  slopeUnused_0;
    float _S184 = convShapeDistance_0(c_27, 0.5f * (uLo_0 + uHi_0), 0.5f * (low_1 + high_1), &slopeUnused_0);
    float2  stepUnused_0;
    return - convShapeProfile_0(_S184 + 2.5f * length_0(halfSpan_0), mMin_0, c_27->cvShapeRound_0, &stepUnused_0);
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
    float2  _S185 = float2 {t_6.x, t_6.y};
    float2  nearGap_2 = max_0(max_0(float2 {lo_5.x, lo_5.z} - _S185, _S185 - float2 {hi_5.x, hi_5.z}), make_float2 (0.0f, 0.0f));
    float gap2_1 = dot_0(nearGap_2, nearGap_2);
    float _S186 = convTurretReach_0(c_30, t_6);
    if(gap2_1 >= (_S186 * _S186))
    {
        return false;
    }
    float rMin_0 = (F32_sqrt((gap2_1)));
    float _S187 = t_6.w;
    float _S188 = t_6.z;
    float tower_0 = convDomeHeight_0(_S187, _S188, c_30->cvShape_0, rMin_0);
    float ra_0 = convDomeRadiusAt_0(_S187, _S188, c_30->cvShape_0, low_2);
    float _S189 = convTurretBillow_0(c_30, _S188);
    float _S190 = convLift_0(c_30, high_2, _S189);
    *lift_1 = _S190;
    bool _S191 = ra_0 < 0.0f;
    bool _S192;
    if(_S191)
    {
        _S192 = true;
    }
    else
    {
        _S192 = rMin_0 >= ra_0;
    }
    if(_S192)
    {
        float hMin_1;
        if(_S191)
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
    float _S193 = convCeiling_0(c_31);
    float _S194 = c_31->cvMammaDepth_0;
    bool pouches_0;
    if(high_3 < (- c_31->cvMammaDepth_0))
    {
        pouches_0 = true;
    }
    else
    {
        pouches_0 = low_3 > _S193;
    }
    if(pouches_0)
    {
        return 0.0f;
    }
    if(_S194 > 0.0f)
    {
        pouches_0 = low_3 < 40.0f;
    }
    else
    {
        pouches_0 = false;
    }
    float _S195 = (F32_max((low_3), (0.0f)));
    float _S196 = (F32_min(((F32_max((high_3), (0.0f)))), (_S193)));
    bool _S197 = (c_31->cvHeroTop_0) > 0.0f;
    bool _S198;
    if(_S197)
    {
        if((c_31->cvPileusThick_0) > 0.0f)
        {
            _S198 = true;
        }
        else
        {
            _S198 = (c_31->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        _S198 = false;
    }
    float capBound_0;
    if(_S198)
    {
        float _S199 = convCapBound_0(c_31, lo_6, hi_6, _S195, _S196);
        capBound_0 = _S199;
    }
    else
    {
        capBound_0 = 0.0f;
    }
    float _S200 = convLift_0(c_31, _S196, 1.0f);
    float inside_0;
    if((c_31->cvHeroAlone_0) == int(0))
    {
        float2  _S201 = float2 {lo_6.x, lo_6.z};
        float2  _S202 = float2 {hi_6.x, hi_6.z};
        float _S203 = convUpdraftBound_0(c_31, _S201 - c_31->cvDrift_0, _S202 - c_31->cvDrift_0);
        float _S204 = convTowerHeight_0(c_31, _S203);
        float _S205 = convNeededUpdraft_0(c_31, _S195);
        if(_S203 < _S205)
        {
            float _S206 = convSlopeCap_0(c_31);
            if((c_31->cvMoat_0) > 0.0f)
            {
                float _S207 = convMoatSlopeOver_0(c_31, _S201, _S202);
                inside_0 = _S206 + _S207;
            }
            else
            {
                inside_0 = _S206;
            }
            inside_0 = _S200 - convDistanceFloor_0(_S195 - _S204, (_S205 - _S203) / inside_0);
        }
        else
        {
            inside_0 = (F32_max((_S204 - _S195), (0.0f))) + _S200;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    float edge_0;
    if(_S197)
    {
        float rMin_1 = length_0(max_0(max_0(float2 {lo_6.x, lo_6.z} - c_31->cvHeroAt_0, c_31->cvHeroAt_0 - float2 {hi_6.x, hi_6.z}), make_float2 (0.0f, 0.0f)));
        float _S208 = convHeroReachAll_0(c_31);
        float groupD_0;
        float groupLift_0;
        if(rMin_1 < _S208)
        {
            float _S209 = convHeroHeight_0(c_31, rMin_1);
            float _S210 = convHeroRadiusAt_0(c_31, _S195);
            float _S211 = c_31->cvHeroBillow_0;
            float _S212 = convLift_0(c_31, _S196, c_31->cvHeroBillow_0);
            bool _S213 = _S210 < 0.0f;
            if(_S213)
            {
                _S198 = true;
            }
            else
            {
                _S198 = rMin_1 >= _S210;
            }
            if(_S198)
            {
                if(_S213)
                {
                    edge_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    edge_0 = rMin_1 - _S210;
                }
                edge_0 = - convDistanceFloor_0(_S195 - _S209, edge_0);
            }
            else
            {
                edge_0 = (F32_max((_S209 - _S195), (0.0f)));
            }
            if((c_31->cvShapeOn_0) != int(0))
            {
                _S198 = (c_31->cvShapeDecay_0) < 1.0f;
            }
            else
            {
                _S198 = false;
            }
            if(_S198)
            {
                float _S214 = convShapeBound_0(c_31, lo_6, hi_6, _S195, _S196);
                float _S215 = lerp_0(_S214, edge_0, c_31->cvShapeDecay_0);
                float _S216 = convLift_0(c_31, _S196, _S211 * lerp_0(c_31->cvShapeBillow_0, 1.0f, c_31->cvShapeDecay_0));
                groupD_0 = _S215;
                groupLift_0 = _S216;
            }
            else
            {
                groupD_0 = edge_0;
                groupLift_0 = _S212;
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
            float4  _S217 = convTurret_0(c_31, k_5);
            float turretD_0;
            float turretLift_0;
            bool _S218 = convTurretBound_0(c_31, _S217, lo_6, hi_6, _S195, _S196, &turretD_0, &turretLift_0);
            if(_S218)
            {
                float _S219 = (F32_max((groupLift_0), (turretLift_0)));
                groupD_0 = (F32_max((groupD_0), (turretD_0)));
                groupLift_0 = _S219;
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
        inside_0 = _S196 + _S194;
    }
    else
    {
        inside_0 = _S196;
    }
    return (F32_max((c_31->cvSigma_0 * (F32_sqrt((saturate_0(inside_0 / 40.0f)))) * edge_0 * 1.00001001358032227f), (capBound_0)));
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_19 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_13 = clamp_1(int((F32_floor((x_19)))), int(0), int(31));
    float2  _S220 = __ldg((&(disp_0)[i_13]));
    float2  _S221 = __ldg((&(disp_0)[i_13 + int(1)]));
    return lerp_1(_S220, _S221, make_float2 (x_19 - float(i_13)));
}

static __device__ void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<float2 > disp_1, float d0_0, float d1_0, float2  * lo_7, float2  * hi_7)
{
    float2  _S222 = driftAt_0(g_5, disp_1, d0_0);
    *lo_7 = _S222;
    *hi_7 = _S222;
    float2  _S223 = driftAt_0(g_5, disp_1, d1_0);
    *lo_7 = min_1(*lo_7, _S223);
    *hi_7 = max_0(*hi_7, _S223);
    int _S224 = clamp_1(int((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_6 = clamp_1(int((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_6 <= _S224)
        {
        }
        else
        {
            break;
        }
        float2  _S225 = *lo_7;
        float2  _S226 = __ldg((&(disp_1)[k_6]));
        *lo_7 = min_1(_S225, _S226);
        float2  _S227 = *hi_7;
        float2  _S228 = __ldg((&(disp_1)[k_6]));
        *hi_7 = max_0(_S227, _S228);
        k_6 = k_6 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_6, float2  q0_2, float2  q1_2)
{
    float2  a_4;
    float2  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    float2  _S229 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    float2  _S230 = floor_1(a_4);
    int2  _S231 = make_int2 ((int)_S230.x, (int)_S230.y);
    int2  _S232 = make_int2 (int(1), int(1));
    int2  i0_2 = _S231 - _S232;
    float2  _S233 = floor_1(b_3);
    int2  _S234 = make_int2 ((int)_S233.x, (int)_S233.y);
    int2  _S235 = _S234 + _S232;
    int _S236 = i0_2.y;
    int j_9 = _S236;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S237;
        if(j_9 <= (_S235.y))
        {
            _S237 = j_9 <= (_S236 + int(32));
        }
        else
        {
            _S237 = false;
        }
        if(_S237)
        {
        }
        else
        {
            break;
        }
        int _S238 = i0_2.x;
        int i_14 = _S238;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S239;
            if(i_14 <= (_S235.x))
            {
                _S239 = i_14 <= (_S238 + int(32));
            }
            else
            {
                _S239 = false;
            }
            if(_S239)
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
            float2  _S240 = make_float2 ((float)o_7.x, (float)o_7.y);
            float2  c_32 = _S240 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S229;
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
    bool _S241;
    if(d1_1 < 0.0f)
    {
        _S241 = true;
    }
    else
    {
        _S241 = d0_1 > (g_7->streakLength_0);
    }
    if(_S241)
    {
        return 0.0f;
    }
    float _S242 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S243 = cellFieldBound_0(g_7, make_float2 (lo_8.x, lo_8.z) - driftHi_0, make_float2 (hi_8.x, hi_8.z) - driftLo_0);
    return (F32_max((_S243 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S242), (1.0f)));
}

static __device__ float mediumBound_0(Medium_0 * m_2, StructuredBuffer<float2 > disp_3, float3  lo_9, float3  hi_9)
{
    int _S244 = m_2->mode_0;
    if((m_2->mode_0) == int(3))
    {
        float _S245 = convectionBound_0(&m_2->conv_0, lo_9, hi_9);
        return _S245;
    }
    if(_S244 == int(2))
    {
        float _S246 = iceDensityBound_0(&m_2->gen_0, disp_3, lo_9, hi_9);
        return _S246;
    }
    return m_2->majorant_0;
}

static __device__ float gridBound_0(Medium_0 * m_3, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_0, StructuredBuffer<float2 > disp_4, int3  c_33, float fallback_0)
{
    int _S247 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S247 == int(2))
    {
        float3  _S248 = make_float3 ((float)c_33.x, (float)c_33.y, (float)c_33.z);
        float3  lo_10 = g_8->origin_0 + _S248 * g_8->cellExtent_0;
        float _S249 = mediumBound_0(m_3, disp_4, lo_10, lo_10 + g_8->cellExtent_0);
        return _S249;
    }
    int _S250 = c_33.x;
    bool _S251;
    if(_S250 < int(0))
    {
        _S251 = true;
    }
    else
    {
        _S251 = (c_33.y) < int(0);
    }
    if(_S251)
    {
        _S251 = true;
    }
    else
    {
        _S251 = (c_33.z) < int(0);
    }
    if(_S251)
    {
        _S251 = true;
    }
    else
    {
        _S251 = _S250 >= (g_8->dims_0.x);
    }
    if(_S251)
    {
        _S251 = true;
    }
    else
    {
        _S251 = (c_33.y) >= (g_8->dims_0.y);
    }
    if(_S251)
    {
        _S251 = true;
    }
    else
    {
        _S251 = (c_33.z) >= (g_8->dims_0.z);
    }
    if(_S251)
    {
        return fallback_0;
    }
    float _S252 = __ldg((&(bounds_0)[(c_33.z * g_8->dims_0.y + c_33.y) * g_8->dims_0.x + _S250]));
    return _S252;
}

static __device__ float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S253;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S253 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S253 = false;
    }
    if(_S253)
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
    uint _S254 = r_4->state_0 * 747796405U + 2891336453U;
    r_4->state_0 = _S254;
    uint word_0 = ((_S254 >> ((_S254 >> 28U) + 4U)) ^ _S254) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float orgWaveFactor_0(Organization_0 * o_8, float2  q_7)
{
    float2  unused_0;
    float _S255 = orgWave_0(o_8, q_7, &unused_0);
    return _S255;
}

static __device__ float cellField_0(GeneratorInput_0 * g_9, float2  q_8)
{
    float2  _S256 = q_8 - g_9->cellDrift_0;
    float2  _S257 = orgPattern_0(&g_9->gnOrg_0, _S256, g_9->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(_S257);
    int2  _S258 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    float2  _S259 = orgJitter_0(&g_9->gnOrg_0, 0.80000001192092896f);
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
            int2  o_9 = _S258 + make_int2 (i_15, j_10);
            if((hash22_0(o_9, 2654435769U).x) > (g_9->cellDensity_0))
            {
                i_15 = i_15 + int(1);
                continue;
            }
            float2  _S260 = make_float2 ((float)o_9.x, (float)o_9.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(_S257 - (_S260 + make_float2 (0.5f) + (hash22_0(o_9, 0U) - make_float2 (0.5f)) * _S259)) * 2.20000004768371582f);
            i_15 = i_15 + int(1);
        }
        j_10 = j_10 + int(1);
        acc_2 = acc_3;
    }
    float _S261 = acc_2 * g_9->cellStrength_0;
    float _S262 = orgWaveFactor_0(&g_9->gnOrg_0, _S256);
    return _S261 * _S262;
}

static __device__ float fbm_0(float3  p_2, int octaves_1)
{
    int i_16 = int(0);
    float amp_0 = 0.5f;
    float3  _S263 = p_2;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S263);
        float norm_1 = norm_0 + amp_0;
        float3  _S264 = _S263 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_16 = i_16 + int(1);
        amp_0 = amp_1;
        _S263 = _S264;
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
    bool _S265;
    if(depth_1 < 0.0f)
    {
        _S265 = true;
    }
    else
    {
        _S265 = depth_1 > (g_10->streakLength_0);
    }
    if(_S265)
    {
        return 0.0f;
    }
    float2  _S266 = float2 {p_3.x, p_3.z};
    float2  _S267 = driftAt_0(g_10, disp_5, depth_1);
    float2  source_0 = _S266 - _S267;
    float _S268 = cellField_0(g_10, source_0);
    if(_S268 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S268 * (F32_exp((- g_10->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_10->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_10->streakLength_0, g_10->streakLength_0, depth_1)) * (F32_max((1.0f + g_10->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_10->detailScale_0)).x, (source_0 / make_float2 (g_10->detailScale_0)).y, depth_1 / (F32_max((g_10->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_10->timeSeconds_0 * 0.00999999977648258f), g_10->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_10->opticalDepth_0 / (F32_max((g_10->streakLength_0), (1.0f)));
}

static __device__ float convPouches_0(ConvectionInput_0 * c_34, float2  q_9)
{
    float2  g_11 = q_9 / make_float2 (c_34->cvPouchSize_0);
    float2  _S269 = floor_1(g_11);
    int2  _S270 = make_int2 ((int)_S269.x, (int)_S269.y);
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
            int2  slot_7 = _S270 + make_int2 (i_17, j_11);
            float2  _S271 = make_float2 ((float)slot_7.x, (float)slot_7.y);
            float2  d_8 = g_11 - (_S271 + make_float2 (0.5f) + (hash22_0(slot_7, 739982445U) - make_float2 (0.5f)) * make_float2 (0.60000002384185791f));
            float t2_0 = dot_0(d_8, d_8) / 0.46240001916885376f;
            if(t2_0 >= 1.0f)
            {
                i_17 = i_17 + int(1);
                continue;
            }
            float2  h_3 = hash22_0(slot_7, 2135587861U);
            deepest_1 = (F32_max((deepest_1), (lerp_0(0.30000001192092896f, 1.0f, convLife_0((F32_frac((2.0f * c_34->cvAge_0 + h_3.x))))) * lerp_0(0.60000002384185791f, 1.0f, h_3.y) * (F32_sqrt((1.0f - t2_0))))));
            i_17 = i_17 + int(1);
        }
        int j_12 = j_11 + int(1);
        deepest_0 = deepest_1;
        j_11 = j_12;
    }
    return deepest_0;
}

static __device__ void convMoatRing_0(float2  xz_0, float2  at_0, float radius_3, float * s_7, float2  * gs_0, float * slope_1)
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
    if(f_1 < (*s_7))
    {
        *s_7 = f_1;
        float2  _S272;
        if(r_5 > 0.00100000004749745f)
        {
            _S272 = d_9 * make_float2 (6.0f * t_7 * (1.0f - t_7) / (band_2 * r_5));
        }
        else
        {
            _S272 = make_float2 (0.0f, 0.0f);
        }
        *gs_0 = _S272;
    }
    return;
}

static __device__ float convMoat_0(ConvectionInput_0 * c_35, float2  xz_1, float2  * grad_5, float * slopeAdd_0)
{
    float s_8 = 1.0f;
    float2  gs_1 = make_float2 (0.0f, 0.0f);
    float slope_2 = 0.0f;
    convMoatRing_0(xz_1, c_35->cvHeroAt_0, c_35->cvHeroRadius_0, &s_8, &gs_1, &slope_2);
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
        float4  _S273 = convTurret_0(c_35, k_7);
        convMoatRing_0(xz_1, float2 {_S273.x, _S273.y}, _S273.z, &s_8, &gs_1, &slope_2);
        k_7 = k_7 + int(1);
    }
    float _S274 = c_35->cvMoat_0;
    *grad_5 = gs_1 * make_float2 (c_35->cvMoat_0);
    *slopeAdd_0 = slope_2 * _S274;
    return 1.0f - _S274 * (1.0f - s_8);
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_36, float2  q_10, float2  * grad_6)
{
    if(((&c_36->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S275 = convUpdraftGradT_2(c_36, q_10, grad_6);
        return _S275;
    }
    if((c_36->cvLacunarity_0) <= 0.0f)
    {
        float _S276 = convUpdraftGradT_1(c_36, q_10, grad_6);
        return _S276;
    }
    float _S277 = convUpdraftGradT_0(c_36, q_10, grad_6);
    return _S277;
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
    float _S278;
    if(v_2 >= 0.0f)
    {
        _S278 = d_10;
    }
    else
    {
        _S278 = - d_10;
    }
    return _S278;
}

static __device__ float convFieldBaseInside_0(ConvectionInput_0 * c_37, float w_3, float2  slope_4, float cap_3)
{
    float _S279 = convTowerHeight_0(c_37, w_3);
    float v_3 = _S279 - 1.0f;
    float _S280 = convNeededUpdraft_0(c_37, 1.0f);
    return convSurfaceDistance_0(v_3, w_3 - _S280, (F32_min((length_0(slope_4)), (cap_3))));
}

static __device__ float convDomeSurface_0(float top_4, float radius_4, float shape_2, float2  rel_0, float r_6, float py_0, float above_4, float3  * x_20)
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
        float _S281 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S281;
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
    *x_20 = make_float3 (at_1.x, py_0 + shiftUp_0, at_1.y);
    return d_11;
}

static __device__ float convTowerSurface_0(ConvectionInput_0 * c_38, float2  rel_1, float r_7, float py_1, float above_5, float3  * x_21)
{
    float _S282 = convDomeSurface_0(c_38->cvHeroTop_0, c_38->cvHeroRadius_0, c_38->cvShape_0, rel_1, r_7, py_1, above_5, x_21);
    return _S282;
}

static __device__ float convShapeSurface_0(ConvectionInput_0 * c_39, float2  plane_0, float py_2, float above_6, float3  * x_22)
{
    float _S283 = plane_0.x;
    float2  slopeUY_1;
    float _S284 = convShapeDistance_0(c_39, _S283, above_6, &slopeUY_1);
    float _S285 = plane_0.y;
    float2  stepDM_1;
    float gap_2 = convShapeProfile_0(_S284, (F32_abs((_S285))), c_39->cvShapeRound_0, &stepDM_1);
    float side_0;
    if(_S285 >= 0.0f)
    {
        side_0 = 1.0f;
    }
    else
    {
        side_0 = -1.0f;
    }
    *x_22 = make_float3 (_S283 + stepDM_1.x * slopeUY_1.x, py_2 + stepDM_1.x * slopeUY_1.y, _S285 + side_0 * stepDM_1.y);
    return - gap_2;
}

static __device__ bool convHeroSmooth_0(ConvectionInput_0 * c_40, float3  p_4, float above_7, float * d_13, float3  * x_23, float * amount_0, float * lobe_0)
{
    *d_13 = -1.00000001504746622e+30f;
    *x_23 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S286 = c_40->cvHeroBillow_0;
    *amount_0 = c_40->cvHeroBillow_0;
    *lobe_0 = _S286;
    float2  rel_2 = float2 {p_4.x, p_4.z} - c_40->cvHeroAt_0;
    float r_8 = length_0(rel_2);
    float _S287 = convHeroReachAll_0(c_40);
    if(r_8 >= _S287)
    {
        return false;
    }
    if((c_40->cvShapeOn_0) == int(0))
    {
        float _S288 = convTowerSurface_0(c_40, rel_2, r_8, p_4.y, above_7, x_23);
        *d_13 = _S288;
    }
    else
    {
        float2  plane_1 = make_float2 (dot_0(rel_2, c_40->cvShapeAxisU_0), dot_0(rel_2, make_float2 (- c_40->cvShapeAxisU_0.y, c_40->cvShapeAxisU_0.x)));
        float _S289 = c_40->cvShapeDecay_0;
        if((c_40->cvShapeDecay_0) >= 1.0f)
        {
            float _S290 = convTowerSurface_0(c_40, plane_1, r_8, p_4.y, above_7, x_23);
            *d_13 = _S290;
        }
        else
        {
            float _S291 = p_4.y;
            float3  xs_0;
            float _S292 = convShapeSurface_0(c_40, plane_1, _S291, above_7, &xs_0);
            if(_S289 > 0.0f)
            {
                float3  xt_0;
                float _S293 = convTowerSurface_0(c_40, plane_1, r_8, _S291, above_7, &xt_0);
                *d_13 = lerp_0(_S292, _S293, _S289);
                *x_23 = lerp_2(xs_0, xt_0, make_float3 (_S289));
            }
            else
            {
                *d_13 = _S292;
                *x_23 = xs_0;
            }
            float _S294 = c_40->cvShapeBillow_0;
            *amount_0 = _S286 * lerp_0(c_40->cvShapeBillow_0, 1.0f, _S289);
            *lobe_0 = _S286 * lerp_0((F32_max((_S294), (0.30000001192092896f))), 1.0f, _S289);
        }
    }
    return true;
}

static __device__ bool convTurretSmooth_0(ConvectionInput_0 * c_41, float4  t_8, float3  p_5, float above_8, float * d_14, float3  * x_24, float * k_8)
{
    *d_14 = -1.00000001504746622e+30f;
    *x_24 = make_float3 (0.0f, 0.0f, 0.0f);
    *k_8 = 1.0f;
    float2  rel_3 = float2 {p_5.x, p_5.z} - float2 {t_8.x, t_8.y};
    float r2_2 = dot_0(rel_3, rel_3);
    float _S295 = convTurretReach_0(c_41, t_8);
    if(r2_2 >= (_S295 * _S295))
    {
        return false;
    }
    float _S296 = t_8.w;
    if(above_8 >= (_S296 + c_41->cvBillow_0 * c_41->cvHeroBillow_0))
    {
        return false;
    }
    float r_9 = (F32_sqrt((r2_2)));
    float _S297 = t_8.z;
    float _S298 = convTurretBillow_0(c_41, _S297);
    *k_8 = _S298;
    float3  own_0;
    float _S299 = convDomeSurface_0(_S296, _S297, c_41->cvShape_0, rel_3, r_9, p_5.y, above_8, &own_0);
    *d_14 = _S299;
    float3  w_4 = own_0 + make_float3 (t_8.x - c_41->cvHeroAt_0.x, 0.0f, t_8.y - c_41->cvHeroAt_0.y);
    float3  w_5;
    if((c_41->cvShapeOn_0) != int(0))
    {
        float2  _S300 = float2 {w_4.x, w_4.z};
        w_5 = make_float3 (dot_0(_S300, c_41->cvShapeAxisU_0), w_4.y, dot_0(_S300, make_float2 (- c_41->cvShapeAxisU_0.y, c_41->cvShapeAxisU_0.x)));
    }
    else
    {
        w_5 = w_4;
    }
    *x_24 = w_5;
    return true;
}

static __device__ float convGroupBaseInside_0(ConvectionInput_0 * c_42, float2  xz_2, bool nearGroup_0)
{
    float best_1;
    if((c_42->cvHeroTop_0) > 0.0f)
    {
        float3  p_6 = make_float3 (xz_2.x, c_42->cvBase_0 + 1.0f, xz_2.y);
        float d_15;
        float amount_1;
        float lobe_1;
        float3  x_25;
        bool _S301 = convHeroSmooth_0(c_42, p_6, 1.0f, &d_15, &x_25, &amount_1, &lobe_1);
        if(_S301)
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
            bool _S302;
            if(!nearGroup_0)
            {
                _S302 = true;
            }
            else
            {
                _S302 = k_9 >= (c_42->cvTurretCount_0);
            }
            if(_S302)
            {
                break;
            }
            float4  _S303 = convTurret_0(c_42, k_9);
            float kt_0;
            bool _S304 = convTurretSmooth_0(c_42, _S303, p_6, 1.0f, &d_15, &x_25, &kt_0);
            if(_S304)
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
        float m_4;
        if(moated_0)
        {
            float _S305 = convMoat_0(c_43, xz_3, &gMoat_0, &capMoat_0);
            m_4 = _S305;
        }
        else
        {
            m_4 = 1.0f;
        }
        if(m_4 > 0.0f)
        {
            float2  slope_5;
            float _S306 = convUpdraftGrad_0(c_43, xz_3 - c_43->cvDrift_0, &slope_5);
            float _S307 = convSlopeCap_0(c_43);
            float cap_4;
            if(moated_0)
            {
                slope_5 = slope_5 * make_float2 (m_4) + gMoat_0 * make_float2 (_S306);
                float cap_5 = _S307 + capMoat_0;
                best_2 = _S306 * m_4;
                cap_4 = cap_5;
            }
            else
            {
                best_2 = _S306;
                cap_4 = _S307;
            }
            float _S308 = convFieldBaseInside_0(c_43, best_2, slope_5, cap_4);
            best_2 = _S308;
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
    float _S309 = convGroupBaseInside_0(c_43, xz_3, nearGroup_1);
    return (F32_max((best_2), (_S309)));
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
    float _S310 = convPouches_0(c_45, xz_4 - c_45->cvDrift_0);
    if((c_45->cvMammaDepth_0 * _S310) <= below_0)
    {
        return 0.0f;
    }
    float _S311 = convBaseInside_0(c_45, xz_4, nearGroup_2);
    float _S312 = convMammaSagOf_0(c_45, _S310, _S311);
    return _S312;
}

static __device__ float3  convTwist_0(float3  x_26)
{
    float _S313 = x_26.x;
    float _S314 = x_26.y;
    float _S315 = x_26.z;
    return make_float3 (0.0f * _S313 + 0.80000001192092896f * _S314 + 0.60000002384185791f * _S315, -0.80000001192092896f * _S313 + 0.36000001430511475f * _S314 - 0.47999998927116394f * _S315, -0.60000002384185791f * _S313 - 0.47999998927116394f * _S314 + 0.63999998569488525f * _S315);
}

static __device__ float convPuffs_0(float3  x_27)
{
    float3  fl_0 = floor_0(x_27);
    int3  _S316 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
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
    int3  _S317 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S317 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S318 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_16 = _S318 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S316 + off_0) - f_2;
                float _S319 = (F32_min((nearest_1), (dot_1(d_16, d_16))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S319;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_46, float3  p_7, float scale_0)
{
    float3  _S320 = make_float3 (p_7.x, p_7.y - c_46->cvRise_0, p_7.z) / make_float3 (scale_0);
    int i_18 = int(0);
    float3  x_28 = _S320;
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
        if(i_18 >= (c_46->cvOctaves_0))
        {
            break;
        }
        float3  x_29 = convTwist_0(x_28);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_29);
        float norm_3 = norm_2 + amp_2;
        float3  x_30 = x_29 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_18 = i_18 + int(1);
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
    return clamp_0(raw_0 * 2.20000004768371582f - 1.15999996662139893f, -1.0f, 1.0f);
}

static __device__ float convInside_0(ConvectionInput_0 * c_47, float d_17, float lift_2, float3  x_31, float scale_1)
{
    float _S321 = d_17 + lift_2;
    if(_S321 <= 0.0f)
    {
        return _S321;
    }
    if((d_17 - lift_2) >= 12.0f)
    {
        return 12.0f;
    }
    float _S322 = convBillow_0(c_47, x_31, scale_1);
    return d_17 + lift_2 * _S322;
}

static __device__ float convCapGrain_0(ConvectionInput_0 * c_48, float2  rel_4, float scale_2)
{
    return saturate_0(0.80000001192092896f + 0.13330000638961792f * gradientNoise_0(make_float3 (rel_4.x / scale_2 + c_48->cvHeroSeed_0.x * 0.00100000004749745f, 0.37000000476837158f, rel_4.y / scale_2 + c_48->cvHeroSeed_0.z * 0.00100000004749745f)));
}

static __device__ float convCapDensity_0(ConvectionInput_0 * c_49, float3  p_8, float above_9)
{
    float2  rel_5 = float2 {p_8.x, p_8.z} - c_49->cvHeroAt_0;
    float r2_3 = dot_0(rel_5, rel_5);
    float _S323 = c_49->cvHeroRadius_0;
    float _S324 = c_49->cvPileusThick_0;
    float best_3;
    if((c_49->cvPileusThick_0) > 0.0f)
    {
        float rp_1 = 0.60000002384185791f * _S323;
        float _S325 = rp_1 * rp_1;
        if(r2_3 < _S325)
        {
            float lens_0 = 1.0f - r2_3 / _S325;
            float _S326 = c_49->cvPileusGap_0;
            float _S327 = convHeroHeight_0(c_49, (F32_sqrt((r2_3))) * 0.60000002384185791f);
            float most_0 = 0.5f * _S324 * lens_0;
            float _S328 = (F32_abs((above_9 - (_S326 + _S327))));
            if(_S328 < most_0)
            {
                float _S329 = convCapGrain_0(c_49, rel_5, 900.0f);
                float s_9 = most_0 * _S329 - _S328;
                if(s_9 > 0.0f)
                {
                    best_3 = (F32_max((0.0f), (0.44999998807907104f * smoothstep_0(0.0f, 15.0f, s_9))));
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
    float _S330 = c_49->cvVelumThick_0;
    if((c_49->cvVelumThick_0) > 0.0f)
    {
        float ext_1 = 1.89999997615814209f * _S323;
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
            float edge_1 = _S323 + (ext_1 - _S323) * saturate_0(0.875f + 0.08330000191926956f * gradientNoise_0(make_float3 (1.70000004768371582f * dir_0.x + c_49->cvHeroSeed_0.x * 0.00100000004749745f, 2.29999995231628418f, 1.70000004768371582f * dir_0.y + c_49->cvHeroSeed_0.z * 0.00100000004749745f)));
            float _S331 = 0.5f * _S330;
            float most_1 = _S331 * (1.0f - smoothstep_0(_S323 + 0.40000000596046448f * (edge_1 - _S323), edge_1, r_10));
            float _S332 = (F32_abs((above_9 - (c_49->cvVelumHeight_0 + _S331 * (1.0f - smoothstep_0(_S323, 2.0f * _S323, r_10))))));
            if(_S332 < most_1)
            {
                float _S333 = convCapGrain_0(c_49, rel_5, 2500.0f);
                float s_10 = most_1 * _S333 - _S332;
                if(s_10 > 0.0f)
                {
                    best_3 = (F32_max((best_3), (0.2199999988079071f * smoothstep_0(0.0f, 15.0f, s_10))));
                }
            }
        }
    }
    return c_49->cvSigma_0 * best_3;
}

static __device__ void convGroupFold_0(float d_18, float3  x_32, float lift_3, float lobe_2, float * gMax_0, float * gSum_0, float3  * gX_0, float * gLift_0, float * gLobe_0)
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
    *gX_0 = *gX_0 + make_float3 (wt_0) * x_32;
    *gLift_0 = *gLift_0 + wt_0 * lift_3;
    *gLobe_0 = *gLobe_0 + wt_0 * lobe_2;
    return;
}

static __device__ float convGroupInside_0(ConvectionInput_0 * c_50, float3  p_9, float above_10, bool nearGroup_3)
{
    bool _S334;
    float gMax_1 = -1.00000001504746622e+30f;
    float gSum_1 = 0.0f;
    float gLift_1 = 0.0f;
    float gLobe_1 = 0.0f;
    float3  gX_1 = make_float3 (0.0f, 0.0f, 0.0f);
    float d_19;
    float amount_2;
    float lobe_3;
    float3  x_33;
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
            _S334 = true;
        }
        else
        {
            _S334 = k_10 >= (c_50->cvTurretCount_0);
        }
        if(_S334)
        {
            break;
        }
        float4  _S335 = convTurret_0(c_50, k_10);
        float kt_1;
        bool _S336 = convTurretSmooth_0(c_50, _S335, p_9, above_10, &d_19, &x_33, &kt_1);
        if(_S336)
        {
            float _S337 = convLift_0(c_50, above_10, kt_1);
            convGroupFold_0(d_19, x_33, _S337, kt_1, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
            anyTurret_0 = true;
        }
        k_10 = k_10 + int(1);
    }
    bool _S338 = convHeroSmooth_0(c_50, p_9, above_10, &d_19, &x_33, &amount_2, &lobe_3);
    float heroLift_0;
    if(_S338)
    {
        float _S339 = convLift_0(c_50, above_10, amount_2);
        heroLift_0 = _S339;
    }
    else
    {
        heroLift_0 = 0.0f;
    }
    if(!_S338)
    {
        _S334 = !anyTurret_0;
    }
    else
    {
        _S334 = false;
    }
    if(_S334)
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
        at_2 = x_33;
        lobeAt_0 = lobe_3;
    }
    else
    {
        if(_S338)
        {
            convGroupFold_0(d_19, x_33, heroLift_0, lobe_3, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
        }
        float3  _S340 = gX_1 / make_float3 (gSum_1);
        float _S341 = gLobe_1 / gSum_1;
        lift_4 = gLift_1 / gSum_1;
        at_2 = _S340;
        lobeAt_0 = _S341;
    }
    float _S342 = convInside_0(c_50, gMax_1, lift_4, at_2 + c_50->cvHeroSeed_0, c_50->cvBillowScale_0 * lobeAt_0);
    return _S342;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_51, float3  p_10, float above_11)
{
    float d_20;
    float amount_3;
    float lobe_4;
    float3  x_34;
    bool _S343 = convHeroSmooth_0(c_51, p_10, above_11, &d_20, &x_34, &amount_3, &lobe_4);
    if(!_S343)
    {
        return -1.00000001504746622e+30f;
    }
    float _S344 = convLift_0(c_51, above_11, amount_3);
    float _S345 = convInside_0(c_51, d_20, _S344, x_34 + c_51->cvHeroSeed_0, c_51->cvBillowScale_0 * lobe_4);
    return _S345;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_52, float3  p_11)
{
    float _S346 = p_11.y;
    float above_12 = _S346 - c_52->cvBase_0;
    float _S347 = c_52->cvMammaDepth_0;
    bool rampBand_0;
    if(above_12 < (- c_52->cvMammaDepth_0))
    {
        rampBand_0 = true;
    }
    else
    {
        float _S348 = convCeiling_0(c_52);
        rampBand_0 = above_12 > _S348;
    }
    if(rampBand_0)
    {
        return 0.0f;
    }
    float2  _S349 = float2 {p_11.x, p_11.z};
    float2  fromHero_0 = _S349 - c_52->cvHeroAt_0;
    bool nearGroup_4 = (dot_0(fromHero_0, fromHero_0)) < (c_52->cvGroupReach_0 * c_52->cvGroupReach_0);
    bool _S350 = _S347 > 0.0f;
    if(_S350)
    {
        rampBand_0 = above_12 < 0.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    if(rampBand_0)
    {
        float _S351 = convMammaSag_0(c_52, _S349, nearGroup_4, - above_12);
        float hang_0 = _S351 + above_12;
        if(hang_0 <= 0.0f)
        {
            return 0.0f;
        }
        return c_52->cvSigma_0 * (F32_sqrt((saturate_0(hang_0 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, hang_0);
    }
    float _S352 = convLift_0(c_52, above_12, 1.0f - 0.60000002384185791f * c_52->cvLacunarity_0);
    if(_S350)
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
        float2  _S353 = make_float2 (0.0f, 0.0f);
        float2  gMoat_1 = _S353;
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
            float _S354 = convMoat_0(c_52, _S349, &gMoat_1, &capMoat_1);
            capDensity_0 = _S354;
        }
        else
        {
            capDensity_0 = 1.0f;
        }
        if(capDensity_0 > 0.0f)
        {
            float2  q_11 = _S349 - c_52->cvDrift_0;
            float2  slope_6;
            float _S355 = convUpdraftGrad_0(c_52, q_11, &slope_6);
            float _S356 = convSlopeCap_0(c_52);
            float cap_6;
            if(moated_1)
            {
                slope_6 = slope_6 * make_float2 (capDensity_0) + gMoat_1 * make_float2 (_S355);
                float cap_7 = _S356 + capMoat_1;
                sag_0 = _S355 * capDensity_0;
                cap_6 = cap_7;
            }
            else
            {
                sag_0 = _S355;
                cap_6 = _S356;
            }
            if(rampBand_0)
            {
                float _S357 = convFieldBaseInside_0(c_52, sag_0, slope_6, cap_6);
                baseField_0 = _S357;
            }
            else
            {
                baseField_0 = -1.00000001504746622e+30f;
            }
            float _S358 = convTowerHeight_0(c_52, sag_0);
            float v_5 = _S358 - above_12;
            float _S359 = convNeededUpdraft_0(c_52, above_12);
            float delta_1 = sag_0 - _S359;
            float d_21 = convSurfaceDistance_0(v_5, delta_1, (F32_min((length_0(slope_6)), (cap_6))));
            if((d_21 + _S352) > 0.0f)
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
                    shiftAcross_0 = _S353;
                }
                float _S360 = convInside_0(c_52, d_21, _S352, make_float3 (q_11.x + shiftAcross_0.x, _S346 + inside_3, q_11.y + shiftAcross_0.y), c_52->cvBillowScale_0);
                inside_3 = _S360;
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
    bool _S361 = (c_52->cvHeroTop_0) > 0.0f;
    if(_S361)
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
        float _S362 = convCapDensity_0(c_52, p_11, above_12);
        capDensity_0 = _S362;
    }
    else
    {
        capDensity_0 = 0.0f;
    }
    if(_S361)
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
            float _S363 = convGroupInside_0(c_52, p_11, above_12, nearGroup_4);
            inside_3 = (F32_max((inside_3), (_S363)));
        }
        else
        {
            float _S364 = convHeroInside_0(c_52, p_11, above_12);
            inside_3 = (F32_max((inside_3), (_S364)));
        }
    }
    if(inside_3 <= 0.0f)
    {
        return capDensity_0;
    }
    if(rampBand_0)
    {
        float _S365 = convPouches_0(c_52, _S349 - c_52->cvDrift_0);
        if(_S365 > 0.0f)
        {
            float _S366 = convGroupBaseInside_0(c_52, _S349, nearGroup_4);
            float _S367 = convMammaSagOf_0(c_52, _S365, (F32_max((baseField_0), (_S366))));
            sag_0 = _S367;
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

static __device__ float densityAt_0(Medium_0 * m_5, StructuredBuffer<float2 > disp_6, float3  p_12)
{
    float _S368 = p_12.y;
    bool _S369;
    if(_S368 < (m_5->slabBottom_0))
    {
        _S369 = true;
    }
    else
    {
        _S369 = _S368 > (m_5->slabTop_0);
    }
    if(_S369)
    {
        return 0.0f;
    }
    if((m_5->clipOn_0) != int(0))
    {
        float2  _S370 = float2 {p_12.x, p_12.z};
        if(any_0(_S370 < (m_5->clipLo_0)))
        {
            _S369 = true;
        }
        else
        {
            _S369 = any_0(_S370 > (m_5->clipHi_0));
        }
    }
    else
    {
        _S369 = false;
    }
    if(_S369)
    {
        return 0.0f;
    }
    float _S371 = m_5->fadeRadius_0;
    float fade_0;
    if((m_5->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S371 - length_0(float2 {p_12.x, p_12.z} - m_5->fadeAt_0)) / (F32_max((m_5->fadeWidth_0), (1.0f))));
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
    int _S372 = m_5->mode_0;
    if((m_5->mode_0) == int(0))
    {
        return m_5->density_0 * fade_0;
    }
    if(_S372 == int(2))
    {
        float _S373 = iceDensity_0(&m_5->gen_0, disp_6, p_12);
        return _S373 * fade_0;
    }
    if(_S372 == int(3))
    {
        float _S374 = convectionDensity_0(&m_5->conv_0, p_12);
        return _S374 * fade_0;
    }
    float3  d_22 = (p_12 - m_5->coreCentre_0) / make_float3 ((F32_max((m_5->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_5->density_0 + m_5->coreDensity_0 * (F32_exp((- dot_1(d_22, d_22))))) * fade_0;
}

static __device__ float transmittance_0(Medium_0 * m_6, MajorantGrid_0 * g_12, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_7, Rng_0 * rng_0, float3  p_13, float3  dir_1, int * steps_0)
{
    float t0_2;
    float t1_2;
    bool _S375 = slabRange_0(m_6, p_13, dir_1, &t0_2, &t1_2);
    if(!_S375)
    {
        return 1.0f;
    }
    float _S376 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S376;
    Dda_0 _S377 = ddaInit_0(g_12, p_13, dir_1, _S376);
    Dda_0 dda_0 = _S377;
    float _S378 = m_6->majorant_0;
    float _S379 = gridBound_0(m_6, g_12, bounds_1, disp_7, (&dda_0)->cell_0, m_6->majorant_0);
    float localMaj_0 = _S379;
    int i_19 = int(0);
    float t_9 = _S376;
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
        Dda_0 _S380 = dda_0;
        float _S381 = ddaExit_0(&_S380);
        float _S382 = (F32_min((_S381), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S382 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S383 = gridBound_0(m_6, g_12, bounds_1, disp_7, (&dda_0)->cell_0, _S378);
            localMaj_0 = _S383;
            t_9 = _S382;
            i_19 = i_19 + int(1);
            continue;
        }
        float _S384 = randFloat_0(rng_0);
        float t_10 = t_9 - (F32_log(((F32_max((1.0f - _S384), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_10 >= _S382)
        {
            if(_S382 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S385 = gridBound_0(m_6, g_12, bounds_1, disp_7, (&dda_0)->cell_0, _S378);
            localMaj_0 = _S385;
            t_9 = _S382;
            i_19 = i_19 + int(1);
            continue;
        }
        float _S386 = densityAt_0(m_6, disp_7, p_13 + dir_1 * make_float3 (t_10));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S386 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S387 = randFloat_0(rng_0);
            if(_S387 > 0.5f)
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

extern "C" __global__ void transmittanceTrial(Medium_0 medium_0, MajorantGrid_0 grid_0, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > drift_0, float3  origin_1, float3  direction_0, RWStructuredBuffer<float> output_0, RWStructuredBuffer<int> outSteps_0, uint seed_1, int count_0)
{
    int i_20 = int((blockIdx * blockDim + threadIdx).x);
    if(i_20 >= count_0)
    {
        return;
    }
    uint s_11 = uint(i_20) * 747796405U + 2891336453U;
    uint s_12 = ((s_11 >> ((s_11 >> 28U) + 4U)) ^ s_11) * 277803737U;
    Rng_0 rng_1 = makeRng_0(((s_12 >> 22U) ^ s_12) ^ seed_1);
    int steps_1 = int(0);
    float * _S388 = (&(output_0)[i_20]);
    Medium_0 _S389 = medium_0;
    MajorantGrid_0 _S390 = grid_0;
    float _S391 = transmittance_0(&_S389, &_S390, bounds_2, drift_0, &rng_1, origin_1, direction_0, &steps_1);
    *_S388 = _S391;
    *(&(outSteps_0)[i_20]) = steps_1;
    return;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_7, MajorantGrid_0 * g_13, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > disp_8, Rng_0 * rng_2, float3  ro_2, float3  rd_2, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_2)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S392 = slabRange_0(m_7, ro_2, rd_2, &t0_3, &t1_3);
    if(!_S392)
    {
        return false;
    }
    float _S393 = (F32_min((t1_3), (tLimit_0)));
    t1_3 = _S393;
    if(!(_S393 > t0_3))
    {
        return false;
    }
    float _S394 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S395 = ddaInit_0(g_13, ro_2, rd_2, _S394);
    Dda_0 dda_1 = _S395;
    float _S396 = m_7->majorant_0;
    float _S397 = gridBound_0(m_7, g_13, bounds_3, disp_8, (&dda_1)->cell_0, m_7->majorant_0);
    float localMaj_1 = _S397;
    int i_21 = int(0);
    float t_11 = _S394;
    for(;;)
    {
        if(i_21 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_2 = *steps_2 + int(1);
        Dda_0 _S398 = dda_1;
        float _S399 = ddaExit_0(&_S398);
        float _S400 = (F32_min((_S399), (t1_3)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S400 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S401 = gridBound_0(m_7, g_13, bounds_3, disp_8, (&dda_1)->cell_0, _S396);
            localMaj_1 = _S401;
            t_11 = _S400;
            i_21 = i_21 + int(1);
            continue;
        }
        float _S402 = randFloat_0(rng_2);
        float t_12 = t_11 - (F32_log(((F32_max((1.0f - _S402), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_12 >= _S400)
        {
            if(_S400 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S403 = gridBound_0(m_7, g_13, bounds_3, disp_8, (&dda_1)->cell_0, _S396);
            localMaj_1 = _S403;
            t_11 = _S400;
            i_21 = i_21 + int(1);
            continue;
        }
        float3  p_14 = ro_2 + rd_2 * make_float3 (t_12);
        float _S404 = randFloat_0(rng_2);
        float _S405 = densityAt_0(m_7, disp_8, p_14);
        if(_S404 < (_S405 / localMaj_1))
        {
            *scatterPoint_0 = p_14;
            *distance_0 = t_12;
            return true;
        }
        t_11 = t_12;
        i_21 = i_21 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_8, MajorantGrid_0 * g_14, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > disp_9, Rng_0 * rng_3, float3  ro_3, float3  rd_3, float3  * scatterPoint_1, float * distance_1, int * steps_3)
{
    bool _S406 = sampleFreeFlightUpTo_0(m_8, g_14, bounds_4, disp_9, rng_3, ro_3, rd_3, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_3);
    return _S406;
}

extern "C" __global__ void freeFlightTrial(Medium_0 medium_1, MajorantGrid_0 grid_1, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > drift_1, float3  origin_2, float3  direction_1, RWStructuredBuffer<float> outDistance_0, RWStructuredBuffer<int> outSteps_1, uint seed_2, int count_1)
{
    int i_22 = int((blockIdx * blockDim + threadIdx).x);
    if(i_22 >= count_1)
    {
        return;
    }
    uint s_13 = uint(i_22) * 747796405U + 2891336453U;
    uint s_14 = ((s_13 >> ((s_13 >> 28U) + 4U)) ^ s_13) * 277803737U;
    Rng_0 rng_4 = makeRng_0(((s_14 >> 22U) ^ s_14) ^ seed_2);
    int steps_4 = int(0);
    float * _S407 = (&(outDistance_0)[i_22]);
    Medium_0 _S408 = medium_1;
    MajorantGrid_0 _S409 = grid_1;
    float3  hit_0;
    float dist_1;
    bool _S410 = sampleFreeFlight_0(&_S408, &_S409, bounds_5, drift_1, &rng_4, origin_2, direction_1, &hit_0, &dist_1, &steps_4);
    float _S411;
    if(_S410)
    {
        _S411 = dist_1;
    }
    else
    {
        _S411 = -1.0f;
    }
    *_S407 = _S411;
    *(&(outSteps_1)[i_22]) = steps_4;
    return;
}

extern "C" __global__ void rngTrial(RWStructuredBuffer<float> output_1, uint seed_3, int count_2)
{
    int i_23 = int((blockIdx * blockDim + threadIdx).x);
    if(i_23 >= count_2)
    {
        return;
    }
    Rng_0 rng_5 = makeRng_0(seed_3 + uint(i_23));
    float * _S412 = (&(output_1)[i_23]);
    float _S413 = randFloat_0(&rng_5);
    *_S412 = _S413;
    return;
}

extern "C" __global__ void buildIceGrid(Medium_0 medium_2, StructuredBuffer<float2 > drift_2, MajorantGrid_0 grid_2, RWStructuredBuffer<float> outBounds_0, int cellCount_0)
{
    int i_24 = int((blockIdx * blockDim + threadIdx).x);
    if(i_24 >= cellCount_0)
    {
        return;
    }
    int _S414 = grid_2.dims_0.x;
    int cx_0 = i_24 % _S414;
    int _S415 = i_24 / _S414;
    int _S416 = grid_2.dims_0.y;
    int cy_0 = _S415 % _S416;
    int cz_0 = i_24 / (_S414 * _S416);
    float3  lo_11 = grid_2.origin_0 + make_float3 (float(cx_0), float(cy_0), float(cz_0)) * grid_2.cellExtent_0;
    float * _S417 = (&(outBounds_0)[i_24]);
    float3  _S418 = lo_11 + grid_2.cellExtent_0;
    GeneratorInput_0 _S419 = medium_2.gen_0;
    float _S420 = iceDensityBound_0(&_S419, drift_2, lo_11, _S418);
    *_S417 = _S420;
    return;
}

