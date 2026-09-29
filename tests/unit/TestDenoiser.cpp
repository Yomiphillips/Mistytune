// The denoiser, and mostly the case where there is no denoiser.
//
// ===========================================================================
// THE TESTS THAT MATTER MOST HERE RUN WITHOUT OIDN INSTALLED, which is the opposite of
// where the attention would naturally go.
//
// PLAN.md requires the integration to degrade to "no denoise" rather than to an effect
// that will not load, and bundling the DLLs makes that path RARER, not unnecessary: a
// user who prunes the install folder, or an antivirus that quarantines one file of the
// set, lands on it. That path is also the one nobody exercises by accident, because
// every developer machine has the library -- so it is the one that rots.
//
// So the refusal cases are asserted unconditionally and the denoising cases skip when
// the library is absent. That is the same split cmake/SlangCheckRegenerated.cmake
// makes and for the same reason: skipping is honest when the input genuinely cannot be
// produced, and dishonest when it can.
//
// WHAT IS *NOT* TESTED HERE, AND CANNOT BE. Whether the denoised picture looks right,
// and whether it flickers across frames. OIDN is not temporal, and per-frame denoising
// of a stochastic image is how animation gets shimmer -- PLAN.md is explicit that this
// is judged on a moving 48-frame render and never on a still. No unit test can stand
// in for that.
// ===========================================================================

#include "TestFramework.h"

#include "Denoiser.h"

#include <cmath>
#include <vector>

using namespace plugin;

namespace {

// A frame of four-float pixels with a known, checkable pattern in it.
struct Frame {
    std::vector<float> data;
    int w = 0, h = 0, pitch = 0;

    Frame(int width, int height, int pitchPx)
        : data(static_cast<size_t>(pitchPx) * height * 4, 0.0f),
          w(width), h(height), pitch(pitchPx) {}

    float* at(int x, int y) {
        return data.data() + (static_cast<size_t>(y) * pitch + x) * 4;
    }
    const float* at(int x, int y) const {
        return data.data() + (static_cast<size_t>(y) * pitch + x) * 4;
    }

    cloud::DenoiseImage image(cloud::DenoiseOrder order) {
        cloud::DenoiseImage img;
        img.data = data.data();
        img.widthPx = w;
        img.heightPx = h;
        img.pitchPx = pitch;
        img.order = order;
        return img;
    }
};

// A deterministic value in [0,1), so a "noisy" image is the same noise every run.
float hashUnit(int x, int y, int c) {
    unsigned int h = static_cast<unsigned int>(x) * 374761393u +
                     static_cast<unsigned int>(y) * 668265263u +
                     static_cast<unsigned int>(c) * 2246822519u;
    h = (h ^ (h >> 13)) * 1274126177u;
    h ^= h >> 16;
    return static_cast<float>(h & 0xffffffu) / 16777216.0f;
}

void writePixel(float* p, bool bgra, float r, float g, float b, float a) {
    if (bgra) { p[0] = b; p[1] = g; p[2] = r; p[3] = a; }
    else      { p[0] = a; p[1] = r; p[2] = g; p[3] = b; }
}

void readPixel(const float* p, bool bgra, float& r, float& g, float& b, float& a) {
    if (bgra) { b = p[0]; g = p[1]; r = p[2]; a = p[3]; }
    else      { a = p[0]; r = p[1]; g = p[2]; b = p[3]; }
}

} // namespace

// ---------------------------------------------------------------------------
// The description is always answerable
// ---------------------------------------------------------------------------

// A DIAGNOSTIC LINE THAT CRASHES IS WORSE THAN NO DIAGNOSTIC LINE, and this one is
// called from the effect's log before any render has happened.
PL_TEST(TheDescriptionIsNeverNullWhetherOrNotThereIsALibrary) {
    const char* d = cloud::denoiserDescription();
    PL_CHECK(d != nullptr);
    PL_CHECK(d[0] != '\0');
}

PL_TEST(AvailabilityIsStableAcrossCalls) {
    // Cached, including the negative answer -- a machine without OIDN must not pay a
    // failed library load per frame.
    const bool a = cloud::denoiserAvailable();
    const bool b = cloud::denoiserAvailable();
    PL_CHECK_EQ(a, b);
}

// ---------------------------------------------------------------------------
// Refusals, which must be refusals and not crashes
// ---------------------------------------------------------------------------

