#define QDEL_HINT_QUEUE      0
#define QDEL_HINT_DEL        1

#define DF_USE_TAG				(1<<0)

#define ALL (~0) //For convenience.
#define NONE 0

#define NUM_E 2.71828183

#define PI 3.1416
#define INFINITY 1e31 //closer then enough

#define QDEL_NULL(item) qdel(item); item = null
#define QDEL_LIST(L) if(L) { for(var/I in L) qdel(I); L.Cut(); }
//#define QDEL_LIST_IN(L, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(______qdel_list_wrapper), L), time, TIMER_STOPPABLE)
#define QDEL_LIST_CONTENTS(L) if(L) { for(var/I in L) qdel(I); L.Cut(); }
#define QDEL_LIST_ASSOC(L) if(L) { for(var/I in L) { qdel(L[I]); qdel(I); } L.Cut(); }
#define QDEL_LIST_ASSOC_VAL(L) if(L) { for(var/I in L) qdel(L[I]); L.Cut(); }

//wrapper macros for easier grepping
#define DIRECT_OUTPUT(A, B) A << B
#define SEND_IMAGE(target, image) DIRECT_OUTPUT(target, image)
#define SEND_SOUND(target, sound) DIRECT_OUTPUT(target, sound)
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

#define PROC_REF(X) (nameof(.proc/##X))
#define VERB_REF(X) (nameof(.verb/##X))
#define TYPE_PROC_REF(TYPE, X) (nameof(##TYPE.proc/##X))
#define TYPE_VERB_REF(TYPE, X) (nameof(##TYPE.verb/##X))
#define GLOBAL_PROC_REF(X) (/proc/##X)

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

// Human vital statistics. Needs are expressed as a percentage where zero is
// satisfied and the maximum is critical.
#define HUMAN_MAX_HEALTH 100
#define HUMAN_MAX_NEED 100
#define HUMAN_NEEDS_PROCESS_INTERVAL 25
#define HUMAN_SORROW_MAX_CYCLES 10
#define HUMAN_NEEDS_HUD_LERP 0.15
#define HUMAN_HUNGER_FULL_TIME (25 * 60 * 10)
#define HUMAN_THIRST_FULL_TIME (30 * 60 * 10)

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