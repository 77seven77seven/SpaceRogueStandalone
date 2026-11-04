#define STOCKMASTER_WINDOW "STOCKMASTER-vLUKE"
#define CATALOG_REFRESH_INTERVAL (5 MINUTES)
#define TELEPORT_CHARGE_TIME 16.72

/obj/machine
	var/broken = FALSE

/obj/machine/terminal
	icon = 'icons/obj/terminals/terminals.dmi'

/obj/machine/proc/wrench_interact(mob/human/user)
	if(!broken)
		user.chat_info("It appears to be working.")
		return TRUE

	fix()
	if(user.mind && istype(user.mind.current_job, /datum/role/technician))
		user.mind.performance_paycheck += 20
		if(prob(60))
			user.AddRewardPip()
	playsound(get_turf(src), 'sound/effects/obj/wrench.ogg', 75)
	return TRUE

/obj/machine/proc/fix()
	broken = FALSE

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

/// One vendor on the STOCKMASTER network. To add a supplier, subtype this and list the new type
/// in the terminal's supplier_types.
/datum/technician_supplier
	var/name = "SUPPLIER"

	/// Restock cartridges listed on every refresh. Listed as-is, so they don't need to be buy_rollable.
	var/list/restock_paths = list(
		/obj/item/restock_package/medic,
		/obj/item/restock_package/food,
		/obj/item/restock_package/merc,
		/obj/item/restock_package/planta
	)
	var/restock_price_min = 15
	var/restock_price_max = 35

	/// Extra goods sold on top of the cartridges. Each refresh lists up to extra_count of them, picked at random.
	/// Exact item paths, used as-is: no subtypes and no buy_rollable filter.
	var/list/extra_items = list()
	/// Roots whose buyable subtypes may be offered as extras. A subtype must be buy_rollable, not junk,
	/// and not named plain "item". The roots themselves are not offered; put those in extra_items.
	var/list/extra_roots = list()
	var/extra_count = 3

	/// Extras cost their vendor_price (or a random 5-40 if they have none) times price_mult, give or take price_jitter.
	var/price_mult = 1
	var/price_jitter = 2

	var/min_stock = 1
	var/max_stock = 4
	var/min_delivery = 3 SECONDS
	var/max_delivery = 60 SECONDS

	/// Whether customers can pay refresh_cost to re-roll this supplier's catalog on demand.
	var/refreshable = FALSE
	var/refresh_cost = 5

	/// Extra pools by supplier type, built on first use so subtypesof() only runs once per supplier type.
	var/static/list/extra_pool_cache = list()

/// Every extra this supplier may offer.
/datum/technician_supplier/proc/get_extra_pool()
	var/list/pool = extra_pool_cache[type]
	if(!isnull(pool))
		return pool

	pool = list()
	pool |= extra_items
	for(var/root in extra_roots)
		for(var/item_path in subtypesof(root))
			var/obj/item/item_type = item_path
			if(!initial(item_type.buy_rollable) || initial(item_type.junk) || initial(item_type.name) == "item")
				continue
			pool |= item_path

	extra_pool_cache[type] = pool
	return pool

/datum/technician_supplier/proc/roll_extra_price(item_path)
	var/obj/item/item_type = item_path
	var/base_price = initial(item_type.vendor_price) > 0 ? initial(item_type.vendor_price) : rand(5, 40)
	return max(1, round(base_price * price_mult) + rand(-price_jitter, price_jitter))

/datum/technician_supplier/masterline_cinder
	name = "MASTERLINE CINDER"
	extra_roots = list(/obj/item/medical/pills, /obj/item/medical/injector)

/datum/technician_supplier/seramorris
	name = "SERAMORRIS"
	// No extras yet. Add some with extra_roots = list(/obj/item/...) and/or extra_items = list(/obj/item/...)

/datum/technician_supplier/aufsithestine
	name = "AUFSITHESTINE"
	// No extras yet. Add some with extra_roots = list(/obj/item/...) and/or extra_items = list(/obj/item/...)

/datum/technician_supplier/chez_mainline
	name = "CHEZ GROUP MAINLINE CARGO"
	extra_items = list(/obj/item/melee/wrench)

