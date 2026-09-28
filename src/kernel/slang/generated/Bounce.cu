// GENERATED FROM Bounce.slang BY slangc -- DO NOT EDIT.
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

static __device__ float clamp_0(float x_2, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_2), (minBound_0)))), (maxBound_0)));
}

static __device__ float saturate_0(float x_3)
{
    return clamp_0(x_3, 0.0f, 1.0f);
}

static __device__ float dot_1(float2  x_4, float2  y_1)
{
    return x_4.x * y_1.x + x_4.y * y_1.y;
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

static __device__ float3  normalize_0(float3  x_5)
{
    return x_5 / make_float3 (length_0(x_5));
}

static __device__ float lerp_0(float x_6, float y_2, float s_0)
{
    return x_6 + (y_2 - x_6) * s_0;
}

static __device__ float smoothstep_0(float min_0, float max_0, float x_7)
{
    float _S7 = saturate_0((x_7 - min_0) / (max_0 - min_0));
    return _S7 * _S7 * (3.0f - (_S7 + _S7));
}

static __device__ float length_1(float2  x_8)
{
    return (F32_sqrt((dot_1(x_8, x_8))));
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

static __device__ Rng_0 makeRngForIndex_0(uint seed_1, int index_0)
{
    uint s_2 = uint(index_0) * 747796405U + 2891336453U;
    uint s_3 = ((s_2 >> ((s_2 >> 28U) + 4U)) ^ s_2) * 277803737U;
    return makeRng_0(((s_3 >> 22U) ^ s_3) ^ seed_1);
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
    float _S8 = rd_0.y;
    bool _S9;
    if((F32_abs((_S8))) < 9.99999997475242708e-07f)
    {
        float _S10 = ro_0.y;
        if(_S10 < (m_0->slabBottom_0))
        {
            _S9 = true;
        }
        else
        {
            _S9 = _S10 > (m_0->slabTop_0);
        }
        if(_S9)
        {
            return false;
        }
    }
    else
    {
        float _S11 = ro_0.y;
        float ta_0 = (m_0->slabBottom_0 - _S11) / _S8;
        float tb_0 = (m_0->slabTop_0 - _S11) / _S8;
        *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
        *t1_0 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    }
    float _S12 = (F32_min((*t1_0), (1.2e+05f)));
    *t1_0 = _S12;
    if(_S12 > (*t0_0))
    {
        _S9 = (*t1_0) > 0.0f;
    }
    else
    {
        _S9 = false;
    }
    return _S9;
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
        int3  _S13 = make_int3 (int(0), int(0), int(0));
        (&d_0)->cell_0 = _S13;
        (&d_0)->stepDir_0 = _S13;
        float3  _S14 = make_float3 (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_0)->tMax_0 = _S14;
        (&d_0)->tDelta_0 = _S14;
        return d_0;
    }
    float3  p_0 = ro_1 + rd_1 * make_float3 (t_0);
    float3  _S15 = floor_1((p_0 - g_0->origin_0) / g_0->cellExtent_0);
    int3  _S16 = make_int3 ((int)_S15.x, (int)_S15.y, (int)_S15.z);
    (&d_0)->cell_0 = _S16;
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
        int _S17 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            *_slang_vector_get_element_ptr(&(&d_0)->stepDir_0, a_0) = int(0);
            *_slang_vector_get_element_ptr(&(&d_0)->tMax_0, a_0) = 1.00000001504746622e+30f;
            *_slang_vector_get_element_ptr(&(&d_0)->tDelta_0, a_0) = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S18 = _slang_vector_get_element(rd_1, _S17) > 0.0f;
            int _S19;
            if(_S18)
            {
                _S19 = int(1);
            }
            else
            {
                _S19 = int(-1);
            }
            *_slang_vector_get_element_ptr(&(&d_0)->stepDir_0, a_0) = _S19;
            float _S20 = *_slang_vector_get_element_ptr(&g_0->origin_0, a_0);
            float _S21 = float(*_slang_vector_get_element_ptr(&(&d_0)->cell_0, a_0));
            float _S22;
            if(_S18)
            {
                _S22 = 1.0f;
            }
            else
            {
                _S22 = 0.0f;
            }
            *_slang_vector_get_element_ptr(&(&d_0)->tMax_0, a_0) = t_0 + (_S20 + (_S21 + _S22) * *_slang_vector_get_element_ptr(&g_0->cellExtent_0, a_0) - _slang_vector_get_element(p_0, a_0)) / _slang_vector_get_element(rd_1, _S17);
            *_slang_vector_get_element_ptr(&(&d_0)->tDelta_0, a_0) = (F32_abs((*_slang_vector_get_element_ptr(&g_0->cellExtent_0, a_0) / _slang_vector_get_element(rd_1, _S17))));
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
    int _S23 = c_0.x;
    bool _S24;
    if(_S23 < int(0))
    {
        _S24 = true;
    }
    else
    {
        _S24 = (c_0.y) < int(0);
    }
    if(_S24)
    {
        _S24 = true;
    }
    else
    {
        _S24 = (c_0.z) < int(0);
    }
    if(_S24)
    {
        _S24 = true;
    }
    else
    {
        _S24 = _S23 >= (g_1->dims_0.x);
    }
    if(_S24)
    {
        _S24 = true;
    }
    else
    {
        _S24 = (c_0.y) >= (g_1->dims_0.y);
    }
    if(_S24)
    {
        _S24 = true;
    }
    else
    {
        _S24 = (c_0.z) >= (g_1->dims_0.z);
    }
    if(_S24)
    {
        return fallback_0;
    }
    float _S25 = __ldg((&(bounds_0)[(c_0.z * g_1->dims_0.y + c_0.y) * g_1->dims_0.x + _S23]));
    return _S25;
}

static __device__ float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_2)
{
    bool _S26;
    if((d_2->tMax_0.x) <= (d_2->tMax_0.y))
    {
        _S26 = (d_2->tMax_0.x) <= (d_2->tMax_0.z);
    }
    else
    {
        _S26 = false;
    }
    if(_S26)
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
    uint _S27 = r_1->state_0 * 747796405U + 2891336453U;
    r_1->state_0 = _S27;
    uint word_0 = ((_S27 >> ((_S27 >> 28U) + 4U)) ^ _S27) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_2, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_13 = clamp_0(depth_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_2 = clamp_1(int((F32_floor((x_13)))), int(0), int(31));
    float2  _S28 = __ldg((&(disp_0)[i_2]));
    float2  _S29 = __ldg((&(disp_0)[i_2 + int(1)]));
    return lerp_1(_S28, _S29, make_float2 (x_13 - float(i_2)));
}

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S30 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S31 = _S30;
    *&((&_S31)->x) = *&((&_S31)->x) + _S30.y * 1664525U;
    *&((&_S31)->y) = *&((&_S31)->y) + _S31.x * 1664525U;
    uint2  _S32 = _S31 ^ (_S31 >> make_uint2 (16U));
    _S31 = _S32;
    *&((&_S31)->x) = *&((&_S31)->x) + _S32.y * 1664525U;
    *&((&_S31)->y) = *&((&_S31)->y) + _S31.x * 1664525U;
    uint2  _S33 = _S31 ^ (_S31 >> make_uint2 (16U));
    _S31 = _S33;
    return _S33;
}

