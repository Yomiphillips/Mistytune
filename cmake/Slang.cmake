# Slang, located rather than assumed, and OPTIONAL -- like cmake/Cuda.cmake.
#
# ===========================================================================
# THE GENERATED CUDA IS COMMITTED. SLANG IS ONLY NEEDED TO REGENERATE IT.
#
# That is the decision this file exists to implement, and it is worth the paragraph
# because the obvious alternative -- run slangc as a build step -- is what most
# projects do and is wrong here.
#
# A shader compiler decides the bits in every golden image. Making it a build
# dependency means every machine that builds this plugin needs the right VERSION of
# it, or the golden suite fails for a reason that has nothing to do with the change
# being tested. It also means CI, a fresh clone, and anyone who just wants to fix a
# typo in the host code all need a 147 MB download.
#
# Committing the generated .cu costs a file in review and buys: builds that work
# with no toolchain, a diff that SHOWS what a shader change did to the generated
# code, and a bisect that compiles at every commit.
#
# The cost is that the generated file can go stale against its .slang source. That
# is guarded rather than hoped about -- see slang_generated_source() below, and the
# slang.regenerates test.
# ===========================================================================
#
# WHY SLANG AT ALL, and why CUDA SOURCE rather than PTX. Measured 2026-09-28, in
# PROGRESS.md: every transcendental the renderer calls is BIT-IDENTICAL between
# Slang's CUDA output and hand-written CUDA over 44,001 inputs, so a faithful port
# reproduces the CPU reference by construction. That holds because the generated
# source goes through nvcc with THIS PROJECT'S flags -- --fmad=false, --prec-div,
# --prec-sqrt. Emitting PTX instead would put contraction and division precision
# outside our control, which is precisely what tests/golden/ exists to protect.

option(PLUGIN_ENABLE_SLANG "Regenerate the CUDA kernel from Slang sources when available" ON)

set(PLUGIN_SLANG_FOUND FALSE)

# PLUGIN_SLANGC IS DELIBERATELY NOT PRE-SET HERE. find_program writes a CACHE entry,
# and a normal variable of the same name shadows it -- so initialising it to "" makes
# the search appear to fail on a machine that has slangc sitting right where the hint
# points. Cost an afternoon once; the empty set() looked like tidy initialisation.

# ---------------------------------------------------------------------------
# THE FLAG THAT MUST NEVER BE PASSED
# ---------------------------------------------------------------------------
#
# -fp-mode fast makes Slang emit SLANG_CUDA_ENABLE_FAST_MATH=1, and the prelude then
# redirects exp/sin/cos/tan/log/pow to the approximate __*f intrinsics. Measured over
# the same 44,001 inputs: exp differs on 36,886 of them, worst absolute difference
# 4.12e11; tan differs on 43,688, worst 2812.
#
# IT BREAKS SOME FUNCTIONS AND NOT OTHERS -- sqrt, rsqrt and exp2 have no fast form
# and stay exact -- so a build with it on renders a picture that is nearly right, and
# the golden suite would catch it only where exp happens to dominate the pixel.
#
# This variable is not configurable on purpose. If a future target genuinely needs
# it, that is a decision to re-bless every golden reference, not a flag to flip.
set(PLUGIN_SLANG_FP_MODE "precise")


