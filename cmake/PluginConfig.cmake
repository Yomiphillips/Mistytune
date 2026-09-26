# ===========================================================================
# THE ONE FILE THAT NAMES THIS PLUGIN.
#
# Everything else in cmake/, src/ and the build scripts is deliberately
# name-free, so a fix in one plugin copies into another without renaming.
# Identity reaches C++ through the generated PluginIdentity.h.
# ===========================================================================

# Binary name: Mistytune.aex / Mistytune.plugin. Also the CMake target name.
#
# ONE BINARY, ONE REGISTRATION. Unlike the Gravitune scaffolding this repo grew
# from -- an AEGP plus three inert parameter carriers -- Mistytune is a single
# plain effect. Effects self-register on AE 2023+ through
# PluginDataEntryFunction2 / PF_REGISTER_EFFECT_EXT2, so there is no PiPL and no
# AEGP discovery path to keep in sync.
set(PLUGIN_TARGET "Mistytune")

set(PLUGIN_DISPLAY_NAME "Mistytune")

# THE PERMANENT IDENTITY. After Effects stores this string in every project file
# that uses the effect and finds the effect by it at load time. CHANGING IT
# AFTER YOU SHIP BREAKS EVERY SAVED PROJECT -- AE cannot find the effect, drops
# it from the comp, and the user's sky settings go with it.
#
# It is free to change now and never again. PLAN.md fixes it here in Phase 1 and
# reviews it once more before the v0.5 hand-out; after that it is permanent.
set(PLUGIN_MATCH_NAME "Mistytune")

# Submenu in the Effect menu.
set(PLUGIN_CATEGORY "Mistytune")

set(PLUGIN_VENDOR "Mistytune")
set(PLUGIN_BUNDLE_ID "com.mistytune.mistytune")

# Diagnostics, off unless MISTYTUNE_DIAG=1 is set BEFORE AE launches.
set(PLUGIN_ENV_PREFIX "MISTYTUNE")
set(PLUGIN_LOG_NAME "mistytune.log")
