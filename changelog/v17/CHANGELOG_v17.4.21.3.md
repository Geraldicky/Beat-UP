# Beat UP! v17.4.21.3 — Splash Session-State Hotfix

## Fixed
- The launch splash no longer replays when returning from Song Library, Chart Studio, or gameplay.
- Splash state now lives in the `AppSessionState` autoload for the lifetime of the running game process.
- `startup.tscn` can be recreated any number of times without being mistaken for a fresh application launch.
- Returning to Main Menu suppresses the splash before the first rendered frame, preventing a one-frame logo flash.

## Intended behavior
- Fresh application process: splash plays once.
- Main Menu → Song Library → Back: no splash.
- Main Menu → Chart Studio → Back: no splash.
- Gameplay → Main Menu: no splash.
- Quit game and launch it again: splash plays once again.

No chart, gameplay, scoring, timing, telemetry, or balancing changes.
