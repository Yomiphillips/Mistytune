// Draft's scale-up (build 26): the half-resolution trace back to the buffer the host asked
// for. See src/engine/Upscale.h.
//
// THE CLAIMS THAT MATTER are the ones a picture would hide: that a flat field stays exactly
// flat (a scale-up that leaks brightness reads as a grading change, not a bug), that a ramp
// lands where the block centres say it should (a half-block shift is the half-pixel crawl
// primaryRayDirection's own comment warns about), and that the pitch is honoured (AE pads
// its rows, and a scale-up that assumed it did not would shear the frame).

#include "TestFramework.h"

#include "Upscale.h"

#include <vector>

using namespace plugin;
using namespace plugin::cloud;

PL_TEST(StrideExtentCoversEveryPixel) {
    PL_CHECK_EQ(strideExtent(480, 1), 480);
    PL_CHECK_EQ(strideExtent(480, 2), 240);
    PL_CHECK_EQ(strideExtent(135, 2), 68);     // the odd row is its own block
    PL_CHECK_EQ(strideExtent(1, 2), 1);
    PL_CHECK_EQ(strideExtent(0, 2), 0);
}

PL_TEST(StrideOneIsACopy) {
    std::vector<float> src(3 * 2 * 4), dst(3 * 2 * 4, -1.0f);
    for (size_t i = 0; i < src.size(); ++i) src[i] = static_cast<float>(i);
    upscaleFromStride(src.data(), 3, 2, 3, dst.data(), 3, 2, 3, 1);
    for (size_t i = 0; i < src.size(); ++i) PL_CHECK_EQ(dst[i], src[i]);
}

PL_TEST(AFlatFieldStaysExactlyFlat) {
    const int sw = 5, sh = 3, dw = 9, dh = 5;     // odd destination: the last block is half off
    std::vector<float> src(sw * sh * 4), dst(dw * dh * 4, -1.0f);
    for (int i = 0; i < sw * sh; ++i) {
        src[i * 4 + 0] = 1.0f;  src[i * 4 + 1] = 0.25f;
        src[i * 4 + 2] = 0.5f;  src[i * 4 + 3] = 2.0f;
    }
    upscaleFromStride(src.data(), sw, sh, sw, dst.data(), dw, dh, dw, 2);
    for (int i = 0; i < dw * dh; ++i) {
        PL_CHECK_EQ(dst[i * 4 + 0], 1.0f);
        PL_CHECK_EQ(dst[i * 4 + 1], 0.25f);
        PL_CHECK_EQ(dst[i * 4 + 2], 0.5f);
        PL_CHECK_EQ(dst[i * 4 + 3], 2.0f);
    }
}

// A RAMP IN X, SAMPLED AT THE BLOCK CENTRES: source pixel i holds the value at destination
// coordinate (i + 0.5) * 2, so a correct scale-up reproduces x + 0.5 at every destination
// pixel between the first and last centres -- and clamps outside them.
PL_TEST(ARampLandsOnTheBlockCentres) {
    const int sw = 6, sh = 2, dw = 12, dh = 4;
    std::vector<float> src(sw * sh * 4), dst(dw * dh * 4, -1.0f);
    for (int j = 0; j < sh; ++j)
        for (int i = 0; i < sw; ++i)
            for (int k = 0; k < 4; ++k)
                src[(j * sw + i) * 4 + k] = (static_cast<float>(i) + 0.5f) * 2.0f;
    upscaleFromStride(src.data(), sw, sh, sw, dst.data(), dw, dh, dw, 2);

    for (int y = 0; y < dh; ++y) {
        for (int x = 0; x < dw; ++x) {
            const float centre = static_cast<float>(x) + 0.5f;
            const float want = centre < 1.0f ? 1.0f : (centre > 11.0f ? 11.0f : centre);
            PL_CHECK_NEAR(dst[(y * dw + x) * 4 + 1], want, 1e-5);
        }
    }
}

// AE PADS ITS ROWS. Both pitches are honoured, and the padding is never written.
PL_TEST(PitchesAreHonouredAndPaddingUntouched) {
    const int sw = 2, sh = 2, sp = 3, dw = 4, dh = 4, dp = 6;
    std::vector<float> src(sp * sh * 4, 99.0f), dst(dp * dh * 4, -7.0f);
    for (int j = 0; j < sh; ++j)
        for (int i = 0; i < sw; ++i)
            for (int k = 0; k < 4; ++k) src[(j * sp + i) * 4 + k] = 1.0f;
    upscaleFromStride(src.data(), sw, sh, sp, dst.data(), dw, dh, dp, 2);

    for (int y = 0; y < dh; ++y) {
        for (int x = 0; x < dp; ++x) {
            const float want = x < dw ? 1.0f : -7.0f;
            for (int k = 0; k < 4; ++k) PL_CHECK_EQ(dst[(y * dp + x) * 4 + k], want);
        }
    }
}
