#pragma once

// EVERYTHING THE RENDERER IS TOLD, in one plain struct.
//
// NO AE HEADERS, NO CUDA HEADERS, NO STL. This header is included by the effect,
// by the CLI, by the .cu translation unit and by the CPU reference, so it has to
// compile under every one of nvcc, MSVC and clang with nothing on the include
// path. That constraint is what makes golden images possible at all: the effect
// hands the kernel this struct and src/cli/ hands it the same struct, so a
// mismatch between the two is a difference in the struct and nowhere else.
//
// It is the reason src/kernel/ is a separate directory from src/ae/ rather than a
// file inside it.

#include "../engine/Atmosphere.h"
#include "../engine/CloudParams.h"
#include "../engine/ConvectionField.h"
#include "../engine/IceField.h"

#include "AirMapPlan.h"

// The pareidolia map is HOST data the request only points at; see `shapeMap` below.
namespace plugin::cloud { struct ShapeMap; }

// ...and so are the local lights (build 29); see `lightSet` below.
namespace plugin::cloud { struct LightSet; }

// ...and so is the scene's depth pass (build 30); see `sceneDepth` below.
namespace plugin::cloud { struct SceneDepthMap; }

namespace plugin::kernel {

// WHERE A PIXEL'S FOUR FLOATS SIT IN MEMORY, and it is not the same on both
// paths -- which is a bug waiting to happen, so it is a parameter rather than an
// assumption.
//
//   AE's CPU worlds are ARGB: PF_PixelFloat is { alpha, red, green, blue }.
//   AE's GPU worlds are BGRA: PF_PixelFormat_GPU_BGRA128 is
//                             { blue, green, red, alpha }.
//
// Getting it wrong does not crash and does not look obviously broken -- it looks
// like the sky has the wrong colour balance, which reads as a bug in the
// atmosphere model rather than as a channel swap. Ask, do not assume.
enum class ChannelOrder : int {
    ARGB = 0,   // AE CPU worlds, 8/16/32 bpc
    BGRA = 1    // AE GPU worlds, PF_PixelFormat_GPU_BGRA128
};

// The destination surface.
//
// PITCH IN PIXELS, NOT BYTES, matching what the GPU sample passes its kernels
// (rowbytes / bytes_per_pixel). A row stride is never assumed to equal the width:
// AE pads rows, and at reduced resolution the buffer is a different shape again.
struct Surface {
    void* data      = nullptr;
    int   widthPx   = 0;
    int   heightPx  = 0;
    int   pitchPx   = 0;          // elements of 4 floats per row
    ChannelOrder order = ChannelOrder::ARGB;
};

// One render, fully specified.
//
// THE SPLIT MIRRORS FieldParams / ViewParams FOR THE SAME REASON THEY EXIST: the
// field is expensive and the view is not. See src/engine/FieldCache.h.
struct RenderRequest {
    cloud::FieldParams   field;
    cloud::ViewParams    view;
    cloud::QualityParams quality;

    // -----------------------------------------------------------------------
    // WHAT THE HOST DERIVED FROM `field`, BECAUSE THE KERNEL CANNOT
    // -----------------------------------------------------------------------
    //
    // Each of these is a pure function of the parameters above -- no pixel, no
    // sample, no ray in any of them -- so working them out on the GPU would be the
    // same answer recomputed a few billion times a frame. src/engine/IceField.h owns
    // the arithmetic and tests/unit/ checks it without a card.
    //
    // NOBODY HAS TO REMEMBER TO FILL THEM IN. deriveRenderInputs() in KernelApi.h is
    // called by renderCpu, renderCuda and renderCudaToHost on their own copy of the
    // request, so a caller that leaves them zero still renders correctly. They are
    // in the struct rather than in a side channel because the kernel reads them and
    // the kernel is handed exactly this.
    //
    // A DERIVED VALUE IS NOT A PARAMETER and none of this is hashed: FieldCache keys
    // on FieldParams, and these move only when it does.

    // The shear profile integrated into horizontal displacement, 33 knots. This is
    // the hook -- see IceField.h, where the integral is argued for at length.
    cloud::DriftTable drift;

