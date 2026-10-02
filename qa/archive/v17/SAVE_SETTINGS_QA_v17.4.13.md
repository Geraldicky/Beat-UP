# Beat UP! v17.4.13 — Save Data & Settings Reliability QA

Goal: Beta 1 must not silently lose preferences or best-level progression when settings contain malformed values or a save is interrupted/corrupted.

## A. Normal restart persistence

Set intentionally recognizable values, close Beat UP! normally, then relaunch:
- Master Volume
- Menu SFX toggle and volume
- Song Background Opacity
- Input Offset
- Audio Offset
- Input Style
- Resolution
- Window Mode
- VSync
- last selected Song Library song/difficulty

Pass: all values return exactly as expected and display settings re-apply in a standalone export.

## B. Pause-settings persistence

During gameplay:
1. Pause.
2. Change Master Volume, Background Opacity, and timing offsets.
3. Resume.
4. Finish/leave the song.
5. Close and relaunch the game.

Pass: the same settings persist and gameplay background/timing use them on the next run.

## C. Reset Defaults scope

Before reset, complete first-run tutorial and select a non-default song/difficulty. Then press Reset Defaults.

Pass:
- audio/visual/timing/display/input preferences return to defaults;
- first-run tutorial remains completed;
- Song Library continuity is preserved;
- no unrelated ConfigFile sections are deleted.

## D. Corrupt settings recovery

Use a disposable test copy of the user data folder.
1. Change a setting twice so `settings.backup.cfg` exists.
2. Close Beat UP!.
3. Replace the contents of `settings.cfg` with invalid text.
4. Relaunch.

Pass:
- game starts;
- corrupted primary is quarantined as `settings.corrupt.cfg` when possible;
- last known-good backup is restored;
- no crash or parser loop occurs.

## E. Malformed but parseable settings

In a disposable `settings.cfg`, enter values such as:
- background opacity > 100;
- timing offset outside ±200 ms;
- invalid input style;
- invalid window mode;
- resolution below minimum;
- boolean represented as `false` string.

Pass: values are normalized/clamped to safe canonical values and the file becomes valid again.

## F. Best-level stats persistence

Play a song and create a recognizable best score/accuracy. Relaunch and confirm Song Library progression still shows it. Play again with another result and relaunch again.

Pass: `best_level_stats.json` remains valid and progression survives restart.

## G. Best-level stats corruption recovery

Use a disposable test copy.
1. Produce at least two saved result updates so `best_level_stats.json.bak` exists.
2. Close Beat UP!.
3. Corrupt `best_level_stats.json` with invalid JSON.
4. Relaunch.

Pass:
- game does not wipe progression to an empty store if a backup exists;
- corrupted primary is quarantined;
- previous known-good backup is restored automatically.

## H. Interrupted-write model

The persistence model is now:
1. write `.tmp`;
2. parse/verify `.tmp`;
3. rotate primary to backup;
4. promote `.tmp` to primary.

Pass criteria: a crash before promotion leaves either the old primary or its backup recoverable on next launch.

## I. Regression

Confirm unchanged behavior for:
- v17.4.8 timing/calibration;
- v17.4.9 tutorial;
- v17.4.10 navigation;
- v17.4.11 HF2 lane/note/hit-zone/background presentation;
- v17.4.12 Result Screen calculations and reveal lock;
- all 42 deterministic charts.
