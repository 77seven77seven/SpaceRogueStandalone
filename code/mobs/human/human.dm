/mob/human
	name = "human being"
	icon = 'icons/human/human.dmi'
	icon_state = "human"

	appearance_flags = KEEP_APART|TILE_BOUND|PIXEL_SCALE

	var/base_delay = 3
	var/move_delay = 3

	var/first_name = "Urist"
	var/last_name = "H."

	var/is_moving = FALSE
	var/tmp/next_move = 0
	var/tmp/next_attack = 0

	var/datum/disease/disease
	var/datum/mind/mind

	var/health = HUMAN_MAX_HEALTH
	var/max_health = HUMAN_MAX_HEALTH
	var/blood = 100
	var/bleeding = 0

	var/bones = 2 // how many bones you can break
	var/broke_bones = 0

	var/dead = FALSE
	var/ragdolled = FALSE
	var/cmode = FALSE

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

	var/sorrow_recovery = 0.7

	var/tmp/next_needs_process = 0
	var/tmp/last_needs_process = 0
	var/tmp/sorrow_cycles = 0
	var/tmp/heart_attack = FALSE
	var/tmp/hud_hunger
	var/tmp/hud_thirst
	var/tmp/list/cooldowns = list()

	var/sorrow = 0 // if youre at 100 for too long, you suffer a heartattack, collapse and then die

	var/list/obj/item/inventory = list()
	var/inventory_space = 10
	var/obj/item/holding

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

	var/xp_buffer = 0 // you wont get your XP unless you depart the station bro!

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
	UpdateMoveDelay()

	filters += filter(type="drop_shadow", x=2, size=2, offset=1)

/mob/human/Destroy(force = FALSE)
	if(processor)
		processor.processing -= src
	if(station)
		station.humans -= src
		station.dead_humans -= src
	return ..()

/mob/human/Move(NewLoc, Dir, step_x, step_y)
	if(dead || ragdolled)
		return FALSE

	var/time = world.time

	if(next_move > time)
		return FALSE

	//glide_size = ICON_SIZE / max(move_delay,TICK_LAG) * TICK_LAG

	next_move = time + move_delay
	return ..()

/mob/human/Click(location, control, params)
	. = ..()
	var/input = input(src, "bleed") as num|null
	if(input)
		AdjustBleeding(input)

/mob/human/interact(mob/user, obj/item/held_item)
	. = ..()
	var/mob/human/Huser = user
	if(held_item)
		if(held_item.harmful && !Huser.cmode)
			return
		held_item.attack(Huser, src)

/mob/human/proc/cooldown(cooldown_name, cooldown_duration)
	if(!cooldowns)
		cooldowns = list()

	if(cooldowns[cooldown_name])
		cooldowns[cooldown_name] = max(cooldowns[cooldown_name], world.time + cooldown_duration * world.tick_lag)
	else
		cooldowns[cooldown_name] = world.time + cooldown_duration * world.tick_lag

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

/mob/human/proc/SetRagdolled(value)
	if(ragdolled == value)
		return

	ragdolled = value
	if(ragdolled)
		var/matrix/M = matrix()
		var/turnation = prob(50) ? 90 : -90
		transform = M.Turn(turnation)
	else
		transform = null
	dir = SOUTH

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

/mob/human/proc/Die(cause)
	if(dead)
		return FALSE

	dead = TRUE
	health = 0
	is_moving = FALSE

	UpdateHUD()
	SetRagdolled(TRUE)
	
	if(processor)
		processor.processing -= src

	if(station)
		station.humans -= src
		if(!station.dead_humans.Find(src))
			station.dead_humans += src

	var/obj/hud/fullscreen/death/death = new()
	death.alpha = 0
	
	client.screen += death
	client.color = "#000000"

	animate(death, time = 20, easing = QUAD_EASING | EASE_IN | EASE_OUT, alpha = 150)
	client << sound(null)
	client << sound('sound/death.ogg')
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

/mob/human/proc/AdjustSorrow(amount)
	var/old_sorrow = sorrow
	sorrow = max(0, min(max_need, sorrow + amount))
	if(sorrow < max_need)
		sorrow_cycles = 0
	if(old_sorrow != sorrow)
		UpdateHUD()
	return sorrow - old_sorrow

