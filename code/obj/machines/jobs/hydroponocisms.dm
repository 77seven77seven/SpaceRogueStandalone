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

	// The overlay currently showing the plant, and a cache key so we only rebuild it when something visible changed.
	var/tmp/image/plant_overlay
	var/tmp/plant_overlay_key

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
	plant_overlay = null
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
			wilt_plant() // refreshes the overlay itself
			return

	update_plant_overlay()

/obj/machine/hydro/proc/wilt_plant()
	QDEL_NULL(plant)
	wilt_cycles = 0
	growth = 0
	update_plant_overlay()

/// Which sprite stage the plant is at, 1 to plant.growth_stages. The final stage is reserved for "ready to harvest".
/obj/machine/hydro/proc/get_plant_stage()
	if(!plant)
		return 0
	if(growth >= plant.growth_required)
		return plant.growth_stages
	var/fraction = max(0, growth) / plant.growth_required
	return clamp(floor(fraction * (plant.growth_stages - 1)) + 1, 1, plant.growth_stages)

/// Rebuilds the plant overlay if the stage or wilting state has changed. Safe to call as often as you like.
/obj/machine/hydro/proc/update_plant_overlay()
	var/key = null
	if(plant && plant.plant_icon && plant.plant_icon_state)
		key = "[plant.type]-[get_plant_stage()]-[wilt_cycles ? "wilt" : "ok"]"

	if(key == plant_overlay_key)
		return
	plant_overlay_key = key

	if(plant_overlay)
		overlays -= plant_overlay
		plant_overlay = null

	if(!key)
		return
	
	var/image/I = image(icon = plant.plant_icon, icon_state = "[plant.plant_icon_state]-[get_plant_stage()]")
	I.layer = layer + 0.1
	if(wilt_cycles)
		I.color = plant.wilt_color
	plant_overlay = I
	overlays += I

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

	user.chat_info("I harvest [jru_NumberText(amt)] [amt == 1 ? "piece" : "pieces"] from the [plant.name].")

	// Plant stays in the tray and starts regrowing, but it's riskier each time.
	growth = 0
	var/adjusted_wilt_chance = max(0, plant.wilt_chance - (hydro_skill / 10))
	if(prob(adjusted_wilt_chance))
		user.chat_info("The [plant.name] withers away. Just like dust in the space wind.","bad")
		wilt_plant()
	else
		plant.wilt_chance = min(100, plant.wilt_chance + max(0, rand(15, 30) - (hydro_skill / 10)))
		update_plant_overlay() // back to the first growth stage

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

	user.chat_info("I run some water into the [name].")

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
		update_plant_overlay()
		user.chat_info("I plant the seeds in the [name].")
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

	// Overlay sprites shown on the hydroplate. Leave plant_icon or plant_icon_state null for no overlay.
	// Expects icon states named "[plant_icon_state]-1" through "[plant_icon_state]-[growth_stages]".
	// The last stage is shown once the plant is ready to harvest.
	var/plant_icon = 'icons/obj/hydro_plants.dmi'
	var/plant_icon_state = null
	var/growth_stages = 3
	var/wilt_color = "#8a7f4a" // tint applied to the overlay while the plant is wilting

/datum/plant/mealwood
	name = "lignum alimentarium facticium"
	desc = "A common, usually farmed plant mostly found on space station environments. Natively, it is called mealwood."

	growth_required = 50
	water_demand = 2
	growth_rate = 3

	harvest = /obj/item/consumable/meallice
	harvest_low = 3
	harvest_hi = 12

	seed_type = /obj/item/seeds/mealwood

	plant_icon_state = "mealwood"
	growth_stages = 3

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

	icon_state = "seeds"

	var/plant_type = /datum/plant

/obj/item/seeds/Initialize()
	. = ..()
	var/flavor = "...something?"
	if(plant_type)
		var/datum/plant/P = plant_type
		flavor = "[initial(P.name)]! [initial(P.desc)]"
	desc_expansive = "I know! It's a seed packet of [flavor]"

/obj/item/seeds/mealwood
	plant_type = /datum/plant/mealwood

	vendor_name = "MW.S"
	vendor_price = 10

/obj/machine/slicer
	name = "two-purpose food preparation machine"
	desc = "Neglected by many that preceded it, even the name was abandoned. Press the <span style='color:blue;'>BLUE</span> button to switch between the two modes, and the <span style='color:green;'>GREEN</span> button to confirm the selection, and buy a delicious meallice pressed into the form you like."

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "slicer"

	var/atom/movable/maptext_holder
	var/pressing = FALSE // FALSE = slicing, TRUE = pressing

/obj/machine/slicer/Initialize()
	. = ..()
	maptext_holder = new(src)
	maptext_holder.maptext = "<div style='color:#A4A4A2; line-height: 0.6; text-align:center; font-size: 6pt; font-family: Tiny5;'>SLICE</div>"
	maptext_holder.maptext_width = 21
	maptext_holder.maptext_height = 10
	maptext_holder.maptext_y = 39
	maptext_holder.maptext_x = 22

	maptext_holder.layer = src.layer
	maptext_holder.plane = src.plane

	vis_contents += maptext_holder

/obj/machine/slicer/proc/maptxt(text)
	maptext_holder.maptext = text
	flicker_animation()

/obj/machine/slicer/get_examine_text(mob/human/user)
	return "[desc] | <b>M.LICE COST:</b> [station.mlices_price]"

/obj/machine/slicer/proc/flicker_animation()
	maptext_holder.alpha = 0
	animate(maptext_holder, rand(2,4), easing = BOUNCE_EASING, alpha = 255)

/obj/machine/slicer/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if(istype(held_item, /obj/item/consumable/meallice))
		user.chat_info("No, no, you see, you need to BUY the meal-lice back from the company to be able to use it!","bad")
		return

	if(check_pixel_bounds(_x, _y, 22, 28, 30, 36))
		flick_overlay_view(image(src.icon, src, "confirm_slicer"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		if(station.mlices)
			if(user.AttemptTransaction(station.mlices_price, TRUE))
				station.mlices--
				playsound(get_turf(src), 'sound/effects/pda/scanner1.ogg', vol = 75)
				playsound(get_turf(src), 'sound/effects/obj/machine.ogg', vol = 50)
				playsound(get_turf(src), 'sound/effects/obj/machine_vend.ogg', vol = 50)

				sleep(0.331 SECONDS)
				var/obj/item/new_item
				if(pressing)
					new_item = new /obj/item/consumable/food/burger/part/patty(get_turf(src))
				else
					new_item = new /obj/item/consumable/food/burger/part/bacon(get_turf(src))
				new_item.pixel_x = rand(-4, 4)
				new_item.pixel_y = rand(-4, 4)
				new_item.update_transform()
				return
		playsound(get_turf(src), 'sound/effects/pda/scanner0.ogg', vol = 75)
		animate(maptext_holder, 0.5, color = "#ff0000")
		animate(color = "#ffffff", time = 5)
	else if(check_pixel_bounds(_x, _y, 38, 44, 30, 36))
		flick_overlay_view(image(src.icon, src, "switch_slicer"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)
		pressing = !pressing

		maptxt("<div style='color:#A4A4A2; line-height: 0.6; text-align:center; font-size: 6pt; font-family: Tiny5;'>[pressing ? "PRES" : "SLICE"]</div>")