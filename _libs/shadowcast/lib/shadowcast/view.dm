// ============================================================================
//  shadowcast / view.dm
//  One /datum/shadowcast_view per client: layout, the triangle pool, the
//  displacement filter, and the per-tick "did the light move?" logic.
//  Edge updates live in edges.dm, the FOV cone in fov.dm.
// ============================================================================

/datum/shadowcast_view
	var/client/owner
	// -- layout (tiles / pixels), recomputed when client.view or icon_size changes
	var/layout_key
	var/tw = 32
	var/th = 32
	var/vw = 15
	var/vh = 15
	/// screen tile (1-based) the eye is drawn on
	var/ex = 8
	var/ey = 8
	/// how far the view reaches from the light along an axis, and along the diagonal (+ slack)
	var/ext = 300
	var/ext_diag = 400
	/// scan window in tiles beyond the eye tile
	var/win_l = 9
	var/win_r = 9
	var/win_d = 9
	var/win_u = 9
	var/anchor_loc = "8:-240,8:-240"
	// -- screen objects
	var/obj/shadowcast_master/master
	var/obj/shadowcast_noise/noise
	var/list/pool = list()
	var/tri_count = 0
	// -- shadow state
	var/list/edges = list()
	var/list/dying = list()
	var/serial = 0
	var/list/cone = list()
	var/cone_phi = 0
	var/cone_fov = 360
	// -- light timeline: the shadows glide (from_x,from_y) -> (to_x,to_y) over dur deciseconds from t0
	var/has_light = 0
	var/atom/last_eye
	var/last_z = 0
	var/from_x = 0
	var/from_y = 0
	var/to_x = 0
	var/to_y = 0
	var/t0 = 0
	var/dur = 0
	var/last_move_time = 0
	var/rescan_in = 0
	/// deciseconds the built-in loop is behind the client (0 when you call shadowcast_tick() from world/Tick)
	var/lag_ds = 0

/datum/shadowcast_view/New(client/C)
	owner = C
#ifndef SHADOWCAST_MANUAL_TICK
	lag_ds = world.tick_lag
#endif
	build_layout()

/// Work out tile size, view size, where the eye sits and how far the view reaches.
/datum/shadowcast_view/proc/build_layout()
	layout_key = "[owner.view]|[world.icon_size]"
	var/list/ts = shadowcast_parse_size(world.icon_size)
	var/list/vs = shadowcast_view_size(owner.view)
	tw = ts[1]
	th = ts[2]
	vw = vs[1]
	vh = vs[2]
	ex = floor(vw / 2) + 1
	ey = floor(vh / 2) + 1
	// distance from the eye tile's centre to the far edge of the view
	var/reach_x = max((ex - 1) * tw + tw / 2, (vw - ex) * tw + tw / 2)
	var/reach_y = max((ey - 1) * th + th / 2, (vh - ey) * th + th / 2)
	ext = max(reach_x, reach_y) + SHADOWCAST_SLACK_PX
	ext_diag = sqrt(reach_x * reach_x + reach_y * reach_y) + SHADOWCAST_SLACK_PX
	win_l = ex - 1 + 2
	win_r = vw - ex + 2
	win_d = ey - 1 + 2
	win_u = vh - ey + 2
	// put the middle of the (square) triangle icon on the middle of the eye tile
	var/off_x = round(tw / 2 - SHADOWCAST_ICON_SIZE / 2)
	var/off_y = round(th / 2 - SHADOWCAST_ICON_SIZE / 2)
	anchor_loc = "[ex]:[off_x],[ey]:[off_y]"

/// The colour matrix of the mask plane: alpha gain (closes seams) + additive tint.
/datum/shadowcast_view/proc/mask_color()
	var/list/rgb = rgb2num(SHADOWCAST_COLOR)
	return list(1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, SHADOWCAST_SEAM_GAIN,  rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 0)

/// Create the plane master (and the displacement-map object).
/datum/shadowcast_view/proc/build_screen()
	if(master)
		return
	master = new
	master.color = mask_color()
	owner.screen += master
#if SHADOWCAST_DISPLACE_SIZE > 0
	build_displace()
#endif

/// Displacement filter: the mask is warped by a smooth noise map so shadow
/// edges shimmer instead of being razor straight. The map slowly drifts.
/datum/shadowcast_view/proc/build_displace()
	noise = new
	var/map_px = max(vw * tw, vh * th)
	var/scale = max(1, map_px / SHADOWCAST_NOISE_SIZE)
	noise.transform = matrix(scale, 0, 0, 0, scale, 0)
	var/nx = round((vw * tw - SHADOWCAST_NOISE_SIZE) / 2)
	var/ny = round((vh * th - SHADOWCAST_NOISE_SIZE) / 2)
	noise.screen_loc = "1:[nx],1:[ny]"
	owner.screen += noise
	master.filters = filter(type = "displace", render_source = "*shadowcast_noise", size = SHADOWCAST_DISPLACE_SIZE)
#if SHADOWCAST_DISPLACE_DRIFT > 0
	var/filter_ref = master.filters[1]
	animate(filter_ref, x = SHADOWCAST_DISPLACE_DRIFT, time = SHADOWCAST_DISPLACE_DRIFT_TIME, loop = -1, easing = SINE_EASING)
	animate(x = 0, time = SHADOWCAST_DISPLACE_DRIFT_TIME, easing = SINE_EASING)
