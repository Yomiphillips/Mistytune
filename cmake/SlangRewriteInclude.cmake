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

file(WRITE "${GENERATED}" "${_banner}${_content}")
