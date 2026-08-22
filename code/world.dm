#define subtypesof(typepath) ( typesof(typepath) - typepath )
#define ishuman(A) (istype(A, /mob/human))

#define PROC_REF(X) (nameof(.proc/##X))
#define VERB_REF(X) (nameof(.verb/##X))
#define TYPE_PROC_REF(TYPE, X) (nameof(##TYPE.proc/##X))
#define TYPE_VERB_REF(TYPE, X) (nameof(##TYPE.verb/##X))
#define GLOBAL_PROC_REF(X) (/proc/##X)

var/global/datum/system/master/master = new()
var/global/datum/system/processor/processor = new()

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

/proc/REF(input)
	if(istype(input, /datum))
		var/datum/thing = input
		if(thing.datum_flags & DF_USE_TAG)
			if(!thing.tag)
				thing.datum_flags &= ~DF_USE_TAG
			else
				return "\[[url_encode(thing.tag)]\]"
	return "\ref[input]"