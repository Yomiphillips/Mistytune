#!/usr/bin/env bash
#
# Builds the distributable macOS release ZIP -- the counterpart of
# `build.ps1 -Package`.
#
#   ./package-mac.sh              # clean universal release build -> dist/
#   ./package-mac.sh --skip-build # package whatever is already in build-dist/
#
# Produces dist/<Name>-v<version>-macos-universal.zip: the .plugin bundle plus
# README.md, INSTALL.md, CHANGELOG.md and LICENSE -- the same four documents the
# Windows ZIP carries, so the install steps travel with the file.
#
# RELEASE SHAPE. The bundle comes from `./build.sh --package`:
# PLUGIN_HOT_RELOAD=OFF, built in build-dist/, one self-contained binary with no
# nested impl dylib and no hot-reload stub. build/ belongs to the dev loop and is
# never packaged. See src/ae/CMakeLists.txt for why the stub must never ship.
#
# Name and version are READ OUT of cmake/PluginConfig.cmake and src/ae/Build.h
# rather than repeated here, so the filename can never disagree with what the
# plug-in reports to AE.
#
# EVERY "ok" LINE BELOW IS A RELEASE GATE. The script refuses to produce a ZIP
# that is a hot-reload stub, single-architecture, unsigned, misclassified,
# mis-versioned, or built from failing tests, and it re-checks the finished ZIP
# as a user will receive it. Shipping a broken bundle costs far more than a
# failed package run -- a user cannot tell "plug-in is missing" from "plug-in is
# broken", and neither produces an error message inside After Effects.
#
# Kept ASCII deliberately.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$root/build-dist"
dist_dir="$root/dist"
skip_build=0
[[ "${1:-}" == "--skip-build" ]] && skip_build=1

fail() { echo "FAIL: $*" >&2; exit 1; }

cfg() {
    sed -n "s/^[[:space:]]*set([[:space:]]*$1[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
        "$root/cmake/PluginConfig.cmake" | head -1
}
plugin="$(cfg PLUGIN_TARGET)"
[[ -n "$plugin" ]] || fail "could not read PLUGIN_TARGET from cmake/PluginConfig.cmake"

# The \r strip is there in case the header was edited on Windows: "3\r" would
# otherwise land in the ZIP's filename.
src="$root/src/ae/Build.h"
read_define() { awk -v n="$1" '$1 == "#define" && $2 == n {sub(/\r$/, "", $3); print $3}' "$src"; }
ver_major="$(read_define PLUGIN_MAJOR)"
ver_minor="$(read_define PLUGIN_MINOR)"
ver_build="$(read_define PLUGIN_BUILD)"
[[ "$ver_major" =~ ^[0-9]+$ && "$ver_minor" =~ ^[0-9]+$ && "$ver_build" =~ ^[0-9]+$ ]] \
    || fail "could not read numeric PLUGIN_MAJOR/MINOR/BUILD from $src"
version="${ver_major}.${ver_minor}.0"
name="$plugin-v${version}-macos-universal"
docs=(README.md INSTALL.md CHANGELOG.md LICENSE)

if [[ $skip_build -eq 0 ]]; then
    echo "==> Clean universal release build + tests"
    "$root/build.sh" --package --clean --test --config Release
fi

bundle="$build_dir/src/ae/$plugin.plugin"
binary="$bundle/Contents/MacOS/$plugin"
plist="$bundle/Contents/Info.plist"
[[ -d "$bundle" ]] || fail "no bundle at $bundle -- run without --skip-build"

echo
echo "==> Verify (release gates)"

# THE GUARD. A release bundle holds exactly ONE binary. Any trace of the impl
# means PLUGIN_HOT_RELOAD did not actually go off and this is a hot-reload stub
# that would ship broken. Checked from three angles (the configuration, the
# build tree, the bundle) because --skip-build packages whatever is there.
grep -q '^PLUGIN_HOT_RELOAD:BOOL=OFF$' "$build_dir/CMakeCache.txt" \
    || fail "$build_dir is not configured PLUGIN_HOT_RELOAD=OFF. Delete it and retry."
impl_hits="$(find "$build_dir/src/ae" -name "${plugin}Impl*")"
[[ -z "$impl_hits" ]] \
    || fail "hot-reload impl found in a release build -- the bundle is a stub and MUST NOT ship. Delete $build_dir and retry. Found: $impl_hits"
macos_count="$(find "$bundle/Contents/MacOS" -type f | wc -l | tr -d ' ')"
[[ "$macos_count" == "1" ]] \
    || fail "expected exactly 1 file in Contents/MacOS, found $macos_count"
echo "  ok  self-contained          (one binary, no impl dylib, no stub)"

archs="$(lipo -archs "$binary")"
[[ "$archs" == *x86_64* && "$archs" == *arm64* ]] \
    || fail "binary is not universal (got: $archs)"
echo "  ok  universal               ($archs)"

# INSTALL.md promises macOS 11. If the deployment target ever drifts up, users
# on older systems get a plug-in that AE skips without a word.
minos="$(otool -l "$binary" \
    | awk '$2 == "LC_BUILD_VERSION" {f=1} f && $1 == "minos" {print $2; f=0}' \
    | sort -u | paste -sd' ' -)"
[[ "$minos" == "11.0" ]] \
    || fail "minimum macOS is '$minos' but INSTALL.md promises 11.0"
echo "  ok  minimum macOS           ($minos, every slice)"

# Ad-hoc is expected and sufficient -- Apple Silicon refuses code with NO
# signature at all, which is the bar this clears. It is not notarization.
sig_out="$(codesign --verify --deep --strict "$bundle" 2>&1)" \
    || fail "signature does not verify: $sig_out"
