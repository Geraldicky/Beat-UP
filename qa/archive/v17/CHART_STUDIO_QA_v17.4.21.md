# v17.4.21 Chart Studio QA

Static verification completed in the build environment.

- Main Menu exposes `CHART STUDIO` as item 02.
- New Chart Studio presents separate OGG playback and FLAC analysis inputs.
- OGG picker accepts `.ogg`; analysis picker accepts `.flac`.
- Generator requires a valid OGG gameplay asset and FLAC analysis source before starting.
- FLAC source is decoded to temporary PCM16 WAV for the existing deterministic analysis pipeline.
- New custom songs/charts are written to `user://songs/<song_id>/`, which LevelCatalog already scans.
- NORMAL / HARD / MASTER are generated as one validated transaction.
- Freshly generated charts run through the Big Daddy benchmark readability guard before final save; all retained timestamps/directions and SPACE events are preserved by that pass.
- Python helper scripts are included by the Windows export preset and materialized to `user://chart_studio_tools/` before subprocess execution.
- Manual timeline editor controls remain present.
- Back action returns to Main Menu.
- All `$NodePath` references used by `chart_editor.gd` resolve to nodes in the redesigned scene.
- 42 built-in chart JSON files are byte-identical to v17.4.20.
- All 42 built-in chart JSON files parse successfully.
- `validation.txt` is not included.

Godot is not installed in this build environment, so runtime/UI interaction testing must be performed locally.
