# Beat UP! v18.4.0 — Unified Interface & Player Focus

Base version: v18.3.0

## Custom interface surfaces

- Replaced the Song Library JSON import `FileDialog` with the Beat UP! file picker.
- Replaced Chart Studio OGG, multi-OGG, and FLAC `FileDialog` windows with the same custom picker.
- Added Beat UP!-styled Places shortcuts, editable folder path, navigation, filtering, multi-select, keyboard confirmation, cancel behavior, and compact scrolling.
- Replaced the remaining native Practice Section `PopupMenu` with a custom anchored context menu.
- Replaced the native run-details `AcceptDialog` with a custom Beat UP! modal, including replay action support.
- Kept all standard dropdowns on the existing custom `BeatDropdown` component.

## Gameplay readability

- Restored the high-clarity note language: white body, dark direction glyph, blue normal outline, orange diagonal outline, and red reverse outline.
- Increased the hit receptor, hit feedback, SPACE prompt, judgement text, score, and combo presence without changing timing or BPM-driven travel speed.
- Slightly increased lane height while preserving the single-lane layout and the existing hit-zone position.

## Release foundation

- Updated the project version to 18.4.0.
- Credits now read the version from `ProjectSettings`; the stale 17.4.25 label cannot return on later releases.
- Added Windows file/product metadata and disabled the release console wrapper.
- Added a focused v18.4.0 static release check and updated the canonical release gate.
- No build-manifest JSON was created.

## Compatibility

- Patch target: Beat UP! v18.3.0 source project.
- Music is not included in this patch.
- Existing charts, settings, records, replays, and playtest telemetry are not overwritten.
