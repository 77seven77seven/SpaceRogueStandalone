/obj/machine
	var/broken = FALSE

/obj/machine/proc/wrench_interact(mob/human/user)
	if(!broken)
		user.chat_info("It appears to be working.")
		return TRUE

	broken = FALSE
	if(user.mind && istype(user.mind.current_job, /datum/role/technician))
		user.mind.performance_paycheck += 20
		if(prob(60))
			user.AddRewardPip()
	playsound(get_turf(src), 'sound/effects/obj/wrench.ogg', 75)
	return TRUE

/obj/item/restock_package
	name = "restock cartridge"
	desc = "A sealed cartridge containing a vending machine's replacement stock."
	icon_state = "generic"
	buy_rollable = FALSE

/obj/item/restock_package/medic
	name = "medical restock cartridge"

/obj/item/restock_package/food
	name = "food restock cartridge"

/obj/item/restock_package/merc
	name = "ammunition restock cartridge"

/obj/item/restock_package/planta
	name = "hydroponics restock cartridge"

/datum/technician_order
	var/code
	var/item_path
	var/item_name
	var/price
	var/stock
	var/delivery_time

/obj/machine/technician_terminal
	name = "STOCKMASTER-vLUKE"
	desc = "A supplier terminal for ordering vending cartridges and other goods."
	desc_expansive_extra_skill = TECH
	desc_expansive = "One of the few computing-machines on-board this station that CHEZ made themselves. Probably owed to the fact that CHEZ prides themselves on their logistics."

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "laptop"

	var/obj/machine/telepad/linked_telepad
	var/list/supplier_names = list("MASTERLINE CINDER", "SERAMORRIS", "AUFSITHESTINE", "CHEZ GROUP MAINLINE CARGO", "UNAUTHORIZED")
	var/list/supplier_catalogs = list()
	var/next_catalog_refresh = 0

	var/atom/movable/whiteout

/obj/machine/technician_terminal/Initialize()
	. = ..()
	for(var/obj/machine/telepad/pad in range(6, get_turf(src)))
		linked_telepad = pad
		break

/obj/machine/technician_terminal/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	if(istype(held_item, /obj/item/melee/wrench))
		return
	if(user.SkillRoll(TECH))
		open_terminal(user)

	whiteout = new(src)
	whiteout.icon = src.icon
	whiteout.icon_state = "computer-whiteout"
	whiteout.mouse_opacity = 0
	whiteout.layer = layer + 0.01
	whiteout.alpha = 0

	vis_contents += whiteout

/obj/machine/technician_terminal/Topic(href, href_list)
	. = ..()
	var/mob/human/user = usr
	if(href_list["close_terminal"])
		user << browse(null, "window=STOCKMASTER-vLUKE")
		user.client.open_popups -= "STOCKMASTER-vLUKE"
		return
	
	if(!user || !user.client || !user.mind || !user.SkillRoll(TECH, FALSE, -1) || !Adjacent(user))
		return

	animate(whiteout, 0.5, alpha = 255)
	animate(alpha = 0, time = 5)

	if(world.time >= next_catalog_refresh)
		refresh_catalogs()

	var/supplier_index = text2num(href_list["supplier"])
	if(supplier_index < 1 || supplier_index > supplier_names.len)
		supplier_index = 1
	var/supplier = supplier_names[supplier_index]

	if(href_list["action"] == "refresh" && supplier == "UNAUTHORIZED")
		if(user.AttemptTransaction(5))
			refresh_supplier(supplier)
	else if(href_list["order"])
		if(!linked_telepad)
			user.chat_info("The STOCKMASTER-vLUKE cannot reach a delivery telepad.", "bad")
			return
		var/list/catalog = supplier_catalogs[supplier]
		var/datum/technician_order/order = catalog[href_list["order"]]
		if(!order || order.stock <= 0)
			user.chat_info("Huh... That's strange.", "bad")
			open_terminal(user, supplier_index)
			return
		if(!user.AttemptTransaction(order.price))
			open_terminal(user, supplier_index)
			return

		order.stock--
		addtimer(CALLBACK(linked_telepad, TYPE_PROC_REF(/obj/machine/telepad, deliver_order), order.item_path, user), order.delivery_time)
		AnimatedSpeech("ORDER ACCEPTED. DELIVER IN: [max(1, round(order.delivery_time / 10))] SECONDS.")

	open_terminal(user, supplier_index)

/obj/machine/technician_terminal/proc/open_terminal(mob/human/user, supplier_index = 1)
	if(!user.mind)
		return
	if(!linked_telepad)
		user.chat_info("The STOCKMASTER-vLUKE cannot reach a delivery telepad.", "bad")
		return
	if(world.time >= next_catalog_refresh)
		refresh_catalogs()
	supplier_index = clamp(supplier_index, 1, supplier_names.len)
	var/datum/popup/terminal/popup = new(user, "STOCKMASTER-vLUKE", "STOCKMASTER-vLUKE", 1080, 720, src)
	popup.set_content(get_terminal_content(supplier_index))
	playsound(get_turf(src), 'sound/effects/obj/machine.ogg', vol = 75)
	popup.open()

