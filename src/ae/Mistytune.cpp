// Mistytune: the effect.
//
// ONE effect, self-registering, with a GPU render path and a CPU fallback.
//
// ===========================================================================
// WHAT PHASE 1 IS, STATED HERE SO NOBODY MISTAKES THE PLACEHOLDER FOR THE PRODUCT.
//
// This file is the complete HOST side of a GPU effect: registration, the parameter
// table, GPU device setup and setdown, pre-render, smart render on both the GPU and
// the CPU, all three bit depths, reduced resolution, and the diagnostic line naming
// the device AE handed us.
//
// WHAT IT RENDERS IS NO LONGER A PLACEHOLDER. Null-collision tracking, the bounce
// loop, the Jendersie-d'Eon phase function, the precomputed transmittance table and
// the ice generator all landed across 2026-09-28 and 09-29; this file hands them a
// FieldParams and gets float pixels back.
//
// THE PARAMETER TABLE IS THE PART THAT LAGGED, and it lagged invisibly. The ice
// generator was plumbed and hashed for a day before a single one of its parameters
// had a control, so `field.ice` kept the struct's defaults through every render made
// in that time -- one sky, correct, and unreachable. The `toIce` line in preRender
// below is the whole of the fix; see Params.h on why the group is inserted rather
// than appended.
//
// The host/renderer split is still on purpose. Phase 1's exit criterion was about the
// HOST -- that a parameter typed in After Effects reaches a GPU kernel and comes back
// as correct float pixels at 8, 16 and 32 bpc and at reduced resolution. Proving that
// with a renderer that also had to be right would have confounded two unrelated kinds
// of bug, which is why it was proved first and against an analytic sky.
// ===========================================================================

#include "AEBridge.h"
#include "EffectCommon.h"
#include "Params.h"

#include "Denoiser.h"
#include "FieldCache.h"
#include "Fingerprint.h"
#include "KernelApi.h"
#include "Pareidolia.h"

#include <algorithm>
#include <cstring>
#include <thread>
#include <new>
#include <vector>

using namespace plugin;
using namespace plugin::ae;

namespace {

// ---------------------------------------------------------------------------
// Naming AE's GPU framework
// ---------------------------------------------------------------------------

// ONE SPELLING, USED BY BOTH DEVICE SETUP AND PRE-RENDER.
//
// PF_GPU_Framework_NONE is the value that matters most and is the easiest to skip
// over: it does not mean "unknown framework", it means AE HAS ALREADY DECIDED THIS
// RENDER IS A CPU RENDER. An effect that only logs the framework at device setup
// never sees it, because device setup is only called for a real device.
inline const char* frameworkName(PF_GPU_Framework what) {
    switch (what) {
        case PF_GPU_Framework_CUDA:    return "CUDA";
        case PF_GPU_Framework_OPENCL:  return "OpenCL";
        case PF_GPU_Framework_METAL:   return "Metal";
        case PF_GPU_Framework_DIRECTX: return "DirectX";
        case PF_GPU_Framework_NONE:    return "NONE (AE is not GPU-rendering this frame)";
        default:                       return "unrecognised";
    }
}

// ---------------------------------------------------------------------------
// What pre-render hands to render
// ---------------------------------------------------------------------------

// PARAMETERS ARE READ AT PRE-RENDER AND CARRIED FORWARD, not re-read at render.
//
// Not an optimisation. Under multi-frame rendering several frames are in flight, and
// checking parameters out on a render thread is the kind of host contact that
// docs/HOST-NOTES.md says to keep off render threads. Pre-render is the documented
// place to do it, and pre_render_data is the documented way to carry the result.
struct PreRenderData {
    cloud::FieldParams   field;
    cloud::ViewParams    view;
    cloud::QualityParams quality;

    // The cache key, computed once here rather than twice on two render paths.
    sim::RenderKey key;

    // WHERE THE BUFFER AE WILL HAND BACK SITS IN THE FRAME, recorded here because
    // this is the only place the host says so.
    //
    // in_data->output_origin_x/y IS NOT THAT, AND READING IT WAS A BUG. Measured in
    // AE 2026 with a Region of Interest drawn over part of the frame: pre-render was
    // asked for [633,387 907x751], returned a result_rect of [633,387 907x693], and
    // was handed a 907x693 buffer at smart render -- with output_origin_x/y both
    // reporting ZERO. The renderer therefore drew the top-left 907x693 of the sky
    // into a buffer AE composited at (633,387), which on a sky whose top-left corner
    // is empty is a flat pale-blue rectangle, and reads as a broken effect rather
    // than as a missing offset. The THIRD time this project has shipped that shape of
    // bug: see the reduced-resolution entry in PROGRESS.md.
    //
    // The result rect is the rect we TOLD AE we would fill, and the buffer that comes
    // back has matched it exactly every time it has been measured. renderOriginValid
    // records whether we actually got one, so smart render can say so rather than
    // silently trusting a zero.
    A_long renderOriginX = 0;
    A_long renderOriginY = 0;
    A_long renderWidth   = 0;
    A_long renderHeight  = 0;
    bool   renderOriginValid = false;

