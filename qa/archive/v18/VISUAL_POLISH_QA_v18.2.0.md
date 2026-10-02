# Beat UP! v18.2.0 Visual Polish QA

## Target resolutions
- 1280×720
- 1600×900
- 1920×1080
- 2560×1440
- 16:10 equivalent window sizes

## Manual checks
1. Main Menu: inactive buttons remain readable; Now Playing remains full-width and unobtrusive.
2. Song Library: selected title is visible, Now Playing is distinct, Details/Ranking do not duplicate metadata, 4K/8K+Random records remain separated.
3. Gameplay: HUD never overlaps lane/receptor at the target resolutions; judgement and combo remain readable over bright backgrounds.
4. Pause: every icon exposes an action label by hover/focus and Resume is the default action.
5. Result: Special panel disappears if the chart has no Reverse/SPACE result data.
6. Settings: tab context is sufficient without repeated section headers.
7. Calibration: Apply is disabled until sampling completes.
8. How To Play / Chart Studio: no clipping or horizontal overflow at 1280×720.
9. Navigation: Main Menu ↔ Song Library route animation has no synchronous hitch.
10. Release UI: Song Library contains no import/refresh/export telemetry actions.

## Performance budgets
- Resident route transition target: <= 260 ms
- Preview request-to-start target: <= 320 ms
- Frame spike reporting threshold: 25 ms

Godot runtime validation is still required on the target PC/export.