/mob/human/proc/UpdateMoveDelay()
	var/penalty = 0
	if(hunger >= 50)
		penalty++
	if(hunger >= 70)
		penalty++

	if(thirst >= 50)
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

	penalty += broke_bones * 1.5

	move_delay = max(1, base_delay + penalty)
	return move_delay

/mob/human/proc/ProcessNeeds(elapsed = HUMAN_NEEDS_PROCESS_INTERVAL)
	if(dead)
		return FALSE

	AdjustHunger(hunger_rate * elapsed * (cmode ? 1.4 : 1))
	AdjustThirst(thirst_rate * elapsed * (cmode ? 1.3 : 1))

	if(hunger >= starvation_threshold)
		TakeDamage(starvation_damage, "starvation")
	if(thirst >= dehydration_threshold)
		TakeDamage(dehydration_damage, "dehydration")

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
	else if(sorrow < max_need)
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
	if(health <= 0)
		Die("heart attack")
	else
		TakeDamage(health, "heart attack")
	return TRUE

/mob/human/proc/wristpad_display_change(colorina)
	overlays -= wristpad_glow
	wristpad_glow.color = colorina
	overlays += wristpad_glow

/mob/human/proc/eyes_color_change(colorina)
	overlays -= eyes
	eyes.color = colorina
	overlays += eyes

/mob/human/proc/Initialize_HUD()
	hud_holder = new /obj/hud/sysmas(src)

	hud_holder.bg_stats = new /obj/hud/bg_stats(src)
	hud_holder.bg_health = new /obj/hud/bg_health(src)
	hud_holder.health = new /obj/hud/health(src)
	hud_holder.combat = new /obj/hud/combat(src)

	client.screen += hud_holder.bg_stats
	client.screen += hud_holder.bg_health
	client.screen += hud_holder.health
	client.screen += hud_holder.combat

