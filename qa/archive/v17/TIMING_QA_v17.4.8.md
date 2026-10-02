# Beat UP! v17.4.8 — Timing QA

This pass intentionally leaves all chart JSON unchanged.

## Release checks

- Calibration: run at least two sessions; verify recommendation direction feels correct.
- Persistence: save non-zero Input/Audio Offset, relaunch, verify exact values remain.
- Pause/Resume: 10 cycles in one familiar song; no accumulating sync drift.
- Retry: test during countdown, early song, mid-song, after pause, and from Result.
- Refresh rate: compare the same chart at 60 Hz, 120 Hz, and 144 Hz when hardware supports them.
- Display mode: compare Windowed and Fullscreen.
- Timing debug: F3 should show RAW, SONG, Input/Audio offsets, hit delta, and last RESUME delta.
- Settings regression: volume, background opacity, resolution, window mode, VSync, input style, Input Offset, Audio Offset.
- Chart integrity: NORMAL/HARD/MASTER chart files must be byte-identical to v17.4.7.

## Expected timing semantics

- Positive Input Offset judges input earlier to compensate late key registration.
- Positive Audio Offset moves gameplay song time earlier, delaying chart events relative to audible music.
- Audio playback remains the authoritative runtime clock; `_process(delta)` is not the song clock.
- Retry resets runtime timing state before the next 3-second countdown.
- Pause/Resume never adds paused wall-clock duration to gameplay time.

## Automated test

Run with a Godot 4.7 command-line binary:

```text
godot --headless --path . -s res://tests/timing_v1748_test.gd
```