    // WHERE THE KERNEL READS THAT TABLE FROM, which is not always the field above.
    //
    // Host memory on the CPU path -- it points straight at `drift.xz` -- and DEVICE
    // memory on the CUDA one, because a kernel cannot dereference a host pointer and
    // taking the address of a kernel parameter spills 264 bytes per thread. The
    // render entry points set it; a caller never does.
    //
    // The same rule the accumulator and the destination live under, for the same
    // reason: this file describes a render, and where its memory lives is part of
    // the description rather than something the kernel should have to guess.
    const void* driftBuffer = nullptr;

    // ===================================================================
    // THE TRANSMITTANCE TABLE, AND IT IS A POINTER RATHER THAN A MEMBER FOR A REASON
    // THAT IS NOT STYLE.
    //
    // THIS STRUCT GOES TO THE DEVICE AS A KERNEL ARGUMENT BLOCK, which CUDA caps at
    // 4 KB. The table is 256 x 64 x 3 floats -- 196 KB. Putting it here by value, the
    // way DriftTable's 264 bytes sit above, would not fail at runtime: it would fail
    // at LAUNCH, as an invalid configuration, on every frame.
    //
    // WHERE THE STORAGE ACTUALLY IS: a thread-local cache owned by the kernel
    // library, keyed on the three parameters the table depends on -- see
    // deriveRenderInputs() in KernelApi.h. It is rebuilt only when turbidity, planet
    // radius or scale height move, which is what makes it affordable at all; a table
    // rebuilt per launch would cost more than the march it replaces.
    //
    // SAME TWO-MEMORIES RULE AS driftBuffer. deriveRenderInputs() leaves the HOST
    // pointer here; renderCuda uploads from it and overwrites this with the device
    // pointer before the launch. A caller never sets it.
    const void* transmittanceBuffer = nullptr;

    // THE GROUND'S SKYLIGHT, linear RGB: albedo / pi times the sky's irradiance on flat
    // ground. Derived, like the table above, and from the same thread-local kind of cache
    // (deriveRenderInputs). By value, because it is three floats. See
    // SkyInput.groundSkyLight in SkyLib.slang for why the ground needs it.
    float groundSkyLight[3] = { 0.0f, 0.0f, 0.0f };

    // A sound upper bound on the medium's density per metre, resolved from
    // quality.densityMajorant when the user pinned one and derived structurally
    // otherwise. NEVER sampled from the field: see IceField.h on why a bound that is
    // merely usually right is worse than a loose one.
    cloud::Real densityMajorant = 0.0f;

    // The crystal's terminal velocity, m/s -- the habit's own speed times the
    // artist's multiplier, floored so it cannot divide by zero.
    cloud::Real fallSpeed = 0.0f;

    // Where the generating level itself has drifted to by field.timeSeconds. The
    // streaks hang off the cells, so moving the cells moves the whole sky as one
    // thing rather than as a pattern crawling through a fixed window.
    cloud::Real cellDriftX = 0.0f;
    cloud::Real cellDriftZ = 0.0f;

    // How the ice layer's generating cells are arranged, resolved (build 20). The cumulus
    // layer's rides in `convection` below.
    cloud::OrganizationResolved iceOrganization;

    // The convection layer's derived half: its base at the condensation level, how tall
    // its towers may grow, where its cells have drifted and how far through their lives
    // they are, and its droplets' phase function. `present` is false when there can be
    // no cumulus at all -- the layer is off, or the air is too dry to saturate under the
    // lid. See src/engine/ConvectionField.h.
    cloud::ConvectionDerived convection;

    // ===================================================================
    // PAREIDOLIA (build 21): the hero's silhouette from another layer's matte.
    //
    // `shapeMap` IS THE ONE THING A CALLER SETS, and it is HOST memory the caller owns for
    // the length of the render: the effect builds it from the layer it checked out, the
    // CLI from a file. Null is no shape. THE DEVICE NEVER DEREFERENCES IT -- this struct
    // is a kernel argument, and deriveRenderInputs() reads what the kernel needs out of it
    // on the host: the placement into `shape`, by value, and the texels' address into
    // `shapeBuffer`, which renderCuda then replaces with a device copy, as it does the
    // transmittance table. `shapeHash` is the map's own, which keys that upload and the
    // shadow maps' build: the picture is not a parameter, so nothing else would notice it
    // change.
    // ===================================================================
    const cloud::ShapeMap* shapeMap = nullptr;
    cloud::ShapeGeometry   shape;
    const void*            shapeBuffer = nullptr;
    uint64_t               shapeHash   = 0;

