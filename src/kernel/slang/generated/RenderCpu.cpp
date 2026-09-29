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
    int32_t mode_0;
};

struct PhaseInput_0
{
    float hgG_0;
    float draineG_0;
    float draineAlpha_0;
    float draineW_0;
    int32_t useIce_0;
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

static float clamp_0(float x_0, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_0), (minBound_0)))), (maxBound_0)));
}

static float saturate_0(float x_1)
{
    return clamp_0(x_1, 0.0f, 1.0f);
}

static float dot_0(Vector<float, 2>  x_2, Vector<float, 2>  y_0)
{
    return x_2.x * y_0.x + x_2.y * y_0.y;
}

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

static float dot_1(Vector<float, 3>  x_3, Vector<float, 3>  y_1)
{
    return x_3.x * y_1.x + x_3.y * y_1.y + x_3.z * y_1.z;
}

static float length_0(Vector<float, 3>  x_4)
{
    return (F32_sqrt((dot_1(x_4, x_4))));
}

static Vector<float, 3>  normalize_0(Vector<float, 3>  x_5)
{
    return x_5 / (Vector<float, 3> )length_0(x_5);
}

static int32_t StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    Vector<uint32_t, 2>  _S7 = uint2(_elementCount_0, _stride_0);
    return int32_t(_S7.x);
}

