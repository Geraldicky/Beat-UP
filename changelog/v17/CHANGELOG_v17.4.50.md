# Beat UP! v17.4.50 — Song Detail / Personal Best Rework

## Focus
This release implements the selected **Option B** direction for Song Library: the player record is presented as one cohesive Personal Best performance card instead of several disconnected record boxes.

## Song detail hierarchy
- Increased selected song title size.
- Increased artist and chart metadata readability.
- Enlarged BPM / LENGTH / NOTES cards and their numeric values.
- Increased progress-status readability while keeping the left panel clean.

## Personal Best card
- Replaced the old Personal Best header + three separate mini-cards with one 520 px performance card.
- Best Rank is now a large focal value in the card header.
- Score, Accuracy, and Max Combo remain separate metrics internally but share one visual container.
- Internal metric backgrounds are intentionally subtle so the parent card, not each mini box, owns the visual hierarchy.
- Judgement breakdown remains at the bottom of the card and is larger/easier to scan.
- The card accent follows the selected chart difficulty color.
- No-record state remains supported without changing score data.

## Scope / integrity
- No chart JSON was modified.
- No timing, choreography, scoring, preview audio, resident-library, or async loading logic was changed.
- v17.4.49.1 Variant type hotfix remains included.
- Existing v17.4.49 Audio Pack remains compatible; audio files were not changed in this release.
