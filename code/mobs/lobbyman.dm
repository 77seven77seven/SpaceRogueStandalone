/client
	var/dissidence_preference = FALSE
	var/presentation_preference = NEUTER // NEUTER = pick randomly between male or female

/mob
	var/deaf = FALSE
	var/sound_environment_override = SOUND_ENVIRONMENT_NONE

/mob/Topic(href, href_list)
	. = ..()
	if(href_list["close"])
		var/windowid = href_list["close"]
		src << browse(null, "window=[windowid]")
		client.open_popups -= windowid
	if(href_list["link"])
		var/dest = href_list["link"]
		if(dest)
			src << link(dest) // This launches the URL in the user's OS default browser

/mob/Login()
	. = ..()
	if(client)
		client.update_area_ambience(get_area(src))
	src << load_resource('sound/music/spawn.ogg', 'sound/effects/senses/combat_on.ogg', 'sound/effects/senses/combat_off.ogg', 'sound/death.ogg', -1)
	//src << load_resource('icons/full_resized.dmi', -1)
	//src << 'icons/full.dmi'

/mob/lobbyman // for people in the lobby
	name = "lobbym"
	invisibility = 101
	
	var/datum/role/chosing_job
	var/list/datum/quirk/quirks = list()
	var/menu_message = ""

/mob/lobbyman/Move(NewLoc, Dir, step_x, step_y)
	return FALSE

/mob/lobbyman/Initialize()
	. = ..()
	if(length(station.newplayer_start))
		forceMove(pick(station.newplayer_start))
	else
		forceMove(locate(1,1,1))

/mob/lobbyman/Login()
	. = ..()
	UpdateMainMenu()

/mob/lobbyman/proc/roll_dissidence()
	if(client.dissidence_preference)
		if(chosing_job.antag_can_roll)
			var/rand_chance = rand(chosing_job.antag_chance_min,chosing_job.antag_chance_max) - rand(-5,5)

			return prob(rand_chance)
	return FALSE

