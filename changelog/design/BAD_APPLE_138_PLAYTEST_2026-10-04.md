# Bad Apple!! 138 BPM — experimental playable charts

User-approved next step: make a playable candidate instead of requiring the
user to validate click previews first. Changes are limited to three bundled
Bad Apple difficulties and offline QA/tests; version remains 18.7.0.1.

## Chart change, not a runtime offset workaround

Existing musical beat positions are remapped with:

`new_time = 1.43 + (old_time - 1.287429) * 140 / 138`

Both directional and SPACE timestamps change. BPM becomes 138; candidate
anchor becomes 1.43 seconds, rounded from the first detected audio attack at
1.428 seconds. This is an experimental phase choice, not a calibrated device
offset or a claim of manual mapping accuracy. `beat_offset` is not applied
again at runtime; timestamps remain absolute audio times.

Directions, note types, input counts, audio, duration, difficulty/star labels,
Random/reverse behavior, and the pacing pilot's reduced density are preserved.
Master is not made harder. Rest intervals/section coordinates move with their
beat positions. The final section end is bounded to unchanged audio duration;
no input is silently clipped or removed. Old generator diagnostics remain
historical provenance; timing_grid and pacing_meta.after describe this trial.
The candidate is explicitly marked experimental in tempo_trial and timing_grid.

Arrow counts Normal/Hard/Master remain 537/722/968. Changing timestamps changes
chart hash and record/replay identity by existing ScoreIdentity behavior; no
old PB or replay is forcibly relabeled as compatible. No production script,
judgement window, scoring formula, clock, input binding, or user setting changes.

## Evidence and limits

Existing librosa audit: detected beat sequence fits approximately 137.995 BPM,
with per-window candidates approximately 137.90–138.11 BPM. The original chart
used 140 BPM. New source-audio QA was run after retiming. On the same onset
envelope, best full-beat-grid probe score changes from 0.35546 to 0.82940;
the 138 BPM window probes stay around +20–25 ms through most of the track,
instead of jumping around the ±200 ms range. Intro/tail differ. This is stronger
numerical consistency, NOT a musical accuracy percentage. Onset/attack-analysis
bias can explain small positive offsets; no automatic +20 ms adjustment is made.

New QA artifacts:
`C:\Users\USER\AppData\Local\Temp\beatup-bad-apple-138-trial-20261004`.

Exact pre-trial pacing charts, for rollback without losing the earlier nerf:
`C:\Users\USER\AppData\Local\Temp\beatup-bad-apple-pre138-e678d1c2-18c6-477b-8430-6ba8b74d77f0`.
These local temporary directories are not packaged/exported or committed.

## Playtest

Restart the Godot project, or export a new executable. An old exported EXE/PCK
still contains the old charts. Select Bad Apple!! and confirm 138 BPM. Use
Random OFF, Reverse OFF and a comfortable fixed note speed initially; do not
change offsets mid-comparison. Play Normal first, then Hard/Master. Compare
early/middle/late phrases and re-entry after rests, not just the intro.

User chart overrides still have precedence. No user song/export was deleted or
overwritten. If the Library still shows 140 after restarting/re-exporting,
inspect the resolved source rather than bypassing LevelCatalog precedence.
Report whether hits sound early/late, whether the mismatch grows over time,
and whether particular phrases alone feel wrong. This pilot does not establish
that every chart in the library needs 138 BPM or the same phase adjustment.

## Ownership/reference and regression

osu-reference principle from inspected WorkingBeatmap/WorkingBeatmapManagerTest
(see the preceding librosa audit report): authoritative source and disposable
runtime state have separate identity; invalidate/refetch at launch. Beat UP!
keeps JSON as source and LevelCatalog as launch owner. Offline retiming returns
a deep copy, persists only through the approved source edit, then existing Play
resolution creates a fresh runtime snapshot. No osu database/cache/DI/ruleset
framework is copied. No production lifecycle adaptation is needed.

`chart_tempo_trial_test.py` tests source immutability, exact beat-index retention,
direction/type preservation, no double application, no out-of-duration clipping,
and three shipped trial charts' grid/order/count/duration invariants. It is
included in the unchanged-strength release gate. Existing pacing/timeline tests
continue to validate rests and no source mutation.

Executed: two tempo-trial tests PASS, three pacing tests PASS, source-pattern /
audio / duration comparison against exact pre-trial backups PASS, post-retime
librosa audit completed, and full release gate PASS including strict Godot
import/parser/warning validation and authoritative launch/input/navigation tests.
Existing runtime shutdown-retention diagnostics remain; no criteria weakened.