/datum/technician_supplier/unauthorized
	name = "UNAUTHORIZED"
	restock_paths = list()
	extra_roots = list(/obj/item)
	extra_count = 6
	price_jitter = 10
	refreshable = TRUE
	refresh_cost = 5

/obj/machine/terminal/technician
	name = "STOCKMASTER-vLUKE"
	desc = "A supplier terminal for ordering vending cartridges and other goods."
	desc_expansive_extra_skill = TECH
	desc_expansive = "One of the few computing-machines on-board this station that CHEZ made themselves. Probably owed to the fact that CHEZ prides themselves on their logistics."

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "laptop"

	var/obj/machine/telepad/linked_telepad

	/// The suppliers this terminal talks to, in tab order. Instanced into suppliers on Initialize.
	var/list/supplier_types = list(
		/datum/technician_supplier/masterline_cinder,
		/datum/technician_supplier/seramorris,
		/datum/technician_supplier/aufsithestine,
		/datum/technician_supplier/chez_mainline,
		/datum/technician_supplier/unauthorized
	)
	var/list/suppliers = list()
	/// Current catalog per supplier: supplier datum -> (item code -> /datum/technician_order).
	var/list/supplier_catalogs = list()
	var/next_catalog_refresh = 0

	// Bumped every time any catalog is regenerated. Order links carry the version they were
	// rendered with, so a click on a stale page can't buy whatever now has that item code.
	var/catalog_version = 1

	var/atom/movable/whiteout

/obj/machine/terminal/technician/Initialize()
	. = ..()
	get_linked_telepad()

	for(var/supplier_type in supplier_types)
		suppliers += new supplier_type

	whiteout = new(src)
	whiteout.icon = src.icon
	whiteout.icon_state = "computer-whiteout"
	whiteout.mouse_opacity = 0
	whiteout.layer = layer + 0.01
	whiteout.alpha = 0

	vis_contents += whiteout

/obj/machine/terminal/technician/Destroy()
	for(var/supplier in supplier_catalogs.Copy())
		clear_catalog(supplier)
	supplier_catalogs = null
	for(var/supplier in suppliers)
		qdel(supplier)
	suppliers = null
	linked_telepad = null
	if(whiteout)
		vis_contents -= whiteout
		qdel(whiteout)
		whiteout = null
	return ..()

/// Returns the telepad this terminal delivers to, re-linking to the nearest one if the old one is gone.
/obj/machine/terminal/technician/proc/get_linked_telepad()
	if(!QDELETED(linked_telepad))
		return linked_telepad
	linked_telepad = null
	for(var/obj/machine/telepad/pad in range(6, get_turf(src)))
		if(!linked_telepad || get_dist(src, pad) < get_dist(src, linked_telepad))
			linked_telepad = pad
	return linked_telepad

/obj/machine/terminal/technician/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	if(istype(held_item, /obj/item/melee/wrench))
		return
	if(user.SkillRoll(TECH))
		open_terminal(user)

/obj/machine/terminal/technician/Topic(href, href_list)
	. = ..()
	if(!istype(usr, /mob/human))
		return
	var/mob/human/user = usr
	if(!user.client)
		return

	if(href_list["close_terminal"])
		user << browse(null, "window=[STOCKMASTER_WINDOW]")
		user.client.open_popups -= STOCKMASTER_WINDOW
		return

	// Adjacent is checked first so clicking from across the room doesn't burn a skill roll.
	if(!user.mind || !Adjacent(user) || !user.SkillRoll(TECH, FALSE, -1))
		return

	animate(whiteout, time = 0.5, alpha = 255)
	animate(alpha = 0, time = 5)

	if(world.time >= next_catalog_refresh)
		refresh_catalogs()

	var/supplier_index = get_supplier_index(href_list["supplier"])
	var/datum/technician_supplier/supplier = suppliers[supplier_index]

	if(href_list["action"] == "refresh")
		if(supplier.refreshable && user.AttemptTransaction(supplier.refresh_cost))
			refresh_supplier(supplier)
	else if(href_list["order"])
		place_order(user, supplier, href_list["order"], href_list["version"])

	open_terminal(user, supplier_index)

/// Turns the raw "supplier" href value into a valid index into suppliers (defaults to 1).
/obj/machine/terminal/technician/proc/get_supplier_index(raw_index)
	return clamp(round(text2num(raw_index)), 1, suppliers.len)

