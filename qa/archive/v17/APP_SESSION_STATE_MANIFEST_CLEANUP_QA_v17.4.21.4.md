# v17.4.21.4 QA — AppSessionState + Manifest Cleanup

Static checks:
- No direct `AppSessionState.` identifier references remain in GDScript.
- `AppSessionState` remains registered as an autoload in `project.godot`.
- `startup.gd` resolves it using `/root/AppSessionState` with a SceneTree metadata fallback.
- No filename matching `*manifest*.json` remains in the project.
- Legacy FLAC generator scripts reference `flac_library_14_catalog.json`.
- Built-in chart JSON files are unchanged from v17.4.21.3.

Runtime Godot execution is not available in the build environment; test the cold-launch and return-to-menu flow locally.