    // PAREIDOLIA'S SOURCE WAS CHECKED OUT, whole, under kShapeCheckout -- so smart render
    // may ask for its pixels. False for no layer picked, which is no shape.
    bool shapeCheckedOut = false;
};

// ===========================================================================
// THE CHECKOUT IDs FOR PAREIDOLIA'S SOURCE, which are ours to choose and only have to be
// distinct from every other checkout in this pre-render -- the input layer's is its
// parameter index, 0. TWO, BECAUSE THE WHOLE LAYER IS WANTED AND ITS SIZE IS NOT KNOWN
// until something has been checked out: the probe asks for what AE asked of us and reads
// back max_result_rect, the layer's whole extent; the second asks for exactly that. Only
// the second's pixels are ever checked out.
// ===========================================================================
constexpr A_long kShapeProbeCheckout = 7001;
constexpr A_long kShapeCheckout      = 7002;

// A SOURCE LARGER THAN THIS ON A SIDE IS CROPPED TO IT. The map is 256 texels across
// whatever the source is, so a bigger checkout only costs AE a render nobody reads.
constexpr A_long kShapeMaxSide = 8192;

void disposePreRenderData(void* p) {
    delete static_cast<PreRenderData*>(p);
}

// ---------------------------------------------------------------------------
// Per-instance state
// ---------------------------------------------------------------------------

// WHAT SEQUENCE DATA HOLDS, AND WHY IT IS NEARLY EMPTY IN PHASE 1.
//
// PF_OutFlag2_SUPPORTS_THREADED_RENDERING says AE may call render from any thread
// with several frames in flight in one process. So anything mutable here needs a
// lock or needs not to exist.
//
// Phase 1 chooses "not to exist": the render path is stateless, so there is nothing
// to protect.
//
// ===========================================================================
// THE ACCUMULATOR CACHE: ONE PER ENGINE, PER RENDER THREAD, BESIDE THE BUFFER IT
// DESCRIBES.
//
// It used to be a sim::FieldCache in SequenceData -- shared across every render thread
// AE has in flight for the layer -- describing accumulators that are NOT shared: both
// are thread_local, `g_accum` in CpuRender.cpp and the DeviceScratch of the same name in
// Mistytune.cu. A shared cache over per-thread buffers is wrong even with a lock: thread
// A records 32 samples, thread B is told "resolve", and resolves from ITS OWN buffer
// while the cache vouches for A's. A mutex makes that race deterministic. It does not
// make it correct.
//
// SO IT IS thread_local TOO, and nothing is shared, and no lock exists. A thread that
// has not rendered this frame sees an empty cache and renders from scratch -- exactly
// the behaviour before the cache existed. THE WORST CASE OF A MISS IS A SLOW FRAME.
//
// ONE PER ENGINE, BECAUSE THEY ARE TWO BUFFERS. A frame accumulated on the GPU is not in
// the CPU's accumulator, and the render loop can switch engines mid-frame on a driver
// failure. A single cache would vouch for whichever engine happened to render last.
//
// WHAT IT ADDS BEYOND sim::FieldCache is the geometry. The accumulator is indexed by
// row pitch, and pitch is in no hash -- AE's rowbytes can differ between two renders of
// the same frame -- so a resolve at a different pitch would read every row at the wrong
// stride. It renders; it is garbage. The check is cheap and the failure is silent.
// ===========================================================================
// THE LOGIC LIVES IN src/engine/FieldCache.h as sim::AccumulatorCache, where every one
// of its conditions is unit-tested without a host -- each of them guards a picture that
// would render plausibly and be wrong. Only the per-thread instances live here.
thread_local sim::AccumulatorCache t_cpuAccumCache;
thread_local sim::AccumulatorCache t_gpuAccumCache;

// Nothing is kept per sequence any more. The struct stays because the sequence-setup
// plumbing below allocates it, and a later per-layer setting has a home to go to.
struct SequenceData {
    int reserved = 0;
};

// ---------------------------------------------------------------------------
// GPU device state
// ---------------------------------------------------------------------------

// NOTHING TO ALLOCATE FOR CUDA, and the AE GPU sample says the same: the kernel is
// statically linked into this binary, so there is no program to compile at device
// setup and no handle to keep.
//
// OpenCL and DirectX would each need a compiled program cached per device here, and
// Metal a pipeline state. When the Metal path lands in Phase 5 this is where its
// MTLComputePipelineState goes, keyed by device index -- which is why the function
// exists at all rather than being left unhandled.
PF_Err gpuDeviceSetup(PF_InData* in_data, PF_OutData* out_data,
                      PF_GPUDeviceSetupExtra* extra) {
    PF_Err err = PF_Err_NONE;

    AEFX_SuiteScoper<PF_GPUDeviceSuite1> gpuSuite(in_data, kPFGPUDeviceSuite,
                                                  kPFGPUDeviceSuiteVersion1, out_data);

    PF_GPUDeviceInfo info;
    AEFX_CLR_STRUCT(info);
    err = gpuSuite->GetDeviceInfo(in_data->effect_ref, extra->input->device_index, &info);
    if (err) return err;

    // PLAN.md'S PHASE 1 EXIT CRITERION ASKS FOR EXACTLY THIS LINE: the diagnostic
    // log names the GPU device AE handed us. A render that silently fell back to the
    // CPU and was merely slow is the failure this catches -- and it is a failure
    // that is otherwise invisible, because the picture is identical.
    const char* framework = frameworkName(extra->input->what_gpu);

    diagLog("GPU_DEVICE_SETUP: device_index=%d framework=%s",
            static_cast<int>(extra->input->device_index), framework);

    // compatibleB IS AE'S OWN VERDICT on whether this device meets its minimum for
    // acceleration, and it is the one field worth logging above all the others: a
    // device AE considers incompatible will be handed to us anyway and then never
    // asked to render, which looks exactly like a kernel that does nothing.
    //
    // PF_GPUDeviceInfo carries no memory size or core count -- only the framework,
    // this flag, and the platform handles. The card's own description comes from the
    // renderer instead, which is why both lines are here.
    diagLog("  AE says compatible: %s", info.compatibleB ? "yes" : "no");
    diagLog("  renderer will use : %s", kernel::deviceDescription());

    if (extra->input->what_gpu != PF_GPU_Framework_CUDA) {
        // NOT AN ERROR, and returning one here would be wrong: AE asks every
        // framework it supports, and refusing a framework we do not implement is how
        // the CPU fallback gets chosen. Saying so in the log is what stops the
        // resulting slowness from being a mystery.
        diagLog("  %s is not implemented -- this device will use the CPU path.", framework);
    }

    return PF_Err_NONE;
}

PF_Err gpuDeviceSetdown(PF_InData* in_data, PF_OutData* out_data,
                        PF_GPUDeviceSetdownExtra* extra) {
    (void)in_data; (void)out_data; (void)extra;
    // Nothing allocated in setup, so nothing to release. See the note there.
    diagLog("GPU_DEVICE_SETDOWN: device_index=%d",
            static_cast<int>(extra->input->device_index));

    // ONE THING IS ALLOCATED ELSEWHERE AND IS RELEASED HERE: this thread's OIDN
    // session. An OIDN CUDA device holds a context and a few hundred MB, and AE may
    // issue a setdown between renders rather than at the end of the session -- so
    // leaving one alive per render thread after the GPU has been taken away is how the
    // next render fails for a reason that points nowhere near the denoiser.
    //
    // ONLY THIS THREAD'S, WHICH IS THE LIMIT OF WHAT A thread_local CAN DO. The
    // sessions belonging to AE's other render workers are released when those threads
    // end. That is a real gap and it is bounded: a session is rebuilt on demand, so the
    // worst case is memory held until the thread exits rather than a wrong picture.
    cloud::denoiserShutdown();

    // AND THIS THREAD'S GPU ACCUMULATOR CACHE, for the same reason: the device it
    // described is being taken away, and a cache that outlived its buffer would vouch
    // for memory that no longer holds the frame -- or no longer exists.
    t_gpuAccumCache.invalidate();

    return PF_Err_NONE;
}

// ---------------------------------------------------------------------------
// Pre-render
// ---------------------------------------------------------------------------

PF_Err preRender(PF_InData* in_data, PF_OutData* out_data, PF_PreRenderExtra* extra) {
    // KEPT IN THE SIGNATURE THOUGH UNUSED. Every suite acquisition wants an
    // out_data to report a missing suite through, and Phase 2's camera query is one
    // -- so dropping the parameter now would only mean putting it back.
    (void)out_data;

    PF_Err err = PF_Err_NONE;

    // THE GPU OPT-IN, AND IT IS TWO FLAGS AND NOT ONE.
    //
    // PF_OutFlag2_SUPPORTS_GPU_RENDER_F32 at global setup says the effect CAN render
    // on the GPU. THIS flag says this particular render MAY. Omit it and AE takes
    // the CPU path on every frame and never says why -- which presents as "the GPU
    // support does not work" rather than as a missing flag.
    //
    // ONLY OFFERED WHEN THERE IS ACTUALLY A GPU PATH TO TAKE, and that condition is
    // the point rather than a tidiness.
    //
    // This binary can be built with the CUDA kernel stubbed out (cmake/Cuda.cmake
    // selects CudaStub.cpp when no toolkit is present), and then claiming the flag
    // makes AE hand a 32-bpc-float project to PF_Cmd_SMART_RENDER_GPU, which has
    // nothing to render with and can only return an error. WHETHER AE FALLS BACK TO
    // THE CPU AFTER THAT ERROR IS AN ASSUMPTION AND NOT A MEASUREMENT -- and if it
    // does not, the frame simply fails, which is indistinguishable from an effect
    // that renders nothing. Not making the claim costs this build nothing, because
    // there is no GPU path in it to lose.
    // WHAT AE INTENDS, LOGGED BEFORE WE SAY WHAT WE CAN DO.
    //
    // This is the line that separates "the effect declined the GPU" from "AE never
    // offered it". PF_RenderOutputFlag_GPU_RENDER_POSSIBLE is our half of the
    // handshake and it is NOT sufficient on its own: if what_gpu is None here, AE
    // has already chosen a CPU render for this frame and nothing the effect sets
    // will change it. Without this line the two cases produce identical logs.
    diagLog("PRE_RENDER: AE offers what_gpu=%s device_index=%d bitdepth=%d",
            frameworkName(extra->input->what_gpu),
            static_cast<int>(extra->input->device_index),
            static_cast<int>(extra->input->bitdepth));

    // THE OFFER ITSELF IS MADE AT THE END, once pareidolia's source has been checked out:
    // see there for why a source withdraws it.

    // new rather than malloc, because PreRenderData holds C++ members with
    // constructors. nothrow because throwing into AE is never allowed and a
    // std::bad_alloc crossing the boundary is exactly that.
    PreRenderData* data = new (std::nothrow) PreRenderData();
    if (!data) return PF_Err_OUT_OF_MEMORY;

    extra->output->pre_render_data = data;
    extra->output->delete_pre_render_data_func = disposePreRenderData;

    ParamValues values;
    err = readParams(in_data, values);
    if (err) return err;

    data->field.physics    = toPhysics(values);
    data->field.atmosphere = toAtmosphere(values);
    data->field.ice        = toIce(values);
    data->field.convection = toConvection(values);
    data->field.timeSeconds = currentTimeSeconds(in_data);
    data->quality          = toQuality(values);

    // THE LAYER'S DRAFT SWITCH IS THE PREVIEW MODE. See draftQuality in CloudParams.h.
    // Applied here, before the sampling hash is taken below, so a Draft frame and a Best
    // frame are different accumulations and neither is mistaken for the other.
    if (in_data->quality == PF_Quality_LO) {
        data->quality = cloud::draftQuality(data->quality);
        diagLog("  layer quality Draft: %d spp, %d bounces",
                static_cast<int>(data->quality.samplesPerPixel),
                static_cast<int>(data->quality.maxBounces));
    }

    data->view.exposureEV = static_cast<float>(values.v[kMistytuneExposureEV]);
    data->view.renderDistance = static_cast<float>(values.v[kMistytuneRenderDistance]);
    data->view.agxTonemap = values.v[kMistytuneAgxTonemap] > 0.5;

    // ---------------------------------------------------------------------
    // ASKED OF THE PROJECT, NOT ASSUMED OF IT -- AND IT USED TO BE A HARDCODED `true`.
    //
    // MEASURED in AE 2026 with Working Color Space None and linearisation off -- which
    // is AE's default: the host applies NO transform to the buffer on the way to the
    // screen, at any bit depth. So a generator has to encode its own output, and
    // proto/index.html, which passed the Phase 0 look verdict, does exactly that.
    //
    // THAT MEASUREMENT WAS OF ONE PROJECT, and the constant it justified is wrong for a
    // colour-managed one, where AE applies the display transform itself and our encode
    // would be the second of two. readHostColorSettings() asks; encodesSrgbForHost() in
    // src/engine/ decides, so every branch of the decision is unit-tested without a
    // host. A read that fails returns the default-constructed settings, which decide
    // `true` -- so this line cannot render worse than the constant it replaces.
    // ---------------------------------------------------------------------
    const cloud::HostColorSettings colourSettings = readHostColorSettings(in_data);
    data->view.encodeSrgb = cloud::encodesSrgbForHost(colourSettings);

    // WHICH RULE FIRED, NAMED. The bool alone cannot distinguish "the project is
    // unmanaged" from "the host refused to say", and those want different next steps --
    // the first is correct and the second is a bug to chase. The raw host answers are
    // logged by readHostColorSettings immediately above this line.
    diagLog("  colour: encodeSrgb=%d (%s)",
            static_cast<int>(data->view.encodeSrgb),
            !colourSettings.queried  ? "host not asked -- default"
            : colourSettings.ocioManaged ? "OCIO manages the display transform"
            : colourSettings.haveWorkingGamma
                ? (cloud::isLinearWorkingGamma(colourSettings.workingGamma)
                       ? "linear working space"
                       : "encoded working space")
                : "no working space profile");

    // THE CAMERA'S FRAME IS THE LAYER, NOT THE REQUESTED RECT -- IN DOWNSAMPLED PIXELS.
    //
    // The layer is the whole picture the lens sees. THE REQUESTED RECT IS NOT THAT: AE
    // asks for whatever area it needs and the buffer it hands back is a third size
    // again -- measured on a plain 1920x1080 comp, the request was [-192,-108
    // 2304x1296] while the output world was 1920x1080. Storing the REQUEST size here
    // was a framing bug: every ray got divided by a denominator 20% too large, so the
    // field of view silently widened and the image slid off centre.
    //
    // STORING in_data->width/height RAW WAS THE SECOND HALF OF THE SAME MISTAKE, and
    // the comment that used to sit here asserted the opposite -- that they were
    // already downsampled. They are not. A 1/3 render logged frame=1920x1080 against
    // AE's own result_rect of 640x360, and since primaryRayDirection divides the
    // destination pixel by this frame, px ran 0..639 over a denominator of 1920: every
    // reduced-resolution render drew the top-left third of the sky, which on a sky
    // whose top third is empty is a flat blue frame and reads as a dead renderer.
    //
    // THE FIELD OF VIEW IS STILL NOT SCALED BY THE DOWNSAMPLE, and that part was
    // always right: a smaller buffer of the same view is exactly what a proxy render
    // is, and scaling the FOV would zoom the image instead. Scaling the frame WITH the
    // buffer is what holds the FOV fixed -- the ray maths divides one by the other, so
    // only their ratio is a camera property, and the ratio does not move.
    //
    // The buffer's own offset within the frame arrives in the same downsampled units
    // and is read at render time, where AE fills it in -- see smartRender.
    data->view.widthPx  = downsampledExtent(in_data->width,  in_data->downsample_x);
    data->view.heightPx = downsampledExtent(in_data->height, in_data->downsample_y);

    const PF_LRect& req = extra->input->output_request.rect;

    // THE ORBIT RIG UNLESS THE USER ASKED FOR THE COMP'S CAMERA. The rig reads the
    // field, which is filled above, because it aims at the cloud's height -- see
    // src/engine/OrbitCamera.h. It never calls AEGP_GetEffectCameraMatrix, so a comp
    // camera left in the comp does nothing while the rig is chosen.
    const bool compCamera = usesCompCamera(values);
    if (compCamera) {
        fillCameraFromComp(in_data, data->view,
                           static_cast<float>(values.v[kMistytuneCameraTravel]),
                           static_cast<float>(values.v[kMistytuneCameraAltitude]));
    } else {
        cloud::orbitView(data->field, toOrbit(values), data->view);
        diagLog("  orbit: eye (%.1f, %.1f, %.1f) m",
                static_cast<double>(data->view.observerX),
                static_cast<double>(data->view.observerAltitude),
                static_cast<double>(data->view.observerZ));
    }

    // THE SUN, PLACED RELATIVE TO THE CAMERA JUST RESOLVED -- and before the fingerprint
    // below, because under a preset a camera move IS a lighting change and the field key
    // has to say so. Manual returns the slider untouched. See src/engine/SunPlacement.h.
    const cloud::SunPlacement placement = toSunPlacement(values);
    data->field.atmosphere.sunAzimuth =
        cloud::placedSunAzimuth(placement, data->field.atmosphere.sunAzimuth, data->view);
    // THE SHAPE'S FACING, placed like the sun and for the same reason: under Turn to Camera
    // a camera move turns the shape, so the field key has to see it. See Pareidolia.h.
    // The hero where it stands NOW: drifting, it has moved from its sliders.
    cloud::Real heroX = 0, heroZ = 0;
    cloud::heroPositionNow(data->field, heroX, heroZ);
    cloud::placeShape(data->field.convection.pareidolia, data->view,
                      heroX, heroZ);

    diagLog("  sun: %s, azimuth %.1f deg, elevation %.1f deg",
            placement == cloud::SunPlacement::Backlit  ? "backlit"
            : placement == cloud::SunPlacement::SideLit ? "side lit"
            : placement == cloud::SunPlacement::FrontLit ? "front lit"
                                                        : "manual",
            static_cast<double>(data->field.atmosphere.sunAzimuth),
            static_cast<double>(data->field.atmosphere.sunElevation));

    // WHICH CAMERA, NAMED RATHER THAN INFERRED FROM THE PICTURE. "No camera,
    // defaulting" and "the comp's camera, and it points there" produce different
    // skies, and telling them apart by looking is exactly the diagnosis this
    // project has repeatedly got wrong.
    diagLog("  camera: %s, vertical fov %.1f deg",
            !compCamera                  ? "orbit the hero"
            : data->view.cameraFromComp ? "from the comp"
                                        : "no comp camera -- default",
            static_cast<double>(data->view.verticalFovDegrees));

    // THE RENDER PATH HAD NO INSTRUMENTATION AT ALL, and that is what made "nothing
    // renders" un-diagnosable: the log proved the effect LOADED and said nothing
    // about whether AE ever asked it for a pixel. These lines are the difference
    // between a guess and a measurement -- see DiagLog.h on why that is the rule.
    diagLog("PRE_RENDER: frame=%dx%d request=[%d,%d %dx%d] downsample=%d/%d,%d/%d samples=%d",
            data->view.widthPx, data->view.heightPx,
            static_cast<int>(req.left), static_cast<int>(req.top),
            static_cast<int>(req.right - req.left), static_cast<int>(req.bottom - req.top),
            static_cast<int>(in_data->downsample_x.num),
            static_cast<int>(in_data->downsample_x.den),
            static_cast<int>(in_data->downsample_y.num),
            static_cast<int>(in_data->downsample_y.den),
            static_cast<int>(data->quality.samplesPerPixel));

    sim::Fingerprint fp;
    fp.add(data->field);
    data->key.field    = fp.value();
    data->key.sampling = sim::samplingHash(data->view, data->quality);
    data->key.resolve  = sim::resolveHash(data->view, data->quality);

    // THE INPUT LAYER IS CHECKED OUT EVEN THOUGH PHASE 1 IGNORES ITS PIXELS.
    //
    // It is what tells AE the output's extent. A generator that checked out nothing
    // would report an empty result rect, and AE would render nothing at all -- which
    // looks like a broken kernel.
    PF_CheckoutResult inResult;
    AEFX_CLR_STRUCT(inResult);
    PF_RenderRequest request = extra->input->output_request;

    err = extra->cb->checkout_layer(in_data->effect_ref, kMistytuneInput, kMistytuneInput,
                                    &request, in_data->current_time,
                                    in_data->time_step, in_data->time_scale, &inResult);
    if (err) return err;

    UnionLRect(&inResult.result_rect,     &extra->output->result_rect);
    UnionLRect(&inResult.max_result_rect, &extra->output->max_result_rect);

    // AN EMPTY RESULT RECT MEANS AE SKIPS SMART_RENDER ENTIRELY and reports nothing.
    // It is the one failure that looks exactly like a broken kernel, so it is named
    // here rather than left to be inferred from the absence of a later line.
    const PF_LRect& rr = extra->output->result_rect;
    diagLog("  result_rect=[%d,%d %dx%d]%s",
            static_cast<int>(rr.left), static_cast<int>(rr.top),
            static_cast<int>(rr.right - rr.left), static_cast<int>(rr.bottom - rr.top),
            (rr.right <= rr.left || rr.bottom <= rr.top)
                ? "  <-- EMPTY: AE will not call SMART_RENDER" : "");

    // CARRIED TO SMART RENDER, WHERE THE HOST WILL NOT SAY IT AGAIN. See the note on
    // PreRenderData for why in_data->output_origin_x/y cannot be used for this.
    data->renderOriginX     = rr.left;
    data->renderOriginY     = rr.top;
    data->renderWidth       = rr.right - rr.left;
    data->renderHeight      = rr.bottom - rr.top;
    data->renderOriginValid = (rr.right > rr.left && rr.bottom > rr.top);

    // -----------------------------------------------------------------------
    // PAREIDOLIA'S SOURCE, WHOLE (build 21).
    //
    // A layer parameter's pixels arrive in that layer's own space, masks and effects on,
    // transforms off -- the picture as its author made it. WHOLE, because the silhouette is
    // cropped to its own box and a partial checkout would crop a different shape.
    //
    // NOT UNIONED INTO THE RESULT RECT: it shapes the cloud, not where our pixels lie.
    // -----------------------------------------------------------------------
    {
        PF_CheckoutResult probe;
        AEFX_CLR_STRUCT(probe);
        PF_RenderRequest probeRequest = extra->input->output_request;
        PF_Err shapeErr = extra->cb->checkout_layer(in_data->effect_ref, kMistytunePareidoliaSource,
                                                    kShapeProbeCheckout, &probeRequest,
                                                    in_data->current_time, in_data->time_step,
                                                    in_data->time_scale, &probe);
        const PF_LRect& whole = probe.max_result_rect;
        if (!shapeErr && whole.right > whole.left && whole.bottom > whole.top) {
            PF_RenderRequest wholeRequest = extra->input->output_request;
            wholeRequest.rect = whole;
            if (wholeRequest.rect.right - wholeRequest.rect.left > kShapeMaxSide)
                wholeRequest.rect.right = wholeRequest.rect.left + kShapeMaxSide;
            if (wholeRequest.rect.bottom - wholeRequest.rect.top > kShapeMaxSide)
                wholeRequest.rect.bottom = wholeRequest.rect.top + kShapeMaxSide;
            wholeRequest.channel_mask = PF_ChannelMask_ARGB;
            wholeRequest.preserve_rgb_of_zero_alpha = FALSE;

            PF_CheckoutResult got;
            AEFX_CLR_STRUCT(got);
            shapeErr = extra->cb->checkout_layer(in_data->effect_ref, kMistytunePareidoliaSource,
                                                 kShapeCheckout, &wholeRequest,
                                                 in_data->current_time, in_data->time_step,
                                                 in_data->time_scale, &got);
            data->shapeCheckedOut = !shapeErr && got.result_rect.right > got.result_rect.left &&
                                    got.result_rect.bottom > got.result_rect.top;
            diagLog("  pareidolia: source [%d,%d %dx%d]%s",
                    static_cast<int>(got.result_rect.left), static_cast<int>(got.result_rect.top),
                    static_cast<int>(got.result_rect.right - got.result_rect.left),
                    static_cast<int>(got.result_rect.bottom - got.result_rect.top),
                    data->shapeCheckedOut ? "" : " -- EMPTY, no shape");
        }
        // A FAILED CHECKOUT OF THE SOURCE IS NO SHAPE, NOT A FAILED FRAME: the sky renders
        // without it and the log says so.
        if (shapeErr) diagLog("  pareidolia: source checkout failed (err %d) -- no shape",
                              static_cast<int>(shapeErr));
    }

    // THE GPU OFFER, and a picture withdraws it. PF_Cmd_SMART_RENDER_GPU would hand the
    // source over as a GPU world, which the map builder cannot read; the host path reads it
    // and still renders on the card through renderCudaToHost. AE has never taken the offer
    // on this effect anyway (see smartRenderHost), so nothing is lost that was being used.
    if (!kernel::cudaAvailable()) {
        diagLog("  no GPU path in this build -- not offering GPU_RENDER_POSSIBLE.");
    } else if (data->shapeCheckedOut) {
        diagLog("  pareidolia source present -- not offering GPU_RENDER_POSSIBLE.");
    } else {
        extra->output->flags |= PF_RenderOutputFlag_GPU_RENDER_POSSIBLE;
    }

    return err;
}

// ---------------------------------------------------------------------------
// Where the buffer sits in the frame
// ---------------------------------------------------------------------------

// Both render paths need this and both used to get it wrong the same way, so it is
// one function rather than two copies of a subtle line.
//
// THE SIZE IS CHECKED, NOT ASSUMED. The offset is only right if the buffer AE handed
// back is the rect pre-render promised to fill. That has matched on every frame
// measured so far -- but if it ever stops matching, the renderer draws the wrong part
// of the picture into a buffer of the right size, which is the failure mode this
// project has now shipped three times and recognised late every time. A line in the
// log is the difference between finding it in a minute and finding it in a day.
void applyRenderOrigin(const PreRenderData& data, const PF_EffectWorld* output,
                       const PF_InData* in_data, cloud::ViewParams& view) {
    if (!data.renderOriginValid) {
        // No usable rect from pre-render. output_origin_x/y is the documented field
        // even though it has measured zero whenever it mattered, so it is a better
        // guess than assuming the top-left corner -- and the log says which one ran.
        view.originX = in_data->output_origin_x;
        view.originY = in_data->output_origin_y;
        diagLog("  origin: pre-render left no result rect -- falling back to "
                "output_origin=%d,%d",
                static_cast<int>(in_data->output_origin_x),
                static_cast<int>(in_data->output_origin_y));
        return;
    }

    view.originX = static_cast<int32_t>(data.renderOriginX);
    view.originY = static_cast<int32_t>(data.renderOriginY);

    if (output->width != data.renderWidth || output->height != data.renderHeight) {
        diagLog("  ORIGIN SUSPECT: buffer is %dx%d but pre-render promised %dx%d "
                "at %d,%d -- the offset below may be for a different rect.",
                static_cast<int>(output->width), static_cast<int>(output->height),
                static_cast<int>(data.renderWidth), static_cast<int>(data.renderHeight),
                static_cast<int>(data.renderOriginX), static_cast<int>(data.renderOriginY));
    }
}

// ---------------------------------------------------------------------------
// Smart render: the GPU path
// ---------------------------------------------------------------------------

PF_Err smartRenderGpu(PF_InData* in_data, PF_OutData* out_data,
                      PF_PixelFormat format, PF_EffectWorld* output,
                      PF_SmartRenderExtra* extra, const PreRenderData& data) {
    PF_Err err = PF_Err_NONE;

    // THE ONLY GPU FORMAT AE OFFERS IS BGRA128. Anything else is a host we do not
    // understand, and guessing a stride into someone else's memory is worse than
    // refusing.
    if (format != PF_PixelFormat_GPU_BGRA128) {
        diagLog("SMART_RENDER_GPU: unexpected pixel format %d -- refusing.",
                static_cast<int>(format));
        return PF_Err_UNRECOGNIZED_PARAM_TYPE;
    }

    if (extra->input->what_gpu != PF_GPU_Framework_CUDA || !kernel::cudaAvailable()) {
        // AE asked for a GPU render on a framework this build does not implement.
        // Returning an error is right: it makes AE fall back rather than leaving the
        // output buffer full of whatever was in it, which shows as a flicker.
        diagLog("SMART_RENDER_GPU: no CUDA path available -- asking AE for the CPU path.");
        return PF_Err_UNRECOGNIZED_PARAM_TYPE;
    }

    AEFX_SuiteScoper<PF_GPUDeviceSuite1> gpuSuite(in_data, kPFGPUDeviceSuite,
                                                  kPFGPUDeviceSuiteVersion1, out_data);

    void* destMem = nullptr;
    err = gpuSuite->GetGPUWorldData(in_data->effect_ref, output, &destMem);
    if (err || !destMem) return err ? err : PF_Err_INTERNAL_STRUCT_DAMAGED;

    kernel::RenderRequest req;
    req.field   = data.field;
    req.view    = data.view;
    req.quality = data.quality;
    req.dest    = toSurface(output, format);
    req.dest.data = destMem;

    // The offset of this buffer's pixel (0,0) within the frame. Without it the
    // renderer draws the wrong part of the picture into the right buffer -- see the
    // frame/window note in CloudParams.h, and PreRenderData on where it comes from.
    applyRenderOrigin(data, output, in_data, req.view);

    // MANY LAUNCHES, NOT ONE, AND THIS USED TO BE THE HAZARD PHASE 1 LEFT IN.
    //
    // The Windows display driver's timeout is about two seconds and it kills the whole
    // CUDA context rather than the launch -- taking After Effects with it. A frame at
    // a high sample count in one launch sits past that, so the samples are split and
    // the accumulator carries the partial sums between them.
    //
    // NO ROW BANDING HERE, unlike smartRenderHost. AE owns this buffer and hands it
    // over whole, so the only axis left to split is the samples -- which is why the
    // floor band passed to samplesPerLaunch() is the WHOLE FRAME rather than sixteen
    // rows, and why the chunks here are correspondingly smaller.
    const int totalSamples = data.quality.samplesPerPixel > 0 ? data.quality.samplesPerPixel : 1;
    const int samplesPerChunk = kernel::samplesPerLaunch(
        kernel::kGpuPixelSampleBudget,
        static_cast<long long>(output->width) * output->height,
        totalSamples);

    req.accumulator        = nullptr;
    req.accumulatorPitchPx = 0;

    if (samplesPerChunk < totalSamples) {
        // THIS PATH WRITES THE SAME DEVICE ACCUMULATOR THE CPU COMMAND CACHES, and it
        // does not credit the cache -- its destination is a device buffer AE owns, and
        // resolving from it would need a second destination it cannot see. So the GPU
        // cache stops vouching the moment this runs, or the next CPU-command render on
        // this thread would resolve from a buffer this call just filled with another
        // frame. Fails safe: the next render traces.
        t_gpuAccumCache.invalidate();
        req.accumulator = kernel::reserveDeviceAccumulator(req.dest.pitchPx, output->height);
        if (!req.accumulator) {
            const char* why = kernel::lastCudaError();
            diagLog("SMART_RENDER_GPU: no accumulator (%s) -- asking AE for the CPU path.",
                    why && why[0] ? why : "no detail");
            return PF_Err_UNRECOGNIZED_PARAM_TYPE;
        }
        req.accumulatorPitchPx = req.dest.pitchPx;
    }

    // STILL NEVER EXERCISED BY A HOST. AE reports what_gpu=NONE and does not call this
    // command, so everything above is reasoned rather than measured -- including
    // whether PF_ABORT and PF_PROGRESS are legal from inside it. Written now because
    // the alternative is that the day AE does start calling it, it calls the version
    // with the driver-reset hazard in it.
    for (int s0 = 0; s0 < totalSamples; s0 += samplesPerChunk) {
        req.firstSample        = s0;
        req.sampleCount        = std::min(samplesPerChunk, totalSamples - s0);
        req.samplesAlreadyDone = s0;

        if (!kernel::renderCuda(req)) {
            const char* why = kernel::lastCudaError();
            diagLog("SMART_RENDER_GPU: launch failed at sample %d of %d: %s",
                    s0, totalSamples, why[0] ? why : "(no detail)");
            return PF_Err_INTERNAL_STRUCT_DAMAGED;
        }

        if (PF_Err abortErr = PF_ABORT(in_data)) return abortErr;
        if (PF_Err progErr = PF_PROGRESS(in_data, s0 + req.sampleCount, totalSamples)) {
            return progErr;
        }
    }

    // ---------------------------------------------------------------------
    // THE FRAME IS COMPLETE, SO THE OUTPUT TRANSFORM RUNS -- ONCE, AFTER THE LOOP.
    //
    // The buffer holds LINEAR radiance until this call. Exposure, AgX and the sRGB
    // transfer curve left renderPixel because the denoiser needs a linear buffer;
    // see KernelApi.h.
    //
    // transformCuda AND NOT transformCpu, because this is the one path whose
    // destination is device memory -- AE handed it to us through
    // PF_GPUDeviceSuite1::GetGPUWorldData and the CPU cannot touch it.
    //
    // AFTER THE SAMPLE LOOP AND NOT INSIDE IT. Each chunk rewrites the destination
    // with the running mean, so transforming per chunk would transform an
    // already-transformed buffer every time after the first.
    // ---------------------------------------------------------------------
    if (!kernel::transformCuda(req)) {
        const char* why = kernel::lastCudaError();
        diagLog("SMART_RENDER_GPU: output transform failed: %s",
                why && why[0] ? why : "(no detail)");
        return PF_Err_INTERNAL_STRUCT_DAMAGED;
    }

    return err;
}

// ---------------------------------------------------------------------------
// Smart render: the CPU path
// ---------------------------------------------------------------------------

// RENDERS INTO HOST MEMORY. IT MAY STILL USE THE GPU TO DO IT.
//
// The name is "host" and not "CPU" on purpose, and the distinction is the whole
// point of this function now. After Effects calls PF_Cmd_SMART_RENDER -- the
// non-GPU command -- and hands out an ordinary CPU world; what fills that world is
// a separate question, and on a machine with CUDA the answer is the GPU.
//
// WHY THAT IS NECESSARY RATHER THAN CLEVER. Measured on AE 2026 with a 32 bpc float
// project, Mercury GPU Acceleration set to CUDA, and a card AE itself hands this
// effect at GPU_DEVICE_SETUP: pre-render reports what_gpu=NONE, so
// PF_Cmd_SMART_RENDER_GPU is NEVER CALLED. Dropping I_USE_3D_CAMERA did not change
// it; adding PIX_INDEPENDENT did not change it. AE settles what_gpu before asking
// the effect anything, so no flag the effect sets can reach that decision.
//
// Owning the device memory and copying back is what most GPU-using AE plugins do
// anyway, and it costs one device-to-host copy per frame -- nothing against a path
// trace, and it buys a measured 100x at 1920x1080 and 64 samples.
//
// AE ALSO TAKES THIS PATH at 8 and 16 bpc regardless of any of the above, and on any
// machine whose GPU is unavailable. So it is not an optional path -- it is the one
// every user hits, and PLAN.md's Phase 1 exit criterion names all three bit depths
// explicitly.
//
// THE RENDERER'S OUTPUT IS HDR, so the integer formats are reached through a float
// staging buffer rather than by rendering into them. Quantising to 8 bits is the LAST
// thing that should happen to a radiance value, not the first: rendering directly
// into an integer buffer would clamp the sun to white before the tonemap ever saw it.
PF_Err smartRenderHost(PF_InData* in_data, PF_OutData* out_data,
                       PF_PixelFormat format, PF_EffectWorld* output,
                       const PreRenderData& data, const cloud::ShapeMap* shape) {
    (void)out_data;

    diagLog("SMART_RENDER_HOST: format=%d output=%dx%d rowbytes=%d samples=%d",
            static_cast<int>(format), static_cast<int>(output->width),
            static_cast<int>(output->height), static_cast<int>(output->rowbytes),
            static_cast<int>(data.quality.samplesPerPixel));

    const size_t bpp = bytesPerPixel(format);
    if (bpp == 0) {
        // A depth we do not recognise. Leaving the output untouched shows as a
        // flicker; writing at a guessed stride corrupts someone else's memory. The
        // flicker is the better failure.
        diagLog("SMART_RENDER: unrecognised pixel format %d -- leaving output untouched.",
                static_cast<int>(format));
        return PF_Err_NONE;
    }

    kernel::RenderRequest req;
    req.field   = data.field;
    req.view    = data.view;
    req.quality = data.quality;

    // PAREIDOLIA'S MAP, built by smartRender from the source it checked out. It outlives
    // this function, so the request may point at it.
    req.shapeMap = shape;

    // THE PICTURE IS IN THE KEY. It is not a parameter, so pre-render's fingerprint cannot
    // see it -- and without this, editing the source layer would leave every parameter
    // unchanged and the accumulator cache would resolve the old shape from memory.
    sim::RenderKey key = data.key;
    if (shape) {
        sim::Fingerprint fp;
        fp.add(key.field);
        fp.add(shape->hash);
        key.field = fp.value();
    }

    // See the note on the GPU path, and PreRenderData on why this is not
    // in_data->output_origin_x/y.
    applyRenderOrigin(data, output, in_data, req.view);

    // output_origin IS LOGGED BESIDE THE ONE ACTUALLY USED, on purpose. It read 0,0
    // on the Region of Interest frame that exposed the bug, and printing both is what
    // makes a future disagreement between them visible instead of theoretical.
    diagLog("  frame=%dx%d origin=%d,%d (output_origin=%d,%d)",
            req.view.widthPx, req.view.heightPx,
            req.view.originX, req.view.originY,
            static_cast<int>(in_data->output_origin_x),
            static_cast<int>(in_data->output_origin_y));

    req.firstSample        = 0;
    req.sampleCount        = data.quality.samplesPerPixel;
    req.samplesAlreadyDone = 0;
    req.accumulator        = nullptr;

    // 32 bpc renders straight into AE's buffer, because it is already the format the
    // renderer works in. 8 and 16 bpc go through a float staging buffer and convert
    // below. EITHER WAY THE DRIVER BELOW IS THE SAME, which is the point of deciding
    // the destination here rather than writing the loop twice.
    std::vector<float> staging;
    const bool direct = (format == PF_PixelFormat_ARGB128);

    if (direct) {
        req.dest = toSurface(output, format);
    } else {
        const size_t pixels =
            static_cast<size_t>(output->width) * static_cast<size_t>(output->height);
        staging.assign(pixels * 4, 0.0f);

        req.dest.data     = staging.data();
        req.dest.widthPx  = output->width;
        req.dest.heightPx = output->height;
        req.dest.pitchPx  = output->width;      // tightly packed, unlike AE's worlds
        req.dest.order    = kernel::ChannelOrder::ARGB;
    }

    // =======================================================================
    // RENDERED IN BANDS OF ROWS, AND THE REASON IS THE ONE FAILURE THAT LOOKS
    // EXACTLY LIKE A BROKEN PLUGIN.
    //
    // One 1920x1080 frame at the default 64 samples is MINUTES on this path
    // (measured: 3m43s). A single blocking call of that length gives After Effects
    // no progress to draw and no opportunity to cancel, so the host sits frozen and
    // never paints a frame -- which presents as "the effect renders nothing", not as
    // "the effect is slow". The user's only recourse is to kill AE.
    //
    // THE SPLIT IS BY ROW AND NOT BY SAMPLE, deliberately. Every pixel still gets its
    // whole sample budget inside ONE renderCpu call, so the per-sample sum is grouped
    // exactly as it was before and the image is bit-for-bit what the golden tests
    // assert. Chunking by SAMPLE instead would regroup that sum, and floating-point
    // addition is not associative -- it would trade a determinism guarantee for
    // nothing, since rows give all the granularity needed.
    //
    // THE BAND SIZE IS A PIXEL-SAMPLE BUDGET, not a time target. A band sized by
    // measuring the clock would vary run to run, and anything that varies run to run
    // has no business anywhere near a renderer that promises byte-identical output.
    // 256k pixel-samples is a few tenths of a second on the machine this was measured
    // on, which is responsive enough to cancel and fine-grained enough for a progress
    // bar that visibly moves.
    // =======================================================================
    // WHICH ENGINE FILLS THE BUFFER. Asked once, here, rather than per band.
    //
    // NOT CONST: a GPU failure partway down a frame clears it, and every band after
    // that goes to the CPU. See the fallback in the loop below.
    bool useGpu = kernel::cudaAvailable();

    // THE BAND BUDGET IS PER ENGINE, because the two are three orders of magnitude
    // apart and one number cannot serve both.
    //
    //   CPU  256K pixel-samples is a few tenths of a second (measured ~1.7 us each).
    //   GPU  see kGpuPixelSampleBudget in KernelApi.h, which carries the measurement
    //        and the reason it is what it is. Staying near a quarter second is what
    //        keeps every launch clear of the Windows display-driver timeout, which
    //        kills the whole context rather than just the launch.
    //
    // THE GPU FIGURE WAS A LITERAL HERE AND IN ONE OTHER PLACE, AND IT WENT STALE.
    // It was calibrated against the Phase 1 analytic sky at 5 ns a pixel-sample; the
    // real transport costs 93, so the same constant went from 0.16 s a band to 3.0 s
    // -- past the timeout, with nothing to say so. It is one named constant now,
    // beside the measurement that sets it.
    const long long kBandBudget = useGpu ? kernel::kGpuPixelSampleBudget : (256 * 1024);
    const long long perRow =
        static_cast<long long>(output->width) * data.quality.samplesPerPixel;

    int rowsPerBand = perRow > 0 ? static_cast<int>(kBandBudget / perRow) : output->height;

    // A FLOOR, BECAUSE THE BAND IS ALSO THE UNIT OF PARALLELISM.
    //
    // renderCpu divides ITS ROW RANGE across workers and clamps the worker count to
    // the number of rows, so a two-row band runs on two threads no matter how many
    // the machine has. At the default 64 samples the budget alone gives exactly that
    // -- measured 0.373 s/row inside AE against 0.207 s/row headless, a 1.8x loss
    // for a finer abort check nobody asked for.
    //
    // THE FLOOR TRACKS THE POOL rather than being a constant, because the pool is
    // now the machine's full width and a fixed 8 would starve a 16-thread box the
    // same way a fixed 2 starved a 4-thread one. Two rows per worker: enough that
    // every worker gets a band, without making the abort check rarer than it needs
    // to be.
    unsigned int hw = std::thread::hardware_concurrency();
    if (hw == 0) hw = 1;
    //
    // ON THE GPU THE FLOOR IS THE BLOCK HEIGHT INSTEAD. kBlockY is 16, so a band
    // shorter than that wastes most of the threads in every block it launches --
    // the same starvation as the CPU case, one level down.
    const int kMinRowsPerBand = useGpu ? 16 : static_cast<int>(hw) * 2;
    if (rowsPerBand < kMinRowsPerBand) rowsPerBand = kMinRowsPerBand;
    if (rowsPerBand > output->height)  rowsPerBand = output->height;

    // =======================================================================
    // AND THE SAMPLES ARE SPLIT TOO, ONCE THE ROWS CANNOT GO ANY FINER.
    //
    // The row floor above is where the band stops shrinking, so past it the launch
    // grows with the sample count and nothing bounds it. samplesPerLaunch() works out
    // where that crossover is -- see KernelApi.h, which also says why this number may
    // not depend on rowsPerBand, on the thread count, or on anything measured.
    //
    // BELOW THE CROSSOVER THIS IS ONE CHUNK AND CHANGES NOTHING, bit for bit. The
    // frame only regroups its per-pixel sum when it was going to blow the driver
    // timeout otherwise, which is a trade worth making exactly then and not before.
    // =======================================================================
    const int totalSamples = data.quality.samplesPerPixel > 0 ? data.quality.samplesPerPixel : 1;
    const int samplesPerChunk = kernel::samplesPerLaunch(
        kBandBudget,
        static_cast<long long>(output->width) * kMinRowsPerBand,
        totalSamples);

    const int chunksPerBand = (totalSamples + samplesPerChunk - 1) / samplesPerChunk;
    const A_long bandCount  = (output->height + rowsPerBand - 1) / rowsPerBand;
    const A_long totalUnits = bandCount * chunksPerBand;
    A_long unitsDone = 0;

    // =======================================================================
    // CAN THIS FRAME BE RESOLVED RATHER THAN TRACED?
    //
    // When nothing but a RESOLVE input changed -- exposure, AgX, the encoding, the
    // denoise switch or its amount -- every sample in this thread's accumulator is
    // still exactly right, and the frame can be rebuilt from it with zero new rays:
    // one pass per band that divides the stored sum and nothing else. At final
    // quality that is the difference between a slider nudge costing seconds and it
    // costing the denoise.
    //
    // ONLY WHEN THE RENDER IS SPLIT, because only then was the accumulator WRITTEN.
    // An unsplit render takes renderPixel's no-accumulator branch and leaves the
    // buffer holding whatever the last split render put there -- another frame. A
    // Draft render at one chunk therefore never resolves; it is cheap to trace anyway,
    // and that is where the saving would have been smallest.
    //
    // INVALIDATE BEFORE WRITING, CREDIT AFTER COMPLETING. A full render is about to
    // overwrite an accumulator, so both engines' caches stop vouching for anything
    // NOW -- the render may fall back to the other engine partway, or be aborted, and
    // neither leaves a whole frame anywhere. Only a frame finished start to end on one
    // engine is credited, below the loop. Every path through here that is not that
    // path leaves the cache empty, and an empty cache is a re-render, never a wrong
    // picture.
    // =======================================================================
    const bool split      = samplesPerChunk < totalSamples;
    const int  cacheW     = static_cast<int>(req.dest.widthPx);
    const int  cacheH     = static_cast<int>(req.dest.heightPx);
    const int  cachePitch = req.dest.pitchPx > 0 ? static_cast<int>(req.dest.pitchPx)
                                                 : static_cast<int>(req.dest.widthPx);

    sim::AccumulatorCache& startCache = useGpu ? t_gpuAccumCache : t_cpuAccumCache;
    bool resolveOnly = split && startCache.canResolve(key, totalSamples,
                                                      cacheW, cacheH, cachePitch);
    bool fellBack = false;

    if (!resolveOnly && split) {
        t_cpuAccumCache.invalidate();
        t_gpuAccumCache.invalidate();
    }

    const double t0 = diagSeconds();

    for (A_long y = 0; y < output->height; y += rowsPerBand) {
        const A_long y1 = std::min<A_long>(y + rowsPerBand, output->height);

        // THE BAND IS RESTARTED, NOT RESUMED, IF THE GPU DROPS OUT PARTWAY THROUGH IT.
        //
        // The partial sums live in device memory that the CPU path cannot see, so
        // continuing from chunk N on the other engine would add this band's remaining
        // samples to an accumulator that has nothing in it -- a band correct only in
        // the samples taken after the failure, which is noise against its neighbours.
        // Re-rendering the band costs one band; getting it wrong costs a visible seam.
        const A_long unitsAtBandStart = unitsDone;

        for (bool restart = true; restart; ) {
            restart   = false;
            unitsDone = unitsAtBandStart;   // the band's chunks are about to be redone

            for (int s0 = 0; s0 < totalSamples; s0 += samplesPerChunk) {
                const int n = std::min(samplesPerChunk, totalSamples - s0);

                if (resolveOnly) {
                    // ZERO NEW SAMPLES, AND THE STORED SUM DIVIDED BY THE COUNT IT HOLDS.
                    // The same request --resolve-check makes, which is proved
                    // byte-identical to a full render on both engines and, on the GPU,
                    // in bands -- see resolve.reproducesTheRenderOnGpuInBands.
                    req.firstSample        = totalSamples;
                    req.sampleCount        = 0;
                    req.samplesAlreadyDone = totalSamples;
                } else {
                    req.firstSample        = s0;
                    req.sampleCount        = n;
                    req.samplesAlreadyDone = s0;
                }

                if (useGpu) {
                    if (!kernel::renderCudaToHost(req, static_cast<int>(y),
                                                  static_cast<int>(y1))) {
                        // FALLS BACK FOR THE REST OF THE FRAME RATHER THAN FAILING IT.
                        // A driver reset or an out-of-memory partway down a frame
                        // should cost a slow frame, not a black one -- and the bands
                        // already written stay valid, because both engines write the
                        // identical pixels. The log names it so the slowness is not a
                        // mystery.
                        const char* why = kernel::lastCudaError();
                        diagLog("  GPU band at row %d failed (%s) -- CPU for the rest of this frame.",
                                static_cast<int>(y), why && why[0] ? why : "no detail");
                        useGpu  = false;
                        restart = true;

                        // A RESOLVE CANNOT FALL BACK. The frame's samples are in the
                        // GPU's accumulator and the CPU's holds something else, so
                        // resolving there would build this band out of another frame.
                        // This band -- and every one after it -- is traced in full on
                        // the CPU instead. The bands already resolved are correct and
                        // stay.
                        //
                        // AND NEITHER CACHE VOUCHES FOR ANYTHING NOW: the frame is
                        // split across two engines, so no accumulator holds all of it.
                        resolveOnly = false;
                        fellBack    = true;
                        t_cpuAccumCache.invalidate();
                        t_gpuAccumCache.invalidate();
                        break;
                    }
                } else {
                    kernel::renderCpu(req, 0, static_cast<int>(y), static_cast<int>(y1));
                }

                // ABORT BEFORE PROGRESS. PF_ABORT is what lets the user cancel and
                // what lets AE discard a frame whose inputs already changed; a render
                // that ignores it keeps burning minutes on a picture nobody is waiting
                // for any more.
                //
                // PER CHUNK, NOT PER BAND, and that is the half of the fix that the
                // user actually feels. At a high sample count a band is many launches,
                // and checking only between bands would leave the host unresponsive
                // for exactly as long as the split was introduced to avoid.
                //
                // The error is RETURNED, not swallowed: PF_Interrupt_CANCEL is how the
                // host is told the buffer is incomplete, and converting a partly-filled
                // staging buffer below would hand AE a half-rendered frame to cache.
                if (PF_Err abortErr = PF_ABORT(in_data)) {
                    diagLog("  aborted at row %d of %d, sample %d of %d, after %.2f s",
                            static_cast<int>(y1), static_cast<int>(output->height),
                            s0 + n, totalSamples, diagSeconds() - t0);
                    return abortErr;
                }

                if (resolveOnly) {
                    // ONE PASS STANDS IN FOR THE BAND'S EVERY CHUNK, so the progress bar
                    // moves by the band rather than crawling one unit per band and then
                    // jumping at the end.
                    unitsDone = unitsAtBandStart + chunksPerBand;
                    if (PF_Err progErr = PF_PROGRESS(in_data, unitsDone, totalUnits)) return progErr;
                    break;
                }

                ++unitsDone;
                if (PF_Err progErr = PF_PROGRESS(in_data, unitsDone, totalUnits)) return progErr;
            }
        }
    }

    // CREDITED ONLY FOR A WHOLE FRAME ON ONE ENGINE -- see above the loop. An abort
    // returned before reaching here, which is what leaves an aborted frame uncredited.
    //
    // resolveOnly STILL TRUE MEANS NO FALLBACK HAPPENED, because the fallback clears it,
    // so the engine now is the engine the cache was read from.
    sim::AccumulatorCache& endCache = useGpu ? t_gpuAccumCache : t_cpuAccumCache;
    if (resolveOnly) {
        endCache.adoptResolve(key);
    } else if (split && !fellBack) {
        endCache.adoptFull(key, totalSamples, cacheW, cacheH, cachePitch);
    }

    // THE NUMBER THAT SETTLES "IT RENDERS NOTHING" VERSUS "IT IS STILL RENDERING" --
    // and now also the one that says whether the cache did anything. "resolved" is the
    // line to look for after dragging Exposure or Denoise Amount at final quality; a
    // "traced" there, on a frame that was just rendered, is a cache miss worth knowing.
    diagLog("  %s %dx%d on the %s in %.2f s (%d rows per band, %d samples%s)",
            resolveOnly ? "resolved" : "traced",
            static_cast<int>(output->width), static_cast<int>(output->height),
            useGpu ? "GPU" : "CPU", diagSeconds() - t0, rowsPerBand, totalSamples,
            resolveOnly ? " from the accumulator" : (split ? "" : ", unsplit -- not cacheable"));

    // =======================================================================
    // THE FRAME IS COMPLETE, SO THE OUTPUT TRANSFORM RUNS -- ONCE, HERE.
    //
    // Everything above leaves LINEAR radiance in `req.dest`. Exposure, AgX and the
    // sRGB transfer curve used to happen inside renderPixel and now do not, because
    // the denoiser wants the linear buffer and the correct order is
    //
    //     render (LINEAR) -> denoise -> output transform -> quantise
    //
    // OIDN IS IMMEDIATELY ABOVE THIS LINE, WHICH IS THE ENTIRE REASON THIS PASS EXISTS
    // AS A PASS -- and the measurement that decided it stays one pass is in
    // KernelApi.h: the filter normalises its own input, so exposure does not have to
    // precede it and the transform did not have to be split.
    //
    // transformCpu EVEN WHEN useGpu IS TRUE. renderCudaToHost copies each band back
    // into host memory, so by here the destination is `staging` or AE's own world
    // either way -- which engine traced the rays does not decide where the pixels
    // ended up. The one path that needs transformCuda is smartRenderGpu, whose
    // destination AE never brings back to the host.
    //
    // AFTER THE BAND LOOP AND AFTER THE CHUNK LOOP, WHICH IS WHY IT IS OUT HERE AND
    // NOT BESIDE EITHER. A band's last chunk leaves that band's linear mean in place;
    // transforming per band would be correct today and would be silently wrong the
    // moment a denoiser that needs the WHOLE frame runs between the two.
    //
    // FORGETTING THIS IS NOT SUBTLE, WHICH IS WHY THE RESTRUCTURE IS SAFE NOW AND WAS
    // NOT BEFORE. ViewParams::encodeSrgb defaults to true, so the transform is never
    // the identity: without this call the render is near-black with a sun in it. The
    // earlier attempt was abandoned precisely because exposure 0 and AgX off made the
    // transform a no-op, so a missing pass would have waited months to appear as
    // "the Exposure slider does nothing".
    // =======================================================================
    const double tDenoise = diagSeconds();
    const bool denoised = kernel::denoiseCpu(req);
    if (data.quality.denoise) {
        // REPORTED EITHER WAY. "Denoise is on and it did not happen" is the state a
        // user cannot see except as a noisier picture, and it is what a pruned install
        // folder or a quarantined DLL produces -- so the log has to name it.
        diagLog("  denoise %.3f s (%s)", diagSeconds() - tDenoise,
                denoised ? "applied" : cloud::denoiserDescription());
    }

    const double tTransform = diagSeconds();
    kernel::transformCpu(req);
    diagLog("  output transform %.3f s (encodeSrgb=%d, ev=%.2f, agx=%d)",
            diagSeconds() - tTransform,
            static_cast<int>(data.view.encodeSrgb),
            static_cast<double>(data.view.exposureEV),
            static_cast<int>(data.view.agxTonemap));

    if (direct) return PF_Err_NONE;

    // ONE CALL, AND THE MATHS IS IN src/engine/OutputConvert.h.
    //
    // THIS LOOP USED TO BE HERE, about sixty lines of it: the 0..32768 scale, the sRGB
    // curve, the deliberate omission of that curve on alpha, and the integer clamp. All
    // four are host conventions that fail quietly, and while they lived in this function
    // the only instrument that had ever been pointed at them was a person rendering in
    // After Effects and looking. PLAN.md's Phase 1 exit asks for all three bit depths to
    // be CORRECT, which is not something looking establishes.
    //
    // None of it needs an AE header, so none of it stays here. tests/unit/ now exercises
    // every format, the alpha rule and the stride in microseconds without the SDK.
    // AND IF IT IS NEITHER OF THE TWO INTEGER FORMATS, SAY SO. toImageView falls back to
    // the narrowest format, which keeps the write inside the buffer at the cost of a wrong
    // picture -- and a wrong picture with nothing in the log is the expensive kind.
    if (format != PF_PixelFormat_ARGB64 && format != PF_PixelFormat_ARGB32) {
        diagLog("  WARNING: format %d is not one this path knows; converting it as 8 bpc. "
                "The picture will be wrong. See toImageView in AEBridge.h.",
                static_cast<int>(format));
    }

    cloud::convertStagingFrame(staging.data(), toImageView(output, format));

    return PF_Err_NONE;
}

// ---------------------------------------------------------------------------
// Smart render: the dispatch
// ---------------------------------------------------------------------------

PF_Err smartRender(PF_InData* in_data, PF_OutData* out_data,
                   PF_SmartRenderExtra* extra, bool isGpu) {
    PF_Err err = PF_Err_NONE, err2 = PF_Err_NONE;

    diagLog("SMART_RENDER: AE chose the %s path.", isGpu ? "GPU" : "CPU");

    const PreRenderData* data =
        reinterpret_cast<const PreRenderData*>(extra->input->pre_render_data);
    if (!data) {
        diagLog("  pre_render_data is NULL -- refusing.");
        return PF_Err_INTERNAL_STRUCT_DAMAGED;
    }

    PF_EffectWorld* input  = nullptr;
    PF_EffectWorld* output = nullptr;

    // CHECKED OUT AND CHECKED BACK IN ON EVERY PATH. A layer checked out and not
    // checked in leaks a host reference, and AE reports that as an unrelated failure
    // several frames later.
    err = extra->cb->checkout_layer_pixels(in_data->effect_ref, kMistytuneInput, &input);
    if (err) return err;

    // ---------------------------------------------------------------------
    // PAREIDOLIA'S MAP, from the source pre-render checked out, BEFORE THE OUTPUT: the
    // pixels are read once into the map and checked straight back in.
    //
    // ANY FAILURE HERE IS NO SHAPE, NOT A FAILED FRAME, and the log says which. The GPU
    // command never gets a source -- pre-render withdraws the GPU offer when there is one
    // -- so a source seen on that path is named and left alone.
    // ---------------------------------------------------------------------
    cloud::ShapeMap shapeMap;
    bool haveShape = false;
    if (data->shapeCheckedOut && !isGpu) {
        PF_EffectWorld* source = nullptr;
        const double tShape = diagSeconds();
        const PF_Err srcErr = extra->cb->checkout_layer_pixels(in_data->effect_ref,
                                                               kShapeCheckout, &source);
        if (!srcErr && source) {
            PF_PixelFormat srcFormat = PF_PixelFormat_INVALID;
            ConstImageView view;
            if (!pixelFormatOf(in_data, out_data, source, srcFormat) &&
                toSourceView(source, srcFormat, view)) {
                const cloud::PareidoliaParams& pp = data->field.convection.pareidolia;
                haveShape = cloud::buildShapeMap(view, static_cast<cloud::ShapeChannel>(pp.channel),
                                                 pp.threshold, shapeMap);
                diagLog("  pareidolia: %dx%d source -> %dx%d map in %.3f s%s",
                        static_cast<int>(source->width), static_cast<int>(source->height),
                        static_cast<int>(shapeMap.width), static_cast<int>(shapeMap.height),
                        diagSeconds() - tShape,
                        haveShape ? "" : " -- nothing reaches the threshold, no shape");
            } else {
                diagLog("  pareidolia: source format %d not readable -- no shape",
                        static_cast<int>(srcFormat));
            }
        } else {
            diagLog("  pareidolia: source pixels unavailable (err %d) -- no shape",
                    static_cast<int>(srcErr));
        }
        extra->cb->checkin_layer_pixels(in_data->effect_ref, kShapeCheckout);
    } else if (data->shapeCheckedOut) {
        diagLog("  pareidolia: source on the GPU path -- not read, no shape");
        extra->cb->checkin_layer_pixels(in_data->effect_ref, kShapeCheckout);
    }

    err = extra->cb->checkout_output(in_data->effect_ref, &output);
    if (err || !output) diagLog("  checkout_output failed: err=%d", static_cast<int>(err));

    if (!err && output) {
        PF_PixelFormat format = PF_PixelFormat_INVALID;
        err = pixelFormatOf(in_data, out_data, output, format);

        if (!err) {
            if (isGpu) {
                err = smartRenderGpu(in_data, out_data, format, output, extra, *data);
            } else {
                err = smartRenderHost(in_data, out_data, format, output, *data,
                                      haveShape ? &shapeMap : nullptr);
            }
        }
    }

    err2 = extra->cb->checkin_layer_pixels(in_data->effect_ref, kMistytuneInput);
    return err ? err : err2;
}

// ---------------------------------------------------------------------------
// Sequence data
// ---------------------------------------------------------------------------

// PF_Handle RATHER THAN new, because AE owns sequence data across a save and
// reload and has to be able to move it.
// ===========================================================================
// THE CLASSIFIER READOUT, RENAMED IN PLACE.
//
// The readout is a parameter whose NAME is the text (see addStaticText in Params.h), and
// PF_UpdateParamUI on a copy with a new name is how the SDK's own Supervisor sample
// renames one. Called for PF_Cmd_USER_CHANGED_PARAM, which the classifier's supervised
// inputs send as they change, and for PF_Cmd_UPDATE_PARAMS_UI, which covers opening the
// panel and loading a project.
//
// SKIPPED WHEN THE TEXT HAS NOT CHANGED, so a slider drag that stays inside one species
// does not ask AE to redraw the panel on every step.
// ===========================================================================
PF_Err updateReadout(PF_InData* in_data, PF_OutData* out_data, PF_ParamDef* params[]) {
    if (!params || !params[kMistytuneClassification]) return PF_Err_NONE;

    ParamValues values;
    readParamsFromArray(params, values);

    char text[cloud::kReadoutMaxChars + 1];
    cloud::describeSky(cloud::classifySky(toFieldForReadout(values)), text,
                       static_cast<int>(sizeof(text)));

    const PF_ParamDef& current = *params[kMistytuneClassification];
    if (std::strncmp(current.PF_DEF_NAME, text, sizeof(current.PF_DEF_NAME)) == 0) {
        return PF_Err_NONE;
    }

    // A COPY, as PF_UpdateParamUI requires; the params array is AE's.
    PF_ParamDef renamed = current;
    renamed.param_type = PF_Param_FLOAT_SLIDER;
    PF_STRNNCPY(renamed.PF_DEF_NAME, text, sizeof(renamed.PF_DEF_NAME));

    AEFX_SuiteScoper<PF_ParamUtilsSuite3> paramUtils(in_data, kPFParamUtilsSuite,
                                                     kPFParamUtilsSuiteVersion3, out_data);
    const PF_Err err = paramUtils->PF_UpdateParamUI(in_data->effect_ref,
                                                    kMistytuneClassification, &renamed);
    diagLog("readout: \"%s\" (err %d)", text, static_cast<int>(err));
    return err;
}

PF_Err sequenceSetup(PF_InData* in_data, PF_OutData* out_data) {
    AEGP_SuiteHandler suites(in_data->pica_basicP);

    PF_Handle handle = suites.HandleSuite1()->host_new_handle(sizeof(SequenceData));
    if (!handle) return PF_Err_OUT_OF_MEMORY;

    SequenceData* seq = static_cast<SequenceData*>(suites.HandleSuite1()->host_lock_handle(handle));
    if (!seq) {
        suites.HandleSuite1()->host_dispose_handle(handle);
        return PF_Err_OUT_OF_MEMORY;
    }

    // PLACEMENT-NEW, because host_new_handle returns raw bytes and SequenceData has
    // a member with a constructor. Zeroing it instead would happen to work today and
    // stop working the moment FieldCache gains a std::mutex in Phase 2.
    new (seq) SequenceData();

    suites.HandleSuite1()->host_unlock_handle(handle);
    out_data->sequence_data = handle;
    return PF_Err_NONE;
}

PF_Err sequenceSetdown(PF_InData* in_data, PF_OutData* out_data) {
    AEGP_SuiteHandler suites(in_data->pica_basicP);

    if (in_data->sequence_data) {
        SequenceData* seq =
            static_cast<SequenceData*>(suites.HandleSuite1()->host_lock_handle(in_data->sequence_data));
        if (seq) {
            seq->~SequenceData();
            suites.HandleSuite1()->host_unlock_handle(in_data->sequence_data);
        }
        suites.HandleSuite1()->host_dispose_handle(in_data->sequence_data);
    }
    out_data->sequence_data = nullptr;
    return PF_Err_NONE;
}

} // namespace

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

