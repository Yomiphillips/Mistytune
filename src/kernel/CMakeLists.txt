# The renderer.
#
# ZERO AE HEADERS -- the same rule src/engine/ lives under, and for a sharper
# reason: this is what makes golden images possible. The effect hands the kernel a
# plain struct of physics constants and a camera; src/cli/ hands it the same
# struct. Neither could, if the struct's own header needed a host to compile.
#
# Target name is deliberately generic, so the build scripts need no edit when the
# plugin is renamed.

set(PLUGIN_KERNEL_SOURCES
    RenderRequest.h     # what the renderer is told
    Shading.h           # the per-pixel maths, compiled for BOTH paths
    KernelApi.h         # the only thing the host calls
    CpuRender.cpp       # the CPU loop around Shading.h
)

if(PLUGIN_CUDA_FOUND)
    # Mistytune.cu supplies cudaAvailable(), deviceDescription(), renderCuda() and
    # lastCudaError(). CudaStub.cpp supplies the same four when there is no
    # toolkit. EXACTLY ONE OF THEM IS EVER COMPILED -- both would be a duplicate
    # symbol at link time, which is the correct failure for that mistake.
    list(APPEND PLUGIN_KERNEL_SOURCES Mistytune.cu)
else()
    list(APPEND PLUGIN_KERNEL_SOURCES CudaStub.cpp)
endif()

add_library(plugin_kernel STATIC ${PLUGIN_KERNEL_SOURCES})

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
