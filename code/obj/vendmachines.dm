/obj/vendor
	name = "WENDR"
	desc = ""

	icon = 'icons/obj/vendor.dmi'
	icon_state = "vend"

	density = TRUE
	opacity = FALSE

	var/image/button
	
	var/list/items = list()
	var/jammed = FALSE

/obj/vendor/Initialize()
	. = ..()
	button = image(src.icon)
	overlays += button

/obj/vendor/interact(mob/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if((_x >= 15 && _x <= 18) && (_y >= 12 && _y <= 18))
		flick("confirm",button)
		world << "confirm"

/obj/vendor/wall
	density = FALSE
	icon_state = "vend_wall"