# Beat UP! v17.4.40 — Beta 1 Consolidated Hardening

This build consolidates the seven planned non-generator Beta 1 passes into one larger update. Chart-generator / Chart Studio work is intentionally not part of this pass.

## 1. Song Library final polish
- Added navigation/action locking around PLAY and BACK to prevent double activation during route transitions.
- Keeps the resident Song Library selection warm across route changes.
- Gameplay launch requests are logged to the local Beta runtime log for troubleshooting.

## 2. Gameplay flow hardening
- Added automatic pause when the application loses focus during an active run.
- Focus loss never auto-resumes; the player explicitly resumes through the existing 3/2/1 safety countdown.
- Navigation transitions, results, preparation, and existing pause states are excluded from auto-pause triggering.
- Duplicate route requests are ignored while navigation is already active.

## 3. Calibration & input accuracy hardening
- APPLY now re-reads the persisted timing offsets after saving and updates the UI from the stored canonical values.
- Confirmation text shows the exact saved input/audio offsets.

## 4. Result/session summary integrity
- Result snapshots now include song id, difficulty label, input style, Random state, run duration, and completion state in addition to the existing score/accuracy/judgement data.
- Result data keeps a defensive copy for QA/debug inspection.

## 5. Settings & persistence hardening
- Settings schema advanced to v2.
- Existing atomic temp -> verify -> backup -> promote storage remains intact.
- Recovery/write failures are also reported to the local runtime log.

## 6. Failure recovery / Beta diagnostics
- Added a global RuntimeGuard.
- Writes compact JSON-line diagnostics to `user://logs/beta_runtime.log`.
- Rotates the log at 1 MiB to `beta_runtime.previous.log`.
- Navigation timeouts, settings recovery, gameplay focus-loss pause and completed runs are captured without adding any online service.

## 7. Beta 1 UX freeze pass
- No main-menu, song-library, gameplay HUD, result-screen or chart redesign in this build.
- Existing seamless music/background/navigation architecture from v17.4.31–37 is preserved.
- Initial READY/3/2/1 remains removed; pause -> resume countdown remains.
- Chart Studio remains present but receives no generator work in this release.

## Scope intentionally frozen
- All 42 built-in chart JSON files remain unchanged.
- No telemetry/analyzer expansion from the skipped v17.4.38/v17.4.39 plan.
- No chart-generator changes.
- No manifest JSON files.
