// GENERATED FROM Transport.slang BY slangc -- DO NOT EDIT.
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

static __device__ float smoothstep_0(float min_1, float max_1, float x_7)
{
    float _S1 = saturate_0((x_7 - min_1) / (max_1 - min_1));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static __device__ float length_0(float2  x_8)
{
    return (F32_sqrt((dot_0(x_8, x_8))));
}

static __device__ float2  floor_0(float2  x_9)
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
        *_slang_vector_get_element_ptr(&result_2, i_2) = (F32_floor((_slang_vector_get_element(x_9, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ float2  lerp_1(float2  x_10, float2  y_5, float2  s_1)
{
    return x_10 + (y_5 - x_10) * s_1;
}

static __device__ int clamp_1(int x_11, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_11), (minBound_1)))), (maxBound_1)));
}

static __device__ float3  floor_1(float3  x_12)
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
        *_slang_vector_get_element_ptr(&result_3, i_3) = (F32_floor((_slang_vector_get_element(x_12, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
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
    float _S2 = rd_0.y;
    bool _S3;
    if((F32_abs((_S2))) < 9.99999997475242708e-07f)
    {
        float _S4 = ro_0.y;
        if(_S4 < (m_0->slabBottom_0))
        {
            _S3 = true;
        }
        else
        {
            _S3 = _S4 > (m_0->slabTop_0);
        }
        if(_S3)
        {
            return false;
        }
    }
    else
    {
        float _S5 = ro_0.y;
        float ta_0 = (m_0->slabBottom_0 - _S5) / _S2;
        float tb_0 = (m_0->slabTop_0 - _S5) / _S2;
        *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
        *t1_0 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    }
    float _S6 = (F32_min((*t1_0), (1.2e+05f)));
    *t1_0 = _S6;
    if(_S6 > (*t0_0))
    {
        _S3 = (*t1_0) > 0.0f;
    }
    else
    {
        _S3 = false;
    }
    return _S3;
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
        int3  _S7 = make_int3 (int(0), int(0), int(0));
        (&d_0)->cell_0 = _S7;
        (&d_0)->stepDir_0 = _S7;
        float3  _S8 = make_float3 (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_0)->tMax_0 = _S8;
        (&d_0)->tDelta_0 = _S8;
        return d_0;
    }
    float3  p_0 = ro_1 + rd_1 * make_float3 (t_0);
    float3  _S9 = floor_1((p_0 - g_0->origin_0) / g_0->cellExtent_0);
    int3  _S10 = make_int3 ((int)_S9.x, (int)_S9.y, (int)_S9.z);
    (&d_0)->cell_0 = _S10;
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
        int _S11 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            *_slang_vector_get_element_ptr(&(&d_0)->stepDir_0, a_0) = int(0);
            *_slang_vector_get_element_ptr(&(&d_0)->tMax_0, a_0) = 1.00000001504746622e+30f;
            *_slang_vector_get_element_ptr(&(&d_0)->tDelta_0, a_0) = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S12 = _slang_vector_get_element(rd_1, _S11) > 0.0f;
            int _S13;
            if(_S12)
            {
                _S13 = int(1);
            }
            else
            {
                _S13 = int(-1);
            }
            *_slang_vector_get_element_ptr(&(&d_0)->stepDir_0, a_0) = _S13;
            float _S14 = *_slang_vector_get_element_ptr(&g_0->origin_0, a_0);
            float _S15 = float(*_slang_vector_get_element_ptr(&(&d_0)->cell_0, a_0));
            float _S16;
            if(_S12)
            {
                _S16 = 1.0f;
            }
            else
            {
                _S16 = 0.0f;
            }
            *_slang_vector_get_element_ptr(&(&d_0)->tMax_0, a_0) = t_0 + (_S14 + (_S15 + _S16) * *_slang_vector_get_element_ptr(&g_0->cellExtent_0, a_0) - _slang_vector_get_element(p_0, a_0)) / _slang_vector_get_element(rd_1, _S11);
            *_slang_vector_get_element_ptr(&(&d_0)->tDelta_0, a_0) = (F32_abs((*_slang_vector_get_element_ptr(&g_0->cellExtent_0, a_0) / _slang_vector_get_element(rd_1, _S11))));
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
    int _S17 = c_0.x;
    bool _S18;
    if(_S17 < int(0))
    {
        _S18 = true;
    }
    else
    {
        _S18 = (c_0.y) < int(0);
    }
    if(_S18)
    {
        _S18 = true;
    }
    else
    {
        _S18 = (c_0.z) < int(0);
    }
    if(_S18)
    {
        _S18 = true;
    }
    else
    {
        _S18 = _S17 >= (g_1->dims_0.x);
    }
    if(_S18)
    {
        _S18 = true;
    }
    else
    {
        _S18 = (c_0.y) >= (g_1->dims_0.y);
    }
    if(_S18)
    {
        _S18 = true;
    }
    else
    {
        _S18 = (c_0.z) >= (g_1->dims_0.z);
    }
    if(_S18)
    {
        return fallback_0;
    }
    float _S19 = __ldg((&(bounds_0)[(c_0.z * g_1->dims_0.y + c_0.y) * g_1->dims_0.x + _S17]));
    return _S19;
}

static __device__ float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_2)
{
    bool _S20;
    if((d_2->tMax_0.x) <= (d_2->tMax_0.y))
    {
        _S20 = (d_2->tMax_0.x) <= (d_2->tMax_0.z);
    }
    else
    {
        _S20 = false;
    }
    if(_S20)
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
    uint _S21 = r_1->state_0 * 747796405U + 2891336453U;
    r_1->state_0 = _S21;
    uint word_0 = ((_S21 >> ((_S21 >> 28U) + 4U)) ^ _S21) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_2, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_13 = clamp_0(depth_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_4 = clamp_1(int((F32_floor((x_13)))), int(0), int(31));
    float2  _S22 = __ldg((&(disp_0)[i_4]));
    float2  _S23 = __ldg((&(disp_0)[i_4 + int(1)]));
    return lerp_1(_S22, _S23, make_float2 (x_13 - float(i_4)));
}

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S24 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S25 = _S24;
    *&((&_S25)->x) = *&((&_S25)->x) + _S24.y * 1664525U;
    *&((&_S25)->y) = *&((&_S25)->y) + _S25.x * 1664525U;
    uint2  _S26 = _S25 ^ (_S25 >> make_uint2 (16U));
    _S25 = _S26;
    *&((&_S25)->x) = *&((&_S25)->x) + _S26.y * 1664525U;
    *&((&_S25)->y) = *&((&_S25)->y) + _S25.x * 1664525U;
    uint2  _S27 = _S25 ^ (_S25 >> make_uint2 (16U));
    _S25 = _S27;
    return _S27;
}

static __device__ float2  hash22_0(int2  c_1, uint salt_0)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_1.x), uint(c_1.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S28 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S28 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float cellField_0(GeneratorInput_0 * g_3, float2  q_0)
{
    float2  gq_0 = (q_0 - g_3->cellDrift_0) / make_float2 (g_3->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_0(gq_0);
    int2  _S29 = make_int2 ((int)gf_0.x, (int)gf_0.y);
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
            int2  o_0 = _S29 + make_int2 (i_5, j_0);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_5 = i_5 + int(1);
                continue;
            }
            float2  _S30 = make_float2 ((float)o_0.x, (float)o_0.y);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(gq_0 - (_S30 + make_float2 (0.5f) + (hash22_0(o_0, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f))) * 2.20000004768371582f);
            i_5 = i_5 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S31 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S32 = _S31;
    *&((&_S32)->x) = *&((&_S32)->x) + _S31.y * _S31.z;
    *&((&_S32)->y) = *&((&_S32)->y) + _S32.z * _S32.x;
    *&((&_S32)->z) = *&((&_S32)->z) + _S32.x * _S32.y;
    uint3  _S33 = _S32 ^ (_S32 >> make_uint3 (16U));
    _S32 = _S33;
    *&((&_S32)->x) = *&((&_S32)->x) + _S33.y * _S33.z;
    *&((&_S32)->y) = *&((&_S32)->y) + _S32.z * _S32.x;
    *&((&_S32)->z) = *&((&_S32)->z) + _S32.x * _S32.y;
    return _S32;
}

static __device__ float3  hash33_0(int3  c_2)
{
    uint3  h_1 = pcg3d_0(make_uint3 (uint(c_2.x), uint(c_2.y), uint(c_2.z)));
    float3  _S34 = make_float3 ((float)h_1.x, (float)h_1.y, (float)h_1.z);
    return _S34 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_1)
{
    float3  fi_0 = floor_1(p_1);
    int3  _S35 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_1 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S36 = u_0.x;
    float _S37 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_1(hash33_0(_S35), f_0), dot_1(hash33_0(_S35 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S36), lerp_0(dot_1(hash33_0(_S35 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S35 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S36), _S37), lerp_0(lerp_0(dot_1(hash33_0(_S35 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S35 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S36), lerp_0(dot_1(hash33_0(_S35 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S35 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S36), _S37), u_0.z);
}

static __device__ float fbm_0(float3  p_2, int octaves_1)
{
    int i_6 = int(0);
    float amp_0 = 0.5f;
    float3  _S38 = p_2;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S38);
        float norm_1 = norm_0 + amp_0;
        float3  _S39 = _S38 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_6 = i_6 + int(1);
        amp_0 = amp_1;
        _S38 = _S39;
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
    bool _S40;
    if(depth_1 < 0.0f)
    {
        _S40 = true;
    }
    else
    {
        _S40 = depth_1 > (g_4->streakLength_0);
    }
    if(_S40)
    {
        return 0.0f;
    }
    float2  _S41 = float2 {p_3.x, p_3.z};
    float2  _S42 = driftAt_0(g_4, disp_1, depth_1);
    float2  source_0 = _S41 - _S42;
    float _S43 = cellField_0(g_4, source_0);
    if(_S43 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S43 * (F32_exp((- g_4->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, depth_1)) * (F32_max((1.0f + g_4->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_4->detailScale_0)).x, (source_0 / make_float2 (g_4->detailScale_0)).y, depth_1 / (F32_max((g_4->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_4->timeSeconds_0 * 0.00999999977648258f), g_4->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((g_4->streakLength_0), (1.0f)));
}

static __device__ float densityAt_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_2, float3  p_4)
{
    float _S44 = p_4.y;
    bool _S45;
    if(_S44 < (m_1->slabBottom_0))
    {
        _S45 = true;
    }
    else
    {
        _S45 = _S44 > (m_1->slabTop_0);
    }
    if(_S45)
    {
        return 0.0f;
    }
    int _S46 = m_1->mode_0;
    if((m_1->mode_0) == int(0))
    {
        return m_1->density_0;
    }
    if(_S46 == int(2))
    {
        float _S47 = iceDensity_0(&m_1->gen_0, disp_2, p_4);
        return _S47;
    }
    float3  d_3 = (p_4 - m_1->coreCentre_0) / make_float3 ((F32_max((m_1->coreRadius_0), (9.99999997475242708e-07f))));
    return m_1->density_0 + m_1->coreDensity_0 * (F32_exp((- dot_1(d_3, d_3))));
}

static __device__ float transmittance_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_3, Rng_0 * rng_0, float3  p_5, float3  dir_0, int * steps_0)
{
    float t0_1;
    float t1_1;
    bool _S48 = slabRange_0(m_2, p_5, dir_0, &t0_1, &t1_1);
    if(!_S48)
    {
        return 1.0f;
    }
    float _S49 = (F32_max((t0_1), (0.0f)));
    t0_1 = _S49;
    Dda_0 _S50 = ddaInit_0(g_5, p_5, dir_0, _S49);
    Dda_0 dda_0 = _S50;
    int i_7 = int(0);
    float t_1 = _S49;
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
        *steps_0 = *steps_0 + int(1);
        float _S51 = gridBound_0(g_5, bounds_1, (&dda_0)->cell_0, m_2->majorant_0);
        Dda_0 _S52 = dda_0;
        float _S53 = ddaExit_0(&_S52);
        float _S54 = (F32_min((_S53), (t1_1)));
        if(_S51 <= 0.0f)
        {
            if(_S54 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S54;
            i_7 = i_7 + int(1);
            continue;
        }
        float _S55 = randFloat_0(rng_0);
        float t_2 = t_1 - (F32_log(((F32_max((1.0f - _S55), (1.00000001168609742e-07f)))))) / _S51;
        if(t_2 >= _S54)
        {
            if(_S54 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S54;
            i_7 = i_7 + int(1);
            continue;
        }
        float _S56 = densityAt_0(m_2, disp_3, p_5 + dir_0 * make_float3 (t_2));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S56 / _S51)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S57 = randFloat_0(rng_0);
            if(_S57 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_1 = t_2;
        tr_0 = tr_2;
        i_7 = i_7 + int(1);
    }
    return tr_0;
}

extern "C" __global__ void transmittanceTrial(Medium_0 medium_0, MajorantGrid_0 grid_0, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > drift_0, float3  origin_1, float3  direction_0, RWStructuredBuffer<float> output_0, RWStructuredBuffer<int> outSteps_0, uint seed_1, int count_0)
{
    int i_8 = int((blockIdx * blockDim + threadIdx).x);
    if(i_8 >= count_0)
    {
        return;
    }
    uint s_2 = uint(i_8) * 747796405U + 2891336453U;
    uint s_3 = ((s_2 >> ((s_2 >> 28U) + 4U)) ^ s_2) * 277803737U;
    Rng_0 rng_1 = makeRng_0(((s_3 >> 22U) ^ s_3) ^ seed_1);
    int steps_1 = int(0);
    float * _S58 = (&(output_0)[i_8]);
    Medium_0 _S59 = medium_0;
    MajorantGrid_0 _S60 = grid_0;
    float _S61 = transmittance_0(&_S59, &_S60, bounds_2, drift_0, &rng_1, origin_1, direction_0, &steps_1);
    *_S58 = _S61;
    *(&(outSteps_0)[i_8]) = steps_1;
    return;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_3, MajorantGrid_0 * g_6, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > disp_4, Rng_0 * rng_2, float3  ro_2, float3  rd_2, float3  * scatterPoint_0, float * distance_0, int * steps_2)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_2;
    float t1_2;
    bool _S62 = slabRange_0(m_3, ro_2, rd_2, &t0_2, &t1_2);
    if(!_S62)
    {
        return false;
    }
    float _S63 = (F32_max((t0_2), (0.0f)));
    Dda_0 _S64 = ddaInit_0(g_6, ro_2, rd_2, _S63);
    Dda_0 dda_1 = _S64;
    int i_9 = int(0);
    float t_3 = _S63;
    for(;;)
    {
        if(i_9 < int(1024))
        {
        }
        else
        {
            break;
        }
        *steps_2 = *steps_2 + int(1);
        float _S65 = gridBound_0(g_6, bounds_3, (&dda_1)->cell_0, m_3->majorant_0);
        Dda_0 _S66 = dda_1;
        float _S67 = ddaExit_0(&_S66);
        float _S68 = (F32_min((_S67), (t1_2)));
        if(_S65 <= 0.0f)
        {
            if(_S68 >= t1_2)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            t_3 = _S68;
            i_9 = i_9 + int(1);
            continue;
        }
        float _S69 = randFloat_0(rng_2);
        float t_4 = t_3 - (F32_log(((F32_max((1.0f - _S69), (1.00000001168609742e-07f)))))) / _S65;
        if(t_4 >= _S68)
        {
            if(_S68 >= t1_2)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            t_3 = _S68;
            i_9 = i_9 + int(1);
            continue;
        }
        float3  p_6 = ro_2 + rd_2 * make_float3 (t_4);
        float _S70 = randFloat_0(rng_2);
        float _S71 = densityAt_0(m_3, disp_4, p_6);
        if(_S70 < (_S71 / _S65))
        {
            *scatterPoint_0 = p_6;
            *distance_0 = t_4;
            return true;
        }
        t_3 = t_4;
        i_9 = i_9 + int(1);
    }
    return false;
}

extern "C" __global__ void freeFlightTrial(Medium_0 medium_1, MajorantGrid_0 grid_1, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > drift_1, float3  origin_2, float3  direction_1, RWStructuredBuffer<float> outDistance_0, RWStructuredBuffer<int> outSteps_1, uint seed_2, int count_1)
{
    int i_10 = int((blockIdx * blockDim + threadIdx).x);
    if(i_10 >= count_1)
    {
        return;
    }
    uint s_4 = uint(i_10) * 747796405U + 2891336453U;
    uint s_5 = ((s_4 >> ((s_4 >> 28U) + 4U)) ^ s_4) * 277803737U;
    Rng_0 rng_3 = makeRng_0(((s_5 >> 22U) ^ s_5) ^ seed_2);
    int steps_3 = int(0);
    float * _S72 = (&(outDistance_0)[i_10]);
    Medium_0 _S73 = medium_1;
    MajorantGrid_0 _S74 = grid_1;
    float3  hit_0;
    float dist_0;
    bool _S75 = sampleFreeFlight_0(&_S73, &_S74, bounds_4, drift_1, &rng_3, origin_2, direction_1, &hit_0, &dist_0, &steps_3);
    float _S76;
    if(_S75)
    {
        _S76 = dist_0;
    }
    else
    {
        _S76 = -1.0f;
    }
    *_S72 = _S76;
    *(&(outSteps_1)[i_10]) = steps_3;
    return;
}

extern "C" __global__ void rngTrial(RWStructuredBuffer<float> output_1, uint seed_3, int count_2)
{
    int i_11 = int((blockIdx * blockDim + threadIdx).x);
    if(i_11 >= count_2)
    {
        return;
    }
    Rng_0 rng_4 = makeRng_0(seed_3 + uint(i_11));
    float * _S77 = (&(output_1)[i_11]);
    float _S78 = randFloat_0(&rng_4);
    *_S77 = _S78;
    return;
}

static __device__ void driftRange_0(GeneratorInput_0 * g_7, StructuredBuffer<float2 > disp_5, float d0_0, float d1_0, float2  * lo_0, float2  * hi_0)
{
    float2  _S79 = driftAt_0(g_7, disp_5, d0_0);
    *lo_0 = _S79;
    *hi_0 = _S79;
    float2  _S80 = driftAt_0(g_7, disp_5, d1_0);
    *lo_0 = min_0(*lo_0, _S80);
    *hi_0 = max_0(*hi_0, _S80);
    int _S81 = clamp_1(int((F32_ceil((clamp_0(d1_0 / g_7->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_0 = clamp_1(int((F32_floor((clamp_0(d0_0 / g_7->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_0 <= _S81)
        {
        }
        else
        {
            break;
        }
        float2  _S82 = *lo_0;
        float2  _S83 = __ldg((&(disp_5)[k_0]));
        *lo_0 = min_0(_S82, _S83);
        float2  _S84 = *hi_0;
        float2  _S85 = __ldg((&(disp_5)[k_0]));
        *hi_0 = max_0(_S84, _S85);
        k_0 = k_0 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_8, float2  q0_0, float2  q1_0)
{
    float spacing_0 = g_8->cellSize_0 * 2.20000004768371582f;
    float2  a_1 = (q0_0 - g_8->cellDrift_0) / make_float2 (spacing_0);
    float2  b_0 = (q1_0 - g_8->cellDrift_0) / make_float2 (spacing_0);
    float2  _S86 = floor_0(a_1);
    int2  _S87 = make_int2 ((int)_S86.x, (int)_S86.y);
    int2  _S88 = make_int2 (int(1), int(1));
    int2  i0_0 = _S87 - _S88;
    float2  _S89 = floor_0(b_0);
    int2  _S90 = make_int2 ((int)_S89.x, (int)_S89.y);
    int2  _S91 = _S90 + _S88;
    int _S92 = i0_0.y;
    int j_1 = _S92;
    float acc_2 = 0.0f;
    for(;;)
    {
        bool _S93;
        if(j_1 <= (_S91.y))
        {
            _S93 = j_1 <= (_S92 + int(32));
        }
        else
        {
            _S93 = false;
        }
        if(_S93)
        {
        }
        else
        {
            break;
        }
        int _S94 = i0_0.x;
        int i_12 = _S94;
        float acc_3 = acc_2;
        for(;;)
        {
            bool _S95;
            if(i_12 <= (_S91.x))
            {
                _S95 = i_12 <= (_S94 + int(32));
            }
            else
            {
                _S95 = false;
            }
            if(_S95)
            {
            }
            else
            {
                break;
            }
            int2  o_1 = make_int2 (i_12, j_1);
            if((hash22_0(o_1, 2654435769U).x) > (g_8->cellDensity_0))
            {
                i_12 = i_12 + int(1);
                continue;
            }
            float2  _S96 = make_float2 ((float)o_1.x, (float)o_1.y);
            float2  c_3 = _S96 + make_float2 (0.5f) + (hash22_0(o_1, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_0(max_0(a_1 - c_3, c_3 - b_0), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_12 = i_12 + int(1);
        }
        j_1 = j_1 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_8->cellStrength_0;
}

static __device__ float iceDensityBound_0(GeneratorInput_0 * g_9, StructuredBuffer<float2 > disp_6, float3  lo_1, float3  hi_1)
{
    float d0_1 = g_9->cellAltitude_0 - hi_1.y;
    float d1_1 = g_9->cellAltitude_0 - lo_1.y;
    bool _S97;
    if(d1_1 < 0.0f)
    {
        _S97 = true;
    }
    else
    {
        _S97 = d0_1 > (g_9->streakLength_0);
    }
    if(_S97)
    {
        return 0.0f;
    }
    float _S98 = g_9->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_9->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_9->streakLength_0);
    float subl_0 = (F32_exp((- g_9->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_9->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_9->streakLength_0, g_9->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_9->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_9, disp_6, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S99 = cellFieldBound_0(g_9, make_float2 (lo_1.x, lo_1.z) - driftHi_0, make_float2 (hi_1.x, hi_1.z) - driftLo_0);
    return (F32_max((_S99 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_9->opticalDepth_0 / (F32_max((_S98), (1.0f)));
}

extern "C" __global__ void buildIceGrid(Medium_0 medium_2, StructuredBuffer<float2 > drift_2, MajorantGrid_0 grid_2, RWStructuredBuffer<float> outBounds_0, int cellCount_0)
{
    int i_13 = int((blockIdx * blockDim + threadIdx).x);
    if(i_13 >= cellCount_0)
    {
        return;
    }
    int _S100 = grid_2.dims_0.x;
    int cx_0 = i_13 % _S100;
    int _S101 = i_13 / _S100;
    int _S102 = grid_2.dims_0.y;
    int cy_0 = _S101 % _S102;
    int cz_0 = i_13 / (_S100 * _S102);
    float3  lo_2 = grid_2.origin_0 + make_float3 (float(cx_0), float(cy_0), float(cz_0)) * grid_2.cellExtent_0;
    float * _S103 = (&(outBounds_0)[i_13]);
    float3  _S104 = lo_2 + grid_2.cellExtent_0;
    GeneratorInput_0 _S105 = medium_2.gen_0;
    float _S106 = iceDensityBound_0(&_S105, drift_2, lo_2, _S104);
    *_S103 = _S106;
    return;
}

