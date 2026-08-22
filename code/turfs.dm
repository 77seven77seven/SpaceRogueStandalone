/turf/solid
	density = TRUE
	opacity = TRUE

/turf/solid/wall
	name = "wall"
	icon = 'icons/turf/rs_walls.dmi'
	icon_state = "rwall15"
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