#pragma once

// Engine basics.
//
// NOTHING in src/engine/ may include an AE SDK header. That is what makes this
// layer unit-testable without launching After Effects, and what makes a future
// host port (Premiere, OFX, standalone) tractable. Host contact belongs in
// src/ae/.

#include <cmath>

// FORCED INLINING FOR PER-PIXEL HELPERS.
//
// `inline` is a linkage keyword, not an instruction, and MSVC routinely
// declines it for exactly the functions that matter -- a pixel read or write
// left as a real CALL inside the innermost loop costs more than the work it
// does. Use this ONLY for leaf helpers on a hot path; everywhere else it
// trades instruction cache for nothing.
#if defined(_MSC_VER)
    #define PLUGIN_FORCEINLINE __forceinline
#elif defined(__GNUC__) || defined(__clang__)
    #define PLUGIN_FORCEINLINE inline __attribute__((always_inline))
#else
    #define PLUGIN_FORCEINLINE inline
#endif

namespace plugin {

// Maths runs in double by default. AE's own A_Matrix4 is double, and any
// transform work carries translations in the thousands of pixels where float
// precision starts to bite. Convert to float at the backend boundary if you
// add one.
using Scalar = double;

PLUGIN_FORCEINLINE Scalar clamp01(Scalar v) {
    return v < 0 ? Scalar(0) : (v > 1 ? Scalar(1) : v);
}

} // namespace plugin
