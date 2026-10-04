/client
	preload_rsc = 1
	fps = 100
	
	var/xp = 6 // saves
	var/rewardpips = 0
	var/max_rewardpips = 6

	var/datum/role/previously_played // saves too. reset when you successfully escape (do not set when success escape)

	var/turf/movered
	var/mpx = 0
	var/mpy = 0

	var/image/mouseover_text
	var/sound/droning_sound

/client/New()
	. = ..()
	master.clients += src

/client/Del()
	. = ..()
	master.clients -= src

/client/MouseMove(object, location, control, params)
	. = ..()
	movered = get_turf(location)
	mpx = null
	mpy = null

	if(!isturf(location))
		return

	var/list/p = params2list(params)
	var/screen_loc = p["screen-loc"]
	if(!screen_loc)
		return

	var/list/parts = splittext(screen_loc, ",")
	if(parts.len < 2)
		return

	mpx = screen_loc_pixel(parts[1])
	mpy = screen_loc_pixel(parts[2])

/proc/screen_loc_pixel(part)
	var/list/bits = splittext(part, ":")
	if(bits.len < 2)
		return 0
	return text2num(bits[bits.len]) // last element is the pixel offset

/client/proc/play_droning(music = null, vol = 50)
	if(!music)
		return
	var/sound/combat_music = sound(pick(music), repeat = TRUE, wait = 0, channel = 1017, volume = vol)
	SEND_SOUND(src, combat_music)
	droning_sound = combat_music
	
/client/proc/stop_droning()
	if(!droning_sound)
		return
	var/sound/sound_killer = sound()
	sound_killer.channel = droning_sound.channel
	SEND_SOUND(src, sound_killer)
	droning_sound = null

/client/verb/fuckyou()
	world << "----"
	if(master)
		world << "master = OK"
	if(processor)
		world << "processor = OK"
	if(station)
		world << "station = OK"
	world << "----"