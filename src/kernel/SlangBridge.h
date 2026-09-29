#pragma once

// RenderRequest -> the kernel's own structs, written ONCE and compiled per backend.
//
// ===========================================================================
// MEMBER BY MEMBER, AND `sizeof` IS NOT A SHORTCUT AVAILABLE HERE.
//
// PROGRESS.md records the measurement: `Medium_0` is 96 bytes when slangc emits it
// for CUDA and 112 when it emits it for C++, because one target uses `float3` and
// the other `Vector<float,3>`, and the two need not agree on size or alignment.
//
// The first thing anyone writes here is a memcpy. It compiles, it runs, and it
// renders a picture that is WRONG IN A WAY THAT DOES NOT LOOK LIKE A BUG -- the
// first attempt at slang.cpuParity did exactly this and every CPU ray came back with
// transmittance 1.0, which reads as "the ray missed the cloud", not as a
// marshalling error. It cost an afternoon.
//
// So: field by field, by name, for both backends.
// ===========================================================================
//
// WHY THIS IS A TEMPLATE RATHER THAN THE SAME FORTY LINES IN TWO FILES.
//
// The two backends' structs have the same MEMBER NAMES -- Slang's suffixing gives
// every host-visible field `_0` on both, which tests/slang/ now checks -- and differ
// only in their vector types. A template over the struct types with a tiny vector
// factory handed in is therefore the whole difference between them, and it means
// this marshalling exists once. Two copies of it would drift, and the way they would
// drift is one backend picking up a new parameter and the other not, which presents
// as a CPU/GPU mismatch in the golden suite with no obvious cause.
//
// IT RUNS ON THE DEVICE. renderPixel calls it from inside the CUDA kernel, so
// nothing here may call into src/engine/ -- every derived value it needs is already
// in the request. See RenderRequest.h.

#include "RenderRequest.h"

