# Beat UP! v17.3.2.1 — Song Card Readability Hotfix

## Focus
- fix the overly dark song card rendering introduced in v17.3.2;
- restore readable text on song cards and difficulty cards;
- keep the art-based row identity while making the library usable again.

## Changes
- Reduced the darkness of the song-card veil and lowered the tint intensity in `SongBannerButton`.
- Increased banner visibility so the background art reads more clearly.
- Moved visible song-row text from built-in `Button.text` rendering to dedicated label children layered above the card artwork.
- Added readable title/subtitle label stacks for main song rows.
- Added readable metadata label rows for difficulty rows.
- Added shadowed white text treatment for better contrast against banner art.
- Updated version to 17.3.2.1.

## Frozen systems
- No chart changes.
- No gameplay changes.
- No progression changes.
- No song asset changes.
