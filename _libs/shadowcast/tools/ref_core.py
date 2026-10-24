"""Reference port of lib/shadowcast/geometry.dm + a software "BYOND client".

Everything here mirrors the DM one-to-one (same formulas, same ladder) so the
DM math can be checked against brute-force raycasting without a BYOND runtime.
Coordinates: pixels, +x east, +y north. Screen space = relative to the light.
"""
import math
import numpy as np

S = 512                     # SHADOWCAST_ICON_SIZE
GROW = 0.5                  # SHADOWCAST_EDGE_GROW
GAIN = 1.4                  # SHADOWCAST_SEAM_GAIN
MAX_M = 64                  # SHADOWCAST_MAX_EXTRUDE
LADDER = [1.5, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64]
TILE = 32


# ------------------------------------------------------------ geometry (= geometry.dm)
def tri_matrix(rx, ry, px, py, qx, qy):
    return np.array([(px - rx) / S, (qx - rx) / S, (px + qx) * .5,
                     (py - ry) / S, (qy - ry) / S, (py + qy) * .5])


def side(ax, ay, nx, ny, lx, ly):
    return nx * (lx - ax) + ny * (ly - ay)


def cross_t(s0, s1):
    return s0 / (s0 - s1)


def pick_m(h, ext):
    need = ext / max(h, 0.5)
    for m in LADDER:
        if m >= need:
            return min(m, MAX_M)
    return MAX_M


def quad_matrices(ax, ay, bx, by, nx, ny, lx, ly, m):
    g = GROW
    tx, ty = bx - ax, by - ay
    ln = math.hypot(tx, ty)
    if ln <= 0:
        return None
    tx /= ln
    ty /= ln
    anx, any_ = ax - lx - g * tx - g * nx, ay - ly - g * ty - g * ny
    bnx, bny = bx - lx + g * tx - g * nx, by - ly + g * ty - g * ny
    afx, afy = m * (ax - lx) - g * tx, m * (ay - ly) - g * ty
    bfx, bfy = m * (bx - lx) + g * tx, m * (by - ly) + g * ty
    return [tri_matrix(bnx, bny, anx, any_, bfx, bfy),
            tri_matrix(afx, afy, bfx, bfy, anx, any_)]


def cone_matrices(phi, fov, behind, ext):
    if fov >= 360:
        return []
    fov = max(fov, 4)
    blind = 360 - fov
    pieces = max(1, math.ceil(blind / 100))
    step = blind / pieces
    start = phi + fov * .5
    apx, apy = -behind * math.cos(math.radians(phi)), -behind * math.sin(math.radians(phi))
    rho = (ext + behind) / math.cos(math.radians(step * .5))
    out = []
    for i in range(pieces):
        t1 = math.radians(start + step * i)
        t2 = math.radians(start + step * (i + 1))
        out.append(tri_matrix(apx, apy, apx + rho * math.cos(t1), apy + rho * math.sin(t1),
                              apx + rho * math.cos(t2), apy + rho * math.sin(t2)))
    return out


# ------------------------------------------------------------ scanning (= scan.dm)
def tile_edges(walls):
    """Exposed unit edges of a set of wall tiles {(x,y)} (1-based, y up).
    Each edge: (key, ax, ay, bx, by, nx, ny) in world px."""
    out = []
    for (x, y) in walls:
        l, b = (x - 1) * TILE, (y - 1) * TILE
        r, t = l + TILE, b + TILE
        if (x, y + 1) not in walls:
            out.append((f"{x},{y}N", l, t, r, t, 0, 1))
        if (x, y - 1) not in walls:
            out.append((f"{x},{y}S", l, b, r, b, 0, -1))
        if (x + 1, y) not in walls:
            out.append((f"{x},{y}E", r, b, r, t, 1, 0))
        if (x - 1, y) not in walls:
            out.append((f"{x},{y}W", l, b, l, t, -1, 0))
    return out


