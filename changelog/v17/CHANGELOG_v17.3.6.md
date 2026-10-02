# Beat UP! v17.3.6 — 12-Song Expansion Batch

## Added songs
- Death by Glamour — Toby Fox
- Battle Against a True Hero — Toby Fox
- Moonlight Sonata 3rd Movement (meganeko Remix) — meganeko
- Blue Zenith — xi
- Exit This Earth's Atomosphere — Camellia
- Septette for the Dead Princess — ZUN
- Aleph-0 — LeaF
- Night of Nights — COOL&CREATE / beatMARIO
- Spider Dance — Toby Fox
- U.N. Owen Was Her? — ZUN
- Necrofantasia — ZUN
- Oshama Scramble! — t+pazolite

## Audio import
- Renamed all uploaded files to Godot-safe snake_case filenames.
- Normalized the 12 imported tracks to Ogg Vorbis for consistent Godot playback.
- Added them under `music/imported/`.

## Charts
- Added NORMAL / HARD / MASTER charts for every new song: 36 new chart files total.
- Existing 39 chart JSON files were left untouched.
- Chart generation uses audio onset/energy analysis with Beat UP!'s existing difficulty contracts and two-finger direction vocabulary.
- NORMAL stays direction + SPACE only.
- HARD adds sparse Reverse notes.
- MASTER adds denser patterns, Reverse, and sparse Bomb notes.
- Aleph-0 uses adaptive transient timing because the uploaded source has strong tempo changes instead of one stable BPM grid.

## Song backgrounds
- Added a new 1600×900 abstract Beat UP! background for every new track so the Song Library has complete visual coverage.
- Added per-song accent colors to the Song Library browser.

## Versioning / packaging
- Project version bumped to `17.3.6`.
- Startup label updated to `BEAT UP! / SYSTEM 17.3.6`.
- Changelog remains inside `changelog/`.
- `VALIDATION*.txt` files are not included.
