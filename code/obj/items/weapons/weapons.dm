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
	
	var/attack_delay = 12 // Self explanatory. So you don't smeck someone thirty times in a milisecond.

/obj/item/melee/proc/GetMeleeSkill(mob/human/H)
	if(!istype(H) || !H.mind)
		return 0
	return clamp(H.mind.GetSkill(MELEE) || 0, 0, 100)

/obj/item/melee/attack(mob/human/user, mob/human/target)
	. = ..()
	if(user.on_cooldown("attack_cd"))
		return FALSE

	var/user_melee_skill = GetMeleeSkill(user)
	var/target_melee_skill = GetMeleeSkill(target)
	var/skill_adjusted_delay = max(4, attack_delay - user_melee_skill / 16)
	user.cooldown("attack_cd", skill_adjusted_delay)

	user.swing_anim(target, 8, 12, 1)

	if(target.client && target.client.movement_cooldown_until <= world.time)
		var/dodge_chance = min(20, 5 + target_melee_skill * 0.15)
		if(prob(dodge_chance) && !target.dead)
			target.chat_info("You dodge [user]'s [name].", "good")
			user.chat_info("[target] dodges your [name].", "bad")
			return FALSE

	var/damage_adjusted = damage + rand(-7,4) + (user_melee_skill * 0.08) - (target_melee_skill * 0.05)
	damage_adjusted = max(1, floor(damage_adjusted))

	var/amplitude = min(4, (damage/100) + 1)
	var/pixel_x_diff = ceil(rand(-amplitude, amplitude))
	var/pixel_y_diff = ceil(rand(-amplitude/3, amplitude/2))
	animate(target, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_x = -pixel_x_diff , pixel_y = -pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)

	target.TakeDamage(damage_adjusted, "[name]")
	world << "DEBUG: damage log, [damage_adjusted]"
	var/health_loss = 1 - (target.health / max(target.max_health, 1))
	var/ragdoll_chance = 5 + (user_melee_skill * 0.1) - (target_melee_skill * 0.1) + (health_loss * 20)
	ragdoll_chance = sharp ? clamp(ragdoll_chance * 0.2, 1, 5) : clamp(ragdoll_chance, 1, 25)
	if(!target.dead && !target.ragdolled && prob(ragdoll_chance))
		target.SetRagdolled(TRUE)

	if(sharp && prob(damage_adjusted * 9 + user_melee_skill * 0.1)) // SHARP WEAPONS!
		target.AdjustBleeding(damage_adjusted * bloodloss_coefficient)
		if(prob(10) && target.blood && !target.dead)
			target.bleed_effect()

		var/blood_prob = 45 + user_melee_skill * 0.2
		if(target.mind?.HasQuirk(/datum/quirk/bloodybastard))
			blood_prob *= 3
		if((prob(blood_prob) && target.blood) && !target.dead)
			target.bleed_effect()
			target.AdjustBlood(rand(-10,-1))
			new /atom/movable/blood/splatter(get_turf(target), target)
	else if(!sharp) // BLUNT WEAPONS!
		if(prob(rand(1,35) + user_melee_skill * 0.15))
			if(prob(damage_adjusted * 7 + user_melee_skill * 0.12))
				world << "DEBUG: bones proc'd"
				if(target.blood)
					new /atom/movable/blood/splatter(get_turf(target), target)

				if(target.broke_bones < target.bones)
					target.broke_bones++
					target.AdjustBleeding(rand(7,13))
					world << "DEBUG: bones broken: [target.broke_bones]/[target.bones]"
			else if(prob(damage_adjusted * 5 + user_melee_skill * 0.1))
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
	attack_delay = 6

/obj/item/melee/baton
	name = "baton"
	desc = "A baton. Commonly called a 'nightstick' in corporate environments. The word is said to come from them being mainly used at night, to secretly oppress innocent civilians."
	desc_expansive = "I know! It's a Standard Enforcement Melee Item template 12. A favorite of Sidereal Plexus official workers."
	desc_expansive_extra_skill = CORP

	inhand_icon_state = "baton"
	sharp = FALSE

	damage = 7
	attack_delay = 9