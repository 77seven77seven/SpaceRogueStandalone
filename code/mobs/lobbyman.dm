var/global/list/newplayer_start = list()

/client
	var/dissidence_preference = FALSE
	var/presentation_preference = NEUTER // NEUTER = pick randomly between male or female

/mob/lobbyman // for people in the lobby
	name = "lobbym"
	invisibility = 101
	
	var/datum/role/chosing_job
	var/list/datum/quirk/quirks = list()

/mob/lobbyman/Move(NewLoc, Dir, step_x, step_y)
	return FALSE

/mob/lobbyman/Initialize()
	. = ..()
	if(length(newplayer_start))
		forceMove(pick(newplayer_start))
	else
		forceMove(locate(1,1,1))

/mob/lobbyman/Login()
	. = ..()
	UpdateMainMenu()
	winshow(src, "main_menu", TRUE)

/mob/lobbyman/proc/roll_dissidence()
	return FALSE

/mob/lobbyman/proc/UpdateMainMenu()
	var/quirkozas = ""
	for(var/datum/quirk/Q in quirks)
		quirkozas += "<li>[Q.display_name]</li>"

	if(!quirks.len)
		quirkozas = "<li>None.</li>"

	var/information_browser = {"
	<html>
		<body>
		<b>CHOSEN ROLE:</b> [chosing_job ? chosing_job.title : "Nobody"]!

		<br><br>

		<b>DESCRIPTION:</b> [chosing_job ? chosing_job.desc : "Not a job in sight! Click a open job slot on the left!"]

		<br><br>

		<b>Your quirks are:</b>
		[quirkozas]
		<br>

		<b>YOUR XP:</b> [client.xp]
		</body>
	</html>
	"}

	var/roles = ""

	for(var/datum/role/R in master.all_occupations)
		if(R.total_positions > 0 && R.probability)
			roles += "<br>"
			roles += "<a href='byond://?src=[REF(src)];role=[R.type]'>[uppertext(R.title)] ([R.current_positions]/[R.total_positions]) [R.cost ? "([R.cost] XP)" : null]</a>"
			roles += "<br>"

	var/roles_browser = {"
	<style>
		div.menu {
			font-size: 9px;
		}
	</style>

	<html>
		<body>
		<div style="height:256px;overflow:auto;" class="menu">

		[roles]

		</div>
		</body>
	</html>
	"}

	src << output(information_browser, "main_menu.information_browser")
	src << output(roles_browser, "main_menu.roles_browser")

/mob/lobbyman/verb/toggle_dissident()
	set name = ".toggledissident"

	UpdateMainMenu()

	if(winget(src, "main_menu", "is-visible"))
		var/plist[0]

		if(client.dissidence_preference)
			plist["text"] = "DISSIDENT: NO"
			plist["text-color"] = "#000f"
		else
			plist["text"] = "DISSIDENT: YES"
			plist["text-color"] = "#f00f"
		client.dissidence_preference = !client.dissidence_preference
		world << "[client.dissidence_preference]"

		winset(src, "main_menu.dissident", list2params(plist))
	
/mob/lobbyman/verb/toggle_gender()
	set name = ".togglegender"

	UpdateMainMenu()

	if(winget(src, "main_menu", "is-visible"))
		var/plist[0]

		if(client.presentation_preference == NEUTER || client.presentation_preference == FEMALE)
			plist["text"] = "PRESENTATION: MALE"
			client.presentation_preference = MALE
		else
			plist["text"] = "PRESENTATION: FEMALE"
			client.presentation_preference = FEMALE
		world << "[client.presentation_preference]"

		winset(src, "main_menu.gender", list2params(plist))

/mob/lobbyman/proc/GetQuirk()
	var/list/available_quirks = subtypesof(/datum/quirk)
	for(var/datum/quirk/Q in quirks)
		available_quirks -= Q.type
	if(available_quirks.len > 0)
		var/chosen = pick(available_quirks)
		quirks += new chosen
	else
		world << "No quirks to choose from! This is a very bad bug! But only if there are more than 2 quirks."

/mob/lobbyman/verb/get_quirk()
	set name = ".getquirk"

	if(winget(src, "main_menu", "is-visible"))
		var/plist[0]

		// GET QUIRK

		switch(quirks.len)
			if(0)
				// we have no quirks! add one!
				plist["text"] = "DOUBLE QUIRK (1 XP)"
				GetQuirk()
			if(1)
				// we have 1 quirk! double quirk time! 1 XP
				
				if(client.xp >= 1)
					client.xp -= 1
					
					plist["text"] = "TRIPLE QUIRK (2 XP)"
					GetQuirk()
			if(2)
				// daring today are we? triple quirk? 2 XP
				if(client.xp >= 2)
					client.xp -= 2

					plist["text"] = "QUIRK LIMIT REACHED"
					plist["text-color"] = "#f00f"
					GetQuirk()

		winset(src, "main_menu.get_quirk", list2params(plist))
	UpdateMainMenu()

/mob/lobbyman/verb/join_game()
	set name = ".join"

	if(winget(src, "main_menu", "is-visible"))
		if(!chosing_job)
			return

		if(chosing_job.cost > client.xp || chosing_job.current_positions >= chosing_job.total_positions)
			return

		winshow(src, "main_menu", FALSE)

		client.xp -= chosing_job.cost

		var/mob/human/H = new
		H.ckey = ckey
		H.Initialize_Humanity(quirks, chosing_job.get_skills(), chosing_job, roll_dissidence())

		qdel(src)
	
/mob/lobbyman/Topic(href, href_list)
	if(href_list["role"])
		var/datum/role/J = master.GetJobType(text2path(href_list["role"]))
		var/plist[0]

		chosing_job = null

		if(J.cost > client.xp)
			plist["text"] = "INSUFFICIENT XP!"
			plist["text-color"] = "#f00f"
		else if(J.current_positions >= J.total_positions)
			plist["text"] = "ROLE IS FULL!"
			plist["text-color"] = "#f00f"
		else
			plist["text"] = "JOIN!"
			plist["text-color"] = "#000f"
			
			chosing_job = J

		winset(src, "main_menu.join_button", list2params(plist))
	UpdateMainMenu()