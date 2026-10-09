/obj/machine/tickets
	name = "TIKETS"
	desc = "WENDR-type vz. 71. A popular choice in the automatic selling of public transport permits. You determine your destination on board, no need for pesky menus! ...At least here."
	desc_expansive = "You are well versed! The ticket price fluctuates with PKD Transport stock price. You understand it is mostly around 100§ and 200§ most of the time."
	desc_expansive_extra_skill = TECH

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "ticketmachine"

	density = TRUE
	opacity = FALSE

	var/ticket_amt = 20

	var/atom/movable/maptext_holder

/obj/machine/tickets/Initialize()
	. = ..()
	shuttle.ticket_machine = src

	maptext_holder = new(src)
	maptext_holder.maptext_width = 40
	maptext_holder.maptext_height = 48
	maptext_holder.maptext_y = 32
	maptext_holder.maptext_x = 13

	maptext_holder.layer = src.layer
	maptext_holder.plane = src.plane

	vis_contents += maptext_holder

	update()

/obj/machine/tickets/proc/update()
	maptext_holder.maptext = "<div style='color:#A4A4A2; line-height: 0.6; text-align:center; font-size: 80%; font-family: Tiny5;'>STK: [ticket_amt]<br>[shuttle.ticket_price]§</div>"

/obj/machine/tickets/interact(mob/human/user, obj/item/held_item, params)
	. = ..()
	var/_x = text2num(params2list(params)["icon-x"])
	var/_y = text2num(params2list(params)["icon-y"])

	if(check_pixel_bounds(_x, _y, 30, 36, 24, 30))
		flick_overlay_view(image(src.icon, src, "confirm"), src, 2)
		playsound(get_turf(src), 'sound/effects/pda/button.ogg', vol = 75)

		if(ticket_amt <= 0 || !user.AttemptTransaction(shuttle.ticket_price))
			playsound(get_turf(src), 'sound/effects/pda/scanner0.ogg', vol = 75)
			animate(maptext_holder, 0.5, color = "#ff0000")
			animate(color = "#ffffff", time = 5)
		else
			ticket_amt--
			update()
			
			var/obj/item/new_item = new(src)
			playsound(get_turf(src), 'sound/effects/obj/machine_vend.ogg', vol = 75)
			sleep(0.331 SECONDS)
			new_item.loc = get_turf(src)
			new_item.update_transform()