// The output conversion: float radiance to the pixels After Effects asked for.
//
// ===========================================================================
// WHY THIS FILE EXISTS, AND IT IS THE LAST PART OF THE RENDER PATH TO GET IT.
//
// PLAN.md's Phase 1 exit criterion is that the effect "renders CORRECTLY at 8, 16 and
// 32 bpc (16-bit channels run 0..32768, not 65535)". That criterion has been open since
// the effect first loaded, and the reason it stayed open is that the conversion lived
// inside the smart-render loop, where the only way to exercise it was to render in After
// Effects and look at the picture.
//
// LOOKING CANNOT SETTLE ANY OF THE THREE THINGS IN IT.
//
//   * 0..32768 versus 0..65535 is a factor of two in brightness, in ONE bit depth that
//     a person is unlikely to be working in when they check. It reads as a grading
//     choice, not as a bug.
//   * A missing sRGB curve renders near-black with a sun in it -- which looks like a
//     broken renderer and sends the reader to the transport.
//   * Encoding ALPHA along with the colour is invisible on an opaque sky. There is no
//     picture this renderer currently produces in which it shows at all. It breaks the
//     first generator with a real matte, months later, in someone else's scene.
//
// None of it needs an AE header, a GPU or a host, which is what makes moving it into
// src/engine/OutputConvert.h the whole fix. What remains for After Effects to confirm is
// that the plugin loads and that AE hands us the format it says it will -- not whether
// the arithmetic is right.
// ===========================================================================

#include "TestFramework.h"

#include "OutputConvert.h"

// applyOutputTransform and encodeSrgbChannel: the curve moved there, and so did the
// tests for it. plugin_tests already links plugin_kernel -- TestCamera.cpp does the same.
#include "Shading.h"

#include <cmath>
#include <cstdint>
#include <cstdio>
#include <vector>

using namespace plugin;
using namespace plugin::cloud;
using namespace plugin::kernel;

namespace {

// A one-pixel conversion, so each test reads as the claim it is making.
struct Pixel16 { uint16_t a, r, g, b; };
struct Pixel8  { uint8_t  a, r, g, b; };

Pixel16 to16(float a, float r, float g, float b) {
    uint16_t buf[4] = { 0, 0, 0, 0 };
    writeConverted(buf, PixelFormat::ARGB16, a, r, g, b);
    return { buf[0], buf[1], buf[2], buf[3] };
}

Pixel8 to8(float a, float r, float g, float b) {
    uint8_t buf[4] = { 0, 0, 0, 0 };
    writeConverted(buf, PixelFormat::ARGB8, a, r, g, b);
    return { buf[0], buf[1], buf[2], buf[3] };
}

} // namespace

// ---------------------------------------------------------------------------
// The 16-bit range
// ---------------------------------------------------------------------------

// ===========================================================================
// THE ONE PLAN.md NAMES, AND IT IS NOW A TEST RATHER THAN A SENTENCE IN A COMMENT.
//
// AE's 16-bit channels run 0..32768 INCLUSIVE, which is 32769 distinct values and not a
// power-of-two range. Every other host and every image format on disk uses 0..65535, so
// 65535 is what a reasonable person writes, and the result is a 16 bpc render at half
// brightness -- in the one bit depth that is neither the default nor the one anybody
// checks first.
// ===========================================================================
PL_TEST(SixteenBitWhiteIs32768NotWhatEveryOtherHostUses) {
    const Pixel16 p = to16(1.0f, 1.0f, 1.0f, 1.0f);

    PL_CHECK_EQ(p.a == 32768, 1);
    PL_CHECK_EQ(p.r == 32768, 1);
    PL_CHECK_EQ(p.g == 32768, 1);
    PL_CHECK_EQ(p.b == 32768, 1);

    // Stated as its own assertion, because 65535 is the value that would be there if
    // this had been written from habit, and it FITS in the type -- so nothing else in
    // the program would object to it.
    PL_CHECK(p.r != 65535);
}

PL_TEST(SixteenBitBlackIsZeroAndNothingIsOffByHalf) {
    const Pixel16 p = to16(0.0f, 0.0f, 0.0f, 0.0f);

    PL_CHECK_EQ(p.a == 0, 1);
    PL_CHECK_EQ(p.r == 0, 1);
    PL_CHECK_EQ(p.g == 0, 1);
    PL_CHECK_EQ(p.b == 0, 1);
}

