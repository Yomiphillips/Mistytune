# The renderer.
#
# ZERO AE HEADERS -- the same rule src/engine/ lives under, and for a sharper
# reason: this is what makes golden images possible. The effect hands the kernel a
# plain struct of physics constants and a camera; src/cli/ hands it the same
# struct. Neither could, if the struct's own header needed a host to compile.
#
# Target name is deliberately generic, so the build scripts need no edit when the
# plugin is renamed.

# ---------------------------------------------------------------------------
# The renderer, from ONE Slang source to both backends
# ---------------------------------------------------------------------------
#
# PLAN.md's central bet, and this is where it reaches the shipping binary.
# RenderLib.slang is the renderer; Render.slang and RenderCpu.slang are two entry
# points over it, compiled to CUDA and to C++ respectively, and included as SOURCE by
# Mistytune.cu and CpuRender.cpp so each can call into it.
#
# TWO FILES FOR ONE RENDERER because slangc marks entry points `extern "C"` and both
# objects land in this library -- identical names would be one symbol and the link
# would fail. See Render.slang's header; CpuParity.slang hit it first.
#
# THE TRAILING ARGUMENTS ARE THE #include'd SOURCES AND A MISSING ONE IS A STALE
# COMMITTED ARTIFACT. CMake cannot see through an #include, so leaving a name out
# means editing that file regenerates nothing, the build succeeds, the tests pass,
# and what ships is the old maths. slang.regenerates is the backstop.
set(SLANG_DIR       "${CMAKE_CURRENT_SOURCE_DIR}/slang")
set(SLANG_GENERATED "${SLANG_DIR}/generated")

set(PLUGIN_SLANG_RENDER_DEPS
    "${SLANG_DIR}/RenderLib.slang"
    "${SLANG_DIR}/BounceLib.slang"
    "${SLANG_DIR}/TransportLib.slang"
    "${SLANG_DIR}/GeneratorLib.slang"
    "${SLANG_DIR}/OrganizationLib.slang"
    "${SLANG_DIR}/ConvectionLib.slang"
    "${SLANG_DIR}/PhaseLib.slang"
    "${SLANG_DIR}/SkyLib.slang"
    "${SLANG_DIR}/AirMapLib.slang"
    "${SLANG_DIR}/LightLib.slang"
    "${SLANG_DIR}/Rng.slang")

slang_generate("${SLANG_DIR}/Render.slang"
               "${SLANG_GENERATED}/Render.cu"
               "../prelude/slang-cuda-prelude.h"
               ${PLUGIN_SLANG_RENDER_DEPS})

slang_generate_cpp("${SLANG_DIR}/RenderCpu.slang"
                   "${SLANG_GENERATED}/RenderCpu.cpp"
                   "../prelude/slang-cpp-prelude.h"
                   ${PLUGIN_SLANG_RENDER_DEPS})

set(PLUGIN_KERNEL_SOURCES
    RenderRequest.h     # what the renderer is told
    Shading.h           # the per-pixel maths, compiled for BOTH paths
    SlangBridge.h       # RenderRequest -> the kernel's structs, written ONCE
    KernelApi.h         # the only thing the host calls
    CpuRender.cpp       # the CPU loop around Shading.h
    GroundSkyLight.cpp  # the ground's skylight, integrated on the host
    StylizedFrame.h     # the Stylized look (build 32): one frame's bakes, and reading them
    StylizedPlan.h      #   where its grids lie, and its constants
    StylizedHost.h      #   the frame built from the scene
    StylizedShading.h   #   the light and the march, for BOTH paths
    StylizedPasses.h    #   the passes each backend runs
    StylizedCpu.cpp     #   ...on the CPU

    # Generated, committed, and #included as source rather than compiled on their
    # own -- see HEADER_FILE_ONLY below. Listed here so the custom commands that
    # regenerate them are attached to this target and run before it builds.
    "${SLANG_GENERATED}/RenderCpu.cpp"
)

if(PLUGIN_CUDA_FOUND)
    list(APPEND PLUGIN_KERNEL_SOURCES "${SLANG_GENERATED}/Render.cu")
endif()

if(PLUGIN_CUDA_FOUND)
    # Mistytune.cu supplies cudaAvailable(), deviceDescription(), renderCuda() and
    # lastCudaError(). CudaStub.cpp supplies the same four when there is no
    # toolkit. EXACTLY ONE OF THEM IS EVER COMPILED -- both would be a duplicate
    # symbol at link time, which is the correct failure for that mistake.
    list(APPEND PLUGIN_KERNEL_SOURCES Mistytune.cu StylizedCuda.cu)
else()
    list(APPEND PLUGIN_KERNEL_SOURCES CudaStub.cpp)
endif()

add_library(plugin_kernel STATIC ${PLUGIN_KERNEL_SOURCES})

# NEITHER GENERATED FILE IS ITS OWN TRANSLATION UNIT. Both are #included as source --
# Render.cu by Mistytune.cu, RenderCpu.cpp by CpuRender.cpp -- because slangc emits
# everything below an entry point `static`, so a separately compiled object would
# expose only the compute kernel and not the function a pixel needs to call.
#
# Compiling them as well would define `renderRays` and `cpuRenderRays` twice.
set_source_files_properties("${SLANG_GENERATED}/Render.cu"
                            "${SLANG_GENERATED}/RenderCpu.cpp"
                            PROPERTIES HEADER_FILE_ONLY ON)

target_include_directories(plugin_kernel PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# The parameter model. PUBLIC because RenderRequest.h -- which every caller
# includes -- includes CloudParams.h out of it.
target_link_libraries(plugin_kernel PUBLIC plugin_engine)

set_target_properties(plugin_kernel PROPERTIES LINKER_LANGUAGE CXX)

if(PLUGIN_CUDA_FOUND)
    set_target_properties(plugin_kernel PROPERTIES
        CUDA_ARCHITECTURES "${PLUGIN_CUDA_ARCHITECTURES}"

        # SEPARABLE COMPILATION OFF. Everything the kernel calls is an inline
        # function in Shading.h, so there is nothing to link between translation
        # units -- and whole-program compilation is what lets nvcc inline
        # renderPixel() into the kernel body. Turning it on would cost real
        # performance for a facility this does not use.
        CUDA_SEPARABLE_COMPILATION OFF

        # POSITION-INDEPENDENT CODE, because this static library is linked into a
        # shared one (.aex is a DLL, .plugin is a bundle). On Linux and macOS the
        # link fails without it; on Windows it is a no-op. Set here rather than
        # globally so the CLI does not pay for it.
        POSITION_INDEPENDENT_CODE ON)

    # Determinism flags, from cmake/Cuda.cmake. --fmad=false is the one that
    # matters: nvcc contracts a*b + c*d into an FMA by default and MSVC does not,
    # so leaving it on makes the CPU reference and the GPU disagree in the last
    # bits -- and tests/golden/ compares them.
    target_compile_options(plugin_kernel PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:${PLUGIN_CUDA_FLAGS}>)

    # The CUDA runtime. STATIC, so the built .aex does not need cudart64_*.dll
    # beside it -- a missing DLL is how a plugin fails to load on Windows while
    # saying nothing at all, which docs/HOST-NOTES.md records happening with the
    # VC++ redistributable for exactly the same reason.
    target_link_libraries(plugin_kernel PRIVATE CUDA::cudart_static)

    message(STATUS "plugin_kernel: CUDA path (arch ${PLUGIN_CUDA_ARCHITECTURES})")
else()
    message(STATUS "plugin_kernel: CPU reference path only (no CUDA).")
endif()
