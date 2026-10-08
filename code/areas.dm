/area	
	icon = 'icons/areas.dmi'
	icon_state = "fallback"
	layer = AREA_LAYER
	plane = AREA_PLANE

	mouse_opacity = 0

	var/sound_environment = SOUND_ENVIRONMENT_NONE

/area/Initialize()
	icon_state = ""
	. = ..()

/area/space
	name = "space"
	icon_state = "space"
	sound_environment = SOUND_ENVIRONMENT_MOUNTAINS

/area/station
	name = "station"
	icon_state = "generic"

/area/station/maintenance
	name = "Maintenance Tunnels"
	icon_state = "maints"

/area/station/maintenance/New(loc)
	. = ..()
	var/image/I = image('icons/obj/abstract/fuzz.dmi', src, "fuzz")
	I.alpha = 50
	I.mouse_opacity = 0
	overlays += I

/area/station/maintenance/Entered(mob/human/H, OldLoc)
	. = ..()
	if(ishuman(H) && H.client)
		var/obj/hud/plane_master/PM = locate(/obj/hud/plane_master) in H?.hud_holder?.plane_masters
		if(PM) animate(PM, time = 10, color = "#A4A4A2", easing = QUAD_EASING | EASE_IN | EASE_OUT)

/area/station/maintenance/Exited(mob/human/H, newloc)
	. = ..()
	if(ishuman(H) && H.client)
		var/obj/hud/plane_master/PM = locate(/obj/hud/plane_master) in H?.hud_holder?.plane_masters
		if(PM) animate(PM, color = "#ffffff", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 10)

/particles/dust
	width = 124
	height = 124
	count = 256
	spawning = 999999 //spawn all instantly
	lifespan = 0.75 SECONDS
	fade = 0.35 SECONDS
	position = generator("box", list(-16, -16), list(16, 16), NORMAL_RAND)
	velocity = generator("circle", -8, 8, NORMAL_RAND)
	friction = 0.125
	color = "#660000"

/area/station/medical
	name = "medicaloids"
	icon_state = "medicaloid"

/area/station/corporate
	name = "corpors"
	icon_state = "corpo"

/area/station/corporate/director
	name = "director"

/area/station/hydro
	name = "hydroponics"
	icon_state = "garden"

/area/station/water
	name = "waterworks"
	icon_state = "waterworks"

/area/station/tech
	name = "techs"
	icon_state = "engi"

/area/station/tech/mining
	name = "mining"
	icon_state = "miner"