# Beat UP! v17.4.44 — Full-library song-specific choreography

## Why this update exists

v17.4.43 exposed a direction-authoring regression: the 25-song FLAC batch reused a small global motif bank, so unrelated songs could repeatedly feel like the same numpad route (for example the recognizable `7-8-9-6-3-2-1-4` perimeter family). That made the library feel generated from one template instead of giving each song its own rhythm-game identity.

## Entire chart library re-authored

All **39 songs / 117 charts** (NORMAL, HARD, MASTER) now use the v17.4.44 song-specific choreography system. This pass rewrites note directions across the entire shipped library, including the 14 older songs that previously used the anti-orbit pass and the 25 songs added in v17.4.43.

The existing FLAC-derived musical skeleton is preserved: note timestamps, BPM/offset, note count, Normal/Reverse type, Reverse placement, SPACE timing, density, section metadata, and prior readability/telemetry thinning are unchanged. Only directional choreography and its metadata are re-authored. Across the full library, **80,331 of 92,000 note directions changed (87.316%)**.

## Song identity instead of a global motif bank

The fixed global motif bank and `motif[i % len(motif)]` authoring model are no longer used. Each song now receives one deterministic movement grammar derived from its own FLAC-timing rhythm fingerprint, BPM, section form/energy, and song identity. NORMAL, HARD, and MASTER share that same song DNA while applying different complexity pressure.

Section anchors are musical attractors on accents, not cyclic direction sequences. This allows a song to establish recognizable internal motifs without forcing the same motif onto other songs.

## Anti-template guardrails

The full-library pass rejects immediate repeated direction blocks from 2–12 notes, same-direction spam, four-note-or-longer clockwise/counter-clockwise perimeter walks, and three-step repeated translation-vector motion. Cross-song exact 6-note vocabulary overlap is regression-tested so a shared template bank cannot silently return.

## QA result

All 117 charts pass the v17.4.44 choreography regression suite. Maximum perimeter run is 3 notes, adjacent repeated 2–12-note blocks are 0, and the maximum cross-song 6-note Jaccard overlap across matching difficulties is below 0.06. The previous `7-8-9-6-3-2-1-4` template is absent from United (L.A.O.S Remix) and At the Speed of Light across all three difficulties.

No Bomb notes were added. No FLAC masters are bundled. No build/manifest JSON files were added.
