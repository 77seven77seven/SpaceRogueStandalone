#define QDEL_HINT_QUEUE      0
#define QDEL_HINT_DEL        1

#define DF_USE_TAG				(1<<0)

#define ALL (~0) //For convenience.
#define NONE 0

#define QDEL_NULL(item) qdel(item); item = null
#define QDEL_LIST(L) if(L) { for(var/I in L) qdel(I); L.Cut(); }
#define QDEL_LIST_IN(L, time) addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(______qdel_list_wrapper), L), time, TIMER_STOPPABLE)
#define QDEL_LIST_CONTENTS(L) if(L) { for(var/I in L) qdel(I); L.Cut(); }
#define QDEL_LIST_ASSOC(L) if(L) { for(var/I in L) { qdel(L[I]); qdel(I); } L.Cut(); }
#define QDEL_LIST_ASSOC_VAL(L) if(L) { for(var/I in L) qdel(L[I]); L.Cut(); }

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

#define HUD_PLANE 21
#define HUD_LAYER 21