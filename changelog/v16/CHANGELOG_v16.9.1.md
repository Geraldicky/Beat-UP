# Beat UP! v16.9.1 — Timing & Difficulty Curve Pass

## Objective
v16.9.1 addresses two playfeel problems that remained after v16.9:
1. directional notes could inherit transient-driven micro-offsets and feel slightly off the musical beat grid;
2. chart pressure followed local energy well, but repeated song sections did not always evolve into a clear level-wide difficulty arc.

The new pipeline separates **timing** from **arrangement**. Audio transients now provide evidence for choosing a rhythmic slot; they no longer pull the final playable timestamp away from the selected beat subdivision.

## Timing precision
- Generator identity bumped to `BUP-CG-01691` / revision `1691` / version `16.9.1`.
- Final directional timestamps are grid-locked.
- NORMAL uses quarter/eighth readability as its bundled timing contract.
- HARD/MASTER use the straight quarter/eighth/sixteenth grid.
- Native v16.9.1 generation can expose triplet subdivisions only when local onset evidence is stronger than the competing straight subdivisions and section pressure is high enough.
- Bundled v16.9 charts are **not retroactively converted into triplets**, because their source candidate grid did not author triplets. Their transient micro-shifts are restored to the straight source grid instead.
- Added conservative global phase refinement for future generation. A phase shift is applied only when onset-grid score improves by at least 3%, and the correction is capped at ±45 ms.
- Onset peaks are retained as candidate-selection confidence/strength information rather than playable timestamp offsets.

### Bundled timing migration
Across the v16.9 bundled directional events, deviation from each chart's declared straight grid had:
- median absolute deviation: ~18.69 ms;
- P95 absolute deviation: ~75.00 ms;
- ~22.85% of directional events more than 40 ms from that declared grid.

After the v16.9.1 migration, all bundled directional timestamps resolve to their selected straight grid within JSON rounding tolerance (<0.001 ms measured residual). This is a **grid-consistency metric**, not a claim that automatic beat detection is perceptually infallible.

Nine songs had enough evidence for a conservative global phase correction:
- `3_bow_for_me`: +23.00 ms
- `bad_apple`: -44.57 ms
- `can_can_audition`: +38.40 ms
- `diana_boncheva_feat_banya_beethoven_virus_full_version`: -41.04 ms
- `freedom_dive`: -32.40 ms
- `megalovania`: -40.00 ms
- `orpheus_can_can`: +22.94 ms
- `the_lab`: +45.00 ms
- `vessel`: -24.00 ms

Songs whose phase score did not improve by at least 3% keep their previous phase.

## Section-based difficulty envelope
Every generation phrase now carries:
- `section_occurrence` / `section_occurrence_count`;
- `difficulty_pressure`;
- `difficulty_density_multiplier`;
- `difficulty_stage` (`opening`, `develop`, `build`, `payoff`, `peak`, `technical`, `climax`, `release`);
- `musical_climax`.

The envelope uses functional song form when available:
- Intro establishes the chart at restrained pressure.
- Verse develops the main vocabulary.
- Pre-Chorus builds pressure.
- Chorus is a payoff, and repeated Chorus occurrences evolve instead of resetting to the same pressure.
- Bridge can become technical without necessarily becoming denser than the Chorus.
- Outro releases pressure.

This is intentionally **not a monotonic time ramp**. The detected musical climax is chosen primarily from audio intensity, with section role, recurrence, and song position used as restrained tie-breakers. A bridge or outro may therefore reduce pressure after a difficult section.

For songs with repeated Chorus labels in the bundled structure, final Chorus pressure is higher than the first Chorus in all cases. Songs whose structure backend exposes mostly `interlude` use the same audio-driven climax logic instead of fabricating Chorus labels.

## Difficulty behavior
- NORMAL: strongest readability constraint, quarter/eighth bundled grid, no Reverse/Bomb.
- HARD: stronger section-to-section escalation, selective sixteenth vocabulary, sparse Reverse.
- MASTER: strongest curve contrast, full straight subdivision vocabulary, evolved peak/climax motif families, Reverse + sparse Bomb.
- Difficulty still preserves deliberate recovery sections; MASTER does not mean constant maximum density.

## Bundled chart migration
All 39 bundled charts were migrated from v16.9 using their bundled OGG audio and existing musical candidate timings.
- v16.9 directional events: 21,381
- v16.9.1 directional events: 19,909
- retained: ~93.1%
- Reverse: 277
- Bomb: 27
- bundled triplets invented by migration: 0

The reduction is intentional: lower-pressure phrases are thinned more strongly so builds/payoffs/climax passages have perceptible contrast rather than every section converging toward similar density.

## Metadata / tooling
Added or updated:
- `timing_precision_meta`
- `difficulty_curve_meta`
- `musicality_meta` v16.9.1
- `timing_grid.timestamp_policy = grid_locked_onset_evidence`
- v16.9.1 generator/integrity metadata
- `tests/timing_curve_v1691_test.gd`
- v16.9 regression test accepts v16.9.x metadata so it remains useful after this patch.

## Runtime note
Static source checks and full bundled-data validation were completed. The build environment does not contain a runnable Godot editor binary, so interactive playfeel still needs local verification in the Godot project. Timing metadata is intentionally exposed per chart to make any remaining song-specific offset easy to identify and correct after playtest.
