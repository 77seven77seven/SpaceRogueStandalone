/obj/hud
	icon = 'icons/obj/abstract/hud.dmi'
	layer = HUD_LAYER
	plane = HUD_PLANE
	var/mob/human/owner
	var/processing = FALSE

/obj/hud/New(mob/human/owner)
	src.owner = owner
	if(processing)
		processor.processing += src

/obj/hud/Destroy(force)
	processor.processing -= src
	return ..()

/obj/hud/sysmas
	name = "HUD system master /per client"

	var/obj/hud/bg_stats/bg_stats
	var/obj/hud/bg_health/bg_health
	var/obj/hud/health/health

	var/obj/hud/combat/combat
	var/obj/hud/maptext_holder/maptext_holder

	var/list/plane_masters = list()

/obj/hud/sysmas/proc/Update()
	if(!owner || !owner.client)
		return
	if(bg_stats)
		bg_stats.Update()
	if(health)
		health.Update()

/obj/hud/bg_stats
	icon_state = "bg"
	screen_loc = "11,1"

	maptext_width = 192
	maptext_height = 128
	maptext_x = 10
	maptext_y = 2

	maptext = "Help me!"

/obj/hud/bg_stats/proc/GenerateMapText()
	if(!owner)
		return ""
	return {"
		<div style='color:[owner.hud_color]; text-align:left; font-size: 140%; font-family: serif;'>
		WEALTH: [owner.get_money_balance()]§
		HUNGER: [floor(owner.hud_hunger)]%
		THIRST: [floor(owner.hud_thirst)]%
		SORROW: [floor(owner.hud_sorrow)]%<br>
		XP: [owner.client.xp]
		</div>
		"}

/obj/hud/bg_stats/proc/Update()
	if(!owner || !owner.client)
		return
	maptext = GenerateMapText()

/obj/hud/bg_health
	icon = 'icons/obj/abstract/hud_32.dmi'
	icon_state = "bg"
	screen_loc = "13,3"

/obj/hud/health
	icon = 'icons/obj/abstract/hud_32.dmi'
	icon_state = "health0"
	screen_loc = "13,3"
	processing = TRUE

	var/prev_rastra = 1

	var/list/health_color_levels = list("#aeea77", "#ccd455", "#d48743", "#da6c31", "#7e3830", "#ffffff")
	var/iconismus = "health"

/obj/hud/health/Process()
	alpha = rand(220,255)

/obj/hud/health/proc/Update()
	if(!owner || !owner.client)
		return
	var/health = owner.health
	var/rastra

	switch(health)
		if(70 to INFINITY)
			rastra = 1
		if(60 to 70)
			rastra = 2
		if(40 to 60)
			rastra = 3
		if(20 to 40)
			rastra = 4
		if(1 to 20)
			rastra = 5
		else
			rastra = 6

	if(prev_rastra < rastra)
		owner.playsound_local(get_turf(owner), 'sound/effects/senses/health_face.ogg')
	prev_rastra = rastra

	icon_state = "[iconismus][rastra]"

	var/colorissimo = health_color_levels[rastra]
	animate(src, 2, color = colorissimo)

/obj/hud/combat
	screen_loc = "10:-3,1"
	processing = TRUE

	var/atom/movable/backgroundo
	var/atom/movable/combatico

/obj/hud/combat/New()
	..()
	backgroundo = new(src) // You might be confused on why we're doing this. The reason is that you can't move HUD objects out of bounds in BYOND without stretching the viewport.
	backgroundo.icon = 'icons/obj/abstract/hud_32.dmi'
	backgroundo.icon_state = "bg"

	backgroundo.pixel_y = -64

	backgroundo.layer = HUD_LAYER
	backgroundo.plane = HUD_PLANE

	combatico = new(src)
	combatico.icon = 'icons/obj/abstract/hud_32.dmi'
	combatico.icon_state = "combat"

	combatico.layer = HUD_LAYER
	combatico.plane = HUD_PLANE

	vis_contents += backgroundo
	backgroundo.vis_contents += combatico

/obj/hud/combat/Process()
	combatico.alpha = rand(220,255)

/obj/hud/maptext_holder
	screen_loc = "6,1"
	maptext = "yes"
	maptext_height = 128
	maptext_width = 256
	
	processing = TRUE

/obj/hud/maptext_holder/proc/txt(msg)
	maptext = {"<div style='font-size: 200%;font-family:serif;color:[owner.hud_color];text-shadow: 3px 3px 2px #000; display: flex; align-items: center; justify-content: center; width: auto; height: 128px; text-align: center;'>[msg]</div>"}

/obj/hud/maptext_holder/Process()
	alpha = rand(220,255)
	
/obj/hud/fullscreen
	icon = 'icons/full_resized.dmi'
	icon_state = "black"
	screen_loc = "CENTER-6,CENTER-6"
	appearance_flags = NO_CLIENT_COLOR
	layer = HUD_LAYER + 0.1
	//mouse_opacity = 2

/obj/hud/fullscreen/death
	icon_state = "death"

/obj/hud/fullscreen/success
	icon_state = "success"

/obj/hud/fullscreen/nothing
	icon_state = "nothing"

/obj/hud/fullscreen/dissident
	icon_state = "dissidence"

/obj/hud/plane_master
	name = "master plane master"

	plane = GENERIC_PLANE
	layer = 0
	screen_loc = "CENTER"

	mouse_opacity = 1
	appearance_flags = PLANE_MASTER

/obj/hud/plane_master/New(mob/human/owner)
	. = ..()
	owner.client.screen |= src

	animate(src, transform = matrix().Turn(0.5), time = 500, easing = QUAD_EASING | EASE_IN | EASE_OUT, loop = -1, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(transform = matrix().Turn(-1), time = 500, easing = QUAD_EASING | EASE_IN | EASE_OUT, flags = ANIMATION_RELATIVE)