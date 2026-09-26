# out_flags, out_flags2 and the encoded effect version -- written ONCE, here.
#
# WHAT THIS FILE IS FOR NOW THAT THERE IS NO PiPL.
#
# In the scaffolding this repo grew from, these numbers appeared twice: as raw
# decimals in a PiPL resource, and as symbolic PF_OutFlag_* constants in the C++.
# After Effects cached the PiPL's copy and compared it against what
# PF_Cmd_GLOBAL_SETUP reported at load, so disagreeing by a single bit meant:
#
#     effect "Mistytune" has version mismatch.
#     Code version is 1.0 and PiPL version is 1.0. (8001e)
#
# ...or "global outflags2 mismatch", and the plugin did not load. Both halves
# print 1.0 because the dialog shows only major.minor and the difference is in the
# build field, so the message actively misleads you about which field differs.
#
# MISTYTUNE HAS NO PiPL -- it self-registers -- so that particular trap is gone.
# The numbers are still single-sourced here, for a different and smaller reason:
# they land in the generated identity header, where src/ae/EffectCommon.h
# static_asserts them against the constants the effect actually sets. That makes
# a flag typo a compile error on this machine, and it keeps the packaging scripts
# and the diagnostics reading the same version the binary reports.

# PF_OutFlag_DEEP_COLOR_AWARE (1 << 25) = 33554432
#   -- 16 bpc. An effect that silently dropped to 8 bpc would band every gradient
#      in the sky, and a sky is very nearly all gradient.
#
# NOTE WHAT IS ABSENT: PF_OutFlag_PIX_INDEPENDENT.
#
# It says an output pixel depends only on the input pixel at the same coordinate,
# which is true of a pass-through and false of anything that integrates along a
# ray. Setting it would let AE hand back an output buffer smaller than the input
# and tile the render however it liked, and every pixel of a path trace depends on
# the whole field. It is also what made the predecessor's 3D crash possible.
math(EXPR MT_EFFECT_OUT_FLAGS "33554432")

# PF_OutFlag2_I_USE_3D_CAMERA              (1 << 1)  = 2
#   -- required before AEGP_GetEffectCameraMatrix will return anything, and the
#      thing that makes AE re-render when the comp camera moves. PHASE 1 DOES NOT
#      USE THE CAMERA YET and this flag is set anyway, deliberately: out_flags2 is
#      cached by AE against the binary, so adding it later costs a version bump
#      and a stale-cache hunt, while setting it early costs only some redundant
#      re-renders during development. Nothing has shipped, so it is free now.
#
# PF_OutFlag2_SUPPORTS_SMART_RENDER        (1 << 10) = 1024
# PF_OutFlag2_FLOAT_COLOR_AWARE            (1 << 12) = 4096
#   -- 32 bpc float. Legal ONLY alongside SUPPORTS_SMART_RENDER, and the format
#      the renderer actually works in: the accumulation buffer is linear radiance
#      and values above 1.0 are the sun.
#
# PF_OutFlag2_SUPPORTS_GPU_RENDER_F32      (1 << 25) = 33554432
#   -- the GPU opt-in. Must ALSO set PF_RenderOutputFlag_GPU_RENDER_POSSIBLE at
#      pre-render, or AE takes the CPU path and never says why.
#
# PF_OutFlag2_SUPPORTS_THREADED_RENDERING  (1 << 27) = 134217728
#   -- the Multi-Frame Rendering opt-in. Without it After Effects puts up "This
#      effect may slow down Preview and Export as it is not optimized for
#      Multi-Frame Rendering" and drops MFR for every comp holding the effect.
#
#      THIS FLAG IS A PROMISE ABOUT THE RENDER PATH, and it is the one to be
#      careful with here. It says AE may call render from any thread and have
#      several frames in flight in one process. For Mistytune that means: no
#      shared mutable renderer state, a field cache that is read-mostly with
#      explicit locking, and nothing on the render path that touches host streams.
#
#      IT ALSO MEANS SEEDS COME FROM (frame, sample index, pixel) AND NOTHING
#      ELSE -- never a clock, a thread id, or a counter shared between launches --
#      because motion blur renders one frame several times and MFR renders frames
#      on different workers. tests/golden/ holds the tripwire: the same inputs
#      rendered twice, and rendered again with a different worker count, must
#      compare identical.
#
#      In the predecessor this flag was blamed at length for a 3D crash it did not
#      cause (the real cause was a frozen AE-5.0-era copy call walking float
#      pixels at the wrong stride). Read that history before blaming it here:
#      docs/HOST-NOTES.md has the short version.
math(EXPR MT_EFFECT_OUT_FLAGS2 "2 | 1024 | 4096 | 33554432 | 134217728")

# AE's packed version field: major<<19 | minor<<15 | bug<<11 | stage<<9 | build.
#
# THE STAGE IS PART OF IT, which is the half people miss. PF_Stage_DEVELOP is 0
# and PF_Stage_BETA is 2, so flipping build shape CHANGES THIS NUMBER. Derived
# from the same PLUGIN_DIST_BUILD switch the C++ uses, so the two cannot drift.
if(PLUGIN_HOT_RELOAD)
    set(_mt_stage 0)   # PF_Stage_DEVELOP
else()
    set(_mt_stage 2)   # PF_Stage_BETA
endif()

math(EXPR MT_EFFECT_VERSION
     "(${_plugin_major} << 19) | (${_plugin_minor} << 15) | (${_mt_stage} << 9) | ${_plugin_build}")

message(STATUS "Effect registration: version=${MT_EFFECT_VERSION} "
               "out_flags=${MT_EFFECT_OUT_FLAGS} out_flags2=${MT_EFFECT_OUT_FLAGS2}")
