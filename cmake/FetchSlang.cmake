# Fetches the Slang toolchain into tools/slang/.
#
#     cmake -P cmake/FetchSlang.cmake
#
# STANDALONE AND NOT PART OF CONFIGURE, deliberately. A configure step that reaches
# the network is a configure step that fails on a locked-down machine, in CI, and on
# an aeroplane -- and it would do so for a tool that MOST BUILDS DO NOT NEED. The
# generated CUDA is committed (see cmake/Slang.cmake), so Slang is required only to
# REGENERATE it, which is a thing a person does deliberately.
#
# VERSION AND CHECKSUM ARE PINNED. A shader compiler is part of the toolchain that
# decides the bits in a golden image, so "whatever is latest" is not a thing this
# project can have. Changing the version here is a decision to re-verify the golden
# suite, exactly like changing the CUDA toolkit would be.

cmake_minimum_required(VERSION 3.20)

set(SLANG_VERSION "2026.18.3")
set(SLANG_SHA256  "1339d7b3050ae680c11152b8ccff977173591ce8e9c1d2a5cff2eb904d52e50d")

# ---------------------------------------------------------------------------
# Which build to fetch
# ---------------------------------------------------------------------------
if(CMAKE_HOST_WIN32)
    set(_slang_platform "windows-x86_64")
    set(_slang_ext      "zip")
elseif(CMAKE_HOST_APPLE)
    # Apple Silicon and Intel ship separately. Phase 5 is when this gets exercised
    # for real; it is written now so the file does not have to be understood again
    # by whoever does that.
    execute_process(COMMAND uname -m OUTPUT_VARIABLE _arch OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(_arch STREQUAL "arm64")
        set(_slang_platform "macos-aarch64")
    else()
        set(_slang_platform "macos-x86_64")
    endif()
    set(_slang_ext "tar.gz")

    # THE CHECKSUM ABOVE IS THE WINDOWS ONE. Refusing is better than downloading
    # something unverified: the whole point of pinning is that the bits are known.
    message(FATAL_ERROR
        "No pinned checksum for ${_slang_platform}. Add one before fetching on macOS --\n"
        "  an unverified shader compiler decides the bits in every golden image.")
else()
    set(_slang_platform "linux-x86_64")
    set(_slang_ext      "tar.gz")
    message(FATAL_ERROR "No pinned checksum for ${_slang_platform}. Add one before fetching.")
endif()

set(_slang_file "slang-${SLANG_VERSION}-${_slang_platform}.${_slang_ext}")
set(_slang_url
    "https://github.com/shader-slang/slang/releases/download/v${SLANG_VERSION}/${_slang_file}")

get_filename_component(_repo "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(_dest     "${_repo}/tools/slang")
set(_download "${_repo}/tools/${_slang_file}")

if(EXISTS "${_dest}/bin/slangc.exe" OR EXISTS "${_dest}/bin/slangc")
    message(STATUS "Slang ${SLANG_VERSION} already present at ${_dest}")
    message(STATUS "  Delete that directory to force a re-fetch.")
    return()
endif()

message(STATUS "Fetching Slang ${SLANG_VERSION} (${_slang_platform})...")
message(STATUS "  ${_slang_url}")

file(DOWNLOAD "${_slang_url}" "${_download}"
     EXPECTED_HASH SHA256=${SLANG_SHA256}
     SHOW_PROGRESS
     STATUS _status)

list(GET _status 0 _code)
if(NOT _code EQUAL 0)
    list(GET _status 1 _why)
    file(REMOVE "${_download}")
    message(FATAL_ERROR "Slang download failed: ${_why}")
endif()

file(MAKE_DIRECTORY "${_dest}")
file(ARCHIVE_EXTRACT INPUT "${_download}" DESTINATION "${_dest}")

# The archives unpack into a versioned subdirectory on some platforms and flat on
# others. Normalise, so cmake/Slang.cmake has exactly one layout to find.
if(NOT EXISTS "${_dest}/bin" AND EXISTS "${_dest}/slang-${SLANG_VERSION}-${_slang_platform}/bin")
    file(GLOB _inner "${_dest}/slang-${SLANG_VERSION}-${_slang_platform}/*")
    foreach(_item IN LISTS _inner)
        get_filename_component(_name "${_item}" NAME)
        file(RENAME "${_item}" "${_dest}/${_name}")
    endforeach()
    file(REMOVE_RECURSE "${_dest}/slang-${SLANG_VERSION}-${_slang_platform}")
endif()

file(REMOVE "${_download}")

message(STATUS "Slang ${SLANG_VERSION} installed to ${_dest}")
message(STATUS "  Re-run cmake to pick it up.")
