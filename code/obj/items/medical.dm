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

/obj/item/medical/pills
	name = "pills"
	desc = "A pill bottle. You're not sure what's inside, maybe if you knew something about medicine."

	var/med_name = "Unobtainium"
	var/med_desc = "Uh... you're still not sure, actually."

	desc_expansive_extra_skill = MEDI

	icon_state = "pills"
	dropshrink = 0.5

/obj/item/medical/pills/Initialize()
	. = ..()
	var/image/cap = image(src.icon, src, "cap")
	cap.color = get_random_light_color()
	overlays += cap

	desc_expansive = "I know! It's [med_name]. [med_desc]"

/obj/item/medical/pills/vitamins
	med_name = "Nosaphed"
	med_desc = "The day Nosaphed® was invented might go down in history as one of the greater moments of man. Nosaphed® brand vitamin supplements, enhances natural healing of the human body to a staggering degree."

	vendor_name = "NSFD"
	vendor_price = 25

/obj/item/medical/pills/magnesium
	med_name = "Magnesolam"
	med_desc = "A dietary supplement mostly used for helping people stay happier. Not an anti-depressant. Tread lightly."

	vendor_name = "MAGN"
	vendor_price = 25