#include "Denoiser.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#if defined(_WIN32)
// GUARDED: the build already defines this project-wide, and redefining it identically
// is still a C4005 under /W4.
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  include <windows.h>
#else
#  include <dlfcn.h>
#endif

namespace plugin::cloud {
namespace {

// ---------------------------------------------------------------------------
// The declared ABI
// ---------------------------------------------------------------------------
//
// TRANSCRIBED FROM tools/oidn/include/OpenImageDenoise/oidn.h, NOT GUESSED, and
// deliberately not #included from there -- see Denoiser.h on why this file must build
// with no OIDN present.
//
// THE RISK THIS CARRIES IS A SILENT ABI MISMATCH: a future OIDN that changed a
// signature would still resolve every symbol and then corrupt the stack. Two things
// bound it. The version is PINNED in cmake/FetchOidn.cmake, so the bytes are known;
// and OIDN's C API is its stability contract -- it is what the .dll exports and what
// every language binding is written against, so it moves on major versions only.
// oidnGetDeviceError is checked after the calls that can fail, which is what turns a
// wrong answer into a reported one.
using OIDNDevice = void*;
using OIDNFilter = void*;
using OIDNBuffer = void*;

constexpr int kDeviceTypeDefault = 0;   // OIDN_DEVICE_TYPE_DEFAULT -- best available
constexpr int kFormatFloat3      = 3;   // OIDN_FORMAT_FLOAT3
constexpr int kErrorNone         = 0;   // OIDN_ERROR_NONE

using PFN_oidnNewDevice            = OIDNDevice (*)(int);
using PFN_oidnCommitDevice         = void       (*)(OIDNDevice);
using PFN_oidnReleaseDevice        = void       (*)(OIDNDevice);
using PFN_oidnGetDeviceError       = int        (*)(OIDNDevice, const char**);
using PFN_oidnNewBuffer            = OIDNBuffer (*)(OIDNDevice, size_t);
using PFN_oidnReleaseBuffer        = void       (*)(OIDNBuffer);
using PFN_oidnWriteBuffer          = void       (*)(OIDNBuffer, size_t, size_t, const void*);
using PFN_oidnReadBuffer           = void       (*)(OIDNBuffer, size_t, size_t, void*);
using PFN_oidnNewFilter            = OIDNFilter (*)(OIDNDevice, const char*);
using PFN_oidnReleaseFilter        = void       (*)(OIDNFilter);
using PFN_oidnSetFilterImage       = void       (*)(OIDNFilter, const char*, OIDNBuffer,
                                                    int, size_t, size_t, size_t, size_t, size_t);
using PFN_oidnSetFilterBool        = void       (*)(OIDNFilter, const char*, bool);
using PFN_oidnCommitFilter         = void       (*)(OIDNFilter);
using PFN_oidnExecuteFilter        = void       (*)(OIDNFilter);

struct Api {
    PFN_oidnNewDevice      newDevice      = nullptr;
    PFN_oidnCommitDevice   commitDevice   = nullptr;
    PFN_oidnReleaseDevice  releaseDevice  = nullptr;
    PFN_oidnGetDeviceError getDeviceError = nullptr;
    PFN_oidnNewBuffer      newBuffer      = nullptr;
    PFN_oidnReleaseBuffer  releaseBuffer  = nullptr;
    PFN_oidnWriteBuffer    writeBuffer    = nullptr;
    PFN_oidnReadBuffer     readBuffer     = nullptr;
    PFN_oidnNewFilter      newFilter      = nullptr;
    PFN_oidnReleaseFilter  releaseFilter  = nullptr;
    PFN_oidnSetFilterImage setFilterImage = nullptr;
    PFN_oidnSetFilterBool  setFilterBool  = nullptr;
    PFN_oidnCommitFilter   commitFilter   = nullptr;
    PFN_oidnExecuteFilter  executeFilter  = nullptr;

