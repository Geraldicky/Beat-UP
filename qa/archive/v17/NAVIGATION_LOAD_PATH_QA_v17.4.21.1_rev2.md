# Beat UP! v17.4.21.1 Revision 2 — Navigation Load Path QA

Static checks:
- Main Menu PLAY targets `res://scenes/song_library.tscn`, not `main.tscn`.
- Song Library is a standalone scene containing only LevelCatalog + SongSelect.
- Gameplay is entered through a pending launch metadata handoff and `main.tscn`.
- Common destinations are requested for threaded warmup by SceneTransition.
- Quick transitions load/resolve destination before `_quick_cover()`.
- SongSelect no longer waits on its old 0.22 s transition-out tween.
- Built-in charts are untouched by this revision.

Runtime Godot verification is still required on the target machine.
