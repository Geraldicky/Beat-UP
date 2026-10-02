# Beat UP! Player Creator Guide (v18.7.0.1)

## Create a playable song

1. Open **Song Library**, then choose **Chart Studio**.
2. Import an **Ogg Vorbis (`.ogg`)** file. This becomes the gameplay audio and
   creates local NORMAL, HARD, and MASTER chart drafts under `user://songs`.
3. Choose the difficulty you want to edit and set its **Chart BPM**. BPM is
   edited directly on the active chart; the player build does not auto-generate
   notes.
4. Optional: choose a **FLAC or PCM WAV (`.wav`) waveform source**. This source is
   used only to build the Chart Studio waveform preview. Gameplay still uses the
   imported OGG.
5. Use the timeline, seek controls, beat snap, and **Normal / Reverse / Space**
   tools to author the chart manually. Undo and Redo remain available while
   editing.
6. Save each difficulty you want to keep, then return to Song Library and
   refresh the local library.

Chart Studio keeps a recovery copy under `user://chart_autosaves` while a chart
has unsaved changes. A successful manual save removes that recovery copy.

## Automatic generation is developer-only

The automatic chart generator is not exposed in normal player builds. Players
can import audio, create charts manually, edit charts, save them, and share
custom levels, but **Generate All / Quick Generate / advanced AI generation** is
reserved for development.

Developer generation remains in the codebase for internal chart production and
QA. It is available when the project runs in the Godot editor, or when a
developer deliberately enables `beat_up/creator_tools_enabled` for a dedicated
development build. The default project value is `false`.

## Share or install a level

- Select a custom song in Song Library and choose **Export Pack**. The resulting
  `.beatup-pack` is written to `user://level_packs`.
- Choose **Import Level / Pack** to install either a standalone chart JSON or a
  `.beatup-pack`.
- Built-in songs cannot be exported. Existing custom-song folders are not
  silently replaced by pack import.

Only share audio and artwork for which you have distribution permission. A
chart-only sharing mode is supported by the pack API, while the current player
button exports the complete local song for straightforward installation.
