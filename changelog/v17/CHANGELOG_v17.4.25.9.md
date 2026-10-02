# Beat UP! v17.4.25.9 — NowPlaying Panel Structural Fix

- Root cause fix: `NowPlayingCard` changed from `PanelContainer` to plain `Panel`.
- This prevents child minimum sizes from forcing the black bar taller than the explicit layout height.
- `CardMargin` now anchors to the panel bounds instead of driving parent minimum size.
- Top bar target height is now 32 px base, clamped to 30–34 px.
- Transport buttons remain square at 22x22 so icons do not flatten.
- User waveform settings in `main_menu_visual.gd` are preserved unchanged.
- No manifest JSON files created.
