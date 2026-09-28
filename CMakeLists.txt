cmake_minimum_required(VERSION 3.20)

# Plugin identity. Included before project() because the project is NAMED and
# VERSIONED from it. Nothing else in this file mentions the plugin by name.
include(${CMAKE_CURRENT_LIST_DIR}/cmake/PluginConfig.cmake)

# ONE SOURCE FOR THE VERSION, and it is src/ae/Build.h.
#
# The plugin reports its version to AE from that header, the packaging scripts
# name the ZIP from it, and project(VERSION) -- which ends up in the macOS
# Info.plist -- is read out of it here. A second hand-edited copy is how a
# bundle ends up claiming a version it does not contain, so there isn't one.
set(_build_h "${CMAKE_CURRENT_LIST_DIR}/src/ae/Build.h")
file(STRINGS "${_build_h}" _ver_lines
     REGEX "^#define[ \t]+PLUGIN_(MAJOR|MINOR|BUILD)[ \t]+[0-9]+")
foreach(_line IN LISTS _ver_lines)
    if(_line MATCHES "PLUGIN_MAJOR[ \t]+([0-9]+)")
        set(_plugin_major "${CMAKE_MATCH_1}")
    elseif(_line MATCHES "PLUGIN_MINOR[ \t]+([0-9]+)")
        set(_plugin_minor "${CMAKE_MATCH_1}")
    elseif(_line MATCHES "PLUGIN_BUILD[ \t]+([0-9]+)")
        set(_plugin_build "${CMAKE_MATCH_1}")
    endif()
endforeach()
if(NOT DEFINED _plugin_major OR NOT DEFINED _plugin_minor OR NOT DEFINED _plugin_build)
    message(FATAL_ERROR "Could not read PLUGIN_MAJOR/MINOR/BUILD from ${_build_h}")
endif()

# THIS BLOCK MUST STAY ABOVE project(). CMAKE_OSX_* are consumed while project()
# probes the compiler, so setting them afterwards silently does nothing at all
# -- no warning, no error, just a single-architecture build that looks fine
# until `lipo -archs` says otherwise.
#
# Note the guard is CMAKE_HOST_APPLE, not APPLE: APPLE does not exist until
# project() has run, so `if(APPLE)` up here is silently false.
if(CMAKE_HOST_APPLE)
    # Universal, so one download covers Intel and Apple Silicon.
    # Override for a faster local loop: -DCMAKE_OSX_ARCHITECTURES=arm64
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64"
        CACHE STRING "Architectures to build (universal by default)")
    # AE 2023+ is the floor and it already requires macOS 11.
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0"
        CACHE STRING "Minimum macOS version")
endif()

project(${PLUGIN_TARGET}
        VERSION ${_plugin_major}.${_plugin_minor}.0
        LANGUAGES C CXX)

# Re-run CMake when the version changes, so Info.plist cannot go stale.
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_build_h}")

# C++17 rather than 20: MSVC 14.29 (VS2019 16.11) still builds this, and
# nothing here needs C++20. Raise it when your own toolchain floor moves.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    # Conformance mode from commit one, so Windows-only non-conforming code
    # fails now rather than at macOS port time.
    #
    # SCOPED PER LANGUAGE, AND IT HAS TO BE. add_compile_options() applies to EVERY
    # enabled language, and once CUDA is one of them these land on nvcc's own command
    # line rather than the host compiler's. nvcc does not recognise a bare MSVC
    # switch and treats it as another INPUT FILE, so the whole build dies on:
    #
    #     nvcc fatal : A single input file is required for a non-link phase
    #                  when an outputfile is specified
    #
    # which names neither the flag nor the language and reads like a broken source
    # file. Host flags reach nvcc's host compiler only through -Xcompiler.
    #
    # SHELL: keeps the repeated -Xcompiler tokens; without it CMake de-duplicates
    # them and the switches they carry get attached to the wrong one.
    add_compile_options(
        "$<$<COMPILE_LANGUAGE:CXX>:/permissive-;/W4;/utf-8>"
        "$<$<COMPILE_LANGUAGE:CUDA>:SHELL:-Xcompiler /permissive- -Xcompiler /W4 -Xcompiler /utf-8>")
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
else()
    # The clang-side equivalent of /W4. Same reasoning in reverse: keep the
    # warning bar level on both platforms so portability rot surfaces wherever
    # it is introduced rather than at the next port.
    add_compile_options(-Wall -Wextra)

    # Match MSVC's floating-point contraction behaviour. NOT a micro-optimisation
    # knob -- removing this changes render output.
    #
    # clang defaults to -ffp-contract=on and fuses a*b + c*d into an FMA, which
    # keeps one product at higher intermediate precision. MSVC does not contract
    # under its default /fp:precise. The two therefore round differently, and an
    # expression that cancels to exactly zero on Windows can leave a small
    # residue on arm64 -- which is the difference between a pixel-identical
    # cross-platform render and a test suite that only passes on one of them.
    add_compile_options(-ffp-contract=off)
endif()

# Build shape. Declared HERE rather than in src/ae/ because it has to be known
# before any target is created -- it decides how the C runtime is linked, and
# that has to be uniform across the engine, the plugin and the tests.
#
# NOTE: in this plugin the name is historical. There is no hot-reload stub --
# an AEGP entry point is called once at launch and cannot be swapped underneath
# a running host (src/ae/CMakeLists.txt has the full argument). The option now
# selects only the BUILD SHAPE: ON = development (dynamic CRT, PF_Stage_DEVELOP),
# OFF = distribution (static CRT, PF_Stage_BETA). Both emit one binary.
option(PLUGIN_HOT_RELOAD
       "Development build shape: dynamic CRT and PF_Stage_DEVELOP (OFF = distribution)"
       ON)