    bool ok = false;
    std::string description = "not yet probed";
};

// ---------------------------------------------------------------------------
// Finding the library
// ---------------------------------------------------------------------------

#if defined(_WIN32)

// WHERE OUR OWN BINARY LIVES. The DLLs ship beside the .aex, so this is the answer in
// an install; in a dev tree it is the build output directory the CLI runs from.
//
// GetModuleHandleEx WITH THE ADDRESS OF A FUNCTION IN THIS FILE, not GetModuleFileName
// with a null handle. The latter returns the path of the EXE -- which is
// AfterFX.exe -- and that is emphatically not where the plugin's DLLs are.
std::string ownDirectory() {
    HMODULE self = nullptr;
    if (!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                            GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                            reinterpret_cast<LPCSTR>(&ownDirectory), &self)) {
        return std::string();
    }

    char path[MAX_PATH] = { 0 };
    const DWORD n = GetModuleFileNameA(self, path, MAX_PATH);
    if (n == 0 || n >= MAX_PATH) return std::string();

    std::string s(path, n);
    const size_t slash = s.find_last_of("\\/");
    return slash == std::string::npos ? std::string() : s.substr(0, slash);
}

// LOAD_WITH_ALTERED_SEARCH_PATH IS THE LOAD-BEARING FLAG. OpenImageDenoise.dll is a
// shim that depends on OpenImageDenoise_core.dll, and without this the loader looks
// for that dependency beside the EXE -- AfterFX.exe's directory -- rather than beside
// the DLL it just loaded. The symptom is a load failure naming neither file.
HMODULE tryLoad(const std::string& dir, std::string& outTried) {
    std::string full = dir.empty() ? std::string("OpenImageDenoise.dll")
                                   : dir + "\\OpenImageDenoise.dll";
    outTried = full;
    if (dir.empty()) return LoadLibraryA("OpenImageDenoise.dll");
    return LoadLibraryExA(full.c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH);
}

void* symbol(HMODULE lib, const char* name) {
    return reinterpret_cast<void*>(GetProcAddress(lib, name));
}

#else

std::string ownDirectory() {
    Dl_info info;
    if (dladdr(reinterpret_cast<void*>(&ownDirectory), &info) == 0 || !info.dli_fname) {
        return std::string();
    }
    std::string s(info.dli_fname);
    const size_t slash = s.find_last_of('/');
    return slash == std::string::npos ? std::string() : s.substr(0, slash);
}

void* tryLoad(const std::string& dir, std::string& outTried) {
    std::string full = dir.empty() ? std::string("libOpenImageDenoise.dylib")
                                   : dir + "/libOpenImageDenoise.dylib";
    outTried = full;
    return dlopen(full.c_str(), RTLD_LAZY | RTLD_LOCAL);
}

void* symbol(void* lib, const char* name) { return dlsym(lib, name); }

#endif

// THE ENVIRONMENT OVERRIDE IS FOR DEVELOPMENT AND FOR THE CLI, which runs out of a
// build tree where the DLLs have not been staged beside it. It is read once.
std::string envDirectory() {
#if defined(_WIN32)
    char buf[1024] = { 0 };
    const DWORD n = GetEnvironmentVariableA("MISTYTUNE_OIDN_DIR", buf, sizeof(buf));
    if (n == 0 || n >= sizeof(buf)) return std::string();
    return std::string(buf, n);
#else
    const char* v = std::getenv("MISTYTUNE_OIDN_DIR");
    return v ? std::string(v) : std::string();
#endif
}

// ---------------------------------------------------------------------------
// Loading it, once
// ---------------------------------------------------------------------------
//
// FUNCTION-LOCAL STATIC, so the load happens on first use and exactly once even with
// several AE render threads arriving together -- C++11 guarantees that, and it is not
// incidental here: PF_OutFlag2_SUPPORTS_THREADED_RENDERING means several frames are
// inside this call at the same time on the first frame of a render.
//
// THE NEGATIVE ANSWER IS CACHED TOO. A machine without OIDN must not pay a failed
// LoadLibrary and a directory probe on every frame.
const Api& api() {
    static const Api loaded = [] {
        Api a;

        std::string tried;
        std::string attempts;

#if defined(_WIN32)
        HMODULE lib = nullptr;
#else
        void* lib = nullptr;
#endif
        // In order: an explicit override, beside our own binary, then the system search
        // path. The last is what a machine with OIDN installed system-wide hits.
        const std::string dirs[3] = { envDirectory(), ownDirectory(), std::string() };
        for (int di = 0; di < 3; ++di) {
            const std::string& d = dirs[di];
            // AN UNSET OVERRIDE IS SKIPPED, not tried as an empty directory -- which
            // would load by bare name and then load by bare name again in slot 2, and
            // print the same path twice in the one log line meant to explain a failure.
            if (di == 0 && d.empty()) continue;
            lib = tryLoad(d, tried);
            if (!attempts.empty()) attempts += "; ";
            attempts += tried;
            if (lib) break;
        }

        if (!lib) {
            a.description = "no denoiser -- OpenImageDenoise.dll not found (tried " +
                            attempts + ")";
            return a;
        }

        struct Entry { const char* name; void** slot; };
        const Entry entries[] = {
            { "oidnNewDevice",      reinterpret_cast<void**>(&a.newDevice)      },
            { "oidnCommitDevice",   reinterpret_cast<void**>(&a.commitDevice)   },
            { "oidnReleaseDevice",  reinterpret_cast<void**>(&a.releaseDevice)  },
            { "oidnGetDeviceError", reinterpret_cast<void**>(&a.getDeviceError) },
            { "oidnNewBuffer",      reinterpret_cast<void**>(&a.newBuffer)      },
            { "oidnReleaseBuffer",  reinterpret_cast<void**>(&a.releaseBuffer)  },
            { "oidnWriteBuffer",    reinterpret_cast<void**>(&a.writeBuffer)    },
            { "oidnReadBuffer",     reinterpret_cast<void**>(&a.readBuffer)     },
            { "oidnNewFilter",      reinterpret_cast<void**>(&a.newFilter)      },
            { "oidnReleaseFilter",  reinterpret_cast<void**>(&a.releaseFilter)  },
            { "oidnSetFilterImage", reinterpret_cast<void**>(&a.setFilterImage) },
            { "oidnSetFilterBool",  reinterpret_cast<void**>(&a.setFilterBool)  },
            { "oidnCommitFilter",   reinterpret_cast<void**>(&a.commitFilter)   },
            { "oidnExecuteFilter",  reinterpret_cast<void**>(&a.executeFilter)  },
        };

        // EVERY SYMBOL OR NONE. A partially resolved API is the state that crashes
        // later rather than failing here, and "later" is inside a render.
        for (const Entry& e : entries) {
            *e.slot = symbol(lib, e.name);
            if (*e.slot == nullptr) {
                a.description = std::string("no denoiser -- ") + tried +
                                " is missing " + e.name +
                                " (wrong or corrupt OpenImageDenoise)";
                return a;
            }
        }

        a.ok = true;
        a.description = "OpenImageDenoise loaded from " + tried;
        return a;
    }();

    return loaded;
}

// ---------------------------------------------------------------------------
// Per-thread state
// ---------------------------------------------------------------------------
//
// THREAD_LOCAL, WHICH IS THE SAME ANSWER THE ACCUMULATOR AND THE TRANSMITTANCE TABLE
// CAME TO, AND FOR THE SAME REASON. An OIDN filter is not safe to execute from two
// threads at once, and AE has several frames in flight under
// PF_OutFlag2_SUPPORTS_THREADED_RENDERING. A shared filter behind a mutex would
// serialise the denoise across all of them -- 30 ms becoming 30 ms times the worker
// count -- and PROGRESS.md's field-cache entry already argues at length that a lock
// over per-thread work makes a race deterministic without making it correct.
//
// WHAT IT COSTS IS REAL AND IS NOT YET MEASURED IN THE HOST: one OIDN device per
// render thread, and a CUDA device is not small. If AE runs eight workers this is
// eight contexts. That is the first thing to watch under a multi-frame render, and it
// is recorded here rather than discovered.
struct Session {
    OIDNDevice device = nullptr;
    OIDNFilter filter = nullptr;
    OIDNBuffer buffer = nullptr;
    size_t     bufferBytes = 0;
    int        filterW = 0;
    int        filterH = 0;
    std::vector<float> staging;   // packed RGB, three floats per pixel

