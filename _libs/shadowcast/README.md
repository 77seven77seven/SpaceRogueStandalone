# shadowcast: smooth 2D shadow casting for BYOND

Drop-in, glide-synced shadows with an optional FOV cone and a displacement-filter edge shimmer.

```dm
#include "shadowcast/shadowcast.dm"
```

That is the whole setup. Anything with `opacity = 1` (turfs, objs, mobs) casts shadows, every
connected client sees them from their `eye`, and they slide in step with the camera.
Requires BYOND 515+.

## Using it

| You want | Do |
|---|---|
| Shadows | include the file |
| Walls that stay visible in the dark (like your screenshot) | give them a plane above `SHADOWCAST_PLANE` (demo does this) |
| HUD on top of the shadows | HUD plane above `SHADOWCAST_PLANE` (default `1`) |
| Flashlight / FOV cone | `mob.shadowcast_fov = 120` (degrees, 360 = off); facing follows `dir`, or set `mob.shadowcast_facing = angle` |
| Off for one player | `client.shadowcast_enabled = 0` |
| Custom blockers | `#define SHADOWCAST_BLOCKS(T) your_proc(T)` before the include |
| Smooth glides | set `glide_size` on the mob (the demo's `Move()` shows how). `animate_movement = NO_STEPS` snaps |
| No latency | `#define SHADOWCAST_MANUAL_TICK` and call `shadowcast_tick()` from `/world/Tick()` |

Every knob is an `#ifndef` in `config.dm`: define it before the include to override it.

## How the smoothing works

A shadow is one quad per light-facing-away tile face: `near = A - L`, `far = m * (A - L)`, relative to the light `L`.
Each vertex is therefore affine in `L`. BYOND's `animate(transform = ..., flags = ANIMATION_LINEAR_TRANSFORM)`
interpolates matrix entries linearly, so while the camera glides from `L0` to `L1` every shadow vertex
slides along a straight line, which is exactly where the true shadow is at every instant. The server
sends one `animate()` per triangle per step and does no per-frame work. A face the light crosses
mid-glide collapses to zero area at the crossing instant (and grows from it), so nothing pops.

Each quad is two matrix-transformed right-triangle sprites (`triangle.png`), composited on a plane
master. `SEAM_GAIN` closes the hairline where triangles meet.

## Displacement filter

The mask plane carries `filter(type = "displace")` fed by a hidden noise map (`noise.png`, a
`*` render target) that slowly drifts, so shadow edges shimmer a few pixels instead of being razor
straight. `SHADOWCAST_DISPLACE_SIZE` (px) sets the strength, `0` removes it. The mask plane master is
`master.filters[1]` if you want to drive it yourself (heat haze, flicker, an explosion pulse).

## Verification and its limits

I could not run BYOND in the build sandbox. What was checked:

* `dreamchecker` (SpacemanDMM): 0 diagnostics on the library + demo, also with `MANUAL_TICK`, displacement off and a 1024px sprite.
* `tools/verify.py`: a line-for-line Python port of `geometry.dm`, with a software "client" (bilinear texture sampling, alpha blending, gain), compared with brute-force raycasting.
  * 5 static scenes (incl. sub-tile offsets): 0 wrong pixels.
  * 10 glides (axis, diagonal, past walls, mid-glide start, pixel steps), frames at t = 0, .25, .5, .75, 1: worst 0.014% wrong.
  * 12 FOV cone configs: worst 0.001% wrong.
* Against your reference screenshot: 185,039 pixels compared; 0 disagree away from shadow boundaries.

Not verified (needs a real client; check these first if something looks off):

1. The mask plane master draws above your world and below your HUD (`SHADOWCAST_PLANE`).
2. Timing: the shadows end their glide when the camera does. If they lead or lag, check the mob's `glide_size` is what the client really uses.
3. `ANIMATION_LINEAR_TRANSFORM` interpolating the triangle matrices linearly (documented, but this is the load-bearing assumption).
4. The displace filter reading the `*shadowcast_noise` render target from the mask plane master.

`python3 tools/make_assets.py [size]` regenerates the sprites; `python3 tools/verify.py` re-runs the checks.
