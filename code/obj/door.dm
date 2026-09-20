/obj/solid
	density = TRUE
	opacity = TRUE

/obj/solid/door
	name = "door"
	desc = "It's a door."
	icon = 'icons/obj/Door1.dmi'
	icon_state = "door"
	vis_flags = VIS_INHERIT_ID

	var/open = FALSE
	var/doing = FALSE

	var/opacita = TRUE

	var/shock_on_deny = FALSE
	var/shock_damage = 5 // 20 denials to kill someone with full health

	var/time = 2

	var/list/access = list() // If the person interacting has ANY OF THESE ACCESS TAGS, they can access the door and open/close it.
							 // This means that you can't make doors that need more than one type of access tag to open. Not yet anyway.

	var/atom/movable/door_l
	var/atom/movable/door_r

/obj/solid/door/glass
	name = "win-door"
	icon_state = "door_glass"
	opacity = FALSE
	opacita = FALSE

/atom/movable/door_dummy
	icon = 'icons/obj/Door1.dmi'
	mouse_opacity = 2
	layer = TURF_LAYER

/obj/solid/door/Initialize()
	. = ..()
	icon_state = null

	var/atom/movable/door_dummy/l_door = new()
	var/atom/movable/door_dummy/r_door = new()
	l_door.icon_state = "[initial(icon_state)]_l"
	l_door.dir = dir

	r_door.icon_state = "[initial(icon_state)]_r"
	r_door.dir = dir

	door_l = l_door
	door_r = r_door

	vis_contents += door_l
	vis_contents += door_r

	filters += filter(type="drop_shadow", x=2, size=2, offset=1)

	spawn()
		for(var/obj/DC in range(1, loc))
			if(istype(DC, /obj/door_control))
				var/obj/door_control/DCC = DC
				DCC.linked_door = src
				break

/obj/solid/door/proc/do_door()
	if(doing)
		return FALSE

	var/px = 0
	var/py = 0

	switch(dir)
		if(NORTH, SOUTH)
			px = 12 - rand(-2,2)
		if(WEST, EAST)
			py = 12 - rand(-2,2)

	if(open)
		// closing
		animate(door_l, time, pixel_x = 0, pixel_y = 0, easing = BOUNCE_EASING)
		animate(door_r, time, pixel_x = 0, pixel_y = 0, easing = BOUNCE_EASING)

		door_l.filters += filter(type="motion_blur", x = px / 10, y = py / 10)
		door_r.filters += filter(type="motion_blur", x = px / 10, y = py / 10)
	else
		// opening
		animate(door_l, time, pixel_x = -px, pixel_y = -py, easing = QUAD_EASING)
		animate(door_r, time, pixel_x = px, pixel_y = py, easing = QUAD_EASING)
	playsound('sound/effects/obj/door.ogg', get_turf(src))

	doing = TRUE
	if(opacita)
		opacity = !opacity
	spawn(time / 2)
		doing = FALSE

		open = !open
		density = !density

		door_l.filters = null
		door_r.filters = null
	return TRUE

/obj/door_control
	name = "door control"
	icon = 'icons/obj/Door1.dmi'
	icon_state = "door_control"
	layer = OBJ_LAYER + 0.2
	var/obj/solid/door/linked_door

/obj/door_control/interact(user)
	. = ..()
	if(ishuman(user))
		var/mob/human/H = user
		if(linked_door)
			if(linked_door.doing)
				H.chat_pda("DOOR BUSY!", "bad")
				return FALSE
			if(!linked_door.access.len || (find_common_entry(H.mind?.current_job?.access, linked_door.access) || H.mind?.current_job?.access.Find("EVERYTHING")))
				flick("[initial(icon_state)]-allow",src)
				playsound('sound/effects/pda/airlock_grant.ogg', get_turf(src))

				H.chat_pda("ACCESS GRANTED", "good")
				linked_door.do_door()
			else
				flick("[initial(icon_state)]-deny",src)
				H.chat_pda("ACCESS DENIED", "bad")
				playsound('sound/effects/pda/airlock_deny.ogg', get_turf(src))
				if(linked_door.shock_on_deny)
					H.TakeDamage(linked_door.shock_damage, "access denial shock")

					var/amplitude = min(4, (linked_door.shock_damage/100) + 1)
					var/pixel_x_diff = rand(-amplitude, amplitude)
					var/pixel_y_diff = rand(-amplitude/3, amplitude/3)
					animate(H, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = amplitude / 3, loop = 6, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
					animate(pixel_x = -pixel_x_diff , pixel_y = -pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE)