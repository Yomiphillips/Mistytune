#pragma once

// Minimal test framework.
//
// Hand-rolled rather than vendoring Catch2/doctest: the build stays hermetic
// (no download step, no third-party header in a repo that must not ship
// Adobe's SDK either), and this is ~60 lines against a 2MB header. Swap it for
// doctest the day these tests need fixtures or parameterisation.

#include <cmath>
#include <cstdio>
#include <string>
#include <vector>

namespace pltest {

struct TestCase {
    const char* name;
    void (*fn)();
};

inline std::vector<TestCase>& registry() {
    static std::vector<TestCase> tests;
    return tests;
}

inline int& failures() { static int n = 0; return n; }
inline const char*& currentTest() { static const char* n = ""; return n; }

struct Registrar {
    Registrar(const char* name, void (*fn)()) { registry().push_back({ name, fn }); }
};

inline void reportFailure(const char* file, int line, const std::string& what) {
    ++failures();
    std::printf("  FAIL  %s\n        %s:%d\n        %s\n",
                currentTest(), file, line, what.c_str());
}

inline int runAll() {
    std::printf("Running %zu tests...\n\n", registry().size());
    for (const TestCase& t : registry()) {
        currentTest() = t.name;
        const int before = failures();
        t.fn();
        if (failures() == before) std::printf("  ok    %s\n", t.name);
    }
    std::printf("\n%s  (%d failure%s)\n",
                failures() == 0 ? "PASSED" : "FAILED",
                failures(), failures() == 1 ? "" : "s");
    return failures() == 0 ? 0 : 1;
}

} // namespace pltest

#define PL_TEST(NAME)                                                        \
    static void NAME();                                                      \
    static ::pltest::Registrar pl_reg_##NAME(#NAME, &NAME);                  \
    static void NAME()

#define PL_CHECK(COND)                                                       \
    do {                                                                     \
        if (!(COND)) ::pltest::reportFailure(__FILE__, __LINE__,             \
                                             "expected: " #COND);            \
    } while (0)

// EXACT equality, printed as unsigned 64-bit.
//
// NOT PL_CHECK_NEAR with a zero epsilon: that routes both sides through double,
// and a uint64 hash above 2^53 does not survive the trip -- two different hashes
// can compare equal after the conversion, which is the one failure a hash test
// must never miss.
#define PL_CHECK_EQ(A, B)                                                    \
    do {                                                                     \
        const unsigned long long a_ = (unsigned long long)(A);               \
        const unsigned long long b_ = (unsigned long long)(B);               \
        if (a_ != b_) {                                                      \
            char buf_[256];                                                  \
            std::snprintf(buf_, sizeof(buf_),                                \
                          "%s == %s : %llu vs %llu", #A, #B, a_, b_);        \
            ::pltest::reportFailure(__FILE__, __LINE__, buf_);               \
        }                                                                    \
    } while (0)

#define PL_CHECK_NEAR(A, B, EPS)                                             \
    do {                                                                     \
        const double a_ = (A), b_ = (B);                                     \
        if (!(std::fabs(a_ - b_) <= (EPS))) {                                \
            char buf_[256];                                                  \
            std::snprintf(buf_, sizeof(buf_),                                \
                          "%s == %s : %.10g vs %.10g (eps %g)",              \
                          #A, #B, a_, b_, (double)(EPS));                    \
            ::pltest::reportFailure(__FILE__, __LINE__, buf_);               \
        }                                                                    \
    } while (0)
