# Has a committed generated .cu drifted from the .slang it came from?
#
#     cmake -DSLANGC=<path> -DSLANG_DIR=<dir> -DGENERATED_DIR=<dir> -DTEMP_DIR=<dir> \
#           -DFP_MODE=precise -DPRELUDE=<relative> -DREWRITE=<script> \
#           -DSOURCES=Sky;Phase;... -P cmake/SlangCheckRegenerated.cmake
#
# ===========================================================================
# THIS IS THE TEST THREE COMMENTS ALREADY CLAIMED EXISTED.
#
# cmake/Slang.cmake said it twice and cmake/SlangRewriteInclude.cmake said it once:
# "the slang.regenerates test fails if this file and its .slang source have drifted
# apart". It did not exist. Nothing anywhere in the repository did.
#
# WHAT IT GUARDS, AND WHY THE BUILD RULE IS NOT ENOUGH. The generated CUDA is
# committed and is what ships; Slang is needed only to regenerate it. The build's
# dependency rule regenerates when a source is newer -- but only on a machine that HAS
# Slang. Edit a .slang without it and the build happily compiles the old .cu: green
# tests, and the OLD MATHS in the artifact that ships.
#
# The same hole opens for a regeneration made with the wrong flags, and for anyone who
# hand-edits a generated file despite the banner telling them not to.
#
# WHY IT SKIPS RATHER THAN FAILS WITHOUT SLANG, which is the opposite of what
# tests/slang/CMakeLists.txt does for a MISSING generated file, and the difference is
# real. A missing artifact means the inputs were never produced and a suite that passes
# on them is worse than no suite. Here the artifact exists and is compiled and tested
# by every other suite -- there is simply no way to re-derive it without the compiler
# that made it. Skipping is honest; failing would make Slang mandatory, which is the
# one thing this whole arrangement exists to avoid.
# ===========================================================================

if(NOT SLANGC OR NOT EXISTS "${SLANGC}")
    message("no slangc -- skipping (this test needs Slang, and the arrangement does not)")
    return()
endif()

# EVERY REQUIRED ARGUMENT CHECKED BEFORE ANYTHING IS DELETED. An unset -DTEMP_DIR
# would otherwise reach `file(REMOVE_RECURSE "")` a few lines below, and a script that
# removes a path it computed from an empty variable is not one to leave unguarded.
foreach(_required SOURCES SLANG_DIR GENERATED_DIR TEMP_DIR FP_MODE PRELUDE REWRITE)
    if(NOT ${_required})
        message(FATAL_ERROR "SlangCheckRegenerated.cmake needs -D${_required}=...")
    endif()
endforeach()

if(NOT EXISTS "${REWRITE}")
    message(FATAL_ERROR "no rewrite script at ${REWRITE}")
endif()

# PIPE-SEPARATED, NOT SEMICOLON. A semicolon is CMake's own list separator, so passing
# one through `add_test`'s COMMAND means quoting it past two levels of expansion; the
# forms that survive differ between generators. A separator that means nothing to
# CMake costs one line here and cannot be re-broken by an argument-quoting change.
string(REPLACE "|" ";" SOURCES "${SOURCES}")
if(CPP_SOURCES)
    string(REPLACE "|" ";" CPP_SOURCES "${CPP_SOURCES}")
endif()

file(REMOVE_RECURSE "${TEMP_DIR}")
file(MAKE_DIRECTORY "${TEMP_DIR}")

set(_stale)
set(_checked 0)

foreach(_name IN LISTS SOURCES)
    set(_src       "${SLANG_DIR}/${_name}.slang")
    set(_committed "${GENERATED_DIR}/${_name}.cu")
    set(_fresh     "${TEMP_DIR}/${_name}.cu")

    if(NOT EXISTS "${_src}")
        message(FATAL_ERROR "no such Slang source: ${_src}")
    endif()
    if(NOT EXISTS "${_committed}")
        # NOT a skip. The committed artifact is the thing that ships.
        message("  ${_name}: FAIL -- no committed ${_name}.cu at all")
        list(APPEND _stale "${_name} (missing)")
        continue()
    endif()

    # THE SAME FLAGS THE BUILD USES, and they have to stay the same flags or this test
    # reports drift on every run. -fp-mode in particular: see cmake/Slang.cmake on why
    # `fast` must never be passed.
    execute_process(
        COMMAND "${SLANGC}" "${_src}"
                -target cuda
                -fp-mode ${FP_MODE}
                -line-directive-mode none
                -o "${_fresh}"
        RESULT_VARIABLE _rc
        OUTPUT_VARIABLE _out
        ERROR_VARIABLE  _err)

    if(NOT _rc EQUAL 0)
        message("  ${_name}: FAIL -- slangc could not compile it\n${_out}${_err}")
        list(APPEND _stale "${_name} (does not compile)")
        continue()
    endif()

    execute_process(
        COMMAND "${CMAKE_COMMAND}"
                -DGENERATED=${_fresh}
                -DPRELUDE=${PRELUDE}
                -DSOURCE=${_src}
                -P "${REWRITE}"
        RESULT_VARIABLE _rc
        OUTPUT_QUIET ERROR_VARIABLE _err)

    if(NOT _rc EQUAL 0)
        message("  ${_name}: FAIL -- the prelude rewrite refused\n${_err}")
        list(APPEND _stale "${_name} (rewrite failed)")
        continue()
    endif()

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E compare_files "${_fresh}" "${_committed}"
        RESULT_VARIABLE _diff OUTPUT_QUIET ERROR_QUIET)

    math(EXPR _checked "${_checked} + 1")

    if(_diff EQUAL 0)
        message("  ${_name}: up to date")
    else()
        message("  ${_name}: STALE -- ${_name}.cu does not match ${_name}.slang")
        list(APPEND _stale "${_name}")
    endif()
