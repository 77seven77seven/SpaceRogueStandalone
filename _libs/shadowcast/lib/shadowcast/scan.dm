// ============================================================================
//  shadowcast / scan.dm
//  Finds the exposed faces of everything that blocks light near the eye.
//  Nothing is cached: opacity is read live, so doors, smoke and destructible
//  walls just work. A 15x15 view scans ~360 turfs per step.
// ============================================================================

/// Default rule: a turf blocks light if it, or anything standing on it, has opacity.
/// Override with #define SHADOWCAST_BLOCKS(T) in your own code.
/proc/shadowcast_default_blocks(turf/T)
	if(T.opacity)
		return 1
	for(var/atom/movable/A in T)
		if(A.opacity)
			return 1
	return 0

/// The turf an atom is standing on (plain DM has no get_turf).
/proc/shadowcast_turf(atom/A)
	while(A && !isturf(A))
		A = A.loc
	return A

/// "32" or "32x32" -> list(32, 32). Used for world.icon_size.
/proc/shadowcast_parse_size(value)
	if(isnum(value))
		return list(value, value)
	var/list/parts = splittext("[value]", "x")
	var/w = text2num(parts[1])
	var/h = parts.len > 1 ? text2num(parts[2]) : w
	return list(w, h)

/// client.view -> list(width, height) in tiles. A plain number is a view depth.
/proc/shadowcast_view_size(view)
	if(isnum(view))
		return list(view * 2 + 1, view * 2 + 1)
	return shadowcast_parse_size(view)

/// Every exposed tile face inside the window around tile (cx,cy,cz).
/// The window reaches left/right/down/up tiles from the centre.
/// Returns a list of edges, each list(key, ax, ay, bx, by, nx, ny): the face runs
/// from A to B (pixels, y up) and (nx,ny) points out of the solid.
/proc/shadowcast_scan(cx, cy, cz, left, right, down, up, tw, th)
	var/list/out = list()
	var/x0 = max(1, cx - left)
	var/y0 = max(1, cy - down)
	var/x1 = min(world.maxx, cx + right)
	var/y1 = min(world.maxy, cy + up)
	var/w = x1 - x0 + 1
	var/h = y1 - y0 + 1
	if(w < 1 || h < 1)
		return out
	var/list/opq = new /list(w * h)
	var/list/blocked = list()
	for(var/i in 0 to w - 1)
		for(var/j in 0 to h - 1)
			var/turf/T = locate(x0 + i, y0 + j, cz)
			var/index = i * h + j + 1
			var/is_blocked = T && SHADOWCAST_BLOCKS(T)
			opq[index] = is_blocked ? 1 : 0
			if(is_blocked)
				blocked += index
	for(var/blocked_index in blocked)
		var/index = blocked_index - 1
		var/i = floor(index / h)
		var/j = index % h
		var/tx = x0 + i
		var/ty = y0 + j
		var/l = (tx - 1) * tw
		var/b = (ty - 1) * th
		var/r = l + tw
		var/t = b + th
		// Faces on the window border count as exposed; they are off-screen anyway.
		if(j == h - 1 || !opq[i * h + j + 2])
			out += list(list("[tx],[ty]N", l, t, r, t, 0, 1))
		if(j == 0 || !opq[i * h + j])
			out += list(list("[tx],[ty]S", l, b, r, b, 0, -1))
		if(i == w - 1 || !opq[(i + 1) * h + j + 1])
			out += list(list("[tx],[ty]E", r, b, r, t, 1, 0))
		if(i == 0 || !opq[(i - 1) * h + j + 1])
			out += list(list("[tx],[ty]W", l, b, l, t, -1, 0))
	return out
