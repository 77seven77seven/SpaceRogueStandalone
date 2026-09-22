// "Under UN-ICM § 9 of the Corporate Morality Code, you are entitled to unemployment stipends. Please note that abuse of this system will lead to prosecution."

/mob/human/proc/AdjustMoney(amount, silent = FALSE)
	wealth += amount
	UpdateHUD()
	if(silent)
		return

	var/list/lines = list()
	if(amount < 0)
		lines = list("Unfortunate!","CHEZ Group informs you to follow your obligation under § 13 of IMPKOD!","Please reconsider your actions.","All thanks to the hard work of the fellas in CS&INB!","Gamble responsibly!")
		chat_pda("TRANSACTION LOGGED. YOU HAVE BEEN FINED: [amount][pick(" EURODOLLARS"," OF STANDARD CURRENCY","§","€$")]. <b>[pick(lines)]</b>","pay")
	else
		lines = list("Have a nice day!","CHEZ Group informs you to follow your obligation under § 13 of IMPKOD!","The Michl administration thanks you!","All thanks to the hard work of the fellas in CS&INB!","Gamble responsibly!")
		
		if(mind.current_job.unemployed)
			lines = list("Please consider seeking employment.","CHEZ Group informs you that bottomfeeding is a socially frowned upon action.")
		chat_pda("TRANSACTION LOGGED. YOU HAVE BEEN TRANSFERRED: [amount][pick(" EURODOLLARS"," OF STANDARD CURRENCY","§","€$")]. <b>[pick(lines)]</b>","pay")