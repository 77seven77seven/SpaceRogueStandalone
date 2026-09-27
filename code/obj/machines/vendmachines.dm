#define YES_TAXES 0
#define NO_TAXES 1
#define GAMBLE_A_TRON 2

/datum/vending_product
	var/name = "generic"
	///Typepath of the product that is created when this record "sells"
	var/product_path = null
	///How many of this product we currently have
	var/amount = 0
	///How many we can store at maximum
	var/max_amount = 0
	///The price of the item
	var/price

/datum/vending_product/proc/get_price(taxless)
	var/obj/item/temp = product_path
	var/vendor_price = temp.vendor_price

	if(taxless)
		if(taxless == 2)
			return floor(vendor_price + rand(-10,10)) // GAMBLING!
		else
			return vendor_price
	else
		var/tax_fee
		if(station.get_tax())
			tax_fee = vendor_price / station.get_tax()
		else
			tax_fee = 0
		return vendor_price + tax_fee

/obj/machine/vendor
	name = "WENDR"
	desc = "WENDR-type vz. 68. Not meant for civilian/consumer use. Limited in production. Tread lightly."

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "vend"

	var/color_tint
	var/overlay_icon

	density = TRUE
	opacity = FALSE

	maptext = "<div style='color:#A4A4A2; line-height: 0.6; text-align:center; font-size: 80%; font-family: Tiny5;'>OHNOE<br>900§</div>"
	maptext_width = 40
	maptext_height = 48
	maptext_y = 32
	maptext_x = 13

	var/list/items = list() // List of products this vendor sells, form should be list(/type/path = amount, /type/path2 = amount2)
	var/list/datum/vending_product/product_records = list() // This is what is used for keeping track of items.
	var/items_index = 1
	
	var/obj/item/restock_package/package_type
	var/jammed = FALSE
	var/taxless = YES_TAXES

/obj/machine/vendor/Initialize()
	. = ..()
	build_inventory(product_records)
	if(overlay_icon)
		var/image/I = image('icons/obj/terminals/vendor_brands.dmi', src, overlay_icon)
		overlays += I
	if(color_tint)
		var/image/I = image('icons/obj/terminals/vendor_brands.dmi', src, "tint_[icon_state]")
		I.blend_mode = BLEND_MULTIPLY
		I.alpha = 100
		I.color = color_tint
		overlays += I

/obj/machine/vendor/proc/build_inventory(list/recordlist)
	for(var/I in items)
		var/amount = items[I]

		var/obj/item/temp = I
		var/datum/vending_product/new_record = new
		new_record.name = temp.vendor_name
		new_record.product_path = I
		new_record.amount = amount
		new_record.max_amount = amount
		new_record.price = new_record.get_price(taxless)

		recordlist += new_record
	update_maptext()

/obj/machine/vendor/proc/update_maptext()
	if(!product_records.len)
		return
	var/datum/vending_product/chosen = product_records[items_index]
	maptext = "<div style='color:#A4A4A2; line-height: 0.6; text-align:center; font-size: 80%; font-family: Tiny5;'>[chosen.name]<br>[chosen.price]§</div>"

/obj/machine/vendor/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if(check_pixel_bounds(_x, _y, 30, 36, 24, 30))
		flick_overlay_view(image(src.icon, src, "confirm"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)
	else if(check_pixel_bounds(_x, _y, 22, 26, 24, 30))
		flick_overlay_view(image(src.icon, src, "left"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		if(items_index > 1 && product_records.len)
			items_index--
	else if(check_pixel_bounds(_x, _y, 40, 44, 24, 30))
		flick_overlay_view(image(src.icon, src, "right"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		if(items_index >= 1 && items_index < product_records.len)
			items_index++
	update_maptext()

/obj/machine/vendor/wall
	density = FALSE
	icon_state = "vend_wall"

/obj/machine/vendor/medic
	name = "WENDR-MEDMED X36"
	desc = "Most commonly used for use in medical areas. Features an expansive refridgerated sterile storage to minimize change of infection when using stored products."
	overlay_icon = "medmed"
	color_tint = "#bde9ff"

	items = list(/obj/item/bandage = 20, /obj/item/splint = 15, /obj/item/vitamins = 10, /obj/item/magnesium = 10)

#undef NO_TAXES
#undef YES_TAXES
#undef GAMBLE_A_TRON