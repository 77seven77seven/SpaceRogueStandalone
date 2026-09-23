/obj/machine/pay
	name = "Paymachine"
	desc = "Only has two buttons. Hard to mess up."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "pay_machine"
	var/mob/human/identified
	var/atom/movable/whiteout

/obj/machine/pay/Initialize()
	. = ..()
	whiteout = new(src)
	whiteout.icon = src.icon
	whiteout.icon_state = "whiteout"
	whiteout.mouse_opacity = 0
	whiteout.layer = layer + 0.01
	whiteout.alpha = 0

	vis_contents += whiteout

/obj/machine/pay/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if((_x >= 11 && _x <= 14) && (_y >= 10 && _y <= 13))
		flick_overlay_view(image(src.icon, src, "confirm_pay"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		if(!identified)
			return

		var/adjus = user.mind.get_paycheck_amount()
		if(identified == user)
			if(adjus)
				playsound(get_turf(src), 'sound/effects/pda/scanner1.ogg', vol = 50)
				user.AdjustMoney(adjus)
				user.mind.nullify_paychecks()
			else
				user.chat_pda("CHEZ GROUP WOULD LIKE TO INFORM YOU THAT YOU DO NOT HAVE ANY STANDARD CURRENCY TO WITHDRAW FROM YOUR PAYSTUB ACCOUNT. PLEASE TRY NEXT TIME.")

		world << "confirm"
	else if((_x >= 19 && _x <= 22) && (_y >= 10 && _y <= 13))
		flick_overlay_view(image(src.icon, src, "ident_pay"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		if(user.mind.current_job)
			identified = user
			playsound(get_turf(src), 'sound/effects/obj/login.ogg', vol = 50)

			animate(whiteout, 3, alpha = 255, easing=QUAD_EASING|EASE_IN)
			animate(5, alpha = 0, easing=QUAD_EASING|EASE_IN)

			addtimer(CALLBACK(src, PROC_REF(reset_ident)), 3 SECONDS)
		else
			user.chat_pda("What?","bad")
		world << "ident"

/obj/machine/pay/proc/reset_ident()
	identified = null