# Beat UP! v17.3.7.1 — Compact Song Info Pass

## Scope
UI-only follow-up to v17.3.7. The selected-song information block was visually oversized and consumed too much of the left column.

## Changes
- Reduced the title/meta/chart-description scale slightly so the hierarchy stays strong without dominating the screen.
- Converted BPM / Length / Notes into compact, left-aligned metric cards instead of full-width cards.
- Reduced metric-card height, padding, border weight, and typography size.
- Compacted the Personal Best block to a ~406 px rail with three smaller Score / Accuracy / Max Combo cards.
- Reduced spacing between metadata, progress, Personal Best, and judgement summary.
- Kept the bottom Back / Random / Play action cluster anchored by the existing flexible spacer.

## Frozen systems
- Song Library sorting/filter logic from v17.3.7 is unchanged.
- All 75 chart JSON files are unchanged.
- All 25 song backgrounds are unchanged.
- Audio, gameplay, chart timing, notes, progression, custom dropdowns, and song browser motion are unchanged.

## Packaging
- Changelog remains in `changelog/`.
- No `VALIDATION*.txt` files are included.
