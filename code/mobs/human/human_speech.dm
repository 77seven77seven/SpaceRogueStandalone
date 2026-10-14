#define VOICE_BLIP_SOUND        'sound/blip.wav' // generic sound, override if needed :)
#define VOICE_BASE_FREQUENCY    44100
#define VOICE_PITCH_MIN         0.3
#define VOICE_PITCH_MAX         0.65
#define VOICE_JITTER            0.06
#define VOICE_BLIP_EVERY        2
#define VOICE_BLIP_VOLUME       40
#define VOICE_TYPE_SPEED        0.6
#define VOICE_BUBBLE_LINGER     15
#define VOICE_HEAR_RANGE        7
#define VOICE_BUBBLE_WIDTH      128

/mob/human
	var/voice_file = VOICE_BLIP_SOUND
	var/voice_freq    = 0
	var/voice_channel = 0
	var/voice_seq     = 0
	var/voice_color   = "white"

	var/atom/movable/voice_bubble
	var/atom/movable/emote_bubble

// ---- Deterministic string hash (djb2-style, masked to stay float-exact) ----
/proc/TextHash(text)
	. = 5381
	for(var/i = 1, i <= length(text), i++)
		. = (. * 33 + text2ascii(text, i)) & 0xFFFFFF
	return .

/mob/human/proc/GenerateVoice()
	var/seed_text = "[first_name] [last_name]"
	if(!seed_text || !length(seed_text))
		seed_text = "[ckey]"
	var/seed = TextHash(seed_text)
	var/min_pitch = VOICE_PITCH_MIN
	var/max_pitch = VOICE_PITCH_MAX
	if(gender == MALE)
		min_pitch = 0.22
		max_pitch = 0.52
	else if(gender == FEMALE)
		min_pitch = 0.38
		max_pitch = 0.7
	var/spread = max_pitch - min_pitch
	voice_freq = min_pitch + ((seed % 1000) / 1000) * spread
	voice_channel = 1 + (seed % 1024)

/atom/movable/bubble
	maptext_width = VOICE_BUBBLE_WIDTH
	layer = MOB_LAYER + 0.5
	maptext = ""

/mob/human/verb/speak()
	set name = ".speak"

	if(dead || !client)
		return FALSE

	var/timer = world.time + 60
	var/msg = input(src, null, null) as null|text

	var/first_char = copytext_char(msg, 1, 2)

	if(msg || msg != "")
		msg = trim(copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN))
		if(first_char == "*")
			if(on_cooldown("emote"))
				return FALSE
			ParseEmote(copytext_char(msg, 2))
		else
			var/whispering = FALSE
			if(first_char == "+" || first_char == "#")
				whispering = TRUE
				msg = copytext_char(msg, 2)
			msg = SanitizeSpeech(msg)
			msg = punctualize(capitalize(msg))
			AnimatedSpeech(msg, do_bubble = !whispering, whispering = whispering)
	else
		if(world.time > timer)
			for(var/mob/M in viewers(world.view, src))
				if(istype(M, /mob/lobbyman))
					continue
				if(M.deaf)
					continue
				if(M.client)
					var/icon/I = getFlatIcon(src, SOUTH)
					M << "\icon[I] <b>[src]</b> wanted to say something, but \he changed \his mind."

