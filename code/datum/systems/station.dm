/datum/system/station
	var/list/humans = list()
	var/list/dead_humans = list()
	
	var/datum/investment/investments = list()

	var/treasury = STATION_BUDGET_DEFAULT
	var/treasury_defaulted = 0 // when at 3, the Director gets wanted and FIRED!
	var/mob/human/director

	var/waters = 10 // Let them have some to start out with.
	var/waters_price = 3 // Export price. Largely random, fluxuates. May drop temporarily on export.

	var/metals = 0
	var/metals_price = 12

	var/mworms = 10
	var/mworms_price = 5

	var/list/newplayer_start = list()

/datum/system/station/proc/do_paychecks()
	for(var/mob/human/H in humans)
		if(H.mind.current_job.unemployed)
			H.chat_pda("Unemployed fucker.","pay")