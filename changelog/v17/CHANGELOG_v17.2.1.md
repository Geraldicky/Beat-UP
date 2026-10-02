# Beat UP! v17.2.1 — Background Cleanup Pass

## Focus
- remove the lingering pseudo-panel feel in Song Library;
- clean up the background artwork so it behaves like real fullscreen background art;
- reduce the remaining dark overlay feel on the left side;
- preserve all gameplay, chart, progression, and browser structure improvements from v17.2.

## Changes
- Regenerated all 13 bundled song backgrounds.
- Removed the large rounded-rectangle frame language from the artworks.
- Removed song title / artist text baked into the background images.
- Kept only ambient full-bleed shapes and light motifs so the UI can float over them.
- Reworked `song_select_visual.gd` to replace the blocky left overlay with a softer edge-to-center gradient.
- Reduced right-side browser darkening so the background remains more visible.
- Increased the visible strength of `BackdropVisual` in the Song Select scene.
- Updated version text to `17.2.1`.

## Frozen systems
- No gameplay logic changes.
- No chart or timing changes.
- No progression/data changes.
