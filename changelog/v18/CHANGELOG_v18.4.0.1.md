# Beat UP! v18.4.0.1 — Parser Hotfix

Base version: v18.4.0

## Fixed

- Removed early global-class type annotations for `BeatFilePicker` and
  `BeatContextMenu` from Song Library and Chart Studio.
- The custom components remain scene-backed/preloaded, but the project no
  longer depends on Godot rebuilding its global script-class cache before it
  can parse the screens that use them.
- Fixed the startup parse errors reported at `chart_editor.gd:41-43` and
  `song_select.gd:111,165` on Godot 4.7.1.

## Compatibility

- Patch target: Beat UP! v18.4.0 source project.
- No music, charts, settings, records, replays, or telemetry are overwritten.
- No build-manifest JSON is included.
