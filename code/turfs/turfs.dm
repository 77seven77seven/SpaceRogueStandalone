// manage

/turf
	var/base_icon_state = "rwall"

/turf/Initialize()
	..()

	// give all non-dense turfs a 47-state autojoining shadow.
	if(!density)
		var/n = autojoin47("density")
		var/icon/shadow = icon('icons/turf/autojoin/shadows.dmi', "[n]")
		overlays += shadow

	// give all dense turfs a 16-state autojoining outline.
	else
		var/n = autojoin16("density")
		icon_state = "[base_icon_state][n]"

// solid

/turf/solid
	density = TRUE
	opacity = TRUE
	layer = TURF_LAYER + 0.1

/turf/solid/wall
	name = "wall"
	icon = 'icons/turf/rs_walls.dmi'

	base_icon_state = "rwall"
	icon_state = "rwall0"

/turf/solid/wall/Initialize()
	. = ..()
	var/rando = rand(230,255)
	src.color = rgb(rando,rando,rando)

/turf/solid/window
	name = "window"
	icon = 'icons/turf/rs_windows.dmi'

	opacity = FALSE

	base_icon_state = "fwindow"
	icon_state = "fwindow0"

// open

/turf/open
	density = FALSE

/turf/open/floor
	name = "floor"
	icon = 'icons/turf/rs_floors.dmi'
	icon_state = "floor"
	var/artisinal = TRUE

/turf/open/floor/Initialize()
	. = ..()
	if(artisinal)
		icon_state = "[initial(icon_state)][rand(1,4)]"
		dir = pick(NORTH,SOUTH,EAST,WEST)

/turf/open/floor/light
	color = list(
		1.25, 0,   0,   0,
		0,   1.25, 0,   0,
		0,   0,   1.25, 0,
		0,   0,   0,   1, // Keeps alpha (transparency) normal
		0,   0,   0,   0
	)

/turf/open/floor/dark
	name = "floor"
	icon = 'icons/turf/rs_floors.dmi'
	icon_state = "dark"

/turf/open/floor/wood
	icon_state = "wood"
	artisinal = FALSE

/turf/open/floor/wood/alt
	icon_state = "wood_alt"

/turf/open/floor/wood/tile
	icon_state = "wood_tile"

/turf/open/space
	name = "space"
	desc = "The final frontier."
	icon = 'icons/turf/space.dmi'
	icon_state = "roguespace"
	var/cahed

/turf/open/space/Initialize()
	. = ..()
	dir = pick(SOUTH,NORTH,WEST,EAST)
	
	var/tim = 100 - rand(-20,20)

	animate(src, color="#f00f", easing=QUAD_EASING|EASE_OUT, time=tim, loop=-1)
	animate(color="#ffff", easing=QUAD_EASING|EASE_IN, time=tim)