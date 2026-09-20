// For handling the visual blood effects that show up when you... well, bleed. Not for the bleeding mechanic. For that, see human.bleeding.dm

/atom/movable/blood
	icon = 'icons/human/blood.dmi'
	mouse_opacity = 2
	layer = TURF_LAYER

/atom/movable/blood/drip/Initialize()
	. = ..()
	icon_state = "drip[rand(1,6)]"
	pixel_x = rand(-5,5)
	pixel_y = rand(-5,5)

	animate(src, 500, alpha = 0)
	addtimer(CALLBACK_GLOBAL(/proc/qdel, src), 500)

/atom/movable/blood/splatter/New(loc, ss)
	. = ..()
	icon_state = "splatter[rand(1,4)]"
	swing_anim(ss, rand(1,5), rand(7,8), rev = TRUE)
	animate(src, 3, pixel_y = rand(-5,5), pixel_x = rand(-5,5))

	animate(src, 500, alpha = 0)
	addtimer(CALLBACK_GLOBAL(/proc/qdel, src), 500)