/obj/machine/vendor
	name = "WENDR"
	desc = ""

	icon = 'icons/obj/terminals.dmi'
	icon_state = "vend"

	density = TRUE
	opacity = FALSE
	
	var/list/items = list()
	var/jammed = FALSE

/obj/machine/vendor/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if((_x >= 15 && _x <= 18) && (_y >= 12 && _y <= 15))
		flick_overlay_view(image(src.icon, src, "confirm"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)
		
		world << "confirm"
	else if((_x >= 11 && _x <= 13) && (_y >= 12 && _y <= 15))
		flick_overlay_view(image(src.icon, src, "left"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		world << "left"
	else if((_x >= 20 && _x <= 22) && (_y >= 12 && _y <= 15))
		flick_overlay_view(image(src.icon, src, "right"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		world << "right"

/obj/machine/vendor/wall
	density = FALSE
	icon_state = "vend_wall"