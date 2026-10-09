# Main Menu / Song Library continuity

Beat UP! source of truth: AppShell previously faded both complete resident screens
in parallel, then invoked `shell_will_resume`. Library randomized ambience there;
Main Menu's music synchronization also randomized it. Its background controller
used child-local visibility and started an additional 280 ms fade / 750 ms zoom.

Now BackgroundSession prepares a random generic-pool texture without publishing
state. Preparation is bounded to 3 seconds; failure retains the current background
and cannot publish a late completion. AppShell keeps its existing transaction and
locks during preparation. A presentation-only temporary backdrop blends ambience
while foregrounds exit for 80 ms and enter for 120 ms, never overlapping. The
prepared state commits between these phases. Library retires its old async poll
and applies the cached texture immediately. Resume does not randomize again.
Catalog, records, preview and selection work retain their existing owners.

Main Menu uses a 93% neutral scrim, matching Library's approximately 7% ambient
exposure. Repeat-visit fade/zoom is removed; effective tree visibility replaces
child-local visibility checks in the background controller. Startup alone owns
boot foreground animation; MainMenuVisual no longer has a competing ready tween.
Rollback does not create a new Library background. Music activation is unchanged.

## Reference research (principles only)

- Relevant audited osu! code: `osu.Game/Screens/OsuScreen.cs` (`OsuScreen`) and
  `osu.Game.Tests/Visual/TestSceneOsuScreenStack.cs` (`TestSceneOsuScreenStack`),
  at `b267e64503973cf8c1183e72c9b870240bb57883`.
- Flow: screen enter/resume applies presentation defaults; background lifecycle
  is explicit and current-screen checks guard delayed logo work.
- Ownership: screens own lifecycle participation; persistent music is external.
- Lifecycle: enter/resume/suspend/exit govern background and logo presentation.
- Problem solved: transient or stale screen presentation must not commandeer
  current presentation or persistent state.
- Reusable principle: prepare before reveal, guard stale work and test repeated
  navigation; separate persistent ambience from transient foregrounds.
- osu!-specific implementation: background stacks, screen dependencies, Bindables.
- Beat UP! equivalents: existing AppShell, BackgroundSession, Startup/controller,
  SongLibrary/SongSelectVisual and persistent MusicSession.
- Adaptation: narrow texture preparation and non-overlapping foreground handoff.
- Do not copy: ScreenStack, DI, additional managers, osu! layouts/assets.
- Regression implications: observe every transition frame, one background commit,
  final texture on first reveal, no late swap/zoom, and existing transaction,
  MusicSession, selection, authoritative Play and mode/input regressions intact.

Motion guidance from `ui-animation`: this frequent navigation needs continuity,
not decorative delight. One restrained 200 ms handoff replaces stacked motion.
No screen layout, gameplay rule, chart content or application version was changed.
