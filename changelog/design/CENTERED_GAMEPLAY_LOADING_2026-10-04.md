# Centered gameplay loading presentation

Approved composition: square selected-song jacket, title, artist, then a thin
loading rail, centered as one group. No difficulty/BPM row, status caption,
waveform, top sweep, or fullscreen cover art. The rough mockup defines hierarchy,
not literal dimensions or an outer card.

`SongLaunchTransitionVisual` now owns a compact viewport-scaled layout:
280px jacket, 32px title, 18px artist, 420px by 4px rail at 1080p, scaled down
for smaller desktop windows. Long identity text is centered and ellipsized.
Missing artwork gets a restrained diamond placeholder. Art is loaded from the
existing `assets/song_thumbnails/<song_id>.png` source, never a random background.
The loading backdrop is neutral near-black; other routes' generic randomized
background behavior is unchanged.

SceneTransition fills missing song_id from canonical selection. AppShell passes
the authoritative resolved song_id in its existing visual payload so the jacket
and displayed identity refer to the same launch. No chart lookup is introduced
in the visual control. Existing preparation, rollback, completion signals,
readiness wait, and navigation ownership are unchanged.

Preparation has no reliable aggregate percentage: the thin moving segment
indicates activity, not fabricated completion. Cover/reveal remain short
(0.22s cover boundary / 0.30s reveal including delay); input availability is
still controlled by existing launch readiness, not a new animation delay.

Files: scene_transition_layer.tscn, song_launch_transition_visual.gd,
scene_transition.gd, app_shell.gd, loading_presentation_test.gd, this report.
Existing loading tests retain failed-launch rollback, exactly-once signals,
slow readiness, identity retention, input restoration, and tooltip/file-picker
coverage. Added assertions check the actual jacket, square/centered geometry,
title/artist/bar order and clipping at 1280x720, 1600x900 and 1920x1080.
Window and canvas coordinates are deliberately distinguished under stretch.

Actual OpenGL render captured at 1920x1080 with isolated APPDATA/XDG_DATA_HOME:
`C:\Users\USER\AppData\Local\Temp\beatup-loading-capture-e68bc187-2a02-41fb-95cc-30e3721e1823/loading.png`.
Focused loading presentation test PASS. No gameplay/chart/settings/scoring
changes; version remains 18.7.0.1.
Final full release gate PASS, including strict Godot import/parser/warning
validation, navigation, launch resolution, input snapshots and loading tests.
Existing runtime shutdown-retention diagnostics remain; criteria unchanged.
