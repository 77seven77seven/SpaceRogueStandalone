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
	maptext_width = 64

	maptext = "<span style='color: #00ff00'>Help me!</span>"

/obj/hud/bg_stats/proc/GenerateMapText()
	return {"
		<span style='color:#00ff00; text-align:left'>
		WEALTH: [owner.wealth]$<br>
		HUNGER: [owner.hunger]%<br>
		THIRST: [owner.thirst]%<br>
		SORROW: [owner.sorrow]%<br>
		XP: [owner.client.xp]
		</span>
		"}

/obj/hud/bg_stats/proc/Update()
	maptext = GenerateMapText()

/obj/hud/bg_health
	icon = 'icons/obj/abstract/hud_32.dmi'
	icon_state = "bg_health"
	screen_loc = "13,3"