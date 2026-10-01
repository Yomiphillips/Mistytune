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
    int32_t cvShapeOn_0;
    StructuredBuffer<float> cvShapeMap_0;
    Vector<int32_t, 2>  cvShapeDim_0;
    Vector<float, 2>  cvShapeOffset_0;
    float cvShapeTexel_0;
    Vector<float, 2>  cvShapeAxisU_0;
    float cvShapeRound_0;
    float cvShapeHalfWidth_0;
    float cvShapeDecay_0;
    float cvShapeBillow_0;
    float cvMoat_0;
    float cvGroupReach_0;
    int32_t cvTurretCount_0;
    Vector<float, 4>  cvTurret0_0;
    Vector<float, 4>  cvTurret1_0;
    Vector<float, 4>  cvTurret2_0;
    Vector<float, 4>  cvTurret3_0;
    Vector<float, 4>  cvTurret4_0;
    float cvMammaDepth_0;
    float cvPouchSize_0;
    float cvPileusThick_0;
    float cvPileusGap_0;
    float cvVelumThick_0;
    float cvVelumHeight_0;
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

static Vector<float, 3>  lerp_2(Vector<float, 3>  x_10, Vector<float, 3>  y_4, Vector<float, 3>  s_6)
{
    return x_10 + (y_4 - x_10) * s_6;
}

static Vector<int32_t, 2>  min_0(Vector<int32_t, 2>  x_11, Vector<int32_t, 2>  y_5)
{
    Vector<int32_t, 2>  result_3;
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
        result_3[i_6] = (I32_min((_slang_vector_get_element(x_11, i_6)), (_slang_vector_get_element(y_5, i_6))));
        i_6 = i_6 + int(1);
    }
    return result_3;
}

static Vector<float, 2>  max_0(Vector<float, 2>  x_12, Vector<float, 2>  y_6)
{
    Vector<float, 2>  result_4;
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
        result_4[i_7] = (F32_max((_slang_vector_get_element(x_12, i_7)), (_slang_vector_get_element(y_6, i_7))));
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static Vector<float, 2>  min_1(Vector<float, 2>  x_13, Vector<float, 2>  y_7)
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
        result_5[i_8] = (F32_min((_slang_vector_get_element(x_13, i_8)), (_slang_vector_get_element(y_7, i_8))));
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static Vector<float, 2>  clamp_2(Vector<float, 2>  x_14, Vector<float, 2>  minBound_2, Vector<float, 2>  maxBound_2)
{
    return min_1(max_0(x_14, minBound_2), maxBound_2);
}

static float length_0(Vector<float, 2>  x_15)
{
    return (F32_sqrt((dot_0(x_15, x_15))));
}

static Vector<float, 2>  abs_0(Vector<float, 2>  x_16)
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
        result_6[i_9] = (F32_abs((_slang_vector_get_element(x_16, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static bool all_0(Vector<bool, 2>  x_17)
{
    bool result_7 = true;
    int32_t i_10 = int(0);
    for(;;)
    {
        if(i_10 < int(2))
        {
        }
        else
        {
            break;
        }
        if(result_7)
        {
            result_7 = (bool((_slang_vector_get_element(x_17, i_10))));
        }
        else
        {
            result_7 = false;
        }
        i_10 = i_10 + int(1);
    }
    return result_7;
}

static float smoothstep_0(float min_2, float max_1, float x_18)
{
    float _S72 = saturate_0((x_18 - min_2) / (max_1 - min_2));
    return _S72 * _S72 * (3.0f - (_S72 + _S72));
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
    int32_t i_11 = int32_t((_S76->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S76->groupThreadID).x);
    if(i_11 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Rng_0 rng_0 = makeRng_0((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_11));
    float * _S77 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->output_0)[i_11]);
    float _S78 = randFloat_0(&rng_0);
    *_S77 = _S78;
    return;
}

static Rng_0 makeRngForIndex_0(uint32_t seed_3, int32_t index_0)
{
    uint32_t s_7 = uint32_t(index_0) * 747796405U + 2891336453U;
    uint32_t s_8 = ((s_7 >> ((s_7 >> 28U) + 4U)) ^ s_7) * 277803737U;
    return makeRng_0(((s_8 >> 22U) ^ s_8) ^ seed_3);
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
        lo_1 = max_0(lo_1, m_0->fadeAt_0 - (Vector<float, 2> )_S86);
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

static float convCapCeiling_0(ConvectionInput_0 * c_9)
{
    float _S101 = c_9->cvHeroTop_0;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        return 0.0f;
    }
    float _S102 = c_9->cvPileusThick_0;
    float cap_0;
    if((c_9->cvPileusThick_0) > 0.0f)
    {
        cap_0 = _S101 + c_9->cvPileusGap_0 + _S102;
    }
    else
    {
        cap_0 = 0.0f;
    }
    float _S103 = c_9->cvVelumThick_0;
    float veil_0;
    if((c_9->cvVelumThick_0) > 0.0f)
    {
        veil_0 = c_9->cvVelumHeight_0 + 1.5f * _S103;
    }
    else
    {
        veil_0 = 0.0f;
    }
    return (F32_max((cap_0), (veil_0)));
}

static float convCeiling_0(ConvectionInput_0 * c_10)
{
    float _S104 = c_10->cvBillow_0;
    float field_0 = c_10->cvDepth_0 + c_10->cvBillow_0;
    float _S105 = c_10->cvHeroTop_0;
    float hero_0;
    if((c_10->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S105 + _S104 * c_10->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    float _S106 = (F32_max((field_0), (hero_0)));
    float _S107 = convCapCeiling_0(c_10);
    return (F32_max((_S106), (_S107)));
}

static float convDomeHeight_0(float top_0, float radius_0, float shape_0, float r_3)
{
    bool _S108;
    if(top_0 <= 0.0f)
    {
        _S108 = true;
    }
    else
    {
        _S108 = r_3 >= radius_0;
    }
    if(_S108)
    {
        return 0.0f;
    }
    return top_0 * (F32_pow((1.0f - r_3 * r_3 / (radius_0 * radius_0)), (shape_0)));
}

static float convHeroHeight_0(ConvectionInput_0 * c_11, float r_4)
{
    return convDomeHeight_0(c_11->cvHeroTop_0, c_11->cvHeroRadius_0, c_11->cvShape_0, r_4);
}

static float convCapBound_0(ConvectionInput_0 * c_12, Vector<float, 3>  lo_2, Vector<float, 3>  hi_2, float low_0, float high_0)
{
    Vector<float, 2>  nearGap_0 = max_0(max_0(Vector<float, 2> {lo_2.x, lo_2.z} - c_12->cvHeroAt_0, c_12->cvHeroAt_0 - Vector<float, 2> {hi_2.x, hi_2.z}), Vector<float, 2> (0.0f, 0.0f));
    float gap2_0 = dot_0(nearGap_0, nearGap_0);
    float _S109 = c_12->cvHeroRadius_0;
    float _S110 = c_12->cvPileusThick_0;
    bool _S111;
    float best_0;
    if((c_12->cvPileusThick_0) > 0.0f)
    {
        float rp_0 = 0.60000002384185791f * _S109;
        float _S112 = c_12->cvPileusGap_0;
        float _S113 = convHeroHeight_0(c_12, rp_0 * 0.60000002384185791f);
        float _S114 = 0.5f * _S110;
        float bottom_0 = _S112 + _S113 - _S114;
        float top_1 = _S112 + c_12->cvHeroTop_0 + _S114;
        if(gap2_0 < (rp_0 * rp_0))
        {
            _S111 = high_0 >= bottom_0;
        }
        else
        {
            _S111 = false;
        }
        if(_S111)
        {
            _S111 = low_0 <= top_1;
        }
        else
        {
            _S111 = false;
        }
        if(_S111)
        {
            best_0 = (F32_max((0.0f), (0.44999998807907104f)));
        }
        else
        {
            best_0 = 0.0f;
        }
    }
    else
    {
        best_0 = 0.0f;
    }
    float _S115 = c_12->cvVelumThick_0;
    if((c_12->cvVelumThick_0) > 0.0f)
    {
        float ext_0 = 1.89999997615814209f * _S109;
        float bottom_1 = c_12->cvVelumHeight_0 - 0.5f * _S115;
        float top_2 = c_12->cvVelumHeight_0 + _S115;
        if(gap2_0 < (ext_0 * ext_0))
        {
            _S111 = high_0 >= bottom_1;
        }
        else
        {
            _S111 = false;
        }
        if(_S111)
        {
            _S111 = low_0 <= top_2;
        }
        else
        {
            _S111 = false;
        }
        if(_S111)
        {
            best_0 = (F32_max((best_0), (0.2199999988079071f)));
        }
    }
    return c_12->cvSigma_0 * best_0 * 1.00001001358032227f;
}

static float convLift_0(ConvectionInput_0 * c_13, float above_0, float k_1)
{
    return (F32_min((c_13->cvBillow_0 * k_1 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_0(0.60000002384185791f, 1.0f, saturate_0(above_0 / (F32_max((c_13->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_0), (0.0f))))));
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
    Organization_0 _S116 = flat_0;
    Vector<float, 2>  _S117 = orgPattern_0(&_S116, q0_0, spacing_2);
    Organization_0 _S118 = flat_0;
    Vector<float, 2>  _S119 = orgPattern_0(&_S118, q1_0, spacing_2);
    Vector<float, 2>  _S120 = Vector<float, 2> (q0_0.x, q1_0.y);
    Organization_0 _S121 = flat_0;
    Vector<float, 2>  _S122 = orgPattern_0(&_S121, _S120, spacing_2);
    Vector<float, 2>  _S123 = Vector<float, 2> (q1_0.x, q0_0.y);
    Organization_0 _S124 = flat_0;
    Vector<float, 2>  _S125 = orgPattern_0(&_S124, _S123, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S117.x)))), ((F32_abs((_S117.y))))))), ((F32_max(((F32_abs((_S119.x)))), ((F32_abs((_S119.y)))))))));
    *a_1 = min_1(min_1(_S117, _S122), min_1(_S125, _S119)) - (Vector<float, 2> )grow_0;
    *b_0 = max_0(max_0(_S117, _S122), max_0(_S125, _S119)) + (Vector<float, 2> )grow_0;
    return;
}

