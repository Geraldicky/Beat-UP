# Startup, menu motion, gameplay loading, and Chart Studio retirement

Branch: `ui/song-library-redesign`. Application version: **18.7.0.1**, unchanged.

## Beat UP! source of truth

- The former entry scene loaded Main Menu, Song Library, and Gameplay dependencies before the first application scene could render. The new lightweight `boot.tscn` draws the existing Beat UP! wordmark first and waits on SceneTransition's existing threaded AppShell cache.
- Splash animation changes only a fixed wordmark's clipping window: 580 ms left-to-right reveal, short hold, 420 ms right-to-left retirement. AppSessionState marks it seen before AppShell opens, avoiding a second splash. Startup's standalone splash uses the same fixed geometry.
- Bootstrap preparation has a local 30-second monotonic deadline and an inline failure message. This is not a navigation watchdog or new scene manager. It cannot eliminate Windows process startup, graphics-driver initialization, or work before Godot's first frame. Scene instantiation can still occupy the main thread; the rendered boot/loading frame provides feedback, not a guarantee of zero stalls.
- AppShell continues to own resident navigation. Main Menu / Library foregrounds exit in 140 ms and enter in 260 ms with small horizontal motion. Their prepared randomized backgrounds blend independently across the 400 ms handoff; foregrounds never overlap. Input remains transaction-locked until completion.
- AppShell begins the persistent gameplay loading cover **before** `prepare_launch_request(request, true)`. A rendered frame is explicitly awaited on graphical runs. The existing LevelCatalog resolver still validates/refreshes the authoritative chart; the resolved chart supplies the displayed final metadata and gameplay request.
- Preparation failure removes the cover and leaves the originating resident route active. No early music suspension, no route commit, and no stale caller lock. A user-paused stream stays paused. Successful launch, Retry, and standalone gameplay retain the existing readiness boundary and preparation deadlines.
- Loading holds the song identity and a small indeterminate rail until reveal. It does not invent a percentage or use album covers as fullscreen backgrounds. The existing randomized generic background source is preserved. Background/dim children draw behind the parent's status rail, so the status is actually visible.
- Chart Studio's scene, editor script, timeline/waveform editor controls, route request, lazy loader, Main Menu action, Library action, and developer F2 entry were removed. Gameplay's `ChartTimeline`, LevelCatalog, level packs, analyzer utilities, bundled charts, and all user songs/exports/autosaves remain untouched. Deleted tracked editor sources are recoverable through Git; no user content was deleted.
- Gameplay's key compass node and its visual-only update calls were removed. Directional/Space judgement still uses the same run snapshot. The gold Space timing target remains; its custom key caption is obtained from the snapshot, never from a live settings getter.
- UIAccessibility no longer manufactures hover tooltips. Explicit tooltip assignments were removed, including late selection/settings updates. Pause action names remain in the persistent action hint. File picker callbacks now capture an explicit entry path instead of misusing tooltip text as storage. Keyboard focus remains enabled.

## Reference principles, not architecture copies

Audited osu! commit: `b267e64503973cf8c1183e72c9b870240bb57883`.

### Loading presentation

- Relevant source: [osu.Game/Screens/Play/PlayerLoader.cs](https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game/Screens/Play/PlayerLoader.cs), class `PlayerLoader`.
- Flow / ownership: the loader presents preparation while the player is loaded; the player's readiness is distinct from visual animation.
- Lifecycle: present the loader, prepare the destination, hand over only after readiness; loading state must not remain as a second active owner after handoff.
- Problem solved / reusable principle: heavy work must have visible feedback, and an intro animation finishing is not proof that gameplay is ready.
- Beat UP! equivalent / adaptation: `SceneTransition`, `SongLaunchTransitionVisual`, and `AppShell.launch_gameplay`; show the existing layer earlier and keep copy visible through preparation. `LevelCatalog` retains authoritative chart ownership.
- Do not copy: osu!'s PlayerLoader class graph, rulesets, dependency loading, Bindables, or ScreenStack. No osu! assets, visual identity, or code were copied.
- Regression implications: visible loading before rejected launch, retained authoritative identity during a slow readiness probe, exactly one transition start/finish, no leaked action/navigation locks.

### Navigation presentation

