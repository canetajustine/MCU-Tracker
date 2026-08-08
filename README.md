# MCU Watch Tracker

All 47 MCU entries in release order, as a checklist you can actually tick off.
Built from a watch-guide poster, with the poster's status tags and both lore
columns carried over.

There are two ways to use it on an iPhone. Both are free.

| | Web (GitHub Pages) | Native app (Flutter) |
| --- | --- | --- |
| Cost | Free | Free |
| Setup | Push to GitHub, flip on Pages | Build in CI, sideload over USB |
| Home screen icon | Yes | Yes |
| Progress persists | Yes | Yes |
| Needs a cable | No | Yes, at least once |
| Expires | Never | Every 7 days on a free Apple ID |

The web route does everything most people want. The native app exists for when
you'd rather have a real app than a bookmark.

## Files

| Path | What it is |
| --- | --- |
| `mcu-tracker.html` | **The source of truth.** Standalone, offline, no dependencies. |
| `docs/index.html` | Copy of the above, served by GitHub Pages. Generated. |
| `mcu-tracker-web.html` | Variant for publishing as a Claude artifact. Generated. |
| `mcu_tracker/` | The Flutter app. See its own README. |
| `tools/` | Generators. Never edit generated files by hand. |

Change `mcu-tracker.html`, then regenerate everything downstream:

```bash
python tools/build_site.py && python tools/gen_data.py
```

## Putting the web version on your iPhone

1. Create a free GitHub account and a **public** repository.
2. Push this project to it.
3. In the repo: **Settings → Pages → Source: Deploy from a branch**, pick
   **main** and the **/docs** folder, then Save.
4. Wait about a minute. Your tracker is at
   `https://YOUR-USERNAME.github.io/YOUR-REPO/`.
5. Open that in **Safari** on the iPhone, then **Share → Add to Home Screen**.

You get the checkmark icon, a full-screen launch with no browser bar, and
progress that persists — because it's a real origin rather than a local file or
an embedded frame.

The page never makes a network request after loading, so it keeps working with
no signal.

## Building the native app

See [`mcu_tracker/README.md`](mcu_tracker/README.md). The short version: GitHub
Actions builds an unsigned `.ipa` on a macOS runner, and you sign and install it
from the PC with Sideloadly or AltStore over USB.

## Notes on the data

The poster had three slips, corrected here: two entries numbered 7, two numbered
45, and *Age of Ultron* dated 2013. Titles the poster abbreviated for space use
their full official names.
