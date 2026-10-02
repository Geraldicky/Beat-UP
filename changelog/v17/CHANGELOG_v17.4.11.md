# Beat UP! v17.4.11 — Gameplay Presentation Polish

## Objective

Make the gameplay screen visually beta-ready while preserving chart, timing, and navigation behavior from v17.4.10.

## Song-specific gameplay backgrounds

- Gameplay now loads the `background` resource authored in the selected chart.
- All current bundled songs therefore use their own song artwork during gameplay.
- Backgrounds use aspect-cover scaling so there are no stretched images or letterbox gaps.
- If a chart background is missing/unloadable, gameplay safely falls back to Beat UP!'s base-dark background.
- Song artwork is visible only during gameplay; Song Library and Result continue using their own existing backdrops.

## User-controlled background visibility

- The existing `background_opacity` preference is now applied directly to the per-song gameplay artwork.
- 0% = artwork hidden / darkest gameplay background.
- 100% = full artwork visibility.
- The existing default remains 62%.
- The Pause Settings slider updates the gameplay background live.
- The Startup Settings slider persists through `user://settings.cfg`.
- The setting label is clarified as `SONG BACKGROUND OPACITY`.
- No permanent transparent-black overlay was added; opacity blends artwork over the existing base-dark colour instead.

## HUD hierarchy

- Score panel moved to the top-left gameplay corner.
- Song information occupies the remaining centered top rail.
- Pause remains top-right.
- Combo remains lower-left.
- HUD panels receive slightly stronger surfaces/borders to remain readable over bright song artwork.
- Score odometer is left-aligned inside its new top-left position while retaining the existing rolling animation.

## Note and receptor readability

- Note fill is now near-white.
- Normal outline remains blue.
- Diagonal outline remains orange.
- Reverse outline remains red.
- Direction arrow is dark over the white fill for reliable contrast.
- Hit receptor is strengthened to a white diamond with a subtle dark inner structure.
- SPACE remains gold.

## Judgment feedback — intentionally unchanged

Per playtest direction, v17.4.11 does **not** add or redesign judgment feedback. Existing PERFECT/GREAT/GOOD/MISS popup behavior and existing hit feedback remain as they were in v17.4.10.

## Preserved systems

- No chart regeneration or rebalance.
- No note timestamp changes.
- No BPM changes.
- No scroll-speed formula changes.
- No judgment-window changes.
- v17.4.8 timing/calibration hardening preserved.
- v17.4.9 first-time tutorial preserved.
- v17.4.10 menu/navigation behavior preserved.
- No `validation.txt`.

## Hotfix 1
- Extended the gameplay lane so it visually reaches both screen edges.
- Restored note and hit-zone colours to the previous pre-v17.4.11 presentation.
- Removed the "HIT" caption from the hit zone.

## Hotfix 2
- Restored the gameplay palette source in `theme_config` so runtime no longer forces white-filled notes.
- Restored darker note fill and brighter arrow contrast from the previous version.
- Restored the previous hit-zone opacity and border treatment.
