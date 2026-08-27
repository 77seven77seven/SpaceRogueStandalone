/obj/Click(location, control, params)
	if(!usr || !usr.client)
		return FALSE
	. = ..()
	var/mob/user = usr

	if(Adjacent(user))	
		interact(user)
	
/obj/proc/interact(user)
	return