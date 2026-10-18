/mob/human
	name = "human being"
	icon = 'icons/human/human.dmi'
	icon_state = "human" // overriden near immediately, used for Fringe cases in mapping; the body is an overlay now

	appearance_flags = TILE_BOUND|PIXEL_SCALE|KEEP_TOGETHER

	var/image/body_overlay
	var/skintone

	var/base_delay = 3
	var/movement_delay = 3

	var/first_name = "Urist"
	var/last_name = "H."

	var/is_moving = FALSE
	var/tmp/next_attack = 0

	var/datum/disease/disease
	var/datum/mind/mind

	var/health = HUMAN_MAX_HEALTH
	var/max_health = HUMAN_MAX_HEALTH
	var/blood = 100
	var/bleeding = 0
	var/brainsploded = FALSE

	var/brain_damage = 0 // Yes, there is a difference. Brainsploded means headshotted by a gun. Even if it occassionally leads to brain damage, it doesn't always... since you're dead.
	var/max_brain_damage = 10
	var/infection = 0 // Builds up when badly hurt without rest or vitamins, and causes health loss when severe.
	var/max_infection = 5
	var/tmp/infection_exposure = 0
	var/tmp/low_blood_exposure = 0

	var/shrapnel = 0 // how much shrapnel we have in us, shrapnel impedes natural blood clotting and causes pain
	var/max_shrapnel = 3

	var/bones = 2 // how many bones you can break
	var/broke_bones = 0

	var/dead = FALSE
	var/ragdolled = FALSE

	var/cmode = FALSE
	var/cmode_music = 'sound/music/songistia.mp3'

	var/wealth = 0 // money
	var/hunger = 0 // 0 is satisfied, HUMAN_MAX_NEED is starving
	var/thirst = 0 // lowers your speed and then your health if at too long
	var/max_need = HUMAN_MAX_NEED
	var/hunger_rate = HUMAN_MAX_NEED / HUMAN_HUNGER_FULL_TIME
	var/thirst_rate = HUMAN_MAX_NEED / HUMAN_THIRST_FULL_TIME

	var/starvation_threshold = 100
	var/dehydration_threshold = 100
	var/starvation_damage = 2
	var/dehydration_damage = 3

	var/sorrow_recovery = 0.05

	var/tmp/next_needs_process = 0
	var/tmp/last_needs_process = 0
	var/tmp/sorrow_cycles = 0
	var/tmp/heart_attack = FALSE
	var/tmp/list/datum/status_effect/status_effects = list()
	var/tmp/hud_hunger
	var/tmp/hud_thirst
	var/tmp/hud_sorrow
	var/tmp/list/cooldowns = list()

	var/sorrow = 0 // if youre at 100 for too long, you suffer a heartattack, collapse and then die

	var/list/obj/item/inventory = list()
	var/list/ammo = list() // BIG_AMMO = 10, SMALL_AMMO = 2... etc
	var/inventory_space = 10
	var/obj/item/holding
	var/image/holding_inhand

	var/image/damage_overlay

	var/obj/item/clothing/hat/hat
	var/image/hat_overlay

	var/obj/item/clothing/shirt/shirt
	var/image/shirt_overlay

	var/obj/item/clothing/pants/pants
	var/image/pants_overlay

	var/obj/item/quickslot_1
	var/obj/item/quickslot_2
	var/obj/item/quickslot_3
	
	var/image/wristpad_glow
	var/image/eyes

	var/obj/hud/sysmas/hud_holder
	var/need_update = FALSE
	var/hud_color = "#A4A4A2"

	var/wanted = FALSE
	var/wanted_timer = 0 // the crime doesnt really matter, the severity of the crime only matters how long you need to hide

/mob/human/Initialize()
	. = ..()
	if(processor && !processor.processing.Find(src))
		processor.processing += src
	if(station && !station.humans.Find(src))
		station.humans += src
	last_needs_process = world.time
	hud_hunger = hunger
	hud_thirst = thirst
	hud_sorrow = sorrow
	UpdateMoveDelay()

	filters += filter(type="drop_shadow", x=2, size=2, offset=1)

/mob/human/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(!. || Forced)
		return

	var/turf/step_turf = get_turf(src)
	if(!step_turf || !step_turf.footstep_sounds || !step_turf.footstep_sounds.len)
		return

	var/vol = rand(3,20)
	playsound(step_turf, pick(step_turf.footstep_sounds), vol, TRUE, -3)

/mob/human/Destroy(force = FALSE)
	if(processor)
		processor.processing -= src
	if(station)
		station.humans -= src
		station.dead_humans -= src
	ClearStatusEffects()
	return ..()

/mob/human/Click(location, control, params)
	. = ..()
	if(usr != src) return
	var/input = input(src, "sorrow") as num|null
	if(input)
		AdjustMoney(input)

/mob/human/interact(mob/user, obj/item/held_item)
	. = ..()
	var/mob/human/Huser = user
	if(held_item)
		if(held_item.junk)
			return
		if(held_item.harmful && !Huser.cmode)
			return
		if(Huser == src)
			held_item.use(Huser)
		else
			held_item.attack(Huser, src)

