// GENERATED FROM Render.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

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

static __device__ float dot_0(float3  x_0, float3  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y + x_0.z * y_0.z;
}

static __device__ float length_0(float3  x_1)
{
    return (F32_sqrt((dot_0(x_1, x_1))));
}

static __device__ float3  normalize_0(float3  x_2)
{
    return x_2 / make_float3 (length_0(x_2));
}

static __device__ int StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    uint2  _S7 = make_uint2(_elementCount_0, _stride_0);
    return int(_S7.x);
}

static __device__ float dot_1(float2  x_3, float2  y_1)
{
    return x_3.x * y_1.x + x_3.y * y_1.y;
}

static __device__ float length_1(float2  x_4)
{
    return (F32_sqrt((dot_1(x_4, x_4))));
}

static __device__ float2  min_0(float2  x_5, float2  y_2)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_min((_slang_vector_get_element(x_5, i_0)), (_slang_vector_get_element(y_2, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ float2  lerp_0(float2  x_6, float2  y_3, float2  s_0)
{
    return x_6 + (y_3 - x_6) * s_0;
}

static __device__ int clamp_0(int x_7, int minBound_0, int maxBound_0)
{
    return (I32_min(((I32_max((x_7), (minBound_0)))), (maxBound_0)));
}

static __device__ float clamp_1(float x_8, float minBound_1, float maxBound_1)
{
    return (F32_min(((F32_max((x_8), (minBound_1)))), (maxBound_1)));
}

static __device__ float saturate_0(float x_9)
{
    return clamp_1(x_9, 0.0f, 1.0f);
}

static __device__ float smoothstep_0(float min_1, float max_0, float x_10)
{
    float _S8 = saturate_0((x_10 - min_1) / (max_0 - min_1));
    return _S8 * _S8 * (3.0f - (_S8 + _S8));
}

static __device__ float2  abs_0(float2  x_11)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_abs((_slang_vector_get_element(x_11, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ float2  max_1(float2  x_12, float2  y_4)
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
        *_slang_vector_get_element_ptr(&result_2, i_2) = (F32_max((_slang_vector_get_element(x_12, i_2)), (_slang_vector_get_element(y_4, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ float lerp_1(float x_13, float y_5, float s_1)
{
    return x_13 + (y_5 - x_13) * s_1;
}

static __device__ bool all_0(bool2  x_14)
{
    bool result_3 = true;
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
        if(result_3)
        {
            result_3 = (bool((_slang_vector_get_element(x_14, i_3))));
        }
        else
        {
            result_3 = false;
        }
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ float2  floor_0(float2  x_15)
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
        *_slang_vector_get_element_ptr(&result_4, i_4) = (F32_floor((_slang_vector_get_element(x_15, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static __device__ float3  floor_1(float3  x_16)
{
    float3  result_5;
    int i_5 = int(0);
    for(;;)
    {
        if(i_5 < int(3))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_5, i_5) = (F32_floor((_slang_vector_get_element(x_16, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
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

static __device__ Rng_0 splitRng_0(Rng_0 * r_1, uint salt_0)
{
    uint s_2 = ((r_1->state_0) ^ (salt_0 * 2654435761U)) * 747796405U + 2891336453U;
    uint s_3 = ((s_2 >> ((s_2 >> 28U) + 4U)) ^ s_2) * 277803737U;
    return makeRng_0((s_3 >> 22U) ^ s_3);
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

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S27 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S28 = _S27;
    *&((&_S28)->x) = *&((&_S28)->x) + _S27.y * 1664525U;
    *&((&_S28)->y) = *&((&_S28)->y) + _S28.x * 1664525U;
    uint2  _S29 = _S28 ^ (_S28 >> make_uint2 (16U));
    _S28 = _S29;
    *&((&_S28)->x) = *&((&_S28)->x) + _S29.y * 1664525U;
    *&((&_S28)->y) = *&((&_S28)->y) + _S28.x * 1664525U;
    uint2  _S30 = _S28 ^ (_S28 >> make_uint2 (16U));
    _S28 = _S30;
    return _S30;
}

static __device__ float2  hash22_0(int2  c_0, uint salt_1)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_0.x), uint(c_0.y)) ^ make_uint2 (salt_1, salt_1 * 2654435761U));
    float2  _S31 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S31 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float convLife_0(float u_0)
{
    float _S32 = 1.0f - u_0;
    return 6.75f * u_0 * _S32 * _S32;
}

static __device__ float convVigour_0(ConvectionInput_0 * c_1, int2  slot_0)
{
    float2  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_1->cvAge_0 + h_1.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_1.y);
}

static __device__ float2  convCellCentre_0(int2  slot_1)
{
    float2  _S33 = make_float2 ((float)slot_1.x, (float)slot_1.y);
    return _S33 + make_float2 (0.5f) + (hash22_0(slot_1, 1759714724U) - make_float2 (0.5f)) * make_float2 (0.69999998807907104f);
}

static __device__ float convBump_0(float d2_0, float reach_0)
{
    float r2_0 = reach_0 * reach_0;
    if(d2_0 >= r2_0)
    {
        return 0.0f;
    }
    float t_1 = 1.0f - d2_0 / r2_0;
    return t_1 * t_1;
}

static __device__ void convSlotBound_0(ConvectionInput_0 * c_2, int2  slot_2, float2  a_1, float2  b_0, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S34 = convVigour_0(c_2, slot_2);
    if(_S34 <= 0.0f)
    {
        return;
    }
    float2  ctr_0 = convCellCentre_0(slot_2);
    float2  _S35 = a_1 - ctr_0;
    float2  nearGap_0 = max_1(max_1(_S35, ctr_0 - b_0), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_1(abs_0(_S35), abs_0(b_0 - ctr_0));
    float oHi_0 = _S34 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S34 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S34 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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

static __device__ float convUpdraftBound_0(ConvectionInput_0 * c_3, float2  q0_0, float2  q1_0)
{
    float2  a_2 = q0_0 / make_float2 (c_3->cvSpacing_0);
    float2  b_1 = q1_0 / make_float2 (c_3->cvSpacing_0);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    float2  _S36 = floor_0((a_2 + b_1) * make_float2 (0.5f));
    int2  _S37 = make_int2 ((int)_S36.x, (int)_S36.y);
    float2  _S38 = make_float2 ((float)_S37.x, (float)_S37.y);
    float2  highEdge_0 = _S38 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S39;
    if(all_0(a_2 >= (_S38 - make_float2 (0.00009999999747379f))))
    {
        _S39 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S39 = false;
    }
    int j_0;
    int i_6;
    if(_S39)
    {
        j_0 = int(-1);
        for(;;)
        {
            if(j_0 <= int(1))
            {
            }
            else
            {
                break;
            }
            i_6 = int(-1);
            for(;;)
            {
                if(i_6 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_3, _S37 + make_int2 (i_6, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_6 = i_6 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    else
    {
        float2  _S40 = floor_0(a_2);
        int2  _S41 = make_int2 ((int)_S40.x, (int)_S40.y);
        int2  _S42 = make_int2 (int(1), int(1));
        int2  i0_0 = _S41 - _S42;
        float2  _S43 = floor_0(b_1);
        int2  _S44 = make_int2 ((int)_S43.x, (int)_S43.y);
        int2  _S45 = _S44 + _S42;
        int _S46 = i0_0.y;
        j_0 = _S46;
        for(;;)
        {
            if(j_0 <= (_S45.y))
            {
                _S39 = j_0 <= (_S46 + int(32));
            }
            else
            {
                _S39 = false;
            }
            if(_S39)
            {
            }
            else
            {
                break;
            }
            int _S47 = i0_0.x;
            i_6 = _S47;
            for(;;)
            {
                bool _S48;
                if(i_6 <= (_S45.x))
                {
                    _S48 = i_6 <= (_S47 + int(32));
                }
                else
                {
                    _S48 = false;
                }
                if(_S48)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_3, make_int2 (i_6, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_6 = i_6 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    return lerp_1((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_3->cvPolarity_0) + 0.00000999999974738f;
}

static __device__ float convTowerHeight_0(ConvectionInput_0 * c_4, float w_0)
{
    float cover_0 = clamp_1(c_4->cvCoverage_0, 0.0f, 1.0f);
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
    return c_4->cvDepth_0 * (F32_pow((u_1), (c_4->cvShape_0)));
}

static __device__ float convLift_0(ConvectionInput_0 * c_5, float above_0)
{
    return c_5->cvBillow_0 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_1(0.34999999403953552f, 1.0f, saturate_0(above_0 / (F32_max((c_5->cvDepth_0), (1.0f)))));
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_6, float3  lo_0, float3  hi_0)
{
    float low_0 = lo_0.y - c_6->cvBase_0;
    float high_0 = hi_0.y - c_6->cvBase_0;
    float ceiling_0 = c_6->cvDepth_0 + c_6->cvBillow_0;
    bool _S49;
    if(high_0 < 0.0f)
    {
        _S49 = true;
    }
    else
    {
        _S49 = low_0 > ceiling_0;
    }
    if(_S49)
    {
        return 0.0f;
    }
    float _S50 = (F32_max((low_0), (0.0f)));
    float _S51 = (F32_min((high_0), (ceiling_0)));
    float _S52 = convUpdraftBound_0(c_6, float2 {lo_0.x, lo_0.z} - c_6->cvDrift_0, float2 {hi_0.x, hi_0.z} - c_6->cvDrift_0);
    float _S53 = convTowerHeight_0(c_6, _S52);
    if(_S53 <= 0.0f)
    {
        return 0.0f;
    }
    float _S54 = convLift_0(c_6, _S51);
    float inside_0 = _S53 - _S50 + _S54 + 0.00100000004749745f;
    if(inside_0 <= 0.0f)
    {
        return 0.0f;
    }
    return c_6->cvSigma_0 * (F32_sqrt((saturate_0(_S51 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_0) * 1.00001001358032227f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_1, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_17 = clamp_1(depth_0 / g_1->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_7 = clamp_0(int((F32_floor((x_17)))), int(0), int(31));
    float2  _S55 = __ldg((&(disp_0)[i_7]));
    float2  _S56 = __ldg((&(disp_0)[i_7 + int(1)]));
    return lerp_0(_S55, _S56, make_float2 (x_17 - float(i_7)));
}

static __device__ void driftRange_0(GeneratorInput_0 * g_2, StructuredBuffer<float2 > disp_1, float d0_0, float d1_0, float2  * lo_1, float2  * hi_1)
{
    float2  _S57 = driftAt_0(g_2, disp_1, d0_0);
    *lo_1 = _S57;
    *hi_1 = _S57;
    float2  _S58 = driftAt_0(g_2, disp_1, d1_0);
    *lo_1 = min_0(*lo_1, _S58);
    *hi_1 = max_1(*hi_1, _S58);
    int _S59 = clamp_0(int((F32_ceil((clamp_1(d1_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_0 = clamp_0(int((F32_floor((clamp_1(d0_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_0 <= _S59)
        {
        }
        else
        {
            break;
        }
        float2  _S60 = *lo_1;
        float2  _S61 = __ldg((&(disp_1)[k_0]));
        *lo_1 = min_0(_S60, _S61);
        float2  _S62 = *hi_1;
        float2  _S63 = __ldg((&(disp_1)[k_0]));
        *hi_1 = max_1(_S62, _S63);
        k_0 = k_0 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_3, float2  q0_1, float2  q1_1)
{
    float spacing_0 = g_3->cellSize_0 * 2.20000004768371582f;
    float2  a_3 = (q0_1 - g_3->cellDrift_0) / make_float2 (spacing_0);
    float2  b_2 = (q1_1 - g_3->cellDrift_0) / make_float2 (spacing_0);
    float2  _S64 = floor_0(a_3);
    int2  _S65 = make_int2 ((int)_S64.x, (int)_S64.y);
    int2  _S66 = make_int2 (int(1), int(1));
    int2  i0_1 = _S65 - _S66;
    float2  _S67 = floor_0(b_2);
    int2  _S68 = make_int2 ((int)_S67.x, (int)_S67.y);
    int2  _S69 = _S68 + _S66;
    int _S70 = i0_1.y;
    int j_1 = _S70;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S71;
        if(j_1 <= (_S69.y))
        {
            _S71 = j_1 <= (_S70 + int(32));
        }
        else
        {
            _S71 = false;
        }
        if(_S71)
        {
        }
        else
        {
            break;
        }
        int _S72 = i0_1.x;
        int i_8 = _S72;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S73;
            if(i_8 <= (_S69.x))
            {
                _S73 = i_8 <= (_S72 + int(32));
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
            int2  o_0 = make_int2 (i_8, j_1);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_8 = i_8 + int(1);
                continue;
            }
            float2  _S74 = make_float2 ((float)o_0.x, (float)o_0.y);
            float2  c_7 = _S74 + make_float2 (0.5f) + (hash22_0(o_0, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(max_1(max_1(a_3 - c_7, c_7 - b_2), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_8 = i_8 + int(1);
        }
        j_1 = j_1 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static __device__ float iceDensityBound_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_2, float3  lo_2, float3  hi_2)
{
    float d0_1 = g_4->cellAltitude_0 - hi_2.y;
    float d1_1 = g_4->cellAltitude_0 - lo_2.y;
    bool _S75;
    if(d1_1 < 0.0f)
    {
        _S75 = true;
    }
    else
    {
        _S75 = d0_1 > (g_4->streakLength_0);
    }
    if(_S75)
    {
        return 0.0f;
    }
    float _S76 = g_4->streakLength_0;
    float d0_2 = clamp_1(d0_1, 0.0f, g_4->streakLength_0);
    float d1_2 = clamp_1(d1_1, 0.0f, g_4->streakLength_0);
    float subl_0 = (F32_exp((- g_4->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_4->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_4, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S77 = cellFieldBound_0(g_4, make_float2 (lo_2.x, lo_2.z) - driftHi_0, make_float2 (hi_2.x, hi_2.z) - driftLo_0);
    return (F32_max((_S77 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((_S76), (1.0f)));
}

static __device__ float mediumBound_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_3, float3  lo_3, float3  hi_3)
{
    int _S78 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S79 = convectionBound_0(&m_1->conv_0, lo_3, hi_3);
        return _S79;
    }
    if(_S78 == int(2))
    {
        float _S80 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_3, hi_3);
        return _S80;
    }
    return m_1->majorant_0;
}

static __device__ float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_0, StructuredBuffer<float2 > disp_4, int3  c_8, float fallback_0)
{
    int _S81 = g_5->enabled_0;
    if((g_5->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S81 == int(2))
    {
        float3  _S82 = make_float3 ((float)c_8.x, (float)c_8.y, (float)c_8.z);
        float3  lo_4 = g_5->origin_0 + _S82 * g_5->cellExtent_0;
        float _S83 = mediumBound_0(m_2, disp_4, lo_4, lo_4 + g_5->cellExtent_0);
        return _S83;
    }
    int _S84 = c_8.x;
    bool _S85;
    if(_S84 < int(0))
    {
        _S85 = true;
    }
    else
    {
        _S85 = (c_8.y) < int(0);
    }
    if(_S85)
    {
        _S85 = true;
    }
    else
    {
        _S85 = (c_8.z) < int(0);
    }
    if(_S85)
    {
        _S85 = true;
    }
    else
    {
        _S85 = _S84 >= (g_5->dims_0.x);
    }
    if(_S85)
    {
        _S85 = true;
    }
    else
    {
        _S85 = (c_8.y) >= (g_5->dims_0.y);
    }
    if(_S85)
    {
        _S85 = true;
    }
    else
    {
        _S85 = (c_8.z) >= (g_5->dims_0.z);
    }
    if(_S85)
    {
        return fallback_0;
    }
    float _S86 = __ldg((&(bounds_0)[(c_8.z * g_5->dims_0.y + c_8.y) * g_5->dims_0.x + _S84]));
    return _S86;
}

static __device__ float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_2)
{
    bool _S87;
    if((d_2->tMax_0.x) <= (d_2->tMax_0.y))
    {
        _S87 = (d_2->tMax_0.x) <= (d_2->tMax_0.z);
    }
    else
    {
        _S87 = false;
    }
    if(_S87)
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

static __device__ float randFloat_0(Rng_0 * r_2)
{
    uint _S88 = r_2->state_0 * 747796405U + 2891336453U;
    r_2->state_0 = _S88;
    uint word_0 = ((_S88 >> ((_S88 >> 28U) + 4U)) ^ _S88) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ bool segmentStep_0(Medium_0 * m_3, MajorantGrid_0 * g_6, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > drift_0, float scale_0, float tEnd_0, Dda_0 * dda_0, float * rate_0, float * t_2, Rng_0 * rng_0, float * uKeep_0, float * uLive_0, int * budget_0, int * steps_0)
{
    *uKeep_0 = 0.0f;
    *uLive_0 = 0.0f;
    for(;;)
    {
        if((*budget_0) > int(0))
        {
        }
        else
        {
            break;
        }
        *budget_0 = *budget_0 - int(1);
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S89 = *dda_0;
        float _S90 = ddaExit_0(&_S89);
        float _S91 = (F32_min((_S90), (tEnd_0)));
        if(!((*rate_0) > 0.0f))
        {
            if(_S91 >= tEnd_0)
            {
                return false;
            }
            *t_2 = _S91;
            ddaAdvance_0(dda_0);
            float _S92 = gridBound_0(m_3, g_6, bounds_1, drift_0, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S92 * scale_0;
            continue;
        }
        float uStep_0 = randFloat_0(rng_0);
        float _S93 = randFloat_0(rng_0);
        *uKeep_0 = _S93;
        float _S94 = randFloat_0(rng_0);
        *uLive_0 = _S94;
        float _S95 = *t_2 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / *rate_0;
        *t_2 = _S95;
        if(_S95 >= _S91)
        {
            if(_S91 >= tEnd_0)
            {
                return false;
            }
            *t_2 = _S91;
            ddaAdvance_0(dda_0);
            float _S96 = gridBound_0(m_3, g_6, bounds_1, drift_0, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S96 * scale_0;
            continue;
        }
        return true;
    }
    return false;
}

static __device__ MajorantGrid_0 gridFor_0(Medium_0 * m_4, MajorantGrid_0 * g_7, float3  p_1)
{
    MajorantGrid_0 chosen_0 = *g_7;
    bool _S97;
    if((g_7->enabled_0) == int(2))
    {
        _S97 = (p_1.y) >= (m_4->slabBottom_0);
    }
    else
    {
        _S97 = false;
    }
    if(_S97)
    {
        _S97 = (p_1.y) <= (m_4->slabTop_0);
    }
    else
    {
        _S97 = false;
    }
    if(_S97)
    {
        (&chosen_0)->enabled_0 = int(0);
    }
    return chosen_0;
}

static __device__ float cellField_0(GeneratorInput_0 * g_8, float2  q_0)
{
    float2  gq_0 = (q_0 - g_8->cellDrift_0) / make_float2 (g_8->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_0(gq_0);
    int2  _S98 = make_int2 ((int)gf_0.x, (int)gf_0.y);
    int j_2 = int(-1);
    float acc_2 = 0.0f;
    for(;;)
    {
        if(j_2 <= int(1))
        {
        }
        else
        {
            break;
        }
        int i_9 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_9 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_1 = _S98 + make_int2 (i_9, j_2);
            if((hash22_0(o_1, 2654435769U).x) > (g_8->cellDensity_0))
            {
                i_9 = i_9 + int(1);
                continue;
            }
            float2  _S99 = make_float2 ((float)o_1.x, (float)o_1.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(gq_0 - (_S99 + make_float2 (0.5f) + (hash22_0(o_1, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f))) * 2.20000004768371582f);
            i_9 = i_9 + int(1);
        }
        j_2 = j_2 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_8->cellStrength_0;
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S100 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S101 = _S100;
    *&((&_S101)->x) = *&((&_S101)->x) + _S100.y * _S100.z;
    *&((&_S101)->y) = *&((&_S101)->y) + _S101.z * _S101.x;
    *&((&_S101)->z) = *&((&_S101)->z) + _S101.x * _S101.y;
    uint3  _S102 = _S101 ^ (_S101 >> make_uint3 (16U));
    _S101 = _S102;
    *&((&_S101)->x) = *&((&_S101)->x) + _S102.y * _S102.z;
    *&((&_S101)->y) = *&((&_S101)->y) + _S101.z * _S101.x;
    *&((&_S101)->z) = *&((&_S101)->z) + _S101.x * _S101.y;
    return _S101;
}

static __device__ float3  hash33_0(int3  c_9)
{
    uint3  h_2 = pcg3d_0(make_uint3 (uint(c_9.x), uint(c_9.y), uint(c_9.z)));
    float3  _S103 = make_float3 ((float)h_2.x, (float)h_2.y, (float)h_2.z);
    return _S103 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_2)
{
    float3  fi_0 = floor_1(p_2);
    int3  _S104 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_2 - fi_0;
    float3  u_2 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S105 = u_2.x;
    float _S106 = u_2.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S104), f_0), dot_0(hash33_0(_S104 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S105), lerp_1(dot_0(hash33_0(_S104 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S104 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S105), _S106), lerp_1(lerp_1(dot_0(hash33_0(_S104 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S104 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S105), lerp_1(dot_0(hash33_0(_S104 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S104 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S105), _S106), u_2.z);
}

static __device__ float fbm_0(float3  p_3, int octaves_1)
{
    int i_10 = int(0);
    float amp_0 = 0.5f;
    float3  _S107 = p_3;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_10 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_10 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S107);
        float norm_1 = norm_0 + amp_0;
        float3  _S108 = _S107 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_10 = i_10 + int(1);
        amp_0 = amp_1;
        _S107 = _S108;
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

static __device__ float iceDensity_0(GeneratorInput_0 * g_9, StructuredBuffer<float2 > disp_5, float3  p_4)
{
    float depth_1 = g_9->cellAltitude_0 - p_4.y;
    bool _S109;
    if(depth_1 < 0.0f)
    {
        _S109 = true;
    }
    else
    {
        _S109 = depth_1 > (g_9->streakLength_0);
    }
    if(_S109)
    {
        return 0.0f;
    }
    float2  _S110 = float2 {p_4.x, p_4.z};
    float2  _S111 = driftAt_0(g_9, disp_5, depth_1);
    float2  source_0 = _S110 - _S111;
    float _S112 = cellField_0(g_9, source_0);
    if(_S112 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S112 * (F32_exp((- g_9->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_9->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_9->streakLength_0, g_9->streakLength_0, depth_1)) * (F32_max((1.0f + g_9->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_9->detailScale_0)).x, (source_0 / make_float2 (g_9->detailScale_0)).y, depth_1 / (F32_max((g_9->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_9->timeSeconds_0 * 0.00999999977648258f), g_9->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_9->opticalDepth_0 / (F32_max((g_9->streakLength_0), (1.0f)));
}

static __device__ float convUpdraft_0(ConvectionInput_0 * c_10, float2  q_1)
{
    float2  g_10 = q_1 / make_float2 (c_10->cvSpacing_0);
    float2  _S113 = floor_0(g_10);
    int2  _S114 = make_int2 ((int)_S113.x, (int)_S113.y);
    float oTop_0 = 0.0f;
    float oNext_0 = 0.0f;
    float kTop_0 = 0.0f;
    float kNext_0 = 0.0f;
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
        float oTop_1 = oTop_0;
        float oNext_1 = oNext_0;
        float kTop_1 = kTop_0;
        float kNext_1 = kNext_0;
        int i_11 = int(-1);
        for(;;)
        {
            if(i_11 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_3 = _S114 + make_int2 (i_11, j_3);
            float _S115 = convVigour_0(c_10, slot_3);
            if(_S115 <= 0.0f)
            {
                i_11 = i_11 + int(1);
                continue;
            }
            float2  d_3 = g_10 - convCellCentre_0(slot_3);
            float d2_1 = dot_1(d_3, d_3);
            float ko_0 = _S115 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S115 * convBump_0(d2_1, 1.04999995231628418f);
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
                float _S116 = oTop_2;
                oTop_2 = oTop_1;
                oNext_2 = _S116;
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
                float _S117 = kTop_2;
                kTop_2 = kTop_1;
                kNext_2 = _S117;
            }
            oTop_1 = oTop_2;
            oNext_1 = oNext_2;
            kTop_1 = kTop_2;
            kNext_1 = kNext_2;
            i_11 = i_11 + int(1);
        }
        int j_4 = j_3 + int(1);
        oTop_0 = oTop_1;
        oNext_0 = oNext_1;
        kTop_0 = kTop_1;
        kNext_0 = kNext_1;
        j_3 = j_4;
    }
    return lerp_1((F32_min((oNext_0 / 0.31000000238418579f), (1.0f))), kTop_0 - kNext_0, c_10->cvPolarity_0);
}

static __device__ float convPuffs_0(float3  x_18)
{
    float3  fl_0 = floor_1(x_18);
    int3  _S118 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_1 = x_18 - fl_0;
    int dz_0;
    if((f_1.x) < 0.5f)
    {
        dz_0 = int(-1);
    }
    else
    {
        dz_0 = int(0);
    }
    int dy_0;
    if((f_1.y) < 0.5f)
    {
        dy_0 = int(-1);
    }
    else
    {
        dy_0 = int(0);
    }
    int dx_0;
    if((f_1.z) < 0.5f)
    {
        dx_0 = int(-1);
    }
    else
    {
        dx_0 = int(0);
    }
    int3  _S119 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S119 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S120 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_4 = _S120 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S118 + off_0) - f_1;
                float _S121 = (F32_min((nearest_1), (dot_0(d_4, d_4))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S121;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_11, float3  p_5)
{
    float3  _S122 = make_float3 (p_5.x, p_5.y - c_11->cvRise_0, p_5.z) / make_float3 (c_11->cvBillowScale_0);
    int i_12 = int(0);
    float amp_2 = 0.60000002384185791f;
    float3  x_19 = _S122;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_12 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_12 >= (c_11->cvOctaves_0))
        {
            break;
        }
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_19);
        float norm_3 = norm_2 + amp_2;
        float3  x_20 = x_19 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_12 = i_12 + int(1);
        amp_2 = amp_3;
        x_19 = x_20;
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
    return clamp_1(raw_0 * 2.20000004768371582f - 1.15999996662139893f, -1.0f, 1.0f);
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_12, float3  p_6)
{
    float _S123 = p_6.y;
    float above_1 = _S123 - c_12->cvBase_0;
    bool _S124;
    if(above_1 < 0.0f)
    {
        _S124 = true;
    }
    else
    {
        _S124 = above_1 > (c_12->cvDepth_0 + c_12->cvBillow_0);
    }
    if(_S124)
    {
        return 0.0f;
    }
    float2  q_2 = float2 {p_6.x, p_6.z} - c_12->cvDrift_0;
    float _S125 = convUpdraft_0(c_12, q_2);
    float _S126 = convTowerHeight_0(c_12, _S125);
    if(_S126 <= 0.0f)
    {
        return 0.0f;
    }
    float _S127 = convLift_0(c_12, above_1);
    float _S128 = _S126 - above_1;
    if((_S128 + _S127) <= 0.0f)
    {
        return 0.0f;
    }
    float inside_1;
    if((_S128 - _S127) >= 12.0f)
    {
        inside_1 = 12.0f;
    }
    else
    {
        float _S129 = convBillow_0(c_12, make_float3 (q_2.x, _S123, q_2.y));
        float inside_2 = _S128 + _S127 * _S129;
        if(inside_2 <= 0.0f)
        {
            return 0.0f;
        }
        inside_1 = inside_2;
    }
    return c_12->cvSigma_0 * (F32_sqrt((saturate_0(above_1 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1);
}

static __device__ float densityAt_0(Medium_0 * m_5, StructuredBuffer<float2 > disp_6, float3  p_7)
{
    float _S130 = p_7.y;
    bool _S131;
    if(_S130 < (m_5->slabBottom_0))
    {
        _S131 = true;
    }
    else
    {
        _S131 = _S130 > (m_5->slabTop_0);
    }
    if(_S131)
    {
        return 0.0f;
    }
    int _S132 = m_5->mode_0;
    if((m_5->mode_0) == int(0))
    {
        return m_5->density_0;
    }
    if(_S132 == int(2))
    {
        float _S133 = iceDensity_0(&m_5->gen_0, disp_6, p_7);
        return _S133;
    }
    if(_S132 == int(3))
    {
        float _S134 = convectionDensity_0(&m_5->conv_0, p_7);
        return _S134;
    }
    float3  d_5 = (p_7 - m_5->coreCentre_0) / make_float3 ((F32_max((m_5->coreRadius_0), (9.99999997475242708e-07f))));
    return m_5->density_0 + m_5->coreDensity_0 * (F32_exp((- dot_0(d_5, d_5))));
}

static __device__ float transmittance_0(Medium_0 * m_6, MajorantGrid_0 * g_11, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > disp_7, Rng_0 * rng_1, float3  p_8, float3  dir_0, int * steps_1)
{
    float t0_1;
    float t1_1;
    bool _S135 = slabRange_0(m_6, p_8, dir_0, &t0_1, &t1_1);
    if(!_S135)
    {
        return 1.0f;
    }
    float _S136 = (F32_max((t0_1), (0.0f)));
    t0_1 = _S136;
    Dda_0 _S137 = ddaInit_0(g_11, p_8, dir_0, _S136);
    Dda_0 dda_1 = _S137;
    float _S138 = m_6->majorant_0;
    float _S139 = gridBound_0(m_6, g_11, bounds_2, disp_7, (&dda_1)->cell_0, m_6->majorant_0);
    float localMaj_0 = _S139;
    int i_13 = int(0);
    float t_3 = _S136;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_13 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_1 = *steps_1 + int(1);
        Dda_0 _S140 = dda_1;
        float _S141 = ddaExit_0(&_S140);
        float _S142 = (F32_min((_S141), (t1_1)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S142 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S143 = gridBound_0(m_6, g_11, bounds_2, disp_7, (&dda_1)->cell_0, _S138);
            localMaj_0 = _S143;
            t_3 = _S142;
            i_13 = i_13 + int(1);
            continue;
        }
        float _S144 = randFloat_0(rng_1);
        float t_4 = t_3 - (F32_log(((F32_max((1.0f - _S144), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_4 >= _S142)
        {
            if(_S142 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S145 = gridBound_0(m_6, g_11, bounds_2, disp_7, (&dda_1)->cell_0, _S138);
            localMaj_0 = _S145;
            t_3 = _S142;
            i_13 = i_13 + int(1);
            continue;
        }
        float _S146 = densityAt_0(m_6, disp_7, p_8 + dir_0 * make_float3 (t_4));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S146 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S147 = randFloat_0(rng_1);
            if(_S147 > 0.5f)
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
        i_13 = i_13 + int(1);
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

struct Environment_0
{
    float3  uniformRadiance_0;
    SkyInput_0 sky_0;
    int envMode_0;
};

struct PhaseInput_0
{
    float hgG_0;
    float draineG_0;
    float draineAlpha_0;
    float draineW_0;
    int useIce_0;
    float lobeG_0;
    float lobeWeight_0;
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
    int layer2On_0;
    Medium_0 medium2_0;
    MajorantGrid_0 grid2_0;
    float3  albedo2_0;
    PhaseInput_0 phase2_0;
};

static __device__ float sceneTransmittance_0(Scene_0 * s_4, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > drift_1, Rng_0 * rng_2, float3  p_9, float3  dir_1, int * steps_2)
{
    float _S148 = transmittance_0(&s_4->medium_0, &s_4->grid_0, bounds_3, drift_1, rng_2, p_9, dir_1, steps_2);
    bool _S149;
    if((s_4->layer2On_0) != int(0))
    {
        _S149 = _S148 > 0.0f;
    }
    else
    {
        _S149 = false;
    }
    float tr_3;
    if(_S149)
    {
        MajorantGrid_0 _S150 = gridFor_0(&s_4->medium2_0, &s_4->grid2_0, p_9);
        MajorantGrid_0 _S151 = _S150;
        float _S152 = transmittance_0(&s_4->medium2_0, &_S151, bounds_3, drift_1, rng_2, p_9, dir_1, steps_2);
        tr_3 = _S148 * _S152;
    }
    else
    {
        tr_3 = _S148;
    }
    return tr_3;
}

static __device__ float hg_0(float cosT_0, float g_12)
{
    float _S153 = g_12 * g_12;
    float d_6 = 1.0f + _S153 - 2.0f * g_12 * cosT_0;
    return (1.0f - _S153) / (12.56637096405029297f * d_6 * (F32_sqrt(((F32_max((d_6), (9.99999997475242708e-07f)))))));
}

static __device__ float phaseIce_0(float cosT_1)
{
    float t_5 = ((F32_acos((clamp_1(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_1(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_5 * t_5))) * 0.34999999403953552f;
}

static __device__ float draine_0(float cosT_2, float g_13, float a_4)
{
    float _S154 = g_13 * g_13;
    float _S155 = 2.0f * g_13;
    float d_7 = 1.0f + _S154 - _S155 * cosT_2;
    return (1.0f - _S154) / (12.56637096405029297f * d_7 * (F32_sqrt(((F32_max((d_7), (9.99999997475242708e-07f))))))) * (1.0f + a_4 * cosT_2 * cosT_2) / (1.0f + a_4 * (1.0f + _S155 * g_13) / 3.0f);
}

static __device__ float phaseLiquid_0(PhaseInput_0 * p_10, float cosT_3)
{
    return (1.0f - p_10->draineW_0) * hg_0(cosT_3, p_10->hgG_0) + p_10->draineW_0 * draine_0(cosT_3, p_10->draineG_0, p_10->draineAlpha_0);
}

static __device__ float phaseAt_0(PhaseInput_0 * p_11, float cosT_4)
{
    float _S156;
    if((p_11->useIce_0) != int(0))
    {
        _S156 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S157 = phaseLiquid_0(p_11, cosT_4);
        _S156 = _S157;
    }
    return _S156;
}

static __device__ float phaseCamera_0(PhaseInput_0 * p_12, float cosT_5)
{
    float _S158 = phaseAt_0(p_12, cosT_5);
    float _S159 = p_12->lobeWeight_0;
    float v_2;
    if((p_12->lobeWeight_0) > 0.0f)
    {
        v_2 = _S158 + _S159 * hg_0(cosT_5, p_12->lobeG_0);
    }
    else
    {
        v_2 = _S158;
    }
    return v_2;
}

static __device__ float sunIrradianceTop_0(SkyInput_0 * p_13)
{
    return 20.0f * p_13->sunIntensity_0;
}

static __device__ float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static __device__ float3  normalizeExact_0(float3  v_3)
{
    float len2_0 = dot_0(v_3, v_3);
    if(len2_0 <= 0.0f)
    {
        return make_float3 (0.0f, 1.0f, 0.0f);
    }
    return v_3 * make_float3 (1.0f / (F32_sqrt((len2_0))));
}

static __device__ float3  sunDirection_0(SkyInput_0 * p_14)
{
    float az_0 = toRadians_0(p_14->sunAzimuth_0);
    float el_0 = toRadians_0(p_14->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(make_float3 ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static __device__ float lutMuFor_0(float3  geocentric_0, float3  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S160;
    if(len_0 > 1.0f)
    {
        _S160 = dot_0(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S160 = dot_0(geocentric_0, sun_0);
    }
    return _S160;
}

static __device__ float clampf_0(float v_4, float lo_5, float hi_4)
{
    float _S161;
    if(v_4 < lo_5)
    {
        _S161 = lo_5;
    }
    else
    {
        if(v_4 > hi_4)
        {
            _S161 = hi_4;
        }
        else
        {
            _S161 = v_4;
        }
    }
    return _S161;
}

static __device__ float3  sampleTransmittanceLut_0(SkyInput_0 * p_15, float altitude_0, float mu_0)
{
    StructuredBuffer<float> _S162 = p_15->transmittanceLut_0;
    if(uint(StructuredBuffer_getCount_0(p_15->transmittanceLut_0)) < 49152U)
    {
        return make_float3 (1.0f, 1.0f, 1.0f);
    }
    float _S163 = p_15->scaleHeight_0;
    float scaleHeight_1;
    if((p_15->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S163;
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
    float _S164 = fx_1 - float(x0_1);
    float _S165 = fy_1 - float(y0_1);
    int _S166 = y0_1 * int(256);
    int _S167 = (_S166 + x0_1) * int(3);
    int _S168 = (_S166 + x1_1) * int(3);
    int _S169 = y1_1 * int(256);
    int _S170 = (_S169 + x0_1) * int(3);
    int _S171 = (_S169 + x1_1) * int(3);
    float3  out_0 = make_float3 (0.0f, 0.0f, 0.0f);
    int c_13 = int(0);
    for(;;)
    {
        if(c_13 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S172 = __ldg((&(_S162)[_S167 + c_13]));
        float _S173 = 1.0f - _S164;
        float _S174 = _S172 * _S173;
        float _S175 = __ldg((&(_S162)[_S168 + c_13]));
        float a_5 = _S174 + _S175 * _S164;
        float _S176 = __ldg((&(_S162)[_S170 + c_13]));
        float _S177 = _S176 * _S173;
        float _S178 = __ldg((&(_S162)[_S171 + c_13]));
        float r_3 = a_5 * (1.0f - _S165) + (_S177 + _S178 * _S164) * _S165;
        if(c_13 == int(0))
        {
            *&((&out_0)->x) = r_3;
        }
        else
        {
            if(c_13 == int(1))
            {
                *&((&out_0)->y) = r_3;
            }
            else
            {
                *&((&out_0)->z) = r_3;
            }
        }
        c_13 = c_13 + int(1);
    }
    return out_0;
}

static __device__ float3  sunTransmittanceAt_0(SkyInput_0 * p_16, float3  worldPos_0)
{
    float3  _S179 = sunDirection_0(p_16);
    float _S180 = p_16->planetRadius_0;
    float planetRadius_1;
    if((p_16->planetRadius_0) > 1000.0f)
    {
        planetRadius_1 = _S180;
    }
    else
    {
        planetRadius_1 = 1000.0f;
    }
    float _S181 = worldPos_0.y;
    float altitude_1;
    if(_S181 > 0.0f)
    {
        altitude_1 = _S181;
    }
    else
    {
        altitude_1 = 0.0f;
    }
    float3  _S182 = sampleTransmittanceLut_0(p_16, altitude_1, lutMuFor_0(make_float3 (worldPos_0.x, planetRadius_1 + _S181, worldPos_0.z), _S179));
    return _S182;
}

static __device__ float3  sunIrradianceAt_0(Scene_0 * s_5, float3  p_17)
{
    if(((&s_5->environment_0)->envMode_0) == int(1))
    {
        float _S183 = sunIrradianceTop_0(&(&s_5->environment_0)->sky_0);
        float3  _S184 = sunTransmittanceAt_0(&(&s_5->environment_0)->sky_0, p_17);
        return make_float3 (_S183) * _S184;
    }
    return s_5->sunIrradiance_0;
}

static __device__ float3  cameraSegmentSun_0(Scene_0 * s_6, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > drift_2, Rng_0 * rng_3, Rng_0 * rng2_0, float3  ro_2, float3  rd_2, int * steps_3)
{
    float ph0_0;
    float kept_0;
    float3  keptAt_0;
    int keptLayer_0;
    Rng_0 _S185 = *rng2_0;
    float3  none_0 = make_float3 (0.0f, 0.0f, 0.0f);
    float _S186 = (F32_max((s_6->neeTentativeScale_0), (1.0f)));
    float tA_0;
    float endA_0;
    bool _S187 = slabRange_0(&s_6->medium_0, ro_2, rd_2, &tA_0, &endA_0);
    float _S188 = (F32_max((tA_0), (0.0f)));
    tA_0 = _S188;
    Dda_0 _S189 = ddaInit_0(&s_6->grid_0, ro_2, rd_2, _S188);
    Dda_0 ddaA_0 = _S189;
    float _S190 = gridBound_0(&s_6->medium_0, &s_6->grid_0, bounds_4, drift_2, (&ddaA_0)->cell_0, (&s_6->medium_0)->majorant_0);
    float rateA_0 = _S190 * _S186;
    int budgetA_0 = int(4096);
    float keepA_0 = 0.0f;
    float rouletteA_0 = 0.0f;
    bool haveA_0;
    if(_S187)
    {
        bool _S191 = segmentStep_0(&s_6->medium_0, &s_6->grid_0, bounds_4, drift_2, _S186, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
        haveA_0 = _S191;
    }
    else
    {
        haveA_0 = _S187;
    }
    float tB_0 = 0.0f;
    float endB_0 = 0.0f;
    bool haveB_0;
    if((s_6->layer2On_0) != int(0))
    {
        bool _S192 = slabRange_0(&s_6->medium2_0, ro_2, rd_2, &tB_0, &endB_0);
        haveB_0 = _S192;
    }
    else
    {
        haveB_0 = false;
    }
    float _S193 = (F32_max((tB_0), (0.0f)));
    tB_0 = _S193;
    MajorantGrid_0 _S194 = gridFor_0(&s_6->medium2_0, &s_6->grid2_0, ro_2);
    MajorantGrid_0 _S195 = _S194;
    Dda_0 _S196 = ddaInit_0(&_S195, ro_2, rd_2, _S193);
    Dda_0 ddaB_0 = _S196;
    MajorantGrid_0 _S197 = _S194;
    float _S198 = gridBound_0(&s_6->medium2_0, &_S197, bounds_4, drift_2, (&ddaB_0)->cell_0, (&s_6->medium2_0)->majorant_0);
    float rateB_0 = _S198 * _S186;
    int budgetB_0 = int(4096);
    float keepB_0 = 0.0f;
    float rouletteB_0 = 0.0f;
    if(haveB_0)
    {
        MajorantGrid_0 _S199 = _S194;
        bool _S200 = segmentStep_0(&s_6->medium2_0, &_S199, bounds_4, drift_2, _S186, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S185, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
        haveB_0 = _S200;
    }
    float kept_1 = 0.0f;
    float3  keptAt_1 = none_0;
    int keptLayer_1 = int(0);
    float tr_4 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        bool _S201;
        if(haveA_0)
        {
            _S201 = true;
        }
        else
        {
            _S201 = haveB_0;
        }
        if(_S201)
        {
        }
        else
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            keptLayer_0 = keptLayer_1;
            break;
        }
        bool takeA_0;
        if(haveA_0)
        {
            if(!haveB_0)
            {
                takeA_0 = true;
            }
            else
            {
                takeA_0 = tA_0 <= tB_0;
            }
        }
        else
        {
            takeA_0 = false;
        }
        if(takeA_0)
        {
            ph0_0 = tA_0;
        }
        else
        {
            ph0_0 = tB_0;
        }
        float rate_1;
        if(takeA_0)
        {
            rate_1 = rateA_0;
        }
        else
        {
            rate_1 = rateB_0;
        }
        float uKeep_1;
        if(takeA_0)
        {
            uKeep_1 = keepA_0;
        }
        else
        {
            uKeep_1 = keepB_0;
        }
        float uLive_1;
        if(takeA_0)
        {
            uLive_1 = rouletteA_0;
        }
        else
        {
            uLive_1 = rouletteB_0;
        }
        float3  p_18 = ro_2 + rd_2 * make_float3 (ph0_0);
        float sigma_0;
        if(takeA_0)
        {
            float _S202 = densityAt_0(&s_6->medium_0, drift_2, p_18);
            sigma_0 = _S202;
        }
        else
        {
            float _S203 = densityAt_0(&s_6->medium2_0, drift_2, p_18);
            sigma_0 = _S203;
        }
        if(sigma_0 > 0.0f)
        {
            float w_1 = sigma_0 / rate_1;
            float b_3 = tr_4 * w_1;
            float total_1;
            if(b_3 > 0.0f)
            {
                float total_2 = total_0 + b_3;
                if((uKeep_1 * total_2) < b_3)
                {
                    if(takeA_0)
                    {
                        keptLayer_0 = int(0);
                    }
                    else
                    {
                        keptLayer_0 = int(1);
                    }
                    kept_0 = b_3;
                    keptAt_0 = p_18;
                }
                else
                {
                    kept_0 = kept_1;
                    keptAt_0 = keptAt_1;
                    keptLayer_0 = keptLayer_1;
                }
                total_1 = total_2;
            }
            else
            {
                kept_0 = kept_1;
                keptAt_0 = keptAt_1;
                keptLayer_0 = keptLayer_1;
                total_1 = total_0;
            }
            float tr_5 = tr_4 * (F32_max((0.0f), (1.0f - w_1)));
            float tr_6;
            if(tr_5 < 0.00999999977648258f)
            {
                if(uLive_1 > 0.5f)
                {
                    total_0 = total_1;
                    break;
                }
                tr_6 = tr_5 * 2.0f;
            }
            else
            {
                tr_6 = tr_5;
            }
            tr_4 = tr_6;
            total_0 = total_1;
        }
        else
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            keptLayer_0 = keptLayer_1;
        }
        if(takeA_0)
        {
            bool _S204 = segmentStep_0(&s_6->medium_0, &s_6->grid_0, bounds_4, drift_2, _S186, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
            haveA_0 = _S204;
        }
        else
        {
            MajorantGrid_0 _S205 = _S194;
            bool _S206 = segmentStep_0(&s_6->medium2_0, &_S205, bounds_4, drift_2, _S186, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S185, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
            haveB_0 = _S206;
        }
        kept_1 = kept_0;
        keptAt_1 = keptAt_0;
        keptLayer_1 = keptLayer_0;
    }
    if(!(total_0 > 0.0f))
    {
        haveA_0 = true;
    }
    else
    {
        haveA_0 = !(kept_0 > 0.0f);
    }
    if(haveA_0)
    {
        return none_0;
    }
    float3  _S207 = s_6->sunDir_0;
    float _S208 = sceneTransmittance_0(s_6, bounds_4, drift_2, rng_3, keptAt_0 + s_6->sunDir_0 * make_float3 (s_6->shadowOffset_0), s_6->sunDir_0, steps_3);
    float3  _S209 = s_6->albedo_0;
    float3  matterAlbedo_0;
    if(keptLayer_0 == int(0))
    {
        float _S210 = phaseCamera_0(ph_0, dot_0(rd_2, _S207));
        matterAlbedo_0 = _S209;
        ph0_0 = _S210;
    }
    else
    {
        float _S211 = phaseCamera_0(&s_6->phase2_0, dot_0(rd_2, _S207));
        matterAlbedo_0 = s_6->albedo2_0;
        ph0_0 = _S211;
    }
    float3  _S212 = make_float3 (total_0) * matterAlbedo_0 * make_float3 (ph0_0) * make_float3 (_S208);
    float3  _S213 = sunIrradianceAt_0(s_6, keptAt_0);
    return _S212 * _S213;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_7, MajorantGrid_0 * g_14, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > disp_8, Rng_0 * rng_4, float3  ro_3, float3  rd_3, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_4)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_2;
    float t1_2;
    bool _S214 = slabRange_0(m_7, ro_3, rd_3, &t0_2, &t1_2);
    if(!_S214)
    {
        return false;
    }
    float _S215 = (F32_min((t1_2), (tLimit_0)));
    t1_2 = _S215;
    if(!(_S215 > t0_2))
    {
        return false;
    }
    float _S216 = (F32_max((t0_2), (0.0f)));
    Dda_0 _S217 = ddaInit_0(g_14, ro_3, rd_3, _S216);
    Dda_0 dda_2 = _S217;
    float _S218 = m_7->majorant_0;
    float _S219 = gridBound_0(m_7, g_14, bounds_5, disp_8, (&dda_2)->cell_0, m_7->majorant_0);
    float localMaj_1 = _S219;
    int i_14 = int(0);
    float t_6 = _S216;
    for(;;)
    {
        if(i_14 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_4 = *steps_4 + int(1);
        Dda_0 _S220 = dda_2;
        float _S221 = ddaExit_0(&_S220);
        float _S222 = (F32_min((_S221), (t1_2)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S222 >= t1_2)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S223 = gridBound_0(m_7, g_14, bounds_5, disp_8, (&dda_2)->cell_0, _S218);
            localMaj_1 = _S223;
            t_6 = _S222;
            i_14 = i_14 + int(1);
            continue;
        }
        float _S224 = randFloat_0(rng_4);
        float t_7 = t_6 - (F32_log(((F32_max((1.0f - _S224), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_7 >= _S222)
        {
            if(_S222 >= t1_2)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S225 = gridBound_0(m_7, g_14, bounds_5, disp_8, (&dda_2)->cell_0, _S218);
            localMaj_1 = _S225;
            t_6 = _S222;
            i_14 = i_14 + int(1);
            continue;
        }
        float3  p_19 = ro_3 + rd_3 * make_float3 (t_7);
        float _S226 = randFloat_0(rng_4);
        float _S227 = densityAt_0(m_7, disp_8, p_19);
        if(_S226 < (_S227 / localMaj_1))
        {
            *scatterPoint_0 = p_19;
            *distance_0 = t_7;
            return true;
        }
        t_6 = t_7;
        i_14 = i_14 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_8, MajorantGrid_0 * g_15, StructuredBuffer<float> bounds_6, StructuredBuffer<float2 > disp_9, Rng_0 * rng_5, float3  ro_4, float3  rd_4, float3  * scatterPoint_1, float * distance_1, int * steps_5)
{
    bool _S228 = sampleFreeFlightUpTo_0(m_8, g_15, bounds_6, disp_9, rng_5, ro_4, rd_4, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_5);
    return _S228;
}

static __device__ bool sceneFreeFlight_0(Scene_0 * s_7, StructuredBuffer<float> bounds_7, StructuredBuffer<float2 > drift_3, Rng_0 * rng_6, float3  ro_5, float3  rd_5, float3  * scatterAt_0, int * layer_0, int * steps_6)
{
    *layer_0 = int(0);
    float dist_0;
    if((s_7->layer2On_0) == int(0))
    {
        bool _S229 = sampleFreeFlight_0(&s_7->medium_0, &s_7->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, scatterAt_0, &dist_0, steps_6);
        return _S229;
    }
    float a0_0;
    float a1_0;
    bool _S230 = slabRange_0(&s_7->medium_0, ro_5, rd_5, &a0_0, &a1_0);
    float b0_0;
    float b1_0;
    bool _S231 = slabRange_0(&s_7->medium2_0, ro_5, rd_5, &b0_0, &b1_0);
    bool secondFirst_0;
    if(_S231)
    {
        if(!_S230)
        {
            secondFirst_0 = true;
        }
        else
        {
            secondFirst_0 = (F32_max((b0_0), (0.0f))) < (F32_max((a0_0), (0.0f)));
        }
    }
    else
    {
        secondFirst_0 = false;
    }
    float3  pNear_0;
    float3  pFar_0;
    float dNear_1;
    float dFar_0;
    MajorantGrid_0 _S232 = gridFor_0(&s_7->medium2_0, &s_7->grid2_0, ro_5);
    float _S233;
    if(secondFirst_0)
    {
        MajorantGrid_0 _S234 = _S232;
        bool _S235 = sampleFreeFlight_0(&s_7->medium2_0, &_S234, bounds_7, drift_3, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S235)
        {
            _S233 = dNear_1;
        }
        else
        {
            _S233 = 1.00000001504746622e+30f;
        }
        bool _S236 = sampleFreeFlightUpTo_0(&s_7->medium_0, &s_7->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, _S233, &pFar_0, &dFar_0, steps_6);
        if(_S236)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(0);
            return true;
        }
        if(_S235)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(1);
            return true;
        }
    }
    else
    {
        bool _S237 = sampleFreeFlight_0(&s_7->medium_0, &s_7->grid_0, bounds_7, drift_3, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S237)
        {
            _S233 = dNear_1;
        }
        else
        {
            _S233 = 1.00000001504746622e+30f;
        }
        MajorantGrid_0 _S238 = _S232;
        bool _S239 = sampleFreeFlightUpTo_0(&s_7->medium2_0, &_S238, bounds_7, drift_3, rng_6, ro_5, rd_5, _S233, &pFar_0, &dFar_0, steps_6);
        if(_S239)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(1);
            return true;
        }
        if(_S237)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(0);
            return true;
        }
    }
    *scatterAt_0 = make_float3 (0.0f, 0.0f, 0.0f);
    return false;
}

static __device__ float shellC_0(float altitude_2, float planetRadius_2, float shellHeight_0)
{
    float d_8 = altitude_2 - shellHeight_0;
    return d_8 * (d_8 + 2.0f * planetRadius_2 + 2.0f * shellHeight_0);
}

static __device__ float shellExit_0(float b_4, float c_14)
{
    float disc_0 = b_4 * b_4 - c_14;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_4 + (F32_sqrt((disc_0)));
}

static __device__ float shellEnter_0(float b_5, float c_15)
{
    float disc_1 = b_5 * b_5 - c_15;
    if(disc_1 < 0.0f)
    {
        return -1.0f;
    }
    return - b_5 - (F32_sqrt((disc_1)));
}

static __device__ float3  rayleighCoefficients_0()
{
    return make_float3 (5.80200003241770901e-06f, 0.00001355800031888f, 0.00003310000101919f);
}

static __device__ float mieCoefficient_0(float turbidity_1)
{
    return 3.99600003220257349e-06f * (turbidity_1 / 2.20000004768371582f);
}

static __device__ float altitudeFromQ_0(float q_3, float planetRadius_3)
{
    float rr_0 = planetRadius_3 * planetRadius_3 + q_3;
    float _S240;
    if(rr_0 > 0.0f)
    {
        _S240 = rr_0;
    }
    else
    {
        _S240 = 0.0f;
    }
    return q_3 / (planetRadius_3 + (F32_sqrt((_S240))));
}

static __device__ float3  skyRadiance_0(SkyInput_0 * p_20, float originAltitude_0, float3  rayDir_0, bool includeSunDisc_0)
{
    float hc_0;
    float3  _S241 = sunDirection_0(p_20);
    float _S242 = p_20->planetRadius_0;
    float planetRadius_4;
    if((p_20->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S242;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S243 = p_20->scaleHeight_0;
    float scaleHeight_2;
    if((p_20->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S243;
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
    float _S244 = planetRadius_4 + observerAltitude_0;
    float _S245 = rayDir_0.y;
    float b_6 = _S244 * _S245;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_4, 0.0f);
    float tTop_0 = shellExit_0(b_6, shellC_0(observerAltitude_0, planetRadius_4, atmosphereHeight_0));
    if(tTop_0 <= 0.0f)
    {
        return make_float3 (0.0f, 0.0f, 0.0f);
    }
    float tGround_0 = shellEnter_0(b_6, cGround_0);
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
    float betaM_0 = mieCoefficient_0(p_20->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_0, _S241), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_16 = clampf_0(p_20->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S246 = g_16 * g_16;
    float hgDenom_0 = 1.0f + _S246 - 2.0f * g_16 * cosTheta_0;
    float _S247 = 1.0f - _S246;
    float _S248 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S247 / (_S248 * (F32_sqrt((tPrev_0))));
    float3  _S249 = make_float3 (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    float3  sumR_0 = _S249;
    float3  sumM_0 = _S249;
    int i_15 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_15 < int(24))
        {
        }
        else
        {
            break;
        }
        int _S250 = i_15 + int(1);
        float tNext_0 = observerAltitude_0 * float(_S250 * _S250) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_15 = _S250;
            continue;
        }
        float h_3 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_6 + tMid_0 * tMid_0, planetRadius_4);
        if(h_3 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_3;
        }
        float _S251 = - hc_0;
        float dR_0 = (F32_exp((_S251 / scaleHeight_2))) * dt_0;
        float dM_0 = (F32_exp((_S251 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        float3  _S252 = sampleTransmittanceLut_0(p_20, hc_0, lutMuFor_0(make_float3 (rayDir_0.x * tMid_0, _S244 + _S245 * tMid_0, rayDir_0.z * tMid_0), _S241));
        float _S253 = betaMExt_0 * depthM_1;
        float3  transmittance_1 = make_float3 ((F32_exp((- (betaR_0.x * depthR_1 + _S253)))), (F32_exp((- (betaR_0.y * depthR_1 + _S253)))), (F32_exp((- (betaR_0.z * depthR_1 + _S253))))) * _S252;
        float3  _S254 = sumM_0 + transmittance_1 * make_float3 (dM_0);
        sumR_0 = sumR_0 + transmittance_1 * make_float3 (dR_0);
        sumM_0 = _S254;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_15 = _S250;
    }
    float _S255 = sunIrradianceTop_0(p_20);
    float3  radiance_0 = (sumR_0 * betaR_0 * make_float3 (phaseR_0) + sumM_0 * make_float3 (betaM_0 * phaseM_0)) * make_float3 (_S255);
    float3  radiance_1;
    if(hitsGround_0)
    {
        float3  groundPoint_0 = make_float3 (rayDir_0.x * tGround_0, _S244 + _S245 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S241), 0.0f, 1.0f);
        float3  _S256 = sampleTransmittanceLut_0(p_20, 0.0f, lutMuFor_0(groundPoint_0, _S241));
        float _S257 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S257)))), (F32_exp((- (betaR_0.y * depthR_0 + _S257)))), (F32_exp((- (betaR_0.z * depthR_0 + _S257))))) * _S256 * make_float3 (p_20->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S255);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S258;
    if(!hitsGround_0)
    {
        _S258 = includeSunDisc_0;
    }
    else
    {
        _S258 = false;
    }
    if(_S258)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_20->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S259 = betaMExt_0 * depthM_0;
            float3  viewT_0 = make_float3 ((F32_exp((- (betaR_0.x * depthR_0 + _S259)))), (F32_exp((- (betaR_0.y * depthR_0 + _S259)))), (F32_exp((- (betaR_0.z * depthR_0 + _S259)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_0 = solidAngle_0;
            }
            else
            {
                hc_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * make_float3 (_S255 / hc_0);
        }
    }
    return radiance_1;
}

static __device__ float3  environmentRadiance_0(Environment_0 * e_0, float3  origin_1, float3  dir_2, bool includeSunDisc_1)
{
    if((e_0->envMode_0) == int(1))
    {
        float3  _S260 = skyRadiance_0(&e_0->sky_0, origin_1.y, dir_2, includeSunDisc_1);
        return _S260;
    }
    return e_0->uniformRadiance_0;
}

static __device__ float3  sampleHG_0(Rng_0 * rng_7, float3  wo_0, float g_17, float * cosT_6)
{
    float _S261 = clamp_1(g_17, -0.99900001287460327f, 0.99900001287460327f);
    float u1_0 = randFloat_0(rng_7);
    float u2_0 = randFloat_0(rng_7);
    if((F32_abs((_S261))) < 0.00100000004749745f)
    {
        *cosT_6 = 1.0f - 2.0f * u1_0;
    }
    else
    {
        float _S262 = _S261 * _S261;
        float _S263 = 2.0f * _S261;
        float s_8 = (1.0f - _S262) / (1.0f - _S261 + _S263 * u1_0);
        *cosT_6 = (1.0f + _S262 - s_8 * s_8) / _S263;
    }
    float _S264 = clamp_1(*cosT_6, -1.0f, 1.0f);
    *cosT_6 = _S264;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S264 * _S264))))));
    float phi_0 = 6.28318548202514648f * u2_0;
    float3  w_2 = normalize_0(wo_0);
    float3  a_6;
    if((F32_abs((w_2.y))) < 0.94999998807907104f)
    {
        a_6 = make_float3 (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_6 = make_float3 (1.0f, 0.0f, 0.0f);
    }
    float3  u_3 = normalize_0(cross_0(a_6, w_2));
    return normalize_0(make_float3 (sinT_0 * (F32_cos((phi_0)))) * u_3 + make_float3 (sinT_0 * (F32_sin((phi_0)))) * cross_0(w_2, u_3) + make_float3 (*cosT_6) * w_2);
}

static __device__ float3  sampleDraine_0(Rng_0 * rng_8, float3  wo_1, float g_18, float a_7, float * cosT_7)
{
    float3  dir_3 = sampleHG_0(rng_8, wo_1, g_18, cosT_7);
    if(!(a_7 > 0.0f))
    {
        return dir_3;
    }
    float3  dir_4 = dir_3;
    int i_16 = int(0);
    for(;;)
    {
        if(i_16 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S265 = randFloat_0(rng_8);
        if((_S265 * (1.0f + a_7)) <= (1.0f + a_7 * *cosT_7 * *cosT_7))
        {
            break;
        }
        float3  _S266 = sampleHG_0(rng_8, wo_1, g_18, cosT_7);
        int i_17 = i_16 + int(1);
        dir_4 = _S266;
        i_16 = i_17;
    }
    return dir_4;
}

static __device__ float3  samplePhaseDir_0(PhaseInput_0 * p_21, Rng_0 * rng_9, float3  wo_2, float * weight_0)
{
    float cosT_8;
    float3  dir_5;
    float _S267;
    if((p_21->useIce_0) != int(0))
    {
        float _S268 = randFloat_0(rng_9);
        if(_S268 < 0.72000002861022949f)
        {
            float3  _S269 = sampleHG_0(rng_9, wo_2, 0.85000002384185791f, &cosT_8);
            dir_5 = _S269;
        }
        else
        {
            float3  _S270 = sampleHG_0(rng_9, wo_2, 0.0f, &cosT_8);
            dir_5 = _S270;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_8, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S267 = phaseIce_0(cosT_8) / pdf_0;
        }
        else
        {
            _S267 = 0.0f;
        }
        *weight_0 = _S267;
    }
    else
    {
        float _S271 = randFloat_0(rng_9);
        if(_S271 < (p_21->draineW_0))
        {
            float3  _S272 = sampleDraine_0(rng_9, wo_2, p_21->draineG_0, p_21->draineAlpha_0, &cosT_8);
            dir_5 = _S272;
        }
        else
        {
            float3  _S273 = sampleHG_0(rng_9, wo_2, p_21->hgG_0, &cosT_8);
            dir_5 = _S273;
        }
        float _S274 = phaseLiquid_0(p_21, cosT_8);
        if(_S274 > 9.99999971718068537e-10f)
        {
            _S267 = 1.0f;
        }
        else
        {
            _S267 = 0.0f;
        }
        *weight_0 = _S267;
    }
    return dir_5;
}

struct TraceResult_0
{
    float3  pathRadiance_0;
    int scatterEvents_0;
    int capped_0;
    int trackingSteps_0;
};

static __device__ TraceResult_0 trace_0(Scene_0 * s_9, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_8, StructuredBuffer<float2 > drift_4, Rng_0 * rng_10, float3  ro_6, float3  rd_6)
{
    TraceResult_0 r_4;
    (&r_4)->pathRadiance_0 = make_float3 (0.0f, 0.0f, 0.0f);
    (&r_4)->scatterEvents_0 = int(0);
    (&r_4)->capped_0 = int(0);
    (&r_4)->trackingSteps_0 = int(0);
    float3  throughput_0 = make_float3 (1.0f, 1.0f, 1.0f);
    int _S275 = (I32_min((s_9->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_9->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S275 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    if(sunAlongCamera_0)
    {
        Rng_0 _S276 = *rng_10;
        Rng_0 _S277 = splitRng_0(&_S276, 1510U);
        Rng_0 segmentRng_0 = _S277;
        Rng_0 _S278 = *rng_10;
        Rng_0 _S279 = splitRng_0(&_S278, 1511U);
        Rng_0 _S280 = _S279;
        float3  _S281 = cameraSegmentSun_0(s_9, ph_1, bounds_8, drift_4, &segmentRng_0, &_S280, ro_6, rd_6, &(&r_4)->trackingSteps_0);
        (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + _S281;
    }
    float3  _S282 = ro_6;
    float3  _S283 = rd_6;
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
        if(bounce_0 >= _S275)
        {
            (&r_4)->capped_0 = int(1);
            break;
        }
        float3  p_22;
        int layer_1;
        bool _S284 = sceneFreeFlight_0(s_9, bounds_8, drift_4, rng_10, _S282, _S283, &p_22, &layer_1, &(&r_4)->trackingSteps_0);
        if(!_S284)
        {
            float3  _S285 = environmentRadiance_0(&s_9->environment_0, _S282, _S283, bounce_0 == int(0));
            (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + throughput_1 * _S285;
            break;
        }
        (&r_4)->scatterEvents_0 = (&r_4)->scatterEvents_0 + int(1);
        float3  _S286 = s_9->albedo_0;
        float3  matterAlbedo_1;
        PhaseInput_0 matterPhase_0;
        if(layer_1 != int(0))
        {
            matterPhase_0 = s_9->phase2_0;
            matterAlbedo_1 = s_9->albedo2_0;
        }
        else
        {
            matterPhase_0 = *ph_1;
            matterAlbedo_1 = _S286;
        }
        bool _S287;
        if(bounce_0 == int(0))
        {
            _S287 = sunAlongCamera_0;
        }
        else
        {
            _S287 = false;
        }
        if(!_S287)
        {
            float3  _S288 = s_9->sunDir_0;
            float _S289 = sceneTransmittance_0(s_9, bounds_8, drift_4, rng_10, p_22 + s_9->sunDir_0 * make_float3 (s_9->shadowOffset_0), s_9->sunDir_0, &(&r_4)->trackingSteps_0);
            if(_S289 > 0.0f)
            {
                float _S290 = dot_0(_S283, _S288);
                PhaseInput_0 _S291 = matterPhase_0;
                float _S292 = phaseAt_0(&_S291, _S290);
                float3  _S293 = throughput_1 * matterAlbedo_1 * make_float3 (_S292) * make_float3 (_S289);
                float3  _S294 = sunIrradianceAt_0(s_9, p_22);
                (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + _S293 * _S294;
            }
        }
        PhaseInput_0 _S295 = matterPhase_0;
        float w_3;
        float3  _S296 = samplePhaseDir_0(&_S295, rng_10, _S283, &w_3);
        float3  throughput_2 = throughput_1 * (matterAlbedo_1 * make_float3 (w_3));
        float3  _S297 = p_22;
        if(bounce_0 >= (s_9->rrStartBounce_0))
        {
            float p2_0 = clamp_1((F32_max((throughput_2.x), ((F32_max((throughput_2.y), (throughput_2.z)))))), 0.05000000074505806f, 1.0f);
            float _S298 = randFloat_0(rng_10);
            if(_S298 > p2_0)
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
        _S282 = _S297;
        _S283 = _S296;
        bounce_0 = bounce_1;
    }
    return r_4;
}

static __device__ float3  renderSample_0(Scene_0 * s_10, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_9, StructuredBuffer<float2 > drift_5, float3  ro_7, float3  rd_7, uint seed_1)
{
    Rng_0 rng_11 = makeRng_0(seed_1);
    TraceResult_0 _S299 = trace_0(s_10, ph_2, bounds_9, drift_5, &rng_11, ro_7, rd_7);
    return _S299.pathRadiance_0;
}

extern "C" __global__ void renderRays(Scene_0 scene_0, PhaseInput_0 phase_0, StructuredBuffer<float> bounds_10, StructuredBuffer<float2 > drift_6, StructuredBuffer<float3 > origins_0, StructuredBuffer<float3 > directions_0, RWStructuredBuffer<float3 > outRadiance_0, uint seed_2, int count_0)
{
    int i_18 = int((blockIdx * blockDim + threadIdx).x);
    if(i_18 >= count_0)
    {
        return;
    }
    float3  * _S300 = (&(outRadiance_0)[i_18]);
    float3  _S301 = slang_ldg_0((&(origins_0)[i_18]));
    float3  _S302 = slang_ldg_0((&(directions_0)[i_18]));
    uint _S303 = seed_2 + uint(i_18);
    Scene_0 _S304 = scene_0;
    PhaseInput_0 _S305 = phase_0;
    float3  _S306 = renderSample_0(&_S304, &_S305, bounds_10, drift_6, _S301, _S302, _S303);
    *_S300 = _S306;
    return;
}

