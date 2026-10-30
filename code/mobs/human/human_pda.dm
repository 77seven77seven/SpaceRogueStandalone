/mob/human/proc/chat_pda(msg, style="good", silent = FALSE)
	src << "<span class='[style] small'>Your wristpad displays a message:</span>"
	src << "<span class='[style]' style='font-family:Verdana'>\"[uppertext(msg)]\"</span>\n"

	if(!silent)
		playsound(get_turf(src), 'sound/effects/pda/pda_message.ogg', 50, FALSE, -3)

/mob/human/proc/chat_info(msg, style="good")
	src << "<span class='[style]' style='font-family:Verdana'>[msg]</span>"

/proc/chat_announce(msg, style="good", sound/optional_sound)
	station.speakertower.do_blip()
	for(var/mob/human/H in station.humans)
		if(is_stationbound(H))
			H << "<span class='[style]'>You hear a loud booming voice echoing through the halls:</span>"
			H << "<span class='[style]' style='font-family:Verdana'>\"[uppertext(msg)]\"</span>\n"

			if(optional_sound)
				H.playsound_local(get_turf(src), 'sound/effects/announce/announce.ogg', 75)
				spawn(1) H.playsound_local(get_turf(src), optional_sound, 100)
			else
				H.playsound_local(get_turf(src), 'sound/effects/announce/announce.ogg', 100)