- Relevant sources: [osu.Game/Screens/OsuScreen.cs](https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game/Screens/OsuScreen.cs) and [osu.Game.Tests/Visual/Navigation/TestSceneScreenNavigation.cs](https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game.Tests/Visual/Navigation/TestSceneScreenNavigation.cs).
- Flow / ownership: screen lifecycle and presentation have explicit entry/exit ownership; visual effects should follow activation rather than independent late callbacks.
- Lifecycle / problem solved: entering, suspending, returning, and exiting must preserve the destination's state and avoid stale work influencing a later screen.
- Reusable principle: prepare before reveal; complete a transition once; test repeated navigation, not only one successful entry.
- Beat UP! equivalent / adaptation: existing AppShell/NavigationController transaction remains intact. Only foreground timing/offsets and the background blend duration changed. Existing visibility-in-tree and prepared-background behavior was retained.
- Do not copy: osu!'s screen hierarchy, cancellation framework, or DI ownership model. A generic timeout/global state machine was not added.
- Regression implications: no foreground ghosting, one prepared randomized background per visit, no later background swap/zoom, a non-instant foreground handoff, preserved selection/focus, paired navigation state and completion signals.

The supplied showcase video's sampled frames informed the presentation direction; they do **not** establish cold-launch OS latency or exact osu! animation durations. The local motion-design skill informed restrained easing and explicit motion durations, not new UI architecture.

## Files touched by this task

Production additions: `scenes/boot.tscn`, `scripts/boot.gd` (and Godot `.uid`).

Production updates:

- `project.godot`
- `scenes/app_shell.tscn`, `scenes/startup.tscn`, `scenes/song_select.tscn`, `scenes/track.tscn`, `scenes/scene_transition_layer.tscn`
- `scripts/app_shell.gd`, `scripts/navigation_controller.gd`, `scripts/scene_transition.gd`, `scripts/startup.gd`, `scripts/song_library.gd`, `scripts/song_select.gd`, `scripts/main.gd`, `scripts/track.gd`, `scripts/pause_menu.gd`
- `scripts/ui/song_launch_transition_visual.gd`, `scripts/ui/beat_file_picker.gd`, `scripts/ui/library_composition.gd`, `scripts/ui/note_speed_dialog.gd`, `scripts/v18/ui_accessibility.gd`

Removed: `scenes/chart_editor.tscn`, `scripts/chart_editor.gd`, `scripts/chart_timeline_view.gd`, `scripts/chart_waveform_view.gd`, and the three scripts' `.uid` files.

QA updates:

- `tests/release_gate.py`
- `tests/loading_presentation_test.gd`, `tests/loading_readiness_probe.gd` (new, plus `.uid` files)
- `tests/app_shell_navigation_lifecycle_test.gd`, `tests/main_menu_standalone_fallback_test.gd`, `tests/phase4_ui_foundation_test.gd`, `tests/records_foundation_test.gd`
- `tests/current_release_contract_test.py`, `tests/v1860_waveform_studio_static_test.py`, `tests/v1870_player_creator_static_test.py`, `tests/v1870_generator_reliability_static_test.py`
- `tests/chart_editor_polish_v167_test.gd`, `tests/v1870_generator_integration_test.gd`, `tests/ui_capture.gd`

This document is also new. Pre-existing dirty changes were preserved; this inventory is not the entire worktree's diff. No release-gate test entry was removed. Retired editor-only assertions now check its absence; live timing, scoring, chart resolution, input, records, import/export, and navigation assertions remain.

## Verification and limits

- Strict Godot import/parser/warning validation passes through the gate.
- New loading presentation suite passes headlessly and with actual OpenGL rendering; captures were inspected in an isolated temporary directory.
- Navigation, input snapshot, Reverse, readability, Phase 4 layout, live records, desktop Library layout, level packs, authoritative launch resolution, and Library interaction suites passed in a complete release-gate run.
- Gate failure criteria are unchanged. Existing shutdown resource-retention/ObjectDB diagnostics are still printed; they were not suppressed. One earlier run hit the previously observed live-records timeout; a complete subsequent run passed.
- Old non-gate historical editor regression scripts may still describe the retired feature. They are not a claim that Chart Studio remains supported.
- A new export is required to test these changes in the standalone executable. Subjective transition feel and true cold-launch timing on the player's machine still benefit from manual review.
