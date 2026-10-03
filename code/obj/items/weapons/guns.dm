#define SMALL_AMMO "SMALL" // Common for small pistols.
#define MEDIU_AMMO "MEDIUM" // Rare ammo, used mostly for exotic firearms. Not commonly found in vending machines.
#define BIG_AMMO "BIG" // Big 
#define SHOTG_AMMO "SHELLS"

/obj/item/gun
	name = "Wonder"
	desc = "The Wonder is one of the Wonder Nines family of firearms. An iconic, all-metal small bulleted semi-automatic pistol."
	desc_expansive = "The Wonder Nines family of firearms has nine sons, all which have only nine bullet capacity due to legal standards. This gun is most widely used in CHEZ Group operated regions, even though most employees of the corporation use alternatives."

	icon_state = "gun"
	inhand_icon = 'icons/human/inhands/guns.dmi'
	inhand_icon_state = "gun"

	var/list/gunshot_sounds = list('sound/effects/obj/guns/pistol1.ogg','sound/effects/obj/guns/pistol2.ogg','sound/effects/obj/guns/pistol3.ogg')

	var/damage = 20
	var/headshot_damage = 99 // Basically all headshots are deadly.
	
	var/ammo_type = SMALL_AMMO
	var/ammo_loaded = 9
	var/ammo_max = 9

	var/range = 20 * WORLD_ICON_SIZE       // pixels, 20 tiles, enough basically
	
	var/spread = 10                   // measured in pixels
	var/spread_range = 4 * WORLD_ICON_SIZE  // ...measured at this distance (keep > spread)
	
	var/fire_delay = 3                // deciseconds
	var/next_fire = 0

	var/tracers = FALSE

/obj/item/gun/revolver
	name = "Alpha"
	desc = "AlphaProj high-calibre revolvers are a staple of any self-respecting gun owner. Recently they have gotten a bad reputation due to their involvement in the Ganymedean Civil War."
	desc_expansive = "A man pulls the trigger on a deserter, his brains are blown out, the executioner looks at the weapon of infamy in his hand. It is an Alpha. Holds six rounds, evidently."

	ammo_type = BIG_AMMO
	ammo_loaded = 6
	ammo_max = 6

	damage = 40
	headshot_damage = 100

/obj/item/gun/assault
	name = "Template"
	desc = "Template 58. These firearms combined have more lives claimed than disease and famine, while bringing death and war."
	desc_expansive = "There is nothing more to say about it. Holds thirty rounds of large calibers."

	damage = 40
	headshot_damage = 100
	
	ammo_type = BIG_AMMO
	ammo_loaded = 30
	ammo_max = 30

/obj/item/gun/proc/Fire(mob/shooter, aim_x, aim_y)
	// aim_x / aim_y are WORLD pixel coordinates of where the shooter is aiming
	if(world.time < next_fire)
		return
	next_fire = world.time + fire_delay

	// Muzzle = centre of the shooter, in world pixels
	var/ox = (shooter.x - 1) * WORLD_ICON_SIZE + shooter.step_x + WORLD_ICON_SIZE / 2
	var/oy = (shooter.y - 1) * WORLD_ICON_SIZE + shooter.step_y + WORLD_ICON_SIZE / 2

	// Unit vector toward the aim point
	var/dx = aim_x - ox
	var/dy = aim_y - oy
	var/len = sqrt(dx * dx + dy * dy)
	if(len < 1)
		return
	dx /= len
	dy /= len

	// Random spread: put a virtual target spread_range px away along the aim
	// line, then nudge it by a random offset inside a circle of `spread` px.
	if(spread > 0)
		var/ang = rand() * 360
		var/rad = spread * sqrt(rand())
		dx = dx * spread_range + rad * cos(ang)
		dy = dy * spread_range + rad * sin(ang)
		len = sqrt(dx * dx + dy * dy)
		dx /= len
		dy /= len

	animate(shooter?.client, color = "#f3d4d4ff", easing = EASE_OUT, time = 0.5)
	animate(color = "#ffefef", easing = EASE_IN, time = 0.5)

	firearm_recoil_mob(shooter)

	playsound(get_turf(shooter), pick(gunshot_sounds), 75, TRUE)
	for(var/mob/M in station.humans)
		var/turf/M_turf = get_turf(M)
		if(!M_turf)
			continue
		if(get_dist(M_turf, shooter.loc) < 7)
			continue
		M.playsound_local(M_turf, 'sound/effects/obj/guns/distantshot.ogg', 60, 1, get_rand_frequency(), falloff_exponent = 5)

	var/datum/ray_hit/hit = PixelRaycast(ox, oy, shooter.z, dx, dy, range, shooter)

	if(tracers)
		new /obj/tracer(get_turf(shooter), ox, oy, ox + dx * hit.dist, oy + dy * hit.dist)
	new /atom/movable/casing(get_turf(shooter))

	if(istype(hit.target, /mob/human))
		var/mob/human/victim = hit.target
		var/dmg = damage
		if(hit.zone == "head")
			dmg = headshot_damage
		victim.TakeDamage(dmg, hit.zone, shooter)
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
			if(victim.broke_bones < victim.bones)
				victim.broke_bones++
				victim.AdjustBleeding(rand(7,13))

/client/Click(atom/object, location, control, params)
	var/mob/human/H = mob
	if(!istype(H) || !H.holding || !istype(H.holding, /obj/item/gun) || !H.cmode)
		return ..()

	var/obj/item/gun/G = H.holding
	var/turf/T = get_turf(object)
	if(!T)
		return ..()
	var/list/p = params2list(params)
	// icon-x / icon-y are 1-based pixels inside the clicked icon
	var/aim_x = (T.x - 1) * WORLD_ICON_SIZE + (text2num(p["icon-x"]) - 1)
	var/aim_y = (T.y - 1) * WORLD_ICON_SIZE + (text2num(p["icon-y"]) - 1)
	G.Fire(H, aim_x, aim_y)

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