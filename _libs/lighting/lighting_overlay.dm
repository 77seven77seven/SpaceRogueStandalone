/proc/create_lighting_overlays()
	for(var/turf/T in world)
		if(!T.dynamic_lighting || !T.loc || !T.loc.lighting_use_dynamic)
			continue
		if(!T.lighting_overlay)
			var/atom/movable/lighting_overlay/O = PoolOrNew(/atom/movable/lighting_overlay, T)
			T.lighting_overlay = O

// client control of lighting plane
/atom/movable/lighting_master
	screen_loc = "1,1"
	appearance_flags = PLANE_MASTER
	plane = LIGHT_PLANE
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = 0

/atom/movable/lighting_overlay
	name = ""
	mouse_opacity = 0
	//simulated = 0 // ?
	alpha = 0 // start out transparent until the lighting process can get around to updating us (makes pregame map more usable)

	icon = '_libs/lighting/lighting_overlay.dmi'
	icon_state = "light1"
	layer = LIGHTING_LAYER
	plane = LIGHT_PLANE
	color = "#000000"

	var/lum_r
	var/lum_g
	var/lum_b

	var/needs_update = 0

/atom/movable/lighting_overlay/New()
	. = ..()
	verbs.Cut() // dont want these to pop up on the right click menu for admins

	// it appears to be smarter to schedule all of these for updating rather than assuming its initially 'black'
	// this is nice for early game start testing but also it appears that assuming an overlay didn't necessarily need to be updated on game start was breaking things anyways
	needs_update = 1
	lighting_controller.lighting_update_overlays += src

/atom/movable/lighting_overlay/proc/update_lumcount(delta_r, delta_g, delta_b)
	if(!delta_r && !delta_g && !delta_b) //Nothing is being changed all together.
		return

	var/should_update = 0

	if(!needs_update) //If this isn't true, we're already updating anyways.
		if(max(lum_r, lum_g, lum_b) < 1) //Any change that could happen WILL change appearance.
			should_update = 1

		else if(max(lum_r + delta_r, lum_g + delta_g, lum_b + delta_b) < 1) //The change would bring us under 1 max lum, again, guaranteed to change appearance.
			should_update = 1

		else //We need to make sure that the colour ratios won't change in this code block.
			var/mx1 = max(lum_r, lum_g, lum_b)
			var/mx2 = max(lum_r + delta_r, lum_g + delta_g, lum_b + delta_b)

			if(lum_r / mx1 != (lum_r + delta_r) / mx2 || lum_g / mx1 != (lum_g + delta_g) / mx2 || lum_b / mx1 != (lum_b + delta_b) / mx2) //Stuff would change.
				should_update = 1

	lum_r += delta_r
	lum_g += delta_g
	lum_b += delta_b

	if(!needs_update && should_update)
		needs_update = 1
		lighting_controller.lighting_update_overlays += src

/atom/movable/lighting_overlay/proc/update_overlay()
	var/turf/T = loc

	if(istype(T)) //Incase we're not on a turf, pool ourselves, something happened.
		alpha = 255
		var/mx = max(lum_r, lum_g, lum_b)
		if (mx < 0.01)
			//No light, set the turf's luminosity to 0 to remove it from view()
			color = rgb(0,0,0)
			T.luminosity = 0
		else if (mx > 1)
			// range down to let the dominant color dominate
			var/factor = 1/mx
			color = rgb(lum_r * 255 * factor, lum_g * 255 * factor, lum_b * 255 * factor)
			T.luminosity = 1
		else
			color = rgb(lum_r * 255, lum_g * 255, lum_b * 255)
			T.luminosity = 1

	else
		world.log << "A lighting overlay realised its loc was NOT a turf (actual loc: [loc][loc ? ", " + loc.type : ""]) in update_overlay() and got pooled!"
		qdel(src)

/atom/movable/lighting_overlay/ResetVars()
	loc = null

	lum_r = 0
	lum_g = 0
	lum_b = 0

	color = "#000000"

	needs_update = 0

/atom/movable/lighting_overlay/Destroy()
	lighting_controller.lighting_update_overlays -= src

	var/turf/T = loc
	if(istype(T))
		T.lighting_overlay = null

	..()
