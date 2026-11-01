/datum/system/lighting
	var/list/lighting_update_lights = list()
	var/list/lighting_update_overlays = list()

	// what percentage of an overall frame is used per process() (approx.)
	// NOTE: if this exceeds 100 and there was no error message, that means we successfully avoided losing a frame
	// now split so that only 'final' values are ever presented
	var/frame_usage_scratch = 0
	var/frame_usage = 0 // this should only have 'final' values placed in it
	var/tick_start = 0 // used to track tick usage when we get kicked into the next frame by scheck

/datum/system/lighting/setup()
	lighting_controller = src

/datum/system/lighting/proc/scheck()
	// debug
	if (world.tick_usage > 100)
		world.log << "PROCESS: lighting blew frame timing! [world.tick_usage]"

	// NOTE: process_scheduler also looks at tick_usage to decide if it will queue a new process or not, be aware of that if wanting to modify this
	// we have used up too much of our current tick, abort
	if (world.tick_usage > 70)
		frame_usage_scratch += world.tick_usage - tick_start // store partial frame tick usage

		do
			sleep(world.tick_lag) // skip to next frame
		while (world.tick_usage > 70)

		tick_start = world.tick_usage // restart tick usage tracking
		return 1
	return 0

/datum/system/lighting/Process()
	var/list/lighting_update_lights_old = lighting_update_lights
	lighting_update_lights = list()

	for(var/datum/light_source/L in lighting_update_lights_old)
		//current = L
		if(L.destroyed || L.check() || L.force_update)
			L.remove_lum()
			if(!L.destroyed)
				L.apply_lum()
		else if(L.vis_update)	//We smartly update only tiles that became (in) visible to use.
			L.smart_vis_update()

		L.vis_update = 0
		L.force_update = 0
		L.needs_update = 0
		scheck()

	var/list/lighting_update_overlays_old = lighting_update_overlays
	lighting_update_overlays = list()

	for(var/atom/movable/lighting_overlay/O in lighting_update_overlays_old)
		O.update_overlay()
		O.needs_update = 0
		scheck()