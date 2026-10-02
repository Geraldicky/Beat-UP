# Beat UP! v17.4.21.2 Navigation State + Beat Diamond QA

Static verification targets:

- App boot still starts with the BEAT UP! splash.
- `BOOT_SPLASH_META` is set when the first splash completes.
- Reloading `startup.tscn` after boot skips the splash and enters Main Menu immediately.
- Song Library Back sets `beat_up_return_to_main_menu` before changing scene.
- Song Library Back restores PLAY focus.
- Chart Studio return restores CHART STUDIO focus.
- Gameplay return restores PLAY focus.
- Quick transition no longer exposes the full-screen loading backdrop/visual.
- Quick transition draws `QuickTransitionVisual` using the Beat Diamond visual.
- Full loading transition remains available for real loading work.
- Project/app version strings report 17.4.21.2.
- Built-in chart JSON files must remain byte-identical to v17.4.21.1 revision 2.

Runtime note: Godot executable is not available in the build environment, so runtime QA must be performed locally in Godot/exported Windows build.
