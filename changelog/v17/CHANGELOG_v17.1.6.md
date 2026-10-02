# Beat UP! v17.1.6 — Overlay Cleanup Pass

## Focus
- move the utility controls above the song list closer to the upper-right corner;
- remove leftover decorative elements on the left side that distract from the background;
- eliminate the residual low-opacity black overlay so the background can read more clearly;
- preserve gameplay, timing, progression, and chart data.

## Changes
- Removed the remaining `BackdropShade` tint by setting it fully transparent.
- Rebuilt `song_select_visual.gd` into a much cleaner overlay pass:
  - removed the diamond watermark,
  - removed the left-side sound bars/waveform,
  - removed the global black wash,
  - kept only a subtle right-side readability gradient and a thin top accent rail.
- Increased selected background visibility slightly so the artwork can carry more of the mood.
- Tightened `LibraryVBox` vertical separation to reduce the boxed feel.
- Added leading spacers to `LibraryToolbar` and `ProgressToolbar` so the search/filter/sort controls sit more toward the upper-right, closer to the osu-inspired layout.
- Reduced the heaviness of the floating search/filter controls for a lighter overlay feel.
- Slightly tightened header/control vertical sizing so the utility area sits higher.
- Updated project version to `17.1.6`.

## Non-goals / frozen systems
- No chart, timing, gameplay, or progression changes.
- All 39 charts remain byte-identical to v17.1.5.
