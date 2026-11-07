/mob/human/proc/get_money_balance()
	if(station && mind && istype(mind.current_job, /datum/role/director))
		return station.treasury
	return wealth

/mob/human/proc/AdjustMoney(amount, silent = FALSE)
	if(station && mind && istype(mind.current_job, /datum/role/director))
		station.treasury += amount
	else
		wealth += amount
	UpdateHUD()
	if(silent)
		return

	var/list/lines = list()
	if(amount < 0)
		lines = list("Unfortunate!","CHEZ Group informs you to follow your obligation under § 13 of IMPKOD!","Please reconsider your actions.","All thanks to the hard work of the fellas in CS&INB!","Gamble responsibly!")
		
		if(mind.current_job.unemployed)
			lines += "This wire transfer has been recorded , marked as a note of interest and will be used as evidence in accusations of delinquency."
		chat_pda("TRANSACTION LOGGED. YOU HAVE TRANSFERRED: <b>[abs(amount)][pick("§","€$")]</b>.","pay", TRUE)
	else
		lines = list("Have a nice day!","CHEZ Group informs you to follow your obligation under § 13 of IMPKOD!","The Michl administration thanks you!","All thanks to the hard work of the fellas in CS&INB!","Gamble responsibly!")
		
		if(mind.current_job.unemployed)
			lines = list("Please consider seeking employment.","CHEZ Group informs you that bottomfeeding is a socially frowned upon action.","CHEZ Group would like to inform you that a stable source of income leads to a healthy and successful life, Take this information as you will.")
		chat_pda("TRANSACTION LOGGED. YOU HAVE BEEN TRANSFERRED: [amount][pick("§","€$")]. <b>[pick(lines)]</b>","pay", TRUE)
	playsound(get_turf(src), 'sound/effects/pda/pay.ogg', 50, FALSE, -3)

/mob/human/proc/AttemptTransaction(amount, proceeds_go_to_station = FALSE)
	if(get_money_balance() >= amount)
		AdjustMoney(-amount)
		if(proceeds_go_to_station)
			station.treasury += amount
		return TRUE
	else
		chat_pda("TRANSACTION FAIL! <b>YOU'RE BROKE!</b>","bad")
	return FALSE

/mob/human/proc/AdjustPaycheck(amount, silent = FALSE)
	mind.paycheck = amount
	UpdateHUD()
	if(silent)
		return
	var/list/lines = list("Please spend your paycheck responsibly.","Thank you for your continued loyalty to CHEZ Group and associates!","CHEZ Group: Serving the Public Trust","CHEZ Group informs you to follow your obligation under § 13 of IMPKOD!","The Michl administration thanks you!","All thanks to the hard work of the fellas in CS&INB!")
	if(mind.current_job.unemployed)
		lines = list("Under UN-ICM § 9 of the Corporate Morality Code, you are entitled to unemployment stipends. Please note that abuse of this system will lead to prosecution.","Under UN-ICM § 9 of the Corporate Morality Code, you are entitled to unemployment stipends. CHEZ Group would like to inform you that a stable source of income leads to a healthy and successful life, Take this information as you will.")
	chat_pda("EMPLOYMENT INCOME PRIVATE ACCOUNT DEFAULTED. YOU HAVE BEEN ASSIGNED [amount + mind.bonus_paycheck][pick("§","€$")]. <b>[pick(lines)]</b>","pay")

/mob/human/proc/AdjustBonus(amount, silent = FALSE)
	mind.bonus_paycheck += amount
	UpdateHUD()
	if(silent)
		return
	var/list/lines = list("Remind yourself that this is a privilege, not a right.","Thank you for your continued loyalty to CHEZ Group and associates!","CHEZ Group: Serving the Public Trust","CHEZ Group informs you to follow your obligation under § 13 of IMPKOD!","The Michl administration thanks you!","All thanks to the hard work of the fellas in CS&INB!")
	if(mind.current_job.unemployed)
		lines = list("Under UN-ICM § 10 of the Corporate Morality Code, even unemployed persons are entitled to Director-assigned bonuses. Please consider seeking employment in the future.")
	chat_pda("CHEZ GROUP ASSIGNED DIRECTOR HAS ANNOUNCED A STATION-WIDE BONUS PAYCHECK OF [amount + mind.bonus_paycheck][pick("§","€$")]. <b>[pick(lines)]</b>","pay")