# Beat UP! — CHANGELOG v17.4.15

## Objective
Add an **offline Playtest Heatmap Analyzer** so local telemetry JSON can be inspected visually without manual parsing.

## What’s included
- New tool: `tools/playtest_heatmap_analyzer/beatup_heatmap_analyzer.html`
- New launcher: `tools/playtest_heatmap_analyzer/open_heatmap_analyzer.bat`
- New usage guide: `tools/playtest_heatmap_analyzer/README.md`
- New QA note: `qa/archive/v17/HEATMAP_ANALYZER_QA_v17.4.15.md`

## Analyzer capabilities
- Load one or multiple local telemetry `.json` files.
- Filter by song, difficulty, and session.
- Render a **timeline heatmap** using time bins.
- Show judgement composition (`PERFECT / GREAT / GOOD / MISS`) in each bin.
- Surface the worst sections via **Hotspot List**.
- Show per-song summary and full session table.
- Show median hit bias and other quick metrics.

## Notes
- This tool is **offline only**.
- No backend, upload pipeline, or cloud dependency was added.
- No chart data was changed in this version.
