# Beat UP! v17.4.8 — Calibration & Timing QA Finalization

## Objective

Harden runtime timing before Beta 1 playtesting so future judgement telemetry reflects player/chart difficulty rather than preventable clock or calibration instability.

## Runtime timing

- Preserved v17.4.7's audio-authoritative timing architecture.
- Added monotonic raw-audio stabilization so mixer interpolation cannot move gameplay time backwards during an active run.
- Kept the existing offset sign convention unchanged.
- Centralized Audio Offset application on the stabilized raw clock.
- Added explicit runtime timing-state reset on chart start/countdown and Retry.

## Pause / Resume

- Capture a raw-audio timing snapshot before pausing.
- Verify continuity on the first active frame after Resume.
- F3 timing debug now exposes the latest resume clock delta.
- Emits a QA warning for abnormally large resume deltas.

## Calibration

- Preserved the existing 20-sample median/MAD-style robust calibration flow.
- Click prediction now includes both `AudioServer.get_time_to_next_mix()` and output latency, reducing buffer-delay contamination in the recommended Input Offset.
- Manual Input Offset and Audio Offset remain independent.

## Settings persistence

- Added load warnings for unreadable `user://settings.cfg`.
- Added centralized save error reporting while preserving all existing settings sections and public APIs.

## QA

- Added `tests/timing_v1748_test.gd` for offset sign, clamping, and monotonic-clock regression checks.
- Added `qa/archive/v17/TIMING_QA_v17.4.8.md` covering calibration persistence, Pause/Resume, Retry, 60/120/144 Hz, Windowed/Fullscreen, and settings regression.

## Versioning

- Project version bumped to 17.4.8.
- Startup system label bumped to 17.4.8.

## Explicitly unchanged

- No chart JSON was edited.
- No note density/readability rebalance was performed.
- BPM-driven scroll-speed behavior was not changed.
- No Beta telemetry/player identity system was added yet.
- No `validation.txt` was added.
