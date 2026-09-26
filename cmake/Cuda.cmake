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
# ---------------------------------------------------------------------------
# MAKE THE VERSIONED ENV VAR EXIST BEFORE ANYTHING SPAWNS MSBUILD.
#
# check_language(CUDA) does not just look for nvcc -- it configures and BUILDS a
# tiny project, through MSBuild under a Visual Studio generator. That build reads
# CudaToolkitDir out of `CUDA <ver>.props`, which reads the VERSIONED variable
# CUDA_PATH_V13_4 and not CUDA_PATH. A shell opened before the toolkit was
# installed has neither, and the only symptom is "Looking for a CUDA compiler -
# NOTFOUND" -- which reads as "no toolkit installed" when the toolkit is right
# there.
#
# set(ENV{...}) here reaches every process CMake spawns from this point on, which
# is exactly the set of processes that need it. Discovering the path instead of
# requiring the environment to carry it is the same rule cmake/AESDK.cmake follows
# for After Effects.
if(WIN32 AND CMAKE_GENERATOR MATCHES "Visual Studio")
    set(_cuda_hint "$ENV{CUDA_PATH}")

    if(NOT _cuda_hint)
        # NATURAL sort, because the default is lexicographic and would rank v9.0
        # above v13.4 -- picking a toolkit four major versions too old.
        file(GLOB _cuda_dirs "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v*")
        list(SORT _cuda_dirs COMPARE NATURAL)
        list(REVERSE _cuda_dirs)
        foreach(_d IN LISTS _cuda_dirs)
            if(EXISTS "${_d}/bin/nvcc.exe")
                set(_cuda_hint "${_d}")
                break()
            endif()
        endforeach()
    endif()

    if(_cuda_hint AND EXISTS "${_cuda_hint}/bin/nvcc.exe")
        get_filename_component(_cuda_leaf "${_cuda_hint}" NAME)     # "v13.4"
        string(SUBSTRING "${_cuda_leaf}" 1 -1 _cuda_num)            # "13.4"
        string(REPLACE "." "_" _cuda_num "${_cuda_num}")            # "13_4"
        set(_cuda_var "CUDA_PATH_V${_cuda_num}")

        if(NOT DEFINED ENV{${_cuda_var}})
            set(ENV{${_cuda_var}} "${_cuda_hint}")
            message(STATUS "CUDA: exported ${_cuda_var} for MSBuild -- the shell did not have it.")
        endif()
        if(NOT DEFINED ENV{CUDA_PATH})
            set(ENV{CUDA_PATH} "${_cuda_hint}")
        endif()
    endif()
endif()
# ---------------------------------------------------------------------------

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
# MSBUILD NEEDS THE TOOLKIT PATH AT *BUILD* TIME, NOT ONLY AT CONFIGURE TIME.
#
# `CUDA <ver>.props` resolves CudaToolkitDir from the VERSIONED environment
# variable -- CUDA_PATH_V13_4, not CUDA_PATH -- which the installer sets
# machine-wide. Any shell opened BEFORE the toolkit was installed inherits a stale
# environment and does not have it, and an editor's integrated terminal can carry
# that staleness for as long as the editor stays open.
#
# THE FAILURE MODE IS WORSE THAN IT LOOKS, because configure and build read the
# environment at different moments. A tree configured in a good shell caches
# "CUDA found", and a build of that same tree from a stale shell then fails inside
# a .targets file with:
#
#     error : The CUDA Toolkit directory '' does not exist.
#
# followed by LNK1181 on cudart_static.lib, because the empty directory also
# emptied the library search path. Neither message mentions the environment, and
# the tree looks correctly configured because it was.
#
# So the path is BAKED INTO THE GENERATED PROJECTS rather than looked up again
# later. CMAKE_VS_GLOBALS applies to every target created after this point, which
# is why it is set here, above the add_subdirectory() calls. Same rule as
# cmake/AESDK.cmake finding After Effects through the registry: locate it once,
# write it down, and do not ask the environment a second time.
get_filename_component(_cuda_bin "${CMAKE_CUDA_COMPILER}" DIRECTORY)
get_filename_component(PLUGIN_CUDA_ROOT "${_cuda_bin}" DIRECTORY)

if(CMAKE_GENERATOR MATCHES "Visual Studio")
    list(APPEND CMAKE_VS_GLOBALS "CudaToolkitDir=${PLUGIN_CUDA_ROOT}")
    message(STATUS "  CudaToolkitDir pinned into the projects: ${PLUGIN_CUDA_ROOT}")
endif()
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Architectures.
#
# THE MINIMUM GPU IS A MEASUREMENT AND NOT AN OPINION -- PLAN.md defers it until
# Phase 2 has samples/second from real cards, because that number is what decides
# whether Draft mode is interactive at all.
#
# THE FLOOR IS NOT OURS TO CHOOSE ANY MORE -- THE TOOLKIT SETS IT.
#
# This list began at 61 (Pascal, GTX 10-series) on the reasoning that it was the
# oldest card anyone would point a path tracer at. CUDA 13 removed Maxwell, Pascal
# and Volta outright, and nvcc 13.4 answers `--list-gpu-arch` with compute_75 and
# up. Asking it for 61 is not a slow build or a fat binary, it is:
#
#     nvcc fatal : Unsupported gpu architecture 'compute_61'
#
# So the minimum GPU is Turing for as long as the build uses a 13.x toolkit. That
# is a CONSTRAINT DISCOVERED, not the measurement PLAN.md defers to Phase 2 -- that
# one is still about samples/second deciding whether Draft mode is interactive, and
# it can only raise this floor, never lower it. Supporting Pascal again would mean
# pinning a CUDA 12.x toolkit, which is a deliberate decision with its own costs and
# should be taken on evidence that anyone is asking for it.
#
# 75 Turing, 86 Ampere, 89 Ada, then PTX. Named rather than "all": `all` on a recent
# toolkit emits every architecture it knows including ones no user has, and the .aex
# gets tens of megabytes of dead cubin. The trailing -virtual is the PTX that JITs
# forward onto whatever comes next -- which is what covers Hopper and Blackwell here
# without compiling cubin for either.
set(PLUGIN_CUDA_ARCHITECTURES "75-real;86-real;89-real;89-virtual"
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
