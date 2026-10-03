from pathlib import Path

root = Path(__file__).resolve().parents[1]
song = (root / "scripts" / "song_select.gd").read_text(encoding="utf-8")
interaction = (root / "scripts" / "ui" / "interaction_polish.gd").read_text(encoding="utf-8")
gate = (root / "tests" / "release_gate.py").read_text(encoding="utf-8")

required = [
    'const SongRowScene = preload("res://scenes/ui/song_library/song_row.tscn")',
    'const DifficultyCardScene = preload("res://scenes/ui/song_library/difficulty_card.tscn")',
    'const ModeButtonScene = preload("res://scenes/ui/song_library/mode_button.tscn")',
    'const ModButtonScene = preload("res://scenes/ui/song_library/mod_button.tscn")',
    'const RecordPanelScene = preload("res://scenes/ui/song_library/record_panel.tscn")',
    'const PlayButtonScene = preload("res://scenes/ui/song_library/play_button.tscn")',
    'var supported_sort_modes: Array[String] = ["BPM Asc", "BPM Desc"]',
    'if selected_progress_filter != "All Progress":',
    '_refresh_song_rows(false)',
    '_update_detail(false)',
]
for token in required:
    if token not in song:
        raise SystemExit(f"Missing Song Library release contract: {token}")

for obsolete in [
    "SongLibraryAmbientScript",
    "album_flow_filter_button",
    "album_flow_bottom_panel",
    "album_flow_play_row",
    "_album_flow_toggle_filters",
    "_album_flow_show_filter",
    "_album_flow_reset_filters",
    "_install_album_flow_play_button_content",
    "_install_album_flow_mod_button_content",
]:
    if obsolete in song:
        raise SystemExit(f"Obsolete Song Library compatibility code survived cleanup: {obsolete}")

for runtime_test in [
    "song_library_rhythm_redesign_test.gd",
    "song_library_osu_reference_contract_test.gd",
]:
    if runtime_test not in gate:
        raise SystemExit(f"Release gate is missing {runtime_test}")

if 'beat_up_micro_tween' not in interaction:
    raise SystemExit("Interaction micro-motion does not cancel superseded tweens.")

for path in [
    "assets/ui/icons/arrow_right.svg",
    "assets/ui/icons/chevron_down.svg",
    "assets/ui/icons/chevron_left.svg",
    "assets/ui/icons/chevron_right.svg",
    "assets/ui/icons/chevron_up.svg",
    "assets/ui/icons/diamond.svg",
    "assets/ui/icons/info.svg",
    "assets/ui/icons/play_diamond.svg",
    "assets/ui/icons/practice.svg",
    "assets/ui/icons/random.svg",
    "assets/ui/icons/rank_diamond.svg",
    "assets/ui/icons/search.svg",
]:
    if not (root / path).is_file():
        raise SystemExit(f"Canonical Song Library icon missing: {path}")

print("SONG_LIBRARY_RELEASE_STATIC: PASS")
