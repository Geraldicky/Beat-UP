# v17.5.0 — Gameplay & Records Foundation

Based on user-supplied v17.4.52.1 Parser Hotfix.

- Coherent per-run records; aggregated accuracy/combo/FC remain separate.
- Completed-run history and selectable local ranking, isolated by existing ScoreIdentity.
- Legacy data retained without inventing missing run history or assigning aggregate FC to a run.
- Result score/accuracy delta against the pre-commit best run.
- Session ID and duplicate-completion guard; explicit record-save failure feedback.
- Shared ScoreProcessor for accuracy and judgement thresholds; RunRecords handles record merging/ranking; GameplaySession handles session lifecycle.
- Playtest ZIP export from Song Library, including local records and telemetry, with explicit errors and local folder access.
- Missing-audio launch guard including keyboard launch; chart import validates before saving and refuses chart/audio conflicts.
- Additional chart validation for nonnumeric event time, finite/nonnegative times, and events outside duration.
- Ranking layout tested with populated records at 1280x720, 1600x900 and 1920x1080; PLAY width adjusted for the information column.
- Removed historical version-equality assertions from Python feature checks. Added focused release gate and runtime tests.
- Version metadata updated to 17.5.0.
- Restored only the 25 missing audio files from the previous complete v17.4.48 archive. Matching source chart paths, duration and events were checked. Existing latest audio files are untouched.
- All 117 chart files, generator and song background assets remain byte-identical to the uploaded v17.4.52.1 source. BPM-based scroll speed unchanged.
- No build manifest JSON. Changelogs remain in changelog/.

## Limits
No recorded-input replay, practice loop or online ranking. Refactor is incremental, not a wholesale rewrite. Hardware audio latency and Windows rendering/export require manual QA. Existing scene shutdown resource warnings are recorded in QA.