static Vector<float, 3>  floor_0(Vector<float, 3>  x_6)
{
    Vector<float, 3>  result_0;
    int32_t i_0 = int(0);
    for(;;)
    {
        if(i_0 < int(3))
        {
        }
        else
        {
            break;
        }
        result_0[i_0] = (F32_floor((_slang_vector_get_element(x_6, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static float smoothstep_0(float min_0, float max_0, float x_7)
{
    float _S8 = saturate_0((x_7 - min_0) / (max_0 - min_0));
    return _S8 * _S8 * (3.0f - (_S8 + _S8));
}

static float length_1(Vector<float, 2>  x_8)
{
    return (F32_sqrt((dot_0(x_8, x_8))));
}

static Vector<float, 2>  floor_1(Vector<float, 2>  x_9)
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
        result_1[i_1] = (F32_floor((_slang_vector_get_element(x_9, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static Vector<float, 2>  lerp_0(Vector<float, 2>  x_10, Vector<float, 2>  y_2, Vector<float, 2>  s_0)
{
    return x_10 + (y_2 - x_10) * s_0;
}

static int32_t clamp_1(int32_t x_11, int32_t minBound_1, int32_t maxBound_1)
{
    return (I32_min(((I32_max((x_11), (minBound_1)))), (maxBound_1)));
}

static float lerp_1(float x_12, float y_3, float s_1)
{
    return x_12 + (y_3 - x_12) * s_1;
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

static float hg_0(float cosT_0, float g_0)
{
    float _S14 = g_0 * g_0;
    float d_0 = 1.0f + _S14 - 2.0f * g_0 * cosT_0;
    return (1.0f - _S14) / (12.56637096405029297f * d_0 * (F32_sqrt(((F32_max((d_0), (9.99999997475242708e-07f)))))));
}

static float phaseIce_0(float cosT_1)
{
    float t_0 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_1(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_0 * t_0))) * 0.34999999403953552f;
}

static float draine_0(float cosT_2, float g_1, float a_0)
{
    float _S15 = g_1 * g_1;
    float _S16 = 2.0f * g_1;
    float d_1 = 1.0f + _S15 - _S16 * cosT_2;
    return (1.0f - _S15) / (12.56637096405029297f * d_1 * (F32_sqrt(((F32_max((d_1), (9.99999997475242708e-07f))))))) * (1.0f + a_0 * cosT_2 * cosT_2) / (1.0f + a_0 * (1.0f + _S16 * g_1) / 3.0f);
}

static float phaseLiquid_0(PhaseInput_0 * p_0, float cosT_3)
{
    return (1.0f - p_0->draineW_0) * hg_0(cosT_3, p_0->hgG_0) + p_0->draineW_0 * draine_0(cosT_3, p_0->draineG_0, p_0->draineAlpha_0);
}

static float phaseAt_0(PhaseInput_0 * p_1, float cosT_4)
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

static float randFloat_0(Rng_0 * r_2)
{
    uint32_t _S19 = r_2->state_0 * 747796405U + 2891336453U;
    r_2->state_0 = _S19;
    uint32_t word_0 = ((_S19 >> ((_S19 >> 28U) + 4U)) ^ _S19) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_2, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_13 = clamp_0(depth_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_2 = clamp_1(int32_t((F32_floor((x_13)))), int(0), int(31));
    return lerp_0(disp_0.Load(i_2), disp_0.Load(i_2 + int(1)), (Vector<float, 2> )(x_13 - float(i_2)));
}

static Vector<uint32_t, 2>  pcg2d_0(Vector<uint32_t, 2>  v_0)
{
    Vector<uint32_t, 2>  _S20 = v_0 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S21 = _S20;
    _S21.x = _S21.x + _S20.y * 1664525U;
    _S21.y = _S21.y + _S21.x * 1664525U;
    Vector<uint32_t, 2>  _S22 = _S21 ^ (_S21 >> ((Vector<uint32_t, 2> )16U));
    _S21 = _S22;
    _S21.x = _S21.x + _S22.y * 1664525U;
    _S21.y = _S21.y + _S21.x * 1664525U;
    Vector<uint32_t, 2>  _S23 = _S21 ^ (_S21 >> ((Vector<uint32_t, 2> )16U));
    _S21 = _S23;
    return _S23;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_0, uint32_t salt_1)
{
    Vector<uint32_t, 2>  h_0 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_0.x), uint32_t(c_0.y)) ^ Vector<uint32_t, 2> (salt_1, salt_1 * 2654435761U));
    Vector<float, 2>  _S24 = Vector<float, 2> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1)};
    return _S24 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float cellField_0(GeneratorInput_0 * g_3, Vector<float, 2>  q_0)
{
    Vector<float, 2>  gq_0 = (q_0 - g_3->cellDrift_0) / (Vector<float, 2> )(g_3->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_1(gq_0);
    Vector<int32_t, 2>  _S25 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
    int32_t j_0 = int(-1);
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
        int32_t i_3 = int(-1);
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
            Vector<int32_t, 2>  o_0 = _S25 + Vector<int32_t, 2> (i_3, j_0);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_3 = i_3 + int(1);
                continue;
            }
            Vector<float, 2>  _S26 = Vector<float, 2> {(float)_slang_vector_get_element(o_0, 0), (float)_slang_vector_get_element(o_0, 1)};
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(gq_0 - (_S26 + (Vector<float, 2> )0.5f + (hash22_0(o_0, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f)) * 2.20000004768371582f);
            i_3 = i_3 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_1)
{
    Vector<uint32_t, 3>  _S27 = v_1 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S28 = _S27;
    _S28.x = _S28.x + _S27.y * _S27.z;
    _S28.y = _S28.y + _S28.z * _S28.x;
    _S28.z = _S28.z + _S28.x * _S28.y;
    Vector<uint32_t, 3>  _S29 = _S28 ^ (_S28 >> ((Vector<uint32_t, 3> )16U));
    _S28 = _S29;
    _S28.x = _S28.x + _S29.y * _S29.z;
    _S28.y = _S28.y + _S28.z * _S28.x;
    _S28.z = _S28.z + _S28.x * _S28.y;
    return _S28;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_1)
{
    Vector<uint32_t, 3>  h_1 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_1.x), uint32_t(c_1.y), uint32_t(c_1.z)));
    Vector<float, 3>  _S30 = Vector<float, 3> {(float)_slang_vector_get_element(h_1, 0), (float)_slang_vector_get_element(h_1, 1), (float)_slang_vector_get_element(h_1, 2)};
    return _S30 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float gradientNoise_0(Vector<float, 3>  p_2)
{
    Vector<float, 3>  fi_0 = floor_0(p_2);
    Vector<int32_t, 3>  _S31 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_2 - fi_0;
    Vector<float, 3>  u_0 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S32 = u_0.x;
    float _S33 = u_0.y;
    return lerp_1(lerp_1(lerp_1(dot_1(hash33_0(_S31), f_0), dot_1(hash33_0(_S31 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S32), lerp_1(dot_1(hash33_0(_S31 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S31 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S32), _S33), lerp_1(lerp_1(dot_1(hash33_0(_S31 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S31 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S32), lerp_1(dot_1(hash33_0(_S31 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S31 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S32), _S33), u_0.z);
}

static float fbm_0(Vector<float, 3>  p_3, int32_t octaves_1)
{
    int32_t i_4 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S34 = p_3;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S34);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S35 = _S34 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_4 = i_4 + int(1);
        amp_0 = amp_1;
        _S34 = _S35;
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

static float iceDensity_0(GeneratorInput_0 * g_4, StructuredBuffer<Vector<float, 2> > disp_1, Vector<float, 3>  p_4)
{
    float depth_1 = g_4->cellAltitude_0 - p_4.y;
    bool _S36;
    if(depth_1 < 0.0f)
    {
        _S36 = true;
    }
    else
    {
        _S36 = depth_1 > (g_4->streakLength_0);
    }
    if(_S36)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S37 = Vector<float, 2> {p_4.x, p_4.z};
    Vector<float, 2>  _S38 = driftAt_0(g_4, disp_1, depth_1);
    Vector<float, 2>  source_0 = _S37 - _S38;
    float _S39 = cellField_0(g_4, source_0);
    if(_S39 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S39 * (F32_exp((- g_4->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, depth_1)) * (F32_max((1.0f + g_4->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_4->detailScale_0).x, (source_0 / (Vector<float, 2> )g_4->detailScale_0).y, depth_1 / (F32_max((g_4->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_4->timeSeconds_0 * 0.00999999977648258f), g_4->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((g_4->streakLength_0), (1.0f)));
}

static float densityAt_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_2, Vector<float, 3>  p_5)
{
    float _S40 = p_5.y;
    bool _S41;
    if(_S40 < (m_1->slabBottom_0))
    {
        _S41 = true;
    }
    else
    {
        _S41 = _S40 > (m_1->slabTop_0);
    }
    if(_S41)
    {
        return 0.0f;
    }
    int32_t _S42 = m_1->mode_0;
    if((m_1->mode_0) == int(0))
    {
        return m_1->density_0;
    }
    if(_S42 == int(2))
    {
        float _S43 = iceDensity_0(&m_1->gen_0, disp_2, p_5);
        return _S43;
    }
    Vector<float, 3>  d_2 = (p_5 - m_1->coreCentre_0) / (Vector<float, 3> )(F32_max((m_1->coreRadius_0), (9.99999997475242708e-07f)));
    return m_1->density_0 + m_1->coreDensity_0 * (F32_exp((- dot_1(d_2, d_2))));
}

static Dda_0 ddaInit_0(MajorantGrid_0 * g_5, Vector<float, 3>  ro_1, Vector<float, 3>  rd_1, float t_1)
{
    Dda_0 d_3;
    if((g_5->enabled_0) == int(0))
    {
        Vector<int32_t, 3>  _S44 = Vector<int32_t, 3> (int(0), int(0), int(0));
        (&d_3)->cell_0 = _S44;
        (&d_3)->stepDir_0 = _S44;
        Vector<float, 3>  _S45 = Vector<float, 3> (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_3)->tMax_0 = _S45;
        (&d_3)->tDelta_0 = _S45;
        return d_3;
    }
    Vector<float, 3>  p_6 = ro_1 + rd_1 * (Vector<float, 3> )t_1;
    Vector<float, 3>  _S46 = floor_0((p_6 - g_5->origin_0) / g_5->cellExtent_0);
    Vector<int32_t, 3>  _S47 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(_S46, 0), (int32_t)_slang_vector_get_element(_S46, 1), (int32_t)_slang_vector_get_element(_S46, 2)};
    (&d_3)->cell_0 = _S47;
    int32_t a_1 = int(0);
    for(;;)
    {
        if(a_1 < int(3))
        {
        }
        else
        {
            break;
        }
        int32_t _S48 = a_1;
        if((F32_abs((_slang_vector_get_element(rd_1, a_1)))) < 9.999999960041972e-13f)
        {
            (&d_3)->stepDir_0[a_1] = int(0);
            (&d_3)->tMax_0[a_1] = 1.00000001504746622e+30f;
            (&d_3)->tDelta_0[a_1] = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S49 = _slang_vector_get_element(rd_1, _S48) > 0.0f;
            int32_t _S50;
            if(_S49)
            {
                _S50 = int(1);
            }
            else
            {
                _S50 = int(-1);
            }
            (&d_3)->stepDir_0[a_1] = _S50;
            float _S51 = g_5->origin_0[a_1];
            float _S52 = float((&d_3)->cell_0[a_1]);
            float _S53;
            if(_S49)
            {
                _S53 = 1.0f;
            }
            else
            {
                _S53 = 0.0f;
            }
            (&d_3)->tMax_0[a_1] = t_1 + (_S51 + (_S52 + _S53) * g_5->cellExtent_0[a_1] - _slang_vector_get_element(p_6, a_1)) / _slang_vector_get_element(rd_1, _S48);
            (&d_3)->tDelta_0[a_1] = (F32_abs((g_5->cellExtent_0[a_1] / _slang_vector_get_element(rd_1, _S48))));
        }
        a_1 = a_1 + int(1);
    }
    return d_3;
}

static float gridBound_0(MajorantGrid_0 * g_6, StructuredBuffer<float> bounds_1, Vector<int32_t, 3>  c_2, float fallback_0)
{
    if((g_6->enabled_0) == int(0))
    {
        return fallback_0;
    }
    int32_t _S54 = c_2.x;
    bool _S55;
    if(_S54 < int(0))
    {
        _S55 = true;
    }
    else
    {
        _S55 = (c_2.y) < int(0);
    }
    if(_S55)
    {
        _S55 = true;
    }
    else
    {
        _S55 = (c_2.z) < int(0);
    }
    if(_S55)
    {
        _S55 = true;
    }
    else
    {
        _S55 = _S54 >= (g_6->dims_0.x);
    }
    if(_S55)
    {
        _S55 = true;
    }
    else
    {
        _S55 = (c_2.y) >= (g_6->dims_0.y);
    }
    if(_S55)
    {
        _S55 = true;
    }
    else
    {
        _S55 = (c_2.z) >= (g_6->dims_0.z);
    }
    if(_S55)
    {
        return fallback_0;
    }
    return bounds_1.Load((c_2.z * g_6->dims_0.y + c_2.y) * g_6->dims_0.x + _S54);
}

static float ddaExit_0(Dda_0 * d_4)
{
    return (F32_min((d_4->tMax_0.x), ((F32_min((d_4->tMax_0.y), (d_4->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_5)
{
    bool _S56;
    if((d_5->tMax_0.x) <= (d_5->tMax_0.y))
    {
        _S56 = (d_5->tMax_0.x) <= (d_5->tMax_0.z);
    }
    else
    {
        _S56 = false;
    }
    if(_S56)
    {
        d_5->cell_0.x = d_5->cell_0.x + d_5->stepDir_0.x;
        d_5->tMax_0.x = d_5->tMax_0.x + d_5->tDelta_0.x;
    }
    else
    {
        if((d_5->tMax_0.y) <= (d_5->tMax_0.z))
        {
            d_5->cell_0.y = d_5->cell_0.y + d_5->stepDir_0.y;
            d_5->tMax_0.y = d_5->tMax_0.y + d_5->tDelta_0.y;
        }
        else
        {
            d_5->cell_0.z = d_5->cell_0.z + d_5->stepDir_0.z;
            d_5->tMax_0.z = d_5->tMax_0.z + d_5->tDelta_0.z;
        }
    }
    return;
}

static float transmittance_0(Medium_0 * m_2, MajorantGrid_0 * g_7, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > disp_3, Rng_0 * rng_0, Vector<float, 3>  p_7, Vector<float, 3>  dir_0, int32_t * steps_0)
{
    float t0_1;
    float t1_1;
    bool _S57 = slabRange_0(m_2, p_7, dir_0, &t0_1, &t1_1);
    if(!_S57)
    {
        return 1.0f;
    }
    float _S58 = (F32_max((t0_1), (0.0f)));
    t0_1 = _S58;
    Dda_0 _S59 = ddaInit_0(g_7, p_7, dir_0, _S58);
    Dda_0 dda_0 = _S59;
    int32_t i_5 = int(0);
    float t_2 = _S58;
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
        float _S60 = gridBound_0(g_7, bounds_2, (&dda_0)->cell_0, m_2->majorant_0);
        Dda_0 _S61 = dda_0;
        float _S62 = ddaExit_0(&_S61);
        float _S63 = (F32_min((_S62), (t1_1)));
        if(_S60 <= 0.0f)
        {
            if(_S63 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            t_2 = _S63;
            i_5 = i_5 + int(1);
            continue;
        }
        float _S64 = randFloat_0(rng_0);
        float t_3 = t_2 - (F32_log(((F32_max((1.0f - _S64), (1.00000001168609742e-07f)))))) / _S60;
        if(t_3 >= _S63)
        {
            if(_S63 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            t_2 = _S63;
            i_5 = i_5 + int(1);
            continue;
        }
        float _S65 = densityAt_0(m_2, disp_3, p_7 + dir_0 * (Vector<float, 3> )t_3);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S65 / _S60)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S66 = randFloat_0(rng_0);
            if(_S66 > 0.5f)
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

static float sunIrradianceTop_0(SkyInput_0 * p_8)
{
    return 20.0f * p_8->sunIntensity_0;
}

static float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static Vector<float, 3>  normalizeExact_0(Vector<float, 3>  v_2)
{
    float len2_0 = dot_1(v_2, v_2);
    if(len2_0 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    return v_2 * (Vector<float, 3> )(1.0f / (F32_sqrt((len2_0))));
}

static Vector<float, 3>  sunDirection_0(SkyInput_0 * p_9)
{
    float az_0 = toRadians_0(p_9->sunAzimuth_0);
    float el_0 = toRadians_0(p_9->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(Vector<float, 3> ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static float lutMuFor_0(Vector<float, 3>  geocentric_0, Vector<float, 3>  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S67;
    if(len_0 > 1.0f)
    {
        _S67 = dot_1(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S67 = dot_1(geocentric_0, sun_0);
    }
    return _S67;
}

static float clampf_0(float v_3, float lo_0, float hi_0)
{
    float _S68;
    if(v_3 < lo_0)
    {
        _S68 = lo_0;
    }
    else
    {
        if(v_3 > hi_0)
        {
            _S68 = hi_0;
        }
        else
        {
            _S68 = v_3;
        }
    }
    return _S68;
}

static Vector<float, 3>  sampleTransmittanceLut_0(SkyInput_0 * p_10, float altitude_0, float mu_0)
{
    StructuredBuffer<float> _S69 = p_10->transmittanceLut_0;
    if(uint32_t(StructuredBuffer_getCount_0(p_10->transmittanceLut_0)) < 49152U)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float _S70 = p_10->scaleHeight_0;
    float scaleHeight_1;
    if((p_10->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S70;
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
    float _S71 = fx_1 - float(x0_1);
    float _S72 = fy_1 - float(y0_1);
    int32_t _S73 = y0_1 * int(256);
    int32_t _S74 = (_S73 + x0_1) * int(3);
    int32_t _S75 = (_S73 + x1_1) * int(3);
    int32_t _S76 = y1_1 * int(256);
    int32_t _S77 = (_S76 + x0_1) * int(3);
    int32_t _S78 = (_S76 + x1_1) * int(3);
    Vector<float, 3>  out_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    int32_t c_3 = int(0);
    for(;;)
    {
        if(c_3 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S79 = 1.0f - _S71;
        float r_3 = (_S69.Load(_S74 + c_3) * _S79 + _S69.Load(_S75 + c_3) * _S71) * (1.0f - _S72) + (_S69.Load(_S77 + c_3) * _S79 + _S69.Load(_S78 + c_3) * _S71) * _S72;
        if(c_3 == int(0))
        {
            out_0.x = r_3;
        }
        else
        {
            if(c_3 == int(1))
            {
                out_0.y = r_3;
            }
            else
            {
                out_0.z = r_3;
            }
        }
        c_3 = c_3 + int(1);
    }
    return out_0;
}

static Vector<float, 3>  sunTransmittanceAt_0(SkyInput_0 * p_11, Vector<float, 3>  worldPos_0)
{
    Vector<float, 3>  _S80 = sunDirection_0(p_11);
    float _S81 = p_11->planetRadius_0;
    float planetRadius_1;
    if((p_11->planetRadius_0) > 1000.0f)
    {
        planetRadius_1 = _S81;
    }
    else
    {
        planetRadius_1 = 1000.0f;
    }
    float _S82 = worldPos_0.y;
    float altitude_1;
    if(_S82 > 0.0f)
    {
        altitude_1 = _S82;
    }
    else
    {
        altitude_1 = 0.0f;
    }
    Vector<float, 3>  _S83 = sampleTransmittanceLut_0(p_11, altitude_1, lutMuFor_0(Vector<float, 3> (worldPos_0.x, planetRadius_1 + _S82, worldPos_0.z), _S80));
    return _S83;
}

static Vector<float, 3>  sunIrradianceAt_0(Scene_0 * s_4, Vector<float, 3>  p_12)
{
    if(((&s_4->environment_0)->envMode_0) == int(1))
    {
        float _S84 = sunIrradianceTop_0(&(&s_4->environment_0)->sky_0);
        Vector<float, 3>  _S85 = sunTransmittanceAt_0(&(&s_4->environment_0)->sky_0, p_12);
        return (Vector<float, 3> )_S84 * _S85;
    }
    return s_4->sunIrradiance_0;
}

static Vector<float, 3>  cameraSegmentSun_0(Scene_0 * s_5, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_3, StructuredBuffer<Vector<float, 2> > drift_1, Rng_0 * rng_1, Vector<float, 3>  ro_2, Vector<float, 3>  rd_2, int32_t * steps_1)
{
    float kept_0;
    Vector<float, 3>  keptAt_0;
    Vector<float, 3>  none_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float t0_2;
    float t1_2;
    bool _S86 = slabRange_0(&s_5->medium_0, ro_2, rd_2, &t0_2, &t1_2);
    if(!_S86)
    {
        return none_0;
    }
    t0_2 = (F32_max((t0_2), (0.0f)));
    float rate_0 = (&s_5->medium_0)->majorant_0 * (F32_max((s_5->neeTentativeScale_0), (1.0f)));
    if(!(rate_0 > 0.0f))
    {
        return none_0;
    }
    Vector<float, 3>  _S87 = s_5->sunDir_0;
    float _S88 = phaseAt_0(ph_0, dot_1(rd_2, s_5->sunDir_0));
    float kept_1 = 0.0f;
    Vector<float, 3>  keptAt_1 = none_0;
    int32_t i_6 = int(0);
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
        Vector<float, 3>  p_13 = ro_2 + rd_2 * (Vector<float, 3> )t_5;
        float _S89 = densityAt_0(&s_5->medium_0, drift_1, p_13);
        if(_S89 <= 0.0f)
        {
            kept_0 = kept_1;
            keptAt_0 = keptAt_1;
            int32_t i_7 = i_6 + int(1);
            kept_1 = kept_0;
            keptAt_1 = keptAt_0;
            i_6 = i_7;
            t_4 = t_5;
            continue;
        }
        float w_0 = _S89 / rate_0;
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
        int32_t i_7 = i_6 + int(1);
        kept_1 = kept_0;
        keptAt_1 = keptAt_0;
        i_6 = i_7;
        t_4 = t_5;
    }
    bool _S90;
    if(!(total_0 > 0.0f))
    {
        _S90 = true;
    }
    else
    {
        _S90 = !(kept_0 > 0.0f);
    }
    if(_S90)
    {
        return none_0;
    }
    float _S91 = transmittance_0(&s_5->medium_0, &s_5->grid_0, bounds_3, drift_1, rng_1, keptAt_0 + _S87 * (Vector<float, 3> )s_5->shadowOffset_0, _S87, steps_1);
    Vector<float, 3>  _S92 = (Vector<float, 3> )total_0 * s_5->albedo_0 * (Vector<float, 3> )_S88 * (Vector<float, 3> )_S91;
    Vector<float, 3>  _S93 = sunIrradianceAt_0(s_5, keptAt_0);
    return _S92 * _S93;
}

static bool sampleFreeFlight_0(Medium_0 * m_3, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_4, StructuredBuffer<Vector<float, 2> > disp_4, Rng_0 * rng_2, Vector<float, 3>  ro_3, Vector<float, 3>  rd_3, Vector<float, 3>  * scatterPoint_0, float * distance_0, int32_t * steps_2)
{
    *scatterPoint_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S94 = slabRange_0(m_3, ro_3, rd_3, &t0_3, &t1_3);
    if(!_S94)
    {
        return false;
    }
    float _S95 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S96 = ddaInit_0(g_8, ro_3, rd_3, _S95);
    Dda_0 dda_1 = _S96;
    int32_t i_8 = int(0);
    float t_6 = _S95;
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
        float _S97 = gridBound_0(g_8, bounds_4, (&dda_1)->cell_0, m_3->majorant_0);
        Dda_0 _S98 = dda_1;
        float _S99 = ddaExit_0(&_S98);
        float _S100 = (F32_min((_S99), (t1_3)));
        if(_S97 <= 0.0f)
        {
            if(_S100 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            t_6 = _S100;
            i_8 = i_8 + int(1);
            continue;
        }
        float _S101 = randFloat_0(rng_2);
        float t_7 = t_6 - (F32_log(((F32_max((1.0f - _S101), (1.00000001168609742e-07f)))))) / _S97;
        if(t_7 >= _S100)
        {
            if(_S100 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_1);
            t_6 = _S100;
            i_8 = i_8 + int(1);
            continue;
        }
        Vector<float, 3>  p_14 = ro_3 + rd_3 * (Vector<float, 3> )t_7;
        float _S102 = randFloat_0(rng_2);
        float _S103 = densityAt_0(m_3, disp_4, p_14);
        if(_S102 < (_S103 / _S97))
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

static float shellC_0(float altitude_2, float planetRadius_2, float shellHeight_0)
{
    float d_6 = altitude_2 - shellHeight_0;
    return d_6 * (d_6 + 2.0f * planetRadius_2 + 2.0f * shellHeight_0);
}

static float shellExit_0(float b_1, float c_4)
{
    float disc_0 = b_1 * b_1 - c_4;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_1 + (F32_sqrt((disc_0)));
}

static float shellEnter_0(float b_2, float c_5)
{
    float disc_1 = b_2 * b_2 - c_5;
    if(disc_1 < 0.0f)
    {
        return -1.0f;
    }
    return - b_2 - (F32_sqrt((disc_1)));
}

static Vector<float, 3>  rayleighCoefficients_0()
{
    return Vector<float, 3> (5.80200003241770901e-06f, 0.00001355800031888f, 0.00003310000101919f);
}

static float mieCoefficient_0(float turbidity_1)
{
    return 3.99600003220257349e-06f * (turbidity_1 / 2.20000004768371582f);
}

static float altitudeFromQ_0(float q_1, float planetRadius_3)
{
    float rr_0 = planetRadius_3 * planetRadius_3 + q_1;
    float _S104;
    if(rr_0 > 0.0f)
    {
        _S104 = rr_0;
    }
    else
    {
        _S104 = 0.0f;
    }
    return q_1 / (planetRadius_3 + (F32_sqrt((_S104))));
}

static Vector<float, 3>  skyRadiance_0(SkyInput_0 * p_15, float originAltitude_0, Vector<float, 3>  rayDir_0, bool includeSunDisc_0)
{
    float hc_0;
    Vector<float, 3>  _S105 = sunDirection_0(p_15);
    float _S106 = p_15->planetRadius_0;
    float planetRadius_4;
    if((p_15->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S106;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S107 = p_15->scaleHeight_0;
    float scaleHeight_2;
    if((p_15->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S107;
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
    float _S108 = planetRadius_4 + observerAltitude_0;
    float _S109 = rayDir_0.y;
    float b_3 = _S108 * _S109;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_4, 0.0f);
    float tTop_0 = shellExit_0(b_3, shellC_0(observerAltitude_0, planetRadius_4, atmosphereHeight_0));
    if(tTop_0 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 0.0f, 0.0f);
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
    Vector<float, 3>  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_15->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_1(rayDir_0, _S105), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_9 = clampf_0(p_15->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S110 = g_9 * g_9;
    float hgDenom_0 = 1.0f + _S110 - 2.0f * g_9 * cosTheta_0;
    float _S111 = 1.0f - _S110;
    float _S112 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S111 / (_S112 * (F32_sqrt((tPrev_0))));
    Vector<float, 3>  _S113 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    Vector<float, 3>  sumR_0 = _S113;
    Vector<float, 3>  sumM_0 = _S113;
    int32_t i_9 = int(0);
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
        int32_t _S114 = i_9 + int(1);
        float tNext_0 = observerAltitude_0 * float(_S114 * _S114) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_9 = _S114;
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
        float _S115 = - hc_0;
        float dR_0 = (F32_exp((_S115 / scaleHeight_2))) * dt_0;
        float dM_0 = (F32_exp((_S115 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        Vector<float, 3>  _S116 = sampleTransmittanceLut_0(p_15, hc_0, lutMuFor_0(Vector<float, 3> (rayDir_0.x * tMid_0, _S108 + _S109 * tMid_0, rayDir_0.z * tMid_0), _S105));
        float _S117 = betaMExt_0 * depthM_1;
        Vector<float, 3>  transmittance_1 = Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_1 + _S117)))), (F32_exp((- (betaR_0.y * depthR_1 + _S117)))), (F32_exp((- (betaR_0.z * depthR_1 + _S117))))) * _S116;
        Vector<float, 3>  _S118 = sumM_0 + transmittance_1 * (Vector<float, 3> )dM_0;
        sumR_0 = sumR_0 + transmittance_1 * (Vector<float, 3> )dR_0;
        sumM_0 = _S118;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_9 = _S114;
    }
    float _S119 = sunIrradianceTop_0(p_15);
    Vector<float, 3>  radiance_0 = (sumR_0 * betaR_0 * (Vector<float, 3> )phaseR_0 + sumM_0 * (Vector<float, 3> )(betaM_0 * phaseM_0)) * (Vector<float, 3> )_S119;
    Vector<float, 3>  radiance_1;
    if(hitsGround_0)
    {
        Vector<float, 3>  groundPoint_0 = Vector<float, 3> (rayDir_0.x * tGround_0, _S108 + _S109 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_1(normalizeExact_0(groundPoint_0), _S105), 0.0f, 1.0f);
        Vector<float, 3>  _S120 = sampleTransmittanceLut_0(p_15, 0.0f, lutMuFor_0(groundPoint_0, _S105));
        float _S121 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S121)))), (F32_exp((- (betaR_0.y * depthR_0 + _S121)))), (F32_exp((- (betaR_0.z * depthR_0 + _S121))))) * _S120 * (Vector<float, 3> )(p_15->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S119);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S122;
    if(!hitsGround_0)
    {
        _S122 = includeSunDisc_0;
    }
    else
    {
        _S122 = false;
    }
    if(_S122)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_15->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S123 = betaMExt_0 * depthM_0;
            Vector<float, 3>  viewT_0 = Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S123)))), (F32_exp((- (betaR_0.y * depthR_0 + _S123)))), (F32_exp((- (betaR_0.z * depthR_0 + _S123)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_0 = solidAngle_0;
            }
            else
            {
                hc_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * (Vector<float, 3> )(_S119 / hc_0);
        }
    }
    return radiance_1;
}

static Vector<float, 3>  environmentRadiance_0(Environment_0 * e_0, Vector<float, 3>  origin_1, Vector<float, 3>  dir_1, bool includeSunDisc_1)
{
    if((e_0->envMode_0) == int(1))
    {
        Vector<float, 3>  _S124 = skyRadiance_0(&e_0->sky_0, origin_1.y, dir_1, includeSunDisc_1);
        return _S124;
    }
    return e_0->uniformRadiance_0;
}

static Vector<float, 3>  sampleHG_0(Rng_0 * rng_3, Vector<float, 3>  wo_0, float g_10, float * cosT_5)
{
    float _S125 = clamp_0(g_10, -0.99900001287460327f, 0.99900001287460327f);
    float u1_0 = randFloat_0(rng_3);
    float u2_0 = randFloat_0(rng_3);
    if((F32_abs((_S125))) < 0.00100000004749745f)
    {
        *cosT_5 = 1.0f - 2.0f * u1_0;
    }
    else
    {
        float _S126 = _S125 * _S125;
        float _S127 = 2.0f * _S125;
        float s_6 = (1.0f - _S126) / (1.0f - _S125 + _S127 * u1_0);
        *cosT_5 = (1.0f + _S126 - s_6 * s_6) / _S127;
    }
    float _S128 = clamp_0(*cosT_5, -1.0f, 1.0f);
    *cosT_5 = _S128;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S128 * _S128))))));
    float phi_0 = 6.28318548202514648f * u2_0;
    Vector<float, 3>  w_1 = normalize_0(wo_0);
    Vector<float, 3>  a_2;
    if((F32_abs((w_1.y))) < 0.94999998807907104f)
    {
        a_2 = Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_2 = Vector<float, 3> (1.0f, 0.0f, 0.0f);
    }
    Vector<float, 3>  u_1 = normalize_0(cross_0(a_2, w_1));
    return normalize_0((Vector<float, 3> )(sinT_0 * (F32_cos((phi_0)))) * u_1 + (Vector<float, 3> )(sinT_0 * (F32_sin((phi_0)))) * cross_0(w_1, u_1) + (Vector<float, 3> )*cosT_5 * w_1);
}

static Vector<float, 3>  samplePhaseDir_0(PhaseInput_0 * p_16, Rng_0 * rng_4, Vector<float, 3>  wo_1, float * weight_0)
{
    float cosT_6;
    Vector<float, 3>  dir_2;
    float _S129;
    if((p_16->useIce_0) != int(0))
    {
        float _S130 = randFloat_0(rng_4);
        if(_S130 < 0.72000002861022949f)
        {
            Vector<float, 3>  _S131 = sampleHG_0(rng_4, wo_1, 0.85000002384185791f, &cosT_6);
            dir_2 = _S131;
        }
        else
        {
            Vector<float, 3>  _S132 = sampleHG_0(rng_4, wo_1, 0.0f, &cosT_6);
            dir_2 = _S132;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_6, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S129 = phaseIce_0(cosT_6) / pdf_0;
        }
        else
        {
            _S129 = 0.0f;
        }
        *weight_0 = _S129;
    }
    else
    {
        float _S133 = randFloat_0(rng_4);
        float _S134 = p_16->draineW_0;
        if(_S133 < (p_16->draineW_0))
        {
            Vector<float, 3>  _S135 = sampleHG_0(rng_4, wo_1, p_16->draineG_0, &cosT_6);
            dir_2 = _S135;
        }
        else
        {
            Vector<float, 3>  _S136 = sampleHG_0(rng_4, wo_1, p_16->hgG_0, &cosT_6);
            dir_2 = _S136;
        }
        float pdf_1 = _S134 * hg_0(cosT_6, p_16->draineG_0) + (1.0f - _S134) * hg_0(cosT_6, p_16->hgG_0);
        if(pdf_1 > 9.99999971718068537e-10f)
        {
            float _S137 = phaseLiquid_0(p_16, cosT_6);
            _S129 = _S137 / pdf_1;
        }
        else
        {
            _S129 = 0.0f;
        }
        *weight_0 = _S129;
    }
    return dir_2;
}

static TraceResult_0 trace_0(Scene_0 * s_7, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_5, StructuredBuffer<Vector<float, 2> > drift_2, Rng_0 * rng_5, Vector<float, 3>  ro_4, Vector<float, 3>  rd_4)
{
    TraceResult_0 r_4;
    (&r_4)->pathRadiance_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&r_4)->scatterEvents_0 = int(0);
    (&r_4)->capped_0 = int(0);
    (&r_4)->trackingSteps_0 = int(0);
    Vector<float, 3>  throughput_0 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    int32_t _S138 = (I32_min((s_7->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_7->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S138 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    if(sunAlongCamera_0)
    {
        Rng_0 _S139 = *rng_5;
        Rng_0 _S140 = splitRng_0(&_S139, 1510U);
        Rng_0 segmentRng_0 = _S140;
        Vector<float, 3>  _S141 = cameraSegmentSun_0(s_7, ph_1, bounds_5, drift_2, &segmentRng_0, ro_4, rd_4, &(&r_4)->trackingSteps_0);
        (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + _S141;
    }
    Vector<float, 3>  _S142 = ro_4;
    Vector<float, 3>  _S143 = rd_4;
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
        if(bounce_0 >= _S138)
        {
            (&r_4)->capped_0 = int(1);
            break;
        }
        Vector<float, 3>  p_17;
        float dist_0;
        bool _S144 = sampleFreeFlight_0(&s_7->medium_0, &s_7->grid_0, bounds_5, drift_2, rng_5, _S142, _S143, &p_17, &dist_0, &(&r_4)->trackingSteps_0);
        if(!_S144)
        {
            Vector<float, 3>  _S145 = environmentRadiance_0(&s_7->environment_0, _S142, _S143, bounce_0 == int(0));
            (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + throughput_1 * _S145;
            break;
        }
        (&r_4)->scatterEvents_0 = (&r_4)->scatterEvents_0 + int(1);
        bool _S146;
        if(bounce_0 == int(0))
        {
            _S146 = sunAlongCamera_0;
        }
        else
        {
            _S146 = false;
        }
        if(!_S146)
        {
            Vector<float, 3>  _S147 = s_7->sunDir_0;
            float _S148 = transmittance_0(&s_7->medium_0, &s_7->grid_0, bounds_5, drift_2, rng_5, p_17 + s_7->sunDir_0 * (Vector<float, 3> )s_7->shadowOffset_0, s_7->sunDir_0, &(&r_4)->trackingSteps_0);
            if(_S148 > 0.0f)
            {
                float _S149 = phaseAt_0(ph_1, dot_1(_S143, _S147));
                Vector<float, 3>  _S150 = throughput_1 * s_7->albedo_0 * (Vector<float, 3> )_S149 * (Vector<float, 3> )_S148;
                Vector<float, 3>  _S151 = sunIrradianceAt_0(s_7, p_17);
                (&r_4)->pathRadiance_0 = (&r_4)->pathRadiance_0 + _S150 * _S151;
            }
        }
        float w_2;
        Vector<float, 3>  _S152 = samplePhaseDir_0(ph_1, rng_5, _S143, &w_2);
        Vector<float, 3>  throughput_2 = throughput_1 * (s_7->albedo_0 * (Vector<float, 3> )w_2);
        Vector<float, 3>  _S153 = p_17;
        if(bounce_0 >= (s_7->rrStartBounce_0))
        {
            float p2_0 = clamp_0((F32_max((throughput_2.x), ((F32_max((throughput_2.y), (throughput_2.z)))))), 0.05000000074505806f, 1.0f);
            float _S154 = randFloat_0(rng_5);
            if(_S154 > p2_0)
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
        _S142 = _S153;
        _S143 = _S152;
        bounce_0 = bounce_1;
    }
    return r_4;
}

static Vector<float, 3>  renderSample_0(Scene_0 * s_8, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_6, StructuredBuffer<Vector<float, 2> > drift_3, Vector<float, 3>  ro_5, Vector<float, 3>  rd_5, uint32_t seed_2)
{
    Rng_0 rng_6 = makeRng_0(seed_2);
    TraceResult_0 _S155 = trace_0(s_8, ph_2, bounds_6, drift_3, &rng_6, ro_5, rd_5);
    return _S155.pathRadiance_0;
}

void _cpuRenderRays(void* _S156, void* entryPointParams_0, void* _S157)
{
    ComputeThreadVaryingInput * _S158 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S156));
    int32_t i_10 = int32_t((_S158->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S158->groupThreadID).x);
    if(i_10 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Vector<float, 3>  * _S159 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->outRadiance_0)[i_10]);
    Vector<float, 3>  _S160 = renderSample_0(&(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->scene_0, &(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->phase_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->bounds_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->drift_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->origins_0.Load(i_10), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->directions_0.Load(i_10), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_10));
    *_S159 = _S160;
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