PL_TEST(ANullBufferIsRefusedRatherThanDereferenced) {
    cloud::DenoiseImage img;
    img.data = nullptr;
    img.widthPx = 16; img.heightPx = 16; img.pitchPx = 16;
    PL_CHECK_EQ(cloud::denoiseFrame(img), false);
}

PL_TEST(AnEmptyOrNegativeGeometryIsRefused) {
    Frame f(4, 4, 4);

    cloud::DenoiseImage img = f.image(cloud::DenoiseOrder::ArgbFloat4);
    img.widthPx = 0;
    PL_CHECK_EQ(cloud::denoiseFrame(img), false);

    img = f.image(cloud::DenoiseOrder::ArgbFloat4);
    img.heightPx = -1;
    PL_CHECK_EQ(cloud::denoiseFrame(img), false);
}

// A PITCH NARROWER THAN THE WIDTH IS THE ONE THAT WOULD READ PAST THE ROW rather than
// simply do nothing, so it is refused explicitly rather than left to arithmetic.
PL_TEST(APitchNarrowerThanTheWidthIsRefusedRatherThanOverrun) {
    Frame f(8, 8, 8);
    cloud::DenoiseImage img = f.image(cloud::DenoiseOrder::ArgbFloat4);
    img.pitchPx = 4;
    PL_CHECK_EQ(cloud::denoiseFrame(img), false);
}

// THE CONTRACT THE CALLER RELIES ON: a refusal leaves the picture alone, so "no
// denoiser" is the undenoised render rather than a black or half-written frame.
PL_TEST(ARefusedFrameIsLeftExactlyAsItWas) {
    Frame f(8, 8, 8);
    for (int y = 0; y < 8; ++y)
        for (int x = 0; x < 8; ++x)
            writePixel(f.at(x, y), false,
                       hashUnit(x, y, 0), hashUnit(x, y, 1), hashUnit(x, y, 2), 1.0f);

    const std::vector<float> before = f.data;

    cloud::DenoiseImage img = f.image(cloud::DenoiseOrder::ArgbFloat4);
    img.pitchPx = 1;                       // refused
    PL_CHECK_EQ(cloud::denoiseFrame(img), false);

    for (size_t i = 0; i < before.size(); ++i) PL_CHECK_EQ(f.data[i], before[i]);
}

// ---------------------------------------------------------------------------
// With a library present
// ---------------------------------------------------------------------------

// ALPHA IS COVERAGE, NOT LIGHT -- the same rule OutputConvert.h and
// applyOutputTransform follow. The denoiser is given three channels and must not
// disturb the fourth, whichever slot it happens to sit in.
PL_TEST(AlphaSurvivesTheDenoiseInBothChannelOrders) {
    if (!cloud::denoiserAvailable()) {
        std::printf("      no OpenImageDenoise -- skipping (%s)\n",
                    cloud::denoiserDescription());
        return;
    }

    for (int pass = 0; pass < 2; ++pass) {
        const bool bgra = (pass == 1);
        const cloud::DenoiseOrder order = bgra ? cloud::DenoiseOrder::BgraFloat4
                                               : cloud::DenoiseOrder::ArgbFloat4;
        Frame f(32, 32, 32);
        for (int y = 0; y < 32; ++y) {
            for (int x = 0; x < 32; ++x) {
                // A distinct alpha per pixel, so a shuffle shows up as well as a wipe.
                writePixel(f.at(x, y), bgra,
                           hashUnit(x, y, 0), hashUnit(x, y, 1), hashUnit(x, y, 2),
                           hashUnit(x, y, 3));
            }
        }
        std::vector<float> alphaBefore;
        for (int y = 0; y < 32; ++y)
            for (int x = 0; x < 32; ++x)
                alphaBefore.push_back(bgra ? f.at(x, y)[3] : f.at(x, y)[0]);

        cloud::DenoiseImage img = f.image(order);
        PL_CHECK_EQ(cloud::denoiseFrame(img), true);

        size_t i = 0;
        for (int y = 0; y < 32; ++y)
            for (int x = 0; x < 32; ++x, ++i)
                PL_CHECK_EQ(bgra ? f.at(x, y)[3] : f.at(x, y)[0], alphaBefore[i]);
    }
}

