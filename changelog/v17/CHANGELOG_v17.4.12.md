# Beat UP! v17.4.12 — Result Screen Beta Finalization

## Objective
Finalize Result Screen behavior for Beta 1 so every displayed metric comes from one reconciled run snapshot and navigation cannot trigger during the reveal.

## Changes

### Final judgement reconciliation
- Before result calculation and personal-best storage, any unresolved authored directional notes are recorded as MISS.
- Any unresolved authored SPACE events are also recorded as MISS.
- Warnings are emitted if runtime judged counts exceed authored counts.

### Result snapshot as source of truth
- Added a single result snapshot builder in gameplay.
- Score, judgement counts, special counts, rank label, and run metadata are passed together.
- Full Combo now requires a non-empty run and complete resolution of both directional notes and SPACE events.

### Derived metric consistency
- Result Screen recomputes Accuracy directly from PERFECT/GREAT/GOOD/MISS using the configured weighted model.
- Perfect Rate is recomputed from final counts.
- Rank is recomputed from the exact Accuracy shown on screen.
- SPACE and Reverse hit counts are clamped against authored totals.

### Reveal hardening
- Added reveal-generation guards so stale/deferred callbacks cannot unlock an old Result Screen.
- Hiding the Result Screen cancels rank-fill audio and the active reveal tween.
- Final values are force-synchronized when reveal completes.
- Rank-fill finish/lock is idempotent per reveal.

### Navigation lock
- Retry and Song Library actions remain disabled throughout the result animation.
- Added a short 80 ms input-settle delay after action reveal before navigation unlocks.
- Button handlers re-check navigation readiness and disable themselves immediately after a valid action.

### Debug / QA
- F4 result preview now uses the same weighted Accuracy model as real gameplay.
- Added `tests/result_beta_finalization_v17412_test.gd`.
- Added `qa/archive/v17/RESULT_SCREEN_QA_v17.4.12.md`.

## Explicitly unchanged
- Charts / BPM / timestamps / density.
- Runtime timing and calibration.
- BPM-derived scroll speed.
- Gameplay background system.
- v17.4.11 Hotfix 2 lane, note palette, and hit-zone presentation.
