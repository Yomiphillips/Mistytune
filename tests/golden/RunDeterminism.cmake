# Determinism checks, run by ctest through `cmake -P`.
#
# IN CMAKE SCRIPT MODE RATHER THAN AS A SHELL SCRIPT so that the suite runs
# unchanged on Windows and macOS. The alternative -- a .ps1 and a .sh kept in
# step by hand -- is the same trap PLAN.md rejects for the kernel, on a smaller
# scale: two files that must agree and no way to notice when they stop.
#
# Expects: MISTYTUNEC, OUT_DIR, MODE.

if(NOT MISTYTUNEC OR NOT OUT_DIR OR NOT MODE)
    message(FATAL_ERROR "RunDeterminism.cmake needs -DMISTYTUNEC -DOUT_DIR -DMODE")
endif()

file(MAKE_DIRECTORY "${OUT_DIR}")

# Small and cheap: these tests are about whether two runs AGREE, not about image
# quality, so the resolution only has to be large enough that a race has somewhere
# to show up.
set(SCENE -w 96 -h 54 -s 16 --sun-el 20)

function(render OUTFILE)
    execute_process(
        # --cpu: these tripwires are about the CPU worker pool and the seed, and
        # mistytunec now uses the GPU by default. Without this, --threads would be
        # silently ignored and determinism.threadCount would compare two identical
        # GPU renders -- a test that cannot fail.
        COMMAND "${MISTYTUNEC}" ${SCENE} --cpu ${ARGN} -o "${OUTFILE}"
        RESULT_VARIABLE _rc
        OUTPUT_VARIABLE _out
        ERROR_VARIABLE  _err)
    if(NOT _rc EQUAL 0)
        message(FATAL_ERROR "mistytunec failed (${_rc}):\n${_out}\n${_err}")
    endif()
endfunction()

# THE GPU TWIN OF render(). --require-gpu rather than a silent fallback: a GPU test
# that rendered on the CPU would compare two CPU images and pass while checking
# nothing at all.
function(gpu_render OUTFILE)
    execute_process(
        COMMAND "${MISTYTUNEC}" ${SCENE} --require-gpu ${ARGN} -o "${OUTFILE}"
        RESULT_VARIABLE _rc
        OUTPUT_VARIABLE _out
        ERROR_VARIABLE  _err)
    if(NOT _rc EQUAL 0)
        message(FATAL_ERROR "mistytunec --require-gpu failed (${_rc}):\n${_out}\n${_err}")
    endif()
endfunction()

if(MODE STREQUAL "repeat")
    # THE SAME COMMAND TWICE. Anything carried between runs -- a clock, a global
    # counter, an uninitialised buffer -- shows up here and nowhere else.
    render("${OUT_DIR}/repeat_a.ppm" --threads 4)
    render("${OUT_DIR}/repeat_b.ppm" --threads 4)

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E compare_files
                "${OUT_DIR}/repeat_a.ppm" "${OUT_DIR}/repeat_b.ppm"
        RESULT_VARIABLE _same)
    if(NOT _same EQUAL 0)
        message(FATAL_ERROR
            "NON-DETERMINISTIC: the same arguments produced two different images.\n"
            "  A seed is coming from somewhere other than (frame, sample, pixel) --\n"
            "  a clock, a thread id, or a counter shared between launches.\n"
            "  Motion blur renders one frame several times and MFR renders frames on\n"
            "  different workers, so this reaches a user as flicker.")
    endif()
    message(STATUS "repeatable: identical")

elseif(MODE STREQUAL "gpubands")
    # BANDED VERSUS WHOLE-FRAME, ON THE GPU.
    #
    # The effect never renders a frame in one launch: it goes in bands of rows so it
    # can check After Effects' abort between them and so no single launch approaches
    # the Windows display-driver timeout. A band is a WINDOW into the frame -- the
    # device buffer holds only those rows, and view.originY is moved down by the band
    # start so every ray still knows which row of the full picture it is.
    #
    # GET THAT WRONG AND EVERY BAND RENDERS THE TOP OF THE FRAME, which a whole-frame
    # render cannot show because it has exactly one band. This is the only test that
    # exercises it.
    #
    # 37 ROWS IS DELIBERATELY AWKWARD: not a divisor of 54 and not a multiple of the
    # kernel's 16-row block, so the last band is short and the block grid does not
    # line up with the band edges. A band size that divided evenly would pass while
    # hiding an off-by-one at the boundary.
    gpu_render("${OUT_DIR}/gpu_whole.ppm")
    gpu_render("${OUT_DIR}/gpu_banded.ppm" --gpu-band-rows 37)

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E compare_files
                "${OUT_DIR}/gpu_whole.ppm" "${OUT_DIR}/gpu_banded.ppm"
        RESULT_VARIABLE _same)
    if(NOT _same EQUAL 0)
        message(FATAL_ERROR
            "GPU BANDING CHANGES THE IMAGE: one launch and banded launches disagree.\n"
            "  The band is a window, not a crop. renderCudaToHost() must offset\n"
            "  view.originY by the band's first row, or each band renders the top of\n"
            "  the frame into a different part of the output.\n"
            "  Reaches a user as horizontal stripes of repeated sky.")
    endif()
    message(STATUS "gpu bands: identical to a single launch")

elseif(MODE STREQUAL "threads")
    # ONE WORKER VERSUS EIGHT. After Effects picks the worker count under
    # multi-frame rendering and we do not get a say, so the image cannot depend
    # on it.
    render("${OUT_DIR}/threads_1.ppm" --threads 1)
    render("${OUT_DIR}/threads_8.ppm" --threads 8)

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E compare_files
                "${OUT_DIR}/threads_1.ppm" "${OUT_DIR}/threads_8.ppm"
        RESULT_VARIABLE _same)
    if(NOT _same EQUAL 0)
        message(FATAL_ERROR
            "WORKER-COUNT DEPENDENT: one thread and eight gave different images.\n"
            "  Causes, in the order they are usually true: a thread id or an atomic\n"
            "  counter reaching a seed; two threads writing the same pixel; or a row\n"
            "  band whose boundary is computed differently at different counts.\n"
            "  Under MFR this is a frame that changes depending on machine load.")
    endif()
    message(STATUS "thread count: identical at 1 and 8")

elseif(MODE STREQUAL "seed")
    # THE CONTROL FOR THE OTHER TWO. A renderer that ignored the seed -- or that
    # returned a constant -- would pass both of the tests above perfectly. This is
    # what stops "deterministic" from being satisfied by "always the same wrong
    # answer".
    render("${OUT_DIR}/seed_a.ppm" --seed 1)
    render("${OUT_DIR}/seed_b.ppm" --seed 2)

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E compare_files
                "${OUT_DIR}/seed_a.ppm" "${OUT_DIR}/seed_b.ppm"
        RESULT_VARIABLE _same)
    if(_same EQUAL 0)
        message(FATAL_ERROR
            "SEED IGNORED: two different seeds produced an identical image.\n"
            "  The sampler is not reading the seed, so every 'deterministic' result\n"
            "  above is vacuous -- and the variations grid, which re-rolls the seed,\n"
            "  would show nine copies of the same sky.")
    endif()
    message(STATUS "seed: different seeds differ, as they must")

else()
    message(FATAL_ERROR "unknown MODE '${MODE}'")
endif()
