# Fetches Intel Open Image Denoise into tools/oidn/.
#
#     cmake -P cmake/FetchOidn.cmake
#
# STANDALONE AND NOT PART OF CONFIGURE, for the same reason cmake/FetchSlang.cmake is:
# a configure step that reaches the network fails on a locked-down machine, in CI, and
# on an aeroplane. A build without OIDN present configures, compiles and tests -- it
# renders without a denoiser and says so. See src/engine/Denoiser.h, where that is not
# a build-time fallback but a RUNTIME one.
#
# VERSION AND CHECKSUM ARE PINNED, as Slang's are. The denoiser runs on the pixels that
# reach the user, so "whatever is latest" is not a thing this project can have: a
# version change is a decision to re-look at a 48-frame animation for flicker.
#
# ===========================================================================
# WHY THE BYTES ARE NOT IN THE REPOSITORY. 53 MB, and a binary in git is a binary in
# git forever -- the rule tools/slang/ and dist/ are already under. The repo carries the
# version, the checksum and the fetch instructions instead.
#
# THAT IS NOT THE SAME QUESTION AS WHETHER TO BUNDLE IT IN THE RELEASE. PLAN.md settled
# that one on 2026-09-29: BUNDLE, because the denoiser is ON BY DEFAULT, so every
# failure mode of fetching on first run -- an offline install, a corporate proxy, a
# stall, a cache directory that is not writable -- would land on nearly every user
# rather than on a minority who opted in. Packaging copies from tools/oidn/ into the
# distributable; this file is only about what git tracks.
# ===========================================================================

cmake_minimum_required(VERSION 3.20)

set(OIDN_VERSION "2.5.1")

# ---------------------------------------------------------------------------
# Which build to fetch
# ---------------------------------------------------------------------------
if(CMAKE_HOST_WIN32)
    set(_oidn_platform "x64.windows")
    set(_oidn_ext      "zip")
    set(_oidn_sha256   "f11f91bc072a5e3a564515724cb72ab8fcfbc445c84a84c197ff9b16cc01396f")
