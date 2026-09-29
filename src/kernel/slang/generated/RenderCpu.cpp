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
    int32_t layer2On_0;
    Medium_0 medium2_0;
    MajorantGrid_0 grid2_0;
    Vector<float, 3>  albedo2_0;
    PhaseInput_0 phase2_0;
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

static float dot_1(Vector<float, 2>  x_3, Vector<float, 2>  y_1)
{
    return x_3.x * y_1.x + x_3.y * y_1.y;
}

static float length_1(Vector<float, 2>  x_4)
{
    return (F32_sqrt((dot_1(x_4, x_4))));
}

static Vector<float, 2>  min_0(Vector<float, 2>  x_5, Vector<float, 2>  y_2)
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
        result_0[i_0] = (F32_min((_slang_vector_get_element(x_5, i_0)), (_slang_vector_get_element(y_2, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static Vector<float, 2>  lerp_0(Vector<float, 2>  x_6, Vector<float, 2>  y_3, Vector<float, 2>  s_0)
{
    return x_6 + (y_3 - x_6) * s_0;
}

static int32_t clamp_0(int32_t x_7, int32_t minBound_0, int32_t maxBound_0)
{
    return (I32_min(((I32_max((x_7), (minBound_0)))), (maxBound_0)));
}

static float clamp_1(float x_8, float minBound_1, float maxBound_1)
{
    return (F32_min(((F32_max((x_8), (minBound_1)))), (maxBound_1)));
}

static float saturate_0(float x_9)
{
    return clamp_1(x_9, 0.0f, 1.0f);
}

static float smoothstep_0(float min_1, float max_0, float x_10)
{
    float _S8 = saturate_0((x_10 - min_1) / (max_0 - min_1));
    return _S8 * _S8 * (3.0f - (_S8 + _S8));
}

static Vector<float, 2>  abs_0(Vector<float, 2>  x_11)
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
        result_1[i_1] = (F32_abs((_slang_vector_get_element(x_11, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static Vector<float, 2>  max_1(Vector<float, 2>  x_12, Vector<float, 2>  y_4)
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
        result_2[i_2] = (F32_max((_slang_vector_get_element(x_12, i_2)), (_slang_vector_get_element(y_4, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static float lerp_1(float x_13, float y_5, float s_1)
{
    return x_13 + (y_5 - x_13) * s_1;
}

static bool all_0(Vector<bool, 2>  x_14)
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

static Vector<float, 2>  floor_0(Vector<float, 2>  x_15)
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
        result_4[i_4] = (F32_floor((_slang_vector_get_element(x_15, i_4))));
        i_4 = i_4 + int(1);
    }
    return result_4;
}

static Vector<float, 3>  floor_1(Vector<float, 3>  x_16)
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
        result_5[i_5] = (F32_floor((_slang_vector_get_element(x_16, i_5))));
        i_5 = i_5 + int(1);
    }
    return result_5;
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

static bool slabRange_0(Medium_0 * m_0, Vector<float, 3>  ro_0, Vector<float, 3>  rd_0, float * t0_0, float * t1_0)
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

static Dda_0 ddaInit_0(MajorantGrid_0 * g_0, Vector<float, 3>  ro_1, Vector<float, 3>  rd_1, float t_0)
{
    Dda_0 d_0;
    if((g_0->enabled_0) == int(0))
    {
        Vector<int32_t, 3>  _S14 = Vector<int32_t, 3> (int(0), int(0), int(0));
        (&d_0)->cell_0 = _S14;
        (&d_0)->stepDir_0 = _S14;
        Vector<float, 3>  _S15 = Vector<float, 3> (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_0)->tMax_0 = _S15;
        (&d_0)->tDelta_0 = _S15;
        return d_0;
    }
    Vector<float, 3>  p_0 = ro_1 + rd_1 * (Vector<float, 3> )t_0;
    Vector<float, 3>  _S16 = floor_1((p_0 - g_0->origin_0) / g_0->cellExtent_0);
    Vector<int32_t, 3>  _S17 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(_S16, 0), (int32_t)_slang_vector_get_element(_S16, 1), (int32_t)_slang_vector_get_element(_S16, 2)};
    (&d_0)->cell_0 = _S17;
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
        int32_t _S18 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            (&d_0)->stepDir_0[a_0] = int(0);
            (&d_0)->tMax_0[a_0] = 1.00000001504746622e+30f;
            (&d_0)->tDelta_0[a_0] = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S19 = _slang_vector_get_element(rd_1, _S18) > 0.0f;
            int32_t _S20;
            if(_S19)
            {
                _S20 = int(1);
            }
            else
            {
                _S20 = int(-1);
            }
            (&d_0)->stepDir_0[a_0] = _S20;
            float _S21 = g_0->origin_0[a_0];
            float _S22 = float((&d_0)->cell_0[a_0]);
            float _S23;
            if(_S19)
            {
                _S23 = 1.0f;
            }
            else
            {
                _S23 = 0.0f;
            }
            (&d_0)->tMax_0[a_0] = t_0 + (_S21 + (_S22 + _S23) * g_0->cellExtent_0[a_0] - _slang_vector_get_element(p_0, a_0)) / _slang_vector_get_element(rd_1, _S18);
            (&d_0)->tDelta_0[a_0] = (F32_abs((g_0->cellExtent_0[a_0] / _slang_vector_get_element(rd_1, _S18))));
        }
        a_0 = a_0 + int(1);
    }
    return d_0;
}

static Vector<uint32_t, 2>  pcg2d_0(Vector<uint32_t, 2>  v_0)
{
    Vector<uint32_t, 2>  _S24 = v_0 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S25 = _S24;
    _S25.x = _S25.x + _S24.y * 1664525U;
    _S25.y = _S25.y + _S25.x * 1664525U;
    Vector<uint32_t, 2>  _S26 = _S25 ^ (_S25 >> ((Vector<uint32_t, 2> )16U));
    _S25 = _S26;
    _S25.x = _S25.x + _S26.y * 1664525U;
    _S25.y = _S25.y + _S25.x * 1664525U;
    Vector<uint32_t, 2>  _S27 = _S25 ^ (_S25 >> ((Vector<uint32_t, 2> )16U));
    _S25 = _S27;
    return _S27;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_0, uint32_t salt_1)
{
    Vector<uint32_t, 2>  h_0 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_0.x), uint32_t(c_0.y)) ^ Vector<uint32_t, 2> (salt_1, salt_1 * 2654435761U));
    Vector<float, 2>  _S28 = Vector<float, 2> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1)};
    return _S28 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float convLife_0(float u_0)
{
    float _S29 = 1.0f - u_0;
    return 6.75f * u_0 * _S29 * _S29;
}

static float convVigour_0(ConvectionInput_0 * c_1, Vector<int32_t, 2>  slot_0)
{
    Vector<float, 2>  h_1 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_1->cvAge_0 + h_1.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_1.y);
}

static Vector<float, 2>  convCellCentre_0(Vector<int32_t, 2>  slot_1)
{
    Vector<float, 2>  _S30 = Vector<float, 2> {(float)_slang_vector_get_element(slot_1, 0), (float)_slang_vector_get_element(slot_1, 1)};
    return _S30 + (Vector<float, 2> )0.5f + (hash22_0(slot_1, 1759714724U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.69999998807907104f;
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
    float _S31 = convVigour_0(c_2, slot_2);
    if(_S31 <= 0.0f)
    {
        return;
    }
    Vector<float, 2>  ctr_0 = convCellCentre_0(slot_2);
    Vector<float, 2>  _S32 = a_1 - ctr_0;
    Vector<float, 2>  nearGap_0 = max_1(max_1(_S32, ctr_0 - b_0), Vector<float, 2> (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    Vector<float, 2>  farGap_0 = max_1(abs_0(_S32), abs_0(b_0 - ctr_0));
    float oHi_0 = _S31 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S31 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S31 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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
    Vector<float, 2>  _S33 = floor_0((a_2 + b_1) * (Vector<float, 2> )0.5f);
    Vector<int32_t, 2>  _S34 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S33, 0), (int32_t)_slang_vector_get_element(_S33, 1)};
    Vector<float, 2>  _S35 = Vector<float, 2> {(float)_slang_vector_get_element(_S34, 0), (float)_slang_vector_get_element(_S34, 1)};
    Vector<float, 2>  highEdge_0 = _S35 + (Vector<float, 2> )1.0f + (Vector<float, 2> )0.00009999999747379f;
    bool _S36;
    if(all_0(a_2 >= (_S35 - (Vector<float, 2> )0.00009999999747379f)))
    {
        _S36 = all_0(b_1 <= highEdge_0);
    }
    else
    {
        _S36 = false;
    }
    int32_t j_0;
    int32_t i_6;
    if(_S36)
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
                convSlotBound_0(c_3, _S34 + Vector<int32_t, 2> (i_6, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_6 = i_6 + int(1);
            }
            j_0 = j_0 + int(1);
        }
    }
    else
    {
        Vector<float, 2>  _S37 = floor_0(a_2);
        Vector<int32_t, 2>  _S38 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S37, 0), (int32_t)_slang_vector_get_element(_S37, 1)};
        Vector<int32_t, 2>  _S39 = Vector<int32_t, 2> (int(1), int(1));
        Vector<int32_t, 2>  i0_0 = _S38 - _S39;
        Vector<float, 2>  _S40 = floor_0(b_1);
        Vector<int32_t, 2>  _S41 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S40, 0), (int32_t)_slang_vector_get_element(_S40, 1)};
        Vector<int32_t, 2>  _S42 = _S41 + _S39;
        int32_t _S43 = i0_0.y;
        j_0 = _S43;
        for(;;)
        {
            if(j_0 <= (_S42.y))
            {
                _S36 = j_0 <= (_S43 + int(32));
            }
            else
            {
                _S36 = false;
            }
            if(_S36)
            {
            }
            else
            {
                break;
            }
            int32_t _S44 = i0_0.x;
            i_6 = _S44;
            for(;;)
            {
                bool _S45;
                if(i_6 <= (_S42.x))
                {
                    _S45 = i_6 <= (_S44 + int(32));
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
                convSlotBound_0(c_3, Vector<int32_t, 2> (i_6, j_0), a_2, b_1, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_6 = i_6 + int(1);
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
    bool _S46;
    if(high_0 < 0.0f)
    {
        _S46 = true;
    }
    else
    {
        _S46 = low_0 > ceiling_0;
    }
    if(_S46)
    {
        return 0.0f;
    }
    float _S47 = (F32_max((low_0), (0.0f)));
    float _S48 = (F32_min((high_0), (ceiling_0)));
    float _S49 = convUpdraftBound_0(c_6, Vector<float, 2> {lo_0.x, lo_0.z} - c_6->cvDrift_0, Vector<float, 2> {hi_0.x, hi_0.z} - c_6->cvDrift_0);
    float _S50 = convTowerHeight_0(c_6, _S49);
    if(_S50 <= 0.0f)
    {
        return 0.0f;
    }
    float _S51 = convLift_0(c_6, _S48);
    float inside_0 = _S50 - _S47 + _S51 + 0.00100000004749745f;
    if(inside_0 <= 0.0f)
    {
        return 0.0f;
    }
    return c_6->cvSigma_0 * (F32_sqrt((saturate_0(_S48 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_0) * 1.00001001358032227f;
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_1, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_17 = clamp_1(depth_0 / g_1->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_7 = clamp_0(int32_t((F32_floor((x_17)))), int(0), int(31));
    return lerp_0(disp_0.Load(i_7), disp_0.Load(i_7 + int(1)), (Vector<float, 2> )(x_17 - float(i_7)));
}

static void driftRange_0(GeneratorInput_0 * g_2, StructuredBuffer<Vector<float, 2> > disp_1, float d0_0, float d1_0, Vector<float, 2>  * lo_1, Vector<float, 2>  * hi_1)
{
    Vector<float, 2>  _S52 = driftAt_0(g_2, disp_1, d0_0);
    *lo_1 = _S52;
    *hi_1 = _S52;
    Vector<float, 2>  _S53 = driftAt_0(g_2, disp_1, d1_0);
    *lo_1 = min_0(*lo_1, _S53);
    *hi_1 = max_1(*hi_1, _S53);
    int32_t _S54 = clamp_0(int32_t((F32_ceil((clamp_1(d1_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int32_t k_0 = clamp_0(int32_t((F32_floor((clamp_1(d0_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_0 <= _S54)
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
    Vector<float, 2>  _S55 = floor_0(a_3);
    Vector<int32_t, 2>  _S56 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S55, 0), (int32_t)_slang_vector_get_element(_S55, 1)};
    Vector<int32_t, 2>  _S57 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  i0_1 = _S56 - _S57;
    Vector<float, 2>  _S58 = floor_0(b_2);
    Vector<int32_t, 2>  _S59 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S58, 0), (int32_t)_slang_vector_get_element(_S58, 1)};
    Vector<int32_t, 2>  _S60 = _S59 + _S57;
    int32_t _S61 = i0_1.y;
    int32_t j_1 = _S61;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S62;
        if(j_1 <= (_S60.y))
        {
            _S62 = j_1 <= (_S61 + int(32));
        }
        else
        {
            _S62 = false;
        }
        if(_S62)
        {
        }
        else
        {
            break;
        }
        int32_t _S63 = i0_1.x;
        int32_t i_8 = _S63;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S64;
            if(i_8 <= (_S60.x))
            {
                _S64 = i_8 <= (_S63 + int(32));
            }
            else
            {
                _S64 = false;
            }
            if(_S64)
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_0 = Vector<int32_t, 2> (i_8, j_1);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_8 = i_8 + int(1);
                continue;
            }
            Vector<float, 2>  _S65 = Vector<float, 2> {(float)_slang_vector_get_element(o_0, 0), (float)_slang_vector_get_element(o_0, 1)};
            Vector<float, 2>  c_7 = _S65 + (Vector<float, 2> )0.5f + (hash22_0(o_0, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(max_1(max_1(a_3 - c_7, c_7 - b_2), Vector<float, 2> (0.0f, 0.0f))) * 2.20000004768371582f);
            i_8 = i_8 + int(1);
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
    bool _S66;
    if(d1_1 < 0.0f)
    {
        _S66 = true;
    }
    else
    {
        _S66 = d0_1 > (g_4->streakLength_0);
    }
    if(_S66)
    {
        return 0.0f;
    }
    float _S67 = g_4->streakLength_0;
    float d0_2 = clamp_1(d0_1, 0.0f, g_4->streakLength_0);
    float d1_2 = clamp_1(d1_1, 0.0f, g_4->streakLength_0);
    float subl_0 = (F32_exp((- g_4->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_4->detailAmount_0 * 1.5f * 1.79999995231628418f;
    Vector<float, 2>  driftLo_0;
    Vector<float, 2>  driftHi_0;
    driftRange_0(g_4, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S68 = cellFieldBound_0(g_4, Vector<float, 2> (lo_2.x, lo_2.z) - driftHi_0, Vector<float, 2> (hi_2.x, hi_2.z) - driftLo_0);
    return (F32_max((_S68 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((_S67), (1.0f)));
}

static float mediumBound_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_3, Vector<float, 3>  lo_3, Vector<float, 3>  hi_3)
{
    int32_t _S69 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S70 = convectionBound_0(&m_1->conv_0, lo_3, hi_3);
        return _S70;
    }
    if(_S69 == int(2))
    {
        float _S71 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_3, hi_3);
        return _S71;
    }
    return m_1->majorant_0;
}

static float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_1, StructuredBuffer<Vector<float, 2> > disp_4, Vector<int32_t, 3>  c_8, float fallback_0)
{
    int32_t _S72 = g_5->enabled_0;
    if((g_5->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S72 == int(2))
    {
        Vector<float, 3>  _S73 = Vector<float, 3> {(float)_slang_vector_get_element(c_8, 0), (float)_slang_vector_get_element(c_8, 1), (float)_slang_vector_get_element(c_8, 2)};
        Vector<float, 3>  lo_4 = g_5->origin_0 + _S73 * g_5->cellExtent_0;
        float _S74 = mediumBound_0(m_2, disp_4, lo_4, lo_4 + g_5->cellExtent_0);
        return _S74;
    }
    int32_t _S75 = c_8.x;
    bool _S76;
    if(_S75 < int(0))
    {
        _S76 = true;
    }
    else
    {
        _S76 = (c_8.y) < int(0);
    }
    if(_S76)
    {
        _S76 = true;
    }
    else
    {
        _S76 = (c_8.z) < int(0);
    }
    if(_S76)
    {
        _S76 = true;
    }
    else
    {
        _S76 = _S75 >= (g_5->dims_0.x);
    }
    if(_S76)
    {
        _S76 = true;
    }
    else
    {
        _S76 = (c_8.y) >= (g_5->dims_0.y);
    }
    if(_S76)
    {
        _S76 = true;
    }
    else
    {
        _S76 = (c_8.z) >= (g_5->dims_0.z);
    }
    if(_S76)
    {
        return fallback_0;
    }
    return bounds_1.Load((c_8.z * g_5->dims_0.y + c_8.y) * g_5->dims_0.x + _S75);
}

static float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_2)
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

static float randFloat_0(Rng_0 * r_2)
{
    uint32_t _S78 = r_2->state_0 * 747796405U + 2891336453U;
    r_2->state_0 = _S78;
    uint32_t word_0 = ((_S78 >> ((_S78 >> 28U) + 4U)) ^ _S78) * 277803737U;
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
        Dda_0 _S79 = *dda_0;
        float _S80 = ddaExit_0(&_S79);
        float _S81 = (F32_min((_S80), (tEnd_0)));
        if(!((*rate_0) > 0.0f))
        {
            if(_S81 >= tEnd_0)
            {
                return false;
            }
            *t_2 = _S81;
            ddaAdvance_0(dda_0);
            float _S82 = gridBound_0(m_3, g_6, bounds_2, drift_1, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S82 * scale_0;
            continue;
        }
        float uStep_0 = randFloat_0(rng_0);
        float _S83 = randFloat_0(rng_0);
        *uKeep_0 = _S83;
        float _S84 = randFloat_0(rng_0);
        *uLive_0 = _S84;
        float _S85 = *t_2 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / *rate_0;
        *t_2 = _S85;
        if(_S85 >= _S81)
        {
            if(_S81 >= tEnd_0)
            {
                return false;
            }
            *t_2 = _S81;
            ddaAdvance_0(dda_0);
            float _S86 = gridBound_0(m_3, g_6, bounds_2, drift_1, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S86 * scale_0;
            continue;
        }
        return true;
    }
    return false;
}

static MajorantGrid_0 gridFor_0(Medium_0 * m_4, MajorantGrid_0 * g_7, Vector<float, 3>  p_1)
{
    MajorantGrid_0 chosen_0 = *g_7;
    bool _S87;
    if((g_7->enabled_0) == int(2))
    {
        _S87 = (p_1.y) >= (m_4->slabBottom_0);
    }
    else
    {
        _S87 = false;
    }
    if(_S87)
    {
        _S87 = (p_1.y) <= (m_4->slabTop_0);
    }
    else
    {
        _S87 = false;
    }
    if(_S87)
    {
        (&chosen_0)->enabled_0 = int(0);
    }
    return chosen_0;
}

static float cellField_0(GeneratorInput_0 * g_8, Vector<float, 2>  q_0)
{
    Vector<float, 2>  gq_0 = (q_0 - g_8->cellDrift_0) / (Vector<float, 2> )(g_8->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_0(gq_0);
    Vector<int32_t, 2>  _S88 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
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
        int32_t i_9 = int(-1);
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
            Vector<int32_t, 2>  o_1 = _S88 + Vector<int32_t, 2> (i_9, j_2);
            if((hash22_0(o_1, 2654435769U).x) > (g_8->cellDensity_0))
            {
                i_9 = i_9 + int(1);
                continue;
            }
            Vector<float, 2>  _S89 = Vector<float, 2> {(float)_slang_vector_get_element(o_1, 0), (float)_slang_vector_get_element(o_1, 1)};
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(gq_0 - (_S89 + (Vector<float, 2> )0.5f + (hash22_0(o_1, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f)) * 2.20000004768371582f);
            i_9 = i_9 + int(1);
        }
        j_2 = j_2 + int(1);
        acc_2 = acc_3;
    }
    return acc_2 * g_8->cellStrength_0;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_1)
{
    Vector<uint32_t, 3>  _S90 = v_1 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S91 = _S90;
    _S91.x = _S91.x + _S90.y * _S90.z;
    _S91.y = _S91.y + _S91.z * _S91.x;
    _S91.z = _S91.z + _S91.x * _S91.y;
    Vector<uint32_t, 3>  _S92 = _S91 ^ (_S91 >> ((Vector<uint32_t, 3> )16U));
    _S91 = _S92;
    _S91.x = _S91.x + _S92.y * _S92.z;
    _S91.y = _S91.y + _S91.z * _S91.x;
    _S91.z = _S91.z + _S91.x * _S91.y;
    return _S91;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_9)
{
    Vector<uint32_t, 3>  h_2 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_9.x), uint32_t(c_9.y), uint32_t(c_9.z)));
    Vector<float, 3>  _S93 = Vector<float, 3> {(float)_slang_vector_get_element(h_2, 0), (float)_slang_vector_get_element(h_2, 1), (float)_slang_vector_get_element(h_2, 2)};
    return _S93 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float gradientNoise_0(Vector<float, 3>  p_2)
{
    Vector<float, 3>  fi_0 = floor_1(p_2);
    Vector<int32_t, 3>  _S94 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_2 - fi_0;
    Vector<float, 3>  u_2 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S95 = u_2.x;
    float _S96 = u_2.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S94), f_0), dot_0(hash33_0(_S94 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S95), lerp_1(dot_0(hash33_0(_S94 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S94 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S95), _S96), lerp_1(lerp_1(dot_0(hash33_0(_S94 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S94 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S95), lerp_1(dot_0(hash33_0(_S94 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S94 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S95), _S96), u_2.z);
}

static float fbm_0(Vector<float, 3>  p_3, int32_t octaves_1)
{
    int32_t i_10 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S97 = p_3;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S97);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S98 = _S97 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_10 = i_10 + int(1);
        amp_0 = amp_1;
        _S97 = _S98;
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
    bool _S99;
    if(depth_1 < 0.0f)
    {
        _S99 = true;
    }
    else
    {
        _S99 = depth_1 > (g_9->streakLength_0);
    }
    if(_S99)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S100 = Vector<float, 2> {p_4.x, p_4.z};
    Vector<float, 2>  _S101 = driftAt_0(g_9, disp_5, depth_1);
    Vector<float, 2>  source_0 = _S100 - _S101;
    float _S102 = cellField_0(g_9, source_0);
    if(_S102 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S102 * (F32_exp((- g_9->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_9->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_9->streakLength_0, g_9->streakLength_0, depth_1)) * (F32_max((1.0f + g_9->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_9->detailScale_0).x, (source_0 / (Vector<float, 2> )g_9->detailScale_0).y, depth_1 / (F32_max((g_9->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_9->timeSeconds_0 * 0.00999999977648258f), g_9->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_9->opticalDepth_0 / (F32_max((g_9->streakLength_0), (1.0f)));
}

static float convUpdraft_0(ConvectionInput_0 * c_10, Vector<float, 2>  q_1)
{
    Vector<float, 2>  g_10 = q_1 / (Vector<float, 2> )c_10->cvSpacing_0;
    Vector<float, 2>  _S103 = floor_0(g_10);
    Vector<int32_t, 2>  _S104 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S103, 0), (int32_t)_slang_vector_get_element(_S103, 1)};
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
        int32_t i_11 = int(-1);
        for(;;)
        {
            if(i_11 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_3 = _S104 + Vector<int32_t, 2> (i_11, j_3);
            float _S105 = convVigour_0(c_10, slot_3);
            if(_S105 <= 0.0f)
            {
                i_11 = i_11 + int(1);
                continue;
            }
            Vector<float, 2>  d_3 = g_10 - convCellCentre_0(slot_3);
            float d2_1 = dot_1(d_3, d_3);
            float ko_0 = _S105 * convBump_0(d2_1, 0.75f);
            float kk_0 = _S105 * convBump_0(d2_1, 1.04999995231628418f);
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
                float _S106 = oTop_2;
                oTop_2 = oTop_1;
                oNext_2 = _S106;
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
                float _S107 = kTop_2;
                kTop_2 = kTop_1;
                kNext_2 = _S107;
            }
            oTop_1 = oTop_2;
            oNext_1 = oNext_2;
            kTop_1 = kTop_2;
            kNext_1 = kNext_2;
            i_11 = i_11 + int(1);
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

static float convPuffs_0(Vector<float, 3>  x_18)
{
    Vector<float, 3>  fl_0 = floor_1(x_18);
    Vector<int32_t, 3>  _S108 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fl_0, 0), (int32_t)_slang_vector_get_element(fl_0, 1), (int32_t)_slang_vector_get_element(fl_0, 2)};
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
    Vector<int32_t, 3>  _S109 = Vector<int32_t, 3> (dz_0, dy_0, dx_0);
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
                Vector<int32_t, 3>  off_0 = _S109 + Vector<int32_t, 3> (dx_0, dy_0, dz_0);
                Vector<float, 3>  _S110 = Vector<float, 3> {(float)_slang_vector_get_element(off_0, 0), (float)_slang_vector_get_element(off_0, 1), (float)_slang_vector_get_element(off_0, 2)};
                Vector<float, 3>  d_4 = _S110 + (Vector<float, 3> )0.5f + (Vector<float, 3> )0.25f * hash33_0(_S108 + off_0) - f_1;
                float _S111 = (F32_min((nearest_1), (dot_0(d_4, d_4))));
                int32_t dx_1 = dx_0 + int(1);
                nearest_1 = _S111;
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

static float convBillow_0(ConvectionInput_0 * c_11, Vector<float, 3>  p_5)
{
    Vector<float, 3>  _S112 = Vector<float, 3> (p_5.x, p_5.y - c_11->cvRise_0, p_5.z) / (Vector<float, 3> )c_11->cvBillowScale_0;
    int32_t i_12 = int(0);
    float amp_2 = 0.60000002384185791f;
    Vector<float, 3>  x_19 = _S112;
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
        Vector<float, 3>  x_20 = x_19 * (Vector<float, 3> )2.17000007629394531f;
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

static float convectionDensity_0(ConvectionInput_0 * c_12, Vector<float, 3>  p_6)
{
    float _S113 = p_6.y;
    float above_1 = _S113 - c_12->cvBase_0;
    bool _S114;
    if(above_1 < 0.0f)
    {
        _S114 = true;
    }
    else
    {
        _S114 = above_1 > (c_12->cvDepth_0 + c_12->cvBillow_0);
    }
    if(_S114)
    {
        return 0.0f;
    }
    Vector<float, 2>  q_2 = Vector<float, 2> {p_6.x, p_6.z} - c_12->cvDrift_0;
    float _S115 = convUpdraft_0(c_12, q_2);
    float _S116 = convTowerHeight_0(c_12, _S115);
    if(_S116 <= 0.0f)
    {
        return 0.0f;
    }
    float _S117 = convLift_0(c_12, above_1);
    float _S118 = _S116 - above_1;
    if((_S118 + _S117) <= 0.0f)
    {
        return 0.0f;
    }
    float inside_1;
    if((_S118 - _S117) >= 12.0f)
    {
        inside_1 = 12.0f;
    }
    else
    {
        float _S119 = convBillow_0(c_12, Vector<float, 3> (q_2.x, _S113, q_2.y));
        float inside_2 = _S118 + _S117 * _S119;
        if(inside_2 <= 0.0f)
        {
            return 0.0f;
        }
        inside_1 = inside_2;
    }
    return c_12->cvSigma_0 * (F32_sqrt((saturate_0(above_1 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1);
}

static float densityAt_0(Medium_0 * m_5, StructuredBuffer<Vector<float, 2> > disp_6, Vector<float, 3>  p_7)
{
    float _S120 = p_7.y;
    bool _S121;
    if(_S120 < (m_5->slabBottom_0))
    {
        _S121 = true;
    }
    else
    {
        _S121 = _S120 > (m_5->slabTop_0);
    }
    if(_S121)
    {
        return 0.0f;
    }
    int32_t _S122 = m_5->mode_0;
    if((m_5->mode_0) == int(0))
    {
        return m_5->density_0;
    }
    if(_S122 == int(2))
    {
        float _S123 = iceDensity_0(&m_5->gen_0, disp_6, p_7);
        return _S123;
    }
    if(_S122 == int(3))
    {
        float _S124 = convectionDensity_0(&m_5->conv_0, p_7);
        return _S124;
    }
    Vector<float, 3>  d_5 = (p_7 - m_5->coreCentre_0) / (Vector<float, 3> )(F32_max((m_5->coreRadius_0), (9.99999997475242708e-07f)));
    return m_5->density_0 + m_5->coreDensity_0 * (F32_exp((- dot_0(d_5, d_5))));
}

static float transmittance_0(Medium_0 * m_6, MajorantGrid_0 * g_11, StructuredBuffer<float> bounds_3, StructuredBuffer<Vector<float, 2> > disp_7, Rng_0 * rng_1, Vector<float, 3>  p_8, Vector<float, 3>  dir_0, int32_t * steps_1)
{
    float t0_1;
    float t1_1;
    bool _S125 = slabRange_0(m_6, p_8, dir_0, &t0_1, &t1_1);
    if(!_S125)
    {
        return 1.0f;
    }
    float _S126 = (F32_max((t0_1), (0.0f)));
    t0_1 = _S126;
    Dda_0 _S127 = ddaInit_0(g_11, p_8, dir_0, _S126);
    Dda_0 dda_1 = _S127;
    float _S128 = m_6->majorant_0;
    float _S129 = gridBound_0(m_6, g_11, bounds_3, disp_7, (&dda_1)->cell_0, m_6->majorant_0);
    float localMaj_0 = _S129;
    int32_t i_13 = int(0);
    float t_3 = _S126;
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
        Dda_0 _S130 = dda_1;
        float _S131 = ddaExit_0(&_S130);
        float _S132 = (F32_min((_S131), (t1_1)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S132 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S133 = gridBound_0(m_6, g_11, bounds_3, disp_7, (&dda_1)->cell_0, _S128);
            localMaj_0 = _S133;
            t_3 = _S132;
            i_13 = i_13 + int(1);
            continue;
        }
        float _S134 = randFloat_0(rng_1);
        float t_4 = t_3 - (F32_log(((F32_max((1.0f - _S134), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_4 >= _S132)
        {
            if(_S132 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S135 = gridBound_0(m_6, g_11, bounds_3, disp_7, (&dda_1)->cell_0, _S128);
            localMaj_0 = _S135;
            t_3 = _S132;
            i_13 = i_13 + int(1);
            continue;
        }
        float _S136 = densityAt_0(m_6, disp_7, p_8 + dir_0 * (Vector<float, 3> )t_4);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S136 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S137 = randFloat_0(rng_1);
            if(_S137 > 0.5f)
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

static float sceneTransmittance_0(Scene_0 * s_4, StructuredBuffer<float> bounds_4, StructuredBuffer<Vector<float, 2> > drift_2, Rng_0 * rng_2, Vector<float, 3>  p_9, Vector<float, 3>  dir_1, int32_t * steps_2)
{
    float _S138 = transmittance_0(&s_4->medium_0, &s_4->grid_0, bounds_4, drift_2, rng_2, p_9, dir_1, steps_2);
    bool _S139;
    if((s_4->layer2On_0) != int(0))
    {
        _S139 = _S138 > 0.0f;
    }
    else
    {
        _S139 = false;
    }
    float tr_3;
    if(_S139)
    {
        MajorantGrid_0 _S140 = gridFor_0(&s_4->medium2_0, &s_4->grid2_0, p_9);
        MajorantGrid_0 _S141 = _S140;
        float _S142 = transmittance_0(&s_4->medium2_0, &_S141, bounds_4, drift_2, rng_2, p_9, dir_1, steps_2);
        tr_3 = _S138 * _S142;
    }
    else
    {
        tr_3 = _S138;
    }
    return tr_3;
}

static float hg_0(float cosT_0, float g_12)
{
    float _S143 = g_12 * g_12;
    float d_6 = 1.0f + _S143 - 2.0f * g_12 * cosT_0;
    return (1.0f - _S143) / (12.56637096405029297f * d_6 * (F32_sqrt(((F32_max((d_6), (9.99999997475242708e-07f)))))));
}

static float phaseIce_0(float cosT_1)
{
    float t_5 = ((F32_acos((clamp_1(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_1(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_5 * t_5))) * 0.34999999403953552f;
}

static float draine_0(float cosT_2, float g_13, float a_4)
{
    float _S144 = g_13 * g_13;
    float _S145 = 2.0f * g_13;
    float d_7 = 1.0f + _S144 - _S145 * cosT_2;
    return (1.0f - _S144) / (12.56637096405029297f * d_7 * (F32_sqrt(((F32_max((d_7), (9.99999997475242708e-07f))))))) * (1.0f + a_4 * cosT_2 * cosT_2) / (1.0f + a_4 * (1.0f + _S145 * g_13) / 3.0f);
}

static float phaseLiquid_0(PhaseInput_0 * p_10, float cosT_3)
{
    return (1.0f - p_10->draineW_0) * hg_0(cosT_3, p_10->hgG_0) + p_10->draineW_0 * draine_0(cosT_3, p_10->draineG_0, p_10->draineAlpha_0);
}

static float phaseAt_0(PhaseInput_0 * p_11, float cosT_4)
{
    float _S146;
    if((p_11->useIce_0) != int(0))
    {
        _S146 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S147 = phaseLiquid_0(p_11, cosT_4);
        _S146 = _S147;
    }
    return _S146;
}

static float phaseCamera_0(PhaseInput_0 * p_12, float cosT_5)
{
    float _S148 = phaseAt_0(p_12, cosT_5);
    float _S149 = p_12->lobeWeight_0;
    float v_2;
    if((p_12->lobeWeight_0) > 0.0f)
    {
        v_2 = _S148 + _S149 * hg_0(cosT_5, p_12->lobeG_0);
    }
    else
    {
        v_2 = _S148;
    }
    return v_2;
}

static float sunIrradianceTop_0(SkyInput_0 * p_13)
{
    return 20.0f * p_13->sunIntensity_0;
}

static float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static Vector<float, 3>  normalizeExact_0(Vector<float, 3>  v_3)
{
    float len2_0 = dot_0(v_3, v_3);
    if(len2_0 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    return v_3 * (Vector<float, 3> )(1.0f / (F32_sqrt((len2_0))));
}

static Vector<float, 3>  sunDirection_0(SkyInput_0 * p_14)
{
    float az_0 = toRadians_0(p_14->sunAzimuth_0);
    float el_0 = toRadians_0(p_14->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(Vector<float, 3> ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static float lutMuFor_0(Vector<float, 3>  geocentric_0, Vector<float, 3>  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S150;
    if(len_0 > 1.0f)
    {
        _S150 = dot_0(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S150 = dot_0(geocentric_0, sun_0);
    }
    return _S150;
}

static float clampf_0(float v_4, float lo_5, float hi_4)
{
    float _S151;
    if(v_4 < lo_5)
    {
        _S151 = lo_5;
    }
    else
    {
        if(v_4 > hi_4)
        {
            _S151 = hi_4;
        }
        else
        {
            _S151 = v_4;
        }
    }
    return _S151;
}

static Vector<float, 3>  sampleTransmittanceLut_0(SkyInput_0 * p_15, float altitude_0, float mu_0)
{
    StructuredBuffer<float> _S152 = p_15->transmittanceLut_0;
    if(uint32_t(StructuredBuffer_getCount_0(p_15->transmittanceLut_0)) < 49152U)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float _S153 = p_15->scaleHeight_0;
    float scaleHeight_1;
    if((p_15->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S153;
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
    float _S154 = fx_1 - float(x0_1);
    float _S155 = fy_1 - float(y0_1);
    int32_t _S156 = y0_1 * int(256);
    int32_t _S157 = (_S156 + x0_1) * int(3);
    int32_t _S158 = (_S156 + x1_1) * int(3);
    int32_t _S159 = y1_1 * int(256);
    int32_t _S160 = (_S159 + x0_1) * int(3);
    int32_t _S161 = (_S159 + x1_1) * int(3);
    Vector<float, 3>  out_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    int32_t c_13 = int(0);
    for(;;)
    {
        if(c_13 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S162 = 1.0f - _S154;
        float r_3 = (_S152.Load(_S157 + c_13) * _S162 + _S152.Load(_S158 + c_13) * _S154) * (1.0f - _S155) + (_S152.Load(_S160 + c_13) * _S162 + _S152.Load(_S161 + c_13) * _S154) * _S155;
        if(c_13 == int(0))
        {
            out_0.x = r_3;
        }
        else
        {
            if(c_13 == int(1))
            {
                out_0.y = r_3;
            }
            else
            {
                out_0.z = r_3;
            }
        }
        c_13 = c_13 + int(1);
    }
    return out_0;
}

static Vector<float, 3>  sunTransmittanceAt_0(SkyInput_0 * p_16, Vector<float, 3>  worldPos_0)
{
    Vector<float, 3>  _S163 = sunDirection_0(p_16);
    float _S164 = p_16->planetRadius_0;
    float planetRadius_1;
    if((p_16->planetRadius_0) > 1000.0f)
    {
        planetRadius_1 = _S164;
    }
    else
    {
        planetRadius_1 = 1000.0f;
    }
    float _S165 = worldPos_0.y;
    float altitude_1;
    if(_S165 > 0.0f)
    {
        altitude_1 = _S165;
    }
    else
    {
        altitude_1 = 0.0f;
    }
    Vector<float, 3>  _S166 = sampleTransmittanceLut_0(p_16, altitude_1, lutMuFor_0(Vector<float, 3> (worldPos_0.x, planetRadius_1 + _S165, worldPos_0.z), _S163));
    return _S166;
}

static Vector<float, 3>  sunIrradianceAt_0(Scene_0 * s_5, Vector<float, 3>  p_17)
{
    if(((&s_5->environment_0)->envMode_0) == int(1))
    {
        float _S167 = sunIrradianceTop_0(&(&s_5->environment_0)->sky_0);
        Vector<float, 3>  _S168 = sunTransmittanceAt_0(&(&s_5->environment_0)->sky_0, p_17);
        return (Vector<float, 3> )_S167 * _S168;
    }
    return s_5->sunIrradiance_0;
}

static Vector<float, 3>  cameraSegmentSun_0(Scene_0 * s_6, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_5, StructuredBuffer<Vector<float, 2> > drift_3, Rng_0 * rng_3, Rng_0 * rng2_0, Vector<float, 3>  ro_2, Vector<float, 3>  rd_2, int32_t * steps_3)
{
    float ph0_0;
    float kept_0;
    Vector<float, 3>  keptAt_0;
    int32_t keptLayer_0;
    Rng_0 _S169 = *rng2_0;
    Vector<float, 3>  none_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float _S170 = (F32_max((s_6->neeTentativeScale_0), (1.0f)));
    float tA_0;
    float endA_0;
    bool _S171 = slabRange_0(&s_6->medium_0, ro_2, rd_2, &tA_0, &endA_0);
    float _S172 = (F32_max((tA_0), (0.0f)));
    tA_0 = _S172;
    Dda_0 _S173 = ddaInit_0(&s_6->grid_0, ro_2, rd_2, _S172);
    Dda_0 ddaA_0 = _S173;
    float _S174 = gridBound_0(&s_6->medium_0, &s_6->grid_0, bounds_5, drift_3, (&ddaA_0)->cell_0, (&s_6->medium_0)->majorant_0);
    float rateA_0 = _S174 * _S170;
    int32_t budgetA_0 = int(4096);
    float keepA_0 = 0.0f;
    float rouletteA_0 = 0.0f;
    bool haveA_0;
    if(_S171)
    {
        bool _S175 = segmentStep_0(&s_6->medium_0, &s_6->grid_0, bounds_5, drift_3, _S170, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
        haveA_0 = _S175;
    }
    else
    {
        haveA_0 = _S171;
    }
    float tB_0 = 0.0f;
    float endB_0 = 0.0f;
    bool haveB_0;
    if((s_6->layer2On_0) != int(0))
    {
        bool _S176 = slabRange_0(&s_6->medium2_0, ro_2, rd_2, &tB_0, &endB_0);
        haveB_0 = _S176;
    }
    else
    {
        haveB_0 = false;
    }
    float _S177 = (F32_max((tB_0), (0.0f)));
    tB_0 = _S177;
    MajorantGrid_0 _S178 = gridFor_0(&s_6->medium2_0, &s_6->grid2_0, ro_2);
    MajorantGrid_0 _S179 = _S178;
    Dda_0 _S180 = ddaInit_0(&_S179, ro_2, rd_2, _S177);
    Dda_0 ddaB_0 = _S180;
    MajorantGrid_0 _S181 = _S178;
    float _S182 = gridBound_0(&s_6->medium2_0, &_S181, bounds_5, drift_3, (&ddaB_0)->cell_0, (&s_6->medium2_0)->majorant_0);
    float rateB_0 = _S182 * _S170;
    int32_t budgetB_0 = int(4096);
    float keepB_0 = 0.0f;
    float rouletteB_0 = 0.0f;
    if(haveB_0)
    {
        MajorantGrid_0 _S183 = _S178;
        bool _S184 = segmentStep_0(&s_6->medium2_0, &_S183, bounds_5, drift_3, _S170, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S169, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
        haveB_0 = _S184;
    }
    float kept_1 = 0.0f;
    Vector<float, 3>  keptAt_1 = none_0;
    int32_t keptLayer_1 = int(0);
    float tr_4 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        bool _S185;
        if(haveA_0)
        {
            _S185 = true;
        }
        else
        {
            _S185 = haveB_0;
        }
        if(_S185)
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
        Vector<float, 3>  p_18 = ro_2 + rd_2 * (Vector<float, 3> )ph0_0;
        float sigma_0;
        if(takeA_0)
        {
            float _S186 = densityAt_0(&s_6->medium_0, drift_3, p_18);
            sigma_0 = _S186;
        }
        else
        {
            float _S187 = densityAt_0(&s_6->medium2_0, drift_3, p_18);
            sigma_0 = _S187;
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
            bool _S188 = segmentStep_0(&s_6->medium_0, &s_6->grid_0, bounds_5, drift_3, _S170, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
            haveA_0 = _S188;
        }
        else
        {
            MajorantGrid_0 _S189 = _S178;
            bool _S190 = segmentStep_0(&s_6->medium2_0, &_S189, bounds_5, drift_3, _S170, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S169, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
            haveB_0 = _S190;
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
    Vector<float, 3>  _S191 = s_6->sunDir_0;
    float _S192 = sceneTransmittance_0(s_6, bounds_5, drift_3, rng_3, keptAt_0 + s_6->sunDir_0 * (Vector<float, 3> )s_6->shadowOffset_0, s_6->sunDir_0, steps_3);
    Vector<float, 3>  _S193 = s_6->albedo_0;
    Vector<float, 3>  matterAlbedo_0;
    if(keptLayer_0 == int(0))
    {
        float _S194 = phaseCamera_0(ph_0, dot_0(rd_2, _S191));
        matterAlbedo_0 = _S193;
        ph0_0 = _S194;
    }
    else
    {
        float _S195 = phaseCamera_0(&s_6->phase2_0, dot_0(rd_2, _S191));
        matterAlbedo_0 = s_6->albedo2_0;
        ph0_0 = _S195;
    }
    Vector<float, 3>  _S196 = (Vector<float, 3> )total_0 * matterAlbedo_0 * (Vector<float, 3> )ph0_0 * (Vector<float, 3> )_S192;
    Vector<float, 3>  _S197 = sunIrradianceAt_0(s_6, keptAt_0);
    return _S196 * _S197;
}

static bool sampleFreeFlightUpTo_0(Medium_0 * m_7, MajorantGrid_0 * g_14, StructuredBuffer<float> bounds_6, StructuredBuffer<Vector<float, 2> > disp_8, Rng_0 * rng_4, Vector<float, 3>  ro_3, Vector<float, 3>  rd_3, float tLimit_0, Vector<float, 3>  * scatterPoint_0, float * distance_0, int32_t * steps_4)
{
    *scatterPoint_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_2;
    float t1_2;
    bool _S198 = slabRange_0(m_7, ro_3, rd_3, &t0_2, &t1_2);
    if(!_S198)
    {
        return false;
    }
    float _S199 = (F32_min((t1_2), (tLimit_0)));
    t1_2 = _S199;
    if(!(_S199 > t0_2))
    {
        return false;
    }
    float _S200 = (F32_max((t0_2), (0.0f)));
    Dda_0 _S201 = ddaInit_0(g_14, ro_3, rd_3, _S200);
    Dda_0 dda_2 = _S201;
    float _S202 = m_7->majorant_0;
    float _S203 = gridBound_0(m_7, g_14, bounds_6, disp_8, (&dda_2)->cell_0, m_7->majorant_0);
    float localMaj_1 = _S203;
    int32_t i_14 = int(0);
    float t_6 = _S200;
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
        Dda_0 _S204 = dda_2;
        float _S205 = ddaExit_0(&_S204);
        float _S206 = (F32_min((_S205), (t1_2)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S206 >= t1_2)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S207 = gridBound_0(m_7, g_14, bounds_6, disp_8, (&dda_2)->cell_0, _S202);
            localMaj_1 = _S207;
            t_6 = _S206;
            i_14 = i_14 + int(1);
            continue;
        }
        float _S208 = randFloat_0(rng_4);
        float t_7 = t_6 - (F32_log(((F32_max((1.0f - _S208), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_7 >= _S206)
        {
            if(_S206 >= t1_2)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S209 = gridBound_0(m_7, g_14, bounds_6, disp_8, (&dda_2)->cell_0, _S202);
            localMaj_1 = _S209;
            t_6 = _S206;
            i_14 = i_14 + int(1);
            continue;
        }
        Vector<float, 3>  p_19 = ro_3 + rd_3 * (Vector<float, 3> )t_7;
        float _S210 = randFloat_0(rng_4);
        float _S211 = densityAt_0(m_7, disp_8, p_19);
        if(_S210 < (_S211 / localMaj_1))
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

static bool sampleFreeFlight_0(Medium_0 * m_8, MajorantGrid_0 * g_15, StructuredBuffer<float> bounds_7, StructuredBuffer<Vector<float, 2> > disp_9, Rng_0 * rng_5, Vector<float, 3>  ro_4, Vector<float, 3>  rd_4, Vector<float, 3>  * scatterPoint_1, float * distance_1, int32_t * steps_5)
{
    bool _S212 = sampleFreeFlightUpTo_0(m_8, g_15, bounds_7, disp_9, rng_5, ro_4, rd_4, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_5);
    return _S212;
}

static bool sceneFreeFlight_0(Scene_0 * s_7, StructuredBuffer<float> bounds_8, StructuredBuffer<Vector<float, 2> > drift_4, Rng_0 * rng_6, Vector<float, 3>  ro_5, Vector<float, 3>  rd_5, Vector<float, 3>  * scatterAt_0, int32_t * layer_0, int32_t * steps_6)
{
    *layer_0 = int(0);
    float dist_0;
    if((s_7->layer2On_0) == int(0))
    {
        bool _S213 = sampleFreeFlight_0(&s_7->medium_0, &s_7->grid_0, bounds_8, drift_4, rng_6, ro_5, rd_5, scatterAt_0, &dist_0, steps_6);
        return _S213;
    }
    float a0_0;
    float a1_0;
    bool _S214 = slabRange_0(&s_7->medium_0, ro_5, rd_5, &a0_0, &a1_0);
    float b0_0;
    float b1_0;
    bool _S215 = slabRange_0(&s_7->medium2_0, ro_5, rd_5, &b0_0, &b1_0);
    bool secondFirst_0;
    if(_S215)
    {
        if(!_S214)
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
    MajorantGrid_0 _S216 = gridFor_0(&s_7->medium2_0, &s_7->grid2_0, ro_5);
    float _S217;
    if(secondFirst_0)
    {
        MajorantGrid_0 _S218 = _S216;
        bool _S219 = sampleFreeFlight_0(&s_7->medium2_0, &_S218, bounds_8, drift_4, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S219)
        {
            _S217 = dNear_1;
        }
        else
        {
            _S217 = 1.00000001504746622e+30f;
        }
        bool _S220 = sampleFreeFlightUpTo_0(&s_7->medium_0, &s_7->grid_0, bounds_8, drift_4, rng_6, ro_5, rd_5, _S217, &pFar_0, &dFar_0, steps_6);
        if(_S220)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(0);
            return true;
        }
        if(_S219)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(1);
            return true;
        }
    }
    else
    {
        bool _S221 = sampleFreeFlight_0(&s_7->medium_0, &s_7->grid_0, bounds_8, drift_4, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S221)
        {
            _S217 = dNear_1;
        }
        else
        {
            _S217 = 1.00000001504746622e+30f;
        }
        MajorantGrid_0 _S222 = _S216;
        bool _S223 = sampleFreeFlightUpTo_0(&s_7->medium2_0, &_S222, bounds_8, drift_4, rng_6, ro_5, rd_5, _S217, &pFar_0, &dFar_0, steps_6);
        if(_S223)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(1);
            return true;
        }
        if(_S221)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(0);
            return true;
        }
    }
    *scatterAt_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    return false;
}

static float shellC_0(float altitude_2, float planetRadius_2, float shellHeight_0)
{
    float d_8 = altitude_2 - shellHeight_0;
    return d_8 * (d_8 + 2.0f * planetRadius_2 + 2.0f * shellHeight_0);
}

static float shellExit_0(float b_4, float c_14)
{
    float disc_0 = b_4 * b_4 - c_14;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_4 + (F32_sqrt((disc_0)));
}

static float shellEnter_0(float b_5, float c_15)
{
    float disc_1 = b_5 * b_5 - c_15;
    if(disc_1 < 0.0f)
    {
        return -1.0f;
    }
    return - b_5 - (F32_sqrt((disc_1)));
}

static Vector<float, 3>  rayleighCoefficients_0()
{
    return Vector<float, 3> (5.80200003241770901e-06f, 0.00001355800031888f, 0.00003310000101919f);
}

static float mieCoefficient_0(float turbidity_1)
{
    return 3.99600003220257349e-06f * (turbidity_1 / 2.20000004768371582f);
}

static float altitudeFromQ_0(float q_3, float planetRadius_3)
{
    float rr_0 = planetRadius_3 * planetRadius_3 + q_3;
    float _S224;
    if(rr_0 > 0.0f)
    {
        _S224 = rr_0;
    }
    else
    {
        _S224 = 0.0f;
    }
    return q_3 / (planetRadius_3 + (F32_sqrt((_S224))));
}

static Vector<float, 3>  skyRadiance_0(SkyInput_0 * p_20, float originAltitude_0, Vector<float, 3>  rayDir_0, bool includeSunDisc_0)
{
    float hc_0;
    Vector<float, 3>  _S225 = sunDirection_0(p_20);
    float _S226 = p_20->planetRadius_0;
    float planetRadius_4;
    if((p_20->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S226;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S227 = p_20->scaleHeight_0;
    float scaleHeight_2;
    if((p_20->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S227;
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
    float _S228 = planetRadius_4 + observerAltitude_0;
    float _S229 = rayDir_0.y;
    float b_6 = _S228 * _S229;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_4, 0.0f);
    float tTop_0 = shellExit_0(b_6, shellC_0(observerAltitude_0, planetRadius_4, atmosphereHeight_0));
    if(tTop_0 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 0.0f, 0.0f);
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
    Vector<float, 3>  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_20->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_0, _S225), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_16 = clampf_0(p_20->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S230 = g_16 * g_16;
    float hgDenom_0 = 1.0f + _S230 - 2.0f * g_16 * cosTheta_0;
    float _S231 = 1.0f - _S230;
    float _S232 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S231 / (_S232 * (F32_sqrt((tPrev_0))));
    Vector<float, 3>  _S233 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    Vector<float, 3>  sumR_0 = _S233;
    Vector<float, 3>  sumM_0 = _S233;
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
        int32_t _S234 = i_15 + int(1);
        float tNext_0 = observerAltitude_0 * float(_S234 * _S234) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_15 = _S234;
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
        float _S235 = - hc_0;
        float dR_0 = (F32_exp((_S235 / scaleHeight_2))) * dt_0;
        float dM_0 = (F32_exp((_S235 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        Vector<float, 3>  _S236 = sampleTransmittanceLut_0(p_20, hc_0, lutMuFor_0(Vector<float, 3> (rayDir_0.x * tMid_0, _S228 + _S229 * tMid_0, rayDir_0.z * tMid_0), _S225));
        float _S237 = betaMExt_0 * depthM_1;
        Vector<float, 3>  transmittance_1 = Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_1 + _S237)))), (F32_exp((- (betaR_0.y * depthR_1 + _S237)))), (F32_exp((- (betaR_0.z * depthR_1 + _S237))))) * _S236;
        Vector<float, 3>  _S238 = sumM_0 + transmittance_1 * (Vector<float, 3> )dM_0;
        sumR_0 = sumR_0 + transmittance_1 * (Vector<float, 3> )dR_0;
        sumM_0 = _S238;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_15 = _S234;
    }
    float _S239 = sunIrradianceTop_0(p_20);
    Vector<float, 3>  radiance_0 = (sumR_0 * betaR_0 * (Vector<float, 3> )phaseR_0 + sumM_0 * (Vector<float, 3> )(betaM_0 * phaseM_0)) * (Vector<float, 3> )_S239;
    Vector<float, 3>  radiance_1;
    if(hitsGround_0)
    {
        Vector<float, 3>  groundPoint_0 = Vector<float, 3> (rayDir_0.x * tGround_0, _S228 + _S229 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S225), 0.0f, 1.0f);
        Vector<float, 3>  _S240 = sampleTransmittanceLut_0(p_20, 0.0f, lutMuFor_0(groundPoint_0, _S225));
        float _S241 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S241)))), (F32_exp((- (betaR_0.y * depthR_0 + _S241)))), (F32_exp((- (betaR_0.z * depthR_0 + _S241))))) * _S240 * (Vector<float, 3> )(p_20->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S239);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S242;
    if(!hitsGround_0)
    {
        _S242 = includeSunDisc_0;
    }
    else
    {
        _S242 = false;
    }
    if(_S242)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_20->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S243 = betaMExt_0 * depthM_0;
            Vector<float, 3>  viewT_0 = Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S243)))), (F32_exp((- (betaR_0.y * depthR_0 + _S243)))), (F32_exp((- (betaR_0.z * depthR_0 + _S243)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_0 = solidAngle_0;
            }
            else
            {
                hc_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * (Vector<float, 3> )(_S239 / hc_0);
        }
    }
    return radiance_1;
}

static Vector<float, 3>  environmentRadiance_0(Environment_0 * e_0, Vector<float, 3>  origin_1, Vector<float, 3>  dir_2, bool includeSunDisc_1)
{
    if((e_0->envMode_0) == int(1))
    {
        Vector<float, 3>  _S244 = skyRadiance_0(&e_0->sky_0, origin_1.y, dir_2, includeSunDisc_1);
        return _S244;
    }
    return e_0->uniformRadiance_0;
}

static Vector<float, 3>  sampleHG_0(Rng_0 * rng_7, Vector<float, 3>  wo_0, float g_17, float * cosT_6)
{
    float _S245 = clamp_1(g_17, -0.99900001287460327f, 0.99900001287460327f);
    float u1_0 = randFloat_0(rng_7);
    float u2_0 = randFloat_0(rng_7);
    if((F32_abs((_S245))) < 0.00100000004749745f)
    {
        *cosT_6 = 1.0f - 2.0f * u1_0;
    }
    else
    {
        float _S246 = _S245 * _S245;
        float _S247 = 2.0f * _S245;
        float s_8 = (1.0f - _S246) / (1.0f - _S245 + _S247 * u1_0);
        *cosT_6 = (1.0f + _S246 - s_8 * s_8) / _S247;
    }
    float _S248 = clamp_1(*cosT_6, -1.0f, 1.0f);
    *cosT_6 = _S248;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S248 * _S248))))));
    float phi_0 = 6.28318548202514648f * u2_0;
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
    Vector<float, 3>  u_3 = normalize_0(cross_0(a_5, w_2));
    return normalize_0((Vector<float, 3> )(sinT_0 * (F32_cos((phi_0)))) * u_3 + (Vector<float, 3> )(sinT_0 * (F32_sin((phi_0)))) * cross_0(w_2, u_3) + (Vector<float, 3> )*cosT_6 * w_2);
}

static Vector<float, 3>  sampleDraine_0(Rng_0 * rng_8, Vector<float, 3>  wo_1, float g_18, float a_6, float * cosT_7)
{
    Vector<float, 3>  dir_3 = sampleHG_0(rng_8, wo_1, g_18, cosT_7);
    if(!(a_6 > 0.0f))
    {
        return dir_3;
    }
    Vector<float, 3>  dir_4 = dir_3;
    int32_t i_16 = int(0);
    for(;;)
    {
        if(i_16 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S249 = randFloat_0(rng_8);
        if((_S249 * (1.0f + a_6)) <= (1.0f + a_6 * *cosT_7 * *cosT_7))
        {
            break;
        }
        Vector<float, 3>  _S250 = sampleHG_0(rng_8, wo_1, g_18, cosT_7);
        int32_t i_17 = i_16 + int(1);
        dir_4 = _S250;
        i_16 = i_17;
    }
    return dir_4;
}

static Vector<float, 3>  samplePhaseDir_0(PhaseInput_0 * p_21, Rng_0 * rng_9, Vector<float, 3>  wo_2, float * weight_0)
{
    float cosT_8;
    Vector<float, 3>  dir_5;
    float _S251;
    if((p_21->useIce_0) != int(0))
    {
        float _S252 = randFloat_0(rng_9);
        if(_S252 < 0.72000002861022949f)
        {
            Vector<float, 3>  _S253 = sampleHG_0(rng_9, wo_2, 0.85000002384185791f, &cosT_8);
            dir_5 = _S253;
        }
        else
        {
            Vector<float, 3>  _S254 = sampleHG_0(rng_9, wo_2, 0.0f, &cosT_8);
            dir_5 = _S254;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_8, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S251 = phaseIce_0(cosT_8) / pdf_0;
        }
        else
        {
            _S251 = 0.0f;
        }
        *weight_0 = _S251;
    }
    else
    {
        float _S255 = randFloat_0(rng_9);
        if(_S255 < (p_21->draineW_0))
        {
            Vector<float, 3>  _S256 = sampleDraine_0(rng_9, wo_2, p_21->draineG_0, p_21->draineAlpha_0, &cosT_8);
            dir_5 = _S256;
        }
        else
        {
            Vector<float, 3>  _S257 = sampleHG_0(rng_9, wo_2, p_21->hgG_0, &cosT_8);
            dir_5 = _S257;
        }
        float _S258 = phaseLiquid_0(p_21, cosT_8);
        if(_S258 > 9.99999971718068537e-10f)
        {
            _S251 = 1.0f;
        }
        else
        {
            _S251 = 0.0f;
        }
        *weight_0 = _S251;
    }
    return dir_5;
}

static TraceResult_0 trace_0(Scene_0 * s_9, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_9, StructuredBuffer<Vector<float, 2> > drift_5, Rng_0 * rng_10, Vector<float, 3>  ro_6, Vector<float, 3>  rd_6)
{
    TraceResult_0 r_4;
    (&r_4)->pathRadiance_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&r_4)->scatterEvents_0 = int(0);
    (&r_4)->capped_0 = int(0);
    (&r_4)->trackingSteps_0 = int(0);
    Vector<float, 3>  throughput_0 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    int32_t _S259 = (I32_min((s_9->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_9->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S259 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    if(sunAlongCamera_0)
    {
        Rng_0 _S260 = *rng_10;
        Rng_0 _S261 = splitRng_0(&_S260, 1510U);
        Rng_0 segmentRng_0 = _S261;
        Rng_0 _S262 = *rng_10;
        Rng_0 _S263 = splitRng_0(&_S262, 1511U);
        Rng_0 _S264 = _S263;
        Vector<float, 3>  _S265 = cameraSegmentSun_0(s_9, ph_1, bounds_9, drift_5, &segmentRng_0, &_S264, ro_6, rd_6, &(&r_4)->trackingSteps_0);
        (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + _S265;
    }
    Vector<float, 3>  _S266 = ro_6;
    Vector<float, 3>  _S267 = rd_6;
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
        if(bounce_0 >= _S259)
        {
            (&r_4)->capped_0 = int(1);
            break;
        }
        Vector<float, 3>  p_22;
        int32_t layer_1;
        bool _S268 = sceneFreeFlight_0(s_9, bounds_9, drift_5, rng_10, _S266, _S267, &p_22, &layer_1, &(&r_4)->trackingSteps_0);
        if(!_S268)
        {
            Vector<float, 3>  _S269 = environmentRadiance_0(&s_9->environment_0, _S266, _S267, bounce_0 == int(0));
            (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + throughput_1 * _S269;
            break;
        }
        (&r_4)->scatterEvents_0 = (&r_4)->scatterEvents_0 + int(1);
        Vector<float, 3>  _S270 = s_9->albedo_0;
        Vector<float, 3>  matterAlbedo_1;
        PhaseInput_0 matterPhase_0;
        if(layer_1 != int(0))
        {
            matterPhase_0 = s_9->phase2_0;
            matterAlbedo_1 = s_9->albedo2_0;
        }
        else
        {
            matterPhase_0 = *ph_1;
            matterAlbedo_1 = _S270;
        }
        bool _S271;
        if(bounce_0 == int(0))
        {
            _S271 = sunAlongCamera_0;
        }
        else
        {
            _S271 = false;
        }
        if(!_S271)
        {
            Vector<float, 3>  _S272 = s_9->sunDir_0;
            float _S273 = sceneTransmittance_0(s_9, bounds_9, drift_5, rng_10, p_22 + s_9->sunDir_0 * (Vector<float, 3> )s_9->shadowOffset_0, s_9->sunDir_0, &(&r_4)->trackingSteps_0);
            if(_S273 > 0.0f)
            {
                float _S274 = dot_0(_S267, _S272);
                PhaseInput_0 _S275 = matterPhase_0;
                float _S276 = phaseAt_0(&_S275, _S274);
                Vector<float, 3>  _S277 = throughput_1 * matterAlbedo_1 * (Vector<float, 3> )_S276 * (Vector<float, 3> )_S273;
                Vector<float, 3>  _S278 = sunIrradianceAt_0(s_9, p_22);
                (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + _S277 * _S278;
            }
        }
        PhaseInput_0 _S279 = matterPhase_0;
        float w_3;
        Vector<float, 3>  _S280 = samplePhaseDir_0(&_S279, rng_10, _S267, &w_3);
        Vector<float, 3>  throughput_2 = throughput_1 * (matterAlbedo_1 * (Vector<float, 3> )w_3);
        Vector<float, 3>  _S281 = p_22;
        if(bounce_0 >= (s_9->rrStartBounce_0))
        {
            float p2_0 = clamp_1((F32_max((throughput_2.x), ((F32_max((throughput_2.y), (throughput_2.z)))))), 0.05000000074505806f, 1.0f);
            float _S282 = randFloat_0(rng_10);
            if(_S282 > p2_0)
            {
                break;
            }
            throughput_1 = throughput_2 / (Vector<float, 3> )p2_0;
        }
        else
        {
            throughput_1 = throughput_2;
        }
        int32_t bounce_1 = bounce_0 + int(1);
        _S266 = _S281;
        _S267 = _S280;
        bounce_0 = bounce_1;
    }
    return r_4;
}

static Vector<float, 3>  renderSample_0(Scene_0 * s_10, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_10, StructuredBuffer<Vector<float, 2> > drift_6, Vector<float, 3>  ro_7, Vector<float, 3>  rd_7, uint32_t seed_2)
{
    Rng_0 rng_11 = makeRng_0(seed_2);
    TraceResult_0 _S283 = trace_0(s_10, ph_2, bounds_10, drift_6, &rng_11, ro_7, rd_7);
    return _S283.pathRadiance_0;
}

void _cpuRenderRays(void* _S284, void* entryPointParams_0, void* _S285)
{
    ComputeThreadVaryingInput * _S286 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S284));
    int32_t i_18 = int32_t((_S286->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S286->groupThreadID).x);
    if(i_18 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Vector<float, 3>  * _S287 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->outRadiance_0)[i_18]);
    Vector<float, 3>  _S288 = renderSample_0(&(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->scene_0, &(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->phase_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->bounds_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->drift_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->origins_0.Load(i_18), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->directions_0.Load(i_18), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_18));
    *_S287 = _S288;
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
