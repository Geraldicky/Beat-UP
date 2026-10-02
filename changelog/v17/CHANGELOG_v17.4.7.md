# Beat UP! v17.4.7 — Result Screen Finalization

## Goal
Finalize the player-facing Result Screen for the first beta playtest line while keeping the v17.4.6 gameplay/chart baseline frozen.

## Result presentation
- Result Screen now carries the played song's background artwork into the result view with a restrained dark readability veil.
- Top accent now follows chart difficulty:
  - Normal = cyan
  - Hard = gold
  - Master = pink
- Reduced panel opacity so the result view feels less like a dashboard and lets the song art breathe.
- Tightened result-card sizing and action-button footprint for a cleaner 16:9 composition.

## Performance summary
- Added an animated judgement-distribution strip above the judgement counts.
- Corrected judgement color language to match gameplay:
  - PERFECT = pink
  - GREAT = green
  - GOOD = cyan
  - MISS = red
- Final Score, Accuracy, Max Combo, Perfect Rate, judgement totals, rank meter, and rank-fill SFX remain part of the reveal sequence.
- FULL COMBO / EXCELLENT / GREAT CLEAR / CLEAR remains displayed directly under the final rank.

## Special notes
- SPACE now reports hits together with total prompts and misses.
- REVERSE now reports hits together with total Reverse notes and misses.
- Reverse totals are derived from the frozen chart at result time; chart files are not modified.

## Controls
- Result actions remain exactly two player-facing actions:
  - SONG LIBRARY
  - RETRY
- Footer hint now explicitly reads `ENTER RETRY · ESC SONG LIBRARY`.

## Frozen systems
- No chart regeneration.
- No note timing, direction, density, Reverse placement, Space timing, BPM, or scroll-speed changes.
- No song audio or background asset modifications.
- 4K / 8K / Random gameplay behavior remains from v17.4.6.

## Packaging
- Project version bumped to 17.4.7.
- Changelog stored in `changelog/`.
- No `VALIDATION*.txt` files are included.
