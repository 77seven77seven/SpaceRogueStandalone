#define AMMO_SMALL "SMALL" // Common for small pistols.
#define AMMO_MEDIU "MEDIUM" // Rare ammo, used mostly for exotic firearms. Not commonly found in vending machines.
#define AMMO_BIG "BIG" // Big 
#define AMMO_SHELLS "SHELLS"

#define SMALL_AMMO AMMO_SMALL
#define MEDIU_AMMO AMMO_MEDIU
#define BIG_AMMO AMMO_BIG
#define SHOTG_AMMO AMMO_SHELLS
#define AMMO_MEDIUM AMMO_MEDIU

/obj/item/gun
	name = "Wonder"
	desc = "The Wonder is one of the Wonder Nines family of firearms. An iconic, all-metal small bulleted semi-automatic pistol."
	desc_expansive = "The Wonder Nines family of firearms has nine sons, all which have only nine bullet capacity due to legal standards. This gun is most widely used in CHEZ Group operated regions, even though most employees of the corporation use alternatives."
	desc_expansive_extra_skill = GUNS

	icon = 'icons/obj/guns/guns_small.dmi'
	icon_state = "gun"
	inhand_icon = 'icons/human/inhands/guns.dmi'
	inhand_icon_state = "gun"

	vendor_price = 145

	var/list/gunshot_sounds = list('sound/effects/obj/guns/pistol1.ogg','sound/effects/obj/guns/pistol2.ogg','sound/effects/obj/guns/pistol3.ogg')

	var/damage = 20
	var/headshot_damage = 99 // Basically all headshots are deadly.
	
	var/ammo_type = AMMO_SMALL
	var/ammo_loaded = 9
	var/ammo_max = 9
	var/ejects_casings = TRUE
	var/ejects_casings_on_reload = FALSE
	var/casings_to_eject = 0

	var/range = 20 * WORLD_ICON_SIZE       // pixels, 20 tiles, enough basically
	
	var/spread = 10                   // measured in pixels
	var/spread_range = 4 * WORLD_ICON_SIZE  // ...measured at this distance (keep > spread)
	var/accuracy = 1                  // Higher values reduce spread; override per gun type.
	
	var/fire_delay = 3                // deciseconds
	var/next_fire = 0

	var/tracers = TRUE
	var/pellets = 1
	var/pellet_damage_multiplier = 1

/obj/item/gun/revolver
	name = "Alpha"
	desc = "AlphaProj high-calibre revolvers are a staple of any self-respecting gun owner. Recently they have gotten a bad reputation due to their involvement in the Ganymedean Civil War."
	desc_expansive = "A man pulls the trigger on a deserter, his brains are blown out, the executioner looks at the weapon of infamy in his hand. It is an Alpha. Holds six rounds, evidently."

	icon_state = "revolver"
	gunshot_sounds = list('sound/effects/obj/guns/revolver1.ogg','sound/effects/obj/guns/revolver2.ogg')
	accuracy = 0.95 // It's a snubnose revolver.
	fire_delay = 8

	ejects_casings_on_reload = TRUE

	ammo_type = AMMO_BIG
	ammo_loaded = 6
	ammo_max = 6

	vendor_price = 210

	damage = 40
	headshot_damage = 100

/obj/item/gun/revolver/gunvolver
	name = "Architect"
	icon_state = "gunvolver"
	desc = "Something isn't right here..."
	desc_expansive = "You're not sure, but something about this gun reminds you of prisons."

	vendor_price = 238

/obj/item/gun/silenced
	name = "Resolutionist"
	icon_state = "silenced"
	
	desc = "This weapon has resolved more political conflicts than mere words ever will."
	desc_expansive = "A weapon favored by those that are usually unwilling to give up a weapon. Due to the internal structure of the weapon, it both has a built-in suppressor and flash hider. For portability and a low profile, it only holds four rounds of a small caliber."
	
	tracers = FALSE
	ejects_casings_on_reload = TRUE

	vendor_price = 138

	damage = 10
	headshot_damage = 89

	ammo_loaded = 4
	ammo_max = 4
	fire_delay = 2

