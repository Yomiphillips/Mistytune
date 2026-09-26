#!/usr/bin/env bash
#
# Configures and builds the plugin on macOS. Run from anywhere.
#
#   ./build.sh                        # configure + build (universal)
#   ./build.sh --test                 # ... and run the unit tests
#   ./build.sh --install              # ... and install into AE's plug-ins folder
#   ./build.sh --hot                  # swap ONLY the impl dylib, AE stays open
#   ./build.sh --clean
#   ./build.sh --arch arm64           # skip the x86_64 slice for a faster loop
#   ./build.sh --package              # RELEASE shape into build-dist/ (package-mac.sh)
#   ./build.sh --install --dest /some/other/Plug-ins
#
# The macOS counterpart of build.ps1. Same switches, same order of operations,
# same two-target (stub bundle, impl dylib) model -- see
# src/host/HotReloadStub.inl. Differences that are real, not cosmetic:
#
#   * The plugin is a BUNDLE (<Name>.plugin), not a single file, so install is
#     a directory replace rather than a file copy.
#   * Everything is ad-hoc signed by the build (cmake/AESDK.cmake). That is
#     required on Apple Silicon, free, and NOT notarization.
#   * Single-config generator, so there is no Release/ segment in build paths.
#
# The plugin's NAME is read out of cmake/PluginConfig.cmake, so this script
# needs no edit when you start a new plugin. Kept ASCII deliberately.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$root/build"

# Identity comes from the config file, never from a string typed here.
cfg() {
    sed -n "s/^[[:space:]]*set([[:space:]]*$1[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
        "$root/cmake/PluginConfig.cmake" | head -1
}
plugin="$(cfg PLUGIN_TARGET)"
[[ -n "$plugin" ]] || { echo "Could not read PLUGIN_TARGET from cmake/PluginConfig.cmake" >&2; exit 1; }

do_install=0
do_hot=0
do_clean=0
do_test=0
config="Release"
dest=""
arch=""
do_package=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install) do_install=1 ;;
        --hot)     do_hot=1; do_install=1 ;;
        --clean)   do_clean=1 ;;
        --test)    do_test=1 ;;
        --config)  config="${2:?--config needs Release or Debug}"; shift ;;
        --dest)    dest="${2:?--dest needs a path}"; shift ;;
        --arch)    arch="${2:?--arch needs e.g. arm64 or 'x86_64;arm64'}"; shift ;;
        --package) do_package=1 ;;
        -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

case "$config" in
    Release|Debug) ;;
    *) echo "--config must be Release or Debug (got '$config')" >&2; exit 2 ;;
esac

# --package builds into its OWN directory, and that separation is load-bearing.
# The release shape is a different CMake configuration (PLUGIN_HOT_RELOAD=OFF),
# so sharing build/ with the dev loop would mean every package run reconfigured
# it and the next plain build reconfigured it back -- a full rebuild each way,
# and a real chance of shipping whatever happened to be in the directory.
if [[ $do_package -eq 1 ]]; then
    build_dir="$root/build-dist"
    if [[ $do_hot -eq 1 ]]; then
        echo "--hot and --package do not mix: a release-shape build has no impl dylib to swap." >&2
        exit 2
    fi
fi

# --- cmake ------------------------------------------------------------------
# Prefer PATH; fall back to the CMake.app bundle, which does not add itself.
cmake_bin="$(command -v cmake || true)"
if [[ -z "$cmake_bin" ]]; then
    for candidate in \
        /Applications/CMake.app/Contents/bin/cmake \
        /opt/homebrew/bin/cmake \
        /usr/local/bin/cmake
    do
        [[ -x "$candidate" ]] && { cmake_bin="$candidate"; break; }
    done
fi
if [[ -z "$cmake_bin" ]]; then
    echo "No cmake found. Install with 'brew install cmake', or get CMake.app" >&2
    echo "from https://cmake.org/download/ ." >&2
    exit 1
fi
echo "cmake: $cmake_bin"

if [[ $do_clean -eq 1 && -d "$build_dir" ]]; then
    echo "Removing $build_dir"
    rm -rf "$build_dir"
fi

# --- SDK --------------------------------------------------------------------
# Adobe's, licensed, and not in this repo. An unextracted download looks exactly
# like a missing SDK to CMake, so say which it is.
if [[ -z "${AE_SDK_ROOT:-}" ]] && ! find "$root/sdk" -name AE_Effect.h -print -quit 2>/dev/null | grep -q .; then
    archive="$(find "$root/sdk" -maxdepth 1 -name '*AfterEffectsSDK*.zip' -print -quit 2>/dev/null || true)"
    if [[ -n "$archive" ]]; then
        echo "SDK archive found but not extracted: $(basename "$archive")" >&2
        echo "Unzip it into ./sdk/ first." >&2
    else
        echo "After Effects SDK not found. Download it from" >&2
        echo "https://developer.adobe.com/after-effects/ and unpack into ./sdk/," >&2
        echo "or set AE_SDK_ROOT to a copy you already have (recommended: one copy" >&2
        echo "shared by every plugin you build)." >&2
    fi
    exit 1
