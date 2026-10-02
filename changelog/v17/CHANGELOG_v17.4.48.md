# Beat UP! v17.4.48 — Audio Restore

## Fixed
- Restored the 25 newer runtime OGG files that were accidentally omitted from the packaged v17.4.44–v17.4.47 builds.
- The project now contains runtime OGG audio for all 39 songs referenced by the chart library.
- Restored files use the canonical `music/imported/<song_id>.ogg` names already referenced by the charts.

## Preserved
- v17.4.47 Song Library transition/preview fixes remain unchanged.
- v17.4.46 Beat UP!-style backgrounds remain unchanged.
- v17.4.44 song-specific choreography, chart timing, Reverse/SPACE placement, scoring, and difficulties remain unchanged.

## Packaging
- 39/39 chart audio references verified to resolve to an OGG file.
- No FLAC files are bundled in the game project.
- No build/manifest JSON was added.
