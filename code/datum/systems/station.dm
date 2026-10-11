/datum/system/station
	var/list/humans = list()
	var/list/dead_humans = list()

	var/obj/deco/speakertower/speakertower

	var/mob/human/director
	var/datum/investment/investments = list()

	var/treasury = STATION_BUDGET_DEFAULT
	var/treasury_defaulted = 0 // When at 3, the Director gets wanted and FIRED! Treasury defaults to the default value when the treasury can't pay the workers UBI.
	var/treasury_tax = 0 // In percent, to get multiplier, use get_tax()

	var/waters = 10 // Let them have some to start out with.
	var/waters_price = 3 // Export price. Largely random, fluxuates. May drop temporarily on export.

	var/metals = 0
	var/metals_price = 12

	var/mlices = 10 // Meal Lice.
	var/mlices_price = 5

	// FALSE = ILLEGAL, TRUE = LEGAL
	var/legality_guns = FALSE
	var/legality_gambling = FALSE

	var/list/newplayer_start = list()
	var/next_paycheck = 0

	var/day = 1
	var/next_day = 0

///datum/system/station/setup()
//	processor.processing += src // Handled in world.New()

/datum/system/station/proc/do_paychecks()
	var/list/payroll = list() // mob = amount
	var/total_payroll = 0
	for(var/mob/human/H in humans)
		if(!H.mind || !H.mind.current_job)
			continue
		var/amount = H.mind.get_paycheck_to_pay()
		payroll[H] = amount
		total_payroll += amount

	if(total_payroll <= treasury)
		for(var/mob/human/H in payroll)
			H.AdjustPaycheck(payroll[H])
		treasury -= total_payroll
		return

	for(var/mob/human/H in payroll)
		H.chat_pda("WE APOLOGIZE. YOUR PAYSTUB OF [payroll[H]][pick("§","€$")] IS CURRENTLY UNAVAILABLE TO BE PROCESSED DUE TO LACK OF STATION FUNDS. WE APOLOGIZE FOR THE INCONVENIENCE.","bad")

/datum/system/station/proc/get_tax()
	var/tax_value = 0
	if(treasury_tax)
		tax_value = treasury_tax / 10

	return tax_value

/datum/system/station/Process()
	if(world.time > next_paycheck)
		do_paychecks()
		next_paycheck = world.time + rand(4 MINUTES, 7 MINUTES)

	if(world.time > next_day)
		day++
		next_day = world.time + 24 MINUTES