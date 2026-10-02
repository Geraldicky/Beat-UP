# Beat UP! v17.3.4 — Song Card Readability & Hierarchy Pass

## Focus
- keep song-card artwork visible without fading song text with distance;
- make selected/unselected hierarchy come from artwork treatment instead of parent opacity;
- tighten the relationship between the selected song and its difficulty rows.

## Changes
- Removed distance-based `Button.modulate` fading from main song rows.
- Main title/subtitle labels now remain fully readable regardless of distance from the selected song.
- Added artwork-only `visual_emphasis` to `SongBannerButton`; distance now dims the image/veil treatment while leaving child text untouched.
- Reduced selected-row accent tint so more of the original song artwork remains visible.
- Reduced general card tint intensity and tuned overlay strength for cleaner artwork integration.
- Increased the difficulty-row inset and tightened its stepped indentation so Normal/Hard/Master read more clearly as children of the selected song.
- Preserved v17.3.3 custom dropdowns and v17.3.1 fluid motion behavior.
- Version updated to 17.3.4.

## Frozen systems
- No chart changes.
- No song background asset changes.
- No gameplay/timing/progression changes.
- No custom dropdown behavior changes.
- No import or Chart Editor behavior changes.
