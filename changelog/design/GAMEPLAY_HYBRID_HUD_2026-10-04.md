# Gameplay hybrid HUD

Beat UP! source of truth: `main.gd` owns HUD presentation and updates; Track owns
visual geometry around an unchanged HitPoint. Notes retain their existing arrows,
normal/diagonal colours and reverse outline-only renderer. BackgroundSession is
still the fullscreen randomized generic-pool source. Song cover art is used only
for a small cached HUD jacket, never selected as the fullscreen background.

Mockup adaptation: song jacket/title/artist/difficulty/BPM/progress/time occupy
the top-left rail; larger score and accuracy occupy the top-right, separate from
Pause. A neutral 64% scrim subdues bright randomized imagery without changing the
persisted background-opacity setting or source. Song context has no boxed card.
The input compass moves below the lane, keeping incoming notes clear.
The white receptor is visually enlarged without moving HitPoint or SpawnPoint.
Lane alignment lines are restrained; no orbit rings, trails or new gameplay
abstractions were added. Score formulas, timing, input, projection, Random,
replay and navigation contracts remain unchanged.

## Performance panel and natural audio completion follow-up

The top-right panel draws a thin clipped-corner frame with separate score and
accuracy rows. Following visual review, gameplay rank and its divider/marks
were removed; the compact panel keeps focus on notes. Rank remains in Results,
with canonical grading unchanged.

MusicSession deliberately sets loop flags on cached preview AudioStreams.
Gameplay previously assigned the same cached resource, inheriting preview
looping: no natural `finished` signal arrived and the audio clock wrapped.
Gameplay now duplicates the resolved stream and disables looping on its own
Ogg/MP3/WAV resource. MusicSession's preview resource/policy is not modified.
The existing offset-aware tail clock, `end_fight()` idempotency and finalized
Results snapshot handoff remain the completion owners. Practice section looping
is still managed by its existing seek/restart lifecycle, not stream looping.

### osu-reference: score/results boundary

- Relevant inspected source: `osu.Game/Screens/Ranking/ResultsScreen.cs` and
  `osu.Game.Tests/Rulesets/Scoring/ScoreProcessorTest.cs` at the audited pin.
- Flow: processor data becomes ScoreInfo, then Results consumes it.
- Ownership: processors own scoring; Results presents an authoritative snapshot.
- Lifecycle: completed score enters Results; retry starts another play lifecycle.
- Why: presentation must not reconstruct or own live gameplay completion.
- Principle: finalize once and render authoritative state.
- osu-specific: ScoreInfo, Bindables, ranking services and Screen hierarchy.
- Beat UP! equivalent: main.gd counters, `end_fight()`, result snapshot and Result UI.
- Adaptation: isolate per-run audio loop policy and keep rank in Results;
  keep existing result finalization unchanged.
- Do not copy: score formula, framework clock or ranking infrastructure.
- Regressions: shared preview stays looped, gameplay stream does not; natural
  audio completion happens exactly once, Results becomes visible, no restart;
  score/accuracy remain readable. Tests use isolated QA storage.

## osu-reference research

- Inspected `osu.Game/Screens/Play/HUDOverlay.cs` / `HUDOverlay` and
  `osu.Game.Tests/Visual/Gameplay/TestSceneHUDOverlay.cs` / `TestSceneHUDOverlay`
  at audited pin `b267e64503973cf8c1183e72c9b870240bb57883`.
- Flow: HUD presentation observes existing gameplay/processor state.
- Ownership: HUD controls presentation, not judgement/scoring authority.
- Lifecycle: components bind on load; visibility/layout tracks play and display
  state while interactive exit controls remain available.
- Problem solved: readable peripheral information without obscuring playfield
  or exit controls.
- Reusable principle: consume existing values, separate peripheral context from
  timing targets and check layout/visibility behavior.
- osu!-specific: skinnable containers, Bindables, ruleset components, DI.
- Beat UP! equivalent: main.gd HUD, existing ScoreDigits, RhythmTrack and note.gd.
- Adaptation: change only existing presentation geometry/styles and jacket binding.
- Do not copy: osu! skins/layout, ruleset hierarchy or processor architecture.
- Regression implications: title/artist and score/accuracy must not overlap;
  desktop resolutions must keep HUD, Pause, compass and judgement on screen;
  timing receptor coordinates and locked semantic note colours remain unchanged.

Runtime layout coverage extends the existing isolated Phase 4 suite at 1280x720,
1600x900 and 1920x1080. Retired static score-row coordinates are replaced by that
behavioral overlap contract, not dummy legacy layout code. Version stays 18.7.0.1.

## Playfield polish after checkpoint f1c2508

The white receptor retains its existing centre/size and now uses a crisp 4px
stroke. Judgement colour stays on short FX, not the receptor itself. Space adds
a fixed gold diamond centred on the same HitPoint while the existing approach
diamond still follows its unchanged timing/progress calculations. The Space
caption is dark with gold text rather than a solid gold bar.

The lane uses a stronger neutral matte scrim (86%, 90% receptor deck) so bright
generic backgrounds cannot compete with note outlines/arrows. Note rendering,
reverse shape/red-outline-only semantics and all motion/timing coordinates are
unchanged. BackgroundSession continues to select the generic randomized pool.

Input feedback is a compact square-key compass with vector direction arrows,
more legible inactive labels, mode caption and gold Space-binding caption.
At run launch only, Track receives the captured input snapshot for presentation.
The visual copies labels; canonical input matching, replay keys and persistence
remain in their existing owners. Custom bindings do not alter direction semantics.

Motion-design adaptation: judgement is frequent keyboard feedback, so text is
fully visible immediately; total lifetime is 300ms with 100ms opacity exit,
98% entry scale and 3px/4px displacement, using existing quadratic easing.
No springs, bounce, particles or continuously pulsing key cells were added.
The existing effect-intensity control still scales displacement/scale.

osu-reference mapping (audited HUDOverlay and TestSceneHUDOverlay paths above):
flow is run state → peripheral presentation; ownership remains main/Track;
lifecycle captures labels at launch and clears transient activity on reset;
the problem is readable information without obscuring the playfield; principle
is that HUD observes authoritative state rather than creating gameplay rules;
osu-specific Bindables/skins/DI remain excluded; Beat UP! equivalent is the
existing run snapshot, Track and compass; adaptation is only scoped visuals and
launch-time labels; do not copy rulesets or score processors; regressions cover
custom 4K/8K/Space labels, immutable snapshot data, immediate semantic judgement
colours, fixed gold target/white receptor, natural completion and desktop layout.