/obj/item/gun/assault
	name = "Template"
	desc = "Template 58. These firearms combined have more lives claimed than disease and famine, while bringing death and war."
	desc_expansive = "There is nothing more to say about it. Holds thirty rounds of large calibers."

	icon = 'icons/obj/guns/guns_wide.dmi'
	icon_state = "arifle"
	inhand_icon_state = "arifle"

	dropshrink = 0.7

	fire_delay = 1
	damage = 40
	headshot_damage = 100
	
	vendor_price = 12500

	gunshot_sounds = list('sound/effects/obj/guns/rifle.ogg')
	
	ammo_type = AMMO_BIG
	ammo_loaded = 30
	ammo_max = 30

/obj/item/gun/shotgun
	name = "Blunder"
	desc = "A light, close-range scattergun built for stopping power at point-blank range."
	desc_expansive = "The Blunder fires eight pellets in a spread, making it effective at close quarters. Holds six shells."

	icon = 'icons/obj/guns/guns_wide.dmi'
	icon_state = "shotgun"
	inhand_icon_state = "shotgun"
	gunshot_sounds = list('sound/effects/obj/guns/shotgun.ogg')

	ammo_type = AMMO_SHELLS
	ammo_loaded = 6
	ammo_max = 6

	vendor_price = 300

	dropshrink = 0.7

	damage = 8
	headshot_damage = 80
	fire_delay = 12
	spread = 30
	spread_range = 3 * WORLD_ICON_SIZE
	pellets = 8
	accuracy = 0.8

/obj/item/gun/proc/CanFire(mob/shooter)
	if(ammo_max > 0 && ammo_loaded <= 0)
		return FALSE
	return TRUE

/obj/item/gun/proc/Reload(mob/human/shooter)
	if(!shooter || !ammo_type || ammo_loaded >= ammo_max)
		return FALSE
	if(!shooter.ammo)
		shooter.ammo = list()

	var/available = shooter.ammo[ammo_type] || 0
	if(!available)
		return FALSE

	var/needed = ammo_max - ammo_loaded
	var/added = min(needed, available)
	if(added <= 0)
		return FALSE

	shooter.ammo[ammo_type] = max(0, available - added)
	ammo_loaded += added

	playsound(get_turf(shooter), 'sound/effects/obj/guns/reload.ogg', 90, TRUE)
	if(ejects_casings_on_reload && casings_to_eject)
		EjectCasings(shooter, casings_to_eject)
		casings_to_eject = 0

	return TRUE

/obj/item/gun/proc/EjectCasings(mob/shooter, count)
	for(var/i in 1 to count)
		spawn(rand(0.1,0.4))
			new /atom/movable/casing(get_turf(shooter))
			playsound(get_turf(shooter), 'sound/effects/obj/guns/casing.ogg', 65, TRUE)

/obj/item/gun/use(mob/human/H)
	. = ..()
	Reload(H)

