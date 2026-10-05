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
    float cvReliefHeight_0;
    float cvReliefSlope_0;
    float cvReliefFade_0;
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
    float shadowHandoff_0;
    int32_t ltCount_0;
    StructuredBuffer<float> ltBuffer_0;
    Vector<float, 3>  ltAmbient_0;
    int32_t hideSunDisc_0;
    int32_t clearSky_0;
};

struct AirSegment_0
{
    Vector<float, 3>  airIn_0;
    Vector<float, 3>  airT_0;
    float shadowAt_0;
};

struct LightSample_0
{
    Vector<float, 3>  lsDir_0;
    float lsDist_0;
    Vector<float, 3>  lsIrradiance_0;
};

struct PathState_0
{
    Vector<float, 3>  psRadiance_0;
    Vector<float, 3>  psThroughput_0;
    Vector<float, 3>  psOrigin_0;
    Vector<float, 3>  psDir_0;
    Rng_0 psRng_0;
    int32_t psBounce_0;
    int32_t psAlive_0;
    int32_t psEvents_0;
    int32_t psCapped_0;
    int32_t psSteps_0;
    float psSee_0;
};

struct TraceResult_0
{
    Vector<float, 3>  pathRadiance_0;
    int32_t scatterEvents_0;
    int32_t capped_0;
    int32_t trackingSteps_0;
    float sceneSee_0;
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

struct EntryPointParams_2
{
    Scene_0 scene_1;
    StructuredBuffer<float> bounds_1;
    StructuredBuffer<Vector<float, 2> > drift_2;
    StructuredBuffer<Vector<float, 3> > origins_1;
    StructuredBuffer<Vector<float, 3> > directions_1;
    RWStructuredBuffer<Vector<float, 2> > outMoments_0;
    float tMax_1;
    int32_t count_2;
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

static bool any_0(Vector<bool, 3>  x_3)
{
    bool result_0 = false;
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

static Vector<float, 3>  max_0(Vector<float, 3>  x_4, Vector<float, 3>  y_1)
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
        result_1[i_1] = (F32_max((_slang_vector_get_element(x_4, i_1)), (_slang_vector_get_element(y_1, i_1))));
        i_1 = i_1 + int(1);
    }
    return result_1;
}

static int32_t StructuredBuffer_getCount_0(StructuredBuffer<float> this_0)
{
    uint _elementCount_0;
    uint _stride_0;
    this_0.GetDimensions(&_elementCount_0, &_stride_0);
    Vector<uint32_t, 2>  _S7 = uint2(_elementCount_0, _stride_0);
    return int32_t(_S7.x);
}

static Vector<float, 3>  lerp_0(Vector<float, 3>  x_5, Vector<float, 3>  y_2, Vector<float, 3>  s_0)
{
    return x_5 + (y_2 - x_5) * s_0;
}

static float dot_1(Vector<float, 2>  x_6, Vector<float, 2>  y_3)
{
    return x_6.x * y_3.x + x_6.y * y_3.y;
}

static Vector<float, 3>  floor_0(Vector<float, 3>  x_7)
{
    Vector<float, 3>  result_2;
    int32_t i_2 = int(0);
    for(;;)
    {
        if(i_2 < int(3))
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

static float lerp_1(float x_8, float y_4, float s_1)
{
    return x_8 + (y_4 - x_8) * s_1;
}

static float gradientNoise_0(Vector<float, 3>  p_0)
{
    Vector<float, 3>  fi_0 = floor_0(p_0);
    Vector<int32_t, 3>  _S12 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fi_0, 0), (int32_t)_slang_vector_get_element(fi_0, 1), (int32_t)_slang_vector_get_element(fi_0, 2)};
    Vector<float, 3>  f_0 = p_0 - fi_0;
    Vector<float, 3>  u_0 = f_0 * f_0 * ((Vector<float, 3> )3.0f - (Vector<float, 3> )2.0f * f_0);
    float _S13 = u_0.x;
    float _S14 = u_0.y;
    return lerp_1(lerp_1(lerp_1(dot_0(hash33_0(_S12), f_0), dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(1), int(0), int(0))), f_0 - Vector<float, 3> (1.0f, 0.0f, 0.0f)), _S13), lerp_1(dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(0), int(1), int(0))), f_0 - Vector<float, 3> (0.0f, 1.0f, 0.0f)), dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(1), int(1), int(0))), f_0 - Vector<float, 3> (1.0f, 1.0f, 0.0f)), _S13), _S14), lerp_1(lerp_1(dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(0), int(0), int(1))), f_0 - Vector<float, 3> (0.0f, 0.0f, 1.0f)), dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(1), int(0), int(1))), f_0 - Vector<float, 3> (1.0f, 0.0f, 1.0f)), _S13), lerp_1(dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(0), int(1), int(1))), f_0 - Vector<float, 3> (0.0f, 1.0f, 1.0f)), dot_0(hash33_0(_S12 + Vector<int32_t, 3> (int(1), int(1), int(1))), f_0 - Vector<float, 3> (1.0f, 1.0f, 1.0f)), _S13), _S14), u_0.z);
}

static Vector<float, 2>  orgWarpOffset_0(Organization_0 * o_0, Vector<float, 2>  g_0)
{
    Vector<float, 2>  s_2 = g_0 / (Vector<float, 2> )2.5f;
    float _S15 = s_2.x;
    float _S16 = s_2.y;
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

static Vector<float, 2>  floor_1(Vector<float, 2>  x_9)
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
    return convLife_0((F32_frac((c_2->cvAge_0 + h_2.x)))) * lerp_1(0.34999999403953552f, 1.0f, h_2.y);
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

static float clamp_0(float x_10, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_10), (minBound_0)))), (maxBound_0)));
}

static float saturate_0(float x_11)
{
    return clamp_0(x_11, 0.0f, 1.0f);
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

static Vector<float, 2>  lerp_2(Vector<float, 2>  x_12, Vector<float, 2>  y_5, Vector<float, 2>  s_3)
{
    return x_12 + (y_5 - x_12) * s_3;
}

static Vector<float, 2>  orgGradToWorld_0(Organization_0 * o_3, Vector<float, 2>  gp_0, float spacing_1)
{
    if((o_3->ogOn_0) == int(0))
    {
        return gp_0 / (Vector<float, 2> )spacing_1;
    }
    Vector<float, 2>  s_4 = gp_0 / Vector<float, 2> (spacing_1 * o_3->ogStretch_0, spacing_1);
    return o_3->ogAxis_0 * (Vector<float, 2> )s_4.x + Vector<float, 2> (- o_3->ogAxis_0.y, o_3->ogAxis_0.x) * (Vector<float, 2> )s_4.y;
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
    float s_5 = 2.0f * (F32_frac((dot_1(q_1, o_4->ogWaveK_0)))) - 1.0f;
    float tri_0 = 1.0f - (F32_abs((s_5)));
    float crest_0 = tri_0 * tri_0 * (3.0f - 2.0f * tri_0);
    float dCrest_0 = 6.0f * tri_0 * (1.0f - tri_0);
    float dTri_0;
    if(s_5 > 0.0f)
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
        float fill_0 = lerp_1(w_0, 0.40000000596046448f, _S32);
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
        float s_6 = lerp_1(1.0f, t_2 * t_2 * (3.0f - 2.0f * t_2), _S36);
        float _S40 = _S34 * s_6;
        _S33 = _S33 * (Vector<float, 2> )s_6 + gcn_0 * (Vector<float, 2> )(_S34 * (6.0f * t_2 * (1.0f - t_2) / ramp_0 * _S36));
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
            Vector<int32_t, 2>  slot_2 = _S45 + Vector<int32_t, 2> (i_4, j_1);
            float _S47 = convVigour_0(c_6, slot_2);
            if(_S47 <= 0.0f)
            {
                i_4 = i_4 + int(1);
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
            i_4 = i_4 + int(1);
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
    float _S54 = convOrganize_0(c_6, q_3, kTop_1, kNext_1, gkTop_1, gkNext_1, keep_2, gKeep_2, lerp_1(_S53, closedField_0, c_6->cvPolarity_0), lerp_2(goTop_0, gClosed_0, (Vector<float, 2> )c_6->cvPolarity_0), grad_2);
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
            Vector<int32_t, 2>  slot_3 = _S57 + Vector<int32_t, 2> (i_5, j_3);
            float _S58 = convVigour_0(c_7, slot_3);
            if(_S58 <= 0.0f)
            {
                i_5 = i_5 + int(1);
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
            i_5 = i_5 + int(1);
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
    float _S65 = convOrganize_0(c_7, q_4, kTop_4, kNext_4, gkTop_4, gkNext_4, 1.0f, gKeep_3, lerp_1(_S64, closedField_1, c_7->cvPolarity_0), lerp_2(goTop_3, gClosed_1, (Vector<float, 2> )c_7->cvPolarity_0), grad_3);
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
        int32_t i_6 = int(-1);
        for(;;)
        {
            if(i_6 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_5 = _S70 + Vector<int32_t, 2> (i_6, j_5);
            float _S72 = convVigour_0(c_8, slot_5);
            if(_S72 <= 0.0f)
            {
                i_6 = i_6 + int(1);
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
            i_6 = i_6 + int(1);
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
    *grad_4 = lerp_2(goTop_6, gClosed_2, (Vector<float, 2> )c_8->cvPolarity_0) / (Vector<float, 2> )_S67;
    return lerp_1(_S77, closedField_2, _S78);
}

static bool any_1(Vector<bool, 2>  x_13)
{
    bool result_4 = false;
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
            result_4 = true;
        }
        else
        {
            result_4 = (bool((_slang_vector_get_element(x_13, i_7))));
        }
        i_7 = i_7 + int(1);
    }
    return result_4;
}

static int32_t clamp_1(int32_t x_14, int32_t minBound_1, int32_t maxBound_1)
{
    return (I32_min(((I32_max((x_14), (minBound_1)))), (maxBound_1)));
}

static Vector<float, 4>  lerp_3(Vector<float, 4>  x_15, Vector<float, 4>  y_6, Vector<float, 4>  s_7)
{
    return x_15 + (y_6 - x_15) * s_7;
}

static Vector<int32_t, 2>  min_0(Vector<int32_t, 2>  x_16, Vector<int32_t, 2>  y_7)
{
    Vector<int32_t, 2>  result_5;
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
        result_5[i_8] = (I32_min((_slang_vector_get_element(x_16, i_8)), (_slang_vector_get_element(y_7, i_8))));
        i_8 = i_8 + int(1);
    }
    return result_5;
}

static Vector<float, 2>  max_1(Vector<float, 2>  x_17, Vector<float, 2>  y_8)
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
        result_6[i_9] = (F32_max((_slang_vector_get_element(x_17, i_9)), (_slang_vector_get_element(y_8, i_9))));
        i_9 = i_9 + int(1);
    }
    return result_6;
}

static Vector<float, 2>  min_1(Vector<float, 2>  x_18, Vector<float, 2>  y_9)
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
        result_7[i_10] = (F32_min((_slang_vector_get_element(x_18, i_10)), (_slang_vector_get_element(y_9, i_10))));
        i_10 = i_10 + int(1);
    }
    return result_7;
}

static Vector<float, 2>  clamp_2(Vector<float, 2>  x_19, Vector<float, 2>  minBound_2, Vector<float, 2>  maxBound_2)
{
    return min_1(max_1(x_19, minBound_2), maxBound_2);
}

static float length_1(Vector<float, 2>  x_20)
{
    return (F32_sqrt((dot_1(x_20, x_20))));
}

static Vector<float, 2>  abs_0(Vector<float, 2>  x_21)
{
    Vector<float, 2>  result_8;
    int32_t i_11 = int(0);
    for(;;)
    {
        if(i_11 < int(2))
        {
        }
        else
        {
            break;
        }
        result_8[i_11] = (F32_abs((_slang_vector_get_element(x_21, i_11))));
        i_11 = i_11 + int(1);
    }
    return result_8;
}

static bool all_0(Vector<bool, 2>  x_22)
{
    bool result_9 = true;
    int32_t i_12 = int(0);
    for(;;)
    {
        if(i_12 < int(2))
        {
        }
        else
        {
            break;
        }
        if(result_9)
        {
            result_9 = (bool((_slang_vector_get_element(x_22, i_12))));
        }
        else
        {
            result_9 = false;
        }
        i_12 = i_12 + int(1);
    }
    return result_9;
}

static float smoothstep_0(float min_2, float max_2, float x_23)
{
    float _S79 = saturate_0((x_23 - min_2) / (max_2 - min_2));
    return _S79 * _S79 * (3.0f - (_S79 + _S79));
}

static Rng_0 makeRng_0(uint32_t seed_1)
{
    Rng_0 r_1;
    (&r_1)->state_0 = seed_1;
    return r_1;
}

static Rng_0 splitRng_0(Rng_0 * r_2, uint32_t salt_1)
{
    uint32_t s_8 = ((r_2->state_0) ^ (salt_1 * 2654435761U)) * 747796405U + 2891336453U;
    uint32_t s_9 = ((s_8 >> ((s_8 >> 28U) + 4U)) ^ s_8) * 277803737U;
    return makeRng_0((s_9 >> 22U) ^ s_9);
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
        lo_1 = max_1(lo_1, m_0->fadeAt_0 - (Vector<float, 2> )_S87);
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

static float convCapCeiling_0(ConvectionInput_0 * c_9)
{
    float _S102 = c_9->cvHeroTop_0;
    if((c_9->cvHeroTop_0) <= 0.0f)
    {
        return 0.0f;
    }
    float _S103 = c_9->cvPileusThick_0;
    float cap_0;
    if((c_9->cvPileusThick_0) > 0.0f)
    {
        cap_0 = _S102 + c_9->cvPileusGap_0 + _S103;
    }
    else
    {
        cap_0 = 0.0f;
    }
    float _S104 = c_9->cvVelumThick_0;
    float veil_0;
    if((c_9->cvVelumThick_0) > 0.0f)
    {
        veil_0 = c_9->cvVelumHeight_0 + 1.5f * _S104;
    }
    else
    {
        veil_0 = 0.0f;
    }
    return (F32_max((cap_0), (veil_0)));
}

static float convCeiling_0(ConvectionInput_0 * c_10)
{
    float _S105 = c_10->cvBillow_0;
    float field_0 = c_10->cvDepth_0 + c_10->cvBillow_0;
    float _S106 = c_10->cvHeroTop_0;
    float hero_0;
    if((c_10->cvHeroTop_0) > 0.0f)
    {
        hero_0 = _S106 + _S105 * c_10->cvHeroBillow_0;
    }
    else
    {
        hero_0 = 0.0f;
    }
    float _S107 = (F32_max((field_0), (hero_0)));
    float _S108 = convCapCeiling_0(c_10);
    return (F32_max((_S107), (_S108)));
}

static float convDomeHeight_0(float top_0, float radius_0, float shape_0, float r_3)
{
    bool _S109;
    if(top_0 <= 0.0f)
    {
        _S109 = true;
    }
    else
    {
        _S109 = r_3 >= radius_0;
    }
    if(_S109)
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
    Vector<float, 2>  nearGap_0 = max_1(max_1(Vector<float, 2> {lo_2.x, lo_2.z} - c_12->cvHeroAt_0, c_12->cvHeroAt_0 - Vector<float, 2> {hi_2.x, hi_2.z}), Vector<float, 2> (0.0f, 0.0f));
    float gap2_0 = dot_1(nearGap_0, nearGap_0);
    float _S110 = c_12->cvHeroRadius_0;
    float _S111 = c_12->cvPileusThick_0;
    bool _S112;
    float best_0;
    if((c_12->cvPileusThick_0) > 0.0f)
    {
        float rp_0 = 0.60000002384185791f * _S110;
        float _S113 = c_12->cvPileusGap_0;
        float _S114 = convHeroHeight_0(c_12, rp_0 * 0.60000002384185791f);
        float _S115 = 0.5f * _S111;
        float bottom_0 = _S113 + _S114 - _S115;
        float top_1 = _S113 + c_12->cvHeroTop_0 + _S115;
        if(gap2_0 < (rp_0 * rp_0))
        {
            _S112 = high_0 >= bottom_0;
        }
        else
        {
            _S112 = false;
        }
        if(_S112)
        {
            _S112 = low_0 <= top_1;
        }
        else
        {
            _S112 = false;
        }
        if(_S112)
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
    float _S116 = c_12->cvVelumThick_0;
    if((c_12->cvVelumThick_0) > 0.0f)
    {
        float ext_0 = 1.89999997615814209f * _S110;
        float bottom_1 = c_12->cvVelumHeight_0 - 0.5f * _S116;
        float top_2 = c_12->cvVelumHeight_0 + _S116;
        if(gap2_0 < (ext_0 * ext_0))
        {
            _S112 = high_0 >= bottom_1;
        }
        else
        {
            _S112 = false;
        }
        if(_S112)
        {
            _S112 = low_0 <= top_2;
        }
        else
        {
            _S112 = false;
        }
        if(_S112)
        {
            best_0 = (F32_max((best_0), (0.2199999988079071f)));
        }
    }
    return c_12->cvSigma_0 * best_0 * 1.00001001358032227f;
}

static float convLift_0(ConvectionInput_0 * c_13, float above_0, float k_1)
{
    return (F32_min((c_13->cvBillow_0 * k_1 * smoothstep_0(0.0f, 150.0f, above_0) * lerp_1(0.60000002384185791f, 1.0f, saturate_0(above_0 / (F32_max((c_13->cvDepth_0), (1.0f)))))), (0.69999998807907104f * (F32_max((above_0), (0.0f))))));
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
    Organization_0 _S117 = flat_0;
    Vector<float, 2>  _S118 = orgPattern_0(&_S117, q0_0, spacing_2);
    Organization_0 _S119 = flat_0;
    Vector<float, 2>  _S120 = orgPattern_0(&_S119, q1_0, spacing_2);
    Vector<float, 2>  _S121 = Vector<float, 2> (q0_0.x, q1_0.y);
    Organization_0 _S122 = flat_0;
    Vector<float, 2>  _S123 = orgPattern_0(&_S122, _S121, spacing_2);
    Vector<float, 2>  _S124 = Vector<float, 2> (q1_0.x, q0_0.y);
    Organization_0 _S125 = flat_0;
    Vector<float, 2>  _S126 = orgPattern_0(&_S125, _S124, spacing_2);
    float grow_0 = o_6->ogWarp_0 * 1.5f + 0.00009999999747379f + 9.99999997475242708e-07f * (F32_max(((F32_max(((F32_abs((_S118.x)))), ((F32_abs((_S118.y))))))), ((F32_max(((F32_abs((_S120.x)))), ((F32_abs((_S120.y)))))))));
    *a_1 = min_1(min_1(_S118, _S123), min_1(_S126, _S120)) - (Vector<float, 2> )grow_0;
    *b_0 = max_1(max_1(_S118, _S123), max_1(_S126, _S120)) + (Vector<float, 2> )grow_0;
    return;
}

static void convSlotBound_0(ConvectionInput_0 * c_14, Vector<int32_t, 2>  slot_6, Vector<float, 2>  a_2, Vector<float, 2>  b_1, float * openTop_0, float * openNext_0, float * hiTop_0, float * loTop_0, float * loNext_0)
{
    float _S127 = convVigour_0(c_14, slot_6);
    if(_S127 <= 0.0f)
    {
        return;
    }
    Vector<float, 2>  _S128 = convCellCentre_0(c_14, slot_6);
    Vector<float, 2>  _S129 = a_2 - _S128;
    Vector<float, 2>  nearGap_1 = max_1(max_1(_S129, _S128 - b_1), Vector<float, 2> (0.0f, 0.0f));
    float dNear_0 = dot_1(nearGap_1, nearGap_1);
    if(dNear_0 >= 1.10249984264373779f)
    {
        return;
    }
    Vector<float, 2>  farGap_0 = max_1(abs_0(_S129), abs_0(b_1 - _S128));
    float oHi_0 = _S127 * convBump_0(dNear_0, 0.75f);
    float kHi_0 = _S127 * convBump_0(dNear_0, 1.04999995231628418f);
    float kLo_0 = _S127 * convBump_0(dot_1(farGap_0, farGap_0), 1.04999995231628418f);
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
    Vector<float, 2>  _S130 = floor_1((a_3 + b_2) * (Vector<float, 2> )0.5f);
    Vector<int32_t, 2>  _S131 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S130, 0), (int32_t)_slang_vector_get_element(_S130, 1)};
    Vector<float, 2>  _S132 = Vector<float, 2> {(float)_slang_vector_get_element(_S131, 0), (float)_slang_vector_get_element(_S131, 1)};
    Vector<float, 2>  highEdge_0 = _S132 + (Vector<float, 2> )1.0f + (Vector<float, 2> )0.00009999999747379f;
    bool _S133;
    if(all_0(a_3 >= (_S132 - (Vector<float, 2> )0.00009999999747379f)))
    {
        _S133 = all_0(b_2 <= highEdge_0);
    }
    else
    {
        _S133 = false;
    }
    int32_t j_7;
    int32_t i_13;
    if(_S133)
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
            i_13 = int(-1);
            for(;;)
            {
                if(i_13 <= int(1))
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, _S131 + Vector<int32_t, 2> (i_13, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_13 = i_13 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    else
    {
        Vector<float, 2>  _S134 = floor_1(a_3);
        Vector<int32_t, 2>  _S135 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S134, 0), (int32_t)_slang_vector_get_element(_S134, 1)};
        Vector<int32_t, 2>  _S136 = Vector<int32_t, 2> (int(1), int(1));
        Vector<int32_t, 2>  i0_0 = _S135 - _S136;
        Vector<float, 2>  _S137 = floor_1(b_2);
        Vector<int32_t, 2>  _S138 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S137, 0), (int32_t)_slang_vector_get_element(_S137, 1)};
        Vector<int32_t, 2>  _S139 = _S138 + _S136;
        int32_t _S140 = i0_0.y;
        j_7 = _S140;
        for(;;)
        {
            if(j_7 <= (_S139.y))
            {
                _S133 = j_7 <= (_S140 + int(32));
            }
            else
            {
                _S133 = false;
            }
            if(_S133)
            {
            }
            else
            {
                break;
            }
            int32_t _S141 = i0_0.x;
            i_13 = _S141;
            for(;;)
            {
                bool _S142;
                if(i_13 <= (_S139.x))
                {
                    _S142 = i_13 <= (_S141 + int(32));
                }
                else
                {
                    _S142 = false;
                }
                if(_S142)
                {
                }
                else
                {
                    break;
                }
                convSlotBound_0(c_15, Vector<int32_t, 2> (i_13, j_7), a_3, b_2, &openTop_1, &openNext_1, &hiTop_1, &loTop_1, &loNext_1);
                i_13 = i_13 + int(1);
            }
            j_7 = j_7 + int(1);
        }
    }
    float field_1 = lerp_1((F32_min((openNext_1 / 0.31000000238418579f), (1.0f))), (F32_max((hiTop_1 - loNext_1), (0.0f))), c_15->cvPolarity_0);
    float _S143 = c_15->cvLacunarity_0;
    float field_2;
    if((c_15->cvLacunarity_0) > 0.0f)
    {
        field_2 = lerp_1(field_1, 0.40000000596046448f, _S143);
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
    bool _S144;
    if(cover_1 <= 0.0f)
    {
        _S144 = true;
    }
    else
    {
        _S144 = (c_17->cvDepth_0) <= 0.0f;
    }
    if(_S144)
    {
        return 1.0e+09f;
    }
    float span_1 = (F32_sqrt((cover_1)));
    return 1.0f - span_1 + span_1 * (F32_pow(((F32_max((above_1), (0.0f))) / c_17->cvDepth_0), (1.0f / (F32_max((c_17->cvShape_0), (0.00100000004749745f))))));
}

static float convSlopeCap_0(ConvectionInput_0 * c_18)
{
    float _S145 = c_18->cvSpacing_0;
    float cap_1 = 7.0f / c_18->cvSpacing_0;
    if(((&c_18->cvOrg_0)->ogOn_0) == int(0))
    {
        return cap_1;
    }
    float _S146 = c_18->cvLacunarity_0;
    float cap_2;
    if((c_18->cvLacunarity_0) > 0.0f)
    {
        cap_2 = cap_1 + 1.5f / (0.15000000596046448f * _S146 * (F32_sqrt(((F32_sqrt((0.10000000149011612f)))))) * _S145);
    }
    else
    {
        cap_2 = cap_1;
    }
    float _S147 = c_18->cvGapWidth_0;
    if((c_18->cvGapWidth_0) > 0.0f)
    {
        cap_2 = cap_2 + 14.25f * c_18->cvPolarity_0 / (0.5f * _S147 * _S145);
    }
    return cap_2 + 3.0f * (&c_18->cvOrg_0)->ogWaveAmp_0 * length_1((&c_18->cvOrg_0)->ogWaveK_0);
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
            Vector<float, 4>  _S148 = convTurret_0(c_20, k_3);
            t_4 = _S148;
        }
        Vector<float, 4>  _S149 = t_4;
        Vector<float, 2>  _S150 = Vector<float, 2> {_S149.x, _S149.y};
        Vector<float, 2>  gap_0 = max_1(max_1(lo_3 - _S150, _S150 - hi_3), Vector<float, 2> (0.0f, 0.0f));
        float _S151 = t_4.z;
        float outer_0 = 1.29999995231628418f * _S151;
        float band_1 = outer_0 - 0.75f * _S151;
        if((dot_1(gap_0, gap_0)) < (outer_0 * outer_0))
        {
            slope_0 = (F32_max((slope_0), (1.5f / band_1)));
        }
        k_3 = k_3 + int(1);
    }
    return slope_0 * c_20->cvMoat_0;
}

static float convDistanceFloor_0(float vMin_0, float hMin_0)
{
    bool _S152;
    if(vMin_0 <= 0.0f)
    {
        _S152 = true;
    }
    else
    {
        _S152 = hMin_0 <= 0.0f;
    }
    if(_S152)
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
    return length_1(Vector<float, 2> (c_22->cvShapeHalfWidth_0 + lift_0, c_22->cvShapeRound_0 + c_22->cvReliefHeight_0 + lift_0));
}

static float convHeroReachAll_0(ConvectionInput_0 * c_23)
{
    float _S153 = convHeroReach_0(c_23);
    float _S154;
    if((c_23->cvShapeOn_0) != int(0))
    {
        float _S155 = convShapeReach_0(c_23);
        _S154 = (F32_max((_S153), (_S155)));
    }
    else
    {
        _S154 = _S153;
    }
    return _S154;
}

static float convDomeRadiusAt_0(float top_3, float radius_1, float shape_1, float above_2)
{
    bool _S156;
    if(top_3 <= 0.0f)
    {
        _S156 = true;
    }
    else
    {
        _S156 = above_2 >= top_3;
    }
    if(_S156)
    {
        return -1.0f;
    }
    return radius_1 * (F32_sqrt(((F32_max((1.0f - (F32_pow(((F32_max((above_2), (0.0f))) / top_3), (1.0f / (F32_max((shape_1), (0.00100000004749745f))))))), (0.0f))))));
}

