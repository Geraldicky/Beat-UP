# Beat UP! v17.4.6 — Core Gameplay Stability Pass

## Beta direction
v17.4.6 starts the first beta-release stabilization line. The 14-song / 42-chart gameplay baseline from v17.4.5.4 is frozen for this pass; no note timing, direction, density, Reverse placement, SPACE timing, BPM, or chart metadata was edited.

## Stability changes
- Block gameplay/menu key input while the global loading transition owns the screen, preventing confirm/back/retry/pause input from leaking into the destination screen.
- Added transition guards around Retry, Result Retry, Result Back, Song Library navigation, and level transitions so repeated clicks/keypresses cannot queue competing state changes.
- Hardened pause/audio cleanup when retrying, finishing a run, returning to Song Library, or returning to the Main Menu.
- Clear cached 8K/4K runtime direction layouts when leaving gameplay for the Song Library, ensuring the next run always prepares its layout from the selected chart.
- Added a tracked countdown reveal tween. Old GO/countdown callbacks are now cancelled during retry/navigation so a stale tween cannot hide a newly started countdown.
- A fresh level start now explicitly clears paused audio state before preparing gameplay.

## Beta chart freeze
- Added `tools/beta_chart_baseline_v1746.json` containing SHA-256 fingerprints for all 42 active chart files. This is groundwork for the upcoming playtest telemetry system so future data can be tied to an exact chart revision.

## Intentionally unchanged
- 14-song Song Library content.
- 42 authored charts.
- BPM-based scroll speed.
- Reverse density and visual treatment.
- 4K / 8K MOD behavior and Random MOD rules.
- Gameplay backgrounds and audio files.
- Result-screen presentation.

## Packaging
- Version bumped to 17.4.6.
- Changelog remains under `changelog/`.
- No `VALIDATION*.txt` files are included.
