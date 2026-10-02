# Beat UP! v17.4.52.1 — Godot 4.7 Parser Hotfix

- Fixed five `ui_capture.gd` parse errors caused by inferring typed variables from Variant-returning calls while warnings are treated as errors.
- Added explicit `Vector2` typing for spectrum frequency-range values.
- Added typed spectrum helper APIs to the centralized `MusicSession` and its menu/preview controllers.
- Updated stale spectrum assertions in `ui_capture.gd` to match the centralized audio architecture introduced in v17.4.49.
- No chart, scoring, gameplay, background, song metadata, or UI layout changes.
