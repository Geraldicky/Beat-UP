# Beat UP! v17.4.10 — Menu & Navigation QA

Run this pass before moving to gameplay presentation polish.

## A. Main Menu return context

From Main Menu:
- Open HOW TO PLAY → Esc/Back → HOW TO PLAY should remain highlighted.
- Open CALIBRATION → Back → CALIBRATION should remain highlighted.
- Open SETTINGS → Back → SETTINGS should remain highlighted.
- Open CREDITS → Back → CREDITS should remain highlighted.
- Open EXIT → Stay/Esc → EXIT should remain highlighted.

Pass if there is no unexplained jump back to PLAY.

## B. Song Library keyboard model

With no modal/search field active:
- Up/Down changes song.
- Left/Right changes difficulty.
- Enter starts the selected chart.
- F1 opens MODS.
- Slash or Ctrl+F focuses Search.
- Esc returns to Main Menu.

Repeat after:
- clicking a song with the mouse;
- clicking a difficulty with the mouse;
- opening and closing MODS;
- entering and leaving Search;
- returning from gameplay;
- returning from Result Screen.

Pass if controls retain the same meaning every time.

## C. Search escape behavior

1. Focus Search with `/`.
2. Type text.
3. Press Esc.

Expected:
- query clears;
- Search focus exits;
- Song Library stays open.

Repeat with an already-empty Search field.

Expected:
- first Esc exits Search only;
- a later Esc exits Song Library.

## D. Song/difficulty restoration

1. Select a non-default song and difficulty.
2. Return to Main Menu.
3. Re-enter Song Library.

Expected:
- the previous valid song and difficulty are restored.

Then restart the game and enter Song Library again.

Expected:
- valid previous selection is restored;
- if the saved song no longer exists, library falls back safely.

## E. Transition race check

Rapidly press/click Play twice.
Rapidly press Back twice.
Try pressing another library action while the transition cover is appearing.

Pass if:
- only one transition occurs;
- no duplicate gameplay start;
- no double scene change;
- no preview audio continues behind gameplay/Main Menu.

## F. Pause navigation

During gameplay:
1. Esc → Pause.
2. Use Left/Right repeatedly.
3. Verify circular order:
   Song Library ↔ Retry ↔ Settings ↔ Resume.
4. Open Settings.
5. Esc → Pause Menu.
6. Esc → Resume gameplay.

Pass if focus and state are deterministic.

## G. Result action lock

Finish/debug-open a Result Screen.

During the reveal animation, repeatedly press Enter, KP5, and Esc.

Expected:
- no retry;
- no exit to Song Library;
- no duplicate transition.

After reveal finishes:
- Enter/Retry works;
- Esc/Song Library works;
- Left/Right switches between the two action buttons.

## H. Regression

Confirm:
- HOW TO PLAY still works;
- Calibration still opens/applies/returns;
- timing offsets remain saved;
- Pause/Resume timing remains stable;
- Result statistics still animate correctly;
- all songs/charts still load.

## Release gate

v17.4.10 passes when all navigation paths can be completed without:
- dead ends;
- double activation;
- stale focus;
- surprise Back behavior;
- preview audio leaks;
- unexpected song/difficulty reset.
