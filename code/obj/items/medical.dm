/obj/item/medical
	icon = 'icons/obj/medical/items.dmi'

/obj/item/medical/bandage
	name = "bandage"
	desc = "Most commonly used to treat bleeding in bleeding patients. Usually has to be applied more than once."

	icon_state = "bandage"

	vendor_name = "BNDG"
	vendor_price = 20

/obj/item/medical/bandage/use(mob/human/H)
	. = ..()
	return bandagize(H, H)

/obj/item/medical/bandage/attack(mob/human/user, mob/human/target)
	. = ..()
	return bandagize(user, target)

/obj/item/medical/bandage/proc/bandagize(mob/human/user, mob/human/target)
	if(!target || !user)
		return

	var/medicine_skill = user?.mind?.GetSkill(MEDI) || 0
	var/bleeding_fix = clamp(7 + medicine_skill / 10, 3, 20)

	playsound(get_turf(target), 'sound/effects/human/medical/bandage.ogg', 85, TRUE)
	if(target.bleeding)
		target.AdjustBleeding(-bleeding_fix)
		target.chat_info("That helps.")
		if(target != user)
			user.chat_info("That should help them.")
	else
		user.chat_info("What?","bad")

	destroyself(user)

/obj/item/medical/splint
	name = "splint"
	desc = "A reinforced hardcloth medical item containing a hydrostatic regenerative gel that assists in osteogenesis."

	icon_state = "splint"

	vendor_name = "SPLT"
	vendor_price = 25

/obj/item/medical/splint/use(mob/human/H)
	. = ..()
	return splintize(H, H)

/obj/item/medical/splint/attack(mob/human/user, mob/human/target)
	. = ..()
	return splintize(user, target)

/obj/item/medical/splint/proc/splintize(mob/human/user, mob/human/target)
	if(!target || !user)
		return

	playsound(get_turf(target), 'sound/effects/human/medical/bandage.ogg', 85, TRUE)

	if(!user.SkillRoll(MEDI))
		target.AdjustSorrow(1)
		return

	if(target.broke_bones)
		target.broke_bones = max(0, target.broke_bones - 1)
		target.chat_info("That helps.")
		if(target != user)
			user.chat_info("That should help them.")
	else
		user.chat_info("What?","bad")

	destroyself(user)

/obj/item/medical/pills
	name = "pills"
	desc = "A pill bottle. You're not sure what's inside, maybe if you knew something about medicine."

	var/med_name = "Unobtainium"
	var/med_desc = "Uh... you're still not sure, actually."
	var/status_effect_type

	var/pills_desc = "You don't feel anything."

	desc_expansive_extra_skill = MEDI

	icon_state = "pills"
	dropshrink = 0.5

/obj/item/medical/pills/use(mob/human/H)
	if(!H || !status_effect_type)
		return FALSE

	if(!H.ApplyStatusEffect(status_effect_type))
		return FALSE

	playsound(get_turf(H), 'sound/effects/human/medical/take_pills.ogg', 75, TRUE)
	if(prob(40))
		pills_desc = pick("It's hard to describe.","I don't know what's happening.")
	H.chat_info("I swallow the pills. <b>[pills_desc]</b>")
	
	destroyself(H)
	return TRUE

/obj/item/medical/pills/Initialize()
	. = ..()
	var/image/cap = image(src.icon, src, "cap")
	cap.color = get_random_light_color()
	overlays += cap

	desc_expansive = "I know! It's [med_name]. [med_desc]"

/obj/item/medical/pills/vitamins
	med_name = "Nosaphed"
	med_desc = "The day Nosaphed® was invented might go down in history as one of the greater moments of man. Nosaphed® brand vitamin supplements, enhances natural healing of the human body to a staggering degree."
	status_effect_type = /datum/status_effect/vitamin_regeneration

	vendor_name = "NSFD"
	vendor_price = 25

/obj/item/medical/pills/magnesium
	med_name = "Magnesolam"
	med_desc = "A dietary supplement mostly used for helping people stay happier. Not an anti-depressant. Tread lightly."
	status_effect_type = /datum/status_effect/magnesium_boost

	vendor_name = "MAGN"
	vendor_price = 25

/datum/status_effect
	var/mob/human/owner
	var/duration = 0
	var/tick_interval = 5 SECONDS
	var/remaining_duration = 0
	var/time_until_tick = 0

/datum/status_effect/New(mob/human/new_owner)
	. = ..()
	owner = new_owner
	remaining_duration = duration
	time_until_tick = tick_interval

/datum/status_effect/proc/Refresh()
	remaining_duration = duration
	time_until_tick = tick_interval

/datum/status_effect/proc/Advance(elapsed)
	if(!owner || owner.dead || duration <= 0 || tick_interval <= 0)
		qdel(src)
		return FALSE

	var/old_remaining_duration = remaining_duration
	remaining_duration -= elapsed
	time_until_tick -= elapsed
	while(time_until_tick <= 0)
		var/tick_elapsed = elapsed + time_until_tick
		if(tick_elapsed > old_remaining_duration)
			break
		on_tick()
		time_until_tick += tick_interval

	if(remaining_duration <= 0)
		qdel(src)
	return TRUE

/datum/status_effect/proc/on_tick()
	return

/datum/status_effect/Destroy(force = FALSE)
	if(owner?.status_effects)
		owner.status_effects -= src
	owner = null
	return ..()

/datum/status_effect/vitamin_regeneration
	duration = 60 SECONDS

/datum/status_effect/vitamin_regeneration/on_tick()
	owner.Heal(2)
	owner.AdjustHunger(1)

/datum/status_effect/magnesium_boost
	duration = 30 SECONDS

/datum/status_effect/magnesium_boost/on_tick()
	owner.AdjustSorrow(-4)