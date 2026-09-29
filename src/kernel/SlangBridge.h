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

// The single-scatter albedo of cloud droplets at visible wavelengths.
//
// WATER ABSORBS EVEN LESS THAN ICE IN THE VISIBLE, and a cumulus is the case where
// that matters: a path through one scatters a hundred times or more, so an albedo of
// 0.999 would lose a tenth of the light to absorption that is not there, and the
// interior would read grey rather than the bright white a real cumulus is. Real
// droplets sit around 0.99998 in the green; a hundred bounces at that lose 0.2%.
constexpr float kWaterSingleScatterAlbedo = 0.99998f;

// How the convection layer's procedural majorant grid is cut, in metres.
//
// A QUARTER OF A CELL ACROSS, ALIGNED TO THE CELLS, AND FOUR SLICES DEEP.
//
// ALIGNED, because a box inside one lattice slot is bounded by the density's own fixed
// 3x3 neighbourhood, which the compiler unrolls -- see convUpdraftBound. Unaligned boxes
// took the general loop, and with it the grid made every cloudy scene slower than no
// grid at all. So the box is a power-of-two fraction or multiple of the cell spacing,
// and the lattice is anchored where the pattern is: at its drift, and at the base.
//
// A QUARTER, because smaller boxes give a tighter bound: slang.convection measured half
// a cell proving a tenth of boxes empty, a quarter nearly all of the empty ones.
//
// FLOORED AT 400 m, doubling towards it, because a grazing ray crosses the layer for up
// to 120 km and every box is one iteration of a walk capped at kTrackCap. 120 km at
// 400 m is about 600 crossings on two axes, with room left for the collisions.
constexpr float kConvGridFraction  = 0.25f;
constexpr float kConvGridMinExtent = 400.0f;
constexpr int   kConvGridSlices    = 4;

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

    // ICE OFF IS AN EMPTY SLAB, and that is the whole of honouring the switch.
    // IceParams::enabled was hashed from Phase 1 and read by nothing, so the cirrus
    // could not be turned off. A slab whose top and bottom coincide far below the
    // ground has no range for any ray: slabRange() refuses it, so every walk through
    // this layer ends before it draws a number. Nothing else has to know.
    if (!ice.enabled) {
        s.medium_0.slabTop_0    = -1.0e6f;
        s.medium_0.slabBottom_0 = -1.0e6f;
    }

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
    // The second layer: cellular convection
    // -----------------------------------------------------------------------
    //
    // ABSENT UNLESS THE HOST SAYS THERE CAN BE CLOUD, and absent means the scene
    // functions in BounceLib.slang do exactly what they did with one layer -- see the
    // note on Scene.layer2On. `present` is false for a switched-off layer and for air
    // too dry to saturate under the lid; both render as no cumulus, which is right.
    const cloud::ConvectionParams&  cv = f.convection;
    const cloud::ConvectionDerived& cd = req.convection;

    s.layer2On_0 = cd.present ? 1 : 0;

    // CLAMPED HERE, NOT TRUSTED: AE lets an expression drive any slider past its range.
    // Polarity and coverage outside [0, 1] would make the kernel's bound a weighted sum
    // with a negative weight, which is not a bound. Spacing and billow scale are
    // divisors. The octave loop in convBillow stops at four.
    const float polarity = cv.polarity < 0.0f ? 0.0f : (cv.polarity > 1.0f ? 1.0f : cv.polarity);
    const float coverage = cv.coverage < 0.0f ? 0.0f : (cv.coverage > 1.0f ? 1.0f : cv.coverage);
    const float spacing  = cv.cellSize > 1.0f ? cv.cellSize : 1.0f;
    const float billow   = cv.billowAmount > 0.0f ? cv.billowAmount : 0.0f;
    const float bScale   = cv.billowScale > 1.0f ? cv.billowScale : 1.0f;
    const int   octaves  = cv.billowOctaves < 1 ? 1 : (cv.billowOctaves > 4 ? 4 : cv.billowOctaves);

    s.medium2_0.conv_0.cvBase_0        = cd.base;
    s.medium2_0.conv_0.cvDepth_0       = cd.depth;
    s.medium2_0.conv_0.cvSpacing_0     = spacing;
    s.medium2_0.conv_0.cvPolarity_0    = polarity;
    s.medium2_0.conv_0.cvCoverage_0    = coverage;
    s.medium2_0.conv_0.cvShape_0       = cd.shape;
    s.medium2_0.conv_0.cvSigma_0       = cd.sigma;
    s.medium2_0.conv_0.cvBillow_0      = billow;
    s.medium2_0.conv_0.cvBillowScale_0 = bScale;
    s.medium2_0.conv_0.cvOctaves_0     = octaves;
    s.medium2_0.conv_0.cvDrift_0       = V::v2(cd.driftX, cd.driftZ);
    s.medium2_0.conv_0.cvAge_0         = cd.age;
    s.medium2_0.conv_0.cvRise_0        = cd.rise;

    // THE SLAB IS THE TALLEST THE CLOUD CAN BE: the tallest tower plus the biggest
    // outward billow. convectionDensity() returns zero outside exactly this range.
    s.medium2_0.slabBottom_0 = cd.base;
    s.medium2_0.slabTop_0    = cd.base + cd.depth + billow;
    s.medium2_0.majorant_0   = cd.sigma;
    s.medium2_0.density_0    = 0.0f;
    s.medium2_0.mode_0       = 3;          // cellular convection

    // Mode 1's core and mode 2's generator, which mode 3 never reads. The radius and
    // the ice divisors are left non-zero for the reason given for medium_0 above.
    s.medium2_0.coreCentre_0  = V::v3(0.0f, 0.0f, 0.0f);
    s.medium2_0.coreRadius_0  = 1.0f;
    s.medium2_0.coreDensity_0 = 0.0f;
    s.medium2_0.gen_0.streakLength_0 = 1.0f;
    s.medium2_0.gen_0.cellSize_0     = 1.0f;
    s.medium2_0.gen_0.fallSpeed_0    = 1.0f;
    s.medium2_0.gen_0.detailScale_0  = 1.0f;

    // THE PROCEDURAL GRID. No storage: gridBound() computes each box's bound from the
    // generator's structure as the walk enters it. The lattice is anchored at the base
    // so that its slices line up with the flat bottom, where the density switches on.
    float across = spacing * kConvGridFraction;
    for (int k = 0; k < 24 && across < kConvGridMinExtent; ++k) across *= 2.0f;
    const float slice  = (cd.depth + billow) / static_cast<float>(kConvGridSlices);
    s.grid2_0.origin_0     = V::v3(cd.driftX, cd.base, cd.driftZ);
    s.grid2_0.cellExtent_0 = V::v3(across, slice > 1.0f ? slice : 1.0f, across);
    s.grid2_0.dims_0       = V::i3(1, 1, 1);
    s.grid2_0.enabled_0    = req.convectionGrid ? 2 : 0;

    s.albedo2_0 = V::v3(kWaterSingleScatterAlbedo,
                        kWaterSingleScatterAlbedo,
                        kWaterSingleScatterAlbedo);

    // Droplets, not crystals: the Jendersie-d'Eon fit, from the host's mirror of it.
    //
    // DELTA-EDDINGTON TRUNCATED: the diffraction lobe is out of the mixture every event
    // scatters with, and out of the extinction (cd.sigma already carries that), and
    // comes back only in the camera ray's single scattering. See truncateDiffraction()
    // in ConvectionField.h, which says why and what it costs.
    s.phase2_0.hgG_0         = cd.phase.transport.hgG;
    s.phase2_0.draineG_0     = cd.phase.transport.draineG;
    s.phase2_0.draineAlpha_0 = cd.phase.transport.draineAlpha;
    s.phase2_0.draineW_0     = cd.phase.transport.draineW;
    s.phase2_0.useIce_0      = 0;
    s.phase2_0.lobeG_0       = cd.phase.lobeG;
    s.phase2_0.lobeWeight_0  = cd.phase.lobeWeight;

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
    ph.lobeG_0       = 0.0f;   // no truncated lobe: ice is not delta-scaled
    ph.lobeWeight_0  = 0.0f;
}

} // namespace plugin::kernel
