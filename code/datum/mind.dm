/datum/mind
	var/key // ckey
	var/mob/human/current // current human

	var/list/skills = list()
	var/list/datum/quirk/quirks = list()
	
	var/mental_state = MENTAL_STATE_BASELINE

	var/datum/goal/goal
	var/datum/goal/antag/special_goal // dissident goals
	var/dissident = FALSE

	var/paycheck = 0
	var/performance_paycheck = 0 // You can increase your normal paycheck by doing your JOB. This value gets added to the default paycheck your job gets.
	var/bonus_paycheck = 0 // director assigned bonus that doesnt get wiped on pay cycle

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

/datum/mind/proc/get_paycheck_to_pay()
	if(!current_job)
		return 0
	return current_job.paycheck + performance_paycheck + bonus_paycheck

/datum/mind/proc/get_paycheck_amount()
	if(!current_job)
		return 0
	return paycheck + performance_paycheck + bonus_paycheck

/datum/mind/proc/nullify_paychecks()
	paycheck = 0
	performance_paycheck = 0
	bonus_paycheck = 0