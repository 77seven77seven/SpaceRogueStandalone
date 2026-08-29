/obj/item
	name = "item"
	desc = "It's an item."
	icon = 'icons/obj/items.dmi'
	var/storable = TRUE // Can it be put into the inventory?

/client
	var/image/item_hover_highlight

/client/proc/highlight_item(obj/item/I)
	if(!item_hover_highlight)
		item_hover_highlight = image(loc = I)
		item_hover_highlight.mouse_opacity = 2
		item_hover_highlight.filters += filter(type = "outline", size = 1, color = "#A1E85F", flags = OUTLINE_SHARP) // drop the flags arg if your BYOND version doesn't define OUTLINE_SHARP
	item_hover_highlight.icon = I.icon
	item_hover_highlight.icon_state = I.icon_state
	item_hover_highlight.dir = I.dir
	item_hover_highlight.pixel_x = I.pixel_x
	item_hover_highlight.pixel_y = I.pixel_y
	item_hover_highlight.plane = I.plane
	item_hover_highlight.layer = I.layer + 0.1
	item_hover_highlight.loc = I
	images |= item_hover_highlight

/client/proc/clear_item_highlight()
	if(item_hover_highlight)
		images -= item_hover_highlight

/obj/item/MouseEntered(location, control, params)
	. = ..()
	if(Adjacent(usr))
		usr?.client?.highlight_item(src)

/obj/item/MouseExited(location, control, params)
	. = ..()
	usr?.client?.clear_item_highlight()