/obj/item/gun/proc/Fire(mob/shooter, atom/target, aim_x, aim_y)
	if(!CanFire(shooter))
		if(ishuman(shooter))
			if(ammo_loaded <= 0)
				return
		else
			return
	if(world.time < next_fire)
		return
	next_fire = world.time + fire_delay
	ammo_loaded = max(0, ammo_loaded - 1)

	// Muzzle = centre of the shooter, in world pixels
	var/ox = (shooter.x - 1) * WORLD_ICON_SIZE + shooter.step_x + WORLD_ICON_SIZE / 2
	var/oy = (shooter.y - 1) * WORLD_ICON_SIZE + shooter.step_y + WORLD_ICON_SIZE / 2

	// Unit vector toward the aim point
	var/dx = aim_x - ox
	var/dy = aim_y - oy
	var/aim_distance = sqrt(dx * dx + dy * dy)
	if(aim_distance < 1)
		return
	dx /= aim_distance
	dy /= aim_distance

	var/atom/movable/aimed_target
	var/turf/aimed_turf
	var/target_x
	var/target_y
	var/aimed_zone
	if(istype(target, /atom/movable))
		aimed_target = target
		aimed_turf = get_turf(aimed_target)
		if(aimed_turf)
			target_x = (aimed_turf.x - 1) * WORLD_ICON_SIZE + aimed_target.step_x
			target_y = (aimed_turf.y - 1) * WORLD_ICON_SIZE + aimed_target.step_y
			aimed_zone = aimed_target.GetHitZoneAt(aim_x - target_x, aim_y - target_y)

	var/gun_skill = 0
	if(istype(shooter, /mob/human))
		var/mob/human/human_shooter = shooter
		gun_skill = clamp(human_shooter.mind?.GetSkill(GUNS) || 0, 0, 100)

	var/skill_spread_multiplier = 1 - (gun_skill / 100 * 0.8)
	var/head_aim_spread_multiplier = aimed_zone == "head" ? 3 : 1
	var/effective_spread = spread * skill_spread_multiplier * head_aim_spread_multiplier / max(accuracy, 0.01)

	var/shot_distance = min(aim_distance, range)
	var/impact_x = ox + dx * shot_distance
	var/impact_y = oy + dy * shot_distance
	var/pellet_count = max(1, pellets)
	var/list/pellet_impacts = list()
	for(var/i in 1 to pellet_count)
		var/shot_impact_x = impact_x
		var/shot_impact_y = impact_y
		if(effective_spread > 0)
			var/ang = rand() * 360
			var/rad = effective_spread * (shot_distance / max(spread_range, 1)) * sqrt(rand())
			shot_impact_x += rad * cos(ang)
			shot_impact_y += rad * sin(ang)
		pellet_impacts += list(list("x" = shot_impact_x, "y" = shot_impact_y))

	var/pellet_hits = 0
	var/headshot_hits = 0
	var/list/blocked_hits = list() // bystander -> list("hits", "head")
	for(var/list/impact in pellet_impacts)
		// Indirect friendly fire: anyone standing in the line of fire catches the pellet.
		var/list/block = FindBlocker(shooter, aimed_target, ox, oy, impact["x"], impact["y"])
		if(block)
			var/mob/human/blocker = block["mob"]
			impact["x"] = block["x"] // tracer now ends at the body that stopped it
			impact["y"] = block["y"]
			var/list/record = blocked_hits[blocker]
			if(!record)
				record = list("hits" = 0, "head" = 0)
				blocked_hits[blocker] = record
			record["hits"]++
			if(block["zone"] == "head")
				record["head"]++
			continue
		if(aim_distance <= range && target != shooter && aimed_target && aimed_turf)
			var/pellet_zone = aimed_target.GetHitZoneAt(impact["x"] - target_x, impact["y"] - target_y)
			if(pellet_zone)
				pellet_hits++
				if(pellet_zone == "head")
					headshot_hits++

	animate(shooter?.client, color = "#f3d4d4ff", easing = EASE_OUT, time = 0.5)
	animate(color = "#ffefef", easing = EASE_IN, time = 0.5)

	if(ishuman(shooter))
		var/mob/human/human_shooter = shooter
		human_shooter.ApplyFiringSlowdown()

	firearm_recoil_mob(shooter)

	var/recoil = 16 - round(gun_skill / 100 * 14)
	shake_cam(shooter, 2, recoil)

	playsound(get_turf(shooter), pick(gunshot_sounds), 75, TRUE, ignore_walls = TRUE)
	var/rand_vol = rand(30,60)
	for(var/mob/M in station.humans)
		var/turf/M_turf = get_turf(M)
		if(!M_turf)
			continue
		if(get_dist(M_turf, shooter.loc) < 7)
			continue
		M.playsound_local(M_turf, 'sound/effects/obj/guns/distantshot.ogg', rand_vol, 1, get_rand_frequency(), falloff_exponent = 5)

	if(tracers)
		for(var/list/impact in pellet_impacts)
			new /obj/bullet_tracer(get_turf(shooter), ox, oy, impact["x"], impact["y"])
	if(ejects_casings)
		if(ejects_casings_on_reload)
			casings_to_eject++
		else
			EjectCasings(shooter, 1)

	if(istype(target, /mob/human) && pellet_hits)
		ApplyHit(shooter, target, pellet_hits, headshot_hits)
	for(var/mob/human/blocker in blocked_hits)
		var/list/record = blocked_hits[blocker]
		ApplyHit(shooter, blocker, record["hits"], record["head"])

