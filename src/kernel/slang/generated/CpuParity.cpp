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

static float lerp_0(float x_3, float y_1, float s_0)
{
    return x_3 + (y_1 - x_3) * s_0;
}

static float dot_1(Vector<float, 3>  x_4, Vector<float, 3>  y_2)
{
    return x_4.x * y_2.x + x_4.y * y_2.y + x_4.z * y_2.z;
}

static float smoothstep_0(float min_0, float max_0, float x_5)
{
    float _S1 = saturate_0((x_5 - min_0) / (max_0 - min_0));
    return _S1 * _S1 * (3.0f - (_S1 + _S1));
}

static float length_0(Vector<float, 2>  x_6)
{
    return (F32_sqrt((dot_0(x_6, x_6))));
}

static Vector<float, 2>  floor_0(Vector<float, 2>  x_7)
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
        result_0[i_0] = (F32_floor((_slang_vector_get_element(x_7, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static Vector<float, 2>  lerp_1(Vector<float, 2>  x_8, Vector<float, 2>  y_3, Vector<float, 2>  s_1)
{
    return x_8 + (y_3 - x_8) * s_1;
}

static int32_t clamp_1(int32_t x_9, int32_t minBound_1, int32_t maxBound_1)
{
    return (I32_min(((I32_max((x_9), (minBound_1)))), (maxBound_1)));
}

static Vector<float, 3>  floor_1(Vector<float, 3>  x_10)
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
        result_1[i_1] = (F32_floor((_slang_vector_get_element(x_10, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
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
    int32_t i_2 = int32_t((_S5->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S5->groupThreadID).x);
    if(i_2 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Rng_0 rng_0 = makeRng_0((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_2));
    float * _S6 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->output_0)[i_2]);
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

static float gridBound_0(MajorantGrid_0 * g_1, StructuredBuffer<float> bounds_1, Vector<int32_t, 3>  c_0, float fallback_0)
{
    if((g_1->enabled_0) == int(0))
    {
        return fallback_0;
    }
    int32_t _S23 = c_0.x;
    bool _S24;
    if(_S23 < int(0))
    {
        _S24 = true;
    }
    else
    {
        _S24 = (c_0.y) < int(0);
    }
    if(_S24)
    {
        _S24 = true;
    }
    else
    {
        _S24 = (c_0.z) < int(0);
    }
    if(_S24)
    {
        _S24 = true;
    }
    else
    {
        _S24 = _S23 >= (g_1->dims_0.x);
    }
    if(_S24)
    {
        _S24 = true;
    }
    else
    {
        _S24 = (c_0.y) >= (g_1->dims_0.y);
    }
    if(_S24)
    {
        _S24 = true;
    }
    else
    {
        _S24 = (c_0.z) >= (g_1->dims_0.z);
    }
    if(_S24)
    {
        return fallback_0;
    }
    return bounds_1.Load((c_0.z * g_1->dims_0.y + c_0.y) * g_1->dims_0.x + _S23);
}

static float ddaExit_0(Dda_0 * d_1)
{
    return (F32_min((d_1->tMax_0.x), ((F32_min((d_1->tMax_0.y), (d_1->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_2)
{
    bool _S25;
    if((d_2->tMax_0.x) <= (d_2->tMax_0.y))
    {
        _S25 = (d_2->tMax_0.x) <= (d_2->tMax_0.z);
    }
    else
    {
        _S25 = false;
    }
    if(_S25)
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

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_2, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_11 = clamp_0(depth_0 / g_2->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_3 = clamp_1(int32_t((F32_floor((x_11)))), int(0), int(31));
    return lerp_1(disp_0.Load(i_3), disp_0.Load(i_3 + int(1)), (Vector<float, 2> )(x_11 - float(i_3)));
}

static Vector<uint32_t, 2>  pcg2d_0(Vector<uint32_t, 2>  v_0)
{
    Vector<uint32_t, 2>  _S26 = v_0 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S27 = _S26;
    _S27.x = _S27.x + _S26.y * 1664525U;
    _S27.y = _S27.y + _S27.x * 1664525U;
    Vector<uint32_t, 2>  _S28 = _S27 ^ (_S27 >> ((Vector<uint32_t, 2> )16U));
    _S27 = _S28;
    _S27.x = _S27.x + _S28.y * 1664525U;
    _S27.y = _S27.y + _S27.x * 1664525U;
    Vector<uint32_t, 2>  _S29 = _S27 ^ (_S27 >> ((Vector<uint32_t, 2> )16U));
    _S27 = _S29;
    return _S29;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_1, uint32_t salt_0)
{
    Vector<uint32_t, 2>  h_0 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_1.x), uint32_t(c_1.y)) ^ Vector<uint32_t, 2> (salt_0, salt_0 * 2654435761U));
    Vector<float, 2>  _S30 = Vector<float, 2> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1)};
    return _S30 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float cellField_0(GeneratorInput_0 * g_3, Vector<float, 2>  q_0)
{
    Vector<float, 2>  gq_0 = (q_0 - g_3->cellDrift_0) / (Vector<float, 2> )(g_3->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_0(gq_0);
    Vector<int32_t, 2>  _S31 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
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
        int32_t i_4 = int(-1);
        float acc_1 = acc_0;
        for(;;)
        {
            if(i_4 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_0 = _S31 + Vector<int32_t, 2> (i_4, j_0);
            if((hash22_0(o_0, 2654435769U).x) > (g_3->cellDensity_0))
            {
                i_4 = i_4 + int(1);
                continue;
            }
            Vector<float, 2>  _S32 = Vector<float, 2> {(float)_slang_vector_get_element(o_0, 0), (float)_slang_vector_get_element(o_0, 1)};
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(gq_0 - (_S32 + (Vector<float, 2> )0.5f + (hash22_0(o_0, 0U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.80000001192092896f)) * 2.20000004768371582f);
            i_4 = i_4 + int(1);
        }
        j_0 = j_0 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_3->cellStrength_0;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_1)
{
    Vector<uint32_t, 3>  _S33 = v_1 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S34 = _S33;
    _S34.x = _S34.x + _S33.y * _S33.z;
    _S34.y = _S34.y + _S34.z * _S34.x;
    _S34.z = _S34.z + _S34.x * _S34.y;
    Vector<uint32_t, 3>  _S35 = _S34 ^ (_S34 >> ((Vector<uint32_t, 3> )16U));
    _S34 = _S35;
    _S34.x = _S34.x + _S35.y * _S35.z;
    _S34.y = _S34.y + _S34.z * _S34.x;
    _S34.z = _S34.z + _S34.x * _S34.y;
    return _S34;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_2)
{
    Vector<uint32_t, 3>  h_1 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_2.x), uint32_t(c_2.y), uint32_t(c_2.z)));
    Vector<float, 3>  _S36 = Vector<float, 3> {(float)_slang_vector_get_element(h_1, 0), (float)_slang_vector_get_element(h_1, 1), (float)_slang_vector_get_element(h_1, 2)};
    return _S36 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float gradientNoise_0(Vector<float, 3>  p_1)
{
    Vector<float, 3>  fi_0 = floor_1(p_1);
    Vector<int32_t, 3>  _S37 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_1 - fi_0;
    Vector<float, 3>  u_0 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S38 = u_0.x;
    float _S39 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_1(hash33_0(_S37), f_0), dot_1(hash33_0(_S37 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S38), lerp_0(dot_1(hash33_0(_S37 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S37 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S38), _S39), lerp_0(lerp_0(dot_1(hash33_0(_S37 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S37 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S38), lerp_0(dot_1(hash33_0(_S37 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S37 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S38), _S39), u_0.z);
}

static float fbm_0(Vector<float, 3>  p_2, int32_t octaves_1)
{
    int32_t i_5 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S40 = p_2;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_5 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_5 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S40);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S41 = _S40 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_5 = i_5 + int(1);
        amp_0 = amp_1;
        _S40 = _S41;
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
    bool _S42;
    if(depth_1 < 0.0f)
    {
        _S42 = true;
    }
    else
    {
        _S42 = depth_1 > (g_4->streakLength_0);
    }
    if(_S42)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S43 = Vector<float, 2> {p_3.x, p_3.z};
    Vector<float, 2>  _S44 = driftAt_0(g_4, disp_1, depth_1);
    Vector<float, 2>  source_0 = _S43 - _S44;
    float _S45 = cellField_0(g_4, source_0);
    if(_S45 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S45 * (F32_exp((- g_4->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_4->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_4->streakLength_0, g_4->streakLength_0, depth_1)) * (F32_max((1.0f + g_4->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_4->detailScale_0).x, (source_0 / (Vector<float, 2> )g_4->detailScale_0).y, depth_1 / (F32_max((g_4->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_4->timeSeconds_0 * 0.00999999977648258f), g_4->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_4->opticalDepth_0 / (F32_max((g_4->streakLength_0), (1.0f)));
}

static float densityAt_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_2, Vector<float, 3>  p_4)
{
    float _S46 = p_4.y;
    bool _S47;
    if(_S46 < (m_1->slabBottom_0))
    {
        _S47 = true;
    }
    else
    {
        _S47 = _S46 > (m_1->slabTop_0);
    }
    if(_S47)
    {
        return 0.0f;
    }
    int32_t _S48 = m_1->mode_0;
    if((m_1->mode_0) == int(0))
    {
        return m_1->density_0;
    }
    if(_S48 == int(2))
    {
        float _S49 = iceDensity_0(&m_1->gen_0, disp_2, p_4);
        return _S49;
    }
    Vector<float, 3>  d_3 = (p_4 - m_1->coreCentre_0) / (Vector<float, 3> )(F32_max((m_1->coreRadius_0), (9.99999997475242708e-07f)));
    return m_1->density_0 + m_1->coreDensity_0 * (F32_exp((- dot_1(d_3, d_3))));
}

static float transmittance_0(Medium_0 * m_2, MajorantGrid_0 * g_5, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > disp_3, Rng_0 * rng_1, Vector<float, 3>  p_5, Vector<float, 3>  dir_0, int32_t * steps_0)
{
    float t0_1;
    float t1_1;
    bool _S50 = slabRange_0(m_2, p_5, dir_0, &t0_1, &t1_1);
    if(!_S50)
    {
        return 1.0f;
    }
    float _S51 = (F32_max((t0_1), (0.0f)));
    t0_1 = _S51;
    Dda_0 _S52 = ddaInit_0(g_5, p_5, dir_0, _S51);
    Dda_0 dda_0 = _S52;
    int32_t i_6 = int(0);
    float t_1 = _S51;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_6 < int(1024))
        {
        }
        else
        {
            break;
        }
        *steps_0 = *steps_0 + int(1);
        float _S53 = gridBound_0(g_5, bounds_2, (&dda_0)->cell_0, m_2->majorant_0);
        Dda_0 _S54 = dda_0;
        float _S55 = ddaExit_0(&_S54);
        float _S56 = (F32_min((_S55), (t1_1)));
        if(_S53 <= 0.0f)
        {
            if(_S56 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S56;
            i_6 = i_6 + int(1);
            continue;
        }
        float _S57 = randFloat_0(rng_1);
        float t_2 = t_1 - (F32_log(((F32_max((1.0f - _S57), (1.00000001168609742e-07f)))))) / _S53;
        if(t_2 >= _S56)
        {
            if(_S56 >= t1_1)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            t_1 = _S56;
            i_6 = i_6 + int(1);
            continue;
        }
        float _S58 = densityAt_0(m_2, disp_3, p_5 + dir_0 * (Vector<float, 3> )t_2);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S58 / _S53)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S59 = randFloat_0(rng_1);
            if(_S59 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_1 = t_2;
        tr_0 = tr_2;
        i_6 = i_6 + int(1);
    }
    return tr_0;
}

void _cpuTransmittanceTrial(void* _S60, void* entryPointParams_1, void* _S61)
{
    ComputeThreadVaryingInput * _S62 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S60));
    int32_t i_7 = int32_t((_S62->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S62->groupThreadID).x);
    if(i_7 >= ((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->count_1))
    {
        return;
    }
    Rng_0 rng_2 = makeRngForIndex_0((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->seed_1, i_7);
    int32_t steps_1 = int(0);
    float * _S63 = (&((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->output_1)[i_7]);
    float _S64 = transmittance_0(&(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->medium_0, &(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->grid_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->bounds_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->drift_0, &rng_2, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->origin_1, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->direction_0, &steps_1);
    *_S63 = _S64;
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
