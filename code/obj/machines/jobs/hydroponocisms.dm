// TODO: Finish this!

/obj/machine/hydro
	name = "hydroplate"

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "grower"
	density = TRUE

	var/water = 0
	var/plant_type = ""

	var/growth = 0
	var/growth_required

/datum/plant
	var/name = "generic plant"
	var/desc = "It's a plant."

	var/growth_needed
	var/growth_rate

	// TODO: Do more.

/obj/machine/hydro/get_examine_text()
	return "<b>WATER:</b> [water] | <b>GROWING:</b> [plant_type ? uppertext(plant_type) : "NIL (NONE)"]"