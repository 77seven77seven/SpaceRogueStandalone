"""Generates triangle.png, noise.png (library) and the demo tiles.

    python3 make_assets.py            # 512px sprites, matching SHADOWCAST_ICON_SIZE 512
    python3 make_assets.py 1024       # crisper far edges; also #define SHADOWCAST_ICON_SIZE 1024
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.join(HERE, "..", "lib", "shadowcast")
DEMO = os.path.join(HERE, "..", "demo")
S = int(sys.argv[1]) if len(sys.argv) > 1 else 512


def triangle(size, ss=8):
    """Black right triangle, opaque where x + y <= size (x, y from the bottom-left),
    with exact-ish 8x8 supersampled anti-aliasing on the hypotenuse."""
    c = (np.arange(size * ss) + .5) / ss
    xx, yy = np.meshgrid(c, c)
    cov = ((xx + yy) <= size).astype(np.float32)
    cov = cov.reshape(size, ss, size, ss).mean(axis=(1, 3))      # rows from the bottom
    alpha = np.flipud(cov)                                       # PNG row 0 is the top
    img = np.zeros((size, size, 4), np.uint8)
    img[..., 3] = np.round(alpha * 255)
    return Image.fromarray(img, "RGBA")


def noise(size, cells=20, amp=110, seed=7):
    """Smooth RG noise centred on 128 (= no displacement), fully opaque."""
    rng = np.random.default_rng(seed)
    chans = []
    for _ in range(2):
        g = rng.random((cells + 3, cells + 3)).astype(np.float32)
        im = Image.fromarray(g, "F").resize((size + size * 3 // cells,) * 2, Image.BICUBIC)
        a = np.asarray(im)[size // cells: size // cells + size, size // cells: size // cells + size]
        a = (a - a.min()) / (a.max() - a.min())
        chans.append(np.clip(128 + (a - .5) * 2 * amp, 0, 255))
    out = np.zeros((size, size, 4), np.uint8)
    out[..., 0], out[..., 1], out[..., 2], out[..., 3] = chans[0], chans[1], 128, 255
    return Image.fromarray(out, "RGBA")


def tile(fill, line, inner=None):
    im = Image.new("RGBA", (32, 32), fill)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 31, 31], outline=line)
    if inner:
        d.rectangle([3, 3, 28, 28], outline=inner)
    return im


def player():
    ss = 8
    im = Image.new("RGBA", (32 * ss, 32 * ss), (0, 0, 0, 0))
    ImageDraw.Draw(im).ellipse([6 * ss, 6 * ss, 26 * ss - 1, 26 * ss - 1], fill=(255, 235, 20, 255))
    return im.resize((32, 32), Image.LANCZOS)


if __name__ == "__main__":
    triangle(S).save(os.path.join(LIB, "triangle.png"))
    noise(512).save(os.path.join(LIB, "noise.png"))
    tile((150, 150, 150, 255), (128, 128, 128, 255)).save(os.path.join(DEMO, "floor.png"))
    tile((58, 56, 80, 255), (30, 30, 52, 255), (86, 84, 118, 255)).save(os.path.join(DEMO, "wall.png"))
    player().save(os.path.join(DEMO, "player.png"))
    print("wrote triangle.png (%d), noise.png (512) and demo tiles" % S)
