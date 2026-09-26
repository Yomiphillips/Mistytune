#pragma once

// Pixel buffer views.
//
// Non-owning views over memory the host allocates, so the engine never has to
// know about PF_EffectWorld. The AE layer wraps a world in one of these and
// passes it down (see src/ae/AEBridge.h).
//
// Channel order is A, R, G, B in memory, matching AE's PF_Pixel structs.
// Pixels are PREMULTIPLIED, as AE effect buffers always are -- compositing
// assumes that and would double-darken edges otherwise.

#include "Types.h"

#include <cstdint>
#include <cstddef>
#include <cstring>

namespace plugin {

enum class PixelFormat {
    ARGB8,     // PF_Pixel8     -- 0..255
    ARGB16,    // PF_Pixel16    -- 0..32768  (NOT 65535, see below)
    ARGB32F    // PF_PixelFloat -- 0..1 nominal, may exceed for HDR
};

// AE's 16-bit channels run 0..32768 inclusive, not 0..65535. Using 65535 here
// makes 16bpc renders come out roughly half as bright, which is subtle enough
// to survive a casual look and is a classic first-plugin bug.
constexpr Scalar kMaxChan8  = 255.0;
constexpr Scalar kMaxChan16 = 32768.0;

// 16-bit converts by RECIPROCAL MULTIPLY, which is exact here and only here:
// 32768 is a power of two, so 1/32768 is representable and x * (1/32768) is
// bit-identical to x / 32768 for every input.
//
// 8-bit CANNOT use that trick -- 1/255 is not representable, and 24 of the 256
// inputs round differently through the multiply than through the divide. A
// table is both exact and faster, and 256 doubles is 2 KB that stays in L1.
constexpr Scalar kInvChan16 = Scalar(1) / kMaxChan16;

struct Chan8Table {
    Scalar v[256];
    constexpr Chan8Table() : v() {
        for (int i = 0; i < 256; ++i) v[i] = Scalar(i) / kMaxChan8;
    }
};
inline constexpr Chan8Table kChan8{};

inline int bytesPerPixel(PixelFormat f) {
    switch (f) {
        case PixelFormat::ARGB8:   return 4;
        case PixelFormat::ARGB16:  return 8;
        case PixelFormat::ARGB32F: return 16;
    }
    return 4;
}

// True for formats whose channels are bounded at 1.0, so rgb > a is provably
// malformed rather than HDR.
inline bool isIntegerFormat(PixelFormat f) {
    return f == PixelFormat::ARGB8 || f == PixelFormat::ARGB16;
}

struct ImageView {
    void*          data = nullptr;
    int            width = 0;
    int            height = 0;
    std::ptrdiff_t rowBytes = 0;
    PixelFormat    format = PixelFormat::ARGB8;

    bool valid() const { return data && width > 0 && height > 0 && rowBytes != 0; }

    template <typename T>
    T* rowPtr(int y) const {
        return reinterpret_cast<T*>(static_cast<uint8_t*>(data) +
                                    static_cast<std::ptrdiff_t>(y) * rowBytes);
    }
};

struct ConstImageView {
    const void*    data = nullptr;
    int            width = 0;
    int            height = 0;
    std::ptrdiff_t rowBytes = 0;
    PixelFormat    format = PixelFormat::ARGB8;

    ConstImageView() = default;
    ConstImageView(const ImageView& v)
        : data(v.data), width(v.width), height(v.height),
          rowBytes(v.rowBytes), format(v.format) {}

    bool valid() const { return data && width > 0 && height > 0 && rowBytes != 0; }

