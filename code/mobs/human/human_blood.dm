// For handling the visual blood effects that show up when you... well, bleed. Not for the bleeding mechanic. For that, see human.bleeding.dm

/atom/movable/blood
	icon = 'icons/human/blood.dmi'
	mouse_opacity = 0
	layer = TURF_LAYER

/atom/movable/blood/drip/Initialize()
	. = ..()
	icon_state = "drip[rand(1,4)]"
	pixel_x = rand(-10,10)
	pixel_y = rand(-10,10)

	animate(src, 2 MINUTES, alpha = 0)
	QDEL_IN(src, 2 MINUTES)

/atom/movable/blood/splatter/New(loc, ss)
	. = ..()
	icon_state = "splatter[rand(1,4)]"
	swing_anim(ss, rand(1,5), rand(7,8), rev = TRUE)

	animate(src, 2 MINUTES, alpha = 0)
	QDEL_IN(src, 2 MINUTES)