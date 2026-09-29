# After Effects host notes

Things about the AE SDK that are not in the documentation, or are in it and
wrong. Each one cost real debugging time. Read this before you spend a day on a
symptom that is listed here.

The rule underneath all of them: **measure host conventions, do not infer
them.** When you do not know what AE hands you, log the actual numbers out of a
running host and read them. `src/ae/DiagLog.h` exists for exactly this.

## Registration and versions

**AE caches an effect's registration against the plugin file.** Version,
`out_flags`, `out_flags2`, parameter list, effect name, match name and category
are all read once and remembered. Change any of them without a new version and
AE either ignores the change or refuses to load with a mismatch error.

**The version must live where the stub can see it** — `src/ae/Build.h`, not the
effect source. In the development (hot-reload) shape the effect compiles into
the impl library, not into the file AE loaded. If the version lived only there,
bumping it would leave the stub byte-identical, `copy_if_different` would skip
the install, and AE's cache would survive a full close-install-relaunch cycle
untouched. `StubMain.cpp` exports a build-stamp symbol naming `PLUGIN_BUILD` so
a bump always changes the stub's bytes too.

**"Version mismatch. Code version is 1.0 and PiPL version is 1.0 (8001d/8001e)"**
means the cached registration and the loaded code disagree. Both halves print
1.0 because the dialog shows only major.minor and the difference is in the build
field. Usual cause: a hot-swapped impl reporting a version the stub AE loaded
does not claim. Fix: quit AE, install properly, relaunch.

**`PF_OutFlag2_FLOAT_COLOR_AWARE` is legal only with `SUPPORTS_SMART_RENDER`.**

**Changing `out_flags2` without a version bump** gives "global outflags2
mismatch".

**Effects self-register on AE 2023+** via `PluginDataEntryFunction2` /
`PF_REGISTER_EFFECT_EXT2`. There is no PiPL step on either platform. Supporting
pre-2022 hosts brings it back on both.

## Parameters

**Indices are positions, and AE stores values by position.** Reordering or
deleting a shipped parameter silently rewires every saved project. Append new
ones; retire old ones by hiding them. Parameter IDs are a separate namespace and
must never be reused.

**The valid range is a hard limit, not a hint.** `PF_ADD_FLOAT_SLIDERX` takes a
valid range and a slider range. Values outside the valid range are refused when
typed *and silently flattened when driven by an expression or a keyframe*, which
is the expensive half — it looks like the expression is broken. Make the valid
range as wide as the maths allows and the slider range as wide as is
comfortable.

**Smart render does not get the params array.** Check parameters out with
`PF_CHECKOUT_PARAM` (see `ae::readFloatParam` in `src/ae/AEBridge.h`), and check
them back in.

**`PF_PUI_STD_CONTROL_ONLY` requires `PF_ParamFlag_SUPERVISE`.** That pairing is
mandated, not a choice. It is the usual way to fake a static text label, since
the parameter API has no such control: the parameter's *name* carries the
message and `PF_UpdateParamUI` rewrites it.

**`PF_UpdateParamUI` cannot change a valid range.** Only AE re-running
`PARAMS_SETUP` after a version change can, so a range fix needs a full install
and restart, never a hot swap.

## Pixels and resolution

**AE's 16-bit channels run 0..32768, not 0..65535.** Using 65535 makes 16bpc
renders come out roughly half as bright — subtle enough to survive a casual
look.

**Ask the world what format it is**, per render
(`PF_WorldSuite2::PF_GetPixelFormat`). One binary serves 8, 16 and 32 bpc and
will be called with all three. The codes are FOURCCs and print as integers, so
keep the decode ring to hand — measured in AE 2026:

| logged | FOURCC | format | bytes/px |
| --- | --- | --- | --- |
| 1650946657 | `argb` | `PF_PixelFormat_ARGB32` | 4 |
| 909206881 | `ae16` | `PF_PixelFormat_ARGB64` | 8 |
| 842229089 | `ae32` | `PF_PixelFormat_ARGB128` | 16 |

