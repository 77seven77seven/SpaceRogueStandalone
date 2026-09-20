/obj/deco
	icon = 'icons/obj/deco.dmi'
	opacity = FALSE
	density = FALSE

/obj/deco/plant
	name = "plant"
	desc = "What's wrong honey? Something not to your liking?"
	icon_state = "plant"

/obj/deco/plant/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,4)]"
	desc = pick("What's wrong honey? Something not to your liking?","A genus of Tilia.","Tilia industria.","Smell the ashes.","Unsurprisingly, common plants don't thrive on space stations.","Blacker than a black hole sun.")

/obj/deco/poster
	name = "poster"
	icon_state = "poster"

/obj/deco/poster/Initialize()
	. = ..()
	icon_state = "[initial(icon_state)]_[pick("un","cz","cz2","mountain","chez")]"