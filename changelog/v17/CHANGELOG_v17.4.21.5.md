# Beat UP! v17.4.21.5 — Transition Input Lock Hotfix

## Fixed
- Fixed a navigation deadlock when ESC was pressed during Main Menu -> Song Library transition.
- Scene transitions now consume keyboard/mouse/joypad button input until reveal completes.
- Song Library refuses outbound navigation while the global transition manager is busy, preventing its controls from being locked for a navigation request that cannot start.
- Startup also ignores/consumes navigation input while its outbound transition is active.

## Unchanged
- Built-in charts, gameplay, scoring, telemetry payload structure, Chart Studio workflow, and Beat Diamond visuals are unchanged.
- No build manifest JSON is generated.
