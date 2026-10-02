# v17.4.22.3 QA — Consistent Gameplay Launch Transition

Static checks:
- Project/profile/telemetry/startup version strings set to 17.4.22.3.
- Standalone Song Library still uses `change_scene_to_gameplay()` for the first gameplay launch.
- In-main Song Select/Retry paths use `transition_action_to_gameplay()` rather than generic `transition_action()`.
- Result Retry and Pause Retry route through `_transition_to_level()` and therefore reuse the song artwork transition.
- 42 built-in chart JSON files are byte-identical to v17.4.22.2.
- No `*manifest*.json` files are present.

Runtime Godot execution is not available in the build environment; verify the repeated launch flow locally.