PL_TEST(EightBitWhiteIs255) {
    const Pixel8 p = to8(1.0f, 1.0f, 1.0f, 1.0f);

    PL_CHECK_EQ(p.a == 255, 1);
    PL_CHECK_EQ(p.r == 255, 1);
    PL_CHECK_EQ(p.g == 255, 1);
    PL_CHECK_EQ(p.b == 255, 1);
}

// THE FULL-SCALE VALUE IS READ FROM ONE PLACE, and this is what says so. The smart-render
// loop used to carry its own copy of both numbers.
PL_TEST(FullScaleMatchesTheImageFormatConstants) {
    PL_CHECK_EQ(fullScale(PixelFormat::ARGB8)  == static_cast<float>(kMaxChan8),  1);
    PL_CHECK_EQ(fullScale(PixelFormat::ARGB16) == static_cast<float>(kMaxChan16), 1);
    PL_CHECK_EQ(fullScale(PixelFormat::ARGB32F) == 1.0f, 1);
}

// ---------------------------------------------------------------------------
// The transfer curve, which is no longer in this file's subject
// ---------------------------------------------------------------------------

// ===========================================================================
// THE CURVE MOVED, AND THE BUG THAT MOVED IT IS WHAT THESE NOW GUARD.
//
// This file used to assert that writeConverted() sRGB-encodes the colour channels. It
// did, and nothing encoded the 32 bpc path -- so the same comp rendered DIFFERENTLY at
// different bit depths, and each depth looked entirely plausible on its own.
//
// MEASURED IN AE 2026, Working Color Space None: one frame at 32 bpc and the same frame
// at 16 bpc differed by exactly one sRGB encode, to half a code value on flat areas. AE
// applies no transform to either buffer -- it is the identity at every depth -- so the
// encode was ours and the asymmetry was ours.
//
// The encoding is a property of the PROJECT, not of the bit depth, so it lives in
// applyOutputTransform() beside the exposure and the tonemap it is the third stage of.
// Every render path goes through that one function.
// ===========================================================================

namespace {

// The output transform on a single grey level, which is all these need.
float transformedGrey(float linear, bool encode, bool agx = false) {
    ViewParams view;
    view.exposureEV = 0.0f;
    view.agxTonemap = agx;
    view.encodeSrgb = encode;
    return applyOutputTransform(vec3(linear, linear, linear), view).x;
}

} // namespace

// WITHOUT THE CURVE, MID-GREY LANDS AT 128 AND IT SHOULD LAND AT 188.
//
// A linear 0.5 is not half way up an sRGB ramp; it is most of the way up, because the
// curve spends more codes on the darks where the eye can tell them apart. PROGRESS.md
// records a Phase 1 sky whose ground landed at 18/255 instead of 74 and whose zenith
// landed at 106 instead of 169 when this was missing -- and whose only clearly visible
// feature was the sun, which is above 1.0 and clips to white either way.
PL_TEST(LinearMidGreyEncodesWellAboveHalf) {
    const float encoded = transformedGrey(0.5f, true);

    // 1.055 * 0.5^(1/2.4) - 0.055 = 0.7354
    PL_CHECK_NEAR(encoded, 0.7354, 0.001);

    // The value it would have with no curve, named so a regression reads as "the curve
    // is gone" rather than as an arithmetic slip.
    PL_CHECK(encoded > 0.7f);
    PL_CHECK_NEAR(transformedGrey(0.5f, false), 0.5, 1e-6);
}

// THE CURVE SURVIVES THE TONEMAP. AgX looks like a complete output transform and is only
// two thirds of one -- proto/index.html says so in the same words, and it is the easy one
// to get wrong because an AgX image looks finished.
PL_TEST(AgxStillGetsTheTransferCurve) {
    const float withCurve    = transformedGrey(0.5f, true,  true);
    const float withoutCurve = transformedGrey(0.5f, false, true);

    PL_CHECK(withCurve > withoutCurve);
    PL_CHECK_NEAR(withCurve, encodeSrgbChannel(withoutCurve), 1e-6);
}

