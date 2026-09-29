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
    StructuredBuffer<float> transmittance_0;
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
};

struct TraceResult_0
{
    Vector<float, 3>  pathRadiance_0;
    int32_t scatterEvents_0;
    int32_t capped_0;
    int32_t trackingSteps_0;
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

static float lerp_0(float x_6, float y_2, float s_0)
{
    return x_6 + (y_2 - x_6) * s_0;
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

static Vector<float, 2>  floor_0(Vector<float, 2>  x_9)
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
        result_0[i_0] = (F32_floor((_slang_vector_get_element(x_9, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static Vector<float, 2>  lerp_1(Vector<float, 2>  x_10, Vector<float, 2>  y_3, Vector<float, 2>  s_1)
{
    return x_10 + (y_3 - x_10) * s_1;
}

static int32_t clamp_1(int32_t x_11, int32_t minBound_1, int32_t maxBound_1)
{
    return (I32_min(((I32_max((x_11), (minBound_1)))), (maxBound_1)));
}

static Vector<float, 3>  floor_1(Vector<float, 3>  x_12)
{
    Vector<float, 3>  result_1;
    int32_t i_1 = int(0);
    for(;;)
    {
        if(i_1 < int(3))
        {
        }
        else
        {
            break;
        }
        result_1[i_1] = (F32_floor((_slang_vector_get_element(x_12, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static Rng_0 makeRng_0(uint32_t seed_1)
{
    Rng_0 r_0;
    (&r_0)->state_0 = seed_1;
    return r_0;
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

static float gridBound_0(MajorantGrid_0 * g_1, StructuredBuffer<float> bounds_1, Vector<int32_t, 3>  c_0, float fallback_0)
{
    if((g_1->enabled_0) == int(0))
    {
        return fallback_0;
    }
    int32_t _S24 = c_0.x;
    bool _S25;
    if(_S24 < int(0))
    {
        _S25 = true;
    }
    else
    {
        _S25 = (c_0.y) < int(0);
    }
    if(_S25)
    {
        _S25 = true;
    }
    else
    {
        _S25 = (c_0.z) < int(0);
    }
    if(_S25)
    {
        _S25 = true;
    }
    else
    {
        _S25 = _S24 >= (g_1->dims_0.x);
    }
    if(_S25)
    {
        _S25 = true;
    }
    else
    {
        _S25 = (c_0.y) >= (g_1->dims_0.y);
    }
    if(_S25)
    {
        _S25 = true;
    }
    else
    {
        _S25 = (c_0.z) >= (g_1->dims_0.z);
    }
    if(_S25)
    {
        return fallback_0;
    }
    return bounds_1.Load((c_0.z * g_1->dims_0.y + c_0.y) * g_1->dims_0.x + _S24);
}

static float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_2)
{
    bool _S26;
    if((d_2->tMax_0.x) <= (d_2->tMax_0.y))
    {
        _S26 = (d_2->tMax_0.x) <= (d_2->tMax_0.z);
    }
    else
    {
        _S26 = false;
    }
    if(_S26)
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

static float randFloat_0(Rng_0 * r_1)
{
    uint32_t _S27 = r_1->state_0 * 747796405U + 2891336453U;
    r_1->state_0 = _S27;
    uint32_t word_0 = ((_S27 >> ((_S27 >> 28U) + 4U)) ^ _S27) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_2, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_13 = clamp_0(depth_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_2 = clamp_1(int32_t((F32_floor((x_13)))), int(0), int(31));
    return lerp_1(disp_0.Load(i_2), disp_0.Load(i_2 + int(1)), (Vector<float, 2> )(x_13 - float(i_2)));
}

static Vector<uint32_t, 2>  pcg2d_0(Vector<uint32_t, 2>  v_0)
{
    Vector<uint32_t, 2>  _S28 = v_0 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S29 = _S28;
    _S29.x = _S29.x + _S28.y * 1664525U;
    _S29.y = _S29.y + _S29.x * 1664525U;
    Vector<uint32_t, 2>  _S30 = _S29 ^ (_S29 >> ((Vector<uint32_t, 2> )16U));
    _S29 = _S30;
    _S29.x = _S29.x + _S30.y * 1664525U;
    _S29.y = _S29.y + _S29.x * 1664525U;
    Vector<uint32_t, 2>  _S31 = _S29 ^ (_S29 >> ((Vector<uint32_t, 2> )16U));
    _S29 = _S31;
    return _S31;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_1, uint32_t salt_0)
{
    Vector<uint32_t, 2>  h_0 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_1.x), uint32_t(c_1.y)) ^ Vector<uint32_t, 2> (salt_0, salt_0 * 2654435761U));
    Vector<float, 2>  _S32 = Vector<float, 2> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1)};
    return _S32 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float cellField_0(GeneratorInput_0 * g_3, Vector<float, 2>  q_0)
{
    Vector<float, 2>  gq_0 = (q_0 - g_3->cellDrift_0) / (Vector<float, 2> )(g_3->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_0(gq_0);
    Vector<int32_t, 2>  _S33 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
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
            Vector<int32_t, 2>  o_0 = _S33 + Vector<int32_t, 2> (i_3, j_0);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_3 = i_3 + int(1);
                continue;
            }
            Vector<float, 2>  _S34 = Vector<float, 2> {(float)_slang_vector_get_element(o_0, 0), (float)_slang_vector_get_element(o_0, 1)};
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(gq_0 - (_S34 + (Vector<float, 2> )0.5f + (hash22_0(o_0, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f)) * 2.20000004768371582f);
            i_3 = i_3 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_1)
{
    Vector<uint32_t, 3>  _S35 = v_1 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S36 = _S35;
    _S36.x = _S36.x + _S35.y * _S35.z;
    _S36.y = _S36.y + _S36.z * _S36.x;
    _S36.z = _S36.z + _S36.x * _S36.y;
    Vector<uint32_t, 3>  _S37 = _S36 ^ (_S36 >> ((Vector<uint32_t, 3> )16U));
    _S36 = _S37;
    _S36.x = _S36.x + _S37.y * _S37.z;
    _S36.y = _S36.y + _S36.z * _S36.x;
    _S36.z = _S36.z + _S36.x * _S36.y;
    return _S36;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_2)
{
    Vector<uint32_t, 3>  h_1 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_2.x), uint32_t(c_2.y), uint32_t(c_2.z)));
    Vector<float, 3>  _S38 = Vector<float, 3> {(float)_slang_vector_get_element(h_1, 0), (float)_slang_vector_get_element(h_1, 1), (float)_slang_vector_get_element(h_1, 2)};
    return _S38 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float gradientNoise_0(Vector<float, 3>  p_1)
{
    Vector<float, 3>  fi_0 = floor_1(p_1);
    Vector<int32_t, 3>  _S39 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_1 - fi_0;
    Vector<float, 3>  u_0 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S40 = u_0.x;
    float _S41 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_1(hash33_0(_S39), f_0), dot_1(hash33_0(_S39 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S40), lerp_0(dot_1(hash33_0(_S39 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S39 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S40), _S41), lerp_0(lerp_0(dot_1(hash33_0(_S39 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S39 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S40), lerp_0(dot_1(hash33_0(_S39 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S39 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S40), _S41), u_0.z);
}

static float fbm_0(Vector<float, 3>  p_2, int32_t octaves_1)
{
    int32_t i_4 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S42 = p_2;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S42);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S43 = _S42 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_4 = i_4 + int(1);
        amp_0 = amp_1;
        _S42 = _S43;
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

static float iceDensity_0(GeneratorInput_0 * g_4, StructuredBuffer<Vector<float, 2> > disp_1, Vector<float, 3>  p_3)
{
    float depth_1 = g_4->cellAltitude_0 - p_3.y;
    bool _S44;
    if(depth_1 < 0.0f)
    {
        _S44 = true;
    }
    else
    {
        _S44 = depth_1 > (g_4->streakLength_0);
    }
    if(_S44)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S45 = Vector<float, 2> {p_3.x, p_3.z};
    Vector<float, 2>  _S46 = driftAt_0(g_4, disp_1, depth_1);
    Vector<float, 2>  source_0 = _S45 - _S46;
    float _S47 = cellField_0(g_4, source_0);
    if(_S47 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S47 * (F32_exp((- g_4->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, depth_1)) * (F32_max((1.0f + g_4->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_4->detailScale_0).x, (source_0 / (Vector<float, 2> )g_4->detailScale_0).y, depth_1 / (F32_max((g_4->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_4->timeSeconds_0 * 0.00999999977648258f), g_4->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((g_4->streakLength_0), (1.0f)));
}

static float densityAt_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_2, Vector<float, 3>  p_4)
{
    float _S48 = p_4.y;
    bool _S49;
    if(_S48 < (m_1->slabBottom_0))
    {
        _S49 = true;
    }
    else
    {
        _S49 = _S48 > (m_1->slabTop_0);
    }
    if(_S49)
    {
        return 0.0f;
    }
    int32_t _S50 = m_1->mode_0;
    if((m_1->mode_0) == int(0))
    {
        return m_1->density_0;
    }
    if(_S50 == int(2))
    {
        float _S51 = iceDensity_0(&m_1->gen_0, disp_2, p_4);
        return _S51;
    }
    Vector<float, 3>  d_3 = (p_4 - m_1->coreCentre_0) / (Vector<float, 3> )(F32_max((m_1->coreRadius_0), (9.99999997475242708e-07f)));
    return m_1->density_0 + m_1->coreDensity_0 * (F32_exp((- dot_1(d_3, d_3))));
}

static bool sampleFreeFlight_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > disp_3, Rng_0 * rng_0, Vector<float, 3>  ro_2, Vector<float, 3>  rd_2, Vector<float, 3>  * scatterPoint_0, float * distance_0, int32_t * steps_0)
{
    *scatterPoint_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_1;
    float t1_1;
    bool _S52 = slabRange_0(m_2, ro_2, rd_2, &t0_1, &t1_1);
    if(!_S52)
    {
        return false;
    }
    float _S53 = (F32_max((t0_1), (0.0f)));
    Dda_0 _S54 = ddaInit_0(g_5, ro_2, rd_2, _S53);
    Dda_0 dda_0 = _S54;
    int32_t i_5 = int(0);
    float t_1 = _S53;
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
        float _S55 = gridBound_0(g_5, bounds_2, (&dda_0)->cell_0, m_2->majorant_0);
        Dda_0 _S56 = dda_0;
        float _S57 = ddaExit_0(&_S56);
        float _S58 = (F32_min((_S57), (t1_1)));
        if(_S55 <= 0.0f)
        {
            if(_S58 >= t1_1)
            {
                return false;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S58;
            i_5 = i_5 + int(1);
            continue;
        }
        float _S59 = randFloat_0(rng_0);
        float t_2 = t_1 - (F32_log(((F32_max((1.0f - _S59), (1.00000001168609742e-07f)))))) / _S55;
        if(t_2 >= _S58)
        {
            if(_S58 >= t1_1)
            {
                return false;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S58;
            i_5 = i_5 + int(1);
            continue;
        }
        Vector<float, 3>  p_5 = ro_2 + rd_2 * (Vector<float, 3> )t_2;
        float _S60 = randFloat_0(rng_0);
        float _S61 = densityAt_0(m_2, disp_3, p_5);
        if(_S60 < (_S61 / _S55))
        {
            *scatterPoint_0 = p_5;
            *distance_0 = t_2;
            return true;
        }
        t_1 = t_2;
        i_5 = i_5 + int(1);
    }
    return false;
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

static Vector<float, 3>  sunDirection_0(SkyInput_0 * p_6)
{
    float az_0 = toRadians_0(p_6->sunAzimuth_0);
    float el_0 = toRadians_0(p_6->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(Vector<float, 3> ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_4 = altitude_0 - shellHeight_0;
    return d_4 * (d_4 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static float shellExit_0(float b_0, float c_3)
{
    float disc_0 = b_0 * b_0 - c_3;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_0 + (F32_sqrt((disc_0)));
}

static float shellEnter_0(float b_1, float c_4)
{
    float disc_1 = b_1 * b_1 - c_4;
    if(disc_1 < 0.0f)
    {
        return -1.0f;
    }
    return - b_1 - (F32_sqrt((disc_1)));
}

static Vector<float, 3>  rayleighCoefficients_0()
{
    return Vector<float, 3> (5.80200003241770901e-06f, 0.00001355800031888f, 0.00003310000101919f);
}

static float mieCoefficient_0(float turbidity_1)
{
    return 3.99600003220257349e-06f * (turbidity_1 / 2.20000004768371582f);
}

static float clampf_0(float v_3, float lo_0, float hi_0)
{
    float _S62;
    if(v_3 < lo_0)
    {
        _S62 = lo_0;
    }
    else
    {
        if(v_3 > hi_0)
        {
            _S62 = hi_0;
        }
        else
        {
            _S62 = v_3;
        }
    }
    return _S62;
}

static float altitudeFromQ_0(float q_1, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_1;
    float _S63;
    if(rr_0 > 0.0f)
    {
        _S63 = rr_0;
    }
    else
    {
        _S63 = 0.0f;
    }
    return q_1 / (planetRadius_2 + (F32_sqrt((_S63))));
}

static float lutMuFor_0(Vector<float, 3>  geocentric_0, Vector<float, 3>  sun_0)
{
    float len_0 = length_0(geocentric_0);
    float _S64;
    if(len_0 > 1.0f)
    {
        _S64 = dot_1(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S64 = dot_1(geocentric_0, sun_0);
    }
    return _S64;
}

static Vector<float, 3>  sampleTransmittanceLut_0(SkyInput_0 * p_7, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S65 = p_7->transmittance_0;
    if(uint32_t(StructuredBuffer_getCount_0(p_7->transmittance_0)) < 49152U)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float _S66 = p_7->scaleHeight_0;
    float scaleHeight_1;
    if((p_7->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S66;
    }
    else
    {
        scaleHeight_1 = 1.0f;
    }
    float topAltitude_0 = scaleHeight_1 * 8.0f;
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
    float _S67 = fx_1 - float(x0_1);
    float _S68 = fy_1 - float(y0_1);
    int32_t _S69 = y0_1 * int(256);
    int32_t _S70 = (_S69 + x0_1) * int(3);
    int32_t _S71 = (_S69 + x1_1) * int(3);
    int32_t _S72 = y1_1 * int(256);
    int32_t _S73 = (_S72 + x0_1) * int(3);
    int32_t _S74 = (_S72 + x1_1) * int(3);
    Vector<float, 3>  out_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    int32_t c_5 = int(0);
    for(;;)
    {
        if(c_5 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S75 = 1.0f - _S67;
        float r_2 = (_S65.Load(_S70 + c_5) * _S75 + _S65.Load(_S71 + c_5) * _S67) * (1.0f - _S68) + (_S65.Load(_S73 + c_5) * _S75 + _S65.Load(_S74 + c_5) * _S67) * _S68;
        if(c_5 == int(0))
        {
            out_0.x = r_2;
        }
        else
        {
            if(c_5 == int(1))
            {
                out_0.y = r_2;
            }
            else
            {
                out_0.z = r_2;
            }
        }
        c_5 = c_5 + int(1);
    }
    return out_0;
}

static float sunIrradianceTop_0(SkyInput_0 * p_8)
{
    return 20.0f * p_8->sunIntensity_0;
}

static Vector<float, 3>  skyRadiance_0(SkyInput_0 * p_9, Vector<float, 3>  rayDir_0, bool includeSunDisc_0)
{
    Vector<float, 3>  _S76 = sunDirection_0(p_9);
    float _S77 = p_9->planetRadius_0;
    float planetRadius_3;
    if((p_9->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S77;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S78 = p_9->scaleHeight_0;
    float scaleHeight_2;
    if((p_9->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S78;
    }
    else
    {
        scaleHeight_2 = 1.0f;
    }
    float _S79 = planetRadius_3 + 2.0f;
    float _S80 = rayDir_0.y;
    float b_2 = _S79 * _S80;
    float cGround_0 = shellC_0(2.0f, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(b_2, shellC_0(2.0f, planetRadius_3, scaleHeight_2 * 8.0f));
    if(tTop_0 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 0.0f, 0.0f);
    }
    float tGround_0 = shellEnter_0(b_2, cGround_0);
    bool hitsGround_0 = tGround_0 > 0.0f;
    float safeSolid_0;
    if(hitsGround_0)
    {
        safeSolid_0 = tGround_0;
    }
    else
    {
        safeSolid_0 = tTop_0;
    }
    Vector<float, 3>  betaR_0 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_9->turbidity_0);
    float betaMExt_0 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_1(rayDir_0, _S76), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_6 = clampf_0(p_9->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S81 = g_6 * g_6;
    float hgDenom_0 = 1.0f + _S81 - 2.0f * g_6 * cosTheta_0;
    float _S82 = 1.0f - _S81;
    float _S83 = 12.56637096405029297f * hgDenom_0;
    float tPrev_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_0 = hgDenom_0;
    }
    else
    {
        tPrev_0 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S82 / (_S83 * (F32_sqrt((tPrev_0))));
    Vector<float, 3>  _S84 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    tPrev_0 = 0.0f;
    Vector<float, 3>  sumR_0 = _S84;
    Vector<float, 3>  sumM_0 = _S84;
    int32_t i_6 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_6 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S85 = i_6 + int(1);
        float tNext_0 = safeSolid_0 * float(_S85 * _S85) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_6 = _S85;
            continue;
        }
        float h_2 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_2 + tMid_0 * tMid_0, planetRadius_3);
        float hc_0;
        if(h_2 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_2;
        }
        float _S86 = - hc_0;
        float dR_0 = (F32_exp((_S86 / scaleHeight_2))) * dt_0;
        float dM_0 = (F32_exp((_S86 / 1200.0f))) * dt_0;
        float depthR_1 = depthR_0 + dR_0;
        float depthM_1 = depthM_0 + dM_0;
        Vector<float, 3>  _S87 = sampleTransmittanceLut_0(p_9, hc_0, lutMuFor_0(Vector<float, 3> (rayDir_0.x * tMid_0, _S79 + _S80 * tMid_0, rayDir_0.z * tMid_0), _S76));
        float _S88 = betaMExt_0 * depthM_1;
        Vector<float, 3>  transmittance_1 = Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_1 + _S88)))), (F32_exp((- (betaR_0.y * depthR_1 + _S88)))), (F32_exp((- (betaR_0.z * depthR_1 + _S88))))) * _S87;
        Vector<float, 3>  _S89 = sumM_0 + transmittance_1 * (Vector<float, 3> )dM_0;
        sumR_0 = sumR_0 + transmittance_1 * (Vector<float, 3> )dR_0;
        sumM_0 = _S89;
        depthR_0 = depthR_1;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_6 = _S85;
    }
    float _S90 = sunIrradianceTop_0(p_9);
    Vector<float, 3>  radiance_0 = (sumR_0 * betaR_0 * (Vector<float, 3> )phaseR_0 + sumM_0 * (Vector<float, 3> )(betaM_0 * phaseM_0)) * (Vector<float, 3> )_S90;
    Vector<float, 3>  radiance_1;
    if(hitsGround_0)
    {
        Vector<float, 3>  groundPoint_0 = Vector<float, 3> (rayDir_0.x * tGround_0, _S79 + _S80 * tGround_0, rayDir_0.z * tGround_0);
        float nDotL_0 = clampf_0(dot_1(normalizeExact_0(groundPoint_0), _S76), 0.0f, 1.0f);
        Vector<float, 3>  _S91 = sampleTransmittanceLut_0(p_9, 0.0f, lutMuFor_0(groundPoint_0, _S76));
        float _S92 = betaMExt_0 * depthM_0;
        radiance_1 = radiance_0 + Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S92)))), (F32_exp((- (betaR_0.y * depthR_0 + _S92)))), (F32_exp((- (betaR_0.z * depthR_0 + _S92))))) * _S91 * (Vector<float, 3> )(p_9->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S90);
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S93;
    if(!hitsGround_0)
    {
        _S93 = includeSunDisc_0;
    }
    else
    {
        _S93 = false;
    }
    if(_S93)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_9->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S94 = betaMExt_0 * depthM_0;
            Vector<float, 3>  viewT_0 = Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S94)))), (F32_exp((- (betaR_0.y * depthR_0 + _S94)))), (F32_exp((- (betaR_0.z * depthR_0 + _S94)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                safeSolid_0 = solidAngle_0;
            }
            else
            {
                safeSolid_0 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_0 * (Vector<float, 3> )(_S90 / safeSolid_0);
        }
    }
    return radiance_1;
}

static Vector<float, 3>  environmentRadiance_0(Environment_0 * e_0, Vector<float, 3>  dir_0, bool includeSunDisc_1)
{
    if((e_0->envMode_0) == int(1))
    {
        Vector<float, 3>  _S95 = skyRadiance_0(&e_0->sky_0, dir_0, includeSunDisc_1);
        return _S95;
    }
    return e_0->uniformRadiance_0;
}

static float transmittance_2(Medium_0 * m_3, MajorantGrid_0 * g_7, StructuredBuffer<float> bounds_3, StructuredBuffer<Vector<float, 2> > disp_4, Rng_0 * rng_1, Vector<float, 3>  p_10, Vector<float, 3>  dir_1, int32_t * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S96 = slabRange_0(m_3, p_10, dir_1, &t0_2, &t1_2);
    if(!_S96)
    {
        return 1.0f;
    }
    float _S97 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S97;
    Dda_0 _S98 = ddaInit_0(g_7, p_10, dir_1, _S97);
    Dda_0 dda_1 = _S98;
    int32_t i_7 = int(0);
    float t_3 = _S97;
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
        *steps_1 = *steps_1 + int(1);
        float _S99 = gridBound_0(g_7, bounds_3, (&dda_1)->cell_0, m_3->majorant_0);
        Dda_0 _S100 = dda_1;
        float _S101 = ddaExit_0(&_S100);
        float _S102 = (F32_min((_S101), (t1_2)));
        if(_S99 <= 0.0f)
        {
            if(_S102 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            t_3 = _S102;
            i_7 = i_7 + int(1);
            continue;
        }
        float _S103 = randFloat_0(rng_1);
        float t_4 = t_3 - (F32_log(((F32_max((1.0f - _S103), (1.00000001168609742e-07f)))))) / _S99;
        if(t_4 >= _S102)
        {
            if(_S102 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            t_3 = _S102;
            i_7 = i_7 + int(1);
            continue;
        }
        float _S104 = densityAt_0(m_3, disp_4, p_10 + dir_1 * (Vector<float, 3> )t_4);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S104 / _S99)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S105 = randFloat_0(rng_1);
            if(_S105 > 0.5f)
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
        i_7 = i_7 + int(1);
    }
    return tr_0;
}

static float hg_0(float cosT_0, float g_8)
{
    float _S106 = g_8 * g_8;
    float d_5 = 1.0f + _S106 - 2.0f * g_8 * cosT_0;
    return (1.0f - _S106) / (12.56637096405029297f * d_5 * (F32_sqrt(((F32_max((d_5), (9.99999997475242708e-07f)))))));
}

static float phaseIce_0(float cosT_1)
{
    float t_5 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_0(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_5 * t_5))) * 0.34999999403953552f;
}

static float draine_0(float cosT_2, float g_9, float a_1)
{
    float _S107 = g_9 * g_9;
    float _S108 = 2.0f * g_9;
    float d_6 = 1.0f + _S107 - _S108 * cosT_2;
    return (1.0f - _S107) / (12.56637096405029297f * d_6 * (F32_sqrt(((F32_max((d_6), (9.99999997475242708e-07f))))))) * (1.0f + a_1 * cosT_2 * cosT_2) / (1.0f + a_1 * (1.0f + _S108 * g_9) / 3.0f);
}

static float phaseLiquid_0(PhaseInput_0 * p_11, float cosT_3)
{
    return (1.0f - p_11->draineW_0) * hg_0(cosT_3, p_11->hgG_0) + p_11->draineW_0 * draine_0(cosT_3, p_11->draineG_0, p_11->draineAlpha_0);
}

static float phaseAt_0(PhaseInput_0 * p_12, float cosT_4)
{
    float _S109;
    if((p_12->useIce_0) != int(0))
    {
        _S109 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S110 = phaseLiquid_0(p_12, cosT_4);
        _S109 = _S110;
    }
    return _S109;
}

static Vector<float, 3>  sunTransmittanceAt_0(SkyInput_0 * p_13, Vector<float, 3>  worldPos_0)
{
    Vector<float, 3>  _S111 = sunDirection_0(p_13);
    float _S112 = p_13->planetRadius_0;
    float planetRadius_4;
    if((p_13->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S112;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S113 = worldPos_0.y;
    float altitude_2;
    if(_S113 > 0.0f)
    {
        altitude_2 = _S113;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    Vector<float, 3>  _S114 = sampleTransmittanceLut_0(p_13, altitude_2, lutMuFor_0(Vector<float, 3> (worldPos_0.x, planetRadius_4 + _S113, worldPos_0.z), _S111));
    return _S114;
}

static Vector<float, 3>  sampleHG_0(Rng_0 * rng_2, Vector<float, 3>  wo_0, float g_10, float * cosT_5)
{
    float _S115 = clamp_0(g_10, -0.99900001287460327f, 0.99900001287460327f);
    float u1_0 = randFloat_0(rng_2);
    float u2_0 = randFloat_0(rng_2);
    if((F32_abs((_S115))) < 0.00100000004749745f)
    {
        *cosT_5 = 1.0f - 2.0f * u1_0;
    }
    else
    {
        float _S116 = _S115 * _S115;
        float _S117 = 2.0f * _S115;
        float s_2 = (1.0f - _S116) / (1.0f - _S115 + _S117 * u1_0);
        *cosT_5 = (1.0f + _S116 - s_2 * s_2) / _S117;
    }
    float _S118 = clamp_0(*cosT_5, -1.0f, 1.0f);
    *cosT_5 = _S118;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S118 * _S118))))));
    float phi_0 = 6.28318548202514648f * u2_0;
    Vector<float, 3>  w_0 = normalize_0(wo_0);
    Vector<float, 3>  a_2;
    if((F32_abs((w_0.y))) < 0.94999998807907104f)
    {
        a_2 = Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_2 = Vector<float, 3> (1.0f, 0.0f, 0.0f);
    }
    Vector<float, 3>  u_1 = normalize_0(cross_0(a_2, w_0));
    return normalize_0((Vector<float, 3> )(sinT_0 * (F32_cos((phi_0)))) * u_1 + (Vector<float, 3> )(sinT_0 * (F32_sin((phi_0)))) * cross_0(w_0, u_1) + (Vector<float, 3> )*cosT_5 * w_0);
}

static Vector<float, 3>  samplePhaseDir_0(PhaseInput_0 * p_14, Rng_0 * rng_3, Vector<float, 3>  wo_1, float * weight_0)
{
    float cosT_6;
    Vector<float, 3>  dir_2;
    float _S119;
    if((p_14->useIce_0) != int(0))
    {
        float _S120 = randFloat_0(rng_3);
        if(_S120 < 0.72000002861022949f)
        {
            Vector<float, 3>  _S121 = sampleHG_0(rng_3, wo_1, 0.85000002384185791f, &cosT_6);
            dir_2 = _S121;
        }
        else
        {
            Vector<float, 3>  _S122 = sampleHG_0(rng_3, wo_1, 0.0f, &cosT_6);
            dir_2 = _S122;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_6, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S119 = phaseIce_0(cosT_6) / pdf_0;
        }
        else
        {
            _S119 = 0.0f;
        }
        *weight_0 = _S119;
    }
    else
    {
        float _S123 = randFloat_0(rng_3);
        float _S124 = p_14->draineW_0;
        if(_S123 < (p_14->draineW_0))
        {
            Vector<float, 3>  _S125 = sampleHG_0(rng_3, wo_1, p_14->draineG_0, &cosT_6);
            dir_2 = _S125;
        }
        else
        {
            Vector<float, 3>  _S126 = sampleHG_0(rng_3, wo_1, p_14->hgG_0, &cosT_6);
            dir_2 = _S126;
        }
        float pdf_1 = _S124 * hg_0(cosT_6, p_14->draineG_0) + (1.0f - _S124) * hg_0(cosT_6, p_14->hgG_0);
        if(pdf_1 > 9.99999971718068537e-10f)
        {
            float _S127 = phaseLiquid_0(p_14, cosT_6);
            _S119 = _S127 / pdf_1;
        }
        else
        {
            _S119 = 0.0f;
        }
        *weight_0 = _S119;
    }
    return dir_2;
}

static TraceResult_0 trace_0(Scene_0 * s_3, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_4, StructuredBuffer<Vector<float, 2> > drift_1, Rng_0 * rng_4, Vector<float, 3>  ro_3, Vector<float, 3>  rd_3)
{
    TraceResult_0 r_3;
    (&r_3)->pathRadiance_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&r_3)->scatterEvents_0 = int(0);
    (&r_3)->capped_0 = int(0);
    (&r_3)->trackingSteps_0 = int(0);
    Vector<float, 3>  _S128 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    int32_t _S129 = (I32_min((s_3->maxBounces_0), (int(256))));
    Vector<float, 3>  _S130 = ro_3;
    Vector<float, 3>  _S131 = rd_3;
    int32_t bounce_0 = int(0);
    Vector<float, 3>  throughput_0 = _S128;
    for(;;)
    {
        if(bounce_0 < int(256))
        {
        }
        else
        {
            break;
        }
        if(bounce_0 >= _S129)
        {
            (&r_3)->capped_0 = int(1);
            break;
        }
        Vector<float, 3>  p_15;
        float dist_0;
        bool _S132 = sampleFreeFlight_0(&s_3->medium_0, &s_3->grid_0, bounds_4, drift_1, rng_4, _S130, _S131, &p_15, &dist_0, &(&r_3)->trackingSteps_0);
        if(!_S132)
        {
            Vector<float, 3>  _S133 = environmentRadiance_0(&s_3->environment_0, _S131, bounce_0 == int(0));
            (&r_3)->pathRadiance_0 = (&r_3)->pathRadiance_0 + throughput_0 * _S133;
            break;
        }
        (&r_3)->scatterEvents_0 = (&r_3)->scatterEvents_0 + int(1);
        Vector<float, 3>  _S134 = s_3->sunDir_0;
        float _S135 = transmittance_2(&s_3->medium_0, &s_3->grid_0, bounds_4, drift_1, rng_4, p_15 + s_3->sunDir_0 * (Vector<float, 3> )s_3->shadowOffset_0, s_3->sunDir_0, &(&r_3)->trackingSteps_0);
        if(_S135 > 0.0f)
        {
            float _S136 = phaseAt_0(ph_0, dot_1(_S131, _S134));
            Vector<float, 3>  _S137 = s_3->sunIrradiance_0;
            Vector<float, 3>  sunE_0;
            if(((&s_3->environment_0)->envMode_0) == int(1))
            {
                float _S138 = sunIrradianceTop_0(&(&s_3->environment_0)->sky_0);
                Vector<float, 3>  _S139 = sunTransmittanceAt_0(&(&s_3->environment_0)->sky_0, p_15);
                sunE_0 = (Vector<float, 3> )_S138 * _S139;
            }
            else
            {
                sunE_0 = _S137;
            }
            (&r_3)->pathRadiance_0 = (&r_3)->pathRadiance_0 + throughput_0 * s_3->albedo_0 * (Vector<float, 3> )_S136 * (Vector<float, 3> )_S135 * sunE_0;
        }
        float w_1;
        Vector<float, 3>  _S140 = samplePhaseDir_0(ph_0, rng_4, _S131, &w_1);
        Vector<float, 3>  throughput_1 = throughput_0 * (s_3->albedo_0 * (Vector<float, 3> )w_1);
        Vector<float, 3>  _S141 = p_15;
        if(bounce_0 >= (s_3->rrStartBounce_0))
        {
            float p2_0 = clamp_0((F32_max((throughput_1.x), ((F32_max((throughput_1.y), (throughput_1.z)))))), 0.05000000074505806f, 1.0f);
            float _S142 = randFloat_0(rng_4);
            if(_S142 > p2_0)
            {
                break;
            }
            throughput_0 = throughput_1 / (Vector<float, 3> )p2_0;
        }
        else
        {
            throughput_0 = throughput_1;
        }
        int32_t bounce_1 = bounce_0 + int(1);
        _S130 = _S141;
        _S131 = _S140;
        bounce_0 = bounce_1;
    }
    return r_3;
}

static Vector<float, 3>  renderSample_0(Scene_0 * s_4, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_5, StructuredBuffer<Vector<float, 2> > drift_2, Vector<float, 3>  ro_4, Vector<float, 3>  rd_4, uint32_t seed_2)
{
    Rng_0 rng_5 = makeRng_0(seed_2);
    TraceResult_0 _S143 = trace_0(s_4, ph_1, bounds_5, drift_2, &rng_5, ro_4, rd_4);
    return _S143.pathRadiance_0;
}

void _cpuRenderRays(void* _S144, void* entryPointParams_0, void* _S145)
{
    ComputeThreadVaryingInput * _S146 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S144));
    int32_t i_8 = int32_t((_S146->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S146->groupThreadID).x);
    if(i_8 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Vector<float, 3>  * _S147 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->outRadiance_0)[i_8]);
    Vector<float, 3>  _S148 = renderSample_0(&(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->scene_0, &(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->phase_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->bounds_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->drift_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->origins_0.Load(i_8), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->directions_0.Load(i_8), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_8));
    *_S147 = _S148;
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
