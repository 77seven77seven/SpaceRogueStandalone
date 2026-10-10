/atom/movable
	glide_size = 8
	appearance_flags = TILE_BOUND|PIXEL_SCALE|LONG_GLIDE
	var/desc_expansive = null
	var/desc_expansive_extra_skill = null

	var/letpassthrow = FALSE

/atom/movable/Click(location, control, params)
	if(!usr || !usr.client)
		return FALSE
	. = ..()
	var/mob/user = usr
	if(istype(user, /mob/lobbyman))
		return
		
	var/list/parms = params2list(params)
	if(parms["shift"])
		src.examine(user)
		return

	if(Adjacent(user))
		if(ishuman(user))
			var/mob/human/H = user
			interact(H, H.holding, params)
		else
			interact(user, params = params)
	else
		if(ishuman(user))
			var/mob/human/H = user
			interact_ranged(H, H.holding, params)
		else
			interact_ranged(user, params = params)
	
/atom/movable/proc/interact(mob/user, obj/item/held_item, params)
	user.face_atom(src)
	return

/atom/movable/proc/interact_ranged(mob/user, obj/item/held_item, params)
	return

/atom/movable/proc/examine(mob/human/user)
	if(!get_examine_text())
		return FALSE
	var/icon/I = getFlatIcon(src)

	user << "\icon[I] <b>[name]</b> — [get_examine_text()]"
	if(desc_expansive)
		var/result = user.SkillRoll(ENCY, TRUE)
		var/skill = "ENCYCLOPEDIA"
		if(!result && desc_expansive_extra_skill)
			result = user.SkillRoll(desc_expansive_extra_skill, TRUE)
			skill = desc_expansive_extra_skill
		if(result)
			user.playsound_local(get_turf(user), 'sound/effects/senses/intelligence.ogg', 100)
			user << "<B>[skill]</b> — [desc_expansive]"

	return TRUE

/atom/movable/proc/get_examine_text()
	return desc

/atom/movable/proc/swing_anim(atom/A, pixelirona = 16, rostra = 15, timera = 2, rev = FALSE)
	if(A == src)
		return //don't do an animation if attacking self

	var/pixel_x_diff = 0
	var/pixel_y_diff = 0
	var/turn_dir = 1

	var/direction = get_dir(src, A)
	if(direction & NORTH)
		pixel_y_diff = pixelirona
		pixel_x_diff = rand(2,8)
		turn_dir = prob(50) ? -1 : 1
	else if(direction & SOUTH)
		pixel_y_diff = -pixelirona
		pixel_x_diff = rand(-2,-8)
		turn_dir = prob(50) ? -1 : 1

	if(direction & EAST)
		pixel_x_diff = pixelirona
		pixel_y_diff = rand(2,8)
	else if(direction & WEST)
		pixel_x_diff = -pixelirona
		pixel_y_diff = rand(-2,-8)
		turn_dir = -1

	var/matrix/initial_transform = matrix(transform)
	var/matrix/rotated_transform = transform.Turn(rostra * turn_dir)
	if(!rev)
		animate(
			src,
			pixel_x = pixel_x + pixel_x_diff,
			pixel_y = pixel_y + pixel_y_diff,
			transform = rotated_transform,
			time = timera,
			easing = CIRCULAR_EASING,
			flags = ANIMATION_PARALLEL
			)
		animate(
			pixel_x = pixel_x - pixel_x_diff,
			pixel_y = pixel_y - pixel_y_diff,
			transform = initial_transform,
			time = timera * 2,
			easing = SINE_EASING,
			flags = ANIMATION_PARALLEL
			)
	else
		animate(
			pixel_x = pixel_x - pixel_x_diff,
			pixel_y = pixel_y - pixel_y_diff,
			transform = initial_transform,
			time = timera,
			easing = SINE_EASING,
			flags = ANIMATION_PARALLEL
			)