/obj/item/gun/proc/ApplyHit(mob/shooter, mob/human/victim, pellet_hits, headshot_hits)
	var/hit_zone = headshot_hits ? "head" : "body"
	var/pellet_damage = max(1, round(damage * pellet_damage_multiplier))
	var/dmg = pellet_damage * pellet_hits
	if(headshot_hits && !victim.brainsploded)
		var/list/brainlines = list(
		"EEEWWWWW!",
		"I THINK I'M GOING TO BE SICK!!!",
		"THAT'S DISGUSTING!!!",
		"OH MY GOD THAT'S THEIR EVERYTHING!!!",
		"Ourgh.. OURG! I'M GONNA PUKE!",
		"Oh my God, oh my GOD! WHAT IS THAT?!"
		)
		
		var/list/brainlines_psycho = list(
		"Oh! Cool!",
		"FIREWORKS!!",
		"Now we can see what they really think!",
		"The yeast of the mind!",
		"Let me pick at their thoughts!",
		"Penny for your thoughts? I'd gladly pay! Hehe.",
		"Oooooh! I always wondered if it was pink or grey. Turns out its both!",
		"Brilliant!"
		)
		
		var/list/brainlines_minor = list(
		"Not again...",
		"I've cleaned up messes like this before... this won't be fun...",
		"You could've aimed ANYWHERE else.",
		"Unnecessary man... completely unnecessary.",
		"Come on..."
		)

		for(var/mob/human/H in oviewers(world.view, victim))
			if(!H.client)
				continue

			var/style = "bad"
			var/mood = rand(20,40)

			var/line

			switch(H?.mind?.mental_state)
				if(MENTAL_STATE_DESENSITIZED)
					mood = 0
					line = pick(list("I just can't find a reason to care.","Okay.","Mhm. Do what you want.","Yeah..."))
				if(MENTAL_STATE_BASELINE)
					mood = rand(20,40)
					line = pick(brainlines)
				if(MENTAL_STATE_MILD)
					mood = rand(5,20)
					line = pick(brainlines_minor)
				if(MENTAL_STATE_PSYCHO)
					mood = rand(-20,-40)
					line = pick(brainlines_psycho)
					style = "good"

			H.chat_info(line, style)
			H.AdjustSorrow(mood)

		dmg += headshot_damage - pellet_damage

		var/sound = list('sound/effects/human/medical/headshot/headcrush (1).ogg', 'sound/effects/human/medical/headshot/headcrush (2).ogg', 'sound/effects/human/medical/headshot/headcrush (3).ogg', 'sound/effects/human/medical/headshot/headcrush (4).ogg','sound/effects/human/medical/headshot/headcrush (5).ogg','sound/effects/human/medical/headshot/headcrush (6).ogg','sound/effects/human/medical/headshot/headcrush (7).ogg')
		playsound(get_turf(victim), pick(sound), 65, TRUE)

		victim.AdjustBlood(-80) // Lots of blood in the head.
		victim.AdjustBleeding(rand(10,30))

		var/dire = get_dir(get_turf(victim),get_turf(shooter))
		dire = turn(dire, 180)

		headshot_splatter(get_turf(victim), dire)
		flick_overlay_view(image('icons/human/blood.dmi', victim, "bleed", MOB_LAYER + 0.1), victim, 6)
		for(var/i in 1 to 31)
			new /atom/movable/blood/splatter(get_turf(victim), victim)

		victim.go_blind(1,40)

		victim.filters = filter(type="displace", icon=icon('icons/human/blood.dmi',"headshot_displacement_map"), size=13)
		victim.brainsploded = TRUE // His brain 'sploded!
	var/amplitude = min(4, (dmg/100) + 1)
	var/pixel_x_diff = ceil(rand(-amplitude, amplitude))
	var/pixel_y_diff = ceil(rand(-amplitude/3, amplitude/2))
	animate(victim, pixel_x = pixel_x_diff, pixel_y = pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_x = -pixel_x_diff , pixel_y = -pixel_y_diff , time = amplitude / 3, flags = ANIMATION_RELATIVE)

	playsound(get_turf(victim), pick(list('sound/effects/human/medical/combat/pierce1.ogg', 'sound/effects/human/medical/combat/pierce2.ogg', 'sound/effects/human/medical/combat/pierce3.ogg', 'sound/effects/human/medical/combat/pierce4.ogg', 'sound/effects/human/medical/combat/pierce5.ogg')), 65, TRUE)
	victim.TakeDamage(dmg, "[shooter] - [hit_zone]", 6, 14)
	if(headshot_hits && !victim.dead)
		victim.AdjustBrainDamage(headshot_hits * 3)
	victim.bleed_effect()

	victim.AdjustBleeding(rand(1,10))

	if(prob(dmg))
		victim.SetRagdolled(TRUE)

	if(prob(40))
		if(victim.shrapnel < victim.max_shrapnel)
			victim.shrapnel++

	if(prob(rand(1,35)))
		if(victim.blood)
			new /atom/movable/blood/splatter(get_turf(victim), victim)

	if(prob(50))
		victim.BreakBones()