def plan_move(edges, L0, L1, ext):
    """What the DM update() does for one light move L0 -> L1.
    Returns {key: (mode, m, M0, M1, Mc, tc)} with mode in
    'stable' | 'vanish' | 'appear'. Matrices are lists of two arrays."""
    plan = {}
    for (key, ax, ay, bx, by, nx, ny) in edges:
        s0 = side(ax, ay, nx, ny, *L0)
        s1 = side(ax, ay, nx, ny, *L1)
        b0, b1 = s0 < 0, s1 < 0
        if not (b0 or b1):
            continue
        h = min(abs(s) for s, b in ((s0, b0), (s1, b1)) if b)
        m = pick_m(h, ext)
        if b0 and b1:
            plan[key] = ("stable", m, quad_matrices(ax, ay, bx, by, nx, ny, *L0, m),
                         quad_matrices(ax, ay, bx, by, nx, ny, *L1, m), None, None)
        else:
            tc = cross_t(s0, s1)
            Lc = (L0[0] + (L1[0] - L0[0]) * tc, L0[1] + (L1[1] - L0[1]) * tc)
            Mc = quad_matrices(ax, ay, bx, by, nx, ny, *Lc, m)
            if b0:
                plan[key] = ("vanish", m, quad_matrices(ax, ay, bx, by, nx, ny, *L0, m), None, Mc, tc)
            else:
                plan[key] = ("appear", m, None, quad_matrices(ax, ay, bx, by, nx, ny, *L1, m), Mc, tc)
    return plan


def matrices_at(plan, t):
    """Triangle matrices a BYOND client shows at fraction t of the glide, given
    the animate() sequences the DM builds (linear matrix interpolation)."""
    mats = []
    for key, (mode, m, M0, M1, Mc, tc) in plan.items():
        if mode == "stable":
            mats += [(1 - t) * a + t * b for a, b in zip(M0, M1)]
        elif mode == "vanish":
            if t < tc:
                f = t / tc if tc > 0 else 1
                mats += [(1 - f) * a + f * b for a, b in zip(M0, Mc)]
        else:
            if t >= tc:
                f = (t - tc) / (1 - tc) if tc < 1 else 1
                mats += [(1 - f) * a + f * b for a, b in zip(Mc, M1)]
    return mats


# ------------------------------------------------------------ the software client
def sprite_alpha(ss=4):
    """triangle.png alpha: 1 where x+y <= S (x,y from the bottom-left), box-filtered AA."""
    n = S * ss
    c = (np.arange(n) + .5) / ss
    xx, yy = np.meshgrid(c, c)
    a = (xx + yy <= S).astype(np.float32)
    return a.reshape(S, ss, S, ss).mean(axis=(1, 3))        # [row_from_bottom, col]


_SPR = None


