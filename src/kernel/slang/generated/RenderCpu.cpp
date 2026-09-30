// GENERATED FROM RenderCpu.slang BY slangc -- DO NOT EDIT.
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
    Vector<float, 3>  uniformRadiance_0;
    SkyInput_0 sky_0;
    int32_t envMode_0;
};

struct PhaseInput_0
{
    float hgG_0;
    float draineG_0;
    float draineAlpha_0;
    float draineW_0;
    int32_t useIce_0;
    float lobeG_0;
    float lobeWeight_0;
};

struct Scene_0
{
    Medium_0 medium_0;
    MajorantGrid_0 grid_0;
    Environment_0 environment_0;
    Vector<float, 3>  albedo_0;
    Vector<float, 3>  sunIrradiance_0;
    Vector<float, 3>  sunDir_0;
    float shadowOffset_0;
    int32_t maxBounces_0;
    int32_t rrStartBounce_0;
    float neeTentativeScale_0;
    int32_t aerialMode_0;
    int32_t layer2On_0;
    Medium_0 medium2_0;
    MajorantGrid_0 grid2_0;
    Vector<float, 3>  albedo2_0;
    PhaseInput_0 phase2_0;
};

struct AirSegment_0
{
    Vector<float, 3>  airIn_0;
    Vector<float, 3>  airT_0;
    float shadowAt_0;
};

struct TraceResult_0
{
    Vector<float, 3>  pathRadiance_0;
    int32_t scatterEvents_0;
    int32_t capped_0;
    int32_t trackingSteps_0;
};

struct EntryPointParams_0
{
    Scene_0 scene_0;
    PhaseInput_0 phase_0;
    StructuredBuffer<float> bounds_0;
    StructuredBuffer<Vector<float, 2> > drift_0;
    StructuredBuffer<Vector<float, 3> > origins_0;
    StructuredBuffer<Vector<float, 3> > directions_0;
    RWStructuredBuffer<Vector<float, 3> > outRadiance_0;
    uint32_t seed_0;
    int32_t count_0;
};

static Vector<float, 3>  cross_0(Vector<float, 3>  left_0, Vector<float, 3>  right_0)
{
    float _S1 = left_0.y;
    float _S2 = right_0.z;
    float _S3 = left_0.z;
    float _S4 = right_0.y;
    float _S5 = right_0.x;
    float _S6 = left_0.x;
    return Vector<float, 3> (_S1 * _S2 - _S3 * _S4, _S3 * _S5 - _S6 * _S2, _S6 * _S4 - _S1 * _S5);
}

static float dot_0(Vector<float, 3>  x_0, Vector<float, 3>  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y + x_0.z * y_0.z;
}

static float length_0(Vector<float, 3>  x_1)
{
    return (F32_sqrt((dot_0(x_1, x_1))));
}

static Vector<float, 3>  normalize_0(Vector<float, 3>  x_2)
{
    return x_2 / (Vector<float, 3> )length_0(x_2);
}

static int32_t StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    Vector<uint32_t, 2>  _S7 = uint2(_elementCount_0, _stride_0);
    return int32_t(_S7.x);
}

static bool any_0(Vector<bool, 2>  x_3)
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
            result_0 = (bool((_slang_vector_get_element(x_3, i_0))));
        }
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static Vector<float, 2>  lerp_0(Vector<float, 2>  x_4, Vector<float, 2>  y_1, Vector<float, 2>  s_0)
{
    return x_4 + (y_1 - x_4) * s_0;
}

static int32_t clamp_0(int32_t x_5, int32_t minBound_0, int32_t maxBound_0)
{
    return (I32_min(((I32_max((x_5), (minBound_0)))), (maxBound_0)));
}

static float dot_1(Vector<float, 2>  x_6, Vector<float, 2>  y_2)
{
    return x_6.x * y_2.x + x_6.y * y_2.y;
}

static float length_1(Vector<float, 2>  x_7)
{
    return (F32_sqrt((dot_1(x_7, x_7))));
}

static float clamp_1(float x_8, float minBound_1, float maxBound_1)
{
    return (F32_min(((F32_max((x_8), (minBound_1)))), (maxBound_1)));
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

static bool all_0(Vector<bool, 2>  x_10)
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
            result_2 = (bool((_slang_vector_get_element(x_10, i_2))));
        }
        else
        {
            result_2 = false;
        }
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static Vector<float, 2>  floor_0(Vector<float, 2>  x_11)
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
        result_3[i_3] = (F32_floor((_slang_vector_get_element(x_11, i_3))));
        i_3 = i_3 + int(1);
    }
    return result_3;
}

static float lerp_1(float x_12, float y_3, float s_1)
{
    return x_12 + (y_3 - x_12) * s_1;
}

static float saturate_0(float x_13)
{
    return clamp_1(x_13, 0.0f, 1.0f);
}

static float smoothstep_0(float min_0, float max_0, float x_14)
{
    float _S8 = saturate_0((x_14 - min_0) / (max_0 - min_0));
    return _S8 * _S8 * (3.0f - (_S8 + _S8));
}

static Vector<float, 3>  floor_1(Vector<float, 3>  x_15)
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
        result_4[i_4] = (F32_floor((_slang_vector_get_element(x_15, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static Vector<float, 2>  min_1(Vector<float, 2>  x_16, Vector<float, 2>  y_4)
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
        result_5[i_5] = (F32_min((_slang_vector_get_element(x_16, i_5)), (_slang_vector_get_element(y_4, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
}

static Vector<float, 2>  max_1(Vector<float, 2>  x_17, Vector<float, 2>  y_5)
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
        result_6[i_6] = (F32_max((_slang_vector_get_element(x_17, i_6)), (_slang_vector_get_element(y_5, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_6;
}

static Rng_0 makeRng_0(uint32_t seed_1)
{
    Rng_0 r_0;
    (&r_0)->state_0 = seed_1;
    return r_0;
}

static Rng_0 splitRng_0(Rng_0 * r_1, uint32_t salt_0)
{
    uint32_t s_2 = ((r_1->state_0) ^ (salt_0 * 2654435761U)) * 747796405U + 2891336453U;
    uint32_t s_3 = ((s_2 >> ((s_2 >> 28U) + 4U)) ^ s_2) * 277803737U;
    return makeRng_0((s_3 >> 22U) ^ s_3);
}

static bool clipAxis_0(float o_0, float d_0, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_0))) < 9.99999971718068537e-10f)
    {
        bool _S9;
        if(o_0 >= lo_0)
        {
            _S9 = o_0 <= hi_0;
        }
        else
        {
            _S9 = false;
        }
        return _S9;
    }
    float ta_0 = (lo_0 - o_0) / d_0;
    float tb_0 = (hi_0 - o_0) / d_0;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S10 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S10;
    return _S10 > (*t0_0);
}

static bool slabRange_0(Medium_0 * m_0, Vector<float, 3>  ro_0, Vector<float, 3>  rd_0, float * t0_1, float * t1_1)
{
    *t0_1 = 0.0f;
    *t1_1 = 1.0e+09f;
    float _S11 = rd_0.y;
    bool _S12;
    if((F32_abs((_S11))) < 9.99999997475242708e-07f)
    {
        float _S13 = ro_0.y;
        if(_S13 < (m_0->slabBottom_0))
        {
            _S12 = true;
        }
        else
        {
            _S12 = _S13 > (m_0->slabTop_0);
        }
        if(_S12)
        {
            return false;
        }
    }
    else
    {
        float _S14 = ro_0.y;
        float ta_1 = (m_0->slabBottom_0 - _S14) / _S11;
        float tb_1 = (m_0->slabTop_0 - _S14) / _S11;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S15 = (m_0->clipOn_0) != int(0);
    Vector<float, 2>  lo_1;
    if(_S15)
    {
        lo_1 = m_0->clipLo_0;
    }
    else
    {
        lo_1 = Vector<float, 2> (-1.0e+09f, -1.0e+09f);
    }
    Vector<float, 2>  hi_1;
    if(_S15)
    {
        hi_1 = m_0->clipHi_0;
    }
    else
    {
        hi_1 = Vector<float, 2> (1.0e+09f, 1.0e+09f);
    }
    float _S16 = m_0->fadeRadius_0;
    if((m_0->fadeRadius_0) > 0.0f)
    {
        Vector<float, 2>  _S17 = min_1(hi_1, m_0->fadeAt_0 + (Vector<float, 2> )_S16);
        lo_1 = max_1(lo_1, m_0->fadeAt_0 - (Vector<float, 2> )_S16);
        hi_1 = _S17;
    }
    bool _S18 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S18)
    {
        return false;
    }
    bool _S19 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S19)
    {
        return false;
    }
    float _S20 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S20;
    if(_S20 > (*t0_1))
    {
        _S12 = (*t1_1) > 0.0f;
    }
    else
    {
        _S12 = false;
    }
    return _S12;
}

static Dda_0 ddaInit_0(MajorantGrid_0 * g_0, Vector<float, 3>  ro_1, Vector<float, 3>  rd_1, float t_0)
{
    Dda_0 d_1;
    if((g_0->enabled_0) == int(0))
    {
        Vector<int32_t, 3>  _S21 = Vector<int32_t, 3> (int(0), int(0), int(0));
        (&d_1)->cell_0 = _S21;
        (&d_1)->stepDir_0 = _S21;
        Vector<float, 3>  _S22 = Vector<float, 3> (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_1)->tMax_0 = _S22;
        (&d_1)->tDelta_0 = _S22;
        return d_1;
    }
    Vector<float, 3>  p_0 = ro_1 + rd_1 * (Vector<float, 3> )t_0;
    Vector<float, 3>  _S23 = floor_1((p_0 - g_0->origin_0) / g_0->cellExtent_0);
    Vector<int32_t, 3>  _S24 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(_S23, 0), (int32_t)_slang_vector_get_element(_S23, 1), (int32_t)_slang_vector_get_element(_S23, 2)};
    (&d_1)->cell_0 = _S24;
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
        int32_t _S25 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            (&d_1)->stepDir_0[a_0] = int(0);
            (&d_1)->tMax_0[a_0] = 1.00000001504746622e+30f;
            (&d_1)->tDelta_0[a_0] = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S26 = _slang_vector_get_element(rd_1, _S25) > 0.0f;
            int32_t _S27;
            if(_S26)
            {
                _S27 = int(1);
            }
            else
            {
                _S27 = int(-1);
            }
            (&d_1)->stepDir_0[a_0] = _S27;
            float _S28 = g_0->origin_0[a_0];
            float _S29 = float((&d_1)->cell_0[a_0]);
            float _S30;
            if(_S26)
            {
                _S30 = 1.0f;
            }
            else
            {
                _S30 = 0.0f;
            }
            (&d_1)->tMax_0[a_0] = t_0 + (_S28 + (_S29 + _S30) * g_0->cellExtent_0[a_0] - _slang_vector_get_element(p_0, a_0)) / _slang_vector_get_element(rd_1, _S25);
            (&d_1)->tDelta_0[a_0] = (F32_abs((g_0->cellExtent_0[a_0] / _slang_vector_get_element(rd_1, _S25))));
        }
        a_0 = a_0 + int(1);
    }
    return d_1;
}

static float convCeiling_0(ConvectionInput_0 * c_0)
{
    float _S31 = c_0->cvBillow_0;
    float field_0 = c_0->cvDepth_0 + c_0->cvBillow_0;
    float _S32 = c_0->cvHeroTop_0;
    float hero_0;
    if((c_0->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S32 + _S31 * c_0->cvHeroBillow_0;
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
    Vector<uint32_t, 2>  _S33 = v_0 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S34 = _S33;
    _S34.x = _S34.x + _S33.y * 1664525U;
    _S34.y = _S34.y + _S34.x * 1664525U;
    Vector<uint32_t, 2>  _S35 = _S34 ^ (_S34 >> ((Vector<uint32_t, 2> )16U));
    _S34 = _S35;
    _S34.x = _S34.x + _S35.y * 1664525U;
    _S34.y = _S34.y + _S34.x * 1664525U;
    Vector<uint32_t, 2>  _S36 = _S34 ^ (_S34 >> ((Vector<uint32_t, 2> )16U));
    _S34 = _S36;
    return _S36;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_2, uint32_t salt_1)
{
    Vector<uint32_t, 2>  h_0 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_2.x), uint32_t(c_2.y)) ^ Vector<uint32_t, 2> (salt_1, salt_1 * 2654435761U));
    Vector<float, 2>  _S37 = Vector<float, 2> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1)};
    return _S37 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float convLife_0(float u_0)
{
    float _S38 = 1.0f - u_0;
    return 6.75f * u_0 * _S38 * _S38;
}

