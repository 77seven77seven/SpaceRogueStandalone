// manage

/turf/Initialize()
	..()

	// give all non-dense turfs a 47-state autojoining shadow.
	if(!density)
		var/n = autojoin47("density")
		overlays += icon('icons/turf/autojoin/shadows.dmi', "[n]")

	// give all dense turfs a 16-state autojoining outline.
	else
		var/n = autojoin16("density")
		overlays += icon('icons/turf/rs_walls.dmi', "rwall[n]")

// solid

/turf/solid
	density = TRUE
	opacity = TRUE

/turf/solid/wall
	name = "wall"
	icon = 'icons/turf/rs_walls.dmi'
	icon_state = "rwall0"
	layer = OBJ_LAYER + 0.1

// open

/turf/open
	density = FALSE

/turf/open/floor
	name = "floor"
	icon = 'icons/turf/rs_floors.dmi'
	icon_state = "floor"

/turf/open/floor/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,4)]"