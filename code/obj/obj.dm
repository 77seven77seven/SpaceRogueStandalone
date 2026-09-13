/atom/movable/Click(location, control, params)
	if(!usr || !usr.client)
		return FALSE
	. = ..()
	var/mob/user = usr

	if(Adjacent(user))
		if(ishuman(user))
			var/mob/human/H = user
			interact(H, H.holding)
		else
			interact(user)
	
/atom/movable/proc/interact(mob/user, obj/item/held_item)
	return

/atom/movable/proc/swing_anim(atom/A, pixelirona = 16, rostra = 15, timera = 2)
	if(A == src)
		return //don't do an animation if attacking self

	var/pixel_x_diff = 0
	var/pixel_y_diff = 0
	var/turn_dir = 1

	var/direction = get_dir(src, A)
	if(direction & NORTH)
		pixel_y_diff = pixelirona
		pixel_x_diff = rand(1,4)
		turn_dir = prob(50) ? -1 : 1
	else if(direction & SOUTH)
		pixel_y_diff = -pixelirona
		pixel_x_diff = rand(-1,-4)
		turn_dir = prob(50) ? -1 : 1

	if(direction & EAST)
		pixel_x_diff = pixelirona
		pixel_y_diff = rand(1,4)
	else if(direction & WEST)
		pixel_x_diff = -pixelirona
		pixel_y_diff = rand(-1,-4)
		turn_dir = -1

	var/matrix/initial_transform = matrix(transform)
	var/matrix/rotated_transform = transform.Turn(rostra * turn_dir)
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