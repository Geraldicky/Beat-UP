# Beat UP! v18.0.0.1 — UI Hierarchy Correction

This corrective patch reduces redundant UI copy and rebuilds Song Library details/ranking around the compact hierarchy used by mature rhythm-game song-select screens.

## Song Library
- DETAILS now keeps only core chart information: title/artist, difficulty + stars, BPM, length, total notes, input mode, Reverse count, and SPACE count.
- Removed the large Normal/Reverse/SPACE breakdown grid, recommendation copy, progress graph, and weak-section copy from Song Details. The underlying progress/analytics data remains intact.
- RANKING is LOCAL-only for now.
- Added ranking filters for 8K, 8K + Random, 4K, and 4K + Random.
- Ranking identity uses the exact selected input style + Random state, so 4K scores never appear in 8K rankings and vice versa.
- Local ranking now renders a scrollable score list with place, grade, score, accuracy, max combo, and FC marker.
- Ranking can still be sorted by Score or Date.
- Removed duplicate ranking context text because scope/sort/mod filters already communicate the state.
- Song cards now show only title, artist, BPM, and concise difficulty data. UNPLAYED and REC labels are no longer repeated on every row.
- Library summary copy and action labels were shortened.

## Global redundancy pass
- Main Menu: removed redundant CURRENT PLAYING kicker and ENTER footer hint.
- Settings: removed duplicate section headers under already-labelled tabs and shortened timing labels.
- Result Screen: removed redundant PERFORMANCE SUMMARY, LONGEST CHAIN, TIMING PRECISION, and keyboard shortcut footer copy.
- Pause Quick Settings: shortened INPUT OFFSET / AUDIO OFFSET labels.

## Integrity
- No chart, OGG, or song-background assets are changed by this patch.
- No manifest JSON is created.
