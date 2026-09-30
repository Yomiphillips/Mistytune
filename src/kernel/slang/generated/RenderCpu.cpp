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
    Vector<float, 3>  groundSkyLight_0;
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

struct LayerShadowMap_0
{
    StructuredBuffer<float> smTexels_0;
    Vector<float, 3>  smSun_0;
    Vector<float, 2>  smCentre_0;
    Vector<float, 2>  smAxisU_0;
    Vector<float, 2>  smLo_0;
    Vector<float, 2>  smTexel_0;
    int32_t smDimU_0;
    int32_t smDimV_0;
    int32_t smSlices_0;
    float smBottom_0;
    float smTop_0;
    float smStep_0;
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
    int32_t airMapOn_0;
    LayerShadowMap_0 airMapIce_0;
    LayerShadowMap_0 airMapCu_0;
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

struct EntryPointParams_1
{
    Medium_0 medium_1;
    StructuredBuffer<Vector<float, 2> > drift_1;
    LayerShadowMap_0 map_0;
    RWStructuredBuffer<float> outTexels_0;
    int32_t count_1;
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

static Vector<float, 3>  max_0(Vector<float, 3>  x_3, Vector<float, 3>  y_1)
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
        result_0[i_0] = (F32_max((_slang_vector_get_element(x_3, i_0)), (_slang_vector_get_element(y_1, i_0))));
        i_0 = i_0 + int(1);
    }
    return result_0;
}

static int32_t StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    Vector<uint32_t, 2>  _S7 = uint2(_elementCount_0, _stride_0);
    return int32_t(_S7.x);
}

static float dot_1(Vector<float, 2>  x_4, Vector<float, 2>  y_2)
{
    return x_4.x * y_2.x + x_4.y * y_2.y;
}

static Vector<float, 3>  floor_0(Vector<float, 3>  x_5)
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
        result_1[i_1] = (F32_floor((_slang_vector_get_element(x_5, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static Vector<uint32_t, 3>  pcg3d_0(Vector<uint32_t, 3>  v_0)
{
    Vector<uint32_t, 3>  _S8 = v_0 * (Vector<uint32_t, 3> )1664525U + (Vector<uint32_t, 3> )1013904223U;
    Vector<uint32_t, 3>  _S9 = _S8;
    _S9.x = _S9.x + _S8.y * _S8.z;
    _S9.y = _S9.y + _S9.z * _S9.x;
    _S9.z = _S9.z + _S9.x * _S9.y;
    Vector<uint32_t, 3>  _S10 = _S9 ^ (_S9 >> ((Vector<uint32_t, 3> )16U));
    _S9 = _S10;
    _S9.x = _S9.x + _S10.y * _S10.z;
    _S9.y = _S9.y + _S9.z * _S9.x;
    _S9.z = _S9.z + _S9.x * _S9.y;
    return _S9;
}

static Vector<float, 3>  hash33_0(Vector<int32_t, 3>  c_0)
{
    Vector<uint32_t, 3>  h_0 = pcg3d_0(Vector<uint32_t, 3> (uint32_t(c_0.x), uint32_t(c_0.y), uint32_t(c_0.z)));
    Vector<float, 3>  _S11 = Vector<float, 3> {(float)_slang_vector_get_element(h_0, 0), (float)_slang_vector_get_element(h_0, 1), (float)_slang_vector_get_element(h_0, 2)};
    return _S11 * (Vector<float, 3> )4.65661287307739258e-10f - (Vector<float, 3> )1.0f;
}

static float lerp_0(float x_6, float y_3, float s_0)
{
    return x_6 + (y_3 - x_6) * s_0;
}

static float gradientNoise_0(Vector<float, 3>  p_0)
{
    Vector<float, 3>  fi_0 = floor_0(p_0);
    Vector<int32_t, 3>  _S12 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_0 - fi_0;
    Vector<float, 3>  u_0 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S13 = u_0.x;
    float _S14 = u_0.y;
    return lerp_0(lerp_0(lerp_0(dot_0(hash33_0(_S12), f_0), dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S13), lerp_0(dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S13), _S14), lerp_0(lerp_0(dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S13), lerp_0(dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S13), _S14), u_0.z);
}

static Vector<float, 2>  orgWarpOffset_0(Organization_0 * o_0, Vector<float, 2>  g_0)
{
    Vector<float, 2>  s_1 = g_0 / (Vector<float, 2> )2.5f;
    float _S15 = s_1.x;
    float _S16 = s_1.y;
    return (Vector<float, 2> )o_0->ogWarp_0 * Vector<float, 2> (gradientNoise_0(Vector<float, 3> (_S15, 0.37000000476837158f, _S16)), gradientNoise_0(Vector<float, 3> (_S15 + 17.10000038146972656f, 5.82999992370605469f, _S16 - 9.39999961853027344f)));
}

static Vector<float, 2>  orgPattern_0(Organization_0 * o_1, Vector<float, 2>  q_0, float spacing_0)
{
    if((o_1->ogOn_0) == int(0))
    {
        return q_0 / (Vector<float, 2> )spacing_0;
    }
    Vector<float, 2>  g_1 = Vector<float, 2> (dot_1(q_0, o_1->ogAxis_0), dot_1(q_0, Vector<float, 2> (- o_1->ogAxis_0.y, o_1->ogAxis_0.x))) / Vector<float, 2> (spacing_0 * o_1->ogStretch_0, spacing_0);
    Vector<float, 2>  g_2;
    if((o_1->ogWarp_0) > 0.0f)
    {
        Vector<float, 2>  _S17 = orgWarpOffset_0(o_1, g_1);
        g_2 = g_1 + _S17;
    }
    else
    {
        g_2 = g_1;
    }
    return g_2;
}

static Vector<float, 2>  floor_1(Vector<float, 2>  x_7)
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
        result_2[i_2] = (F32_floor((_slang_vector_get_element(x_7, i_2))));
        i_2 = i_2 + int(1);
    }
    return result_2;
}

static Vector<uint32_t, 2>  pcg2d_0(Vector<uint32_t, 2>  v_1)
{
    Vector<uint32_t, 2>  _S18 = v_1 * (Vector<uint32_t, 2> )1664525U + (Vector<uint32_t, 2> )1013904223U;
    Vector<uint32_t, 2>  _S19 = _S18;
    _S19.x = _S19.x + _S18.y * 1664525U;
    _S19.y = _S19.y + _S19.x * 1664525U;
    Vector<uint32_t, 2>  _S20 = _S19 ^ (_S19 >> ((Vector<uint32_t, 2> )16U));
    _S19 = _S20;
    _S19.x = _S19.x + _S20.y * 1664525U;
    _S19.y = _S19.y + _S19.x * 1664525U;
    Vector<uint32_t, 2>  _S21 = _S19 ^ (_S19 >> ((Vector<uint32_t, 2> )16U));
    _S19 = _S21;
    return _S21;
}

static Vector<float, 2>  hash22_0(Vector<int32_t, 2>  c_1, uint32_t salt_0)
{
    Vector<uint32_t, 2>  h_1 = pcg2d_0(Vector<uint32_t, 2> (uint32_t(c_1.x), uint32_t(c_1.y)) ^ Vector<uint32_t, 2> (salt_0, salt_0 * 2654435761U));
    Vector<float, 2>  _S22 = Vector<float, 2> {(float)_slang_vector_get_element(h_1, 0), (float)_slang_vector_get_element(h_1, 1)};
    return _S22 * (Vector<float, 2> )2.32830643653869629e-10f;
}

static float convLife_0(float u_1)
{
    float _S23 = 1.0f - u_1;
    return 6.75f * u_1 * _S23 * _S23;
}

static float convVigour_0(ConvectionInput_0 * c_2, Vector<int32_t, 2>  slot_0)
{
    Vector<float, 2>  h_2 = hash22_0(slot_0, 3039394381U);
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_0(0.34999999403953552f, 1.0f, h_2.y);
}

static Vector<float, 2>  orgJitter_0(Organization_0 * o_2, float jitter_0)
{
    float _S24;
    if((o_2->ogOn_0) != int(0))
    {
        _S24 = jitter_0 * (1.0f - o_2->ogCoherence_0);
    }
    else
    {
        _S24 = jitter_0;
    }
    return Vector<float, 2> (jitter_0, _S24);
}

static Vector<float, 2>  convCellCentre_0(ConvectionInput_0 * c_3, Vector<int32_t, 2>  slot_1)
{
    Vector<float, 2>  j_0 = hash22_0(slot_1, 1759714724U) - (Vector<float, 2> )0.5f;
    Vector<float, 2>  _S25 = Vector<float, 2> {(float)_slang_vector_get_element(slot_1, 0), (float)_slang_vector_get_element(slot_1, 1)};
    Vector<float, 2>  _S26 = _S25 + (Vector<float, 2> )0.5f;
    Vector<float, 2>  _S27 = orgJitter_0(&c_3->cvOrg_0, 0.69999998807907104f);
    return _S26 + j_0 * _S27;
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

static float clamp_0(float x_8, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_8), (minBound_0)))), (maxBound_0)));
}

static float saturate_0(float x_9)
{
    return clamp_0(x_9, 0.0f, 1.0f);
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
        Vector<float, 2>  _S28;
        if(dist_0 > 9.99999997475242708e-07f)
        {
            _S28 = d_0 * (Vector<float, 2> )(6.0f * t_1 * (1.0f - t_1) / (band_0 * dist_0));
        }
        else
        {
            _S28 = Vector<float, 2> (0.0f, 0.0f);
        }
        *gKeep_0 = _S28;
    }
    return;
}

static Vector<float, 2>  lerp_1(Vector<float, 2>  x_10, Vector<float, 2>  y_4, Vector<float, 2>  s_2)
{
    return x_10 + (y_4 - x_10) * s_2;
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
    bool _S29;
    if((o_4->ogOn_0) == int(0))
    {
        _S29 = true;
    }
    else
    {
        _S29 = (o_4->ogWaveAmp_0) <= 0.0f;
    }
    if(_S29)
    {
        return 1.0f;
    }
    Vector<float, 2>  _S30 = o_4->ogWaveK_0;
    float s_4 = 2.0f * (F32_frac((dot_1(q_1, o_4->ogWaveK_0)))) - 1.0f;
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
    float _S31 = o_4->ogWaveAmp_0;
    *grad_0 = _S30 * (Vector<float, 2> )(o_4->ogWaveAmp_0 * dCrest_0 * dTri_0);
    return 1.0f - _S31 * (1.0f - crest_0);
}

static float convOrganize_0(ConvectionInput_0 * c_5, Vector<float, 2>  q_2, float kTop_0, float kNext_0, Vector<float, 2>  gkTop_0, Vector<float, 2>  gkNext_0, float keep_1, Vector<float, 2>  gKeep_1, float w_0, Vector<float, 2>  gp_1, Vector<float, 2>  * grad_1)
{
    float _S32 = c_5->cvLacunarity_0;
    Vector<float, 2>  _S33;
    float _S34;
    if((c_5->cvLacunarity_0) > 0.0f)
    {
        float fill_0 = lerp_0(w_0, 0.40000000596046448f, _S32);
        float _S35 = fill_0 * keep_1;
        _S33 = gp_1 * (Vector<float, 2> )(1.0f - _S32) * (Vector<float, 2> )keep_1 + gKeep_1 * (Vector<float, 2> )fill_0;
        _S34 = _S35;
    }
    else
    {
        _S33 = gp_1;
        _S34 = w_0;
    }
    float _S36 = c_5->cvPolarity_0;
    bool _S37;
    if((c_5->cvPolarity_0) > 0.0f)
    {
        _S37 = (c_5->cvGapWidth_0) > 0.0f;
    }
    else
    {
        _S37 = false;
    }
    if(_S37)
    {
        Vector<float, 2>  _S38 = Vector<float, 2> (0.0f, 0.0f);
        Vector<float, 2>  gcn_0;
        float cn_0;
        if(kTop_0 > 0.0f)
        {
            Vector<float, 2>  _S39 = (gkTop_0 * (Vector<float, 2> )kNext_0 - gkNext_0 * (Vector<float, 2> )kTop_0) / (Vector<float, 2> )(kTop_0 * kTop_0);
            cn_0 = 1.0f - kNext_0 / kTop_0;
            gcn_0 = _S39;
        }
        else
        {
            cn_0 = 0.0f;
            gcn_0 = _S38;
        }
        float ramp_0 = 0.5f * c_5->cvGapWidth_0;
        float t_2 = saturate_0((cn_0 - ramp_0) / ramp_0);
        float s_5 = lerp_0(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S36);
        float _S40 = _S34 * s_5;
        _S33 = _S33 * (Vector<float, 2> )s_5 + gcn_0 * (Vector<float, 2> )(_S34 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S36));
        _S34 = _S40;
    }
    Vector<float, 2>  _S41 = orgGradToWorld_0(&c_5->cvOrg_0, _S33, c_5->cvSpacing_0);
    *grad_1 = _S41;
    Vector<float, 2>  gm_0;
    float _S42 = orgWave_0(&c_5->cvOrg_0, q_2, &gm_0);
    *grad_1 = _S41 * (Vector<float, 2> )_S42 + gm_0 * (Vector<float, 2> )_S34;
    return _S34 * _S42;
}

