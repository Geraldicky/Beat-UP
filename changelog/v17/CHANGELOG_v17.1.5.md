# Beat UP! v17.1.5 — Floating Song Library Pass

## Focus
- move the Song Library away from boxed-panel composition toward an overlay layout inspired by osu!'s browser philosophy;
- let the background breathe and carry more of the screen mood;
- make search/filter/song rows feel like floating controls instead of nested panels;
- preserve gameplay, timing, progression, and chart data.

## Changes
- Removed the visual enclosing box from the right-side song library panel by making the library panel itself fully transparent.
- Reduced the global backdrop shade so artwork has more room to breathe.
- Reworked `song_select_visual.gd` to add a right-side readability gradient instead of relying on a dark boxed panel.
- Kept left-side readability via a soft veil rather than a hard panel treatment.
- Search input is now explicitly styled as a floating translucent control.
- Filter dropdowns remain compact but are retuned to read as floating overlay controls rather than embedded form widgets.
- Main song rows are lighter and less boxed; selected/hover/focus states remain clear without looking trapped in a panel.
- Difficulty rows are softened slightly so they feel integrated under the selected song row rather than like separate mini-cards inside a larger card.
- Removed the list separator line to reduce the sense of a boxed browser module.
- Updated version to `17.1.5`.

## Non-goals / frozen systems
- No chart, timing, gameplay, or progression logic changes.
- All 39 charts remain byte-identical to v17.1.4.
