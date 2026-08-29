/obj/item/weapon
	name = "weapon"
	desc = "It's a weapon."
	var/sharp = FALSE // Is this weapon sharp? If false, it is classified as BLUNT.
					  // SHARP weapons are deadlier, and cause blood loss. BLUNT weapons are less deadly, but cause people to get knocked unconcsious, lose teeth and are generally better for pacifying people... So you can kill them.

	var/damage = 5
	var/bloodloss_coefficient = 1 // A sharp weapon would cause only as much blood loss overtime (BLOT) as the damage, this is the modifier
	
	var/attack_delay = 3 // Self explanatory. So you don't smack someone thirty times in a milisecond.