    // ===================================================================
    // LOCAL LIGHTS (build 29): the comp's lights and a light layer, packed on the host by
    // src/engine/LocalLights.h.
    //
    // `lightSet` IS THE ONE THING A CALLER SETS, and like the shape map it is HOST memory
    // the caller owns for the render; null is no lights. deriveRenderInputs() reads the
    // rest out of it: the buffer's address, which renderCuda replaces with a device copy
    // keyed on `lightHash`, the record count and the float count the kernel bounds its
    // reads by, and the ambient light's radiance, by value.
    // ===================================================================
    const cloud::LightSet* lightSet    = nullptr;
    const void*            lightBuffer = nullptr;
    int                    lightCount  = 0;
    int                    lightFloats = 0;
    uint64_t               lightHash   = 0;
    float                  ambientLight[3] = { 0.0f, 0.0f, 0.0f };

    // ===================================================================
    // SCENE INTEGRATION (build 30): the footage's depth pass, resolved on the host to metres
    // along the view axis and a coverage per texel by src/engine/SceneDepth.h.
    //
    // `sceneDepth` IS THE ONE THING A CALLER SETS, host memory it owns for the render, as the
    // shape map is; null is no geometry, and then every sample runs exactly the arithmetic it
    // ran before build 30. deriveRenderInputs() reads the rest out of it, and renderCuda
    // replaces the buffer with a device copy keyed on `sceneHash`. The texels are read per
    // SAMPLE, in Shading.h, where the camera ray is made: a sample that lands on geometry has
    // its camera ray stopped there.
    // ===================================================================
    const cloud::SceneDepthMap* sceneDepth  = nullptr;
    const void*                 sceneBuffer = nullptr;
    int                         sceneWidth  = 0;
    int                         sceneHeight = 0;
    uint64_t                    sceneHash   = 0;

    // THE REASON ALL FIVE ARE HERE RATHER THAN COMPUTED WHERE THEY ARE USED: the
    // marshalling into the kernel's structs runs ON THE DEVICE, inside renderPixel,
    // and src/engine/ is host code. A device function cannot call iceFallSpeed(), so
    // the answer has to arrive as data. That is not a limitation worth working
    // around -- it is the same reason the drift table is a table.

    // WHICH SAMPLES THIS LAUNCH IS RESPONSIBLE FOR, as a half-open range into the
    // frame's total sample budget.
    //
    // THIS IS THE TDR MITIGATION, and it is why the renderer is chunked at all.
    // The Windows display driver's timeout is about two seconds; a full-quality
    // frame sits exactly on it, and the failure is a driver reset rather than a
    // slow render. So a frame is many launches, each responsible for a slice of
    // the samples, with the accumulation buffer persisting between them.
    //
    // IT IS ALSO WHERE DETERMINISM COMES FROM. The seed for a sample is derived
    // from (frame, sampleIndex, pixel) and the field's own seed -- never a clock,
    // a thread id, or a counter shared between launches. Motion blur renders one
    // frame several times and MFR renders frames on different workers, so
    // anything else gives a different image on the second pass.
    int firstSample = 0;
    int sampleCount = 1;

    // THE CAMERA SEGMENT'S SUN: 0 is delta tracking's single next event at the first
    // real collision; 1 or more is a continuous estimate over tentative collisions
    // along the camera ray, drawn at this multiple of the majorant (values between 0
    // and 1 are raised to 1, because below it the estimate is biased). Both are
    // unbiased; they differ in noise, flicker and cost. See cameraSegmentSun in
    // BounceLib.slang.
    //
    // 1, AND MEASURED (PROGRESS.md, 2026-09-29): at 1 spp denoised it cuts the
    // flicker by 42% and the RMSE by 42% for 2.2x the time per sample, and beats
    // delta tracking at 3 spp on every measure. Scale 2 buys ~5% more for 15% more
    // time. Not a user parameter and not hashed -- it is the renderer's estimator,
    // chosen here once, and 0 survives only so the CLI can A/B it.
    float neeTentativeScale = 1.0f;

    // THE AIR BETWEEN THE EYE AND THE FIRST CLOUD: its airlight in front, its
    // transmittance on the cloud behind. ON, because it is the physics; OFF survives so
    // the CLI can A/B it and so the goldens blessed before build 17 can be reproduced.
    // Not hashed and not a user parameter, like the two knobs beside it. Whether the
    // clouds' shadows fall in that air is a user parameter, and lives in
    // AtmosphereParams::cloudShadowsInMedium.
    bool aerialPerspective = true;