// ===========================================================================
// THE CHANNEL-ORDER TEST, AND IT IS THE ONE WORTH THE MOST.
//
// OIDN's FLOAT3 reads three CONSECUTIVE floats; there is no per-channel offset. ARGB
// happens to put R,G,B consecutively and BGRA stores them REVERSED, so the packing
// step in Denoiser.cpp is the only thing standing between a BGRA render and a network
// fed B,G,R.
//
// THAT FAILURE WOULD LOOK ALMOST RIGHT. The RT filter would still smooth the image --
// it would simply denoise using the colour statistics of a differently-coloured
// picture, and the result is a subtly wrong hue in the noisy regions. Nothing about it
// says "channel order". After Effects hands out BGRA worlds, so it is the host path
// that would carry the bug while the CLI stayed clean.
//
// SO THE TEST IS AN EQUIVALENCE: the same colours, laid out both ways, must come back
// the same colours. It needs to know nothing about what the denoiser does.
// ===========================================================================
PL_TEST(TheSameImageDenoisesIdenticallyInBothChannelOrders) {
    if (!cloud::denoiserAvailable()) {
        std::printf("      no OpenImageDenoise -- skipping (%s)\n",
                    cloud::denoiserDescription());
        return;
    }

    const int w = 48, h = 32;
    Frame argb(w, h, w);
    Frame bgra(w, h, w);

    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            // Structure plus noise, in HDR range -- a gradient with a bright core, so
            // the filter has something to preserve as well as something to remove.
            const float base = 0.2f + 3.0f * std::exp(-0.01f *
                static_cast<float>((x - w / 2) * (x - w / 2) + (y - h / 2) * (y - h / 2)));
            const float r = base * (0.6f + 0.8f * hashUnit(x, y, 0));
            const float g = base * (0.5f + 0.8f * hashUnit(x, y, 1));
            const float b = base * (0.9f + 0.8f * hashUnit(x, y, 2));
            writePixel(argb.at(x, y), false, r, g, b, 1.0f);
            writePixel(bgra.at(x, y), true,  r, g, b, 1.0f);
        }
    }

    cloud::DenoiseImage ia = argb.image(cloud::DenoiseOrder::ArgbFloat4);
    cloud::DenoiseImage ib = bgra.image(cloud::DenoiseOrder::BgraFloat4);
    PL_CHECK_EQ(cloud::denoiseFrame(ia), true);
    PL_CHECK_EQ(cloud::denoiseFrame(ib), true);

    PL_SWEEP(sweep, "ARGB vs BGRA denoised channels");
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            float ra, ga, ba, aa, rb, gb, bb, ab;
            readPixel(argb.at(x, y), false, ra, ga, ba, aa);
            readPixel(bgra.at(x, y), true,  rb, gb, bb, ab);
            // BIT-EXACT, not near. Both went through the same filter with the same
            // numbers; only the pack differs, and a pack cannot round.
            sweep.require(ra == rb && ga == gb && ba == bb,
                          static_cast<double>(y * w + x));
        }
    }
    sweep.finish(w * h);
}

// ===========================================================================
// A UNIFORM IMAGE HAS NOTHING TO DENOISE, SO THE INTERIOR MUST COME BACK UNCHANGED.
//
// This is the cheapest check that the pack, the filter and the unpack are wired to the
// same pixels: a transposed or offset unpack shows up as structure appearing out of a
// flat field, everywhere at once.
//
// THE MARGIN IS NOT A FUDGE, IT IS A MEASURED PROPERTY OF THE FILTER. RT does not
// reproduce a flat field exactly at the image CORNERS, because a convolutional network
// has to invent something outside the frame and a corner is short of context on two
// sides at once. Measured here, on a flat 0.25 / 0.50 / 0.75:
//
//     40 x 24    35 of 960 pixels off by more than 0.02, worst 0.135 at (39,23)
//     160 x 96   15 of 15360,                            worst 0.095 at (159,0)
//
// It is a fixed band rather than a fraction -- the count barely moved while the area
// grew sixteen times -- so it shrinks to nothing on a real frame and is invisible at
// 1920x1080. A wiring error would not behave like that: it would scale with the image.
//
// SO THE TEST ASSERTS THE INTERIOR STRICTLY and leaves the border to the numbers above.
// Tightening it to the whole frame would be asserting something about OIDN that OIDN
// does not promise, and the failure would arrive as a mystery on the day someone
// changed the filter type.
// ===========================================================================
PL_TEST(AUniformImageComesBackUniformInTheInterior) {
    if (!cloud::denoiserAvailable()) {
        std::printf("      no OpenImageDenoise -- skipping (%s)\n",
                    cloud::denoiserDescription());
        return;
    }

    const int w = 160, h = 96;
    const int margin = 8;
    Frame f(w, h, w + 3);          // a pitch WIDER than the width, deliberately
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
            writePixel(f.at(x, y), false, 0.25f, 0.5f, 0.75f, 1.0f);

    cloud::DenoiseImage img = f.image(cloud::DenoiseOrder::ArgbFloat4);
    PL_CHECK_EQ(cloud::denoiseFrame(img), true);

    PL_SWEEP(sweep, "uniform image interior after denoise");
    for (int y = margin; y < h - margin; ++y) {
        for (int x = margin; x < w - margin; ++x) {
            float r, g, b, a;
            readPixel(f.at(x, y), false, r, g, b, a);
            sweep.require(std::fabs(r - 0.25f) < 0.02f &&
                          std::fabs(g - 0.50f) < 0.02f &&
                          std::fabs(b - 0.75f) < 0.02f,
                          static_cast<double>(y * w + x));
        }
    }
    sweep.finish((w - 2 * margin) * (h - 2 * margin));
}

