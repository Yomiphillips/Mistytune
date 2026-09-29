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
// The thing it renders is a placeholder -- an analytic sky in src/kernel/Shading.h.
// There is no volumetric transport yet: no null-collision tracking, no multiple
// scattering, no precomputed atmosphere, no ice generator. Those are Phase 2, ported
// from proto/ once the Phase 0 look verdict is in.
//
// The split is on purpose. Phase 1's exit criterion is about the HOST -- that a
// parameter typed in After Effects reaches a GPU kernel and comes back as correct
// float pixels at 8, 16 and 32 bpc and at reduced resolution. Proving that with a
// renderer that also has to be right would confound two unrelated kinds of bug.
// ===========================================================================

#include "AEBridge.h"
#include "EffectCommon.h"
#include "Params.h"

#include "FieldCache.h"
#include "Fingerprint.h"
#include "KernelApi.h"

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
};

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
// THE FieldCache BELOW IS IN THE WRONG PLACE, AND A LOCK IS NOT THE FIX.
//
// This comment used to say the cache "will need the lock in Phase 2, when it starts
// describing a real GPU allocation". That is the wrong answer, and knowing why is
// worth more than the lock would have been.
//
// A CACHE MUST LIVE WHERE THE MEMORY IT DESCRIBES LIVES. Sequence data is shared
// across every render thread AE has in flight for this layer. The accumulators it
// would describe are NOT: both of them are `thread_local` --
// `g_accum` in CpuRender.cpp and the DeviceScratch of the same name in Mistytune.cu.
//
// So a shared cache describing per-thread buffers is wrong even WITH a lock. Thread A
// adopts a key and records 32 samples; thread B asks, is told "Accumulate", and
// accumulates into ITS OWN empty accumulator while the cache still claims 32 samples
// are in it. The result is a frame that is darker or noisier than its neighbours for
// no visible reason, arriving only under multi-frame rendering. A mutex makes that
// race deterministic; it does not make it correct.
//
// WHERE IT BELONGS is beside the accumulator, thread_local, in the kernel library --
// and then no lock is needed at all, because nothing is shared. A thread that has not
// rendered this key sees an empty cache and renders the frame from scratch, which is
// exactly today's behaviour. THE DESIGN FAILS SAFE: the worst case of a cache miss is
// a slow frame, never a wrong one.
//
// WHAT STILL BLOCKS IT is the GPU accumulator's SIZE rather than its lifetime. The CPU
// one is already full-frame; the CUDA one is BAND-sized (`rowBytes * bandRows` in
// renderCudaToHost), so it is overwritten by each band and cannot carry a frame across
// renders. Making it frame-sized means indexing it by the band's offset into the frame
// -- which is precisely the band-as-window arithmetic this project has got wrong three
// times, and it should be written where a host can be watched rather than blind.
//
// The member stays here for now because nothing reads it, and moving it before the
// accumulator question is settled would just relocate the problem.
// ===========================================================================
struct SequenceData {
    sim::FieldCache cache;
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

    if (kernel::cudaAvailable()) {
        extra->output->flags |= PF_RenderOutputFlag_GPU_RENDER_POSSIBLE;
    } else {
        diagLog("  no GPU path in this build -- not offering GPU_RENDER_POSSIBLE.");
    }

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
    data->field.timeSeconds = currentTimeSeconds(in_data);
    data->quality          = toQuality(values);

    data->view.exposureEV = static_cast<float>(values.v[kMistytuneExposureEV]);
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

    fillCameraFromComp(in_data, data->view);

    // WHICH CAMERA, NAMED RATHER THAN INFERRED FROM THE PICTURE. "No camera,
    // defaulting" and "the comp's camera, and it points there" produce different
    // skies, and telling them apart by looking is exactly the diagnosis this
    // project has repeatedly got wrong.
    diagLog("  camera: %s, vertical fov %.1f deg",
            data->view.cameraFromComp ? "from the comp" : "no comp camera -- default",
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
    data->key.resolve  = sim::resolveHash(data->view);

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
                       const PreRenderData& data) {
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

                req.firstSample        = s0;
                req.sampleCount        = n;
                req.samplesAlreadyDone = s0;

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

                ++unitsDone;
                if (PF_Err progErr = PF_PROGRESS(in_data, unitsDone, totalUnits)) return progErr;
            }
        }
    }

    // THE NUMBER THAT SETTLES "IT RENDERS NOTHING" VERSUS "IT IS STILL RENDERING".
    diagLog("  rendered %dx%d on the %s in %.2f s (%d rows per band)",
            static_cast<int>(output->width), static_cast<int>(output->height),
            useGpu ? "GPU" : "CPU", diagSeconds() - t0, rowsPerBand);

    // =======================================================================
    // THE FRAME IS COMPLETE, SO THE OUTPUT TRANSFORM RUNS -- ONCE, HERE.
    //
    // Everything above leaves LINEAR radiance in `req.dest`. Exposure, AgX and the
    // sRGB transfer curve used to happen inside renderPixel and now do not, because
    // the denoiser wants the linear buffer and the correct order is
    //
    //     render (LINEAR) -> denoise -> output transform -> quantise
    //
    // OIDN goes in immediately above this line when it lands. That is the entire
    // reason this pass exists as a pass.
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

    err = extra->cb->checkout_output(in_data->effect_ref, &output);
    if (err || !output) diagLog("  checkout_output failed: err=%d", static_cast<int>(err));

    if (!err && output) {
        PF_PixelFormat format = PF_PixelFormat_INVALID;
        err = pixelFormatOf(in_data, out_data, output, format);

        if (!err) {
            if (isGpu) {
                err = smartRenderGpu(in_data, out_data, format, output, extra, *data);
            } else {
                err = smartRenderHost(in_data, out_data, format, output, *data);
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
    (void)params; (void)output;

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
