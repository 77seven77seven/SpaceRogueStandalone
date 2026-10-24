// ============================================================================
//  shadowcast  -  smooth, animated, drop-in 2D shadow casting for BYOND
//
//      #include "shadowcast/shadowcast.dm"
//
//  That is the whole setup. Anything with `opacity = 1` casts shadows,
//  every connected client sees them from their eye, and they glide in step
//  with the camera. See README.md for the knobs.
// ============================================================================

#include "config.dm"
#include "geometry.dm"
#include "scan.dm"
#include "objects.dm"
#include "view.dm"
#include "edges.dm"
#include "fov.dm"
#include "tick.dm"
