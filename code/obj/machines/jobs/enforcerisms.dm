/obj/item/mindsampler
	name = "cogniwand"
	icon_state = "cogniwand"

	inhand_icon = 'icons/human/inhands/melee.dmi'
	inhand_icon_state = "cogniwand"
	desc = "THINKPOL Cogni-Wands! \"Dissidence is a crime.\""
	desc_expansive = "The only reason you're even seeing these here is because of UN-ERC-#227. Cogni-Wands are used to extract the most important of psychological memories and ingrained behaviours and then cross-referenced with the ideal think patterns to determine if someone is a dissident."
	desc_expansive_extra_skill = CORP

	vendor_name = "THINK"
	vendor_price = 45

	var/cached // The initials of the scanned person in HEX	code.
	var/mob/human/cached_scanned
	var/cached_sorrow // The amount of sorrow a person had upon being scanned. Having high sorrow means you're less likely to be detected.
	var/cached_dissidence = FALSE // Is the person stored a DISSIDENT?

/obj/item/mindsampler/junkize(mob/human/H)
	. = ..()
	icon_state = "[initial(icon_state)]-spent"
	inhand_icon_state = "baton"

/obj/item/mindsampler/attack(mob/human/user, mob/human/target)
	. = ..()
	user.swing_anim(target, 16, 0, 1)

	if(target.cmode)
		if(!user.SkillRoll(CORP, TRUE, 2) || (prob(10) && target.mind?.HasQuirk(/datum/quirk/sensitive)))
			var/icon/I = getFlatIcon(target, SOUTH)
			visible_message("\icon[I] <b>[target]</b> pulls away from the Cogni-Wand.", center = get_turf(target))
			return
	if(!cached)
		if(user.SkillRoll(CORP))
			cached = text2hex("[target.first_name][target?.last_name]")
			cached_scanned = target
			cached_sorrow = target.sorrow
			cached_dissidence = target.mind?.dissident

			icon_state = "[initial(icon_state)]-loaded"
			inhand_icon_state = "[initial(icon_state)]-loaded"
			user.UpdateInhand()

			name = "[initial(name)] ([random_capital_letter()]-[cached])"

			if(target.client)
				animate(target?.client, color = "#b1abddff", easing = SINE_EASING | EASE_IN | EASE_OUT, time = 2)
				spawn(2) animate(target?.client, color = "#ffffff", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 2)

			var/icon/icon_target = getFlatIcon(target, SOUTH)
			var/icon/icon_user = getFlatIcon(user, SOUTH)
			visible_message("\icon[icon_user] <b>[user]</b> scans \icon[icon_target] <b>[target]</b> with the Cogni-Wand.", center = get_turf(target))
			playsound(get_turf(user), 'sound/effects/obj/scancogni.ogg', 85, TRUE, -2)

			if(prob(90))
				// TODO: give target migraine, this is just a placeholder
				target.AdjustSorrow(rand(5,20))
				if(prob(20) || target.mind?.HasQuirk(/datum/quirk/sensitive))
					target.chat_info("AGH!! PAIN! PAIN! PAIN! WHY IS IT SO PAINFUL?!","bad")
					target.AdjustSorrow(rand(5,10))
	else
		user.chat_info("Unfortunately, these things aren't exactly reusable.","bad")

/obj/machine/terminal/enforcer
	name = "THINKPOL LAYLAW A68"
	desc = "Co-opt production with the WENDR product line."
	desc_expansive = "Used for checking the validity of Cogni-Wand samples."
	desc_expansive_extra_skill = CORP
	icon_state = "laptop"

	var/last_check = 0
	var/busy = FALSE
	var/atom/movable/whiteout

/obj/machine/terminal/enforcer/Initialize()
	. = ..()
	whiteout = new(src)
	whiteout.icon = src.icon
	whiteout.icon_state = "computer-whiteout"
	whiteout.mouse_opacity = 0
	whiteout.layer = layer + 0.01
	whiteout.alpha = 0

	whiteout.color = "#97B7EF"

	vis_contents += whiteout

	animate(whiteout, 15, alpha = 150, loop = -1, flags = ANIMATION_PARALLEL)
	animate(time = 30, alpha = 0, easing = SINE_EASING|EASE_IN)

/obj/machine/terminal/enforcer/interact(mob/user, obj/item/held_item, params)
	. = ..()
	if(held_item)
		if(busy)
			return
		if(istype(held_item, /obj/item/mindsampler))
			for(var/mob/human/H in station.humans)
				if(is_stationbound(H))
					H.playsound_local(get_turf(src), 'sound/effects/obj/cogniscan.ogg', 50)
			var/obj/item/mindsampler/MS = held_item
			var/is_dissident = MS.cached_dissidence
			if(prob(MS.cached_sorrow / 1.67))
				is_dissident = FALSE
			MS.junkize(user)
			whiteout.color = "#ffffff"
			whiteout.icon_state = "computer-buffer"

			busy = TRUE

			addtimer(CALLBACK(src, PROC_REF(DoResult), is_dissident), 13 SECONDS)

/obj/machine/terminal/enforcer/proc/DoResult(is_dissident)
	if(is_dissident)
		whiteout.color = "#7e3830"
		// TODO: Dissidence wanted logic here.
	else
		whiteout.color = "#aeea77"
	whiteout.icon_state = "computer-whiteout"

	sleep(3 SECONDS)
	whiteout.icon_state = "computer-buffer"

	addtimer(CALLBACK(src, PROC_REF(unbusy)), 20 SECONDS)

/obj/machine/terminal/enforcer/proc/unbusy()
	whiteout.icon_state = "computer-whiteout"
	whiteout.color = "#97B7EF"