static float convVigour_0(ConvectionInput_0 * c_3, Vector<int32_t, 2>  slot_0)
{
    Vector<float, 2>  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_3->cvAge_0 + h_1.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_1.y);
}

static Vector<float, 2>  convCellCentre_0(Vector<int32_t, 2>  slot_1)
{
    Vector<float, 2>  _S39 = Vector<float, 2> {(float)_slang_vector_get_element(slot_1, 0), (float)_slang_vector_get_element(slot_1, 1)};
    return _S39 + (Vector<float, 2> )0.5f + (hash22_0(slot_1, 1759714724U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.69999998807907104f;
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
    float _S40 = convVigour_0(c_4, slot_2);
    if(_S40 <= 0.0f)
    {
        return;
    }
    Vector<float, 2>  ctr_0 = convCellCentre_0(slot_2);
    Vector<float, 2>  _S41 = a_1 - ctr_0;
    Vector<float, 2>  nearGap_0 = max_1(max_1(_S41, ctr_0 - b_0), Vector<float, 2> (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    Vector<float, 2>  farGap_0 = max_1(abs_0(_S41), abs_0(b_0 - ctr_0));
    float oHi_0 = _S40 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S40 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S40 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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
    Vector<float, 2>  _S42 = floor_0((a_2 + b_1) * (Vector<float, 2> )0.5f);
    Vector<int32_t, 2>  _S43 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S42, 0), (int32_t)_slang_vector_get_element(_S42, 1)};
    Vector<float, 2>  _S44 = Vector<float, 2> {(float)_slang_vector_get_element(_S43, 0), (float)_slang_vector_get_element(_S43, 1)};
    Vector<float, 2>  highEdge_0 = _S44 + (Vector<float, 2> )1.0f + (Vector<float, 2> )0.00009999999747379f;
    bool _S45;
    if(all_0(a_2 >= (_S44 - (Vector<float, 2> )0.00009999999747379f)))
    {
        _S45 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S45 = false;
    }
    int32_t j_0;
    int32_t i_7;
    if(_S45)
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
                convSlotBound_0(c_5, _S43 + Vector<int32_t, 2> (i_7, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_7 = i_7 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    else
    {
        Vector<float, 2>  _S46 = floor_0(a_2);
        Vector<int32_t, 2>  _S47 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S46, 0), (int32_t)_slang_vector_get_element(_S46, 1)};
        Vector<int32_t, 2>  _S48 = Vector<int32_t, 2> (int(1), int(1));
        Vector<int32_t, 2>  i0_0 = _S47 - _S48;
        Vector<float, 2>  _S49 = floor_0(b_1);
        Vector<int32_t, 2>  _S50 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S49, 0), (int32_t)_slang_vector_get_element(_S49, 1)};
        Vector<int32_t, 2>  _S51 = _S50 + _S48;
        int32_t _S52 = i0_0.y;
        j_0 = _S52;
        for(;;)
        {
            if(j_0 <= (_S51.y))
            {
                _S45 = j_0 <= (_S52 + int(32));
            }
            else
            {
                _S45 = false;
            }
            if(_S45)
            {
            }
            else
            {
                break;
            }
            int32_t _S53 = i0_0.x;
            i_7 = _S53;
            for(;;)
            {
                bool _S54;
                if(i_7 <= (_S51.x))
                {
                    _S54 = i_7 <= (_S53 + int(32));
                }
                else
                {
                    _S54 = false;
                }
                if(_S54)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_5, Vector<int32_t, 2> (i_7, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_7 = i_7 + int(1);
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
    bool _S55;
    if(cover_1 <= 0.0f)
    {
        _S55 = true;
    }
    else
    {
        _S55 = (c_7->cvDepth_0) <= 0.0f;
    }
    if(_S55)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_7->cvDepth_0), (1.0f / (F32_max((c_7->cvShape_0), (0.00100000004749745f))))));
}

static float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S56;
    if(vMin_0 <= 0.0f)
    {
        _S56 = true;
    }
    else
    {
        _S56 = hMin_0 <= 0.0f;
    }
    if(_S56)
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
    float _S57 = c_9->cvHeroTop_0;
    bool _S58;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        _S58 = true;
    }
    else
    {
        _S58 = r_2 >= (c_9->cvHeroRadius_0);
    }
    if(_S58)
    {
        return 0.0f;
    }
    return _S57 * (F32_pow((1.0f - r_2 * r_2 / (c_9->cvHeroRadius_0 * c_9->cvHeroRadius_0)), (c_9->cvShape_0)));
}

