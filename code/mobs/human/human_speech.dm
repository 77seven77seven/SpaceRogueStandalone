#define VOICE_BLIP_SOUND        'sound/blip.wav'
#define VOICE_BASE_FREQUENCY    44100
#define VOICE_PITCH_MIN         0.3
#define VOICE_PITCH_MAX         0.65
#define VOICE_JITTER            0.06
#define VOICE_BLIP_EVERY        2
#define VOICE_BLIP_VOLUME       40
#define VOICE_TYPE_SPEED        0.6
#define VOICE_BUBBLE_LINGER     15
#define VOICE_HEAR_RANGE        7
#define VOICE_BUBBLE_WIDTH      96

/mob/human
	var/voice_freq    = 0
	var/voice_channel = 0
	var/voice_seq     = 0
	var/voice_color   = "white"
	var/atom/movable/voice_bubble

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
	var/spread = VOICE_PITCH_MAX - VOICE_PITCH_MIN
	voice_freq = VOICE_PITCH_MIN + ((seed % 1000) / 1000) * spread
	voice_channel = 1 + (seed % 1024)

/mob/human/proc/VoiceBlip(message, sound_path = VOICE_BLIP_SOUND, pitch_override)
	set waitfor = FALSE
	if(!message || !length(message))
		return
	if(!voice_freq)
		GenerateVoice()

	var/pitch = pitch_override || voice_freq
	var/my_seq = ++voice_seq

	for(var/mob/M in hearers(VOICE_HEAR_RANGE, src))
		if(M.client)
			var/icon/I = getFlatIcon(src, SOUTH)
			M << "\icon[I] <b>[first_name] [last_name]</b> : \"<span style='color:[voice_color];font-family:Verdana'>[message]</span>\""

	if(voice_bubble)
		vis_contents -= voice_bubble

	var/atom/movable/bubble = new()

	var/mtet
	WXH_TO_HEIGHT(client.MeasureText(message, null, VOICE_BUBBLE_WIDTH), mtet)

	bubble.maptext_width = VOICE_BUBBLE_WIDTH
	bubble.maptext_height = mtet
	bubble.maptext_x = (VOICE_BUBBLE_WIDTH - bound_width) * -0.5
	bubble.pixel_y = bound_height * 0.95
	bubble.layer = MOB_LAYER + 0.5
	bubble.maptext = ""
	voice_bubble = bubble
	vis_contents += bubble

	var/shown = ""
	var/blip_count = 0
	for(var/i = 1, i <= length(message), i++)
		if(voice_seq != my_seq)
			vis_contents -= bubble
			if(voice_bubble == bubble)
				voice_bubble = null
			return

		var/ch = copytext(message, i, i + 1)
		shown += ch

		bubble.maptext = "<span style='color:[voice_color];background-color: #23232391;text-align:center;font-family:Verdana;font-size:7px'>[shown]</span>"

		if(ch != " " && ch != "\n")
			blip_count++
			if(blip_count % VOICE_BLIP_EVERY == 0)
				PlayBlip(pitch, sound_path)

		sleep(VOICE_TYPE_SPEED)

	voice_bubble.loc = get_turf(src)
	vis_contents -= bubble
	animate(voice_bubble, VOICE_BUBBLE_LINGER, alpha = 10,  maptext_y = 10)
	sleep(VOICE_BUBBLE_LINGER)
	if(voice_seq == my_seq)
		if(voice_bubble == bubble)
			voice_bubble = null

/mob/human/proc/PlayBlip(pitch, sound_path)
	var/wobble = 1 + (rand(-100, 100) * 0.01 * VOICE_JITTER)
	var/freq = VOICE_BASE_FREQUENCY * pitch * wobble

	playsound(get_turf(src), sound_path, VOICE_BLIP_VOLUME, frequency = freq, channel = voice_channel)