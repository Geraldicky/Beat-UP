# Beat UP! v18.5.0 — Beta Stability & Reward Update

Base version: v18.4.0.3

## Million-scale scoring

- Added one centralized score policy shared by directional notes and SPACE.
- Applied a calibrated 13× presentation scale while preserving judgement and
  combo value. Ideal scores across the authored library land around 1–9 million.
- Added a 9,999,999 safety ceiling so unusually long imported charts cannot
  inflate scores into tens or hundreds of millions.
- Bumped the scoring rules identity so legacy scores are never compared against
  runs produced by the new million-scale rules.
- Migrates compatible v18.4 records to the new 13× scale, so existing personal
  bests and run history remain visible instead of resetting the Ranking panel.
- Preserved separate local rankings for 4K, 8K, Random, and standard play.

## Song Library

- Removed the native title/artist tooltip from song-card hover.
- Hid the Details tab and panel completely from the player interface.
- Retained all Details code and scene nodes for future creator/debug use.
- Ranking is now the single visible information surface and opens by default.

## Build separation and hardening

- Chart Import and Chart Studio remain available in editor/debug builds but are
  hidden from release player builds unless explicitly enabled in project settings.
- Added a v18.5.0 regression suite for score rules, Ranking-only UI, tooltip
  removal, catalogue integrity, backgrounds, and forbidden manifests.
- The v18.4 parser compatibility checks remain in the release gate.
- Merged the v18.4.0.3 export-aware audio detection hotfix. Bundled OGG files
  are checked through `ResourceLoader`, so Windows exports no longer report
  `AUDIO MISSING` for tracks stored inside the PCK.

## Preserved

- All 117 charts and 39 song backgrounds remain unchanged.
- The v18.3.0 dark note palette remains active.
- Scroll speed continues to follow BPM using the existing bounded curve.
- Music, records, settings, replays, and telemetry are not overwritten.
