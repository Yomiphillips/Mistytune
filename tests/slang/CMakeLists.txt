# Tier 1b: the Slang toolchain's numerics, checked against CUDA's.
#
# NEEDS CUDA BUT NOT SLANG. It compiles the COMMITTED generated CUDA, which is what
# ships and what the golden images were blessed against -- so it guards the artifact
# rather than the generator, and catches a regeneration made with the wrong flags.
#
# Skipped entirely without a CUDA toolkit, like every other GPU test here.

if(NOT PLUGIN_CUDA_FOUND)
    message(STATUS "Slang parity test: skipped (no CUDA toolkit).")
    return()
endif()

set(SLANG_DIR     "${CMAKE_SOURCE_DIR}/src/kernel/slang")
set(GENERATED_DIR "${SLANG_DIR}/generated")

# THE SHARED SOURCES EVERY GENERATED KERNEL DEPENDS ON THROUGH #include. Named here
# because CMake cannot see through an #include -- see slang_generate() in
# cmake/Slang.cmake on why a missing name is a stale committed artifact rather than a
# build error.
set(SLANG_RNG        "${SLANG_DIR}/Rng.slang")
set(SLANG_PHASE_LIB  "${SLANG_DIR}/PhaseLib.slang")
set(SLANG_XPORT_LIB  "${SLANG_DIR}/TransportLib.slang")
set(SLANG_GEN_LIB    "${SLANG_DIR}/GeneratorLib.slang")
set(SLANG_SKY_LIB    "${SLANG_DIR}/SkyLib.slang")
set(SLANG_BOUNCE_LIB "${SLANG_DIR}/BounceLib.slang")

if(NOT EXISTS "${GENERATED_DIR}/MathParity.cu")
    # A MISSING GENERATED FILE IS A FAILING TEST, NOT A SKIPPED ONE -- the same rule
    # tests/golden/ applies to a missing reference. A suite that quietly passes
    # because its inputs were never produced is worse than no suite.
    add_test(NAME slang.mathParity COMMAND ${CMAKE_COMMAND} -E false)
    message(STATUS "Slang parity: generated CUDA missing -- slang.mathParity will FAIL.")
    return()
endif()

# REGENERATED WHEN SLANG IS PRESENT, from the .slang beside it. On a machine without
# Slang this does nothing and the committed file is compiled as-is -- which is the
# whole arrangement, stated in cmake/Slang.cmake.
slang_generate("${SLANG_DIR}/MathParity.slang"
               "${GENERATED_DIR}/MathParity.cu"
               "../prelude/slang-cuda-prelude.h")

add_executable(slang_math_parity MathParityMain.cu "${GENERATED_DIR}/MathParity.cu")

# The generated .cu is #included as source by the harness, so it must NOT also be
# compiled as its own translation unit -- that would define mathMain twice.
set_source_files_properties("${GENERATED_DIR}/MathParity.cu" PROPERTIES HEADER_FILE_ONLY ON)

# The generated .cu is #included as source, and it includes the vendored prelude by a
# path relative to ITSELF -- so the generated directory is what goes on the include
# path, not the prelude directory.
target_include_directories(slang_math_parity PRIVATE "${GENERATED_DIR}")

set_target_properties(slang_math_parity PROPERTIES
    CUDA_ARCHITECTURES "${PLUGIN_CUDA_ARCHITECTURES}"
    LINKER_LANGUAGE CUDA)

# SLANG'S PRELUDE USES CUDA 13's DEPRECATED VECTOR TYPES (longlong4, ulonglong4,
# double4). Suppressed here and NOWHERE ELSE: the rest of the project builds at /W4
# with no suppressions, and this is a third-party header rather than a standard the
# project is choosing to drop.
target_compile_options(slang_math_parity PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-diag-suppress=1444>
    $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/wd4996>)

add_test(NAME slang.mathParity COMMAND slang_math_parity)

# ---------------------------------------------------------------------------
# The sky port against the hand-written sky
# ---------------------------------------------------------------------------
#
# BOTH RUN ON THE SAME GPU IN THE SAME BUILD, so nothing here can be blamed on
# CPU-versus-GPU or on a flag difference. With slang.mathParity green, a failure is a
# transcription error -- see the file's own diagnostic.
slang_generate("${SLANG_DIR}/Sky.slang"
               "${GENERATED_DIR}/Sky.cu"
               "../prelude/slang-cuda-prelude.h"
               ${SLANG_SKY_LIB})

