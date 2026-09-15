#!/usr/bin/env python3
"""
dmi_punch_holes.py — Punch transparent "holes" into specific icon states /
directions of a BYOND .dmi file, using a mask PNG.

Built for the case: "states pants2..pants39 are missing the hand holes; here's
a mask of what should be transparent, drawn for EAST; mirror it for WEST."

How it works
------------
A .dmi is a PNG sprite sheet plus a zTXt chunk (keyword "Description") holding
the DMI descriptor, which lists each icon state and its dirs/frames counts.
Frames are packed into the sheet in reading order (left-to-right, top-to-
bottom), state after state. Within one state the order is frame-major,
dir-minor:

    frame1[dir0..dirN], frame2[dir0..dirN], ...

and the dir order is fixed by the format:

    0 SOUTH, 1 NORTH, 2 EAST, 3 WEST,
    4 SOUTHEAST, 5 SOUTHWEST, 6 NORTHEAST, 7 NORTHWEST

So we parse the descriptor, walk to the exact tile for each (state, frame, dir)
we care about, and zero the alpha of every pixel the mask marks. The sheet
dimensions and frame order never change, so the descriptor stays valid and gets
copied through byte-for-byte.

Mask
----
Any pixel in the mask PNG with alpha > 0 marks a pixel to clear. Color is
ignored, so your red blob works as-is. The mask must be the same size as one
icon tile (e.g. 32x32).

Requires Pillow:  pip install Pillow

Examples
--------
Preview what would change, without writing anything:
    python3 dmi_punch_holes.py pants.dmi hand_mask.png \
        --prefix pants --from 2 --to 39 --dry-run

Do it, writing pants_fixed.dmi and a before/after contact sheet:
    python3 dmi_punch_holes.py pants.dmi hand_mask.png \
        --prefix pants --from 2 --to 39 --preview check.png

Nudge the mirrored mask if the west sprite isn't a pixel-perfect mirror:
    ... --west-offset 1,0

Apply to all dirs instead of just east/west:
    ... --dirs south,north,east,west
"""

import argparse
import shutil
import sys
from pathlib import Path

from PIL import Image, PngImagePlugin

# Fixed by the DMI format.
DIR_ORDER = [
    "south", "north", "east", "west",
    "southeast", "southwest", "northeast", "northwest",
]
DIR_INDEX = {name: i for i, name in enumerate(DIR_ORDER)}


class DmiFormatError(Exception):
    pass


# ---------------------------------------------------------------- metadata ---

def _unescape(value):
    """Reverse BYOND's descriptor escaping (\\\\ and \\")."""
    out, escaped = [], False
    for ch in value:
        if escaped:
            out.append(ch)
            escaped = False
        elif ch == "\\":
            escaped = True
        else:
            out.append(ch)
    return "".join(out)


