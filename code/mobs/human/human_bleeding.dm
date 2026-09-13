#define BLOOD_VOLUME_REGEN_RATE    2   // blood regained per tick while not bleeding
#define BLOOD_VOLUME_RAGDOLL_RISK  40  // at/below this blood volume, collapse becomes possible
#define BLEED_FX_MIN_SEVERITY      2   // minimum bleed_amount needed to show a blood-splash effect
#define BLEED_FX_CHANCE            70  // % chance to show the splash when eligible
#define BLEED_FX_LIFETIME          10  // deciseconds the splash effect persists (1 second)
#define RAGDOLL_CHANCE_MIN         10  // per-tick collapse chance floor at low blood
#define RAGDOLL_CHANCE_MAX         40  // per-tick collapse chance ceiling at low blood
#define RAGDOLL_LASTWORDS_MIN      0   // chance floor of speaking a line when collapsing
#define RAGDOLL_LASTWORDS_MAX      20  // chance ceiling of speaking a line when collapsing

// Pulled out of the pick() call so it's easy to extend or localize later.
var/global/list/bleedout_lastwords = list(
	"So... tired...",
	"I just need to lay down.",
	"Everything will be fine if I lay down. Right?",
	"It's getting dark.",
	"I'm scared of the dark, don't let me go!"
)

/mob/human/proc/clear_blood_effect(atom/movable/effect)
	qdel(effect)

/mob/human/proc/HandleBleeding() // rename/relocate this line to match your real proc
	if(bleeding)
		// Halve the bleed each tick, but never by less than 1. DM's round()
		// truncates rather than rounding to nearest (round(0.5) == 0), so
		// without this floor, bleeding could decay to 1, bleed_amount would
		// come out to 0, and the mob would stay stuck "bleeding" at 1 forever:
		// no further blood loss, but it also never reaches the regen branch.

		var/bleed_amount = max(1, round(bleeding * 0.5))

		AdjustBlood(-bleed_amount)
		AdjustBleeding(-bleed_amount)
		world << "BLOOD LOG: bleeding [bleeding], blood [blood], bleed amount [bleed_amount]"

		if(bleed_amount >= BLEED_FX_MIN_SEVERITY && prob(BLEED_FX_CHANCE))
			var/atom/movable/blood_effect = new()
			blood_effect.icon = 'icons/human/human.dmi'
			blood_effect.layer = MOB_LAYER + 0.1
			vis_contents += blood_effect
			flick("bleed", blood_effect)

			spawn(BLEED_FX_LIFETIME)
				clear_blood_effect(blood_effect)

		if(dead)
			return FALSE

		if(blood <= BLOOD_VOLUME_RAGDOLL_RISK && !ragdolled)
			if(prob(rand(RAGDOLL_CHANCE_MIN, RAGDOLL_CHANCE_MAX)))
				SetRagdolled(TRUE)
				if(prob(rand(RAGDOLL_LASTWORDS_MIN, RAGDOLL_LASTWORDS_MAX)))
					chat_info(pick(bleedout_lastwords), "bad")

	else if(!dead)
		AdjustBlood(BLOOD_VOLUME_REGEN_RATE)