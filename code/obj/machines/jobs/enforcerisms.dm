/obj/item/mindsampler
	name = "THINKPOL Cogni-Wand"
	icon_state = "cogniwand"
	desc = "THINKPOL Cogni-Wands! \"See what they're REALLY thinking.\" I don't think you need to know much about corporate things to know these are incredibly unethical. Dissidence is a crime."
	desc_expansive = "The only reason you're even seeing these here is because of UN-ERC-#227. Cogni-Wands are used to extract the most important of psychological memories and ingrained behaviours and then cross-referenced with the ideal think patterns to determine if someone is a dissident."
	desc_expansive_extra_skill = CORP

	vendor_name = "THINK"
	vendor_price = 45

	var/cached // The initials of the scanned person in HEX	code.
	var/cached_sorrow // The amount of sorrow a person had upon being scanned. Having high sorrow means you're less likely to be detected.
	var/cached_dissidence = FALSE // Is the person stored a DISSIDENT?

/obj/item/mindsampler/junkize(mob/human/H)
	. = ..()
	icon_state = "[initial(icon_state)]-spent"

/obj/item/mindsampler/attack(mob/human/user, mob/human/target)
	. = ..()
	if(target.cmode)
		if(!user.SkillRoll(CORP, TRUE, 2))
			visible_message("[target] pulls away from the Cogni-Wand.")
			return
	if(!cached)
		if(user.SkillRoll(CORP))
			cached = text2hex("[target.first_name][target?.last_name]")
			cached_sorrow = target.sorrow
			cached_dissidence = target.mind?.dissident

			icon_state = "[initial(icon_state)]-loaded"
			name = "[initial(name)] ([random_capital_letter()]-[cached])"

			if(prob(90))
				// TODO: give target migraine, this is just a placeholder
				target.AdjustSorrow(rand(10,40))
				target.chat_info("AGH!! PAIN! PAIN! PAIN! WHY IS IT SO PAINFUL?!","bad")
	else
		user.chat_info("Unfortunately, these things aren't exactly reusable.","bad")

/obj/machine/terminal/enforcer
	name = "THINKPOL LAYLAW A48"
	desc = "Co-opt production with the WENDR product line."
	desc_expansive = "Used for checking the validity of Cogni-Wand samples."
	desc_expansive_extra_skill = CORP
	icon_state = "laptop"

	var/last_check = 0
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

	animate(whiteout, 15, alpha = 150, loop = -1)
	animate(time = 30, alpha = 0, easing = SINE_EASING|EASE_IN)