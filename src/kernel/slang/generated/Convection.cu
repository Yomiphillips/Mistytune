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

static __device__ float clamp_0(float x_5, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_5), (minBound_0)))), (maxBound_0)));
}

static __device__ float saturate_0(float x_6)
{
    return clamp_0(x_6, 0.0f, 1.0f);
}

static __device__ float smoothstep_0(float min_0, float max_1, float x_7)
{
    float _S1 = saturate_0((x_7 - min_0) / (max_1 - min_0));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static __device__ float dot_1(float2  x_8, float2  y_2)
{
    return x_8.x * y_2.x + x_8.y * y_2.y;
}

static __device__ float lerp_0(float x_9, float y_3, float s_0)
{
    return x_9 + (y_3 - x_9) * s_0;
}

static __device__ float2  floor_1(float2  x_10)
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
        *_slang_vector_get_element_ptr(&result_4, i_4) = (F32_floor((_slang_vector_get_element(x_10, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S2 = __ldg(&(ptr_0->x));
    float _S3 = __ldg(&(ptr_0->y));
    float _S4 = __ldg(&(ptr_0->z));
    return make_float3 (_S2, _S3, _S4);
}

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S5 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S6 = _S5;
    *&((&_S6)->x) = *&((&_S6)->x) + _S5.y * 1664525U;
    *&((&_S6)->y) = *&((&_S6)->y) + _S6.x * 1664525U;
    uint2  _S7 = _S6 ^ (_S6 >> make_uint2 (16U));
    _S6 = _S7;
    *&((&_S6)->x) = *&((&_S6)->x) + _S7.y * 1664525U;
    *&((&_S6)->y) = *&((&_S6)->y) + _S6.x * 1664525U;
    uint2  _S8 = _S6 ^ (_S6 >> make_uint2 (16U));
    _S6 = _S8;
    return _S8;
}

static __device__ float2  hash22_0(int2  c_0, uint salt_0)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_0.x), uint(c_0.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S9 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S9 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float convLife_0(float u_0)
{
    float _S10 = 1.0f - u_0;
    return 6.75f * u_0 * _S10 * _S10;
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
};

static __device__ float convVigour_0(ConvectionInput_0 * c_1, int2  slot_0)
{
    float2  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_1->cvAge_0 + h_1.x)))) * lerp_0(0.34999999403953552f, 1.0f, h_1.y);
}

static __device__ float2  convCellCentre_0(int2  slot_1)
{
    float2  _S11 = make_float2 ((float)slot_1.x, (float)slot_1.y);
    return _S11 + make_float2 (0.5f) + (hash22_0(slot_1, 1759714724U) - make_float2 (0.5f)) * make_float2 (0.69999998807907104f);
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

static __device__ float convUpdraft_0(ConvectionInput_0 * c_2, float2  q_0)
{
    float2  g_0 = q_0 / make_float2 (c_2->cvSpacing_0);
    float2  _S12 = floor_1(g_0);
    int2  _S13 = make_int2 ((int)_S12.x, (int)_S12.y);
    float oTop_0 = 0.0f;
    float oNext_0 = 0.0f;
    float kTop_0 = 0.0f;
    float kNext_0 = 0.0f;
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
        float oNext_1 = oNext_0;
        float kTop_1 = kTop_0;
        float kNext_1 = kNext_0;
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
            int2  slot_2 = _S13 + make_int2 (i_5, j_0);
            float _S14 = convVigour_0(c_2, slot_2);
            if(_S14 <= 0.0f)
            {
                i_5 = i_5 + int(1);
                continue;
            }
            float2  d_0 = g_0 - convCellCentre_0(slot_2);
            float d2_1 = dot_1(d_0, d_0);
            float ko_0 = _S14 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S14 * convBump_0(d2_1, 1.04999995231628418f);
            float oTop_2;
            float oNext_2;
            if(ko_0 > oTop_1)
            {
                oTop_2 = ko_0;
                oNext_2 = oTop_1;
            }
            else
            {
                if(ko_0 > oNext_1)
                {
                    oTop_2 = ko_0;
                }
                else
                {
                    oTop_2 = oNext_1;
                }
                float _S15 = oTop_2;
                oTop_2 = oTop_1;
                oNext_2 = _S15;
            }
            float kTop_2;
            float kNext_2;
            if(kk_0 > kTop_1)
            {
                kTop_2 = kk_0;
                kNext_2 = kTop_1;
            }
            else
            {
                if(kk_0 > kNext_1)
                {
                    kTop_2 = kk_0;
                }
                else
                {
                    kTop_2 = kNext_1;
                }
                float _S16 = kTop_2;
                kTop_2 = kTop_1;
                kNext_2 = _S16;
            }
            oTop_1 = oTop_2;
            oNext_1 = oNext_2;
            kTop_1 = kTop_2;
            kNext_1 = kNext_2;
            i_5 = i_5 + int(1);
        }
        int j_1 = j_0 + int(1);
        oTop_0 = oTop_1;
        oNext_0 = oNext_1;
        kTop_0 = kTop_1;
        kNext_0 = kNext_1;
        j_0 = j_1;
    }
    return lerp_0((F32_min((oNext_0 / 0.31000000238418579f), (1.0f))), kTop_0 - kNext_0, c_2->cvPolarity_0);
}

