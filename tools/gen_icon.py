"""Draw the app icon: a mint checkmark on the poster's navy ground.

Writes a 1024px opaque PNG (iOS rejects alpha in app icons) with no third-party
dependencies — just zlib and some line-distance maths.

Usage:  python tools/gen_icon.py
"""

import math
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DST = os.path.join(ROOT, "mcu_tracker", "assets", "icon", "app_icon.png")

SIZE = 1024

BG_TOP = (0x16, 0x21, 0x3D)
BG_BOT = (0x08, 0x0C, 0x18)
GLOW = (0x2C, 0x3F, 0x66)
MINT = (0x3F, 0xD6, 0x8C)

# Checkmark control points, expressed on a 180-unit grid then scaled.
GRID = 180.0
A = (46.0, 94.0)
B = (76.0, 124.0)
C = (136.0, 58.0)
STROKE = 11.0


def seg_dist(px, py, ax, ay, bx, by):
    """Distance from a point to the segment ab."""
    vx, vy = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    length_sq = vx * vx + vy * vy
    t = 0.0 if length_sq == 0 else max(0.0, min(1.0, (wx * vx + wy * vy) / length_sq))
    return math.hypot(px - (ax + t * vx), py - (ay + t * vy))


def mix(c1, c2, t):
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(3))


def chunk(tag, data):
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def main():
    k = SIZE / GRID
    ax, ay = A[0] * k, A[1] * k
    bx, by = B[0] * k, B[1] * k
    cx, cy = C[0] * k, C[1] * k
    stroke = STROKE * k
    feather = 1.6 * k
    glow_x, glow_y, glow_r = 62 * k, 52 * k, 190 * k

    rows = bytearray()
    for y in range(SIZE):
        rows.append(0)  # PNG filter type: none
        py = y + 0.5
        base = mix(BG_TOP, BG_BOT, y / (SIZE - 1.0))
        for x in range(SIZE):
            px = x + 0.5
            lift = max(0.0, 1.0 - math.hypot(px - glow_x, py - glow_y) / glow_r) * 0.16
            col = mix(base, GLOW, lift)

            dist = min(
                seg_dist(px, py, ax, ay, bx, by),
                seg_dist(px, py, bx, by, cx, cy),
            )
            alpha = max(0.0, min(1.0, (stroke + 0.5 - dist) / feather))
            if alpha > 0:
                col = mix(col, MINT, alpha)
            rows += bytes(col)

    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(rows), 9))
        + chunk(b"IEND", b"")
    )

    os.makedirs(os.path.dirname(DST), exist_ok=True)
    with open(DST, "wb") as fh:
        fh.write(png)
    print("wrote %s - %dx%d, %d bytes" % (os.path.relpath(DST, ROOT), SIZE, SIZE, len(png)))


if __name__ == "__main__":
    main()
