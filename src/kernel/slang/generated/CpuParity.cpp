// GENERATED FROM CpuParity.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cpp-prelude.h"

#ifdef SLANG_PRELUDE_NAMESPACE
using namespace SLANG_PRELUDE_NAMESPACE;
#endif

struct Rng_0
{
    uint32_t state_0;
};

struct EntryPointParams_0
{
    RWStructuredBuffer<float> output_0;
    uint32_t seed_0;
    int32_t count_0;
};

struct GeneratorInput_0
{
    float cellAltitude_0;
    float streakLength_0;
    float cellSize_0;
    float cellDensity_0;
    float cellStrength_0;
    Vector<float, 2>  cellDrift_0;
    float sublimation_0;
    float fallSpeed_0;
    float detailScale_0;
    float detailAmount_0;
    float opticalDepth_0;
    float timeSeconds_0;
    int32_t octaves_0;
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
    int32_t cvOctaves_0;
    Vector<float, 2>  cvDrift_0;
    float cvAge_0;
    float cvRise_0;
};

struct Medium_0
{
    float slabTop_0;
    float slabBottom_0;
    float majorant_0;
    float density_0;
    Vector<float, 3>  coreCentre_0;
    float coreRadius_0;
    float coreDensity_0;
    GeneratorInput_0 gen_0;
    ConvectionInput_0 conv_0;
    int32_t mode_0;
};

struct Dda_0
{
    Vector<int32_t, 3>  cell_0;
    Vector<int32_t, 3>  stepDir_0;
    Vector<float, 3>  tMax_0;
    Vector<float, 3>  tDelta_0;
};

struct MajorantGrid_0
{
    Vector<float, 3>  origin_0;
    Vector<float, 3>  cellExtent_0;
    Vector<int32_t, 3>  dims_0;
    int32_t enabled_0;
};

struct EntryPointParams_1
{
    Medium_0 medium_0;
    MajorantGrid_0 grid_0;
    StructuredBuffer<float> bounds_0;
    StructuredBuffer<Vector<float, 2> > drift_0;
    Vector<float, 3>  origin_1;
    Vector<float, 3>  direction_0;
    RWStructuredBuffer<float> output_1;
    uint32_t seed_1;
    int32_t count_1;
};

static float dot_0(Vector<float, 3>  x_0, Vector<float, 3>  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y + x_0.z * y_0.z;
}

static float dot_1(Vector<float, 2>  x_1, Vector<float, 2>  y_1)
{
    return x_1.x * y_1.x + x_1.y * y_1.y;
}

static float length_0(Vector<float, 2>  x_2)
{
    return (F32_sqrt((dot_1(x_2, x_2))));
}