    template <typename T>
    const T* rowPtr(int y) const {
        return reinterpret_cast<const T*>(static_cast<const uint8_t*>(data) +
                                          static_cast<std::ptrdiff_t>(y) * rowBytes);
    }
};

// Premultiplied RGBA in 0..1, regardless of the underlying storage format.
struct Texel {
    Scalar a = 0, r = 0, g = 0, b = 0;
};

PLUGIN_FORCEINLINE Texel readPixel(const ConstImageView& img, int x, int y) {
    Texel t;
    if (x < 0 || y < 0 || x >= img.width || y >= img.height) return t;

    switch (img.format) {
        case PixelFormat::ARGB8: {
            const uint8_t* p = img.rowPtr<uint8_t>(y) + static_cast<std::ptrdiff_t>(x) * 4;
            t.a = kChan8.v[p[0]]; t.r = kChan8.v[p[1]];
            t.g = kChan8.v[p[2]]; t.b = kChan8.v[p[3]];
            break;
        }
        case PixelFormat::ARGB16: {
            const uint16_t* p = img.rowPtr<uint16_t>(y) + static_cast<std::ptrdiff_t>(x) * 4;
            t.a = p[0] * kInvChan16; t.r = p[1] * kInvChan16;
            t.g = p[2] * kInvChan16; t.b = p[3] * kInvChan16;
            break;
        }
        case PixelFormat::ARGB32F: {
            const float* p = img.rowPtr<float>(y) + static_cast<std::ptrdiff_t>(x) * 4;
            t.a = p[0]; t.r = p[1]; t.g = p[2]; t.b = p[3];
            break;
        }
    }
    return t;
}

PLUGIN_FORCEINLINE void writePixel(const ImageView& img, int x, int y, const Texel& t) {
    if (x < 0 || y < 0 || x >= img.width || y >= img.height) return;

    switch (img.format) {
        case PixelFormat::ARGB8: {
            uint8_t* p = img.rowPtr<uint8_t>(y) + static_cast<std::ptrdiff_t>(x) * 4;
            p[0] = static_cast<uint8_t>(clamp01(t.a) * kMaxChan8 + 0.5);
            p[1] = static_cast<uint8_t>(clamp01(t.r) * kMaxChan8 + 0.5);
            p[2] = static_cast<uint8_t>(clamp01(t.g) * kMaxChan8 + 0.5);
            p[3] = static_cast<uint8_t>(clamp01(t.b) * kMaxChan8 + 0.5);
            break;
        }
        case PixelFormat::ARGB16: {
            uint16_t* p = img.rowPtr<uint16_t>(y) + static_cast<std::ptrdiff_t>(x) * 4;
            p[0] = static_cast<uint16_t>(clamp01(t.a) * kMaxChan16 + 0.5);
            p[1] = static_cast<uint16_t>(clamp01(t.r) * kMaxChan16 + 0.5);
            p[2] = static_cast<uint16_t>(clamp01(t.g) * kMaxChan16 + 0.5);
            p[3] = static_cast<uint16_t>(clamp01(t.b) * kMaxChan16 + 0.5);
            break;
        }
        case PixelFormat::ARGB32F: {
            float* p = img.rowPtr<float>(y) + static_cast<std::ptrdiff_t>(x) * 4;
            // 32bpc is allowed to exceed 1.0 -- clamping here would silently
            // destroy HDR values that AE expects to survive an effect.
            p[0] = static_cast<float>(t.a); p[1] = static_cast<float>(t.r);
            p[2] = static_cast<float>(t.g); p[3] = static_cast<float>(t.b);
            break;
        }
    }
}

// Forces a texel back inside the legal premultiplied range, rgb <= a.
//
// rgb > a means the data is NOT premultiplied, whatever it claims, and in a
// premultiplied composite it deposits colour over area it never covered --
// which reads as an over-bright halo along every soft edge.
//
// ONE SCALE FOR ALL THREE CHANNELS, not a per-channel clamp: clamping each
// channel to `a` on its own drags the brightest channel down furthest, so it
// changes the hue as well as the level. Dividing by the largest channel lands
// the pixel on the boundary of the legal range along the line the colour
// already sits on, which is what "clamp the unpremultiplied colour into gamut"
// means when hue is meant to survive it.
//
// NOT for 32-bit float, where rgb > a is legitimate HDR.
PLUGIN_FORCEINLINE void clampPremultiplied(Texel& t) {
    if (t.a <= 0) { t.r = t.g = t.b = 0; return; }
    if (t.r < 0) t.r = 0;
    if (t.g < 0) t.g = 0;
    if (t.b < 0) t.b = 0;

    Scalar peak = t.r;
    if (t.g > peak) peak = t.g;
    if (t.b > peak) peak = t.b;
    if (peak <= t.a) return;          // already legal; the common case

    const Scalar s = t.a / peak;
    t.r *= s; t.g *= s; t.b *= s;
}

inline void clear(const ImageView& img) {
    if (!img.valid()) return;
    const int rowLen = img.width * bytesPerPixel(img.format);
    for (int y = 0; y < img.height; ++y) {
        std::memset(img.rowPtr<uint8_t>(y), 0, static_cast<size_t>(rowLen));
    }
}

} // namespace plugin
