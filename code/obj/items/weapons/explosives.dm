/proc/explosion(turf/epicenter, radius = 5, max_damage = 160, shrapnel = 0, source = "explosion")
	if(!istype(epicenter, /turf) || radius <= 0 || max_damage <= 0)
		return FALSE

	playsound(epicenter, 'sound/Explosion.ogg', 100, TRUE, 6, ignore_walls = TRUE)

	for(var/mob/human/H in range(radius, epicenter))
		var/distance = get_dist(epicenter, H)
		var/behind_wall = FALSE
		if(distance > 1)
			var/turf/target_turf = get_turf(H)
			var/turf/scan_turf = get_turf(epicenter)
			for(var/i in 1 to distance - 1)
				scan_turf = get_step(scan_turf, get_dir(scan_turf, target_turf))
				if(!scan_turf)
					break
				if(scan_turf.density)
					behind_wall = TRUE
					break
				for(var/atom/A in scan_turf)
					if(A != H && A.density)
						behind_wall = TRUE
						break
				if(behind_wall)
					break

		var/damage = round(max_damage * (radius + 1 - distance) / (radius + 1))
		if(behind_wall && distance > 2)
			continue
		if(damage > 0)
			var/damage_factor = clamp(damage / 50, 1, 4)
			if(prob(90 + min(10, damage_factor * 5)))
				H.SetRagdolled(TRUE)
				H.go_blind(3 + damage_factor, 40 + damage_factor * 20)
			H.TakeDamage(damage, "[source]")
			var/amplitude = min(7, round((damage / 35) + 2))
			var/pixel_x_diff = ceil(rand(-amplitude, amplitude))
			var/pixel_y_diff = ceil(rand(-amplitude/3, amplitude/2))
			animate(H, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
			animate(pixel_x = -pixel_x_diff , pixel_y = -pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE)

			if(prob(rand(25,50) + damage_factor * 10))
				if(H.blood)
					new /atom/movable/blood/splatter(get_turf(H), H)

			if(prob(70 + min(20, damage_factor * 10)))
				H.AdjustBrainDamage(rand(1,2) + max(0, damage_factor - 1))

			if(prob(80 + min(15, damage_factor * 5)))
				H.BreakBones(1, damage_factor)

			if(shrapnel)
				if(!behind_wall)
					for(var/i in 1 to max(1, round(shrapnel * (damage / max(1, max_damage)))))
						if(prob(40 + damage_factor * 10) && H.shrapnel < H.max_shrapnel)
							H.shrapnel++
					H.AdjustBleeding(rand(10,40) + damage_factor * 5)
			else if(damage > 0)
				H.AdjustBleeding(rand(5,20) + damage_factor * 4)

	return TRUE

/obj/item/explosive
	name = "timed explosive"
	desc = "Activate this explosive to arm it. It will detonate after a short fuse."

	var/fuse = 5 SECONDS
	var/detonation_timer
	var/armed = FALSE

	var/blast_radius = 4
	var/blast_damage = 300

/obj/item/explosive/use(mob/human/H)
	if(armed || !H || H.holding != src || H.dead || H.ragdolled)
		return FALSE

	var/turf/drop_turf = get_turf(H)
	if(!drop_turf)
		return FALSE
	armed = TRUE
	name = "armed timed explosive"

	H.holding = null
	H.UpdateInhand()
	
	forceMove(drop_turf)
	update_transform()

	detonation_timer = addtimer(CALLBACK(src, PROC_REF(Detonate)), fuse)
	return TRUE

/obj/item/explosive/proc/Detonate()
	var/turf/detonation_turf = get_turf(src)
	if(detonation_turf)
		explosion(detonation_turf, blast_radius, blast_damage, max(2, round(blast_damage / 50)), src.name)
	qdel(src)

/obj/item/explosive/Destroy(force = FALSE)
	if(detonation_timer)
		deltimer(detonation_timer)
		detonation_timer = null
	return ..()