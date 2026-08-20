/datum/goal
	var/name = "Just... Do something, I guess?"
	var/desc = "Everyone has some kind of goal in life, sooner or later. Maybe it's a short-term ambition, or a long-term goal."
	var/award = 1 // XP
	var/rarity = 1.0 // Higher the number, the higher the rarity.

	var/antag = FALSE // Able to be rolled for antagonists.

/datum/goal/special
	award = 2 // Antag goals should have higher rewards, since they should usually be against the LAW.
	antag = TRUE

/datum/goal/proc/IsCompleted()
	return FALSE