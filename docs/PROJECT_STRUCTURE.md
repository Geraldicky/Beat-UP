# Project Structure

Current runtime and development layout.

Runtime source: `assets/`, `audio/`, `charts/`, `config/`, `music/`, `scenes/`, `scripts/`, plus root `main.tscn`.

Development source:
- `tests/` — current release gate and regression tests.
- `qa/` — current release gate and beta testing guide.
- `tools/` — only current developer/build/analysis tooling.
- `CHANGELOG.md` — meaningful releases and milestones.
- `docs/` — current documentation.

Do not keep editor caches, Python caches, temporary UV environments, `.bak` files, generated builds, or per-patch backup trees in canonical source.

Built-in playable audio belongs in `music/imported/`; Main Menu music belongs in `music/menu/`.

The entry point is `scenes/boot.tscn`. Chart Studio is retired; chart/level-pack import, custom-song export and existing user content remain supported. `docs/LEVEL_PACK_FORMAT.md` documents the pack interface. Analysis utilities and historical regression tests are retained for development.

Historical patch notes, QA reports, design mockups, captured telemetry and superseded design/creator instructions are archived locally outside Git. They are not part of the public checkout. Local copies of these materials are ignored and excluded from both export presets.

Use Godot 4.7 and Python 3.10 or newer for the current gate:

```powershell
python tests/release_gate.py --godot "C:\path\to\Godot_v4.7-stable_win64.exe"
```

Windows builds use `tools/build_windows_beta.ps1 -Godot <path>`; the helper performs import/export, so run the release gate separately first. Optional audio analysis dependencies are listed in `tools/requirements-audio-qa.txt`.
