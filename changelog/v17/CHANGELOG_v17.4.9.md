# Beat UP! v17.4.9 — First-Time Player UX / How To Play Finalization

## Objective

Make Beta 1 understandable without the developer standing beside the player. v17.4.9 finalizes the first-run onboarding and HOW TO PLAY flow while leaving gameplay charts and timing behavior unchanged.

## First-run onboarding

- Added a versioned onboarding flag in `user://settings.cfg`.
- A normal release export automatically opens HOW TO PLAY once after the first splash/menu reveal.
- Editor/debug runs do not auto-open the tutorial, keeping development and UI regression testing deterministic.
- Opening HOW TO PLAY marks the v17.4.9 tutorial as seen; it remains available manually from Main Menu.
- First-run Back action is labeled `Skip tutorial` so the onboarding is never a hard gate.
- Reset Defaults preserves onboarding completion instead of unexpectedly reopening first-run training on the next launch.

## Input setup

- Step 01 is now an actual input setup screen instead of only explanatory copy.
- Added direct `8-DIR NUMPAD` and `4-DIR ARROWS` selectors inside HOW TO PLAY.
- 8-Direction Numpad is clearly identified as the intended Beat UP! control scheme.
- Numpad mapping explicitly documents 7/8/9, 4/6, 1/2/3 and states that Numpad 5 is unused.
- 4-Direction Arrow mode is presented as the fallback for keyboards without a physical numpad.
- The chosen input mode is saved immediately and stays synchronized with Settings.

## Tutorial input conflict fix

- Fixed an important 4K tutorial bug where Left/Right Arrow were consumed as page navigation shortcuts.
- In 4-Direction mode, all arrow keys now reach the interactive tutorial/practice as gameplay inputs.
- Left/Right page shortcuts remain available in 8-Direction Numpad mode where they cannot conflict with note input.

## Timing explanation

- Reworded Step 02 around the actual receptor/hit-zone behavior.
- Added explicit judgement order and matching gameplay colors:
  - PERFECT = pink
  - GREAT = green
  - GOOD = cyan
  - MISS = red
- Added a Calibration recommendation for players who consistently perceive early/late hits.
- Corrected the tutorial visual, which previously colored GREAT/GOOD differently from gameplay.

## Note rules

- Tutorial now accurately documents the mechanics present in the current build:
  - blue normal cardinal notes;
  - orange diagonals in 8-Direction mode;
  - red Reverse notes;
  - gold SPACE hit-zone cue.
- Reverse wording now explicitly says to press the direction opposite the arrow being displayed.
- SPACE is visualized as a gold approach cue around the receptor instead of being presented as an ordinary traveling note.
- Bomb is intentionally not documented because v17.4.9 gameplay/charts do not currently contain a Bomb note implementation.

## Interactive practice

- Rebuilt the short practice phrase to include Normal, Reverse, and SPACE cues.
- Practice automatically adapts to 8-Direction Numpad or 4-Direction Arrow mode.
- Reverse practice displays the red opposite arrow and asks for the correct opposite input.
- SPACE practice uses a closing gold cue around the hit zone.
- Practice judgement colors now match live gameplay.
- `R` still restarts practice.
- Completing practice changes the primary action to `Play a song →`.

## UI polish

- HOW TO PLAY tab labels simplified to INPUT / TIMING / NOTES / PRACTICE.
- Added current-input status and recommended/fallback labeling.
- Main Menu HOW TO PLAY description now reflects interactive training and practice.

## Explicitly unchanged

- No chart JSON was modified.
- No note timestamps, BPM, beat offsets, or density were changed.
- No chart generator rebalance was performed.
- v17.4.8 timing/calibration hardening remains intact.
- No beta telemetry/player analytics added yet.
- No `validation.txt`.
## Hotfix 1 — GDScript parser compatibility

- Fixed a parser error in `_refresh_tutorial_input_style_controls()` where Godot could not infer `selected` from an untyped temporary button array.
- Tutorial input buttons are now stored as `Array[Button]`, the loop variable is explicitly typed as `Button`, and local style values use explicit `bool`, `Color`, `float`, and `String` types.
- This is a compile-time compatibility fix only; tutorial behavior, charts, gameplay timing, and calibration behavior are unchanged.

