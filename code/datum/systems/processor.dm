/datum/system/processor
	var/list/processing = list()

/datum/system/processor/setup()
	Ticker()

/datum/system/processor/proc/Ticker()
	set background = 1
	spawn while(1)
		for(var/datum/D in processing)
			D.Process()
			sleep(world.tick_lag)

/datum/proc/Process()
	processor.processing -= src
	return