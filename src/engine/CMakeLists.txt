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
