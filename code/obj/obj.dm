/obj/Click(location, control, params)
	if(!usr || !usr.client)
		return FALSE
	. = ..()
	var/mob/user = usr

	if(Adjacent(user))
		if(ishuman(user))
			var/mob/human/H = user
			interact(H, H.holding)
		else
			interact(user)
	
/obj/proc/interact(mob/user, obj/item/held_item)
	return