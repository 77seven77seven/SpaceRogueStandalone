#define SHUTTLE_REST_PIXEL_X     -64
#define SHUTTLE_ENTRY_PIXEL_X    600
#define SHUTTLE_EXIT_PIXEL_X     -3200
#define SHUTTLE_ARRIVAL_DELAY    (5 SECONDS)
#define SHUTTLE_DWELL_TIME       (2 MINUTES)
#define SHUTTLE_GLOW_COLOR       "#0026FF"

/datum/system/shuttle
	var/obj/abstract/landmark/shuttle_dock/dock
	var/obj/shuttle/arrived_shuttle

	var/next_arrival = 0
	var/next_departure = 0
	
	var/ticket_price
	var/obj/machine/tickets/ticket_machine

	var/shuttle_here = FALSE

/datum/system/shuttle/setup()
	dock = locate(/obj/abstract/landmark/shuttle_dock)
	if(!dock)
		CRASH("Shuttle system requires a mapped shuttle dock landmark.")

	ticket_price = rand(115,285)
	world.log << "TICKET PRICE: [ticket_price]"
	spawn()
		ticket_machine.update()
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

/datum/system/shuttle/proc/arrive()
	chat_announce("PASSENGER SHUTTLE BUS 'PKD' IS ARRIVING VIA HYPERPORT TO 'ENDERA' CIVILIAN DOCKING PORT ONE. ALL WILLING PAID PASSENGERS PLEASE PREPARE TO BOARD.")
	sleep(SHUTTLE_ARRIVAL_DELAY)

	arrived_shuttle = new /obj/shuttle(get_turf(dock))
	next_departure = world.time + SHUTTLE_DWELL_TIME
	hyperport_effect(arrived_shuttle, arriving = TRUE)

	shuttle_here = TRUE

/datum/system/shuttle/proc/depart()
	// Clear the reference first, otherwise this runs again on every tick.
	var/obj/shuttle/leaving = arrived_shuttle
	arrived_shuttle = null

	shuttle_here = FALSE

	ticket_price = rand(115,285)
	ticket_machine.update()

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
	pixel_y = -128 // So we can interact with the bus when it is still considered 'outside'

	appearance_flags = TILE_BOUND

	icon = 'icons/obj/shuttle.dmi'
	icon_state = "generic"
	layer = FLY_LAYER

/obj/shuttle/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	if(istype(held_item, /obj/item/ticket))
		user.chat_info("[pick("Freedom!","Ah, the sweet winds of adventure!","Success!")]")

		var/turf/old_turf = get_turf(user)
		user.client.perspective = EYE_PERSPECTIVE
		user.client.eye = get_turf(old_turf)
		var/atom/movable/dummy = new(get_turf(old_turf))

		user.loc = null // Nullspace my beloved!
		user.client << output(null, "outputwindow.output")

		dummy.appearance = user.appearance
		animate(dummy, time = 3 SECONDS, alpha = 0)

		var/obj/hud/fullscreen/title = new()
		title.alpha = 0
		user.client.screen += title

		user << sound(null)

		var/line
		var/tagline = "SUCCESS!"
		var/xp_reward = 0
		var/mus_file

		if(user.mind.goal?.IsCompleted())
			title.icon_state = "success"
			line = "You've completed your goal. Congratulations! Most people don't get this far. But what matters now, is that you can finally move on."
			mus_file = 'sound/music/success.ogg'

			xp_reward += user.mind.goal.award
		else
			title.icon_state = "nothing"
			line = "Your fields remain unplowed, and your harvest botched. At least you get a second chance."
			mus_file = 'sound/music/pain.ogg'

			tagline = "FAILURE!"

		if(user.mind.special_goal?.IsCompleted())
			title.icon_state = "dissidence"
			line = "No matter how you achieved your goals, they were but a mere speck in the required prerequisites before REAL work can commence. You were but a single cogwheel in a mechanism, but your efforts won't go unnoticed."
			mus_file = 'sound/music/needles.ogg'

			tagline = "TRIUMPH!"

			xp_reward += user.mind.special_goal.award
		animate(title, time = 6 SECONDS, easing = QUAD_EASING | EASE_IN | EASE_OUT, alpha = 255)

		user.playsound_local(get_turf(user), mus_file, 75, FALSE)
		spawn(6 SECONDS)
			user.chat_info("<b>[tagline]</b> [line]")
			if(xp_reward)
				user.chat_info("<b>REWARD:</b> +[xp_reward] XP")
				user.AdjustXP(xp_reward, TRUE)
	else
		user.chat_info("That doesn't seem like a ticket..?", "bad")