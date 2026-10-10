#define QDEL_HINT_QUEUE      0
#define QDEL_HINT_DEL        1

#define DF_USE_TAG				(1<<0)

#define ALL (~0) //For convenience.
#define NONE 0

#define CHANNEL_AREA_AMBIENCE_MIN 1012
#define CHANNEL_AREA_AMBIENCE_MAX 1024
#define CHANNEL_COMBAT_MUSIC 1017

#define NUM_E 2.71828183

#define PI 3.1416
#define INFINITY 1e31 //closer then enough

//default byond sound environments
#define SOUND_ENVIRONMENT_NONE -1
#define SOUND_ENVIRONMENT_GENERIC 0
#define SOUND_ENVIRONMENT_PADDED_CELL 1
#define SOUND_ENVIRONMENT_ROOM 2
#define SOUND_ENVIRONMENT_BATHROOM 3
#define SOUND_ENVIRONMENT_LIVINGROOM 4
#define SOUND_ENVIRONMENT_STONEROOM 5
#define SOUND_ENVIRONMENT_AUDITORIUM 6
#define SOUND_ENVIRONMENT_CONCERT_HALL 7
#define SOUND_ENVIRONMENT_CAVE 8
#define SOUND_ENVIRONMENT_ARENA 9
#define SOUND_ENVIRONMENT_HANGAR 10
#define SOUND_ENVIRONMENT_CARPETED_HALLWAY 11
#define SOUND_ENVIRONMENT_HALLWAY 12
#define SOUND_ENVIRONMENT_STONE_CORRIDOR 13
#define SOUND_ENVIRONMENT_ALLEY 14
#define SOUND_ENVIRONMENT_FOREST 15
#define SOUND_ENVIRONMENT_CITY 16
#define SOUND_ENVIRONMENT_MOUNTAINS 17
#define SOUND_ENVIRONMENT_QUARRY 18
#define SOUND_ENVIRONMENT_PLAIN 19
#define SOUND_ENVIRONMENT_PARKING_LOT 20
#define SOUND_ENVIRONMENT_SEWER_PIPE 21
#define SOUND_ENVIRONMENT_UNDERWATER 22
#define SOUND_ENVIRONMENT_DRUGGED 23
#define SOUND_ENVIRONMENT_DIZZY 24
#define SOUND_ENVIRONMENT_PSYCHOTIC 25
//If we ever make custom ones add them here
#define SOUND_ENVIROMENT_PHASED list(1.8, 0.5, -1000, -4000, 0, 5, 0.1, 1, -15500, 0.007, 2000, 0.05, 0.25, 1, 1.18, 0.348, -5, 2000, 250, 0, 3, 100, 63)

#define QDEL_IN(item, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), item), time)
#define QDEL_NULL(item) qdel(item); item = null
#define QDEL_LIST(L) if(L) { for(var/I in L) qdel(I); L.Cut(); }
//#define QDEL_LIST_IN(L, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(______qdel_list_wrapper), L), time, TIMER_STOPPABLE)
#define QDEL_LIST_CONTENTS(L) if(L) { for(var/I in L) qdel(I); L.Cut(); }
#define QDEL_LIST_ASSOC(L) if(L) { for(var/I in L) { qdel(L[I]); qdel(I); } L.Cut(); }
#define QDEL_LIST_ASSOC_VAL(L) if(L) { for(var/I in L) qdel(L[I]); L.Cut(); }

//wrapper macros for easier grepping
#define SEND_IMAGE(target, image) DIRECT_OUTPUT(target, image)
#define SEND_TEXT(target, text) DIRECT_OUTPUT(target, text)
#define WRITE_FILE(file, text) DIRECT_OUTPUT(file, text)
#define WRITE_LOG(log, text) text2file(text,log) //rustg_log_write

//subtypesof(), typesof() without the parent path
#define subtypesof(typepath) ( typesof(typepath) - typepath )

//Gets the turf this atom inhabits
#define get_turf(A) (get_step(A, 0))

//Same as above except gets the area instead
#define get_area(A) (isarea(A) ? A : get_step(A, 0)?.loc)

#define ishuman(A) (istype(A, /mob/human))

#define isdatum(thing) (istype(thing, /datum))

#define isobj(A) istype(A, /obj) //override the byond proc because it returns true on children of /atom/movable that aren't objs

#define isitem(A) (istype(A, /obj/item))

#define TODEGREES(radians) ((radians) * 57.2957795)

#define TORADIANS(degrees) ((degrees) * 0.0174532925)

// Will filter out extra rotations and negative rotations
// E.g: 540 becomes 180. -180 becomes 180.
#define SIMPLIFY_DEGREES(degrees) (MODULUS((degrees), 360))

