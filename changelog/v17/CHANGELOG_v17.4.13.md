# Beat UP! v17.4.13 — Save Data & Settings Reliability

## Objective
Harden Beta 1 local persistence so preferences and best-level progression survive normal restarts, malformed values, corrupted primary files, and interrupted writes without changing gameplay/chart behavior.

## Settings storage
- Added a settings schema version in `settings.cfg`.
- Added typed normalization for float, integer, boolean, string, enum, resolution, and timing values.
- Malformed-but-parseable values are repaired to safe canonical values.
- Unknown/future ConfigFile sections are preserved.
- Input/Audio Offset remain clamped to the existing ±200 ms runtime range.
- Resolution is bounded to a safe 640×360 through 7680×4320 range.

## Atomic settings writes
- Settings now write to `user://settings.tmp.cfg` first.
- The temporary file is reloaded to verify it is parseable before promotion.
- The previous primary becomes `user://settings.backup.cfg`.
- If promotion fails, the previous backup is restored when possible.
- If the primary settings file is unreadable, it is quarantined as `user://settings.corrupt.cfg` and the backup is used automatically.

## Reset Defaults
- Reset Defaults now resets preferences only.
- First-run tutorial completion is preserved.
- Last Song Library selection is preserved.
- Unknown/future sections are not wiped.

## Best-level progression
- Added `scripts/reliable_json_store.gd`.
- `user://best_level_stats.json` now uses verified temporary writes and previous-generation backup rotation.
- Unreadable primary JSON is quarantined and the previous known-good `.bak` file is restored automatically.
- Existing best-stats migrations remain in place after recovery.

## QA
- Added `tests/save_settings_reliability_v17413_test.gd`.
- Added `qa/archive/v17/SAVE_SETTINGS_QA_v17.4.13.md`.

## Explicitly unchanged
- All authored charts, BPM, note timestamps, density, and scroll-speed behavior.
- Judgement windows and runtime timing model.
- Calibration behavior.
- v17.4.11 Hotfix 2 gameplay lane, note palette, hit zone, and per-song background presentation.
- v17.4.12 Result Screen calculation/reveal behavior.
