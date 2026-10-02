# Beat UP! v17.4.21.2 — Navigation State + Beat Diamond Transition

## Fixed
- Returning from Song Library no longer replays the application splash.
- Startup splash is now an app-session boot sequence and is consumed only once per launch.
- Main Menu returns from Song Library, Chart Studio, and gameplay restore directly into the menu instead of replaying its launch sequence.
- Return focus is restored to the relevant menu entry (PLAY for Song Library/gameplay, CHART STUDIO for Chart Studio).

## Changed
- Replaced the plain lightweight fade with a Beat Diamond transition inspired by the gameplay hit-zone diamond.
- Quick navigation uses a short expanding/collapsing diamond, accent outlines, a small beat strip, and destination-aware accent colors.
- Quick transition duration remains intentionally short: ~90 ms cover + ~110 ms reveal.
- Full loading screens remain reserved for actual heavy work such as gameplay/audio loading.

## Preserved
- Chart Studio OGG + FLAC workflow.
- Local anonymous player profile and telemetry.
- All built-in charts and chart balancing.
- Gameplay timing, scoring, note visuals, result flow, and settings behavior.
