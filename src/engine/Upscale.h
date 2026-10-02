#pragma once

// DRAFT'S HALF-RESOLUTION PICTURE, SCALED BACK UP (build 26).
//
// At QualityParams::pixelStride s the renderer traces one path per s x s block of the
// destination, into a buffer 1/s the size. The caller denoises it THERE -- OIDN on a quarter
// of the pixels, and a cleaner input for the scale-up -- and then this fills the buffer the
// host asked for. In LINEAR radiance, before the output transform, for the reason the
// denoise blend is: interpolating after the transfer curve would darken every edge.
//
// BILINEAR BETWEEN BLOCK CENTRES, CLAMPED AT THE EDGES. Source pixel (i, j) is the block of
// destination pixels [i*s, (i+1)*s) x [j*s, (j+1)*s), so its centre sits at (i + 0.5) * s;
// a destination pixel centre (x + 0.5) therefore reads the source at (x + 0.5) / s - 0.5.
// The block grid starts at the destination's own pixel (0, 0), which is what the kernel's
// seed and ray assume -- see primaryRayDirection.
//
// No host headers, so tests/unit/ checks it without the SDK.

#include <algorithm>
#include <cstddef>

namespace plugin::cloud {

// The width (or height) of the buffer a render at `stride` writes for a destination
// `extent` pixels across: every destination pixel inside some block.
inline int strideExtent(int extent, int stride) {
    if (stride <= 1 || extent <= 0) return extent;
    return (extent + stride - 1) / stride;
}

// Four floats a pixel in both buffers, pitches in pixels. stride 1 is a straight copy.
inline void upscaleFromStride(const float* src, int srcW, int srcH, int srcPitchPx,
                              float* dst, int dstW, int dstH, int dstPitchPx, int stride) {
    if (!src || !dst || srcW <= 0 || srcH <= 0 || dstW <= 0 || dstH <= 0) return;

    if (stride <= 1) {
        const int w = std::min(srcW, dstW), h = std::min(srcH, dstH);
        for (int y = 0; y < h; ++y) {
            std::copy(src + static_cast<size_t>(y) * srcPitchPx * 4,
                      src + static_cast<size_t>(y) * srcPitchPx * 4 + static_cast<size_t>(w) * 4,
                      dst + static_cast<size_t>(y) * dstPitchPx * 4);
        }
        return;
    }

    const float inv = 1.0f / static_cast<float>(stride);
    const auto at = [](float u, int n, int& i0, int& i1, float& f) {
        if (u < 0.0f) u = 0.0f;
        const float top = static_cast<float>(n - 1);
        if (u > top) u = top;
        i0 = static_cast<int>(u);
        i1 = i0 + 1 < n ? i0 + 1 : i0;
        f  = u - static_cast<float>(i0);
    };

    for (int y = 0; y < dstH; ++y) {
        int j0, j1; float fy;
        at((static_cast<float>(y) + 0.5f) * inv - 0.5f, srcH, j0, j1, fy);
        const float* r0 = src + static_cast<size_t>(j0) * srcPitchPx * 4;
        const float* r1 = src + static_cast<size_t>(j1) * srcPitchPx * 4;
        float* out = dst + static_cast<size_t>(y) * dstPitchPx * 4;

        for (int x = 0; x < dstW; ++x) {
            int i0, i1; float fx;
            at((static_cast<float>(x) + 0.5f) * inv - 0.5f, srcW, i0, i1, fx);
            const float* a = r0 + i0 * 4;
            const float* b = r0 + i1 * 4;
            const float* c = r1 + i0 * 4;
            const float* d = r1 + i1 * 4;
            for (int k = 0; k < 4; ++k) {
                const float top    = a[k] + (b[k] - a[k]) * fx;
                const float bottom = c[k] + (d[k] - c[k]) * fx;
                out[x * 4 + k] = top + (bottom - top) * fy;
            }
        }
    }
}

} // namespace plugin::cloud
