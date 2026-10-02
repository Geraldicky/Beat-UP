# Beat UP! v17.1 — Song Select & Progression Pass

v17.1 continues from the v17.0.1 effect-rollback baseline. The v16.9.1 timing/chart set is intentionally frozen; this release focuses on persistent progression and a more informative Song Library without reintroducing the rejected v17.0 gameplay-effect direction.

## Progression model

- Added persistent per-song/per-difficulty progression fields alongside the existing best-score record.
- `CLEARED` is stored independently from whether the latest run becomes the best-score run.
- `FULL COMBO` is persistent and survives later non-FC runs.
- Full Combo requires:
  - 0 directional misses
  - 0 SPACE misses
  - 0 Bomb triggers
- Added aggregate `best_accuracy`, `best_rank`, and `best_max_combo` fields so each metric remains a true lifetime best even when the highest-score run is a different play.
- Existing save files migrate automatically to progression model `v171`.
- Legacy records are conservatively marked cleared, but legacy FC is not fabricated because older saves did not preserve SPACE/Bomb failure data.
- Random Mode continues to use its separate `::random` record key and does not count toward standard chart completion.

## Song Select

- Difficulty rows now show progression directly:
  - `UNPLAYED`
  - `CLEAR · <rank> · <accuracy>`
  - `FC · <rank> · <accuracy>`
- Recommended difficulty is marked with `REC` in the expanded difficulty list.
- The info panel now displays the current chart progression state and recommended difficulty.
- Song summary rows show per-song cleared/FC counts.
- Library header now shows total standard progression, e.g. `23/39 CLEARED · 6 FC`.
- Added Progress filter:
  - All Progress
  - Unplayed
  - Cleared
  - Full Combo
- Added sorting:
  - Title A–Z
  - Star Rating
  - Best Rank
  - Unplayed First
- Difficulty filtering and progression filtering compose together. For example, `MASTER + UNPLAYED` shows songs whose Master chart has not been cleared.

## Difficulty recommendation

- First unplayed difficulty is recommended.
- A cleared difficulty remains recommended until the player's best accuracy reaches 90%.
- At 90%+ best accuracy, the next available difficulty becomes recommended.
- This is advisory only; all difficulties remain manually selectable.

## Accuracy consistency

- Restored weighted live HUD accuracy so the in-game accuracy display uses the same PERFECT/GREAT/GOOD/MISS weighting as final results.
- This is a non-visual correctness fix and does not restore any v17.0 Gameplay Identity effects.

## Preserved from the stable baseline

- All 39 bundled chart JSON files are byte-identical to v17.0.1 / v16.9.1 timing baseline.
- No chart timing, density, pattern, Reverse, Bomb, or SPACE placement was changed.
- No PERFECT-streak effects, HitCore effects, combo milestone callouts, special-note pulses, or other rejected v17.0 over-effects were restored.

## Validation

See `VALIDATION_v17.1.txt` and `tests/song_select_progression_v171_test.gd`.
