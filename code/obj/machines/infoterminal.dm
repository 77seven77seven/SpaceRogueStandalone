/obj/machine/info
	name = "infoterminal"
	desc = "For all the information you could ever need. Now with a display board."
	desc_expansive = "A keepsake of any self-respecting space station, it is linked internally to a somewhat-live count of internal stores and current station guidelines. The machine was not manufactured by CHEZ, and it is instead being actively rented from Bluline Tech. You can even see it on the screen there."

	maptext_height = 64
	maptext_width = 64

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "infoscreen"

/obj/machine/info/interact(mob/user, obj/item/held_item, params)
	. = ..()
	var/datum/popup/terminal/popup = new(user, "infoterminal", "Infoterminal", 640, 480)
	popup.set_content(
	{"

	<div id="terminal-window">
	
	<div><a href='byond://?src=[REF(user)];close=["infoterminal"]'>>EXIT</a></div><br>
	><b>[pick("DEFEND AND PROTECT!","DEFEND AND SERVE!","BRINGING LIFE TO DEATH!","STAY SAFE, IN ROGUE SPACE!","ENDERA, CLOSING BLACKHOLES SINCE 2121","14400 IS A BEAUTIFUL NUMBER")]</b><br>

	>BLULINE TECH, PROPRI H.WARE, INFOTERMINAL<br>
	>WELCOME TO SPACE, IT'S A DANGEROUS PLACE!<br>
	<br>
	>TIME: <b>[time2text(world.realtime, "mm:ss")]</b><br>
	>TAXES: <b>[station.treasury_tax]%</b><br>
	>LEGAL FIREARMS: <b>[station.legality_guns ? " LEGAL" : " ILLEGAL"]</b><br>
	>LEGAL GAMBLING: <b>[station.legality_gambling ? " LEGAL" : " ILLEGAL"]</b><br>
	<br>
	>==STOCKPILES==<br>
	>OXIDANE (WATER): <b>[station.waters]</b> |<br>
	>M.LICE (MEAL PREPARANTS): <b>[station.mlices]</b> |<br>
	>METALLURGICS (METALS): <b>[station.metals]</b> |<br><br>
	<b>>######<br>
	>#<br>
	># ####<br>
	>#<br>
	>######<br></b>

	</div>
	<div class="scanlines"></div>
	"}
	)
	popup.open()