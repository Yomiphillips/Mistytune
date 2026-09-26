#include "Geometry.h"

#include <cstddef>

namespace plugin::sim {

float doubleSignedArea(const Polygon& p) {
    if (p.size() < 3) return 0.0f;

    // Accumulated in double. A comp-sized polygon has coordinates in the
    // thousands, so the products reach millions, and summing those in float
    // loses low-order bits fast enough to matter on a thin shape -- which is
    // precisely where the smallest-ring test needs the precision.
    double sum = 0.0;
    for (size_t i = 0, n = p.size(); i < n; ++i) {
        const Vec2& a = p[i];
        const Vec2& b = p[(i + 1) % n];
        sum += static_cast<double>(a.x) * b.y - static_cast<double>(b.x) * a.y;
    }
    return static_cast<float>(sum);
}

} // namespace plugin::sim