static float convHeroRadiusAt_0(ConvectionInput_0 * c_24, float above_3)
{
    return convDomeRadiusAt_0(c_24->cvHeroTop_0, c_24->cvHeroRadius_0, c_24->cvShape_0, above_3);
}

static Vector<float, 4>  convShapeTexel_0(ConvectionInput_0 * c_25, int32_t i_14, int32_t j_8)
{
    int32_t k_4 = (j_8 * c_25->cvShapeDim_0.x + i_14) * int(4);
    return Vector<float, 4> (c_25->cvShapeMap_0.Load(k_4), c_25->cvShapeMap_0.Load(k_4 + int(1)), c_25->cvShapeMap_0.Load(k_4 + int(2)), c_25->cvShapeMap_0.Load(k_4 + int(3)));
}

static float convShapeDistance_0(ConvectionInput_0 * c_26, float u_3, float y_10, Vector<float, 2>  * slopeUY_0, float * relief_0)
{
    float _S157 = c_26->cvShapeTexel_0;
    Vector<float, 2>  st_0 = Vector<float, 2> (u_3, y_10) / (Vector<float, 2> )c_26->cvShapeTexel_0 + c_26->cvShapeOffset_0 - (Vector<float, 2> )0.5f;
    Vector<int32_t, 2>  _S158 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  last_0 = c_26->cvShapeDim_0 - _S158;
    Vector<float, 2>  _S159 = Vector<float, 2> {(float)_slang_vector_get_element(last_0, 0), (float)_slang_vector_get_element(last_0, 1)};
    Vector<float, 2>  q_6 = clamp_2(st_0, Vector<float, 2> (0.0f, 0.0f), _S159);
    float past_0 = length_1(st_0 - q_6);
    Vector<float, 2>  f0_0 = floor_1(q_6);
    Vector<int32_t, 2>  _S160 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(f0_0, 0), (int32_t)_slang_vector_get_element(f0_0, 1)};
    Vector<int32_t, 2>  i0_1 = min_0(_S160, last_0);
    Vector<int32_t, 2>  i1_0 = min_0(i0_1 + _S158, last_0);
    Vector<float, 2>  fr_0 = q_6 - f0_0;
    int32_t _S161 = i0_1.x;
    int32_t _S162 = i0_1.y;
    Vector<float, 4>  _S163 = convShapeTexel_0(c_26, _S161, _S162);
    int32_t _S164 = i1_0.x;
    Vector<float, 4>  _S165 = convShapeTexel_0(c_26, _S164, _S162);
    int32_t _S166 = i1_0.y;
    Vector<float, 4>  _S167 = convShapeTexel_0(c_26, _S161, _S166);
    Vector<float, 4>  _S168 = convShapeTexel_0(c_26, _S164, _S166);
    Vector<float, 4>  _S169 = (Vector<float, 4> )fr_0.x;
    Vector<float, 4>  blend_0 = lerp_3(lerp_3(_S163, _S165, _S169), lerp_3(_S167, _S168, _S169), (Vector<float, 4> )fr_0.y);
    *slopeUY_0 = Vector<float, 2> {blend_0.y, blend_0.z};
    *relief_0 = blend_0.w;
    return (blend_0.x - past_0) * _S157;
}

static float convShapeProfile_0(float dIn_0, float m_1, float rimR_0, Vector<float, 2>  * stepDM_0)
{
    if(dIn_0 >= rimR_0)
    {
        *stepDM_0 = Vector<float, 2> (0.0f, rimR_0 - m_1);
        return m_1 - rimR_0;
    }
    Vector<float, 2>  w_2 = Vector<float, 2> (dIn_0 - rimR_0, m_1);
    float len_0 = length_1(w_2);
    float gap_1 = len_0 - rimR_0;
    Vector<float, 2>  _S170;
    if(len_0 > 9.99999997475242708e-07f)
    {
        _S170 = w_2 * (Vector<float, 2> )(- gap_1 / len_0);
    }
    else
    {
        _S170 = Vector<float, 2> (0.0f, rimR_0);
    }
    *stepDM_0 = _S170;
    return gap_1;
}

static float convShapeBound_0(ConvectionInput_0 * c_27, Vector<float, 3>  lo_4, Vector<float, 3>  hi_4, float low_1, float high_1)
{
    Vector<float, 2>  ea_0 = Vector<float, 2> {lo_4.x, lo_4.z} - c_27->cvHeroAt_0;
    Vector<float, 2>  eb_0 = Vector<float, 2> {hi_4.x, hi_4.z} - c_27->cvHeroAt_0;
    float _S171 = c_27->cvShapeAxisU_0.y;
    float _S172 = - _S171;
    float _S173 = c_27->cvShapeAxisU_0.x;
    float _S174 = ea_0.x;
    float _S175 = _S174 * _S173;
    float _S176 = eb_0.x;
    float _S177 = _S176 * _S173;
    float _S178 = ea_0.y;
    float _S179 = _S178 * _S171;
    float _S180 = eb_0.y;
    float _S181 = _S180 * _S171;
    float uLo_0 = (F32_min((_S175), (_S177))) + (F32_min((_S179), (_S181)));
    float uHi_0 = (F32_max((_S175), (_S177))) + (F32_max((_S179), (_S181)));
    float _S182 = _S174 * _S172;
    float _S183 = _S176 * _S172;
    float _S184 = _S178 * _S173;
    float _S185 = _S180 * _S173;
    float nLo_0 = (F32_min((_S182), (_S183))) + (F32_min((_S184), (_S185)));
    float nHi_0 = (F32_max((_S182), (_S183))) + (F32_max((_S184), (_S185)));
    bool _S186;
    if(nLo_0 <= 0.0f)
    {
        _S186 = nHi_0 >= 0.0f;
    }
    else
    {
        _S186 = false;
    }
    float mMin_0;
    if(_S186)
    {
        mMin_0 = 0.0f;
    }
    else
    {
        mMin_0 = (F32_min(((F32_abs((nLo_0)))), ((F32_abs((nHi_0))))));
    }
    Vector<float, 2>  halfSpan_0 = Vector<float, 2> (0.5f * (uHi_0 - uLo_0), 0.5f * (high_1 - low_1));
    Vector<float, 2>  slopeUnused_0;
    float relief_1;
    float _S187 = convShapeDistance_0(c_27, 0.5f * (uLo_0 + uHi_0), 0.5f * (low_1 + high_1), &slopeUnused_0, &relief_1);
    float _S188 = length_1(halfSpan_0);
    float dMax_0 = _S187 + 2.5f * _S188;
    float _S189 = c_27->cvReliefHeight_0;
    if((c_27->cvReliefHeight_0) > 0.0f)
    {
        _S186 = nLo_0 > 0.0f;
    }
    else
    {
        _S186 = false;
    }
    if(_S186)
    {
        mMin_0 = (F32_max((nLo_0 - (F32_min((_S189), (_S189 * relief_1 + c_27->cvReliefSlope_0 * _S188)))), (0.0f)));
    }
    Vector<float, 2>  stepUnused_0;
    return - convShapeProfile_0(dMax_0, mMin_0, c_27->cvShapeRound_0, &stepUnused_0);
}

static float convTurretReach_0(ConvectionInput_0 * c_28, Vector<float, 4>  t_5)
{
    return t_5.z + 1.5f * c_28->cvBillow_0 * c_28->cvHeroBillow_0 + 24.0f;
}

static float convTurretBillow_0(ConvectionInput_0 * c_29, float radius_2)
{
    return lerp_1((F32_min((1.0f), (c_29->cvHeroBillow_0))), c_29->cvHeroBillow_0, saturate_0(radius_2 / (F32_max((c_29->cvHeroRadius_0), (1.0f)))));
}

