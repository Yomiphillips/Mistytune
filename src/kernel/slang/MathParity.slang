// Every transcendental the renderer actually calls, evaluated through Slang.
//
// ===========================================================================
// WHAT THIS GUARDS, AND WHY IT IS NOT A CURIOSITY.
//
// The whole case for writing the transport in Slang rests on one measured claim:
// Slang's CUDA output calls the SAME math functions the CPU reference does, so a
// faithful port reproduces tests/golden/ by construction rather than by luck.
//
// That claim holds only while `-fp-mode fast` is absent. With it, Slang emits
// SLANG_CUDA_ENABLE_FAST_MATH=1 and the prelude redirects exp/sin/cos/tan/log/pow to
// the approximate __*f intrinsics. Measured over the 44,001 inputs this file's test
// uses: exp differs on 36,886 of them, worst absolute difference 4.12e11; tan on
// 43,688, worst 2812.
//
// IT BREAKS SOME FUNCTIONS AND NOT OTHERS. sqrt, rsqrt and exp2 have no fast form in
// CUDA and stay exact. So a build with fast math on renders a picture that is NEARLY
// RIGHT, and the golden suite catches it only where exp happens to dominate a pixel.
// That is precisely the kind of defect this project has repeatedly shipped: wrong in
// a way that still looks like a photograph.
//
// A comment asking for `-fp-mode precise` would not survive a build-file edit two
// years from now. This does.
// ===========================================================================
//
// The inventory is counted out of Shading.h, not guessed:
//     expf x16   sqrtf x5   cosf x3   sinf x2   tanf x1   rsqrtf x1   exp2f x1
//
// WHEN THE TRANSPORT LANDS AND ADDS A FUNCTION -- pow, log, atan2, asin -- IT GOES IN
// HERE TOO. A parity test that covers six of the seven functions in use is a parity
// test with a hole in it, and the hole is wherever the newest code is.

[shader("compute")]
[numthreads(256, 1, 1)]
void mathMain(uint3 tid : SV_DispatchThreadID,
              uniform StructuredBuffer<float> input,
              uniform RWStructuredBuffer<float> output,
              uniform int count)
{
    int i = int(tid.x);
    if (i >= count) return;

    float x = input[i];

    output[i * 7 + 0] = exp(x);
    output[i * 7 + 1] = sqrt(abs(x));
    output[i * 7 + 2] = cos(x);
    output[i * 7 + 3] = sin(x);
    output[i * 7 + 4] = tan(x);
    output[i * 7 + 5] = rsqrt(abs(x) + 1.0f);
    output[i * 7 + 6] = exp2(x);
}