fi

# --- configure + build ------------------------------------------------------
configure_args=(-S "$root" -B "$build_dir" "-DCMAKE_BUILD_TYPE=$config")
[[ -n "$arch" ]] && configure_args+=("-DCMAKE_OSX_ARCHITECTURES=$arch")
# PLUGIN_HOT_RELOAD=OFF is what makes the bundle self-contained. Passed
# explicitly BOTH ways so a directory once configured OFF cannot quietly stay
# that way under a plain build. See src/ae/CMakeLists.txt for why the stub must
# never reach a user.
configure_args+=("-DPLUGIN_HOT_RELOAD=$( [[ $do_package -eq 1 ]] && echo OFF || echo ON )")

"$cmake_bin" "${configure_args[@]}"
"$cmake_bin" --build "$build_dir" --parallel "$(sysctl -n hw.ncpu)"

bundle="$build_dir/src/ae/$plugin.plugin"
impl="$build_dir/src/ae/${plugin}Impl.dylib"

echo
if [[ -d "$bundle" ]]; then
    echo "Built: $bundle"
else
    echo "No plugin bundle was built (SDK missing? see above)."
fi

# --- tests ------------------------------------------------------------------
if [[ $do_test -eq 1 ]]; then
    test_exe="$build_dir/tests/plugin_tests"
    [[ -x "$test_exe" ]] || { echo "Test binary not found: $test_exe" >&2; exit 1; }
    echo
    "$test_exe"
fi

# --- install ----------------------------------------------------------------
if [[ $do_install -eq 1 ]]; then
    [[ -d "$bundle" ]] || { echo "Nothing to install." >&2; exit 1; }

    if [[ $do_hot -eq 0 ]] && pgrep -x "After Effects" >/dev/null 2>&1; then
        echo "After Effects is running -- it holds the .plugin open for the session." >&2
        echo "Quit AE and retry, or use --hot to swap just the impl dylib." >&2
        exit 1
    fi

    if [[ -z "$dest" ]]; then
        # Prefer After Effects' OWN Plug-ins folder over the shared
        # /Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore:
        #   * MediaCore is shared with Premiere and Media Encoder, which would
        #     then probe an AE-only effect on every launch.
        #   * AE's own folder sits OUTSIDE the code-signed .app bundle and is
        #     owned by the installing user, so it needs no admin prompt.
        #     MediaCore is root-owned and always does.
        # Newest AE version wins when several are installed.
        while IFS= read -r candidate; do
            [[ -d "$candidate" ]] && { dest="$candidate"; break; }
        done < <(ls -1d /Applications/Adobe\ After\ Effects\ */Plug-ins 2>/dev/null | sort -r)

        if [[ -z "$dest" ]]; then
            dest="/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore"
            echo "No AE install found; falling back to MediaCore (needs admin)."
        fi
    fi

    if [[ $do_hot -eq 1 ]]; then
        # Refresh ONLY the impl, in place inside the installed bundle. The stub
        # loads a shadow COPY of it, so the original is never open and can be
        # overwritten with AE running.
        #
        # No re-sign needed: cp preserves the signature embedded in the Mach-O,
        # and the impl is dlopen'd by path, so it is its own signature that gets
        # checked, not the enclosing bundle's seal.
        [[ -f "$impl" ]] || { echo "No impl dylib -- this looks like a release-shape build." >&2; exit 1; }
        [[ -d "$dest/$plugin.plugin" ]] || { echo "$plugin is not installed yet -- run without --hot first." >&2; exit 1; }
        cp -f "$impl" "$dest/$plugin.plugin/Contents/MacOS/$(basename "$impl")"
        echo "Hot-swapped impl -> $dest"
        echo "Nudge the frame in AE (move the time indicator or touch a param) to pick it up."
        echo "Parameter list, out_flags, effect name and PLUGIN_BUILD changes still need a full restart."
        echo "A hot-swapped PLUGIN_BUILD bump reports 'version mismatch ... (8001d)' - AE caches registration against the stub, which --hot does not replace."
    else
        # Delete-then-copy: a bundle is a directory, so copying over an older
        # install would leave its stale files in place beside the new ones --
        # including an impl dylib the stub would happily load.
        rm -rf "${dest:?}/$plugin.plugin"
        cp -R "$bundle" "$dest/$plugin.plugin"
        echo "Installed to $dest"
    fi
fi
