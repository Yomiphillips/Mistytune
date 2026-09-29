// GENERATED FROM Render.slang BY slangc -- DO NOT EDIT.
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

static __device__ float dot_1(float3  x_3, float3  y_1)
{
    return x_3.x * y_1.x + x_3.y * y_1.y + x_3.z * y_1.z;
}

static __device__ float length_0(float3  x_4)
{
    return (F32_sqrt((dot_1(x_4, x_4))));
}

static __device__ float3  normalize_0(float3  x_5)
{
    return x_5 / make_float3 (length_0(x_5));
}

static __device__ int StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    uint2  _S7 = make_uint2(_elementCount_0, _stride_0);
    return int(_S7.x);
}

static __device__ float lerp_0(float x_6, float y_2, float s_0)
{
    return x_6 + (y_2 - x_6) * s_0;
}

static __device__ float smoothstep_0(float min_0, float max_0, float x_7)
{
    float _S8 = saturate_0((x_7 - min_0) / (max_0 - min_0));
    return _S8 * _S8 * (3.0f - (_S8 + _S8));
}

static __device__ float length_1(float2  x_8)
{
    return (F32_sqrt((dot_0(x_8, x_8))));
}

static __device__ float2  floor_0(float2  x_9)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_floor((_slang_vector_get_element(x_9, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ float2  lerp_1(float2  x_10, float2  y_3, float2  s_1)
{
    return x_10 + (y_3 - x_10) * s_1;
}

static __device__ int clamp_1(int x_11, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_11), (minBound_1)))), (maxBound_1)));
}

