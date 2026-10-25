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

/datum/quirk/veteran
	name = "Veteran"
	display_name = "You're a veteran of the Ganymede Civil War."

/datum/quirk/veteran/equip(mob/human/H)
	. = ..()
	H.mind.mental_state = MENTAL_STATE_DESENSITIZED

/datum/quirk/snack
	name = "Snack"
	display_name = "You brought a snack."

/datum/quirk/snack/equip(mob/human/H)
	. = ..()
	var/eaaa = subtypesof(/obj/item/consumable/food)
	var/fuck = pick(eaaa)
	H.inventory += new fuck(H)

/datum/quirk/wounds
	name = "Wounds"
	display_name = "You have some left-over wounds."

/datum/quirk/wounds/equip(mob/human/H)
	. = ..()
	H.TakeDamage(rand(10,30), "wounds quirk")

/datum/quirk/alone
	name = "Isolationist"
	display_name = "You don't mind being alone."

/datum/quirk/crowds
	name = "Crowds"
	display_name = "You don't like crowds."

/datum/quirk/dontcarehurt
	name = "Don't Care"
	display_name = "You don't mind getting hurt."

/datum/quirk/fighter
	name = "Fighter"
	display_name = "You know how to use your fists."

/datum/quirk/dishonest
	name = "Dishonest Fighter"
	display_name = "You're a dishonest fighter."

/datum/quirk/medicine
	name = "Medicine"
	display_name = "You know a bit about medicine."

/datum/quirk/medicine/equip(mob/human/H)
	. = ..()
	H.mind.AddSkill(MEDI, rand(40,60))

/datum/quirk/melee
	name = "Melee"
	display_name = "You know how to fight."

/datum/quirk/melee/equip(mob/human/H)
	. = ..()
	H.mind.AddSkill(MELEE, rand(40,60))

/datum/quirk/guns
	name = "Guns"
	display_name = "Hey man, nice shot."

/datum/quirk/guns/equip(mob/human/H)
	. = ..()
	H.mind.AddSkill(GUNS, rand(40,60))

/datum/quirk/paranoia
	name = "Paranoid"
	display_name = "AAGH! Oh, didn't see you there."

/datum/quirk/paranoia/equip(mob/human/H)
	. = ..()
	H.mind.AddSkill(PARANOIA, rand(40,60))

/datum/quirk/dodger
	name = "Dodger"
	display_name = "You've always had faster reflexes."

/datum/quirk/footing
	name = "Steady Footing"
	display_name = "You've always had steady footing."

/datum/quirk/randomlaughs
	name = "Random Laughs"
	display_name = "You're a funny little guy, in a funny little world."

/datum/quirk/psycho
	name = "Psycho"
	display_name = "They always told you that 'something' in your head was wrong."

/datum/quirk/psycho/equip(mob/human/H)
	. = ..()
	H.mind.mental_state = MENTAL_STATE_PSYCHO

/datum/quirk/someonehasdied
	name = "Someone Has Died"
	display_name = "You've purchased CHEZ Group's premium life insurance policy."