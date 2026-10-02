# Beat UP! v17.4.37 — Seamless Gameplay Pre-roll + Skip Intro

## Gameplay launch
- Removed the universal READY / 3 / 2 / 1 sequence from initial song launch.
- Song audio now starts immediately after the shared Song Library -> Gameplay artwork handoff finishes.
- Lane/HUD reveal and audio release happen in the same transition phase, so the song itself becomes the preparation lead-in.
- Retry follows the same no-countdown launch path.

## Long intros
- Added a contextual `SKIP INTRO >` button for charts whose first playable event is 8 seconds or later.
- Skip destination is calculated dynamically from the first playable note/SPACE event and current note travel time.
- The skip always lands before the first playable event, preserving a readable approach window.
- The button disappears automatically once skipping is no longer useful.

## Pause / resume
- READY is not used for initial launch anymore.
- Pause -> Resume keeps a short 3 / 2 / 1 safety countdown so the player can return their hands to the controls without losing timing.

## Data integrity
- No built-in chart timing or note data changed.
- No manifest JSON files were added.
