/*
 * Provides addtimer() / deltimer() / timeleft() with no dependency on SS13
 *
 * Quick use:
 *     addtimer(CALLBACK(src, PROC_REF(Unstun)), 5 SECONDS)
 *
 *     var/id = addtimer(CALLBACK(src, PROC_REF(Tick)), 1 SECOND, TIMER_LOOP)
 *     deltimer(id)
 *
 */

// ---------------------------------------------------------------------------
// Flags & helpers
// ---------------------------------------------------------------------------

/// Don't schedule if an identical timer (same object/proc/args/wait) exists.
#define TIMER_UNIQUE        (1<<0)
/// With TIMER_UNIQUE: replace the existing timer instead of keeping it.
#define TIMER_OVERRIDE      (1<<1)
/// Re-arm forever until deltimer()'d.
#define TIMER_LOOP          (1<<2)
/// Measure against real (wall clock) time instead of world.time, so the timer
/// still fires on schedule if the server is lagging or the world is paused.
#define TIMER_CLIENT_TIME   (1<<3)
/// With TIMER_UNIQUE: ignore `wait` when deciding whether two timers match.
#define TIMER_NO_HASH_WAIT  (1<<4)

#define SECOND  * 10
#define SECONDS * 10
#define MINUTE  * 600
#define MINUTES * 600
#define HOUR    * 36000
#define HOURS   * 36000

/// Sentinel used as a callback target when calling a global proc.
#define GLOBAL_PROC "__global_proc__"

/// CALLBACK(target, PROC_REF(name), args...)
#define CALLBACK new /datum/callback

#if DM_VERSION >= 515
	// nameof() validates at compile time that the proc actually exists.
	#define PROC_REF(X) (nameof(.proc/##X))
	#define VERB_REF(X) (nameof(.verb/##X))
	#define TYPE_PROC_REF(TYPE, X) (nameof(##TYPE.proc/##X))
	#define TYPE_VERB_REF(TYPE, X) (nameof(##TYPE.verb/##X))
	#define GLOBAL_PROC_REF(X) (/proc/##X)
#else
	#define PROC_REF(X) (.proc/##X)
	#define VERB_REF(X) (.verb/##X)
	#define TYPE_PROC_REF(TYPE, X) (##TYPE.proc/##X)
	#define TYPE_VERB_REF(TYPE, X) (##TYPE.verb/##X)
	#define GLOBAL_PROC_REF(X) (.proc/##X)
#endif

// ---------------------------------------------------------------------------
// Monotonic real time (deciseconds, survives midnight rollover)
// ---------------------------------------------------------------------------

/proc/realtime()
	var/static/last_tod = 0
	var/static/day_offset = 0
	var/tod = world.timeofday
	if(tod < last_tod)
		day_offset += 864000 // one day in deciseconds
	last_tod = tod
	return tod + day_offset

// ---------------------------------------------------------------------------
// Callback
// ---------------------------------------------------------------------------

/datum/callback
	/// The object the proc is called on, or GLOBAL_PROC.
	var/datum/object
	/// Proc name (text) or proc path.
	var/delegate
	/// Bound arguments, if any.
	var/list/arguments

/datum/callback/New(thing, proc_to_call, ...)
	. = ..()
	object = thing
	delegate = proc_to_call
	if(length(args) > 2)
		arguments = args.Copy(3)

/**
 * Calls the bound proc. Any arguments passed to Invoke() are appended after
 * the arguments bound at creation time.
 *
 * Returns null without calling if the target object has been deleted — BYOND
 * nulls all references to a deleted datum/atom, so this check is reliable as
 * long as you use del() (or your own delete wrapper).
 */
/datum/callback/proc/Invoke(...)
	if(isnull(object))
		return null

	var/list/calling_args = arguments ? arguments.Copy() : list()
	if(length(args))
		calling_args += args

	if(object == GLOBAL_PROC)
		return call(delegate)(arglist(calling_args))
	return call(object, delegate)(arglist(calling_args))

/// Same as Invoke(), but returns to the caller immediately instead of blocking.
/datum/callback/proc/InvokeAsync(...)
	set waitfor = FALSE
	if(isnull(object))
		return null

	var/list/calling_args = arguments ? arguments.Copy() : list()
	if(length(args))
		calling_args += args

	if(object == GLOBAL_PROC)
		return call(delegate)(arglist(calling_args))
	return call(object, delegate)(arglist(calling_args))

