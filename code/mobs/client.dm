#define MOVEMENT_DELAY_BUFFER 0.75
#define MOVEMENT_DELAY_BUFFER_DELTA 1.25

/client
	preload_rsc = 1
	fps = 100
	
	var/xp = 6 // saves


	var/rewardpips = 0
	var/max_rewardpips = 7

	var/datum/role/previously_played // saves too. reset when you successfully escape (do not set when success escape)

	var/turf/movered
	var/mpx = 0
	var/mpy = 0
	var/tmp/movement_cooldown_until = 0
	var/tmp/mob/movement_mob

	var/image/mouseover_text
	var/sound/droning_sound
	var/sound/lobby_music
	var/tmp/lobby_camera_sway = FALSE
	var/current_ambience
	var/current_ambience_channel
	var/current_ambience_volume = 0
	var/area_ambience_transition = 0
	var/list/area_ambience_channels = list()
	var/list/area_ambience_track_order = list()

/client/New()
	. = ..()
	master.clients += src

/client/Del()
	. = ..()
	master.clients -= src

/client/Move(loc, dir)
	var/mob/human/H = mob
	var/time = world.time

	if(movement_mob != mob)
		movement_mob = mob
		movement_cooldown_until = 0

	if(istype(H) && (H.dead || H.ragdolled || movement_cooldown_until > time))
		. = FALSE
	else
		. = ..()
		if(. && istype(H))
			movement_cooldown_until = time + H.movement_delay

	for(var/window_id in open_popups)
		mob << browse(null, "window=[window_id]")
		open_popups -= window_id

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
	var/sound/combat_music = sound(pick(music), repeat = TRUE, wait = 0, channel = CHANNEL_COMBAT_MUSIC, volume = vol)
	SEND_SOUND(src, combat_music)
	droning_sound = combat_music
	
/client/proc/stop_droning()
	if(!droning_sound)
		return
	var/sound/sound_killer = sound()
	sound_killer.channel = droning_sound.channel
	SEND_SOUND(src, sound_killer)
	droning_sound = null

/client/proc/play_lobby_music()
	if(lobby_music)
		return
	lobby_music = sound('sound/music/title.ogg', repeat = TRUE, wait = FALSE, channel = CHANNEL_LOBBY_MUSIC, volume = 50)
	SEND_SOUND(src, lobby_music)

/client/proc/stop_lobby_music()
	if(!lobby_music)
		return
	SEND_SOUND(src, sound(null, repeat = FALSE, wait = FALSE, channel = CHANNEL_LOBBY_MUSIC))
	lobby_music = null

/client/proc/start_lobby_camera_sway()
	if(lobby_camera_sway)
		return
	lobby_camera_sway = TRUE
	animate(src, transform = matrix().Turn(0.3), pixel_w = 0, pixel_z = 1, time = 30, easing = SINE_EASING, loop = -1)
	animate(transform = matrix(), pixel_w = -1, pixel_z = 0, time = 30, easing = SINE_EASING)
	animate(transform = matrix().Turn(-0.3), pixel_w = 0, pixel_z = -1, time = 30, easing = SINE_EASING)
	animate(transform = matrix(), pixel_w = 1, pixel_z = 0, time = 30, easing = SINE_EASING)

/client/proc/stop_lobby_camera_sway()
	if(!lobby_camera_sway)
		return
	lobby_camera_sway = FALSE
	animate(src, transform = matrix(), pixel_w = 0, pixel_z = 0, time = 5, easing = SINE_EASING)

/client/proc/update_area_ambience(area/A)
	var/track
	if(!istype(mob, /mob/lobbyman) && A && islist(A.ambience) && A.ambience.len)
		track = pick(A.ambience)

	var/target_volume = track ? A.ambience_volume : 0
	if(track == current_ambience && target_volume == current_ambience_volume)
		return

	area_ambience_transition++
	var/transition_id = area_ambience_transition
	spawn()
		transition_area_ambience(track, target_volume, transition_id)