/obj/machine/terminal/technician/proc/place_order(mob/human/user, datum/technician_supplier/supplier, order_code, order_version)
	var/obj/machine/telepad/pad = get_linked_telepad()
	if(!pad)
		return // open_terminal() tells the user about the missing telepad

	if(text2num(order_version) != catalog_version)
		user.chat_info("The catalog changed while you were reading it. Check the new listing.", "bad")
		return

	var/list/catalog = supplier_catalogs[supplier]
	var/datum/technician_order/order
	if(catalog)
		order = catalog[order_code]
	if(!order || order.stock <= 0)
		user.chat_info("Huh... That's strange.", "bad")
		return

	// Reserve the stock before taking payment, in case AttemptTransaction can sleep.
	order.stock--
	if(!user.AttemptTransaction(order.price))
		order.stock++
		return

	addtimer(CALLBACK(pad, TYPE_PROC_REF(/obj/machine/telepad, deliver_order), order.item_path, user), order.delivery_time)
	AnimatedSpeech("ORDER ACCEPTED. DELIVER IN: [max(1, round(order.delivery_time / 10))] SECONDS.")

/obj/machine/terminal/technician/proc/open_terminal(mob/human/user, supplier_index = 1)
	if(!user.mind)
		return
	if(!get_linked_telepad())
		user.chat_info("The STOCKMASTER-vLUKE cannot reach a delivery telepad.", "bad")
		return
	if(world.time >= next_catalog_refresh)
		refresh_catalogs()
	supplier_index = clamp(supplier_index, 1, suppliers.len)
	var/datum/popup/terminal/popup = new(user, STOCKMASTER_WINDOW, STOCKMASTER_WINDOW, 1080, 720, src)
	popup.set_content(get_terminal_content(supplier_index))
	playsound(get_turf(src), 'sound/effects/obj/machine.ogg', vol = 75)
	popup.open()

