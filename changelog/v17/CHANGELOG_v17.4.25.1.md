# Beat UP! v17.4.25.1 — Main Menu Minimal Text Cleanup

## Summary
- Removes auxiliary main-menu text so only button labels remain alongside the Beat UP! logo.
- Removes the footer waveform and redraws reactive waveform bars around all four sides of the central Beat UP! diamond/logo area.
- Removes the dark strip/box overlay pass from the main-menu draw layer so song artwork remains unobstructed.

## Main Menu Changes
- Hidden: selected-action text inside the diamond, selection index, description copy, background song metadata, version stamp, and footer control hints.
- Preserved: button labels, Beat UP! logo, diamond identity, and random song-art background system.
- The menu accent divider remains, but the heavy dark draw_rect overlays are gone.

## Technical Notes
- Runtime cleanup is enforced in `startup.gd` via a minimal-text pass.
- `main_menu_visual.gd` now draws only thin framing plus four-sided waveform bars around the central logo.
- No manifest JSON files were created.