#endif

/// Take a triangle from the pool (creating one if needed). null = over the cap.
/datum/shadowcast_view/proc/take_tri()
	if(pool.len)
		var/obj/shadowcast_tri/old = pool[pool.len]
		pool.len--
		return old
	if(tri_count >= SHADOWCAST_MAX_TRIS)
		return null
	var/obj/shadowcast_tri/fresh = new
	fresh.screen_loc = anchor_loc
	owner.screen += fresh
	tri_count++
	return fresh

/// Hide a triangle and put it back in the pool.
/datum/shadowcast_view/proc/give_tri(obj/shadowcast_tri/tri)
	animate(tri)
	tri.alpha = 0
	pool += tri

/// Remove every shadow (the screen objects stay, parked in the pool).
/datum/shadowcast_view/proc/clear_all()
	for(var/key in edges)
		var/datum/shadowcast_edge/S = edges[key]
		S.hide()
	edges.Cut()
	dying.Cut()
	for(var/obj/shadowcast_tri/tri in cone)
		give_tri(tri)
	cone.Cut()
	cone_fov = 360
	has_light = 0

/// Remove everything from the client's screen.
/datum/shadowcast_view/proc/teardown()
	if(!owner)
		return
	clear_all()
	for(var/obj/shadowcast_tri/tri in pool)
		owner.screen -= tri
	pool.Cut()
	tri_count = 0
	if(master)
		owner.screen -= master
		master = null
	if(noise)
		owner.screen -= noise
		noise = null

/// Where the shadows are showing right now, assuming the animation we sent is running to plan.
/datum/shadowcast_view/proc/displayed()
	if(dur <= 0)
		return list(to_x, to_y)
	var/f = clamp((world.time - t0) / dur, 0, 1)
	return list(from_x + (to_x - from_x) * f, from_y + (to_y - from_y) * f)

/// How long (deciseconds) the client takes to glide the eye by (dx,dy) pixels.
/datum/shadowcast_view/proc/glide_time(atom/eye, dx, dy)
	var/dist = sqrt(dx * dx + dy * dy)
	var/gs = 0
	if(ismovable(eye))
		var/atom/movable/M = eye
		gs = M.glide_size
		if(M.appearance_flags & LONG_GLIDE)
			dist = max(abs(dx), abs(dy))
	var/ds = SHADOWCAST_DEFAULT_GLIDE_TIME
	if(gs > 0)
		ds = dist / gs * world.tick_lag
	else
		// glide_size 0 = the client picks. Best guess: it takes as long as the last step took.
		var/since = world.time - last_move_time
		if(last_move_time && since > 0 && since <= 10)
			ds = since
	last_move_time = world.time
	return max(ds - lag_ds, world.tick_lag)

/// Finish vanished edges whose animation has run out.
/datum/shadowcast_view/proc/sweep_dying()
	for(var/datum/shadowcast_edge/S in dying.Copy())
		if(world.time >= S.release)
			dying -= S
			if(!S.live)
				S.hide()

/// Called once per server tick.
/datum/shadowcast_view/proc/tick()
	if(!owner)
		return
	if(layout_key != "[owner.view]|[world.icon_size]")
		clear_all()
		if(master)
			teardown()
		build_layout()
	sweep_dying()
	var/atom/eye = owner.eye
	var/turf/T = eye ? shadowcast_turf(eye) : null
	// no eye, or the eye is buried inside a wall: no shadows rather than a black screen
	if(!T || SHADOWCAST_BLOCKS(T))
		if(has_light)
			clear_all()
		return
	build_screen()
	var/lx = (T.x - 1) * tw + tw / 2
	var/ly = (T.y - 1) * th + th / 2
	if(ismovable(eye))
		var/atom/movable/M = eye
		lx += M.step_x + M.shadowcast_offset_x
		ly += M.step_y + M.shadowcast_offset_y
	var/restart = !has_light || T.z != last_z || eye != last_eye
	if(restart)
		clear_all()
		apply(lx, ly, 0, 1, T)
		has_light = 1
		last_eye = eye
		last_z = T.z
		rescan_in = SHADOWCAST_RESCAN_TICKS
	else if(abs(lx - to_x) > 0.01 || abs(ly - to_y) > 0.01)
		var/dx = lx - to_x
		var/dy = ly - to_y
		var/snap = sqrt(dx * dx + dy * dy) > SHADOWCAST_GLIDE_MAX_TILES * tw
		if(ismovable(eye))
			var/atom/movable/M2 = eye
			if(M2.animate_movement == NO_STEPS)
				snap = 1
		apply(lx, ly, snap ? 0 : glide_time(eye, dx, dy), snap, T)
		rescan_in = SHADOWCAST_RESCAN_TICKS
	else if(SHADOWCAST_RESCAN_TICKS > 0 && world.time >= t0 + dur)
		rescan_in--
		if(rescan_in <= 0)
			rescan_in = SHADOWCAST_RESCAN_TICKS
			apply(lx, ly, 0, 1, T)
	update_cone(eye)
