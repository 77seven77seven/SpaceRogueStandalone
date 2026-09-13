/obj/item
	name = "item"
	desc = "It's an item."
	icon = 'icons/obj/items.dmi'

	var/storable = TRUE // Can it be put into the inventory?
	var/stored = FALSE

/obj/item/proc/use(/mob/human/H) // pressing F when held
	return

/obj/item/proc/do_pickup_animation(atom/target)
	set waitfor = FALSE
	if(!istype(loc, /turf))
		return
	var/image/I = image(icon = src, loc = loc, layer = layer + 0.1)
	I.transform *= 0.75
	I.appearance_flags = RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|RESET_ALPHA|PIXEL_SCALE
	var/turf/T = get_turf(src)
	var/direction
	var/to_x = 0
	var/to_y = 0

	direction = get_dir(T, target)
	if(direction & NORTH)
		to_y = 32
	else if(direction & SOUTH)
		to_y = -32
	if(direction & EAST)
		to_x = 32
	else if(direction & WEST)
		to_x = -32
	if(!direction)
		to_y = 16
	for(var/client/C in master.clients)
		C << I
	var/matrix/M = new
	M.Turn(pick(-30, 30))
	animate(I, alpha = 30, pixel_x = to_x, pixel_y = to_y, time = 3, transform = M, easing = CUBIC_EASING)

	sleep(3)

	qdel(I)

/obj/item/interact(mob/user, obj/item/held_item) // picking up
	if(held_item || !ishuman(user))
		return
	var/mob/human/H = user

	if(src in H.inventory)
		H.inventory -= src

	playsound('sound/effects/pickup.ogg', get_turf(src), falloff = 4, vol = 100)
	do_pickup_animation(H)
	forceMove(H)
	H.holding = src

/mob/human/verb/inhand()
	set name = ".inhand"

	if(dead || ragdolled || !holding || !client)
		return FALSE

	holding.use(src)

/mob/human/verb/drop_item()
	set name = ".drop"

	if(dead || ragdolled || !holding || !client)
		return FALSE

	var/turf/drop_turf = client.movered
	if(!drop_turf || drop_turf.z != z)
		return FALSE
	if(abs(drop_turf.x - x) > 1 || abs(drop_turf.y - y) > 1)
		return FALSE

	holding.forceMove(drop_turf)
	holding.pixel_x = clamp(client.mpx - world.icon_size / 2, -8, 8)
	holding.pixel_y = clamp(client.mpy - world.icon_size / 2, -8, 8)

	holding = null
	return TRUE

/mob/human/verb/store()
	set name = ".store"

	if(dead || ragdolled || !holding || !client)
		return FALSE
	
	if(!holding.storable)
		chat_info("You're gonna need bigger pants if you wanna put THIS in your pockets.", "bad")
		return

	if(inventory.len >= inventory_space)
		chat_info("Your pockets are full.", "bad")
		return

	inventory += holding
	holding.forceMove(src)
	holding = null

/obj/item/consumable
	name = "consumable"
	var/nutrition = 0
	var/hydration = 0
	var/mood = 0

/obj/item/consumable/use(mob/human/H)
	if(nutrition)
		H.AdjustHunger(-nutrition)
	if(hydration)
		H.AdjustThirst(-hydration)
	if(mood)
		H.AdjustSorrow(-mood)

	H.holding = null
	qdel(src)

/obj/item/consumable/food
	name = "meal"
	nutrition = 35

/obj/item/consumable/water
	name = "water"
	hydration = 35