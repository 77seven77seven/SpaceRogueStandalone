/mob/human
	name = "human being"
	icon = 'icons/human/human.dmi'
	icon_state = "human"

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

	var/xp_buffer = 0 // you wont get your XP unless you depart the station bro!

	var/wanted = FALSE
	var/wanted_timer // the crime doesnt really matter, the severity of the crime only matters how long you need to hide

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

	for(var/datum/quirk/Q in mind.quirks)
		Q.equip(src)