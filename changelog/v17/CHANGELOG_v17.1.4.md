# Beat UP! v17.1.4 — Song Library Art Direction Reset

## Focus
- replace the weak/procedural-looking song library ambience with cleaner abstract artwork;
- make the left-side detail hierarchy cleaner and less redundant;
- redesign the song-row presentation so the library feels more cohesive and premium;
- preserve gameplay, timing, progression, and all chart data.

## Changes
- Replaced all 13 bundled song backgrounds with a cleaner abstract art set.
- Removed the blotchy/procedural blob look from the previous background pass.
- Rewrote `song_select_visual.gd` to use a cleaner full-screen ambience: softer overlays, smaller diamond watermark, lighter grid, stronger background presence, and more cohesive waveform rails.
- Cleaned the selected-song detail hierarchy: if the artist is unknown, the song info no longer duplicates `difficulty · stars` twice.
- Selected-song details now favor a single stronger data line (`difficulty · stars · bpm · length · notes`) with artist shown only when meaningful.
- Retuned main song rows: calmer unselected rows, clearer selected/hover states, and a more deliberate panel/readability balance.
- Retuned difficulty rows to keep their identity colors while reading more like part of a single system.
- Library panel opacity/lightness adjusted to better integrate with the new background art.
- Version bumped to `17.1.4`.

## Non-goals / frozen systems
- No chart, timing, gameplay, or progression logic changes.
- All 39 charts remain byte-identical to v17.1.3.
