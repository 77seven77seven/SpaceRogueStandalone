/obj/machine/microphone
	name = "mikrak"
	desc = "Connected directly to the station's PA system. Colloquially called a 'mikrak', we all know it is just a microphone though."
	
	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "microphone"
	
	var/on = FALSE

/obj/machine/microphone/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][on]"

/obj/machine/microphone/interact(mob/user, obj/item/held_item, params)
	. = ..()
	on = !on
	icon_state = "[initial(icon_state)][on]"

	playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)
	if(on)
		var/sund = pick('sound/effects/announce/micfeedback1.ogg','sound/effects/announce/micfeedback2.ogg')
		for(var/mob/human/H in station.humans)
			if(is_stationbound(H))
				H.playsound_local(get_turf(src), sund, 100)

/obj/machine/microphone/proc/speak_into(msg)
	if(msg)
		chat_announce(uppertext(msg))