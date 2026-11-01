#define LIGHTING_HEIGHT 1 // height off the ground of light sources on the pseudo-z-axis, you should probably leave this alone
#define LIGHTING_ROUND_VALUE (1 / 128) //Value used to round lumcounts, values smaller than 1/255 don't matter (if they do, thanks sinking points), greater values will make lighting less precise, but in turn increase performance, VERY SLIGHTLY.

#define LIGHT_PLANE      (2)
#define LIGHTING_LAYER 11

#define Clamp(x, y, z) 	(x <= y ? y : (x >= z ? z : x))

#define CLAMP01(x) 		(Clamp(x, 0, 1))

var/mob/dview/dview_mob = new

#define FOR_DVIEW(type, range, center, invis_flags) \
	dview_mob.loc = center; \
	dview_mob.see_invisible = invis_flags; \
	for(type in view(range, dview_mob))
#define END_FOR_DVIEW dview_mob.loc = null

//Version of view() which ignores darkness, because BYOND doesn't have it.
/proc/dview(var/range = world.view, var/center, var/invis_flags = 0)
	if(!center)
		return

	dview_mob.loc = center

	dview_mob.see_invisible = invis_flags

	. = view(range, dview_mob)
	dview_mob.loc = null

/mob/dview
	invisibility = 101
	density = 0

	see_in_dark = 1e6

/mob/dview/New()
	// do nothing. we don't want to be in any mob lists; we're a dummy not a mob.

/proc/GetRedPart(const/hexa)
	return hex2num(copytext(hexa,2,4))

/proc/GetGreenPart(const/hexa)
	return hex2num(copytext(hexa,4,6))

/proc/GetBluePart(const/hexa)
	return hex2num(copytext(hexa,6,8))

/proc/GetHexColors(const/hexa)
	return list(
			GetRedPart(hexa),
			GetGreenPart(hexa),
			GetBluePart(hexa)
		)

/proc/MixColors(const/list/colors)
	var/list/reds = list()
	var/list/blues = list()
	var/list/greens = list()
	var/list/weights = list()

	for (var/i = 0, ++i <= colors.len)
		reds.Add(GetRedPart(colors[i]))
		blues.Add(GetBluePart(colors[i]))
		greens.Add(GetGreenPart(colors[i]))
		weights.Add(1)

	var/r = mixOneColor(weights, reds)
	var/g = mixOneColor(weights, greens)
	var/b = mixOneColor(weights, blues)
	return rgb(r,g,b)

/proc/mixOneColor(var/list/weight, var/list/color)
	if (!weight || !color || length(weight)!=length(color))
		return 0

	var/contents = length(weight)
	var/i

	//normalize weights
	var/listsum = 0
	for(i=1; i<=contents; i++)
		listsum += weight[i]
	for(i=1; i<=contents; i++)
		weight[i] /= listsum

	//mix them
	var/mixedcolor = 0
	for(i=1; i<=contents; i++)
		mixedcolor += weight[i]*color[i]
	mixedcolor = round(mixedcolor)

	//until someone writes a formal proof for this algorithm, let's keep this in
//	if(mixedcolor<0x00 || mixedcolor>0xFF)
//		return 0
	//that's not the kind of operation we are running here, nerd
	mixedcolor=min(max(mixedcolor,0),255)

	return mixedcolor

/turf
	var/dynamic_lighting = 1
	luminosity = 1