    ~Session() { release(); }

    void release() {
        const Api& a = api();
        if (!a.ok) { device = nullptr; filter = nullptr; buffer = nullptr; return; }
        if (filter) { a.releaseFilter(filter); filter = nullptr; }
        if (buffer) { a.releaseBuffer(buffer); buffer = nullptr; }
        if (device) { a.releaseDevice(device); device = nullptr; }
        bufferBytes = 0;
        filterW = filterH = 0;
        staging.clear();
        staging.shrink_to_fit();
    }
};

Session& session() {
    static thread_local Session s;
    return s;
}

// Reports through the device's error channel, and clears it. Returns true if clean.
bool deviceClean(const Api& a, OIDNDevice dev) {
    const char* msg = nullptr;
    return a.getDeviceError(dev, &msg) == kErrorNone;
}

} // namespace

// ---------------------------------------------------------------------------

bool denoiserAvailable() { return api().ok; }

const char* denoiserDescription() { return api().description.c_str(); }

void denoiserShutdown() { session().release(); }

bool denoiseFrame(const DenoiseImage& img) {
    const Api& a = api();
    if (!a.ok) return false;

    if (img.data == nullptr || img.widthPx <= 0 || img.heightPx <= 0) return false;
    if (img.pitchPx < img.widthPx) return false;

    // NOTHING TO KEEP MEANS NOTHING TO DO. Returning false here is honest -- the image
    // was not denoised -- and it skips a filter whose whole result would be discarded.
    const float amount = img.amount < 0.0f ? 0.0f : (img.amount > 1.0f ? 1.0f : img.amount);
    if (amount <= 0.0f) return false;

    Session& s = session();

    if (s.device == nullptr) {
        s.device = a.newDevice(kDeviceTypeDefault);
        if (s.device == nullptr) return false;
        a.commitDevice(s.device);
        if (!deviceClean(a, s.device)) { s.release(); return false; }
    }

    const size_t pixels = static_cast<size_t>(img.widthPx) *
                          static_cast<size_t>(img.heightPx);
    const size_t bytes  = pixels * 3 * sizeof(float);

    // ===================================================================
    // PACKED INTO A TIGHT RGB BUFFER RATHER THAN FILTERED IN PLACE, and there are two
    // independent reasons, either of which alone would force it.
    //
    // 1. CHANNEL ORDER. OIDN's FLOAT3 reads three CONSECUTIVE floats from an offset;
    //    there is no per-channel offset. ARGB puts R,G,B consecutively at byte 4 and
    //    would work -- but BGRA stores B,G,R, which is REVERSED, and no stride
    //    expresses that. Feeding the network BGR would denoise with the colour
    //    statistics of a different image and would look almost right.
    //
    // 2. DEVICE MEMORY. oidnSetSharedFilterImage needs a pointer the DEVICE can read.
    //    Our destination is host memory -- AE's world, or the CLI's -- and on a CUDA
    //    device a plain host pointer is not device-accessible. The buffer path
    //    (oidnNewBuffer / write / read) is the one that works for EVERY device type,
    //    so there is one code path rather than one per device.
    //
    // The pack is the copy the second reason needs anyway, so the first is free.
    // ===================================================================
    if (s.staging.size() != pixels * 3) s.staging.resize(pixels * 3);

    const bool bgra = (img.order == DenoiseOrder::BgraFloat4);
    for (int y = 0; y < img.heightPx; ++y) {
        const float* src = img.data + static_cast<size_t>(y) * img.pitchPx * 4;
        float* dst = s.staging.data() + static_cast<size_t>(y) * img.widthPx * 3;
        for (int x = 0; x < img.widthPx; ++x) {
            const float* p = src + static_cast<size_t>(x) * 4;
            float* q = dst + static_cast<size_t>(x) * 3;
            if (bgra) { q[0] = p[2]; q[1] = p[1]; q[2] = p[0]; }
            else      { q[0] = p[1]; q[1] = p[2]; q[2] = p[3]; }
        }
    }

    if (s.buffer == nullptr || s.bufferBytes < bytes) {
        if (s.buffer) { a.releaseBuffer(s.buffer); s.buffer = nullptr; }
        s.buffer = a.newBuffer(s.device, bytes);
        if (s.buffer == nullptr) { s.bufferBytes = 0; return false; }
        s.bufferBytes = bytes;

        // The filter holds the buffer, so a new buffer means a new binding.
        s.filterW = s.filterH = 0;
    }

    a.writeBuffer(s.buffer, 0, bytes, s.staging.data());

    // REBOUND ONLY WHEN THE GEOMETRY MOVES. oidnCommitFilter is the expensive call --
    // it is where the network is set up for the size -- and a Draft scrub renders the
    // same size over and over. Rebinding per frame would pay that every time.
    if (s.filter == nullptr || s.filterW != img.widthPx || s.filterH != img.heightPx) {
        if (s.filter) { a.releaseFilter(s.filter); s.filter = nullptr; }

        s.filter = a.newFilter(s.device, "RT");
        if (s.filter == nullptr) return false;

        // IN PLACE: the same buffer as colour and as output. OIDN supports this, and
        // it halves the device memory for a frame that can be 24 MB at 1080p.
        a.setFilterImage(s.filter, "color", s.buffer, kFormatFloat3,
                         static_cast<size_t>(img.widthPx),
                         static_cast<size_t>(img.heightPx), 0, 0, 0);
        a.setFilterImage(s.filter, "output", s.buffer, kFormatFloat3,
                         static_cast<size_t>(img.widthPx),
                         static_cast<size_t>(img.heightPx), 0, 0, 0);

        // HDR, BECAUSE THE BUFFER IS SCENE-REFERRED RADIANCE WITH A SUN IN IT. The
        // LDR filter assumes values in 0..1 and would flatten everything above it.
        a.setFilterBool(s.filter, "hdr", true);

        a.commitFilter(s.filter);
        if (!deviceClean(a, s.device)) { s.release(); return false; }

        s.filterW = img.widthPx;
        s.filterH = img.heightPx;
    }

    a.executeFilter(s.filter);
    if (!deviceClean(a, s.device)) { s.release(); return false; }

    a.readBuffer(s.buffer, 0, bytes, s.staging.data());
    if (!deviceClean(a, s.device)) { s.release(); return false; }

    // ===================================================================
    // UNPACKED BACK AND BLENDED, ALPHA UNTOUCHED. Alpha is coverage, not light -- the
    // same rule src/engine/OutputConvert.h and applyOutputTransform already follow.
    //
    // THE BLEND IS FREE AND NEEDS NO SECOND BUFFER, which is why it is here rather than
    // in a pass of its own: the destination still holds the ORIGINAL radiance at this
    // point -- the pack read from it and the filter worked in its own buffer -- so the
    // raw value is simply `p[..]` and the denoised one is `q[..]`.
    //
    // IN LINEAR, BEFORE THE OUTPUT TRANSFORM, which is the only place it can be
    // correct. Blending after the transfer curve would mix two differently encoded
    // images and land the midtones somewhere neither of them is.
    // ===================================================================
    for (int y = 0; y < img.heightPx; ++y) {
        float* dst = img.data + static_cast<size_t>(y) * img.pitchPx * 4;
        const float* src = s.staging.data() + static_cast<size_t>(y) * img.widthPx * 3;
        for (int x = 0; x < img.widthPx; ++x) {
            float* p = dst + static_cast<size_t>(x) * 4;
            const float* q = src + static_cast<size_t>(x) * 3;
            if (bgra) {
                p[2] += (q[0] - p[2]) * amount;
                p[1] += (q[1] - p[1]) * amount;
                p[0] += (q[2] - p[0]) * amount;
            } else {
                p[1] += (q[0] - p[1]) * amount;
                p[2] += (q[1] - p[2]) * amount;
                p[3] += (q[2] - p[3]) * amount;
            }
        }
    }

    return true;
}

} // namespace plugin::cloud
