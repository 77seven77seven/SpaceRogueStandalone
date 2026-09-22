/obj/machine/pay
	name = "Paymachine"
	desc = "Only has two buttons. Hard to mess up."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "pay_machine"

/obj/machine/pay/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if((_x >= 11 && _x <= 14) && (_y >= 10 && _y <= 13))
		flick_overlay_view(image(src.icon, src, "confirm_pay"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		user.AdjustMoney(15)

		world << "confirm"
	else if((_x >= 19 && _x <= 22) && (_y >= 10 && _y <= 13))
		flick_overlay_view(image(src.icon, src, "ident_pay"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		world << "ident"