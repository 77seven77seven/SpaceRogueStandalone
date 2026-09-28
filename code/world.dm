var/global/datum/system/master/master = new()
var/global/datum/system/processor/processor = new()
var/global/datum/system/station/station = new()
var/global/datum/system/sound/system_sound = new()

var/global/list/landmarks_list = list()
var/global/list/landmarks_start_list = list()

#define WORLD_ICON_SIZE 64
#define PIXEL_MULTIPLIER (WORLD_ICON_SIZE/32)
#define PIXEL_MULTIPLIER_SQUARE (PIXEL_MULTIPLIER*PIXEL_MULTIPLIER)

// Just don't credit me. Do whatever, none of my ideas are copyrighted.
// Feel free to steal my game if you want, but you should probably be creative because being creative is cool.

/world
	name = "Fringe Sector: In Rogue Space"
	fps = 30
	icon_size = WORLD_ICON_SIZE
	view = "13x13"
	movement_mode = PIXEL_MOVEMENT_MODE

	mob = /mob/lobbyman
	turf = /turf/open/space
	area = /area/space

/world/New()
	master.setup()
	processor.setup()
	system_sound.setup()

	station.next_paycheck = world.time + rand(4 MINUTES, 7 MINUTES)
	station.next_day = world.time + 24 MINUTES
	processor.processing += station

	var/datum/D = new /datum/process_tester
	processor.processing += D

/datum/process_tester/Process()
	//world << "hi [world.time]"

/proc/REF(input)
	if(istype(input, /datum))
		var/datum/thing = input
		if(thing.datum_flags & DF_USE_TAG)
			if(!thing.tag)
				thing.datum_flags &= ~DF_USE_TAG
			else
				return "\[[url_encode(thing.tag)]\]"
	return "\ref[input]"

/proc/GetRandomLetter()
    var/alphabet = "abcdefghijklmnopqrstuvwxyz"
    // Pick a random position from 1 to the length of the string
    var/pos = rand(1, length(alphabet))
    // Copy 1 character starting at that random position
    return copytext(alphabet, pos, pos + 1)

/proc/GetRandomLetterUpper()
	return uppertext(GetRandomLetter())

//Returns a string with reserved characters and spaces before the first letter removed
/proc/trim_left(text)
	for (var/i = 1 to length(text))
		if (text2ascii(text, i) > 32)
			return copytext(text, i)
	return ""

//Returns a string with reserved characters and spaces after the last letter removed
/proc/trim_right(text)
	for (var/i = length(text), i > 0, i--)
		if (text2ascii(text, i) > 32)
			return copytext(text, 1, i + 1)

	return ""

//Returns a string with reserved characters and spaces before the first word and after the last word removed.
/proc/trim(text, max_length)
	if(max_length)
		text = copytext(text, 1, max_length)
	return trim_left(trim_right(text))

/atom/proc/InCone(atom/center = usr, dir = NORTH)
	if(get_dist(center, src) == 0 || src == center) return 0
	var/d = get_dir(center, src)
	if(!d || d == dir) return 1
	if(dir & (dir-1))
		return (d & ~dir) ? 0 : 1
	if(!(d & dir)) return 0
	var/dx = abs(x - center.x)
	var/dy = abs(y - center.y)
	if(dx == dy) return 1
	if(dy > dx)
		return (dir & (NORTH|SOUTH)) ? 1 : 0
	return (dir & (EAST|WEST)) ? 1 : 0

/mob/lobbyman/InCone(mob/center = usr, dir = NORTH)
	return

/proc/cone(atom/center = usr, dirs, list/list = oview(center))
	for(var/atom/A in list)
		var/fou
		for(var/D in dirs)
			if(A.InCone(center, D))
				fou = TRUE
				break
		if(!fou)
			list -= A
	return list

proc/find_common_entry(list/list1, list/list2)
    // Overlap will contain all common elements
    var/list/overlap = list1 & list2 
    
    // If the list has entries, return the first one found
    if(overlap && overlap.len)
        return overlap[1] 
        
    return null // No common entry found

/**
 * Picks a random element from a list based on a weighting system.
 * For example, given the following list:
 * A = 6, B = 3, C = 1, D = 0
 * A would have a 60% chance of being picked,
 * B would have a 30% chance of being picked,
 * C would have a 10% chance of being picked,
 * and D would have a 0% chance of being picked.
 * You should only pass integers in.
 */
/proc/pick_weight(list/list_to_pick)
	if(length(list_to_pick) == 0)
		return null

	var/total = 0
	for(var/item in list_to_pick)
		if(!list_to_pick[item])
			list_to_pick[item] = 0
		total += list_to_pick[item]

	total = rand(1, total)
	for(var/item in list_to_pick)
		var/item_weight = list_to_pick[item]
		if(item_weight == 0)
			continue

		total -= item_weight
		if(total <= 0)
			return item

	return null

/**
 * Like pick_weight, but allowing for nested lists.
 *
 * For example, given the following list:
 * list(A = 1, list(B = 1, C = 1))
 * A would have a 50% chance of being picked,
 * and list(B, C) would have a 50% chance of being picked.
 * If list(B, C) was picked, B and C would then each have a 50% chance of being picked.
 * So the final probabilities would be 50% for A, 25% for B, and 25% for C.
 *
 * Weights should be integers. Entries without weights are assigned weight 1 (so unweighted lists can be used as well)
 */
/proc/pick_weight_recursive(list/list_to_pick)
	var/result = pick_weight(fill_with_ones(list_to_pick))
	while(islist(result))
		result = pick_weight(fill_with_ones(result))
	return result

