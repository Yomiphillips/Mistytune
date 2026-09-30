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

static __device__ float2  max_0(float2  x_1, float2  y_0)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_max((_slang_vector_get_element(x_1, i_1)), (_slang_vector_get_element(y_0, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ bool all_0(bool2  x_2)
{
    bool result_2 = true;
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
        if(result_2)
        {
            result_2 = (bool((_slang_vector_get_element(x_2, i_2))));
        }
        else
        {
            result_2 = false;
        }
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ float dot_0(float3  x_3, float3  y_1)
{
    return x_3.x * y_1.x + x_3.y * y_1.y + x_3.z * y_1.z;
}

static __device__ float3  floor_0(float3  x_4)
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
        *_slang_vector_get_element_ptr(&result_3, i_3) = (F32_floor((_slang_vector_get_element(x_4, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ float dot_1(float2  x_5, float2  y_2)
{
    return x_5.x * y_2.x + x_5.y * y_2.y;
}

static __device__ float length_0(float2  x_6)
{
    return (F32_sqrt((dot_1(x_6, x_6))));
}

static __device__ float clamp_0(float x_7, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_7), (minBound_0)))), (maxBound_0)));
}

static __device__ float2  lerp_0(float2  x_8, float2  y_3, float2  s_0)
{
    return x_8 + (y_3 - x_8) * s_0;
}

static __device__ float2  floor_1(float2  x_9)
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
        *_slang_vector_get_element_ptr(&result_4, i_4) = (F32_floor((_slang_vector_get_element(x_9, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static __device__ float lerp_1(float x_10, float y_4, float s_1)
{
    return x_10 + (y_4 - x_10) * s_1;
}

static __device__ float saturate_0(float x_11)
{
    return clamp_0(x_11, 0.0f, 1.0f);
}

static __device__ float smoothstep_0(float min_0, float max_1, float x_12)
{
    float _S1 = saturate_0((x_12 - min_0) / (max_1 - min_0));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S2 = __ldg(&(ptr_0->x));
    float _S3 = __ldg(&(ptr_0->y));
    float _S4 = __ldg(&(ptr_0->z));
    return make_float3 (_S2, _S3, _S4);
}

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
};

static __device__ float convCeiling_0(ConvectionInput_0 * c_0)
{
    float _S5 = c_0->cvBillow_0;
    float field_0 = c_0->cvDepth_0 + c_0->cvBillow_0;
    float _S6 = c_0->cvHeroTop_0;
    float hero_0;
    if((c_0->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S6 + _S5 * c_0->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    return (F32_max((field_0), (hero_0)));
}

static __device__ float convLift_0(ConvectionInput_0 * c_1, float above_0, float k_0)
{
    return (F32_min((c_1->cvBillow_0 * k_0 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_1(0.60000002384185791f, 1.0f, saturate_0(above_0 / (F32_max((c_1->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_0), (0.0f))))));
}

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S7 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S8 = _S7;
    *&((&_S8)->x) = *&((&_S8)->x) + _S7.y * 1664525U;
    *&((&_S8)->y) = *&((&_S8)->y) + _S8.x * 1664525U;
    uint2  _S9 = _S8 ^ (_S8 >> make_uint2 (16U));
    _S8 = _S9;
    *&((&_S8)->x) = *&((&_S8)->x) + _S9.y * 1664525U;
    *&((&_S8)->y) = *&((&_S8)->y) + _S8.x * 1664525U;
    uint2  _S10 = _S8 ^ (_S8 >> make_uint2 (16U));
    _S8 = _S10;
    return _S10;
}

static __device__ float2  hash22_0(int2  c_2, uint salt_0)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_2.x), uint(c_2.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S11 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S11 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float convLife_0(float u_0)
{
    float _S12 = 1.0f - u_0;
    return 6.75f * u_0 * _S12 * _S12;
}

static __device__ float convVigour_0(ConvectionInput_0 * c_3, int2  slot_0)
{
    float2  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_3->cvAge_0 + h_1.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_1.y);
}

static __device__ float2  convCellCentre_0(int2  slot_1)
{
    float2  _S13 = make_float2 ((float)slot_1.x, (float)slot_1.y);
    return _S13 + make_float2 (0.5f) + (hash22_0(slot_1, 1759714724U) - make_float2 (0.5f)) * make_float2 (0.69999998807907104f);
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

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_4, float2  q_0, float2  * grad_0)
{
    float2  goTop_0;
    float _S14 = c_4->cvSpacing_0;
    float2  g_0 = q_0 / make_float2 (c_4->cvSpacing_0);
    float2  _S15 = floor_1(g_0);
    int2  _S16 = make_int2 ((int)_S15.x, (int)_S15.y);
    float2  _S17 = make_float2 (0.0f, 0.0f);
    float oTop_0 = 0.0f;
    float2  goTop_1 = _S17;
    float oNext_0 = 0.0f;
    float kTop_0 = 0.0f;
    float2  gkTop_0 = _S17;
    float kNext_0 = 0.0f;
    float2  goNext_0 = _S17;
    float2  gkNext_0 = _S17;
    int j_0 = int(-1);
    for(;;)
    {
        if(j_0 <= int(1))
        {
        }
        else
        {
            break;
        }
        float oTop_1 = oTop_0;
        goTop_0 = goTop_1;
        float oNext_1 = oNext_0;
        float kTop_1 = kTop_0;
        float2  gkTop_1 = gkTop_0;
        float kNext_1 = kNext_0;
        float2  goNext_1 = goNext_0;
        float2  gkNext_1 = gkNext_0;
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
            int2  slot_2 = _S16 + make_int2 (i_5, j_0);
            float _S18 = convVigour_0(c_4, slot_2);
            if(_S18 <= 0.0f)
            {
                i_5 = i_5 + int(1);
                continue;
            }
            float2  d_0 = g_0 - convCellCentre_0(slot_2);
            float d2_1 = dot_1(d_0, d_0);
            float ko_0 = _S18 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S18 * convBump_0(d2_1, 1.04999995231628418f);
            float2  gko_0;
            if(d2_1 < 0.5625f)
            {
                gko_0 = d_0 * make_float2 (-4.0f * _S18 * (1.0f - d2_1 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S17;
            }
            float2  gkk_0;
            if(d2_1 < 1.10249984264373779f)
            {
                gkk_0 = d_0 * make_float2 (-4.0f * _S18 * (1.0f - d2_1 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S17;
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
                float _S19 = oTop_2;
                float2  _S20 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S19;
                goNext_2 = _S20;
            }
            float kTop_2;
            float kNext_2;
            float2  gkTop_2;
            float2  gkNext_2;
            if(kk_0 > kTop_1)
            {
                kTop_2 = kk_0;
                gkTop_2 = gkk_0;
                kNext_2 = kTop_1;
                gkNext_2 = gkTop_1;
            }
            else
            {
                if(kk_0 > kNext_1)
                {
                    kTop_2 = kk_0;
                    gkTop_2 = gkk_0;
                }
                else
                {
                    kTop_2 = kNext_1;
                    gkTop_2 = gkNext_1;
                }
                float _S21 = kTop_2;
                float2  _S22 = gkTop_2;
                kTop_2 = kTop_1;
                gkTop_2 = gkTop_1;
                kNext_2 = _S21;
                gkNext_2 = _S22;
            }
            oTop_1 = oTop_2;
            goTop_0 = goTop_2;
            oNext_1 = oNext_2;
            kTop_1 = kTop_2;
            gkTop_1 = gkTop_2;
            kNext_1 = kNext_2;
            goNext_1 = goNext_2;
            gkNext_1 = gkNext_2;
            i_5 = i_5 + int(1);
        }
        int j_1 = j_0 + int(1);
        oTop_0 = oTop_1;
        goTop_1 = goTop_0;
        oNext_0 = oNext_1;
        kTop_0 = kTop_1;
        gkTop_0 = gkTop_1;
        kNext_0 = kNext_1;
        goNext_0 = goNext_1;
        gkNext_0 = gkNext_1;
        j_0 = j_1;
    }
    float openRaw_0 = oNext_0 / 0.31000000238418579f;
    float _S23 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_0 - kNext_0;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_0 = _S17;
    }
    float _S24 = c_4->cvPolarity_0;
    *grad_0 = lerp_0(goTop_0, gkTop_0 - gkNext_0, make_float2 (c_4->cvPolarity_0)) / make_float2 (_S14);
    return lerp_1(_S23, closedField_0, _S24);
}

static __device__ float convTowerHeight_0(ConvectionInput_0 * c_5, float w_0)
{
    float cover_0 = clamp_0(c_5->cvCoverage_0, 0.0f, 1.0f);
    if(cover_0 <= 0.0f)
    {
        return 0.0f;
    }
    float span_0 = (F32_sqrt((cover_0)));
    float u_1 = saturate_0((w_0 - (1.0f - span_0)) / span_0);
    if(u_1 <= 0.0f)
    {
        return 0.0f;
    }
    return c_5->cvDepth_0 * (F32_pow((u_1), (c_5->cvShape_0)));
}

static __device__ float convNeededUpdraft_0(ConvectionInput_0 * c_6, float above_1)
{
    float cover_1 = clamp_0(c_6->cvCoverage_0, 0.0f, 1.0f);
    bool _S25;
    if(cover_1 <= 0.0f)
    {
        _S25 = true;
    }
    else
    {
        _S25 = (c_6->cvDepth_0) <= 0.0f;
    }
    if(_S25)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_6->cvDepth_0), (1.0f / (F32_max((c_6->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convSurfaceDistance_0(float v_1, float delta_0, float slope_0)
{
    float num_0 = (F32_abs((v_1 * delta_0)));
    float den_0 = (F32_sqrt((v_1 * v_1 * slope_0 * slope_0 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_1 = num_0 / den_0;
    float _S26;
    if(v_1 >= 0.0f)
    {
        _S26 = d_1;
    }
    else
    {
        _S26 = - d_1;
    }
    return _S26;
}

static __device__ float3  convTwist_0(float3  x_13)
{
    float _S27 = x_13.x;
    float _S28 = x_13.y;
    float _S29 = x_13.z;
    return make_float3 (0.0f * _S27 + 0.80000001192092896f * _S28 + 0.60000002384185791f * _S29, -0.80000001192092896f * _S27 + 0.36000001430511475f * _S28 - 0.47999998927116394f * _S29, -0.60000002384185791f * _S27 - 0.47999998927116394f * _S28 + 0.63999998569488525f * _S29);
}

static __device__ uint3  pcg3d_0(uint3  v_2)
{
    uint3  _S30 = v_2 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S31 = _S30;
    *&((&_S31)->x) = *&((&_S31)->x) + _S30.y * _S30.z;
    *&((&_S31)->y) = *&((&_S31)->y) + _S31.z * _S31.x;
    *&((&_S31)->z) = *&((&_S31)->z) + _S31.x * _S31.y;
    uint3  _S32 = _S31 ^ (_S31 >> make_uint3 (16U));
    _S31 = _S32;
    *&((&_S31)->x) = *&((&_S31)->x) + _S32.y * _S32.z;
    *&((&_S31)->y) = *&((&_S31)->y) + _S31.z * _S31.x;
    *&((&_S31)->z) = *&((&_S31)->z) + _S31.x * _S31.y;
    return _S31;
}

static __device__ float3  hash33_0(int3  c_7)
{
    uint3  h_2 = pcg3d_0(make_uint3 (uint(c_7.x), uint(c_7.y), uint(c_7.z)));
    float3  _S33 = make_float3 ((float)h_2.x, (float)h_2.y, (float)h_2.z);
    return _S33 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float convPuffs_0(float3  x_14)
{
    float3  fl_0 = floor_0(x_14);
    int3  _S34 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_0 = x_14 - fl_0;
    int dz_0;
    if((f_0.x) < 0.5f)
    {
        dz_0 = int(-1);
    }
    else
    {
        dz_0 = int(0);
    }
    int dy_0;
    if((f_0.y) < 0.5f)
    {
        dy_0 = int(-1);
    }
    else
    {
        dy_0 = int(0);
    }
    int dx_0;
    if((f_0.z) < 0.5f)
    {
        dx_0 = int(-1);
    }
    else
    {
        dx_0 = int(0);
    }
    int3  _S35 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S35 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S36 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_2 = _S36 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S34 + off_0) - f_0;
                float _S37 = (F32_min((nearest_1), (dot_0(d_2, d_2))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S37;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_8, float3  p_0, float scale_0)
{
    float3  _S38 = make_float3 (p_0.x, p_0.y - c_8->cvRise_0, p_0.z) / make_float3 (scale_0);
    int i_6 = int(0);
    float3  x_15 = _S38;
    float amp_0 = 0.60000002384185791f;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_6 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_6 >= (c_8->cvOctaves_0))
        {
            break;
        }
        float3  x_16 = convTwist_0(x_15);
        float sum_1 = sum_0 + amp_0 * convPuffs_0(x_16);
        float norm_1 = norm_0 + amp_0;
        float3  x_17 = x_16 * make_float3 (2.17000007629394531f);
        float amp_1 = amp_0 * 0.55000001192092896f;
        i_6 = i_6 + int(1);
        x_15 = x_17;
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

static __device__ float convInside_0(ConvectionInput_0 * c_9, float d_3, float lift_0, float3  x_18, float scale_1)
{
    float _S39 = d_3 + lift_0;
    if(_S39 <= 0.0f)
    {
        return _S39;
    }
    if((d_3 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S40 = convBillow_0(c_9, x_18, scale_1);
    return d_3 + lift_0 * _S40;
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_10)
{
    return c_10->cvHeroRadius_0 + 1.5f * c_10->cvBillow_0 * c_10->cvHeroBillow_0 + 24.0f;
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_11, float r_0)
{
    float _S41 = c_11->cvHeroTop_0;
    bool _S42;
    if((c_11->cvHeroTop_0) <= 0.0f)
    {
        _S42 = true;
    }
    else
    {
        _S42 = r_0 >= (c_11->cvHeroRadius_0);
    }
    if(_S42)
    {
        return 0.0f;
    }
    return _S41 * (F32_pow((1.0f - r_0 * r_0 / (c_11->cvHeroRadius_0 * c_11->cvHeroRadius_0)), (c_11->cvShape_0)));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_12, float above_2)
{
    float _S43 = c_12->cvHeroTop_0;
    bool _S44;
    if((c_12->cvHeroTop_0) <= 0.0f)
    {
        _S44 = true;
    }
    else
    {
        _S44 = above_2 >= _S43;
    }
    if(_S44)
    {
        return -1.0f;
    }
    return c_12->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S43), (1.0f / (F32_max((c_12->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_13, float3  p_1, float above_3)
{
    float2  rel_0 = float2 {p_1.x, p_1.z} - c_13->cvHeroAt_0;
    float r_1 = length_0(rel_0);
    float _S45 = convHeroReach_0(c_13);
    if(r_1 >= _S45)
    {
        return -1.00000001504746622e+30f;
    }
    float _S46 = convHeroHeight_0(c_13, r_1);
    float v_3 = _S46 - above_3;
    float _S47 = convHeroRadiusAt_0(c_13, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_4;
    if(_S47 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_4 = v_3;
    }
    else
    {
        float h_3 = _S47 - r_1;
        float d_5 = convSurfaceDistance_0(v_3, h_3, 1.0f);
        if((F32_abs((v_3))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_5 * (d_5 / v_3);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_3))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_5 * (d_5 / h_3);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S48 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S48;
        d_4 = d_5;
    }
    float2  radial_0;
    if(r_1 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / make_float2 (r_1);
    }
    else
    {
        radial_0 = make_float2 (0.0f, 0.0f);
    }
    float2  at_0 = rel_0 + radial_0 * make_float2 (shiftOut_0);
    float3  x_19 = make_float3 (at_0.x, p_1.y + shiftUp_0, at_0.y) + c_13->cvHeroSeed_0;
    float _S49 = c_13->cvHeroBillow_0;
    float _S50 = convLift_0(c_13, above_3, c_13->cvHeroBillow_0);
    float _S51 = convInside_0(c_13, d_4, _S50, x_19, c_13->cvBillowScale_0 * _S49);
    return _S51;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_14, float3  p_2)
{
    float _S52 = p_2.y;
    float above_4 = _S52 - c_14->cvBase_0;
    bool _S53;
    if(above_4 < 0.0f)
    {
        _S53 = true;
    }
    else
    {
        float _S54 = convCeiling_0(c_14);
        _S53 = above_4 > _S54;
    }
    if(_S53)
    {
        return 0.0f;
    }
    float _S55 = convLift_0(c_14, above_4, 1.0f);
    float inside_0;
    if((c_14->cvHeroAlone_0) == int(0))
    {
        float2  q_1 = float2 {p_2.x, p_2.z} - c_14->cvDrift_0;
        float2  slope_1;
        float _S56 = convUpdraftGrad_0(c_14, q_1, &slope_1);
        float _S57 = convTowerHeight_0(c_14, _S56);
        float v_4 = _S57 - above_4;
        float _S58 = convNeededUpdraft_0(c_14, above_4);
        float delta_1 = _S56 - _S58;
        float d_6 = convSurfaceDistance_0(v_4, delta_1, length_0(slope_1));
        if((d_6 + _S55) > 0.0f)
        {
            if((F32_abs((v_4))) > 9.99999997475242708e-07f)
            {
                inside_0 = d_6 * (d_6 / v_4);
            }
            else
            {
                inside_0 = 0.0f;
            }
            float2  shiftAcross_0;
            if((F32_abs((delta_1))) > 9.999999960041972e-13f)
            {
                shiftAcross_0 = slope_1 * make_float2 (- d_6 * (d_6 / delta_1));
            }
            else
            {
                shiftAcross_0 = make_float2 (0.0f, 0.0f);
            }
            float _S59 = convInside_0(c_14, d_6, _S55, make_float3 (q_1.x + shiftAcross_0.x, _S52 + inside_0, q_1.y + shiftAcross_0.y), c_14->cvBillowScale_0);
            inside_0 = _S59;
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
    if((c_14->cvHeroTop_0) > 0.0f)
    {
        _S53 = inside_0 < 12.0f;
    }
    else
    {
        _S53 = false;
    }
    if(_S53)
    {
        float _S60 = convHeroInside_0(c_14, p_2, above_4);
        inside_0 = (F32_max((inside_0), (_S60)));
    }
    if(inside_0 <= 0.0f)
    {
        return 0.0f;
    }
    return c_14->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_0);
}

extern "C" __global__ void convDensityAt(ConvectionInput_0 c_15, StructuredBuffer<float3 > points_0, RWStructuredBuffer<float> outDensity_0, int count_0)
{
    int i_7 = int((blockIdx * blockDim + threadIdx).x);
    if(i_7 >= count_0)
    {
        return;
    }
    float * _S61 = (&(outDensity_0)[i_7]);
    float3  _S62 = slang_ldg_0((&(points_0)[i_7]));
    ConvectionInput_0 _S63 = c_15;
    float _S64 = convectionDensity_0(&_S63, _S62);
    *_S61 = _S64;
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_16, int2  slot_3, float2  a_0, float2  b_0, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S65 = convVigour_0(c_16, slot_3);
    if(_S65 <= 0.0f)
    {
        return;
    }
    float2  ctr_0 = convCellCentre_0(slot_3);
    float2  _S66 = a_0 - ctr_0;
    float2  nearGap_0 = max_0(max_0(_S66, ctr_0 - b_0), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_0(abs_0(_S66), abs_0(b_0 - ctr_0));
    float oHi_0 = _S65 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S65 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S65 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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

static __device__ float convUpdraftBound_0(ConvectionInput_0 * c_17, float2  q0_0, float2  q1_0)
{
    float2  a_1 = q0_0 / make_float2 (c_17->cvSpacing_0);
    float2  b_1 = q1_0 / make_float2 (c_17->cvSpacing_0);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    float2  _S67 = floor_1((a_1 + b_1) * make_float2 (0.5f));
    int2  _S68 = make_int2 ((int)_S67.x, (int)_S67.y);
    float2  _S69 = make_float2 ((float)_S68.x, (float)_S68.y);
    float2  highEdge_0 = _S69 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S70;
    if(all_0(a_1 >= (_S69 - make_float2 (0.00009999999747379f))))
    {
        _S70 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S70 = false;
    }
    int j_2;
    int i_8;
    if(_S70)
    {
        j_2 = int(-1);
        for(;;)
        {
            if(j_2 <= int(1))
            {
            }
            else
            {
                break;
            }
            i_8 = int(-1);
            for(;;)
            {
                if(i_8 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_17, _S68 + make_int2 (i_8, j_2), a_1, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_8 = i_8 + int(1);
            }
            j_2 = j_2 + int(1);
        }
    }
    else
    {
        float2  _S71 = floor_1(a_1);
        int2  _S72 = make_int2 ((int)_S71.x, (int)_S71.y);
        int2  _S73 = make_int2 (int(1), int(1));
        int2  i0_0 = _S72 - _S73;
        float2  _S74 = floor_1(b_1);
        int2  _S75 = make_int2 ((int)_S74.x, (int)_S74.y);
        int2  _S76 = _S75 + _S73;
        int _S77 = i0_0.y;
        j_2 = _S77;
        for(;;)
        {
            if(j_2 <= (_S76.y))
            {
                _S70 = j_2 <= (_S77 + int(32));
            }
            else
            {
                _S70 = false;
            }
            if(_S70)
            {
            }
            else
            {
                break;
            }
            int _S78 = i0_0.x;
            i_8 = _S78;
            for(;;)
            {
                bool _S79;
                if(i_8 <= (_S76.x))
                {
                    _S79 = i_8 <= (_S78 + int(32));
                }
                else
                {
                    _S79 = false;
                }
                if(_S79)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_17, make_int2 (i_8, j_2), a_1, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_8 = i_8 + int(1);
            }
            j_2 = j_2 + int(1);
        }
    }
    return lerp_1((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_17->cvPolarity_0) + 0.00000999999974738f;
}

static __device__ float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S80;
    if(vMin_0 <= 0.0f)
    {
        _S80 = true;
    }
    else
    {
        _S80 = hMin_0 <= 0.0f;
    }
    if(_S80)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_18, float3  lo_0, float3  hi_0)
{
    float low_0 = lo_0.y - c_18->cvBase_0;
    float high_0 = hi_0.y - c_18->cvBase_0;
    float _S81 = convCeiling_0(c_18);
    bool _S82;
    if(high_0 < 0.0f)
    {
        _S82 = true;
    }
    else
    {
        _S82 = low_0 > _S81;
    }
    if(_S82)
    {
        return 0.0f;
    }
    float _S83 = (F32_max((low_0), (0.0f)));
    float _S84 = (F32_min((high_0), (_S81)));
    float _S85 = convLift_0(c_18, _S84, 1.0f);
    float inside_1;
    if((c_18->cvHeroAlone_0) == int(0))
    {
        float _S86 = convUpdraftBound_0(c_18, float2 {lo_0.x, lo_0.z} - c_18->cvDrift_0, float2 {hi_0.x, hi_0.z} - c_18->cvDrift_0);
        float _S87 = convTowerHeight_0(c_18, _S86);
        float _S88 = convNeededUpdraft_0(c_18, _S83);
        if(_S86 < _S88)
        {
            inside_1 = _S85 - convDistanceFloor_0(_S83 - _S87, (_S88 - _S86) / (7.0f / c_18->cvSpacing_0));
        }
        else
        {
            inside_1 = (F32_max((_S87 - _S83), (0.0f))) + _S85;
        }
    }
    else
    {
        inside_1 = -1.00000001504746622e+30f;
    }
    if((c_18->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_0(max_0(max_0(float2 {lo_0.x, lo_0.z} - c_18->cvHeroAt_0, c_18->cvHeroAt_0 - float2 {hi_0.x, hi_0.z}), make_float2 (0.0f, 0.0f)));
        float _S89 = convHeroReach_0(c_18);
        if(rMin_0 < _S89)
        {
            float _S90 = convHeroHeight_0(c_18, rMin_0);
            float _S91 = convHeroRadiusAt_0(c_18, _S83);
            float _S92 = convLift_0(c_18, _S84, c_18->cvHeroBillow_0);
            bool _S93 = _S91 < 0.0f;
            if(_S93)
            {
                _S82 = true;
            }
            else
            {
                _S82 = rMin_0 >= _S91;
            }
            float heroIn_0;
            if(_S82)
            {
                if(_S93)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S91;
                }
                heroIn_0 = _S92 - convDistanceFloor_0(_S83 - _S90, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S90 - _S83), (0.0f))) + _S92;
            }
            inside_1 = (F32_max((inside_1), (heroIn_0)));
        }
    }
    float inside_2 = inside_1 + 0.00100000004749745f;
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_18->cvSigma_0 * (F32_sqrt((saturate_0(_S84 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2) * 1.00001001358032227f;
}

extern "C" __global__ void convBoundOver(ConvectionInput_0 c_19, StructuredBuffer<float3 > boxLo_0, StructuredBuffer<float3 > boxHi_0, RWStructuredBuffer<float> outBound_0, int count_1)
{
    int i_9 = int((blockIdx * blockDim + threadIdx).x);
    if(i_9 >= count_1)
    {
        return;
    }
    float * _S94 = (&(outBound_0)[i_9]);
    float3  _S95 = slang_ldg_0((&(boxLo_0)[i_9]));
    float3  _S96 = slang_ldg_0((&(boxHi_0)[i_9]));
    ConvectionInput_0 _S97 = c_19;
    float _S98 = convectionBound_0(&_S97, _S95, _S96);
    *_S94 = _S98;
    return;
}

static __device__ float convUpdraft_0(ConvectionInput_0 * c_20, float2  q_2)
{
    float2  unused_0;
    float _S99 = convUpdraftGrad_0(c_20, q_2, &unused_0);
    return _S99;
}

extern "C" __global__ void convUpdraftAt(ConvectionInput_0 c_21, StructuredBuffer<float2 > points_1, RWStructuredBuffer<float> outUpdraft_0, int count_2)
{
    int i_10 = int((blockIdx * blockDim + threadIdx).x);
    if(i_10 >= count_2)
    {
        return;
    }
    float * _S100 = (&(outUpdraft_0)[i_10]);
    float2  _S101 = __ldg((&(points_1)[i_10]));
    ConvectionInput_0 _S102 = c_21;
    float _S103 = convUpdraft_0(&_S102, _S101);
    *_S100 = _S103;
    return;
}

extern "C" __global__ void convCells(ConvectionInput_0 c_22, StructuredBuffer<int2 > slots_0, RWStructuredBuffer<float3 > outCell_0, int count_3)
{
    int i_11 = int((blockIdx * blockDim + threadIdx).x);
    if(i_11 >= count_3)
    {
        return;
    }
    int2  _S104 = __ldg((&(slots_0)[i_11]));
    float2  ctr_1 = convCellCentre_0(_S104);
    float3  * _S105 = (&(outCell_0)[i_11]);
    float _S106 = ctr_1.x;
    float _S107 = ctr_1.y;
    int2  _S108 = __ldg((&(slots_0)[i_11]));
    ConvectionInput_0 _S109 = c_22;
    float _S110 = convVigour_0(&_S109, _S108);
    *_S105 = make_float3 (_S106, _S107, _S110);
    return;
}

extern "C" __global__ void convBillowAt(ConvectionInput_0 c_23, StructuredBuffer<float3 > points_2, RWStructuredBuffer<float> outBillow_0, int count_4)
{
    int i_12 = int((blockIdx * blockDim + threadIdx).x);
    if(i_12 >= count_4)
    {
        return;
    }
    float * _S111 = (&(outBillow_0)[i_12]);
    float3  _S112 = slang_ldg_0((&(points_2)[i_12]));
    ConvectionInput_0 _S113 = c_23;
    float _S114 = convBillow_0(&_S113, _S112, c_23.cvBillowScale_0);
    *_S111 = _S114;
    return;
}

extern "C" __global__ void convUpdraftWide(ConvectionInput_0 c_24, StructuredBuffer<float2 > points_3, RWStructuredBuffer<float> outUpdraft_1, int count_5)
{
    int i_13 = int((blockIdx * blockDim + threadIdx).x);
    if(i_13 >= count_5)
    {
        return;
    }
    float2  _S115 = __ldg((&(points_3)[i_13]));
    float2  g_1 = _S115 / make_float2 (c_24.cvSpacing_0);
    float2  _S116 = floor_1(g_1);
    int2  _S117 = make_int2 ((int)_S116.x, (int)_S116.y);
    float oTop_3 = 0.0f;
    float oNext_3 = 0.0f;
    float kTop_3 = 0.0f;
    float kNext_3 = 0.0f;
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
        float oTop_4 = oTop_3;
        float oNext_4 = oNext_3;
        float kTop_4 = kTop_3;
        float kNext_4 = kNext_3;
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
            int2  slot_4 = _S117 + make_int2 (di_0, dj_0);
            ConvectionInput_0 _S118 = c_24;
            float _S119 = convVigour_0(&_S118, slot_4);
            if(_S119 <= 0.0f)
            {
                di_0 = di_0 + int(1);
                continue;
            }
            float2  d_7 = g_1 - convCellCentre_0(slot_4);
            float d2_2 = dot_1(d_7, d_7);
            float ko_1 = _S119 * convBump_0(d2_2, 0.75f);
            float kk_1 = _S119 * convBump_0(d2_2, 1.04999995231628418f);
            float oTop_5;
            float oNext_5;
            if(ko_1 > oTop_4)
            {
                oTop_5 = ko_1;
                oNext_5 = oTop_4;
            }
            else
            {
                if(ko_1 > oNext_4)
                {
                    oTop_5 = ko_1;
                }
                else
                {
                    oTop_5 = oNext_4;
                }
                float _S120 = oTop_5;
                oTop_5 = oTop_4;
                oNext_5 = _S120;
            }
            float kTop_5;
            float kNext_5;
            if(kk_1 > kTop_4)
            {
                kTop_5 = kk_1;
                kNext_5 = kTop_4;
            }
            else
            {
                if(kk_1 > kNext_4)
                {
                    kTop_5 = kk_1;
                }
                else
                {
                    kTop_5 = kNext_4;
                }
                float _S121 = kTop_5;
                kTop_5 = kTop_4;
                kNext_5 = _S121;
            }
            oTop_4 = oTop_5;
            oNext_4 = oNext_5;
            kTop_4 = kTop_5;
            kNext_4 = kNext_5;
            di_0 = di_0 + int(1);
        }
        int dj_1 = dj_0 + int(1);
        oTop_3 = oTop_4;
        oNext_3 = oNext_4;
        kTop_3 = kTop_4;
        kNext_3 = kNext_4;
        dj_0 = dj_1;
    }
    *(&(outUpdraft_1)[i_13]) = lerp_1((F32_min((oNext_3 / 0.31000000238418579f), (1.0f))), kTop_3 - kNext_3, c_24.cvPolarity_0);
    return;
}