// THE LINEAR SEGMENT NEAR ZERO IS NOT OPTIONAL, and it is the part most likely to be
// dropped as a rounding detail. A pure power curve has infinite slope at the origin,
// which is exactly where a path tracer's noise lives.
//
// ===========================================================================
// THE TOLERANCES ARE LOOSER THAN THEY LOOK, FOR TWO REASONS, AND BOTH ARE THE POINT. An
// earlier version used 1e-9 and 1e-6 and FAILED, and the function was right both times.
//
// 1. The transform is float by design -- it quantises a float buffer the kernel wrote,
//    and widening it would change which integer a value near a rounding boundary lands
//    on. 12.92f times 0.001f carries about 2e-9 on its own.
//
// 2. THE SRGB CURVE IS GENUINELY DISCONTINUOUS AT ITS BREAKPOINT, BY SPECIFICATION. IEC
//    61966-2-1 publishes 12.92 and 0.0031308, both rounded; the pair that actually joins
//    is 12.9232102 and 0.00313066844. Measured across the published breakpoint:
//
//        below   0.0404499360
//        above   0.0404511778
//        jump    1.24e-06, which is 0.0003 of an 8-bit code
//
//    Asserting the jump is zero would assert the standard is something it is not.
// ===========================================================================
PL_TEST(TheCurveIsLinearNearZeroAndContinuousAtTheJoin) {
    PL_CHECK_EQ(encodeSrgbChannel(0.0f) == 0.0f, 1);

    PL_CHECK_NEAR(encodeSrgbChannel(0.001f), 0.001 * 12.92, 1e-8);

    const double below = encodeSrgbChannel(0.0031308f);
    const double above = encodeSrgbChannel(0.0031309f);
    PL_CHECK_NEAR(below, above, 1e-5);

    // AND THE JOIN IS WHERE IT IS SUPPOSED TO BE. Continuity alone does not pin the
    // breakpoint -- a curve linear all the way to 0.1 is continuous with itself and
    // visibly wrong in the darks.
    PL_CHECK(encodeSrgbChannel(0.01f) < 0.01 * 12.92 * 0.9);
}

PL_TEST(TheCurveIsMonotonicAndReachesOneAtOne) {
    float previous = -1.0f;
    for (int i = 0; i <= 1000; ++i) {
        const float encoded = encodeSrgbChannel(static_cast<float>(i) / 1000.0f);
        PL_CHECK(encoded >= previous);
        previous = encoded;
    }
    PL_CHECK_NEAR(encodeSrgbChannel(1.0f), 1.0, 1e-6);
}

// ===========================================================================
// AND IT IS NOT CLAMPED ABOVE ONE, WHICH IS WHERE THIS DIFFERS FROM THE PROTOTYPE ON
// PURPOSE.
//
// proto/index.html clamps to 0..1 before encoding because a WebGL canvas has nowhere to
// put more. A 32 bpc After Effects buffer does, and the sun is what is in it -- every
// downstream glow, bloom and exposure adjustment in the comp needs those values to have
// survived the effect.
//
// The curve extends above 1 continuously, so the headroom survives compressed rather
// than clipped. The integer quantiser clamps at its own end, where it must.
// ===========================================================================
PL_TEST(TheCurveKeepsHeadroomAboveOne) {
    PL_CHECK(encodeSrgbChannel(4.0f) > 1.0f);
    PL_CHECK_NEAR(encodeSrgbChannel(4.0f), 1.055 * std::pow(4.0, 1.0 / 2.4) - 0.055, 1e-5);

    // Still monotonic across the boundary, so a bright edge does not invert.
    PL_CHECK(encodeSrgbChannel(1.5f) > encodeSrgbChannel(1.0f));
    PL_CHECK(encodeSrgbChannel(40.0f) > encodeSrgbChannel(4.0f));
}