/mob/human/proc/UpdateHUD()
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
	hud_holder?.Update()

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
	if(mind.dissident)
		client << sound('sound/music/spawn.ogg', volume = 75)
		spawn(5)
			client << sound('sound/music/violent_terms.ogg', volume = 75)
	else
		client << sound('sound/music/spawn.ogg', volume = 75)
	client.color = "#000000"
	animate(client, color = "#ffffff", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 50)

	chat_info("You are <b>[uppertext("[first_name] [last_name]")]</b>, the <b>[uppertext(mind.current_job.title)]</b>.")
	chat_info("[mind.current_job.desc]\n")

	chat_info("Your goal is: <b>[mind.goal]</b>")
	chat_info("[mind.goal.desc] ([mind.goal.award] XP)")

	if(mind.dissident) // dissidence welcomings flavor text
		chat_info("\n<b>----@#$%&!-------#$%---!!!HAAHAHAHHA---</b>\n","bad")
		chat_info("TRANSMISSION DECRYPTED, COURTESY OF THE <b>[pick("BLIND EYES OF A COWARD","MISTAKES IN THE MAKING","CITADEL","CRYING ANGELS","RENNE DANG TOMBOLA","ONES FREED FROM DESIRE","STARMEN","TAK-TAK-TAKYON","GOLDEN BROWNS","AMERICANO","M.I.T.M","P.M.J","D.A.O.T.S","OKTOBERKLUB","VIOLENT TERMS")]!\n</b>","bad")
		chat_info("<b>[pick("INTERNAL ARMISTICE!","TRYING TO DEFY THE EMPOWERED!","LITTLE FIRE THAT THEY CAN'T PUT OUT!","FETCH ME A BUCKET, THIS IS ABOUT TO BLOW!", "ONE DAY YOU'LL LEAVE THIS WORLD BEHIND!","MAYBE YOU SHOULD CONSIDER... MORE VIOLENT TERMS?!","RING RING GOES THE TELEHPONE... I'M HANGING UP ON YOU!!")]</b>, YOUR MISSION IS: <b>[uppertext(mind.special_goal)]</b>","bad")
		chat_info("[mind.special_goal.desc] ([mind.special_goal.award] XP)","bad")
	else
		if(client.dissidence_preference)
			chat_info("\nYou FAILED the roll for becoming a dissident. <b>[pick("Better luck next time.","I'm sure you'll get to be a bad guy next time.","Aww... is someone sad? Don't worry, you can still kill people. Just with less leeway now.")]</b>","bad")

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

		var/turf/starto = locate(1,1,1)
		for(var/obj/abstract/landmark/start/sloc in landmarks_start_list)
			if(sloc.name != R.title)
				continue
			starto = get_turf(sloc)
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

	var/firsto = "[pick(world.file2list("strings/[pick(replicao)]_[gendero].txt"))]"
	var/lasto = "[GetRandomLetterUpper()]."

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

	var/rando = rand(220,255)
	color = rgb(rando, rando + 5, rando) // Random skintone

	wealth = floor(rand(0,12) + 2.857 * client.xp)
	if(randomize_certain_values)
		thirst = rand(0,43)
		hunger = rand(0,43)

	Initialize_HUD()
	UpdateHUD()

	if(!voice_freq)
		GenerateVoice()

	if(istype(R.special_role_goal) && prob(R.special_role_goal_prob))
		var/new_goal
		if(islist(R.special_role_goal))
			new_goal = pick(R.special_role_goal)
		else
			new_goal = R.special_role_goal
		mind.goal = new new_goal()
	else
		var/new_goal = get_me_a_goal()
		mind.goal = new new_goal()
	
	if(is_dissident)
		var/new_special_goal = get_me_a_goal(is_dissident)
		mind.special_goal = new new_special_goal()
		mind.dissident = TRUE

	for(var/datum/quirk/Q in mind.quirks)
		Q.equip(src)

/mob/human/proc/SkillRoll(skill_name)
	var/skill_value = mind.GetSkill(skill_name)
	
	var/probability = 0
	var/xp_bonus = 0.024 * 20
	var/adjusted_chance = skill_value - ceil(sorrow / 10) + rand(-7,7) // 7seven

	probability = adjusted_chance

	if(probability >= 40)
		xp_bonus /= 1.2

	src << "[skill_name] --- PROB: [probability]% , VALUE: [skill_value] , VAL: [adjusted_chance]"
	if(prob(probability + xp_bonus))
		src << "success"
	else
		src << "fail"

/mob/human/verb/speak()
	set name = ".speak"

	if(dead || !client)
		return FALSE

	var/timer = world.time + 60
	var/msg = input(src, null, null) as null|text

	if(msg)
		VoiceBlip(msg)
	else
		if(world.time > timer)
			for(var/mob/M in hearers(6, src))
				if(M.client)
					var/icon/I = getFlatIcon(src, SOUTH)
					M << "\icon[I] <b>[src]</b> wanted to say something, but \he changed \his mind."

/mob/human/verb/toggle_cmode()
	set name = ".cmode"

	if(dead || !client)
		return FALSE

	if(on_cooldown("cmode"))
		return FALSE
	cooldown("cmode", 20)

	if(cmode == FALSE)
		cmode = TRUE

		var/matrix/M = matrix()
		M.Scale(1.2,1.2)

		client << sound('sound/effects/senses/combat_on.ogg')

		animate(client, color = "#ddababff", easing = SINE_EASING | EASE_IN | EASE_OUT, time = 2)
		animate(client, pixel_z = 20, pixel_w = 20, easing = SINE_EASING | EASE_IN | EASE_OUT, time = 5)
		spawn(2)
			animate(client, color = "#ffefef", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 2)
			animate(client, pixel_z = 0, pixel_w = 0, easing = SINE_EASING | EASE_IN | EASE_OUT, time = 5)

		animate(hud_holder.combat.backgroundo, pixel_y = 0, easing = BOUNCE_EASING, time = 2)
	else
		cmode = FALSE

		client << sound('sound/effects/senses/combat_off.ogg')

		animate(client, color = "#ffffff", easing = QUAD_EASING | EASE_IN | EASE_OUT, time = 2)
		animate(hud_holder.combat.backgroundo, pixel_y = -32, easing = BOUNCE_EASING, time = 2)

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

	stat("INVENTORIUM:")
	if(inventory.len)
		for(var/obj/item/I in inventory)
			stat(I)
	else
		stat("EMPTY!")