static __device__ float2  hash22_0(int2  c_1, uint salt_0)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_1.x), uint(c_1.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S34 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S34 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float cellField_0(GeneratorInput_0 * g_3, float2  q_0)
{
    float2  gq_0 = (q_0 - g_3->cellDrift_0) / make_float2 (g_3->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_0(gq_0);
    int2  _S35 = make_int2 ((int)gf_0.x, (int)gf_0.y);
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
            int2  o_0 = _S35 + make_int2 (i_3, j_0);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_3 = i_3 + int(1);
                continue;
            }
            float2  _S36 = make_float2 ((float)o_0.x, (float)o_0.y);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(gq_0 - (_S36 + make_float2 (0.5f) + (hash22_0(o_0, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f))) * 2.20000004768371582f);
            i_3 = i_3 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S37 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S38 = _S37;
    *&((&_S38)->x) = *&((&_S38)->x) + _S37.y * _S37.z;
    *&((&_S38)->y) = *&((&_S38)->y) + _S38.z * _S38.x;
    *&((&_S38)->z) = *&((&_S38)->z) + _S38.x * _S38.y;
    uint3  _S39 = _S38 ^ (_S38 >> make_uint3 (16U));
    _S38 = _S39;
    *&((&_S38)->x) = *&((&_S38)->x) + _S39.y * _S39.z;
    *&((&_S38)->y) = *&((&_S38)->y) + _S38.z * _S38.x;
    *&((&_S38)->z) = *&((&_S38)->z) + _S38.x * _S38.y;
    return _S38;
}

static __device__ float3  hash33_0(int3  c_2)
{
    uint3  h_1 = pcg3d_0(make_uint3 (uint(c_2.x), uint(c_2.y), uint(c_2.z)));
    float3  _S40 = make_float3 ((float)h_1.x, (float)h_1.y, (float)h_1.z);
    return _S40 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_1)
{
    float3  fi_0 = floor_1(p_1);
    int3  _S41 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_1 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S42 = u_0.x;
    float _S43 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_0(hash33_0(_S41), f_0), dot_0(hash33_0(_S41 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S42), lerp_0(dot_0(hash33_0(_S41 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S41 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S42), _S43), lerp_0(lerp_0(dot_0(hash33_0(_S41 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S41 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S42), lerp_0(dot_0(hash33_0(_S41 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S41 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S42), _S43), u_0.z);
}

static __device__ float fbm_0(float3  p_2, int octaves_1)
{
    int i_4 = int(0);
    float amp_0 = 0.5f;
    float3  _S44 = p_2;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S44);
        float norm_1 = norm_0 + amp_0;
        float3  _S45 = _S44 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_4 = i_4 + int(1);
        amp_0 = amp_1;
        _S44 = _S45;
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
    bool _S46;
    if(depth_1 < 0.0f)
    {
        _S46 = true;
    }
    else
    {
        _S46 = depth_1 > (g_4->streakLength_0);
    }
    if(_S46)
    {
        return 0.0f;
    }
    float2  _S47 = float2 {p_3.x, p_3.z};
    float2  _S48 = driftAt_0(g_4, disp_1, depth_1);
    float2  source_0 = _S47 - _S48;
    float _S49 = cellField_0(g_4, source_0);
    if(_S49 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S49 * (F32_exp((- g_4->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, depth_1)) * (F32_max((1.0f + g_4->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_4->detailScale_0)).x, (source_0 / make_float2 (g_4->detailScale_0)).y, depth_1 / (F32_max((g_4->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_4->timeSeconds_0 * 0.00999999977648258f), g_4->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((g_4->streakLength_0), (1.0f)));
}

static __device__ float densityAt_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_2, float3  p_4)
{
    float _S50 = p_4.y;
    bool _S51;
    if(_S50 < (m_1->slabBottom_0))
    {
        _S51 = true;
    }
    else
    {
        _S51 = _S50 > (m_1->slabTop_0);
    }
    if(_S51)
    {
        return 0.0f;
    }
    int _S52 = m_1->mode_0;
    if((m_1->mode_0) == int(0))
    {
        return m_1->density_0;
    }
    if(_S52 == int(2))
    {
        float _S53 = iceDensity_0(&m_1->gen_0, disp_2, p_4);
        return _S53;
    }
    float3  d_3 = (p_4 - m_1->coreCentre_0) / make_float3 ((F32_max((m_1->coreRadius_0), (9.99999997475242708e-07f))));
    return m_1->density_0 + m_1->coreDensity_0 * (F32_exp((- dot_0(d_3, d_3))));
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_3, Rng_0 * rng_0, float3  ro_2, float3  rd_2, float3  * scatterPoint_0, float * distance_0, int * steps_0)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_1;
    float t1_1;
    bool _S54 = slabRange_0(m_2, ro_2, rd_2, &t0_1, &t1_1);
    if(!_S54)
    {
        return false;
    }
    float _S55 = (F32_max((t0_1), (0.0f)));
    Dda_0 _S56 = ddaInit_0(g_5, ro_2, rd_2, _S55);
    Dda_0 dda_0 = _S56;
    int i_5 = int(0);
    float t_1 = _S55;
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
        float _S57 = gridBound_0(g_5, bounds_1, (&dda_0)->cell_0, m_2->majorant_0);
        Dda_0 _S58 = dda_0;
        float _S59 = ddaExit_0(&_S58);
        float _S60 = (F32_min((_S59), (t1_1)));
        if(_S57 <= 0.0f)
        {
            if(_S60 >= t1_1)
            {
                return false;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S60;
            i_5 = i_5 + int(1);
            continue;
        }
        float _S61 = randFloat_0(rng_0);
        float t_2 = t_1 - (F32_log(((F32_max((1.0f - _S61), (1.00000001168609742e-07f)))))) / _S57;
        if(t_2 >= _S60)
        {
            if(_S60 >= t1_1)
            {
                return false;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S60;
            i_5 = i_5 + int(1);
            continue;
        }
        float3  p_5 = ro_2 + rd_2 * make_float3 (t_2);
        float _S62 = randFloat_0(rng_0);
        float _S63 = densityAt_0(m_2, disp_3, p_5);
        if(_S62 < (_S63 / _S57))
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
    float len2_0 = dot_0(v_2, v_2);
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
    float _S64;
    if(v_3 < lo_0)
    {
        _S64 = lo_0;
    }
    else
    {
        if(v_3 > hi_0)
        {
            _S64 = hi_0;
        }
        else
        {
            _S64 = v_3;
        }
    }
    return _S64;
}

static __device__ float altitudeFromQ_0(float q_1, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_1;
    float _S65;
    if(rr_0 > 0.0f)
    {
        _S65 = rr_0;
    }
    else
    {
        _S65 = 0.0f;
    }
    return q_1 / (planetRadius_2 + (F32_sqrt((_S65))));
}

static __device__ void sunOpticalDepth_0(float altitude_1, float bSun_0, float planetRadius_3, float atmosphereHeight_0, float rayleighScaleHeight_0, float * outRayleigh_0, float * outMie_0)
{
    *outRayleigh_0 = 0.0f;
    *outMie_0 = 0.0f;
    float cGround_0 = shellC_0(altitude_1, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(bSun_0, shellC_0(altitude_1, planetRadius_3, atmosphereHeight_0));
    if(tTop_0 <= 0.0f)
    {
        return;
    }
    if((shellEnter_0(bSun_0, cGround_0)) > 0.0f)
    {
        *outRayleigh_0 = 1.0e+09f;
        *outMie_0 = 1.0e+09f;
        return;
    }
    float sPrev_0 = 0.0f;
    int i_6 = int(0);
    for(;;)
    {
        if(i_6 < int(8))
        {
        }
        else
        {
            break;
        }
        int _S66 = i_6 + int(1);
        float sNext_0 = tTop_0 * float(_S66 * _S66) * 0.015625f;
        float ds_0 = sNext_0 - sPrev_0;
        float sMid_0 = (sPrev_0 + sNext_0) * 0.5f;
        if(ds_0 <= 0.0f)
        {
            sPrev_0 = sNext_0;
            i_6 = _S66;
            continue;
        }
        float h_2 = altitudeFromQ_0(cGround_0 + 2.0f * sMid_0 * bSun_0 + sMid_0 * sMid_0, planetRadius_3);
        float hc_0;
        if(h_2 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_2;
        }
        float _S67 = - hc_0;
        *outRayleigh_0 = *outRayleigh_0 + (F32_exp((_S67 / rayleighScaleHeight_0))) * ds_0;
        *outMie_0 = *outMie_0 + (F32_exp((_S67 / 1200.0f))) * ds_0;
        sPrev_0 = sNext_0;
        i_6 = _S66;
    }
    return;
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_7)
{
    return 20.0f * p_7->sunIntensity_0;
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_8, float3  rayDir_0, bool includeSunDisc_0)
{
    float3  _S68 = sunDirection_0(p_8);
    float _S69 = p_8->planetRadius_0;
    float planetRadius_4;
    if((p_8->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S69;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S70 = p_8->scaleHeight_0;
    float scaleHeight_1;
    if((p_8->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S70;
    }
    else
    {
        scaleHeight_1 = 1.0f;
    }
    float atmosphereHeight_1 = scaleHeight_1 * 8.0f;
    float _S71 = planetRadius_4 + 2.0f;
    float _S72 = rayDir_0.y;
    float b_2 = _S71 * _S72;
    float cGround_1 = shellC_0(2.0f, planetRadius_4, 0.0f);
    float tTop_1 = shellExit_0(b_2, shellC_0(2.0f, planetRadius_4, atmosphereHeight_1));
    if(tTop_1 <= 0.0f)
    {
        return make_float3 (0.0f, 0.0f, 0.0f);
    }
    float tGround_0 = shellEnter_0(b_2, cGround_1);
    bool hitsGround_0 = tGround_0 > 0.0f;
    float safeSolid_0;
    if(hitsGround_0)
    {
        safeSolid_0 = tGround_0;
    }
    else
    {
        safeSolid_0 = tTop_1;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_8->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_0, _S68), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_6 = clampf_0(p_8->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S73 = g_6 * g_6;
    float hgDenom_0 = 1.0f + _S73 - 2.0f * g_6 * cosTheta_0;
    float _S74 = 1.0f - _S73;
    float _S75 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S74 / (_S75 * (F32_sqrt((tPrev_0))));
    float3  _S76 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    float3  sumR_0 = _S76;
    float3  sumM_0 = _S76;
    int i_7 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_7 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S77 = i_7 + int(1);
        float tNext_0 = safeSolid_0 * float(_S77 * _S77) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_7 = _S77;
            continue;
        }
        float h_3 = altitudeFromQ_0(cGround_1 + 2.0f * tMid_0 * b_2 + tMid_0 * tMid_0, planetRadius_4);
        float hc_1;
        if(h_3 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_3;
        }
        float _S78 = - hc_1;
        float dR_0 = (F32_exp((_S78 / scaleHeight_1))) * dt_0;
        float dM_0 = (F32_exp((_S78 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        float sunR_0;
        float sunM_0;
        sunOpticalDepth_0(hc_1, dot_0(make_float3 (rayDir_0.x * tMid_0, _S71 + _S72 * tMid_0, rayDir_0.z * tMid_0), _S68), planetRadius_4, atmosphereHeight_1, scaleHeight_1, &sunR_0, &sunM_0);
        float3  transmittance_0 = make_float3 ((F32_exp((- (betaR_0.x * (depthR_1 + sunR_0) + betaMExt_0 * (depthM_1 + sunM_0))))), (F32_exp((- (betaR_0.y * (depthR_1 + sunR_0) + betaMExt_0 * (depthM_1 + sunM_0))))), (F32_exp((- (betaR_0.z * (depthR_1 + sunR_0) + betaMExt_0 * (depthM_1 + sunM_0))))));
        float3  _S79 = sumM_0 + transmittance_0 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_0 * make_float3 (dR_0);
        sumM_0 = _S79;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_7 = _S77;
    }
    float _S80 = sunIrradianceTop_0(p_8);
    float3  radiance_0 = (sumR_0 * betaR_0 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S80);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_0.x * tGround_0, _S71 + _S72 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S68), 0.0f, 1.0f);
        float sunR_1;
        float sunM_1;
        sunOpticalDepth_0(0.0f, dot_0(groundPoint_0, _S68), planetRadius_4, atmosphereHeight_1, scaleHeight_1, &sunR_1, &sunM_1);
        float _S81 = betaR_0.x;
        float _S82 = betaR_0.y;
        float _S83 = betaR_0.z;
        float _S84 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + make_float3 ((F32_exp((- (_S81 * depthR_0 + _S84)))), (F32_exp((- (_S82 * depthR_0 + _S84)))), (F32_exp((- (_S83 * depthR_0 + _S84))))) * make_float3 ((F32_exp((- (_S81 * sunR_1 + betaMExt_0 * sunM_1)))), (F32_exp((- (_S82 * sunR_1 + betaMExt_0 * sunM_1)))), (F32_exp((- (_S83 * sunR_1 + betaMExt_0 * sunM_1))))) * make_float3 (p_8->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S80);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S85;
    if(!hitsGround_0)
    {
        _S85 = includeSunDisc_0;
    }
    else
    {
        _S85 = false;
    }
    if(_S85)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_8->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S86 = betaMExt_0 * depthM_0;
            float3  viewT_0 = make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S86)))), (F32_exp((- (betaR_0.y * depthR_0 + _S86)))), (F32_exp((- (betaR_0.z * depthR_0 + _S86)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                safeSolid_0 = solidAngle_0;
            }
            else
            {
                safeSolid_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * make_float3 (_S80 / safeSolid_0);
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
        float3  _S87 = skyRadiance_0(&e_0->sky_0, dir_0, includeSunDisc_1);
        return _S87;
    }
    return e_0->uniformRadiance_0;
}

static __device__ float transmittance_1(Medium_0 * m_3, MajorantGrid_0 * g_7, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > disp_4, Rng_0 * rng_1, float3  p_9, float3  dir_1, int * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S88 = slabRange_0(m_3, p_9, dir_1, &t0_2, &t1_2);
    if(!_S88)
    {
        return 1.0f;
    }
    float _S89 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S89;
    Dda_0 _S90 = ddaInit_0(g_7, p_9, dir_1, _S89);
    Dda_0 dda_1 = _S90;
    int i_8 = int(0);
    float t_3 = _S89;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_8 < int(1024))
        {
        }
        else
        {
            break;
        }
        *steps_1 = *steps_1 + int(1);
        float _S91 = gridBound_0(g_7, bounds_2, (&dda_1)->cell_0, m_3->majorant_0);
        Dda_0 _S92 = dda_1;
        float _S93 = ddaExit_0(&_S92);
        float _S94 = (F32_min((_S93), (t1_2)));
        if(_S91 <= 0.0f)
        {
            if(_S94 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            t_3 = _S94;
            i_8 = i_8 + int(1);
            continue;
        }
        float _S95 = randFloat_0(rng_1);
        float t_4 = t_3 - (F32_log(((F32_max((1.0f - _S95), (1.00000001168609742e-07f)))))) / _S91;
        if(t_4 >= _S94)
        {
            if(_S94 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            t_3 = _S94;
            i_8 = i_8 + int(1);
            continue;
        }
        float _S96 = densityAt_0(m_3, disp_4, p_9 + dir_1 * make_float3 (t_4));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S96 / _S91)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S97 = randFloat_0(rng_1);
            if(_S97 > 0.5f)
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
        i_8 = i_8 + int(1);
    }
    return tr_0;
}

static __device__ float hg_0(float cosT_0, float g_8)
{
    float _S98 = g_8 * g_8;
    float d_5 = 1.0f + _S98 - 2.0f * g_8 * cosT_0;
    return (1.0f - _S98) / (12.56637096405029297f * d_5 * (F32_sqrt(((F32_max((d_5), (9.99999997475242708e-07f)))))));
}

static __device__ float phaseIce_0(float cosT_1)
{
    float t_5 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_0(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_5 * t_5))) * 0.34999999403953552f;
}

static __device__ float draine_0(float cosT_2, float g_9, float a_1)
{
    float _S99 = g_9 * g_9;
    float _S100 = 2.0f * g_9;
    float d_6 = 1.0f + _S99 - _S100 * cosT_2;
    return (1.0f - _S99) / (12.56637096405029297f * d_6 * (F32_sqrt(((F32_max((d_6), (9.99999997475242708e-07f))))))) * (1.0f + a_1 * cosT_2 * cosT_2) / (1.0f + a_1 * (1.0f + _S100 * g_9) / 3.0f);
}

struct PhaseInput_0
{
    float hgG_0;
    float draineG_0;
    float draineAlpha_0;
    float draineW_0;
    int useIce_0;
};

static __device__ float phaseLiquid_0(PhaseInput_0 * p_10, float cosT_3)
{
    return (1.0f - p_10->draineW_0) * hg_0(cosT_3, p_10->hgG_0) + p_10->draineW_0 * draine_0(cosT_3, p_10->draineG_0, p_10->draineAlpha_0);
}

static __device__ float phaseAt_0(PhaseInput_0 * p_11, float cosT_4)
{
    float _S101;
    if((p_11->useIce_0) != int(0))
    {
        _S101 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S102 = phaseLiquid_0(p_11, cosT_4);
        _S101 = _S102;
    }
    return _S101;
}

static __device__ float3  sunTransmittanceAt_0(SkyInput_0 * p_12, float3  worldPos_0)
{
    float3  _S103 = sunDirection_0(p_12);
    float _S104 = p_12->planetRadius_0;
    float planetRadius_5;
    if((p_12->planetRadius_0) > 1000.0f)
    {
        planetRadius_5 = _S104;
    }
    else
    {
        planetRadius_5 = 1000.0f;
    }
    float _S105 = p_12->scaleHeight_0;
    float scaleHeight_2;
    if((p_12->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S105;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float atmosphereHeight_2 = scaleHeight_2 * 8.0f;
    float _S106 = worldPos_0.y;
    float altitude_2;
    if(_S106 > 0.0f)
    {
        altitude_2 = _S106;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    float sunR_2;
    float sunM_2;
    sunOpticalDepth_0(altitude_2, dot_0(make_float3 (worldPos_0.x, planetRadius_5 + _S106, worldPos_0.z), _S103), planetRadius_5, atmosphereHeight_2, scaleHeight_2, &sunR_2, &sunM_2);
    float3  betaR_1 = rayleighCoefficients_0();
    float betaMExt_1 = mieCoefficient_0(p_12->turbidity_0) * 1.11000001430511475f;
    return make_float3 ((F32_exp((- (betaR_1.x * sunR_2 + betaMExt_1 * sunM_2)))), (F32_exp((- (betaR_1.y * sunR_2 + betaMExt_1 * sunM_2)))), (F32_exp((- (betaR_1.z * sunR_2 + betaMExt_1 * sunM_2)))));
}

static __device__ float3  sampleHG_0(Rng_0 * rng_2, float3  wo_0, float g_10, float * cosT_5)
{
    float _S107 = clamp_0(g_10, -0.99900001287460327f, 0.99900001287460327f);
    float u1_0 = randFloat_0(rng_2);
    float u2_0 = randFloat_0(rng_2);
    if((F32_abs((_S107))) < 0.00100000004749745f)
    {
        *cosT_5 = 1.0f - 2.0f * u1_0;
    }
    else
    {
        float _S108 = _S107 * _S107;
        float _S109 = 2.0f * _S107;
        float s_4 = (1.0f - _S108) / (1.0f - _S107 + _S109 * u1_0);
        *cosT_5 = (1.0f + _S108 - s_4 * s_4) / _S109;
    }
    float _S110 = clamp_0(*cosT_5, -1.0f, 1.0f);
    *cosT_5 = _S110;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S110 * _S110))))));
    float phi_0 = 6.28318548202514648f * u2_0;
    float3  w_0 = normalize_0(wo_0);
    float3  a_2;
    if((F32_abs((w_0.y))) < 0.94999998807907104f)
    {
        a_2 = make_float3 (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_2 = make_float3 (1.0f, 0.0f, 0.0f);
    }
    float3  u_1 = normalize_0(cross_0(a_2, w_0));
    return normalize_0(make_float3 (sinT_0 * (F32_cos((phi_0)))) * u_1 + make_float3 (sinT_0 * (F32_sin((phi_0)))) * cross_0(w_0, u_1) + make_float3 (*cosT_5) * w_0);
}

static __device__ float3  samplePhaseDir_0(PhaseInput_0 * p_13, Rng_0 * rng_3, float3  wo_1, float * weight_0)
{
    float cosT_6;
    float3  dir_2;
    float _S111;
    if((p_13->useIce_0) != int(0))
    {
        float _S112 = randFloat_0(rng_3);
        if(_S112 < 0.72000002861022949f)
        {
            float3  _S113 = sampleHG_0(rng_3, wo_1, 0.85000002384185791f, &cosT_6);
            dir_2 = _S113;
        }
        else
        {
            float3  _S114 = sampleHG_0(rng_3, wo_1, 0.0f, &cosT_6);
            dir_2 = _S114;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_6, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S111 = phaseIce_0(cosT_6) / pdf_0;
        }
        else
        {
            _S111 = 0.0f;
        }
        *weight_0 = _S111;
    }
    else
    {
        float _S115 = randFloat_0(rng_3);
        float _S116 = p_13->draineW_0;
        if(_S115 < (p_13->draineW_0))
        {
            float3  _S117 = sampleHG_0(rng_3, wo_1, p_13->draineG_0, &cosT_6);
            dir_2 = _S117;
        }
        else
        {
            float3  _S118 = sampleHG_0(rng_3, wo_1, p_13->hgG_0, &cosT_6);
            dir_2 = _S118;
        }
        float pdf_1 = _S116 * hg_0(cosT_6, p_13->draineG_0) + (1.0f - _S116) * hg_0(cosT_6, p_13->hgG_0);
        if(pdf_1 > 9.99999971718068537e-10f)
        {
            float _S119 = phaseLiquid_0(p_13, cosT_6);
            _S111 = _S119 / pdf_1;
        }
        else
        {
            _S111 = 0.0f;
        }
        *weight_0 = _S111;
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

static __device__ TraceResult_0 trace_0(Scene_0 * s_5, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > drift_0, Rng_0 * rng_4, float3  ro_3, float3  rd_3)
{
    TraceResult_0 r_2;
    (&r_2)->pathRadiance_0 = make_float3 (0.0f, 0.0f, 0.0f);
    (&r_2)->scatterEvents_0 = int(0);
    (&r_2)->capped_0 = int(0);
    (&r_2)->trackingSteps_0 = int(0);
    float3  _S120 = make_float3 (1.0f, 1.0f, 1.0f);
    int _S121 = (I32_min((s_5->maxBounces_0), (int(256))));
    float3  _S122 = ro_3;
    float3  _S123 = rd_3;
    int bounce_0 = int(0);
    float3  throughput_0 = _S120;
    for(;;)
    {
        if(bounce_0 < int(256))
        {
        }
        else
        {
            break;
        }
        if(bounce_0 >= _S121)
        {
            (&r_2)->capped_0 = int(1);
            break;
        }
        float3  p_14;
        float dist_0;
        bool _S124 = sampleFreeFlight_0(&s_5->medium_0, &s_5->grid_0, bounds_3, drift_0, rng_4, _S122, _S123, &p_14, &dist_0, &(&r_2)->trackingSteps_0);
        if(!_S124)
        {
            float3  _S125 = environmentRadiance_0(&s_5->environment_0, _S123, bounce_0 == int(0));
            (&r_2)->pathRadiance_0 = (&r_2)->pathRadiance_0 + throughput_0 * _S125;
            break;
        }
        (&r_2)->scatterEvents_0 = (&r_2)->scatterEvents_0 + int(1);
        float3  _S126 = s_5->sunDir_0;
        float _S127 = transmittance_1(&s_5->medium_0, &s_5->grid_0, bounds_3, drift_0, rng_4, p_14 + s_5->sunDir_0 * make_float3 (s_5->shadowOffset_0), s_5->sunDir_0, &(&r_2)->trackingSteps_0);
        if(_S127 > 0.0f)
        {
            float _S128 = phaseAt_0(ph_0, dot_0(_S123, _S126));
            float3  _S129 = s_5->sunIrradiance_0;
            float3  sunE_0;
            if(((&s_5->environment_0)->envMode_0) == int(1))
            {
                float _S130 = sunIrradianceTop_0(&(&s_5->environment_0)->sky_0);
                float3  _S131 = sunTransmittanceAt_0(&(&s_5->environment_0)->sky_0, p_14);
                sunE_0 = make_float3 (_S130) * _S131;
            }
            else
            {
                sunE_0 = _S129;
            }
            (&r_2)->pathRadiance_0 = (&r_2)->pathRadiance_0 + throughput_0 * s_5->albedo_0 * make_float3 (_S128) * make_float3 (_S127) * sunE_0;
        }
        float w_1;
        float3  _S132 = samplePhaseDir_0(ph_0, rng_4, _S123, &w_1);
        float3  throughput_1 = throughput_0 * (s_5->albedo_0 * make_float3 (w_1));
        float3  _S133 = p_14;
        if(bounce_0 >= (s_5->rrStartBounce_0))
        {
            float p2_0 = clamp_0((F32_max((throughput_1.x), ((F32_max((throughput_1.y), (throughput_1.z)))))), 0.05000000074505806f, 1.0f);
            float _S134 = randFloat_0(rng_4);
            if(_S134 > p2_0)
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
        _S122 = _S133;
        _S123 = _S132;
        bounce_0 = bounce_1;
    }
    return r_2;
}

extern "C" __global__ void traceTrial(Scene_0 scene_0, PhaseInput_0 phase_0, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > drift_1, float3  origin_1, float3  direction_0, RWStructuredBuffer<float3 > outRadiance_0, RWStructuredBuffer<int> outScatterEvents_0, RWStructuredBuffer<int> outCapped_0, RWStructuredBuffer<int> outSteps_0, uint seed_2, int count_0)
{
    int i_9 = int((blockIdx * blockDim + threadIdx).x);
    if(i_9 >= count_0)
    {
        return;
    }
    Rng_0 rng_5 = makeRngForIndex_0(seed_2, i_9);
    Scene_0 _S135 = scene_0;
    PhaseInput_0 _S136 = phase_0;
    TraceResult_0 _S137 = trace_0(&_S135, &_S136, bounds_4, drift_1, &rng_5, origin_1, direction_0);
    *(&(outRadiance_0)[i_9]) = _S137.pathRadiance_0;
    *(&(outScatterEvents_0)[i_9]) = _S137.scatterEvents_0;
    *(&(outCapped_0)[i_9]) = _S137.capped_0;
    *(&(outSteps_0)[i_9]) = _S137.trackingSteps_0;
    return;
}

extern "C" __global__ void phaseValueTrial(PhaseInput_0 phase_1, StructuredBuffer<float> inCos_0, RWStructuredBuffer<float> outPhase_0, int count_1)
{
    int i_10 = int((blockIdx * blockDim + threadIdx).x);
    if(i_10 >= count_1)
    {
        return;
    }
    float * _S138 = (&(outPhase_0)[i_10]);
    float _S139 = __ldg((&(inCos_0)[i_10]));
    PhaseInput_0 _S140 = phase_1;
    float _S141 = phaseAt_0(&_S140, _S139);
    *_S138 = _S141;
    return;
}

static __device__ PhaseInput_0 phaseFromDropletDiameter_0(float diameterMicrons_0, int useIce_1)
{
    float d_7 = clamp_0(diameterMicrons_0, 5.0f, 50.0f);
    PhaseInput_0 p_15;
    (&p_15)->hgG_0 = clamp_0((F32_exp((-0.09905669838190079f / (d_7 - 1.6715400218963623f)))), -0.99900001287460327f, 0.99900001287460327f);
    (&p_15)->draineG_0 = clamp_0((F32_exp((- (2.20678997039794922f / (d_7 + 3.91029000282287598f)) - 0.4289340078830719f))), -0.99900001287460327f, 0.99900001287460327f);
    (&p_15)->draineAlpha_0 = (F32_exp((3.62489008903503418f - 8.29288005828857422f / (d_7 + 5.52825021743774414f))));
    (&p_15)->draineW_0 = (F32_exp((- (0.59908497333526611f / (d_7 - 0.64158302545547485f)) - 0.66588801145553589f)));
    (&p_15)->useIce_0 = useIce_1;
    return p_15;
}

extern "C" __global__ void phaseParamsTrial(float diameterMicrons_1, RWStructuredBuffer<float4 > outParams_0)
{
    PhaseInput_0 p_16 = phaseFromDropletDiameter_0(diameterMicrons_1, int(0));
    *(&(outParams_0)[int(0)]) = make_float4 (p_16.hgG_0, p_16.draineG_0, p_16.draineAlpha_0, p_16.draineW_0);
    return;
}