endforeach()

# ---------------------------------------------------------------------------
# The same check for the C++ target
# ---------------------------------------------------------------------------
#
# The CPU arm of "one kernel source" is generated and committed exactly as the CUDA one
# is, so it can go stale in exactly the same way -- and a stale CPU kernel is worse than
# a stale GPU one, because tests/golden/ takes its references from the CPU. A reference
# blessed from maths the source no longer contains would then certify every GPU render
# against the wrong picture.
foreach(_name IN LISTS CPP_SOURCES)
    set(_src       "${SLANG_DIR}/${_name}.slang")
    set(_committed "${GENERATED_DIR}/${_name}.cpp")
    set(_fresh     "${TEMP_DIR}/${_name}.cpp")

    if(NOT EXISTS "${_src}")
        message(FATAL_ERROR "no such Slang source: ${_src}")
    endif()
    if(NOT EXISTS "${_committed}")
        message("  ${_name} (cpp): FAIL -- no committed ${_name}.cpp at all")
        list(APPEND _stale "${_name}.cpp (missing)")
        continue()
    endif()

    execute_process(
        COMMAND "${SLANGC}" "${_src}"
                -target cpp
                -fp-mode ${FP_MODE}
                -line-directive-mode none
                -o "${_fresh}"
        RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err)

    if(NOT _rc EQUAL 0)
        message("  ${_name} (cpp): FAIL -- slangc could not compile it
${_out}${_err}")
        list(APPEND _stale "${_name}.cpp (does not compile)")
        continue()
    endif()

    execute_process(
        COMMAND "${CMAKE_COMMAND}"
                -DGENERATED=${_fresh}
                -DPRELUDE=${CPP_PRELUDE}
                -DSOURCE=${_src}
                -P "${REWRITE}"
        RESULT_VARIABLE _rc OUTPUT_QUIET ERROR_VARIABLE _err)

    if(NOT _rc EQUAL 0)
        message("  ${_name} (cpp): FAIL -- the prelude rewrite refused
${_err}")
        list(APPEND _stale "${_name}.cpp (rewrite failed)")
        continue()
    endif()

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E compare_files "${_fresh}" "${_committed}"
        RESULT_VARIABLE _diff OUTPUT_QUIET ERROR_QUIET)

    math(EXPR _checked "${_checked} + 1")

    if(_diff EQUAL 0)
        message("  ${_name} (cpp): up to date")
    else()
        message("  ${_name} (cpp): STALE -- ${_name}.cpp does not match ${_name}.slang")
        list(APPEND _stale "${_name}.cpp")
    endif()
endforeach()

if(_stale)
    string(REPLACE ";" ", " _list "${_stale}")
    message(FATAL_ERROR
        "\nGENERATED CUDA HAS DRIFTED FROM ITS SLANG SOURCE: ${_list}\n"
        "\n"
        "  The committed .cu is what SHIPS -- Slang is only needed to regenerate it.\n"
        "  So a stale file means the tests above this one, the golden images, and the\n"
        "  plugin itself are all exercising maths that is no longer in the source.\n"
        "\n"
        "  Usually this means a .slang was edited on a machine without Slang, where\n"
        "  the build cannot regenerate and says nothing. Build again with Slang\n"
        "  present and COMMIT THE REGENERATED FILE with the source change.\n"
        "\n"
        "  If it persists with Slang present, the cause is a flag difference or a\n"
        "  slangc version difference -- check the version reported at configure time,\n"
        "  because a compiler upgrade changes the output bits.\n")
endif()

message("${_checked} generated source(s) match their Slang.")
