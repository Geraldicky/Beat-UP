# Beat UP! Beta Testing Guide

The build version is displayed in Main Menu > Credits.

## Player flow

1. Launch the game and open the Song Library.
2. Play one built-in chart on Normal, Hard, and Master.
3. Verify pause/resume, calibration offsets, result saving and replay.
4. From Main Menu, pause and resume the Now Playing track and confirm the
   timestamp does not reset. Verify Previous/Next changes the audio, metadata,
   and artwork.
5. Play a Reverse-heavy chart and confirm Reverse uses the Normal-note shape
   with a red outline only.

## Custom levels

1. Import an existing chart JSON or `.beatup-pack` from Song Library.
2. Confirm the custom song appears and launches with valid audio.
3. Export the selected custom song as a `.beatup-pack`, then import it in a clean
   profile. Built-in songs must refuse export.
4. Confirm Chart Studio is absent from Main Menu and Song Library. Existing
   custom songs, chart exports and autosaves must remain available on disk.

## Developer checks

Run `tests/release_gate.py` with Godot 4.7 before export. Retained analysis tools
run from the source checkout; they are excluded from player builds. The default
project setting remains `beat_up/creator_tools_enabled=false`.

Only distribute audio and artwork when you have permission from their rights holders.
