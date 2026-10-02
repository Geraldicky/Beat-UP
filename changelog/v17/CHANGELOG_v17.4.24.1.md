# Beat UP! v17.4.24.1 — Return-to-Library Frame-Stall Hotfix

- Removed the redundant Song Library catalog/UI rebuild after returning from gameplay.
- Returning to the same song no longer rebuilds filtered song rows just to restore selection.
- Hidden gameplay no longer calls the legacy `show_level_select()` reset path, which reloaded all charts and rebuilt an embedded Song Select UI.
- Gameplay cleanup now runs after the handoff and detaches note nodes in idle-frame batches.
- Main Menu/Song Library remain resident under AppShell; no loading screen was reintroduced.
- Built-in charts are unchanged.
