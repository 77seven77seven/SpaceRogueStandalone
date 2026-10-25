/obj/deco
	icon = 'icons/obj/deco.dmi'
	opacity = FALSE
	density = FALSE

/obj/deco/plant
	name = "plant"
	desc = "What's wrong honey? Something not to your liking?"
	desc_expansive = "A specific species of artificially created a common plant. Most commonly used by space station crew due to it not needing sunlight to live. Running UV light everywhere is expensive after all. Even though it is quite literally pitch black, it is still better than not having any plant companions at all."
	icon_state = "plant"

/obj/deco/plant/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,4)]"
	desc = pick("What's wrong honey? Something not to your liking?","A genus of Tilia.","Tilia industria.","Smell the ashes.","Unsurprisingly, plants don't thrive on space stations.","Blacker than a black hole sun.")

/obj/deco/poster
	name = "poster"
	icon_state = "poster"

/obj/deco/poster/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)]_[pick("un","cz","cz2","cz3","cz4","mdt","mountain","chez","hul")]"
	var/matrix/turna = matrix(transform)
	turna.Turn(rand(-3,3))
	transform = turna

	filters += filter(type="drop_shadow", x=2, size=1, offset=1)

/obj/deco/graffiti
	name = "graffiti"
	desc = "Where is Wednesday's teaser?"
	icon_state = "graffiti"

/obj/deco/graffiti/moids
	name = "graffiti"
	desc = "Moids not welcome!"
	desc_expansive = "A common graffiti to see in Roider territory due to them seeing medical treatment as... agaisnt their culture. Moid is a deragotary slang term used against medicaloids."
	desc_expansive_extra_skill = MEDI
	icon_state = "graffiti-2"

/obj/deco/graffiti/slaughterhouse
	name = "graffiti"
	desc = "ONAGER SLAUGHTER-HOUSE. Makes you wonder who wrote this."
	icon_state = "slaughterhouse"

/obj/deco/graffiti/barnyard
	name = "graffiti"
	desc = "THIS STATION IS A BARNYARD!"
	icon_state = "barnyard"

/obj/deco/graffiti/delegate
	name = "graffiti"
	desc = "We're not in ***** anymore, Delegate."
	icon_state = "delegate"

/obj/deco/graffiti/psychic
	name = "graffiti"
	desc = "I'M A VETERAN OF THE PSYCHIC WARS."
	icon_state = "veteran"

/obj/deco/trashcan
	name = "trashcan"
	desc = "Not a tradition, more of a necesity. But beauty is in the eye of the beholder."
	icon_state = "trashcan"

/obj/deco/trashcan/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	if(!held_item)
		if(prob(50))
			user.chat_info("What exactly was I planning to do? Rummage in the trash? Gross.","bad")
		return
	if(held_item.junk)
		user.holding = null
		user.UpdateInhand()

		held_item.forceMove(src)

		if(prob(20))
			user.AddRewardPip()

		user.mind.performance_paycheck += 2

/obj/deco/furniture
	icon = 'icons/obj/furniture/furniture.dmi'

/obj/deco/furniture/chair
	name = "chair"
	icon_state = "office_chair"
	desc = "It's a chair."
	desc_expansive = "A chair is a piece of furniture with a raised surface supported by legs, commonly used to seat a single person. Chairs are supported most often by four legs and have a back; however, a chair can have three legs or can have a different shape. Chairs are made of a wide variety of materials, ranging from wood to metal to synthetic material (e.g. plastic), and they may be padded or upholstered in various colors and fabrics, either just on the seat (as with some dining room chairs) or on the entire chair. Chairs are used in a number of rooms in homes (e.g. in living rooms, dining rooms, and dens), in schools and offices (with desks), and in various other workplaces, such as Roguestation Endera."

/obj/deco/furniture/bed
	name = "bed"
	desc = "For sleeping or for dying in. Fifty percent of the time, it also comes with a bedsheet for extra snuggling."
	desc_expansive = "For some strange reason, you've got a feeling that laying on a bed makes it easier for a caretaker to administer aid."
	desc_expansive_extra_skill = MEDI

	icon_state = "bed"

/obj/deco/furniture/bed/Initialize()
	. = ..()
	if(prob(50))
		var/image/sheet = image(src.icon, src, "sheet")
		sheet.color = get_random_light_color()
		var/image/sheet_overlay = image(src.icon, src, "sheet-overlay")

		overlays += sheet
		overlays += sheet_overlay

	if(prob(10))
		desc = "Planetfall, is this the one? I haven't slept in so long. I want a bed to lie in!"
	
	if(prob(0.1))
		name = "cool bed"
		desc = "For sleeping or for dying in. In addition, it also looks really cool."
		icon_state = "bed_racecar"

/obj/deco/furniture/table
	name = "table"
	icon = 'icons/obj/furniture/table.dmi'
	icon_state = "0"
	mouse_opacity = 0
	density = TRUE
	letpassthrow = TRUE

	layer = 2.9

	var/auto_type = /obj/deco/furniture/table/auto
	var/auto = FALSE

