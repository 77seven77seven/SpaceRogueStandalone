var/global/list/css_file_cache = list('interface/terminal.css')

/client
	var/list/open_popups = list()

/datum/popup
	var/mob/user
	var/title
	var/window_id // window_id is used as the window name for browse and onclose
	var/width = 0
	var/height = 0
	var/atom/ref = null
	var/window_options = "can_close=1;can_minimize=0;can_maximize=0;can_resize=1;titlebar=0;" // window option is set using window_id
	var/stylesheets[0]
	var/scripts[0]
	var/title_image
	var/head_elements
	var/body_elements
	var/head_content = ""
	var/content = ""
	var/no_close_movement = FALSE

	var/seen_enough = TRUE

	var/default_stylesheet

/datum/popup/terminal
	default_stylesheet = 'interface/terminal.css'
	seen_enough = FALSE

/datum/popup/noclose
	no_close_movement = TRUE

/datum/popup/New(nuser, nwindow_id, ntitle = 0, nwidth = 0, nheight = 0, atom/nref = null)
	if(!nuser)
		return
	user = nuser
	window_id = nwindow_id
	if(!no_close_movement)
		if(ismob(nuser))
			if(user.client)
				user.client.open_popups |= window_id
		else
			var/client/C = user
			C.open_popups |= window_id
	if (ntitle)
		title = format_text(ntitle)
	if (nwidth)
		width = nwidth
	if (nheight)
		height = nheight
	if (nref)
		ref = nref

	if(default_stylesheet)
		add_stylesheet("common", default_stylesheet)

/datum/popup/proc/add_head_content(nhead_content)
	head_content = nhead_content

/datum/popup/proc/set_window_options(nwindow_options)
	window_options = nwindow_options

/datum/popup/proc/set_title_image(ntitle_image)
	title_image = ntitle_image

/datum/popup/proc/add_stylesheet(name, file)
	var/asset_name = "[name].css"

	stylesheets[asset_name] = file

/datum/popup/proc/set_content(ncontent)
	content = ncontent

/datum/popup/proc/add_content(ncontent)
	content += ncontent
	
//" This is here because else the rest of the file looks like a string in notepad++.
/datum/popup/proc/get_footer()
	return {"
			</div>
		</div>
	</body>
</html>"}

/datum/popup/proc/get_header()
	var/file
	for (file in stylesheets)
		head_content += "<link rel='stylesheet' type='text/css' href='[file]'>"
		
	return {"<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<head>
		[head_content]
	</head>
	<body scroll=auto>
		[seen_enough ? "<div style='text-align:right'><a href='byond://?src=[REF(user)];close=[window_id]'>I've seen enough.</a></div>" : null]
	"}

/datum/popup/proc/get_content()
	return {"
	[get_header()]
	[content]
	[get_footer()]
	"}

/datum/popup/proc/open(use_onclose = TRUE)
	if(isnull(window_id))	//null check because this can potentially nuke goonchat
		CRASH("Browser [title] tried to open with a null ID")
		return
	var/window_size = ""
	if (width && height)
		window_size = "size=[width]x[height];"
	for (var/stylesheet in stylesheets)
		user << browse_rsc(stylesheets[stylesheet], stylesheet)
	user << browse(get_content(), "window=[window_id];[window_size][window_options]")
	if (use_onclose)
		setup_onclose()

/datum/popup/proc/setup_onclose()
	set waitfor = 0 //winexists sleeps, so we don't need to.
	for (var/i in 1 to 10)
		if (user && winexists(user, window_id))
			onclose(user, window_id, ref)
			break

/datum/popup/proc/close()
	if(!isnull(window_id))//null check because this can potentially nuke goonchat, if I ever decide to add it
		user << browse(null, "window=[window_id]")
		var/client/C = user
		if(ismob(user) && user.client)
			C = user.client
		if(C && C.open_popups)
			C.open_popups -= window_id
	else
		CRASH("Browser [title] tried to close with a null ID")


// Registers the on-close verb for a browse window (client/verb/.windowclose)
// this will be called when the close-button of a window is pressed.
//
// This is usually only needed for devices that regularly update the browse window,
// e.g. canisters, timers, etc.
//
// windowid should be the specified window name
// e.g. code is	: user << browse(text, "window=fred")
// then use 	: onclose(user, "fred")
//
// Optionally, specify the "ref" parameter as the controlled atom (usually src)
// to pass a "close=1" parameter to the atom's Topic() proc for special handling.
// Otherwise, the user mob's machine var will be reset directly.
//
/proc/onclose(mob/user, windowid, atom/ref=null)
	if(!user.client)
		return
	var/param = "null"
	if(ref)
		param = "[REF(ref)]"

	winset(user, windowid, "on-close=\".windowclose [param]\"")

// the on-close client verb
// called when a browser popup window is closed after registering with proc/onclose()
// if a valid atom reference is supplied, call the atom's Topic() with "close=1"
// otherwise, just reset the client mob's machine var.
//
/client/verb/windowclose(atomref as text)
	set hidden = 1						// hide this verb from the user's panel
	set name = ".windowclose"			// no autocomplete on cmd line

	if(atomref!="null")				// if passed a real atomref
		var/hsrc = locate(atomref)	// find the reffed atom
		var/href = "close=1"
		if(hsrc)
			usr = src.mob
			src.Topic(href, params2list(href), hsrc)	// this will direct to the atom's
			return										// Topic() proc via client.Topic()