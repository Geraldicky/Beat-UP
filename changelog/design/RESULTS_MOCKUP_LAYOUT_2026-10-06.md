# Results mockup composition

## Follow-up: simplified presentation

The user-requested revision replaces the timing/progress cards and boxed
judgement list with a frameless four-column PERFORMANCE strip. Max Combo is
now beside Accuracy; actual counts, reveal and action locking are retained.
The underlying timeline data model remains available but graphs are hidden.
Play Again / Back to Library are right-aligned. Run chips align to the bottom
of the 180px-scaled jacket, with a flexible spacer and compact single-line
artist. Rank/Mods use matching 14px-scaled rounded borders and arc accents,
not square corner brackets.

The apparent background grid came from overlapping alpha veil strips, not
the pool artwork. It is replaced with a continuous GradientTexture2D; edge
strips no longer overlap. The generic randomized pool is unchanged.

The original implementation notes below describe the preceding composition.

Supersedes the outcome-stage composition. Actual Godot scene, not a mockup:
compact RESULT rail; jacket/title/artist/run context upper left; glass rank
card left, score/accuracy beside it, judgement list right; timing scatter,
combo/progress timeline and mods/special-note summaries below. Bottom has only
Play Again and Song Library; duplicated Retry/top navigation and Next Up omitted.
CLEAR/CALCULATING and redundant Perfect Rate remain hidden presentation state.

Six new generated transparent rank-letter sprites are in assets/ui/ranks.
Prompt/original-output provenance is in that folder's README. Shader palette
gives D/C/B/A/S/SS distinct red/orange/green/blue/cyan/gold hues while retaining
the same luminous face/halo family. PNG alpha is unchanged.

Scoped numeric typography uses Rajdhani Medium from Google Fonts' official
repository https://github.com/google/fonts/tree/main/ofl/rajdhani.
Bundled TTF and OFL license allow offline deterministic rendering. Score's
native value remains available to the existing model/tests; custom drawing
renders eight digits with dim leading zeros, without changing its numeric
value. Accuracy uses the same squared technical numeral family.

Timing/progress receive deep copies of the existing telemetry events; no
synthetic dots in production. Missing timelines show an honest unavailable
state (including replay runs lacking this telemetry). The timeline is exposed
read-only before telemetry finalization clears its session and attached to
the presentation snapshot AFTER existing record/replay persistence. No replay
or record format change, no new judgement tracking or timing logic. Existing
signed timing errors, target timestamps, judgements and maximum combo are used.

Fullscreen imagery still uses BackgroundSession's generic randomized pool,
not jacket art or a new artwork pipeline. Readability veils are relaxed to
match the reference's atmospheric presentation. Actual artwork differs from
the supplied mockup according to the chosen generic pool image.

Layout is resolution-proportional with scaled desktop tokens at 720p/900p/1080p.
Wrapped song metadata settles after container sorting before the reveal grows
visible. Regression tests protect header/outcome/analysis/action containment,
no overlap, actual value/asset/palette mapping, missing data, deep-copy ownership,
PB/save errors and single-action locking. Reveal/audio/action-unlock timing,
scoring/rank thresholds, navigation/input/gameplay rules and 18.7.0.1 unchanged.

Verification: RESULT_REDESIGN_TEST, RESULT_ACTIONS_V166_TEST and the v17.4.12
result model checks PASS. Render/layout inspected at 1280x720, 1600x900 and
1920x1080. Full tests/release_gate.py with Godot 4.7.1 exits 0:
RELEASE GATE: PASS (see any printed shutdown warnings). Strict import/parser/
warning validation passes; existing runtime scene teardown retention warnings
remain printed, not suppressed. An earlier live-records timeout did not recur
in its focused rerun or the final full gate.
