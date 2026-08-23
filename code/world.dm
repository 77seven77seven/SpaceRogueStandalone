var/global/datum/system/master/master = new()
var/global/datum/system/processor/processor = new()

var/global/list/landmarks_list = list()
var/global/list/landmarks_start_list = list()

/world
	fps = 30
	//icon_size = 32	// 32x32 icon size by default
	view = "15x15"
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

/proc/GetRandomLetter()
    var/alphabet = "abcdefghijklmnopqrstuvwxyz"
    // Pick a random position from 1 to the length of the string
    var/pos = rand(1, length(alphabet))
    // Copy 1 character starting at that random position
    return copytext(alphabet, pos, pos + 1)

/proc/GetRandomLetterUpper()
	return uppertext(GetRandomLetter())

//Returns a string with reserved characters and spaces before the first letter removed
/proc/trim_left(text)
	for (var/i = 1 to length(text))
		if (text2ascii(text, i) > 32)
			return copytext(text, i)
	return ""

//Returns a string with reserved characters and spaces after the last letter removed
/proc/trim_right(text)
	for (var/i = length(text), i > 0, i--)
		if (text2ascii(text, i) > 32)
			return copytext(text, 1, i + 1)

	return ""

//Returns a string with reserved characters and spaces before the first word and after the last word removed.
/proc/trim(text, max_length)
	if(max_length)
		text = copytext(text, 1, max_length)
	return trim_left(trim_right(text))