# Beat UP! v17.4.12 — Result Screen Beta Finalization QA

Goal: guarantee that Result Screen is a faithful, deterministic summary of the completed run before Beta 1 telemetry is introduced.

## Result data integrity
- Score on Result equals final gameplay score.
- PERFECT + GREAT + GOOD + MISS equals authored directional-note count.
- Accuracy is recomputed from the judgement breakdown using the current weighted model.
- Perfect Rate is PERFECT / judged directional notes.
- Rank is derived from that exact final Accuracy.
- SPACE hit + miss equals authored SPACE-event count.
- Reverse hit + miss equals authored Reverse-note count.
- Max Combo is non-negative and preserved from gameplay.

## End-of-song reconciliation
Test an ordinary clear and deliberately stop pressing near the final notes. Any unresolved directional note or SPACE event must be finalized as MISS before personal-best storage and Result Screen display.

## Reveal / SFX
- FINAL RANK meter begins at zero and stops exactly at final Accuracy.
- Rank changes only when meter crosses configured thresholds.
- Rank-fill ticking stops once.
- Final rank lock SFX plays once.
- Final displayed values exactly equal targets after animation.

## Input lock
During the entire reveal, repeatedly press Enter, Esc, Numpad 5, and click the action area. Nothing may Retry or leave the screen. Actions unlock only after the reveal and short input-settle delay.

## Required scenarios
1. Normal mixed clear.
2. Low-score / many-MISS clear.
3. Full Combo.
4. All directional notes MISS.
5. SPACE misses.
6. Reverse misses.
7. Retry repeatedly from Result.
8. Song Library repeatedly from Result.
9. Developer F4 Result preview in debug/editor builds.

## Regression gate
- No chart JSON changes.
- No timing/calibration changes.
- No lane/note/hit-zone palette changes from v17.4.11 Hotfix 2.
- No background-opacity behavior changes.
