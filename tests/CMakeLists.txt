# Unit tests for the engine. No AE SDK, no After Effects, no GPU, no host -- they
# build and run anywhere, which is what makes them the fast iteration loop.
#
# THIS IS TIER 1 OF THREE (PLAN.md, "Testing"). It covers the parameter model,
# the cache policy, the fingerprint's coverage and the contour extraction --
# everything whose answer does not depend on a renderer. Tier 2 is
# tests/golden/, which renders fixed scenes through src/cli/ and compares with
# tolerance; tier 3 is the in-host checks that are scripted but judged by eye.
#
# THE SPLIT EXISTS SO THAT THE FIRST TIER NEEDS NEITHER AE NOR A GPU. A path
# tracer that can only be tested inside After Effects cannot be bisected, and the
# whole reason src/engine/ holds no host and no GPU headers is to keep this loop
# measured in milliseconds.
#
# Target name is deliberately generic, so the build scripts need no edit when the
# plugin is renamed.

add_executable(plugin_tests
    unit/TestMain.cpp

    # The field fingerprint. The coverage test is the one that matters: a hash
    # that misses a parameter passes every other check you can write about it.
    unit/TestFingerprint.cpp

    # The three-way cache decision. CameraMoveKeepsTheField is the row PLAN.md
    # calls the difference between a plugin people use and one they abandon.
    unit/TestFieldCache.cpp

    # The shear integral and the majorant. ZeroShearGivesZeroDrift is the one that
    # matters: the frame-of-reference bug it catches renders a plausible sky rather
    # than an error, and was found by looking at a picture.
    unit/TestIceField.cpp

    # The convection layer's host half. The condensation level is the flat base, and
    # it is checked three independent ways -- a tabulated dew point, the 125 m/K rule,
    # and its 1/g scaling -- because a wrong one puts the cloud at a plausible height.
    unit/TestConvection.cpp

    # Ordered contours out of a matte: the front half of pareidolia.
    unit/TestContour.cpp

    # The frame/buffer/origin contract. Written after a reduced-resolution render
    # in AE came back flat blue; see the file's own header on why it could not have
    # caught that, and what it does guard instead.
    unit/TestCamera.cpp
    # The sun-camera presets. The row that matters is the one directly under the
    # hero: looking straight up has no forward heading, and a preset that flipped
    # there would swing the sun across the sky between two frames of one tilt.
    unit/TestSunPlacement.cpp
    # The classifier readout. The contract is AE's 31-character parameter name,
    # swept across the parameter space; the rest pin each atlas rule to a scene.
    unit/TestClassifier.cpp
    # The Organization group's host half: each control lands where the kernel reads
    # it, each mode is its setting, and the defaults are off.
    unit/TestOrganization.cpp

    # The output conversion: 8, 16 and 32 bpc, the sRGB curve and the alpha rule.
    # PLAN.md's Phase 1 exit asks for all three bit depths to be CORRECT, and until
    # this file existed the only instrument pointed at them was a person rendering in
    # After Effects. See the file's own header for why looking cannot settle any of the
    # three things in it.
    unit/TestOutputConvert.cpp

    # Whether the renderer encodes its own output. The tests that matter are the ones
    # about the DEFAULTS: a host that cannot be asked must decide what the hardcoded
    # constant used to, because the alternative darkens every render on every machine
    # where the AEGP calls do not answer -- and that is not a machine anyone here has.
    unit/TestColorManagement.cpp
    unit/TestDenoiser.cpp

    # The transmittance table, checked against closed forms rather than against
    # stored numbers. Every way of getting a lookup table wrong produces a smooth,
    # plausible, wrong sky -- see the file's header for the four that matter.
    unit/TestAtmosphere.cpp

    # Where the clouds' shadow maps lie. The contract is coverage: a lookup off the grid
    # answers "lit", so a grid that misses part of a shadow fails silently in a render.
    unit/TestAirMapPlan.cpp

    unit/TestFramework.h
)

# plugin_kernel for Shading.h, which TestCamera.cpp calls directly. It carries
# plugin_engine transitively and pulls in no AE header and no CUDA header on the
# host, which is what keeps this tier runnable anywhere.
target_link_libraries(plugin_tests PRIVATE plugin_kernel)

add_test(NAME unit COMMAND plugin_tests)

# Tier 2: golden images through mistytunec. The top-level CMakeLists adds
# src/cli/ before this directory so the target exists; golden/CMakeLists.txt
# still guards on it, so a build configured without the CLI degrades to skipping
# these rather than failing to configure.
add_subdirectory(golden)

# Tier 1b: Slang's math against CUDA's, bitwise. Guards the premise the Slang port
# rests on -- see tests/slang/MathParityMain.cu, and PROGRESS.md for the measurement
# that made the decision.
add_subdirectory(slang)
