# mistytunec -- the headless renderer.
#
# THE TEST HARNESS, BUILT IN THE SAME WEEK AS THE KERNEL rather than as a later
# convenience. A GPU path tracer that can only run inside After Effects cannot be
# golden-imaged, profiled or bisected -- see src/cli/Main.cpp for the full argument.
#
# NO AE SDK. It links plugin_kernel (which brings plugin_engine) and nothing else,
# which is what makes it buildable on a machine with no Adobe SDK on it at all -- and
# what makes a golden image taken here a meaningful statement about the effect.

add_executable(mistytunec Main.cpp)

target_link_libraries(mistytunec PRIVATE plugin_kernel)

# The binary keeps its lowercase name on every platform. It is a command, and
# ${PLUGIN_TARGET} is the plugin -- naming both "Mistytune" would make the install
# rules ambiguous on a case-insensitive filesystem.
set_target_properties(mistytunec PROPERTIES OUTPUT_NAME "mistytunec")
