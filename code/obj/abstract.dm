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

/obj/abstract/landmark/start/New()
	landmarks_start_list += src
	..()
	if(name != "start")
		tag = "start*[name]"

/obj/abstract/landmark/start/Destroy()
	landmarks_start_list -= src
	return ..()