// GENERATED FROM Transport.slang BY slangc -- DO NOT EDIT.
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

static __device__ float dot_1(float2  x_1, float2  y_1)
{
    return x_1.x * y_1.x + x_1.y * y_1.y;
}

static __device__ float length_0(float2  x_2)
{
    return (F32_sqrt((dot_1(x_2, x_2))));
}

static __device__ float2  min_0(float2  x_3, float2  y_2)
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
        *_slang_vector_get_element_ptr(&result_0, i_0) = (F32_min((_slang_vector_get_element(x_3, i_0)), (_slang_vector_get_element(y_2, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ float2  lerp_0(float2  x_4, float2  y_3, float2  s_0)
{
    return x_4 + (y_3 - x_4) * s_0;
}

static __device__ int clamp_0(int x_5, int minBound_0, int maxBound_0)
{
    return (I32_min(((I32_max((x_5), (minBound_0)))), (maxBound_0)));
}

static __device__ float clamp_1(float x_6, float minBound_1, float maxBound_1)
{
    return (F32_min(((F32_max((x_6), (minBound_1)))), (maxBound_1)));
}

static __device__ float saturate_0(float x_7)
{
    return clamp_1(x_7, 0.0f, 1.0f);
}

static __device__ float smoothstep_0(float min_1, float max_0, float x_8)
{
    float _S1 = saturate_0((x_8 - min_1) / (max_0 - min_1));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static __device__ float2  abs_0(float2  x_9)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_abs((_slang_vector_get_element(x_9, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ float2  max_1(float2  x_10, float2  y_4)
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
        *_slang_vector_get_element_ptr(&result_2, i_2) = (F32_max((_slang_vector_get_element(x_10, i_2)), (_slang_vector_get_element(y_4, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ float lerp_1(float x_11, float y_5, float s_1)
{
    return x_11 + (y_5 - x_11) * s_1;
}

static __device__ bool all_0(bool2  x_12)
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
            result_3 = (bool((_slang_vector_get_element(x_12, i_3))));
        }
        else
        {
            result_3 = false;
        }
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ float2  floor_0(float2  x_13)
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
        *_slang_vector_get_element_ptr(&result_4, i_4) = (F32_floor((_slang_vector_get_element(x_13, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static __device__ float3  floor_1(float3  x_14)
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
        *_slang_vector_get_element_ptr(&result_5, i_5) = (F32_floor((_slang_vector_get_element(x_14, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
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

static __device__ uint2  pcg2d_0(uint2  v_0)
{
    uint2  _S17 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S18 = _S17;
    *&((&_S18)->x) = *&((&_S18)->x) + _S17.y * 1664525U;
    *&((&_S18)->y) = *&((&_S18)->y) + _S18.x * 1664525U;
    uint2  _S19 = _S18 ^ (_S18 >> make_uint2 (16U));
    _S18 = _S19;
    *&((&_S18)->x) = *&((&_S18)->x) + _S19.y * 1664525U;
    *&((&_S18)->y) = *&((&_S18)->y) + _S18.x * 1664525U;
    uint2  _S20 = _S18 ^ (_S18 >> make_uint2 (16U));
    _S18 = _S20;
    return _S20;
}

static __device__ float2  hash22_0(int2  c_0, uint salt_0)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_0.x), uint(c_0.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S21 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S21 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float convLife_0(float u_0)
{
    float _S22 = 1.0f - u_0;
    return 6.75f * u_0 * _S22 * _S22;
}

static __device__ float convVigour_0(ConvectionInput_0 * c_1, int2  slot_0)
{
    float2  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_1->cvAge_0 + h_1.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_1.y);
}

static __device__ float2  convCellCentre_0(int2  slot_1)
{
    float2  _S23 = make_float2 ((float)slot_1.x, (float)slot_1.y);
    return _S23 + make_float2 (0.5f) + (hash22_0(slot_1, 1759714724U) - make_float2 (0.5f)) * make_float2 (0.69999998807907104f);
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
    float _S24 = convVigour_0(c_2, slot_2);
    if(_S24 <= 0.0f)
    {
        return;
    }
    float2  ctr_0 = convCellCentre_0(slot_2);
    float2  _S25 = a_1 - ctr_0;
    float2  nearGap_0 = max_1(max_1(_S25, ctr_0 - b_0), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_1(abs_0(_S25), abs_0(b_0 - ctr_0));
    float oHi_0 = _S24 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S24 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S24 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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
    float2  _S26 = floor_0((a_2 + b_1) * make_float2 (0.5f));
    int2  _S27 = make_int2 ((int)_S26.x, (int)_S26.y);
    float2  _S28 = make_float2 ((float)_S27.x, (float)_S27.y);
    float2  highEdge_0 = _S28 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S29;
    if(all_0(a_2 >= (_S28 - make_float2 (0.00009999999747379f))))
    {
        _S29 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S29 = false;
    }
    int j_0;
    int i_6;
    if(_S29)
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
                convSlotBound_0(c_3, _S27 + make_int2 (i_6, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_6 = i_6 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    else
    {
        float2  _S30 = floor_0(a_2);
        int2  _S31 = make_int2 ((int)_S30.x, (int)_S30.y);
        int2  _S32 = make_int2 (int(1), int(1));
        int2  i0_0 = _S31 - _S32;
        float2  _S33 = floor_0(b_1);
        int2  _S34 = make_int2 ((int)_S33.x, (int)_S33.y);
        int2  _S35 = _S34 + _S32;
        int _S36 = i0_0.y;
        j_0 = _S36;
        for(;;)
        {
            if(j_0 <= (_S35.y))
            {
                _S29 = j_0 <= (_S36 + int(32));
            }
            else
            {
                _S29 = false;
            }
            if(_S29)
            {
            }
            else
            {
                break;
            }
            int _S37 = i0_0.x;
            i_6 = _S37;
            for(;;)
            {
                bool _S38;
                if(i_6 <= (_S35.x))
                {
                    _S38 = i_6 <= (_S37 + int(32));
                }
                else
                {
                    _S38 = false;
                }
                if(_S38)
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
    bool _S39;
    if(high_0 < 0.0f)
    {
        _S39 = true;
    }
    else
    {
        _S39 = low_0 > ceiling_0;
    }
    if(_S39)
    {
        return 0.0f;
    }
    float _S40 = (F32_max((low_0), (0.0f)));
    float _S41 = (F32_min((high_0), (ceiling_0)));
    float _S42 = convUpdraftBound_0(c_6, float2 {lo_0.x, lo_0.z} - c_6->cvDrift_0, float2 {hi_0.x, hi_0.z} - c_6->cvDrift_0);
    float _S43 = convTowerHeight_0(c_6, _S42);
    if(_S43 <= 0.0f)
    {
        return 0.0f;
    }
    float _S44 = convLift_0(c_6, _S41);
    float inside_0 = _S43 - _S40 + _S44 + 0.00100000004749745f;
    if(inside_0 <= 0.0f)
    {
        return 0.0f;
    }
    return c_6->cvSigma_0 * (F32_sqrt((saturate_0(_S41 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_0) * 1.00001001358032227f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_1, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_15 = clamp_1(depth_0 / g_1->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_7 = clamp_0(int((F32_floor((x_15)))), int(0), int(31));
    float2  _S45 = __ldg((&(disp_0)[i_7]));
    float2  _S46 = __ldg((&(disp_0)[i_7 + int(1)]));
    return lerp_0(_S45, _S46, make_float2 (x_15 - float(i_7)));
}

static __device__ void driftRange_0(GeneratorInput_0 * g_2, StructuredBuffer<float2 > disp_1, float d0_0, float d1_0, float2  * lo_1, float2  * hi_1)
{
    float2  _S47 = driftAt_0(g_2, disp_1, d0_0);
    *lo_1 = _S47;
    *hi_1 = _S47;
    float2  _S48 = driftAt_0(g_2, disp_1, d1_0);
    *lo_1 = min_0(*lo_1, _S48);
    *hi_1 = max_1(*hi_1, _S48);
    int _S49 = clamp_0(int((F32_ceil((clamp_1(d1_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_0 = clamp_0(int((F32_floor((clamp_1(d0_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_0 <= _S49)
        {
        }
        else
        {
            break;
        }
        float2  _S50 = *lo_1;
        float2  _S51 = __ldg((&(disp_1)[k_0]));
        *lo_1 = min_0(_S50, _S51);
        float2  _S52 = *hi_1;
        float2  _S53 = __ldg((&(disp_1)[k_0]));
        *hi_1 = max_1(_S52, _S53);
        k_0 = k_0 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_3, float2  q0_1, float2  q1_1)
{
    float spacing_0 = g_3->cellSize_0 * 2.20000004768371582f;
    float2  a_3 = (q0_1 - g_3->cellDrift_0) / make_float2 (spacing_0);
    float2  b_2 = (q1_1 - g_3->cellDrift_0) / make_float2 (spacing_0);
    float2  _S54 = floor_0(a_3);
    int2  _S55 = make_int2 ((int)_S54.x, (int)_S54.y);
    int2  _S56 = make_int2 (int(1), int(1));
    int2  i0_1 = _S55 - _S56;
    float2  _S57 = floor_0(b_2);
    int2  _S58 = make_int2 ((int)_S57.x, (int)_S57.y);
    int2  _S59 = _S58 + _S56;
    int _S60 = i0_1.y;
    int j_1 = _S60;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S61;
        if(j_1 <= (_S59.y))
        {
            _S61 = j_1 <= (_S60 + int(32));
        }
        else
        {
            _S61 = false;
        }
        if(_S61)
        {
        }
        else
        {
            break;
        }
        int _S62 = i0_1.x;
        int i_8 = _S62;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S63;
            if(i_8 <= (_S59.x))
            {
                _S63 = i_8 <= (_S62 + int(32));
            }
            else
            {
                _S63 = false;
            }
            if(_S63)
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
            float2  _S64 = make_float2 ((float)o_0.x, (float)o_0.y);
            float2  c_7 = _S64 + make_float2 (0.5f) + (hash22_0(o_0, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_1(max_1(a_3 - c_7, c_7 - b_2), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
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
    bool _S65;
    if(d1_1 < 0.0f)
    {
        _S65 = true;
    }
    else
    {
        _S65 = d0_1 > (g_4->streakLength_0);
    }
    if(_S65)
    {
        return 0.0f;
    }
    float _S66 = g_4->streakLength_0;
    float d0_2 = clamp_1(d0_1, 0.0f, g_4->streakLength_0);
    float d1_2 = clamp_1(d1_1, 0.0f, g_4->streakLength_0);
    float subl_0 = (F32_exp((- g_4->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_4->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_4, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S67 = cellFieldBound_0(g_4, make_float2 (lo_2.x, lo_2.z) - driftHi_0, make_float2 (hi_2.x, hi_2.z) - driftLo_0);
    return (F32_max((_S67 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((_S66), (1.0f)));
}

static __device__ float mediumBound_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_3, float3  lo_3, float3  hi_3)
{
    int _S68 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S69 = convectionBound_0(&m_1->conv_0, lo_3, hi_3);
        return _S69;
    }
    if(_S68 == int(2))
    {
        float _S70 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_3, hi_3);
        return _S70;
    }
    return m_1->majorant_0;
}

static __device__ float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_0, StructuredBuffer<float2 > disp_4, int3  c_8, float fallback_0)
{
    int _S71 = g_5->enabled_0;
    if((g_5->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S71 == int(2))
    {
        float3  _S72 = make_float3 ((float)c_8.x, (float)c_8.y, (float)c_8.z);
        float3  lo_4 = g_5->origin_0 + _S72 * g_5->cellExtent_0;
        float _S73 = mediumBound_0(m_2, disp_4, lo_4, lo_4 + g_5->cellExtent_0);
        return _S73;
    }
    int _S74 = c_8.x;
    bool _S75;
    if(_S74 < int(0))
    {
        _S75 = true;
    }
    else
    {
        _S75 = (c_8.y) < int(0);
    }
    if(_S75)
    {
        _S75 = true;
    }
    else
    {
        _S75 = (c_8.z) < int(0);
    }
    if(_S75)
    {
        _S75 = true;
    }
    else
    {
        _S75 = _S74 >= (g_5->dims_0.x);
    }
    if(_S75)
    {
        _S75 = true;
    }
    else
    {
        _S75 = (c_8.y) >= (g_5->dims_0.y);
    }
    if(_S75)
    {
        _S75 = true;
    }
    else
    {
        _S75 = (c_8.z) >= (g_5->dims_0.z);
    }
    if(_S75)
    {
        return fallback_0;
    }
    float _S76 = __ldg((&(bounds_0)[(c_8.z * g_5->dims_0.y + c_8.y) * g_5->dims_0.x + _S74]));
    return _S76;
}

static __device__ float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_2)
{
    bool _S77;
    if((d_2->tMax_0.x) <= (d_2->tMax_0.y))
    {
        _S77 = (d_2->tMax_0.x) <= (d_2->tMax_0.z);
    }
    else
    {
        _S77 = false;
    }
    if(_S77)
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
    uint _S78 = r_1->state_0 * 747796405U + 2891336453U;
    r_1->state_0 = _S78;
    uint word_0 = ((_S78 >> ((_S78 >> 28U) + 4U)) ^ _S78) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float cellField_0(GeneratorInput_0 * g_6, float2  q_0)
{
    float2  gq_0 = (q_0 - g_6->cellDrift_0) / make_float2 (g_6->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_0(gq_0);
    int2  _S79 = make_int2 ((int)gf_0.x, (int)gf_0.y);
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
            int2  o_1 = _S79 + make_int2 (i_9, j_2);
            if((hash22_0(o_1, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_9 = i_9 + int(1);
                continue;
            }
            float2  _S80 = make_float2 ((float)o_1.x, (float)o_1.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(gq_0 - (_S80 + make_float2 (0.5f) + (hash22_0(o_1, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f))) * 2.20000004768371582f);
            i_9 = i_9 + int(1);
        }
        j_2 = j_2 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_6->cellStrength_0;
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S81 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S82 = _S81;
    *&((&_S82)->x) = *&((&_S82)->x) + _S81.y * _S81.z;
    *&((&_S82)->y) = *&((&_S82)->y) + _S82.z * _S82.x;
    *&((&_S82)->z) = *&((&_S82)->z) + _S82.x * _S82.y;
    uint3  _S83 = _S82 ^ (_S82 >> make_uint3 (16U));
    _S82 = _S83;
    *&((&_S82)->x) = *&((&_S82)->x) + _S83.y * _S83.z;
    *&((&_S82)->y) = *&((&_S82)->y) + _S82.z * _S82.x;
    *&((&_S82)->z) = *&((&_S82)->z) + _S82.x * _S82.y;
    return _S82;
}

static __device__ float3  hash33_0(int3  c_9)
{
    uint3  h_2 = pcg3d_0(make_uint3 (uint(c_9.x), uint(c_9.y), uint(c_9.z)));
    float3  _S84 = make_float3 ((float)h_2.x, (float)h_2.y, (float)h_2.z);
    return _S84 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_1)
{
    float3  fi_0 = floor_1(p_1);
    int3  _S85 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_1 - fi_0;
    float3  u_2 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S86 = u_2.x;
    float _S87 = u_2.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S85), f_0), dot_0(hash33_0(_S85 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S86), lerp_1(dot_0(hash33_0(_S85 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S85 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S86), _S87), lerp_1(lerp_1(dot_0(hash33_0(_S85 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S85 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S86), lerp_1(dot_0(hash33_0(_S85 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S85 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S86), _S87), u_2.z);
}

static __device__ float fbm_0(float3  p_2, int octaves_1)
{
    int i_10 = int(0);
    float amp_0 = 0.5f;
    float3  _S88 = p_2;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S88);
        float norm_1 = norm_0 + amp_0;
        float3  _S89 = _S88 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_10 = i_10 + int(1);
        amp_0 = amp_1;
        _S88 = _S89;
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

static __device__ float iceDensity_0(GeneratorInput_0 * g_7, StructuredBuffer<float2 > disp_5, float3  p_3)
{
    float depth_1 = g_7->cellAltitude_0 - p_3.y;
    bool _S90;
    if(depth_1 < 0.0f)
    {
        _S90 = true;
    }
    else
    {
        _S90 = depth_1 > (g_7->streakLength_0);
    }
    if(_S90)
    {
        return 0.0f;
    }
    float2  _S91 = float2 {p_3.x, p_3.z};
    float2  _S92 = driftAt_0(g_7, disp_5, depth_1);
    float2  source_0 = _S91 - _S92;
    float _S93 = cellField_0(g_7, source_0);
    if(_S93 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S93 * (F32_exp((- g_7->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, depth_1)) * (F32_max((1.0f + g_7->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_7->detailScale_0)).x, (source_0 / make_float2 (g_7->detailScale_0)).y, depth_1 / (F32_max((g_7->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_7->timeSeconds_0 * 0.00999999977648258f), g_7->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((g_7->streakLength_0), (1.0f)));
}

static __device__ float convUpdraft_0(ConvectionInput_0 * c_10, float2  q_1)
{
    float2  g_8 = q_1 / make_float2 (c_10->cvSpacing_0);
    float2  _S94 = floor_0(g_8);
    int2  _S95 = make_int2 ((int)_S94.x, (int)_S94.y);
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
            int2  slot_3 = _S95 + make_int2 (i_11, j_3);
            float _S96 = convVigour_0(c_10, slot_3);
            if(_S96 <= 0.0f)
            {
                i_11 = i_11 + int(1);
                continue;
            }
            float2  d_3 = g_8 - convCellCentre_0(slot_3);
            float d2_1 = dot_1(d_3, d_3);
            float ko_0 = _S96 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S96 * convBump_0(d2_1, 1.04999995231628418f);
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
                float _S97 = oTop_2;
                oTop_2 = oTop_1;
                oNext_2 = _S97;
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
                float _S98 = kTop_2;
                kTop_2 = kTop_1;
                kNext_2 = _S98;
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

static __device__ float convPuffs_0(float3  x_16)
{
    float3  fl_0 = floor_1(x_16);
    int3  _S99 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
    float3  f_1 = x_16 - fl_0;
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
    int3  _S100 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S100 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S101 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_4 = _S101 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S99 + off_0) - f_1;
                float _S102 = (F32_min((nearest_1), (dot_0(d_4, d_4))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S102;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_11, float3  p_4)
{
    float3  _S103 = make_float3 (p_4.x, p_4.y - c_11->cvRise_0, p_4.z) / make_float3 (c_11->cvBillowScale_0);
    int i_12 = int(0);
    float amp_2 = 0.60000002384185791f;
    float3  x_17 = _S103;
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
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_17);
        float norm_3 = norm_2 + amp_2;
        float3  x_18 = x_17 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_12 = i_12 + int(1);
        amp_2 = amp_3;
        x_17 = x_18;
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

static __device__ float convectionDensity_0(ConvectionInput_0 * c_12, float3  p_5)
{
    float _S104 = p_5.y;
    float above_1 = _S104 - c_12->cvBase_0;
    bool _S105;
    if(above_1 < 0.0f)
    {
        _S105 = true;
    }
    else
    {
        _S105 = above_1 > (c_12->cvDepth_0 + c_12->cvBillow_0);
    }
    if(_S105)
    {
        return 0.0f;
    }
    float2  q_2 = float2 {p_5.x, p_5.z} - c_12->cvDrift_0;
    float _S106 = convUpdraft_0(c_12, q_2);
    float _S107 = convTowerHeight_0(c_12, _S106);
    if(_S107 <= 0.0f)
    {
        return 0.0f;
    }
    float _S108 = convLift_0(c_12, above_1);
    float _S109 = _S107 - above_1;
    if((_S109 + _S108) <= 0.0f)
    {
        return 0.0f;
    }
    float inside_1;
    if((_S109 - _S108) >= 12.0f)
    {
        inside_1 = 12.0f;
    }
    else
    {
        float _S110 = convBillow_0(c_12, make_float3 (q_2.x, _S104, q_2.y));
        float inside_2 = _S109 + _S108 * _S110;
        if(inside_2 <= 0.0f)
        {
            return 0.0f;
        }
        inside_1 = inside_2;
    }
    return c_12->cvSigma_0 * (F32_sqrt((saturate_0(above_1 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1);
}

static __device__ float densityAt_0(Medium_0 * m_3, StructuredBuffer<float2 > disp_6, float3  p_6)
{
    float _S111 = p_6.y;
    bool _S112;
    if(_S111 < (m_3->slabBottom_0))
    {
        _S112 = true;
    }
    else
    {
        _S112 = _S111 > (m_3->slabTop_0);
    }
    if(_S112)
    {
        return 0.0f;
    }
    int _S113 = m_3->mode_0;
    if((m_3->mode_0) == int(0))
    {
        return m_3->density_0;
    }
    if(_S113 == int(2))
    {
        float _S114 = iceDensity_0(&m_3->gen_0, disp_6, p_6);
        return _S114;
    }
    if(_S113 == int(3))
    {
        float _S115 = convectionDensity_0(&m_3->conv_0, p_6);
        return _S115;
    }
    float3  d_5 = (p_6 - m_3->coreCentre_0) / make_float3 ((F32_max((m_3->coreRadius_0), (9.99999997475242708e-07f))));
    return m_3->density_0 + m_3->coreDensity_0 * (F32_exp((- dot_0(d_5, d_5))));
}

static __device__ float transmittance_0(Medium_0 * m_4, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_7, Rng_0 * rng_0, float3  p_7, float3  dir_0, int * steps_0)
{
    float t0_1;
    float t1_1;
    bool _S116 = slabRange_0(m_4, p_7, dir_0, &t0_1, &t1_1);
    if(!_S116)
    {
        return 1.0f;
    }
    float _S117 = (F32_max((t0_1), (0.0f)));
    t0_1 = _S117;
    Dda_0 _S118 = ddaInit_0(g_9, p_7, dir_0, _S117);
    Dda_0 dda_0 = _S118;
    float _S119 = m_4->majorant_0;
    float _S120 = gridBound_0(m_4, g_9, bounds_1, disp_7, (&dda_0)->cell_0, m_4->majorant_0);
    float localMaj_0 = _S120;
    int i_13 = int(0);
    float t_2 = _S117;
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
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S121 = dda_0;
        float _S122 = ddaExit_0(&_S121);
        float _S123 = (F32_min((_S122), (t1_1)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S123 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S124 = gridBound_0(m_4, g_9, bounds_1, disp_7, (&dda_0)->cell_0, _S119);
            localMaj_0 = _S124;
            t_2 = _S123;
            i_13 = i_13 + int(1);
            continue;
        }
        float _S125 = randFloat_0(rng_0);
        float t_3 = t_2 - (F32_log(((F32_max((1.0f - _S125), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_3 >= _S123)
        {
            if(_S123 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S126 = gridBound_0(m_4, g_9, bounds_1, disp_7, (&dda_0)->cell_0, _S119);
            localMaj_0 = _S126;
            t_2 = _S123;
            i_13 = i_13 + int(1);
            continue;
        }
        float _S127 = densityAt_0(m_4, disp_7, p_7 + dir_0 * make_float3 (t_3));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S127 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S128 = randFloat_0(rng_0);
            if(_S128 > 0.5f)
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
        i_13 = i_13 + int(1);
    }
    return tr_0;
}

extern "C" __global__ void transmittanceTrial(Medium_0 medium_0, MajorantGrid_0 grid_0, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > drift_0, float3  origin_1, float3  direction_0, RWStructuredBuffer<float> output_0, RWStructuredBuffer<int> outSteps_0, uint seed_1, int count_0)
{
    int i_14 = int((blockIdx * blockDim + threadIdx).x);
    if(i_14 >= count_0)
    {
        return;
    }
    uint s_2 = uint(i_14) * 747796405U + 2891336453U;
    uint s_3 = ((s_2 >> ((s_2 >> 28U) + 4U)) ^ s_2) * 277803737U;
    Rng_0 rng_1 = makeRng_0(((s_3 >> 22U) ^ s_3) ^ seed_1);
    int steps_1 = int(0);
    float * _S129 = (&(output_0)[i_14]);
    Medium_0 _S130 = medium_0;
    MajorantGrid_0 _S131 = grid_0;
    float _S132 = transmittance_0(&_S130, &_S131, bounds_2, drift_0, &rng_1, origin_1, direction_0, &steps_1);
    *_S129 = _S132;
    *(&(outSteps_0)[i_14]) = steps_1;
    return;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_5, MajorantGrid_0 * g_10, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > disp_8, Rng_0 * rng_2, float3  ro_2, float3  rd_2, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_2)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_2;
    float t1_2;
    bool _S133 = slabRange_0(m_5, ro_2, rd_2, &t0_2, &t1_2);
    if(!_S133)
    {
        return false;
    }
    float _S134 = (F32_min((t1_2), (tLimit_0)));
    t1_2 = _S134;
    if(!(_S134 > t0_2))
    {
        return false;
    }
    float _S135 = (F32_max((t0_2), (0.0f)));
    Dda_0 _S136 = ddaInit_0(g_10, ro_2, rd_2, _S135);
    Dda_0 dda_1 = _S136;
    float _S137 = m_5->majorant_0;
    float _S138 = gridBound_0(m_5, g_10, bounds_3, disp_8, (&dda_1)->cell_0, m_5->majorant_0);
    float localMaj_1 = _S138;
    int i_15 = int(0);
    float t_4 = _S135;
    for(;;)
    {
        if(i_15 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_2 = *steps_2 + int(1);
        Dda_0 _S139 = dda_1;
        float _S140 = ddaExit_0(&_S139);
        float _S141 = (F32_min((_S140), (t1_2)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S141 >= t1_2)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S142 = gridBound_0(m_5, g_10, bounds_3, disp_8, (&dda_1)->cell_0, _S137);
            localMaj_1 = _S142;
            t_4 = _S141;
            i_15 = i_15 + int(1);
            continue;
        }
        float _S143 = randFloat_0(rng_2);
        float t_5 = t_4 - (F32_log(((F32_max((1.0f - _S143), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_5 >= _S141)
        {
            if(_S141 >= t1_2)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S144 = gridBound_0(m_5, g_10, bounds_3, disp_8, (&dda_1)->cell_0, _S137);
            localMaj_1 = _S144;
            t_4 = _S141;
            i_15 = i_15 + int(1);
            continue;
        }
        float3  p_8 = ro_2 + rd_2 * make_float3 (t_5);
        float _S145 = randFloat_0(rng_2);
        float _S146 = densityAt_0(m_5, disp_8, p_8);
        if(_S145 < (_S146 / localMaj_1))
        {
            *scatterPoint_0 = p_8;
            *distance_0 = t_5;
            return true;
        }
        t_4 = t_5;
        i_15 = i_15 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_6, MajorantGrid_0 * g_11, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > disp_9, Rng_0 * rng_3, float3  ro_3, float3  rd_3, float3  * scatterPoint_1, float * distance_1, int * steps_3)
{
    bool _S147 = sampleFreeFlightUpTo_0(m_6, g_11, bounds_4, disp_9, rng_3, ro_3, rd_3, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_3);
    return _S147;
}

extern "C" __global__ void freeFlightTrial(Medium_0 medium_1, MajorantGrid_0 grid_1, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > drift_1, float3  origin_2, float3  direction_1, RWStructuredBuffer<float> outDistance_0, RWStructuredBuffer<int> outSteps_1, uint seed_2, int count_1)
{
    int i_16 = int((blockIdx * blockDim + threadIdx).x);
    if(i_16 >= count_1)
    {
        return;
    }
    uint s_4 = uint(i_16) * 747796405U + 2891336453U;
    uint s_5 = ((s_4 >> ((s_4 >> 28U) + 4U)) ^ s_4) * 277803737U;
    Rng_0 rng_4 = makeRng_0(((s_5 >> 22U) ^ s_5) ^ seed_2);
    int steps_4 = int(0);
    float * _S148 = (&(outDistance_0)[i_16]);
    Medium_0 _S149 = medium_1;
    MajorantGrid_0 _S150 = grid_1;
    float3  hit_0;
    float dist_0;
    bool _S151 = sampleFreeFlight_0(&_S149, &_S150, bounds_5, drift_1, &rng_4, origin_2, direction_1, &hit_0, &dist_0, &steps_4);
    float _S152;
    if(_S151)
    {
        _S152 = dist_0;
    }
    else
    {
        _S152 = -1.0f;
    }
    *_S148 = _S152;
    *(&(outSteps_1)[i_16]) = steps_4;
    return;
}

extern "C" __global__ void rngTrial(RWStructuredBuffer<float> output_1, uint seed_3, int count_2)
{
    int i_17 = int((blockIdx * blockDim + threadIdx).x);
    if(i_17 >= count_2)
    {
        return;
    }
    Rng_0 rng_5 = makeRng_0(seed_3 + uint(i_17));
    float * _S153 = (&(output_1)[i_17]);
    float _S154 = randFloat_0(&rng_5);
    *_S153 = _S154;
    return;
}

extern "C" __global__ void buildIceGrid(Medium_0 medium_2, StructuredBuffer<float2 > drift_2, MajorantGrid_0 grid_2, RWStructuredBuffer<float> outBounds_0, int cellCount_0)
{
    int i_18 = int((blockIdx * blockDim + threadIdx).x);
    if(i_18 >= cellCount_0)
    {
        return;
    }
    int _S155 = grid_2.dims_0.x;
    int cx_0 = i_18 % _S155;
    int _S156 = i_18 / _S155;
    int _S157 = grid_2.dims_0.y;
    int cy_0 = _S156 % _S157;
    int cz_0 = i_18 / (_S155 * _S157);
    float3  lo_5 = grid_2.origin_0 + make_float3 (float(cx_0), float(cy_0), float(cz_0)) * grid_2.cellExtent_0;
    float * _S158 = (&(outBounds_0)[i_18]);
    float3  _S159 = lo_5 + grid_2.cellExtent_0;
    GeneratorInput_0 _S160 = medium_2.gen_0;
    float _S161 = iceDensityBound_0(&_S160, drift_2, lo_5, _S159);
    *_S158 = _S161;
    return;
}

