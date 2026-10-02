# Beat UP! v17.4.21 — Player-Facing Chart Studio

## Added
- CHART STUDIO is now a normal Main Menu destination instead of a hidden/developer-only workflow.
- Completely reorganized Chart Studio screen around a three-step creation flow:
  1. Import gameplay audio as `.ogg`.
  2. Select a lossless `.flac` source for analysis.
  3. Generate deterministic NORMAL / HARD / MASTER charts.
- Existing timeline editing remains available after generation: preview, seek, snap, Normal/Reverse/SPACE editing, delete, undo/redo, save, and discard.
- Freshly generated custom charts automatically receive the v17.4.19/Big-Daddy-benchmark readability guard (density-window limits, tight-chain breaks, and difficulty-scaled Reverse relocation) before final save.
- Imported player songs are now stored under `user://songs/<song_id>/`, making the creation flow writable in exported builds instead of depending on writable `res://` project folders.

## Changed
- Chart analysis selection is intentionally FLAC-only in the player-facing UI.
- FLAC is normalized to temporary PCM16 WAV internally before the existing local + All-In-One analysis pipeline.
- OGG remains the playback asset and is converted to Ogg Vorbis when necessary.
- Bulk import is removed from the primary UI to keep the workflow explicit and single-song focused.
- Back from Chart Studio returns to the Main Menu.
- Python generator helper scripts are materialized under `user://chart_studio_tools/` so external Python can execute them even when the game is exported with an embedded PCK.

## Unchanged
- All 42 built-in charts are byte-identical to v17.4.20.
- Gameplay judgement, scoring, timing, telemetry, player profile, and v17.4.19 chart balancing are unchanged.
