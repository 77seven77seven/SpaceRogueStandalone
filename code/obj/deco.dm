/obj/deco
	icon = 'icons/obj/deco.dmi'
	opacity = FALSE
	density = FALSE

/obj/deco/plant
	name = "plant"
	desc = "What's wrong honey? Something not to your liking?"
	desc_expansive = "A specific species of artificially created a common plant. Most commonly used by space station crew for help with filtering out contaminants in the early stages of space habitation. It is now rendered useless due to advances in modern air recycling. The aesthetic however, stayed."
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
	icon_state = "[initial(icon_state)]_[pick("un","cz","cz2","mountain","chez")]"

/obj/deco/trashcan
	name = "trashcan"
	desc = "Not a tradition, more of a necesity. But beauty is in the eye of the beholder."
	icon_state = "trashcan"

/obj/deco/furniture
	icon = 'icons/obj/furniture/furniture.dmi'

/obj/deco/furniture/chair
	name = "chair"
	icon_state = "office_chair"
	desc = "It's a chair."
	desc_expansive = "A chair is a piece of furniture with a raised surface supported by legs, commonly used to seat a single person. Chairs are supported most often by four legs and have a back; however, a chair can have three legs or can have a different shape. Chairs are made of a wide variety of materials, ranging from wood to metal to synthetic material (e.g. plastic), and they may be padded or upholstered in various colors and fabrics, either just on the seat (as with some dining room chairs) or on the entire chair. Chairs are used in a number of rooms in homes (e.g. in living rooms, dining rooms, and dens), in schools and offices (with desks), and in various other workplaces, such as Roguestation Endera."

/obj/deco/furniture/table
	name = "table"
	icon = 'icons/obj/furniture/table.dmi'
	icon_state = "0"
	mouse_opacity = 0
	density = TRUE

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