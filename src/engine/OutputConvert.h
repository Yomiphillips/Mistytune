#pragma once

// The float the renderer produces, to the pixels After Effects asked for.
//
// ===========================================================================
// WHY THIS IS IN src/engine/ RATHER THAN INLINE IN THE SMART-RENDER LOOP, WHICH IS
// WHERE IT WAS.
//
// It carries three host conventions, all of which fail QUIETLY, none of which needs an
// AE header to exercise, and every one of which was previously checkable only by
// rendering in After Effects and looking at it:
//
//   * AE's 16-bit channels run 0..32768, NOT 0..65535. Getting it wrong halves the
//     brightness of every 16 bpc render, which reads as a grading choice.
//   * 8 and 16 bpc are DISPLAY-REFERRED and want the sRGB curve; 32 bpc float is
//     linear and must not have one. Skipping the curve renders near-black with a sun
//     in it -- measured, see encodeSrgb below.
//   * ALPHA IS COVERAGE, NOT LIGHT, and never gets the curve. An opaque sky cannot
//     show this, which is exactly why it would survive review and break the first
//     generator with a real matte.
//
// PLAN.md's Phase 1 exit asks for 8, 16 and 32 bpc to be correct, and the only tool
// that had ever been pointed at them was a person looking at a picture. Here
// tests/unit/ exercises all three in microseconds with no SDK and no host -- which is
// the entire argument for the src/engine split, applied to the last part of the render
// path that was not getting it.
//
// FLOAT, NOT Scalar, THROUGHOUT. The rest of src/engine/ computes in double, and this
// file deliberately does not: it is quantising a float buffer that the kernel wrote,
// and widening the arithmetic would change which integer a value lands on for inputs
// near a rounding boundary. That would move every 8 and 16 bpc pixel AE has ever been
// handed, for no gain, and it would do it silently.
// ===========================================================================

#include "Image.h"

#include <cmath>

