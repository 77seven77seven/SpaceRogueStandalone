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
	var/datum/popup/terminal/popup = new(user, "infoterminal", "Infoterminal", 640, 500)
	playsound(get_turf(src), 'sound/effects/obj/machine.ogg', vol = 75)
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
	>LEGAL PSYCHOACTIVES: <b>[station.legality_drugs ? " LEGAL" : " ILLEGAL"]</b><br>
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

/obj/machine/infoboard
	name = "infoboard"
	desc = "A bigger version of an infoterminal. This one seems to be linked to a newsfeed of sorts."
	desc_expansive = "A keepsake of any self-respecting space station. I'd just be repeating myself for the infoterminal knowledge. Look at that, if you want. I'm tired."

	icon = 'icons/obj/terminals/terminals_128x64.dmi'
	icon_state = "boardscreen"

	var/atom/movable/maptext_holder

	var/random_headlines = TRUE
	var/list/headlines = list(
		"WELCOME ABOARD - PLEASE ENJOY YOUR STAY.",
		"CHEZ GROUP PROVIDES SAFETY FROM ROGUESPACE.",
		"STOWAWAYS ARE ADVISED TO SEEK EMPLOYMENT.",
		"WORK IS A GREAT WAY TO PURIFY THE SOUL.",
		"CHEZ UP 12.4%",
		"TRANSIT ROUTE TO 'LASTRON' CLOSED FOR MAINTENANCE",
		"DO YOU FEAR THE LIGHTS OF GOD? OPEN UP NOW INSIDE!",
		"GWAREKDROPPER, OUT NOW ON PLAYBOX 7! 50% LAUNCH DISCOUNT!",
		"'TO CATCH A NIGHTCREEPER' SEASON 37 GREENLIT FOR PLASVID.",
		"COUNTER-CULTURAL ACTIVITY NOW DEEMED LEGAL BY UNITED NATIONS COURT",
		"REMEMBER! THE UNITED NATIONS CORPORATE MORALITY CONDUCT HAS YOUR BACK!",
		"WORKERS REJOICE! UNITED NATIONS CORPORATE MORALITY ACT PUT INTO ACTION. NOW ENFORCED.",
		"ENFORCERS! ENFORCERS! HEAR MY PRAYER!",
		"HOW DOES IT FEEL TO BE REAL?",
		"WE ARE NOT HERE YET, THOUGH. NOT YET. NOT UNFAIR!",
		"SHOULD WE BE AFRAID OF THE GREEN MEN IN THE SKY? OF COURSE NOT! MORE AT SEVEN.",
		"BACKWATER OCEAN WORLD PLANET NARROWLY AVOIDS NUCLEAR HOLOCAUST. SHOULD CORPORATIONS BE HELD TO BLAME?",
		"GANYMEDEAN CIVIL WAR STILL ONGOING. DEATHS REACH TENS OF THOUSANDS. SHOULD THE UN INTERVENE?",
		"GANYMEDEAN CIVIL WAR STILL ONGOING. WILL THE FIGHTING REACH GAIAN TERRITORIES?",
		"GAIAN TRASH BELT TO BE CLEANED UP BY 2149, UN REPRESENTATIVE SAYS.",
		"UN PERFORMATIVE DISPLAY OF EMOTION PROHIBITION ACT TO BE REPEALLED BY 2171, UN REPRESENTATIVE SAYS.",
		"FRINGE SECTORS AND ROGUE SPACE. SAFE ENOUGH FOR HUMAN COLONIZATION?",
		"ROGUESTATIONS ARE IN 'LEGAL GRAY ZONE' SAYS UN REPRESENTATIVE.",
		"GAIAN PLANETARY NATURE RESERVE ASTOUNDING SUCCESS. PILGRIMAGES SHOULD RESUME BY END OF MONTH.",
		"ATHEISM ON ALL-TIME LOW. SHOULD HUMANITY BE CONCERNED?",
		"DO NOT BOTHER WITH THE FACT THAT THE STARS PULSE RED.",
		"ECUMENICAL AVERAGE LIFE EXPECTANCY AT ALL TIME HIGH OF 132.8 GAIAN YEARS.",
		"EXPERTS SAY THAT DUE TO STRIDES IN MEDICAL TECHNOLOGY, ALZHEIMERS AND OTHER NEURAL DISEASES CAN BE RENDERED EXTINCT OR MINIMIZED TO 0.8% OF FRINGE CASES.",
		"THE YEAR IS 2147.",
		"THE SUPREME AUTHORITY FROM WHICH ALL OTHER AUTHORITY DERIVES IS ULTIMATE VIOLENCE.",
		"WOULD YOU LAY YOUR LIFE FOR GAIA, THE CRADLE OF ALL OF MANKIND?",
		"178TH ANNIVERSARY OF THE LUNAR DUO-LANDING. SHAKE HANDS WITH YOUR FRIENDS AND FOES JUST LIKE THE FIRST ASTRONAUTS DID!",
		"EXPERTS SAY HUMANITY HAS ENTERED A NEW GOLDEN AGE. 'IT CAN ONLY GO DOWNHILL FROM HERE' SAY CYNICS."
	)
	/// Index of the headline currently on screen.
	var/headline_index = 0
	/// Scroll speed in pixels per second.
	var/scroll_speed = 30
	/// Blank pause (deciseconds) after a headline has fully left the screen.
	var/scroll_pause = 15
	/// Whether the scroll loop is running.
	var/scrolling = FALSE

