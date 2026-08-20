#define subtypesof(typepath) ( typesof(typepath) - typepath )
#define ishuman(A) (istype(A, /mob/human))

var/global/datum/system/master/master
var/global/datum/system/processor/processor

/datum/proc/process()
	processor.processing -= src
	return

/world
	fps = 20
	icon_size = 32	// 32x32 icon size by default
	view = 6		// show up to 6 tiles outward from center (13x13 view)
	movement_mode = TILE_MOVEMENT_MODE

	mob = /mob/lobbyman

/world/New()
	if(!master)
		master = new /datum/system/master
	if(!processor)
		processor = new /datum/system/processor

	master.setup()
	processor.setup()

	var/datum/D = new /datum/process_tester
	processor.processing += D

/datum/process_tester/process()
	//world << "hi [world.time]"