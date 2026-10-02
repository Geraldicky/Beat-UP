# Beat UP! v17.3.0.1 — ActionRow Startup Hotfix

## Root cause
`song_select.gd` resolves the new action cluster with `%ActionRow`, but the `ActionRow` node introduced in v17.3.0 was not marked `unique_name_in_owner = true`. Godot therefore returned null for `%ActionRow`; `_apply_layout_config()` then failed when calling `add_theme_constant_override()` on that null reference.

## Fixes
- Marked `ActionRow` as `unique_name_in_owner = true` in `song_select.tscn`.
- Kept `%ActionRow` as the script reference; it now resolves correctly.
- Renamed the unused `_difficulty_row_style` accent parameter to `_accent` to remove its warning.
- Renamed unused `set_audio_levels` parameter to `_levels`.
- Renamed the SongSelectVisual local `scale` variable to `fit_scale` to avoid shadowing `Control.scale`.

## Frozen systems
- No Song Library layout/motion changes.
- No gameplay/timing/progression changes.
- No chart changes.
- No background asset changes.
