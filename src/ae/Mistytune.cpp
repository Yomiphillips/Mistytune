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

#include <cstring>
#include <new>
#include <vector>

using namespace plugin;
using namespace plugin::ae;

namespace {

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
    const char* framework = "unknown";
    switch (extra->input->what_gpu) {
        case PF_GPU_Framework_CUDA:    framework = "CUDA";    break;
        case PF_GPU_Framework_OPENCL:  framework = "OpenCL";  break;
        case PF_GPU_Framework_METAL:   framework = "Metal";   break;
        case PF_GPU_Framework_DIRECTX: framework = "DirectX"; break;
        default: break;
    }

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
    extra->output->flags |= PF_RenderOutputFlag_GPU_RENDER_POSSIBLE;

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

    // THE OUTPUT SIZE COMES FROM THE REQUEST, NOT FROM THE COMP.
    //
    // At reduced resolution the buffer is smaller, and a renderer that used the comp
    // size here would write past the end of it. The camera's field of view is
    // deliberately NOT scaled to match: a smaller buffer of the same view is exactly
    // what a proxy render is, and scaling the FOV would zoom the image instead.
    const PF_LRect& req = extra->input->output_request.rect;
    data->view.widthPx  = req.right - req.left;
    data->view.heightPx = req.bottom - req.top;

    fillCameraFromComp(in_data, data->view);

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

// WHY THIS IS NOT JUST "THE SLOW ONE".
//
// AE takes it at 8 and 16 bpc regardless of what the GPU can do, and on any machine
// whose GPU is unavailable. So it is not an optional path -- it is the one most
// users will hit first, and PLAN.md's Phase 1 exit criterion names all three bit
// depths explicitly.
//
// THE RENDERER'S OUTPUT IS HDR, so the integer formats are reached through a float
// staging buffer rather than by rendering into them. Quantising to 8 bits is the LAST
// thing that should happen to a radiance value, not the first: rendering directly
// into an integer buffer would clamp the sun to white before the tonemap ever saw it.
PF_Err smartRenderCpu(PF_InData* in_data, PF_OutData* out_data,
                      PF_PixelFormat format, PF_EffectWorld* output,
                      const PreRenderData& data) {
    (void)in_data; (void)out_data;

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

    req.firstSample        = 0;
    req.sampleCount        = data.quality.samplesPerPixel;
    req.samplesAlreadyDone = 0;
    req.accumulator        = nullptr;

    if (format == PF_PixelFormat_ARGB128) {
        // Straight into AE's buffer: it is already the format the renderer works in.
        req.dest = toSurface(output, format);
        kernel::renderCpu(req);
        return PF_Err_NONE;
    }

    // 8 or 16 bpc: render to float, then convert.
    std::vector<float> staging;
    const size_t pixels = static_cast<size_t>(output->width) * static_cast<size_t>(output->height);
    staging.assign(pixels * 4, 0.0f);

    req.dest.data     = staging.data();
    req.dest.widthPx  = output->width;
    req.dest.heightPx = output->height;
    req.dest.pitchPx  = output->width;          // tightly packed, unlike AE's worlds
    req.dest.order    = kernel::ChannelOrder::ARGB;

    kernel::renderCpu(req);

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

    const PreRenderData* data =
        reinterpret_cast<const PreRenderData*>(extra->input->pre_render_data);
    if (!data) return PF_Err_INTERNAL_STRUCT_DAMAGED;

    PF_EffectWorld* input  = nullptr;
    PF_EffectWorld* output = nullptr;

    // CHECKED OUT AND CHECKED BACK IN ON EVERY PATH. A layer checked out and not
    // checked in leaks a host reference, and AE reports that as an unrelated failure
    // several frames later.
    err = extra->cb->checkout_layer_pixels(in_data->effect_ref, kMistytuneInput, &input);
    if (err) return err;

    err = extra->cb->checkout_output(in_data->effect_ref, &output);

    if (!err && output) {
        PF_PixelFormat format = PF_PixelFormat_INVALID;
        err = pixelFormatOf(in_data, out_data, output, format);

        if (!err) {
            if (isGpu) {
                err = smartRenderGpu(in_data, out_data, format, output, extra, *data);
            } else {
                err = smartRenderCpu(in_data, out_data, format, output, *data);
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