add_executable(slang_sky_parity SkyParityMain.cu "${GENERATED_DIR}/Sky.cu")

set_source_files_properties("${GENERATED_DIR}/Sky.cu" PROPERTIES HEADER_FILE_ONLY ON)

target_include_directories(slang_sky_parity PRIVATE "${GENERATED_DIR}")
target_link_libraries(slang_sky_parity PRIVATE plugin_kernel)

set_target_properties(slang_sky_parity PROPERTIES
    CUDA_ARCHITECTURES "${PLUGIN_CUDA_ARCHITECTURES}"
    LINKER_LANGUAGE CUDA)

target_compile_options(slang_sky_parity PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-diag-suppress=1444>
    $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/wd4996>)

add_test(NAME slang.skyParity COMMAND slang_sky_parity)

# ---------------------------------------------------------------------------
# The phase functions, against physics rather than against a reference
# ---------------------------------------------------------------------------
#
# The transport has no C++ twin to diff against, so this checks the identities a
# correct phase function and importance sampler obey -- which also catches an error
# the prototype itself might contain. See the file's header.
slang_generate("${SLANG_DIR}/Phase.slang"
               "${GENERATED_DIR}/Phase.cu"
               "../prelude/slang-cuda-prelude.h"
               ${SLANG_RNG} ${SLANG_PHASE_LIB})

add_executable(slang_phase_parity PhaseParityMain.cu "${GENERATED_DIR}/Phase.cu")

set_source_files_properties("${GENERATED_DIR}/Phase.cu" PROPERTIES HEADER_FILE_ONLY ON)

target_include_directories(slang_phase_parity PRIVATE "${GENERATED_DIR}")

set_target_properties(slang_phase_parity PROPERTIES
    CUDA_ARCHITECTURES "${PLUGIN_CUDA_ARCHITECTURES}"
    LINKER_LANGUAGE CUDA)

target_compile_options(slang_phase_parity PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-diag-suppress=1444>
    $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/wd4996>)

add_test(NAME slang.phase COMMAND slang_phase_parity)

# ---------------------------------------------------------------------------
# Null-collision transport: the majorant must not reach the answer
# ---------------------------------------------------------------------------
#
# The identity that makes delta and ratio tracking testable without a reference --
# see the file's header on why sweeping the majorant is the whole point.
slang_generate("${SLANG_DIR}/Transport.slang"
               "${GENERATED_DIR}/Transport.cu"
               "../prelude/slang-cuda-prelude.h"
               ${SLANG_RNG} ${SLANG_XPORT_LIB} ${SLANG_GEN_LIB})

add_executable(slang_transport TransportMain.cu "${GENERATED_DIR}/Transport.cu")

set_source_files_properties("${GENERATED_DIR}/Transport.cu" PROPERTIES HEADER_FILE_ONLY ON)

target_include_directories(slang_transport PRIVATE "${GENERATED_DIR}")

set_target_properties(slang_transport PROPERTIES
    CUDA_ARCHITECTURES "${PLUGIN_CUDA_ARCHITECTURES}"
    LINKER_LANGUAGE CUDA)

target_compile_options(slang_transport PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-diag-suppress=1444>
    $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/wd4996>)

add_test(NAME slang.transport COMMAND slang_transport)

# ---------------------------------------------------------------------------
# The ice generator: does its optical-depth parameter mean optical depth?
# ---------------------------------------------------------------------------
#
# Also reports the peak density, which is the number a majorant estimator has to
# beat -- slang.transport shows what it costs to get that wrong in either direction.
slang_generate("${SLANG_DIR}/Generator.slang"
               "${GENERATED_DIR}/Generator.cu"
               "../prelude/slang-cuda-prelude.h"
               ${SLANG_GEN_LIB})

add_executable(slang_generator GeneratorMain.cu "${GENERATED_DIR}/Generator.cu")

set_source_files_properties("${GENERATED_DIR}/Generator.cu" PROPERTIES HEADER_FILE_ONLY ON)

