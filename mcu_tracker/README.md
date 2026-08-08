# MCU Tracker

A personal watch tracker for all 47 MCU entries in release order, built to run
natively on iPhone. Progress is stored on the device — no account, no server,
no network access at all.

## What it does

- All 47 titles in the poster's release order, split across the two sagas.
- Tap the checkbox to mark something watched; tap the row to read why it matters
  and how it connects to the bigger story.
- Running count, per-saga tallies, and a "watch next" line that always names the
  first unwatched title.
- Auto / light / dark theme, and a reset behind a confirmation.

## Where things live

| Path | What it is |
| --- | --- |
| `lib/data.dart` | All 47 entries. **Generated** — see below. |
| `lib/store.dart` | Persistence and theme state (`shared_preferences`). |
| `lib/theme.dart` | The poster's palette as a `ThemeExtension`. |
| `lib/main.dart` | The screen and its widgets. |
| `test/widget_test.dart` | 12 tests covering data, toggling, persistence, reset, theme. |
| `assets/icon/app_icon.png` | 1024px app icon source. |

`lib/data.dart` is generated from `../mcu-tracker.html`, which is the single
source of truth for the checklist. Don't hand-edit it — change the HTML, then:

```bash
python tools/gen_data.py
```

The app icon is likewise drawn by a script. To change it, edit and re-run:

```bash
python tools/gen_icon.py
```

then regenerate the iOS icon set:

```bash
dart run flutter_launcher_icons
```

## Developing

```bash
flutter pub get
flutter analyze
flutter test
```

To see it in a browser on Windows without any Apple tooling:

```bash
flutter run -d chrome
```

## Getting it onto an iPhone from Windows

iOS binaries can only be compiled on macOS, so the build happens on a free
GitHub Actions macOS runner and the install happens over USB from the PC.

1. Push this project to a **public** GitHub repository (macOS runner minutes are
   free for public repos; private repos consume a limited monthly quota).
2. Open the **Actions** tab, run **Build iOS (unsigned)**, and download the
   `mcu-tracker-ipa` artifact when it finishes. Unzip it to get `mcu_tracker.ipa`.
3. Install [AltStore or SideStore](https://altstore.io) — AltServer runs on the
   PC, the companion app on the iPhone.
4. Sideload `mcu_tracker.ipa` through AltStore, signing with your Apple ID.

### The catch, stated plainly

A free Apple ID signs apps for **7 days**. After that the app stops opening
until it is re-signed. AltStore refreshes it automatically when the phone is on
the same Wi-Fi as the PC running AltServer, so in practice this is invisible —
until you go a week without being near the PC.

A paid Apple Developer account ($99/year) signs for a year and removes the
refresh entirely. Nothing in this project requires it.

A free Apple ID also allows only about three sideloaded apps at a time.
