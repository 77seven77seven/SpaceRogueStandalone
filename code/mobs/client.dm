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
	var/tmp/atom/movable/lighting_master/lighting_master
	var/current_ambience
	var/current_ambience_channel
	var/current_ambience_volume = 0
	var/area_ambience_transition = 0
	var/list/area_ambience_channels = list()
	var/list/area_ambience_track_order = list()
	var/tmp/list/client_color_effects = list()
	var/tmp/client_color_effect_counter = 0

/client/proc/SetColorEffect(effect_id, effect_color, transition_time = 0, easing = 0)
	if(!client_color_effects)
		client_color_effects = list()

	var/list/effect_data = client_color_effects[effect_id]
	if(!effect_data)
		effect_data = list("red" = 1, "green" = 1, "blue" = 1, "transition_id" = 0)
		client_color_effects[effect_id] = effect_data

	effect_data["red"] = hex2num(copytext(effect_color, 2, 4)) / 255
	effect_data["green"] = hex2num(copytext(effect_color, 4, 6)) / 255
	effect_data["blue"] = hex2num(copytext(effect_color, 6, 8)) / 255
	effect_data["transition_id"]++
	effect_data["remove_when_done"] = FALSE
	UpdateColorEffects(transition_time, easing)

/client/proc/AddColorEffect(effect_color, transition_time = 0, easing = 0)
	client_color_effect_counter++
	var/effect_id = "transient_[client_color_effect_counter]"
	SetColorEffect(effect_id, effect_color, transition_time, easing)
	return effect_id

/client/proc/RemoveColorEffect(effect_id, transition_time = 0, easing = 0)
	if(!client_color_effects || !client_color_effects[effect_id])
		return
	if(!transition_time)
		client_color_effects -= effect_id
		UpdateColorEffects()
		return

	var/list/effect_data = client_color_effects[effect_id]
	SetColorEffect(effect_id, "#ffffff", transition_time, easing)
	effect_data["remove_when_done"] = TRUE
	var/transition_id = effect_data["transition_id"]
	spawn(transition_time)
		if(src && client_color_effects[effect_id] == effect_data && effect_data["transition_id"] == transition_id && effect_data["remove_when_done"])
			client_color_effects -= effect_id
			UpdateColorEffects()

/client/proc/PulseColorEffect(effect_color, fade_in, hold, fade_out, easing_in, easing_out, release_color = "#ffffff")
	var/effect_id = AddColorEffect(effect_color, fade_in, easing_in)
	spawn(fade_in + hold)
		if(!src)
			return
		if(release_color == "#ffffff")
			RemoveColorEffect(effect_id, fade_out, easing_out)
			return
		SetColorEffect(effect_id, release_color, fade_out, easing_out)
		spawn(fade_out)
			if(src)
				RemoveColorEffect(effect_id)

/client/proc/UpdateColorEffects(transition_time = 0, easing = 0)
	var/red = 1
	var/green = 1
	var/blue = 1
	for(var/effect_id in client_color_effects)
		var/list/effect_data = client_color_effects[effect_id]
		red *= effect_data["red"]
		green *= effect_data["green"]
		blue *= effect_data["blue"]

	if(client_color_effects.len)
		var/composed_color = rgb(round(red * 255), round(green * 255), round(blue * 255))
		if(transition_time)
			animate(src, color = composed_color, time = transition_time, easing = easing, flags = ANIMATION_PARALLEL)
		else
			color = composed_color
	else
		color = null

/client/New()
	. = ..()
	master.clients += src
	lighting_master = new /atom/movable/lighting_master
	screen += lighting_master

/client/Del()
	. = ..()
	master.clients -= src
	screen -= lighting_master
	qdel(lighting_master)
	lighting_master = null

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
			var/movement_delay = H.movement_delay
			if(H.firing_slow_until > time)
				movement_delay += 2
			movement_cooldown_until = time + movement_delay

	var/list/closing_popups = open_popups.Copy()
	for(var/window_id in closing_popups)
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
	if(!part)
		return 0
	var/list/bits = splittext(part, ":")
	if(bits.len < 2)
		return 0
	var/pixel_offset = text2num(bits[bits.len])
	if(isnull(pixel_offset))
		return 0
	return pixel_offset // last element is the pixel offset

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
	lobby_music = sound(pick('sound/music/title.ogg', 'sound/music/title2.ogg'), repeat = TRUE, wait = FALSE, channel = CHANNEL_LOBBY_MUSIC, volume = 50)
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
	animate(src, transform = matrix().Turn(3), pixel_w = 0, pixel_z = 10, time = 30, easing = SINE_EASING, loop = -1)
	animate(transform = matrix(), pixel_w = -10, pixel_z = 0, time = 30, easing = SINE_EASING)
	animate(transform = matrix().Turn(-3), pixel_w = 0, pixel_z = -10, time = 30, easing = SINE_EASING)
	animate(transform = matrix(), pixel_w = 10, pixel_z = 0, time = 30, easing = SINE_EASING)

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

/client/verb/license()
	set name = ".license"

	alert(src, "Some sprites and code snippets are taken from unlicensed obsolete codebases and or BYOND user-generated libraries. A small amount of sprites taken from /tg/station 13, licensed under CC BY-SA 3.0. This codebase/software is licensed under GNU General Public License v3, and is not under legal obligation to release the source code.", "Fringe Sector: Roguestation Endera License Popup")

/client/verb/about()
	set name = ".about"

	alert(src, "<b>Fringe Sector: Roguestation Endera</b> is a roleplaying game based on the BYOND game engine with a focus on improvisation, immersion and reinforcing player performance with mechanics. Try your best to survive with temporary characters and upkeep the veil of immersion. Try to tell an interesting story, no matter what happens. And try to find a sense of belonging among your crewmembers in the supposed 'New Golden Age of Humanity' of 2147.", "Welcome Aboard to Roguestation Endera!")