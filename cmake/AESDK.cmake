# Locates the Adobe After Effects SDK, and defines the two functions that build
# an AE plugin: add_ae_effect() and set_ae_impl_naming().
#
# NAME-FREE BY DESIGN. Nothing here mentions a particular plugin, so this file
# can be copied verbatim between plugin repos when you fix something in it.
# Identity comes from cmake/PluginConfig.cmake.
#
# The SDK is Adobe's, licensed, and must NOT be committed to a repo.
# Download it from https://developer.adobe.com/after-effects/ then either:
#   * set -DAE_SDK_ROOT=<path>, or
#   * set an AE_SDK_ROOT environment variable (best: one copy for every
#     plugin you build), or
#   * unpack it to <repo>/sdk/  (gitignored)
#
# AE_SDK_ROOT should be the folder CONTAINING "Examples",
# e.g. /Users/you/SDK/AfterEffectsSDK

set(AE_SDK_ROOT "$ENV{AE_SDK_ROOT}" CACHE PATH "Root of the After Effects SDK")

if(NOT AE_SDK_ROOT AND EXISTS "${CMAKE_SOURCE_DIR}/sdk/Examples")
    set(AE_SDK_ROOT "${CMAKE_SOURCE_DIR}/sdk")
endif()

# Adobe's archive unpacks to a versioned subfolder, and how deep depends on the
# platform download:
#   Windows  sdk/ae25.6_61.64bit.AfterEffectsSDK/Examples/...          (one down)
#   macOS    sdk/AfterEffectsSDK_25.6_61_mac/                          (two down)
#              ae25.6_61.64bit.AfterEffectsSDK/Examples/...
# The Mac zip holds a zstd-compressed tar plus Adobe's extractzstd.sh, and
# unpacking in place leaves that extra wrapper directory. Search both depths.
if(NOT AE_SDK_ROOT)
    file(GLOB _ae_sdk_candidates
        "${CMAKE_SOURCE_DIR}/sdk/*/Examples/Headers/AE_Effect.h"
        "${CMAKE_SOURCE_DIR}/sdk/*/*/Examples/Headers/AE_Effect.h")
    if(_ae_sdk_candidates)
        list(GET _ae_sdk_candidates 0 _ae_hit)
        get_filename_component(_ae_root "${_ae_hit}" DIRECTORY)   # .../Examples/Headers
        get_filename_component(_ae_root "${_ae_root}" DIRECTORY)  # .../Examples
        get_filename_component(_ae_root "${_ae_root}" DIRECTORY)  # SDK root
        set(AE_SDK_ROOT "${_ae_root}")
    endif()
endif()

# Missing SDK is NOT fatal.
#
# src/engine/ is host-agnostic by design and its tests must build and run with
# no SDK present. Making this a hard error would quietly couple the engine to
# Adobe's headers, which is the exact thing the layout exists to prevent. Only
# the plugin targets need the SDK.
if(NOT AE_SDK_ROOT OR NOT EXISTS "${AE_SDK_ROOT}/Examples/Headers/AE_Effect.h")
    set(AE_SDK_FOUND FALSE)
    message(STATUS "AE SDK: NOT FOUND - plugin targets will be skipped.")
    message(STATUS "  Engine and unit tests still build. To build the plugin, get the SDK from")
    message(STATUS "  https://developer.adobe.com/after-effects/ and unpack into ./sdk/,")
    message(STATUS "  or point AE_SDK_ROOT at a copy you already have.")
    return()
endif()

set(AE_SDK_FOUND TRUE)
message(STATUS "AE SDK: ${AE_SDK_ROOT}")

set(AE_SDK_INCLUDE_DIRS
    "${AE_SDK_ROOT}/Examples/Headers"
    "${AE_SDK_ROOT}/Examples/Headers/SP"
    "${AE_SDK_ROOT}/Examples/Util"
    "${AE_SDK_ROOT}/Examples/Resources")

# The SDK ships helper sources rather than a prebuilt library; compile them in.
#
# Smart_Utils.cpp is the one that catches people out: Smart_Utils.h DECLARES
# UnionLRect and IsEmptyRect, which every smart-render effect uses, but the
# definitions live in the .cpp. Include the header without this and you get a
# link error, not a compile one.
set(AE_SDK_SOURCES "")
foreach(_f
        "Examples/Util/AEGP_SuiteHandler.cpp"
        "Examples/Util/AEFX_SuiteHelper.c"
        "Examples/Util/MissingSuiteError.cpp"
        "Examples/Util/Smart_Utils.cpp")
    if(EXISTS "${AE_SDK_ROOT}/${_f}")
        list(APPEND AE_SDK_SOURCES "${AE_SDK_ROOT}/${_f}")
    endif()
endforeach()

