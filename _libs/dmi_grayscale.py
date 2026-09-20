#!/usr/bin/env python3
"""
dmi_grayscale.py — Convert every icon state in a BYOND .dmi file to greyscale.

A .dmi file is just a PNG sprite sheet with an extra zTXt chunk (keyword
"Description") that tells BYOND how to slice the sheet into icon states,
directions, and animation frames. Since that chunk only describes *layout*,
not color, we don't need to parse individual states at all: converting the
whole pixel sheet to greyscale converts every state, direction, and frame at
once. We just have to preserve the Description chunk byte-for-byte (and make
sure it's written before the image data), or BYOND won't be able to read the
file anymore.

Requires Pillow:  pip install Pillow

Usage:
    Single file:
        python3 dmi_grayscale.py path/to/icon.dmi
        python3 dmi_grayscale.py path/to/icon.dmi -o path/to/icon_gray.dmi

    Whole folder (all .dmi files, recursively):
        python3 dmi_grayscale.py path/to/icons_dir -o path/to/out_dir

    Choose how RGB is combined into grey (default: luminosity, the
    perceptually-weighted method — closer to how the eye sees brightness):
        python3 dmi_grayscale.py icon.dmi --method average
"""

import argparse
import sys
from pathlib import Path

from PIL import Image, PngImagePlugin


def grayscale_dmi(in_path: Path, out_path: Path, method: str = "luminosity") -> None:
    """Convert one .dmi (PNG) file's pixels to greyscale, preserving alpha
    and the BYOND Description metadata chunk."""
    img = Image.open(in_path)
    description = img.info.get("Description")  # raw DMI state/frame metadata

    img = img.convert("RGBA")
    r, g, b, a = img.split()

    if method == "luminosity":
        # ITU-R 601 luma weighting — what Pillow's "L" conversion uses.
        gray = Image.merge("RGB", (r, g, b)).convert("L")
    elif method == "average":
        import numpy as np

        arr = np.array(Image.merge("RGB", (r, g, b)), dtype=np.uint16)
        gray = Image.fromarray(arr.mean(axis=2).astype("uint8"), mode="L")
    else:
        raise ValueError(f"Unknown method: {method}")

    gray_rgba = Image.merge("RGBA", (gray, gray, gray, a))

    pnginfo = None
    if description is not None:
        pnginfo = PngImagePlugin.PngInfo()
        # zip=True writes a compressed zTXt chunk, matching what BYOND itself
        # writes, and Pillow places pnginfo chunks before IDAT (required —
        # BYOND fails to read the file if Description comes after IDAT).
        pnginfo.add_text("Description", description, zip=True)
    else:
        print(f"  warning: no DMI 'Description' metadata found in {in_path.name}; "
              f"converting pixels only", file=sys.stderr)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    gray_rgba.save(out_path, "PNG", pnginfo=pnginfo)


def collect_dmi_files(input_path: Path):
    if input_path.is_file():
        return [input_path]
    return sorted(input_path.rglob("*.dmi"))


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                      formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path, help="A .dmi file or a directory of .dmi files")
    parser.add_argument("-o", "--output", type=Path, default=None,
                         help="Output file (single input) or output directory (folder input). "
                              "Defaults to '<name>_gray.dmi' next to the input, or an "
                              "'_gray' suffixed folder for directories.")
    parser.add_argument("--method", choices=["luminosity", "average"], default="luminosity",
                         help="How to combine R/G/B into grey (default: luminosity)")
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"Input not found: {args.input}")

    files = collect_dmi_files(args.input)
    if not files:
        sys.exit(f"No .dmi files found at: {args.input}")

    is_dir_mode = args.input.is_dir()

    for f in files:
        if is_dir_mode:
            rel = f.relative_to(args.input)
            out_root = args.output or args.input.with_name(args.input.name + "_gray")
            out_path = out_root / rel
        else:
            out_path = args.output or f.with_name(f.stem + "_gray" + f.suffix)

        print(f"Converting {f} -> {out_path}")
        grayscale_dmi(f, out_path, method=args.method)

    print(f"Done. {len(files)} file(s) converted.")


if __name__ == "__main__":
    main()
