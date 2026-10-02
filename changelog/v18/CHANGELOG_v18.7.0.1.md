# Beat UP! v18.7.0.1 — QA Authority & Creator Contract Hotfix

## Player Creator contract

- Player Creator remains enabled.
- Players can import OGG audio, create NORMAL/HARD/MASTER drafts, set chart BPM,
  author Normal/Reverse/Space notes manually, use waveform/timeline tools,
  Undo/Redo, save charts, and share custom levels.
- Automatic chart generation is now developer-only.
- `beat_up/creator_tools_enabled` defaults to `false`.
- Generate All is shown only in the Godot editor or an explicitly enabled
  developer build, and the generator handler also rejects player access.
- FLAC/WAV remains available to player Chart Studio as an optional waveform
  source without auto-generating notes.

## QA authority

- Added `current_release_contract_test.py` as the current-build invariant test.
- `release_gate.py` no longer treats the obsolete v18.4 visual palette assertion
  as a release blocker.
- Added the Main Menu transport hotfix and v18.7 generator reliability checks to
  the authoritative release gate.
- Historical tests remain available as references, while the current gate is
  documented in `qa/CURRENT_RELEASE_GATE.md`.

## Documentation sync

- Reverse documentation now matches runtime: Normal silhouette + red outline
  only, with no special inner diamond.
- Player Creator documentation now reflects manual player charting and
  developer-only automatic generation.