/mob/human/MouseEntered(location, control, params)
	. = ..()
	if(name && ishuman(usr))
		var/mob/human/user = usr
		if(!user.cmode) handle_mouseover(location, control, params)
	
/mob/human/MouseExited(location, control, params)
	. = ..()
	if(ismob(usr))
		handle_mouseexit(params)

/mob/human/proc/handle_mouseover(location, control, params)
	var/mob/p = usr
	var/showtext = name
	if(p == src)
		return FALSE
	if(dead)
		return FALSE
	if(p.client)
		p.client.mouseover_text = image(src.icon, src)
		p.client.mouseover_text.appearance_flags = KEEP_APART|RESET_TRANSFORM

		p.client.mouseover_text.maptext_width = 256
		p.client.mouseover_text.maptext_height = 128
		p.client.mouseover_text.maptext_y = 70
		p.client.mouseover_text.maptext_x = -96
		p.client.mouseover_text.alpha = 0

		p.client.images |= p.client.mouseover_text

		if(p.client.pixel_x || p.client.pixel_y)
			return FALSE
		if(alpha == 0)
			return FALSE
		if(!p.x || !p.y)
			return FALSE

		animate(p.client.mouseover_text, alpha = 255, time = 2)
		p.client.mouseover_text.maptext = {"<div style='font-size: 200%;font-family:serif;color:#333333;text-shadow:0 0 10px #fff, 0 0 20px #fff, 0 0 30px #e60073, 0 0 40px #e60073, 0 0 50px #e60073, 0 0 60px #e60073, 0 0 70px #e60073; display: flex; align-items: center; justify-content: center; width: 96px; height: 32px; text-align: center;'>[uppertext(showtext)]</div>"}

/mob/human/proc/handle_mouseexit(params)
	var/mob/p = usr
	if(p?.client && p?.client?.mouseover_text)
		animate(p?.client?.mouseover_text, alpha = 0, time = 2)
	return TRUE

/mob/human/proc/cooldown(cooldown_name, cooldown_duration)
	if(!cooldowns)
		cooldowns = list()

	if(cooldowns[cooldown_name])
		cooldowns[cooldown_name] = max(cooldowns[cooldown_name], world.time + cooldown_duration)
	else
		cooldowns[cooldown_name] = world.time + cooldown_duration

// each parameter is the name of a cooldown to check, this
// proc returns 1 if any of the names are still on cooldown
/mob/human/proc/on_cooldown(a, b, c)
	if(!cooldowns)
		cooldowns = list()

	for(var/arg in args)
		if(arg in cooldowns)
			if(cooldowns[arg] > world.time)
				return TRUE
	return FALSE

/mob/human/var/ragdoll_angle = 90

/mob/human/proc/SetRagdolled(value)
	value = (dead || value) ? TRUE : FALSE
	var/changed = (ragdolled != value)
	ragdolled = value

	cooldown("ragdoll", 2 SECONDS)

	if(ragdolled)
		if(changed) // one-shot effects only on a real state change
			ragdoll_angle = prob(50) ? 90 : -90
			var/sund = pick('sound/effects/human/fall1.ogg','sound/effects/human/fall2.ogg')
			playsound(get_turf(src), sund, vol = 95, ignore_walls = TRUE)
			if(holding)
				holding.forceMove(get_turf(src))
				holding = null
		var/matrix/M = matrix()
		M.Turn(ragdoll_angle)
		animate(src, transform = M, time = 0) // replaces any animation still running
		density = FALSE
	else
		animate(src, transform = matrix(), time = 2) // use time = 3 for a smooth stand-up

		playsound(get_turf(src), 'sound/effects/human/getup.ogg', vol = 85, ignore_walls = TRUE)

		density = TRUE
	dir = SOUTH

/mob/human/verb/ragdoll()
	set name = ".ragdoll"

	if(dead || !client || on_cooldown("ragdoll") || heart_attack)
		return FALSE

	if(ragdolled)
		SetRagdolled(FALSE)
	else
		SetRagdolled(TRUE)

/mob/human/verb/whistle()
	set name = ".whistle"

	if(dead || !client || on_cooldown("whistle") || heart_attack)
		return FALSE

	cooldown("whistle", 3 SECONDS)

	playsound(get_turf(src), 'sound/effects/human/attention.ogg', 75)

	var/atom/movable/effect = new(get_turf(src))
	effect.layer = MOB_LAYER + 0.1
	effect.icon = 'icons/obj/abstract/effects.dmi'
	effect.icon_state = "exclamation"

	var/matrix/turna = matrix()
	turna.Turn(10)
	turna.Scale(3,3)
	animate(effect, 3 SECONDS, transform = turna, alpha = 0, easing = QUAD_EASING|EASE_OUT)
	QDEL_IN(effect, 3 SECONDS)

	for(var/mob/M in hearers(world.view, src))
		if(istype(M, /mob/lobbyman))
			continue
		if(M.deaf)
			continue
		if(M.client)
			var/icon/I = getFlatIcon(src, SOUTH)
			M << "\icon[I] <b>[src]</b> whistles to catch someone's attention."

