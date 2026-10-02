# Beat UP! v17.4.46 — Background Restore Pass

## Summary
- Reverted the v17.4.45 illustrated-artwork experiment.
- Restored the original Beat UP!-native background direction.
- Applied minimal-style native backgrounds across the full 39-song library.
- Reused the provided legacy backgrounds for the original 14 songs.
- Created matching Beat UP!-style backgrounds for the remaining 25 songs so the whole library now shares one consistent visual language.
- Charts, choreography, timing, gameplay, UI flow, and song metadata were not changed.

## Technical notes
- Background file paths remain `res://assets/song_backgrounds/<song_id>.png`.
- All `.png.import` files under `assets/song_backgrounds/` were removed so Godot can reimport the updated assets cleanly.
- A preview sheet is included at `changelog/V17.4.46_BACKGROUND_PREVIEW.jpg`.
