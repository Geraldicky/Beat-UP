# Bad Apple!! — read-only librosa audit

Scope: current Normal/Hard/Master, after the pacing pilot. No source chart,
game audio, gameplay timing/scoring, settings, records, or version is changed.

## Reproduce

Python 3.12 is used in an isolated optional QA environment. The repository's
Python 3.7 release gate and Godot runtime do not depend on librosa.
Executed versions: Python 3.12.10, librosa 0.11.0, NumPy 2.5.3,
SciPy 1.18.1, SoundFile 0.14.0, matplotlib 3.10.7. Transitive dependencies
are not fully locked; candidate estimates can change with their versions.

```powershell
py -3.12 -m venv "$env:TEMP\beatup-audio-qa-env"
& "$env:TEMP\beatup-audio-qa-env\Scripts\python.exe" -m pip install -r tools/requirements-audio-qa.txt
& "$env:TEMP\beatup-audio-qa-env\Scripts\python.exe" tests/chart_audio_audit_test.py
& "$env:TEMP\beatup-audio-qa-env\Scripts\python.exe" tools/chart_audio_audit.py charts/bad_apple/normal.json charts/bad_apple/hard.json charts/bad_apple/master.json --output "$env:TEMP\beatup-bad-apple-qa-new"
```

Requires ffmpeg on PATH (or `--ffmpeg <path>`). Choose a fresh output directory.
Existing directories and repository-local output are refused. Do not reuse or
overwrite developer/user settings directories. Source chart/audio SHA-256 is
checked before/after each audit. Multiple difficulties reuse decoded analysis,
but receive separate timestamp-accurate previews. No auto-correction exists.

Executed artifacts for this session:
`C:\Users\USER\AppData\Local\Temp\beatup-bad-apple-audio-audit-20261004-v2`.
Use **v2**, not the first exploratory directory: full-song onset normalization
initially missed many softer attacks. Detection now uses overlapping, locally
normalized 30-second windows with one-second context at boundaries.

Per difficulty: mixed source-audio/click WAV, clicks-only WAV, waveform PNG,
input-to-onset candidate CSV, detected beat/onset CSV, and JSON report.
Arrow clicks are high pitched; SPACE clicks are lower pitched. Audio is mono
22,050 Hz with fixed headroom for listening QA; timestamps and decoded sample
count are preserved. No intro trim or beat_offset reapplication is performed.
The previews include optional authored `chart_offset_ms`, but not personal
settings/hardware latency. Default scene `chart_sync_offset_ms` is zero.

## Results / interpretation

The current chart declares 140 BPM, `beat_offset=1.287429` seconds, and a
`verified_bpm_phase_refined` fixed grid in historical generator metadata.
This metadata is not proof of musical correctness.

Decoded gameplay OGG lasts 324.115782 seconds, matching chart duration.
librosa's unconstrained global estimate is 137.8125 BPM. Linear fitting of its
detected beat sequence gives 137.9948 BPM, **a candidate close to 138 BPM**.
The beat tracker covers 1.434–258.409 seconds, not the entire song. Missing
beats, beat-index mistakes, and tempo aliases can bias both estimates; fitting
the same detector's output is not independent verification.
Additional fitting within consecutive 30-second windows gives approximately
137.90–138.11 BPM across the detected coverage. This strengthens the tempo
candidate, but still uses the same detector and requires musical verification.

Fixed-grid phase probes vary considerably by 30-second region and sometimes
reach the ±200 ms search boundary. A single global offset is therefore not
justified by this audit. A 140-vs-138 tempo mismatch is a stronger candidate to
investigate manually, but is not yet an approved chart retiming.

Nearest detected-onset median distances: Normal 25.42 ms, Hard 22.05 ms,
Master 21.85 ms. These are **not accuracy scores**: 2,356 detected onsets include
vocal/melodic/secondary attacks, so a wrong chart can still be close to some
onset. All-input shift probes have small gains and different optimal shifts
(-15/-5/+10 ms); do not turn these into user-offset recommendations.

Next check: listen to the clicks in early/middle/late excerpts, verify the
intended rhythmic instrument, then compare a manually verified 138 BPM grid
and correct first-beat phase against the full track. Only after that should
the chart grid/pattern be revised. Do not snap every note to nearest onset or
replace OGG with WAV as a speculative fix. Original FLAC/WAV timeline equality
has not been established by this audit.

## Ownership and reference principle

Beat UP! source of truth: `main.gd::get_chart_target_offset_seconds` treats
stored note timestamps as absolute song time; `beat_offset` is analysis
metadata, not an additional runtime shift. `RhythmTiming` owns compensation.
`LevelCatalog` remains authoritative at Play. This tool owns no runtime state.

osu-reference research: inspected `osu.Game/Beatmaps/WorkingBeatmap.cs` and
`osu.Game.Tests/Beatmaps/WorkingBeatmapManagerTest.cs` at the skill's audited
snapshot. Source/resource state is separated from derived playable state;
tests cover cache reuse/refetch and persistence. Reusable principle: audit a
disposable derivative while retaining exact source identity. Here, JSON/audio
are read-only inputs; decode/features/previews are created offline, cached
only for this CLI invocation, then discarded or reviewed as QA artifacts.
Do not copy WorkingBeatmap, database/cache/DI architecture, ruleset conversion,
or an editor framework. No production adaptation is needed for this audit.

Analysis API references:
[beat_track](https://librosa.org/doc/0.11.0/generated/librosa.beat.beat_track.html),
[onset_detect](https://librosa.org/doc/0.11.0/generated/librosa.onset.onset_detect.html).

## Regression checks

Optional six-test suite covers nearest-onset sign, known +80 ms synthetic
shift, silence/empty detections, exact click sample positions and distinct
SPACE cue, absolute timestamps/fine offset without source mutation, output
safety, and actual ffmpeg/librosa analysis of a known 120 BPM metronome.
These checks protect tooling correctness, not musical quality. Optional audio
dependencies are deliberately not made mandatory for the Python 3.7 gate.

Executed verification: six audio QA tests PASS, Python compile checks PASS,
chart/audio source hash checks PASS, and final full release gate PASS including
strict Godot import/parser/warning validation. The first gate attempt hit the
existing intermittent 120-second `live_records_foundation_test.gd` timeout;
an isolated rerun exited successfully and the full gate rerun passed. Existing
shutdown retention diagnostics remain; no tests/criteria were weakened.
