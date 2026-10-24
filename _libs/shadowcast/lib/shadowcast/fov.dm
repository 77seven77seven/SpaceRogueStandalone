// ============================================================================
//  shadowcast / fov.dm
//  Field-of-view cone. The blind part of the cone is 1-4 triangles fanned out
//  from the eye, drawn on the same mask plane as the wall shadows, so the two
//  combine for free. The cone is attached to the eye, so while you walk it
//  needs no animation at all; it only animates when you turn.
//
//  Turn a mob into a flashlight-style viewer:
//      mob.shadowcast_fov = 120        // degrees, 360 = off
//      mob.shadowcast_facing = 45      // optional, degrees; default is mob.dir
// ============================================================================

/datum/shadowcast_view
	var/cone_behind = 16

/// Shortest signed turn from angle a to angle b, in (-180, 180].
/proc/shadowcast_angle_delta(a, b)
	var/d = b - a
	while(d > 180)
		d -= 360
	while(d <= -180)
		d += 360
	return d

/// Make `cone` hold exactly n triangles.
/datum/shadowcast_view/proc/cone_count(n)
	while(cone.len > n)
		var/obj/shadowcast_tri/spare = cone[cone.len]
		cone.len--
		give_tri(spare)
	while(cone.len < n)
		var/obj/shadowcast_tri/fresh = take_tri()
		if(!fresh)
			break
		cone += fresh

/// Follow the eye's fov / facing. Called every tick from tick().
/datum/shadowcast_view/proc/update_cone(atom/eye)
	var/fov = 360
	var/phi = 270
	var/behind = 16
	if(ismovable(eye))
		var/atom/movable/M = eye
		fov = M.shadowcast_fov
		behind = M.shadowcast_fov_behind
		phi = isnull(M.shadowcast_facing) ? shadowcast_dir_angle(M.dir) : M.shadowcast_facing
	if(fov >= 360)
		if(cone.len)
			cone_count(0)
		cone_fov = 360
		return
	// new cone, or its shape changed: snap
	if(!cone.len || fov != cone_fov || behind != cone_behind)
		var/list/fresh_mats = shadowcast_cone_matrices(phi, fov, behind, ext_diag)
		cone_count(fresh_mats.len)
		var/i = 0
		for(var/obj/shadowcast_tri/tri in cone)
			i++
			animate(tri)
			tri.transform = fresh_mats[i]
			tri.alpha = 255
		cone_phi = phi
		cone_fov = fov
		cone_behind = behind
		return
	var/delta = shadowcast_angle_delta(cone_phi, phi)
	if(abs(delta) < 0.5)
		return
	// Linear matrix interpolation shrinks a rotation (it cuts the chord), so turn in
	// slices of at most 20 degrees; the error per slice is a fraction of a percent.
	var/steps = max(1, ceil(abs(delta) / 20))
	var/slice = max(abs(delta) / SHADOWCAST_TURN_SPEED / steps, 0.05)
	var/list/frames = list()
	for(var/k in 1 to steps)
		frames += list(shadowcast_cone_matrices(cone_phi + delta * k / steps, fov, behind, ext_diag))
	var/n = 0
	for(var/obj/shadowcast_tri/wedge in cone)
		n++
		for(var/k2 in 1 to steps)
			var/list/step_mats = frames[k2]
			if(k2 == 1)
				animate(wedge, transform = step_mats[n], time = slice, easing = LINEAR_EASING, flags = ANIMATION_LINEAR_TRANSFORM)
			else
				animate(transform = step_mats[n], time = slice, easing = LINEAR_EASING, flags = ANIMATION_LINEAR_TRANSFORM)
	cone_phi = phi
