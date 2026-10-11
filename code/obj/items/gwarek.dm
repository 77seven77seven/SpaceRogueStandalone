/obj/item/gwarek
	name = "gwarek"
	desc = "It's a gwarek."
	desc_expansive = "Oh yes, you know! It's a gwarek."
	icon_state = "gwarek"

	droprot = FALSE

/obj/item/gwarek/Initialize()
	. = ..()
	if(prob(1))
		desc_expansive = "What the heck?! There's \"REPLICA\" written down on the side of this gwarek! This is a scam! A SHAM!"

/obj/item/gwarek/heretic
	icon_state = "gwarek_heretic"
	color = "#8A9774"