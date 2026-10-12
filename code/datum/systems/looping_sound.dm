/*
	One /datum/looping_sound drives a playlist from a LIST of source objects.
	Every few ticks it works out which players are in range, and for each of them
	sets volume and stereo pan from the distance to the NEAREST source, so the
	music fades as you walk away and picks up again, mid-song, when you walk back.

	Lists you can read:
		active_sound_loops   (global)  every running loop
		loop.sources                   the objects the sound comes from
		loop.listeners                 the clients currently hearing it

	Track and line lengths are in DECISECONDS (10 = 1 second). BYOND can't read a
	file's duration at runtime and can't tell you when a sound ends, so the length
	is how the loop knows when to start the next song.
*/

// Channels reserved for loops. Keep these clear of anything else you use.
#define LOOP_CHANNEL_MIN 800
#define LOOP_CHANNEL_MAX 1000

#ifndef QDELETED
#define QDELETED(X) (isnull(X))
#endif

var/list/active_sound_loops = list()
var/list/used_loop_channels = list()

/proc/AllocLoopChannel()
	for(var/ch = LOOP_CHANNEL_MIN, ch <= LOOP_CHANNEL_MAX, ch++)
		if(!(ch in used_loop_channels))
			used_loop_channels += ch
			return ch
	return 0

/proc/FreeLoopChannel(ch)
	used_loop_channels -= ch

/// Every running loop that uses A as one of its sources.
/proc/GetSoundLoopsFor(atom/movable/A)
	var/list/found = list()
	for(var/datum/looping_sound/L in active_sound_loops)
		if(A in L.sources)
			found += L
	return found


/datum/looping_sound
	// ---- config: set these before Start() ----
	var/list/sources                  // objects the sound comes from (list)
	var/list/tracks                   // assoc: sound file = length in deciseconds
	var/shuffle = FALSE               // random order (never the same song twice in a row)
	var/volume = 70                   // 0-100, volume right next to a source
	var/range = 6                    // tiles; silent beyond this
	var/falloff_start = 3             // full volume inside this many tiles, fades out to range
	var/refresh_rate = 4              // deciseconds between listener updates

	var/list/lines                    // OPTIONAL: assoc: sound file = length in deciseconds
	var/line_chance = 60              // % chance of a line between two songs
	var/line_volume = 70              // passed to playsound()

	var/station_name = "Roguestation" // lol, get it? used for radios
	var/station_band = "74.4 MHz"

	// ---- state ----
	var/running = FALSE
	var/channel = 0
	var/run_id = 0
	var/skip_requested = FALSE
	var/list/listeners = list()       // assoc: client = list(volume, pan) last sent
	var/segment_file
	var/segment_length
	var/segment_start
	var/segment_repeat = FALSE
	var/track_index = 0
	var/last_track

/// sources_in can be a single object or a list of objects.
/datum/looping_sound/New(sources_in)
	..()
	sources = list()
	if(islist(sources_in))
		var/list/L = sources_in
		sources += L
	else if(sources_in)
		sources += sources_in

/datum/looping_sound/Destroy()
	Stop()
	sources = null
	listeners = null
	return ..()

// ------------------------------------------------------------------
// Public API
// ------------------------------------------------------------------

/datum/looping_sound/proc/Start()
	if(running)
		return TRUE
	if(!length(tracks))
		return FALSE
	for(var/f in tracks)
		if(!isnum(tracks[f]) || tracks[f] <= 0)
			world.log << "looping_sound: track [f] needs a length in deciseconds (tracks = list('a.ogg' = 1800))"
			return FALSE
	channel = AllocLoopChannel()
	if(!channel)
		world.log << "looping_sound: out of channels"
		return FALSE
	running = TRUE
	run_id++
	active_sound_loops += src
	Run()
	return TRUE

/datum/looping_sound/proc/Stop()
	if(!running)
		return
	running = FALSE
	run_id++
	StopAll()
	active_sound_loops -= src
	FreeLoopChannel(channel)
	channel = 0

/// Jump to the next song.
/datum/looping_sound/proc/Skip()
	skip_requested = TRUE

/datum/looping_sound/proc/SetVolume(new_volume)
	volume = clamp(new_volume, 0, 100)

/datum/looping_sound/proc/AddSource(atom/movable/A)
	if(A && !(A in sources))
		sources += A

/datum/looping_sound/proc/RemoveSource(atom/movable/A)
	sources -= A
	if(!length(sources))
		Stop()

/// Override for deafness, earmuffs, a mute pref, etc.
/datum/looping_sound/proc/CanHear(mob/M)
	return TRUE

// ------------------------------------------------------------------
// Main loop
// ------------------------------------------------------------------

/datum/looping_sound/proc/Run()
	set waitfor = FALSE
	var/my_run = run_id

	while(running && run_id == my_run)
		if(!PruneSources())
			Stop()
			return

		BeginTrack()

		while(running && run_id == my_run && !skip_requested)
			if(!segment_repeat && world.time >= segment_start + segment_length)
				break
			Refresh()
			sleep(refresh_rate)

		if(!running || run_id != my_run)
			return

		var/skipped = skip_requested
		skip_requested = FALSE
		StopAll()

		if(!skipped && length(lines) && prob(line_chance))
			PlayLine(my_run)

/datum/looping_sound/proc/PruneSources()
	listclearnulls(sources)
	for(var/atom/movable/A in sources.Copy())
		if(QDELETED(A))
			sources -= A
	return length(sources)

/datum/looping_sound/proc/BeginTrack()
	var/f
	if(shuffle)
		var/list/pool = tracks.Copy()
		if(length(pool) > 1 && last_track)
			pool -= last_track
		f = pick(pool)
	else
		track_index = (track_index % length(tracks)) + 1
		f = tracks[track_index]

	last_track = f
	segment_file = f
	segment_length = tracks[f]
	segment_start = world.time
	// A single song with no lines just uses BYOND's own repeat
	segment_repeat = (length(tracks) == 1 && !length(lines))

