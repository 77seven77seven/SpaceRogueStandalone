/atom
	plane = GENERIC_PLANE
	
	// lighting
	var/light_power = 1 // intensity of the light
	var/light_range = 0 // range in tiles of the light
	var/light_color     // RGB string representing the colour of the light

	var/datum/light_source/light
	var/list/light_sources

/atom/New(loc)
	. = ..()
	spawn()
		Initialize()

/atom/proc/Initialize()
	return

/atom/movable/New()
	..()
	if(light_power && light_range)
		update_light()

/atom/movable/Destroy(force)
	if(light)
		light.destroy()
		light = null
	var/turf/T = loc
	if(opacity && istype(T))
		T.reconsider_lights()

	loc = null
	vis_contents?.Cut()

	return ..()

/atom/MouseDrop(atom/over, src_location, over_location, src_control, over_control, params)
	if(!usr || !over)
		return
	if(!Adjacent(usr) || !over.Adjacent(usr))
		return // should stop you from dragging through windows
	var/list/L = params2list(params)
	if (L["middle"])
		over.MiddleMouseDrop_T(src,usr)
	else
		if(over == src)
			return usr.client.Click(src, src_location, src_control, params)
		over.MouseDrop_T(src,usr)
	return

// receive a mousedrop
/atom/proc/MouseDrop_T(atom/dropping, mob/user)
	return

/atom/proc/MiddleMouseDrop_T(atom/dropping, mob/user)
	return

/*
/atom/movable/Click(location, control, params)
	. = ..()
	if(control == "infowindow.info")
		return
	world << "---"
	world << "[name]"
	world << "[layer]"
	world << "[plane]"
	if(screen_loc)
		world << "[screen_loc]"
	world << "---"
*/

/atom/movable/proc/forceMove(atom/destination)
	. = FALSE
	if(destination)
		. = doMove(destination)

/atom/movable/proc/Moved(atom/oldLoc, Dir, Forced = FALSE)	
	update_light()
	if(light_sources)
		for(var/datum/light_source/L in light_sources)
			if(L.source_atom != src)
				L.update(src)
	return TRUE

/atom/movable/proc/doMove(atom/destination)
	. = FALSE
	if(destination)
		var/atom/oldloc = loc
		var/same_loc = oldloc == destination
		var/area/old_area = get_area(oldloc)
		var/area/destarea = get_area(destination)

		loc = destination
		//moving_diagonally = 0

		if(!same_loc)
			if(oldloc)
				oldloc.Exited(src, destination)
				if(old_area && old_area != destarea)
					old_area.Exited(src, destination)
			for(var/atom/movable/AM in oldloc)
				AM.Uncrossed(src)

			destination.Entered(src, oldloc)
			if(destarea && old_area != destarea)
				destarea.Entered(src, oldloc)

			for(var/atom/movable/AM in destination)
				if(AM == src)
					continue
				AM.Crossed(src, oldloc)

		Moved(oldloc, NONE, TRUE)
		. = TRUE

	//If no destination, move the atom into nullspace (don't do this unless you know what you're doing)
	else
		. = TRUE
		if (loc)
			var/atom/oldloc = loc
			var/area/old_area = get_area(oldloc)
			oldloc.Exited(src, null)
			if(old_area)
				old_area.Exited(src, null)
		loc = null