static Vector<float, 2>  min_0(Vector<float, 2>  x_3, Vector<float, 2>  y_2)
{
    Vector<float, 2>  result_0;
    int32_t i_0 = int(0);
    for(;;)
    {
        if(i_0 < int(2))
        {
        }
        else
        {
            break;
        }
        result_0[i_0] = (F32_min((_slang_vector_get_element(x_3, i_0)), (_slang_vector_get_element(y_2, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static Vector<float, 2>  lerp_0(Vector<float, 2>  x_4, Vector<float, 2>  y_3, Vector<float, 2>  s_0)
{
    return x_4 + (y_3 - x_4) * s_0;
}

static int32_t clamp_0(int32_t x_5, int32_t minBound_0, int32_t maxBound_0)
{
    return (I32_min(((I32_max((x_5), (minBound_0)))), (maxBound_0)));
}

static float clamp_1(float x_6, float minBound_1, float maxBound_1)
{
    return (F32_min(((F32_max((x_6), (minBound_1)))), (maxBound_1)));
}

static float saturate_0(float x_7)
{
    return clamp_1(x_7, 0.0f, 1.0f);
}

static float smoothstep_0(float min_1, float max_0, float x_8)
{
    float _S1 = saturate_0((x_8 - min_1) / (max_0 - min_1));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static Vector<float, 2>  abs_0(Vector<float, 2>  x_9)
{
    Vector<float, 2>  result_1;
    int32_t i_1 = int(0);
    for(;;)
    {
        if(i_1 < int(2))
        {
        }
        else
        {
            break;
        }
        result_1[i_1] = (F32_abs((_slang_vector_get_element(x_9, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static Vector<float, 2>  max_1(Vector<float, 2>  x_10, Vector<float, 2>  y_4)
{
    Vector<float, 2>  result_2;
    int32_t i_2 = int(0);
    for(;;)
    {
        if(i_2 < int(2))
        {
        }
        else
        {
            break;
        }
        result_2[i_2] = (F32_max((_slang_vector_get_element(x_10, i_2)), (_slang_vector_get_element(y_4, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static float lerp_1(float x_11, float y_5, float s_1)
{
    return x_11 + (y_5 - x_11) * s_1;
}

static bool all_0(Vector<bool, 2>  x_12)
{
    bool result_3 = true;
    int32_t i_3 = int(0);
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

static Vector<float, 2>  floor_0(Vector<float, 2>  x_13)
{
    Vector<float, 2>  result_4;
    int32_t i_4 = int(0);
    for(;;)
    {
        if(i_4 < int(2))
        {
        }
        else
        {
            break;
        }
        result_4[i_4] = (F32_floor((_slang_vector_get_element(x_13, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static Vector<float, 3>  floor_1(Vector<float, 3>  x_14)
{
    Vector<float, 3>  result_5;
    int32_t i_5 = int(0);
    for(;;)
    {
        if(i_5 < int(3))
        {
        }
        else
        {
            break;
        }
        result_5[i_5] = (F32_floor((_slang_vector_get_element(x_14, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
}

static Rng_0 makeRng_0(uint32_t seed_2)
{
    Rng_0 r_0;
    (&r_0)->state_0 = seed_2;
    return r_0;
}

static float randFloat_0(Rng_0 * r_1)
{
    uint32_t _S2 = r_1->state_0 * 747796405U + 2891336453U;
    r_1->state_0 = _S2;
    uint32_t word_0 = ((_S2 >> ((_S2 >> 28U) + 4U)) ^ _S2) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

void _cpuRngTrial(void* _S3, void* entryPointParams_0, void* _S4)
{
    ComputeThreadVaryingInput * _S5 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S3));
    int32_t i_6 = int32_t((_S5->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S5->groupThreadID).x);
    if(i_6 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Rng_0 rng_0 = makeRng_0((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_6));
    float * _S6 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->output_0)[i_6]);
    float _S7 = randFloat_0(&rng_0);
    *_S6 = _S7;
    return;
}

static Rng_0 makeRngForIndex_0(uint32_t seed_3, int32_t index_0)
{
    uint32_t s_2 = uint32_t(index_0) * 747796405U + 2891336453U;
    uint32_t s_3 = ((s_2 >> ((s_2 >> 28U) + 4U)) ^ s_2) * 277803737U;
    return makeRng_0(((s_3 >> 22U) ^ s_3) ^ seed_3);
}

static bool slabRange_0(Medium_0 * m_0, Vector<float, 3>  ro_0, Vector<float, 3>  rd_0, float * t0_0, float * t1_0)
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

static Dda_0 ddaInit_0(MajorantGrid_0 * g_0, Vector<float, 3>  ro_1, Vector<float, 3>  rd_1, float t_0)
{
    Dda_0 d_0;
    if((g_0->enabled_0) == int(0))
    {
        Vector<int32_t, 3>  _S13 = Vector<int32_t, 3> (int(0), int(0), int(0));
        (&d_0)->cell_0 = _S13;
        (&d_0)->stepDir_0 = _S13;
        Vector<float, 3>  _S14 = Vector<float, 3> (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_0)->tMax_0 = _S14;
        (&d_0)->tDelta_0 = _S14;
        return d_0;
    }
    Vector<float, 3>  p_0 = ro_1 + rd_1 * (Vector<float, 3> )t_0;
    Vector<float, 3>  _S15 = floor_1((p_0 - g_0->origin_0) / g_0->cellExtent_0);
    Vector<int32_t, 3>  _S16 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(_S15, 0), (int32_t)_slang_vector_get_element(_S15, 1), (int32_t)_slang_vector_get_element(_S15, 2)};
    (&d_0)->cell_0 = _S16;
    int32_t a_0 = int(0);
    for(;;)
    {
        if(a_0 < int(3))
        {
        }
        else
        {
            break;
        }
        int32_t _S17 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            (&d_0)->stepDir_0[a_0] = int(0);
            (&d_0)->tMax_0[a_0] = 1.00000001504746622e+30f;
            (&d_0)->tDelta_0[a_0] = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S18 = _slang_vector_get_element(rd_1, _S17) > 0.0f;
            int32_t _S19;
            if(_S18)
            {
                _S19 = int(1);
            }
            else
            {
                _S19 = int(-1);
            }
            (&d_0)->stepDir_0[a_0] = _S19;
            float _S20 = g_0->origin_0[a_0];
            float _S21 = float((&d_0)->cell_0[a_0]);
            float _S22;
            if(_S18)
            {
                _S22 = 1.0f;
            }
            else
            {
                _S22 = 0.0f;
            }
            (&d_0)->tMax_0[a_0] = t_0 + (_S20 + (_S21 + _S22) * g_0->cellExtent_0[a_0] - _slang_vector_get_element(p_0, a_0)) / _slang_vector_get_element(rd_1, _S17);
            (&d_0)->tDelta_0[a_0] = (F32_abs((g_0->cellExtent_0[a_0] / _slang_vector_get_element(rd_1, _S17))));
        }
        a_0 = a_0 + int(1);
    }
    return d_0;
}

static Vector<uint32_t, 2>  pcg2d_0(Vector<uint32_t, 2>  v_0)
{
    Vector<uint32_t, 2>  _S23 = v_0 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S24 = _S23;
    _S24.x = _S24.x + _S23.y * 1664525U;
    _S24.y = _S24.y + _S24.x * 1664525U;
    Vector<uint32_t, 2>  _S25 = _S24 ^ (_S24 >> ((Vector<uint32_t, 2> )16U));
    _S24 = _S25;
    _S24.x = _S24.x + _S25.y * 1664525U;
    _S24.y = _S24.y + _S24.x * 1664525U;
    Vector<uint32_t, 2>  _S26 = _S24 ^ (_S24 >> ((Vector<uint32_t, 2> )16U));
    _S24 = _S26;
    return _S26;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_0, uint32_t salt_0)
{
    Vector<uint32_t, 2>  h_0 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_0.x), uint32_t(c_0.y)) ^ Vector<uint32_t, 2> (salt_0, salt_0 * 2654435761U));
    Vector<float, 2>  _S27 = Vector<float, 2> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1)};
    return _S27 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float convLife_0(float u_0)
{
    float _S28 = 1.0f - u_0;
    return 6.75f * u_0 * _S28 * _S28;
}

static float convVigour_0(ConvectionInput_0 * c_1, Vector<int32_t, 2>  slot_0)
{
    Vector<float, 2>  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_1->cvAge_0 + h_1.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_1.y);
}

static Vector<float, 2>  convCellCentre_0(Vector<int32_t, 2>  slot_1)
{
    Vector<float, 2>  _S29 = Vector<float, 2> {(float)_slang_vector_get_element(slot_1, 0), (float)_slang_vector_get_element(slot_1, 1)};
    return _S29 + (Vector<float, 2> )0.5f + (hash22_0(slot_1, 1759714724U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.69999998807907104f;
}

static float convBump_0(float d2_0, float reach_0)
{
    float r2_0 = reach_0 * reach_0;
    if(d2_0 >= r2_0)
    {
        return 0.0f;
    }
    float t_1 = 1.0f - d2_0 / r2_0;
    return t_1 * t_1;
}

static void convSlotBound_0(ConvectionInput_0 * c_2, Vector<int32_t, 2>  slot_2, Vector<float, 2>  a_1, Vector<float, 2>  b_0, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S30 = convVigour_0(c_2, slot_2);
    if(_S30 <= 0.0f)
    {
        return;
    }
    Vector<float, 2>  ctr_0 = convCellCentre_0(slot_2);
    Vector<float, 2>  _S31 = a_1 - ctr_0;
    Vector<float, 2>  nearGap_0 = max_1(max_1(_S31, ctr_0 - b_0), Vector<float, 2> (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    Vector<float, 2>  farGap_0 = max_1(abs_0(_S31), abs_0(b_0 - ctr_0));
    float oHi_0 = _S30 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S30 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S30 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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

static float convUpdraftBound_0(ConvectionInput_0 * c_3, Vector<float, 2>  q0_0, Vector<float, 2>  q1_0)
{
    Vector<float, 2>  a_2 = q0_0 / (Vector<float, 2> )c_3->cvSpacing_0;
    Vector<float, 2>  b_1 = q1_0 / (Vector<float, 2> )c_3->cvSpacing_0;
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    Vector<float, 2>  _S32 = floor_0((a_2 + b_1) * (Vector<float, 2> )0.5f);
    Vector<int32_t, 2>  _S33 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S32, 0), (int32_t)_slang_vector_get_element(_S32, 1)};
    Vector<float, 2>  _S34 = Vector<float, 2> {(float)_slang_vector_get_element(_S33, 0), (float)_slang_vector_get_element(_S33, 1)};
    Vector<float, 2>  highEdge_0 = _S34 + (Vector<float, 2> )1.0f + (Vector<float, 2> )0.00009999999747379f;
    bool _S35;
    if(all_0(a_2 >= (_S34 - (Vector<float, 2> )0.00009999999747379f)))
    {
        _S35 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S35 = false;
    }
    int32_t j_0;
    int32_t i_7;
    if(_S35)
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
                convSlotBound_0(c_3, _S33 + Vector<int32_t, 2> (i_7, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_7 = i_7 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    else
    {
        Vector<float, 2>  _S36 = floor_0(a_2);
        Vector<int32_t, 2>  _S37 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S36, 0), (int32_t)_slang_vector_get_element(_S36, 1)};
        Vector<int32_t, 2>  _S38 = Vector<int32_t, 2> (int(1), int(1));
        Vector<int32_t, 2>  i0_0 = _S37 - _S38;
        Vector<float, 2>  _S39 = floor_0(b_1);
        Vector<int32_t, 2>  _S40 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S39, 0), (int32_t)_slang_vector_get_element(_S39, 1)};
        Vector<int32_t, 2>  _S41 = _S40 + _S38;
        int32_t _S42 = i0_0.y;
        j_0 = _S42;
        for(;;)
        {
            if(j_0 <= (_S41.y))
            {
                _S35 = j_0 <= (_S42 + int(32));
            }
            else
            {
                _S35 = false;
            }
            if(_S35)
            {
            }
            else
            {
                break;
            }
            int32_t _S43 = i0_0.x;
            i_7 = _S43;
            for(;;)
            {
                bool _S44;
                if(i_7 <= (_S41.x))
                {
                    _S44 = i_7 <= (_S43 + int(32));
                }
                else
                {
                    _S44 = false;
                }
                if(_S44)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_3, Vector<int32_t, 2> (i_7, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_7 = i_7 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    return lerp_1((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_3->cvPolarity_0) + 0.00000999999974738f;
}

static float convTowerHeight_0(ConvectionInput_0 * c_4, float w_0)
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

static float convLift_0(ConvectionInput_0 * c_5, float above_0)
{
    return c_5->cvBillow_0 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_1(0.34999999403953552f, 1.0f, saturate_0(above_0 / (F32_max((c_5->cvDepth_0), (1.0f)))));
}

static float convectionBound_0(ConvectionInput_0 * c_6, Vector<float, 3>  lo_0, Vector<float, 3>  hi_0)
{
    float low_0 = lo_0.y - c_6->cvBase_0;
    float high_0 = hi_0.y - c_6->cvBase_0;
    float ceiling_0 = c_6->cvDepth_0 + c_6->cvBillow_0;
    bool _S45;
    if(high_0 < 0.0f)
    {
        _S45 = true;
    }
    else
    {
        _S45 = low_0 > ceiling_0;
    }
    if(_S45)
    {
        return 0.0f;
    }
    float _S46 = (F32_max((low_0), (0.0f)));
    float _S47 = (F32_min((high_0), (ceiling_0)));
    float _S48 = convUpdraftBound_0(c_6, Vector<float, 2> {lo_0.x, lo_0.z} - c_6->cvDrift_0, Vector<float, 2> {hi_0.x, hi_0.z} - c_6->cvDrift_0);
    float _S49 = convTowerHeight_0(c_6, _S48);
    if(_S49 <= 0.0f)
    {
        return 0.0f;
    }
    float _S50 = convLift_0(c_6, _S47);
    float inside_0 = _S49 - _S46 + _S50 + 0.00100000004749745f;
    if(inside_0 <= 0.0f)
    {
        return 0.0f;
    }
    return c_6->cvSigma_0 * (F32_sqrt((saturate_0(_S47 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_0) * 1.00001001358032227f;
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_1, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_15 = clamp_1(depth_0 / g_1->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_8 = clamp_0(int32_t((F32_floor((x_15)))), int(0), int(31));
    return lerp_0(disp_0.Load(i_8), disp_0.Load(i_8 + int(1)), (Vector<float, 2> )(x_15 - float(i_8)));
}

static void driftRange_0(GeneratorInput_0 * g_2, StructuredBuffer<Vector<float, 2> > disp_1, float d0_0, float d1_0, Vector<float, 2>  * lo_1, Vector<float, 2>  * hi_1)
{
    Vector<float, 2>  _S51 = driftAt_0(g_2, disp_1, d0_0);
    *lo_1 = _S51;
    *hi_1 = _S51;
    Vector<float, 2>  _S52 = driftAt_0(g_2, disp_1, d1_0);
    *lo_1 = min_0(*lo_1, _S52);
    *hi_1 = max_1(*hi_1, _S52);
    int32_t _S53 = clamp_0(int32_t((F32_ceil((clamp_1(d1_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int32_t k_0 = clamp_0(int32_t((F32_floor((clamp_1(d0_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_0 <= _S53)
        {
        }
        else
        {
            break;
        }
        *lo_1 = min_0(*lo_1, disp_1.Load(k_0));
        *hi_1 = max_1(*hi_1, disp_1.Load(k_0));
        k_0 = k_0 + int(1);
    }
    return;
}

static float cellFieldBound_0(GeneratorInput_0 * g_3, Vector<float, 2>  q0_1, Vector<float, 2>  q1_1)
{
    float spacing_0 = g_3->cellSize_0 * 2.20000004768371582f;
    Vector<float, 2>  a_3 = (q0_1 - g_3->cellDrift_0) / (Vector<float, 2> )spacing_0;
    Vector<float, 2>  b_2 = (q1_1 - g_3->cellDrift_0) / (Vector<float, 2> )spacing_0;
    Vector<float, 2>  _S54 = floor_0(a_3);
    Vector<int32_t, 2>  _S55 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S54, 0), (int32_t)_slang_vector_get_element(_S54, 1)};
    Vector<int32_t, 2>  _S56 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  i0_1 = _S55 - _S56;
    Vector<float, 2>  _S57 = floor_0(b_2);
    Vector<int32_t, 2>  _S58 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S57, 0), (int32_t)_slang_vector_get_element(_S57, 1)};
    Vector<int32_t, 2>  _S59 = _S58 + _S56;
    int32_t _S60 = i0_1.y;
    int32_t j_1 = _S60;
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
        int32_t _S62 = i0_1.x;
        int32_t i_9 = _S62;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S63;
            if(i_9 <= (_S59.x))
            {
                _S63 = i_9 <= (_S62 + int(32));
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
            Vector<int32_t, 2>  o_0 = Vector<int32_t, 2> (i_9, j_1);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_9 = i_9 + int(1);
                continue;
            }
            Vector<float, 2>  _S64 = Vector<float, 2> {(float)_slang_vector_get_element(o_0, 0), (float)_slang_vector_get_element(o_0, 1)};
            Vector<float, 2>  c_7 = _S64 + (Vector<float, 2> )0.5f + (hash22_0(o_0, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_1(max_1(a_3 - c_7, c_7 - b_2), Vector<float, 2> (0.0f, 0.0f))) * 2.20000004768371582f);
            i_9 = i_9 + int(1);
        }
        j_1 = j_1 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static float iceDensityBound_0(GeneratorInput_0 * g_4, StructuredBuffer<Vector<float, 2> > disp_2, Vector<float, 3>  lo_2, Vector<float, 3>  hi_2)
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
    Vector<float, 2>  driftLo_0;
    Vector<float, 2>  driftHi_0;
    driftRange_0(g_4, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S67 = cellFieldBound_0(g_4, Vector<float, 2> (lo_2.x, lo_2.z) - driftHi_0, Vector<float, 2> (hi_2.x, hi_2.z) - driftLo_0);
    return (F32_max((_S67 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((_S66), (1.0f)));
}

static float mediumBound_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_3, Vector<float, 3>  lo_3, Vector<float, 3>  hi_3)
{
    int32_t _S68 = m_1->mode_0;
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

static float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_1, StructuredBuffer<Vector<float, 2> > disp_4, Vector<int32_t, 3>  c_8, float fallback_0)
{
    int32_t _S71 = g_5->enabled_0;
    if((g_5->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S71 == int(2))
    {
        Vector<float, 3>  _S72 = Vector<float, 3> {(float)_slang_vector_get_element(c_8, 0), (float)_slang_vector_get_element(c_8, 1), (float)_slang_vector_get_element(c_8, 2)};
        Vector<float, 3>  lo_4 = g_5->origin_0 + _S72 * g_5->cellExtent_0;
        float _S73 = mediumBound_0(m_2, disp_4, lo_4, lo_4 + g_5->cellExtent_0);
        return _S73;
    }
    int32_t _S74 = c_8.x;
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
    return bounds_1.Load((c_8.z * g_5->dims_0.y + c_8.y) * g_5->dims_0.x + _S74);
}

static float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_2)
{
    bool _S76;
    if((d_2->tMax_0.x) <= (d_2->tMax_0.y))
    {
        _S76 = (d_2->tMax_0.x) <= (d_2->tMax_0.z);
    }
    else
    {
        _S76 = false;
    }
    if(_S76)
    {
        d_2->cell_0.x = d_2->cell_0.x + d_2->stepDir_0.x;
        d_2->tMax_0.x = d_2->tMax_0.x + d_2->tDelta_0.x;
    }
    else
    {
        if((d_2->tMax_0.y) <= (d_2->tMax_0.z))
        {
            d_2->cell_0.y = d_2->cell_0.y + d_2->stepDir_0.y;
            d_2->tMax_0.y = d_2->tMax_0.y + d_2->tDelta_0.y;
        }
        else
        {
            d_2->cell_0.z = d_2->cell_0.z + d_2->stepDir_0.z;
            d_2->tMax_0.z = d_2->tMax_0.z + d_2->tDelta_0.z;
        }
    }
    return;
}

static float cellField_0(GeneratorInput_0 * g_6, Vector<float, 2>  q_0)
{
    Vector<float, 2>  gq_0 = (q_0 - g_6->cellDrift_0) / (Vector<float, 2> )(g_6->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_0(gq_0);
    Vector<int32_t, 2>  _S77 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
    int32_t j_2 = int(-1);
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
        int32_t i_10 = int(-1);
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
            Vector<int32_t, 2>  o_1 = _S77 + Vector<int32_t, 2> (i_10, j_2);
            if((hash22_0(o_1, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_10 = i_10 + int(1);
                continue;
            }
            Vector<float, 2>  _S78 = Vector<float, 2> {(float)_slang_vector_get_element(o_1, 0), (float)_slang_vector_get_element(o_1, 1)};
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(gq_0 - (_S78 + (Vector<float, 2> )0.5f + (hash22_0(o_1, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f)) * 2.20000004768371582f);
            i_10 = i_10 + int(1);
        }
        j_2 = j_2 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_6->cellStrength_0;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_1)
{
    Vector<uint32_t, 3>  _S79 = v_1 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S80 = _S79;
    _S80.x = _S80.x + _S79.y * _S79.z;
    _S80.y = _S80.y + _S80.z * _S80.x;
    _S80.z = _S80.z + _S80.x * _S80.y;
    Vector<uint32_t, 3>  _S81 = _S80 ^ (_S80 >> ((Vector<uint32_t, 3> )16U));
    _S80 = _S81;
    _S80.x = _S80.x + _S81.y * _S81.z;
    _S80.y = _S80.y + _S80.z * _S80.x;
    _S80.z = _S80.z + _S80.x * _S80.y;
    return _S80;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_9)
{
    Vector<uint32_t, 3>  h_2 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_9.x), uint32_t(c_9.y), uint32_t(c_9.z)));
    Vector<float, 3>  _S82 = Vector<float, 3> {(float)_slang_vector_get_element(h_2, 0), (float)_slang_vector_get_element(h_2, 1), (float)_slang_vector_get_element(h_2, 2)};
    return _S82 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float gradientNoise_0(Vector<float, 3>  p_1)
{
    Vector<float, 3>  fi_0 = floor_1(p_1);
    Vector<int32_t, 3>  _S83 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_1 - fi_0;
    Vector<float, 3>  u_2 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S84 = u_2.x;
    float _S85 = u_2.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S83), f_0), dot_0(hash33_0(_S83 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S84), lerp_1(dot_0(hash33_0(_S83 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S83 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S84), _S85), lerp_1(lerp_1(dot_0(hash33_0(_S83 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S83 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S84), lerp_1(dot_0(hash33_0(_S83 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S83 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S84), _S85), u_2.z);
}

static float fbm_0(Vector<float, 3>  p_2, int32_t octaves_1)
{
    int32_t i_11 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S86 = p_2;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S86);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S87 = _S86 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_11 = i_11 + int(1);
        amp_0 = amp_1;
        _S86 = _S87;
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

static float iceDensity_0(GeneratorInput_0 * g_7, StructuredBuffer<Vector<float, 2> > disp_5, Vector<float, 3>  p_3)
{
    float depth_1 = g_7->cellAltitude_0 - p_3.y;
    bool _S88;
    if(depth_1 < 0.0f)
    {
        _S88 = true;
    }
    else
    {
        _S88 = depth_1 > (g_7->streakLength_0);
    }
    if(_S88)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S89 = Vector<float, 2> {p_3.x, p_3.z};
    Vector<float, 2>  _S90 = driftAt_0(g_7, disp_5, depth_1);
    Vector<float, 2>  source_0 = _S89 - _S90;
    float _S91 = cellField_0(g_7, source_0);
    if(_S91 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S91 * (F32_exp((- g_7->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, depth_1)) * (F32_max((1.0f + g_7->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_7->detailScale_0).x, (source_0 / (Vector<float, 2> )g_7->detailScale_0).y, depth_1 / (F32_max((g_7->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_7->timeSeconds_0 * 0.00999999977648258f), g_7->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((g_7->streakLength_0), (1.0f)));
}

static float convUpdraft_0(ConvectionInput_0 * c_10, Vector<float, 2>  q_1)
{
    Vector<float, 2>  g_8 = q_1 / (Vector<float, 2> )c_10->cvSpacing_0;
    Vector<float, 2>  _S92 = floor_0(g_8);
    Vector<int32_t, 2>  _S93 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S92, 0), (int32_t)_slang_vector_get_element(_S92, 1)};
    float oTop_0 = 0.0f;
    float oNext_0 = 0.0f;
    float kTop_0 = 0.0f;
    float kNext_0 = 0.0f;
    int32_t j_3 = int(-1);
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
        int32_t i_12 = int(-1);
        for(;;)
        {
            if(i_12 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_3 = _S93 + Vector<int32_t, 2> (i_12, j_3);
            float _S94 = convVigour_0(c_10, slot_3);
            if(_S94 <= 0.0f)
            {
                i_12 = i_12 + int(1);
                continue;
            }
            Vector<float, 2>  d_3 = g_8 - convCellCentre_0(slot_3);
            float d2_1 = dot_1(d_3, d_3);
            float ko_0 = _S94 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S94 * convBump_0(d2_1, 1.04999995231628418f);
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
                float _S95 = oTop_2;
                oTop_2 = oTop_1;
                oNext_2 = _S95;
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
                float _S96 = kTop_2;
                kTop_2 = kTop_1;
                kNext_2 = _S96;
            }
            oTop_1 = oTop_2;
            oNext_1 = oNext_2;
            kTop_1 = kTop_2;
            kNext_1 = kNext_2;
            i_12 = i_12 + int(1);
        }
        int32_t j_4 = j_3 + int(1);
        oTop_0 = oTop_1;
        oNext_0 = oNext_1;
        kTop_0 = kTop_1;
        kNext_0 = kNext_1;
        j_3 = j_4;
    }
    return lerp_1((F32_min((oNext_0 / 0.31000000238418579f), (1.0f))), kTop_0 - kNext_0, c_10->cvPolarity_0);
}

static float convPuffs_0(Vector<float, 3>  x_16)
{
    Vector<float, 3>  fl_0 = floor_1(x_16);
    Vector<int32_t, 3>  _S97 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fl_0, 0), (int32_t)_slang_vector_get_element(fl_0, 1), (int32_t)_slang_vector_get_element(fl_0, 2)};
    Vector<float, 3>  f_1 = x_16 - fl_0;
    int32_t dz_0;
    if((f_1.x) < 0.5f)
    {
        dz_0 = int(-1);
    }
    else
    {
        dz_0 = int(0);
    }
    int32_t dy_0;
    if((f_1.y) < 0.5f)
    {
        dy_0 = int(-1);
    }
    else
    {
        dy_0 = int(0);
    }
    int32_t dx_0;
    if((f_1.z) < 0.5f)
    {
        dx_0 = int(-1);
    }
    else
    {
        dx_0 = int(0);
    }
    Vector<int32_t, 3>  _S98 = Vector<int32_t, 3> (dz_0, dy_0, dx_0);
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
                Vector<int32_t, 3>  off_0 = _S98 + Vector<int32_t, 3> (dx_0, dy_0, dz_0);
                Vector<float, 3>  _S99 = Vector<float, 3> {(float)_slang_vector_get_element(off_0, 0), (float)_slang_vector_get_element(off_0, 1), (float)_slang_vector_get_element(off_0, 2)};
                Vector<float, 3>  d_4 = _S99 + (Vector<float, 3> )0.5f + (Vector<float, 3> )0.25f * hash33_0(_S97 + off_0) - f_1;
                float _S100 = (F32_min((nearest_1), (dot_0(d_4, d_4))));
                int32_t dx_1 = dx_0 + int(1);
                nearest_1 = _S100;
                dx_0 = dx_1;
            }
            int32_t dy_1 = dy_0 + int(1);
            nearest_0 = nearest_1;
            dy_0 = dy_1;
        }
        dz_0 = dz_0 + int(1);
    }
    return saturate_0(1.0f - nearest_0 / 0.5625f);
}

static float convBillow_0(ConvectionInput_0 * c_11, Vector<float, 3>  p_4)
{
    Vector<float, 3>  _S101 = Vector<float, 3> (p_4.x, p_4.y - c_11->cvRise_0, p_4.z) / (Vector<float, 3> )c_11->cvBillowScale_0;
    int32_t i_13 = int(0);
    float amp_2 = 0.60000002384185791f;
    Vector<float, 3>  x_17 = _S101;
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
        if(i_13 >= (c_11->cvOctaves_0))
        {
            break;
        }
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_17);
        float norm_3 = norm_2 + amp_2;
        Vector<float, 3>  x_18 = x_17 * (Vector<float, 3> )2.17000007629394531f;
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_13 = i_13 + int(1);
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

static float convectionDensity_0(ConvectionInput_0 * c_12, Vector<float, 3>  p_5)
{
    float _S102 = p_5.y;
    float above_1 = _S102 - c_12->cvBase_0;
    bool _S103;
    if(above_1 < 0.0f)
    {
        _S103 = true;
    }
    else
    {
        _S103 = above_1 > (c_12->cvDepth_0 + c_12->cvBillow_0);
    }
    if(_S103)
    {
        return 0.0f;
    }
    Vector<float, 2>  q_2 = Vector<float, 2> {p_5.x, p_5.z} - c_12->cvDrift_0;
    float _S104 = convUpdraft_0(c_12, q_2);
    float _S105 = convTowerHeight_0(c_12, _S104);
    if(_S105 <= 0.0f)
    {
        return 0.0f;
    }
    float _S106 = convLift_0(c_12, above_1);
    float _S107 = _S105 - above_1;
    if((_S107 + _S106) <= 0.0f)
    {
        return 0.0f;
    }
    float inside_1;
    if((_S107 - _S106) >= 12.0f)
    {
        inside_1 = 12.0f;
    }
    else
    {
        float _S108 = convBillow_0(c_12, Vector<float, 3> (q_2.x, _S102, q_2.y));
        float inside_2 = _S107 + _S106 * _S108;
        if(inside_2 <= 0.0f)
        {
            return 0.0f;
        }
        inside_1 = inside_2;
    }
    return c_12->cvSigma_0 * (F32_sqrt((saturate_0(above_1 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1);
}

static float densityAt_0(Medium_0 * m_3, StructuredBuffer<Vector<float, 2> > disp_6, Vector<float, 3>  p_6)
{
    float _S109 = p_6.y;
    bool _S110;
    if(_S109 < (m_3->slabBottom_0))
    {
        _S110 = true;
    }
    else
    {
        _S110 = _S109 > (m_3->slabTop_0);
    }
    if(_S110)
    {
        return 0.0f;
    }
    int32_t _S111 = m_3->mode_0;
    if((m_3->mode_0) == int(0))
    {
        return m_3->density_0;
    }
    if(_S111 == int(2))
    {
        float _S112 = iceDensity_0(&m_3->gen_0, disp_6, p_6);
        return _S112;
    }
    if(_S111 == int(3))
    {
        float _S113 = convectionDensity_0(&m_3->conv_0, p_6);
        return _S113;
    }
    Vector<float, 3>  d_5 = (p_6 - m_3->coreCentre_0) / (Vector<float, 3> )(F32_max((m_3->coreRadius_0), (9.99999997475242708e-07f)));
    return m_3->density_0 + m_3->coreDensity_0 * (F32_exp((- dot_0(d_5, d_5))));
}

static float transmittance_0(Medium_0 * m_4, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > disp_7, Rng_0 * rng_1, Vector<float, 3>  p_7, Vector<float, 3>  dir_0, int32_t * steps_0)
{
    float t0_1;
    float t1_1;
    bool _S114 = slabRange_0(m_4, p_7, dir_0, &t0_1, &t1_1);
    if(!_S114)
    {
        return 1.0f;
    }
    float _S115 = (F32_max((t0_1), (0.0f)));
    t0_1 = _S115;
    Dda_0 _S116 = ddaInit_0(g_9, p_7, dir_0, _S115);
    Dda_0 dda_0 = _S116;
    float _S117 = m_4->majorant_0;
    float _S118 = gridBound_0(m_4, g_9, bounds_2, disp_7, (&dda_0)->cell_0, m_4->majorant_0);
    float localMaj_0 = _S118;
    int32_t i_14 = int(0);
    float t_2 = _S115;
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
        Dda_0 _S119 = dda_0;
        float _S120 = ddaExit_0(&_S119);
        float _S121 = (F32_min((_S120), (t1_1)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S121 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S122 = gridBound_0(m_4, g_9, bounds_2, disp_7, (&dda_0)->cell_0, _S117);
            localMaj_0 = _S122;
            t_2 = _S121;
            i_14 = i_14 + int(1);
            continue;
        }
        float _S123 = randFloat_0(rng_1);
        float t_3 = t_2 - (F32_log(((F32_max((1.0f - _S123), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_3 >= _S121)
        {
            if(_S121 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S124 = gridBound_0(m_4, g_9, bounds_2, disp_7, (&dda_0)->cell_0, _S117);
            localMaj_0 = _S124;
            t_2 = _S121;
            i_14 = i_14 + int(1);
            continue;
        }
        float _S125 = densityAt_0(m_4, disp_7, p_7 + dir_0 * (Vector<float, 3> )t_3);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S125 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S126 = randFloat_0(rng_1);
            if(_S126 > 0.5f)
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

void _cpuTransmittanceTrial(void* _S127, void* entryPointParams_1, void* _S128)
{
    ComputeThreadVaryingInput * _S129 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S127));
    int32_t i_15 = int32_t((_S129->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S129->groupThreadID).x);
    if(i_15 >= ((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->count_1))
    {
        return;
    }
    Rng_0 rng_2 = makeRngForIndex_0((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->seed_1, i_15);
    int32_t steps_1 = int(0);
    float * _S130 = (&((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->output_1)[i_15]);
    float _S131 = transmittance_0(&(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->medium_0, &(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->grid_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->bounds_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->drift_0, &rng_2, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->origin_1, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->direction_0, &steps_1);
    *_S130 = _S131;
    return;
}

SLANG_PRELUDE_EXPORT
void cpuRngTrial_Thread(ComputeThreadVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    _cpuRngTrial(varyingInput, entryPointParams, globalParams);
}
SLANG_PRELUDE_EXPORT
void cpuRngTrial_Group(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    ComputeThreadVaryingInput threadInput = {};
    threadInput.groupID = varyingInput->startGroupID;
    for (uint32_t x = 0; x < 64; ++x)
    {
        threadInput.groupThreadID.x = x;
        _cpuRngTrial(&threadInput, entryPointParams, globalParams);
    }
}
SLANG_PRELUDE_EXPORT
void cpuRngTrial(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    ComputeVaryingInput vi = *varyingInput;
    ComputeVaryingInput groupVaryingInput = {};
    for (uint32_t z = vi.startGroupID.z; z < vi.endGroupID.z; ++z)
    {
        groupVaryingInput.startGroupID.z = z;
        for (uint32_t y = vi.startGroupID.y; y < vi.endGroupID.y; ++y)
        {
            groupVaryingInput.startGroupID.y = y;
            for (uint32_t x = vi.startGroupID.x; x < vi.endGroupID.x; ++x)
            {
                groupVaryingInput.startGroupID.x = x;
                cpuRngTrial_Group(&groupVaryingInput, entryPointParams, globalParams);
            }
        }
    }
}
SLANG_PRELUDE_EXPORT
void cpuTransmittanceTrial_Thread(ComputeThreadVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    _cpuTransmittanceTrial(varyingInput, entryPointParams, globalParams);
}
SLANG_PRELUDE_EXPORT
void cpuTransmittanceTrial_Group(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    ComputeThreadVaryingInput threadInput = {};
    threadInput.groupID = varyingInput->startGroupID;
    for (uint32_t x = 0; x < 64; ++x)
    {
        threadInput.groupThreadID.x = x;
        _cpuTransmittanceTrial(&threadInput, entryPointParams, globalParams);
    }
}
SLANG_PRELUDE_EXPORT
void cpuTransmittanceTrial(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    ComputeVaryingInput vi = *varyingInput;
    ComputeVaryingInput groupVaryingInput = {};
    for (uint32_t z = vi.startGroupID.z; z < vi.endGroupID.z; ++z)
    {
        groupVaryingInput.startGroupID.z = z;
        for (uint32_t y = vi.startGroupID.y; y < vi.endGroupID.y; ++y)
        {
            groupVaryingInput.startGroupID.y = y;
            for (uint32_t x = vi.startGroupID.x; x < vi.endGroupID.x; ++x)
            {
                groupVaryingInput.startGroupID.x = x;
                cpuTransmittanceTrial_Group(&groupVaryingInput, entryPointParams, globalParams);
            }
        }
    }
}