static float convUpdraftGradT_0(ConvectionInput_0 * c_6, Vector<float, 2>  q_3, Vector<float, 2>  * grad_2)
{
    Vector<float, 2>  goTop_0;
    Vector<float, 2>  _S43 = orgPattern_0(&c_6->cvOrg_0, q_3, c_6->cvSpacing_0);
    Vector<float, 2>  _S44 = floor_1(_S43);
    Vector<int32_t, 2>  _S45 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S44, 0), (int32_t)_slang_vector_get_element(_S44, 1)};
    Vector<float, 2>  _S46 = Vector<float, 2> (0.0f, 0.0f);
    float keep_2 = 1.0f;
    Vector<float, 2>  gKeep_2 = _S46;
    float oTop_0 = 0.0f;
    Vector<float, 2>  goTop_1 = _S46;
    float oNext_0 = 0.0f;
    float kTop_1 = 0.0f;
    Vector<float, 2>  gkTop_1 = _S46;
    float kNext_1 = 0.0f;
    Vector<float, 2>  goNext_0 = _S46;
    Vector<float, 2>  gkNext_1 = _S46;
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
            Vector<int32_t, 2>  slot_2 = _S45 + Vector<int32_t, 2> (i_3, j_1);
            float _S47 = convVigour_0(c_6, slot_2);
            if(_S47 <= 0.0f)
            {
                i_3 = i_3 + int(1);
                continue;
            }
            Vector<float, 2>  _S48 = convCellCentre_0(c_6, slot_2);
            Vector<float, 2>  d_1 = _S43 - _S48;
            float d2_2 = dot_1(d_1, d_1);
            float ko_0 = _S47 * convBump_0(d2_2, 0.75f);
            float kk_0 = _S47 * convBump_0(d2_2, 1.04999995231628418f);
            convHole_0(c_6, d_1, d2_2, _S47, &keep_2, &gKeep_2);
            Vector<float, 2>  gko_0;
            if(d2_2 < 0.5625f)
            {
                gko_0 = d_1 * (Vector<float, 2> )(-4.0f * _S47 * (1.0f - d2_2 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_0 = _S46;
            }
            Vector<float, 2>  gkk_0;
            if(d2_2 < 1.10249984264373779f)
            {
                gkk_0 = d_1 * (Vector<float, 2> )(-4.0f * _S47 * (1.0f - d2_2 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_0 = _S46;
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
                float _S49 = oTop_2;
                Vector<float, 2>  _S50 = goTop_2;
                oTop_2 = oTop_1;
                goTop_2 = goTop_0;
                oNext_2 = _S49;
                goNext_2 = _S50;
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
                float _S51 = kTop_3;
                Vector<float, 2>  _S52 = gkTop_3;
                kTop_3 = kTop_2;
                gkTop_3 = gkTop_2;
                kNext_3 = _S51;
                gkNext_3 = _S52;
            }
            oTop_1 = oTop_2;
            goTop_0 = goTop_2;
            oNext_1 = oNext_2;
            kTop_2 = kTop_3;
            gkTop_2 = gkTop_3;
            kNext_2 = kNext_3;
            goNext_1 = goNext_2;
            gkNext_2 = gkNext_3;
            i_3 = i_3 + int(1);
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
    float _S53 = (F32_min((openRaw_0), (1.0f)));
    float closedField_0 = kTop_1 - kNext_1;
    if(openRaw_0 < 1.0f)
    {
        goTop_0 = goNext_0 / (Vector<float, 2> )0.31000000238418579f;
    }
    else
    {
        goTop_0 = _S46;
    }
    Vector<float, 2>  gClosed_0 = gkTop_1 - gkNext_1;
    float _S54 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_0(_S53, closedField_0, c_6->cvPolarity_0), lerp_1(goTop_0, gClosed_0, (Vector<float, 2> )c_6->cvPolarity_0), grad_2);
    return _S54;
}

static float convUpdraftGradT_1(ConvectionInput_0 * c_7, Vector<float, 2>  q_4, Vector<float, 2>  * grad_3)
{
    Vector<float, 2>  goTop_3;
    Vector<float, 2>  _S55 = orgPattern_0(&c_7->cvOrg_0, q_4, c_7->cvSpacing_0);
    Vector<float, 2>  _S56 = floor_1(_S55);
    Vector<int32_t, 2>  _S57 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S56, 0), (int32_t)_slang_vector_get_element(_S56, 1)};
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
            Vector<int32_t, 2>  slot_3 = _S57 + Vector<int32_t, 2> (i_4, j_3);
            float _S58 = convVigour_0(c_7, slot_3);
            if(_S58 <= 0.0f)
            {
                i_4 = i_4 + int(1);
                continue;
            }
            Vector<float, 2>  _S59 = convCellCentre_0(c_7, slot_3);
            Vector<float, 2>  d_2 = _S55 - _S59;
            float d2_3 = dot_1(d_2, d_2);
            float ko_1 = _S58 * convBump_0(d2_3, 0.75f);
            float kk_1 = _S58 * convBump_0(d2_3, 1.04999995231628418f);
            Vector<float, 2>  gko_1;
            if(d2_3 < 0.5625f)
            {
                gko_1 = d_2 * (Vector<float, 2> )(-4.0f * _S58 * (1.0f - d2_3 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_1 = gKeep_3;
            }
            Vector<float, 2>  gkk_1;
            if(d2_3 < 1.10249984264373779f)
            {
                gkk_1 = d_2 * (Vector<float, 2> )(-4.0f * _S58 * (1.0f - d2_3 / 1.10249984264373779f) / 1.10249984264373779f);
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
                float _S60 = oTop_5;
                Vector<float, 2>  _S61 = goTop_5;
                oTop_5 = oTop_4;
                goTop_5 = goTop_3;
                oNext_5 = _S60;
                goNext_5 = _S61;
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
                float _S62 = kTop_6;
                Vector<float, 2>  _S63 = gkTop_6;
                kTop_6 = kTop_5;
                gkTop_6 = gkTop_5;
                kNext_6 = _S62;
                gkNext_6 = _S63;
            }
            oTop_4 = oTop_5;
            goTop_3 = goTop_5;
            oNext_4 = oNext_5;
            kTop_5 = kTop_6;
            gkTop_5 = gkTop_6;
            kNext_5 = kNext_6;
            goNext_4 = goNext_5;
            gkNext_5 = gkNext_6;
            i_4 = i_4 + int(1);
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
    float _S64 = (F32_min((openRaw_1), (1.0f)));
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
    float _S65 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_0(_S64, closedField_1, c_7->cvPolarity_0), lerp_1(goTop_3, gClosed_1, (Vector<float, 2> )c_7->cvPolarity_0), grad_3);
    return _S65;
}

static Vector<float, 2>  convCellCentrePlain_0(Vector<int32_t, 2>  slot_4)
{
    Vector<float, 2>  _S66 = Vector<float, 2> {(float)_slang_vector_get_element(slot_4, 0), (float)_slang_vector_get_element(slot_4, 1)};
    return _S66 + (Vector<float, 2> )0.5f + (hash22_0(slot_4, 1759714724U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.69999998807907104f;
}

static float convUpdraftGradT_2(ConvectionInput_0 * c_8, Vector<float, 2>  q_5, Vector<float, 2>  * grad_4)
{
    Vector<float, 2>  goTop_6;
    float _S67 = c_8->cvSpacing_0;
    Vector<float, 2>  _S68 = q_5 / (Vector<float, 2> )c_8->cvSpacing_0;
    Vector<float, 2>  _S69 = floor_1(_S68);
    Vector<int32_t, 2>  _S70 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S69, 0), (int32_t)_slang_vector_get_element(_S69, 1)};
    Vector<float, 2>  _S71 = Vector<float, 2> (0.0f, 0.0f);
    float oTop_6 = 0.0f;
    Vector<float, 2>  goTop_7 = _S71;
    float oNext_6 = 0.0f;
    float kTop_7 = 0.0f;
    Vector<float, 2>  gkTop_7 = _S71;
    float kNext_7 = 0.0f;
    Vector<float, 2>  goNext_6 = _S71;
    Vector<float, 2>  gkNext_7 = _S71;
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
        int32_t i_5 = int(-1);
        for(;;)
        {
            if(i_5 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_5 = _S70 + Vector<int32_t, 2> (i_5, j_5);
            float _S72 = convVigour_0(c_8, slot_5);
            if(_S72 <= 0.0f)
            {
                i_5 = i_5 + int(1);
                continue;
            }
            Vector<float, 2>  d_3 = _S68 - convCellCentrePlain_0(slot_5);
            float d2_4 = dot_1(d_3, d_3);
            float ko_2 = _S72 * convBump_0(d2_4, 0.75f);
            float kk_2 = _S72 * convBump_0(d2_4, 1.04999995231628418f);
            Vector<float, 2>  gko_2;
            if(d2_4 < 0.5625f)
            {
                gko_2 = d_3 * (Vector<float, 2> )(-4.0f * _S72 * (1.0f - d2_4 / 0.5625f) / 0.5625f);
            }
            else
            {
                gko_2 = _S71;
            }
            Vector<float, 2>  gkk_2;
            if(d2_4 < 1.10249984264373779f)
            {
                gkk_2 = d_3 * (Vector<float, 2> )(-4.0f * _S72 * (1.0f - d2_4 / 1.10249984264373779f) / 1.10249984264373779f);
            }
            else
            {
                gkk_2 = _S71;
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
                float _S73 = oTop_8;
                Vector<float, 2>  _S74 = goTop_8;
                oTop_8 = oTop_7;
                goTop_8 = goTop_6;
                oNext_8 = _S73;
                goNext_8 = _S74;
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
                float _S75 = kTop_9;
                Vector<float, 2>  _S76 = gkTop_9;
                kTop_9 = kTop_8;
                gkTop_9 = gkTop_8;
                kNext_9 = _S75;
                gkNext_9 = _S76;
            }
            oTop_7 = oTop_8;
            goTop_6 = goTop_8;
            oNext_7 = oNext_8;
            kTop_8 = kTop_9;
            gkTop_8 = gkTop_9;
            kNext_8 = kNext_9;
            goNext_7 = goNext_8;
            gkNext_8 = gkNext_9;
            i_5 = i_5 + int(1);
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
    float _S77 = (F32_min((openRaw_2), (1.0f)));
    float closedField_2 = kTop_7 - kNext_7;
    if(openRaw_2 < 1.0f)
    {
        goTop_6 = goNext_6 / (Vector<float, 2> )0.31000000238418579f;
    }
    else
    {
        goTop_6 = _S71;
    }
    Vector<float, 2>  gClosed_2 = gkTop_7 - gkNext_7;
    float _S78 = c_8->cvPolarity_0;
    *grad_4 = lerp_1(goTop_6, gClosed_2, (Vector<float, 2> )c_8->cvPolarity_0) / (Vector<float, 2> )_S67;
    return lerp_0(_S77, closedField_2, _S78);
}

static bool any_0(Vector<bool, 2>  x_11)
{
    bool result_3 = false;
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
        if(result_3)
        {
            result_3 = true;
        }
        else
        {
            result_3 = (bool((_slang_vector_get_element(x_11, i_6))));
        }
        i_6 = i_6 + int(1);
    }
    return result_3;
}

static int32_t clamp_1(int32_t x_12, int32_t minBound_1, int32_t maxBound_1)
{
    return (I32_min(((I32_max((x_12), (minBound_1)))), (maxBound_1)));
}

static float length_1(Vector<float, 2>  x_13)
{
    return (F32_sqrt((dot_1(x_13, x_13))));
}

static Vector<float, 2>  abs_0(Vector<float, 2>  x_14)
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
        result_4[i_7] = (F32_abs((_slang_vector_get_element(x_14, i_7))));
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static bool all_0(Vector<bool, 2>  x_15)
{
    bool result_5 = true;
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
        if(result_5)
        {
            result_5 = (bool((_slang_vector_get_element(x_15, i_8))));
        }
        else
        {
            result_5 = false;
        }
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static float smoothstep_0(float min_0, float max_1, float x_16)
{
    float _S79 = saturate_0((x_16 - min_0) / (max_1 - min_0));
    return _S79 * _S79 * (3.0f - (_S79 + _S79));
}

static Vector<float, 2>  min_1(Vector<float, 2>  x_17, Vector<float, 2>  y_5)
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
        result_6[i_9] = (F32_min((_slang_vector_get_element(x_17, i_9)), (_slang_vector_get_element(y_5, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static Vector<float, 2>  max_2(Vector<float, 2>  x_18, Vector<float, 2>  y_6)
{
    Vector<float, 2>  result_7;
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
        result_7[i_10] = (F32_max((_slang_vector_get_element(x_18, i_10)), (_slang_vector_get_element(y_6, i_10))));
        i_10 = i_10 + int(1);
    }
    return result_7;
}

static Rng_0 makeRng_0(uint32_t seed_1)
{
    Rng_0 r_1;
    (&r_1)->state_0 = seed_1;
    return r_1;
}

static Rng_0 splitRng_0(Rng_0 * r_2, uint32_t salt_1)
{
    uint32_t s_6 = ((r_2->state_0) ^ (salt_1 * 2654435761U)) * 747796405U + 2891336453U;
    uint32_t s_7 = ((s_6 >> ((s_6 >> 28U) + 4U)) ^ s_6) * 277803737U;
    return makeRng_0((s_7 >> 22U) ^ s_7);
}

static bool clipAxis_0(float o_5, float d_4, float lo_0, float hi_0, float * t0_0, float * t1_0)
{
    if((F32_abs((d_4))) < 9.99999971718068537e-10f)
    {
        bool _S80;
        if(o_5 >= lo_0)
        {
            _S80 = o_5 <= hi_0;
        }
        else
        {
            _S80 = false;
        }
        return _S80;
    }
    float ta_0 = (lo_0 - o_5) / d_4;
    float tb_0 = (hi_0 - o_5) / d_4;
    *t0_0 = (F32_max((*t0_0), ((F32_min((ta_0), (tb_0))))));
    float _S81 = (F32_min((*t1_0), ((F32_max((ta_0), (tb_0))))));
    *t1_0 = _S81;
    return _S81 > (*t0_0);
}

static bool slabRange_0(Medium_0 * m_0, Vector<float, 3>  ro_0, Vector<float, 3>  rd_0, float * t0_1, float * t1_1)
{
    *t0_1 = 0.0f;
    *t1_1 = 1.0e+09f;
    float _S82 = rd_0.y;
    bool _S83;
    if((F32_abs((_S82))) < 9.99999997475242708e-07f)
    {
        float _S84 = ro_0.y;
        if(_S84 < (m_0->slabBottom_0))
        {
            _S83 = true;
        }
        else
        {
            _S83 = _S84 > (m_0->slabTop_0);
        }
        if(_S83)
        {
            return false;
        }
    }
    else
    {
        float _S85 = ro_0.y;
        float ta_1 = (m_0->slabBottom_0 - _S85) / _S82;
        float tb_1 = (m_0->slabTop_0 - _S85) / _S82;
        *t0_1 = (F32_max((*t0_1), ((F32_min((ta_1), (tb_1))))));
        *t1_1 = (F32_min((*t1_1), ((F32_max((ta_1), (tb_1))))));
    }
    bool _S86 = (m_0->clipOn_0) != int(0);
    Vector<float, 2>  lo_1;
    if(_S86)
    {
        lo_1 = m_0->clipLo_0;
    }
    else
    {
        lo_1 = Vector<float, 2> (-1.0e+09f, -1.0e+09f);
    }
    Vector<float, 2>  hi_1;
    if(_S86)
    {
        hi_1 = m_0->clipHi_0;
    }
    else
    {
        hi_1 = Vector<float, 2> (1.0e+09f, 1.0e+09f);
    }
    float _S87 = m_0->fadeRadius_0;
    if((m_0->fadeRadius_0) > 0.0f)
    {
        Vector<float, 2>  _S88 = min_1(hi_1, m_0->fadeAt_0 + (Vector<float, 2> )_S87);
        lo_1 = max_2(lo_1, m_0->fadeAt_0 - (Vector<float, 2> )_S87);
        hi_1 = _S88;
    }
    bool _S89 = clipAxis_0(ro_0.x, rd_0.x, lo_1.x, hi_1.x, t0_1, t1_1);
    if(!_S89)
    {
        return false;
    }
    bool _S90 = clipAxis_0(ro_0.z, rd_0.z, lo_1.y, hi_1.y, t0_1, t1_1);
    if(!_S90)
    {
        return false;
    }
    float _S91 = (F32_min((*t1_1), (1.2e+05f)));
    *t1_1 = _S91;
    if(_S91 > (*t0_1))
    {
        _S83 = (*t1_1) > 0.0f;
    }
    else
    {
        _S83 = false;
    }
    return _S83;
}

static Dda_0 ddaInit_0(MajorantGrid_0 * g_3, Vector<float, 3>  ro_1, Vector<float, 3>  rd_1, float t_3)
{
    Dda_0 d_5;
    if((g_3->enabled_0) == int(0))
    {
        Vector<int32_t, 3>  _S92 = Vector<int32_t, 3> (int(0), int(0), int(0));
        (&d_5)->cell_0 = _S92;
        (&d_5)->stepDir_0 = _S92;
        Vector<float, 3>  _S93 = Vector<float, 3> (1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
        (&d_5)->tMax_0 = _S93;
        (&d_5)->tDelta_0 = _S93;
        return d_5;
    }
    Vector<float, 3>  p_1 = ro_1 + rd_1 * (Vector<float, 3> )t_3;
    Vector<float, 3>  _S94 = floor_0((p_1 - g_3->origin_0) / g_3->cellExtent_0);
    Vector<int32_t, 3>  _S95 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(_S94, 0), (int32_t)_slang_vector_get_element(_S94, 1), (int32_t)_slang_vector_get_element(_S94, 2)};
    (&d_5)->cell_0 = _S95;
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
        int32_t _S96 = a_0;
        if((F32_abs((_slang_vector_get_element(rd_1, a_0)))) < 9.999999960041972e-13f)
        {
            (&d_5)->stepDir_0[a_0] = int(0);
            (&d_5)->tMax_0[a_0] = 1.00000001504746622e+30f;
            (&d_5)->tDelta_0[a_0] = 1.00000001504746622e+30f;
        }
        else
        {
            bool _S97 = _slang_vector_get_element(rd_1, _S96) > 0.0f;
            int32_t _S98;
            if(_S97)
            {
                _S98 = int(1);
            }
            else
            {
                _S98 = int(-1);
            }
            (&d_5)->stepDir_0[a_0] = _S98;
            float _S99 = g_3->origin_0[a_0];
            float _S100 = float((&d_5)->cell_0[a_0]);
            float _S101;
            if(_S97)
            {
                _S101 = 1.0f;
            }
            else
            {
                _S101 = 0.0f;
            }
            (&d_5)->tMax_0[a_0] = t_3 + (_S99 + (_S100 + _S101) * g_3->cellExtent_0[a_0] - _slang_vector_get_element(p_1, a_0)) / _slang_vector_get_element(rd_1, _S96);
            (&d_5)->tDelta_0[a_0] = (F32_abs((g_3->cellExtent_0[a_0] / _slang_vector_get_element(rd_1, _S96))));
        }
        a_0 = a_0 + int(1);
    }
    return d_5;
}

static float convCeiling_0(ConvectionInput_0 * c_9)
{
    float _S102 = c_9->cvBillow_0;
    float field_0 = c_9->cvDepth_0 + c_9->cvBillow_0;
    float _S103 = c_9->cvHeroTop_0;
    float hero_0;
    if((c_9->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S103 + _S102 * c_9->cvHeroBillow_0;
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
    Organization_0 _S104 = flat_0;
    Vector<float, 2>  _S105 = orgPattern_0(&_S104, q0_0, spacing_2);
    Organization_0 _S106 = flat_0;
    Vector<float, 2>  _S107 = orgPattern_0(&_S106, q1_0, spacing_2);
    Vector<float, 2>  _S108 = Vector<float, 2> (q0_0.x, q1_0.y);
    Organization_0 _S109 = flat_0;
    Vector<float, 2>  _S110 = orgPattern_0(&_S109, _S108, spacing_2);
    Vector<float, 2>  _S111 = Vector<float, 2> (q1_0.x, q0_0.y);
    Organization_0 _S112 = flat_0;
    Vector<float, 2>  _S113 = orgPattern_0(&_S112, _S111, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S105.x)))), ((F32_abs((_S105.y))))))), ((F32_max(((F32_abs((_S107.x)))), ((F32_abs((_S107.y)))))))));
    *a_1 = min_1(min_1(_S105, _S110), min_1(_S113, _S107)) - (Vector<float, 2> )grow_0;
    *b_0 = max_2(max_2(_S105, _S110), max_2(_S113, _S107)) + (Vector<float, 2> )grow_0;
    return;
}

