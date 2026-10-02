from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / 'project.godot').read_text(encoding='utf-8')
script = (ROOT / 'scripts' / 'song_select.gd').read_text(encoding='utf-8')

assert 'config/version="18.0.0.2"' in project
assert 'func _build_v18_details_controls() -> void:' in script
assert 'ranking_mods_label.text = "SELECTED MODS"' in script
assert 'ranking_tab_tools.move_child(rank_sort_button, ranking_tab_tools.get_child_count() - 1)' in script
assert 'action_row.add_child(practice_button)' in script
assert 'action_row.add_child(replay_button)' in script
assert 'NO LOCAL SCORES FOR %s' in script
print('v18.0.0.2 Song Library layout checks passed.')