# ===========================================================================
# THE FUNCTION IS DEFINED BEFORE THE EARLY RETURNS BELOW, AND THAT ORDER IS THE WHOLE
# POINT. IT USED TO BE AT THE BOTTOM, AND THAT WAS A BUG IN THE ONE CONFIGURATION THIS
# FILE EXISTS TO SUPPORT.
#
# Both exits below -- PLUGIN_ENABLE_SLANG=OFF, and slangc not found -- `return()` out
# of this file. With the definition after them, `slang_generate` simply did not exist
# on any machine without Slang, and tests/slang/CMakeLists.txt calls it unconditionally:
#
#     CMake Error at tests/slang/CMakeLists.txt: Unknown CMake command "slang_generate"
#
# So a fresh clone or a CI runner with CUDA and no Slang could not CONFIGURE, let alone
# build from the committed CUDA. That is the exact scenario the committed artifacts are
# for, and PROGRESS.md recorded it as verified.
#
# WHY IT WENT UNNOTICED: tests/slang/CMakeLists.txt returns early when CUDA is absent,
# so the call is never reached on a machine with neither. It needs CUDA *and* no Slang
# to bite -- which is CI and a fresh clone, and is never the machine doing the work.
#
# The function no-ops internally on PLUGIN_SLANG_FOUND, so defining it unconditionally
# is all that was needed. Nothing else about the arrangement changes.
# ===========================================================================
# ---------------------------------------------------------------------------
# slang_generate(<slang file> <generated cu> <prelude> [included .slang files...])
# ---------------------------------------------------------------------------
#
# Regenerates INTO THE SOURCE TREE rather than the build directory, because the
# output is committed. That is unusual enough to say out loud: the build writes a
# file that git tracks, so an edit to a .slang shows up as a change to both files and
# gets reviewed together.
#
# A NO-OP WHEN THE OUTPUT IS NEWER, via the usual dependency rule, so an ordinary
# build of an unchanged tree touches nothing.
#
# ===========================================================================
# THE TRAILING ARGUMENTS ARE THE #include'd SOURCES, AND LEAVING ONE OUT IS A STALE
# COMMITTED ARTIFACT.
#
# Slang has no `[export]`, so code is shared between kernels by #include -- Rng.slang,
# PhaseLib.slang, TransportLib.slang. CMake cannot see through an #include it does not
# know about, so with only the top-level source listed as a dependency, editing
# Rng.slang would leave every generated .cu exactly as it was: the build succeeds, the
# tests pass, and what ships is the OLD maths.
#
# That is the worst failure this file can have, because the committed artifact is the
# thing that ships and nothing else would notice. slangc can emit a depfile, which
# would remove the chance of a wrong list entirely -- but `add_custom_command` takes
# DEPFILE only on Ninja and Makefile generators, and this project builds with the
# Visual Studio generator. So the list is explicit and the reason is recorded here.
# ===========================================================================
function(slang_generate SLANG_SRC GENERATED_CU PRELUDE_RELATIVE)
    set(_includes)
    foreach(_inc IN LISTS ARGN)
        get_filename_component(_inc_abs "${_inc}" ABSOLUTE)
        if(NOT EXISTS "${_inc_abs}")
            # A REFUSAL, NOT A WARNING. A typo'd include path silently reintroduces
            # exactly the staleness this argument exists to prevent.
            message(FATAL_ERROR
                "slang_generate(${SLANG_SRC}): included source does not exist:\n"
                "  ${_inc_abs}")
        endif()
        list(APPEND _includes "${_inc_abs}")
    endforeach()

    if(NOT PLUGIN_SLANG_FOUND)
        return()
    endif()

    get_filename_component(_src_abs "${SLANG_SRC}" ABSOLUTE)
    get_filename_component(_out_abs "${GENERATED_CU}" ABSOLUTE)

    # -line-directive-mode none IS NOT COSMETIC. With it left at the default, slangc
    # writes #line directives carrying the ABSOLUTE PATH of the source on the
    # generating machine. In a committed file that means the output differs for every
    # developer, and slang.regenerates fails for everyone but the last person to run
    # it. It also costs the debugger's line mapping, which is a fair trade for a file
    # nobody is meant to read.
    add_custom_command(
        OUTPUT  "${_out_abs}"
        COMMAND "${PLUGIN_SLANGC}" "${_src_abs}"
                -target cuda
                -fp-mode ${PLUGIN_SLANG_FP_MODE}
                -line-directive-mode none
                -o "${_out_abs}"
        COMMAND "${CMAKE_COMMAND}"
                -DGENERATED=${_out_abs}
                -DPRELUDE=${PRELUDE_RELATIVE}
                -DSOURCE=${_src_abs}
                -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/SlangRewriteInclude.cmake"
        DEPENDS "${_src_abs}" ${_includes}
        COMMENT "Slang -> CUDA: ${SLANG_SRC}"
        VERBATIM)
endfunction()

