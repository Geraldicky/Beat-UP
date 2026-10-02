# Beat UP! v18.0.0 Beta Testing Guide

Test with a clean copy of the project first. Keep an untouched v17.5.0 folder and your existing user data backup.

## Smoke test
1. Launch Main Menu, enter Song Library, return, and repeat several times. Route animation should remain responsive.
2. Select songs quickly and confirm preview audio follows the final selection without playing stale tracks.
3. Play one NORMAL, HARD and MASTER chart in both 8K and 4K where practical.
4. Toggle Random and confirm the chart remains playable and a replay can reproduce the same Random run.
5. Pause/resume mid-chart and verify timing remains continuous.

## v18 controls
- Open Settings > Timing and change one 8K key, one 4K key and SPACE.
- Duplicate assignments should be rejected.
- Set Effect Intensity to 0%, 50% and 100%. Timing/scoring must not change.

## Practice
- Song Library > PRACTICE > choose a section.
- Verify a lead-in plays, only the selected section is judged, and it loops.
- Verify normal Personal Best/plays do not increase.

## Replay
- Finish a normal run, return to Song Library, press REPLAY for the same chart/mode.
- Replay should reproduce inputs automatically and should not overwrite a normal Personal Best.
- Changing chart identity/rules should cause incompatible replay rejection rather than unsafe playback.

## Progress / export
- Finish several runs, inspect DETAILS for accuracy history.
- After telemetry exists, inspect weak-section summary.
- Use EXPORT PLAYTEST and include the resulting ZIP with bug reports.

## Report with
- exact song / difficulty / 4K or 8K / Random status;
- what happened and what was expected;
- whether the issue reproduces after restart;
- exported playtest ZIP when possible.
