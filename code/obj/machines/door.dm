/obj/machine/door
	name = "door"
	desc = "It's a door."
	icon = 'icons/obj/Door1.dmi'
	icon_state = "door"
	vis_flags = VIS_INHERIT_ID

	mouse_opacity = 2

	density = TRUE
	opacity = TRUE

	var/open = FALSE
	var/doing = FALSE

	var/opacita = TRUE

	var/shock_on_deny = FALSE
	var/shock_damage = 5 // 20 denials to kill someone with full health

	var/time = 2

	var/auto_closes = TRUE
	var/auto_opens = FALSE // MUTUALLY EXLCUSIVE, FUCKED UP THINGS HAPPEN IF YOU PAIR THESE TOGETHER!

	var/list/linked_controls = list()

	var/list/access = list() // If the person interacting has ANY OF THESE ACCESS TAGS, they can access the door and open/close it.
							 // This means that you can't make doors that need more than one type of access tag to open. Not yet anyway.

	var/atom/movable/door_l
	var/atom/movable/door_r

	var/atom/movable/whiteout

/obj/machine/door/start_open/Initialize()
	. = ..()
	do_door()

/obj/machine/door/glass
	name = "win-door"
	icon_state = "door_glass"
	opacity = FALSE
	opacita = FALSE

/atom/movable/door_dummy
	icon = 'icons/obj/Door1.dmi'
	mouse_opacity = 0
	layer = TURF_LAYER

/obj/machine/door/Initialize()
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

	whiteout = new(src)
	whiteout.icon = src.icon
	whiteout.mouse_opacity = 0
	whiteout.layer = layer + 0.01
	whiteout.alpha = 0

	vis_contents += whiteout

	filters += filter(type="drop_shadow", x=2, size=2, offset=1)

	spawn()
		for(var/obj/door_control/DCC in range(1, loc))
			if(!(src in DCC.linked_doors))
				DCC.linked_doors += src
			linked_controls += DCC

/obj/machine/door/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	if(!open)
		knock(user)

/obj/machine/door/proc/knock(mob/human/user)
	var/list/all_in_range = orange(world.view, src)
	var/list/those_who_see = oviewers(world.view, src)

	var/list/cant_see = all_in_range - those_who_see

	if(user.on_cooldown("knock"))
		return
	user.cooldown("knock", 1 SECONDS)

	playsound(get_turf(src), 'sound/effects/obj/door_knocking.ogg', vol = 100, ignore_walls = TRUE, vary = TRUE)
	whiteout.icon_state = "knock"
	whiteout.alpha = 150
	animate(whiteout, time = 2 SECONDS, alpha = 0)

	for(var/mob/M in cant_see)
		var/turf/anchor = get_turf(M)
		var/image/I = image('icons/obj/abstract/hud_32.dmi', M, "knocking")
		I.pixel_x = (src.x - anchor.x) * world.icon_size
		I.pixel_y = (src.y - anchor.y) * world.icon_size

		M.client.images += I
		animate(I, time = 2 SECONDS, alpha = 0)
		QDEL_IN(I, 2 SECONDS)

/obj/machine/door/proc/do_door()
	if(doing)
		return FALSE

	var/px = 0
	var/py = 0

	switch(dir)
		if(NORTH, SOUTH)
			px = 24 - rand(-2,2)
		if(WEST, EAST)
			py = 24 - rand(-2,2)

	if(open)
		// closing
		animate(door_l, time, pixel_x = 0, pixel_y = 0, easing = BOUNCE_EASING)
		animate(door_r, time, pixel_x = 0, pixel_y = 0, easing = BOUNCE_EASING)

		door_l.filters += filter(type="motion_blur", x = px / 10, y = py / 10)
		door_r.filters += filter(type="motion_blur", x = px / 10, y = py / 10)

		mouse_opacity = 2
	else
		// opening
		animate(door_l, time, pixel_x = -px, pixel_y = -py, easing = QUAD_EASING)
		animate(door_r, time, pixel_x = px, pixel_y = py, easing = QUAD_EASING)

		mouse_opacity = 0

	doing = TRUE
	if(opacita)
		set_opacity(!opacity)
	spawn(time / 2)
		playsound(get_turf(src), 'sound/effects/obj/door.ogg', 100, TRUE, 1, 4, ignore_walls = TRUE)
		doing = FALSE

		open = !open
		density = !density

		door_l.filters = null
		door_r.filters = null
		if(open && auto_closes)
			addtimer(CALLBACK(src, PROC_REF(auto_close)), 2 MINUTES, TIMER_UNIQUE|TIMER_OVERRIDE)
		if(!open && auto_opens)
			addtimer(CALLBACK(src, PROC_REF(auto_open)), 5 MINUTES, TIMER_UNIQUE|TIMER_OVERRIDE)
	return TRUE

