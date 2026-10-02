# Splash Session-State QA — v17.4.21.3

Static checks:
- `AppSessionState` is registered as an autoload.
- Session state is memory-only and is not persisted to `user://`.
- Cold `startup.tscn` may run `_run_splash()` only while `splash_seen == false`.
- `_finish_splash()` marks the process session as consumed.
- Explicit returns from Song Library, Chart Studio, and gameplay mark splash consumed before changing to `startup.tscn`.
- Returning startup path uses `_show_main_menu_immediate()`.
- Built-in charts must remain byte-identical to v17.4.21.2.

Runtime Godot verification is still required on a local machine because Godot is not installed in the build environment.
