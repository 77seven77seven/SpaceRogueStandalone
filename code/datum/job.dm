/datum/job
	var/title = "Job!"
	var/desc = "Simple enough, really."
	var/cost = 0 // xp

	var/current_positions = 0
	var/total_positions = 0

/datum/job/proc/equip(/mob/human/H)
	return

/datum/job/unassigned
	title = "Unassigned"

/datum/job/director
	title = "Station Director"
	desc = "The HEAD HONCHO!"
	cost = 6

	total_positions = 1

/datum/job/merc
	title = "Mercenary"
	desc = "Kill criminals."
	cost = 4

	total_positions = 4

/datum/job/gardener
	title = "Hydroponocist"
	desc = "Grow food."

	total_positions = 2
	
/datum/job/plumber
	title = "Plumber"
	desc = "Grow water."

	total_positions = 2

/datum/job/technician
	title = "Technician"
	desc = "Salvage things."
	cost = 2

	total_positions = 2

/datum/job/warehouser
	title = "Warehouser"
	desc = "Nobody likes you."

	total_positions = 1

/datum/job/miner
	title = "Miner"
	desc = "Mine ores, refine them yourself."

	total_positions = 4

/datum/job/medicaloid
	title = "Medicaloid"
	desc = "Someone's gonna die eventually."

	total_positions = 4

/datum/job/stowaway
	title = "Stowaway"
	desc = "Get a job, you lazy fucking bum."

	total_positions = 20