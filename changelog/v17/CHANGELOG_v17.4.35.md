# Beat UP! v17.4.35 — Song Library State Polish + Cold-Launch Autoplay Fix

## Fixed
- Fixed first application launch sometimes reaching Main Menu with the selected song loaded visually but no music playing.
- Main Menu now has an explicit cold-launch music readiness guard. If the global `MusicSession` has no stream yet, it rebuilds playback from the already-selected Main Menu candidate instead of requiring a manual Play press or a Library round-trip.
- Existing playback is never restarted by the guard; paused state and current playback position remain intact when a valid session already exists.

## Song Library state consistency
- `SongSelectionState` now wins over older persisted Library selection while the app is running.
- Entering Song Library from Main Menu restores both the globally selected song and its difficulty when available.
- Re-activating the resident Library with a global song selection also restores the matching global difficulty instead of carrying an unrelated difficulty from the previous card.
- Existing same-track preview behavior remains continuous: difficulty changes do not restart the song and card preview playback continues through the track instead of looping a fixed preview window.

## Scope
- No built-in chart data changed.
- No gameplay judgement/scoring changes.
- No manifest JSON or validation.txt added.
