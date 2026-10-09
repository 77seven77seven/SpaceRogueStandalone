#define GOAL_RARITY_BASIC 500
#define GOAL_RARITY_RARE 200
#define GOAL_RARITY_VERY_RARE 100

/datum/goal
	var/name = "Something"
	var/desc = "Everyone has some kind of goal in life, sooner or later. Maybe it's a short-term ambition, or a long-term goal."
	var/award = 1 // XP
	var/rarity = GOAL_RARITY_BASIC // Lower the number, the higher the rarity.

	var/antag = FALSE // Able to be rolled for antagonists.
	var/special = FALSE // Can only be assigned manually.

/datum/goal/proc/IsCompleted()
	return FALSE

/datum/goal/leisure
	name = "Leisure"
	desc = "Smart planning and diligent work have lead you to be free of any outside obligations. Your goal is complete."
	award = 1

/datum/goal/leisure/IsCompleted()
	return TRUE

/datum/goal/antag
	antag = TRUE

/datum/goal/antag/debug_goal
	name = "SABOTAGE"
	desc = "Leave them hanging! Kill the reactor, kill them all! MAKE THEIR TUMORS GROW!"
	award = 7 // 7seven
	antag = TRUE

/datum/goal/debug_goal
	name = "Debug Goal"
	desc = "This goal is only available for the Director! This goal was used to test if special goals work. If you're reading this, you're either a coder or they do!"
	award = 77 // 7seven
	special = TRUE

#undef GOAL_RARITY_BASIC
#undef GOAL_RARITY_RARE
#undef GOAL_RARITY_VERY_RARE