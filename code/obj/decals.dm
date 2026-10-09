/obj/decal
	opacity = FALSE
	density = FALSE
	icon = 'icons/obj/decals.dmi'
	icon_state = "nil"
	layer = TURF_LAYER + 0.1

/obj/decal/maintsign
	icon_state = "randomsign"

/obj/decal/maintsign/Initialize()
	. = ..()

	var/matrix/turna = matrix(transform)
	var/turn = rand(-5,5)
	turna.Turn(turn)
	transform = turna

	var/px = rand(-5,5)
	var/py = rand(-5,5)
	pixel_x += px
	pixel_y += py

	icon_state = pick("crime","CH_restricted_area","CH_danger","CH_electrical_equipment","CH_access_restricted","CH_notice","RU_staff_only","RU_caution")
	if(prob(1))
		icon_state = "randomsign" // :))))))

/obj/decal/floor
	layer = TURF_LAYER

/obj/decal/floor/turf
	icon = 'icons/turf/decals.dmi'