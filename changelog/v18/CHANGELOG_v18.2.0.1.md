# Beat UP! v18.2.0.1 — Godot 4.7 Parser / Warning Compatibility Hotfix

This hotfix targets projects where warnings are treated as errors.

- Renamed the `Theme` preload alias in `interaction_polish.gd` so it no longer shadows Godot's native `Theme` class.
- Removed `Node.name` parameter-shadow warnings from the performance monitor and Song Library helpers.
- Rewrote Calibration's 4K/8K key-list selection without the incompatible typed-array ternary.
- Renamed the `key` iterator in `score_identity.gd`, which shadowed the class' own `key()` function.
- Replaced two integer divisions with explicit float division + `floori()` in Now Playing and How To Play.
- Renamed generic dictionary iterators touched by this pass to avoid warning-as-error failures.
- No gameplay, chart, background, audio, scoring, timing, or visual-layout behavior is intentionally changed.