static void convSlotBound_0(ConvectionInput_0 * c_14, Vector<int32_t, 2>  slot_6, Vector<float, 2>  a_2, Vector<float, 2>  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S126 = convVigour_0(c_14, slot_6);
    if(_S126 <= 0.0f)
    {
        return;
    }
    Vector<float, 2>  _S127 = convCellCentre_0(c_14, slot_6);
    Vector<float, 2>  _S128 = a_2 - _S127;
    Vector<float, 2>  nearGap_1 = max_0(max_0(_S128, _S127 - b_1), Vector<float, 2> (0.0f, 0.0f));
    float dNear_0 = dot_0(nearGap_1, nearGap_1);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    Vector<float, 2>  farGap_0 = max_0(abs_0(_S128), abs_0(b_1 - _S127));
    float oHi_0 = _S126 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S126 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S126 * convBump_0(dot_0(farGap_0, farGap_0), 1.04999995231628418f);
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

static float convUpdraftBound_0(ConvectionInput_0 * c_15, Vector<float, 2>  q0_1, Vector<float, 2>  q1_1)
{
    Vector<float, 2>  a_3;
    Vector<float, 2>  b_2;
    orgPatternBox_0(&c_15->cvOrg_0, q0_1, q1_1, c_15->cvSpacing_0, &a_3, &b_2);
    float openTop_1 = 0.0f;
    float openNext_1 = 0.0f;
    float hiTop_1 = 0.0f;
    float loTop_1 = 0.0f;
    float loNext_1 = 0.0f;
    Vector<float, 2>  _S129 = floor_1((a_3 + b_2) * (Vector<float, 2> )0.5f);
    Vector<int32_t, 2>  _S130 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S129, 0), (int32_t)_slang_vector_get_element(_S129, 1)};
    Vector<float, 2>  _S131 = Vector<float, 2> {(float)_slang_vector_get_element(_S130, 0), (float)_slang_vector_get_element(_S130, 1)};
    Vector<float, 2>  highEdge_0 = _S131 + (Vector<float, 2> )1.0f + (Vector<float, 2> )0.00009999999747379f;
    bool _S132;
    if(all_0(a_3 >= (_S131 - (Vector<float, 2> )0.00009999999747379f)))
    {
        _S132 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S132 = false;
    }
    int32_t j_7;
    int32_t i_12;
    if(_S132)
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
            i_12 = int(-1);
            for(;;)
            {
                if(i_12 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, _S130 + Vector<int32_t, 2> (i_12, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_12 = i_12 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        Vector<float, 2>  _S133 = floor_1(a_3);
        Vector<int32_t, 2>  _S134 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S133, 0), (int32_t)_slang_vector_get_element(_S133, 1)};
        Vector<int32_t, 2>  _S135 = Vector<int32_t, 2> (int(1), int(1));
        Vector<int32_t, 2>  i0_0 = _S134 - _S135;
        Vector<float, 2>  _S136 = floor_1(b_2);
        Vector<int32_t, 2>  _S137 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S136, 0), (int32_t)_slang_vector_get_element(_S136, 1)};
        Vector<int32_t, 2>  _S138 = _S137 + _S135;
        int32_t _S139 = i0_0.y;
        j_7 = _S139;
        for(;;)
        {
            if(j_7 <= (_S138.y))
            {
                _S132 = j_7 <= (_S139 + int(32));
            }
            else
            {
                _S132 = false;
            }
            if(_S132)
            {
            }
            else
            {
                break;
            }
            int32_t _S140 = i0_0.x;
            i_12 = _S140;
            for(;;)
            {
                bool _S141;
                if(i_12 <= (_S138.x))
                {
                    _S141 = i_12 <= (_S140 + int(32));
                }
                else
                {
                    _S141 = false;
                }
                if(_S141)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, Vector<int32_t, 2> (i_12, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_12 = i_12 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_0((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_15->cvPolarity_0);
    float _S142 = c_15->cvLacunarity_0;
    float field_2;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_0(field_1, 0.40000000596046448f, _S142);
    }
    else
    {
        field_2 = field_1;
    }
    return field_2 + 0.00000999999974738f;
}

static float convTowerHeight_0(ConvectionInput_0 * c_16, float w_1)
{
    float cover_0 = clamp_0(c_16->cvCoverage_0, 0.0f, 1.0f);
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
    return c_16->cvDepth_0 * (F32_pow((u_2), (c_16->cvShape_0)));
}

static float convNeededUpdraft_0(ConvectionInput_0 * c_17, float above_1)
{
    float cover_1 = clamp_0(c_17->cvCoverage_0, 0.0f, 1.0f);
    bool _S143;
    if(cover_1 <= 0.0f)
    {
        _S143 = true;
    }
    else
    {
        _S143 = (c_17->cvDepth_0) <= 0.0f;
    }
    if(_S143)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_17->cvDepth_0), (1.0f / (F32_max((c_17->cvShape_0), (0.00100000004749745f))))));
}

static float convSlopeCap_0(ConvectionInput_0 * c_18)
{
    float _S144 = c_18->cvSpacing_0;
    float cap_1 = 7.0f / c_18->cvSpacing_0;
    if(((&c_18->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_1;
    }
    float _S145 = c_18->cvLacunarity_0;
    float cap_2;
    if((c_18->cvLacunarity_0) > 0.0f)
    {
        cap_2 = cap_1 + 1.5f / (0.15000000596046448f * _S145 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S144);
    }
    else
    {
        cap_2 = cap_1;
    }
    float _S146 = c_18->cvGapWidth_0;
    if((c_18->cvGapWidth_0) > 0.0f)
    {
        cap_2 = cap_2 + 14.25f * c_18->cvPolarity_0 / (0.5f * _S146 * _S144);
    }
    return cap_2 + 3.0f * (&c_18->cvOrg_0)->ogWaveAmp_0 * length_0((&c_18->cvOrg_0)->ogWaveK_0);
}

static Vector<float, 4>  convTurret_0(ConvectionInput_0 * c_19, int32_t k_2)
{
    if(k_2 == int(0))
    {
        return c_19->cvTurret0_0;
    }
    if(k_2 == int(1))
    {
        return c_19->cvTurret1_0;
    }
    if(k_2 == int(2))
    {
        return c_19->cvTurret2_0;
    }
    if(k_2 == int(3))
    {
        return c_19->cvTurret3_0;
    }
    return c_19->cvTurret4_0;
}

static float convMoatSlopeOver_0(ConvectionInput_0 * c_20, Vector<float, 2>  lo_3, Vector<float, 2>  hi_3)
{
    float slope_0 = 0.0f;
    int32_t k_3 = int(-1);
    for(;;)
    {
        if(k_3 < int(5))
        {
        }
        else
        {
            break;
        }
        if(k_3 >= (c_20->cvTurretCount_0))
        {
            break;
        }
        Vector<float, 4>  t_4;
        if(k_3 < int(0))
        {
            t_4 = Vector<float, 4> (c_20->cvHeroAt_0.x, c_20->cvHeroAt_0.y, c_20->cvHeroRadius_0, c_20->cvHeroTop_0);
        }
        else
        {
            Vector<float, 4>  _S147 = convTurret_0(c_20, k_3);
            t_4 = _S147;
        }
        Vector<float, 4>  _S148 = t_4;
        Vector<float, 2>  _S149 = Vector<float, 2> {_S148.x, _S148.y};
        Vector<float, 2>  gap_0 = max_0(max_0(lo_3 - _S149, _S149 - hi_3), Vector<float, 2> (0.0f, 0.0f));
        float _S150 = t_4.z;
        float outer_0 = 1.29999995231628418f * _S150;
        float band_1 = outer_0 - 0.75f * _S150;
        if((dot_0(gap_0, gap_0)) < (outer_0 * outer_0))
        {
            slope_0 = (F32_max((slope_0), (1.5f / band_1)));
        }
        k_3 = k_3 + int(1);
    }
    return slope_0 * c_20->cvMoat_0;
}

static float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S151;
    if(vMin_0 <= 0.0f)
    {
        _S151 = true;
    }
    else
    {
        _S151 = hMin_0 <= 0.0f;
    }
    if(_S151)
    {
        return 0.0f;
    }
    return 1.0f / (F32_sqrt((1.0f / (vMin_0 * vMin_0) + 1.0f / (hMin_0 * hMin_0))));
}

static float convHeroReach_0(ConvectionInput_0 * c_21)
{
    return c_21->cvHeroRadius_0 + 1.5f * c_21->cvBillow_0 * c_21->cvHeroBillow_0 + 24.0f;
}

static float convShapeReach_0(ConvectionInput_0 * c_22)
{
    float lift_0 = 1.5f * c_22->cvBillow_0 * c_22->cvHeroBillow_0 + 24.0f;
    return length_0(Vector<float, 2> (c_22->cvShapeHalfWidth_0 + lift_0, c_22->cvShapeRound_0 + lift_0));
}

static float convHeroReachAll_0(ConvectionInput_0 * c_23)
{
    float _S152 = convHeroReach_0(c_23);
    float _S153;
    if((c_23->cvShapeOn_0) != int(0))
    {
        float _S154 = convShapeReach_0(c_23);
        _S153 = (F32_max((_S152), (_S154)));
    }
    else
    {
        _S153 = _S152;
    }
    return _S153;
}

static float convDomeRadiusAt_0(float top_3, float radius_1, float shape_1, float above_2)
{
    bool _S155;
    if(top_3 <= 0.0f)
    {
        _S155 = true;
    }
    else
    {
        _S155 = above_2 >= top_3;
    }
    if(_S155)
    {
        return -1.0f;
    }
    return radius_1 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / top_3), (1.0f / (F32_max((shape_1), (0.00100000004749745f))))))), (0.0f))))));
}

static float convHeroRadiusAt_0(ConvectionInput_0 * c_24, float above_3)
{
    return convDomeRadiusAt_0(c_24->cvHeroTop_0, c_24->cvHeroRadius_0, c_24->cvShape_0, above_3);
}

static Vector<float, 3>  convShapeTexel_0(ConvectionInput_0 * c_25, int32_t i_13, int32_t j_8)
{
    int32_t k_4 = (j_8 * c_25->cvShapeDim_0.x + i_13) * int(4);
    return Vector<float, 3> (c_25->cvShapeMap_0.Load(k_4), c_25->cvShapeMap_0.Load(k_4 + int(1)), c_25->cvShapeMap_0.Load(k_4 + int(2)));
}