/// Between-song line. Goes through playsound(), from the first live source only.
/// If your playsound() signature differs from /tg/'s, change the one call below.
/datum/looping_sound/proc/PlayLine(my_run)
	var/atom/movable/primary
	for(var/atom/movable/A in sources)
		if(!QDELETED(A))
			primary = A
			break
	if(!primary)
		return

	var/f = pick(lines)
	var/len = lines[f]
	if(!isnum(len) || len <= 0)
		len = 30

	playsound(primary, f, line_volume, FALSE)

	var/end = world.time + len
	while(running && run_id == my_run && world.time < end)
		sleep(min(refresh_rate, max(end - world.time, 1)))

// ------------------------------------------------------------------
// Listeners
// ------------------------------------------------------------------

/datum/looping_sound/proc/Refresh()
	var/list/new_listeners = list()
	var/elapsed = round(world.time - segment_start)

	for(var/client/C)
		var/mob/M = C.mob
		if(!M || !CanHear(M))
			continue
		var/turf/LT = get_turf(M)
		if(!LT)
			continue

		// Nearest source wins, so several speakers never stack up
		var/best = 1e30
		var/best_dx = 0
		for(var/atom/movable/A in sources)
			if(QDELETED(A))
				continue
			var/turf/T = get_turf(A)
			if(!T || T.z != LT.z)
				continue
			var/dx = T.x - LT.x
			var/dy = T.y - LT.y
			var/d = sqrt(dx * dx + dy * dy)
			if(d < best)
				best = d
				best_dx = dx

		if(best > range)
			continue

		var/vol = CalcVolume(best)
		if(vol <= 0)
			continue
		var/pan = round(clamp(best_dx * 12.5, -100, 100)) // 8 tiles to the side = full pan

		var/list/prev = listeners[C]
		if(!prev)
			PlayTo(C, vol, pan, FALSE, elapsed)     // just came into range: start mid-song
		else if(prev[1] != vol || prev[2] != pan)
			PlayTo(C, vol, pan, TRUE, elapsed)      // already playing: adjust only
		new_listeners[C] = list(vol, pan)

	// Anyone who was hearing it and no longer is
	for(var/client/C in listeners)
		if(!(C in new_listeners))
			StopFor(C)

	listeners = new_listeners

/datum/looping_sound/proc/CalcVolume(dist)
	if(dist <= falloff_start)
		return volume
	var/t = clamp((dist - falloff_start) / max(range - falloff_start, 1), 0, 1)
	return round(volume * ((1 - t) ** 2))

/datum/looping_sound/proc/PlayTo(client/C, vol, pan, update, elapsed)
	var/sound/S = sound(segment_file, repeat = segment_repeat, wait = FALSE, channel = channel, volume = vol)
	S.pan = pan
	if(update)
		S.status = SOUND_UPDATE
	else
		if(segment_repeat)
			elapsed = elapsed % segment_length
		S.offset = elapsed / 10
	C << S

/datum/looping_sound/proc/StopFor(client/C)
	if(C && channel)
		C << sound(null, channel = channel)

/datum/looping_sound/proc/StopAll()
	for(var/client/C in listeners)
		StopFor(C)
	listeners = list()


/* ------------------------------------------------------------------
	EXAMPLE

	/obj/machine/jukebox
		var/datum/looping_sound/music

	/obj/machine/jukebox/proc/TogglePower()
		if(music)
			QDEL_NULL(music)
			return
		music = new(src)                       // or new(list(src, speaker1, speaker2))
		music.tracks = list(
			'sound/music/song1.ogg' = 1832,    // length in deciseconds
			'sound/music/song2.ogg' = 2410,
		)
		music.lines = list(                    // optional
			'sound/lines/dj1.ogg' = 52,
			'sound/lines/dj2.ogg' = 70,
		)
		music.shuffle = TRUE
		music.range = 16
		music.Start()

	/obj/machine/jukebox/Destroy()
		QDEL_NULL(music)
		return ..()
------------------------------------------------------------------ */

/obj/item/deco/radio
	name = "radio"
	icon_state = "radio"
	desc = "Thanks to the ever expanding net of communications artiholes, this thing can receive frequencies faster-than-light! (That is if you consider wormholes to be FTL, that is.)"
	desc_expansive_extra_skill = TECH
	desc_expansive = "Maybe in the future you'll be able to tune this to specific stations. But today? Something tells you that the knobs are too stuck to rotate. Oof."
	droprot = FALSE

	vendor_name = "RDIO"
	vendor_price = 81

	var/datum/looping_sound/music

/obj/item/deco/radio/Initialize()
	. = ..()
	music = new(src)
	music.tracks = list(
		'sound/music/radio/142046mhz/crystalmatango.ogg' = 2023,
		'sound/music/radio/142046mhz/matangoneverbloom.ogg' = 1930,
		'sound/music/radio/142046mhz/la_vipera.ogg' = 2140,
		'sound/music/radio/142046mhz/tulpa.ogg' = 2430,
		'sound/music/radio/142046mhz/psychic_veteran.ogg' = 2900,
	)
	music.lines = list(
		'sound/music/radio/142046mhz/dj/dj_best_songs.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_gamble_responsibly.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_shoutout_frouge.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_shoutout_totchke.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_shove_it.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_thank_you.ogg' = 200
	)
	music.shuffle = TRUE
	music.range = 5
	music.line_chance = 90

	music.Start()

/obj/item/deco/radio/Destroy(force)
	QDEL_NULL(music)
	return ..()