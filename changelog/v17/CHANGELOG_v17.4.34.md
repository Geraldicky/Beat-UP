# Beat UP! v17.4.34 — Controller Separation

## Goal
Reduce `startup.gd` ownership before Beta 1 hardening. The startup scene remains the composition root, while focused controllers now own Main Menu interaction, shared artwork/background behaviour, and Now Playing presentation.

## Architecture
- Added `scripts/controllers/main_menu_controller.gd`.
  - Owns Main Menu selection/focus state.
  - Owns hover/focus tweening.
  - Owns rhythm-reactive diamond/button pulse logic.
- Added `scripts/controllers/main_menu_background_controller.gd`.
  - Owns random Main Menu artwork selection.
  - Owns global `SongSelectionState` / `BackgroundSession` subscriptions for the Main Menu.
  - Owns Main Menu ↔ Song Library music/background synchronization and compatibility handoff.
  - Owns background transition animation.
- Added `scripts/controllers/now_playing_controller.gd`.
  - Owns title/artist/transport state.
  - Owns progress/duration presentation.
  - Owns play/pause presentation and transport icon state.
- Existing global `NavigationController` remains the navigation authority introduced in v17.4.33.
- `startup.gd` now delegates these responsibilities through small compatibility wrappers, so existing scene signal bindings and shell hooks do not need to change.

## Behaviour preserved
- Global `MusicSession`, `SongSelectionState`, and `BackgroundSession` remain authoritative.
- Returning from Song Library continues the selected song instead of restarting it.
- Main Menu random music remains a cold/default path only.
- Main Menu visual layout and gameplay/chart behaviour are unchanged.

## Small fix
- Now Playing progress no longer visually jumps to `0:00` while music is paused. The shared playback clock remains visible at its actual paused position.

## Verification scope
- Built-in chart JSON files are intentionally untouched.
- No manifest JSON is generated.
- No `validation.txt` is generated.