namespace plugin::kernel {

// The single-scatter albedo of ice at visible wavelengths.
//
// NOT A TUNING CONSTANT. Ice is very nearly non-absorbing in the visible, which is
// why cirrus is white rather than grey and why it is the cheapest generator to
// render: a photon that is never absorbed costs only the bounces it takes to leave.
// The prototype's slider defaults here and its range stops at 1.
//
// IT WILL BECOME A PARAMETER, and deliberately is not one yet: adding a field to
// FieldParams trips Fingerprint.cpp's sizeof tripwire, which is the tripwire working
// -- it wants the new field hashed in the same change. That belongs with the rest of
// the Phase 3 parameter work rather than smuggled in beside a renderer.
constexpr float kIceSingleScatterAlbedo = 0.999f;

// Where Russian roulette starts, counted in scattering events.
//
// FOUR, FROM THE PROTOTYPE. Early bounces are the cheap ones and carry most of the
// energy, so killing them buys little and costs variance; by the fourth the
// throughput is low enough that the survivors are worth more than the paths.
// slang.bounce checks the only property that matters here -- roulette is a free
// parameter, so turning it off must not move the answer.
constexpr int kRussianRouletteStart = 4;

// Marshal the request into a Scene and a PhaseInput.
//
// `V` supplies the backend's vector constructors: V::v2(x, y), V::v3(x, y, z) and
// V::i3(x, y, z). It is a type rather than three arguments so the call site reads as
// "fill these, for this backend".
template <class V, class SceneT, class PhaseT>
MT_RENDER void fillSlangScene(const RenderRequest& req, SceneT& s, PhaseT& ph) {
    const cloud::FieldParams& f   = req.field;
    const cloud::IceParams&   ice = f.ice;

    // -----------------------------------------------------------------------
    // The generator
    // -----------------------------------------------------------------------
    s.medium_0.gen_0.cellAltitude_0 = ice.cellAltitude;
    s.medium_0.gen_0.streakLength_0 = ice.streakLength;
    s.medium_0.gen_0.cellSize_0     = ice.cellSize;
    s.medium_0.gen_0.cellDensity_0  = ice.cellDensity;
    s.medium_0.gen_0.cellStrength_0 = ice.cellStrength;
    s.medium_0.gen_0.cellDrift_0    = V::v2(req.cellDriftX, req.cellDriftZ);
    s.medium_0.gen_0.sublimation_0  = ice.sublimationRate;
    s.medium_0.gen_0.fallSpeed_0    = req.fallSpeed;
    s.medium_0.gen_0.detailScale_0  = ice.detailScale;
    s.medium_0.gen_0.detailAmount_0 = ice.detailAmount;
    s.medium_0.gen_0.opticalDepth_0 = ice.opticalDepth;
    s.medium_0.gen_0.timeSeconds_0  = f.timeSeconds;
    s.medium_0.gen_0.octaves_0      = ice.detailOctaves;

    // -----------------------------------------------------------------------
    // The medium
    // -----------------------------------------------------------------------
    //
    // THE SLAB IS THE GENERATOR'S OWN EXTENT, not a separate parameter. Crystals are
    // made at the generating level and are gone `streakLength` below it, so a slab
    // that disagreed with those two would either clip the streaks or make the
    // tracker march through empty air above and below them.
    s.medium_0.slabTop_0     = ice.cellAltitude;
    s.medium_0.slabBottom_0  = ice.cellAltitude - ice.streakLength;
    s.medium_0.majorant_0    = req.densityMajorant;
    s.medium_0.density_0     = 0.0f;
    s.medium_0.mode_0        = 2;          // the ice generator

    // Mode 1's Gaussian core, which mode 2 never reads. A RADIUS OF ONE RATHER THAN
    // ZERO: it is a divisor in that branch, and leaving a divisor at zero in a field
    // nothing currently reads is how a later `mode` change produces NaNs that look
    // like a transport bug.
    s.medium_0.coreCentre_0  = V::v3(0.0f, 0.0f, 0.0f);
    s.medium_0.coreRadius_0  = 1.0f;
    s.medium_0.coreDensity_0 = 0.0f;

    // -----------------------------------------------------------------------
    // The majorant grid: OFF, and that is a measurement rather than a shortcut
    // -----------------------------------------------------------------------
    //
    // Measured 2026-09-28 on exactly this generator: the 16^3 grid costs 16.2
    // tracking steps per ray against the global majorant's 2.4 -- SEVEN TIMES SLOWER
    // -- because it pays a traversal step per cell crossed whatever the density is,
    // and thin cirrus spread through 1500 m is nearly uniform where it exists. The
    // grid wins 25x on a background with a hard core, which is a cumulus, and that
    // is the case Phase 3 brings.
    //
    // IT IS WIRED AND PROVED CORRECT, so switching it on is a line here. Leaving it
    // on would be paying seven times over for a generator it cannot help.
    //
    // THE 2.4 IS slang.transport's OWN MAJORANT, WHICH IS TIGHTER THAN THE SHIPPING ONE,
    // and the distinction matters now that the shipping one has moved. That test derives
    // its global majorant as the largest cell bound over its 16^3 grid -- 0.00094 per
    // metre, the tightest global bound the structural construction can give -- while
    // iceMajorant() has to bound the field without evaluating the occupancy hash.
    //
    // THE GAP HAS CLOSED AND THE DECISION HELD, which is the useful part: tightening the
    // cell-overlap and depth factors took the shipping majorant from 5.94x that number to
    // 2.01x it. So the global column here got BETTER by about three times while the grid's
    // 16.2 traversal steps did not move at all -- a grid pays per cell crossed whatever
    // the density is. Switching the grid on is a worse trade today than when this was
    // measured, not a closer one.
    //
    // dims AND cellExtent ARE NOT LEFT AT ZERO even though `enabled = 0` means the
    // grid is never consulted: ddaInit still runs and divides by cellExtent.
    s.grid_0.origin_0     = V::v3(0.0f, 0.0f, 0.0f);
    s.grid_0.cellExtent_0 = V::v3(1.0f, 1.0f, 1.0f);
    s.grid_0.dims_0       = V::i3(1, 1, 1);
    s.grid_0.enabled_0    = 0;

    // -----------------------------------------------------------------------
    // The environment: the atmosphere, not an ambient constant
    // -----------------------------------------------------------------------
    //
    // THE SKYLIGHT ON THE CLOUD IS A TRANSPORT RESULT. A path that leaves the medium
    // collects whatever the sky is in the direction it left, so the underside of a
    // deck is lit by the ground-facing half of the atmosphere and the top by the
    // zenith -- which is what an ambient term cannot do and is why there is no
    // ambient term.
    const cloud::AtmosphereParams& atm = f.atmosphere;

    s.environment_0.sky_0.planetRadius_0     = f.physics.planetRadius;
    s.environment_0.sky_0.scaleHeight_0      = f.physics.scaleHeight;
    s.environment_0.sky_0.turbidity_0        = atm.turbidity;
    s.environment_0.sky_0.mieAnisotropy_0    = atm.mieAnisotropy;
    s.environment_0.sky_0.sunAzimuth_0       = atm.sunAzimuth;
    s.environment_0.sky_0.sunElevation_0     = atm.sunElevation;
    s.environment_0.sky_0.sunIntensity_0     = atm.sunIntensity;
    s.environment_0.sky_0.sunAngularRadius_0 = atm.sunAngularRadius;
    s.environment_0.sky_0.groundAlbedo_0     = atm.groundAlbedo;

    // THE TRANSMITTANCE TABLE, AS A POINTER AND A COUNT -- the same two fields the
    // drift table above is handed through, because the prelude generates every
    // StructuredBuffer<T> as { T* data; size_t count; } on both backends.
    //
    // WHICHEVER MEMORY THE REQUEST IS POINTING AT. deriveRenderInputs left the host
    // cache's pointer there; renderCuda has already replaced it with a device one by
    // the time this runs on that path. This function does not know or care which, and
    // that is the same contract driftBuffer is under.
    //
    // A NULL TABLE IS DESCRIBED AS EMPTY RATHER THAN AS A NULL WITH A COUNT, so the
    // kernel's one guard -- a count below the table's size -- catches it. A count set
    // beside a null pointer would sail past that check and index nothing.
    s.environment_0.sky_0.transmittanceLut_0.data =
        const_cast<float*>(static_cast<const float*>(req.transmittanceBuffer));
    s.environment_0.sky_0.transmittanceLut_0.count =
        req.transmittanceBuffer ? static_cast<size_t>(cloud::kTransmittanceFloats) : 0;
    s.environment_0.envMode_0                = 1;

    // Mode 0's uniform radiance, unread at mode 1 and zeroed rather than left as
    // whatever was on the stack -- this struct travels to a GPU.
    s.environment_0.uniformRadiance_0 = V::v3(0.0f, 0.0f, 0.0f);

    // -----------------------------------------------------------------------
    // The scene
    // -----------------------------------------------------------------------
    s.albedo_0 = V::v3(kIceSingleScatterAlbedo,
                       kIceSingleScatterAlbedo,
                       kIceSingleScatterAlbedo);

    // ZERO, AND READ THE NOTE. At envMode 1 the bounce loop takes the sun's
    // brightness from the sky itself -- irradiance at the top of the atmosphere
    // times the transmittance down to the scattering point -- so that the sun and
    // the sky behind the cloud cannot disagree about how bright the sun is. This
    // field is mode 0's answer, which is the furnace test's.
    s.sunIrradiance_0 = V::v3(0.0f, 0.0f, 0.0f);

    const Vec3 sun = sunDirection(atm);
    s.sunDir_0 = V::v3(sun.x, sun.y, sun.z);

    // ZERO, AND IT IS A PARAMETER SO THAT THE TEST CAN PROVE IT MUST BE. The reflex
    // from surface ray tracing is to push the shadow ray off the surface it left; a
    // null-collision medium has no surface to self-intersect, and the offset simply
    // skips that much medium -- every shadow too bright by exp(sigma * offset), at
    // every scattering event of every path. slang.bounce sweeps it.
    s.shadowOffset_0 = 0.0f;

    s.maxBounces_0    = req.quality.maxBounces;
    s.rrStartBounce_0 = kRussianRouletteStart;

    // The camera segment's sun as a sum rather than a coin toss. See
    // cameraSegmentSun in BounceLib.slang and RenderRequest::neeTentativeScale.
    s.neeTentativeScale_0 = req.neeTentativeScale;

    // -----------------------------------------------------------------------
    // The phase function
    // -----------------------------------------------------------------------
    //
    // useIce SELECTS THE ICE ARM, which ignores the four droplet parameters
    // entirely. They are zeroed rather than left undefined for the same reason the
    // unread medium fields are.
    //
    // THE ICE PHASE FUNCTION IS A PLACEHOLDER AND PhaseLib.slang SAYS SO. The real
    // one is a library indexed by habit and orientation, and it is what produces 22
    // and 46 degree halos, sundogs and pillars -- the thing a spherical-droplet
    // model cannot reach. It is Phase 4 content, and the seam is this integer.
    ph.hgG_0         = 0.0f;
    ph.draineG_0     = 0.0f;
    ph.draineAlpha_0 = 0.0f;
    ph.draineW_0     = 0.0f;
    ph.useIce_0      = 1;
}

} // namespace plugin::kernel
