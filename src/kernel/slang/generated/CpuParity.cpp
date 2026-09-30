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

struct Organization_0
{
    int32_t ogOn_0;
    Vector<float, 2>  ogAxis_0;
    float ogStretch_0;
    float ogCoherence_0;
    Vector<float, 2>  ogWaveK_0;
    float ogWaveAmp_0;
    float ogWarp_0;
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
    Organization_0 cvOrg_0;
    float cvGapWidth_0;
    float cvLacunarity_0;
};

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
    Organization_0 gnOrg_0;
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

static float dot_0(Vector<float, 2>  x_0, Vector<float, 2>  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y;
}

static Vector<float, 3>  floor_0(Vector<float, 3>  x_1)
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
        result_0[i_0] = (F32_floor((_slang_vector_get_element(x_1, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_0)
{
    Vector<uint32_t, 3>  _S1 = v_0 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S2 = _S1;
    _S2.x = _S2.x + _S1.y * _S1.z;
    _S2.y = _S2.y + _S2.z * _S2.x;
    _S2.z = _S2.z + _S2.x * _S2.y;
    Vector<uint32_t, 3>  _S3 = _S2 ^ (_S2 >> ((Vector<uint32_t, 3> )16U));
    _S2 = _S3;
    _S2.x = _S2.x + _S3.y * _S3.z;
    _S2.y = _S2.y + _S2.z * _S2.x;
    _S2.z = _S2.z + _S2.x * _S2.y;
    return _S2;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_0)
{
    Vector<uint32_t, 3>  h_0 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_0.x), uint32_t(c_0.y), uint32_t(c_0.z)));
    Vector<float, 3>  _S4 = Vector<float, 3> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1), (float)_slang_vector_get_element(h_0, 2)};
    return _S4 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float dot_1(Vector<float, 3>  x_2, Vector<float, 3>  y_1)
{
    return x_2.x * y_1.x + x_2.y * y_1.y + x_2.z * y_1.z;
}

static float lerp_0(float x_3, float y_2, float s_0)
{
    return x_3 + (y_2 - x_3) * s_0;
}

