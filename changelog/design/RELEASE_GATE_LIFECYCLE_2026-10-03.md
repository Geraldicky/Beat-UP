# Release-gate lifecycle follow-up — 2026-10-03

Branch: `ui/song-library-redesign`. Application version: `18.7.0.1` (unchanged).

## Source-of-truth findings

Beat UP!'s runtime trace identified a Main Menu boot tween calling
`_begin_main_menu_under_splash()` after resident-screen suspension. Its
`ensure_music_ready()` → `MenuBGMController.start_menu_music()` →
`MusicSession.ensure_playing()` chain resumed an explicitly paused session and
could reclaim Song Library focus. Cancelling queued Song Library previews alone
could not prevent this independently owned callback.

Main Menu now retires its boot/reveal work at suspend or explicit reactivation.
Failed-navigation restoration honours AppShell's existing
`preserve_music_state` context; it restores presentation without randomising,
replacing or resuming the current track. MusicSession and navigation transaction
ownership remain unchanged.

The retained composition helper created a hidden Button without a parent.
Giving it a screen-owned parent removes the orphan and its TextServer/font RID
errors. Live-records QA now checks for newly orphaned nodes after shell disposal.

Quick runtime suites could quit while SceneTransition's scene warm-ups were
still parsing. SceneTransition joins only its outstanding requests at exit,
before engine class registration is dismantled. Navigation remains asynchronous.
Level-pack QA begins after SceneTree/autoload initialisation and explicitly waits
for normal warm-up completion, with a failing deadline rather than error filtering.

Song Library redesign QA declares the duration helper's dynamic return as String.
InteractionPolish checks metadata existence before reading its previous tween:
Godot treats a null `get_meta` default as an error when the key is absent.
Regression coverage exercises first focus, press and release supersession without
changing motion semantics or suppressing engine diagnostics.

## osu-reference research and adaptation

Inspected source snapshot: ppy/osu
`b267e64503973cf8c1183e72c9b870240bb57883`.

- Relevant classes/files: `osu.Game/Overlays/MusicController.cs` and
  `osu.Game.Tests/Visual/TestSceneOsuScreenStack.cs`, plus the installed skill's
  audio/navigation/song-select/testing references.
- Flow: user transport intent enters MusicController; incidental playback
  readiness respects `UserPauseRequested`. The stack tests exercise adjustment
  restoration on push/exit and inheritance between screens.
- Ownership: osu!'s MusicController owns transport intent; screen lifecycle
  controls track adjustments. Beat UP! retains MusicSession for playback,
  AppShell/NavigationController for route transactions, and Startup for its own
  reveal work.
- Lifecycle: create a screen and its local UI, activate it, suspend its work,
  restore origin state on failure, dispose local nodes and finish owned resource
  work before engine teardown. These fixes change no persistence lifecycle.
- Engineering problem: hidden resident screens and stale callbacks must not
  override the active screen or explicit transport intent.
- Reusable principle: restore only state the transition temporarily owns; retire
  screen-local continuations at lifecycle boundaries; test delayed effects as
  well as immediate transaction results.
- osu!-specific implementation: ScreenStack/dependency/Bindable infrastructure
  remains osu!-specific. No such infrastructure was added to Beat UP!.
- Minimum adaptation: use existing suspend/resume hooks, existing rollback
  metadata, parent ownership and ResourceLoader shutdown completion.
- Do not copy: osu! screen hierarchy, track dependency architecture or visual
  identity. Provisional Song Library selection and authoritative chart resolution
  at Play remain Beat UP!'s unchanged contract.
- Regression implications: verify user-paused streams survive failed navigation
  from both origins, wait past stale boot callbacks, retain focus/lock/signal
  assertions, detect orphan UI nodes, and treat parser/runtime errors as failures.

Release-gate suites and their failure criteria are retained unchanged.

## Verification

Focused live-records, navigation, level-pack, authoritative-launch and Song
Library redesign regressions were rerun after their fixes. The full command:

```powershell
python tests/release_gate.py --godot "C:\Users\USER\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe"
```

completed with exit code `0` and:

```text
RELEASE GATE: PASS (see any printed shutdown warnings)
```

All 13 static suites, strict import/parser/warning validation, and all 11 runtime
suites passed. Existing shutdown ObjectDB/resource-retention diagnostics and the
deliberate malformed-settings recovery warnings remain visible. No release-gate
filter, suite, chart, scoring/timing rule, settings persistence or version changed.
