/client
	var/xp = 0 // saves
	var/datum/job/previously_played

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