# Results hero-stage layout

Replaces the tall left summary / isolated right rank with a new composition:

- Compact song jacket/title/context header and contextual personal-best badge.
- Upper hero stage: generated rank glyph on the left; score, PB delta/save
  status and accuracy/max-combo/% PERFECT on the right.
- Full-width lower judgement strip with semantic colors and count totals.
- Compact SPACE and REVERSE hit/total/miss summary beneath the strip.
- Footer retains keyboard hints, Song Library and primary Retry actions.

The rank no longer draws a persistent progress rail resembling unfinished
loading. Original six generated PNGs are retained; fitted glyph space is
larger relative to its container. Numeric reveal, rank charge sound, thresholds,
one-action lock, finalized data snapshot and navigation signals are unchanged.
The additional Details container fades alongside the existing metrics, using
the same short reveal timing and cancellation owner (no extra timeline).

Inline special-note rolling labels explicitly reserve the final glyph width;
their native empty text otherwise causes drawn digits to overlap neighbouring
miss metadata in an HBox. Only Results sizes these controls; the shared rolling
label implementation and other screens are unchanged.

MainMargin desktop scale: 144 horizontal / 48 vertical at 1080p, scaled down
for 900p and 720p. Containers handle distribution; no independently positioned
metric labels. Results regression checks viewport containment, hero and
full-width strip non-overlap, inline digit bounds, all six rank sprites,
semantic colors, missing jacket/empty special strip, long title, PB/save states,
canonical values, snapshot isolation and action locking.

Scope: scenes/result_screen.tscn, scripts/result_screen.gd,
scripts/ui/result_rank_meter.gd, tests/result_redesign_test.gd and this note.
No gameplay/scoring, records, chart, MusicSession, navigation, global theme,
Song Library or settings changes. Version remains 18.7.0.1.

Verification: result_redesign_test PASS headless and real OpenGL at all three
resolutions, result_actions_v166 PASS, result_beta_finalization_v17412 PASS,
phase4_ui_foundation PASS, app_shell_navigation_lifecycle PASS, strict import/
parser/warning validation PASS and git diff --check PASS. Complete release gate
exited 0: RELEASE GATE: PASS (see any printed shutdown warnings). Existing
ObjectDB/resource-retention shutdown diagnostics remain visible; no gate
criteria changed. Render review: 1920x1080 and 1280x720 screenshots inspected
under C:\Users\USER\AppData\Local\Temp\beatup-results-final-layout-pwz1bv53.
