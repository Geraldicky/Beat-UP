# Beat UP! v17.4.33 — Navigation Lifecycle Cleanup

## Architecture
- Added global `NavigationController` as the single navigation entry point for Main Menu, Song Library, and Gameplay.
- AppShell now owns route changes, gameplay-exit preparation, hidden gameplay cleanup, and screen transition input locking.
- Added explicit resident-screen lifecycle callbacks: `shell_will_resume`, `shell_did_resume`, `shell_will_suspend`, and `shell_did_suspend`.
- Main Menu, Song Library, and Gameplay no longer need to search the scene tree for AppShell during normal navigation.

## Behaviour preserved
- Main Menu ↔ Song Library remains a resident UI transition with no generic loading screen.
- Song Library → Gameplay keeps the selected-artwork handoff.
- Gameplay → Song Library/Main Menu still cleans gameplay only after the destination is visible.
- Global MusicSession, SongSelectionState, and BackgroundSession from v17.4.31–32 remain authoritative.
- Song Library selection and focus are restored through lifecycle context instead of scattered return-path logic.

## Compatibility
- AppShell keeps compatibility aliases for older `show_*_from_gameplay` callers.
- Standalone scene fallbacks still use SceneTransition where required.
- Built-in charts are unchanged.
