# Beat UP! v17.4 — Reverse Core + 4-Arrow Input Mode

## Core gameplay
- Removed Bomb from the active gameplay ruleset, chart generation, Chart Editor tools, tutorial note list, and Result Screen metrics.
- Migrated all 75 standard charts to a Reverse-only special-note ruleset while preserving note timestamps and authored directions.
- Bomb events from existing charts were converted into Reverse notes rather than deleting timing events.

## Reverse density rework
Reverse is now a core reading mechanic instead of a rare special note.

Target density across the full library:
- Normal: ~6% Reverse
- Hard: ~12% Reverse
- Master: ~18% Reverse

The 75 migrated charts now contain:
- Normal: 596 Reverse / 9,895 directional notes (~6.02%)
- Hard: 1,647 Reverse / 13,737 directional notes (~11.99%)
- Master: 3,145 Reverse / 17,461 directional notes (~18.01%)

Future Chart Editor generation uses the same difficulty-scaled Reverse targets, with opening guards, SPACE-note separation, phrase/intensity preference, and anti-back-to-back spacing.

## 4-Arrow mode
Added a global Input Style setting:
- 8-Direction (Numpad) — default
- 4-Direction (Arrow Keys)

4-Arrow mode:
- uses Up / Left / Right / Down keys;
- keeps the exact same chart timestamps;
- maps authored diagonal vocabulary deterministically onto compatible cardinal patterns;
- keeps Reverse behavior intact (opposite shown direction);
- supports Random Mode;
- updates the gameplay input compass;
- is shown in Song Library chart info as `4-ARROW` or `8-DIR`.

## Settings / tutorial / calibration
- Added Input Style dropdown to Settings.
- Input Style persists in `user://settings.cfg`.
- How To Play now explains both Numpad and Arrow Key styles and no longer teaches Bomb.
- Tutorial practice adapts to the selected input style.
- Calibration accepts Arrow Keys when 4-Arrow mode is active.

## Chart Editor / Results
- Removed the Add Bomb tool and keyboard Bomb shortcut.
- Chart save metadata now records Reverse only.
- Removed Bomb Evade / Bomb Hit metrics from Result Screen.

## Packaging
- Project version: 17.4
- Changelogs remain under `changelog/`.
- No `VALIDATION*.txt` files are included.
