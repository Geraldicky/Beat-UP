# Beat UP! v17.4.40 — Beta 1 Consolidated Hardening QA

Runtime Godot execution is not available in the build environment. This file records the intended manual smoke-test matrix for the local build.

## Required smoke test

1. Cold launch into Main Menu; music must start automatically.
2. Main Menu -> Song Library -> change song -> change difficulty -> back to Main Menu; selected music and artwork must continue without restarting.
3. Rapidly press PLAY/BACK during a route transition; only one navigation request should execute.
4. Launch Gameplay; no READY/3/2/1 initial countdown should appear.
5. Alt-tab or otherwise remove application focus during active Gameplay; Pause should open and playback should stop.
6. Resume Gameplay; existing 3/2/1 resume safety countdown should run.
7. Retry, Skip Intro where available, then return to Song Library.
8. Open Calibration, change offsets, APPLY, close/reopen Calibration; the exact saved values should persist.
9. Finish a song; Result Screen score, accuracy, combo and judgement totals should remain internally consistent.
10. Change display/audio/background settings, restart the game, and verify persistence.
11. Temporarily corrupt `user://settings.cfg`; next launch should recover from backup/defaults rather than crash.
12. Check `user://logs/beta_runtime.log` for boot/navigation/settings/gameplay/result diagnostics.

## Static verification performed during packaging

- 42/42 built-in chart JSON files byte-identical to v17.4.37.
- All JSON files parse successfully.
- No `*manifest*.json` files.
- No `validation.txt` files.
- Changed GDScript files passed delimiter-balance checks.
- ZIP archive CRC is checked after packaging.