static float convShapeDistance_0(ConvectionInput_0 * c_26, float u_3, float y_8, Vector<float, 2>  * slopeUY_0)
{
    float _S156 = c_26->cvShapeTexel_0;
    Vector<float, 2>  st_0 = Vector<float, 2> (u_3, y_8) / (Vector<float, 2> )c_26->cvShapeTexel_0 + c_26->cvShapeOffset_0 - (Vector<float, 2> )0.5f;
    Vector<int32_t, 2>  _S157 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  last_0 = c_26->cvShapeDim_0 - _S157;
    Vector<float, 2>  _S158 = Vector<float, 2> {(float)_slang_vector_get_element(last_0, 0), (float)_slang_vector_get_element(last_0, 1)};
    Vector<float, 2>  q_6 = clamp_2(st_0, Vector<float, 2> (0.0f, 0.0f), _S158);
    float past_0 = length_0(st_0 - q_6);
    Vector<float, 2>  f0_0 = floor_1(q_6);
    Vector<int32_t, 2>  _S159 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(f0_0, 0), (int32_t)_slang_vector_get_element(f0_0, 1)};
    Vector<int32_t, 2>  i0_1 = min_0(_S159, last_0);
    Vector<int32_t, 2>  i1_0 = min_0(i0_1 + _S157, last_0);
    Vector<float, 2>  fr_0 = q_6 - f0_0;
    int32_t _S160 = i0_1.x;
    int32_t _S161 = i0_1.y;
    Vector<float, 3>  _S162 = convShapeTexel_0(c_26, _S160, _S161);
    int32_t _S163 = i1_0.x;
    Vector<float, 3>  _S164 = convShapeTexel_0(c_26, _S163, _S161);
    int32_t _S165 = i1_0.y;
    Vector<float, 3>  _S166 = convShapeTexel_0(c_26, _S160, _S165);
    Vector<float, 3>  _S167 = convShapeTexel_0(c_26, _S163, _S165);
    Vector<float, 3>  _S168 = (Vector<float, 3> )fr_0.x;
    Vector<float, 3>  blend_0 = lerp_2(lerp_2(_S162, _S164, _S168), lerp_2(_S166, _S167, _S168), (Vector<float, 3> )fr_0.y);
    *slopeUY_0 = Vector<float, 2> {blend_0.y, blend_0.z};
    return (blend_0.x - past_0) * _S156;
}

static float convShapeProfile_0(float dIn_0, float m_1, float rimR_0, Vector<float, 2>  * stepDM_0)
{
    if(dIn_0 >= rimR_0)
    {
        *stepDM_0 = Vector<float, 2> (0.0f, rimR_0 - m_1);
        return m_1 - rimR_0;
    }
    Vector<float, 2>  w_2 = Vector<float, 2> (dIn_0 - rimR_0, m_1);
    float len_0 = length_0(w_2);
    float gap_1 = len_0 - rimR_0;
    Vector<float, 2>  _S169;
    if(len_0 > 9.99999997475242708e-07f)
    {
        _S169 = w_2 * (Vector<float, 2> )(- gap_1 / len_0);
    }
    else
    {
        _S169 = Vector<float, 2> (0.0f, rimR_0);
    }
    *stepDM_0 = _S169;
    return gap_1;
}

static float convShapeBound_0(ConvectionInput_0 * c_27, Vector<float, 3>  lo_4, Vector<float, 3>  hi_4, float low_1, float high_1)
{
    Vector<float, 2>  ea_0 = Vector<float, 2> {lo_4.x, lo_4.z} - c_27->cvHeroAt_0;
    Vector<float, 2>  eb_0 = Vector<float, 2> {hi_4.x, hi_4.z} - c_27->cvHeroAt_0;
    float _S170 = c_27->cvShapeAxisU_0.y;
    float _S171 = - _S170;
    float _S172 = c_27->cvShapeAxisU_0.x;
    float _S173 = ea_0.x;
    float _S174 = _S173 * _S172;
    float _S175 = eb_0.x;
    float _S176 = _S175 * _S172;
    float _S177 = ea_0.y;
    float _S178 = _S177 * _S170;
    float _S179 = eb_0.y;
    float _S180 = _S179 * _S170;
    float uLo_0 = (F32_min((_S174), (_S176))) + (F32_min((_S178), (_S180)));
    float uHi_0 = (F32_max((_S174), (_S176))) + (F32_max((_S178), (_S180)));
    float _S181 = _S173 * _S171;
    float _S182 = _S175 * _S171;
    float _S183 = _S177 * _S172;
    float _S184 = _S179 * _S172;
    float nLo_0 = (F32_min((_S181), (_S182))) + (F32_min((_S183), (_S184)));
    float nHi_0 = (F32_max((_S181), (_S182))) + (F32_max((_S183), (_S184)));
    bool _S185;
    if(nLo_0 <= 0.0f)
    {
        _S185 = nHi_0 >= 0.0f;
    }
    else
    {
        _S185 = false;
    }
    float mMin_0;
    if(_S185)
    {
        mMin_0 = 0.0f;
    }
    else
    {
        mMin_0 = (F32_min(((F32_abs((nLo_0)))), ((F32_abs((nHi_0))))));
    }
    Vector<float, 2>  halfSpan_0 = Vector<float, 2> (0.5f * (uHi_0 - uLo_0), 0.5f * (high_1 - low_1));
    Vector<float, 2>  slopeUnused_0;
    float _S186 = convShapeDistance_0(c_27, 0.5f * (uLo_0 + uHi_0), 0.5f * (low_1 + high_1), &slopeUnused_0);
    Vector<float, 2>  stepUnused_0;
    return - convShapeProfile_0(_S186 + 2.5f * length_0(halfSpan_0), mMin_0, c_27->cvShapeRound_0, &stepUnused_0);
}

static float convTurretReach_0(ConvectionInput_0 * c_28, Vector<float, 4>  t_5)
{
    return t_5.z + 1.5f * c_28->cvBillow_0 * c_28->cvHeroBillow_0 + 24.0f;
}

static float convTurretBillow_0(ConvectionInput_0 * c_29, float radius_2)
{
    return lerp_0((F32_min((1.0f), (c_29->cvHeroBillow_0))), c_29->cvHeroBillow_0, saturate_0(radius_2 / (F32_max((c_29->cvHeroRadius_0), (1.0f)))));
}

static bool convTurretBound_0(ConvectionInput_0 * c_30, Vector<float, 4>  t_6, Vector<float, 3>  lo_5, Vector<float, 3>  hi_5, float low_2, float high_2, float * dPart_0, float * lift_1)
{
    *dPart_0 = -1.00000001504746622e+30f;
    *lift_1 = 0.0f;
    Vector<float, 2>  _S187 = Vector<float, 2> {t_6.x, t_6.y};
    Vector<float, 2>  nearGap_2 = max_0(max_0(Vector<float, 2> {lo_5.x, lo_5.z} - _S187, _S187 - Vector<float, 2> {hi_5.x, hi_5.z}), Vector<float, 2> (0.0f, 0.0f));
    float gap2_1 = dot_0(nearGap_2, nearGap_2);
    float _S188 = convTurretReach_0(c_30, t_6);
    if(gap2_1 >= (_S188 * _S188))
    {
        return false;
    }
    float rMin_0 = (F32_sqrt((gap2_1)));
    float _S189 = t_6.w;
    float _S190 = t_6.z;
    float tower_0 = convDomeHeight_0(_S189, _S190, c_30->cvShape_0, rMin_0);
    float ra_0 = convDomeRadiusAt_0(_S189, _S190, c_30->cvShape_0, low_2);
    float _S191 = convTurretBillow_0(c_30, _S190);
    float _S192 = convLift_0(c_30, high_2, _S191);
    *lift_1 = _S192;
    bool _S193 = ra_0 < 0.0f;
    bool _S194;
    if(_S193)
    {
        _S194 = true;
    }
    else
    {
        _S194 = rMin_0 >= ra_0;
    }
    if(_S194)
    {
        float hMin_1;
        if(_S193)
        {
            hMin_1 = 1.00000001504746622e+30f;
        }
        else
        {
            hMin_1 = rMin_0 - ra_0;
        }
        *dPart_0 = - convDistanceFloor_0(low_2 - tower_0, hMin_1);
    }
    else
    {
        *dPart_0 = (F32_max((tower_0 - low_2), (0.0f)));
    }
    return true;
}

