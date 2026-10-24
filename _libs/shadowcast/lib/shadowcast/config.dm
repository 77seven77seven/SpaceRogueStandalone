// ============================================================================
//  shadowcast / config.dm
//  Every knob is an #ifndef, so you can #define your own value *before*
//  including shadowcast.dm and it wins.
// ============================================================================

// ---- Rendering --------------------------------------------------------------

/// Edge length (px) of triangle.png. Bigger = crisper far shadow edges.
/// Must match the file in this folder (tools/make_assets.py can regenerate it).
#ifndef SHADOWCAST_ICON_SIZE
#define SHADOWCAST_ICON_SIZE 512
#endif

/// The plane the shadows are drawn on. It gets a plane master, so it must be a
/// plane nothing else uses, and it must sit ABOVE your world and BELOW your HUD:
/// give HUD objects a higher plane (or leave the default of 1 and put HUD on 2+).
/// Anything on a lower plane (floors, mobs, walls) is hidden where it is in shadow;
/// put an object on a higher plane to make it show through the dark.
#ifndef SHADOWCAST_PLANE
#define SHADOWCAST_PLANE 2
#endif

/// Colour of the shadow (solid; it is added on top of black, so "#000000" = black).
#ifndef SHADOWCAST_COLOR
#define SHADOWCAST_COLOR "#000000"
#endif

/// Alpha gain applied on the mask plane. >1 closes the hairline seams where two
/// anti-aliased triangles meet (two 50% edges only composite to 75%).
/// Needs to be >= 1.34 to fully hide them.
#ifndef SHADOWCAST_SEAM_GAIN
#define SHADOWCAST_SEAM_GAIN 1.4
#endif

/// Each shadow quad is grown by this many pixels (sideways + into the wall)
/// so neighbouring quads overlap even if the client ignores SEAM_GAIN.
#ifndef SHADOWCAST_EDGE_GROW
#define SHADOWCAST_EDGE_GROW 2
#endif

// ---- Displacement filter (shadow edge shimmer) -------------------------------

/// Max displacement in pixels. 0 disables the displacement filter entirely.
#ifndef SHADOWCAST_DISPLACE_SIZE
#define SHADOWCAST_DISPLACE_SIZE 2
#endif

/// How far (px) the displacement map slowly drifts back and forth, and how long
/// (deciseconds) one drift takes. 0 = static map.
#ifndef SHADOWCAST_DISPLACE_DRIFT
#define SHADOWCAST_DISPLACE_DRIFT 24
#endif
#ifndef SHADOWCAST_DISPLACE_DRIFT_TIME
#define SHADOWCAST_DISPLACE_DRIFT_TIME 60
#endif

/// Plane of the (never drawn) displacement-map object. Anything nothing else uses.
#ifndef SHADOWCAST_NOISE_PLANE
#define SHADOWCAST_NOISE_PLANE -9100
#endif

/// Edge length (px) of noise.png, the displacement map.
#ifndef SHADOWCAST_NOISE_SIZE
#define SHADOWCAST_NOISE_SIZE 512
#endif

// ---- Behaviour ---------------------------------------------------------------

/// Shadow geometry is built for this many pixels beyond the edge of the view.
#ifndef SHADOWCAST_SLACK_PX
#define SHADOWCAST_SLACK_PX 32
#endif

/// Hard cap on live shadow triangles per client (nearest edges win).
#ifndef SHADOWCAST_MAX_TRIS
#define SHADOWCAST_MAX_TRIS 600
#endif

/// Largest extrusion factor. Limits how far an edge hugging the light is stretched.
#ifndef SHADOWCAST_MAX_EXTRUDE
#define SHADOWCAST_MAX_EXTRUDE 32
#endif

/// Moves longer than this many tiles are teleports: snap, do not glide.
#ifndef SHADOWCAST_GLIDE_MAX_TILES
#define SHADOWCAST_GLIDE_MAX_TILES 1.5
#endif

/// Glide time (deciseconds) guessed when the eye has glide_size 0 (auto) and no
/// previous step exists to measure from.
#ifndef SHADOWCAST_DEFAULT_GLIDE_TIME
#define SHADOWCAST_DEFAULT_GLIDE_TIME 2
#endif

/// How often (ticks) to re-scan for opacity changes (doors etc.) while standing still. 0 = never.
#ifndef SHADOWCAST_RESCAN_TICKS
#define SHADOWCAST_RESCAN_TICKS 4
#endif

/// Field-of-view cone: turning speed in degrees per decisecond.
#ifndef SHADOWCAST_TURN_SPEED
#define SHADOWCAST_TURN_SPEED 45
#endif

/// Define SHADOWCAST_MANUAL_TICK to drive the library yourself: call
/// shadowcast_tick() from /world/Tick() (BYOND 515+). That removes the one
/// tick of latency the built-in loop has. Without it the library runs its own loop.
// #define SHADOWCAST_MANUAL_TICK

/// How an atom blocks light. Override the macro for custom rules.
#ifndef SHADOWCAST_BLOCKS
#define SHADOWCAST_BLOCKS(T) shadowcast_default_blocks(T)
#endif
