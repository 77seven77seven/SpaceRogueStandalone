/obj/deco
	icon = 'icons/obj/deco.dmi'
	opacity = FALSE
	density = FALSE

/obj/deco/plant
	name = "plant"
	desc = "What's wrong honey? Something not to your liking?"
	desc_expansive = "A specific species of artificially created a common plant. Most commonly used by space station crew for help with filtering out contaminants in the early stages of space habitation. It is now rendered useless due to advances in modern air recycling. The aesthetic however, stayed."
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