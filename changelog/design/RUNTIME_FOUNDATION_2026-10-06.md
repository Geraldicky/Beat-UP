# Runtime foundation follow-up

Branch: `ui/song-library-redesign`. Application version: `18.7.0.1`.

Files touched in this follow-up (the workspace already contained earlier changes):
`scripts/app_shell.gd`, `scripts/level_catalog.gd`, `scripts/main.gd`,
`scripts/music_session.gd`, `scripts/scene_transition.gd`,
`scripts/ui/menu_sfx_manager.gd`, `tests/chart_pacing_timeline_test.gd`,
`tests/gameplay_integrity_v168_test.gd`, `tests/live_records_foundation_test.gd`,
`tests/release_gate.py`, `tests/timing_v1748_test.gd`,
`tests/runtime_foundation_test.gd`, its generated Godot `.uid`, and this report.

## Changes and ownership

- `LevelCatalog.resolve_playable_async` uses a temporary off-tree catalog on a worker thread. It retains the existing authoritative storage scan, precedence, integrity, audio validation, hash and chart snapshot. The live catalog receives the result only after the thread joins; the worker is freed on completion or owner exit. Concurrent preparations fail explicitly rather than sharing mutable worker state.
- AppShell shows the existing loading presentation before awaiting preparation. Gameplay's standalone launch and Retry now follow the same readiness boundary. The synchronous preparation API remains available for existing diagnostic callers. Selection metadata is provisional presentation only; it is not used as launch authority.
- MusicSession automatic keep-alive respects `stream_paused`; explicit `set_paused(false)` still resumes. Shutdown stops playback, drains owned resource warm-ups and releases cached streams. SceneTransition releases cached scenes and its tween; menu SFX stops/releases generator voices.
- AppShell warm-up is owned by Boot rather than also being started speculatively by SceneTransition on every autoload initialization. The redundant warm-up caused intermittent standalone/test loading/shutdown races. Explicit `preload_scene` callers are preserved.
- The canonical gameplay clock returns its pause snapshot, not continuing mixer interpolation. Post-audio judgement tail is also frozen during pause and rebased on resume. Score formulas, charts, note generation, input bindings and records schema are unchanged.

## osu-reference research mapping

### Preparation

Inspected production owner: `osu.Game/Screens/Play/PlayerLoader.cs` (`prepareNewPlayer`), https://github.com/ppy/osu/blob/master/osu.Game/Screens/Play/PlayerLoader.cs.
Flow: prepare asynchronously, wait for readiness, reveal only while the loader is current. Ownership/lifecycle: PlayerLoader owns pending player creation and cancellation/disposal; screen lifetime determines whether the result remains usable. Problem solved: blocking preparation and stale completion. Reusable principle: loading feedback continues while authoritative preparation runs, and only its owner commits. Beat UP! equivalent: existing LevelCatalog + AppShell transaction + SceneTransition cover. Adaptation: a private catalog worker joined before publication, followed by the existing transaction/reveal. Do NOT copy osu!'s drawable loading, WorkingBeatmap, DI or ScreenStack. Regression: yielded UI frames, identical sync/async authoritative result, missing-chart failure/recovery, worker release, existing disk-mutation and navigation suites. The exact upstream test equivalent for this new worker is Unverified; Beat UP! runtime assertions cover it directly.

### Music intent

Inspected owner: `osu.Game/Overlays/MusicController.cs`, https://github.com/ppy/osu/blob/master/osu.Game/Overlays/MusicController.cs.
Flow: automatic transport maintenance distinguishes user pause from explicit Play. Ownership/lifecycle: MusicController retains transport intent across screen activity; explicit commands alter it. Problem solved: an incidental refresh restarting user-paused music. Reusable principle: activation/keep-alive cannot revoke explicit pause. Beat UP! equivalent: persistent MusicSession. Adaptation: paused guard in ensure_playing and deterministic cleanup on exit. Do NOT copy osu!'s music overlay or binding hierarchy. Regression: ensure preserves pause; explicit Resume works; Main Menu transport and AppShell lifecycle tests remain adjacent gates. Upstream transport-test mapping is Unverified beyond the inspected production behavior.

### Timing and verification

Inspected test class: `osu.Game.Tests/Gameplay/TestSceneMasterGameplayClockContainer.cs`, https://github.com/ppy/osu/blob/master/osu.Game.Tests/Gameplay/TestSceneMasterGameplayClockContainer.cs; local skill references audio, timing and testing were read.
Flow: exercise start/reset/seek/offset/stopped clock states against the clock owner. Lifecycle/ownership: one gameplay clock owns song time, while pause/reset/seek explicitly change its state. Problem solved: consumers drifting or applying offsets twice. Reusable principle: test lifecycle boundaries, not only a timing formula. Beat UP! equivalent: main.gd canonical clock + RhythmTiming. Adaptation: frozen pause snapshot/tail, offset sweep and reset regressions. Do NOT copy framework clock wrappers, rulesets or rate mechanics. Regression: paused canonical/raw time, post-audio pause, offset sign/application and reset origin; input snapshots, 4K/8K, Reverse and note readability remain in the gate.

## Test maintenance

The retired Ascend fixture now tests the live audio-duration authority with Bad Apple and a synthetic final phrase, without altering any song/chart. Records integration waits for the launch transaction instead of guessing a fixed 1.5-second preparation time. Pacing QA begins after SceneTree initialization; all pacing assertions remain intact. New runtime/timing/integrity suites are included in the release gate; no existing suite is removed.

## Remaining limits

Worker preparation removes synchronous catalog/audio validation from the loading UI frame, but scene/node creation and gameplay runtime construction still have main-thread work. No zero-stutter guarantee is claimed. Historical RefCounted/ObjectDB and occasional resource-retention diagnostics still occur at test shutdown; generator playback leaks no longer appear in the focused verbose timing probe. Existing release-gate shutdown exception is unchanged, not expanded. Real playback/listening and hardware latency validation remain necessary.

## Final verification

`python tests/release_gate.py --godot "C:\Users\USER\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"`
exited 0 with `RELEASE GATE: PASS (see any printed shutdown warnings)`.
All 16 static/Python checks, strict import/parser/warning validation and 21 runtime suites passed, including navigation lifecycle, authoritative launch, input snapshots, records, loading, Reverse and Song Library contracts. Focused runtime foundation, timing, integrity, pacing, records and authoritative launch checks were also run during iteration. `git diff --check` passed. No tests were removed and no shutdown diagnostic exemption was added.
