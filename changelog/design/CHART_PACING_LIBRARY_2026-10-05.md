# Full-library pacing pass

## Beat UP! source of truth

39 bundled songs / 117 charts now have pacing revisions. This pass changes
108 charts (36 songs); the nine existing Immortal Flame, Bad Apple and Freedom
Dive charts remain byte-identical to their pre-pass working-tree versions.
In particular, Bad Apple's approved 138 BPM playtest is not retimed again.

Only inputs are removed. Every retained event has its original timestamp,
type and direction, and every retained SPACE has its original timestamp.
First/last arrows, BPM, beat offset, audio, duration, sections and timing-grid
metadata remain unchanged. No runtime gameplay/UI/settings code is changed.
Existing authoritative resolution and source-hash record/replay separation
remain the owners of chart identity; old records are not migrated to new charts.
Application version remains 18.7.0.1.

## Recipe and limits

`tools/chart_pacing_library.py` is an offline, read-only planner and patch emitter.
It reuses the pilot's deletion recipe, with explicit rest candidates and caps.
Already-paced groups are skipped; partially-paced groups fail rather than
applying a second destructive pass to some difficulties.

- Prefer bridge/interlude sections, then lower-energy verse sections.
- Never choose chorus/climax/pre-chorus/intro/outro sections.
- Use section-aligned 8-beat or 16-beat gaps, exceeding 3.25 seconds so
  maximum 2.6-second note preempt leaves a genuinely empty lane interval.
- Choose up to 1–4 gaps per song according to duration and available sections,
  separated by at least 40 seconds. All difficulties share the same gaps.
- Clear directional AND SPACE inputs inside the half-open gaps.
- Remove arrows within 200 ms of retained SPACE, preserving endpoint arrows.
- Prefer thinning weak subdivisions over full-beat anchors, using the existing
  Normal/Hard/Master minimum gap preferences (200/150/100 ms).
- Total directional-removal caps: Normal 25%, Hard 20%, Master 10%.

Actual directional reductions across the 108 changed charts:
Normal 3.18–20.68%, Hard 4.92–14.55%, Master 2.81–10.00%.
Added rest windows span 3.31–6.23 seconds. These are input-free windows,
not claims of silence in the audio. Music keeps playing throughout.

Section role/energy metadata comes from existing generator analysis, not new
listening or verified human annotations. Sparse quiet sections mean some songs
still have long active stretches (Night of Nights has only one eligible late
verse). Do not force periodic gaps into choruses to disguise that limitation.
Further musical placement requires playtesting/manual review.

## osu-reference adaptation

Inspected audited `osu.Game/Beatmaps/Timing/BreakPeriod.cs` and
`osu.Game.Tests/Editing/Checks/CheckBreaksTest.cs` at
`b267e64503973cf8c1183e72c9b870240bb57883`.
Flow/ownership: beatmap-owned break start/end data is validated against hit
objects and consumed by gameplay presentation. Lifecycle: loaded chart data
persists; gameplay uses its intervals, including clearance before/after objects.
Problem solved: a nominal gap is not restful if previous/next objects overlap
it visually. Reusable principle: test actual empty scheduling intervals and
return to gameplay, not just metadata lengths.

Beat UP!'s equivalent is existing chart event data and `ChartTimeline`; the
minimum adaptation is to remove authored input slots and test the existing
scheduler at maximum preempt. No BreakPeriod class, osu! millisecond constants,
break overlay, ruleset/editor framework or runtime manager is copied.
The testing-reference lesson is pure transformation tests plus real scheduler
tests, not osu!'s NUnit infrastructure.

## Verification

- Full-library Python regression: all charts, shared rests, caps, refreshed
  audit counts, non-increasing local peaks/fast direction changes, immutable
  source transform, exact retained inputs and no repeat application.
- Runtime pacing regression expanded from three songs to all 39, using actual
  ChartIntegrity and ChartTimeline with maximum note travel time.
- Pilot and tempo-trial tests retained.
- Release gate includes the new library suite. Historical v18.5 score test
  keeps scale/cap/base-reward checks; its density-dependent million-point
  floor applies only to unrevised charts. No scoring compensation is added.
- Pre-pass chart backup (including dirty pilot edits):
  `C:\Users\USER\AppData\Local\Temp\beatup-before-library-pacing-0e3e8a64-7a0f-4f61-b56a-584cddc5b81a\charts`.

Difficulty level/star labels are not recalibrated by this deletion-only pass.
Human playtesting is still needed to judge fatigue, phrase alignment, 4K/8K
feel and appropriate displayed difficulty; automated peak metrics cannot
certify that every chart feels balanced or musically correct.

Execution results: library Python suite 3/3 PASS, pilot 3/3 PASS, tempo trial
2/2 PASS, 117-chart runtime structure/scheduling PASS, `git diff --check` PASS.
Full `tests/release_gate.py` with Godot 4.7.1 exited 0:
`RELEASE GATE: PASS (see any printed shutdown warnings)`.
Strict import/parser/warning validation passed. Existing runtime teardown
ObjectDB/resource-retention diagnostics and the intentional settings-recovery
warnings remain visible; no gate criteria were suppressed or changed.
