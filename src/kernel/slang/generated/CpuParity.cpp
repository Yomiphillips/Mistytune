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
    int32_t cvHeroAlone_0;
    Vector<float, 2>  cvHeroAt_0;
    float cvHeroRadius_0;
    float cvHeroTop_0;
    Vector<float, 3>  cvHeroSeed_0;
    float cvHeroBillow_0;
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
    int32_t clipOn_0;
    Vector<float, 2>  clipLo_0;
    Vector<float, 2>  clipHi_0;
    Vector<float, 2>  fadeAt_0;
    float fadeRadius_0;
    float fadeWidth_0;
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

static bool any_0(Vector<bool, 2>  x_1)
{
    bool result_0 = false;
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

static Vector<float, 2>  lerp_0(Vector<float, 2>  x_2, Vector<float, 2>  y_1, Vector<float, 2>  s_0)
{
    return x_2 + (y_1 - x_2) * s_0;
}

static int32_t clamp_0(int32_t x_3, int32_t minBound_0, int32_t maxBound_0)
{
    return (I32_min(((I32_max((x_3), (minBound_0)))), (maxBound_0)));
}

static float dot_1(Vector<float, 2>  x_4, Vector<float, 2>  y_2)
{
    return x_4.x * y_2.x + x_4.y * y_2.y;
}

static float length_0(Vector<float, 2>  x_5)
{
    return (F32_sqrt((dot_1(x_5, x_5))));
}

static float clamp_1(float x_6, float minBound_1, float maxBound_1)
{
    return (F32_min(((F32_max((x_6), (minBound_1)))), (maxBound_1)));
}

static Vector<float, 2>  abs_0(Vector<float, 2>  x_7)
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
        result_1[i_1] = (F32_abs((_slang_vector_get_element(x_7, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static bool all_0(Vector<bool, 2>  x_8)
{
    bool result_2 = true;
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

static Vector<float, 2>  floor_0(Vector<float, 2>  x_9)
{
    Vector<float, 2>  result_3;
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
        result_3[i_3] = (F32_floor((_slang_vector_get_element(x_9, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static float lerp_1(float x_10, float y_3, float s_1)
{
    return x_10 + (y_3 - x_10) * s_1;
}

static float saturate_0(float x_11)
{
    return clamp_1(x_11, 0.0f, 1.0f);
}

static float smoothstep_0(float min_0, float max_0, float x_12)
{
    float _S1 = saturate_0((x_12 - min_0) / (max_0 - min_0));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static Vector<float, 3>  floor_1(Vector<float, 3>  x_13)
{
    Vector<float, 3>  result_4;
    int32_t i_4 = int(0);
    for(;;)
    {
        if(i_4 < int(3))
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

static Vector<float, 2>  min_1(Vector<float, 2>  x_14, Vector<float, 2>  y_4)
{
    Vector<float, 2>  result_5;
    int32_t i_5 = int(0);
    for(;;)
    {
        if(i_5 < int(2))
        {
        }
        else
        {
            break;
        }
        result_5[i_5] = (F32_min((_slang_vector_get_element(x_14, i_5)), (_slang_vector_get_element(y_4, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
}

static Vector<float, 2>  max_1(Vector<float, 2>  x_15, Vector<float, 2>  y_5)
{
    Vector<float, 2>  result_6;
    int32_t i_6 = int(0);
    for(;;)
    {
        if(i_6 < int(2))
        {
        }
        else
        {
            break;
        }
        result_6[i_6] = (F32_max((_slang_vector_get_element(x_15, i_6)), (_slang_vector_get_element(y_5, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_6;
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
    int32_t i_7 = int32_t((_S5->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S5->groupThreadID).x);
    if(i_7 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Rng_0 rng_0 = makeRng_0((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_7));
    float * _S6 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->output_0)[i_7]);
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

static bool clipAxis_0(float o_0, float d_0, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_0))) < 9.99999971718068537e-10f)
    {
        bool _S8;
        if(o_0 >= lo_0)
        {
            _S8 = o_0 <= hi_0;
        }
        else
        {
            _S8 = false;
        }
        return _S8;
    }
    float ta_0 = (lo_0 - o_0) / d_0;
    float tb_0 = (hi_0 - o_0) / d_0;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S9 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S9;
    return _S9 > (*t0_0);
}

static bool slabRange_0(Medium_0 * m_0, Vector<float, 3>  ro_0, Vector<float, 3>  rd_0, float * t0_1, float * t1_1)
{
    *t0_1 = 0.0f;
    *t1_1 = 1.0e+09f;
    float _S10 = rd_0.y;
    bool _S11;
    if((F32_abs((_S10))) < 9.99999997475242708e-07f)
    {
        float _S12 = ro_0.y;
        if(_S12 < (m_0->slabBottom_0))
        {
            _S11 = true;
        }
        else
        {
            _S11 = _S12 > (m_0->slabTop_0);
        }
        if(_S11)
        {
            return false;
        }
    }
    else
    {
        float _S13 = ro_0.y;
        float ta_1 = (m_0->slabBottom_0 - _S13) / _S10;
        float tb_1 = (m_0->slabTop_0 - _S13) / _S10;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S14 = (m_0->clipOn_0) != int(0);
    Vector<float, 2>  lo_1;
    if(_S14)
    {
        lo_1 = m_0->clipLo_0;
    }
    else
    {
        lo_1 = Vector<float, 2> (-1.0e+09f, -1.0e+09f);
    }
    Vector<float, 2>  hi_1;
    if(_S14)
    {
        hi_1 = m_0->clipHi_0;
    }
    else
    {
        hi_1 = Vector<float, 2> (1.0e+09f, 1.0e+09f);
    }
    float _S15 = m_0->fadeRadius_0;
    if((m_0->fadeRadius_0) > 0.0f)
    {
        Vector<float, 2>  _S16 = min_1(hi_1, m_0->fadeAt_0 + (Vector<float, 2> )_S15);
        lo_1 = max_1(lo_1, m_0->fadeAt_0 - (Vector<float, 2> )_S15);
        hi_1 = _S16;
    }
    bool _S17 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S17)
    {
        return false;
    }
    bool _S18 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S18)
    {
        return false;
    }
    float _S19 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S19;
    if(_S19 > (*t0_1))
    {
        _S11 = (*t1_1) > 0.0f;
    }
    else
    {
        _S11 = false;
    }
    return _S11;
}

static Dda_0 ddaInit_0(MajorantGrid_0 * g_0, Vector<float, 3>  ro_1, Vector<float, 3>  rd_1, float t_0)
{
    Dda_0 d_1;
    if((g_0->enabled_0) == int(0))
    {
        Vector<int32_t, 3>  _S20 = Vector<int32_t, 3> (int(0), int(0), int(0));
        (&d_1)->cell_0 = _S20;
        (&d_1)->stepDir_0 = _S20;
        Vector<float, 3>  _S21 = Vector<float, 3> (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_1)->tMax_0 = _S21;
        (&d_1)->tDelta_0 = _S21;
        return d_1;
    }
    Vector<float, 3>  p_0 = ro_1 + rd_1 * (Vector<float, 3> )t_0;
    Vector<float, 3>  _S22 = floor_1((p_0 - g_0->origin_0) / g_0->cellExtent_0);
    Vector<int32_t, 3>  _S23 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(_S22, 0), (int32_t)_slang_vector_get_element(_S22, 1), (int32_t)_slang_vector_get_element(_S22, 2)};
    (&d_1)->cell_0 = _S23;
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
        int32_t _S24 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            (&d_1)->stepDir_0[a_0] = int(0);
            (&d_1)->tMax_0[a_0] = 1.00000001504746622e+30f;
            (&d_1)->tDelta_0[a_0] = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S25 = _slang_vector_get_element(rd_1, _S24) > 0.0f;
            int32_t _S26;
            if(_S25)
            {
                _S26 = int(1);
            }
            else
            {
                _S26 = int(-1);
            }
            (&d_1)->stepDir_0[a_0] = _S26;
            float _S27 = g_0->origin_0[a_0];
            float _S28 = float((&d_1)->cell_0[a_0]);
            float _S29;
            if(_S25)
            {
                _S29 = 1.0f;
            }
            else
            {
                _S29 = 0.0f;
            }
            (&d_1)->tMax_0[a_0] = t_0 + (_S27 + (_S28 + _S29) * g_0->cellExtent_0[a_0] - _slang_vector_get_element(p_0, a_0)) / _slang_vector_get_element(rd_1, _S24);
            (&d_1)->tDelta_0[a_0] = (F32_abs((g_0->cellExtent_0[a_0] / _slang_vector_get_element(rd_1, _S24))));
        }
        a_0 = a_0 + int(1);
    }
    return d_1;
}

static float convCeiling_0(ConvectionInput_0 * c_0)
{
    float _S30 = c_0->cvBillow_0;
    float field_0 = c_0->cvDepth_0 + c_0->cvBillow_0;
    float _S31 = c_0->cvHeroTop_0;
    float hero_0;
    if((c_0->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S31 + _S30 * c_0->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    return (F32_max((field_0), (hero_0)));
}

static float convLift_0(ConvectionInput_0 * c_1, float above_0, float k_0)
{
    return (F32_min((c_1->cvBillow_0 * k_0 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_1(0.60000002384185791f, 1.0f, saturate_0(above_0 / (F32_max((c_1->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_0), (0.0f))))));
}

static Vector<uint32_t, 2>  pcg2d_0(Vector<uint32_t, 2>  v_0)
{
    Vector<uint32_t, 2>  _S32 = v_0 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S33 = _S32;
    _S33.x = _S33.x + _S32.y * 1664525U;
    _S33.y = _S33.y + _S33.x * 1664525U;
    Vector<uint32_t, 2>  _S34 = _S33 ^ (_S33 >> ((Vector<uint32_t, 2> )16U));
    _S33 = _S34;
    _S33.x = _S33.x + _S34.y * 1664525U;
    _S33.y = _S33.y + _S33.x * 1664525U;
    Vector<uint32_t, 2>  _S35 = _S33 ^ (_S33 >> ((Vector<uint32_t, 2> )16U));
    _S33 = _S35;
    return _S35;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_2, uint32_t salt_0)
{
    Vector<uint32_t, 2>  h_0 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_2.x), uint32_t(c_2.y)) ^ Vector<uint32_t, 2> (salt_0, salt_0 * 2654435761U));
    Vector<float, 2>  _S36 = Vector<float, 2> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1)};
    return _S36 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float convLife_0(float u_0)
{
    float _S37 = 1.0f - u_0;
    return 6.75f * u_0 * _S37 * _S37;
}

static float convVigour_0(ConvectionInput_0 * c_3, Vector<int32_t, 2>  slot_0)
{
    Vector<float, 2>  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_3->cvAge_0 + h_1.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_1.y);
}

static Vector<float, 2>  convCellCentre_0(Vector<int32_t, 2>  slot_1)
{
    Vector<float, 2>  _S38 = Vector<float, 2> {(float)_slang_vector_get_element(slot_1, 0), (float)_slang_vector_get_element(slot_1, 1)};
    return _S38 + (Vector<float, 2> )0.5f + (hash22_0(slot_1, 1759714724U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.69999998807907104f;
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

static void convSlotBound_0(ConvectionInput_0 * c_4, Vector<int32_t, 2>  slot_2, Vector<float, 2>  a_1, Vector<float, 2>  b_0, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S39 = convVigour_0(c_4, slot_2);
    if(_S39 <= 0.0f)
    {
        return;
    }
    Vector<float, 2>  ctr_0 = convCellCentre_0(slot_2);
    Vector<float, 2>  _S40 = a_1 - ctr_0;
    Vector<float, 2>  nearGap_0 = max_1(max_1(_S40, ctr_0 - b_0), Vector<float, 2> (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    Vector<float, 2>  farGap_0 = max_1(abs_0(_S40), abs_0(b_0 - ctr_0));
    float oHi_0 = _S39 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S39 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S39 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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

static float convUpdraftBound_0(ConvectionInput_0 * c_5, Vector<float, 2>  q0_0, Vector<float, 2>  q1_0)
{
    Vector<float, 2>  a_2 = q0_0 / (Vector<float, 2> )c_5->cvSpacing_0;
    Vector<float, 2>  b_1 = q1_0 / (Vector<float, 2> )c_5->cvSpacing_0;
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    Vector<float, 2>  _S41 = floor_0((a_2 + b_1) * (Vector<float, 2> )0.5f);
    Vector<int32_t, 2>  _S42 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S41, 0), (int32_t)_slang_vector_get_element(_S41, 1)};
    Vector<float, 2>  _S43 = Vector<float, 2> {(float)_slang_vector_get_element(_S42, 0), (float)_slang_vector_get_element(_S42, 1)};
    Vector<float, 2>  highEdge_0 = _S43 + (Vector<float, 2> )1.0f + (Vector<float, 2> )0.00009999999747379f;
    bool _S44;
    if(all_0(a_2 >= (_S43 - (Vector<float, 2> )0.00009999999747379f)))
    {
        _S44 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S44 = false;
    }
    int32_t j_0;
    int32_t i_8;
    if(_S44)
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
            i_8 = int(-1);
            for(;;)
            {
                if(i_8 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_5, _S42 + Vector<int32_t, 2> (i_8, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_8 = i_8 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    else
    {
        Vector<float, 2>  _S45 = floor_0(a_2);
        Vector<int32_t, 2>  _S46 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S45, 0), (int32_t)_slang_vector_get_element(_S45, 1)};
        Vector<int32_t, 2>  _S47 = Vector<int32_t, 2> (int(1), int(1));
        Vector<int32_t, 2>  i0_0 = _S46 - _S47;
        Vector<float, 2>  _S48 = floor_0(b_1);
        Vector<int32_t, 2>  _S49 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S48, 0), (int32_t)_slang_vector_get_element(_S48, 1)};
        Vector<int32_t, 2>  _S50 = _S49 + _S47;
        int32_t _S51 = i0_0.y;
        j_0 = _S51;
        for(;;)
        {
            if(j_0 <= (_S50.y))
            {
                _S44 = j_0 <= (_S51 + int(32));
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
            int32_t _S52 = i0_0.x;
            i_8 = _S52;
            for(;;)
            {
                bool _S53;
                if(i_8 <= (_S50.x))
                {
                    _S53 = i_8 <= (_S52 + int(32));
                }
                else
                {
                    _S53 = false;
                }
                if(_S53)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_5, Vector<int32_t, 2> (i_8, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_8 = i_8 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    return lerp_1((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_5->cvPolarity_0) + 0.00000999999974738f;
}

static float convTowerHeight_0(ConvectionInput_0 * c_6, float w_0)
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

static float convNeededUpdraft_0(ConvectionInput_0 * c_7, float above_1)
{
    float cover_1 = clamp_1(c_7->cvCoverage_0, 0.0f, 1.0f);
    bool _S54;
    if(cover_1 <= 0.0f)
    {
        _S54 = true;
    }
    else
    {
        _S54 = (c_7->cvDepth_0) <= 0.0f;
    }
    if(_S54)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_7->cvDepth_0), (1.0f / (F32_max((c_7->cvShape_0), (0.00100000004749745f))))));
}

static float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S55;
    if(vMin_0 <= 0.0f)
    {
        _S55 = true;
    }
    else
    {
        _S55 = hMin_0 <= 0.0f;
    }
    if(_S55)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static float convHeroReach_0(ConvectionInput_0 * c_8)
{
    return c_8->cvHeroRadius_0 + 1.5f * c_8->cvBillow_0 * c_8->cvHeroBillow_0 + 24.0f;
}

static float convHeroHeight_0(ConvectionInput_0 * c_9, float r_2)
{
    float _S56 = c_9->cvHeroTop_0;
    bool _S57;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        _S57 = true;
    }
    else
    {
        _S57 = r_2 >= (c_9->cvHeroRadius_0);
    }
    if(_S57)
    {
        return 0.0f;
    }
    return _S56 * (F32_pow((1.0f - r_2 * r_2 / (c_9->cvHeroRadius_0 * c_9->cvHeroRadius_0)), (c_9->cvShape_0)));
}

static float convHeroRadiusAt_0(ConvectionInput_0 * c_10, float above_2)
{
    float _S58 = c_10->cvHeroTop_0;
    bool _S59;
    if((c_10->cvHeroTop_0) <= 0.0f)
    {
        _S59 = true;
    }
    else
    {
        _S59 = above_2 >= _S58;
    }
    if(_S59)
    {
        return -1.0f;
    }
    return c_10->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S58), (1.0f / (F32_max((c_10->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static float convectionBound_0(ConvectionInput_0 * c_11, Vector<float, 3>  lo_2, Vector<float, 3>  hi_2)
{
    float low_0 = lo_2.y - c_11->cvBase_0;
    float high_0 = hi_2.y - c_11->cvBase_0;
    float _S60 = convCeiling_0(c_11);
    bool _S61;
    if(high_0 < 0.0f)
    {
        _S61 = true;
    }
    else
    {
        _S61 = low_0 > _S60;
    }
    if(_S61)
    {
        return 0.0f;
    }
    float _S62 = (F32_max((low_0), (0.0f)));
    float _S63 = (F32_min((high_0), (_S60)));
    float _S64 = convLift_0(c_11, _S63, 1.0f);
    float inside_0;
    if((c_11->cvHeroAlone_0) == int(0))
    {
        float _S65 = convUpdraftBound_0(c_11, Vector<float, 2> {lo_2.x, lo_2.z} - c_11->cvDrift_0, Vector<float, 2> {hi_2.x, hi_2.z} - c_11->cvDrift_0);
        float _S66 = convTowerHeight_0(c_11, _S65);
        float _S67 = convNeededUpdraft_0(c_11, _S62);
        if(_S65 < _S67)
        {
            inside_0 = _S64 - convDistanceFloor_0(_S62 - _S66, (_S67 - _S65) / (7.0f / c_11->cvSpacing_0));
        }
        else
        {
            inside_0 = (F32_max((_S66 - _S62), (0.0f))) + _S64;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    if((c_11->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_0(max_1(max_1(Vector<float, 2> {lo_2.x, lo_2.z} - c_11->cvHeroAt_0, c_11->cvHeroAt_0 - Vector<float, 2> {hi_2.x, hi_2.z}), Vector<float, 2> (0.0f, 0.0f)));
        float _S68 = convHeroReach_0(c_11);
        if(rMin_0 < _S68)
        {
            float _S69 = convHeroHeight_0(c_11, rMin_0);
            float _S70 = convHeroRadiusAt_0(c_11, _S62);
            float _S71 = convLift_0(c_11, _S63, c_11->cvHeroBillow_0);
            bool _S72 = _S70 < 0.0f;
            if(_S72)
            {
                _S61 = true;
            }
            else
            {
                _S61 = rMin_0 >= _S70;
            }
            float heroIn_0;
            if(_S61)
            {
                if(_S72)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S70;
                }
                heroIn_0 = _S71 - convDistanceFloor_0(_S62 - _S69, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S69 - _S62), (0.0f))) + _S71;
            }
            inside_0 = (F32_max((inside_0), (heroIn_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return 0.0f;
    }
    return c_11->cvSigma_0 * (F32_sqrt((saturate_0(_S63 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1) * 1.00001001358032227f;
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_1, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_16 = clamp_1(depth_0 / g_1->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_9 = clamp_0(int32_t((F32_floor((x_16)))), int(0), int(31));
    return lerp_0(disp_0.Load(i_9), disp_0.Load(i_9 + int(1)), (Vector<float, 2> )(x_16 - float(i_9)));
}

static void driftRange_0(GeneratorInput_0 * g_2, StructuredBuffer<Vector<float, 2> > disp_1, float d0_0, float d1_0, Vector<float, 2>  * lo_3, Vector<float, 2>  * hi_3)
{
    Vector<float, 2>  _S73 = driftAt_0(g_2, disp_1, d0_0);
    *lo_3 = _S73;
    *hi_3 = _S73;
    Vector<float, 2>  _S74 = driftAt_0(g_2, disp_1, d1_0);
    *lo_3 = min_1(*lo_3, _S74);
    *hi_3 = max_1(*hi_3, _S74);
    int32_t _S75 = clamp_0(int32_t((F32_ceil((clamp_1(d1_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int32_t k_1 = clamp_0(int32_t((F32_floor((clamp_1(d0_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_1 <= _S75)
        {
        }
        else
        {
            break;
        }
        *lo_3 = min_1(*lo_3, disp_1.Load(k_1));
        *hi_3 = max_1(*hi_3, disp_1.Load(k_1));
        k_1 = k_1 + int(1);
    }
    return;
}

static float cellFieldBound_0(GeneratorInput_0 * g_3, Vector<float, 2>  q0_1, Vector<float, 2>  q1_1)
{
    float spacing_0 = g_3->cellSize_0 * 2.20000004768371582f;
    Vector<float, 2>  a_3 = (q0_1 - g_3->cellDrift_0) / (Vector<float, 2> )spacing_0;
    Vector<float, 2>  b_2 = (q1_1 - g_3->cellDrift_0) / (Vector<float, 2> )spacing_0;
    Vector<float, 2>  _S76 = floor_0(a_3);
    Vector<int32_t, 2>  _S77 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S76, 0), (int32_t)_slang_vector_get_element(_S76, 1)};
    Vector<int32_t, 2>  _S78 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  i0_1 = _S77 - _S78;
    Vector<float, 2>  _S79 = floor_0(b_2);
    Vector<int32_t, 2>  _S80 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S79, 0), (int32_t)_slang_vector_get_element(_S79, 1)};
    Vector<int32_t, 2>  _S81 = _S80 + _S78;
    int32_t _S82 = i0_1.y;
    int32_t j_1 = _S82;
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
        int32_t _S84 = i0_1.x;
        int32_t i_10 = _S84;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S85;
            if(i_10 <= (_S81.x))
            {
                _S85 = i_10 <= (_S84 + int(32));
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
            Vector<int32_t, 2>  o_1 = Vector<int32_t, 2> (i_10, j_1);
            if((hash22_0(o_1, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_10 = i_10 + int(1);
                continue;
            }
            Vector<float, 2>  _S86 = Vector<float, 2> {(float)_slang_vector_get_element(o_1, 0), (float)_slang_vector_get_element(o_1, 1)};
            Vector<float, 2>  c_12 = _S86 + (Vector<float, 2> )0.5f + (hash22_0(o_1, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_1(max_1(a_3 - c_12, c_12 - b_2), Vector<float, 2> (0.0f, 0.0f))) * 2.20000004768371582f);
            i_10 = i_10 + int(1);
        }
        j_1 = j_1 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static float iceDensityBound_0(GeneratorInput_0 * g_4, StructuredBuffer<Vector<float, 2> > disp_2, Vector<float, 3>  lo_4, Vector<float, 3>  hi_4)
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
    Vector<float, 2>  driftLo_0;
    Vector<float, 2>  driftHi_0;
    driftRange_0(g_4, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S89 = cellFieldBound_0(g_4, Vector<float, 2> (lo_4.x, lo_4.z) - driftHi_0, Vector<float, 2> (hi_4.x, hi_4.z) - driftLo_0);
    return (F32_max((_S89 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((_S88), (1.0f)));
}

static float mediumBound_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_3, Vector<float, 3>  lo_5, Vector<float, 3>  hi_5)
{
    int32_t _S90 = m_1->mode_0;
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

static float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_1, StructuredBuffer<Vector<float, 2> > disp_4, Vector<int32_t, 3>  c_13, float fallback_0)
{
    int32_t _S93 = g_5->enabled_0;
    if((g_5->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S93 == int(2))
    {
        Vector<float, 3>  _S94 = Vector<float, 3> {(float)_slang_vector_get_element(c_13, 0), (float)_slang_vector_get_element(c_13, 1), (float)_slang_vector_get_element(c_13, 2)};
        Vector<float, 3>  lo_6 = g_5->origin_0 + _S94 * g_5->cellExtent_0;
        float _S95 = mediumBound_0(m_2, disp_4, lo_6, lo_6 + g_5->cellExtent_0);
        return _S95;
    }
    int32_t _S96 = c_13.x;
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
    return bounds_1.Load((c_13.z * g_5->dims_0.y + c_13.y) * g_5->dims_0.x + _S96);
}

static float ddaExit_0(Dda_0 * d_2)
{
    return (F32_min((d_2->tMax_0.x), ((F32_min((d_2->tMax_0.y), (d_2->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_3)
{
    bool _S98;
    if((d_3->tMax_0.x) <= (d_3->tMax_0.y))
    {
        _S98 = (d_3->tMax_0.x) <= (d_3->tMax_0.z);
    }
    else
    {
        _S98 = false;
    }
    if(_S98)
    {
        d_3->cell_0.x = d_3->cell_0.x + d_3->stepDir_0.x;
        d_3->tMax_0.x = d_3->tMax_0.x + d_3->tDelta_0.x;
    }
    else
    {
        if((d_3->tMax_0.y) <= (d_3->tMax_0.z))
        {
            d_3->cell_0.y = d_3->cell_0.y + d_3->stepDir_0.y;
            d_3->tMax_0.y = d_3->tMax_0.y + d_3->tDelta_0.y;
        }
        else
        {
            d_3->cell_0.z = d_3->cell_0.z + d_3->stepDir_0.z;
            d_3->tMax_0.z = d_3->tMax_0.z + d_3->tDelta_0.z;
        }
    }
    return;
}

static float cellField_0(GeneratorInput_0 * g_6, Vector<float, 2>  q_0)
{
    Vector<float, 2>  gq_0 = (q_0 - g_6->cellDrift_0) / (Vector<float, 2> )(g_6->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_0(gq_0);
    Vector<int32_t, 2>  _S99 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
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
        int32_t i_11 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_11 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_2 = _S99 + Vector<int32_t, 2> (i_11, j_2);
            if((hash22_0(o_2, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_11 = i_11 + int(1);
                continue;
            }
            Vector<float, 2>  _S100 = Vector<float, 2> {(float)_slang_vector_get_element(o_2, 0), (float)_slang_vector_get_element(o_2, 1)};
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(gq_0 - (_S100 + (Vector<float, 2> )0.5f + (hash22_0(o_2, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f)) * 2.20000004768371582f);
            i_11 = i_11 + int(1);
        }
        j_2 = j_2 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_6->cellStrength_0;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_1)
{
    Vector<uint32_t, 3>  _S101 = v_1 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S102 = _S101;
    _S102.x = _S102.x + _S101.y * _S101.z;
    _S102.y = _S102.y + _S102.z * _S102.x;
    _S102.z = _S102.z + _S102.x * _S102.y;
    Vector<uint32_t, 3>  _S103 = _S102 ^ (_S102 >> ((Vector<uint32_t, 3> )16U));
    _S102 = _S103;
    _S102.x = _S102.x + _S103.y * _S103.z;
    _S102.y = _S102.y + _S102.z * _S102.x;
    _S102.z = _S102.z + _S102.x * _S102.y;
    return _S102;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_14)
{
    Vector<uint32_t, 3>  h_2 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_14.x), uint32_t(c_14.y), uint32_t(c_14.z)));
    Vector<float, 3>  _S104 = Vector<float, 3> {(float)_slang_vector_get_element(h_2, 0), (float)_slang_vector_get_element(h_2, 1), (float)_slang_vector_get_element(h_2, 2)};
    return _S104 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float gradientNoise_0(Vector<float, 3>  p_1)
{
    Vector<float, 3>  fi_0 = floor_1(p_1);
    Vector<int32_t, 3>  _S105 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_1 - fi_0;
    Vector<float, 3>  u_2 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S106 = u_2.x;
    float _S107 = u_2.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S105), f_0), dot_0(hash33_0(_S105 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S106), lerp_1(dot_0(hash33_0(_S105 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S105 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S106), _S107), lerp_1(lerp_1(dot_0(hash33_0(_S105 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S105 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S106), lerp_1(dot_0(hash33_0(_S105 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S105 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S106), _S107), u_2.z);
}

static float fbm_0(Vector<float, 3>  p_2, int32_t octaves_1)
{
    int32_t i_12 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S108 = p_2;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_12 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_12 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S108);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S109 = _S108 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_12 = i_12 + int(1);
        amp_0 = amp_1;
        _S108 = _S109;
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
    bool _S110;
    if(depth_1 < 0.0f)
    {
        _S110 = true;
    }
    else
    {
        _S110 = depth_1 > (g_7->streakLength_0);
    }
    if(_S110)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S111 = Vector<float, 2> {p_3.x, p_3.z};
    Vector<float, 2>  _S112 = driftAt_0(g_7, disp_5, depth_1);
    Vector<float, 2>  source_0 = _S111 - _S112;
    float _S113 = cellField_0(g_7, source_0);
    if(_S113 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S113 * (F32_exp((- g_7->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, depth_1)) * (F32_max((1.0f + g_7->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_7->detailScale_0).x, (source_0 / (Vector<float, 2> )g_7->detailScale_0).y, depth_1 / (F32_max((g_7->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_7->timeSeconds_0 * 0.00999999977648258f), g_7->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((g_7->streakLength_0), (1.0f)));
}

static float convUpdraftGrad_0(ConvectionInput_0 * c_15, Vector<float, 2>  q_1, Vector<float, 2>  * grad_0)
{
    Vector<float, 2>  goTop_0;
    float _S114 = c_15->cvSpacing_0;
    Vector<float, 2>  g_8 = q_1 / (Vector<float, 2> )c_15->cvSpacing_0;
    Vector<float, 2>  _S115 = floor_0(g_8);
    Vector<int32_t, 2>  _S116 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S115, 0), (int32_t)_slang_vector_get_element(_S115, 1)};
    Vector<float, 2>  _S117 = Vector<float, 2> (0.0f, 0.0f);
    float oTop_0 = 0.0f;
    Vector<float, 2>  goTop_1 = _S117;
    float oNext_0 = 0.0f;
    float kTop_0 = 0.0f;
    Vector<float, 2>  gkTop_0 = _S117;
    float kNext_0 = 0.0f;
    Vector<float, 2>  goNext_0 = _S117;
    Vector<float, 2>  gkNext_0 = _S117;
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
        goTop_0 = goTop_1;
        float oNext_1 = oNext_0;
        float kTop_1 = kTop_0;
        Vector<float, 2>  gkTop_1 = gkTop_0;
        float kNext_1 = kNext_0;
        Vector<float, 2>  goNext_1 = goNext_0;
        Vector<float, 2>  gkNext_1 = gkNext_0;
        int32_t i_13 = int(-1);
        for(;;)
        {
            if(i_13 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_3 = _S116 + Vector<int32_t, 2> (i_13, j_3);
            float _S118 = convVigour_0(c_15, slot_3);
            if(_S118 <= 0.0f)
            {
                i_13 = i_13 + int(1);
                continue;
            }
            Vector<float, 2>  d_4 = g_8 - convCellCentre_0(slot_3);
            float d2_1 = dot_1(d_4, d_4);
            float ko_0 = _S118 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S118 * convBump_0(d2_1, 1.04999995231628418f);
            Vector<float, 2>  gko_0;
            if(d2_1 < 0.5625f)
            {
                gko_0 = d_4 * (Vector<float, 2> )(-4.0f * _S118 * (1.0f - d2_1 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S117;
            }
            Vector<float, 2>  gkk_0;
            if(d2_1 < 1.10249984264373779f)
            {
                gkk_0 = d_4 * (Vector<float, 2> )(-4.0f * _S118 * (1.0f - d2_1 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S117;
            }
            float oTop_2;
            float oNext_2;
            Vector<float, 2>  goTop_2;
            Vector<float, 2>  goNext_2;
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
                float _S119 = oTop_2;
                Vector<float, 2>  _S120 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S119;
                goNext_2 = _S120;
            }
            float kTop_2;
            float kNext_2;
            Vector<float, 2>  gkTop_2;
            Vector<float, 2>  gkNext_2;
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
                float _S121 = kTop_2;
                Vector<float, 2>  _S122 = gkTop_2;
                kTop_2 = kTop_1;
                gkTop_2 = gkTop_1;
                kNext_2 = _S121;
                gkNext_2 = _S122;
            }
            oTop_1 = oTop_2;
            goTop_0 = goTop_2;
            oNext_1 = oNext_2;
            kTop_1 = kTop_2;
            gkTop_1 = gkTop_2;
            kNext_1 = kNext_2;
            goNext_1 = goNext_2;
            gkNext_1 = gkNext_2;
            i_13 = i_13 + int(1);
        }
        int32_t j_4 = j_3 + int(1);
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
    float _S123 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_0 - kNext_0;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / (Vector<float, 2> )0.31000000238418579f;
    }
    else
    {
        goTop_0 = _S117;
    }
    float _S124 = c_15->cvPolarity_0;
    *grad_0 = lerp_0(goTop_0, gkTop_0 - gkNext_0, (Vector<float, 2> )c_15->cvPolarity_0) / (Vector<float, 2> )_S114;
    return lerp_1(_S123, closedField_0, _S124);
}

static float convSurfaceDistance_0(float v_2, float delta_0, float slope_0)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_0 * slope_0 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_5 = num_0 / den_0;
    float _S125;
    if(v_2 >= 0.0f)
    {
        _S125 = d_5;
    }
    else
    {
        _S125 = - d_5;
    }
    return _S125;
}

static Vector<float, 3>  convTwist_0(Vector<float, 3>  x_17)
{
    float _S126 = x_17.x;
    float _S127 = x_17.y;
    float _S128 = x_17.z;
    return Vector<float, 3> (0.0f * _S126 + 0.80000001192092896f * _S127 + 0.60000002384185791f * _S128, -0.80000001192092896f * _S126 + 0.36000001430511475f * _S127 - 0.47999998927116394f * _S128, -0.60000002384185791f * _S126 - 0.47999998927116394f * _S127 + 0.63999998569488525f * _S128);
}

static float convPuffs_0(Vector<float, 3>  x_18)
{
    Vector<float, 3>  fl_0 = floor_1(x_18);
    Vector<int32_t, 3>  _S129 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fl_0, 0), (int32_t)_slang_vector_get_element(fl_0, 1), (int32_t)_slang_vector_get_element(fl_0, 2)};
    Vector<float, 3>  f_1 = x_18 - fl_0;
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
    Vector<int32_t, 3>  _S130 = Vector<int32_t, 3> (dz_0, dy_0, dx_0);
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
                Vector<int32_t, 3>  off_0 = _S130 + Vector<int32_t, 3> (dx_0, dy_0, dz_0);
                Vector<float, 3>  _S131 = Vector<float, 3> {(float)_slang_vector_get_element(off_0, 0), (float)_slang_vector_get_element(off_0, 1), (float)_slang_vector_get_element(off_0, 2)};
                Vector<float, 3>  d_6 = _S131 + (Vector<float, 3> )0.5f + (Vector<float, 3> )0.25f * hash33_0(_S129 + off_0) - f_1;
                float _S132 = (F32_min((nearest_1), (dot_0(d_6, d_6))));
                int32_t dx_1 = dx_0 + int(1);
                nearest_1 = _S132;
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

static float convBillow_0(ConvectionInput_0 * c_16, Vector<float, 3>  p_4, float scale_0)
{
    Vector<float, 3>  _S133 = Vector<float, 3> (p_4.x, p_4.y - c_16->cvRise_0, p_4.z) / (Vector<float, 3> )scale_0;
    int32_t i_14 = int(0);
    Vector<float, 3>  x_19 = _S133;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_14 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_14 >= (c_16->cvOctaves_0))
        {
            break;
        }
        Vector<float, 3>  x_20 = convTwist_0(x_19);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_20);
        float norm_3 = norm_2 + amp_2;
        Vector<float, 3>  x_21 = x_20 * (Vector<float, 3> )2.17000007629394531f;
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_14 = i_14 + int(1);
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

static float convInside_0(ConvectionInput_0 * c_17, float d_7, float lift_0, Vector<float, 3>  x_22, float scale_1)
{
    float _S134 = d_7 + lift_0;
    if(_S134 <= 0.0f)
    {
        return _S134;
    }
    if((d_7 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S135 = convBillow_0(c_17, x_22, scale_1);
    return d_7 + lift_0 * _S135;
}

static float convHeroInside_0(ConvectionInput_0 * c_18, Vector<float, 3>  p_5, float above_3)
{
    Vector<float, 2>  rel_0 = Vector<float, 2> {p_5.x, p_5.z} - c_18->cvHeroAt_0;
    float r_3 = length_0(rel_0);
    float _S136 = convHeroReach_0(c_18);
    if(r_3 >= _S136)
    {
        return -1.00000001504746622e+30f;
    }
    float _S137 = convHeroHeight_0(c_18, r_3);
    float v_3 = _S137 - above_3;
    float _S138 = convHeroRadiusAt_0(c_18, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_8;
    if(_S138 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_8 = v_3;
    }
    else
    {
        float h_3 = _S138 - r_3;
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
        float _S139 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S139;
        d_8 = d_9;
    }
    Vector<float, 2>  radial_0;
    if(r_3 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / (Vector<float, 2> )r_3;
    }
    else
    {
        radial_0 = Vector<float, 2> (0.0f, 0.0f);
    }
    Vector<float, 2>  at_0 = rel_0 + radial_0 * (Vector<float, 2> )shiftOut_0;
    Vector<float, 3>  x_23 = Vector<float, 3> (at_0.x, p_5.y + shiftUp_0, at_0.y) + c_18->cvHeroSeed_0;
    float _S140 = c_18->cvHeroBillow_0;
    float _S141 = convLift_0(c_18, above_3, c_18->cvHeroBillow_0);
    float _S142 = convInside_0(c_18, d_8, _S141, x_23, c_18->cvBillowScale_0 * _S140);
    return _S142;
}

static float convectionDensity_0(ConvectionInput_0 * c_19, Vector<float, 3>  p_6)
{
    float _S143 = p_6.y;
    float above_4 = _S143 - c_19->cvBase_0;
    bool _S144;
    if(above_4 < 0.0f)
    {
        _S144 = true;
    }
    else
    {
        float _S145 = convCeiling_0(c_19);
        _S144 = above_4 > _S145;
    }
    if(_S144)
    {
        return 0.0f;
    }
    float _S146 = convLift_0(c_19, above_4, 1.0f);
    float inside_2;
    if((c_19->cvHeroAlone_0) == int(0))
    {
        Vector<float, 2>  q_2 = Vector<float, 2> {p_6.x, p_6.z} - c_19->cvDrift_0;
        Vector<float, 2>  slope_1;
        float _S147 = convUpdraftGrad_0(c_19, q_2, &slope_1);
        float _S148 = convTowerHeight_0(c_19, _S147);
        float v_4 = _S148 - above_4;
        float _S149 = convNeededUpdraft_0(c_19, above_4);
        float delta_1 = _S147 - _S149;
        float d_10 = convSurfaceDistance_0(v_4, delta_1, length_0(slope_1));
        if((d_10 + _S146) > 0.0f)
        {
            if((F32_abs((v_4))) > 9.99999997475242708e-07f)
            {
                inside_2 = d_10 * (d_10 / v_4);
            }
            else
            {
                inside_2 = 0.0f;
            }
            Vector<float, 2>  shiftAcross_0;
            if((F32_abs((delta_1))) > 9.999999960041972e-13f)
            {
                shiftAcross_0 = slope_1 * (Vector<float, 2> )(- d_10 * (d_10 / delta_1));
            }
            else
            {
                shiftAcross_0 = Vector<float, 2> (0.0f, 0.0f);
            }
            float _S150 = convInside_0(c_19, d_10, _S146, Vector<float, 3> (q_2.x + shiftAcross_0.x, _S143 + inside_2, q_2.y + shiftAcross_0.y), c_19->cvBillowScale_0);
            inside_2 = _S150;
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
        _S144 = inside_2 < 12.0f;
    }
    else
    {
        _S144 = false;
    }
    if(_S144)
    {
        float _S151 = convHeroInside_0(c_19, p_6, above_4);
        inside_2 = (F32_max((inside_2), (_S151)));
    }
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_19->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2);
}

static float densityAt_0(Medium_0 * m_3, StructuredBuffer<Vector<float, 2> > disp_6, Vector<float, 3>  p_7)
{
    float _S152 = p_7.y;
    bool _S153;
    if(_S152 < (m_3->slabBottom_0))
    {
        _S153 = true;
    }
    else
    {
        _S153 = _S152 > (m_3->slabTop_0);
    }
    if(_S153)
    {
        return 0.0f;
    }
    if((m_3->clipOn_0) != int(0))
    {
        Vector<float, 2>  _S154 = Vector<float, 2> {p_7.x, p_7.z};
        if(any_0(_S154 < (m_3->clipLo_0)))
        {
            _S153 = true;
        }
        else
        {
            _S153 = any_0(_S154 > (m_3->clipHi_0));
        }
    }
    else
    {
        _S153 = false;
    }
    if(_S153)
    {
        return 0.0f;
    }
    float _S155 = m_3->fadeRadius_0;
    float fade_0;
    if((m_3->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S155 - length_0(Vector<float, 2> {p_7.x, p_7.z} - m_3->fadeAt_0)) / (F32_max((m_3->fadeWidth_0), (1.0f))));
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
    int32_t _S156 = m_3->mode_0;
    if((m_3->mode_0) == int(0))
    {
        return m_3->density_0 * fade_0;
    }
    if(_S156 == int(2))
    {
        float _S157 = iceDensity_0(&m_3->gen_0, disp_6, p_7);
        return _S157 * fade_0;
    }
    if(_S156 == int(3))
    {
        float _S158 = convectionDensity_0(&m_3->conv_0, p_7);
        return _S158 * fade_0;
    }
    Vector<float, 3>  d_11 = (p_7 - m_3->coreCentre_0) / (Vector<float, 3> )(F32_max((m_3->coreRadius_0), (9.99999997475242708e-07f)));
    return (m_3->density_0 + m_3->coreDensity_0 * (F32_exp((- dot_0(d_11, d_11))))) * fade_0;
}

static float transmittance_0(Medium_0 * m_4, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > disp_7, Rng_0 * rng_1, Vector<float, 3>  p_8, Vector<float, 3>  dir_0, int32_t * steps_0)
{
    float t0_2;
    float t1_2;
    bool _S159 = slabRange_0(m_4, p_8, dir_0, &t0_2, &t1_2);
    if(!_S159)
    {
        return 1.0f;
    }
    float _S160 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S160;
    Dda_0 _S161 = ddaInit_0(g_9, p_8, dir_0, _S160);
    Dda_0 dda_0 = _S161;
    float _S162 = m_4->majorant_0;
    float _S163 = gridBound_0(m_4, g_9, bounds_2, disp_7, (&dda_0)->cell_0, m_4->majorant_0);
    float localMaj_0 = _S163;
    int32_t i_15 = int(0);
    float t_2 = _S160;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_15 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S164 = dda_0;
        float _S165 = ddaExit_0(&_S164);
        float _S166 = (F32_min((_S165), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S166 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S167 = gridBound_0(m_4, g_9, bounds_2, disp_7, (&dda_0)->cell_0, _S162);
            localMaj_0 = _S167;
            t_2 = _S166;
            i_15 = i_15 + int(1);
            continue;
        }
        float _S168 = randFloat_0(rng_1);
        float t_3 = t_2 - (F32_log(((F32_max((1.0f - _S168), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_3 >= _S166)
        {
            if(_S166 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S169 = gridBound_0(m_4, g_9, bounds_2, disp_7, (&dda_0)->cell_0, _S162);
            localMaj_0 = _S169;
            t_2 = _S166;
            i_15 = i_15 + int(1);
            continue;
        }
        float _S170 = densityAt_0(m_4, disp_7, p_8 + dir_0 * (Vector<float, 3> )t_3);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S170 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S171 = randFloat_0(rng_1);
            if(_S171 > 0.5f)
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
        i_15 = i_15 + int(1);
    }
    return tr_0;
}

void _cpuTransmittanceTrial(void* _S172, void* entryPointParams_1, void* _S173)
{
    ComputeThreadVaryingInput * _S174 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S172));
    int32_t i_16 = int32_t((_S174->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S174->groupThreadID).x);
    if(i_16 >= ((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->count_1))
    {
        return;
    }
    Rng_0 rng_2 = makeRngForIndex_0((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->seed_1, i_16);
    int32_t steps_1 = int(0);
    float * _S175 = (&((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->output_1)[i_16]);
    float _S176 = transmittance_0(&(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->medium_0, &(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->grid_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->bounds_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->drift_0, &rng_2, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->origin_1, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->direction_0, &steps_1);
    *_S175 = _S176;
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