target_include_directories(slang_generator PRIVATE "${GENERATED_DIR}")

# plugin_engine for IceField.h: this suite now checks the HOST's structural majorant
# against the kernel's own sampled peak, which is the only place the two tiers can
# meet. tests/unit/ can check that the arithmetic is what it claims; only a GPU can
# check that the claim is true.
target_link_libraries(slang_generator PRIVATE plugin_engine)

set_target_properties(slang_generator PROPERTIES
    CUDA_ARCHITECTURES "${PLUGIN_CUDA_ARCHITECTURES}"
    LINKER_LANGUAGE CUDA)

target_compile_options(slang_generator PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-diag-suppress=1444>
    $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/wd4996>)

add_test(NAME slang.generator COMMAND slang_generator)

# ---------------------------------------------------------------------------
# The bounce loop: a conservative medium in a uniform source must return the source
# ---------------------------------------------------------------------------
#
# THE ONLY IDENTITY COMPOSITION HAS. Every piece so far was checkable alone -- a phase
# function integrates to 1, a transmittance matches exp(-sigma d). The bounce loop is
# what joins them, and it fails by losing a few percent per event, which is invisible
# in a single-scatter check and a factor of two after twenty-five bounces.
#
# NOT A REPLACEMENT FOR slang.transport. In a furnace every escape returns the source
# radiance, so a path that escapes too early returns the right answer for the wrong
# reason -- the furnace is blind to exactly what the majorant sweep catches. The two
# tiers are complementary; see the headers of both files.
slang_generate("${SLANG_DIR}/Bounce.slang"
               "${GENERATED_DIR}/Bounce.cu"
               "../prelude/slang-cuda-prelude.h"
               ${SLANG_RNG} ${SLANG_PHASE_LIB} ${SLANG_XPORT_LIB} ${SLANG_GEN_LIB}
               ${SLANG_BOUNCE_LIB} ${SLANG_SKY_LIB})

add_executable(slang_bounce BounceMain.cu "${GENERATED_DIR}/Bounce.cu")

set_source_files_properties("${GENERATED_DIR}/Bounce.cu" PROPERTIES HEADER_FILE_ONLY ON)

target_include_directories(slang_bounce PRIVATE "${GENERATED_DIR}")

set_target_properties(slang_bounce PROPERTIES
    CUDA_ARCHITECTURES "${PLUGIN_CUDA_ARCHITECTURES}"
    LINKER_LANGUAGE CUDA)

target_compile_options(slang_bounce PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-diag-suppress=1444>
    $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/wd4996>)

add_test(NAME slang.bounce COMMAND slang_bounce)

# ---------------------------------------------------------------------------
# Has any committed .cu drifted from the .slang it came from?
# ---------------------------------------------------------------------------
#
# THE GUARD THREE COMMENTS ALREADY CLAIMED EXISTED. It did not, until now — see the
# header of cmake/SlangCheckRegenerated.cmake.
#
# WHAT IT ACTUALLY CATCHES, given that the build regenerates on this machine anyway:
# a WRONG DEPENDENCY LIST. `slang_generate` is told its #include'd sources by hand
# because CMake cannot see through an #include, and the failure mode of a hand-written
# list is a forgotten name — after which the build stops regenerating that kernel and
# says nothing at all. This test regenerates unconditionally into a temporary
# directory and compares, so it notices what the dependency rule has stopped noticing.
#
# It also catches a hand-edited generated file, and a regeneration made with the wrong
# -fp-mode.
#
# SKIPS WITHOUT SLANG rather than failing, which is deliberate and is argued in the
# script: the artifact exists and every other suite compiles it, there is simply no way
# to re-derive it without the compiler that made it, and failing here would make Slang
# mandatory — the one thing this arrangement exists to avoid.
# ---------------------------------------------------------------------------
# One kernel source, two backends: do they agree?
# ---------------------------------------------------------------------------
#
# The property PLAN.md's "one kernel source" asserts and nothing checked. `renderPixel`
# is a single function serving the CPU and the GPU, which is what makes a golden image
# taken on one a meaningful check on the other -- but only while the two backends really
# are computing the same maths.
#
# The CPU side is the SAME library through `-target cpp`, with entry points named `cpu*`
# because slangc marks them extern "C" and the CUDA names would otherwise collide. See
# the headers of CpuParity.slang and CpuParityMain.cu.
slang_generate_cpp("${SLANG_DIR}/CpuParity.slang"
                   "${GENERATED_DIR}/CpuParity.cpp"
                   "../prelude/slang-cpp-prelude.h"
                   ${SLANG_RNG} ${SLANG_XPORT_LIB} ${SLANG_GEN_LIB})