# Ad-hoc code signing. No-op off macOS.
#
# Free, needs no Apple account, and is NOT notarization -- it exists because
# Apple Silicon refuses to load arm64 code carrying no signature at all
# ("Trying to load an unsigned library"). Ad-hoc clears exactly that bar.
#
# `ld` already ad-hoc signs its own output, so this matters for the cases where
# something touched the binary AFTER linking. Nesting a dylib inside a bundle is
# one: it invalidates the enclosing bundle's seal, so the bundle has to be
# re-signed afterwards. Sign inside-out -- nested files first, bundle last.
function(plugin_adhoc_sign TARGET)
    if(NOT APPLE)
        return()
    endif()
    foreach(_path IN LISTS ARGN)
        add_custom_command(TARGET ${TARGET} POST_BUILD
            # xattr -cr FIRST, and it is not optional housekeeping.
            #
            # codesign refuses outright to sign anything carrying a resource
            # fork or Finder info -- "resource fork, Finder information, or
            # similar detritus not allowed" -- and a cloud-synced working copy
            # attracts exactly that. A repo living under OneDrive, iCloud Drive
            # or Dropbox gets com.apple.FinderInfo and provider attributes
            # stamped onto build output whenever the sync client feels like it.
            # Without this the build fails intermittently, in a way that looks
            # like a signing bug rather than a sync-client one.
            COMMAND xattr -cr "${_path}"
            COMMAND codesign --force --sign - "${_path}"
            COMMENT "Ad-hoc signing ${_path}"
            VERBATIM)
    endforeach()
endfunction()

# Builds an AE effect plugin.
#
#   Windows   <TARGET>.aex -- a DLL with a renamed suffix.
#   macOS     <TARGET>.plugin -- a CFBundle. AE will not load a bare .dylib;
#             it scans for bundles and reads Info.plist to classify them.
#             MODULE + BUNDLE yields
#             <TARGET>.plugin/Contents/{Info.plist,MacOS/<TARGET>}.
#
# Registration note: this template targets AE 2023+, so effects self-register
# in code via PluginDataEntryFunction2 / PF_REGISTER_EFFECT_EXT2. That removes
# the legacy PiPL build step entirely -- .r -> PiPLtool -> .rrc -> .rc on
# Windows, .r -> Rez -> Contents/Resources on macOS.
function(add_ae_effect TARGET)
    if(APPLE)
        add_library(${TARGET} MODULE ${ARGN} ${AE_SDK_SOURCES})
        set_target_properties(${TARGET} PROPERTIES
            BUNDLE TRUE
            BUNDLE_EXTENSION "plugin"
            MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/cmake/AEPlugin.plist.in"
            MACOSX_BUNDLE_BUNDLE_NAME "${TARGET}"
            MACOSX_BUNDLE_GUI_IDENTIFIER "${PLUGIN_BUNDLE_ID}"
            MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
            MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
            MACOSX_BUNDLE_COPYRIGHT "${PLUGIN_VENDOR}")
    else()
        add_library(${TARGET} SHARED ${ARGN} ${AE_SDK_SOURCES})
        set_target_properties(${TARGET} PROPERTIES
            SUFFIX ".aex"
            PREFIX "")
    endif()
    # SYSTEM, so the compiler stops warning about Adobe's headers.
    #
    # They are not warning-clean under -Wall -Wextra / /W4 (Param_Utils.h alone
    # trips -Wmissing-field-initializers on every file that includes it), and
    # they are not ours to fix. Without SYSTEM every build buries your own
    # warnings under the SDK's, which is how a real one goes unnoticed.
    target_include_directories(${TARGET} SYSTEM PRIVATE ${AE_SDK_INCLUDE_DIRS})
endfunction()

# Names the hot-reload impl library for the platform, matching what
# PLUGIN_IMPL_BASENAME + kImplSuffix resolve to in src/host/HotReloadStub.inl.
function(set_ae_impl_naming TARGET)
    if(APPLE)
        set_target_properties(${TARGET} PROPERTIES PREFIX "" SUFFIX ".dylib")
    else()
        set_target_properties(${TARGET} PROPERTIES PREFIX "" SUFFIX ".dll")
    endif()
endfunction()

# Fallback install location for the `install_plugin` target.
#
# Prefer the build scripts -- `.\build.ps1 -Install` on Windows, `./build.sh
# --install` on macOS -- which locate the AE install rather than assuming it.
#
# Windows: build.ps1 auto-detects across all drives (AE is not always on C:)
# and targets AE's own Support Files\Plug-ins\Effects folder -- writable
# without elevation, and not shared with Premiere/Media Encoder the way
# MediaCore is.
#
# macOS: the per-app equivalent is inside the .app bundle, which is Adobe-signed
# and should not be written into. MediaCore is the correct destination here even
# though it is shared, and it needs an admin prompt.
if(APPLE)
    set(AE_PLUGIN_DIR "/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore"
        CACHE PATH "Where install_plugin copies the .plugin bundle")
else()
    set(AE_PLUGIN_DIR "C:/Program Files/Adobe/Common/Plug-ins/7.0/MediaCore"
        CACHE PATH "Where install_plugin copies the .aex")
endif()
