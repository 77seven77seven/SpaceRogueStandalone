#define SHUTTLE_REST_PIXEL_X     -64
#define SHUTTLE_ENTRY_PIXEL_X    200
#define SHUTTLE_EXIT_PIXEL_X     -3200
#define SHUTTLE_ARRIVAL_DELAY    (5 SECONDS)
#define SHUTTLE_DWELL_TIME       (2 MINUTES)
#define SHUTTLE_GLOW_COLOR       "#0026FF"

/datum/system/shuttle
	var/obj/abstract/landmark/shuttle_dock/dock
	var/obj/shuttle/arrived_shuttle
	var/next_arrival = 0
	var/next_departure = 0

/datum/system/shuttle/setup()
	dock = locate(/obj/abstract/landmark/shuttle_dock)
	if(!dock)
		CRASH("Shuttle system requires a mapped shuttle dock landmark.")

	next_arrival = world.time + (rand(16, 23) MINUTES)

/datum/system/shuttle/Process()
	if(arrived_shuttle)
		if(world.time >= next_departure)
			depart()
		return

	if(world.time < next_arrival)
		return

	// Schedule the next cycle before doing anything that can yield.
	next_arrival = world.time + (rand(16, 23) MINUTES)
	spawn()
		arrive()

/datum/system/shuttle/proc/arrive()
	chat_announce("PASSENGER SHUTTLE BUS 'PKD' IS ARRIVING VIA HYPERPORT TO 'ENDERA' CIVILIAN DOCKING PORT ONE. ALL WILLING PAID PASSENGERS PLEASE PREPARE TO BOARD.")
	sleep(SHUTTLE_ARRIVAL_DELAY)

	arrived_shuttle = new /obj/shuttle(get_turf(dock))
	next_departure = world.time + SHUTTLE_DWELL_TIME
	hyperport_effect(arrived_shuttle, arriving = TRUE)

/datum/system/shuttle/proc/depart()
	// Clear the reference first, otherwise this runs again on every tick.
	var/obj/shuttle/leaving = arrived_shuttle
	arrived_shuttle = null

	chat_announce("PASSENGER SHUTTLE BUS 'PKD' HAS LEFT THE STATION VIA HYPERPORT. NEXT DESTINATION: '[pick("ROUTING HUB: GYRO", "MASTERLINE CINDER", "SPRAGA TRANSPORT HUB", "LITOMER", "NILSPACE")]'.")
	hyperport_effect(leaving, arriving = FALSE)
	QDEL_IN(leaving, 5 SECONDS)

/datum/system/shuttle/proc/hyperport_effect(obj/shuttle/shuttle, arriving)
	playsound(get_turf(shuttle), 'sound/effects/announce/hyperport.ogg', 100, FALSE, 2, ignore_walls = FALSE, pressure_affected = FALSE)

	// Not placed inside the shuttle, so it can't be swept up when the shuttle is deleted.
	var/atom/movable/glow = new /atom/movable
	glow.icon = shuttle.icon
	glow.icon_state = "glow"
	glow.mouse_opacity = 0
	glow.layer = shuttle.layer + 0.01
	glow.alpha = 255
	glow.color = SHUTTLE_GLOW_COLOR
	glow.filters = list(
		filter(type = "drop_shadow", x = 0, y = 0, size = 5, color = SHUTTLE_GLOW_COLOR),
		filter(type = "motion_blur", x = 5, y = 0),
	)
	shuttle.vis_contents += glow

	var/dest_x = arriving ? SHUTTLE_REST_PIXEL_X : SHUTTLE_EXIT_PIXEL_X
	var/easing = CUBIC_EASING | (arriving ? EASE_OUT : EASE_IN)
	if(arriving)
		shuttle.pixel_x = SHUTTLE_ENTRY_PIXEL_X

	var/shadow = glow.filters[1]
	var/blur = glow.filters[2]
	animate(shuttle, time = 0.5 SECONDS, pixel_x = dest_x, easing = easing, flags = ANIMATION_PARALLEL)
	animate(blur,    time = 5 SECONDS, x = 0,     flags = ANIMATION_PARALLEL, easing = QUAD_EASING | EASE_IN | EASE_OUT)
	animate(shadow,  time = 5 SECONDS, size = 0,  flags = ANIMATION_PARALLEL, easing = QUAD_EASING | EASE_IN | EASE_OUT)
	animate(glow,    time = 5 SECONDS, alpha = 0, flags = ANIMATION_PARALLEL, easing = QUAD_EASING | EASE_IN | EASE_OUT)

	QDEL_IN(glow, 5 SECONDS)

/obj/shuttle
	name = "Passenger Shuttle Bus 'PKD'"
	desc = "A Vlada-funded public transport bus that runs between stations, your final destination if you decide your stay here is done."
	desc_expansive = "Hyperports are essential to the economy, and thus, every station must have one."

	bound_height = 128
	bound_width = 192
	pixel_x = SHUTTLE_REST_PIXEL_X

	appearance_flags = TILE_BOUND

	icon = 'icons/obj/shuttle.dmi'
	icon_state = "generic"
	layer = FLY_LAYER