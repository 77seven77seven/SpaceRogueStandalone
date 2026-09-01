/mob/human
	name = "human being"
	icon = 'icons/human/human.dmi'
	icon_state = "human"

	appearance_flags = KEEP_APART|TILE_BOUND|PIXEL_SCALE

	var/base_delay = 3
	var/move_delay = 3

	var/first_name = "Urist"
	var/last_name = "H."

	var/is_moving = FALSE
	var/tmp/next_move = 0
	var/tmp/next_attack = 0

	var/datum/disease/disease
	var/datum/mind/mind

	var/health = 100
	var/blood = 100

	var/dead = FALSE
	var/ragdolled = FALSE

	var/wealth = 0 // money
	var/hunger = 0 // ditto thirst
	var/thirst = 0 // lowers your speed and then your health if at too long

	var/bones = 2 // how many bones you can break
	var/broke_bones = 0

	var/sorrow = 0 // if youre at 100 for too long, you suffer a heartattack, collapse and then die

	var/list/obj/item/inventory = list()
	var/max_inv = 10
	var/obj/item/holding

	var/obj/item/clothing/hat/hat
	var/image/hat_overlay

	var/obj/item/clothing/shirt/shirt
	var/image/shirt_overlay

	var/obj/item/clothing/pants/pants
	var/image/pants_overlay

	var/obj/item/quickslot_1
	var/obj/item/quickslot_2
	var/obj/item/quickslot_3
	
	var/image/wristpad_glow
	var/image/eyes

	var/obj/hud/sysmas/hud_holder
	var/need_update = FALSE
	var/hud_color = "#A1E85F"

	var/xp_buffer = 0 // you wont get your XP unless you depart the station bro!

	var/wanted = FALSE
	var/wanted_timer = 0 // the crime doesnt really matter, the severity of the crime only matters how long you need to hide

/mob/human/Move(NewLoc, Dir, step_x, step_y)
	var/time = world.time

	if(next_move > time)
		return

	//glide_size = ICON_SIZE / max(move_delay,TICK_LAG) * TICK_LAG

	next_move = time + move_delay
	..()

/mob/human/Click(location, control, params)
	. = ..()
	wristpad_display_change(rgb(rand(0,255),rand(0,255),rand(0,255)))
	eyes_color_change(rgb(rand(0,255),rand(0,255),rand(0,255)))
	var/wealthnew = input(usr, "update wealth") as num|null
	if(wealthnew)
		health = wealthnew
		UpdateHUD()

/mob/human/proc/wristpad_display_change(colorina)
	overlays -= wristpad_glow
	wristpad_glow.color = colorina
	overlays += wristpad_glow

/mob/human/proc/eyes_color_change(colorina)
	overlays -= eyes
	eyes.color = colorina
	overlays += eyes

/mob/human/proc/Initialize_HUD()
	hud_holder = new /obj/hud/sysmas(src)

	hud_holder.bg_stats = new /obj/hud/bg_stats(src)
	hud_holder.bg_health = new /obj/hud/bg_health(src)
	hud_holder.health = new /obj/hud/health(src)

	client.screen += hud_holder.bg_stats
	client.screen += hud_holder.bg_health
	client.screen += hud_holder.health

/mob/human/proc/UpdateHUD()
	hud_holder?.Update()

/mob/human/proc/can_equip_clothing(obj/item/clothing/C)
	if(!C)
		return FALSE
	if(C.slot == "hat" && hat)
		return FALSE
	if(C.slot == "shirt" && shirt)
		return FALSE
	if(C.slot == "pants" && pants)
		return FALSE
	return TRUE

/mob/human/proc/equip_clothing(obj/item/clothing/C)
	if(!C)
		return FALSE
	if(!can_equip_clothing(C))
		return FALSE
	return C.equip_to(src)

/mob/human/proc/unequip_clothing(obj/item/clothing/C)
	if(!C || !C.wearer || C.wearer != src)
		return FALSE
	return C.remove_from_mob()

/mob/human/proc/Initialize_Humanity(list/quirks, list/skills, datum/role/R, is_dissident = FALSE)
	if(!mind)
		var/datum/mind/new_mind = new /datum/mind(ckey)
		mind = new_mind

	if(skills)
		mind.skills = skills

	if(quirks)
		mind.quirks = quirks
		
	if(R)
		mind.set_current_job(R)
		R.equip(src)

		var/turf/starto = locate(1,1,1)
		for(var/obj/abstract/landmark/start/sloc in landmarks_start_list)
			if(sloc.name != R.title)
				continue
			starto = get_turf(sloc)
		forceMove(starto)
	
	if(client.presentation_preference == NEUTER)
		gender = pick(MALE,FEMALE)
	else
		gender = client.presentation_preference

	var/gendero = "m"
	var/list/replicao = list("generic")

	if(gender == FEMALE)
		gendero = "f"

	if(R.corporate)
		replicao -= "generic"
		replicao += "corporate"
	if(R.fancy)
		replicao += "fancy"

	var/firsto = "[pick(world.file2list("strings/[pick(replicao)]_[gendero].txt"))]"
	var/lasto = "[GetRandomLetterUpper()]."

	first_name = firsto
	last_name = lasto

	name = "[first_name] [last_name]"

	wristpad_glow = image(src.icon, src, "wristpad_display", MOB_LAYER + 0.01)
	wristpad_glow.appearance_flags = RESET_COLOR
	wristpad_glow.color = "#4CFF00"
	winset(src, "outputwindow.output", list("text-color" = hud_color))

	eyes = image(src.icon, src, "eyes", MOB_LAYER)
	eyes.appearance_flags = RESET_COLOR
	eyes.color = rgb(rand(0,255),rand(0,255),rand(0,255))
	
	var/image/wristpad = image(src.icon, src, "wristpad", MOB_LAYER + 0.01)
	wristpad.appearance_flags = RESET_COLOR
	overlays += wristpad
	overlays += wristpad_glow
	overlays += eyes

	var/rando = rand(220,255)
	color = rgb(rando, rando + 5, rando) // Random skintone

	Initialize_HUD()
	UpdateHUD()

	if(istype(R.special_role_goal) && prob(R.special_role_goal_prob))
		var/new_goal
		if(islist(R.special_role_goal))
			new_goal = pick(R.special_role_goal)
		else
			new_goal = R.special_role_goal
		mind.goal = new new_goal()
	else
		var/new_goal = get_me_a_goal()
		mind.goal = new new_goal()
	
	if(is_dissident)
		var/new_special_goal = get_me_a_goal(is_dissident)
		mind.special_goal = new new_special_goal()

	for(var/datum/quirk/Q in mind.quirks)
		Q.equip(src)

/mob/human/Stat()
	. = ..()
	stat("<br><br>") // The text looks ugly without this...
	stat("<div style='font-size: 125%'>[first_name] [last_name]</div>")
	stat("<div style='font-size: 110%'>[uppertext(mind.current_job?.title)]</div>")

	stat("-----------------------------------")

	stat("GOAL: [mind.goal?.name] <br>[mind.goal?.desc] (+[mind.goal?.award] XP) [mind.goal?.IsCompleted() ? "(COMPLETED)" : null]")

	if(mind.dissident)
		stat("@#$%&!:", "[uppertext(mind.special_goal?.name)]")
		stat("[mind.special_goal?.desc] (+[mind.special_goal?.award] XP) [mind.special_goal?.IsCompleted() ? "(COMPLETED)" : null]")

	stat("<br><br>") // Ditto! (Not like the Pokémon) Check above!

	stat("QUIRKS:")
	for(var/datum/quirk/Q in mind.quirks)
		stat("● [Q.display_name]")