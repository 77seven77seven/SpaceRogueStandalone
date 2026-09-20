#define QDEL_HINT_QUEUE      0
#define QDEL_HINT_DEL        1

#define DF_USE_TAG				(1<<0)

#define ALL (~0) //For convenience.
#define NONE 0

#define NUM_E 2.71828183

#define PI 3.1416
#define INFINITY 1e31 //closer then enough

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
		return_var = text2num(copytext_char(_measurement, findtextEx(_measurement, "x") + 1)); \
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
#define HUMAN_NEEDS_HUD_LERP 0.15
#define HUMAN_HUNGER_FULL_TIME (25 * 80 * 10)
#define HUMAN_THIRST_FULL_TIME (30 * 80 * 10)

// SKILLS

#define CORP "CORP"
#define GUNS "GUNS"
#define PARANOIA "AAH!!!"
#define MELEE "MELEE"
#define HYDRO "HYDRO"
#define PLUMB "PLUMB"
#define TECH "TECH"
#define MINE "MINE"
#define MEDI "MEDI"

// FLICK OVERLAYS

/proc/remove_images_from_clients(image/I, list/show_to)
	for(var/client/C in show_to)
		C.images -= I

/proc/flick_overlay(image/I, list/show_to, duration)
	for(var/client/C in show_to)
		C.images += I
	addtimer(CALLBACK_GLOBAL(/proc/remove_images_from_clients, I, show_to), duration, TIMER_CLIENT_TIME)

/proc/flick_overlay_view(image/I, atom/target, duration) //wrapper for the above, flicks to everyone who can see the target atom
	var/list/viewing = list()
	for(var/m in viewers(target))
		var/mob/M = m
		if(M.client)
			viewing += M.client
	flick_overlay(I, viewing, duration)