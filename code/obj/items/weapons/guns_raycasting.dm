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