/obj/deco/furniture/table/auto
	auto = TRUE

/obj/deco/furniture/table/Initialize()
	. = ..()
	src.color = rgb(150,150,150)
	if(auto && icon_state == "0") // if someone's set up a special icon state don't mess with it
		set_up()
		spawn(1)
			for(var/obj/deco/furniture/table/T in orange(1))
				if(T.auto)
					T.set_up()

/obj/deco/furniture/table/proc/set_up()
	if(!auto)
		return

	var/dirs = 0
	for(var/direction in list(NORTH, SOUTH, EAST, WEST))
		var/turf/T = get_step(src, direction)
		if(locate(auto_type) in T)
			dirs |= direction

	src.overlays.Cut()
	icon_state = num2text(dirs)

	//christ this is ugly
	var/obj/deco/furniture/table/southwest_table = locate(auto_type) in get_step(src, SOUTHWEST)
	if(southwest_table)
		var/obj/deco/furniture/table/south_table = locate(auto_type) in get_step(src, SOUTH)
		var/obj/deco/furniture/table/west_table = locate(auto_type) in get_step(src, WEST)
		if(south_table && west_table)
			src.overlays += "SW"

	var/obj/deco/furniture/table/southeast_table = locate(auto_type) in get_step(src, SOUTHEAST)
	if(southeast_table)
		var/obj/deco/furniture/table/south_table = locate(auto_type) in get_step(src, SOUTH)
		var/obj/deco/furniture/table/east_table = locate(auto_type) in get_step(src, EAST)
		if(south_table && east_table)
			src.overlays += "SE"

	var/obj/deco/furniture/table/northwest_table = locate(auto_type) in get_step(src, NORTHWEST)
	if(northwest_table)
		var/obj/deco/furniture/table/north_table = locate(auto_type) in get_step(src, NORTH)
		var/obj/deco/furniture/table/west_table = locate(auto_type) in get_step(src, WEST)
		if(north_table && west_table)
			src.overlays += "NW"

	var/obj/deco/furniture/table/northeast_table = locate(auto_type) in get_step(src, NORTHEAST)
	if(northeast_table)
		var/obj/deco/furniture/table/north_table = locate(auto_type) in get_step(src, NORTH)
		var/obj/deco/furniture/table/east_table = locate(auto_type) in get_step(src, EAST)
		if(north_table && east_table)
			src.overlays += "NE"

/obj/deco/fishtank
	name = "fish tank"
	desc = "Cool fish."
	icon_state = "fishtank"
	density = TRUE

/obj/deco/fishtank/interact(mob/user, obj/item/held_item, params)
	. = ..()
	user << browse_rsc('interface/really_cool_fish.gif',"really_cool_fish.gif")
	var/datum/popup/popup = new(user, "cool_fish", "Really Cool Fish")
	popup.set_content("<p><img src=really_cool_fish.gif></p>[desc]")
	popup.open()

/obj/deco/speakertower
	name = "Public Announcement Terminal"
	icon = 'icons/obj/64x128.dmi'
	icon_state = "speakertower"

	layer = FLY_LAYER
	density = TRUE

	var/atom/movable/blip

	desc = "A temporary solution to P.A. addresses, pretty much just a pole with very, very loud speakers. Connected directly to the Director's console and the station's AI."
	desc_expansive = "It has a stupidly done, very much makeshift design that allows for easy tampering and hijacking. As said, it is temporary. P.S: P.A. stands for Public Address, or Public Announcement."

/obj/deco/speakertower/Initialize()
	. = ..()
	station.speakertower = src

	blip = new(src)
	blip.icon = src

	blip.layer = FLY_LAYER
	vis_contents += blip

	filters += filter(type="drop_shadow", x=2, size=2, offset=1)

/obj/deco/speakertower/proc/do_blip(colori)
	blip.color = colori
	flick("speakertower-blip", blip)

/obj/deco/supports
	name = "station support"
	icon = 'icons/turf/rs_floors.dmi'
	icon_state = "station_support"

/obj/deco/chute
	name = "chute"
	desc = "A simple rudimentary cargo transport network chute, or CTNC for short. Leads directly to the overcomplicated storage storage network."
	icon_state = "chute"

/obj/deco/chute/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	if(istype(held_item, /obj/item/consumable/meallice))
		held_item.destroyself(user)
		station.mlices += rand(1,2)
		if(istype(user.mind.current_job, /datum/role/gardener))
			user.mind.performance_paycheck += rand(1,4)
			if(prob(3))
				user.AddRewardPip()

		playsound(get_turf(src), 'sound/effects/obj/chute.ogg', 75, TRUE, -2)

/obj/deco/camera
	name = "CCTV"
	desc = "A security camera."
	desc_expansive = "It actually stands for Closed-Circuit Television, by-the-by. You're welcome."
	icon_state = "camera"

/obj/deco/camera/Initialize()
	. = ..()
	station.cameras += src