static __device__ float convTowerHeight_0(ConvectionInput_0 * c_3, float w_0)
{
    float cover_0 = clamp_0(c_3->cvCoverage_0, 0.0f, 1.0f);
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
    return c_3->cvDepth_0 * (F32_pow((u_1), (c_3->cvShape_0)));
}

static __device__ float convLift_0(ConvectionInput_0 * c_4, float above_0)
{
    return c_4->cvBillow_0 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_0(0.34999999403953552f, 1.0f, saturate_0(above_0 / (F32_max((c_4->cvDepth_0), (1.0f)))));
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S17 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S18 = _S17;
    *&((&_S18)->x) = *&((&_S18)->x) + _S17.y * _S17.z;
    *&((&_S18)->y) = *&((&_S18)->y) + _S18.z * _S18.x;
    *&((&_S18)->z) = *&((&_S18)->z) + _S18.x * _S18.y;
    uint3  _S19 = _S18 ^ (_S18 >> make_uint3 (16U));
    _S18 = _S19;
    *&((&_S18)->x) = *&((&_S18)->x) + _S19.y * _S19.z;
    *&((&_S18)->y) = *&((&_S18)->y) + _S18.z * _S18.x;
    *&((&_S18)->z) = *&((&_S18)->z) + _S18.x * _S18.y;
    return _S18;
}

