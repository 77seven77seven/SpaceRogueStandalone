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
	if(wanted_timer > 0)
		wanted_timer = max(0, wanted_timer - elapsed)
	wanted = wanted_timer > 0

/mob/human/proc/IsCrimeWitnessed()
	if(!station)
		return FALSE

	for(var/obj/deco/camera/C in station.cameras)
		if(C in view(world.view, get_turf(src)))
			return TRUE

	for(var/mob/human/H in viewers(world.view, get_turf(src)))
		if(H == src || H.dead || !H.HasImplant(/datum/implant/enforcer))
			continue
		return TRUE
	return FALSE

/mob/human/proc/CommitCrime(crime, crime_duration, mark_outlaw = FALSE, verified_dissidence = FALSE)
	if(dead)
		return FALSE

	if(HasImplant(/datum/implant/enforcer) && !verified_dissidence)
		if(crime_duration <= 90 SECONDS)
			EnforcerWarningShock()
		return FALSE

	if(!verified_dissidence && !IsCrimeWitnessed())
		return FALSE

	ProcessWantedStatus()
	var/was_wanted = wanted
	var/announce_crime = !was_wanted || crime_duration > last_crime_duration
	wanted_timer = min(5 MINUTES, wanted_timer + crime_duration)
	wanted = TRUE
	last_crime_duration = crime_duration

	if(mark_outlaw)
		outlaw = TRUE

	if(announce_crime)
		var/announcement = "[src] HAS BEEN MARKED FOR EMERGENCY [pick("TERMINATION","THREAT NEUTRALIZATION","THREAT TERMINATION")] FOR VIOLATION OF IMPKOD § [rand(1,13)].[rand(63,299)]: [crime]."
		chat_announce(announcement, "bad")
	return TRUE

/mob/human/proc/EnforcerWarningShock()
	chat_info("LIABILITY! LIABILITY! CONTROLLED SHOCK ADMINISTERED.", "bad")
	playsound(get_turf(src), 'sound/effects/pda/airlock_deny.ogg', 100, TRUE)
	TakeDamage(15, "enforcer implant shock")

/mob/human/proc/IsCriminalTarget()
	ProcessWantedStatus()
	return wanted || outlaw

/mob/human/proc/IsAuthorizedEnforcerTarget(mob/human/target)
	return HasImplant(/datum/implant/enforcer) && target && target.IsCriminalTarget()

/mob/human/proc/EnforcerAttackAllowed(mob/human/target)
	if(!HasImplant(/datum/implant/enforcer) || !target || target.IsCriminalTarget())
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