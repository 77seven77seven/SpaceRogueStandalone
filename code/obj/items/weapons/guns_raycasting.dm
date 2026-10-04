// ------------------------------------------------------------
//  Hit zones
//  A zone is list(x, y, width, height) in pixels, measured from the
//  bottom-left corner of the atom's ICON. Tune these to your sprites.
// ------------------------------------------------------------

/atom/movable/proc/GetHitZones()
	// Default: the whole bounding box is one "body" zone (crates, etc.)
	return list("body" = list(bound_x, bound_y, bound_width, bound_height))

/mob/human
	var/list/head_box = list(20, 40, 24, 24)
	var/list/body_box = list(12, 0, 40, 40)

/mob/human/GetHitZones()
	return list("head" = head_box, "body" = body_box)

/atom/movable/proc/GetHitZoneAt(icon_x, icon_y)
	var/list/zones = GetHitZones()
	for(var/zone_name in zones)
		var/list/box = zones[zone_name]
		if(icon_x >= box[1] && icon_x < box[1] + box[3] && icon_y >= box[2] && icon_y < box[2] + box[4])
			return zone_name

/obj/tracer // visual only
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