// Real modulus that handles decimals
#define MODULUS(x, y) ( (x) - (y) * round((x) / (y)) )

#define WXH_TO_HEIGHT(measurement, return_var) \
	do { \
		var/_measurement = measurement; \
		return_var = text2num(copytext_char(_measurement, findtextEx(_measurement, "x") + 0.5)); \
	} while(FALSE);

#define HUD_PLANE 21
#define HUD_LAYER 21

#define AREA_PLANE 20
#define GENERIC_PLANE 1

// Human vital statistics. Needs are expressed as a percentage where zero is
// satisfied and the maximum is critical.
#define HUMAN_MAX_HEALTH 100
#define HUMAN_MAX_NEED 100
#define HUMAN_NEEDS_PROCESS_INTERVAL 25
#define HUMAN_SORROW_MAX_CYCLES 10
#define HUMAN_NEEDS_HUD_LERP 0.2
#define HUMAN_HUNGER_FULL_TIME (25 * 80 * 10)
#define HUMAN_THIRST_FULL_TIME (30 * 80 * 10)

// SKILLS

#define CORP "ESPRIT DE CORPO"
#define GUNS "FIREARMS"
#define PARANOIA "AAH!!!"
#define MELEE "MELEE"
#define HYDRO "HYDROPONICS"
#define PLUMB "PLUMBING"
#define TECH "TECHNOLOGY"
#define MINE "MINING"
#define MEDI "MEDICINE"
#define ENCY "ENCYCLOPEDIA"
#define FORI "FORENSICS"
#define MUSI "MUSIC"
#define MYST "???" // Psionics

// MENTAL STATES

#define MENTAL_STATE_BASELINE "baseline" // Normal guy.
#define MENTAL_STATE_MILD "mild" // Someone used to killing. Enforcers, etc.
#define MENTAL_STATE_PSYCHO "psycho" // Enjoys murder.
#define MENTAL_STATE_DESENSITIZED "desensitized"

// ECONOMY

#define PAYCHECK_LOW 10
#define PAYCHECK_STANDARD 25
#define PAYCHECK_CORPO 50
#define PAYCHECK_VHIGH 100 // For very important corporate roles, that are generally very rare.

#define STATION_BUDGET_DEFAULT 1500

// FLICK OVERLAYS

/proc/remove_images_from_clients(image/I, list/show_to)
	for(var/client/C in show_to)
		C.images -= I

/proc/flick_overlay(image/I, list/show_to, duration)
	for(var/client/C in show_to)
		C.images += I
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(remove_images_from_clients), I, show_to), duration, TIMER_CLIENT_TIME)

/proc/flick_overlay_view(image/I, atom/target, duration) //wrapper for the above, flicks to everyone who can see the target atom
	var/list/viewing = list()
	for(var/m in viewers(target))
		var/mob/M = m
		if(M.client)
			viewing += M.client
	flick_overlay(I, viewing, duration)

/// Returns TRUE if the input_text ends with the ending
/proc/endswith(input_text, ending)
	var/input_length = length(ending)
	return !!findtext(input_text, ending, -input_length)

/// Generate a grawlix string of length of the text argument.
/proc/grawlix(text)
	var/grawlix = ""
	for(var/iteration in 1 to length_char(text))
		grawlix += pick("@", "$", "?", "!", "#", "§", "*", "£", "%", "☠", "★", "☆", "¿")
	return grawlix

///Returns the top(last) element from the list and removes it from the list (typical stack function)
/proc/pop(list/L)
	if(L.len)
		. = L[L.len]
		L.len--

/proc/format_text(text)
	return replacetext(replacetext(text,"\proper ",""),"\improper ","")

/**
 * Takes a directory and returns every file within every sub directory.
 * If extensions_filter is provided then only files that end in that extension are given back.
 * If extensions_filter is a list, any file that matches at least one entry is given back.
 */
/proc/pathwalk(path, extensions_filter)
	var/list/jobs = list(path)
	var/list/filenames = list()

	while(jobs.len)
		var/current_dir = pop(jobs)
		var/list/new_filenames = flist(current_dir)
		for(var/new_filename in new_filenames)
			// if filename ends in / it is a directory, append to currdir
			if(findtext(new_filename, "/", -1))
				jobs += "[current_dir][new_filename]"
				continue
			// filename extension filtering
			if(extensions_filter)
				if(islist(extensions_filter))
					for(var/allowed_extension in extensions_filter)
						if(endswith(new_filename, allowed_extension))
							filenames += "[current_dir][new_filename]"
							break
				else if(endswith(new_filename, extensions_filter))
					filenames += "[current_dir][new_filename]"
			else
				filenames += "[current_dir][new_filename]"
	return filenames