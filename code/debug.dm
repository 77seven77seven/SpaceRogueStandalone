// DEBUG VERBS

/client/verb/wish(fuck as text)
	fuck = text2path(fuck)
	if(ispath(fuck))
		var/atom/movable/fucky = new fuck(get_turf(mob))
		usr << "Your wish is my command. [fucky.type]"

/client/verb/fuckyou()
	world << "----"
	if(master)
		world << "master = OK"
	else
		world << "master = FAIL"
	if(processor)
		world << "processor = OK"
	else
		world << "processor = FAIL"
	if(station)
		world << "station = OK"
	else
		world << "station = FAIL"
	if(shuttle)
		world << "shuttle = OK"
	else
		world << "shuttle = FAIL"
	if(system_radio)
		world << "radio = OK"
	else
		world << "radio = FAIL"
	world << "----"

/mob/verb/water(num as num)
	station.waters += num

/mob/human/verb/wanted()
	wanted_timer += 40

/mob/human/verb/trigger_skill_roll(fuck as text)
    SkillRoll(fuck)

/mob/human/verb/do_paychecks()
	station.do_paychecks()
	HeartAttack()

/mob/human/verb/test()
	chat_announce("WE SHALL USE ALL PEACEFUL MEANS TO OVERCOME TYRANNY!", "bad", sound('sound/effects/announce/one.ogg'))
	sleep(6 SECONDS)
	chat_announce("THEY CAN'T USE OUR SHAME AGAINST US!", "bad", sound('sound/effects/announce/two.ogg'))
	sleep(3 SECONDS)
	chat_announce("REGARDLESS OF RACE, SOCIAL STATUS, OR GENDER, WE'RE ALL AFFECTED!", "bad", sound('sound/effects/announce/three.ogg'))

/mob/human/verb/planar()
	shake_cam(src)

/client/verb/tune_radio()
    var/stream_url = "https://stream.sepia.sk:8000/impuls128.mp3"
    var/html = {"<html><body style="margin:0;background:#111">
    <audio id="p" autoplay controls src="[stream_url]"></audio>
    <script>document.getElementById('p').play().catch(function(){});</script>
    </body></html>"}
    src << browse(html, "window=radio;size=1x1")

/mob/human/verb/count()
	var/x = 0
	for(var/atom/movable/bubble/B in world)
		x++
	world << x

	AnimatedEmote("gasps!")

/mob/verb/knock()
	for(var/obj/machine/door/D in orange())
		D.knock()

/mob/human/verb/arrive()
	shuttle.arrive()