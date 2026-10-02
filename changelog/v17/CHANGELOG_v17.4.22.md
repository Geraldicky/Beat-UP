# Beat UP! v17.4.22 — UI Cohesion + Seamless Gameplay Transition

## Main Menu cohesion
- Main Menu now uses the same dark surface/panel language as Song Library.
- Replaced the legacy circular focal treatment with the Beat UP! diamond motif.
- Menu cards now rest on neutral surfaces and use accent colors for hover/focus instead of a permanently bright PLAY block.
- Fixed Main Menu visual selection indexing so EXIT receives the correct danger accent.

## Song Library → Gameplay
- Replaced the generic full loading page with a song-artwork continuity transition inspired by the motion principle shown in the osu! reference.
- Selected artwork stays full-screen while `main.tscn`, chart data, song background, and audio prepare.
- Shows song title, artist, difficulty, BPM, star rating, Random state, and a thin preparation progress line.
- Artwork is softly blurred/dimmed during preparation and dissolves directly into the same gameplay background.
- Gameplay lane/HUD fade in after the artwork transition completes.
- READY / countdown timing does not advance while the global transition is active.
- Transition input remains locked, preserving the v17.4.21.5 ESC-race fix.

## Loading/transition language
- Generic heavy loading and Beat Diamond transitions now share the Song Library base background color.
- Dedicated generic loading remains available for non-song heavy operations; Song Library → Gameplay uses the new continuity path.

## Safety / compatibility
- Gameplay rules, scoring, judgement windows, telemetry schema, chart timings, chart directions, and balancing are unchanged.
- All 42 built-in charts are byte-identical to v17.4.21.5.
- No manifest JSON file is created.