/mob/lobbyman/proc/UpdateMainMenu()
	var/quirkozas = ""
	for(var/datum/quirk/Q in quirks)
		quirkozas += "<li>[Q.display_name]</li>"

	if(!quirks.len)
		quirkozas = "<li>None.</li>"

	var/roles = ""
	for(var/datum/role/R in master.all_occupations)
		if(R.total_positions > 0 && R.probability)
			roles += "<a class='role' href='byond://?src=[REF(src)];role=[R.type]'>[uppertext(R.title)] ([R.current_positions]/[R.total_positions])[R.cost ? " ([R.cost] XP)" : null]</a>"

	var/quirk_button_text = "GET QUIRK"
	if(quirks.len == 1)
		quirk_button_text = client.xp >= 1 ? "DOUBLE QUIRK (1 XP)" : "NEED 1 XP"
	else if(quirks.len == 2)
		quirk_button_text = client.xp >= 2 ? "TRIPLE QUIRK (2 XP)" : "NEED 2 XP"
	else if(quirks.len >= 3)
		quirk_button_text = "QUIRK LIMIT REACHED"

	var/role_title = chosing_job ? chosing_job.title : "Nobody"
	var/role_description = chosing_job ? chosing_job.desc : "Not a job in sight! Click an open job slot on the left!"
	var/join_text = chosing_job ? "JOIN!" : (menu_message ? menu_message : "PICK A ROLE!")
	var/join_class = chosing_job ? "button join" : "button join unavailable"
	var/presentation_text = "EITHER"
	if(client.presentation_preference == MALE)
		presentation_text = "MALE"
	else if(client.presentation_preference == FEMALE)
		presentation_text = "FEMALE"
	var/menu = {"
		<div class="menu">
			<div class="title">Fringe Sector</div>
			<div class="join-row"><a class="[join_class]" href="byond://?src=[REF(src)];action=join">[join_text]</a></div>
			<div class="section-label roles-label">WHO ARE YOU?</div>
			<div class="section-label info-label">INFORMATION</div>
			<div class="dissident-cell">
				<a class="button" href="byond://?src=[REF(src)];action=dissident">DISSIDENT: [client.dissidence_preference ? "YES" : "NO"]</a>
			</div>
			<div class="role-list">[roles]</div>
			<div class="information">
				<div class="role-name"><b>CHOSEN ROLE:</b> [role_title]!</div>
				<div class="description"><b>DESCRIPTION:</b> [role_description]</div>
				<div class="quirks"><b>Your quirks are:</b><ul>[quirkozas]</ul></div>
				<div class="xp"><b>YOUR XP:</b> [client.xp]</div>
			</div>
			<div class="footer">
				<span class="button codex">CODEX</span>
				<a class="button get-quirk" href="byond://?src=[REF(src)];action=quirk">[quirk_button_text]</a>
				<a class="button gender" href="byond://?src=[REF(src)];action=gender">PRESENTATION: [presentation_text]</a>
			</div>
		</div>
	"}

	var/datum/popup/menu_popup = new /datum/popup/noclose(src, "main_menu", "Main Menu", 800, 540)
	menu_popup.seen_enough = FALSE
	menu_popup.set_window_options("can_close=0;can_minimize=0;can_maximize=0;can_resize=1;titlebar=1;")
	menu_popup.add_stylesheet("lobby", 'interface/lobby.css')
	menu_popup.set_content(menu)
	menu_popup.open(FALSE)

/mob/lobbyman/verb/toggle_dissident()
	set name = ".toggledissident"

	client.dissidence_preference = !client.dissidence_preference
	UpdateMainMenu()
	
/mob/lobbyman/verb/toggle_gender()
	set name = ".togglegender"

	if(client.presentation_preference == NEUTER || client.presentation_preference == FEMALE)
		client.presentation_preference = MALE
	else
		client.presentation_preference = FEMALE
	UpdateMainMenu()

/mob/lobbyman/proc/GetQuirk()
	var/list/available_quirks = subtypesof(/datum/quirk)
	for(var/datum/quirk/Q in quirks)
		available_quirks -= Q.type
	if(available_quirks.len > 0)
		var/chosen = pick(available_quirks)
		quirks += new chosen
	else
		world << "No quirks to choose from! This is a very bad bug! But only if there are more than 2 quirks."

/mob/verb/toggle_textmode()
	set name = ".tab_panel"

	var/winge = winget(src, "rpanewindow", "left")
	//world << winge
	if(winge == "infowindow")
		winset(src, "rpanewindow", "left=.")
		winset(src, "infob", "is-checked=false")
		winset(src, "textb", "is-checked=true")
	else
		winset(src, "rpanewindow", "left=infowindow")
		winset(src, "infob", "is-checked=true")
		winset(src, "textb", "is-checked=false")

/mob/lobbyman/verb/get_quirk()
	set name = ".getquirk"

	switch(quirks.len)
		if(0)
			GetQuirk()
		if(1)
			if(client.xp >= 1)
				client.xp -= 1
				GetQuirk()
		if(2)
			if(client.xp >= 2)
				client.xp -= 2
				GetQuirk()
	UpdateMainMenu()

/mob/lobbyman/verb/join_game()
	set name = ".join"

	if(!chosing_job)
		return

	if(chosing_job.cost > client.xp || chosing_job.current_positions >= chosing_job.total_positions)
		return

	src << browse(null, "window=main_menu")

	client.xp -= chosing_job.cost

	var/dissidence = roll_dissidence()

	var/mob/human/H = new
	H.ckey = ckey
	H.Initialize_Humanity(quirks, chosing_job.get_skills(), chosing_job, dissidence)
	H.DoSpawnEffects()

	qdel(src)
	
/mob/lobbyman/Topic(href, href_list)
	if(href_list["role"])
		var/datum/role/J = master.GetJobType(text2path(href_list["role"]))

		chosing_job = null

		if(!J)
			menu_message = "ROLE NOT AVAILABLE!"
		else if(J.cost > client.xp)
			menu_message = "INSUFFICIENT XP!"
		else if(J.current_positions >= J.total_positions)
			menu_message = "ROLE IS FULL!"
		else
			chosing_job = J
			menu_message = ""
	else if(href_list["action"])
		switch(href_list["action"])
			if("join")
				join_game()
			if("dissident")
				toggle_dissident()
			if("gender")
				toggle_gender()
			if("quirk")
				get_quirk()

	if(href_list["role"])
		UpdateMainMenu()