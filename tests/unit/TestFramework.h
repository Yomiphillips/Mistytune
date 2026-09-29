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

// ---------------------------------------------------------------------------
// Sweeps
// ---------------------------------------------------------------------------

// ===========================================================================
// THIS EXISTS BECAUSE THE SAME MISTAKE HAS NOW BEEN MADE THREE TIMES, AND WRITING
// IT DOWN TWICE DID NOT PREVENT THE THIRD.
//
// A test that sweeps a range and asserts INSIDE the loop reports once per failing
// sample. Measured, each time by injecting the fault the test was written to catch:
//
//     TheQuantiserIsExactlyClampScaleAndRound     ~16000 lines
//     TheCurveMatchesTheOneOnTheRenderPath          2007 lines
//     TheAltitudeWarpRoundTrips                       64 lines
//
// Every one of those buries the other failures in the run -- including, the first
// time, the two that named the actual bug. Each was then rewritten by hand into
// count-and-report-once, and the lesson was recorded in PROGRESS.md, and the next
// sweep written still did it the wrong way.
//
// THE FIX IS NOT ANOTHER NOTE, IT IS MAKING THE RIGHT SHAPE THE EASY ONE. A Sweep
// collects, remembers the first disagreement, and reports a single line naming what
// it was -- which is strictly more useful than the flood, because the flood's first
// line scrolls away.
//
// USE: construct, call check() per sample, then finish() once.
//
//     pltest::Sweep sweep("probes");
//     for (...) sweep.check(got, want, 1e-6, x);
//     sweep.finish();      // reports and asserts
//
// `where` is whatever number identifies the sample -- an index, an input value, an
// altitude. It is printed with the first mismatch, because "2007 of 2015 disagree"
// says there is a bug and "first at input 0.00313" says where to look.
// ===========================================================================
class Sweep {
public:
    explicit Sweep(const char* what, const char* file = __FILE__, int line = __LINE__)
        : what_(what), file_(file), line_(line) {}

    // One sample. Returns false if it disagreed, so a caller can count something else.
    bool check(double got, double want, double eps, double where = 0.0) {
        ++compared_;
        if (!(std::fabs(got - want) <= eps)) {
            if (mismatches_ == 0) {
                firstGot_ = got;
                firstWant_ = want;
                firstWhere_ = where;
            }
            ++mismatches_;
            return false;
        }
        return true;
    }

    // A sample whose condition is not a near-comparison.
    bool require(bool ok, double where = 0.0) {
        ++compared_;
        if (!ok) {
            if (mismatches_ == 0) firstWhere_ = where;
            ++mismatches_;
            return false;
        }
        return true;
    }

    int compared() const { return compared_; }
    int mismatches() const { return mismatches_; }

    // Reports once and fails once.
    //
    // `atLeast` GUARDS THE FAILURE MODE OF EVERY LOOP-DRIVEN TEST: a sweep whose
    // range was empty compared nothing and passes silently. Every sweep in this
    // suite has a minimum, and it is not optional.
    void finish(int atLeast = 1) {
        if (mismatches_ > 0) {
            std::printf("      %d of %d %s disagree.\n"
                        "      first: at %.9g -- got %.9g, wanted %.9g\n",
                        mismatches_, compared_, what_,
                        firstWhere_, firstGot_, firstWant_);
            ::pltest::reportFailure(file_, line_, std::string("sweep over ") + what_);
        }
        if (compared_ < atLeast) {
            char buf[256];
            std::snprintf(buf, sizeof(buf),
                          "sweep over %s compared %d, expected at least %d "
                          "-- an empty sweep passes while checking nothing",
                          what_, compared_, atLeast);
            ::pltest::reportFailure(file_, line_, buf);
        }
    }

private:
    const char* what_;
    const char* file_;
    int         line_;
    int    compared_   = 0;
    int    mismatches_ = 0;
    double firstGot_   = 0.0;
    double firstWant_  = 0.0;
    double firstWhere_ = 0.0;
};

} // namespace pltest

// A Sweep that carries the line it was declared on, so its failure points here
// rather than into TestFramework.h.
#define PL_SWEEP(NAME, WHAT) ::pltest::Sweep NAME((WHAT), __FILE__, __LINE__)

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
