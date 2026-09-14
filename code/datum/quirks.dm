// quirks don't have a description, their display_name should be enough to tell the player what they're meant to be doing, or how special they are.
/datum/quirk
	var/name = "Incredible"
	var/display_name = "You're strange, however, you are just incredibly incredible."
	//var/rarity = 1.0

/datum/quirk/proc/equip(mob/human/H) // applied after everything else

/datum/quirk/weirdlook
	name = "Weird Look"
	display_name = "You look weird."

/datum/quirk/weirdlook/equip(mob/human/H)
	. = ..()
	var/r = rand(175, 255)
	var/g = rand(175, 255)
	var/b = rand(175, 255)
	
	H.color = rgb(r,g,b)

/datum/quirk/corponame
	name = "Corpo Name"
	display_name = "Your parents named you in honor of a high ranking CHEZ Group employee."

/datum/quirk/corponame/equip(mob/human/H)
	. = ..()
	var/gendero = "m"
	if(H.gender == FEMALE)
		gendero = "f"

	H.first_name = "[pick(world.file2list("strings/corporate_[gendero].txt"))]"
	H.name = "[H.first_name] [H.last_name]"

/datum/quirk/bloodybastard
	name = "Bloody Bastard"
	display_name = "Your blood pressure is double the normal rate, but you have enough to spare."

/datum/quirk/nolast
	name = "No Last Name"
	display_name = "Your mother was a Jukie."

/datum/quirk/nolast/equip(mob/human/H)
	. = ..()
	H.name = "[H.first_name]"