# ---------------------------------------------------------------------------
# slang_generate_cpp(<slang file> <generated cpp> <prelude> [included .slang files...])
# ---------------------------------------------------------------------------
#
# The same arrangement for the C++ target, and it exists for one reason:
# PLAN.md's premise is ONE KERNEL SOURCE, and `renderPixel` is a single function serving
# both the CPU and the GPU. Forking it is what the whole golden-image strategy rests on
# not doing -- a golden image taken on the CPU is only a meaningful check on the GPU
# while both run the same maths.
#
# So the CPU arm compiles THE SAME .slang through `-target cpp`, and the committed
# output is treated exactly as the CUDA one is: generated when Slang is present, checked
# for staleness by slang.regenerates, and compiled with no toolchain otherwise.
#
# THE SAME -fp-mode APPLIES AND FOR THE SAME REASON. See the note above on why `fast`
# must never be passed; it breaks some functions and not others, and CPU/GPU parity is
# exactly the thing that would catch it and exactly the thing that would then be blamed.
function(slang_generate_cpp SLANG_SRC GENERATED_CPP PRELUDE_RELATIVE)
    set(_includes)
    foreach(_inc IN LISTS ARGN)
        get_filename_component(_inc_abs "${_inc}" ABSOLUTE)
        if(NOT EXISTS "${_inc_abs}")
            message(FATAL_ERROR
                "slang_generate_cpp(${SLANG_SRC}): included source does not exist:\n"
                "  ${_inc_abs}")
        endif()
        list(APPEND _includes "${_inc_abs}")
    endforeach()

    if(NOT PLUGIN_SLANG_FOUND)
        return()
    endif()

    get_filename_component(_src_abs "${SLANG_SRC}" ABSOLUTE)
    get_filename_component(_out_abs "${GENERATED_CPP}" ABSOLUTE)

    add_custom_command(
        OUTPUT  "${_out_abs}"
        COMMAND "${PLUGIN_SLANGC}" "${_src_abs}"
                -target cpp
                -fp-mode ${PLUGIN_SLANG_FP_MODE}
                -line-directive-mode none
                -o "${_out_abs}"
        COMMAND "${CMAKE_COMMAND}"
                -DGENERATED=${_out_abs}
                -DPRELUDE=${PRELUDE_RELATIVE}
                -DSOURCE=${_src_abs}
                -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/SlangRewriteInclude.cmake"
        DEPENDS "${_src_abs}" ${_includes}
        COMMENT "Slang -> C++: ${SLANG_SRC}"
        VERBATIM)
endfunction()

if(NOT PLUGIN_ENABLE_SLANG)
    message(STATUS "Slang: disabled by PLUGIN_ENABLE_SLANG=OFF -- using the committed generated CUDA.")
    return()
endif()

# ---------------------------------------------------------------------------
# Finding it
# ---------------------------------------------------------------------------
#
# In preference order: an explicit root, the fetched copy, then whatever is on PATH.
# The explicit root comes first so a developer testing a Slang upgrade does not have
# to delete the fetched one.
set(_slang_hints)
if(PLUGIN_SLANG_ROOT)
    list(APPEND _slang_hints "${PLUGIN_SLANG_ROOT}/bin")
endif()
if(DEFINED ENV{PLUGIN_SLANG_ROOT})
    list(APPEND _slang_hints "$ENV{PLUGIN_SLANG_ROOT}/bin")
endif()
# ABSOLUTE, because find_program does not normalise a hint containing "..". The
# path resolves, the directory exists, and the search silently misses it -- which
# presents as "Slang: NOT FOUND" on a machine that has just fetched it.
get_filename_component(_slang_fetched "${CMAKE_CURRENT_LIST_DIR}/../tools/slang/bin" ABSOLUTE)
list(APPEND _slang_hints "${_slang_fetched}")

find_program(PLUGIN_SLANGC
    NAMES slangc
    HINTS ${_slang_hints}
    DOC "Slang shader compiler (slangc)")

if(NOT PLUGIN_SLANGC)
    message(STATUS "Slang: NOT FOUND -- building from the committed generated CUDA.")
    message(STATUS "  That is a supported configuration, not a degraded one: the")
    message(STATUS "  generated sources are in the repository and are what ships.")
    message(STATUS "  To regenerate after editing a .slang file, run:")
    message(STATUS "      cmake -P cmake/FetchSlang.cmake")
    return()
endif()

# THE VERSION IS READ AND REPORTED, because a shader compiler upgrade is a change to
# the output bits. When a golden test fails on a machine and passes on another, this
# line in the configure log is the first thing worth comparing.
execute_process(
    COMMAND "${PLUGIN_SLANGC}" -v
    OUTPUT_VARIABLE _slang_ver
    ERROR_VARIABLE  _slang_ver_err
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE)
if(NOT _slang_ver)
    set(_slang_ver "${_slang_ver_err}")
endif()

set(PLUGIN_SLANG_FOUND TRUE)
message(STATUS "Slang: ${_slang_ver} (${PLUGIN_SLANGC})")
message(STATUS "  fp-mode ${PLUGIN_SLANG_FP_MODE} -- see cmake/Slang.cmake on why this is not optional")

