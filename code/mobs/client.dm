/client
	var/xp = 6 // saves
	var/datum/role/previously_played // saves too. reset when you successfully escape (do not set when success escape)

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
		new fuck(get_turf(mob))
		usr << "Your wish is my command."

/mob/human/verb/trigger_skill_roll(fuck as text)
    SkillRoll(fuck)

/client/verb/tune_radio()
    var/stream_url = "https://stream.sepia.sk:8000/impuls128.mp3"
    var/html = {"<html><body style="margin:0;background:#111">
    <audio id="p" autoplay controls src="[stream_url]"></audio>
    <script>document.getElementById('p').play().catch(function(){});</script>
    </body></html>"}
    src << browse(html, "window=radio;size=320x60")