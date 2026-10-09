# Current Release Gate — v18.7.0.1

`tests/release_gate.py` is the authoritative release gate for the current Beat UP!
build. Historical version-specific tests remain in `tests/` as regression/history
references, but they are not automatically authoritative merely because they can
be executed individually.

The current gate protects:

- current build/version identity and export hygiene;
- frozen gameplay timing, scoring, rank, and Reverse presentation contracts;
- Main Menu pause/resume and Previous/Next transport behavior;
- player-facing manual Chart Studio creation with developer-only auto generation;
- waveform/editor regression coverage;
- exported audio loading, complete built-in audio references, asynchronous Song
  Library loading, MusicSession type safety, and typography assets;
- Song Library release architecture: reusable component scenes, canonical SVG
  icon set, BPM-only sort contract, and removal of dead Album Flow compatibility
  scaffolding;
- Song Library runtime behavior at 1280×720, 1600×900, 1920×1080 and 2560×1440;
- rapid provisional selection followed immediately by Play resolving the final
  visible song/difficulty;
- force-resolving an edited chart at the Play boundary even when the resident
  Library UI still holds its previous catalog snapshot;
- Godot headless import/parser/warning checks and selected runtime foundation tests.

Run from the project root:

```powershell
python tests/release_gate.py --godot "C:\\path\\to\\Godot_v4.7-stable_win64.exe"
```

The Song Library runtime tests are automatically given isolated APPDATA and
XDG_DATA_HOME roots plus `BEAT_UP_QA_SONG_LIBRARY=isolated`. Do not run their
disk-mutation fixtures against normal user data.

The full gate expects the canonical local project, including `music/imported`.
A source-only patch copy that intentionally omits the large built-in audio files
cannot pass `full_audio_library_v17448_test.py` until those files are present.

## Song Library lock

The `ui/song-library-redesign` branch is code-complete for the current Song
Library design contract as of 2026-10-03. Future work should treat its visual
hierarchy, selection ownership, launch boundary and component split as locked
unless a regression, accessibility issue, or explicitly approved redesign
requires reopening them.

The gate definition is committed in-repo, but a full Godot release-gate execution
still has to be run on a machine with the canonical audio library and Godot 4.7.
