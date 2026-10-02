# Beat UP! v18.7.0 — Player Creator Update

## Player Creator

- Chart Studio and local song import are supported player features.
- Custom content is stored below `user://songs` and remains separate from the built-in library.
- Creator availability is now explicit through `beat_up/player_creator_enabled`.
- PCM WAV can generate all three difficulties through the built-in Quick Generate path when optional AI tooling is unavailable.
- Unsaved chart edits are recovered from an automatic local recovery file.
- Custom songs can be exported and imported as guarded `.beatup-pack` archives.

## Reliability

- Normal run history and local telemetry now use bounded retention.
- Windows build artifacts read their version from `project.godot`.
- Historical patch backups, tests, QA notes, and changelogs are excluded from player exports.
- Level packs enforce entry, path, file-size, format, and chart-integrity checks before transactional installation.

## Compatibility

- All 117 built-in charts and existing custom JSON charts remain compatible.
- Existing settings, records, replays, and custom songs are preserved.
