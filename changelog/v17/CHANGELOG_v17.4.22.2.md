# Beat UP! v17.4.22.2 — osu!-Inspired Launch Flow

- Rebuilt the cold-launch choreography around the motion language demonstrated in the supplied osu! capture: quiet welcome, staged input marks, expanding central brand/receptor, then a continuous reveal into the live main menu.
- Reworked quick navigation into a horizontal ribbon handoff instead of a full-screen loading page.
- Song Library -> Gameplay now keeps selected artwork as the visual anchor, softly blurs/dims it, shows only song metadata + Beat UP! receptor pulse, then dissolves directly into gameplay.
- Removed the player-facing progress bar and `PREPARING CHART` loading copy from gameplay launch.
- Retired the legacy generic loading page from normal transition APIs. `change_scene()` and `transition_action()` now route through the new ribbon transition.
- Existing gameplay/chart data is unchanged.
- No manifest JSON files are generated.
