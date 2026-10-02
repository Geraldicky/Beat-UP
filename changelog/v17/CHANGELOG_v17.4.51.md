# Beat UP! v17.4.51 — Typography Role System

## Focus
This release introduces a clearer osu!-inspired typography hierarchy without copying or bundling osu! font assets. Beat UP! now assigns different font families by information role instead of using one visual voice for everything.

## Font roles
- **Display / identity:** Space Grotesk Variable — large screen headings, selected song title, section headings, rank.
- **UI / reading:** Poppins Regular / Medium / SemiBold — artists, controls, descriptive text, labels, buttons.
- **Numeric / technical:** IBM Plex Mono — BPM, duration, note count, score, accuracy, combo and compact chart data.

## Song Library polish
- SONG LIBRARY and selected-song titles now use the dedicated display face.
- Chart metadata moves away from the terminal-like mono treatment and uses the UI family.
- BPM / LENGTH / NOTES values are larger and use the numeric face.
- Personal Best Score / Accuracy / Max Combo values are larger and use the numeric face.
- Rank is larger and uses the display face as the primary performance focal point.
- Personal Best labels and judgement breakdown use the UI family for better scanning.
- Song-card titles receive a small readability increase.

## Scope / integrity
- No osu! font files are included.
- No chart JSON was modified.
- No timing, choreography, scoring, audio preview, async loading, background, or save-data logic was changed.
- v17.4.49 resident/async library changes and v17.4.49.1 Variant hotfix remain included.
