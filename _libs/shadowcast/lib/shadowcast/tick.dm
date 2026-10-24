// ============================================================================
//  shadowcast / tick.dm
//  The driver. Include the library and shadows appear for every client: this
//  file watches who is connected and keeps their view up to date.
//
//  Default: a tiny loop, one pass per server tick. It sees a move one tick
//  after it happened, and compensates by finishing the glide on time.
//
//  Zero-latency option (BYOND 515+): put
//      #define SHADOWCAST_MANUAL_TICK
//  before the include and call shadowcast_tick() from your /world/Tick().
//  world.Tick() runs right before the map is sent, so shadows and camera
//  start in the very same frame.
// ============================================================================

#if DM_VERSION < 515
#warn shadowcast needs BYOND 515 or newer (floor(), ceil(), clamp(), world.Tick).
#endif

/// Run one pass over every client: create, update or remove their view.
/proc/shadowcast_tick()
	for(var/client/C)
		if(C.shadowcast_enabled)
			if(!C.shadowcast)
				C.shadowcast = new /datum/shadowcast_view(C)
			C.shadowcast.tick()
		else if(C.shadowcast)
			C.shadowcast.teardown()
			C.shadowcast = null

#ifndef SHADOWCAST_MANUAL_TICK

/datum/shadowcast_driver/New()
	..()
	spawn(0)
		trun()

/datum/shadowcast_driver/proc/trun()
	set waitfor = 0
	while(1)
		shadowcast_tick()
		sleep(world.tick_lag)

/// Created at startup (global initialisers run before world/New), which starts the loop.
/var/global/datum/shadowcast_driver/shadowcast_driver = new

#endif
