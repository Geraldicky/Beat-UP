# Beat UP! v17.3.2 — Song Card Art Pass

## Focus
- rebuild Song Library song rows so they stop feeling like transparent UI strips;
- make each song card use its own artwork crop based on the same song background, closer to the osu!-style identity target;
- preserve the v17.3.1 motion system while upgrading visual identity.

## Changes
- Added a new `SongBannerButton` control that draws cropped song-art banners directly inside song rows.
- Main song rows now use each song's background image as an opaque banner card instead of a transparent fill.
- Difficulty rows now inherit the same song artwork so the selected song stack feels visually connected.
- Added layered dark readability veils over banner art so title and metadata remain readable.
- Selected rows now get a stronger accent border and left strip, while unselected rows stay darker and more subdued.
- Hover/focus states now redraw the banner rows instead of relying on translucent panel fills.
- Added lightweight song-background texture caching in `song_select.gd` for repeated row rendering.
- Version updated to 17.3.2.

## Frozen systems
- No chart changes.
- No gameplay/timing/progression changes.
- No song background asset changes.
- No import or Chart Editor changes.
- No Song Library structural layout rewrite beyond the row rendering pass.
