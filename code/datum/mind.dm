/datum/mind
	/// ckey
	var/key
	// current human
	var/mob/human/current

	var/list/skills = list()
	var/list/datum/quirk/quirks = list()

	var/datum/goal/goal
	var/datum/goal/antag/special_goal // dissident goals

	var/dissident = FALSE

	var/datum/role/current_job

/datum/mind/New(key)
	src.key = key
	//set_current_job(master.GetJobType(/datum/role/unassigned))

/datum/mind/proc/SetSkill(new_skill, level)
	skills[new_skill] = clamp(level, 1, 100)

/datum/mind/proc/AddSkill(new_skill, level)
	if(skills[new_skill])
		skills[new_skill] = clamp(skills[new_skill] + level, 1, 100)
	else
		SetSkill(new_skill, level)

/datum/mind/proc/GetSkill(skillget)
	if(skills[skillget])
		return skills[skillget]
	else
		return FALSE

/datum/mind/proc/HasQuirk(quirk_type)
	for(var/datum/quirk/Q in quirks)
		if(Q.type == quirk_type) return TRUE

/// Setter for the current_job job datum.
/datum/mind/proc/set_current_job(datum/role/new_role)
	if(!istype(new_role))
		new_role = ispath(new_role) ? master.GetJobType(new_role) : master.GetJob(new_role)
	if(current_job == new_role)
		return current_job
	. = current_job
	
	current_job = new_role
	current_job.current_positions++