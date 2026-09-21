/mob/human/proc/chat_pda(msg, style="good")
	src << "<span class='[style]'>Your wristpad displays a message:</span>"
	src << "<span class='[style]' style='font-family:Verdana'>\"[uppertext(msg)]\"</span>\n"

	playsound(get_turf(src), 'sound/effects/pda/pda_message.ogg', 50, FALSE, -3)

/mob/human/proc/chat_info(msg, style="good")
	src << "<span class='[style]' style='font-family:Verdana'>[msg]</span>"