# Personal note speed and optional Reverse

Beat UP! source-of-truth: gameplay previously computed travel time from BPM
using exponent 1.8 (200 BPM: ~0.72s; 240 BPM: ~0.52s). Player feedback and
explicit approval replace the previous BPM-coupled/no-speed-slider contract.

## Runtime and settings

- UserSettings owns `gameplay/note_travel_time`: 0.6–2.6 seconds, default 1.5.
- Launch captures this value alongside the existing normalized input snapshot.
  Directional spawning/positioning uses the run value, never a live getter.
- Pause/resume preserves it. Retry/new run captures current canonical settings.
- Judgement targets/windows, offsets, audio rate, score formulas and Space
  approach cue remain unchanged. Speed is not part of PB identity.
- New replays record the visual read time and restore it for playback.
- Settings → Timing contains a moving right-to-left preview, actual RhythmNote
  renderer/position formula, white hit diamond, gold Space diamond, presets and
  140/220 BPM density comparison. It never plays audio or judges real input.
- Hidden resident screens stop advancing preview time. This is a miniature lane:
  the travel duration matches gameplay, not its physical screen width.
- Malformed speed normalizes through existing recovery. Variant equality now
  checks type before comparing to avoid String/float normalization exceptions.

## Reverse policy

`reverse_v2_optional`: normalize normal/reverse directional events on the owned
runtime copy, then select a deterministic rounded fraction of ALL directional
events. OFF contains zero reverse; Space is untouched. Source chart/hash remains
unchanged. RANDOM uses its independent RNG. Mod reverse has no score bonus.

Changed authored-reverse charts and enabled mod runs carry the new Reverse
version in score identity; old records/replays are retained in their old scope.
Unchanged normal-only OFF charts keep historical identity. Historical Reverse
replays fail preparation explicitly, before activation, rather than being
silently interpreted using the new rules. No migration of old scores is claimed.

## Generator / chart development

Generator revision 1871 (`BUP-CG-01871`; application remains 18.7.0.1) removes
automatic authored reverse and stamps `optional_reverse_absolute_gap_v1`.
Candidate selection and final global filtering retain beat-grid/musical choices
but enforce absolute minimum gaps: Normal 220ms, Hard 140ms, Master 100ms.
Existing per-second/four-second fatigue caps and direction choreography remain.
These are initial playtest limits, not a claim that every chart is comfortable.
Existing bundled/user chart files are NOT rewritten or regenerated. Their rhythm
density still needs human playtesting; new generated charts use the new policy.

Read-only bundled-chart audit: Aleph 0 Hard/Master reach 60ms minimum gaps;
Everything Will Freeze 62.5ms; Freedom Dive 67.5ms; Ghost 68.2ms;
several 200-BPM charts reach 75ms. Their Normal difficulties reach 120–150ms.
Personal speed cannot remove that authored density. Do not claim the old chart
pack has been rebalanced: targeted regeneration and playtest remain necessary.

## osu-reference research (pinned b267e64503973cf8c1183e72c9b870240bb57883)

- Files/classes: `ManiaRulesetConfigManager`, `DrawableManiaRuleset`,
  `osu.Game.Tests/Visual/Gameplay/TestSceneDrawableScrollingRuleset.cs`.
- Flow: configured scroll speed becomes display time range and object positions.
- Ownership: ruleset config owns preference; scrolling ruleset owns presentation.
- Lifecycle: initialization establishes range; tests advance a controlled clock.
- Why: rendering lifetime/position must agree with the visible time horizon.
- Reusable principle: verify arrival positions independently of target times.
- osu-specific: Bindables, timing/control-point scaling and scrolling rulesets.
- Beat UP! equivalent: UserSettings, main.gd, RhythmNote, ChartTimeline.
- Adaptation: per-run value plus settings preview sharing the existing renderer.
- Do NOT copy: Bindables, ruleset hierarchy, mania layout or clock framework.
- Regression: target arrival unchanged; speed changes neither PB scope nor timing.

Sources inspected (principles only, no copied implementation):
https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game.Rulesets.Mania/Configuration/ManiaRulesetConfigManager.cs
https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game.Rulesets.Mania/UI/DrawableManiaRuleset.cs
https://github.com/ppy/osu/blob/b267e64503973cf8c1183e72c9b870240bb57883/osu.Game.Tests/Visual/Gameplay/TestSceneDrawableScrollingRuleset.cs

## Regression boundaries

QA-guarded `note_readability_test.gd` is part of isolated release-gate runtime
suites. It covers malformed/default speed, launch/Retry/replay snapshot,
pause/resume, BPM independence, unchanged identity/source, historical Reverse
rejection, live preview slider/persistence/arrival, hidden visibility and actual
240-BPM generation for every difficulty. Reverse regression now asserts the
approved optional-only behavior rather than the superseded authored-reverse rule.
