# Beat UP! v17.4.32 — Global Background + Song State

## Architecture
- Added `BackgroundSession` autoload as the shared artwork/background state.
- Expanded `SongSelectionState` into the canonical selected-song state for song id, difficulty, title, artist, artwork, audio, duration, BPM, difficulty label, star rating, and source.
- `BackgroundSession` subscribes to `SongSelectionState` and caches loaded textures.
- Main Menu, Song Library preview metadata, and gameplay launch handoff now consume the same canonical selected-song metadata.

## Main Menu
- Random/cycled Main Menu songs now publish into `SongSelectionState` instead of existing only as menu-local state.
- Returning from Song Library applies the globally selected artwork directly.
- Now Playing title/artist prefer the canonical global selected-song state while playback position remains owned by `MusicSession`.
- Cold launch still chooses a random built-in song, but that song now becomes the initial global selection so PLAY opens the matching song in Song Library.

## Song Library
- Selecting a song/difficulty publishes full canonical metadata before visuals/audio update.
- Song Library artwork resolves through `BackgroundSession` so the shared state is the source of truth.
- Preview playback merges canonical song metadata into `MusicSession` without restarting the same track.

## Gameplay handoff
- Song Library launch payload prefers canonical title/artist/BPM/background state for the selected song.
- No chart data or chart-generation logic changed.

## Compatibility
- Existing local fallback paths remain for standalone-scene/editor usage.
- No manifest JSON files are generated.
