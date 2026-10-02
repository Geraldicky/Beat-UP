# Beat UP! v17.4.25.2 — Diagonal Waveform + Now Playing Bar

## Summary
- Moves the reactive waveform from top/bottom/left/right placement to the four diagonal sides of the central Beat UP! diamond.
- Adds a top now-playing bar card inspired by osu!-style chrome.
- The bar shows the current track title/artist and provides `PREV`, `PAUSE`, and `NEXT` controls.
- Main Menu background randomization remains intact, and the selected background now also drives the displayed current track metadata.

## Main Menu Changes
- Added a compact top card for current track status.
- `PREV` / `NEXT` cycles through song-art backgrounds and their matching menu tracks.
- `PAUSE` toggles the current menu track playback.
- The previous footer waveform remains removed.
- The waveform now follows each diagonal edge of the diamond instead of axis-aligned placement.

## Technical Notes
- Menu background entries now include audio references under `MENU_BACKGROUND_CANDIDATES`.
- `MenuBGM` is repurposed to play the selected main-menu song track and still feeds the spectrum visualizer.
- No manifest JSON files were created.