    // THE CUMULUS LAYER'S PROCEDURAL MAJORANT GRID, on or off. An A/B knob for the CLI
    // and nothing else, like neeTentativeScale: any majorant at or above the density is
    // unbiased, so this moves cost and never the converged image. Not hashed.
    //
    // OFF, AND THAT IS A MEASUREMENT. 640x360 at 32 spp, grid on against off:
    //
    //     empty layer, low camera     0.42 s  vs  1.10 s
    //     sparse field, low camera    5.86 s  vs  3.56 s
    //     dense field, low camera     6.62 s  vs  4.48 s
    //     dense field, looking up     1.90 s  vs  1.42 s
    //
    // It wins only where there is no cloud to render. With clouds near, a camera ray
    // meets one within a kilometre or two, and each box crossed costs about what the
    // null collisions it saves would have. Aligning the boxes to the lattice, taller
    // boxes and giving the grid only to walks that start outside the layer were each
    // measured and none changed the verdict. The grid stays because it is proved correct
    // (slang.convection) and a denser or sparser default may yet want it.
    bool convectionGrid = false;

    // THE CLOUDS' SHADOW MAPS, ONE PER LAYER, built once per frame: the clouds' shadows in
    // the air and, since build 19, on the ground. False falls back to build 17's one shadow
    // ray per camera ray for the air and leaves the ground unshadowed. An A/B knob for the
    // CLI, like the two above: not hashed and not a user parameter. Whether the AIR's
    // shadows are there at all is AtmosphereParams::cloudShadowsInMedium. See AirMapLib.
    bool airShadowMap = true;

    // THE MAP'S TEXEL BUDGET: this many squared for the cumulus, a quarter of that for the
    // cirrus. Not hashed, like airShadowMap. See AirMapPlan.h.
    int airMapResolution = 512;

    // ===================================================================
    // WHERE THE MAPS LIE AND THE ONE BUFFER THAT HOLDS BOTH, filled by the render entry
    // points exactly as transmittanceBuffer is: a caller never sets them.
    //
    // THE PLAN RIDES HERE BY VALUE, a few dozen scalars, because the kernel marshals it
    // into LayerShadowMap per sample. THE TEXELS DO NOT. The cumulus map is 16 MB, and
    // this struct is a kernel argument, capped at 4 KB. They live in a thread-local cache
    // keyed on everything a column reads, so the bands and sample chunks of one frame build
    // them once. See AirMapHost.h.
    // ===================================================================
    AirMapPlan  airMaps;
    const void* airMapBuffer = nullptr;

    // THE GPU RENDER IN STAGES (build 25): every sample's camera ray and first bounce in one
    // launch, then one launch per bounce over the paths still alive. FALSE is the single
    // kernel that traces each pixel's paths start to finish, which survives only so the CLI
    // can A/B it: the two are the same arithmetic and give the same bits. Not hashed and not
    // a user parameter, like the knobs above. See PathState in BounceLib.slang.
    bool stagedGpu = true;

    // THE LOOK (build 32), and the Stylized look's controls. Physical, the default, is every
    // frame before this build. Stylized is drawn by renderStylizedCudaToHost / renderStylizedCpu
    // instead of the path trace, and reads nothing below this line but `dest`. See
    // StylizedFrame.h.
    cloud::Look           look = cloud::Look::Physical;
    cloud::StylizedParams stylized;

    // THE CLI'S --style-tune: "name=value,..." overrides of the look's constants, for tuning
    // without a rebuild. See styleApplyTune in StylizedHost.h. Null everywhere else.
    const char* styleTune = nullptr;

    // Linear radiance, four floats per pixel, persisting across the launches of
    // one frame. Null on the CPU reference path, which accumulates in the
    // destination surface directly because it has nowhere else to put it.
    float* accumulator     = nullptr;
    int    accumulatorPitchPx = 0;

    // Total samples already in the accumulator BEFORE this launch. The kernel
    // needs it to weight its own contribution, and taking it as a parameter rather
    // than storing it per-pixel keeps the accumulator a plain radiance sum.
    int samplesAlreadyDone = 0;

    Surface dest;
};

} // namespace plugin::kernel
