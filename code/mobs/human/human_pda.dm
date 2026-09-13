/mob/human/proc/chat_pda(msg, style="good")
	src << "<span class='[style]'>Your wristpad displays a message:</span>"
	src << "<span class='[style]' style='font-family:Verdana'>\"[uppertext(msg)]\"</span>\n"

	playsound('sound/effects/pda/pda_message.ogg', get_turf(src), vol = 50)

/mob/human/proc/chat_info(msg, style="good")
	src << "<span class='[style]' style='font-family:Verdana'>[msg]</span>"