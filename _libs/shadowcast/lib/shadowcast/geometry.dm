// ============================================================================
//  shadowcast / geometry.dm
//  Pure math, no world state. Coordinates are pixels, +x east, +y NORTH.
//  "Screen space" below means: relative to the light, which is always drawn at
//  the centre of the eye tile because the client camera follows the eye.
//
//  Why this smooths out for free: a shadow quad is
//      near  = A - L            far = m * (A - L)
//  i.e. every vertex is AFFINE in the light position L. BYOND's
//  ANIMATION_LINEAR_TRANSFORM interpolates matrix entries linearly, and the
//  vertices are linear in the matrix entries, so while the light glides from
//  L0 to L1 each vertex slides along a straight line - exactly where the
//  true shadow would be at every instant. No per-frame server work.
// ============================================================================

/// The sprite is a right triangle: R = bottom-left corner (the right angle),
/// P = bottom-right, Q = top-left. This returns the matrix that maps the sprite
/// onto triangle (R, P, Q). Points are in screen px relative to the icon centre.
/// Because the transform pivots on the icon centre, the translation is simply
/// the midpoint of P and Q (independent of the icon size).
/proc/shadowcast_tri_matrix(rx, ry, px, py, qx, qy)
	var/s = SHADOWCAST_ICON_SIZE
	return matrix((px - rx) / s, (qx - rx) / s, (px + qx) * 0.5, (py - ry) / s, (qy - ry) / s, (py + qy) * 0.5)

/// Signed distance from the light to an edge's supporting line, measured along
/// the edge's outward normal. Negative = the edge faces away from the light =
/// it extrudes a shadow. Zero or positive = the light can see it, no shadow.
/proc/shadowcast_side(ax, ay, nx, ny, lx, ly)
	return nx * (lx - ax) + ny * (ly - ay)

/// Fraction (0..1) of a straight light move at which the side value crosses
/// zero, given its value at the start (s0) and at the end (s1).
/proc/shadowcast_cross_t(s0, s1)
	return s0 / (s0 - s1)

/// The extrusion factors we allow (far = m * near). A short ladder means an
/// edge keeps the same m across many consecutive steps, which is what keeps
/// the glide exact; m only changes when the light crosses a rung.
/var/global/list/shadowcast_m_ladder = list(1.5, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64)

/// Smallest ladder rung that pushes the far side of the shadow past the edge
/// of the view. h = distance from the light to the edge line, ext = how far the
/// view reaches from the light (plus slack).
/proc/shadowcast_pick_m(h, ext)
	var/need = ext / max(h, 0.5)
	for(var/m in shadowcast_m_ladder)
		if(m >= need)
			return min(m, SHADOWCAST_MAX_EXTRUDE)
	return SHADOWCAST_MAX_EXTRUDE

/// The two triangle matrices that make up the shadow of one edge A->B whose
/// outward normal is (nx,ny), cast by a light at (lx,ly), extruded by factor m.
/// Quad = near A, near B, far B, far A. Returns list(matrix1, matrix2) or null.
/// Both triangles share the diagonal (near A)-(far B), so it is the only seam.
/proc/shadowcast_quad_matrices(ax, ay, bx, by, nx, ny, lx, ly, m)
	var/g = SHADOWCAST_EDGE_GROW
	var/tx = bx - ax
	var/ty = by - ay
	var/len = sqrt(tx * tx + ty * ty)
	if(len <= 0)
		return null
	tx /= len
	ty /= len
	// Near vertices: pushed g px along the edge (overlap with neighbours) and
	// g px into the wall (no light leak between wall and shadow).
	var/anx = ax - lx - g * tx - g * nx
	var/any = ay - ly - g * ty - g * ny
	var/bnx = bx - lx + g * tx - g * nx
	var/bny = by - ly + g * ty - g * ny
	// Far vertices: the same ray scaled by m, kept g px wide on each side.
	var/afx = m * (ax - lx) - g * tx
	var/afy = m * (ay - ly) - g * ty
	var/bfx = m * (bx - lx) + g * tx
	var/bfy = m * (by - ly) + g * ty
	return list(
		shadowcast_tri_matrix(bnx, bny, anx, any, bfx, bfy),
		shadowcast_tri_matrix(afx, afy, bfx, bfy, anx, any))

/// Matrices for the "blind" part of a field-of-view cone. The cone points along
/// angle phi (degrees, 0 = east, 90 = north), is fov degrees wide and its apex
/// sits "behind" px behind the light so the tiles right next to you stay
/// visible. ext = how far the view reaches. Returns a list of matrices
/// (1..4 triangles), or an empty list when fov >= 360.
/proc/shadowcast_cone_matrices(phi, fov, behind, ext)
	var/list/out = list()
	if(fov >= 360)
		return out
	fov = max(fov, 4)
	var/blind = 360 - fov
	var/pieces = max(1, ceil(blind / 100))
	var/step = blind / pieces
	var/start = phi + fov * 0.5
	var/apx = -behind * cos(phi)
	var/apy = -behind * sin(phi)
	var/rho = (ext + behind) / cos(step * 0.5)
	for(var/i in 0 to pieces - 1)
		var/t1 = start + step * i
		var/t2 = t1 + step
		out += shadowcast_tri_matrix(apx, apy, apx + rho * cos(t1), apy + rho * sin(t1), apx + rho * cos(t2), apy + rho * sin(t2))
	return out

/// Facing angle (degrees, 0 = east, counter-clockwise) of a BYOND direction.
/proc/shadowcast_dir_angle(dir)
	switch(dir)
		if(EAST)
			return 0
		if(NORTHEAST)
			return 45
		if(NORTH)
			return 90
		if(NORTHWEST)
			return 135
		if(WEST)
			return 180
		if(SOUTHWEST)
			return 225
		if(SOUTH)
			return 270
		if(SOUTHEAST)
			return 315
	return 270
