# Beat UP! v17.4.10 — Menu & Navigation Polish

## Objective

Harden the complete Beta 1 navigation flow without changing authored charts:

Splash → Main Menu → Song Library → Gameplay → Pause → Result → Retry / Song Library.

## Changes

### Main Menu focus restoration
- Returning from SETTINGS now restores focus/highlight to SETTINGS instead of jumping back to PLAY.
- Returning from HOW TO PLAY restores the HOW TO PLAY context.
- Returning from CREDITS restores the CREDITS context.
- Cancelling EXIT restores the EXIT highlight.
- Returning from Quick Calibration restores the CALIBRATION context.
- Returning from Calibration opened through Settings returns focus to the Calibration action.
- First-run tutorial still returns toward PLAY so onboarding does not strand a new player.

### Song Library navigation hardening
- Last played/selected song and difficulty are remembered in `user://settings.cfg`.
- A fresh visit to the Song Library restores that song/difficulty when they still exist.
- Keyboard row navigation no longer leaves stale GUI focus on song/difficulty rows.
- Dynamic song and difficulty rows no longer capture keyboard focus; the documented global controls remain authoritative:
  - Up/Down = song
  - Left/Right = difficulty
  - Enter = play
  - Slash / Ctrl+F = search
  - F1 = mods
  - Esc = back
- Closing MODS releases its temporary focus instead of leaving ENTER bound to reopening MODS.
- Leaving an empty Search field with Esc now exits Search first instead of unexpectedly leaving the Song Library.
- Enter/Down while Search is focused exits Search cleanly back to library navigation.
- During transition-out, all major Song Library controls are locked to prevent double activation/races.
- Song preview is still faded/stopped before leaving the library.
- Footer control hint now explicitly includes Search and Back.

### Pause Menu
- Added explicit circular left/right focus neighbors for:
  Song Library ↔ Retry ↔ Settings ↔ Resume.
- Resume remains the default pause focus.
- Esc behavior remains:
  Settings → Pause Menu → Gameplay.

### Result Screen
- Result action buttons are locked until the result reveal finishes.
- Prevents buffered/accidental Enter/KP5/Esc from immediately retrying or leaving while the result animation is still resolving.
- After reveal, Retry receives default focus.
- Song Library and Retry have explicit left/right focus neighbors.
- Main gameplay input checks the Result Screen navigation-ready state before honoring result shortcuts.

### Regression boundaries
- No chart generator changes.
- No chart JSON changes.
- No BPM, beat offset, event timestamp, note density, or deterministic chart logic changes.
- v17.4.8 timing/calibration hardening remains intact.
- v17.4.9 first-time player tutorial remains intact.
- No `validation.txt`.

## Beta QA priorities

1. Main Menu → each sub-screen → Back restores the expected context.
2. Song Library keyboard navigation remains stable after Search and MODS.
3. Selected song/difficulty survives Main Menu round-trips.
4. Pause navigation cycles predictably.
5. Result Screen cannot be accidentally skipped before reveal completion.
6. Retry and Song Library actions work normally after result reveal.