static __device__ float3  hash33_0(int3  c_5)
{
    uint3  h_2 = pcg3d_0(make_uint3 (uint(c_5.x), uint(c_5.y), uint(c_5.z)));
    float3  _S20 = make_float3 ((float)h_2.x, (float)h_2.y, (float)h_2.z);
    return _S20 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float convPuffs_0(float3  x_11)
{
    float3  fl_0 = floor_0(x_11);
    int3  _S21 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_0 = x_11 - fl_0;
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
    int3  _S22 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S22 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S23 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_1 = _S23 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S21 + off_0) - f_0;
                float _S24 = (F32_min((nearest_1), (dot_0(d_1, d_1))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S24;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_6, float3  p_0)
{
    float3  _S25 = make_float3 (p_0.x, p_0.y - c_6->cvRise_0, p_0.z) / make_float3 (c_6->cvBillowScale_0);
    int i_6 = int(0);
    float amp_0 = 0.60000002384185791f;
    float3  x_12 = _S25;
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
        if(i_6 >= (c_6->cvOctaves_0))
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * convPuffs_0(x_12);
        float norm_1 = norm_0 + amp_0;
        float3  x_13 = x_12 * make_float3 (2.17000007629394531f);
        float amp_1 = amp_0 * 0.55000001192092896f;
        i_6 = i_6 + int(1);
        amp_0 = amp_1;
        x_12 = x_13;
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

static __device__ float convectionDensity_0(ConvectionInput_0 * c_7, float3  p_1)
{
    float _S26 = p_1.y;
    float above_1 = _S26 - c_7->cvBase_0;
    bool _S27;
    if(above_1 < 0.0f)
    {
        _S27 = true;
    }
    else
    {
        _S27 = above_1 > (c_7->cvDepth_0 + c_7->cvBillow_0);
    }
    if(_S27)
    {
        return 0.0f;
    }
    float2  q_1 = float2 {p_1.x, p_1.z} - c_7->cvDrift_0;
    float _S28 = convUpdraft_0(c_7, q_1);
    float _S29 = convTowerHeight_0(c_7, _S28);
    if(_S29 <= 0.0f)
    {
        return 0.0f;
    }
    float _S30 = convLift_0(c_7, above_1);
    float _S31 = _S29 - above_1;
    if((_S31 + _S30) <= 0.0f)
    {
        return 0.0f;
    }
    float inside_0;
    if((_S31 - _S30) >= 12.0f)
    {
        inside_0 = 12.0f;
    }
    else
    {
        float _S32 = convBillow_0(c_7, make_float3 (q_1.x, _S26, q_1.y));
        float inside_1 = _S31 + _S30 * _S32;
        if(inside_1 <= 0.0f)
        {
            return 0.0f;
        }
        inside_0 = inside_1;
    }
    return c_7->cvSigma_0 * (F32_sqrt((saturate_0(above_1 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_0);
}

extern "C" __global__ void convDensityAt(ConvectionInput_0 c_8, StructuredBuffer<float3 > points_0, RWStructuredBuffer<float> outDensity_0, int count_0)
{
    int i_7 = int((blockIdx * blockDim + threadIdx).x);
    if(i_7 >= count_0)
    {
        return;
    }
    float * _S33 = (&(outDensity_0)[i_7]);
    float3  _S34 = slang_ldg_0((&(points_0)[i_7]));
    ConvectionInput_0 _S35 = c_8;
    float _S36 = convectionDensity_0(&_S35, _S34);
    *_S33 = _S36;
    return;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_9, int2  slot_3, float2  a_0, float2  b_0, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S37 = convVigour_0(c_9, slot_3);
    if(_S37 <= 0.0f)
    {
        return;
    }
    float2  ctr_0 = convCellCentre_0(slot_3);
    float2  _S38 = a_0 - ctr_0;
    float2  nearGap_0 = max_0(max_0(_S38, ctr_0 - b_0), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_0(abs_0(_S38), abs_0(b_0 - ctr_0));
    float oHi_0 = _S37 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S37 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S37 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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

static __device__ float convUpdraftBound_0(ConvectionInput_0 * c_10, float2  q0_0, float2  q1_0)
{
    float2  a_1 = q0_0 / make_float2 (c_10->cvSpacing_0);
    float2  b_1 = q1_0 / make_float2 (c_10->cvSpacing_0);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    float2  _S39 = floor_1((a_1 + b_1) * make_float2 (0.5f));
    int2  _S40 = make_int2 ((int)_S39.x, (int)_S39.y);
    float2  _S41 = make_float2 ((float)_S40.x, (float)_S40.y);
    float2  highEdge_0 = _S41 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S42;
    if(all_0(a_1 >= (_S41 - make_float2 (0.00009999999747379f))))
    {
        _S42 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S42 = false;
    }
    int j_2;
    int i_8;
    if(_S42)
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
                convSlotBound_0(c_10, _S40 + make_int2 (i_8, j_2), a_1, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_8 = i_8 + int(1);
            }
            j_2 = j_2 + int(1);
        }
    }
    else
    {
        float2  _S43 = floor_1(a_1);
        int2  _S44 = make_int2 ((int)_S43.x, (int)_S43.y);
        int2  _S45 = make_int2 (int(1), int(1));
        int2  i0_0 = _S44 - _S45;
        float2  _S46 = floor_1(b_1);
        int2  _S47 = make_int2 ((int)_S46.x, (int)_S46.y);
        int2  _S48 = _S47 + _S45;
        int _S49 = i0_0.y;
        j_2 = _S49;
        for(;;)
        {
            if(j_2 <= (_S48.y))
            {
                _S42 = j_2 <= (_S49 + int(32));
            }
            else
            {
                _S42 = false;
            }
            if(_S42)
            {
            }
            else
            {
                break;
            }
            int _S50 = i0_0.x;
            i_8 = _S50;
            for(;;)
            {
                bool _S51;
                if(i_8 <= (_S48.x))
                {
                    _S51 = i_8 <= (_S50 + int(32));
                }
                else
                {
                    _S51 = false;
                }
                if(_S51)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_10, make_int2 (i_8, j_2), a_1, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_8 = i_8 + int(1);
            }
            j_2 = j_2 + int(1);
        }
    }
    return lerp_0((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_10->cvPolarity_0) + 0.00000999999974738f;
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_11, float3  lo_0, float3  hi_0)
{
    float low_0 = lo_0.y - c_11->cvBase_0;
    float high_0 = hi_0.y - c_11->cvBase_0;
    float ceiling_0 = c_11->cvDepth_0 + c_11->cvBillow_0;
    bool _S52;
    if(high_0 < 0.0f)
    {
        _S52 = true;
    }
    else
    {
        _S52 = low_0 > ceiling_0;
    }
    if(_S52)
    {
        return 0.0f;
    }
    float _S53 = (F32_max((low_0), (0.0f)));
    float _S54 = (F32_min((high_0), (ceiling_0)));
    float _S55 = convUpdraftBound_0(c_11, float2 {lo_0.x, lo_0.z} - c_11->cvDrift_0, float2 {hi_0.x, hi_0.z} - c_11->cvDrift_0);
    float _S56 = convTowerHeight_0(c_11, _S55);
    if(_S56 <= 0.0f)
    {
        return 0.0f;
    }
    float _S57 = convLift_0(c_11, _S54);
    float inside_2 = _S56 - _S53 + _S57 + 0.00100000004749745f;
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_11->cvSigma_0 * (F32_sqrt((saturate_0(_S54 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2) * 1.00001001358032227f;
}

extern "C" __global__ void convBoundOver(ConvectionInput_0 c_12, StructuredBuffer<float3 > boxLo_0, StructuredBuffer<float3 > boxHi_0, RWStructuredBuffer<float> outBound_0, int count_1)
{
    int i_9 = int((blockIdx * blockDim + threadIdx).x);
    if(i_9 >= count_1)
    {
        return;
    }
    float * _S58 = (&(outBound_0)[i_9]);
    float3  _S59 = slang_ldg_0((&(boxLo_0)[i_9]));
    float3  _S60 = slang_ldg_0((&(boxHi_0)[i_9]));
    ConvectionInput_0 _S61 = c_12;
    float _S62 = convectionBound_0(&_S61, _S59, _S60);
    *_S58 = _S62;
    return;
}

extern "C" __global__ void convUpdraftAt(ConvectionInput_0 c_13, StructuredBuffer<float2 > points_1, RWStructuredBuffer<float> outUpdraft_0, int count_2)
{
    int i_10 = int((blockIdx * blockDim + threadIdx).x);
    if(i_10 >= count_2)
    {
        return;
    }
    float * _S63 = (&(outUpdraft_0)[i_10]);
    float2  _S64 = __ldg((&(points_1)[i_10]));
    ConvectionInput_0 _S65 = c_13;
    float _S66 = convUpdraft_0(&_S65, _S64);
    *_S63 = _S66;
    return;
}

extern "C" __global__ void convCells(ConvectionInput_0 c_14, StructuredBuffer<int2 > slots_0, RWStructuredBuffer<float3 > outCell_0, int count_3)
{
    int i_11 = int((blockIdx * blockDim + threadIdx).x);
    if(i_11 >= count_3)
    {
        return;
    }
    int2  _S67 = __ldg((&(slots_0)[i_11]));
    float2  ctr_1 = convCellCentre_0(_S67);
    float3  * _S68 = (&(outCell_0)[i_11]);
    float _S69 = ctr_1.x;
    float _S70 = ctr_1.y;
    int2  _S71 = __ldg((&(slots_0)[i_11]));
    ConvectionInput_0 _S72 = c_14;
    float _S73 = convVigour_0(&_S72, _S71);
    *_S68 = make_float3 (_S69, _S70, _S73);
    return;
}

extern "C" __global__ void convBillowAt(ConvectionInput_0 c_15, StructuredBuffer<float3 > points_2, RWStructuredBuffer<float> outBillow_0, int count_4)
{
    int i_12 = int((blockIdx * blockDim + threadIdx).x);
    if(i_12 >= count_4)
    {
        return;
    }
    float * _S74 = (&(outBillow_0)[i_12]);
    float3  _S75 = slang_ldg_0((&(points_2)[i_12]));
    ConvectionInput_0 _S76 = c_15;
    float _S77 = convBillow_0(&_S76, _S75);
    *_S74 = _S77;
    return;
}

extern "C" __global__ void convUpdraftWide(ConvectionInput_0 c_16, StructuredBuffer<float2 > points_3, RWStructuredBuffer<float> outUpdraft_1, int count_5)
{
    int i_13 = int((blockIdx * blockDim + threadIdx).x);
    if(i_13 >= count_5)
    {
        return;
    }
    float2  _S78 = __ldg((&(points_3)[i_13]));
    float2  g_1 = _S78 / make_float2 (c_16.cvSpacing_0);
    float2  _S79 = floor_1(g_1);
    int2  _S80 = make_int2 ((int)_S79.x, (int)_S79.y);
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
            int2  slot_4 = _S80 + make_int2 (di_0, dj_0);
            ConvectionInput_0 _S81 = c_16;
            float _S82 = convVigour_0(&_S81, slot_4);
            if(_S82 <= 0.0f)
            {
                di_0 = di_0 + int(1);
                continue;
            }
            float2  d_2 = g_1 - convCellCentre_0(slot_4);
            float d2_2 = dot_1(d_2, d_2);
            float ko_1 = _S82 * convBump_0(d2_2, 0.75f);
            float kk_1 = _S82 * convBump_0(d2_2, 1.04999995231628418f);
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
                float _S83 = oTop_5;
                oTop_5 = oTop_4;
                oNext_5 = _S83;
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
                float _S84 = kTop_5;
                kTop_5 = kTop_4;
                kNext_5 = _S84;
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
    *(&(outUpdraft_1)[i_13]) = lerp_0((F32_min((oNext_3 / 0.31000000238418579f), (1.0f))), kTop_3 - kNext_3, c_16.cvPolarity_0);
    return;
}

