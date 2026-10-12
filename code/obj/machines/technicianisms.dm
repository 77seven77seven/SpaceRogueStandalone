/obj/machine/technician_terminal
	name = "komp"
	desc = "It's a computer. In more technical terms, a laptop. A thick one. It also has a weird screen."

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "laptop"

	var/obj/machine/telepad/linked_telepad

/obj/machine/telepad
	name = "telepad"
	desc = "Unoriginal name aside, it is pretty handy for the would-be Technician."

	icon = 'icons/obj/terminals/terminals.dmi'
	icon_state = "telepad"

	var/atom/movable/whiteout

/obj/machine/telepad/Initialize()
	. = ..()
	whiteout = new(src)
	whiteout.icon = src.icon
	whiteout.icon_state = "telepad-glow"
	whiteout.mouse_opacity = 0
	whiteout.layer = layer + 0.01

	whiteout.color = "#000000ff"

	vis_contents += whiteout