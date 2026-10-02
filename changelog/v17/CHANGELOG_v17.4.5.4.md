# Beat UP! v17.4.5.4 — Burst Readability & Difficulty Budget Pass

## Why this pass exists
Dense sections could become disproportionately difficult to read even when average NPS looked acceptable. The clearest example was Big Daddy HARD around 57–59 seconds: several quarter-beat microbursts at 190 BPM created ~79 ms note gaps, with Reverse notes inside the cluster.

## Changed
- Added a **0.5-second local readability budget** in addition to the existing 1-second density checks.
- Added section-aware density ceilings so Intro/Verse/Bridge/Pre-Chorus are not allowed to spike as hard as Chorus/Climax.
- For high-BPM HARD charts, weak 1/4-beat subdivisions inside already-dense runs are removed before primary/half-beat accents.
- Reverse notes are re-authored onto safer readable accents while keeping the target ratios near:
  - NORMAL: ~6%
  - HARD: ~12%
  - MASTER: ~18%
- Reverse placement now avoids the tightest local clusters whenever enough safer positions exist.
- Directions of every **retained** note remain exactly the same as v17.4.5.3.
- No retained timestamp is moved; the pass only removes overloaded note slots and relocates Reverse type flags.

## Big Daddy HARD example
Around 58.57–59.04 s the old chart contained repeated ~79 ms gaps. The new chart removes those quarter-beat inserts so that the dense stream in this passage resolves to ~157.9 ms spacing (half-beat at 190 BPM), and Reverse notes are moved out of that stream.

## Library impact
Across 42 charts:
- NORMAL: 8,286 → 8,262 notes (-24), 497 Reverse (~6.0%)
- HARD: 11,634 → 11,526 notes (-108), 1,383 Reverse (~12.0%)
- MASTER: 14,689 → 14,614 notes (-75), 2,630 Reverse (~18.0%)

The largest safety reduction is on Aleph-0, where the 250 BPM charts produced the most short-window pressure.

## Future generation
- Added `tools/apply_burst_readability_v17454.py`.
- The FLAC chart generator now automatically applies the v17.4.5.4 readability post-process after generating each chart.

## Frozen systems
- BPM values unchanged.
- Beat offsets unchanged.
- SPACE timings unchanged.
- Direction values unchanged for all retained notes.
- BPM-based scroll speed from v17.4.5.3 unchanged.
- 4K/8K deterministic state system unchanged.
- Audio OGG files unchanged.
- Song backgrounds unchanged.
- Reverse visual style unchanged.
- Bomb remains removed.
- No `VALIDATION*.txt` files are included.
