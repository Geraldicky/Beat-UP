# Beat UP! v17.3.5 — Song Background Refresh + Text Hierarchy Pass

## Summary
This pass focuses on restoring stronger visual hierarchy in the song list while also refreshing the per-song background art set.

## Changes

### 1) Unselected song card text hierarchy refined
- Reduced brightness on **unselected song card text** so selected cards remain the clear focal point.
- Preserved full readability while lowering emphasis on non-selected entries.
- Selected card titles/subtitles now restore their original brighter emphasis.
- Distance from the selected card also subtly affects non-selected text emphasis for smoother hierarchy.

### 2) Background art regenerated for each song
Rebuilt the song background set with new abstract art direction for every available song:
- `2_starting_over`
- `3_bow_for_me`
- `5_flying_temple`
- `aresenes_bazaar`
- `ascend`
- `bad_apple`
- `can_can_audition`
- `diana_boncheva_feat_banya_beethoven_virus_full_version`
- `freedom_dive`
- `megalovania`
- `orpheus_can_can`
- `the_lab`
- `vessel`

Design goals:
- cleaner readability under song-card overlays
- stronger identity per song through color and motif differences
- consistent Beat UP! abstract motion-language across the whole library

### 3) Packaging cleanup
- Removed all `VALIDATION*.txt` files from the deliverable.
- Continued using the dedicated `changelog/` folder for changelog files.

## Notes
- This is an art/readability pass, so the main impact is visual polish rather than gameplay changes.
- Godot should reimport updated background PNG files automatically when the project is opened.
