# Beat UP! v16.9 — Chart Quality & Musicality Pass

## Objective
v16.9 changes chart generation from primarily local-density selection into a phrase-aware arranger. Local audio intensity remains the primary timing/density signal, but chart output now has musical phrase arcs, controlled cadence breathing, recurring song-signature patterns, and context-aware special notes.

## Generator / arranger
- Generator identity: `BUP-CG-01690` / revision `1690` / version `16.9`.
- Added phrase arcs: `breath`, `groove`, `build`, `payoff`, `contrast`, and `release`.
- Added per-phrase density multipliers. The multiplier is deliberately restrained so song-form labels cannot override actual audio intensity.
- Added pre-climax cadence breathing. Ordinary trailing subdivisions can be withheld before a meaningful upward transition; strong terminal onset anchors are preserved.
- Added a deterministic per-song signature ID and phrase pattern families: `pulse`, `stair`, `orbit`, `cross`, `zigzag`, `syncopated`, and `burst`.
- Candidate selection now receives a pattern-slot bias while strong audio transients remain authoritative.
- Direction generation keeps the two-finger playability model and anti-repetition guards, but now receives phrase-scoped motif bias.

## Difficulty identity
- NORMAL: direction + SPACE only; strongest pulse/readability bias and the largest dynamic contrast.
- HARD: denser syncopation and phrase-accent Reverse notes.
- MASTER: full pattern vocabulary, payoff bursts, more Reverse notes, and sparse Bomb notes.
- Difficulty still uses independent density, subdivision, burst, and NPS limits; v16.9 does not inflate speed merely to create difficulty.

## Special-note placement
- Removed the v16.8 wall-clock interval rule from active generation.
- Reverse is selected from clear musical/structural accents inside eligible phrases.
- Bomb is restricted to MASTER, prefers secondary/offbeat accents, avoids SPACE proximity, and avoids clustering with other specials.
- Instrumental songs with no literal chorus label receive a strongest-phrase fallback so MASTER still teaches/uses Bomb.

## Bundled chart migration
All 39 bundled charts (13 songs × NORMAL/HARD/MASTER) received an offline audio musicality pass using the bundled OGG audio plus the existing audio-aligned timing candidates.
- Local onset + RMS strength was used to thin calm/release phrases while preserving payoff density.
- Existing candidate timing was retained wherever possible rather than inventing an unrelated chart grid.
- Direction choreography was re-authored with the v16.9 song-signature motif system.
- Special notes were re-authored using phrase context.
- Orpheus Can Can and The Lab received tail-recovery charting because their previous candidates stopped before the active final sections.

Bundled chart totals after migration:
- 39 charts / 13 songs.
- 21,381 directional events.
- 353 Reverse notes.
- 42 Bomb notes.
- NORMAL contains no Reverse/Bomb.
- HARD contains Reverse but no Bomb.
- Every MASTER chart contains both Reverse and Bomb.

## Quality checks
- All 39 JSON charts parse and pass structural validation.
- All event timestamps are strictly increasing.
- All non-Bomb directions are valid numpad directions.
- No generated special is within 0.55 s of SPACE.
- Generated specials maintain readable separation.
- Note-count and star progression remain ordered NORMAL < HARD < MASTER for every song.
- No bundled chart now has a >20 s uncharted active tail.
- Exact `3-note burst -> long gap -> 3-note burst` signatures decreased from 358 in v16.8 to 324 in v16.9 while four-bar density contrast increased overall.

## Regression coverage
- Added `tests/chart_musicality_v169_test.gd`.
- Existing v16.8 gameplay-integrity regression test remains in the project.

## Runtime verification note
The project targets Godot 4.7. Static source/data validation was completed in the build environment. A Godot executable was not available locally; an attempted 4.7.x headless download was blocked by the execution environment, so final interactive playfeel still requires opening the project in Godot and playtesting representative songs.