// THE PADDING BETWEEN ROWS MUST NOT BE TOUCHED. A destination is routinely a WINDOW
// into a larger buffer -- an AE world with its own rowbytes, or a CUDA band -- so a
// denoise that wrote pitch-width rows instead of width-width rows would corrupt
// whatever sits in the margin. That is the band-as-window mistake this project has
// already made three times, arriving in a new file.
PL_TEST(TheRowPaddingOutsideTheImageIsLeftAlone) {
    if (!cloud::denoiserAvailable()) {
        std::printf("      no OpenImageDenoise -- skipping (%s)\n",
                    cloud::denoiserDescription());
        return;
    }

    const int w = 16, h = 8, pitch = 24;
    Frame f(w, h, pitch);

    const float kSentinel = -12345.0f;
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < pitch; ++x) {
            float* p = f.data.data() + (static_cast<size_t>(y) * pitch + x) * 4;
            if (x < w) writePixel(p, false, hashUnit(x, y, 0), hashUnit(x, y, 1),
                                  hashUnit(x, y, 2), 1.0f);
            else       { p[0] = p[1] = p[2] = p[3] = kSentinel; }
        }
    }

    cloud::DenoiseImage img = f.image(cloud::DenoiseOrder::ArgbFloat4);
    PL_CHECK_EQ(cloud::denoiseFrame(img), true);

    PL_SWEEP(sweep, "row padding");
    for (int y = 0; y < h; ++y) {
        for (int x = w; x < pitch; ++x) {
            const float* p = f.data.data() + (static_cast<size_t>(y) * pitch + x) * 4;
            sweep.require(p[0] == kSentinel && p[1] == kSentinel &&
                          p[2] == kSentinel && p[3] == kSentinel,
                          static_cast<double>(y * pitch + x));
        }
    }
    sweep.finish(h * (pitch - w));
}

// SHUTDOWN IS IDEMPOTENT AND A DENOISE STILL WORKS AFTERWARDS. It is called from
// PF_Cmd_GPU_DEVICE_SETDOWN, which AE may issue between renders rather than at the end
// of the session -- so a session that could not be rebuilt would turn one setdown into
// a permanently undenoised effect.
PL_TEST(ShutdownCanBeCalledTwiceAndTheNextDenoiseStillWorks) {
    cloud::denoiserShutdown();
    cloud::denoiserShutdown();

    if (!cloud::denoiserAvailable()) return;

    Frame f(16, 16, 16);
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 16; ++x)
            writePixel(f.at(x, y), false, hashUnit(x, y, 0), hashUnit(x, y, 1),
                       hashUnit(x, y, 2), 1.0f);

    cloud::DenoiseImage img = f.image(cloud::DenoiseOrder::ArgbFloat4);
    PL_CHECK_EQ(cloud::denoiseFrame(img), true);
    cloud::denoiserShutdown();
}

