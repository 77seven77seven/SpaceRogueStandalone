/obj/item
	name = "item"
	icon = 'icons/obj/items.dmi'

	mouse_over_pointer = MOUSE_HAND_POINTER

	var/dropshrink = 0.8
	var/droprot = TRUE

	var/inhand_icon = 'icons/human/inhands/items.dmi'
	var/inhand_icon_state = "generic"

	var/vendor_name // Optional short vendor label; generated from the item name when unset.
	var/vendor_price = -1 // Generic price to buy from a vendor. It's at a strange value for easy bugfinding.
	var/buy_rollable = TRUE // Can this item be rolled in the Technician's machine? Will invent a random vendor_price if it does.

	var/storable = TRUE // Can it be put into the inventory?
	var/stored = FALSE

	var/junk = FALSE // Can not be used. Can only be thrown away. "I eat something junk... Yes... a.. shit..."
	var/harmful = FALSE // Only allows attack() calls when AWARENESS is toggled on.

/obj/item/proc/use(mob/human/H) // pressing F when held
	return
	
/obj/item/proc/attack(mob/human/user, mob/human/target) // when user clicks target, it prompts interact, which then prompts attack on the item.
	return

/obj/item/proc/update_transform()
	transform = null
	if(isturf(loc))
		var/matrix/M = matrix()
		if(dropshrink)
			M.Scale(dropshrink,dropshrink)
		if(droprot)
			M.Turn(rand(50,350))
		transform = M

/obj/item/proc/destroyself(mob/human/H)
	H.holding = null
	H.UpdateInhand()
	
	qdel(src)

/obj/item/proc/junkize(mob/human/H)
	src.junk = TRUE
	if(src.desc_expansive) // Mostly for medical items, so you can tell they're JUNK when it matters.
		desc_expansive = null

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
		to_y = 64
	else if(direction & SOUTH)
		to_y = -64
	if(direction & EAST)
		to_x = 64
	else if(direction & WEST)
		to_x = -64
	if(!direction)
		to_y = 32
	for(var/client/C in master.clients)
		C << I
	var/matrix/M = new
	M.Turn(pick(-30, 30))
	animate(I, alpha = 30, pixel_x = to_x, pixel_y = to_y, time = 3, transform = M, easing = CUBIC_EASING)

	sleep(3)

	qdel(I)

/mob/human/verb/inhand()
	set name = ".inhand"

	if(dead || ragdolled || !holding || !client)
		return FALSE

	if(!holding.junk)
		holding.use(src)

// Cache of icon file -> list(width, height) so we don't build an /icon on every drop
var/list/icon_dim_cache = list()

/atom/movable/proc/get_icon_dims()
	if(!icon)
		return list(world.icon_size, world.icon_size)
	if(!isfile(icon))
		// runtime /icon datum, can't be cached by key
		var/icon/runtime_icon = icon(icon)
		return list(runtime_icon.Width(), runtime_icon.Height())
	var/key = "[icon]"
	var/list/dims = icon_dim_cache[key]
	if(!dims)
		var/icon/I = icon(icon)
		dims = list(I.Width(), I.Height())
		icon_dim_cache[key] = dims
	return dims

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
	holding.update_transform()

	// How far the icon overhangs the tile on each axis, split evenly per side.
	// 0 for a standard icon, 32 for a 128x128 icon on a 64x64 tile.
	var/list/dims = holding.get_icon_dims()
	var/overhang_x = round((dims[1] - world.icon_size) / 2)
	var/overhang_y = round((dims[2] - world.icon_size) / 2)

	// Offset of the item's *center* from the tile's center
	var/newx = 0
	var/newy = 0
	if(client.mpx != null && client.mpy != null)
		newx = client.mpx - world.icon_size / 2
		newy = client.mpy - world.icon_size / 2
		if(!locate(/obj/deco/furniture/table) in drop_turf.contents)
			newx = clamp(newx, -16, 16)
			newy = clamp(newy, -16, 16)
		else
			newx = clamp(newx, -32, 32)
			newy = clamp(newy, -32, 32)

	// Shift back by the overhang so the icon's center, not its corner, lands there
	holding.pixel_x = newx - overhang_x
	holding.pixel_y = newy - overhang_y

	holding = null
	UpdateInhand()
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
	holding.update_transform()
	holding = null
	UpdateInhand()

/obj/item/Initialize()
	. = ..()
	update_transform()

/obj/item/get_examine_text()
	var/desco = desc
	if(junk)
		desco = "[desc] <b>\[JUNK\]</b>"
	return desco

/obj/item/interact(mob/user, obj/item/held_item) // picking up
	. = ..()
	if(held_item || !ishuman(user))
		return
	var/mob/human/H = user

	if(H.dead || H.ragdolled || !H.client)
		return FALSE

	if(src in H.inventory)
		H.inventory -= src

	playsound(get_turf(src), 'sound/effects/pickup.ogg', falloff_exponent = 4, vol = 75)
	do_pickup_animation(H)
	forceMove(H)
	H.holding = src

	H.UpdateInhand()

/obj/item/ticket
	name = "bus ticket"
	desc = "A public transport permit, your key to the rest of civilized space."

	icon_state = "ticket"

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
		var/moodrand = mood - rand(-4,4)
		H.AdjustSorrow(-moodrand)

	destroyself(H)

/obj/item/consumable/nutrition
	name = "nutrition bar"
	icon_state = "nutritionbar"
	desc = "Imported from some backwater (compared to where <u>you</u> are though, it is quite close to human civilization at large) waterworld. Not very good, and the amount of time it took to transport here probably didn't do it any favors."
	desc_expansive = "Fish offal and kelp, squeezed into a tightly packed nutritional brick through sheer tyranny of will."
	nutrition = 20
	mood = -12

	vendor_name = "NBAR"
	vendor_price = 20

/obj/item/consumable/annegree
	name = "Anne-Gree Cola"
	icon_state = "annegree"

	desc = "A refreshing can of soda, mixed with chemicals to trick your taste buds into percepting it is colder than it is, even if stored at room temperature. Refreshing."
	desc_expansive = "This product's name was censored after the UN Performative Display of Emotion Prohibition act was enacted, and prohibited brands from naming themselves or their products after emotions or feelings. Pronounced Anney-Gree. Supposedly."
	hydration = 15
	mood = 25

	vendor_name = "ANNE"
	vendor_price = 15

/obj/item/consumable/limelite
	name = "Lime-Lite"
	icon_state = "limelite"

	desc = "Lime-Lite™, a lithiated lemon-lime soda coming to space stations near you! Be refreshed, even in space. \"Be Lime-Wired!\""
	desc_expansive = "Rumors are that the company behind Lime-Lite™ is owned by the same company that makes Anne-Gree®, using the fierce competition public angle as a mere marketing stunt between corporations."
	hydration = 25
	mood = 15

	vendor_name = "LIME"
	vendor_price = 15