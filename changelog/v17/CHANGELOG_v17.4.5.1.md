# Beat UP! v17.4.5.1 — Reverse Visual Simplification + Anti-Orbit Direction Hotfix

## Reverse visual
- Reverse now uses the exact same note fill, shape, arrow, and normal single-border thickness as standard notes.
- The only visual difference is the red outline.
- Removed the extra outer Reverse diamond / double-outline treatment.
- Removed the small Reverse cue icon.

## Direction pattern hotfix
- Re-authored direction values for all 42 active charts while preserving every event timestamp and note type.
- Removed the ordered direction bias that could force long numpad perimeter loops such as `8-9-6-3-2-1-4-7` and rotations of the same pattern.
- Added a hard guard against 4+ consecutive clockwise/counter-clockwise perimeter steps.
- Added guards against repeated 3–8 note blocks and short ABAB-style repetition.
- Direction complexity remains difficulty-aware, with more cardinal emphasis on Normal and more diagonal pressure on Master.
- Beat/subdivision placement can influence direction complexity without forcing a fixed geometric sequence.

## Chart integrity scope
- 42/42 event counts unchanged.
- 42/42 event timestamps unchanged.
- 42/42 note types unchanged.
- Reverse count unchanged: 4,539 total.
- Space-event timing unchanged.
- Only `event.direction` and `direction_profile` were intentionally rewritten.
- Maximum detected continuous numpad-perimeter rotation is now 3 notes; v17.4.5 had runs above 30 notes in some charts.

## Generator
- Future chart generation uses the same anti-orbit guard and no longer gives a large bonus to canned clockwise/counter-clockwise direction banks.

## Packaging
- Version bumped to 17.4.5.1.
- No `VALIDATION*.txt` files are included.
