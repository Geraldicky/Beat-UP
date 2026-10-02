# Beat UP! v17.4.45 — Illustrated Artwork Pass

## Scope
Visual-only song artwork overhaul on top of v17.4.44. Gameplay, chart timing, note directions, judgement logic, difficulty data, and choreography are unchanged.

## Artwork overhaul
- Added/replaced illustrated artwork for all 39 songs.
- Every one of the 117 charts now explicitly references `res://assets/song_backgrounds/<song_id>.png`.
- The same per-song artwork now reaches song select, launch transition, gameplay backdrop, and results.
- Existing bland/line-art backgrounds are replaced.
- Songs that previously had no dedicated artwork now receive one.
- Runtime artwork files are normalized to 1600x900 PNG.

## Art direction
- Modern illustrated rhythm-game / game-key-art treatment.
- Strong focal subjects and silhouettes for song-card readability.
- Broader visual families across cyber, cosmic, fiery, dreamlike, urban, fantasy, monochrome, and kinetic scenes.
- This is the first illustrated art-direction pass for playtest feedback before final per-song refinement.

## Technical
- Project version: 17.4.45.
- 39 song artwork PNGs.
- 117/117 chart artwork paths populated.
- Stale artwork `.png.import` files removed so Godot rebuilds imports.
- No chart-generation/gameplay logic changed.
- No build/manifest JSON added.
