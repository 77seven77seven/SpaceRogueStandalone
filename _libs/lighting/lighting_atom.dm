/atom/proc/set_light(l_range, l_power, l_color)
	if(l_power != null) light_power = l_power
	if(l_range != null) light_range = l_range
	if(l_color != null) light_color = l_color

	update_light()

/atom/proc/update_light()
	if(light_power <= 0 || light_range <= 0)
		if(light)
			light.destroy()
			light = null
	else
		if(!istype(loc, /atom/movable))
			. = src
		else
			. = loc

		if (light)
			light.update(.)
		else
			light = new /datum/light_source(src, .)

/atom/proc/set_opacity(new_opacity)
	var/old_opacity = opacity
	opacity = new_opacity
	var/turf/T = get_step(src, 0)
	if(old_opacity != new_opacity && istype(T))
		T.reconsider_lights()