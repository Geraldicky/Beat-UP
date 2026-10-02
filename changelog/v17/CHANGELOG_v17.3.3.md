# Beat UP! v17.3.3 — Custom Dropdown System

## Focus
Replace Godot's native `OptionButton` / `PopupMenu` dropdown experience with a reusable Beat UP!-specific dropdown component across current player-facing and editor-facing screens.

## Changes
- Added `scripts/ui/beat_dropdown.gd` as the reusable dropdown implementation.
- Dropdown menus are now composed from Beat UP! controls (`Button`, `PanelContainer`, `ScrollContainer`, `VBoxContainer`) instead of native `PopupMenu` lists.
- Added custom open/close animation, outside-click dismissal, Escape dismissal, focus handling, selected-row accent, hover state, and thin custom scrollbar.
- Added a custom cyan/pink chevron state instead of the native Godot OptionButton arrow.
- Preserved an OptionButton-like data API (`add_item`, `clear`, `select`, `selected`, item IDs, metadata, item count, `item_selected`) so existing feature logic remains intact.
- Replaced all four Song Library dropdowns: Artist, Difficulty, Progress, Sort.
- Replaced all three Display Settings dropdowns: Resolution, Window Mode, VSync.
- Replaced all four Chart Editor dropdowns: Song, Difficulty, Snap, Tempo Mode.
- Updated tests/capture helpers so they no longer cast the replaced controls to `OptionButton`.
- Version updated to 17.3.3.

## Frozen systems
- No chart changes.
- No song background asset changes.
- No gameplay/timing changes.
- No progression changes.
- No Song Library card-art or motion redesign in this pass.