/**
 * Given a list, return a copy where values without defined weights are given weight 1.
 * For example, fill_with_ones(list(A, B=2, C)) = list(A=1, B=2, C=1)
 * Useful for weighted random choices (loot tables, syllables in languages, etc.)
 */
/proc/fill_with_ones(list/list_to_pad)
	if (!islist(list_to_pad))
		return list_to_pad

	var/list/final_list = list()

	for (var/key in list_to_pad)
		if (list_to_pad[key])
			final_list[key] = list_to_pad[key]
		else
			final_list[key] = 1

	return final_list

/**
* Like pick_weight, but decreases the value of the picked element by 1
 * For example, given the following list:
 * A = 6, B = 3, C = 1, D = 0
 * A would have a 60% chance of being picked, after which it would decrease by one and the new list would be
 * A = 5, B = 3, C = 1, D = 0
 * Tt would then have a 55.55...% to be picked, rinse and repeat
*/
/proc/pick_weight_take(list/list_to_pick)
	. = pick_weight(list_to_pick)
	list_to_pick[.]--

/// Pick a random element from the list and remove it from the list.
/proc/pick_n_take(list/list_to_pick)
	//RETURN_TYPE(list_to_pick[_].type)
	if(list_to_pick.len)
		var/picked = rand(1,list_to_pick.len)
		. = list_to_pick[picked]
		list_to_pick.Cut(picked,picked+1) //Cut is far more efficient that Remove()

/proc/get_me_a_goal(is_dissident = FALSE)
	var/list/possible = list()
	for(var/goal_type in subtypesof(/datum/goal) - /datum/goal/antag)
		var/datum/goal/G = goal_type
		var/weight = initial(G.rarity)
		if(weight <= 0)
			continue
		if(initial(G.special))
			continue
		if(is_dissident)
			if(!initial(G.antag))
				continue
		else
			if(initial(G.antag))
				continue
		possible[goal_type] = weight

	if(!length(possible))
		return null

	return pick_weight(possible)

/proc/get_random_bright_color()
	return rgb(rand(0, 360), rand(0, 100), rand(21, 100), space = COLORSPACE_HSV)

proc/get_random_light_color()
    return rgb(rand(150, 255),rand(150, 255),rand(150, 255))

// Parse number into a word. Essentially, 1 is NONCE and what so.
/proc/skill_level_to_word(numero)
	var/flarov = "WAS?!"
	switch(numero)
		if(1)
			flarov = "JSI NULLA!"
		if(2 to 10)
			flarov = "NONCE"
		if(10 to 25)
			flarov = "KLARE"
		if(25 to 45)
			flarov = "NOTICE-ABLE"
		if(40 to 50)
			flarov = "HALF-FOR"
		if(50 to 60)
			flarov = "GUT-RU"
		if(60 to 80)
			flarov = "YORES"
		if(80 to 99)
			flarov = "INDHERE"
		if(100)
			flarov = "GUARANTEED"

	return flarov

/proc/check_pixel_bounds(_x, _y, check_x, check_x2, check_y, check_y2)
	if((_x >= check_x && _x <= check_x2) && (_y >= check_y && _y <= check_y2))
		return TRUE
	return FALSE

/proc/is_stationbound(atom/A)
	if(!A)
		return
	var/turf/T = get_turf(A)
	if(!T)
		return
	var/area/AR = get_area(T)
	if(istype(AR, /area/station))
		return TRUE	

/**
  * Hook for running code when a dir change occurs
  *
  * Not recommended to use, listen for the COMSIG_ATOM_DIR_CHANGE signal instead (sent by this proc)
  */
/atom/proc/setDir(newdir)
	//SEND_SIGNAL(src, COMSIG_ATOM_DIR_CHANGE, dir, newdir)
	dir = newdir

/*
	Misc helpers
	face_atom: turns the mob towards what you clicked on
*/

/atom/proc/face_me(location, control, params)
	return src

// Simple helper to face another atom, much nicer than byond's dir = get_dir(src,A) which is biased in some ugly ways
/atom/proc/face_atom(atom/A, location, control, params)
	if(!A)
		return
	var/atom/holder = A.face_me(location, control, params)
	if(!holder)
		return
	var/dx = holder.x - x
	var/dy = holder.y - y
	if(!dx && !dy) // Wall items are graphically shifted but on the floor
		if(holder.pixel_y > 64)
			setDir(NORTH)
		else if(holder.pixel_y < -64)
			setDir(SOUTH)
		else if(holder.pixel_x > 64)
			setDir(EAST)
		else if(holder.pixel_x < -64)
			setDir(WEST)
		return

	if(abs(dx) < abs(dy))
		if(dy > 0)
			setDir(NORTH)
		else
			setDir(SOUTH)
	else
		if(dx > 0)
			setDir(EAST)
		else
			setDir(WEST)

/mob/human/verb/do_paychecks()
	station.do_paychecks()
	HeartAttack()

/mob/human/verb/test()
	chat_announce("WE SHALL USE ALL PEACEFUL MEANS TO OVERCOME TYRANNY!", "bad", sound('sound/effects/announce/one.ogg'))
	sleep(6 SECONDS)
	chat_announce("THEY CAN'T USE OUR SHAME AGAINST US!", "bad", sound('sound/effects/announce/two.ogg'))
	sleep(3 SECONDS)
	chat_announce("REGARDLESS OF RACE, SOCIAL STATUS, OR GENDER, WE'RE ALL AFFECTED!", "bad", sound('sound/effects/announce/three.ogg'))