/obj/machine/infoboard/church
	random_headlines = FALSE
	headlines = list(
		"PRAY.",
		"UNITY.",
		"FOLLOW."
	)
	scroll_pause = 2
	scroll_speed = 50

/obj/machine/infoboard/medicaloid
	headlines = list(
		"PRAY FOR RECOVERY.",
		"TIME TICKS DOWN, BUT YOU WILL STAND UP AND THRIVE!",
		"INJURED? PRESS BUTTON FOR ASSISTANCE!",
		"CATS ARE SCIENTIFICALLY PROVEN TO INCREASE SURVIVORSHIP. THIS INFOBOARD PERIODICALLY SHOWS EMOTICONS OF CATS.",
		"≽^•⩊•^≼",
		"ദ്ദി(• ⩊ •マ",
		"⚞^◕⩊◕^⚟",
		"≽^-⩊-^≼",
		"/ᐠ˵> ˕ <˵マ"
	)

/obj/machine/infoboard/Initialize()
	. = ..()
	maptext_holder = new(src)
	maptext_holder.icon = icon
	maptext_holder.vis_flags = VIS_INHERIT_LAYER | VIS_INHERIT_PLANE | VIS_INHERIT_ID
	maptext_holder.maptext_width = 3024 // big enough to not matter
	maptext_holder.maptext_height = 12
	maptext_holder.maptext_y = 28
	maptext_holder.filters += filter(type = "alpha", icon = icon(icon, "content"))

	vis_contents += maptext_holder

	scroll_headlines()

/obj/machine/infoboard/Destroy()
	scrolling = FALSE
	if(maptext_holder)
		vis_contents -= maptext_holder
		qdel(maptext_holder)
		maptext_holder = null
	return ..()

/// Formats a headline for display on the board.
/obj/machine/infoboard/proc/format_headline(headline)
	return "<span style='font-family: \"Small Fonts\"; font-size: 6px; color:#A4A4A2;'><b>[headline]</b></span>"

/// Loops forever: scrolls one headline right-to-left across the screen, waits until it has
/// fully passed, then moves on to the next one.
/obj/machine/infoboard/proc/scroll_headlines()
	set waitfor = FALSE

	if(scrolling)
		return
	scrolling = TRUE

	while(scrolling && !QDELETED(src))
		if(!length(headlines))
			sleep(50)
			continue

		var/headline
		if(random_headlines)
			headline = pick(headlines)
		else
			headline_index = (headline_index % length(headlines)) + 1
			headline = headlines[headline_index]

		// Measured pixel width of the text. The trailing spaces pad it so the tail fully clears the screen.
		var/text_width = tinyfont_bold.GetWidth("       [headline]", DF_INCLUDE_AC)
		var/start_x = 4 + 112 // just off the right edge
		var/end_x = 4 - text_width               // just off the left edge
		var/travel_time = max(1, round(((start_x - end_x) / scroll_speed) * 10))

		maptext_holder.maptext = format_headline(headline)
		maptext_holder.maptext_x = start_x
		animate(maptext_holder, maptext_x = end_x, time = travel_time, easing = LINEAR_EASING)

		// Wait for the headline to completely pass, plus a short blank gap, then rotate.
		sleep(travel_time + scroll_pause)

	scrolling = FALSE