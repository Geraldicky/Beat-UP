# v17.4.21.1 Navigation Transition QA

Static verification completed in the build environment.

- `SceneTransition` exposes `change_scene_quick()` and `transition_action_quick()`.
- Quick navigation has no `minimum_visible_duration` wait.
- Quick cover duration: 0.07 s.
- Quick reveal duration: 0.10 s.
- Quick mode hides the loading logo/status/progress UI and uses only the transition backdrop.
- Main Menu no longer runs its old 0.24 s exit tween before invoking another transition system.
- Main Menu → Song Library uses quick navigation.
- Main Menu → Chart Studio uses quick navigation.
- Song Library → Chart Studio uses quick navigation.
- Song Library → Main Menu uses quick navigation.
- Chart Studio → Main Menu uses quick navigation.
- Return to Song Library uses `transition_action_quick()`.
- Starting gameplay still uses the full loading transition.
- Result calculation still uses the full loading transition.
- All 42 built-in charts are byte-identical to v17.4.21.
- All built-in chart JSON files parse successfully.
- `validation.txt` is not included.

Godot is not installed in this build environment, so runtime feel and scene-loading time must be verified locally.
