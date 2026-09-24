/client
	preload_rsc = 1
	
	var/xp = 6 // saves
	var/datum/role/previously_played // saves too. reset when you successfully escape (do not set when success escape)

	var/turf/movered
	var/mpx = 0
	var/mpy = 0

	var/sound/droning_sound

/client/New()
	. = ..()
	master.clients += src

/client/Del()
	. = ..()
	master.clients -= src

/client/MouseMove(object, location, control, params)
	. = ..()
	movered = get_turf(location)

	var/list/marams = params2list(params)
	mpx = text2num(marams["icon-x"])
	mpy = text2num(marams["icon-y"])

	//src << "[mpx] [mpy]"

/client/proc/play_droning(music = null, vol = 50)
	if(!music)
		return
	var/sound/combat_music = sound(pick(music), repeat = TRUE, wait = 0, channel = 1017, volume = vol)
	SEND_SOUND(src, combat_music)
	droning_sound = combat_music
	
/client/proc/stop_droning()
	if(!droning_sound)
		return
	var/sound/sound_killer = sound()
	sound_killer.channel = droning_sound.channel
	SEND_SOUND(src, sound_killer)
	droning_sound = null

/client/verb/fuckyou()
	world << "----"
	if(master)
		world << "master = OK"
	if(processor)
		world << "processor = OK"
	if(station)
		world << "station = OK"
	world << "----"

/client/verb/wish(fuck as text)
	fuck = text2path(fuck)
	if(ispath(fuck))
		var/atom/movable/fucky = new fuck(get_turf(mob))
		usr << "Your wish is my command. [fucky.type]"

/mob/human/verb/trigger_skill_roll(fuck as text)
    SkillRoll(fuck)

/client/verb/tune_radio()
    var/stream_url = "https://stream.sepia.sk:8000/impuls128.mp3"
    var/html = {"<html><body style="margin:0;background:#111">
    <audio id="p" autoplay controls src="[stream_url]"></audio>
    <script>document.getElementById('p').play().catch(function(){});</script>
    </body></html>"}
    src << browse(html, "window=radio;size=320x60")