if(MSVC AND NOT PLUGIN_HOT_RELOAD)
    # STATIC CRT FOR DISTRIBUTION.
    #
    # A dynamically linked build imports MSVCP140.dll and VCRUNTIME140_1.dll. If
    # the user's machine lacks the matching Visual C++ redistributable, AE fails
    # to load the plugin and says NOTHING -- the effect simply never appears in
    # the menu, which is indistinguishable from installing it in the wrong
    # folder. VCRUNTIME140_1.dll is the one that actually bites: it arrived in a
    # later redist than many machines have, so "I have the redistributable"
    # isn't sufficient.
    #
    # Static linking removes the dependency entirely and costs ~100 KB. The
    # usual objection -- allocations crossing a CRT boundary -- does not apply:
    # every build here is a single binary, and anything handed back to AE is
    # allocated through AE's own suites.
    #
    # ANY THIRD-PARTY LIBRARY ADDED LATER MUST BE TIED TO THIS SAME SWITCH.
    # Intel Open Image Denoise is the one coming (Phase 2): a library built on one
    # CRT setting and linked into a plugin on the other gives duplicate-CRT link
    # errors at best, and heap corruption at the first allocation crossing the
    # boundary at worst.
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# macOS needs no equivalent: libc++ is part of the OS, so the release bundle has
# no redistributable to miss.

# The numbers After Effects caches about the effect -- version, out_flags,
# out_flags2 -- computed ONCE and substituted into the generated identity header,
# where a static_assert checks them against the symbolic PF_OutFlag_* constants
# the effect actually sets. MUST come before the configure_file below, which
# consumes them, and after the version read and the PLUGIN_HOT_RELOAD option,
# which it consumes.
include(cmake/EffectFlags.cmake)

# The generated identity header, and the INTERFACE target that puts it on the
# include path. This is what lets every other file avoid hardcoding the name.
configure_file("${CMAKE_CURRENT_LIST_DIR}/cmake/PluginIdentity.h.in"
               "${CMAKE_BINARY_DIR}/generated/PluginIdentity.h" @ONLY)
add_library(plugin_identity INTERFACE)
target_include_directories(plugin_identity INTERFACE "${CMAKE_BINARY_DIR}/generated")

include(cmake/AESDK.cmake)

# NO PiPL STEP, and that is a deliberate simplification over the scaffolding this
# repo grew from.
#
# That predecessor was primarily an AEGP, and an AEGP is discoverable ONLY through
# a 'PiPL' resource naming its entry point -- so it needed the whole .r ->
# PiPLtool -> .rrc -> .rc chain on Windows and Rez on macOS. Mistytune is a plain
# effect, and effects self-register on AE 2023+ through PluginDataEntryFunction2 /
# PF_REGISTER_EFFECT_EXT2.
#
# THE POINT IS NOT THE MISSING BUILD STEP, it is the missing failure mode. A
# PiPL-registered effect states its version and out_flags as raw decimals that AE
# caches and compares against what GLOBAL_SETUP reports; disagree by one bit and
# the plugin refuses to load with a message that prints both halves as "1.0".
# With no PiPL there is only one copy of those numbers, so they cannot disagree.
# cmake/EffectFlags.cmake still computes them -- now feeding only the
# static_assert in the generated identity header.

# CUDA. Optional at configure time: the engine, the tests and the CPU render path
# all build without it, so a machine with no CUDA toolkit still gets a working
# plugin and a green test run -- it just gets the CPU fallback.
include(cmake/Cuda.cmake)

# Slang. Optional in a stronger sense than CUDA is: the GENERATED CUDA IS COMMITTED,
# so Slang is needed to regenerate a kernel after editing its .slang source and never
# to build one. A clone with no Slang builds the same bits that ship.
include(cmake/Slang.cmake)

# Engine and tests build with or without the AE SDK and with or without CUDA --
# see cmake/AESDK.cmake. That is the whole point of the layout: the parameter
# model, the cache policy and the feature extraction are the parts worth testing,
# and they must stay testable on a machine with no Adobe SDK and no GPU on it at
# all.
add_subdirectory(src/engine)

# The renderer. ONE kernel source, cross-compiled -- see src/kernel/CMakeLists.txt
# and PLAN.md's "One kernel source". No-ops into a stub when CUDA is absent.
add_subdirectory(src/kernel)

# The headless renderer: golden images, profiling, EXR bakes.
#
# BUILT IN THE SAME WEEK AS THE KERNEL, per PLAN.md, and not as a later
# convenience. A GPU path tracer that can only run inside After Effects cannot be
# golden-imaged, profiled or bisected -- so the CLI is the test harness first and
# the EXR bake feature second.
#
# BEFORE add_subdirectory(tests), and that ordering is load-bearing:
# tests/golden/ renders through this target, and CMake needs the target to exist
# before a test can name it.
add_subdirectory(src/cli)

enable_testing()
add_subdirectory(tests)

if(AE_SDK_FOUND)
    add_subdirectory(src/ae)
else()
    message(STATUS "Skipping plugin target (no AE SDK).")
endif()
