# Beat UP! v17.4.1 — Song Library MODS Integration

## Summary
Moves gameplay mode selection into a dedicated Song Library MODS panel and folds Random into the same modifier workflow.

## Added
- Added a dedicated **MODS** button to the Song Library action row.
- Added a custom in-game MODS overlay inspired by rhythm-game mod selection workflows.
- Added **8 KEY** and **4 KEY** mode cards inside the MODS panel.
- Added **RANDOM** as a selectable modifier inside the MODS panel.
- Added active-mod summary text (`8 KEY / 4 KEY`, `RANDOM / NO MODIFIERS`).
- Added `F1` shortcut to open the MODS panel.
- Added click-outside and Escape behavior to close the panel.

## Changed
- Removed the standalone RANDOM button from the Song Library action row.
- The Song Library action row is now `BACK / MODS / PLAY`.
- MODS button text summarizes the current setup, e.g. `MODS · 8K` or `MODS · 4K + RND`.
- Input-style changes made from the Song Library are refreshed immediately before gameplay starts.
- Song information continues to reflect the active 8-key/4-key mode and Random state.
- Keyboard hint now advertises `F1 MODS` instead of a standalone Random shortcut.

## Preserved
- Reverse rates and Reverse behavior from v17.4 remain unchanged.
- Bomb remains fully removed.
- Existing chart timing, directions, special-note placement, audio, backgrounds, progression, and scoring are unchanged.
- Input Style remains persisted through the existing user settings system.

## Packaging
- Changelog remains under `changelog/`.
- No `VALIDATION*.txt` files are included.
