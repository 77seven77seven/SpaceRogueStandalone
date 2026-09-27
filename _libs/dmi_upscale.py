#!/usr/bin/env python3
"""
upscale_dmi.py - Upscale a BYOND .dmi icon file (e.g. 32x32 -> 64x64).

A .dmi file is a PNG sprite sheet plus a compressed zTXt chunk
(keyword "Description") that tells BYOND how to slice it into states,
directions and animation frames.

Every other line of the description (state names, dirs, frames, delays,
loop flags, etc.) is passed through untouched.

Requires Pillow:  pip install pillow

Usage:
    python upscale_dmi.py input.dmi
    python upscale_dmi.py input.dmi output.dmi
    python upscale_dmi.py input.dmi --scale 4
"""

import argparse
import io
import os
import re
import struct
import sys
import zlib

try:
    from PIL import Image
except ImportError:
    sys.exit("This script requires Pillow. Install it with:  pip install pillow")

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
DMI_KEYWORD = "Description"
TEXT_CHUNK_TYPES = (b"tEXt", b"zTXt", b"iTXt")

DIMENSION_RE = re.compile(r"^(\s*)(width|height)\s*=\s*(\d+)\s*$")
STATE_RE = re.compile(r'^state\s*=\s*"((?:[^"\\]|\\.)*)"\s*$')
KEYVAL_RE = re.compile(r"^(\w+)\s*=\s*(.*)$")

FILTERS = ("nearest", "bilinear", "bicubic", "lanczos", "box", "hamming")


# ---------------------------------------------------------------------------
# PNG chunk helpers
# ---------------------------------------------------------------------------

def iter_png_chunks(png_bytes):
    """Yield (chunk_type, chunk_data) for every chunk in a PNG byte string."""
    if png_bytes[:8] != PNG_SIGNATURE:
        raise ValueError("not a PNG file (bad signature)")
    pos = 8
    while pos + 8 <= len(png_bytes):
        (length,) = struct.unpack_from(">I", png_bytes, pos)
        ctype = png_bytes[pos + 4:pos + 8]
        cdata = png_bytes[pos + 8:pos + 8 + length]
        yield ctype, cdata
        pos += 12 + length  # length field + type + data + CRC
        if ctype == b"IEND":
            return
    raise ValueError("PNG is truncated (no IEND chunk)")


def rebuild_png(chunks):
    """Re-serialize (chunk_type, chunk_data) pairs into PNG bytes, fixing CRCs."""
    out = bytearray(PNG_SIGNATURE)
    for ctype, cdata in chunks:
        out += struct.pack(">I", len(cdata))
        out += ctype
        out += cdata
        out += struct.pack(">I", zlib.crc32(ctype + cdata) & 0xFFFFFFFF)
    return bytes(out)


def strip_description_chunks(png_bytes):
    """Defensively drop any existing DMI 'Description' text chunks."""
    kept = []
    for ctype, cdata in iter_png_chunks(png_bytes):
        if ctype in TEXT_CHUNK_TYPES:
            keyword = cdata.partition(b"\x00")[0].decode("latin-1", "replace")
            if keyword == DMI_KEYWORD:
                continue
        kept.append((ctype, cdata))
    return rebuild_png(kept)


def build_dmi_ztxt(description_text):
    """Build a zTXt ('Description') chunk payload in the layout BYOND uses."""
    compressed = zlib.compress(description_text.encode("latin-1"), 9)
    payload = DMI_KEYWORD.encode("latin-1") + b"\x00" + b"\x00" + compressed
    return (b"zTXt", payload)


def insert_before_idat(png_bytes, new_chunk):
    chunks = list(iter_png_chunks(png_bytes))
    for i, (ctype, _) in enumerate(chunks):
        if ctype == b"IDAT":
            chunks.insert(i, new_chunk)
            return rebuild_png(chunks)
    raise ValueError("could not find IDAT chunk in output PNG")


# ---------------------------------------------------------------------------
# DMI description handling
# ---------------------------------------------------------------------------

def extract_dmi_description(png_bytes):
    """Find the zTXt 'Description' chunk and decompress it."""
    for ctype, cdata in iter_png_chunks(png_bytes):
        if ctype != b"zTXt":
            continue
        keyword, _, rest = cdata.partition(b"\x00")
        if keyword.decode("latin-1", "replace") != DMI_KEYWORD:
            continue
        if rest[:1] != b"\x00":  # compression method must be 0 (zlib)
            raise ValueError("unsupported zTXt compression method")
        try:
            raw = zlib.decompress(rest[1:])
        except zlib.error as exc:
            raise ValueError(f"could not decompress DMI description: {exc}")
        # latin-1 maps bytes 1:1, so re-encoding later reproduces the
        # original bytes exactly, even for odd state names.
        return raw.decode("latin-1")
    raise ValueError("no DMI 'Description' zTXt chunk found - "
                     "this does not look like a .dmi file")


