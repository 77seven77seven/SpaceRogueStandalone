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

	var/current_positions = 0
	var/total_positions = 0

	var/probability = 0 // The probability for a person to roll the role when their role selection is rerolled by winning.
						// Role selection is not influenced by dying, it keeps it. You have a slightly higher chance to roll some roles with a high XP amount.
						// 100 means Guaranteed, 0 means never. Simple enough.

/datum/role/proc/equip(/mob/human/H)
	return

/datum/role/proc/get_skills()
	return

/datum/role/unassigned
	title = "Nobody"
	desc = "Not a job in sight! Click a open job slot on the left!"

/datum/role/director
	title = "Director"
	desc = "The HEAD HONCHO!"
	cost = 6

	total_positions = 1
	probability = RARE

/datum/role/merc
	title = "Mercenary"
	desc = "Kill criminals."
	cost = 4

	total_positions = 4
	probability = UNCOMMON

/datum/role/gardener
	title = "Hydroponocist"
	desc = "Grow food."

	total_positions = 2
	probability = COMMON
	
/datum/role/plumber
	title = "Plumber"
	desc = "Grow water."

	total_positions = 2
	probability = COMMON

/datum/role/technician
	title = "Technician"
	desc = "Salvage things, and fix things."
	cost = 2

	total_positions = 2
	probability = UNCOMMON

/datum/role/warehouser
	title = "Warehouser"
	desc = "Nobody likes you."

	total_positions = 1
	probability = GUARANTEED

/datum/role/miner
	title = "Miner"
	desc = "Mine ores, refine them yourself."

	total_positions = 4
	probability = 90 // Common

/datum/role/medicaloid
	title = "Medicaloid"
	desc = "Someone's gonna die eventually."

	total_positions = 4
	probability = COMMON

/datum/role/stowaway
	title = "Stowaway"
	desc = "Get a job, you lazy fucking bum."

	total_positions = 20
	probability = GUARANTEED