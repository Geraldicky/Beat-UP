# Beat UP! v17.4.9 — First-Time Player UX QA

Use a release export for the first-run auto-open checks. Editor/debug builds intentionally do not force onboarding.

## A. Clean first launch

1. Remove/rename the Beat UP! `user://settings.cfg` for a clean profile.
2. Launch a release export.
3. Let the splash finish normally.

Pass:
- Main Menu reveal completes cleanly.
- HOW TO PLAY opens automatically once.
- Header reads `FIRST RUN TRAINING`.
- Back action reads `Skip tutorial`.
- Player can skip without being trapped.

Relaunch the game.

Pass:
- tutorial does not auto-open again;
- HOW TO PLAY remains available from Main Menu.

## B. 8-Direction Numpad path

On Step 01 choose `8-DIR NUMPAD`.

Pass:
- status says `8-DIRECTION NUMPAD · RECOMMENDED`;
- numpad visual shows 7/8/9, 4/6, 1/2/3;
- Numpad 5 is shown as REST/unused;
- pressing numpad direction keys flashes the matching visual;
- Settings reflects 8-Direction after leaving tutorial.

## C. 4-Direction Arrow fallback

Choose `4-DIR ARROWS`.

Pass:
- status says `4-DIRECTION ARROWS · FALLBACK`;
- Up/Right/Down/Left visual is displayed;
- all four arrow keys work as tutorial inputs;
- Left/Right do NOT unexpectedly change tutorial pages;
- Settings reflects 4-Direction after leaving tutorial.

## D. Timing page

Pass:
- text clearly says notes move right-to-left into the hit zone;
- visual judgement colors match gameplay:
  - PERFECT pink;
  - GREAT green;
  - GOOD cyan;
  - MISS red;
- Calibration is mentioned as the fix for consistently early/late perceived timing.

## E. Notes page

In 8-Direction mode verify:
- Normal = blue outline;
- Diagonal = orange outline;
- Reverse = red outline and opposite input rule;
- SPACE = gold receptor/approach cue.

In 4-Direction mode verify:
- diagonal tutorial card is omitted;
- Normal, Reverse, and SPACE remain understandable.

## F. Practice

Run the complete eight-cue practice phrase in both input modes.

Pass:
- Normal cues accept the displayed direction;
- Reverse cues require the opposite direction;
- SPACE cue requires Space;
- too-early input can show WAIT;
- incorrect input shows WRONG;
- judgement colors match gameplay;
- R restarts practice;
- completion displays `PRACTICE COMPLETE`;
- final button becomes `Play a song →` and enters Song Select.

## G. Navigation

Pass:
- Escape leaves HOW TO PLAY;
- Back/Skip returns Main Menu;
- tabs can jump directly between tutorial pages;
- Previous works where applicable;
- 8-Direction mode may use Left/Right page shortcuts;
- 4-Direction mode reserves arrows for note input.

## H. Layout

Check at minimum:
- 1280×720;
- 1600×900;
- 1920×1080;
- windowed and fullscreen.

Pass:
- input selector does not overlap copy/tip/buttons;
- practice visual remains readable;
- no tutorial text is clipped;
- bottom actions remain reachable.

## I. Regression gate

Pass:
- Main Menu still opens normally after returning from Song Select;
- Settings still persists input style;
- Calibration still opens/returns correctly;
- v17.4.8 timing behavior is unchanged;
- all bundled chart JSON files are byte-identical to v17.4.8.