// Walks the pellet's path (muzzle -> impact) and returns the first living human standing in it.
// Returns list("mob", "x", "y", "zone") or null.
/obj/item/gun/proc/FindBlocker(mob/shooter, atom/movable/ignore, x1, y1, x2, y2)
	var/sx = x2 - x1
	var/sy = y2 - y1
	var/seg_len_sq = sx * sx + sy * sy
	if(seg_len_sq < 1)
		return null
	var/seg_len = sqrt(seg_len_sq)

	var/mob/human/best
	var/best_t = 2
	var/best_x
	var/best_y
	var/best_zone

	for(var/mob/human/M in range(ceil(seg_len / WORLD_ICON_SIZE) + 1, shooter))
		if(M == shooter || M == ignore || M.dead || !isturf(M.loc))
			continue
		var/mx = (M.x - 1) * WORLD_ICON_SIZE + M.step_x
		var/my = (M.y - 1) * WORLD_ICON_SIZE + M.step_y
		var/cx = mx + WORLD_ICON_SIZE / 2
		var/cy = my + WORLD_ICON_SIZE / 2

		// Part of the segment that passes near this mob.
		var/t_center = ((cx - x1) * sx + (cy - y1) * sy) / seg_len_sq
		var/half_t = (WORLD_ICON_SIZE * 0.75) / seg_len
		var/t_start = max(0, t_center - half_t)
		var/t_end = min(1, t_center + half_t)
		if(t_end <= t_start || t_start >= best_t)
			continue

		// Sample along the path and ask the mob's hitbox whether it was touched.
		var/step_t = 4 / seg_len
		for(var/st = t_start, st <= t_end, st += step_t)
			if(st >= best_t)
				break
			var/px = x1 + sx * st
			var/py = y1 + sy * st
			var/zone = M.GetHitZoneAt(px - mx, py - my)
			if(zone)
				best = M
				best_t = st
				best_x = px
				best_y = py
				best_zone = zone
				break

	if(!best)
		return null
	return list("mob" = best, "x" = best_x, "y" = best_y, "zone" = best_zone)

// A thin line from muzzle to impact that fades out almost instantly.
/obj/bullet_tracer
	mouse_opacity = 0
	layer = FLY_LAYER
	appearance_flags = PIXEL_SCALE
	var/global/icon/bullet_tracer_icon

/obj/bullet_tracer/New(newloc, x1, y1, x2, y2)
	..(newloc)
	if(!bullet_tracer_icon)
		// Blank the tile, then draw a 2px line across its full width.
		var/icon/I = icon('icons/obj/abstract/effects.dmi', "tracer", SOUTH, 1)
		I.DrawBox(null, 1, 1, WORLD_ICON_SIZE, WORLD_ICON_SIZE)
		I.DrawBox("#ffffff", 1, WORLD_ICON_SIZE / 2, WORLD_ICON_SIZE, WORLD_ICON_SIZE / 2 + 1)
		bullet_tracer_icon = I
	icon = bullet_tracer_icon

	var/dx = x2 - x1
	var/dy = y2 - y1
	var/len = max(1, sqrt(dx * dx + dy * dy))
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return

	// Centre the stretched icon on the midpoint of the shot.
	pixel_x = (x1 + x2) / 2 - ((T.x - 1) * WORLD_ICON_SIZE + WORLD_ICON_SIZE / 2)
	pixel_y = (y1 + y2) / 2 - ((T.y - 1) * WORLD_ICON_SIZE + WORLD_ICON_SIZE / 2)

	var/matrix/M = matrix()
	M.Scale(len / WORLD_ICON_SIZE, 1)
	M.Turn(-arctan(dx, dy))
	transform = M

	alpha = 230
	animate(src, alpha = 0, time = 2, easing = SINE_EASING)
	QDEL_IN(src, 2)

