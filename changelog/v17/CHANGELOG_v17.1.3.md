# Beat UP! v17.1.3 — Song Library Visibility Fix

## Focus
- fix weak song-background visibility from v17.1.2;
- improve contrast/readability of the song list and difficulty strips;
- keep song library structure, progression logic, gameplay, and charts unchanged.

## Changes
- Increased `BackdropVisual` opacity in `song_select.tscn` so the selected song background is actually visible.
- Reduced `BackdropShade` opacity so bundled backgrounds are no longer smothered by the global dark overlay.
- Increased background draw alpha in `song_select_visual.gd` and strengthened crossfade visibility.
- Lightened the left-side vignette and right-side dark overlay so ambience reads while text remains legible.
- Boosted waveform visibility slightly to preserve life in the lower-left area.
- Retuned main song row colors so collapsed rows are visibly tinted instead of nearly black.
- Increased selected/hover/focus song-row contrast for clearer scanning in the library list.
- Difficulty rows now carry clearer cyan/gold/pink tint fills instead of almost invisible dark strips.
- Library panel opacity and border contrast adjusted for better separation from the backdrop.
- Version bumped to `17.1.3`.

## Non-goals / frozen systems
- No chart, timing, progression, or gameplay changes.
- All 39 charts remain byte-identical to v17.1.2.
- No new layout restructure beyond visibility/contrast tuning.
