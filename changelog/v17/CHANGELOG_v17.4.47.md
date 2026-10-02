# Beat UP! v17.4.47 — Library Smoothness + Preview Audio Fix

## Fixed
- Main Menu -> Song Library no longer starts a synchronous song preview on the transition frame. Preview handoff now begins after the shell route animation completes.
- Song rows use 384x216 thumbnails instead of synchronously loading all 1600x900 backgrounds. Full-resolution art is still used for the selected-song backdrop/gameplay/result.
- Fixed preview section lookup: generated charts use `sections[].role`, while the previous code only checked `sections[].name`.
- Song previews now start one musical phrase before the first chorus/drop/climax when available, instead of an arbitrary ~32% point in the track.
- Added a short selection debounce and lengthened the audio crossfade so fast card browsing does not produce abrupt/stale audio.
- Added a MusicSession generation guard so an older crossfade callback cannot start the wrong track after a newer selection.

## Unchanged
- 39-song library and v17.4.46 Beat UP!-native backgrounds.
- All v17.4.44 song-specific choreography/charts, timing, scoring, Reverse, SPACE and gameplay behavior.