// SELF-REGISTRATION, NO PiPL. AE 2023+ reads this on both platforms, which removes
// the .r -> PiPLtool -> .rrc -> .rc chain and, with it, the whole class of
// "version mismatch" and "global outflags2 mismatch" failures that came from those
// numbers existing in two places.
//
// EVERY STRING HERE COMES FROM cmake/PluginConfig.cmake through the generated
// identity header. THE MATCH NAME IS PERMANENT from the first build anyone else
// installs: AE stores it in every project file that uses the effect and finds the
// effect by it at load time, so changing it later drops the effect from every saved
// comp and takes the user's sky settings with it.
extern "C" DllExport
PF_Err PluginDataEntryFunction2(
    PF_PluginDataPtr    inPtr,
    PF_PluginDataCB2    inPluginDataCallBackPtr,
    SPBasicSuite*       inSPBasicSuitePtr,
    const char*         inHostName,
    const char*         inHostVersion) {
    (void)inSPBasicSuitePtr; (void)inHostName; (void)inHostVersion;

    // PF_REGISTER_EFFECT_EXT2 IS A STATEMENT, NOT AN EXPRESSION. Its body assigns to
    // a variable named `result` that the caller must already have declared -- so
    // `return PF_REGISTER_EFFECT_EXT2(...)` does not compile, and the error names
    // `result` rather than the macro.
    PF_Err result = PF_Err_INVALID_CALLBACK;

    PF_REGISTER_EFFECT_EXT2(
        inPtr,
        inPluginDataCallBackPtr,
        PLUGIN_NAME,
        PLUGIN_MATCH_NAME,
        PLUGIN_CATEGORY,
        AE_RESERVED_INFO,
        "EffectMain",
        "");

    return result;
}

