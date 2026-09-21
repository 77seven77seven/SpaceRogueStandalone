/*
 * playsound.dm — a standalone positional-audio engine for BYOND/DM projects.
 *
 * Reproduces SS13's playsound()/playsound_local() without SSambience, atmos
 * pressure checks, reverb environments, or any /datum framework dependency.
 * Pairs with timers.dm but has no dependency on it.
 *
 * Quick use:
 *     playsound(src, 'sound/effects/explosion.ogg', 100, TRUE)
 *     playsound_local(usr.client, 'sound/machines/click.ogg', 50)
 *
 * Requires get_turf() and get_dist(); get_turf() is defined below — delete
 * that definition if your project already has one (duplicate proc = compile
 * error).
 */

// ---------------------------------------------------------------------------
// Tuning — adjust these to taste, ideally to match world.view
// ---------------------------------------------------------------------------

#define DIRECT_OUTPUT(A, B) A << B
#define SEND_SOUND(target, sound) DIRECT_OUTPUT(target, sound)

/// Tiles a sound travels by default before it's inaudible.
#define SOUND_RANGE_DEFAULT        7
/// Tiles closest to the source that get full volume with no falloff.
#define SOUND_FALLOFF_DISTANCE     1
/// Steepness of the volume curve past the no-falloff zone. Higher = sound
/// stays strong nearby then drops off harder near max range.
#define SOUND_FALLOFF_EXPONENT     6
/// Volume multiplier applied when a dense turf blocks line of sight
/// (only checked if playsound() is called with ignore_walls = FALSE).
#define SOUND_MUFFLED_MULTIPLIER   0.35
/// Don't bother sending sounds quieter than this — inaudible, wastes bandwidth.
#define SOUND_MIN_VOLUME_CUTOFF    1
/// Random pitch range used when vary = TRUE and no explicit frequency is given.
/// Tune to your sound files; these are cents-ish either side of "normal".
#define SOUND_FREQUENCY_LOW        32000
#define SOUND_FREQUENCY_HIGH       55000

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Walks up an atom's location chain until it finds the turf it's on.
 * Delete this if your codebase already defines get_turf() — DM will refuse
 * to compile two procs of the same name.
 */
/proc/get_turf(atom/A)
	if(!A)
		return null
	if(isturf(A))
		return A
	var/atom/loc = A.loc
	while(loc && !isturf(loc))
		loc = loc.loc
	return loc

/proc/get_rand_frequency()
	return rand(SOUND_FREQUENCY_LOW, SOUND_FREQUENCY_HIGH)

/**
 * Bresenham walk from `from_turf` to `to_turf`, true if any turf in between
 * (exclusive of the source tile) is dense. Cheap approximation of "is there
 * a wall in the way" — no diagonal corner-cutting logic, no opacity checks
 * on objects, just turf density. Only called when ignore_walls = FALSE.
 */
/proc/_sound_los_blocked(turf/from_turf, turf/to_turf)
	var/x1 = from_turf.x
	var/y1 = from_turf.y
	var/x2 = to_turf.x
	var/y2 = to_turf.y
	var/z = from_turf.z

	var/dx = abs(x2 - x1)
	var/dy = abs(y2 - y1)
	var/sx = (x1 < x2) ? 1 : -1
	var/sy = (y1 < y2) ? 1 : -1
	var/err = dx - dy

	var/cx = x1
	var/cy = y1

	while(!(cx == x2 && cy == y2))
		var/e2 = 2 * err
		if(e2 > -dy)
			err -= dy
			cx += sx
		if(e2 < dx)
			err += dx
			cy += sy

		if(cx == x2 && cy == y2)
			break // don't test density of the listener's own tile

		var/turf/T = locate(cx, cy, z)
		if(T && T.density)
			return TRUE

	return FALSE

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Plays `soundin` at `source`'s location for every client within range.
 *
 * source           - atom (or turf) the sound originates from.
 * soundin          - a sound file, or a /list of files to pick() from.
 * vol              - base volume at the source tile (0-100).
 * vary             - if TRUE, randomizes pitch each play (see SOUND_FREQUENCY_*).
 * extra_range      - added to SOUND_RANGE_DEFAULT; ignored if max_range is set.
 * falloff_exponent - overrides SOUND_FALLOFF_EXPONENT for this call.
 * frequency        - explicit pitch; ignored if vary = TRUE and this is null.
 * channel          - BYOND sound channel (0 = engine picks one; 1-1024 = exclusive,
 *                     new sound on that channel cuts off whatever was playing there).
 * ignore_walls     - if FALSE, muffles the sound when a dense turf blocks line
 *                     of sight between source and listener.
 * max_range        - explicit cutoff in tiles; 0 = auto (SOUND_RANGE_DEFAULT + extra_range).
 * repeat           - loop the sound (pair with a nonzero channel so you can stop it later).
 */
