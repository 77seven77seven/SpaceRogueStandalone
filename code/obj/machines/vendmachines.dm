/obj/machine/vendor
	name = "WENDR"
	desc = ""

	icon = 'icons/obj/terminals.dmi'
	icon_state = "vend"

	density = TRUE
	opacity = FALSE
	
	var/list/items = list()
	var/jammed = FALSE

/obj/machine/vendor

/obj/machine/vendor/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if((_x >= 30 && _x <= 36) && (_y >= 24 && _y <= 30))
		flick_overlay_view(image(src.icon, src, "confirm"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)
	else if((_x >= 22 && _x <= 26) && (_y >= 24 && _y <= 30))
		flick_overlay_view(image(src.icon, src, "left"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)
	else if((_x >= 40 && _x <= 44) && (_y >= 24 && _y <= 30))
		flick_overlay_view(image(src.icon, src, "right"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

/obj/machine/vendor/wall
	density = FALSE
	icon_state = "vend_wall"