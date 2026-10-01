# Makes a slangc-generated .cu portable enough to commit.
#
#     cmake -DGENERATED=<file> -DPRELUDE=<relative path> -DSOURCE=<slang file> \
#           -P cmake/SlangRewriteInclude.cmake
#
# TWO THINGS LEAK THE GENERATING MACHINE INTO THE OUTPUT, and both have to go or the
# committed file differs per-developer and the staleness test fails for everyone
# except whoever last regenerated it.
#
#   1. #line directives carrying absolute source paths. Handled at generation time
#      by -line-directive-mode none, not here.
#   2. The prelude #include, which slangc writes as an absolute path to wherever the
#      toolchain happens to live. That is this file's job.
#
# The prelude itself is vendored next to the generated sources -- see
# src/kernel/slang/prelude/, and LICENSE-Slang.txt beside it. Apache-2.0 WITH
# LLVM-exception, which is the licence written for exactly this: a runtime support
# header emitted into someone else's build output.

if(NOT GENERATED OR NOT PRELUDE)
    message(FATAL_ERROR "SlangRewriteInclude.cmake needs -DGENERATED and -DPRELUDE")
endif()

if(NOT EXISTS "${GENERATED}")
    message(FATAL_ERROR "slangc produced no output at ${GENERATED}")
endif()

file(READ "${GENERATED}" _content)

# EITHER PRELUDE. The CUDA target emits slang-cuda-prelude.h and the C++ target emits
# slang-cpp-prelude.h, and both arrive as an absolute path into the toolchain. The
# caller says which vendored file it wants via -DPRELUDE, so the pattern here only has
# to recognise the shape slangc writes.
string(REGEX REPLACE "#include \"[^\"]*slang-(cuda|cpp)-prelude\\.h\""
                     "#include \"${PRELUDE}\""
                     _content "${_content}")

# A REFUSAL RATHER THAN A SILENT PASS. If slangc ever stops emitting the include in
# this shape, the generated file would still compile on the machine that made it and
# fail everywhere else -- which is the worst kind of build bug, because it reproduces
# for nobody who could fix it.
if(NOT _content MATCHES "#include \"${PRELUDE}\"")
    message(FATAL_ERROR
        "Could not rewrite the prelude include in ${GENERATED}.\n"
        "  slangc's output shape changed. The generated file is NOT portable until\n"
        "  this is fixed -- see cmake/SlangRewriteInclude.cmake.")
endif()

get_filename_component(_src_name "${SOURCE}" NAME)

set(_banner "// GENERATED FROM ${_src_name} BY slangc -- DO NOT EDIT.
//
// Committed on purpose: Slang is needed to REGENERATE this, never to build it. See
// cmake/Slang.cmake for why, and for the fp-mode that must not change.
//
// Regenerate with a normal build when Slang is present; the slang.regenerates test
// fails if this file and its .slang source have drifted apart.

")

# ===========================================================================
# WRITTEN THROUGH A COPY THAT RETRIES, NOT WITH file(WRITE) -- AND THAT WAS A MEASUREMENT
# OF HOW OFTEN THE BUILD FAILED.
#
# Two test projects generate Transport.cu (slang_transport, and slang_cpu_parity with its
# CpuParity.cpp), and MSBuild builds them in parallel; one compiles the file while the
# other rewrites it. file(WRITE) then failed "Permission denied" -- on 2026-10-01 on the
# FIRST build after every change to a shared .slang, five builds running -- and a fatal
# error in a script cannot be caught. copy_if_different never rewrites a file that
# already holds this text, which is the usual case when the other project got there first,
# and a write that meets a lock is tried again for a few seconds before it fails.
# ===========================================================================
string(RANDOM LENGTH 10 _tag)
set(_staging "${GENERATED}.${_tag}.tmp")
file(WRITE "${_staging}" "${_banner}${_content}")
set(_copied 1)
# ...AND TOUCHED, because a file copy_if_different left alone keeps its old time, and the
# build would then see this output as older than its .slang and regenerate it every time.
foreach(_try RANGE 1 20)
    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_staging}" "${GENERATED}"
                    RESULT_VARIABLE _copied OUTPUT_QUIET ERROR_QUIET)
    if(_copied EQUAL 0)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E touch_nocreate "${GENERATED}"
                        RESULT_VARIABLE _copied OUTPUT_QUIET ERROR_QUIET)
    endif()
    if(_copied EQUAL 0)
        break()
    endif()
    execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 0.5)
endforeach()
file(REMOVE "${_staging}")
if(NOT _copied EQUAL 0)
    message(FATAL_ERROR "Could not write ${GENERATED}: it stayed locked for ten seconds.")
endif()
