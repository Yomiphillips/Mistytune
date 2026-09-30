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

static __device__ bool any_0(bool2  x_1)
{
    bool result_0 = false;
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
        if(result_0)
        {
            result_0 = true;
        }
        else
        {
            result_0 = (bool((_slang_vector_get_element(x_1, i_0))));
        }
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static __device__ float2  lerp_0(float2  x_2, float2  y_1, float2  s_0)
{
    return x_2 + (y_1 - x_2) * s_0;
}

static __device__ int clamp_0(int x_3, int minBound_0, int maxBound_0)
{
    return (I32_min(((I32_max((x_3), (minBound_0)))), (maxBound_0)));
}

static __device__ float dot_1(float2  x_4, float2  y_2)
{
    return x_4.x * y_2.x + x_4.y * y_2.y;
}

static __device__ float length_0(float2  x_5)
{
    return (F32_sqrt((dot_1(x_5, x_5))));
}

static __device__ float clamp_1(float x_6, float minBound_1, float maxBound_1)
{
    return (F32_min(((F32_max((x_6), (minBound_1)))), (maxBound_1)));
}

static __device__ float2  abs_0(float2  x_7)
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
        *_slang_vector_get_element_ptr(&result_1, i_1) = (F32_abs((_slang_vector_get_element(x_7, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static __device__ bool all_0(bool2  x_8)
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
            result_2 = (bool((_slang_vector_get_element(x_8, i_2))));
        }
        else
        {
            result_2 = false;
        }
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static __device__ float2  floor_0(float2  x_9)
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
        *_slang_vector_get_element_ptr(&result_3, i_3) = (F32_floor((_slang_vector_get_element(x_9, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static __device__ float lerp_1(float x_10, float y_3, float s_1)
{
    return x_10 + (y_3 - x_10) * s_1;
}

static __device__ float saturate_0(float x_11)
{
    return clamp_1(x_11, 0.0f, 1.0f);
}

static __device__ float smoothstep_0(float min_0, float max_0, float x_12)
{
    float _S1 = saturate_0((x_12 - min_0) / (max_0 - min_0));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static __device__ float3  floor_1(float3  x_13)
{
    float3  result_4;
    int i_4 = int(0);
    for(;;)
    {
        if(i_4 < int(3))
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

static __device__ float2  min_1(float2  x_14, float2  y_4)
{
    float2  result_5;
    int i_5 = int(0);
    for(;;)
    {
        if(i_5 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_5, i_5) = (F32_min((_slang_vector_get_element(x_14, i_5)), (_slang_vector_get_element(y_4, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
}

static __device__ float2  max_1(float2  x_15, float2  y_5)
{
    float2  result_6;
    int i_6 = int(0);
    for(;;)
    {
        if(i_6 < int(2))
        {
        }
        else
        {
            break;
        }
        *_slang_vector_get_element_ptr(&result_6, i_6) = (F32_max((_slang_vector_get_element(x_15, i_6)), (_slang_vector_get_element(y_5, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_6;
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

static __device__ bool clipAxis_0(float o_0, float d_0, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_0))) < 9.99999971718068537e-10f)
    {
        bool _S2;
        if(o_0 >= lo_0)
        {
            _S2 = o_0 <= hi_0;
        }
        else
        {
            _S2 = false;
        }
        return _S2;
    }
    float ta_0 = (lo_0 - o_0) / d_0;
    float tb_0 = (hi_0 - o_0) / d_0;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S3 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S3;
    return _S3 > (*t0_0);
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
    int cvHeroAlone_0;
    float2  cvHeroAt_0;
    float cvHeroRadius_0;
    float cvHeroTop_0;
    float3  cvHeroSeed_0;
    float cvHeroBillow_0;
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
    int clipOn_0;
    float2  clipLo_0;
    float2  clipHi_0;
    float2  fadeAt_0;
    float fadeRadius_0;
    float fadeWidth_0;
};

static __device__ bool slabRange_0(Medium_0 * m_0, float3  ro_0, float3  rd_0, float * t0_1, float * t1_1)
{
    *t0_1 = 0.0f;
    *t1_1 = 1.0e+09f;
    float _S4 = rd_0.y;
    bool _S5;
    if((F32_abs((_S4))) < 9.99999997475242708e-07f)
    {
        float _S6 = ro_0.y;
        if(_S6 < (m_0->slabBottom_0))
        {
            _S5 = true;
        }
        else
        {
            _S5 = _S6 > (m_0->slabTop_0);
        }
        if(_S5)
        {
            return false;
        }
    }
    else
    {
        float _S7 = ro_0.y;
        float ta_1 = (m_0->slabBottom_0 - _S7) / _S4;
        float tb_1 = (m_0->slabTop_0 - _S7) / _S4;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S8 = (m_0->clipOn_0) != int(0);
    float2  lo_1;
    if(_S8)
    {
        lo_1 = m_0->clipLo_0;
    }
    else
    {
        lo_1 = make_float2 (-1.0e+09f, -1.0e+09f);
    }
    float2  hi_1;
    if(_S8)
    {
        hi_1 = m_0->clipHi_0;
    }
    else
    {
        hi_1 = make_float2 (1.0e+09f, 1.0e+09f);
    }
    float _S9 = m_0->fadeRadius_0;
    if((m_0->fadeRadius_0) > 0.0f)
    {
        float2  _S10 = min_1(hi_1, m_0->fadeAt_0 + make_float2 (_S9));
        lo_1 = max_1(lo_1, m_0->fadeAt_0 - make_float2 (_S9));
        hi_1 = _S10;
    }
    bool _S11 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S11)
    {
        return false;
    }
    bool _S12 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S12)
    {
        return false;
    }
    float _S13 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S13;
    if(_S13 > (*t0_1))
    {
        _S5 = (*t1_1) > 0.0f;
    }
    else
    {
        _S5 = false;
    }
    return _S5;
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
    Dda_0 d_1;
    if((g_0->enabled_0) == int(0))
    {
        int3  _S14 = make_int3 (int(0), int(0), int(0));
        (&d_1)->cell_0 = _S14;
        (&d_1)->stepDir_0 = _S14;
        float3  _S15 = make_float3 (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_1)->tMax_0 = _S15;
        (&d_1)->tDelta_0 = _S15;
        return d_1;
    }
    float3  p_0 = ro_1 + rd_1 * make_float3 (t_0);
    float3  _S16 = floor_1((p_0 - g_0->origin_0) / g_0->cellExtent_0);
    int3  _S17 = make_int3 ((int)_S16.x, (int)_S16.y, (int)_S16.z);
    (&d_1)->cell_0 = _S17;
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
        int _S18 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            *_slang_vector_get_element_ptr(&(&d_1)->stepDir_0, a_0) = int(0);
            *_slang_vector_get_element_ptr(&(&d_1)->tMax_0, a_0) = 1.00000001504746622e+30f;
            *_slang_vector_get_element_ptr(&(&d_1)->tDelta_0, a_0) = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S19 = _slang_vector_get_element(rd_1, _S18) > 0.0f;
            int _S20;
            if(_S19)
            {
                _S20 = int(1);
            }
            else
            {
                _S20 = int(-1);
            }
            *_slang_vector_get_element_ptr(&(&d_1)->stepDir_0, a_0) = _S20;
            float _S21 = *_slang_vector_get_element_ptr(&g_0->origin_0, a_0);
            float _S22 = float(*_slang_vector_get_element_ptr(&(&d_1)->cell_0, a_0));
            float _S23;
            if(_S19)
            {
                _S23 = 1.0f;
            }
            else
            {
                _S23 = 0.0f;
            }
            *_slang_vector_get_element_ptr(&(&d_1)->tMax_0, a_0) = t_0 + (_S21 + (_S22 + _S23) * *_slang_vector_get_element_ptr(&g_0->cellExtent_0, a_0) - _slang_vector_get_element(p_0, a_0)) / _slang_vector_get_element(rd_1, _S18);
            *_slang_vector_get_element_ptr(&(&d_1)->tDelta_0, a_0) = (F32_abs((*_slang_vector_get_element_ptr(&g_0->cellExtent_0, a_0) / _slang_vector_get_element(rd_1, _S18))));
        }
        a_0 = a_0 + int(1);
    }
    return d_1;
}

static __device__ float convCeiling_0(ConvectionInput_0 * c_0)
{
    float _S24 = c_0->cvBillow_0;
    float field_0 = c_0->cvDepth_0 + c_0->cvBillow_0;
    float _S25 = c_0->cvHeroTop_0;
    float hero_0;
    if((c_0->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S25 + _S24 * c_0->cvHeroBillow_0;
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
    uint2  _S26 = v_0 * make_uint2 (1664525U) + make_uint2 (1013904223U);
    uint2  _S27 = _S26;
    *&((&_S27)->x) = *&((&_S27)->x) + _S26.y * 1664525U;
    *&((&_S27)->y) = *&((&_S27)->y) + _S27.x * 1664525U;
    uint2  _S28 = _S27 ^ (_S27 >> make_uint2 (16U));
    _S27 = _S28;
    *&((&_S27)->x) = *&((&_S27)->x) + _S28.y * 1664525U;
    *&((&_S27)->y) = *&((&_S27)->y) + _S27.x * 1664525U;
    uint2  _S29 = _S27 ^ (_S27 >> make_uint2 (16U));
    _S27 = _S29;
    return _S29;
}

static __device__ float2  hash22_0(int2  c_2, uint salt_0)
{
    uint2  h_0 = pcg2d_0(make_uint2 (uint(c_2.x), uint(c_2.y)) ^ make_uint2 (salt_0, salt_0 * 2654435761U));
    float2  _S30 = make_float2 ((float)h_0.x, (float)h_0.y);
    return _S30 * make_float2 (2.32830643653869629e-10f);
}

static __device__ float convLife_0(float u_0)
{
    float _S31 = 1.0f - u_0;
    return 6.75f * u_0 * _S31 * _S31;
}

static __device__ float convVigour_0(ConvectionInput_0 * c_3, int2  slot_0)
{
    float2  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_3->cvAge_0 + h_1.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_1.y);
}

static __device__ float2  convCellCentre_0(int2  slot_1)
{
    float2  _S32 = make_float2 ((float)slot_1.x, (float)slot_1.y);
    return _S32 + make_float2 (0.5f) + (hash22_0(slot_1, 1759714724U) - make_float2 (0.5f)) * make_float2 (0.69999998807907104f);
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

static __device__ void convSlotBound_0(ConvectionInput_0 * c_4, int2  slot_2, float2  a_1, float2  b_0, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S33 = convVigour_0(c_4, slot_2);
    if(_S33 <= 0.0f)
    {
        return;
    }
    float2  ctr_0 = convCellCentre_0(slot_2);
    float2  _S34 = a_1 - ctr_0;
    float2  nearGap_0 = max_1(max_1(_S34, ctr_0 - b_0), make_float2 (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    float2  farGap_0 = max_1(abs_0(_S34), abs_0(b_0 - ctr_0));
    float oHi_0 = _S33 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S33 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S33 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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

static __device__ float convUpdraftBound_0(ConvectionInput_0 * c_5, float2  q0_0, float2  q1_0)
{
    float2  a_2 = q0_0 / make_float2 (c_5->cvSpacing_0);
    float2  b_1 = q1_0 / make_float2 (c_5->cvSpacing_0);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    float2  _S35 = floor_0((a_2 + b_1) * make_float2 (0.5f));
    int2  _S36 = make_int2 ((int)_S35.x, (int)_S35.y);
    float2  _S37 = make_float2 ((float)_S36.x, (float)_S36.y);
    float2  highEdge_0 = _S37 + make_float2 (1.0f) + make_float2 (0.00009999999747379f);
    bool _S38;
    if(all_0(a_2 >= (_S37 - make_float2 (0.00009999999747379f))))
    {
        _S38 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S38 = false;
    }
    int j_0;
    int i_7;
    if(_S38)
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
            i_7 = int(-1);
            for(;;)
            {
                if(i_7 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_5, _S36 + make_int2 (i_7, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_7 = i_7 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    else
    {
        float2  _S39 = floor_0(a_2);
        int2  _S40 = make_int2 ((int)_S39.x, (int)_S39.y);
        int2  _S41 = make_int2 (int(1), int(1));
        int2  i0_0 = _S40 - _S41;
        float2  _S42 = floor_0(b_1);
        int2  _S43 = make_int2 ((int)_S42.x, (int)_S42.y);
        int2  _S44 = _S43 + _S41;
        int _S45 = i0_0.y;
        j_0 = _S45;
        for(;;)
        {
            if(j_0 <= (_S44.y))
            {
                _S38 = j_0 <= (_S45 + int(32));
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
            int _S46 = i0_0.x;
            i_7 = _S46;
            for(;;)
            {
                bool _S47;
                if(i_7 <= (_S44.x))
                {
                    _S47 = i_7 <= (_S46 + int(32));
                }
                else
                {
                    _S47 = false;
                }
                if(_S47)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_5, make_int2 (i_7, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_7 = i_7 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    return lerp_1((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_5->cvPolarity_0) + 0.00000999999974738f;
}

static __device__ float convTowerHeight_0(ConvectionInput_0 * c_6, float w_0)
{
    float cover_0 = clamp_1(c_6->cvCoverage_0, 0.0f, 1.0f);
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
    return c_6->cvDepth_0 * (F32_pow((u_1), (c_6->cvShape_0)));
}

static __device__ float convNeededUpdraft_0(ConvectionInput_0 * c_7, float above_1)
{
    float cover_1 = clamp_1(c_7->cvCoverage_0, 0.0f, 1.0f);
    bool _S48;
    if(cover_1 <= 0.0f)
    {
        _S48 = true;
    }
    else
    {
        _S48 = (c_7->cvDepth_0) <= 0.0f;
    }
    if(_S48)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_7->cvDepth_0), (1.0f / (F32_max((c_7->cvShape_0), (0.00100000004749745f))))));
}

static __device__ float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S49;
    if(vMin_0 <= 0.0f)
    {
        _S49 = true;
    }
    else
    {
        _S49 = hMin_0 <= 0.0f;
    }
    if(_S49)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static __device__ float convHeroReach_0(ConvectionInput_0 * c_8)
{
    return c_8->cvHeroRadius_0 + 1.5f * c_8->cvBillow_0 * c_8->cvHeroBillow_0 + 24.0f;
}

static __device__ float convHeroHeight_0(ConvectionInput_0 * c_9, float r_1)
{
    float _S50 = c_9->cvHeroTop_0;
    bool _S51;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        _S51 = true;
    }
    else
    {
        _S51 = r_1 >= (c_9->cvHeroRadius_0);
    }
    if(_S51)
    {
        return 0.0f;
    }
    return _S50 * (F32_pow((1.0f - r_1 * r_1 / (c_9->cvHeroRadius_0 * c_9->cvHeroRadius_0)), (c_9->cvShape_0)));
}

static __device__ float convHeroRadiusAt_0(ConvectionInput_0 * c_10, float above_2)
{
    float _S52 = c_10->cvHeroTop_0;
    bool _S53;
    if((c_10->cvHeroTop_0) <= 0.0f)
    {
        _S53 = true;
    }
    else
    {
        _S53 = above_2 >= _S52;
    }
    if(_S53)
    {
        return -1.0f;
    }
    return c_10->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S52), (1.0f / (F32_max((c_10->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static __device__ float convectionBound_0(ConvectionInput_0 * c_11, float3  lo_2, float3  hi_2)
{
    float low_0 = lo_2.y - c_11->cvBase_0;
    float high_0 = hi_2.y - c_11->cvBase_0;
    float _S54 = convCeiling_0(c_11);
    bool _S55;
    if(high_0 < 0.0f)
    {
        _S55 = true;
    }
    else
    {
        _S55 = low_0 > _S54;
    }
    if(_S55)
    {
        return 0.0f;
    }
    float _S56 = (F32_max((low_0), (0.0f)));
    float _S57 = (F32_min((high_0), (_S54)));
    float _S58 = convLift_0(c_11, _S57, 1.0f);
    float inside_0;
    if((c_11->cvHeroAlone_0) == int(0))
    {
        float _S59 = convUpdraftBound_0(c_11, float2 {lo_2.x, lo_2.z} - c_11->cvDrift_0, float2 {hi_2.x, hi_2.z} - c_11->cvDrift_0);
        float _S60 = convTowerHeight_0(c_11, _S59);
        float _S61 = convNeededUpdraft_0(c_11, _S56);
        if(_S59 < _S61)
        {
            inside_0 = _S58 - convDistanceFloor_0(_S56 - _S60, (_S61 - _S59) / (7.0f / c_11->cvSpacing_0));
        }
        else
        {
            inside_0 = (F32_max((_S60 - _S56), (0.0f))) + _S58;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    if((c_11->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_0(max_1(max_1(float2 {lo_2.x, lo_2.z} - c_11->cvHeroAt_0, c_11->cvHeroAt_0 - float2 {hi_2.x, hi_2.z}), make_float2 (0.0f, 0.0f)));
        float _S62 = convHeroReach_0(c_11);
        if(rMin_0 < _S62)
        {
            float _S63 = convHeroHeight_0(c_11, rMin_0);
            float _S64 = convHeroRadiusAt_0(c_11, _S56);
            float _S65 = convLift_0(c_11, _S57, c_11->cvHeroBillow_0);
            bool _S66 = _S64 < 0.0f;
            if(_S66)
            {
                _S55 = true;
            }
            else
            {
                _S55 = rMin_0 >= _S64;
            }
            float heroIn_0;
            if(_S55)
            {
                if(_S66)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S64;
                }
                heroIn_0 = _S65 - convDistanceFloor_0(_S56 - _S63, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S63 - _S56), (0.0f))) + _S65;
            }
            inside_0 = (F32_max((inside_0), (heroIn_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return 0.0f;
    }
    return c_11->cvSigma_0 * (F32_sqrt((saturate_0(_S57 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1) * 1.00001001358032227f;
}

static __device__ float2  driftAt_0(GeneratorInput_0 * g_1, StructuredBuffer<float2 > disp_0, float depth_0)
{
    float x_16 = clamp_1(depth_0 / g_1->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int i_8 = clamp_0(int((F32_floor((x_16)))), int(0), int(31));
    float2  _S67 = __ldg((&(disp_0)[i_8]));
    float2  _S68 = __ldg((&(disp_0)[i_8 + int(1)]));
    return lerp_0(_S67, _S68, make_float2 (x_16 - float(i_8)));
}

static __device__ void driftRange_0(GeneratorInput_0 * g_2, StructuredBuffer<float2 > disp_1, float d0_0, float d1_0, float2  * lo_3, float2  * hi_3)
{
    float2  _S69 = driftAt_0(g_2, disp_1, d0_0);
    *lo_3 = _S69;
    *hi_3 = _S69;
    float2  _S70 = driftAt_0(g_2, disp_1, d1_0);
    *lo_3 = min_1(*lo_3, _S70);
    *hi_3 = max_1(*hi_3, _S70);
    int _S71 = clamp_0(int((F32_ceil((clamp_1(d1_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int k_1 = clamp_0(int((F32_floor((clamp_1(d0_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_1 <= _S71)
        {
        }
        else
        {
            break;
        }
        float2  _S72 = *lo_3;
        float2  _S73 = __ldg((&(disp_1)[k_1]));
        *lo_3 = min_1(_S72, _S73);
        float2  _S74 = *hi_3;
        float2  _S75 = __ldg((&(disp_1)[k_1]));
        *hi_3 = max_1(_S74, _S75);
        k_1 = k_1 + int(1);
    }
    return;
}

static __device__ float cellFieldBound_0(GeneratorInput_0 * g_3, float2  q0_1, float2  q1_1)
{
    float spacing_0 = g_3->cellSize_0 * 2.20000004768371582f;
    float2  a_3 = (q0_1 - g_3->cellDrift_0) / make_float2 (spacing_0);
    float2  b_2 = (q1_1 - g_3->cellDrift_0) / make_float2 (spacing_0);
    float2  _S76 = floor_0(a_3);
    int2  _S77 = make_int2 ((int)_S76.x, (int)_S76.y);
    int2  _S78 = make_int2 (int(1), int(1));
    int2  i0_1 = _S77 - _S78;
    float2  _S79 = floor_0(b_2);
    int2  _S80 = make_int2 ((int)_S79.x, (int)_S79.y);
    int2  _S81 = _S80 + _S78;
    int _S82 = i0_1.y;
    int j_1 = _S82;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S83;
        if(j_1 <= (_S81.y))
        {
            _S83 = j_1 <= (_S82 + int(32));
        }
        else
        {
            _S83 = false;
        }
        if(_S83)
        {
        }
        else
        {
            break;
        }
        int _S84 = i0_1.x;
        int i_9 = _S84;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S85;
            if(i_9 <= (_S81.x))
            {
                _S85 = i_9 <= (_S84 + int(32));
            }
            else
            {
                _S85 = false;
            }
            if(_S85)
            {
            }
            else
            {
                break;
            }
            int2  o_1 = make_int2 (i_9, j_1);
            if((hash22_0(o_1, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_9 = i_9 + int(1);
                continue;
            }
            float2  _S86 = make_float2 ((float)o_1.x, (float)o_1.y);
            float2  c_12 = _S86 + make_float2 (0.5f) + (hash22_0(o_1, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f);
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_1(max_1(a_3 - c_12, c_12 - b_2), make_float2 (0.0f, 0.0f))) * 2.20000004768371582f);
            i_9 = i_9 + int(1);
        }
        j_1 = j_1 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static __device__ float iceDensityBound_0(GeneratorInput_0 * g_4, StructuredBuffer<float2 > disp_2, float3  lo_4, float3  hi_4)
{
    float d0_1 = g_4->cellAltitude_0 - hi_4.y;
    float d1_1 = g_4->cellAltitude_0 - lo_4.y;
    bool _S87;
    if(d1_1 < 0.0f)
    {
        _S87 = true;
    }
    else
    {
        _S87 = d0_1 > (g_4->streakLength_0);
    }
    if(_S87)
    {
        return 0.0f;
    }
    float _S88 = g_4->streakLength_0;
    float d0_2 = clamp_1(d0_1, 0.0f, g_4->streakLength_0);
    float d1_2 = clamp_1(d1_1, 0.0f, g_4->streakLength_0);
    float subl_0 = (F32_exp((- g_4->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_4->detailAmount_0 * 1.5f * 1.79999995231628418f;
    float2  driftLo_0;
    float2  driftHi_0;
    driftRange_0(g_4, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S89 = cellFieldBound_0(g_4, make_float2 (lo_4.x, lo_4.z) - driftHi_0, make_float2 (hi_4.x, hi_4.z) - driftLo_0);
    return (F32_max((_S89 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((_S88), (1.0f)));
}

static __device__ float mediumBound_0(Medium_0 * m_1, StructuredBuffer<float2 > disp_3, float3  lo_5, float3  hi_5)
{
    int _S90 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S91 = convectionBound_0(&m_1->conv_0, lo_5, hi_5);
        return _S91;
    }
    if(_S90 == int(2))
    {
        float _S92 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_5, hi_5);
        return _S92;
    }
    return m_1->majorant_0;
}

static __device__ float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_0, StructuredBuffer<float2 > disp_4, int3  c_13, float fallback_0)
{
    int _S93 = g_5->enabled_0;
    if((g_5->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S93 == int(2))
    {
        float3  _S94 = make_float3 ((float)c_13.x, (float)c_13.y, (float)c_13.z);
        float3  lo_6 = g_5->origin_0 + _S94 * g_5->cellExtent_0;
        float _S95 = mediumBound_0(m_2, disp_4, lo_6, lo_6 + g_5->cellExtent_0);
        return _S95;
    }
    int _S96 = c_13.x;
    bool _S97;
    if(_S96 < int(0))
    {
        _S97 = true;
    }
    else
    {
        _S97 = (c_13.y) < int(0);
    }
    if(_S97)
    {
        _S97 = true;
    }
    else
    {
        _S97 = (c_13.z) < int(0);
    }
    if(_S97)
    {
        _S97 = true;
    }
    else
    {
        _S97 = _S96 >= (g_5->dims_0.x);
    }
    if(_S97)
    {
        _S97 = true;
    }
    else
    {
        _S97 = (c_13.y) >= (g_5->dims_0.y);
    }
    if(_S97)
    {
        _S97 = true;
    }
    else
    {
        _S97 = (c_13.z) >= (g_5->dims_0.z);
    }
    if(_S97)
    {
        return fallback_0;
    }
    float _S98 = __ldg((&(bounds_0)[(c_13.z * g_5->dims_0.y + c_13.y) * g_5->dims_0.x + _S96]));
    return _S98;
}

static __device__ float ddaExit_0(Dda_0 * d_2)
{
    return (F32_min((d_2->tMax_0.x), ((F32_min((d_2->tMax_0.y), (d_2->tMax_0.z))))));
}

static __device__ void ddaAdvance_0(Dda_0 * d_3)
{
    bool _S99;
    if((d_3->tMax_0.x) <= (d_3->tMax_0.y))
    {
        _S99 = (d_3->tMax_0.x) <= (d_3->tMax_0.z);
    }
    else
    {
        _S99 = false;
    }
    if(_S99)
    {
        *&((&d_3->cell_0)->x) = *&((&d_3->cell_0)->x) + d_3->stepDir_0.x;
        *&((&d_3->tMax_0)->x) = *&((&d_3->tMax_0)->x) + d_3->tDelta_0.x;
    }
    else
    {
        if((d_3->tMax_0.y) <= (d_3->tMax_0.z))
        {
            *&((&d_3->cell_0)->y) = *&((&d_3->cell_0)->y) + d_3->stepDir_0.y;
            *&((&d_3->tMax_0)->y) = *&((&d_3->tMax_0)->y) + d_3->tDelta_0.y;
        }
        else
        {
            *&((&d_3->cell_0)->z) = *&((&d_3->cell_0)->z) + d_3->stepDir_0.z;
            *&((&d_3->tMax_0)->z) = *&((&d_3->tMax_0)->z) + d_3->tDelta_0.z;
        }
    }
    return;
}

static __device__ float randFloat_0(Rng_0 * r_2)
{
    uint _S100 = r_2->state_0 * 747796405U + 2891336453U;
    r_2->state_0 = _S100;
    uint word_0 = ((_S100 >> ((_S100 >> 28U) + 4U)) ^ _S100) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static __device__ float cellField_0(GeneratorInput_0 * g_6, float2  q_0)
{
    float2  gq_0 = (q_0 - g_6->cellDrift_0) / make_float2 (g_6->cellSize_0 * 2.20000004768371582f);
    float2  gf_0 = floor_0(gq_0);
    int2  _S101 = make_int2 ((int)gf_0.x, (int)gf_0.y);
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
        int i_10 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_10 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  o_2 = _S101 + make_int2 (i_10, j_2);
            if((hash22_0(o_2, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_10 = i_10 + int(1);
                continue;
            }
            float2  _S102 = make_float2 ((float)o_2.x, (float)o_2.y);
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(gq_0 - (_S102 + make_float2 (0.5f) + (hash22_0(o_2, 0U) - make_float2 (0.5f)) * make_float2 (0.80000001192092896f))) * 2.20000004768371582f);
            i_10 = i_10 + int(1);
        }
        j_2 = j_2 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_6->cellStrength_0;
}

static __device__ uint3  pcg3d_0(uint3  v_1)
{
    uint3  _S103 = v_1 * make_uint3 (1664525U) + make_uint3 (1013904223U);
    uint3  _S104 = _S103;
    *&((&_S104)->x) = *&((&_S104)->x) + _S103.y * _S103.z;
    *&((&_S104)->y) = *&((&_S104)->y) + _S104.z * _S104.x;
    *&((&_S104)->z) = *&((&_S104)->z) + _S104.x * _S104.y;
    uint3  _S105 = _S104 ^ (_S104 >> make_uint3 (16U));
    _S104 = _S105;
    *&((&_S104)->x) = *&((&_S104)->x) + _S105.y * _S105.z;
    *&((&_S104)->y) = *&((&_S104)->y) + _S104.z * _S104.x;
    *&((&_S104)->z) = *&((&_S104)->z) + _S104.x * _S104.y;
    return _S104;
}

static __device__ float3  hash33_0(int3  c_14)
{
    uint3  h_2 = pcg3d_0(make_uint3 (uint(c_14.x), uint(c_14.y), uint(c_14.z)));
    float3  _S106 = make_float3 ((float)h_2.x, (float)h_2.y, (float)h_2.z);
    return _S106 * make_float3 (4.65661287307739258e-10f) - make_float3 (1.0f);
}

static __device__ float gradientNoise_0(float3  p_1)
{
    float3  fi_0 = floor_1(p_1);
    int3  _S107 = make_int3 ((int)fi_0.x, (int)fi_0.y, (int)fi_0.z);
    float3  f_0 = p_1 - fi_0;
    float3  u_2 = f_0 * f_0 * (make_float3 (3.0f) - make_float3 (2.0f) * f_0);
    float _S108 = u_2.x;
    float _S109 = u_2.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S107), f_0), dot_0(hash33_0(_S107 + make_int3 (int(1), int(0), int(0))), f_0 - make_float3 (1.0f, 0.0f, 0.0f)), _S108), lerp_1(dot_0(hash33_0(_S107 + make_int3 (int(0), int(1), int(0))), f_0 - make_float3 (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S107 + make_int3 (int(1), int(1), int(0))), f_0 - make_float3 (1.0f, 1.0f, 0.0f)), _S108), _S109), lerp_1(lerp_1(dot_0(hash33_0(_S107 + make_int3 (int(0), int(0), int(1))), f_0 - make_float3 (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S107 + make_int3 (int(1), int(0), int(1))), f_0 - make_float3 (1.0f, 0.0f, 1.0f)), _S108), lerp_1(dot_0(hash33_0(_S107 + make_int3 (int(0), int(1), int(1))), f_0 - make_float3 (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S107 + make_int3 (int(1), int(1), int(1))), f_0 - make_float3 (1.0f, 1.0f, 1.0f)), _S108), _S109), u_2.z);
}

static __device__ float fbm_0(float3  p_2, int octaves_1)
{
    int i_11 = int(0);
    float amp_0 = 0.5f;
    float3  _S110 = p_2;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_11 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_11 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S110);
        float norm_1 = norm_0 + amp_0;
        float3  _S111 = _S110 * make_float3 (2.01999998092651367f);
        float amp_1 = amp_0 * 0.5f;
        i_11 = i_11 + int(1);
        amp_0 = amp_1;
        _S110 = _S111;
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
    bool _S112;
    if(depth_1 < 0.0f)
    {
        _S112 = true;
    }
    else
    {
        _S112 = depth_1 > (g_7->streakLength_0);
    }
    if(_S112)
    {
        return 0.0f;
    }
    float2  _S113 = float2 {p_3.x, p_3.z};
    float2  _S114 = driftAt_0(g_7, disp_5, depth_1);
    float2  source_0 = _S113 - _S114;
    float _S115 = cellField_0(g_7, source_0);
    if(_S115 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S115 * (F32_exp((- g_7->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, depth_1)) * (F32_max((1.0f + g_7->detailAmount_0 * fbm_0(make_float3 ((source_0 / make_float2 (g_7->detailScale_0)).x, (source_0 / make_float2 (g_7->detailScale_0)).y, depth_1 / (F32_max((g_7->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_7->timeSeconds_0 * 0.00999999977648258f), g_7->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((g_7->streakLength_0), (1.0f)));
}

static __device__ float convUpdraftGrad_0(ConvectionInput_0 * c_15, float2  q_1, float2  * grad_0)
{
    float2  goTop_0;
    float _S116 = c_15->cvSpacing_0;
    float2  g_8 = q_1 / make_float2 (c_15->cvSpacing_0);
    float2  _S117 = floor_0(g_8);
    int2  _S118 = make_int2 ((int)_S117.x, (int)_S117.y);
    float2  _S119 = make_float2 (0.0f, 0.0f);
    float oTop_0 = 0.0f;
    float2  goTop_1 = _S119;
    float oNext_0 = 0.0f;
    float kTop_0 = 0.0f;
    float2  gkTop_0 = _S119;
    float kNext_0 = 0.0f;
    float2  goNext_0 = _S119;
    float2  gkNext_0 = _S119;
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
        goTop_0 = goTop_1;
        float oNext_1 = oNext_0;
        float kTop_1 = kTop_0;
        float2  gkTop_1 = gkTop_0;
        float kNext_1 = kNext_0;
        float2  goNext_1 = goNext_0;
        float2  gkNext_1 = gkNext_0;
        int i_12 = int(-1);
        for(;;)
        {
            if(i_12 <= int(1))
            {
            }
            else
            {
                break;
            }
            int2  slot_3 = _S118 + make_int2 (i_12, j_3);
            float _S120 = convVigour_0(c_15, slot_3);
            if(_S120 <= 0.0f)
            {
                i_12 = i_12 + int(1);
                continue;
            }
            float2  d_4 = g_8 - convCellCentre_0(slot_3);
            float d2_1 = dot_1(d_4, d_4);
            float ko_0 = _S120 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S120 * convBump_0(d2_1, 1.04999995231628418f);
            float2  gko_0;
            if(d2_1 < 0.5625f)
            {
                gko_0 = d_4 * make_float2 (-4.0f * _S120 * (1.0f - d2_1 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S119;
            }
            float2  gkk_0;
            if(d2_1 < 1.10249984264373779f)
            {
                gkk_0 = d_4 * make_float2 (-4.0f * _S120 * (1.0f - d2_1 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S119;
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
                float _S121 = oTop_2;
                float2  _S122 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S121;
                goNext_2 = _S122;
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
                float _S123 = kTop_2;
                float2  _S124 = gkTop_2;
                kTop_2 = kTop_1;
                gkTop_2 = gkTop_1;
                kNext_2 = _S123;
                gkNext_2 = _S124;
            }
            oTop_1 = oTop_2;
            goTop_0 = goTop_2;
            oNext_1 = oNext_2;
            kTop_1 = kTop_2;
            gkTop_1 = gkTop_2;
            kNext_1 = kNext_2;
            goNext_1 = goNext_2;
            gkNext_1 = gkNext_2;
            i_12 = i_12 + int(1);
        }
        int j_4 = j_3 + int(1);
        oTop_0 = oTop_1;
        goTop_1 = goTop_0;
        oNext_0 = oNext_1;
        kTop_0 = kTop_1;
        gkTop_0 = gkTop_1;
        kNext_0 = kNext_1;
        goNext_0 = goNext_1;
        gkNext_0 = gkNext_1;
        j_3 = j_4;
    }
    float openRaw_0 = oNext_0 / 0.31000000238418579f;
    float _S125 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_0 - kNext_0;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / make_float2 (0.31000000238418579f);
    }
    else
    {
        goTop_0 = _S119;
    }
    float _S126 = c_15->cvPolarity_0;
    *grad_0 = lerp_0(goTop_0, gkTop_0 - gkNext_0, make_float2 (c_15->cvPolarity_0)) / make_float2 (_S116);
    return lerp_1(_S125, closedField_0, _S126);
}

static __device__ float convSurfaceDistance_0(float v_2, float delta_0, float slope_0)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_0 * slope_0 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_5 = num_0 / den_0;
    float _S127;
    if(v_2 >= 0.0f)
    {
        _S127 = d_5;
    }
    else
    {
        _S127 = - d_5;
    }
    return _S127;
}

static __device__ float3  convTwist_0(float3  x_17)
{
    float _S128 = x_17.x;
    float _S129 = x_17.y;
    float _S130 = x_17.z;
    return make_float3 (0.0f * _S128 + 0.80000001192092896f * _S129 + 0.60000002384185791f * _S130, -0.80000001192092896f * _S128 + 0.36000001430511475f * _S129 - 0.47999998927116394f * _S130, -0.60000002384185791f * _S128 - 0.47999998927116394f * _S129 + 0.63999998569488525f * _S130);
}

static __device__ float convPuffs_0(float3  x_18)
{
    float3  fl_0 = floor_1(x_18);
    int3  _S131 = make_int3 ((int)fl_0.x, (int)fl_0.y, (int)fl_0.z);
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
    int3  _S132 = make_int3 (dz_0, dy_0, dx_0);
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
                int3  off_0 = _S132 + make_int3 (dx_0, dy_0, dz_0);
                float3  _S133 = make_float3 ((float)off_0.x, (float)off_0.y, (float)off_0.z);
                float3  d_6 = _S133 + make_float3 (0.5f) + make_float3 (0.25f) * hash33_0(_S131 + off_0) - f_1;
                float _S134 = (F32_min((nearest_1), (dot_0(d_6, d_6))));
                int dx_1 = dx_0 + int(1);
                nearest_1 = _S134;
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

static __device__ float convBillow_0(ConvectionInput_0 * c_16, float3  p_4, float scale_0)
{
    float3  _S135 = make_float3 (p_4.x, p_4.y - c_16->cvRise_0, p_4.z) / make_float3 (scale_0);
    int i_13 = int(0);
    float3  x_19 = _S135;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_13 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_13 >= (c_16->cvOctaves_0))
        {
            break;
        }
        float3  x_20 = convTwist_0(x_19);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_20);
        float norm_3 = norm_2 + amp_2;
        float3  x_21 = x_20 * make_float3 (2.17000007629394531f);
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_13 = i_13 + int(1);
        x_19 = x_21;
        amp_2 = amp_3;
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

static __device__ float convInside_0(ConvectionInput_0 * c_17, float d_7, float lift_0, float3  x_22, float scale_1)
{
    float _S136 = d_7 + lift_0;
    if(_S136 <= 0.0f)
    {
        return _S136;
    }
    if((d_7 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S137 = convBillow_0(c_17, x_22, scale_1);
    return d_7 + lift_0 * _S137;
}

static __device__ float convHeroInside_0(ConvectionInput_0 * c_18, float3  p_5, float above_3)
{
    float2  rel_0 = float2 {p_5.x, p_5.z} - c_18->cvHeroAt_0;
    float r_3 = length_0(rel_0);
    float _S138 = convHeroReach_0(c_18);
    if(r_3 >= _S138)
    {
        return -1.00000001504746622e+30f;
    }
    float _S139 = convHeroHeight_0(c_18, r_3);
    float v_3 = _S139 - above_3;
    float _S140 = convHeroRadiusAt_0(c_18, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_8;
    if(_S140 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_8 = v_3;
    }
    else
    {
        float h_3 = _S140 - r_3;
        float d_9 = convSurfaceDistance_0(v_3, h_3, 1.0f);
        if((F32_abs((v_3))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_9 * (d_9 / v_3);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_3))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_9 * (d_9 / h_3);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S141 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S141;
        d_8 = d_9;
    }
    float2  radial_0;
    if(r_3 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / make_float2 (r_3);
    }
    else
    {
        radial_0 = make_float2 (0.0f, 0.0f);
    }
    float2  at_0 = rel_0 + radial_0 * make_float2 (shiftOut_0);
    float3  x_23 = make_float3 (at_0.x, p_5.y + shiftUp_0, at_0.y) + c_18->cvHeroSeed_0;
    float _S142 = c_18->cvHeroBillow_0;
    float _S143 = convLift_0(c_18, above_3, c_18->cvHeroBillow_0);
    float _S144 = convInside_0(c_18, d_8, _S143, x_23, c_18->cvBillowScale_0 * _S142);
    return _S144;
}

static __device__ float convectionDensity_0(ConvectionInput_0 * c_19, float3  p_6)
{
    float _S145 = p_6.y;
    float above_4 = _S145 - c_19->cvBase_0;
    bool _S146;
    if(above_4 < 0.0f)
    {
        _S146 = true;
    }
    else
    {
        float _S147 = convCeiling_0(c_19);
        _S146 = above_4 > _S147;
    }
    if(_S146)
    {
        return 0.0f;
    }
    float _S148 = convLift_0(c_19, above_4, 1.0f);
    float inside_2;
    if((c_19->cvHeroAlone_0) == int(0))
    {
        float2  q_2 = float2 {p_6.x, p_6.z} - c_19->cvDrift_0;
        float2  slope_1;
        float _S149 = convUpdraftGrad_0(c_19, q_2, &slope_1);
        float _S150 = convTowerHeight_0(c_19, _S149);
        float v_4 = _S150 - above_4;
        float _S151 = convNeededUpdraft_0(c_19, above_4);
        float delta_1 = _S149 - _S151;
        float d_10 = convSurfaceDistance_0(v_4, delta_1, length_0(slope_1));
        if((d_10 + _S148) > 0.0f)
        {
            if((F32_abs((v_4))) > 9.99999997475242708e-07f)
            {
                inside_2 = d_10 * (d_10 / v_4);
            }
            else
            {
                inside_2 = 0.0f;
            }
            float2  shiftAcross_0;
            if((F32_abs((delta_1))) > 9.999999960041972e-13f)
            {
                shiftAcross_0 = slope_1 * make_float2 (- d_10 * (d_10 / delta_1));
            }
            else
            {
                shiftAcross_0 = make_float2 (0.0f, 0.0f);
            }
            float _S152 = convInside_0(c_19, d_10, _S148, make_float3 (q_2.x + shiftAcross_0.x, _S145 + inside_2, q_2.y + shiftAcross_0.y), c_19->cvBillowScale_0);
            inside_2 = _S152;
        }
        else
        {
            inside_2 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        inside_2 = -1.00000001504746622e+30f;
    }
    if((c_19->cvHeroTop_0) > 0.0f)
    {
        _S146 = inside_2 < 12.0f;
    }
    else
    {
        _S146 = false;
    }
    if(_S146)
    {
        float _S153 = convHeroInside_0(c_19, p_6, above_4);
        inside_2 = (F32_max((inside_2), (_S153)));
    }
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_19->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2);
}

static __device__ float densityAt_0(Medium_0 * m_3, StructuredBuffer<float2 > disp_6, float3  p_7)
{
    float _S154 = p_7.y;
    bool _S155;
    if(_S154 < (m_3->slabBottom_0))
    {
        _S155 = true;
    }
    else
    {
        _S155 = _S154 > (m_3->slabTop_0);
    }
    if(_S155)
    {
        return 0.0f;
    }
    if((m_3->clipOn_0) != int(0))
    {
        float2  _S156 = float2 {p_7.x, p_7.z};
        if(any_0(_S156 < (m_3->clipLo_0)))
        {
            _S155 = true;
        }
        else
        {
            _S155 = any_0(_S156 > (m_3->clipHi_0));
        }
    }
    else
    {
        _S155 = false;
    }
    if(_S155)
    {
        return 0.0f;
    }
    float _S157 = m_3->fadeRadius_0;
    float fade_0;
    if((m_3->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S157 - length_0(float2 {p_7.x, p_7.z} - m_3->fadeAt_0)) / (F32_max((m_3->fadeWidth_0), (1.0f))));
        if(fade_1 <= 0.0f)
        {
            return 0.0f;
        }
        fade_0 = fade_1;
    }
    else
    {
        fade_0 = 1.0f;
    }
    int _S158 = m_3->mode_0;
    if((m_3->mode_0) == int(0))
    {
        return m_3->density_0 * fade_0;
    }
    if(_S158 == int(2))
    {
        float _S159 = iceDensity_0(&m_3->gen_0, disp_6, p_7);
        return _S159 * fade_0;
    }
    if(_S158 == int(3))
    {
        float _S160 = convectionDensity_0(&m_3->conv_0, p_7);
        return _S160 * fade_0;
    }
    float3  d_11 = (p_7 - m_3->coreCentre_0) / make_float3 ((F32_max((m_3->coreRadius_0), (9.99999997475242708e-07f))));
    return (m_3->density_0 + m_3->coreDensity_0 * (F32_exp((- dot_0(d_11, d_11))))) * fade_0;
}

static __device__ float transmittance_0(Medium_0 * m_4, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_1, StructuredBuffer<float2 > disp_7, Rng_0 * rng_0, float3  p_8, float3  dir_0, int * steps_0)
{
    float t0_2;
    float t1_2;
    bool _S161 = slabRange_0(m_4, p_8, dir_0, &t0_2, &t1_2);
    if(!_S161)
    {
        return 1.0f;
    }
    float _S162 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S162;
    Dda_0 _S163 = ddaInit_0(g_9, p_8, dir_0, _S162);
    Dda_0 dda_0 = _S163;
    float _S164 = m_4->majorant_0;
    float _S165 = gridBound_0(m_4, g_9, bounds_1, disp_7, (&dda_0)->cell_0, m_4->majorant_0);
    float localMaj_0 = _S165;
    int i_14 = int(0);
    float t_2 = _S162;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_14 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S166 = dda_0;
        float _S167 = ddaExit_0(&_S166);
        float _S168 = (F32_min((_S167), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S168 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S169 = gridBound_0(m_4, g_9, bounds_1, disp_7, (&dda_0)->cell_0, _S164);
            localMaj_0 = _S169;
            t_2 = _S168;
            i_14 = i_14 + int(1);
            continue;
        }
        float _S170 = randFloat_0(rng_0);
        float t_3 = t_2 - (F32_log(((F32_max((1.0f - _S170), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_3 >= _S168)
        {
            if(_S168 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S171 = gridBound_0(m_4, g_9, bounds_1, disp_7, (&dda_0)->cell_0, _S164);
            localMaj_0 = _S171;
            t_2 = _S168;
            i_14 = i_14 + int(1);
            continue;
        }
        float _S172 = densityAt_0(m_4, disp_7, p_8 + dir_0 * make_float3 (t_3));
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S172 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S173 = randFloat_0(rng_0);
            if(_S173 > 0.5f)
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
        i_14 = i_14 + int(1);
    }
    return tr_0;
}

extern "C" __global__ void transmittanceTrial(Medium_0 medium_0, MajorantGrid_0 grid_0, StructuredBuffer<float> bounds_2, StructuredBuffer<float2 > drift_0, float3  origin_1, float3  direction_0, RWStructuredBuffer<float> output_0, RWStructuredBuffer<int> outSteps_0, uint seed_1, int count_0)
{
    int i_15 = int((blockIdx * blockDim + threadIdx).x);
    if(i_15 >= count_0)
    {
        return;
    }
    uint s_2 = uint(i_15) * 747796405U + 2891336453U;
    uint s_3 = ((s_2 >> ((s_2 >> 28U) + 4U)) ^ s_2) * 277803737U;
    Rng_0 rng_1 = makeRng_0(((s_3 >> 22U) ^ s_3) ^ seed_1);
    int steps_1 = int(0);
    float * _S174 = (&(output_0)[i_15]);
    Medium_0 _S175 = medium_0;
    MajorantGrid_0 _S176 = grid_0;
    float _S177 = transmittance_0(&_S175, &_S176, bounds_2, drift_0, &rng_1, origin_1, direction_0, &steps_1);
    *_S174 = _S177;
    *(&(outSteps_0)[i_15]) = steps_1;
    return;
}

static __device__ bool sampleFreeFlightUpTo_0(Medium_0 * m_5, MajorantGrid_0 * g_10, StructuredBuffer<float> bounds_3, StructuredBuffer<float2 > disp_8, Rng_0 * rng_2, float3  ro_2, float3  rd_2, float tLimit_0, float3  * scatterPoint_0, float * distance_0, int * steps_2)
{
    *scatterPoint_0 = make_float3 (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S178 = slabRange_0(m_5, ro_2, rd_2, &t0_3, &t1_3);
    if(!_S178)
    {
        return false;
    }
    float _S179 = (F32_min((t1_3), (tLimit_0)));
    t1_3 = _S179;
    if(!(_S179 > t0_3))
    {
        return false;
    }
    float _S180 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S181 = ddaInit_0(g_10, ro_2, rd_2, _S180);
    Dda_0 dda_1 = _S181;
    float _S182 = m_5->majorant_0;
    float _S183 = gridBound_0(m_5, g_10, bounds_3, disp_8, (&dda_1)->cell_0, m_5->majorant_0);
    float localMaj_1 = _S183;
    int i_16 = int(0);
    float t_4 = _S180;
    for(;;)
    {
        if(i_16 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_2 = *steps_2 + int(1);
        Dda_0 _S184 = dda_1;
        float _S185 = ddaExit_0(&_S184);
        float _S186 = (F32_min((_S185), (t1_3)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S186 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S187 = gridBound_0(m_5, g_10, bounds_3, disp_8, (&dda_1)->cell_0, _S182);
            localMaj_1 = _S187;
            t_4 = _S186;
            i_16 = i_16 + int(1);
            continue;
        }
        float _S188 = randFloat_0(rng_2);
        float t_5 = t_4 - (F32_log(((F32_max((1.0f - _S188), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_5 >= _S186)
        {
            if(_S186 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            float _S189 = gridBound_0(m_5, g_10, bounds_3, disp_8, (&dda_1)->cell_0, _S182);
            localMaj_1 = _S189;
            t_4 = _S186;
            i_16 = i_16 + int(1);
            continue;
        }
        float3  p_9 = ro_2 + rd_2 * make_float3 (t_5);
        float _S190 = randFloat_0(rng_2);
        float _S191 = densityAt_0(m_5, disp_8, p_9);
        if(_S190 < (_S191 / localMaj_1))
        {
            *scatterPoint_0 = p_9;
            *distance_0 = t_5;
            return true;
        }
        t_4 = t_5;
        i_16 = i_16 + int(1);
    }
    return false;
}

static __device__ bool sampleFreeFlight_0(Medium_0 * m_6, MajorantGrid_0 * g_11, StructuredBuffer<float> bounds_4, StructuredBuffer<float2 > disp_9, Rng_0 * rng_3, float3  ro_3, float3  rd_3, float3  * scatterPoint_1, float * distance_1, int * steps_3)
{
    bool _S192 = sampleFreeFlightUpTo_0(m_6, g_11, bounds_4, disp_9, rng_3, ro_3, rd_3, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_3);
    return _S192;
}

extern "C" __global__ void freeFlightTrial(Medium_0 medium_1, MajorantGrid_0 grid_1, StructuredBuffer<float> bounds_5, StructuredBuffer<float2 > drift_1, float3  origin_2, float3  direction_1, RWStructuredBuffer<float> outDistance_0, RWStructuredBuffer<int> outSteps_1, uint seed_2, int count_1)
{
    int i_17 = int((blockIdx * blockDim + threadIdx).x);
    if(i_17 >= count_1)
    {
        return;
    }
    uint s_4 = uint(i_17) * 747796405U + 2891336453U;
    uint s_5 = ((s_4 >> ((s_4 >> 28U) + 4U)) ^ s_4) * 277803737U;
    Rng_0 rng_4 = makeRng_0(((s_5 >> 22U) ^ s_5) ^ seed_2);
    int steps_4 = int(0);
    float * _S193 = (&(outDistance_0)[i_17]);
    Medium_0 _S194 = medium_1;
    MajorantGrid_0 _S195 = grid_1;
    float3  hit_0;
    float dist_0;
    bool _S196 = sampleFreeFlight_0(&_S194, &_S195, bounds_5, drift_1, &rng_4, origin_2, direction_1, &hit_0, &dist_0, &steps_4);
    float _S197;
    if(_S196)
    {
        _S197 = dist_0;
    }
    else
    {
        _S197 = -1.0f;
    }
    *_S193 = _S197;
    *(&(outSteps_1)[i_17]) = steps_4;
    return;
}

extern "C" __global__ void rngTrial(RWStructuredBuffer<float> output_1, uint seed_3, int count_2)
{
    int i_18 = int((blockIdx * blockDim + threadIdx).x);
    if(i_18 >= count_2)
    {
        return;
    }
    Rng_0 rng_5 = makeRng_0(seed_3 + uint(i_18));
    float * _S198 = (&(output_1)[i_18]);
    float _S199 = randFloat_0(&rng_5);
    *_S198 = _S199;
    return;
}

extern "C" __global__ void buildIceGrid(Medium_0 medium_2, StructuredBuffer<float2 > drift_2, MajorantGrid_0 grid_2, RWStructuredBuffer<float> outBounds_0, int cellCount_0)
{
    int i_19 = int((blockIdx * blockDim + threadIdx).x);
    if(i_19 >= cellCount_0)
    {
        return;
    }
    int _S200 = grid_2.dims_0.x;
    int cx_0 = i_19 % _S200;
    int _S201 = i_19 / _S200;
    int _S202 = grid_2.dims_0.y;
    int cy_0 = _S201 % _S202;
    int cz_0 = i_19 / (_S200 * _S202);
    float3  lo_7 = grid_2.origin_0 + make_float3 (float(cx_0), float(cy_0), float(cz_0)) * grid_2.cellExtent_0;
    float * _S203 = (&(outBounds_0)[i_19]);
    float3  _S204 = lo_7 + grid_2.cellExtent_0;
    GeneratorInput_0 _S205 = medium_2.gen_0;
    float _S206 = iceDensityBound_0(&_S205, drift_2, lo_7, _S204);
    *_S203 = _S206;
    return;
}