if(EXISTS "${GENERATED_DIR}/CpuParity.cpp")
    add_executable(slang_cpu_parity CpuParityMain.cu
                   "${GENERATED_DIR}/CpuParity.cpp"
                   "${GENERATED_DIR}/Transport.cu")

    # Both generated files are #included as source by the harness, so neither may also
    # be compiled as its own translation unit.
    set_source_files_properties("${GENERATED_DIR}/CpuParity.cpp"
                                "${GENERATED_DIR}/Transport.cu"
                                PROPERTIES HEADER_FILE_ONLY ON)

    target_include_directories(slang_cpu_parity PRIVATE "${GENERATED_DIR}")

    set_target_properties(slang_cpu_parity PROPERTIES
        CUDA_ARCHITECTURES "${PLUGIN_CUDA_ARCHITECTURES}"
        LINKER_LANGUAGE CUDA)

    target_compile_options(slang_cpu_parity PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:-diag-suppress=1444>
        $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/wd4996>)

    add_test(NAME slang.cpuParity COMMAND slang_cpu_parity)
else()
    # A MISSING GENERATED FILE IS A FAILING TEST, NOT A SKIPPED ONE -- the same rule the
    # rest of this file applies. Without Slang the committed CpuParity.cpp is compiled;
    # if it is absent, the CPU arm is untested and must say so loudly.
    add_test(NAME slang.cpuParity COMMAND ${CMAKE_COMMAND} -E false)
    message(STATUS "Slang: generated CpuParity.cpp missing -- slang.cpuParity will FAIL.")
endif()

add_test(NAME slang.regenerates
    COMMAND ${CMAKE_COMMAND}
        -DSLANGC=${PLUGIN_SLANGC}
        -DSLANG_DIR=${SLANG_DIR}
        -DGENERATED_DIR=${GENERATED_DIR}
        -DTEMP_DIR=${CMAKE_CURRENT_BINARY_DIR}/regen-check
        -DFP_MODE=${PLUGIN_SLANG_FP_MODE}
        -DPRELUDE=../prelude/slang-cuda-prelude.h
        -DREWRITE=${CMAKE_SOURCE_DIR}/cmake/SlangRewriteInclude.cmake
        -DSOURCES=MathParity|Sky|Phase|Transport|Generator|Bounce|Render
        -DCPP_SOURCES=CpuParity|RenderCpu
        -DCPP_PRELUDE=../prelude/slang-cpp-prelude.h
        -P ${CMAKE_SOURCE_DIR}/cmake/SlangCheckRegenerated.cmake)

# ---------------------------------------------------------------------------
# Are the generated struct field names still unique?
# ---------------------------------------------------------------------------
#
# THE HAZARD PROGRESS.md HAS NOW RECORDED TWICE, turned into a test.
#
# slangc numbers repeated identifiers across a whole translation unit, so a field can
# be renamed by an edit to a file that does not mention it -- and two fields of the
# same type swapping suffixes between two structs still compiles and reads the wrong
# memory. The mitigation has always been "keep host-visible field names unique", which
# is a rule somebody has to remember. This checks it instead.
#
# NEEDS NO SLANG AND NO GPU: it reads the committed generated sources, which are what
# ships. See cmake/SlangCheckFieldNames.cmake for the argument in full.
add_test(NAME slang.fieldNames
    COMMAND ${CMAKE_COMMAND}
        -DGENERATED_DIR=${GENERATED_DIR}
        -DFILES=MathParity.cu|Sky.cu|Phase.cu|Transport.cu|Generator.cu|Bounce.cu|Render.cu|CpuParity.cpp|RenderCpu.cpp
        -P ${CMAKE_SOURCE_DIR}/cmake/SlangCheckFieldNames.cmake)