// ===========================================================================
// DOES THE FILTER CARE WHAT SCALE ITS INPUT IS AT? Measured, because two comments in
// this repository disagreed about it and the answer decides the resolve order.
//
// src/engine/FieldCache.h argued that exposure must reach the denoiser -- "OIDN is
// trained on roughly perceptual magnitudes, so the exposure has to be in the numbers
// before the denoiser sees them, or denoise strength silently tracks the exposure
// slider" -- and fixed the resolve as mean -> exposure -> DENOISE -> tonemap -> encode.
// src/kernel/Shading.h, KernelApi.h and Mistytune.cpp all say the shorter thing:
// render (LINEAR) -> denoise -> output transform.
//
// THE DIFFERENCE IS A WHOLE EXTRA FULL-FRAME PASS. If the filter is scale-invariant the
// transform stays one pass; if it is not, exposure has to be lifted out of it and run
// separately, at about 5 ms a frame at 1080p.
//
// THE TEST: denoise x, and denoise k*x, then divide the second by k. If the filter
// normalises its input -- OIDN 2.x computes an hdrScale when none is given -- the two
// agree and exposure can stay where it is.
// ===========================================================================
PL_TEST(TheHdrFilterIsScaleInvariantSoExposureNeedNotPrecedeIt) {
    if (!cloud::denoiserAvailable()) {
        std::printf("      no OpenImageDenoise -- skipping (%s)\n",
                    cloud::denoiserDescription());
        return;
    }

    const int w = 96, h = 64;
    const float k = 8.0f;          // three stops

    Frame plain(w, h, w);
    Frame scaled(w, h, w);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const float base = 0.15f + 2.5f * std::exp(-0.004f *
                static_cast<float>((x - w / 2) * (x - w / 2) + (y - h / 2) * (y - h / 2)));
            const float r = base * (0.6f + 0.8f * hashUnit(x, y, 0));
            const float g = base * (0.5f + 0.8f * hashUnit(x, y, 1));
            const float b = base * (0.9f + 0.8f * hashUnit(x, y, 2));
            writePixel(plain.at(x, y),  false, r, g, b, 1.0f);
            writePixel(scaled.at(x, y), false, r * k, g * k, b * k, 1.0f);
        }
    }

    cloud::DenoiseImage ip = plain.image(cloud::DenoiseOrder::ArgbFloat4);
    cloud::DenoiseImage is = scaled.image(cloud::DenoiseOrder::ArgbFloat4);
    PL_CHECK_EQ(cloud::denoiseFrame(ip), true);
    PL_CHECK_EQ(cloud::denoiseFrame(is), true);

    // Relative difference, interior only -- the corner behaviour above is not what
    // this is measuring.
    const int margin = 8;
    double worstRel = 0.0;
    for (int y = margin; y < h - margin; ++y) {
        for (int x = margin; x < w - margin; ++x) {
            float r1, g1, b1, a1, r2, g2, b2, a2;
            readPixel(plain.at(x, y),  false, r1, g1, b1, a1);
            readPixel(scaled.at(x, y), false, r2, g2, b2, a2);
            const float c1[3] = { r1, g1, b1 };
            const float c2[3] = { r2 / k, g2 / k, b2 / k };
            for (int c = 0; c < 3; ++c) {
                const double denom = std::fabs(c1[c]) > 1e-4 ? std::fabs(c1[c]) : 1e-4;
                const double rel = std::fabs(c1[c] - c2[c]) / denom;
                if (rel > worstRel) worstRel = rel;
            }
        }
    }

    std::printf("      worst relative difference across %g x exposure: %.4f\n",
                static_cast<double>(k), worstRel);

    // 2% ALLOWS FOR THE FILTER'S OWN AUTOEXPOSURE LANDING ON A SLIGHTLY DIFFERENT
    // INTERNAL SCALE, which is a rounding difference rather than a different answer.
    // A filter that genuinely denoised harder at one exposure would be nowhere near it.
    PL_CHECK(worstRel < 0.02);
}