static void convSlotBound_0(ConvectionInput_0 * c_11, Vector<int32_t, 2>  slot_6, Vector<float, 2>  a_2, Vector<float, 2>  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S114 = convVigour_0(c_11, slot_6);
    if(_S114 <= 0.0f)
    {
        return;
    }
    Vector<float, 2>  _S115 = convCellCentre_0(c_11, slot_6);
    Vector<float, 2>  _S116 = a_2 - _S115;
    Vector<float, 2>  nearGap_0 = max_2(max_2(_S116, _S115 - b_1), Vector<float, 2> (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_0, nearGap_0);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    Vector<float, 2>  farGap_0 = max_2(abs_0(_S116), abs_0(b_1 - _S115));
    float oHi_0 = _S114 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S114 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S114 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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
    Vector<float, 2>  _S117 = floor_1((a_3 + b_2) * (Vector<float, 2> )0.5f);
    Vector<int32_t, 2>  _S118 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S117, 0), (int32_t)_slang_vector_get_element(_S117, 1)};
    Vector<float, 2>  _S119 = Vector<float, 2> {(float)_slang_vector_get_element(_S118, 0), (float)_slang_vector_get_element(_S118, 1)};
    Vector<float, 2>  highEdge_0 = _S119 + (Vector<float, 2> )1.0f + (Vector<float, 2> )0.00009999999747379f;
    bool _S120;
    if(all_0(a_3 >= (_S119 - (Vector<float, 2> )0.00009999999747379f)))
    {
        _S120 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S120 = false;
    }
    int32_t j_7;
    int32_t i_11;
    if(_S120)
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
                convSlotBound_0(c_12, _S118 + Vector<int32_t, 2> (i_11, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_11 = i_11 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        Vector<float, 2>  _S121 = floor_1(a_3);
        Vector<int32_t, 2>  _S122 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S121, 0), (int32_t)_slang_vector_get_element(_S121, 1)};
        Vector<int32_t, 2>  _S123 = Vector<int32_t, 2> (int(1), int(1));
        Vector<int32_t, 2>  i0_0 = _S122 - _S123;
        Vector<float, 2>  _S124 = floor_1(b_2);
        Vector<int32_t, 2>  _S125 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S124, 0), (int32_t)_slang_vector_get_element(_S124, 1)};
        Vector<int32_t, 2>  _S126 = _S125 + _S123;
        int32_t _S127 = i0_0.y;
        j_7 = _S127;
        for(;;)
        {
            if(j_7 <= (_S126.y))
            {
                _S120 = j_7 <= (_S127 + int(32));
            }
            else
            {
                _S120 = false;
            }
            if(_S120)
            {
            }
            else
            {
                break;
            }
            int32_t _S128 = i0_0.x;
            i_11 = _S128;
            for(;;)
            {
                bool _S129;
                if(i_11 <= (_S126.x))
                {
                    _S129 = i_11 <= (_S128 + int(32));
                }
                else
                {
                    _S129 = false;
                }
                if(_S129)
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
    float _S130 = c_12->cvLacunarity_0;
    float field_2;
    if((c_12->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_0(field_1, 0.40000000596046448f, _S130);
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
    bool _S131;
    if(cover_1 <= 0.0f)
    {
        _S131 = true;
    }
    else
    {
        _S131 = (c_14->cvDepth_0) <= 0.0f;
    }
    if(_S131)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_14->cvDepth_0), (1.0f / (F32_max((c_14->cvShape_0), (0.00100000004749745f))))));
}

static float convSlopeCap_0(ConvectionInput_0 * c_15)
{
    float _S132 = c_15->cvSpacing_0;
    float cap_0 = 7.0f / c_15->cvSpacing_0;
    if(((&c_15->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_0;
    }
    float _S133 = c_15->cvLacunarity_0;
    float cap_1;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        cap_1 = cap_0 + 1.5f / (0.15000000596046448f * _S133 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S132);
    }
    else
    {
        cap_1 = cap_0;
    }
    float _S134 = c_15->cvGapWidth_0;
    if((c_15->cvGapWidth_0) > 0.0f)
    {
        cap_1 = cap_1 + 14.25f * c_15->cvPolarity_0 / (0.5f * _S134 * _S132);
    }
    return cap_1 + 3.0f * (&c_15->cvOrg_0)->ogWaveAmp_0 * length_1((&c_15->cvOrg_0)->ogWaveK_0);
}

static float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S135;
    if(vMin_0 <= 0.0f)
    {
        _S135 = true;
    }
    else
    {
        _S135 = hMin_0 <= 0.0f;
    }
    if(_S135)
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
    float _S136 = c_17->cvHeroTop_0;
    bool _S137;
    if((c_17->cvHeroTop_0) <= 0.0f)
    {
        _S137 = true;
    }
    else
    {
        _S137 = r_3 >= (c_17->cvHeroRadius_0);
    }
    if(_S137)
    {
        return 0.0f;
    }
    return _S136 * (F32_pow((1.0f - r_3 * r_3 / (c_17->cvHeroRadius_0 * c_17->cvHeroRadius_0)), (c_17->cvShape_0)));
}

static float convHeroRadiusAt_0(ConvectionInput_0 * c_18, float above_2)
{
    float _S138 = c_18->cvHeroTop_0;
    bool _S139;
    if((c_18->cvHeroTop_0) <= 0.0f)
    {
        _S139 = true;
    }
    else
    {
        _S139 = above_2 >= _S138;
    }
    if(_S139)
    {
        return -1.0f;
    }
    return c_18->cvHeroRadius_0 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / _S138), (1.0f / (F32_max((c_18->cvShape_0), (0.00100000004749745f))))))), (0.0f))))));
}

static float convectionBound_0(ConvectionInput_0 * c_19, Vector<float, 3>  lo_2, Vector<float, 3>  hi_2)
{
    float low_0 = lo_2.y - c_19->cvBase_0;
    float high_0 = hi_2.y - c_19->cvBase_0;
    float _S140 = convCeiling_0(c_19);
    bool _S141;
    if(high_0 < 0.0f)
    {
        _S141 = true;
    }
    else
    {
        _S141 = low_0 > _S140;
    }
    if(_S141)
    {
        return 0.0f;
    }
    float _S142 = (F32_max((low_0), (0.0f)));
    float _S143 = (F32_min((high_0), (_S140)));
    float _S144 = convLift_0(c_19, _S143, 1.0f);
    float inside_0;
    if((c_19->cvHeroAlone_0) == int(0))
    {
        float _S145 = convUpdraftBound_0(c_19, Vector<float, 2> {lo_2.x, lo_2.z} - c_19->cvDrift_0, Vector<float, 2> {hi_2.x, hi_2.z} - c_19->cvDrift_0);
        float _S146 = convTowerHeight_0(c_19, _S145);
        float _S147 = convNeededUpdraft_0(c_19, _S142);
        if(_S145 < _S147)
        {
            float _S148 = convSlopeCap_0(c_19);
            inside_0 = _S144 - convDistanceFloor_0(_S142 - _S146, (_S147 - _S145) / _S148);
        }
        else
        {
            inside_0 = (F32_max((_S146 - _S142), (0.0f))) + _S144;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    if((c_19->cvHeroTop_0) > 0.0f)
    {
        float rMin_0 = length_1(max_2(max_2(Vector<float, 2> {lo_2.x, lo_2.z} - c_19->cvHeroAt_0, c_19->cvHeroAt_0 - Vector<float, 2> {hi_2.x, hi_2.z}), Vector<float, 2> (0.0f, 0.0f)));
        float _S149 = convHeroReach_0(c_19);
        if(rMin_0 < _S149)
        {
            float _S150 = convHeroHeight_0(c_19, rMin_0);
            float _S151 = convHeroRadiusAt_0(c_19, _S142);
            float _S152 = convLift_0(c_19, _S143, c_19->cvHeroBillow_0);
            bool _S153 = _S151 < 0.0f;
            if(_S153)
            {
                _S141 = true;
            }
            else
            {
                _S141 = rMin_0 >= _S151;
            }
            float heroIn_0;
            if(_S141)
            {
                if(_S153)
                {
                    heroIn_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    heroIn_0 = rMin_0 - _S151;
                }
                heroIn_0 = _S152 - convDistanceFloor_0(_S142 - _S150, heroIn_0);
            }
            else
            {
                heroIn_0 = (F32_max((_S150 - _S142), (0.0f))) + _S152;
            }
            inside_0 = (F32_max((inside_0), (heroIn_0)));
        }
    }
    float inside_1 = inside_0 + 0.00100000004749745f;
    if(inside_1 <= 0.0f)
    {
        return 0.0f;
    }
    return c_19->cvSigma_0 * (F32_sqrt((saturate_0(_S143 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_1) * 1.00001001358032227f;
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_19 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_12 = clamp_1(int32_t((F32_floor((x_19)))), int(0), int(31));
    return lerp_1(disp_0.Load(i_12), disp_0.Load(i_12 + int(1)), (Vector<float, 2> )(x_19 - float(i_12)));
}

static void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<Vector<float, 2> > disp_1, float d0_0, float d1_0, Vector<float, 2>  * lo_3, Vector<float, 2>  * hi_3)
{
    Vector<float, 2>  _S154 = driftAt_0(g_5, disp_1, d0_0);
    *lo_3 = _S154;
    *hi_3 = _S154;
    Vector<float, 2>  _S155 = driftAt_0(g_5, disp_1, d1_0);
    *lo_3 = min_1(*lo_3, _S155);
    *hi_3 = max_2(*hi_3, _S155);
    int32_t _S156 = clamp_1(int32_t((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int32_t k_2 = clamp_1(int32_t((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_2 <= _S156)
        {
        }
        else
        {
            break;
        }
        *lo_3 = min_1(*lo_3, disp_1.Load(k_2));
        *hi_3 = max_2(*hi_3, disp_1.Load(k_2));
        k_2 = k_2 + int(1);
    }
    return;
}

static float cellFieldBound_0(GeneratorInput_0 * g_6, Vector<float, 2>  q0_2, Vector<float, 2>  q1_2)
{
    Vector<float, 2>  a_4;
    Vector<float, 2>  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    Vector<float, 2>  _S157 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    Vector<float, 2>  _S158 = floor_1(a_4);
    Vector<int32_t, 2>  _S159 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S158, 0), (int32_t)_slang_vector_get_element(_S158, 1)};
    Vector<int32_t, 2>  _S160 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  i0_1 = _S159 - _S160;
    Vector<float, 2>  _S161 = floor_1(b_3);
    Vector<int32_t, 2>  _S162 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S161, 0), (int32_t)_slang_vector_get_element(_S161, 1)};
    Vector<int32_t, 2>  _S163 = _S162 + _S160;
    int32_t _S164 = i0_1.y;
    int32_t j_8 = _S164;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S165;
        if(j_8 <= (_S163.y))
        {
            _S165 = j_8 <= (_S164 + int(32));
        }
        else
        {
            _S165 = false;
        }
        if(_S165)
        {
        }
        else
        {
            break;
        }
        int32_t _S166 = i0_1.x;
        int32_t i_13 = _S166;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S167;
            if(i_13 <= (_S163.x))
            {
                _S167 = i_13 <= (_S166 + int(32));
            }
            else
            {
                _S167 = false;
            }
            if(_S167)
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
            Vector<float, 2>  _S168 = Vector<float, 2> {(float)_slang_vector_get_element(o_7, 0), (float)_slang_vector_get_element(o_7, 1)};
            Vector<float, 2>  c_20 = _S168 + (Vector<float, 2> )0.5f + (hash22_0(o_7, 0U) - (Vector<float, 2> )0.5f) * _S157;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(max_2(max_2(a_4 - c_20, c_20 - b_3), Vector<float, 2> (0.0f, 0.0f))) * 2.20000004768371582f);
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
    bool _S169;
    if(d1_1 < 0.0f)
    {
        _S169 = true;
    }
    else
    {
        _S169 = d0_1 > (g_7->streakLength_0);
    }
    if(_S169)
    {
        return 0.0f;
    }
    float _S170 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    Vector<float, 2>  driftLo_0;
    Vector<float, 2>  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S171 = cellFieldBound_0(g_7, Vector<float, 2> (lo_4.x, lo_4.z) - driftHi_0, Vector<float, 2> (hi_4.x, hi_4.z) - driftLo_0);
    return (F32_max((_S171 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S170), (1.0f)));
}

static float mediumBound_0(Medium_0 * m_1, StructuredBuffer<Vector<float, 2> > disp_3, Vector<float, 3>  lo_5, Vector<float, 3>  hi_5)
{
    int32_t _S172 = m_1->mode_0;
    if((m_1->mode_0) == int(3))
    {
        float _S173 = convectionBound_0(&m_1->conv_0, lo_5, hi_5);
        return _S173;
    }
    if(_S172 == int(2))
    {
        float _S174 = iceDensityBound_0(&m_1->gen_0, disp_3, lo_5, hi_5);
        return _S174;
    }
    return m_1->majorant_0;
}

static float gridBound_0(Medium_0 * m_2, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_1, StructuredBuffer<Vector<float, 2> > disp_4, Vector<int32_t, 3>  c_21, float fallback_0)
{
    int32_t _S175 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S175 == int(2))
    {
        Vector<float, 3>  _S176 = Vector<float, 3> {(float)_slang_vector_get_element(c_21, 0), (float)_slang_vector_get_element(c_21, 1), (float)_slang_vector_get_element(c_21, 2)};
        Vector<float, 3>  lo_6 = g_8->origin_0 + _S176 * g_8->cellExtent_0;
        float _S177 = mediumBound_0(m_2, disp_4, lo_6, lo_6 + g_8->cellExtent_0);
        return _S177;
    }
    int32_t _S178 = c_21.x;
    bool _S179;
    if(_S178 < int(0))
    {
        _S179 = true;
    }
    else
    {
        _S179 = (c_21.y) < int(0);
    }
    if(_S179)
    {
        _S179 = true;
    }
    else
    {
        _S179 = (c_21.z) < int(0);
    }
    if(_S179)
    {
        _S179 = true;
    }
    else
    {
        _S179 = _S178 >= (g_8->dims_0.x);
    }
    if(_S179)
    {
        _S179 = true;
    }
    else
    {
        _S179 = (c_21.y) >= (g_8->dims_0.y);
    }
    if(_S179)
    {
        _S179 = true;
    }
    else
    {
        _S179 = (c_21.z) >= (g_8->dims_0.z);
    }
    if(_S179)
    {
        return fallback_0;
    }
    return bounds_1.Load((c_21.z * g_8->dims_0.y + c_21.y) * g_8->dims_0.x + _S178);
}

static float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S180;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S180 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S180 = false;
    }
    if(_S180)
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

static float randFloat_0(Rng_0 * r_4)
{
    uint32_t _S181 = r_4->state_0 * 747796405U + 2891336453U;
    r_4->state_0 = _S181;
    uint32_t word_0 = ((_S181 >> ((_S181 >> 28U) + 4U)) ^ _S181) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static bool segmentStep_0(Medium_0 * m_3, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > drift_2, float scale_0, float tEnd_0, Dda_0 * dda_0, float * rate_0, float * t_4, Rng_0 * rng_0, float * uKeep_0, float * uLive_0, int32_t * budget_0, int32_t * steps_0)
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
        Dda_0 _S182 = *dda_0;
        float _S183 = ddaExit_0(&_S182);
        float _S184 = (F32_min((_S183), (tEnd_0)));
        if(!((*rate_0) > 0.0f))
        {
            if(_S184 >= tEnd_0)
            {
                return false;
            }
            *t_4 = _S184;
            ddaAdvance_0(dda_0);
            float _S185 = gridBound_0(m_3, g_9, bounds_2, drift_2, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S185 * scale_0;
            continue;
        }
        float uStep_0 = randFloat_0(rng_0);
        float _S186 = randFloat_0(rng_0);
        *uKeep_0 = _S186;
        float _S187 = randFloat_0(rng_0);
        *uLive_0 = _S187;
        float _S188 = *t_4 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / *rate_0;
        *t_4 = _S188;
        if(_S188 >= _S184)
        {
            if(_S184 >= tEnd_0)
            {
                return false;
            }
            *t_4 = _S184;
            ddaAdvance_0(dda_0);
            float _S189 = gridBound_0(m_3, g_9, bounds_2, drift_2, dda_0->cell_0, m_3->majorant_0);
            *rate_0 = _S189 * scale_0;
            continue;
        }
        return true;
    }
    return false;
}

static MajorantGrid_0 gridFor_0(Medium_0 * m_4, MajorantGrid_0 * g_10, Vector<float, 3>  p_2)
{
    MajorantGrid_0 chosen_0 = *g_10;
    bool _S190;
    if((g_10->enabled_0) == int(2))
    {
        _S190 = (p_2.y) >= (m_4->slabBottom_0);
    }
    else
    {
        _S190 = false;
    }
    if(_S190)
    {
        _S190 = (p_2.y) <= (m_4->slabTop_0);
    }
    else
    {
        _S190 = false;
    }
    if(_S190)
    {
        (&chosen_0)->enabled_0 = int(0);
    }
    return chosen_0;
}

static float orgWaveFactor_0(Organization_0 * o_8, Vector<float, 2>  q_6)
{
    Vector<float, 2>  unused_0;
    float _S191 = orgWave_0(o_8, q_6, &unused_0);
    return _S191;
}

static float cellField_0(GeneratorInput_0 * g_11, Vector<float, 2>  q_7)
{
    Vector<float, 2>  _S192 = q_7 - g_11->cellDrift_0;
    Vector<float, 2>  _S193 = orgPattern_0(&g_11->gnOrg_0, _S192, g_11->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_1(_S193);
    Vector<int32_t, 2>  _S194 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
    Vector<float, 2>  _S195 = orgJitter_0(&g_11->gnOrg_0, 0.80000001192092896f);
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
            Vector<int32_t, 2>  o_9 = _S194 + Vector<int32_t, 2> (i_14, j_9);
            if((hash22_0(o_9, 2654435769U).x) > (g_11->cellDensity_0))
            {
                i_14 = i_14 + int(1);
                continue;
            }
            Vector<float, 2>  _S196 = Vector<float, 2> {(float)_slang_vector_get_element(o_9, 0), (float)_slang_vector_get_element(o_9, 1)};
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(_S193 - (_S196 + (Vector<float, 2> )0.5f + (hash22_0(o_9, 0U) - (Vector<float, 2> )0.5f) * _S195)) * 2.20000004768371582f);
            i_14 = i_14 + int(1);
        }
        j_9 = j_9 + int(1);
        acc_2 = acc_3;
    }
    float _S197 = acc_2 * g_11->cellStrength_0;
    float _S198 = orgWaveFactor_0(&g_11->gnOrg_0, _S192);
    return _S197 * _S198;
}

