// GENERATED FROM Phase.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

static __device__ float dot_0(float3  x_0, float3  y_0)
{
    return x_0.x * y_0.x + x_0.y * y_0.y + x_0.z * y_0.z;
}

static __device__ float length_0(float3  x_1)
{
    return (F32_sqrt((dot_0(x_1, x_1))));
}

static __device__ float3  cross_0(float3  left_0, float3  right_0)
{
    float _S1 = left_0.y;
    float _S2 = right_0.z;
    float _S3 = left_0.z;
    float _S4 = right_0.y;
    float _S5 = right_0.x;
    float _S6 = left_0.x;
    return make_float3 (_S1 * _S2 - _S3 * _S4, _S3 * _S5 - _S6 * _S2, _S6 * _S4 - _S1 * _S5);
}

static __device__ float3  normalize_0(float3  x_2)
{
    return x_2 / make_float3 (length_0(x_2));
}

static __device__ float lerp_0(float x_3, float y_1, float s_0)
{
    return x_3 + (y_1 - x_3) * s_0;
}

static __device__ float clamp_0(float x_4, float minBound_0, float maxBound_0)
{
    return (F32_min(((F32_max((x_4), (minBound_0)))), (maxBound_0)));
}

struct PhaseInput_0
{
    float hgG_0;
    float draineG_0;
    float draineAlpha_0;
    float draineW_0;
    int useIce_0;
    float lobeG_0;
    float lobeWeight_0;
};

static __device__ PhaseInput_0 phaseFromDropletDiameter_0(float diameterMicrons_0, int useIce_1)
{
    float d_0 = clamp_0(diameterMicrons_0, 5.0f, 50.0f);
    PhaseInput_0 p_0;
    (&p_0)->hgG_0 = clamp_0((F32_exp((-0.09905669838190079f / (d_0 - 1.6715400218963623f)))), -0.99900001287460327f, 0.99900001287460327f);
    (&p_0)->draineG_0 = clamp_0((F32_exp((- (2.20678997039794922f / (d_0 + 3.91029000282287598f)) - 0.4289340078830719f))), -0.99900001287460327f, 0.99900001287460327f);
    (&p_0)->draineAlpha_0 = (F32_exp((3.62489008903503418f - 8.29288005828857422f / (d_0 + 5.52825021743774414f))));
    (&p_0)->draineW_0 = (F32_exp((- (0.59908497333526611f / (d_0 - 0.64158302545547485f)) - 0.66588801145553589f)));
    (&p_0)->useIce_0 = useIce_1;
    (&p_0)->lobeG_0 = 0.0f;
    (&p_0)->lobeWeight_0 = 0.0f;
    return p_0;
}

static __device__ float hg_0(float cosT_0, float g_0)
{
    float _S7 = g_0 * g_0;
    float d_1 = 1.0f + _S7 - 2.0f * g_0 * cosT_0;
    return (1.0f - _S7) / (12.56637096405029297f * d_1 * (F32_sqrt(((F32_max((d_1), (9.99999997475242708e-07f)))))));
}

static __device__ float phaseIce_0(float cosT_1)
{
    float t_0 = ((F32_acos((clamp_0(cosT_1, -1.0f, 1.0f)))) - 0.38400000333786011f) / 0.03500000014901161f;
    return lerp_0(0.07957746833562851f, hg_0(cosT_1, 0.85000002384185791f), 0.72000002861022949f) + (F32_exp((- t_0 * t_0))) * 0.34999999403953552f;
}

static __device__ float draine_0(float cosT_2, float g_1, float a_0)
{
    float _S8 = g_1 * g_1;
    float _S9 = 2.0f * g_1;
    float d_2 = 1.0f + _S8 - _S9 * cosT_2;
    return (1.0f - _S8) / (12.56637096405029297f * d_2 * (F32_sqrt(((F32_max((d_2), (9.99999997475242708e-07f))))))) * (1.0f + a_0 * cosT_2 * cosT_2) / (1.0f + a_0 * (1.0f + _S9 * g_1) / 3.0f);
}

