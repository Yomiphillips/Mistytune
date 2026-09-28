// GENERATED FROM Generator.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

static __device__ float clamp_0(float x_0, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_0), (minBound_0)))), (maxBound_0)));
}

static __device__ float saturate_0(float x_1)
{
    return clamp_0(x_1, 0.0f, 1.0f);
}

static __device__ float dot_0(float2  x_2, float2  y_0)
{
    return x_2.x * y_0.x + x_2.y * y_0.y;
}

static __device__ float2  max_0(float2  x_3, float2  y_1)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_max((_slang_vector_get_element(x_3, i_0)), (_slang_vector_get_element(y_1, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ float2  min_0(float2  x_4, float2  y_2)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_min((_slang_vector_get_element(x_4, i_1)), (_slang_vector_get_element(y_2, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ float lerp_0(float x_5, float y_3, float s_0)
{
    return x_5 + (y_3 - x_5) * s_0;
}

static __device__ float dot_1(float3  x_6, float3  y_4)
{
    return x_6.x * y_4.x + x_6.y * y_4.y + x_6.z * y_4.z;
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

static __device__ float smoothstep_0(float min_1, float max_1, float x_8)
{
    float _S1 = saturate_0((x_8 - min_1) / (max_1 - min_1));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static __device__ float length_0(float2  x_9)
{
    return (F32_sqrt((dot_0(x_9, x_9))));
}

static __device__ float2  floor_1(float2  x_10)
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
        *_slang_vector_get_element_ptr(&result_3, i_3) = (F32_floor((_slang_vector_get_element(x_10, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ float2  lerp_1(float2  x_11, float2  y_5, float2  s_1)
{
    return x_11 + (y_5 - x_11) * s_1;
}

static __device__ int clamp_1(int x_12, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_12), (minBound_1)))), (maxBound_1)));
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
};

static __device__ float2  driftAt_0(GeneratorInput_0 * g_0, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_13 = clamp_0(depth_0 / g_0->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_4 = clamp_1(int((F32_floor((x_13)))), int(0), int(31));
    float2  _S2 = __ldg((&(disp_0)[i_4]));
    float2  _S3 = __ldg((&(disp_0)[i_4 + int(1)]));
    return lerp_1(_S2, _S3, make_float2 (x_13 - float(i_4)));
}

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S4 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S5 = _S4;
    *&((&_S5)->x) = *&((&_S5)->x) + _S4.y * 1664525U;
    *&((&_S5)->y) = *&((&_S5)->y) + _S5.x * 1664525U;
    uint2  _S6 = _S5 ^ (_S5 >> make_uint2 (16U));
    _S5 = _S6;
    *&((&_S5)->x) = *&((&_S5)->x) + _S6.y * 1664525U;
    *&((&_S5)->y) = *&((&_S5)->y) + _S5.x * 1664525U;
    uint2  _S7 = _S5 ^ (_S5 >> make_uint2 (16U));
    _S5 = _S7;
    return _S7;
}

static __device__ float2  hash22_0(int2  c_0, uint salt_0)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_0.x), uint(c_0.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S8 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S8 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float cellField_0(GeneratorInput_0 * g_1, float2  q_0)
{
    float2  gq_0 = (q_0 - g_1->cellDrift_0) / make_float2 (g_1->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(gq_0);
    int2  _S9 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    int j_0 = int(-1);
    float acc_0 = 0.0f;
    for(;;)
    {
        if(j_0 <= int(1))
        {
        }
        else
        {
            break;
        }
        int i_5 = int(-1);
        float acc_1 = acc_0;
        for(;;)
        {
            if(i_5 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_0 = _S9 + make_int2 (i_5, j_0);
            if((hash22_0(o_0, 2654435769U).x) > (g_1->cellDensity_0))
            {
                i_5 = i_5 + int(1);
                continue;
            }
            float2  _S10 = make_float2 ((float)o_0.x, (float)o_0.y);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(gq_0 - (_S10 + make_float2 (0.5f) + (hash22_0(o_0, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f))) * 2.20000004768371582f);
            i_5 = i_5 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_1->cellStrength_0;
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S11 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S12 = _S11;
    *&((&_S12)->x) = *&((&_S12)->x) + _S11.y * _S11.z;
    *&((&_S12)->y) = *&((&_S12)->y) + _S12.z * _S12.x;
    *&((&_S12)->z) = *&((&_S12)->z) + _S12.x * _S12.y;
    uint3  _S13 = _S12 ^ (_S12 >> make_uint3 (16U));
    _S12 = _S13;
    *&((&_S12)->x) = *&((&_S12)->x) + _S13.y * _S13.z;
    *&((&_S12)->y) = *&((&_S12)->y) + _S12.z * _S12.x;
    *&((&_S12)->z) = *&((&_S12)->z) + _S12.x * _S12.y;
    return _S12;
}

static __device__ float3  hash33_0(int3  c_1)
{
    uint3  h_1 = pcg3d_0(make_uint3 (uint(c_1.x), uint(c_1.y), uint(c_1.z)));
    float3  _S14 = make_float3 ((float)h_1.x, (float)h_1.y, (float)h_1.z);
    return _S14 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_0(p_0);
    int3  _S15 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S16 = u_0.x;
    float _S17 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_1(hash33_0(_S15), f_0), dot_1(hash33_0(_S15 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S16), lerp_0(dot_1(hash33_0(_S15 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S15 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S16), _S17), lerp_0(lerp_0(dot_1(hash33_0(_S15 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S15 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S16), lerp_0(dot_1(hash33_0(_S15 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S15 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S16), _S17), u_0.z);
}

static __device__ float fbm_0(float3  p_1, int octaves_1)
{
    int i_6 = int(0);
    float amp_0 = 0.5f;
    float3  _S18 = p_1;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_6 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_6 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S18);
        float norm_1 = norm_0 + amp_0;
        float3  _S19 = _S18 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_6 = i_6 + int(1);
        amp_0 = amp_1;
        _S18 = _S19;
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

static __device__ float iceDensity_0(GeneratorInput_0 * g_2, StructuredBuffer<float2 > disp_1, float3  p_2)
{
    float depth_1 = g_2->cellAltitude_0 - p_2.y;
    bool _S20;
    if(depth_1 < 0.0f)
    {
        _S20 = true;
    }
    else
    {
        _S20 = depth_1 > (g_2->streakLength_0);
    }
    if(_S20)
    {
        return 0.0f;
    }
    float2  _S21 = float2 {p_2.x, p_2.z};
    float2  _S22 = driftAt_0(g_2, disp_1, depth_1);
    float2  source_0 = _S21 - _S22;
    float _S23 = cellField_0(g_2, source_0);
    if(_S23 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S23 * (F32_exp((- g_2->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_2->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_2->streakLength_0, g_2->streakLength_0, depth_1)) * (F32_max((1.0f + g_2->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_2->detailScale_0)).x, (source_0 / make_float2 (g_2->detailScale_0)).y, depth_1 / (F32_max((g_2->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_2->timeSeconds_0 * 0.00999999977648258f), g_2->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_2->opticalDepth_0 / (F32_max((g_2->streakLength_0), (1.0f)));
}

extern "C" __global__ void densityColumn(GeneratorInput_0 g_3, StructuredBuffer<float2 > disp_2, float2  columnXZ_0, RWStructuredBuffer<float> output_0, int count_0)
{
    int i_7 = int((blockIdx * blockDim + threadIdx).x);
    if(i_7 >= count_0)
    {
        return;
    }
    float3  p_3 = make_float3 (columnXZ_0.x, g_3.cellAltitude_0 - (float(i_7) + 0.5f) * (g_3.streakLength_0 / float(count_0)), columnXZ_0.y);
    float * _S24 = (&(output_0)[i_7]);
    GeneratorInput_0 _S25 = g_3;
    float _S26 = iceDensity_0(&_S25, disp_2, p_3);
    *_S24 = _S26;
    return;
}

extern "C" __global__ void densityPlane(GeneratorInput_0 g_4, StructuredBuffer<float2 > disp_3, float depth_2, float extent_0, RWStructuredBuffer<float> output_1, int side_0)
{
    uint3  _S27 = blockIdx * blockDim + threadIdx;
    int x_14 = int(_S27.x);
    int y_6 = int(_S27.y);
    bool _S28;
    if(x_14 >= side_0)
    {
        _S28 = true;
    }
    else
    {
        _S28 = y_6 >= side_0;
    }
    if(_S28)
    {
        return;
    }
    float _S29 = float(side_0);
    float _S30 = extent_0 * 0.5f;
    float * _S31 = (&(output_1)[y_6 * side_0 + x_14]);
    float3  _S32 = make_float3 ((float(x_14) + 0.5f) / _S29 * extent_0 - _S30, g_4.cellAltitude_0 - depth_2, (float(y_6) + 0.5f) / _S29 * extent_0 - _S30);
    GeneratorInput_0 _S33 = g_4;
    float _S34 = iceDensity_0(&_S33, disp_3, _S32);
    *_S31 = _S34;
    return;
}

static __device__ void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<float2 > disp_4, float d0_0, float d1_0, float2  * lo_0, float2  * hi_0)
{
    float2  _S35 = driftAt_0(g_5, disp_4, d0_0);
    *lo_0 = _S35;
    *hi_0 = _S35;
    float2  _S36 = driftAt_0(g_5, disp_4, d1_0);
    *lo_0 = min_0(*lo_0, _S36);
    *hi_0 = max_0(*hi_0, _S36);
    int _S37 = clamp_1(int((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_0 = clamp_1(int((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_0 <= _S37)
        {
        }
        else
        {
            break;
        }
        float2  _S38 = *lo_0;
        float2  _S39 = __ldg((&(disp_4)[k_0]));
        *lo_0 = min_0(_S38, _S39);
        float2  _S40 = *hi_0;
        float2  _S41 = __ldg((&(disp_4)[k_0]));
        *hi_0 = max_0(_S40, _S41);
        k_0 = k_0 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_6, float2  q0_0, float2  q1_0)
{
    float spacing_0 = g_6->cellSize_0 * 2.20000004768371582f;
    float2  a_0 = (q0_0 - g_6->cellDrift_0) / make_float2 (spacing_0);
    float2  b_0 = (q1_0 - g_6->cellDrift_0) / make_float2 (spacing_0);
    float2  _S42 = floor_1(a_0);
    int2  _S43 = make_int2 ((int)_S42.x, (int)_S42.y);
    int2  _S44 = make_int2 (int(1), int(1));
    int2  i0_0 = _S43 - _S44;
    float2  _S45 = floor_1(b_0);
    int2  _S46 = make_int2 ((int)_S45.x, (int)_S45.y);
    int2  _S47 = _S46 + _S44;
    int _S48 = i0_0.y;
    int j_1 = _S48;
    float acc_2 = 0.0f;
    for(;;)
    {
        bool _S49;
        if(j_1 <= (_S47.y))
        {
            _S49 = j_1 <= (_S48 + int(32));
        }
        else
        {
            _S49 = false;
        }
        if(_S49)
        {
        }
        else
        {
            break;
        }
        int _S50 = i0_0.x;
        int i_8 = _S50;
        float acc_3 = acc_2;
        for(;;)
        {
            bool _S51;
            if(i_8 <= (_S47.x))
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
            int2  o_1 = make_int2 (i_8, j_1);
            if((hash22_0(o_1, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_8 = i_8 + int(1);
                continue;
            }
            float2  _S52 = make_float2 ((float)o_1.x, (float)o_1.y);
            float2  c_2 = _S52 + make_float2 (0.5f) + (hash22_0(o_1, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_0(max_0(a_0 - c_2, c_2 - b_0), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_8 = i_8 + int(1);
        }
        j_1 = j_1 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_6->cellStrength_0;
}

static __device__ float iceDensityBound_0(GeneratorInput_0 * g_7, StructuredBuffer<float2 > disp_5, float3  lo_1, float3  hi_1)
{
    float d0_1 = g_7->cellAltitude_0 - hi_1.y;
    float d1_1 = g_7->cellAltitude_0 - lo_1.y;
    bool _S53;
    if(d1_1 < 0.0f)
    {
        _S53 = true;
    }
    else
    {
        _S53 = d0_1 > (g_7->streakLength_0);
    }
    if(_S53)
    {
        return 0.0f;
    }
    float _S54 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_7, disp_5, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S55 = cellFieldBound_0(g_7, make_float2 (lo_1.x, lo_1.z) - driftHi_0, make_float2 (hi_1.x, hi_1.z) - driftLo_0);
    return (F32_max((_S55 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S54), (1.0f)));
}

extern "C" __global__ void cellBound(GeneratorInput_0 g_8, StructuredBuffer<float2 > disp_6, float3  gridOrigin_0, float3  cellSize_1, int3  dims_0, RWStructuredBuffer<float> outBound_0, int cellCount_0)
{
    int i_9 = int((blockIdx * blockDim + threadIdx).x);
    if(i_9 >= cellCount_0)
    {
        return;
    }
    int _S56 = dims_0.x;
    int cx_0 = i_9 % _S56;
    int _S57 = i_9 / _S56;
    int _S58 = dims_0.y;
    int cy_0 = _S57 % _S58;
    int cz_0 = i_9 / (_S56 * _S58);
    float3  lo_2 = gridOrigin_0 + make_float3 (float(cx_0), float(cy_0), float(cz_0)) * cellSize_1;
    float * _S59 = (&(outBound_0)[i_9]);
    float3  _S60 = lo_2 + cellSize_1;
    GeneratorInput_0 _S61 = g_8;
    float _S62 = iceDensityBound_0(&_S61, disp_6, lo_2, _S60);
    *_S59 = _S62;
    return;
}

extern "C" __global__ void cellMax(GeneratorInput_0 g_9, StructuredBuffer<float2 > disp_7, float3  gridOrigin_1, float3  cellSize_2, int3  dims_1, int samplesPerAxis_0, RWStructuredBuffer<float> outMax_0, int cellCount_1)
{
    int i_10 = int((blockIdx * blockDim + threadIdx).x);
    if(i_10 >= cellCount_1)
    {
        return;
    }
    int _S63 = dims_1.x;
    int cx_1 = i_10 % _S63;
    int _S64 = i_10 / _S63;
    int _S65 = dims_1.y;
    int cy_1 = _S64 % _S65;
    int cz_1 = i_10 / (_S63 * _S65);
    float3  _S66 = gridOrigin_1 + make_float3 (float(cx_1), float(cy_1), float(cz_1)) * cellSize_2;
    float m_0 = 0.0f;
    int a_1 = int(0);
    for(;;)
    {
        if(a_1 < samplesPerAxis_0)
        {
        }
        else
        {
            break;
        }
        int b_1 = int(0);
        for(;;)
        {
            if(b_1 < samplesPerAxis_0)
            {
            }
            else
            {
                break;
            }
            float m_1 = m_0;
            int c_3 = int(0);
            for(;;)
            {
                if(c_3 < samplesPerAxis_0)
                {
                }
                else
                {
                    break;
                }
                float3  _S67 = _S66 + (make_float3 (float(a_1), float(b_1), float(c_3)) + make_float3 (0.5f)) / make_float3 (float(samplesPerAxis_0)) * cellSize_2;
                GeneratorInput_0 _S68 = g_9;
                float _S69 = iceDensity_0(&_S68, disp_7, _S67);
                float _S70 = (F32_max((m_1), (_S69)));
                int c_4 = c_3 + int(1);
                m_1 = _S70;
                c_3 = c_4;
            }
            int b_2 = b_1 + int(1);
            m_0 = m_1;
            b_1 = b_2;
        }
        a_1 = a_1 + int(1);
    }
    *(&(outMax_0)[i_10]) = m_0;
    return;
}

extern "C" __global__ void hashTrial(RWStructuredBuffer<float> output_2, int count_1)
{
    int i_11 = int((blockIdx * blockDim + threadIdx).x);
    if(i_11 >= count_1)
    {
        return;
    }
    *(&(output_2)[i_11]) = hash22_0(make_int2 (i_11, i_11 * int(7) + int(3)), 0U).x;
    return;
}

extern "C" __global__ void cellFieldPlane(GeneratorInput_0 g_10, float2  origin_0, float span_0, RWStructuredBuffer<float> output_3, int side_1)
{
    uint3  _S71 = blockIdx * blockDim + threadIdx;
    int x_15 = int(_S71.x);
    int y_7 = int(_S71.y);
    bool _S72;
    if(x_15 >= side_1)
    {
        _S72 = true;
    }
    else
    {
        _S72 = y_7 >= side_1;
    }
    if(_S72)
    {
        return;
    }
    float _S73 = float(side_1);
    float * _S74 = (&(output_3)[y_7 * side_1 + x_15]);
    float2  _S75 = make_float2 (origin_0.x + (float(x_15) + 0.5f) / _S73 * span_0, origin_0.y + (float(y_7) + 0.5f) / _S73 * span_0);
    GeneratorInput_0 _S76 = g_10;
    float _S77 = cellField_0(&_S76, _S75);
    *_S74 = _S77;
    return;
}

extern "C" __global__ void cellGeometry(RWStructuredBuffer<float> output_4, int count_2)
{
    bool _S78;
    if(int((blockIdx * blockDim + threadIdx).x) != int(0))
    {
        _S78 = true;
    }
    else
    {
        _S78 = count_2 < int(6);
    }
    if(_S78)
    {
        return;
    }
    *(&(output_4)[int(0)]) = 2.20000004768371582f;
    *(&(output_4)[int(1)]) = 0.80000001192092896f;
    *(&(output_4)[int(2)]) = 1.0f;
    *(&(output_4)[int(3)]) = 0.05000000074505806f;
    float corner_0 = (F32_sqrt((0.01999999769032001f))) * 2.20000004768371582f;
    *(&(output_4)[int(4)]) = 4.0f * smoothstep_0(1.0f, 0.05000000074505806f, corner_0);
    *(&(output_4)[int(5)]) = corner_0;
    return;
}

