// ============================================================================
//  shadowcast / edges.dm
//  Turns "the light moves from D to L" into animate() calls.
//
//  For every exposed tile face we know its facing at the start (D, where the
//  shadows are showing right now) and at the end (L):
//    back-facing at both   -> STABLE : glide matrix M(D) -> M(L)
//    back -> front         -> VANISH : glide M(D) -> M(crossing), then hide.
//                             The quad has zero area exactly where the light
//                             crosses the face's line, so nothing pops.
//    front -> back         -> APPEAR : wait hidden until the crossing, then
//                             glide M(crossing) -> M(L).
//    front at both         -> nothing.
//  Matrices are affine in the light position, so linear interpolation between
//  them is exact (see geometry.dm and tools/verify.py).
// ============================================================================

/// One triangle's slice of a glide: linear matrix interpolation over `time`.
/datum/shadowcast_view/proc/glide_tri(obj/shadowcast_tri/tri, matrix/tlo, time)
	animate(tri, transform = tlo, time = time, easing = LINEAR_EASING, flags = ANIMATION_LINEAR_TRANSFORM)

/// Glide to M(L) and stay.
/datum/shadowcast_view/proc/glide_edge(datum/shadowcast_edge/S, list/mats, time)
	glide_tri(S.t1, mats[1], time)
	glide_tri(S.t2, mats[2], time)
	S.live = 1

/// Glide to the zero-area crossing shape over `to_cross`, then switch off.
/datum/shadowcast_view/proc/vanish_edge(datum/shadowcast_edge/S, list/crossing, to_cross, time)
	var/i = 0
	for(var/obj/shadowcast_tri/tri in list(S.t1, S.t2))
		i++
		glide_tri(tri, crossing[i], max(to_cross, 0.01))
		animate(alpha = 0, time = max(world.tick_lag, 0.01), easing = JUMP_EASING | EASE_IN)
	S.live = 0
	S.release = world.time + time + world.tick_lag * 2
	dying |= S

/// Stay hidden until the crossing, then appear and glide to M(L).
/datum/shadowcast_view/proc/appear_edge(datum/shadowcast_edge/S, list/mats, wait, time)
	var/i = 0
	for(var/obj/shadowcast_tri/tri in list(S.t1, S.t2))
		i++
		animate(tri, alpha = 255, time = max(wait, 0.01), easing = JUMP_EASING)
		animate(transform = mats[i], time = max(time - wait, 0.01), easing = LINEAR_EASING, flags = ANIMATION_LINEAR_TRANSFORM)
	S.live = 1
	dying -= S

/// The two matrices for one scanned edge `E` lit from (lx,ly) with extrusion m.
/datum/shadowcast_view/proc/edge_mats(list/E, lx, ly, m)
	return shadowcast_quad_matrices(E[2], E[3], E[4], E[5], E[6], E[7], lx, ly, m)

/// Bring the shadows to a light at (nx,ny), standing in turf T.
/// time = deciseconds the glide takes; instant = snap without animating.
/datum/shadowcast_view/proc/apply(nx, ny, time, instant, turf/T)
	// where the shadows are showing right now
	var/ox = nx
	var/oy = ny
	if(!instant)
		var/list/d = displayed()
		ox = d[1]
		oy = d[2]
	var/list/found = shadowcast_scan(T.x, T.y, T.z, win_l, win_r, win_d, win_u, tw, th)
	serial++
	for(var/list/E in found)
		var/key = E[1]
		var/s0 = shadowcast_side(E[2], E[3], E[6], E[7], ox, oy)
		var/s1 = shadowcast_side(E[2], E[3], E[6], E[7], nx, ny)
		var/b0 = s0 < 0
		var/b1 = s1 < 0
		var/datum/shadowcast_edge/S = edges[key]
		if(!b0 && !b1)
			// the light sees this face: no shadow
			if(S)
				S.stamp = serial
				if(S.live)
					S.hide()
				if(!S.t1)
					edges -= key
			continue
		if(!S)
			S = new
			S.view = src
			edges[key] = S
		S.stamp = serial
		var/h = 999999
		if(b0)
			h = min(h, -s0)
		if(b1)
			h = min(h, -s1)
		var/m = shadowcast_pick_m(h, ext)
		if(!S.claim())
			continue
		if(b0 && b1)
			if(instant)
				S.place(edge_mats(E, nx, ny, m), m, 1)
				continue
			if(!S.live || S.m != m)
				S.place(edge_mats(E, ox, oy, m), m, 1)
			glide_edge(S, edge_mats(E, nx, ny, m), time)
			continue
		var/tc = shadowcast_cross_t(s0, s1)
		var/cx = ox + (nx - ox) * tc
		var/cy = oy + (ny - oy) * tc
		if(b0)
			if(!S.live || S.m != m)
				S.place(edge_mats(E, ox, oy, m), m, 1)
			vanish_edge(S, edge_mats(E, cx, cy, m), tc * time, time)
		else
			S.place(edge_mats(E, cx, cy, m), m, 0)
			appear_edge(S, edge_mats(E, nx, ny, m), tc * time, time)
	// faces that left the window or stopped blocking light
	var/list/gone = list()
	for(var/key2 in edges)
		var/datum/shadowcast_edge/G = edges[key2]
		if(G.stamp != serial)
			gone += key2
	for(var/key3 in gone)
		var/datum/shadowcast_edge/G2 = edges[key3]
		dying -= G2
		G2.hide()
		edges -= key3
	from_x = ox
	from_y = oy
	to_x = nx
	to_y = ny
	t0 = world.time
	dur = instant ? 0 : time