echo "  ok  signature verifies      (ad-hoc, deep+strict)"

pkg_type="$(plutil -extract CFBundlePackageType raw -o - "$plist")"
[[ "$pkg_type" == "eFKT" ]] \
    || fail "CFBundlePackageType is '$pkg_type', must be eFKT"
echo "  ok  classified as effect    (eFKT/FXTC)"

# Info.plist takes its version from project(VERSION), which CMake reads out of
# Build.h -- so this confirms the generated bundle actually picked up the
# version this script is naming the ZIP after.
plist_ver="$(plutil -extract CFBundleShortVersionString raw -o - "$plist")"
[[ "$plist_ver" == "$version" ]] \
    || fail "Info.plist says $plist_ver but Build.h says $version -- stale build directory?"
echo "  ok  version agrees          ($plist_ver, build $ver_build)"

exports="$(nm -gU "$binary")"
for sym in EffectMain PluginDataEntryFunction2; do
    grep -q "_$sym\$" <<<"$exports" || fail "binary does not export $sym"
done
echo "  ok  entry points exported"

echo
echo "==> Stage"
# Staged and zipped OUTSIDE the repo. A working copy under OneDrive, iCloud
# Drive or Dropbox has a file provider that stamps extended attributes and
# execute bits onto new files as it syncs -- a race with anything created and
# then archived seconds later. $TMPDIR is out of its reach.
work="$(mktemp -d "${TMPDIR:-/tmp}/$plugin-package.XXXXXX")"
trap 'rm -rf "$work"' EXIT
stage="$work/$name"
mkdir -p "$stage"

# cp -R on a bundle preserves the directory structure and the embedded
# signature; the signature lives inside the Mach-O, not in an xattr.
cp -R "$bundle" "$stage/$plugin.plugin"
for doc in "${docs[@]}"; do
    [[ -f "$root/$doc" ]] || fail "missing $doc -- it ships in the ZIP"
    cp "$root/$doc" "$stage/$doc"
done

# Normalise modes. Documents are not programs, and files that passed through a
# sync client arrive marked executable. The code signature does not seal file
# modes, so this cannot invalidate it -- the ZIP check below proves that rather
# than assuming it.
find "$stage" -type d -exec chmod 755 {} +
find "$stage" -type f -exec chmod 644 {} +
chmod 755 "$stage/$plugin.plugin/Contents/MacOS/$plugin"

# Gate, not a cleanup: assert the payload is the product and its documents and
# nothing else.
expected="$(printf '%s\n' "$plugin.plugin" "${docs[@]}" | LC_ALL=C sort)"
actual="$(ls -1A "$stage" | LC_ALL=C sort)"
[[ "$actual" == "$expected" ]] || fail "unexpected payload:"$'\n'"$actual"
echo "  ok  payload is product + docs only"

echo
echo "==> Zip"
# zip -X, not ditto.
#
# ditto is the usual advice for macOS bundles, but it insists on preserving
# extended attributes, and it cannot win here: with --sequesterRsrc it emits a
# __MACOSX/ sidecar tree, and without it it interleaves AppleDouble ._* files
# INSIDE the bundle, which is worse. Stripping the xattrs first does not help --
# com.apple.provenance is kernel-managed and comes straight back.
#
# None of that metadata is needed: the code signature lives inside the Mach-O,
# CodeResources is an ordinary file, and this bundle has no resource forks.
# `zip -X` simply does not record it, giving an archive that is clean whether it
# is opened on macOS or Windows.
#
# -y stores symlinks as symlinks. There are none today; the gate below keeps it
# that way, because zip WOULD otherwise follow them and silently duplicate.
symlinks="$(find "$stage" -type l)"
[[ -z "$symlinks" ]] || fail "payload contains symlinks -- verify zip -y handles them: $symlinks"
( cd "$work" && zip -r -X -y -q "$name.zip" "$name" )
mkdir -p "$dist_dir"
zip_path="$dist_dir/$name.zip"
rm -f "$zip_path"
mv "$work/$name.zip" "$zip_path"

echo
echo "==> Verify the ZIP as a user will receive it"
check="$work/check"
mkdir -p "$check"
ditto -x -k "$zip_path" "$check"
got="$check/$name"
junk="$(find "$check" \( -name '__MACOSX' -o -name '._*' \))"
[[ -z "$junk" ]] || fail "ZIP carries AppleDouble/__MACOSX metadata: $junk"
[[ "$(ls -1A "$got" | LC_ALL=C sort)" == "$expected" ]] \
    || fail "extracted payload differs from what was staged"
sig_out="$(codesign --verify --deep --strict "$got/$plugin.plugin" 2>&1)" \
    || fail "signature does not survive the ZIP: $sig_out"
got_archs="$(lipo -archs "$got/$plugin.plugin/Contents/MacOS/$plugin")"
[[ "$got_archs" == "$archs" ]] || fail "architectures changed in the ZIP (got: $got_archs)"
[[ -x "$got/$plugin.plugin/Contents/MacOS/$plugin" ]] \
    || fail "binary lost its execute bit in the ZIP"
echo "  ok  extracts clean, signature intact, both slices, executable"

echo
echo "==> Done"
echo "  Packaged v$version (build $ver_build)"
echo "  $zip_path"
echo "  size:   $(du -h "$zip_path" | cut -f1)"
echo "  sha256: $(shasum -a 256 "$zip_path" | cut -d' ' -f1)"
echo
echo "  Single self-contained .plugin - no impl dylib, no hot-reload stub."
echo "  Publish the SHA256 alongside the download so users can verify it."
