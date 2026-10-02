# v17.4.24 QA — Persistent UI Shell + Async Handoff

Static verification targets:

- `project.godot` starts at `res://scenes/app_shell.tscn`.
- AppShell owns persistent Startup, Song Library and gameplay instances.
- Main Menu -> Song Library routes through `AppShell.show_song_library()` rather than `SceneTree.change_scene*()`.
- Song Library -> Main Menu routes through `AppShell.show_main_menu()`.
- Song Library -> Gameplay routes through `AppShell.launch_gameplay()` while the selected artwork handoff remains visible.
- Result/Pause -> Song Library routes through `AppShell.show_song_library_from_gameplay()`.
- Splash is not recreated on persistent menu return.
- Hidden screens are disabled from processing/input.
- 42 built-in chart JSON files remain byte-identical to v17.4.23.1.
- No `*manifest*.json` files exist.
- No `validation.txt` exists.

Runtime Godot verification is still required locally because Godot is not installed in the build environment.