static float gradientNoise_0(Vector<float, 3>  p_0)
{
    Vector<float, 3>  fi_0 = floor_0(p_0);
    Vector<int32_t, 3>  _S5 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_0 - fi_0;
    Vector<float, 3>  u_0 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S6 = u_0.x;
    float _S7 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_1(hash33_0(_S5), f_0), dot_1(hash33_0(_S5 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S6), lerp_0(dot_1(hash33_0(_S5 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_1(hash33_0(_S5 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S6), _S7), lerp_0(lerp_0(dot_1(hash33_0(_S5 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_1(hash33_0(_S5 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S6), lerp_0(dot_1(hash33_0(_S5 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_1(hash33_0(_S5 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S6), _S7), u_0.z);
}

static Vector<float, 2>  orgWarpOffset_0(Organization_0 * o_0, Vector<float, 2>  g_0)
{
    Vector<float, 2>  s_1 = g_0 / (Vector<float, 2> )2.5f;
    float _S8 = s_1.x;
    float _S9 = s_1.y;
    return (Vector<float, 2> )o_0->ogWarp_0 * Vector<float, 2> (gradientNoise_0(Vector<float, 3> (_S8, 0.37000000476837158f, _S9)), gradientNoise_0(Vector<float, 3> (_S8 + 17.10000038146972656f, 5.82999992370605469f, _S9 - 9.39999961853027344f)));
}

static Vector<float, 2>  orgPattern_0(Organization_0 * o_1, Vector<float, 2>  q_0, float spacing_0)
{
    if((o_1->ogOn_0) == int(0))
    {
        return q_0 / (Vector<float, 2> )spacing_0;
    }
    Vector<float, 2>  g_1 = Vector<float, 2> (dot_0(q_0, o_1->ogAxis_0), dot_0(q_0, Vector<float, 2> (- o_1->ogAxis_0.y, o_1->ogAxis_0.x))) / Vector<float, 2> (spacing_0 * o_1->ogStretch_0, spacing_0);
    Vector<float, 2>  g_2;
    if((o_1->ogWarp_0) > 0.0f)
    {
        Vector<float, 2>  _S10 = orgWarpOffset_0(o_1, g_1);
        g_2 = g_1 + _S10;
    }
    else
    {
        g_2 = g_1;
    }
    return g_2;
}

static Vector<float, 2>  floor_1(Vector<float, 2>  x_4)
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
        result_1[i_1] = (F32_floor((_slang_vector_get_element(x_4, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static Vector<uint32_t, 2>  pcg2d_0(Vector<uint32_t, 2>  v_1)
{
    Vector<uint32_t, 2>  _S11 = v_1 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S12 = _S11;
    _S12.x = _S12.x + _S11.y * 1664525U;
    _S12.y = _S12.y + _S12.x * 1664525U;
    Vector<uint32_t, 2>  _S13 = _S12 ^ (_S12 >> ((Vector<uint32_t, 2> )16U));
    _S12 = _S13;
    _S12.x = _S12.x + _S13.y * 1664525U;
    _S12.y = _S12.y + _S12.x * 1664525U;
    Vector<uint32_t, 2>  _S14 = _S12 ^ (_S12 >> ((Vector<uint32_t, 2> )16U));
    _S12 = _S14;
    return _S14;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_1, uint32_t salt_0)
{
    Vector<uint32_t, 2>  h_1 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_1.x), uint32_t(c_1.y)) ^ Vector<uint32_t, 2> (salt_0, salt_0 * 2654435761U));
    Vector<float, 2>  _S15 = Vector<float, 2> {(float)_slang_vector_get_element(h_1, 0), (float)_slang_vector_get_element(h_1, 1)};
    return _S15 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float convLife_0(float u_1)
{
    float _S16 = 1.0f - u_1;
    return 6.75f * u_1 * _S16 * _S16;
}

static float convVigour_0(ConvectionInput_0 * c_2, Vector<int32_t, 2>  slot_0)
{
    Vector<float, 2>  h_2 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_0(0.34999999403953552f, 1.0f, h_2.y);
}

static Vector<float, 2>  orgJitter_0(Organization_0 * o_2, float jitter_0)
{
    float _S17;
    if((o_2->ogOn_0) != int(0))
    {
        _S17 = jitter_0 * (1.0f - o_2->ogCoherence_0);
    }
    else
    {
        _S17 = jitter_0;
    }
    return Vector<float, 2> (jitter_0, _S17);
}

static Vector<float, 2>  convCellCentre_0(ConvectionInput_0 * c_3, Vector<int32_t, 2>  slot_1)
{
    Vector<float, 2>  j_0 = hash22_0(slot_1, 1759714724U) - (Vector<float, 2> )0.5f;
    Vector<float, 2>  _S18 = Vector<float, 2> {(float)_slang_vector_get_element(slot_1, 0), (float)_slang_vector_get_element(slot_1, 1)};
    Vector<float, 2>  _S19 = _S18 + (Vector<float, 2> )0.5f;
    Vector<float, 2>  _S20 = orgJitter_0(&c_3->cvOrg_0, 0.69999998807907104f);
    return _S19 + j_0 * _S20;
}

static float convBump_0(float d2_0, float reach_0)
{
    float r2_0 = reach_0 * reach_0;
    if(d2_0 >= r2_0)
    {
        return 0.0f;
    }
    float t_0 = 1.0f - d2_0 / r2_0;
    return t_0 * t_0;
}

static float clamp_0(float x_5, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_5), (minBound_0)))), (maxBound_0)));
}

static float saturate_0(float x_6)
{
    return clamp_0(x_6, 0.0f, 1.0f);
}

static void convHole_0(ConvectionInput_0 * c_4, Vector<float, 2>  d_0, float d2_1, float vig_0, float * keep_0, Vector<float, 2>  * gKeep_0)
{
    float r_0 = 0.5f * c_4->cvLacunarity_0 * (F32_sqrt(((F32_sqrt((vig_0))))));
    if(!(d2_1 < (r_0 * r_0)))
    {
        return;
    }
    float dist_0 = (F32_sqrt((d2_1)));
    float inner_0 = 0.69999998807907104f * r_0;
    float band_0 = r_0 - inner_0;
    float t_1 = saturate_0((dist_0 - inner_0) / band_0);
    float k_0 = t_1 * t_1 * (3.0f - 2.0f * t_1);
    if(k_0 < (*keep_0))
    {
        *keep_0 = k_0;
        Vector<float, 2>  _S21;
        if(dist_0 > 9.99999997475242708e-07f)
        {
            _S21 = d_0 * (Vector<float, 2> )(6.0f * t_1 * (1.0f - t_1) / (band_0 * dist_0));
        }
        else
        {
            _S21 = Vector<float, 2> (0.0f, 0.0f);
        }
        *gKeep_0 = _S21;
    }
    return;
}

static Vector<float, 2>  lerp_1(Vector<float, 2>  x_7, Vector<float, 2>  y_3, Vector<float, 2>  s_2)
{
    return x_7 + (y_3 - x_7) * s_2;
}

static Vector<float, 2>  orgGradToWorld_0(Organization_0 * o_3, Vector<float, 2>  gp_0, float spacing_1)
{
    if((o_3->ogOn_0) == int(0))
    {
        return gp_0 / (Vector<float, 2> )spacing_1;
    }
    Vector<float, 2>  s_3 = gp_0 / Vector<float, 2> (spacing_1 * o_3->ogStretch_0, spacing_1);
    return o_3->ogAxis_0 * (Vector<float, 2> )s_3.x + Vector<float, 2> (- o_3->ogAxis_0.y, o_3->ogAxis_0.x) * (Vector<float, 2> )s_3.y;
}

static float orgWave_0(Organization_0 * o_4, Vector<float, 2>  q_1, Vector<float, 2>  * grad_0)
{
    *grad_0 = Vector<float, 2> (0.0f, 0.0f);
    bool _S22;
    if((o_4->ogOn_0) == int(0))
    {
        _S22 = true;
    }
    else
    {
        _S22 = (o_4->ogWaveAmp_0) <= 0.0f;
    }
    if(_S22)
    {
        return 1.0f;
    }
    Vector<float, 2>  _S23 = o_4->ogWaveK_0;
    float s_4 = 2.0f * (F32_frac((dot_0(q_1, o_4->ogWaveK_0)))) - 1.0f;
    float tri_0 = 1.0f - (F32_abs((s_4)));
    float crest_0 = tri_0 * tri_0 * (3.0f - 2.0f * tri_0);
    float dCrest_0 = 6.0f * tri_0 * (1.0f - tri_0);
    float dTri_0;
    if(s_4 > 0.0f)
    {
        dTri_0 = -2.0f;
    }
    else
    {
        dTri_0 = 2.0f;
    }
    float _S24 = o_4->ogWaveAmp_0;
    *grad_0 = _S23 * (Vector<float, 2> )(o_4->ogWaveAmp_0 * dCrest_0 * dTri_0);
    return 1.0f - _S24 * (1.0f - crest_0);
}

static float convOrganize_0(ConvectionInput_0 * c_5, Vector<float, 2>  q_2, float kTop_0, float kNext_0, Vector<float, 2>  gkTop_0, Vector<float, 2>  gkNext_0, float keep_1, Vector<float, 2>  gKeep_1, float w_0, Vector<float, 2>  gp_1, Vector<float, 2>  * grad_1)
{
    float _S25 = c_5->cvLacunarity_0;
    Vector<float, 2>  _S26;
    float _S27;
    if((c_5->cvLacunarity_0) > 0.0f)
    {
        float fill_0 = lerp_0(w_0, 0.40000000596046448f, _S25);
        float _S28 = fill_0 * keep_1;
        _S26 = gp_1 * (Vector<float, 2> )(1.0f - _S25) * (Vector<float, 2> )keep_1 + gKeep_1 * (Vector<float, 2> )fill_0;
        _S27 = _S28;
    }
    else
    {
        _S26 = gp_1;
        _S27 = w_0;
    }
    float _S29 = c_5->cvPolarity_0;
    bool _S30;
    if((c_5->cvPolarity_0) > 0.0f)
    {
        _S30 = (c_5->cvGapWidth_0) > 0.0f;
    }
    else
    {
        _S30 = false;
    }
    if(_S30)
    {
        Vector<float, 2>  _S31 = Vector<float, 2> (0.0f, 0.0f);
        Vector<float, 2>  gcn_0;
        float cn_0;
        if(kTop_0 > 0.0f)
        {
            Vector<float, 2>  _S32 = (gkTop_0 * (Vector<float, 2> )kNext_0 - gkNext_0 * (Vector<float, 2> )kTop_0) / (Vector<float, 2> )(kTop_0 * kTop_0);
            cn_0 = 1.0f - kNext_0 / kTop_0;
            gcn_0 = _S32;
        }
        else
        {
            cn_0 = 0.0f;
            gcn_0 = _S31;
        }
        float ramp_0 = 0.5f * c_5->cvGapWidth_0;
        float t_2 = saturate_0((cn_0 - ramp_0) / ramp_0);
        float s_5 = lerp_0(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S29);
        float _S33 = _S27 * s_5;
        _S26 = _S26 * (Vector<float, 2> )s_5 + gcn_0 * (Vector<float, 2> )(_S27 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S29));
        _S27 = _S33;
    }
    Vector<float, 2>  _S34 = orgGradToWorld_0(&c_5->cvOrg_0, _S26, c_5->cvSpacing_0);
    *grad_1 = _S34;
    Vector<float, 2>  gm_0;
    float _S35 = orgWave_0(&c_5->cvOrg_0, q_2, &gm_0);
    *grad_1 = _S34 * (Vector<float, 2> )_S35 + gm_0 * (Vector<float, 2> )_S27;
    return _S27 * _S35;
}

static float convUpdraftGradT_0(ConvectionInput_0 * c_6, Vector<float, 2>  q_3, Vector<float, 2>  * grad_2)
{
    Vector<float, 2>  goTop_0;
    Vector<float, 2>  _S36 = orgPattern_0(&c_6->cvOrg_0, q_3, c_6->cvSpacing_0);
    Vector<float, 2>  _S37 = floor_1(_S36);
    Vector<int32_t, 2>  _S38 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S37, 0), (int32_t)_slang_vector_get_element(_S37, 1)};
    Vector<float, 2>  _S39 = Vector<float, 2> (0.0f, 0.0f);
    float keep_2 = 1.0f;
    Vector<float, 2>  gKeep_2 = _S39;
    float oTop_0 = 0.0f;
    Vector<float, 2>  goTop_1 = _S39;
    float oNext_0 = 0.0f;
    float kTop_1 = 0.0f;
    Vector<float, 2>  gkTop_1 = _S39;
    float kNext_1 = 0.0f;
    Vector<float, 2>  goNext_0 = _S39;
    Vector<float, 2>  gkNext_1 = _S39;
    int32_t j_1 = int(-1);
    for(;;)
    {
        if(j_1 <= int(1))
        {
        }
        else
        {
            break;
        }
        float oTop_1 = oTop_0;
        goTop_0 = goTop_1;
        float oNext_1 = oNext_0;
        float kTop_2 = kTop_1;
        Vector<float, 2>  gkTop_2 = gkTop_1;
        float kNext_2 = kNext_1;
        Vector<float, 2>  goNext_1 = goNext_0;
        Vector<float, 2>  gkNext_2 = gkNext_1;
        int32_t i_2 = int(-1);
        for(;;)
        {
            if(i_2 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_2 = _S38 + Vector<int32_t, 2> (i_2, j_1);
            float _S40 = convVigour_0(c_6, slot_2);
            if(_S40 <= 0.0f)
            {
                i_2 = i_2 + int(1);
                continue;
            }
            Vector<float, 2>  _S41 = convCellCentre_0(c_6, slot_2);
            Vector<float, 2>  d_1 = _S36 - _S41;
            float d2_2 = dot_0(d_1, d_1);
            float ko_0 = _S40 * convBump_0(d2_2, 0.75f);
            float kk_0 = _S40 * convBump_0(d2_2, 1.04999995231628418f);
            convHole_0(c_6, d_1, d2_2, _S40, &keep_2, &gKeep_2);
            Vector<float, 2>  gko_0;
            if(d2_2 < 0.5625f)
            {
                gko_0 = d_1 * (Vector<float, 2> )(-4.0f * _S40 * (1.0f - d2_2 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S39;
            }
            Vector<float, 2>  gkk_0;
            if(d2_2 < 1.10249984264373779f)
            {
                gkk_0 = d_1 * (Vector<float, 2> )(-4.0f * _S40 * (1.0f - d2_2 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S39;
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
                float _S42 = oTop_2;
                Vector<float, 2>  _S43 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S42;
                goNext_2 = _S43;
            }
            float kTop_3;
            float kNext_3;
            Vector<float, 2>  gkTop_3;
            Vector<float, 2>  gkNext_3;
            if(kk_0 > kTop_2)
            {
                kTop_3 = kk_0;
                gkTop_3 = gkk_0;
                kNext_3 = kTop_2;
                gkNext_3 = gkTop_2;
            }
            else
            {
                if(kk_0 > kNext_2)
                {
                    kTop_3 = kk_0;
                    gkTop_3 = gkk_0;
                }
                else
                {
                    kTop_3 = kNext_2;
                    gkTop_3 = gkNext_2;
                }
                float _S44 = kTop_3;
                Vector<float, 2>  _S45 = gkTop_3;
                kTop_3 = kTop_2;
                gkTop_3 = gkTop_2;
                kNext_3 = _S44;
                gkNext_3 = _S45;
            }
            oTop_1 = oTop_2;
            goTop_0 = goTop_2;
            oNext_1 = oNext_2;
            kTop_2 = kTop_3;
            gkTop_2 = gkTop_3;
            kNext_2 = kNext_3;
            goNext_1 = goNext_2;
            gkNext_2 = gkNext_3;
            i_2 = i_2 + int(1);
        }
        int32_t j_2 = j_1 + int(1);
        oTop_0 = oTop_1;
        goTop_1 = goTop_0;
        oNext_0 = oNext_1;
        kTop_1 = kTop_2;
        gkTop_1 = gkTop_2;
        kNext_1 = kNext_2;
        goNext_0 = goNext_1;
        gkNext_1 = gkNext_2;
        j_1 = j_2;
    }
    float openRaw_0 = oNext_0 / 0.31000000238418579f;
    float _S46 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_1 - kNext_1;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / (Vector<float, 2> )0.31000000238418579f;
    }
    else
    {
        goTop_0 = _S39;
    }
    Vector<float, 2>  gClosed_0 = gkTop_1 - gkNext_1;
    float _S47 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_0(_S46, closedField_0, c_6->cvPolarity_0), lerp_1(goTop_0, gClosed_0, (Vector<float, 2> )c_6->cvPolarity_0), grad_2);
    return _S47;
}

static float convUpdraftGradT_1(ConvectionInput_0 * c_7, Vector<float, 2>  q_4, Vector<float, 2>  * grad_3)
{
    Vector<float, 2>  goTop_3;
    Vector<float, 2>  _S48 = orgPattern_0(&c_7->cvOrg_0, q_4, c_7->cvSpacing_0);
    Vector<float, 2>  _S49 = floor_1(_S48);
    Vector<int32_t, 2>  _S50 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S49, 0), (int32_t)_slang_vector_get_element(_S49, 1)};
    Vector<float, 2>  gKeep_3 = Vector<float, 2> (0.0f, 0.0f);
    float oTop_3 = 0.0f;
    Vector<float, 2>  goTop_4 = gKeep_3;
    float oNext_3 = 0.0f;
    float kTop_4 = 0.0f;
    Vector<float, 2>  gkTop_4 = gKeep_3;
    float kNext_4 = 0.0f;
    Vector<float, 2>  goNext_3 = gKeep_3;
    Vector<float, 2>  gkNext_4 = gKeep_3;
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
        float oTop_4 = oTop_3;
        goTop_3 = goTop_4;
        float oNext_4 = oNext_3;
        float kTop_5 = kTop_4;
        Vector<float, 2>  gkTop_5 = gkTop_4;
        float kNext_5 = kNext_4;
        Vector<float, 2>  goNext_4 = goNext_3;
        Vector<float, 2>  gkNext_5 = gkNext_4;
        int32_t i_3 = int(-1);
        for(;;)
        {
            if(i_3 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_3 = _S50 + Vector<int32_t, 2> (i_3, j_3);
            float _S51 = convVigour_0(c_7, slot_3);
            if(_S51 <= 0.0f)
            {
                i_3 = i_3 + int(1);
                continue;
            }
            Vector<float, 2>  _S52 = convCellCentre_0(c_7, slot_3);
            Vector<float, 2>  d_2 = _S48 - _S52;
            float d2_3 = dot_0(d_2, d_2);
            float ko_1 = _S51 * convBump_0(d2_3, 0.75f);
            float kk_1 = _S51 * convBump_0(d2_3, 1.04999995231628418f);
            Vector<float, 2>  gko_1;
            if(d2_3 < 0.5625f)
            {
                gko_1 = d_2 * (Vector<float, 2> )(-4.0f * _S51 * (1.0f - d2_3 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_1 = gKeep_3;
            }
            Vector<float, 2>  gkk_1;
            if(d2_3 < 1.10249984264373779f)
            {
                gkk_1 = d_2 * (Vector<float, 2> )(-4.0f * _S51 * (1.0f - d2_3 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_1 = gKeep_3;
            }
            float oTop_5;
            float oNext_5;
            Vector<float, 2>  goTop_5;
            Vector<float, 2>  goNext_5;
            if(ko_1 > oTop_4)
            {
                oTop_5 = ko_1;
                goTop_5 = gko_1;
                oNext_5 = oTop_4;
                goNext_5 = goTop_3;
            }
            else
            {
                if(ko_1 > oNext_4)
                {
                    oTop_5 = ko_1;
                    goTop_5 = gko_1;
                }
                else
                {
                    oTop_5 = oNext_4;
                    goTop_5 = goNext_4;
                }
                float _S53 = oTop_5;
                Vector<float, 2>  _S54 = goTop_5;
                oTop_5 = oTop_4;
                goTop_5 = goTop_3;
                oNext_5 = _S53;
                goNext_5 = _S54;
            }
            float kTop_6;
            float kNext_6;
            Vector<float, 2>  gkTop_6;
            Vector<float, 2>  gkNext_6;
            if(kk_1 > kTop_5)
            {
                kTop_6 = kk_1;
                gkTop_6 = gkk_1;
                kNext_6 = kTop_5;
                gkNext_6 = gkTop_5;
            }
            else
            {
                if(kk_1 > kNext_5)
                {
                    kTop_6 = kk_1;
                    gkTop_6 = gkk_1;
                }
                else
                {
                    kTop_6 = kNext_5;
                    gkTop_6 = gkNext_5;
                }
                float _S55 = kTop_6;
                Vector<float, 2>  _S56 = gkTop_6;
                kTop_6 = kTop_5;
                gkTop_6 = gkTop_5;
                kNext_6 = _S55;
                gkNext_6 = _S56;
            }
            oTop_4 = oTop_5;
            goTop_3 = goTop_5;
            oNext_4 = oNext_5;
            kTop_5 = kTop_6;
            gkTop_5 = gkTop_6;
            kNext_5 = kNext_6;
            goNext_4 = goNext_5;
            gkNext_5 = gkNext_6;
            i_3 = i_3 + int(1);
        }
        int32_t j_4 = j_3 + int(1);
        oTop_3 = oTop_4;
        goTop_4 = goTop_3;
        oNext_3 = oNext_4;
        kTop_4 = kTop_5;
        gkTop_4 = gkTop_5;
        kNext_4 = kNext_5;
        goNext_3 = goNext_4;
        gkNext_4 = gkNext_5;
        j_3 = j_4;
    }
    float openRaw_1 = oNext_3 / 0.31000000238418579f;
    float _S57 = (F32_min((openRaw_1), (1.0f)));
    float closedField_1 = kTop_4 - kNext_4;
    if(openRaw_1 < 1.0f)
    {
        goTop_3 = goNext_3 / (Vector<float, 2> )0.31000000238418579f;
    }
    else
    {
        goTop_3 = gKeep_3;
    }
    Vector<float, 2>  gClosed_1 = gkTop_4 - gkNext_4;
    float _S58 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_0(_S57, closedField_1, c_7->cvPolarity_0), lerp_1(goTop_3, gClosed_1, (Vector<float, 2> )c_7->cvPolarity_0), grad_3);
    return _S58;
}

static Vector<float, 2>  convCellCentrePlain_0(Vector<int32_t, 2>  slot_4)
{
    Vector<float, 2>  _S59 = Vector<float, 2> {(float)_slang_vector_get_element(slot_4, 0), (float)_slang_vector_get_element(slot_4, 1)};
    return _S59 + (Vector<float, 2> )0.5f + (hash22_0(slot_4, 1759714724U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.69999998807907104f;
}

static float convUpdraftGradT_2(ConvectionInput_0 * c_8, Vector<float, 2>  q_5, Vector<float, 2>  * grad_4)
{
    Vector<float, 2>  goTop_6;
    float _S60 = c_8->cvSpacing_0;
    Vector<float, 2>  _S61 = q_5 / (Vector<float, 2> )c_8->cvSpacing_0;
    Vector<float, 2>  _S62 = floor_1(_S61);
    Vector<int32_t, 2>  _S63 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S62, 0), (int32_t)_slang_vector_get_element(_S62, 1)};
    Vector<float, 2>  _S64 = Vector<float, 2> (0.0f, 0.0f);
    float oTop_6 = 0.0f;
    Vector<float, 2>  goTop_7 = _S64;
    float oNext_6 = 0.0f;
    float kTop_7 = 0.0f;
    Vector<float, 2>  gkTop_7 = _S64;
    float kNext_7 = 0.0f;
    Vector<float, 2>  goNext_6 = _S64;
    Vector<float, 2>  gkNext_7 = _S64;
    int32_t j_5 = int(-1);
    for(;;)
    {
        if(j_5 <= int(1))
        {
        }
        else
        {
            break;
        }
        float oTop_7 = oTop_6;
        goTop_6 = goTop_7;
        float oNext_7 = oNext_6;
        float kTop_8 = kTop_7;
        Vector<float, 2>  gkTop_8 = gkTop_7;
        float kNext_8 = kNext_7;
        Vector<float, 2>  goNext_7 = goNext_6;
        Vector<float, 2>  gkNext_8 = gkNext_7;
        int32_t i_4 = int(-1);
        for(;;)
        {
            if(i_4 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_5 = _S63 + Vector<int32_t, 2> (i_4, j_5);
            float _S65 = convVigour_0(c_8, slot_5);
            if(_S65 <= 0.0f)
            {
                i_4 = i_4 + int(1);
                continue;
            }
            Vector<float, 2>  d_3 = _S61 - convCellCentrePlain_0(slot_5);
            float d2_4 = dot_0(d_3, d_3);
            float ko_2 = _S65 * convBump_0(d2_4, 0.75f);
            float kk_2 = _S65 * convBump_0(d2_4, 1.04999995231628418f);
            Vector<float, 2>  gko_2;
            if(d2_4 < 0.5625f)
            {
                gko_2 = d_3 * (Vector<float, 2> )(-4.0f * _S65 * (1.0f - d2_4 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_2 = _S64;
            }
            Vector<float, 2>  gkk_2;
            if(d2_4 < 1.10249984264373779f)
            {
                gkk_2 = d_3 * (Vector<float, 2> )(-4.0f * _S65 * (1.0f - d2_4 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_2 = _S64;
            }
            float oTop_8;
            float oNext_8;
            Vector<float, 2>  goTop_8;
            Vector<float, 2>  goNext_8;
            if(ko_2 > oTop_7)
            {
                oTop_8 = ko_2;
                goTop_8 = gko_2;
                oNext_8 = oTop_7;
                goNext_8 = goTop_6;
            }
            else
            {
                if(ko_2 > oNext_7)
                {
                    oTop_8 = ko_2;
                    goTop_8 = gko_2;
                }
                else
                {
                    oTop_8 = oNext_7;
                    goTop_8 = goNext_7;
                }
                float _S66 = oTop_8;
                Vector<float, 2>  _S67 = goTop_8;
                oTop_8 = oTop_7;
                goTop_8 = goTop_6;
                oNext_8 = _S66;
                goNext_8 = _S67;
            }
            float kTop_9;
            float kNext_9;
            Vector<float, 2>  gkTop_9;
            Vector<float, 2>  gkNext_9;
            if(kk_2 > kTop_8)
            {
                kTop_9 = kk_2;
                gkTop_9 = gkk_2;
                kNext_9 = kTop_8;
                gkNext_9 = gkTop_8;
            }
            else
            {
                if(kk_2 > kNext_8)
                {
                    kTop_9 = kk_2;
                    gkTop_9 = gkk_2;
                }
                else
                {
                    kTop_9 = kNext_8;
                    gkTop_9 = gkNext_8;
                }
                float _S68 = kTop_9;
                Vector<float, 2>  _S69 = gkTop_9;
                kTop_9 = kTop_8;
                gkTop_9 = gkTop_8;
                kNext_9 = _S68;
                gkNext_9 = _S69;
            }
            oTop_7 = oTop_8;
            goTop_6 = goTop_8;
            oNext_7 = oNext_8;
            kTop_8 = kTop_9;
            gkTop_8 = gkTop_9;
            kNext_8 = kNext_9;
            goNext_7 = goNext_8;
            gkNext_8 = gkNext_9;
            i_4 = i_4 + int(1);
        }
        int32_t j_6 = j_5 + int(1);
        oTop_6 = oTop_7;
        goTop_7 = goTop_6;
        oNext_6 = oNext_7;
        kTop_7 = kTop_8;
        gkTop_7 = gkTop_8;
        kNext_7 = kNext_8;
        goNext_6 = goNext_7;
        gkNext_7 = gkNext_8;
        j_5 = j_6;
    }
    float openRaw_2 = oNext_6 / 0.31000000238418579f;
    float _S70 = (F32_min((openRaw_2), (1.0f)));
    float closedField_2 = kTop_7 - kNext_7;
    if(openRaw_2 < 1.0f)
    {
        goTop_6 = goNext_6 / (Vector<float, 2> )0.31000000238418579f;
    }
    else
    {
        goTop_6 = _S64;
    }
    Vector<float, 2>  gClosed_2 = gkTop_7 - gkNext_7;
    float _S71 = c_8->cvPolarity_0;
    *grad_4 = lerp_1(goTop_6, gClosed_2, (Vector<float, 2> )c_8->cvPolarity_0) / (Vector<float, 2> )_S60;
    return lerp_0(_S70, closedField_2, _S71);
}

static bool any_0(Vector<bool, 2>  x_8)
{
    bool result_2 = false;
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
        if(result_2)
        {
            result_2 = true;
        }
        else
        {
            result_2 = (bool((_slang_vector_get_element(x_8, i_5))));
        }
        i_5 = i_5 + int(1);
    }
    return result_2;
}

static int32_t clamp_1(int32_t x_9, int32_t minBound_1, int32_t maxBound_1)
{
    return (I32_min(((I32_max((x_9), (minBound_1)))), (maxBound_1)));
}

static float length_0(Vector<float, 2>  x_10)
{
    return (F32_sqrt((dot_0(x_10, x_10))));
}

static Vector<float, 2>  abs_0(Vector<float, 2>  x_11)
{
    Vector<float, 2>  result_3;
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
        result_3[i_6] = (F32_abs((_slang_vector_get_element(x_11, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_3;
}

static bool all_0(Vector<bool, 2>  x_12)
{
    bool result_4 = true;
    int32_t i_7 = int(0);
    for(;;)
    {
        if(i_7 < int(2))
        {
        }
        else
        {
            break;
        }
        if(result_4)
        {
            result_4 = (bool((_slang_vector_get_element(x_12, i_7))));
        }
        else
        {
            result_4 = false;
        }
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static float smoothstep_0(float min_0, float max_0, float x_13)
{
    float _S72 = saturate_0((x_13 - min_0) / (max_0 - min_0));
    return _S72 * _S72 * (3.0f - (_S72 + _S72));
}

static Vector<float, 2>  min_1(Vector<float, 2>  x_14, Vector<float, 2>  y_4)
{
    Vector<float, 2>  result_5;
    int32_t i_8 = int(0);
    for(;;)
    {
        if(i_8 < int(2))
        {
        }
        else
        {
            break;
        }
        result_5[i_8] = (F32_min((_slang_vector_get_element(x_14, i_8)), (_slang_vector_get_element(y_4, i_8))));
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static Vector<float, 2>  max_1(Vector<float, 2>  x_15, Vector<float, 2>  y_5)
{
    Vector<float, 2>  result_6;
    int32_t i_9 = int(0);
    for(;;)
    {
        if(i_9 < int(2))
        {
        }
        else
        {
            break;
        }
        result_6[i_9] = (F32_max((_slang_vector_get_element(x_15, i_9)), (_slang_vector_get_element(y_5, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static Rng_0 makeRng_0(uint32_t seed_2)
{
    Rng_0 r_1;
    (&r_1)->state_0 = seed_2;
    return r_1;
}

static float randFloat_0(Rng_0 * r_2)
{
    uint32_t _S73 = r_2->state_0 * 747796405U + 2891336453U;
    r_2->state_0 = _S73;
    uint32_t word_0 = ((_S73 >> ((_S73 >> 28U) + 4U)) ^ _S73) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

void _cpuRngTrial(void* _S74, void* entryPointParams_0, void* _S75)
{
    ComputeThreadVaryingInput * _S76 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S74));
    int32_t i_10 = int32_t((_S76->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S76->groupThreadID).x);
    if(i_10 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Rng_0 rng_0 = makeRng_0((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_10));
    float * _S77 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->output_0)[i_10]);
    float _S78 = randFloat_0(&rng_0);
    *_S77 = _S78;
    return;
}

static Rng_0 makeRngForIndex_0(uint32_t seed_3, int32_t index_0)
{
    uint32_t s_6 = uint32_t(index_0) * 747796405U + 2891336453U;
    uint32_t s_7 = ((s_6 >> ((s_6 >> 28U) + 4U)) ^ s_6) * 277803737U;
    return makeRng_0(((s_7 >> 22U) ^ s_7) ^ seed_3);
}

static bool clipAxis_0(float o_5, float d_4, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_4))) < 9.99999971718068537e-10f)
    {
        bool _S79;
        if(o_5 >= lo_0)
        {
            _S79 = o_5 <= hi_0;
        }
        else
        {
            _S79 = false;
        }
        return _S79;
    }
    float ta_0 = (lo_0 - o_5) / d_4;
    float tb_0 = (hi_0 - o_5) / d_4;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S80 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S80;
    return _S80 > (*t0_0);
}

static bool slabRange_0(Medium_0 * m_0, Vector<float, 3>  ro_0, Vector<float, 3>  rd_0, float * t0_1, float * t1_1)
{
    *t0_1 = 0.0f;
    *t1_1 = 1.0e+09f;
    float _S81 = rd_0.y;
    bool _S82;
    if((F32_abs((_S81))) < 9.99999997475242708e-07f)
    {
        float _S83 = ro_0.y;
        if(_S83 < (m_0->slabBottom_0))
        {
            _S82 = true;
        }
        else
        {
            _S82 = _S83 > (m_0->slabTop_0);
        }
        if(_S82)
        {
            return false;
        }
    }
    else
    {
        float _S84 = ro_0.y;
        float ta_1 = (m_0->slabBottom_0 - _S84) / _S81;
        float tb_1 = (m_0->slabTop_0 - _S84) / _S81;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S85 = (m_0->clipOn_0) != int(0);
    Vector<float, 2>  lo_1;
    if(_S85)
    {
        lo_1 = m_0->clipLo_0;
    }
    else
    {
        lo_1 = Vector<float, 2> (-1.0e+09f, -1.0e+09f);
    }
    Vector<float, 2>  hi_1;
    if(_S85)
    {
        hi_1 = m_0->clipHi_0;
    }
    else
    {
        hi_1 = Vector<float, 2> (1.0e+09f, 1.0e+09f);
    }
    float _S86 = m_0->fadeRadius_0;
    if((m_0->fadeRadius_0) > 0.0f)
    {
        Vector<float, 2>  _S87 = min_1(hi_1, m_0->fadeAt_0 + (Vector<float, 2> )_S86);
        lo_1 = max_1(lo_1, m_0->fadeAt_0 - (Vector<float, 2> )_S86);
        hi_1 = _S87;
    }
    bool _S88 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S88)
    {
        return false;
    }
    bool _S89 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S89)
    {
        return false;
    }
    float _S90 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S90;
    if(_S90 > (*t0_1))
    {
        _S82 = (*t1_1) > 0.0f;
    }
    else
    {
        _S82 = false;
    }
    return _S82;
}

static Dda_0 ddaInit_0(MajorantGrid_0 * g_3, Vector<float, 3>  ro_1, Vector<float, 3>  rd_1, float t_3)
{
    Dda_0 d_5;
    if((g_3->enabled_0) == int(0))
    {
        Vector<int32_t, 3>  _S91 = Vector<int32_t, 3> (int(0), int(0), int(0));
        (&d_5)->cell_0 = _S91;
        (&d_5)->stepDir_0 = _S91;
        Vector<float, 3>  _S92 = Vector<float, 3> (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_5)->tMax_0 = _S92;
        (&d_5)->tDelta_0 = _S92;
        return d_5;
    }
    Vector<float, 3>  p_1 = ro_1 + rd_1 * (Vector<float, 3> )t_3;
    Vector<float, 3>  _S93 = floor_0((p_1 - g_3->origin_0) / g_3->cellExtent_0);
    Vector<int32_t, 3>  _S94 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(_S93, 0), (int32_t)_slang_vector_get_element(_S93, 1), (int32_t)_slang_vector_get_element(_S93, 2)};
    (&d_5)->cell_0 = _S94;
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
        int32_t _S95 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            (&d_5)->stepDir_0[a_0] = int(0);
            (&d_5)->tMax_0[a_0] = 1.00000001504746622e+30f;
            (&d_5)->tDelta_0[a_0] = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S96 = _slang_vector_get_element(rd_1, _S95) > 0.0f;
            int32_t _S97;
            if(_S96)
            {
                _S97 = int(1);
            }
            else
            {
                _S97 = int(-1);
            }
            (&d_5)->stepDir_0[a_0] = _S97;
            float _S98 = g_3->origin_0[a_0];
            float _S99 = float((&d_5)->cell_0[a_0]);
            float _S100;
            if(_S96)
            {
                _S100 = 1.0f;
            }
            else
            {
                _S100 = 0.0f;
            }
            (&d_5)->tMax_0[a_0] = t_3 + (_S98 + (_S99 + _S100) * g_3->cellExtent_0[a_0] - _slang_vector_get_element(p_1, a_0)) / _slang_vector_get_element(rd_1, _S95);
            (&d_5)->tDelta_0[a_0] = (F32_abs((g_3->cellExtent_0[a_0] / _slang_vector_get_element(rd_1, _S95))));
        }
        a_0 = a_0 + int(1);
    }
    return d_5;
}

static float convCeiling_0(ConvectionInput_0 * c_9)
{
    float _S101 = c_9->cvBillow_0;
    float field_0 = c_9->cvDepth_0 + c_9->cvBillow_0;
    float _S102 = c_9->cvHeroTop_0;
    float hero_0;
    if((c_9->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S102 + _S101 * c_9->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    return (F32_max((field_0), (hero_0)));
}

static float convLift_0(ConvectionInput_0 * c_10, float above_0, float k_1)
{
    return (F32_min((c_10->cvBillow_0 * k_1 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_0(0.60000002384185791f, 1.0f, saturate_0(above_0 / (F32_max((c_10->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_0), (0.0f))))));
}

static void orgPatternBox_0(Organization_0 * o_6, Vector<float, 2>  q0_0, Vector<float, 2>  q1_0, float spacing_2, Vector<float, 2>  * a_1, Vector<float, 2>  * b_0)
{
    if((o_6->ogOn_0) == int(0))
    {
        *a_1 = q0_0 / (Vector<float, 2> )spacing_2;
        *b_0 = q1_0 / (Vector<float, 2> )spacing_2;
        return;
    }
    Organization_0 flat_0 = *o_6;
    (&flat_0)->ogWarp_0 = 0.0f;
    Organization_0 _S103 = flat_0;
    Vector<float, 2>  _S104 = orgPattern_0(&_S103, q0_0, spacing_2);
    Organization_0 _S105 = flat_0;
    Vector<float, 2>  _S106 = orgPattern_0(&_S105, q1_0, spacing_2);
    Vector<float, 2>  _S107 = Vector<float, 2> (q0_0.x, q1_0.y);
    Organization_0 _S108 = flat_0;
    Vector<float, 2>  _S109 = orgPattern_0(&_S108, _S107, spacing_2);
    Vector<float, 2>  _S110 = Vector<float, 2> (q1_0.x, q0_0.y);
    Organization_0 _S111 = flat_0;
    Vector<float, 2>  _S112 = orgPattern_0(&_S111, _S110, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S104.x)))), ((F32_abs((_S104.y))))))), ((F32_max(((F32_abs((_S106.x)))), ((F32_abs((_S106.y)))))))));
    *a_1 = min_1(min_1(_S104, _S109), min_1(_S112, _S106)) - (Vector<float, 2> )grow_0;
    *b_0 = max_1(max_1(_S104, _S109), max_1(_S112, _S106)) + (Vector<float, 2> )grow_0;
    return;
}

static void convSlotBound_0(ConvectionInput_0 * c_11, Vector<int32_t, 2>  slot_6, Vector<float, 2>  a_2, Vector<float, 2>  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S113 = convVigour_0(c_11, slot_6);
    if(_S113 <= 0.0f)
    {
        return;
    }
    Vector<float, 2>  _S114 = convCellCentre_0(c_11, slot_6);
    Vector<float, 2>  _S115 = a_2 - _S114;
    Vector<float, 2>  nearGap_0 = max_1(max_1(_S115, _S114 - b_1), Vector<float, 2> (0.0f, 0.0f));
    float dNear_0 = dot_0(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    Vector<float, 2>  farGap_0 = max_1(abs_0(_S115), abs_0(b_1 - _S114));
    float oHi_0 = _S113 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S113 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S113 * convBump_0(dot_0(farGap_0, farGap_0), 1.04999995231628418f);
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

static float convUpdraftBound_0(ConvectionInput_0 * c_12, Vector<float, 2>  q0_1, Vector<float, 2>  q1_1)
{
    Vector<float, 2>  a_3;
    Vector<float, 2>  b_2;
    orgPatternBox_0(&c_12->cvOrg_0, q0_1, q1_1, c_12->cvSpacing_0, &a_3, &b_2);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    Vector<float, 2>  _S116 = floor_1((a_3 + b_2) * (Vector<float, 2> )0.5f);
    Vector<int32_t, 2>  _S117 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S116, 0), (int32_t)_slang_vector_get_element(_S116, 1)};
    Vector<float, 2>  _S118 = Vector<float, 2> {(float)_slang_vector_get_element(_S117, 0), (float)_slang_vector_get_element(_S117, 1)};
    Vector<float, 2>  highEdge_0 = _S118 + (Vector<float, 2> )1.0f + (Vector<float, 2> )0.00009999999747379f;
    bool _S119;
    if(all_0(a_3 >= (_S118 - (Vector<float, 2> )0.00009999999747379f)))
    {
        _S119 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S119 = false;
    }
    int32_t j_7;
    int32_t i_11;
    if(_S119)
    {
        j_7 = int(-1);
        for(;;)
        {
            if(j_7 <= int(1))
            {
            }
            else
            {
                break;
            }
            i_11 = int(-1);
            for(;;)
            {
                if(i_11 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_12, _S117 + Vector<int32_t, 2> (i_11, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        Vector<float, 2>  _S120 = floor_1(a_3);
        Vector<int32_t, 2>  _S121 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S120, 0), (int32_t)_slang_vector_get_element(_S120, 1)};
        Vector<int32_t, 2>  _S122 = Vector<int32_t, 2> (int(1), int(1));
        Vector<int32_t, 2>  i0_0 = _S121 - _S122;
        Vector<float, 2>  _S123 = floor_1(b_2);
        Vector<int32_t, 2>  _S124 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S123, 0), (int32_t)_slang_vector_get_element(_S123, 1)};
        Vector<int32_t, 2>  _S125 = _S124 + _S122;
        int32_t _S126 = i0_0.y;
        j_7 = _S126;
        for(;;)
        {
            if(j_7 <= (_S125.y))
            {
                _S119 = j_7 <= (_S126 + int(32));
            }
            else
            {
                _S119 = false;
            }
            if(_S119)
            {
            }
            else
            {
                break;
            }
            int32_t _S127 = i0_0.x;
            i_11 = _S127;
            for(;;)
            {
                bool _S128;
                if(i_11 <= (_S125.x))
                {
                    _S128 = i_11 <= (_S127 + int(32));
                }
                else
                {
                    _S128 = false;
                }
                if(_S128)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_12, Vector<int32_t, 2> (i_11, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_0((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_12->cvPolarity_0);
    float _S129 = c_12->cvLacunarity_0;
    float field_2;
    if((c_12->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_0(field_1, 0.40000000596046448f, _S129);
    }
    else
    {
        field_2 = field_1;
    }
    return field_2 + 0.00000999999974738f;
}

static float convTowerHeight_0(ConvectionInput_0 * c_13, float w_1)
{
    float cover_0 = clamp_0(c_13->cvCoverage_0, 0.0f, 1.0f);
    if(cover_0 <= 0.0f)
    {
        return 0.0f;
    }
    float span_0 = (F32_sqrt((cover_0)));
    float u_2 = saturate_0((w_1 - (1.0f - span_0)) / span_0);
    if(u_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_13->cvDepth_0 * (F32_pow((u_2), (c_13->cvShape_0)));
}

static float convNeededUpdraft_0(ConvectionInput_0 * c_14, float above_1)
{
    float cover_1 = clamp_0(c_14->cvCoverage_0, 0.0f, 1.0f);
    bool _S130;
    if(cover_1 <= 0.0f)
    {
        _S130 = true;
    }
    else
    {
        _S130 = (c_14->cvDepth_0) <= 0.0f;
    }
    if(_S130)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_14->cvDepth_0), (1.0f / (F32_max((c_14->cvShape_0), (0.00100000004749745f))))));
}

static float convSlopeCap_0(ConvectionInput_0 * c_15)
{
    float _S131 = c_15->cvSpacing_0;
    float cap_0 = 7.0f / c_15->cvSpacing_0;
    if(((&c_15->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_0;
    }
    float _S132 = c_15->cvLacunarity_0;
    float cap_1;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        cap_1 = cap_0 + 1.5f / (0.15000000596046448f * _S132 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S131);
    }
    else
    {
        cap_1 = cap_0;
    }
    float _S133 = c_15->cvGapWidth_0;
    if((c_15->cvGapWidth_0) > 0.0f)
    {
        cap_1 = cap_1 + 14.25f * c_15->cvPolarity_0 / (0.5f * _S133 * _S131);
    }
    return cap_1 + 3.0f * (&c_15->cvOrg_0)->ogWaveAmp_0 * length_0((&c_15->cvOrg_0)->ogWaveK_0);
}

static float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S134;
    if(vMin_0 <= 0.0f)
    {
        _S134 = true;
    }
    else
    {
        _S134 = hMin_0 <= 0.0f;
    }
    if(_S134)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static float convHeroReach_0(ConvectionInput_0 * c_16)
{
    return c_16->cvHeroRadius_0 + 1.5f * c_16->cvBillow_0 * c_16->cvHeroBillow_0 + 24.0f;
}

static float convHeroHeight_0(ConvectionInput_0 * c_17, float r_3)
{
    float _S135 = c_17->cvHeroTop_0;
    bool _S136;
    if((c_17->cvHeroTop_0) <= 0.0f)
    {
        _S136 = true;
    }
    else
    {
        _S136 = r_3 >= (c_17->cvHeroRadius_0);
    }
    if(_S136)
    {
        return 0.0f;
    }
    return _S135 * (F32_pow((1.0f - r_3 * r_3 / (c_17->cvHeroRadius_0 * c_17->cvHeroRadius_0)), (c_17->cvShape_0)));
}

static float convHeroRadiusAt_0(ConvectionInput_0 * c_18, float above_2)
{
    float _S137 = c_18->cvHeroTop_0;
    bool _S138;
    if((c_18->cvHeroTop_0) <= 0.0f)
    {
        _S138 = true;
    }
    else
    {
        _S138 = above_2 >= _S137;
    }
    if(_S138)
    {
        return -1.0f;
    }
    return c_18->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S137), (1.0f / (F32_max((c_18->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static float convectionBound_0(ConvectionInput_0 * c_19, Vector<float, 3>  lo_2, Vector<float, 3>  hi_2)
{
    float low_0 = lo_2.y - c_19->cvBase_0;
    float high_0 = hi_2.y - c_19->cvBase_0;
    float _S139 = convCeiling_0(c_19);
    bool _S140;
    if(high_0 < 0.0f)
    {
        _S140 = true;
    }
    else
    {
        _S140 = low_0 > _S139;
    }
    if(_S140)
    {
        return 0.0f;
    }
    float _S141 = (F32_max((low_0), (0.0f)));
    float _S142 = (F32_min((high_0), (_S139)));
    float _S143 = convLift_0(c_19, _S142, 1.0f);
    float inside_0;
    if((c_19->cvHeroAlone_0) == int(0))
    {
        float _S144 = convUpdraftBound_0(c_19, Vector<float, 2> {lo_2.x, lo_2.z} - c_19->cvDrift_0, Vector<float, 2> {hi_2.x, hi_2.z} - c_19->cvDrift_0);
        float _S145 = convTowerHeight_0(c_19, _S144);
        float _S146 = convNeededUpdraft_0(c_19, _S141);
        if(_S144 < _S146)
        {
            float _S147 = convSlopeCap_0(c_19);
            inside_0 = _S143 - convDistanceFloor_0(_S141 - _S145, (_S146 - _S144) / _S147);
        }
        else
        {
            inside_0 = (F32_max((_S145 - _S141), (0.0f))) + _S143;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    if((c_19->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_0(max_1(max_1(Vector<float, 2> {lo_2.x, lo_2.z} - c_19->cvHeroAt_0, c_19->cvHeroAt_0 - Vector<float, 2> {hi_2.x, hi_2.z}), Vector<float, 2> (0.0f, 0.0f)));
        float _S148 = convHeroReach_0(c_19);
        if(rMin_0 < _S148)
        {
            float _S149 = convHeroHeight_0(c_19, rMin_0);
            float _S150 = convHeroRadiusAt_0(c_19, _S141);
            float _S151 = convLift_0(c_19, _S142, c_19->cvHeroBillow_0);
            bool _S152 = _S150 < 0.0f;
            if(_S152)
            {
                _S140 = true;
            }
            else
            {
                _S140 = rMin_0 >= _S150;
            }
            float heroIn_0;
            if(_S140)
            {
                if(_S152)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S150;
                }
                heroIn_0 = _S151 - convDistanceFloor_0(_S141 - _S149, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S149 - _S141), (0.0f))) + _S151;
            }
            inside_0 = (F32_max((inside_0), (heroIn_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return 0.0f;
    }
    return c_19->cvSigma_0 * (F32_sqrt((saturate_0(_S142 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1) * 1.00001001358032227f;
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_16 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_12 = clamp_1(int32_t((F32_floor((x_16)))), int(0), int(31));
    return lerp_1(disp_0.Load(i_12), disp_0.Load(i_12 + int(1)), (Vector<float, 2> )(x_16 - float(i_12)));
}

static void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<Vector<float, 2> > disp_1, float d0_0, float d1_0, Vector<float, 2>  * lo_3, Vector<float, 2>  * hi_3)
{
    Vector<float, 2>  _S153 = driftAt_0(g_5, disp_1, d0_0);
    *lo_3 = _S153;
    *hi_3 = _S153;
    Vector<float, 2>  _S154 = driftAt_0(g_5, disp_1, d1_0);
    *lo_3 = min_1(*lo_3, _S154);
    *hi_3 = max_1(*hi_3, _S154);
    int32_t _S155 = clamp_1(int32_t((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int32_t k_2 = clamp_1(int32_t((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_2 <= _S155)
        {
        }
        else
        {
            break;
        }
        *lo_3 = min_1(*lo_3, disp_1.Load(k_2));
        *hi_3 = max_1(*hi_3, disp_1.Load(k_2));
        k_2 = k_2 + int(1);
    }
    return;
}

static float cellFieldBound_0(GeneratorInput_0 * g_6, Vector<float, 2>  q0_2, Vector<float, 2>  q1_2)
{
    Vector<float, 2>  a_4;
    Vector<float, 2>  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    Vector<float, 2>  _S156 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    Vector<float, 2>  _S157 = floor_1(a_4);
    Vector<int32_t, 2>  _S158 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S157, 0), (int32_t)_slang_vector_get_element(_S157, 1)};
    Vector<int32_t, 2>  _S159 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  i0_1 = _S158 - _S159;
    Vector<float, 2>  _S160 = floor_1(b_3);
    Vector<int32_t, 2>  _S161 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S160, 0), (int32_t)_slang_vector_get_element(_S160, 1)};
    Vector<int32_t, 2>  _S162 = _S161 + _S159;
    int32_t _S163 = i0_1.y;
    int32_t j_8 = _S163;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S164;
        if(j_8 <= (_S162.y))
        {
            _S164 = j_8 <= (_S163 + int(32));
        }
        else
        {
            _S164 = false;
        }
        if(_S164)
        {
        }
        else
        {
            break;
        }
        int32_t _S165 = i0_1.x;
        int32_t i_13 = _S165;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S166;
            if(i_13 <= (_S162.x))
            {
                _S166 = i_13 <= (_S165 + int(32));
            }
            else
            {
                _S166 = false;
            }
            if(_S166)
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_7 = Vector<int32_t, 2> (i_13, j_8);
            if((hash22_0(o_7, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_13 = i_13 + int(1);
                continue;
            }
            Vector<float, 2>  _S167 = Vector<float, 2> {(float)_slang_vector_get_element(o_7, 0), (float)_slang_vector_get_element(o_7, 1)};
            Vector<float, 2>  c_20 = _S167 + (Vector<float, 2> )0.5f + (hash22_0(o_7, 0U) - (Vector<float, 2> )0.5f) * _S156;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_1(max_1(a_4 - c_20, c_20 - b_3), Vector<float, 2> (0.0f, 0.0f))) * 2.20000004768371582f);
            i_13 = i_13 + int(1);
        }
        j_8 = j_8 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_6->cellStrength_0;
}

static float iceDensityBound_0(GeneratorInput_0 * g_7, StructuredBuffer<Vector<float, 2> > disp_2, Vector<float, 3>  lo_4, Vector<float, 3>  hi_4)
{
    float d0_1 = g_7->cellAltitude_0 - hi_4.y;
    float d1_1 = g_7->cellAltitude_0 - lo_4.y;
    bool _S168;
    if(d1_1 < 0.0f)
    {
        _S168 = true;
    }
    else
    {
        _S168 = d0_1 > (g_7->streakLength_0);
    }
    if(_S168)
    {
        return 0.0f;
    }
    float _S169 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    Vector<float, 2>  driftLo_0;
    Vector<float, 2>  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S170 = cellFieldBound_0(g_7, Vector<float, 2> (lo_4.x, lo_4.z) - driftHi_0, Vector<float, 2> (hi_4.x, hi_4.z) - driftLo_0);
    return (F32_max((_S170 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S169), (1.0f)));
}

static float mediumBound_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_3, Vector<float, 3>  lo_5, Vector<float, 3>  hi_5)
{
    int32_t _S171 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S172 = convectionBound_0(&m_1->conv_0, lo_5, hi_5);
        return _S172;
    }
    if(_S171 == int(2))
    {
        float _S173 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_5, hi_5);
        return _S173;
    }
    return m_1->majorant_0;
}

static float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_1, StructuredBuffer<Vector<float, 2> > disp_4, Vector<int32_t, 3>  c_21, float fallback_0)
{
    int32_t _S174 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S174 == int(2))
    {
        Vector<float, 3>  _S175 = Vector<float, 3> {(float)_slang_vector_get_element(c_21, 0), (float)_slang_vector_get_element(c_21, 1), (float)_slang_vector_get_element(c_21, 2)};
        Vector<float, 3>  lo_6 = g_8->origin_0 + _S175 * g_8->cellExtent_0;
        float _S176 = mediumBound_0(m_2, disp_4, lo_6, lo_6 + g_8->cellExtent_0);
        return _S176;
    }
    int32_t _S177 = c_21.x;
    bool _S178;
    if(_S177 < int(0))
    {
        _S178 = true;
    }
    else
    {
        _S178 = (c_21.y) < int(0);
    }
    if(_S178)
    {
        _S178 = true;
    }
    else
    {
        _S178 = (c_21.z) < int(0);
    }
    if(_S178)
    {
        _S178 = true;
    }
    else
    {
        _S178 = _S177 >= (g_8->dims_0.x);
    }
    if(_S178)
    {
        _S178 = true;
    }
    else
    {
        _S178 = (c_21.y) >= (g_8->dims_0.y);
    }
    if(_S178)
    {
        _S178 = true;
    }
    else
    {
        _S178 = (c_21.z) >= (g_8->dims_0.z);
    }
    if(_S178)
    {
        return fallback_0;
    }
    return bounds_1.Load((c_21.z * g_8->dims_0.y + c_21.y) * g_8->dims_0.x + _S177);
}

static float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S179;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S179 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S179 = false;
    }
    if(_S179)
    {
        d_7->cell_0.x = d_7->cell_0.x + d_7->stepDir_0.x;
        d_7->tMax_0.x = d_7->tMax_0.x + d_7->tDelta_0.x;
    }
    else
    {
        if((d_7->tMax_0.y) <= (d_7->tMax_0.z))
        {
            d_7->cell_0.y = d_7->cell_0.y + d_7->stepDir_0.y;
            d_7->tMax_0.y = d_7->tMax_0.y + d_7->tDelta_0.y;
        }
        else
        {
            d_7->cell_0.z = d_7->cell_0.z + d_7->stepDir_0.z;
            d_7->tMax_0.z = d_7->tMax_0.z + d_7->tDelta_0.z;
        }
    }
    return;
}

static float orgWaveFactor_0(Organization_0 * o_8, Vector<float, 2>  q_6)
{
    Vector<float, 2>  unused_0;
    float _S180 = orgWave_0(o_8, q_6, &unused_0);
    return _S180;
}

static float cellField_0(GeneratorInput_0 * g_9, Vector<float, 2>  q_7)
{
    Vector<float, 2>  _S181 = q_7 - g_9->cellDrift_0;
    Vector<float, 2>  _S182 = orgPattern_0(&g_9->gnOrg_0, _S181, g_9->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_1(_S182);
    Vector<int32_t, 2>  _S183 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
    Vector<float, 2>  _S184 = orgJitter_0(&g_9->gnOrg_0, 0.80000001192092896f);
    int32_t j_9 = int(-1);
    float acc_2 = 0.0f;
    for(;;)
    {
        if(j_9 <= int(1))
        {
        }
        else
        {
            break;
        }
        int32_t i_14 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_14 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_9 = _S183 + Vector<int32_t, 2> (i_14, j_9);
            if((hash22_0(o_9, 2654435769U).x) > (g_9->cellDensity_0))
            {
                i_14 = i_14 + int(1);
                continue;
            }
            Vector<float, 2>  _S185 = Vector<float, 2> {(float)_slang_vector_get_element(o_9, 0), (float)_slang_vector_get_element(o_9, 1)};
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(_S182 - (_S185 + (Vector<float, 2> )0.5f + (hash22_0(o_9, 0U) - (Vector<float, 2> )0.5f) * _S184)) * 2.20000004768371582f);
            i_14 = i_14 + int(1);
        }
        j_9 = j_9 + int(1);
        acc_2 = acc_3;
    }
    float _S186 = acc_2 * g_9->cellStrength_0;
    float _S187 = orgWaveFactor_0(&g_9->gnOrg_0, _S181);
    return _S186 * _S187;
}

static float fbm_0(Vector<float, 3>  p_2, int32_t octaves_1)
{
    int32_t i_15 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S188 = p_2;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_15 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_15 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S188);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S189 = _S188 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_15 = i_15 + int(1);
        amp_0 = amp_1;
        _S188 = _S189;
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

static float iceDensity_0(GeneratorInput_0 * g_10, StructuredBuffer<Vector<float, 2> > disp_5, Vector<float, 3>  p_3)
{
    float depth_1 = g_10->cellAltitude_0 - p_3.y;
    bool _S190;
    if(depth_1 < 0.0f)
    {
        _S190 = true;
    }
    else
    {
        _S190 = depth_1 > (g_10->streakLength_0);
    }
    if(_S190)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S191 = Vector<float, 2> {p_3.x, p_3.z};
    Vector<float, 2>  _S192 = driftAt_0(g_10, disp_5, depth_1);
    Vector<float, 2>  source_0 = _S191 - _S192;
    float _S193 = cellField_0(g_10, source_0);
    if(_S193 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S193 * (F32_exp((- g_10->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_10->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_10->streakLength_0, g_10->streakLength_0, depth_1)) * (F32_max((1.0f + g_10->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_10->detailScale_0).x, (source_0 / (Vector<float, 2> )g_10->detailScale_0).y, depth_1 / (F32_max((g_10->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_10->timeSeconds_0 * 0.00999999977648258f), g_10->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_10->opticalDepth_0 / (F32_max((g_10->streakLength_0), (1.0f)));
}

static float convUpdraftGrad_0(ConvectionInput_0 * c_22, Vector<float, 2>  q_8, Vector<float, 2>  * grad_5)
{
    if(((&c_22->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S194 = convUpdraftGradT_2(c_22, q_8, grad_5);
        return _S194;
    }
    if((c_22->cvLacunarity_0) <= 0.0f)
    {
        float _S195 = convUpdraftGradT_1(c_22, q_8, grad_5);
        return _S195;
    }
    float _S196 = convUpdraftGradT_0(c_22, q_8, grad_5);
    return _S196;
}

static float convSurfaceDistance_0(float v_2, float delta_0, float slope_0)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_0 * slope_0 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_8 = num_0 / den_0;
    float _S197;
    if(v_2 >= 0.0f)
    {
        _S197 = d_8;
    }
    else
    {
        _S197 = - d_8;
    }
    return _S197;
}

static Vector<float, 3>  convTwist_0(Vector<float, 3>  x_17)
{
    float _S198 = x_17.x;
    float _S199 = x_17.y;
    float _S200 = x_17.z;
    return Vector<float, 3> (0.0f * _S198 + 0.80000001192092896f * _S199 + 0.60000002384185791f * _S200, -0.80000001192092896f * _S198 + 0.36000001430511475f * _S199 - 0.47999998927116394f * _S200, -0.60000002384185791f * _S198 - 0.47999998927116394f * _S199 + 0.63999998569488525f * _S200);
}

static float convPuffs_0(Vector<float, 3>  x_18)
{
    Vector<float, 3>  fl_0 = floor_0(x_18);
    Vector<int32_t, 3>  _S201 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fl_0, 0), (int32_t)_slang_vector_get_element(fl_0, 1), (int32_t)_slang_vector_get_element(fl_0, 2)};
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
    Vector<int32_t, 3>  _S202 = Vector<int32_t, 3> (dz_0, dy_0, dx_0);
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
                Vector<int32_t, 3>  off_0 = _S202 + Vector<int32_t, 3> (dx_0, dy_0, dz_0);
                Vector<float, 3>  _S203 = Vector<float, 3> {(float)_slang_vector_get_element(off_0, 0), (float)_slang_vector_get_element(off_0, 1), (float)_slang_vector_get_element(off_0, 2)};
                Vector<float, 3>  d_9 = _S203 + (Vector<float, 3> )0.5f + (Vector<float, 3> )0.25f * hash33_0(_S201 + off_0) - f_1;
                float _S204 = (F32_min((nearest_1), (dot_1(d_9, d_9))));
                int32_t dx_1 = dx_0 + int(1);
                nearest_1 = _S204;
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

static float convBillow_0(ConvectionInput_0 * c_23, Vector<float, 3>  p_4, float scale_0)
{
    Vector<float, 3>  _S205 = Vector<float, 3> (p_4.x, p_4.y - c_23->cvRise_0, p_4.z) / (Vector<float, 3> )scale_0;
    int32_t i_16 = int(0);
    Vector<float, 3>  x_19 = _S205;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_16 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_16 >= (c_23->cvOctaves_0))
        {
            break;
        }
        Vector<float, 3>  x_20 = convTwist_0(x_19);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_20);
        float norm_3 = norm_2 + amp_2;
        Vector<float, 3>  x_21 = x_20 * (Vector<float, 3> )2.17000007629394531f;
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_16 = i_16 + int(1);
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
    return clamp_0(raw_0 * 2.20000004768371582f - 1.15999996662139893f, -1.0f, 1.0f);
}

static float convInside_0(ConvectionInput_0 * c_24, float d_10, float lift_0, Vector<float, 3>  x_22, float scale_1)
{
    float _S206 = d_10 + lift_0;
    if(_S206 <= 0.0f)
    {
        return _S206;
    }
    if((d_10 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S207 = convBillow_0(c_24, x_22, scale_1);
    return d_10 + lift_0 * _S207;
}

static float convHeroInside_0(ConvectionInput_0 * c_25, Vector<float, 3>  p_5, float above_3)
{
    Vector<float, 2>  rel_0 = Vector<float, 2> {p_5.x, p_5.z} - c_25->cvHeroAt_0;
    float r_4 = length_0(rel_0);
    float _S208 = convHeroReach_0(c_25);
    if(r_4 >= _S208)
    {
        return -1.00000001504746622e+30f;
    }
    float _S209 = convHeroHeight_0(c_25, r_4);
    float v_3 = _S209 - above_3;
    float _S210 = convHeroRadiusAt_0(c_25, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_11;
    if(_S210 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_11 = v_3;
    }
    else
    {
        float h_3 = _S210 - r_4;
        float d_12 = convSurfaceDistance_0(v_3, h_3, 1.0f);
        if((F32_abs((v_3))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_12 * (d_12 / v_3);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_3))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_12 * (d_12 / h_3);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S211 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S211;
        d_11 = d_12;
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
    Vector<float, 3>  x_23 = Vector<float, 3> (at_0.x, p_5.y + shiftUp_0, at_0.y) + c_25->cvHeroSeed_0;
    float _S212 = c_25->cvHeroBillow_0;
    float _S213 = convLift_0(c_25, above_3, c_25->cvHeroBillow_0);
    float _S214 = convInside_0(c_25, d_11, _S213, x_23, c_25->cvBillowScale_0 * _S212);
    return _S214;
}

static float convectionDensity_0(ConvectionInput_0 * c_26, Vector<float, 3>  p_6)
{
    float _S215 = p_6.y;
    float above_4 = _S215 - c_26->cvBase_0;
    bool _S216;
    if(above_4 < 0.0f)
    {
        _S216 = true;
    }
    else
    {
        float _S217 = convCeiling_0(c_26);
        _S216 = above_4 > _S217;
    }
    if(_S216)
    {
        return 0.0f;
    }
    float _S218 = convLift_0(c_26, above_4, 1.0f - 0.60000002384185791f * c_26->cvLacunarity_0);
    float inside_2;
    if((c_26->cvHeroAlone_0) == int(0))
    {
        Vector<float, 2>  q_9 = Vector<float, 2> {p_6.x, p_6.z} - c_26->cvDrift_0;
        Vector<float, 2>  slope_1;
        float _S219 = convUpdraftGrad_0(c_26, q_9, &slope_1);
        float _S220 = convTowerHeight_0(c_26, _S219);
        float v_4 = _S220 - above_4;
        float _S221 = convNeededUpdraft_0(c_26, above_4);
        float delta_1 = _S219 - _S221;
        float _S222 = length_0(slope_1);
        float _S223 = convSlopeCap_0(c_26);
        float d_13 = convSurfaceDistance_0(v_4, delta_1, (F32_min((_S222), (_S223))));
        if((d_13 + _S218) > 0.0f)
        {
            if((F32_abs((v_4))) > 9.99999997475242708e-07f)
            {
                inside_2 = d_13 * (d_13 / v_4);
            }
            else
            {
                inside_2 = 0.0f;
            }
            Vector<float, 2>  shiftAcross_0;
            if((F32_abs((delta_1))) > 9.999999960041972e-13f)
            {
                shiftAcross_0 = slope_1 * (Vector<float, 2> )(- d_13 * (d_13 / delta_1));
            }
            else
            {
                shiftAcross_0 = Vector<float, 2> (0.0f, 0.0f);
            }
            float _S224 = convInside_0(c_26, d_13, _S218, Vector<float, 3> (q_9.x + shiftAcross_0.x, _S215 + inside_2, q_9.y + shiftAcross_0.y), c_26->cvBillowScale_0);
            inside_2 = _S224;
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
    if((c_26->cvHeroTop_0) > 0.0f)
    {
        _S216 = inside_2 < 12.0f;
    }
    else
    {
        _S216 = false;
    }
    if(_S216)
    {
        float _S225 = convHeroInside_0(c_26, p_6, above_4);
        inside_2 = (F32_max((inside_2), (_S225)));
    }
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_26->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2);
}

static float densityAt_0(Medium_0 * m_3, StructuredBuffer<Vector<float, 2> > disp_6, Vector<float, 3>  p_7)
{
    float _S226 = p_7.y;
    bool _S227;
    if(_S226 < (m_3->slabBottom_0))
    {
        _S227 = true;
    }
    else
    {
        _S227 = _S226 > (m_3->slabTop_0);
    }
    if(_S227)
    {
        return 0.0f;
    }
    if((m_3->clipOn_0) != int(0))
    {
        Vector<float, 2>  _S228 = Vector<float, 2> {p_7.x, p_7.z};
        if(any_0(_S228 < (m_3->clipLo_0)))
        {
            _S227 = true;
        }
        else
        {
            _S227 = any_0(_S228 > (m_3->clipHi_0));
        }
    }
    else
    {
        _S227 = false;
    }
    if(_S227)
    {
        return 0.0f;
    }
    float _S229 = m_3->fadeRadius_0;
    float fade_0;
    if((m_3->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S229 - length_0(Vector<float, 2> {p_7.x, p_7.z} - m_3->fadeAt_0)) / (F32_max((m_3->fadeWidth_0), (1.0f))));
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
    int32_t _S230 = m_3->mode_0;
    if((m_3->mode_0) == int(0))
    {
        return m_3->density_0 * fade_0;
    }
    if(_S230 == int(2))
    {
        float _S231 = iceDensity_0(&m_3->gen_0, disp_6, p_7);
        return _S231 * fade_0;
    }
    if(_S230 == int(3))
    {
        float _S232 = convectionDensity_0(&m_3->conv_0, p_7);
        return _S232 * fade_0;
    }
    Vector<float, 3>  d_14 = (p_7 - m_3->coreCentre_0) / (Vector<float, 3> )(F32_max((m_3->coreRadius_0), (9.99999997475242708e-07f)));
    return (m_3->density_0 + m_3->coreDensity_0 * (F32_exp((- dot_1(d_14, d_14))))) * fade_0;
}

static float transmittance_0(Medium_0 * m_4, MajorantGrid_0 * g_11, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > disp_7, Rng_0 * rng_1, Vector<float, 3>  p_8, Vector<float, 3>  dir_0, int32_t * steps_0)
{
    float t0_2;
    float t1_2;
    bool _S233 = slabRange_0(m_4, p_8, dir_0, &t0_2, &t1_2);
    if(!_S233)
    {
        return 1.0f;
    }
    float _S234 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S234;
    Dda_0 _S235 = ddaInit_0(g_11, p_8, dir_0, _S234);
    Dda_0 dda_0 = _S235;
    float _S236 = m_4->majorant_0;
    float _S237 = gridBound_0(m_4, g_11, bounds_2, disp_7, (&dda_0)->cell_0, m_4->majorant_0);
    float localMaj_0 = _S237;
    int32_t i_17 = int(0);
    float t_4 = _S234;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_17 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S238 = dda_0;
        float _S239 = ddaExit_0(&_S238);
        float _S240 = (F32_min((_S239), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S240 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S241 = gridBound_0(m_4, g_11, bounds_2, disp_7, (&dda_0)->cell_0, _S236);
            localMaj_0 = _S241;
            t_4 = _S240;
            i_17 = i_17 + int(1);
            continue;
        }
        float _S242 = randFloat_0(rng_1);
        float t_5 = t_4 - (F32_log(((F32_max((1.0f - _S242), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_5 >= _S240)
        {
            if(_S240 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S243 = gridBound_0(m_4, g_11, bounds_2, disp_7, (&dda_0)->cell_0, _S236);
            localMaj_0 = _S243;
            t_4 = _S240;
            i_17 = i_17 + int(1);
            continue;
        }
        float _S244 = densityAt_0(m_4, disp_7, p_8 + dir_0 * (Vector<float, 3> )t_5);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S244 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S245 = randFloat_0(rng_1);
            if(_S245 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_4 = t_5;
        tr_0 = tr_2;
        i_17 = i_17 + int(1);
    }
    return tr_0;
}

void _cpuTransmittanceTrial(void* _S246, void* entryPointParams_1, void* _S247)
{
    ComputeThreadVaryingInput * _S248 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S246));
    int32_t i_18 = int32_t((_S248->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S248->groupThreadID).x);
    if(i_18 >= ((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->count_1))
    {
        return;
    }
    Rng_0 rng_2 = makeRngForIndex_0((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->seed_1, i_18);
    int32_t steps_1 = int(0);
    float * _S249 = (&((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->output_1)[i_18]);
    float _S250 = transmittance_0(&(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->medium_0, &(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->grid_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->bounds_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->drift_0, &rng_2, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->origin_1, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->direction_0, &steps_1);
    *_S249 = _S250;
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
