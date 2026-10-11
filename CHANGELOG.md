# Changelog

Major development milestones. These version labels describe project history,
not published GitHub releases. The current application version is 18.7.0.1.
Detailed patch notes, design experiments and historical QA are preserved in a
local archive outside Git and remain accessible in earlier commits.

## Repository hygiene (2026-10-11)

- Archived historical patch notes, QA reports, unused mockups, captured telemetry
  and superseded design/creator instructions outside the repository.
- Retained runtime source, charts, music, artwork, attribution, tests and analysis
  tools. Both export presets exclude local development artifacts.
- Corrected documentation for the existing Chart Studio and Practice UI retirement.

## Current 18.7.0.1 follow-ups (October 2026)

- Consolidated Main Menu and Song Library presentation with persistent navigation,
  authoritative chart resolution at launch and 39 generic runtime backgrounds.
- Added boot/loading feedback; retired Chart Studio while preserving chart and
  level-pack import/export, user songs, exports and autosaves.
- Updated chart pacing across 39 songs / 117 charts, preserving retained event
  timestamps. Bad Apple's approved 138 BPM charts remain the authority.
- Added asynchronous launch preparation, music pause-intent preservation and
  frozen gameplay time during pause, protected by the current release gate.
- Refined gameplay/results presentation and separated gameplay audio from looping
  menu playback without changing the scoring and rank contracts.

## 18.7.0 / 18.7.0.1

- Introduced manual Player Creator and level-pack sharing, then restricted automatic
  chart generation to development. The editor was subsequently retired as above.
- Established `tests/release_gate.py` and `qa/CURRENT_RELEASE_GATE.md` as the
  current-build QA authority; older version-specific tests remain historical checks.

## 18.0

- Added rebindable controls, practice/replay systems, accessibility focus behavior
  and local performance diagnostics with atomic persistence and v17 compatibility.
- Added Windows beta build helpers. Later UI retirement supersedes the original
  player-facing Practice and creator instructions.

## 17.5

- Introduced coherent per-run records, local ranking, duplicate-completion guards,
  score deltas, shared score processing and missing-audio launch validation.
- Preserved legacy saves without fabricating run history or migrating unrelated
  record identities.

## 17.4

- Removed Bomb from the active ruleset, preserving chart timestamps through the
  Reverse migration. Added 4-direction controls and deterministic projection of
  the authored 8-direction vocabulary.

## 16.8

- Established weighted accuracy, chart integrity validation and audio-duration
  authority for gameplay completion.
