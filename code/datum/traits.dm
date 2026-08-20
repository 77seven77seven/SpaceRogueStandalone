// Traits don't have a description, their display_name should be enough to tell the player what they're meant to be doing, or how special they are.
/datum/trait
	var/name = "Incredible"
	var/display_name = "You're strange, however, you are just incredibly incredible."
	//var/rarity = 1.0

/datum/trait/proc/equip(mob/human/H)