# Tier 2: golden images, rendered through src/cli and compared with tolerance.
#
# ===========================================================================
# WHAT THIS TIER CATCHES THAT tests/unit/ CANNOT.
#
# The unit tests exercise the parameter model, the cache policy and the contour
# extraction -- everything whose answer does not depend on a renderer. They say
# nothing at all about whether the renderer produces the right pixels, and they
# cannot, because they never run it.
#
# This tier renders fixed scenes and compares them. It is what catches:
#
#   * kernel regressions -- a change to the transport that alters the image
#   * cross-platform float divergence -- MSVC and clang contracting differently,
#     which is why -ffp-contract=off is in the top-level CMakeLists and why
#     --fmad=false is in cmake/Cuda.cmake
#   * NON-DETERMINISM, which is the one PLAN.md calls a project-killer
#
# NO GPU AND NO AFTER EFFECTS. Everything here runs through mistytunec, which
# links the same kernel the effect does. That is the entire reason the CLI was
# built in the same week as the kernel rather than later as a convenience.
# ===========================================================================

if(NOT TARGET mistytunec)
    message(STATUS "Golden tests: skipped (mistytunec not built).")
    return()
endif()

set(GOLDEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/reference")
set(GOLDEN_OUT "${CMAKE_CURRENT_BINARY_DIR}/out")

# BOTH directories, and the source one matters as much as the build one:
# mistytunec writes a file, it does not create the path to it, so a fresh clone
# whose reference/ has not been committed yet would fail the bless target with
# "could not write" rather than with anything that names the missing directory.
file(MAKE_DIRECTORY "${GOLDEN_OUT}")
file(MAKE_DIRECTORY "${GOLDEN_DIR}")

# ---------------------------------------------------------------------------
# THE SCENES.
#
# Small on purpose -- 128x72 at 24 samples. These are committed to the
# repository, and .gitignore's own comment is right that a binary in git is a
# binary in git forever, so each one is 27 KB rather than a megabyte. A
# regression that does not show at 128x72 is not a regression anyone would see.
#
# Each scene exists to hold a DIFFERENT part of the renderer still:
#
#   midday   the ordinary case, and the one that moves if anything at all in the
#            transport changes
#   sunset   the low-sun path: long slant paths, strong wavelength-dependent
#            extinction, the part most sensitive to a float-precision change
#   horizon  looking at the horizon, where the ray-sphere intersection is at its
#            worst-conditioned and where the altitude parameterisation earns its
#            keep. This is the scene that would have caught the flat-earth
#            altitude bug in the prototype.
# ---------------------------------------------------------------------------
#
# Declared through a function taking ARGN rather than as a list of packed
# strings. A packed "name::args" string has to be split back apart, and CMake
# splits on the semicolons INSIDE the arguments at the same time -- so the scene
# ends up named "128" and the failure reads as a missing reference file.

# TOLERANCE IS A MAXIMUM PER-CHANNEL DIFFERENCE, NOT A MEAN. See comparePpm() in
# src/cli/Main.cpp for why a mean-based threshold cannot catch the failures worth
# catching.
#
# 2/255 absorbs the last-bit rounding differences between MSVC and clang on the
# same arithmetic. It does not absorb a changed algorithm: every bug found while
# building the prototype moved pixels by tens or hundreds of levels.
set(GOLDEN_TOLERANCE 2 CACHE STRING "Max per-channel difference for golden comparisons")

# Collects the bless commands as it goes, so the scene list is written once.
set_property(GLOBAL PROPERTY MT_GOLDEN_BLESS "")

# --cpu IS PASSED EXPLICITLY, AND IT HAS TO BE.
#
# mistytunec renders on the GPU BY DEFAULT when a device is present. The CPU path
# is the correctness reference -- it is what these references were blessed from and
# what the determinism tripwires are about -- so leaving the flag off would silently
# change what this suite checks the moment someone builds on a machine with a card.
# The GPU gets its own comparisons below, against the same references.
function(add_golden_scene NAME)
    if(EXISTS "${GOLDEN_DIR}/${NAME}.ppm")
        add_test(NAME golden.${NAME}
                 COMMAND mistytunec ${ARGN} --cpu
                         --compare "${GOLDEN_DIR}/${NAME}.ppm"
                         --tolerance ${GOLDEN_TOLERANCE})

        # THE CROSS-PATH COMPARISON, which could not be written until the kernel
        # could run outside After Effects. Same scene, same reference, GPU instead
        # of CPU -- so a divergence is a divergence in the compiler or the flags,
        # never in somebody's second attempt at the maths.
        #
        # --require-gpu because a fallback to the CPU here would turn this into a
        # duplicate of the test above and report green while checking nothing.
        #
        # MEASURED at the time of writing: all three scenes compare max 0 against
        # CPU-blessed references -- byte-identical, not merely within tolerance.
        # The tolerance is kept anyway: it is there for the transcendental library
        # differences that a future toolkit or card may introduce, and those are
        # exactly what this test exists to keep inside a bound.
        if(PLUGIN_CUDA_FOUND)
            add_test(NAME golden.gpu.${NAME}
                     COMMAND mistytunec ${ARGN} --require-gpu
                             --compare "${GOLDEN_DIR}/${NAME}.ppm"
                             --tolerance ${GOLDEN_TOLERANCE})
        endif()
    else()
        # A MISSING REFERENCE IS A FAILING TEST, NOT A SKIPPED ONE. A suite that
        # quietly passes because its references were never generated is worse
        # than no suite: it reports green while checking nothing at all.
        add_test(NAME golden.${NAME}
                 COMMAND ${CMAKE_COMMAND} -E env
                         "${CMAKE_COMMAND}" -E false)
        message(STATUS
            "Golden reference missing (${NAME}.ppm) -- golden.${NAME} will FAIL "
            "until you run: cmake --build . --target golden-bless")
    endif()

    get_property(_bless GLOBAL PROPERTY MT_GOLDEN_BLESS)
    # BLESSED FROM THE CPU PATH, for the same reason the comparison runs there: the
    # reference must not depend on whether the machine that blessed it had a GPU.
    list(APPEND _bless "COMMAND" "$<TARGET_FILE:mistytunec>" ${ARGN} "--cpu"
                       "-o" "${GOLDEN_DIR}/${NAME}.ppm")
    set_property(GLOBAL PROPERTY MT_GOLDEN_BLESS "${_bless}")
endfunction()

add_golden_scene(midday  -w 128 -h 72 -s 24 --sun-el 45 --sun-az 135)
add_golden_scene(sunset  -w 128 -h 72 -s 24 --sun-el 2  --sun-az 180 --ev 1.5)
add_golden_scene(horizon -w 128 -h 72 -s 24 --sun-el 12 --sun-az 90  --turbidity 6)

# ---------------------------------------------------------------------------
# DETERMINISM.
#
# PLAN.md: "seeds come from (frame, sample index, pixel) and nothing else --
# never a clock, a thread id, or a counter shared between launches. The tripwire
# is in tests/golden/: the same inputs rendered twice, and rendered again with a
# different worker count, must compare identical."
#
# These two are that tripwire, and note that they compare BYTE-IDENTICAL rather
# than within tolerance. There is no rounding to absorb here: it is the same
# binary on the same machine, so any difference at all is a real one.
# ---------------------------------------------------------------------------

set(_det_args -w 96 -h 54 -s 16 --sun-el 20)

# Same inputs, twice. Catches a clock, a global counter, or anything else
# carried between runs.
add_test(NAME determinism.repeatable
         COMMAND ${CMAKE_COMMAND}
                 -DMISTYTUNEC=$<TARGET_FILE:mistytunec>
                 -DOUT_DIR=${GOLDEN_OUT}
                 -DMODE=repeat
                 -P "${CMAKE_CURRENT_SOURCE_DIR}/RunDeterminism.cmake")

# One worker versus eight. Catches a thread id in a seed, a race in the
# accumulator, and a band boundary that does not tile -- all of which are
# invisible on a single-threaded run and all of which MFR would expose in front
# of a user, because AE picks the worker count and we do not get a say.
add_test(NAME determinism.threadCount
         COMMAND ${CMAKE_COMMAND}
                 -DMISTYTUNEC=$<TARGET_FILE:mistytunec>
                 -DOUT_DIR=${GOLDEN_OUT}
                 -DMODE=threads
                 -P "${CMAKE_CURRENT_SOURCE_DIR}/RunDeterminism.cmake")

# GPU BANDING MUST NOT CHANGE THE IMAGE. See the mode in RunDeterminism.cmake --
# this is the only test that exercises the band-as-window offset the effect relies
# on for every frame it renders.
if(PLUGIN_CUDA_FOUND)
    add_test(NAME determinism.gpuBands
             COMMAND ${CMAKE_COMMAND}
                     -DMISTYTUNEC=$<TARGET_FILE:mistytunec>
                     -DOUT_DIR=${GOLDEN_OUT}
                     -DMODE=gpubands
                     -P "${CMAKE_CURRENT_SOURCE_DIR}/RunDeterminism.cmake")
endif()

# A different seed MUST give a different image. Without this, a renderer that
# ignored the seed entirely would pass both tests above with full marks -- the
# most determinstic renderer of all is one that always returns black.
add_test(NAME determinism.seedMatters
         COMMAND ${CMAKE_COMMAND}
                 -DMISTYTUNEC=$<TARGET_FILE:mistytunec>
                 -DOUT_DIR=${GOLDEN_OUT}
                 -DMODE=seed
                 -P "${CMAKE_CURRENT_SOURCE_DIR}/RunDeterminism.cmake")

# ---------------------------------------------------------------------------
# Blessing.
#
# `cmake --build . --target golden-bless` re-renders every reference.
#
# IT IS A SEPARATE TARGET AND NOT AUTOMATIC, deliberately. A suite that
# regenerated its own references whenever they failed would agree with every
# change ever made, including the wrong ones. Blessing is a decision: LOOK at the
# new image, convince yourself the change was intended, and only then run this.
# ---------------------------------------------------------------------------
get_property(GOLDEN_BLESS_COMMANDS GLOBAL PROPERTY MT_GOLDEN_BLESS)

add_custom_target(golden-bless
    COMMAND ${CMAKE_COMMAND} -E make_directory "${GOLDEN_DIR}"
    ${GOLDEN_BLESS_COMMANDS}
    DEPENDS mistytunec
    COMMENT "Re-rendering golden references into ${GOLDEN_DIR}"
    VERBATIM)