/// Identity string used for TIMER_UNIQUE matching.
/datum/callback/proc/Hash(wait)
	var/list/parts = list()
	if(isnull(object))
		parts += "null"
	else if(istext(object))
		parts += object
	else
		parts += "\ref[object]"
	parts += "[delegate]"
	if(!isnull(wait))
		parts += "w[wait]"
	for(var/arg in arguments)
		parts += istype(arg, /datum) ? "\ref[arg]" : "[arg]"
	return jointext(parts, "|")

// ---------------------------------------------------------------------------
// Timer record
// ---------------------------------------------------------------------------

/datum/timer
	var/id
	var/datum/callback/callback
	/// Original delay, reused when looping.
	var/wait = 0
	var/flags = 0
	/// Absolute fire time (world.time, or realtime() for TIMER_CLIENT_TIME).
	var/time_to_run = 0
	var/hash
	var/cancelled = FALSE

// ---------------------------------------------------------------------------
// The engine
// ---------------------------------------------------------------------------

/// Lazily-created singleton. Call TIMERS() rather than instantiating directly.
/proc/TIMERS()
	var/static/datum/timer_engine/engine
	if(!engine)
		engine = new
		engine.Start()
		engine.Watchdog()
	return engine

/datum/timer_engine
	/// Min-heaps of /datum/timer, ordered by time_to_run.
	var/list/heap = list()    // keyed to world.time
	var/list/rt_heap = list() // keyed to realtime()
	/// "id" (as text) -> /datum/timer
	var/list/lookup = list()
	/// hash -> id, for TIMER_UNIQUE
	var/list/hashes = list()
	var/next_id = 1
	var/running = FALSE
	var/last_tick = 0
	/// Yield the rest of the queue to the next tick above this % of tick budget.
	var/tick_budget = 85

/datum/timer_engine/proc/Start()
	set waitfor = FALSE
	if(running)
		return
	running = TRUE
	while(running)
		last_tick = world.time
		Tick()
		sleep(world.tick_lag)

/datum/timer_engine/proc/Stop()
	running = FALSE

/**
 * A hard runtime inside a callback can unwind the main loop. Callbacks are
 * already wrapped in try/catch, but this restarts the loop if it ever dies
 * anyway, so a single bad proc can't silently kill every timer in the game.
 */
/datum/timer_engine/proc/Watchdog()
	set waitfor = FALSE
	while(TRUE)
		sleep(2 SECONDS)
		if(running && (world.time - last_tick) > 3 SECONDS)
			world.log << "timer_engine: main loop stalled, restarting."
			running = FALSE
			Start()

/datum/timer_engine/proc/Tick()
	var/now = world.time
	while(length(heap))
		var/datum/timer/next = heap[1]
		if(next.time_to_run > now)
			break
		if(world.tick_usage > tick_budget)
			return // finish the rest next tick
		HeapPop(heap)
		Fire(next, now)

	if(!length(rt_heap))
		return
	var/rnow = realtime()
	while(length(rt_heap))
		var/datum/timer/next = rt_heap[1]
		if(next.time_to_run > rnow)
			break
		if(world.tick_usage > tick_budget)
			return
		HeapPop(rt_heap)
		Fire(next, rnow)

/datum/timer_engine/proc/Fire(datum/timer/T, now)
	if(T.cancelled)
		Forget(T)
		return

	// Re-arm or retire *before* invoking, so a runtime in the callback can't
	// break the loop chain or leave a stale lookup entry.
	if(T.flags & TIMER_LOOP)
		T.time_to_run = now + max(T.wait, world.tick_lag)
		Schedule(T)
	else
		Forget(T)

	try
		T.callback.Invoke()
	catch(var/exception/e)
		world.log << "timer callback error: [e.name] ([e.file]:[e.line])"

/datum/timer_engine/proc/Add(datum/callback/cb, wait = 0, flags = 0)
	if(!istype(cb))
		world.log << "addtimer: first argument must be a /datum/callback."
		return null
	if(isnull(cb.object))
		return null // target already deleted

	wait = max(wait, 0)

	var/hash
	if(flags & TIMER_UNIQUE)
		hash = cb.Hash((flags & TIMER_NO_HASH_WAIT) ? null : wait)
		var/existing_id = hashes[hash]
		if(!isnull(existing_id))
			var/datum/timer/existing = lookup["[existing_id]"]
			if(existing && !existing.cancelled)
				if(flags & TIMER_OVERRIDE)
					Cancel(existing_id)
				else
					return existing_id

	var/datum/timer/T = new
	T.id = next_id++
	T.callback = cb
	T.wait = wait
	T.flags = flags
	T.hash = hash
	// max(..., tick_lag) guarantees a timer never fires on the tick it was
	// created, which also makes a 0-wait TIMER_LOOP safe.
	T.time_to_run = ((flags & TIMER_CLIENT_TIME) ? realtime() : world.time) + max(wait, world.tick_lag)

	lookup["[T.id]"] = T
	if(hash)
		hashes[hash] = T.id
	Schedule(T)
	return T.id

