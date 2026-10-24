// ============================================================================
//  shadowcast / objects.dm
//  The few types the renderer is built from, plus the vars you can set on
//  your own mobs and clients. Nothing here needs to be touched to use it.
// ============================================================================

/// One shadow triangle. A HUD object whose transform is animated; the whole
/// shape of a shadow lives in its matrix.
/obj/shadowcast_tri
	icon = 'triangle.png'
	plane = SHADOWCAST_PLANE
	alpha = 0
	mouse_opacity = 0
	appearance_flags = NO_CLIENT_COLOR | TILE_BOUND

/// Groups everything on SHADOWCAST_PLANE into one surface so that overlapping
/// triangles composite together, then applies the seam gain / tint and the
/// displacement filter to the result.
/obj/shadowcast_master
	plane = SHADOWCAST_PLANE
	screen_loc = "1,1"
	mouse_opacity = 0
	appearance_flags = PLANE_MASTER | NO_CLIENT_COLOR

/// Never drawn (render target starts with *). It only exists so the displace
/// filter on the master can read its pixels as a displacement map.
/obj/shadowcast_noise
	icon = 'noise.png'
	plane = SHADOWCAST_NOISE_PLANE
	render_target = "*shadowcast_noise"
	mouse_opacity = 0
	appearance_flags = NO_CLIENT_COLOR | TILE_BOUND

/// Per-edge bookkeeping: the two triangles currently representing one tile face.
/datum/shadowcast_edge
	var/datum/shadowcast_view/view
	var/obj/shadowcast_tri/t1
	var/obj/shadowcast_tri/t2
	/// extrusion factor the triangles were built with
	var/m = 0
	/// 1 while the face is (or is about to be) casting a shadow
	var/live = 0
	var/stamp = 0
	/// world.time at which a vanishing face can give its triangles back
	var/release = 0

/// Give the triangles back to the pool.
/datum/shadowcast_edge/proc/hide()
	if(t1)
		view.give_tri(t1)
		t1 = null
	if(t2)
		view.give_tri(t2)
		t2 = null
	live = 0
	m = 0

/// Make sure this face owns two triangles. Returns 0 if the pool is exhausted.
/datum/shadowcast_edge/proc/claim()
	if(!t1)
		t1 = view.take_tri()
	if(!t2)
		t2 = view.take_tri()
	if(t1 && t2)
		return 1
	hide()
	return 0

/// Snap to a shape right now (no animation), visible or not.
/datum/shadowcast_edge/proc/place(list/mats, new_m, visible)
	t1.transform = mats[1]
	t2.transform = mats[2]
	t1.alpha = visible ? 255 : 0
	t2.alpha = visible ? 255 : 0
	m = new_m
	live = visible

// ---- vars you can set ---------------------------------------------------------

/client
	/// The renderer for this client. Created automatically.
	var/datum/shadowcast_view/shadowcast
	/// Set to 0 to switch shadows off for this client (and back to 1 to resume).
	var/shadowcast_enabled = 1

/atom/movable
	/// Field of view in degrees when this atom is somebody's eye. 360 = no cone.
	var/shadowcast_fov = 360
	/// Facing in degrees (0 = east, 90 = north). null = use dir.
	var/shadowcast_facing = null
	/// How far (px) behind the eye the cone starts, so the tiles beside you stay visible.
	var/shadowcast_fov_behind = 16
	/// Move the light away from the middle of the atom (pixels).
	var/shadowcast_offset_x = 0
	var/shadowcast_offset_y = 0
