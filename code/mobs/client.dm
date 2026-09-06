/client
	var/xp = 6 // saves
	var/datum/role/previously_played // saves too. reset when you successfully escape (do not set when success escape)

	var/tx
	var/px
	var/ty
	var/py

/client/New()
	. = ..()
	track_mouse(TRUE, )

/client/MouseUpdate(tx, px, ty, py)
	src.tx = tx
	src.px = px
	src.ty = ty
	src.py = py

/client/proc/mouse_turf()
	if(!mob || !tx || !ty)
		return

	var/view_text = "[view]"
	var/view_separator = findtext(view_text, "x")
	var/view_width = view_separator ? text2num(copytext(view_text, 1, view_separator)) : text2num(view_text)
	var/view_height = view_separator ? text2num(copytext(view_text, view_separator + 1)) : view_width
	var/center_x = round((view_width + 1) / 2)
	var/center_y = round((view_height + 1) / 2)

	return locate(mob.x + tx - center_x, mob.y + ty - center_y, mob.z)

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

/client/verb/test()
	src << "<span class='hfade'>Oh no...</span>"

/client/verb/tune_radio()
    var/stream_url = "https://stream.sepia.sk:8000/impuls128.mp3"
    var/html = {"<html><body style="margin:0;background:#111">
    <audio id="p" autoplay controls src="[stream_url]"></audio>
    <script>document.getElementById('p').play().catch(function(){});</script>
    </body></html>"}
    src << browse(html, "window=radio;size=320x60")