/datum/system/radio
	var/list/datum/looping_sound/all_channels = list()
	var/list/datum/looping_sound/default_channels = list() // Publicly available
	var/datum/looping_sound/radio/noise // invalid channel

/datum/system/radio/proc/frequency_to_channel(frequency)
	for(var/datum/looping_sound/radio/R in all_channels)
		if(R.radio_frequency == frequency)
			return R

/datum/system/radio/proc/name_to_channel(name)
	for(var/datum/looping_sound/radio/R in all_channels)
		if(R.radio_station == name)
			return R

/datum/system/radio/setup()
	for(var/station in subtypesof(/datum/looping_sound/radio))
		all_channels += new station(src)
	for(var/datum/looping_sound/radio/R in all_channels)
		if(R.radio_public)
			default_channels += R
		R.Start()

/datum/looping_sound/radio
	radio_filter = TRUE
	range = 5
	shuffle = TRUE
	line_chance = 90

	var/radio_station = null		  // radio station name
	var/radio_frequency = null		  // radio station frequency
	var/radio_public = FALSE

/datum/looping_sound/radio/wow // Wow! signal, 1420.46 megahertz
	radio_station = "1420.46 MegaHurtz"
	radio_frequency = 1419.12 // The irony! Oh, the irony!
	radio_public = TRUE

	tracks = list(
		'sound/music/radio/142046mhz/crystalmatango.ogg' = 2023,
		'sound/music/radio/142046mhz/matangoneverbloom.ogg' = 1930,
		'sound/music/radio/142046mhz/la_vipera.ogg' = 2140,
		'sound/music/radio/142046mhz/tulpa.ogg' = 2430,
		'sound/music/radio/142046mhz/psychic_veteran.ogg' = 2900,
	)
	lines = list(
		'sound/music/radio/142046mhz/dj/dj_best_songs.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_gamble_responsibly.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_shoutout_frouge.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_shoutout_totchke.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_shove_it.ogg' = 200,
		'sound/music/radio/142046mhz/dj/dj_thank_you.ogg' = 200
	)

/datum/looping_sound/radio/flowerbedfm
	radio_station = "Flowerbed FM"
	radio_frequency = 74.4
	radio_public = TRUE

	tracks = list('sound/music/radio/142046mhz/crystalmatango.ogg' = 2023)

/obj/item/deco/radio
	name = "radio"
	icon_state = "radio"
	desc = "Thanks to the ever expanding net of communications artiholes, this thing can receive frequencies faster-than-light! (That is if you consider wormholes to be FTL, that is.)"
	desc_expansive_extra_skill = TECH
	desc_expansive = "Maybe in the future you'll be able to tune this to specific stations. But today? Something tells you that the knobs are too stuck to rotate. Oof."
	droprot = FALSE

	vendor_name = "RDIO"
	vendor_price = 81

	var/datum/looping_sound/radio/tuned_to

/obj/item/deco/radio/use(mob/human/H)
	. = ..()
	var/input = input(H, "Frequency Tuning", name, tuned_to?.radio_frequency) as num|null
	if(input)
		var/datum/looping_sound/radio/inputted = system_radio.frequency_to_channel(input)
		if(inputted)
			tuned_to?.RemoveSource(src)
			tuned_to = inputted
			tuned_to.AddSource(src)
		else
			H.chat_info("Huh, just noise.","bad")

/obj/item/deco/radio/Destroy(force)
	
	return ..()