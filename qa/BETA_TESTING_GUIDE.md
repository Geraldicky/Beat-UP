# Beat UP! Beta Testing Guide

The build version is displayed in Main Menu > Credits.

## Player flow

1. Launch the game and open the Song Library.
2. Play one built-in chart on Normal, Hard, and Master.
3. Verify pause/resume, calibration offsets, result saving, replay, and practice.
4. From Main Menu, pause and resume the Now Playing track and confirm the
   timestamp does not reset. Verify Previous/Next changes the audio, metadata,
   and artwork.
5. Play a Reverse-heavy chart and confirm Reverse uses the Normal-note shape
   with a red outline only.

## Player Creator

1. Open Chart Studio from the Main Menu.
2. Import an Ogg Vorbis gameplay file.
3. Confirm NORMAL, HARD, and MASTER blank drafts are created locally.
4. Select one difficulty, set its Chart BPM, place Normal/Reverse/Space notes,
   use Undo/Redo, and save it.
5. Optional: select FLAC/WAV as a waveform source and confirm a waveform preview
   can be built without creating notes automatically.
6. Confirm **Generate All / Quick Generate / advanced AI generation is not
   visible in a normal player build**.
7. Confirm the custom song appears in Song Library.
8. Export the selected custom song as a `.beatup-pack`, then import it in a clean
   profile.

## Developer generator

When running the project in the Godot editor, confirm the developer generator is
available and still passes generator reliability QA. A normal player export must
keep `beat_up/creator_tools_enabled=false`.

Only distribute audio and artwork when you have permission from their rights holders.
