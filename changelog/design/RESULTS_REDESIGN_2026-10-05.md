# Results redesign

## Presentation

Replaces the circular rank-meter/card composition with a matte, two-column
results stage: left score/accuracy/performance summary, right generated rank
letter sprite. Header contains the managed song jacket, title and existing
run-context metadata. Jackets never replace the generic randomized background.
BackgroundSession's supplied generic background is deliberately subdued.

Score is the strongest summary value. Accuracy, max combo and perfect rate
follow; judgement counts retain PERFECT pink, GREAT green, GOOD cyan, MISS red.
SPACE/reverse totals and misses remain available when relevant. Thin separator
rules replace filled metric cards. Retry is primary, Song Library secondary,
with native existing SVG icons, keyboard focus and visible shortcut guidance.

Rank lettering SS/S/A/B/C/D uses six individually generated transparent metallic
letter PNGs, without a shared frame or native text overlay. Transparent margins
are fitted at runtime without editing the original images. Rank thresholds remain
the existing Results owner's responsibility. CLEAR/FULL COMBO/etc. is below
the emblem, not squeezed into its lower point. The former ring progress is
now a restrained linear charge under the emblem; existing reveal/audio lifecycle
and navigation lock remain unchanged.

NEW PERSONAL BEST uses the existing finalized flag. Existing previous-best
data is shown as delta for a PB, otherwise a previous-best summary. Save errors
remain contextual and override that summary. The accuracy delta is now computed
from the same count-derived accuracy displayed by Results, rather than a stale
supplied accuracy field. This is display consistency, not a scoring change.

## Boundaries

No changes to main gameplay finalization, scoring policy, record persistence,
chart resolution, input snapshots, navigation transactions, MusicSession or
chart content. `set_result()` still deep-copies the finalized snapshot; actions
unlock at the existing reveal completion and accept one navigation request.
Application version remains 18.7.0.1 on ui/song-library-redesign.

## Asset generation

Built-in image-generation tool used, original alpha preserved. Project asset:
`assets/ui/ranks/rank_{d,c,b,a,s,ss}.png`; exact generation prompts are
documented in `assets/ui/ranks/README.md`. No external downloaded assets.

## Verification

`result_redesign_test.gd` exercises actual Results at 1280x720, 1600x900 and
1920x1080: geometry, score/count-derived accuracy/rank, PB delta, semantic colors,
alpha, managed jacket versus generic background, snapshot isolation, all six
rank letters, save failure, hidden state, Retry/Back and duplicate action locking.
Added to the release gate. Optional capture directory environment variable only
saves rendered PNGs; it does not modify production paths or settings.

Historical result action test now validates the approved reveal lock and
count-derived 92.9% sample accuracy, rather than expecting actions before a
result exists or the inconsistent supplied 92.5%. Rank-charge SFX lifecycle
assertions are retained. Historical static heading checks follow the new copy.

Real OpenGL renders at all three desktop resolutions were captured in isolated
user data and inspected (1080p and 720p). Human review is still recommended for
the emblem's material treatment, visual balance and artwork-specific contrast.

Final checks: new Results suite PASS (headless and real OpenGL), result action
SFX/reveal regression PASS, result model regression PASS, static heading
contract PASS, strict Godot import/parser/warning validation PASS,
`git diff --check` PASS. Full release gate rerun exited 0 with
`RELEASE GATE: PASS (see any printed shutdown warnings)`.
An earlier full run timed out in authoritative launch resolution; that suite
passed independently and in the complete rerun without chart-resolution edits.
Existing shutdown ObjectDB/resource-retention diagnostics remain visible.

Final render capture directory:
`C:\Users\USER\AppData\Local\Temp\beatup-results-final-capture-dm1u8akc`.

## Rank-letter correction

User clarified that the generated assets must be the actual D/C/B/A/S/SS
letters, not a frame. Six transparent metallic glyph sprites now replace the
frame, which was removed from project assets (original generated file retained).
The native label is only an unsupported-rank fallback, never overlaid on a
supported glyph. Mapping and alpha tests cover all six ranks; thresholds,
score/counts and reveal/navigation behavior remain unchanged.

Correction checks: Results redesign suite PASS headless and real OpenGL at
720p/900p/1080p, result actions PASS, result model PASS, Godot import without
parser/errors/warnings PASS, diff whitespace check PASS. Full gate was run
again: Results, records, input snapshots, reverse, readability, pacing,
navigation, loading, standalone fallback and Phase 4 passed; the run then
timed out after 120 seconds in `live_records_foundation_test.gd`. No unrelated
test/production fixes or release-gate criteria changes were made.
Latest inspected captures: `C:\Users\USER\AppData\Local\Temp\beatup-rank-capture-lf7kdch_`.
