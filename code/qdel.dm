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

/datum
	var/gc_destroyed = 0 // Tracks if the item has already been queued or destroyed
	var/datum_flags = NONE

/datum/proc/Destroy(force = FALSE)
	return QDEL_HINT_QUEUE // Or handle immediate cleanup

/proc/qdel(datum/target, force = FALSE)
	if(!target) return
	if(target.gc_destroyed) return
	
	target.gc_destroyed = 1
	
	// Call the object's custom cleanup routine
	var/hint = target.Destroy(force)
	
	if(hint == QDEL_HINT_DEL || force)
		del(target)
	else
		// In a full SS13 implementation, you add `target` to a global processing list/queue here
		// and check it later. If it persists after a timeout, call del(target).
		loc_spoof_and_queue(target)

/proc/loc_spoof_and_queue(datum/target)
	// Move atoms to nullspace to drop map/contents references immediately
	if(istype(target, /atom/movable))
		var/atom/movable/A = target
		A.loc = null
	del(target)