/proc/playsound(atom/source, soundin, vol = 100, vary = FALSE, extra_range = 0, falloff_exponent = SOUND_FALLOFF_EXPONENT, frequency = null, channel = 0, ignore_walls = TRUE, max_range = 0, repeat = FALSE)
	if(!source || !soundin)
		return

	var/turf/source_turf = get_turf(source)
	if(!source_turf)
		return

	if(islist(soundin))
		var/list/choices = soundin
		if(!length(choices))
			return
		soundin = pick(choices)
	else if(istype(soundin, /sound))
		var/sound/given = soundin
		soundin = given.file

	var/effective_range = max_range ? max_range : (SOUND_RANGE_DEFAULT + extra_range)
	if(effective_range <= 0)
		return

	for(var/mob/listener in hearers(effective_range, source_turf))
		var/client/C = listener.client
		if(!C) continue
		var/turf/listener_turf = get_turf(listener)
		var/distance = get_dist(source_turf, listener_turf)

		// Full volume within the no-falloff zone, then an exponential taper
		// out to effective_range.
		var/falloff_span = max(effective_range - SOUND_FALLOFF_DISTANCE, 1)
		var/beyond_floor = max(distance - SOUND_FALLOFF_DISTANCE, 0)
		var/attenuation = 1 - (beyond_floor / falloff_span)
		attenuation = min(max(attenuation, 0), 1) ** falloff_exponent

		var/final_vol = vol * attenuation

		if(!ignore_walls && distance > 0 && _sound_los_blocked(source_turf, listener_turf))
			final_vol *= SOUND_MUFFLED_MULTIPLIER

		final_vol = round(final_vol)
		if(final_vol < SOUND_MIN_VOLUME_CUTOFF)
			continue

		var/sound/S = sound(soundin)
		S.repeat = repeat
		S.channel = channel
		S.volume = final_vol
		// x/y/z drive BYOND's own stereo panning; falloff here is tile-scale,
		// separate from the vol we already computed above.
		S.x = source_turf.x - listener_turf.x
		S.y = source_turf.y - listener_turf.y
		S.z = source_turf.z - listener_turf.z
		S.falloff = SOUND_FALLOFF_DISTANCE

		if(vary)
			S.frequency = frequency || get_rand_frequency()
		else if(frequency)
			S.frequency = frequency

		C << S

/**
 * Plays a sound only for one client, at flat volume, ignoring position and
 * range entirely — UI feedback, personal cues, anything that shouldn't be
 * affected by where the listener's mob is standing.
 */
/proc/playsound_local(client/C, soundin, vol = 100, vary = FALSE, frequency = null, channel = 0, repeat = FALSE)
	if(!C || !soundin)
		return

	if(islist(soundin))
		var/list/choices = soundin
		if(!length(choices))
			return
		soundin = pick(choices)
	else if(istype(soundin, /sound))
		var/sound/given = soundin
		soundin = given.file

	var/sound/S = sound(soundin)
	S.repeat = repeat
	S.channel = channel
	S.volume = vol

	if(vary)
		S.frequency = frequency || get_rand_frequency()
	else if(frequency)
		S.frequency = frequency

	C << S

/**
 * Stops whatever is playing on `channel` for that client — the counterpart
 * to a looping playsound()/playsound_local() call. Requires a nonzero,
 * exclusive channel to have been used when the sound was started.
 */
/proc/stop_sound_channel(client/C, channel)
	if(!C || !channel)
		return
	C << sound(null, channel = channel)

/*
 * ---------------------------------------------------------------------------
 * Examples
 * ---------------------------------------------------------------------------
 *
 * // One-shot positional sound, heard by everyone in range, pitch-varied
 * playsound(src, 'sound/effects/explosion.ogg', 100, TRUE)
 *
 * // Quiet, short-range, muffled through walls
 * playsound(src, 'sound/effects/footstep.ogg', 40, TRUE, -3, ignore_walls = FALSE)
 *
 * // Random variant picked from a list
 * playsound(src, list('sound/voice/grunt1.ogg', 'sound/voice/grunt2.ogg'), 60)
 *
 * // Looping ambience on its own channel, stopped later
 * #define CHANNEL_MACHINE_HUM 50
 * ambience_id = playsound(src, 'sound/machines/hum.ogg', 30, channel = CHANNEL_MACHINE_HUM, repeat = TRUE)
 * // ...later, when the machine turns off:
 * for(var/client/C in world.clients)
 *     stop_sound_channel(C, CHANNEL_MACHINE_HUM)
 *
 * // UI click, local to one client, unaffected by mob position
 * playsound_local(usr.client, 'sound/ui/click.ogg', 50)
 */
