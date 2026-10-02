# v17.4.22 QA — UI Cohesion + Seamless Gameplay Transition

Static verification checklist:

- Project/app/player-profile/telemetry version set to 17.4.22.
- Song Library launch uses `SceneTransition.change_scene_to_gameplay()` instead of generic `change_scene()`.
- Gameplay transition payload includes title, artist, difficulty, BPM, star rating, background, and Random state.
- Persistent transition layer owns artwork continuity across the scene replacement.
- Gameplay exposes `is_gameplay_transition_ready()` and holds countdown progress while SceneTransition is active.
- Battle/HUD/Feedback enter after transition completion.
- Quick menu Beat Diamond path remains separate and unchanged in behavior.
- Transition input lock remains enabled.
- Main Menu focal visual uses diamond styling and Song Library-like neutral cards.
- 42/42 built-in charts byte-identical to v17.4.21.5 baseline.
- Zero `*manifest*.json` files.
- JSON parse sweep passes.
- ZIP CRC must pass before delivery.

Godot runtime is not installed in the build environment; runtime transition timing/appearance must be validated locally in Godot.
