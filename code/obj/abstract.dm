/obj/abstract
	invisibility = 101
	density = FALSE
	opacity = FALSE

/obj/abstract/landmark
	icon = 'icons/obj/abstract/landmarks.dmi'
	icon_state = "red"

/obj/abstract/landmark/Initialize()
	. = ..()
	landmarks_list += src

/obj/abstract/landmark/Destroy()
	landmarks_list -= src
	return ..()

/obj/abstract/landmark/start
	name = "start"

/obj/abstract/landmark/shuttle_dock
	name = "Shuttle Dock"

/obj/abstract/landmark/start/New()
	if(name == "lobbyman")
		station.newplayer_start += src
	else
		landmarks_start_list += src
	..()

/obj/abstract/landmark/start/Destroy()
	landmarks_start_list -= src
	return ..()