/mob/human/proc/AnimatedSpeech(message, sound_path = voice_file, pitch_override, do_bubble = TRUE, whispering = FALSE)
	set waitfor = FALSE
	if(!message || !length(message))
		return
	if(!voice_freq)
		GenerateVoice()

	var/hear_range = VOICE_HEAR_RANGE

	var/pitch = pitch_override || voice_freq
	var/my_seq = ++voice_seq

	if(whispering)
		hear_range = floor(hear_range / 2)

	for(var/mob/M in hearers(hear_range, src))
		if(istype(M, /mob/lobbyman))
			continue
		if(M.deaf)
			continue
		if(M.client)
			var/icon/I = getFlatIcon(src, SOUTH)
			M << "\icon[I] <b>[first_name] [last_name]</b> : \"<span style='color:[voice_color];font-family:Verdana;font-size: [whispering ? "75%" : "100%"]'>[message]</span>\""

	var/obj/machine/microphone/mic = locate() in get_turf(src)
	if(mic && mic?.on)
		mic.speak_into(message)

	if(!do_bubble)
		return

	if(voice_bubble)
		vis_contents -= voice_bubble

	var/mtet
	WXH_TO_HEIGHT(client.MeasureText(message, null, VOICE_BUBBLE_WIDTH), mtet)

	var/atom/movable/bubble/bubble = new()
	bubble.maptext_height = mtet
	bubble.maptext_x = (VOICE_BUBBLE_WIDTH - bound_width) * -0.5
	bubble.pixel_y = bound_height * 0.95
	bubble.appearance_flags = KEEP_APART|RESET_TRANSFORM

	voice_bubble = bubble
	vis_contents += bubble

	message = html_decode(message)

	var/shown = ""
	var/blip_count = 0
	for(var/i = 1, i <= length_char(message), i++)
		if(voice_seq != my_seq)
			vis_contents -= bubble
			if(voice_bubble == bubble)
				voice_bubble = null
			return

		var/ch = copytext_char(message, i, i + 1)
		shown += ch

		bubble.maptext = "<span style='color:[voice_color];background-color: #23232391;text-align:center;font-family:Verdana;font-size:14px'>[shown]</span>"

		if(ch != " " && ch != "\n")
			blip_count++
			if(blip_count % VOICE_BLIP_EVERY == 0)
				PlayBlip(pitch, sound_path)

		sleep(VOICE_TYPE_SPEED)

	voice_bubble.loc = get_turf(src)
	vis_contents -= bubble
	animate(voice_bubble, VOICE_BUBBLE_LINGER, alpha = 10,  maptext_y = 20)
	sleep(VOICE_BUBBLE_LINGER)
	QDEL_NULL(bubble)
	if(voice_seq == my_seq)
		if(voice_bubble == bubble)
			voice_bubble = null

// EMOTES

/mob/human/proc/ParseEmote(emote)
	switch(emote)
		if("gasp" || "gasps")
			var/file = 'sound/effects/human/gasp_male.ogg'
			if(gender == FEMALE)
				file = 'sound/effects/human/gasp_female.ogg'
			AnimatedEmote("gasps!", file)
		if("scream" || "screams")
			var/file = 'sound/effects/human/scream_male.ogg'
			if(gender == FEMALE)
				file = 'sound/effects/human/scream_female.ogg'
			AnimatedEmote("screams!", file)
		if("laugh" || "laughs")
			var/file = 'sound/effects/human/laugh_male.ogg'
			if(gender == FEMALE)
				file = 'sound/effects/human/laugh_female.ogg'
			AnimatedEmote("laughs!", file)
		if("hem" || "hems")
			var/file = 'sound/effects/human/hem_male.ogg'
			if(gender == FEMALE)
				file = 'sound/effects/human/hem_female.ogg'
			AnimatedEmote("hems.", file)
		if("cough" || "coughs")
			var/file = 'sound/effects/human/cough_male.ogg'
			if(gender == FEMALE)
				file = 'sound/effects/human/cough_female.ogg'
			AnimatedEmote("coughs.", file)
		if("clap" || "claps")
			AnimatedEmote("claps.", 'sound/effects/human/clap.ogg')
		if("sob" || "sobs")
			AnimatedEmote("sobs.", 'sound/effects/human/sob.ogg')
		else
			AnimatedEmote(emote)

/mob/human/proc/AnimatedEmote(message, sound_path = 'sound/effects/human/generic_emote.ogg')
	set waitfor = FALSE
	if(!message || !length(message) || !client)
		return

	if(emote_bubble)
		vis_contents -= emote_bubble

	cooldown("emote", 5 SECONDS)

	var/mtet
	WXH_TO_HEIGHT(client.MeasureText(message, null, VOICE_BUBBLE_WIDTH), mtet)

	var/atom/movable/bubble/bubble = new()
	bubble.maptext_height = mtet
	bubble.maptext_x = (VOICE_BUBBLE_WIDTH - bound_width) * -0.5
	bubble.pixel_y = bound_height * 0.95

	emote_bubble = bubble
	vis_contents += bubble

	var/adjusted_message = "[first_name] [last_name] [message]"
	bubble.maptext = "<span style='color:[voice_color];-dm-text-outline: 2px #23232391;text-align:center;font-size:13px'>[adjusted_message]</span>"

	emote_bubble.loc = get_turf(src)
	vis_contents -= bubble

	if(sound_path)
		playsound(get_turf(src), sound_path, 75)

	animate(emote_bubble, 25, alpha = 0, maptext_y = 20)
	sleep(25)
	QDEL_NULL(bubble)
	if(emote_bubble == bubble)
		emote_bubble = null

/mob/human/proc/PlayBlip(pitch, sound_path)
	var/wobble = 1 + (rand(-100, 100) * 0.01 * VOICE_JITTER)
	var/freq = VOICE_BASE_FREQUENCY * pitch * wobble

	playsound(get_turf(src), sound_path, VOICE_BLIP_VOLUME, frequency = freq, channel = voice_channel)