/client
	var/xp = 6 // saves
	var/datum/role/previously_played // saves too. reset when you successfully escape (do not set when success escape)

	var/dissidence_preference = FALSE
	var/presentation_preference = NEUTER // NEUTER = pick randomly between male or female

/client/verb/fuckyou()
	if(master)
		world << "master = OK"
	if(processor)
		world << "processor = OK"

var
  worldstarttime = 0
  worldstarttimeofday = 0
client
  Stat()
    if (!worldstarttime || worldstarttimeofday)
      worldstarttime = world.time
      worldstarttimeofday = world.timeofday
    var/tickdrift = (world.timeofday - worldstarttimeofday) - (world.time - worldstarttime)  / world.tick_lag
    statpanel("Tick Drift", "[round(tickdrift)] Missed ticks")
    ..()