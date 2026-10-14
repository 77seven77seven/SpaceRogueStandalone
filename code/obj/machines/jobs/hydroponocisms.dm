// TODO: Finish this!

/obj/machine/hydro
	name = "hydroplate"

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "grower"
	density = TRUE

	var/water = 0
	var/datum/plant/plant

	var/growth = 0

/obj/machine/hydro/get_examine_text()
	return "<b>WATER:</b> [floor(water)] | <b>GROWING:</b> [plant ? uppertext(plant.name) : "NIL (NONE)"]"

/obj/machine/hydro/interact(mob/user, obj/item/held_item, params)
	// TODO: Complete all this logic!
	. = ..()
	if(!held_item)
		if(plant && growth >= plant.growth_required)
			// TODO: Complete harvest logic!
			var/amt = rand(plant.harvest_low, plant.harvest_hi)
			for(var/i in 1 to amt)
				var/obj/item/harvested = new plant.harvest(get_turf(src))
				harvested.update_transform()
	else if(istype(held_item, /obj/item/seeds))
		var/obj/item/seeds/seeds = held_item
		plant = new seeds.plant_type
		seeds.destroyself(user)

// MISC.

/datum/plant
	var/name = "genericia"
	var/desc = "It's a plant."

	var/growth_required = 10 // ready to harvest atp
	var/growth_rate = 1 // One per tick?

	var/water_demand = 0 // how much water it consumes per tick?

	var/obj/item/harvest
	var/harvest_low = 1 // rand
	var/harvest_hi = 1 // if 1 on both fields, produces only 1 per harvest

/datum/plant/mealwood
	name = "lignum alimentarium facticium"
	desc = "A common, usually farmed plant mostly found on space station environments. Natively, it is called mealwood."

	growth_required = 50
	water_demand = 0.25

/obj/item/seeds
	name = "seeds"
	desc = "A packet of seeds. You're not sure what's inside, maybe if you knew something about plants..."
	desc_expansive_extra_skill = HYDRO

	var/plant_type = /datum/plant

/obj/item/consumable/meallice
	name = "meal lice"
	desc = "A flavorless grain that almost never wiggles on its own."
	icon_state = "meallice"

	nutrition = 12
	hydration = -6
	mood = -20

	destroy_on_eat = TRUE
	flavor_profile = "Eugh, bleugh BLEUGH! For it being flavorless, it sure has a tendency to NOT have a good texture!"
	flavor_profile_style = "bad"

/obj/item/seeds/Initialize()
	. = ..()
	var/falvor = "...something?"
	if(plant_type)
		falvor = "[plant_type:name]! [plant_type:desc]"
	desc_expansive = "I know! It's a seed packet of [falvor]"