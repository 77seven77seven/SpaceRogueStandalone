/obj/item
	name = "item"
	desc = "It's an item."
	icon = 'icons/obj/items.dmi'
	var/storable = TRUE // Can it be put into the inventory?

/obj/item/proc/use(/mob/human/H) // pressing F when held
	return

/obj/item/interact(mob/user, obj/item/held_item) // picking up
	if(held_item || !ishuman(user))
		return
	var/mob/human/H = user

	H.swing_anim(src, 8, 5, 3)

	forceMove(H)
	H.holding = src

/mob/human/verb/inhand()
	set name = ".inhand"

	if(!holding)
		return

	if(!src || src.dead)
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
	holding.pixel_x = client.mpx - world.icon_size / 2
	holding.pixel_y = client.mpy - world.icon_size / 2

	holding = null
	return TRUE

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