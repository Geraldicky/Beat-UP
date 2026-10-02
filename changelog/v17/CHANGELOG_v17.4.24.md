# Beat UP! v17.4.24 — Persistent UI Shell + Async Gameplay Handoff

## Goal
Remove the freeze-like feeling caused by unloading/loading whole menu scenes. Main Menu, Song Library and gameplay now live under one persistent application shell so navigation is a UI state change instead of a scene replacement.

## Changes
- Added `scenes/app_shell.tscn` as the application entry point.
- Main Menu, Song Library and `main.tscn` gameplay are instantiated once and kept resident for the process lifetime.
- Main Menu <-> Song Library now cross-slide/cross-fade for ~180 ms with no `change_scene()` call and no loading overlay.
- Song Library -> Gameplay reuses the existing selected-artwork continuity layer, but the gameplay controller is already resident; no `main.tscn` scene load happens after PLAY.
- Result/Pause -> Song Library now returns to the persistent library instead of revealing the embedded legacy selector.
- Gameplay/Song Library -> Main Menu returns to the same Main Menu instance, so splash and menu state are not reconstructed.
- Hidden screens use `PROCESS_MODE_DISABLED` so they do not receive gameplay/menu input or spend frame time on `_process()`.
- External Chart Studio remains a separate destination; returning from it loads `app_shell.tscn`.
- Legacy loading UI remains absent from the normal Main Menu / Song Library / Gameplay flow.

## Data / charts
- Built-in charts are unchanged from v17.4.23.1.
- No manifest JSON files are generated or included.
