// GENERATED FROM Bounce.slang BY slangc -- DO NOT EDIT.
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

static __device__ float3  floor_0(float3  x_6)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_floor((_slang_vector_get_element(x_6, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
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

static __device__ float2  floor_1(float2  x_9)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_floor((_slang_vector_get_element(x_9, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ float2  lerp_0(float2  x_10, float2  y_2, float2  s_0)
{
    return x_10 + (y_2 - x_10) * s_0;
}

static __device__ int clamp_1(int x_11, int minBound_1, int maxBound_1)
{
    return (I32_min(((I32_max((x_11), (minBound_1)))), (maxBound_1)));
}

static __device__ float lerp_1(float x_12, float y_3, float s_1)
{
    return x_12 + (y_3 - x_12) * s_1;
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

static __device__ Rng_0 splitRng_0(Rng_0 * r_1, uint salt_0)
{
    uint s_4 = ((r_1->state_0) ^ (salt_0 * 2654435761U)) * 747796405U + 2891336453U;
    uint s_5 = ((s_4 >> ((s_4 >> 28U) + 4U)) ^ s_4) * 277803737U;
    return makeRng_0((s_5 >> 22U) ^ s_5);
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
    float _S9 = rd_0.y;
    bool _S10;
    if((F32_abs((_S9))) < 9.99999997475242708e-07f)
    {
        float _S11 = ro_0.y;
        if(_S11 < (m_0->slabBottom_0))
        {
            _S10 = true;
        }
        else
        {
            _S10 = _S11 > (m_0->slabTop_0);
        }
        if(_S10)
        {
            return false;
        }
    }
    else
    {
        float _S12 = ro_0.y;
        float ta_0 = (m_0->slabBottom_0 - _S12) / _S9;
        float tb_0 = (m_0->slabTop_0 - _S12) / _S9;
        *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
        *t1_0 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    }
    float _S13 = (F32_min((*t1_0), (1.2e+05f)));
    *t1_0 = _S13;
    if(_S13 > (*t0_0))
    {
        _S10 = (*t1_0) > 0.0f;
    }
    else
    {
        _S10 = false;
    }
    return _S10;
}

static __device__ float hg_0(float cosT_0, float g_0)
{
    float _S14 = g_0 * g_0;
    float d_0 = 1.0f + _S14 - 2.0f * g_0 * cosT_0;
    return (1.0f - _S14) / (12.56637096405029297f * d_0 * (F32_sqrt(((F32_max((d_0), (9.99999997475242708e-07f)))))));
}

static __device__ float phaseIce_0(float cosT_1)
{
    float t_0 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_1(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_0 * t_0))) * 0.34999999403953552f;
}

static __device__ float draine_0(float cosT_2, float g_1, float a_0)
{
    float _S15 = g_1 * g_1;
    float _S16 = 2.0f * g_1;
    float d_1 = 1.0f + _S15 - _S16 * cosT_2;
    return (1.0f - _S15) / (12.56637096405029297f * d_1 * (F32_sqrt(((F32_max((d_1), (9.99999997475242708e-07f))))))) * (1.0f + a_0 * cosT_2 * cosT_2) / (1.0f + a_0 * (1.0f + _S16 * g_1) / 3.0f);
}

struct PhaseInput_0
{
    float hgG_0;
    float draineG_0;
    float draineAlpha_0;
    float draineW_0;
    int useIce_0;
};

static __device__ float phaseLiquid_0(PhaseInput_0 * p_0, float cosT_3)
{
    return (1.0f - p_0->draineW_0) * hg_0(cosT_3, p_0->hgG_0) + p_0->draineW_0 * draine_0(cosT_3, p_0->draineG_0, p_0->draineAlpha_0);
}

static __device__ float phaseAt_0(PhaseInput_0 * p_1, float cosT_4)
{
    float _S17;
    if((p_1->useIce_0) != int(0))
    {
        _S17 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S18 = phaseLiquid_0(p_1, cosT_4);
        _S17 = _S18;
    }
    return _S17;
}

static __device__ float randFloat_0(Rng_0 * r_2)
{
    uint _S19 = r_2->state_0 * 747796405U + 2891336453U;
    r_2->state_0 = _S19;
    uint word_0 = ((_S19 >> ((_S19 >> 28U) + 4U)) ^ _S19) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_2, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_13 = clamp_0(depth_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_2 = clamp_1(int((F32_floor((x_13)))), int(0), int(31));
    float2  _S20 = __ldg((&(disp_0)[i_2]));
    float2  _S21 = __ldg((&(disp_0)[i_2 + int(1)]));
    return lerp_0(_S20, _S21, make_float2 (x_13 - float(i_2)));
}

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S22 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S23 = _S22;
    *&((&_S23)->x) = *&((&_S23)->x) + _S22.y * 1664525U;
    *&((&_S23)->y) = *&((&_S23)->y) + _S23.x * 1664525U;
    uint2  _S24 = _S23 ^ (_S23 >> make_uint2 (16U));
    _S23 = _S24;
    *&((&_S23)->x) = *&((&_S23)->x) + _S24.y * 1664525U;
    *&((&_S23)->y) = *&((&_S23)->y) + _S23.x * 1664525U;
    uint2  _S25 = _S23 ^ (_S23 >> make_uint2 (16U));
    _S23 = _S25;
    return _S25;
}

static __device__ float2  hash22_0(int2  c_0, uint salt_1)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_0.x), uint(c_0.y)) ^ make_uint2 (salt_1, salt_1 * 2654435761U));
    float2  _S26 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S26 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float cellField_0(GeneratorInput_0 * g_3, float2  q_0)
{
    float2  gq_0 = (q_0 - g_3->cellDrift_0) / make_float2 (g_3->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_1(gq_0);
    int2  _S27 = make_int2 ((int)gf_0.x, (int)gf_0.y);
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
            int2  o_0 = _S27 + make_int2 (i_3, j_0);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_3 = i_3 + int(1);
                continue;
            }
            float2  _S28 = make_float2 ((float)o_0.x, (float)o_0.y);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(gq_0 - (_S28 + make_float2 (0.5f) + (hash22_0(o_0, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f))) * 2.20000004768371582f);
            i_3 = i_3 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S29 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S30 = _S29;
    *&((&_S30)->x) = *&((&_S30)->x) + _S29.y * _S29.z;
    *&((&_S30)->y) = *&((&_S30)->y) + _S30.z * _S30.x;
    *&((&_S30)->z) = *&((&_S30)->z) + _S30.x * _S30.y;
    uint3  _S31 = _S30 ^ (_S30 >> make_uint3 (16U));
    _S30 = _S31;
    *&((&_S30)->x) = *&((&_S30)->x) + _S31.y * _S31.z;
    *&((&_S30)->y) = *&((&_S30)->y) + _S30.z * _S30.x;
    *&((&_S30)->z) = *&((&_S30)->z) + _S30.x * _S30.y;
    return _S30;
}

static __device__ float3  hash33_0(int3  c_1)
{
    uint3  h_1 = pcg3d_0(make_uint3 (uint(c_1.x), uint(c_1.y), uint(c_1.z)));
    float3  _S32 = make_float3 ((float)h_1.x, (float)h_1.y, (float)h_1.z);
    return _S32 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_2)
{
    float3  fi_0 = floor_0(p_2);
    int3  _S33 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_2 - fi_0;
    float3  u_0 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S34 = u_0.x;
    float _S35 = u_0.y;
    return lerp_1(lerp_1(lerp_1(dot_1(hash33_0(_S33), f_0), dot_1(hash33_0(_S33 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S34), lerp_1(dot_1(hash33_0(_S33 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S33 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S34), _S35), lerp_1(lerp_1(dot_1(hash33_0(_S33 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S33 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S34), lerp_1(dot_1(hash33_0(_S33 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S33 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S34), _S35), u_0.z);
}

static __device__ float fbm_0(float3  p_3, int octaves_1)
{
    int i_4 = int(0);
    float amp_0 = 0.5f;
    float3  _S36 = p_3;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S36);
        float norm_1 = norm_0 + amp_0;
        float3  _S37 = _S36 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_4 = i_4 + int(1);
        amp_0 = amp_1;
        _S36 = _S37;
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

static __device__ float iceDensity_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_1, float3  p_4)
{
    float depth_1 = g_4->cellAltitude_0 - p_4.y;
    bool _S38;
    if(depth_1 < 0.0f)
    {
        _S38 = true;
    }
    else
    {
        _S38 = depth_1 > (g_4->streakLength_0);
    }
    if(_S38)
    {
        return 0.0f;
    }
    float2  _S39 = float2 {p_4.x, p_4.z};
    float2  _S40 = driftAt_0(g_4, disp_1, depth_1);
    float2  source_0 = _S39 - _S40;
    float _S41 = cellField_0(g_4, source_0);
    if(_S41 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S41 * (F32_exp((- g_4->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, depth_1)) * (F32_max((1.0f + g_4->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_4->detailScale_0)).x, (source_0 / make_float2 (g_4->detailScale_0)).y, depth_1 / (F32_max((g_4->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_4->timeSeconds_0 * 0.00999999977648258f), g_4->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((g_4->streakLength_0), (1.0f)));
}

static __device__ float densityAt_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_2, float3  p_5)
{
    float _S42 = p_5.y;
    bool _S43;
    if(_S42 < (m_1->slabBottom_0))
    {
        _S43 = true;
    }
    else
    {
        _S43 = _S42 > (m_1->slabTop_0);
    }
    if(_S43)
    {
        return 0.0f;
    }
    int _S44 = m_1->mode_0;
    if((m_1->mode_0) == int(0))
    {
        return m_1->density_0;
    }
    if(_S44 == int(2))
    {
        float _S45 = iceDensity_0(&m_1->gen_0, disp_2, p_5);
        return _S45;
    }
    float3  d_2 = (p_5 - m_1->coreCentre_0) / make_float3 ((F32_max((m_1->coreRadius_0), (9.99999997475242708e-07f))));
    return m_1->density_0 + m_1->coreDensity_0 * (F32_exp((- dot_1(d_2, d_2))));
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

static __device__ Dda_0 ddaInit_0(MajorantGrid_0 * g_5, float3  ro_1, float3  rd_1, float t_1)
{
    Dda_0 d_3;
    if((g_5->enabled_0) == int(0))
    {
        int3  _S46 = make_int3 (int(0), int(0), int(0));
        (&d_3)->cell_0 = _S46;
        (&d_3)->stepDir_0 = _S46;
        float3  _S47 = make_float3 (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_3)->tMax_0 = _S47;
        (&d_3)->tDelta_0 = _S47;
        return d_3;
    }
    float3  p_6 = ro_1 + rd_1 * make_float3 (t_1);
    float3  _S48 = floor_0((p_6 - g_5->origin_0) / g_5->cellExtent_0);
    int3  _S49 = make_int3 ((int)_S48.x, (int)_S48.y, (int)_S48.z);
    (&d_3)->cell_0 = _S49;
    int a_1 = int(0);
    for(;;)
    {
        if(a_1 < int(3))
        {
        }
        else
        {
            break;
        }
        int _S50 = a_1;
        if((F32_abs((_slang_vector_get_element(rd_1, a_1)))) < 9.999999960041972e-13f)
        {
            *_slang_vector_get_element_ptr(&(&d_3)->stepDir_0, a_1) = int(0);
            *_slang_vector_get_element_ptr(&(&d_3)->tMax_0, a_1) = 1.00000001504746622e+30f;
            *_slang_vector_get_element_ptr(&(&d_3)->tDelta_0, a_1) = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S51 = _slang_vector_get_element(rd_1, _S50) > 0.0f;
            int _S52;
            if(_S51)
            {
                _S52 = int(1);
            }
            else
            {
                _S52 = int(-1);
            }
            *_slang_vector_get_element_ptr(&(&d_3)->stepDir_0, a_1) = _S52;
            float _S53 = *_slang_vector_get_element_ptr(&g_5->origin_0, a_1);
            float _S54 = float(*_slang_vector_get_element_ptr(&(&d_3)->cell_0, a_1));
            float _S55;
            if(_S51)
            {
                _S55 = 1.0f;
            }
            else
            {
                _S55 = 0.0f;
            }
            *_slang_vector_get_element_ptr(&(&d_3)->tMax_0, a_1) = t_1 + (_S53 + (_S54 + _S55) * *_slang_vector_get_element_ptr(&g_5->cellExtent_0, a_1) - _slang_vector_get_element(p_6, a_1)) / _slang_vector_get_element(rd_1, _S50);
            *_slang_vector_get_element_ptr(&(&d_3)->tDelta_0, a_1) = (F32_abs((*_slang_vector_get_element_ptr(&g_5->cellExtent_0, a_1) / _slang_vector_get_element(rd_1, _S50))));
        }
        a_1 = a_1 + int(1);
    }
    return d_3;
}

static __device__ float gridBound_0(MajorantGrid_0 * g_6, StructuredBuffer<float> bounds_0, int3  c_2, float fallback_0)
{
    if((g_6->enabled_0) == int(0))
    {
        return fallback_0;
    }
    int _S56 = c_2.x;
    bool _S57;
    if(_S56 < int(0))
    {
        _S57 = true;
    }
    else
    {
        _S57 = (c_2.y) < int(0);
    }
    if(_S57)
    {
        _S57 = true;
    }
    else
    {
        _S57 = (c_2.z) < int(0);
    }
    if(_S57)
    {
        _S57 = true;
    }
    else
    {
        _S57 = _S56 >= (g_6->dims_0.x);
    }
    if(_S57)
    {
        _S57 = true;
    }
    else
    {
        _S57 = (c_2.y) >= (g_6->dims_0.y);
    }
    if(_S57)
    {
        _S57 = true;
    }
    else
    {
        _S57 = (c_2.z) >= (g_6->dims_0.z);
    }
    if(_S57)
    {
        return fallback_0;
    }
    float _S58 = __ldg((&(bounds_0)[(c_2.z * g_6->dims_0.y + c_2.y) * g_6->dims_0.x + _S56]));
    return _S58;
}

static __device__ float ddaExit_0(Dda_0 * d_4)
{
    return (F32_min((d_4->tMax_0.x), ((F32_min((d_4->tMax_0.y), (d_4->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_5)
{
    bool _S59;
    if((d_5->tMax_0.x) <= (d_5->tMax_0.y))
    {
        _S59 = (d_5->tMax_0.x) <= (d_5->tMax_0.z);
    }
    else
    {
        _S59 = false;
    }
    if(_S59)
    {
        *&((&d_5->cell_0)->x) = *&((&d_5->cell_0)->x) + d_5->stepDir_0.x;
        *&((&d_5->tMax_0)->x) = *&((&d_5->tMax_0)->x) + d_5->tDelta_0.x;
    }
    else
    {
        if((d_5->tMax_0.y) <= (d_5->tMax_0.z))
        {
            *&((&d_5->cell_0)->y) = *&((&d_5->cell_0)->y) + d_5->stepDir_0.y;
            *&((&d_5->tMax_0)->y) = *&((&d_5->tMax_0)->y) + d_5->tDelta_0.y;
        }
        else
        {
            *&((&d_5->cell_0)->z) = *&((&d_5->cell_0)->z) + d_5->stepDir_0.z;
            *&((&d_5->tMax_0)->z) = *&((&d_5->tMax_0)->z) + d_5->tDelta_0.z;
        }
    }
    return;
}

static __device__ float transmittance_0(Medium_0 * m_2, MajorantGrid_0 * g_7, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_3, Rng_0 * rng_0, float3  p_7, float3  dir_0, int * steps_0)
{
    float t0_1;
    float t1_1;
    bool _S60 = slabRange_0(m_2, p_7, dir_0, &t0_1, &t1_1);
    if(!_S60)
    {
        return 1.0f;
    }
    float _S61 = (F32_max((t0_1), (0.0f)));
    t0_1 = _S61;
    Dda_0 _S62 = ddaInit_0(g_7, p_7, dir_0, _S61);
    Dda_0 dda_0 = _S62;
    int i_5 = int(0);
    float t_2 = _S61;
    float tr_0 = 1.0f;
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
        float _S63 = gridBound_0(g_7, bounds_1, (&dda_0)->cell_0, m_2->majorant_0);
        Dda_0 _S64 = dda_0;
        float _S65 = ddaExit_0(&_S64);
        float _S66 = (F32_min((_S65), (t1_1)));
        if(_S63 <= 0.0f)
        {
            if(_S66 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            t_2 = _S66;
            i_5 = i_5 + int(1);
            continue;
        }
        float _S67 = randFloat_0(rng_0);
        float t_3 = t_2 - (F32_log(((F32_max((1.0f - _S67), (1.00000001168609742e-07f)))))) / _S63;
        if(t_3 >= _S66)
        {
            if(_S66 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            t_2 = _S66;
            i_5 = i_5 + int(1);
            continue;
        }
        float _S68 = densityAt_0(m_2, disp_3, p_7 + dir_0 * make_float3 (t_3));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S68 / _S63)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S69 = randFloat_0(rng_0);
            if(_S69 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_2 = t_3;
        tr_0 = tr_2;
        i_5 = i_5 + int(1);
    }
    return tr_0;
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
    StructuredBuffer<float> transmittanceLut_0;
};

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_8)
{
    return 20.0f * p_8->sunIntensity_0;
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

static __device__ float3  sunDirection_0(SkyInput_0 * p_9)
{
    float az_0 = toRadians_0(p_9->sunAzimuth_0);
    float el_0 = toRadians_0(p_9->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
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

static __device__ float clampf_0(float v_3, float lo_0, float hi_0)
{
    float _S71;
    if(v_3 < lo_0)
    {
        _S71 = lo_0;
    }
    else
    {
        if(v_3 > hi_0)
        {
            _S71 = hi_0;
        }
        else
        {
            _S71 = v_3;
        }
    }
    return _S71;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_10, float altitude_0, float mu_0)
{
    StructuredBuffer<float> _S72 = p_10->transmittanceLut_0;
    if(uint(StructuredBuffer_getCount_0(p_10->transmittanceLut_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S73 = p_10->scaleHeight_0;
    float scaleHeight_1;
    if((p_10->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S73;
    }
    else
    {
        scaleHeight_1 = 1.0f;
    }
    float topAltitude_0 = scaleHeight_1 * 8.0f;
    float fx_0 = (clampf_0(mu_0, -1.0f, 1.0f) + 1.0f) * 0.5f * 256.0f - 0.5f;
    float fy_0 = (F32_sqrt((clampf_0(altitude_0, 0.0f, topAltitude_0) / topAltitude_0))) * 64.0f - 0.5f;
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
    float _S74 = fx_1 - float(x0_1);
    float _S75 = fy_1 - float(y0_1);
    int _S76 = y0_1 * int(256);
    int _S77 = (_S76 + x0_1) * int(3);
    int _S78 = (_S76 + x1_1) * int(3);
    int _S79 = y1_1 * int(256);
    int _S80 = (_S79 + x0_1) * int(3);
    int _S81 = (_S79 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_3 = int(0);
    for(;;)
    {
        if(c_3 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S82 = __ldg((&(_S72)[_S77 + c_3]));
        float _S83 = 1.0f - _S74;
        float _S84 = _S82 * _S83;
        float _S85 = __ldg((&(_S72)[_S78 + c_3]));
        float a_2 = _S84 + _S85 * _S74;
        float _S86 = __ldg((&(_S72)[_S80 + c_3]));
        float _S87 = _S86 * _S83;
        float _S88 = __ldg((&(_S72)[_S81 + c_3]));
        float r_3 = a_2 * (1.0f - _S75) + (_S87 + _S88 * _S74) * _S75;
        if(c_3 == int(0))
        {
            *&((&out_0)->x) = r_3;
        }
        else
        {
            if(c_3 == int(1))
            {
                *&((&out_0)->y) = r_3;
            }
            else
            {
                *&((&out_0)->z) = r_3;
            }
        }
        c_3 = c_3 + int(1);
    }
    return out_0;
}

static __device__ float3  sunTransmittanceAt_0(SkyInput_0 * p_11, float3  worldPos_0)
{
    float3  _S89 = sunDirection_0(p_11);
    float _S90 = p_11->planetRadius_0;
    float planetRadius_1;
    if((p_11->planetRadius_0) > 1000.0f)
    {
        planetRadius_1 = _S90;
    }
    else
    {
        planetRadius_1 = 1000.0f;
    }
    float _S91 = worldPos_0.y;
    float altitude_1;
    if(_S91 > 0.0f)
    {
        altitude_1 = _S91;
    }
    else
    {
        altitude_1 = 0.0f;
    }
    float3  _S92 = sampleTransmittanceLut_0(p_11, altitude_1, lutMuFor_0(make_float3 (worldPos_0.x, planetRadius_1 + _S91, worldPos_0.z), _S89));
    return _S92;
}

struct Environment_0
{
    float3  uniformRadiance_0;
    SkyInput_0 sky_0;
    int envMode_0;
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
    float neeTentativeScale_0;
};

static __device__ float3  sunIrradianceAt_0(Scene_0 * s_6, float3  p_12)
{
    if(((&s_6->environment_0)->envMode_0) == int(1))
    {
        float _S93 = sunIrradianceTop_0(&(&s_6->environment_0)->sky_0);
        float3  _S94 = sunTransmittanceAt_0(&(&s_6->environment_0)->sky_0, p_12);
        return make_float3 (_S93) * _S94;
    }
    return s_6->sunIrradiance_0;
}

static __device__ float3  cameraSegmentSun_0(Scene_0 * s_7, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > drift_0, Rng_0 * rng_1, float3  ro_2, float3  rd_2, int * steps_1)
{
    float kept_0;
    float3  keptAt_0;
    float3  none_0 = make_float3 (0.0f, 0.0f, 0.0f);
    float t0_2;
    float t1_2;
    bool _S95 = slabRange_0(&s_7->medium_0, ro_2, rd_2, &t0_2, &t1_2);
    if(!_S95)
    {
        return none_0;
    }
    t0_2 = (F32_max((t0_2), (0.0f)));
    float rate_0 = (&s_7->medium_0)->majorant_0 * (F32_max((s_7->neeTentativeScale_0), (1.0f)));
    if(!(rate_0 > 0.0f))
    {
        return none_0;
    }
    float3  _S96 = s_7->sunDir_0;
    float _S97 = phaseAt_0(ph_0, dot_1(rd_2, s_7->sunDir_0));
    float kept_1 = 0.0f;
    float3  keptAt_1 = none_0;
    int i_6 = int(0);
    float t_4 = t0_2;
    float tr_3 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        if(i_6 < int(1024))
        {
        }
        else
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            break;
        }
        *steps_1 = *steps_1 + int(1);
        float uStep_0 = randFloat_0(rng_1);
        float uKeep_0 = randFloat_0(rng_1);
        float uLive_0 = randFloat_0(rng_1);
        float t_5 = t_4 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / rate_0;
        if(t_5 >= t1_2)
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            break;
        }
        float3  p_13 = ro_2 + rd_2 * make_float3 (t_5);
        float _S98 = densityAt_0(&s_7->medium_0, drift_0, p_13);
        if(_S98 <= 0.0f)
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            int i_7 = i_6 + int(1);
            kept_1 = kept_0;
            keptAt_1 = keptAt_0;
            i_6 = i_7;
            t_4 = t_5;
            continue;
        }
        float w_0 = _S98 / rate_0;
        float b_0 = tr_3 * w_0;
        float total_1;
        if(b_0 > 0.0f)
        {
            float total_2 = total_0 + b_0;
            if((uKeep_0 * total_2) < b_0)
            {
                kept_0 = b_0;
                keptAt_0 = p_13;
            }
            else
            {
                kept_0 = kept_1;
                keptAt_0 = keptAt_1;
            }
            total_1 = total_2;
        }
        else
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            total_1 = total_0;
        }
        float tr_4 = tr_3 * (F32_max((0.0f), (1.0f - w_0)));
        float tr_5;
        if(tr_4 < 0.00999999977648258f)
        {
            if(uLive_0 > 0.5f)
            {
                total_0 = total_1;
                break;
            }
            tr_5 = tr_4 * 2.0f;
        }
        else
        {
            tr_5 = tr_4;
        }
        tr_3 = tr_5;
        total_0 = total_1;
        int i_7 = i_6 + int(1);
        kept_1 = kept_0;
        keptAt_1 = keptAt_0;
        i_6 = i_7;
        t_4 = t_5;
    }
    bool _S99;
    if(!(total_0 > 0.0f))
    {
        _S99 = true;
    }
    else
    {
        _S99 = !(kept_0 > 0.0f);
    }
    if(_S99)
    {
        return none_0;
    }
    float _S100 = transmittance_0(&s_7->medium_0, &s_7->grid_0, bounds_2, drift_0, rng_1, keptAt_0 + _S96 * make_float3 (s_7->shadowOffset_0), _S96, steps_1);
    float3  _S101 = make_float3 (total_0) * s_7->albedo_0 * make_float3 (_S97) * make_float3 (_S100);
    float3  _S102 = sunIrradianceAt_0(s_7, keptAt_0);
    return _S101 * _S102;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_3, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > disp_4, Rng_0 * rng_2, float3  ro_3, float3  rd_3, float3  * scatterPoint_0, float * distance_0, int * steps_2)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S103 = slabRange_0(m_3, ro_3, rd_3, &t0_3, &t1_3);
    if(!_S103)
    {
        return false;
    }
    float _S104 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S105 = ddaInit_0(g_8, ro_3, rd_3, _S104);
    Dda_0 dda_1 = _S105;
    int i_8 = int(0);
    float t_6 = _S104;
    for(;;)
    {
        if(i_8 < int(1024))
        {
        }
        else
        {
            break;
        }
        *steps_2 = *steps_2 + int(1);
        float _S106 = gridBound_0(g_8, bounds_3, (&dda_1)->cell_0, m_3->majorant_0);
        Dda_0 _S107 = dda_1;
        float _S108 = ddaExit_0(&_S107);
        float _S109 = (F32_min((_S108), (t1_3)));
        if(_S106 <= 0.0f)
        {
            if(_S109 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            t_6 = _S109;
            i_8 = i_8 + int(1);
            continue;
        }
        float _S110 = randFloat_0(rng_2);
        float t_7 = t_6 - (F32_log(((F32_max((1.0f - _S110), (1.00000001168609742e-07f)))))) / _S106;
        if(t_7 >= _S109)
        {
            if(_S109 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            t_6 = _S109;
            i_8 = i_8 + int(1);
            continue;
        }
        float3  p_14 = ro_3 + rd_3 * make_float3 (t_7);
        float _S111 = randFloat_0(rng_2);
        float _S112 = densityAt_0(m_3, disp_4, p_14);
        if(_S111 < (_S112 / _S106))
        {
            *scatterPoint_0 = p_14;
            *distance_0 = t_7;
            return true;
        }
        t_6 = t_7;
        i_8 = i_8 + int(1);
    }
    return false;
}

static __device__ float shellC_0(float altitude_2, float planetRadius_2, float shellHeight_0)
{
    float d_6 = altitude_2 - shellHeight_0;
    return d_6 * (d_6 + 2.0f * planetRadius_2 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_1, float c_4)
{
    float disc_0 = b_1 * b_1 - c_4;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_1 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_2, float c_5)
{
    float disc_1 = b_2 * b_2 - c_5;
    if(disc_1 < 0.0f)
    {
        return -1.0f;
    }
    return - b_2 - (F32_sqrt((disc_1)));
}

static __device__ float3  rayleighCoefficients_0()
{
    return make_float3 (5.80200003241770901e-06f, 0.00001355800031888f, 0.00003310000101919f);
}

static __device__ float mieCoefficient_0(float turbidity_1)
{
    return 3.99600003220257349e-06f * (turbidity_1 / 2.20000004768371582f);
}

static __device__ float altitudeFromQ_0(float q_1, float planetRadius_3)
{
    float rr_0 = planetRadius_3 * planetRadius_3 + q_1;
    float _S113;
    if(rr_0 > 0.0f)
    {
        _S113 = rr_0;
    }
    else
    {
        _S113 = 0.0f;
    }
    return q_1 / (planetRadius_3 + (F32_sqrt((_S113))));
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_15, float originAltitude_0, float3  rayDir_0, bool includeSunDisc_0)
{
    float hc_0;
    float3  _S114 = sunDirection_0(p_15);
    float _S115 = p_15->planetRadius_0;
    float planetRadius_4;
    if((p_15->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S115;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S116 = p_15->scaleHeight_0;
    float scaleHeight_2;
    if((p_15->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S116;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float atmosphereHeight_0 = scaleHeight_2 * 8.0f;
    float observerAltitude_0;
    if(originAltitude_0 > 0.0f)
    {
        observerAltitude_0 = originAltitude_0;
    }
    else
    {
        observerAltitude_0 = 0.0f;
    }
    float _S117 = planetRadius_4 + observerAltitude_0;
    float _S118 = rayDir_0.y;
    float b_3 = _S117 * _S118;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_4, 0.0f);
    float tTop_0 = shellExit_0(b_3, shellC_0(observerAltitude_0, planetRadius_4, atmosphereHeight_0));
    if(tTop_0 <= 0.0f)
    {
        return make_float3 (0.0f, 0.0f, 0.0f);
    }
    float tGround_0 = shellEnter_0(b_3, cGround_0);
    bool hitsGround_0 = tGround_0 > 0.0f;
    if(hitsGround_0)
    {
        observerAltitude_0 = tGround_0;
    }
    else
    {
        observerAltitude_0 = tTop_0;
    }
    float3  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_15->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_1(rayDir_0, _S114), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_9 = clampf_0(p_15->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S119 = g_9 * g_9;
    float hgDenom_0 = 1.0f + _S119 - 2.0f * g_9 * cosTheta_0;
    float _S120 = 1.0f - _S119;
    float _S121 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S120 / (_S121 * (F32_sqrt((tPrev_0))));
    float3  _S122 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    float3  sumR_0 = _S122;
    float3  sumM_0 = _S122;
    int i_9 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_9 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S123 = i_9 + int(1);
        float tNext_0 = observerAltitude_0 * float(_S123 * _S123) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_9 = _S123;
            continue;
        }
        float h_2 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_3 + tMid_0 * tMid_0, planetRadius_4);
        if(h_2 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_2;
        }
        float _S124 = - hc_0;
        float dR_0 = (F32_exp((_S124 / scaleHeight_2))) * dt_0;
        float dM_0 = (F32_exp((_S124 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        float3  _S125 = sampleTransmittanceLut_0(p_15, hc_0, lutMuFor_0(make_float3 (rayDir_0.x * tMid_0, _S117 + _S118 * tMid_0, rayDir_0.z * tMid_0), _S114));
        float _S126 = betaMExt_0 * depthM_1;
        float3  transmittance_1 = make_float3 ((F32_exp((- (betaR_0.x * depthR_1 + _S126)))), (F32_exp((- (betaR_0.y * depthR_1 + _S126)))), (F32_exp((- (betaR_0.z * depthR_1 + _S126))))) * _S125;
        float3  _S127 = sumM_0 + transmittance_1 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_1 * make_float3 (dR_0);
        sumM_0 = _S127;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_9 = _S123;
    }
    float _S128 = sunIrradianceTop_0(p_15);
    float3  radiance_0 = (sumR_0 * betaR_0 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S128);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_0.x * tGround_0, _S117 + _S118 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_1(normalizeExact_0(groundPoint_0), _S114), 0.0f, 1.0f);
        float3  _S129 = sampleTransmittanceLut_0(p_15, 0.0f, lutMuFor_0(groundPoint_0, _S114));
        float _S130 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S130)))), (F32_exp((- (betaR_0.y * depthR_0 + _S130)))), (F32_exp((- (betaR_0.z * depthR_0 + _S130))))) * _S129 * make_float3 (p_15->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S128);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S131;
    if(!hitsGround_0)
    {
        _S131 = includeSunDisc_0;
    }
    else
    {
        _S131 = false;
    }
    if(_S131)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_15->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S132 = betaMExt_0 * depthM_0;
            float3  viewT_0 = make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S132)))), (F32_exp((- (betaR_0.y * depthR_0 + _S132)))), (F32_exp((- (betaR_0.z * depthR_0 + _S132)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_0 = solidAngle_0;
            }
            else
            {
                hc_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * make_float3 (_S128 / hc_0);
        }
    }
    return radiance_1;
}

static __device__ float3  environmentRadiance_0(Environment_0 * e_0, float3  origin_1, float3  dir_1, bool includeSunDisc_1)
{
    if((e_0->envMode_0) == int(1))
    {
        float3  _S133 = skyRadiance_0(&e_0->sky_0, origin_1.y, dir_1, includeSunDisc_1);
        return _S133;
    }
    return e_0->uniformRadiance_0;
}

static __device__ float3  sampleHG_0(Rng_0 * rng_3, float3  wo_0, float g_10, float * cosT_5)
{
    float _S134 = clamp_0(g_10, -0.99900001287460327f, 0.99900001287460327f);
    float u1_0 = randFloat_0(rng_3);
    float u2_0 = randFloat_0(rng_3);
    if((F32_abs((_S134))) < 0.00100000004749745f)
    {
        *cosT_5 = 1.0f - 2.0f * u1_0;
    }
    else
    {
        float _S135 = _S134 * _S134;
        float _S136 = 2.0f * _S134;
        float s_8 = (1.0f - _S135) / (1.0f - _S134 + _S136 * u1_0);
        *cosT_5 = (1.0f + _S135 - s_8 * s_8) / _S136;
    }
    float _S137 = clamp_0(*cosT_5, -1.0f, 1.0f);
    *cosT_5 = _S137;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S137 * _S137))))));
    float phi_0 = 6.28318548202514648f * u2_0;
    float3  w_1 = normalize_0(wo_0);
    float3  a_3;
    if((F32_abs((w_1.y))) < 0.94999998807907104f)
    {
        a_3 = make_float3 (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_3 = make_float3 (1.0f, 0.0f, 0.0f);
    }
    float3  u_1 = normalize_0(cross_0(a_3, w_1));
    return normalize_0(make_float3 (sinT_0 * (F32_cos((phi_0)))) * u_1 + make_float3 (sinT_0 * (F32_sin((phi_0)))) * cross_0(w_1, u_1) + make_float3 (*cosT_5) * w_1);
}

static __device__ float3  samplePhaseDir_0(PhaseInput_0 * p_16, Rng_0 * rng_4, float3  wo_1, float * weight_0)
{
    float cosT_6;
    float3  dir_2;
    float _S138;
    if((p_16->useIce_0) != int(0))
    {
        float _S139 = randFloat_0(rng_4);
        if(_S139 < 0.72000002861022949f)
        {
            float3  _S140 = sampleHG_0(rng_4, wo_1, 0.85000002384185791f, &cosT_6);
            dir_2 = _S140;
        }
        else
        {
            float3  _S141 = sampleHG_0(rng_4, wo_1, 0.0f, &cosT_6);
            dir_2 = _S141;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_6, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S138 = phaseIce_0(cosT_6) / pdf_0;
        }
        else
        {
            _S138 = 0.0f;
        }
        *weight_0 = _S138;
    }
    else
    {
        float _S142 = randFloat_0(rng_4);
        float _S143 = p_16->draineW_0;
        if(_S142 < (p_16->draineW_0))
        {
            float3  _S144 = sampleHG_0(rng_4, wo_1, p_16->draineG_0, &cosT_6);
            dir_2 = _S144;
        }
        else
        {
            float3  _S145 = sampleHG_0(rng_4, wo_1, p_16->hgG_0, &cosT_6);
            dir_2 = _S145;
        }
        float pdf_1 = _S143 * hg_0(cosT_6, p_16->draineG_0) + (1.0f - _S143) * hg_0(cosT_6, p_16->hgG_0);
        if(pdf_1 > 9.99999971718068537e-10f)
        {
            float _S146 = phaseLiquid_0(p_16, cosT_6);
            _S138 = _S146 / pdf_1;
        }
        else
        {
            _S138 = 0.0f;
        }
        *weight_0 = _S138;
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

static __device__ TraceResult_0 trace_0(Scene_0 * s_9, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > drift_1, Rng_0 * rng_5, float3  ro_4, float3  rd_4)
{
    TraceResult_0 r_4;
    (&r_4)->pathRadiance_0 = make_float3 (0.0f, 0.0f, 0.0f);
    (&r_4)->scatterEvents_0 = int(0);
    (&r_4)->capped_0 = int(0);
    (&r_4)->trackingSteps_0 = int(0);
    float3  throughput_0 = make_float3 (1.0f, 1.0f, 1.0f);
    int _S147 = (I32_min((s_9->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_9->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S147 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    if(sunAlongCamera_0)
    {
        Rng_0 _S148 = *rng_5;
        Rng_0 _S149 = splitRng_0(&_S148, 1510U);
        Rng_0 segmentRng_0 = _S149;
        float3  _S150 = cameraSegmentSun_0(s_9, ph_1, bounds_4, drift_1, &segmentRng_0, ro_4, rd_4, &(&r_4)->trackingSteps_0);
        (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + _S150;
    }
    float3  _S151 = ro_4;
    float3  _S152 = rd_4;
    int bounce_0 = int(0);
    float3  throughput_1 = throughput_0;
    for(;;)
    {
        if(bounce_0 < int(256))
        {
        }
        else
        {
            break;
        }
        if(bounce_0 >= _S147)
        {
            (&r_4)->capped_0 = int(1);
            break;
        }
        float3  p_17;
        float dist_0;
        bool _S153 = sampleFreeFlight_0(&s_9->medium_0, &s_9->grid_0, bounds_4, drift_1, rng_5, _S151, _S152, &p_17, &dist_0, &(&r_4)->trackingSteps_0);
        if(!_S153)
        {
            float3  _S154 = environmentRadiance_0(&s_9->environment_0, _S151, _S152, bounce_0 == int(0));
            (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + throughput_1 * _S154;
            break;
        }
        (&r_4)->scatterEvents_0 = (&r_4)->scatterEvents_0 + int(1);
        bool _S155;
        if(bounce_0 == int(0))
        {
            _S155 = sunAlongCamera_0;
        }
        else
        {
            _S155 = false;
        }
        if(!_S155)
        {
            float3  _S156 = s_9->sunDir_0;
            float _S157 = transmittance_0(&s_9->medium_0, &s_9->grid_0, bounds_4, drift_1, rng_5, p_17 + s_9->sunDir_0 * make_float3 (s_9->shadowOffset_0), s_9->sunDir_0, &(&r_4)->trackingSteps_0);
            if(_S157 > 0.0f)
            {
                float _S158 = phaseAt_0(ph_1, dot_1(_S152, _S156));
                float3  _S159 = throughput_1 * s_9->albedo_0 * make_float3 (_S158) * make_float3 (_S157);
                float3  _S160 = sunIrradianceAt_0(s_9, p_17);
                (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + _S159 * _S160;
            }
        }
        float w_2;
        float3  _S161 = samplePhaseDir_0(ph_1, rng_5, _S152, &w_2);
        float3  throughput_2 = throughput_1 * (s_9->albedo_0 * make_float3 (w_2));
        float3  _S162 = p_17;
        if(bounce_0 >= (s_9->rrStartBounce_0))
        {
            float p2_0 = clamp_0((F32_max((throughput_2.x), ((F32_max((throughput_2.y), (throughput_2.z)))))), 0.05000000074505806f, 1.0f);
            float _S163 = randFloat_0(rng_5);
            if(_S163 > p2_0)
            {
                break;
            }
            throughput_1 = throughput_2 / make_float3 (p2_0);
        }
        else
        {
            throughput_1 = throughput_2;
        }
        int bounce_1 = bounce_0 + int(1);
        _S151 = _S162;
        _S152 = _S161;
        bounce_0 = bounce_1;
    }
    return r_4;
}

extern "C" __global__ void traceTrial(Scene_0 scene_0, PhaseInput_0 phase_0, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > drift_2, float3  origin_2, float3  direction_0, RWStructuredBuffer<float3 > outRadiance_0, RWStructuredBuffer<int> outScatterEvents_0, RWStructuredBuffer<int> outCapped_0, RWStructuredBuffer<int> outSteps_0, uint seed_2, int count_0)
{
    int i_10 = int((blockIdx * blockDim + threadIdx).x);
    if(i_10 >= count_0)
    {
        return;
    }
    Rng_0 rng_6 = makeRngForIndex_0(seed_2, i_10);
    Scene_0 _S164 = scene_0;
    PhaseInput_0 _S165 = phase_0;
    TraceResult_0 _S166 = trace_0(&_S164, &_S165, bounds_5, drift_2, &rng_6, origin_2, direction_0);
    *(&(outRadiance_0)[i_10]) = _S166.pathRadiance_0;
    *(&(outScatterEvents_0)[i_10]) = _S166.scatterEvents_0;
    *(&(outCapped_0)[i_10]) = _S166.capped_0;
    *(&(outSteps_0)[i_10]) = _S166.trackingSteps_0;
    return;
}

extern "C" __global__ void phaseValueTrial(PhaseInput_0 phase_1, StructuredBuffer<float> inCos_0, RWStructuredBuffer<float> outPhase_0, int count_1)
{
    int i_11 = int((blockIdx * blockDim + threadIdx).x);
    if(i_11 >= count_1)
    {
        return;
    }
    float * _S167 = (&(outPhase_0)[i_11]);
    float _S168 = __ldg((&(inCos_0)[i_11]));
    PhaseInput_0 _S169 = phase_1;
    float _S170 = phaseAt_0(&_S169, _S168);
    *_S167 = _S170;
    return;
}

static __device__ PhaseInput_0 phaseFromDropletDiameter_0(float diameterMicrons_0, int useIce_1)
{
    float d_7 = clamp_0(diameterMicrons_0, 5.0f, 50.0f);
    PhaseInput_0 p_18;
    (&p_18)->hgG_0 = clamp_0((F32_exp((-0.09905669838190079f / (d_7 - 1.6715400218963623f)))), -0.99900001287460327f, 0.99900001287460327f);
    (&p_18)->draineG_0 = clamp_0((F32_exp((- (2.20678997039794922f / (d_7 + 3.91029000282287598f)) - 0.4289340078830719f))), -0.99900001287460327f, 0.99900001287460327f);
    (&p_18)->draineAlpha_0 = (F32_exp((3.62489008903503418f - 8.29288005828857422f / (d_7 + 5.52825021743774414f))));
    (&p_18)->draineW_0 = (F32_exp((- (0.59908497333526611f / (d_7 - 0.64158302545547485f)) - 0.66588801145553589f)));
    (&p_18)->useIce_0 = useIce_1;
    return p_18;
}

extern "C" __global__ void phaseParamsTrial(float diameterMicrons_1, RWStructuredBuffer<float4 > outParams_0)
{
    PhaseInput_0 p_19 = phaseFromDropletDiameter_0(diameterMicrons_1, int(0));
    *(&(outParams_0)[int(0)]) = make_float4 (p_19.hgG_0, p_19.draineG_0, p_19.draineAlpha_0, p_19.draineW_0);
    return;
}

