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
    # A SCENE THE PROPERTY CAN ACTUALLY FAIL IN, which this test did not have until
    # 2026-09-28. It ran on the suite's shared 96x54 sky at sun elevation 20 -- smooth
    # enough that a per-band change in the sampler's jitter moved no pixel by a whole
    # level -- and so it compared byte-identical for weeks while the sampler really was
    # seeded per band. The sun disc is where sub-pixel differences become whole levels,
    # so the scene now contains one.
    set(SCENE -w 256 -h 144 -s 8 --sun-el 12)

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

elseif(MODE STREQUAL "gpustaged")
    # THE STAGED GPU RENDER AGAINST THE SINGLE KERNEL (build 25).
    #
    # The staged render traces a launch's samples one bounce per launch, gathering the
    # paths still alive each time; the single kernel traces each pixel's paths start to
    # finish. Same arithmetic per path, so the two must agree to the bit -- which is the
    # claim that lets the staged render ship without new goldens.
    #
    # A CUMULUS LAYER WITH A HERO, Draft's shadow hand-off on, and bands and sample chunks,
    # because that is where the paths are long and differ: a sky alone would end every path
    # at its first bounce and compare the two kernels on nothing.
    set(SCENE -w 128 -h 72 -s 6 --hero 1 --coverage 0.6 --hero-connection 0.6
              --orbit 0 --sun-placement backlit --shadow-handoff 2)

    gpu_render("${OUT_DIR}/gpu_staged.ppm" --gpu-band-rows 37 --sample-chunk 4)
    gpu_render("${OUT_DIR}/gpu_single.ppm" --gpu-band-rows 37 --sample-chunk 4 --megakernel)

    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E compare_files
                "${OUT_DIR}/gpu_staged.ppm" "${OUT_DIR}/gpu_single.ppm"
        RESULT_VARIABLE _same)
    if(NOT _same EQUAL 0)
        message(FATAL_ERROR
            "THE STAGED GPU RENDER DIFFERS FROM THE SINGLE KERNEL.\n"
            "  Each path must be pathBegin and then pathBounce until it ends, exactly as\n"
            "  trace() runs them, and the finish must sum a pixel's samples in sample\n"
            "  order. Look at what renderStaged() hands each kernel, and at the path index.")
    endif()
    message(STATUS "gpu staged: identical to the single kernel")