def render_mask(mats, size=(480, 480), center=(240, 240)):
    """Composite black triangles like the mask plane master: bilinear texture
    sampling, normal alpha blending, then the alpha gain. Returns H x W alpha (row 0 = top)."""
    global _SPR
    if _SPR is None:
        _SPR = sprite_alpha()
    W, H = size
    keep = np.ones((H, W), np.float32)          # running product of (1 - alpha)
    for M in mats:
        a, b, c, d, e, f = M
        det = a * e - b * d
        if abs(det) < 1e-12:
            continue
        # bounding box of the transformed sprite in screen px
        corners = [(-S / 2, -S / 2), (S / 2, -S / 2), (-S / 2, S / 2)]
        xs = [a * x + b * y + c for x, y in corners]
        ys = [d * x + e * y + f for x, y in corners]
        x0 = max(0, int(math.floor(center[0] + min(xs) - 2)))
        x1 = min(W, int(math.ceil(center[0] + max(xs) + 2)))
        y0 = max(0, int(math.floor(center[1] - max(ys) - 2)))
        y1 = min(H, int(math.ceil(center[1] - min(ys) + 2)))
        if x0 >= x1 or y0 >= y1:
            continue
        px, py = np.meshgrid(np.arange(x0, x1) + .5, np.arange(y0, y1) + .5)
        u = px - center[0]
        v = center[1] - py
        du, dv = u - c, v - f
        sx = (e * du - b * dv) / det            # inverse affine -> icon-centre coords
        sy = (-d * du + a * dv) / det
        col = sx + S / 2 - .5                   # texel-centre coordinates
        row = sy + S / 2 - .5
        c0 = np.floor(col).astype(int)
        r0 = np.floor(row).astype(int)
        fc, fr = col - c0, row - r0
        val = np.zeros_like(fc)
        for dr in (0, 1):
            for dc in (0, 1):
                rr, cc = r0 + dr, c0 + dc
                ok = (rr >= 0) & (rr < S) & (cc >= 0) & (cc < S)
                wgt = (fr if dr else 1 - fr) * (fc if dc else 1 - fc)
                tex = np.zeros_like(fc)
                tex[ok] = _SPR[rr[ok], cc[ok]]
                val += wgt * tex
        keep[y0:y1, x0:x1] *= (1 - val)
    return np.clip((1 - keep) * GAIN, 0, 1)


def truth_mask(walls, L, size=(480, 480), center=(240, 240)):
    """1 where the pixel is hidden from L by a wall (exact slab test), -1 inside walls."""
    W, H = size
    px, py = np.meshgrid(np.arange(W) + .5, np.arange(H) + .5)
    wx = L[0] + (px - center[0])                # world px of each screen pixel
    wy = L[1] + (center[1] - py)
    dx, dy = wx - L[0], wy - L[1]
    hidden = np.zeros((H, W), bool)
    inside = np.zeros((H, W), bool)
    eps = .02
    for (x, y) in walls:
        l, r = (x - 1) * TILE + eps, x * TILE - eps
        b, t = (y - 1) * TILE + eps, y * TILE - eps
        inside |= (wx > l) & (wx < r) & (wy > b) & (wy < t)
        with np.errstate(divide="ignore", invalid="ignore"):
            t1x, t2x = (l - L[0]) / dx, (r - L[0]) / dx
            t1y, t2y = (b - L[1]) / dy, (t - L[1]) / dy
        tminx, tmaxx = np.minimum(t1x, t2x), np.maximum(t1x, t2x)
        tminy, tmaxy = np.minimum(t1y, t2y), np.maximum(t1y, t2y)
        zx = dx == 0
        zy = dy == 0
        tminx = np.where(zx, np.where((L[0] > l) & (L[0] < r), -np.inf, np.inf), tminx)
        tmaxx = np.where(zx, np.inf, tmaxx)
        tminy = np.where(zy, np.where((L[1] > b) & (L[1] < t), -np.inf, np.inf), tminy)
        tmaxy = np.where(zy, np.inf, tmaxy)
        tmin = np.maximum(tminx, tminy)
        tmax = np.minimum(tmaxx, tmaxy)
        hidden |= (tmin < tmax) & (tmax > 0) & (tmin < 1)
    out = hidden.astype(np.int8)
    out[inside] = -1
    return out


def compare(alpha, truth, band=2.5):
    """Count pixels where mask and truth disagree, ignoring a band around truth edges
    and wall interiors. Returns (bad_pixels, checked_pixels)."""
    valid = truth >= 0
    t = (truth == 1)
    edge = np.zeros_like(t)
    for sh in (1, -1):
        for ax in (0, 1):
            edge |= (np.roll(t, sh, ax) != t)
    k = int(math.ceil(band))
    near = edge.copy()
    for _ in range(k):
        n2 = near.copy()
        for sh in (1, -1):
            for ax in (0, 1):
                n2 |= np.roll(near, sh, ax)
        near = n2
    check = valid & ~near
    bad = ((alpha > .5) != t) & check
    return int(bad.sum()), int(check.sum())