Note that 8 bpc is the only one named by its channels; 16 and 32 are `ae16` and
`ae32`. Check `rowbytes / width` against the table — it is the independent
confirmation that the format code was read correctly.

**Buffers are premultiplied.** Colour above its own alpha composites as an
over-bright halo on every soft edge. Clamp for the integer formats; leave 32bpc
float alone, where values above 1.0 are legitimate HDR.

**Point parameters arrive downsample-scaled in X and Y but not in Z.** Typing
960,540 at Third resolution arrives as 320,180, while Z arrives unscaled. Slider
parameters are never scaled. Normalise in the bridge
(`ae::pointParamToComp`), not in the engine.

**At reduced resolution you get a smaller buffer**, and anything measured in
comp pixels has to be scaled or your effect changes shape when the user switches
preview quality.

## Colour management

**Bit depth and colour space are orthogonal.** There is no "32 bpc float is
linear, the integer worlds are display-referred" rule, though it is an easy one
to believe and this codebase shipped it. Measured in AE 2026 with Working Color
Space **None**: the host applies *no* transform on the way to the screen, at any
depth. An effect that filters someone else's pixels never meets this — whatever
encoding arrives, leaves. One that *makes* light has to choose, and the choice
follows the project, not the buffer.

The symptom of getting it wrong is the worst kind: the same comp renders
differently at two bit depths, and each looks perfectly plausible on its own.

**`AEGP_DoesViewHaveColorSpaceXform` asks about the comp VIEWER, not the render.**
It takes an `AEGP_ItemViewP`. A render-queue export has no viewer, so keying
output encoding off it makes the preview and the exported file disagree. Ask the
project instead: `AEGP_IsOCIOColorManagementUsed`, and the working space's own
profile via `AEGP_GetNewWorkingSpaceColorProfile` →
`AEGP_GetColorProfileApproximateGamma`.

**"Linearize Working Color Space" has no API.** Searched the AE 25.6 headers;
there is nothing that reads that checkbox. A project working in sRGB with
linearisation on is linear in fact and will report sRGB's gamma, and no plugin
can currently tell the two apart.

**In OCIO mode the working-space gamma is not what you would expect, and should
not be trusted.** Measured in AE 2026 on an OCIO-managed project:
`ocio=1`, `gamma=2.400`. If the OCIO working space were the config's
`scene_linear` role the gamma would be near 1. Either it is not, or
`AEGP_GetNewWorkingSpaceColorProfile` does not describe the OCIO working space
and falls back to something generic — Rec.709's transfer curve is 2.4, which is
suspicious. Ask `AEGP_IsOCIOColorManagementUsed` *first* and let it decide;
reading the gamma in OCIO mode gives the opposite answer.

**The AEGP colour-settings calls are legal from pre-render.** Measured, error
codes zero, across four frames and three bit depths:
`AEGP_RegisterWithAEGP`, `AEGP_GetEffectLayer`, `AEGP_GetLayerParentComp`,
`AEGP_GetNewWorkingSpaceColorProfile` and
`AEGP_GetColorProfileApproximateGamma`. None of them is *documented* for a
render thread, so write the fallback anyway — a wrong-thread call returns
`A_Err_WRONG_THREAD` (5) rather than crashing, which makes it cheap to try.

**An effect has no `AEGP_PluginID`**, and most AEGP colour calls want one.
`AEGP_UtilitySuite6::AEGP_RegisterWithAEGP` mints one for any plugin that asks.
Ask once and cache it.

**`AEFX_SuiteScoper` throws when a suite is missing.** For any suite the effect
must be able to do without — an older host, a call AE will not answer — acquire
through `SPBasicSuite::AcquireSuite` and check for null instead. A throw crossing
the AE boundary is never allowed. Note that
`reinterpret_cast<const void**>(&suitePtr)` is ill-formed; go through a
`const void*` local.

**A call made on the wrong thread returns `A_Err_WRONG_THREAD` (5)**, it does not
crash. So an undocumented call is cheap to *try* if every failure path falls back
to known-good behaviour and the error code is logged.

## Cameras, layers and paths

