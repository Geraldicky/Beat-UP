# Note Speed preview and resident Library reveal
# Note Speed preview and resident Library reveal

## Beat UP! changes

- Library opens the existing Note Speed dialog with its currently selected chart BPM and canonical 4K/8K preference. Invalid BPM uses the existing 140 BPM example fallback.
- The actual note renderer shows cardinal-only arrows in 4K and cardinal/diagonal arrows in 8K. A labelled, optional dense example adds half-beat bursts; it is not advertised as the selected chart. Changing reading time changes presentation only.
- `SongLibrary.shell_prepare_resume()` binds resident selection before the destination reveal. Pending detail tweens are invalidated and detail opacity is finalised. No catalog reload or audio activation is added to this hook. Selection excluded by existing filters retains existing filter semantics.
- Preview activation remains deferred by the existing resume generation; rollback/user-paused MusicSession policy and authoritative resolution at Play are unchanged.
- Behavioral regressions extend the existing readability and AppShell lifecycle suites, already registered in the isolated release gate.

## osu-reference engineering mapping

Relevant audited source: `osu.Game/Screens/Select/SongSelect.cs` and `osu.Game.Tests/Visual/SongSelect/TestSceneSongSelectCurrentSelectionInvalidated.cs`, commit `b267e64503973cf8c1183e72c9b870240bb57883`; local skill references `song-select.md` and `navigation.md`.

Flow: responsive local selection precedes deferred global work; launch validates the intended selection. Ownership: osu! SongSelect coordinates carousel/global beatmap selection; Beat UP! keeps SongSelect presentation, LevelCatalog launch authority, MusicSession playback, and AppShell lifecycle.

Lifecycle: prepare visible destination data before reveal; activate preview after commit; invalidate stale local callbacks on preparation/suspension. This avoids displaying a half-initialised destination and letting obsolete work win.

Reusable principle: distinguish immediate presentation from deferred global/audio work. Adaptation: use the existing Beat UP! prepare/resume hooks and generation counter. Do not copy osu! ScreenStack, Bindables, DI, WorkingBeatmap, or carousel architecture. The local skill's old BPM-coupled/no-slider note-speed statement is superseded by the approved Beat UP! reading-time implementation.

Regression implications: every incoming Library frame uses the requested title/artwork; late detail work cannot restore the old song; failed navigation preserves user pause; repeated 4K/8K popup opens capture current context; dense-example toggle changes rhythm without touching a playable chart.

Application version remains 18.7.0.1. Chart content, timing, scoring and launch resolution are unchanged.

## Verification

Final `tests/release_gate.py` run with Godot 4.7.1: exit 0, `RELEASE GATE: PASS (see any printed shutdown warnings)`. Includes strict import/parser/warning validation, updated readability and lifecycle suites, authoritative launch, input snapshots, records, UI/layout, level-pack and Library contracts. Dedicated final readability run also passed with exit 0. `git diff --check` passed.

Earlier attempts encountered one lifecycle timeout and one nonzero process exit after its PASS marker. Dedicated lifecycle reruns and the final full gate passed without weakening criteria; the earlier intermittent process/teardown behavior is not claimed resolved. Existing shutdown ObjectDB/resource diagnostics remain.

Settings' shared preview also follows changes to the canonical input mode; Library additionally supplies the selected song BPM. The dense example is illustrative, not actual chart analysis. No new timing, scoring, settings-storage or navigation owner was introduced.
