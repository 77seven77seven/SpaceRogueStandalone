/obj/item/clothing
	name = "clothing"
	icon = 'icons/clothing/item.dmi'
	desc = "A piece of clothing."
	storable = TRUE

	var/onmob_icon = 'icons/clothing/shirts.dmi'

	var/slot = null
	var/equipped = FALSE
	var/wearer
	var/list/possible_colors = list("#F4F4F4")

/obj/item/clothing/Initialize()
	. = ..()
	if(!possible_colors || !length(possible_colors))
		return
	color = pick(possible_colors)
	return

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
		H.hat_overlay = image(src.onmob_icon, H, src.icon_state)
		H.hat_overlay.appearance_flags = RESET_COLOR
		H.overlays += H.hat_overlay
		
	else if(slot == "shirt")
		H.shirt = src
		H.shirt_overlay = image(src.onmob_icon, H, src.icon_state)
		H.shirt_overlay.appearance_flags = RESET_COLOR
		H.overlays += H.shirt_overlay

	else if(slot == "pants")
		H.pants = src
		H.pants_overlay = image(src.onmob_icon, H, src.icon_state)
		H.pants_overlay.appearance_flags = RESET_COLOR
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
	forceMove(get_turf(old_wearer))
	return TRUE

/obj/item/clothing/hat
	name = "hat"
	icon_state = "hat"

	onmob_icon = 'icons/clothing/hats.dmi'

	slot = "hat"
	possible_colors = list("#534B3E", "#8B5A2B", "#8E9E99", "#2C3E50", "#7B3F00")

/obj/item/clothing/shirt
	name = "shirt"
	icon_state = "shirt"

	onmob_icon = 'icons/clothing/shirts.dmi'

	slot = "shirt"
	possible_colors = list("#4F5D75", "#A3B18A", "#C4A35C", "#B55446", "#6B7280")

/obj/item/clothing/pants
	name = "pants"
	icon_state = "pants"

	onmob_icon = 'icons/clothing/pants.dmi'

	slot = "pants"
	possible_colors = list("#3A3A3A", "#5A4A3A", "#2D5A3E", "#4A4F6A", "#7A5A3A")