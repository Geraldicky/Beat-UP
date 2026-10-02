# Beat UP! v17.2.5 — 16:9 Layout Rebalance

## Focus
- correct the Song Browser proportions for a 16:9 target display;
- stop the right-side song cards from stretching across too much of the screen;
- keep row height and the v17.2.4 hierarchy polish while making the browser closer to osu-style proportions.

## Changes
- Changed logical design viewport from 1440×900 (16:10) to 1600×900 (16:9).
- Kept `canvas_items` + `expand`, now with a native 16:9 logical canvas for more predictable scaling to 1920×1080 / 2560×1440 / 3840×2160.
- Rebalanced the main Song Library body from roughly 36/64 to 60/40 (artwork/info vs browser).
- Reduced browser minimum width from 780 px to 600 px logical.
- Reworked the upper-right utility area into two compact rows:
  - row 1: Search + Artist + Difficulty
  - row 2: Progress + Sort
- Preserved v17.2.4 row heights, selected cluster treatment, Personal Best compacting, Random treatment, and thin scrollbar.
- Updated version to 17.2.5.

## Frozen systems
- No chart or timing changes.
- No background changes.
- No gameplay changes.
- No progression/data changes.
