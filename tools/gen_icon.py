"""Draw the app icon: a spider-web mask on a dark slate ground.

Everything is computed in polar coordinates so it stays cheap at 1024px: web
strands are "distance from this pixel to the nearest radial spoke / sagging
ring", not a list of line segments.

Writes two things from one drawing:
  * mcu_tracker/assets/icon/app_icon.png  - 1024px, opaque (iOS rejects alpha)
  * the apple-touch-icon data URI inside mcu-tracker.html - 180px

No third-party dependencies: zlib and some trigonometry.

Usage:  python tools/gen_icon.py
"""

import base64
import math
import os
import re
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG_DST = os.path.join(ROOT, "mcu_tracker", "assets", "icon", "app_icon.png")
HTML_DST = os.path.join(ROOT, "mcu-tracker.html")

BG = (0x1C, 0x25, 0x31)
BG_EDGE = (0x14, 0x1B, 0x25)
WEB = (0xC0, 0x55, 0x59)
EYE_FILL = (0xFF, 0xFF, 0xFF)
EYE_LINE = (0xE7, 0x61, 0x5F)

# Everything below is expressed on a 180-unit grid, then scaled to the output.
GRID = 180.0
CENTRE = (90.0, 84.0)

SPOKES = 8
RINGS = (26.0, 50.0, 74.0, 98.0, 122.0)
RING_SAG = 0.17          # how far a strand dips between two spokes
WEB_STROKE = 1.5

# Two almond eyes, mirrored. Angles tilt the outer end upward.
EYES = (
    {"c": (58.0, 92.0), "w": 27.0, "h": 15.5, "rot": -17.0},
    {"c": (122.0, 92.0), "w": 27.0, "h": 15.5, "rot": 17.0},
)
EYE_STROKE = 2.6


def mix(c1, c2, t):
    if t <= 0:
        return c1
    if t >= 1:
        return c2
    return (
        int(round(c1[0] + (c2[0] - c1[0]) * t)),
        int(round(c1[1] + (c2[1] - c1[1]) * t)),
        int(round(c1[2] + (c2[2] - c1[2]) * t)),
    )


def chunk(tag, data):
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def eye_distance(px, py, eye):
    """Signed distance to the almond outline: negative inside, positive outside."""
    a = math.radians(eye["rot"])
    dx, dy = px - eye["c"][0], py - eye["c"][1]
    u = dx * math.cos(a) + dy * math.sin(a)
    v = -dx * math.sin(a) + dy * math.cos(a)

    t = abs(u) / eye["w"]
    if t >= 1.0:
        # Past the pointed corner: fall back to distance from the tip.
        tip = eye["w"] if u > 0 else -eye["w"]
        return math.hypot(u - tip, v)
    # Exponent below 1 pulls the ends into points rather than an ellipse's curve.
    half = eye["h"] * math.pow(1.0 - t * t, 0.72)
    return abs(v) - half


def draw(size):
    k = size / GRID
    cx, cy = CENTRE[0] * k, CENTRE[1] * k
    step = 2.0 * math.pi / SPOKES
    stroke = WEB_STROKE * k
    feather = 1.15 * k
    rings = [r * k for r in RINGS]
    eyes = [
        {
            "c": (e["c"][0] * k, e["c"][1] * k),
            "w": e["w"] * k,
            "h": e["h"] * k,
            "rot": e["rot"],
        }
        for e in EYES
    ]
    eye_stroke = EYE_STROKE * k
    half_diag = math.hypot(size, size) / 2.0

    rows = bytearray()
    for y in range(size):
        rows.append(0)  # PNG filter type: none
        py = y + 0.5
        for x in range(size):
            px = x + 0.5
            dx, dy = px - cx, py - cy
            r = math.hypot(dx, dy)

            # vignette so the corners sit back a little
            col = mix(BG, BG_EDGE, min(1.0, (r / half_diag) ** 2 * 1.15))

            theta = math.atan2(dy, dx)
            # angle to the nearest spoke, and the same as a fraction of a gap
            off = theta - step * round(theta / step)
            best = abs(off) * r          # arc-length distance to that spoke

            # sagging rings: full radius on a spoke, dipping between them
            phase = (1.0 - math.cos(2.0 * math.pi * off / step)) * 0.5
            for rr in rings:
                d = abs(r - rr * (1.0 - RING_SAG * phase))
                if d < best:
                    best = d

            if best < stroke + feather:
                col = mix(col, WEB, max(0.0, min(1.0, (stroke - best) / feather + 1.0)))

            for eye in eyes:
                d = eye_distance(px, py, eye)
                if d < eye_stroke + feather:
                    if d <= 0.0:
                        col = mix(col, EYE_FILL, min(1.0, -d / feather + 1.0))
                    if abs(d) < eye_stroke:
                        col = mix(col, EYE_LINE, min(1.0, (eye_stroke - abs(d)) / feather))
                    elif d > 0.0:
                        col = mix(col, EYE_LINE, max(0.0, (eye_stroke + feather - d) / feather))
                    break

            rows += bytes(col)

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(rows), 9))
        + chunk(b"IEND", b"")
    )


def main():
    big = draw(1024)
    os.makedirs(os.path.dirname(PNG_DST), exist_ok=True)
    with open(PNG_DST, "wb") as fh:
        fh.write(big)
    print("wrote %s - 1024x1024, %d bytes" % (os.path.relpath(PNG_DST, ROOT), len(big)))

    small = draw(180)
    uri = "data:image/png;base64," + base64.b64encode(small).decode()

    html = open(HTML_DST, encoding="utf-8").read()
    new_html, count = re.subn(
        r'(<link rel="apple-touch-icon" href=")[^"]*(")',
        lambda m: m.group(1) + uri + m.group(2),
        html,
        count=1,
    )
    if count != 1:
        raise SystemExit("could not find the apple-touch-icon link in mcu-tracker.html")
    open(HTML_DST, "w", encoding="utf-8").write(new_html)
    print("patched apple-touch-icon in mcu-tracker.html - 180x180, %d bytes" % len(small))


if __name__ == "__main__":
    main()


# ---------------------------------------------------------------------------
# To use your own image instead of this drawing:
#   1. Save it as mcu_tracker/assets/icon/app_icon.png (1024x1024, no alpha)
#      and stop running this script, which would overwrite it.
#   2. Embed the same file in the web page:
#          python -c "import base64;print('data:image/png;base64,'+base64.b64encode(open('icon.png','rb').read()).decode())"
#      then paste the output into the apple-touch-icon href in mcu-tracker.html.
#   3. For the Flutter app: dart run flutter_launcher_icons
# ---------------------------------------------------------------------------
