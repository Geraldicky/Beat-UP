# Beat UP! v17.4.5 — Gameplay Readability & Reverse Visual Pass

## Summary
This pass improves moment-to-moment gameplay readability after the FLAC chart pass, while folding the planned 4K/8K consistency QA into the same build.

## Reverse readability
- Reverse notes now use a darker red-tinted fill instead of sharing the exact normal-note fill.
- Reverse notes now have a stronger primary red outline plus a restrained secondary outer diamond.
- Added a small universal reverse cue on the note so Reverse can be recognized before reading the arrow direction.
- The cue is shared by 8K and 4K and does not add text/numbers to the note body.

## 4K input consistency
- Reworked diagonal-to-cardinal runtime mapping for 4 KEY mode.
- Mapping remains deterministic for authored charts.
- Added history-aware penalties for accidental repeated-key runs and mechanical ABAB loops.
- Authored cardinal directions are preserved.
- Static simulation across all 42 charts produced a maximum 4K same-key run of 2 notes.
- 8K authored direction data is unchanged.

## Gameplay HUD/readability
- Gameplay difficulty label now also shows the active input mode (`4K` / `8K`).
- Random modifier is shown compactly as `RND` during gameplay.
- Countdown now explicitly shows `4 KEY · ARROW KEYS` or `8 KEY · NUMPAD` before the song starts.
- Reduced HUD panel opacity/border weight so the note field and song background remain easier to read.

## Hit feedback
- Judgment text uses a clearer semibold treatment with a restrained dark outline.
- Judgment motion is slightly faster and less floaty.
- Hit-zone diamonds are now brighter/whiter and easier to acquire visually.
- Lane receptor guide changed from saturated pink to a neutral white guide so it does not compete with Reverse red.
- Hit effects were reduced in opacity/scale to keep MASTER passages readable.
- Feedback colors now match the judgment language consistently:
  - PERFECT = pink
  - GREAT = green
  - GOOD = cyan
  - MISS = red

## Frozen content
- 42/42 chart JSON files are byte-identical to v17.4.3.
- 14/14 song backgrounds are byte-identical to v17.4.3.
- 14/14 gameplay OGG files are byte-identical to v17.4.3.
- Reverse density remains approximately 6% Normal / 12% Hard / 18% Master.
- Bomb remains removed.
- No `VALIDATION*.txt` files are included.

## Runtime note
Godot runtime is not available in the build environment, so this release received static/source validation only.
