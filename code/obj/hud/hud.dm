/obj/hud
	icon = 'icons/obj/abstract/hud.dmi'
	layer = HUD_LAYER
	plane = HUD_PLANE
	var/mob/human/owner

/obj/hud/New(owner)
	src.owner = owner

/obj/hud/sysmas
	name = "HUD system master /per client"

	var/obj/hud/bg_stats/bg_stats

	var/obj/hud/bg_health/bg_health
	var/obj/hud/health/health

/obj/hud/sysmas/proc/Update()
	bg_stats.Update()
	health.Update()

/obj/hud/bg_stats
	icon_state = "bg"
	screen_loc = "11,1"

	maptext_width = 96
	maptext_height = 64
	maptext_x = 5

	maptext = "Help me!"

/obj/hud/bg_stats/proc/GenerateMapText()
	return {"
		<div style='color:[owner.hud_color]; text-align:left; font-size: 70%; font-family: serif;'>
		WEALTH: [owner.wealth]$
		HUNGER: [owner.hunger]%
		THIRST: [owner.thirst]%
		SORROW: [owner.sorrow]%<br>
		XP: [owner.client.xp]
		</div>
		"}

/obj/hud/bg_stats/proc/Update()
	maptext = GenerateMapText()

/obj/hud/bg_health
	icon = 'icons/obj/abstract/hud_32.dmi'
	icon_state = "bg_health"
	screen_loc = "13,3"

/obj/hud/health
	icon = 'icons/obj/abstract/hud_32.dmi'
	icon_state = "health0"
	var/iconismus = "health"
	screen_loc = "13,3"

	var/list/health_color_levels = list("#aeea77", "#ccd455", "#d48743", "#da6c31", "#7e3830", "#ffffff")

/obj/hud/health/proc/Update()
	var/health = (owner.health/100) * 100
	var/rastra

	switch(health)
		if(100 to INFINITY)
			rastra = 1
		if(60 to 100)
			rastra = 2
		if(40 to 60)
			rastra = 3
		if(20 to 40)
			rastra = 4
		if(1 to 20)
			rastra = 5
		else
			rastra = 6

	icon_state = "[iconismus][rastra]"

	var/colorissimo = health_color_levels[rastra]
	animate(src, 2, color = colorissimo)