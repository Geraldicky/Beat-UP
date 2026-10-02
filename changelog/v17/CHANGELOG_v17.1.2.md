# Beat UP! v17.1.2 — Song Library Final Layout Pass

## Focus
- finalize Song Library layout after v17.1.1 feedback;
- add per-song background ambience for the 13 bundled songs;
- reduce left-side dead space without reintroducing heavy cards;
- keep progression logic, gameplay, and all 39 charts unchanged.

## Changes
- Added `assets/song_backgrounds/` with 13 bundled abstract backgrounds.
- `song_select_visual.gd` now loads a song-specific background when available and falls back to the procedural ambience when not.
- Background transitions crossfade softly on song change.
- Backdrop composition tuned: smaller diamond watermark, clearer lower-left waveform, softer overlay, stronger ambience.
- Left/right Song Library balance adjusted to ~53/47.
- Quick stat cards on the left are hidden; song metadata is compressed into a single line (`difficulty · stars · bpm · length · notes`).
- Personal Best grid reduced to score / accuracy / combo; plays removed from the main cluster.
- Random button downsized and relabeled as a compact toggle.
- Filter controls slightly reduced to fit the compact layout better.
- Difficulty rows now say `NOTES` instead of the terse `N` suffix.
- Built-in library visuals stay player-facing; developer controls remain hidden.
- Project version bumped to `17.1.2`.

## Non-goals / frozen systems
- No chart, timing, or gameplay effect changes.
- All 39 charts remain byte-identical to v17.1.1.
- Progression logic remains the same as v17.1.
