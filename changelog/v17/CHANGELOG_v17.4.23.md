# Beat UP! v17.4.23 — Zero Loading Screen / Seamless Gameplay Handoff

## Player-facing behavior
- Removed the legacy loading-screen scene from the active project flow.
- Song Library → Gameplay no longer enters a loading page, progress bar, spinner, percentage, or `LOADING`/`PREPARING` state.
- Selected song artwork persists as a global handoff layer while `main.tscn`, chart data, audio, and gameplay state prepare behind it.
- Song title/artist/difficulty/BPM/star information is now a short launch flourish. It fades away on its own instead of remaining on screen as a disguised loading page.
- If preparation takes longer than the intro flourish, only the animated song artwork remains. Resource progress is never exposed to the player.
- When gameplay reports ready, the handoff artwork unblurs and dissolves into the gameplay background before `READY / 3 / 2 / 1` continues.
- Retry and in-main Song Select launches use the same seamless handoff path.

## Loading architecture
- Replaced `scenes/loading_transition.tscn` with `scenes/scene_transition_layer.tscn`.
- Removed legacy `TransitionVisual`, loading center, status text, percentage text, and progress-bar nodes.
- Removed `scripts/ui/loading_transition_visual.gd` from the project.
- Gameplay scene threaded loading starts before the handoff entrance finishes, overlapping resource work with visible motion.
- Generic menu/action transitions continue to use the short Beat Diamond handoff, not a loading UI.

## Integrity
- Built-in chart data is unchanged from v17.4.22.3.
- No manifest JSON files are created or included.
