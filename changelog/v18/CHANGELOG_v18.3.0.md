# Beat UP! v18.3.0 — Presentation & Creator Workflow Rebuild

## Boot / Main Menu
- Replaced the grey first-frame exposure with a dark boot surface and matching default clear color.
- Removed the old welcome/glyph intro sequence.
- New launch intro: the BEAT UP! wordmark reveals left-to-right, holds briefly, then erases right-to-left.
- Removed the BEAT UP! text from the Main Menu diamond; the diamond now acts as the visual mark by itself.
- Removed the thin top accent strip from Main Menu, Song Library, How To Play and Chart Studio.
- Reworked the Exit confirmation into a smaller, cleaner two-action dialog.

## Gameplay / Pause
- Reduced the gameplay score card footprint and visual weight.
- Tightened score and accuracy hierarchy while keeping the lane unobstructed.
- Refined pause action iconography: Retry uses a cleaner circular arrow and Settings now uses slider controls rather than the previous sun-like symbol.

## Song Library
- Rebuilt Mods into a smaller input-first panel with 8K / 4K and Random as the only player-facing choices.
- Reworked local Ranking rows into leaderboard cards with placement, large score, grade, accuracy, max combo, FC state, mode tag and timestamp.
- Ranking remains local-only and respects 4K/8K + Random identity separation.

## Chart Studio
- Added Chart Studio as a resident AppShell route with lazy threaded scene loading.
- Entering Chart Studio transitions immediately to a lightweight shell before editor resources are constructed.
- Returning to Main Menu suspends the editor rather than destroying/rebuilding it.
- Heavy external audio analysis continues outside the main UI flow through worker threads.
- Refocused the editor around Beat UP! level creation: SONG → GENERATE → REVIEW → SAVE.
- Runtime playback source is explicitly OGG; lossless chart-analysis source is explicitly FLAC.
- Hid unrelated kitchen-sink editor controls until the Review stage.

## How To Play
- Removed the old documentation-heavy copy and rebuilt the flow around INPUT, TIMING, SPECIALS and PRACTICE.
- Existing interactive practice lane remains the primary teaching surface; copy is now short and action-oriented.

## Calibration
- Reframed calibration as a two-stage wizard: LISTEN + TAP → REVIEW + APPLY.
- Manual offset controls stay hidden until enough timing samples have been collected.
- Apply is disabled while calibration is incomplete.

## Settings / UI Cleanup
- Reduced Settings footprint and promoted Calibration Wizard as the timing entry point.
- Retained the v18.2 unified visual system while reducing redundant decoration.

## Safety / Content Integrity
- No chart JSON, song background, scoring rules or chart choreography changed in this update.
- No manifest JSON files are created.
