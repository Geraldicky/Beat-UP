from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
startup = (ROOT / 'scripts/startup.gd').read_text()
transition = (ROOT / 'scripts/scene_transition.gd').read_text()
select = (ROOT / 'scripts/song_select.gd').read_text()
main = (ROOT / 'scripts/main.gd').read_text()
assert '_transition_to_scene("res://scenes/song_library.tscn")' in startup
assert '"res://scenes/song_library.tscn"' in transition
assert 'var packed_scene: PackedScene = await _get_scene_for_quick_transition(scene_path)' in transition
assert '_quick_cover' not in transition and '_quick_reveal' not in transition
assert 'transition_tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.22)' not in select
assert 'PENDING_LIBRARY_LAUNCH_META' in main
assert (ROOT / 'scenes/song_library.tscn').exists()
assert (ROOT / 'scripts/song_library.gd').exists()
print('navigation_load_path_v174211_rev2_test: PASS')
