"""Copy the tracker into docs/ so GitHub Pages can serve it.

GitHub Pages publishes the docs/ folder of the main branch as a real https site.
That gives the page a proper origin, which is what makes localStorage persist
and what lets Safari honour the apple-touch-icon on Add to Home Screen.

Usage:  python tools/build_site.py
"""

import os
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "mcu-tracker.html")
DST = os.path.join(ROOT, "docs", "index.html")


def main():
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    shutil.copyfile(SRC, DST)

    # Tell Pages not to run the file through Jekyll, which would otherwise
    # ignore anything it considers a special filename.
    open(os.path.join(ROOT, "docs", ".nojekyll"), "w").close()

    print("wrote %s (%d bytes)" % (os.path.relpath(DST, ROOT), os.path.getsize(DST)))


if __name__ == "__main__":
    main()