// ===========================================================================
// THE REGRESSION THIS WHOLE CHANGE EXISTS FOR: ALL THREE BIT DEPTHS MUST AGREE.
//
// The bug was not that any one depth was wrong in isolation. It was that 32 bpc and
// 16 bpc rendered the same comp differently, because the encode was applied by the
// QUANTISER -- which only 8 and 16 bpc go through -- instead of by the output transform,
// which everything goes through.
//
// So this takes one linear radiance, runs the real transform once, and checks that what
// each depth ends up storing means the same brightness. Nothing here would have held
// before the change.
// ===========================================================================
PL_TEST(EveryBitDepthStoresTheSameBrightness) {
    const float linears[] = { 0.0f, 0.02f, 0.18f, 0.5f, 0.85f, 1.0f };

    for (float linear : linears) {
        // What the transform produces, which is what 32 bpc stores verbatim.
        const float display = transformedGrey(linear, true);

        uint8_t p8[4] = { 0, 0, 0, 0 };
        writeConverted(p8, PixelFormat::ARGB8, 1.0f, display, display, display);

        uint16_t p16[4] = { 0, 0, 0, 0 };
        writeConverted(p16, PixelFormat::ARGB16, 1.0f, display, display, display);

        // Back to a fraction of full scale, which is the only way to compare depths.
        const double as8  = p8[1]  / 255.0;
        const double as16 = p16[1] / 32768.0;

        // 8 bpc quantisation is half a code, which is 1/510.
        PL_CHECK_NEAR(as8,  static_cast<double>(display), 1.0 / 510.0);
        PL_CHECK_NEAR(as16, static_cast<double>(display), 1.0 / 65536.0);
        PL_CHECK_NEAR(as8, as16, 1.0 / 510.0);
    }
}

// ...AND THE QUANTISER APPLIES NO CURVE OF ITS OWN, which is the other half of the same
// property. A second encode anywhere on the path puts the depths back out of step, and it
// is exactly what used to be here.
PL_TEST(TheQuantiserAppliesNoTransferCurve) {
    const float values[] = { 0.0f, 0.1f, 0.25f, 0.5f, 0.75f, 1.0f };

    for (float v : values) {
        uint8_t p[4] = { 0, 0, 0, 0 };
        writeConverted(p, PixelFormat::ARGB8, v, v, v, v);

        const int expected = static_cast<int>(v * 255.0f + 0.5f);

        // ALL FOUR CHANNELS THE SAME, colour included. Alpha being unencoded used to be
        // the interesting half of this; now nothing is encoded here and the assertion is
        // that colour behaves exactly like alpha.
        PL_CHECK_EQ(p[0] == expected, 1);
        PL_CHECK_EQ(p[1] == expected, 1);
        PL_CHECK_EQ(p[2] == expected, 1);
        PL_CHECK_EQ(p[3] == expected, 1);
    }
}


// ---------------------------------------------------------------------------
// Out-of-range input
// ---------------------------------------------------------------------------

// A PATH TRACER PRODUCES VALUES ABOVE ONE AS A MATTER OF COURSE -- the sun is one --
// and the integer formats have nowhere to put them. Clamping is correct here and wrong
// one format over, which is the next test.
PL_TEST(IntegerFormatsClampAboveOneRatherThanWrapping) {
    const Pixel8  p8  = to8(2.0f, 100.0f, 1.0f, 3.0f);
    const Pixel16 p16 = to16(2.0f, 100.0f, 1.0f, 3.0f);

    PL_CHECK_EQ(p8.a == 255, 1);
    PL_CHECK_EQ(p8.r == 255, 1);
    PL_CHECK_EQ(p8.b == 255, 1);

    PL_CHECK_EQ(p16.a == 32768, 1);
    PL_CHECK_EQ(p16.r == 32768, 1);

    // WRAPPING IS THE FAILURE THIS RULES OUT, and it is what an unclamped cast to an
    // unsigned type does: a bright sun would come back as a dark disc with a hard edge,
    // which looks like a transport bug rather than a quantiser bug.
    PL_CHECK(p8.r != 0);
    PL_CHECK(p16.r != 0);
}

