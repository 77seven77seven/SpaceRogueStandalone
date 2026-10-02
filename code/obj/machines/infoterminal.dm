/obj/machine/info
	name = "infoterminal"
	desc = "For all the information you could ever need. Now with a display board."

	maptext_height = 64
	maptext_width = 64

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "infoscreen"

/obj/machine/info/interact(mob/user, obj/item/held_item, params)
	. = ..()
	var/datum/popup/terminal/popup = new(user, "infoterminal", "Infoterminal")
	popup.set_content(
	{"

	<div id="terminal-window">

	OH FUCK
	
	</div>
	<div class="scanlines"></div>
	
	"}
	)
	popup.open()