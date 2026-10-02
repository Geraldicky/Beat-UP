# Beat UP! v17.4.23.1 — True Seamless Menu Handoff

## Navigation visual fix
- Removed the global center ribbon / diamond transition from menu navigation.
- Main Menu -> Song Library now keeps the Main Menu visible while Song Library finishes loading, then swaps directly.
- Song Library -> Main Menu uses the same overlay-free handoff.
- Gameplay / Pause / Result -> Song Library no longer displays the ribbon overlay.
- Generic UI actions no longer display a loading-like global transition visual.
- Input remains locked atomically while a destination is being prepared, preventing ESC/click leakage during scene swaps.

## Gameplay launch
- Song Library -> Gameplay still uses the persistent selected-song artwork continuity layer introduced in v17.4.23.
- No spinner, loading text, progress bar, or generic loading scene was reintroduced.

## Cleanup
- Retired `beat_diamond_transition_visual.gd` and the `QuickTransitionVisual` node from the global transition layer.
- Built-in charts are unchanged.
- No manifest JSON is created.