static float convectionBound_0(ConvectionInput_0 * c_31, Vector<float, 3>  lo_6, Vector<float, 3>  hi_6)
{
    float low_3 = lo_6.y - c_31->cvBase_0;
    float high_3 = hi_6.y - c_31->cvBase_0;
    float _S195 = convCeiling_0(c_31);
    float _S196 = c_31->cvMammaDepth_0;
    bool pouches_0;
    if(high_3 < (- c_31->cvMammaDepth_0))
    {
        pouches_0 = true;
    }
    else
    {
        pouches_0 = low_3 > _S195;
    }
    if(pouches_0)
    {
        return 0.0f;
    }
    if(_S196 > 0.0f)
    {
        pouches_0 = low_3 < 40.0f;
    }
    else
    {
        pouches_0 = false;
    }
    float _S197 = (F32_max((low_3), (0.0f)));
    float _S198 = (F32_min(((F32_max((high_3), (0.0f)))), (_S195)));
    bool _S199 = (c_31->cvHeroTop_0) > 0.0f;
    bool _S200;
    if(_S199)
    {
        if((c_31->cvPileusThick_0) > 0.0f)
        {
            _S200 = true;
        }
        else
        {
            _S200 = (c_31->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        _S200 = false;
    }
    float capBound_0;
    if(_S200)
    {
        float _S201 = convCapBound_0(c_31, lo_6, hi_6, _S197, _S198);
        capBound_0 = _S201;
    }
    else
    {
        capBound_0 = 0.0f;
    }
    float _S202 = convLift_0(c_31, _S198, 1.0f);
    float inside_0;
    if((c_31->cvHeroAlone_0) == int(0))
    {
        Vector<float, 2>  _S203 = Vector<float, 2> {lo_6.x, lo_6.z};
        Vector<float, 2>  _S204 = Vector<float, 2> {hi_6.x, hi_6.z};
        float _S205 = convUpdraftBound_0(c_31, _S203 - c_31->cvDrift_0, _S204 - c_31->cvDrift_0);
        float _S206 = convTowerHeight_0(c_31, _S205);
        float _S207 = convNeededUpdraft_0(c_31, _S197);
        if(_S205 < _S207)
        {
            float _S208 = convSlopeCap_0(c_31);
            if((c_31->cvMoat_0) > 0.0f)
            {
                float _S209 = convMoatSlopeOver_0(c_31, _S203, _S204);
                inside_0 = _S208 + _S209;
            }
            else
            {
                inside_0 = _S208;
            }
            inside_0 = _S202 - convDistanceFloor_0(_S197 - _S206, (_S207 - _S205) / inside_0);
        }
        else
        {
            inside_0 = (F32_max((_S206 - _S197), (0.0f))) + _S202;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    float edge_0;
    if(_S199)
    {
        float rMin_1 = length_0(max_0(max_0(Vector<float, 2> {lo_6.x, lo_6.z} - c_31->cvHeroAt_0, c_31->cvHeroAt_0 - Vector<float, 2> {hi_6.x, hi_6.z}), Vector<float, 2> (0.0f, 0.0f)));
        float _S210 = convHeroReachAll_0(c_31);
        float groupD_0;
        float groupLift_0;
        if(rMin_1 < _S210)
        {
            float _S211 = convHeroHeight_0(c_31, rMin_1);
            float _S212 = convHeroRadiusAt_0(c_31, _S197);
            float _S213 = c_31->cvHeroBillow_0;
            float _S214 = convLift_0(c_31, _S198, c_31->cvHeroBillow_0);
            bool _S215 = _S212 < 0.0f;
            if(_S215)
            {
                _S200 = true;
            }
            else
            {
                _S200 = rMin_1 >= _S212;
            }
            if(_S200)
            {
                if(_S215)
                {
                    edge_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    edge_0 = rMin_1 - _S212;
                }
                edge_0 = - convDistanceFloor_0(_S197 - _S211, edge_0);
            }
            else
            {
                edge_0 = (F32_max((_S211 - _S197), (0.0f)));
            }
            if((c_31->cvShapeOn_0) != int(0))
            {
                _S200 = (c_31->cvShapeDecay_0) < 1.0f;
            }
            else
            {
                _S200 = false;
            }
            if(_S200)
            {
                float _S216 = convShapeBound_0(c_31, lo_6, hi_6, _S197, _S198);
                float _S217 = lerp_0(_S216, edge_0, c_31->cvShapeDecay_0);
                float _S218 = convLift_0(c_31, _S198, _S213 * lerp_0(c_31->cvShapeBillow_0, 1.0f, c_31->cvShapeDecay_0));
                groupD_0 = _S217;
                groupLift_0 = _S218;
            }
            else
            {
                groupD_0 = edge_0;
                groupLift_0 = _S214;
            }
        }
        else
        {
            groupD_0 = -1.00000001504746622e+30f;
            groupLift_0 = 0.0f;
        }
        int32_t k_5 = int(0);
        for(;;)
        {
            if(k_5 < int(5))
            {
            }
            else
            {
                break;
            }
            if(k_5 >= (c_31->cvTurretCount_0))
            {
                break;
            }
            Vector<float, 4>  _S219 = convTurret_0(c_31, k_5);
            float turretD_0;
            float turretLift_0;
            bool _S220 = convTurretBound_0(c_31, _S219, lo_6, hi_6, _S197, _S198, &turretD_0, &turretLift_0);
            if(_S220)
            {
                float _S221 = (F32_max((groupLift_0), (turretLift_0)));
                groupD_0 = (F32_max((groupD_0), (turretD_0)));
                groupLift_0 = _S221;
            }
            k_5 = k_5 + int(1);
        }
        if(groupD_0 > -1.00000001504746622e+29f)
        {
            inside_0 = (F32_max((inside_0), (groupD_0 + groupLift_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return capBound_0;
    }
    if(pouches_0)
    {
        edge_0 = 1.0f;
    }
    else
    {
        edge_0 = smoothstep_0(0.0f, 12.0f, inside_1);
    }
    if(pouches_0)
    {
        inside_0 = _S198 + _S196;
    }
    else
    {
        inside_0 = _S198;
    }
    return (F32_max((c_31->cvSigma_0 * (F32_sqrt((saturate_0(inside_0 / 40.0f)))) * edge_0 * 1.00001001358032227f), (capBound_0)));
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_19 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_14 = clamp_1(int32_t((F32_floor((x_19)))), int(0), int(31));
    return lerp_1(disp_0.Load(i_14), disp_0.Load(i_14 + int(1)), (Vector<float, 2> )(x_19 - float(i_14)));
}

static void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<Vector<float, 2> > disp_1, float d0_0, float d1_0, Vector<float, 2>  * lo_7, Vector<float, 2>  * hi_7)
{
    Vector<float, 2>  _S222 = driftAt_0(g_5, disp_1, d0_0);
    *lo_7 = _S222;
    *hi_7 = _S222;
    Vector<float, 2>  _S223 = driftAt_0(g_5, disp_1, d1_0);
    *lo_7 = min_1(*lo_7, _S223);
    *hi_7 = max_0(*hi_7, _S223);
    int32_t _S224 = clamp_1(int32_t((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int32_t k_6 = clamp_1(int32_t((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_6 <= _S224)
        {
        }
        else
        {
            break;
        }
        *lo_7 = min_1(*lo_7, disp_1.Load(k_6));
        *hi_7 = max_0(*hi_7, disp_1.Load(k_6));
        k_6 = k_6 + int(1);
    }
    return;
}

static float cellFieldBound_0(GeneratorInput_0 * g_6, Vector<float, 2>  q0_2, Vector<float, 2>  q1_2)
{
    Vector<float, 2>  a_4;
    Vector<float, 2>  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    Vector<float, 2>  _S225 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    Vector<float, 2>  _S226 = floor_1(a_4);
    Vector<int32_t, 2>  _S227 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S226, 0), (int32_t)_slang_vector_get_element(_S226, 1)};
    Vector<int32_t, 2>  _S228 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  i0_2 = _S227 - _S228;
    Vector<float, 2>  _S229 = floor_1(b_3);
    Vector<int32_t, 2>  _S230 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S229, 0), (int32_t)_slang_vector_get_element(_S229, 1)};
    Vector<int32_t, 2>  _S231 = _S230 + _S228;
    int32_t _S232 = i0_2.y;
    int32_t j_9 = _S232;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S233;
        if(j_9 <= (_S231.y))
        {
            _S233 = j_9 <= (_S232 + int(32));
        }
        else
        {
            _S233 = false;
        }
        if(_S233)
        {
        }
        else
        {
            break;
        }
        int32_t _S234 = i0_2.x;
        int32_t i_15 = _S234;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S235;
            if(i_15 <= (_S231.x))
            {
                _S235 = i_15 <= (_S234 + int(32));
            }
            else
            {
                _S235 = false;
            }
            if(_S235)
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_7 = Vector<int32_t, 2> (i_15, j_9);
            if((hash22_0(o_7, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_15 = i_15 + int(1);
                continue;
            }
            Vector<float, 2>  _S236 = Vector<float, 2> {(float)_slang_vector_get_element(o_7, 0), (float)_slang_vector_get_element(o_7, 1)};
            Vector<float, 2>  c_32 = _S236 + (Vector<float, 2> )0.5f + (hash22_0(o_7, 0U) - (Vector<float, 2> )0.5f) * _S225;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(max_0(max_0(a_4 - c_32, c_32 - b_3), Vector<float, 2> (0.0f, 0.0f))) * 2.20000004768371582f);
            i_15 = i_15 + int(1);
        }
        j_9 = j_9 + int(1);
        acc_0 = acc_1;
    }
    return acc_0 * g_6->cellStrength_0;
}

static float iceDensityBound_0(GeneratorInput_0 * g_7, StructuredBuffer<Vector<float, 2> > disp_2, Vector<float, 3>  lo_8, Vector<float, 3>  hi_8)
{
    float d0_1 = g_7->cellAltitude_0 - hi_8.y;
    float d1_1 = g_7->cellAltitude_0 - lo_8.y;
    bool _S237;
    if(d1_1 < 0.0f)
    {
        _S237 = true;
    }
    else
    {
        _S237 = d0_1 > (g_7->streakLength_0);
    }
    if(_S237)
    {
        return 0.0f;
    }
    float _S238 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    Vector<float, 2>  driftLo_0;
    Vector<float, 2>  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S239 = cellFieldBound_0(g_7, Vector<float, 2> (lo_8.x, lo_8.z) - driftHi_0, Vector<float, 2> (hi_8.x, hi_8.z) - driftLo_0);
    return (F32_max((_S239 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S238), (1.0f)));
}

static float mediumBound_0(Medium_0 * m_2, StructuredBuffer<Vector<float, 2> > disp_3, Vector<float, 3>  lo_9, Vector<float, 3>  hi_9)
{
    int32_t _S240 = m_2->mode_0;
    if((m_2->mode_0) == int(3))
    {
        float _S241 = convectionBound_0(&m_2->conv_0, lo_9, hi_9);
        return _S241;
    }
    if(_S240 == int(2))
    {
        float _S242 = iceDensityBound_0(&m_2->gen_0, disp_3, lo_9, hi_9);
        return _S242;
    }
    return m_2->majorant_0;
}

static float gridBound_0(Medium_0 * m_3, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_1, StructuredBuffer<Vector<float, 2> > disp_4, Vector<int32_t, 3>  c_33, float fallback_0)
{
    int32_t _S243 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S243 == int(2))
    {
        Vector<float, 3>  _S244 = Vector<float, 3> {(float)_slang_vector_get_element(c_33, 0), (float)_slang_vector_get_element(c_33, 1), (float)_slang_vector_get_element(c_33, 2)};
        Vector<float, 3>  lo_10 = g_8->origin_0 + _S244 * g_8->cellExtent_0;
        float _S245 = mediumBound_0(m_3, disp_4, lo_10, lo_10 + g_8->cellExtent_0);
        return _S245;
    }
    int32_t _S246 = c_33.x;
    bool _S247;
    if(_S246 < int(0))
    {
        _S247 = true;
    }
    else
    {
        _S247 = (c_33.y) < int(0);
    }
    if(_S247)
    {
        _S247 = true;
    }
    else
    {
        _S247 = (c_33.z) < int(0);
    }
    if(_S247)
    {
        _S247 = true;
    }
    else
    {
        _S247 = _S246 >= (g_8->dims_0.x);
    }
    if(_S247)
    {
        _S247 = true;
    }
    else
    {
        _S247 = (c_33.y) >= (g_8->dims_0.y);
    }
    if(_S247)
    {
        _S247 = true;
    }
    else
    {
        _S247 = (c_33.z) >= (g_8->dims_0.z);
    }
    if(_S247)
    {
        return fallback_0;
    }
    return bounds_1.Load((c_33.z * g_8->dims_0.y + c_33.y) * g_8->dims_0.x + _S246);
}

static float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S248;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S248 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S248 = false;
    }
    if(_S248)
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

static float orgWaveFactor_0(Organization_0 * o_8, Vector<float, 2>  q_7)
{
    Vector<float, 2>  unused_0;
    float _S249 = orgWave_0(o_8, q_7, &unused_0);
    return _S249;
}

static float cellField_0(GeneratorInput_0 * g_9, Vector<float, 2>  q_8)
{
    Vector<float, 2>  _S250 = q_8 - g_9->cellDrift_0;
    Vector<float, 2>  _S251 = orgPattern_0(&g_9->gnOrg_0, _S250, g_9->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_1(_S251);
    Vector<int32_t, 2>  _S252 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
    Vector<float, 2>  _S253 = orgJitter_0(&g_9->gnOrg_0, 0.80000001192092896f);
    int32_t j_10 = int(-1);
    float acc_2 = 0.0f;
    for(;;)
    {
        if(j_10 <= int(1))
        {
        }
        else
        {
            break;
        }
        int32_t i_16 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_16 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_9 = _S252 + Vector<int32_t, 2> (i_16, j_10);
            if((hash22_0(o_9, 2654435769U).x) > (g_9->cellDensity_0))
            {
                i_16 = i_16 + int(1);
                continue;
            }
            Vector<float, 2>  _S254 = Vector<float, 2> {(float)_slang_vector_get_element(o_9, 0), (float)_slang_vector_get_element(o_9, 1)};
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_0(_S251 - (_S254 + (Vector<float, 2> )0.5f + (hash22_0(o_9, 0U) - (Vector<float, 2> )0.5f) * _S253)) * 2.20000004768371582f);
            i_16 = i_16 + int(1);
        }
        j_10 = j_10 + int(1);
        acc_2 = acc_3;
    }
    float _S255 = acc_2 * g_9->cellStrength_0;
    float _S256 = orgWaveFactor_0(&g_9->gnOrg_0, _S250);
    return _S255 * _S256;
}

static float fbm_0(Vector<float, 3>  p_2, int32_t octaves_1)
{
    int32_t i_17 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S257 = p_2;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_17 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_17 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S257);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S258 = _S257 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_17 = i_17 + int(1);
        amp_0 = amp_1;
        _S257 = _S258;
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
    bool _S259;
    if(depth_1 < 0.0f)
    {
        _S259 = true;
    }
    else
    {
        _S259 = depth_1 > (g_10->streakLength_0);
    }
    if(_S259)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S260 = Vector<float, 2> {p_3.x, p_3.z};
    Vector<float, 2>  _S261 = driftAt_0(g_10, disp_5, depth_1);
    Vector<float, 2>  source_0 = _S260 - _S261;
    float _S262 = cellField_0(g_10, source_0);
    if(_S262 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S262 * (F32_exp((- g_10->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_10->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_10->streakLength_0, g_10->streakLength_0, depth_1)) * (F32_max((1.0f + g_10->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_10->detailScale_0).x, (source_0 / (Vector<float, 2> )g_10->detailScale_0).y, depth_1 / (F32_max((g_10->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_10->timeSeconds_0 * 0.00999999977648258f), g_10->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_10->opticalDepth_0 / (F32_max((g_10->streakLength_0), (1.0f)));
}

static float convPouches_0(ConvectionInput_0 * c_34, Vector<float, 2>  q_9)
{
    Vector<float, 2>  g_11 = q_9 / (Vector<float, 2> )c_34->cvPouchSize_0;
    Vector<float, 2>  _S263 = floor_1(g_11);
    Vector<int32_t, 2>  _S264 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S263, 0), (int32_t)_slang_vector_get_element(_S263, 1)};
    float deepest_0 = 0.0f;
    int32_t j_11 = int(-1);
    for(;;)
    {
        if(j_11 <= int(1))
        {
        }
        else
        {
            break;
        }
        float deepest_1 = deepest_0;
        int32_t i_18 = int(-1);
        for(;;)
        {
            if(i_18 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_7 = _S264 + Vector<int32_t, 2> (i_18, j_11);
            Vector<float, 2>  _S265 = Vector<float, 2> {(float)_slang_vector_get_element(slot_7, 0), (float)_slang_vector_get_element(slot_7, 1)};
            Vector<float, 2>  d_8 = g_11 - (_S265 + (Vector<float, 2> )0.5f + (hash22_0(slot_7, 739982445U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.60000002384185791f);
            float t2_0 = dot_0(d_8, d_8) / 0.46240001916885376f;
            if(t2_0 >= 1.0f)
            {
                i_18 = i_18 + int(1);
                continue;
            }
            Vector<float, 2>  h_3 = hash22_0(slot_7, 2135587861U);
            deepest_1 = (F32_max((deepest_1), (lerp_0(0.30000001192092896f, 1.0f, convLife_0((F32_frac((2.0f * c_34->cvAge_0 + h_3.x))))) * lerp_0(0.60000002384185791f, 1.0f, h_3.y) * (F32_sqrt((1.0f - t2_0))))));
            i_18 = i_18 + int(1);
        }
        int32_t j_12 = j_11 + int(1);
        deepest_0 = deepest_1;
        j_11 = j_12;
    }
    return deepest_0;
}

static void convMoatRing_0(Vector<float, 2>  xz_0, Vector<float, 2>  at_0, float radius_3, float * s_9, Vector<float, 2>  * gs_0, float * slope_1)
{
    Vector<float, 2>  d_9 = xz_0 - at_0;
    float r2_1 = dot_0(d_9, d_9);
    float outer_1 = 1.29999995231628418f * radius_3;
    if(!(r2_1 < (outer_1 * outer_1)))
    {
        return;
    }
    float band_2 = outer_1 - 0.75f * radius_3;
    float inner_1 = outer_1 - band_2;
    *slope_1 = (F32_max((*slope_1), (1.5f / band_2)));
    float r_5 = (F32_sqrt((r2_1)));
    float t_7 = saturate_0((r_5 - inner_1) / band_2);
    float f_1 = t_7 * t_7 * (3.0f - 2.0f * t_7);
    if(f_1 < (*s_9))
    {
        *s_9 = f_1;
        Vector<float, 2>  _S266;
        if(r_5 > 0.00100000004749745f)
        {
            _S266 = d_9 * (Vector<float, 2> )(6.0f * t_7 * (1.0f - t_7) / (band_2 * r_5));
        }
        else
        {
            _S266 = Vector<float, 2> (0.0f, 0.0f);
        }
        *gs_0 = _S266;
    }
    return;
}

static float convMoat_0(ConvectionInput_0 * c_35, Vector<float, 2>  xz_1, Vector<float, 2>  * grad_5, float * slopeAdd_0)
{
    float s_10 = 1.0f;
    Vector<float, 2>  gs_1 = Vector<float, 2> (0.0f, 0.0f);
    float slope_2 = 0.0f;
    convMoatRing_0(xz_1, c_35->cvHeroAt_0, c_35->cvHeroRadius_0, &s_10, &gs_1, &slope_2);
    int32_t k_7 = int(0);
    for(;;)
    {
        if(k_7 < int(5))
        {
        }
        else
        {
            break;
        }
        if(k_7 >= (c_35->cvTurretCount_0))
        {
            break;
        }
        Vector<float, 4>  _S267 = convTurret_0(c_35, k_7);
        convMoatRing_0(xz_1, Vector<float, 2> {_S267.x, _S267.y}, _S267.z, &s_10, &gs_1, &slope_2);
        k_7 = k_7 + int(1);
    }
    float _S268 = c_35->cvMoat_0;
    *grad_5 = gs_1 * (Vector<float, 2> )c_35->cvMoat_0;
    *slopeAdd_0 = slope_2 * _S268;
    return 1.0f - _S268 * (1.0f - s_10);
}

static float convUpdraftGrad_0(ConvectionInput_0 * c_36, Vector<float, 2>  q_10, Vector<float, 2>  * grad_6)
{
    if(((&c_36->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S269 = convUpdraftGradT_2(c_36, q_10, grad_6);
        return _S269;
    }
    if((c_36->cvLacunarity_0) <= 0.0f)
    {
        float _S270 = convUpdraftGradT_1(c_36, q_10, grad_6);
        return _S270;
    }
    float _S271 = convUpdraftGradT_0(c_36, q_10, grad_6);
    return _S271;
}

static float convSurfaceDistance_0(float v_2, float delta_0, float slope_3)
{
    float num_0 = (F32_abs((v_2 * delta_0)));
    float den_0 = (F32_sqrt((v_2 * v_2 * slope_3 * slope_3 + delta_0 * delta_0)));
    if(den_0 <= 9.99999968265522539e-21f)
    {
        return 0.0f;
    }
    float d_10 = num_0 / den_0;
    float _S272;
    if(v_2 >= 0.0f)
    {
        _S272 = d_10;
    }
    else
    {
        _S272 = - d_10;
    }
    return _S272;
}

static float convFieldBaseInside_0(ConvectionInput_0 * c_37, float w_3, Vector<float, 2>  slope_4, float cap_3)
{
    float _S273 = convTowerHeight_0(c_37, w_3);
    float v_3 = _S273 - 1.0f;
    float _S274 = convNeededUpdraft_0(c_37, 1.0f);
    return convSurfaceDistance_0(v_3, w_3 - _S274, (F32_min((length_0(slope_4)), (cap_3))));
}

static float convDomeSurface_0(float top_4, float radius_4, float shape_2, Vector<float, 2>  rel_0, float r_6, float py_0, float above_4, Vector<float, 3>  * x_20)
{
    float v_4 = convDomeHeight_0(top_4, radius_4, shape_2, r_6) - above_4;
    float ra_1 = convDomeRadiusAt_0(top_4, radius_4, shape_2, above_4);
    float shiftOut_0;
    float shiftUp_0;
    float d_11;
    if(ra_1 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_4;
        d_11 = v_4;
    }
    else
    {
        float h_4 = ra_1 - r_6;
        float d_12 = convSurfaceDistance_0(v_4, h_4, 1.0f);
        if((F32_abs((v_4))) > 9.99999997475242708e-07f)
        {
            shiftOut_0 = d_12 * (d_12 / v_4);
        }
        else
        {
            shiftOut_0 = 0.0f;
        }
        if((F32_abs((h_4))) > 9.99999997475242708e-07f)
        {
            shiftUp_0 = d_12 * (d_12 / h_4);
        }
        else
        {
            shiftUp_0 = 0.0f;
        }
        float _S275 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S275;
        d_11 = d_12;
    }
    Vector<float, 2>  radial_0;
    if(r_6 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / (Vector<float, 2> )r_6;
    }
    else
    {
        radial_0 = Vector<float, 2> (0.0f, 0.0f);
    }
    Vector<float, 2>  at_1 = rel_0 + radial_0 * (Vector<float, 2> )shiftOut_0;
    *x_20 = Vector<float, 3> (at_1.x, py_0 + shiftUp_0, at_1.y);
    return d_11;
}

static float convTowerSurface_0(ConvectionInput_0 * c_38, Vector<float, 2>  rel_1, float r_7, float py_1, float above_5, Vector<float, 3>  * x_21)
{
    float _S276 = convDomeSurface_0(c_38->cvHeroTop_0, c_38->cvHeroRadius_0, c_38->cvShape_0, rel_1, r_7, py_1, above_5, x_21);
    return _S276;
}

static float convShapeSurface_0(ConvectionInput_0 * c_39, Vector<float, 2>  plane_0, float py_2, float above_6, Vector<float, 3>  * x_22)
{
    float _S277 = plane_0.x;
    Vector<float, 2>  slopeUY_1;
    float _S278 = convShapeDistance_0(c_39, _S277, above_6, &slopeUY_1);
    float _S279 = plane_0.y;
    Vector<float, 2>  stepDM_1;
    float gap_2 = convShapeProfile_0(_S278, (F32_abs((_S279))), c_39->cvShapeRound_0, &stepDM_1);
    float side_0;
    if(_S279 >= 0.0f)
    {
        side_0 = 1.0f;
    }
    else
    {
        side_0 = -1.0f;
    }
    *x_22 = Vector<float, 3> (_S277 + stepDM_1.x * slopeUY_1.x, py_2 + stepDM_1.x * slopeUY_1.y, _S279 + side_0 * stepDM_1.y);
    return - gap_2;
}

static bool convHeroSmooth_0(ConvectionInput_0 * c_40, Vector<float, 3>  p_4, float above_7, float * d_13, Vector<float, 3>  * x_23, float * amount_0, float * lobe_0)
{
    *d_13 = -1.00000001504746622e+30f;
    *x_23 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float _S280 = c_40->cvHeroBillow_0;
    *amount_0 = c_40->cvHeroBillow_0;
    *lobe_0 = _S280;
    Vector<float, 2>  rel_2 = Vector<float, 2> {p_4.x, p_4.z} - c_40->cvHeroAt_0;
    float r_8 = length_0(rel_2);
    float _S281 = convHeroReachAll_0(c_40);
    if(r_8 >= _S281)
    {
        return false;
    }
    if((c_40->cvShapeOn_0) == int(0))
    {
        float _S282 = convTowerSurface_0(c_40, rel_2, r_8, p_4.y, above_7, x_23);
        *d_13 = _S282;
    }
    else
    {
        Vector<float, 2>  plane_1 = Vector<float, 2> (dot_0(rel_2, c_40->cvShapeAxisU_0), dot_0(rel_2, Vector<float, 2> (- c_40->cvShapeAxisU_0.y, c_40->cvShapeAxisU_0.x)));
        float _S283 = c_40->cvShapeDecay_0;
        if((c_40->cvShapeDecay_0) >= 1.0f)
        {
            float _S284 = convTowerSurface_0(c_40, plane_1, r_8, p_4.y, above_7, x_23);
            *d_13 = _S284;
        }
        else
        {
            float _S285 = p_4.y;
            Vector<float, 3>  xs_0;
            float _S286 = convShapeSurface_0(c_40, plane_1, _S285, above_7, &xs_0);
            if(_S283 > 0.0f)
            {
                Vector<float, 3>  xt_0;
                float _S287 = convTowerSurface_0(c_40, plane_1, r_8, _S285, above_7, &xt_0);
                *d_13 = lerp_0(_S286, _S287, _S283);
                *x_23 = lerp_2(xs_0, xt_0, (Vector<float, 3> )_S283);
            }
            else
            {
                *d_13 = _S286;
                *x_23 = xs_0;
            }
            float _S288 = c_40->cvShapeBillow_0;
            *amount_0 = _S280 * lerp_0(c_40->cvShapeBillow_0, 1.0f, _S283);
            *lobe_0 = _S280 * lerp_0((F32_max((_S288), (0.30000001192092896f))), 1.0f, _S283);
        }
    }
    return true;
}

static bool convTurretSmooth_0(ConvectionInput_0 * c_41, Vector<float, 4>  t_8, Vector<float, 3>  p_5, float above_8, float * d_14, Vector<float, 3>  * x_24, float * k_8)
{
    *d_14 = -1.00000001504746622e+30f;
    *x_24 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *k_8 = 1.0f;
    Vector<float, 2>  rel_3 = Vector<float, 2> {p_5.x, p_5.z} - Vector<float, 2> {t_8.x, t_8.y};
    float r2_2 = dot_0(rel_3, rel_3);
    float _S289 = convTurretReach_0(c_41, t_8);
    if(r2_2 >= (_S289 * _S289))
    {
        return false;
    }
    float _S290 = t_8.w;
    if(above_8 >= (_S290 + c_41->cvBillow_0 * c_41->cvHeroBillow_0))
    {
        return false;
    }
    float r_9 = (F32_sqrt((r2_2)));
    float _S291 = t_8.z;
    float _S292 = convTurretBillow_0(c_41, _S291);
    *k_8 = _S292;
    Vector<float, 3>  own_0;
    float _S293 = convDomeSurface_0(_S290, _S291, c_41->cvShape_0, rel_3, r_9, p_5.y, above_8, &own_0);
    *d_14 = _S293;
    Vector<float, 3>  w_4 = own_0 + Vector<float, 3> (t_8.x - c_41->cvHeroAt_0.x, 0.0f, t_8.y - c_41->cvHeroAt_0.y);
    Vector<float, 3>  w_5;
    if((c_41->cvShapeOn_0) != int(0))
    {
        Vector<float, 2>  _S294 = Vector<float, 2> {w_4.x, w_4.z};
        w_5 = Vector<float, 3> (dot_0(_S294, c_41->cvShapeAxisU_0), w_4.y, dot_0(_S294, Vector<float, 2> (- c_41->cvShapeAxisU_0.y, c_41->cvShapeAxisU_0.x)));
    }
    else
    {
        w_5 = w_4;
    }
    *x_24 = w_5;
    return true;
}

static float convGroupBaseInside_0(ConvectionInput_0 * c_42, Vector<float, 2>  xz_2, bool nearGroup_0)
{
    float best_1;
    if((c_42->cvHeroTop_0) > 0.0f)
    {
        Vector<float, 3>  p_6 = Vector<float, 3> (xz_2.x, c_42->cvBase_0 + 1.0f, xz_2.y);
        float d_15;
        float amount_1;
        float lobe_1;
        Vector<float, 3>  x_25;
        bool _S295 = convHeroSmooth_0(c_42, p_6, 1.0f, &d_15, &x_25, &amount_1, &lobe_1);
        if(_S295)
        {
            best_1 = (F32_max((-1.00000001504746622e+30f), (d_15)));
        }
        else
        {
            best_1 = -1.00000001504746622e+30f;
        }
        int32_t k_9 = int(0);
        for(;;)
        {
            if(k_9 < int(5))
            {
            }
            else
            {
                break;
            }
            bool _S296;
            if(!nearGroup_0)
            {
                _S296 = true;
            }
            else
            {
                _S296 = k_9 >= (c_42->cvTurretCount_0);
            }
            if(_S296)
            {
                break;
            }
            Vector<float, 4>  _S297 = convTurret_0(c_42, k_9);
            float kt_0;
            bool _S298 = convTurretSmooth_0(c_42, _S297, p_6, 1.0f, &d_15, &x_25, &kt_0);
            if(_S298)
            {
                best_1 = (F32_max((best_1), (d_15)));
            }
            k_9 = k_9 + int(1);
        }
    }
    else
    {
        best_1 = -1.00000001504746622e+30f;
    }
    return best_1;
}

static float convBaseInside_0(ConvectionInput_0 * c_43, Vector<float, 2>  xz_3, bool nearGroup_1)
{
    float best_2;
    if((c_43->cvHeroAlone_0) == int(0))
    {
        float capMoat_0 = 0.0f;
        Vector<float, 2>  gMoat_0 = Vector<float, 2> (0.0f, 0.0f);
        bool moated_0;
        if((c_43->cvMoat_0) > 0.0f)
        {
            moated_0 = nearGroup_1;
        }
        else
        {
            moated_0 = false;
        }
        float m_4;
        if(moated_0)
        {
            float _S299 = convMoat_0(c_43, xz_3, &gMoat_0, &capMoat_0);
            m_4 = _S299;
        }
        else
        {
            m_4 = 1.0f;
        }
        if(m_4 > 0.0f)
        {
            Vector<float, 2>  slope_5;
            float _S300 = convUpdraftGrad_0(c_43, xz_3 - c_43->cvDrift_0, &slope_5);
            float _S301 = convSlopeCap_0(c_43);
            float cap_4;
            if(moated_0)
            {
                slope_5 = slope_5 * (Vector<float, 2> )m_4 + gMoat_0 * (Vector<float, 2> )_S300;
                float cap_5 = _S301 + capMoat_0;
                best_2 = _S300 * m_4;
                cap_4 = cap_5;
            }
            else
            {
                best_2 = _S300;
                cap_4 = _S301;
            }
            float _S302 = convFieldBaseInside_0(c_43, best_2, slope_5, cap_4);
            best_2 = _S302;
        }
        else
        {
            best_2 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        best_2 = -1.00000001504746622e+30f;
    }
    float _S303 = convGroupBaseInside_0(c_43, xz_3, nearGroup_1);
    return (F32_max((best_2), (_S303)));
}

static float convMammaSagOf_0(ConvectionInput_0 * c_44, float pouch_0, float inside_2)
{
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_44->cvMammaDepth_0 * pouch_0 * smoothstep_0(0.0f, 0.60000002384185791f * c_44->cvPouchSize_0, inside_2);
}

static float convMammaSag_0(ConvectionInput_0 * c_45, Vector<float, 2>  xz_4, bool nearGroup_2, float below_0)
{
    float _S304 = convPouches_0(c_45, xz_4 - c_45->cvDrift_0);
    if((c_45->cvMammaDepth_0 * _S304) <= below_0)
    {
        return 0.0f;
    }
    float _S305 = convBaseInside_0(c_45, xz_4, nearGroup_2);
    float _S306 = convMammaSagOf_0(c_45, _S304, _S305);
    return _S306;
}

static Vector<float, 3>  convTwist_0(Vector<float, 3>  x_26)
{
    float _S307 = x_26.x;
    float _S308 = x_26.y;
    float _S309 = x_26.z;
    return Vector<float, 3> (0.0f * _S307 + 0.80000001192092896f * _S308 + 0.60000002384185791f * _S309, -0.80000001192092896f * _S307 + 0.36000001430511475f * _S308 - 0.47999998927116394f * _S309, -0.60000002384185791f * _S307 - 0.47999998927116394f * _S308 + 0.63999998569488525f * _S309);
}

static float convPuffs_0(Vector<float, 3>  x_27)
{
    Vector<float, 3>  fl_0 = floor_0(x_27);
    Vector<int32_t, 3>  _S310 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fl_0, 0), (int32_t)_slang_vector_get_element(fl_0, 1), (int32_t)_slang_vector_get_element(fl_0, 2)};
    Vector<float, 3>  f_2 = x_27 - fl_0;
    int32_t dz_0;
    if((f_2.x) < 0.5f)
    {
        dz_0 = int(-1);
    }
    else
    {
        dz_0 = int(0);
    }
    int32_t dy_0;
    if((f_2.y) < 0.5f)
    {
        dy_0 = int(-1);
    }
    else
    {
        dy_0 = int(0);
    }
    int32_t dx_0;
    if((f_2.z) < 0.5f)
    {
        dx_0 = int(-1);
    }
    else
    {
        dx_0 = int(0);
    }
    Vector<int32_t, 3>  _S311 = Vector<int32_t, 3> (dz_0, dy_0, dx_0);
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
                Vector<int32_t, 3>  off_0 = _S311 + Vector<int32_t, 3> (dx_0, dy_0, dz_0);
                Vector<float, 3>  _S312 = Vector<float, 3> {(float)_slang_vector_get_element(off_0, 0), (float)_slang_vector_get_element(off_0, 1), (float)_slang_vector_get_element(off_0, 2)};
                Vector<float, 3>  d_16 = _S312 + (Vector<float, 3> )0.5f + (Vector<float, 3> )0.25f * hash33_0(_S310 + off_0) - f_2;
                float _S313 = (F32_min((nearest_1), (dot_1(d_16, d_16))));
                int32_t dx_1 = dx_0 + int(1);
                nearest_1 = _S313;
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

static float convBillow_0(ConvectionInput_0 * c_46, Vector<float, 3>  p_7, float scale_0)
{
    Vector<float, 3>  _S314 = Vector<float, 3> (p_7.x, p_7.y - c_46->cvRise_0, p_7.z) / (Vector<float, 3> )scale_0;
    int32_t i_19 = int(0);
    Vector<float, 3>  x_28 = _S314;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_19 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_19 >= (c_46->cvOctaves_0))
        {
            break;
        }
        Vector<float, 3>  x_29 = convTwist_0(x_28);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_29);
        float norm_3 = norm_2 + amp_2;
        Vector<float, 3>  x_30 = x_29 * (Vector<float, 3> )2.17000007629394531f;
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_19 = i_19 + int(1);
        x_28 = x_30;
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

static float convInside_0(ConvectionInput_0 * c_47, float d_17, float lift_2, Vector<float, 3>  x_31, float scale_1)
{
    float _S315 = d_17 + lift_2;
    if(_S315 <= 0.0f)
    {
        return _S315;
    }
    if((d_17 - lift_2) >= 12.0f)
    {
        return 12.0f;
    }
    float _S316 = convBillow_0(c_47, x_31, scale_1);
    return d_17 + lift_2 * _S316;
}

static float convCapGrain_0(ConvectionInput_0 * c_48, Vector<float, 2>  rel_4, float scale_2)
{
    return saturate_0(0.80000001192092896f + 0.13330000638961792f * gradientNoise_0(Vector<float, 3> (rel_4.x / scale_2 + c_48->cvHeroSeed_0.x * 0.00100000004749745f, 0.37000000476837158f, rel_4.y / scale_2 + c_48->cvHeroSeed_0.z * 0.00100000004749745f)));
}

static float convCapDensity_0(ConvectionInput_0 * c_49, Vector<float, 3>  p_8, float above_9)
{
    Vector<float, 2>  rel_5 = Vector<float, 2> {p_8.x, p_8.z} - c_49->cvHeroAt_0;
    float r2_3 = dot_0(rel_5, rel_5);
    float _S317 = c_49->cvHeroRadius_0;
    float _S318 = c_49->cvPileusThick_0;
    float best_3;
    if((c_49->cvPileusThick_0) > 0.0f)
    {
        float rp_1 = 0.60000002384185791f * _S317;
        float _S319 = rp_1 * rp_1;
        if(r2_3 < _S319)
        {
            float lens_0 = 1.0f - r2_3 / _S319;
            float _S320 = c_49->cvPileusGap_0;
            float _S321 = convHeroHeight_0(c_49, (F32_sqrt((r2_3))) * 0.60000002384185791f);
            float most_0 = 0.5f * _S318 * lens_0;
            float _S322 = (F32_abs((above_9 - (_S320 + _S321))));
            if(_S322 < most_0)
            {
                float _S323 = convCapGrain_0(c_49, rel_5, 900.0f);
                float s_11 = most_0 * _S323 - _S322;
                if(s_11 > 0.0f)
                {
                    best_3 = (F32_max((0.0f), (0.44999998807907104f * smoothstep_0(0.0f, 15.0f, s_11))));
                }
                else
                {
                    best_3 = 0.0f;
                }
            }
            else
            {
                best_3 = 0.0f;
            }
        }
        else
        {
            best_3 = 0.0f;
        }
    }
    else
    {
        best_3 = 0.0f;
    }
    float _S324 = c_49->cvVelumThick_0;
    if((c_49->cvVelumThick_0) > 0.0f)
    {
        float ext_1 = 1.89999997615814209f * _S317;
        if(r2_3 < (ext_1 * ext_1))
        {
            float r_10 = (F32_sqrt((r2_3)));
            Vector<float, 2>  dir_0;
            if(r_10 > 0.00100000004749745f)
            {
                dir_0 = rel_5 / (Vector<float, 2> )r_10;
            }
            else
            {
                dir_0 = Vector<float, 2> (1.0f, 0.0f);
            }
            float edge_1 = _S317 + (ext_1 - _S317) * saturate_0(0.875f + 0.08330000191926956f * gradientNoise_0(Vector<float, 3> (1.70000004768371582f * dir_0.x + c_49->cvHeroSeed_0.x * 0.00100000004749745f, 2.29999995231628418f, 1.70000004768371582f * dir_0.y + c_49->cvHeroSeed_0.z * 0.00100000004749745f)));
            float _S325 = 0.5f * _S324;
            float most_1 = _S325 * (1.0f - smoothstep_0(_S317 + 0.40000000596046448f * (edge_1 - _S317), edge_1, r_10));
            float _S326 = (F32_abs((above_9 - (c_49->cvVelumHeight_0 + _S325 * (1.0f - smoothstep_0(_S317, 2.0f * _S317, r_10))))));
            if(_S326 < most_1)
            {
                float _S327 = convCapGrain_0(c_49, rel_5, 2500.0f);
                float s_12 = most_1 * _S327 - _S326;
                if(s_12 > 0.0f)
                {
                    best_3 = (F32_max((best_3), (0.2199999988079071f * smoothstep_0(0.0f, 15.0f, s_12))));
                }
            }
        }
    }
    return c_49->cvSigma_0 * best_3;
}

static void convGroupFold_0(float d_18, Vector<float, 3>  x_32, float lift_3, float lobe_2, float * gMax_0, float * gSum_0, Vector<float, 3>  * gX_0, float * gLift_0, float * gLobe_0)
{
    if(d_18 > (*gMax_0))
    {
        float scale_3 = (F32_exp(((*gMax_0 - d_18) / 50.0f)));
        *gSum_0 = *gSum_0 * scale_3;
        *gX_0 = *gX_0 * (Vector<float, 3> )scale_3;
        *gLift_0 = *gLift_0 * scale_3;
        *gLobe_0 = *gLobe_0 * scale_3;
        *gMax_0 = d_18;
    }
    float wt_0 = (F32_exp(((d_18 - *gMax_0) / 50.0f)));
    *gSum_0 = *gSum_0 + wt_0;
    *gX_0 = *gX_0 + (Vector<float, 3> )wt_0 * x_32;
    *gLift_0 = *gLift_0 + wt_0 * lift_3;
    *gLobe_0 = *gLobe_0 + wt_0 * lobe_2;
    return;
}

static float convGroupInside_0(ConvectionInput_0 * c_50, Vector<float, 3>  p_9, float above_10, bool nearGroup_3)
{
    bool _S328;
    float gMax_1 = -1.00000001504746622e+30f;
    float gSum_1 = 0.0f;
    float gLift_1 = 0.0f;
    float gLobe_1 = 0.0f;
    Vector<float, 3>  gX_1 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float d_19;
    float amount_2;
    float lobe_3;
    Vector<float, 3>  x_33;
    bool anyTurret_0 = false;
    int32_t k_10 = int(0);
    for(;;)
    {
        if(k_10 < int(5))
        {
        }
        else
        {
            break;
        }
        if(!nearGroup_3)
        {
            _S328 = true;
        }
        else
        {
            _S328 = k_10 >= (c_50->cvTurretCount_0);
        }
        if(_S328)
        {
            break;
        }
        Vector<float, 4>  _S329 = convTurret_0(c_50, k_10);
        float kt_1;
        bool _S330 = convTurretSmooth_0(c_50, _S329, p_9, above_10, &d_19, &x_33, &kt_1);
        if(_S330)
        {
            float _S331 = convLift_0(c_50, above_10, kt_1);
            convGroupFold_0(d_19, x_33, _S331, kt_1, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
            anyTurret_0 = true;
        }
        k_10 = k_10 + int(1);
    }
    bool _S332 = convHeroSmooth_0(c_50, p_9, above_10, &d_19, &x_33, &amount_2, &lobe_3);
    float heroLift_0;
    if(_S332)
    {
        float _S333 = convLift_0(c_50, above_10, amount_2);
        heroLift_0 = _S333;
    }
    else
    {
        heroLift_0 = 0.0f;
    }
    if(!_S332)
    {
        _S328 = !anyTurret_0;
    }
    else
    {
        _S328 = false;
    }
    if(_S328)
    {
        return -1.00000001504746622e+30f;
    }
    float lift_4;
    float lobeAt_0;
    Vector<float, 3>  at_2;
    if(!anyTurret_0)
    {
        gMax_1 = d_19;
        lift_4 = heroLift_0;
        at_2 = x_33;
        lobeAt_0 = lobe_3;
    }
    else
    {
        if(_S332)
        {
            convGroupFold_0(d_19, x_33, heroLift_0, lobe_3, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
        }
        Vector<float, 3>  _S334 = gX_1 / (Vector<float, 3> )gSum_1;
        float _S335 = gLobe_1 / gSum_1;
        lift_4 = gLift_1 / gSum_1;
        at_2 = _S334;
        lobeAt_0 = _S335;
    }
    float _S336 = convInside_0(c_50, gMax_1, lift_4, at_2 + c_50->cvHeroSeed_0, c_50->cvBillowScale_0 * lobeAt_0);
    return _S336;
}

static float convHeroInside_0(ConvectionInput_0 * c_51, Vector<float, 3>  p_10, float above_11)
{
    float d_20;
    float amount_3;
    float lobe_4;
    Vector<float, 3>  x_34;
    bool _S337 = convHeroSmooth_0(c_51, p_10, above_11, &d_20, &x_34, &amount_3, &lobe_4);
    if(!_S337)
    {
        return -1.00000001504746622e+30f;
    }
    float _S338 = convLift_0(c_51, above_11, amount_3);
    float _S339 = convInside_0(c_51, d_20, _S338, x_34 + c_51->cvHeroSeed_0, c_51->cvBillowScale_0 * lobe_4);
    return _S339;
}

static float convectionDensity_0(ConvectionInput_0 * c_52, Vector<float, 3>  p_11)
{
    float _S340 = p_11.y;
    float above_12 = _S340 - c_52->cvBase_0;
    float _S341 = c_52->cvMammaDepth_0;
    bool rampBand_0;
    if(above_12 < (- c_52->cvMammaDepth_0))
    {
        rampBand_0 = true;
    }
    else
    {
        float _S342 = convCeiling_0(c_52);
        rampBand_0 = above_12 > _S342;
    }
    if(rampBand_0)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S343 = Vector<float, 2> {p_11.x, p_11.z};
    Vector<float, 2>  fromHero_0 = _S343 - c_52->cvHeroAt_0;
    bool nearGroup_4 = (dot_0(fromHero_0, fromHero_0)) < (c_52->cvGroupReach_0 * c_52->cvGroupReach_0);
    bool _S344 = _S341 > 0.0f;
    if(_S344)
    {
        rampBand_0 = above_12 < 0.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    if(rampBand_0)
    {
        float _S345 = convMammaSag_0(c_52, _S343, nearGroup_4, - above_12);
        float hang_0 = _S345 + above_12;
        if(hang_0 <= 0.0f)
        {
            return 0.0f;
        }
        return c_52->cvSigma_0 * (F32_sqrt((saturate_0(hang_0 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, hang_0);
    }
    float _S346 = convLift_0(c_52, above_12, 1.0f - 0.60000002384185791f * c_52->cvLacunarity_0);
    if(_S344)
    {
        rampBand_0 = above_12 < 40.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    bool moated_1;
    float capDensity_0;
    float sag_0;
    float baseField_0;
    float inside_3;
    if((c_52->cvHeroAlone_0) == int(0))
    {
        float capMoat_1 = 0.0f;
        Vector<float, 2>  _S347 = Vector<float, 2> (0.0f, 0.0f);
        Vector<float, 2>  gMoat_1 = _S347;
        if((c_52->cvMoat_0) > 0.0f)
        {
            moated_1 = nearGroup_4;
        }
        else
        {
            moated_1 = false;
        }
        if(moated_1)
        {
            float _S348 = convMoat_0(c_52, _S343, &gMoat_1, &capMoat_1);
            capDensity_0 = _S348;
        }
        else
        {
            capDensity_0 = 1.0f;
        }
        if(capDensity_0 > 0.0f)
        {
            Vector<float, 2>  q_11 = _S343 - c_52->cvDrift_0;
            Vector<float, 2>  slope_6;
            float _S349 = convUpdraftGrad_0(c_52, q_11, &slope_6);
            float _S350 = convSlopeCap_0(c_52);
            float cap_6;
            if(moated_1)
            {
                slope_6 = slope_6 * (Vector<float, 2> )capDensity_0 + gMoat_1 * (Vector<float, 2> )_S349;
                float cap_7 = _S350 + capMoat_1;
                sag_0 = _S349 * capDensity_0;
                cap_6 = cap_7;
            }
            else
            {
                sag_0 = _S349;
                cap_6 = _S350;
            }
            if(rampBand_0)
            {
                float _S351 = convFieldBaseInside_0(c_52, sag_0, slope_6, cap_6);
                baseField_0 = _S351;
            }
            else
            {
                baseField_0 = -1.00000001504746622e+30f;
            }
            float _S352 = convTowerHeight_0(c_52, sag_0);
            float v_5 = _S352 - above_12;
            float _S353 = convNeededUpdraft_0(c_52, above_12);
            float delta_1 = sag_0 - _S353;
            float d_21 = convSurfaceDistance_0(v_5, delta_1, (F32_min((length_0(slope_6)), (cap_6))));
            if((d_21 + _S346) > 0.0f)
            {
                if((F32_abs((v_5))) > 9.99999997475242708e-07f)
                {
                    inside_3 = d_21 * (d_21 / v_5);
                }
                else
                {
                    inside_3 = 0.0f;
                }
                Vector<float, 2>  shiftAcross_0;
                if((F32_abs((delta_1))) > 9.999999960041972e-13f)
                {
                    shiftAcross_0 = slope_6 * (Vector<float, 2> )(- d_21 * (d_21 / delta_1));
                }
                else
                {
                    shiftAcross_0 = _S347;
                }
                float _S354 = convInside_0(c_52, d_21, _S346, Vector<float, 3> (q_11.x + shiftAcross_0.x, _S340 + inside_3, q_11.y + shiftAcross_0.y), c_52->cvBillowScale_0);
                inside_3 = _S354;
            }
            else
            {
                inside_3 = -1.00000001504746622e+30f;
            }
        }
        else
        {
            inside_3 = -1.00000001504746622e+30f;
            baseField_0 = -1.00000001504746622e+30f;
        }
    }
    else
    {
        inside_3 = -1.00000001504746622e+30f;
        baseField_0 = -1.00000001504746622e+30f;
    }
    bool _S355 = (c_52->cvHeroTop_0) > 0.0f;
    if(_S355)
    {
        if((c_52->cvPileusThick_0) > 0.0f)
        {
            moated_1 = true;
        }
        else
        {
            moated_1 = (c_52->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        float _S356 = convCapDensity_0(c_52, p_11, above_12);
        capDensity_0 = _S356;
    }
    else
    {
        capDensity_0 = 0.0f;
    }
    if(_S355)
    {
        moated_1 = inside_3 < 12.0f;
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        if((c_52->cvTurretCount_0) > int(0))
        {
            float _S357 = convGroupInside_0(c_52, p_11, above_12, nearGroup_4);
            inside_3 = (F32_max((inside_3), (_S357)));
        }
        else
        {
            float _S358 = convHeroInside_0(c_52, p_11, above_12);
            inside_3 = (F32_max((inside_3), (_S358)));
        }
    }
    if(inside_3 <= 0.0f)
    {
        return capDensity_0;
    }
    if(rampBand_0)
    {
        float _S359 = convPouches_0(c_52, _S343 - c_52->cvDrift_0);
        if(_S359 > 0.0f)
        {
            float _S360 = convGroupBaseInside_0(c_52, _S343, nearGroup_4);
            float _S361 = convMammaSagOf_0(c_52, _S359, (F32_max((baseField_0), (_S360))));
            sag_0 = _S361;
        }
        else
        {
            sag_0 = 0.0f;
        }
    }
    else
    {
        sag_0 = 0.0f;
    }
    return (F32_max((c_52->cvSigma_0 * (F32_sqrt((saturate_0((above_12 + sag_0) / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_3)), (capDensity_0)));
}

static float densityAt_0(Medium_0 * m_5, StructuredBuffer<Vector<float, 2> > disp_6, Vector<float, 3>  p_12)
{
    float _S362 = p_12.y;
    bool _S363;
    if(_S362 < (m_5->slabBottom_0))
    {
        _S363 = true;
    }
    else
    {
        _S363 = _S362 > (m_5->slabTop_0);
    }
    if(_S363)
    {
        return 0.0f;
    }
    if((m_5->clipOn_0) != int(0))
    {
        Vector<float, 2>  _S364 = Vector<float, 2> {p_12.x, p_12.z};
        if(any_0(_S364 < (m_5->clipLo_0)))
        {
            _S363 = true;
        }
        else
        {
            _S363 = any_0(_S364 > (m_5->clipHi_0));
        }
    }
    else
    {
        _S363 = false;
    }
    if(_S363)
    {
        return 0.0f;
    }
    float _S365 = m_5->fadeRadius_0;
    float fade_0;
    if((m_5->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S365 - length_0(Vector<float, 2> {p_12.x, p_12.z} - m_5->fadeAt_0)) / (F32_max((m_5->fadeWidth_0), (1.0f))));
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
    int32_t _S366 = m_5->mode_0;
    if((m_5->mode_0) == int(0))
    {
        return m_5->density_0 * fade_0;
    }
    if(_S366 == int(2))
    {
        float _S367 = iceDensity_0(&m_5->gen_0, disp_6, p_12);
        return _S367 * fade_0;
    }
    if(_S366 == int(3))
    {
        float _S368 = convectionDensity_0(&m_5->conv_0, p_12);
        return _S368 * fade_0;
    }
    Vector<float, 3>  d_22 = (p_12 - m_5->coreCentre_0) / (Vector<float, 3> )(F32_max((m_5->coreRadius_0), (9.99999997475242708e-07f)));
    return (m_5->density_0 + m_5->coreDensity_0 * (F32_exp((- dot_1(d_22, d_22))))) * fade_0;
}

static float transmittance_0(Medium_0 * m_6, MajorantGrid_0 * g_12, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > disp_7, Rng_0 * rng_1, Vector<float, 3>  p_13, Vector<float, 3>  dir_1, int32_t * steps_0)
{
    float t0_2;
    float t1_2;
    bool _S369 = slabRange_0(m_6, p_13, dir_1, &t0_2, &t1_2);
    if(!_S369)
    {
        return 1.0f;
    }
    float _S370 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S370;
    Dda_0 _S371 = ddaInit_0(g_12, p_13, dir_1, _S370);
    Dda_0 dda_0 = _S371;
    float _S372 = m_6->majorant_0;
    float _S373 = gridBound_0(m_6, g_12, bounds_2, disp_7, (&dda_0)->cell_0, m_6->majorant_0);
    float localMaj_0 = _S373;
    int32_t i_20 = int(0);
    float t_9 = _S370;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_20 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_0 = *steps_0 + int(1);
        Dda_0 _S374 = dda_0;
        float _S375 = ddaExit_0(&_S374);
        float _S376 = (F32_min((_S375), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S376 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S377 = gridBound_0(m_6, g_12, bounds_2, disp_7, (&dda_0)->cell_0, _S372);
            localMaj_0 = _S377;
            t_9 = _S376;
            i_20 = i_20 + int(1);
            continue;
        }
        float _S378 = randFloat_0(rng_1);
        float t_10 = t_9 - (F32_log(((F32_max((1.0f - _S378), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_10 >= _S376)
        {
            if(_S376 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_0);
            float _S379 = gridBound_0(m_6, g_12, bounds_2, disp_7, (&dda_0)->cell_0, _S372);
            localMaj_0 = _S379;
            t_9 = _S376;
            i_20 = i_20 + int(1);
            continue;
        }
        float _S380 = densityAt_0(m_6, disp_7, p_13 + dir_1 * (Vector<float, 3> )t_10);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S380 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S381 = randFloat_0(rng_1);
            if(_S381 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_9 = t_10;
        tr_0 = tr_2;
        i_20 = i_20 + int(1);
    }
    return tr_0;
}

void _cpuTransmittanceTrial(void* _S382, void* entryPointParams_1, void* _S383)
{
    ComputeThreadVaryingInput * _S384 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S382));
    int32_t i_21 = int32_t((_S384->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S384->groupThreadID).x);
    if(i_21 >= ((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->count_1))
    {
        return;
    }
    Rng_0 rng_2 = makeRngForIndex_0((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->seed_1, i_21);
    int32_t steps_1 = int(0);
    float * _S385 = (&((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->output_1)[i_21]);
    float _S386 = transmittance_0(&(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->medium_0, &(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->grid_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->bounds_0, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->drift_0, &rng_2, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->origin_1, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->direction_0, &steps_1);
    *_S385 = _S386;
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
