# Beat UP! v17.2.2 — Left Overlay Removal Fix

## Focus
- fix the remaining transparent dark box artifact on the left side of Song Library;
- confirm the issue comes from the custom draw code rather than the background image assets;
- preserve the v17.2 browser rebuild and the v17.2.1 background cleanup.

## Root cause
- `scripts/ui/song_select_visual.gd` was still drawing multiple stacked rectangles from the top-left corner.
- Those rectangles created a fake panel / transparent-box silhouette over the left side of the screen.

## Changes
- Replaced the old nested left-veil rectangle logic in `song_select_visual.gd`.
- Added a proper full-height left-to-center strip gradient instead of stacked corner rectangles.
- Kept only a subtle right-side veil for song-list readability.
- Preserved the cleaned background artwork from v17.2.1.
- Updated version text to `17.2.2`.

## Frozen systems
- No gameplay changes.
- No chart or timing changes.
- No progression/data changes.
- No song browser structural changes beyond the overlay fix.