def parse_dmi_metadata(text):
    """Parse a DMI descriptor into (version, tile_w, tile_h, [state dicts]).

    Each state dict has: name, dirs, frames, start (global frame index).
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "# BEGIN DMI":
        raise DmiFormatError("Descriptor does not start with '# BEGIN DMI'")

    version, tile_w, tile_h = None, None, None
    states, cur = [], None

    for raw in lines[1:]:
        line = raw.rstrip("\r")
        if line.strip() == "# END DMI":
            break
        if " = " not in line:
            continue
        key, _, val = line.partition(" = ")
        key, val = key.strip(), val.strip()

        if key == "version":
            version = val
        elif key == "state":
            if len(val) >= 2 and val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            cur = {"name": _unescape(val), "dirs": 1, "frames": 1}
            states.append(cur)
        elif cur is None:
            # Header block (before any state): width/height live here.
            if key == "width":
                tile_w = int(val)
            elif key == "height":
                tile_h = int(val)
        else:
            if key == "dirs":
                cur["dirs"] = int(val)
            elif key == "frames":
                cur["frames"] = int(val)

    if not states:
        raise DmiFormatError("Descriptor contains no icon states")

    # BYOND defaults to 32x32 when width/height are omitted.
    tile_w = tile_w or 32
    tile_h = tile_h or 32

    index = 0
    for st in states:
        st["start"] = index
        index += st["dirs"] * st["frames"]

    return version, tile_w, tile_h, states


def tile_box(global_index, cols, tile_w, tile_h):
    x = (global_index % cols) * tile_w
    y = (global_index // cols) * tile_h
    return x, y, x + tile_w, y + tile_h


# -------------------------------------------------------------------- mask ---

def load_mask(path, tile_w, tile_h):
    """Return a set of (x, y) pixel coords marked by the mask."""
    mask_img = Image.open(path).convert("RGBA")
    mw, mh = mask_img.size
    if (mw, mh) != (tile_w, tile_h):
        raise DmiFormatError(
            f"Mask is {mw}x{mh} but the icon's tile size is {tile_w}x{tile_h}. "
            f"They must match."
        )
    px = mask_img.load()
    coords = {(x, y) for y in range(mh) for x in range(mw) if px[x, y][3] > 0}
    if not coords:
        raise DmiFormatError(f"Mask {path} has no non-transparent pixels")
    return coords


def mirror_mask(coords, tile_w, offset=(0, 0)):
    """Horizontally mirror mask coords within the tile, then shift."""
    dx, dy = offset
    return {(tile_w - 1 - x + dx, y + dy) for (x, y) in coords}


# ----------------------------------------------------------------- punching ---

def clear_pixels(sheet_px, box, coords, tile_w, tile_h):
    """Zero the alpha of mask pixels inside one tile. Returns count cleared."""
    x0, y0 = box[0], box[1]
    cleared = 0
    for (mx, my) in coords:
        if not (0 <= mx < tile_w and 0 <= my < tile_h):
            continue  # shifted off the tile
        sx, sy = x0 + mx, y0 + my
        r, g, b, a = sheet_px[sx, sy]
        if a != 0:
            sheet_px[sx, sy] = (r, g, b, 0)
            cleared += 1
    return cleared


def resolve_target_names(args):
    if args.states:
        return [n.strip() for n in args.states.split(",") if n.strip()]
    if args.prefix is None or args.from_n is None or args.to_n is None:
        raise SystemExit(
            "Specify either --states, or all of --prefix / --from / --to"
        )
    return [f"{args.prefix}{i}" for i in range(args.from_n, args.to_n + 1)]


# ------------------------------------------------------------------ preview ---

def checkerboard(size, cell=4):
    """Light/dark checker tile so transparency is visible in the preview."""
    w, h = size
    img = Image.new("RGBA", size, (255, 255, 255, 255))
    px = img.load()
    for y in range(h):
        for x in range(w):
            if ((x // cell) + (y // cell)) % 2:
                px[x, y] = (205, 205, 205, 255)
    return img


def build_preview(rows, tile_w, tile_h, scale=4, gap=6):
    """rows: list of (label, [ (before_tile, after_tile, mask_coords), ... ])

    Lays out one row per modified (state, frame), each row being pairs of
    before/after tiles with the mask highlighted on the 'before'.
    """
    if not rows:
        return None

    cols = max(len(cells) for _, cells in rows)
    cell_w = tile_w * scale
    cell_h = tile_h * scale
    total_w = cols * 2 * cell_w + (cols * 2 + 1) * gap
    total_h = len(rows) * (cell_h + gap) + gap

    canvas = Image.new("RGBA", (total_w, total_h), (30, 30, 34, 255))
    checker = checkerboard((cell_w, cell_h))

    for ri, (_label, cells) in enumerate(rows):
        y = gap + ri * (cell_h + gap)
        for ci, (before, after, coords) in enumerate(cells):
            # Highlight the mask region on the "before" tile.
            marked = before.copy()
            mpx = marked.load()
            for (mx, my) in coords:
                if 0 <= mx < tile_w and 0 <= my < tile_h:
                    r, g, b, a = mpx[mx, my]
                    if a == 0:
                        mpx[mx, my] = (255, 0, 255, 160)   # already transparent
                    else:
                        mpx[mx, my] = (255, 40, 40, 255)   # will be removed

            for oi, tile in enumerate((marked, after)):
                big = tile.resize((cell_w, cell_h), Image.NEAREST)
                plate = checker.copy()
                plate.alpha_composite(big)
                x = gap + (ci * 2 + oi) * (cell_w + gap)
                canvas.paste(plate, (x, y))

    return canvas


# --------------------------------------------------------------------- main ---

def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("dmi", type=Path, help="Input .dmi file")
    ap.add_argument("mask", type=Path,
                    help="Mask PNG, tile-sized; non-transparent pixels get cleared")
    ap.add_argument("-o", "--output", type=Path, default=None,
                    help="Output .dmi (default: <name>_fixed.dmi)")
    ap.add_argument("--in-place", action="store_true",
                    help="Overwrite the input (a .bak copy is made first)")

    ap.add_argument("--prefix", default=None,
                    help="State name prefix, e.g. 'pants'")
    ap.add_argument("--from", dest="from_n", type=int, default=None,
                    help="First numeric suffix, e.g. 2")
    ap.add_argument("--to", dest="to_n", type=int, default=None,
                    help="Last numeric suffix, e.g. 39")
    ap.add_argument("--states", default=None,
                    help="Explicit comma-separated state names (overrides prefix/from/to)")

    ap.add_argument("--dirs", default="east,west",
                    help="Comma-separated dirs to punch (default: east,west). "
                         "The mask is used as drawn for every dir listed except "
                         "west/southwest/northwest, which get it mirrored.")
    ap.add_argument("--no-mirror", action="store_true",
                    help="Use the mask as-is for west too (no horizontal flip)")
    ap.add_argument("--west-offset", default="0,0", metavar="DX,DY",
                    help="Shift the mirrored mask by DX,DY if the west sprite "
                         "isn't a pixel-perfect mirror (default: 0,0)")

    ap.add_argument("--dry-run", action="store_true",
                    help="Report what would change; write nothing")
    ap.add_argument("--preview", type=Path, default=None,
                    help="Write a before/after contact sheet PNG here")
    args = ap.parse_args()

    if not args.dmi.exists():
        raise SystemExit(f"Not found: {args.dmi}")
    if not args.mask.exists():
        raise SystemExit(f"Not found: {args.mask}")

    target_names = resolve_target_names(args)

    try:
        want_dirs = [d.strip().lower() for d in args.dirs.split(",") if d.strip()]
        for d in want_dirs:
            if d not in DIR_INDEX:
                raise SystemExit(f"Unknown dir '{d}'. Valid: {', '.join(DIR_ORDER)}")
        dx, dy = (int(v) for v in args.west_offset.split(","))
    except ValueError:
        raise SystemExit("--west-offset must look like '1,0'")

    # --- read the sheet + descriptor ---
    sheet = Image.open(args.dmi)
    description = sheet.info.get("Description")
    if description is None:
        raise SystemExit(
            f"{args.dmi} has no DMI 'Description' metadata — it's a plain PNG, "
            f"not a multi-state .dmi. Nothing to index into."
        )
    sheet = sheet.convert("RGBA")

    version, tile_w, tile_h, states = parse_dmi_metadata(description)
    sheet_w, sheet_h = sheet.size
    if sheet_w % tile_w or sheet_h % tile_h:
        raise SystemExit(
            f"Sheet {sheet_w}x{sheet_h} isn't a whole multiple of the "
            f"{tile_w}x{tile_h} tile size — file looks corrupt."
        )
    cols = sheet_w // tile_w
    capacity = cols * (sheet_h // tile_h)
    needed = states[-1]["start"] + states[-1]["dirs"] * states[-1]["frames"]
    if needed > capacity:
        raise SystemExit(
            f"Descriptor claims {needed} frames but the sheet only holds "
            f"{capacity} — file looks corrupt."
        )

    print(f"{args.dmi.name}: DMI v{version}, {tile_w}x{tile_h} tiles, "
          f"{len(states)} states, sheet {sheet_w}x{sheet_h} ({cols} cols)")

    mask = load_mask(args.mask, tile_w, tile_h)
    mirrored = mask if args.no_mirror else mirror_mask(mask, tile_w, (dx, dy))
    print(f"mask: {len(mask)} px, "
          f"x {min(x for x,_ in mask)}-{max(x for x,_ in mask)}, "
          f"y {min(y for _,y in mask)}-{max(y for _,y in mask)}")
    if not args.no_mirror:
        print(f"mirrored for west: x {min(x for x,_ in mirrored)}-"
              f"{max(x for x,_ in mirrored)}"
              + (f" (offset {dx},{dy})" if (dx or dy) else ""))
    print()

    MIRROR_DIRS = {"west", "southwest", "northwest"}
    sheet_px = sheet.load()

    by_name = {}
    for st in states:
        by_name.setdefault(st["name"], []).append(st)

    missing, no_dirs, total_cleared, touched = [], [], 0, 0
    preview_rows = []

    for name in target_names:
        matches = by_name.get(name)
        if not matches:
            missing.append(name)
            continue

        for st in matches:
            dirs, frames, start = st["dirs"], st["frames"], st["start"]
            usable = [d for d in want_dirs if DIR_INDEX[d] < dirs]
            if not usable:
                no_dirs.append(f"{name} (dirs={dirs})")
                continue

            parts, row_cells = [], []
            for f in range(frames):
                for d in usable:
                    idx = start + f * dirs + DIR_INDEX[d]
                    box = tile_box(idx, cols, tile_w, tile_h)
                    coords = mirrored if d in MIRROR_DIRS else mask

                    before = sheet.crop(box) if args.preview else None
                    if args.dry_run:
                        # Count without mutating.
                        n = sum(
                            1 for (mx, my) in coords
                            if 0 <= mx < tile_w and 0 <= my < tile_h
                            and sheet_px[box[0] + mx, box[1] + my][3] != 0
                        )
                    else:
                        n = clear_pixels(sheet_px, box, coords, tile_w, tile_h)

                    total_cleared += n
                    label = d[:1].upper() if frames == 1 else f"{d[:1].upper()}f{f+1}"
                    parts.append(f"{label}:{n}")
                    if args.preview:
                        row_cells.append((before, sheet.crop(box), coords))

            touched += 1
            flag = "  <-- nothing to clear" if all(
                p.endswith(":0") for p in parts) else ""
            print(f"  {name:<12} dirs={dirs} frames={frames}  "
                  f"{' '.join(parts)}{flag}")
            if args.preview and row_cells:
                preview_rows.append((name, row_cells))

    print()
    verb = "would clear" if args.dry_run else "cleared"
    print(f"{touched} state(s) processed, {verb} {total_cleared} pixel(s).")

    if missing:
        print(f"\nNot found in this file ({len(missing)}): {', '.join(missing)}",
              file=sys.stderr)
    if no_dirs:
        print(f"\nSkipped, lacks the requested dirs ({len(no_dirs)}): "
              f"{', '.join(no_dirs)}", file=sys.stderr)

    if args.preview and preview_rows:
        canvas = build_preview(preview_rows, tile_w, tile_h)
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(args.preview)
        print(f"\nPreview written to {args.preview}")
        print("  Per row: [before | after] for each dir/frame. On 'before', "
              "red = pixels being removed, magenta = already transparent.")

    if args.dry_run:
        print("\nDry run — no file written.")
        return

    if args.in_place:
        backup = args.dmi.with_suffix(args.dmi.suffix + ".bak")
        shutil.copy2(args.dmi, backup)
        out_path = args.dmi
        print(f"\nBackup: {backup}")
    else:
        out_path = args.output or args.dmi.with_name(
            args.dmi.stem + "_fixed" + args.dmi.suffix)

    pnginfo = PngImagePlugin.PngInfo()
    # zip=True writes a compressed zTXt, and Pillow places pnginfo chunks
    # before IDAT — required, BYOND rejects a Description that follows IDAT.
    pnginfo.add_text("Description", description, zip=True)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, "PNG", pnginfo=pnginfo)
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    try:
        main()
    except DmiFormatError as exc:
        raise SystemExit(f"error: {exc}")