elseif(MODE STREQUAL "gpubandchunks")
    # ===================================================================
    # BANDS *AND* SAMPLE CHUNKS TOGETHER, WHICH NEITHER OF THE TWO TESTS ABOVE
    # EXERCISES AND WHICH IS THE ONLY CONFIGURATION THE FRAME-SIZED ACCUMULATOR
    # CHANGES.
    #
    # The accumulator exists only when a render is SPLIT BY SAMPLES. Its base pointer
    # is offset by the band's first row, so the offset is only non-zero when the render
    # is ALSO split by BANDS.
    #
    #   determinism.gpuBands    bands, one sample launch  -> no accumulator at all
    #   determinism.sampleChunks  chunks, one band        -> offset is always zero
    #
    # So a wrong offset passes both of them with full marks. That is the fourth time
    # this project has met the band-as-window hazard -- the reduced-resolution render
    # that drew the top-left third, the Region of Interest that drew the top-left
    # corner, the band offset in renderCudaToHost itself -- and the first time a test
    # has been written for it BEFORE a human found it in After Effects.
    #
    # WHAT A WRONG OFFSET LOOKS LIKE: every band accumulating into the frame's first
    # rows, so the top of the picture is the sum of every band and the rest is a single
    # launch. It renders. It looks like a banding or exposure bug.
    #
    # 37 ROWS AND CHUNKS OF 1, the harshest of both settings, on a scene with a sun
    # disc -- because sub-pixel differences only become whole levels where there is an
    # edge, and this test's ancestor compared byte-identical for weeks on a smooth sky
    # while the sampler really was seeded per band.
    # ===================================================================
    set(SCENE -w 256 -h 144 -s 8 --sun-el 12)

    gpu_render("${OUT_DIR}/gpu_bc_whole.ppm")
    gpu_render("${OUT_DIR}/gpu_bc_split.ppm" --gpu-band-rows 37 --sample-chunk 1)

    # WITH TOLERANCE, NOT BYTE-FOR-BYTE, and for the reason determinism.sampleChunks
    # gives: splitting the samples REGROUPS a floating-point sum and addition is not
    # associative. A misplaced accumulator is not a rounding difference -- it moves
    # whole bands -- so 2 levels is nowhere near loose enough to hide one.
    execute_process(
        COMMAND "${MISTYTUNEC}" ${SCENE} --require-gpu
                --gpu-band-rows 37 --sample-chunk 1
                --compare "${OUT_DIR}/gpu_bc_whole.ppm" --tolerance 2
        RESULT_VARIABLE _same OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
    if(NOT _same EQUAL 0)
        message(FATAL_ERROR
            "BANDED + CHUNKED RENDER DISAGREES WITH THE WHOLE FRAME.
"
            "  The accumulator is frame-sized and each band is handed the slice that
"
            "  starts at its first row. If that offset is wrong, every band accumulates
"
            "  into the top of the frame.
"
            "  See renderCudaToHost() in src/kernel/Mistytune.cu.
${_out}${_err}")
    endif()
    message(STATUS "gpu bands + sample chunks: matches the whole frame")

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

elseif(MODE STREQUAL "window")
    # A WINDOW OF THE FRAME MUST MATCH THE SAME PATCH OF THE WHOLE FRAME.
    #
    # This is the test that three separate shipped bugs were all waiting for. The
    # destination buffer is routinely a sub-rect -- a Region of Interest, a CUDA band,
    # a reduced-resolution proxy -- and each time the number saying WHERE that rect
    # sits came from the wrong place, the effect rendered the top-left corner of the
    # picture into a buffer the host composited somewhere else. Every one of them was
    # found by a human looking at After Effects, because nothing headless could ask
    # for a window until --window existed.
    #
    # A SCENE WITH THE SUN IN IT, AND THAT IS NOT DECORATION. The first thing this
    # test caught was the sampler being seeded from the BUFFER pixel instead of the
    # FRAME pixel, which changes only the sub-pixel jitter -- invisible across a smooth
    # gradient and worth 190 levels of 255 at the edge of the sun disc. determinism
    # .gpuBands had been asserting a neighbouring property for weeks against a scene
    # too smooth to show it, and passed throughout. A test can only catch what its
    # scene can show.
    set(WINDOW_SCENE -w 256 -h 144 -s 8 --sun-el 12)

    foreach(_engine --cpu --require-gpu)
        if(_engine STREQUAL "--require-gpu" AND NOT WITH_GPU)
            continue()
        endif()

        execute_process(
            COMMAND "${MISTYTUNEC}" ${WINDOW_SCENE} ${_engine}
                    -o "${OUT_DIR}/window_full.ppm"
            RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
        if(NOT _rc EQUAL 0)
            message(FATAL_ERROR "mistytunec ${_engine} failed (${_rc}):\n${_out}\n${_err}")
        endif()

        # DELIBERATELY AWKWARD: 90,50 is not a multiple of the kernel's 16-row block
        # and 120x70 does not tile the frame, so a window that lined up with the block
        # grid cannot pass by accident.
        execute_process(
            COMMAND "${MISTYTUNEC}" ${WINDOW_SCENE} ${_engine} --window 90 50 120 70
                    --compare "${OUT_DIR}/window_full.ppm" --compare-at 90 50
                    --tolerance 2
            RESULT_VARIABLE _same OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
        if(NOT _same EQUAL 0)
            message(FATAL_ERROR
                "A WINDOW DOES NOT MATCH THE FRAME on ${_engine}.\n"
                "${_out}${_err}"
                "  The buffer is a WINDOW, not a crop: view.originX/Y must reach BOTH\n"
                "  the ray direction and the sampler seed, or the same frame pixel gets\n"
                "  a different answer depending on how the frame was divided.\n"
                "  Reaches a user as a Region of Interest that disagrees with the\n"
                "  picture underneath it, or as banding seams across a frame.")
        endif()

        # THE CONTROL. Comparing the window against the WRONG patch must fail, or the
        # comparison above is not actually looking at position at all.
        execute_process(
            COMMAND "${MISTYTUNEC}" ${WINDOW_SCENE} ${_engine} --window 90 50 120 70
                    --compare "${OUT_DIR}/window_full.ppm" --compare-at 0 0
                    --tolerance 2
            RESULT_VARIABLE _differs OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
        if(_differs EQUAL 0)
            message(FATAL_ERROR
                "POSITION IGNORED on ${_engine}: the window matched the frame's\n"
                "  top-left corner as well as its own position, so the test above\n"
                "  proves nothing about where anything was rendered.")
        endif()

        message(STATUS "window (${_engine}): matches its own patch, and not another")
    endforeach()

elseif(MODE STREQUAL "samplechunks")
    # ACCUMULATION ACROSS LAUNCHES MUST NOT CHANGE THE PICTURE.
    #
    # Above about a thousand samples per pixel the row bands hit their floor and one
    # launch would sit past the Windows display-driver timeout, so the samples are
    # split too and the partial sums are carried in an accumulator between launches.
    # That accumulator is the only piece of state in the renderer that outlives a
    # launch, which makes it the only place a frame can be silently half-rendered.
    #
    # A SCENE WITH SOMETHING TO CONVERGE. 64 samples, not the suite's usual 16: the
    # sun disc and the horizon edge are where sample count actually shows, and a
    # comparison of two already-converged skies would pass whatever the accumulator
    # did.
    #
    # --sample-chunk 1 IS THE HARSHEST SETTING, not a gentle one: 64 launches each
    # responsible for a single sample, so every one of them has to read what the last
    # left behind. The obvious ways to break this -- keeping only the last chunk,
    # re-initialising every launch, weighting by the chunk instead of the running
    # total -- all produce a 1-sample image, which the control below measures at 206
    # levels away.
    set(CHUNK_SCENE -w 96 -h 54 -s 64 --sun-el 20)

    foreach(_engine --cpu --require-gpu)
        if(_engine STREQUAL "--require-gpu" AND NOT WITH_GPU)
            continue()
        endif()

        execute_process(
            COMMAND "${MISTYTUNEC}" ${CHUNK_SCENE} ${_engine}
                    -o "${OUT_DIR}/chunk_whole.ppm"
            RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
        if(NOT _rc EQUAL 0)
            message(FATAL_ERROR "mistytunec ${_engine} failed (${_rc}):\n${_out}\n${_err}")
        endif()

        # COMPARED WITH TOLERANCE AND NOT BYTE-FOR-BYTE, unlike the tripwires above,
        # and the difference is real rather than defensive. Splitting the samples
        # REGROUPS a floating-point sum, and addition is not associative -- so an exact
        # match is not something this test is entitled to demand, even though every
        # split measured here has in fact produced one.
        execute_process(
            COMMAND "${MISTYTUNEC}" ${CHUNK_SCENE} ${_engine} --sample-chunk 1
                    --compare "${OUT_DIR}/chunk_whole.ppm" --tolerance 2
            RESULT_VARIABLE _same OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
        if(NOT _same EQUAL 0)
            message(FATAL_ERROR
                "ACCUMULATION IS LOSSY: 64 samples in one launch and 64 samples in 64\n"
                "  launches disagree on ${_engine}.\n"
                "${_out}${_err}"
                "  The accumulator is not carrying partial sums between launches, or\n"
                "  samplesAlreadyDone is not reaching the weighting in renderPixel.\n"
                "  Reaches a user as a frame that gets NOISIER the more samples they\n"
                "  ask for, because only the last chunk survives.")
        endif()

        # THE CONTROL, AND THIS TEST IS WORTHLESS WITHOUT IT. The comparison above
        # passes trivially if the sample count does not reach the image at all. One
        # sample against sixty-four must therefore FAIL the same tolerance.
        execute_process(
            COMMAND "${MISTYTUNEC}" -w 96 -h 54 -s 1 --sun-el 20 ${_engine}
                    --compare "${OUT_DIR}/chunk_whole.ppm" --tolerance 2
            RESULT_VARIABLE _differs OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
        if(_differs EQUAL 0)
            message(FATAL_ERROR
                "SAMPLE COUNT IGNORED on ${_engine}: 1 sample and 64 samples produced\n"
                "  the same image, so the chunk comparison above proves nothing.")
        endif()

        message(STATUS "sample chunks (${_engine}): 64x1 matches 64, and 1 does not")
    endforeach()

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
