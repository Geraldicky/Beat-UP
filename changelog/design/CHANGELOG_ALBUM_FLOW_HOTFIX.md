# Album Flow Hotfix

## Gameplay presentation
- Reverse note geometry is now identical to Normal note geometry.
- Removed the extra Reverse inner diamond treatment.
- Reverse semantic distinction is now the red outline only.

## Main Menu music transport
- Pause no longer causes the track clock to fall back to `00:00`.
- Resume now continues from the cached pause position instead of cold-starting the current stream.
- Previous/Next now correctly swaps to the adjacent track.
- Removed the redundant `start_menu_music()` call that cancelled the pending MusicSession track-switch tween.
- Main-menu synchronization preserves paused state.