static __device__ float phaseLiquid_0(PhaseInput_0 * p_1, float cosT_3)
{
    return (1.0f - p_1->draineW_0) * hg_0(cosT_3, p_1->hgG_0) + p_1->draineW_0 * draine_0(cosT_3, p_1->draineG_0, p_1->draineAlpha_0);
}

static __device__ float phaseAt_0(PhaseInput_0 * p_2, float cosT_4)
{
    float _S10;
    if((p_2->useIce_0) != int(0))
    {
        _S10 = phaseIce_0(cosT_4);
    }
    else
    {
        float _S11 = phaseLiquid_0(p_2, cosT_4);
        _S10 = _S11;
    }
    return _S10;
}

extern "C" __global__ void phaseEval(float dropletDiameter_0, int useIce_2, RWStructuredBuffer<float> output_0, int count_0)
{
    int i_0 = int((blockIdx * blockDim + threadIdx).x);
    if(i_0 >= count_0)
    {
        return;
    }
    float mu_0 = -1.0f + (float(i_0) + 0.5f) * (2.0f / float(count_0));
    float * _S12 = (&(output_0)[i_0]);
    PhaseInput_0 _S13 = phaseFromDropletDiameter_0(dropletDiameter_0, useIce_2);
    float _S14 = phaseAt_0(&_S13, mu_0);
    *_S12 = _S14;
    return;
}

struct Rng_0
{
    uint state_0;
};

static __device__ Rng_0 makeRng_0(uint seed_0)
{
    Rng_0 r_0;
    (&r_0)->state_0 = seed_0;
    return r_0;
}

static __device__ float randFloat_0(Rng_0 * r_1)
{
    uint _S15 = r_1->state_0 * 747796405U + 2891336453U;
    r_1->state_0 = _S15;
    uint word_0 = ((_S15 >> ((_S15 >> 28U) + 4U)) ^ _S15) * 277803737U;
    return float((word_0 >> 22U) ^ word_0) * 2.32830643653869629e-10f;
}

extern "C" __global__ void rngTrial(RWStructuredBuffer<float> output_1, uint seed_1, int count_1)
{
    int i_1 = int((blockIdx * blockDim + threadIdx).x);
    if(i_1 >= count_1)
    {
        return;
    }
    Rng_0 rng_0 = makeRng_0(seed_1 + uint(i_1));
    float * _S16 = (&(output_1)[i_1]);
    float _S17 = randFloat_0(&rng_0);
    *_S16 = _S17;
    return;
}

static __device__ float3  sampleHG_0(Rng_0 * rng_1, float3  wo_0, float g_2, float * cosT_5)
{
    float _S18 = clamp_0(g_2, -0.99900001287460327f, 0.99900001287460327f);
    float u1_0 = randFloat_0(rng_1);
    float u2_0 = randFloat_0(rng_1);
    if((F32_abs((_S18))) < 0.00100000004749745f)
    {
        *cosT_5 = 1.0f - 2.0f * u1_0;
    }
    else
    {
        float _S19 = _S18 * _S18;
        float _S20 = 2.0f * _S18;
        float s_1 = (1.0f - _S19) / (1.0f - _S18 + _S20 * u1_0);
        *cosT_5 = (1.0f + _S19 - s_1 * s_1) / _S20;
    }
    float _S21 = clamp_0(*cosT_5, -1.0f, 1.0f);
    *cosT_5 = _S21;
    float sinT_0 = (F32_sqrt(((F32_max((0.0f), (1.0f - _S21 * _S21))))));
    float phi_0 = 6.28318548202514648f * u2_0;
    float3  w_0 = normalize_0(wo_0);
    float3  a_1;
    if((F32_abs((w_0.y))) < 0.94999998807907104f)
    {
        a_1 = make_float3 (0.0f, 1.0f, 0.0f);
    }
    else
    {
        a_1 = make_float3 (1.0f, 0.0f, 0.0f);
    }
    float3  u_0 = normalize_0(cross_0(a_1, w_0));
    return normalize_0(make_float3 (sinT_0 * (F32_cos((phi_0)))) * u_0 + make_float3 (sinT_0 * (F32_sin((phi_0)))) * cross_0(w_0, u_0) + make_float3 (*cosT_5) * w_0);
}

