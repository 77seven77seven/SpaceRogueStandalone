#define GARANT 100 // Short for guaranteed.
#define GUARANTEED 100 // alt
#define COMMON 90
#define UNCOMMON 75
#define RARE 60
#define VERY_RARE 50
#define EXTR_RARE 10

/datum/role
	var/title = "Job"
	var/desc = "Simple enough, really."
	var/cost = 0 // xp

	var/antag_chance_min = 10
	var/antag_chance_max = 60
	var/antag_can_roll = TRUE

	var/corporate = FALSE
	var/fancy = FALSE

	var/list/access = list()

	var/shoes_is = "shoes"
	var/list/shirts = list(/obj/item/clothing/shirt)
	var/list/pants = list(/obj/item/clothing/pants)

	var/list/hats = list()
	var/hat_prob = 0

	var/datum/goal/special_role_goal
	var/special_role_goal_prob = 100 // 100 means always.

	var/current_positions = 0
	var/total_positions = 0

	var/probability = 0 // The probability for a person to roll the role when their role selection is rerolled by winning.
						// Role selection is not influenced by dying, it keeps it. You have a slightly higher chance to roll some roles with a high XP amount.
						// 100 means Guaranteed, 0 means never. Simple enough.

/datum/role/proc/equip(mob/human/H)
	if(!H)
		return

	if(!H.hat)
		if(hats.len && prob(hat_prob))
			var/obj/item/clothing/new_hat = pick(hats)
			new_hat = new new_hat
			H.equip_clothing(new_hat)
	if(!H.shirt)
		if(shirts.len)
			var/obj/item/clothing/new_shirt = pick(shirts)
			new_shirt = new new_shirt
			H.equip_clothing(new_shirt)
	if(!H.pants)
		if(pants.len)
			var/obj/item/clothing/new_pants = pick(pants)
			new_pants = new new_pants
			H.equip_clothing(new_pants)

	if(shoes_is)
		var/image/shoes = image('icons/clothing/accessories.dmi', H, shoes_is)
		shoes.appearance_flags = RESET_COLOR
		H.overlays += shoes

	return TRUE

/datum/role/proc/get_skills()
	return

/datum/role/unassigned // Unused.
	title = "Nobody"
	desc = "Not a job in sight!"

/datum/role/director
	title = "Director"
	desc = "CHEZ Group only sends their finest, and depending on your performance you're going to be no exception. You've been chosen to watch and take care of Roguestation Endera, a small mining and refining station. You're here for one thing... profit."
	cost = 6

	total_positions = 1
	probability = RARE
	corporate = TRUE

	access = list("EVERYTHING")

	antag_can_roll = FALSE

/datum/role/director/equip(mob/human/H)
	. = ..()
	
	var/badge = image('icons/clothing/accessories.dmi', H, "director_badge", MOB_LAYER + 0.01)
	H.overlays += badge

/datum/role/director/get_skills()
	return list(CORP = 90, GUNS = 20 + rand(-10,10), PARANOIA = 60, MELEE = 10 + rand(-9,10))

/datum/role/merc
	title = "Contractor"
	desc = "Make no mistake, you're a mercenary (Just don't let anyone talk about you like that.). A rent-a-cop from Sidereal Plexus, working on behalf of CHEZ Group and by extension the Director. As if the unofficial job title didn't make it clear enough, you're not here to 'give out fines' or 'detain people', or any of that official policeman business. You're here to keep the peace, no matter the cost. It's not like this recently bought roguestation has a prison. You're here to ensure the workers don't rise up, and profits soar. You're authorized to permanently neutralize any or all troublemakers and beat people that complain unconscious. Just make sure to only beat people that are wanted, wouldn't want you to be shocked, would we?"
	cost = 4

	total_positions = 4
	probability = UNCOMMON
	corporate = TRUE
	shoes_is = "mercenary_shoes"

	access = list("CORP")

	antag_can_roll = FALSE

/datum/role/merc/equip(mob/human/H)
	. = ..()
	
	var/merc_badge = image('icons/clothing/accessories.dmi', H, "mercenary_badge[rand(1,2)]", MOB_LAYER + 0.01)
	H.overlays += merc_badge

/datum/role/merc/get_skills()
	return list(CORP = 60, GUNS = 40 + rand(-10,10), MELEE = 60 + rand(-10,10), PARANOIA = 40)

/datum/role/gardener
	title = "Hydroponocist"
	desc = "Since the dawn of mankind, every society needed someone to make food for people. Well, that's who you are. Operate the mealworm farms, press them into bricks, and then give them some texture in the cooking machines. Remember, this is a respectful occupation where everyone will eventually grow to like you. Ensure it stays that way."

	total_positions = 2
	probability = COMMON

/datum/role/gardener/get_skills()
	return list(HYDRO = 80 + rand(-10,10))
	
/datum/role/plumber
	title = "Plumber"
	desc = "You work with water purification. Your life is alright, nothing too special. You're insured by CHEZ Group, well paid, and you have a safe, stable job. Thankfully, there's enough chaos on Endera to entertain you while you're on your break."

	total_positions = 2
	probability = COMMON

/datum/role/plumber/get_skills()
	return list(PLUMB = 80 + rand(-10,10))

/datum/role/technician
	title = "Technician"
	desc = "You're an on-site technician working for CHEZ. You're insured, and your job mostly consists of restocking the vending machines, and ordering items through the pipeline for anyone that might be willing to import something. Sometimes, you're gonna find yourself in space finding things to salvage for recycling."
	cost = 2

	total_positions = 2
	probability = UNCOMMON

	antag_chance_min = 10
	antag_chance_max = 40

/datum/role/technician/get_skills()
	return list(TECH = 85 + rand(-10,10))

/datum/role/miner
	title = "Miner"
	desc = "The brother or sister, more of a cousin to the Technician. You're both in the same union, and your jobs are remarkably similar. You venture down into the mines to find ore, scrap them to... well, scrap. And then refine them yourself in an incredibly convoluted process. At least the pay's nice, and the Director is sure to give you a nice bonus for quotas. You run the primary economy of the station! Act like it! Wear your union badge with pride."

	total_positions = 4
	probability = COMMON

/datum/role/miner/get_skills()
	return list(MINE = 85 + rand(-10,10), TECH = 45 + rand(-10,10))

/datum/role/medicaloid
	title = "Medicaloid"
	desc = "A doctor, medical doctors. Can you believe that some people call medicaloids 'lazarii'? Horrible, right? Anyway, you better buckle up and try to treat people to your best ability, but don't get your worries up... Someone's gonna die eventually."

	total_positions = 4
	probability = COMMON

/datum/role/medicaloid/equip(mob/human/H)
	. = ..()
	
	var/med_badge = image('icons/clothing/accessories.dmi', H, "medi_badge", MOB_LAYER + 0.01)
	H.overlays += med_badge

/datum/role/medicaloid/get_skills()
	return list(MEDI = 85 + rand(-10,10), TECH = 45 + rand(-10,10))

/datum/role/stowaway
	title = "Stowaway"
	desc = "By all means, you're not meant to be here. Nobody really knows who, or what you even are. But I doubt you'll be in trouble. Everybody likes some company on this decaying heap of a newly-bought and refurbished roguestation. Beg the Director for a job, or don't and just enjoy the scenery. But keep in mind, if you're planning on getting a job, make sure you actually *know* how to work one. Or don't, and just enjoy the raised pay."

	total_positions = 20
	probability = GUARANTEED

	antag_chance_min = 1
	antag_chance_max = 70