/datum/timer_engine/proc/Cancel(id)
	if(isnull(id))
		return FALSE
	var/datum/timer/T = lookup["[id]"]
	if(!T)
		return FALSE
	T.cancelled = TRUE // lazily removed from the heap when it comes due
	Forget(T)
	return TRUE

/datum/timer_engine/proc/Forget(datum/timer/T)
	lookup -= "[T.id]"
	if(T.hash && hashes[T.hash] == T.id)
		hashes -= T.hash

// --- heap ------------------------------------------------------------------

/datum/timer_engine/proc/Schedule(datum/timer/T)
	var/list/h = (T.flags & TIMER_CLIENT_TIME) ? rt_heap : heap
	h += T
	var/index = length(h)
	while(index > 1)
		var/parent_index = round(index / 2)
		var/datum/timer/parent = h[parent_index]
		if(parent.time_to_run <= T.time_to_run)
			break
		h[index] = parent
		h[parent_index] = T
		index = parent_index

/datum/timer_engine/proc/HeapPop(list/h)
	var/datum/timer/top = h[1]
	var/size = length(h)
	if(size == 1)
		h.Cut(1, 2)
		return top

	h[1] = h[size]
	h.Cut(size, size + 1)
	size--

	var/index = 1
	while(TRUE)
		var/left = index * 2
		var/right = left + 1
		var/smallest = index
		var/datum/timer/best = h[index]

		if(left <= size)
			var/datum/timer/candidate = h[left]
			if(candidate.time_to_run < best.time_to_run)
				smallest = left
				best = candidate
		if(right <= size)
			var/datum/timer/candidate = h[right]
			if(candidate.time_to_run < best.time_to_run)
				smallest = right
				best = candidate

		if(smallest == index)
			break

		var/datum/timer/swap = h[index]
		h[index] = h[smallest]
		h[smallest] = swap
		index = smallest

	return top

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Schedules `callback` to run in `wait` deciseconds.
 * Returns a timer id usable with deltimer() / timeleft(), or null on failure.
 */
/proc/addtimer(datum/callback/callback, wait = 0, flags = 0)
	return TIMERS().Add(callback, wait, flags)

/// Cancels a pending timer. Returns TRUE if one was actually cancelled.
/proc/deltimer(id)
	return TIMERS().Cancel(id)

/// Deciseconds until the timer fires, or null if it isn't pending.
/proc/timeleft(id)
	if(isnull(id))
		return null
	var/datum/timer_engine/E = TIMERS()
	var/datum/timer/T = E.lookup["[id]"]
	if(!T || T.cancelled)
		return null
	var/now = (T.flags & TIMER_CLIENT_TIME) ? realtime() : world.time
	return max(T.time_to_run - now, 0)

/// TRUE if the timer is still pending.
/proc/timerpending(id)
	return !isnull(timeleft(id))

/*
 * ---------------------------------------------------------------------------
 * Examples
 * ---------------------------------------------------------------------------
 *
 * // Simple delayed call
 * /mob/proc/Stun(duration)
 *     stunned = TRUE
 *     addtimer(CALLBACK(src, PROC_REF(Unstun)), duration)
 *
 * /mob/proc/Unstun()
 *     stunned = FALSE
 *
 * // Cancellable
 * /mob/proc/BeginCast()
 *     cast_timer = addtimer(CALLBACK(src, PROC_REF(FinishCast)), 3 SECONDS)
 *
 * /mob/proc/InterruptCast()
 *     deltimer(cast_timer)
 *     cast_timer = null
 *
 * // Repeating
 * /obj/machine/proc/PowerOn()
 *     process_timer = addtimer(CALLBACK(src, PROC_REF(Process)), 2 SECONDS, TIMER_LOOP)
 *
 * // Only one regen timer per mob, refreshed on each hit
 * /mob/proc/TakeDamage(amount)
 *     health -= amount
 *     addtimer(CALLBACK(src, PROC_REF(StartRegen)), 10 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
 *
 * // Bound arguments, plus a global proc
 * addtimer(CALLBACK(src, PROC_REF(Say), "hello"), 1 SECOND)
 */
