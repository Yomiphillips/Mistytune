# The plugin: ONE .aex carrying ONE self-registering effect.
#
#   Windows   Mistytune.aex      -- a DLL with a renamed suffix
#   macOS     Mistytune.plugin   -- a CFBundle (untested; v1 is Windows-only)
#
# ---------------------------------------------------------------------------
# NO PiPL, NO AEGP, NO HOT-RELOAD STUB.
#
# The scaffolding this repo grew from was primarily an AEGP -- discoverable only
# through a PiPL resource -- carrying three inert parameter-carrier effects
# alongside it. Mistytune is a plain effect, and effects self-register on AE 2023+
# through PluginDataEntryFunction2. That removes the PiPL build chain and the whole
# class of version-mismatch failures that came with it.
#
# PLUGIN_HOT_RELOAD THEREFORE SELECTS ONLY THE BUILD SHAPE, which is what the rest
# of the project keys off:
#
#   ON  (default)  development  -- dynamic CRT, PF_Stage_DEVELOP
#   OFF (-Package) distribution -- static CRT, PF_Stage_BETA
#
# Both produce a single self-contained binary.
#
# THE FAST LOOP IS NOT IN HERE ANYWAY, and that is the design rather than a
# consolation. The parameter model, the fingerprint, the cache policy and the
# contour extraction are in src/engine/ and test in milliseconds with no SDK and no
# GPU; the renderer is in src/kernel/ and runs headless through src/cli/, where it
# can be golden-imaged, profiled and bisected. What is left here is host contact,
# which needs a host.
# ---------------------------------------------------------------------------

set(PLUGIN_AE_HEADERS
    AEBridge.h          # the ONLY place AE types meet engine and kernel types
    Build.h             # the version, single-sourced; CMake parses this file
    DiagLog.h           # opt-in diagnostics, behind MISTYTUNE_DIAG=1
    EffectCommon.h      # the registration numbers, static_asserted against CMake
    Params.h            # the parameter table: enum, setup and checkout from ONE list
)

set(PLUGIN_AE_SOURCES
    Mistytune.cpp       # registration, GPU device setup, pre-render, both render paths
)

add_ae_effect(${PLUGIN_TARGET} ${PLUGIN_AE_HEADERS} ${PLUGIN_AE_SOURCES})

# plugin_kernel brings plugin_engine with it (PUBLIC), so the parameter model and
# the cache policy arrive through it rather than being linked twice.
target_link_libraries(${PLUGIN_TARGET} PRIVATE plugin_kernel plugin_identity)

if(NOT PLUGIN_HOT_RELOAD)
    # Flips PLUGIN_STAGE from PF_Stage_DEVELOP to PF_Stage_BETA in
    # src/ae/EffectCommon.h. THE STAGE IS PART OF THE PACKED VERSION NUMBER AE
    # CACHES, so cmake/EffectFlags.cmake derives its copy from this same switch --
    # otherwise a release build would register a version its own identity header
    # disagrees with, and only the release build would fail to load.
    target_compile_definitions(${PLUGIN_TARGET} PRIVATE PLUGIN_DIST_BUILD=1)
    message(STATUS "${PLUGIN_TARGET}: DISTRIBUTION shape -- static CRT, PF_Stage_BETA.")
endif()

if(APPLE)
    # `ld` ad-hoc signs the Mach-O it produces but knows nothing about the enclosing
    # bundle. Apple Silicon refuses to load code carrying no signature at all, so the
    # bundle is signed too -- inside-out, nested files first.
    plugin_adhoc_sign(${PLUGIN_TARGET} "$<TARGET_BUNDLE_DIR:${PLUGIN_TARGET}>")
endif()

# ---------------------------------------------------------------------------
# Copy the built plugin into the AE plug-ins folder. Prefer the build scripts, which
# locate AE rather than assuming a path; this is the CMake-native fallback.
if(APPLE)
    # Delete-then-copy, not copy-over: a bundle is a directory, so copying onto an
    # older install would leave that install's stale files alongside the new ones.
    add_custom_target(install_plugin
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${AE_PLUGIN_DIR}/${PLUGIN_TARGET}.plugin"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
                "$<TARGET_BUNDLE_DIR:${PLUGIN_TARGET}>"
                "${AE_PLUGIN_DIR}/${PLUGIN_TARGET}.plugin"
        DEPENDS ${PLUGIN_TARGET}
        COMMENT "Installing ${PLUGIN_TARGET}.plugin -> ${AE_PLUGIN_DIR}"
        VERBATIM)
else()
    add_custom_target(install_plugin
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "$<TARGET_FILE:${PLUGIN_TARGET}>"
                "${AE_PLUGIN_DIR}/$<TARGET_FILE_NAME:${PLUGIN_TARGET}>"
        DEPENDS ${PLUGIN_TARGET}
        COMMENT "Installing ${PLUGIN_TARGET} -> ${AE_PLUGIN_DIR}"
        VERBATIM)
endif()