static float fbm_0(Vector<float, 3>  p_3, int32_t octaves_1)
{
    int32_t i_15 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S199 = p_3;
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
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S199);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S200 = _S199 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_15 = i_15 + int(1);
        amp_0 = amp_1;
        _S199 = _S200;
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

static float iceDensity_0(GeneratorInput_0 * g_12, StructuredBuffer<Vector<float, 2> > disp_5, Vector<float, 3>  p_4)
{
    float depth_1 = g_12->cellAltitude_0 - p_4.y;
    bool _S201;
    if(depth_1 < 0.0f)
    {
        _S201 = true;
    }
    else
    {
        _S201 = depth_1 > (g_12->streakLength_0);
    }
    if(_S201)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S202 = Vector<float, 2> {p_4.x, p_4.z};
    Vector<float, 2>  _S203 = driftAt_0(g_12, disp_5, depth_1);
    Vector<float, 2>  source_0 = _S202 - _S203;
    float _S204 = cellField_0(g_12, source_0);
    if(_S204 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S204 * (F32_exp((- g_12->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_12->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_12->streakLength_0, g_12->streakLength_0, depth_1)) * (F32_max((1.0f + g_12->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_12->detailScale_0).x, (source_0 / (Vector<float, 2> )g_12->detailScale_0).y, depth_1 / (F32_max((g_12->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_12->timeSeconds_0 * 0.00999999977648258f), g_12->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_12->opticalDepth_0 / (F32_max((g_12->streakLength_0), (1.0f)));
}

static float convUpdraftGrad_0(ConvectionInput_0 * c_22, Vector<float, 2>  q_8, Vector<float, 2>  * grad_5)
{
    if(((&c_22->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S205 = convUpdraftGradT_2(c_22, q_8, grad_5);
        return _S205;
    }
    if((c_22->cvLacunarity_0) <= 0.0f)
    {
        float _S206 = convUpdraftGradT_1(c_22, q_8, grad_5);
        return _S206;
    }
    float _S207 = convUpdraftGradT_0(c_22, q_8, grad_5);
    return _S207;
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
    float _S208;
    if(v_2 >= 0.0f)
    {
        _S208 = d_8;
    }
    else
    {
        _S208 = - d_8;
    }
    return _S208;
}

static Vector<float, 3>  convTwist_0(Vector<float, 3>  x_20)
{
    float _S209 = x_20.x;
    float _S210 = x_20.y;
    float _S211 = x_20.z;
    return Vector<float, 3> (0.0f * _S209 + 0.80000001192092896f * _S210 + 0.60000002384185791f * _S211, -0.80000001192092896f * _S209 + 0.36000001430511475f * _S210 - 0.47999998927116394f * _S211, -0.60000002384185791f * _S209 - 0.47999998927116394f * _S210 + 0.63999998569488525f * _S211);
}

static float convPuffs_0(Vector<float, 3>  x_21)
{
    Vector<float, 3>  fl_0 = floor_0(x_21);
    Vector<int32_t, 3>  _S212 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fl_0, 0), (int32_t)_slang_vector_get_element(fl_0, 1), (int32_t)_slang_vector_get_element(fl_0, 2)};
    Vector<float, 3>  f_1 = x_21 - fl_0;
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
    Vector<int32_t, 3>  _S213 = Vector<int32_t, 3> (dz_0, dy_0, dx_0);
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
                Vector<int32_t, 3>  off_0 = _S213 + Vector<int32_t, 3> (dx_0, dy_0, dz_0);
                Vector<float, 3>  _S214 = Vector<float, 3> {(float)_slang_vector_get_element(off_0, 0), (float)_slang_vector_get_element(off_0, 1), (float)_slang_vector_get_element(off_0, 2)};
                Vector<float, 3>  d_9 = _S214 + (Vector<float, 3> )0.5f + (Vector<float, 3> )0.25f * hash33_0(_S212 + off_0) - f_1;
                float _S215 = (F32_min((nearest_1), (dot_0(d_9, d_9))));
                int32_t dx_1 = dx_0 + int(1);
                nearest_1 = _S215;
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

static float convBillow_0(ConvectionInput_0 * c_23, Vector<float, 3>  p_5, float scale_1)
{
    Vector<float, 3>  _S216 = Vector<float, 3> (p_5.x, p_5.y - c_23->cvRise_0, p_5.z) / (Vector<float, 3> )scale_1;
    int32_t i_16 = int(0);
    Vector<float, 3>  x_22 = _S216;
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
        Vector<float, 3>  x_23 = convTwist_0(x_22);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_23);
        float norm_3 = norm_2 + amp_2;
        Vector<float, 3>  x_24 = x_23 * (Vector<float, 3> )2.17000007629394531f;
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_16 = i_16 + int(1);
        x_22 = x_24;
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

static float convInside_0(ConvectionInput_0 * c_24, float d_10, float lift_0, Vector<float, 3>  x_25, float scale_2)
{
    float _S217 = d_10 + lift_0;
    if(_S217 <= 0.0f)
    {
        return _S217;
    }
    if((d_10 - lift_0) >= 12.0f)
    {
        return 12.0f;
    }
    float _S218 = convBillow_0(c_24, x_25, scale_2);
    return d_10 + lift_0 * _S218;
}

static float convHeroInside_0(ConvectionInput_0 * c_25, Vector<float, 3>  p_6, float above_3)
{
    Vector<float, 2>  rel_0 = Vector<float, 2> {p_6.x, p_6.z} - c_25->cvHeroAt_0;
    float r_5 = length_1(rel_0);
    float _S219 = convHeroReach_0(c_25);
    if(r_5 >= _S219)
    {
        return -1.00000001504746622e+30f;
    }
    float _S220 = convHeroHeight_0(c_25, r_5);
    float v_3 = _S220 - above_3;
    float _S221 = convHeroRadiusAt_0(c_25, above_3);
    float shiftOut_0;
    float shiftUp_0;
    float d_11;
    if(_S221 < 0.0f)
    {
        shiftOut_0 = 0.0f;
        shiftUp_0 = v_3;
        d_11 = v_3;
    }
    else
    {
        float h_3 = _S221 - r_5;
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
        float _S222 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S222;
        d_11 = d_12;
    }
    Vector<float, 2>  radial_0;
    if(r_5 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / (Vector<float, 2> )r_5;
    }
    else
    {
        radial_0 = Vector<float, 2> (0.0f, 0.0f);
    }
    Vector<float, 2>  at_0 = rel_0 + radial_0 * (Vector<float, 2> )shiftOut_0;
    Vector<float, 3>  x_26 = Vector<float, 3> (at_0.x, p_6.y + shiftUp_0, at_0.y) + c_25->cvHeroSeed_0;
    float _S223 = c_25->cvHeroBillow_0;
    float _S224 = convLift_0(c_25, above_3, c_25->cvHeroBillow_0);
    float _S225 = convInside_0(c_25, d_11, _S224, x_26, c_25->cvBillowScale_0 * _S223);
    return _S225;
}

static float convectionDensity_0(ConvectionInput_0 * c_26, Vector<float, 3>  p_7)
{
    float _S226 = p_7.y;
    float above_4 = _S226 - c_26->cvBase_0;
    bool _S227;
    if(above_4 < 0.0f)
    {
        _S227 = true;
    }
    else
    {
        float _S228 = convCeiling_0(c_26);
        _S227 = above_4 > _S228;
    }
    if(_S227)
    {
        return 0.0f;
    }
    float _S229 = convLift_0(c_26, above_4, 1.0f - 0.60000002384185791f * c_26->cvLacunarity_0);
    float inside_2;
    if((c_26->cvHeroAlone_0) == int(0))
    {
        Vector<float, 2>  q_9 = Vector<float, 2> {p_7.x, p_7.z} - c_26->cvDrift_0;
        Vector<float, 2>  slope_1;
        float _S230 = convUpdraftGrad_0(c_26, q_9, &slope_1);
        float _S231 = convTowerHeight_0(c_26, _S230);
        float v_4 = _S231 - above_4;
        float _S232 = convNeededUpdraft_0(c_26, above_4);
        float delta_1 = _S230 - _S232;
        float _S233 = length_1(slope_1);
        float _S234 = convSlopeCap_0(c_26);
        float d_13 = convSurfaceDistance_0(v_4, delta_1, (F32_min((_S233), (_S234))));
        if((d_13 + _S229) > 0.0f)
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
            float _S235 = convInside_0(c_26, d_13, _S229, Vector<float, 3> (q_9.x + shiftAcross_0.x, _S226 + inside_2, q_9.y + shiftAcross_0.y), c_26->cvBillowScale_0);
            inside_2 = _S235;
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
        _S227 = inside_2 < 12.0f;
    }
    else
    {
        _S227 = false;
    }
    if(_S227)
    {
        float _S236 = convHeroInside_0(c_26, p_7, above_4);
        inside_2 = (F32_max((inside_2), (_S236)));
    }
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_26->cvSigma_0 * (F32_sqrt((saturate_0(above_4 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_2);
}

static float densityAt_0(Medium_0 * m_5, StructuredBuffer<Vector<float, 2> > disp_6, Vector<float, 3>  p_8)
{
    float _S237 = p_8.y;
    bool _S238;
    if(_S237 < (m_5->slabBottom_0))
    {
        _S238 = true;
    }
    else
    {
        _S238 = _S237 > (m_5->slabTop_0);
    }
    if(_S238)
    {
        return 0.0f;
    }
    if((m_5->clipOn_0) != int(0))
    {
        Vector<float, 2>  _S239 = Vector<float, 2> {p_8.x, p_8.z};
        if(any_0(_S239 < (m_5->clipLo_0)))
        {
            _S238 = true;
        }
        else
        {
            _S238 = any_0(_S239 > (m_5->clipHi_0));
        }
    }
    else
    {
        _S238 = false;
    }
    if(_S238)
    {
        return 0.0f;
    }
    float _S240 = m_5->fadeRadius_0;
    float fade_0;
    if((m_5->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S240 - length_1(Vector<float, 2> {p_8.x, p_8.z} - m_5->fadeAt_0)) / (F32_max((m_5->fadeWidth_0), (1.0f))));
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
    int32_t _S241 = m_5->mode_0;
    if((m_5->mode_0) == int(0))
    {
        return m_5->density_0 * fade_0;
    }
    if(_S241 == int(2))
    {
        float _S242 = iceDensity_0(&m_5->gen_0, disp_6, p_8);
        return _S242 * fade_0;
    }
    if(_S241 == int(3))
    {
        float _S243 = convectionDensity_0(&m_5->conv_0, p_8);
        return _S243 * fade_0;
    }
    Vector<float, 3>  d_14 = (p_8 - m_5->coreCentre_0) / (Vector<float, 3> )(F32_max((m_5->coreRadius_0), (9.99999997475242708e-07f)));
    return (m_5->density_0 + m_5->coreDensity_0 * (F32_exp((- dot_0(d_14, d_14))))) * fade_0;
}

static float transmittance_0(Medium_0 * m_6, MajorantGrid_0 * g_13, StructuredBuffer<float> bounds_3, StructuredBuffer<Vector<float, 2> > disp_7, Rng_0 * rng_1, Vector<float, 3>  p_9, Vector<float, 3>  dir_0, int32_t * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S244 = slabRange_0(m_6, p_9, dir_0, &t0_2, &t1_2);
    if(!_S244)
    {
        return 1.0f;
    }
    float _S245 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S245;
    Dda_0 _S246 = ddaInit_0(g_13, p_9, dir_0, _S245);
    Dda_0 dda_1 = _S246;
    float _S247 = m_6->majorant_0;
    float _S248 = gridBound_0(m_6, g_13, bounds_3, disp_7, (&dda_1)->cell_0, m_6->majorant_0);
    float localMaj_0 = _S248;
    int32_t i_17 = int(0);
    float t_5 = _S245;
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
        *steps_1 = *steps_1 + int(1);
        Dda_0 _S249 = dda_1;
        float _S250 = ddaExit_0(&_S249);
        float _S251 = (F32_min((_S250), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S251 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S252 = gridBound_0(m_6, g_13, bounds_3, disp_7, (&dda_1)->cell_0, _S247);
            localMaj_0 = _S252;
            t_5 = _S251;
            i_17 = i_17 + int(1);
            continue;
        }
        float _S253 = randFloat_0(rng_1);
        float t_6 = t_5 - (F32_log(((F32_max((1.0f - _S253), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_6 >= _S251)
        {
            if(_S251 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S254 = gridBound_0(m_6, g_13, bounds_3, disp_7, (&dda_1)->cell_0, _S247);
            localMaj_0 = _S254;
            t_5 = _S251;
            i_17 = i_17 + int(1);
            continue;
        }
        float _S255 = densityAt_0(m_6, disp_7, p_9 + dir_0 * (Vector<float, 3> )t_6);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S255 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S256 = randFloat_0(rng_1);
            if(_S256 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_5 = t_6;
        tr_0 = tr_2;
        i_17 = i_17 + int(1);
    }
    return tr_0;
}

static float sceneTransmittance_0(Scene_0 * s_8, StructuredBuffer<float> bounds_4, StructuredBuffer<Vector<float, 2> > drift_3, Rng_0 * rng_2, Vector<float, 3>  p_10, Vector<float, 3>  dir_1, int32_t * steps_2)
{
    float _S257 = transmittance_0(&s_8->medium_0, &s_8->grid_0, bounds_4, drift_3, rng_2, p_10, dir_1, steps_2);
    bool _S258;
    if((s_8->layer2On_0) != int(0))
    {
        _S258 = _S257 > 0.0f;
    }
    else
    {
        _S258 = false;
    }
    float tr_3;
    if(_S258)
    {
        MajorantGrid_0 _S259 = gridFor_0(&s_8->medium2_0, &s_8->grid2_0, p_10);
        MajorantGrid_0 _S260 = _S259;
        float _S261 = transmittance_0(&s_8->medium2_0, &_S260, bounds_4, drift_3, rng_2, p_10, dir_1, steps_2);
        tr_3 = _S257 * _S261;
    }
    else
    {
        tr_3 = _S257;
    }
    return tr_3;
}

static float hg_0(float cosT_0, float g_14)
{
    float _S262 = g_14 * g_14;
    float d_15 = 1.0f + _S262 - 2.0f * g_14 * cosT_0;
    return (1.0f - _S262) / (12.56637096405029297f * d_15 * (F32_sqrt(((F32_max((d_15), (9.99999997475242708e-07f)))))));
}

static float phaseIce_0(float cosT_1)
{
    float t_7 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_0(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_7 * t_7))) * 0.34999999403953552f;
}

static float draine_0(float cosT_2, float g_15, float a_5)
{
    float _S263 = g_15 * g_15;
    float _S264 = 2.0f * g_15;
    float d_16 = 1.0f + _S263 - _S264 * cosT_2;
    return (1.0f - _S263) / (12.56637096405029297f * d_16 * (F32_sqrt(((F32_max((d_16), (9.99999997475242708e-07f))))))) * (1.0f + a_5 * cosT_2 * cosT_2) / (1.0f + a_5 * (1.0f + _S264 * g_15) / 3.0f);
}

static float phaseLiquid_0(PhaseInput_0 * p_11, float cosT_3)
{
    return (1.0f - p_11->draineW_0) * hg_0(cosT_3, p_11->hgG_0) + p_11->draineW_0 * draine_0(cosT_3, p_11->draineG_0, p_11->draineAlpha_0);
}

static float phaseAt_0(PhaseInput_0 * p_12, float cosT_4)
{
    float _S265;
    if((p_12->useIce_0) != int(0))
    {
        _S265 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S266 = phaseLiquid_0(p_12, cosT_4);
        _S265 = _S266;
    }
    return _S265;
}

static float phaseCamera_0(PhaseInput_0 * p_13, float cosT_5)
{
    float _S267 = phaseAt_0(p_13, cosT_5);
    float _S268 = p_13->lobeWeight_0;
    float v_5;
    if((p_13->lobeWeight_0) > 0.0f)
    {
        v_5 = _S267 + _S268 * hg_0(cosT_5, p_13->lobeG_0);
    }
    else
    {
        v_5 = _S267;
    }
    return v_5;
}

static float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_17 = altitude_0 - shellHeight_0;
    return d_17 * (d_17 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static float shellExit_0(float b_4, float c_27)
{
    float disc_0 = b_4 * b_4 - c_27;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_4 + (F32_sqrt((disc_0)));
}

static float shellEnter_0(float b_5, float c_28)
{
    float disc_1 = b_5 * b_5 - c_28;
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

static float altitudeFromQ_0(float q_10, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_10;
    float _S269;
    if(rr_0 > 0.0f)
    {
        _S269 = rr_0;
    }
    else
    {
        _S269 = 0.0f;
    }
    return q_10 / (planetRadius_2 + (F32_sqrt((_S269))));
}

static Vector<float, 3>  airTransmittance_0(SkyInput_0 * p_14, float originAltitude_0, Vector<float, 3>  rayDir_0, float dist_1)
{
    float _S270 = p_14->planetRadius_0;
    float planetRadius_3;
    if((p_14->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S270;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S271 = p_14->scaleHeight_0;
    float scaleHeight_1;
    if((p_14->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S271;
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
    float b_6 = (planetRadius_3 + observerAltitude_0) * rayDir_0.y;
    float cGround_0 = shellC_0(observerAltitude_0, planetRadius_3, 0.0f);
    float tTop_0 = shellExit_0(b_6, shellC_0(observerAltitude_0, planetRadius_3, atmosphereHeight_0));
    bool _S272;
    if(tTop_0 <= 0.0f)
    {
        _S272 = true;
    }
    else
    {
        _S272 = !(dist_1 > 0.0f);
    }
    if(_S272)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float tGround_0 = shellEnter_0(b_6, cGround_0);
    float tMax_1;
    if(tGround_0 > 0.0f)
    {
        tMax_1 = tGround_0;
    }
    else
    {
        tMax_1 = tTop_0;
    }
    if(dist_1 < tMax_1)
    {
        tMax_1 = dist_1;
    }
    Vector<float, 3>  betaR_0 = rayleighCoefficients_0();
    float betaMExt_0 = mieCoefficient_0(p_14->turbidity_0) * 1.11000001430511475f;
    float tPrev_0 = 0.0f;
    int32_t i_18 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_18 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S273 = i_18 + int(1);
        float tNext_0 = tMax_1 * float(_S273 * _S273) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_18 = _S273;
            continue;
        }
        float h_4 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_6 + tMid_0 * tMid_0, planetRadius_3);
        float hc_0;
        if(h_4 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_4;
        }
        float _S274 = - hc_0;
        float depthM_1 = depthM_0 + (F32_exp((_S274 / 1200.0f))) * dt_0;
        depthR_0 = depthR_0 + (F32_exp((_S274 / scaleHeight_1))) * dt_0;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_18 = _S273;
    }
    float _S275 = betaMExt_0 * depthM_0;
    return Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S275)))), (F32_exp((- (betaR_0.y * depthR_0 + _S275)))), (F32_exp((- (betaR_0.z * depthR_0 + _S275)))));
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
    float _S276;
    if(len_0 > 1.0f)
    {
        _S276 = dot_0(geocentric_0, sun_0) / len_0;
    }
    else
    {
        _S276 = dot_0(geocentric_0, sun_0);
    }
    return _S276;
}

static float clampf_0(float v_7, float lo_7, float hi_6)
{
    float _S277;
    if(v_7 < lo_7)
    {
        _S277 = lo_7;
    }
    else
    {
        if(v_7 > hi_6)
        {
            _S277 = hi_6;
        }
        else
        {
            _S277 = v_7;
        }
    }
    return _S277;
}

static Vector<float, 3>  sampleTransmittanceLut_0(SkyInput_0 * p_17, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S278 = p_17->transmittanceLut_0;
    if(uint32_t(StructuredBuffer_getCount_0(p_17->transmittanceLut_0)) < 49152U)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float _S279 = p_17->scaleHeight_0;
    float scaleHeight_2;
    if((p_17->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S279;
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
    float _S280 = fx_1 - float(x0_1);
    float _S281 = fy_1 - float(y0_1);
    int32_t _S282 = y0_1 * int(256);
    int32_t _S283 = (_S282 + x0_1) * int(3);
    int32_t _S284 = (_S282 + x1_1) * int(3);
    int32_t _S285 = y1_1 * int(256);
    int32_t _S286 = (_S285 + x0_1) * int(3);
    int32_t _S287 = (_S285 + x1_1) * int(3);
    Vector<float, 3>  out_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    int32_t c_29 = int(0);
    for(;;)
    {
        if(c_29 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S288 = 1.0f - _S280;
        float r_6 = (_S278.Load(_S283 + c_29) * _S288 + _S278.Load(_S284 + c_29) * _S280) * (1.0f - _S281) + (_S278.Load(_S286 + c_29) * _S288 + _S278.Load(_S287 + c_29) * _S280) * _S281;
        if(c_29 == int(0))
        {
            out_0.x = r_6;
        }
        else
        {
            if(c_29 == int(1))
            {
                out_0.y = r_6;
            }
            else
            {
                out_0.z = r_6;
            }
        }
        c_29 = c_29 + int(1);
    }
    return out_0;
}

static Vector<float, 3>  sunTransmittanceAt_0(SkyInput_0 * p_18, Vector<float, 3>  worldPos_0)
{
    Vector<float, 3>  _S289 = sunDirection_0(p_18);
    float _S290 = p_18->planetRadius_0;
    float planetRadius_4;
    if((p_18->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S290;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S291 = worldPos_0.y;
    float altitude_2;
    if(_S291 > 0.0f)
    {
        altitude_2 = _S291;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    Vector<float, 3>  _S292 = sampleTransmittanceLut_0(p_18, altitude_2, lutMuFor_0(Vector<float, 3> (worldPos_0.x, planetRadius_4 + _S291, worldPos_0.z), _S289));
    return _S292;
}

static Vector<float, 3>  sunIrradianceAt_0(Scene_0 * s_9, Vector<float, 3>  p_19)
{
    if(((&s_9->environment_0)->envMode_0) == int(1))
    {
        float _S293 = sunIrradianceTop_0(&(&s_9->environment_0)->sky_0);
        Vector<float, 3>  _S294 = sunTransmittanceAt_0(&(&s_9->environment_0)->sky_0, p_19);
        return (Vector<float, 3> )_S293 * _S294;
    }
    return s_9->sunIrradiance_0;
}

static Vector<float, 3>  cameraSegmentSun_0(Scene_0 * s_10, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_5, StructuredBuffer<Vector<float, 2> > drift_4, Rng_0 * rng_3, Rng_0 * rng2_0, Vector<float, 3>  ro_2, Vector<float, 3>  rd_2, int32_t * steps_3)
{
    float ph0_0;
    float kept_0;
    float keptT_0;
    Vector<float, 3>  keptAt_0;
    int32_t keptLayer_0;
    Rng_0 _S295 = *rng2_0;
    Vector<float, 3>  none_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float _S296 = (F32_max((s_10->neeTentativeScale_0), (1.0f)));
    float tA_0;
    float endA_0;
    bool _S297 = slabRange_0(&s_10->medium_0, ro_2, rd_2, &tA_0, &endA_0);
    float _S298 = (F32_max((tA_0), (0.0f)));
    tA_0 = _S298;
    Dda_0 _S299 = ddaInit_0(&s_10->grid_0, ro_2, rd_2, _S298);
    Dda_0 ddaA_0 = _S299;
    float _S300 = gridBound_0(&s_10->medium_0, &s_10->grid_0, bounds_5, drift_4, (&ddaA_0)->cell_0, (&s_10->medium_0)->majorant_0);
    float rateA_0 = _S300 * _S296;
    int32_t budgetA_0 = int(4096);
    float keepA_0 = 0.0f;
    float rouletteA_0 = 0.0f;
    bool haveA_0;
    if(_S297)
    {
        bool _S301 = segmentStep_0(&s_10->medium_0, &s_10->grid_0, bounds_5, drift_4, _S296, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
        haveA_0 = _S301;
    }
    else
    {
        haveA_0 = _S297;
    }
    float tB_0 = 0.0f;
    float endB_0 = 0.0f;
    bool haveB_0;
    if((s_10->layer2On_0) != int(0))
    {
        bool _S302 = slabRange_0(&s_10->medium2_0, ro_2, rd_2, &tB_0, &endB_0);
        haveB_0 = _S302;
    }
    else
    {
        haveB_0 = false;
    }
    float _S303 = (F32_max((tB_0), (0.0f)));
    tB_0 = _S303;
    MajorantGrid_0 _S304 = gridFor_0(&s_10->medium2_0, &s_10->grid2_0, ro_2);
    MajorantGrid_0 _S305 = _S304;
    Dda_0 _S306 = ddaInit_0(&_S305, ro_2, rd_2, _S303);
    Dda_0 ddaB_0 = _S306;
    MajorantGrid_0 _S307 = _S304;
    float _S308 = gridBound_0(&s_10->medium2_0, &_S307, bounds_5, drift_4, (&ddaB_0)->cell_0, (&s_10->medium2_0)->majorant_0);
    float rateB_0 = _S308 * _S296;
    int32_t budgetB_0 = int(4096);
    float keepB_0 = 0.0f;
    float rouletteB_0 = 0.0f;
    if(haveB_0)
    {
        MajorantGrid_0 _S309 = _S304;
        bool _S310 = segmentStep_0(&s_10->medium2_0, &_S309, bounds_5, drift_4, _S296, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S295, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
        haveB_0 = _S310;
    }
    float kept_1 = 0.0f;
    Vector<float, 3>  keptAt_1 = none_0;
    int32_t keptLayer_1 = int(0);
    float keptT_1 = 0.0f;
    float tr_4 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        bool _S311;
        if(haveA_0)
        {
            _S311 = true;
        }
        else
        {
            _S311 = haveB_0;
        }
        if(_S311)
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
            float _S312 = densityAt_0(&s_10->medium_0, drift_4, p_20);
            sigma_0 = _S312;
        }
        else
        {
            float _S313 = densityAt_0(&s_10->medium2_0, drift_4, p_20);
            sigma_0 = _S313;
        }
        if(sigma_0 > 0.0f)
        {
            float w_2 = sigma_0 / rate_1;
            float b_7 = tr_4 * w_2;
            float total_1;
            if(b_7 > 0.0f)
            {
                float total_2 = total_0 + b_7;
                if((uKeep_1 * total_2) < b_7)
                {
                    if(takeA_0)
                    {
                        keptLayer_0 = int(0);
                    }
                    else
                    {
                        keptLayer_0 = int(1);
                    }
                    kept_0 = b_7;
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
            float tr_5 = tr_4 * (F32_max((0.0f), (1.0f - w_2)));
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
            bool _S314 = segmentStep_0(&s_10->medium_0, &s_10->grid_0, bounds_5, drift_4, _S296, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_3, &keepA_0, &rouletteA_0, &budgetA_0, steps_3);
            haveA_0 = _S314;
        }
        else
        {
            MajorantGrid_0 _S315 = _S304;
            bool _S316 = segmentStep_0(&s_10->medium2_0, &_S315, bounds_5, drift_4, _S296, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S295, &keepB_0, &rouletteB_0, &budgetB_0, steps_3);
            haveB_0 = _S316;
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
    Vector<float, 3>  _S317 = s_10->sunDir_0;
    float _S318 = sceneTransmittance_0(s_10, bounds_5, drift_4, rng_3, keptAt_0 + s_10->sunDir_0 * (Vector<float, 3> )s_10->shadowOffset_0, s_10->sunDir_0, steps_3);
    Vector<float, 3>  _S319 = s_10->albedo_0;
    Vector<float, 3>  matterAlbedo_0;
    if(keptLayer_0 == int(0))
    {
        float _S320 = phaseCamera_0(ph_0, dot_0(rd_2, _S317));
        matterAlbedo_0 = _S319;
        ph0_0 = _S320;
    }
    else
    {
        float _S321 = phaseCamera_0(&s_10->phase2_0, dot_0(rd_2, _S317));
        matterAlbedo_0 = s_10->albedo2_0;
        ph0_0 = _S321;
    }
    Vector<float, 3>  _S322 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    if(((&s_10->environment_0)->envMode_0) == int(1))
    {
        haveA_0 = (s_10->aerialMode_0) != int(0);
    }
    else
    {
        haveA_0 = false;
    }
    Vector<float, 3>  air_0;
    if(haveA_0)
    {
        Vector<float, 3>  _S323 = airTransmittance_0(&(&s_10->environment_0)->sky_0, ro_2.y, rd_2, keptT_0);
        air_0 = _S323;
    }
    else
    {
        air_0 = _S322;
    }
    Vector<float, 3>  _S324 = (Vector<float, 3> )total_0 * matterAlbedo_0 * (Vector<float, 3> )ph0_0 * (Vector<float, 3> )_S318;
    Vector<float, 3>  _S325 = sunIrradianceAt_0(s_10, keptAt_0);
    return _S324 * _S325 * air_0;
}

static bool sampleFreeFlightUpTo_0(Medium_0 * m_7, MajorantGrid_0 * g_16, StructuredBuffer<float> bounds_6, StructuredBuffer<Vector<float, 2> > disp_8, Rng_0 * rng_4, Vector<float, 3>  ro_3, Vector<float, 3>  rd_3, float tLimit_0, Vector<float, 3>  * scatterPoint_0, float * distance_0, int32_t * steps_4)
{
    *scatterPoint_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_3;
    float t1_3;
    bool _S326 = slabRange_0(m_7, ro_3, rd_3, &t0_3, &t1_3);
    if(!_S326)
    {
        return false;
    }
    float _S327 = (F32_min((t1_3), (tLimit_0)));
    t1_3 = _S327;
    if(!(_S327 > t0_3))
    {
        return false;
    }
    float _S328 = (F32_max((t0_3), (0.0f)));
    Dda_0 _S329 = ddaInit_0(g_16, ro_3, rd_3, _S328);
    Dda_0 dda_2 = _S329;
    float _S330 = m_7->majorant_0;
    float _S331 = gridBound_0(m_7, g_16, bounds_6, disp_8, (&dda_2)->cell_0, m_7->majorant_0);
    float localMaj_1 = _S331;
    int32_t i_19 = int(0);
    float t_8 = _S328;
    for(;;)
    {
        if(i_19 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_4 = *steps_4 + int(1);
        Dda_0 _S332 = dda_2;
        float _S333 = ddaExit_0(&_S332);
        float _S334 = (F32_min((_S333), (t1_3)));
        if(localMaj_1 <= 0.0f)
        {
            if(_S334 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S335 = gridBound_0(m_7, g_16, bounds_6, disp_8, (&dda_2)->cell_0, _S330);
            localMaj_1 = _S335;
            t_8 = _S334;
            i_19 = i_19 + int(1);
            continue;
        }
        float _S336 = randFloat_0(rng_4);
        float t_9 = t_8 - (F32_log(((F32_max((1.0f - _S336), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_9 >= _S334)
        {
            if(_S334 >= t1_3)
            {
                return false;
            }
            ddaAdvance_0(&dda_2);
            float _S337 = gridBound_0(m_7, g_16, bounds_6, disp_8, (&dda_2)->cell_0, _S330);
            localMaj_1 = _S337;
            t_8 = _S334;
            i_19 = i_19 + int(1);
            continue;
        }
        Vector<float, 3>  p_21 = ro_3 + rd_3 * (Vector<float, 3> )t_9;
        float _S338 = randFloat_0(rng_4);
        float _S339 = densityAt_0(m_7, disp_8, p_21);
        if(_S338 < (_S339 / localMaj_1))
        {
            *scatterPoint_0 = p_21;
            *distance_0 = t_9;
            return true;
        }
        t_8 = t_9;
        i_19 = i_19 + int(1);
    }
    return false;
}

static bool sampleFreeFlight_0(Medium_0 * m_8, MajorantGrid_0 * g_17, StructuredBuffer<float> bounds_7, StructuredBuffer<Vector<float, 2> > disp_9, Rng_0 * rng_5, Vector<float, 3>  ro_4, Vector<float, 3>  rd_4, Vector<float, 3>  * scatterPoint_1, float * distance_1, int32_t * steps_5)
{
    bool _S340 = sampleFreeFlightUpTo_0(m_8, g_17, bounds_7, disp_9, rng_5, ro_4, rd_4, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_5);
    return _S340;
}

static bool sceneFreeFlight_0(Scene_0 * s_11, StructuredBuffer<float> bounds_8, StructuredBuffer<Vector<float, 2> > drift_5, Rng_0 * rng_6, Vector<float, 3>  ro_5, Vector<float, 3>  rd_5, Vector<float, 3>  * scatterAt_0, int32_t * layer_0, int32_t * steps_6)
{
    *layer_0 = int(0);
    float dist_2;
    if((s_11->layer2On_0) == int(0))
    {
        bool _S341 = sampleFreeFlight_0(&s_11->medium_0, &s_11->grid_0, bounds_8, drift_5, rng_6, ro_5, rd_5, scatterAt_0, &dist_2, steps_6);
        return _S341;
    }
    float a0_0;
    float a1_0;
    bool _S342 = slabRange_0(&s_11->medium_0, ro_5, rd_5, &a0_0, &a1_0);
    float b0_0;
    float b1_0;
    bool _S343 = slabRange_0(&s_11->medium2_0, ro_5, rd_5, &b0_0, &b1_0);
    bool secondFirst_0;
    if(_S343)
    {
        if(!_S342)
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
    MajorantGrid_0 _S344 = gridFor_0(&s_11->medium2_0, &s_11->grid2_0, ro_5);
    float _S345;
    if(secondFirst_0)
    {
        MajorantGrid_0 _S346 = _S344;
        bool _S347 = sampleFreeFlight_0(&s_11->medium2_0, &_S346, bounds_8, drift_5, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S347)
        {
            _S345 = dNear_1;
        }
        else
        {
            _S345 = 1.00000001504746622e+30f;
        }
        bool _S348 = sampleFreeFlightUpTo_0(&s_11->medium_0, &s_11->grid_0, bounds_8, drift_5, rng_6, ro_5, rd_5, _S345, &pFar_0, &dFar_0, steps_6);
        if(_S348)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(0);
            return true;
        }
        if(_S347)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(1);
            return true;
        }
    }
    else
    {
        bool _S349 = sampleFreeFlight_0(&s_11->medium_0, &s_11->grid_0, bounds_8, drift_5, rng_6, ro_5, rd_5, &pNear_0, &dNear_1, steps_6);
        if(_S349)
        {
            _S345 = dNear_1;
        }
        else
        {
            _S345 = 1.00000001504746622e+30f;
        }
        MajorantGrid_0 _S350 = _S344;
        bool _S351 = sampleFreeFlightUpTo_0(&s_11->medium2_0, &_S350, bounds_8, drift_5, rng_6, ro_5, rd_5, _S345, &pFar_0, &dFar_0, steps_6);
        if(_S351)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(1);
            return true;
        }
        if(_S349)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(0);
            return true;
        }
    }
    *scatterAt_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    return false;
}

static Vector<float, 2>  airMapAxisV_0(LayerShadowMap_0 * m_9)
{
    return Vector<float, 2> (- m_9->smAxisU_0.y, m_9->smAxisU_0.x);
}

static float airMapTexel_0(LayerShadowMap_0 * m_10, int32_t iu_0, int32_t iv_0, int32_t k_3)
{
    return m_10->smTexels_0.Load((k_3 * m_10->smDimV_0 + iv_0) * m_10->smDimU_0 + iu_0);
}

static float layerMapTransmittance_0(LayerShadowMap_0 * m_11, Vector<float, 3>  p_22)
{
    int32_t _S352 = m_11->smDimU_0;
    int32_t _S353 = m_11->smDimV_0;
    int32_t _S354 = m_11->smSlices_0;
    uint32_t want_0 = uint32_t(m_11->smDimU_0 * m_11->smDimV_0 * m_11->smSlices_0);
    bool _S355;
    if(want_0 == 0U)
    {
        _S355 = true;
    }
    else
    {
        _S355 = uint32_t(StructuredBuffer_getCount_0(m_11->smTexels_0)) < want_0;
    }
    if(_S355)
    {
        return 1.0f;
    }
    float _S356 = p_22.y;
    float _S357 = m_11->smTop_0;
    if(_S356 >= (m_11->smTop_0))
    {
        return 1.0f;
    }
    Vector<float, 3>  _S358 = m_11->smSun_0;
    float _S359 = m_11->smBottom_0;
    Vector<float, 2>  q_11 = Vector<float, 2> {p_22.x, p_22.z} + Vector<float, 2> {_S358.x, _S358.z} * (Vector<float, 2> )((m_11->smBottom_0 - _S356) / m_11->smSun_0.y) - m_11->smCentre_0;
    Vector<float, 2>  _S360 = m_11->smLo_0;
    Vector<float, 2>  _S361 = m_11->smTexel_0;
    float fu_0 = (dot_1(q_11, m_11->smAxisU_0) - m_11->smLo_0.x) / m_11->smTexel_0.x - 0.5f;
    Vector<float, 2>  _S362 = airMapAxisV_0(m_11);
    float fv_0 = (dot_1(q_11, _S362) - _S360.y) / _S361.y - 0.5f;
    if(fu_0 >= -0.5f)
    {
        _S355 = fv_0 >= -0.5f;
    }
    else
    {
        _S355 = false;
    }
    if(_S355)
    {
        _S355 = fu_0 <= (float(_S352) - 0.5f);
    }
    else
    {
        _S355 = false;
    }
    if(_S355)
    {
        _S355 = fv_0 <= (float(_S353) - 0.5f);
    }
    else
    {
        _S355 = false;
    }
    if(!_S355)
    {
        return 1.0f;
    }
    int32_t _S363 = _S352 - int(1);
    float fu_1 = clampf_0(fu_0, 0.0f, float(_S363));
    int32_t _S364 = _S353 - int(1);
    float fv_1 = clampf_0(fv_0, 0.0f, float(_S364));
    int32_t u0_0 = int32_t(fu_1);
    int32_t v0_0 = int32_t(fv_1);
    int32_t _S365 = (I32_min((u0_0 + int(1)), (_S363)));
    int32_t _S366 = (I32_min((v0_0 + int(1)), (_S364)));
    float tu_0 = fu_1 - float(u0_0);
    float tv_0 = fv_1 - float(v0_0);
    int32_t _S367 = _S354 - int(1);
    float fk_0 = clampf_0((_S356 - _S359) / (F32_max((_S357 - _S359), (1.0f))), 0.0f, 1.0f) * float(_S367);
    int32_t _S368 = (I32_min((int32_t(fk_0)), (_S367)));
    int32_t _S369 = (I32_min((_S368 + int(1)), (_S367)));
    float tk_0 = fk_0 - float(_S368);
    float _S370 = airMapTexel_0(m_11, u0_0, v0_0, _S368);
    float _S371 = 1.0f - tu_0;
    float _S372 = _S370 * _S371;
    float _S373 = airMapTexel_0(m_11, _S365, v0_0, _S368);
    float a0_1 = _S372 + _S373 * tu_0;
    float _S374 = airMapTexel_0(m_11, u0_0, _S366, _S368);
    float _S375 = _S374 * _S371;
    float _S376 = airMapTexel_0(m_11, _S365, _S366, _S368);
    float b0_1 = _S375 + _S376 * tu_0;
    float _S377 = airMapTexel_0(m_11, u0_0, v0_0, _S369);
    float _S378 = _S377 * _S371;
    float _S379 = airMapTexel_0(m_11, _S365, v0_0, _S369);
    float a1_1 = _S378 + _S379 * tu_0;
    float _S380 = airMapTexel_0(m_11, u0_0, _S366, _S369);
    float _S381 = _S380 * _S371;
    float _S382 = airMapTexel_0(m_11, _S365, _S366, _S369);
    float _S383 = 1.0f - tv_0;
    return (a0_1 * _S383 + b0_1 * tv_0) * (1.0f - tk_0) + (a1_1 * _S383 + (_S381 + _S382 * tu_0) * tv_0) * tk_0;
}

static float groundShadow_0(LayerShadowMap_0 * mapA_0, LayerShadowMap_0 * mapB_0, Vector<float, 3>  origin_1, Vector<float, 3>  dir_2)
{
    float _S384 = dir_2.y;
    bool _S385;
    if(!(_S384 < 0.0f))
    {
        _S385 = true;
    }
    else
    {
        _S385 = !((origin_1.y) > 0.0f);
    }
    if(_S385)
    {
        return 1.0f;
    }
    Vector<float, 3>  ground_0 = origin_1 + dir_2 * (Vector<float, 3> )(origin_1.y / - _S384);
    ground_0.y = 0.0f;
    float _S386 = layerMapTransmittance_0(mapA_0, ground_0);
    float _S387 = layerMapTransmittance_0(mapB_0, ground_0);
    return _S386 * _S387;
}

static Vector<float, 3>  skyRadiance_0(SkyInput_0 * p_23, float originAltitude_1, Vector<float, 3>  rayDir_1, bool includeSunDisc_0, float groundLit_0)
{
    float hc_1;
    Vector<float, 3>  _S388 = sunDirection_0(p_23);
    float _S389 = p_23->planetRadius_0;
    float planetRadius_5;
    if((p_23->planetRadius_0) > 1000.0f)
    {
        planetRadius_5 = _S389;
    }
    else
    {
        planetRadius_5 = 1000.0f;
    }
    float _S390 = p_23->scaleHeight_0;
    float scaleHeight_3;
    if((p_23->scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = _S390;
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
    float _S391 = planetRadius_5 + observerAltitude_1;
    float _S392 = rayDir_1.y;
    float b_8 = _S391 * _S392;
    float cGround_1 = shellC_0(observerAltitude_1, planetRadius_5, 0.0f);
    float tTop_1 = shellExit_0(b_8, shellC_0(observerAltitude_1, planetRadius_5, atmosphereHeight_1));
    if(tTop_1 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 0.0f, 0.0f);
    }
    float tGround_1 = shellEnter_0(b_8, cGround_1);
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
    float betaM_0 = mieCoefficient_0(p_23->turbidity_0);
    float betaMExt_1 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_1, _S388), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_18 = clampf_0(p_23->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S393 = g_18 * g_18;
    float hgDenom_0 = 1.0f + _S393 - 2.0f * g_18 * cosTheta_0;
    float _S394 = 1.0f - _S393;
    float _S395 = 12.56637096405029297f * hgDenom_0;
    float tPrev_1;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        tPrev_1 = hgDenom_0;
    }
    else
    {
        tPrev_1 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S394 / (_S395 * (F32_sqrt((tPrev_1))));
    Vector<float, 3>  _S396 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    tPrev_1 = 0.0f;
    Vector<float, 3>  sumR_0 = _S396;
    Vector<float, 3>  sumM_0 = _S396;
    int32_t i_20 = int(0);
    float depthR_1 = 0.0f;
    float depthM_2 = 0.0f;
    for(;;)
    {
        if(i_20 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S397 = i_20 + int(1);
        float tNext_1 = observerAltitude_1 * float(_S397 * _S397) * 0.00173611112404615f;
        float dt_1 = tNext_1 - tPrev_1;
        float tMid_1 = (tPrev_1 + tNext_1) * 0.5f;
        if(dt_1 <= 0.0f)
        {
            tPrev_1 = tNext_1;
            i_20 = _S397;
            continue;
        }
        float h_5 = altitudeFromQ_0(cGround_1 + 2.0f * tMid_1 * b_8 + tMid_1 * tMid_1, planetRadius_5);
        if(h_5 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_5;
        }
        float _S398 = - hc_1;
        float dR_0 = (F32_exp((_S398 / scaleHeight_3))) * dt_1;
        float dM_0 = (F32_exp((_S398 / 1200.0f))) * dt_1;
        float midR_0 = depthR_1 + 0.5f * dR_0;
        float midM_0 = depthM_2 + 0.5f * dM_0;
        float depthR_2 = depthR_1 + dR_0;
        float depthM_3 = depthM_2 + dM_0;
        Vector<float, 3>  _S399 = sampleTransmittanceLut_0(p_23, hc_1, lutMuFor_0(Vector<float, 3> (rayDir_1.x * tMid_1, _S391 + _S392 * tMid_1, rayDir_1.z * tMid_1), _S388));
        float _S400 = betaMExt_1 * midM_0;
        Vector<float, 3>  transmittance_1 = Vector<float, 3> ((F32_exp((- (betaR_1.x * midR_0 + _S400)))), (F32_exp((- (betaR_1.y * midR_0 + _S400)))), (F32_exp((- (betaR_1.z * midR_0 + _S400))))) * _S399;
        Vector<float, 3>  _S401 = sumM_0 + transmittance_1 * (Vector<float, 3> )dM_0;
        sumR_0 = sumR_0 + transmittance_1 * (Vector<float, 3> )dR_0;
        sumM_0 = _S401;
        depthR_1 = depthR_2;
        depthM_2 = depthM_3;
        tPrev_1 = tNext_1;
        i_20 = _S397;
    }
    float _S402 = sunIrradianceTop_0(p_23);
    Vector<float, 3>  radiance_0 = (sumR_0 * betaR_1 * (Vector<float, 3> )phaseR_0 + sumM_0 * (Vector<float, 3> )(betaM_0 * phaseM_0)) * (Vector<float, 3> )_S402;
    Vector<float, 3>  radiance_1;
    if(hitsGround_0)
    {
        Vector<float, 3>  groundPoint_0 = Vector<float, 3> (rayDir_1.x * tGround_1, _S391 + _S392 * tGround_1, rayDir_1.z * tGround_1);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S388), 0.0f, 1.0f);
        Vector<float, 3>  _S403 = sampleTransmittanceLut_0(p_23, 0.0f, lutMuFor_0(groundPoint_0, _S388));
        float _S404 = betaMExt_1 * depthM_2;
        Vector<float, 3>  viewT_0 = Vector<float, 3> ((F32_exp((- (betaR_1.x * depthR_1 + _S404)))), (F32_exp((- (betaR_1.y * depthR_1 + _S404)))), (F32_exp((- (betaR_1.z * depthR_1 + _S404)))));
        radiance_1 = radiance_0 + viewT_0 * _S403 * (Vector<float, 3> )(p_23->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S402 * groundLit_0) + viewT_0 * p_23->groundSkyLight_0;
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S405;
    if(!hitsGround_0)
    {
        _S405 = includeSunDisc_0;
    }
    else
    {
        _S405 = false;
    }
    if(_S405)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_23->sunAngularRadius_0))));
        if(cosTheta_0 > cosRadius_0)
        {
            float _S406 = betaMExt_1 * depthM_2;
            Vector<float, 3>  viewT_1 = Vector<float, 3> ((F32_exp((- (betaR_1.x * depthR_1 + _S406)))), (F32_exp((- (betaR_1.y * depthR_1 + _S406)))), (F32_exp((- (betaR_1.z * depthR_1 + _S406)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_1 = solidAngle_0;
            }
            else
            {
                hc_1 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_1 * (Vector<float, 3> )(_S402 / hc_1);
        }
    }
    return radiance_1;
}

static Vector<float, 3>  environmentRadiance_0(Environment_0 * e_0, Vector<float, 3>  origin_2, Vector<float, 3>  dir_3, bool includeSunDisc_1, float groundLit_1)
{
    if((e_0->envMode_0) == int(1))
    {
        Vector<float, 3>  _S407 = skyRadiance_0(&e_0->sky_0, origin_2.y, dir_3, includeSunDisc_1, groundLit_1);
        return _S407;
    }
    return e_0->uniformRadiance_0;
}

static bool layerMapRange_0(LayerShadowMap_0 * m_12, Vector<float, 3>  ro_6, Vector<float, 3>  rd_6, float * t0_4, float * t1_4)
{
    *t0_4 = 0.0f;
    *t1_4 = 1.00000001504746622e+30f;
    int32_t _S408 = m_12->smDimU_0;
    int32_t _S409 = m_12->smDimV_0;
    uint32_t want_1 = uint32_t(m_12->smDimU_0 * m_12->smDimV_0 * m_12->smSlices_0);
    bool _S410;
    if(want_1 == 0U)
    {
        _S410 = true;
    }
    else
    {
        _S410 = uint32_t(StructuredBuffer_getCount_0(m_12->smTexels_0)) < want_1;
    }
    if(_S410)
    {
        return false;
    }
    float _S411 = rd_6.y;
    if((F32_abs((_S411))) < 9.99999971718068537e-10f)
    {
        if((ro_6.y) >= (m_12->smTop_0))
        {
            return false;
        }
    }
    else
    {
        float tt_0 = (m_12->smTop_0 - ro_6.y) / _S411;
        if(_S411 > 0.0f)
        {
            *t1_4 = (F32_min((*t1_4), (tt_0)));
        }
        else
        {
            *t0_4 = (F32_max((*t0_4), (tt_0)));
        }
    }
    Vector<float, 3>  _S412 = m_12->smSun_0;
    Vector<float, 2>  _S413 = Vector<float, 2> {_S412.x, _S412.z};
    float _S414 = m_12->smSun_0.y;
    Vector<float, 2>  q0_3 = Vector<float, 2> {ro_6.x, ro_6.z} + _S413 * (Vector<float, 2> )((m_12->smBottom_0 - ro_6.y) / _S414) - m_12->smCentre_0;
    Vector<float, 2>  dq_0 = Vector<float, 2> {rd_6.x, rd_6.z} - _S413 * (Vector<float, 2> )(_S411 / _S414);
    Vector<float, 2>  _S415 = airMapAxisV_0(m_12);
    float _S416 = m_12->smLo_0.x;
    float _S417 = m_12->smLo_0.y;
    float vHi_0 = _S417 + float(_S409) * m_12->smTexel_0.y;
    bool _S418 = clipAxis_0(dot_1(q0_3, m_12->smAxisU_0), dot_1(dq_0, m_12->smAxisU_0), _S416, _S416 + float(_S408) * m_12->smTexel_0.x, t0_4, t1_4);
    if(!_S418)
    {
        return false;
    }
    bool _S419 = clipAxis_0(dot_1(q0_3, _S415), dot_1(dq_0, _S415), _S417, vHi_0, t0_4, t1_4);
    if(!_S419)
    {
        return false;
    }
    return (*t1_4) > (*t0_4);
}

static Vector<float, 3>  airShadowLoss_0(SkyInput_0 * p_24, LayerShadowMap_0 * mapA_1, LayerShadowMap_0 * mapB_1, Vector<float, 3>  ro_7, Vector<float, 3>  rd_7, float dist_3, float jitter_1)
{
    Vector<float, 3>  none_1 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float r0_0;
    float r1_0;
    bool _S420 = layerMapRange_0(mapA_1, ro_7, rd_7, &r0_0, &r1_0);
    float tA_1;
    float tB_1;
    if(_S420)
    {
        float _S421 = (F32_max((-1.00000001504746622e+30f), (r1_0)));
        tA_1 = (F32_min((1.00000001504746622e+30f), (r0_0)));
        tB_1 = _S421;
    }
    else
    {
        tA_1 = 1.00000001504746622e+30f;
        tB_1 = -1.00000001504746622e+30f;
    }
    bool _S422 = layerMapRange_0(mapB_1, ro_7, rd_7, &r0_0, &r1_0);
    if(_S422)
    {
        float _S423 = (F32_min((tA_1), (r0_0)));
        tB_1 = (F32_max((tB_1), (r1_0)));
        tA_1 = _S423;
    }
    if(!(tB_1 > tA_1))
    {
        return none_1;
    }
    Vector<float, 3>  _S424 = sunDirection_0(p_24);
    float _S425 = p_24->planetRadius_0;
    float planetRadius_6;
    if((p_24->planetRadius_0) > 1000.0f)
    {
        planetRadius_6 = _S425;
    }
    else
    {
        planetRadius_6 = 1000.0f;
    }
    float _S426 = p_24->scaleHeight_0;
    float scaleHeight_4;
    if((p_24->scaleHeight_0) > 1.0f)
    {
        scaleHeight_4 = _S426;
    }
    else
    {
        scaleHeight_4 = 1.0f;
    }
    float atmosphereHeight_2 = scaleHeight_4 * 8.0f;
    float _S427 = ro_7.y;
    float observerAltitude_2;
    if(_S427 > 0.0f)
    {
        observerAltitude_2 = _S427;
    }
    else
    {
        observerAltitude_2 = 0.0f;
    }
    float _S428 = planetRadius_6 + observerAltitude_2;
    float _S429 = rd_7.y;
    float b_9 = _S428 * _S429;
    float cGround_2 = shellC_0(observerAltitude_2, planetRadius_6, 0.0f);
    float tTop_2 = shellExit_0(b_9, shellC_0(observerAltitude_2, planetRadius_6, atmosphereHeight_2));
    bool _S430;
    if(tTop_2 <= 0.0f)
    {
        _S430 = true;
    }
    else
    {
        _S430 = !(dist_3 > 0.0f);
    }
    if(_S430)
    {
        return none_1;
    }
    float tGround_2 = shellEnter_0(b_9, cGround_2);
    float tMax_2;
    if(tGround_2 > 0.0f)
    {
        tMax_2 = tGround_2;
    }
    else
    {
        tMax_2 = tTop_2;
    }
    if(dist_3 < tMax_2)
    {
        tMax_2 = dist_3;
    }
    float _S431 = (F32_max((tA_1), (0.0f)));
    float _S432 = (F32_min((tB_1), (tMax_2)));
    if(!(_S432 > _S431))
    {
        return none_1;
    }
    Vector<float, 3>  betaR_2 = rayleighCoefficients_0();
    float betaM_1 = mieCoefficient_0(p_24->turbidity_0);
    float _S433 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rd_7, _S424), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_19 = clampf_0(p_24->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S434 = g_19 * g_19;
    float hgDenom_1 = 1.0f + _S434 - 2.0f * g_19 * cosTheta_1;
    float _S435 = 1.0f - _S434;
    float _S436 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        tA_1 = hgDenom_1;
    }
    else
    {
        tA_1 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S435 / (_S436 * (F32_sqrt((tA_1))));
    float depthR_3;
    float depthM_4;
    float hc_2;
    int32_t i_21;
    if(_S431 > 0.0f)
    {
        float _S437 = _S431 / 8.0f;
        i_21 = int(0);
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
        for(;;)
        {
            if(i_21 < int(8))
            {
            }
            else
            {
                break;
            }
            float tm_0 = (float(i_21) + 0.5f) * _S437;
            float h_6 = altitudeFromQ_0(cGround_2 + 2.0f * tm_0 * b_9 + tm_0 * tm_0, planetRadius_6);
            if(h_6 < 0.0f)
            {
                hc_2 = 0.0f;
            }
            else
            {
                hc_2 = h_6;
            }
            float _S438 = - hc_2;
            float depthR_4 = depthR_3 + (F32_exp((_S438 / scaleHeight_4))) * _S437;
            float depthM_5 = depthM_4 + (F32_exp((_S438 / 1200.0f))) * _S437;
            i_21 = i_21 + int(1);
            depthR_3 = depthR_4;
            depthM_4 = depthM_5;
        }
    }
    else
    {
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
    }
    float _S439 = clampf_0(jitter_1, 0.0f, 1.0f);
    float _S440 = _S432 - _S431;
    Vector<float, 3>  lossR_0 = none_1;
    Vector<float, 3>  lossM_0 = none_1;
    i_21 = int(0);
    for(;;)
    {
        if(i_21 < int(48))
        {
        }
        else
        {
            break;
        }
        float s0_0 = _S431 + _S440 * float(i_21 * i_21) * 0.00043402778101154f;
        int32_t _S441 = i_21 + int(1);
        float dt_2 = _S431 + _S440 * float(_S441 * _S441) * 0.00043402778101154f - s0_0;
        float ts_0 = s0_0 + _S439 * dt_2;
        float h_7 = altitudeFromQ_0(cGround_2 + 2.0f * ts_0 * b_9 + ts_0 * ts_0, planetRadius_6);
        if(h_7 < 0.0f)
        {
            hc_2 = 0.0f;
        }
        else
        {
            hc_2 = h_7;
        }
        float _S442 = - hc_2;
        float rhoR_0 = (F32_exp((_S442 / scaleHeight_4)));
        float rhoM_0 = (F32_exp((_S442 / 1200.0f)));
        float _S443 = ts_0 - s0_0;
        float atR_0 = depthR_3 + rhoR_0 * _S443;
        float atM_0 = depthM_4 + rhoM_0 * _S443;
        float depthR_5 = depthR_3 + rhoR_0 * dt_2;
        float depthM_6 = depthM_4 + rhoM_0 * dt_2;
        Vector<float, 3>  pw_0 = ro_7 + rd_7 * (Vector<float, 3> )ts_0;
        float _S444 = layerMapTransmittance_0(mapA_1, pw_0);
        float _S445 = layerMapTransmittance_0(mapB_1, pw_0);
        float v_8 = _S444 * _S445;
        if(v_8 >= 1.0f)
        {
            i_21 = _S441;
            depthR_3 = depthR_5;
            depthM_4 = depthM_6;
            continue;
        }
        Vector<float, 3>  _S446 = sampleTransmittanceLut_0(p_24, hc_2, lutMuFor_0(Vector<float, 3> (rd_7.x * ts_0, _S428 + _S429 * ts_0, rd_7.z * ts_0), _S424));
        float _S447 = _S433 * atM_0;
        Vector<float, 3>  w_3 = Vector<float, 3> ((F32_exp((- (betaR_2.x * atR_0 + _S447)))), (F32_exp((- (betaR_2.y * atR_0 + _S447)))), (F32_exp((- (betaR_2.z * atR_0 + _S447))))) * _S446 * (Vector<float, 3> )((1.0f - v_8) * dt_2);
        Vector<float, 3>  _S448 = lossM_0 + w_3 * (Vector<float, 3> )rhoM_0;
        lossR_0 = lossR_0 + w_3 * (Vector<float, 3> )rhoR_0;
        lossM_0 = _S448;
        i_21 = _S441;
        depthR_3 = depthR_5;
        depthM_4 = depthM_6;
    }
    Vector<float, 3>  _S449 = lossR_0 * betaR_2 * (Vector<float, 3> )phaseR_1 + lossM_0 * (Vector<float, 3> )(betaM_1 * phaseM_1);
    float _S450 = sunIrradianceTop_0(p_24);
    return _S449 * (Vector<float, 3> )_S450;
}

static AirSegment_0 airSegment_0(SkyInput_0 * p_25, float originAltitude_2, Vector<float, 3>  rayDir_2, float dist_4, float u1_0, float u2_0)
{
    AirSegment_0 seg_0;
    Vector<float, 3>  _S451 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&seg_0)->airIn_0 = _S451;
    (&seg_0)->airT_0 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    (&seg_0)->shadowAt_0 = -1.0f;
    Vector<float, 3>  _S452 = sunDirection_0(p_25);
    float _S453 = p_25->planetRadius_0;
    float planetRadius_7;
    if((p_25->planetRadius_0) > 1000.0f)
    {
        planetRadius_7 = _S453;
    }
    else
    {
        planetRadius_7 = 1000.0f;
    }
    float _S454 = p_25->scaleHeight_0;
    float scaleHeight_5;
    if((p_25->scaleHeight_0) > 1.0f)
    {
        scaleHeight_5 = _S454;
    }
    else
    {
        scaleHeight_5 = 1.0f;
    }
    float atmosphereHeight_3 = scaleHeight_5 * 8.0f;
    float observerAltitude_3;
    if(originAltitude_2 > 0.0f)
    {
        observerAltitude_3 = originAltitude_2;
    }
    else
    {
        observerAltitude_3 = 0.0f;
    }
    float _S455 = planetRadius_7 + observerAltitude_3;
    float _S456 = rayDir_2.y;
    float b_10 = _S455 * _S456;
    float cGround_3 = shellC_0(observerAltitude_3, planetRadius_7, 0.0f);
    float tTop_3 = shellExit_0(b_10, shellC_0(observerAltitude_3, planetRadius_7, atmosphereHeight_3));
    bool _S457;
    if(tTop_3 <= 0.0f)
    {
        _S457 = true;
    }
    else
    {
        _S457 = !(dist_4 > 0.0f);
    }
    if(_S457)
    {
        return seg_0;
    }
    float tGround_3 = shellEnter_0(b_10, cGround_3);
    float tMax_3;
    if(tGround_3 > 0.0f)
    {
        tMax_3 = tGround_3;
    }
    else
    {
        tMax_3 = tTop_3;
    }
    if(dist_4 < tMax_3)
    {
        tMax_3 = dist_4;
    }
    Vector<float, 3>  betaR_3 = rayleighCoefficients_0();
    float betaM_2 = mieCoefficient_0(p_25->turbidity_0);
    float betaMExt_2 = betaM_2 * 1.11000001430511475f;
    float cosTheta_2 = clampf_0(dot_0(rayDir_2, _S452), -1.0f, 1.0f);
    float phaseR_2 = 0.05968309938907623f * (1.0f + cosTheta_2 * cosTheta_2);
    float g_20 = clampf_0(p_25->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S458 = g_20 * g_20;
    float hgDenom_2 = 1.0f + _S458 - 2.0f * g_20 * cosTheta_2;
    float _S459 = 1.0f - _S458;
    float _S460 = 12.56637096405029297f * hgDenom_2;
    if(hgDenom_2 > 9.99999997475242708e-07f)
    {
        observerAltitude_3 = hgDenom_2;
    }
    else
    {
        observerAltitude_3 = 9.99999997475242708e-07f;
    }
    float phaseM_2 = _S459 / (_S460 * (F32_sqrt((observerAltitude_3))));
    float tPrev_2 = 0.0f;
    Vector<float, 3>  sumR_1 = _S451;
    Vector<float, 3>  sumM_1 = _S451;
    float u_3 = u1_0;
    float pickedFrom_0 = -1.0f;
    float pickedSpan_0 = 0.0f;
    int32_t i_22 = int(0);
    float depthR_6 = 0.0f;
    float depthM_7 = 0.0f;
    float lumTotal_0 = 0.0f;
    for(;;)
    {
        if(i_22 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S461 = i_22 + int(1);
        float tNext_2 = tMax_3 * float(_S461 * _S461) * 0.00173611112404615f;
        float dt_3 = tNext_2 - tPrev_2;
        float tMid_2 = (tPrev_2 + tNext_2) * 0.5f;
        float u_4;
        float pickedFrom_1;
        float pickedSpan_1;
        if(dt_3 <= 0.0f)
        {
            u_4 = u_3;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            tPrev_2 = tNext_2;
            u_3 = u_4;
            pickedFrom_0 = pickedFrom_1;
            pickedSpan_0 = pickedSpan_1;
            i_22 = _S461;
            continue;
        }
        float h_8 = altitudeFromQ_0(cGround_3 + 2.0f * tMid_2 * b_10 + tMid_2 * tMid_2, planetRadius_7);
        float hc_3;
        if(h_8 < 0.0f)
        {
            hc_3 = 0.0f;
        }
        else
        {
            hc_3 = h_8;
        }
        float _S462 = - hc_3;
        float dR_1 = (F32_exp((_S462 / scaleHeight_5))) * dt_3;
        float dM_1 = (F32_exp((_S462 / 1200.0f))) * dt_3;
        float midR_1 = depthR_6 + 0.5f * dR_1;
        float midM_1 = depthM_7 + 0.5f * dM_1;
        float depthR_7 = depthR_6 + dR_1;
        float depthM_8 = depthM_7 + dM_1;
        Vector<float, 3>  _S463 = sampleTransmittanceLut_0(p_25, hc_3, lutMuFor_0(Vector<float, 3> (rayDir_2.x * tMid_2, _S455 + _S456 * tMid_2, rayDir_2.z * tMid_2), _S452));
        float _S464 = betaMExt_2 * midM_1;
        Vector<float, 3>  transmittance_2 = Vector<float, 3> ((F32_exp((- (betaR_3.x * midR_1 + _S464)))), (F32_exp((- (betaR_3.y * midR_1 + _S464)))), (F32_exp((- (betaR_3.z * midR_1 + _S464))))) * _S463;
        Vector<float, 3>  _S465 = sumR_1 + transmittance_2 * (Vector<float, 3> )dR_1;
        Vector<float, 3>  _S466 = sumM_1 + transmittance_2 * (Vector<float, 3> )dM_1;
        Vector<float, 3>  c_30 = transmittance_2 * (betaR_3 * (Vector<float, 3> )(phaseR_2 * dR_1) + (Vector<float, 3> )(betaM_2 * (phaseM_2 * dM_1)));
        float lum_0 = c_30.x + c_30.y + c_30.z;
        float lumTotal_1;
        if(lum_0 > 0.0f)
        {
            float lumTotal_2 = lumTotal_0 + lum_0;
            float keep_3 = lum_0 / lumTotal_2;
            if(u_3 < keep_3)
            {
                u_4 = u_3 / keep_3;
                pickedFrom_1 = tPrev_2;
                pickedSpan_1 = dt_3;
            }
            else
            {
                u_4 = (u_3 - keep_3) / (1.0f - keep_3);
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
        sumR_1 = _S465;
        sumM_1 = _S466;
        depthR_6 = depthR_7;
        depthM_7 = depthM_8;
        lumTotal_0 = lumTotal_1;
        tPrev_2 = tNext_2;
        u_3 = u_4;
        pickedFrom_0 = pickedFrom_1;
        pickedSpan_0 = pickedSpan_1;
        i_22 = _S461;
    }
    float _S467 = sunIrradianceTop_0(p_25);
    (&seg_0)->airIn_0 = (sumR_1 * betaR_3 * (Vector<float, 3> )phaseR_2 + sumM_1 * (Vector<float, 3> )(betaM_2 * phaseM_2)) * (Vector<float, 3> )_S467;
    float _S468 = betaMExt_2 * depthM_7;
    (&seg_0)->airT_0 = Vector<float, 3> ((F32_exp((- (betaR_3.x * depthR_6 + _S468)))), (F32_exp((- (betaR_3.y * depthR_6 + _S468)))), (F32_exp((- (betaR_3.z * depthR_6 + _S468)))));
    if(pickedFrom_0 >= 0.0f)
    {
        (&seg_0)->shadowAt_0 = pickedFrom_0 + clampf_0(u2_0, 0.0f, 1.0f) * pickedSpan_0;
    }
    return seg_0;
}

static float airShadow_0(Scene_0 * s_12, StructuredBuffer<float> bounds_9, StructuredBuffer<Vector<float, 2> > drift_6, Rng_0 * rng_7, AirSegment_0 * seg_1, Vector<float, 3>  ro_8, Vector<float, 3>  rd_8, int32_t * steps_7)
{
    bool _S469;
    if((s_12->aerialMode_0) < int(2))
    {
        _S469 = true;
    }
    else
    {
        _S469 = (seg_1->shadowAt_0) < 0.0f;
    }
    if(_S469)
    {
        return 1.0f;
    }
    float _S470 = sceneTransmittance_0(s_12, bounds_9, drift_6, rng_7, ro_8 + rd_8 * (Vector<float, 3> )seg_1->shadowAt_0, s_12->sunDir_0, steps_7);
    return _S470;
}

static Vector<float, 3>  sampleHG_0(Rng_0 * rng_8, Vector<float, 3>  wo_0, float g_21, float * cosT_6)
{
    float _S471 = clamp_0(g_21, -0.99900001287460327f, 0.99900001287460327f);
    float u1_1 = randFloat_0(rng_8);
    float u2_1 = randFloat_0(rng_8);
    if((F32_abs((_S471))) < 0.00100000004749745f)
    {
        *cosT_6 = 1.0f - 2.0f * u1_1;
    }
    else
    {
        float _S472 = _S471 * _S471;
        float _S473 = 2.0f * _S471;
        float s_13 = (1.0f - _S472) / (1.0f - _S471 + _S473 * u1_1);
        *cosT_6 = (1.0f + _S472 - s_13 * s_13) / _S473;
    }
    float _S474 = clamp_0(*cosT_6, -1.0f, 1.0f);
    *cosT_6 = _S474;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S474 * _S474))))));
    float phi_0 = 6.28318548202514648f * u2_1;
    Vector<float, 3>  w_4 = normalize_0(wo_0);
    Vector<float, 3>  a_6;
    if((F32_abs((w_4.y))) < 0.94999998807907104f)
    {
        a_6 = Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_6 = Vector<float, 3> (1.0f, 0.0f, 0.0f);
    }
    Vector<float, 3>  u_5 = normalize_0(cross_0(a_6, w_4));
    return normalize_0((Vector<float, 3> )(sinT_0 * (F32_cos((phi_0)))) * u_5 + (Vector<float, 3> )(sinT_0 * (F32_sin((phi_0)))) * cross_0(w_4, u_5) + (Vector<float, 3> )*cosT_6 * w_4);
}

static Vector<float, 3>  sampleDraine_0(Rng_0 * rng_9, Vector<float, 3>  wo_1, float g_22, float a_7, float * cosT_7)
{
    Vector<float, 3>  dir_4 = sampleHG_0(rng_9, wo_1, g_22, cosT_7);
    if(!(a_7 > 0.0f))
    {
        return dir_4;
    }
    Vector<float, 3>  dir_5 = dir_4;
    int32_t i_23 = int(0);
    for(;;)
    {
        if(i_23 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S475 = randFloat_0(rng_9);
        if((_S475 * (1.0f + a_7)) <= (1.0f + a_7 * *cosT_7 * *cosT_7))
        {
            break;
        }
        Vector<float, 3>  _S476 = sampleHG_0(rng_9, wo_1, g_22, cosT_7);
        int32_t i_24 = i_23 + int(1);
        dir_5 = _S476;
        i_23 = i_24;
    }
    return dir_5;
}

static Vector<float, 3>  samplePhaseDir_0(PhaseInput_0 * p_26, Rng_0 * rng_10, Vector<float, 3>  wo_2, float * weight_0)
{
    float cosT_8;
    Vector<float, 3>  dir_6;
    float _S477;
    if((p_26->useIce_0) != int(0))
    {
        float _S478 = randFloat_0(rng_10);
        if(_S478 < 0.72000002861022949f)
        {
            Vector<float, 3>  _S479 = sampleHG_0(rng_10, wo_2, 0.85000002384185791f, &cosT_8);
            dir_6 = _S479;
        }
        else
        {
            Vector<float, 3>  _S480 = sampleHG_0(rng_10, wo_2, 0.0f, &cosT_8);
            dir_6 = _S480;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_8, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S477 = phaseIce_0(cosT_8) / pdf_0;
        }
        else
        {
            _S477 = 0.0f;
        }
        *weight_0 = _S477;
    }
    else
    {
        float _S481 = randFloat_0(rng_10);
        if(_S481 < (p_26->draineW_0))
        {
            Vector<float, 3>  _S482 = sampleDraine_0(rng_10, wo_2, p_26->draineG_0, p_26->draineAlpha_0, &cosT_8);
            dir_6 = _S482;
        }
        else
        {
            Vector<float, 3>  _S483 = sampleHG_0(rng_10, wo_2, p_26->hgG_0, &cosT_8);
            dir_6 = _S483;
        }
        float _S484 = phaseLiquid_0(p_26, cosT_8);
        if(_S484 > 9.99999971718068537e-10f)
        {
            _S477 = 1.0f;
        }
        else
        {
            _S477 = 0.0f;
        }
        *weight_0 = _S477;
    }
    return dir_6;
}

static TraceResult_0 trace_0(Scene_0 * s_14, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_10, StructuredBuffer<Vector<float, 2> > drift_7, Rng_0 * rng_11, Vector<float, 3>  ro_9, Vector<float, 3>  rd_9)
{
    TraceResult_0 r_7;
    Vector<float, 3>  _S485 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&r_7)->pathRadiance_0 = _S485;
    (&r_7)->scatterEvents_0 = int(0);
    (&r_7)->capped_0 = int(0);
    (&r_7)->trackingSteps_0 = int(0);
    Vector<float, 3>  throughput_0 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    int32_t _S486 = (I32_min((s_14->maxBounces_0), (int(256))));
    bool sunAlongCamera_0;
    if((s_14->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S486 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    if(sunAlongCamera_0)
    {
        Rng_0 _S487 = *rng_11;
        Rng_0 _S488 = splitRng_0(&_S487, 1510U);
        Rng_0 segmentRng_0 = _S488;
        Rng_0 _S489 = *rng_11;
        Rng_0 _S490 = splitRng_0(&_S489, 1511U);
        Rng_0 _S491 = _S490;
        Vector<float, 3>  _S492 = cameraSegmentSun_0(s_14, ph_1, bounds_10, drift_7, &segmentRng_0, &_S491, ro_9, rd_9, &(&r_7)->trackingSteps_0);
        (&r_7)->pathRadiance_0 = (&r_7)->pathRadiance_0 + _S492;
    }
    bool _S493;
    if(((&s_14->environment_0)->envMode_0) == int(1))
    {
        _S493 = (s_14->aerialMode_0) != int(0);
    }
    else
    {
        _S493 = false;
    }
    Rng_0 _S494 = *rng_11;
    Rng_0 _S495 = splitRng_0(&_S494, 2590U);
    Rng_0 airRng_0 = _S495;
    Vector<float, 3>  env_0 = ro_9;
    Vector<float, 3>  _S496 = rd_9;
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
        if(bounce_0 >= _S486)
        {
            (&r_7)->capped_0 = int(1);
            break;
        }
        Vector<float, 3>  p_27;
        int32_t layer_1;
        bool _S497 = sceneFreeFlight_0(s_14, bounds_10, drift_7, rng_11, env_0, _S496, &p_27, &layer_1, &(&r_7)->trackingSteps_0);
        if(!_S497)
        {
            bool _S498 = (s_14->airMapOn_0) != int(0);
            float groundLit_2;
            if(_S498)
            {
                float _S499 = groundShadow_0(&s_14->airMapIce_0, &s_14->airMapCu_0, env_0, _S496);
                groundLit_2 = _S499;
            }
            else
            {
                groundLit_2 = 1.0f;
            }
            bool _S500 = bounce_0 == int(0);
            Vector<float, 3>  _S501 = environmentRadiance_0(&s_14->environment_0, env_0, _S496, _S500, groundLit_2);
            if(_S500)
            {
                sunAlongCamera_0 = _S493;
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                sunAlongCamera_0 = (s_14->aerialMode_0) >= int(2);
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                float u1_2 = randFloat_0(&airRng_0);
                float u2_2 = randFloat_0(&airRng_0);
                if(_S498)
                {
                    Vector<float, 3>  _S502 = airShadowLoss_0(&(&s_14->environment_0)->sky_0, &s_14->airMapIce_0, &s_14->airMapCu_0, env_0, _S496, 1.00000001504746622e+30f, u2_2);
                    env_0 = max_0(_S501 - _S502, _S485);
                }
                else
                {
                    AirSegment_0 _S503 = airSegment_0(&(&s_14->environment_0)->sky_0, env_0.y, _S496, 1.00000001504746622e+30f, u1_2, u2_2);
                    AirSegment_0 _S504 = _S503;
                    float _S505 = airShadow_0(s_14, bounds_10, drift_7, &airRng_0, &_S504, env_0, _S496, &(&r_7)->trackingSteps_0);
                    env_0 = _S501 - _S503.airIn_0 * (Vector<float, 3> )(1.0f - _S505);
                }
            }
            else
            {
                env_0 = _S501;
            }
            (&r_7)->pathRadiance_0 = (&r_7)->pathRadiance_0 + throughput_1 * env_0;
            break;
        }
        (&r_7)->scatterEvents_0 = (&r_7)->scatterEvents_0 + int(1);
        bool _S506 = bounce_0 == int(0);
        bool _S507;
        if(_S506)
        {
            _S507 = _S493;
        }
        else
        {
            _S507 = false;
        }
        bool _S508;
        Vector<float, 3>  throughput_2;
        if(_S507)
        {
            float u1_3 = randFloat_0(&airRng_0);
            float u2_3 = randFloat_0(&airRng_0);
            float dist_5 = length_0(p_27 - env_0);
            AirSegment_0 _S509 = airSegment_0(&(&s_14->environment_0)->sky_0, env_0.y, _S496, dist_5, u1_3, u2_3);
            if((s_14->aerialMode_0) >= int(2))
            {
                _S508 = (s_14->airMapOn_0) != int(0);
            }
            else
            {
                _S508 = false;
            }
            if(_S508)
            {
                Vector<float, 3>  _S510 = airShadowLoss_0(&(&s_14->environment_0)->sky_0, &s_14->airMapIce_0, &s_14->airMapCu_0, env_0, _S496, dist_5, u2_3);
                throughput_2 = max_0(_S509.airIn_0 - _S510, _S485);
            }
            else
            {
                AirSegment_0 _S511 = _S509;
                float _S512 = airShadow_0(s_14, bounds_10, drift_7, &airRng_0, &_S511, env_0, _S496, &(&r_7)->trackingSteps_0);
                throughput_2 = _S509.airIn_0 * (Vector<float, 3> )_S512;
            }
            (&r_7)->pathRadiance_0 = (&r_7)->pathRadiance_0 + throughput_1 * throughput_2;
            throughput_2 = throughput_1 * _S509.airT_0;
        }
        else
        {
            throughput_2 = throughput_1;
        }
        Vector<float, 3>  _S513 = s_14->albedo_0;
        Vector<float, 3>  matterAlbedo_1;
        PhaseInput_0 matterPhase_0;
        if(layer_1 != int(0))
        {
            matterPhase_0 = s_14->phase2_0;
            matterAlbedo_1 = s_14->albedo2_0;
        }
        else
        {
            matterPhase_0 = *ph_1;
            matterAlbedo_1 = _S513;
        }
        if(_S506)
        {
            _S508 = sunAlongCamera_0;
        }
        else
        {
            _S508 = false;
        }
        if(!_S508)
        {
            Vector<float, 3>  _S514 = s_14->sunDir_0;
            float _S515 = sceneTransmittance_0(s_14, bounds_10, drift_7, rng_11, p_27 + s_14->sunDir_0 * (Vector<float, 3> )s_14->shadowOffset_0, s_14->sunDir_0, &(&r_7)->trackingSteps_0);
            if(_S515 > 0.0f)
            {
                float _S516 = dot_0(_S496, _S514);
                PhaseInput_0 _S517 = matterPhase_0;
                float _S518 = phaseAt_0(&_S517, _S516);
                Vector<float, 3>  _S519 = throughput_2 * matterAlbedo_1 * (Vector<float, 3> )_S518 * (Vector<float, 3> )_S515;
                Vector<float, 3>  _S520 = sunIrradianceAt_0(s_14, p_27);
                (&r_7)->pathRadiance_0 = (&r_7)->pathRadiance_0 + _S519 * _S520;
            }
        }
        PhaseInput_0 _S521 = matterPhase_0;
        float w_5;
        Vector<float, 3>  _S522 = samplePhaseDir_0(&_S521, rng_11, _S496, &w_5);
        Vector<float, 3>  throughput_3 = throughput_2 * (matterAlbedo_1 * (Vector<float, 3> )w_5);
        Vector<float, 3>  _S523 = p_27;
        if(bounce_0 >= (s_14->rrStartBounce_0))
        {
            float p2_0 = clamp_0((F32_max((throughput_3.x), ((F32_max((throughput_3.y), (throughput_3.z)))))), 0.05000000074505806f, 1.0f);
            float _S524 = randFloat_0(rng_11);
            if(_S524 > p2_0)
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
        env_0 = _S523;
        _S496 = _S522;
        bounce_0 = bounce_1;
    }
    return r_7;
}

static Vector<float, 3>  renderSample_0(Scene_0 * s_15, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_11, StructuredBuffer<Vector<float, 2> > drift_8, Vector<float, 3>  ro_10, Vector<float, 3>  rd_10, uint32_t seed_2)
{
    Rng_0 rng_12 = makeRng_0(seed_2);
    TraceResult_0 _S525 = trace_0(s_15, ph_2, bounds_11, drift_8, &rng_12, ro_10, rd_10);
    return _S525.pathRadiance_0;
}

void _cpuRenderRays(void* _S526, void* entryPointParams_0, void* _S527)
{
    ComputeThreadVaryingInput * _S528 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S526));
    int32_t i_25 = int32_t((_S528->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S528->groupThreadID).x);
    if(i_25 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Vector<float, 3>  * _S529 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->outRadiance_0)[i_25]);
    Vector<float, 3>  _S530 = renderSample_0(&(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->scene_0, &(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->phase_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->bounds_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->drift_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->origins_0.Load(i_25), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->directions_0.Load(i_25), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_25));
    *_S529 = _S530;
    return;
}

static void layerMapColumn_0(Medium_0 * med_0, StructuredBuffer<Vector<float, 2> > drift_9, LayerShadowMap_0 * m_13, int32_t texel_0, RWStructuredBuffer<float> outTexels_1)
{
    int32_t _S531 = m_13->smDimU_0;
    int32_t stride_0 = m_13->smDimU_0 * m_13->smDimV_0;
    bool _S532;
    if(texel_0 < int(0))
    {
        _S532 = true;
    }
    else
    {
        _S532 = texel_0 >= stride_0;
    }
    if(_S532)
    {
        return;
    }
    int32_t iu_1 = texel_0 % _S531;
    int32_t iv_1 = texel_0 / _S531;
    Vector<float, 2>  _S533 = m_13->smLo_0;
    Vector<float, 2>  _S534 = m_13->smTexel_0;
    Vector<float, 2>  _S535 = m_13->smCentre_0 + m_13->smAxisU_0 * (Vector<float, 2> )(m_13->smLo_0.x + (float(iu_1) + 0.5f) * m_13->smTexel_0.x);
    Vector<float, 2>  _S536 = airMapAxisV_0(m_13);
    Vector<float, 2>  q_12 = _S535 + _S536 * (Vector<float, 2> )(_S533.y + (float(iv_1) + 0.5f) * _S534.y);
    Vector<float, 3>  base_0 = Vector<float, 3> (q_12.x, m_13->smBottom_0, q_12.y);
    Vector<float, 3>  _S537 = m_13->smSun_0;
    int32_t _S538 = m_13->smSlices_0;
    int32_t _S539 = m_13->smSlices_0 - int(1);
    float _S540 = (m_13->smTop_0 - m_13->smBottom_0) / (float(_S539) * m_13->smSun_0.y);
    float _S541 = (F32_max((m_13->smStep_0), (1.0f)));
    float t0_5;
    float t1_5;
    bool _S542 = slabRange_0(med_0, base_0, m_13->smSun_0, &t0_5, &t1_5);
    *(&(outTexels_1)[_S539 * stride_0 + texel_0]) = 1.0f;
    int32_t k_4 = _S538 - int(2);
    float tau_0 = 0.0f;
    for(;;)
    {
        if(k_4 >= int(0))
        {
        }
        else
        {
            break;
        }
        if(_S542)
        {
            _S532 = tau_0 < 12.0f;
        }
        else
        {
            _S532 = false;
        }
        float tau_1;
        if(_S532)
        {
            float _S543 = (F32_max((float(k_4) * _S540), (t0_5)));
            float _S544 = (F32_min((float(k_4 + int(1)) * _S540), (t1_5)));
            if(_S544 > _S543)
            {
                float _S545 = _S544 - _S543;
                int32_t n_0 = clamp_1(int32_t((F32_ceil((_S545 / _S541)))), int(1), int(1024));
                float _S546 = _S545 / float(n_0);
                int32_t j_10 = int(0);
                tau_1 = tau_0;
                for(;;)
                {
                    if(j_10 < n_0)
                    {
                    }
                    else
                    {
                        break;
                    }
                    float _S547 = densityAt_0(med_0, drift_9, base_0 + _S537 * (Vector<float, 3> )(_S543 + (float(j_10) + 0.5f) * _S546));
                    float tau_2 = tau_1 + _S547 * _S546;
                    j_10 = j_10 + int(1);
                    tau_1 = tau_2;
                }
            }
            else
            {
                tau_1 = tau_0;
            }
        }
        else
        {
            tau_1 = tau_0;
        }
        float * _S548 = (&(outTexels_1)[k_4 * stride_0 + texel_0]);
        float _S549;
        if(tau_1 < 12.0f)
        {
            _S549 = (F32_exp((- tau_1)));
        }
        else
        {
            _S549 = 0.0f;
        }
        *_S548 = _S549;
        k_4 = k_4 - int(1);
        tau_0 = tau_1;
    }
    return;
}

void _cpuBuildAirMap(void* _S550, void* entryPointParams_1, void* _S551)
{
    ComputeThreadVaryingInput * _S552 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S550));
    int32_t i_26 = int32_t((_S552->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S552->groupThreadID).x);
    if(i_26 >= ((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->count_1))
    {
        return;
    }
    layerMapColumn_0(&(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->medium_1, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->drift_1, &(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->map_0, i_26, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->outTexels_0);
    return;
}

SLANG_PRELUDE_EXPORT
void cpuRenderRays_Thread(ComputeThreadVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    _cpuRenderRays(varyingInput, entryPointParams, globalParams);
}
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
SLANG_PRELUDE_EXPORT
void cpuBuildAirMap_Thread(ComputeThreadVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    _cpuBuildAirMap(varyingInput, entryPointParams, globalParams);
}
SLANG_PRELUDE_EXPORT
void cpuBuildAirMap_Group(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    ComputeThreadVaryingInput threadInput = {};
    threadInput.groupID = varyingInput->startGroupID;
    for (uint32_t x = 0; x < 64; ++x)
    {
        threadInput.groupThreadID.x = x;
        _cpuBuildAirMap(&threadInput, entryPointParams, globalParams);
    }
}
SLANG_PRELUDE_EXPORT
void cpuBuildAirMap(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
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
                cpuBuildAirMap_Group(&groupVaryingInput, entryPointParams, globalParams);
            }
        }
    }
}