static bool convTurretBound_0(ConvectionInput_0 * c_30, Vector<float, 4>  t_6, Vector<float, 3>  lo_5, Vector<float, 3>  hi_5, float low_2, float high_2, float * dPart_0, float * lift_1)
{
    *dPart_0 = -1.00000001504746622e+30f;
    *lift_1 = 0.0f;
    Vector<float, 2>  _S190 = Vector<float, 2> {t_6.x, t_6.y};
    Vector<float, 2>  nearGap_2 = max_1(max_1(Vector<float, 2> {lo_5.x, lo_5.z} - _S190, _S190 - Vector<float, 2> {hi_5.x, hi_5.z}), Vector<float, 2> (0.0f, 0.0f));
    float gap2_1 = dot_1(nearGap_2, nearGap_2);
    float _S191 = convTurretReach_0(c_30, t_6);
    if(gap2_1 >= (_S191 * _S191))
    {
        return false;
    }
    float rMin_0 = (F32_sqrt((gap2_1)));
    float _S192 = t_6.w;
    float _S193 = t_6.z;
    float tower_0 = convDomeHeight_0(_S192, _S193, c_30->cvShape_0, rMin_0);
    float ra_0 = convDomeRadiusAt_0(_S192, _S193, c_30->cvShape_0, low_2);
    float _S194 = convTurretBillow_0(c_30, _S193);
    float _S195 = convLift_0(c_30, high_2, _S194);
    *lift_1 = _S195;
    bool _S196 = ra_0 < 0.0f;
    bool _S197;
    if(_S196)
    {
        _S197 = true;
    }
    else
    {
        _S197 = rMin_0 >= ra_0;
    }
    if(_S197)
    {
        float hMin_1;
        if(_S196)
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
    float _S198 = convCeiling_0(c_31);
    float _S199 = c_31->cvMammaDepth_0;
    bool pouches_0;
    if(high_3 < (- c_31->cvMammaDepth_0))
    {
        pouches_0 = true;
    }
    else
    {
        pouches_0 = low_3 > _S198;
    }
    if(pouches_0)
    {
        return 0.0f;
    }
    if(_S199 > 0.0f)
    {
        pouches_0 = low_3 < 40.0f;
    }
    else
    {
        pouches_0 = false;
    }
    float _S200 = (F32_max((low_3), (0.0f)));
    float _S201 = (F32_min(((F32_max((high_3), (0.0f)))), (_S198)));
    bool _S202 = (c_31->cvHeroTop_0) > 0.0f;
    bool _S203;
    if(_S202)
    {
        if((c_31->cvPileusThick_0) > 0.0f)
        {
            _S203 = true;
        }
        else
        {
            _S203 = (c_31->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        _S203 = false;
    }
    float capBound_0;
    if(_S203)
    {
        float _S204 = convCapBound_0(c_31, lo_6, hi_6, _S200, _S201);
        capBound_0 = _S204;
    }
    else
    {
        capBound_0 = 0.0f;
    }
    float _S205 = convLift_0(c_31, _S201, 1.0f);
    float inside_0;
    if((c_31->cvHeroAlone_0) == int(0))
    {
        Vector<float, 2>  _S206 = Vector<float, 2> {lo_6.x, lo_6.z};
        Vector<float, 2>  _S207 = Vector<float, 2> {hi_6.x, hi_6.z};
        float _S208 = convUpdraftBound_0(c_31, _S206 - c_31->cvDrift_0, _S207 - c_31->cvDrift_0);
        float _S209 = convTowerHeight_0(c_31, _S208);
        float _S210 = convNeededUpdraft_0(c_31, _S200);
        if(_S208 < _S210)
        {
            float _S211 = convSlopeCap_0(c_31);
            if((c_31->cvMoat_0) > 0.0f)
            {
                float _S212 = convMoatSlopeOver_0(c_31, _S206, _S207);
                inside_0 = _S211 + _S212;
            }
            else
            {
                inside_0 = _S211;
            }
            inside_0 = _S205 - convDistanceFloor_0(_S200 - _S209, (_S210 - _S208) / inside_0);
        }
        else
        {
            inside_0 = (F32_max((_S209 - _S200), (0.0f))) + _S205;
        }
    }
    else
    {
        inside_0 = -1.00000001504746622e+30f;
    }
    float edge_0;
    if(_S202)
    {
        float rMin_1 = length_1(max_1(max_1(Vector<float, 2> {lo_6.x, lo_6.z} - c_31->cvHeroAt_0, c_31->cvHeroAt_0 - Vector<float, 2> {hi_6.x, hi_6.z}), Vector<float, 2> (0.0f, 0.0f)));
        float _S213 = convHeroReachAll_0(c_31);
        float groupD_0;
        float groupLift_0;
        if(rMin_1 < _S213)
        {
            float _S214 = convHeroHeight_0(c_31, rMin_1);
            float _S215 = convHeroRadiusAt_0(c_31, _S200);
            float _S216 = c_31->cvHeroBillow_0;
            float _S217 = convLift_0(c_31, _S201, c_31->cvHeroBillow_0);
            bool _S218 = _S215 < 0.0f;
            if(_S218)
            {
                _S203 = true;
            }
            else
            {
                _S203 = rMin_1 >= _S215;
            }
            if(_S203)
            {
                if(_S218)
                {
                    edge_0 = 1.00000001504746622e+30f;
                }
                else
                {
                    edge_0 = rMin_1 - _S215;
                }
                edge_0 = - convDistanceFloor_0(_S200 - _S214, edge_0);
            }
            else
            {
                edge_0 = (F32_max((_S214 - _S200), (0.0f)));
            }
            if((c_31->cvShapeOn_0) != int(0))
            {
                _S203 = (c_31->cvShapeDecay_0) < 1.0f;
            }
            else
            {
                _S203 = false;
            }
            if(_S203)
            {
                float _S219 = convShapeBound_0(c_31, lo_6, hi_6, _S200, _S201);
                float _S220 = lerp_1(_S219, edge_0, c_31->cvShapeDecay_0);
                float _S221 = convLift_0(c_31, _S201, _S216 * lerp_1(c_31->cvShapeBillow_0, 1.0f, c_31->cvShapeDecay_0));
                groupD_0 = _S220;
                groupLift_0 = _S221;
            }
            else
            {
                groupD_0 = edge_0;
                groupLift_0 = _S217;
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
            Vector<float, 4>  _S222 = convTurret_0(c_31, k_5);
            float turretD_0;
            float turretLift_0;
            bool _S223 = convTurretBound_0(c_31, _S222, lo_6, hi_6, _S200, _S201, &turretD_0, &turretLift_0);
            if(_S223)
            {
                float _S224 = (F32_max((groupLift_0), (turretLift_0)));
                groupD_0 = (F32_max((groupD_0), (turretD_0)));
                groupLift_0 = _S224;
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
        inside_0 = _S201 + _S199;
    }
    else
    {
        inside_0 = _S201;
    }
    return (F32_max((c_31->cvSigma_0 * (F32_sqrt((saturate_0(inside_0 / 40.0f)))) * edge_0 * 1.00001001358032227f), (capBound_0)));
}

static Vector<float, 2>  driftAt_0(GeneratorInput_0 * g_4, StructuredBuffer<Vector<float, 2> > disp_0, float depth_0)
{
    float x_24 = clamp_0(depth_0 / g_4->streakLength_0, 0.0f, 1.0f) * 32.0f;
    int32_t i_15 = clamp_1(int32_t((F32_floor((x_24)))), int(0), int(31));
    return lerp_2(disp_0.Load(i_15), disp_0.Load(i_15 + int(1)), (Vector<float, 2> )(x_24 - float(i_15)));
}

static void driftRange_0(GeneratorInput_0 * g_5, StructuredBuffer<Vector<float, 2> > disp_1, float d0_0, float d1_0, Vector<float, 2>  * lo_7, Vector<float, 2>  * hi_7)
{
    Vector<float, 2>  _S225 = driftAt_0(g_5, disp_1, d0_0);
    *lo_7 = _S225;
    *hi_7 = _S225;
    Vector<float, 2>  _S226 = driftAt_0(g_5, disp_1, d1_0);
    *lo_7 = min_1(*lo_7, _S226);
    *hi_7 = max_1(*hi_7, _S226);
    int32_t _S227 = clamp_1(int32_t((F32_ceil((clamp_0(d1_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    int32_t k_6 = clamp_1(int32_t((F32_floor((clamp_0(d0_0 / g_5->streakLength_0, 0.0f, 1.0f) * 32.0f)))), int(0), int(32));
    for(;;)
    {
        if(k_6 <= _S227)
        {
        }
        else
        {
            break;
        }
        *lo_7 = min_1(*lo_7, disp_1.Load(k_6));
        *hi_7 = max_1(*hi_7, disp_1.Load(k_6));
        k_6 = k_6 + int(1);
    }
    return;
}

static float cellFieldBound_0(GeneratorInput_0 * g_6, Vector<float, 2>  q0_2, Vector<float, 2>  q1_2)
{
    Vector<float, 2>  a_4;
    Vector<float, 2>  b_3;
    orgPatternBox_0(&g_6->gnOrg_0, q0_2 - g_6->cellDrift_0, q1_2 - g_6->cellDrift_0, g_6->cellSize_0 * 2.20000004768371582f, &a_4, &b_3);
    Vector<float, 2>  _S228 = orgJitter_0(&g_6->gnOrg_0, 0.80000001192092896f);
    Vector<float, 2>  _S229 = floor_1(a_4);
    Vector<int32_t, 2>  _S230 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S229, 0), (int32_t)_slang_vector_get_element(_S229, 1)};
    Vector<int32_t, 2>  _S231 = Vector<int32_t, 2> (int(1), int(1));
    Vector<int32_t, 2>  i0_2 = _S230 - _S231;
    Vector<float, 2>  _S232 = floor_1(b_3);
    Vector<int32_t, 2>  _S233 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S232, 0), (int32_t)_slang_vector_get_element(_S232, 1)};
    Vector<int32_t, 2>  _S234 = _S233 + _S231;
    int32_t _S235 = i0_2.y;
    int32_t j_9 = _S235;
    float acc_0 = 0.0f;
    for(;;)
    {
        bool _S236;
        if(j_9 <= (_S234.y))
        {
            _S236 = j_9 <= (_S235 + int(32));
        }
        else
        {
            _S236 = false;
        }
        if(_S236)
        {
        }
        else
        {
            break;
        }
        int32_t _S237 = i0_2.x;
        int32_t i_16 = _S237;
        float acc_1 = acc_0;
        for(;;)
        {
            bool _S238;
            if(i_16 <= (_S234.x))
            {
                _S238 = i_16 <= (_S237 + int(32));
            }
            else
            {
                _S238 = false;
            }
            if(_S238)
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_7 = Vector<int32_t, 2> (i_16, j_9);
            if((hash22_0(o_7, 2654435769U).x) > (g_6->cellDensity_0))
            {
                i_16 = i_16 + int(1);
                continue;
            }
            Vector<float, 2>  _S239 = Vector<float, 2> {(float)_slang_vector_get_element(o_7, 0), (float)_slang_vector_get_element(o_7, 1)};
            Vector<float, 2>  c_32 = _S239 + (Vector<float, 2> )0.5f + (hash22_0(o_7, 0U) - (Vector<float, 2> )0.5f) * _S228;
            acc_1 = acc_1 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(max_1(max_1(a_4 - c_32, c_32 - b_3), Vector<float, 2> (0.0f, 0.0f))) * 2.20000004768371582f);
            i_16 = i_16 + int(1);
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
    bool _S240;
    if(d1_1 < 0.0f)
    {
        _S240 = true;
    }
    else
    {
        _S240 = d0_1 > (g_7->streakLength_0);
    }
    if(_S240)
    {
        return 0.0f;
    }
    float _S241 = g_7->streakLength_0;
    float d0_2 = clamp_0(d0_1, 0.0f, g_7->streakLength_0);
    float d1_2 = clamp_0(d1_1, 0.0f, g_7->streakLength_0);
    float subl_0 = (F32_exp((- g_7->sublimation_0 * d0_2 / 1000.0f)));
    float head_0 = smoothstep_0(0.0f, 0.07999999821186066f * g_7->streakLength_0, d1_2);
    float tail_0 = 1.0f - smoothstep_0(0.75f * g_7->streakLength_0, g_7->streakLength_0, d0_2);
    float detail_0 = 1.0f + g_7->detailAmount_0 * 1.5f * 1.79999995231628418f;
    Vector<float, 2>  driftLo_0;
    Vector<float, 2>  driftHi_0;
    driftRange_0(g_7, disp_2, d0_2, d1_2, &driftLo_0, &driftHi_0);
    float _S242 = cellFieldBound_0(g_7, Vector<float, 2> (lo_8.x, lo_8.z) - driftHi_0, Vector<float, 2> (hi_8.x, hi_8.z) - driftLo_0);
    return (F32_max((_S242 * subl_0 * head_0 * tail_0 * (F32_max((detail_0), (0.0f)))), (0.0f))) * g_7->opticalDepth_0 / (F32_max((_S241), (1.0f)));
}

static float mediumBound_0(Medium_0 * m_2, StructuredBuffer<Vector<float, 2> > disp_3, Vector<float, 3>  lo_9, Vector<float, 3>  hi_9)
{
    int32_t _S243 = m_2->mode_0;
    if((m_2->mode_0) == int(3))
    {
        float _S244 = convectionBound_0(&m_2->conv_0, lo_9, hi_9);
        return _S244;
    }
    if(_S243 == int(2))
    {
        float _S245 = iceDensityBound_0(&m_2->gen_0, disp_3, lo_9, hi_9);
        return _S245;
    }
    return m_2->majorant_0;
}

static float gridBound_0(Medium_0 * m_3, MajorantGrid_0 * g_8, StructuredBuffer<float> bounds_2, StructuredBuffer<Vector<float, 2> > disp_4, Vector<int32_t, 3>  c_33, float fallback_0)
{
    int32_t _S246 = g_8->enabled_0;
    if((g_8->enabled_0) == int(0))
    {
        return fallback_0;
    }
    if(_S246 == int(2))
    {
        Vector<float, 3>  _S247 = Vector<float, 3> {(float)_slang_vector_get_element(c_33, 0), (float)_slang_vector_get_element(c_33, 1), (float)_slang_vector_get_element(c_33, 2)};
        Vector<float, 3>  lo_10 = g_8->origin_0 + _S247 * g_8->cellExtent_0;
        float _S248 = mediumBound_0(m_3, disp_4, lo_10, lo_10 + g_8->cellExtent_0);
        return _S248;
    }
    int32_t _S249 = c_33.x;
    bool _S250;
    if(_S249 < int(0))
    {
        _S250 = true;
    }
    else
    {
        _S250 = (c_33.y) < int(0);
    }
    if(_S250)
    {
        _S250 = true;
    }
    else
    {
        _S250 = (c_33.z) < int(0);
    }
    if(_S250)
    {
        _S250 = true;
    }
    else
    {
        _S250 = _S249 >= (g_8->dims_0.x);
    }
    if(_S250)
    {
        _S250 = true;
    }
    else
    {
        _S250 = (c_33.y) >= (g_8->dims_0.y);
    }
    if(_S250)
    {
        _S250 = true;
    }
    else
    {
        _S250 = (c_33.z) >= (g_8->dims_0.z);
    }
    if(_S250)
    {
        return fallback_0;
    }
    return bounds_2.Load((c_33.z * g_8->dims_0.y + c_33.y) * g_8->dims_0.x + _S249);
}

static float ddaExit_0(Dda_0 * d_6)
{
    return (F32_min((d_6->tMax_0.x), ((F32_min((d_6->tMax_0.y), (d_6->tMax_0.z))))));
}

static void ddaAdvance_0(Dda_0 * d_7)
{
    bool _S251;
    if((d_7->tMax_0.x) <= (d_7->tMax_0.y))
    {
        _S251 = (d_7->tMax_0.x) <= (d_7->tMax_0.z);
    }
    else
    {
        _S251 = false;
    }
    if(_S251)
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

static float randFloat_0(Rng_0 * r_5)
{
    uint32_t _S252 = r_5->state_0 * 747796405U + 2891336453U;
    r_5->state_0 = _S252;
    uint32_t word_0 = ((_S252 >> ((_S252 >> 28U) + 4U)) ^ _S252) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

static bool segmentStep_0(Medium_0 * m_4, MajorantGrid_0 * g_9, StructuredBuffer<float> bounds_3, StructuredBuffer<Vector<float, 2> > drift_3, float scale_0, float tEnd_0, Dda_0 * dda_0, float * rate_0, float * t_7, Rng_0 * rng_0, float * uKeep_0, float * uLive_0, float * uHit_0, int32_t * budget_0, int32_t * steps_0)
{
    *uKeep_0 = 0.0f;
    *uLive_0 = 0.0f;
    *uHit_0 = 0.0f;
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
        Dda_0 _S253 = *dda_0;
        float _S254 = ddaExit_0(&_S253);
        float _S255 = (F32_min((_S254), (tEnd_0)));
        if(!((*rate_0) > 0.0f))
        {
            if(_S255 >= tEnd_0)
            {
                return false;
            }
            *t_7 = _S255;
            ddaAdvance_0(dda_0);
            float _S256 = gridBound_0(m_4, g_9, bounds_3, drift_3, dda_0->cell_0, m_4->majorant_0);
            *rate_0 = _S256 * scale_0;
            continue;
        }
        float uStep_0 = randFloat_0(rng_0);
        float _S257 = randFloat_0(rng_0);
        *uKeep_0 = _S257;
        float _S258 = randFloat_0(rng_0);
        *uLive_0 = _S258;
        float _S259 = randFloat_0(rng_0);
        *uHit_0 = _S259;
        float _S260 = *t_7 - (F32_log(((F32_max((1.0f - uStep_0), (1.00000001168609742e-07f)))))) / *rate_0;
        *t_7 = _S260;
        if(_S260 >= _S255)
        {
            if(_S255 >= tEnd_0)
            {
                return false;
            }
            *t_7 = _S255;
            ddaAdvance_0(dda_0);
            float _S261 = gridBound_0(m_4, g_9, bounds_3, drift_3, dda_0->cell_0, m_4->majorant_0);
            *rate_0 = _S261 * scale_0;
            continue;
        }
        return true;
    }
    return false;
}

static MajorantGrid_0 gridFor_0(Medium_0 * m_5, MajorantGrid_0 * g_10, Vector<float, 3>  p_2)
{
    MajorantGrid_0 chosen_0 = *g_10;
    bool _S262;
    if((g_10->enabled_0) == int(2))
    {
        _S262 = (p_2.y) >= (m_5->slabBottom_0);
    }
    else
    {
        _S262 = false;
    }
    if(_S262)
    {
        _S262 = (p_2.y) <= (m_5->slabTop_0);
    }
    else
    {
        _S262 = false;
    }
    if(_S262)
    {
        (&chosen_0)->enabled_0 = int(0);
    }
    return chosen_0;
}

static float orgWaveFactor_0(Organization_0 * o_8, Vector<float, 2>  q_7)
{
    Vector<float, 2>  unused_0;
    float _S263 = orgWave_0(o_8, q_7, &unused_0);
    return _S263;
}

static float cellField_0(GeneratorInput_0 * g_11, Vector<float, 2>  q_8)
{
    Vector<float, 2>  _S264 = q_8 - g_11->cellDrift_0;
    Vector<float, 2>  _S265 = orgPattern_0(&g_11->gnOrg_0, _S264, g_11->cellSize_0 * 2.20000004768371582f);
    Vector<float, 2>  gf_0 = floor_1(_S265);
    Vector<int32_t, 2>  _S266 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(gf_0, 0), (int32_t)_slang_vector_get_element(gf_0, 1)};
    Vector<float, 2>  _S267 = orgJitter_0(&g_11->gnOrg_0, 0.80000001192092896f);
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
        int32_t i_17 = int(-1);
        float acc_3 = acc_2;
        for(;;)
        {
            if(i_17 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  o_9 = _S266 + Vector<int32_t, 2> (i_17, j_10);
            if((hash22_0(o_9, 2654435769U).x) > (g_11->cellDensity_0))
            {
                i_17 = i_17 + int(1);
                continue;
            }
            Vector<float, 2>  _S268 = Vector<float, 2> {(float)_slang_vector_get_element(o_9, 0), (float)_slang_vector_get_element(o_9, 1)};
            acc_3 = acc_3 + smoothstep_0(1.0f, 0.05000000074505806f, length_1(_S265 - (_S268 + (Vector<float, 2> )0.5f + (hash22_0(o_9, 0U) - (Vector<float, 2> )0.5f) * _S267)) * 2.20000004768371582f);
            i_17 = i_17 + int(1);
        }
        j_10 = j_10 + int(1);
        acc_2 = acc_3;
    }
    float _S269 = acc_2 * g_11->cellStrength_0;
    float _S270 = orgWaveFactor_0(&g_11->gnOrg_0, _S264);
    return _S269 * _S270;
}

static float fbm_0(Vector<float, 3>  p_3, int32_t octaves_1)
{
    int32_t i_18 = int(0);
    float amp_0 = 0.5f;
    Vector<float, 3>  _S271 = p_3;
    float sum_0 = 0.0f;
    float norm_0 = 0.0f;
    for(;;)
    {
        if(i_18 < int(6))
        {
        }
        else
        {
            break;
        }
        if(i_18 >= octaves_1)
        {
            break;
        }
        float sum_1 = sum_0 + amp_0 * gradientNoise_0(_S271);
        float norm_1 = norm_0 + amp_0;
        Vector<float, 3>  _S272 = _S271 * (Vector<float, 3> )2.01999998092651367f;
        float amp_1 = amp_0 * 0.5f;
        i_18 = i_18 + int(1);
        amp_0 = amp_1;
        _S271 = _S272;
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
    bool _S273;
    if(depth_1 < 0.0f)
    {
        _S273 = true;
    }
    else
    {
        _S273 = depth_1 > (g_12->streakLength_0);
    }
    if(_S273)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S274 = Vector<float, 2> {p_4.x, p_4.z};
    Vector<float, 2>  _S275 = driftAt_0(g_12, disp_5, depth_1);
    Vector<float, 2>  source_0 = _S274 - _S275;
    float _S276 = cellField_0(g_12, source_0);
    if(_S276 <= 0.00100000004749745f)
    {
        return 0.0f;
    }
    return (F32_max((_S276 * (F32_exp((- g_12->sublimation_0 * depth_1 / 1000.0f))) * smoothstep_0(0.0f, 0.07999999821186066f * g_12->streakLength_0, depth_1) * (1.0f - smoothstep_0(0.75f * g_12->streakLength_0, g_12->streakLength_0, depth_1)) * (F32_max((1.0f + g_12->detailAmount_0 * fbm_0(Vector<float, 3> ((source_0 / (Vector<float, 2> )g_12->detailScale_0).x, (source_0 / (Vector<float, 2> )g_12->detailScale_0).y, depth_1 / (F32_max((g_12->fallSpeed_0), (0.00999999977648258f))) * 0.01999999955296516f + g_12->timeSeconds_0 * 0.00999999977648258f), g_12->octaves_0) * 1.79999995231628418f), (0.0f)))), (0.0f))) * g_12->opticalDepth_0 / (F32_max((g_12->streakLength_0), (1.0f)));
}

static float convPouches_0(ConvectionInput_0 * c_34, Vector<float, 2>  q_9)
{
    Vector<float, 2>  g_13 = q_9 / (Vector<float, 2> )c_34->cvPouchSize_0;
    Vector<float, 2>  _S277 = floor_1(g_13);
    Vector<int32_t, 2>  _S278 = Vector<int32_t, 2> {(int32_t)_slang_vector_get_element(_S277, 0), (int32_t)_slang_vector_get_element(_S277, 1)};
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
        int32_t i_19 = int(-1);
        for(;;)
        {
            if(i_19 <= int(1))
            {
            }
            else
            {
                break;
            }
            Vector<int32_t, 2>  slot_7 = _S278 + Vector<int32_t, 2> (i_19, j_11);
            Vector<float, 2>  _S279 = Vector<float, 2> {(float)_slang_vector_get_element(slot_7, 0), (float)_slang_vector_get_element(slot_7, 1)};
            Vector<float, 2>  d_8 = g_13 - (_S279 + (Vector<float, 2> )0.5f + (hash22_0(slot_7, 739982445U) - (Vector<float, 2> )0.5f) * (Vector<float, 2> )0.60000002384185791f);
            float t2_0 = dot_1(d_8, d_8) / 0.46240001916885376f;
            if(t2_0 >= 1.0f)
            {
                i_19 = i_19 + int(1);
                continue;
            }
            Vector<float, 2>  h_3 = hash22_0(slot_7, 2135587861U);
            deepest_1 = (F32_max((deepest_1), (lerp_1(0.30000001192092896f, 1.0f, convLife_0((F32_frac((2.0f * c_34->cvAge_0 + h_3.x))))) * lerp_1(0.60000002384185791f, 1.0f, h_3.y) * (F32_sqrt((1.0f - t2_0))))));
            i_19 = i_19 + int(1);
        }
        int32_t j_12 = j_11 + int(1);
        deepest_0 = deepest_1;
        j_11 = j_12;
    }
    return deepest_0;
}

static void convMoatRing_0(Vector<float, 2>  xz_0, Vector<float, 2>  at_0, float radius_3, float * s_10, Vector<float, 2>  * gs_0, float * slope_1)
{
    Vector<float, 2>  d_9 = xz_0 - at_0;
    float r2_1 = dot_1(d_9, d_9);
    float outer_1 = 1.29999995231628418f * radius_3;
    if(!(r2_1 < (outer_1 * outer_1)))
    {
        return;
    }
    float band_2 = outer_1 - 0.75f * radius_3;
    float inner_1 = outer_1 - band_2;
    *slope_1 = (F32_max((*slope_1), (1.5f / band_2)));
    float r_6 = (F32_sqrt((r2_1)));
    float t_8 = saturate_0((r_6 - inner_1) / band_2);
    float f_1 = t_8 * t_8 * (3.0f - 2.0f * t_8);
    if(f_1 < (*s_10))
    {
        *s_10 = f_1;
        Vector<float, 2>  _S280;
        if(r_6 > 0.00100000004749745f)
        {
            _S280 = d_9 * (Vector<float, 2> )(6.0f * t_8 * (1.0f - t_8) / (band_2 * r_6));
        }
        else
        {
            _S280 = Vector<float, 2> (0.0f, 0.0f);
        }
        *gs_0 = _S280;
    }
    return;
}

static float convMoat_0(ConvectionInput_0 * c_35, Vector<float, 2>  xz_1, Vector<float, 2>  * grad_5, float * slopeAdd_0)
{
    float s_11 = 1.0f;
    Vector<float, 2>  gs_1 = Vector<float, 2> (0.0f, 0.0f);
    float slope_2 = 0.0f;
    convMoatRing_0(xz_1, c_35->cvHeroAt_0, c_35->cvHeroRadius_0, &s_11, &gs_1, &slope_2);
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
        Vector<float, 4>  _S281 = convTurret_0(c_35, k_7);
        convMoatRing_0(xz_1, Vector<float, 2> {_S281.x, _S281.y}, _S281.z, &s_11, &gs_1, &slope_2);
        k_7 = k_7 + int(1);
    }
    float _S282 = c_35->cvMoat_0;
    *grad_5 = gs_1 * (Vector<float, 2> )c_35->cvMoat_0;
    *slopeAdd_0 = slope_2 * _S282;
    return 1.0f - _S282 * (1.0f - s_11);
}

static float convUpdraftGrad_0(ConvectionInput_0 * c_36, Vector<float, 2>  q_10, Vector<float, 2>  * grad_6)
{
    if(((&c_36->cvOrg_0)->ogOn_0) == int(0))
    {
        float _S283 = convUpdraftGradT_2(c_36, q_10, grad_6);
        return _S283;
    }
    if((c_36->cvLacunarity_0) <= 0.0f)
    {
        float _S284 = convUpdraftGradT_1(c_36, q_10, grad_6);
        return _S284;
    }
    float _S285 = convUpdraftGradT_0(c_36, q_10, grad_6);
    return _S285;
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
    float _S286;
    if(v_2 >= 0.0f)
    {
        _S286 = d_10;
    }
    else
    {
        _S286 = - d_10;
    }
    return _S286;
}

static float convFieldBaseInside_0(ConvectionInput_0 * c_37, float w_3, Vector<float, 2>  slope_4, float cap_3)
{
    float _S287 = convTowerHeight_0(c_37, w_3);
    float v_3 = _S287 - 1.0f;
    float _S288 = convNeededUpdraft_0(c_37, 1.0f);
    return convSurfaceDistance_0(v_3, w_3 - _S288, (F32_min((length_1(slope_4)), (cap_3))));
}

static float convDomeSurface_0(float top_4, float radius_4, float shape_2, Vector<float, 2>  rel_0, float r_7, float py_0, float above_4, Vector<float, 3>  * x_25)
{
    float v_4 = convDomeHeight_0(top_4, radius_4, shape_2, r_7) - above_4;
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
        float h_4 = ra_1 - r_7;
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
        float _S289 = shiftOut_0;
        shiftOut_0 = shiftUp_0;
        shiftUp_0 = _S289;
        d_11 = d_12;
    }
    Vector<float, 2>  radial_0;
    if(r_7 > 0.00100000004749745f)
    {
        radial_0 = rel_0 / (Vector<float, 2> )r_7;
    }
    else
    {
        radial_0 = Vector<float, 2> (0.0f, 0.0f);
    }
    Vector<float, 2>  at_1 = rel_0 + radial_0 * (Vector<float, 2> )shiftOut_0;
    *x_25 = Vector<float, 3> (at_1.x, py_0 + shiftUp_0, at_1.y);
    return d_11;
}

static float convTowerSurface_0(ConvectionInput_0 * c_38, Vector<float, 2>  rel_1, float r_8, float py_1, float above_5, Vector<float, 3>  * x_26)
{
    float _S290 = convDomeSurface_0(c_38->cvHeroTop_0, c_38->cvHeroRadius_0, c_38->cvShape_0, rel_1, r_8, py_1, above_5, x_26);
    return _S290;
}

static float convReliefLift_0(ConvectionInput_0 * c_39, float dIn_1, float relief_2)
{
    return c_39->cvReliefHeight_0 * relief_2 * smoothstep_0(0.0f, (F32_max((c_39->cvReliefFade_0), (1.0f))), dIn_1);
}

static float convShapeSurface_0(ConvectionInput_0 * c_40, Vector<float, 2>  plane_0, float py_2, float above_6, Vector<float, 3>  * x_27)
{
    float _S291 = plane_0.x;
    Vector<float, 2>  slopeUY_1;
    float relief_3;
    float _S292 = convShapeDistance_0(c_40, _S291, above_6, &slopeUY_1, &relief_3);
    float _S293 = plane_0.y;
    float _S294 = (F32_abs((_S293)));
    bool _S295;
    if((c_40->cvReliefHeight_0) > 0.0f)
    {
        _S295 = _S293 > 0.0f;
    }
    else
    {
        _S295 = false;
    }
    float m_6;
    if(_S295)
    {
        float _S296 = convReliefLift_0(c_40, _S292, relief_3);
        m_6 = (F32_max((_S293 - _S296), (0.0f)));
    }
    else
    {
        m_6 = _S294;
    }
    Vector<float, 2>  stepDM_1;
    float gap_2 = convShapeProfile_0(_S292, m_6, c_40->cvShapeRound_0, &stepDM_1);
    float side_0;
    if(_S293 >= 0.0f)
    {
        side_0 = 1.0f;
    }
    else
    {
        side_0 = -1.0f;
    }
    *x_27 = Vector<float, 3> (_S291 + stepDM_1.x * slopeUY_1.x, py_2 + stepDM_1.x * slopeUY_1.y, _S293 + side_0 * stepDM_1.y);
    return - gap_2;
}

static bool convHeroSmooth_0(ConvectionInput_0 * c_41, Vector<float, 3>  p_5, float above_7, float * d_13, Vector<float, 3>  * x_28, float * amount_0, float * lobe_0)
{
    *d_13 = -1.00000001504746622e+30f;
    *x_28 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float _S297 = c_41->cvHeroBillow_0;
    *amount_0 = c_41->cvHeroBillow_0;
    *lobe_0 = _S297;
    Vector<float, 2>  rel_2 = Vector<float, 2> {p_5.x, p_5.z} - c_41->cvHeroAt_0;
    float r_9 = length_1(rel_2);
    float _S298 = convHeroReachAll_0(c_41);
    if(r_9 >= _S298)
    {
        return false;
    }
    if((c_41->cvShapeOn_0) == int(0))
    {
        float _S299 = convTowerSurface_0(c_41, rel_2, r_9, p_5.y, above_7, x_28);
        *d_13 = _S299;
    }
    else
    {
        Vector<float, 2>  plane_1 = Vector<float, 2> (dot_1(rel_2, c_41->cvShapeAxisU_0), dot_1(rel_2, Vector<float, 2> (- c_41->cvShapeAxisU_0.y, c_41->cvShapeAxisU_0.x)));
        float _S300 = c_41->cvShapeDecay_0;
        if((c_41->cvShapeDecay_0) >= 1.0f)
        {
            float _S301 = convTowerSurface_0(c_41, plane_1, r_9, p_5.y, above_7, x_28);
            *d_13 = _S301;
        }
        else
        {
            float _S302 = p_5.y;
            Vector<float, 3>  xs_0;
            float _S303 = convShapeSurface_0(c_41, plane_1, _S302, above_7, &xs_0);
            if(_S300 > 0.0f)
            {
                Vector<float, 3>  xt_0;
                float _S304 = convTowerSurface_0(c_41, plane_1, r_9, _S302, above_7, &xt_0);
                *d_13 = lerp_1(_S303, _S304, _S300);
                *x_28 = lerp_0(xs_0, xt_0, (Vector<float, 3> )_S300);
            }
            else
            {
                *d_13 = _S303;
                *x_28 = xs_0;
            }
            float _S305 = c_41->cvShapeBillow_0;
            *amount_0 = _S297 * lerp_1(c_41->cvShapeBillow_0, 1.0f, _S300);
            *lobe_0 = _S297 * lerp_1((F32_max((_S305), (0.30000001192092896f))), 1.0f, _S300);
        }
    }
    return true;
}

static bool convTurretSmooth_0(ConvectionInput_0 * c_42, Vector<float, 4>  t_9, Vector<float, 3>  p_6, float above_8, float * d_14, Vector<float, 3>  * x_29, float * k_8)
{
    *d_14 = -1.00000001504746622e+30f;
    *x_29 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *k_8 = 1.0f;
    Vector<float, 2>  rel_3 = Vector<float, 2> {p_6.x, p_6.z} - Vector<float, 2> {t_9.x, t_9.y};
    float r2_2 = dot_1(rel_3, rel_3);
    float _S306 = convTurretReach_0(c_42, t_9);
    if(r2_2 >= (_S306 * _S306))
    {
        return false;
    }
    float _S307 = t_9.w;
    if(above_8 >= (_S307 + c_42->cvBillow_0 * c_42->cvHeroBillow_0))
    {
        return false;
    }
    float r_10 = (F32_sqrt((r2_2)));
    float _S308 = t_9.z;
    float _S309 = convTurretBillow_0(c_42, _S308);
    *k_8 = _S309;
    Vector<float, 3>  own_0;
    float _S310 = convDomeSurface_0(_S307, _S308, c_42->cvShape_0, rel_3, r_10, p_6.y, above_8, &own_0);
    *d_14 = _S310;
    Vector<float, 3>  w_4 = own_0 + Vector<float, 3> (t_9.x - c_42->cvHeroAt_0.x, 0.0f, t_9.y - c_42->cvHeroAt_0.y);
    Vector<float, 3>  w_5;
    if((c_42->cvShapeOn_0) != int(0))
    {
        Vector<float, 2>  _S311 = Vector<float, 2> {w_4.x, w_4.z};
        w_5 = Vector<float, 3> (dot_1(_S311, c_42->cvShapeAxisU_0), w_4.y, dot_1(_S311, Vector<float, 2> (- c_42->cvShapeAxisU_0.y, c_42->cvShapeAxisU_0.x)));
    }
    else
    {
        w_5 = w_4;
    }
    *x_29 = w_5;
    return true;
}

static float convGroupBaseInside_0(ConvectionInput_0 * c_43, Vector<float, 2>  xz_2, bool nearGroup_0)
{
    float best_1;
    if((c_43->cvHeroTop_0) > 0.0f)
    {
        Vector<float, 3>  p_7 = Vector<float, 3> (xz_2.x, c_43->cvBase_0 + 1.0f, xz_2.y);
        float d_15;
        float amount_1;
        float lobe_1;
        Vector<float, 3>  x_30;
        bool _S312 = convHeroSmooth_0(c_43, p_7, 1.0f, &d_15, &x_30, &amount_1, &lobe_1);
        if(_S312)
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
            bool _S313;
            if(!nearGroup_0)
            {
                _S313 = true;
            }
            else
            {
                _S313 = k_9 >= (c_43->cvTurretCount_0);
            }
            if(_S313)
            {
                break;
            }
            Vector<float, 4>  _S314 = convTurret_0(c_43, k_9);
            float kt_0;
            bool _S315 = convTurretSmooth_0(c_43, _S314, p_7, 1.0f, &d_15, &x_30, &kt_0);
            if(_S315)
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

static float convBaseInside_0(ConvectionInput_0 * c_44, Vector<float, 2>  xz_3, bool nearGroup_1)
{
    float best_2;
    if((c_44->cvHeroAlone_0) == int(0))
    {
        float capMoat_0 = 0.0f;
        Vector<float, 2>  gMoat_0 = Vector<float, 2> (0.0f, 0.0f);
        bool moated_0;
        if((c_44->cvMoat_0) > 0.0f)
        {
            moated_0 = nearGroup_1;
        }
        else
        {
            moated_0 = false;
        }
        float m_7;
        if(moated_0)
        {
            float _S316 = convMoat_0(c_44, xz_3, &gMoat_0, &capMoat_0);
            m_7 = _S316;
        }
        else
        {
            m_7 = 1.0f;
        }
        if(m_7 > 0.0f)
        {
            Vector<float, 2>  slope_5;
            float _S317 = convUpdraftGrad_0(c_44, xz_3 - c_44->cvDrift_0, &slope_5);
            float _S318 = convSlopeCap_0(c_44);
            float cap_4;
            if(moated_0)
            {
                slope_5 = slope_5 * (Vector<float, 2> )m_7 + gMoat_0 * (Vector<float, 2> )_S317;
                float cap_5 = _S318 + capMoat_0;
                best_2 = _S317 * m_7;
                cap_4 = cap_5;
            }
            else
            {
                best_2 = _S317;
                cap_4 = _S318;
            }
            float _S319 = convFieldBaseInside_0(c_44, best_2, slope_5, cap_4);
            best_2 = _S319;
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
    float _S320 = convGroupBaseInside_0(c_44, xz_3, nearGroup_1);
    return (F32_max((best_2), (_S320)));
}

static float convMammaSagOf_0(ConvectionInput_0 * c_45, float pouch_0, float inside_2)
{
    if(inside_2 <= 0.0f)
    {
        return 0.0f;
    }
    return c_45->cvMammaDepth_0 * pouch_0 * smoothstep_0(0.0f, 0.60000002384185791f * c_45->cvPouchSize_0, inside_2);
}

static float convMammaSag_0(ConvectionInput_0 * c_46, Vector<float, 2>  xz_4, bool nearGroup_2, float below_0)
{
    float _S321 = convPouches_0(c_46, xz_4 - c_46->cvDrift_0);
    if((c_46->cvMammaDepth_0 * _S321) <= below_0)
    {
        return 0.0f;
    }
    float _S322 = convBaseInside_0(c_46, xz_4, nearGroup_2);
    float _S323 = convMammaSagOf_0(c_46, _S321, _S322);
    return _S323;
}

static Vector<float, 3>  convTwist_0(Vector<float, 3>  x_31)
{
    float _S324 = x_31.x;
    float _S325 = x_31.y;
    float _S326 = x_31.z;
    return Vector<float, 3> (0.0f * _S324 + 0.80000001192092896f * _S325 + 0.60000002384185791f * _S326, -0.80000001192092896f * _S324 + 0.36000001430511475f * _S325 - 0.47999998927116394f * _S326, -0.60000002384185791f * _S324 - 0.47999998927116394f * _S325 + 0.63999998569488525f * _S326);
}

static float convPuffs_0(Vector<float, 3>  x_32)
{
    Vector<float, 3>  fl_0 = floor_0(x_32);
    Vector<int32_t, 3>  _S327 = Vector<int32_t, 3> {(int32_t)_slang_vector_get_element(fl_0, 0), (int32_t)_slang_vector_get_element(fl_0, 1), (int32_t)_slang_vector_get_element(fl_0, 2)};
    Vector<float, 3>  f_2 = x_32 - fl_0;
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
    Vector<int32_t, 3>  _S328 = Vector<int32_t, 3> (dz_0, dy_0, dx_0);
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
                Vector<int32_t, 3>  off_0 = _S328 + Vector<int32_t, 3> (dx_0, dy_0, dz_0);
                Vector<float, 3>  _S329 = Vector<float, 3> {(float)_slang_vector_get_element(off_0, 0), (float)_slang_vector_get_element(off_0, 1), (float)_slang_vector_get_element(off_0, 2)};
                Vector<float, 3>  d_16 = _S329 + (Vector<float, 3> )0.5f + (Vector<float, 3> )0.25f * hash33_0(_S327 + off_0) - f_2;
                float _S330 = (F32_min((nearest_1), (dot_0(d_16, d_16))));
                int32_t dx_1 = dx_0 + int(1);
                nearest_1 = _S330;
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

static float convBillow_0(ConvectionInput_0 * c_47, Vector<float, 3>  p_8, float scale_1)
{
    Vector<float, 3>  _S331 = Vector<float, 3> (p_8.x, p_8.y - c_47->cvRise_0, p_8.z) / (Vector<float, 3> )scale_1;
    int32_t i_20 = int(0);
    Vector<float, 3>  x_33 = _S331;
    float amp_2 = 0.60000002384185791f;
    float sum_2 = 0.0f;
    float norm_2 = 0.0f;
    for(;;)
    {
        if(i_20 < int(4))
        {
        }
        else
        {
            break;
        }
        if(i_20 >= (c_47->cvOctaves_0))
        {
            break;
        }
        Vector<float, 3>  x_34 = convTwist_0(x_33);
        float sum_3 = sum_2 + amp_2 * convPuffs_0(x_34);
        float norm_3 = norm_2 + amp_2;
        Vector<float, 3>  x_35 = x_34 * (Vector<float, 3> )2.17000007629394531f;
        float amp_3 = amp_2 * 0.55000001192092896f;
        i_20 = i_20 + int(1);
        x_33 = x_35;
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

static float convInside_0(ConvectionInput_0 * c_48, float d_17, float lift_2, Vector<float, 3>  x_36, float scale_2)
{
    float _S332 = d_17 + lift_2;
    if(_S332 <= 0.0f)
    {
        return _S332;
    }
    if((d_17 - lift_2) >= 12.0f)
    {
        return 12.0f;
    }
    float _S333 = convBillow_0(c_48, x_36, scale_2);
    return d_17 + lift_2 * _S333;
}

static float convCapGrain_0(ConvectionInput_0 * c_49, Vector<float, 2>  rel_4, float scale_3)
{
    return saturate_0(0.80000001192092896f + 0.13330000638961792f * gradientNoise_0(Vector<float, 3> (rel_4.x / scale_3 + c_49->cvHeroSeed_0.x * 0.00100000004749745f, 0.37000000476837158f, rel_4.y / scale_3 + c_49->cvHeroSeed_0.z * 0.00100000004749745f)));
}

static float convCapDensity_0(ConvectionInput_0 * c_50, Vector<float, 3>  p_9, float above_9)
{
    Vector<float, 2>  rel_5 = Vector<float, 2> {p_9.x, p_9.z} - c_50->cvHeroAt_0;
    float r2_3 = dot_1(rel_5, rel_5);
    float _S334 = c_50->cvHeroRadius_0;
    float _S335 = c_50->cvPileusThick_0;
    float best_3;
    if((c_50->cvPileusThick_0) > 0.0f)
    {
        float rp_1 = 0.60000002384185791f * _S334;
        float _S336 = rp_1 * rp_1;
        if(r2_3 < _S336)
        {
            float lens_0 = 1.0f - r2_3 / _S336;
            float _S337 = c_50->cvPileusGap_0;
            float _S338 = convHeroHeight_0(c_50, (F32_sqrt((r2_3))) * 0.60000002384185791f);
            float most_0 = 0.5f * _S335 * lens_0;
            float _S339 = (F32_abs((above_9 - (_S337 + _S338))));
            if(_S339 < most_0)
            {
                float _S340 = convCapGrain_0(c_50, rel_5, 900.0f);
                float s_12 = most_0 * _S340 - _S339;
                if(s_12 > 0.0f)
                {
                    best_3 = (F32_max((0.0f), (0.44999998807907104f * smoothstep_0(0.0f, 15.0f, s_12))));
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
    float _S341 = c_50->cvVelumThick_0;
    if((c_50->cvVelumThick_0) > 0.0f)
    {
        float ext_1 = 1.89999997615814209f * _S334;
        if(r2_3 < (ext_1 * ext_1))
        {
            float r_11 = (F32_sqrt((r2_3)));
            Vector<float, 2>  dir_0;
            if(r_11 > 0.00100000004749745f)
            {
                dir_0 = rel_5 / (Vector<float, 2> )r_11;
            }
            else
            {
                dir_0 = Vector<float, 2> (1.0f, 0.0f);
            }
            float edge_1 = _S334 + (ext_1 - _S334) * saturate_0(0.875f + 0.08330000191926956f * gradientNoise_0(Vector<float, 3> (1.70000004768371582f * dir_0.x + c_50->cvHeroSeed_0.x * 0.00100000004749745f, 2.29999995231628418f, 1.70000004768371582f * dir_0.y + c_50->cvHeroSeed_0.z * 0.00100000004749745f)));
            float _S342 = 0.5f * _S341;
            float most_1 = _S342 * (1.0f - smoothstep_0(_S334 + 0.40000000596046448f * (edge_1 - _S334), edge_1, r_11));
            float _S343 = (F32_abs((above_9 - (c_50->cvVelumHeight_0 + _S342 * (1.0f - smoothstep_0(_S334, 2.0f * _S334, r_11))))));
            if(_S343 < most_1)
            {
                float _S344 = convCapGrain_0(c_50, rel_5, 2500.0f);
                float s_13 = most_1 * _S344 - _S343;
                if(s_13 > 0.0f)
                {
                    best_3 = (F32_max((best_3), (0.2199999988079071f * smoothstep_0(0.0f, 15.0f, s_13))));
                }
            }
        }
    }
    return c_50->cvSigma_0 * best_3;
}

static void convGroupFold_0(float d_18, Vector<float, 3>  x_37, float lift_3, float lobe_2, float * gMax_0, float * gSum_0, Vector<float, 3>  * gX_0, float * gLift_0, float * gLobe_0)
{
    if(d_18 > (*gMax_0))
    {
        float scale_4 = (F32_exp(((*gMax_0 - d_18) / 50.0f)));
        *gSum_0 = *gSum_0 * scale_4;
        *gX_0 = *gX_0 * (Vector<float, 3> )scale_4;
        *gLift_0 = *gLift_0 * scale_4;
        *gLobe_0 = *gLobe_0 * scale_4;
        *gMax_0 = d_18;
    }
    float wt_0 = (F32_exp(((d_18 - *gMax_0) / 50.0f)));
    *gSum_0 = *gSum_0 + wt_0;
    *gX_0 = *gX_0 + (Vector<float, 3> )wt_0 * x_37;
    *gLift_0 = *gLift_0 + wt_0 * lift_3;
    *gLobe_0 = *gLobe_0 + wt_0 * lobe_2;
    return;
}

static float convGroupInside_0(ConvectionInput_0 * c_51, Vector<float, 3>  p_10, float above_10, bool nearGroup_3)
{
    bool _S345;
    float gMax_1 = -1.00000001504746622e+30f;
    float gSum_1 = 0.0f;
    float gLift_1 = 0.0f;
    float gLobe_1 = 0.0f;
    Vector<float, 3>  gX_1 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float d_19;
    float amount_2;
    float lobe_3;
    Vector<float, 3>  x_38;
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
            _S345 = true;
        }
        else
        {
            _S345 = k_10 >= (c_51->cvTurretCount_0);
        }
        if(_S345)
        {
            break;
        }
        Vector<float, 4>  _S346 = convTurret_0(c_51, k_10);
        float kt_1;
        bool _S347 = convTurretSmooth_0(c_51, _S346, p_10, above_10, &d_19, &x_38, &kt_1);
        if(_S347)
        {
            float _S348 = convLift_0(c_51, above_10, kt_1);
            convGroupFold_0(d_19, x_38, _S348, kt_1, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
            anyTurret_0 = true;
        }
        k_10 = k_10 + int(1);
    }
    bool _S349 = convHeroSmooth_0(c_51, p_10, above_10, &d_19, &x_38, &amount_2, &lobe_3);
    float heroLift_0;
    if(_S349)
    {
        float _S350 = convLift_0(c_51, above_10, amount_2);
        heroLift_0 = _S350;
    }
    else
    {
        heroLift_0 = 0.0f;
    }
    if(!_S349)
    {
        _S345 = !anyTurret_0;
    }
    else
    {
        _S345 = false;
    }
    if(_S345)
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
        at_2 = x_38;
        lobeAt_0 = lobe_3;
    }
    else
    {
        if(_S349)
        {
            convGroupFold_0(d_19, x_38, heroLift_0, lobe_3, &gMax_1, &gSum_1, &gX_1, &gLift_1, &gLobe_1);
        }
        Vector<float, 3>  _S351 = gX_1 / (Vector<float, 3> )gSum_1;
        float _S352 = gLobe_1 / gSum_1;
        lift_4 = gLift_1 / gSum_1;
        at_2 = _S351;
        lobeAt_0 = _S352;
    }
    float _S353 = convInside_0(c_51, gMax_1, lift_4, at_2 + c_51->cvHeroSeed_0, c_51->cvBillowScale_0 * lobeAt_0);
    return _S353;
}

static float convHeroInside_0(ConvectionInput_0 * c_52, Vector<float, 3>  p_11, float above_11)
{
    float d_20;
    float amount_3;
    float lobe_4;
    Vector<float, 3>  x_39;
    bool _S354 = convHeroSmooth_0(c_52, p_11, above_11, &d_20, &x_39, &amount_3, &lobe_4);
    if(!_S354)
    {
        return -1.00000001504746622e+30f;
    }
    float _S355 = convLift_0(c_52, above_11, amount_3);
    float _S356 = convInside_0(c_52, d_20, _S355, x_39 + c_52->cvHeroSeed_0, c_52->cvBillowScale_0 * lobe_4);
    return _S356;
}

static float convectionDensity_0(ConvectionInput_0 * c_53, Vector<float, 3>  p_12)
{
    float _S357 = p_12.y;
    float above_12 = _S357 - c_53->cvBase_0;
    float _S358 = c_53->cvMammaDepth_0;
    bool rampBand_0;
    if(above_12 < (- c_53->cvMammaDepth_0))
    {
        rampBand_0 = true;
    }
    else
    {
        float _S359 = convCeiling_0(c_53);
        rampBand_0 = above_12 > _S359;
    }
    if(rampBand_0)
    {
        return 0.0f;
    }
    Vector<float, 2>  _S360 = Vector<float, 2> {p_12.x, p_12.z};
    Vector<float, 2>  fromHero_0 = _S360 - c_53->cvHeroAt_0;
    bool nearGroup_4 = (dot_1(fromHero_0, fromHero_0)) < (c_53->cvGroupReach_0 * c_53->cvGroupReach_0);
    bool _S361 = _S358 > 0.0f;
    if(_S361)
    {
        rampBand_0 = above_12 < 0.0f;
    }
    else
    {
        rampBand_0 = false;
    }
    if(rampBand_0)
    {
        float _S362 = convMammaSag_0(c_53, _S360, nearGroup_4, - above_12);
        float hang_0 = _S362 + above_12;
        if(hang_0 <= 0.0f)
        {
            return 0.0f;
        }
        return c_53->cvSigma_0 * (F32_sqrt((saturate_0(hang_0 / 40.0f)))) * smoothstep_0(0.0f, 12.0f, hang_0);
    }
    float _S363 = convLift_0(c_53, above_12, 1.0f - 0.60000002384185791f * c_53->cvLacunarity_0);
    if(_S361)
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
    if((c_53->cvHeroAlone_0) == int(0))
    {
        float capMoat_1 = 0.0f;
        Vector<float, 2>  _S364 = Vector<float, 2> (0.0f, 0.0f);
        Vector<float, 2>  gMoat_1 = _S364;
        if((c_53->cvMoat_0) > 0.0f)
        {
            moated_1 = nearGroup_4;
        }
        else
        {
            moated_1 = false;
        }
        if(moated_1)
        {
            float _S365 = convMoat_0(c_53, _S360, &gMoat_1, &capMoat_1);
            capDensity_0 = _S365;
        }
        else
        {
            capDensity_0 = 1.0f;
        }
        if(capDensity_0 > 0.0f)
        {
            Vector<float, 2>  q_11 = _S360 - c_53->cvDrift_0;
            Vector<float, 2>  slope_6;
            float _S366 = convUpdraftGrad_0(c_53, q_11, &slope_6);
            float _S367 = convSlopeCap_0(c_53);
            float cap_6;
            if(moated_1)
            {
                slope_6 = slope_6 * (Vector<float, 2> )capDensity_0 + gMoat_1 * (Vector<float, 2> )_S366;
                float cap_7 = _S367 + capMoat_1;
                sag_0 = _S366 * capDensity_0;
                cap_6 = cap_7;
            }
            else
            {
                sag_0 = _S366;
                cap_6 = _S367;
            }
            if(rampBand_0)
            {
                float _S368 = convFieldBaseInside_0(c_53, sag_0, slope_6, cap_6);
                baseField_0 = _S368;
            }
            else
            {
                baseField_0 = -1.00000001504746622e+30f;
            }
            float _S369 = convTowerHeight_0(c_53, sag_0);
            float v_5 = _S369 - above_12;
            float _S370 = convNeededUpdraft_0(c_53, above_12);
            float delta_1 = sag_0 - _S370;
            float d_21 = convSurfaceDistance_0(v_5, delta_1, (F32_min((length_1(slope_6)), (cap_6))));
            if((d_21 + _S363) > 0.0f)
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
                    shiftAcross_0 = _S364;
                }
                float _S371 = convInside_0(c_53, d_21, _S363, Vector<float, 3> (q_11.x + shiftAcross_0.x, _S357 + inside_3, q_11.y + shiftAcross_0.y), c_53->cvBillowScale_0);
                inside_3 = _S371;
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
    bool _S372 = (c_53->cvHeroTop_0) > 0.0f;
    if(_S372)
    {
        if((c_53->cvPileusThick_0) > 0.0f)
        {
            moated_1 = true;
        }
        else
        {
            moated_1 = (c_53->cvVelumThick_0) > 0.0f;
        }
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        float _S373 = convCapDensity_0(c_53, p_12, above_12);
        capDensity_0 = _S373;
    }
    else
    {
        capDensity_0 = 0.0f;
    }
    if(_S372)
    {
        moated_1 = inside_3 < 12.0f;
    }
    else
    {
        moated_1 = false;
    }
    if(moated_1)
    {
        if((c_53->cvTurretCount_0) > int(0))
        {
            float _S374 = convGroupInside_0(c_53, p_12, above_12, nearGroup_4);
            inside_3 = (F32_max((inside_3), (_S374)));
        }
        else
        {
            float _S375 = convHeroInside_0(c_53, p_12, above_12);
            inside_3 = (F32_max((inside_3), (_S375)));
        }
    }
    if(inside_3 <= 0.0f)
    {
        return capDensity_0;
    }
    if(rampBand_0)
    {
        float _S376 = convPouches_0(c_53, _S360 - c_53->cvDrift_0);
        if(_S376 > 0.0f)
        {
            float _S377 = convGroupBaseInside_0(c_53, _S360, nearGroup_4);
            float _S378 = convMammaSagOf_0(c_53, _S376, (F32_max((baseField_0), (_S377))));
            sag_0 = _S378;
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
    return (F32_max((c_53->cvSigma_0 * (F32_sqrt((saturate_0((above_12 + sag_0) / 40.0f)))) * smoothstep_0(0.0f, 12.0f, inside_3)), (capDensity_0)));
}

static float densityAt_0(Medium_0 * m_8, StructuredBuffer<Vector<float, 2> > disp_6, Vector<float, 3>  p_13)
{
    float _S379 = p_13.y;
    bool _S380;
    if(_S379 < (m_8->slabBottom_0))
    {
        _S380 = true;
    }
    else
    {
        _S380 = _S379 > (m_8->slabTop_0);
    }
    if(_S380)
    {
        return 0.0f;
    }
    if((m_8->clipOn_0) != int(0))
    {
        Vector<float, 2>  _S381 = Vector<float, 2> {p_13.x, p_13.z};
        if(any_1(_S381 < (m_8->clipLo_0)))
        {
            _S380 = true;
        }
        else
        {
            _S380 = any_1(_S381 > (m_8->clipHi_0));
        }
    }
    else
    {
        _S380 = false;
    }
    if(_S380)
    {
        return 0.0f;
    }
    float _S382 = m_8->fadeRadius_0;
    float fade_0;
    if((m_8->fadeRadius_0) > 0.0f)
    {
        float fade_1 = saturate_0((_S382 - length_1(Vector<float, 2> {p_13.x, p_13.z} - m_8->fadeAt_0)) / (F32_max((m_8->fadeWidth_0), (1.0f))));
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
    int32_t _S383 = m_8->mode_0;
    if((m_8->mode_0) == int(0))
    {
        return m_8->density_0 * fade_0;
    }
    if(_S383 == int(2))
    {
        float _S384 = iceDensity_0(&m_8->gen_0, disp_6, p_13);
        return _S384 * fade_0;
    }
    if(_S383 == int(3))
    {
        float _S385 = convectionDensity_0(&m_8->conv_0, p_13);
        return _S385 * fade_0;
    }
    Vector<float, 3>  d_22 = (p_13 - m_8->coreCentre_0) / (Vector<float, 3> )(F32_max((m_8->coreRadius_0), (9.99999997475242708e-07f)));
    return (m_8->density_0 + m_8->coreDensity_0 * (F32_exp((- dot_0(d_22, d_22))))) * fade_0;
}

static Vector<float, 2>  airMapAxisV_0(LayerShadowMap_0 * m_9)
{
    return Vector<float, 2> (- m_9->smAxisU_0.y, m_9->smAxisU_0.x);
}

static float clampf_0(float v_6, float lo_11, float hi_10)
{
    float _S386;
    if(v_6 < lo_11)
    {
        _S386 = lo_11;
    }
    else
    {
        if(v_6 > hi_10)
        {
            _S386 = hi_10;
        }
        else
        {
            _S386 = v_6;
        }
    }
    return _S386;
}

static float airMapTexel_0(LayerShadowMap_0 * m_10, int32_t iu_0, int32_t iv_0, int32_t k_11)
{
    return m_10->smTexels_0.Load((k_11 * m_10->smDimV_0 + iv_0) * m_10->smDimU_0 + iu_0);
}

static float layerMapTransmittance_0(LayerShadowMap_0 * m_11, Vector<float, 3>  p_14)
{
    int32_t _S387 = m_11->smDimU_0;
    int32_t _S388 = m_11->smDimV_0;
    int32_t _S389 = m_11->smSlices_0;
    uint32_t want_0 = uint32_t(m_11->smDimU_0 * m_11->smDimV_0 * m_11->smSlices_0);
    bool _S390;
    if(want_0 == 0U)
    {
        _S390 = true;
    }
    else
    {
        _S390 = uint32_t(StructuredBuffer_getCount_0(m_11->smTexels_0)) < want_0;
    }
    if(_S390)
    {
        return 1.0f;
    }
    float _S391 = p_14.y;
    float _S392 = m_11->smTop_0;
    if(_S391 >= (m_11->smTop_0))
    {
        return 1.0f;
    }
    Vector<float, 3>  _S393 = m_11->smSun_0;
    float _S394 = m_11->smBottom_0;
    Vector<float, 2>  q_12 = Vector<float, 2> {p_14.x, p_14.z} + Vector<float, 2> {_S393.x, _S393.z} * (Vector<float, 2> )((m_11->smBottom_0 - _S391) / m_11->smSun_0.y) - m_11->smCentre_0;
    Vector<float, 2>  _S395 = m_11->smLo_0;
    Vector<float, 2>  _S396 = m_11->smTexel_0;
    float fu_0 = (dot_1(q_12, m_11->smAxisU_0) - m_11->smLo_0.x) / m_11->smTexel_0.x - 0.5f;
    Vector<float, 2>  _S397 = airMapAxisV_0(m_11);
    float fv_0 = (dot_1(q_12, _S397) - _S395.y) / _S396.y - 0.5f;
    if(fu_0 >= -0.5f)
    {
        _S390 = fv_0 >= -0.5f;
    }
    else
    {
        _S390 = false;
    }
    if(_S390)
    {
        _S390 = fu_0 <= (float(_S387) - 0.5f);
    }
    else
    {
        _S390 = false;
    }
    if(_S390)
    {
        _S390 = fv_0 <= (float(_S388) - 0.5f);
    }
    else
    {
        _S390 = false;
    }
    if(!_S390)
    {
        return 1.0f;
    }
    int32_t _S398 = _S387 - int(1);
    float fu_1 = clampf_0(fu_0, 0.0f, float(_S398));
    int32_t _S399 = _S388 - int(1);
    float fv_1 = clampf_0(fv_0, 0.0f, float(_S399));
    int32_t u0_0 = int32_t(fu_1);
    int32_t v0_0 = int32_t(fv_1);
    int32_t _S400 = (I32_min((u0_0 + int(1)), (_S398)));
    int32_t _S401 = (I32_min((v0_0 + int(1)), (_S399)));
    float tu_0 = fu_1 - float(u0_0);
    float tv_0 = fv_1 - float(v0_0);
    int32_t _S402 = _S389 - int(1);
    float fk_0 = clampf_0((_S391 - _S394) / (F32_max((_S392 - _S394), (1.0f))), 0.0f, 1.0f) * float(_S402);
    int32_t _S403 = (I32_min((int32_t(fk_0)), (_S402)));
    int32_t _S404 = (I32_min((_S403 + int(1)), (_S402)));
    float tk_0 = fk_0 - float(_S403);
    float _S405 = airMapTexel_0(m_11, u0_0, v0_0, _S403);
    float _S406 = 1.0f - tu_0;
    float _S407 = _S405 * _S406;
    float _S408 = airMapTexel_0(m_11, _S400, v0_0, _S403);
    float a0_0 = _S407 + _S408 * tu_0;
    float _S409 = airMapTexel_0(m_11, u0_0, _S401, _S403);
    float _S410 = _S409 * _S406;
    float _S411 = airMapTexel_0(m_11, _S400, _S401, _S403);
    float b0_0 = _S410 + _S411 * tu_0;
    float _S412 = airMapTexel_0(m_11, u0_0, v0_0, _S404);
    float _S413 = _S412 * _S406;
    float _S414 = airMapTexel_0(m_11, _S400, v0_0, _S404);
    float a1_0 = _S413 + _S414 * tu_0;
    float _S415 = airMapTexel_0(m_11, u0_0, _S401, _S404);
    float _S416 = _S415 * _S406;
    float _S417 = airMapTexel_0(m_11, _S400, _S401, _S404);
    float _S418 = 1.0f - tv_0;
    return (a0_0 * _S418 + b0_0 * tv_0) * (1.0f - tk_0) + (a1_0 * _S418 + (_S416 + _S417 * tu_0) * tv_0) * tk_0;
}

static float transmittanceUpTo_0(Medium_0 * m_12, MajorantGrid_0 * g_14, StructuredBuffer<float> bounds_4, StructuredBuffer<Vector<float, 2> > disp_7, Rng_0 * rng_1, Vector<float, 3>  p_15, Vector<float, 3>  dir_1, float tMax_2, int32_t * steps_1)
{
    float t0_2;
    float t1_2;
    bool _S419 = slabRange_0(m_12, p_15, dir_1, &t0_2, &t1_2);
    if(!_S419)
    {
        return 1.0f;
    }
    float _S420 = (F32_max((t0_2), (0.0f)));
    t0_2 = _S420;
    t1_2 = (F32_min((t1_2), (tMax_2)));
    Dda_0 _S421 = ddaInit_0(g_14, p_15, dir_1, _S420);
    Dda_0 dda_1 = _S421;
    float _S422 = m_12->majorant_0;
    float _S423 = gridBound_0(m_12, g_14, bounds_4, disp_7, (&dda_1)->cell_0, m_12->majorant_0);
    float localMaj_0 = _S423;
    int32_t i_21 = int(0);
    float t_10 = _S420;
    float tr_0 = 1.0f;
    for(;;)
    {
        if(i_21 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_1 = *steps_1 + int(1);
        Dda_0 _S424 = dda_1;
        float _S425 = ddaExit_0(&_S424);
        float _S426 = (F32_min((_S425), (t1_2)));
        if(localMaj_0 <= 0.0f)
        {
            if(_S426 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S427 = gridBound_0(m_12, g_14, bounds_4, disp_7, (&dda_1)->cell_0, _S422);
            localMaj_0 = _S427;
            t_10 = _S426;
            i_21 = i_21 + int(1);
            continue;
        }
        float _S428 = randFloat_0(rng_1);
        float t_11 = t_10 - (F32_log(((F32_max((1.0f - _S428), (1.00000001168609742e-07f)))))) / localMaj_0;
        if(t_11 >= _S426)
        {
            if(_S426 >= t1_2)
            {
                break;
            }
            ddaAdvance_0(&dda_1);
            float _S429 = gridBound_0(m_12, g_14, bounds_4, disp_7, (&dda_1)->cell_0, _S422);
            localMaj_0 = _S429;
            t_10 = _S426;
            i_21 = i_21 + int(1);
            continue;
        }
        float _S430 = densityAt_0(m_12, disp_7, p_15 + dir_1 * (Vector<float, 3> )t_11);
        float tr_1 = tr_0 * (F32_max((0.0f), (1.0f - _S430 / localMaj_0)));
        float tr_2;
        if(tr_1 < 0.00999999977648258f)
        {
            float _S431 = randFloat_0(rng_1);
            if(_S431 > 0.5f)
            {
                return 0.0f;
            }
            tr_2 = tr_1 * 2.0f;
        }
        else
        {
            tr_2 = tr_1;
        }
        t_10 = t_11;
        tr_0 = tr_2;
        i_21 = i_21 + int(1);
    }
    return tr_0;
}

static float transmittance_0(Medium_0 * m_13, MajorantGrid_0 * g_15, StructuredBuffer<float> bounds_5, StructuredBuffer<Vector<float, 2> > disp_8, Rng_0 * rng_2, Vector<float, 3>  p_16, Vector<float, 3>  dir_2, int32_t * steps_2)
{
    float _S432 = transmittanceUpTo_0(m_13, g_15, bounds_5, disp_8, rng_2, p_16, dir_2, 1.00000001504746622e+30f, steps_2);
    return _S432;
}

static float transmittanceHandoff_0(Medium_0 * m_14, MajorantGrid_0 * g_16, StructuredBuffer<float> bounds_6, StructuredBuffer<Vector<float, 2> > disp_9, LayerShadowMap_0 * map_1, float handoff_0, Rng_0 * rng_3, Vector<float, 3>  p_17, Vector<float, 3>  dir_3, int32_t * steps_3)
{
    float t0_3;
    float t1_3;
    bool _S433 = slabRange_0(m_14, p_17, dir_3, &t0_3, &t1_3);
    if(!_S433)
    {
        return 1.0f;
    }
    float _S434 = (F32_max((t0_3), (0.0f)));
    t0_3 = _S434;
    float _S435 = map_1->smBottom_0;
    float _S436 = (map_1->smTop_0 - map_1->smBottom_0) / float((I32_max((map_1->smSlices_0 - int(1)), (int(1)))));
    Dda_0 _S437 = ddaInit_0(g_16, p_17, dir_3, _S434);
    Dda_0 dda_2 = _S437;
    float _S438 = m_14->majorant_0;
    float _S439 = gridBound_0(m_14, g_16, bounds_6, disp_9, (&dda_2)->cell_0, m_14->majorant_0);
    float tEnd_1 = t1_3;
    float localMaj_1 = _S439;
    bool toPlane_0 = false;
    float clearFrom_0 = _S434;
    int32_t i_22 = int(0);
    float t_12 = _S434;
    float tr_3 = 1.0f;
    for(;;)
    {
        if(i_22 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_3 = *steps_3 + int(1);
        Dda_0 _S440 = dda_2;
        float _S441 = ddaExit_0(&_S440);
        float _S442 = (F32_min((_S441), (tEnd_1)));
        float tEnd_2;
        bool toPlane_1;
        if(localMaj_1 <= 0.0f)
        {
            if(_S442 >= tEnd_1)
            {
                break;
            }
            ddaAdvance_0(&dda_2);
            float _S443 = gridBound_0(m_14, g_16, bounds_6, disp_9, (&dda_2)->cell_0, _S438);
            tEnd_2 = tEnd_1;
            localMaj_1 = _S443;
            toPlane_1 = toPlane_0;
            t_12 = _S442;
            int32_t i_23 = i_22 + int(1);
            tEnd_1 = tEnd_2;
            toPlane_0 = toPlane_1;
            i_22 = i_23;
            continue;
        }
        float _S444 = randFloat_0(rng_3);
        float t_13 = t_12 - (F32_log(((F32_max((1.0f - _S444), (1.00000001168609742e-07f)))))) / localMaj_1;
        if(t_13 >= _S442)
        {
            if(_S442 >= tEnd_1)
            {
                break;
            }
            ddaAdvance_0(&dda_2);
            float _S445 = gridBound_0(m_14, g_16, bounds_6, disp_9, (&dda_2)->cell_0, _S438);
            tEnd_2 = tEnd_1;
            localMaj_1 = _S445;
            toPlane_1 = toPlane_0;
            t_12 = _S442;
            int32_t i_23 = i_22 + int(1);
            tEnd_1 = tEnd_2;
            toPlane_0 = toPlane_1;
            i_22 = i_23;
            continue;
        }
        Vector<float, 3>  x_40 = p_17 + dir_3 * (Vector<float, 3> )t_13;
        float _S446 = densityAt_0(m_14, disp_9, x_40);
        float clearFrom_1;
        float tr_4;
        if(_S446 > 0.0f)
        {
            float tr_5 = tr_3 * (F32_max((0.0f), (1.0f - _S446 / localMaj_1)));
            float _S447 = t1_3;
            if(tr_5 < 0.00999999977648258f)
            {
                float _S448 = randFloat_0(rng_3);
                if(_S448 > 0.5f)
                {
                    return 0.0f;
                }
                tEnd_2 = tr_5 * 2.0f;
            }
            else
            {
                tEnd_2 = tr_5;
            }
            float _S449 = tEnd_2;
            tEnd_2 = _S447;
            toPlane_1 = false;
            clearFrom_1 = t_13;
            tr_4 = _S449;
        }
        else
        {
            bool _S450;
            if(!toPlane_0)
            {
                _S450 = (t_13 - clearFrom_0) >= handoff_0;
            }
            else
            {
                _S450 = false;
            }
            if(_S450)
            {
                float _S451 = x_40.y;
                float tPlane_0 = t_13 + (F32_max((_S435 + (F32_ceil(((_S451 - _S435) / _S436))) * _S436 - _S451), (0.0f))) / (F32_max((dir_3.y), (9.99999997475242708e-07f)));
                if(tPlane_0 < t1_3)
                {
                    tEnd_2 = tPlane_0;
                    toPlane_1 = true;
                }
                else
                {
                    tEnd_2 = tEnd_1;
                    toPlane_1 = toPlane_0;
                }
            }
            else
            {
                tEnd_2 = tEnd_1;
                toPlane_1 = toPlane_0;
            }
            clearFrom_1 = clearFrom_0;
            tr_4 = tr_3;
        }
        clearFrom_0 = clearFrom_1;
        t_12 = t_13;
        tr_3 = tr_4;
        int32_t i_23 = i_22 + int(1);
        tEnd_1 = tEnd_2;
        toPlane_0 = toPlane_1;
        i_22 = i_23;
    }
    if(toPlane_0)
    {
        float _S452 = layerMapTransmittance_0(map_1, p_17 + dir_3 * (Vector<float, 3> )tEnd_1);
        return tr_3 * _S452;
    }
    return tr_3;
}

static float sceneTransmittance_0(Scene_0 * s_14, StructuredBuffer<float> bounds_7, StructuredBuffer<Vector<float, 2> > drift_4, Rng_0 * rng_4, Vector<float, 3>  p_18, Vector<float, 3>  dir_4, int32_t * steps_4)
{
    float _S453 = s_14->shadowHandoff_0;
    bool handoff_1;
    if((s_14->shadowHandoff_0) > 0.0f)
    {
        handoff_1 = (s_14->airMapOn_0) != int(0);
    }
    else
    {
        handoff_1 = false;
    }
    bool _S454;
    if(handoff_1)
    {
        _S454 = (p_18.y) < ((&s_14->medium_0)->slabBottom_0);
    }
    else
    {
        _S454 = false;
    }
    float tr_6;
    if(_S454)
    {
        float _S455 = layerMapTransmittance_0(&s_14->airMapIce_0, p_18);
        tr_6 = _S455;
    }
    else
    {
        float _S456 = transmittance_0(&s_14->medium_0, &s_14->grid_0, bounds_7, drift_4, rng_4, p_18, dir_4, steps_4);
        tr_6 = _S456;
    }
    if((s_14->layer2On_0) != int(0))
    {
        _S454 = tr_6 > 0.0f;
    }
    else
    {
        _S454 = false;
    }
    if(_S454)
    {
        MajorantGrid_0 _S457 = gridFor_0(&s_14->medium2_0, &s_14->grid2_0, p_18);
        if(handoff_1)
        {
            float _S458 = _S453 * (F32_max(((&s_14->airMapCu_0)->smTexel_0.x), ((&s_14->airMapCu_0)->smTexel_0.y)));
            MajorantGrid_0 _S459 = _S457;
            float _S460 = transmittanceHandoff_0(&s_14->medium2_0, &_S459, bounds_7, drift_4, &s_14->airMapCu_0, _S458, rng_4, p_18, dir_4, steps_4);
            tr_6 = tr_6 * _S460;
        }
        else
        {
            MajorantGrid_0 _S461 = _S457;
            float _S462 = transmittance_0(&s_14->medium2_0, &_S461, bounds_7, drift_4, rng_4, p_18, dir_4, steps_4);
            tr_6 = tr_6 * _S462;
        }
    }
    return tr_6;
}

static float hg_0(float cosT_0, float g_17)
{
    float _S463 = g_17 * g_17;
    float d_23 = 1.0f + _S463 - 2.0f * g_17 * cosT_0;
    return (1.0f - _S463) / (12.56637096405029297f * d_23 * (F32_sqrt(((F32_max((d_23), (9.99999997475242708e-07f)))))));
}

static float phaseIce_0(float cosT_1)
{
    float t_14 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_1(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_14 * t_14))) * 0.34999999403953552f;
}

static float draine_0(float cosT_2, float g_18, float a_5)
{
    float _S464 = g_18 * g_18;
    float _S465 = 2.0f * g_18;
    float d_24 = 1.0f + _S464 - _S465 * cosT_2;
    return (1.0f - _S464) / (12.56637096405029297f * d_24 * (F32_sqrt(((F32_max((d_24), (9.99999997475242708e-07f))))))) * (1.0f + a_5 * cosT_2 * cosT_2) / (1.0f + a_5 * (1.0f + _S465 * g_18) / 3.0f);
}

static float phaseLiquid_0(PhaseInput_0 * p_19, float cosT_3)
{
    return (1.0f - p_19->draineW_0) * hg_0(cosT_3, p_19->hgG_0) + p_19->draineW_0 * draine_0(cosT_3, p_19->draineG_0, p_19->draineAlpha_0);
}

static float phaseAt_0(PhaseInput_0 * p_20, float cosT_4)
{
    float _S466;
    if((p_20->useIce_0) != int(0))
    {
        _S466 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S467 = phaseLiquid_0(p_20, cosT_4);
        _S466 = _S467;
    }
    return _S466;
}

static float phaseCamera_0(PhaseInput_0 * p_21, float cosT_5)
{
    float _S468 = phaseAt_0(p_21, cosT_5);
    float _S469 = p_21->lobeWeight_0;
    float v_7;
    if((p_21->lobeWeight_0) > 0.0f)
    {
        v_7 = _S468 + _S469 * hg_0(cosT_5, p_21->lobeG_0);
    }
    else
    {
        v_7 = _S468;
    }
    return v_7;
}

static float shellC_0(float altitude_0, float planetRadius_1, float shellHeight_0)
{
    float d_25 = altitude_0 - shellHeight_0;
    return d_25 * (d_25 + 2.0f * planetRadius_1 + 2.0f * shellHeight_0);
}

static float shellExit_0(float b_4, float c_54)
{
    float disc_0 = b_4 * b_4 - c_54;
    if(disc_0 < 0.0f)
    {
        return -1.0f;
    }
    return - b_4 + (F32_sqrt((disc_0)));
}

static float shellEnter_0(float b_5, float c_55)
{
    float disc_1 = b_5 * b_5 - c_55;
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

static float altitudeFromQ_0(float q_13, float planetRadius_2)
{
    float rr_0 = planetRadius_2 * planetRadius_2 + q_13;
    float _S470;
    if(rr_0 > 0.0f)
    {
        _S470 = rr_0;
    }
    else
    {
        _S470 = 0.0f;
    }
    return q_13 / (planetRadius_2 + (F32_sqrt((_S470))));
}

static Vector<float, 3>  airTransmittance_0(SkyInput_0 * p_22, float originAltitude_0, Vector<float, 3>  rayDir_0, float dist_1)
{
    float _S471 = p_22->planetRadius_0;
    float planetRadius_3;
    if((p_22->planetRadius_0) > 1000.0f)
    {
        planetRadius_3 = _S471;
    }
    else
    {
        planetRadius_3 = 1000.0f;
    }
    float _S472 = p_22->scaleHeight_0;
    float scaleHeight_1;
    if((p_22->scaleHeight_0) > 1.0f)
    {
        scaleHeight_1 = _S472;
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
    bool _S473;
    if(tTop_0 <= 0.0f)
    {
        _S473 = true;
    }
    else
    {
        _S473 = !(dist_1 > 0.0f);
    }
    if(_S473)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float tGround_0 = shellEnter_0(b_6, cGround_0);
    float tMax_3;
    if(tGround_0 > 0.0f)
    {
        tMax_3 = tGround_0;
    }
    else
    {
        tMax_3 = tTop_0;
    }
    if(dist_1 < tMax_3)
    {
        tMax_3 = dist_1;
    }
    Vector<float, 3>  betaR_0 = rayleighCoefficients_0();
    float betaMExt_0 = mieCoefficient_0(p_22->turbidity_0) * 1.11000001430511475f;
    float tPrev_0 = 0.0f;
    int32_t i_24 = int(0);
    float depthR_0 = 0.0f;
    float depthM_0 = 0.0f;
    for(;;)
    {
        if(i_24 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S474 = i_24 + int(1);
        float tNext_0 = tMax_3 * float(_S474 * _S474) * 0.00173611112404615f;
        float dt_0 = tNext_0 - tPrev_0;
        float tMid_0 = (tPrev_0 + tNext_0) * 0.5f;
        if(dt_0 <= 0.0f)
        {
            tPrev_0 = tNext_0;
            i_24 = _S474;
            continue;
        }
        float h_5 = altitudeFromQ_0(cGround_0 + 2.0f * tMid_0 * b_6 + tMid_0 * tMid_0, planetRadius_3);
        float hc_0;
        if(h_5 < 0.0f)
        {
            hc_0 = 0.0f;
        }
        else
        {
            hc_0 = h_5;
        }
        float _S475 = - hc_0;
        float depthM_1 = depthM_0 + (F32_exp((_S475 / 1200.0f))) * dt_0;
        depthR_0 = depthR_0 + (F32_exp((_S475 / scaleHeight_1))) * dt_0;
        depthM_0 = depthM_1;
        tPrev_0 = tNext_0;
        i_24 = _S474;
    }
    float _S476 = betaMExt_0 * depthM_0;
    return Vector<float, 3> ((F32_exp((- (betaR_0.x * depthR_0 + _S476)))), (F32_exp((- (betaR_0.y * depthR_0 + _S476)))), (F32_exp((- (betaR_0.z * depthR_0 + _S476)))));
}

static float sunIrradianceTop_0(SkyInput_0 * p_23)
{
    return 20.0f * p_23->sunIntensity_0;
}

static float toRadians_0(float degrees_0)
{
    return degrees_0 * 0.01745329238474369f;
}

static Vector<float, 3>  normalizeExact_0(Vector<float, 3>  v_8)
{
    float len2_0 = dot_0(v_8, v_8);
    if(len2_0 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    return v_8 * (Vector<float, 3> )(1.0f / (F32_sqrt((len2_0))));
}

static Vector<float, 3>  sunDirection_0(SkyInput_0 * p_24)
{
    float az_0 = toRadians_0(p_24->sunAzimuth_0);
    float el_0 = toRadians_0(p_24->sunElevation_0);
    float cosEl_0 = (F32_cos((el_0)));
    return normalizeExact_0(Vector<float, 3> ((F32_sin((az_0))) * cosEl_0, (F32_sin((el_0))), (F32_cos((az_0))) * cosEl_0));
}

static float lutMuFor_0(Vector<float, 3>  geocentric_0, Vector<float, 3>  sun_0)
{
    float len_1 = length_0(geocentric_0);
    float _S477;
    if(len_1 > 1.0f)
    {
        _S477 = dot_0(geocentric_0, sun_0) / len_1;
    }
    else
    {
        _S477 = dot_0(geocentric_0, sun_0);
    }
    return _S477;
}

static Vector<float, 3>  sampleTransmittanceLut_0(SkyInput_0 * p_25, float altitude_1, float mu_0)
{
    StructuredBuffer<float> _S478 = p_25->transmittanceLut_0;
    if(uint32_t(StructuredBuffer_getCount_0(p_25->transmittanceLut_0)) < 49152U)
    {
        return Vector<float, 3> (1.0f, 1.0f, 1.0f);
    }
    float _S479 = p_25->scaleHeight_0;
    float scaleHeight_2;
    if((p_25->scaleHeight_0) > 1.0f)
    {
        scaleHeight_2 = _S479;
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
    float _S480 = fx_1 - float(x0_1);
    float _S481 = fy_1 - float(y0_1);
    int32_t _S482 = y0_1 * int(256);
    int32_t _S483 = (_S482 + x0_1) * int(3);
    int32_t _S484 = (_S482 + x1_1) * int(3);
    int32_t _S485 = y1_1 * int(256);
    int32_t _S486 = (_S485 + x0_1) * int(3);
    int32_t _S487 = (_S485 + x1_1) * int(3);
    Vector<float, 3>  out_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    int32_t c_56 = int(0);
    for(;;)
    {
        if(c_56 < int(3))
        {
        }
        else
        {
            break;
        }
        float _S488 = 1.0f - _S480;
        float r_12 = (_S478.Load(_S483 + c_56) * _S488 + _S478.Load(_S484 + c_56) * _S480) * (1.0f - _S481) + (_S478.Load(_S486 + c_56) * _S488 + _S478.Load(_S487 + c_56) * _S480) * _S481;
        if(c_56 == int(0))
        {
            out_0.x = r_12;
        }
        else
        {
            if(c_56 == int(1))
            {
                out_0.y = r_12;
            }
            else
            {
                out_0.z = r_12;
            }
        }
        c_56 = c_56 + int(1);
    }
    return out_0;
}

static Vector<float, 3>  sunTransmittanceAt_0(SkyInput_0 * p_26, Vector<float, 3>  worldPos_0)
{
    Vector<float, 3>  _S489 = sunDirection_0(p_26);
    float _S490 = p_26->planetRadius_0;
    float planetRadius_4;
    if((p_26->planetRadius_0) > 1000.0f)
    {
        planetRadius_4 = _S490;
    }
    else
    {
        planetRadius_4 = 1000.0f;
    }
    float _S491 = worldPos_0.y;
    float altitude_2;
    if(_S491 > 0.0f)
    {
        altitude_2 = _S491;
    }
    else
    {
        altitude_2 = 0.0f;
    }
    Vector<float, 3>  _S492 = sampleTransmittanceLut_0(p_26, altitude_2, lutMuFor_0(Vector<float, 3> (worldPos_0.x, planetRadius_4 + _S491, worldPos_0.z), _S489));
    return _S492;
}

static Vector<float, 3>  sunIrradianceAt_0(Scene_0 * s_15, Vector<float, 3>  p_27)
{
    if(((&s_15->environment_0)->envMode_0) == int(1))
    {
        float _S493 = sunIrradianceTop_0(&(&s_15->environment_0)->sky_0);
        Vector<float, 3>  _S494 = sunTransmittanceAt_0(&(&s_15->environment_0)->sky_0, p_27);
        return (Vector<float, 3> )_S493 * _S494;
    }
    return s_15->sunIrradiance_0;
}

static Vector<float, 3>  cameraSegmentSun_0(Scene_0 * s_16, PhaseInput_0 * ph_0, StructuredBuffer<float> bounds_8, StructuredBuffer<Vector<float, 2> > drift_5, Rng_0 * rng_5, Rng_0 * rng2_0, Vector<float, 3>  ro_2, Vector<float, 3>  rd_2, int32_t * steps_5, int32_t * hit_0, Vector<float, 3>  * hitAt_0, int32_t * hitLayer_0, float * tResume_0, float tEnd_3, float * camT_0)
{
    bool rouletted_0;
    float ph0_0;
    float kept_0;
    float keptT_0;
    Vector<float, 3>  keptAt_0;
    int32_t keptLayer_0;
    Rng_0 _S495 = *rng2_0;
    *hit_0 = int(0);
    Vector<float, 3>  _S496 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *hitAt_0 = _S496;
    *hitLayer_0 = int(0);
    *tResume_0 = 0.0f;
    *camT_0 = 1.0f;
    float _S497 = (F32_max((s_16->neeTentativeScale_0), (1.0f)));
    float tA_0;
    float endA_0;
    bool _S498 = slabRange_0(&s_16->medium_0, ro_2, rd_2, &tA_0, &endA_0);
    float _S499 = (F32_max((tA_0), (0.0f)));
    tA_0 = _S499;
    endA_0 = (F32_min((endA_0), (tEnd_3)));
    Dda_0 _S500 = ddaInit_0(&s_16->grid_0, ro_2, rd_2, _S499);
    Dda_0 ddaA_0 = _S500;
    float _S501 = gridBound_0(&s_16->medium_0, &s_16->grid_0, bounds_8, drift_5, (&ddaA_0)->cell_0, (&s_16->medium_0)->majorant_0);
    float rateA_0 = _S501 * _S497;
    int32_t budgetA_0 = int(4096);
    float keepA_0 = 0.0f;
    float rouletteA_0 = 0.0f;
    float coinA_0 = 0.0f;
    bool haveA_0;
    if(_S498)
    {
        bool _S502 = segmentStep_0(&s_16->medium_0, &s_16->grid_0, bounds_8, drift_5, _S497, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_5, &keepA_0, &rouletteA_0, &coinA_0, &budgetA_0, steps_5);
        haveA_0 = _S502;
    }
    else
    {
        haveA_0 = _S498;
    }
    float tB_0 = 0.0f;
    float endB_0 = 0.0f;
    bool haveB_0;
    if((s_16->layer2On_0) != int(0))
    {
        bool _S503 = slabRange_0(&s_16->medium2_0, ro_2, rd_2, &tB_0, &endB_0);
        haveB_0 = _S503;
    }
    else
    {
        haveB_0 = false;
    }
    float _S504 = (F32_max((tB_0), (0.0f)));
    tB_0 = _S504;
    endB_0 = (F32_min((endB_0), (tEnd_3)));
    MajorantGrid_0 _S505 = gridFor_0(&s_16->medium2_0, &s_16->grid2_0, ro_2);
    MajorantGrid_0 _S506 = _S505;
    Dda_0 _S507 = ddaInit_0(&_S506, ro_2, rd_2, _S504);
    Dda_0 ddaB_0 = _S507;
    MajorantGrid_0 _S508 = _S505;
    float _S509 = gridBound_0(&s_16->medium2_0, &_S508, bounds_8, drift_5, (&ddaB_0)->cell_0, (&s_16->medium2_0)->majorant_0);
    float rateB_0 = _S509 * _S497;
    int32_t budgetB_0 = int(4096);
    float keepB_0 = 0.0f;
    float rouletteB_0 = 0.0f;
    float coinB_0 = 0.0f;
    if(haveB_0)
    {
        MajorantGrid_0 _S510 = _S505;
        bool _S511 = segmentStep_0(&s_16->medium2_0, &_S510, bounds_8, drift_5, _S497, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S495, &keepB_0, &rouletteB_0, &coinB_0, &budgetB_0, steps_5);
        haveB_0 = _S511;
    }
    float kept_1 = 0.0f;
    Vector<float, 3>  keptAt_1 = _S496;
    int32_t keptLayer_1 = int(0);
    float keptT_1 = 0.0f;
    float tr_7 = 1.0f;
    float total_0 = 0.0f;
    for(;;)
    {
        if(haveA_0)
        {
            rouletted_0 = true;
        }
        else
        {
            rouletted_0 = haveB_0;
        }
        if(rouletted_0)
        {
        }
        else
        {
            rouletted_0 = false;
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
        float uHit_1;
        if(takeA_0)
        {
            uHit_1 = coinA_0;
        }
        else
        {
            uHit_1 = coinB_0;
        }
        Vector<float, 3>  p_28 = ro_2 + rd_2 * (Vector<float, 3> )ph0_0;
        *tResume_0 = ph0_0;
        float sigma_0;
        if(takeA_0)
        {
            float _S512 = densityAt_0(&s_16->medium_0, drift_5, p_28);
            sigma_0 = _S512;
        }
        else
        {
            float _S513 = densityAt_0(&s_16->medium2_0, drift_5, p_28);
            sigma_0 = _S513;
        }
        if(sigma_0 > 0.0f)
        {
            float w_6 = sigma_0 / rate_1;
            bool _S514;
            if((*hit_0) == int(0))
            {
                _S514 = uHit_1 < w_6;
            }
            else
            {
                _S514 = false;
            }
            if(_S514)
            {
                *hit_0 = int(1);
                *hitAt_0 = p_28;
                if(takeA_0)
                {
                    keptLayer_0 = int(0);
                }
                else
                {
                    keptLayer_0 = int(1);
                }
                *hitLayer_0 = keptLayer_0;
            }
            float b_7 = tr_7 * w_6;
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
                    keptAt_0 = p_28;
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
            float tr_8 = tr_7 * (F32_max((0.0f), (1.0f - w_6)));
            float tr_9;
            if(tr_8 < 0.00999999977648258f)
            {
                if(uLive_1 > 0.5f)
                {
                    rouletted_0 = true;
                    tr_7 = tr_8;
                    total_0 = total_1;
                    break;
                }
                tr_9 = tr_8 * 2.0f;
            }
            else
            {
                tr_9 = tr_8;
            }
            tr_7 = tr_9;
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
            bool _S515 = segmentStep_0(&s_16->medium_0, &s_16->grid_0, bounds_8, drift_5, _S497, endA_0, &ddaA_0, &rateA_0, &tA_0, rng_5, &keepA_0, &rouletteA_0, &coinA_0, &budgetA_0, steps_5);
            haveA_0 = _S515;
        }
        else
        {
            MajorantGrid_0 _S516 = _S505;
            bool _S517 = segmentStep_0(&s_16->medium2_0, &_S516, bounds_8, drift_5, _S497, endB_0, &ddaB_0, &rateB_0, &tB_0, &_S495, &keepB_0, &rouletteB_0, &coinB_0, &budgetB_0, steps_5);
            haveB_0 = _S517;
        }
        kept_1 = kept_0;
        keptAt_1 = keptAt_0;
        keptLayer_1 = keptLayer_0;
        keptT_1 = keptT_0;
    }
    if((*hit_0) == int(0))
    {
        if(rouletted_0)
        {
            haveA_0 = true;
        }
        else
        {
            haveA_0 = budgetA_0 <= int(0);
        }
        if(haveA_0)
        {
            haveA_0 = true;
        }
        else
        {
            haveA_0 = budgetB_0 <= int(0);
        }
    }
    else
    {
        haveA_0 = false;
    }
    if(haveA_0)
    {
        *hit_0 = int(2);
    }
    if(rouletted_0)
    {
        kept_1 = 0.0f;
    }
    else
    {
        kept_1 = tr_7;
    }
    *camT_0 = kept_1;
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
        return _S496;
    }
    Vector<float, 3>  _S518 = s_16->sunDir_0;
    float _S519 = sceneTransmittance_0(s_16, bounds_8, drift_5, rng_5, keptAt_0 + s_16->sunDir_0 * (Vector<float, 3> )s_16->shadowOffset_0, s_16->sunDir_0, steps_5);
    Vector<float, 3>  _S520 = s_16->albedo_0;
    Vector<float, 3>  matterAlbedo_0;
    if(keptLayer_0 == int(0))
    {
        float _S521 = phaseCamera_0(ph_0, dot_0(rd_2, _S518));
        matterAlbedo_0 = _S520;
        ph0_0 = _S521;
    }
    else
    {
        float _S522 = phaseCamera_0(&s_16->phase2_0, dot_0(rd_2, _S518));
        matterAlbedo_0 = s_16->albedo2_0;
        ph0_0 = _S522;
    }
    Vector<float, 3>  _S523 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    if(((&s_16->environment_0)->envMode_0) == int(1))
    {
        haveA_0 = (s_16->aerialMode_0) != int(0);
    }
    else
    {
        haveA_0 = false;
    }
    Vector<float, 3>  air_0;
    if(haveA_0)
    {
        Vector<float, 3>  _S524 = airTransmittance_0(&(&s_16->environment_0)->sky_0, ro_2.y, rd_2, keptT_0);
        air_0 = _S524;
    }
    else
    {
        air_0 = _S523;
    }
    Vector<float, 3>  _S525 = (Vector<float, 3> )total_0 * matterAlbedo_0 * (Vector<float, 3> )ph0_0 * (Vector<float, 3> )_S519;
    Vector<float, 3>  _S526 = sunIrradianceAt_0(s_16, keptAt_0);
    return _S525 * _S526 * air_0;
}

static bool sampleFreeFlightUpTo_0(Medium_0 * m_15, MajorantGrid_0 * g_19, StructuredBuffer<float> bounds_9, StructuredBuffer<Vector<float, 2> > disp_10, Rng_0 * rng_6, Vector<float, 3>  ro_3, Vector<float, 3>  rd_3, float tLimit_0, Vector<float, 3>  * scatterPoint_0, float * distance_0, int32_t * steps_6)
{
    *scatterPoint_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    *distance_0 = 0.0f;
    float t0_4;
    float t1_4;
    bool _S527 = slabRange_0(m_15, ro_3, rd_3, &t0_4, &t1_4);
    if(!_S527)
    {
        return false;
    }
    float _S528 = (F32_min((t1_4), (tLimit_0)));
    t1_4 = _S528;
    if(!(_S528 > t0_4))
    {
        return false;
    }
    float _S529 = (F32_max((t0_4), (0.0f)));
    Dda_0 _S530 = ddaInit_0(g_19, ro_3, rd_3, _S529);
    Dda_0 dda_3 = _S530;
    float _S531 = m_15->majorant_0;
    float _S532 = gridBound_0(m_15, g_19, bounds_9, disp_10, (&dda_3)->cell_0, m_15->majorant_0);
    float localMaj_2 = _S532;
    int32_t i_25 = int(0);
    float t_15 = _S529;
    for(;;)
    {
        if(i_25 < int(4096))
        {
        }
        else
        {
            break;
        }
        *steps_6 = *steps_6 + int(1);
        Dda_0 _S533 = dda_3;
        float _S534 = ddaExit_0(&_S533);
        float _S535 = (F32_min((_S534), (t1_4)));
        if(localMaj_2 <= 0.0f)
        {
            if(_S535 >= t1_4)
            {
                return false;
            }
            ddaAdvance_0(&dda_3);
            float _S536 = gridBound_0(m_15, g_19, bounds_9, disp_10, (&dda_3)->cell_0, _S531);
            localMaj_2 = _S536;
            t_15 = _S535;
            i_25 = i_25 + int(1);
            continue;
        }
        float _S537 = randFloat_0(rng_6);
        float t_16 = t_15 - (F32_log(((F32_max((1.0f - _S537), (1.00000001168609742e-07f)))))) / localMaj_2;
        if(t_16 >= _S535)
        {
            if(_S535 >= t1_4)
            {
                return false;
            }
            ddaAdvance_0(&dda_3);
            float _S538 = gridBound_0(m_15, g_19, bounds_9, disp_10, (&dda_3)->cell_0, _S531);
            localMaj_2 = _S538;
            t_15 = _S535;
            i_25 = i_25 + int(1);
            continue;
        }
        Vector<float, 3>  p_29 = ro_3 + rd_3 * (Vector<float, 3> )t_16;
        float _S539 = randFloat_0(rng_6);
        float _S540 = densityAt_0(m_15, disp_10, p_29);
        if(_S539 < (_S540 / localMaj_2))
        {
            *scatterPoint_0 = p_29;
            *distance_0 = t_16;
            return true;
        }
        t_15 = t_16;
        i_25 = i_25 + int(1);
    }
    return false;
}

static bool sampleFreeFlight_0(Medium_0 * m_16, MajorantGrid_0 * g_20, StructuredBuffer<float> bounds_10, StructuredBuffer<Vector<float, 2> > disp_11, Rng_0 * rng_7, Vector<float, 3>  ro_4, Vector<float, 3>  rd_4, Vector<float, 3>  * scatterPoint_1, float * distance_1, int32_t * steps_7)
{
    bool _S541 = sampleFreeFlightUpTo_0(m_16, g_20, bounds_10, disp_11, rng_7, ro_4, rd_4, 1.00000001504746622e+30f, scatterPoint_1, distance_1, steps_7);
    return _S541;
}

static bool sceneFreeFlight_0(Scene_0 * s_17, StructuredBuffer<float> bounds_11, StructuredBuffer<Vector<float, 2> > drift_6, Rng_0 * rng_8, Vector<float, 3>  ro_5, Vector<float, 3>  rd_5, Vector<float, 3>  * scatterAt_0, int32_t * layer_0, int32_t * steps_8)
{
    *layer_0 = int(0);
    float dist_2;
    if((s_17->layer2On_0) == int(0))
    {
        bool _S542 = sampleFreeFlight_0(&s_17->medium_0, &s_17->grid_0, bounds_11, drift_6, rng_8, ro_5, rd_5, scatterAt_0, &dist_2, steps_8);
        return _S542;
    }
    float a0_1;
    float a1_1;
    bool _S543 = slabRange_0(&s_17->medium_0, ro_5, rd_5, &a0_1, &a1_1);
    float b0_1;
    float b1_0;
    bool _S544 = slabRange_0(&s_17->medium2_0, ro_5, rd_5, &b0_1, &b1_0);
    bool secondFirst_0;
    if(_S544)
    {
        if(!_S543)
        {
            secondFirst_0 = true;
        }
        else
        {
            secondFirst_0 = (F32_max((b0_1), (0.0f))) < (F32_max((a0_1), (0.0f)));
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
    MajorantGrid_0 _S545 = gridFor_0(&s_17->medium2_0, &s_17->grid2_0, ro_5);
    float _S546;
    if(secondFirst_0)
    {
        MajorantGrid_0 _S547 = _S545;
        bool _S548 = sampleFreeFlight_0(&s_17->medium2_0, &_S547, bounds_11, drift_6, rng_8, ro_5, rd_5, &pNear_0, &dNear_1, steps_8);
        if(_S548)
        {
            _S546 = dNear_1;
        }
        else
        {
            _S546 = 1.00000001504746622e+30f;
        }
        bool _S549 = sampleFreeFlightUpTo_0(&s_17->medium_0, &s_17->grid_0, bounds_11, drift_6, rng_8, ro_5, rd_5, _S546, &pFar_0, &dFar_0, steps_8);
        if(_S549)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(0);
            return true;
        }
        if(_S548)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(1);
            return true;
        }
    }
    else
    {
        bool _S550 = sampleFreeFlight_0(&s_17->medium_0, &s_17->grid_0, bounds_11, drift_6, rng_8, ro_5, rd_5, &pNear_0, &dNear_1, steps_8);
        if(_S550)
        {
            _S546 = dNear_1;
        }
        else
        {
            _S546 = 1.00000001504746622e+30f;
        }
        MajorantGrid_0 _S551 = _S545;
        bool _S552 = sampleFreeFlightUpTo_0(&s_17->medium2_0, &_S551, bounds_11, drift_6, rng_8, ro_5, rd_5, _S546, &pFar_0, &dFar_0, steps_8);
        if(_S552)
        {
            *scatterAt_0 = pFar_0;
            *layer_0 = int(1);
            return true;
        }
        if(_S550)
        {
            *scatterAt_0 = pNear_0;
            *layer_0 = int(0);
            return true;
        }
    }
    *scatterAt_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    return false;
}

static AirSegment_0 airSegment_0(SkyInput_0 * p_30, float originAltitude_1, Vector<float, 3>  rayDir_1, float dist_3, float u1_0, float u2_0)
{
    AirSegment_0 seg_0;
    Vector<float, 3>  _S553 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&seg_0)->airIn_0 = _S553;
    (&seg_0)->airT_0 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    (&seg_0)->shadowAt_0 = -1.0f;
    Vector<float, 3>  _S554 = sunDirection_0(p_30);
    float _S555 = p_30->planetRadius_0;
    float planetRadius_5;
    if((p_30->planetRadius_0) > 1000.0f)
    {
        planetRadius_5 = _S555;
    }
    else
    {
        planetRadius_5 = 1000.0f;
    }
    float _S556 = p_30->scaleHeight_0;
    float scaleHeight_3;
    if((p_30->scaleHeight_0) > 1.0f)
    {
        scaleHeight_3 = _S556;
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
    float _S557 = planetRadius_5 + observerAltitude_1;
    float _S558 = rayDir_1.y;
    float b_8 = _S557 * _S558;
    float cGround_1 = shellC_0(observerAltitude_1, planetRadius_5, 0.0f);
    float tTop_1 = shellExit_0(b_8, shellC_0(observerAltitude_1, planetRadius_5, atmosphereHeight_1));
    bool _S559;
    if(tTop_1 <= 0.0f)
    {
        _S559 = true;
    }
    else
    {
        _S559 = !(dist_3 > 0.0f);
    }
    if(_S559)
    {
        return seg_0;
    }
    float tGround_1 = shellEnter_0(b_8, cGround_1);
    float tMax_4;
    if(tGround_1 > 0.0f)
    {
        tMax_4 = tGround_1;
    }
    else
    {
        tMax_4 = tTop_1;
    }
    if(dist_3 < tMax_4)
    {
        tMax_4 = dist_3;
    }
    Vector<float, 3>  betaR_1 = rayleighCoefficients_0();
    float betaM_0 = mieCoefficient_0(p_30->turbidity_0);
    float betaMExt_1 = betaM_0 * 1.11000001430511475f;
    float cosTheta_0 = clampf_0(dot_0(rayDir_1, _S554), -1.0f, 1.0f);
    float phaseR_0 = 0.05968309938907623f * (1.0f + cosTheta_0 * cosTheta_0);
    float g_21 = clampf_0(p_30->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S560 = g_21 * g_21;
    float hgDenom_0 = 1.0f + _S560 - 2.0f * g_21 * cosTheta_0;
    float _S561 = 1.0f - _S560;
    float _S562 = 12.56637096405029297f * hgDenom_0;
    if(hgDenom_0 > 9.99999997475242708e-07f)
    {
        observerAltitude_1 = hgDenom_0;
    }
    else
    {
        observerAltitude_1 = 9.99999997475242708e-07f;
    }
    float phaseM_0 = _S561 / (_S562 * (F32_sqrt((observerAltitude_1))));
    float tPrev_1 = 0.0f;
    Vector<float, 3>  sumR_0 = _S553;
    Vector<float, 3>  sumM_0 = _S553;
    float u_4 = u1_0;
    float pickedFrom_0 = -1.0f;
    float pickedSpan_0 = 0.0f;
    int32_t i_26 = int(0);
    float depthR_1 = 0.0f;
    float depthM_2 = 0.0f;
    float lumTotal_0 = 0.0f;
    for(;;)
    {
        if(i_26 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S563 = i_26 + int(1);
        float tNext_1 = tMax_4 * float(_S563 * _S563) * 0.00173611112404615f;
        float dt_1 = tNext_1 - tPrev_1;
        float tMid_1 = (tPrev_1 + tNext_1) * 0.5f;
        float u_5;
        float pickedFrom_1;
        float pickedSpan_1;
        if(dt_1 <= 0.0f)
        {
            u_5 = u_4;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            tPrev_1 = tNext_1;
            u_4 = u_5;
            pickedFrom_0 = pickedFrom_1;
            pickedSpan_0 = pickedSpan_1;
            i_26 = _S563;
            continue;
        }
        float h_6 = altitudeFromQ_0(cGround_1 + 2.0f * tMid_1 * b_8 + tMid_1 * tMid_1, planetRadius_5);
        float hc_1;
        if(h_6 < 0.0f)
        {
            hc_1 = 0.0f;
        }
        else
        {
            hc_1 = h_6;
        }
        float _S564 = - hc_1;
        float dR_0 = (F32_exp((_S564 / scaleHeight_3))) * dt_1;
        float dM_0 = (F32_exp((_S564 / 1200.0f))) * dt_1;
        float midR_0 = depthR_1 + 0.5f * dR_0;
        float midM_0 = depthM_2 + 0.5f * dM_0;
        float depthR_2 = depthR_1 + dR_0;
        float depthM_3 = depthM_2 + dM_0;
        Vector<float, 3>  _S565 = sampleTransmittanceLut_0(p_30, hc_1, lutMuFor_0(Vector<float, 3> (rayDir_1.x * tMid_1, _S557 + _S558 * tMid_1, rayDir_1.z * tMid_1), _S554));
        float _S566 = betaMExt_1 * midM_0;
        Vector<float, 3>  transmittance_1 = Vector<float, 3> ((F32_exp((- (betaR_1.x * midR_0 + _S566)))), (F32_exp((- (betaR_1.y * midR_0 + _S566)))), (F32_exp((- (betaR_1.z * midR_0 + _S566))))) * _S565;
        Vector<float, 3>  _S567 = sumR_0 + transmittance_1 * (Vector<float, 3> )dR_0;
        Vector<float, 3>  _S568 = sumM_0 + transmittance_1 * (Vector<float, 3> )dM_0;
        Vector<float, 3>  c_57 = transmittance_1 * (betaR_1 * (Vector<float, 3> )(phaseR_0 * dR_0) + (Vector<float, 3> )(betaM_0 * (phaseM_0 * dM_0)));
        float lum_0 = c_57.x + c_57.y + c_57.z;
        float lumTotal_1;
        if(lum_0 > 0.0f)
        {
            float lumTotal_2 = lumTotal_0 + lum_0;
            float keep_3 = lum_0 / lumTotal_2;
            if(u_4 < keep_3)
            {
                u_5 = u_4 / keep_3;
                pickedFrom_1 = tPrev_1;
                pickedSpan_1 = dt_1;
            }
            else
            {
                u_5 = (u_4 - keep_3) / (1.0f - keep_3);
                pickedFrom_1 = pickedFrom_0;
                pickedSpan_1 = pickedSpan_0;
            }
            lumTotal_1 = lumTotal_2;
        }
        else
        {
            u_5 = u_4;
            pickedFrom_1 = pickedFrom_0;
            pickedSpan_1 = pickedSpan_0;
            lumTotal_1 = lumTotal_0;
        }
        sumR_0 = _S567;
        sumM_0 = _S568;
        depthR_1 = depthR_2;
        depthM_2 = depthM_3;
        lumTotal_0 = lumTotal_1;
        tPrev_1 = tNext_1;
        u_4 = u_5;
        pickedFrom_0 = pickedFrom_1;
        pickedSpan_0 = pickedSpan_1;
        i_26 = _S563;
    }
    float _S569 = sunIrradianceTop_0(p_30);
    (&seg_0)->airIn_0 = (sumR_0 * betaR_1 * (Vector<float, 3> )phaseR_0 + sumM_0 * (Vector<float, 3> )(betaM_0 * phaseM_0)) * (Vector<float, 3> )_S569;
    float _S570 = betaMExt_1 * depthM_2;
    (&seg_0)->airT_0 = Vector<float, 3> ((F32_exp((- (betaR_1.x * depthR_1 + _S570)))), (F32_exp((- (betaR_1.y * depthR_1 + _S570)))), (F32_exp((- (betaR_1.z * depthR_1 + _S570)))));
    if(pickedFrom_0 >= 0.0f)
    {
        (&seg_0)->shadowAt_0 = pickedFrom_0 + clampf_0(u2_0, 0.0f, 1.0f) * pickedSpan_0;
    }
    return seg_0;
}

static bool layerMapRange_0(LayerShadowMap_0 * m_17, Vector<float, 3>  ro_6, Vector<float, 3>  rd_6, float * t0_5, float * t1_5)
{
    *t0_5 = 0.0f;
    *t1_5 = 1.00000001504746622e+30f;
    int32_t _S571 = m_17->smDimU_0;
    int32_t _S572 = m_17->smDimV_0;
    uint32_t want_1 = uint32_t(m_17->smDimU_0 * m_17->smDimV_0 * m_17->smSlices_0);
    bool _S573;
    if(want_1 == 0U)
    {
        _S573 = true;
    }
    else
    {
        _S573 = uint32_t(StructuredBuffer_getCount_0(m_17->smTexels_0)) < want_1;
    }
    if(_S573)
    {
        return false;
    }
    float _S574 = rd_6.y;
    if((F32_abs((_S574))) < 9.99999971718068537e-10f)
    {
        if((ro_6.y) >= (m_17->smTop_0))
        {
            return false;
        }
    }
    else
    {
        float tt_0 = (m_17->smTop_0 - ro_6.y) / _S574;
        if(_S574 > 0.0f)
        {
            *t1_5 = (F32_min((*t1_5), (tt_0)));
        }
        else
        {
            *t0_5 = (F32_max((*t0_5), (tt_0)));
        }
    }
    Vector<float, 3>  _S575 = m_17->smSun_0;
    Vector<float, 2>  _S576 = Vector<float, 2> {_S575.x, _S575.z};
    float _S577 = m_17->smSun_0.y;
    Vector<float, 2>  q0_3 = Vector<float, 2> {ro_6.x, ro_6.z} + _S576 * (Vector<float, 2> )((m_17->smBottom_0 - ro_6.y) / _S577) - m_17->smCentre_0;
    Vector<float, 2>  dq_0 = Vector<float, 2> {rd_6.x, rd_6.z} - _S576 * (Vector<float, 2> )(_S574 / _S577);
    Vector<float, 2>  _S578 = airMapAxisV_0(m_17);
    float _S579 = m_17->smLo_0.x;
    float _S580 = m_17->smLo_0.y;
    float vHi_0 = _S580 + float(_S572) * m_17->smTexel_0.y;
    bool _S581 = clipAxis_0(dot_1(q0_3, m_17->smAxisU_0), dot_1(dq_0, m_17->smAxisU_0), _S579, _S579 + float(_S571) * m_17->smTexel_0.x, t0_5, t1_5);
    if(!_S581)
    {
        return false;
    }
    bool _S582 = clipAxis_0(dot_1(q0_3, _S578), dot_1(dq_0, _S578), _S580, vHi_0, t0_5, t1_5);
    if(!_S582)
    {
        return false;
    }
    return (*t1_5) > (*t0_5);
}

static Vector<float, 3>  airShadowLoss_0(SkyInput_0 * p_31, LayerShadowMap_0 * mapA_0, LayerShadowMap_0 * mapB_0, Vector<float, 3>  ro_7, Vector<float, 3>  rd_7, float dist_4, float jitter_1)
{
    Vector<float, 3>  none_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    float r0_0;
    float r1_0;
    bool _S583 = layerMapRange_0(mapA_0, ro_7, rd_7, &r0_0, &r1_0);
    float tA_1;
    float tB_1;
    if(_S583)
    {
        float _S584 = (F32_max((-1.00000001504746622e+30f), (r1_0)));
        tA_1 = (F32_min((1.00000001504746622e+30f), (r0_0)));
        tB_1 = _S584;
    }
    else
    {
        tA_1 = 1.00000001504746622e+30f;
        tB_1 = -1.00000001504746622e+30f;
    }
    bool _S585 = layerMapRange_0(mapB_0, ro_7, rd_7, &r0_0, &r1_0);
    if(_S585)
    {
        float _S586 = (F32_min((tA_1), (r0_0)));
        tB_1 = (F32_max((tB_1), (r1_0)));
        tA_1 = _S586;
    }
    if(!(tB_1 > tA_1))
    {
        return none_0;
    }
    Vector<float, 3>  _S587 = sunDirection_0(p_31);
    float _S588 = p_31->planetRadius_0;
    float planetRadius_6;
    if((p_31->planetRadius_0) > 1000.0f)
    {
        planetRadius_6 = _S588;
    }
    else
    {
        planetRadius_6 = 1000.0f;
    }
    float _S589 = p_31->scaleHeight_0;
    float scaleHeight_4;
    if((p_31->scaleHeight_0) > 1.0f)
    {
        scaleHeight_4 = _S589;
    }
    else
    {
        scaleHeight_4 = 1.0f;
    }
    float atmosphereHeight_2 = scaleHeight_4 * 8.0f;
    float _S590 = ro_7.y;
    float observerAltitude_2;
    if(_S590 > 0.0f)
    {
        observerAltitude_2 = _S590;
    }
    else
    {
        observerAltitude_2 = 0.0f;
    }
    float _S591 = planetRadius_6 + observerAltitude_2;
    float _S592 = rd_7.y;
    float b_9 = _S591 * _S592;
    float cGround_2 = shellC_0(observerAltitude_2, planetRadius_6, 0.0f);
    float tTop_2 = shellExit_0(b_9, shellC_0(observerAltitude_2, planetRadius_6, atmosphereHeight_2));
    bool _S593;
    if(tTop_2 <= 0.0f)
    {
        _S593 = true;
    }
    else
    {
        _S593 = !(dist_4 > 0.0f);
    }
    if(_S593)
    {
        return none_0;
    }
    float tGround_2 = shellEnter_0(b_9, cGround_2);
    float tMax_5;
    if(tGround_2 > 0.0f)
    {
        tMax_5 = tGround_2;
    }
    else
    {
        tMax_5 = tTop_2;
    }
    if(dist_4 < tMax_5)
    {
        tMax_5 = dist_4;
    }
    float _S594 = (F32_max((tA_1), (0.0f)));
    float _S595 = (F32_min((tB_1), (tMax_5)));
    if(!(_S595 > _S594))
    {
        return none_0;
    }
    Vector<float, 3>  betaR_2 = rayleighCoefficients_0();
    float betaM_1 = mieCoefficient_0(p_31->turbidity_0);
    float _S596 = betaM_1 * 1.11000001430511475f;
    float cosTheta_1 = clampf_0(dot_0(rd_7, _S587), -1.0f, 1.0f);
    float phaseR_1 = 0.05968309938907623f * (1.0f + cosTheta_1 * cosTheta_1);
    float g_22 = clampf_0(p_31->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S597 = g_22 * g_22;
    float hgDenom_1 = 1.0f + _S597 - 2.0f * g_22 * cosTheta_1;
    float _S598 = 1.0f - _S597;
    float _S599 = 12.56637096405029297f * hgDenom_1;
    if(hgDenom_1 > 9.99999997475242708e-07f)
    {
        tA_1 = hgDenom_1;
    }
    else
    {
        tA_1 = 9.99999997475242708e-07f;
    }
    float phaseM_1 = _S598 / (_S599 * (F32_sqrt((tA_1))));
    float depthR_3;
    float depthM_4;
    float hc_2;
    int32_t i_27;
    if(_S594 > 0.0f)
    {
        float _S600 = _S594 / 8.0f;
        i_27 = int(0);
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
        for(;;)
        {
            if(i_27 < int(8))
            {
            }
            else
            {
                break;
            }
            float tm_0 = (float(i_27) + 0.5f) * _S600;
            float h_7 = altitudeFromQ_0(cGround_2 + 2.0f * tm_0 * b_9 + tm_0 * tm_0, planetRadius_6);
            if(h_7 < 0.0f)
            {
                hc_2 = 0.0f;
            }
            else
            {
                hc_2 = h_7;
            }
            float _S601 = - hc_2;
            float depthR_4 = depthR_3 + (F32_exp((_S601 / scaleHeight_4))) * _S600;
            float depthM_5 = depthM_4 + (F32_exp((_S601 / 1200.0f))) * _S600;
            i_27 = i_27 + int(1);
            depthR_3 = depthR_4;
            depthM_4 = depthM_5;
        }
    }
    else
    {
        depthR_3 = 0.0f;
        depthM_4 = 0.0f;
    }
    float _S602 = clampf_0(jitter_1, 0.0f, 1.0f);
    float _S603 = _S595 - _S594;
    Vector<float, 3>  lossR_0 = none_0;
    Vector<float, 3>  lossM_0 = none_0;
    i_27 = int(0);
    for(;;)
    {
        if(i_27 < int(48))
        {
        }
        else
        {
            break;
        }
        float s0_0 = _S594 + _S603 * float(i_27 * i_27) * 0.00043402778101154f;
        int32_t _S604 = i_27 + int(1);
        float dt_2 = _S594 + _S603 * float(_S604 * _S604) * 0.00043402778101154f - s0_0;
        float ts_0 = s0_0 + _S602 * dt_2;
        float h_8 = altitudeFromQ_0(cGround_2 + 2.0f * ts_0 * b_9 + ts_0 * ts_0, planetRadius_6);
        if(h_8 < 0.0f)
        {
            hc_2 = 0.0f;
        }
        else
        {
            hc_2 = h_8;
        }
        float _S605 = - hc_2;
        float rhoR_0 = (F32_exp((_S605 / scaleHeight_4)));
        float rhoM_0 = (F32_exp((_S605 / 1200.0f)));
        float _S606 = ts_0 - s0_0;
        float atR_0 = depthR_3 + rhoR_0 * _S606;
        float atM_0 = depthM_4 + rhoM_0 * _S606;
        float depthR_5 = depthR_3 + rhoR_0 * dt_2;
        float depthM_6 = depthM_4 + rhoM_0 * dt_2;
        Vector<float, 3>  pw_0 = ro_7 + rd_7 * (Vector<float, 3> )ts_0;
        float _S607 = layerMapTransmittance_0(mapA_0, pw_0);
        float _S608 = layerMapTransmittance_0(mapB_0, pw_0);
        float v_9 = _S607 * _S608;
        if(v_9 >= 1.0f)
        {
            i_27 = _S604;
            depthR_3 = depthR_5;
            depthM_4 = depthM_6;
            continue;
        }
        Vector<float, 3>  _S609 = sampleTransmittanceLut_0(p_31, hc_2, lutMuFor_0(Vector<float, 3> (rd_7.x * ts_0, _S591 + _S592 * ts_0, rd_7.z * ts_0), _S587));
        float _S610 = _S596 * atM_0;
        Vector<float, 3>  w_7 = Vector<float, 3> ((F32_exp((- (betaR_2.x * atR_0 + _S610)))), (F32_exp((- (betaR_2.y * atR_0 + _S610)))), (F32_exp((- (betaR_2.z * atR_0 + _S610))))) * _S609 * (Vector<float, 3> )((1.0f - v_9) * dt_2);
        Vector<float, 3>  _S611 = lossM_0 + w_7 * (Vector<float, 3> )rhoM_0;
        lossR_0 = lossR_0 + w_7 * (Vector<float, 3> )rhoR_0;
        lossM_0 = _S611;
        i_27 = _S604;
        depthR_3 = depthR_5;
        depthM_4 = depthM_6;
    }
    Vector<float, 3>  _S612 = lossR_0 * betaR_2 * (Vector<float, 3> )phaseR_1 + lossM_0 * (Vector<float, 3> )(betaM_1 * phaseM_1);
    float _S613 = sunIrradianceTop_0(p_31);
    return _S612 * (Vector<float, 3> )_S613;
}

static float airShadow_0(Scene_0 * s_18, StructuredBuffer<float> bounds_12, StructuredBuffer<Vector<float, 2> > drift_7, Rng_0 * rng_9, AirSegment_0 * seg_1, Vector<float, 3>  ro_8, Vector<float, 3>  rd_8, int32_t * steps_9)
{
    bool _S614;
    if((s_18->aerialMode_0) < int(2))
    {
        _S614 = true;
    }
    else
    {
        _S614 = (seg_1->shadowAt_0) < 0.0f;
    }
    if(_S614)
    {
        return 1.0f;
    }
    float _S615 = sceneTransmittance_0(s_18, bounds_12, drift_7, rng_9, ro_8 + rd_8 * (Vector<float, 3> )seg_1->shadowAt_0, s_18->sunDir_0, steps_9);
    return _S615;
}

static float groundShadow_0(LayerShadowMap_0 * mapA_1, LayerShadowMap_0 * mapB_1, Vector<float, 3>  origin_1, Vector<float, 3>  dir_5)
{
    float _S616 = dir_5.y;
    bool _S617;
    if(!(_S616 < 0.0f))
    {
        _S617 = true;
    }
    else
    {
        _S617 = !((origin_1.y) > 0.0f);
    }
    if(_S617)
    {
        return 1.0f;
    }
    Vector<float, 3>  ground_0 = origin_1 + dir_5 * (Vector<float, 3> )(origin_1.y / - _S616);
    ground_0.y = 0.0f;
    float _S618 = layerMapTransmittance_0(mapA_1, ground_0);
    float _S619 = layerMapTransmittance_0(mapB_1, ground_0);
    return _S618 * _S619;
}

static Vector<float, 3>  skyRadiance_0(SkyInput_0 * p_32, float originAltitude_2, Vector<float, 3>  rayDir_2, bool includeSunDisc_0, float groundLit_0)
{
    float hc_3;
    Vector<float, 3>  _S620 = sunDirection_0(p_32);
    float _S621 = p_32->planetRadius_0;
    float planetRadius_7;
    if((p_32->planetRadius_0) > 1000.0f)
    {
        planetRadius_7 = _S621;
    }
    else
    {
        planetRadius_7 = 1000.0f;
    }
    float _S622 = p_32->scaleHeight_0;
    float scaleHeight_5;
    if((p_32->scaleHeight_0) > 1.0f)
    {
        scaleHeight_5 = _S622;
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
    float _S623 = planetRadius_7 + observerAltitude_3;
    float _S624 = rayDir_2.y;
    float b_10 = _S623 * _S624;
    float cGround_3 = shellC_0(observerAltitude_3, planetRadius_7, 0.0f);
    float tTop_3 = shellExit_0(b_10, shellC_0(observerAltitude_3, planetRadius_7, atmosphereHeight_3));
    if(tTop_3 <= 0.0f)
    {
        return Vector<float, 3> (0.0f, 0.0f, 0.0f);
    }
    float tGround_3 = shellEnter_0(b_10, cGround_3);
    bool hitsGround_0 = tGround_3 > 0.0f;
    if(hitsGround_0)
    {
        observerAltitude_3 = tGround_3;
    }
    else
    {
        observerAltitude_3 = tTop_3;
    }
    Vector<float, 3>  betaR_3 = rayleighCoefficients_0();
    float betaM_2 = mieCoefficient_0(p_32->turbidity_0);
    float betaMExt_2 = betaM_2 * 1.11000001430511475f;
    float cosTheta_2 = clampf_0(dot_0(rayDir_2, _S620), -1.0f, 1.0f);
    float phaseR_2 = 0.05968309938907623f * (1.0f + cosTheta_2 * cosTheta_2);
    float g_23 = clampf_0(p_32->mieAnisotropy_0, -0.94999998807907104f, 0.94999998807907104f);
    float _S625 = g_23 * g_23;
    float hgDenom_2 = 1.0f + _S625 - 2.0f * g_23 * cosTheta_2;
    float _S626 = 1.0f - _S625;
    float _S627 = 12.56637096405029297f * hgDenom_2;
    float tPrev_2;
    if(hgDenom_2 > 9.99999997475242708e-07f)
    {
        tPrev_2 = hgDenom_2;
    }
    else
    {
        tPrev_2 = 9.99999997475242708e-07f;
    }
    float phaseM_2 = _S626 / (_S627 * (F32_sqrt((tPrev_2))));
    Vector<float, 3>  _S628 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    tPrev_2 = 0.0f;
    Vector<float, 3>  sumR_1 = _S628;
    Vector<float, 3>  sumM_1 = _S628;
    int32_t i_28 = int(0);
    float depthR_6 = 0.0f;
    float depthM_7 = 0.0f;
    for(;;)
    {
        if(i_28 < int(24))
        {
        }
        else
        {
            break;
        }
        int32_t _S629 = i_28 + int(1);
        float tNext_2 = observerAltitude_3 * float(_S629 * _S629) * 0.00173611112404615f;
        float dt_3 = tNext_2 - tPrev_2;
        float tMid_2 = (tPrev_2 + tNext_2) * 0.5f;
        if(dt_3 <= 0.0f)
        {
            tPrev_2 = tNext_2;
            i_28 = _S629;
            continue;
        }
        float h_9 = altitudeFromQ_0(cGround_3 + 2.0f * tMid_2 * b_10 + tMid_2 * tMid_2, planetRadius_7);
        if(h_9 < 0.0f)
        {
            hc_3 = 0.0f;
        }
        else
        {
            hc_3 = h_9;
        }
        float _S630 = - hc_3;
        float dR_1 = (F32_exp((_S630 / scaleHeight_5))) * dt_3;
        float dM_1 = (F32_exp((_S630 / 1200.0f))) * dt_3;
        float midR_1 = depthR_6 + 0.5f * dR_1;
        float midM_1 = depthM_7 + 0.5f * dM_1;
        float depthR_7 = depthR_6 + dR_1;
        float depthM_8 = depthM_7 + dM_1;
        Vector<float, 3>  _S631 = sampleTransmittanceLut_0(p_32, hc_3, lutMuFor_0(Vector<float, 3> (rayDir_2.x * tMid_2, _S623 + _S624 * tMid_2, rayDir_2.z * tMid_2), _S620));
        float _S632 = betaMExt_2 * midM_1;
        Vector<float, 3>  transmittance_2 = Vector<float, 3> ((F32_exp((- (betaR_3.x * midR_1 + _S632)))), (F32_exp((- (betaR_3.y * midR_1 + _S632)))), (F32_exp((- (betaR_3.z * midR_1 + _S632))))) * _S631;
        Vector<float, 3>  _S633 = sumM_1 + transmittance_2 * (Vector<float, 3> )dM_1;
        sumR_1 = sumR_1 + transmittance_2 * (Vector<float, 3> )dR_1;
        sumM_1 = _S633;
        depthR_6 = depthR_7;
        depthM_7 = depthM_8;
        tPrev_2 = tNext_2;
        i_28 = _S629;
    }
    float _S634 = sunIrradianceTop_0(p_32);
    Vector<float, 3>  radiance_0 = (sumR_1 * betaR_3 * (Vector<float, 3> )phaseR_2 + sumM_1 * (Vector<float, 3> )(betaM_2 * phaseM_2)) * (Vector<float, 3> )_S634;
    Vector<float, 3>  radiance_1;
    if(hitsGround_0)
    {
        Vector<float, 3>  groundPoint_0 = Vector<float, 3> (rayDir_2.x * tGround_3, _S623 + _S624 * tGround_3, rayDir_2.z * tGround_3);
        float nDotL_0 = clampf_0(dot_0(normalizeExact_0(groundPoint_0), _S620), 0.0f, 1.0f);
        Vector<float, 3>  _S635 = sampleTransmittanceLut_0(p_32, 0.0f, lutMuFor_0(groundPoint_0, _S620));
        float _S636 = betaMExt_2 * depthM_7;
        Vector<float, 3>  viewT_0 = Vector<float, 3> ((F32_exp((- (betaR_3.x * depthR_6 + _S636)))), (F32_exp((- (betaR_3.y * depthR_6 + _S636)))), (F32_exp((- (betaR_3.z * depthR_6 + _S636)))));
        radiance_1 = radiance_0 + viewT_0 * _S635 * (Vector<float, 3> )(p_32->groundAlbedo_0 * nDotL_0 * 0.31830987334251404f * _S634 * groundLit_0) + viewT_0 * p_32->groundSkyLight_0;
    }
    else
    {
        radiance_1 = radiance_0;
    }
    bool _S637;
    if(!hitsGround_0)
    {
        _S637 = includeSunDisc_0;
    }
    else
    {
        _S637 = false;
    }
    if(_S637)
    {
        float cosRadius_0 = (F32_cos((toRadians_0(p_32->sunAngularRadius_0))));
        if(cosTheta_2 > cosRadius_0)
        {
            float _S638 = betaMExt_2 * depthM_7;
            Vector<float, 3>  viewT_1 = Vector<float, 3> ((F32_exp((- (betaR_3.x * depthR_6 + _S638)))), (F32_exp((- (betaR_3.y * depthR_6 + _S638)))), (F32_exp((- (betaR_3.z * depthR_6 + _S638)))));
            float solidAngle_0 = 6.28318548202514648f * (1.0f - cosRadius_0);
            if(solidAngle_0 > 9.99999971718068537e-10f)
            {
                hc_3 = solidAngle_0;
            }
            else
            {
                hc_3 = 9.99999971718068537e-10f;
            }
            radiance_1 = radiance_1 + viewT_1 * (Vector<float, 3> )(_S634 / hc_3);
        }
    }
    return radiance_1;
}

static Vector<float, 3>  environmentRadiance_0(Environment_0 * e_0, Vector<float, 3>  origin_2, Vector<float, 3>  dir_6, bool includeSunDisc_1, float groundLit_1)
{
    if((e_0->envMode_0) == int(1))
    {
        Vector<float, 3>  _S639 = skyRadiance_0(&e_0->sky_0, origin_2.y, dir_6, includeSunDisc_1, groundLit_1);
        return _S639;
    }
    return e_0->uniformRadiance_0;
}

static Vector<float, 3>  pathEnvironment_0(Scene_0 * s_19, Vector<float, 3>  ro_9, Vector<float, 3>  rd_9, bool first_0)
{
    float groundLit_2;
    if((s_19->airMapOn_0) != int(0))
    {
        float _S640 = groundShadow_0(&s_19->airMapIce_0, &s_19->airMapCu_0, ro_9, rd_9);
        groundLit_2 = _S640;
    }
    else
    {
        groundLit_2 = 1.0f;
    }
    bool _S641;
    if(first_0)
    {
        _S641 = (s_19->hideSunDisc_0) == int(0);
    }
    else
    {
        _S641 = false;
    }
    Vector<float, 3>  _S642 = environmentRadiance_0(&s_19->environment_0, ro_9, rd_9, _S641, groundLit_2);
    Vector<float, 3>  env_0;
    if(!first_0)
    {
        env_0 = _S642 + s_19->ltAmbient_0;
    }
    else
    {
        env_0 = _S642;
    }
    return env_0;
}

static Vector<float, 3>  lightTriple_0(StructuredBuffer<float> b_11, int32_t i_29)
{
    return Vector<float, 3> (b_11.Load(i_29), b_11.Load(i_29 + int(1)), b_11.Load(i_29 + int(2)));
}

static int32_t sheetLevelStart_0(int32_t k_12)
{
    return ((int(1) << (int(2) * k_12)) - int(1)) / int(3);
}

static float lightEdge_0(float lo_12, float hi_11, float x_41)
{
    if(!(hi_11 > lo_12))
    {
        float _S643;
        if(x_41 >= lo_12)
        {
            _S643 = 1.0f;
        }
        else
        {
            _S643 = 0.0f;
        }
        return _S643;
    }
    float t_17 = clamp_0((x_41 - lo_12) / (hi_11 - lo_12), 0.0f, 1.0f);
    return t_17 * t_17 * (3.0f - 2.0f * t_17);
}

static LightSample_0 sampleLocalLight_0(StructuredBuffer<float> b_12, int32_t count_3, Vector<float, 3>  p_33, Rng_0 * rng_10)
{
    int32_t k_13;
    float imp_0;
    float imp1_0;
    LightSample_0 ls_0;
    Vector<float, 3>  _S644 = Vector<float, 3> (0.0f, 1.0f, 0.0f);
    (&ls_0)->lsDir_0 = _S644;
    (&ls_0)->lsDist_0 = 0.0f;
    (&ls_0)->lsIrradiance_0 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    int32_t _S645 = (I32_min((count_3), (int(16))));
    if(_S645 <= int(0))
    {
        return ls_0;
    }
    float _S646 = randFloat_0(rng_10);
    int32_t _S647 = _S645 - int(1);
    int32_t i_30 = int(0);
    for(;;)
    {
        if(i_30 < int(16))
        {
        }
        else
        {
            k_13 = _S647;
            break;
        }
        if(i_30 >= _S645)
        {
            k_13 = _S647;
            break;
        }
        if(_S646 < b_12.Load(int(8) + i_30 * int(20) + int(1)))
        {
            k_13 = i_30;
            break;
        }
        i_30 = i_30 + int(1);
    }
    int32_t r_13 = int(8) + k_13 * int(20);
    int32_t kind_0 = int32_t(b_12.Load(r_13));
    float pick_0 = b_12.Load(r_13 + int(2));
    if(!(pick_0 > 0.0f))
    {
        return ls_0;
    }
    int32_t _S648 = r_13 + int(9);
    Vector<float, 3>  rgb_0 = lightTriple_0(b_12, _S648);
    if(kind_0 == int(2))
    {
        (&ls_0)->lsDir_0 = lightTriple_0(b_12, r_13 + int(6));
        (&ls_0)->lsDist_0 = 1.00000001504746622e+30f;
        (&ls_0)->lsIrradiance_0 = rgb_0 / (Vector<float, 3> )pick_0;
        return ls_0;
    }
    float floorSq_0 = b_12.Load(r_13 + int(12));
    bool _S649;
    float floorSq_1;
    Vector<float, 3>  q_14;
    Vector<float, 3>  rgb_1;
    if(kind_0 == int(3))
    {
        int32_t w_8 = int32_t(b_12.Load(r_13 + int(13)));
        int32_t h_10 = int32_t(b_12.Load(r_13 + int(14)));
        int32_t texels_0 = int32_t(b_12.Load(r_13 + int(15)));
        int32_t tree_0 = int32_t(b_12.Load(r_13 + int(19)));
        int32_t levels_0 = int32_t(b_12.Load(tree_0));
        Vector<float, 3>  origin_3 = lightTriple_0(b_12, r_13 + int(3));
        Vector<float, 3>  axisU_0 = lightTriple_0(b_12, r_13 + int(6));
        Vector<float, 3>  eye_0 = lightTriple_0(b_12, _S648);
        Vector<float, 3>  axisV_0 = lightTriple_0(b_12, r_13 + int(16));
        if(w_8 <= int(0))
        {
            _S649 = true;
        }
        else
        {
            _S649 = h_10 <= int(0);
        }
        if(_S649)
        {
            _S649 = true;
        }
        else
        {
            _S649 = levels_0 < int(0);
        }
        if(_S649)
        {
            _S649 = true;
        }
        else
        {
            _S649 = levels_0 > int(12);
        }
        if(_S649)
        {
            return ls_0;
        }
        int32_t cx_0 = int(0);
        int32_t cy_0 = int(0);
        int32_t lv_0 = int(0);
        floorSq_1 = 1.0f;
        for(;;)
        {
            if(lv_0 < int(12))
            {
            }
            else
            {
                break;
            }
            if(lv_0 >= levels_0)
            {
                break;
            }
            int32_t child_0 = lv_0 + int(1);
            int32_t _S650 = int(1) << child_0;
            int32_t _S651 = tree_0 + int(1) + int(5) * sheetLevelStart_0(child_0);
            float imp0_0 = 0.0f;
            float imp1_1 = 0.0f;
            float imp2_0 = 0.0f;
            float imp3_0 = 0.0f;
            int32_t c_58 = int(0);
            for(;;)
            {
                if(c_58 < int(4))
                {
                }
                else
                {
                    break;
                }
                int32_t at_3 = _S651 + int(5) * ((int(2) * cy_0 + (c_58 >> int(1))) * _S650 + (int(2) * cx_0 + (c_58 & int(1))));
                float power_0 = b_12.Load(at_3);
                if(power_0 > 0.0f)
                {
                    Vector<float, 3>  d_26 = lightTriple_0(b_12, at_3 + int(1)) - p_33;
                    imp_0 = power_0 / (F32_max((dot_0(d_26, d_26)), (b_12.Load(at_3 + int(4)))));
                }
                else
                {
                    imp_0 = 0.0f;
                }
                if(c_58 == int(0))
                {
                    imp0_0 = imp_0;
                }
                else
                {
                    float imp2_1;
                    float imp3_1;
                    if(c_58 == int(1))
                    {
                        imp1_0 = imp_0;
                        imp2_1 = imp2_0;
                        imp3_1 = imp3_0;
                    }
                    else
                    {
                        if(c_58 == int(2))
                        {
                            imp1_0 = imp_0;
                            imp2_1 = imp3_0;
                        }
                        else
                        {
                            imp1_0 = imp2_0;
                            imp2_1 = imp_0;
                        }
                        float _S652 = imp1_0;
                        float _S653 = imp2_1;
                        imp1_0 = imp1_1;
                        imp2_1 = _S652;
                        imp3_1 = _S653;
                    }
                    imp1_1 = imp1_0;
                    imp2_0 = imp2_1;
                    imp3_0 = imp3_1;
                }
                c_58 = c_58 + int(1);
            }
            float _S654 = imp0_0 + imp1_1;
            float _S655 = _S654 + imp2_0;
            float total_3 = _S655 + imp3_0;
            if(!(total_3 > 0.0f))
            {
                return ls_0;
            }
            float _S656 = randFloat_0(rng_10);
            float u_6 = _S656 * total_3;
            int32_t pickC_0;
            if(u_6 < imp0_0)
            {
                imp_0 = imp0_0;
                pickC_0 = int(0);
            }
            else
            {
                if(u_6 < _S654)
                {
                    imp_0 = imp1_1;
                    pickC_0 = int(1);
                }
                else
                {
                    if(u_6 < _S655)
                    {
                        imp_0 = imp2_0;
                        pickC_0 = int(2);
                    }
                    else
                    {
                        imp_0 = imp3_0;
                        pickC_0 = int(3);
                    }
                }
            }
            int32_t pickC_1;
            if(!(imp_0 > 0.0f))
            {
                if(imp3_0 > 0.0f)
                {
                    imp1_0 = imp3_0;
                    pickC_1 = int(3);
                }
                else
                {
                    if(imp2_0 > 0.0f)
                    {
                        imp1_0 = imp2_0;
                        pickC_1 = int(2);
                    }
                    else
                    {
                        if(imp1_1 > 0.0f)
                        {
                            imp1_0 = imp1_1;
                            pickC_1 = int(1);
                        }
                        else
                        {
                            imp1_0 = imp0_0;
                            pickC_1 = int(0);
                        }
                    }
                }
            }
            else
            {
                imp1_0 = imp_0;
                pickC_1 = pickC_0;
            }
            float pdf_0 = floorSq_1 * (imp1_0 / total_3);
            int32_t _S657 = int(2) * cx_0 + (pickC_1 & int(1));
            int32_t _S658 = int(2) * cy_0 + (pickC_1 >> int(1));
            cx_0 = _S657;
            cy_0 = _S658;
            lv_0 = child_0;
            floorSq_1 = pdf_0;
        }
        if(cx_0 >= w_8)
        {
            _S649 = true;
        }
        else
        {
            _S649 = cy_0 >= h_10;
        }
        if(_S649)
        {
            _S649 = true;
        }
        else
        {
            _S649 = !(floorSq_1 > 0.0f);
        }
        if(_S649)
        {
            return ls_0;
        }
        int32_t tx_0 = texels_0 + int(4) * (cy_0 * w_8 + cx_0);
        float s_20 = b_12.Load(tx_0 + int(3));
        float u2_1 = randFloat_0(rng_10);
        float u3_0 = randFloat_0(rng_10);
        float floorSq_2 = floorSq_0 * (s_20 * s_20);
        Vector<float, 3>  _S659 = lightTriple_0(b_12, tx_0) * (Vector<float, 3> )(floorSq_2 / floorSq_1);
        q_14 = eye_0 + (origin_3 + axisU_0 * (Vector<float, 3> )(float(cx_0) + u2_1) + axisV_0 * (Vector<float, 3> )(float(cy_0) + u3_0) - eye_0) * (Vector<float, 3> )s_20;
        rgb_1 = _S659;
        floorSq_1 = floorSq_2;
    }
    else
    {
        q_14 = lightTriple_0(b_12, r_13 + int(3));
        rgb_1 = rgb_0;
        floorSq_1 = floorSq_0;
    }
    Vector<float, 3>  d_27 = q_14 - p_33;
    float dSq_0 = dot_0(d_27, d_27);
    float dist_5 = (F32_sqrt((dSq_0)));
    if(dist_5 > 0.0f)
    {
        q_14 = d_27 / (Vector<float, 3> )dist_5;
    }
    else
    {
        q_14 = _S644;
    }
    (&ls_0)->lsDir_0 = q_14;
    (&ls_0)->lsDist_0 = dist_5;
    Vector<float, 3>  e_1 = rgb_1 / (Vector<float, 3> )(F32_max((dSq_0), (floorSq_1)));
    Vector<float, 3>  e_2;
    if(kind_0 == int(1))
    {
        e_2 = e_1 * (Vector<float, 3> )lightEdge_0(b_12.Load(r_13 + int(13)), b_12.Load(r_13 + int(14)), dot_0(- (&ls_0)->lsDir_0, lightTriple_0(b_12, r_13 + int(6))));
    }
    else
    {
        e_2 = e_1;
    }
    if(kind_0 != int(3))
    {
        _S649 = b_12.Load(r_13 + int(16)) > 0.0f;
    }
    else
    {
        _S649 = false;
    }
    if(_S649)
    {
        e_2 = e_2 * (Vector<float, 3> )(1.0f - lightEdge_0(b_12.Load(r_13 + int(15)), b_12.Load(r_13 + int(16)), dist_5));
    }
    (&ls_0)->lsIrradiance_0 = e_2 / (Vector<float, 3> )pick_0;
    return ls_0;
}

static float sceneTransmittanceUpTo_0(Scene_0 * s_21, StructuredBuffer<float> bounds_13, StructuredBuffer<Vector<float, 2> > drift_8, Rng_0 * rng_11, Vector<float, 3>  p_34, Vector<float, 3>  dir_7, float tMax_6, int32_t * steps_10)
{
    float _S660 = transmittanceUpTo_0(&s_21->medium_0, &s_21->grid_0, bounds_13, drift_8, rng_11, p_34, dir_7, tMax_6, steps_10);
    bool _S661;
    if((s_21->layer2On_0) != int(0))
    {
        _S661 = _S660 > 0.0f;
    }
    else
    {
        _S661 = false;
    }
    float tr_10;
    if(_S661)
    {
        MajorantGrid_0 _S662 = gridFor_0(&s_21->medium2_0, &s_21->grid2_0, p_34);
        MajorantGrid_0 _S663 = _S662;
        float _S664 = transmittanceUpTo_0(&s_21->medium2_0, &_S663, bounds_13, drift_8, rng_11, p_34, dir_7, tMax_6, steps_10);
        tr_10 = _S660 * _S664;
    }
    else
    {
        tr_10 = _S660;
    }
    return tr_10;
}

static Vector<float, 3>  sampleHG_0(Rng_0 * rng_12, Vector<float, 3>  wo_0, float g_24, float * cosT_6)
{
    float _S665 = clamp_0(g_24, -0.99900001287460327f, 0.99900001287460327f);
    float u1_1 = randFloat_0(rng_12);
    float u2_2 = randFloat_0(rng_12);
    if((F32_abs((_S665))) < 0.00100000004749745f)
    {
        *cosT_6 = 1.0f - 2.0f * u1_1;
    }
    else
    {
        float _S666 = _S665 * _S665;
        float _S667 = 2.0f * _S665;
        float s_22 = (1.0f - _S666) / (1.0f - _S665 + _S667 * u1_1);
        *cosT_6 = (1.0f + _S666 - s_22 * s_22) / _S667;
    }
    float _S668 = clamp_0(*cosT_6, -1.0f, 1.0f);
    *cosT_6 = _S668;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S668 * _S668))))));
    float phi_0 = 6.28318548202514648f * u2_2;
    Vector<float, 3>  w_9 = normalize_0(wo_0);
    Vector<float, 3>  a_6;
    if((F32_abs((w_9.y))) < 0.94999998807907104f)
    {
        a_6 = Vector<float, 3> (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_6 = Vector<float, 3> (1.0f, 0.0f, 0.0f);
    }
    Vector<float, 3>  u_7 = normalize_0(cross_0(a_6, w_9));
    return normalize_0((Vector<float, 3> )(sinT_0 * (F32_cos((phi_0)))) * u_7 + (Vector<float, 3> )(sinT_0 * (F32_sin((phi_0)))) * cross_0(w_9, u_7) + (Vector<float, 3> )*cosT_6 * w_9);
}

static Vector<float, 3>  sampleDraine_0(Rng_0 * rng_13, Vector<float, 3>  wo_1, float g_25, float a_7, float * cosT_7)
{
    Vector<float, 3>  dir_8 = sampleHG_0(rng_13, wo_1, g_25, cosT_7);
    if(!(a_7 > 0.0f))
    {
        return dir_8;
    }
    Vector<float, 3>  dir_9 = dir_8;
    int32_t i_31 = int(0);
    for(;;)
    {
        if(i_31 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S669 = randFloat_0(rng_13);
        if((_S669 * (1.0f + a_7)) <= (1.0f + a_7 * *cosT_7 * *cosT_7))
        {
            break;
        }
        Vector<float, 3>  _S670 = sampleHG_0(rng_13, wo_1, g_25, cosT_7);
        int32_t i_32 = i_31 + int(1);
        dir_9 = _S670;
        i_31 = i_32;
    }
    return dir_9;
}

static Vector<float, 3>  samplePhaseDir_0(PhaseInput_0 * p_35, Rng_0 * rng_14, Vector<float, 3>  wo_2, float * weight_0)
{
    float cosT_8;
    Vector<float, 3>  dir_10;
    float _S671;
    if((p_35->useIce_0) != int(0))
    {
        float _S672 = randFloat_0(rng_14);
        if(_S672 < 0.72000002861022949f)
        {
            Vector<float, 3>  _S673 = sampleHG_0(rng_14, wo_2, 0.85000002384185791f, &cosT_8);
            dir_10 = _S673;
        }
        else
        {
            Vector<float, 3>  _S674 = sampleHG_0(rng_14, wo_2, 0.0f, &cosT_8);
            dir_10 = _S674;
        }
        float pdf_1 = 0.72000002861022949f * hg_0(cosT_8, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_1 > 9.99999971718068537e-10f)
        {
            _S671 = phaseIce_0(cosT_8) / pdf_1;
        }
        else
        {
            _S671 = 0.0f;
        }
        *weight_0 = _S671;
    }
    else
    {
        float _S675 = randFloat_0(rng_14);
        if(_S675 < (p_35->draineW_0))
        {
            Vector<float, 3>  _S676 = sampleDraine_0(rng_14, wo_2, p_35->draineG_0, p_35->draineAlpha_0, &cosT_8);
            dir_10 = _S676;
        }
        else
        {
            Vector<float, 3>  _S677 = sampleHG_0(rng_14, wo_2, p_35->hgG_0, &cosT_8);
            dir_10 = _S677;
        }
        float _S678 = phaseLiquid_0(p_35, cosT_8);
        if(_S678 > 9.99999971718068537e-10f)
        {
            _S671 = 1.0f;
        }
        else
        {
            _S671 = 0.0f;
        }
        *weight_0 = _S671;
    }
    return dir_10;
}

static bool pathScatter_0(Scene_0 * s_23, PhaseInput_0 * ph_1, StructuredBuffer<float> bounds_14, StructuredBuffer<Vector<float, 2> > drift_9, PathState_0 * st_1, Vector<float, 3>  p_36, int32_t layer_1, bool nee_0)
{
    Vector<float, 3>  _S679 = s_23->albedo_0;
    PhaseInput_0 matterPhase_0;
    Vector<float, 3>  matterAlbedo_1;
    if(layer_1 != int(0))
    {
        matterPhase_0 = s_23->phase2_0;
        matterAlbedo_1 = s_23->albedo2_0;
    }
    else
    {
        matterPhase_0 = *ph_1;
        matterAlbedo_1 = _S679;
    }
    if(nee_0)
    {
        Vector<float, 3>  _S680 = s_23->sunDir_0;
        float _S681 = sceneTransmittance_0(s_23, bounds_14, drift_9, &st_1->psRng_0, p_36 + s_23->sunDir_0 * (Vector<float, 3> )s_23->shadowOffset_0, s_23->sunDir_0, &st_1->psSteps_0);
        if(_S681 > 0.0f)
        {
            float _S682 = dot_0(st_1->psDir_0, _S680);
            PhaseInput_0 _S683 = matterPhase_0;
            float _S684 = phaseAt_0(&_S683, _S682);
            Vector<float, 3>  _S685 = st_1->psThroughput_0 * matterAlbedo_1 * (Vector<float, 3> )_S684 * (Vector<float, 3> )_S681;
            Vector<float, 3>  _S686 = sunIrradianceAt_0(s_23, p_36);
            st_1->psRadiance_0 = st_1->psRadiance_0 + _S685 * _S686;
        }
    }
    int32_t _S687 = s_23->ltCount_0;
    if((s_23->ltCount_0) > int(0))
    {
        Rng_0 _S688 = st_1->psRng_0;
        Rng_0 _S689 = splitRng_0(&_S688, 281U);
        Rng_0 lr_0 = _S689;
        LightSample_0 ls_1 = sampleLocalLight_0(s_23->ltBuffer_0, _S687, p_36, &lr_0);
        if(any_0((ls_1.lsIrradiance_0) > Vector<float, 3> (0.0f, 0.0f, 0.0f)))
        {
            float _S690 = sceneTransmittanceUpTo_0(s_23, bounds_14, drift_9, &lr_0, p_36, ls_1.lsDir_0, ls_1.lsDist_0, &st_1->psSteps_0);
            if(_S690 > 0.0f)
            {
                float _S691 = dot_0(st_1->psDir_0, ls_1.lsDir_0);
                PhaseInput_0 _S692 = matterPhase_0;
                float _S693 = phaseAt_0(&_S692, _S691);
                st_1->psRadiance_0 = st_1->psRadiance_0 + st_1->psThroughput_0 * matterAlbedo_1 * (Vector<float, 3> )_S693 * (Vector<float, 3> )_S690 * ls_1.lsIrradiance_0;
            }
        }
    }
    PhaseInput_0 _S694 = matterPhase_0;
    float w_10;
    Vector<float, 3>  _S695 = samplePhaseDir_0(&_S694, &st_1->psRng_0, st_1->psDir_0, &w_10);
    st_1->psThroughput_0 = st_1->psThroughput_0 * (matterAlbedo_1 * (Vector<float, 3> )w_10);
    st_1->psOrigin_0 = p_36;
    st_1->psDir_0 = _S695;
    if((st_1->psBounce_0) >= (s_23->rrStartBounce_0))
    {
        float p2_0 = clamp_0((F32_max((st_1->psThroughput_0.x), ((F32_max((st_1->psThroughput_0.y), (st_1->psThroughput_0.z)))))), 0.05000000074505806f, 1.0f);
        float _S696 = randFloat_0(&st_1->psRng_0);
        if(_S696 > p2_0)
        {
            return false;
        }
        st_1->psThroughput_0 = st_1->psThroughput_0 / (Vector<float, 3> )p2_0;
    }
    return true;
}

static PathState_0 pathBegin_0(Scene_0 * s_24, PhaseInput_0 * ph_2, StructuredBuffer<float> bounds_15, StructuredBuffer<Vector<float, 2> > drift_10, Rng_0 * rng_15, Vector<float, 3>  ro_10, Vector<float, 3>  rd_10, float tGeo_0)
{
    PathState_0 st_2;
    Vector<float, 3>  _S697 = Vector<float, 3> (0.0f, 0.0f, 0.0f);
    (&st_2)->psRadiance_0 = _S697;
    (&st_2)->psThroughput_0 = Vector<float, 3> (1.0f, 1.0f, 1.0f);
    (&st_2)->psOrigin_0 = ro_10;
    (&st_2)->psDir_0 = rd_10;
    (&st_2)->psRng_0 = *rng_15;
    (&st_2)->psBounce_0 = int(0);
    (&st_2)->psAlive_0 = int(0);
    (&st_2)->psEvents_0 = int(0);
    (&st_2)->psCapped_0 = int(0);
    (&st_2)->psSteps_0 = int(0);
    (&st_2)->psSee_0 = 0.0f;
    int32_t _S698 = (I32_min((s_24->maxBounces_0), (int(256))));
    bool geo_0 = tGeo_0 < 1.00000001504746622e+30f;
    float camT_1 = 1.0f;
    bool sunAlongCamera_0;
    if((s_24->neeTentativeScale_0) > 0.0f)
    {
        sunAlongCamera_0 = _S698 > int(0);
    }
    else
    {
        sunAlongCamera_0 = false;
    }
    int32_t cameraHit_0 = int(0);
    Vector<float, 3>  cameraHitAt_0 = _S697;
    int32_t cameraHitLayer_0 = int(0);
    float cameraResume_0 = 0.0f;
    if(sunAlongCamera_0)
    {
        Rng_0 _S699 = splitRng_0(rng_15, 1510U);
        Rng_0 segmentRng_0 = _S699;
        Rng_0 _S700 = splitRng_0(rng_15, 1511U);
        Rng_0 _S701 = _S700;
        Vector<float, 3>  _S702 = cameraSegmentSun_0(s_24, ph_2, bounds_15, drift_10, &segmentRng_0, &_S701, ro_10, rd_10, &(&st_2)->psSteps_0, &cameraHit_0, &cameraHitAt_0, &cameraHitLayer_0, &cameraResume_0, tGeo_0, &camT_1);
        (&st_2)->psRadiance_0 = (&st_2)->psRadiance_0 + (&st_2)->psThroughput_0 * _S702;
    }
    bool airOn_0;
    if(((&s_24->environment_0)->envMode_0) == int(1))
    {
        airOn_0 = (s_24->aerialMode_0) != int(0);
    }
    else
    {
        airOn_0 = false;
    }
    Rng_0 _S703 = splitRng_0(rng_15, 2590U);
    Rng_0 airRng_0 = _S703;
    if(_S698 <= int(0))
    {
        (&st_2)->psCapped_0 = int(1);
        return st_2;
    }
    Vector<float, 3>  p_37;
    int32_t layer_2;
    bool collided_0;
    if(sunAlongCamera_0)
    {
        collided_0 = cameraHit_0 != int(2);
    }
    else
    {
        collided_0 = false;
    }
    if(collided_0)
    {
        bool _S704 = cameraHit_0 == int(1);
        p_37 = cameraHitAt_0;
        layer_2 = cameraHitLayer_0;
        collided_0 = _S704;
    }
    else
    {
        if(sunAlongCamera_0)
        {
            bool _S705 = sceneFreeFlight_0(s_24, bounds_15, drift_10, &(&st_2)->psRng_0, ro_10 + rd_10 * (Vector<float, 3> )cameraResume_0, rd_10, &p_37, &layer_2, &(&st_2)->psSteps_0);
            collided_0 = _S705;
        }
        else
        {
            bool _S706 = sceneFreeFlight_0(s_24, bounds_15, drift_10, &(&st_2)->psRng_0, ro_10, rd_10, &p_37, &layer_2, &(&st_2)->psSteps_0);
            collided_0 = _S706;
        }
    }
    bool _S707;
    if(geo_0)
    {
        _S707 = collided_0;
    }
    else
    {
        _S707 = false;
    }
    if(_S707)
    {
        _S707 = (dot_0(p_37 - ro_10, rd_10)) > tGeo_0;
    }
    else
    {
        _S707 = false;
    }
    if(_S707)
    {
        collided_0 = false;
    }
    if(geo_0)
    {
        float _S708;
        if(sunAlongCamera_0)
        {
            _S708 = camT_1;
        }
        else
        {
            if(collided_0)
            {
                _S708 = 0.0f;
            }
            else
            {
                _S708 = 1.0f;
            }
        }
        (&st_2)->psSee_0 = _S708;
    }
    bool _S709 = !collided_0;
    if(_S709)
    {
        collided_0 = geo_0;
    }
    else
    {
        collided_0 = false;
    }
    Vector<float, 3>  airIn_1;
    if(collided_0)
    {
        if((s_24->clearSky_0) != int(0))
        {
            sunAlongCamera_0 = ((&st_2)->psSee_0) >= 1.0f;
        }
        else
        {
            sunAlongCamera_0 = false;
        }
        if(sunAlongCamera_0)
        {
            return st_2;
        }
        if(airOn_0)
        {
            float u1_2 = randFloat_0(&airRng_0);
            float u2_3 = randFloat_0(&airRng_0);
            AirSegment_0 _S710 = airSegment_0(&(&s_24->environment_0)->sky_0, ro_10.y, rd_10, tGeo_0, u1_2, u2_3);
            if((s_24->aerialMode_0) >= int(2))
            {
                sunAlongCamera_0 = (s_24->airMapOn_0) != int(0);
            }
            else
            {
                sunAlongCamera_0 = false;
            }
            if(sunAlongCamera_0)
            {
                Vector<float, 3>  _S711 = airShadowLoss_0(&(&s_24->environment_0)->sky_0, &s_24->airMapIce_0, &s_24->airMapCu_0, ro_10, rd_10, tGeo_0, u2_3);
                airIn_1 = max_0(_S710.airIn_0 - _S711, _S697);
            }
            else
            {
                AirSegment_0 _S712 = _S710;
                float _S713 = airShadow_0(s_24, bounds_15, drift_10, &airRng_0, &_S712, ro_10, rd_10, &(&st_2)->psSteps_0);
                airIn_1 = _S710.airIn_0 * (Vector<float, 3> )_S713;
            }
            (&st_2)->psRadiance_0 = (&st_2)->psRadiance_0 + (&st_2)->psThroughput_0 * (airIn_1 - (Vector<float, 3> )(&st_2)->psSee_0 * _S710.airIn_0);
        }
        return st_2;
    }
    if(_S709)
    {
        Vector<float, 3>  _S714 = pathEnvironment_0(s_24, ro_10, rd_10, true);
        if(airOn_0)
        {
            sunAlongCamera_0 = (s_24->aerialMode_0) >= int(2);
        }
        else
        {
            sunAlongCamera_0 = false;
        }
        if(sunAlongCamera_0)
        {
            float u1_3 = randFloat_0(&airRng_0);
            float u2_4 = randFloat_0(&airRng_0);
            if((s_24->airMapOn_0) != int(0))
            {
                Vector<float, 3>  _S715 = airShadowLoss_0(&(&s_24->environment_0)->sky_0, &s_24->airMapIce_0, &s_24->airMapCu_0, ro_10, rd_10, 1.00000001504746622e+30f, u2_4);
                airIn_1 = max_0(_S714 - _S715, _S697);
            }
            else
            {
                AirSegment_0 _S716 = airSegment_0(&(&s_24->environment_0)->sky_0, ro_10.y, rd_10, 1.00000001504746622e+30f, u1_3, u2_4);
                AirSegment_0 _S717 = _S716;
                float _S718 = airShadow_0(s_24, bounds_15, drift_10, &airRng_0, &_S717, ro_10, rd_10, &(&st_2)->psSteps_0);
                airIn_1 = _S714 - _S716.airIn_0 * (Vector<float, 3> )(1.0f - _S718);
            }
        }
        else
        {
            airIn_1 = _S714;
        }
        (&st_2)->psRadiance_0 = (&st_2)->psRadiance_0 + (&st_2)->psThroughput_0 * airIn_1;
        return st_2;
    }
    (&st_2)->psEvents_0 = (&st_2)->psEvents_0 + int(1);
    if(airOn_0)
    {
        float u1_4 = randFloat_0(&airRng_0);
        float u2_5 = randFloat_0(&airRng_0);
        float dist_6 = length_0(p_37 - ro_10);
        float _S719 = ro_10.y;
        AirSegment_0 _S720 = airSegment_0(&(&s_24->environment_0)->sky_0, _S719, rd_10, dist_6, u1_4, u2_5);
        if((s_24->aerialMode_0) >= int(2))
        {
            airOn_0 = (s_24->airMapOn_0) != int(0);
        }
        else
        {
            airOn_0 = false;
        }
        if(airOn_0)
        {
            Vector<float, 3>  _S721 = airShadowLoss_0(&(&s_24->environment_0)->sky_0, &s_24->airMapIce_0, &s_24->airMapCu_0, ro_10, rd_10, dist_6, u2_5);
            airIn_1 = max_0(_S720.airIn_0 - _S721, _S697);
        }
        else
        {
            AirSegment_0 _S722 = _S720;
            float _S723 = airShadow_0(s_24, bounds_15, drift_10, &airRng_0, &_S722, ro_10, rd_10, &(&st_2)->psSteps_0);
            airIn_1 = _S720.airIn_0 * (Vector<float, 3> )_S723;
        }
        (&st_2)->psRadiance_0 = (&st_2)->psRadiance_0 + (&st_2)->psThroughput_0 * airIn_1;
        if(geo_0)
        {
            AirSegment_0 _S724 = airSegment_0(&(&s_24->environment_0)->sky_0, _S719, rd_10, tGeo_0, u1_4, u2_5);
            (&st_2)->psRadiance_0 = (&st_2)->psRadiance_0 - (&st_2)->psThroughput_0 * ((Vector<float, 3> )(&st_2)->psSee_0 * _S724.airIn_0);
        }
        (&st_2)->psThroughput_0 = (&st_2)->psThroughput_0 * _S720.airT_0;
    }
    bool _S725 = pathScatter_0(s_24, ph_2, bounds_15, drift_10, &st_2, p_37, layer_2, !sunAlongCamera_0);
    if(_S725)
    {
        (&st_2)->psBounce_0 = int(1);
        (&st_2)->psAlive_0 = int(1);
    }
    return st_2;
}

static void pathBounce_0(Scene_0 * s_25, PhaseInput_0 * ph_3, StructuredBuffer<float> bounds_16, StructuredBuffer<Vector<float, 2> > drift_11, PathState_0 * st_3)
{
    if((st_3->psAlive_0) == int(0))
    {
        return;
    }
    if((st_3->psBounce_0) >= (I32_min((s_25->maxBounces_0), (int(256)))))
    {
        st_3->psCapped_0 = int(1);
        st_3->psAlive_0 = int(0);
        return;
    }
    Vector<float, 3>  p_38;
    int32_t layer_3;
    bool _S726 = sceneFreeFlight_0(s_25, bounds_16, drift_11, &st_3->psRng_0, st_3->psOrigin_0, st_3->psDir_0, &p_38, &layer_3, &st_3->psSteps_0);
    if(!_S726)
    {
        Vector<float, 3>  _S727 = st_3->psThroughput_0;
        Vector<float, 3>  _S728 = pathEnvironment_0(s_25, st_3->psOrigin_0, st_3->psDir_0, false);
        st_3->psRadiance_0 = st_3->psRadiance_0 + _S727 * _S728;
        st_3->psAlive_0 = int(0);
        return;
    }
    st_3->psEvents_0 = st_3->psEvents_0 + int(1);
    bool _S729 = pathScatter_0(s_25, ph_3, bounds_16, drift_11, st_3, p_38, layer_3, true);
    if(_S729)
    {
        st_3->psBounce_0 = st_3->psBounce_0 + int(1);
    }
    else
    {
        st_3->psAlive_0 = int(0);
    }
    return;
}

static TraceResult_0 traceTo_0(Scene_0 * s_26, PhaseInput_0 * ph_4, StructuredBuffer<float> bounds_17, StructuredBuffer<Vector<float, 2> > drift_12, Rng_0 * rng_16, Vector<float, 3>  ro_11, Vector<float, 3>  rd_11, float tGeo_1)
{
    Rng_0 _S730 = *rng_16;
    PathState_0 _S731 = pathBegin_0(s_26, ph_4, bounds_17, drift_12, &_S730, ro_11, rd_11, tGeo_1);
    PathState_0 st_4 = _S731;
    int32_t i_33 = int(1);
    for(;;)
    {
        bool _S732;
        if(i_33 < int(256))
        {
            _S732 = ((&st_4)->psAlive_0) != int(0);
        }
        else
        {
            _S732 = false;
        }
        if(_S732)
        {
        }
        else
        {
            break;
        }
        pathBounce_0(s_26, ph_4, bounds_17, drift_12, &st_4);
        i_33 = i_33 + int(1);
    }
    if(((&st_4)->psAlive_0) != int(0))
    {
        (&st_4)->psCapped_0 = int(1);
    }
    *rng_16 = (&st_4)->psRng_0;
    TraceResult_0 r_14;
    (&r_14)->pathRadiance_0 = (&st_4)->psRadiance_0;
    (&r_14)->scatterEvents_0 = (&st_4)->psEvents_0;
    (&r_14)->capped_0 = (&st_4)->psCapped_0;
    (&r_14)->trackingSteps_0 = (&st_4)->psSteps_0;
    (&r_14)->sceneSee_0 = (&st_4)->psSee_0;
    return r_14;
}

static Vector<float, 4>  renderSample_0(Scene_0 * s_27, PhaseInput_0 * ph_5, StructuredBuffer<float> bounds_18, StructuredBuffer<Vector<float, 2> > drift_13, Vector<float, 3>  ro_12, Vector<float, 3>  rd_12, uint32_t seed_2, float tGeo_2)
{
    Rng_0 rng_17 = makeRng_0(seed_2);
    TraceResult_0 _S733 = traceTo_0(s_27, ph_5, bounds_18, drift_13, &rng_17, ro_12, rd_12, tGeo_2);
    return Vector<float, 4> (_S733.pathRadiance_0.x, _S733.pathRadiance_0.y, _S733.pathRadiance_0.z, _S733.sceneSee_0);
}

void _cpuRenderRays(void* _S734, void* entryPointParams_0, void* _S735)
{
    ComputeThreadVaryingInput * _S736 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S734));
    int32_t i_34 = int32_t((_S736->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S736->groupThreadID).x);
    if(i_34 >= ((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->count_0))
    {
        return;
    }
    Vector<float, 3>  * _S737 = (&((slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->outRadiance_0)[i_34]);
    Vector<float, 4>  _S738 = renderSample_0(&(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->scene_0, &(slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->phase_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->bounds_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->drift_0, (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->origins_0.Load(i_34), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->directions_0.Load(i_34), (slang_bit_cast<EntryPointParams_0*>(entryPointParams_0))->seed_0 + uint32_t(i_34), 1.00000001504746622e+30f);
    *_S737 = Vector<float, 3> {_S738.x, _S738.y, _S738.z};
    return;
}

static void layerMapColumn_0(Medium_0 * med_0, StructuredBuffer<Vector<float, 2> > drift_14, LayerShadowMap_0 * m_18, int32_t texel_0, RWStructuredBuffer<float> outTexels_1)
{
    int32_t _S739 = m_18->smDimU_0;
    int32_t stride_0 = m_18->smDimU_0 * m_18->smDimV_0;
    bool _S740;
    if(texel_0 < int(0))
    {
        _S740 = true;
    }
    else
    {
        _S740 = texel_0 >= stride_0;
    }
    if(_S740)
    {
        return;
    }
    int32_t iu_1 = texel_0 % _S739;
    int32_t iv_1 = texel_0 / _S739;
    Vector<float, 2>  _S741 = m_18->smLo_0;
    Vector<float, 2>  _S742 = m_18->smTexel_0;
    Vector<float, 2>  _S743 = m_18->smCentre_0 + m_18->smAxisU_0 * (Vector<float, 2> )(m_18->smLo_0.x + (float(iu_1) + 0.5f) * m_18->smTexel_0.x);
    Vector<float, 2>  _S744 = airMapAxisV_0(m_18);
    Vector<float, 2>  q_15 = _S743 + _S744 * (Vector<float, 2> )(_S741.y + (float(iv_1) + 0.5f) * _S742.y);
    Vector<float, 3>  base_0 = Vector<float, 3> (q_15.x, m_18->smBottom_0, q_15.y);
    Vector<float, 3>  _S745 = m_18->smSun_0;
    int32_t _S746 = m_18->smSlices_0;
    int32_t _S747 = m_18->smSlices_0 - int(1);
    float _S748 = (m_18->smTop_0 - m_18->smBottom_0) / (float(_S747) * m_18->smSun_0.y);
    float _S749 = (F32_max((m_18->smStep_0), (1.0f)));
    float t0_6;
    float t1_6;
    bool _S750 = slabRange_0(med_0, base_0, m_18->smSun_0, &t0_6, &t1_6);
    *(&(outTexels_1)[_S747 * stride_0 + texel_0]) = 1.0f;
    int32_t k_14 = _S746 - int(2);
    float tau_0 = 0.0f;
    for(;;)
    {
        if(k_14 >= int(0))
        {
        }
        else
        {
            break;
        }
        if(_S750)
        {
            _S740 = tau_0 < 12.0f;
        }
        else
        {
            _S740 = false;
        }
        float tau_1;
        if(_S740)
        {
            float _S751 = (F32_max((float(k_14) * _S748), (t0_6)));
            float _S752 = (F32_min((float(k_14 + int(1)) * _S748), (t1_6)));
            if(_S752 > _S751)
            {
                float _S753 = _S752 - _S751;
                int32_t n_0 = clamp_1(int32_t((F32_ceil((_S753 / _S749)))), int(1), int(1024));
                float _S754 = _S753 / float(n_0);
                int32_t j_13 = int(0);
                tau_1 = tau_0;
                for(;;)
                {
                    if(j_13 < n_0)
                    {
                    }
                    else
                    {
                        break;
                    }
                    float _S755 = densityAt_0(med_0, drift_14, base_0 + _S745 * (Vector<float, 3> )(_S751 + (float(j_13) + 0.5f) * _S754));
                    float tau_2 = tau_1 + _S755 * _S754;
                    j_13 = j_13 + int(1);
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
        float * _S756 = (&(outTexels_1)[k_14 * stride_0 + texel_0]);
        float _S757;
        if(tau_1 < 12.0f)
        {
            _S757 = (F32_exp((- tau_1)));
        }
        else
        {
            _S757 = 0.0f;
        }
        *_S756 = _S757;
        k_14 = k_14 - int(1);
        tau_0 = tau_1;
    }
    return;
}

void _cpuBuildAirMap(void* _S758, void* entryPointParams_1, void* _S759)
{
    ComputeThreadVaryingInput * _S760 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S758));
    int32_t i_35 = int32_t((_S760->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S760->groupThreadID).x);
    if(i_35 >= ((slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->count_1))
    {
        return;
    }
    layerMapColumn_0(&(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->medium_1, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->drift_1, &(slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->map_0, i_35, (slang_bit_cast<EntryPointParams_1*>(entryPointParams_1))->outTexels_0);
    return;
}

static Vector<float, 2>  firstScatterMoments_0(Medium_0 * m_19, MajorantGrid_0 * g_26, StructuredBuffer<float> bounds_19, StructuredBuffer<Vector<float, 2> > disp_12, Vector<float, 3>  ro_13, Vector<float, 3>  rd_13, float tMax_7)
{
    float t0_7;
    float t1_7;
    bool _S761 = slabRange_0(m_19, ro_13, rd_13, &t0_7, &t1_7);
    if(!_S761)
    {
        return Vector<float, 2> (0.0f, 0.0f);
    }
    float _S762 = (F32_min((t1_7), (tMax_7)));
    t1_7 = _S762;
    float _S763 = (F32_max((t0_7), (0.0f)));
    if(!(_S762 > _S763))
    {
        return Vector<float, 2> (0.0f, 0.0f);
    }
    Dda_0 _S764 = ddaInit_0(g_26, ro_13, rd_13, _S763);
    Dda_0 dda_4 = _S764;
    float _S765 = m_19->majorant_0;
    float _S766 = gridBound_0(m_19, g_26, bounds_19, disp_12, (&dda_4)->cell_0, m_19->majorant_0);
    float localMaj_3 = _S766;
    int32_t i_36 = int(0);
    float t_18 = _S763;
    float tr_11 = 1.0f;
    float sumP_0 = 0.0f;
    float sumT_0 = 0.0f;
    for(;;)
    {
        if(i_36 < int(4096))
        {
        }
        else
        {
            break;
        }
        Dda_0 _S767 = dda_4;
        float _S768 = ddaExit_0(&_S767);
        float _S769 = (F32_min((_S768), (t1_7)));
        bool _S770;
        if(localMaj_3 > 0.0f)
        {
            _S770 = _S769 > t_18;
        }
        else
        {
            _S770 = false;
        }
        float tr_12;
        float sumP_1;
        float sumT_1;
        if(_S770)
        {
            float _S771 = (F32_min((0.25f / localMaj_3), (_S769 - t_18)));
            float tm_1 = t_18 + 0.5f * _S771;
            float _S772 = densityAt_0(m_19, disp_12, ro_13 + rd_13 * (Vector<float, 3> )tm_1);
            float a_8 = 1.0f - (F32_exp((- _S772 * _S771)));
            float _S773 = tr_11 * a_8;
            float sumP_2 = sumP_0 + _S773;
            float sumT_2 = sumT_0 + _S773 * tm_1;
            float tr_13 = tr_11 * (1.0f - a_8);
            if(tr_13 < 0.00499999988824129f)
            {
                sumT_0 = sumT_2;
                sumP_0 = sumP_2;
                break;
            }
            float t_19 = t_18 + _S771;
            if(t_19 < _S769)
            {
                t_18 = t_19;
                tr_11 = tr_13;
                sumP_0 = sumP_2;
                sumT_0 = sumT_2;
                i_36 = i_36 + int(1);
                continue;
            }
            tr_12 = tr_13;
            sumP_1 = sumP_2;
            sumT_1 = sumT_2;
        }
        else
        {
            tr_12 = tr_11;
            sumP_1 = sumP_0;
            sumT_1 = sumT_0;
        }
        if(_S769 >= t1_7)
        {
            sumT_0 = sumT_1;
            sumP_0 = sumP_1;
            break;
        }
        ddaAdvance_0(&dda_4);
        float _S774 = gridBound_0(m_19, g_26, bounds_19, disp_12, (&dda_4)->cell_0, _S765);
        localMaj_3 = _S774;
        t_18 = _S769;
        tr_11 = tr_12;
        sumP_0 = sumP_1;
        sumT_0 = sumT_1;
        i_36 = i_36 + int(1);
    }
    return Vector<float, 2> (sumT_0, sumP_0);
}

static Vector<float, 2>  sceneFirstScatter_0(Scene_0 * s_28, StructuredBuffer<float> bounds_20, StructuredBuffer<Vector<float, 2> > drift_15, Vector<float, 3>  ro_14, Vector<float, 3>  rd_14, float tMax_8)
{
    Vector<float, 2>  _S775 = firstScatterMoments_0(&s_28->medium_0, &s_28->grid_0, bounds_20, drift_15, ro_14, rd_14, tMax_8);
    Vector<float, 2>  a_9;
    if((s_28->layer2On_0) != int(0))
    {
        MajorantGrid_0 _S776 = gridFor_0(&s_28->medium2_0, &s_28->grid2_0, ro_14);
        MajorantGrid_0 _S777 = _S776;
        Vector<float, 2>  _S778 = firstScatterMoments_0(&s_28->medium2_0, &_S777, bounds_20, drift_15, ro_14, rd_14, tMax_8);
        float a0_2;
        float a1_2;
        bool _S779 = slabRange_0(&s_28->medium_0, ro_14, rd_14, &a0_2, &a1_2);
        float b0_2;
        float b1_1;
        bool _S780 = slabRange_0(&s_28->medium2_0, ro_14, rd_14, &b0_2, &b1_1);
        bool secondFirst_1;
        if(_S780)
        {
            if(!_S779)
            {
                secondFirst_1 = true;
            }
            else
            {
                secondFirst_1 = (F32_max((b0_2), (0.0f))) < (F32_max((a0_2), (0.0f)));
            }
        }
        else
        {
            secondFirst_1 = false;
        }
        if(secondFirst_1)
        {
            a_9 = _S778;
        }
        else
        {
            a_9 = _S775;
        }
        Vector<float, 2>  farther_0;
        if(secondFirst_1)
        {
            farther_0 = _S775;
        }
        else
        {
            farther_0 = _S778;
        }
        a_9 = a_9 + farther_0 * (Vector<float, 2> )(1.0f - a_9.y);
    }
    else
    {
        a_9 = _S775;
    }
    float _S781 = a_9.y;
    float _S782;
    if(_S781 > 0.0f)
    {
        _S782 = a_9.x / _S781;
    }
    else
    {
        _S782 = 0.0f;
    }
    return Vector<float, 2> (_S782, _S781);
}

void _cpuSurfaceProbe(void* _S783, void* entryPointParams_2, void* _S784)
{
    ComputeThreadVaryingInput * _S785 = (slang_bit_cast<ComputeThreadVaryingInput *>(_S783));
    int32_t i_37 = int32_t((_S785->groupID * Vector<uint32_t, 3> (64U, 1U, 1U) + _S785->groupThreadID).x);
    if(i_37 >= ((slang_bit_cast<EntryPointParams_2*>(entryPointParams_2))->count_2))
    {
        return;
    }
    Vector<float, 2>  * _S786 = (&((slang_bit_cast<EntryPointParams_2*>(entryPointParams_2))->outMoments_0)[i_37]);
    Vector<float, 2>  _S787 = sceneFirstScatter_0(&(slang_bit_cast<EntryPointParams_2*>(entryPointParams_2))->scene_1, (slang_bit_cast<EntryPointParams_2*>(entryPointParams_2))->bounds_1, (slang_bit_cast<EntryPointParams_2*>(entryPointParams_2))->drift_2, (slang_bit_cast<EntryPointParams_2*>(entryPointParams_2))->origins_1.Load(i_37), (slang_bit_cast<EntryPointParams_2*>(entryPointParams_2))->directions_1.Load(i_37), (slang_bit_cast<EntryPointParams_2*>(entryPointParams_2))->tMax_1);
    *_S786 = _S787;
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
SLANG_PRELUDE_EXPORT
void cpuSurfaceProbe_Thread(ComputeThreadVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    _cpuSurfaceProbe(varyingInput, entryPointParams, globalParams);
}
SLANG_PRELUDE_EXPORT
void cpuSurfaceProbe_Group(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
{
    ComputeThreadVaryingInput threadInput = {};
    threadInput.groupID = varyingInput->startGroupID;
    for (uint32_t x = 0; x < 64; ++x)
    {
        threadInput.groupThreadID.x = x;
        _cpuSurfaceProbe(&threadInput, entryPointParams, globalParams);
    }
}
SLANG_PRELUDE_EXPORT
void cpuSurfaceProbe(ComputeVaryingInput* varyingInput, void* entryPointParams, void* globalParams)
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
                cpuSurfaceProbe_Group(&groupVaryingInput, entryPointParams, globalParams);
            }
        }
    }
}