extern "C" DllExport
PF_Err EffectMain(
    PF_Cmd          cmd,
    PF_InData*      in_data,
    PF_OutData*     out_data,
    PF_ParamDef*    params[],
    PF_LayerDef*    output,
    void*           extra) {
    (void)output;

    PF_Err err = PF_Err_NONE;

    // NEVER EVER THROW INTO AE. The host is C and unwinding through it is undefined;
    // the observable result is a crash with no dialog and no log line.
    try {
        switch (cmd) {
            case PF_Cmd_ABOUT:
                err = about(in_data, out_data);
                break;
            case PF_Cmd_GLOBAL_SETUP:
                err = globalSetup(in_data, out_data);
                break;
            case PF_Cmd_PARAMS_SETUP:
                err = paramsSetup(in_data, out_data);
                break;
            case PF_Cmd_SEQUENCE_SETUP:
            case PF_Cmd_SEQUENCE_RESETUP:
                err = sequenceSetup(in_data, out_data);
                break;
            case PF_Cmd_SEQUENCE_SETDOWN:
                err = sequenceSetdown(in_data, out_data);
                break;
            case PF_Cmd_USER_CHANGED_PARAM:
            case PF_Cmd_UPDATE_PARAMS_UI:
                err = updateReadout(in_data, out_data, params);
                break;
            case PF_Cmd_GPU_DEVICE_SETUP:
                err = gpuDeviceSetup(in_data, out_data,
                                     reinterpret_cast<PF_GPUDeviceSetupExtra*>(extra));
                break;
            case PF_Cmd_GPU_DEVICE_SETDOWN:
                err = gpuDeviceSetdown(in_data, out_data,
                                       reinterpret_cast<PF_GPUDeviceSetdownExtra*>(extra));
                break;
            case PF_Cmd_SMART_PRE_RENDER:
                err = preRender(in_data, out_data,
                                reinterpret_cast<PF_PreRenderExtra*>(extra));
                break;
            case PF_Cmd_SMART_RENDER:
                err = smartRender(in_data, out_data,
                                  reinterpret_cast<PF_SmartRenderExtra*>(extra), false);
                break;
            case PF_Cmd_SMART_RENDER_GPU:
                err = smartRender(in_data, out_data,
                                  reinterpret_cast<PF_SmartRenderExtra*>(extra), true);
                break;
            case PF_Cmd_RENDER:
                // THE NON-SMART PATH, WHICH THIS EFFECT DOES NOT IMPLEMENT. AE should
                // never send it while PF_OutFlag2_SUPPORTS_SMART_RENDER is set, and if
                // it ever does the symptom is an output buffer nobody wrote to -- so
                // it is named here rather than swallowed by `default`.
                diagLog("PF_Cmd_RENDER: the non-smart path, which is NOT implemented.");
                break;
            default:
                break;
        }
    } catch (PF_Err& thrown) {
        err = thrown;
    } catch (...) {
        err = PF_Err_INTERNAL_STRUCT_DAMAGED;
    }

    return err;
}
