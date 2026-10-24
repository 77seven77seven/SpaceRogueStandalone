"""Checks the shadow geometry against brute-force raycasting.  python3 verify.py"""
import sys, math
import numpy as np
import ref_core as rc

# walls transcribed from the reference screenshot: (col,row) from the top-left, 0-based
SHOT = """1,3 2,3 3,3 1,4 1,5 1,6  5,3 6,3 7,3  4,5  5,7 8,7  4,9 6,9 6,10
11,1 11,2 11,3 11,4  14,8 13,9 14,9 12,10 13,10 11,11 10,12 9,13
1,11 1,12 1,13 1,14 2,14 3,14  5,14 6,14 7,14 8,14"""
WALLS = {(int(c) + 1, 15 - int(r)) for c, r in (p.split(",") for p in SHOT.split())}
EXT = 240 + 64                      # half view + SHADOWCAST_SLACK_PX
C = rc.TILE


def light(x, y, ox=0, oy=0):        # tile centre (+ pixel offset) in world px
    return ((x - 1) * C + C / 2 + ox, (y - 1) * C + C / 2 + oy)


def static_err(L, label):
    edges = rc.tile_edges(WALLS)
    plan = rc.plan_move(edges, L, L, EXT)
    a = rc.render_mask(rc.matrices_at(plan, 0.0))
    bad, n = rc.compare(a, rc.truth_mask(WALLS, L))
    print(f"  {label:<34} bad {bad:>5} / {n}  ({100 * bad / n:.3f}%)")
    return bad / n


def move_err(L0, L1, label, ts=(0, .25, .5, .75, 1)):
    edges = rc.tile_edges(WALLS)
    plan = rc.plan_move(edges, L0, L1, EXT)
    worst = 0
    for t in ts:
        L = (L0[0] + (L1[0] - L0[0]) * t, L0[1] + (L1[1] - L0[1]) * t)
        a = rc.render_mask(rc.matrices_at(plan, t))
        bad, n = rc.compare(a, rc.truth_mask(WALLS, L))
        worst = max(worst, bad / n)
    print(f"  {label:<34} worst frame {100 * worst:.3f}%  ({len(plan)} edges, "
          f"{sum(1 for v in plan.values() if v[0] != 'stable')} flip)")
    return worst


def tile_of(L):
    return (int(L[0] // C) + 1, int(L[1] // C) + 1)


_orig_plan = rc.plan_move


def _checked_plan(edges, L0, L1, ext):
    for L in (L0, L1):                      # a light inside a wall is a test bug, not a result
        assert tile_of(L) not in WALLS, f"light {L} is inside wall {tile_of(L)}"
    return _orig_plan(edges, L0, L1, ext)


rc.plan_move = _checked_plan
fails = []
print("static frames (player at screenshot position, other spots, pixel offsets):")
for lab, L in [("screenshot spot (8,8)", light(8, 8)), ("(3,3)", light(3, 3)), ("(12,6)", light(12, 6)),
               ("(8,8) +7,+11 px", light(8, 8, 7, 11)), ("(6,11) -9,+3 px", light(6, 11, -9, 3))]:
    if static_err(L, lab) > 0.004:
        fails.append(lab)

print("glides (tile -> tile, frames at t=0,.25,.5,.75,1):")
for lab, a, b in [("west  (8,8)->(7,8)", light(8, 8), light(7, 8)),
                  ("east  (7,8)->(8,8)  [wall beside]", light(7, 8), light(8, 8)),
                  ("north (8,8)->(8,9)", light(8, 8), light(8, 9)),
                  ("diag  (8,8)->(7,9)", light(8, 8), light(7, 9)),
                  ("diag  (7,8)->(8,9)", light(7, 8), light(8, 9)),
                  ("diag  (4,8)->(5,9)", light(4, 8), light(5, 9)),
                  ("south (12,6)->(12,5)", light(12, 6), light(12, 5)),
                  ("south (6,9)->(6,8)  [past wall]", light(6, 9), light(6, 8)) if (6, 8) not in WALLS else
                  ("south (7,9)->(7,8)", light(7, 9), light(7, 8)),
                  ("mid-glide start (8,8)-11px->(7,8)", light(8, 8, -11), light(7, 8)),
                  ("pixel step (8,8)+3,+5 ->+9,+5", light(8, 8, 3, 5), light(8, 8, 9, 5))]:
    if move_err(a, b, lab) > 0.006:
        fails.append(lab)

print("field-of-view cone (blind wedge, apex 16px behind):")
for fov in (90, 120, 200, 270):
    for phi in (0, 90, 215):
        # the cone needs the view's DIAGONAL radius (+slack); shadow quads only the axis extent
        a = rc.render_mask(rc.cone_matrices(phi, fov, 16, math.hypot(240, 240) + 64))
        yy, xx = np.mgrid[0:480, 0:480]
        u, v = xx + .5 - 240, 240 - (yy + .5)
        ax, ay = -16 * math.cos(math.radians(phi)), -16 * math.sin(math.radians(phi))
        ang = (np.degrees(np.arctan2(v - ay, u - ax)) - phi + 180) % 360 - 180
        blind = np.abs(ang) > fov / 2
        edge = np.abs(np.abs(ang) - fov / 2) < 1.5
        bad = ((a > .5) != blind) & ~edge
        pct = 100 * bad.mean()
        flag = "" if pct < .05 else "  <-- FAIL"
        if flag:
            fails.append(f"cone {fov}/{phi}")
        print(f"  fov {fov:>3} facing {phi:>3}: bad {pct:.3f}%{flag}")

print("\nRESULT:", "ALL PASS" if not fails else f"FAILURES: {fails}")
sys.exit(1 if fails else 0)
