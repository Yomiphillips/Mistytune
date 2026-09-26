#!/usr/bin/env bash
#
# Starts a new plugin from this template.
#
#   ./new-plugin.sh Vignette                 # -> ../Vignette
#   ./new-plugin.sh Vignette ~/code/vignette # -> that directory
#
# Copies the template (without its git history, build output or SDK), replaces
# the placeholder identity everywhere, resets the version to build 1, and
# initialises a fresh git repo with one commit.
#
# Prompts for the details, with sensible defaults derived from the name. Run it
# with --yes to take every default without asking.
#
# Set AE_PLUGIN_VENDOR in your environment to have your own vendor name
# defaulted in -- worth doing once, since the match name is permanent.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

assume_yes=0
args=()
for a in "$@"; do
    case "$a" in
        --yes|-y) assume_yes=1 ;;
        *) args+=("$a") ;;
    esac
done

if [[ ${#args[@]} -lt 1 ]]; then
    echo "usage: ./new-plugin.sh <PluginName> [destination] [--yes]" >&2
    exit 2
fi

target="${args[0]}"
dest="${args[1]:-$(dirname "$root")/$target}"

if [[ ! "$target" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
    echo "Plugin name must be a bare identifier (letters, digits, underscore): got '$target'" >&2
    exit 2
fi
if [[ -e "$dest" ]]; then
    echo "Destination already exists: $dest" >&2
    exit 2
fi

# Defaults. The display name splits CamelCase into words, which is right often
# enough to be worth doing and is a prompt away from being fixed when it isn't.
vendor_default="${AE_PLUGIN_VENDOR:-Acme}"
display_default="$(sed 's/\([a-z0-9]\)\([A-Z]\)/\1 \2/g' <<<"$target")"
match_default="$(tr '[:lower:]' '[:upper:]' <<<"${vendor_default:0:4}") $display_default"
lower_target="$(tr '[:upper:]' '[:lower:]' <<<"$target")"
lower_vendor="$(tr '[:upper:]' '[:lower:]' <<<"$vendor_default" | tr -cd '[:alnum:]')"
upper_target="$(tr '[:lower:]' '[:upper:]' <<<"$target" | tr -cd '[:alnum:]_')"

ask() {   # ask <prompt> <default> -> echoes the answer
    local prompt="$1" default="$2" reply=""
    if [[ $assume_yes -eq 1 || ! -t 0 ]]; then
        echo "$default"
        return
    fi
    read -r -p "$prompt [$default]: " reply </dev/tty
    echo "${reply:-$default}"
}

echo "New plugin: $target  ->  $dest"
echo
display="$(ask 'Display name (Effect menu entry)' "$display_default")"
vendor="$(ask 'Vendor / your name' "$vendor_default")"
match="$(ask 'Match name (PERMANENT -- AE finds the effect by it)' "$match_default")"
category="$(ask 'Category (Effect menu submenu)' "$vendor")"
bundle_id="$(ask 'macOS bundle identifier' "com.${lower_vendor}.${lower_target}")"
env_prefix="$(ask 'Diagnostic env var prefix' "$upper_target")"
log_name="$(ask 'Diagnostic log filename' "${lower_target}.log")"

echo
echo "  target      $target"
echo "  display     $display"
echo "  match name  $match"
echo "  category    $category"
echo "  vendor      $vendor"
echo "  bundle id   $bundle_id"
echo "  diagnostics ${env_prefix}_DIAG -> $log_name"
echo

# --- copy -------------------------------------------------------------------
mkdir -p "$dest"
# Everything except history, build output, the SDK and this script. Using find
# rather than rsync so this works on a stock macOS with no extra tools.
( cd "$root" && find . \
    -path ./.git -prune -o \
    -path ./build -prune -o \
    -path ./build-dist -prune -o \
    -path ./dist -prune -o \
    -path ./sdk -prune -o \
    -name .DS_Store -prune -o \
    -name new-plugin.sh -prune -o \
    -name new-plugin.ps1 -prune -o \
    -type f -print ) | while IFS= read -r f; do
    mkdir -p "$dest/$(dirname "$f")"
    cp "$root/$f" "$dest/$f"
done

# --- replace the placeholder identity ---------------------------------------
# Order matters: the longest and most specific strings go first, so that
# "ACME My Effect" is not half-rewritten by the "My Effect" rule.
#
# sed -i '' is the BSD/macOS spelling. GNU sed wants -i with no argument, which
# is why this writes to a temp file instead of using -i at all.
subst() {
    local from="$1" to="$2" file="$3"
    # Escape the replacement for sed: & and \ are special, / is the delimiter.
    local esc_to esc_from
    esc_from="$(printf '%s' "$from" | sed 's/[.[\*^$/]/\\&/g')"
    esc_to="$(printf '%s' "$to" | sed 's/[\/&\\]/\\&/g')"
    sed "s/$esc_from/$esc_to/g" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

find "$dest" -type f \
    \( -name '*.md' -o -name '*.txt' -o -name '*.cmake' -o -name '*.in' \
       -o -name '*.h' -o -name '*.cpp' -o -name '*.inl' -o -name '*.sh' \
       -o -name '*.ps1' -o -name 'LICENSE' \) -print0 |
while IFS= read -r -d '' f; do
    subst 'ACME My Effect'   "$match"      "$f"
    subst 'com.acme.myeffect' "$bundle_id" "$f"
    subst 'myeffect.log'     "$log_name"   "$f"
    subst 'MYEFFECT'         "$env_prefix" "$f"
    subst 'My Effect'        "$display"    "$f"
    subst 'MyEffect'         "$target"     "$f"
    subst 'Acme'             "$vendor"     "$f"
done

# Category is asked for separately and may differ from the vendor, so it is set
# directly rather than being caught by the substitutions above.
subst "set(PLUGIN_CATEGORY \"$vendor\")" "set(PLUGIN_CATEGORY \"$category\")" \
      "$dest/cmake/PluginConfig.cmake"

# --- reset version and changelog --------------------------------------------
sed 's/^#define PLUGIN_BUILD .*/#define PLUGIN_BUILD 1/' "$dest/src/ae/Build.h" > "$dest/src/ae/Build.h.tmp"
mv "$dest/src/ae/Build.h.tmp" "$dest/src/ae/Build.h"

cat > "$dest/CHANGELOG.md" <<EOF
# Changelog

## Unreleased

- build 1: created from the AE plugin template.
EOF

chmod +x "$dest/build.sh" "$dest/package-mac.sh"

# --- fresh history ----------------------------------------------------------
if command -v git >/dev/null 2>&1; then
    ( cd "$dest" && git init -q && git add -A && \
      git -c user.useConfigOnly=false commit -q -m "Initial commit: $display from AE plugin template" ) || \
      echo "(git init/commit skipped)"
fi

echo "Created $dest"
echo
echo "Next:"
echo "  cd \"$dest\""
echo "  export AE_SDK_ROOT=...        # if you have not set it globally"
echo "  ./build.sh --test --install   # quit After Effects first"
echo
echo "Then look for Effect > $category > $display in After Effects."
