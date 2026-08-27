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