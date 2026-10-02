# v17.4.24.1 QA — Return-to-Library Frame Stall

Static checks:
- No `refresh_from_shell_deferred()` call after Gameplay -> Song Library handoff.
- Hidden gameplay reset does not call `show_level_select()`.
- Note cleanup provides a batched idle-frame path.
- App version strings are 17.4.24.1.
- No manifest JSON is present.

Runtime target (Godot unavailable in build environment):
1. Play a dense MASTER chart.
2. Pause or finish and choose Song Library.
3. Song Library reveal animation should keep moving continuously.
4. No mid-reveal UI build/freeze should occur.
