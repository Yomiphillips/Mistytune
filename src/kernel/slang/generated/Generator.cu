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

static __device__ float2  max_0(float2  x_2, float2  y_0)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_max((_slang_vector_get_element(x_2, i_0)), (_slang_vector_get_element(y_0, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ float2  min_0(float2  x_3, float2  y_1)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_min((_slang_vector_get_element(x_3, i_1)), (_slang_vector_get_element(y_1, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ float smoothstep_0(float min_1, float max_1, float x_4)
{
    float _S1 = saturate_0((x_4 - min_1) / (max_1 - min_1));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static __device__ float dot_0(float2  x_5, float2  y_2)
{
    return x_5.x * y_2.x + x_5.y * y_2.y;
}

static __device__ float length_0(float2  x_6)
{
    return (F32_sqrt((dot_0(x_6, x_6))));
}

static __device__ float2  floor_0(float2  x_7)
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

static __device__ float lerp_0(float x_8, float y_3, float s_0)
{
    return x_8 + (y_3 - x_8) * s_0;
}

static __device__ float dot_1(float3  x_9, float3  y_4)
{
    return x_9.x * y_4.x + x_9.y * y_4.y + x_9.z * y_4.z;
}

static __device__ float3  floor_1(float3  x_10)
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

static __device__ float2  driftAt_0(GeneratorInput_0 * g_0, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_13 = clamp_0(depth_0 / g_0->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_4 = clamp_1(int((F32_floor((x_13)))), int(0), int(31));
    float2  _S2 = __ldg((&(disp_0)[i_4]));
    float2  _S3 = __ldg((&(disp_0)[i_4 + int(1)]));
    return lerp_1(_S2, _S3, make_float2 (x_13 - float(i_4)));
}

static __device__ uint3  pcg3d_0(uint3  v_0)
{
    uint3  _S4 = v_0 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S5 = _S4;
    *&((&_S5)->x) = *&((&_S5)->x) + _S4.y * _S4.z;
    *&((&_S5)->y) = *&((&_S5)->y) + _S5.z * _S5.x;
    *&((&_S5)->z) = *&((&_S5)->z) + _S5.x * _S5.y;
    uint3  _S6 = _S5 ^ (_S5 >> make_uint3 (16U));
    _S5 = _S6;
    *&((&_S5)->x) = *&((&_S5)->x) + _S6.y * _S6.z;
    *&((&_S5)->y) = *&((&_S5)->y) + _S5.z * _S5.x;
    *&((&_S5)->z) = *&((&_S5)->z) + _S5.x * _S5.y;
    return _S5;
}

static __device__ float3  hash33_0(int3  c_0)
{
    uint3  h_0 = pcg3d_0(make_uint3 (uint(c_0.x), uint(c_0.y), uint(c_0.z)));
    float3  _S7 = make_float3 ((float)h_0.x, (float)h_0.y, (float)h_0.z);
    return _S7 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_0)
{
    float3  fi_0 = floor_1(p_0);
    int3  _S8 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_0 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S9 = u_0.x;
    float _S10 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_1(hash33_0(_S8), f_0), dot_1(hash33_0(_S8 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S9), lerp_0(dot_1(hash33_0(_S8 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S8 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S9), _S10), lerp_0(lerp_0(dot_1(hash33_0(_S8 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S8 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S9), lerp_0(dot_1(hash33_0(_S8 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S8 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S9), _S10), u_0.z);
}

static __device__ float2  orgWarpOffset_0(Organization_0 * o_0, float2  g_1)
{
    float2  s_2 = g_1 / make_float2 (2.5f);
    float _S11 = s_2.x;
    float _S12 = s_2.y;
    return make_float2 (o_0->ogWarp_0) * make_float2 (gradientNoise_0(make_float3 (_S11, 0.37000000476837158f, _S12)), gradientNoise_0(make_float3 (_S11 + 17.10000038146972656f, 5.82999992370605469f, _S12 - 9.39999961853027344f)));
}

static __device__ float2  orgPattern_0(Organization_0 * o_1, float2  q_0, float spacing_0)
{
    if((o_1->ogOn_0) == int(0))
    {
        return q_0 / make_float2 (spacing_0);
    }
    float2  g_2 = make_float2 (dot_0(q_0, o_1->ogAxis_0), dot_0(q_0, make_float2 (- o_1->ogAxis_0.y, o_1->ogAxis_0.x))) / make_float2 (spacing_0 * o_1->ogStretch_0, spacing_0);
    float2  g_3;
    if((o_1->ogWarp_0) > 0.0f)
    {
        float2  _S13 = orgWarpOffset_0(o_1, g_2);
        g_3 = g_2 + _S13;
    }
    else
    {
        g_3 = g_2;
    }
    return g_3;
}

static __device__ float2  orgJitter_0(Organization_0 * o_2, float jitter_0)
{
    float _S14;
    if((o_2->ogOn_0) != int(0))
    {
        _S14 = jitter_0 * (1.0f - o_2->ogCoherence_0);
    }
    else
    {
        _S14 = jitter_0;
    }
    return make_float2 (jitter_0, _S14);
}

static __device__ uint2  pcg2d_0(uint2  v_1)
{
    uint2  _S15 = v_1 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S16 = _S15;
    *&((&_S16)->x) = *&((&_S16)->x) + _S15.y * 1664525U;
    *&((&_S16)->y) = *&((&_S16)->y) + _S16.x * 1664525U;
    uint2  _S17 = _S16 ^ (_S16 >> make_uint2 (16U));
    _S16 = _S17;
    *&((&_S16)->x) = *&((&_S16)->x) + _S17.y * 1664525U;
    *&((&_S16)->y) = *&((&_S16)->y) + _S16.x * 1664525U;
    uint2  _S18 = _S16 ^ (_S16 >> make_uint2 (16U));
    _S16 = _S18;
    return _S18;
}

static __device__ float2  hash22_0(int2  c_1, uint salt_0)
{
    uint2  h_1 = pcg2d_0(make_uint2 (uint(c_1.x), uint(c_1.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S19 = make_float2 ((float)h_1.x, (float)h_1.y);
    return _S19 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float orgWave_0(Organization_0 * o_3, float2  q_1, float2  * grad_0)
{
    *grad_0 = make_float2 (0.0f, 0.0f);
    bool _S20;
    if((o_3->ogOn_0) == int(0))
    {
        _S20 = true;
    }
    else
    {
        _S20 = (o_3->ogWaveAmp_0) <= 0.0f;
    }
    if(_S20)
    {
        return 1.0f;
    }
    float2  _S21 = o_3->ogWaveK_0;
    float s_3 = 2.0f * (F32_frac((dot_0(q_1, o_3->ogWaveK_0)))) - 1.0f;
    float tri_0 = 1.0f - (F32_abs((s_3)));
    float crest_0 = tri_0 * tri_0 * (3.0f - 2.0f * tri_0);
    float dCrest_0 = 6.0f * tri_0 * (1.0f - tri_0);
    float dTri_0;
    if(s_3 > 0.0f)
    {
        dTri_0 = -2.0f;
    }
    else
    {
        dTri_0 = 2.0f;
    }
    float _S22 = o_3->ogWaveAmp_0;
    *grad_0 = _S21 * make_float2 (o_3->ogWaveAmp_0 * dCrest_0 * dTri_0);
    return 1.0f - _S22 * (1.0f - crest_0);
}

static __device__ float orgWaveFactor_0(Organization_0 * o_4, float2  q_2)
{
    float2  unused_0;
    float _S23 = orgWave_0(o_4, q_2, &unused_0);
    return _S23;
}

static __device__ float cellField_0(GeneratorInput_0 * g_4, float2  q_3)
{
    float2  _S24 = q_3 - g_4->cellDrift_0;
    float2  _S25 = orgPattern_0(&g_4->gnOrg_0, _S24, g_4->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_0(_S25);
    int2  _S26 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    float2  _S27 = orgJitter_0(&g_4->gnOrg_0, 0.80000001192092896f);
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
            int2  o_5 = _S26 + make_int2 (i_5, j_0);
            if((hash22_0(o_5, 2654435769U).x) > (g_4->cellDensity_0))
            {
                i_5 = i_5 + int(1);
                continue;
            }
            float2  _S28 = make_float2 ((float)o_5.x, (float)o_5.y);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(_S25 - (_S28 + make_float2 (0.5f) + (hash22_0(o_5, 0U) - make_float2 (0.5f)) * _S27)) * 2.20000004768371582f);
            i_5 = i_5 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    float _S29 = acc_0 * g_4->cellStrength_0;
    float _S30 = orgWaveFactor_0(&g_4->gnOrg_0, _S24);
    return _S29 * _S30;
}

static __device__ float fbm_0(float3  p_1, int octaves_1)
{
    int i_6 = int(0);
    float amp_0 = 0.5f;
    float3  _S31 = p_1;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S31);
        float norm_1 = norm_0 + amp_0;
        float3  _S32 = _S31 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_6 = i_6 + int(1);
        amp_0 = amp_1;
        _S31 = _S32;
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
    bool _S33;
    if(depth_1 < 0.0f)
    {
        _S33 = true;
    }
    else
    {
        _S33 = depth_1 > (g_5->streakLength_0);
    }
    if(_S33)
    {
        return 0.0f;
    }
    float2  _S34 = float2 {p_2.x, p_2.z};
    float2  _S35 = driftAt_0(g_5, disp_1, depth_1);
    float2  source_0 = _S34 - _S35;
    float _S36 = cellField_0(g_5, source_0);
    if(_S36 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S36 * (F32_exp((- g_5->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_5->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_5->streakLength_0, g_5->streakLength_0, depth_1)) * (F32_max((1.0f + g_5->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_5->detailScale_0)).x, (source_0 / make_float2 (g_5->detailScale_0)).y, depth_1 / (F32_max((g_5->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_5->timeSeconds_0 * 0.00999999977648258f), g_5->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_5->opticalDepth_0 / (F32_max((g_5->streakLength_0), (1.0f)));
}

extern "C" __global__ void densityColumn(GeneratorInput_0 g_6, StructuredBuffer<float2 > disp_2, float2  columnXZ_0, RWStructuredBuffer<float> output_0, int count_0)
{
    int i_7 = int((blockIdx * blockDim + threadIdx).x);
    if(i_7 >= count_0)
    {
        return;
    }
    float3  p_3 = make_float3 (columnXZ_0.x, g_6.cellAltitude_0 - (float(i_7) + 0.5f) * (g_6.streakLength_0 / float(count_0)), columnXZ_0.y);
    float * _S37 = (&(output_0)[i_7]);
    GeneratorInput_0 _S38 = g_6;
    float _S39 = iceDensity_0(&_S38, disp_2, p_3);
    *_S37 = _S39;
    return;
}

extern "C" __global__ void densityPlane(GeneratorInput_0 g_7, StructuredBuffer<float2 > disp_3, float depth_2, float extent_0, RWStructuredBuffer<float> output_1, int side_0)
{
    uint3  _S40 = blockIdx * blockDim + threadIdx;
    int x_14 = int(_S40.x);
    int y_6 = int(_S40.y);
    bool _S41;
    if(x_14 >= side_0)
    {
        _S41 = true;
    }
    else
    {
        _S41 = y_6 >= side_0;
    }
    if(_S41)
    {
        return;
    }
    float _S42 = float(side_0);
    float _S43 = extent_0 * 0.5f;
    float * _S44 = (&(output_1)[y_6 * side_0 + x_14]);
    float3  _S45 = make_float3 ((float(x_14) + 0.5f) / _S42 * extent_0 - _S43, g_7.cellAltitude_0 - depth_2, (float(y_6) + 0.5f) / _S42 * extent_0 - _S43);
    GeneratorInput_0 _S46 = g_7;
    float _S47 = iceDensity_0(&_S46, disp_3, _S45);
    *_S44 = _S47;
    return;
}

static __device__ void driftRange_0(GeneratorInput_0 * g_8, StructuredBuffer<float2 > disp_4, float d0_0, float d1_0, float2  * lo_0, float2  * hi_0)
{
    float2  _S48 = driftAt_0(g_8, disp_4, d0_0);
    *lo_0 = _S48;
    *hi_0 = _S48;
    float2  _S49 = driftAt_0(g_8, disp_4, d1_0);
    *lo_0 = min_0(*lo_0, _S49);
    *hi_0 = max_0(*hi_0, _S49);
    int _S50 = clamp_1(int((F32_ceil((clamp_0(d1_0 / g_8->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_0 = clamp_1(int((F32_floor((clamp_0(d0_0 / g_8->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_0 <= _S50)
        {
        }
        else
        {
            break;
        }
        float2  _S51 = *lo_0;
        float2  _S52 = __ldg((&(disp_4)[k_0]));
        *lo_0 = min_0(_S51, _S52);
        float2  _S53 = *hi_0;
        float2  _S54 = __ldg((&(disp_4)[k_0]));
        *hi_0 = max_0(_S53, _S54);
        k_0 = k_0 + int(1);
    }
    return;
}

static __device__ void orgPatternBox_0(Organization_0 * o_6, float2  q0_0, float2  q1_0, float spacing_1, float2  * a_0, float2  * b_0)
{
    if((o_6->ogOn_0) == int(0))
    {
        *a_0 = q0_0 / make_float2 (spacing_1);
        *b_0 = q1_0 / make_float2 (spacing_1);
        return;
    }
    Organization_0 flat_0 = *o_6;
    (&flat_0)->ogWarp_0 = 0.0f;
    Organization_0 _S55 = flat_0;
    float2  _S56 = orgPattern_0(&_S55, q0_0, spacing_1);
    Organization_0 _S57 = flat_0;
    float2  _S58 = orgPattern_0(&_S57, q1_0, spacing_1);
    float2  _S59 = make_float2 (q0_0.x, q1_0.y);
    Organization_0 _S60 = flat_0;
    float2  _S61 = orgPattern_0(&_S60, _S59, spacing_1);
    float2  _S62 = make_float2 (q1_0.x, q0_0.y);
    Organization_0 _S63 = flat_0;
    float2  _S64 = orgPattern_0(&_S63, _S62, spacing_1);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S56.x)))), ((F32_abs((_S56.y))))))), ((F32_max(((F32_abs((_S58.x)))), ((F32_abs((_S58.y)))))))));
    *a_0 = min_0(min_0(_S56, _S61), min_0(_S64, _S58)) - make_float2 (grow_0);
    *b_0 = max_0(max_0(_S56, _S61), max_0(_S64, _S58)) + make_float2 (grow_0);
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_9, float2  q0_1, float2  q1_1)
{
    float2  a_1;
    float2  b_1;
    orgPatternBox_0(&g_9->gnOrg_0, q0_1 - g_9->cellDrift_0, q1_1 - g_9->cellDrift_0, g_9->cellSize_0 * 2.20000004768371582f, &a_1, &b_1);
    float2  _S65 = orgJitter_0(&g_9->gnOrg_0, 0.80000001192092896f);
    float2  _S66 = floor_0(a_1);
    int2  _S67 = make_int2 ((int)_S66.x, (int)_S66.y);
    int2  _S68 = make_int2 (int(1), int(1));
    int2  i0_0 = _S67 - _S68;
    float2  _S69 = floor_0(b_1);
    int2  _S70 = make_int2 ((int)_S69.x, (int)_S69.y);
    int2  _S71 = _S70 + _S68;
    int _S72 = i0_0.y;
    int j_1 = _S72;
    float acc_2 = 0.0f;
    for(;;)
    {
        bool _S73;
        if(j_1 <= (_S71.y))
        {
            _S73 = j_1 <= (_S72 + int(32));
        }
        else
        {
            _S73 = false;
        }
        if(_S73)
        {
        }
        else
        {
            break;
        }
        int _S74 = i0_0.x;
        int i_8 = _S74;
        float acc_3 = acc_2;
        for(;;)
        {
            bool _S75;
            if(i_8 <= (_S71.x))
            {
                _S75 = i_8 <= (_S74 + int(32));
            }
            else
            {
                _S75 = false;
            }
            if(_S75)
            {
            }
            else
            {
                break;
            }
            int2  o_7 = make_int2 (i_8, j_1);
            if((hash22_0(o_7, 2654435769U).x) > (g_9->cellDensity_0))
            {
                i_8 = i_8 + int(1);
                continue;
            }
            float2  _S76 = make_float2 ((float)o_7.x, (float)o_7.y);
            float2  c_2 = _S76 + make_float2 (0.5f) + (hash22_0(o_7, 0U) - make_float2 (0.5f)) * _S65;
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_0(max_0(a_1 - c_2, c_2 - b_1), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_8 = i_8 + int(1);
        }
        j_1 = j_1 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_9->cellStrength_0;
}

static __device__ float iceDensityBound_0(GeneratorInput_0 * g_10, StructuredBuffer<float2 > disp_5, float3  lo_1, float3  hi_1)
{
    float d0_1 = g_10->cellAltitude_0 - hi_1.y;
    float d1_1 = g_10->cellAltitude_0 - lo_1.y;
    bool _S77;
    if(d1_1 < 0.0f)
    {
        _S77 = true;
    }
    else
    {
        _S77 = d0_1 > (g_10->streakLength_0);
    }
    if(_S77)
    {
        return 0.0f;
    }
    float _S78 = g_10->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_10->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_10->streakLength_0);
    float subl_0 = (F32_exp((- g_10->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_10->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_10->streakLength_0, g_10->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_10->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_10, disp_5, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S79 = cellFieldBound_0(g_10, make_float2 (lo_1.x, lo_1.z) - driftHi_0, make_float2 (hi_1.x, hi_1.z) - driftLo_0);
    return (F32_max((_S79 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_10->opticalDepth_0 / (F32_max((_S78), (1.0f)));
}

extern "C" __global__ void cellBound(GeneratorInput_0 g_11, StructuredBuffer<float2 > disp_6, float3  gridOrigin_0, float3  cellSize_1, int3  dims_0, RWStructuredBuffer<float> outBound_0, int cellCount_0)
{
    int i_9 = int((blockIdx * blockDim + threadIdx).x);
    if(i_9 >= cellCount_0)
    {
        return;
    }
    int _S80 = dims_0.x;
    int cx_0 = i_9 % _S80;
    int _S81 = i_9 / _S80;
    int _S82 = dims_0.y;
    int cy_0 = _S81 % _S82;
    int cz_0 = i_9 / (_S80 * _S82);
    float3  lo_2 = gridOrigin_0 + make_float3 (float(cx_0), float(cy_0), float(cz_0)) * cellSize_1;
    float * _S83 = (&(outBound_0)[i_9]);
    float3  _S84 = lo_2 + cellSize_1;
    GeneratorInput_0 _S85 = g_11;
    float _S86 = iceDensityBound_0(&_S85, disp_6, lo_2, _S84);
    *_S83 = _S86;
    return;
}

extern "C" __global__ void cellMax(GeneratorInput_0 g_12, StructuredBuffer<float2 > disp_7, float3  gridOrigin_1, float3  cellSize_2, int3  dims_1, int samplesPerAxis_0, RWStructuredBuffer<float> outMax_0, int cellCount_1)
{
    int i_10 = int((blockIdx * blockDim + threadIdx).x);
    if(i_10 >= cellCount_1)
    {
        return;
    }
    int _S87 = dims_1.x;
    int cx_1 = i_10 % _S87;
    int _S88 = i_10 / _S87;
    int _S89 = dims_1.y;
    int cy_1 = _S88 % _S89;
    int cz_1 = i_10 / (_S87 * _S89);
    float3  _S90 = gridOrigin_1 + make_float3 (float(cx_1), float(cy_1), float(cz_1)) * cellSize_2;
    float m_0 = 0.0f;
    int a_2 = int(0);
    for(;;)
    {
        if(a_2 < samplesPerAxis_0)
        {
        }
        else
        {
            break;
        }
        int b_2 = int(0);
        for(;;)
        {
            if(b_2 < samplesPerAxis_0)
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
                float3  _S91 = _S90 + (make_float3 (float(a_2), float(b_2), float(c_3)) + make_float3 (0.5f)) / make_float3 (float(samplesPerAxis_0)) * cellSize_2;
                GeneratorInput_0 _S92 = g_12;
                float _S93 = iceDensity_0(&_S92, disp_7, _S91);
                float _S94 = (F32_max((m_1), (_S93)));
                int c_4 = c_3 + int(1);
                m_1 = _S94;
                c_3 = c_4;
            }
            int b_3 = b_2 + int(1);
            m_0 = m_1;
            b_2 = b_3;
        }
        a_2 = a_2 + int(1);
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

extern "C" __global__ void cellFieldPlane(GeneratorInput_0 g_13, float2  origin_0, float span_0, RWStructuredBuffer<float> output_3, int side_1)
{
    uint3  _S95 = blockIdx * blockDim + threadIdx;
    int x_15 = int(_S95.x);
    int y_7 = int(_S95.y);
    bool _S96;
    if(x_15 >= side_1)
    {
        _S96 = true;
    }
    else
    {
        _S96 = y_7 >= side_1;
    }
    if(_S96)
    {
        return;
    }
    float _S97 = float(side_1);
    float * _S98 = (&(output_3)[y_7 * side_1 + x_15]);
    float2  _S99 = make_float2 (origin_0.x + (float(x_15) + 0.5f) / _S97 * span_0, origin_0.y + (float(y_7) + 0.5f) / _S97 * span_0);
    GeneratorInput_0 _S100 = g_13;
    float _S101 = cellField_0(&_S100, _S99);
    *_S98 = _S101;
    return;
}

extern "C" __global__ void cellGeometry(RWStructuredBuffer<float> output_4, int count_2)
{
    bool _S102;
    if(int((blockIdx * blockDim + threadIdx).x) != int(0))
    {
        _S102 = true;
    }
    else
    {
        _S102 = count_2 < int(6);
    }
    if(_S102)
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

