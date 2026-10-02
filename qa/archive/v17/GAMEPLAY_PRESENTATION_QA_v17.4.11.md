# Beat UP! v17.4.11 — Gameplay Presentation QA

## A. Per-song background

Play at least five visually different songs. Confirm:

- gameplay artwork matches the selected song;
- Normal/Hard/Master of the same song use the same background;
- Retry keeps the same artwork;
- returning to Song Library does not leak the gameplay background through its UI;
- Result uses its existing result backdrop behavior.

## B. Background opacity

Test Startup Settings and Pause Settings at:

- 0%;
- 25%;
- 62%;
- 100%.

Confirm:

- lower values visibly dim the artwork by blending it into the base-dark background;
- 0% leaves a clean dark gameplay background;
- 100% does not alter note/chart timing;
- Pause slider updates the running gameplay immediately;
- value persists after relaunch.

## C. Gameplay readability

Test songs with both bright and dark artwork. Confirm:

- white note fill is clearly visible;
- normal blue outline is readable;
- diagonal orange outline is readable;
- reverse red outline is readable;
- arrows remain visible inside white notes;
- SPACE remains immediately distinguishable as gold;
- white hit receptor remains visible against both bright and dark backgrounds.

## D. HUD

At 1280x720 and a higher-resolution fullscreen mode confirm:

- score is top-left;
- song context does not overlap score or Pause;
- Pause remains top-right;
- combo remains lower-left;
- top HUD text stays readable on bright artwork;
- score odometer still rolls correctly.

## E. Judgment feedback regression

Confirm no new judgment-feedback presentation was introduced. PERFECT/GREAT/GOOD/MISS and existing receptor hit feedback should behave exactly as before this presentation pass.

## F. Gameplay regression

Confirm:

- calibration offsets unchanged;
- pause/resume sync unchanged;
- Retry timing unchanged;
- deterministic charts unchanged;
- scroll speed still follows BPM;
- all bundled songs still load.
