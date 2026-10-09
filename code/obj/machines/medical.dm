/obj/machine/medical
	icon = 'icons/obj/medical/terminals.dmi'

// Terminal

/obj/machine/medical/medscan_terminal
	name = "NEMSKN-Terminal"
	desc = "The interface terminal to the NEMSKN, to be operated only by medical professionals. Don't try, you'll hurt yourself."
	icon_state = "medscan_terminal"
	density = FALSE
	opacity = FALSE

	var/scanning = FALSE
	var/list/scan_results = list()

	var/obj/machine/medical/medscan/linked
	var/atom/movable/whiteout

/obj/machine/medical/medscan_terminal/Initialize()
	. = ..()
	whiteout = new(src)
	whiteout.icon = src.icon
	whiteout.icon_state = "whiteout"
	whiteout.mouse_opacity = 0
	whiteout.layer = layer + 0.01
	whiteout.alpha = 0

	vis_contents += whiteout

	for(var/obj/machine/medical/medscan/MS in range(3, get_turf(src)))
		if(istype(MS))
			linked = MS

/obj/machine/medical/medscan_terminal/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if(check_pixel_bounds(_x, _y, 29, 36, 19, 26))
		if(!user.SkillRoll(MEDI))
			return
			
		if(scanning)
			whiteout.color = "#ff0000"
			animate(whiteout, 0.5, alpha = 255)
			animate(alpha = 0, time = 5)

			playsound(get_turf(src), 'sound/effects/pda/scanner0.ogg', vol = 50)
			return
		flick_overlay_view(image(src.icon, src, "confirm"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		playsound(get_turf(src), 'sound/effects/obj/scan_med.ogg', vol = 100)

		scanning = TRUE

		whiteout.color = "#ffffff"
		animate(whiteout, 16.5, alpha = 255)
		animate(alpha = 0, time = 2)

		spawn(16.5)
			var/mob/human/H = locate() in get_turf(linked)
			if(H)
				scan_results["dead"] = H.dead ? "DEAD" : null
				scan_results["fractures"] = H.broke_bones
				scan_results["blood"] = "[H.blood]%"
				scan_results["shrapenl"] = H.shrapnel
				scan_results["bleeding"] = H.bleeding
				scan_results["headshot"] = H.brainsploded

				H.AdjustSorrow(8)

				switch(H.brain_damage)
					if(0)
						scan_results["braindam"] = "NOMINAL :)"
					if(1)
						scan_results["braindam"] = "FAIR :I"
					if(2)
						scan_results["braindam"] = "IMPAIRED :("
					if(3)
						scan_results["braindam"] = "BARELY FUNCTIONING (ᗒᗣᗕ)"

				switch(H.infection)
					if(0 to 2) // Virtually undetectable.
						if(prob(40))
							scan_results["infection"] = "???"
						else
							scan_results["infection"] = "NONE/LOW"
					if(3 to 4)
						scan_results["infection"] = "UH OH... :("
					if(5)
						scan_results["infection"] = "PESTERING!!! (ᗒᗣᗕ)"

				var/rastra
				switch(H.health)
					if(70 to INFINITY)
						rastra = "ECSTATIC"
					if(60 to 70)
						rastra = "HAPPY"
					if(40 to 60)
						rastra = "GRIMACE"
					if(20 to 40)
						rastra = "SAD"
					if(1 to 20)
						rastra = "AGONY"
					else
						rastra = "DEATH"

				scan_results["health"] = rastra

		addtimer(CALLBACK(linked, TYPE_PROC_REF(/obj/machine/medical/medscan, flash)), 16.5, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_CLIENT_TIME)
		spawn(20)
			scanning = FALSE
	else if(check_pixel_bounds(_x, _y, 17, 48, 29, 52))
		if(!user.SkillRoll(MEDI))
			return

		var/datum/popup/terminal/popup = new(user, "medscan", "Medscan", 640, 500)
		if(scan_results.len)
			popup.set_content(
			{"

			<div id="terminal-window">
			
			<div><a href='byond://?src=[REF(user)];close=["medscan"]'>>EXIT</a></div><br>
			>BLULINE TECH, PROPRI H.WARE, NEMSKN-TERMINAL<br>
				
			>[pick("YOUR STOP FOR MEDICALOIDISMS","NEMSKN - THE FUTURE OF MEDICAL CARE")]!<br>
			<br>
			>TIME: <b>[time2text(world.realtime, "mm:ss")]</b><br>
			<br>

			[scan_results["dead"] ? ">SUBJECT IS DECEASED.<br>" : null]
			[scan_results["headshot"] ? ">SUBJECT HAS RECEIVED IRREPAIRABLE NEUROTRAUMA.<br>" : null]
			<br>

			>PHYS. HEALTH: <b>[scan_results["health"]]</b><br>
			>DETECTED FRACTURES: <b>[scan_results["fractures"]]</b><br>
			>BRAIN HEALTH: <b>[scan_results["braindam"]]</b><br>
			>BLOOD LV.: <b>[scan_results["blood"]]</b><br>
			>XENOBIOTIC INFECTIONS: <b>[scan_results["infection"]]</b><br>
			>ILLNESSES: <b>[scan_results["disease"] ? scan_results["disease"] : "ALL CLEAN! :)"]</b><br>
			[scan_results["shrapnel"] ? ">WARNING! DETECTED FOREIGN OBJECTS!<br>" : null]
			[scan_results["bleeding"] ? ">WARNING! SUBJECT IS BLEEDING!<br>" : null]
			<br>

			<b>>######<br>
			>#<br>
			># ####<br>
			>#<br>
			>######<br></b>
			<br>

			</div>
			<div class="scanlines"></div>
			"}
			)
		else
			popup.set_content(
			{"

			<div id="terminal-window">
			<br>
			<div><a href='byond://?src=[REF(user)];close=["medscan"]'>>EXIT</a></div><br>

			>WARNING. FATAL ERROR.<br>
			>PLEASE TRY AGAIN LATER.<br>
			<br>
			</div>
			<div class="scanlines"></div>
			"}
			)
		popup.open()

// Actual machine

/obj/machine/medical/medscan
	name = "NEMSKN"
	desc = "The NEMSKN is a vital piece of technology to any self-respecting medicaloid."
	desc_expansive = "It works on the principle of blasting the unsuspecting patient with a high amount of radiation. For that reason, it should probably not be overused."
	icon_state = "medscan"
	density = FALSE
	opacity = FALSE

	var/atom/movable/glow

/obj/machine/medical/medscan/Initialize()
	. = ..()
	glow = new(src)
	glow.icon = src.icon
	glow.icon_state = "medscan-glow"
	glow.mouse_opacity = 0
	glow.layer = layer + 0.01
	glow.alpha = 0
	glow.color = "#0026FF"

	glow.filters += filter(type="bloom", size=3, offset = 0.5, alpha = 220)
	//world.log << "medscan filters: [length(glow.filters)]" // temp debug

	vis_contents += glow

/obj/machine/medical/medscan/proc/flash()
	animate(glow, time = 2, alpha = 255)
	animate(time = 16.5, alpha = 0)

	if(!length(glow.filters))
		world.log << "medscan filters: FILTER MISSING!!"
		return // filter missing, bail instead of runtime

	var/bloom = glow.filters[1]
	animate(bloom, time = 2, size = 4)
	animate(time = 16.5, size = 0)