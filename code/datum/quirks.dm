// quirks don't have a description, their display_name should be enough to tell the player what they're meant to be doing, or how special they are.
/datum/quirk
	var/name = "Incredible"
	var/display_name = "You're strange, however, you are just incredibly incredible."
	//var/rarity = 1.0

/datum/quirk/proc/equip(mob/human/H) // applied after everything else

// todo, light random color skin tone quirk: RGB(150, 255, 150)