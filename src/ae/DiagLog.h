#pragma once

// Opt-in diagnostic logging.
//
// An AE plugin has nowhere to print to and no debugger attached when the bug is on
// someone else's machine, and half of what you need to know is a host convention
// nobody documented. A log you can switch on is the instrument that settles those
// questions with real numbers instead of guesses -- but it is off by default,
// because a file open/close per frame on a render thread is not something to ship
// enabled.
//
// THE RULE UNDERNEATH docs/HOST-NOTES.md IS "MEASURE HOST CONVENTIONS, DO NOT
// INFER THEM", and this is the instrument that makes that possible. When you do
// not know what AE hands you, log the actual numbers out of a running host and
// read them.
//
// Enable by setting the environment variable (PLUGIN_DIAG_ENV, from
// cmake/PluginConfig.cmake) to 1 BEFORE launching After Effects, then read the log
// in the temp directory:
//     Windows   %TEMP%\mistytune.log
//     macOS     $TMPDIR/mistytune.log   (per-user, NOT /tmp -- print the path
//                                        from Terminal with `echo $TMPDIR`)
//
// On macOS, launch AE with the variable set like this:
//     open --env MISTYTUNE_DIAG=1 -a "Adobe After Effects 2026"
//
// DELIBERATELY NOT THREAD-SAFE. Under multi-frame rendering several render threads
// can append at once and interleave lines -- and Mistytune sets
// PF_OutFlag2_SUPPORTS_THREADED_RENDERING, so that is the normal case rather than
// the exception. Diagnose on a single still frame; if the output looks shuffled,
// that is why.

#include "PluginIdentity.h"

#include <chrono>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <string>
#include <system_error>

namespace plugin {
namespace ae {

inline bool diagEnabled() {
    static const bool on = [] {
        const char* v = std::getenv(PLUGIN_DIAG_ENV);
        return v && v[0] && v[0] != '0';
    }();
    return on;
}

inline const char* diagPath() {
    static const std::string path = [] {
        // temp_directory_path() reads TEMP on Windows and TMPDIR on macOS, and
        // picks the right separator, which is the whole reason this is not
        // getenv("TEMP") + "\\...".
        std::error_code ec;
        std::filesystem::path dir = std::filesystem::temp_directory_path(ec);
        if (ec) dir = ".";
        return (dir / PLUGIN_LOG_NAME).string();
    }();
    return path.c_str();
}

// A monotonic clock in seconds, for the one measurement the log could not make:
// how long a render actually took.
//
// steady_clock RATHER THAN system_clock, because the only use is a difference and a
// wall clock that steps for an NTP correction or a DST change would report a
// negative render time.
inline double diagSeconds() {
    using clock = std::chrono::steady_clock;
    static const clock::time_point start = clock::now();
    return std::chrono::duration<double>(clock::now() - start).count();
}

inline void diagLog(const char* fmt, ...) {
    if (!diagEnabled()) return;
    FILE* f = std::fopen(diagPath(), "a");
    if (!f) return;
    va_list args;
    va_start(args, fmt);
    std::vfprintf(f, fmt, args);
    va_end(args);
    std::fputc('\n', f);
    std::fclose(f);
}

} // namespace ae
} // namespace plugin
