# Beat UP! v17.1.1 — Compact Song Library Polish

This is a presentation-only follow-up to v17.1. The progression model and all 39 bundled charts are unchanged.

## Song Library layout
- Rebalanced the screen toward a broad selected-song area with a narrower right-side song list.
- Added a full-screen, low-contrast selected-song reactive backdrop driven by the existing audio preview spectrum.
- Removed the large selected-song hero card from the visible layout; song information now sits directly over the background.
- Reduced outer margins and panel spacing so the screen reads like a rhythm-game library rather than a dashboard.
- Reduced heavy panel borders and card fills. The left side, personal-best fields, quick stats, filters, and footer are substantially flatter.

## Compact song wheel
- Collapsed rows reduced to a 48 px baseline and selected rows to 56 px.
- Difficulty strips reduced to 30 px and use a thin difficulty-colored left rail instead of full heavy cards.
- Song-wheel indentation was reduced while retaining the focused/stacked visual movement around the selected song.
- Song rows no longer print `Unknown Artist`; missing artist metadata is omitted cleanly.
- Collapsed rows prioritize title, BPM, clear count, and FC count.
- Difficulty strips use compact `difficulty / stars / note count / progression / REC` presentation.

## Filters and actions
- Search and dropdown heights were reduced.
- `PROGRESS` and `SORT` captions were removed from the visible toolbar; their dropdowns remain.
- Random and Back remain secondary actions while Play remains the single strong CTA.
- IMPORT, REFRESH, and CHART EDITOR are hidden from the normal player-facing footer. The underlying nodes/signals remain available to development flows.
- Entry, selection, hover, and scrolling motion were reduced to restrained fades/translations; no gameplay effects were added.

## Personal best
- Personal-best fields remain visible even before the first play, using dash placeholders instead of collapsing the entire area. This avoids the large empty hole present in v17.1.

## Frozen gameplay/data
- No chart timestamps, note types, star ratings, timing, accuracy, progression rules, or gameplay feedback were changed.
- 39/39 bundled chart JSON files are byte-identical to v17.1.
