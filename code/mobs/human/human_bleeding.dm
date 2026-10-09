#define BLOOD_VOLUME_REGEN_RATE    2   // blood regained per tick while not bleeding
#define BLOOD_VOLUME_RAGDOLL_RISK  40  // at/below this blood volume, collapse becomes possible
#define BLEED_FX_CHANCE            70  // % chance to show the splash when eligible
#define RAGDOLL_CHANCE_MIN         10  // per-tick collapse chance floor at low blood
#define RAGDOLL_CHANCE_MAX         40  // per-tick collapse chance ceiling at low blood
#define RAGDOLL_LASTWORDS_MIN      20   // chance floor of speaking a line when collapsing
#define RAGDOLL_LASTWORDS_MAX      60  // chance ceiling of speaking a line when collapsing

// Pulled out of the pick() call so it's easy to extend or localize later.
var/global/list/bleedout_lastwords = list(
	"So... tired...",
	"I just need to lay down.",
	"Everything will be fine if I lay down. Right?",
	"It's getting dark.",
	"I'm scared of the dark, don't let me go!"
)

/mob/human/proc/HandleBleeding() // rename/relocate this line to match your real proc
	if(dead)
		return FALSE

	if(bleeding)
		// Halve the bleed each tick, but never by less than 1. DM's round()
		// truncates rather than rounding to nearest (round(0.5) == 0), so
		// without this floor, bleeding could decay to 1, bleed_amount would
		// come out to 0, and the mob would stay stuck "bleeding" at 1 forever:
		// no further blood loss, but it also never reaches the regen branch.

		var/bleed_amount = max(1, round(bleeding * 0.5))
		var/blood_loss = IsOnBed() ? bleed_amount * 0.5 : bleed_amount

		AdjustBlood(-blood_loss)
		if(dead)
			return FALSE

		var/bleeding_change = -bleed_amount * 0.7
		switch(shrapnel)
			if(1)
				bleeding_change = -bleed_amount * 0.5
			if(2) // It's pretty bad.
				bleeding_change = -bleed_amount * 0.4
			if(3) // If we have that much shrapnel in us, our bleeding never gets better.
				bleeding_change = 0
		AdjustBleeding(bleeding_change)
		//world << "BLOOD LOG: bleeding [bleeding], blood [blood], bleed amount [bleed_amount]"

		bleed_effect()

		if(blood <= BLOOD_VOLUME_RAGDOLL_RISK && !ragdolled)
			if(prob(rand(RAGDOLL_CHANCE_MIN, RAGDOLL_CHANCE_MAX)))
				SetRagdolled(TRUE)
				go_blind(4,10)
				if(prob(rand(RAGDOLL_LASTWORDS_MIN, RAGDOLL_LASTWORDS_MAX)))
					chat_info(pick(bleedout_lastwords), "bad")

	else if(!dead)
		AdjustBlood(BLOOD_VOLUME_REGEN_RATE)

/mob/human/proc/go_blind(tim = 5, fade = 5)
	set waitfor = FALSE
	if(!client)
		return

	animate(client, color = "#000000", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = tim)
	sleep(5)
	animate(client, color = "#ffffff", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = fade)

/mob/human/proc/bleed_effect()
	if(prob(BLEED_FX_CHANCE))
		flick_overlay_view(image('icons/human/blood.dmi', src, "bleed", MOB_LAYER + 0.1), src, 6)

	var/vol2use
	switch(rand(1,4))
		if(1)
			vol2use = 'sound/effects/human/medical/BloodDrip0.ogg'
		if(2)
			vol2use = 'sound/effects/human/medical/BloodDrip1.ogg'
		if(3)
			vol2use = 'sound/effects/human/medical/BloodDrip2.ogg'
		if(4)
			vol2use = 'sound/effects/human/medical/BloodDrip3.ogg'
	playsound(get_turf(src), vol2use, 30, TRUE, -1)

	new /atom/movable/blood/drip(get_turf(src))

/particles/brain_splatter
	width = 64
	height = 64
	count = 40
	spawning = 40              // whole burst on the first tick
	lifespan = generator("num", 8, 16)   // ticks (1 tick = 0.1s)
	fade = 20
	icon = 'icons/human/blood.dmi'
	icon_state = "chunk"       // small 2-3px pink/grey blob sprite
	//color = generator("color", "#b5524f", "#e8a7a1")
	position = generator("sphere", 0, 3)
	scale = generator("vector", list(0.6, 0.6), list(1.4, 1.4))
	spin = 5
	gravity = list(0, -6)    // pulls chunks down
	friction = 0.2

/proc/headshot_splatter(turf/T, hit_dir)
	var/obj/fx = new /obj(T)
	fx.mouse_opacity = 0
	fx.layer = FLY_LAYER

	// direction of the exit spray
	var/dx = ((hit_dir & EAST) ? 1 : 0) - ((hit_dir & WEST) ? 1 : 0)
	var/dy = ((hit_dir & NORTH) ? 1 : 0) - ((hit_dir & SOUTH) ? 1 : 0)

	var/particles/brain_splatter/P = new
	P.velocity = generator("box", list(dx*5 - 3, dy*5 - 3, 0), list(dx*5 + 3, dy*5 + 3, 0))
	fx.particles = P

	spawn(1) P.spawning = 0
	spawn(30) qdel(fx)         // clean up once the particles have faded