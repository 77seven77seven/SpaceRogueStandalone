/datum/mind
	/// ckey
	var/key
	// current human
	var/mob/human/current

	var/list/skills = list()
	var/list/datum/trait/traits = list()

	var/datum/goal/goal
	var/datum/goal/special/special_goal

	var/datum/job/current_job

/datum/mind/New(key)
	src.key = key
	set_current_job(master.GetJobType(/datum/job/unassigned))

/// Setter for the current_job job datum.
/datum/mind/proc/set_current_job(datum/job/new_role)
	if(!istype(new_role))
		new_role = ispath(new_role) ? master.GetJobType(new_role) : master.GetJob(new_role)
	if(current_job == new_role)
		return current_job
	. = current_job
	current_job = new_role