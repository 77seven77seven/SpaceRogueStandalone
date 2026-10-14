/area	
	icon = 'icons/areas.dmi'
	icon_state = "fallback"
	layer = AREA_LAYER
	plane = AREA_PLANE

	mouse_opacity = 0

	var/sound_environment = SOUND_ENVIRONMENT_NONE
	var/list/ambience = null
	var/ambience_volume = 35

/area/Initialize()
	icon_state = ""
	. = ..()

/area/Entered(atom/movable/arrived, atom/oldloc)
	. = ..()
	if(ismob(arrived))
		var/mob/M = arrived
		if(M.client)
			M.client.update_area_ambience(src)

/area/Exited(atom/movable/leaving, atom/newloc)
	. = ..()
	if(!newloc && ismob(leaving))
		var/mob/M = leaving
		if(M.client)
			M.client.update_area_ambience(null)

/area/space
	name = "space"
	icon_state = "space"
	sound_environment = SOUND_ENVIRONMENT_MOUNTAINS
	ambience = list('sound/music/ambiance/space.ogg')

/area/station
	name = "station"
	icon_state = "generic"
	ambience = list('sound/music/ambiance/selene.ogg')

/area/station/maintenance
	name = "Maintenance Tunnels"
	icon_state = "maints"
	ambience = list('sound/music/ambiance/maint.ogg')

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
		if(PM) animate(PM, time = 10, color = "#A4A4A2", easing = QUAD_EASING | EASE_IN | EASE_OUT, flags = ANIMATION_PARALLEL)

/area/station/maintenance/Exited(mob/human/H, newloc)
	. = ..()
	if(ishuman(H) && H.client)
		var/obj/hud/plane_master/PM = locate(/obj/hud/plane_master) in H?.hud_holder?.plane_masters
		if(PM) animate(PM, color = "#ffffff", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 10, flags = ANIMATION_PARALLEL)

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
	ambience = list('sound/music/ambiance/corpo.ogg')
	ambience_volume = 20

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
	ambience = list('sound/music/ambiance/maint.ogg')