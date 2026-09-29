# The engine: host-agnostic, unit-testable, ZERO After Effects headers and ZERO
# GPU headers.
#
# This target must never include anything from the AE SDK, CUDA, Metal or Slang.
# It is the parameter model, the classifier, the cache policy and the feature
# extraction -- the parts worth testing in milliseconds, and the parts that
# survive a host port. Host contact belongs in src/ae/; the renderer itself
# belongs in src/kernel/.
#
# THE SECOND HALF OF THAT RULE IS WHAT MAKES GOLDEN IMAGES POSSIBLE. The effect
# hands the kernel a plain struct of physics constants and a camera; src/cli/
# hands it the same struct. Neither can do that if the struct's own header needs
# a host to compile.
#
# Target name is deliberately generic (not the plugin's name) so this file needs
# no edit when the plugin is renamed.

add_library(plugin_engine STATIC
    Types.h
    Image.h

    # The parameter model, and the only definition of it. The AE effect, the CLI
    # and proto/ all mirror these names.
    CloudParams.h

    # AE's camera in the renderer's conventions -- a transpose and a handedness
    # flip, kept here rather than in src/ae/ so tests/unit/ can reach the one
    # piece of host arithmetic whose errors render a convincing wrong picture.
    CameraConvert.h

    # Whether the renderer encodes its own output, decided from what the project
    # says about its colour management rather than from a constant. Here for the
    # same reason CameraConvert.h is: every branch renders a plausible picture,
    # so every branch needs a test that does not involve looking at one.
    ColorManagement.h

    # The transmittance table: how much light survives from a point in the
    # atmosphere out to space. A pure function of turbidity, planet radius and
    # scale height, built ONCE per parameter change rather than per launch --
    # which is why it is host code and not a kernel loop. It replaces the inner
    # sun march that made the Phase 1 sky quadratic.
    Atmosphere.h
    Atmosphere.cpp

    # Intel Open Image Denoise, loaded at RUNTIME with no link-time dependency --
    # there is deliberately no OpenImageDenoise.lib on any link line here. A
    # load-time import of a missing DLL is a plugin After Effects refuses to load
    # at all, with an error naming the effect rather than the file. So this builds,
    # links and tests identically whether or not tools/oidn/ exists; what changes
    # is only what denoiserAvailable() answers at runtime.
    Denoiser.h
    Denoiser.cpp

    # The host's half of the ice generator: the shear integral that IS the
    # fallstreak hook, the habit fall speeds, and a majorant that is sound by
    # construction rather than by sampling. All of it a pure function of the
    # parameters, which is why it is here and not in the kernel.
    IceField.h
    IceField.cpp
    # The host's half of the convection generator: the condensation level that IS
    # the flat base, the steering wind, the cells' clock, and the droplets' phase
    # function -- each a pure function of the parameters.
    ConvectionField.h
    ConvectionField.cpp

    # 2D primitives for the contour tracer. What is left of the rigid-body
    # engine's Hull.h once the hull builder went with the solver.
    Geometry.h
    Geometry.cpp

    # Ordered contours out of an alpha channel: the front half of pareidolia.
    Contour.h
    Contour.cpp

    # "Would rebuilding the field give a different sky?", answered by a hash
    # instead of a rebuild -- with the sizeof tripwire that breaks this build
    # when a new parameter goes unhashed.
    Fingerprint.h
    Fingerprint.cpp

    # ...and the cache that question exists to serve. Three-way, so a camera
    # move keeps the field and only clears the accumulator.
    FieldCache.h
    FieldCache.cpp
)

target_include_directories(plugin_engine PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

set_target_properties(plugin_engine PROPERTIES LINKER_LANGUAGE CXX)
