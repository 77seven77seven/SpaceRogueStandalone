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

	var/shock_on_deny = FALSE
	var/shock_damage = 5 // 20 denials to kill someone with full health

	var/time = 2

	var/list/access = list() // If the person interacting has ANY OF THESE ACCESS TAGS, they can access the door and open/close it.
							 // This means that you can't make doors that need more than one type of access tag to open. Not yet anyway.

	var/atom/movable/door_l
	var/atom/movable/door_r

/atom/movable/door_dummy
	icon = 'icons/obj/Door1.dmi'
	mouse_opacity = 2

/obj/solid/door/Initialize()
	. = ..()
	icon_state = null

	var/atom/movable/door_dummy/l_door = new()
	var/atom/movable/door_dummy/r_door = new()
	l_door.icon_state = "[initial(icon_state)]_l"
	r_door.icon_state = "[initial(icon_state)]_r"

	door_l = l_door
	door_r = r_door

	vis_contents += door_l
	vis_contents += door_r

	spawn()
		for(var/obj/DC in range(1, loc))
			if(istype(DC, /obj/door_control))
				var/obj/door_control/DCC = DC
				DCC.linked_door = src
				break

/obj/solid/door/proc/do_door()
	if(doing)
		// DOOR BUSY!
		return FALSE
	if(open)
		// closing
		animate(door_l, time, pixel_x = 0, easing = BOUNCE_EASING)
		animate(door_r, time, pixel_x = 0, easing = BOUNCE_EASING)
	else
		// opening
		animate(door_l, time, pixel_x = -12 - rand(-2,2), easing = QUAD_EASING)
		animate(door_r, time, pixel_x = 12 - rand(-2,2), easing = QUAD_EASING)
	doing = TRUE
	opacity = !opacity
	spawn(time / 2)
		doing = FALSE

		open = !open
		density = !density
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
			if(!linked_door.access.len || (find_common_entry(H.mind?.current_job?.access, linked_door.access) || H.mind?.current_job?.access.Find("EVERYTHING")))
				flick("[initial(icon_state)]-allow",src)
				linked_door.do_door()
			else
				flick("[initial(icon_state)]-deny",src)
				if(linked_door.shock_on_deny)
					flick("[initial(icon_state)]-deny",src) // temp
					H.TakeDamage(linked_door.shock_damage, "access denial shock")