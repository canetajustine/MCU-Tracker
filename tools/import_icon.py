"""Turn a supplied image into the app icon, for web and for Flutter.

iOS applies its own rounded-corner mask to an app icon, so the artwork has to
bleed to the edges of the square. A source image with a white margin around a
rounded badge would end up with white slivers in the corners. This trims the
margin and floods the leftover corner background with the badge's own colour,
so the mask has something dark to cut into.

Writes:
  * mcu_tracker/assets/icon/app_icon.png  - 1024px, opaque
  * the apple-touch-icon data URI inside mcu-tracker.html - 180px

Usage:  python tools/import_icon.py <path-to-image>
"""

import base64
import io
import os
import re
import sys

from PIL import Image, ImageChops, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG_DST = os.path.join(ROOT, "mcu_tracker", "assets", "icon", "app_icon.png")
HTML_DST = os.path.join(ROOT, "mcu-tracker.html")

# Generous: the seed is white, and the artwork's dark navy is ~200 away from
# it, so a high threshold eats the JPEG halo without touching the badge.
CORNER_TOLERANCE = 120

# How far to crop inside the badge, as a fraction of its width. Enough to lose
# the rounded corner, its outline, and any compression halo, so the artwork
# reaches all four edges — iOS will round it again with its own mask.
INSET = 0.07


def trim_margin(im):
    """Crop away a uniform border of any colour."""
    border = Image.new("RGB", im.size, im.getpixel((0, 0)))
    bbox = ImageChops.difference(im, border).getbbox()
    return im.crop(bbox) if bbox else im


def badge_colour(im):
    """The artwork's dominant dark colour.

    Sampling a fixed spot is fragile — it lands on a web strand or in the
    margin. The most common dark pixel is reliably the badge's own background.
    """
    counts = {}
    for px in im.convert("RGB").getdata():
        if (px[0] + px[1] + px[2]) / 3.0 < 120:
            counts[px] = counts.get(px, 0) + 1
    if not counts:
        return (0x1C, 0x25, 0x31)
    return max(counts.items(), key=lambda kv: kv[1])[0]


def inset_crop(im, frac):
    """Crop inward so the rounded corner and its halo fall outside the frame."""
    w, h = im.size
    dx, dy = int(round(w * frac)), int(round(h * frac))
    return im.crop((dx, dy, w - dx, h - dy))


def flood_corners(im, colour):
    """Replace the background still sitting outside the rounded badge."""
    draw = ImageDraw.Draw(im)
    w, h = im.size
    for xy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        ImageDraw.floodfill(im, xy, colour, thresh=CORNER_TOLERANCE)
    del draw
    return im


def square(im, colour):
    """Pad to a square so nothing is distorted when resized."""
    w, h = im.size
    if w == h:
        return im
    side = max(w, h)
    out = Image.new("RGB", (side, side), colour)
    out.paste(im, ((side - w) // 2, (side - h) // 2))
    return out


def main():
    if len(sys.argv) < 2:
        raise SystemExit("usage: python tools/import_icon.py <path-to-image>")
    src_path = sys.argv[1]

    im = Image.open(src_path).convert("RGB")
    original = im.size

    im = trim_margin(im)
    colour = badge_colour(im)
    im = inset_crop(im, INSET)
    im = flood_corners(im, colour)   # safety net for any light pixels left
    im = square(im, colour)

    os.makedirs(os.path.dirname(PNG_DST), exist_ok=True)
    im.resize((1024, 1024), Image.LANCZOS).save(PNG_DST, "PNG")

    buf = io.BytesIO()
    im.resize((180, 180), Image.LANCZOS).save(buf, "PNG")
    uri = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

    html = open(HTML_DST, encoding="utf-8").read()
    html, count = re.subn(
        r'(<link rel="apple-touch-icon" href=")[^"]*(")',
        lambda m: m.group(1) + uri + m.group(2),
        html,
        count=1,
    )
    if count != 1:
        raise SystemExit("could not find the apple-touch-icon link in mcu-tracker.html")
    open(HTML_DST, "w", encoding="utf-8").write(html)

    print("source      : %s %sx%s" % (os.path.basename(src_path), original[0], original[1]))
    print("trimmed to  : %sx%s, badge colour #%02X%02X%02X" % (im.size + colour))
    print("wrote       : %s (1024px)" % os.path.relpath(PNG_DST, ROOT))
    print("patched     : mcu-tracker.html (180px, %d bytes)" % len(buf.getvalue()))


if __name__ == "__main__":
    main()
