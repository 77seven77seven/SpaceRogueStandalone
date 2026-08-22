var/global/list/newplayer_start = list()

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
	spawn(10)
		winshow(src, "main_menu", TRUE)
		UpdateMainMenu()

/mob/lobbyman/proc/roll_dissidence()
	return FALSE

/mob/lobbyman/proc/UpdateMainMenu()
	var/information_browser = {"
	<html>
		<body>
		<b>CHOSEN ROLE:</b> [chosing_job ? chosing_job.title : "Nobody"]!

		<br><br>

		<b>DESCRIPTION:</b> [chosing_job ? chosing_job.desc : "Not a job in sight! Click a open job slot on the left!"]

		<br><br>

		<b>Your quirks are:</b>
		&nbsp;<li>None.</li>

		<br><br>

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

/mob/lobbyman/verb/join_game()
	set name = ".join"

	winshow(src, "main_menu", FALSE)

	var/mob/human/H = new
	H.ckey = ckey
	H.Initialize_Humanity(quirks, chosing_job.get_skills(), chosing_job, roll_dissidence())

	qdel(src)
	
/mob/lobbyman/Topic(href, href_list)
	if(href_list["role"])
		var/J = master.GetJobType(text2path(href_list["role"]))
		chosing_job = J
	UpdateMainMenu()