static float convHeroRadiusAt_0(ConvectionInput_0 * c_10, float above_2)
{
    float _S59 = c_10->cvHeroTop_0;
    bool _S60;
    if((c_10->cvHeroTop_0) <= 0.0f)
    {
        _S60 = true;
    }
    else
    {
        _S60 = above_2 >= _S59;
    }
    if(_S60)
    {
        return -1.0f;
    }
    return c_10->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S59), (1.0f / (F32_max((c_10->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static float convectionBound_0(ConvectionInput_0 * c_11, Vector<float, 3>  lo_2, Vector<float, 3>  hi_2)
{
    float low_0 = lo_2.y - c_11->cvBase_0;
    float high_0 = hi_2.y - c_11->cvBase_0;
    float _S61 = convCeiling_0(c_11);
    bool _S62;
    if(high_0 < 0.0f)
    {
        _S62 = true;
    }
    else
    {
        _S62 = low_0 > _S61;
    }
    if(_S62)
    {
        return 0.0f;
    }
    float _S63 = (F32_max((low_0), (0.0f)));
    float _S64 = (F32_min((high_0), (_S61)));
    float _S65 = convLift_0(c_11, _S64, 1.0f);
    float inside_0;
    if((c_11->cvHeroAlone_0) == int(0))
    {
        float _S66 = convUpdraftBound_0(c_11, Vector<float, 2> {lo_2.x, lo_2.z} - c_11->cvDrift_0, Vector<float, 2> {hi_2.x, hi_2.z} - c_11->cvDrift_0);
        float _S67 = convTowerHeight_0(c_11, _S66);
        float _S68 = convNeededUpdraft_0(c_11, _S63);
        if(_S66 < _S68)
        {
            inside_0 = _S65 - convDistanceFloor_0(_S63 - _S67, (_S68 - _S66) / (7.0f / c_11->cvSpacing_0));
        }
        else
        {
            inside_0 = (F32_max((_S67 - _S63), (0.0f))) + _S65;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    if((c_11->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_1(max_1(max_1(Vector<float, 2> {lo_2.x, lo_2.z} - c_11->cvHeroAt_0, c_11->cvHeroAt_0 - Vector<float, 2> {hi_2.x, hi_2.z}), Vector<float, 2> (0.0f, 0.0f)));
        float _S69 = convHeroReach_0(c_11);
        if(rMin_0 < _S69)
        {
            float _S70 = convHeroHeight_0(c_11, rMin_0);
            float _S71 = convHeroRadiusAt_0(c_11, _S63);
            float _S72 = convLift_0(c_11, _S64, c_11->cvHeroBillow_0);
            bool _S73 = _S71 < 0.0f;
            if(_S73)
            {
                _S62 = true;
            }
            else
            {
                _S62 = rMin_0 >= _S71;
            }
            float heroIn_0;
            if(_S62)
            {
                if(_S73)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S71;
                }
                heroIn_0 = _S72 - convDistanceFloor_0(_S63 - _S70, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S70 - _S63), (0.0f))) + _S72;
            }
            inside_0 = (F32_max((inside_0), (heroIn_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return 0.0f;
    }
    return c_11->cvSigma_0 * (F32_sqrt((saturate_0(_S64 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1) * 1.00001001358032227f;
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_1, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_18 = clamp_1(depth_0 / g_1->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_8 = clamp_0(int32_t((F32_floor((x_18)))), int(0), int(31));
    return lerp_0(disp_0.Load(i_8), disp_0.Load(i_8 + int(1)), (Vector<float, 2> )(x_18 - float(i_8)));
}

static void driftRange_0(GeneratorInput_0 * g_2, StructuredBuffer<Vector<float, 2> > disp_1, float d0_0, float d1_0, Vector<float, 2>  * lo_3, Vector<float, 2>  * hi_3)
{
    Vector<float, 2>  _S74 = driftAt_0(g_2, disp_1, d0_0);
    *lo_3 = _S74;
    *hi_3 = _S74;
    Vector<float, 2>  _S75 = driftAt_0(g_2, disp_1, d1_0);
    *lo_3 = min_1(*lo_3, _S75);
    *hi_3 = max_1(*hi_3, _S75);
    int32_t _S76 = clamp_0(int32_t((F32_ceil((clamp_1(d1_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int32_t k_1 = clamp_0(int32_t((F32_floor((clamp_1(d0_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_1 <= _S76)
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
    Vector<float, 2>  _S77 = floor_0(a_3);
    Vector<int32_t, 2>  _S78 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S77, 0), (int32_t)_slang_vector_get_element(_S77, 1)};
    Vector<int32_t, 2>  _S79 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  i0_1 = _S78 - _S79;
    Vector<float, 2>  _S80 = floor_0(b_2);
    Vector<int32_t, 2>  _S81 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S80, 0), (int32_t)_slang_vector_get_element(_S80, 1)};
    Vector<int32_t, 2>  _S82 = _S81 + _S79;
    int32_t _S83 = i0_1.y;
    int32_t j_1 = _S83;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S84;
        if(j_1 <= (_S82.y))
        {
            _S84 = j_1 <= (_S83 + int(32));
        }
        else
        {
            _S84 = false;
        }
        if(_S84)
        {
        }
        else
        {
            break;
        }
        int32_t _S85 = i0_1.x;
        int32_t i_9 = _S85;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S86;
            if(i_9 <= (_S82.x))
            {
                _S86 = i_9 <= (_S85 + int(32));
            }
            else
            {
                _S86 = false;
            }
            if(_S86)
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_1 = Vector<int32_t, 2> (i_9, j_1);
            if((hash22_0(o_1, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_9 = i_9 + int(1);
                continue;
            }
            Vector<float, 2>  _S87 = Vector<float, 2> {(float)_slang_vector_get_element(o_1, 0), (float)_slang_vector_get_element(o_1, 1)};
            Vector<float, 2>  c_12 = _S87 + (Vector<float, 2> )0.5f + (hash22_0(o_1, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(max_1(max_1(a_3 - c_12, c_12 - b_2), Vector<float, 2> (0.0f, 0.0f))) * 2.20000004768371582f);
            i_9 = i_9 + int(1);
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
    bool _S88;
    if(d1_1 < 0.0f)
    {
        _S88 = true;
    }
    else
    {
        _S88 = d0_1 > (g_4->streakLength_0);
    }
    if(_S88)
    {
        return 0.0f;
    }
    float _S89 = g_4->streakLength_0;
    float d0_2 = clamp_1(d0_1, 0.0f, g_4->streakLength_0);
    float d1_2 = clamp_1(d1_1, 0.0f, g_4->streakLength_0);
    float subl_0 = (F32_exp((- g_4->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_4->detailAmount_0 * 1.5f * 1.79999995231628418f;
    Vector<float, 2>  driftLo_0;
    Vector<float, 2>  driftHi_0;
    driftRange_0(g_4, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S90 = cellFieldBound_0(g_4, Vector<float, 2> (lo_4.x, lo_4.z) - driftHi_0, Vector<float, 2> (hi_4.x, hi_4.z) - driftLo_0);
    return (F32_max((_S90 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((_S89), (1.0f)));
}

static float mediumBound_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_3, Vector<float, 3>  lo_5, Vector<float, 3>  hi_5)
{
    int32_t _S91 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S92 = convectionBound_0(&m_1->conv_0, lo_5, hi_5);
        return _S92;
    }
    if(_S91 == int(2))
    {
        float _S93 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_5, hi_5);
        return _S93;
    }
    return m_1->majorant_0;
}

static float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_1, StructuredBuffer<Vector<float, 2> > disp_4, Vector<int32_t, 3>  c_13, float fallback_0)
{
    int32_t _S94 = g_5->enabled_0;
    if((g_5->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S94 == int(2))
    {
        Vector<float, 3>  _S95 = Vector<float, 3> {(float)_slang_vector_get_element(c_13, 0), (float)_slang_vector_get_element(c_13, 1), (float)_slang_vector_get_element(c_13, 2)};
        Vector<float, 3>  lo_6 = g_5->origin_0 + _S95 * g_5->cellExtent_0;
        float _S96 = mediumBound_0(m_2, disp_4, lo_6, lo_6 + g_5->cellExtent_0);
        return _S96;
    }
    int32_t _S97 = c_13.x;
    bool _S98;
    if(_S97 < int(0))
    {
        _S98 = true;
    }
    else
    {
        _S98 = (c_13.y) < int(0);
    }
    if(_S98)
    {
        _S98 = true;
    }
    else
    {
        _S98 = (c_13.z) < int(0);
    }
    if(_S98)
    {
        _S98 = true;
    }
    else
    {
        _S98 = _S97 >= (g_5->dims_0.x);
    }
    if(_S98)
    {
        _S98 = true;
    }
    else
    {
        _S98 = (c_13.y) >= (g_5->dims_0.y);
    }
    if(_S98)
    {
        _S98 = true;
    }
    else
    {
        _S98 = (c_13.z) >= (g_5->dims_0.z);
    }
    if(_S98)
    {
        return fallback_0;
    }
    return bounds_1.Load((c_13.z * g_5->dims_0.y + c_13.y) * g_5->dims_0.x + _S97);
}

static float ddaExit_0(Dda_0 * d_2)
{
    return (F32_min((d_2->tMax_0.x), ((F32_min((d_2->tMax_0.y), (d_2->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_3)
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

static float randFloat_0(Rng_0 * r_3)
{
    uint32_t _S100 = r_3->state_0 * 747796405U + 2891336453U;
    r_3->state_0 = _S100;
    uint32_t word_0 = ((_S100 >> ((_S100 >> 28U) + 4U)) ^ _S100) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static bool segmentStep_0(Medium_0 * m_3, MajorantGrid_0 * g_6, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > drift_1, float scale_0, float tEnd_0, Dda_0 * dda_0, float * rate_0, float * t_2, Rng_0 * rng_0, float * uKeep_0, float * uLive_0, int32_t * budget_0, int32_t * steps_0)
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
        Dda_0 _S101 = *dda_0;
        float _S102 = ddaExit_0(&_S101);
        float _S103 = (F32_min((_S102), (tEnd_0)));
        if(!((*rate_0) > 0.0f))
        {
            if(_S103 >= tEnd_0)
            {
                return false;
            }
            *t_2 = _S103;
            ddaAdvance_0(dda_0);
            float _S104 = gridBound_0(m_3, g_6, bounds_2, drift_1, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S104 * scale_0;
            continue;
        }
        float uStep_0 = randFloat_0(rng_0);
        float _S105 = randFloat_0(rng_0);
        *uKeep_0 = _S105;
        float _S106 = randFloat_0(rng_0);
        *uLive_0 = _S106;
        float _S107 = *t_2 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / *rate_0;
        *t_2 = _S107;
        if(_S107 >= _S103)
        {
            if(_S103 >= tEnd_0)
            {
                return false;
            }
            *t_2 = _S103;
            ddaAdvance_0(dda_0);
            float _S108 = gridBound_0(m_3, g_6, bounds_2, drift_1, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S108 * scale_0;
            continue;
        }
        return true;
    }
    return false;
}

static MajorantGrid_0 gridFor_0(Medium_0 * m_4, MajorantGrid_0 * g_7, Vector<float, 3>  p_1)
{
    MajorantGrid_0 chosen_0 = *g_7;
    bool _S109;
    if((g_7->enabled_0) == int(2))
    {
        _S109 = (p_1.y) >= (m_4->slabBottom_0);
    }
    else
    {
        _S109 = false;
    }
    if(_S109)
    {
        _S109 = (p_1.y) <= (m_4->slabTop_0);
    }
    else
    {
        _S109 = false;
    }
    if(_S109)
    {
        (&chosen_0)->enabled_0 = int(0);
    }
    return chosen_0;
}

static float cellField_0(GeneratorInput_0 * g_8, Vector<float, 2>  q_0)
{
    Vector<float, 2>  gq_0 = (q_0 - g_8->cellDrift_0) / (Vector<float, 2> )(g_8->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_0(gq_0);
    Vector<int32_t, 2>  _S110 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
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
            Vector<int32_t, 2>  o_2 = _S110 + Vector<int32_t, 2> (i_10, j_2);
            if((hash22_0(o_2, 2654435769U).x) > (g_8->cellDensity_0))
            {
                i_10 = i_10 + int(1);
                continue;
            }
            Vector<float, 2>  _S111 = Vector<float, 2> {(float)_slang_vector_get_element(o_2, 0), (float)_slang_vector_get_element(o_2, 1)};
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(gq_0 - (_S111 + (Vector<float, 2> )0.5f + (hash22_0(o_2, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f)) * 2.20000004768371582f);
            i_10 = i_10 + int(1);
        }
        j_2 = j_2 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_8->cellStrength_0;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_1)
{
    Vector<uint32_t, 3>  _S112 = v_1 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S113 = _S112;
    _S113.x = _S113.x + _S112.y * _S112.z;
    _S113.y = _S113.y + _S113.z * _S113.x;
    _S113.z = _S113.z + _S113.x * _S113.y;
    Vector<uint32_t, 3>  _S114 = _S113 ^ (_S113 >> ((Vector<uint32_t, 3> )16U));
    _S113 = _S114;
    _S113.x = _S113.x + _S114.y * _S114.z;
    _S113.y = _S113.y + _S113.z * _S113.x;
    _S113.z = _S113.z + _S113.x * _S113.y;
    return _S113;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_14)
{
    Vector<uint32_t, 3>  h_2 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_14.x), uint32_t(c_14.y), uint32_t(c_14.z)));
    Vector<float, 3>  _S115 = Vector<float, 3> {(float)_slang_vector_get_element(h_2, 0), (float)_slang_vector_get_element(h_2, 1), (float)_slang_vector_get_element(h_2, 2)};
    return _S115 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float gradientNoise_0(Vector<float, 3>  p_2)
{
    Vector<float, 3>  fi_0 = floor_1(p_2);
    Vector<int32_t, 3>  _S116 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_2 - fi_0;
    Vector<float, 3>  u_2 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S117 = u_2.x;
    float _S118 = u_2.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S116), f_0), dot_0(hash33_0(_S116 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S117), lerp_1(dot_0(hash33_0(_S116 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S116 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S117), _S118), lerp_1(lerp_1(dot_0(hash33_0(_S116 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S116 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S117), lerp_1(dot_0(hash33_0(_S116 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S116 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S117), _S118), u_2.z);
}

static float fbm_0(Vector<float, 3>  p_3, int32_t octaves_1)
{
    int32_t i_11 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S119 = p_3;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S119);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S120 = _S119 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_11 = i_11 + int(1);
        amp_0 = amp_1;
        _S119 = _S120;
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

static float iceDensity_0(GeneratorInput_0 * g_9, StructuredBuffer<Vector<float, 2> > disp_5, Vector<float, 3>  p_4)
{
    float depth_1 = g_9->cellAltitude_0 - p_4.y;
    bool _S121;
    if(depth_1 < 0.0f)
    {
        _S121 = true;
    }
    else
    {
        _S121 = depth_1 > (g_9->streakLength_0);
    }
    if(_S121)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S122 = Vector<float, 2> {p_4.x, p_4.z};
    Vector<float, 2>  _S123 = driftAt_0(g_9, disp_5, depth_1);
    Vector<float, 2>  source_0 = _S122 - _S123;
    float _S124 = cellField_0(g_9, source_0);
    if(_S124 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S124 * (F32_exp((- g_9->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_9->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_9->streakLength_0, g_9->streakLength_0, depth_1)) * (F32_max((1.0f + g_9->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_9->detailScale_0).x, (source_0 / (Vector<float, 2> )g_9->detailScale_0).y, depth_1 / (F32_max((g_9->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_9->timeSeconds_0 * 0.00999999977648258f), g_9->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_9->opticalDepth_0 / (F32_max((g_9->streakLength_0), (1.0f)));
}

static float convUpdraftGrad_0(ConvectionInput_0 * c_15, Vector<float, 2>  q_1, Vector<float, 2>  * grad_0)
{
    Vector<float, 2>  goTop_0;
    float _S125 = c_15->cvSpacing_0;
    Vector<float, 2>  g_10 = q_1 / (Vector<float, 2> )c_15->cvSpacing_0;
    Vector<float, 2>  _S126 = floor_0(g_10);
    Vector<int32_t, 2>  _S127 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S126, 0), (int32_t)_slang_vector_get_element(_S126, 1)};
    Vector<float, 2>  _S128 = Vector<float, 2> (0.0f, 0.0f);
    float oTop_0 = 0.0f;
    Vector<float, 2>  goTop_1 = _S128;
    float oNext_0 = 0.0f;
    float kTop_0 = 0.0f;
    Vector<float, 2>  gkTop_0 = _S128;
    float kNext_0 = 0.0f;
    Vector<float, 2>  goNext_0 = _S128;
    Vector<float, 2>  gkNext_0 = _S128;
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
            Vector<int32_t, 2>  slot_3 = _S127 + Vector<int32_t, 2> (i_12, j_3);
            float _S129 = convVigour_0(c_15, slot_3);
            if(_S129 <= 0.0f)
            {
                i_12 = i_12 + int(1);
                continue;
            }
            Vector<float, 2>  d_4 = g_10 - convCellCentre_0(slot_3);
            float d2_1 = dot_1(d_4, d_4);
            float ko_0 = _S129 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S129 * convBump_0(d2_1, 1.04999995231628418f);
            Vector<float, 2>  gko_0;
            if(d2_1 < 0.5625f)
            {
                gko_0 = d_4 * (Vector<float, 2> )(-4.0f * _S129 * (1.0f - d2_1 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S128;
            }
            Vector<float, 2>  gkk_0;
            if(d2_1 < 1.10249984264373779f)
            {
                gkk_0 = d_4 * (Vector<float, 2> )(-4.0f * _S129 * (1.0f - d2_1 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S128;
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
                float _S130 = oTop_2;
                Vector<float, 2>  _S131 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S130;
                goNext_2 = _S131;
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
                float _S132 = kTop_2;
                Vector<float, 2>  _S133 = gkTop_2;
                kTop_2 = kTop_1;
                gkTop_2 = gkTop_1;
                kNext_2 = _S132;
                gkNext_2 = _S133;
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
    float _S134 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_0 - kNext_0;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / (Vector<float, 2> )0.31000000238418579f;
    }
    else
    {
        goTop_0 = _S128;
    }
    float _S135 = c_15->cvPolarity_0;
    *grad_0 = lerp_0(goTop_0, gkTop_0 - gkNext_0, (Vector<float, 2> )c_15->cvPolarity_0) / (Vector<float, 2> )_S125;
    return lerp_1(_S134, closedField_0, _S135);
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
    float _S136;
    if(v_2 >= 0.0f)
    {
        _S136 = d_5;
    }
    else
    {
        _S136 = - d_5;
    }
    return _S136;
}

static Vector<float, 3>  convTwist_0(Vector<float, 3>  x_19)
{
    float _S137 = x_19.x;
    float _S138 = x_19.y;
    float _S139 = x_19.z;
    return Vector<float, 3> (0.0f * _S137 + 0.80000001192092896f * _S138 + 0.60000002384185791f * _S139, -0.80000001192092896f * _S137 + 0.36000001430511475f * _S138 - 0.47999998927116394f * _S139, -0.60000002384185791f * _S137 - 0.47999998927116394f * _S138 + 0.63999998569488525f * _S139);
}

static float convPuffs_0(Vector<float, 3>  x_20)
{
    Vector<float, 3>  fl_0 = floor_1(x_20);
    Vector<int32_t, 3>  _S140 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fl_0, 0), (int32_t)_slang_vector_get_element(fl_0, 1), (int32_t)_slang_vector_get_element(fl_0, 2)};
    Vector<float, 3>  f_1 = x_20 - fl_0;
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
    Vector<int32_t, 3>  _S141 = Vector<int32_t, 3> (dz_0, dy_0, dx_0);
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
                Vector<int32_t, 3>  off_0 = _S141 + Vector<int32_t, 3> (dx_0, dy_0, dz_0);
                Vector<float, 3>  _S142 = Vector<float, 3> {(float)_slang_vector_get_element(off_0, 0), (float)_slang_vector_get_element(off_0, 1), (float)_slang_vector_get_element(off_0, 2)};
                Vector<float, 3>  d_6 = _S142 + (Vector<float, 3> )0.5f + (Vector<float, 3> )0.25f * hash33_0(_S140 + off_0) - f_1;
                float _S143 = (F32_min((nearest_1), (dot_0(d_6, d_6))));
                int32_t dx_1 = dx_0 + int(1);
                nearest_1 = _S143;
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

static float convBillow_0(ConvectionInput_0 * c_16, Vector<float, 3>  p_5, float scale_1)
{
    Vector<float, 3>  _S144 = Vector<float, 3> (p_5.x, p_5.y - c_16->cvRise_0, p_5.z) / (Vector<float, 3> )scale_1;
    int32_t i_13 = int(0);
    Vector<float, 3>  x_21 = _S144;
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
        Vector<float, 3>  x_22 = convTwist_0(x_21);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_22);
        float norm_3 = norm_2 + amp_2;
        Vector<float, 3>  x_23 = x_22 * (Vector<float, 3> )2.17000007629394531f;
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_13 = i_13 + int(1);
        x_21 = x_23;
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

static float convInside_0(ConvectionInput_0 * c_17, float d_7, float lift_0, Vector<float, 3>  x_24, float scale_2)
{
    float _S145 = d_7 + lift_0;
    if(_S145 <= 0.0f)
    {
        return _S145;
    }
    if((d_7 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S146 = convBillow_0(c_17, x_24, scale_2);
    return d_7 + lift_0 * _S146;
}

static float convHeroInside_0(ConvectionInput_0 * c_18, Vector<float, 3>  p_6, float above_3)
{
    Vector<float, 2>  rel_0 = Vector<float, 2> {p_6.x, p_6.z} - c_18->cvHeroAt_0;
    float r_4 = length_1(rel_0);
    float _S147 = convHeroReach_0(c_18);
    if(r_4 >= _S147)
    {
        return -1.00000001504746622e+30f;
    }
    float _S148 = convHeroHeight_0(c_18, r_4);
    float v_3 = _S148 - above_3;
    float _S149 = convHeroRadiusAt_0(c_18, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_8;
    if(_S149 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_8 = v_3;
    }
    else
    {
        float h_3 = _S149 - r_4;
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
        float _S150 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S150;
        d_8 = d_9;
    }
    Vector<float, 2>  radial_0;
    if(r_4 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / (Vector<float, 2> )r_4;
    }
    else
    {
        radial_0 = Vector<float, 2> (0.0f, 0.0f);
    }
    Vector<float, 2>  at_0 = rel_0 + radial_0 * (Vector<float, 2> )shiftOut_0;
    Vector<float, 3>  x_25 = Vector<float, 3> (at_0.x, p_6.y + shiftUp_0, at_0.y) + c_18->cvHeroSeed_0;
    float _S151 = c_18->cvHeroBillow_0;
    float _S152 = convLift_0(c_18, above_3, c_18->cvHeroBillow_0);
    float _S153 = convInside_0(c_18, d_8, _S152, x_25, c_18->cvBillowScale_0 * _S151);
    return _S153;
}

static float convectionDensity_0(ConvectionInput_0 * c_19, Vector<float, 3>  p_7)
{
    float _S154 = p_7.y;
    float above_4 = _S154 - c_19->cvBase_0;
    bool _S155;
    if(above_4 < 0.0f)
    {
        _S155 = true;
    }
    else
    {
        float _S156 = convCeiling_0(c_19);
        _S155 = above_4 > _S156;
    }
    if(_S155)
    {
        return 0.0f;
    }
    float _S157 = convLift_0(c_19, above_4, 1.0f);
    float inside_2;
    if((c_19->cvHeroAlone_0) == int(0))
    {
        Vector<float, 2>  q_2 = Vector<float, 2> {p_7.x, p_7.z} - c_19->cvDrift_0;
        Vector<float, 2>  slope_1;
        float _S158 = convUpdraftGrad_0(c_19, q_2, &slope_1);
        float _S159 = convTowerHeight_0(c_19, _S158);
        float v_4 = _S159 - above_4;
        float _S160 = convNeededUpdraft_0(c_19, above_4);
        float delta_1 = _S158 - _S160;
        float d_10 = convSurfaceDistance_0(v_4, delta_1, length_1(slope_1));
        if((d_10 + _S157) > 0.0f)
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
            float _S161 = convInside_0(c_19, d_10, _S157, Vector<float, 3> (q_2.x + shiftAcross_0.x, _S154 + inside_2, q_2.y + shiftAcross_0.y), c_19->cvBillowScale_0);
            inside_2 = _S161;
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
        _S155 = inside_2 < 12.0f;
    }
    else
    {
        _S155 = false;
    }
    if(_S155)
    {
        float _S162 = convHeroInside_0(c_19, p_7, above_4);
        inside_2 = (F32_max((inside_2), (_S162)));
    }
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_19->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2);
}

static float densityAt_0(Medium_0 * m_5, StructuredBuffer<Vector<float, 2> > disp_6, Vector<float, 3>  p_8)
{
    float _S163 = p_8.y;
    bool _S164;
    if(_S163 < (m_5->slabBottom_0))
    {
        _S164 = true;
    }
    else
    {
        _S164 = _S163 > (m_5->slabTop_0);
    }
    if(_S164)
    {
        return 0.0f;
    }
    if((m_5->clipOn_0) != int(0))
    {
        Vector<float, 2>  _S165 = Vector<float, 2> {p_8.x, p_8.z};
        if(any_0(_S165 < (m_5->clipLo_0)))
        {
            _S164 = true;
        }
        else
        {
            _S164 = any_0(_S165 > (m_5->clipHi_0));
        }
    }
    else
    {
        _S164 = false;
    }
    if(_S164)
    {
        return 0.0f;
    }
    float _S166 = m_5->fadeRadius_0;
    float fade_0;
    if((m_5->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S166 - length_1(Vector<float, 2> {p_8.x, p_8.z} - m_5->fadeAt_0)) / (F32_max((m_5->fadeWidth_0), (1.0f))));
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
    int32_t _S167 = m_5->mode_0;
    if((m_5->mode_0) == int(0))
    {
        return m_5->density_0 * fade_0;
    }
    if(_S167 == int(2))
    {
        float _S168 = iceDensity_0(&m_5->gen_0, disp_6, p_8);
        return _S168 * fade_0;
    }
    if(_S167 == int(3))
    {
        float _S169 = convectionDensity_0(&m_5->conv_0, p_8);
        return _S169 * fade_0;
    }
    Vector<float, 3>  d_11 = (p_8 - m_5->coreCentre_0) / (Vector<float, 3> )(F32_max((m_5->coreRadius_0), (9.99999997475242708e-07f)));
    return (m_5->density_0 + m_5->coreDensity_0 * (F32_exp((- dot_0(d_11, d_11))))) * fade_0;
}

static float transmittance_0(Medium_0 * m_6, MajorantGrid_0 * g_11, StructuredBuffer<float> bounds_3, StructuredBuffer<Vector<float, 2> > disp_7, Rng_0 * rng_1, Vector<float, 3>  p_9, Vector<float, 3>  dir_0, int32_t * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S170 = slabRange_0(m_6, p_9, dir_0, &t0_2, &t1_2);
    if(!_S170)
    {
        return 1.0f;
    }
    float _S171 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S171;
    Dda_0 _S172 = ddaInit_0(g_11, p_9, dir_0, _S171);
    Dda_0 dda_1 = _S172;
    float _S173 = m_6->majorant_0;
    float _S174 = gridBound_0(m_6, g_11, bounds_3, disp_7, (&dda_1)->cell_0, m_6->majorant_0);
    float localMaj_0 = _S174;
    int32_t i_14 = int(0);
    float t_3 = _S171;
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
        *steps_1 = *steps_1 + int(1);
        Dda_0 _S175 = dda_1;
        float _S176 = ddaExit_0(&_S175);
        float _S177 = (F32_min((_S176), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S177 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S178 = gridBound_0(m_6, g_11, bounds_3, disp_7, (&dda_1)->cell_0, _S173);
            localMaj_0 = _S178;
            t_3 = _S177;
            i_14 = i_14 + int(1);
            continue;
        }
        float _S179 = randFloat_0(rng_1);
        float t_4 = t_3 - (F32_log(((F32_max((1.0f - _S179), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_4 >= _S177)
        {
            if(_S177 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S180 = gridBound_0(m_6, g_11, bounds_3, disp_7, (&dda_1)->cell_0, _S173);
            localMaj_0 = _S180;
            t_3 = _S177;
            i_14 = i_14 + int(1);
            continue;
        }
        float _S181 = densityAt_0(m_6, disp_7, p_9 + dir_0 * (Vector<float, 3> )t_4);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S181 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S182 = randFloat_0(rng_1);
            if(_S182 > 0.5f)
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
        i_14 = i_14 + int(1);
    }
    return tr_0;
}

static float sceneTransmittance_0(Scene_0 * s_4, StructuredBuffer<float> bounds_4, StructuredBuffer<Vector<float, 2> > drift_2, Rng_0 * rng_2, Vector<float, 3>  p_10, Vector<float, 3>  dir_1, int32_t * steps_2)
{
    float _S183 = transmittance_0(&s_4->medium_0, &s_4->grid_0, bounds_4, drift_2, rng_2, p_10, dir_1, steps_2);
    bool _S184;
    if((s_4->layer2On_0) != int(0))
    {
        _S184 = _S183 > 0.0f;
    }
    else
    {
        _S184 = false;
    }
    float tr_3;
    if(_S184)
    {
        MajorantGrid_0 _S185 = gridFor_0(&s_4->medium2_0, &s_4->grid2_0, p_10);
        MajorantGrid_0 _S186 = _S185;
        float _S187 = transmittance_0(&s_4->medium2_0, &_S186, bounds_4, drift_2, rng_2, p_10, dir_1, steps_2);
        tr_3 = _S183 * _S187;
    }
    else
    {
        tr_3 = _S183;
    }
    return tr_3;
}

static float hg_0(float cosT_0, float g_12)
{
    float _S188 = g_12 * g_12;
    float d_12 = 1.0f + _S188 - 2.0f * g_12 * cosT_0;
    return (1.0f - _S188) / (12.56637096405029297f * d_12 * (F32_sqrt(((F32_max((d_12), (9.99999997475242708e-07f)))))));
}

static float phaseIce_0(float cosT_1)
{
    float t_5 = ((F32_acos((clamp_1(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_1(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_5 * t_5))) * 0.34999999403953552f;
}

static float draine_0(float cosT_2, float g_13, float a_4)
{
    float _S189 = g_13 * g_13;
    float _S190 = 2.0f * g_13;
    float d_13 = 1.0f + _S189 - _S190 * cosT_2;
    return (1.0f - _S189) / (12.56637096405029297f * d_13 * (F32_sqrt(((F32_max((d_13), (9.99999997475242708e-07f))))))) * (1.0f + a_4 * cosT_2 * cosT_2) / (1.0f + a_4 * (1.0f + _S190 * g_13) / 3.0f);
}

static float phaseLiquid_0(PhaseInput_0 * p_11, float cosT_3)
{
    return (1.0f - p_11->draineW_0) * hg_0(cosT_3, p_11->hgG_0) + p_11->draineW_0 * draine_0(cosT_3, p_11->draineG_0, p_11->draineAlpha_0);
}

static float phaseAt_0(PhaseInput_0 * p_12, float cosT_4)
{
    float _S191;
    if((p_12->useIce_0) != int(0))
    {
        _S191 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S192 = phaseLiquid_0(p_12, cosT_4);
        _S191 = _S192;
    }
    return _S191;
}

static float phaseCamera_0(PhaseInput_0 * p_13, float cosT_5)
{
    float _S193 = phaseAt_0(p_13, cosT_5);
    float _S194 = p_13->lobeWeight_0;
    float v_5;
    if((p_13->lobeWeight_0) > 0.0f)
    {
        v_5 = _S193 + _S194 * hg_0(cosT_5, p_13->lobeG_0);
    }
    else
    {
        v_5 = _S193;
    }
    return v_5;
}

static float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_14 = altitude_0 - shellHeight_0;
    return d_14 * (d_14 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static float shellExit_0(float b_3, float c_20)
{
    float disc_0 = b_3 * b_3 - c_20;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_3 + (F32_sqrt((disc_0)));
}

static float shellEnter_0(float b_4, float c_21)
{
    float disc_1 = b_4 * b_4 - c_21;
    if(disc_1 < 0.0f)
    {
        return -1.0f;
    }
    return - b_4 - (F32_sqrt((disc_1)));
}

static Vector<float, 3>  rayleighCoefficients_0()
{
    return Vector<float, 3> (5.80200003241770901e-06f, 0.00001355800031888f, 0.00003310000101919f);
}

static float mieCoefficient_0(float turbidity_1)
{
    return 3.99600003220257349e-06f * (turbidity_1 / 2.20000004768371582f);
}

static float altitudeFromQ_0(float q_3, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_3;
    float _S195;
    if(rr_0 > 0.0f)
    {
        _S195 = rr_0;
    }
    else
    {
        _S195 = 0.0f;
    }
    return q_3 / (planetRadius_2 + (F32_sqrt((_S195))));
}

static Vector<float, 3>  airTransmittance_0(SkyInput_0 * p_14, float originAltitude_0, Vector<float, 3>  rayDir_0, float dist_0)
{
    float _S196 = p_14->planetRadius_0;
    float planetRadius_3;
    if((p_14->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S196;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S197 = p_14->scaleHeight_0;
    float scaleHeight_1;
    if((p_14->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S197;
    }
    else
    {
        scaleHeight_1 = 1.0f;
    }
    float atmosphereHeight_0 = scaleHeight_1 * 8.0f;
    float observerAltitude_0;
    if(originAltitude_0 > 0.0f)
    {
        observerAltitude_0 = originAltitude_0;
    }
    else
    {
        observerAltitude_0 = 0.0f;
    }
    float b_5 = (planetRadius_3 + observerAltitude_0) * rayDir_0.y;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(b_5, shellC_0(observerAltitude_0, planetRadius_3, atmosphereHeight_0));
    bool _S198;
    if(tTop_0 <= 0.0f)
    {
        _S198 = true;
    }
    else
    {
        _S198 = !(dist_0 > 0.0f);
    }
    if(_S198)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float tGround_0 = shellEnter_0(b_5, cGround_0);
    float tMax_1;
    if(tGround_0 > 0.0f)
    {
        tMax_1 = tGround_0;
    }
    else
    {
        tMax_1 = tTop_0;
    }
    if(dist_0 < tMax_1)
    {
        tMax_1 = dist_0;
    }
    Vector<float, 3>  betaR_0 = rayleighCoefficients_0();
    float betaMExt_0 = mieCoefficient_0(p_14->turbidity_0) * 1.11000001430511475f;
    float tPrev_0 = 0.0f;
    int32_t i_15 = int(0);
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
        int32_t _S199 = i_15 + int(1);
        float tNext_0 = tMax_1 * float(_S199 * _S199) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_15 = _S199;
            continue;
        }
        float h_4 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_5 + tMid_0 * tMid_0, planetRadius_3);
        float hc_0;
        if(h_4 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_4;
        }
        float _S200 = - hc_0;
        float depthM_1 = depthM_0 + (F32_exp((_S200 / 1200.0f))) * dt_0;
        depthR_0 = depthR_0 + (F32_exp((_S200 / scaleHeight_1))) * dt_0;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_15 = _S199;
    }
    float _S201 = betaMExt_0 * depthM_0;
    return Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S201)))), (F32_exp((- (betaR_0.y * depthR_0 + _S201)))), (F32_exp((- (betaR_0.z * depthR_0 + _S201)))));
}

static float sunIrradianceTop_0(SkyInput_0 * p_15)
{
    return 20.0f * p_15->sunIntensity_0;
}

static float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static Vector<float, 3>  normalizeExact_0(Vector<float, 3>  v_6)
{
    float len2_0 = dot_0(v_6, v_6);
    if(len2_0 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    return v_6 * (Vector<float, 3> )(1.0f / (F32_sqrt((len2_0))));
}

static Vector<float, 3>  sunDirection_0(SkyInput_0 * p_16)
{
    float az_0 = toRadians_0(p_16->sunAzimuth_0);
    float el_0 = toRadians_0(p_16->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(Vector<float, 3> ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static float lutMuFor_0(Vector<float, 3>  geocentric_0, Vector<float, 3>  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S202;
    if(len_0 > 1.0f)
    {
        _S202 = dot_0(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S202 = dot_0(geocentric_0, sun_0);
    }
    return _S202;
}

static float clampf_0(float v_7, float lo_7, float hi_6)
{
    float _S203;
    if(v_7 < lo_7)
    {
        _S203 = lo_7;
    }
    else
    {
        if(v_7 > hi_6)
        {
            _S203 = hi_6;
        }
        else
        {
            _S203 = v_7;
        }
    }
    return _S203;
}

static Vector<float, 3>  sampleTransmittanceLut_0(SkyInput_0 * p_17, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S204 = p_17->transmittanceLut_0;
    if(uint32_t(StructuredBuffer_getCount_0(p_17->transmittanceLut_0)) < 49152U)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float _S205 = p_17->scaleHeight_0;
    float scaleHeight_2;
    if((p_17->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S205;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float topAltitude_0 = scaleHeight_2 * 8.0f;
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
    int32_t x0_0 = int32_t(fx_1);
    int32_t y0_0 = int32_t(fy_1);
    int32_t x0_1;
    if(x0_0 > int(255))
    {
        x0_1 = int(255);
    }
    else
    {
        x0_1 = x0_0;
    }
    int32_t y0_1;
    if(y0_0 > int(63))
    {
        y0_1 = int(63);
    }
    else
    {
        y0_1 = y0_0;
    }
    int32_t x1_0 = x0_1 + int(1);
    int32_t y1_0 = y0_1 + int(1);
    int32_t x1_1;
    if(x1_0 > int(255))
    {
        x1_1 = int(255);
    }
    else
    {
        x1_1 = x1_0;
    }
    int32_t y1_1;
    if(y1_0 > int(63))
    {
        y1_1 = int(63);
    }
    else
    {
        y1_1 = y1_0;
    }
    float _S206 = fx_1 - float(x0_1);
    float _S207 = fy_1 - float(y0_1);
    int32_t _S208 = y0_1 * int(256);
    int32_t _S209 = (_S208 + x0_1) * int(3);
    int32_t _S210 = (_S208 + x1_1) * int(3);
    int32_t _S211 = y1_1 * int(256);
    int32_t _S212 = (_S211 + x0_1) * int(3);
    int32_t _S213 = (_S211 + x1_1) * int(3);
    Vector<float, 3>  out_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    int32_t c_22 = int(0);
    for(;;)
    {
        if(c_22 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S214 = 1.0f - _S206;
        float r_5 = (_S204.Load(_S209 + c_22) * _S214 + _S204.Load(_S210 + c_22) * _S206) * (1.0f - _S207) + (_S204.Load(_S212 + c_22) * _S214 + _S204.Load(_S213 + c_22) * _S206) * _S207;
        if(c_22 == int(0))
        {
            out_0.x = r_5;
        }
        else
        {
            if(c_22 == int(1))
            {
                out_0.y = r_5;
            }
            else
            {
                out_0.z = r_5;
            }
        }
        c_22 = c_22 + int(1);
    }
    return out_0;
}

static Vector<float, 3>  sunTransmittanceAt_0(SkyInput_0 * p_18, Vector<float, 3>  worldPos_0)
{
    Vector<float, 3>  _S215 = sunDirection_0(p_18);
    float _S216 = p_18->planetRadius_0;
    float planetRadius_4;
    if((p_18->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S216;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S217 = worldPos_0.y;
    float altitude_2;
    if(_S217 > 0.0f)
    {
        altitude_2 = _S217;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    Vector<float, 3>  _S218 = sampleTransmittanceLut_0(p_18, altitude_2, lutMuFor_0(Vector<float, 3> (worldPos_0.x, planetRadius_4 + _S217, worldPos_0.z), _S215));
    return _S218;
}

static Vector<float, 3>  sunIrradianceAt_0(Scene_0 * s_5, Vector<float, 3>  p_19)
{
    if(((&s_5->environment_0)->envMode_0) == int(1))
    {
        float _S219 = sunIrradianceTop_0(&(&s_5->environment_0)->sky_0);
        Vector<float, 3>  _S220 = sunTransmittanceAt_0(&(&s_5->environment_0)->sky_0, p_19);
        return (Vector<float, 3> )_S219 * _S220;
    }
    return s_5->sunIrradiance_0;
}

static Vector<float, 3>  cameraSegmentSun_0(Scene_0 * s_6, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_5, StructuredBuffer<Vector<float, 2> > drift_3, Rng_0 * rng_3, Rng_0 * rng2_0, Vector<float, 3>  ro_2, Vector<float, 3>  rd_2, int32_t * steps_3)
{
    float ph0_0;
    float kept_0;
    float keptT_0;
    Vector<float, 3>  keptAt_0;
    int32_t keptLayer_0;
    Rng_0 _S221 = *rng2_0;
    Vector<float, 3>  none_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float _S222 = (F32_max((s_6->neeTentativeScale_0), (1.0f)));
    float tA_0;
    float endA_0;
    bool _S223 = slabRange_0(&s_6->medium_0, ro_2, rd_2, &tA_0, &endA_0);
    float _S224 = (F32_max((tA_0), (0.0f)));
    tA_0 = _S224;
    Dda_0 _S225 = ddaInit_0(&s_6->grid_0, ro_2, rd_2, _S224);
    Dda_0 ddaA_0 = _S225;
    float _S226 = gridBound_0(&s_6->medium_0, &s_6->grid_0, bounds_5, drift_3, (&ddaA_0)->cell_0, (&s_6->medium_0)->majorant_0);
    float rateA_0 = _S226 * _S222;
    int32_t budgetA_0 = int(4096);
    float keepA_0 = 0.0f;
    float rouletteA_0 = 0.0f;
    bool haveA_0;
    if(_S223)
    {
        bool _S227 = segmentStep_0(&s_6->medium_0, &s_6->grid_0, bounds_5, drift_3, _S222, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
        haveA_0 = _S227;
    }
    else
    {
        haveA_0 = _S223;
    }
    float tB_0 = 0.0f;
    float endB_0 = 0.0f;
    bool haveB_0;
    if((s_6->layer2On_0) != int(0))
    {
        bool _S228 = slabRange_0(&s_6->medium2_0, ro_2, rd_2, &tB_0, &endB_0);
        haveB_0 = _S228;
    }
    else
    {
        haveB_0 = false;
    }
    float _S229 = (F32_max((tB_0), (0.0f)));
    tB_0 = _S229;
    MajorantGrid_0 _S230 = gridFor_0(&s_6->medium2_0, &s_6->grid2_0, ro_2);
    MajorantGrid_0 _S231 = _S230;
    Dda_0 _S232 = ddaInit_0(&_S231, ro_2, rd_2, _S229);
    Dda_0 ddaB_0 = _S232;
    MajorantGrid_0 _S233 = _S230;
    float _S234 = gridBound_0(&s_6->medium2_0, &_S233, bounds_5, drift_3, (&ddaB_0)->cell_0, (&s_6->medium2_0)->majorant_0);
    float rateB_0 = _S234 * _S222;
    int32_t budgetB_0 = int(4096);
    float keepB_0 = 0.0f;
    float rouletteB_0 = 0.0f;
    if(haveB_0)
    {
        MajorantGrid_0 _S235 = _S230;
        bool _S236 = segmentStep_0(&s_6->medium2_0, &_S235, bounds_5, drift_3, _S222, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S221, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
        haveB_0 = _S236;
    }
    float kept_1 = 0.0f;
    Vector<float, 3>  keptAt_1 = none_0;
    int32_t keptLayer_1 = int(0);
    float keptT_1 = 0.0f;
    float tr_4 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        bool _S237;
        if(haveA_0)
        {
            _S237 = true;
        }
        else
        {
            _S237 = haveB_0;
        }
        if(_S237)
        {
        }
        else
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            keptLayer_0 = keptLayer_1;
            keptT_0 = keptT_1;
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
        Vector<float, 3>  p_20 = ro_2 + rd_2 * (Vector<float, 3> )ph0_0;
        float sigma_0;
        if(takeA_0)
        {
            float _S238 = densityAt_0(&s_6->medium_0, drift_3, p_20);
            sigma_0 = _S238;
        }
        else
        {
            float _S239 = densityAt_0(&s_6->medium2_0, drift_3, p_20);
            sigma_0 = _S239;
        }
        if(sigma_0 > 0.0f)
        {
            float w_1 = sigma_0 / rate_1;
            float b_6 = tr_4 * w_1;
            float total_1;
            if(b_6 > 0.0f)
            {
                float total_2 = total_0 + b_6;
                if((uKeep_1 * total_2) < b_6)
                {
                    if(takeA_0)
                    {
                        keptLayer_0 = int(0);
                    }
                    else
                    {
                        keptLayer_0 = int(1);
                    }
                    kept_0 = b_6;
                    keptAt_0 = p_20;
                    keptT_0 = ph0_0;
                }
                else
                {
                    kept_0 = kept_1;
                    keptAt_0 = keptAt_1;
                    keptLayer_0 = keptLayer_1;
                    keptT_0 = keptT_1;
                }
                total_1 = total_2;
            }
            else
            {
                kept_0 = kept_1;
                keptAt_0 = keptAt_1;
                keptLayer_0 = keptLayer_1;
                keptT_0 = keptT_1;
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
            keptT_0 = keptT_1;
        }
        if(takeA_0)
        {
            bool _S240 = segmentStep_0(&s_6->medium_0, &s_6->grid_0, bounds_5, drift_3, _S222, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
            haveA_0 = _S240;
        }
        else
        {
            MajorantGrid_0 _S241 = _S230;
            bool _S242 = segmentStep_0(&s_6->medium2_0, &_S241, bounds_5, drift_3, _S222, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S221, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
            haveB_0 = _S242;
        }
        kept_1 = kept_0;
        keptAt_1 = keptAt_0;
        keptLayer_1 = keptLayer_0;
        keptT_1 = keptT_0;
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
    Vector<float, 3>  _S243 = s_6->sunDir_0;
    float _S244 = sceneTransmittance_0(s_6, bounds_5, drift_3, rng_3, keptAt_0 + s_6->sunDir_0 * (Vector<float, 3> )s_6->shadowOffset_0, s_6->sunDir_0, steps_3);
    Vector<float, 3>  _S245 = s_6->albedo_0;
    Vector<float, 3>  matterAlbedo_0;
    if(keptLayer_0 == int(0))
    {
        float _S246 = phaseCamera_0(ph_0, dot_0(rd_2, _S243));
        matterAlbedo_0 = _S245;
        ph0_0 = _S246;
    }
    else
    {
        float _S247 = phaseCamera_0(&s_6->phase2_0, dot_0(rd_2, _S243));
        matterAlbedo_0 = s_6->albedo2_0;
        ph0_0 = _S247;
    }
    Vector<float, 3>  _S248 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    if(((&s_6->environment_0)->envMode_0) == int(1))
    {
        haveA_0 = (s_6->aerialMode_0) != int(0);
    }
    else
    {
        haveA_0 = false;
    }
    Vector<float, 3>  air_0;
    if(haveA_0)
    {
        Vector<float, 3>  _S249 = airTransmittance_0(&(&s_6->environment_0)->sky_0, ro_2.y, rd_2, keptT_0);
        air_0 = _S249;
    }
    else
    {
        air_0 = _S248;
    }
    Vector<float, 3>  _S250 = (Vector<float, 3> )total_0 * matterAlbedo_0 * (Vector<float, 3> )ph0_0 * (Vector<float, 3> )_S244;
    Vector<float, 3>  _S251 = sunIrradianceAt_0(s_6, keptAt_0);
    return _S250 * _S251 * air_0;
}

static bool sampleFreeFlightUpTo_0(Medium_0 * m_7, MajorantGrid_0 * g_14, StructuredBuffer<float> bounds_6, StructuredBuffer<Vector<float, 2> > disp_8, Rng_0 * rng_4, Vector<float, 3>  ro_3, Vector<float, 3>  rd_3, float tLimit_0, Vector<float, 3>  * scatterPoint_0, float * distance_0, int32_t * steps_4)
{
    *scatterPoint_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S252 = slabRange_0(m_7, ro_3, rd_3, &t0_3, &t1_3);
    if(!_S252)
    {
        return false;
    }
    float _S253 = (F32_min((t1_3), (tLimit_0)));
    t1_3 = _S253;
    if(!(_S253 > t0_3))
    {
        return false;
    }
    float _S254 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S255 = ddaInit_0(g_14, ro_3, rd_3, _S254);
    Dda_0 dda_2 = _S255;
    float _S256 = m_7->majorant_0;
    float _S257 = gridBound_0(m_7, g_14, bounds_6, disp_8, (&dda_2)->cell_0, m_7->majorant_0);
    float localMaj_1 = _S257;
    int32_t i_16 = int(0);
    float t_6 = _S254;
    for(;;)
    {
        if(i_16 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_4 = *steps_4 + int(1);
        Dda_0 _S258 = dda_2;
        float _S259 = ddaExit_0(&_S258);
        float _S260 = (F32_min((_S259), (t1_3)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S260 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S261 = gridBound_0(m_7, g_14, bounds_6, disp_8, (&dda_2)->cell_0, _S256);
            localMaj_1 = _S261;
            t_6 = _S260;
            i_16 = i_16 + int(1);
            continue;
        }
        float _S262 = randFloat_0(rng_4);
        float t_7 = t_6 - (F32_log(((F32_max((1.0f - _S262), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_7 >= _S260)
        {
            if(_S260 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S263 = gridBound_0(m_7, g_14, bounds_6, disp_8, (&dda_2)->cell_0, _S256);
            localMaj_1 = _S263;
            t_6 = _S260;
            i_16 = i_16 + int(1);
            continue;
        }
        Vector<float, 3>  p_21 = ro_3 + rd_3 * (Vector<float, 3> )t_7;
        float _S264 = randFloat_0(rng_4);
        float _S265 = densityAt_0(m_7, disp_8, p_21);
        if(_S264 < (_S265 / localMaj_1))
        {
            *scatterPoint_0 = p_21;
            *distance_0 = t_7;
            return true;
        }
        t_6 = t_7;
        i_16 = i_16 + int(1);
    }
    return false;
}

static bool sampleFreeFlight_0(Medium_0 * m_8, MajorantGrid_0 * g_15, StructuredBuffer<float> bounds_7, StructuredBuffer<Vector<float, 2> > disp_9, Rng_0 * rng_5, Vector<float, 3>  ro_4, Vector<float, 3>  rd_4, Vector<float, 3>  * scatterPoint_1, float * distance_1, int32_t * steps_5)
{
    bool _S266 = sampleFreeFlightUpTo_0(m_8, g_15, bounds_7, disp_9, rng_5, ro_4, rd_4, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_5);
    return _S266;
}

static bool sceneFreeFlight_0(Scene_0 * s_7, StructuredBuffer<float> bounds_8, StructuredBuffer<Vector<float, 2> > drift_4, Rng_0 * rng_6, Vector<float, 3>  ro_5, Vector<float, 3>  rd_5, Vector<float, 3>  * scatterAt_0, int32_t * layer_0, int32_t * steps_6)
{
    *layer_0 = int(0);
    float dist_1;
    if((s_7->layer2On_0) == int(0))
    {
        bool _S267 = sampleFreeFlight_0(&s_7->medium_0, &s_7->grid_0, bounds_8, drift_4, rng_6, ro_5, rd_5, scatterAt_0, &dist_1, steps_6);
        return _S267;
    }
    float a0_0;
    float a1_0;
    bool _S268 = slabRange_0(&s_7->medium_0, ro_5, rd_5, &a0_0, &a1_0);
    float b0_0;
    float b1_0;
    bool _S269 = slabRange_0(&s_7->medium2_0, ro_5, rd_5, &b0_0, &b1_0);
    bool secondFirst_0;
    if(_S269)
    {
        if(!_S268)
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
    Vector<float, 3>  pNear_0;
    Vector<float, 3>  pFar_0;
    float dNear_1;
    float dFar_0;
    MajorantGrid_0 _S270 = gridFor_0(&s_7->medium2_0, &s_7->grid2_0, ro_5);
    float _S271;
    if(secondFirst_0)
    {
        MajorantGrid_0 _S272 = _S270;
        bool _S273 = sampleFreeFlight_0(&s_7->medium2_0, &_S272, bounds_8, drift_4, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S273)
        {
            _S271 = dNear_1;
        }
        else
        {
            _S271 = 1.00000001504746622e+30f;
        }
        bool _S274 = sampleFreeFlightUpTo_0(&s_7->medium_0, &s_7->grid_0, bounds_8, drift_4, rng_6, ro_5, rd_5, _S271, &pFar_0, &dFar_0, steps_6);
        if(_S274)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(0);
            return true;
        }
        if(_S273)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(1);
            return true;
        }
    }
    else
    {
        bool _S275 = sampleFreeFlight_0(&s_7->medium_0, &s_7->grid_0, bounds_8, drift_4, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S275)
        {
            _S271 = dNear_1;
        }
        else
        {
            _S271 = 1.00000001504746622e+30f;
        }
        MajorantGrid_0 _S276 = _S270;
        bool _S277 = sampleFreeFlightUpTo_0(&s_7->medium2_0, &_S276, bounds_8, drift_4, rng_6, ro_5, rd_5, _S271, &pFar_0, &dFar_0, steps_6);
        if(_S277)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(1);
            return true;
        }
        if(_S275)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(0);
            return true;
        }
    }
    *scatterAt_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    return false;
}

static Vector<float, 3>  skyRadiance_0(SkyInput_0 * p_22, float originAltitude_1, Vector<float, 3>  rayDir_1, bool includeSunDisc_0)
{
    float hc_1;
    Vector<float, 3>  _S278 = sunDirection_0(p_22);
    float _S279 = p_22->planetRadius_0;
    float planetRadius_5;
    if((p_22->planetRadius_0) > 1000.0f)
    {
        planetRadius_5 = _S279;
    }
    else
    {
        planetRadius_5 = 1000.0f;
    }
    float _S280 = p_22->scaleHeight_0;
    float scaleHeight_3;
    if((p_22->scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = _S280;
    }
    else
    {
        scaleHeight_3 = 1.0f;
    }
    float atmosphereHeight_1 = scaleHeight_3 * 8.0f;
    float observerAltitude_1;
    if(originAltitude_1 > 0.0f)
    {
        observerAltitude_1 = originAltitude_1;
    }
    else
    {
        observerAltitude_1 = 0.0f;
    }
    float _S281 = planetRadius_5 + observerAltitude_1;
    float _S282 = rayDir_1.y;
    float b_7 = _S281 * _S282;
    float cGround_1 = shellC_0(observerAltitude_1, planetRadius_5, 0.0f);
    float tTop_1 = shellExit_0(b_7, shellC_0(observerAltitude_1, planetRadius_5, atmosphereHeight_1));
    if(tTop_1 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 0.0f, 0.0f);
    }
    float tGround_1 = shellEnter_0(b_7, cGround_1);
    bool hitsGround_0 = tGround_1 > 0.0f;
    if(hitsGround_0)
    {
        observerAltitude_1 = tGround_1;
    }
    else
    {
        observerAltitude_1 = tTop_1;
    }
    Vector<float, 3>  betaR_1 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_22->turbidity_0);
    float betaMExt_1 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_1, _S278), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_16 = clampf_0(p_22->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S283 = g_16 * g_16;
    float hgDenom_0 = 1.0f + _S283 - 2.0f * g_16 * cosTheta_0;
    float _S284 = 1.0f - _S283;
    float _S285 = 12.56637096405029297f * hgDenom_0;
    float tPrev_1;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_1 = hgDenom_0;
    }
    else
    {
        tPrev_1 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S284 / (_S285 * (F32_sqrt((tPrev_1))));
    Vector<float, 3>  _S286 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    tPrev_1 = 0.0f;
    Vector<float, 3>  sumR_0 = _S286;
    Vector<float, 3>  sumM_0 = _S286;
    int32_t i_17 = int(0);
    float depthR_1 = 0.0f;
    float depthM_2 = 0.0f;
    for(;;)
    {
        if(i_17 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S287 = i_17 + int(1);
        float tNext_1 = observerAltitude_1 * float(_S287 * _S287) * 0.00173611112404615f;
        float dt_1 = tNext_1 - tPrev_1;
        float tMid_1 = (tPrev_1 + tNext_1) * 0.5f;
        if(dt_1 <= 0.0f)
        {
            tPrev_1 = tNext_1;
            i_17 = _S287;
            continue;
        }
        float h_5 = altitudeFromQ_0(cGround_1 + 2.0f * tMid_1 * b_7 + tMid_1 * tMid_1, planetRadius_5);
        if(h_5 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_5;
        }
        float _S288 = - hc_1;
        float dR_0 = (F32_exp((_S288 / scaleHeight_3))) * dt_1;
        float dM_0 = (F32_exp((_S288 / 1200.0f))) * dt_1;
        float midR_0 = depthR_1 + 0.5f * dR_0;
        float midM_0 = depthM_2 + 0.5f * dM_0;
        float depthR_2 = depthR_1 + dR_0;
        float depthM_3 = depthM_2 + dM_0;
        Vector<float, 3>  _S289 = sampleTransmittanceLut_0(p_22, hc_1, lutMuFor_0(Vector<float, 3> (rayDir_1.x * tMid_1, _S281 + _S282 * tMid_1, rayDir_1.z * tMid_1), _S278));
        float _S290 = betaMExt_1 * midM_0;
        Vector<float, 3>  transmittance_1 = Vector<float, 3> ((F32_exp((- (betaR_1.x * midR_0 + _S290)))), (F32_exp((- (betaR_1.y * midR_0 + _S290)))), (F32_exp((- (betaR_1.z * midR_0 + _S290))))) * _S289;
        Vector<float, 3>  _S291 = sumM_0 + transmittance_1 * (Vector<float, 3> )dM_0;
        sumR_0 = sumR_0 + transmittance_1 * (Vector<float, 3> )dR_0;
        sumM_0 = _S291;
        depthR_1 = depthR_2;
        depthM_2 = depthM_3;
        tPrev_1 = tNext_1;
        i_17 = _S287;
    }
    float _S292 = sunIrradianceTop_0(p_22);
    Vector<float, 3>  radiance_0 = (sumR_0 * betaR_1 * (Vector<float, 3> )phaseR_0 + sumM_0 * (Vector<float, 3> )(betaM_0 * phaseM_0)) * (Vector<float, 3> )_S292;
    Vector<float, 3>  radiance_1;
    if(hitsGround_0)
    {
        Vector<float, 3>  groundPoint_0 = Vector<float, 3> (rayDir_1.x * tGround_1, _S281 + _S282 * tGround_1, rayDir_1.z * tGround_1);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S278), 0.0f, 1.0f);
        Vector<float, 3>  _S293 = sampleTransmittanceLut_0(p_22, 0.0f, lutMuFor_0(groundPoint_0, _S278));
        float _S294 = betaMExt_1 * depthM_2;
        radiance_1 = radiance_0 + Vector<float, 3> ((F32_exp((- (betaR_1.x * depthR_1 + _S294)))), (F32_exp((- (betaR_1.y * depthR_1 + _S294)))), (F32_exp((- (betaR_1.z * depthR_1 + _S294))))) * _S293 * (Vector<float, 3> )(p_22->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S292);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S295;
    if(!hitsGround_0)
    {
        _S295 = includeSunDisc_0;
    }
    else
    {
        _S295 = false;
    }
    if(_S295)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_22->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S296 = betaMExt_1 * depthM_2;
            Vector<float, 3>  viewT_0 = Vector<float, 3> ((F32_exp((- (betaR_1.x * depthR_1 + _S296)))), (F32_exp((- (betaR_1.y * depthR_1 + _S296)))), (F32_exp((- (betaR_1.z * depthR_1 + _S296)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_1 = solidAngle_0;
            }
            else
            {
                hc_1 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * (Vector<float, 3> )(_S292 / hc_1);
        }
    }
    return radiance_1;
}

static Vector<float, 3>  environmentRadiance_0(Environment_0 * e_0, Vector<float, 3>  origin_1, Vector<float, 3>  dir_2, bool includeSunDisc_1)
{
    if((e_0->envMode_0) == int(1))
    {
        Vector<float, 3>  _S297 = skyRadiance_0(&e_0->sky_0, origin_1.y, dir_2, includeSunDisc_1);
        return _S297;
    }
    return e_0->uniformRadiance_0;
}

static AirSegment_0 airSegment_0(SkyInput_0 * p_23, float originAltitude_2, Vector<float, 3>  rayDir_2, float dist_2, float u1_0, float u2_0)
{
    AirSegment_0 seg_0;
    Vector<float, 3>  _S298 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&seg_0)->airIn_0 = _S298;
    (&seg_0)->airT_0 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    (&seg_0)->shadowAt_0 = -1.0f;
    Vector<float, 3>  _S299 = sunDirection_0(p_23);
    float _S300 = p_23->planetRadius_0;
    float planetRadius_6;
    if((p_23->planetRadius_0) > 1000.0f)
    {
        planetRadius_6 = _S300;
    }
    else
    {
        planetRadius_6 = 1000.0f;
    }
    float _S301 = p_23->scaleHeight_0;
    float scaleHeight_4;
    if((p_23->scaleHeight_0) > 1.0f)
    {
        scaleHeight_4 = _S301;
    }
    else
    {
        scaleHeight_4 = 1.0f;
    }
    float atmosphereHeight_2 = scaleHeight_4 * 8.0f;
    float observerAltitude_2;
    if(originAltitude_2 > 0.0f)
    {
        observerAltitude_2 = originAltitude_2;
    }
    else
    {
        observerAltitude_2 = 0.0f;
    }
    float _S302 = planetRadius_6 + observerAltitude_2;
    float _S303 = rayDir_2.y;
    float b_8 = _S302 * _S303;
    float cGround_2 = shellC_0(observerAltitude_2, planetRadius_6, 0.0f);
    float tTop_2 = shellExit_0(b_8, shellC_0(observerAltitude_2, planetRadius_6, atmosphereHeight_2));
    bool _S304;
    if(tTop_2 <= 0.0f)
    {
        _S304 = true;
    }
    else
    {
        _S304 = !(dist_2 > 0.0f);
    }
    if(_S304)
    {
        return seg_0;
    }
    float tGround_2 = shellEnter_0(b_8, cGround_2);
    float tMax_2;
    if(tGround_2 > 0.0f)
    {
        tMax_2 = tGround_2;
    }
    else
    {
        tMax_2 = tTop_2;
    }
    if(dist_2 < tMax_2)
    {
        tMax_2 = dist_2;
    }
    Vector<float, 3>  betaR_2 = rayleighCoefficients_0();
    float betaM_1 = mieCoefficient_0(p_23->turbidity_0);
    float betaMExt_2 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rayDir_2, _S299), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_17 = clampf_0(p_23->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S305 = g_17 * g_17;
    float hgDenom_1 = 1.0f + _S305 - 2.0f * g_17 * cosTheta_1;
    float _S306 = 1.0f - _S305;
    float _S307 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        observerAltitude_2 = hgDenom_1;
    }
    else
    {
        observerAltitude_2 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S306 / (_S307 * (F32_sqrt((observerAltitude_2))));
    float tPrev_2 = 0.0f;
    Vector<float, 3>  sumR_1 = _S298;
    Vector<float, 3>  sumM_1 = _S298;
    float u_3 = u1_0;
    float pickedFrom_0 = -1.0f;
    float pickedSpan_0 = 0.0f;
    int32_t i_18 = int(0);
    float depthR_3 = 0.0f;
    float depthM_4 = 0.0f;
    float lumTotal_0 = 0.0f;
    for(;;)
    {
        if(i_18 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S308 = i_18 + int(1);
        float tNext_2 = tMax_2 * float(_S308 * _S308) * 0.00173611112404615f;
        float dt_2 = tNext_2 - tPrev_2;
        float tMid_2 = (tPrev_2 + tNext_2) * 0.5f;
        float u_4;
        float pickedFrom_1;
        float pickedSpan_1;
        if(dt_2 <= 0.0f)
        {
            u_4 = u_3;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            tPrev_2 = tNext_2;
            u_3 = u_4;
            pickedFrom_0 = pickedFrom_1;
            pickedSpan_0 = pickedSpan_1;
            i_18 = _S308;
            continue;
        }
        float h_6 = altitudeFromQ_0(cGround_2 + 2.0f * tMid_2 * b_8 + tMid_2 * tMid_2, planetRadius_6);
        float hc_2;
        if(h_6 < 0.0f)
        {
            hc_2 = 0.0f;
        }
        else
        {
            hc_2 = h_6;
        }
        float _S309 = - hc_2;
        float dR_1 = (F32_exp((_S309 / scaleHeight_4))) * dt_2;
        float dM_1 = (F32_exp((_S309 / 1200.0f))) * dt_2;
        float midR_1 = depthR_3 + 0.5f * dR_1;
        float midM_1 = depthM_4 + 0.5f * dM_1;
        float depthR_4 = depthR_3 + dR_1;
        float depthM_5 = depthM_4 + dM_1;
        Vector<float, 3>  _S310 = sampleTransmittanceLut_0(p_23, hc_2, lutMuFor_0(Vector<float, 3> (rayDir_2.x * tMid_2, _S302 + _S303 * tMid_2, rayDir_2.z * tMid_2), _S299));
        float _S311 = betaMExt_2 * midM_1;
        Vector<float, 3>  transmittance_2 = Vector<float, 3> ((F32_exp((- (betaR_2.x * midR_1 + _S311)))), (F32_exp((- (betaR_2.y * midR_1 + _S311)))), (F32_exp((- (betaR_2.z * midR_1 + _S311))))) * _S310;
        Vector<float, 3>  _S312 = sumR_1 + transmittance_2 * (Vector<float, 3> )dR_1;
        Vector<float, 3>  _S313 = sumM_1 + transmittance_2 * (Vector<float, 3> )dM_1;
        Vector<float, 3>  c_23 = transmittance_2 * (betaR_2 * (Vector<float, 3> )(phaseR_1 * dR_1) + (Vector<float, 3> )(betaM_1 * (phaseM_1 * dM_1)));
        float lum_0 = c_23.x + c_23.y + c_23.z;
        float lumTotal_1;
        if(lum_0 > 0.0f)
        {
            float lumTotal_2 = lumTotal_0 + lum_0;
            float keep_0 = lum_0 / lumTotal_2;
            if(u_3 < keep_0)
            {
                u_4 = u_3 / keep_0;
                pickedFrom_1 = tPrev_2;
                pickedSpan_1 = dt_2;
            }
            else
            {
                u_4 = (u_3 - keep_0) / (1.0f - keep_0);
                pickedFrom_1 = pickedFrom_0;
                pickedSpan_1 = pickedSpan_0;
            }
            lumTotal_1 = lumTotal_2;
        }
        else
        {
            u_4 = u_3;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            lumTotal_1 = lumTotal_0;
        }
        sumR_1 = _S312;
        sumM_1 = _S313;
        depthR_3 = depthR_4;
        depthM_4 = depthM_5;
        lumTotal_0 = lumTotal_1;
        tPrev_2 = tNext_2;
        u_3 = u_4;
        pickedFrom_0 = pickedFrom_1;
        pickedSpan_0 = pickedSpan_1;
        i_18 = _S308;
    }
    float _S314 = sunIrradianceTop_0(p_23);
    (&seg_0)->airIn_0 = (sumR_1 * betaR_2 * (Vector<float, 3> )phaseR_1 + sumM_1 * (Vector<float, 3> )(betaM_1 * phaseM_1)) * (Vector<float, 3> )_S314;
    float _S315 = betaMExt_2 * depthM_4;
    (&seg_0)->airT_0 = Vector<float, 3> ((F32_exp((- (betaR_2.x * depthR_3 + _S315)))), (F32_exp((- (betaR_2.y * depthR_3 + _S315)))), (F32_exp((- (betaR_2.z * depthR_3 + _S315)))));
    if(pickedFrom_0 >= 0.0f)
    {
        (&seg_0)->shadowAt_0 = pickedFrom_0 + clampf_0(u2_0, 0.0f, 1.0f) * pickedSpan_0;
    }
    return seg_0;
}

static float airShadow_0(Scene_0 * s_8, StructuredBuffer<float> bounds_9, StructuredBuffer<Vector<float, 2> > drift_5, Rng_0 * rng_7, AirSegment_0 * seg_1, Vector<float, 3>  ro_6, Vector<float, 3>  rd_6, int32_t * steps_7)
{
    bool _S316;
    if((s_8->aerialMode_0) < int(2))
    {
        _S316 = true;
    }
    else
    {
        _S316 = (seg_1->shadowAt_0) < 0.0f;
    }
    if(_S316)
    {
        return 1.0f;
    }
    float _S317 = sceneTransmittance_0(s_8, bounds_9, drift_5, rng_7, ro_6 + rd_6 * (Vector<float, 3> )seg_1->shadowAt_0, s_8->sunDir_0, steps_7);
    return _S317;
}

static Vector<float, 3>  sampleHG_0(Rng_0 * rng_8, Vector<float, 3>  wo_0, float g_18, float * cosT_6)
{
    float _S318 = clamp_1(g_18, -0.99900001287460327f, 0.99900001287460327f);
    float u1_1 = randFloat_0(rng_8);
    float u2_1 = randFloat_0(rng_8);
    if((F32_abs((_S318))) < 0.00100000004749745f)
    {
        *cosT_6 = 1.0f - 2.0f * u1_1;
    }
    else
    {
        float _S319 = _S318 * _S318;
        float _S320 = 2.0f * _S318;
        float s_9 = (1.0f - _S319) / (1.0f - _S318 + _S320 * u1_1);
        *cosT_6 = (1.0f + _S319 - s_9 * s_9) / _S320;
    }
    float _S321 = clamp_1(*cosT_6, -1.0f, 1.0f);
    *cosT_6 = _S321;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S321 * _S321))))));
    float phi_0 = 6.28318548202514648f * u2_1;
    Vector<float, 3>  w_2 = normalize_0(wo_0);
    Vector<float, 3>  a_5;
    if((F32_abs((w_2.y))) < 0.94999998807907104f)
    {
        a_5 = Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_5 = Vector<float, 3> (1.0f, 0.0f, 0.0f);
    }
    Vector<float, 3>  u_5 = normalize_0(cross_0(a_5, w_2));
    return normalize_0((Vector<float, 3> )(sinT_0 * (F32_cos((phi_0)))) * u_5 + (Vector<float, 3> )(sinT_0 * (F32_sin((phi_0)))) * cross_0(w_2, u_5) + (Vector<float, 3> )*cosT_6 * w_2);
}

static Vector<float, 3>  sampleDraine_0(Rng_0 * rng_9, Vector<float, 3>  wo_1, float g_19, float a_6, float * cosT_7)
{
    Vector<float, 3>  dir_3 = sampleHG_0(rng_9, wo_1, g_19, cosT_7);
    if(!(a_6 > 0.0f))
    {
        return dir_3;
    }
    Vector<float, 3>  dir_4 = dir_3;
    int32_t i_19 = int(0);
    for(;;)
    {
        if(i_19 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S322 = randFloat_0(rng_9);
        if((_S322 * (1.0f + a_6)) <= (1.0f + a_6 * *cosT_7 * *cosT_7))
        {
            break;
        }
        Vector<float, 3>  _S323 = sampleHG_0(rng_9, wo_1, g_19, cosT_7);
        int32_t i_20 = i_19 + int(1);
        dir_4 = _S323;
        i_19 = i_20;
    }
    return dir_4;
}

static Vector<float, 3>  samplePhaseDir_0(PhaseInput_0 * p_24, Rng_0 * rng_10, Vector<float, 3>  wo_2, float * weight_0)
{
    float cosT_8;
    Vector<float, 3>  dir_5;
    float _S324;
    if((p_24->useIce_0) != int(0))
    {
        float _S325 = randFloat_0(rng_10);
        if(_S325 < 0.72000002861022949f)
        {
            Vector<float, 3>  _S326 = sampleHG_0(rng_10, wo_2, 0.85000002384185791f, &cosT_8);
            dir_5 = _S326;
        }
        else
        {
            Vector<float, 3>  _S327 = sampleHG_0(rng_10, wo_2, 0.0f, &cosT_8);
            dir_5 = _S327;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_8, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S324 = phaseIce_0(cosT_8) / pdf_0;
        }
        else
        {
            _S324 = 0.0f;
        }
        *weight_0 = _S324;
    }
    else
    {
        float _S328 = randFloat_0(rng_10);
        if(_S328 < (p_24->draineW_0))
        {
            Vector<float, 3>  _S329 = sampleDraine_0(rng_10, wo_2, p_24->draineG_0, p_24->draineAlpha_0, &cosT_8);
            dir_5 = _S329;
        }
        else
        {
            Vector<float, 3>  _S330 = sampleHG_0(rng_10, wo_2, p_24->hgG_0, &cosT_8);
            dir_5 = _S330;
        }
        float _S331 = phaseLiquid_0(p_24, cosT_8);
        if(_S331 > 9.99999971718068537e-10f)
        {
            _S324 = 1.0f;
        }
        else
        {
            _S324 = 0.0f;
        }
        *weight_0 = _S324;
    }
    return dir_5;
}

static TraceResult_0 trace_0(Scene_0 * s_10, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_10, StructuredBuffer<Vector<float, 2> > drift_6, Rng_0 * rng_11, Vector<float, 3>  ro_7, Vector<float, 3>  rd_7)
{
    TraceResult_0 r_6;
    (&r_6)->pathRadiance_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&r_6)->scatterEvents_0 = int(0);
    (&r_6)->capped_0 = int(0);
    (&r_6)->trackingSteps_0 = int(0);
    Vector<float, 3>  throughput_0 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    int32_t _S332 = (I32_min((s_10->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_10->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S332 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    if(sunAlongCamera_0)
    {
        Rng_0 _S333 = *rng_11;
        Rng_0 _S334 = splitRng_0(&_S333, 1510U);
        Rng_0 segmentRng_0 = _S334;
        Rng_0 _S335 = *rng_11;
        Rng_0 _S336 = splitRng_0(&_S335, 1511U);
        Rng_0 _S337 = _S336;
        Vector<float, 3>  _S338 = cameraSegmentSun_0(s_10, ph_1, bounds_10, drift_6, &segmentRng_0, &_S337, ro_7, rd_7, &(&r_6)->trackingSteps_0);
        (&r_6)->pathRadiance_0 = (&r_6)->pathRadiance_0 + _S338;
    }
    bool _S339;
    if(((&s_10->environment_0)->envMode_0) == int(1))
    {
        _S339 = (s_10->aerialMode_0) != int(0);
    }
    else
    {
        _S339 = false;
    }
    Rng_0 _S340 = *rng_11;
    Rng_0 _S341 = splitRng_0(&_S340, 2590U);
    Rng_0 airRng_0 = _S341;
    Vector<float, 3>  env_0 = ro_7;
    Vector<float, 3>  _S342 = rd_7;
    int32_t bounce_0 = int(0);
    Vector<float, 3>  throughput_1 = throughput_0;
    for(;;)
    {
        if(bounce_0 < int(256))
        {
        }
        else
        {
            break;
        }
        if(bounce_0 >= _S332)
        {
            (&r_6)->capped_0 = int(1);
            break;
        }
        Vector<float, 3>  p_25;
        int32_t layer_1;
        bool _S343 = sceneFreeFlight_0(s_10, bounds_10, drift_6, rng_11, env_0, _S342, &p_25, &layer_1, &(&r_6)->trackingSteps_0);
        if(!_S343)
        {
            bool _S344 = bounce_0 == int(0);
            Vector<float, 3>  _S345 = environmentRadiance_0(&s_10->environment_0, env_0, _S342, _S344);
            if(_S344)
            {
                sunAlongCamera_0 = _S339;
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                sunAlongCamera_0 = (s_10->aerialMode_0) >= int(2);
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                float u1_2 = randFloat_0(&airRng_0);
                float u2_2 = randFloat_0(&airRng_0);
                AirSegment_0 _S346 = airSegment_0(&(&s_10->environment_0)->sky_0, env_0.y, _S342, 1.00000001504746622e+30f, u1_2, u2_2);
                AirSegment_0 _S347 = _S346;
                float _S348 = airShadow_0(s_10, bounds_10, drift_6, &airRng_0, &_S347, env_0, _S342, &(&r_6)->trackingSteps_0);
                env_0 = _S345 - _S346.airIn_0 * (Vector<float, 3> )(1.0f - _S348);
            }
            else
            {
                env_0 = _S345;
            }
            (&r_6)->pathRadiance_0 = (&r_6)->pathRadiance_0 + throughput_1 * env_0;
            break;
        }
        (&r_6)->scatterEvents_0 = (&r_6)->scatterEvents_0 + int(1);
        bool _S349 = bounce_0 == int(0);
        bool _S350;
        if(_S349)
        {
            _S350 = _S339;
        }
        else
        {
            _S350 = false;
        }
        Vector<float, 3>  throughput_2;
        if(_S350)
        {
            float u1_3 = randFloat_0(&airRng_0);
            float u2_3 = randFloat_0(&airRng_0);
            AirSegment_0 _S351 = airSegment_0(&(&s_10->environment_0)->sky_0, env_0.y, _S342, length_0(p_25 - env_0), u1_3, u2_3);
            AirSegment_0 _S352 = _S351;
            float _S353 = airShadow_0(s_10, bounds_10, drift_6, &airRng_0, &_S352, env_0, _S342, &(&r_6)->trackingSteps_0);
            (&r_6)->pathRadiance_0 = (&r_6)->pathRadiance_0 + throughput_1 * _S351.airIn_0 * (Vector<float, 3> )_S353;
            throughput_2 = throughput_1 * _S351.airT_0;
        }
        else
        {
            throughput_2 = throughput_1;
        }
        Vector<float, 3>  _S354 = s_10->albedo_0;
        Vector<float, 3>  matterAlbedo_1;
        PhaseInput_0 matterPhase_0;
        if(layer_1 != int(0))
        {
            matterPhase_0 = s_10->phase2_0;
            matterAlbedo_1 = s_10->albedo2_0;
        }
        else
        {
            matterPhase_0 = *ph_1;
            matterAlbedo_1 = _S354;
        }
        bool _S355;
        if(_S349)
        {
            _S355 = sunAlongCamera_0;
        }
        else
        {
            _S355 = false;
        }
        if(!_S355)
        {
            Vector<float, 3>  _S356 = s_10->sunDir_0;
            float _S357 = sceneTransmittance_0(s_10, bounds_10, drift_6, rng_11, p_25 + s_10->sunDir_0 * (Vector<float, 3> )s_10->shadowOffset_0, s_10->sunDir_0, &(&r_6)->trackingSteps_0);
            if(_S357 > 0.0f)
            {
                float _S358 = dot_0(_S342, _S356);
                PhaseInput_0 _S359 = matterPhase_0;
                float _S360 = phaseAt_0(&_S359, _S358);
                Vector<float, 3>  _S361 = throughput_2 * matterAlbedo_1 * (Vector<float, 3> )_S360 * (Vector<float, 3> )_S357;
                Vector<float, 3>  _S362 = sunIrradianceAt_0(s_10, p_25);
                (&r_6)->pathRadiance_0 = (&r_6)->pathRadiance_0 + _S361 * _S362;
            }
        }
        PhaseInput_0 _S363 = matterPhase_0;
        float w_3;
        Vector<float, 3>  _S364 = samplePhaseDir_0(&_S363, rng_11, _S342, &w_3);
        Vector<float, 3>  throughput_3 = throughput_2 * (matterAlbedo_1 * (Vector<float, 3> )w_3);
        Vector<float, 3>  _S365 = p_25;
        if(bounce_0 >= (s_10->rrStartBounce_0))
        {
            float p2_0 = clamp_1((F32_max((throughput_3.x), ((F32_max((throughput_3.y), (throughput_3.z)))))), 0.05000000074505806f, 1.0f);
            float _S366 = randFloat_0(rng_11);
            if(_S366 > p2_0)
            {
                break;
            }
            throughput_1 = throughput_3 / (Vector<float, 3> )p2_0;
        }
        else
        {
            throughput_1 = throughput_3;
        }
        int32_t bounce_1 = bounce_0 + int(1);
        env_0 = _S365;
        _S342 = _S364;
        bounce_0 = bounce_1;
    }
    return r_6;
}

static Vector<float, 3>  renderSample_0(Scene_0 * s_11, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_11, StructuredBuffer<Vector<float, 2> > drift_7, Vector<float, 3>  ro_8, Vector<float, 3>  rd_8, uint32_t seed_2)
{
    Rng_0 rng_12 = makeRng_0(seed_2);
    TraceResult_0 _S367 = trace_0(s_11, ph_2, bounds_11, drift_7, &rng_12, ro_8, rd_8);
    return _S367.pathRadiance_0;
}

void _cpuRenderRays(void* _S368, void* entryPointParams_0, void* _S369)
{
    ComputeThreadVaryingInput * _S370 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S368));
    int32_t i_21 = int32_t((_S370->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S370->groupThreadID).x);
    if(i_21 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Vector<float, 3>  * _S371 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->outRadiance_0)[i_21]);
    Vector<float, 3>  _S372 = renderSample_0(&(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->scene_0, &(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->phase_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->bounds_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->drift_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->origins_0.Load(i_21), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->directions_0.Load(i_21), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_21));
    *_S371 = _S372;
    return;
}

// [numthreads(64, 1, 1)]
SLANG_PRELUDE_EXPORT
void cpuRenderRays_Thread(ComputeThreadVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    _cpuRenderRays(varyingInput, entryPointParams, globalParams);
}
// [numthreads(64, 1, 1)]
SLANG_PRELUDE_EXPORT
void cpuRenderRays_Group(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    ComputeThreadVaryingInput threadInput = {};
    threadInput.groupID = varyingInput->startGroupID;
    for (uint32_t x = 0; x < 64; ++x)
    {
        threadInput.groupThreadID.x = x;
        _cpuRenderRays(&threadInput, entryPointParams, globalParams);
    }
}
// [numthreads(64, 1, 1)]
SLANG_PRELUDE_EXPORT
void cpuRenderRays(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
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
                cpuRenderRays_Group(&groupVaryingInput, entryPointParams, globalParams);
            }
        }
    }
}
