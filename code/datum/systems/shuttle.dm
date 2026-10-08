/datum/system/shuttle
	var/obj/abstract/landmark/shuttle_dock/dock
	var/obj/shuttle/arrived_shuttle
	var/next_arrival = 0
	var/next_departure = 0

/datum/system/shuttle/setup()
	dock = locate(/obj/abstract/landmark/shuttle_dock)
	if(!dock)
		CRASH("Shuttle system requires a mapped shuttle dock landmark.")

	next_arrival = world.time + 10 SECONDS

/datum/system/shuttle/Process()
	if(arrived_shuttle)
		if(world.time >= next_departure)
			qdel(arrived_shuttle)
			arrived_shuttle = null
			chat_announce("PASSENGER SHUTTLE BUS 'PKD' HAS LEFT THE STATION VIA HYPERPORT. NEXT DESTINATION: '[pick("ROUTING HUB: GYRO","MASTERLINE CINDER","SPRAGA TRANSPORT HUB","LITOMER","NILSPACE")]'.")
		return

	if(world.time < next_arrival)
		return

	next_departure = world.time + (2 MINUTES)
	next_arrival = world.time + (rand(16,23) MINUTES)

	chat_announce("PASSENGER SHUTTLE BUS 'PKD' IS ARRIVING VIA HYPERPORT TO 'ENDERA' CIVILIAN DOCKPING PORT ONE. ALL WILLING PAID PASSENGERS PLEASE PREPARE TO BOARD.")

	sleep(2 SECONDS)

	arrived_shuttle = new /obj/shuttle(get_turf(dock))

	playsound(get_turf(arrived_shuttle), 'sound/effects/announce/hyperport.ogg', 100, FALSE, 2, ignore_walls = FALSE, pressure_affected = FALSE)

	var/atom/movable/glow
	glow = new(arrived_shuttle)
	glow.icon = arrived_shuttle.icon
	glow.icon_state = "glow"
	glow.mouse_opacity = 0
	glow.layer = arrived_shuttle.layer + 0.01
	glow.alpha = 255
	glow.color = "#0026FF"

	glow.filters += filter(type = "drop_shadow", x = 0, y = 0, size = 5, color = "#0026FF")
	glow.filters += filter(type="motion_blur", x = 40)

	arrived_shuttle.vis_contents += glow

	arrived_shuttle.pixel_x = 200
	animate(arrived_shuttle, time = 0.5, pixel_x = -64, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)

	var/bloom = glow.filters[1]
	var/blur = glow.filters[2]
	animate(blur, time = 0.5, x=0, flags = ANIMATION_PARALLEL, easing = QUAD_EASING | EASE_IN | EASE_OUT)
	animate(bloom, time = 50, size = 0, flags = ANIMATION_PARALLEL, easing = QUAD_EASING | EASE_IN | EASE_OUT)
	animate(glow, time = 50, alpha = 0, flags = ANIMATION_PARALLEL, easing = QUAD_EASING | EASE_IN | EASE_OUT)

/obj/shuttle
	name = "Passenger Shuttle Bus 'PKD'"
	desc = "A Vlada-funded public transport bus that runs between stations, your final destination if you decide your stay here is done."
	desc_expansive = "Hyperports are essential to the economy, and thus, every station must have one."
	
	bound_height = 128
	bound_width = 192
	pixel_x = -64

	appearance_flags = TILE_BOUND
	
	icon = 'icons/obj/shuttle.dmi'
	icon_state = "generic"
	layer = FLY_LAYER