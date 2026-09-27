/obj/item/clothing
	name = "clothing"
	icon = 'icons/obj/items.dmi'
	icon_state = "fuck"

	desc = "A piece of clothing."
	storable = TRUE

	var/onmob_icon = 'icons/clothing/shirts.dmi'
	var/onmob_icon_state = null

	var/slot = null
	var/equipped = FALSE
	var/wearer
	var/random_color = TRUE

/obj/item/clothing/New(loc)
	. = ..()
	if(!random_color)
		return
	color = get_random_light_color()

/obj/item/clothing/use(mob/human/H)
	. = ..()
	H.holding = null
	H.UpdateInhand()

	if(slot == "hat" && H.hat)
		H.hat.remove_from_mob()
	if(slot == "shirt" && H.shirt)
		H.shirt.remove_from_mob()
	if(slot == "pants" && H.pants)
		H.pants.remove_from_mob()
	H.equip_clothing(src)

/obj/item/clothing/proc/equip_to(mob/human/H)
	if(!istype(H))
		return FALSE
	if(!slot)
		return FALSE
	if(src.equipped)
		return FALSE
	if(wearer)
		return FALSE

	if(slot == "hat" && H.hat)
		return FALSE
	if(slot == "shirt" && H.shirt)
		return FALSE
	if(slot == "pants" && H.pants)
		return FALSE

	if(src in H.inventory)
		H.inventory -= src

	wearer = H
	equipped = TRUE
	forceMove(H)

	if(slot == "hat")
		H.hat = src
		H.hat_overlay = image(src.onmob_icon, H, src.onmob_icon_state)
		H.hat_overlay.appearance_flags = RESET_COLOR
		H.hat_overlay.color = H.hat.color

		H.overlays += H.hat_overlay
		
	else if(slot == "shirt")
		H.shirt = src
		H.shirt_overlay = image(src.onmob_icon, H, src.onmob_icon_state)
		H.shirt_overlay.appearance_flags = RESET_COLOR
		H.shirt_overlay.color = H.shirt.color

		H.overlays += H.shirt_overlay

	else if(slot == "pants")
		H.pants = src
		H.pants_overlay = image(src.onmob_icon, H, src.onmob_icon_state)
		H.pants_overlay.appearance_flags = RESET_COLOR
		H.pants_overlay.color = H.pants.color

		H.overlays += H.pants_overlay

	if(H.client)
		H.UpdateHUD()
	return TRUE

/obj/item/clothing/proc/remove_from_mob()
	if(!wearer)
		return FALSE

	var/mob/human/old_wearer = wearer
	if(slot == "hat")
		old_wearer.hat = null
		old_wearer.overlays -= old_wearer.hat_overlay
	else if(slot == "shirt")
		old_wearer.shirt = null
		old_wearer.overlays -= old_wearer.shirt_overlay
	else if(slot == "pants")
		old_wearer.pants = null
		old_wearer.overlays -= old_wearer.pants_overlay

	equipped = FALSE
	wearer = null
	if(!(src in old_wearer.inventory))
		old_wearer.inventory += src
	else
		forceMove(get_turf(old_wearer))
	return TRUE

/obj/item/clothing/hat
	name = "hat"
	icon_state = "hat"

	onmob_icon = 'icons/clothing/hats.dmi'
	slot = "hat"

/obj/item/clothing/shirt
	name = "shirt"
	icon_state = "shirt"

	onmob_icon = 'icons/clothing/shirts.dmi'
	slot = "shirt"

/obj/item/clothing/shirt/New(loc)
	. = ..()
	onmob_icon_state = "shirt[rand(1,39)]"

/obj/item/clothing/shirt/megadeathtether
	name = "mega death tether fan shirt"
	onmob_icon_state = "shirt40"

/obj/item/clothing/shirt/megadeathtether/New(loc)

/obj/item/clothing/pants
	name = "pants"
	icon_state = "pants"

	onmob_icon = 'icons/clothing/pants.dmi'
	slot = "pants"

/obj/item/clothing/pants/New(loc)
	. = ..()
	onmob_icon_state = "pants[rand(1,39)]"