/client/Click(atom/object, location, control, params)
	var/mob/human/H = mob
	if(!istype(H) || !H.holding || !istype(H.holding, /obj/item/gun) || !H.cmode)
		return ..()

	var/obj/item/gun/G = H.holding
	var/turf/T = get_turf(object)
	if(!T)
		return ..()
	var/list/p = params2list(params)
	// icon-x / icon-y are 1-based pixels inside the clicked icon.
	var/click_x = text2num(p["icon-x"])
	var/click_y = text2num(p["icon-y"])
	if(!click_x)
		click_x = WORLD_ICON_SIZE / 2
	if(!click_y)
		click_y = WORLD_ICON_SIZE / 2
	click_x = max(1, min(WORLD_ICON_SIZE, click_x))
	click_y = max(1, min(WORLD_ICON_SIZE, click_y))

	var/target_offset_x = 0
	var/target_offset_y = 0
	if(istype(object, /atom/movable))
		var/atom/movable/target_movable = object
		target_offset_x = target_movable.step_x
		target_offset_y = target_movable.step_y
	var/aim_x = (T.x - 1) * WORLD_ICON_SIZE + target_offset_x + click_x - 1
	var/aim_y = (T.y - 1) * WORLD_ICON_SIZE + target_offset_y + click_y - 1
	G.Fire(H, object, aim_x, aim_y)

/atom/movable/casing
	icon = 'icons/obj/abstract/effects.dmi'
	mouse_opacity = 0
	layer = TURF_LAYER

/atom/movable/casing/Initialize()
	. = ..()
	pixel_x = rand(-10,10)
	pixel_y = rand(-10,10)

	filters += filter(type="outline", size = 1, color = "#FFFF00", flags = OUTLINE_SQUARE)

	var/yeah = "shell[rand(1,3)]"
	flick(yeah,src)
	spawn(4) icon_state = yeah

	QDEL_IN(src, 5000)

/obj/item/ammo_box
	name = "ammo box"
	desc = "It's a box of ammunition. Maybe if you knew something about firearms you'd know what's inside."
	desc_expansive_extra_skill = GUNS

	vendor_name = "S.AM"
	vendor_price = 40

	var/ammo_type = AMMO_SMALL
	var/ammo_amt = 16

/obj/item/ammo_box/Initialize()
	. = ..()
	var/falvor = "...something?"
	switch(ammo_type)
		if(AMMO_SMALL)
			falvor = "small ammo, these are handy for pistols and other small arms."
		if(AMMO_MEDIU)
			falvor = "medium ammunition. These were largely phased out of production due to standardization efforts. These are still handy for antiques."
		if(AMMO_BIG)
			falvor = "big ammunition. Used for high-calibre rifles, such as assault rifles."
		if(AMMO_SHELLS)
			falvor = "shotgun shells. Self-explanatory. Used in shotguns."
	desc_expansive = "I know! It's a box of [falvor]"

/obj/item/ammo_box/use(mob/human/H)
	. = ..()
	if(!H.ammo)
		H.ammo = list()
	if(ammo_type && ammo_amt)
		H.ammo[ammo_type] += ammo_amt
		H.chat_info("Sweet, sweet ammo.")
	else
		H.ammo[AMMO_SMALL] += rand(8,32)
		H.ammo[AMMO_BIG] += rand(15,60)
		H.ammo[AMMO_SHELLS] += rand(8,32)
		if(prob(20))
			H.ammo[AMMO_MEDIU] += rand(1,40)
		H.chat_info("Good, that's all they left.")
	junkize(H)

/obj/item/ammo_box/big
	ammo_type = AMMO_BIG
	ammo_amt = 30

	vendor_name = "B.AM"
	vendor_price = 60

/obj/item/ammo_box/med
	ammo_type = AMMO_MEDIU

	vendor_name = "M.AM"
	vendor_price = 90

	ammo_amt = 24 // NON-STANDARD! Intended. :)

/obj/item/ammo_box/shells
	ammo_type = AMMO_SHELLS
	ammo_amt = 16

	vendor_name = "SH.AM"
	vendor_price = 65

/obj/item/ammo_box/random
	ammo_type = null
	ammo_amt = null
	buy_rollable = FALSE

	vendor_name = "ASS."
	vendor_price = 75 // Dissident only, lets keep it cheap-ish.