# Beat UP! v17.3.1 — Motion System Pass

## Focus
- make Song Library navigation feel continuous and interruptible instead of like rows snapping between layout states;
- synchronize song-wheel, info, difficulty, scroll, and background timing;
- preserve the v17.3.0 layout rebuild and v17.3.0.1 startup hotfix.

## Changes
- Song header margins now use damped spring interpolation every frame.
- Difficulty row margins use their own spring motion with staggered reveal delays.
- Rapid navigation can interrupt current wheel and scroll motion cleanly instead of stacking scroll tweens.
- Selected-row height/alpha easing was lengthened slightly and standardized around QUINT/QUAD ease-out curves.
- Difficulty expansion/collapse now combines height, fade, and slide with a tighter cascade.
- Selected-song info now fades down first, updates after a short delay, then fades back in.
- Song-list auto-scroll now continuously approaches an interruptible target rather than restarting a tween for every selection.
- Background crossfade duration increased from ~0.34s to ~0.38s with slightly stronger drift so its timing better matches the browser motion.
- Motion caches are cleared when the song list is rebuilt after filtering.
- Version updated to 17.3.1.

## Frozen systems
- No chart changes.
- No background asset changes.
- No gameplay/timing/progression changes.
- No import or Chart Editor changes.
- No Song Library structural layout changes from v17.3.0.1.