/client/proc/transition_area_ambience(track, target_volume, transition_id)
	if(current_ambience && current_ambience != track)
		fade_area_ambience("[current_ambience]", 0, transition_id)
		if(transition_id != area_ambience_transition)
			return

		var/sound/pause_sound = sound(null, repeat = TRUE, channel = current_ambience_channel)
		pause_sound.status = SOUND_PAUSED
		SEND_SOUND(src, pause_sound)
		current_ambience = null
		current_ambience_channel = null
		current_ambience_volume = 0

	if(!track || transition_id != area_ambience_transition)
		return

	var/track_key = "[track]"
	var/channel = area_ambience_channels[track_key]
	var/new_track = !channel
	if(new_track)
		channel = allocate_area_ambience_channel()
		if(!channel)
			CRASH("Unable to allocate an area ambience sound channel.")

	var/track_already_playing = (track == current_ambience)
	if(area_ambience_track_order.Find(track_key))
		var/track_position = area_ambience_track_order.Find(track_key)
		area_ambience_track_order.Cut(track_position, track_position + 1)
	area_ambience_track_order += track_key

	current_ambience = track
	current_ambience_channel = channel
	if(new_track)
		var/sound/ambience = sound(track, repeat = TRUE, wait = 0, channel = channel, volume = 0)
		SEND_SOUND(src, ambience)
	else if(!track_already_playing)
		var/sound/resume_sound = sound(null, repeat = TRUE, channel = channel, volume = 0)
		resume_sound.status = SOUND_UPDATE
		SEND_SOUND(src, resume_sound)

	area_ambience_channels[track_key] = channel
	fade_area_ambience(track_key, target_volume, transition_id)

/client/proc/allocate_area_ambience_channel()
	for(var/channel in CHANNEL_AREA_AMBIENCE_MIN to CHANNEL_AREA_AMBIENCE_MAX)
		if(channel == CHANNEL_COMBAT_MUSIC)
			continue
		var/channel_in_use = FALSE
		for(var/cached_track in area_ambience_track_order)
			if(area_ambience_channels[cached_track] == channel)
				channel_in_use = TRUE
				break
		if(!channel_in_use)
			return channel

	for(var/cached_track in area_ambience_track_order)
		if(area_ambience_channels[cached_track] == current_ambience_channel)
			continue
		var/channel = area_ambience_channels[cached_track]
		SEND_SOUND(src, sound(null, repeat = 0, wait = 0, channel = channel))
		area_ambience_channels -= cached_track
		area_ambience_track_order -= cached_track
		return channel
	return null

/client/proc/fade_area_ambience(track_key, target_volume, transition_id)
	var/channel = area_ambience_channels[track_key]
	var/start_volume = current_ambience_volume
	if(start_volume == target_volume)
		return

	var/step_count = 10
	for(var/step in 1 to step_count)
		if(transition_id != area_ambience_transition)
			return
		var/volume = start_volume + ((target_volume - start_volume) * step / step_count)
		var/sound/volume_update = sound(null, repeat = TRUE, channel = channel, volume = volume)
		volume_update.status = SOUND_UPDATE
		SEND_SOUND(src, volume_update)
		current_ambience_volume = volume
		sleep(1)

/client/verb/fuckyou()
	world << "----"
	if(master)
		world << "master = OK"
	else
		world << "master = FAIL"
	if(processor)
		world << "processor = OK"
	else
		world << "processor = FAIL"
	if(station)
		world << "station = OK"
	else
		world << "station = FAIL"
	if(shuttle)
		world << "shuttle = OK"
	else
		world << "shuttle = FAIL"
	world << "----"

/client/verb/license()
	set name = ".license"

	alert(src, "Some sprites and code snippets are taken from unlicensed obsolete codebases and or BYOND user-generated libraries. A small amount of sprites taken from /tg/station 13, licensed under CC BY-SA 3.0. This codebase/software is licensed under GNU General Public License v3, and is not under legal obligation to release the source code.", "Fringe Sector: Roguestation Endera License Popup")

/client/verb/about()
	set name = ".about"

	alert(src, "<b>Fringe Sector: Roguestation Endera</b> is a roleplaying game based on the BYOND game engine with a focus on improvisation, immersion and reinforcing player performance with mechanics. Try your best to survive with temporary characters and upkeep the veil of immersion. Try to tell an interesting story, no matter what happens. And try to find a sense of belonging among your crewmembers in the supposed 'New Golden Age of Humanity' of 2147.", "Welcome Aboard to Roguestation Endera!")