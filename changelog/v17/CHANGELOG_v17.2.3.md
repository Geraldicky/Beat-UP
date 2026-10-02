# Beat UP! v17.2.3 — Song Browser Hierarchy Polish

## Focus
- polish hierarchy and density without reopening the v17.2.2 background/overlay fix;
- make the right browser more dominant and the left selected-song information more compact;
- reduce visual competition from secondary controls;
- preserve gameplay, progression, charts, and background assets.

## Changes
- Rebalanced Song Library body proportions to approximately 36% selected-song info / 64% browser.
- Widened the right browser baseline and reduced the semantic width of the left info area.
- Compacted Personal Best into a fixed-width three-metric cluster (Score / Accuracy / Combo) instead of spreading it across the full left side.
- Moved Progress and Sort into the main search/filter toolbar, creating a single compact upper-right utility row.
- Hid the now-unused secondary ProgressToolbar presentation row.
- Reduced search/filter control height and surface opacity so they read as utilities rather than primary cards.
- Retuned song-row hierarchy:
  - unselected rows are quieter and more transparent;
  - selected row gets the strongest fill and a clear left accent rail;
  - hover/focus states remain readable without competing with selection.
- Tightened the selected-song difficulty group and aligned all difficulty strips with a consistent inset.
- Reduced Random Mode to a compact ghost-style secondary toggle while keeping Play as the single dominant CTA.
- Added a thin, low-contrast edge scrollbar with stronger hover/drag feedback.
- Updated version markers to `17.2.3`.

## Frozen systems
- All 39 chart JSON files are byte-identical to v17.2.2.
- All 13 bundled song background assets are byte-identical to v17.2.2.
- No gameplay, timing, chart-generation, progression, or background-rendering changes.