// NEGATIVE RADIANCE IS NOT SUPPOSED TO EXIST, which is why it has to be handled. A
// single stray negative cast to an unsigned type is a maximum-brightness pixel -- a
// white speck in a dark sky, indistinguishable from a firefly in the sampler.
PL_TEST(NegativeInputClampsToZeroRatherThanToWhite) {
    const Pixel8  p8  = to8(-1.0f, -0.5f, -1e9f, -0.0f);
    const Pixel16 p16 = to16(-1.0f, -0.5f, -1e9f, -0.0f);

    PL_CHECK_EQ(p8.a == 0, 1);
    PL_CHECK_EQ(p8.r == 0, 1);
    PL_CHECK_EQ(p8.g == 0, 1);
    PL_CHECK_EQ(p16.r == 0, 1);
    PL_CHECK_EQ(p16.g == 0, 1);
}

// ===========================================================================
// AND 32 BPC MUST NOT BE CLAMPED, WHICH IS THE OPPOSITE RULE IN THE SAME FUNCTION.
//
// Float is the format the renderer works in and the one the headroom exists for: a
// radiance of 40 is the sun, and an effect that clamps it has thrown away what every
// downstream glow, bloom and exposure adjustment in the comp needs. Nor does it get the
// curve -- AE's float world is linear.
//
// The effect never actually takes this branch, because at 32 bpc it renders straight
// into AE's buffer with no staging. It is here so the asymmetry is asserted rather than
// implied by an `if` at the call site.
// ===========================================================================
PL_TEST(ThirtyTwoBitFloatPassesHdrStraightThrough) {
    float buf[4] = { 0, 0, 0, 0 };
    writeConverted(buf, PixelFormat::ARGB32F, 1.0f, 40.0f, -0.25f, 0.5f);

    PL_CHECK_EQ(buf[0] == 1.0f, 1);
    PL_CHECK_EQ(buf[1] == 40.0f, 1);   // not clamped to 1
    PL_CHECK_EQ(buf[2] == -0.25f, 1);  // not clamped to 0 either
    PL_CHECK_EQ(buf[3] == 0.5f, 1);    // and NOT sRGB-encoded

    // Said plainly: a linear 0.5 survives as 0.5 here and becomes 188/255 one format
    // over. Both are correct, and that is the thing worth a test.
    PL_CHECK(buf[3] != encodeSrgb(0.5f));
}

// ---------------------------------------------------------------------------
// The frame walk
// ---------------------------------------------------------------------------

// ===========================================================================
// TWO DIFFERENT STRIDES, AND THE DESTINATION'S IS NOT THE WIDTH.
//
// The staging buffer the kernel writes is tightly packed. An AE world is padded, and at
// reduced resolution or inside a Region of Interest it describes a sub-rect of something
// larger. Taking the destination stride from the width instead of from the world is how
// a render lands diagonally across the frame -- which looks dramatic and is a one-line
// bug, and is exactly the kind of thing the reduced-resolution AE run could have hidden
// because 480 is a multiple of everything.
//
// So the destination here is DELIBERATELY PADDED, by a number of bytes that is not a
// whole pixel, and the padding is pre-filled with a sentinel that must survive.
// ===========================================================================
PL_TEST(TheFrameWalkHonoursTheDestinationStride) {
    const int width = 5, height = 3;
    const int padBytes = 6;                        // not a multiple of 4 bytes per pixel
    const std::ptrdiff_t rowBytes = width * 4 + padBytes;

    std::vector<uint8_t> dst(static_cast<size_t>(rowBytes) * height, 0xAB);

    std::vector<float> staging(static_cast<size_t>(width) * height * 4, 0.0f);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            const size_t i = (static_cast<size_t>(y) * width + x) * 4;
            staging[i + 0] = 1.0f;                                   // alpha
            staging[i + 1] = 1.0f;                                   // red: full
            staging[i + 2] = 0.0f;                                   // green: none
            staging[i + 3] = 0.0f;
        }
    }

    ImageView view;
    view.data     = dst.data();
    view.width    = width;
    view.height   = height;
    view.rowBytes = rowBytes;
    view.format   = PixelFormat::ARGB8;

    convertStagingFrame(staging.data(), view);

    for (int y = 0; y < height; ++y) {
        const uint8_t* row = dst.data() + static_cast<size_t>(y) * rowBytes;

        for (int x = 0; x < width; ++x) {
            PL_CHECK_EQ(row[x * 4 + 0] == 255, 1);   // a
            PL_CHECK_EQ(row[x * 4 + 1] == 255, 1);   // r
            PL_CHECK_EQ(row[x * 4 + 2] == 0, 1);     // g
        }

        // THE PADDING MUST BE UNTOUCHED. Writing into it is how an effect corrupts the
        // next row of a world it does not own, and at 8 bpc with a tight destination it
        // would still produce a correct-looking picture.
        for (int k = 0; k < padBytes; ++k) {
            PL_CHECK_EQ(row[width * 4 + k] == 0xAB, 1);
        }
    }
}

