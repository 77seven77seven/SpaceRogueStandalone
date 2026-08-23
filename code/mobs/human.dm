/mob/human
	name = "human being"
	icon = 'icons/human/human.dmi'
	icon_state = "human"

	var/base_delay = 3
	var/move_delay = 3

	var/real_name = "Urist H."

	var/is_moving = FALSE
	var/tmp/next_move = 0

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
	
	var/image/wristpad_glow

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

	var/random_name = "[pick(world.file2list("strings/[pick(replicao)]_[gendero].txt"))] [GetRandomLetterUpper()]."

	real_name = random_name
	name = random_name

	wristpad_glow = image(src.icon, src, "wristpad")
	overlays += image(src.icon, src, "wristpad")
	overlays += wristpad_glow

	for(var/datum/quirk/Q in mind.quirks)
		Q.equip(src)