/obj/machine/technician_terminal/proc/get_terminal_content(supplier_index)
	var/supplier = supplier_names[supplier_index]
	var/list/catalog = supplier_catalogs[supplier]
	var/content = {"<div id="terminal-window">
	<div><a href='byond://?src=[REF(src)];close_terminal=1'>>EXIT</a></div><br>
	><b>STOCKMASTER-vLUKE — CHEZ LOGISTICS, SUPPLIER NETWORK [pick(":)",">:)",":D","≽^•⩊•^≼","(˵◝ ⩊  ◜˵マ")]</b><br>
	>TIME: <b>[time2text(world.realtime, "mm:ss")]</b><br>
	>TELELINK?: <b>[linked_telepad ? "SUCCESS" : "ERR 695"]</b><br><br>
	"}

	for(var/i in 1 to supplier_names.len)
		var/supplier_name = supplier_names[i]
		if(i == supplier_index)
			content += ">[uppertext(supplier_name)] &nbsp; "
		else
			content += "<a href='byond://?src=[REF(src)];supplier=[i]'>>[uppertext(supplier_name)]</a> &nbsp; "
	content += "<br><br>>== AVAILABLE STOCK: <b>[uppertext(supplier)]</b> ==<br>"

	if(supplier == "UNAUTHORIZED")
		content += ">XXX | NEW STUFF | 5§ <a href='byond://?src=[REF(src)];action=refresh;supplier=[supplier_index]'>>ORDER</a><br>"
	content += "<br>"
	for(var/code in catalog)
		var/datum/technician_order/order = catalog[code]
		content += ">[order.code] | [html_encode(order.item_name)] | [order.price]§ | STOCK: [order.stock] | ETA: [max(1, round(order.delivery_time / 10))] SEC "
		if(order.stock > 0)
			content += "<a href='byond://?src=[REF(src)];order=[order.code];supplier=[supplier_index]'>>ORDER</a>"
		else
			content += "| SOLD OUT"
		content += "<br>"

	content += {"<br>>CATALOGS REFRESH PERIODICALLY.<br>
	>SELECT AN ITEM CODE TO PLACE YOUR ORDER.<br>
	</div><div class="scanlines"></div>"}
	return content

/obj/machine/technician_terminal/proc/refresh_catalogs()
	for(var/supplier in supplier_names)
		var/list/old_catalog = supplier_catalogs[supplier]
		if(old_catalog)
			for(var/code in old_catalog)
				qdel(old_catalog[code])
	supplier_catalogs = list()

	for(var/supplier in supplier_names)
		refresh_supplier(supplier)
	next_catalog_refresh = world.time + 5 MINUTES

/obj/machine/technician_terminal/proc/refresh_supplier(supplier)
	var/list/catalog = list()
	var/list/restock_paths = list(
		/obj/item/restock_package/medic,
		/obj/item/restock_package/food,
		/obj/item/restock_package/merc,
		/obj/item/restock_package/planta
	)

	if(supplier == "UNAUTHORIZED")
		var/list/candidates = subtypesof(/obj/item)
		for(var/item_path in candidates.Copy())
			var/obj/item/item_type = item_path
			if(!item_type.buy_rollable || item_type.junk || item_type.name == "item")
				candidates -= item_path

		while(candidates.len && catalog.len < 6)
			var/item_path = pick(candidates)
			candidates -= item_path
			var/obj/item/item_type = item_path
			var/base_price = item_type.vendor_price > 0 ? item_type.vendor_price : rand(5, 40)
			add_catalog_order(catalog, item_path, uppertext(replacetext(item_type.name, " ", "")), max(1, base_price + rand(-10, 10)), rand(1, 4), rand(3 SECONDS, 60 SECONDS))
	else
		for(var/item_path in restock_paths)
			var/obj/item/item_type = item_path
			add_catalog_order(catalog, item_path, uppertext(replacetext(item_type.name, " ", "")), rand(15, 35), rand(1, 4), rand(3 SECONDS, 60 SECONDS))

	supplier_catalogs[supplier] = catalog

/obj/machine/technician_terminal/proc/add_catalog_order(list/catalog, item_path, item_name, price, stock, delivery_time)
	var/code
	while(TRUE)
		code = "[rand(100, 999)]"
		if(!catalog[code])
			break

	var/datum/technician_order/order = new
	order.code = code
	order.item_path = item_path
	order.item_name = item_name
	order.price = price
	order.stock = stock
	order.delivery_time = delivery_time
	catalog[code] = order

/obj/machine/telepad
	name = "telepad"
	desc = "Unoriginal name aside, it is pretty handy for the would-be Technician."
	desc_expansive_extra_skill = CORP
	desc_expansive = "The inner workings of this is a mystery. Not a mystery, actually, just known by very few. The three people aren't allowed to travel in the same vehicle, be in the same room, or talk to each other in person. Extremely classified. If you knew, you'd be dead."

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "telepad"

	var/atom/movable/whiteout

/obj/machine/telepad/Initialize()
	. = ..()
	whiteout = new(src)
	whiteout.icon = src.icon
	whiteout.icon_state = "telepad-glow"
	whiteout.mouse_opacity = 0
	whiteout.filters += filter(type="bloom", size=3, offset = 0.5, alpha = 220)
	whiteout.alpha = 0

	vis_contents += whiteout

	for(var/obj/machine/technician_terminal/terminal in range(6, get_turf(src)))
		terminal.linked_telepad = src
		break

/obj/machine/telepad/proc/deliver_order(item_path, mob/human/ordered_by)
	if(!get_turf(src))
		return
	playsound(get_turf(src), 'sound/effects/obj/tele.ogg', vol = 75)
	animate(whiteout, time = 16.72, alpha = 255)

	if(!length(whiteout.filters))
		world.log << "teleport filters: FILTER MISSING!!"
		return // filter missing, bail instead of runtime

	spawn(16.72)
		animate(whiteout, time = 2, alpha = 0)

		var/bloom = whiteout.filters[1]
		animate(bloom, time = 0.1, size = 4)
		animate(time = 16.72, size = 0)

		var/obj/item/delivery = new item_path(get_turf(src))
		delivery.update_transform()