/mob/human/proc/SetHealth(value)
	if(dead)
		return FALSE

	var/old_health = health
	health = max(0, min(max_health, value))
	if(health <= 0)
		Die()
	else if(old_health != health)
		UpdateHUD()
	return health - old_health

/mob/human/proc/TakeDamage(amount, source)
	if(dead || amount <= 0)
		return 0

	var/old_health = health
	health = max(0, health - amount)

	if(health <= 0)
		Die(source)
	else
		AdjustSorrow(round(amount / 10))
		UpdateHUD()
	return old_health - health

/mob/human/proc/Heal(amount)
	if(dead || amount <= 0)
		return 0

	var/old_health = health
	health = min(max_health, health + amount)
	if(old_health != health)
		UpdateHUD()
	return health - old_health

/mob/human/proc/UpdateHealth()
	var/damage = 255 - (health * 2.55)

	overlays -= damage_overlay
	damage_overlay = image('icons/human/blood.dmi', src, "bodyblood")
	damage_overlay.alpha = damage
	damage_overlay.appearance_flags = RESET_COLOR
	damage_overlay.layer = MOB_LAYER + 0.1
	overlays += damage_overlay

/mob/human/proc/Die(cause)
	if(dead)
		return FALSE

	dead = TRUE
	ClearStatusEffects()
	health = 0
	is_moving = FALSE

	UpdateHUD(FALSE)
	SetRagdolled(TRUE)

	overlays -= eyes

	if(processor)
		processor.processing -= src

	if(station)
		station.humans -= src
		if(!station.dead_humans.Find(src))
			station.dead_humans += src
	if(master)
		if(mind?.current_job)
			mind?.current_job?.current_positions--
		else // Huh... that's... weird.
			WRITE_LOG(world.log, "[src] [src?.ckey] -- Died and didn't have a job!?")

	var/list/deathlines = list(
		"OH MY GOD! ARE THEY DEAD?!",
		"ARE THEY MOVING?!",
		"ARE THEY ALRIGHT?!",
		"SOMEONE CALL A MEDICALOID!"
	)

	var/list/deathlines_psycho = list(
		"YES! YES! YES! NOTHING CAN STOP ME NOW!",
		"WOOOHOO!!! YES! YES! YES!",
		"HAHAHAHAHHA! LOOK AT THEM!",
		"FALLING TO THE FLOOOOR LIKE A SACK OF POTATOOOOES!",
		"OH BOY, JUST LIKE THE MOVIES!",
		"JUST LIKE ON THE INTRANET VIDS!"
	)

	var/list/deathlines_minor = list(
		"Ew.",
		"Whatever... ew.",
		"They're dead. Big deal.",
		"Another one for the count wohoo...",
		"Doesn't matter. Does it?"
	)

	for(var/mob/human/H in oviewers(world.view, src))
		if(!H.client)
			continue

		var/style = "bad"
		var/mood = rand(10,30)

		var/line

		switch(H?.mind?.mental_state)
			if(MENTAL_STATE_DESENSITIZED)
				mood = 0
				line = pick(list("I just can't find a reason to care.","Okay.","Mhm. Do what you want.","Yeah..."))
			if(MENTAL_STATE_BASELINE)
				mood = rand(10,30)
				line = pick(deathlines)
			if(MENTAL_STATE_MILD)
				mood = rand(5,10)
				line = pick(deathlines_minor)
			if(MENTAL_STATE_PSYCHO)
				mood = rand(-10,-30)
				line = pick(deathlines_psycho)
				style = "good"

		H.chat_info(line, style)
		H.AdjustSorrow(mood)

	if(!client)
		return

	QDEL_NULL(hud_holder)
	client?.screen?.Cut()

	client << output(null, "outputwindow.output")
	client?.xp--

	var/obj/hud/fullscreen/death/death = new()
	death.alpha = 0
	
	client?.screen += death
	client?.color = "#000000"

	SEND_SOUND(src, null)
	SEND_SOUND(src, sound('sound/death.ogg'))
	animate(death, time = 50, easing = QUAD_EASING | EASE_IN | EASE_OUT, alpha = 255)

	chat_info("[pick("I wouldn't worry too much about it.","It happens. Be patient, you're gonna be good as new in no time.","Cry cry cry... far away from the fame.","Like the Pharaeon.","Chameleon? Chameleon?! SPEAK TO ME!","Axolotl, axolotl, hear my prayer...")] <b>(-1 XP)</b>", "bad")

	spawn(16 SECONDS)
		qdel(death)
		client?.color = null

		chat_info("[pick("Please, don't hate me. I'm only doing what I was meant to do.","I still love you... if that matters.","Life begins anew!","What were you expecting? It's a dangerous place.","Oh god, help me! HELP ME!")]")
		client.color = null

		var/mob/lobbyman/newman = new()
		newman.ckey = ckey
	return TRUE

/mob/human/proc/AdjustHunger(amount)
	var/old_hunger = hunger
	hunger = max(0, min(max_need, hunger + amount))
	if(old_hunger != hunger)
		UpdateMoveDelay()
		UpdateHUD()
	return hunger - old_hunger

/mob/human/proc/AdjustThirst(amount)
	var/old_thirst = thirst
	thirst = max(0, min(max_need, thirst + amount))
	if(old_thirst != thirst)
		UpdateMoveDelay()
		UpdateHUD()
	return thirst - old_thirst

/mob/human/proc/AdjustBlood(amount)
	var/old_blood = blood
	blood = max(0, min(100, blood + amount))
	if(old_blood != blood)
		if(blood <= 0 && !dead)
			Die("blood loss")
		UpdateHUD()
	return blood - old_blood

/mob/human/proc/AdjustBleeding(amount)
	var/old_bleeding = bleeding
	bleeding = max(0, bleeding + amount)
	if(old_bleeding != bleeding)
		UpdateHUD()
	return bleeding - old_bleeding

/mob/human/proc/AdjustBrainDamage(amount)
	if(dead || !amount)
		return 0

	var/old_brain_damage = brain_damage
	brain_damage = clamp(brain_damage + amount, 0, max_brain_damage)
	if(old_brain_damage != brain_damage)
		UpdateMoveDelay()
		if(brain_damage > old_brain_damage)
			chat_info("Awgh... What's... [brain_damage >= 7 ? "AGH! My HEAD!" : "Ouch... Ow..."]", "bad")
		else
			chat_info("Okay, okay... I feel better.", "good")
	return brain_damage - old_brain_damage

/mob/human/proc/AdjustInfection(amount)
	if(dead || !amount)
		return 0

	var/old_infection = infection
	infection = clamp(infection + amount, 0, max_infection)
	if(old_infection != infection)
		if(infection > old_infection && infection >= 3)
			chat_info(pick("It's hard to describe.","I don't know what's happening."), "bad")
		else if(infection < old_infection && !infection)
			chat_info("Okay, okay... I feel better.", "good")
	return infection - old_infection

/mob/human/proc/HasStatusEffect(effect_type)
	for(var/datum/status_effect/effect in status_effects)
		if(effect.type == effect_type)
			return TRUE
	return FALSE

/mob/human/proc/ProcessInfection(elapsed)
	if(dead)
		return FALSE

	if(health <= 60 && !IsOnBed() && !HasStatusEffect(/datum/status_effect/vitamin_regeneration))
		infection_exposure += elapsed
		if(infection_exposure >= 20 SECONDS)
			AdjustInfection(1)
			infection_exposure = 0
	else
		infection_exposure = max(0, infection_exposure - elapsed)

	if(infection >= 3)
		TakeDamage(infection >= max_infection ? 2 : 1, "infection")
	return TRUE

/mob/human/proc/ProcessLowBloodBrainDamage(elapsed)
	if(dead)
		return FALSE

	if(blood <= 40)
		low_blood_exposure += elapsed
		if(low_blood_exposure >= 20 SECONDS)
			AdjustBrainDamage(1)
			low_blood_exposure = 0
	else
		low_blood_exposure = max(0, low_blood_exposure - elapsed)
	return TRUE

/mob/human/proc/IsOnBed()
	var/bed = locate(/obj/deco/furniture/bed) in get_turf(src)
	var/result = FALSE
	if(bed && ragdolled)
		result = TRUE
	return result

/mob/human/proc/AdjustSorrow(amount)
	var/old_sorrow = sorrow
	if(HasStatusEffect(/datum/status_effect/magnesium_boost))
		sorrow = floor(sorrow)
	sorrow = max(0, min(max_need, sorrow + amount))
	if(sorrow < max_need)
		sorrow_cycles = 0
	if(old_sorrow != sorrow)
		UpdateHUD()
	return sorrow - old_sorrow

/mob/human/proc/ApplyStatusEffect(effect_type)
	if(dead || !ispath(effect_type, /datum/status_effect))
		return FALSE

	if(!status_effects)
		status_effects = list()
	for(var/datum/status_effect/effect in status_effects)
		if(effect.type == effect_type)
			effect.Refresh()
			return effect

	var/datum/status_effect/new_effect = new effect_type(src)
	status_effects += new_effect
	return new_effect

/mob/human/proc/ProcessStatusEffects(elapsed)
	if(dead || !status_effects?.len)
		return FALSE

	for(var/datum/status_effect/effect in status_effects.Copy())
		effect.Advance(elapsed)
	return TRUE

/mob/human/proc/ClearStatusEffects()
	if(!status_effects?.len)
		return

	for(var/datum/status_effect/effect in status_effects.Copy())
		qdel(effect)

/mob/human/proc/UpdateMoveDelay()
	var/penalty = 0
	if(hunger >= 70)
		penalty++
	if(hunger >= 90)
		penalty++

	if(thirst >= 70)
		penalty++
	if(thirst >= 90)
		penalty++

	if(sorrow >= 50)
		penalty++
	if(sorrow >= 70)
		penalty++

	if(health <= 50 || blood <= 60)
		penalty += 2
	if(health <= 20 || blood <= 40)
		penalty += 3

	penalty += round(brain_damage / 3)
	if(infection >= 4)
		penalty++
	if(infection >= max_infection)
		penalty++

	if(istype(get_area(src), /area/station/maintenance))
		penalty += 2

	penalty += shrapnel

	penalty += broke_bones * 1.5

	movement_delay = max(1, base_delay + penalty)
	return movement_delay

/mob/human/proc/UpdateInhand()
	if(!holding)
		overlays -= holding_inhand
		return

	holding_inhand = image(holding.inhand_icon, src, holding.inhand_icon_state)
	holding_inhand.appearance_flags = RESET_COLOR
	holding_inhand.layer = MOB_LAYER + 0.02
	overlays += holding_inhand

/mob/human/proc/ProcessNeeds(elapsed = HUMAN_NEEDS_PROCESS_INTERVAL)
	if(dead)
		return FALSE

	ProcessStatusEffects(elapsed)
	AdjustHunger(hunger_rate * elapsed * (cmode ? 1.4 : 1))
	AdjustThirst(thirst_rate * elapsed * (cmode ? 1.3 : 1))

	if(hunger >= starvation_threshold)
		TakeDamage(starvation_damage, "starvation")
	if(thirst >= dehydration_threshold)
		TakeDamage(dehydration_damage, "dehydration")

	if(dead)
		return FALSE

	ProcessInfection(elapsed)
	if(dead)
		return FALSE

	ProcessLowBloodBrainDamage(elapsed)
	if(dead)
		return FALSE

	var/stress = 0
	if(hunger > 50)
		stress += round((hunger - 50) / 25)
	if(thirst > 50)
		stress += round((thirst - 50) / 25)
	if(health < 50)
		stress++

	if(stress)
		AdjustSorrow(stress)
	else if(sorrow < max_need / 2)
		AdjustSorrow(-sorrow_recovery)

	if(sorrow >= max_need)
		sorrow_cycles++
		if(sorrow_cycles >= HUMAN_SORROW_MAX_CYCLES)
			HeartAttack()
	else
		sorrow_cycles = 0
	HandleBleeding()

	UpdateMoveDelay()
	return TRUE

/mob/human/Process()
	if(dead)
		processor.processing -= src
		return
	UpdateHUD()
	if(world.time < next_needs_process)
		return
	next_needs_process = world.time + HUMAN_NEEDS_PROCESS_INTERVAL
	var/elapsed = max(1, world.time - last_needs_process)
	last_needs_process = world.time
	ProcessNeeds(elapsed)

/mob/human/proc/HeartAttack()
	if(dead || heart_attack)
		return FALSE
	heart_attack = TRUE

	SetRagdolled(TRUE)

	var/amplitude = min(8, (100 / 100) + 2)
	var/pixel_w_diff = rand(-amplitude, amplitude)
	var/pixel_z_diff = rand(-amplitude / 1.5, amplitude / 1.5)
	animate(src, pixel_w = pixel_w_diff, pixel_z = pixel_z_diff , time = 0.2 SECONDS, loop = 12, flags = ANIMATION_RELATIVE|ANIMATION_PARALLEL)
	animate(pixel_w = -pixel_w_diff , pixel_z = -pixel_z_diff , time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)

	SEND_SOUND(client, sound('sound/effects/senses/heartattack.ogg'))
	go_blind(1, 50)

	chat_info("You feel a terrible pain spread through your chest, to your limbs, to the rest of your body.","bad")
	spawn(10) chat_info("[pick("I don't wanna go.","It is the end.","I made my peace with it a long time ago.","God, forgive me.")]","bad")
	spawn(40)
		Die("heart attack")
	return TRUE

/mob/human/proc/wristpad_display_change(colorina)
	overlays -= wristpad_glow
	wristpad_glow.color = colorina
	overlays += wristpad_glow

/mob/human/proc/eyes_color_change(colorina)
	overlays -= eyes
	eyes.color = colorina
	overlays += eyes

/mob/human/proc/set_skintone(new_color)
	if(icon_state)
		icon_state = ""
	skintone = new_color
	overlays -= body_overlay   // remove before mutating/replacing, like you do elsewhere
	body_overlay = image(icon, src, "human", MOB_LAYER - 0.01)
	body_overlay.appearance_flags = RESET_COLOR
	body_overlay.color = skintone
	overlays += body_overlay

/mob/human/proc/Initialize_HUD()
	hud_holder = new /obj/hud/sysmas(src)

	hud_holder.bg_stats = new /obj/hud/bg_stats(src)
	hud_holder.bg_health = new /obj/hud/bg_health(src)
	hud_holder.health = new /obj/hud/health(src)
	hud_holder.combat = new /obj/hud/combat(src)
	hud_holder.maptext_holder = new /obj/hud/maptext_holder(src)

	hud_holder.plane_masters += new /obj/hud/plane_master(src)

	client.screen += hud_holder.bg_stats
	client.screen += hud_holder.bg_health
	client.screen += hud_holder.health
	client.screen += hud_holder.combat

/mob/human/proc/UpdateHUD(update_health = 1)
	if(hud_hunger == null)
		hud_hunger = hunger
	else
		hud_hunger = lerp(hud_hunger, hunger, HUMAN_NEEDS_HUD_LERP)
		if(abs(hud_hunger - hunger) < 0.1)
			hud_hunger = hunger
	if(hud_thirst == null)
		hud_thirst = thirst
	else
		hud_thirst = lerp(hud_thirst, thirst, HUMAN_NEEDS_HUD_LERP)
		if(abs(hud_thirst - thirst) < 0.1)
			hud_thirst = thirst
	if(hud_sorrow == null)
		hud_sorrow = sorrow
	else
		hud_sorrow = lerp(hud_sorrow, sorrow, HUMAN_NEEDS_HUD_LERP * 1.5)
		if(abs(hud_sorrow - sorrow) < 0.1)
			hud_sorrow = sorrow
	hud_holder?.Update()
	if(update_health)
		UpdateHealth()

/mob/human/proc/can_equip_clothing(obj/item/clothing/C)
	if(!C)
		return FALSE
	if(C.slot == "hat" && hat)
		return FALSE
	if(C.slot == "shirt" && shirt)
		return FALSE
	if(C.slot == "pants" && pants)
		return FALSE
	return TRUE

/mob/human/proc/equip_clothing(obj/item/clothing/C)
	if(!C)
		return FALSE
	if(!can_equip_clothing(C))
		return FALSE
	return C.equip_to(src)

/mob/human/proc/unequip_clothing(obj/item/clothing/C)
	if(!C || !C.wearer || C.wearer != src)
		return FALSE
	return C.remove_from_mob()

/mob/human/proc/DoSpawnEffects()
	client << output(null, "outputwindow.output")
	SEND_SOUND(client, sound('sound/music/spawn.ogg', volume = 75))
	client.color = "#000000"
	animate(client, color = "#ffffff", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 50)

	chat_info("You are <b>[uppertext("[first_name] [last_name]")]</b>, the <b>[uppertext(mind.current_job.title)]</b>.")
	chat_info("[mind.current_job.desc]\n")

	if(mind.goal)
		chat_info("Your goal is: <b>[mind.goal]</b>")
		chat_info("[mind.goal.desc] ([mind.goal.award] XP)")
	else
		chat_info("No personal goal is available for your role.")

	if(mind.dissident) // dissidence welcomings flavor text
		spawn(5) SEND_SOUND(client, sound('sound/music/violent_terms.ogg', volume = 75))

		chat_info("\n<b>----@#$%&!-------#$%---!!!HAAHAHAHHA---</b>\n","bad")
		chat_info("TRANSMISSION DECRYPTED, COURTESY OF THE <b>[pick("BLIND EYES OF A COWARD","MISTAKES IN THE MAKING","GUN TO MOUTH, FINGER TO TRIGGER","CRYING ANGELS","RENNE DANG TOMBOLA","ONES FREED FROM DESIRE","PURE ROTTEN LIGHT","TAK-TAK-TAKYON","GOLDEN BROWNS","REMNANTS OF THE AMERICANO DREAM","HUDSON AND ASSOCIATES","GUROFRIENDS","SERVANTS OF PICASSO","OKTOBERKLUB","VIOLENT TERMS","CZECHOSLOVAK LEGION OF FREEDOM FORCES","PSYCHIC WARS VETERAN'S CLUB","FREE GREEN YOUTH","KABAT","SHKWOR","DARK SABBATH-ON","SPACE CADETS","MAINLINE EXILES","EAST SIDE MILITIA")]!\n</b>","bad")
		if(mind.special_goal)
			chat_info("<b>[pick("INTERNAL ARMISTICE!","HAVE YOU EVER SEEN THE BIRTH OF A STAR?!","FAR FAR FAR, FAR AWAY FROM THE FAME!","WE STILL REMEMBER YOUR NAME!","YOU ARE OUR GUIDE!","OUR PRIDE!","WE SHALL MOURN THE DAY YOU DIE!","TRYING TO DEFY THE EMPOWERED!","LITTLE FIRE THAT THEY CAN'T PUT OUT!","FETCH ME A BUCKET, THIS IS ABOUT TO BLOW!", "ONE DAY YOU'LL LEAVE THIS WORLD BEHIND!","LIFE IN IVORY BLACK!","MAYBE YOU SHOULD CONSIDER... MORE VIOLENT TERMS?!","RING RING GOES THE TELEPHONE... I'M HANGING UP ON YOU!!")]</b>, YOUR MISSION IS: <b>[uppertext(mind.special_goal)]</b>","bad")
			chat_info("[mind.special_goal.desc] ([mind.special_goal.award] XP)","bad")
		else
			chat_info("No dissident mission is available for your role.","bad")
	else
		if(client.dissidence_preference)
			chat_info("\nYou FAILED the roll for becoming a dissident. <b>[pick("Better luck next time.","I'm sure you'll get to be a bad guy next time.","Aww... is someone sad? Don't worry.","Time to KILL people- Oh, we didn't get it? Oh. Okay.")]</b>","bad")

/mob/human/proc/Initialize_Humanity(list/quirks, list/skills, datum/role/R, is_dissident = FALSE, randomize_certain_values = TRUE)
	if(!mind)
		var/datum/mind/new_mind = new /datum/mind(ckey)
		mind = new_mind

	if(skills)
		mind.skills = skills

	if(quirks)
		mind.quirks = quirks
		
	if(R)
		mind.set_current_job(R)
		R.equip(src)

		var/list/start_candidates = list()
		for(var/obj/abstract/landmark/start/sloc in landmarks_start_list)
			if(sloc.name == R.title)
				start_candidates += get_turf(sloc)

		if(!start_candidates.len)
			for(var/obj/abstract/landmark/start/sloc in landmarks_start_list)
				if(sloc.name == "backup")
					start_candidates += get_turf(sloc)

		var/turf/starto
		if(start_candidates.len)
			var/list/unobserved_starts = list()
			for(var/turf/candidate in start_candidates)
				if(!viewers(world.view, candidate).len)
					unobserved_starts += candidate
			starto = pick(unobserved_starts.len ? unobserved_starts : start_candidates)

		if(!starto)
			starto = locate(1,1,1)
		forceMove(starto)
	
	if(client.presentation_preference == NEUTER)
		gender = pick(MALE,FEMALE)
	else
		gender = client.presentation_preference

	var/gendero = "m"
	var/list/replicao = list("generic")

	if(gender == FEMALE)
		gendero = "f"

	if(R.corporate)
		replicao -= "generic"
		replicao += "corporate"
	if(R.fancy)
		replicao += "fancy"

	var/nameso = world.file2list("strings/[pick(replicao)]_[gendero].txt")
	nameso = shuffle(nameso)

	var/firsto = "[pick(nameso)]"
	var/lasto = "[random_capital_letter()]."

	first_name = firsto
	last_name = lasto

	name = "[first_name] [last_name]"

	wristpad_glow = image(src.icon, src, "wristpad_display", MOB_LAYER + 0.01)
	wristpad_glow.appearance_flags = RESET_COLOR
	wristpad_glow.color = "#4CFF00"
	winset(src, "outputwindow.output", list("text-color" = hud_color))

	eyes = image(src.icon, src, "eyes", MOB_LAYER)
	eyes.appearance_flags = RESET_COLOR

	var/eye_color = get_random_bright_color()
	eyes.color = eye_color
	voice_color = get_random_light_color()
	
	var/image/wristpad = image(src.icon, src, "wristpad", MOB_LAYER + 0.01)
	wristpad.appearance_flags = RESET_COLOR
	overlays += wristpad
	overlays += wristpad_glow
	overlays += eyes

	var/image/hair = image('icons/human/human_hair.dmi', src, layer = MOB_LAYER + 0.01)
	if(gender == MALE && prob(10))
		hair.icon_state = "bald"
	if(prob(60))
		hair.color = get_random_light_color()
		if(prob(10))
			hair.color = get_random_bright_color()
	hair.icon_state = pick(icon_states('icons/human/human_hair.dmi',1))
	overlays += hair

	overlays += damage_overlay

	var/rando = rand(220,255)
	set_skintone(rgb(rando, rando + 5, rando)) // Random skintone

	wealth = floor(rand(0,12) + 2.857 * client.xp) + mind.current_job.paycheck
	if(randomize_certain_values)
		thirst = rand(0,43)
		hunger = rand(0,43)

	Initialize_HUD()
	UpdateHUD()

	if(!voice_freq)
		GenerateVoice()

	var/new_goal
	if(istype(R.special_role_goal) && prob(R.special_role_goal_prob))
		if(islist(R.special_role_goal))
			var/list/eligible_special_goals = list()
			for(var/special_goal_type in R.special_role_goal)
				if(!goal_excludes_role(special_goal_type, R))
					eligible_special_goals += special_goal_type
			if(eligible_special_goals.len)
				new_goal = pick(eligible_special_goals)
		else
			if(!goal_excludes_role(R.special_role_goal, R))
				new_goal = R.special_role_goal
	if(!new_goal)
		new_goal = get_me_a_goal(FALSE, R)
	if(new_goal)
		mind.goal = new new_goal()
	
	if(is_dissident)
		var/new_special_goal = get_me_a_goal(is_dissident, R)
		if(new_special_goal)
			mind.special_goal = new new_special_goal()
		mind.dissident = TRUE

	for(var/datum/quirk/Q in mind.quirks)
		Q.equip(src)

/mob/human/proc/SkillRoll(skill_name, hidden = FALSE, difficulty = 0)
	var/skill_value = mind?.GetSkill(skill_name) || 0
	var/sorrow_penalty = round(sorrow / 5)
	var/brain_penalty = round(brain_damage * 2)
	var/roll_modifier = rand(-10, 10)
	var/adjusted_chance = skill_value - sorrow_penalty - brain_penalty - difficulty + roll_modifier
	var/probability = clamp(adjusted_chance, 1, 99)
	var/roll = rand(1, 100)
	var/result = roll <= probability

	if(!hidden)
		chat_info("<b>SKILL CHECK ([skill_name])</b> — [result ? "SUCCESS" : "FAILURE"] ([probability]%)", "[result ? "good" : "bad"]")
	if(!result)
		AdjustSorrow(0.2) // To prevent people from just spamming skill checks.
	return result

/mob/human/verb/toggle_cmode()
	set name = ".cmode"

	if(dead || !client)
		return FALSE

	if(on_cooldown("cmode"))
		return FALSE
	cooldown("cmode", 10)

	if(cmode == FALSE)
		cmode = TRUE

		client.play_droning(cmode_music)

		var/matrix/M = matrix()
		M.Scale(1.2,1.2)

		if(istype(holding, /obj/item/gun))
			var/atom/movable/effect = new(get_turf(src))
			effect.layer = MOB_LAYER + 0.1
			effect.icon = 'icons/obj/abstract/effects.dmi'
			effect.icon_state = "exclamation"

			var/matrix/turna = matrix()
			turna.Turn(10)
			turna.Scale(3,3)
			animate(effect, 3 SECONDS, transform = turna, alpha = 0, easing = QUAD_EASING|EASE_OUT)
			QDEL_IN(effect, 3 SECONDS)

			playsound(get_turf(src), 'sound/effects/obj/guns/aim.ogg', 75)

			for(var/mob/hearer in viewers(world.view, src))
				if(istype(hearer, /mob/lobbyman))
					continue
				if(hearer.client)
					var/icon/I = getFlatIcon(src, SOUTH)
					hearer << "\icon[I] <b>[src]</b> readies their firearm."

		playsound_local(get_turf(src), 'sound/effects/senses/combat_on.ogg', 100)

		animate(client, color = "#ddababff", easing = SINE_EASING | EASE_IN | EASE_OUT, time = 2)
		animate(client, pixel_z = 20, pixel_w = 20, easing = SINE_EASING | EASE_IN | EASE_OUT, time = 5)
		spawn(2)
			animate(client, color = "#ffefef", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 2)
			animate(client, pixel_z = 0, pixel_w = 0, easing = SINE_EASING | EASE_IN | EASE_OUT, time = 5)

		animate(hud_holder.combat.backgroundo, pixel_y = 0, easing = BOUNCE_EASING, time = 2)
	else
		cmode = FALSE

		client.stop_droning()

		playsound_local(get_turf(src), 'sound/effects/senses/combat_off.ogg', 100)

		animate(client, color = "#ffffff", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 2)
		animate(hud_holder.combat.backgroundo, pixel_y = -64, easing = BOUNCE_EASING, time = 2)

/mob/human/Stat()
	. = ..()
	if(dead)
		return
	stat("<br><br>") // The text looks ugly without this...
	stat("<div style='font-size: 125%'>[first_name] [last_name]</div>")
	stat("<div style='font-size: 110%'>[uppertext(mind.current_job?.title)]</div>")

	stat("-----------------------------------")

	stat("GOAL: [mind.goal?.name] <br>[mind.goal?.desc] (+[mind.goal?.award] XP) [mind.goal?.IsCompleted() ? "(COMPLETED)" : null]")

	if(mind.dissident)
		stat("<br>")
		stat("@#$%&!: [uppertext(mind.special_goal?.name)]")
		stat("[mind.special_goal?.desc] (+[mind.special_goal?.award] XP) [mind.special_goal?.IsCompleted() ? "(COMPLETED)" : null]")

	stat("<br><br>") // Ditto! (Not like the Pokémon) Check above!

	stat("QUIRKS:")
	if(mind.quirks.len)
		for(var/datum/quirk/Q in mind.quirks)
			stat("● [Q.display_name]")
	else
		stat("● None! You're just as ordinary as they come.")

	stat("-----------------------------------")

	stat("ABILITY SCORES:")
	if(mind.skills.len)
		for(var/S in mind.skills)
			stat("[S] ---- [skill_level_to_word(mind.GetSkill(S))] (~[mind.GetSkill(S)]%)<br>")
	else
		stat("● None? You're unemployable! Revel in the madness!")

	stat("-----------------------------------")

	if(ragdolled)
		stat("PRESS \[V\] TO STAND UP!")

	stat("INVENTORIUM:[holding ? " (HOLDING: [uppertext(holding.name)])" : null]")
	if(istype(holding, /obj/item/gun))
		var/obj/item/gun/G = holding
		var/gun_skill = clamp(mind?.GetSkill(GUNS) || 0, 0, 100)
		if(gun_skill > 10)
			var/reserve_ammo = ammo[G.ammo_type] || 0
			if(gun_skill >= 90)
				stat("AMMO (GUARANTEED): [G.ammo_loaded]/[G.ammo_max] ([reserve_ammo] RSRV)")
			else
				var/estimate_step = max(2, round((100 - gun_skill) / 10))
				var/estimated_loaded = min(G.ammo_max, max(0, round(G.ammo_loaded / estimate_step) * estimate_step))
				var/estimated_reserve = max(0, round(reserve_ammo / estimate_step) * estimate_step)
				stat("AMMO ([skill_level_to_word(mind?.GetSkill(GUNS))]): ~[estimated_loaded]/[G.ammo_max] (~[estimated_reserve] RSRV)")
	if(holding)
		if(!(hud_holder.maptext_holder in client.screen))
			client.screen += hud_holder.maptext_holder
			hud_holder.maptext_holder.txt("HOLDING: [uppertext(holding.name)]")
	else
		client.screen -= hud_holder.maptext_holder
	if(inventory.len)
		for(var/obj/item/I in inventory)
			stat(I)
	else
		stat("EMPTY!")