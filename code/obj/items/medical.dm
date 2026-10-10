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
	
	if(!user.SkillRoll(MEDI, FALSE, target.IsOnBed() ? -20 : 0))
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

	var/pills_desc = "I don't feel anything."

	desc_expansive_extra_skill = MEDI

	icon_state = "pills"
	dropshrink = 0.5

/obj/item/medical/pills/use(mob/human/H)
	if(!H || !status_effect_type)
		return FALSE

	if(!H.ApplyStatusEffect(status_effect_type))
		return FALSE

	playsound(get_turf(H), 'sound/effects/human/medical/take_pills.ogg', 75, TRUE)
	if(prob(10))
		pills_desc = pick("It's hard to describe.","I don't know what's happening.")
	H.chat_info("I swallow the pills. <b>[pills_desc]</b>")
	
	destroyself(H)
	return TRUE

/obj/item/medical/pills/Initialize()
	. = ..()
	var/image/cap = image(src.icon, src, "cap")
	cap.color = get_random_bright_color()
	overlays += cap

	desc_expansive = "I know! It's [med_name]. [med_desc]"

/obj/item/medical/pills/vitamins
	med_name = "Nosaphed"
	med_desc = "The day Nosaphed® was invented might go down in history as one of the greater moments of man. Nosaphed® brand vitamin supplements, enhances natural healing of the human body to a staggering degree."
	status_effect_type = /datum/status_effect/vitamin_regeneration
	pills_desc = "This should help."

	vendor_name = "NSFD"
	vendor_price = 25

/obj/item/medical/pills/magnesium
	med_name = "Magnesolam"
	med_desc = "A dietary supplement mostly used for helping people stay happier. Not an anti-depressant. Tread lightly."
	status_effect_type = /datum/status_effect/magnesium_boost
	pills_desc = "This should help me stay happier."

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
	owner.Heal(rand(1,2))
	owner.AdjustHunger(rand(0,2))

/datum/status_effect/magnesium_boost
	duration = 30 SECONDS

/datum/status_effect/magnesium_boost/on_tick()
	owner.AdjustSorrow(rand(-1,-4))

/obj/item/medical/pills/antibiotics
	med_name = "Bioprofen"
	med_desc = "A broad-spectrum antibiotic that gradually suppresses infection. Rest and vitamins help prevent further infection."
	status_effect_type = /datum/status_effect/antibiotic_treatment
	pills_desc = "I hope this clears me up."

	vendor_name = "ANTI"
	vendor_price = 35

/datum/status_effect/antibiotic_treatment
	duration = 15 SECONDS
	tick_interval = 5 SECONDS

/datum/status_effect/antibiotic_treatment/on_tick()
	owner.AdjustInfection(-1)

/obj/item/medical/pills/neuroregenerative
	med_name = "Neurovance"
	med_desc = "A neuroregenerative course commonly used in improving brain health. Occasionaly also used recreationally by more wealthier individuals."
	status_effect_type = /datum/status_effect/neuroregeneration
	pills_desc = "This should help me think more clearly."

	vendor_name = "NEUR"
	vendor_price = 60

/datum/status_effect/neuroregeneration
	duration = 60 SECONDS
	tick_interval = 10 SECONDS

/datum/status_effect/neuroregeneration/on_tick()
	owner.AdjustBrainDamage(-1)
	owner.AdjustSorrow(-1)

/obj/item/medical/injector
	name = "medical injector"
	desc = "A medical injector. You're not sure what's inside, maybe if you knew something about medicine."
	var/med_name = "Unobtainium"
	var/med_desc = "Uh... you're still not sure, actually."

	var/inject_desc = "I don't feel anything."

	desc_expansive_extra_skill = MEDI

	icon_state = "injector"
	dropshrink = 0.7

/obj/item/medical/injector/Initialize()
	. = ..()
	var/image/stripe = image(src.icon, src, "injector_stripe")
	stripe.color = get_random_bright_color()
	overlays += stripe

	desc_expansive = "I know! It's [med_name]. [med_desc]"

/obj/item/medical/injector/use(mob/human/H)
	. = ..()
	return injectize(H, H)

/obj/item/medical/injector/attack(mob/human/user, mob/human/target)
	. = ..()
	return injectize(user, target)

/obj/item/medical/injector/proc/effect(mob/human/target)
	return

/obj/item/medical/injector/proc/injectize(mob/human/user, mob/human/target)
	if(!target || !user)
		return

	playsound(get_turf(target), 'sound/effects/human/medical/inject.ogg', 85, TRUE)
	
	if(!user.SkillRoll(MEDI, FALSE, target.IsOnBed() ? -20 : 0))
		target.AdjustSorrow(5)
		target.chat_info("I messed it up...","bad")
	else
		effect(target)

	junkize()

/obj/item/medical/injector/blood
	med_name = "Tranethamsylate"
	med_desc = "Alternative and arguably better shorter names exist, and those include... Tran, Etham, or even just Sylate. Injection causes the patient to experience extreme thirst, side effects include increased blood regeneration."

	vendor_name = "BLUD"
	vendor_price = 80

	inject_desc = "This feels weird..."

/obj/item/medical/injector/blood/effect(mob/human/target)
	. = ..()
	target.AdjustBlood(60)
	target.AdjustThirst(30)
	target.AdjustBleeding(-10) // You know, for kicks. Blood clotting, maybe?

/obj/item/medical/injector/bones
	med_name = "Osteogenitorix"
	med_desc = "Uses a wide variety of BMPs, BPM-7s, Chrysalins, assorted biomaterials and scaffolds mixed with PTH to rapidly speed up osteogenesis, basically healing fractures in a fraction of a second. It's a good thing Medicaloids aren't legally considered doctors, because you're pretty sure this thing is incredibly illegal."

	vendor_name = "FRAC"
	vendor_price = 90

	inject_desc = "OH NO! OH NO! OW! OWWWW! OWWWWWWWW!!!"

/obj/item/medical/injector/bones/effect(mob/human/target)
	. = ..()
	target.broke_bones = 0
	if(target.bleeding)
		target.AdjustBleeding(20)
		target.AdjustSorrow(10)
		target.TakeDamage(20, "osteogenitorix malpractice")

		target.ParseEmote("scream")
	target.AdjustHunger(30)
	target.AdjustSorrow(10)

	target.SetRagdolled(TRUE)
	target.go_blind()

	var/amplitude = min(8, (100 / 100) + 2)
	var/pixel_w_diff = rand(-amplitude, amplitude)
	var/pixel_z_diff = rand(-amplitude / 1.5, amplitude / 1.5)
	animate(target, pixel_w = pixel_w_diff, pixel_z = pixel_z_diff , time = 0.2 SECONDS, loop = 6, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_w = -pixel_w_diff , pixel_z = -pixel_z_diff , time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)

/obj/item/medical/injector/infection
	med_name = "Bacteriostat"
	med_desc = "Originally developed as a bioweapon, it was shown to be quite effective at stifling infection. And practically anything else in the vicinity of it."

	vendor_name = "BACT"
	vendor_price = 80

	inject_desc = "Eugh. It tingles."

/obj/item/medical/injector/infection/effect(mob/human/target)
	. = ..()
	target.AdjustInfection(-4)
	target.AdjustBlood(-15)