// ===========================================================================
// THE BLEND, WHICH IS WHAT "DENOISE AMOUNT" IS.
//
// OIDN's RT filter has no strength of its own, so the slider is a lerp between the raw
// render and the filtered one. It exists because the filter measurably OVERSHOOTS on
// this content: at 4 spp, against a 512-spp render of the same frame, a full denoise
// leaves 33% of the fine structure the converged image has.
//
// THE ENDPOINTS ARE WHAT A TEST CAN PIN. Whether 0.8 is the right default is a
// judgement about pictures; whether 0 is the identity and 1 is the full filter is
// arithmetic, and it is the arithmetic that would break silently.
// ===========================================================================
PL_TEST(AnAmountOfZeroLeavesTheImageExactlyAsItWas) {
    Frame f(32, 32, 32);
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 32; ++x)
            writePixel(f.at(x, y), false, hashUnit(x, y, 0), hashUnit(x, y, 1),
                       hashUnit(x, y, 2), 1.0f);

    const std::vector<float> before = f.data;

    cloud::DenoiseImage img = f.image(cloud::DenoiseOrder::ArgbFloat4);
    img.amount = 0.0f;

    // FALSE, because nothing was denoised -- and the filter is skipped entirely rather
    // than run and thrown away.
    PL_CHECK_EQ(cloud::denoiseFrame(img), false);

    PL_SWEEP(sweep, "pixels at amount 0");
    for (size_t i = 0; i < before.size(); ++i) sweep.require(f.data[i] == before[i],
                                                             static_cast<double>(i));
    sweep.finish(static_cast<int>(before.size()));
}

PL_TEST(AnAmountOfAHalfLandsHalfwayBetweenRawAndFullyDenoised) {
    if (!cloud::denoiserAvailable()) {
        std::printf("      no OpenImageDenoise -- skipping (%s)\n",
                    cloud::denoiserDescription());
        return;
    }

    const int w = 64, h = 48;
    Frame raw(w, h, w), full(w, h, w), half(w, h, w);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const float base = 0.2f + 2.0f * std::exp(-0.006f *
                static_cast<float>((x - w / 2) * (x - w / 2) + (y - h / 2) * (y - h / 2)));
            const float r = base * (0.6f + 0.8f * hashUnit(x, y, 0));
            const float g = base * (0.5f + 0.8f * hashUnit(x, y, 1));
            const float b = base * (0.9f + 0.8f * hashUnit(x, y, 2));
            writePixel(raw.at(x, y),  false, r, g, b, 1.0f);
            writePixel(full.at(x, y), false, r, g, b, 1.0f);
            writePixel(half.at(x, y), false, r, g, b, 1.0f);
        }
    }

    cloud::DenoiseImage fi = full.image(cloud::DenoiseOrder::ArgbFloat4);
    fi.amount = 1.0f;
    PL_CHECK_EQ(cloud::denoiseFrame(fi), true);

    cloud::DenoiseImage hi = half.image(cloud::DenoiseOrder::ArgbFloat4);
    hi.amount = 0.5f;
    PL_CHECK_EQ(cloud::denoiseFrame(hi), true);

    // EXACTLY THE MIDPOINT, to a float epsilon. The filter is deterministic, so the
    // only thing between these three buffers is the lerp -- and a lerp that had picked
    // up the encode, or blended the wrong pair, would not land here.
    PL_SWEEP(sweep, "half-amount pixels against the midpoint of raw and full");
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            for (int c = 1; c < 4; ++c) {
                const float want = raw.at(x, y)[c] +
                                   (full.at(x, y)[c] - raw.at(x, y)[c]) * 0.5f;
                sweep.check(half.at(x, y)[c], want, 1e-5,
                            static_cast<double>(y * w + x));
            }
        }
    }
    sweep.finish(w * h * 3);
}

// THE SLIDER IS THE ONLY THING THAT MOVES. An amount below 1 must not change WHICH
// pixels the filter looked at, only how much of its answer is kept -- so alpha stays
// untouched at every amount, not just at 1.
PL_TEST(TheBlendLeavesAlphaAloneAtEveryAmount) {
    if (!cloud::denoiserAvailable()) return;

    for (float amt : { 0.25f, 0.5f, 0.8f, 1.0f }) {
        Frame f(32, 32, 32);
        for (int y = 0; y < 32; ++y)
            for (int x = 0; x < 32; ++x)
                writePixel(f.at(x, y), true, hashUnit(x, y, 0), hashUnit(x, y, 1),
                           hashUnit(x, y, 2), hashUnit(x, y, 3));

        std::vector<float> alphaBefore;
        for (int y = 0; y < 32; ++y)
            for (int x = 0; x < 32; ++x) alphaBefore.push_back(f.at(x, y)[3]);

        cloud::DenoiseImage img = f.image(cloud::DenoiseOrder::BgraFloat4);
        img.amount = amt;
        PL_CHECK_EQ(cloud::denoiseFrame(img), true);

        size_t i = 0;
        for (int y = 0; y < 32; ++y)
            for (int x = 0; x < 32; ++x, ++i)
                PL_CHECK_EQ(f.at(x, y)[3], alphaBefore[i]);
    }
}
