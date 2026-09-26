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
// to protect. The FieldCache below is the thing that will need the lock in Phase 2,
// when it starts describing a real GPU allocation -- and it is declared here now,
// unused for caching, so that the place the lock goes is already decided rather than
// being invented under pressure later.
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

    // THE CAMERA'S FRAME IS THE LAYER, NOT THE REQUESTED RECT.
    //
    // in_data->width/height are the layer's size at the current downsample, which is
    // the whole picture the lens sees. THE REQUESTED RECT IS NOT THAT: AE asks for
    // whatever area it needs and the buffer it hands back is a third size again --
    // measured on a plain 1920x1080 comp, the request was [-192,-108 2304x1296] while
    // the output world was 1920x1080.
    //
    // Storing the REQUEST size here was a framing bug: every ray got divided by a
    // denominator 20% too large, so the field of view silently widened and the image
    // slid off centre. The buffer's own offset within the frame is read at render
    // time, where AE fills it in -- see smartRender.
    //
    // THE FIELD OF VIEW IS STILL NOT SCALED BY THE DOWNSAMPLE, and that part was
    // always right: a smaller buffer of the same view is exactly what a proxy render
    // is, and scaling the FOV would zoom the image instead.
    data->view.widthPx  = in_data->width;
    data->view.heightPx = in_data->height;

    const PF_LRect& req = extra->input->output_request.rect;

    fillCameraFromComp(in_data, data->view);

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
    data->key.field = fp.value();
    data->key.view  = sim::viewHash(data->view, data->quality);

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
    return err;
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

    // READ AT RENDER, NOT AT PRE-RENDER. AE fills output_origin_x/y in for the call
    // that hands over the buffer; it is the offset of this buffer's pixel (0,0)
    // within the frame, and without it the renderer draws the wrong part of the
    // picture. See the frame/window note in CloudParams.h.
    req.view.originX = in_data->output_origin_x;
    req.view.originY = in_data->output_origin_y;

    // ONE LAUNCH, ALL THE SAMPLES -- FOR NOW, AND THIS IS THE ONE PLACE PHASE 1
    // KNOWINGLY LEAVES A KNOWN HAZARD IN.
    //
    // The Windows display driver's timeout is about two seconds and a real frame sits
    // on it, so the shipping renderer must be many launches with the accumulator
    // persisting between them, checking AE's abort and reporting progress in between.
    // req.firstSample / sampleCount and the accumulator fields already exist for
    // exactly that, and FieldCache already counts samples across launches.
    //
    // It is safe HERE only because the placeholder kernel is a handful of
    // transcendentals per pixel and cannot approach the timeout. The chunked loop
    // lands in Phase 2 with the real transport, where it is load-bearing rather than
    // precautionary -- and where the abort and progress callbacks land with it,
    // because a host that looks frozen for a whole frame gets killed by the user.
    req.firstSample        = 0;
    req.sampleCount        = data.quality.samplesPerPixel;
    req.samplesAlreadyDone = 0;
    req.accumulator        = nullptr;

    if (!kernel::renderCuda(req)) {
        const char* why = kernel::lastCudaError();
        diagLog("SMART_RENDER_GPU: launch failed: %s", why[0] ? why : "(no detail)");
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

    // See the note on the GPU path: the buffer's offset within the frame is only
    // known at render time.
    req.view.originX = in_data->output_origin_x;
    req.view.originY = in_data->output_origin_y;

    diagLog("  frame=%dx%d origin=%d,%d", req.view.widthPx, req.view.heightPx,
            req.view.originX, req.view.originY);

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
    const bool useGpu = kernel::cudaAvailable();

    // THE BAND BUDGET IS PER ENGINE, because the two are three orders of magnitude
    // apart and one number cannot serve both.
    //
    //   CPU  256K pixel-samples is a few tenths of a second (measured ~1.7 us each).
    //   GPU   32M pixel-samples is about the same wall time (measured ~5 ns each),
    //         and staying near a quarter second is what keeps every launch clear of
    //         the Windows display-driver timeout, which kills the whole context
    //         rather than just the launch.
    const long long kBandBudget = useGpu ? (32 * 1024 * 1024) : (256 * 1024);
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

    const double t0 = diagSeconds();

    for (A_long y = 0; y < output->height; y += rowsPerBand) {
        const A_long y1 = std::min<A_long>(y + rowsPerBand, output->height);

        bool ok = true;
        if (useGpu) {
            ok = kernel::renderCudaToHost(req, static_cast<int>(y), static_cast<int>(y1));
            if (!ok) {
                // FALLS BACK FOR THE REST OF THE FRAME RATHER THAN FAILING IT.
                // A driver reset or an out-of-memory partway down a frame should
                // cost a slow frame, not a black one -- and the bands already
                // written stay valid, because both engines write the identical
                // pixels. The log names it so the slowness is not a mystery.
                const char* why = kernel::lastCudaError();
                diagLog("  GPU band at row %d failed (%s) -- CPU for the rest of this frame.",
                        static_cast<int>(y), why && why[0] ? why : "no detail");
            }
        }
        if (!ok || !useGpu) {
            kernel::renderCpu(req, 0, static_cast<int>(y), static_cast<int>(y1));
        }

        // ABORT BEFORE PROGRESS. PF_ABORT is what lets the user cancel and what lets
        // AE discard a frame whose inputs already changed; a render that ignores it
        // keeps burning minutes on a picture nobody is waiting for any more.
        //
        // The error is RETURNED, not swallowed: PF_Interrupt_CANCEL is how the host
        // is told the buffer is incomplete, and converting a partly-filled staging
        // buffer below would hand AE a half-rendered frame to cache.
        if (PF_Err abortErr = PF_ABORT(in_data)) {
            diagLog("  aborted at row %d of %d after %.2f s",
                    static_cast<int>(y1), static_cast<int>(output->height),
                    diagSeconds() - t0);
            return abortErr;
        }
        if (PF_Err progErr = PF_PROGRESS(in_data, y1, output->height)) return progErr;
    }

    // THE NUMBER THAT SETTLES "IT RENDERS NOTHING" VERSUS "IT IS STILL RENDERING".
    diagLog("  rendered %dx%d on the %s in %.2f s (%d rows per band)",
            static_cast<int>(output->width), static_cast<int>(output->height),
            useGpu ? "GPU" : "CPU", diagSeconds() - t0, rowsPerBand);

    if (direct) return PF_Err_NONE;

    // AE'S 16-BIT CHANNELS RUN 0..32768, NOT 0..65535. Using 65535 makes 16 bpc
    // renders come out roughly half as bright -- subtle enough to survive a casual
    // look, which is what makes it a classic first-plugin bug.
    const bool sixteen = (format == PF_PixelFormat_ARGB64);
    const float scale  = sixteen ? 32768.0f : 255.0f;
    const float maxVal = scale;

    for (A_long y = 0; y < output->height; ++y) {
        const float* src = staging.data() + static_cast<size_t>(y) * output->width * 4;
        char* dstRow = reinterpret_cast<char*>(output->data) +
                       static_cast<ptrdiff_t>(y) * output->rowbytes;

        for (A_long x = 0; x < output->width; ++x) {
            // CLAMPED FOR THE INTEGER FORMATS, and only for them. A radiance above 1
            // is legitimate in 32 bpc float -- it is the sun -- and clamping there
            // would throw away the headroom that path exists to carry. Here there is
            // nowhere to put it.
            float a = src[x * 4 + 0];
            float r = src[x * 4 + 1];
            float g = src[x * 4 + 2];
            float b = src[x * 4 + 3];

            a = a < 0.0f ? 0.0f : (a > 1.0f ? 1.0f : a);
            r = r < 0.0f ? 0.0f : (r > 1.0f ? 1.0f : r);
            g = g < 0.0f ? 0.0f : (g > 1.0f ? 1.0f : g);
            b = b < 0.0f ? 0.0f : (b > 1.0f ? 1.0f : b);

            // ENCODED, BECAUSE THESE TWO FORMATS ARE DISPLAY-REFERRED. See the long
            // note on encodeSrgb in AEBridge.h -- skipping this is what made the
            // render read as black with a sun in it.
            //
            // COLOUR ONLY. ALPHA NEVER GETS A TRANSFER CURVE: it is coverage, not
            // light, and encoding it makes every soft edge composite too opaque.
            // The sky is opaque so it makes no difference to THIS picture, which is
            // exactly why it would survive review and break the first thing that
            // has a real alpha.
            r = encodeSrgb(r);
            g = encodeSrgb(g);
            b = encodeSrgb(b);

            // BUFFERS ARE PREMULTIPLIED. At alpha 1 -- which an opaque sky always has
            // -- premultiplied and straight are the same numbers, so this is correct
            // rather than merely convenient. A generator with genuine transparency
            // would have to multiply, and colour above its own alpha composites as an
            // over-bright halo on every soft edge.
            const float av = a * scale;
            const float rv = r * scale;
            const float gv = g * scale;
            const float bv = b * scale;

            if (sixteen) {
                A_u_short* p = reinterpret_cast<A_u_short*>(dstRow) + x * 4;
                p[0] = static_cast<A_u_short>(av > maxVal ? maxVal : av + 0.5f);
                p[1] = static_cast<A_u_short>(rv > maxVal ? maxVal : rv + 0.5f);
                p[2] = static_cast<A_u_short>(gv > maxVal ? maxVal : gv + 0.5f);
                p[3] = static_cast<A_u_short>(bv > maxVal ? maxVal : bv + 0.5f);
            } else {
                A_u_char* p = reinterpret_cast<A_u_char*>(dstRow) + x * 4;
                p[0] = static_cast<A_u_char>(av > maxVal ? maxVal : av + 0.5f);
                p[1] = static_cast<A_u_char>(rv > maxVal ? maxVal : rv + 0.5f);
                p[2] = static_cast<A_u_char>(gv > maxVal ? maxVal : gv + 0.5f);
                p[3] = static_cast<A_u_char>(bv > maxVal ? maxVal : bv + 0.5f);
            }
        }
    }

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
