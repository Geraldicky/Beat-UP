from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
script = (ROOT / 'scripts/song_select.gd').read_text(encoding='utf-8')
scene = (ROOT / 'scenes/song_select.tscn').read_text(encoding='utf-8')
startup = (ROOT / 'scripts/startup.gd').read_text(encoding='utf-8')
result_scene = (ROOT / 'scenes/result_screen.tscn').read_text(encoding='utf-8')
project = (ROOT / 'project.godot').read_text(encoding='utf-8')

assert 'config/version="18.0.0.1"' in project
assert 'var selected_info_tab: String = "details"' in script
assert 'ranking_scope_label.text = "LOCAL"' in script
for token in ['ranking_mods_filter.add_item("8K")', 'ranking_mods_filter.add_item("4K")', 'ranking_mods_filter.add_item("8K + RANDOM")', 'ranking_mods_filter.add_item("4K + RANDOM")']:
    assert token in script, token
assert 'ScoreIdentity.key(chart, ranking_input_style, ranking_random_mode)' in script
assert 'NO LOCAL SCORES' in script
assert 'breakdown_grid.visible = false' in script
assert 'progress_status.visible = false' in script
assert 'subtitle_parts.append(_song_chart_summary(song_id))' not in script
assert 'SORT: SCORE' not in script
assert 'main_footer.visible = false' in startup
assert '[node name="FooterHint" type="Label"' in result_scene and 'visible = false' in result_scene[result_scene.index('[node name="FooterHint"'):result_scene.index('[node name="BackButton"', result_scene.index('[node name="FooterHint"'))]
assert len(list((ROOT/'charts').rglob('*.json'))) == 117
assert len(list((ROOT/'music/imported').glob('*.ogg'))) == 39
assert len(list((ROOT/'assets/song_backgrounds').glob('*.png'))) == 39
assert not list(ROOT.rglob('*manifest*.json'))
print('v18.0.0.1 UI simplification static QA: PASS')
