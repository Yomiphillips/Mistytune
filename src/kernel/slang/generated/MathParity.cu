// GENERATED FROM MathParity.slang BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

#include "../prelude/slang-cuda-prelude.h"

extern "C" __global__ void mathMain(StructuredBuffer<float> input_0, RWStructuredBuffer<float> output_0, int count_0)
{
    int i_0 = int((blockIdx * blockDim + threadIdx).x);
    if(i_0 >= count_0)
    {
        return;
    }
    float _S1 = __ldg((&(input_0)[i_0]));
    int _S2 = i_0 * int(7);
    *(&(output_0)[_S2]) = (F32_exp((_S1)));
    float _S3 = (F32_abs((_S1)));
    *(&(output_0)[_S2 + int(1)]) = (F32_sqrt((_S3)));
    *(&(output_0)[_S2 + int(2)]) = (F32_cos((_S1)));
    *(&(output_0)[_S2 + int(3)]) = (F32_sin((_S1)));
    *(&(output_0)[_S2 + int(4)]) = (F32_tan((_S1)));
    *(&(output_0)[_S2 + int(5)]) = (F32_rsqrt((_S3 + 1.0f)));
    *(&(output_0)[_S2 + int(6)]) = (F32_exp2((_S1)));
    return;
}