/obj/machine/door/proc/auto_close()
	if(!open || doing)
		return
	if(locate(/mob/human) in get_turf(src))
		addtimer(CALLBACK(src, PROC_REF(auto_close)), 2 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
		playsound(get_turf(src), 'sound/effects/pda/airlock_deny.ogg', 150, ignore_walls = TRUE)
		for(var/obj/door_control/DC in linked_controls)
			flick("[initial(DC.icon_state)]-deny", DC)
		return
	do_door()

/obj/machine/door/proc/auto_open()
	if(open || doing)
		return
	do_door()

/obj/door_control
	name = "door control"
	icon = 'icons/obj/Door1.dmi'
	icon_state = "door_control"
	layer = OBJ_LAYER + 0.2

	var/shuttered = FALSE

	var/list/linked_doors = list()
	var/list/linked_shutters = list()

/obj/door_control/interact(user)
	. = ..()
	if(ishuman(user))
		var/mob/human/H = user
		if(!linked_doors.len && !linked_shutters.len)
			return FALSE
		for(var/obj/machine/door/D in linked_doors)
			if(D.doing)
				H.chat_pda("DOOR BUSY!", "bad")
				flick("[initial(icon_state)]-deny",src)
				return FALSE
			if(locate(/mob/human) in get_turf(D))
				H.chat_pda("DOOR BLOCKED!", "bad")
				flick("[initial(icon_state)]-deny",src)
				playsound(get_turf(src), 'sound/effects/pda/airlock_deny.ogg', 150, ignore_walls = TRUE)
				return FALSE

		for(var/obj/machine/shutter/S in linked_shutters)
			if(S.doing)
				H.chat_pda("SHUTTER BUSY!", "bad")
				flick("[initial(icon_state)]-deny",src)
				return FALSE
			if(locate(/mob/human) in get_turf(S))
				H.chat_pda("SHUTTER BLOCKED!", "bad")
				flick("[initial(icon_state)]-deny",src)
				playsound(get_turf(src), 'sound/effects/pda/airlock_deny.ogg', 150, ignore_walls = TRUE)
				return FALSE

		for(var/obj/machine/door/D in linked_doors)
			if(D.access.len && !find_common_entry(H.mind?.current_job?.access, D.access) && !H.mind?.current_job?.access.Find("EVERYTHING"))
				flick("[initial(icon_state)]-deny",src)
				H.chat_pda("ACCESS DENIED", "bad")
				playsound(get_turf(src), 'sound/effects/pda/airlock_deny.ogg', 150, ignore_walls = TRUE)
				if(D.shock_on_deny)
					H.TakeDamage(D.shock_damage, "access denial shock")

					var/amplitude = min(4, (D.shock_damage/100) + 1)
					var/pixel_x_diff = rand(-amplitude, amplitude)
					var/pixel_y_diff = rand(-amplitude/3, amplitude/3)
					animate(H, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = amplitude / 3, loop = 6, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
					animate(pixel_x = -pixel_x_diff , pixel_y = -pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE)
				return FALSE

		flick("[initial(icon_state)]-allow",src)
		playsound(get_turf(src), 'sound/effects/pda/airlock_grant.ogg', 150, ignore_walls = TRUE)
		H.chat_pda("ACCESS GRANTED", "good")
		var/should_open = FALSE
		for(var/obj/machine/door/D in linked_doors)
			if(!D.open)
				should_open = TRUE
		for(var/obj/machine/shutter/S in linked_shutters)
			if(!S.open)
				should_open = TRUE
		for(var/obj/machine/door/D in linked_doors)
			if(D.open != should_open)
				D.do_door()
		for(var/obj/machine/shutter/S in linked_shutters)
			if(S.open != should_open)
				S.do_door()

/obj/machine/shutter
	name = "shutter"
	desc = "A heavy shutter. Singular."
	icon = 'icons/obj/Door1.dmi'
	icon_state = "shutter"
	vis_flags = VIS_INHERIT_ID
	appearance_flags = KEEP_TOGETHER

	mouse_opacity = 2

	density = TRUE
	opacity = TRUE

	var/open = FALSE
	var/opacita = TRUE
	var/time = 2

	var/atom/movable/door
	var/atom/movable/indicator
	var/doing = FALSE

/obj/machine/shutter/Initialize()
	. = ..()
	icon_state = null

	overlays += icon(icon, "shutter-frame")

	var/atom/movable/door = new()
	door.icon = src.icon
	door.icon_state = "shutter-door"
	door.appearance_flags = KEEP_TOGETHER
	door.filters += filter(type="alpha", icon = icon('icons/obj/abstract/effects.dmi', "tilemask"))
	filters += filter(type="alpha", icon = icon('icons/obj/abstract/effects.dmi', "tilemask"))

	src.door = door
	vis_contents += door

	indicator = new(src)
	indicator.icon = src.icon
	indicator.icon_state = "shutter-indicator"
	indicator.mouse_opacity = 0
	indicator.layer = layer + 0.01

	indicator.color = "#FF0033"

	vis_contents += indicator

	filters += filter(type="drop_shadow", x=2, size=2, offset=1)

	spawn()
		for(var/obj/door_control/DCC in range(1, loc))
			if(DCC.shuttered && !(src in DCC.linked_shutters))
				DCC.linked_shutters += src

/obj/machine/shutter/proc/do_door()
	if(doing)
		return FALSE

	var/py = 0
	py = 62 - rand(-2,2)

	if(open)
		// closing
		animate(door, time, pixel_x = 0, pixel_y = 0, easing = BOUNCE_EASING, flags = ANIMATION_PARALLEL)
		animate(indicator, time, color = "#FF0033")
		mouse_opacity = 2
	else
		// opening
		animate(door, time, pixel_y = py, easing = QUAD_EASING, flags = ANIMATION_PARALLEL)
		animate(indicator, time, color = "#00FF00")
		mouse_opacity = 0

	doing = TRUE
	spawn(time / 2)
		playsound(get_turf(src), 'sound/effects/obj/door.ogg', 100, TRUE, 1, 4, ignore_walls = TRUE)
	spawn(time)
		open = !open
		density = !density
		if(opacita)
			set_opacity(!opacity)
		doing = FALSE
	return TRUE