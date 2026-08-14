"""Copy the tracker into docs/ so GitHub Pages can serve it.

GitHub Pages publishes the docs/ folder of the main branch as a real https site.
That gives the page a proper origin, which is what makes localStorage persist
and what lets Safari honour the apple-touch-icon on Add to Home Screen.

docs/index.html is GENERATED. Edit mcu-tracker.html instead. To stop a stray
edit from being silently destroyed, this script records a hash of what it wrote
and refuses to overwrite anything that has changed since.

Usage:
    python tools/build_site.py
    python tools/build_site.py --force    # discard manual edits to docs/
"""

import hashlib
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "mcu-tracker.html")
OUT_DIR = os.path.join(ROOT, "docs")
DST = os.path.join(OUT_DIR, "index.html")
HASH_FILE = os.path.join(OUT_DIR, ".build-hash")

BANNER = (
    "<!-- GENERATED FILE - do not edit.\n"
    "     Edit ../mcu-tracker.html, then run: python tools/build_site.py -->\n"
)

# Android decides whether to offer a real installed app (own icon, no address
# bar) based on this. iOS ignores it and uses the meta tags instead. It only
# goes into the hosted copy — mcu-tracker.html stays a single portable file.
MANIFEST = """{
  "name": "MCU Watch Tracker",
  "short_name": "MCU Tracker",
  "description": "All 47 MCU entries in release order, ticked off as you watch.",
  "start_url": ".",
  "scope": ".",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#1D2D3A",
  "theme_color": "#1D2D3A",
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any" },
    { "src": "icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
"""

MANIFEST_LINK = '<link rel="manifest" href="manifest.webmanifest">\n'


def digest(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def render():
    source = open(SRC, encoding="utf-8").read()

    # The hosted copy gets a manifest link; the portable file does not.
    anchor = '<link rel="apple-touch-icon"'
    if MANIFEST_LINK.strip() not in source and anchor in source:
        source = source.replace(anchor, MANIFEST_LINK + anchor, 1)

    # Slip the banner in after the doctype so it is the first thing anyone sees.
    marker = "<!doctype html>\n"
    if source.startswith(marker):
        return marker + BANNER + source[len(marker):]
    return BANNER + source


def main():
    force = "--force" in sys.argv
    output = render()

    os.makedirs(OUT_DIR, exist_ok=True)

    if os.path.exists(DST) and os.path.exists(HASH_FILE) and not force:
        previous = open(HASH_FILE, encoding="utf-8").read().strip()
        current = digest(open(DST, encoding="utf-8").read())
        if current != previous:
            print("REFUSING TO OVERWRITE: docs/index.html has been edited by hand.")
            print()
            print("  That file is generated. Your changes belong in mcu-tracker.html,")
            print("  otherwise they are lost on the next build.")
            print()
            print("  Move them across, then run this again. To throw them away:")
            print("      python tools/build_site.py --force")
            return 1

    with open(DST, "w", encoding="utf-8") as fh:
        fh.write(output)
    with open(HASH_FILE, "w", encoding="utf-8") as fh:
        fh.write(digest(output))

    with open(os.path.join(OUT_DIR, "manifest.webmanifest"), "w", encoding="utf-8") as fh:
        fh.write(MANIFEST)

    # Pages runs Jekyll by default, which ignores files it considers special.
    open(os.path.join(OUT_DIR, ".nojekyll"), "w").close()

    print("wrote %s (%d bytes)" % (os.path.relpath(DST, ROOT), len(output.encode("utf-8"))))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
