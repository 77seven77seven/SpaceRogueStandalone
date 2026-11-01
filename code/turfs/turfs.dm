// manage

/turf
	var/base_icon_state = "rwall"
	var/list/footstep_sounds

/turf/Initialize()
	..()

	if(dynamic_lighting && loc && loc.lighting_use_dynamic)
		lighting_build_overlays()

	// give all non-dense turfs a 47-state autojoining shadow.
	if(!density)
		var/n = autojoin47("density")
		var/icon/shadow = icon('icons/turf/autojoin/shadows.dmi', "[n]")
		overlays += shadow

	// give all dense turfs a 16-state autojoining outline.
	else
		var/n = autojoin16("density")
		icon_state = "[base_icon_state][n]"

// solid

/turf/solid
	density = TRUE
	opacity = TRUE
	layer = TURF_LAYER + 0.1

/turf/solid/wall
	name = "wall"
	icon = 'icons/turf/rs_walls.dmi'

	base_icon_state = "rwall"
	icon_state = "rwall0"

/turf/solid/wall/Initialize()
	. = ..()
	var/rando = rand(230,255)
	src.color = rgb(rando,rando,rando)

/obj/deco/maint_tunnel
	name = "maintenance tunnel"
	desc = "When you look at this, you ponder... do we really <b>need</b> to go deeper?"

	alpha = 10
	icon_state = "maint_tunnel"
	icon = 'icons/obj/deco.dmi'

/obj/deco/maint_tunnel/Initialize()
	. = ..()
	var/matrix/turna = matrix(transform)
	var/turn = rand(-5,5)
	turna.Turn(turn)
	transform = turna

	var/px = rand(-5,5)
	var/py = rand(-5,5)
	pixel_x = px
	pixel_y = py

/obj/deco/maint_tunnel/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	if(user.on_cooldown("vent")) return
	user.cooldown("vent", 1 SECOND)

	if(user.SkillRoll("GENERIC", FALSE, -50))
		user.AdjustSorrow(2)
		user.AdjustThirst(1)
		user.AdjustHunger(2)

		var/turf/exit = get_step(get_turf(src), user.dir)
		if(istype(exit, /turf/open/floor))
			playsound(get_turf(user), 'sound/effects/obj/vent_crawl.ogg', 20, FALSE, -3, ignore_walls = TRUE)
			user.go_blind(0.3,4)
			user.forceMove(exit)

/obj/deco/maint_tunnel/MouseEntered(location, control, params)
	. = ..()
	if(name && ishuman(usr))
		if(Adjacent(usr)) animate(src, time = 2 SECONDS, alpha = 40)

/obj/deco/maint_tunnel/MouseExited(location, control, params)
	. = ..()
	alpha = 10

/turf/solid/window
	name = "window"
	icon = 'icons/turf/rs_windows.dmi'

	opacity = FALSE

	base_icon_state = "fwindow"
	icon_state = "fwindow0"

// open

/turf/open
	density = FALSE
	icon = 'icons/turf/rs_floors.dmi'

/turf/open/floor
	name = "floor"
	icon_state = "floor"
	var/artisinal = TRUE
	footstep_sounds = list('sound/effects/obj/footstep_metal.ogg')

/turf/open/floor/Initialize()
	. = ..()
	if(artisinal)
		icon_state = "[initial(icon_state)][rand(1,4)]"
		dir = pick(NORTH,SOUTH,EAST,WEST)
	
	if(istype(get_area(src), /area/station/maintenance) || prob(5))
		if(prob(rand(10,40)))
			var/image/I = image('icons/turf/decals.dmi', src, pick("dirt","pepper","crumbs"))
			I.alpha = rand(50,200)
			overlays += I

/turf/open/floor/light
	color = list(
		1.25, 0,   0,   0,
		0,   1.25, 0,   0,
		0,   0,   1.25, 0,
		0,   0,   0,   1, // Keeps alpha (transparency) normal
		0,   0,   0,   0
	)

/turf/open/floor/dark
	name = "floor"
	icon = 'icons/turf/rs_floors.dmi'
	icon_state = "dark"

/turf/open/floor/wood
	icon_state = "wood"
	artisinal = FALSE
	footstep_sounds = list('sound/effects/obj/footstep_wood.ogg')

/turf/open/floor/wood/alt
	icon_state = "wood_alt"

/turf/open/floor/wood/tile
	icon_state = "wood_tile"

/turf/open/space
	name = "space"
	desc = "The final frontier."
	icon = 'icons/turf/space.dmi'
	icon_state = "roguespace"
	var/cahed

/turf/open/space/Initialize()
	. = ..()
	dir = pick(SOUTH,NORTH,WEST,EAST)
	
	var/tim = 100 - rand(-20,20)

	animate(src, color="#f00f", easing=QUAD_EASING|EASE_OUT, time=tim, loop=-1)
	animate(color="#ffff", easing=QUAD_EASING|EASE_IN, time=tim)