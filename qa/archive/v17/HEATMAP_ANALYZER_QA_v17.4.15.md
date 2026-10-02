# Beat UP! v17.4.15 — Heatmap Analyzer QA

## Objective
Add an offline analyzer that can load local telemetry session JSON files and visualize:
- where players get `MISS / GOOD / GREAT / PERFECT`
- which time windows are the main difficulty hotspots
- per-song and per-session summary statistics

## Manual QA checklist
1. Open `tools/playtest_heatmap_analyzer/beatup_heatmap_analyzer.html` in Chrome / Edge / Firefox.
2. Load 1 valid session JSON file.
   - Expect the summary cards to populate.
   - Expect one song summary row.
   - Expect one session row.
   - Expect the heatmap to render an Aggregate row and one session row.
3. Load multiple valid session JSON files from different songs.
   - Expect summary cards to update for all loaded sessions.
   - Expect song summary table to list each song+difficulty group.
   - Expect heatmap prompt to ask for a single song if filter is too broad.
4. Filter to a single song.
   - Expect timeline heatmap to render.
   - Expect hotspot list to show worst time windows.
5. Click any heatmap cell.
   - Expect bin details panel to show counts and timing info.
6. Change bin size between 2 / 3 / 5 / 10 sec.
   - Expect heatmap and hotspots to re-render.
7. Clear loaded sessions.
   - Expect UI to reset cleanly.

## Expected limitations
- This is a browser-based offline utility, not an in-game scene.
- Demo loader only works if the sample JSON files exist relative to the extracted project path.
- Folder loading with `webkitdirectory` works best in Chromium-based browsers.
