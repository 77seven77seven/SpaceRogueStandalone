// Essentially quirks.
// Yeah.

/datum/implant
	var/name = "genericia"
	var/technical_name = "GENIRICI-7fN"
	var/dissident_only = FALSE // If it can only be detected by Dissidents or people very well trained in identifying dissident technology.

/mob/human/proc/HasImplant(implant_type)
	for(var/datum/implant/Q in implants)
		if(Q.type == implant_type) return TRUE

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