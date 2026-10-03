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
# PF_OutFlag_PIX_INDEPENDENT (1 << 10) = 1024
#   -- ADDED after reading the SDK's own wording instead of paraphrasing it:
#      "Set this flag if the output at a given pixel is not dependent on the values
#      of THE PIXELS AROUND IT." It is a statement about the INPUT IMAGE.
#
#      This file previously argued the flag would be a lie because "every pixel of
#      a path trace depends on the whole field". That conflates the SCENE with the
#      INPUT IMAGE. Mistytune is a generator: it does not read its input at all, so
#      no output pixel depends on any input pixel, neighbouring or otherwise. The
#      same note also attributed "AE may hand back an output buffer smaller than the
#      input" to this flag, which is PF_OutFlag_I_SHRINK_BUFFER.
#
#      The SDK's own GPU sample (SDK_Invert_ProcAmp) sets it, and it is one of only
#      two registration differences left between that sample and this effect -- the
#      other being SUPPORTS_DIRECTX_RENDERING, which cannot honestly be set without
#      a DirectX kernel behind it.
#
#      WHEN THIS STOPS BEING TRUE: Phase 4's pareidolia reads the input layer and
#      traces contours through it, at which point an output pixel DOES depend on its
#      neighbours and the flag becomes a lie. It is overridable at
#      PF_Cmd_QUERY_DYNAMIC_FLAGS, which is the documented way to withdraw it --
#      and doing so requires PF_OutFlag2_SUPPORTS_QUERY_DYNAMIC_FLAGS, which this
#      effect does not set yet. That is the Phase 4 task, not a reason to keep
#      declaring something false today.
#
#      BUILD 21: IT STOPPED BEING TRUE, AND THE FLAG IS GONE. Pareidolia reads a
#      whole layer through a layer parameter, so every output pixel depends on all
#      of it. Dropped outright rather than withdrawn per frame: while it was set it
#      changed nothing that was measured -- not the GPU offer (see below), not a
#      timing -- so the dynamic-flags machinery would buy nothing. The number below
#      no longer carries 1024.
#
# PF_OutFlag_DEEP_COLOR_AWARE (1 << 25) = 33554432
#
# PF_OutFlag_SEND_UPDATE_PARAMS_UI (1 << 26) = 67108864
#   -- build 17. PF_Cmd_UPDATE_PARAMS_UI is what names the classifier readout when
#      the Effect Controls open and when a project loads. Without it the readout
#      says "--" until a supervised control is touched.
#
# PF_OutFlag_NON_PARAM_VARY (1 << 2) = 4
#   -- build 24, and missing since Phase 1. The output depends on the frame's time --
#      the cumulus cells drift, live and billow by it, the ice drifts by it -- and
#      without this AE treats an effect on a solid with nothing keyframed as one frame,
#      rendered once and played back.
math(EXPR MT_EFFECT_OUT_FLAGS "4 | 33554432 | 67108864")

# PF_OutFlag2_I_USE_3D_CAMERA              (1 << 1)  = 2
#   -- required before AEGP_GetEffectCameraMatrix will return anything, and the
#      thing that makes AE re-render when the comp camera moves. PHASE 1 DOES NOT
#      USE THE CAMERA YET and this flag is set anyway, deliberately: out_flags2 is
#      cached by AE against the binary, so adding it later costs a version bump
#      and a stale-cache hunt, while setting it early costs only some redundant
#      re-renders during development. Nothing has shipped, so it is free now.
#
# PF_OutFlag2_I_USE_3D_LIGHTS              (1 << 2)  = 4
#   -- build 29. The comp's lights light the clouds (src/engine/LocalLights.h), read at
#      pre-render through the layer suite. The SDK says this bit must be set by an effect
#      that reads light layers, and it is what makes AE re-render when one moves, changes
#      intensity or is switched off -- without it a keyframed lightning flash would play
#      back from the cache unlit.
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
# MEASURED: I_USE_3D_CAMERA DOES NOT DISQUALIFY AN EFFECT FROM AE'S GPU PIPELINE.
#
# Tested directly on AE 2026, 32 bpc float project, Mercury GPU Acceleration set to
# CUDA, a working CUDA build, and a registration with bit 1 REMOVED
# (out_flags2 167777280 instead of 167777282, version bumped so AE could not serve
# a cached registration). Pre-render still reported:
#
#     PRE_RENDER: AE offers what_gpu=NONE device_index=-1 bitdepth=32
#
# identically to the run with the flag present. So the flag is not the gate, and
# the reason AE declines to GPU-render this effect is still unknown. Recorded here
# because a plausible, cheap-to-test hypothesis that turns out to be WRONG is worth
# exactly as much as one that is right -- and this one will otherwise be re-tested
# by the next person who reads the pre-render log.
#
math(EXPR MT_EFFECT_OUT_FLAGS2 "2 | 4 | 1024 | 4096 | 33554432 | 134217728")

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
