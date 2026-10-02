# Beat UP! v17.3.0 — Fluid Song Library Rebuild

## Goal
Rebuild the Song Library interaction feel around a fluid, osu-inspired browser composition while keeping Beat UP!'s own visual identity.

## Major changes
- Added a curved song-wheel layout: the selected song extends furthest left while nearby/farther rows progressively indent to the right.
- Row positions now interpolate continuously instead of snapping to a flat list.
- Hovering a row gives a small horizontal pull toward the player.
- Selection transitions are slower and smoother with QUINT easing.
- Selected-row opacity and nearby-row opacity now depend on distance from the current selection, adding depth to the wheel.
- Difficulty rows expand/collapse with a staggered cascade and stepped indentation.
- Selected-song scroll movement now eases over 0.28 s and targets a more natural ~58% browser position.
- Selected-song info on the left crossfades in as a coordinated cluster instead of a simple 0.1 s pulse.
- Background changes now crossfade with a subtle horizontal drift; bundled background image files themselves remain unchanged.
- Back / Random / Play are now one compact action cluster in the left overlay.
- Removed the separate player-facing footer bar.
- Personal Best hides the empty SCORE/ACCURACY/COMBO rows when no record exists.
- Song strips and difficulty rows were tightened slightly to reduce the card-list feel.

## Frozen systems
- Gameplay logic unchanged.
- Timing/chart generation unchanged.
- Progression data and logic unchanged.
- All 39 chart JSON files unchanged.
- All 13 song background image assets unchanged.
- Import and Chart Editor functionality unchanged.