/obj/machine/terminal/technician/proc/get_terminal_content(supplier_index)
	var/datum/technician_supplier/supplier = suppliers[supplier_index]
	var/list/catalog = supplier_catalogs[supplier] || list()
	var/content = {"<div id="terminal-window">
	<div><a href='byond://?src=[REF(src)];close_terminal=1'>>EXIT</a></div><br>
	><b>STOCKMASTER-vLUKE — CHEZ LOGISTICS, SUPPLIER NETWORK [pick(":)",">:)",":D","≽^•⩊•^≼","(˵◝ ⩊  ◜˵マ")]</b><br>
	>TIME: <b>[time2text(world.realtime, "mm:ss")]</b><br>
	>TELELINK?: <b>[get_linked_telepad() ? "SUCCESS" : "ERR 695"]</b><br><br>
	"}

	for(var/i in 1 to suppliers.len)
		var/datum/technician_supplier/tab_supplier = suppliers[i]
		if(i == supplier_index)
			content += ">[uppertext(tab_supplier.name)] &nbsp; "
		else
			content += "<a href='byond://?src=[REF(src)];supplier=[i]'>>[uppertext(tab_supplier.name)]</a> &nbsp; "
	content += "<br><br>>== AVAILABLE STOCK: <b>[uppertext(supplier.name)]</b> ==<br>"

	if(supplier.refreshable)
		content += ">XXX | NEW STUFF | [supplier.refresh_cost]§ <a href='byond://?src=[REF(src)];action=refresh;supplier=[supplier_index]'>>ORDER</a><br>"
	content += "<br>"
	for(var/code in catalog)
		var/datum/technician_order/order = catalog[code]
		content += ">[order.code] | [html_encode(order.item_name)] | [order.price]§ | STOCK: [order.stock] | ETA: [max(1, round(order.delivery_time / 10))] SEC "
		if(order.stock > 0)
			content += "<a href='byond://?src=[REF(src)];order=[order.code];supplier=[supplier_index];version=[catalog_version]'>>ORDER</a>"
		else
			content += "| SOLD OUT"
		content += "<br>"

	content += {"<br>>CATALOGS REFRESH PERIODICALLY.<br>
	>SELECT AN ITEM CODE TO PLACE YOUR ORDER.<br>
	</div><div class="scanlines"></div>"}
	return content

/obj/machine/terminal/technician/proc/refresh_catalogs()
	for(var/supplier in suppliers)
		refresh_supplier(supplier)
	next_catalog_refresh = world.time + CATALOG_REFRESH_INTERVAL

/obj/machine/terminal/technician/proc/clear_catalog(datum/technician_supplier/supplier)
	var/list/old_catalog = supplier_catalogs[supplier]
	for(var/code in old_catalog)
		qdel(old_catalog[code])
	supplier_catalogs -= supplier

/// Rebuilds one supplier's catalog: all of its restock cartridges, then up to extra_count random extras.
/obj/machine/terminal/technician/proc/refresh_supplier(datum/technician_supplier/supplier)
	clear_catalog(supplier)
	catalog_version++
	var/list/catalog = list()

	for(var/item_path in supplier.restock_paths)
		add_catalog_order(catalog, item_path, rand(supplier.restock_price_min, supplier.restock_price_max), rand(supplier.min_stock, supplier.max_stock), rand(supplier.min_delivery, supplier.max_delivery))

	// A cartridge is never also listed as an extra.
	var/list/candidates = supplier.get_extra_pool().Copy()
	candidates -= supplier.restock_paths
	var/extras_listed = 0
	while(candidates.len && extras_listed < supplier.extra_count)
		var/item_path = pick(candidates)
		candidates -= item_path
		extras_listed++
		add_catalog_order(catalog, item_path, supplier.roll_extra_price(item_path), rand(supplier.min_stock, supplier.max_stock), rand(supplier.min_delivery, supplier.max_delivery))

	supplier_catalogs[supplier] = catalog

/// The name shown in the catalog for an item type. Medicine uses its med_name, everything else its (space-stripped) name.
/obj/machine/terminal/technician/proc/get_catalog_name(item_path)
	var/med_name
	if(ispath(item_path, /obj/item/medical/pills))
		var/obj/item/medical/pills/pill_type = item_path
		med_name = initial(pill_type.med_name)
	else if(ispath(item_path, /obj/item/medical/injector))
		var/obj/item/medical/injector/injector_type = item_path
		med_name = initial(injector_type.med_name)
	if(med_name)
		return uppertext(med_name)

	var/obj/item/item_type = item_path
	return uppertext(replacetext(initial(item_type.name), " ", ""))

/obj/machine/terminal/technician/proc/add_catalog_order(list/catalog, item_path, price, stock, delivery_time)
	var/code = "[rand(100, 999)]"
	while(catalog[code])
		code = "[rand(100, 999)]"

	var/datum/technician_order/order = new
	order.code = code
	order.item_path = item_path
	order.item_name = get_catalog_name(item_path)
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

	// Only claim terminals that don't already have a pad, so we don't steal links from a nearer one.
	for(var/obj/machine/terminal/technician/terminal in range(6, get_turf(src)))
		if(!terminal.linked_telepad)
			terminal.linked_telepad = src

/obj/machine/telepad/Destroy()
	if(whiteout)
		vis_contents -= whiteout
		qdel(whiteout)
		whiteout = null
	return ..()

/obj/machine/telepad/proc/deliver_order(item_path, mob/human/ordered_by)
	var/turf/pad_turf = get_turf(src)
	if(!pad_turf)
		return
	playsound(pad_turf, 'sound/effects/obj/tele.ogg', vol = 75)
	animate(whiteout, time = TELEPORT_CHARGE_TIME, alpha = 255)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/machine/telepad, finish_delivery), item_path), TELEPORT_CHARGE_TIME)

/obj/machine/telepad/proc/finish_delivery(item_path)
	if(QDELETED(src))
		return
	var/turf/pad_turf = get_turf(src)
	if(!pad_turf)
		return

	animate(whiteout, time = 2, alpha = 0)

	// The bloom is only cosmetic, so a missing filter must never eat a paid-for order.
	if(length(whiteout.filters))
		var/bloom = whiteout.filters[1]
		animate(bloom, time = 0.1, size = 4)
		animate(time = TELEPORT_CHARGE_TIME, size = 0)
	else
		world.log << "teleport filters: FILTER MISSING!!"

	var/obj/item/delivery = new item_path(pad_turf)
	delivery.update_transform()
