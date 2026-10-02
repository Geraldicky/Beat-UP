# Beat UP! v17.4.3 — FLAC Chart Musicality & Timing Pass

## Summary
Rebuilds the complete 14-song / 42-chart library from the supplied lossless FLAC masters. This pass focuses on timing phase, local musical intensity, section escalation, breathing room, and difficulty-specific density instead of adding UI features.

## Chart timing
- Regenerated all 42 Normal / Hard / Master charts from FLAC analysis; the 11 previously preserved charts are now included in the FLAC pass too.
- Keeps each song on its verified BPM grid, then performs a small source-driven phase refinement (maximum ±90 ms) against FLAC onset evidence.
- Note timestamps remain grid-locked after phase refinement to avoid free-running timing drift.
- Runtime playback remains Ogg Vorbis; the FLAC masters are analysis sources only and are not bundled into the game ZIP.

## Musicality / density
- Added 16-beat phrase analysis using RMS energy, onset mean/peak, and transient density.
- Phrase roles now distinguish Intro, Verse, Pre-Chorus, Chorus, Climax, Bridge/Interlude, and Outro behavior.
- Calm phrases deliberately retain breathing room while Chorus/Climax phrases receive stronger density pressure.
- Added long-gap filling only when local musical evidence is strong, specifically targeting the old burst → empty gap failure pattern.
- Added repeated bar-slot penalties so adjacent bars are less likely to reuse identical subdivision layouts.

## Difficulty behavior
- NORMAL prioritizes primary beats and half-beat rhythm with a peak cap of 6 notes in any 1-second window.
- HARD introduces stronger subdivision/syncopation pressure with a peak cap of 9 notes per 1-second window.
- MASTER uses the densest technical phrasing while remaining capped at 11 notes in any 1-second window.
- Density is section-aware rather than a global note multiplier.

## Reverse / special notes
- Reverse remains the only directional special mechanic.
- Overall Reverse targets remain approximately 6% / 12% / 18% for Normal / Hard / Master.
- Reverse placement is now weighted toward phrase accents, Chorus, and Climax instead of being uniformly distributed.
- Bomb remains fully removed.
- SPACE timings are selected from strong beat accents with difficulty-specific spacing.

## Direction flow
- Updated generated direction choreography to phrase-level motif families with alternating virtual-finger pressure.
- Added guards against immediate same-direction repetition, short ABAB loops, and repeated bar-slot patterns.
- Existing 4 KEY remapping and 8 KEY mode behavior remain unchanged.

## Tooling
- Added `tools/generate_flac_chart_pass_v1743.py` for reproducible bulk regeneration from the external FLAC master folder.
- Added `tools/flac_chart_analysis_v1743.json` with per-song/per-difficulty analysis metrics.
- Updated the 14-song FLAC manifest with the resolved v17.4.3 chart offsets.

## Unchanged
- Song Library UI / MODS panel unchanged.
- 4 KEY / 8 KEY selection unchanged.
- Random MOD unchanged.
- Gameplay judgement and scoring unchanged.
- 14 OGG gameplay audio files unchanged from v17.4.2.
- Song backgrounds unchanged from v17.4.2.

## Packaging
- Version bumped to 17.4.3.
- Changelog remains under `changelog/`.
- No `VALIDATION*.txt` files are included.