**`AEGP_GetEffectCameraMatrix` returns camera-to-world.** Invert it for a view
matrix. It requires `PF_OutFlag2_I_USE_3D_CAMERA`, and it is safe to call on a
render thread. A comp with no camera returns a zero plane size — fall back to a
default camera rather than failing, but keep track of *which* happened: "no
camera, defaulting" is correct, "the call failed" is a guess.

**Layer parameters arrive raw** — un-transformed, un-masked, with no effects
applied, and there is no way to ask for anything else. The layer's own
Position/Scale/Rotation keyframes are outside that boundary and do not come with
it. Pre-composing is the only way to bake them in.

**`PF_PathVertex` tangents are ABSOLUTE control-point positions**, not offsets
from the vertex — measured in AE 26.2.1. AEGP's identically-shaped
`AEGP_MaskVertex` documents the opposite, so do not "correct" it from that
header. Symptom of getting it wrong: gentle curves land roughly right while
tight curves are thrown off, worsening with distance from the origin, because a
bezier's endpoints do not move when the tangent convention is wrong — only the
curvature between them does.

**Keep layer and stream access off render threads.** Sample on the UI thread and
cache it in sequence data.

## Threading

**`PF_OutFlag2_SUPPORTS_THREADED_RENDERING` means several frames render at
once**, in the same process, through the same globals. Anything shared needs a
lock or needs not to be shared.

**Diagnostic logs interleave** under multi-frame rendering. Diagnose on a single
still frame.

## macOS

**The bundle must be classified `eFKT` / `FXTC`** in Info.plist. Wrong values and
AE skips the bundle at scan time with no error, no log line, and nothing in the
Effects panel.

**Apple Silicon refuses to load code with no signature at all.** Ad-hoc signing
(`codesign --sign -`) clears that bar, is free, and needs no Apple account. It
is *not* notarization: users still have to clear the quarantine flag on a
download by hand.

**`codesign` refuses to sign anything carrying Finder info or a resource fork.**
A working copy inside OneDrive, iCloud Drive or Dropbox gets those attributes
stamped on build output at random, so the build runs `xattr -cr` first. Without
it the build fails intermittently and it looks like a signing bug.

**Nesting a file inside a signed bundle breaks the bundle's seal.** Sign
inside-out: nested files first, the bundle last.

**`std::filesystem::copy_file` carries extended attributes across**, including
`com.apple.quarantine`. That is why the hot-reload shadow copy strips it before
`dlopen` — otherwise Gatekeeper stalls ~13 seconds on a modal and then refuses
the load, and the effect silently does nothing.

**`dlclose` is advisory.** An image with C++ static state may stay mapped, which
is why each hot-reload generation loads from its own path instead of overwriting
one.

**Install into AE's own `Plug-ins` folder**, not
`/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore`. MediaCore is
shared with Premiere and Media Encoder — they will probe an AE-only effect on
every launch — and it needs an admin prompt. AE's own folder is outside the
signed `.app` and is owned by the installing user.

## Windows

**A dynamically linked release build needs the VC++ redistributable**, and
`VCRUNTIME140_1.dll` in particular arrived later than many machines have. If it
is missing, AE fails to load the plugin and says *nothing* — indistinguishable
from installing it in the wrong folder. Release builds link the CRT statically
for this reason (~100 KB).

**AE is not always on C:.** Search every drive when locating the plug-ins folder.

**Unsigned DLLs get quarantined by some antivirus products**, usually silently.
If the file disappears from the plug-ins folder after you copy it, that is what
happened.

## Cross-platform

**Floating point contracts differently per compiler.** clang defaults to
`-ffp-contract=on` and fuses `a*b + c*d` into an FMA; MSVC does not under
`/fp:precise`. An expression that cancels to exactly zero on Windows can leave a
residue on arm64. The build turns contraction off so both platforms agree —
removing that flag changes render output.

**MSVC ignores `inline` where it matters most.** Per-pixel helpers left as real
calls in an inner loop dominated one profile. Check the disassembly before
assuming a small header function was inlined.