elseif(CMAKE_HOST_APPLE)
    # Phase 5 is when this gets exercised. Written now so the file does not have to be
    # understood again by whoever does that, and refusing rather than guessing.
    execute_process(COMMAND uname -m OUTPUT_VARIABLE _arch OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(_arch STREQUAL "arm64")
        set(_oidn_platform "arm64.macos")
    else()
        set(_oidn_platform "x86_64.macos")
    endif()
    set(_oidn_ext "tar.gz")
    message(FATAL_ERROR
        "No pinned checksum for ${_oidn_platform}. Add one before fetching on macOS --\n"
        "  an unverified denoiser runs on every pixel that reaches the user.")
else()
    set(_oidn_platform "x86_64.linux")
    set(_oidn_ext      "tar.gz")
    message(FATAL_ERROR "No pinned checksum for ${_oidn_platform}. Add one before fetching.")
endif()

set(_oidn_dir  "oidn-${OIDN_VERSION}.${_oidn_platform}")
set(_oidn_file "${_oidn_dir}.${_oidn_ext}")
set(_oidn_url
    "https://github.com/RenderKit/oidn/releases/download/v${OIDN_VERSION}/${_oidn_file}")

get_filename_component(_repo "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(_dest     "${_repo}/tools/oidn")
set(_download "${_repo}/tools/${_oidn_file}")

if(EXISTS "${_dest}/include/OpenImageDenoise/oidn.h")
    message(STATUS "OIDN ${OIDN_VERSION} already present at ${_dest}")
    message(STATUS "  Delete that directory to force a re-fetch.")
    return()
endif()

message(STATUS "Fetching Open Image Denoise ${OIDN_VERSION} (${_oidn_platform})...")
message(STATUS "  ${_oidn_url}")

file(DOWNLOAD "${_oidn_url}" "${_download}"
     EXPECTED_HASH SHA256=${_oidn_sha256}
     SHOW_PROGRESS
     STATUS _status)

list(GET _status 0 _code)
if(NOT _code EQUAL 0)
    list(GET _status 1 _why)
    file(REMOVE "${_download}")
    message(FATAL_ERROR "OIDN download failed: ${_why}")
endif()

file(MAKE_DIRECTORY "${_dest}")
file(ARCHIVE_EXTRACT INPUT "${_download}" DESTINATION "${_dest}")

# The archive unpacks into a versioned subdirectory. Normalise, so cmake/Oidn.cmake has
# exactly one layout to find.
if(NOT EXISTS "${_dest}/include" AND EXISTS "${_dest}/${_oidn_dir}/include")
    file(GLOB _inner "${_dest}/${_oidn_dir}/*")
    foreach(_item IN LISTS _inner)
        get_filename_component(_name "${_item}" NAME)
        file(RENAME "${_item}" "${_dest}/${_name}")
    endforeach()
    file(REMOVE_RECURSE "${_dest}/${_oidn_dir}")
endif()

file(REMOVE "${_download}")

# ---------------------------------------------------------------------------
# Pruning the devices we do not ship
# ---------------------------------------------------------------------------
#
# ===========================================================================
# MEASURED AND RECORDED IN PROGRESS.md ON 2026-09-28, not decided here: with the HIP
# device, the SYCL device and its runtime removed, the remaining set still enumerates
# every RT filter and denoises on both the CPU and CUDA. Checked, not assumed.
#
#   dropped   OpenImageDenoise_device_hip.dll     13.8 MiB   AMD, and we have no AMD path
#             OpenImageDenoise_device_sycl.dll     0.7 MiB   Intel GPU
#             sycl9.dll, ur_*.dll                  8.8 MiB   the SYCL runtime it needs
#             oidn{Benchmark,Denoise,Test}.exe     1.3 MiB   tools, not a runtime
#
# WHAT STAYS IS 52.9 MiB and every byte of it is load-bearing:
#
#   OpenImageDenoise_core.dll         48.3 MiB   core AND WEIGHTS -- see below
#   OpenImageDenoise_device_cuda.dll   3.1 MiB   the device that makes Draft usable
#   OpenImageDenoise_device_cpu.dll    0.6 MiB   + tbb, the no-CUDA fallback
#   OpenImageDenoise.dll               0.2 MiB   the API shim
#
# THE WEIGHTS ARE NOT A SEPARABLE FILE. There is no .tza, no blob, no weights
# directory -- they are linked into core.dll, which is required whatever device is
# used. That is why "bundle the code and fetch the weights" was never an option, and
# it is the measurement that turned the bundling question into a product decision.
#
# THE CPU DEVICE STAYS DESPITE BEING 17x THE RENDER AT DRAFT. It is 0.6 MiB, and it is
# what a machine with no CUDA falls back to for a FINAL render, where 774 ms a frame is
# irrelevant. Draft on such a machine is denoiser-bound and that is a known, recorded
# consequence rather than a surprise.
# ===========================================================================
set(_prune
    "bin/OpenImageDenoise_device_hip.dll"
    "bin/OpenImageDenoise_device_sycl.dll"
    "bin/sycl9.dll"
    "bin/ur_loader.dll"
    "bin/ur_win_proxy_loader.dll"
    "bin/ur_adapter_level_zero.dll"
    "bin/ur_adapter_level_zero_v2.dll"
    "bin/oidnBenchmark.exe"
    "bin/oidnDenoise.exe"
    "bin/oidnTest.exe")

foreach(_p IN LISTS _prune)
    if(EXISTS "${_dest}/${_p}")
        file(REMOVE "${_dest}/${_p}")
    endif()
endforeach()

# REPORTED RATHER THAN ASSERTED. The keep set is a decision recorded in PROGRESS.md
# against a measured 52.9 MiB; printing the total means a future OIDN whose layout
# changed shows up here as a number that does not match, rather than as a packaging
# surprise months later.
set(_total 0)
file(GLOB_RECURSE _kept "${_dest}/bin/*")
foreach(_f IN LISTS _kept)
    file(SIZE "${_f}" _sz)
    math(EXPR _total "${_total} + ${_sz}")
endforeach()
math(EXPR _total_mib "${_total} / 1048576")

message(STATUS "OIDN ${OIDN_VERSION} installed to ${_dest}")
message(STATUS "  runtime set after pruning: ${_total_mib} MiB (expected 52)")
message(STATUS "  Re-run cmake to pick it up.")
