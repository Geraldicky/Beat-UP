# Beat UP! v17.4.5.3 — BPM-Based Scroll Speed & Dense Note Readability

## Summary
Gameplay note travel speed is now driven directly by each song's BPM. There is no player-facing independent note-speed setting.

## Changed
- Reworked BPM-to-scroll-speed curve for dense-pattern readability.
- 120 BPM is the reference point for the travel-speed calculation.
- Higher BPM always produces a shorter note travel time until the safety cap is reached.
- Updated travel curve parameters:
  - reference BPM: `120`
  - base travel time: `1.80 s`
  - BPM influence exponent: `1.80`
  - minimum travel time: `0.50 s`
  - maximum travel time: `2.60 s`
- Big Daddy at 190 BPM now uses approximately `0.787 s` travel time.
- FREEDOM DiVE↓ at ~222 BPM uses approximately `0.594 s` travel time.
- Aleph-0 at 250 BPM reaches the `0.50 s` safety cap.

## Gameplay Integrity
- No chart regeneration in this release.
- 42/42 chart JSON files are byte-identical to v17.4.5.2.
- Note timing, direction, Reverse placement, SPACE events, BPM metadata, and difficulty data are unchanged.
- 14 song backgrounds are unchanged.
- OGG playback assets are unchanged.
- 4K / 8K deterministic state fix from v17.4.5.2 is preserved.
- Random remains the only modifier allowed to randomize direction layouts.

## Packaging
- Changelog remains under `changelog/`.
- No `VALIDATION*.txt` files are included.
