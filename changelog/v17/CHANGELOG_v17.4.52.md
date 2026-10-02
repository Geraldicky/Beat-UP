# Beat UP! v17.4.52 — osu!-inspired Details & Ranking

## Song Library
- Reworked the selected-song information hierarchy using the same architectural idea as osu!lazer's song-select details area: metadata stays visible while a dedicated Details / Ranking section changes context below it.
- Added interactive `DETAILS` and `RANKING` tabs. Ranking is the default view so the player's record is immediately visible.
- Added a chart breakdown view with Normal-note, Reverse-note, and SPACE counts sourced directly from the selected chart.
- Added chart status, input mode, star rating, progression state, and recommended difficulty to the Details view.
- Reworked Personal Best into a local ranking presentation with `#1 LOCAL RECORD`, grade, score, accuracy, max combo, play count context, FC state, and judgement breakdown.
- Added a compact ranking context strip showing `LOCAL / SCORE / 4K|8K / STANDARD|RANDOM` without pretending Beat UP! has online leaderboards.
- Tab accents follow the selected difficulty colour and switch with a short fade rather than rebuilding the Song Library.

## Integrity
- No chart JSON was modified.
- No song background was modified.
- No scoring, judgement, timing, audio-preview, or gameplay behaviour was changed.
- No build/manifest JSON files were added.
