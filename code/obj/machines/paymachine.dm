/obj/machine/pay
	name = "EIPA Withdrawal Machine"
	desc = "The place where the average employee gets his paycheck. Press the <font color='blue'>BLUE</font> button to identify yourself, and the <font color='green'>GREEN</font> button to withdraw."
	desc_expansive = "The Employment Income Private Account withdrawal machine is linked to the CS&INB banking network to ensure all employees of CHEZ Group are easily paid. The machine was not manufactured by CHEZ, and it is instead being actively rented from Bluline Tech."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "pay_machine"
	var/mob/human/identified
	var/atom/movable/whiteout

	var/icon/overlay

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
			playsound(get_turf(src), 'sound/effects/pda/scanner0.ogg', vol = 50)

			whiteout.color = "#ff0000"
			animate(whiteout, 0.5, alpha = 255)
			animate(alpha = 0, time = 5)
			return

		var/adjus = user.mind.get_paycheck_amount()
		if(identified == user)
			if(adjus)
				playsound(get_turf(src), 'sound/effects/pda/scanner1.ogg', vol = 50)
				user.AdjustMoney(adjus)
				user.mind.nullify_paychecks()

				whiteout.color = "#646682"
				animate(whiteout, 0.5, alpha = 255)
				animate(alpha = 0, time = 5)
			else
				user.chat_pda("CHEZ GROUP WOULD LIKE TO INFORM YOU THAT YOU DO NOT HAVE ANY STANDARD CURRENCY TO WITHDRAW FROM YOUR PAYSTUB ACCOUNT. PLEASE TRY NEXT TIME.", "bad")
				
	else if((_x >= 19 && _x <= 22) && (_y >= 10 && _y <= 13))
		flick_overlay_view(image(src.icon, src, "ident_pay"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		if(user.mind.current_job)
			identified = user
			playsound(get_turf(src), 'sound/effects/obj/login.ogg', vol = 50)

			whiteout.color = null
			animate(whiteout, 0.5, alpha = 255)
			animate(alpha = 0, time = 5)

			get_portrait(user)

			addtimer(CALLBACK(src, PROC_REF(reset_ident)), 3 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
		else
			user.chat_pda("What?","bad")

/obj/machine/pay/proc/get_portrait(mob/human/H)
	var/icon/I = getFlatIcon(H, SOUTH)
	if(I)
		var/icon/blend = icon(icon='icons/human/masking.dmi', icon_state="credits")
		I.Blend(blend, ICON_MULTIPLY)
		I.Scale(25,25)

		var/mutable_appearance/MA = new /mutable_appearance(I)
		MA.pixel_x = 4
		MA.pixel_y = 2

		overlay = MA
		overlays += overlay

/obj/machine/pay/proc/reset_ident()
	identified = null
	overlay = null

	whiteout.color = null
	animate(whiteout, 1, alpha = 255)
	spawn(1) overlays.Cut()
	animate(alpha = 0, time = 2)