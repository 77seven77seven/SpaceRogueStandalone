/mob/human/proc/AddRewardPip() // ● / ○
	var/list/lines = list("Good deeds are rewarded.","Success!","I knew I could do it!","Good for me.")

	if(client.rewardpips < client.max_rewardpips)
		client.rewardpips++

		var/pips
		for(var/i in 1 to client.rewardpips)
			pips += "●"
		for(var/i in 1 to client.max_rewardpips - client.rewardpips)
			pips += "○"

		chat_info("[pick(lines)] [pips]")
	else
		lines = list("Alas! I have done all I can do.","There is nothing else left for me.","No more! I can't have any more!")
	
/mob/human/proc/AdjustXP(amount, silent = FALSE)
	if(!client)
		return

	var/list/lines = list()

	if(!silent)
		if(amount < 0)
			lines = list("FAILURE!","LOSS!","NEGLIGENCE!")
			chat_info("<b>[pick(lines)]</b> -[amount] XP!", "bad")
		else
			lines = list("REWARD!","AWARD!","TRIUMPH!")
			chat_info("<b>[pick(lines)]</b> +[amount] XP!", "good")

	if(client.xp < 0) // Are we in debt?
		client.xp = 0
		chat_info("Your debt is repaid!", "good")
	else
		client?.xp += amount
	 return TRUE