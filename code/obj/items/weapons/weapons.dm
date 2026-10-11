/obj/item/melee
	name = "weapon"
	desc = "It's a weapon."
	inhand_icon = 'icons/human/inhands/melee.dmi'
	inhand_icon_state = "crowbar"
	harmful = TRUE

	var/sharp = FALSE // Is this weapon sharp? If false, it is classified as BLUNT.
					  // SHARP weapons are deadlier, and cause blood loss. BLUNT weapons are less deadly, but cause people to get knocked unconcsious, lose teeth and are generally better for pacifying people... So you can kill them.

	var/damage = 5
	var/bloodloss_coefficient = 0.6 // A sharp weapon would cause only as much blood loss overtime (BLOT) as the damage if this were 1, this is the modifier.
	
	var/attack_delay = 25 // Self explanatory. So you don't smeck someone thirty times in a milisecond.

/obj/item/melee/attack(mob/human/user, mob/human/target) // TODO: make a lot of these be affected by melee skill, both on defense and offense
	. = ..()
	if(user.on_cooldown("attack_cd"))
		return FALSE
	user.cooldown("attack_cd", attack_delay)

	user.swing_anim(target, 8, 12, 1)

	var/damage_adjusted = damage
	damage_adjusted += rand(-3,4)

	var/amplitude = min(4, (damage/100) + 1)
	var/pixel_x_diff = ceil(rand(-amplitude, amplitude))
	var/pixel_y_diff = ceil(rand(-amplitude/3, amplitude/2))
	animate(target, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_x = -pixel_x_diff , pixel_y = -pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)

	target.TakeDamage(damage_adjusted, "[name]")
	world << "DEBUG: damage log, [damage_adjusted]"
	if(sharp && prob(damage_adjusted * 9)) // SHARP WEAPONS!
		target.AdjustBleeding(damage_adjusted * bloodloss_coefficient)
		if(prob(10) && target.blood && !target.dead)
			target.bleed_effect()

		var/blood_prob = 45
		if(target.mind?.HasQuirk(/datum/quirk/bloodybastard))
			blood_prob *= 3
		if((prob(blood_prob) && target.blood) && !target.dead)
			target.bleed_effect()
			target.AdjustBlood(rand(-10,-1))
			new /atom/movable/blood/splatter(get_turf(target), target)
	else if(!sharp) // BLUNT WEAPONS!
		if(prob(rand(1,35)))
			if(prob(damage_adjusted * 7))
				world << "DEBUG: bones proc'd"
				if(target.blood)
					new /atom/movable/blood/splatter(get_turf(target), target)

				if(target.broke_bones < target.bones)
					target.broke_bones++
					target.AdjustBleeding(rand(7,13))
					world << "DEBUG: bones broken: [target.broke_bones]/[target.bones]"
			else if(prob(damage_adjusted * 5))
				if(!target.dead && prob(clamp(damage_adjusted * 2, 1, 20)))
					target.AdjustBrainDamage(rand(1,3))
				else
					world << "DEBUG: teeth proc'd"
					target.AdjustBleeding(rand(1,3))
					target.chat_info("MY TEETH!","bad")
					// teeth knock out logic

/obj/item/melee/knife
	name = "knife"
	inhand_icon_state = "knife"
	sharp = TRUE
	attack_delay = 15