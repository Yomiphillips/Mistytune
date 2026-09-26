# CUDA, located rather than assumed, and OPTIONAL.
#
# NAME-FREE BY DESIGN, like cmake/AESDK.cmake -- nothing here mentions the plugin.
#
# ---------------------------------------------------------------------------
# WHY OPTIONAL. Exactly the same argument as a missing AE SDK: src/engine/ and
# tests/ are the fast loop, they hold no GPU headers, and making CUDA a hard
# error would quietly couple them to a toolkit they do not use. A machine with no
# CUDA still gets a building plugin, a green test run, and the CPU render path.
#
# The cost of the CPU path is honesty about what it is: a correctness reference
# and a fallback, not a shipping renderer. A path trace on a CPU at comp
# resolution is minutes per frame.
# ---------------------------------------------------------------------------
#
# CUDA FIRST, WINDOWS FIRST, per PLAN.md. Metal comes from the SAME kernel source
# at Phase 5 -- hand-maintaining two path tracers is the design spec's own named
# risk, and the sample convention of parallel .cu and .metal files kept in sync by
# hand is tolerable for a fifty-line invert and untenable for six generators.

option(PLUGIN_ENABLE_CUDA "Build the CUDA render path (OFF = CPU reference only)" ON)

set(PLUGIN_CUDA_FOUND FALSE)

if(NOT PLUGIN_ENABLE_CUDA)
    message(STATUS "CUDA: disabled by PLUGIN_ENABLE_CUDA=OFF -- CPU reference path only.")
    return()
endif()

if(APPLE)
    # Not a failure, and not worth a warning every configure. NVIDIA has shipped
    # no macOS driver since 10.13; the mac path is Metal, from the same source.
    message(STATUS "CUDA: skipped on macOS -- the mac path is Metal (Phase 5).")
    return()
endif()

# CheckLanguage rather than enable_language() directly: enable_language(CUDA) on a
# machine with no toolkit is a FATAL error with no way to recover, which would
# make a GPU-less machine unable to configure at all.
include(CheckLanguage)
check_language(CUDA)

if(NOT CMAKE_CUDA_COMPILER)
    message(STATUS "CUDA: NOT FOUND -- CPU reference path only.")
    message(STATUS "  Install the CUDA Toolkit from https://developer.nvidia.com/cuda-downloads")
    message(STATUS "  to build the GPU renderer. Engine and unit tests build regardless.")
    return()
endif()

enable_language(CUDA)
find_package(CUDAToolkit REQUIRED)

set(PLUGIN_CUDA_FOUND TRUE)
message(STATUS "CUDA: ${CMAKE_CUDA_COMPILER_VERSION} (${CMAKE_CUDA_COMPILER})")

# ---------------------------------------------------------------------------
# Architectures.
#
# THE MINIMUM GPU IS A MEASUREMENT AND NOT AN OPINION -- PLAN.md defers it until
# Phase 2 has samples/second from real cards, because that number is what decides
# whether Draft mode is interactive at all.
#
# Until then: a spread wide enough to run on what people have, with PTX at the top
# so a card newer than this list still works. 61 is Pascal (GTX 10-series), which
# is roughly the oldest card anyone would try a path tracer on; 75 Turing, 86
# Ampere, 89 Ada.
#
# "61-real;75-real;86-real;89-real;89-virtual" rather than "all": `all` on a recent
# toolkit emits every architecture it knows including ones no user has, and the
# .aex gets tens of megabytes of dead cubin. The trailing -virtual is the PTX that
# JITs forward onto whatever comes next.
set(PLUGIN_CUDA_ARCHITECTURES "61-real;75-real;86-real;89-real;89-virtual"
    CACHE STRING "CUDA architectures to compile the kernel for")

# ---------------------------------------------------------------------------
# Determinism, and it is not a taste setting.
#
# tests/golden/ compares renders bit-for-bit across runs, worker counts and
# platforms. Three nvcc defaults break that:
#
#   --fmad=false      nvcc fuses a*b + c*d into an FMA by default, keeping one
#                     product at higher intermediate precision. MSVC does not
#                     contract under /fp:precise, and the top-level CMakeLists
#                     already passes -ffp-contract=off to clang for exactly this
#                     reason. An expression that cancels to zero on the CPU
#                     reference leaves a residue on the GPU otherwise, and the
#                     golden image only matches on one of them.
#
#   --prec-div=true   } both default to true already, stated explicitly so a
#   --prec-sqrt=true  } future -use_fast_math cannot silently take them away.
#
# -use_fast_math IS THE FLAG TO NOT REACH FOR. It turns on all three of the above
# in reverse plus approximate transcendentals, and the speedup is small next to a
# path tracer's memory traffic. If it is ever measured to be worth it, it goes
# behind its own option with the golden tolerances widened in the same commit.
set(PLUGIN_CUDA_FLAGS
    --fmad=false
    --prec-div=true
    --prec-sqrt=true
    CACHE STRING "Extra nvcc flags applied to the kernel translation units")
