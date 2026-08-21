/mob/lobbyman // for people in the lobby
	name = "lobbym"
	var/datum/job/chosing_job

/mob/lobbyman/Login()
	. = ..()
	spawn(10)
		winshow(src, "main_menu", TRUE)
		UpdateMainMenu()

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

	var/roles_browser = {"
	<style>
		div.menu {
			font-size: 12px;
		}
	</style>

	<html>
		<body>
		<div style="height:256px;overflow:auto;" class="menu">

		<a>TOURIST (1/2) (6 XP)</a>

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
	
/mob/lobbyman/Topic(href, href_list)
	UpdateMainMenu()
	switch(href_list["role"])
		if("yea")
			return