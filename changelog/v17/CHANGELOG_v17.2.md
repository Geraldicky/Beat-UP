# Beat UP! v17.2 — osu-style Song Browser Rebuild

## Focus
- rebuild the Song Library around an osu-inspired browser philosophy rather than continuing small opacity tweaks;
- let full-screen song artwork carry the mood of the screen;
- tighten the left-side info into a compact overlay and make the right-side browser feel more like a floating edge-anchored list;
- preserve gameplay, timing, progression, and chart data.

## Major changes
- Replaced the bundled abstract song backgrounds with a new set of 13 richer, cover-art-like full-screen artworks.
- Rewrote `song_select_visual.gd` so the browser uses a cleaner composition.
- Widened the browser column and reduced the left info column’s dominance so the right-side list behaves more like an edge browser.
- Toolbar controls (search / artist / difficulty / progress / sort) were resized and tightened to feel more like a compact upper-right utility strip.
- Song rows now use per-song accent colors instead of a single generic list treatment.
- Song rows were realigned so the old staggered margin behavior is gone.
- Selected-row and difficulty-row styles were retuned for a stronger banner-like presence.
- Selected-row auto-centering now targets a lower viewing zone (~63%) for a more natural browser feel.
- Detail typography on the left was tightened slightly for a cleaner compact info presentation.
- Updated version to `17.2`.

## Frozen systems
- No gameplay logic, timing logic, progression logic, or chart content changes.
- All 39 charts remain byte-identical to v17.1.6.
