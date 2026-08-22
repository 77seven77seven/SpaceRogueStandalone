/datum/system/master
	var/list/all_occupations = list()
	var/list/name_occupations = list()
	var/list/type_occupations = list()

/datum/system/master/setup()
	SetupJobs()

/datum/system/master/proc/SetupJobs()
	var/list/all_jobs = subtypesof(/datum/role)
	if(!length(all_jobs))
		return FALSE

	for(var/job_type in all_jobs)
		var/datum/role/job = new job_type()

		all_occupations += job
		name_occupations[job.title] = job
		type_occupations[job_type] = job
	return TRUE

/datum/system/master/proc/GetJob(rank)
	if(!length(all_occupations))
		SetupJobs()
	return name_occupations[rank]

/datum/system/master/proc/GetJobType(jobtype)
	if(!length(all_occupations))
		SetupJobs()
	return type_occupations[jobtype]