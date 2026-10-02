# Beat UP! Playtest Heatmap Analyzer (v17.4.15)

## Purpose
This offline tool helps inspect Beat UP! telemetry session JSON files and visualize which sections of a song are causing the most `MISS`, `GOOD`, `GREAT`, and `PERFECT` outcomes.

## Main features
- Load **one or multiple** session JSON files.
- Load a whole **sessions folder** at once in Chrome / Edge.
- Filter by **song**, **difficulty**, and **session**.
- Timeline **heatmap** with judgement composition per time bin.
- **Hotspot list** to surface the worst time windows.
- Aggregate **per-song summary** and full **session table**.
- Inspect timing bias and event-density trends.

## How to use
### Option A — easiest
1. Extract the project zip.
2. Open `tools/playtest_heatmap_analyzer/open_heatmap_analyzer.bat`.
3. Use the file picker to load JSON sessions.

### Option B — manual
Open `tools/playtest_heatmap_analyzer/beatup_heatmap_analyzer.html` in your browser.

## Where the JSON files come from
Beat UP! telemetry writes local session files under:
- `user://playtest_data/sessions/`

On Windows this is typically similar to:
- `%APPDATA%\Godot\app_userdata\Beat UP!\playtest_data\sessions`

## Notes
- The analyzer is **offline only**.
- It does **not** upload telemetry anywhere.
- If you filter multiple songs at once, the heatmap asks you to choose a single song before rendering the timeline.

## Included demo data
This package also includes 4 sample telemetry sessions in `tools/playtest_heatmap_analyzer/samples/`. You can load them manually with the file picker to test the analyzer immediately.
