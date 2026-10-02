# Beat UP! v17.4.31 — Global Music Session Architecture

## Architecture
- Added global `MusicSession` autoload as the single owner of menu/library music playback.
- Added global `SongSelectionState` autoload as the single source of truth for the currently selected Song Library item.
- Main Menu and Song Library no longer own separate playback clocks.
- Existing `MenuBGMController` and `SongPreviewController` are now UI adapters over the shared music session.

## Navigation / audio behavior
- Main Menu -> Song Library -> Main Menu keeps the exact same playback clock when the selected song is unchanged.
- Returning to Main Menu no longer requires copying a stream and seeking a new AudioStreamPlayer.
- Hiding the persistent Song Library no longer stops its selected song.
- Back from Song Library preserves music; launching gameplay/editor still fades/stops menu music as needed.
- Selecting a different Song Library card starts that song at its preview entry point, then continues naturally through the full song.
- Changing difficulty for the same song updates metadata without restarting or seeking the audio.

## State flow
- Song Library publishes selected song/difficulty metadata into `SongSelectionState`.
- `MusicSession` carries song metadata together with the playback state so Main Menu artwork and Now Playing UI can resume without a handoff copy.
- AppShell now switches screens only; it no longer needs an audio handoff dictionary for normal persistent-shell navigation.

## Compatibility
- Legacy handoff code remains as a standalone-scene fallback, but persistent AppShell navigation uses the global session path.
- No built-in chart data was intentionally modified.
- No manifest JSON files were created.