static __device__ float3  floor_1(float3  x_12)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_floor((_slang_vector_get_element(x_12, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ float3  slang_ldg_0(float3  * ptr_0)
{
    float _S9 = __ldg(&(ptr_0->x));
    float _S10 = __ldg(&(ptr_0->y));
    float _S11 = __ldg(&(ptr_0->z));
    return make_float3 (_S9, _S10, _S11);
}

struct Rng_0
{
    uint state_0;
};

static __device__ Rng_0 makeRng_0(uint seed_0)
{
    Rng_0 r_0;
    (&r_0)->state_0 = seed_0;
    return r_0;
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
    int mode_0;
};

static __device__ bool slabRange_0(Medium_0 * m_0, float3  ro_0, float3  rd_0, float * t0_0, float * t1_0)
{
    *t0_0 = 0.0f;
    *t1_0 = 1.0e+09f;
    float _S12 = rd_0.y;
    bool _S13;
    if((F32_abs((_S12))) < 9.99999997475242708e-07f)
    {
        float _S14 = ro_0.y;
        if(_S14 < (m_0->slabBottom_0))
        {
            _S13 = true;
        }
        else
        {
            _S13 = _S14 > (m_0->slabTop_0);
        }
        if(_S13)
        {
            return false;
        }
    }
    else
    {
        float _S15 = ro_0.y;
        float ta_0 = (m_0->slabBottom_0 - _S15) / _S12;
        float tb_0 = (m_0->slabTop_0 - _S15) / _S12;
        *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
        *t1_0 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    }
    float _S16 = (F32_min((*t1_0), (1.2e+05f)));
    *t1_0 = _S16;
    if(_S16 > (*t0_0))
    {
        _S13 = (*t1_0) > 0.0f;
    }
    else
    {
        _S13 = false;
    }
    return _S13;
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

static __device__ Dda_0 ddaInit_0(MajorantGrid_0 * g_0, float3  ro_1, float3  rd_1, float t_0)
{
    Dda_0 d_0;
    if((g_0->enabled_0) == int(0))
    {
        int3  _S17 = make_int3 (int(0), int(0), int(0));
        (&d_0)->cell_0 = _S17;
        (&d_0)->stepDir_0 = _S17;
        float3  _S18 = make_float3 (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_0)->tMax_0 = _S18;
        (&d_0)->tDelta_0 = _S18;
        return d_0;
    }
    float3  p_0 = ro_1 + rd_1 * make_float3 (t_0);
    float3  _S19 = floor_1((p_0 - g_0->origin_0) / g_0->cellExtent_0);
    int3  _S20 = make_int3 ((int)_S19.x, (int)_S19.y, (int)_S19.z);
    (&d_0)->cell_0 = _S20;
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
        int _S21 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            *_slang_vector_get_element_ptr(&(&d_0)->stepDir_0, a_0) = int(0);
            *_slang_vector_get_element_ptr(&(&d_0)->tMax_0, a_0) = 1.00000001504746622e+30f;
            *_slang_vector_get_element_ptr(&(&d_0)->tDelta_0, a_0) = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S22 = _slang_vector_get_element(rd_1, _S21) > 0.0f;
            int _S23;
            if(_S22)
            {
                _S23 = int(1);
            }
            else
            {
                _S23 = int(-1);
            }
            *_slang_vector_get_element_ptr(&(&d_0)->stepDir_0, a_0) = _S23;
            float _S24 = *_slang_vector_get_element_ptr(&g_0->origin_0, a_0);
            float _S25 = float(*_slang_vector_get_element_ptr(&(&d_0)->cell_0, a_0));
            float _S26;
            if(_S22)
            {
                _S26 = 1.0f;
            }
            else
            {
                _S26 = 0.0f;
            }
            *_slang_vector_get_element_ptr(&(&d_0)->tMax_0, a_0) = t_0 + (_S24 + (_S25 + _S26) * *_slang_vector_get_element_ptr(&g_0->cellExtent_0, a_0) - _slang_vector_get_element(p_0, a_0)) / _slang_vector_get_element(rd_1, _S21);
            *_slang_vector_get_element_ptr(&(&d_0)->tDelta_0, a_0) = (F32_abs((*_slang_vector_get_element_ptr(&g_0->cellExtent_0, a_0) / _slang_vector_get_element(rd_1, _S21))));
        }
        a_0 = a_0 + int(1);
    }
    return d_0;
}

static __device__ float gridBound_0(MajorantGrid_0 * g_1, StructuredBuffer<float> bounds_0, int3  c_0, float fallback_0)
{
    if((g_1->enabled_0) == int(0))
    {
        return fallback_0;
    }
    int _S27 = c_0.x;
    bool _S28;
    if(_S27 < int(0))
    {
        _S28 = true;
    }
    else
    {
        _S28 = (c_0.y) < int(0);
    }
    if(_S28)
    {
        _S28 = true;
    }
    else
    {
        _S28 = (c_0.z) < int(0);
    }
    if(_S28)
    {
        _S28 = true;
    }
    else
    {
        _S28 = _S27 >= (g_1->dims_0.x);
    }
    if(_S28)
    {
        _S28 = true;
    }
    else
    {
        _S28 = (c_0.y) >= (g_1->dims_0.y);
    }
    if(_S28)
    {
        _S28 = true;
    }
    else
    {
        _S28 = (c_0.z) >= (g_1->dims_0.z);
    }
    if(_S28)
    {
        return fallback_0;
    }
    float _S29 = __ldg((&(bounds_0)[(c_0.z * g_1->dims_0.y + c_0.y) * g_1->dims_0.x + _S27]));
    return _S29;
}

static __device__ float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_2)
{
    bool _S30;
    if((d_2->tMax_0.x) <= (d_2->tMax_0.y))
    {
        _S30 = (d_2->tMax_0.x) <= (d_2->tMax_0.z);
    }
    else
    {
        _S30 = false;
    }
    if(_S30)
    {
        *&((&d_2->cell_0)->x) = *&((&d_2->cell_0)->x) + d_2->stepDir_0.x;
        *&((&d_2->tMax_0)->x) = *&((&d_2->tMax_0)->x) + d_2->tDelta_0.x;
    }
    else
    {
        if((d_2->tMax_0.y) <= (d_2->tMax_0.z))
        {
            *&((&d_2->cell_0)->y) = *&((&d_2->cell_0)->y) + d_2->stepDir_0.y;
            *&((&d_2->tMax_0)->y) = *&((&d_2->tMax_0)->y) + d_2->tDelta_0.y;
        }
        else
        {
            *&((&d_2->cell_0)->z) = *&((&d_2->cell_0)->z) + d_2->stepDir_0.z;
            *&((&d_2->tMax_0)->z) = *&((&d_2->tMax_0)->z) + d_2->tDelta_0.z;
        }
    }
    return;
}

static __device__ float randFloat_0(Rng_0 * r_1)
{
    uint _S31 = r_1->state_0 * 747796405U + 2891336453U;
    r_1->state_0 = _S31;
    uint word_0 = ((_S31 >> ((_S31 >> 28U) + 4U)) ^ _S31) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_2, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_13 = clamp_0(depth_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_2 = clamp_1(int((F32_floor((x_13)))), int(0), int(31));
    float2  _S32 = __ldg((&(disp_0)[i_2]));
    float2  _S33 = __ldg((&(disp_0)[i_2 + int(1)]));
    return lerp_1(_S32, _S33, make_float2 (x_13 - float(i_2)));
}

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S34 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S35 = _S34;
    *&((&_S35)->x) = *&((&_S35)->x) + _S34.y * 1664525U;
    *&((&_S35)->y) = *&((&_S35)->y) + _S35.x * 1664525U;
    uint2  _S36 = _S35 ^ (_S35 >> make_uint2 (16U));
    _S35 = _S36;
    *&((&_S35)->x) = *&((&_S35)->x) + _S36.y * 1664525U;
    *&((&_S35)->y) = *&((&_S35)->y) + _S35.x * 1664525U;
    uint2  _S37 = _S35 ^ (_S35 >> make_uint2 (16U));
    _S35 = _S37;
    return _S37;
}

static __device__ float2  hash22_0(int2  c_1, uint salt_0)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_1.x), uint(c_1.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S38 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S38 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float cellField_0(GeneratorInput_0 * g_3, float2  q_0)
{
    float2  gq_0 = (q_0 - g_3->cellDrift_0) / make_float2 (g_3->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_0(gq_0);
    int2  _S39 = make_int2 ((int)gf_0.x, (int)gf_0.y);
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
        int i_3 = int(-1);
        float acc_1 = acc_0;
        for(;;)
        {
            if(i_3 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_0 = _S39 + make_int2 (i_3, j_0);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_3 = i_3 + int(1);
                continue;
            }
            float2  _S40 = make_float2 ((float)o_0.x, (float)o_0.y);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(gq_0 - (_S40 + make_float2 (0.5f) + (hash22_0(o_0, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f))) * 2.20000004768371582f);
            i_3 = i_3 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S41 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S42 = _S41;
    *&((&_S42)->x) = *&((&_S42)->x) + _S41.y * _S41.z;
    *&((&_S42)->y) = *&((&_S42)->y) + _S42.z * _S42.x;
    *&((&_S42)->z) = *&((&_S42)->z) + _S42.x * _S42.y;
    uint3  _S43 = _S42 ^ (_S42 >> make_uint3 (16U));
    _S42 = _S43;
    *&((&_S42)->x) = *&((&_S42)->x) + _S43.y * _S43.z;
    *&((&_S42)->y) = *&((&_S42)->y) + _S42.z * _S42.x;
    *&((&_S42)->z) = *&((&_S42)->z) + _S42.x * _S42.y;
    return _S42;
}

static __device__ float3  hash33_0(int3  c_2)
{
    uint3  h_1 = pcg3d_0(make_uint3 (uint(c_2.x), uint(c_2.y), uint(c_2.z)));
    float3  _S44 = make_float3 ((float)h_1.x, (float)h_1.y, (float)h_1.z);
    return _S44 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_1)
{
    float3  fi_0 = floor_1(p_1);
    int3  _S45 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_1 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S46 = u_0.x;
    float _S47 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_1(hash33_0(_S45), f_0), dot_1(hash33_0(_S45 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S46), lerp_0(dot_1(hash33_0(_S45 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S45 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S46), _S47), lerp_0(lerp_0(dot_1(hash33_0(_S45 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S45 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S46), lerp_0(dot_1(hash33_0(_S45 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S45 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S46), _S47), u_0.z);
}

static __device__ float fbm_0(float3  p_2, int octaves_1)
{
    int i_4 = int(0);
    float amp_0 = 0.5f;
    float3  _S48 = p_2;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_4 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_4 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S48);
        float norm_1 = norm_0 + amp_0;
        float3  _S49 = _S48 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_4 = i_4 + int(1);
        amp_0 = amp_1;
        _S48 = _S49;
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

static __device__ float iceDensity_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_1, float3  p_3)
{
    float depth_1 = g_4->cellAltitude_0 - p_3.y;
    bool _S50;
    if(depth_1 < 0.0f)
    {
        _S50 = true;
    }
    else
    {
        _S50 = depth_1 > (g_4->streakLength_0);
    }
    if(_S50)
    {
        return 0.0f;
    }
    float2  _S51 = float2 {p_3.x, p_3.z};
    float2  _S52 = driftAt_0(g_4, disp_1, depth_1);
    float2  source_0 = _S51 - _S52;
    float _S53 = cellField_0(g_4, source_0);
    if(_S53 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S53 * (F32_exp((- g_4->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, depth_1)) * (F32_max((1.0f + g_4->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_4->detailScale_0)).x, (source_0 / make_float2 (g_4->detailScale_0)).y, depth_1 / (F32_max((g_4->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_4->timeSeconds_0 * 0.00999999977648258f), g_4->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((g_4->streakLength_0), (1.0f)));
}

static __device__ float densityAt_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_2, float3  p_4)
{
    float _S54 = p_4.y;
    bool _S55;
    if(_S54 < (m_1->slabBottom_0))
    {
        _S55 = true;
    }
    else
    {
        _S55 = _S54 > (m_1->slabTop_0);
    }
    if(_S55)
    {
        return 0.0f;
    }
    int _S56 = m_1->mode_0;
    if((m_1->mode_0) == int(0))
    {
        return m_1->density_0;
    }
    if(_S56 == int(2))
    {
        float _S57 = iceDensity_0(&m_1->gen_0, disp_2, p_4);
        return _S57;
    }
    float3  d_3 = (p_4 - m_1->coreCentre_0) / make_float3 ((F32_max((m_1->coreRadius_0), (9.99999997475242708e-07f))));
    return m_1->density_0 + m_1->coreDensity_0 * (F32_exp((- dot_1(d_3, d_3))));
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_3, Rng_0 * rng_0, float3  ro_2, float3  rd_2, float3  * scatterPoint_0, float * distance_0, int * steps_0)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_1;
    float t1_1;
    bool _S58 = slabRange_0(m_2, ro_2, rd_2, &t0_1, &t1_1);
    if(!_S58)
    {
        return false;
    }
    float _S59 = (F32_max((t0_1), (0.0f)));
    Dda_0 _S60 = ddaInit_0(g_5, ro_2, rd_2, _S59);
    Dda_0 dda_0 = _S60;
    int i_5 = int(0);
    float t_1 = _S59;
    for(;;)
    {
        if(i_5 < int(1024))
        {
        }
        else
        {
            break;
        }
        *steps_0 = *steps_0 + int(1);
        float _S61 = gridBound_0(g_5, bounds_1, (&dda_0)->cell_0, m_2->majorant_0);
        Dda_0 _S62 = dda_0;
        float _S63 = ddaExit_0(&_S62);
        float _S64 = (F32_min((_S63), (t1_1)));
        if(_S61 <= 0.0f)
        {
            if(_S64 >= t1_1)
            {
                return false;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S64;
            i_5 = i_5 + int(1);
            continue;
        }
        float _S65 = randFloat_0(rng_0);
        float t_2 = t_1 - (F32_log(((F32_max((1.0f - _S65), (1.00000001168609742e-07f)))))) / _S61;
        if(t_2 >= _S64)
        {
            if(_S64 >= t1_1)
            {
                return false;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S64;
            i_5 = i_5 + int(1);
            continue;
        }
        float3  p_5 = ro_2 + rd_2 * make_float3 (t_2);
        float _S66 = randFloat_0(rng_0);
        float _S67 = densityAt_0(m_2, disp_3, p_5);
        if(_S66 < (_S67 / _S61))
        {
            *scatterPoint_0 = p_5;
            *distance_0 = t_2;
            return true;
        }
        t_1 = t_2;
        i_5 = i_5 + int(1);
    }
    return false;
}

static __device__ float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static __device__ float3  normalizeExact_0(float3  v_2)
{
    float len2_0 = dot_1(v_2, v_2);
    if(len2_0 <= 0.0f)
    {
        return make_float3 (0.0f, 1.0f, 0.0f);
    }
    return v_2 * make_float3 (1.0f / (F32_sqrt((len2_0))));
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
    StructuredBuffer<float> transmittance_0;
};

static __device__ float3  sunDirection_0(SkyInput_0 * p_6)
{
    float az_0 = toRadians_0(p_6->sunAzimuth_0);
    float el_0 = toRadians_0(p_6->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static __device__ float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_4 = altitude_0 - shellHeight_0;
    return d_4 * (d_4 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_0, float c_3)
{
    float disc_0 = b_0 * b_0 - c_3;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_0 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_1, float c_4)
{
    float disc_1 = b_1 * b_1 - c_4;
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

static __device__ float clampf_0(float v_3, float lo_0, float hi_0)
{
    float _S68;
    if(v_3 < lo_0)
    {
        _S68 = lo_0;
    }
    else
    {
        if(v_3 > hi_0)
        {
            _S68 = hi_0;
        }
        else
        {
            _S68 = v_3;
        }
    }
    return _S68;
}

static __device__ float altitudeFromQ_0(float q_1, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_1;
    float _S69;
    if(rr_0 > 0.0f)
    {
        _S69 = rr_0;
    }
    else
    {
        _S69 = 0.0f;
    }
    return q_1 / (planetRadius_2 + (F32_sqrt((_S69))));
}

static __device__ float lutMuFor_0(float3  geocentric_0, float3  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S70;
    if(len_0 > 1.0f)
    {
        _S70 = dot_1(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S70 = dot_1(geocentric_0, sun_0);
    }
    return _S70;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_7, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S71 = p_7->transmittance_0;
    if(uint(StructuredBuffer_getCount_0(p_7->transmittance_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S72 = p_7->scaleHeight_0;
    float scaleHeight_1;
    if((p_7->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S72;
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
    float _S73 = fx_1 - float(x0_1);
    float _S74 = fy_1 - float(y0_1);
    int _S75 = y0_1 * int(256);
    int _S76 = (_S75 + x0_1) * int(3);
    int _S77 = (_S75 + x1_1) * int(3);
    int _S78 = y1_1 * int(256);
    int _S79 = (_S78 + x0_1) * int(3);
    int _S80 = (_S78 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_5 = int(0);
    for(;;)
    {
        if(c_5 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S81 = __ldg((&(_S71)[_S76 + c_5]));
        float _S82 = 1.0f - _S73;
        float _S83 = _S81 * _S82;
        float _S84 = __ldg((&(_S71)[_S77 + c_5]));
        float a_1 = _S83 + _S84 * _S73;
        float _S85 = __ldg((&(_S71)[_S79 + c_5]));
        float _S86 = _S85 * _S82;
        float _S87 = __ldg((&(_S71)[_S80 + c_5]));
        float r_2 = a_1 * (1.0f - _S74) + (_S86 + _S87 * _S73) * _S74;
        if(c_5 == int(0))
        {
            *&((&out_0)->x) = r_2;
        }
        else
        {
            if(c_5 == int(1))
            {
                *&((&out_0)->y) = r_2;
            }
            else
            {
                *&((&out_0)->z) = r_2;
            }
        }
        c_5 = c_5 + int(1);
    }
    return out_0;
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_8)
{
    return 20.0f * p_8->sunIntensity_0;
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_9, float3  rayDir_0, bool includeSunDisc_0)
{
    float3  _S88 = sunDirection_0(p_9);
    float _S89 = p_9->planetRadius_0;
    float planetRadius_3;
    if((p_9->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S89;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S90 = p_9->scaleHeight_0;
    float scaleHeight_2;
    if((p_9->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S90;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float _S91 = planetRadius_3 + 2.0f;
    float _S92 = rayDir_0.y;
    float b_2 = _S91 * _S92;
    float cGround_0 = shellC_0(2.0f, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(b_2, shellC_0(2.0f, planetRadius_3, scaleHeight_2 * 8.0f));
    if(tTop_0 <= 0.0f)
    {
        return make_float3 (0.0f, 0.0f, 0.0f);
    }
    float tGround_0 = shellEnter_0(b_2, cGround_0);
    bool hitsGround_0 = tGround_0 > 0.0f;
    float safeSolid_0;
    if(hitsGround_0)
    {
        safeSolid_0 = tGround_0;
    }
    else
    {
        safeSolid_0 = tTop_0;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_9->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_1(rayDir_0, _S88), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_6 = clampf_0(p_9->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S93 = g_6 * g_6;
    float hgDenom_0 = 1.0f + _S93 - 2.0f * g_6 * cosTheta_0;
    float _S94 = 1.0f - _S93;
    float _S95 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S94 / (_S95 * (F32_sqrt((tPrev_0))));
    float3  _S96 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    float3  sumR_0 = _S96;
    float3  sumM_0 = _S96;
    int i_6 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_6 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S97 = i_6 + int(1);
        float tNext_0 = safeSolid_0 * float(_S97 * _S97) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_6 = _S97;
            continue;
        }
        float h_2 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_2 + tMid_0 * tMid_0, planetRadius_3);
        float hc_0;
        if(h_2 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_2;
        }
        float _S98 = - hc_0;
        float dR_0 = (F32_exp((_S98 / scaleHeight_2))) * dt_0;
        float dM_0 = (F32_exp((_S98 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        float3  _S99 = sampleTransmittanceLut_0(p_9, hc_0, lutMuFor_0(make_float3 (rayDir_0.x * tMid_0, _S91 + _S92 * tMid_0, rayDir_0.z * tMid_0), _S88));
        float _S100 = betaMExt_0 * depthM_1;
        float3  transmittance_1 = make_float3 ((F32_exp((- (betaR_0.x * depthR_1 + _S100)))), (F32_exp((- (betaR_0.y * depthR_1 + _S100)))), (F32_exp((- (betaR_0.z * depthR_1 + _S100))))) * _S99;
        float3  _S101 = sumM_0 + transmittance_1 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_1 * make_float3 (dR_0);
        sumM_0 = _S101;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_6 = _S97;
    }
    float _S102 = sunIrradianceTop_0(p_9);
    float3  radiance_0 = (sumR_0 * betaR_0 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S102);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_0.x * tGround_0, _S91 + _S92 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_1(normalizeExact_0(groundPoint_0), _S88), 0.0f, 1.0f);
        float3  _S103 = sampleTransmittanceLut_0(p_9, 0.0f, lutMuFor_0(groundPoint_0, _S88));
        float _S104 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S104)))), (F32_exp((- (betaR_0.y * depthR_0 + _S104)))), (F32_exp((- (betaR_0.z * depthR_0 + _S104))))) * _S103 * make_float3 (p_9->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S102);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S105;
    if(!hitsGround_0)
    {
        _S105 = includeSunDisc_0;
    }
    else
    {
        _S105 = false;
    }
    if(_S105)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_9->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S106 = betaMExt_0 * depthM_0;
            float3  viewT_0 = make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S106)))), (F32_exp((- (betaR_0.y * depthR_0 + _S106)))), (F32_exp((- (betaR_0.z * depthR_0 + _S106)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                safeSolid_0 = solidAngle_0;
            }
            else
            {
                safeSolid_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * make_float3 (_S102 / safeSolid_0);
        }
    }
    return radiance_1;
}

struct Environment_0
{
    float3  uniformRadiance_0;
    SkyInput_0 sky_0;
    int envMode_0;
};

static __device__ float3  environmentRadiance_0(Environment_0 * e_0, float3  dir_0, bool includeSunDisc_1)
{
    if((e_0->envMode_0) == int(1))
    {
        float3  _S107 = skyRadiance_0(&e_0->sky_0, dir_0, includeSunDisc_1);
        return _S107;
    }
    return e_0->uniformRadiance_0;
}

static __device__ float transmittance_2(Medium_0 * m_3, MajorantGrid_0 * g_7, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > disp_4, Rng_0 * rng_1, float3  p_10, float3  dir_1, int * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S108 = slabRange_0(m_3, p_10, dir_1, &t0_2, &t1_2);
    if(!_S108)
    {
        return 1.0f;
    }
    float _S109 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S109;
    Dda_0 _S110 = ddaInit_0(g_7, p_10, dir_1, _S109);
    Dda_0 dda_1 = _S110;
    int i_7 = int(0);
    float t_3 = _S109;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_7 < int(1024))
        {
        }
        else
        {
            break;
        }
        *steps_1 = *steps_1 + int(1);
        float _S111 = gridBound_0(g_7, bounds_2, (&dda_1)->cell_0, m_3->majorant_0);
        Dda_0 _S112 = dda_1;
        float _S113 = ddaExit_0(&_S112);
        float _S114 = (F32_min((_S113), (t1_2)));
        if(_S111 <= 0.0f)
        {
            if(_S114 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            t_3 = _S114;
            i_7 = i_7 + int(1);
            continue;
        }
        float _S115 = randFloat_0(rng_1);
        float t_4 = t_3 - (F32_log(((F32_max((1.0f - _S115), (1.00000001168609742e-07f)))))) / _S111;
        if(t_4 >= _S114)
        {
            if(_S114 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            t_3 = _S114;
            i_7 = i_7 + int(1);
            continue;
        }
        float _S116 = densityAt_0(m_3, disp_4, p_10 + dir_1 * make_float3 (t_4));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S116 / _S111)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S117 = randFloat_0(rng_1);
            if(_S117 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_3 = t_4;
        tr_0 = tr_2;
        i_7 = i_7 + int(1);
    }
    return tr_0;
}

static __device__ float hg_0(float cosT_0, float g_8)
{
    float _S118 = g_8 * g_8;
    float d_5 = 1.0f + _S118 - 2.0f * g_8 * cosT_0;
    return (1.0f - _S118) / (12.56637096405029297f * d_5 * (F32_sqrt(((F32_max((d_5), (9.99999997475242708e-07f)))))));
}

static __device__ float phaseIce_0(float cosT_1)
{
    float t_5 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_0(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_5 * t_5))) * 0.34999999403953552f;
}

static __device__ float draine_0(float cosT_2, float g_9, float a_2)
{
    float _S119 = g_9 * g_9;
    float _S120 = 2.0f * g_9;
    float d_6 = 1.0f + _S119 - _S120 * cosT_2;
    return (1.0f - _S119) / (12.56637096405029297f * d_6 * (F32_sqrt(((F32_max((d_6), (9.99999997475242708e-07f))))))) * (1.0f + a_2 * cosT_2 * cosT_2) / (1.0f + a_2 * (1.0f + _S120 * g_9) / 3.0f);
}

struct PhaseInput_0
{
    float hgG_0;
    float draineG_0;
    float draineAlpha_0;
    float draineW_0;
    int useIce_0;
};

static __device__ float phaseLiquid_0(PhaseInput_0 * p_11, float cosT_3)
{
    return (1.0f - p_11->draineW_0) * hg_0(cosT_3, p_11->hgG_0) + p_11->draineW_0 * draine_0(cosT_3, p_11->draineG_0, p_11->draineAlpha_0);
}

static __device__ float phaseAt_0(PhaseInput_0 * p_12, float cosT_4)
{
    float _S121;
    if((p_12->useIce_0) != int(0))
    {
        _S121 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S122 = phaseLiquid_0(p_12, cosT_4);
        _S121 = _S122;
    }
    return _S121;
}

static __device__ float3  sunTransmittanceAt_0(SkyInput_0 * p_13, float3  worldPos_0)
{
    float3  _S123 = sunDirection_0(p_13);
    float _S124 = p_13->planetRadius_0;
    float planetRadius_4;
    if((p_13->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S124;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S125 = worldPos_0.y;
    float altitude_2;
    if(_S125 > 0.0f)
    {
        altitude_2 = _S125;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    float3  _S126 = sampleTransmittanceLut_0(p_13, altitude_2, lutMuFor_0(make_float3 (worldPos_0.x, planetRadius_4 + _S125, worldPos_0.z), _S123));
    return _S126;
}

static __device__ float3  sampleHG_0(Rng_0 * rng_2, float3  wo_0, float g_10, float * cosT_5)
{
    float _S127 = clamp_0(g_10, -0.99900001287460327f, 0.99900001287460327f);
    float u1_0 = randFloat_0(rng_2);
    float u2_0 = randFloat_0(rng_2);
    if((F32_abs((_S127))) < 0.00100000004749745f)
    {
        *cosT_5 = 1.0f - 2.0f * u1_0;
    }
    else
    {
        float _S128 = _S127 * _S127;
        float _S129 = 2.0f * _S127;
        float s_2 = (1.0f - _S128) / (1.0f - _S127 + _S129 * u1_0);
        *cosT_5 = (1.0f + _S128 - s_2 * s_2) / _S129;
    }
    float _S130 = clamp_0(*cosT_5, -1.0f, 1.0f);
    *cosT_5 = _S130;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S130 * _S130))))));
    float phi_0 = 6.28318548202514648f * u2_0;
    float3  w_0 = normalize_0(wo_0);
    float3  a_3;
    if((F32_abs((w_0.y))) < 0.94999998807907104f)
    {
        a_3 = make_float3 (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_3 = make_float3 (1.0f, 0.0f, 0.0f);
    }
    float3  u_1 = normalize_0(cross_0(a_3, w_0));
    return normalize_0(make_float3 (sinT_0 * (F32_cos((phi_0)))) * u_1 + make_float3 (sinT_0 * (F32_sin((phi_0)))) * cross_0(w_0, u_1) + make_float3 (*cosT_5) * w_0);
}

static __device__ float3  samplePhaseDir_0(PhaseInput_0 * p_14, Rng_0 * rng_3, float3  wo_1, float * weight_0)
{
    float cosT_6;
    float3  dir_2;
    float _S131;
    if((p_14->useIce_0) != int(0))
    {
        float _S132 = randFloat_0(rng_3);
        if(_S132 < 0.72000002861022949f)
        {
            float3  _S133 = sampleHG_0(rng_3, wo_1, 0.85000002384185791f, &cosT_6);
            dir_2 = _S133;
        }
        else
        {
            float3  _S134 = sampleHG_0(rng_3, wo_1, 0.0f, &cosT_6);
            dir_2 = _S134;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_6, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S131 = phaseIce_0(cosT_6) / pdf_0;
        }
        else
        {
            _S131 = 0.0f;
        }
        *weight_0 = _S131;
    }
    else
    {
        float _S135 = randFloat_0(rng_3);
        float _S136 = p_14->draineW_0;
        if(_S135 < (p_14->draineW_0))
        {
            float3  _S137 = sampleHG_0(rng_3, wo_1, p_14->draineG_0, &cosT_6);
            dir_2 = _S137;
        }
        else
        {
            float3  _S138 = sampleHG_0(rng_3, wo_1, p_14->hgG_0, &cosT_6);
            dir_2 = _S138;
        }
        float pdf_1 = _S136 * hg_0(cosT_6, p_14->draineG_0) + (1.0f - _S136) * hg_0(cosT_6, p_14->hgG_0);
        if(pdf_1 > 9.99999971718068537e-10f)
        {
            float _S139 = phaseLiquid_0(p_14, cosT_6);
            _S131 = _S139 / pdf_1;
        }
        else
        {
            _S131 = 0.0f;
        }
        *weight_0 = _S131;
    }
    return dir_2;
}

struct TraceResult_0
{
    float3  pathRadiance_0;
    int scatterEvents_0;
    int capped_0;
    int trackingSteps_0;
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
};

static __device__ TraceResult_0 trace_0(Scene_0 * s_3, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > drift_0, Rng_0 * rng_4, float3  ro_3, float3  rd_3)
{
    TraceResult_0 r_3;
    (&r_3)->pathRadiance_0 = make_float3 (0.0f, 0.0f, 0.0f);
    (&r_3)->scatterEvents_0 = int(0);
    (&r_3)->capped_0 = int(0);
    (&r_3)->trackingSteps_0 = int(0);
    float3  _S140 = make_float3 (1.0f, 1.0f, 1.0f);
    int _S141 = (I32_min((s_3->maxBounces_0), (int(256))));
    float3  _S142 = ro_3;
    float3  _S143 = rd_3;
    int bounce_0 = int(0);
    float3  throughput_0 = _S140;
    for(;;)
    {
        if(bounce_0 < int(256))
        {
        }
        else
        {
            break;
        }
        if(bounce_0 >= _S141)
        {
            (&r_3)->capped_0 = int(1);
            break;
        }
        float3  p_15;
        float dist_0;
        bool _S144 = sampleFreeFlight_0(&s_3->medium_0, &s_3->grid_0, bounds_3, drift_0, rng_4, _S142, _S143, &p_15, &dist_0, &(&r_3)->trackingSteps_0);
        if(!_S144)
        {
            float3  _S145 = environmentRadiance_0(&s_3->environment_0, _S143, bounce_0 == int(0));
            (&r_3)->pathRadiance_0 = (&r_3)->pathRadiance_0 + throughput_0 * _S145;
            break;
        }
        (&r_3)->scatterEvents_0 = (&r_3)->scatterEvents_0 + int(1);
        float3  _S146 = s_3->sunDir_0;
        float _S147 = transmittance_2(&s_3->medium_0, &s_3->grid_0, bounds_3, drift_0, rng_4, p_15 + s_3->sunDir_0 * make_float3 (s_3->shadowOffset_0), s_3->sunDir_0, &(&r_3)->trackingSteps_0);
        if(_S147 > 0.0f)
        {
            float _S148 = phaseAt_0(ph_0, dot_1(_S143, _S146));
            float3  _S149 = s_3->sunIrradiance_0;
            float3  sunE_0;
            if(((&s_3->environment_0)->envMode_0) == int(1))
            {
                float _S150 = sunIrradianceTop_0(&(&s_3->environment_0)->sky_0);
                float3  _S151 = sunTransmittanceAt_0(&(&s_3->environment_0)->sky_0, p_15);
                sunE_0 = make_float3 (_S150) * _S151;
            }
            else
            {
                sunE_0 = _S149;
            }
            (&r_3)->pathRadiance_0 = (&r_3)->pathRadiance_0 + throughput_0 * s_3->albedo_0 * make_float3 (_S148) * make_float3 (_S147) * sunE_0;
        }
        float w_1;
        float3  _S152 = samplePhaseDir_0(ph_0, rng_4, _S143, &w_1);
        float3  throughput_1 = throughput_0 * (s_3->albedo_0 * make_float3 (w_1));
        float3  _S153 = p_15;
        if(bounce_0 >= (s_3->rrStartBounce_0))
        {
            float p2_0 = clamp_0((F32_max((throughput_1.x), ((F32_max((throughput_1.y), (throughput_1.z)))))), 0.05000000074505806f, 1.0f);
            float _S154 = randFloat_0(rng_4);
            if(_S154 > p2_0)
            {
                break;
            }
            throughput_0 = throughput_1 / make_float3 (p2_0);
        }
        else
        {
            throughput_0 = throughput_1;
        }
        int bounce_1 = bounce_0 + int(1);
        _S142 = _S153;
        _S143 = _S152;
        bounce_0 = bounce_1;
    }
    return r_3;
}

static __device__ float3  renderSample_0(Scene_0 * s_4, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > drift_1, float3  ro_4, float3  rd_4, uint seed_1)
{
    Rng_0 rng_5 = makeRng_0(seed_1);
    TraceResult_0 _S155 = trace_0(s_4, ph_1, bounds_4, drift_1, &rng_5, ro_4, rd_4);
    return _S155.pathRadiance_0;
}

extern "C" __global__ void renderRays(Scene_0 scene_0, PhaseInput_0 phase_0, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > drift_2, StructuredBuffer<float3 > origins_0, StructuredBuffer<float3 > directions_0, RWStructuredBuffer<float3 > outRadiance_0, uint seed_2, int count_0)
{
    int i_8 = int((blockIdx * blockDim + threadIdx).x);
    if(i_8 >= count_0)
    {
        return;
    }
    float3  * _S156 = (&(outRadiance_0)[i_8]);
    float3  _S157 = slang_ldg_0((&(origins_0)[i_8]));
    float3  _S158 = slang_ldg_0((&(directions_0)[i_8]));
    uint _S159 = seed_2 + uint(i_8);
    Scene_0 _S160 = scene_0;
    PhaseInput_0 _S161 = phase_0;
    float3  _S162 = renderSample_0(&_S160, &_S161, bounds_5, drift_2, _S157, _S158, _S159);
    *_S156 = _S162;
    return;
}

