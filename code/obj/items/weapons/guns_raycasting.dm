#define RAY_INF 1e30

// ------------------------------------------------------------
//  Raycast result
// ------------------------------------------------------------
/datum/ray_hit
	var/atom/target       // what was hit (null = nothing / max range / map edge)
	var/zone              // zone name on the target: "head", "body", ...
	var/dist = 0          // distance travelled, in pixels

// ------------------------------------------------------------
//  Hit zones
//  A zone is list(x, y, width, height) in pixels, measured from the
//  bottom-left corner of the atom's ICON. Tune these to your sprites.
// ------------------------------------------------------------
/atom/movable/proc/GetHitZones()
	// Default: the whole bounding box is one "body" zone (crates, etc.)
	return list("body" = list(bound_x, bound_y, bound_width, bound_height))

/mob/human
	var/list/head_box = list(20, 40, 24, 24)   // top 12px of a 32x32 sprite
	var/list/body_box = list(12, 0, 40, 40)

/mob/human/GetHitZones()
	// Swap boxes here if your head moves with facing / lying down / etc.
	return list("head" = head_box, "body" = body_box)

// ------------------------------------------------------------
//  Ray vs. axis-aligned box (slab method).
//  Returns distance along the ray where it enters the box, or -1.
// ------------------------------------------------------------
/proc/RayBoxIntersect(ox, oy, dx, dy, x1, y1, x2, y2, max_dist)
	var/t_near = 0
	var/t_far = max_dist
	var/t1
	var/t2
	var/swap

	if(dx == 0)
		if(ox < x1 || ox > x2)
			return -1
	else
		t1 = (x1 - ox) / dx
		t2 = (x2 - ox) / dx
		if(t1 > t2)
			swap = t1
			t1 = t2
			t2 = swap
		t_near = max(t_near, t1)
		t_far = min(t_far, t2)
		if(t_near > t_far)
			return -1

	if(dy == 0)
		if(oy < y1 || oy > y2)
			return -1
	else
		t1 = (y1 - oy) / dy
		t2 = (y2 - oy) / dy
		if(t1 > t2)
			swap = t1
			t1 = t2
			t2 = swap
		t_near = max(t_near, t1)
		t_far = min(t_far, t2)
		if(t_near > t_far)
			return -1

	return t_near

// ------------------------------------------------------------
//  Pixel raycast.
//  ox, oy      origin in WORLD pixels ((x-1)*WORLD_ICON_SIZE style)
//  dx, dy      UNIT direction vector
//  max_dist    in pixels
//  ignore      atom to skip (the shooter)
//  Walks tile-by-tile (Amanatides & Woo DDA), then tests the exact
//  hit zone boxes of every dense movable in each tile it crosses.
// ------------------------------------------------------------
/proc/PixelRaycast(ox, oy, z, dx, dy, max_dist, atom/ignore)
	var/datum/ray_hit/result = new

	var/tx = floor(ox / WORLD_ICON_SIZE) + 1
	var/ty = floor(oy / WORLD_ICON_SIZE) + 1
	var/step_tx = 0
	var/step_ty = 0
	var/t_max_x = RAY_INF
	var/t_max_y = RAY_INF
	var/t_delta_x = RAY_INF
	var/t_delta_y = RAY_INF

	if(dx > 0)
		step_tx = 1
		t_max_x = (tx * WORLD_ICON_SIZE - ox) / dx
		t_delta_x = WORLD_ICON_SIZE / dx
	else if(dx < 0)
		step_tx = -1
		t_max_x = ((tx - 1) * WORLD_ICON_SIZE - ox) / dx
		t_delta_x = -WORLD_ICON_SIZE / dx

	if(dy > 0)
		step_ty = 1
		t_max_y = (ty * WORLD_ICON_SIZE - oy) / dy
		t_delta_y = WORLD_ICON_SIZE / dy
	else if(dy < 0)
		step_ty = -1
		t_max_y = ((ty - 1) * WORLD_ICON_SIZE - oy) / dy
		t_delta_y = -WORLD_ICON_SIZE / dy

	var/t_enter = 0
	while(t_enter < max_dist)
		var/turf/T = locate(tx, ty, z)
		if(!T)
			break   // left the map

		// Solid turf: stop where the ray enters it
		if(T.density)
			result.target = T
			result.dist = t_enter
			return result

		// Nearest hit zone among everything dense in this tile
		var/t_exit = min(t_max_x, t_max_y)
		var/best_t = RAY_INF
		var/atom/best_atom
		var/best_zone

		for(var/atom/movable/AM in T)
			if(AM == ignore || !AM.density)
				continue
			var/bx = (AM.x - 1) * WORLD_ICON_SIZE + AM.step_x
			var/by = (AM.y - 1) * WORLD_ICON_SIZE + AM.step_y
			var/list/zones = AM.GetHitZones()
			for(var/zone_name in zones)
				var/list/box = zones[zone_name]
				var/t_hit = RayBoxIntersect(ox, oy, dx, dy, bx + box[1], by + box[2], bx + box[1] + box[3], by + box[2] + box[4], max_dist)
				if(t_hit >= 0 && t_hit <= t_exit + 0.001 && t_hit < best_t)
					best_t = t_hit
					best_atom = AM
					best_zone = zone_name

		if(best_atom)
			result.target = best_atom
			result.zone = best_zone
			result.dist = best_t
			return result

		// Step into the next tile
		if(t_max_x < t_max_y)
			tx += step_tx
			t_enter = t_max_x
			t_max_x += t_delta_x
		else
			ty += step_ty
			t_enter = t_max_y
			t_max_y += t_delta_y

	result.dist = min(t_enter, max_dist)
	return result

// ------------------------------------------------------------
//  Visual-only bullet tracer (the raycast itself is instant)
//  Give it a sprite that points NORTH; it gets rotated to the shot angle.
// ------------------------------------------------------------
/obj/tracer
	density = 0
	mouse_opacity = 0
	layer = FLY_LAYER
	icon = 'icons/obj/abstract/effects.dmi'
	icon_state = "tracer"
	var/speed = 1600            // pixels per decisecond

/obj/tracer/New(turf/start, x0, y0, x1, y1)
	..(start)
	var/base_x = (x - 1) * WORLD_ICON_SIZE + WORLD_ICON_SIZE / 2   // world px of this turf's centre
	var/base_y = (y - 1) * WORLD_ICON_SIZE + WORLD_ICON_SIZE / 2
	var/dx = x1 - x0
	var/dy = y1 - y0
	var/len = sqrt(dx * dx + dy * dy)
	if(len < 1)
		del(src)
		return

	var/angle = arccos(max(-1, min(1, dy / len)))
	if(dx < 0)
		angle = 360 - angle
	transform = turn(matrix(), angle)

	pixel_x = x0 - base_x
	pixel_y = y0 - base_y
	var/travel_time = max(1, ceil(len / speed))
	animate(src, pixel_x = x1 - base_x, pixel_y = y1 - base_y, time = travel_time, easing = LINEAR_EASING)
	spawn(travel_time + 1)
		del(src)