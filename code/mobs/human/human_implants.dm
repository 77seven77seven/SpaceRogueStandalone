// Essentially quirks.
// Yeah.

/datum/implant
	var/name = "genericia"
	var/technical_name = "GENIRICI-7fN"
	var/dissident_only = FALSE // If it can only be detected by Dissidents or people very well trained in identifying dissident technology.

/mob/human/proc/HasImplant(implant_type)
	for(var/datum/implant/Q in implants)
		if(Q.type == implant_type) return TRUE

/mob/human/proc/ProcessWantedStatus()
	var/elapsed = max(0, world.time - last_wanted_update)
	last_wanted_update = world.time
	wanted_timer = max(0, wanted_timer - elapsed)
	var/old_wanted = wanted
	wanted = wanted_timer > 0
	if(old_wanted && !wanted)
		var/list/lines = list("I got away with it!","Bless the Lord.","Oh, thank the Lord!","Hell yeah.","Never lost my charm.")
		if(outlaw)
			lines = list("I should be careful though, they're not bound to forgive that.","I should stay out of sight, if they realize who I am... it might be bad.")
		chat_info("The Enforcers shouldn't be after me anymore. <b>[pick(lines)]</b>")

/mob/human/proc/IsDirector()
	return mind && istype(mind.current_job, /datum/role/director)

/mob/human/proc/IsCrimeWitnessed()
	if(!station)
		return FALSE

	for(var/obj/machine/camera/C in view(world.view, get_turf(src)))
		if(!C.broken)
			if(prob(1))
				C.broken()
			else
				return TRUE
		continue

	for(var/mob/human/H in viewers(world.view, get_turf(src)))
		if(H == src || H.dead || !H.HasImplant(/datum/implant/enforcer))
			continue
		return TRUE
	return FALSE

/mob/human/proc/CommitCrime(crime, crime_duration, mark_outlaw = FALSE, verified_dissidence = FALSE, force = FALSE)
	if(dead)
		return FALSE

	if(IsDirector())
		return FALSE

	if(HasImplant(/datum/implant/enforcer) && !verified_dissidence && !force)
		if(crime_duration <= 90 SECONDS)
			EnforcerWarningShock()
		return FALSE

	if(!verified_dissidence && !force && !IsCrimeWitnessed())
		return FALSE

	ProcessWantedStatus()
	var/announce_crime = !wanted || crime_duration > last_crime_duration
	wanted_timer = min(5 MINUTES, wanted_timer + crime_duration)
	wanted = TRUE
	last_crime_duration = crime_duration

	if(mark_outlaw)
		outlaw = TRUE

	if(announce_crime)
		for(var/mob/human/H in station.humans)
			if(is_stationbound(H))
				H.playsound_local(get_turf(src), 'sound/effects/announce/alarm.ogg', 50)
		spawn(3 SECONDS)
			var/announcement = "[src] HAS BEEN MARKED FOR EMERGENCY [pick("TERMINATION","THREAT NEUTRALIZATION","THREAT TERMINATION")] FOR VIOLATION OF IMPKOD § [rand(1,13)].[rand(63,299)]: [crime]."
			chat_announce(announcement, "bad")
	return TRUE

/mob/human/proc/CommitAttackCrime(mob/human/target, crime, crime_duration, mark_outlaw = FALSE)
	if(target && target.IsDirector())
		return CommitCrime(target.dead ? "TERRORISM" : "ASSAULT OF LOCAL GOVERNMENT", 5 MINUTES, target.dead, FALSE, TRUE)
	return CommitCrime(crime, crime_duration, mark_outlaw)

/mob/human/proc/EnforcerWarningShock()
	chat_info("<b>LIABILITY! LIABILITY! CONTROLLED SHOCK ADMINISTERED.<b>", "bad")
	playsound(get_turf(src), 'sound/effects/pda/airlock_deny.ogg', 100, TRUE)
	TakeDamage(15, "enforcer implant shock")
	AdjustSorrow(rand(13,24))

/mob/human/proc/IsCriminalTarget()
	ProcessWantedStatus()
	return wanted || outlaw

/mob/human/proc/IsAuthorizedEnforcerTarget(mob/human/target)
	return HasImplant(/datum/implant/enforcer) && target && target.IsCriminalTarget()

/mob/human/proc/EnforcerAttackAllowed(mob/human/target)
	if(IsDirector() || !HasImplant(/datum/implant/enforcer) || !target || target.IsDirector() || target.IsCriminalTarget())
		return TRUE

	EnforcerWarningShock()
	return FALSE

/mob/human/proc/IsIllegalFirearmUser()
	if(!station || station.legality_guns || HasImplant(/datum/implant/firearms))
		return FALSE
	return !mind?.current_job?.corporate

/datum/implant/enforcer // The implant that enforcers start with, making them unable to hit people (without being shocked) unless they're wanted or trespassing.
	name = "SIDEREALED"
	technical_name = "SP-SIDEREALED V73.9: Enforcement Compliance Safety Insurance"

/datum/implant/trespass // Technician starts with this one. People that are trespassing can be beaten by enforcers.
	name = "TRESPA-SS"
	technical_name = "CHEZG. UNAUTHORIZED-ZONING EXCLUSION MECHANISM"

/datum/implant/firearms // Can shoot and own firearms without becoming wanted. Corpos are excluded from that check, so they don't need an implant.
	name = "3F-NEVER TIREARMS FIREARMS"
	technical_name = "CHEZG. UNAUTHORIZED-OWNERSHIP EXCLUSION MECHANISM"

/datum/implant/vigilante // Can kill wanted people like an enforcer.
	name = "VIGIL-SUPERVACLAvIGILANTE"
	technical_name = "CHEZG. UNAUTHORIZED-TERMINATION EXCLUSION MECHANISM"