// A ZERO-SIZED OR NULL DESTINATION IS A NO-OP, NOT A CRASH. AE asks for odd rects, and
// the one thing an effect must not do on the render path is fault inside the host.
PL_TEST(AnInvalidDestinationIsRefusedRatherThanWritten) {
    std::vector<float> staging(16, 1.0f);

    ImageView none;
    convertStagingFrame(staging.data(), none);      // no data, zero size

    uint8_t one[4] = { 1, 2, 3, 4 };
    ImageView view;
    view.data     = one;
    view.width    = 0;                              // AE can ask for this
    view.height   = 1;
    view.rowBytes = 4;
    view.format   = PixelFormat::ARGB8;
    convertStagingFrame(staging.data(), view);

    PL_CHECK_EQ(one[0] == 1, 1);
    PL_CHECK_EQ(one[3] == 4, 1);

    // ...and a null source with a valid destination, which is the same mistake the other
    // way round.
    view.width = 1;
    convertStagingFrame(nullptr, view);
    PL_CHECK_EQ(one[0] == 1, 1);
}

// ---------------------------------------------------------------------------
// Against the reader
// ---------------------------------------------------------------------------

// THE TWO HALVES OF Image.h's RANGE AGREE, which is worth pinning because they are
// separate code: readPixel divides by kMaxChan16 through a reciprocal multiply, and this
// file multiplies by it. A round trip through both must come back where it started, and
// if either had 65535 in it the error would be a clean factor of two.
//
// ALPHA ONLY, because colour goes through the transfer curve on the way out and readPixel
// has no inverse for it -- which is itself the reason this check is about the range and
// not about the picture.
PL_TEST(AlphaSurvivesARoundTripThroughBothFormats) {
    const float values[] = { 0.0f, 0.25f, 0.5f, 0.75f, 1.0f };

    for (float v : values) {
        uint16_t buf16[4] = { 0, 0, 0, 0 };
        writeConverted(buf16, PixelFormat::ARGB16, v, 0.0f, 0.0f, 0.0f);

        ImageView view16;
        view16.data = buf16; view16.width = 1; view16.height = 1;
        view16.rowBytes = 8; view16.format = PixelFormat::ARGB16;

        PL_CHECK_NEAR(readPixel(view16, 0, 0).a, static_cast<double>(v), 1.0 / 32768.0);

        uint8_t buf8[4] = { 0, 0, 0, 0 };
        writeConverted(buf8, PixelFormat::ARGB8, v, 0.0f, 0.0f, 0.0f);

        ImageView view8;
        view8.data = buf8; view8.width = 1; view8.height = 1;
        view8.rowBytes = 4; view8.format = PixelFormat::ARGB8;

        PL_CHECK_NEAR(readPixel(view8, 0, 0).a, static_cast<double>(v), 1.0 / 255.0);
    }
}
// ---------------------------------------------------------------------------
// The quantiser over its whole domain
// ---------------------------------------------------------------------------