static __device__ float3  sampleDraine_0(Rng_0 * rng_2, float3  wo_1, float g_3, float a_2, float * cosT_6)
{
    float3  dir_0 = sampleHG_0(rng_2, wo_1, g_3, cosT_6);
    if(!(a_2 > 0.0f))
    {
        return dir_0;
    }
    float3  dir_1 = dir_0;
    int i_2 = int(0);
    for(;;)
    {
        if(i_2 < int(64))
        {
        }
        else
        {
            break;
        }
        float _S22 = randFloat_0(rng_2);
        if((_S22 * (1.0f + a_2)) <= (1.0f + a_2 * *cosT_6 * *cosT_6))
        {
            break;
        }
        float3  _S23 = sampleHG_0(rng_2, wo_1, g_3, cosT_6);
        int i_3 = i_2 + int(1);
        dir_1 = _S23;
        i_2 = i_3;
    }
    return dir_1;
}

static __device__ float3  samplePhaseDir_0(PhaseInput_0 * p_3, Rng_0 * rng_3, float3  wo_2, float * weight_0)
{
    float cosT_7;
    float3  dir_2;
    float _S24;
    if((p_3->useIce_0) != int(0))
    {
        float _S25 = randFloat_0(rng_3);
        if(_S25 < 0.72000002861022949f)
        {
            float3  _S26 = sampleHG_0(rng_3, wo_2, 0.85000002384185791f, &cosT_7);
            dir_2 = _S26;
        }
        else
        {
            float3  _S27 = sampleHG_0(rng_3, wo_2, 0.0f, &cosT_7);
            dir_2 = _S27;
        }
        float pdf_0 = 0.72000002861022949f * hg_0(cosT_7, 0.85000002384185791f) + 0.02228168956935406f;
        if(pdf_0 > 9.99999971718068537e-10f)
        {
            _S24 = phaseIce_0(cosT_7) / pdf_0;
        }
        else
        {
            _S24 = 0.0f;
        }
        *weight_0 = _S24;
    }
    else
    {
        float _S28 = randFloat_0(rng_3);
        if(_S28 < (p_3->draineW_0))
        {
            float3  _S29 = sampleDraine_0(rng_3, wo_2, p_3->draineG_0, p_3->draineAlpha_0, &cosT_7);
            dir_2 = _S29;
        }
        else
        {
            float3  _S30 = sampleHG_0(rng_3, wo_2, p_3->hgG_0, &cosT_7);
            dir_2 = _S30;
        }
        float _S31 = phaseLiquid_0(p_3, cosT_7);
        if(_S31 > 9.99999971718068537e-10f)
        {
            _S24 = 1.0f;
        }
        else
        {
            _S24 = 0.0f;
        }
        *weight_0 = _S24;
    }
    return dir_2;
}

extern "C" __global__ void phaseSample(float dropletDiameter_1, int useIce_3, RWStructuredBuffer<float> outCos_0, RWStructuredBuffer<float> outWeight_0, uint seed_2, int count_2)
{
    int i_4 = int((blockIdx * blockDim + threadIdx).x);
    if(i_4 >= count_2)
    {
        return;
    }
    PhaseInput_0 params_0 = phaseFromDropletDiameter_0(dropletDiameter_1, useIce_3);
    Rng_0 rng_4 = makeRng_0(seed_2 + uint(i_4) * 2654435761U);
    float3  wo_3 = make_float3 (0.0f, 0.0f, 1.0f);
    PhaseInput_0 _S32 = params_0;
    float weight_1;
    float3  _S33 = samplePhaseDir_0(&_S32, &rng_4, wo_3, &weight_1);
    *(&(outCos_0)[i_4]) = clamp_0(dot_0(_S33, wo_3), -1.0f, 1.0f);
    *(&(outWeight_0)[i_4]) = weight_1;
    return;
}

