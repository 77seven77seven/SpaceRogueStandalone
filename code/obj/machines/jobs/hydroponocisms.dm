/obj/machine/hydro
	name = "hydroplate"

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "grower"
	density = TRUE

	var/water = 0
	var/max_water = 100
	var/datum/plant/plant

	var/wilt_cycles = 0
	var/max_wilt_cycles = 20

	var/tmp/next_needs_process = 0
	var/tmp/last_needs_process = 0

	var/growth = 0

/obj/machine/hydro/get_examine_text()
	var/growing = "NIL (NONE)"
	if(plant)
		var/pct = min(100, round((growth / plant.growth_required) * 100))
		growing = "[uppertext(plant.name)] ([pct]%[growth >= plant.growth_required ? " - READY" : ""])"
	var/status = ""
	if(plant && wilt_cycles)
		status = " | <b>STATUS:</b> WILTING"
	return "<b>WATER:</b> [floor(water)]/[max_water] | <b>NOW.GROWING:</b> [growing][status]"

/obj/machine/hydro/Initialize()
	. = ..()
	processor.processing += src

/obj/machine/hydro/Destroy()
	processor.processing -= src
	QDEL_NULL(plant)
	return ..()

/obj/machine/hydro/Process()
	if(!plant)
		return

	if(world.time < next_needs_process)
		return
	next_needs_process = world.time + (HUMAN_NEEDS_PROCESS_INTERVAL * 0.9)
	last_needs_process = world.time

	if(water >= plant.water_demand)
		if(wilt_cycles)
			wilt_cycles--
		if(growth < plant.growth_required)
			growth += plant.growth_rate
			water -= plant.water_demand
	else
		if(wilt_cycles < max_wilt_cycles)
			wilt_cycles++
		if(prob(4 * wilt_cycles))
			wilt_plant()

/obj/machine/hydro/proc/wilt_plant()
	QDEL_NULL(plant)
	wilt_cycles = 0
	growth = 0

/obj/machine/hydro/proc/harvest_plant(mob/human/user)
	if(!plant || growth < plant.growth_required)
		return

	var/hydro_skill = user?.mind?.GetSkill(HYDRO) || 0

	var/amt = rand(plant.harvest_low, plant.harvest_hi)
	if(!user.SkillRoll(HYDRO, difficulty = -1))
		// Botched it: lose some of the yield, but never walk away empty-handed.
		amt = max(1, amt - rand(1, amt))

	var/turf/T = get_turf(src)
	for(var/i in 1 to amt)
		var/obj/item/harvested = new plant.harvest(T)
		harvested.update_transform()

	// Chance to get a seed packet back, better with skill.
	if(plant.seed_type && prob(plant.seed_chance + (hydro_skill / 5)))
		new plant.seed_type(T)

	user.chat_info("You harvest [jru_NumberText(amt)] [amt == 1 ? "piece" : "pieces"] from the [plant.name].")

	// Plant stays in the tray and starts regrowing, but it's riskier each time.
	growth = 0
	var/adjusted_wilt_chance = max(0, plant.wilt_chance - (hydro_skill / 10))
	if(prob(adjusted_wilt_chance))
		user.chat_info("The [plant.name] withers away. Just like dust in the space wind.","bad")
		wilt_plant()
	else
		plant.wilt_chance = min(100, plant.wilt_chance + max(0, rand(15, 30) - (hydro_skill / 10)))

/obj/machine/hydro/proc/add_water(mob/human/user)
	if(!station.waters)
		user.chat_info("Looks like the tap has run dry...","bad")
		return
	if(water >= max_water)
		user.chat_info("Overwatering it seems like a bad idea. Drowning is universal for all species, no?","bad")
		return

	var/amt = min(station.waters, rand(1, 2))
	station.waters -= amt
	water = min(max_water, water + amt * 10)

	user.chat_info("You run some water into the [name].")

/obj/machine/hydro/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	if(!held_item)
		if(plant && growth >= plant.growth_required)
			harvest_plant(user)
		else
			add_water(user)
	else if(istype(held_item, /obj/item/seeds))
		if(plant)
			user.chat_info("Something is already growing in the [name]. No space for that.","bad")
			return
		var/obj/item/seeds/seeds = held_item
		if(!seeds.plant_type)
			user.chat_info("These seeds are duds.","bad")
			return
		plant = new seeds.plant_type
		growth = 0
		wilt_cycles = 0
		user.chat_info("You plant the seeds in the [name].")
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

	var/wilt_chance = 10

	var/obj/item/seeds/seed_type // seed packet that can drop on harvest
	var/seed_chance = 10 // base % chance, boosted by skill

/datum/plant/mealwood
	name = "lignum alimentarium facticium"
	desc = "A common, usually farmed plant mostly found on space station environments. Natively, it is called mealwood."

	growth_required = 50
	water_demand = 2
	growth_rate = 3

	harvest = /obj/item/consumable/meallice
	harvest_hi = 6

	seed_type = /obj/item/seeds/mealwood

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

/obj/item/seeds
	name = "seeds"
	desc = "A packet of seeds. You're not sure what's inside, maybe if you knew something about plants..."
	desc_expansive_extra_skill = HYDRO

	var/plant_type = /datum/plant

/obj/item/seeds/Initialize()
	. = ..()
	var/flavor = "...something?"
	if(plant_type)
		var/datum/plant/P = plant_type
		flavor = "[initial(P.name)]! [initial(P.desc)]"
	desc_expansive = "I know! It's a seed packet of [flavor]"

/obj/item/seeds/mealwood
	name = "mealwood seeds"
	plant_type = /datum/plant/mealwood

/mob/verb/water(num as num)
	station.waters += num