namespace plugin::cloud {

// ---------------------------------------------------------------------------
// The output transfer curve
// ---------------------------------------------------------------------------

// ===========================================================================
// AE'S INTEGER WORLDS ARE DISPLAY-REFERRED. ITS FLOAT WORLD IS LINEAR.
//
// This is the single most important host convention for anything that RENDERS light
// rather than filtering someone else's pixels, and getting it wrong does not look like
// a colour-management mistake -- it looks like the renderer is broken.
//
//   PF_PixelFormat_ARGB128 (32 bpc float)   linear. Write radiance straight in.
//   PF_PixelFormat_ARGB64  (16 bpc, 0..32768)
//   PF_PixelFormat_ARGB32  (8 bpc, 0..255)  the project working space, which is
//                                           display-encoded -- sRGB by default.
//
// WHAT IT LOOKS LIKE WHEN YOU SKIP IT. Multiplying linear radiance by 255 and storing
// it applies no curve at all, so everything below mid-grey collapses towards black and
// only values above 1.0 survive. Measured on the Phase 1 sky: the ground landed at
// 18/255 where it should be 74, and the zenith at 106 where it should be 169. The one
// thing still clearly visible was the sun disc, which is brighter than 1.0 and clips to
// white.
//
// The symptom is therefore "the effect renders black with a bit of sun in it", and
// nothing about that points at a missing transfer curve.
//
// SRGB RATHER THAN THE PROJECT'S ACTUAL WORKING SPACE, and that is a stopgap with a
// date on it. AE can be told to work in Rec.709, Rec.2020 or a linear space, and the
// honest answer reads the project's colour settings and uses them. sRGB is the default
// working space and therefore right far more often than linear is, which is what makes
// it worth doing now rather than at the same time as the real thing.
// ===========================================================================

// The sRGB opto-electronic transfer function (IEC 61966-2-1).
//
// THE LINEAR SEGMENT NEAR ZERO IS NOT OPTIONAL. A pure 1/2.4 power curve has an
// infinite slope at the origin, which turns sensor and sampling noise in the darkest
// values into visible speckle -- and a path tracer's darkest values are exactly where
// its noise lives.
inline float encodeSrgb(float linear) {
    if (linear <= 0.0f)        return 0.0f;
    if (linear <= 0.0031308f)  return linear * 12.92f;
    return 1.055f * std::pow(linear, 1.0f / 2.4f) - 0.055f;
}

// ---------------------------------------------------------------------------
// The quantiser
// ---------------------------------------------------------------------------

// The full-scale channel value for an integer format: what a linear 1.0 becomes.
//
// 32768 FOR 16-BIT AND THE COMMENT IN Image.h IS THE REASON. Repeated as a function
// here rather than read from two places, because the whole point of this header is
// that there is exactly one copy of this number on the output path. The smart-render
// loop had its own.
inline float fullScale(PixelFormat format) {
    switch (format) {
        case PixelFormat::ARGB8:   return static_cast<float>(kMaxChan8);
        case PixelFormat::ARGB16:  return static_cast<float>(kMaxChan16);
        case PixelFormat::ARGB32F: return 1.0f;
    }
    return static_cast<float>(kMaxChan8);
}

// One pixel: premultiplied linear ARGB in, one pixel of `format` out.
//
// ===========================================================================
// THE ORDER OF OPERATIONS IS THE WHOLE FUNCTION, and each step is here because doing
// it in a different order is wrong in a way that still renders.
//
//   1. CLAMP, integer formats only. A radiance above 1 is legitimate in 32 bpc float
//      -- it is the sun -- and clamping there throws away the headroom that path
//      exists to carry. Here there is nowhere to put it.
//   2. ENCODE, COLOUR ONLY. See encodeSrgb. Alpha is coverage.
//   3. SCALE AND ROUND. Encoding after scaling would apply the curve to a number in
//      0..255 rather than 0..1, which is not the same function at all.
//
// PREMULTIPLIED IN, PREMULTIPLIED OUT. AE effect buffers always are. At alpha 1 --
// which an opaque sky always has -- premultiplied and straight are the same numbers, so
// the encode-without-unpremultiplying below is correct rather than merely convenient.
// A generator with genuine partial coverage wants the colour divided by alpha, encoded,
// and multiplied back; until one exists, doing that would be untested code on the
// render path, and the test that pins the current behaviour says which it is.
// ===========================================================================
inline void writeConverted(void* dstPixel, PixelFormat format,
                           float a, float r, float g, float b) {
    if (format == PixelFormat::ARGB32F) {
        // STRAIGHT THROUGH, UNCLAMPED AND UNENCODED. The renderer already works in
        // this format, which is why the effect renders directly into AE's buffer at
        // 32 bpc and never builds a staging buffer at all. Handled here anyway so
        // that the asymmetry is asserted by a test rather than implied by an `if` at
        // the one call site.
        float* p = static_cast<float*>(dstPixel);
        p[0] = a; p[1] = r; p[2] = g; p[3] = b;
        return;
    }

    // ===================================================================
    // NO TRANSFER CURVE HERE ANY MORE, AND ITS ABSENCE IS THE FIX RATHER THAN AN
    // OMISSION.
    //
    // This function used to sRGB-encode the colour channels, and nothing encoded the
    // 32 bpc path -- so the same comp rendered differently at different bit depths, and
    // each depth looked plausible on its own. Measured in AE 2026 with Working Color
    // Space None: the two differed by exactly one sRGB encode.
    //
    // THE ENCODING IS A PROPERTY OF THE PROJECT, NOT OF THE BIT DEPTH, so it moved to
    // applyOutputTransform() in src/kernel/Shading.h, beside the exposure and the
    // tonemap it is the third stage of. Every path goes through that one function, so
    // every path now agrees. See ViewParams::encodeSrgb.
    //
    // WHAT ARRIVES HERE IS THEREFORE ALREADY DISPLAY-REFERRED, and all that is left to
    // do is clamp it and quantise it.
    // ===================================================================
    a = a < 0.0f ? 0.0f : (a > 1.0f ? 1.0f : a);
    r = r < 0.0f ? 0.0f : (r > 1.0f ? 1.0f : r);
    g = g < 0.0f ? 0.0f : (g > 1.0f ? 1.0f : g);
    b = b < 0.0f ? 0.0f : (b > 1.0f ? 1.0f : b);

    const float scale = fullScale(format);

    // ROUNDED BY ADDING A HALF, which is exact for these ranges: every input is
    // already inside 0..scale, so the sum cannot reach the next representable step
    // above scale + 0.5 and the truncating cast lands on the nearest integer.
    const float av = a * scale + 0.5f;
    const float rv = r * scale + 0.5f;
    const float gv = g * scale + 0.5f;
    const float bv = b * scale + 0.5f;

    if (format == PixelFormat::ARGB16) {
        uint16_t* p = static_cast<uint16_t*>(dstPixel);
        p[0] = static_cast<uint16_t>(av);
        p[1] = static_cast<uint16_t>(rv);
        p[2] = static_cast<uint16_t>(gv);
        p[3] = static_cast<uint16_t>(bv);
    } else {
        uint8_t* p = static_cast<uint8_t*>(dstPixel);
        p[0] = static_cast<uint8_t>(av);
        p[1] = static_cast<uint8_t>(rv);
        p[2] = static_cast<uint8_t>(gv);
        p[3] = static_cast<uint8_t>(bv);
    }
}

// A whole frame: a tightly packed float ARGB staging buffer into a host world.
//
// TWO DIFFERENT STRIDES, AND THAT IS THE POINT OF TAKING AN ImageView. The staging
// buffer the kernel writes is tightly packed -- `pitchPx = width` -- while an AE world
// has a rowbytes that is padded and, for a windowed render, describes a sub-rect of
// something larger. Reading the destination's stride from anywhere but the world is how
// a render lands diagonally.
inline void convertStagingFrame(const float* staging, const ImageView& dst) {
    if (!staging || !dst.valid()) return;

    const int bpp = bytesPerPixel(dst.format);

    for (int y = 0; y < dst.height; ++y) {
        const float* src = staging + static_cast<size_t>(y) * dst.width * 4;
        uint8_t*     row = dst.rowPtr<uint8_t>(y);

        for (int x = 0; x < dst.width; ++x) {
            writeConverted(row + static_cast<std::ptrdiff_t>(x) * bpp, dst.format,
                           src[x * 4 + 0], src[x * 4 + 1],
                           src[x * 4 + 2], src[x * 4 + 3]);
        }
    }
}

} // namespace plugin::cloud
