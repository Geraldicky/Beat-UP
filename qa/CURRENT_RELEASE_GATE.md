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
- Godot headless import/parser/warning checks and selected runtime foundation tests.

Run from the project root:

```powershell
python tests/release_gate.py --godot "C:\\path\\to\\Godot_v4.7-stable_win64.exe"
```

The full gate expects the canonical local project, including `music/imported`.
A source-only patch copy that intentionally omits the large built-in audio files
cannot pass `full_audio_library_v17448_test.py` until those files are present.