def scale_description(description, factor):
    """Scale only the global width/height values; leave all other lines alone."""
    newline = "\r\n" if "\r\n" in description else "\n"
    seen = set()
    out = []
    for line in description.split(newline):
        m = DIMENSION_RE.match(line)
        if m:
            indent, key, value = m.groups()
            seen.add(key)
            out.append(f"{indent}{key} = {int(value) * factor}")
        else:
            out.append(line)
    if not {"width", "height"} <= seen:
        raise ValueError("DMI description is missing width/height")
    return newline.join(out)


def summarize(description):
    """Minimal parser, just enough to report what's inside the file."""
    width = height = None
    states = []
    current = None
    for line in description.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        m = DIMENSION_RE.match(line)
        if m:
            _, key, value = m.groups()
            if key == "width":
                width = int(value)
            else:
                height = int(value)
            continue
        m = STATE_RE.match(stripped)
        if m:
            current = {"name": m.group(1), "dirs": 1, "frames": 1}
            states.append(current)
            continue
        m = KEYVAL_RE.match(stripped)
        if m and current and m.group(1) in ("dirs", "frames"):
            current[m.group(1)] = int(m.group(2))
    return width, height, states


# ---------------------------------------------------------------------------
# Main conversion
# ---------------------------------------------------------------------------

def get_resample(name):
    """Map a filter name to a Pillow resampling constant (any Pillow version)."""
    namespace = getattr(Image, "Resampling", Image)
    return getattr(namespace, name.upper())


def upscale_dmi(in_path, out_path, scale, filter_name):
    with open(in_path, "rb") as fh:
        original = fh.read()

    description = extract_dmi_description(original)
    frame_w, frame_h, states = summarize(description)
    if frame_w is None or frame_h is None:
        raise ValueError("DMI description is missing width/height")

    img = Image.open(in_path)
    img.load()
    img_w, img_h = img.size
    if (img_w, img_h) != (frame_w, frame_h):
        print(f"warning: image is {img_w}x{img_h} but DMI metadata says "
              f"{frame_w}x{frame_h}; result may not slice correctly in BYOND",
              file=sys.stderr)

    new_img = img.resize((img_w * scale, img_h * scale), get_resample(filter_name))
    buf = io.BytesIO()
    new_img.save(buf, format="PNG")

    new_description = scale_description(description, scale)
    png = strip_description_chunks(buf.getvalue())
    png = insert_before_idat(png, build_dmi_ztxt(new_description))

    # Round-trip check: output must still be a valid DMI.
    if extract_dmi_description(png) != new_description:
        raise RuntimeError("internal error: description did not survive round-trip")

    with open(out_path, "wb") as fh:
        fh.write(png)

    total_frames = sum(s["dirs"] * s["frames"] for s in states)
    print(f"input:  {in_path}")
    print(f"        {img_w}x{img_h} sheet, {frame_w}x{frame_h} frames, "
          f"{len(states)} state(s), {total_frames} frame(s)")
    print(f"output: {out_path}")
    print(f"        {img_w * scale}x{img_h * scale} sheet, "
          f"{frame_w * scale}x{frame_h * scale} frames (filter: {filter_name})")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Upscale a BYOND .dmi icon file while keeping its "
                    "state/direction/frame metadata valid.")
    parser.add_argument("input", help="source .dmi file")
    parser.add_argument("output", nargs="?",
                        help="destination file (default: <input>_x<scale>.dmi)")
    parser.add_argument("--scale", type=int, default=2,
                        help="upscale factor (default: 2, i.e. 32x32 -> 64x64)")
    parser.add_argument("--filter", default="nearest", choices=FILTERS,
                        help="resampling filter (default: nearest, which is "
                             "what you want for pixel art)")
    args = parser.parse_args(argv)

    if args.scale < 1:
        parser.error("--scale must be at least 1")

    out_path = args.output
    if out_path is None:
        root, ext = os.path.splitext(args.input)
        out_path = f"{root}_x{args.scale}{ext or '.dmi'}"

    try:
        upscale_dmi(args.input, out_path, args.scale, args.filter)
    except (OSError, ValueError, RuntimeError) as exc:
        sys.exit(f"error: {exc}")


if __name__ == "__main__":
    main()