# Beat UP! v17.4.21.1 — Snappy Navigation Hotfix

## Fixed
- Removed the stacked Main Menu exit animation + full loading-screen transition that made lightweight page changes feel artificially slow.
- Added a dedicated quick transition path for UI-to-UI navigation: 70 ms cover + 100 ms reveal, with no forced minimum loading duration.
- Main Menu → Song Library and Main Menu → Chart Studio now use the quick path.
- Song Library → Chart Studio, Song Library → Main Menu, Chart Studio → Main Menu, and Result/Gameplay → Song Library now use the quick path.

## Preserved
- Heavy operations still use the full loading presentation: starting gameplay/loading chart+audio and result calculation.
- Full transition timing remains available for genuinely expensive work (0.16 s cover, 0.42 s minimum visible duration, 0.20 s reveal).
- Chart Studio OGG + FLAC generation workflow is unchanged.
- All 42 built-in charts are byte-identical to v17.4.21.
- Gameplay, judgement, scoring, timing, telemetry schema, local player ID, and chart balancing are unchanged.

## Revision 2 — Navigation load-path fix
- Added a lightweight standalone `Song Library` scene; opening the library no longer instantiates the complete gameplay scene.
- `SceneTransition` now warms common destinations in the background and keeps their `PackedScene` resources cached.
- Quick navigation resolves its destination before the blackout begins, so resource loading cannot extend a black frame.
- Removed the Song Library's additional 220 ms exit animation; global scene transition is the sole page transition.
- Gameplay `main.tscn` is now instantiated only after `PLAY SONG`; full loading UI remains appropriate there.
- Chart Studio, charts, scoring, telemetry, save data, and gameplay presentation are unchanged.
