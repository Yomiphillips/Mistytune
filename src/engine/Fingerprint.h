#pragma once

// A hash of everything the FIELD depends on.
//
// THE QUESTION IT ANSWERS: "would rebuilding the volume now give a different
// medium from the one in the cache?" -- without rebuilding it. A field rebuild is
// the expensive half of a frame, and the answer has to be cheap enough to ask on
// every render call, so it is a hash and never a build.
//
// THIS IS THE ROW PLAN.md CALLS THE DIFFERENCE BETWEEN A PLUGIN PEOPLE USE AND
// ONE THEY ABANDON. A camera move changes ViewParams and nothing else, so it must
// not touch this hash -- which is why add(FieldParams) exists and add(ViewParams)
// deliberately does not. Orbit the camera and the cached field stands; the
// renderer restarts accumulation and nothing is rebuilt.
//
// EVERY FIELD THAT REACHES THE GENERATOR MUST BE HASHED. A member left out is a
// change the cache cannot see: the user edits it, the field is not rebuilt, and
// the old sky stays on screen with no way to explain why. Fingerprint.cpp
// static_asserts the sizes of every struct below as a tripwire for exactly that
// -- adding a member breaks the build until someone hashes it.
//
// Bitwise on floats, deliberately: any change at all counts, and the only cost of
// a false "changed" is one redundant rebuild.

#include "CloudParams.h"

#include <cmath>
#include <cstddef>
#include <cstdint>

namespace plugin::sim {

class Fingerprint {
public:
    // THE WHOLE FIELD, in one call. Everything that decides what is in the sky.
    //
    // Prefer this over the per-struct overloads: it is the one that the sizeof
    // tripwire is written against, so a new member inside any nested struct
    // breaks the build here rather than silently going unhashed at some call
    // site that only hashed two of the three.
    void add(const cloud::FieldParams& f);

    // The pieces, exposed for tests and for the CLI's scene files -- which build
    // a field out of parts and want to know which part changed.
    void add(const cloud::PhysicsParams& p);
    void add(const cloud::AtmosphereParams& a);
    void add(const cloud::IceParams& i);
    void add(const cloud::ConvectionParams& c);
    void add(const cloud::ShearProfile& s);
    void add(const cloud::OrganizationParams& o);
    void add(const cloud::PareidoliaParams& p);

    // NOTE THE ABSENCE OF add(ViewParams) AND add(QualityParams), and that it is
    // a design decision rather than an omission.
    //
    // ViewParams is the camera: hashing it would rebuild the field on every
    // frame of a camera move, which is the exact failure this class exists to
    // prevent. QualityParams changes how converged the image is, not what is in
    // it -- raising the sample count continues an accumulation rather than
    // restarting one, and rebuilding the medium to add samples to it would be
    // wrong twice over.
    //
    // If you find yourself wanting one of them here, the value you actually want
    // hashed belongs in FieldParams instead.

    // A LENGTH IN METRES THAT MAKES A ROUND TRIP THROUGH THE HOST, hashed to the
    // nearest millimetre instead of bitwise.
    //
    // For inputs the host's own float<->fixed conversions move: an AE parameter
    // typed as 9000 comes back as 8999.9995 often enough to matter, and bitwise
    // that reads as an edit on every single poll -- so the field rebuilds for
    // ever and the plugin never converges. NOT for values that come straight
    // from our own structs: nothing there round-trips, so nothing there needs
    // the slack.
    void addQuantized(cloud::Real metres) {
        add(static_cast<int64_t>(std::llround(static_cast<double>(metres) * 1000.0)));
    }

    void add(uint64_t v)      { bytes(&v, sizeof v); }
    void add(int64_t v)       { bytes(&v, sizeof v); }
    void add(int32_t v)       { add(static_cast<int64_t>(v)); }
    void add(bool v)          { add(static_cast<int64_t>(v ? 1 : 0)); }
    void add(float v)         { bytes(&v, sizeof v); }

    uint64_t value() const { return m_hash; }

private:
    // FNV-1a, 64-bit. Not cryptographic and does not need to be: it is compared
    // only against this same effect instance's previous value, so the odds of a
    // real edit colliding are about one in 2^64.
    void bytes(const void* p, size_t n);

    uint64_t m_hash = 14695981039346656037ull;
};

} // namespace plugin::sim