// ===========================================================================
// THIS USED TO ASSERT THE REFACTOR WAS BIT-IDENTICAL TO THE SMART-RENDER LOOP IT
// REPLACED, AND THAT CLAIM IS NOW DELIBERATELY FALSE.
//
// It was worth having: the loop lived in the one function that cannot run without After
// Effects, so moving it had no safety net, and the sweep showed 16,440 conversions
// agreeing to the byte. It caught nothing, because there was nothing to catch.
//
// The loop applied an sRGB curve. This no longer does -- the curve moved to
// applyOutputTransform(), because applying it HERE is what made 8 and 16 bpc disagree
// with 32 bpc, and that was a real bug measured in the host. So the old behaviour is
// what is now wrong, and asserting equality with it would be asserting the bug.
//
// WHAT WAS WORTH KEEPING IS THE SWEEP, not the thing it was comparing against. The
// quantiser is now exactly a clamp, a scale and a round, and that is a claim with a
// closed form -- so it can be checked over its whole domain against the arithmetic
// rather than against an older implementation of itself.
//
// AND THE OLD VERSION'S REAL LESSON SURVIVES IT. "Bit-identical over 16,440 conversions"
// was a true statement about the inputs that occur and said nothing about the ones that
// do not -- which is how toImageView's unreachable default case shipped a sixteen-byte
// write into a four-byte pixel. An exhaustive-looking sweep is still a sweep of a domain
// somebody chose.
// ===========================================================================
PL_TEST(TheQuantiserIsExactlyClampScaleAndRound) {
    int compared = 0, mismatches = 0;

    float    firstValue   = 0.0f;
    bool     firstSixteen = false;
    int      firstChannel = -1;
    unsigned firstGot = 0, firstWant = 0;

    // 4097 steps across 0..1 straddles every 8-bit rounding boundary several times, and
    // the explicit list adds what a uniform sweep steps over: the ends, the HDR values
    // that must clamp, and the negatives that must not wrap.
    std::vector<float> probes;
    for (int i = 0; i <= 4096; ++i) probes.push_back(static_cast<float>(i) / 4096.0f);
    for (float v : { -1e9f, -1.0f, -1e-8f, 0.0f, 1e-8f, 0.5f,
                     1.0f - 1e-7f, 1.0f, 1.0f + 1e-7f, 2.0f, 40.0f, 1e9f }) {
        probes.push_back(v);
    }

    for (float v : probes) {
        for (int pass = 0; pass < 2; ++pass) {
            const bool  sixteen = (pass == 1);
            const float scale   = sixteen ? 32768.0f : 255.0f;

            // THE SAME VALUE IN ALL FOUR CHANNELS AND THEN ROTATED, so a channel ORDER
            // mistake cannot hide behind four equal numbers -- which is exactly how an
            // ARGB/RGBA slip survives a grey test image.
            const float quads[2][4] = {
                { v, v, v, v },
                { v, 1.0f - v, 0.5f, 0.0f },
            };

            for (const auto& q : quads) {
                unsigned got[4] = { 0, 0, 0, 0 };
                if (sixteen) {
                    uint16_t p[4] = { 0, 0, 0, 0 };
                    writeConverted(p, PixelFormat::ARGB16, q[0], q[1], q[2], q[3]);
                    for (int c = 0; c < 4; ++c) got[c] = p[c];
                } else {
                    uint8_t p[4] = { 0, 0, 0, 0 };
                    writeConverted(p, PixelFormat::ARGB8, q[0], q[1], q[2], q[3]);
                    for (int c = 0; c < 4; ++c) got[c] = p[c];
                }

                for (int c = 0; c < 4; ++c) {
                    float x = q[c];
                    x = x < 0.0f ? 0.0f : (x > 1.0f ? 1.0f : x);
                    const unsigned want = static_cast<unsigned>(x * scale + 0.5f);

                    if (got[c] != want && mismatches++ == 0) {
                        firstValue   = q[c];
                        firstSixteen = sixteen;
                        firstChannel = c;
                        firstGot     = got[c];
                        firstWant    = want;
                    }
                }
                ++compared;
            }
        }
    }

    // ONE ASSERTION AFTER THE SWEEP, NOT ONE INSIDE IT, and that is a lesson from
    // watching an earlier version fail: an injected 65535 made it report sixteen thousand
    // times and buried every other failure in the run, including the two that named the
    // actual bug. A sweep should say WHAT disagreed once.
    if (mismatches > 0) {
        std::printf("      %d of %d channels are not a plain clamp-scale-round.\n"
                    "      first: %s channel %d of input %.9g -- got %u, wanted %u\n",
                    mismatches, compared * 4, firstSixteen ? "16 bpc" : "8 bpc",
                    firstChannel, static_cast<double>(firstValue), firstGot, firstWant);
    }
    PL_CHECK_EQ(mismatches == 0, 1);

    // A SWEEP THAT COMPARED NOTHING WOULD PASS SILENTLY, which is the failure mode of
    // every loop-driven test.
    PL_CHECK(compared > 16000);
}
