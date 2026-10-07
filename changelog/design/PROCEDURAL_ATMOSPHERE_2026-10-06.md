# Procedural atmosphere — 2026-10-06

Replace visible generic pool imagery with a shared dark charcoal shader, slow
blue/amber light drift, sparse diamond outlines at the edges and stationary grain.
No video, jacket sampling, tiled grid, beat flashes or audio analysis. Gameplay
uses lower accent strength and keeps the horizontal note lane quiet.

The presentation-only control is installed by existing renderers. BackgroundSession
selection/preload metadata and navigation transactions remain unchanged; original
pool files remain available for rollback. Route handoff renders one atmosphere
below outgoing/incoming foregrounds, not randomized images. This first pass still
preloads pool textures for compatibility; removing that unused work is future debt.

Motion advances only while visible, stops during tree pause, and follows gameplay's
existing renderer processing toggle. `set_motion_enabled(false)` supports a static
presentation; no persisted settings UI was added in this initial visual trial.

Motion-design principles used: subtle atmospheric movement, no bounce/flash and
no layout animation. osu-reference inspected for ownership guardrails only; no
osu! code or visual assets were copied. Gameplay timing, inputs, score, MusicSession
and chart content are untouched. Application version remains 18.7.0.1.
