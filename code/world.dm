var/global/datum/system/master/master = new()
var/global/datum/system/processor/processor = new()

var/global/list/landmarks_list = list()
var/global/list/landmarks_start_list = list()

/world
	fps = 20
	icon_size = 32	// 32x32 icon size by default
	view = 6		// show up to 6 tiles outward from center (13x13 view)
	movement_mode = TILE_MOVEMENT_MODE

	mob = /mob/lobbyman
	turf = /turf/open/floor

/world/New()
	if(!master)
		master = new /datum/system/master
	if(!processor)
		processor = new /datum/system/processor

	master.setup()
	processor.setup()

	var/datum/D = new /datum/process_tester
	processor.processing += D

/datum/process_tester/Process()
	//world << "hi [world.time]"

/proc/REF(input)
	if(istype(input, /datum))
		var/datum/thing = input
		if(thing.datum_flags & DF_USE_TAG)
			if(!thing.tag)
				thing.datum_flags &= ~DF_USE_TAG
			else
				return "\[[url_encode(thing.tag)]\]"
	return "\ref[input]"